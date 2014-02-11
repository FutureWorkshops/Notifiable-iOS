//
//  FWTNotifiableManager.m
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWTNotifiableManager.h"

#import <CommonCrypto/CommonCrypto.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFJSONRequestOperation.h>

NSString * const FWTNotifiableUserInfoKey           = @"user";
NSString * const FWTNotifiableDeviceTokenKey        = @"token";
NSString * const FWTNotifiableProviderKey           = @"provider";

NSString * const FWTNotifiableDidRegisterWithAPNSNotification      = @"FWTNotifiableDidRegisterWithAPNSNotification";
NSString * const FWTNotifiableFailedToRegisterWithAPNSNotification = @"FWTNotifiableFailedToRegisterWithAPNSNotification";

@interface FWTNotifiableManager ()

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) AFHTTPClient *httpClient;

@end

@implementation FWTNotifiableManager

+ (instancetype)sharedManager
{
    static FWTNotifiableManager *sharedManagerInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManagerInstance = [[FWTNotifiableManager alloc] init];
    });
    return sharedManagerInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_retryAttempts = 5;
        self->_retryDelay = 60;
    }
    return self;
}

- (AFHTTPClient *)httpClient
{
    if (!self->_httpClient) {
        self->_httpClient = [AFHTTPClient clientWithBaseURL:self.baseURL];
        self->_httpClient.parameterEncoding = AFJSONParameterEncoding;
    }
    return self->_httpClient;
}

#pragma mark - Public

+ (BOOL)userAllowsPushNotificationsForType:(UIRemoteNotificationType)types
{
    UIApplication *app = [UIApplication sharedApplication];
    UIRemoteNotificationType typesAllowed = [app enabledRemoteNotificationTypes];
    
    return typesAllowed == types;
}

- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo
{
    [self registerTokenWithUserInfo:userInfo completionHandler:nil];
}

- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo completionHandler:(FWTNotifiableOperationCompletionHandler)hanlder
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    
    if(userInfo)
        p[FWTNotifiableUserInfoKey] = userInfo;
    
    if(self.deviceToken)
        p[FWTNotifiableDeviceTokenKey]  = self.deviceToken;
    
    p[FWTNotifiableProviderKey]     = @"apns";
    [self _registerDeviceWithParams:p attempts:self.retryAttempts completionHandler:hanlder];
}

- (void)anonymiseToken
{
    [self anonymiseTokenWithCompletionHandler:nil];
}

- (void)anonymiseTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _anonymiseTokenWithAttempts:self.retryAttempts completionHandler:handler];
}

- (void)unregisterToken
{
    [self unregisterTokenWithCompletionHandler:nil];
}

- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)hanlder
{
    [self _unregisterTokenWithAttempts:self.retryAttempts completionHandler:hanlder];
}

#pragma mark - UIApplicationDelegate forwarding methods

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    self.deviceToken = [[deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableDidRegisterWithAPNSNotification object:self];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableFailedToRegisterWithAPNSNotification object:self];
}

#pragma mark - Private

- (void)_registerDeviceWithParams:(NSDictionary *)params
                         attempts:(NSUInteger)attempts
                completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    [self.httpClient postPath:@"device_tokens" parameters:params success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            NSLog(@"Did register for push notifications with token: %@", self.deviceToken);
            if(handler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        } else {
            [self _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to register device token: %@", error);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
        });
    }];
}

- (void)_unregisterTokenWithAttempts:(NSUInteger)attempts
                   completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    if(!self.deviceToken){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"device_tokens/%@", self.deviceToken];
    
    [self.httpClient deletePath:path parameters:nil success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            NSLog(@"Did unregister for push notifications");
            if(handler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        } else {
            [self _unregisterTokenWithAttempts:(attempts - 1) completionHandler:handler];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to unregister for push notifications");
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _unregisterTokenWithAttempts:(attempts - 1) completionHandler:handler];
        });
    }];

}

- (void)_anonymiseTokenWithAttempts:(NSUInteger)attempts completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    if(!self.deviceToken){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    [self.httpClient postPath:@"device_tokens/anonymise" parameters:nil success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            NSLog(@"Did anonymise device token");
            if(handler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        } else {
            [self _anonymiseTokenWithAttempts:(attempts - 1) completionHandler:handler];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to anonymise device token");
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _anonymiseTokenWithAttempts:(attempts - 1) completionHandler:handler];
        });
    }];

}

@end
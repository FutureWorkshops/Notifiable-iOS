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

NSString * const FWTNotifiableUserInfoKey           = @"user";
NSString * const FWTNotifiableDeviceTokenKey        = @"token";
NSString * const FWTNotifiableProviderKey           = @"provider";

NSString * const FWTNotifiableDidRegisterWithAPNSNotification       = @"FWTNotifiableDidRegisterWithAPNSNotification";
NSString * const FWTNotifiableFailedToRegisterWithAPNSNotification  = @"FWTNotifiableFailedToRegisterWithAPNSNotification";

NSString * const FWTNotifiableTokenKey                              = @"FWTNotifiableTokenKey";

@interface FWTNotifiableManager ()

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;

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
        self->_debugLogging = NO;
    }
    return self;
}

- (AFHTTPRequestOperationManager *)operationManager {
    if (!self->_operationManager) {
        self->_operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        self->_operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return self->_operationManager;
}

- (NSString *)deviceToken
{
    if(!self->_deviceToken){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self->_deviceToken = [ud objectForKey:FWTNotifiableTokenKey];
    }
    
    return self->_deviceToken;
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
    [self registerTokenWithUserInfo:userInfo extendedParameters:nil completionHandler:hanlder];
}

- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo extendedParameters:(NSDictionary *)parameters completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if(!self.deviceToken)
    {
        if(handler)
            handler(NO);
        return;
    }
    
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    if(userInfo)
        p[FWTNotifiableUserInfoKey] = userInfo;
    
    if(self.deviceToken)
        p[FWTNotifiableDeviceTokenKey]  = self.deviceToken;
    
    p[FWTNotifiableProviderKey]     = @"apns";
    [self _registerDeviceWithParams:p attempts:self.retryAttempts completionHandler:handler];
    
}

- (void)anonymiseTokenWithUserInfo:(NSDictionary *)userInfo
{
    [self anonymiseTokenWithUserInfo:userInfo completionHandler:nil];
}

- (void)anonymiseTokenWithUserInfo:(NSDictionary *)userInfo completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if(!self.deviceToken)
    {
        if(handler)
            handler(NO);
        return;
    }
    
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    
    if(userInfo)
        p[FWTNotifiableUserInfoKey] = userInfo;
    
    if(self.deviceToken)
        p[FWTNotifiableDeviceTokenKey] = self.deviceToken;
    
    [self _anonymiseTokenWithParams:p attempts:self.retryAttempts completionHandler:handler];
}

- (void)unregisterToken
{
    [self unregisterTokenWithCompletionHandler:nil];
}

- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)hanlder
{
    [self _unregisterTokenWithAttempts:self.retryAttempts completionHandler:hanlder];
}

- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo forUserInfo:(NSDictionary *)userInfo
{
    NSString *notificationID = notificationInfo[@"notification_id"];
    
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    
    if(notificationID)
        requestParameters[@"notification_id"] = notificationID;
    
    if(self.deviceToken)
        requestParameters[@"device_token"] = @{ FWTNotifiableDeviceTokenKey : self.deviceToken };
    
    if(userInfo)
        requestParameters[FWTNotifiableUserInfoKey] = userInfo;
    
    [self _markNotificationAsOpenedWithParams:requestParameters attempts:self.retryAttempts];
}

#pragma mark - UIApplicationDelegate forwarding methods

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    self.deviceToken = [[deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableDidRegisterWithAPNSNotification object:self];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:self.deviceToken forKey:FWTNotifiableTokenKey];
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
    
    [self.operationManager POST:@"device_tokens" parameters:params success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            
            if(self.debugLogging)
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
        
        if(self.debugLogging)
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
    
    [self.operationManager DELETE:path parameters:nil success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            
            if(self.debugLogging)
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
        
        if(self.debugLogging)
            NSLog(@"Failed to unregister for push notifications");
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _unregisterTokenWithAttempts:(attempts - 1) completionHandler:handler];
        });
    }];
    
}

- (void)_anonymiseTokenWithParams:(NSDictionary *)params
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
    
    if(!self.deviceToken){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    [self.operationManager PUT:@"device_tokens/anonymise" parameters:params success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            
            if(self.debugLogging)
                NSLog(@"Did anonymise device token");
            
            if(handler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        } else {
            [self _anonymiseTokenWithParams:params attempts:(attempts - 1) completionHandler:handler];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if(self.debugLogging)
            NSLog(@"Failed to anonymise device token");
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _anonymiseTokenWithParams:params attempts:(attempts - 1) completionHandler:handler];
        });
    }];
    
}

- (void)_markNotificationAsOpenedWithParams:(NSDictionary *)params
                                   attempts:(NSUInteger)attempts
{
    if (attempts == 0)
        return;
    
    if(!self.deviceToken)
        return;
    
    [self.operationManager PUT:@"notifications/opened" parameters:params success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        
        if(self.debugLogging)
            NSLog(@"Notification flagged as opened");
            
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
        } else {
            [self _markNotificationAsOpenedWithParams:params attempts:(attempts - 1)];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if(self.debugLogging)
            NSLog(@"Failed to mark notification as opened");

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _markNotificationAsOpenedWithParams:params attempts:(attempts - 1)];
        });
    }];
    
}

@end

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


NSString * const FWTNotifiableAuthTokenKey = @"auth_token";
NSString * const FWTNotifiableUserIdKey = @"user_id";
NSString * const FWTNotifiableDeviceTokenKey = @"token";
NSString * const FWTNotifiableProviderKey = @"provider";
NSString * const FWTNotifiableUserDictionaryKey = @"user";

@interface FWTNotifiableManager ()

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) AFHTTPClient *httpClient;

@end

@implementation FWTNotifiableManager

+ (instancetype)sharedManager {
    static FWTNotifiableManager *sharedManagerInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManagerInstance = [[FWTNotifiableManager alloc] init];
    });
    return sharedManagerInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.retryAttempts = 5;
        self.retryDelay = 60;
    }
    return self;
}

- (AFHTTPClient *)httpClient {
    if (!self->_httpClient) {
        self->_httpClient = [AFHTTPClient clientWithBaseURL:self.baseURL];
        self->_httpClient.parameterEncoding = AFJSONParameterEncoding;
    }
    return self->_httpClient;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = [[deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

}

- (void)registerTokenWithParams:(NSDictionary *)params {
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:params];
    p[FWTNotifiableDeviceTokenKey] = self.deviceToken;
    p[FWTNotifiableProviderKey] = @"apns";
    [self _registerDeviceWithParams:p attempts:self.retryAttempts];
}

#pragma mark - Private

- (void)_registerDeviceWithParams:(NSDictionary *)params attempts:(NSUInteger)attempts {
    if (attempts == 0)
        return;
    [self.httpClient postPath:@"device_tokens" parameters:params success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            NSLog(@"Did register for push notifications with token: %@", self.deviceToken);
        } else {
            [self _registerDeviceWithParams:params attempts:attempts - 1];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to register device token: %@", error);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _registerDeviceWithParams:params attempts:attempts - 1];
        });
    }];
}

@end
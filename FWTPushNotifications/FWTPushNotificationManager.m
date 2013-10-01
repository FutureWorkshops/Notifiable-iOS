//
//  FWTPushNotificationManager.m
//  FWTPushNotifications
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWTPushNotificationManager.h"
#import "NSUserDefaults+FWTPushNotifications.h"

#import <CommonCrypto/CommonCrypto.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFJSONRequestOperation.h>


NSString * const FWTPushNotificationsAuthTokenKey = @"auth_token";
NSString * const FWTPushNotificationsUserIdKey = @"user_id";
NSString * const FWTPushNotificationsDeviceTokenKey = @"token";
NSString * const FWTPushNotificationsProviderKey = @"provider";

@interface FWTPushNotificationManager ()

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) AFHTTPClient *httpClient;

@end

@implementation FWTPushNotificationManager

+ (instancetype)sharedManager {
    static FWTPushNotificationManager *sharedManagerInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManagerInstance = [[FWTPushNotificationManager alloc] init];
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

- (void)registerTokenIfNeededWithParams:(NSDictionary *)params {
    if (!self.deviceToken)
        return;
    NSString *userId = params[FWTPushNotificationsUserIdKey];
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:params];
    p[FWTPushNotificationsDeviceTokenKey] = self.deviceToken;
    p[FWTPushNotificationsProviderKey] = @"apns";
    if (![[NSUserDefaults standardUserDefaults] didRegisterDeviceToken:self.deviceToken forUserInfo:userId]) {
        [self _registerDeviceWithParams:p attempts:self.retryAttempts];
    }
}

#pragma mark - Private

- (void)_registerDeviceWithParams:(NSDictionary *)params attempts:(NSUInteger)attempts {
    if (attempts == 0)
        return;
    [self.httpClient postPath:@"device_tokens" parameters:params success:^(AFHTTPRequestOperation *operation, NSData * responseData) {
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        NSLog(@"%@", JSON);
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            NSString *userId = params[FWTPushNotificationsUserIdKey];
            [[NSUserDefaults standardUserDefaults] registerDeviceToken:self.deviceToken forUserInfo:userId];
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
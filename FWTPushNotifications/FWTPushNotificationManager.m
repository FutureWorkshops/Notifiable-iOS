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
#import <AFNetworking/AFJSONRequestOperation.h>

@interface FWTPushNotificationManager ()

@property (nonatomic, strong) NSString *deviceToken;

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
        self.timeoutInterval = 300;
        self.retryDelay = 60;
        self.deviceName = @"";
        self.deviceId = @"";
    }
    return self;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = [[deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (void)registerTokenInNeeded {
    if (!self.deviceToken)
        return;
    if (![[NSUserDefaults standardUserDefaults] didRegisterDeviceToken:self.deviceToken]) {
        
        NSString *params = [NSString stringWithFormat:@"token=%@&device_name=%@&device_id=%@", self.deviceToken, self.deviceName, self.deviceId];
        NSString *signature = [self _signatureForRequestParams:params];
        [self _registerDeviceParams:params signature:signature attempts:self.retryAttempts];
    }
}

#pragma mark - Private

- (void)_registerDeviceParams:(NSString *)params signature:(NSString *)signature attempts:(NSUInteger)attempts {
    if (attempts == 0)
        return;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.APIURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.timeoutInterval];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[params stringByAppendingFormat:@"&sig=%@", signature] dataUsingEncoding:NSUTF8StringEncoding];
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if ([[JSON valueForKey:@"status"] integerValue] == 0) {
            [[NSUserDefaults standardUserDefaults] registerDeviceToken:self.deviceToken];
            NSLog(@"Did register for push notifications with token: %@", self.deviceToken);
        } else {
            [self _registerDeviceParams:params signature:signature attempts:attempts - 1];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Failed to register device token: %@", error);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _registerDeviceParams:params signature:signature attempts:attempts - 1];
        });
    }] start];
}

- (NSString *)_signatureForRequestParams:(NSString *)params {
    uint8_t digest[CC_SHA256_DIGEST_LENGTH] = { 0 };
    const char *cKey = self.APIKey.UTF8String;
    const char *cData = params.UTF8String;
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), digest);
    NSData *digestData = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    return [[digestData.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
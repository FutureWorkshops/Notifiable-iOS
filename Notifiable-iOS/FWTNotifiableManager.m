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
NSString * const FWTNotifiableTokenIdKey                            = @"FWTNotifiableTokenIdKey";

NSString * const FWTAuthFormat = @"Auth %@:%@";

NSString * const FWTAuthHeader = @"Authorization";
NSString * const FWTTimestampHeader = @"Date";

@interface FWTNotifiableManager ()

@property (nonatomic, readwrite, strong) NSString *deviceToken;
@property (nonatomic, readwrite, strong) NSNumber *deviceTokenId;
@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSDateFormatter *httpDateFormatter;

@end

@implementation FWTNotifiableManager

@synthesize deviceToken = _deviceToken;
@synthesize deviceTokenId = _deviceTokenId;

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

- (NSDateFormatter *)httpDateFormatter
{
    if (!self->_httpDateFormatter) {
        self->_httpDateFormatter = [[NSDateFormatter alloc] init];
        [self->_httpDateFormatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"];
    }
    return self->_httpDateFormatter;
}

- (AFHTTPRequestSerializer *)requestSerializer
{
    if (!self->_requestSerializer) {
        self->_requestSerializer = [AFHTTPRequestSerializer serializer];
        [self->_requestSerializer setValue:@"application/x-www-form-urlencoded"
                        forHTTPHeaderField:@"Content-Type"];
        [self->_requestSerializer setValue:@"application/json"
                        forHTTPHeaderField:@"Content-Accept"];
    }
    return self->_requestSerializer;
}

- (AFHTTPSessionManager *)httpSessionManager
{
    if (!self->_httpSessionManager) {
        self->_httpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
        self->_httpSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        self->_httpSessionManager.requestSerializer = self.requestSerializer;
    }
    return self->_httpSessionManager;
}

- (NSString *)deviceToken
{
    if(!self->_deviceToken){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self->_deviceToken = [ud objectForKey:FWTNotifiableTokenKey];
    }
    
    return self->_deviceToken;
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    self->_deviceToken = deviceToken;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (deviceToken) {
        [ud setObject:deviceToken forKey:FWTNotifiableTokenKey];
    }
    else {
        [ud removeObjectForKey:FWTNotifiableTokenKey];
    }
}

- (NSNumber *)deviceTokenId
{
    if(!self->_deviceTokenId){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self->_deviceTokenId = [ud objectForKey:FWTNotifiableTokenIdKey];
    }
    
    return self->_deviceTokenId;
}

- (void)setDeviceTokenId:(NSNumber *)deviceTokenId
{
    self->_deviceTokenId = deviceTokenId;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (deviceTokenId) {
        [ud setObject:deviceTokenId forKey:FWTNotifiableTokenIdKey];
    }
    else {
        [ud removeObjectForKey:FWTNotifiableTokenIdKey];
    }
}

#pragma mark - Public

+ (BOOL)userAllowsPushNotificationsForType:(UIUserNotificationType)types
{
    UIApplication *app = [UIApplication sharedApplication];
    
    if(![app isRegisteredForRemoteNotifications]) {
        return NO;
    }
    
    UIUserNotificationSettings *settings = [app currentUserNotificationSettings];
    UIUserNotificationType typesAllowed = settings.types;
    
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
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableFailedToRegisterWithAPNSNotification object:self];
}

#pragma mark - Private

- (NSString *) _canonicalStringForPath:(NSString *)path
                                  date:(NSDate *)date
                             andHeader:(NSDictionary <NSString *, NSString *>*)headers
{
    NSString *contentType = headers[@"Content-Type"];
    if (contentType == nil) {
        contentType = @"";
    }
    
    NSString* uri = [NSString stringWithFormat:@"/%@", path];
    NSString* timestamp = [self.httpDateFormatter stringFromDate:date];
    
    return [NSString stringWithFormat:@"%@,,%@,%@",contentType, uri, timestamp];
}

- (NSString *) _hmacHashForString:(NSString *)string
                          withKey:(NSString *)key
{
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    const char *keyChar = [key UTF8String];
    const char *stringChar = [string UTF8String];
    CCHmac(kCCHmacAlgSHA1, keyChar, strlen(keyChar), stringChar, strlen(stringChar), cHMAC);
    NSData *encriptedData = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *base64 = [encriptedData base64EncodedStringWithOptions:0];
    return base64;
}

- (NSDictionary *) _authHeadersForPath:(NSString *)path
                              clientId:(NSString *)clientId
                             secretKey:(NSString *)secretKey
                            andHeaders:(NSDictionary <NSString *, NSString *>*)headers
{
    NSDate *timestamp = [NSDate date];
    NSString* canonicalString = [self _canonicalStringForPath:path
                                                         date:timestamp
                                                    andHeader:headers];
    
    NSString* encryptedString = [self _hmacHashForString:canonicalString
                                                 withKey:secretKey];
    
    NSString* authField = [NSString stringWithFormat:FWTAuthFormat, clientId, encryptedString];
    
    return @{FWTAuthHeader:authField,
             FWTTimestampHeader:[self.httpDateFormatter stringFromDate:timestamp]};
}

- (void)_updateAuthenticationForPath:(NSString *)path
{
    NSDictionary *authHeaders = [self _authHeadersForPath:path
                                                 clientId:self.appId
                                                secretKey:self.secretKey
                                               andHeaders:self.requestSerializer.HTTPRequestHeaders];
    for (NSString *header in authHeaders.keyEnumerator) {
        [self.requestSerializer setValue:authHeaders[header] forHTTPHeaderField:header];
    }
}

- (void)_registerDeviceWithParams:(NSDictionary *)params
                         attempts:(NSUInteger)attempts
                completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if (self.deviceTokenId) {
        [self _updateDeviceWithParams:params attempts:attempts completionHandler:handler];
        return;
    }
    
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    NSString *path = @"user_api/v1/device_tokens";
    [self _updateAuthenticationForPath:path];
    
    [self.httpSessionManager POST:path parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
            if(self.debugLogging)
                NSLog(@"Did register for push notifications with token: %@", self.deviceToken);
            
            self.deviceTokenId = responseObject[@"id"];
            
            if(handler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        } else {
            [self _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(self.debugLogging)
            NSLog(@"Failed to register device token: %@", error);
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
        });
    }];
}

- (void)_updateDeviceWithParams:(NSDictionary *)params
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
    
    if(!self.deviceTokenId){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    NSString *path = [@"user_api/v1/device_tokens/" stringByAppendingString:[self.deviceTokenId stringValue]];
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager PUT:path parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
            if(self.debugLogging)
                NSLog(@"Did update device with deviceTokenId: %@", self.deviceTokenId);
            
            if(handler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        } else {
            [self _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(self.debugLogging)
            NSLog(@"Failed to update device with deviceTokenId %@: %@", self.deviceTokenId, error);
        
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        
        if (response.statusCode == 404) {
            self.deviceTokenId = nil;
        }
        
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
    
    NSString *path = [NSString stringWithFormat:@"user_api/v1/device_tokens/%@", self.deviceToken];
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager DELETE:path parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
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
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
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
    
    NSString *path = @"user_api/v1/device_tokens/anonymise";
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager PUT:path parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
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
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
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
    
    NSString *path = @"user_api/v1/notification_statuses/opened";
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager PUT:path parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(self.debugLogging)
            NSLog(@"Notification flagged as opened");
        
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [self _markNotificationAsOpenedWithParams:params attempts:(attempts - 1)];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(self.debugLogging)
            NSLog(@"Failed to mark notification as opened");
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _markNotificationAsOpenedWithParams:params attempts:(attempts - 1)];
        });
    }];
    
}

@end

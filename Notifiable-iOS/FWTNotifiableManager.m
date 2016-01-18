//
//  FWTNotifiableManager.m
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWTNotifiableManager.h"

#import "FWTRequestManager.h"
#import "FWTNotifiableAuthenticator.h"

NSString * const FWTNotifiableUserInfoKey           = @"user";
NSString * const FWTNotifiableDeviceTokenKey        = @"token";
NSString * const FWTNotifiableProviderKey           = @"provider";

NSString * const FWTNotifiableDidRegisterWithAPNSNotification       = @"FWTNotifiableDidRegisterWithAPNSNotification";
NSString * const FWTNotifiableFailedToRegisterWithAPNSNotification  = @"FWTNotifiableFailedToRegisterWithAPNSNotification";

NSString * const FWTNotifiableTokenKey                              = @"FWTNotifiableTokenKey";
NSString * const FWTNotifiableTokenIdKey                            = @"FWTNotifiableTokenIdKey";

@interface FWTNotifiableManager ()

@property (nonatomic, readwrite, strong) NSString *deviceToken;
@property (nonatomic, readwrite, strong) NSNumber *deviceTokenId;
@property (nonatomic, strong) FWTRequestManager *requestManager;

@end

@implementation FWTNotifiableManager

@synthesize deviceToken = _deviceToken;
@synthesize deviceTokenId = _deviceTokenId;

- (instancetype)initWithUrl:(NSString *)url
                   accessId:(NSString *)accessId
               andSecretKey:(NSString *)secretKey
{
    self = [super init];
    if (self) {
        FWTNotifiableAuthenticator *authenticator = [[FWTNotifiableAuthenticator alloc] initWithAccessId:accessId
                                                                                            andSecretKey:secretKey];
        self->_requestManager = [[FWTRequestManager alloc] initWithBaseUrl:url andAuthenticator:authenticator];
        self->_retryAttempts = 5;
        self->_retryDelay = 60;
        self->_debugLevel = FWTNotifiableLogLevelError;
    }
    return self;
}

- (NSURL *)baseUrl
{
    return self.requestManager.baseUrl;
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
    } else {
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
    } else {
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
            handler(NO, nil);
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
    self.deviceTokenId = nil;
    [self registerTokenWithUserInfo:userInfo completionHandler:handler];
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
                handler(NO, nil);
            });
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithParams:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
            return;
        }
        
        if(sself.debugLevel == FWTNotifiableLogLevelInfo)
            NSLog(@"Did register for push notifications with token: %@", self.deviceToken);
        
        sself.deviceTokenId = response[@"id"];
        
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(YES, nil);
            });
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        if(weakSelf.debugLevel <= FWTNotifiableLogLevelError)
            NSLog(@"Failed to register device token: %@", error);
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
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
                handler(NO, nil);
            });
        }
        return;
    }
    
    if(!self.deviceTokenId){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, nil);
            });
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager updateDeviceWithTokenId:self.deviceTokenId params:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
            return;
        }
        if(sself.debugLevel == FWTNotifiableLogLevelInfo)
            NSLog(@"Did update device with deviceTokenId: %@", self.deviceTokenId);
        
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(YES, nil);
            });
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        
        __strong typeof(weakSelf) sself = weakSelf;
        if(sself.debugLevel <= FWTNotifiableLogLevelError)
            NSLog(@"Failed to update device with deviceTokenId %@: %@", sself.deviceTokenId, error);
        
        if (responseCode == 404)
            sself.deviceTokenId = nil;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _registerDeviceWithParams:params attempts:(attempts - 1) completionHandler:handler];
        });
    }];
}


- (void)_unregisterTokenWithAttempts:(NSUInteger)attempts
                   completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, nil);
            });
        }
        return;
    }
    
    if(!self.deviceToken){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, nil);
            });
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager unregisterToken:self.deviceToken success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _unregisterTokenWithAttempts:(attempts - 1) completionHandler:handler];
            return;
        }
        
        if(sself.debugLevel == FWTNotifiableLogLevelInfo)
            NSLog(@"Did unregister for push notifications");
        
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(YES, nil);
            });
        }
        
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        if(weakSelf.debugLevel <= FWTNotifiableLogLevelError)
            NSLog(@"Failed to unregister for push notifications");
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _unregisterTokenWithAttempts:(attempts - 1) completionHandler:handler];
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
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager markNotificationAsOpenedWithParams:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _markNotificationAsOpenedWithParams:params attempts:(attempts - 1)];
            return;
        }
        if(sself.debugLevel == FWTNotifiableLogLevelInfo)
            NSLog(@"Notification flagged as opened");
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) sself = weakSelf;
        if(sself.debugLevel <= FWTNotifiableLogLevelError)
            NSLog(@"Failed to mark notification as opened");
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _markNotificationAsOpenedWithParams:params attempts:(attempts - 1)];
        });
    }];
}

@end

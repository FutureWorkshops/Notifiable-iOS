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
#import "NSData+FWTNotifiable.h"

NSString * const FWTNotifiableUserInfoKey       = @"user";
NSString * const FWTNotifiableDeviceTokenKey    = @"token";
NSString * const FWTNotifiableProviderKey       = @"provider";
NSString * const FWTNotifiableUserAliasKey      = @"alias";
NSString * const FWTNotifiableLocaleKey         = @"locale";

NSString * const FWTNotifiableProvider          = @"apns";

NSString * const FWTNotifiableTokenKey          = @"FWTNotifiableTokenKey";
NSString * const FWTNotifiableTokenIdKey        = @"FWTNotifiableTokenIdKey";

@interface FWTNotifiableManager ()

@property (nonatomic, readwrite, strong) NSData *deviceToken;
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

- (NSData *)deviceToken
{
    if(!self->_deviceToken){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self->_deviceToken = [ud objectForKey:FWTNotifiableTokenKey];
    }
    
    return self->_deviceToken;
}

- (void)setDeviceToken:(NSData *)deviceToken
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

- (void)registerAnonymousToken:(NSData *)token
             completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousToken:token
                      withLocale:[NSLocale autoupdatingCurrentLocale]
               completionHandler:handler];
}

-(void)registerAnonymousToken:(NSData *)token withLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _registerDeviceWithUserAlias:nil
                                 token:token
                                locale:locale
                              attempts:self.retryAttempts completionHandler:handler];
}

- (void)registerToken:(NSData *)token withUserAlias:(NSString *)userAlias completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerToken:token
          withUserAlias:userAlias
              andLocale:[NSLocale autoupdatingCurrentLocale]
      completionHandler:handler];
}

- (void)registerToken:(NSData *)token withUserAlias:(NSString *)userAlias andLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _registerDeviceWithUserAlias:userAlias
                                 token:token
                                locale:locale
                              attempts:self.retryAttempts
                     completionHandler:handler];
}

- (void)updateDeviceLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _updateDeviceWithUserAlias:nil
                               token:nil
                              locale:locale
                            attempts:self.retryAttempts
                   completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _updateDeviceWithUserAlias:nil
                               token:token
                              locale:nil
                            attempts:self.retryAttempts
                   completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token andLocation:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _updateDeviceWithUserAlias:nil
                               token:token
                              locale:locale
                            attempts:self.retryAttempts
                   completionHandler:handler];
}

-(void)anonymiseTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    self.deviceTokenId = nil;
    [self _registerDeviceWithUserAlias:nil
                                 token:self.deviceToken
                                locale:nil
                              attempts:self.retryAttempts
                     completionHandler:handler];
}

- (void)associateDeviceToUser:(NSString *)userAlias
            completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _updateDeviceWithUserAlias:userAlias
                               token:nil
                              locale:nil
                            attempts:self.retryAttempts
                   completionHandler:handler];
}

- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self _unregisterTokenWithAttempts:self.retryAttempts completionHandler:handler];
}

- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
{
    NSString *notificationID = notificationInfo[@"notification_id"];
    
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    
    if(notificationID)
        requestParameters[@"notification_id"] = notificationID;
    
    if(self.deviceToken)
        requestParameters[@"device_token"] = @{ FWTNotifiableDeviceTokenKey : self.deviceToken };
    
    [self _markNotificationAsOpenedWithParams:requestParameters attempts:self.retryAttempts];
}

#pragma mark - Private
- (NSDictionary *)_buildParametersForUserAlias:(NSString *)userAlias
                                         token:(NSData *)token
                                        locale:(NSLocale *)locale
                             includingProvider:(BOOL)includeProvider
{
    NSMutableDictionary *params;
    if (includeProvider) {
        params = [@{FWTNotifiableProviderKey: FWTNotifiableProvider} mutableCopy];
    } else {
        params = [[NSMutableDictionary alloc] init];
    }
    if (userAlias) {
        [params addEntriesFromDictionary:@{FWTNotifiableUserInfoKey: @{FWTNotifiableUserAliasKey: userAlias}}];
    }
    if (token) {
        [params setObject:[token fwt_notificationTokenString] forKey:FWTNotifiableTokenKey];
    }
    if (locale) {
        [params setObject:[locale localeIdentifier] forKey:FWTNotifiableLocaleKey];
    }
    return [NSDictionary dictionaryWithDictionary:params];
}

- (void)_registerDeviceWithUserAlias:(NSString *)userAlias
                               token:(NSData *)token
                              locale:(NSLocale *)locale
                            attempts:(NSUInteger)attempts
                   completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    if (self.deviceTokenId) {
        [self _updateDeviceWithUserAlias:userAlias
                                   token:token
                                  locale:locale
                                attempts:attempts
                       completionHandler:handler];
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

    NSDictionary *params = [self _buildParametersForUserAlias:userAlias
                                                        token:token
                                                       locale:locale
                                            includingProvider:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithParams:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _registerDeviceWithUserAlias:userAlias
                                          token:token
                                         locale:locale attempts:(attempts - 1)
                              completionHandler:handler];
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
            [weakSelf _registerDeviceWithUserAlias:userAlias
                                          token:token
                                         locale:locale
                                          attempts:(attempts - 1)
                              completionHandler:handler];
        });
    }];
}


- (void)_updateDeviceWithUserAlias:(NSString *)alias
                             token:(NSData *)token
                            locale:(NSLocale *)locale
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

    NSDictionary *params = [self _buildParametersForUserAlias:alias
                                                        token:token
                                                       locale:locale
                                            includingProvider:NO];
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager updateDeviceWithTokenId:self.deviceTokenId params:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _registerDeviceWithUserAlias:alias
                                          token:token
                                         locale:locale
                                       attempts:(attempts - 1)
                              completionHandler:handler];
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
            [weakSelf _registerDeviceWithUserAlias:alias
                                             token:token
                                            locale:locale
                                          attempts:(attempts - 1)
                                 completionHandler:handler];
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
    
    NSString *token = [self.deviceToken fwt_notificationTokenString];
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager unregisterToken:token success:^(NSDictionary * _Nullable response) {
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

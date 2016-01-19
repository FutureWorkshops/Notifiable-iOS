//
//  FWTNotifiableManager.m
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWTNotifiableManager.h"

#import "FWTHTTPRequester.h"
#import "FWTNotifiableAuthenticator.h"
#import "FWTRequesterManager.h"
#import "FWTNotifiableDevice+Private.h"

NSString * const FWTUserInfoNotifiableCurrentDeviceKey          = @"FWTUserInfoNotifiableCurrentDeviceKey";

@interface FWTNotifiableManager ()

@property (nonatomic, strong) FWTRequesterManager *requestManager;
@property (nonatomic, strong, readwrite, nullable) FWTNotifiableDevice *currentDevice;

@end

@implementation FWTNotifiableManager

@synthesize currentDevice = _currentDevice;

- (instancetype)initWithUrl:(NSString *)url
                   accessId:(NSString *)accessId
               andSecretKey:(NSString *)secretKey
{
    self = [super init];
    if (self) {
        FWTNotifiableAuthenticator *authenticator = [[FWTNotifiableAuthenticator alloc] initWithAccessId:accessId
                                                                                            andSecretKey:secretKey];
        FWTHTTPRequester *requester = [[FWTHTTPRequester alloc] initWithBaseUrl:url andAuthenticator:authenticator];
        self->_requestManager = [[FWTRequesterManager alloc] initWithRequester:requester];
    }
    return self;
}

- (FWTNotifiableDevice *)currentDevice
{
    if (!self->_currentDevice) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        self->_currentDevice = [userDefaults objectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
    }
    return self->_currentDevice;
}

- (void)setCurrentDevice:(FWTNotifiableDevice *)currentDevice
{
    self->_currentDevice = currentDevice;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (self->_currentDevice) {
        [ud setObject:self->_currentDevice forKey:FWTUserInfoNotifiableCurrentDeviceKey];
    } else {
        [ud removeObjectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
    }
    [ud synchronize];
}

- (NSInteger)retryAttempts
{
    return self.requestManager.retryAttempts;
}

- (void)setRetryAttempts:(NSInteger)retryAttempts
{
    self.requestManager.retryAttempts = retryAttempts;
}

-(NSTimeInterval)retryDelay
{
    return self.requestManager.retryDelay;
}

- (void)setRetryDelay:(NSTimeInterval)retryDelay
{
    self.requestManager.retryDelay = retryDelay;
}

- (id<FWTNotifiableLogger>)logger
{
    return self.requestManager.logger;
}

- (void)setLogger:(id<FWTNotifiableLogger>)logger
{
    self.requestManager.logger = logger;
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
    [self registerAnonymousToken:token
                      withLocale:locale
               deviceInformation:@{}
               completionHandler:handler];
}

-(void)registerAnonymousToken:(NSData *)token withLocale:(NSLocale *)locale deviceInformation:(NSDictionary *)deviceInformation completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousToken:token
                      deviceName:nil
                      withLocale:locale
               deviceInformation:deviceInformation
               completionHandler:handler];
}

-(void)registerAnonymousToken:(NSData *)token deviceName:(NSString *)name withLocale:(NSLocale *)locale deviceInformation:(NSDictionary *)deviceInformation completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(token != nil, @"To register a device, a token need to be provided!");
    
    if (self.currentDevice.tokenId) {
        [self updateDeviceToken:token
                     deviceName:nil
                       location:locale
              deviceInformation:deviceInformation
              completionHandler:handler];
    } else {
        [self.requestManager registerDeviceWithUserAlias:nil
                                                   token:token
                                                    name:name
                                                  locale:locale
                                       deviceInformation:deviceInformation
                                       completionHandler:[self _defaultRegisterResponseWithToken:token name:name completionHandler:handler]];
    }
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
    [self registerToken:token
          withUserAlias:userAlias
                 locale:locale
      deviceInformation:@{}
      completionHandler:handler];
}

- (void)registerToken:(NSData *)token withUserAlias:(NSString *)userAlias locale:(NSLocale *)locale deviceInformation:(NSDictionary *)deviceInformation completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerToken:token
             deviceName:nil
          withUserAlias:userAlias
                 locale:locale
      deviceInformation:deviceInformation
      completionHandler:handler];
}

- (void)registerToken:(NSData *)token deviceName:(NSString *)name withUserAlias:(NSString *)userAlias locale:(NSLocale *)locale deviceInformation:(NSDictionary *)deviceInformation completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(token != nil, @"To register a device, a token need to be provided!");
    NSAssert(userAlias.length > 0, @"To register a non anonymous device, a user alias need to be provided!");
    
    if (self.currentDevice.tokenId) {
        [self updateDeviceToken:token
                     deviceName:nil
                      userAlias:userAlias
                       location:locale
              deviceInformation:deviceInformation
              completionHandler:handler];
    } else {
        __weak typeof(self) weakSelf = self;
        [self.requestManager registerDeviceWithUserAlias:userAlias
                                                   token:token
                                                    name:name
                                                  locale:locale
                                       deviceInformation:deviceInformation
                                       completionHandler:[self _defaultRegisterResponseWithToken:token name:name completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                __strong typeof(weakSelf) sself = weakSelf;
                sself.currentDevice = [sself.currentDevice deviceWithUser:userAlias];
            }
        }]];
    }
}

- (void)updateDeviceLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:self.currentDevice.name
                   location:locale
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:self.currentDevice.name
                   location:nil
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token andLocation:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:self.currentDevice.name
                   location:locale
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceName:(NSString *)name
       completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:name
                   location:nil
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
               deviceName:(NSString *)name
                 location:(NSLocale *)locale
        deviceInformation:(NSDictionary *)deviceInformation
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:name
                  userAlias:nil
                   location:locale
          deviceInformation:deviceInformation
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
               deviceName:(NSString *)name
                userAlias:(NSString *)userAlias
                 location:(NSLocale *)locale
        deviceInformation:(NSDictionary *)deviceInformation
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(token != nil || userAlias != nil || locale != nil || deviceInformation != nil, @"The update method was called without any information to update.");
    NSAssert(self.currentDevice.tokenId != nil, @"This device is not registered, please use the method registerToken:withUserAlias:locale:deviceInformation:completionHandler: instead");
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager updateDevice:self.currentDevice.tokenId
                        withUserAlias:userAlias
                                token:token
                                 name:name
                               locale:locale
                    deviceInformation:deviceInformation
                    completionHandler:[self _defaultRegisterResponseWithToken:token name:name completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success && userAlias != nil) {
            __strong typeof(weakSelf) sself = weakSelf;
            sself.currentDevice = [sself.currentDevice deviceWithUser:userAlias];
        }
    }]];
}

-(void)anonymiseTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousToken:self.currentDevice.token
               completionHandler:handler];
}

- (void)associateDeviceToUser:(NSString *)userAlias
            completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(userAlias.length > 0, @"To associate a device, a user alias need to be provided");
    NSAssert(self.currentDevice.token != nil, @"This device is not registered, please use the method registerToken:withUserAlias:completionHandler: instead.");
    
    [self registerToken:self.currentDevice.token
          withUserAlias:userAlias
      completionHandler:handler];
}

- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(self.currentDevice.token, @"This device is not registered.");
    
    [self.requestManager unregisterToken:self.currentDevice.token
                       completionHandler:handler];
}

- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
{
    NSString *notificationID = notificationInfo[@"notification_id"];
    NSAssert(notificationID.length > 0, @"The notification received does not have an id");
    
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    
    if(notificationID)
        requestParameters[@"notification_id"] = notificationID;
    
    [self.requestManager markNotificationAsOpenedOnDevice:self.currentDevice.token
                                               withParams:requestParameters
                                          completionHandler:nil];
}

#pragma mark - Private
- (FWTDeviceTokenIdResponse) _defaultRegisterResponseWithToken:(NSData *)token
                                                          name:(NSString *)name
                                             completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    __weak typeof(self) weakSelf = self;
    return ^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
        if (error == nil) {
            __strong typeof(weakSelf) sself = weakSelf;
            if (sself.currentDevice == nil) {
                sself.currentDevice = [[FWTNotifiableDevice alloc] initWithToken:token tokenId:deviceTokenId];
            } else {
                sself.currentDevice = [sself.currentDevice deviceWithToken:token];
            }
            sself.currentDevice = [sself.currentDevice deviceWithName:name];
        }
        if (handler) {
            handler(error == nil, error);
        }
    };
}

@end

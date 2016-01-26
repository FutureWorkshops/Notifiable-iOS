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
#import "NSError+FWTNotifiable.h"
#import "NSLocale+FWTNotifiable.h"

NSString * const FWTNotifiableDidRegisterDeviceWithAPNSNotification = @"FWTNotifiableDidRegisterDeviceWithAPNSNotification";
NSString * const FWTNotifiableFailedToRegisterDeviceWithAPNSNotification = @"FWTNotifiableFailedToRegisterDeviceWithAPNSNotification";
NSString * const FWTNotifiableApplicationDidRegisterForRemoteNotifications = @"FWTNotifiableApplicationDidRegisterForRemoteNotifications";
NSString * const FWTUserInfoNotifiableCurrentDeviceKey          = @"FWTUserInfoNotifiableCurrentDeviceKey";
NSString * const FWTNotifiableNotificationDevice = @"FWTNotifiableNotificationDevice";
NSString * const FWTNotifiableNotificationError = @"FWTNotifiableNotificationError";
NSString * const FWTNotifiableNotificationDeviceToken = @"FWTNotifiableNotificationDeviceToken";

@interface FWTNotifiableManager ()

@property (nonatomic, strong) FWTRequesterManager *requestManager;
@property (nonatomic, copy, readwrite, nullable) FWTNotifiableDevice *currentDevice;
@property (nonatomic, strong) NSData *deviceTokenData;

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
    @synchronized(self) {
        if (!self->_currentDevice) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSData *deviceData = [userDefaults objectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
            self->_currentDevice = [NSKeyedUnarchiver unarchiveObjectWithData:deviceData];
        }
        return self->_currentDevice;
    }
}

- (void)setCurrentDevice:(FWTNotifiableDevice *)currentDevice
{
    @synchronized(self) {
        self->_currentDevice = currentDevice;
        self->_deviceTokenData = self->_currentDevice.token;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        if (self->_currentDevice) {
            NSData *deviceData = [NSKeyedArchiver archivedDataWithRootObject:self->_currentDevice];
            [ud setObject:deviceData forKey:FWTUserInfoNotifiableCurrentDeviceKey];
        } else {
            [ud removeObjectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
        }
        [ud synchronize];
    }
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

- (void)registerAnonymousDeviceWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(self.deviceTokenData != nil || self.currentDevice != nil, @"The application doesn't have a token to register");
    [self registerAnonymousToken:(self.deviceTokenData ? self.deviceTokenData : self.currentDevice.token)
               completionHandler:handler];
}

- (void)registerAnonymousToken:(NSData *)token
             completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousToken:token
                      withLocale:[NSLocale fwt_autoupdatingCurrentLocale]
               completionHandler:handler];
}

- (void)registerAnonymousToken:(NSData *)token
                    deviceName:(NSString *)deviceName
             completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousToken:token
                      deviceName:deviceName
                      withLocale:[NSLocale fwt_autoupdatingCurrentLocale]
               deviceInformation:@{}
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
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithUserAlias:nil
                                               token:token
                                                name:name
                                              locale:locale
                                   deviceInformation:deviceInformation
                                   completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                       __strong typeof(weakSelf) sself = weakSelf;
                                       sself.currentDevice = nil;
                                       [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:locale name:name andError:error];
                                       sself.currentDevice = [sself.currentDevice deviceWithInformation:deviceInformation];
                                       [sself _notifyNewDevice:sself.currentDevice withError:error];
                                       if (handler) {
                                           handler(sself.currentDevice, error);
                                       }
                                   }];
}

- (void)registerDeviceWithUserAlias:(NSString *)userAlias
                  completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(self.deviceTokenData != nil || self.currentDevice != nil, @"The application doesn't have a token to register");
    [self registerToken:(self.deviceTokenData ? self.deviceTokenData : self.currentDevice.token)
          withUserAlias:userAlias
      completionHandler:handler];
}

- (void)registerToken:(NSData *)token withUserAlias:(NSString *)userAlias completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerToken:token
             deviceName:nil
          withUserAlias:userAlias
                 locale:[NSLocale fwt_autoupdatingCurrentLocale]
      deviceInformation:@{}
      completionHandler:handler];
}

- (void)registerToken:(NSData *)token withUserAlias:(NSString *)userAlias deviceName:(NSString *)deviceName completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerToken:token
             deviceName:deviceName
          withUserAlias:userAlias
                 locale:[NSLocale fwt_autoupdatingCurrentLocale]
      deviceInformation:@{}
      completionHandler:handler];
}

- (void)registerToken:(NSData *)token withUserAlias:(NSString *)userAlias andLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerToken:token
             deviceName:nil
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
    NSAssert(userAlias != nil && userAlias.length > 0, @"To register a non anonymous device, a user alias need to be provided!");
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithUserAlias:userAlias
                                               token:token
                                                name:name
                                              locale:locale
                                   deviceInformation:deviceInformation
                                   completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                       __strong typeof(weakSelf) sself = weakSelf;
                                       sself.currentDevice = nil;
                                       [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:locale name:name andError:error];
                                       sself.currentDevice = [sself.currentDevice deviceWithUser:userAlias name:name andInformation:deviceInformation];
                                       [sself _notifyNewDevice:sself.currentDevice withError:error];
                                       if (handler) {
                                           handler(sself.currentDevice, error);
                                       }
                                   }];
}

- (void)updateDeviceLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:nil
                  userAlias:self.currentDevice.user
                   location:locale
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:nil
                  userAlias:self.currentDevice.user
                   location:nil
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token andLocation:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:nil
                  userAlias:self.currentDevice.user
                   location:locale
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceName:(NSString *)name
       completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:name
                  userAlias:self.currentDevice.user
                   location:nil
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceInformation:(NSDictionary *)deviceInformation
              completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:nil
                  userAlias:self.currentDevice.user
                   location:nil
          deviceInformation:deviceInformation
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
                  userAlias:self.currentDevice.user
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
    NSAssert(token != nil || name != nil || userAlias != nil || locale != nil || deviceInformation != nil, @"The update method was called without any information to update.");
    NSAssert(self.currentDevice.tokenId != nil, @"This device is not registered, please use the method registerToken:withUserAlias:locale:deviceInformation:completionHandler: instead");
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager updateDevice:self.currentDevice.tokenId
                        withUserAlias:userAlias
                                token:token
                                 name:name
                               locale:locale
                    deviceInformation:deviceInformation
                    completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                        __strong typeof(weakSelf) sself = weakSelf;
                        [sself _handleDeviceRegisterWithToken:(token ? token : sself.currentDevice.token)
                                                      tokenId:deviceTokenId
                                                       locale:(locale ? locale : sself.currentDevice.locale)
                                                         name:(name ? name : sself.currentDevice.name)
                                                     andError:error];
                        if (error == nil) {
                            sself.currentDevice = [sself.currentDevice deviceWithUser:(userAlias ? userAlias : sself.currentDevice.user)
                                                                                 name:(name ? name : sself.currentDevice.name)
                                                                       andInformation:(deviceInformation ? deviceInformation : sself.currentDevice.information)];
                        }
                        
                        if (handler) {
                            handler(sself.currentDevice, error);
                        }
                    }];
}

-(void)anonymiseTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(self.currentDevice.token != nil, @"To anonymise the device, first, you need to register it.");
    
    if (self.currentDevice.token == nil) {
        if (handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    [self registerAnonymousToken:self.currentDevice.token
               completionHandler:handler];
}

- (void)associateDeviceToUser:(NSString *)userAlias
            completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(userAlias.length > 0, @"To associate a device, a user alias need to be provided");
    NSAssert(self.currentDevice.token != nil, @"This device is not registered, please use the method registerToken:withUserAlias:completionHandler: instead.");
    
    if (userAlias.length == 0 || self.currentDevice.token == nil) {
        if (handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self registerToken:self.currentDevice.token
             deviceName:self.currentDevice.name
          withUserAlias:userAlias
                 locale:self.currentDevice.locale
      deviceInformation:self.currentDevice.information
      completionHandler:^(FWTNotifiableDevice * _Nullable device, NSError * _Nullable error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself _handleDeviceRegisterWithToken:sself.currentDevice.token
                                      tokenId:sself.currentDevice.tokenId
                                       locale:sself.currentDevice.locale
                                         name:sself.currentDevice.name
                                     andError:error];
        if (error == nil && userAlias != nil) {
            sself.currentDevice = [sself.currentDevice deviceWithUser:userAlias];
        }
        handler(sself.currentDevice, error);
    }];
}

- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(self.currentDevice.token, @"This device is not registered.");
    
    if (self.currentDevice.token == nil) {
        if (handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager unregisterTokenId:self.currentDevice.tokenId
                                 userAlias:self.currentDevice.user
                         completionHandler:^(BOOL success, NSError * _Nullable error) {
                             __strong typeof(weakSelf) sself = weakSelf;
                             if (success) {
                                 sself.currentDevice = nil;
                             }
                             handler(sself.currentDevice, error);
                         }];
}

- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
{
    [self applicationDidReceiveRemoteNotification:notificationInfo
                            withCompletionHandler:nil];
}

- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
                          withCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    NSNumber *notificationID = notificationInfo[@"localized_notification_id"];
    
    if (notificationID == nil) {
        if(handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    if(self.currentDevice == nil) {
        if(handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager markNotificationAsOpened:notificationID
                                          forUser:self.currentDevice.user
                                 andDeviceTokenId:self.currentDevice.tokenId
                            withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
                                if (handler) {
                                    handler(weakSelf.currentDevice, error);
                                }
                            }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
{
    self.deviceTokenData = deviceToken;
    [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableApplicationDidRegisterForRemoteNotifications
                                                        object:self
                                                      userInfo:@{FWTNotifiableNotificationDeviceToken:deviceToken}];
}

- (void)listDevicesRelatedToUserWithCompletionHandler:(FWTNotifiableListOperationCompletionHandler)handler
{
    NSAssert(self.currentDevice != nil, @"The device need to be registered to perform this method.");
    
    if (self.currentDevice == nil) {
        if (handler) {
            handler(@[], [NSError fwt_invalidNotificationError:nil]);
        }
        return;
    }
    
    if (self.currentDevice.user.length == 0) {
        if (handler) {
            handler(@[self.currentDevice], nil);
        }
        return;
    }
    
    [self.requestManager listDevicesOfUser:self.currentDevice.user completionHandler:^(NSArray<FWTNotifiableDevice *> * _Nonnull devices, NSError * _Nullable error) {
        if(handler) {
            handler(devices, error);
        }
    }];
}

#pragma mark - Private
- (FWTDeviceTokenIdResponse) _defaultRegisterResponseWithToken:(NSData *)token
                                                        locale:(NSLocale *)locale
                                                          name:(NSString *)name
                                             completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    __weak typeof(self) weakSelf = self;
    return ^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:locale name:name andError:error];
        sself.currentDevice = [sself.currentDevice deviceWithUser:nil];
        [sself _notifyNewDevice:sself.currentDevice withError:error];
        if (handler) {
            handler(sself.currentDevice, error);
        }
    };
}

- (void) _handleDeviceRegisterWithToken:(NSData *)token
                                tokenId:(NSNumber *)deviceTokenId
                                 locale:(NSLocale *)locale
                                   name:(NSString *)name
                               andError:(NSError *)error
{
    if (error == nil) {
        if (self.currentDevice == nil) {
            self.currentDevice = [[FWTNotifiableDevice alloc] initWithToken:token tokenId:deviceTokenId andLocale:locale];
        } else {
            self.currentDevice = [self.currentDevice deviceWithToken:token andLocale:locale];
        }
        self.currentDevice = [self.currentDevice deviceWithName:name];
    }
}

- (void) _notifyNewDevice:(FWTNotifiableDevice *)device withError:(NSError *)error
{
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableFailedToRegisterDeviceWithAPNSNotification object:self userInfo:@{FWTNotifiableNotificationError: error}];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWTNotifiableDidRegisterDeviceWithAPNSNotification object:self userInfo:@{FWTNotifiableNotificationDevice:device}];
    }
}

@end

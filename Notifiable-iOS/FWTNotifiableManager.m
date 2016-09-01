//
//  FWTNotifiableManager.m
//  FWTNotifiable
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWTNotifiableManager.h"

#import "FWTHTTPRequester.h"
#import "FWTNotifiableAuthenticator.h"
#import "FWTRequesterManager.h"
#import "FWTNotifiableDevice+Private.h"
#import "NSError+FWTNotifiable.h"
#import "NSLocale+FWTNotifiable.h"

NSString * const FWTUserInfoNotifiableCurrentDeviceKey          = @"FWTUserInfoNotifiableCurrentDeviceKey";
NSString * const FWTNotifiableNotificationDevice = @"FWTNotifiableNotificationDevice";
NSString * const FWTNotifiableNotificationError = @"FWTNotifiableNotificationError";
NSString * const FWTNotifiableNotificationDeviceToken = @"FWTNotifiableNotificationDeviceToken";

static NSHashTable *listeners;
static NSData * tokenDataBuffer;

@interface FWTNotifiableManager () <FWTNotifiableManagerListener>

@property (nonatomic, strong) FWTRequesterManager *requestManager;
@property (nonatomic, copy, readwrite, nullable) FWTNotifiableDevice *currentDevice;
@property (nonatomic, strong) NSData *deviceTokenData;
@property (nonatomic, strong) NSNotificationCenter *notificationCenter;
@property (nonatomic, copy) FWTNotifiableDidRegisterBlock registerBlock;
@property (nonatomic, copy) FWTNotifiableDidReceiveNotificationBlock notificationBlock;

@end

@implementation FWTNotifiableManager

@synthesize currentDevice = _currentDevice;

- (instancetype)initWithURL:(NSURL *)url
                   accessId:(NSString *)accessId
                  secretKey:(NSString *)secretKey
           didRegisterBlock:(FWTNotifiableDidRegisterBlock)registerBlock
       andNotificationBlock:(FWTNotifiableDidReceiveNotificationBlock)notificationBlock
{
    self = [super init];
    if (self) {
        self->_registerBlock = registerBlock;
        self->_notificationBlock = notificationBlock;
        
        FWTNotifiableAuthenticator *authenticator = [[FWTNotifiableAuthenticator alloc] initWithAccessId:accessId
                                                                                            andSecretKey:secretKey];
        FWTHTTPRequester *requester = [[FWTHTTPRequester alloc] initWithBaseURL:url
                                                               andAuthenticator:authenticator];
        self->_requestManager = [[FWTRequesterManager alloc] initWithRequester:requester];
        self->_deviceTokenData = tokenDataBuffer;
        [FWTNotifiableManager registerManagerListener:self];
    }
    return self;
}

+ (NSHashTable *)listenerTable
{
    if (listeners == nil) {
        listeners = [NSHashTable weakObjectsHashTable];
    }
    return listeners;
}

+ (void) operateOnListenerTableOnBackground:(void(^)(NSHashTable *table))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSHashTable *table = [FWTNotifiableManager listenerTable];
        @synchronized(table) {
            block(table);
        }
    });
}

- (NSNotificationCenter *)notificationCenter
{
    if (self->_notificationCenter == nil) {
        self->_notificationCenter = [NSNotificationCenter defaultCenter];
    }
    return self->_notificationCenter;
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

#pragma mark - Public static methods

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


+ (void)registerManagerListener:(id<FWTNotifiableManagerListener>)listener
{
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table) {
        if (![table containsObject:listener]) {
            [table addObject:listener];
        }
    }];
}

+ (void)unregisterManagerListener:(id<FWTNotifiableManagerListener>)listener
{
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table) {
        if ([table containsObject:listener]) {
            [table removeObject:listener];
        }
    }];
}

+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
{
    tokenDataBuffer = deviceToken;
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table) {
        for (id object in table) {
            if ([object conformsToProtocol:@protocol(FWTNotifiableManagerListener)] && [object respondsToSelector:@selector(applicationDidRegisterForRemoteNotificationsWithToken:)]) {
                [object applicationDidRegisterForRemoteNotificationsWithToken:deviceToken];
            }
        }
    }];
}

#pragma mark - Public methods

-(void)registerAnonymousDeviceWithName:(NSString *)name
                                locale:(NSLocale *)locale
                     deviceInformation:(NSDictionary *)deviceInformation
                  andCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSData *token = self.deviceTokenData;
    
    NSAssert(token != nil, @"Before register the device, make sure that you registered the device for remote notifications");
    if (token == nil) {
        if (handler) {
            handler(nil, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    NSLocale *deviceLocale = locale ?: [NSLocale fwt_autoupdatingCurrentLocale];
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithUserAlias:nil
                                               token:token
                                                name:name
                                              locale:(locale ?: [NSLocale fwt_autoupdatingCurrentLocale])
                                   deviceInformation:deviceInformation
                                   completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                       __strong typeof(weakSelf) sself = weakSelf;
                                       sself.currentDevice = nil;
                                       [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:deviceLocale name:name andError:error];
                                       sself.currentDevice = [sself.currentDevice deviceWithInformation:deviceInformation];
                                       [sself _notifyNewDevice:sself.currentDevice withError:error];
                                       if (handler) {
                                           handler(sself.currentDevice, error);
                                       }
                                   }];
}

- (void)registerDeviceWithName:(NSString *)name
                     userAlias:(NSString *)userAlias
                        locale:(NSLocale *)locale
             deviceInformation:(NSDictionary *)deviceInformation
          andCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(userAlias != nil && userAlias.length > 0, @"To register a non anonymous device, a user alias need to be provided!");
    NSData *token = self.deviceTokenData;
    
    NSAssert(token != nil, @"Before register the device, make sure that you registered the device for remote notifications");
    if (token == nil) {
        if (handler) {
            handler(nil, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return;
    }
    
    NSLocale *deviceLocale = locale ?: [NSLocale fwt_autoupdatingCurrentLocale];
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithUserAlias:userAlias
                                               token:token
                                                name:name
                                              locale:(locale ?: [NSLocale fwt_autoupdatingCurrentLocale])
                                   deviceInformation:deviceInformation
                                   completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                       __strong typeof(weakSelf) sself = weakSelf;
                                       sself.currentDevice = nil;
                                       [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:deviceLocale name:name andError:error];
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
    
    [self registerAnonymousDeviceWithName:self.currentDevice.name
                                   locale:nil
                        deviceInformation:nil
                     andCompletionHandler:handler];
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
    [self registerDeviceWithName:self.currentDevice.name
                       userAlias:userAlias
                          locale:self.currentDevice.locale
               deviceInformation:self.currentDevice.information
            andCompletionHandler:^(FWTNotifiableDevice * _Nullable device, NSError * _Nullable error) {
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

+ (BOOL)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
{
    NSNumber *notificationID = notificationInfo[@"localized_notification_id"];
    
    if (notificationID == nil) {
        return NO;
    }
    
    NSDictionary *notificationCopy = [notificationInfo copy];
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table) {
        for(id listener in table) {
            if ([listener conformsToProtocol:@protocol(FWTNotifiableManagerListener)] && [listener respondsToSelector:@selector(applicationDidReciveNotification:)]) {
                [listener applicationDidReciveNotification:notificationCopy];
            }
        }
    }];
    
    return YES;
}

- (BOOL)markNotificationAsOpened:(NSDictionary *)notificationInfo
           withCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    NSNumber *notificationID = notificationInfo[@"localized_notification_id"];
    
    if (notificationID == nil) {
        if(handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return NO;
    }
    
    if(self.currentDevice == nil) {
        if(handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return NO;
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
    return YES;
}

- (void)listDevicesRelatedToUserWithCompletionHandler:(FWTNotifiableListOperationCompletionHandler)handler
{
    NSAssert(self.currentDevice != nil, @"The device need to be registered to perform this method.");
    
    if (self.currentDevice == nil) {
        if (handler) {
            handler(@[], [NSError fwt_invalidDeviceInformationError:nil]);
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

#pragma mark - FWTManagerListener
- (void)applicationDidRegisterForRemoteNotificationsWithToken:(NSData *)token
{
    self.deviceTokenData = token;
    if (self.registerBlock) {
        self.registerBlock(self, token);
    }
}

- (void)applicationDidReciveNotification:(NSDictionary *)notification
{
    @synchronized(self) {
        [self markNotificationAsOpened:notification
                 withCompletionHandler:nil];
        if (self.notificationBlock) {
            self.notificationBlock(self, self.currentDevice, notification);
        }
    }
}

#pragma mark - Private
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
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table) {
        for (id listener in table) {
            if (![listener conformsToProtocol:@protocol(FWTNotifiableManagerListener)]) {
                continue;
            }
            
            if (error) {
                if ([listener respondsToSelector:@selector(notifiableManager:didFailToRegisterDeviceWithError:)]) {
                    [listener notifiableManager:self didFailToRegisterDeviceWithError:error];
                }
            } else {
                if ([listener respondsToSelector:@selector(notifiableManager:didRegisterDevice:)]) {
                    [listener notifiableManager:self didRegisterDevice:device];
                }
            }
        }
    }];
}

@end

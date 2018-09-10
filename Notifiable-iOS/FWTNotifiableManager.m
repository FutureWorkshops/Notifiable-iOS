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

static NSHashTable *managerListeners;
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
        
        // register self as listener
        [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
            [managerTable addObject:self];
        }];
    }
    return self;
}

- (void)dealloc
{
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        if ([managerTable containsObject:self]) {
            [managerTable removeObject:self];
        }
    }];
}

+ (NSHashTable *)listenerTable
{
    __block NSHashTable* table;
    @synchronized(self) {
        if (listeners == nil) {
            listeners = [NSHashTable weakObjectsHashTable];
        }
        table = listeners;
    }
    return table;
}

+ (NSHashTable *)managerListenerTable
{
    __block NSHashTable* table;
    @synchronized(self) {
        if (managerListeners == nil) {
            managerListeners = [NSHashTable weakObjectsHashTable];
        }
        table = managerListeners;
    }
    return table;
}

+ (void) operateOnListenerTableOnBackground:(void(^)(NSHashTable *table, NSHashTable *managerTable))block
{
    NSHashTable *table = [FWTNotifiableManager listenerTable];
    NSHashTable *managerTable = [FWTNotifiableManager managerListenerTable];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @synchronized(table) {
            block(table, managerTable);
        }
    });
}

+ (void) cleanUp
{
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        [table removeAllObjects];
        [managerTable removeAllObjects];
    }];
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
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        if (![table containsObject:listener]) {
            [table addObject:listener];
        }
    }];
}

+ (void)unregisterManagerListener:(id<FWTNotifiableManagerListener>)listener
{
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        if ([table containsObject:listener]) {
            [table removeObject:listener];
        }
    }];
}

+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
{
    tokenDataBuffer = deviceToken;
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        void (^performWithObject)(id) = ^(id object) {
            if ([object conformsToProtocol:@protocol(FWTNotifiableManagerListener)] && [object respondsToSelector:@selector(applicationDidRegisterForRemoteNotificationsWithToken:)]) {
                [object applicationDidRegisterForRemoteNotificationsWithToken:deviceToken];
            }
        };
        for (id object in managerTable) {
            performWithObject(object);
        }
        for (id object in table) {
            performWithObject(object);
        }
    }];
}

#pragma mark - Public methods

-(void)registerAnonymousDeviceWithName:(NSString *)name
                                locale:(NSLocale *)locale
                      customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
                  andCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousDeviceWithName:name
                                   locale:locale
                         customProperties:customProperties
                       platformProperties:nil
                     andCompletionHandler:handler];
}

-(void)registerAnonymousDeviceWithName:(NSString *)name
                                locale:(NSLocale *)locale
                      customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
                    platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
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
    
    NSLocale *deviceLocale = locale ?: [NSLocale fwt_currentLocale];
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithUserAlias:nil
                                               token:token
                                                name:name
                                              locale:deviceLocale
                                    customProperties:customProperties
                                  platformProperties:platformProperties
                                   completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                       __strong typeof(weakSelf) sself = weakSelf;
                                       sself.currentDevice = nil;
                                       [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:deviceLocale name:name andError:error];
                                       sself.currentDevice = [sself.currentDevice deviceWithCustomProperties:customProperties];
                                       [sself _notifyNewDevice:sself.currentDevice withError:error];
                                       if (handler) {
                                           handler(sself.currentDevice, error);
                                       }
                                   }];
}

- (void)registerDeviceWithName:(NSString *)name
                     userAlias:(NSString *)userAlias
                        locale:(NSLocale *)locale
              customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
          andCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerDeviceWithName:name
                       userAlias:userAlias
                          locale:locale
                customProperties:customProperties
              platformProperties:nil
            andCompletionHandler:handler];
}

- (void)registerDeviceWithName:(NSString *)name
                     userAlias:(NSString *)userAlias
                        locale:(NSLocale *)locale
              customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
            platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
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
    
    NSLocale *deviceLocale = locale ?: [NSLocale fwt_currentLocale];
    __weak typeof(self) weakSelf = self;
    [self.requestManager registerDeviceWithUserAlias:userAlias
                                               token:token
                                                name:name
                                              locale:deviceLocale
                                    customProperties:customProperties
                                  platformProperties:platformProperties
                                   completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                       __strong typeof(weakSelf) sself = weakSelf;
                                       sself.currentDevice = nil;
                                       [sself _handleDeviceRegisterWithToken:token tokenId:deviceTokenId locale:deviceLocale name:name andError:error];
                                       sself.currentDevice = [sself.currentDevice deviceWithUser:userAlias name:name customProperties:customProperties];
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
                     locale:locale
           customProperties:nil
         platformProperties:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:nil
                  userAlias:self.currentDevice.user
                   locale:nil
           customProperties:nil
         platformProperties:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token andLocation:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:nil
                  userAlias:self.currentDevice.user
                   locale:locale
           customProperties:nil
         platformProperties:nil
          completionHandler:handler];
}

- (void)updateDeviceName:(NSString *)name
       completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:name
                  userAlias:self.currentDevice.user
                     locale:nil
           customProperties:nil
         platformProperties:nil
          completionHandler:handler];
}

- (void)updateCustomProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:nil
                  userAlias:self.currentDevice.user
                     locale:nil
           customProperties:customProperties
         platformProperties:nil
          completionHandler:handler];
}

- (void)updatePlatformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
                completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                 deviceName:nil
                  userAlias:self.currentDevice.user
                     locale:nil
           customProperties:nil
         platformProperties:platformProperties
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
               deviceName:(NSString *)name
                   locale:(NSLocale *)locale
         customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken: token
                 deviceName:name
                     locale:locale
           customProperties:customProperties
         platformProperties:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
               deviceName:(NSString *)name
                 locale:(NSLocale *)locale
         customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
       platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:name
                  userAlias:self.currentDevice.user
                   locale:locale
           customProperties:customProperties
         platformProperties:platformProperties
          completionHandler:handler];
}


- (void)updateDeviceToken:(NSData *)token
               deviceName:(NSString *)name
                userAlias:(NSString *)userAlias
                   locale:(NSLocale *)locale
         customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                 deviceName:name
                     locale:locale
           customProperties:customProperties
         platformProperties:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
               deviceName:(NSString *)name
                userAlias:(NSString *)userAlias
                 locale:(NSLocale *)locale
         customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
       platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(token != nil || name != nil || userAlias != nil || locale != nil || customProperties != nil, @"The update method was called without any information to update.");
    NSAssert(self.currentDevice.tokenId != nil, @"This device is not registered, please use the method registerToken:withUserAlias:locale:customProperties:completionHandler: instead");
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager updateDevice:self.currentDevice.tokenId
                        withUserAlias:userAlias
                                token:token
                                 name:name
                               locale:locale
                     customProperties:customProperties
                   platformProperties:platformProperties
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
                                                                     customProperties:(customProperties ?: sself.currentDevice.customProperties)];
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
                         customProperties:nil
                       platformProperties:nil
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
                customProperties:self.currentDevice.customProperties
              platformProperties:self.currentDevice.platformProperties
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

- (void)unregisterTokenWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
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
                         completionHandler:^(BOOL success, NSError * _Nullable error) {
                             __strong typeof(weakSelf) sself = weakSelf;
                             FWTNotifiableDevice *responseDevice;
                             if (success) {
                                 sself.currentDevice = nil;
                                 responseDevice = nil;
                             } else {
                                 responseDevice = sself.currentDevice;
                             }
                             if (handler) {
                                 handler(responseDevice, error);
                             }
                         }];
}

+ (BOOL)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
{
    NSNumber *notificationID = notificationInfo[@"n_id"];
    
    if (notificationID == nil) {
        return NO;
    }
    
    NSDictionary *notificationCopy = [notificationInfo copy];
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        void (^performWithListener)(id) = ^(id listener) {
            if ([listener conformsToProtocol:@protocol(FWTNotifiableManagerListener)] && [listener respondsToSelector:@selector(applicationDidReciveNotification:)]) {
                [listener applicationDidReciveNotification:notificationCopy];
            }
        };
        for (id listener in managerTable) {
            performWithListener(listener);
        }
        for(id listener in table) {
            performWithListener(listener);
        }
    }];
    
    return YES;
}

- (BOOL)markNotificationAsOpened:(NSDictionary *)notificationInfo
           withCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    NSNumber *notificationID = notificationInfo[@"n_id"];
    
    if (![self _isNotificationValid:notificationID]) {
        if(handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager markNotificationAsOpenedWithId:notificationID
                                          deviceTokenId:self.currentDevice.tokenId
                                                   user:self.currentDevice.user
                                      completionHandler:^(BOOL success, NSError * _Nullable error) {
                                          if (handler) {
                                              handler(weakSelf.currentDevice, error);
                                          }
                                      }];
    return YES;
}

- (BOOL)_markNotificationAsReceived:(NSDictionary *)notificationInfo
             withCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler
{
    NSNumber *notificationID = notificationInfo[@"n_id"];
    
    if (![self _isNotificationValid:notificationID]) {
        if(handler) {
            handler(self.currentDevice, [NSError fwt_invalidDeviceInformationError:nil]);
        }
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requestManager markNotificationAsReceivedWithId:notificationID
                                            deviceTokenId:self.currentDevice.tokenId
                                        completionHandler:^(BOOL success, NSError * _Nullable error) {
                                            if (handler) {
                                                handler(weakSelf.currentDevice, error);
                                            }
                                        }];
    return YES;
}

- (BOOL) _isNotificationValid:(NSNumber *)notificationID {
    if (notificationID == nil) {
        return NO;
    }
    
    if(self.currentDevice == nil) {
        return NO;
    }
    
    if (self.currentDevice.user.length == 0 || self.currentDevice.tokenId == nil) {
        return NO;
    }
    
    return YES;
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
        [self _markNotificationAsReceived:notification
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
            self.currentDevice = [self.currentDevice deviceWithToken:token locale:locale];
        }
        self.currentDevice = [self.currentDevice deviceWithName:name];
    }
}

- (void) _notifyNewDevice:(FWTNotifiableDevice *)device withError:(NSError *)error
{
    [FWTNotifiableManager operateOnListenerTableOnBackground:^(NSHashTable *table, NSHashTable *managerTable) {
        void (^performWithListener)(id) = ^(id listener) {
            if (![listener conformsToProtocol:@protocol(FWTNotifiableManagerListener)]) {
                return;
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
        };
        for (id listener in managerTable) {
            performWithListener(listener);
        }
        for (id listener in table) {
            performWithListener(listener);
        }
    }];
}

@end

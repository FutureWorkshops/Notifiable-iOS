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
#import "FWTServerConfiguration.h"
#import "NSUserDefaults+FWTNotifiable.h"
#import "FWTNotifiableLogger.h"

NSString * const FWTNotifiableNotificationError = @"FWTNotifiableNotificationError";

static NSHashTable *managerListeners;
static NSHashTable *listeners;
static NSData * tokenDataBuffer;
static FWTRequesterManager *sharedRequesterManager;

@interface FWTNotifiableManager () <FWTNotifiableManagerListener>

@property (nonatomic, copy, readwrite, nullable) FWTNotifiableDevice *currentDevice;
@property (nonatomic, strong) NSData *deviceTokenData;
@property (nonatomic, strong) NSNotificationCenter *notificationCenter;
@property (nonatomic, copy) FWTNotifiableDidRegisterBlock registerBlock;
@property (nonatomic, copy) FWTNotifiableDidReceiveNotificationBlock notificationBlock;
@property (nonatomic, strong, readonly) NSString *groupId;
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

@end

@implementation FWTNotifiableManager

@synthesize currentDevice = _currentDevice;
@synthesize userDefaults = _userDefaults;

+ (FWTRequesterManager *)requestManagerWithUserDefaults:(NSUserDefaults *)userDefaults
{
    if (sharedRequesterManager == nil) {
        FWTNotifiableAuthenticator *authenticator = [[FWTNotifiableAuthenticator alloc] initWithAccessId:[FWTNotifiableManager serverAccessIdWithUserDefaults:userDefaults]
                                                                                            andSecretKey:[FWTNotifiableManager serverSecretKeyWithUserDefaults:userDefaults]];
        FWTHTTPRequester *requester = [[FWTHTTPRequester alloc] initWithBaseURL:[FWTNotifiableManager serverURLWithUserDefaults:userDefaults]
                                                               andAuthenticator:authenticator];
        sharedRequesterManager = [[FWTRequesterManager alloc] initWithRequester:requester];
    }
    return sharedRequesterManager;
}

+ (FWTServerConfiguration *)savedConfigurationWithUserDefaults:(NSUserDefaults *)userDefaults
{
    FWTServerConfiguration *configuration = [userDefaults storedConfiguration];
    return configuration;
}

+ (NSURL *) serverURLWithUserDefaults:(NSUserDefaults *)userDefaults
{
    return [self savedConfigurationWithUserDefaults:userDefaults].serverURL;
}

+ (NSString *) serverAccessIdWithUserDefaults:(NSUserDefaults *)userDefaults
{
    return [self savedConfigurationWithUserDefaults:userDefaults].serverAccessId;
}

+ (NSString *) serverSecretKeyWithUserDefaults:(NSUserDefaults *)userDefaults
{
    return [self savedConfigurationWithUserDefaults:userDefaults].serverSecretKey;
}

+ (FWTNotifiableDevice *)storedDeviceWithUserDefaults:(NSUserDefaults *)userDefaults {
    FWTNotifiableDevice *currentDevice = [userDefaults storedDevice];
    return currentDevice;
}

+ (void) configureWithURL:(NSURL *)url
                 accessId:(NSString *)accessId
                secretKey:(NSString *)secretKey
{
    [self configureWithURL:url
                  accessId:accessId
                 secretKey:secretKey
                   groupId:nil];
}

+ (void) configureWithURL:(NSURL *)url
                 accessId:(NSString *)accessId
                secretKey:(NSString *)secretKey
                  groupId:(NSString * _Nullable)groupId
{
    FWTServerConfiguration *configuration = [[FWTServerConfiguration alloc] initWithServerURL:url
                                                                                     accessId:accessId
                                                                                 andSecretKey:secretKey];
    [[NSUserDefaults userDefaultsWithGroupId:groupId] storeConfiguration:configuration];
}

- (instancetype)initWithURL:(NSURL *)url
                   accessId:(NSString *)accessId
                  secretKey:(NSString *)secretKey
           didRegisterBlock:(FWTNotifiableDidRegisterBlock)registerBlock
       andNotificationBlock:(FWTNotifiableDidReceiveNotificationBlock)notificationBlock
{
    [FWTNotifiableManager configureWithURL:url
                                  accessId:accessId
                                 secretKey:secretKey];
    return [self initWithDidRegisterBlock:registerBlock andNotificationBlock:notificationBlock];
}

- (instancetype)initWithDidRegisterBlock:(_Nullable FWTNotifiableDidRegisterBlock)registerBlock
                    andNotificationBlock:(_Nullable FWTNotifiableDidReceiveNotificationBlock)notificationBlock
{
    return [self initWithGroupId:nil didRegisterBlock:registerBlock andNotificationBlock:notificationBlock];
}

- (instancetype)initWithGroupId:(NSString * _Nullable)group
               didRegisterBlock:(_Nullable FWTNotifiableDidRegisterBlock)registerBlock
           andNotificationBlock:(_Nullable FWTNotifiableDidReceiveNotificationBlock)notificationBlock
{
    self = [super init];
    if (self) {
        self->_registerBlock = registerBlock;
        self->_notificationBlock = notificationBlock;
        self->_groupId = group;
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

- (NSUserDefaults *)userDefaults {
    if (self->_userDefaults == nil) {
        self->_userDefaults = [NSUserDefaults userDefaultsWithGroupId:self.groupId];
    }
    return self->_userDefaults;
}

- (FWTNotifiableDevice *)currentDevice
{
    @synchronized(self) {
        if (!self->_currentDevice) {
            NSUserDefaults *userDefaults = self.userDefaults;
            self->_currentDevice = [userDefaults storedDevice];
        }
        return self->_currentDevice;
    }
}

- (void)setCurrentDevice:(FWTNotifiableDevice *)currentDevice
{
    @synchronized(self) {
        self->_currentDevice = currentDevice;
        self->_deviceTokenData = self->_currentDevice.token;
        if (self->_currentDevice) {
            [self.userDefaults storeDevice:self->_currentDevice];
        } else {
            [self.userDefaults clearStoredDevice];
        }
    }
}

- (NSInteger)retryAttempts
{
    return [FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults].retryAttempts;
}

- (void)setRetryAttempts:(NSInteger)retryAttempts
{
    [FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults].retryAttempts = retryAttempts;
}

-(NSTimeInterval)retryDelay
{
    return [FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults].retryDelay;
}

- (void)setRetryDelay:(NSTimeInterval)retryDelay
{
    [FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults].retryDelay = retryDelay;
}

- (id<FWTNotifiableLogger>)logger
{
    return [FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults].logger;
}

- (void)setLogger:(id<FWTNotifiableLogger>)logger
{
    [FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults].logger = logger;
}

#pragma mark - Public static methods

+ (void) syncronizeDataWithGroupId:(NSString *)groupId
{
    [[NSUserDefaults standardUserDefaults] syncronizeToGroupId:groupId];
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
    [[FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults] registerDeviceWithUserAlias:nil
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
    [[FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults] registerDeviceWithUserAlias:userAlias
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
    [[FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults] updateDevice:self.currentDevice.tokenId
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
    [[FWTNotifiableManager requestManagerWithUserDefaults:self.userDefaults] unregisterTokenId:self.currentDevice.tokenId
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
    [FWTNotifiableManager markNotificationAsReceived:notificationInfo withCompletionHandler:nil];
    return [FWTNotifiableManager isValidNotification:notificationInfo];
}

+ (BOOL)isValidNotification:(NSDictionary *)notificationInfo
{
    NSNumber *notificationID = notificationInfo[@"n_id"];
    
    if (notificationID == nil) {
        return NO;
    }
    
    return YES;
}

- (BOOL)markNotificationAsOpened:(NSDictionary *)notificationInfo
           withCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler NS_SWIFT_NAME(markAsOpen(notification:completion:))
{
    __weak typeof(self) weakSelf = self;
    return [FWTNotifiableManager markNotificationAsOpened:notificationInfo withCompletionHandler:^(NSError * _Nullable error) {
        if (handler) {
            handler(weakSelf.currentDevice, error);
        }
    }];
}

+ (BOOL)markNotificationAsOpened:(NSDictionary *)notificationInfo
           withCompletionHandler:(nullable void(^)(NSError * _Nullable))handler
{
    return [self markNotificationAsOpened:notificationInfo
                                  groupId:nil
                    withCompletionHandler:handler];
}

+ (BOOL)markNotificationAsOpened:(NSDictionary *)notificationInfo
                         groupId:(NSString * _Nullable)groupId
           withCompletionHandler:(nullable void(^)(NSError * _Nullable))handler
{
    NSUserDefaults *userDefaults = [NSUserDefaults userDefaultsWithGroupId:groupId];
    NSNumber *notificationID = notificationInfo[@"n_id"];
    FWTNotifiableDevice *device = [self storedDeviceWithUserDefaults:userDefaults];
    NSNumber *tokenId = device.tokenId;
    NSString *user = device.user;
    
    FWTRequesterManager *requestManager = [FWTNotifiableManager requestManagerWithUserDefaults:userDefaults];
    [[requestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogReceived
                            forNotificationWithId:notificationID
                                            error: nil];
    
    if (tokenId == nil || notificationID == nil || user == nil) {
        if(handler) {
            handler([NSError fwt_invalidDeviceInformationError:nil]);
        }
        [[requestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogStatusFailure
                                forNotificationWithId:notificationID
                                                error:[NSError fwt_invalidDeviceInformationError:nil]];
        return NO;
    }
    
    __weak typeof(requestManager) weakRequestManager = requestManager;
    [requestManager markNotificationAsOpenedWithId:notificationID
                                     deviceTokenId:tokenId
                                              user:user
                                 completionHandler:^(BOOL success, NSError * _Nullable error) {
                                     if (success) {
                                         [[weakRequestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogStatusUpdate
                                                                     forNotificationWithId:notificationID
                                                                                     error: nil];
                                     } else {
                                         [[weakRequestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogStatusFailure
                                                                     forNotificationWithId:notificationID
                                                                                     error:error];
                                     }
                                     
                                     if (handler) {
                                         handler(error);
                                     }
                                 }];
    return YES;
}

+ (BOOL)markNotificationAsReceived:(NSDictionary *)notificationInfo
             withCompletionHandler:(nullable void(^)(NSError * _Nullable error))handler
{
    return [self markNotificationAsReceived:notificationInfo
                                    groupId:nil
                      withCompletionHandler:handler];
}

+ (BOOL)markNotificationAsReceived:(NSDictionary *)notificationInfo
                           groupId:(NSString * _Nullable)groupId
             withCompletionHandler:(nullable void(^)(NSError * _Nullable error))handler
{
    NSUserDefaults *userDefaults = [NSUserDefaults userDefaultsWithGroupId:groupId];
    NSNumber *notificationID = notificationInfo[@"n_id"];
    NSNumber *deviceTokenId = [self storedDeviceWithUserDefaults:userDefaults].tokenId;
    
    FWTRequesterManager *requestManager = [FWTNotifiableManager requestManagerWithUserDefaults:userDefaults];
    [[requestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogReceived
                            forNotificationWithId:notificationID
                                            error:nil];
    
    if (deviceTokenId == nil || notificationID == nil) {
        if(handler) {
            handler([NSError fwt_invalidDeviceInformationError:nil]);
        }
        [[requestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogStatusFailure
                                forNotificationWithId:notificationID
                                                error:[NSError fwt_invalidDeviceInformationError:nil]];
        return NO;
    }
    
    __weak typeof(requestManager) weakRequestManager = requestManager;
    [requestManager markNotificationAsReceivedWithId:notificationID
                                       deviceTokenId:deviceTokenId
                                   completionHandler:^(BOOL success, NSError * _Nullable error) {
                                       
                                       if (success) {
                                           [[weakRequestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogStatusUpdate
                                                                       forNotificationWithId:notificationID
                                                                                       error:nil];
                                       } else {
                                           [[weakRequestManager logger] logNotificationEvent:FWTNotifiableNotificationEventLogStatusFailure
                                                                       forNotificationWithId:notificationID
                                                                                       error:error];
                                       }
                                       
                                       if (handler) {
                                           handler(error);
                                       }
                                   }];
    
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

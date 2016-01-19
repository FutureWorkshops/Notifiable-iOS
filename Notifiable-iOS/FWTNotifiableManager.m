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

NSString * const FWTUserInfoNotifiableTokenKey          = @"FWTNotifiableTokenKey";
NSString * const FWTUserInfoNotifiableTokenIdKey        = @"FWTNotifiableTokenIdKey";

@interface FWTNotifiableManager ()

@property (nonatomic, strong) FWTRequesterManager *requestManager;
@property (nonatomic, readwrite, strong) NSData *deviceToken;
@property (nonatomic, readwrite, strong) NSNumber *deviceTokenId;

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
        FWTHTTPRequester *requester = [[FWTHTTPRequester alloc] initWithBaseUrl:url andAuthenticator:authenticator];
        self->_requestManager = [[FWTRequesterManager alloc] initWithRequester:requester];
    }
    return self;
}

- (NSData *)deviceToken
{
    if(!self->_deviceToken){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self->_deviceToken = [ud objectForKey:FWTUserInfoNotifiableTokenKey];
    }
    
    return self->_deviceToken;
}

- (void)setDeviceToken:(NSData *)deviceToken
{
    self->_deviceToken = deviceToken;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (deviceToken) {
        [ud setObject:deviceToken forKey:FWTUserInfoNotifiableTokenKey];
    } else {
        [ud removeObjectForKey:FWTUserInfoNotifiableTokenKey];
    }
}

- (NSNumber *)deviceTokenId
{
    if(!self->_deviceTokenId){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self->_deviceTokenId = [ud objectForKey:FWTUserInfoNotifiableTokenIdKey];
    }
    
    return self->_deviceTokenId;
}

- (void)setDeviceTokenId:(NSNumber *)deviceTokenId
{
    self->_deviceTokenId = deviceTokenId;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (deviceTokenId) {
        [ud setObject:deviceTokenId forKey:FWTUserInfoNotifiableTokenIdKey];
    } else {
        [ud removeObjectForKey:FWTUserInfoNotifiableTokenIdKey];
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
    NSAssert(token != nil, @"To register a device, a token need to be provided!");
    
    if (self.deviceTokenId) {
        [self updateDeviceToken:token
                    andLocation:locale
              deviceInformation:deviceInformation
              completionHandler:handler];
    } else {
        [self.requestManager registerDeviceWithUserAlias:nil
                                                   token:token
                                                  locale:locale
                                       deviceInformation:deviceInformation
                                       completionHandler:[self _defaultRegisterResponseWithToken:token completionHandler:handler]];
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
    NSAssert(token != nil, @"To register a device, a token need to be provided!");
    NSAssert(userAlias.length > 0, @"To register a non anonymous device, a user alias need to be provided!");
    
    if (self.deviceTokenId) {
        [self updateDeviceToken:token
                      userAlias:userAlias
                    andLocation:locale
              deviceInformation:deviceInformation
              completionHandler:handler];
    } else {
        [self.requestManager registerDeviceWithUserAlias:userAlias
                                                   token:token
                                                  locale:locale
                                       deviceInformation:deviceInformation
                                       completionHandler:[self _defaultRegisterResponseWithToken:token completionHandler:handler]];
    }
}

- (void)updateDeviceLocale:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:nil
                andLocation:locale
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                andLocation:nil
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token andLocation:(NSLocale *)locale completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token
                andLocation:locale
          deviceInformation:nil
          completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
              andLocation:(NSLocale *)locale
        deviceInformation:(NSDictionary *)deviceInformation
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self updateDeviceToken:token userAlias:nil andLocation:locale deviceInformation:deviceInformation completionHandler:handler];
}

- (void)updateDeviceToken:(NSData *)token
                userAlias:(NSString *)userAlias
              andLocation:(NSLocale *)locale
        deviceInformation:(NSDictionary *)deviceInformation
        completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(token != nil || userAlias != nil || locale != nil || deviceInformation != nil, @"The update method was called without any information to update.");
    NSAssert(self.deviceToken != nil, @"This device is not registered, please use the method registerToken:withUserAlias:locale:deviceInformation:completionHandler: instead");
    
    [self.requestManager updateDevice:self.deviceTokenId
                        withUserAlias:userAlias
                                token:token
                               locale:locale
                    deviceInformation:deviceInformation
                    completionHandler:[self _defaultRegisterResponseWithToken:token completionHandler:handler]];
}

-(void)anonymiseTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    [self registerAnonymousToken:self.deviceToken
               completionHandler:handler];
}

- (void)associateDeviceToUser:(NSString *)userAlias
            completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(userAlias.length > 0, @"To associate a device, a user alias need to be provided");
    NSAssert(self.deviceToken != nil, @"This device is not registered, please use the method registerToken:withUserAlias:completionHandler: instead.");
    
    [self registerToken:self.deviceToken
          withUserAlias:userAlias
      completionHandler:handler];
}

- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    NSAssert(self.deviceToken, @"This device is not registered.");
    
    [self.requestManager unregisterToken:self.deviceToken
                       completionHandler:handler];
}

- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo
{
    NSString *notificationID = notificationInfo[@"notification_id"];
    NSAssert(notificationID.length > 0, @"The notification received does not have an id");
    
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    
    if(notificationID)
        requestParameters[@"notification_id"] = notificationID;
    
    [self.requestManager markNotificationAsOpenedOnDevice:self.deviceToken
                                               withParams:requestParameters
                                          completionHandler:nil];
}

#pragma mark - Private
- (FWTDeviceTokenIdResponse) _defaultRegisterResponseWithToken:(NSData *)token completionHandler:(FWTNotifiableOperationCompletionHandler)handler
{
    __weak typeof(self) weakSelf = self;
    return ^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
        if (error == nil) {
            __strong typeof(weakSelf) sself = weakSelf;
            sself.deviceTokenId = deviceTokenId;
            if (token) {
                sself.deviceToken = token;
            }
        }
        if (handler) {
            handler(error == nil, error);
        }
    };
}

@end

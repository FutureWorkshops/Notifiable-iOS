//
//  FWTRequesterManager.m
//  Pods
//
//

#import "FWTRequesterManager.h"
#import "FWTHTTPRequester.h"
#import "NSError+FWTNotifiable.h"
#import "FWTDefaultNotifiableLogger.h"
#import "NSData+FWTNotifiable.h"
#import "FWTNotifiableDevice+Parser.h"
#import "NSLocale+FWTNotifiable.h"

typedef void (^FWTLoggedErrorHandler)(NSError * _Nullable error);
typedef void (^FWTLoggedTokenErrorHandler)(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error);

NSString * const FWTNotifiableDeviceTokenKey       = @"token";
NSString * const FWTNotifiableProviderKey          = @"provider";
NSString * const FWTNotifiableUserAliasKey         = @"user_alias";
NSString * const FWTNotifiableLanguageKey          = @"language";
NSString * const FWTNotifiableRegionKey            = @"country";
NSString * const FWTNotifiableNameKey              = @"name";
NSString * const FWTNotifiableCustomPropertiesKey  = @"custom_properties";

NSString * const FWTNotifiableProvider             = @"apns";

@interface FWTRequesterManager ()

@property (nonatomic, strong, readonly) FWTHTTPRequester *requester;

@end

@implementation FWTRequesterManager

- (instancetype)initWithRequester:(FWTHTTPRequester *)requester
{
    return [self initWithRequester:requester retryAttempts:3 andRetryDelay:60];
}

- (instancetype)initWithRequester:(FWTHTTPRequester *)requester retryAttempts:(NSInteger)attempts andRetryDelay:(NSTimeInterval)delay
{
    NSAssert(requester != nil, @"The manager need a requester");
    self = [super init];
    if (self) {
        self->_requester = requester;
        self->_retryAttempts = attempts;
        self->_retryDelay = delay;
        self->_logger = [[FWTDefaultNotifiableLogger alloc] init];
    }
    return self;
}

- (void)registerDeviceWithUserAlias:(NSString *)userAlias
                              token:(NSData *)token
                               name:(NSString *)name
                             locale:(NSLocale *)locale
                   customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
                 platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
                  completionHandler:(FWTDeviceTokenIdResponse)handler
{
    [self _registerDeviceWithUserAlias:userAlias
                                 token:token
                                  name:name
                                locale:locale
                      customProperties:customProperties
                    platformProperties:platformProperties
                              attempts:self.retryAttempts + 1
                         previousError:nil
                     completionHandler:handler];
}

- (void)updateDevice:(NSNumber *)deviceTokenId
        withUserAlias:(NSString *)alias
               token:(NSData *)token
                name:(NSString *)name
               locale:(NSLocale *)locale
    customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
  platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
    completionHandler:(FWTDeviceTokenIdResponse)handler
{
    [self _updateDevice:deviceTokenId
          withUserAlias:alias
                  token:token
                   name:name
                 locale:locale
       customProperties:customProperties
     platformProperties:platformProperties
               attempts:self.retryAttempts + 1
          previousError:nil
      completionHandler:handler];
}

- (void)unregisterTokenId:(NSNumber *)deviceTokenId
        completionHandler:(FWTSimpleRequestResponse)handler
{
    [self _unregisterToken:deviceTokenId
              withAttempts:self.retryAttempts + 1
             previousError:nil
         completionHandler:handler];
}

- (void)markNotificationAsOpenedWithId:(NSNumber *)notificationId
                         deviceTokenId:(NSNumber *)deviceTokenId
                                  user:(NSString *)user
                     completionHandler:(_Nullable FWTSimpleRequestResponse)handler
{
    [self _markNotificationAsOpenedWithId:[notificationId stringValue]
                            deviceTokenId:[deviceTokenId stringValue]
                                     user:user
                                 attempts:self.retryAttempts + 1
                                previousError:nil
                            completionHandler:handler];
}

- (void)markNotificationAsReceivedWithId:(NSNumber *)notificationId
                           deviceTokenId:(NSNumber *)deviceTokenId
                       completionHandler:(_Nullable FWTSimpleRequestResponse)handler
{
    [self _markNotificationAsReceivedWithId:[notificationId stringValue]
                              deviceTokenId:[deviceTokenId stringValue]
                                   attempts:self.retryAttempts + 1
                              previousError:nil
                          completionHandler:handler];
}

#pragma mark - Private
- (NSDictionary *)_buildParametersForUserAlias:(NSString *)userAlias
                                         token:(NSData *)token
                                          name:(NSString *)name
                                        locale:(NSLocale *)locale
                              customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
                            platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
                             includingProvider:(BOOL)includeProvider
{
    NSMutableDictionary *params;
    if (includeProvider) {
        params = [@{FWTNotifiableProviderKey: FWTNotifiableProvider} mutableCopy];
    } else {
        params = [[NSMutableDictionary alloc] init];
    }
    if (name) {
        [params setObject:name forKey:FWTNotifiableNameKey];
    }
    if (userAlias) {
        [params setObject:userAlias forKey:FWTNotifiableUserAliasKey];
    }
    if (token) {
        [params setObject:[token fwt_notificationTokenString] forKey:FWTNotifiableDeviceTokenKey];
    }
    if (locale) {
        [params setObject:[locale fwt_languageCode] forKey:FWTNotifiableLanguageKey];
        [params setObject:[locale fwt_countryCode] forKey:FWTNotifiableRegionKey];
    }
    if (customProperties) {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:customProperties options:0 error:&error];
        if (error == nil && jsonData.length > 0) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [params setObject:jsonString forKey:FWTNotifiableCustomPropertiesKey];
        }
    }
    if (platformProperties) {
        [params setValuesForKeysWithDictionary:platformProperties];
    }
    return @{@"device_token": [NSDictionary dictionaryWithDictionary:params]};
}

- (void)_registerDeviceWithUserAlias:(NSString *)userAlias
                               token:(NSData *)token
                                name:(NSString *)name
                              locale:(NSLocale *)locale
                    customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
                  platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
                            attempts:(NSUInteger)attempts
                       previousError:(NSError *)previousError
                   completionHandler:(FWTDeviceTokenIdResponse)handler
{
    NSAssert(token != nil, @"To register a device, a token need to be provided");
    
    FWTLoggedTokenErrorHandler errorHandler = [self _buildLoggedTokenIdErrorHandler: handler];
    
    if (token == nil) {
        errorHandler(nil, [NSError fwt_invalidDeviceInformationError:previousError]);
    }
    
    if (attempts == 0){
        errorHandler(nil, [NSError fwt_errorWithUnderlyingError:previousError]);
        return;
    }
    
    NSDictionary *params = [self _buildParametersForUserAlias:userAlias
                                                        token:token
                                                         name:name
                                                       locale:locale
                                             customProperties:customProperties
                                           platformProperties:platformProperties
                                            includingProvider:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.requester registerDeviceWithParams:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil || ![response isKindOfClass:[NSDictionary class]]) {
            [sself _registerDeviceWithUserAlias:userAlias
                                          token:token
                                           name:name
                                         locale:locale
                               customProperties:customProperties
                             platformProperties:platformProperties
                                       attempts:(attempts - 1)
                                  previousError:previousError
                              completionHandler:handler];
            return;
        }
        NSNumber *tokenId = response[@"id"];
        [sself.logger logMessage:[NSString stringWithFormat:@"Did register for push notifications with token: %@ and tokenId: %@", token, tokenId]];
        
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(tokenId, nil);
            });
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        [weakSelf.logger logMessage:[NSString stringWithFormat:@"Failed to register device token: %@",error]];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _registerDeviceWithUserAlias:userAlias
                                             token:token
                                              name:name
                                            locale:locale
                                  customProperties:customProperties
                                platformProperties:platformProperties
                                          attempts:(attempts - 1)
                                     previousError:error
                                 completionHandler:handler];
        });
    }];
}

- (void)_updateDevice:(NSNumber *)deviceTokenId
        withUserAlias:(NSString *)alias
                token:(NSData *)token
                 name:(NSString *)name
               locale:(NSLocale *)locale
     customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
   platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
             attempts:(NSUInteger)attempts
        previousError:(NSError *)previousError
    completionHandler:(FWTDeviceTokenIdResponse)handler
{
    NSAssert(deviceTokenId != nil, @"To update a device, a device token in need to be provided.");
    
    NSAssert(alias != nil ||
             token != nil ||
             name != nil ||
             locale != nil ||
             customProperties != nil, @"You need provid at least one updated parameter.");
    
    FWTLoggedTokenErrorHandler errorHandler = [self _buildLoggedTokenIdErrorHandler: handler];
    
    if (attempts == 0){
        errorHandler(deviceTokenId, [NSError fwt_errorWithUnderlyingError:previousError]);
        return;
    }
    
    if(!deviceTokenId){
        errorHandler(nil, [NSError fwt_invalidDeviceInformationError:nil]);
        return;
    }
    
    NSDictionary *params = [self _buildParametersForUserAlias:alias
                                                        token:token
                                                         name:name
                                                       locale:locale
                                             customProperties:customProperties
                                           platformProperties:platformProperties
                                            includingProvider:NO];
    
    __weak typeof(self) weakSelf = self;
    NSNumber *tokenId = [deviceTokenId copy];
    [self.requester updateDeviceWithTokenId:deviceTokenId params:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Did updated device"];
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(tokenId, nil);
            });
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:[NSString stringWithFormat:@"Failed to update device with deviceTokenId %@: %@", deviceTokenId, error]];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _updateDevice:deviceTokenId
                      withUserAlias:alias
                              token:token
                               name:name
                             locale:locale
                   customProperties:customProperties
                 platformProperties:platformProperties
                           attempts:(attempts - 1)
                      previousError:error
                  completionHandler:handler];
        });
    }];
}


- (void)_unregisterToken:(NSNumber *)deviceTokenId
            withAttempts:(NSUInteger)attempts
           previousError:(NSError *)previousError
       completionHandler:(FWTSimpleRequestResponse)handler
{
    FWTLoggedErrorHandler errorHandler = [self _buildLoggedErrorHandler:handler];
    
    if (attempts == 0){
        errorHandler([NSError fwt_errorWithUnderlyingError:previousError]);
        return;
    }
    
    if(!deviceTokenId){
        errorHandler([NSError fwt_invalidDeviceInformationError:nil]);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requester unregisterTokenId:deviceTokenId success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Did unregister for push notifications"];
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(YES, nil);
            });
        }
        
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        [weakSelf.logger logMessage:@"Failed to unregister for push notifications"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _unregisterToken:deviceTokenId
                          withAttempts:(attempts - 1)
                         previousError:error
                     completionHandler:handler];
        });
    }];
}


- (void)_markNotificationAsOpenedWithId:(NSString *)notificationId
                          deviceTokenId:(NSString *)deviceTokenId
                                   user:(NSString *)user
                               attempts:(NSUInteger)attempts
                          previousError:(NSError *)error
                      completionHandler:(FWTSimpleRequestResponse)handler
{
    FWTLoggedErrorHandler errorHandler = [self _buildLoggedErrorHandler:handler];
    
    if (attempts == 0) {
        errorHandler([NSError fwt_errorWithUnderlyingError:error]);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requester markNotificationAsOpenedWithId:notificationId deviceTokenId:deviceTokenId user:user success:^(NSDictionary * _Nullable response) {
        [weakSelf.logger logMessage:@"Notification flagged as opened"];
        if (handler) {
            handler(YES,nil);
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Failed to mark notification as opened"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _markNotificationAsOpenedWithId:notificationId
                                        deviceTokenId:deviceTokenId
                                                 user:user
                                             attempts:(attempts - 1)
                                        previousError:error
                                    completionHandler:handler];
        });
    }];
}

- (void)_markNotificationAsReceivedWithId:(NSString *)notificationId
                            deviceTokenId:(NSString *)deviceTokenId
                                 attempts:(NSUInteger)attempts
                            previousError:(NSError *)error
                        completionHandler:(FWTSimpleRequestResponse)handler
{
    FWTLoggedErrorHandler errorHandler = [self _buildLoggedErrorHandler:handler];
    
    if (attempts == 0) {
        errorHandler([NSError fwt_errorWithUnderlyingError:error]);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requester markNotificationAsReceivedWithId:notificationId deviceTokenId:deviceTokenId success:^(NSDictionary * _Nullable response) {
        [weakSelf.logger logMessage:@"Notification flagged as received"];
        if (handler) {
            handler(YES,nil);
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Failed to mark notification as received"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _markNotificationAsReceivedWithId:notificationId
                                        deviceTokenId:deviceTokenId
                                             attempts:(attempts - 1)
                                        previousError:error
                                    completionHandler:handler];
        });
    }];
}

- (FWTLoggedErrorHandler) _buildLoggedErrorHandler:(FWTSimpleRequestResponse)handler {
    __weak typeof(self) weakSelf = self;
    return  ^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __weak typeof(strongSelf.logger) weakLogger = strongSelf.logger;
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakLogger logError:error];
                handler(NO, error);
            });
        }
    };
}

- (FWTLoggedTokenErrorHandler) _buildLoggedTokenIdErrorHandler:(FWTDeviceTokenIdResponse)handler {
    __weak typeof(self) weakSelf = self;
    return  ^(NSNumber *tokenId, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __weak typeof(strongSelf.logger) weakLogger = strongSelf.logger;
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakLogger logError:error];
                handler(tokenId, error);
            });
        }
    };
}

@end

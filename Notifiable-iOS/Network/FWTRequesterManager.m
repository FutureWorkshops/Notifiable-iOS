//
//  FWTRequesterManager.m
//  Pods
//
//  Created by Igor Fereira on 19/01/2016.
//
//

#import "FWTRequesterManager.h"
#import "FWTHTTPRequester.h"
#import "NSError+FWTNotifiable.h"
#import "FWTDefaultNotifiableLogger.h"
#import "NSData+FWTNotifiable.h"
#import "FWTNotifiableDevice+Parser.h"

NSString * const FWTNotifiableUserInfoKey       = @"user";
NSString * const FWTNotifiableDeviceTokenKey    = @"token";
NSString * const FWTNotifiableProviderKey       = @"provider";
NSString * const FWTNotifiableUserAliasKey      = @"alias";
NSString * const FWTNotifiableLocaleKey         = @"locale";
NSString * const FWTNotifiableNameKey           = @"name";

NSString * const FWTNotifiableProvider          = @"apns";

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
                  deviceInformation:(NSDictionary *)deviceInformation
                  completionHandler:(FWTDeviceTokenIdResponse)handler
{
    [self _registerDeviceWithUserAlias:userAlias
                                 token:token
                                  name:name
                                locale:locale
                     deviceInformation:deviceInformation
                              attempts:self.retryAttempts
                         previousError:nil
                     completionHandler:handler];
}

- (void)updateDevice:(NSNumber *)deviceTokenId
        withUserAlias:(NSString *)alias
               token:(NSData *)token
                name:(NSString *)name
               locale:(NSLocale *)locale
    deviceInformation:(NSDictionary *)deviceInformation
    completionHandler:(FWTDeviceTokenIdResponse)handler
{
    [self _updateDevice:deviceTokenId
          withUserAlias:alias
                  token:token
                   name:name
                 locale:locale
      deviceInformation:deviceInformation
               attempts:self.retryAttempts
          previousError:nil
      completionHandler:handler];
}

- (void)unregisterTokenId:(NSNumber *)deviceTokenId
                userAlias:(NSString *)userAlias
        completionHandler:(FWTSimpleRequestResponse)handler
{
    [self _unregisterToken:deviceTokenId
                 userAlias:userAlias
              withAttempts:self.retryAttempts
             previousError:nil
         completionHandler:handler];
}

- (void)markNotificationAsOpenedWithParams:(NSDictionary *)params
                         completionHandler:(FWTSimpleRequestResponse)handler
{
    [self _markNotificationAsOpenedWithParams:params
                                     attempts:self.retryAttempts
                                previousError:nil completionHandler:handler];
}

- (void)listDevicesOfUser:(NSString *)userAlias
        completionHandler:(FWTDeviceListResponse)handler
{
    [self _listDevicesOfUser:userAlias
                    attempts:self.retryAttempts
               previousError:nil
           completionHandler:handler];
}

#pragma mark - Private
- (NSDictionary *)_buildParametersForUserAlias:(NSString *)userAlias
                                         token:(NSData *)token
                                          name:(NSString *)name
                                        locale:(NSLocale *)locale
                             deviceInformation:(NSDictionary *)deviceInformation
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
        [params addEntriesFromDictionary:@{FWTNotifiableUserInfoKey: @{FWTNotifiableUserAliasKey: userAlias}}];
    }
    if (token) {
        [params setObject:[token fwt_notificationTokenString] forKey:FWTNotifiableDeviceTokenKey];
    }
    if (locale) {
        [params setObject:[locale localeIdentifier] forKey:FWTNotifiableLocaleKey];
    }
    if (deviceInformation) {
        [params addEntriesFromDictionary:deviceInformation];
    }
    return [NSDictionary dictionaryWithDictionary:params];
}

- (void)_registerDeviceWithUserAlias:(NSString *)userAlias
                               token:(NSData *)token
                                name:(NSString *)name
                              locale:(NSLocale *)locale
                   deviceInformation:(NSDictionary *)deviceInformation
                            attempts:(NSUInteger)attempts
                       previousError:(NSError *)error
                   completionHandler:(FWTDeviceTokenIdResponse)handler
{
    NSAssert(token != nil, @"To register a device, a token need to be provided");
    
    if (token == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, [NSError fwt_invalidDeviceInformationError:nil]);
        });
    }
    
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, error);
            });
        }
        return;
    }
    
    NSDictionary *params = [self _buildParametersForUserAlias:userAlias
                                                        token:token
                                                         name:name
                                                       locale:locale
                                            deviceInformation:deviceInformation
                                            includingProvider:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.requester registerDeviceWithParams:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil || ![response isKindOfClass:[NSDictionary class]]) {
            [sself _registerDeviceWithUserAlias:userAlias
                                          token:token
                                           name:name
                                         locale:locale
                              deviceInformation:deviceInformation
                                       attempts:(attempts - 1)
                                  previousError:error
                              completionHandler:handler];
            return;
        }
        NSNumber *tokenId = response[@"id"];
        [sself.logger logMessage:@"Did register for push notifications with token: %@ and tokenId: %@", token, tokenId];
        
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(tokenId, nil);
            });
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        [weakSelf.logger logMessage:@"Failed to register device token: %@",error];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _registerDeviceWithUserAlias:userAlias
                                             token:token
                                              name:name
                                            locale:locale
                                 deviceInformation:deviceInformation
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
    deviceInformation:(NSDictionary *)deviceInformation
             attempts:(NSUInteger)attempts
        previousError:(NSError *)error
    completionHandler:(FWTDeviceTokenIdResponse)handler
{
    NSAssert(deviceTokenId != nil, @"To update a device, a device token in need to be provided.");
    
    NSAssert(alias != nil ||
             token != nil ||
             name != nil ||
             locale != nil ||
             deviceInformation != nil, @"You need provid at least one updated parameter.");
    
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(deviceTokenId, [NSError fwt_invalidOperationErrorWithUnderlyingError:nil]);
            });
        }
        return;
    }
    
    if(!deviceTokenId){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, [NSError fwt_invalidDeviceInformationError:nil]);
            });
        }
        return;
    }
    
    NSDictionary *params = [self _buildParametersForUserAlias:alias
                                                        token:token
                                                         name:name
                                                       locale:locale
                                            deviceInformation:deviceInformation
                                            includingProvider:NO];
    
    __weak typeof(self) weakSelf = self;
    [self.requester updateDeviceWithTokenId:deviceTokenId params:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil || ![response isKindOfClass:[NSDictionary class]]) {
            [sself _updateDevice:deviceTokenId
                   withUserAlias:alias
                           token:token
                            name:name
                          locale:locale
               deviceInformation:deviceInformation
                        attempts:(attempts - 1)
                   previousError:error
               completionHandler:handler];
            return;
        }
        
        NSNumber *tokenId = response[@"id"];
        [sself.logger logMessage:@"Did update device with deviceTokenId: %@", tokenId];
        
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(tokenId, nil);
            });
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Failed to update device with deviceTokenId %@: %@", deviceTokenId, error];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _updateDevice:deviceTokenId
                      withUserAlias:alias
                              token:token
                               name:name
                             locale:locale
                  deviceInformation:deviceInformation
                           attempts:(attempts - 1)
                      previousError:error
                  completionHandler:handler];
        });
    }];
}


- (void)_unregisterToken:(NSNumber *)deviceTokenId
               userAlias:(NSString *)userAlias
            withAttempts:(NSUInteger)attempts
           previousError:(NSError *)error
       completionHandler:(FWTSimpleRequestResponse)handler
{
    if (attempts == 0){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, [NSError fwt_invalidOperationErrorWithUnderlyingError:nil]);
            });
        }
        return;
    }
    
    if(!deviceTokenId){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, [NSError fwt_invalidDeviceInformationError:nil]);
            });
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requester unregisterTokenId:deviceTokenId userAlias:userAlias success:^(NSDictionary * _Nullable response) {
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
                             userAlias:userAlias
                          withAttempts:(attempts - 1)
                         previousError:error
                     completionHandler:handler];
        });
    }];
}


- (void)_markNotificationAsOpenedWithParams:(NSDictionary *)params
                                   attempts:(NSUInteger)attempts
                              previousError:(NSError *)error
                          completionHandler:(FWTSimpleRequestResponse)handler
{
    if (attempts == 0) {
        if (handler) {
            handler(NO, error);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requester markNotificationAsOpenedWithParams:params success:^(NSDictionary * _Nullable response) {
        [weakSelf.logger logMessage:@"Notification flagged as opened"];
        if (handler) {
            handler(YES,nil);
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Failed to mark notification as opened"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _markNotificationAsOpenedWithParams:params
                                                 attempts:(attempts - 1)
                                            previousError:error
                                        completionHandler:handler];
        });
    }];
}

- (void)_listDevicesOfUser:(NSString *)userAlias
                  attempts:(NSUInteger)attempts
             previousError:(NSError *)error
        completionHandler:(FWTDeviceListResponse)handler
{
    if (attempts == 0) {
        if (handler) {
            handler(@[], error);
        }
        return;
    }
    
    if (userAlias.length == 0) {
        if (handler) {
            handler(@[], [NSError fwt_invalidDeviceInformationError:error]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.requester listDevicesOfUser:userAlias success:^(NSArray * _Nonnull response) {
        __strong typeof(weakSelf) sself = weakSelf;
        
        NSMutableArray *parsedResponse = [[NSMutableArray alloc] initWithCapacity:response.count];
        
        for (NSDictionary *element in response) {
            FWTNotifiableDevice *device = [[FWTNotifiableDevice alloc] initWithUserName:userAlias dictionary:element];
            if (device) {
                [parsedResponse addObject:device];
            } else {
                [sself.logger logMessage:@"Received an invalid device: %@", element];
            }
        }
        
        [sself.logger logMessage:@"Got the list of devices"];
        if (handler) {
            handler([NSArray arrayWithArray:parsedResponse], nil);
        }
        
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [sself.logger logMessage:@"Failed to list devices"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [weakSelf _listDevicesOfUser:userAlias
                                attempts:(attempts - 1)
                           previousError:error
                       completionHandler:handler];
        });
    }];
    
}

@end

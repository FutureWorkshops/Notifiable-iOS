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

NSString * const FWTNotifiableUserInfoKey       = @"user";
NSString * const FWTNotifiableDeviceTokenKey    = @"token";
NSString * const FWTNotifiableProviderKey       = @"provider";
NSString * const FWTNotifiableUserAliasKey      = @"alias";
NSString * const FWTNotifiableLocaleKey         = @"locale";

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
                             locale:(NSLocale *)locale
                  deviceInformation:(NSDictionary *)deviceInformation
                  completionHandler:(FWTDeviceTokenIdResponse)handler
{
    [self _registerDeviceWithUserAlias:userAlias
                                 token:token
                                locale:locale
                     deviceInformation:deviceInformation
                              attempts:self.retryAttempts
                         previousError:nil
                     completionHandler:handler];
}

- (void)updateDevice:(NSNumber *)deviceTokenId
        withUserAlias:(NSString *)alias
                token:(NSData *)token
               locale:(NSLocale *)locale
    deviceInformation:(NSDictionary *)deviceInformation
    completionHandler:(FWTDeviceTokenIdResponse)handler
{
    [self _updateDevice:deviceTokenId
          withUserAlias:alias
                  token:token
                 locale:locale
      deviceInformation:deviceInformation
               attempts:self.retryAttempts
          previousError:nil completionHandler:handler];
}

- (void)unregisterToken:(NSData *)deviceToken
      completionHandler:(FWTSimpleRequestResponse)handler
{
    [self _unregisterToken:deviceToken
              withAttempts:self.retryAttempts
             previousError:nil
         completionHandler:handler];
}

- (void)markNotificationAsOpenedOnDevice:(NSData *)deviceToken
                              withParams:(NSDictionary *)params
                       completionHandler:(FWTSimpleRequestResponse)handler
{
    [self _markNotificationAsOpenedWithParams:params
                                     attempts:self.retryAttempts
                                previousError:nil completionHandler:handler];
}

#pragma mark - Private
- (NSDictionary *)_buildParametersForUserAlias:(NSString *)userAlias
                                         token:(NSData *)token
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
                              locale:(NSLocale *)locale
                   deviceInformation:(NSDictionary *)deviceInformation
                            attempts:(NSUInteger)attempts
                       previousError:(NSError *)error
                   completionHandler:(FWTDeviceTokenIdResponse)handler
{
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
                                                       locale:locale
                                            deviceInformation:deviceInformation
                                            includingProvider:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.requester registerDeviceWithParams:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil || ![response isKindOfClass:[NSDictionary class]]) {
            [sself _registerDeviceWithUserAlias:userAlias
                                          token:token
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
               locale:(NSLocale *)locale
    deviceInformation:(NSDictionary *)deviceInformation
             attempts:(NSUInteger)attempts
        previousError:(NSError *)error
    completionHandler:(FWTDeviceTokenIdResponse)handler
{
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
                                                       locale:locale
                                            deviceInformation:deviceInformation
                                            includingProvider:NO];
    
    __weak typeof(self) weakSelf = self;
    [self.requester updateDeviceWithTokenId:deviceTokenId params:params success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil || ![response isKindOfClass:[NSDictionary class]]) {
            [sself _registerDeviceWithUserAlias:alias
                                          token:token
                                         locale:locale
                              deviceInformation:deviceInformation
                                       attempts:(attempts - 1)
                                  previousError:nil
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
            [weakSelf _registerDeviceWithUserAlias:alias
                                             token:token
                                            locale:locale
                                 deviceInformation:deviceInformation
                                          attempts:(attempts - 1)
                                     previousError:nil
                                 completionHandler:handler];
        });
    }];
}


- (void)_unregisterToken:(NSData *)deviceToken
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
    
    if(!deviceToken){
        if(handler){
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, [NSError fwt_invalidDeviceInformationError:nil]);
            });
        }
        return;
    }
    
    NSString *token = [deviceToken fwt_notificationTokenString];
    
    __weak typeof(self) weakSelf = self;
    [self.requester unregisterToken:token success:^(NSDictionary * _Nullable response) {
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _unregisterToken:deviceToken
                       withAttempts:(attempts - 1)
                      previousError:error
                  completionHandler:handler];
            return;
        }
        
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
            [weakSelf _unregisterToken:deviceToken
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
        __strong typeof(weakSelf) sself = weakSelf;
        if (response == nil) {
            [sself _markNotificationAsOpenedWithParams:params
                                              attempts:(attempts - 1)
                                         previousError:error
                                     completionHandler:handler];
            return;
        }
        [sself.logger logMessage:@"Notification flagged as opened"];
        if (handler) {
            handler(YES,nil);
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) sself = weakSelf;
        [weakSelf.logger logMessage:@"Failed to mark notification as opened"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sself.retryDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf _markNotificationAsOpenedWithParams:params
                                                 attempts:(attempts - 1)
                                            previousError:error
                                        completionHandler:handler];
        });
    }];
}

@end

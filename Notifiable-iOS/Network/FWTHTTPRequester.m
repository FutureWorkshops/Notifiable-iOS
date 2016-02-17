//
//  FWTRequestManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 15/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTHTTPRequester.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "FWTNotifiableAuthenticator.h"
#import "NSError+FWTNotifiable.h"

typedef void(^FWTAFNetworkingSuccessBlock)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject);
typedef void(^FWTAFNetworkingFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);

NSString * const FWTDeviceTokensPath = @"user_api/v1/device_tokens";
NSString * const FWTNotificationOpenPath = @"user_api/v1/notification_statuses/opened";
NSString * const FWTListDevicesPath = @"user_api/v1/device_tokens.json";

NSString * const FWTUserAliasFormat = @"user[alias]=%@";

@interface FWTHTTPRequester ()

@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) FWTNotifiableAuthenticator *authenticator;

@end

@implementation FWTHTTPRequester

- (instancetype)initWithBaseURL:(NSURL*)baseUrl
               andAuthenticator:(FWTNotifiableAuthenticator*)authenticator
{
    self = [super init];
    if (self) {
        self->_baseUrl = baseUrl;
        self->_authenticator = authenticator;
    }
    return self;
}

- (AFHTTPSessionManager *)httpSessionManager
{
    if (!self->_httpSessionManager) {
        self->_httpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseUrl];
        self->_httpSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return self->_httpSessionManager;
}

- (void)registerDeviceWithParams:(NSDictionary *)params
                         success:(FWTRequestManagerSuccessBlock)success
                         failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(params != nil, @"You need provide, at least, the device token that will be registered");
    
    [self _updateAuthenticationForPath:FWTDeviceTokensPath];
    
    [self.httpSessionManager POST:FWTDeviceTokensPath
                       parameters:params
                         progress:nil
                          success:[self _defaultSuccessHandler:success]
                          failure:[self _defaultFailureHandler:failure success:success]];
}

- (void)updateDeviceWithTokenId:(NSNumber *)tokenId
                         params:(NSDictionary *)params
                        success:(FWTRequestManagerSuccessBlock)success
                        failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(params != nil, @"You need provide some information to update");
    NSAssert(tokenId != nil, @"Device token id missing");
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",FWTDeviceTokensPath, [tokenId stringValue]];
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager PUT:path
                      parameters:params
                         success:[self _defaultSuccessHandler:success]
                         failure:[self _defaultFailureHandler:failure success:success]];
}

- (void)unregisterTokenId:(NSNumber *)tokenId
                userAlias:(NSString *)userAlias
                  success:(FWTRequestManagerSuccessBlock)success
                  failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(tokenId != nil, @"Device token id missing");
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",FWTDeviceTokensPath, tokenId];
    if (userAlias) {
        NSString *userAliasInformation = [NSString stringWithFormat:FWTUserAliasFormat,userAlias];
        path = [path stringByAppendingFormat:@"?%@",[userAliasInformation stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    }
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager DELETE:path
                         parameters:nil
                            success:[self _defaultSuccessHandler:success]
                            failure:[self _defaultFailureHandler:failure success:success]];
}

- (void)markNotificationAsOpenedWithParams:(NSDictionary *)params
                                   success:(FWTRequestManagerSuccessBlock)success
                                   failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(params != nil, @"You need provide, at least, the localized_notification_id");
    [self _updateAuthenticationForPath:FWTNotificationOpenPath];
    [self.httpSessionManager PUT:FWTNotificationOpenPath
                      parameters:params
                         success:[self _defaultSuccessHandler:success]
                         failure:[self _defaultFailureHandler:failure success:success]];
}

- (void)listDevicesOfUser:(NSString *)userAlias
                  success:(FWTRequestManagerArraySuccessBlock)success
                  failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(userAlias != nil, @"User alias missing");
    
    NSString *path = FWTListDevicesPath;
    if (userAlias) {
        NSString *userAliasInformation = [NSString stringWithFormat:FWTUserAliasFormat,userAlias];
        path = [path stringByAppendingFormat:@"?%@",[userAliasInformation stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    }
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSArray class]]) {
            success(responseObject != nil ? responseObject : @[]);
        } else {
            success(@[]);
        }
    } failure:[self _defaultFailureHandler:failure success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
        success(@[]);
    }]];
}

#pragma mark - Private Methods
- (FWTAFNetworkingSuccessBlock) _defaultSuccessHandler:(FWTRequestManagerSuccessBlock)success
{
    return ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            success(responseObject);
        } else {
            success(nil);
        }
    };
}

- (FWTAFNetworkingFailureBlock) _defaultFailureHandler:(FWTRequestManagerFailureBlock)failure success:(FWTRequestManagerSuccessBlock)success
{
    return ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        if (response.statusCode == 200) {
            if (success) {
                success(nil);
            }
        } else if(failure) {
            failure(response.statusCode, error);
        }
    };
}

- (void) _updateAuthenticationForPath:(NSString *)path
{
    NSDictionary *headers = [self.authenticator authHeadersForPath:path
                                                        andHeaders:self.httpSessionManager.requestSerializer.HTTPRequestHeaders];
    for (NSString *header in headers.keyEnumerator) {
        [self.httpSessionManager.requestSerializer setValue:headers[header] forHTTPHeaderField:header];
    }
}

- (NSError *) _errorForStatusCode:(NSInteger)statusCode withUnderlyingError:(NSError *)underlyingError
{
    switch (statusCode) {
        case 401:
            return [NSError fwt_userAliasErrorWithUnderlyingError:underlyingError];
        case 403:
            return [NSError fwt_forbiddenErrorWithUnderlyingError:underlyingError];
        case 404:
            return [NSError fwt_invalidOperationErrorWithUnderlyingError:underlyingError];
        default:
            return underlyingError;
            break;
    }
}

@end

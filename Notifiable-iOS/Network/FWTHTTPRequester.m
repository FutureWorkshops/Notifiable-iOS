//
//  FWTRequestManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 15/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTHTTPRequester.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "AFJSONRequestOperation.h"
#import "FWTNotifiableAuthenticator.h"
#import "NSError+FWTNotifiable.h"

typedef void(^FWTAFNetworkingSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
typedef void(^FWTAFNetworkingFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);

typedef void(^FWTRequestManagerDictionaryArraySuccessBlock)(id _Nullable response);

NSString * const FWTDeviceTokensPath = @"user_api/v1/device_tokens";
NSString * const FWTNotificationOpenPath = @"user_api/v1/notification_statuses/opened";
NSString * const FWTListDevicesPath = @"user_api/v1/device_tokens.json";

NSString * const FWTUserAliasFormat = @"user[alias]=%@";

@interface FWTHTTPRequester ()

@property (nonatomic, strong) AFHTTPClient *httpClient;
@property (nonatomic, strong) FWTNotifiableAuthenticator *authenticator;

@end

@implementation FWTHTTPRequester

- (instancetype)initWithBaseUrl:(NSString*)baseUrl
               andAuthenticator:(FWTNotifiableAuthenticator*)authenticator
{
    self = [super init];
    if (self) {
        self->_baseUrl = [NSURL URLWithString:baseUrl];
        self->_authenticator = authenticator;
    }
    return self;
}

- (AFHTTPClient *)httpClient
{
    if (!self->_httpClient) {
        self->_httpClient = [AFHTTPClient clientWithBaseURL:self.baseUrl];
        self->_httpClient.parameterEncoding = AFJSONParameterEncoding;
    }
    return self->_httpClient;
}

- (void)registerDeviceWithParams:(NSDictionary *)params
                         success:(FWTRequestManagerSuccessBlock)success
                         failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(params != nil, @"You need provide, at least, the device token that will be registered");
    
    [self _postPath:FWTDeviceTokensPath
             params:params
            success:success
            failure:failure];
}

- (void)updateDeviceWithTokenId:(NSNumber *)tokenId
                         params:(NSDictionary *)params
                        success:(FWTRequestManagerSuccessBlock)success
                        failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(params != nil, @"You need provide some information to update");
    NSAssert(tokenId != nil, @"Device token id missing");
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",FWTDeviceTokensPath, [tokenId stringValue]];
    [self _putPath:path
            params:params
           success:success
           failure:failure];
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
    [self _deletePath:path
               params:nil
              success:success
              failure:failure];
}

- (void)markNotificationAsOpenedWithParams:(NSDictionary *)params
                                   success:(FWTRequestManagerSuccessBlock)success
                                   failure:(FWTRequestManagerFailureBlock)failure
{
    NSAssert(params != nil, @"You need provide, at least, the localized_notification_id");
    [self _putPath:FWTNotificationOpenPath
            params:params
           success:success
           failure:failure];
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
    [self _getPath:path
            params:nil
           success:success
           failure:failure];
}

#pragma mark - Private Methods
- (void) _getPath:(NSString *)path
           params:(NSDictionary *)params
          success:(FWTRequestManagerDictionaryArraySuccessBlock)success
          failure:(FWTRequestManagerFailureBlock)failure
{
    [self _performRequestWithMethod:@"GET"
                               path:path
                             params:params
                            success:success
                         andFailure:failure];
}

- (void) _postPath:(NSString *)path
            params:(NSDictionary *)params
           success:(FWTRequestManagerDictionaryArraySuccessBlock)success
           failure:(FWTRequestManagerFailureBlock)failure
{
    [self _performRequestWithMethod:@"POST"
                               path:path
                             params:params
                            success:success
                         andFailure:failure];
}

- (void) _putPath:(NSString *)path
           params:(NSDictionary *)params
          success:(FWTRequestManagerDictionaryArraySuccessBlock)success
          failure:(FWTRequestManagerFailureBlock)failure
{
    [self _performRequestWithMethod:@"PUT"
                               path:path
                             params:params
                            success:success
                         andFailure:failure];
}

- (void) _deletePath:(NSString *)path
              params:(NSDictionary *)params
             success:(FWTRequestManagerDictionaryArraySuccessBlock)success
             failure:(FWTRequestManagerFailureBlock)failure
{
    [self _performRequestWithMethod:@"DELETE"
                               path:path
                             params:params
                            success:success
                         andFailure:failure];
}

- (void) _performRequestWithMethod:(NSString *)method
                              path:(NSString *)path
                            params:(NSDictionary *)params
                           success:(FWTRequestManagerDictionaryArraySuccessBlock)success
                        andFailure:(FWTRequestManagerFailureBlock)failure
{
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:method path:path parameters:params];
    [request setAllHTTPHeaderFields:[self _updateAuthenticationForPath:path andHeaders:request.allHTTPHeaderFields]];
    AFJSONRequestOperation *requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                               success:[self _defaultSuccessHandler:success]
                                                                                               failure:[self _defaultFailureHandler:failure success:success]];
    [self.httpClient enqueueHTTPRequestOperation:requestOperation];
}

- (FWTAFNetworkingSuccessBlock) _defaultSuccessHandler:(FWTRequestManagerDictionaryArraySuccessBlock)success
{
    return ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if (success == nil) {
            return;
        }
        
        if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
            success(JSON);
        } else {
            success(nil);
        }
    };
}

- (FWTAFNetworkingFailureBlock) _defaultFailureHandler:(FWTRequestManagerFailureBlock)failure success:(FWTRequestManagerDictionaryArraySuccessBlock)success
{
    return ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (response.statusCode == 200) {
            if (success) {
                success(nil);
            }
        } else if(failure) {
            if (failure) {
                failure(response.statusCode, error);
            }
        }
    };
}

- (NSDictionary *) _updateAuthenticationForPath:(NSString *)path andHeaders:(NSDictionary *)headers
{
    NSDictionary *authHeaders = [self.authenticator authHeadersForPath:path
                                                            andHeaders:headers];
    return authHeaders;
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

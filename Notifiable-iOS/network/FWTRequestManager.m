//
//  FWTRequestManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 15/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTRequestManager.h"
#import "AFNetworking.h"
#import "FWTNotifiableAuthenticator.h"

typedef void(^FWTAFNetworkingSuccessBlock)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject);
typedef void(^FWTAFNetworkingFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);

NSString * const FWTDeviceTokensPath = @"user_api/v1/device_tokens";
NSString * const FWTNotificationOpenPath = @"user_api/v1/notification_statuses/opened";

@interface FWTRequestManager ()

@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) FWTNotifiableAuthenticator *authenticator;

@end

@implementation FWTRequestManager

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
    [self _updateAuthenticationForPath:FWTDeviceTokensPath];
    
    [self.httpSessionManager POST:FWTDeviceTokensPath
                       parameters:params
                          success:[self _defaultSuccessHandler:success]
                          failure:[self _defaultFailureHandler:failure]];
}

- (void)updateDeviceWithTokenId:(NSNumber *)tokenId
                         params:(NSDictionary *)params
                        success:(FWTRequestManagerSuccessBlock)success
                        failure:(FWTRequestManagerFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"%@/%@",FWTDeviceTokensPath, [tokenId stringValue]];
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager PUT:path
                      parameters:params
                         success:[self _defaultSuccessHandler:success]
                         failure:[self _defaultFailureHandler:failure]];
}

- (void)unregisterToken:(NSString *)token
                success:(FWTRequestManagerSuccessBlock)success
                failure:(FWTRequestManagerFailureBlock)failure
{
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",FWTDeviceTokensPath, token];
    [self _updateAuthenticationForPath:path];
    [self.httpSessionManager DELETE:path
                         parameters:nil
                            success:[self _defaultSuccessHandler:success]
                            failure:[self _defaultFailureHandler:failure]];
}

- (void)markNotificationAsOpenedWithParams:(NSDictionary *)params
                                   success:(FWTRequestManagerSuccessBlock)success
                                   failure:(FWTRequestManagerFailureBlock)failure
{
    [self _updateAuthenticationForPath:FWTNotificationOpenPath];
    [self.httpSessionManager PUT:FWTNotificationOpenPath
                      parameters:params
                         success:[self _defaultSuccessHandler:success]
                         failure:[self _defaultFailureHandler:failure]];
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

- (FWTAFNetworkingFailureBlock) _defaultFailureHandler:(FWTRequestManagerFailureBlock)failure
{
    return ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        failure(response.statusCode, error);
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


@end

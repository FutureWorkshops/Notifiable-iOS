//
//  FWTHTTPSessionManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import "FWTHTTPSessionManager.h"
#import "FWTHTTPRequestSerializer.h"
#import "FWTNotifiableAuthenticator.h"

NSString *const FWTHTTPSessionManagerIdentifier = @"com.futureworkshops.notifiable.FWTHTTPSessionManager";

@interface FWTHTTPSessionManager ()

@property (nonatomic, strong) NSOperationQueue *sessionOperationQueue;
@property (nonatomic, strong) FWTHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;
@property (nonatomic, strong) FWTNotifiableAuthenticator *authenticator;

@end

@implementation FWTHTTPSessionManager

- (instancetype) initWithBaseURL:(NSURL *)baseUrl andAuthenticator:(FWTNotifiableAuthenticator *)authenticator
{
    self = [super init];
    if (self) {
        self->_baseURL = baseUrl;
        self->_authenticator = authenticator;
    }
    return self;
}

#pragma mark - Class properties

- (NSOperationQueue *)sessionOperationQueue
{
    if (self->_sessionOperationQueue == nil) {
        self->_sessionOperationQueue = [[NSOperationQueue alloc] init];
        self->_sessionOperationQueue.maxConcurrentOperationCount = 3;
        self->_sessionOperationQueue.name = FWTHTTPSessionManagerIdentifier;
        self->_sessionOperationQueue.qualityOfService = NSQualityOfServiceUtility;
    }
    return self->_sessionOperationQueue;
}

- (NSMutableDictionary *)mutableHeaders
{
    if (self->_mutableHeaders == nil) {
        self->_mutableHeaders = [[NSMutableDictionary alloc] init];
    }
    return self->_mutableHeaders;
}

- (NSDictionary<NSString *,NSString *> *)HTTPRequestHeaders
{
    return [NSDictionary dictionaryWithDictionary: self.mutableHeaders];
}

- (FWTHTTPRequestSerializer *)requestSerializer
{
    if (self->_requestSerializer == nil) {
        self->_requestSerializer = [[FWTHTTPRequestSerializer alloc] init];
    }
    return self->_requestSerializer;
}

#pragma mark - Public methods

- (void)GET:(NSString *)URLString
 parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters
    success:(nullable FWTHTTPSessionManagerSuccessBlock)success
    failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    [self _buildTaskForPath:URLString
                     method:FWTHTTPMethodGET
                 parameters:parameters
                    success:success
                 andFailure:failure];
}

- (void)PATCH:(NSString *)URLString
   parameters:(nullable NSDictionary *)parameters
      success:(nullable FWTHTTPSessionManagerSuccessBlock)success
      failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    [self _buildTaskForPath:URLString
                     method:FWTHTTPMethodPATCH
                 parameters:parameters
                    success:success
                 andFailure:failure];
}

- (void)DELETE:(NSString *)URLString
    parameters:(nullable NSDictionary *)parameters
       success:(nullable FWTHTTPSessionManagerSuccessBlock)success
       failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    [self _buildTaskForPath:URLString
                     method:FWTHTTPMethodDELETE
                 parameters:parameters
                    success:success
                 andFailure:failure];
}

- (void)PUT:(NSString *)URLString
 parameters:(nullable NSDictionary *)parameters
    success:(nullable FWTHTTPSessionManagerSuccessBlock)success
    failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    [self _buildTaskForPath:URLString
                     method:FWTHTTPMethodPUT
                 parameters:parameters
                    success:success
                 andFailure:failure];
}

- (void)POST:(NSString *)URLString
  parameters:(nullable NSDictionary *)parameters
     success:(nullable FWTHTTPSessionManagerSuccessBlock)success
     failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    [self _buildTaskForPath:URLString
                     method:FWTHTTPMethodPOST
                 parameters:parameters
                    success:success
                 andFailure:failure];
}

- (void) setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [self.mutableHeaders setValue:value
                           forKey:field];
}

- (void)retryRequest:(NSURLRequest *)request
             success:(nullable FWTHTTPSessionManagerSuccessBlock)success
             failure:(nullable FWTHTTPSessionManagerFailureBlock)failure {
    [self _performRequest:[self _resignRequest:request]
                  success:success
               andFailure:failure];
}

#pragma mark - Private methods

- (void) _buildTaskForPath:(NSString *)path
                    method:(FWTHTTPMethod)method
                parameters:(NSDictionary*)parameters
                   success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                andFailure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    NSURLRequest *request = [self _buildRequestWithPath:path method:method andParameters:parameters];
    [self _performRequest:request success:success andFailure:failure];
}
- (void) _performRequest:(NSURLRequest *)request
                 success:(nullable FWTHTTPSessionManagerSuccessBlock)success
              andFailure:(nullable FWTHTTPSessionManagerFailureBlock)failure {
    __weak typeof(self) weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:self.sessionOperationQueue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSLog(@"Response with Error: %@", connectionError);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (connectionError) {
            failure(httpResponse.statusCode, connectionError);
            return;
        }
        
        id responseData = [weakSelf _jsonFromData:data];
        
        if (httpResponse && (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300)) {
            NSDictionary *userInfo = [responseData isKindOfClass:[NSDictionary class]] ? (NSDictionary *)responseData : @{};
            failure(404, [NSError errorWithDomain:@"FWTNotifiableError" code:httpResponse.statusCode userInfo:userInfo]);
            return;
        }
        
        success(responseData);
    }];
}

- (NSURLRequest *) _buildRequestWithPath:(NSString *)path
                                  method:(FWTHTTPMethod)method
                           andParameters:(NSDictionary *)paramters
{
    NSURL* url = [self.baseURL URLByAppendingPathComponent:path];
    NSDictionary *headers = [self _updateAuthenticationForPath:path
                                                    httpMethod:FWTHTTPMethodString(method)];
    NSURLRequest *request = [self.requestSerializer buildRequestWithBaseURL:url
                                                                 parameters:paramters
                                                                 andHeaders:headers
                                                                  forMethod:method];
    return request;
}

- (NSURLRequest *) _resignRequest:(NSURLRequest *)request
{
    NSString *path = [request.URL path];
    NSString *method = [request HTTPMethod];
    NSDictionary *headers = [self _updateAuthenticationForPath:path httpMethod:method];
    
    NSMutableURLRequest *resultRequest = [request mutableCopy];
    [resultRequest setAllHTTPHeaderFields:headers];
    return [resultRequest copy];
}

- (NSDictionary<NSString *, NSString *> *) _updateAuthenticationForPath:(NSString *)path
                                                             httpMethod:(NSString *)httpMethod
{
    NSMutableDictionary *source = [[NSMutableDictionary alloc] initWithDictionary:self.HTTPRequestHeaders];
    NSDictionary *headers = [self.authenticator authHeadersForPath:path
                                                        httpMethod:httpMethod
                                                        andHeaders:source];
    [source setValuesForKeysWithDictionary:headers];
    return source;
}

- (id) _jsonFromData:(NSData *)data
{
    NSError *error;
    id jsonContent = [NSJSONSerialization JSONObjectWithData:data
                                                     options:NSJSONReadingAllowFragments
                                                       error:&error];
    if (error || jsonContent == nil) {
        return data;
    } else {
        return jsonContent;
    }
}

@end

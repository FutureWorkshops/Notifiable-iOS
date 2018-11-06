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
#import "FWTRequestQueue.h"
#import "NSError+FWTNetwork.h"

#define kProcessQueueInterval 2

#define SupportedErrorsForEnqueue @[@(NSURLErrorSecureConnectionFailed),\
@(NSURLErrorCancelled),\
@(NSURLErrorTimedOut),\
@(NSURLErrorCannotConnectToHost),\
@(NSURLErrorNetworkConnectionLost),\
@(NSURLErrorDNSLookupFailed),\
@(NSURLErrorNotConnectedToInternet)]

NSString *const FWTHTTPSessionManagerIdentifier = @"com.futureworkshops.notifiable.FWTHTTPSessionManager";

@interface FWTHTTPSessionManager ()

@property (nonatomic, strong) NSOperationQueue *sessionOperationQueue;
@property (nonatomic, strong) FWTHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;
@property (nonatomic, strong) FWTNotifiableAuthenticator *authenticator;
@property (nonatomic, strong) dispatch_queue_t queueProcessQueue;
@property (nonatomic, strong) FWTRequestQueue *requestQueue;
/**
 This process allows the enable/disable of failed request processing.
 For now, it is not exposed.
 */
@property (nonatomic, assign) BOOL processQueue;

@end

@implementation FWTHTTPSessionManager

- (instancetype) initWithBaseURL:(NSURL *)baseUrl groupID:(NSString *)groupID andAuthenticator:(FWTNotifiableAuthenticator *)authenticator
{
    self = [super init];
    if (self) {
        self->_baseURL = baseUrl;
        self->_authenticator = authenticator;
        self->_processQueue = NO;
        self->_queueProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        self->_requestQueue = [FWTRequestQueue fetchInstanceWithGroupId:groupID];
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

- (void)startQueueProcess {
    if (self.processQueue == YES) {
        return;
    }
    self.processQueue = YES;
    [self _processQueue];
}

- (void)stopQueueProcess {
    self.processQueue = NO;
}

#pragma mark - Private methods

- (void) _retryRequest:(NSURLRequest *)request
               success:(nullable FWTHTTPSessionManagerSuccessBlock)success
               failure:(nullable FWTHTTPSessionManagerFailureBlock)failure {
    [self _performRequest:[self _resignRequest:request]
         enqueueOnFailure:NO
                  success:success
               andFailure:failure];
}

- (void) _buildTaskForPath:(NSString *)path
                    method:(FWTHTTPMethod)method
                parameters:(NSDictionary*)parameters
                   success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                andFailure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    NSURLRequest *request = [self _buildRequestWithPath:path method:method andParameters:parameters];
    [self _performRequest:request
         enqueueOnFailure:YES
                  success:success
               andFailure:failure];
}
- (void) _performRequest:(NSURLRequest *)request
        enqueueOnFailure:(BOOL)enqueue
                 success:(nullable FWTHTTPSessionManagerSuccessBlock)success
              andFailure:(nullable FWTHTTPSessionManagerFailureBlock)failure {
    __weak typeof(self) weakSelf = self;
    
    NSURLRequest *preProcessedRequest = [request copy];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.sessionOperationQueue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSLog(@"Response with Error: %@", connectionError);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        NSInteger statusCode = httpResponse.statusCode ?: connectionError.code;
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (connectionError) {
            NSInteger responseCode;
            if (enqueue) {
                responseCode = [strongSelf _enqueueRequest:preProcessedRequest withResponseCode:statusCode] ? FWTNotifiableEnqueueRequestResponseCode : statusCode;
            } else {
                responseCode = statusCode;
            }
            failure(responseCode, connectionError);
            return;
        }
        
        id responseData = [strongSelf _jsonFromData:data];
        
        if (httpResponse != nil && (statusCode < 200 || statusCode >= 300)) {
            NSDictionary *userInfo = [responseData isKindOfClass:[NSDictionary class]] ? (NSDictionary *)responseData : @{};
            failure(statusCode, [NSError errorWithDomain:@"FWTNotifiableError" code:statusCode userInfo:userInfo]);
            return;
        }
        
        success(responseData);
    }];
}

- (BOOL) _enqueueRequest:(NSURLRequest *)request withResponseCode:(NSInteger)responseCode {
    if (![SupportedErrorsForEnqueue containsObject:@(responseCode)]) {
        return NO;
    }
    
    [self.requestQueue addRequest:request];
    return YES;
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

#pragma mark - Session processor

- (void) _processQueue {
    
    BOOL process = NO;
    @synchronized (self) {
        process = self.processQueue;
    }
    
    if (process == NO) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void(^finishBlock)(void) = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kProcessQueueInterval * NSEC_PER_SEC)), weakSelf.queueProcessQueue, ^{
            [weakSelf _processQueue];
        });
    };
    
    NSURLRequest *request = nil;
    @synchronized (self) {
        request = [self.requestQueue fetchFirst];
    }
    
    if (request == nil) {
        finishBlock();
        return;
    }
    
    [self _retryRequest:request success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        @synchronized (strongSelf.requestQueue) {
            [strongSelf.requestQueue removeRequest:request];
        }
        finishBlock();
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        @synchronized (strongSelf.requestQueue) {
            [strongSelf.requestQueue moveRequestToEndOfTheQueue:request];
        }
        finishBlock();
    }];
}

@end

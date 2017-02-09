//
//  FWTHTTPSessionManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import "FWTHTTPSessionManager.h"
#import "FWHTTPRequestSerializer.h"
#import <AFNetworking/AFHTTPSessionManager.h>

NSString *const FWTHTTPSessionManagerIdentifier = @"com.futureworkshops.notifiable.FWTHTTPSessionManager";

@interface FWTHTTPSessionManager () <NSURLSessionDelegate>

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSOperationQueue *sessionOperationQueue;
@property (nonatomic, strong) FWHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;

@end

@implementation FWTHTTPSessionManager

- (instancetype) initWithBaseURL:(NSURL *)baseUrl
{
    self = [super init];
    if (self) {
        self->_sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseUrl];
        self->_sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        self->_baseURL = baseUrl;
    }
    return self;
}

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

- (NSURLSession *)urlSession
{
    if (self->_urlSession == nil) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:FWTHTTPSessionManagerIdentifier];
        self->_urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.sessionOperationQueue];
    }
    return self->_urlSession;
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

- (FWHTTPRequestSerializer *)requestSerializer
{
    if (self->_requestSerializer == nil) {
        self->_requestSerializer = [[FWHTTPRequestSerializer alloc] init];
    }
    return self->_requestSerializer;
}

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
{
    return [self.sessionManager GET:URLString
                         parameters:parameters
                           progress:nil
                            success:success
                            failure:failure];
}

- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable NSDictionary *)parameters
                                 success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                 failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
{
    return [self.sessionManager PATCH:URLString
                           parameters:parameters
                              success:success
                              failure:failure];
}

- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable NSDictionary *)parameters
                                  success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
{
    return [self.sessionManager DELETE:URLString
                            parameters:parameters
                               success:success
                               failure:failure];
}

- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable NSDictionary *)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
{
    return [self.sessionManager PUT:URLString
                         parameters:parameters
                            success:success
                            failure:failure];
}

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable NSDictionary *)parameters
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
{
    return [self.sessionManager POST:URLString
                          parameters:parameters
                            progress:nil
                             success:success
                             failure:failure];
}

- (NSURLRequest *) _buildRequestWithMethod:(FWHTTPMethod)method
                             andParameters:(NSDictionary *)paramters
{
    NSURLRequest *request = [self.requestSerializer buildRequestWithBaseURL:self.baseURL
                                                                 parameters:paramters
                                                                 andHeaders:self.HTTPRequestHeaders
                                                                  forMethod:method];
    return request;
}

- (void) setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [self.mutableHeaders setValue:value
                           forKey:field];
}

@end

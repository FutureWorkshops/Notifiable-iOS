//
//  FWTHTTPSessionManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import "FWTHTTPSessionManager.h"
#import "FWTHTTPRequestSerializer.h"
#import "FWTSessionTaskDelegate.h"

NSString *const FWTHTTPSessionManagerIdentifier = @"com.futureworkshops.notifiable.FWTHTTPSessionManager";

@interface FWTHTTPSessionManager () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSOperationQueue *sessionOperationQueue;
@property (nonatomic, strong) FWTHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;
@property (nonatomic, strong) NSMutableDictionary<NSString *, FWTSessionTaskDelegate *> *delegates;

@end

@implementation FWTHTTPSessionManager

- (instancetype) initWithBaseURL:(NSURL *)baseUrl
{
    self = [super init];
    if (self) {
        self->_baseURL = baseUrl;
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

- (NSMutableDictionary<NSString *,FWTSessionTaskDelegate *> *)delegates {
    if (self->_delegates == nil) {
        self->_delegates = [[NSMutableDictionary alloc] init];
    }
    return self->_delegates;
}

- (FWTHTTPRequestSerializer *)requestSerializer
{
    if (self->_requestSerializer == nil) {
        self->_requestSerializer = [[FWTHTTPRequestSerializer alloc] init];
    }
    return self->_requestSerializer;
}

#pragma mark - Public methods

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters
                               success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                               failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    return [self _buildTaskForPath:URLString
                            method:FWTHTTPMethodGET
                          parameters:parameters
                             success:success
                          andFailure:failure];
}

- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable NSDictionary *)parameters
                                 success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                 failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    return [self _buildTaskForPath:URLString
                            method:FWTHTTPMethodPATCH
                          parameters:parameters
                             success:success
                          andFailure:failure];
}

- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable NSDictionary *)parameters
                                  success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                  failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    return [self _buildTaskForPath:URLString
                            method:FWTHTTPMethodDELETE
                          parameters:parameters
                             success:success
                          andFailure:failure];
}

- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable NSDictionary *)parameters
                               success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                               failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    return [self _buildTaskForPath:URLString
                            method:FWTHTTPMethodPUT
                          parameters:parameters
                             success:success
                          andFailure:failure];
}

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable NSDictionary *)parameters
                                success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                failure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    return [self _buildTaskForPath:URLString
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

#pragma mark - Private methods

- (NSURLSessionDataTask *) _buildTaskForPath:(NSString *)path
                                      method:(FWTHTTPMethod)method
                                    parameters:(NSDictionary*)parameters
                                       success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                    andFailure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    NSURLRequest *request = [self _buildRequestWithPath:path method:method andParameters:parameters];
    NSURLSessionDataTask *task = [self _buildTaskForRequest:request];
    FWTSessionTaskDelegate *delegate = [[FWTSessionTaskDelegate alloc] initWithTask:task
                                                                       successBlock:success
                                                                         andFailure:failure];
    [self.delegates setObject:delegate forKey:task.taskDescription];
    [task resume];
    
    return task;
}

- (NSURLSessionDataTask *) _buildTaskForRequest:(NSURLRequest *)request
{
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request];
    return dataTask;
}

- (NSURLRequest *) _buildRequestWithPath:(NSString *)path
                                  method:(FWTHTTPMethod)method
                           andParameters:(NSDictionary *)paramters
{
    NSURL* url = [self.baseURL URLByAppendingPathComponent:path];
    NSURLRequest *request = [self.requestSerializer buildRequestWithBaseURL:url
                                                                 parameters:paramters
                                                                 andHeaders:self.HTTPRequestHeaders
                                                                  forMethod:method];
    return request;
}

- (FWTSessionTaskDelegate *) _delegateForTask:(NSURLSessionTask *)task
{
    NSString *taskDescription = task.taskDescription;
    if (taskDescription == nil) {
        return nil;
    }
    
    FWTSessionTaskDelegate *delegate = self.delegates[taskDescription];
    return delegate;
}

#pragma mark - URLSession delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    FWTSessionTaskDelegate *delegate = [self _delegateForTask:task];
    if (delegate == nil) {
        return;
    }
    
    [self.delegates removeObjectForKey:task.description];
    [delegate finishTask:task withError:error];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    FWTSessionTaskDelegate *delegate = [self _delegateForTask:dataTask];
    if (delegate == nil) {
        return;
    }
    
    [delegate appendData:data];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    FWTSessionTaskDelegate *delegate = [self _delegateForTask:downloadTask];
    if (delegate == nil) {
        return;
    }
    
    [delegate extractDataFromURL:location];
}

@end

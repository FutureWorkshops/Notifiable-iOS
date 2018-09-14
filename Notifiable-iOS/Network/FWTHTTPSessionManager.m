//
//  FWTHTTPSessionManager.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import "FWTHTTPSessionManager.h"
#import "FWTHTTPRequestSerializer.h"

NSString *const FWTHTTPSessionManagerIdentifier = @"com.futureworkshops.notifiable.FWTHTTPSessionManager";

@interface FWTHTTPSessionManager () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSOperationQueue *sessionOperationQueue;
@property (nonatomic, strong) FWTHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;

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

    __weak typeof(self) weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:self.sessionOperationQueue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSLog(@"Response with Error: %@", connectionError);
        if (connectionError) {
            failure(nil, connectionError);
            return;
        }
        
        id responseData = [weakSelf _jsonFromData:data];
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse && (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300)) {
            NSDictionary *userInfo = [responseData isKindOfClass:[NSDictionary class]] ? (NSDictionary *)responseData : @{};
            failure(nil, [NSError errorWithDomain:@"FWTNotifiableError" code:httpResponse.statusCode userInfo:userInfo]);
            return;
        }
        
        success(nil, responseData);
    }];
    
    return nil;
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

- (id) _jsonFromData:(NSData *)data
{
    NSError *error;
    id jsonContent = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error || jsonContent == nil) {
        return data;
    } else {
        return jsonContent;
    }
}

#pragma mark - URLSession delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    
}

@end

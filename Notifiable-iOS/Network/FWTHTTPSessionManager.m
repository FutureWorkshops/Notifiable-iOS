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

@interface FWTHTTPSessionManager ()

@property (nonatomic, strong) NSOperationQueue *sessionOperationQueue;
@property (nonatomic, strong) FWTHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;
@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation FWTHTTPSessionManager

- (instancetype) initWithBaseURL:(NSURL *)baseUrl session:(NSURLSession *)session
{
    self = [super init];
    if (self) {
        self->_baseURL = baseUrl;
        self->_urlSession = session;
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

#pragma mark - Private methods

- (void) _buildTaskForPath:(NSString *)path
                    method:(FWTHTTPMethod)method
                parameters:(NSDictionary*)parameters
                   success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                andFailure:(nullable FWTHTTPSessionManagerFailureBlock)failure
{
    NSURLRequest *request = [self _buildRequestWithPath:path method:method andParameters:parameters];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Response with Error: %@", error);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (error) {
            failure(httpResponse.statusCode, error);
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
    [task resume];
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

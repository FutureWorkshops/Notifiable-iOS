//
//  FWTHTTPSessionManager.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FWTHTTPSessionManagerSuccessBlock)(NSURLSessionTask *task, id _Nullable responseObject);
typedef void(^FWTHTTPSessionManagerFailureBlock)(NSURLSessionTask * _Nullable task, NSError *error);

@interface FWTHTTPSessionManager : NSObject

@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *HTTPRequestHeaders;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithBaseURL:(NSURL *)baseUrl NS_DESIGNATED_INITIALIZER;

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters
                               success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                               failure:(nullable FWTHTTPSessionManagerFailureBlock)failure;

- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable NSDictionary *)parameters
                                 success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                 failure:(nullable FWTHTTPSessionManagerFailureBlock)failure;

- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable NSDictionary *)parameters
                                  success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                  failure:(nullable FWTHTTPSessionManagerFailureBlock)failure;

- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable NSDictionary *)parameters
                               success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                               failure:(nullable FWTHTTPSessionManagerFailureBlock)failure;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable NSDictionary *)parameters
                                success:(nullable FWTHTTPSessionManagerSuccessBlock)success
                                failure:(nullable FWTHTTPSessionManagerFailureBlock)failure;

- (void) setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end

NS_ASSUME_NONNULL_END

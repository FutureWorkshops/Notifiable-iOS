//
//  FWTHTTPSessionManager.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWTHTTPSessionManager : NSObject

@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *HTTPRequestHeaders;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithBaseURL:(NSURL *)baseUrl NS_DESIGNATED_INITIALIZER;

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable NSDictionary *)parameters
                                 success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                 failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable NSDictionary *)parameters
                                  success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable NSDictionary *)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable NSDictionary *)parameters
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

- (void) setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end

NS_ASSUME_NONNULL_END

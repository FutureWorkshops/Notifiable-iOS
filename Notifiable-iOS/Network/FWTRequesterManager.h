//
//  FWTRequesterManager.h
//  Pods
//
//  Created by Igor Fereira on 19/01/2016.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FWTAFNetworkingSuccessBlock)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject);
typedef void(^FWTAFNetworkingFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);

@class FWTHTTPRequester;
@protocol FWTNotifiableLogger;

@interface FWTRequesterManager : NSObject

typedef NS_ENUM(NSUInteger, FWTNotifiableLogLevel) {
    FWTNotifiableLogLevelNone,
    FWTNotifiableLogLevelInfo,
    FWTNotifiableLogLevelError
};

@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;
@property (nonatomic, assign) id<FWTNotifiableLogger> logger;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRequester:(FWTHTTPRequester *)requester;
- (instancetype)initWithRequester:(FWTHTTPRequester *)requester
                    retryAttempts:(NSInteger)attempts
                    andRetryDelay:(NSTimeInterval)delay NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
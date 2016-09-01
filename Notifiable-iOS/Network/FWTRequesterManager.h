//
//  FWTRequesterManager.h
//  Pods
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FWTHTTPRequester;
@class FWTNotifiableDevice;
@protocol FWTNotifiableLogger;

typedef void (^FWTSimpleRequestResponse)(BOOL success, NSError * _Nullable error);
typedef void (^FWTDeviceTokenIdResponse)(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error);
typedef void (^FWTDeviceListResponse)(NSArray<FWTNotifiableDevice *> *devices, NSError * _Nullable error);

@interface FWTRequesterManager : NSObject

@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;
@property (nonatomic, strong) id<FWTNotifiableLogger> logger;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRequester:(FWTHTTPRequester *)requester;
- (instancetype)initWithRequester:(FWTHTTPRequester *)requester
                    retryAttempts:(NSInteger)attempts
                    andRetryDelay:(NSTimeInterval)delay NS_DESIGNATED_INITIALIZER;

- (void)registerDeviceWithUserAlias:(NSString * _Nullable)userAlias
                              token:(NSData *)token
                               name:(NSString * _Nullable)name
                             locale:(NSLocale * _Nullable)locale
                  deviceInformation:(NSDictionary * _Nullable)deviceInformation
                  completionHandler:(_Nullable FWTDeviceTokenIdResponse)handler;

- (void)updateDevice:(NSNumber *)deviceTokenId
       withUserAlias:(NSString * _Nullable)alias
               token:(NSData * _Nullable)token
                name:(NSString * _Nullable)name
              locale:(NSLocale * _Nullable)locale
   deviceInformation:(NSDictionary * _Nullable)deviceInformation
   completionHandler:(_Nullable FWTDeviceTokenIdResponse)handler;

- (void)markNotificationAsOpened:(NSNumber *)notificationId
                         forUser:(NSString * _Nullable)userAlias
                andDeviceTokenId:(NSNumber *)deviceTokenId
           withCompletionHandler:(_Nullable FWTSimpleRequestResponse)handler;

- (void)unregisterTokenId:(NSNumber *)tokenId
                userAlias:(NSString * _Nullable)userAlias
        completionHandler:(_Nullable FWTSimpleRequestResponse)handler;

- (void)listDevicesOfUser:(NSString *)userAlias
        completionHandler:(_Nullable FWTDeviceListResponse)handler;

@end

NS_ASSUME_NONNULL_END

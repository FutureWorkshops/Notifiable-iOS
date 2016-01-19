//
//  FWTRequestManager.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 15/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FWTRequestManagerSuccessBlock)(NSDictionary * _Nullable response);
typedef void(^FWTRequestManagerFailureBlock)(NSInteger responseCode, NSError * error);

@class FWTNotifiableAuthenticator;

@interface FWTHTTPRequester : NSObject

@property (nonatomic, readonly, strong) NSURL* baseUrl;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBaseUrl:(NSString*)baseUrl
               andAuthenticator:(FWTNotifiableAuthenticator*)authenticator NS_DESIGNATED_INITIALIZER;
- (void)registerDeviceWithParams:(NSDictionary *)params
                         success:(_Nullable FWTRequestManagerSuccessBlock)success
                         failure:(_Nullable FWTRequestManagerFailureBlock)failure;
- (void)updateDeviceWithTokenId:(NSNumber *)tokenId
                         params:(NSDictionary *)params
                        success:(_Nullable FWTRequestManagerSuccessBlock)success
                        failure:(_Nullable FWTRequestManagerFailureBlock)failure;
- (void)unregisterToken:(NSString *)token
                success:(FWTRequestManagerSuccessBlock)success
                failure:(FWTRequestManagerFailureBlock)failure;
- (void)markNotificationAsOpenedWithParams:(NSDictionary *)params
                                   success:(FWTRequestManagerSuccessBlock)success
                                   failure:(FWTRequestManagerFailureBlock)failure;
@end

NS_ASSUME_NONNULL_END

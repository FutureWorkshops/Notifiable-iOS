//
//  FWTPushNotificationManager.h
//  FWTPushNotifications
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

extern NSString * const FWTPushNotificationsAuthTokenKey;
extern NSString * const FWTPushNotificationsUserIdKey;
extern NSString * const FWTPushNotificationsUserDictionaryKey;

@interface FWTPushNotificationManager : NSObject

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;

+ (instancetype)sharedManager;

- (void)setUseBasicAuthWithUsername:(NSString *)username andPassword:(NSString *)password;

- (void)registerTokenWithParams:(NSDictionary *)params;
- (void)registerTokenIfNeededWithParams:(NSDictionary *)params;
- (void)unregisterTokenForUserId:(NSString *)userId;

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

@end

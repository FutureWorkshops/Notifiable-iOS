//
//  FWTPushNotificationManager.h
//  FWTPushNotifications
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

extern NSString * const FWTPushNotificationsAuthTokenKey;
extern NSString * const FWTPushNotificationsUserIdKey;


@interface FWTPushNotificationManager : NSObject

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;

+ (instancetype)sharedManager;
- (void)registerTokenIfNeededWithParams:(NSDictionary *)params;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

@end

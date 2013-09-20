//
//  FWTPushNotificationManager.h
//  FWTPushNotifications
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

@interface FWTPushNotificationManager : NSObject

@property (nonatomic, strong) NSURL *APIURL;
@property (nonatomic, strong) NSString *APIKey;
@property (nonatomic, strong) NSString *deviceId, *deviceName;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay, timeoutInterval;

+ (instancetype)sharedManager;
- (void)registerTokenInNeeded;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

@end

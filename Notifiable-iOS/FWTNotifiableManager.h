//
//  FWTNotifiableManager.h
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

extern NSString * const FWTNotifiableDidRegisterWithAPNSNotification;
extern NSString * const FWTNotifiableFailedToRegisterWithAPNSNotification;

typedef void (^FWTNotifiableOperationCompletionHandler)(BOOL success);

@interface FWTNotifiableManager : NSObject

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;
@property (nonatomic, assign) BOOL debugLogging;

+ (instancetype)sharedManager;
+ (BOOL)userAllowsPushNotificationsForType:(UIRemoteNotificationType)types;

- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo;
- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo completionHandler:(FWTNotifiableOperationCompletionHandler)hanlder;
- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo extendedParameters:(NSDictionary *)parameters completionHandler:(FWTNotifiableOperationCompletionHandler)handler;
- (void)anonymiseTokenWithUserInfo:(NSDictionary *)userInfo;
- (void)anonymiseTokenWithUserInfo:(NSDictionary *)userInfo completionHandler:(FWTNotifiableOperationCompletionHandler)handler;
- (void)unregisterToken;
- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)hanlder;

// entry points for token registration
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

// Read receipts can be delivered back to server via this method
- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo forUserInfo:(NSDictionary *)userInfo;

@end

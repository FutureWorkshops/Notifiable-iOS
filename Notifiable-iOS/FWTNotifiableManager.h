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

+ (instancetype)sharedManager;
+ (BOOL)userAllowsPushNotificationsForType:(UIRemoteNotificationType)types;

- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo;
- (void)registerTokenWithUserInfo:(NSDictionary *)userInfo completionHandler:(FWTNotifiableOperationCompletionHandler)hanlder;
- (void)anonymiseTokenWithUserInfo:(NSDictionary *)userInfo;
- (void)anonymiseTokenWithUserInfo:(NSDictionary *)userInfo completionHandler:(FWTNotifiableOperationCompletionHandler)handler;
- (void)unregisterToken;
- (void)unregisterTokenWithCompletionHandler:(FWTNotifiableOperationCompletionHandler)hanlder;

// entry points for token registration
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end

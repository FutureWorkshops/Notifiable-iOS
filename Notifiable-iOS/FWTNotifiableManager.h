//
//  FWTNotifiableManager.h
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

extern NSString * const FWTNotifiableAuthTokenKey;
extern NSString * const FWTNotifiableUserIdKey;
extern NSString * const FWTNotifiableUserDictionaryKey;

@interface FWTNotifiableManager : NSObject

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;

+ (instancetype)sharedManager;

- (void)registerTokenWithParams:(NSDictionary *)params;
- (void)registerTokenIfNeededWithParams:(NSDictionary *)params;

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

@end
//
//  NSUserDefaults+FWTPushNotifications.h
//  FWTPushNotifications
//
//  Created by Kamil Kocemba on 19/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

@interface NSUserDefaults (FWTPushNotifications)

- (BOOL)didRegisterDeviceToken:(NSString *)token;
- (void)registerDeviceToken:(NSString *)token;
- (void)removeDeviceToken:(NSString *)token;

@end

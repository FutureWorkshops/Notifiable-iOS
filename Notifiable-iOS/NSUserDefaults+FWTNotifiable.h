//
//  NSUserDefaults+FWTNotifiable.h
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 19/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

@interface NSUserDefaults (FWTNotifiable)

- (BOOL)didRegisterDeviceToken:(NSString *)token forUserInfo:(NSString *)name;
- (void)registerDeviceToken:(NSString *)token forUserInfo:(NSString *)name;

@end

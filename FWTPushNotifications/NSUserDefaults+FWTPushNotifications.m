//
//  NSUserDefaults+FWTPushNotifications.m
//  FWTPushNotifications
//
//  Created by Kamil Kocemba on 19/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "NSUserDefaults+FWTPushNotifications.h"

@implementation NSUserDefaults (FWTPushNotifications)

static NSString *FWTDeviceTokenKey = @"FWTDeviceToken";

- (BOOL)didRegisterDeviceToken:(NSString *)token forUserInfo:(NSString *)name {
    NSString *key = [NSString stringWithFormat:@"%@_%@", FWTDeviceTokenKey, token];
    NSString *savedValue = [self valueForKey:key];
    if (!savedValue)
        return NO;
    return [savedValue isEqualToString:(name ?: @"")];
}

- (void)registerDeviceToken:(NSString *)token forUserInfo:(NSString *)name {
    NSString *key = [NSString stringWithFormat:@"%@_%@", FWTDeviceTokenKey, token];
    [self setValue:(name ?: @"") forKey:key];
    [self synchronize];
}

@end


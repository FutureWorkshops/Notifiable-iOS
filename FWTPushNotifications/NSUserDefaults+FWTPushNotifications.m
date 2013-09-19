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

- (BOOL)didRegisterDeviceToken:(NSString *)token {
    NSString *key = [NSString stringWithFormat:@"%@_%@", FWTDeviceTokenKey, token];
    return [self boolForKey:key];
}

- (void)registerDeviceToken:(NSString *)token {
    NSString *key = [NSString stringWithFormat:@"%@_%@", FWTDeviceTokenKey, token];
    [self setBool:YES forKey:key];
    [self synchronize];
}

@end


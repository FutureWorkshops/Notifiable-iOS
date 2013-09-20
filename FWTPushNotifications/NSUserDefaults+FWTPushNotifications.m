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
    
    BOOL matchFound = NO;
    
    if(!savedValue){
        matchFound = NO;
    }else if(name){
        matchFound = [savedValue isEqualToString:name];
    }else{
        matchFound = [savedValue length] == 0;
    }
    
    return matchFound;
}

- (void)registerDeviceToken:(NSString *)token forUserInfo:(NSString *)name {
    NSString *key = [NSString stringWithFormat:@"%@_%@", FWTDeviceTokenKey, token];
    [self setValue:(name ?: @"") forKey:key];
    [self synchronize];
}

@end


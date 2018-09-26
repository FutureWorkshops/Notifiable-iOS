//
//  NSUserDefaults+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 14/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import "NSUserDefaults+FWTNotifiable.h"
#import "FWTServerConfiguration.h"
#import "FWTNotifiableDevice.h"

#define FWTUserInfoNotifiableCurrentDeviceKey @"FWTUserInfoNotifiableCurrentDeviceKey"
#define FWTNotifiableServerConfiguration @"FWTNotifiableServerConfiguration"

@implementation NSUserDefaults (FWTNotifiable)

+ (NSUserDefaults *) userDefaultsWithGroupId:(NSString * _Nullable)groupId {
    if (groupId.length > 0) {
        return [[NSUserDefaults alloc] initWithSuiteName:groupId];
    } else {
        return [NSUserDefaults standardUserDefaults];
    }
}

- (void) syncronizeToGroupId:(NSString * _Nullable)groupId {
    NSUserDefaults *destination = [NSUserDefaults userDefaultsWithGroupId:groupId];
    BOOL changed = false;
    id serverConfiguration = [self objectForKey:FWTNotifiableServerConfiguration];
    if (serverConfiguration != nil) {
        [destination setObject:serverConfiguration forKey:FWTNotifiableServerConfiguration];
        changed = true;
    }
    id deviceData = [self objectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
    if (deviceData != nil) {
        changed = true;
        [destination setObject:deviceData forKey:FWTUserInfoNotifiableCurrentDeviceKey];
    }
    if (changed) {
        [destination synchronize];
    }
}

- (FWTServerConfiguration * _Nullable)storedConfiguration {
    NSData *configurationData = (NSData *)[self objectForKey:FWTNotifiableServerConfiguration];
    FWTServerConfiguration *configuration = (FWTServerConfiguration *)[NSKeyedUnarchiver unarchiveObjectWithData:configurationData];
    return configuration;
}

- (void) storeConfiguration:(FWTServerConfiguration *)configuration {
    NSData *configurationData = [NSKeyedArchiver archivedDataWithRootObject:configuration];
    [self setObject:configurationData forKey:FWTNotifiableServerConfiguration];
    [self synchronize];
}

- (void) clearStoredDevice {
    [self removeObjectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
    [self synchronize];
}

- (FWTNotifiableDevice *)storedDevice {
    NSData *deviceData = [self objectForKey:FWTUserInfoNotifiableCurrentDeviceKey];
    FWTNotifiableDevice *currentDevice = [NSKeyedUnarchiver unarchiveObjectWithData:deviceData];
    return currentDevice;
}

- (void) storeDevice:(FWTNotifiableDevice *)device {
    NSData *deviceData = [NSKeyedArchiver archivedDataWithRootObject:device];
    [self setObject:deviceData forKey:FWTUserInfoNotifiableCurrentDeviceKey];
    [self synchronize];
}

@end

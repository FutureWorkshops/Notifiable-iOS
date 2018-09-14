//
//  NSUserDefaults+FWTNotifiable.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 14/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FWTServerConfiguration;
@class FWTNotifiableDevice;

NS_ASSUME_NONNULL_BEGIN

@interface NSUserDefaults (FWTNotifiable)

+ (NSUserDefaults *) userDefaultsWithGroupId:(NSString * _Nullable)groupId;

- (FWTServerConfiguration * _Nullable)storedConfiguration;
- (void) storeConfiguration:(FWTServerConfiguration *)configuration;

- (void) syncronizeToGroupId:(NSString * _Nullable)groupId;

- (FWTNotifiableDevice *)storedDevice;
- (void) clearStoredDevice;
- (void) storeDevice:(FWTNotifiableDevice *)device;

@end

NS_ASSUME_NONNULL_END

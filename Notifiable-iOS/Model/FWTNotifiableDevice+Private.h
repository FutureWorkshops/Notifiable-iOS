//
//  FWTNotifiableDevice+Private.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWTNotifiableDevice (Private)

- (instancetype) deviceWithToken:(NSData *)token;
- (instancetype) deviceWithToken:(NSData *)token
                       andLocale:(NSLocale *)locale;

- (instancetype) deviceWithUser:(NSString * _Nullable)user
                           name:(NSString * _Nullable)name
                 andInformation:(NSDictionary * _Nullable)deviceInformation;

- (instancetype) deviceWithUser:(NSString * _Nullable)user;
- (instancetype) deviceWithName:(NSString * _Nullable)name;
- (instancetype) deviceWithInformation:(NSDictionary * _Nullable)deviceInformation;

@end

NS_ASSUME_NONNULL_END

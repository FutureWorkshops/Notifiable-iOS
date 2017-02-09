//
//  FWTNotifiableDevice+Private.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice+Private.h"

@implementation FWTNotifiableDevice (Private)

- (instancetype)deviceWithToken:(NSData *)token
{
    return [[FWTNotifiableDevice alloc] initWithToken:token
                                              tokenId:self.tokenId
                                               locale:self.locale
                                                 user:self.user
                                                 name:self.name
                                     customProperties:self.customProperties
                                   platformProperties:self.platformProperties];
}

- (instancetype)deviceWithToken:(NSData *)token
                         locale:(NSLocale *)locale
{
    return [[FWTNotifiableDevice alloc] initWithToken:token
                                              tokenId:self.tokenId
                                               locale:locale
                                                 user:self.user
                                                 name:self.name
                                     customProperties:self.customProperties
                                   platformProperties:self.platformProperties];
}

- (instancetype)deviceWithUser:(NSString *)user
                          name:(NSString *)name
              customProperties:(NSDictionary<NSString *, id> *)customProperties
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                               locale:self.locale
                                                 user:user
                                                 name:name
                                     customProperties:customProperties
                                   platformProperties:self.platformProperties];
}

- (instancetype)deviceWithUser:(NSString *)user
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                               locale:self.locale
                                                 user:user
                                                 name:self.name
                                     customProperties:self.customProperties
                                   platformProperties:self.platformProperties];
}

- (instancetype)deviceWithName:(NSString *)name
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                               locale:self.locale
                                                 user:self.user
                                                 name:name
                                     customProperties:self.customProperties
                                   platformProperties:self.platformProperties];
}

- (instancetype)deviceWithCustomProperties:(NSDictionary *)customProperties
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                               locale:self.locale
                                                 user:self.user
                                                 name:self.name
                                     customProperties:customProperties
                                   platformProperties:self.platformProperties];
}

- (instancetype)deviceWithPlatformProperties:(NSDictionary<NSString *,id> *)platformProperties
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                               locale:self.locale
                                                 user:self.user
                                                 name:self.name
                                     customProperties:self.customProperties
                                   platformProperties:platformProperties];
}

@end

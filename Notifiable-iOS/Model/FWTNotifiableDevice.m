//
//  FWTNotifiableDevice.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice.h"

NSString * const FWTNotifiableDeviceToken = @"FWTNotifiableDeviceToken";
NSString * const FWTNotifiableDeviceTokenId = @"FWTNotifiableDeviceTokenId";
NSString * const FWTNotifiableDeviceLocale = @"FWTNotifiableDeviceLocale";
NSString * const FWTNotifiableDeviceUser = @"FWTNotifiableDeviceUser";
NSString * const FWTNotifiableDeviceName = @"FWTNotifiableDeviceName";
NSString * const FWTNotifiableDeviceInformation = @"FWTNotifiableDeviceInformation";
NSString * const FWTNotifiablePlatformProperties = @"FWTNotifiablePlatformProperties";

@interface FWTNotifiableDevice () <NSSecureCoding>

@end

@implementation FWTNotifiableDevice

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.token forKey:FWTNotifiableDeviceToken];
    [aCoder encodeObject:self.tokenId forKey:FWTNotifiableDeviceTokenId];
    [aCoder encodeObject:self.locale forKey:FWTNotifiableDeviceLocale];
    [aCoder encodeObject:self.user forKey:FWTNotifiableDeviceUser];
    [aCoder encodeObject:self.name forKey:FWTNotifiableDeviceName];
    [aCoder encodeObject:self.customProperties forKey:FWTNotifiableDeviceInformation];
    [aCoder encodeObject:self.platformProperties forKey:FWTNotifiablePlatformProperties];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSData *token = [aDecoder decodeObjectForKey:FWTNotifiableDeviceToken];
    NSNumber *tokenId = [aDecoder decodeObjectForKey:FWTNotifiableDeviceTokenId];
    NSLocale *locale = [aDecoder decodeObjectForKey:FWTNotifiableDeviceLocale];
    NSString *user = [aDecoder decodeObjectForKey:FWTNotifiableDeviceUser];
    NSString *name = [aDecoder decodeObjectForKey:FWTNotifiableDeviceName];
    NSDictionary<NSString *, id> *customProperties = [aDecoder decodeObjectForKey:FWTNotifiableDeviceInformation];
    NSDictionary<NSString *, id> *platformProperties = [aDecoder decodeObjectForKey:FWTNotifiablePlatformProperties];
    
    NSAssert(token != nil && tokenId != nil, @"The encoded object doesn't have all the required informations.");
    
    return [self initWithToken:token tokenId:tokenId locale:locale user:user name:name customProperties:customProperties platformProperties:platformProperties];
}

- (instancetype)initWithToken:(NSData *)token
                      tokenId:(NSNumber *)tokenId
                    andLocale:(nonnull NSLocale *)locale
{
    return [self initWithToken:token
                       tokenId:tokenId
                        locale:locale
                          user:nil
                          name:nil
              customProperties:nil
            platformProperties:nil];
}

- (instancetype)initWithToken:(NSData *)token
                      tokenId:(NSNumber *)tokenId
                       locale:(NSLocale *)locale
                         user:(NSString *)user
                         name:(NSString *)name
             customProperties:(NSDictionary<NSString *, id> *)customProperties
           platformProperties:(NSDictionary<NSString *,id> * _Nullable)platformProperties
{
    self = [super init];
    if (self) {
        self->_token = token;
        self->_tokenId = tokenId;
        self->_user = user;
        self->_name = name;
        self->_customProperties = customProperties;
        self->_locale = locale;
        self->_platformProperties = platformProperties;
    }
    return self;
}

@end

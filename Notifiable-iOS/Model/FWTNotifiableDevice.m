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
    [aCoder encodeObject:self.information forKey:FWTNotifiableDeviceInformation];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSData *token = [aDecoder decodeObjectForKey:FWTNotifiableDeviceToken];
    NSNumber *tokenId = [aDecoder decodeObjectForKey:FWTNotifiableDeviceTokenId];
    NSLocale *locale = [aDecoder decodeObjectForKey:FWTNotifiableDeviceLocale];
    NSString *user = [aDecoder decodeObjectForKey:FWTNotifiableDeviceUser];
    NSString *name = [aDecoder decodeObjectForKey:FWTNotifiableDeviceName];
    NSDictionary *information = [aDecoder decodeObjectForKey:FWTNotifiableDeviceInformation];
    
    NSAssert(token != nil && tokenId != nil, @"The encoded object doesn't have all the required informations.");
    
    return [self initWithToken:token tokenId:tokenId locale:locale user:user name:name information:information];
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
                   information:nil];
}

- (instancetype)initWithToken:(NSData *)token
                      tokenId:(NSNumber *)tokenId
                       locale:(NSLocale *)locale
                         user:(NSString *)user
                         name:(NSString *)name
                  information:(NSDictionary *)information
{
    self = [super init];
    if (self) {
        self->_token = token;
        self->_tokenId = tokenId;
        self->_user = user;
        self->_name = name;
        self->_information = information;
        self->_locale = locale;
    }
    return self;
}

@end

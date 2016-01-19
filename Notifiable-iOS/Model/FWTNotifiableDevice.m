//
//  FWTNotifiableDevice.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 19/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice.h"

NSString * const FWTNotifiableDeviceToken = @"FWTNotifiableDeviceToken";
NSString * const FWTNotifiableDeviceTokenId = @"FWTNotifiableDeviceTokenId";
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
    [aCoder encodeObject:self.user forKey:FWTNotifiableDeviceUser];
    [aCoder encodeObject:self.name forKey:FWTNotifiableDeviceName];
    [aCoder encodeObject:self.information forKey:FWTNotifiableDeviceInformation];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSData *token = [aDecoder decodeObjectForKey:FWTNotifiableDeviceToken];
    NSNumber *tokenId = [aDecoder decodeObjectForKey:FWTNotifiableDeviceTokenId];
    NSString *user = [aDecoder decodeObjectForKey:FWTNotifiableDeviceUser];
    NSString *name = [aDecoder decodeObjectForKey:FWTNotifiableDeviceName];
    NSDictionary *information = [aDecoder decodeObjectForKey:FWTNotifiableDeviceInformation];
    
    NSAssert(token != nil && tokenId != nil, @"The encoded object doesn't have all the required informations.");
    
    return [self initWithToken:token tokenId:tokenId user:user name:name information:information];
}

- (instancetype)initWithToken:(NSData *)token
                      tokenId:(NSNumber *)tokenId
{
    return [self initWithToken:token
                       tokenId:tokenId
                          user:nil
                          name:nil
                   information:nil];
}

- (instancetype)initWithToken:(NSData *)token
                      tokenId:(NSNumber *)tokenId
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
    }
    return self;
}

@end

//
//  FWTNotifiableDevice+Private.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 19/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice+Private.h"

@implementation FWTNotifiableDevice (Private)

- (instancetype) deviceWithToken:(NSData *)token
{
    return [[FWTNotifiableDevice alloc] initWithToken:token
                                              tokenId:self.tokenId
                                                 user:self.user
                                                 name:self.name
                                          information:self.information];
}

- (instancetype) deviceWithUser:(NSString *)user
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                                 user:user
                                                 name:self.name
                                          information:self.information];
}

- (instancetype) deviceWithName:(NSString *)name
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                                 user:self.user
                                                 name:name
                                          information:self.information];
}

- (instancetype) deviceWithInformation:(NSDictionary *)deviceInformation
{
    return [[FWTNotifiableDevice alloc] initWithToken:self.token
                                              tokenId:self.tokenId
                                                 user:self.user
                                                 name:self.name
                                          information:self.information];
}

@end

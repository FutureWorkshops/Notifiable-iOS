//
//  FWTNotifiableDevice+Parser.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice+Parser.h"

@implementation FWTNotifiableDevice (Parser)

- (instancetype)initWithUserName:(NSString *)userName dictionary:(NSDictionary*)dict
{
    NSNumber *tokenId = dict[@"id"];
    if ([tokenId isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    NSString *name = dict[@"name"];
    if ([name isKindOfClass:[NSNull class]]) {
        name = nil;
    }
    
    NSDictionary *customProperties = dict[@"custom_properties"];
    if ([customProperties isKindOfClass:[NSNull class]]) {
        customProperties = nil;
    }
    
    return [self initWithToken:[[NSData alloc] init]
                       tokenId:tokenId
                        locale:[NSLocale autoupdatingCurrentLocale]
                          user:userName
                          name:name
              customProperties:[NSDictionary dictionaryWithDictionary:customProperties]];
}

@end

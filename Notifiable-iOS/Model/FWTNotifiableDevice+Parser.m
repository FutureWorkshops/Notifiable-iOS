//
//  FWTNotifiableDevice+Parser.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice+Parser.h"

@implementation FWTNotifiableDevice (Parser)

- (instancetype)initWithUserName:(NSString *)userName dictionary:(NSDictionary*)dict
{
    NSMutableDictionary *mutableElement = [[NSMutableDictionary alloc] init];
    
    NSNumber *tokenId = dict[@"id"];
    if ([tokenId isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    NSString *name = dict[@"name"];
    if ([name isKindOfClass:[NSNull class]]) {
        name = nil;
    }
    
    for (NSString *element in dict) {
        if ([element isEqualToString:@"id"] || [element isEqualToString:@"name"]) {
            continue;
        }
        id value = dict[element];
        if (![value isKindOfClass:[NSNull class]]) {
            [mutableElement setValue:value forKey:element];
        }
    }
    
    return [self initWithToken:[[NSData alloc] init]
                       tokenId:tokenId
                        locale:[NSLocale autoupdatingCurrentLocale]
                          user:userName
                          name:name
                   information:[NSDictionary dictionaryWithDictionary:mutableElement]];
}

@end

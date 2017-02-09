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
    
    NSDictionary *customPropertiesDictionary = nil;
    id customPropertiesObject = dict[@"custom_properties"];
    if ([customPropertiesObject isKindOfClass:[NSNull class]]) {
        customPropertiesDictionary = nil;
    } else if ([customPropertiesObject isKindOfClass:[NSDictionary class]]) {
        customPropertiesDictionary = customPropertiesObject;
    } else if ([customPropertiesObject isKindOfClass:[NSString class]]) {
        NSString *jsonString = customPropertiesObject;
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error == nil & jsonObject != nil && [jsonObject isKindOfClass:[NSDictionary class]]) {
            customPropertiesDictionary = jsonObject;
        }
    }
    
    NSMutableDictionary<NSString *, id> *mutablePlatformProperties = [[NSMutableDictionary alloc] init];
    NSSet *excludedKeysSet = [NSSet setWithArray:@[@"id", @"name", @"custom_properties"]];
    for (NSString *element in dict) {
        if ([excludedKeysSet containsObject:element]) {
            continue;
        }
        id value = dict[element];
        if (![value isKindOfClass:[NSNull class]]) {
            [mutablePlatformProperties setValue:value forKey:element];
        }
    }
    
    return [self initWithToken:[[NSData alloc] init]
                       tokenId:tokenId
                        locale:[NSLocale autoupdatingCurrentLocale]
                          user:userName
                          name:name
              customProperties:[NSDictionary dictionaryWithDictionary:customPropertiesDictionary]
            platformProperties:[NSDictionary dictionaryWithDictionary:mutablePlatformProperties]];
}

@end

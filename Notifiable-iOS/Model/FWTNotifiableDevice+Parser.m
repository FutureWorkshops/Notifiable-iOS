//
//  FWTNotifiableDevice+Parser.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 19/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice+Parser.h"

@implementation FWTNotifiableDevice (Parser)

- (instancetype)initWithUserName:(NSString *)userName dictionary:(NSDictionary*)dict
{
    NSMutableDictionary *mutableElement = [dict mutableCopy];
    
    NSNumber *tokenId = mutableElement[@"id"];
    NSString *name = mutableElement[@"name"];
    
    [dict setValue:nil forKey:@"id"];
    [dict setValue:nil forKey:@"name"];
    
    return [self initWithToken:[[NSData alloc] init] tokenId:tokenId locale:[NSLocale autoupdatingCurrentLocale] user:userName name:name information:dict];
}

@end

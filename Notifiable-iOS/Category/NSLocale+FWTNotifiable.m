//
//  NSLocale+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 26/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSLocale+FWTNotifiable.h"

@implementation NSLocale (FWTNotifiable)

+ (NSLocale *)fwt_autoupdatingCurrentLocale
{
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSString *identifier = locale.localeIdentifier;
    identifier = [identifier stringByReplacingOccurrencesOfString:@"[_-]+[\\w]*"
                                                       withString:@""
                                                          options:NSRegularExpressionSearch
                                                            range:NSMakeRange(0, identifier.length)];
    return [NSLocale localeWithLocaleIdentifier:identifier];
}

@end

//
//  NSLocale+FWTNotifiable.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSLocale+FWTNotifiable.h"

@implementation NSLocale (FWTNotifiable)

+ (NSLocale *)fwt_currentLocale
{
    NSString *baseLocation = @"";
    
    if (@available(iOS 10.5, *)) {
        baseLocation = [[NSLocale preferredLanguages] firstObject];
    } else {
        baseLocation = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    }
    
    if (baseLocation == nil || baseLocation.length == 0) {
        return [NSLocale autoupdatingCurrentLocale];
    }
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:baseLocation];
    return locale ?: [NSLocale autoupdatingCurrentLocale];
}

- (NSString *)fwt_countryCode {
    NSString *code = @"";
    
    if (@available(iOS 10.0, *)) {
        code = [self countryCode];
    } else {
        code = [self objectForKey:NSLocaleCountryCode];
    }
    
    return code ?: @"";
}

- (NSString *)fwt_languageCode {
    NSString *languageCode = @"";
    
    if (@available(iOS 10.0, *)) {
        languageCode = [self languageCode];
    } else {
        languageCode = [self objectForKey:NSLocaleLanguageCode];
    }
    
    return languageCode ?: @"";
}

@end

//
//  NSDate+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Ferreira on 4/19/16.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSDate+FWTNotifiable.h"

@implementation NSDate (FWTNotifiable)

+ (NSDate *)fwt_gmtDate
{
    NSDate *localDate = [NSDate date];
    NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSTimeInterval gmtTimeInterval = [localDate timeIntervalSinceReferenceDate] - timeZoneOffset;
    NSDate *gmtDate = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];
    return gmtDate;
}

@end

//
//  NSData+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 18/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSData+FWTNotifiable.h"

@implementation NSData (FWTNotifiable)

- (NSString *)fwt_notificationTokenString
{
    NSString *tokenString = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    NSString *clearToken = [[tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return clearToken;
}

@end

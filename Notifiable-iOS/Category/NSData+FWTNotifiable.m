//
//  NSData+FWTNotifiable.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSData+FWTNotifiable.h"

@implementation NSData (FWTNotifiable)

- (NSString *)hexString {
    const unsigned char *bytes = (const unsigned char *)self.bytes;
    NSMutableString *hex = [NSMutableString new];
    for (NSInteger i = 0; i < self.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return [hex copy];
}

- (NSString *)fwt_notificationTokenString
{
    NSString *tokenString = self.hexString;
    NSString *clearToken = [[tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return clearToken;
}

@end

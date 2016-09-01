//
//  FWTDefaultNotifiableLogger.m
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTDefaultNotifiableLogger.h"
#import "NSError+FWTNotifiable.h"

@implementation FWTDefaultNotifiableLogger

@synthesize logLevel = _logLevel;

- (void)logError:(NSError *)error
{
    if (self.logLevel >= FWTNotifiableLogLevelError) {
        NSLog(@"%@", [error fwt_localizedMessage]);
    }
}

- (void)logMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (self.logLevel >= FWTNotifiableLogLevelInformation) {
        va_list args;
        va_start(args, format);
        NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSLog(@"%@",msg);
    }
}

@end

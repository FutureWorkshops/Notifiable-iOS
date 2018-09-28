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
#if DEBUG
    if (self.logLevel >= FWTNotifiableLogLevelError) {
        NSLog(@"%@", [error fwt_localizedMessage]);
    }
#endif
}

- (void)logMessage:(NSString *)message
{
#if DEBUG
    if (self.logLevel >= FWTNotifiableLogLevelInformation) {
        NSLog(@"%@",message);
    }
#endif
}

- (void)logNotificationEvent:(FWTNotifiableNotificationEventLog)event forNotificationWithId:(NSNumber *)notificationId error:(NSError * _Nullable)error {
#if DEBUG
    if (self.logLevel >= FWTNotifiableLogLevelInformation) {
        NSLog(@"Event %lu on notification %@", event, notificationId);
    }
#endif
}


@end

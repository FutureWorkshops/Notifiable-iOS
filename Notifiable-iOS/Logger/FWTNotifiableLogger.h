//
//  FWTNotifiableLogger.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//
typedef NS_ENUM(NSUInteger, FWTNotifiableLogLevel) {
    FWTNotifiableLogLevelNone = 0,
    FWTNotifiableLogLevelError,
    FWTNotifiableLogLevelInformation,
} NS_SWIFT_NAME(LogLevel);

typedef NS_ENUM(NSUInteger, FWTNotifiableNotificationEventLog) {
    FWTNotifiableNotificationEventLogReceived = 0,
    FWTNotifiableNotificationEventLogOpened,
    FWTNotifiableNotificationEventLogStatusUpdate,
    FWTNotifiableNotificationEventLogStatusFailure
} NS_SWIFT_NAME(NotificationEvent);

NS_SWIFT_NAME(NotifiableLogger)
@protocol FWTNotifiableLogger <NSObject>

@property (nonatomic, assign) FWTNotifiableLogLevel logLevel NS_SWIFT_NAME(level);

- (void)logError:(NSError *)error NS_SWIFT_NAME(log(error:));
- (void)logNotificationEvent:(FWTNotifiableNotificationEventLog)event forNotificationWithId:(NSNumber *)notificationId NS_SWIFT_NAME(log(_:notificationId:));

@optional
- (void)logMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) NS_SWIFT_NAME(log(format:));

@end

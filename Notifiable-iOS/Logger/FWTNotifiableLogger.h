//
//  FWTNotifiableLogger.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//
typedef NS_ENUM(NSUInteger, FWTNotifiableLogLevel) {
    FWTNotifiableLogLevelNone = 0,
    FWTNotifiableLogLevelError,
    FWTNotifiableLogLevelInformation,
};

@protocol FWTNotifiableLogger <NSObject>

@property (nonatomic, assign) FWTNotifiableLogLevel logLevel;

- (void)logError:(NSError *)error;

@optional
- (void)logMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end

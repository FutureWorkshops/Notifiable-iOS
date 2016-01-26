//
//  NSError+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 18/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSError+FWTNotifiable.h"

static NSString * const FWTNotifiableErrorDomain = @"com.futureworkshops.FWTNotifiable.error";

@implementation NSError (FWTNotifiable)

+ (instancetype) fwt_errorWithCode:(NSInteger)code
                andUserInformation:(NSDictionary *)userInformation
{
    NSError *error = [[NSError alloc] initWithDomain:FWTNotifiableErrorDomain
                                                code:code
                                            userInfo:userInformation];
    return error;
}

+ (instancetype) fwt_errorWithUnderlyingError:(NSError * _Nullable)error
{
    if (error == nil) {
        return [NSError fwt_invalidOperationErrorWithUnderlyingError:nil];
    }
    
    switch (error.code) {
        case 401:
            return [NSError fwt_userAliasErrorWithUnderlyingError:error];
            break;
        case 403:
            return [NSError fwt_forbiddenErrorWithUnderlyingError:error];
            break;
        case 404:
            return [NSError fwt_invalidOperationErrorWithUnderlyingError:error];
            break;
        default:
            return [NSError fwt_errorWithCode:error.code
                                  description:error.localizedDescription
                           andUnderlyingError:error];
            break;
    }
}

+ (instancetype) fwt_userAliasErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self fwt_errorWithCode:FWTErrorUserAliasMissing
                       description:@"To perform this operation, you need to inform the user alias."
                andUnderlyingError:underlyingError];
}

+ (instancetype) fwt_invalidOperationErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self fwt_errorWithCode:FWTErrorInvalidOperation
                       description:@"Operation not available."
                andUnderlyingError:underlyingError];
}

+ (instancetype) fwt_forbiddenErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self fwt_errorWithCode:FWTErrorForbidden
                       description:@"Check the access ID and secret Key and try again."
                andUnderlyingError:underlyingError];
}

+ (instancetype) fwt_invalidDeviceInformationError:(NSError * _Nullable)underlyingError
{
    return [self fwt_errorWithCode:FWTErrorInvalidDeviceInformation
                       description:@"Check the device token id and device token and try again."
                andUnderlyingError:underlyingError];
}

+ (instancetype) fwt_invalidNotificationError:(NSError * _Nullable)underlyingError
{
    return [self fwt_errorWithCode:FWTErrorInvalidNotification
                       description:@"Notification without the localized_notification_id property."
                andUnderlyingError:underlyingError];
}

#pragma mark - Private methods

+ (instancetype) fwt_errorWithCode:(NSInteger)code
                       description:(NSString *)description
                andUnderlyingError:(NSError *)underlyingError
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    if (description) {
        [userInfo setObject:description forKey:NSLocalizedDescriptionKey];
    }
    if (underlyingError) {
        [userInfo setObject:underlyingError forKey:NSUnderlyingErrorKey];
    }
    return [self fwt_errorWithCode:code
                andUserInformation:[NSDictionary dictionaryWithDictionary:userInfo]];
}

- (NSString *)fwt_debugMessage
{
    NSString *message = self.debugDescription;
    if (message == nil) {
        message = self.localizedDescription;
    }
    
    if (self.localizedFailureReason) {
        message = [message stringByAppendingFormat:@"\n%@", self.localizedFailureReason];
    }
    return message;
}

@end

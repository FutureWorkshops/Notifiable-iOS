//
//  NSError+FWTNotifiable.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Errors that can occur during the FWTNotifiable operations.
 
 - FWTErrorInvalidOperation: The requested operation is not available (HTTP 404).
 - FWTErrorUserAliasMissing: The requested operation need the user alias information (HTTP 401).
 - FWTErrorForbidden: Authorization error (HTTP 403).
 - FWTErrorInvalidDeviceInformation: The request need more informations about the device.
*/
typedef NS_ENUM(NSInteger, FWTError) {
    FWTErrorInvalidOperation = -1004,
    FWTErrorUserAliasMissing,
    FWTErrorForbidden,
    FWTErrorInvalidDeviceInformation,
    FWTErrorInvalidNotification
};

@interface NSError (FWTNotifiable)

/**
 Create an error with the FWTNotifiable error domain.
 
 @see FWTError
 
 @param code            The error code.
 @param userInformation User information related to the error.
*/
+ (instancetype) fwt_errorWithCode:(NSInteger)code
                andUserInformation:(NSDictionary * _Nullable)userInformation;

/**
 Check the error code to see if matches the kwnown types, otherwise,
 create a new error with the specified code.
 
 @see FWTError
 
 @param underlyingError Original error.
*/
+ (instancetype) fwt_errorWithUnderlyingError:(NSError * _Nullable)underlyingError;

/**
 Create an error with the code FWTErrorUserAliasMissing.
 
 @see FWTError
 
 @param underlyingError Original error.
*/
+ (instancetype) fwt_userAliasErrorWithUnderlyingError:(NSError * _Nullable)underlyingError;
/**
 Create an error with the code FWTErrorInvalidOperation.
 
 @see FWTError
 
 @param underlyingError Original error.
 */
+ (instancetype) fwt_invalidOperationErrorWithUnderlyingError:(NSError * _Nullable)underlyingError;
/**
 Create an error with the code FWTErrorForbidden.
 
 @see FWTError
 
 @param underlyingError Original error.
 */
+ (instancetype) fwt_forbiddenErrorWithUnderlyingError:(NSError * _Nullable)underlyingError;
/**
 Create an error with the code FWTErrorInvalidDeviceInformation.
 
 @see FWTError
 
 @param underlyingError Original error.
 */
+ (instancetype) fwt_invalidDeviceInformationError:(NSError * _Nullable)underlyingError;
/**
 Create an error with the code FWTErrorInvalidNotification.
 
 @see FWTError
 
 @param underlyingError Original error.
 */
+ (instancetype) fwt_invalidNotificationError:(NSError * _Nullable)underlyingError;

- (NSString *) fwt_localizedMessage;

@end

NS_ASSUME_NONNULL_END

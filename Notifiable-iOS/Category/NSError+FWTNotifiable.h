//
//  NSError+FWTNotifiable.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 18/01/2016.
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
    FWTErrorInvalidDeviceInformation
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

- (NSString *) fwt_debugMessage;

@end

NS_ASSUME_NONNULL_END

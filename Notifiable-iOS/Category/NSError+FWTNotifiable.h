//
//  NSError+FWTNotifiable.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 18/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSInteger const FWTInvalidOperationError;
NSInteger const FWTUserAliasMissingError;
NSInteger const FWTForbiddenError;

@interface NSError (FWTNotifiable)

+ (instancetype) fwt_errorWithCode:(NSInteger)code
                andUserInformation:(NSDictionary * _Nullable)userInformation;
+ (instancetype) fwt_userAliasErrorWithUnderlyingError:(NSError * _Nullable)underlyingError;
+ (instancetype) fwt_invalidOperationErrorWithUnderlyingError:(NSError * _Nullable)underlyingError;
+ (instancetype) fwt_forbiddenErrorWithUnderlyingError:(NSError * _Nullable)underlyingError;

@end

NS_ASSUME_NONNULL_END

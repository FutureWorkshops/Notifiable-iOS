//
//  NSError+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 18/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "NSError+FWTNotifiable.h"

static NSString * const FWTNotifiableErrorDomain = @"com.futureworkshops.FWTNotifiable.error";

NSInteger const FWTInvalidOperationError = -1001;
NSInteger const FWTUserAliasMissingError = -1002;
NSInteger const FWTForbiddenError = -1003;

@implementation NSError (FWTNotifiable)

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

+ (instancetype) fwt_userAliasErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self fwt_errorWithCode:FWTUserAliasMissingError
                       description:@"To perform this operation, you need to inform the user alias."
                andUnderlyingError:underlyingError];
}

+ (instancetype) fwt_invalidOperationErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self fwt_errorWithCode:FWTUserAliasMissingError
                       description:@"Operation not available."
                andUnderlyingError:underlyingError];
}

+ (instancetype) fwt_forbiddenErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self fwt_errorWithCode:FWTUserAliasMissingError
                       description:@"Check the access ID and secret Key and try again."
                andUnderlyingError:underlyingError];
}

#pragma mark - Private methods

+ (instancetype) fwt_errorWithCode:(NSInteger)code
                andUserInformation:(NSDictionary *)userInformation
{
    NSError *error = [[NSError alloc] initWithDomain:FWTNotifiableErrorDomain
                                                code:code
                                            userInfo:userInformation];
    return error;
}



@end

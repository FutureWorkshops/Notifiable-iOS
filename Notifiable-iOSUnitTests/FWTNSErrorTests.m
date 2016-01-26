//
//  FWTNSErrorTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 26/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSError+FWTNotifiable.h"

@interface FWTNSErrorTests : XCTestCase

@end

@implementation FWTNSErrorTests

- (void) testError404
{
    NSError *underlyingError = [NSError errorWithDomain:@"test" code:404 userInfo:nil];
    NSError *error = [NSError fwt_errorWithUnderlyingError:underlyingError];
    XCTAssertEqualObjects(error, [NSError fwt_invalidOperationErrorWithUnderlyingError:underlyingError]);
    XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], underlyingError);
    XCTAssertEqual(error.code, FWTErrorInvalidOperation);
}

- (void) testError403
{
    NSError *underlyingError = [NSError errorWithDomain:@"test" code:403 userInfo:nil];
    NSError *error = [NSError fwt_errorWithUnderlyingError:underlyingError];
    XCTAssertEqualObjects(error, [NSError fwt_forbiddenErrorWithUnderlyingError:underlyingError]);
    XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], underlyingError);
    XCTAssertEqual(error.code, FWTErrorForbidden);
}

- (void) testError401
{
    NSError *underlyingError = [NSError errorWithDomain:@"test" code:401 userInfo:nil];
    NSError *error = [NSError fwt_errorWithUnderlyingError:underlyingError];
    XCTAssertEqualObjects(error, [NSError fwt_userAliasErrorWithUnderlyingError:underlyingError]);
    XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], underlyingError);
    XCTAssertEqual(error.code, FWTErrorUserAliasMissing);
}

- (void) testGeneralError
{
    NSError *underlyingError = [NSError errorWithDomain:@"test" code:500 userInfo:nil];
    NSError *error = [NSError fwt_errorWithUnderlyingError:underlyingError];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:underlyingError.localizedDescription forKey:NSLocalizedDescriptionKey];
    [userInfo setObject:underlyingError forKey:NSUnderlyingErrorKey];
    
    XCTAssertEqualObjects(error, [NSError fwt_errorWithCode:500 andUserInformation:userInfo]);
    XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], underlyingError);
    XCTAssertEqual(error.code, 500);
}

- (void) testInvalidOperationError
{
    NSError *error = [NSError fwt_errorWithUnderlyingError:nil];
    XCTAssertEqualObjects(error, [NSError fwt_invalidOperationErrorWithUnderlyingError:nil]);
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey]);
    XCTAssertEqual(error.code, FWTErrorInvalidOperation);
}

- (void) testInvalidDeviceInformationError
{
    NSError *error = [NSError fwt_invalidDeviceInformationError:nil];
    XCTAssertEqual(error.code, FWTErrorInvalidDeviceInformation);
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey]);
}

- (void) testInvalidNotificationError
{
    NSError *error = [NSError fwt_invalidNotificationError:nil];
    XCTAssertEqual(error.code, FWTErrorInvalidNotification);
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey]);
}

- (void) testErrorDescriptions
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:@"test" forKey:NSLocalizedDescriptionKey];
    [dictionary setObject:@"error" forKey:NSLocalizedFailureReasonErrorKey];
    
    NSError *error = [NSError fwt_errorWithCode:200 andUserInformation:dictionary];
    NSString *description = [error fwt_localizedMessage];
    XCTAssertEqualObjects(description, @"test\nerror");
    
    [dictionary removeObjectForKey:NSLocalizedDescriptionKey];
    error = [NSError fwt_errorWithCode:200 andUserInformation:dictionary];
    description = [error fwt_localizedMessage];
    NSString *expectedValue = [NSString stringWithFormat:@"%@\nerror", error.localizedDescription];
    XCTAssertEqualObjects(description, expectedValue);
}



@end

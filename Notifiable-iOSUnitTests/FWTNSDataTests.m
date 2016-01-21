//
//  FWTNSDataTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "NSData+FWTNotifiable.h"

@interface FWTNSDataTests : FWTTestCase

@end

@implementation FWTNSDataTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testTokenFormat
{
    NSString *tokenString = NSStringFromClass([self class]);
    NSData *tokenData = [tokenString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *formattedData = [tokenData fwt_notificationTokenString];
    XCTAssertEqualObjects(formattedData, @"4657544e53446174615465737473");
}

@end

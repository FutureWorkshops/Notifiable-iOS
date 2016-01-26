//
//  FWTAuthorizationTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "FWTNotifiableAuthenticator.h"
#import <OCMock/OCMock.h>

NSString * const FWTTestAccessId = @"access_id";
NSString * const FWTTestSecretKey = @"secret_key";

NSString * const FWTTestPath = @"path";

NSString * const FWTTestContent = @"content";

NSTimeInterval const FWTTestDateTimestamp = 1453393539;

NSString * const FWTTestAuthResult = @"CLYylIraZPl8JItknqVo+0WLwKM=";

NSString * const FWTTestDate = @"Thu, 21 Jan 2016 16:25:39 GMT";

@interface FWTAuthorizationTests : FWTTestCase

@property (nonatomic, strong) FWTNotifiableAuthenticator *authenticator;

@end

@implementation FWTAuthorizationTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
    self->_authenticator = nil;
}

- (FWTNotifiableAuthenticator *)authenticator
{
    if (self->_authenticator == nil) {
        self->_authenticator = [[FWTNotifiableAuthenticator alloc] initWithAccessId:FWTTestAccessId
                                                                       andSecretKey:FWTTestSecretKey];
    }
    return self->_authenticator;
}

- (void)testAuthorization
{
    id mock = OCMClassMock([NSDate class]);
    OCMStub([mock date]).andReturn([NSDate dateWithTimeIntervalSince1970:FWTTestDateTimestamp]);
    
    NSDictionary *headers = [self.authenticator authHeadersForPath:FWTTestPath
                                                        andHeaders:@{@"Content-Type":FWTTestContent}];
    
    XCTAssertEqual(headers.count, 3);
    NSString *authString = [NSString stringWithFormat:@"APIAuth %@:%@", FWTTestAccessId,FWTTestAuthResult];
    XCTAssertEqualObjects(headers[@"Authorization"], authString);
    XCTAssertEqualObjects(headers[@"Date"], FWTTestDate);
    
    [mock stopMocking];
    
}

@end

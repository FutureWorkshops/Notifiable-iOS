//
//  FWTRequestIntegrationTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 26/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FWTHTTPRequester.h"
#import "FWTNotifiableAuthenticator.h"

NSString * const FWTTestServerURL = @"http://fw-notifiable-staging2.herokuapp.com";
NSString * const FWTTestServerAccessId = @"9wx22jXs_f5HVaayKWLs";
NSString * const FWTTestServerSecretKey = @"AJpBYTZN2Jb++lwxwaRHXjfDvfiAPRyv6PzqW/u9lpXsuUpk31ctSxXO3Mq9dNls/hEQhOcPvtW0eNbTL1vE+g==";

NSString * const FWTToken = @"test";
NSString * const FWTLocale = @"en";
NSString * const FWTUser = @"test_user";

@interface FWTRequestIntegrationTests : XCTestCase

@property (nonatomic, strong) FWTHTTPRequester *requester;

@end

@implementation FWTRequestIntegrationTests

- (FWTHTTPRequester *)requester
{
    if (self->_requester == nil) {
        FWTNotifiableAuthenticator *authenticator = [[FWTNotifiableAuthenticator alloc] initWithAccessId:FWTTestServerAccessId
                                                                                            andSecretKey:FWTTestServerSecretKey];
        NSURL *url = [NSURL URLWithString:FWTTestServerURL];
        self->_requester = [[FWTHTTPRequester alloc] initWithBaseURL:url andAuthenticator:authenticator];
    }
    return self->_requester;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testRegisterWithoutParameters
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.requester registerDeviceWithParams:nil success:nil failure:nil]);
#pragma clang diagnostic pop
}

- (void) testRegisterDeviceClientError
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fail"];
    [self.requester registerDeviceWithParams:@{} success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
        XCTAssertTrue(NO, @"This method should fail");
        [expectation fulfill];
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        XCTAssertEqual(responseCode, 422);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testRegisterDevice
{
    NSString *token = @"test";
    NSString *locale = @"en";
    NSString *user = @"test_user";
    NSString *name = [NSString stringWithFormat:@"test_%@", [UIDevice currentDevice].name];
    __weak typeof(self) weakSelf = self;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register"];
    [self.requester registerDeviceWithParams:@{@"token":token, @"provider":@"apns", @"locale":locale, @"user":@{@"alias":user}, @"name":name}
                                     success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
                                         XCTAssertNotNil(response);
                                         NSNumber *tokenId = (NSNumber *)response[@"id"];
                                         XCTAssertNotNil(tokenId);
                                         [weakSelf _unregisterDeviceTokenId:tokenId
                                                                   withUser:user
                                                     andFullfillExpectation:expectation];
                                     } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
                                         XCTAssertTrue(NO, @"This method should succed");
                                         [expectation fulfill];
                                     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testRegisterAnonymousDevice
{
    NSString *name = [NSString stringWithFormat:@"test_%@", [UIDevice currentDevice].name];
    __weak typeof(self) weakSelf = self;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register"];
    [self.requester registerDeviceWithParams:@{@"token":FWTToken, @"provider":@"apns", @"locale":FWTLocale, @"name":name}
                                     success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
                                         XCTAssertNotNil(response);
                                         NSNumber *tokenId = (NSNumber *)response[@"id"];
                                         XCTAssertNotNil(tokenId);
                                         [weakSelf _unregisterDeviceTokenId:tokenId
                                                                   withUser:FWTUser
                                                     andFullfillExpectation:expectation];
                                     } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
                                         XCTAssertTrue(NO, @"This method should succed");
                                         [expectation fulfill];
                                     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testUpdateClientError
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update test with Invalid id"];
    
    [self.requester updateDeviceWithTokenId:@0 params:@{} success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
        XCTAssertTrue(NO, @"This method should fail");
        [expectation fulfill];
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(responseCode, 404);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    expectation = [self expectationWithDescription:@"Update test with empty params"];
    __block NSNumber *deviceTokenId;
    
    [self _registerDeviceAnonymous:NO andPerformBlock:^(FWTHTTPRequester *requester, NSNumber *tokenId) {
        deviceTokenId = tokenId;
        [requester updateDeviceWithTokenId:tokenId params:@{} success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
            XCTAssertTrue(NO, @"This method should fails");
            [expectation fulfill];
        } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
            XCTAssertNotNil(error);
            XCTAssertEqual(responseCode, 401);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    expectation = [self expectationWithDescription:@"Unregister"];
    [self _unregisterDeviceTokenId:deviceTokenId withUser:FWTUser andFullfillExpectation:expectation];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    NSNumber *deviceToken = nil;
    NSDictionary *params = nil;
    
    XCTAssertThrows([self.requester updateDeviceWithTokenId:deviceToken params:@{} success:nil failure:nil]);
    XCTAssertThrows([self.requester updateDeviceWithTokenId:@42 params:params success:nil failure:nil]);
}

- (void) testUpdateDevice
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update device"];
    __block NSNumber *deviceTokenId;
    [self _registerDeviceAnonymous:NO andPerformBlock:^(FWTHTTPRequester *requester, NSNumber *tokenId) {
        deviceTokenId = tokenId;
        [requester updateDeviceWithTokenId:tokenId
                                    params:@{@"token":FWTToken, @"provider":@"apns", @"locale":FWTLocale, @"user":@{@"alias":FWTUser}}
                                   success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
                                        XCTAssertNotNil(response);
                                        NSNumber *updatedId = (NSNumber *)response[@"id"];
                                        XCTAssertEqualObjects(tokenId, updatedId);
                                        [expectation fulfill];
                                   } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
                                       XCTAssertTrue(NO, @"This method should succed");
                                       [expectation fulfill];
                                   }];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    [self _unregisterDeviceTokenId:deviceTokenId withUser:FWTUser andFullfillExpectation:[self expectationWithDescription:@"Unregister"]];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testUpdateAnonymousDevice
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register device"];
    __block NSNumber *deviceTokenId;
    [self _registerDeviceAnonymous:YES andPerformBlock:^(FWTHTTPRequester *requester, NSNumber *tokenId) {
        deviceTokenId = tokenId;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    expectation = [self expectationWithDescription:@"Update device"];
    [self.requester updateDeviceWithTokenId:deviceTokenId
                                     params:@{@"token":FWTToken, @"provider":@"apns", @"locale":FWTLocale}
                                    success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
                                        XCTAssertNotNil(response);
                                        NSNumber *tokenId = (NSNumber *)response[@"id"];
                                        XCTAssertEqualObjects(tokenId, deviceTokenId);
                                        [expectation fulfill];
                                    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
                                        XCTAssertTrue(NO, @"This method should succed");
                                        [expectation fulfill];
                                    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    [self _unregisterDeviceTokenId:deviceTokenId withUser:nil andFullfillExpectation:[self expectationWithDescription:@"unregister"]];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testListDeviceClientError
{
    NSString *invalidUser = [NSString stringWithFormat:@"%f",[NSDate date].timeIntervalSince1970];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Failure"];
    [self.requester listDevicesOfUser:invalidUser success:^(NSArray * _Nonnull response) {
        XCTAssertTrue(NO, @"The test shoudl fail");
        [expectation fulfill];
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(responseCode, 404);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    NSString *user = nil;
    XCTAssertThrows([self.requester listDevicesOfUser:user success:nil failure:nil]);
}

- (void) testListDevice
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"List device"];
    [self.requester listDevicesOfUser:FWTUser success:^(NSArray * _Nonnull response) {
        XCTAssertNotNil(response);
        XCTAssertEqual(response.count, 0);
        [expectation fulfill];
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        XCTAssertTrue(NO, @"This method should succed");
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    expectation = [self expectationWithDescription:@"register"];
    __block NSNumber *deviceTokenId;
    [self _registerDeviceAnonymous:NO andPerformBlock:^(FWTHTTPRequester *requester, NSNumber *tokenId) {
        deviceTokenId = tokenId;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    expectation = [self expectationWithDescription:@"list"];
    [self.requester listDevicesOfUser:FWTUser success:^(NSArray * _Nonnull response) {
        XCTAssertNotNil(response);
        XCTAssertGreaterThanOrEqual(response.count, 1);
        [expectation fulfill];
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        XCTAssertTrue(NO, @"This method should succed");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    [self _unregisterDeviceTokenId:deviceTokenId withUser:FWTUser andFullfillExpectation:[self expectationWithDescription:@"unregister"]];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) _registerDeviceAnonymous:(BOOL)anonymous andPerformBlock:(void(^)(FWTHTTPRequester *requester, NSNumber *tokenId))block
{
    NSString *name = [NSString stringWithFormat:@"test_%@", [UIDevice currentDevice].name];
    NSMutableDictionary* params = [@{@"token":FWTToken, @"provider":@"apns", @"locale":FWTLocale, @"name":name} mutableCopy];
    if (!anonymous) {
        [params setObject:@{@"alias":FWTUser} forKey:@"user"];
    }
    
    FWTHTTPRequester *requester = self.requester;
    [requester registerDeviceWithParams:params success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
        XCTAssertNotNil(response);
        NSNumber *tokenId = (NSNumber *)response[@"id"];
        XCTAssertNotNil(tokenId);
        if (block) {
            block(requester, tokenId);
        }
    } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
        XCTAssertTrue(NO, @"This method should succed");
        if (block) {
            block(requester, nil);
        }
    }];
}

- (void) _unregisterDeviceTokenId:(NSNumber *)tokenId withUser:(NSString *)user andFullfillExpectation:(XCTestExpectation *)expectation
{
    [self.requester unregisterTokenId:tokenId
                            userAlias:user
                              success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
                                  [expectation fulfill];
                              } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
                                  XCTAssertTrue(NO, @"This method should succed");
                                  [expectation fulfill];
                              }];
}

@end

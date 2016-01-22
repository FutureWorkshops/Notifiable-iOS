//
//  FWTUserOperationTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 22/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "FWTNotifiableDevice.h"
#import "FWTRequesterManager.h"
#import "FWTNotifiableManager.h"
#import "FWTHTTPRequester.h"
#import <OCMock/OCMock.h>

@interface FWTUserOperationTests : FWTTestCase

@property (nonatomic, strong) id requesterManagerMock;
@property (nonatomic, strong) id httpRequestMock;
@property (nonatomic, strong) FWTNotifiableManager *manager;
@property (nonatomic, strong) NSNumber *deviceTokenId;

@end

@implementation FWTUserOperationTests

- (NSNumber *)deviceTokenId
{
    if (self->_deviceTokenId == nil) {
        self->_deviceTokenId = @42;
    }
    return self->_deviceTokenId;
}

- (FWTNotifiableManager *)manager
{
    if (self->_manager == nil) {
        self->_manager = [[FWTNotifiableManager alloc] initWithUrl:OCMOCK_ANY
                                                          accessId:OCMOCK_ANY
                                                      andSecretKey:OCMOCK_ANY];
    }
    return self->_manager;
}

- (void)mockRequester
{
    if (self->_requesterManagerMock == nil) {
        id requesterManagerMock = OCMClassMock([FWTRequesterManager class]);
        OCMStub([requesterManagerMock alloc]).andReturn(requesterManagerMock);
        OCMStub([requesterManagerMock initWithRequester:[OCMArg any]]).andReturn(requesterManagerMock);
        self->_requesterManagerMock = requesterManagerMock;
    }
}

- (void)mockHttpRequest
{
    if (self->_httpRequestMock == nil) {
        id httpMock = OCMClassMock([FWTHTTPRequester class]);
        OCMStub([httpMock alloc]).andReturn(httpMock);
        OCMStub([httpMock initWithBaseUrl:[OCMArg any] andAuthenticator:[OCMArg any]]).andReturn(httpMock);
    }
}

- (void)setUp {
    [super setUp];
    [self mockRequester];
    [self mockHttpRequest];
}

- (void)tearDown {
    [self->_requesterManagerMock stopMocking];
    self->_requesterManagerMock = nil;
    
    [self->_httpRequestMock stopMocking];
    self->_httpRequestMock = nil;
    
    [super tearDown];
}

- (void)testAssociateUserWithAnonymous {
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    [self registerAnonymousDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding] tokenId:self.deviceTokenId andError:nil onManager:self.manager andRquesterMock:self.requesterManagerMock];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"associate"];
    [self.manager associateDeviceToUser:@"user" completionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqualObjects(self.manager.currentDevice.user, @"user");
}

- (void)testAssociateUserWithPreviousUser {
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    [self registerDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding] tokenId:self.deviceTokenId error:nil andUserAlias:@"user" onManager:self.manager andRquesterMock:self.requesterManagerMock];
    
    XCTAssertEqualObjects(self.manager.currentDevice.user, @"user");
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"associate"];
    [self.manager associateDeviceToUser:@"test" completionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqualObjects(self.manager.currentDevice.user, @"test");
    
}

- (void) testAnonymiseUser {
    [self stubDeviceRegisterResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    [self registerDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding] tokenId:self.deviceTokenId error:nil andUserAlias:@"user" onManager:self.manager andRquesterMock:self.requesterManagerMock];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"associate"];
    [self.manager anonymiseTokenWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertNil(self.manager.currentDevice.user);
}

- (void) testListDevices {
    [self registerAnonymousDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding] tokenId:self.deviceTokenId andError:nil onManager:self.manager andRquesterMock:self.requesterManagerMock];
    [self _stubDeviceList];
    XCTestExpectation *expectation = [self expectationWithDescription:@"associate"];
    [self.manager listDevicesRelatedToUserWithCompletionHandler:^(NSArray<FWTNotifiableDevice *> * _Nullable devices, NSError * _Nullable error) {
        XCTAssertNotNil(devices);
        XCTAssertNil(error);
        XCTAssertEqual(devices.count, 1);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testListDevicesUser {
    [self registerDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding] tokenId:self.deviceTokenId error:nil andUserAlias:@"user" onManager:self.manager andRquesterMock:self.requesterManagerMock];
    [self _stubDeviceList];
    XCTestExpectation *expectation = [self expectationWithDescription:@"associate"];
    [self.manager listDevicesRelatedToUserWithCompletionHandler:^(NSArray<FWTNotifiableDevice *> * _Nullable devices, NSError * _Nullable error) {
        XCTAssertNotNil(devices);
        XCTAssertNil(error);
        XCTAssertEqual(devices.count, 3);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) _stubDeviceList {
    FWTNotifiableDevice *device = [[FWTNotifiableDevice alloc] initWithToken:[NSData data] tokenId:self.deviceTokenId andLocale:[NSLocale currentLocale]];
    NSArray *responseArray = @[device, device, device];
    
    void(^block)(NSInvocation *) = ^(NSInvocation * invocation) {
        FWTDeviceListResponse response;
        [invocation getArgument:&response atIndex:3];
        if (response) {
            response(responseArray, nil);
        }
    };
    
    OCMStub([self.requesterManagerMock listDevicesOfUser:OCMOCK_ANY
                                       completionHandler:OCMOCK_ANY]).andDo(block);
}

@end

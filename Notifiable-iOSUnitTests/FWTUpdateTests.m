//
//  FWTUpdateTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "FWTRequesterManager.h"
#import "FWTHTTPRequester.h"
#import "FWTNotifiableManager.h"
#import "FWTNotifiableDevice.h"
#import <OCMock/OCMock.h>

typedef void(^FWTTestRegisterBlock)(BOOL success, NSError* error);

@interface FWTUpdateTests : FWTTestCase

@property (nonatomic, strong) id requesterManagerMock;
@property (nonatomic, strong) id httpRequestMock;
@property (nonatomic, strong) FWTNotifiableManager *manager;
@property (nonatomic, strong) NSNumber *deviceTokenId;

@end

@implementation FWTUpdateTests

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

- (void) testUpdateDeviceNotRegistered
{
    [[self.requesterManagerMock reject] updateDevice:OCMOCK_ANY withUserAlias:OCMOCK_ANY token:OCMOCK_ANY name:OCMOCK_ANY locale:OCMOCK_ANY deviceInformation:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    XCTAssertThrows([self.manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                                         deviceName:@"name"
                                          userAlias:@"user"
                                           location:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                                  deviceInformation:@{@"test":@YES}
                                  completionHandler:nil]);
    OCMVerifyAll(self.requesterManagerMock);
}

- (void)testUpdateAnonymousDevice
{
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertEqualObjects(self.manager.currentDevice.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertNil(self.manager.currentDevice.user);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    [self.manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                         deviceName:@"name"
                          userAlias:@"user"
                           location:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                  deviceInformation:@{@"test":@YES}
                  completionHandler:^(BOOL success, NSError * _Nullable error) {
                      [expectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(device.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(device.user, @"user");
    XCTAssertEqualObjects(device.name, @"name");
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    XCTAssertEqualObjects(device.information, @{@"test":@YES});
}

- (void)testUpdateDeviceWithUser
{
    [self _registerDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding] andUserAlias:@"original"];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertEqualObjects(self.manager.currentDevice.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(self.manager.currentDevice.user, @"original");
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    [self.manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                         deviceName:@"name"
                          userAlias:@"user"
                           location:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                  deviceInformation:@{@"test":@YES}
                  completionHandler:^(BOOL success, NSError * _Nullable error) {
                      [expectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(device.user, @"user");
    XCTAssertEqualObjects(device.name, @"name");
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    XCTAssertEqualObjects(device.information, @{@"test":@YES});
}

- (void) _registerAnonymousDeviceWithToken:(NSData *)token
{
    __weak typeof(self) weakSelf = self;
    [self _registerDeviceWithBlock:^(FWTTestRegisterBlock registerBlock) {
        [weakSelf.manager registerAnonymousToken:token completionHandler:^(BOOL success, NSError * _Nullable error) {
            registerBlock(success, error);
        }];
    }];
}

- (void) _registerDeviceWithToken:(NSData *)token andUserAlias:(NSString *)userAlias
{
    __weak typeof(self) weakSelf = self;
    [self _registerDeviceWithBlock:^(FWTTestRegisterBlock registerBlock) {
        [weakSelf.manager registerToken:token withUserAlias:userAlias completionHandler:^(BOOL success, NSError * _Nullable error) {
            registerBlock(success, error);
        }];
    }];
}

- (void) _registerDeviceWithBlock:(void(^)(FWTTestRegisterBlock registerBlock))block
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register device"];
    [self mockDeviceRegisterResponse:self.deviceTokenId onMock:self.requesterManagerMock withBlock:^{
        block(^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        });
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end

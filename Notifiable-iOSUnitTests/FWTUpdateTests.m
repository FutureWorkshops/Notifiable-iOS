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

- (void) testUpdateToken
{
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                 completionHandler:^(BOOL success, NSError * _Nullable error) {
                     [expectation fulfill];
                 }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
}

- (void) testUpdateDeviceLocale
{
    id mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([mockLocale autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTAssertEqualObjects(self.manager.currentDevice.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager *manager) {
        [manager updateDeviceLocale:[NSLocale localeWithLocaleIdentifier:@"pt_BR"] completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
    
    expectation = [self expectationWithDescription:@"second"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager *manager) {
        [manager updateDeviceLocale:[NSLocale localeWithLocaleIdentifier:@"en_GB"] completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertNotEqualObjects(device, self.manager.currentDevice);
    XCTAssertEqualObjects(self.manager.currentDevice.locale, [NSLocale localeWithLocaleIdentifier:@"en_GB"]);
    [mockLocale stopMocking];
}

- (void) testUpdateDeviceTokenAndLocale
{
    id mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([mockLocale autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(self.manager.currentDevice.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager *manager) {
        [manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                       andLocation:[NSLocale localeWithLocaleIdentifier:@"pt_BR"]
                 completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(self.manager.currentDevice.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
    [mockLocale stopMocking];
}

- (void) testUpdateDeviceName
{
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertNil(self.manager.currentDevice.name);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceName:@"device" completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.name, @"device");
    
    expectation = [self expectationWithDescription:@"Second update"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceName:@"second" completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertNotEqualObjects(device, self.manager.currentDevice);
    XCTAssertEqualObjects(self.manager.currentDevice.name, @"second");
}

- (void) testUpdateDeviceInformation
{
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertEqual(self.manager.currentDevice.information.count, 0);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Information"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceInformation:@{@"test":@YES} completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.information, @{@"test":@YES});
    
    expectation = [self expectationWithDescription:@"Second Information"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceInformation:@{@"onsite":@YES} completionHandler:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertNotEqualObjects(device.information, self.manager.currentDevice.information);
    XCTAssertEqualObjects(self.manager.currentDevice.information, @{@"onsite":@YES});
}

- (void) testUpdateDeviceTokenNameLocaleAndInformation
{
    id mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([mockLocale autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self _registerAnonymousDeviceWithToken:[@"original" dataUsingEncoding:NSUTF8StringEncoding]];
    FWTNotifiableDevice *device = self.manager.currentDevice;
    XCTAssertEqualObjects(device.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    XCTAssertEqual(device.information.count, 0);
    XCTAssertNil(device.name);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Information"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                        deviceName:@"name" location:[NSLocale localeWithLocaleIdentifier:@"pt_BR"]
                 deviceInformation:@{@"test":@YES}
                 completionHandler:^(BOOL success, NSError * _Nullable error) {
                     [expectation fulfill];
                 }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertNotEqualObjects(device, self.manager.currentDevice);
    
    device = self.manager.currentDevice;
    
    XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
    XCTAssertEqualObjects(device.information, @{@"test":@YES});
    XCTAssertEqualObjects(device.name, @"name");
    
    [mockLocale stopMocking];
}

- (void) _expectUpdateOnManager:(FWTNotifiableManager *)manager withBlock:(void(^)(FWTNotifiableManager* manager))block
{
    id managerMock = OCMPartialMock(manager);
    OCMExpect([managerMock updateDeviceToken:OCMOCK_ANY
                                  deviceName:OCMOCK_ANY
                                   userAlias:OCMOCK_ANY
                                    location:OCMOCK_ANY
                           deviceInformation:OCMOCK_ANY
                           completionHandler:OCMOCK_ANY]).andForwardToRealObject();
    block(manager);
    
    if(managerMock) {
        OCMVerifyAll(managerMock);
    }
    [managerMock stopMocking];
}

- (void) _registerAnonymousDeviceWithToken:(NSData *)token
{
    [self registerAnonymousDeviceWithToken:token
                                   tokenId:self.deviceTokenId
                                  andError:nil
                                 onManager:self.manager
                           andRquesterMock:self.requesterManagerMock];
}

- (void) _registerDeviceWithToken:(NSData *)token andUserAlias:(NSString *)userAlias
{
    [self registerDeviceWithToken:token
                          tokenId:self.deviceTokenId
                            error:nil
                     andUserAlias:userAlias
                        onManager:self.manager
                  andRquesterMock:self.requesterManagerMock];
}

@end

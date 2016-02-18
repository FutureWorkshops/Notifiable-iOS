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
#import "NSLocale+FWTNotifiable.h"
#import <OCMock/OCMock.h>

@interface FWTUpdateTests : FWTTestCase

@property (nonatomic, strong) id requesterManagerMock;
@property (nonatomic, strong) id httpRequestMock;
@property (nonatomic, strong) FWTNotifiableManager *manager;
@property (nonatomic, strong) NSNumber *deviceTokenId;
@property (nonatomic, strong) NSData *tokenData;

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
        [FWTNotifiableManager application:OCMOCK_ANY didRegisterForRemoteNotificationsWithDeviceToken:self.tokenData];
        self->_manager = [[FWTNotifiableManager alloc] initWithURL:OCMOCK_ANY
                                                          accessId:OCMOCK_ANY
                                                         secretKey:OCMOCK_ANY
                                                  didRegisterBlock:nil
                                              andNotificationBlock:nil];
    }
    return self->_manager;
}

- (NSData *)tokenData
{
    if (self->_tokenData == nil) {
        self->_tokenData = [@"original" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self->_tokenData;
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
        OCMStub([httpMock initWithBaseURL:[OCMArg any] andAuthenticator:[OCMArg any]]).andReturn(httpMock);
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
    [self _registerAnonymousDevice];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertEqualObjects(self.manager.currentDevice.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertNil(self.manager.currentDevice.user);
    
    NSNumber *tokenId = self.deviceTokenId;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    [self stubDeviceUpdateResponse:tokenId onMock:self.requesterManagerMock];
    [self.manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                         deviceName:@"name"
                          userAlias:@"user"
                           location:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                  deviceInformation:@{@"test":@YES}
                  completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                      XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
                      XCTAssertEqualObjects(device.tokenId, tokenId);
                      XCTAssertEqualObjects(device.user, @"user");
                      XCTAssertEqualObjects(device.name, @"name");
                      XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
                      XCTAssertEqualObjects(device.information, @{@"test":@YES});
                      [expectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testUpdateDeviceWithUser
{
    [self _registerDeviceWithUserAlias:@"original"];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertEqualObjects(self.manager.currentDevice.tokenId, self.deviceTokenId);
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(self.manager.currentDevice.user, @"original");
    
    NSNumber *tokenId = self.deviceTokenId;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    [self stubDeviceUpdateResponse:tokenId onMock:self.requesterManagerMock];
    [self.manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                         deviceName:@"name"
                          userAlias:@"user"
                           location:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                  deviceInformation:@{@"test":@YES}
                  completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                      XCTAssertEqualObjects(device.tokenId, tokenId);
                      XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
                      XCTAssertEqualObjects(device.user, @"user");
                      XCTAssertEqualObjects(device.name, @"name");
                      XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
                      XCTAssertEqualObjects(device.information, @{@"test":@YES});
                      [expectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUpdateToken
{
    [self _registerAnonymousDevice];
    
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    NSNumber *tokenId = self.deviceTokenId;
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                 completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                     XCTAssertEqualObjects(device.tokenId, tokenId);
                     XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
                     [expectation fulfill];
                 }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUpdateDeviceLocale
{
    id mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([mockLocale fwt_autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self _registerAnonymousDevice];
    
    XCTAssertEqualObjects(self.manager.currentDevice.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager *manager) {
        [manager updateDeviceLocale:[NSLocale localeWithLocaleIdentifier:@"pt_BR"] completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    expectation = [self expectationWithDescription:@"second"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager *manager) {
        [manager updateDeviceLocale:[NSLocale localeWithLocaleIdentifier:@"en_GB"] completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_GB"]);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [mockLocale stopMocking];
}

- (void) testUpdateDeviceTokenAndLocale
{
    id mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([mockLocale fwt_autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self _registerAnonymousDevice];
    
    XCTAssertEqualObjects(self.manager.currentDevice.token, [@"original" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(self.manager.currentDevice.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager *manager) {
        [manager updateDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                       andLocation:[NSLocale localeWithLocaleIdentifier:@"pt_BR"]
                 completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                     XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
                     XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
                     [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [mockLocale stopMocking];
}

- (void) testUpdateDeviceName
{
    [self _registerAnonymousDevice];
    
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertNil(self.manager.currentDevice.name);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceName:@"device" completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            XCTAssertEqualObjects(device.name, @"device");
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    expectation = [self expectationWithDescription:@"Second update"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceName:@"second" completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            XCTAssertEqualObjects(device.name, @"second");
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUpdateDeviceInformation
{
    [self _registerAnonymousDevice];
    XCTAssertNotNil(self.manager.currentDevice);
    XCTAssertEqual(self.manager.currentDevice.information.count, 0);
    
    [self stubDeviceUpdateResponse:self.deviceTokenId onMock:self.requesterManagerMock];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Information"];
    
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceInformation:@{@"test":@YES} completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            XCTAssertEqualObjects(device.information, @{@"test":@YES});
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    expectation = [self expectationWithDescription:@"Second Information"];
    [self _expectUpdateOnManager:self.manager withBlock:^(FWTNotifiableManager* manager){
        [manager updateDeviceInformation:@{@"onsite":@YES} completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            XCTAssertEqualObjects(device.information, @{@"onsite":@YES});
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUpdateDeviceTokenNameLocaleAndInformation
{
    id mockLocale = OCMClassMock([NSLocale class]);
    OCMStub([mockLocale fwt_autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    
    [self _registerAnonymousDevice];
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
                 completionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                     XCTAssertEqualObjects(device.token, [@"test" dataUsingEncoding:NSUTF8StringEncoding]);
                     XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
                     XCTAssertEqualObjects(device.information, @{@"test":@YES});
                     XCTAssertEqualObjects(device.name, @"name");
                     [expectation fulfill];
                 }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
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

- (void) _registerAnonymousDevice
{
    [self registerAnonymousDeviceWithTokenId:self.deviceTokenId
                                    andError:nil
                                   onManager:self.manager
                             andRquesterMock:self.requesterManagerMock];
}

- (void) _registerDeviceWithUserAlias:(NSString *)userAlias
{
    [self registerDeviceWithTokenId:self.deviceTokenId
                              error:nil
                       andUserAlias:userAlias
                          onManager:self.manager
                    andRquesterMock:self.requesterManagerMock];
}

@end

//
//  Notifiable_iOSUnitTests.m
//  Notifiable-iOSUnitTests
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import <OCMock/OCMock.h>
#import "FWTRequesterManager.h"
#import "FWTNotifiableManager.h"
#import "FWTHTTPRequester.h"
#import "FWTNotifiableDevice+Private.h"
#import "NSData+FWTNotifiable.h"

@interface FWTRegisterTests : FWTTestCase

@property (nonatomic, strong) id requesterManagerMock;
@property (nonatomic, strong) id httpRequestMock;

@end

@implementation FWTRegisterTests

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

- (void)testRegisterAnonymousToken {
    
    NSData* token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];
    [FWTNotifiableManager application:OCMOCK_ANY didRegisterForRemoteNotificationsWithDeviceToken:token];
    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithURL:OCMOCK_ANY
                                                                     accessId:OCMOCK_ANY
                                                                    secretKey:OCMOCK_ANY
                                                             didRegisterBlock:nil
                                                         andNotificationBlock:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Device information"];
    NSLocale* locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString *deviceName = @"deviceName";
    
    [self stubDeviceRegisterResponse:@42 andError:nil onMock:self.requesterManagerMock withBlock:^{
        [manager registerAnonymousDeviceWithName:deviceName
                                          locale:locale
                                customProperties:@{@"test":@YES}
                              platformProperties:nil
                            andCompletionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                                
                                XCTAssertNotNil(device);
                              
                                FWTNotifiableDevice *currentDevice = manager.currentDevice;
                                XCTAssertEqualObjects(currentDevice, device);
                                XCTAssertTrue([currentDevice.tokenId integerValue] == 42);
                                XCTAssertTrue([[currentDevice.token fwt_notificationTokenString] isEqualToString:[token fwt_notificationTokenString]]);
                                XCTAssertTrue([currentDevice.name isEqualToString:deviceName]);
                                XCTAssertTrue([currentDevice.locale.localeIdentifier isEqualToString:locale.localeIdentifier]);
                                XCTAssertTrue([currentDevice.customProperties[@"test"] boolValue]);
                                [expectation fulfill];
                            }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRegisterTokenToUser {
    NSData* token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];
    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithURL:OCMOCK_ANY
                                                                     accessId:OCMOCK_ANY
                                                                    secretKey:OCMOCK_ANY
                                                             didRegisterBlock:nil
                                                         andNotificationBlock:nil];
    [FWTNotifiableManager application:OCMOCK_ANY didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register device with user"];
    NSLocale* locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString *userAlias = @"test";
    NSString *deviceName = @"deviceName";
    
    [self stubDeviceRegisterResponse:@42 andError:nil onMock:self.requesterManagerMock withBlock:^{
        [manager registerDeviceWithName:deviceName
                              userAlias:userAlias
                                 locale:locale
                       customProperties:@{@"test": @YES}
                     platformProperties:nil
                   andCompletionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                       FWTNotifiableDevice *currentDevice = manager.currentDevice;
                       XCTAssertEqualObjects(currentDevice, device);
                       XCTAssertTrue([device.tokenId integerValue] == 42);
                       XCTAssertTrue([[device.token fwt_notificationTokenString] isEqualToString:[token fwt_notificationTokenString]]);
                       XCTAssertTrue([device.user isEqualToString:userAlias]);
                       XCTAssertTrue([device.name isEqualToString:deviceName]);
                       XCTAssertTrue([device.locale.localeIdentifier isEqualToString:locale.localeIdentifier]);
                       XCTAssertTrue([device.customProperties[@"test"] boolValue]);
                 
                       [expectation fulfill];
                   }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testFailOnRegisterAnonymousDevice
{
    [FWTNotifiableManager application:OCMOCK_ANY didRegisterForRemoteNotificationsWithDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]];
    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithURL:OCMOCK_ANY
                                                                     accessId:OCMOCK_ANY
                                                                    secretKey:OCMOCK_ANY
                                                             didRegisterBlock:nil
                                                         andNotificationBlock:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fail unregister"];
    [self stubDeviceRegisterResponse:nil andError:[NSError errorWithDomain:@"domain" code:404 userInfo:nil] onMock:self.requesterManagerMock withBlock:^{
        [manager registerAnonymousDeviceWithName:@"name"
                                          locale:[NSLocale localeWithLocaleIdentifier:@"pt_BR"]
                                customProperties:@{@"test":@YES}
                              platformProperties:nil
                            andCompletionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                          
                                XCTAssertNil(device);
                                XCTAssertNotNil(error);
                          
                                [expectation fulfill];
                            }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertNil(manager.currentDevice);
}

- (void) testFailOnRegisterDevice
{
    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithURL:OCMOCK_ANY
                                                                     accessId:OCMOCK_ANY
                                                                    secretKey:OCMOCK_ANY
                                                             didRegisterBlock:nil
                                                         andNotificationBlock:nil];
    [FWTNotifiableManager application:OCMOCK_ANY didRegisterForRemoteNotificationsWithDeviceToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fail unregister"];
    [self stubDeviceRegisterResponse:nil andError:[NSError errorWithDomain:@"domain" code:404 userInfo:nil] onMock:self.requesterManagerMock withBlock:^{
        [manager registerDeviceWithName:@"name"
                              userAlias:@"user"
                                 locale:[NSLocale localeWithLocaleIdentifier:@"pt_BR"]
                       customProperties:@{@"test":@YES}
                     platformProperties:nil
                   andCompletionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
                          XCTAssertNil(device);
                          XCTAssertNotNil(error);
                          [expectation fulfill];
             }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertNil(manager.currentDevice);
}

@end

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

- (void)testRegisterAnonymousToken {
    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithUrl:OCMOCK_ANY
                                                                     accessId:OCMOCK_ANY
                                                                 andSecretKey:OCMOCK_ANY];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([manager registerAnonymousToken:nil completionHandler:nil], @"The register should fail if no token is provided");
#pragma clang diagnostic pop
    
    [self _expectAnonymousRegisterOnManager:manager withBlock:^{
        [manager registerAnonymousToken:OCMOCK_ANY
                      completionHandler:nil];
    }];
    
    [self _expectAnonymousRegisterOnManager:manager withBlock:^{
        [manager registerAnonymousToken:OCMOCK_ANY
                             deviceName:OCMOCK_ANY
                      completionHandler:nil];
    }];
    
    [self _expectAnonymousRegisterOnManager:manager withBlock:^{
        [manager registerAnonymousToken:OCMOCK_ANY
                             withLocale:OCMOCK_ANY
                      completionHandler:nil];
    }];
    
    [self _expectAnonymousRegisterOnManager:manager withBlock:^{
        [manager registerAnonymousToken:OCMOCK_ANY
                             withLocale:OCMOCK_ANY
                      deviceInformation:OCMOCK_ANY
                      completionHandler:nil];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Device information"];
    NSLocale* locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSData* token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *deviceName = @"deviceName";
    
    [self mockDeviceRegisterResponse:@42 onMock:self.requesterManagerMock withBlock:^{
        [manager registerAnonymousToken:token
                             deviceName:deviceName
                             withLocale:locale
                      deviceInformation:@{@"test":@YES}
                      completionHandler:^(BOOL success, NSError * _Nullable error) {
                          
                          XCTAssertTrue(success);
                          
                          FWTNotifiableDevice *currentDevice = manager.currentDevice;
                          XCTAssertTrue([currentDevice.tokenId integerValue] == 42);
                          XCTAssertTrue([[currentDevice.token fwt_notificationTokenString] isEqualToString:[token fwt_notificationTokenString]]);
                          XCTAssertTrue([currentDevice.name isEqualToString:deviceName]);
                          XCTAssertTrue([currentDevice.locale.localeIdentifier isEqualToString:locale.localeIdentifier]);
                          XCTAssertTrue([currentDevice.information[@"test"] boolValue]);
                          [expectation fulfill];
                      }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRegisterTokenToUser {
    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithUrl:OCMOCK_ANY
                                                                     accessId:OCMOCK_ANY
                                                                 andSecretKey:OCMOCK_ANY];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([manager registerToken:OCMOCK_ANY withUserAlias:nil completionHandler:nil], @"The register should fail if no user is provided");
    XCTAssertThrows([manager registerToken:nil withUserAlias:OCMOCK_ANY completionHandler:nil], @"The register should fail if no token is provided");
    XCTAssertThrows([manager registerToken:OCMOCK_ANY withUserAlias:OCMOCK_ANY completionHandler:nil], @"The register should fail if an empty user string is provided");
#pragma clang diagnostic pop
    
    NSString *userAlias = @"test";
    
    [self _expectUserAliasRegisterOnManager:manager withBlock:^{
        [manager registerToken:OCMOCK_ANY
                 withUserAlias:userAlias
             completionHandler:nil];
    }];
    
    [self _expectUserAliasRegisterOnManager:manager withBlock:^{
        [manager registerToken:OCMOCK_ANY
                 withUserAlias:userAlias
                     andLocale:OCMOCK_ANY
             completionHandler:nil];
    }];
    
    [self _expectUserAliasRegisterOnManager:manager withBlock:^{
        [manager registerToken:OCMOCK_ANY
                 withUserAlias:userAlias
                    deviceName:OCMOCK_ANY
             completionHandler:nil];
    }];
    
    [self _expectUserAliasRegisterOnManager:manager withBlock:^{
        [manager registerToken:OCMOCK_ANY
                 withUserAlias:userAlias
                        locale:OCMOCK_ANY
             deviceInformation:OCMOCK_ANY
             completionHandler:nil];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register device with user"];
    NSLocale* locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSData* token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *deviceName = @"deviceName";
    
    [self mockDeviceRegisterResponse:@42 onMock:self.requesterManagerMock withBlock:^{
        [manager registerToken:token
                    deviceName:deviceName
                 withUserAlias:userAlias
                        locale:locale
             deviceInformation:@{@"test":@YES}
             completionHandler:^(BOOL success, NSError * _Nullable error) {
                 XCTAssertTrue(success);
                 
                 FWTNotifiableDevice *device = manager.currentDevice;
                 XCTAssertTrue([device.tokenId integerValue] == 42);
                 XCTAssertTrue([[device.token fwt_notificationTokenString] isEqualToString:[token fwt_notificationTokenString]]);
                 XCTAssertTrue([device.user isEqualToString:userAlias]);
                 XCTAssertTrue([device.name isEqualToString:deviceName]);
                 XCTAssertTrue([device.locale.localeIdentifier isEqualToString:locale.localeIdentifier]);
                 XCTAssertTrue([device.information[@"test"] boolValue]);
                 
                 [expectation fulfill];
             }];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) _expectUserAliasRegisterOnManager:(FWTNotifiableManager *)manager withBlock:(void(^)(void))block
{
    id managerMock = [self _userAliasMockWithManager:manager];
    
    [self _expectRegisterWithBlock:^{
        block();
    }];
    
    if(managerMock) {
        OCMVerifyAll(managerMock);
    }
    [managerMock stopMocking];
}

- (void) _expectAnonymousRegisterOnManager:(FWTNotifiableManager *)manager withBlock:(void(^)(void))block
{
    id managerMock = [self _anonymousMockWithManager:manager];

    [self _expectRegisterWithBlock:^{
        block();
    }];
    
    if(managerMock) {
        OCMVerifyAll(managerMock);
    }
    [managerMock stopMocking];
}

- (id) _userAliasMockWithManager:(FWTNotifiableManager *)manager
{
    if (manager == nil) {
        return nil;
    }
    id managerMock = OCMPartialMock(manager);
    OCMExpect([managerMock registerToken:OCMOCK_ANY deviceName:OCMOCK_ANY withUserAlias:OCMOCK_ANY locale:OCMOCK_ANY deviceInformation:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andForwardToRealObject();
    return managerMock;
}

- (id) _anonymousMockWithManager:(FWTNotifiableManager *)manager
{
    if(manager) {
        return nil;
    }
    id managerMock = OCMPartialMock(manager);
    OCMExpect([managerMock registerAnonymousToken:OCMOCK_ANY deviceName:OCMOCK_ANY withLocale:OCMOCK_ANY deviceInformation:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andForwardToRealObject();
    
    return managerMock;
}

- (void) _expectRegisterWithBlock:(void(^)(void))block
{
    OCMExpect([self.requesterManagerMock registerDeviceWithUserAlias:[OCMArg any] token:[OCMArg any] name:[OCMArg any] locale:[OCMArg any] deviceInformation:[OCMArg any] completionHandler:[OCMArg any]]);
    block();
    OCMVerifyAll(self.requesterManagerMock);
}

@end

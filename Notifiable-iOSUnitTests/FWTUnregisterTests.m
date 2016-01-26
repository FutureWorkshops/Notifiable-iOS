//
//  FWTUnregisterTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 22/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "FWTRequesterManager.h"
#import "FWTNotifiableDevice.h"
#import "FWTHTTPRequester.h"
#import "FWTNotifiableManager.h"
#import <OCMock/OCMock.h>

@interface FWTUnregisterTests : FWTTestCase

@property (nonatomic, strong) id requesterManagerMock;
@property (nonatomic, strong) id httpRequestMock;
@property (nonatomic, strong) FWTNotifiableManager *manager;

@end

@implementation FWTUnregisterTests

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


- (void) testUnregisterWithNoDevice
{
    [[self.requesterManagerMock reject] unregisterTokenId:OCMOCK_ANY
                                                userAlias:OCMOCK_ANY
                                        completionHandler:OCMOCK_ANY];
    XCTAssertNil(self.manager.currentDevice);
    XCTAssertThrows([self.manager unregisterTokenWithCompletionHandler:nil]);
    OCMVerifyAll(self.requesterManagerMock);
}

- (void) testUnregisterDevice
{
    [self registerAnonymousDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                                   tokenId:@42
                                  andError:nil
                                 onManager:self.manager
                           andRquesterMock:self.requesterManagerMock];
    
    XCTAssertNotNil(self.manager.currentDevice);
    
    [self _stubSuccessUnregister];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Unregister"];
    [self.manager unregisterTokenWithCompletionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
        XCTAssertNil(device);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertNil(self.manager.currentDevice);
}

- (void) testErrorOnUnregister
{
    [self registerAnonymousDeviceWithToken:[@"test" dataUsingEncoding:NSUTF8StringEncoding]
                                   tokenId:@42
                                  andError:nil
                                 onManager:self.manager
                           andRquesterMock:self.requesterManagerMock];
    
    XCTAssertNotNil(self.manager.currentDevice);
    
    [self _stubFailUnregister];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Unregister"];
    [self.manager unregisterTokenWithCompletionHandler:^(FWTNotifiableDevice *device, NSError * _Nullable error) {
        XCTAssertNotNil(device);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertNotNil(self.manager.currentDevice);
}

- (void) _stubSuccessUnregister
{
    [self _stubUnregisterWithSuccess:YES andError:nil];
}

- (void) _stubFailUnregister
{
    [self _stubUnregisterWithSuccess:NO andError:[NSError errorWithDomain:@"domain" code:404 userInfo:nil]];
}

- (void) _stubUnregisterWithSuccess:(BOOL)success andError:(NSError *)error;
{
    void (^block)(NSInvocation *) = ^(NSInvocation *invocation) {
        FWTSimpleRequestResponse passedBlock;
        [invocation getArgument:&passedBlock atIndex:4];
        if (passedBlock) {
            passedBlock(success, error);
        }
    };
    OCMStub([self.requesterManagerMock unregisterTokenId:@42
                                               userAlias:OCMOCK_ANY
                                       completionHandler:OCMOCK_ANY]).andDo(block);
}

@end

//
//  FWTHTTPRequesterTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "FWTHTTPSessionManager.h"
#import "FWTNotifiableAuthenticator.h"
#import "FWTHTTPRequester.h"
#import <OCMock/OCMock.h>

extern NSString * const FWTDeviceTokensPath;
extern NSString * const FWTNotificationOpenPath;
extern NSString * const FWTListDevicesPath;

NSString * const FWTTestURL = @"http://localhost:3000";

@interface FWTHTTPRequester (Private)

@property (nonatomic, strong) FWTHTTPSessionManager *httpSessionManager;

@end

@interface FWTHTTPRequesterTests : FWTTestCase

@property (nonatomic, strong) id httpSessionManager;
@property (nonatomic, strong) id authenticator;
@property (nonatomic, strong) FWTHTTPRequester *requester;

@end

@implementation FWTHTTPRequesterTests

- (id)authenticator
{
    if (self->_authenticator == nil) {
        self->_authenticator = OCMClassMock([FWTNotifiableAuthenticator class]);
    }
    return self->_authenticator;
}

- (FWTHTTPRequester *)requester
{
    if (self->_requester == nil) {
        self->_requester = [[FWTHTTPRequester alloc] initWithBaseURL:[NSURL URLWithString:FWTTestURL]
                                                    andAuthenticator:self.authenticator];
        self->_requester.httpSessionManager = self.httpSessionManager;
    }
    return self->_requester;
}

- (id)httpSessionManager
{
    if (self->_httpSessionManager == nil) {
        self->_httpSessionManager = OCMClassMock([FWTHTTPSessionManager class]);
    }
    return self->_httpSessionManager;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [self->_httpSessionManager stopMocking];
    self->_httpSessionManager = nil;
}

- (void)testRequester {
    XCTAssertNotNil([[FWTHTTPRequester alloc] initWithBaseURL:[NSURL URLWithString:FWTTestURL]
                                             andAuthenticator:self.authenticator]);
}

- (void)testRegisterDevice
{
    OCMExpect([self.httpSessionManager POST:FWTDeviceTokensPath
                                 parameters:OCMOCK_ANY
                                    success:OCMOCK_ANY
                                    failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:FWTDeviceTokensPath
                                          httpMethod:@"POST"
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester registerDeviceWithParams:OCMOCK_ANY
                                     success:nil
                                     failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testUpdateDevice
{
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    
    OCMExpect([self.httpSessionManager PATCH:path
                                  parameters:OCMOCK_ANY
                                     success:OCMOCK_ANY
                                     failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          httpMethod:@"PATCH"
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester updateDeviceWithTokenId:@42
                                     params:OCMOCK_ANY
                                    success:nil
                                    failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testUnregisterDevice
{
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    
    OCMExpect([self.httpSessionManager PATCH:path
                                   parameters:OCMOCK_ANY
                                      success:OCMOCK_ANY
                                      failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          httpMethod:@"PATCH"
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester unregisterTokenId:@42
                              success:^(NSDictionary<NSString *, NSObject *>* _Nullable response) {}
                              failure:^(NSInteger responseCode, NSError * error) {}];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testMarkNotification
{
    NSString *notificationId = @"1";
    NSString *path = [NSString stringWithFormat:FWTNotificationOpenPath, notificationId];
    OCMExpect([self.httpSessionManager POST:path
                                 parameters:OCMOCK_ANY
                                    success:OCMOCK_ANY
                                    failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          httpMethod:@"POST"
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester markNotificationAsOpenedWithId:notificationId
                                     deviceTokenId:OCMOCK_ANY
                                           success:^(NSDictionary<NSString *,NSObject *> * _Nullable response) {
                                               
                                           } failure:^(NSInteger responseCode, NSError * _Nonnull error) {
                                               
                                           }];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

@end

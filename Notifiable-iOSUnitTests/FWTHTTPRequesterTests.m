//
//  FWTHTTPRequesterTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "FWTNotifiableAuthenticator.h"
#import "FWTHTTPRequester.h"
#import <OCMock/OCMock.h>

extern NSString * const FWTDeviceTokensPath;
extern NSString * const FWTNotificationOpenPath;
extern NSString * const FWTListDevicesPath;

extern NSString * const FWTUserAliasFormat;

NSString * const FWTTestURL = @"http://localhost:3000";

@interface FWTHTTPRequester (Private)

@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;

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
        self->_httpSessionManager = OCMClassMock([AFHTTPSessionManager class]);
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
                                   progress:OCMOCK_ANY
                                    success:OCMOCK_ANY
                                    failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:FWTDeviceTokensPath
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
    
    OCMExpect([self.httpSessionManager PUT:path
                                parameters:OCMOCK_ANY
                                   success:OCMOCK_ANY
                                   failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester updateDeviceWithTokenId:@42
                                     params:OCMOCK_ANY
                                    success:nil
                                    failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testUnregisterDeviceWithUser
{
    NSString *userAlias = @"userAlias";
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    NSString *userAliasInformation = [NSString stringWithFormat:FWTUserAliasFormat,userAlias];
    path = [path stringByAppendingFormat:@"?%@",[userAliasInformation stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    
    OCMExpect([self.httpSessionManager DELETE:path
                                   parameters:OCMOCK_ANY
                                      success:OCMOCK_ANY
                                      failure:OCMOCK_ANY]);
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester unregisterTokenId:@42
                            userAlias:userAlias
                              success:nil
                              failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testUnregisterDevice
{
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    
    OCMExpect([self.httpSessionManager DELETE:path
                                   parameters:OCMOCK_ANY
                                      success:OCMOCK_ANY
                                      failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester unregisterTokenId:@42
                            userAlias:nil
                              success:nil
                              failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testMarkNotification
{
    OCMExpect([self.httpSessionManager PUT:FWTNotificationOpenPath
                                parameters:OCMOCK_ANY
                                   success:OCMOCK_ANY
                                   failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:FWTNotificationOpenPath
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester markNotificationAsOpenedWithParams:OCMOCK_ANY
                                               success:nil
                                               failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

- (void)testListDevices
{
    NSString *userAliasInformation = [NSString stringWithFormat:FWTUserAliasFormat,@"user"];
    NSString *path = [FWTListDevicesPath stringByAppendingFormat:@"?%@",[userAliasInformation stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    
    OCMExpect([self.httpSessionManager GET:path
                                parameters:OCMOCK_ANY
                                  progress:OCMOCK_ANY
                                   success:OCMOCK_ANY
                                   failure:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester listDevicesOfUser:@"user"
                              success:nil
                              failure:nil];
    
    OCMVerifyAll(self.httpSessionManager);
    OCMVerifyAll(self.authenticator);
}

@end

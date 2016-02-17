//
//  FWTHTTPRequesterTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "AFHTTPClient.h"
#import "FWTNotifiableAuthenticator.h"
#import "FWTHTTPRequester.h"
#import <OCMock/OCMock.h>

NSString * const FWTGETMethod = @"GET";
NSString * const FWTPOSTMethod = @"POST";
NSString * const FWTPUTMethod = @"PUT";
NSString * const FWTDELETEMethod = @"DELETE";

extern NSString * const FWTDeviceTokensPath;
extern NSString * const FWTNotificationOpenPath;
extern NSString * const FWTListDevicesPath;

extern NSString * const FWTUserAliasFormat;

NSString * const FWTTestURL = @"http://localhost:3000";

@interface FWTHTTPRequester (Private)

@property (nonatomic, strong) AFHTTPClient *httpClient;

@end

@interface FWTHTTPRequesterTests : FWTTestCase

@property (nonatomic, strong) AFHTTPClient *httpClient;
@property (nonatomic, strong) id clientMock;
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
        self->_requester.httpClient = self.clientMock;
    }
    return self->_requester;
}

- (AFHTTPClient *)httpClient
{
    if (self->_httpClient == nil) {
        self->_httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:FWTTestURL]];
    }
    return self->_httpClient;
}

- (id)clientMock
{
    if (self->_clientMock == nil) {
        self->_clientMock = OCMPartialMock(self.httpClient);
    }
    return self->_clientMock;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [self->_clientMock stopMocking];
    self->_clientMock = nil;
    self->_httpClient = nil;
}

- (void)testRequester {
    XCTAssertNotNil([[FWTHTTPRequester alloc] initWithBaseURL:[NSURL URLWithString:FWTTestURL]
                                             andAuthenticator:self.authenticator]);
}

- (id) _stubAndCheckRequestPath:(NSString *)path andMethod:(NSString *)method
{
    id requestMock = OCMClassMock([NSMutableURLRequest class]);
    OCMExpect([self.clientMock requestWithMethod:method path:path parameters:OCMOCK_ANY]).andReturn(requestMock);
    return requestMock;
}

- (void)testRegisterDevice
{
    id requestMock = [self _stubAndCheckRequestPath:FWTDeviceTokensPath andMethod:FWTPOSTMethod];
    OCMExpect([self.clientMock enqueueHTTPRequestOperation:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:FWTDeviceTokensPath
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester registerDeviceWithParams:OCMOCK_ANY
                                     success:nil
                                     failure:nil];
    
    OCMVerifyAll(self.clientMock);
    OCMVerifyAll(self.authenticator);
    [requestMock stopMocking];
}

- (void)testUpdateDevice
{
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    id requestMock = [self _stubAndCheckRequestPath:path andMethod:FWTPUTMethod];
    OCMExpect([self.clientMock enqueueHTTPRequestOperation:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester updateDeviceWithTokenId:@42
                                     params:OCMOCK_ANY
                                    success:nil
                                    failure:nil];
    
    OCMVerifyAll(self.clientMock);
    OCMVerifyAll(self.authenticator);
    [requestMock stopMocking];
}

- (void)testUnregisterDeviceWithUser
{
    NSString *userAlias = @"userAlias";
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    NSString *userAliasInformation = [NSString stringWithFormat:FWTUserAliasFormat,userAlias];
    path = [path stringByAppendingFormat:@"?%@",[userAliasInformation stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    id requestMock = [self _stubAndCheckRequestPath:path andMethod:FWTDELETEMethod];
    OCMExpect([self.clientMock enqueueHTTPRequestOperation:OCMOCK_ANY]);
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester unregisterTokenId:@42
                            userAlias:userAlias
                              success:nil
                              failure:nil];
    
    OCMVerifyAll(self.clientMock);
    OCMVerifyAll(self.authenticator);
    [requestMock stopMocking];
}

- (void)testUnregisterDevice
{
    NSString *path = [NSString stringWithFormat:@"%@/42",FWTDeviceTokensPath];
    id requestMock = [self _stubAndCheckRequestPath:path andMethod:FWTDELETEMethod];
    OCMExpect([self.clientMock enqueueHTTPRequestOperation:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester unregisterTokenId:@42
                            userAlias:nil
                              success:nil
                              failure:nil];
    
    OCMVerifyAll(self.clientMock);
    OCMVerifyAll(self.authenticator);
    [requestMock stopMocking];
}

- (void)testMarkNotification
{
    id requestMock = [self _stubAndCheckRequestPath:FWTNotificationOpenPath andMethod:FWTPUTMethod];
    OCMExpect([self.clientMock enqueueHTTPRequestOperation:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:FWTNotificationOpenPath
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester markNotificationAsOpenedWithParams:OCMOCK_ANY
                                               success:nil
                                               failure:nil];
    
    OCMVerifyAll(self.clientMock);
    OCMVerifyAll(self.authenticator);
    [requestMock stopMocking];
}

- (void)testListDevices
{
    NSString *userAliasInformation = [NSString stringWithFormat:FWTUserAliasFormat,@"user"];
    NSString *path = [FWTListDevicesPath stringByAppendingFormat:@"?%@",[userAliasInformation stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    id requestMock = [self _stubAndCheckRequestPath:path andMethod:FWTGETMethod];
    
    OCMExpect([self.clientMock enqueueHTTPRequestOperation:OCMOCK_ANY]);
    
    OCMExpect([self.authenticator authHeadersForPath:path
                                          andHeaders:OCMOCK_ANY]);
    
    [self.requester listDevicesOfUser:@"user"
                              success:nil
                              failure:nil];
    
    OCMVerifyAll(self.clientMock);
    OCMVerifyAll(self.authenticator);
    [requestMock stopMocking];
}

@end

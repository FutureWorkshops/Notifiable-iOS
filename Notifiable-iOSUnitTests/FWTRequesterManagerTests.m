//
//  FWTRequesterManagerTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import <OCMock/OCMock.h>
#import "FWTRequesterManager.h"
#import "FWTHTTPRequester.h"
#import "FWTNotifiableLogger.h"
#import "NSData+FWTNotifiable.h"
#import "NSError+FWTNotifiable.h"

typedef BOOL(^FWTParameterValidationBlock)(NSDictionary *params);

@interface FWTRequesterManager (Private)

- (void)_updateDevice:(NSNumber *)deviceTokenId
        withUserAlias:(NSString *)alias
                token:(NSData *)token
                 name:(NSString *)name
               locale:(NSLocale *)locale
    customProperties:(NSDictionary *)customProperties
             attempts:(NSUInteger)attempts
        previousError:(NSError *)error
    completionHandler:(FWTDeviceTokenIdResponse)handler;

- (void)_registerDeviceWithUserAlias:(NSString *)userAlias
                               token:(NSData *)token
                                name:(NSString *)name
                              locale:(NSLocale *)locale
                   customProperties:(NSDictionary *)customProperties
                            attempts:(NSUInteger)attempts
                       previousError:(NSError *)previousError
                   completionHandler:(FWTDeviceTokenIdResponse)handler;

@end

@interface FWTRequesterManagerTests : FWTTestCase

@property (nonatomic, strong) id httpRequesterMock;
@property (nonatomic, strong) NSData *token;
@property (nonatomic, strong) FWTRequesterManager *manager;

@end

@implementation FWTRequesterManagerTests

- (id)httpRequesterMock
{
    if (self->_httpRequesterMock == nil) {
        self->_httpRequesterMock = OCMClassMock([FWTHTTPRequester class]);
    }
    return self->_httpRequesterMock;
}

- (NSData *)token
{
    if (self->_token == nil) {
        self->_token = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self->_token;
}

- (FWTRequesterManager *)manager
{
    if (self->_manager == nil) {
        self->_manager = [[FWTRequesterManager alloc] initWithRequester:self.httpRequesterMock];
    }
    return self->_manager;
}

- (void)setUp {
    [super setUp];
    [NSUserDefaults resetStandardUserDefaults];
}

- (void)tearDown {
    [super tearDown];
    
    [self->_httpRequesterMock stopMocking];
    self->_httpRequesterMock = nil;
    self->_manager = nil;
}

- (void)testDefaultInit
{
    FWTRequesterManager *manager = [[FWTRequesterManager alloc] initWithRequester:self.httpRequesterMock];
    XCTAssertNotNil(manager);
    XCTAssertEqual(manager.retryAttempts, 3);
    XCTAssertEqual(manager.retryDelay, 60);
    XCTAssertEqual(manager.logger.logLevel, FWTNotifiableLogLevelNone);
}

- (void)testInvalidInit
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([[FWTRequesterManager alloc] initWithRequester:nil]);
#pragma clang diagnostic pop
}

#pragma mark - Register

- (void)testBasicRegister
{
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:nil]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.manager registerDeviceWithUserAlias:OCMOCK_ANY
                                                        token:nil
                                                         name:OCMOCK_ANY
                                                       locale:OCMOCK_ANY
                                             customProperties:OCMOCK_ANY
                                            completionHandler:OCMOCK_ANY]);
#pragma clang diagnostic pop
    
    [self.manager registerDeviceWithUserAlias:nil
                                        token:self.token
                                         name:nil
                                       locale:nil
                            customProperties:nil
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testRegisterWithAlias
{
    NSString *userAlias = @"userAlias";
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateUserAlias:userAlias count:3]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:userAlias
                                        token:self.token
                                         name:nil
                                       locale:nil
                            customProperties:nil
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testRegisterWithName
{
    NSString *deviceName = @"deviceName";
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateDeviceNameWithName:deviceName count:3]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:nil
                                        token:self.token
                                         name:deviceName
                                       locale:nil
                            customProperties:nil
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testRegisterWithLocale
{
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateLocationBlockWithIdentifier:@"en_US" count:3]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:nil
                                        token:self.token
                                         name:nil
                                       locale:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                            customProperties:nil
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testRegisterWithDeviceInformation
{
    NSDictionary *info = @{@"onsite":@YES, @"test":@YES};
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateDeviceInformationBlockWithTarget:@{@"customProperties": info} count:3]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:nil
                                        token:self.token
                                         name:nil
                                       locale:nil
                            customProperties:info
                            completionHandler:nil];
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testCompleteRegister
{
    NSString *userAlias = @"userAlias";
    NSString *tokenInfo = [self.token fwt_notificationTokenString];
    NSString *name = @"name";
    NSString *locale = @"en_US";
    
    NSDictionary *completeParams = @{ @"user": @{@"alias":userAlias},
                                      @"token": tokenInfo,
                                      @"name": name,
                                      @"locale": locale,
                                      @"provider": @"apns",
                                      @"customProperties": @{@"onsite":@YES, @"test":@YES}};
    
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateCompleteInformationWithTarget:completeParams]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:userAlias
                                        token:self.token
                                         name:name
                                       locale:[NSLocale localeWithLocaleIdentifier:locale]
                            customProperties:@{@"onsite":@YES, @"test":@YES}
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testRegisterError404
{
    NSError *error = [NSError errorWithDomain:@"test" code:404 userInfo:nil];
    [self _testRegisterFailureWithError:error
                       andExpectedError:[NSError fwt_invalidOperationErrorWithUnderlyingError:error]];
}

- (void) testRegisterError403
{
    NSError *error = [NSError errorWithDomain:@"test" code:403 userInfo:nil];
    [self _testRegisterFailureWithError:error
                       andExpectedError:[NSError fwt_forbiddenErrorWithUnderlyingError:error]];
}

- (void) testRegisterError401
{
    NSError *error = [NSError errorWithDomain:@"test" code:401 userInfo:nil];
    [self _testRegisterFailureWithError:error
                       andExpectedError:[NSError fwt_userAliasErrorWithUnderlyingError:error]];
}

- (void) testGeneralError
{
    NSError *error = [NSError errorWithDomain:@"test" code:500 userInfo:nil];
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:error.localizedDescription forKey:NSLocalizedDescriptionKey];
    [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    
    [self _testRegisterFailureWithError:error
                       andExpectedError:[NSError fwt_errorWithCode:500 andUserInformation:userInfo]];
}

- (void) _testRegisterFailureWithError:(NSError *)responseError andExpectedError:(NSError *)expectedError
{
    [self _stubRegisterFailureWithError:responseError];
    
    id mock = OCMPartialMock(self.manager);
    OCMExpect([mock _registerDeviceWithUserAlias:OCMOCK_ANY
                                           token:OCMOCK_ANY
                                            name:OCMOCK_ANY
                                          locale:OCMOCK_ANY
                               customProperties:OCMOCK_ANY
                                        attempts:1
                                   previousError:OCMOCK_ANY
                               completionHandler:OCMOCK_ANY]).andForwardToRealObject();
    
    self.manager.retryAttempts = 2;
    self.manager.retryDelay = 0.1;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"failure"];
    [self.manager registerDeviceWithUserAlias:@"user"
                                        token:self.token
                                         name:@"name"
                                       locale:[NSLocale localeWithLocaleIdentifier:@"en"]
                            customProperties:@{@"test":@YES}
                            completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                                XCTAssertNil(deviceTokenId);
                                XCTAssertNotNil(error);
                                XCTAssertEqualObjects(error, expectedError);
                                [expectation fulfill];
                            }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    OCMVerifyAll(mock);
    [mock stopMocking];
}

- (void) _stubRegisterFailureWithError:(NSError *)error
{
    void(^block)(NSInvocation *) = ^(NSInvocation *invocation) {
        FWTRequestManagerFailureBlock failure;
        [invocation getArgument:&failure atIndex:4];
        if (failure) {
            failure(error.code, error);
        }
    };
    OCMStub([self.httpRequesterMock registerDeviceWithParams:OCMOCK_ANY
                                                     success:OCMOCK_ANY
                                                     failure:OCMOCK_ANY]).andDo(block);
}

#pragma mark - Update tests

- (void)testInvalidUpdateAsserts
{
    [[self.httpRequesterMock reject] updateDeviceWithTokenId:OCMOCK_ANY
                                                      params:OCMOCK_ANY
                                                     success:OCMOCK_ANY
                                                     failure:OCMOCK_ANY];
    XCTAssertThrows([self.manager updateDevice:@42
                                 withUserAlias:nil
                                         token:nil
                                          name:nil
                                        locale:nil
                             customProperties:nil
                             completionHandler:nil]);
    OCMVerifyAll(self.httpRequesterMock);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.manager updateDevice:nil
                                 withUserAlias:OCMOCK_ANY
                                         token:OCMOCK_ANY
                                          name:OCMOCK_ANY
                                        locale:OCMOCK_ANY
                             customProperties:OCMOCK_ANY
                             completionHandler:OCMOCK_ANY]);
#pragma clang diagnostic pop
    
}

- (void)testUpdateToken
{
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateToken:self.token count:1]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:nil
                         token:self.token
                          name:nil
                        locale:nil
             customProperties:nil
             completionHandler:nil];
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testUpdateUserAlias
{
    NSString *userAlias = @"userAlias";
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateUserAlias:userAlias count:1]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:userAlias
                         token:nil
                          name:nil
                        locale:nil
             customProperties:nil
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testUpdateName
{
    NSString *name = @"test";
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateDeviceNameWithName:name count:1]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:nil
                         token:nil
                          name:name
                        locale:nil
             customProperties:nil
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testUpdateLocale
{
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateLocationBlockWithIdentifier:@"en_US" count:1]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:nil
                         token:nil
                          name:nil
                        locale:[NSLocale localeWithLocaleIdentifier:@"en_US"]
             customProperties:nil
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testUpdateInformation
{
    NSDictionary *info = @{@"onsite": @YES, @"test": @YES};
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateDeviceInformationBlockWithTarget:@{@"customProperties": info} count:1]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:nil
                         token:nil
                          name:nil
                        locale:nil
             customProperties:info
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testCompleteUpdate
{
    NSString *userAlias = @"userAlias";
    NSString *tokenInfo = [self.token fwt_notificationTokenString];
    NSString *name = @"name";
    NSString *locale = @"en_US";
    
    NSDictionary *completeParams = @{ @"user": @{@"alias":userAlias},
                                      @"token":tokenInfo,
                                      @"name": name,
                                      @"locale":locale,
                                      @"customProperties": @{@"onsite":@YES, @"test":@YES}};
    
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateCompleteInformationWithTarget:completeParams]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:userAlias
                         token:self.token
                          name:name
                        locale:[NSLocale localeWithLocaleIdentifier:locale]
             customProperties:@{@"onsite":@YES, @"test":@YES}
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testUpdateError404
{
    NSError *responseError = [NSError errorWithDomain:@"test" code:404 userInfo:nil];
    [self _testUpdateFailureWithError:responseError
                     andExpectedError:[NSError fwt_invalidOperationErrorWithUnderlyingError:responseError]];
}

- (void)testUpdateError403
{
    NSError *responseError = [NSError errorWithDomain:@"test" code:403 userInfo:nil];
    [self _testUpdateFailureWithError:responseError
                     andExpectedError:[NSError fwt_forbiddenErrorWithUnderlyingError:responseError]];
}

- (void)testUpdateError401
{
    NSError *responseError = [NSError errorWithDomain:@"test"
                                                 code:401
                                             userInfo:nil];
    [self _testUpdateFailureWithError:responseError
                     andExpectedError:[NSError fwt_userAliasErrorWithUnderlyingError:responseError]];
}

- (void)testUpdateGeneralError
{
    NSError *responseError = [NSError errorWithDomain:@"test"
                                                 code:200
                                             userInfo:nil];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:responseError.localizedDescription forKey:NSLocalizedDescriptionKey];
    [userInfo setObject:responseError forKey:NSUnderlyingErrorKey];
    
    [self _testUpdateFailureWithError:responseError
                     andExpectedError:[NSError fwt_errorWithCode:200 andUserInformation:userInfo]];
}

- (void) _testUpdateFailureWithError:(NSError *)responseError andExpectedError:(NSError *)expectedError
{
    [self _stubUpdateFailureWithError:responseError];
    
    id managerMock = OCMPartialMock(self.manager);
    OCMExpect([managerMock _updateDevice:@42
                           withUserAlias:OCMOCK_ANY
                                   token:OCMOCK_ANY
                                    name:OCMOCK_ANY
                                  locale:OCMOCK_ANY
                       customProperties:OCMOCK_ANY
                                attempts:1
                           previousError:OCMOCK_ANY
                       completionHandler:OCMOCK_ANY]).andForwardToRealObject();
    
    self.manager.retryAttempts = 2;
    self.manager.retryDelay = 0.1;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Failure"];
    
    [self.manager updateDevice:@42
                 withUserAlias:@"user"
                         token:self.token
                          name:@"name"
                        locale:[NSLocale localeWithLocaleIdentifier:@"en"]
             customProperties:@{@"onsite":@YES, @"test":@YES}
             completionHandler:^(NSNumber * _Nullable deviceTokenId, NSError * _Nullable error) {
                 XCTAssertEqualObjects(deviceTokenId, @42);
                 XCTAssertNotNil(error);
                 XCTAssertEqualObjects(error, expectedError);
                 [expectation fulfill];
             }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    OCMVerifyAll(managerMock);
    [managerMock stopMocking];
}

- (void) _stubUpdateFailureWithError:(NSError *)error
{
    void(^block)(NSInvocation *) = ^(NSInvocation *invocation) {
        FWTRequestManagerFailureBlock failure;
        [invocation getArgument:&failure atIndex:5];
        if (failure) {
            failure(error.code, error);
        }
    };
    OCMStub([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                     params:OCMOCK_ANY
                                                    success:OCMOCK_ANY
                                                    failure:OCMOCK_ANY]).andDo(block);
}

- (void)testUnregisterDevice
{
    OCMExpect([self.httpRequesterMock unregisterTokenId:@42
                                              userAlias:@"test"
                                                success:OCMOCK_ANY
                                                failure:OCMOCK_ANY]);
    [self.manager unregisterTokenId:@42
                          userAlias:@"test"
                  completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testMarkNotificationOpen
{
    OCMExpect([self.httpRequesterMock markNotificationAsOpenedWithParams:OCMOCK_ANY
                                                                 success:OCMOCK_ANY
                                                                 failure:OCMOCK_ANY]);
    [self.manager markNotificationAsOpened:OCMOCK_ANY
                                   forUser:OCMOCK_ANY
                          andDeviceTokenId:OCMOCK_ANY
                     withCompletionHandler:nil];
    OCMVerifyAll(self.httpRequesterMock);
}

#pragma mark - Private methods

- (id) _registerParamsValidationWithBlock:(FWTParameterValidationBlock)block
{
    __weak typeof(self) weakSelf = self;
    return [OCMArg checkWithBlock:^BOOL(id obj) {
        if (![weakSelf _basicRegisterParamsIsValid:obj]) {
            return NO;
        }
        if (block) {
            return block((NSDictionary *)obj);
        }
        return YES;
    }];
}

- (id) _updateParamsValidationWithBlock:(FWTParameterValidationBlock)block
{
    __weak typeof(self) weakSelf = self;
    return [OCMArg checkWithBlock:^BOOL(id obj) {
        if (![weakSelf _basicUpdateParamsIsValid:obj]) {
            return NO;
        }
        if (block) {
            return block((NSDictionary *)obj);
        }
        return YES;
    }];
}

- (BOOL) _basicUpdateParamsIsValid:(id)obj
{
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSDictionary *params = (NSDictionary *)obj;
    XCTAssertGreaterThan(params.count, 0);
    
    return YES;
}

- (BOOL) _basicRegisterParamsIsValid:(id)obj
{
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSDictionary *params = (NSDictionary *)obj;
    
    FWTParameterValidationBlock tokenValidation = [self _validateToken:self.token count:params.count];
    tokenValidation(params);
    XCTAssertGreaterThanOrEqual(params.count, 2);
    XCTAssertNotNil(params[@"provider"]);
    
    return YES;
}

#pragma mark - Validation Blocks
- (FWTParameterValidationBlock) _validateToken:(NSData *)token count:(NSInteger)count
{
    return ^BOOL(NSDictionary *params) {
        XCTAssertEqual(params.count, count);
        XCTAssertEqualObjects(params[@"token"], [token fwt_notificationTokenString]);
        return YES;
    };
}

- (FWTParameterValidationBlock)_validateUserAlias:(NSString *)alias count:(NSInteger)count
{
    return ^BOOL(NSDictionary *params) {
        
        XCTAssertEqual(params.count, count);
        XCTAssertEqual(params[@"user"][@"alias"], alias);
        
        return YES;
    };
}

- (FWTParameterValidationBlock)_validateDeviceNameWithName:(NSString *)name count:(NSInteger)count
{
    return ^BOOL(NSDictionary *params) {
        
        XCTAssertEqual(params.count, count);
        XCTAssertEqual(params[@"name"], name);
        
        return YES;
    };
}

- (FWTParameterValidationBlock)_validateLocationBlockWithIdentifier:(NSString *)identifier count:(NSInteger)count
{
    return ^BOOL(NSDictionary *params) {
        XCTAssertEqual(params.count, count);
        XCTAssertEqualObjects(params[@"locale"], identifier);
        return YES;
    };
}

- (FWTParameterValidationBlock)_validateDeviceInformationBlockWithTarget:(NSDictionary *)target count:(NSInteger)count
{
    return ^BOOL(NSDictionary *params) {
        XCTAssertEqual(params.count, count);
        for (NSString *key in target.keyEnumerator) {
            XCTAssertEqualObjects(params[key], target[key]);
        }
        return YES;
    };
}

- (FWTParameterValidationBlock)_validateCompleteInformationWithTarget:(NSDictionary *)target
{
    __weak typeof(self) weakSelf = self;
    return ^BOOL(NSDictionary *params) {
        [weakSelf assertDictionary:params withTarget:target];
        return YES;
    };
}

@end

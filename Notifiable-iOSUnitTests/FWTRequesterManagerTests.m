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

typedef BOOL(^FWTParameterValidationBlock)(NSDictionary *params);

@interface FWTRequesterManager (Private)

- (void)_updateDevice:(NSNumber *)deviceTokenId
        withUserAlias:(NSString *)alias
                token:(NSData *)token
                 name:(NSString *)name
               locale:(NSLocale *)locale
    deviceInformation:(NSDictionary *)deviceInformation
             attempts:(NSUInteger)attempts
        previousError:(NSError *)error
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
                                            deviceInformation:OCMOCK_ANY
                                            completionHandler:OCMOCK_ANY]);
#pragma clang diagnostic pop
    
    [self.manager registerDeviceWithUserAlias:nil
                                        token:self.token
                                         name:nil
                                       locale:nil
                            deviceInformation:nil
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
                            deviceInformation:nil
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
                            deviceInformation:nil
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
                            deviceInformation:nil
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testRegisterWithDeviceInformation
{
    NSDictionary *info = @{@"onsite":@YES, @"test":@YES};
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateDeviceInformationBlockWithTarget:info count:4]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:nil
                                        token:self.token
                                         name:nil
                                       locale:nil
                            deviceInformation:info
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
                                      @"token":tokenInfo,
                                      @"name": name,
                                      @"locale":locale,
                                      @"onsite": @YES,
                                      @"provider":@"apns",
                                      @"test": @YES};
    
    OCMExpect([self.httpRequesterMock registerDeviceWithParams:[self _registerParamsValidationWithBlock:[self _validateCompleteInformationWithTarget:completeParams]]
                                                       success:OCMOCK_ANY
                                                       failure:OCMOCK_ANY]);
    
    [self.manager registerDeviceWithUserAlias:userAlias
                                        token:self.token
                                         name:name
                                       locale:[NSLocale localeWithLocaleIdentifier:locale]
                            deviceInformation:@{@"onsite":@YES, @"test":@YES}
                            completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
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
                             deviceInformation:nil
                             completionHandler:nil]);
    OCMVerifyAll(self.httpRequesterMock);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.manager updateDevice:nil
                                 withUserAlias:OCMOCK_ANY
                                         token:OCMOCK_ANY
                                          name:OCMOCK_ANY
                                        locale:OCMOCK_ANY
                             deviceInformation:OCMOCK_ANY
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
             deviceInformation:nil
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
             deviceInformation:nil
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
             deviceInformation:nil
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
             deviceInformation:nil
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
}

- (void)testUpdateInformation
{
    NSDictionary *info = @{@"onsite":@YES, @"test":@YES};
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateDeviceInformationBlockWithTarget:info count:2]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:nil
                         token:nil
                          name:nil
                        locale:nil
             deviceInformation:info
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
                                      @"onsite": @YES,
                                      @"test": @YES};
    
    OCMExpect([self.httpRequesterMock updateDeviceWithTokenId:@42
                                                       params:[self _updateParamsValidationWithBlock:[self _validateCompleteInformationWithTarget:completeParams]]
                                                      success:OCMOCK_ANY
                                                      failure:OCMOCK_ANY]);
    [self.manager updateDevice:@42
                 withUserAlias:userAlias
                         token:self.token
                          name:name
                        locale:[NSLocale localeWithLocaleIdentifier:locale]
             deviceInformation:@{@"onsite":@YES, @"test":@YES}
             completionHandler:nil];
    
    OCMVerifyAll(self.httpRequesterMock);
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

- (void)testListDevices
{
    OCMExpect([self.httpRequesterMock listDevicesOfUser:@"user"
                                                success:OCMOCK_ANY
                                                failure:OCMOCK_ANY]);
    [self.manager listDevicesOfUser:@"user" completionHandler:nil];
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

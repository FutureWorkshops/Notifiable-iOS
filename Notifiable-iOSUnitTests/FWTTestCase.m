//
//  FWTTestCase.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"
#import "FWTRequesterManager.h"
#import "FWTNotifiableManager.h"
#import "FWTNotifiableDevice.h"
#import <OCMock/OCMock.h>

typedef void(^FWTTestRegisterBlock)(FWTNotifiableDevice *device, NSError* error);

@implementation FWTTestCase

- (void)setUp
{
    [super setUp];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWTUserInfoNotifiableCurrentDeviceKey"];
}

- (void)tearDown
{
    [super setUp];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWTUserInfoNotifiableCurrentDeviceKey"];
}

- (void) assertDictionary:(NSDictionary *)origin withTarget:(NSDictionary *)target
{
    XCTAssertEqual(origin.count, target.count);
    XCTAssertTrue([origin isKindOfClass:[NSDictionary class]], @"The origin %@ is not a dictionary", origin);
    XCTAssertTrue([target isKindOfClass:[NSDictionary class]], @"The targer %@ is not a dictionary", target);
    
    for (NSString *key in origin.keyEnumerator) {
        id object = origin[key];
        id targetObject = target[key];
        
        XCTAssertNotNil(targetObject, @"The key %@ doesn't have an object on target.", key);
        if ([object isKindOfClass:[NSDictionary class]]) {
            [self assertDictionary:object withTarget:targetObject];
        } else {
            XCTAssertEqualObjects(object, targetObject, @"The objects for the key %@ are not the same", key);
        }
    }
}

- (void) stubDeviceRegisterResponse:(NSNumber *)deviceTokenId onMock:(id)mock
{
    [self stubDeviceRegisterResponse:deviceTokenId andError:nil onMock:mock withBlock:nil];
}

- (void) stubDeviceRegisterResponse:(NSNumber *)deviceTokenId andError:(NSError *)error onMock:(id)mock withBlock:(void(^)(void))block
{
    void (^postProxyBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
        FWTDeviceTokenIdResponse passedBlock;
        [invocation getArgument:&passedBlock atIndex:7];
        if (passedBlock) {
            passedBlock(deviceTokenId, error);
        }
    };
    OCMStub([mock registerDeviceWithUserAlias:[OCMArg any]
                                        token:[OCMArg any]
                                         name:[OCMArg any]
                                       locale:[OCMArg any]
                             customProperties:[OCMArg any]
                            completionHandler:[OCMArg any]]).andDo(postProxyBlock);
    if (block) {
        block();
    }
}

- (void) stubDeviceUpdateResponse:(NSNumber *)deviceTokenId onMock:(id)mock
{
    void (^postProxyBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
        FWTDeviceTokenIdResponse passedBlock;
        [invocation getArgument:&passedBlock atIndex:8];
        if (passedBlock) {
            passedBlock(deviceTokenId, nil);
        }
    };
    OCMStub([mock updateDevice:OCMOCK_ANY
                 withUserAlias:OCMOCK_ANY
                         token:OCMOCK_ANY
                          name:OCMOCK_ANY
                        locale:OCMOCK_ANY
              customProperties:OCMOCK_ANY
             completionHandler:OCMOCK_ANY]).andDo(postProxyBlock);
}

- (void) registerAnonymousDeviceWithTokenId:(NSNumber *)tokenId andError:(NSError *)error onManager:(FWTNotifiableManager *)manager andRquesterMock:(id)mock
{
    [self _registerDeviceWithTokenId:tokenId andError:error onMock:mock andBlock:^(FWTTestRegisterBlock registerBlock) {
        [manager registerAnonymousDeviceWithName:nil locale:nil customProperties:nil andCompletionHandler:^(FWTNotifiableDevice * _Nullable device, NSError * _Nullable error) {
            registerBlock(device, error);
        }];
    }];
}

- (void) registerDeviceWithTokenId:(NSNumber *)tokenId error:(NSError *)error andUserAlias:(NSString *)userAlias onManager:(FWTNotifiableManager *)manager andRquesterMock:(id)mock
{
    [self _registerDeviceWithTokenId:tokenId andError:error onMock:mock andBlock:^(FWTTestRegisterBlock registerBlock) {
        [manager registerDeviceWithName:nil userAlias:userAlias locale:nil customProperties:nil andCompletionHandler:^(FWTNotifiableDevice * _Nullable device, NSError * _Nullable error) {
            registerBlock(device, error);
        }];
    }];
}

- (void) _registerDeviceWithTokenId:(NSNumber *)tokenId andError:(NSError *)error onMock:(id)requesterManagerMock andBlock:(void(^)(FWTTestRegisterBlock registerBlock))block
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register device"];
    [self stubDeviceRegisterResponse:tokenId andError:error onMock:requesterManagerMock withBlock:^{
        block(^(FWTNotifiableDevice *device, NSError * _Nullable error) {
            [expectation fulfill];
        });
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end

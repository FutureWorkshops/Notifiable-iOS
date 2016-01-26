//
//  FWTDeviceTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//
#import "FWTTestCase.h"
#import "FWTNotifiableDevice+Private.h"
#import "FWTNotifiableDevice+Parser.h"
#import <OCMock/OCMock.h>

@interface FWTDeviceTests : FWTTestCase

@end

@implementation FWTDeviceTests

- (void)testDevice {
    FWTNotifiableDevice *device = [[FWTNotifiableDevice alloc] initWithToken:[NSStringFromClass([self class]) dataUsingEncoding:NSUTF8StringEncoding]
                                                                     tokenId:@42
                                                                   andLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    XCTAssertEqualObjects(device.token, [NSStringFromClass([self class]) dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(device.tokenId, @42);
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    XCTAssertNil(device.user);
    XCTAssertNil(device.name);
    XCTAssertNil(device.information);
    
    device = [[FWTNotifiableDevice alloc] initWithToken:[NSStringFromClass([self class]) dataUsingEncoding:NSUTF8StringEncoding]
                                                tokenId:@42 locale:[NSLocale localeWithLocaleIdentifier:@"en_US"]
                                                   user:@"user"
                                                   name:@"name"
                                            information:@{@"onsite":@YES}];
    XCTAssertEqualObjects(device.token, [NSStringFromClass([self class]) dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(device.tokenId, @42);
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"en_US"]);
    XCTAssertEqualObjects(device.user, @"user");
    XCTAssertEqualObjects(device.name, @"name");
    XCTAssertEqualObjects(device.information, @{@"onsite":@YES});
}

- (void)testParser {
    id mock = OCMClassMock([NSLocale class]);
    OCMStub([mock autoupdatingCurrentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
    
    FWTNotifiableDevice *device = [[FWTNotifiableDevice alloc] initWithUserName:@"user" dictionary:@{@"id":@42,
                                                                                                     @"name":@"name",
                                                                                                     @"onsite":@"onsite"}];
    
    XCTAssertNotNil(device.token);
    XCTAssertEqualObjects(device.tokenId, @42);
    XCTAssertEqualObjects(device.locale, [NSLocale localeWithLocaleIdentifier:@"pt_BR"]);
    XCTAssertEqualObjects(device.name, @"name");
    XCTAssertEqualObjects(device.information, @{@"onsite":@"onsite"});
    
    [mock stopMocking];
}

@end

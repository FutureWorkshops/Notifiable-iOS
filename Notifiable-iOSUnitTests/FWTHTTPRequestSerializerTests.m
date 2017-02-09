//
//  FWTHTTPRequestSerializerTests.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FWTHTTPRequestSerializer.h"

@interface FWTHTTPRequestSerializerTests : XCTestCase

@property (nonatomic, strong) FWTHTTPRequestSerializer *serializer;

@end

@implementation FWTHTTPRequestSerializerTests

- (FWTHTTPRequestSerializer *)serializer
{
    if (self->_serializer == nil) {
        self->_serializer = [[FWTHTTPRequestSerializer alloc] init];
    }
    return self->_serializer;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testPostSerializer {
    NSDictionary *parameters = @{@"string":@"string", @"number":@2};
    NSURLRequest *request = [self.serializer buildRequestWithBaseURL:[NSURL URLWithString:@"http://localhost"]
                                                          parameters:parameters
                                                          andHeaders:@{@"header":@"header"}
                                                           forMethod:FWTHTTPMethodPOST];
    
    XCTAssertEqualObjects(request.URL.absoluteString, @"http://localhost");
    XCTAssertEqual(request.allHTTPHeaderFields.count, 3);
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Content-Type"], @"application/json; charset=utf-8");
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Accept"], @"application/json");
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"header"], @"header");
    XCTAssertEqualObjects(request.HTTPBody, [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil]);
    
}

- (void) testGetSerializer {
    NSURLRequest *request = [self.serializer buildRequestWithBaseURL:[NSURL URLWithString:@"http://localhost"]
                                                          parameters:@{@"parameter1":@"parameter1"}
                                                          andHeaders:@{@"header":@"header"}
                                                           forMethod:FWTHTTPMethodGET];
    
    XCTAssertEqualObjects(request.URL.absoluteString, @"http://localhost?parameter1=parameter1");
    XCTAssertEqual(request.allHTTPHeaderFields.count, 2);
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Accept"], @"application/json");
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"header"], @"header");
    
    request = [self.serializer buildRequestWithBaseURL:[NSURL URLWithString:@"http://localhost?parameter1=parameter1"]
                                            parameters:@{@"parameter2":@"parameter2"}
                                            andHeaders:@{@"header":@"header"}
                                             forMethod:FWTHTTPMethodGET];
    
    XCTAssertEqualObjects(request.URL.absoluteString, @"http://localhost?parameter1=parameter1&parameter2=parameter2");
    XCTAssertEqual(request.allHTTPHeaderFields.count, 2);
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Accept"], @"application/json");
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"header"], @"header");
    
    request = [self.serializer buildRequestWithBaseURL:[NSURL URLWithString:@"http://localhost"]
                                            parameters:@{@"parameter1":@"parameter1", @"parameter2":@"parameter2"}
                                            andHeaders:@{@"header":@"header"}
                                             forMethod:FWTHTTPMethodGET];
    
    XCTAssertEqualObjects(request.URL.absoluteString, @"http://localhost?parameter2=parameter2&parameter1=parameter1");
    XCTAssertEqual(request.allHTTPHeaderFields.count, 2);
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Accept"], @"application/json");
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"header"], @"header");
    
}

@end

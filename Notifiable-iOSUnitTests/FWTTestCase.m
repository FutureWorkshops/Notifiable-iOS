//
//  FWTTestCase.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTTestCase.h"

@implementation FWTTestCase

- (void)setUp
{
    [super setUp];
    [NSUserDefaults resetStandardUserDefaults];
}

- (void)tearDown
{
    [super setUp];
    [NSUserDefaults resetStandardUserDefaults];
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

@end

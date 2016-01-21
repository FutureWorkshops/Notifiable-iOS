//
//  FWTTestCase.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 21/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface FWTTestCase : XCTestCase

- (void) assertDictionary:(NSDictionary *)origin withTarget:(NSDictionary *)target;

@end

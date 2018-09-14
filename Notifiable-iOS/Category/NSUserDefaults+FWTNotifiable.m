//
//  NSUserDefaults+FWTNotifiable.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 14/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import "NSUserDefaults+FWTNotifiable.h"

@implementation NSUserDefaults (FWTNotifiable)

+ (NSUserDefaults *) userDefaultsWithGroupId:(NSString * _Nullable)groupId {
    if (groupId.length > 0) {
        return [[NSUserDefaults alloc] initWithSuiteName:groupId];
    } else {
        return [NSUserDefaults standardUserDefaults];
    }
}

@end

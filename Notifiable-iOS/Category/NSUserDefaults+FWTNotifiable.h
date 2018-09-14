//
//  NSUserDefaults+FWTNotifiable.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 14/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSUserDefaults (FWTNotifiable)

+ (NSUserDefaults *) userDefaultsWithGroupId:(NSString * _Nullable)groupId;

@end

NS_ASSUME_NONNULL_END

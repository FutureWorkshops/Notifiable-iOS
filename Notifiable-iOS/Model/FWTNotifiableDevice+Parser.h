//
//  FWTNotifiableDevice+Parser.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 19/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import "FWTNotifiableDevice+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWTNotifiableDevice (Parser)

- (instancetype)initWithUserName:(NSString *)userName dictionary:(NSDictionary*)dict;

@end

NS_ASSUME_NONNULL_END

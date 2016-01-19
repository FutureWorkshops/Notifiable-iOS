//
//  NSData+FWTNotifiable.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 18/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (FWTNotifiable)

/** Converts the notification token data into a NSString, removing invalid characters */
- (NSString *)fwt_notificationTokenString;

@end

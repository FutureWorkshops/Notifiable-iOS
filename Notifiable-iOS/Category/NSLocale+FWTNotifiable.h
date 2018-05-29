//
//  NSLocale+FWTNotifiable.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLocale (FWTNotifiable)

+ (NSLocale *)fwt_currentLocale;
- (NSString *)fwt_countryCode;
- (nonnull NSString *)fwt_languageCode;

@end

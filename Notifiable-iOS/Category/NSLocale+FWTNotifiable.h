//
//  NSLocale+FWTNotifiable.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLocale (FWTNotifiable)

NS_ASSUME_NONNULL_BEGIN

+ (NSLocale *)fwt_currentLocale;
- (NSString *)fwt_countryCode;
- (NSString *)fwt_languageCode;

NS_ASSUME_NONNULL_END

@end

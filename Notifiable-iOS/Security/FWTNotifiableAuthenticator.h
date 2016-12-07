//
//  FWTNotifiableAuthenticator.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWTNotifiableAuthenticator : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAccessId:(NSString *)accessId
                    andSecretKey:(NSString *)secretKey NS_DESIGNATED_INITIALIZER;

- (NSDictionary *)authHeadersForPath:(NSString *)path
                          andHeaders:(NSDictionary <NSString *, NSString *>*)headers;
@end

NS_ASSUME_NONNULL_END

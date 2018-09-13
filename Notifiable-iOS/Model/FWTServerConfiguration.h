//
//  FWTServerConfiguration.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 12/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWTServerConfiguration : NSObject

@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, strong, readonly) NSString *serverAccessId;
@property (nonatomic, strong, readonly) NSString *serverSecretKey;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype) initWithServerURL:(NSURL *)url
                          accessId:(NSString *)accessId
                      andSecretKey:(NSString *)secretKey NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

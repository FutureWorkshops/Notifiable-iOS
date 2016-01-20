//
//  FWTNotifiableDevice.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 19/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWTNotifiableDevice : NSObject

/** The registered token for this device */
@property (nonatomic, strong, readonly) NSData *token;
/** The id of this device on the server */
@property (nonatomic, strong, readonly) NSNumber *tokenId;
/** The device locale */
@property (nonatomic, strong, readonly) NSLocale *locale;
/** The user associated with this device. If the device is anonymous, the user will be nil */
@property (nonatomic, strong, readonly, nullable) NSString *user;
/** The name of the this device on the server */
@property (nonatomic, strong, readonly, nullable) NSString *name;
/** Other saved informations about the device */
@property (nonatomic, strong, readonly, nullable) NSDictionary *information;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithToken:(NSData *)deviceToken
                      tokenId:(NSNumber *)deviceTokenId
                    andLocale:(NSLocale *)locale;

- (instancetype)initWithToken:(NSData *)deviceToken
                      tokenId:(NSNumber *)deviceTokenId
                       locale:(NSLocale *)locale
                         user:(NSString * _Nullable)user
                         name:(NSString * _Nullable)name
                  information:(NSDictionary * _Nullable)information NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

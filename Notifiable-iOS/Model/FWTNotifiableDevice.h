//
//  FWTNotifiableDevice.h
//  Notifiable-iOS
//  Copyright © 2016 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWTNotifiableDevice : NSObject

/** The registered token for this device */
@property (nonatomic, copy, readonly) NSData *token;
/** The id of this device on the server */
@property (nonatomic, copy, readonly) NSNumber *tokenId;
/** The device locale */
@property (nonatomic, copy, readonly) NSLocale *locale;
/** The user associated with this device. If the device is anonymous, the user will be nil */
@property (nonatomic, copy, readonly, nullable) NSString *user;
/** The name of the this device on the server */
@property (nonatomic, copy, readonly, nullable) NSString *name;
/** Other saved informations about the device */
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id> *customProperties;
/** Other saved platform protperties */
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id> *platformProperties;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithToken:(NSData *)deviceToken
                      tokenId:(NSNumber *)deviceTokenId
                    andLocale:(NSLocale *)locale;

- (instancetype)initWithToken:(NSData *)deviceToken
                      tokenId:(NSNumber *)deviceTokenId
                       locale:(NSLocale *)locale
                         user:(NSString * _Nullable)user
                         name:(NSString * _Nullable)name
             customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
           platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

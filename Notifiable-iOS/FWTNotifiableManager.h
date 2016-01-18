//
//  FWTNotifiableManager.h
//  FWTNotifiable
//
//  Created by Kamil Kocemba on 18/09/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FWTNotifiableLogLevel) {
    FWTNotifiableLogLevelNone,
    FWTNotifiableLogLevelInfo,
    FWTNotifiableLogLevelError
};

extern NSString * const FWTNotifiableDidRegisterWithAPNSNotification;
extern NSString * const FWTNotifiableFailedToRegisterWithAPNSNotification;

typedef void (^FWTNotifiableOperationCompletionHandler)(BOOL success, NSError * _Nullable error);

/**
 The FWTNotifiableManager is the interface between the iOS application and a Notifiable-Rails gem server
 
 @see <a href="https://github.com/FutureWorkshops/notifiable-rails">Notifiable-Rails gem</a>
*/
@interface FWTNotifiableManager : NSObject

@property (nonatomic, readonly) NSURL *baseUrl;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, assign) NSTimeInterval retryDelay;
@property (nonatomic, assign) FWTNotifiableLogLevel debugLevel;
@property (nonatomic, readonly) NSString *deviceToken;

+ (BOOL)userAllowsPushNotificationsForType:(UIUserNotificationType)types;

- (instancetype)init NS_UNAVAILABLE;

/**
 Init a notifiable manager with the configurations of the Notifiable-Rails server
 
 @see <a href="https://github.com/FutureWorkshops/notifiable-rails">Notifiable-Rails gem</a>
 
 @param url         Notifiable-Rails server url
 @param accessId    Access Id of the app
 @param secretKey   Secret key of the app
 
 @return Manager configured to access a specific Notifiable-Rails server
*/
- (instancetype)initWithUrl:(NSString *)url
                   accessId:(NSString *)accessId
               andSecretKey:(NSString *)secretKey;

#pragma mark - Register Anonymous device
- (void)registerAnonymousToken:(NSData *)token
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)hanlder;

- (void)registerAnonymousToken:(NSData *)token
                    withLocale:(NSLocale *)locale
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)hanlder;

#pragma mark - Register device to a specific user
- (void)registerToken:(NSData *)token
        withUserAlias:(NSString *)userAlias
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)hanlder;

- (void)registerToken:(NSData *)token
        withUserAlias:(NSString *)userAlias
            andLocale:(NSLocale *)locale
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)hanlder;

#pragma mark - Update device information
- (void)updateDeviceToken:(NSData *)token;
- (void)updateDeviceLocale:(NSLocale *)locale
         completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;;
- (void)updateDeviceToken:(NSData *)token
              andLocation:(NSLocale *)locale
        completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;;

#pragma mark - Device/user relationship
- (void)associateDeviceToUser:(NSString *)userAlias
            completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;
- (void)anonymiseTokenWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Unregister
- (void)unregisterTokenWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)hanlder;


#pragma mark - Read receipts can be delivered back to server via this method
- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo;

@end

NS_ASSUME_NONNULL_END

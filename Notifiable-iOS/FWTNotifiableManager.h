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

extern NSString * const FWTNotifiableDidRegisterDeviceWithAPNSNotification;
extern NSString * const FWTNotifiableFailedToRegisterDeviceWithAPNSNotification;

extern NSString * const FWTNotifiableApplicationDidRegisterForRemoteNotifications;

extern NSString * const FWTNotifiableNotificationDevice;
extern NSString * const FWTNotifiableNotificationError;

@protocol FWTNotifiableLogger;
@class FWTNotifiableDevice;

typedef void (^FWTNotifiableOperationCompletionHandler)(FWTNotifiableDevice * _Nullable device, NSError * _Nullable error);
typedef void (^FWTNotifiableListOperationCompletionHandler)(NSArray<FWTNotifiableDevice*> * _Nullable devices, NSError * _Nullable error);

/**
 The FWTNotifiableManager is the interface between the iOS application and a Notifiable-Rails gem server
 
 @see <a href="https://github.com/FutureWorkshops/notifiable-rails">Notifiable-Rails gem</a>
*/
@interface FWTNotifiableManager : NSObject

/** Number of times that the manager will try to resend the informations in case of error */
@property (nonatomic, assign) NSInteger retryAttempts;
/** Delay between retries  */
@property (nonatomic, assign) NSTimeInterval retryDelay;
/** Level of the informations that will be logged by the manager */
@property (nonatomic, strong) id<FWTNotifiableLogger> logger;
/** Current device. If the device is not registered, it will be nil. */
@property (nonatomic, copy, readonly, nullable) FWTNotifiableDevice *currentDevice;

/**
 Checks if the user have allowed the application to use push notifications with a specific UIUserNotificationType
 @param types   Notification setting that is expected to be registered
*/
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
               andSecretKey:(NSString *)secretKey NS_DESIGNATED_INITIALIZER;

#pragma mark - Register Anonymous device
/**
 Register a device without a user associated to it. If the token already exists in the server,
 the device configuration in the server will not change, otherwise, a new device will be created.
 
 @warning If the application:didRegisterForRemoteNotificationsWithDeviceToken: wasn't called,
 this operation will not have a token to register.
 
 @param handler Block called once that the operation is finished.
 */
- (void)registerAnonymousDeviceWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device without a user associated to it. If the token already exists in the server,
 the device configuration in the server will not change, otherwise, a new device will be created.
 
 @param token   The device token.
 @param handler Block called once that the operation is finished.
*/
- (void)registerAnonymousToken:(NSData *)token
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device without a user associated to it. If the token already exists in the server,
 the device configuration in the server will not change, otherwise, a new device will be created.
 
 @param token       The device token.
 @param deviceName  A label for the device.
 @param handler     Block called once that the operation is finished.
 */
- (void)registerAnonymousToken:(NSData *)token
                    deviceName:(NSString *)deviceName
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device, without a user associated to it. If the token already exists in the server,
 the device locale will be updated. Otherwise, a new device will be created with the token 
 and locale provided.
 
 @param token   The device token.
 @param locale  The locale of the device.
 @param handler Block called once that the operation is finished.
*/
- (void)registerAnonymousToken:(NSData *)token
                    withLocale:(NSLocale *)locale
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device, without a user associated to it. If the token already exists in the server,
 the device locale will be updated. Otherwise, a new device will be created with the token
 and locale provided.
 
 @param token               The device token.
 @param locale              The locale of the device.
 @param deviceInformation   Aditional information about the device.
 @param handler             Block called once that the operation is finished.
*/
- (void)registerAnonymousToken:(NSData *)token
                    withLocale:(NSLocale *)locale
             deviceInformation:(NSDictionary *)deviceInformation
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device, without a user associated to it, but with a name to represent the device.
 If the token already exists in the server, the device locale will be updated. 
 Otherwise, a new device will be created with the token and locale provided.
 
 @param token               The device token.
 @param deviceName          A label for the device.
 @param locale              The locale of the device.
 @param deviceInformation   Aditional information about the device.
 @param handler             Block called once that the operation is finished.
 */
-(void)registerAnonymousToken:(NSData *)token
                   deviceName:(NSString * _Nullable)deviceName
                   withLocale:(NSLocale *)locale
            deviceInformation:(NSDictionary *)deviceInformation
            completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Register device to a specific user
/**
 Register a device with a user associated to it. If the token already exists in the server,
 the device configuration in the server will not change, otherwise, a new device will be created.
 If the user alias doesn't exist, a new user will be created.
 
 @warning If the application:didRegisterForRemoteNotificationsWithDeviceToken: wasn't called,
 this operation will not have a token to register.
 
 @param userAlias   The alias of the user in the server.
 @param handler     Block called once that the operation is finished.
 */
- (void)registerDeviceWithUserAlias:(NSString *)userAlias
                  completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device with a user associated to it. If the token already exists in the server,
 the device configuration in the server will not change, otherwise, a new device will be created.
 If the user alias doesn't exist, a new user will be created.
 
 @param token       The device token.
 @param userAlias   The alias of the user in the server.
 @param handler     Block called once that the operation is finished.
*/
- (void)registerToken:(NSData *)token
        withUserAlias:(NSString *)userAlias
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device with a user associated to it. If the token already exists in the server,
 the device configuration in the server will not change, otherwise, a new device will be created.
 If the user alias doesn't exist, a new user will be created.
 
 @param token       The device token.
 @param userAlias   The alias of the user in the server.
 @param deviceName  A label for the device.
 @param handler     Block called once that the operation is finished.
 */
- (void)registerToken:(NSData *)token
        withUserAlias:(NSString *)userAlias
           deviceName:(NSString *)deviceName
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device, with a user associated to it. If the token already exists in the server,
 the device locale will be updated. Otherwise, a new device will be created with the token
 and locale provided. If the user alias doesn't exist, a new user will be created.
 
 @param token       The device token.
 @param locale      The locale of the device.
 @param userAlias   The alias of the user in the server.
 @param handler     Block called once that the operation is finished.
*/
- (void)registerToken:(NSData *)token
        withUserAlias:(NSString *)userAlias
            andLocale:(NSLocale *)locale
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device, with a user associated to it. If the token already exists in the server,
 the device locale will be updated. Otherwise, a new device will be created with the token
 and locale provided. If the user alias doesn't exist, a new user will be created.
 
 @param token       The device token.
 @param locale      The locale of the device.
 @param userAlias   The alias of the user in the server.
 @param deviceInformation   Aditional information about the device
 @param handler     Block called once that the operation is finished.
*/
- (void)registerToken:(NSData *)token
        withUserAlias:(NSString *)userAlias
               locale:(NSLocale *)locale
    deviceInformation:(NSDictionary *)deviceInformation
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Register a device, with a user associated to it, but with a name to represent the device. 
 If the token already exists in the server, the device locale will be updated. 
 Otherwise, a new device will be created with the token and locale provided. 
 If the user alias doesn't exist, a new user will be created.
 
 @param token       The device token.
 @param deviceName  A label for the device.
 @param locale      The locale of the device.
 @param userAlias   The alias of the user in the server.
 @param deviceInformation   Aditional information about the device
 @param handler     Block called once that the operation is finished.
 */
- (void)registerToken:(NSData *)token
           deviceName:(NSString * _Nullable)deviceName
        withUserAlias:(NSString *)userAlias
               locale:(NSLocale *)locale
    deviceInformation:(NSDictionary *)deviceInformation
    completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Update device information
/**
 Update the token of the device
 
 @param token   New device token.
 @param handler Block called once that the operation is finished.
*/
- (void)updateDeviceToken:(NSData *)token
        completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;
/**
 Update the device locale.
 
 @param locale  New device locale.
 @param handler Block called once that the operation is finished.
*/
- (void)updateDeviceLocale:(NSLocale *)locale
         completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;
/**
 Update the device token and locale.
 
 @param token   New device token.
 @param locale  New device locale.
 @param handler Block called once that the operation is finished.
*/
- (void)updateDeviceToken:(NSData *)token
              andLocation:(NSLocale *)locale
        completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the device name
 
 @param name    The name of the device in the server (not related to the user).
 @param handler Block called once that the operation is finished.
*/
- (void)updateDeviceName:(NSString *)name
       completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the device aditional informations
 
 @param deviceInformation   Aditional information about the device
 @param handler             Block called once that the operation is finished.
*/
- (void)updateDeviceInformation:(NSDictionary *)deviceInformation
              completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the informations of the device without change the user.
 
 @param token               New device token.
 @param deviceName          The name of the device
 @param locale              New device locale.
 @param deviceInformation   Aditional information about the device
 @param handler             Block called once that the operation is finished.
*/
- (void)updateDeviceToken:(NSData * _Nullable)token
               deviceName:(NSString * _Nullable)deviceName
                 location:(NSLocale * _Nullable)locale
        deviceInformation:(NSDictionary * _Nullable)deviceInformation
        completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the informations of the device and change the user.
 
 @param token               New device token.
 @param deviceName          The name of the device
 @param locale              New device locale.
 @param deviceInformation   Aditional information about the device.
 @param userAlias   The alias of the user in the server.
 @param handler             Block called once that the operation is finished.
 */
- (void)updateDeviceToken:(NSData * _Nullable)token
               deviceName:(NSString * _Nullable)name
                userAlias:(NSString * _Nullable)userAlias
                 location:(NSLocale * _Nullable)locale
        deviceInformation:(NSDictionary * _Nullable)deviceInformation
        completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Device/user relationship
/**
 Associate an anonymous device to a user. If the user alias doesn't exist, 
 a new user will be created.
 
 @warning   The device id will remain the same on the server, but associated with another user.
 
 @param userAlias   The alias of the user in the server.
 @param handler     Block called once that the operation is finished.
*/
- (void)associateDeviceToUser:(NSString *)userAlias
            completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Remove a token from a specific user and anonymise it. 
 It has a similar effect as registering the device as anonymous.
 
 @warning   The device id and configuration will remain the same in the server.
 
 @param handler Block called once that the operation is finished.
*/
- (void)anonymiseTokenWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Unregister
/**
 Delete the device from the server.

 @param handler Block called once that the operation is finished.
*/
- (void)unregisterTokenWithCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Device list
/**
 List the devices related to the current device user.
 
 @warning If the device is not registered, the server will not be called and the list will return empty.
 @warning If the device is anonymous, the server will not be called and only the current device will be included in the list.
 
 @param handler Block called once that the operation is finished.
*/
- (void)listDevicesRelatedToUserWithCompletionHandler:(_Nullable FWTNotifiableListOperationCompletionHandler)handler;

#pragma mark - Read receipts can be delivered back to server via this method
/**
 Notify the server that a notification was read.
 
 @param notificationInfo    The information of the notification given by the system
*/
- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo;

/**
 Inform the Notifiable Manager that the application did register for remote notifications
 
 @param application Application that was registered
 @param deviceToken Device APNS token
*/
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken;

@end

NS_ASSUME_NONNULL_END

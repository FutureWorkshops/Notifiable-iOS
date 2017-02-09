//
//  FWTNotifiableManager.h
//  FWTNotifiable
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const FWTNotifiableNotificationDevice;
extern NSString * const FWTNotifiableNotificationError;
extern NSString * const FWTNotifiableNotificationDeviceToken;

@protocol FWTNotifiableLogger;

@class FWTNotifiableDevice;
@class FWTNotifiableManager;

typedef void (^FWTNotifiableOperationCompletionHandler)(FWTNotifiableDevice * _Nullable device, NSError * _Nullable error);
typedef void (^FWTNotifiableListOperationCompletionHandler)(NSArray<FWTNotifiableDevice*> * _Nullable devices, NSError * _Nullable error);

typedef void (^FWTNotifiableDidRegisterBlock)(FWTNotifiableManager *manager, NSData * token);
typedef void (^FWTNotifiableDidReceiveNotificationBlock)(FWTNotifiableManager *manager, FWTNotifiableDevice * device, NSDictionary *notification);

@protocol FWTNotifiableManagerListener <NSObject>

@optional
- (void)applicationDidRegisterForRemoteNotificationsWithToken:(NSData *)token;
- (void)applicationDidReciveNotification:(NSDictionary *)notification;
- (void)notifiableManager:(FWTNotifiableManager *)manager didRegisterDevice:(FWTNotifiableDevice *)device;
- (void)notifiableManager:(FWTNotifiableManager *)manager didFailToRegisterDeviceWithError:(NSError *)error;

@end

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

#pragma mark - Permission notification
/**
 Inform the Notifiable Manager that the application did register for remote notifications
 
 @param application Application that was registered
 @param deviceToken Device APNS token
 */
+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken;

#pragma mark - Listener operations
/**
 Register an object to be informed when a asynchronous operation related to the managers is performed
 @param listener    Object to listen for the notifications
 */
+ (void)registerManagerListener:(id<FWTNotifiableManagerListener>)listener;

/**
 Unregister an object previously registered as listener
 @param listener    Object previously registered
 */
+ (void)unregisterManagerListener:(id<FWTNotifiableManagerListener>)listener;

#pragma mark - Read receipts can be delivered back to server via this method
/**
 Notify the server that a notification was read.
 
 @param notificationInfo    The information of the notification given by the system
 
 @return A flag to indicate if the notifications is from Notifiable server or not
 */
+ (BOOL)applicationDidReceiveRemoteNotification:(NSDictionary *)notificationInfo;

/**
 Notify the server that a notification was read and listen for the server response
 
 @param notificationInfo    The information of the notification given by the system
 @param handler             Block called once that the operation is finished.
 
 @return A flag to indicate if the notifications is from Notifiable server or not
 */
- (BOOL)markNotificationAsOpened:(NSDictionary *)notificationInfo
           withCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;


- (instancetype)init NS_UNAVAILABLE;

/**
 Init a notifiable manager with the configurations of the Notifiable-Rails server
 
 @see <a href="https://github.com/FutureWorkshops/notifiable-rails">Notifiable-Rails gem</a>
 
 @param url                 Notifiable-Rails server url
 @param accessId            Access Id of the app
 @param secretKey           Secret key of the app
 @param registerBlock       Block that is called once that the device is registered for receiving notifications
 @param notificationBlock   Block that is called once that the device receives a notification;
 
 @return Manager configured to access a specific Notifiable-Rails server
*/
- (instancetype)initWithURL:(NSURL *)url
                   accessId:(NSString *)accessId
                  secretKey:(NSString *)secretKey
           didRegisterBlock:(_Nullable FWTNotifiableDidRegisterBlock)registerBlock
       andNotificationBlock:(_Nullable FWTNotifiableDidReceiveNotificationBlock)notificationBlock  NS_DESIGNATED_INITIALIZER;

#pragma mark - Register Anonymous device

/**
 Register a device, without a user associated to it, but with a name to represent the device.
 If the token already exists in the server, the device locale will be updated. 
 Otherwise, a new device will be created with the token and locale provided.
 
 @param name                A label for the device.
 @param locale              The locale of the device.
 @param customProperties   Aditional information about the device.
 @param handler             Block called once that the operation is finished.
 */
-(void)registerAnonymousDeviceWithName:(NSString * _Nullable)name
                                locale:(NSLocale * _Nullable)locale
                      customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
                    platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
                  andCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

#pragma mark - Register device to a specific user

/**
 Register a device, with a user associated to it, but with a name to represent the device. 
 If the token already exists in the server, the device locale will be updated. 
 Otherwise, a new device will be created with the token and locale provided. 
 If the user alias doesn't exist, a new user will be created.
 
 @param deviceName  A label for the device.
 @param locale      The locale of the device.
 @param userAlias   The alias of the user in the server.
 @param customProperties   Aditional information about the device
 @param handler     Block called once that the operation is finished.
 */
- (void)registerDeviceWithName:(NSString * _Nullable)deviceName
                     userAlias:(NSString *)userAlias
                        locale:(NSLocale * _Nullable)locale
              customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
            platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
          andCompletionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

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
 
 @param customProperties   Aditional information about the device
 @param handler             Block called once that the operation is finished.
 */
- (void)updateCustomProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
             completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the device platform properties
 
 @param platformProperties  Platform properties
 @param handler             Block called once that the operation is finished.
 */
- (void)updatePlatformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
               completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the informations of the device without change the user.
 
 @param token               New device token.
 @param deviceName          The name of the device
 @param locale              New device locale.
 @param customProperties   Aditional information about the device
 @param handler             Block called once that the operation is finished.
*/
- (void)updateDeviceToken:(NSData * _Nullable)token
               deviceName:(NSString * _Nullable)deviceName
                 locale:(NSLocale * _Nullable)locale
         customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
       platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
        completionHandler:(_Nullable FWTNotifiableOperationCompletionHandler)handler;

/**
 Update the informations of the device and change the user.
 
 @param token               New device token.
 @param deviceName          The name of the device
 @param locale              New device locale.
 @param customProperties   Aditional information about the device.
 @param userAlias   The alias of the user in the server.
 @param handler             Block called once that the operation is finished.
 */
- (void)updateDeviceToken:(NSData * _Nullable)token
               deviceName:(NSString * _Nullable)name
                userAlias:(NSString * _Nullable)userAlias
                 locale:(NSLocale * _Nullable)locale
         customProperties:(NSDictionary<NSString *, id> * _Nullable)customProperties
       platformProperties:(NSDictionary<NSString *, id> * _Nullable)platformProperties
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

@end

NS_ASSUME_NONNULL_END

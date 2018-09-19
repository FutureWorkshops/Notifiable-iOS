# Notifiable

**Notifiable** is a set of utility classes to easily integrate with
[Notifiable-Rails](https://github.com/FutureWorkshops/Notifiable-Rails).

It handles device token registration and takes care of retrying failed requests and avoiding duplicate registrations.

Registering existing token for different user will result in token being reassigned.

## Setup

### Project integration

The `Notifiable` for iOS is available on [CocoaPods](http://cocoapods.org/). To install using it, just add the line to your `Podfile`:

```
pod 'Notifiable'
```

If you are not using CocoaPods, you can clone this project and import the files into your own project. This libraries uses [AFNetworking](https://github.com/AFNetworking/AFNetworking) as a dependency and is configured as a [submodule](https://git-scm.com/docs/git-submodule).

You can see an example of the implementation in the [Sample folder](Sample).

#### Configuring the SDK

Before using the `NotifiableManager` instances, and methods, it is necessary to set the server that the SDK will be talking to, and the [group id](https://github.com/FutureWorkshops/Notifiable-iOS#group-id) that will have access to that configuration.

```swift
NotifiableManager.configure(url: <<SERVER_URL>>, accessId: <<USER_API_ACCESS_ID>>, secretKey: <<USER_API_SECRET_KEY>>, groupId: <<GROUP_ID>>)
```

### Group ID

If you have a [notification extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/index.html), you may want to share the Notifiable SDK configuration between your app, and said extension. To do that, the SDK uses the concept of [App Group](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html).

### Use

To use the `NotifiableManager`, create a new object passing your server URL, application access id, application secret key. You can, also, provide blocks that will be used to notify your code when the device is registered for remote notifications and when it receives a new notification.

```swift
self.manager = NotifiableManager(groupId: <<GROUP_ID>>, didRegisterBlock: { [unowned self] (manager, token) -> Void in 
	...
}, andNotificationBlock: { [unowned self] (manager, device, notification) -> Void in
	...
})
```

### Forward application events

Forward device token to `NotifiableManager`:

```swift
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) 
{
	NotifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

Foward new notifications to `NotifiableManager`:

```swift
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    guard NotifiableManager.isValidNotification(userInfo) else {
        completionHandler(.noData)
        return
    }
    
    NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId) { (error) in
        if let _ = error {
            completionHandler(.failed)
        } else {
            completionHandler(.newData)
        }
    }
}
```

### Listen to application events

To be notified when the device is registered for remote notifications or received a remote notification, you can use the blocks in the `NotifiableManager` init or register an object as a `NotifiableManagerListener`

```swift
func viewDidLoad() {
	super.viewDidLoad()
	NotifiableManager.register(listener: self)
}

//MARK: NotifiableManagerListener methods
func applicationDidRegisterForRemoteNotification(token: NSData) {
	...
}

func applicationDidReceive(notification: [NSObject : AnyObject]) {
	...
}

func manager(_ manager: NotifiableManager, didRegisterDevice device: NotifiableDevice) {
	...
}

func manager(_ manager: NotifiableManager, didFailToRegisterDevice error: NSError) {
	...
}
```

## Registering a device

After the `application:didRegisterForRemoteNotificationsWithDeviceToken:` you can use the device token to register this device in the `Notifiable-Rails` server.

You can register an anonymous device:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    //1 - Config manager
    self.manager = NotifiableManager(groupId: <<GROUP_ID>>, didRegisterBlock: { [unowned self] (manager, token) -> Void in
        //3 - Register device
        self.registerDevice(manager, token: token)
    }, andNotificationBlock: nil)

    //2 - Request for permission
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (authorized, error) in
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
    
func registerDevice(manager:NotifiableManager, token:NSData) {
    manager.register(name:"iPhone", locale: NSLocale.autoupdatingCurrentLocale(), properties: ["onsite":true]) { (device, error) -> Void in
    	...
    }
}
```

Or register a device associated to a user:

```swift
func registerDevice(manager:NotifiableManager, token:NSData) {
    manager.register(name:"device", userAlias: "user", locale: NSLocale.autoupdatingCurrentLocale(), properties: ["onsite":true]) { (device, error) -> Void in
    	...       
    }
}
```

The `properties` dictionary holds some extended parameters that represents the meta data about the device, here you could send the current latitude and longitude of the device, for example.

You can access the registered device informations in the `currentDevice` property of the manager:

```swift
let device = self.manager.currentDevice
```

## Updating the device informations

Once that the device is registered, you can update the device informations:

```swift
self.manager.update(token: nil, name: "device", userAlias: "user", location: NSLocale.currentLocale(), properties: ["onsite":true]) { (device, error) -> Void in
	...
}
```

You can, also, associate the device to other user:

```swift
self.manager.associated(to: user, completionHandler: { (device, error) -> Void in
	...
}
```

Or anonymize the token:

```swift
self.manager.anonymise { (device, error) -> Void in
	...
}
```

## Unregister a device

You may wish to unregister a device token (on user logout or in-app opt out perhaps).

```swift
self.manager.unregister { (device, error) -> Void in
	...
}
```

## Notification validation

If you have multiple services/frameworks that can dispatch a notification to your app, you can check if the notification was sent by Notifiable before trying to make requests to the server.

```swift
NotifiableManager.isValidNotification(userInfo)
```

# Update notification state

iOS has some specific rules to call your app when a notification is received, or open. To ensure that the Notifiable server is displaying the correct state for a notification, the app will have to use the SDK to inform the change of such state, since the methods called by the system are beyond the SDK reaches.

## Marking a notification as opened

When the user taps on a notification, after iOS 10, there are two places were the system informs the app that this action was made:

1. By receiving an `UIApplicationLaunchOptionsKey.remoteNotification` on the `launchOptions` of `application(_:didFinishLaunchingWithOptions:)`
2. If the app is on foreground, and you have a configured `UNUserNotificationCenter`, the `userNotificationCenter(_:didReceive:withCompletionHandler:)` is called.

On both cases, you can use the method `markAsOpen(notification:groupId:completion:)` (where the groupId is optional) to inform the server that the user opened a notification.

### Notification validation

If you have multiple services/frameworks that can dispatch a notification to your app, you can check if the notification was sent by Notifiable before trying to make requests to the server.

```swift
NotifiableManager.isValidNotification(userInfo)
```

### Application Did Finish Launching

```swift
if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [NSObject:AnyObject], NotifiableManager.isValidNotification(remoteNotification) {
    NotifiableManager.markAsOpen(notification: remoteNotification, groupId: kAppGroupId, completion: nil)
}
```

### UNUserNotificationCenter

When operating with the `UNUserNotificationCenterDelegate`, it is better to call the `completionHandler` after the `NotifiableManager` finishes its operation. This will ensure that the network request to the Notifiable server will be completed.

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    
    let userInfo = response.notification.request.content.userInfo
    
    guard NotifiableManager.isValidNotification(userInfo) else {
        completionHandler()
        return
    }
    
    NotifiableManager.markAsOpen(notification: userInfo, groupId: kAppGroupId) { (_) in
        completionHandler()
    }
}
```


## Marking a notification as received

The iOS system has many entry points to indicate that a remote notification was received by the device. To be able to have a consistent status of a notification, you need to mark a notification as received as soon as the system makes it possible. This can be done by using the method `NotifiableManager.markAsReceived(notification:, groupId:, completion:)` (where the groupId is optional) to update the notification state in the server.


### Application Did Receive Remote Notification

If your server sends a message with `content-available: 1`, and your app has `Remote notification` enabled in the capabilities, the system may awake your app to notify about the notification that arrived. At this point, you can call the server to update that notification status.

```swift
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    guard NotifiableManager.isValidNotification(userInfo) else {
        completionHandler(.noData)
        return
    }
    
    NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId) { (error) in
        if let _ = error {
            completionHandler(.failed)
        } else {
            completionHandler(.newData)
        }
    }
}
```

As stated on [Apple's documentation](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application):

>If you enabled the remote notifications background mode, the system launches your app (or wakes it from the suspended state) and puts it in the background state when a remote notification arrives. However, the system does not automatically launch your app if the user has force-quit it. In that situation, the user must relaunch your app or restart the device before the system attempts to launch your app automatically again.

### UNUserNotificationCenter

If the app is on foreground, and you have a configured `UNUserNotificationCenter`, the `userNotificationCenter(_:willPresent:withCompletionHandler:)` will be called, and it is the best moment to update the notification state.

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
    let userInfo = notification.request.content.userInfo
    
    guard NotifiableManager.isValidNotification(userInfo) else {
        return
    }
    
    NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId) { (error) in
        completionHandler(.alert)
    }
}
```

### Notification Service Extension

If the server sends a notification with `mutable-content: 1` APNS property, you may implement a [notification service extension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension), and, there, update the status of the notification in the server.

```swift
override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    
    NotifiableManager.markAsReceived(notification: request.content.userInfo, groupId: kAppGroupId) { [weak self] (_) in
        guard let contentHandler = self?.contentHandler, let bestAttempt = self?.bestAttemptContent else { return }
        contentHandler(bestAttempt)
    }
}
```

This extension will be called only when both of the following conditions are met:

* The remote notification is configured to display an alert.
* The remote notification’s aps dictionary includes the mutable-content key with the value set to 1.

## LICENSE

[Apache License Version 2.0](LICENSE)

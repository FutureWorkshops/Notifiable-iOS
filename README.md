# Notifiable-iOS

**Notifiable-iOS** is a set of utility classes to easily integrate with
[Notifiable-Rails](https://github.com/FutureWorkshops/Notifiable-Rails).

It handles device token registration and takes care of retrying failed requests and avoiding duplicate registrations.

Registering existing token for different user will result in token being reassigned.

## Setup

### Project integration

The `Notifiable-iOS` for iOS is avaliable on [CocoaPods](http://cocoapods.org/). To install using it, just add the line to your `Podfile`:

```
pod 'Notifiable-iOS'
```

If you are not using CocoaPods, you can clone this project and import the files into your own project. This libraries uses [AFNetworking](https://github.com/AFNetworking/AFNetworking) as a dependency and is configured as a [submodule](https://git-scm.com/docs/git-submodule).

You can see an example of the implementation in the [Sample folder](Sample).

### Use

To use the `FWTNotifiableManager`, create a new object passing your server URL, application access id, application secret key. You can, also, provide blocks that will be used to notify your code when the device is registered for remote notifications and when it receives a new notification.

```swift
self.manager = FWTNotifiableManager(url: <<SERVER_URL>>, accessId: <<USER_API_ACCESS_ID>>, secretKey: <<USER_API_SECRET_KEY>>, didRegisterBlock: { [unowned self] (manager, token) -> Void in 
	...
}, andNotificationBlock:{ [unowned self] (manager, device, notification) -> Void in
	...
})
```

### Foward application events

Forward device token to `FWTNotifiableManager`:

```swift
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) 
{
	FWTNotifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

Foward new notifications to `FWTNotifiableManager`:

```swift
func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    if (FWTNotifiableManager.applicationDidReceiveRemoteNotification(userInfo)) {
        print("Notifiable server notification")
    }
}
```

### Listen to application events

To be notified when the device is registered for remote notifications or received a remote notification, you can use the blocks in the `FWTNotifiableManager` init or register an object as a `FWTNotifiableManagerListener`

```swift
func viewDidLoad() {
	super.viewDidLoad()
	FWTNotifiableManager.registerManagerListener(self)
}

//MARK: FWTNotifiableManagerListener methods
func applicationDidRegisterForRemoteNotificationsWithToken(token: NSData) {
	...
}

func applicationDidReciveNotification(notification: [NSObject : AnyObject]) {
	...
}

func notifiableManager(manager: FWTNotifiableManager, didRegisterDevice device: FWTNotifiableDevice) {
	...
}

func notifiableManager(manager: FWTNotifiableManager, didFailToRegisterDeviceWithError error: NSError) {
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
    self.manager = FWTNotifiableManager(URL: serverURL, accessId: accessID, secretKey: secretKey(), didRegisterBlock: { [unowned self] (manager, token) -> Void in
        //3 - Register device
        self.registerDevice(manager, token: token)
    }, andNotificationBlock: nil)

    //2 - Request for permission
    let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
}
    
func registerDevice(manager:FWTNotifiableManager, token:NSData) {
    manager. registerAnonymousDeviceWithName("iPhone", locale: NSLocale.autoupdatingCurrentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
    	...
    }
}
```

Or register a device associated to a user:

```swift
func registerDevice(manager:FWTNotifiableManager, token:NSData) {
    manager.registerDeviceWithName("device", userAlias: "user", locale: NSLocale.autoupdatingCurrentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
    	...       
    }
}
```

The `deviceInformation` dictionary holds some extended parameters that represents the metadata about the device, here you could send the current latitude and longitude of the device, for example.

You can access the registered device informations in the `currentDevice` property of the manager:

```swift
let device = self.manager.currentDevice
```

## Updating the device informations

Once that the device is registered, you can update the device informations:

```swift
self.manager.updateDeviceToken(nil, deviceName: "device", userAlias: "user", location: NSLocale.currentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
	...
}
```

You can, also, associate the device to other user:

```swift
self.manager.associateDeviceToUser(user, completionHandler: { (device, error) -> Void in
	...
}
```

Or anonymise the token:

```swift
self.manager.anonymiseTokenWithCompletionHandler { (device, error) -> Void in
	...
}
```

## Unregister a device

You may wish to unregister a device token (on user logout or in-app opt out perhaps).

```swift
self.manager.unregisterTokenWithCompletionHandler { (device, error) -> Void in
	...
}
```

## Marking a notification as opened
When the application is launched or has received a remote notification, you can relay the fact it was opened by the user to <a href="https://github.com/FutureWorkshops/Notifiable-Rails">Notifiable-Rails</a>.

The `userInfo` here should be the payload received from the notification.

```swift
func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {       
	self.manager.applicationDidReceiveRemoteNotification(userInfo);
}
```

## List devices associated to user

Once that the device is registered, you can request a list of devices registered for the user:

```swift
self.manager.listDevicesRelatedToUserWithCompletionHandler { [weak self] (devices, error) -> Void in
	...
}
```

*If the device is registered as anonymous, the list will contain only the current device.*

## LICENSE

[Apache License Version 2.0](LICENSE)

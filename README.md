# Notifiable-iOS

**Notifiable-iOS** is a set of utility classes to easily integrate with
[Notifiable-Rails](https://github.com/FutureWorkshops/Notifiable-Rails).

It handles device token registration and takes care of retrying failed requests and avoiding duplicate registrations.

Registering existing token for different user will result in token being reassigned.

## Setup

### Project integration

The `FWTNotifiable` for iOS is avaliable on [Cocoapods](http://cocoapods.org/). To install using it, just add the line to your `Podfile`:

```
pod 'FWTNotifiable'
```

If you are not using Cocoapods, you can clone this project and import the files into your own project. This libraries uses [AFNetworking](https://github.com/AFNetworking/AFNetworking) as a dependency and is configured as a [submodule](https://git-scm.com/docs/git-submodule).

You can see an example of the implementation in the [Sample folder](Sample).

### Use

You should add the following to your application delegate:

At the earliest opportunity set the base URL of the `FWTNotifiableManager` to your notifiable rails service.

```swift
var notifiableManager:FWTNotifiableManager!
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
{
	notifiableManager = FWTNotifiableManager(url: <<SERVER_URL>>, accessId: <<USER_API_ACCESS_ID>>, andSecretKey: <<USER_API_SECRET_KEY>>)

	return true;
}
```

Forward device token to `FWTNotifiableManager`:

```swift
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) 
{
	notifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

A notification is triggered (`FWTNotifiableApplicationDidRegisterForRemoteNotifications`) upon the `FWTNotifiableManager ` recording the device token registered for remote notifications. You can use this notification to be warned when the device is ready to be registered on the server.

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	NSNotificationCenter.defaultCenter().addObserver(self, selector: "registerForRemoteNotification:", name: FWTNotifiableApplicationDidRegisterForRemoteNotifications, object: nil)
}
 
 func registerForRemoteNotification(notification:NSNotification) {
	notifiableManager.registerAnonymousDeviceWithCompletionHandler { (device, error) in
		...
	}
}
```

The registered device token is passed in the `userInfo` dictionary of the `NSNotification` with the key `FWTNotifiableNotificationDeviceToken `. So, it can be used to perform the calls on the `FWTNotifiableManager ` object.

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	NSNotificationCenter.defaultCenter().addObserver(self, selector: "registerForRemoteNotification:", name: FWTNotifiableApplicationDidRegisterForRemoteNotifications, object: nil)
}
 
 func registerForRemoteNotification(notification:NSNotification) {
	guard let token = notification.userInfo?[FWTNotifiableNotificationDeviceToken] as? NSData else {
		return
	}
	
	notifiableManager.registerAnonymousToken(token) { (device, error) in
        	...
	}
}
```

## Registering a device

After the `application:didRegisterForRemoteNotificationsWithDeviceToken:` you can use the device token to register this device in the `Notifiable-Rails` server.

You can register an anonymous device:

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	NSNotificationCenter.defaultCenter().addObserver(self, selector: "registerForRemoteNotification:", name: FWTNotifiableApplicationDidRegisterForRemoteNotifications, object: nil)
}
 
 func registerForRemoteNotification(notification:NSNotification) {
	guard let token = notification.userInfo?[FWTNotifiableNotificationDeviceToken] as? NSData else {
		return
	}
	
	notifiableManager.registerAnonymousToken(token, deviceName: "iPhone", withLocale: NSLocale.autoupdatingCurrentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
        	...
	}
}
```

Or register a device associated to a user:

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	NSNotificationCenter.defaultCenter().addObserver(self, selector: "registerForRemoteNotification:", name: FWTNotifiableApplicationDidRegisterForRemoteNotifications, object: nil)
}
 
 func registerForRemoteNotification(notification:NSNotification) {
	guard let token = notification.userInfo?[FWTNotifiableNotificationDeviceToken] as? NSData else {
		return
	}
	
	notifiableManager.registerToken(token, deviceName: "device", withUserAlias: "user", locale: NSLocale.autoupdatingCurrentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
        	...
	}
}
```

The `deviceInformation` dictionary would some extended parameters that represents the metadata about the device, here you could send the latitude and longitude of the device, for example.

A notification is triggered (`FWTNotifiableDidRegisterWithAPNSNotification`) upon the `FWTNotifiableManager` registering the device token. And, you can access the registered device informations in the `currentDevice` property of the manager:

```swift
let device = notifiableManager.currentDevice
```

## Updating the device informations

Once that the device is registered, you can update the device informations:

```swift
notifiableManager.updateDeviceToken(nil, deviceName: "device", userAlias: "user", location: NSLocale.currentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
	...
}
```

You can, also, associate the device to other user:

```swift
notifiableManager.associateDeviceToUser(user, completionHandler: { (device, error) -> Void in
	...
}
```

Or anonymise the token:

```swift
notifiableManager.anonymiseTokenWithCompletionHandler { (device, error) -> Void in
	...
}
```

## Unregister a device

You may wish to unregister a device token (on user logout or in-app opt out perhaps).

```swift
notifiableManager.unregisterTokenWithCompletionHandler { (device, error) -> Void in
	...
}
```

## Marking a notification as opened
When the application is launched or has received a remote notification, you can relay the fact it was opened by the user to <a href="https://github.com/FutureWorkshops/Notifiable-Rails">Notifiable-Rails</a>.

The `userInfo` here should be the payload received from the notification.

```swift
func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {       
	notifiableManager.applicationDidReceiveRemoteNotification(userInfo);
}
```

## List devices associated to user

Once that the device is registered, you can request a list of devices registered for the user:

```swift
notifiableManager.listDevicesRelatedToUserWithCompletionHandler { [weak self] (devices, error) -> Void in
	...
}
```

*If the device is registered as anonymous, the list will contain only the current device.*

## LICENSE

[Apache License Version 2.0](LICENSE)
# Notifiable-iOS

<b>Notifiable-iOS</b> is a set of utility classes to easily integrate with
<a href="https://github.com/FutureWorkshops/Notifiable-Rails">Notifiable-Rails</a>.

It handles device token registration and takes care of retrying failed requests and avoiding duplicate registrations.

Registering existing token for different user will result in token being reassigned.

## Setup

You should add the following to your application delegate:

At the earliest opportunity set the base URL of the `FWTNotifiableManager` to your notifiable rails service.

```
var notifiableManager:FWTNotifiableManager!
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
{
	notifiableManager = FWTNotifiableManager(url: <<SERVER_URL>>, accessId: <<USER_API_ACCESS_ID>>, andSecretKey: <<USER_API_SECRET_KEY>>)

	return YES;
}
```

Forward device token to `FWTNotifiableManager`:

```
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) 
{
	notifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

A notification is triggered (`FWTNotifiableApplicationDidRegisterForRemoteNotifications`) upon the `FWTNotifiableManager ` recording the device token registered for remote notifications. You can use this notification to be warned when the device is ready to be registered on the server.

```
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

```
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

## Registering a user

A notification is triggered (`FWTNotifiableDidRegisterWithAPNSNotification`) upon the `FWTNotifiableManager` registering the device token, you should proceed to register your user with your service at this point.

UserInfo would be some data used to identify the user of the device (user ID, nickname etc...), the extended parameters should represent metadata about the device, here you could send a locale for example along with an application identifier for your app.

```
[[FWTNotifiableManager sharedManager] registerTokenWithUserInfo:@{ @"username" : someUsername } 
											 extendedParameters:@{ @"app_id" : @1 }
											  completionHandler:nil];

```

You may wish to unregister a device token (on user logout or in-app opt out perhaps).

```
FWTNotifiableManager *manager = [FWTNotifiableManager sharedManager];
[manager unregisterToken];
```

## Marking a notification as opened
When the application is launched or has received a remote notification, you can relay the fact it was opened by the user to <a href="https://github.com/FutureWorkshops/Notifiable-Rails">Notifiable-Rails</a>.

The `userInfo` here should provide the necessary data to identify your user on the server (usually you would send the same information as was used during registration), the `notificationInfo` is the payload received from the notification.

```       
 [[FWTNotifiableManager sharedManager] applicationDidReceiveRemoteNotification:notificationInfo forUserInfo:userInfo];
 
```


## LICENSE

[Apache License Version 2.0](LICENSE)
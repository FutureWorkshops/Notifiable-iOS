# Notifiable

<b>Notifiable</b> is a set of utility classes to easily integrate with
<a href="https://github.com/FutureWorkshops/Notifiable-Rails">Notifiable-Rails</a>.

It handles device token registration and takes care of retrying failed requests and avoiding duplicate registrations.

Registering existing token for different user will result in token being reassigned.

## USAGE

You should the following to your <i>AppDelegate</i>:

```objectivec
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
	
    NSURL *endpointURL = [NSURL URLWithString: [NSString stringWithFormat:@"http://HOST/device_tokens"]];
    NSString *userId = @"current_user_id";
    
    FWTNotifiableManager *manager = [FWTNotifiableManager sharedManager];
    manager.baseURL = endpointURL;
    
    [manager application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
	[manager registerTokenIfNeededWithParams:@{
        FWTPushNotificationsUserIdKey : userId
    }];

}
```
<b>user_id</b> parameter is used to associate device token with user model in the backend.


## LICENSE

Apache License Version 2.0
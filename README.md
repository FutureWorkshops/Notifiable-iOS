# Notifiable-iOS

<b>Notifiable-iOS</b> is a set of utility classes to easily integrate with
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
    
	[manager registerTokenWithUserInfo:@{
		@"userId" : user_id,
        @"email"  : @"test@email.com"
    }];

}
```
<b>userInfo</b> parameter is used optionally to provide the backend implementation with additional data associated with the token.

You may wish to unregister a device token, such a scenario may be on user logout, this can be done as follows.

```objectivec
    FWTNotifiableManager *manager = [FWTNotifiableManager sharedManager];

	[manager unregisterToken];
```


## LICENSE

Apache License Version 2.0
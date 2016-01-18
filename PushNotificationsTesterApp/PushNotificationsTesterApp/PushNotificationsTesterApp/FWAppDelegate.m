//
//  PRFAppDelegate.m
//  PushNotificationsTesterApp
//
//  Created by Daniel Phillips on 06/02/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWAppDelegate.h"
#import "FWViewController.h"
@import FWTNotifiable;

@implementation FWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge
                                                                                         categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        [self application:application didReceiveRemoteNotification:remoteNotification];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSDictionary *aps = userInfo[@"aps"];
    NSString *customValue = userInfo[@"customValue"] ?: @"<key 'customValue' not found>";

    if (userInfo) {
        
        if (application.applicationState == UIApplicationStateActive){
            
            // Nothing to do if applicationState is Inactive, the iOS already displayed an alert view.
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Push Alert"
                                                                message:aps[@"alert"]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            
            
            [alertView show];
        }
        
        // make label show value
        FWViewController *rootController = [self getMainController];
        
        NSString *message = [NSString stringWithFormat:@"Notification: %@\n\ncustomValue:\n%@", aps[@"alert"], customValue];
        
        rootController.message = message;
        
        rootController.notificationOutputLabel.text = rootController.message;
        
    }
}

- (FWViewController *)getMainController
{
    UINavigationController *controller = (UINavigationController *)self.window.rootViewController;
    FWViewController *rootController = (FWViewController *)[controller.viewControllers firstObject];
    
    return rootController;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *apnsHostURLString = @"http://fw-notifiable-staging.herokuapp.com";
    
    NSString *token = [[deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];

    FWViewController *rootController = [self getMainController];
    rootController.tokenLabel.text = token;
    
    
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:token];
    
    rootController.pasteboardStatusLabel.text = @"Token copied to pasteboard";

    FWTNotifiableManager *manager = [[FWTNotifiableManager alloc] initWithUrl:apnsHostURLString
                                                                     accessId:@"WyvxpyG9yuuj4kiZUsv6"
                                                                 andSecretKey:@"chEAmSqR1f9MumaRsd1oTIsibeJBcmrw213mHULEntK4WsUytgX3gPCmGM+hgUGcyBjikE7m2BQ6B3KqB7DoSg=="];
    [manager registerAnonymousToken:deviceToken completionHandler:nil];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
}



@end

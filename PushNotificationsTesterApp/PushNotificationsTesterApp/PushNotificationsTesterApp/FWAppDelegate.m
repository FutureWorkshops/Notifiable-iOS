//
//  PRFAppDelegate.m
//  PushNotificationsTesterApp
//
//  Created by Daniel Phillips on 06/02/2013.
//  Copyright (c) 2013 Future Workshops. All rights reserved.
//

#import "FWAppDelegate.h"
#import "FWViewController.h"
#import <Notifiable/FWTNotifiableManager.h>

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

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    
    NSString *apnsHostURLString = apnsHostURLString = @"http://fw-notifiable-staging.herokuapp.com";
    
    NSString *token = [[deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];

    FWViewController *rootController = [self getMainController];
    rootController.tokenLabel.text = token;
    
    
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:token];
    
    rootController.pasteboardStatusLabel.text = @"Token copied to pasteboard";

    FWTNotifiableManager *manager = [FWTNotifiableManager sharedManager];
    manager.baseURL = [NSURL URLWithString:apnsHostURLString];
    manager.appId = @"WyvxpyG9yuuj4kiZUsv6";
    manager.secretKey = @"chEAmSqR1f9MumaRsd1oTIsibeJBcmrw213mHULEntK4WsUytgX3gPCmGM+hgUGcyBjikE7m2BQ6B3KqB7DoSg==";
    
    [manager application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    [manager registerTokenWithUserInfo:nil];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
}



@end

//
//  FWViewController.m
//  PushNotificationsTesterApp
//
//  Created by Daniel Phillips on 03/12/2013.
//
//

#import "FWViewController.h"

@interface FWViewController ()

@end

@implementation FWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if(self.message){
        self.notificationOutputLabel.text = self.message;
    }
    
    self.tokenLabel.text = @"Tap Register to see Token";
    self.pasteboardStatusLabel.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)registerForPushNotifications:(id)sender {
    UIApplication *application = [UIApplication sharedApplication];
    UIUserNotificationSettings *currentSettings = application.currentUserNotificationSettings;
    if (currentSettings.types & UIUserNotificationTypeAlert) {
        [application registerForRemoteNotifications];
    } else {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}


@end

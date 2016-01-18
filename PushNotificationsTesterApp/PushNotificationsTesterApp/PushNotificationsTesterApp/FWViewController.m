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
#if TARGET_IPHONE_SIMULATOR
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"You need to run this app on a real device." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertViewStyleDefault handler:nil];
    [alertController addAction:dismissAction];
    [self presentViewController:alertController animated:YES completion:nil];
#else
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

@end

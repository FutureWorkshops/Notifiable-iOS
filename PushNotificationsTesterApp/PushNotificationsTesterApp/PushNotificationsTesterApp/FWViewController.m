//
//  FWViewController.m
//  PushNotificationsTesterApp
//
//  Created by Daniel Phillips on 03/12/2013.
//
//

#import "FWViewController.h"
@import SVProgressHUD;

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

- (IBAction)unregister:(id)sender {
    if (self.notifiableManager.currentDevice) {
        [self.notifiableManager unregisterTokenWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error on unregister: %@", error);
            } else {
                NSLog(@"Success");
            }
        }];
    }
}

- (IBAction)changeUser:(id)sender {

    UIAlertController *alertController;
    
    if (self.notifiableManager.currentDevice == nil) {
        alertController = [self _invalidDeviceStateAlert];
    } else {
        alertController = [self _changeUserAlert];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (UIAlertController *) _invalidDeviceStateAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                             message:@"Please, register the device first"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:dismissAction];
    return alertController;
}

- (UIAlertController *) _changeUserAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"User"
                                                          message:@"Please, insert the user name"
                                                   preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = weakSelf.notifiableManager.currentDevice.user;
        textField.placeholder = @"User alias";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *anonymousUser = [UIAlertAction actionWithTitle:@"Anonymous" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) sself = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showWithStatus:@"Register as anonymous device"];
        });
        [sself.notifiableManager anonymiseTokenWithCompletionHandler:[sself _defaultCompletionHandler]];
    }];
    UIAlertAction *specificUser = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = [alertController.textFields firstObject];
        NSString *userAlias = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        __strong typeof(weakSelf) sself = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Register as %@", userAlias]];
        });
        [sself.notifiableManager associateDeviceToUser:userAlias completionHandler:[sself _defaultCompletionHandler]];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:anonymousUser];
    [alertController addAction:specificUser];
    
    return alertController;
}

- (void(^)(BOOL success, NSError * _Nullable error)) _defaultCompletionHandler
{
    return ^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [SVProgressHUD showSuccessWithStatus:@""];
            } else {
                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            }
        });
    };
}

- (IBAction)toggleOnSite:(id)sender {
}

@end

//
//  FWViewController.m
//  PushNotificationsTesterApp
//
//  Created by Daniel Phillips on 03/12/2013.
//
//

#import "FWViewController.h"
@import SVProgressHUD;

NSString * const FWOnSiteKey = @"onsite";

@interface FWViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *onSiteSwitch;

@end

@implementation FWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (self.notifiableManager.currentDevice) {
        self.message = [self.notifiableManager.currentDevice.token fwt_notificationTokenString];
        NSNumber *onSite = self.notifiableManager.currentDevice.information[FWOnSiteKey];
        self.onSiteSwitch.on = [onSite boolValue];
    }
    
    if(self.message){
        self.notificationOutputLabel.text = self.message;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_registerNewDeviceResponseNotification:)
                                                 name:FWTNotifiableDidRegisterDeviceWithAPNSNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_registerNewDeviceResponseNotification:)
                                                 name:FWTNotifiableFailedToRegisterDeviceWithAPNSNotification
                                               object:nil];
    
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
    [SVProgressHUD showWithStatus:@"Registering new device"];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

- (IBAction)unregister:(id)sender {
    if (self.notifiableManager.currentDevice) {
        [SVProgressHUD showWithStatus:@"Unregister device"];
        [self.notifiableManager unregisterTokenWithCompletionHandler:[self _defaultCompletionHandler]];
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
        [sself.notifiableManager anonymiseTokenWithCompletionHandler:nil];
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

- (void) _registerNewDeviceResponseNotification:(NSNotification *)notification
{
    if ([notification.name isEqualToString:FWTNotifiableDidRegisterDeviceWithAPNSNotification]) {
        FWTNotifiableDevice *device = (FWTNotifiableDevice *)notification.userInfo[FWTNotifiableNotificationDevice];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Device ID: %@", device.tokenId]];
    } else {
        NSError *error = (NSError *)notification.userInfo[FWTNotifiableNotificationError];
        [SVProgressHUD showErrorWithStatus:[error fwt_debugMessage]];
    }
}

- (void(^)(BOOL success, NSError * _Nullable error)) _defaultCompletionHandler
{
    return ^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [SVProgressHUD showSuccessWithStatus:@""];
            } else {
                [SVProgressHUD showErrorWithStatus:[error fwt_debugMessage]];
            }
        });
    };
}

- (IBAction)toggleOnSite:(UISwitch *)sender {
    
    if (self.notifiableManager == nil) {
        UIAlertController *alertController = [self _invalidDeviceStateAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    if (self.notifiableManager.currentDevice) {
        NSNumber *onSite = self.notifiableManager.currentDevice.information[FWOnSiteKey];
        if(sender.on == [onSite boolValue]) return;
    }
    
    NSDictionary *userInfo = @{FWOnSiteKey:[NSNumber numberWithBool:sender.on]};
    [SVProgressHUD showWithStatus:@"Change on site"];
    [self.notifiableManager updateDeviceInformation:userInfo completionHandler:[self _defaultCompletionHandler]];
}

@end

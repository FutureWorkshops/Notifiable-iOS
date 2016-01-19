//
//  FWViewController.h
//  PushNotificationsTesterApp
//
//  Created by Daniel Phillips on 03/12/2013.
//
//

#import <UIKit/UIKit.h>
@import FWTNotifiable;

@interface FWViewController : UIViewController

@property (weak, nonatomic) FWTNotifiableManager *notifiableManager;

@property (weak, nonatomic) IBOutlet UILabel *notificationOutputLabel;
@property (weak, nonatomic) IBOutlet UILabel *tokenLabel;
@property (weak, nonatomic) IBOutlet UILabel *pasteboardStatusLabel;

@property (nonatomic, copy) NSString *message;

@end

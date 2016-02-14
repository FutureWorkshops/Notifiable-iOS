//
//  ViewController.swift
//  Sample
//
//  Created by Igor Fereira on 25/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

import UIKit
import FWTNotifiable
import SVProgressHUD

class ViewController: UIViewController {
    
    let FWTDeviceListSegue = "FWTDeviceListSegue"
    var manager:FWTNotifiableManager!
    var token:NSData?
    
    typealias FWTRegisterCompleted = (token:NSData!)->Void;
    var registerCompleted:FWTRegisterCompleted?
    
    @IBOutlet weak var onSiteSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "registerDeviceSuccess:", name: FWTNotifiableDidRegisterDeviceWithAPNSNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "failedToRegisterDevice:", name: FWTNotifiableFailedToRegisterDeviceWithAPNSNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "registerForRemoteNotification:", name: FWTNotifiableApplicationDidRegisterForRemoteNotifications, object: nil)
        self.updateScreen()
    }
    
    func updateScreen() {
        guard let information = self.manager.currentDevice?.information?["onsite"] as? NSNumber else {
            onSiteSwitch.on = false
            return
        }
        
        onSiteSwitch.on = information.boolValue
    }
    
    func registerDeviceSuccess(notification:NSNotification) {
        print("Device registered")
    }
    
    func failedToRegisterDevice(notification:NSNotification) {
        print("Device failed to register")
    }

    func registerForRemoteNotification(notification:NSNotification) {
        let token = notification.userInfo?[FWTNotifiableNotificationDeviceToken] as? NSData
        self.registerCompleted?(token: token)
    }
}

//MARK - Register

extension ViewController {
    
    func registeredForNotificationsWithToken(token:NSData) {
        self.token = token
        self.registerCompleted?(token: token)
        self.manager.updateDeviceToken(token, deviceName: "device", userAlias: "user", location: NSLocale.fwt_autoupdatingCurrentLocale(), deviceInformation: ["onsite":true]) { (device, error) -> Void in
            
        }
    }
    
    @IBAction func registerAnonymous(sender: AnyObject) {
        self._registerForNotifications { [weak self] (token) in
            self?._registerAnonymousToken(token)
        }
    }
    
    @IBAction func registerToUser(sender: AnyObject) {
        let alertController = UIAlertController(title: "User", message: "Please, insert the user name", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler {
            $0.placeholder = "User Name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { [weak self] (alertAction) -> Void in
            guard let userName = alertController.textFields?.first?.text else {
                return
            }
            self?._registerWithUser(userName)
        })
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func _registerWithUser(user:String) {
        self._registerForNotifications { [weak self] (token) -> Void in
            self?._registerToken(token, user: user)
        }
    }
    
    private func _registerAnonymousToken(token:NSData) {
        let deviceName = UIDevice.currentDevice().name
        self.manager.registerAnonymousToken(token, deviceName: deviceName) { (device, error) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("Anonymous device registered")
            }
        }
    }
    
    private func _registerToken(token:NSData, user:String) {
        let deviceName = UIDevice.currentDevice().name
        self.manager.registerToken(token, withUserAlias: user, deviceName: deviceName) { (device, error) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("Device registered to user \(user)")
            }
        }
    }
    
    private func _registerForNotifications(completion:FWTRegisterCompleted) {
        self.registerCompleted = completion
        SVProgressHUD.show()
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }
}

//MARK - User

extension ViewController {
    @IBAction func associateToUser(sender: AnyObject) {
        let alertController = UIAlertController(title: "User", message: "Please, insert the user name", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler {
            $0.placeholder = "User Name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { [weak self] (alertAction) -> Void in
            guard let userName = alertController.textFields?.first?.text else {
                return
            }
            self?._associateToUser(userName)
        })
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func _associateToUser(user:String) {
        SVProgressHUD.showWithStatus(nil)
        self.manager.associateDeviceToUser(user, completionHandler: { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("Device associated with the user \(user)")
            }
        })
    }
    
    @IBAction func anonymiseDevice(sender: AnyObject) {
        SVProgressHUD.showWithStatus(nil)
        self.manager.anonymiseTokenWithCompletionHandler { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("Device is now anonymous")
            }
        }
    }
}

//MARK - Update

extension ViewController {
    @IBAction func updateDeviceName(sender: AnyObject) {
        let alertController = UIAlertController(title: "Device Name", message: "Please, insert the device name", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler {
            $0.placeholder = "Device Name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { [weak self] (alertAction) -> Void in
            guard let deviceName = alertController.textFields?.first?.text else {
                return
            }
            self?._updateDeviceName(deviceName)
        })
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func updateOnSite(sender: UISwitch) {
        let onSite = sender.on
        let deviceInformation = ["onsite":NSNumber(bool: onSite)]
        SVProgressHUD.showWithStatus(nil)
        self.manager.updateDeviceInformation(deviceInformation) { [weak self] (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("On site updated")
            }
            self?.updateScreen()
        }
    }
    
    private func _updateDeviceName(name:String) {
        SVProgressHUD.showWithStatus(nil)
        self.manager.updateDeviceName(name) { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("Device name updated to \(name)")
            }
        }
    }
}

//MARK - Unregister
extension ViewController {
    @IBAction func unregisterDevice(sender: AnyObject) {
        SVProgressHUD.showWithStatus(nil)
        self.manager.unregisterTokenWithCompletionHandler { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.fwt_localizedMessage())
            } else {
                SVProgressHUD.showSuccessWithStatus("Device unregistered")
            }
        }
    }
}

//MARK - List
extension ViewController {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? DeviceListTableViewController where segue.identifier == FWTDeviceListSegue {
            destination.manager = self.manager
        }
    }
}


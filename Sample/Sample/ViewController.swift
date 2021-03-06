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
import UserNotifications

class ViewController: UIViewController {
    
    let FWTDeviceListSegue = "FWTDeviceListSegue"
    lazy var manager:NotifiableManager! = {
        let manager = NotifiableManager(groupId: kAppGroupId, session: URLSession.shared, didRegister: { [weak self] (_, token) in
            self?.registerCompleted?(token as NSData)
        }, didRecieve: nil)
        manager.logger = kLogger
        manager.retryAttempts = 0
        return manager
    }()
    
    typealias FWTRegisterCompleted = (NSData)->Void;
    var registerCompleted:FWTRegisterCompleted?
    
    @IBOutlet weak var onSiteSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateScreen()
    }
    
    func updateScreen() {
        guard let information = self.manager?.currentDevice?.properties?["onsite"] as? NSNumber else {
            onSiteSwitch.isOn = false
            return
        }
        
        onSiteSwitch.isOn = information.boolValue
    }
}

//MARK - Register

extension ViewController {
    
    @IBAction func registerAnonymous(sender: AnyObject) {
        self._registerForNotifications { [weak self] (token) in
            self?._registerAnonymousToken(token: token)
        }
    }
    
    @IBAction func registerToUser(sender: AnyObject) {
        let alertController = UIAlertController(title: "User", message: "Please, insert the user name", preferredStyle: .alert)
        alertController.addTextField {
            $0.placeholder = "User Name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] (alertAction) -> Void in
            guard let userName = alertController.textFields?.first?.text else {
                return
            }
            self?._registerWithUser(user: userName)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func _registerWithUser(user:String) {
        self._registerForNotifications { [weak self] (token) -> Void in
            self?._registerToken(token: token, user: user)
        }
    }
    
    private func _registerAnonymousToken(token:NSData) {
        let deviceName = UIDevice.current.name
        self.manager.register(name: deviceName, locale: nil, properties: nil) { (device, error) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "Anonymous device registered")
            }
        }
    }
    
    private func _registerToken(token:NSData, user:String) {
        let deviceName = UIDevice.current.name
        self.manager.register(name: deviceName, userAlias: user, locale: nil, properties: nil) { (device, error) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "Device registered to user \(user)")
            }
        }
    }
    
    private func _registerForNotifications(completion:@escaping FWTRegisterCompleted) {
        self.registerCompleted = completion
        SVProgressHUD.show()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (authorized, error) in
            guard authorized else {
                SVProgressHUD.showError(withStatus: error?.localizedDescription ?? "Permission not granted")
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

extension ViewController {
    @IBAction func associateToUser(sender: AnyObject) {
        let alertController = UIAlertController(title: "User", message: "Please, insert the user name", preferredStyle: .alert)
        alertController.addTextField {
            $0.placeholder = "User Name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] (alertAction) -> Void in
            guard let userName = alertController.textFields?.first?.text else {
                return
            }
            self?._associateToUser(user: userName)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func _associateToUser(user:String) {
        SVProgressHUD.show(withStatus: nil)
        self.manager.associated(to: user, completion: { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "Device associated with the user \(user)")
            }
        })
    }
    
    @IBAction func anonymiseDevice(sender: AnyObject) {
        SVProgressHUD.show(withStatus: nil)
        self.manager.anonymise { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "Device is now anonymous")
            }
        }
    }
}

//MARK - Update

extension ViewController {
    @IBAction func updateDeviceName(sender: AnyObject) {
        let alertController = UIAlertController(title: "Device Name", message: "Please, insert the device name", preferredStyle: .alert)
        alertController.addTextField {
            $0.placeholder = "Device Name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] (alertAction) -> Void in
            guard let deviceName = alertController.textFields?.first?.text else {
                return
            }
            self?._updateDeviceName(name: deviceName)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func updateOnSite(sender: UISwitch) {
        let onSite = sender.isOn
        let deviceInformation = ["onsite":NSNumber(value: onSite)]
        SVProgressHUD.show(withStatus: nil)
        self.manager.update(properties: deviceInformation) { [weak self] (device, error) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "On site updated")
            }
            self?.updateScreen()
        }
    }
    
    private func _updateDeviceName(name:String) {
        SVProgressHUD.show(withStatus: nil)
        self.manager.update(name: name) { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "Device name updated to \(name)")
            }
        }
    }
}

//MARK - Unregister
extension ViewController {
    @IBAction func unregisterDevice(sender: AnyObject) {
        SVProgressHUD.show(withStatus: nil)
        self.manager.unregister { (device, error) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showSuccess(withStatus: "Device unregistered")
            }
        }
    }
}


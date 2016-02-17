//
//  AppDelegate.swift
//  Sample
//
//  Created by Igor Fereira on 25/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

import UIKit
import Keys
import FWTNotifiable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let keys = SampleKeys()
        
        self.getMainViewController()?.manager = FWTNotifiableManager(url: "http://fw-notifiable-staging2.herokuapp.com/", accessId: keys.fWTAccessID(), andSecretKey: keys.fWTSecretKey())
        
        if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject:AnyObject] {
            self.application(application, didReceiveRemoteNotification: remoteNotification)
        }
        
        return true
    }

    func getMainViewController() -> ViewController?
    {
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            return nil
        }
        
        if let mainViewController = navigationController.topViewController as? ViewController {
            return mainViewController
        } else {
            return nil
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if (FWTNotifiableManager.applicationDidReceiveRemoteNotification(userInfo)) {
            print("Notifiable server notification")
        }
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        FWTNotifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}
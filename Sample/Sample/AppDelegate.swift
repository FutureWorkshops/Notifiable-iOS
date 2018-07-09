//
//  AppDelegate.swift
//  Sample
//
//  Created by Igor Fereira on 25/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

import UIKit
import FWTNotifiable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [String: AnyObject]?) -> Bool {
        if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification.rawValue] as? [NSObject:AnyObject] {
            self.application(application: application, didReceiveRemoteNotification: remoteNotification)
        }
        
        return true
    }
    
    private func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if (NotifiableManager.applicationDidReceiveRemoteNotification(userInfo)) {
            print("Notifiable server notification")
        }
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        dump(error)
    }
}

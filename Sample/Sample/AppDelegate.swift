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
import UserNotifications

let kAppGroupId = "group.com.futureworkshops.notifiable.Sample"
let kLogger = SampleLogger(level: .information, groupId: kAppGroupId)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        NotifiableManager.syncronizeData(withGroupId: kAppGroupId)
        
        if let serverURL = URL(string: "https://notifiable.futureworkshops.com/") {
            let keys = SampleKeys()
            NotifiableManager.configure(url: serverURL, accessId: keys.fWTAccessID, secretKey: keys.fWTSecretKey, groupId: kAppGroupId)
        }
        
        if let remoteNotification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [NSObject:AnyObject], NotifiableManager.isValidNotification(remoteNotification) {
            kLogger.log(message: "Opened the message on app: \(remoteNotification)")
            NotifiableManager.markAsOpen(notification: remoteNotification, groupId: kAppGroupId, logger: kLogger, completion: nil)
        }
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard NotifiableManager.isValidNotification(userInfo) else {
            completionHandler(.noData)
            return
        }
        
        kLogger.log(message: "Received notification on app: \(userInfo)")
        
        NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId, logger: kLogger) { (error) in
            if let _ = error {
                completionHandler(.failed)
            } else {
                completionHandler(.newData)
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotifiableManager.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        dump(error)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotifiableManager.didBecomeActive(application: application, groupId: kAppGroupId)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        NotifiableManager.didEnterBackground(application: application, groupId: kAppGroupId)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        guard NotifiableManager.isValidNotification(userInfo) else {
            completionHandler()
            return
        }
        
        kLogger.log(message: "Opened the message on app: \(userInfo)")
        
        NotifiableManager.markAsOpen(notification: userInfo, groupId: kAppGroupId, logger: kLogger) { (_) in
            completionHandler()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        guard NotifiableManager.isValidNotification(userInfo) else {
            return
        }
        
        kLogger.log(message: "Received notification on app: \(userInfo)")
        
        NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId, logger: kLogger) { (error) in
            completionHandler(.alert)
        }
    }
}

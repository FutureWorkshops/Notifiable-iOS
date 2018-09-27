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
            NotifiableManager.markAsOpen(notification: remoteNotification, groupId: kAppGroupId, completion: nil)
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
        
        NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId) { (error) in
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
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        guard NotifiableManager.isValidNotification(userInfo) else {
            completionHandler()
            return
        }
        
        NotifiableManager.markAsOpen(notification: userInfo, groupId: kAppGroupId) { (_) in
            completionHandler()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        guard NotifiableManager.isValidNotification(userInfo) else {
            return
        }
        
        NotifiableManager.markAsReceived(notification: userInfo, groupId: kAppGroupId) { (error) in
            completionHandler(.alert)
        }
    }
}

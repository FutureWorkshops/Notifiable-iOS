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
    var notifiableManager:FWTNotifiableManager!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let keys = SampleKeys()
        self.notifiableManager = FWTNotifiableManager(url: "http://fw-notifiable-staging2.herokuapp.com/", accessId: keys.fWTAccessID(), andSecretKey: keys.fWTSecretKey())
        
        self.getMainViewController()?.manager = self.notifiableManager
        
        return true
    }

    func getMainViewController() -> ViewController?
    {
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            return nil
        }
        
        if let mainViewController = navigationController.viewControllers[0] as? ViewController {
            return mainViewController
        } else {
            return nil
        }
    }
}
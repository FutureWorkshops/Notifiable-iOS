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
        notifiableManager = FWTNotifiableManager(url: "http://fw-notifiable-staging2.herokuapp.com/", accessId: keys.fWTAccessID(), andSecretKey: keys.fWTSecretKey())
        return true
    }


}


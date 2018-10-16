//
//  ServerConfigurationViewController.swift
//  Sample
//
//  Created by Igor Fereira on 16/10/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

import UIKit
import FWTNotifiable

class ServerConfigurationViewController: UIViewController {

    @IBOutlet weak var serverURL: UITextField!
    @IBOutlet weak var accessKey: UITextField!
    @IBOutlet weak var secretKey: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = Configuration.defaultInstance(groupId: kAppGroupId)
        self.serverURL?.text = configuration.serverURL.absoluteString
        self.accessKey?.text = configuration.accessKey as String
        self.secretKey?.text = configuration.secretKey as String
    }
    

    @IBAction func applyChanges(_ sender: Any) {
        guard let serverURLString = self.serverURL?.text,
            let serverURL = URL(string: serverURLString),
            let accessKey = self.accessKey?.text,
            let secretKey = self.secretKey?.text else {
            return
        }
        
        let configuration = Configuration(serverURL: serverURL, accessKey: accessKey, secretKey: secretKey, groupId: kAppGroupId)
        configuration.store()
        NotifiableManager.configure(url: serverURL, accessId: accessKey, secretKey: secretKey)
        self.navigationController?.popViewController(animated: true)
    }

}

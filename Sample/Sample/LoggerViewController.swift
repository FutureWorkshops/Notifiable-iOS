//
//  LoggerViewController.swift
//  Sample
//
//  Created by Igor Fereira on 27/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

import UIKit

class LoggerViewController: UIViewController {

    @IBOutlet weak var textArea: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear(_:)))
        self.textArea?.text = kLogger.logData
    }
    
    @objc func clear(_ sender: Any) {
        kLogger.clear()
        self.textArea?.text = kLogger.logData
    }

}

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
        self.textArea?.text = kLogger.logData
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

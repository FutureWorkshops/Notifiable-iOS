//
//  DeviceListTableViewController.swift
//  Sample
//
//  Created by Igor Fereira on 25/01/2016.
//  Copyright © 2016 Future Workshops. All rights reserved.
//

import UIKit
import FWTNotifiable
import SVProgressHUD

class DeviceListTableViewController: UITableViewController {

    let cellIdentifier = "FWTDeviceListCell"
    var devices = [FWTNotifiableDevice]()
    var manager:FWTNotifiableManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDevices()
    }

    func loadDevices() {
        SVProgressHUD.showWithStatus(nil)
        self.manager.listDevicesRelatedToUserWithCompletionHandler { [weak self] (devices, error) -> Void in
            guard let devices = devices where error == nil else {
                SVProgressHUD.showErrorWithStatus(error?.fwt_debugMessage())
                return
            }
            SVProgressHUD.showSuccessWithStatus(nil)
            self?.devices = devices
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        let device = self.devices[indexPath.row]
        
        cell.textLabel?.text = device.name ?? "<No name>"
        cell.detailTextLabel?.text = "User: \(device.user ?? "Anonymous")"
        
        return cell
    }

}

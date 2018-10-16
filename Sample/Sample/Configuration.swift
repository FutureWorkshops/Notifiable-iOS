//
//  Configuration.swift
//  Sample
//
//  Created by Igor Fereira on 16/10/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

import Foundation
import Keys

private extension UserDefaults {
    var configuration: Configuration? {
        get {
            guard let data = self.data(forKey: Configuration.StorageKeys.configuration.rawValue) else {
                return nil
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? Configuration
        }
        set {
            let data: Data?
            if let configuration = newValue {
                data = NSKeyedArchiver.archivedData(withRootObject: configuration)
            } else {
                data = nil
            }
            self.set(data, forKey: Configuration.StorageKeys.configuration.rawValue)
        }
    }
}

class Configuration: NSObject, NSSecureCoding {
    
    fileprivate enum StorageKeys: String {
        case serverURL
        case accessKey
        case secretKey
        case groupId
        case configuration
    }
    
    let serverURL: URL
    let accessKey: String
    let secretKey: String
    let groupId: String
    
    static var supportsSecureCoding: Bool {
        return true
    }

    static public func defaultInstance(groupId: String) -> Configuration {
        let userDefaults = UserDefaults(groupId: groupId as String)
        
        if let configuration = userDefaults.configuration {
            return configuration
        }
        
        let serverURL = URL(string: "https://notifiable.futureworkshops.com/")!
        let keys = SampleKeys()
        let configuration = Configuration(serverURL: serverURL, accessKey: keys.fWTAccessID, secretKey: keys.fWTSecretKey, groupId: groupId)
        
        userDefaults.configuration = configuration
        userDefaults.synchronize()
        
        return configuration
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.serverURL as NSURL, forKey: StorageKeys.serverURL.rawValue)
        aCoder.encode(self.secretKey as NSString, forKey: StorageKeys.secretKey.rawValue)
        aCoder.encode(self.accessKey as NSString, forKey: StorageKeys.accessKey.rawValue)
        aCoder.encode(self.groupId as NSString, forKey: StorageKeys.groupId.rawValue)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        guard let server = aDecoder.decodeObject(of: [NSURL.self], forKey: StorageKeys.serverURL.rawValue) as? URL,
            let access = aDecoder.decodeObject(of: [NSString.self], forKey: StorageKeys.accessKey.rawValue) as? String,
            let secret = aDecoder.decodeObject(of: [NSString.self], forKey: StorageKeys.secretKey.rawValue) as? String,
            let group = aDecoder.decodeObject(of: [NSString.self], forKey: StorageKeys.groupId.rawValue) as? String else {
            return nil
        }
        self.serverURL = server
        self.accessKey = access
        self.secretKey = secret
        self.groupId = group
    }
    
    public init(serverURL: URL, accessKey: String, secretKey: String, groupId: String) {
        self.serverURL = serverURL
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.groupId = groupId
    }
    
    public func store() {
        let userDefaults = UserDefaults(groupId: self.groupId)
        userDefaults.configuration = self
        userDefaults.synchronize()
    }
}

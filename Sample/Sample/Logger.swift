//
//  Logger.swift
//  Sample
//
//  Created by Igor Fereira on 27/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

import Foundation
import FWTNotifiable

extension NotificationEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .opened:
            return "Opened"
        case .received:
            return "Received"
        case .statusFailure:
            return "Failure on updating Status"
        case .statusUpdate:
            return "Updated Status"
        }
    }
}

private let kLogKey = "SampleApp.Log.Storage"

private extension UserDefaults {
    var logDictionary: [TimeInterval: NSSecureCoding] {
        get {
            guard let data = self.object(forKey: kLogKey) as? Data else {
                return [:]
            }
            guard let response = NSKeyedUnarchiver.unarchiveObject(with: data) as? [TimeInterval: NSSecureCoding] else {
                return [:]
            }
            return response
        }
        set {
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            self.setValue(data, forKey: kLogKey)
        }
    }
}

class SampleLogger: NSObject, NotifiableLogger {
    var level: LogLevel
    private let groupId: String
    
    private var userDefaults: UserDefaults {
        return UserDefaults(groupId: self.groupId)
    }
    
    func clear() {
        self.userDefaults.logDictionary = [:]
    }
    
    var logData: String {
        return self.userDefaults.logDictionary.sorted(by: { $0.key < $1.key }).compactMap({ $0.value as? NSString }).map({ $0 as String }).joined(separator: "\n\n")
    }
    
    init(level: LogLevel, groupId: String) {
        self.level = level
        self.groupId = groupId
    }
    
    func log(error: Error) {
        
        guard case .error = self.level else {
            return
        }
        
        self.log(message: "Notifiable error: \(error.localizedDescription)")
    }
    
    func log(_ event: NotificationEvent, notificationId: NSNumber?, error: Error?) {
        if case .none = self.level {
            return
        }
        
        self.log(message: "\(event.description) notification \(notificationId ?? 0) with error \(error?.localizedDescription ?? "(null)")")
    }
    
    func log(message: String) {
        
        if case .none = self.level {
            return
        }
        
        print(message)
        
        let date = Date().timeIntervalSince1970
        var elements = self.userDefaults.logDictionary
        elements[date] = message as NSString
        self.userDefaults.logDictionary = elements
    }
}

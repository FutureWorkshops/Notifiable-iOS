//
//  NotificationService.swift
//  NotificationService
//
//  Created by Igor Fereira on 14/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

import UserNotifications
import FWTNotifiable

let kAppGroupId = "group.com.futureworkshops.notifiable.Sample"

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        NotifiableManager.markAsReceived(notification: request.content.userInfo, groupId: kAppGroupId) { [weak self] (_) in
            guard let contentHandler = self?.contentHandler, let bestAttempt = self?.bestAttemptContent else { return }
            contentHandler(bestAttempt)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = self.contentHandler, let bestAttemptContent =  self.bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

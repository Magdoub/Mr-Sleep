//
//  NotificationService.swift
//  Mr Sleep Notification Service
//
//  Created for Mr Sleep App
//

import UserNotifications
import Foundation

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Check if this is an alarm notification
        guard let isAlarm = bestAttemptContent.userInfo["isAlarm"] as? Bool,
              isAlarm,
              let alarmIdString = bestAttemptContent.userInfo["alarmId"] as? String,
              let repetition = bestAttemptContent.userInfo["repetition"] as? Int else {
            contentHandler(bestAttemptContent)
            return
        }
        
        print("🔔 Notification Service: Processing alarm notification \(repetition + 1)/6 for alarm \(alarmIdString)")
        
        // Check if user has interacted with the device recently
        if shouldCancelRemainingNotifications(alarmId: alarmIdString, currentRepetition: repetition) {
            print("🛑 Notification Service: Cancelling remaining notifications due to user interaction")
            
            // Cancel remaining notifications
            cancelRemainingNotifications(alarmId: alarmIdString, currentRepetition: repetition)
            
            // Modify this notification to indicate it's the last one
            bestAttemptContent.title = "⏰ FINAL WAKE UP!"
            bestAttemptContent.subtitle = "💗 Remaining notifications cancelled"
            bestAttemptContent.body = "Phone unlock detected - alarm stopped"
        }
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func shouldCancelRemainingNotifications(alarmId: String, currentRepetition: Int) -> Bool {
        // Check if there are fewer pending notifications than expected
        // This indicates user interaction
        
        let semaphore = DispatchSemaphore(value: 0)
        var shouldCancel = false
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmNotifications = requests.filter { request in
                request.identifier.contains(alarmId) && request.identifier.contains("-repeat-")
            }
            
            let expectedRemaining = max(0, 6 - currentRepetition - 1)
            let actualPending = alarmNotifications.count
            
            print("🔍 Extension check: Expected \(expectedRemaining), Found \(actualPending)")
            
            // If we have significantly fewer notifications than expected, user likely interacted
            shouldCancel = actualPending < expectedRemaining
            
            semaphore.signal()
        }
        
        semaphore.wait()
        return shouldCancel
    }
    
    private func cancelRemainingNotifications(alarmId: String, currentRepetition: Int) {
        // Cancel all remaining notifications for this alarm
        var identifiersToCancel: [String] = []
        
        for rep in (currentRepetition + 1)..<6 {
            identifiersToCancel.append("\(alarmId)-repeat-\(rep)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToCancel)
        
        print("🚫 Extension: Cancelled \(identifiersToCancel.count) remaining notifications")
        
        // Also try to communicate back to main app that alarm should be disabled
        let defaults = UserDefaults(suiteName: "group.com.magdoub.mrsleep")
        defaults?.set(Date(), forKey: "lastNotificationServiceActivity")
        defaults?.set(alarmId, forKey: "cancelledAlarmId")
    }
}

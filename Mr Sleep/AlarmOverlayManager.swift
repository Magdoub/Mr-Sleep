//
//  AlarmOverlayManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
import SwiftUI

class AlarmOverlayManager: ObservableObject {
    static let shared = AlarmOverlayManager()
    
    @Published var isShowingAlarm = false
    @Published var currentAlarm: AlarmItem?
    
    private init() {}
    
    func showAlarm(_ alarm: AlarmItem) {
        DispatchQueue.main.async {
            self.currentAlarm = alarm
            self.isShowingAlarm = true
            print("🚨 Showing alarm overlay for: \(alarm.label)")
        }
    }
    
    func dismissAlarm() {
        DispatchQueue.main.async {
            self.isShowingAlarm = false
            self.currentAlarm = nil
            print("✅ Alarm dismissed")
        }
    }
    
    func snoozeAlarm() {
        guard let alarm = currentAlarm else { return }
        
        // Dismiss current alarm
        dismissAlarm()
        
        // Schedule snooze notification (9 minutes)
        let content = UNMutableNotificationContent()
        content.title = "⏰ Snoozed Alarm"
        content.body = "Time to wake up! \(alarm.label)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 540, repeats: false) // 9 minutes
        let request = UNNotificationRequest(identifier: "\(alarm.id.uuidString)_snooze", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze: \(error)")
            } else {
                print("💤 Snooze scheduled for 9 minutes")
            }
        }
    }
}
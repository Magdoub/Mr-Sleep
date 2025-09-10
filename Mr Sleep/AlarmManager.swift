//
//  AlarmManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import SwiftUI
import UserNotifications
import Foundation
import AVFoundation
import AudioToolbox
import UIKit
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Alarm Dismissal Manager
class AlarmDismissalManager: ObservableObject {
    static let shared = AlarmDismissalManager()
    
    @Published var isShowingDismissalPage = false
    @Published var currentAlarm: AlarmItem?
    
    private init() {}
    
    func showDismissalPage(for alarm: AlarmItem) {
        print("🔔 DEBUG: showDismissalPage called for alarm: \(alarm.label)")
        DispatchQueue.main.async {
            print("📱 Showing dismissal page for alarm: \(alarm.label)")
            print("🔔 DEBUG: Setting isShowingDismissalPage to true")
            self.currentAlarm = alarm
            self.isShowingDismissalPage = true
            print("🔔 DEBUG: isShowingDismissalPage is now: \(self.isShowingDismissalPage)")
            print("🔔 DEBUG: currentAlarm is now: \(self.currentAlarm?.label ?? "nil")")
        }
    }
    
    func dismissAlarm() {
        DispatchQueue.main.async {
            print("✅ Dismissal page closed")
            self.isShowingDismissalPage = false
            self.currentAlarm = nil
        }
    }
}

// Enhanced AlarmItem with more properties
struct AlarmItem: Identifiable, Codable, Equatable {
    let id = UUID()
    var time: String
    var isEnabled: Bool
    var label: String
    var category: String // "Quick Boost", "Recovery", "Full Recharge"
    var cycles: Int
    var createdFromSleepNow: Bool = false
    var soundName: String = "Morning" // Default to morning sound
    var shouldAutoReset: Bool = false // For manual alarms that should reset after firing
    
    // Equatable conformance
    static func == (lhs: AlarmItem, rhs: AlarmItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Convert time string to Date for scheduling
    var scheduledDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let timeDate = formatter.date(from: time) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get today's date with the alarm time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard let todayAlarmTime = calendar.date(from: components) else { return nil }
        
        // If the time has already passed today, schedule for tomorrow
        if todayAlarmTime <= now {
            return calendar.date(byAdding: .day, value: 1, to: todayAlarmTime)
        } else {
            return todayAlarmTime
        }
    }
}

class AlarmManager: NSObject, ObservableObject {
    static let shared = AlarmManager()
    
    @Published var alarms: [AlarmItem] = []
    private var testAlarms: [AlarmItem] = [] // Temporary storage for test alarms
    private var isProcessingNotificationResponse = false // Flag to prevent race conditions
    
    private override init() {
        super.init()
        loadAlarms()
        requestNotificationPermission()
        checkAndResetExpiredAlarms()
        setupNotificationHandling()
        
        // Always clear badge count on app start
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Development Helper
    func clearAllAlarms() {
        alarms.removeAll()
        UserDefaults.standard.removeObject(forKey: "SavedAlarms")
        
        // Cancel all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All alarms and notifications cleared")
    }
    
    // MARK: - Test Alarm Support
    func addTestAlarm(_ alarm: AlarmItem) {
        // Add test alarm temporarily (not saved to UserDefaults)
        testAlarms.append(alarm)
        print("Added test alarm: \(alarm.label)")
    }
    
    // MARK: - Auto Reset
    func checkAndResetExpiredAlarms() {
        let now = Date()
        
        for index in alarms.indices {
            let alarm = alarms[index]
            if alarm.shouldAutoReset && alarm.isEnabled {
                if let scheduledDate = alarm.scheduledDate {
                    // If the scheduled time has passed, disable the alarm
                    if scheduledDate < now {
                        alarms[index].isEnabled = false
                        cancelNotification(for: alarm)
                        print("Auto-reset alarm: \(alarm.time)")
                    }
                }
            }
        }
        saveAlarms()
    }
    
    // MARK: - Notification Permissions
    func requestNotificationPermission() {
        // Request critical alert permission which might be needed for proper vibration
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .criticalAlert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted (including critical alerts)")
                    self.setupNotificationCategories()
                    // Clear any existing badge count
                    UNUserNotificationCenter.current().setBadgeCount(0)
                    
                    // Also check current notification settings
                    self.checkNotificationSettings()
                } else {
                    print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Current notification settings:")
                print("   - Authorization Status: \(settings.authorizationStatus.rawValue)")
                print("   - Alert Setting: \(settings.alertSetting.rawValue)")
                print("   - Sound Setting: \(settings.soundSetting.rawValue)")
                print("   - Critical Alert Setting: \(settings.criticalAlertSetting.rawValue)")
                print("   - Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
                print("   - Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
                
                if settings.criticalAlertSetting == .disabled {
                    print("⚠️  Critical alerts are DISABLED - this might prevent vibration")
                }
                if settings.soundSetting == .disabled {
                    print("⚠️  Sound is DISABLED - this might prevent vibration")
                }
            }
        }
    }
    
    private func setupNotificationHandling() {
        // Set up notification delegate to handle when alarms fire
        UNUserNotificationCenter.current().delegate = self
        print("🔔 DEBUG: Notification delegate set to AlarmManager")
        
        // Verify the delegate was set correctly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if UNUserNotificationCenter.current().delegate === self {
                print("🔔 DEBUG: Notification delegate verification: SUCCESS")
            } else {
                print("🔔 DEBUG: Notification delegate verification: FAILED - delegate is not AlarmManager")
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Create dismiss action
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Stop All",
            options: [.destructive]
        )
        
        // Create snooze action (for future use)
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION", 
            title: "Snooze 5min",
            options: []
        )
        
        // Create alarm category with actions
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [dismissAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
    
    // MARK: - Alarm Management
    func addAlarm(time: String, category: String, cycles: Int) {
        // Generate label based on category and cycles
        let label = generateAlarmLabel(category: category, cycles: cycles)
        
        let newAlarm = AlarmItem(
            time: time,
            isEnabled: true,
            label: label,
            category: category,
            cycles: cycles,
            createdFromSleepNow: true
        )
        
        alarms.append(newAlarm)
        saveAlarms()
        scheduleNotification(for: newAlarm)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func addManualAlarm(time: String, soundName: String) {
        let newAlarm = AlarmItem(
            time: time,
            isEnabled: true,
            label: "Alarm",
            category: "Manual",
            cycles: 0,
            createdFromSleepNow: false,
            soundName: soundName,
            shouldAutoReset: true
        )
        
        alarms.append(newAlarm)
        saveAlarms()
        scheduleNotification(for: newAlarm)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func removeAlarm(_ alarm: AlarmItem) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            cancelNotification(for: alarm)
            alarms.remove(at: index)
            saveAlarms()
        }
    }
    
    func toggleAlarm(_ alarm: AlarmItem) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            
            if alarms[index].isEnabled {
                scheduleNotification(for: alarms[index])
            } else {
                cancelNotification(for: alarms[index])
            }
            
            saveAlarms()
        }
    }
    
    func updateAlarm(alarm: AlarmItem, newTime: String, newSoundName: String) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            // Cancel existing notification
            cancelNotification(for: alarms[index])
            
            // Update alarm properties
            alarms[index].time = newTime
            alarms[index].soundName = newSoundName
            
            // Reschedule notification if alarm is enabled
            if alarms[index].isEnabled {
                scheduleNotification(for: alarms[index])
            }
            
            saveAlarms()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Helper Methods
    private func generateAlarmLabel(category: String, cycles: Int) -> String {
        let cycleText = cycles == 1 ? "cycle" : "cycles"
        
        switch category.lowercased() {
        case "quick boost":
            return "Quick Boost (\(cycles) \(cycleText))"
        case "recovery":
            return "Recovery Sleep (\(cycles) \(cycleText))"
        case "full recharge":
            return "Full Recharge (\(cycles) \(cycleText))"
        default:
            return "\(category) (\(cycles) \(cycleText))"
        }
    }
    
    // MARK: - Enhanced Alarm Notifications
    private func scheduleNotification(for alarm: AlarmItem) {
        guard alarm.isEnabled, let scheduledDate = alarm.scheduledDate else { return }
        
        // Pre-schedule ALL 6 notifications upfront
        // We'll cancel remaining ones if phone gets unlocked
        scheduleAllNotifications(for: alarm, baseTime: scheduledDate)
    }
    
    private func scheduleAllNotifications(for alarm: AlarmItem, baseTime: Date) {
        print("📅 Pre-scheduling notifications every 3 seconds for alarm: \(alarm.time)")
        
        // Schedule notifications every 3 seconds instead of 30 seconds
        let notificationInterval = 3.0 // 3 seconds
        let maxNotifications = 20 // More notifications since they're every 3 seconds
        
        for repetition in 0..<maxNotifications {
            let notificationTime = baseTime.addingTimeInterval(TimeInterval(Double(repetition) * notificationInterval))
            let notificationId = "\(alarm.id.uuidString)-repeat-\(repetition)"
            
            let content = UNMutableNotificationContent()
            
            // Simple "Tap to dismiss" message for all notifications
            content.title = "Tap to dismiss"
            content.body = "\(alarm.label)"
            
            // ONLY first notification gets sound - others are silent with vibration only
            if repetition == 0 {
                // Use notification sound like test alarm - this works even when phone is locked
                let selectedSoundName = alarm.soundName.lowercased()
                if selectedSoundName.contains("morning") || selectedSoundName == "morning" {
                    if Bundle.main.path(forResource: "morning-alarm-clock", ofType: "mp3") != nil {
                        content.sound = UNNotificationSound(named: UNNotificationSoundName("morning-alarm-clock.mp3"))
                        print("🔊 First notification: Using morning-alarm-clock.mp3")
                    } else {
                        content.sound = .defaultCritical
                    }
                } else if selectedSoundName.contains("smooth") || selectedSoundName == "smooth" {
                    if Bundle.main.path(forResource: "smooth-alarm-clock", ofType: "mp3") != nil {
                        content.sound = UNNotificationSound(named: UNNotificationSoundName("smooth-alarm-clock.mp3"))
                        print("🔊 First notification: Using smooth-alarm-clock.mp3")
                    } else {
                        content.sound = .defaultCritical
                    }
                } else {
                    if Bundle.main.path(forResource: "alarm-clock", ofType: "mp3") != nil {
                        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm-clock.mp3"))
                        print("🔊 First notification: Using alarm-clock.mp3")
                    } else {
                        content.sound = .defaultCritical
                    }
                }
            } else {
                // Subsequent notifications are silent (vibration only)
                content.sound = nil
                print("📳 Notification \(repetition + 1): Silent with vibration only")
            }
            content.categoryIdentifier = "ALARM_CATEGORY"
            print("🔔 DEBUG: Set categoryIdentifier to ALARM_CATEGORY for notification \(repetition + 1)")
            
            // Make notification critical to bypass Do Not Disturb and ensure vibration
            content.interruptionLevel = .critical
            content.relevanceScore = 1.0
            
            // Add extensive custom user info to trigger vibration
            content.userInfo["shouldVibrate"] = true
            content.userInfo["vibrationPattern"] = "alarm"
            content.userInfo["forceVibration"] = true
            
            // No badge numbers to avoid red circles on app icon
            content.badge = nil
            
            // Add user info for enhanced handling
            content.userInfo = [
                "isAlarm": true,
                "alarmId": alarm.id.uuidString,
                "alarmTime": alarm.time,
                "alarmLabel": alarm.label,
                "repetition": repetition,
                "totalRepetitions": maxNotifications,
                "baseTime": baseTime.timeIntervalSince1970
            ]
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            
            // Schedule this notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification \(repetition + 1)/\(maxNotifications): \(error.localizedDescription)")
                } else {
                    print("✅ Scheduled notification \(repetition + 1)/\(maxNotifications) for \(notificationTime)")
                }
            }
        }
        
        // Schedule automatic cleanup after all notifications (60 seconds total)
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxNotifications * Int(notificationInterval))) {
            if let alarmIndex = self.alarms.firstIndex(where: { $0.id == alarm.id && $0.isEnabled }) {
                self.alarms[alarmIndex].isEnabled = false
                self.saveAlarms()
                print("🏁 Automatically toggled off alarm after all \(maxNotifications) notifications: \(alarm.time)")
            }
        }
    }
    
    
    private func scheduleNextNotification(for alarm: AlarmItem, repetition: Int, baseTime: Date) {
        guard repetition < 6 else {
            // All 6 notifications have been processed
            print("All 6 notifications completed for alarm: \(alarm.time)")
            return
        }
        
        let notificationTime = baseTime.addingTimeInterval(TimeInterval(repetition * 30))
        let notificationId = "\(alarm.id.uuidString)-repeat-\(repetition)"
        
        let content = UNMutableNotificationContent()
        
        // Customize title based on repetition
        if repetition == 0 {
            content.title = "🚨 WAKE UP! 🚨"
            content.subtitle = "💗 Tap to continue alarm!"
            content.body = "\(alarm.label) - Sound will loop when opened"
        } else {
            content.title = "⏰ WAKE UP! (Repeat \(repetition + 1)/6)"
            content.subtitle = "💗 Still sleeping? Time to wake up!"
            content.body = "\(alarm.label) - Tap to stop repeating"
        }
        
        // Set custom sound based on alarm's sound selection
        content.sound = getNotificationSound(for: alarm.soundName)
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Make notification critical to bypass Do Not Disturb and volume settings
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        
        // Add badge to make it more noticeable
        content.badge = NSNumber(value: repetition + 1)
        
        // Add user info for enhanced handling
        content.userInfo = [
            "isAlarm": true,
            "alarmId": alarm.id.uuidString,
            "alarmTime": alarm.time,
            "alarmLabel": alarm.label,
            "repetition": repetition,
            "totalRepetitions": 6,
            "baseTime": baseTime.timeIntervalSince1970 // Store base time for next notification scheduling
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        // Schedule this notification
        print("📅 About to schedule notification \(repetition + 1)/6:")
        print("   Notification ID: \(notificationId)")
        print("   Scheduled for: \(notificationTime)")
        print("   Base time: \(baseTime)")
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification repetition \(repetition + 1): \(error.localizedDescription)")
            } else {
                print("✅ Successfully scheduled notification \(repetition + 1)/6 for \(alarm.time)")
            }
        }
    }
    
    
    private func cancelNotification(for alarm: AlarmItem) {
        // Cancel all repetitions of the alarm
        var identifiersToCancel: [String] = []
        
        // Add all repetition identifiers (now 20 notifications instead of 6)
        for repetition in 0..<20 {
            identifiersToCancel.append("\(alarm.id.uuidString)-repeat-\(repetition)")
        }
        
        // Also cancel the legacy identifier for backwards compatibility
        identifiersToCancel.append(alarm.id.uuidString)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("Cancelled all repetitions for alarm: \(alarm.time)")
    }
    
    private func toggleOffAlarm(with alarmId: UUID) {
        // Find and toggle off the alarm
        if let index = alarms.firstIndex(where: { $0.id == alarmId }) {
            alarms[index].isEnabled = false
            saveAlarms()
            print("Automatically toggled off alarm: \(alarms[index].time)")
        }
    }
    
    // MARK: - App Lifecycle Handling
    func handleAppForeground() {
        // Called when app enters foreground (phone unlocked or app opened)
        trackAppActivity()
        checkNotificationServiceActivity()
        
        // Only dismiss alarms if we're not showing the dismissal page or processing notification response
        // This prevents conflicts with notification tap handling
        if !AlarmDismissalManager.shared.isShowingDismissalPage && !isProcessingNotificationResponse {
            dismissActiveAlarmsOnUserInteraction()
        } else {
            print("🔔 App entered foreground but dismissal page is showing or processing notification - not dismissing alarms")
        }
        
        // Clear badge count when app comes to foreground
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    func handleAppBecameActive() {
        // Called when app becomes active (additional check for user interaction)
        trackAppActivity()
        
        // Only dismiss alarms if we're not showing the dismissal page or processing notification response
        // This prevents conflicts with notification tap handling
        if !AlarmDismissalManager.shared.isShowingDismissalPage && !isProcessingNotificationResponse {
            dismissActiveAlarmsOnUserInteraction()
        } else {
            print("🔔 App became active but dismissal page is showing or processing notification - not dismissing alarms")
        }
    }
    
    func handleAppEnteredBackground() {
        // Called when app enters background - this can help detect when user is done interacting
        print("📱 App entered background")
    }
    
    private func trackAppActivity() {
        // Track when the app becomes active for unlock detection
        UserDefaults.standard.set(Date(), forKey: "lastAppActiveTime")
        print("📱 App activity tracked at \(Date())")
    }
    
    private func checkNotificationServiceActivity() {
        // Check if notification service extension has detected user interaction
        let defaults = UserDefaults(suiteName: "group.com.magdoub.mrsleep")
        
        if let lastExtensionActivity = defaults?.object(forKey: "lastNotificationServiceActivity") as? Date,
           let cancelledAlarmId = defaults?.string(forKey: "cancelledAlarmId"),
           let alarmId = UUID(uuidString: cancelledAlarmId) {
            
            let timeSinceExtensionActivity = Date().timeIntervalSince(lastExtensionActivity)
            
            // If extension was active within last 60 seconds, it detected user interaction
            if timeSinceExtensionActivity < 60 {
                print("🔔 Notification service detected user interaction \(Int(timeSinceExtensionActivity))s ago")
                
                // Find and disable the alarm
                if let alarm = alarms.first(where: { $0.id == alarmId && $0.isEnabled }) {
                    cancelNotification(for: alarm)
                    toggleOffAlarm(with: alarmId)
                    dismissLiveActivity(for: alarmId.uuidString)
                    
                    print("✅ Disabled alarm based on notification service detection: \(alarm.time)")
                }
                
                // Clear the extension activity markers
                defaults?.removeObject(forKey: "lastNotificationServiceActivity")
                defaults?.removeObject(forKey: "cancelledAlarmId")
            }
        }
    }
    
    private func dismissActiveAlarmsOnUserInteraction() {
        let now = Date()
        
        print("🔍 Checking for active alarms at \(now)")
        
        // First, check for alarms with pending notifications (most reliable method)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmNotificationIds = requests.compactMap { request -> String? in
                let identifier = request.identifier
                if identifier.contains("-repeat-") {
                    return String(identifier.prefix(while: { $0 != "-" }))
                }
                return nil
            }
            
            DispatchQueue.main.async {
                let alarmsWithPendingNotifications = self.alarms.filter { alarm in
                    alarm.isEnabled && alarmNotificationIds.contains(alarm.id.uuidString)
                }
                
                if !alarmsWithPendingNotifications.isEmpty {
                    print("🔴 Found \(alarmsWithPendingNotifications.count) alarms with pending notifications - dismissing due to user interaction")
                    
                    for alarm in alarmsWithPendingNotifications {
                        // Cancel all notifications for this alarm
                        self.cancelNotification(for: alarm)
                        
                        // Toggle off the alarm
                        self.toggleOffAlarm(with: alarm.id)
                        
                        // Dismiss any live activities
                        self.dismissLiveActivity(for: alarm.id.uuidString)
                        
                        print("✅ Dismissed active alarm with pending notifications: \(alarm.time)")
                    }
                    
                    // Also clear any notification badges
                    UNUserNotificationCenter.current().setBadgeCount(0)
                } else {
                    // Fallback: Use time-based detection for alarms that have fired but might not have pending notifications
                    self.dismissActiveAlarmsByTime()
                }
            }
        }
    }
    
    private func dismissActiveAlarmsByTime() {
        let now = Date()
        
        // Find alarms that should be active right now (time-based fallback)
        let activeAlarms = alarms.filter { alarm in
            guard alarm.isEnabled else { 
                print("⚪ Alarm \(alarm.time) is disabled, skipping")
                return false 
            }
            
            // Parse the alarm time for today
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            guard let alarmTime = formatter.date(from: alarm.time) else {
                print("❌ Could not parse alarm time: \(alarm.time)")
                return false
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            
            // Create today's alarm time
            let todayAlarmComponents = calendar.dateComponents([.hour, .minute], from: alarmTime)
            let todayAlarmTime = calendar.date(bySettingHour: todayAlarmComponents.hour!, 
                                              minute: todayAlarmComponents.minute!, 
                                              second: 0, 
                                              of: today)!
            
            // Create yesterday's alarm time (in case alarm was set yesterday evening)
            let yesterdayAlarmTime = calendar.date(bySettingHour: todayAlarmComponents.hour!, 
                                                  minute: todayAlarmComponents.minute!, 
                                                  second: 0, 
                                                  of: yesterday)!
            
            // Check if alarm time has PASSED and is within 5 minutes after (not before)
            // Only consider alarms "active" if they've already fired
            let todayInWindow = todayAlarmTime <= now && now.timeIntervalSince(todayAlarmTime) <= 300 // 0 to 5 minutes AFTER alarm
            let yesterdayInWindow = yesterdayAlarmTime <= now && now.timeIntervalSince(yesterdayAlarmTime) <= 300 // 0 to 5 minutes AFTER alarm
            
            let isActive = todayInWindow || yesterdayInWindow
            
            if isActive {
                let activeTime = todayInWindow ? todayAlarmTime : yesterdayAlarmTime
                let minutesAfter = Int(now.timeIntervalSince(activeTime) / 60)
                print("🔴 Found active alarm by time: \(alarm.time) (fired \(minutesAfter) minutes ago)")
            } else {
                // Check if alarm is in the future
                if todayAlarmTime > now {
                    let minutesUntil = Int(todayAlarmTime.timeIntervalSince(now) / 60)
                    print("⚪ Alarm \(alarm.time) is scheduled for future (\(minutesUntil) minutes from now) - NOT dismissing")
                } else {
                    print("⚪ Alarm \(alarm.time) not in active window (too old)")
                }
            }
            
            return isActive
        }
        
        if !activeAlarms.isEmpty {
            print("📱 User interaction detected - dismissing \(activeAlarms.count) active alarm(s)")
            
            for alarm in activeAlarms {
                // Cancel all notifications for this alarm
                cancelNotification(for: alarm)
                
                // Toggle off the alarm
                toggleOffAlarm(with: alarm.id)
                
                // Dismiss any live activities
                dismissLiveActivity(for: alarm.id.uuidString)
                
                print("✅ Dismissed active alarm: \(alarm.time)")
            }
            
            // Also clear any notification badges
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            print("⚪ No active alarms found by time-based detection")
        }
    }
    
    private func checkAndToggleOffAlarmsWithPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmNotificationIds = requests.compactMap { request -> String? in
                let id = request.identifier
                if id.contains("-repeat-") {
                    return String(id.prefix(while: { $0 != "-" }))
                }
                return id
            }
            
            DispatchQueue.main.async {
                let uniqueAlarmIds = Set(alarmNotificationIds)
                print("🔍 Found \(uniqueAlarmIds.count) alarms with pending notifications")
                
                for alarmIdString in uniqueAlarmIds {
                    if let alarmId = UUID(uuidString: alarmIdString),
                       let alarm = self.alarms.first(where: { $0.id == alarmId && $0.isEnabled }) {
                        
                        print("🔴 Found alarm with pending notifications, toggling off: \(alarm.time)")
                        self.cancelNotification(for: alarm)
                        self.toggleOffAlarm(with: alarmId)
                        self.dismissLiveActivity(for: alarmIdString)
                    }
                }
            }
        }
    }
    
    // MARK: - Public method for manual dismissal
    func dismissActiveAlarms() {
        // Public method that can be called from anywhere in the app
        dismissActiveAlarmsOnUserInteraction()
    }
    
    // MARK: - Lock State Detection
    private func isPhoneLocked() -> Bool {
        // iOS doesn't provide a direct way to check if phone is locked
        // We use heuristics based on app state and user activity
        
        let appState = UIApplication.shared.applicationState
        let lastActiveTime = UserDefaults.standard.object(forKey: "lastAppActiveTime") as? Date ?? Date.distantPast
        let timeSinceLastActive = Date().timeIntervalSince(lastActiveTime)
        
        print("🔍 Lock Detection Debug:")
        print("   App State: \(appState.rawValue) (0=active, 1=inactive, 2=background)")
        print("   Last Active: \(lastActiveTime)")
        print("   Time Since Active: \(Int(timeSinceLastActive))s")
        
        // If app is active, phone is definitely unlocked
        if appState == .active {
            print("🔓 RESULT: Phone is unlocked (app is active)")
            return false
        }
        
        // For notifications firing while phone is locked, app will typically be in background
        // and there should be no recent activity
        
        // If app was very recently active (within 5 seconds), phone might still be unlocked
        if timeSinceLastActive < 5 {
            print("🔓 RESULT: Phone is likely unlocked (very recent activity: \(Int(timeSinceLastActive))s)")
            return false
        }
        
        // If app is inactive (transitioning) and was recently active, might be unlocking
        if appState == .inactive && timeSinceLastActive < 15 {
            print("🔓 RESULT: Phone is likely unlocked (inactive state with recent activity)")
            return false
        }
        
        // For alarm notifications, if we're here with background state and no recent activity,
        // the phone is very likely locked
        print("🔒 RESULT: Phone is likely locked")
        print("   Reason: App in background (\(appState.rawValue)) with no recent activity (\(Int(timeSinceLastActive))s)")
        return true
    }
    
    // MARK: - Background Unlock Detection
    private func scheduleBackgroundUnlockCheck(for alarm: AlarmItem, afterNotification repetition: Int) {
        // Schedule multiple aggressive checks to detect phone unlock
        // Check every 3 seconds for the next 27 seconds (before next notification)
        for seconds in stride(from: 3, through: 27, by: 3) {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(seconds)) {
                self.checkForPhoneUnlock(alarmId: alarm.id, repetition: repetition, checkNumber: seconds / 3)
            }
        }
    }
    
    private func checkForPhoneUnlock(alarmId: UUID, repetition: Int, checkNumber: Int) {
        guard let alarm = alarms.first(where: { $0.id == alarmId && $0.isEnabled }) else {
            return // Alarm already disabled
        }
        
        print("🔍 Background unlock check #\(checkNumber) for alarm \(alarm.time)")
        
        // Multiple heuristics to detect phone unlock
        let appState = UIApplication.shared.applicationState
        
        // Check 1: App state changed to inactive (transitioning from background)
        if appState == .inactive {
            print("📱 App state is inactive - phone likely being unlocked")
            self.stopAlarmDueToUnlock(alarm: alarm, reason: "App state inactive")
            return
        }
        
        // Check 2: Check if notifications are being delivered vs pending
        UNUserNotificationCenter.current().getPendingNotificationRequests { pendingRequests in
            UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
                
                let alarmPending = pendingRequests.filter { $0.identifier.contains(alarmId.uuidString) }.count
                let alarmDelivered = deliveredNotifications.filter { $0.request.identifier.contains(alarmId.uuidString) }.count
                
                DispatchQueue.main.async {
                    print("   Pending: \(alarmPending), Delivered: \(alarmDelivered)")
                    
                    // If we have delivered notifications but fewer pending than expected, user saw them
                    let expectedPending = max(0, 6 - repetition - 1)
                    
                    if alarmDelivered > 0 && alarmPending < expectedPending {
                        print("📱 Notifications delivered but some missing - phone unlocked")
                        self.stopAlarmDueToUnlock(alarm: alarm, reason: "Notifications delivered and cleared")
                        return
                    }
                    
                    // Check 3: Try to access device orientation (fails when locked on some devices)
                    let orientation = UIDevice.current.orientation
                    if orientation != .unknown {
                        print("📱 Device orientation accessible - phone likely unlocked")
                        self.stopAlarmDueToUnlock(alarm: alarm, reason: "Device orientation accessible")
                        return
                    }
                    
                    print("   No unlock detected in check #\(checkNumber)")
                }
            }
        }
    }
    
    private func checkIfAlarmShouldContinue(alarmId: UUID) {
        guard let alarm = alarms.first(where: { $0.id == alarmId && $0.isEnabled }) else {
            return // Alarm already disabled
        }
        
        // Check if user has interacted with the app or phone
        let lastActiveTime = UserDefaults.standard.object(forKey: "lastAppActiveTime") as? Date ?? Date.distantPast
        let timeSinceLastActive = Date().timeIntervalSince(lastActiveTime)
        
        // If app was active within last 30 seconds, user unlocked phone
        if timeSinceLastActive < 30 {
            print("🔓 Recent app activity detected (\(Int(timeSinceLastActive))s ago) - stopping alarm")
            stopAlarmDueToUnlock(alarm: alarm, reason: "Recent app activity")
        } else {
            print("🔍 Alarm check: No recent activity (\(Int(timeSinceLastActive))s ago)")
        }
    }
    
    private func stopAlarmDueToUnlock(alarm: AlarmItem, reason: String) {
        print("🔓 Phone unlock detected: \(reason)")
        print("✅ Stopping alarm due to phone unlock: \(alarm.time)")
        
        cancelNotification(for: alarm)
        toggleOffAlarm(with: alarm.id)
        dismissLiveActivity(for: alarm.id.uuidString)
        
        // Clear badge
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    private func checkIfNextNotificationShouldFire(alarmId: UUID, currentRepetition: Int) {
        // Check if the alarm is still enabled
        guard let alarm = alarms.first(where: { $0.id == alarmId && $0.isEnabled }) else {
            return // Alarm already disabled
        }
        
        // Check if the next notification is still pending
        let nextRepetition = currentRepetition + 1
        let nextNotificationId = "\(alarmId.uuidString)-repeat-\(nextRepetition)"
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let nextNotificationExists = requests.contains { request in
                request.identifier == nextNotificationId
            }
            
            DispatchQueue.main.async {
                print("🔍 Checking if next notification (\(nextRepetition + 1)/6) should fire...")
                print("   Next notification ID: \(nextNotificationId)")
                print("   Still pending: \(nextNotificationExists)")
                
                if !nextNotificationExists {
                    // Next notification was cancelled/cleared - user interacted
                    print("🎯 Next notification missing - user interaction detected")
                    
                    self.cancelNotification(for: alarm)
                    self.toggleOffAlarm(with: alarmId)
                    self.dismissLiveActivity(for: alarmId.uuidString)
                    
                    print("✅ Stopped alarm due to missing next notification: \(alarm.time)")
                } else {
                    print("⏰ Next notification still pending - alarm continues")
                }
            }
        }
    }
    
    // MARK: - Unlock Detection
    private func scheduleUnlockDetection(for alarm: AlarmItem) {
        // Schedule periodic checks to see if user has unlocked phone
        // We'll check every 15 seconds for the first 3 minutes (duration of 6 notifications)
        
        for checkInterval in stride(from: 15, through: 180, by: 15) {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(checkInterval)) {
                self.checkForUserActivity(alarmId: alarm.id)
            }
        }
    }
    
    private func checkForUserActivity(alarmId: UUID) {
        // Check if the alarm is still enabled and active
        guard let alarm = alarms.first(where: { $0.id == alarmId && $0.isEnabled }) else {
            return // Alarm already disabled
        }
        
        // Check if the app has become active recently (indicating user interaction)
        let now = Date()
        let lastActiveTime = UserDefaults.standard.object(forKey: "lastAppActiveTime") as? Date ?? Date.distantPast
        let timeSinceLastActive = now.timeIntervalSince(lastActiveTime)
        
        // If app was active within the last 30 seconds, consider it user interaction
        if timeSinceLastActive < 30 {
            print("🔍 Detected recent user activity (app active \(Int(timeSinceLastActive))s ago), dismissing alarm: \(alarm.time)")
            cancelNotification(for: alarm)
            toggleOffAlarm(with: alarmId)
            dismissLiveActivity(for: alarmId.uuidString)
            return
        }
        
        // Alternative check: See if there are fewer pending notifications than expected
        // This could indicate user interaction with notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmNotifications = requests.filter { request in
                request.identifier.contains(alarmId.uuidString)
            }
            
            DispatchQueue.main.async {
                // If there are significantly fewer notifications than expected, user likely interacted
                let expectedNotifications = 6 // We schedule 6 notifications
                let actualNotifications = alarmNotifications.count
                
                if actualNotifications < expectedNotifications - 1 {
                    print("🔍 Detected notification interaction (\(actualNotifications)/\(expectedNotifications) remaining), dismissing alarm: \(alarm.time)")
                    self.cancelNotification(for: alarm)
                    self.toggleOffAlarm(with: alarmId)
                    self.dismissLiveActivity(for: alarmId.uuidString)
                }
            }
        }
        
        // Additional check: Look for any signs of device activity
        // Check if notification center has been accessed (indicated by delivered notifications being cleared)
        UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
            let alarmDeliveredCount = deliveredNotifications.filter { notification in
                notification.request.identifier.contains(alarmId.uuidString)
            }.count
            
            DispatchQueue.main.async {
                // If user has cleared notifications from notification center, they're likely awake
                if alarmDeliveredCount == 0 {
                    print("🔍 Detected notification center interaction (no delivered notifications), dismissing alarm: \(alarm.time)")
                    self.cancelNotification(for: alarm)
                    self.toggleOffAlarm(with: alarmId)
                    self.dismissLiveActivity(for: alarmId.uuidString)
                }
            }
        }
    }
    
    private func getNotificationSound(for soundName: String) -> UNNotificationSound {
        // Use the specific sound based on user selection
        let fileName = soundName.lowercased()
        
        if fileName.contains("morning") {
            // Try morning-alarm-clock sound
            if Bundle.main.path(forResource: "morning-alarm-clock", ofType: "mp3") != nil {
                print("🔊 Using morning-alarm-clock.mp3 for notification sound")
                return UNNotificationSound(named: UNNotificationSoundName(rawValue: "morning-alarm-clock.mp3"))
            }
        } else if fileName.contains("smooth") {
            // Try smooth-alarm-clock sound
            if Bundle.main.path(forResource: "smooth-alarm-clock", ofType: "mp3") != nil {
                print("🔊 Using smooth-alarm-clock.mp3 for notification sound")
                return UNNotificationSound(named: UNNotificationSoundName(rawValue: "smooth-alarm-clock.mp3"))
            }
        } else if fileName.contains("alarm-clock") || fileName == "classic" {
            // Try original alarm-clock sound
            if Bundle.main.path(forResource: "alarm-clock", ofType: "mp3") != nil {
                print("🔊 Using alarm-clock.mp3 for notification sound")
                return UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm-clock.mp3"))
            }
        }
        
        // Default to morning sound if available, then smooth, then classic, then system
        if Bundle.main.path(forResource: "morning-alarm-clock", ofType: "mp3") != nil {
            print("🔊 Using morning-alarm-clock.mp3 as default notification sound")
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: "morning-alarm-clock.mp3"))
        } else if Bundle.main.path(forResource: "smooth-alarm-clock", ofType: "mp3") != nil {
            print("🔊 Using smooth-alarm-clock.mp3 as fallback notification sound")
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: "smooth-alarm-clock.mp3"))
        } else if Bundle.main.path(forResource: "alarm-clock", ofType: "mp3") != nil {
            print("🔊 Using alarm-clock.mp3 as fallback notification sound")
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm-clock.mp3"))
        }
        
        // If no custom sound file, use iOS critical sound
        print("🔊 No custom alarm sound found, using defaultCritical")
        return UNNotificationSound.defaultCritical
    }
    
    // MARK: - Persistence
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: "SavedAlarms")
        }
    }
    
    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: "SavedAlarms"),
           let decoded = try? JSONDecoder().decode([AlarmItem].self, from: data) {
            alarms = decoded
        } else {
            // Start with empty alarms array
            alarms = []
        }
    }
    
    // MARK: - Live Activities Integration
    
    func startLiveActivityForAlarm(_ alarm: AlarmItem) {
        // Start enhanced alarm with overlay (sound is handled separately by notification system)
        print("🚨 Starting alarm overlay for: \(alarm.label)")
        
        // Show full-screen alarm overlay
        AlarmOverlayManager.shared.showAlarm(alarm)
        
        // Start Live Activity on supported devices (if available)
        startLiveActivity(for: alarm)
    }
    
    func dismissLiveActivity(for alarmId: String) {
        // Stop alarm overlay and Live Activity
        print("⏹️ Stopping alarm for ID: \(alarmId)")
        
        // Stop alarm sound
        stopAlarmSound()
        
        // Dismiss alarm overlay
        AlarmOverlayManager.shared.dismissAlarm()
        
        // Stop Live Activity
        stopLiveActivity()
    }
    
    // MARK: - Direct Alarm Sound Management
    private var audioPlayer: AVAudioPlayer?
    private var isAlarmSounding = false
    private var vibrationTimer: Timer?
    
    private func startAlarmSound(for alarm: AlarmItem? = nil) {
        guard !isAlarmSounding else { return }
        isAlarmSounding = true
        
        print("🔊 Starting alarm sound with full volume configuration")
        
        // Configure audio session for background playback when phone is locked
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // CRITICAL: Use .playAndRecord category which allows background audio
            // This is the only category that reliably works when phone is locked
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [
                .defaultToSpeaker,  // Use speaker by default (not earpiece)
                .allowBluetooth,    // Allow Bluetooth audio
                .overrideMutedMicrophoneInterruption  // Override mute switch
            ])
            
            // Activate with option to notify other apps
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Check audio session properties
            print("✅ Audio session configured for BACKGROUND PLAYBACK:")
            print("   - Category: \(audioSession.category.rawValue)")
            print("   - Category options: \(audioSession.categoryOptions)")
            print("   - Output volume: \(audioSession.outputVolume)")
            print("   - Is other audio playing: \(audioSession.isOtherAudioPlaying)")
            print("   - Current route: \(audioSession.currentRoute.outputs.first?.portType.rawValue ?? "unknown")")
            
        } catch {
            print("❌ Failed to set up audio session for background: \(error)")
            print("   - This might prevent audio from playing when phone is locked")
        }
        
        // List all available sound files for debugging
        let availableFiles = ["morning-alarm-clock.mp3", "smooth-alarm-clock.mp3", "alarm-clock.mp3"]
        print("🔊 Available sound files: \(availableFiles)")
        
        // Try to play custom sound based on alarm's sound selection
        var soundURL: URL?
        let selectedSoundName = alarm?.soundName ?? "morning"
        
        print("🔊 Alarm sound selection: '\(selectedSoundName)'")
        
        if let alarm = alarm {
            let soundName = alarm.soundName.lowercased()
            
            if soundName.contains("morning") || soundName == "morning" {
                soundURL = Bundle.main.url(forResource: "morning-alarm-clock", withExtension: "mp3")
                print("🔊 Attempting to play morning-alarm-clock sound - URL: \(soundURL?.absoluteString ?? "nil")")
            } else if soundName.contains("smooth") || soundName == "smooth" {
                soundURL = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3")
                print("🔊 Attempting to play smooth-alarm-clock sound - URL: \(soundURL?.absoluteString ?? "nil")")
            } else if soundName.contains("classic") || soundName.contains("alarm") || soundName == "alarm-clock" {
                soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3")
                print("🔊 Attempting to play alarm-clock sound - URL: \(soundURL?.absoluteString ?? "nil")")
            }
        }
        
        // Fallback to morning sound as default
        if soundURL == nil {
            print("🔄 No specific sound found, trying fallback to morning-alarm-clock.mp3")
            soundURL = Bundle.main.url(forResource: "morning-alarm-clock", withExtension: "mp3")
            print("🔊 Fallback URL: \(soundURL?.absoluteString ?? "nil")")
            
            // Then try smooth alarm
            if soundURL == nil {
                print("🔄 Morning sound not found, trying smooth-alarm-clock.mp3")
                soundURL = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3")
                print("🔊 Smooth URL: \(soundURL?.absoluteString ?? "nil")")
            }
            
            // Finally try classic alarm
            if soundURL == nil {
                print("🔄 Smooth sound not found, trying alarm-clock.mp3")
                soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3")
                print("🔊 Classic URL: \(soundURL?.absoluteString ?? "nil")")
            }
        }
        
        if let soundURL = soundURL {
            print("🎵 Creating audio player with URL: \(soundURL.absoluteString)")
            
            // Check if file exists
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: soundURL.path) {
                print("✅ Sound file exists at path: \(soundURL.path)")
            } else {
                print("❌ Sound file does NOT exist at path: \(soundURL.path)")
            }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = 1.0
                
                // Enable background playback and lock screen controls
                audioPlayer?.prepareToPlay()
                
                print("🎵 Audio player created successfully:")
                print("   - Duration: \(audioPlayer?.duration ?? 0) seconds")
                print("   - Volume: \(audioPlayer?.volume ?? 0)")
                print("   - Number of loops: \(audioPlayer?.numberOfLoops ?? 0)")
                
                let success = audioPlayer?.play() ?? false
                if success {
                    print("🔊 SUCCESS: Playing custom alarm sound: \(soundURL.lastPathComponent)")
                    print("   - Is playing: \(audioPlayer?.isPlaying ?? false)")
                    print("   - Current time: \(audioPlayer?.currentTime ?? 0)")
                    
                    // Keep audio session active to prevent stopping when phone locks
                    try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    print("   - Audio session kept active for background playback")
                } else {
                    print("❌ FAILED: Could not start audio playback for \(soundURL.lastPathComponent)")
                    print("   - Audio player error or audio session issue")
                    playSystemAlarmSound()
                }
            } catch {
                print("❌ Failed to create audio player: \(error)")
                print("   - Error details: \(error.localizedDescription)")
                playSystemAlarmSound()
            }
        } else {
            print("❌ No sound URL found - using system sound")
            playSystemAlarmSound()
        }
    }
    
    private func stopAlarmSound() {
        isAlarmSounding = false
        
        // Stop custom audio
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Stop vibration
        stopContinuousVibration()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func startContinuousVibration() {
        print("📳 Starting continuous vibration pattern")
        
        // Stop any existing vibration timer
        vibrationTimer?.invalidate()
        
        // Immediate vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Continue vibrating every 3 seconds to match notification frequency
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard self?.isAlarmSounding == true else {
                self?.stopContinuousVibration()
                return
            }
            
            // Trigger vibration
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            // Also trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            print("📳 Continuous vibration triggered")
        }
    }
    
    private func stopContinuousVibration() {
        print("📳 Stopping continuous vibration")
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
    
    private func startContinuousAlarmLoop(for alarm: AlarmItem) {
        print("🔂 Starting continuous alarm loop for: \(alarm.soundName)")
        
        // Delay the loop start by 2 seconds to let the notification sound play first
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startAlarmSound(for: alarm)
        }
    }
    
    private func playSystemAlarmSound() {
        print("🔊 Using system alarm sound")
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !self.isAlarmSounding {
                timer.invalidate()
                return
            }
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    // MARK: - Enhanced Alarm Experience
    private func startLiveActivity(for alarm: AlarmItem) {
        print("🚨 Enhanced alarm notification for: \(alarm.label)")
        
        // Start intense haptic feedback pattern
        startAlarmHaptics()
        
        // Note: Alarm sound is now handled by the notification system, not here
    }
    
    private func startAlarmHaptics() {
        // Create intense haptic feedback pattern for waking up
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        
        // Create a repeating timer for haptic feedback
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !self.isAlarmSounding {
                timer.invalidate()
                return
            }
            
            // Trigger heavy impact feedback
            impactFeedback.impactOccurred()
            
            // Add notification feedback as well
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
    
    private func stopLiveActivity() {
        print("🛑 Enhanced alarm notification stopped")
        // Future: Stop Live Activities here
    }
    
    private func getCurrentTimeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AlarmManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Extract alarm ID from notification identifier (handle both new format and legacy)
        let notificationId = notification.request.identifier
        let alarmIdString: String
        
        if notificationId.contains("-repeat-") {
            // New format: "UUID-repeat-0", "UUID-repeat-1", etc.
            alarmIdString = String(notificationId.prefix(while: { $0 != "-" }))
        } else {
            // Legacy format: just the UUID
            alarmIdString = notificationId
        }
        
        // Check if this is the first notification (repeat-0) or a later one
        let isFirstNotification = notificationId.contains("-repeat-0") || !notificationId.contains("-repeat-")
        
        if let alarmId = UUID(uuidString: alarmIdString) {
            // Check both regular alarms and test alarms
            let alarm = alarms.first(where: { $0.id == alarmId }) ?? 
                       testAlarms.first(where: { $0.id == alarmId })
            
            if let alarm = alarm {
                let currentRepetition = notification.request.content.userInfo["repetition"] as? Int ?? 0
                print("🔔 Notification \(currentRepetition + 1)/20 is presenting for alarm: \(alarm.time)")
                
                if isFirstNotification {
                    // First notification plays initial sound, then start continuous looping
                    print("🎵 First notification plays initial sound, starting continuous loop")
                    
                    // Start continuous looping audio player for background
                    startContinuousAlarmLoop(for: alarm)
                    
                    // Start Live Activity when alarm fires (only for first notification)
                    startLiveActivityForAlarm(alarm)
                    
                    // Start continuous vibration pattern
                    startContinuousVibration()
                }
                
                // Trigger vibration for each notification using multiple methods
                DispatchQueue.main.async {
                    print("🔔 Attempting to trigger vibration for notification \(currentRepetition + 1)/20")
                    
                    // Method 1: System vibration sound
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    print("   ✓ Called AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)")
                    
                    // Method 2: Impact feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    print("   ✓ Called UIImpactFeedbackGenerator heavy impact")
                    
                    // Method 3: Notification feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.prepare()
                    notificationFeedback.notificationOccurred(.error)
                    print("   ✓ Called UINotificationFeedbackGenerator error")
                    
                    // Method 4: Try multiple system sounds
                    AudioServicesPlaySystemSound(1519) // Actuate system sound
                    print("   ✓ Called AudioServicesPlaySystemSound(1519)")
                    
                    print("📳 All vibration methods triggered for notification \(currentRepetition + 1)/20")
                }
                
                // Schedule a background task to check if phone gets unlocked
                scheduleBackgroundUnlockCheck(for: alarm, afterNotification: currentRepetition)
                
                // Also disable the alarm if it's set to auto-reset (only for regular alarms)
                if alarm.shouldAutoReset && alarms.contains(where: { $0.id == alarmId }) {
                    DispatchQueue.main.async {
                        if let index = self.alarms.firstIndex(where: { $0.id == alarmId }) {
                            self.alarms[index].isEnabled = false
                            self.saveAlarms()
                        }
                    }
                }
                
                // Remove test alarm after use
                testAlarms.removeAll(where: { $0.id == alarmId })
            }
        }
        
        // Show the notification with banner only (no sound since music is handled separately)
        completionHandler([.banner])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 DEBUG: userNotificationCenter didReceive response called!")
        print("🔔 DEBUG: Notification ID: \(response.notification.request.identifier)")
        print("🔔 DEBUG: Action identifier: \(response.actionIdentifier)")
        print("🔔 DEBUG: User info: \(response.notification.request.content.userInfo)")
        print("🔔 DEBUG: Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Set flag to prevent app lifecycle handlers from interfering
        isProcessingNotificationResponse = true
        print("🔔 DEBUG: Set isProcessingNotificationResponse to true")
        
        // SIMPLE TEST: Just show a basic alert to verify this method is called
        DispatchQueue.main.async {
            print("🔔 DEBUG: About to show test alert")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let alert = UIAlertController(title: "Notification Tapped", message: "Response handler called!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                window.rootViewController?.present(alert, animated: true)
            }
        }
        
        // Extract alarm ID from notification identifier (handle both new format and legacy)
        let notificationId = response.notification.request.identifier
        let alarmIdString: String
        
        if notificationId.contains("-repeat-") {
            // New format: "UUID-repeat-0", "UUID-repeat-1", etc.
            alarmIdString = String(notificationId.prefix(while: { $0 != "-" }))
        } else {
            // Legacy format: just the UUID
            alarmIdString = notificationId
        }
        
        print("🔔 User interacted with alarm notification: \(response.actionIdentifier)")
        
        if let alarmId = UUID(uuidString: alarmIdString) {
            // Check both regular alarms and test alarms
            let alarm = alarms.first(where: { $0.id == alarmId }) ?? 
                       testAlarms.first(where: { $0.id == alarmId })
            
            if let alarm = alarm {
                print("🔔 Found alarm: \(alarm.label) (ID: \(alarm.id.uuidString))")
                
                switch response.actionIdentifier {
                case UNNotificationDefaultActionIdentifier:
                    // User tapped the notification itself (not an action button)
                    print("📱 User tapped notification - showing dismissal page")
                    
                    // Show the new dismissal page
                    DispatchQueue.main.async {
                        print("🔔 About to show dismissal page for alarm: \(alarm.label)")
                        AlarmDismissalManager.shared.showDismissalPage(for: alarm)
                        print("🔔 Dismissal page show request completed")
                    }
                    
                    // IMPORTANT: Don't stop the alarm sound yet - let the dismissal page handle it
                    // The sound should continue until the user explicitly dismisses it
                    
                case "DISMISS_ACTION":
                    // User explicitly dismissed via action button
                    cancelNotification(for: alarm)
                    toggleOffAlarm(with: alarmId)
                    dismissLiveActivity(for: alarmIdString)
                    print("✅ User dismissed via action button: \(alarm.time)")
                    
                case "SNOOZE_ACTION":
                    // Handle snooze - schedule a new alarm 5 minutes from now
                    cancelNotification(for: alarm) // Cancel remaining repetitions
                    toggleOffAlarm(with: alarmId) // Toggle off the current alarm
                    
                    // Schedule a new snooze alarm 5 minutes from now
                    let snoozeTime = Date().addingTimeInterval(5 * 60) // 5 minutes
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    let snoozeTimeString = formatter.string(from: snoozeTime)
                    
                    addManualAlarm(time: snoozeTimeString, soundName: alarm.soundName)
                    print("🔄 Snoozed alarm for 5 minutes: \(snoozeTimeString)")
                    
                default:
                    // For other interactions - show dismissal page
                    print("📱 User interacted with notification - showing dismissal page")
                    
                    DispatchQueue.main.async {
                        AlarmDismissalManager.shared.showDismissalPage(for: alarm)
                    }
                }
            } else {
                print("❌ Alarm not found for ID: \(alarmIdString)")
            }
        } else {
            print("❌ Invalid alarm ID: \(alarmIdString)")
        }
        
        // Clear the flag after a delay to give dismissal page time to show
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isProcessingNotificationResponse = false
            print("🔔 Cleared notification response processing flag")
        }
        
        completionHandler()
    }
    
}

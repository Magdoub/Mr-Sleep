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
#if canImport(ActivityKit)
import ActivityKit
#endif

// Enhanced AlarmItem with more properties
struct AlarmItem: Identifiable, Codable {
    let id = UUID()
    var time: String
    var isEnabled: Bool
    var label: String
    var category: String // "Quick Boost", "Recovery", "Full Recharge"
    var cycles: Int
    var createdFromSleepNow: Bool = false
    var soundName: String = "Smooth" // Default to smooth sound
    var shouldAutoReset: Bool = false // For manual alarms that should reset after firing
    
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
    @Published var alarms: [AlarmItem] = []
    private var testAlarms: [AlarmItem] = [] // Temporary storage for test alarms
    
    override init() {
        super.init()
        loadAlarms()
        requestNotificationPermission()
        checkAndResetExpiredAlarms()
        setupNotificationHandling()
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    self.setupNotificationCategories()
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func setupNotificationHandling() {
        // Set up notification delegate to handle when alarms fire
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func setupNotificationCategories() {
        // Create dismiss action
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Stop",
            options: [.destructive]
        )
        
        // Create alarm category with actions
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [dismissAction],
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
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 WAKE UP! 🚨"
        content.subtitle = "💗 Tap to continue alarm!"
        content.body = "\(alarm.label) - Sound will loop when opened"
        
        // Set custom sound based on alarm's sound selection
        content.sound = getNotificationSound(for: alarm.soundName)
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Make notification critical to bypass Do Not Disturb and volume settings
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        
        // Add badge to make it more noticeable
        content.badge = 1
        
        // Add user info for enhanced handling
        content.userInfo = [
            "isAlarm": true,
            "alarmId": alarm.id.uuidString,
            "alarmTime": alarm.time,
            "alarmLabel": alarm.label
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: scheduledDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        // Schedule the main alarm
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(alarm.time)")
            }
        }
        
        // Note: iOS notifications can only play sound once - continuous sound requires background audio
    }
    
    
    private func cancelNotification(for alarm: AlarmItem) {
        // Cancel main notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
    }
    
    private func getNotificationSound(for soundName: String) -> UNNotificationSound {
        // Use the specific sound based on user selection
        let fileName = soundName.lowercased()
        
        if fileName.contains("smooth") {
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
        
        // Default to smooth sound if available, then classic, then system
        if Bundle.main.path(forResource: "smooth-alarm-clock", ofType: "mp3") != nil {
            print("🔊 Using smooth-alarm-clock.mp3 as default notification sound")
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
        // Start enhanced alarm with overlay (sound handled by AlarmRingingView)
        print("🚨 Starting alarm overlay for: \(alarm.label)")
        
        // Show full-screen alarm overlay (this will handle the sound)
        AlarmOverlayManager.shared.showAlarm(alarm)
        
        // Start Live Activity on supported devices (if available)
        startLiveActivity(for: alarm)
    }
    
    func dismissLiveActivity(for alarmId: String) {
        // Stop alarm overlay and Live Activity
        print("⏹️ Stopping alarm for ID: \(alarmId)")
        
        // Dismiss alarm overlay (this will stop the sound too)
        AlarmOverlayManager.shared.dismissAlarm()
        
        // No repeat notifications to cancel anymore
        
        // Stop Live Activity
        stopLiveActivity()
    }
    
    // MARK: - Direct Alarm Sound Management
    private var audioPlayer: AVAudioPlayer?
    private var isAlarmSounding = false
    
    private func startAlarmSound(for alarm: AlarmItem? = nil) {
        guard !isAlarmSounding else { return }
        isAlarmSounding = true
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Try to play custom sound based on alarm's sound selection
        var soundURL: URL?
        
        if let alarm = alarm {
            let soundName = alarm.soundName.lowercased()
            
            if soundName.contains("smooth") {
                // Try smooth-alarm-clock sound
                soundURL = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3") ??
                          Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "wav") ??
                          Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "m4a")
                print("🔊 Attempting to play smooth-alarm-clock sound")
            } else if soundName.contains("classic") || soundName.contains("alarm-clock") {
                // Try original alarm-clock sound
                soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                          Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                          Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a")
                print("🔊 Attempting to play alarm-clock sound")
            }
        }
        
        // Fallback to default sounds if no specific alarm or sound not found
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3") ??
                      Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "wav") ??
                      Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "m4a") ??
                      Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                      Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                      Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a")
        }
        
        if let soundURL = soundURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
                print("🔊 Playing custom alarm sound: \(soundURL.lastPathComponent)")
            } catch {
                print("Failed to play custom sound: \(error)")
                playSystemAlarmSound()
            }
        } else {
            print("No custom alarm sound files found, using system sound")
            playSystemAlarmSound()
        }
    }
    
    private func stopAlarmSound() {
        isAlarmSounding = false
        
        // Stop custom audio
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
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
        
        // Start alarm sound with the specific alarm's sound selection
        startAlarmSound(for: alarm)
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
        
        // When alarm notification is about to be presented, start Live Activity
        if let alarmId = UUID(uuidString: notification.request.identifier) {
            // Check both regular alarms and test alarms
            let alarm = alarms.first(where: { $0.id == alarmId }) ?? 
                       testAlarms.first(where: { $0.id == alarmId })
            
            if let alarm = alarm {
                // Start Live Activity when alarm fires
                startLiveActivityForAlarm(alarm)
                
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
        
        // Show the notification with sound and alert
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let alarmId = response.notification.request.identifier
        
        switch response.actionIdentifier {
        case "DISMISS_ACTION", UNNotificationDefaultActionIdentifier:
            // Handle dismiss - end Live Activity
            dismissLiveActivity(for: alarmId)
            
        default:
            break
        }
        
        completionHandler()
    }
    
}

//
//  AlarmLiveActivityManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
import AVFoundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)

@MainActor
class AlarmLiveActivityManager: ObservableObject {
    static let shared = AlarmLiveActivityManager()
    
    @Published var currentActivity: Activity<AlarmActivityAttributes>?
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    // Start a Live Activity when the alarm goes off
    func startAlarmActivity(for alarm: AlarmItem) {
        // Stop any existing activity first
        if let currentActivity = currentActivity {
            Task {
                await currentActivity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        let attributes = AlarmActivityAttributes(
            alarmId: alarm.id.uuidString,
            originalAlarmTime: alarm.time,
            alarmLabel: alarm.label
        )
        
        let contentState = AlarmActivityAttributes.ContentState(
            alarmTime: alarm.time,
            alarmLabel: alarm.label,
            isActive: true,
            timeRemaining: "Now",
            currentTime: getCurrentTimeString(),
            alarmId: alarm.id.uuidString
        )
        
        do {
            let activity = try Activity<AlarmActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            self.currentActivity = activity
            
            // Start playing alarm sound continuously
            startAlarmSound()
            
            print("Live Activity started for alarm: \(alarm.label)")
            
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    // Update the Live Activity with current time
    func updateActivity() {
        guard let currentActivity = currentActivity else { return }
        
        Task {
            let updatedContentState = AlarmActivityAttributes.ContentState(
                alarmTime: currentActivity.attributes.originalAlarmTime,
                alarmLabel: currentActivity.attributes.alarmLabel,
                isActive: true,
                timeRemaining: "Now",
                currentTime: getCurrentTimeString(),
                alarmId: currentActivity.attributes.alarmId
            )
            
            await currentActivity.update(using: updatedContentState)
        }
    }
    
    // End the Live Activity when alarm is dismissed
    func endActivity(for alarmId: String) {
        guard let currentActivity = currentActivity,
              currentActivity.attributes.alarmId == alarmId else { return }
        
        Task {
            let finalContentState = AlarmActivityAttributes.ContentState(
                alarmTime: currentActivity.attributes.originalAlarmTime,
                alarmLabel: currentActivity.attributes.alarmLabel,
                isActive: false,
                timeRemaining: "Dismissed",
                currentTime: getCurrentTimeString(),
                alarmId: alarmId
            )
            
            await currentActivity.end(using: finalContentState, dismissalPolicy: .immediate)
            
            // Stop alarm sound
            stopAlarmSound()
            
            self.currentActivity = nil
            print("Live Activity ended for alarm: \(alarmId)")
        }
    }
    
    // End any active activity
    func endCurrentActivity() {
        guard let currentActivity = currentActivity else { return }
        
        Task {
            await currentActivity.end(nil, dismissalPolicy: .immediate)
            stopAlarmSound()
            self.currentActivity = nil
        }
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    // MARK: - Alarm Sound Management
    
    private func startAlarmSound() {
        // Configure audio session for critical alarm sound
        configureAudioSession()
        
        // First try to play custom alarm sound
        if let soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "caf") {
            playCustomAlarmSound(url: soundURL)
        } else {
            // Fallback to system sound pattern
            playSystemAlarmPattern()
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func playCustomAlarmSound(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
            
            // Set up timer to ensure sound continues playing
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if self.currentActivity == nil {
                    timer.invalidate()
                    return
                }
                
                if let player = self.audioPlayer, !player.isPlaying {
                    player.play()
                }
            }
            
        } catch {
            print("Failed to play custom alarm sound: \(error)")
            playSystemAlarmPattern()
        }
    }
    
    private func playSystemAlarmPattern() {
        // Create a repeating pattern using system sounds
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if self.currentActivity == nil {
                timer.invalidate()
                return
            }
            
            // Play system alarm sound
            AudioServicesPlaySystemSound(1005) // Long beep
            
            // Add slight delay then play again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.currentActivity != nil {
                    AudioServicesPlaySystemSound(1005)
                }
            }
        }
        
        // Store timer reference so we can invalidate it later
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func stopAlarmSound() {
        // Stop custom audio player
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Stop system sounds
        AudioServicesDisposeSystemSoundID(1005)
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // Check if Live Activities are supported
    func isSupported() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // Request permission for Live Activities if needed
    func requestPermission() async -> Bool {
        let authInfo = ActivityAuthorizationInfo()
        return authInfo.areActivitiesEnabled
    }
}
#endif
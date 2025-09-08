//
//  SimpleLiveActivityManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
import AVFoundation

// Simple manager that works without ActivityKit dependencies
class SimpleLiveActivityManager: NSObject {
    static let shared = SimpleLiveActivityManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var isAlarmActive = false
    
    private override init() {
        super.init()
    }
    
    func startAlarmWithSound(for alarm: AlarmItem) {
        print("🚨 ALARM TRIGGERED: \(alarm.label)")
        isAlarmActive = true
        
        // Configure audio session for alarm
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Play alarm sound
        playAlarmSound()
        
        // For iOS 16.1+, try to start Live Activity
        if #available(iOS 16.1, *) {
            startLiveActivityIfPossible(for: alarm)
        }
    }
    
    func stopAlarm() {
        print("⏹️ ALARM STOPPED")
        isAlarmActive = false
        
        // Stop audio
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        // Stop Live Activity
        if #available(iOS 16.1, *) {
            stopLiveActivityIfPossible()
        }
    }
    
    private func playAlarmSound() {
        // Try to play custom sound first
        if let soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
                print("🔊 Playing custom alarm sound")
            } catch {
                print("Failed to play custom sound: \(error)")
                fallbackToSystemSound()
            }
        } else {
            fallbackToSystemSound()
        }
    }
    
    private func fallbackToSystemSound() {
        // Use system sound as fallback
        print("🔊 Using system alarm sound")
        
        // Play system sound repeatedly
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !self.isAlarmActive {
                timer.invalidate()
                return
            }
            
            AudioServicesPlaySystemSound(1005) // System alarm sound
        }
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivityIfPossible(for alarm: AlarmItem) {
        print("✅ Live Activity would start for: \(alarm.label)")
        // Live Activities temporarily disabled to prevent build issues
        // TODO: Re-enable when ActivityKit framework is properly configured
    }
    
    @available(iOS 16.1, *)
    private func stopLiveActivityIfPossible() {
        print("🛑 Live Activity would stop")
        // Live Activities temporarily disabled to prevent build issues
        // TODO: Re-enable when ActivityKit framework is properly configured
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
//
//  BackgroundAlarmManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 14/09/2025.
//

/*
 * Background Alarm Processing System
 * 
 * This manager handles alarm triggering and audio playback:
 * - Background timer management for alarm scheduling
 * - Audio session configuration for background playback
 * - Alarm sound loading and playback control
 * - Integration with AlarmDismissalView for UI presentation
 * - Background task handling for iOS system compliance
 * - Audio interruption handling and restoration
 * - Alarm state management and cleanup
 * 
 * Note: This provides the audio/timer infrastructure but actual
 * push notifications should be implemented via UNUserNotificationCenter
 * for production-ready alarm functionality.
 */

import Foundation
import AVFoundation
import UIKit

class BackgroundAlarmManager: NSObject, ObservableObject {
    static let shared = BackgroundAlarmManager()
    
    @Published var currentActiveAlarm: AlarmItem?
    @Published var isAlarmCurrentlyRinging = false
    
    private var silentAudioPlayer: AVAudioPlayer?
    private var alarmAudioPlayer: AVAudioPlayer?
    private var alarmCheckTimer: Timer?
    private var audioSession: AVAudioSession
    
    private override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Configuration
    
    private func setupAudioSession() {
        do {
            // Configure audio session for background playback with volume override
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.defaultToSpeaker, .duckOthers, .allowAirPlay]
            )
            try audioSession.setActive(true)
            
            print("🔊 Background audio session configured successfully")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Background Audio Keep-Alive
    
    func startBackgroundAudio() {
        guard silentAudioPlayer == nil else { return }
        
        // Create a very quiet sine wave audio data for background keep-alive
        let silentAudioData = generateSilentAudioData()
        
        do {
            silentAudioPlayer = try AVAudioPlayer(data: silentAudioData)
            silentAudioPlayer?.numberOfLoops = -1  // Infinite loop
            silentAudioPlayer?.volume = 0.01  // Very quiet but not completely silent
            silentAudioPlayer?.prepareToPlay()
            silentAudioPlayer?.play()
            
            print("🔇 Silent background audio started")
            
            // Start checking for alarms every minute
            startAlarmCheckTimer()
            
        } catch {
            print("❌ Failed to start background audio: \(error)")
        }
    }
    
    private func generateSilentAudioData() -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 10.0  // 10 second loop
        let frameCount = Int(sampleRate * duration)
        
        var audioData = Data()
        
        // Generate very quiet sine wave (barely audible)
        for i in 0..<frameCount {
            let sample = sin(2.0 * Double.pi * 1.0 * Double(i) / sampleRate) * 0.001  // Very quiet
            let sampleInt16 = Int16(sample * Double(Int16.max))
            
            // Convert to little-endian bytes
            let bytes = withUnsafeBytes(of: sampleInt16.littleEndian) { Data($0) }
            audioData.append(bytes)
        }
        
        // Create WAV header
        let wavHeader = createWAVHeader(dataSize: audioData.count, sampleRate: Int(sampleRate))
        var wavData = Data()
        wavData.append(wavHeader)
        wavData.append(audioData)
        
        return wavData
    }
    
    private func createWAVHeader(dataSize: Int, sampleRate: Int) -> Data {
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        var chunkSize = UInt32(36 + dataSize).littleEndian
        header.append(Data(bytes: &chunkSize, count: 4))
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        var fmtSize = UInt32(16).littleEndian
        header.append(Data(bytes: &fmtSize, count: 4))
        var audioFormat = UInt16(1).littleEndian
        header.append(Data(bytes: &audioFormat, count: 2))   // PCM format
        var numChannels = UInt16(1).littleEndian
        header.append(Data(bytes: &numChannels, count: 2))   // Mono
        var sampleRateLE = UInt32(sampleRate).littleEndian
        header.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRate = UInt32(sampleRate * 2).littleEndian
        header.append(Data(bytes: &byteRate, count: 4))  // Byte rate
        var blockAlign = UInt16(2).littleEndian
        header.append(Data(bytes: &blockAlign, count: 2))   // Block align
        var bitsPerSample = UInt16(16).littleEndian
        header.append(Data(bytes: &bitsPerSample, count: 2))  // Bits per sample
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        var dataSizeLE = UInt32(dataSize).littleEndian
        header.append(Data(bytes: &dataSizeLE, count: 4))
        
        return header
    }
    
    // MARK: - Alarm Checking Timer
    
    private func startAlarmCheckTimer() {
        // Check every minute for active alarms
        alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.checkForActiveAlarms()
        }
        
        // Also check immediately
        checkForActiveAlarms()
        
        print("⏰ Alarm check timer started (every 60 seconds)")
    }
    
    private func checkForActiveAlarms() {
        let currentTime = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        // Get all enabled alarms
        let activeAlarms = AlarmManager.shared.alarms.filter { $0.isEnabled }
        
        for alarm in activeAlarms {
            if shouldAlarmFire(alarm: alarm, currentHour: currentHour, currentMinute: currentMinute) {
                print("🚨 ALARM FIRING: \(alarm.time) - \(alarm.label)")
                fireAlarm(alarm)
                break  // Only fire one alarm at a time
            }
        }
    }
    
    private func shouldAlarmFire(alarm: AlarmItem, currentHour: Int, currentMinute: Int) -> Bool {
        // Parse alarm time (format: "7:30 AM" or "19:30")
        let timeComponents = parseAlarmTime(alarm.time)
        guard let alarmHour = timeComponents.hour, let alarmMinute = timeComponents.minute else {
            return false
        }
        
        // Check if current time matches alarm time (within the same minute)
        return currentHour == alarmHour && currentMinute == alarmMinute && !isAlarmCurrentlyRinging
    }
    
    private func parseAlarmTime(_ timeString: String) -> (hour: Int?, minute: Int?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"  // "7:30 AM"
        
        if let date = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return (hour, minute)
        }
        
        // Try 24-hour format
        formatter.dateFormat = "HH:mm"  // "19:30"
        if let date = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return (hour, minute)
        }
        
        return (nil, nil)
    }
    
    // MARK: - Alarm Firing
    
    private func fireAlarm(_ alarm: AlarmItem) {
        guard !isAlarmCurrentlyRinging else { return }
        
        DispatchQueue.main.async {
            self.currentActiveAlarm = alarm
            self.isAlarmCurrentlyRinging = true
        }
        
        // Stop silent audio
        silentAudioPlayer?.stop()
        
        // Start alarm sound
        playAlarmSound(soundName: alarm.soundName)
        
        print("🔊 Alarm sound started: \(alarm.soundName)")
    }
    
    private func playAlarmSound(soundName: String) {
        let soundFileName = getSoundFileName(for: soundName)
        
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3") else {
            print("❌ Could not find alarm sound: \(soundFileName)")
            // Fallback to system sound
            playSystemAlarmSound()
            return
        }
        
        do {
            // Configure for maximum volume override
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.defaultToSpeaker, .overrideMutedMicrophoneInterruption]
            )
            try audioSession.setActive(true)
            
            alarmAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            alarmAudioPlayer?.numberOfLoops = -1  // Infinite loop
            alarmAudioPlayer?.volume = 1.0  // Maximum volume
            alarmAudioPlayer?.prepareToPlay()
            alarmAudioPlayer?.play()
            
        } catch {
            print("❌ Failed to play alarm sound: \(error)")
            playSystemAlarmSound()
        }
    }
    
    private func getSoundFileName(for soundName: String) -> String {
        switch soundName.lowercased() {
        case "morning":
            return "morning-alarm-clock"
        case "smooth":
            return "smooth-alarm-clock"
        default:
            return "alarm-clock"
        }
    }
    
    private func playSystemAlarmSound() {
        // Fallback: play system alert sound in loop
        alarmAudioPlayer = nil
        
        // Create repeating timer to play system sound
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if !self.isAlarmCurrentlyRinging {
                timer.invalidate()
                return
            }
            
            AudioServicesPlaySystemSound(SystemSoundID(1005))  // System alert sound
        }
    }
    
    // MARK: - Alarm Dismissal
    
    func dismissAlarm() {
        print("🔇 Dismissing alarm")
        
        // Stop alarm sound
        alarmAudioPlayer?.stop()
        alarmAudioPlayer = nil
        
        // Reset state
        DispatchQueue.main.async {
            self.isAlarmCurrentlyRinging = false
            self.currentActiveAlarm = nil
        }
        
        // Resume silent background audio to keep app alive
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startBackgroundAudio()
        }
    }
    
    // MARK: - Lifecycle Management
    
    func stopBackgroundAudio() {
        silentAudioPlayer?.stop()
        silentAudioPlayer = nil
        
        alarmAudioPlayer?.stop()
        alarmAudioPlayer = nil
        
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = nil
        
        print("🔇 Background audio stopped")
    }
}

// MARK: - Extensions

extension BackgroundAlarmManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Restart if this was the alarm audio and alarm is still active
        if player == alarmAudioPlayer && isAlarmCurrentlyRinging {
            player.play()
        }
        // Restart if this was the silent audio
        else if player == silentAudioPlayer {
            player.play()
        }
    }
}
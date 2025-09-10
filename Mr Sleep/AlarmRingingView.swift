//
//  AlarmRingingView.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import SwiftUI
import AVFoundation

struct AlarmRingingView: View {
    let alarm: AlarmItem
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var currentTime = Date()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var soundTimer: Timer?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background like your reference image
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.7, blue: 0.9),
                        Color(red: 0.2, green: 0.5, blue: 0.8),
                        Color(red: 0.1, green: 0.3, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Current time display - exactly like the reference image
                    VStack(spacing: 8) {
                        Text(DateFormatter.dayFormatter.string(from: currentTime))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(DateFormatter.timeFormatter.string(from: currentTime))
                            .font(.system(size: 80, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(.bottom, 100)
                    
                    // Alarm info card (like your reference image)
                    VStack(spacing: 16) {
                        // Header with alarm icon and label
                        HStack {
                            Image(systemName: "alarm.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            
                            Text("Alarmy")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(alarm.time) Alarm")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Main alarm message
                        HStack {
                            Text("💗")
                                .font(.title2)
                            
                            Text("It's Monday afternoon")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        // Dismiss button (exactly matching reference design)
                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.9, green: 0.3, blue: 0.3),
                                                    Color(red: 0.8, green: 0.2, blue: 0.2)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(isAnimating ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            print("🚨 AlarmRingingView appeared - starting alarm experience")
            isAnimating = true
            
            // Add slight delay to ensure view is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Sound is now handled by AlarmManager, not here
                startHapticFeedback()
            }
        }
        .onDisappear {
            // Sound is handled by AlarmManager, not here
        }
    }
    
    private func startAlarmSound() {
        print("🔊 Starting alarm sound for: \(alarm.soundName)")
        
        // Configure audio session for alarm - must work when locked
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use playback category with options to continue playing when locked
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            print("✅ Audio session configured for background playback")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
        
        // Try to play the alarm sound based on user's selection
        var soundURL: URL?
        let selectedSound = alarm.soundName.lowercased()
        
        // Check for specific sound files based on user selection
        if selectedSound == "pulse" {
            // For pulse, use a system-generated repeating pulse sound
            print("🔊 Using pulse sound pattern")
            playPulseAlarmSound()
            return
        } else if selectedSound.contains("morning") || selectedSound == "morning" {
            // Check for morning-alarm-clock sound file
            soundURL = Bundle.main.url(forResource: "morning-alarm-clock", withExtension: "mp3") ??
                      Bundle.main.url(forResource: "morning-alarm-clock", withExtension: "wav") ??
                      Bundle.main.url(forResource: "morning-alarm-clock", withExtension: "m4a")
        } else if selectedSound.contains("smooth") || selectedSound == "smooth" {
            // Check for smooth-alarm-clock sound file
            soundURL = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3") ??
                      Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "wav") ??
                      Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "m4a")
        } else if selectedSound.contains("classic") || selectedSound.contains("alarm-clock") {
            // Check for classic alarm-clock sound file
            soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                      Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                      Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a")
        }
        
        if let url = soundURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely until dismissed
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                
                let success = audioPlayer?.play() ?? false
                if success {
                    print("🔊 SUCCESS: Playing continuous \(alarm.soundName) sound with looping")
                } else {
                    print("❌ FAILED: Could not start audio playback")
                    playDefaultAlarmSound()
                }
            } catch {
                print("❌ Failed to create audio player for \(alarm.soundName): \(error)")
                playDefaultAlarmSound()
            }
        } else {
            print("No \(alarm.soundName) sound file found, trying default sounds")
            playDefaultAlarmSound()
        }
    }
    
    private func playDefaultAlarmSound() {
        print("🔄 Trying default alarm sounds...")
        
        // Try morning sound first, then smooth, then classic, then pulse pattern
        if let url = Bundle.main.url(forResource: "morning-alarm-clock", withExtension: "mp3") {
            print("📁 Found morning-alarm-clock.mp3, attempting to play...")
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                
                let success = audioPlayer?.play() ?? false
                if success {
                    print("🔊 SUCCESS: Playing default morning alarm sound with looping")
                    return
                } else {
                    print("❌ FAILED: Could not start morning alarm playback")
                }
            } catch {
                print("❌ Failed to create morning alarm player: \(error)")
            }
        } else {
            print("📁 morning-alarm-clock.mp3 not found in bundle")
        }
        
        if let url = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3") {
            print("📁 Found smooth-alarm-clock.mp3, attempting to play...")
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                
                let success = audioPlayer?.play() ?? false
                if success {
                    print("🔊 SUCCESS: Playing fallback smooth alarm sound with looping")
                    return
                } else {
                    print("❌ FAILED: Could not start smooth alarm playback")
                }
            } catch {
                print("❌ Failed to create smooth alarm player: \(error)")
            }
        } else {
            print("📁 smooth-alarm-clock.mp3 not found in bundle")
        }
        
        if let url = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") {
            print("📁 Found alarm-clock.mp3, attempting to play...")
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                
                let success = audioPlayer?.play() ?? false
                if success {
                    print("🔊 SUCCESS: Playing classic alarm sound with looping")
                    return
                } else {
                    print("❌ FAILED: Could not start classic alarm playback")
                }
            } catch {
                print("❌ Failed to create classic alarm player: \(error)")
            }
        } else {
            print("📁 alarm-clock.mp3 not found in bundle")
        }
        
        // Final fallback to pulse pattern
        print("🔊 No alarm sound files found, using pulse pattern as final fallback")
        playPulseAlarmSound()
    }
    
    private func playPulseAlarmSound() {
        print("🔊 Starting pulse alarm sound pattern as fallback...")
        
        // Create a repeating pulse sound pattern using system sounds
        soundTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            // Play pulse sound - using a sharper, more alarm-like sound
            AudioServicesPlaySystemSound(1005) // Critical alert sound
            print("🔊 Playing pulse beep")
        }
        print("🔊 SUCCESS: Started pulse alarm sound pattern (0.6s intervals)")
    }
    
    private func playSystemAlarmSound() {
        // Fallback to system sound pattern
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard audioPlayer?.isPlaying != true else {
                timer.invalidate()
                return
            }
            AudioServicesPlaySystemSound(1005) // System alarm sound
        }
    }
    
    private func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Stop any sound timers
        soundTimer?.invalidate()
        soundTimer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        print("🔇 Stopped alarm sound")
    }
    
    private func startHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard audioPlayer?.isPlaying == true else {
                timer.invalidate()
                return
            }
            
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Alarm Dismissal View
struct AlarmDismissalView: View {
    let alarm: AlarmItem
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient matching the reference image
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.7, blue: 0.9),
                        Color(red: 0.2, green: 0.5, blue: 0.8),
                        Color(red: 0.1, green: 0.3, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Current time display - exactly like the reference image
                    VStack(spacing: 8) {
                        Text(DateFormatter.dayFormatter.string(from: currentTime))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(DateFormatter.timeFormatter.string(from: currentTime))
                            .font(.system(size: 80, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(.bottom, 100)
                    
                    Spacer()
                    
                    // Dismiss button (exactly matching reference design)
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.9, green: 0.3, blue: 0.3),
                                                Color(red: 0.8, green: 0.2, blue: 0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isAnimating ? 1.03 : 1.0)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isAnimating)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            print("🚨 AlarmDismissalView appeared - alarm music should be playing")
            isAnimating = true
        }
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()
}
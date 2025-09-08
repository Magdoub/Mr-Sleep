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
    let onSnooze: () -> Void
    
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
                    
                    // Current time display
                    VStack(spacing: 8) {
                        Text(DateFormatter.dayFormatter.string(from: currentTime))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(DateFormatter.timeFormatter.string(from: currentTime))
                            .font(.system(size: 72, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(.bottom, 60)
                    
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
                        
                        // Dismiss button (matching your reference design)
                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                        
                        // Snooze option
                        Button(action: onSnooze) {
                            Text("Snooze (9 min)")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
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
            isAnimating = true
            startAlarmSound()
            startHapticFeedback()
        }
        .onDisappear {
            stopAlarmSound()
        }
    }
    
    private func startAlarmSound() {
        // Configure audio session for alarm
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
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
                audioPlayer?.play()
                print("🔊 Playing continuous \(alarm.soundName) sound")
            } catch {
                print("Failed to play \(alarm.soundName) sound: \(error)")
                playDefaultAlarmSound()
            }
        } else {
            print("No \(alarm.soundName) sound file found, trying default sounds")
            playDefaultAlarmSound()
        }
    }
    
    private func playDefaultAlarmSound() {
        // Try smooth sound first, then classic, then pulse pattern
        if let url = Bundle.main.url(forResource: "smooth-alarm-clock", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
                print("🔊 Playing default smooth alarm sound")
                return
            } catch {
                print("Failed to play smooth alarm sound: \(error)")
            }
        }
        
        if let url = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
                print("🔊 Playing classic alarm sound")
                return
            } catch {
                print("Failed to play classic alarm sound: \(error)")
            }
        }
        
        // Final fallback to pulse pattern
        print("🔊 No alarm sound files found, using pulse pattern")
        playPulseAlarmSound()
    }
    
    private func playPulseAlarmSound() {
        // Create a repeating pulse sound pattern using system sounds
        soundTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            // Play pulse sound - using a sharper, more alarm-like sound
            AudioServicesPlaySystemSound(1005) // Critical alert sound
        }
        print("🔊 Started pulse alarm sound pattern (0.6s intervals)")
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
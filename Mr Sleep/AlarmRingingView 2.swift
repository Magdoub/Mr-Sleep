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
            // UI-only overlay; sound is managed centrally by AlarmManager
            isAnimating = true
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
        
        // Try to play custom alarm sound
        if let soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                         Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = 19 // Play up to 20 times total
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
                print("🔊 Playing alarm sound")
            } catch {
                print("Failed to play custom sound: \(error)")
                playSystemAlarmSound()
            }
        } else {
            playSystemAlarmSound()
        }
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
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
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

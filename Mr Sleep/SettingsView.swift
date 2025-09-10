//
//  SettingsView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var sleepCycleDuration: Double = 90
    @State private var fallAsleepTime: Double = 15
    @State private var notificationsEnabled: Bool = true
    @State private var hapticFeedback: Bool = true
    @State private var darkMode: Bool = true
    @StateObject private var alarmManager = AlarmManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.25, blue: 0.5),
                        Color(red: 0.06, green: 0.15, blue: 0.35),
                        Color(red: 0.03, green: 0.08, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text("Settings")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Enhanced Alarm Testing
                        #if DEBUG
                        SettingsSectionView(title: "🧪 Test Enhanced Alarms", icon: "bell.fill") {
                            VStack(spacing: 12) {
                                Button("🚨 Test Enhanced Alarm") {
                                    testEnhancedAlarm()
                                }
                                .buttonStyle(TestButtonStyle(color: .red))
                                
                                Text("⚠️ This will send one test notification in 3 seconds")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 20)
                        #endif
                    
                    // Sleep Settings Section
                    SettingsSectionView(title: "Sleep Settings", icon: "moon.fill") {
                        VStack(spacing: 16) {
                            SettingsSliderView(
                                title: "Sleep Cycle Duration",
                                subtitle: "\(Int(sleepCycleDuration)) minutes",
                                value: $sleepCycleDuration,
                                range: 60...120,
                                step: 5
                            )
                            
                            SettingsSliderView(
                                title: "Fall Asleep Time",
                                subtitle: "\(Int(fallAsleepTime)) minutes",
                                value: $fallAsleepTime,
                                range: 5...30,
                                step: 5
                            )
                        }
                    }
                    
                    // Notification Settings Section
                    SettingsSectionView(title: "Notifications", icon: "bell.fill") {
                        VStack(spacing: 16) {
                            SettingsToggleView(
                                title: "Push Notifications",
                                subtitle: "Receive bedtime reminders",
                                isOn: $notificationsEnabled
                            )
                            
                            SettingsToggleView(
                                title: "Haptic Feedback",
                                subtitle: "Feel vibrations for interactions",
                                isOn: $hapticFeedback
                            )
                        }
                    }
                    
                    // Appearance Settings Section
                    SettingsSectionView(title: "Appearance", icon: "paintbrush.fill") {
                        VStack(spacing: 16) {
                            SettingsToggleView(
                                title: "Dark Mode",
                                subtitle: "Use dark theme throughout the app",
                                isOn: $darkMode
                            )
                        }
                    }
                    
                    // About Section
                    SettingsSectionView(title: "About", icon: "info.circle.fill") {
                        VStack(spacing: 16) {
                            SettingsInfoView(
                                title: "Version",
                                value: "3.0"
                            )
                            
                            SettingsInfoView(
                                title: "Build",
                                value: "2"
                            )
                            
                            Button(action: {
                                // Rate app action
                            }) {
                                HStack {
                                    Text("Rate Mr Sleep")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                                }
                                .padding(.vertical, 12)
                            }
                            
                            Button(action: {
                                // Share app action
                            }) {
                                HStack {
                                    Text("Share App")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                                }
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct SettingsSliderView: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                
                Spacer()
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(Color(red: 0.894, green: 0.729, blue: 0.306))
        }
    }
}

struct SettingsToggleView: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.894, green: 0.729, blue: 0.306)))
        }
    }
}

struct SettingsInfoView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}

extension SettingsView {
    // MARK: - Enhanced Alarm Testing Functions
    #if DEBUG
    private func testEnhancedAlarm() {
        // Create a test alarm that fires in 3 seconds
        let testAlarm = AlarmItem(
            time: "Test Alarm",
            isEnabled: true,
            label: "💗 Enhanced Test Alarm",
            category: "Test",
            cycles: 5,
            createdFromSleepNow: true,
            soundName: "Smooth",
            shouldAutoReset: false
        )
        
        // Schedule immediate test notification
        let content = UNMutableNotificationContent()
        content.title = "🚨 TEST ALARM 🚨"
        content.subtitle = "💗 Smooth Test"
        content.body = "Tap to test full-screen alarm with smooth sound!"
        // Use the same alarm sound that regular alarms use (prefer smooth)
        if Bundle.main.path(forResource: "smooth-alarm-clock", ofType: "mp3") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "smooth-alarm-clock.mp3"))
            print("🧪 Test using smooth-alarm-clock.mp3 for notification sound")
        } else if Bundle.main.path(forResource: "alarm-clock", ofType: "mp3") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm-clock.mp3"))
            print("🧪 Test using alarm-clock.mp3 for notification sound")
        } else {
            content.sound = .defaultCritical
            print("🧪 Test using defaultCritical notification sound")
        }
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        content.badge = 1
        
        // Add test alarm info for full-screen experience
        content.userInfo = [
            "isAlarm": true,
            "alarmId": testAlarm.id.uuidString,
            "alarmTime": testAlarm.time,
            "alarmLabel": testAlarm.label
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: testAlarm.id.uuidString, content: content, trigger: trigger)
        
        // Temporarily add test alarm to AlarmManager so it can be found when notification fires
        alarmManager.addTestAlarm(testAlarm)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test alarm: \(error)")
            } else {
                print("🧪 Test alarm scheduled for 3 seconds from now")
            }
        }
    }
    #endif
}

// MARK: - Test Button Style
struct TestButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


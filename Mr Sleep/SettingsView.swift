//
//  SettingsView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var sleepCycleDuration: Double = 90
    @State private var fallAsleepTime: Double = 15
    @State private var notificationsEnabled: Bool = true
    @State private var hapticFeedback: Bool = true
    @State private var darkMode: Bool = true
    
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
                        
                        // Developer Testing Section (remove after testing)
                        #if DEBUG
                        SettingsSectionView(title: "Live Activity Testing", icon: "bell.fill") {
                            VStack(spacing: 16) {
                                Button("🚨 Test Live Activity") {
                                    Task { @MainActor in
                                        LiveActivityTestHelper.createTestAlarmActivity()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                
                                Button("❌ Stop Live Activity") {
                                    Task { @MainActor in
                                        LiveActivityTestHelper.endTestActivity()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                
                                Text("⚠️ Test buttons - remove before release")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
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


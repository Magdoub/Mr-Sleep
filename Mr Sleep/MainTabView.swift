//
//  MainTabView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

// Simple alarm overlay manager for creation flow
class AlarmOverlayManager: ObservableObject {
    static let shared = AlarmOverlayManager()
    
    @Published var isShowingAlarm = false
    @Published var currentAlarm: AlarmItem?
    
    private init() {}
    
    func showAlarmCreation(for alarm: AlarmItem) {
        currentAlarm = alarm
        isShowingAlarm = true
    }
    
    func dismissAlarm() {
        isShowingAlarm = false
        currentAlarm = nil
    }
}

// Simple alarm creation view
struct AlarmCreationView: View {
    let alarm: AlarmItem
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                Text("Create Alarm?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(alarm.time)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                
                Text(alarm.label)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                    
                    Button("Create Alarm") {
                        onConfirm()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.894, green: 0.729, blue: 0.306))
                    .cornerRadius(25)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.25, blue: 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var tabBarOffset: CGFloat = 0
    @State private var showTabBarAnimation = false
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var alarmOverlayManager = AlarmOverlayManager.shared
    
    var body: some View {
        Group {
            if showOnboarding {
                // Show only SleepNowView during onboarding (no tab bar)
                SleepNowView(alarmManager: alarmManager, selectedTab: $selectedTab)
            } else {
                // Show full TabView
                TabView(selection: $selectedTab) {
                    SleepNowView(alarmManager: alarmManager, selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: selectedTab == 0 ? "bed.double.fill" : "bed.double")
                            Text("Sleep Now")
                        }
                        .tag(0)
                    
                    AlarmsView(alarmManager: alarmManager)
                        .tabItem {
                            Image(systemName: selectedTab == 1 ? "alarm.fill" : "alarm")
                            Text("Alarms")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                            Text("Settings")
                        }
                        .tag(2)
                }
                .accentColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                .offset(y: showTabBarAnimation ? 0 : tabBarOffset)
                .animation(.easeOut(duration: 0.6), value: showTabBarAnimation)
            }
        }
        .overlay(
            // Alarm creation overlay
            Group {
                if alarmOverlayManager.isShowingAlarm, let alarm = alarmOverlayManager.currentAlarm {
                    AlarmCreationView(
                        alarm: alarm,
                        onConfirm: {
                            // Add the alarm and switch to alarms tab
                            alarmManager.addAlarm(
                                time: alarm.time,
                                category: alarm.category,
                                cycles: alarm.cycles
                            )
                            alarmOverlayManager.dismissAlarm()
                            selectedTab = 1 // Switch to Alarms tab
                        },
                        onDismiss: {
                            alarmOverlayManager.dismissAlarm()
                        }
                    )
                }
            }
        )
        .onChange(of: showOnboarding) { isOnboarding in
            showOnboarding = isOnboarding
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            showOnboarding = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if !showOnboarding {
                showTabBarAnimation = false
                tabBarOffset = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if !showOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showTabBarAnimation = true
                }
            }
        }
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.03, green: 0.08, blue: 0.2, alpha: 0.95)
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
            ]
            appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 8)
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.894, green: 0.729, blue: 0.306, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.894, green: 0.729, blue: 0.306, alpha: 1.0)
            ]
            appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 8)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Set standard tab bar height
            UITabBar.appearance().frame.size.height = 83
            
            // Trigger slide-up animation after a short delay
            if !showOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showTabBarAnimation = true
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AlarmManager.shared)
}
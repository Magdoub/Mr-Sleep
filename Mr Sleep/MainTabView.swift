//
//  MainTabView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var tabBarOffset: CGFloat = 0
    @State private var showTabBarAnimation = false
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var alarmOverlayManager = AlarmOverlayManager.shared
    @ObservedObject private var alarmDismissalManager = AlarmDismissalManager.shared
    
    var body: some View {
        Group {
            if showOnboarding {
                // Show only SleepNowView during onboarding (no tab bar)
                SleepNowView(alarmManager: alarmManager, selectedTab: $selectedTab)
            } else {
                // Show full TabView after onboarding
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
        .fullScreenCover(isPresented: $alarmOverlayManager.isShowingAlarm) {
            if let alarm = alarmOverlayManager.currentAlarm {
                AlarmRingingView(
                    alarm: alarm,
                    onDismiss: {
                        // Dismiss through AlarmManager to stop sound properly
                        alarmManager.dismissLiveActivity(for: alarm.id.uuidString)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $alarmDismissalManager.isShowingDismissalPage) {
            if let alarm = alarmDismissalManager.currentAlarm {
                AlarmDismissalView(
                    alarm: alarm,
                    onDismiss: {
                        print("🔔 DEBUG: AlarmDismissalView onDismiss called")
                        // Stop sound, remove notifications, delete alarm
                        alarmManager.dismissAlarmCompletely(alarm)
                        alarmDismissalManager.dismissAlarm()
                    }
                )
                .onAppear {
                    print("🔔 DEBUG: fullScreenCover showing AlarmDismissalView for alarm: \(alarm.label)")
                }
            } else {
                // This should not happen but let's log it
                Text("No alarm data")
                    .onAppear {
                        print("🔔 DEBUG: fullScreenCover triggered but no alarm data!")
                    }
            }
        }
        .onChange(of: alarmDismissalManager.isShowingDismissalPage) { isShowing in
            print("🔔 DEBUG: MainTabView detected isShowingDismissalPage changed to: \(isShowing)")
            if isShowing {
                print("🔔 DEBUG: MainTabView should show fullScreenCover now")
            }
        }
        .onChange(of: alarmDismissalManager.currentAlarm) { alarm in
            print("🔔 DEBUG: MainTabView detected currentAlarm changed to: \(alarm?.label ?? "nil")")
        }
        .onChange(of: showOnboarding) { isOnboarding in
            // Update onboarding state when it changes
            showOnboarding = isOnboarding
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            // Update showOnboarding state when onboarding is completed
            showOnboarding = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Reset animation state when app comes from background
            if !showOnboarding {
                showTabBarAnimation = false
                tabBarOffset = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Trigger slide-up animation when app becomes active
            if !showOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showTabBarAnimation = true
                }
            }
            
            // Handle app lifecycle in alarm manager
            alarmManager.handleAppBecameActive()
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

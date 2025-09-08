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
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var alarmOverlayManager = AlarmOverlayManager.shared
    
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
            }
        }
        .fullScreenCover(isPresented: $alarmOverlayManager.isShowingAlarm) {
            if let alarm = alarmOverlayManager.currentAlarm {
                AlarmRingingView(
                    alarm: alarm,
                    onDismiss: {
                        alarmOverlayManager.dismissAlarm()
                    }
                )
            }
        }
        .onChange(of: showOnboarding) { isOnboarding in
            // Update onboarding state when it changes
            showOnboarding = isOnboarding
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
            
            // Increase the height of the tab bar for more top padding
            UITabBar.appearance().frame.size.height = 140
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AlarmManager())
}

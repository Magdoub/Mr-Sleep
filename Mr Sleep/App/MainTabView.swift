//
//  MainTabView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

/*
 * Main Tab Navigation Container
 * 
 * This file provides the primary navigation structure for the app:
 * - Three-tab navigation: Sleep Now, AlarmKit, Settings
 * - Onboarding flow management for first-time users
 * - Tab bar appearance customization with dark theme
 * - Smooth animation handling for tab transitions
 */

import SwiftUI
import AlarmKit



struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var tabBarOffset: CGFloat = 0
    @State private var showTabBarAnimation = false
    @State private var alarmViewModel = AlarmKitViewModel()
    
    var body: some View {
        Group {
            if showOnboarding {
                // Show only SleepNowView during onboarding (no tab bar)
                SleepNowView(selectedTab: $selectedTab)
                    .environment(alarmViewModel)
            } else {
                // Show full TabView
                TabView(selection: $selectedTab) {
                    SleepNowView(selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: selectedTab == 0 ? "bed.double.fill" : "bed.double")
                            Text("Sleep Now")
                        }
                        .tag(0)
                    
                    AlarmKitView()
                        .tabItem {
                            Image(systemName: selectedTab == 1 ? "alarm.waves.left.and.right.fill" : "alarm.waves.left.and.right")
                            Text("Alarms")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                            Text("Settings")
                        }
                        .tag(2)
                    
                    SingleAlarmView()
                        .tabItem {
                            Image(systemName: selectedTab == 3 ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                            Text("Single")
                        }
                        .tag(3)
                }
                .environment(alarmViewModel)
                .accentColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                .onAppear {
                    // Configure tab bar appearance for iOS 26
                    let tabBarAppearance = UITabBarAppearance()
                    tabBarAppearance.configureWithOpaqueBackground()
                    
                    // Set background colors
                    tabBarAppearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.95)
                    
                    // Configure normal state
                    tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.6, alpha: 1.0)
                    tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                        .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                        .font: UIFont.systemFont(ofSize: 11, weight: .medium)
                    ]
                    
                    // Configure selected state
                    tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.894, green: 0.729, blue: 0.306, alpha: 1.0)
                    tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                        .foregroundColor: UIColor(red: 0.894, green: 0.729, blue: 0.306, alpha: 1.0),
                        .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
                    ]
                    
                    // Apply appearance
                    UITabBar.appearance().standardAppearance = tabBarAppearance
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                    
                    // Add extra bottom padding for iOS 26
                    UITabBar.appearance().itemPositioning = .centered
                    UITabBar.appearance().itemSpacing = 8
                }
                .offset(y: showTabBarAnimation ? 0 : tabBarOffset)
                .animation(.easeOut(duration: 0.6), value: showTabBarAnimation)
            }
        }
        .onChange(of: showOnboarding) { _, isOnboarding in
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
}
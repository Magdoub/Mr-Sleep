//
//  MainTabView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SleepNowView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "bed.double.fill" : "bed.double")
                    Text("Sleep Now")
                }
                .tag(0)
            
            AlarmsView()
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
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.894, green: 0.729, blue: 0.306, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.894, green: 0.729, blue: 0.306, alpha: 1.0)
            ]
            
            // Increase padding for tab bar items
            appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 12)
            appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 12)
            
            // Add more padding to the tab bar itself
            appearance.stackedLayoutAppearance.normal.iconPositionAdjustment = UIOffset(horizontal: 0, vertical: 8)
            appearance.stackedLayoutAppearance.selected.iconPositionAdjustment = UIOffset(horizontal: 0, vertical: 8)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Increase the height of the tab bar
            UITabBar.appearance().frame.size.height = 100
        }
    }
}

#Preview {
    MainTabView()
}

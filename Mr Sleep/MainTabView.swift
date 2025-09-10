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
    @State private var tabBarOffset: CGFloat = 100
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
                        // Dismiss the alarm properly
                        alarmManager.dismissLiveActivity(for: alarm.id.uuidString)
                        alarmDismissalManager.dismissAlarm()
                    }
                )
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
                tabBarOffset = 100
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
            
            // Increase the height of the tab bar for more top padding
            UITabBar.appearance().frame.size.height = 140
            
            // Trigger slide-up animation after a short delay
            if !showOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showTabBarAnimation = true
                }
            }
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
                        Text(currentTimeDay)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(currentTimeString)
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
            print("🚨 AlarmDismissalView appeared - alarm should continue until dismissed")
            isAnimating = true
        }
    }
    
    private var currentTimeDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AlarmManager.shared)
}

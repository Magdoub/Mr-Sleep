//
//  Mr_SleepApp.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI
import StoreKit
import ActivityKit
import WidgetKit
import AVFoundation

@main
struct Mr_SleepApp: App {
    @StateObject private var alarmManager = AlarmManager.shared
    
    init() {
        // Configure audio session for background audio capability on app launch
        configureBackgroundAudio()
        
        // Set notification delegate immediately to ensure it's available for all notifications
        UNUserNotificationCenter.current().delegate = AlarmManager.shared
        print("🔔 DEBUG: Notification delegate set in app init")
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // Use MainTabView to show the bottom tab bar
                .preferredColorScheme(.dark)
                .environmentObject(alarmManager)
                .onAppear {
                    incrementLaunchCount()
                    setupLiveActivities()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleAppWillEnterForeground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    handleAppDidEnterBackground()
                }
        }
    }
    
    private func setupLiveActivities() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            // Request Live Activities authorization
            Task {
                let authStatus = ActivityAuthorizationInfo().areActivitiesEnabled
                print("Live Activities authorized: \(authStatus)")
            }
        }
        #endif
    }
    
    private func handleAppWillEnterForeground() {
        print("📱 App will enter foreground - checking for active alarms")
        alarmManager.handleAppForeground()
    }
    
    private func handleAppDidBecomeActive() {
        print("📱 App became active - checking for active alarms")
        alarmManager.handleAppBecameActive()
    }
    
    private func handleAppDidEnterBackground() {
        print("📱 App entered background")
        alarmManager.handleAppEnteredBackground()
    }
    
    private func incrementLaunchCount() {
        let launchCountKey = "appLaunchCount"
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: launchCountKey)
        
        // Request review on 10th launch
        if newCount == 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
        }
    }
    
    private func configureBackgroundAudio() {
        // Audio session configuration is now handled by AlarmManager
        // to avoid conflicts between app-level and alarm-specific settings
        print("✅ Audio session configuration delegated to AlarmManager")
    }
}

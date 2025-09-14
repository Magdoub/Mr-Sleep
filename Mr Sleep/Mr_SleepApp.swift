//
//  Mr_SleepApp.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI
import StoreKit

@main
struct Mr_SleepApp: App {
    @StateObject private var alarmManager = AlarmManager.shared
    @StateObject private var backgroundAlarmManager = BackgroundAlarmManager.shared
    
    init() {
        // Initialize background alarm system on app launch
        DispatchQueue.main.async {
            BackgroundAlarmManager.shared.startBackgroundAudio()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // Use MainTabView to show the bottom tab bar
                .preferredColorScheme(.dark)
                .environmentObject(alarmManager)
                .onAppear {
                    incrementLaunchCount()
                    // Ensure background audio is running
                    backgroundAlarmManager.startBackgroundAudio()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Resume background audio when app enters foreground
                    backgroundAlarmManager.startBackgroundAudio()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Ensure audio continues in background
                    print("📱 App entering background - background audio should continue")
                }
        }
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
}
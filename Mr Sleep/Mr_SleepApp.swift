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
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // Use MainTabView to show the bottom tab bar
                .preferredColorScheme(.dark)
                .environmentObject(alarmManager)
                .onAppear {
                    incrementLaunchCount()
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
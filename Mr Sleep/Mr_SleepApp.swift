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

@main
struct Mr_SleepApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()  // Use MainTabView to show the bottom tab bar
                .preferredColorScheme(.dark)
                .onAppear {
                    incrementLaunchCount()
                    setupLiveActivities()
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

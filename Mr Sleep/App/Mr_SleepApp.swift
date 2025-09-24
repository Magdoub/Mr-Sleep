//
//  Mr_SleepApp.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

/*
 * App Entry Point & Configuration
 * 
 * This file defines the main SwiftUI App struct and handles:
 * - App lifecycle and startup configuration
 * - Dark mode preference setting
 * - Launch count tracking for App Store review prompts
 * - Initial view hierarchy configuration
 */

import SwiftUI
import StoreKit

@main
struct Mr_SleepApp: App {
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
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
                    AppStore.requestReview(in: windowScene)
                }
            }
        }
    }
}
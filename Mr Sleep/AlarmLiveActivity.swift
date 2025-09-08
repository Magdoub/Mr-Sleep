//
//  AlarmLiveActivity.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
import SwiftUI
import AVFoundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// Always available struct with conditional functionality
struct AlarmLiveActivity {
    static func start(for alarm: AlarmItem) {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                print("Live Activities not authorized")
                return
            }
            
            // Stop any existing activities first
            Task {
                for activity in Activity<AlarmActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            
            let attributes = AlarmActivityAttributes(
                alarmId: alarm.id.uuidString,
                originalAlarmTime: alarm.time,
                alarmLabel: alarm.label
            )
            
            let contentState = AlarmActivityAttributes.ContentState(
                alarmTime: alarm.time,
                alarmLabel: alarm.label,
                isActive: true,
                timeRemaining: "Now",
                currentTime: DateFormatter.timeFormatter.string(from: Date()),
                alarmId: alarm.id.uuidString
            )
            
            do {
                let activity = try Activity<AlarmActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                print("✅ Live Activity started: \(activity.id)")
            } catch {
                print("❌ Failed to start Live Activity: \(error)")
            }
        } else {
            print("Live Activities not available on iOS < 16.1")
        }
        #else
        print("ActivityKit not available")
        #endif
    }
    
    static func stop() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            
            Task {
                for activity in Activity<AlarmActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    print("🛑 Live Activity ended: \(activity.id)")
                }
            }
        }
        #else
        print("ActivityKit not available")
        #endif
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
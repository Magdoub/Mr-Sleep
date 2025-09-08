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

@available(iOS 16.1, *)
struct AlarmLiveActivity {
    static func start(for alarm: AlarmItem) {
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
    }
    
    static func stop() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        Task {
            for activity in Activity<AlarmActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
                print("🛑 Live Activity ended: \(activity.id)")
            }
        }
    }
}

// Widget definition for Live Activities
@available(iOS 16.1, *)
struct AlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmActivityAttributes.self) { context in
            // Lock screen view
            AlarmLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island implementation
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "alarm.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wake Up!")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(context.state.alarmLabel)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text("ALARM")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.alarmTime)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Button("Dismiss") {
                        // This will be handled by the app intent
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red)
                    .cornerRadius(22)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.red)
            } compactTrailing: {
                Text(context.state.alarmTime)
                    .font(.caption)
                    .fontWeight(.bold)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

@available(iOS 16.1, *)
struct AlarmLockScreenView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                
                Text("Alarmy")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(context.state.alarmTime) Alarm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Main message
            HStack {
                Text("💗 It's Monday afternoon")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Dismiss button
            Button("Dismiss") {
                // Button action handled by system
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.red)
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#endif
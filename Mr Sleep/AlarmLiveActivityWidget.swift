//
//  AlarmLiveActivityWidget.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AVFoundation

struct AlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmActivityAttributes.self) { context in
            // Live Activity view for the lock screen and Dynamic Island
            AlarmLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded state
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image("clock-3D-icon")
                            .resizable()
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading) {
                            Text("💗 It's Monday afternoon")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text(context.state.alarmTime)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text("Alarm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.alarmTime)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        Button(intent: DismissAlarmIntent(alarmId: context.state.alarmId)) {
                            Text("Dismiss")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.red.gradient)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                Image("clock-3D-icon")
                    .resizable()
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                Text(context.state.alarmTime)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } minimal: {
                Image("clock-3D-icon")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
    }
}

struct AlarmLiveActivityView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area matching the screenshot design
            VStack(spacing: 12) {
                HStack {
                    Image("clock-3D-icon")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    Text("Alarmy")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(context.state.alarmTime) Alarm")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Main alarm message
                HStack {
                    Text("💗")
                        .font(.title2)
                    
                    Text("It's Monday afternoon")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Dismiss button matching the red design from screenshot
            Button(intent: DismissAlarmIntent(alarmId: context.state.alarmId)) {
                Text("Dismiss")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
        )
        .onAppear {
            playAlarmSound()
        }
    }
    
    private func playAlarmSound() {
        // Configure audio session for alarm sound
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Play alarm sound - we'll implement this with a sound file
        playAlarmSoundFile()
    }
    
    private func playAlarmSoundFile() {
        guard let soundURL = Bundle.main.url(forResource: "alarm-clock", withExtension: "mp3") ??
                             Bundle.main.url(forResource: "alarm-clock", withExtension: "wav") ??
                             Bundle.main.url(forResource: "alarm-clock", withExtension: "m4a") ??
                             Bundle.main.url(forResource: "alarm-clock", withExtension: "caf") else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1005) // Long beep sound
            return
        }
        
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

// App Intent for dismissing the alarm
struct DismissAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Dismiss Alarm"
    
    @Parameter(title: "Alarm ID")
    var alarmId: String
    
    init() {
        self.alarmId = ""
    }
    
    init(alarmId: String) {
        self.alarmId = alarmId
    }
    
    func perform() async throws -> some IntentResult {
        // Stop the Live Activity
        await AlarmLiveActivityManager.shared.endActivity(for: alarmId)
        
        // Stop any playing alarm sounds
        AudioServicesDisposeSystemSoundID(0)
        
        return .result()
    }
}
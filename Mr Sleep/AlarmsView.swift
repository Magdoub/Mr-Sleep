//
//  AlarmsView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

struct AlarmsView: View {
    @ObservedObject var alarmManager: AlarmManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.25, blue: 0.5),
                        Color(red: 0.06, green: 0.15, blue: 0.35),
                        Color(red: 0.03, green: 0.08, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Alarms")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                        
                        Spacer()
                        
                        // Temporary clear all button for development
                        Button(action: {
                            alarmManager.clearAllAlarms()
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.4))
                        }
                        .accessibilityLabel("Clear all alarms")
                        
                        Button(action: {
                            // Add new alarm action
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                        }
                        .accessibilityLabel("Add new alarm")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Alarms List
                    if alarmManager.alarms.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "alarm")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.7))
                            
                            Text("No Alarms Set")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                            
                            Text("Tap + to add your first alarm")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(alarmManager.alarms) { alarm in
                                    AlarmRowView(
                                        alarm: Binding(
                                            get: { alarm },
                                            set: { newValue in
                                                if let index = alarmManager.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                                    alarmManager.alarms[index] = newValue
                                                }
                                            }
                                        ),
                                        onToggle: { alarmManager.toggleAlarm(alarm) },
                                        onDelete: { alarmManager.removeAlarm(alarm) }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct AlarmRowView: View {
    @Binding var alarm: AlarmItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Time and Label
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.time)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                
                HStack(spacing: 8) {
                    Text(alarm.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                    
                    if alarm.createdFromSleepNow {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.4))
            }
            .padding(.trailing, 8)
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.894, green: 0.729, blue: 0.306)))
            .scaleEffect(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            alarm.createdFromSleepNow ? 
                            Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3) : 
                            Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    AlarmsView(alarmManager: AlarmManager())
}


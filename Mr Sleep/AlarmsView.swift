//
//  AlarmsView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

struct AlarmsView: View {
    @State private var alarms: [AlarmItem] = [
        AlarmItem(time: "7:00 AM", isEnabled: true, label: "Work Day"),
        AlarmItem(time: "8:30 AM", isEnabled: false, label: "Weekend"),
        AlarmItem(time: "6:45 AM", isEnabled: true, label: "Gym Day")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Alarms")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                    
                    Spacer()
                    
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
                if alarms.isEmpty {
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
                            ForEach(alarms.indices, id: \.self) { index in
                                AlarmRowView(alarm: $alarms[index])
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.25, blue: 0.5),
                    Color(red: 0.06, green: 0.15, blue: 0.35),
                    Color(red: 0.03, green: 0.08, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .ignoresSafeArea()
    }
}

struct AlarmItem: Identifiable {
    let id = UUID()
    var time: String
    var isEnabled: Bool
    var label: String
}

struct AlarmRowView: View {
    @Binding var alarm: AlarmItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.time)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                
                Text(alarm.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $alarm.isEnabled)
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
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    AlarmsView()
}

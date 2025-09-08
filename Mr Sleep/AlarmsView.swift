//
//  AlarmsView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

struct AlarmsView: View {
    @ObservedObject var alarmManager: AlarmManager
    @State private var showingAddAlarm = false
    @State private var selectedTime = Date()
    @State private var showingEditAlarm = false
    @State private var alarmToEdit: AlarmItem?
    
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
                            showingAddAlarm = true
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
                                        onDelete: { alarmManager.removeAlarm(alarm) },
                                        onEdit: {
                                            alarmToEdit = alarm
                                            showingEditAlarm = true
                                        }
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
        .sheet(isPresented: $showingAddAlarm) {
            AddAlarmView(alarmManager: alarmManager, selectedTime: $selectedTime)
        }
        .sheet(item: Binding<AlarmItem?>(
            get: { showingEditAlarm ? alarmToEdit : nil },
            set: { _ in showingEditAlarm = false }
        )) { alarm in
            EditAlarmView(alarmManager: alarmManager, alarm: alarm)
        }
    }
}

struct AlarmRowView: View {
    @Binding var alarm: AlarmItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Time and Label (tappable area)
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.time)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                
                HStack(spacing: 8) {
                    if alarm.createdFromSleepNow {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                            Text(alarm.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                        }
                    } else {
                        // Manual alarm - show snooze and sound info
                        VStack(alignment: .leading, spacing: 2) {
                            if alarm.snoozeEnabled {
                                Text("Snooze")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                            }
                            Text(alarm.soundName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                        }
                    }
                }
            }
            .onTapGesture {
                onEdit()
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

struct AddAlarmView: View {
    @ObservedObject var alarmManager: AlarmManager
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    @State private var snoozeEnabled = true
    @State private var selectedSound = "Radar"
    
    let soundOptions = ["Radar", "Apex", "Beacon"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient to match app theme
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
                    // Time Picker Section
                    VStack(spacing: 20) {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .colorScheme(.dark)
                            .scaleEffect(1.1)
                            .background(Color.clear)
                            .accentColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    .background(Color.clear)
                
                // Options Section
                VStack(spacing: 30) {
                    // Snooze Section
                    HStack {
                        Text("Snooze")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: $snoozeEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.894, green: 0.729, blue: 0.306)))
                    }
                    .padding(.horizontal, 20)
                    
                    // Sound Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sound")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(soundOptions, id: \.self) { sound in
                                Button(action: {
                                    selectedSound = sound
                                }) {
                                    Text(sound)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedSound == sound ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedSound == sound ? 
                                                      Color(red: 0.894, green: 0.729, blue: 0.306) : 
                                                      Color.white.opacity(0.2))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Spacer()
                }
            }
            .navigationTitle("Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addAlarm()
                    }
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private func addAlarm() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: selectedTime)
        
        alarmManager.addManualAlarm(time: timeString, snoozeEnabled: snoozeEnabled, soundName: selectedSound)
        dismiss()
    }
}

struct EditAlarmView: View {
    @ObservedObject var alarmManager: AlarmManager
    let alarm: AlarmItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    @State private var snoozeEnabled: Bool
    @State private var selectedSound: String
    @State private var alarmLabel: String
    
    init(alarmManager: AlarmManager, alarm: AlarmItem) {
        self.alarmManager = alarmManager
        self.alarm = alarm
        
        // Parse the time string to create a Date
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let parsedTime = formatter.date(from: alarm.time) ?? Date()
        
        // Initialize state with alarm values
        _selectedTime = State(initialValue: parsedTime)
        _snoozeEnabled = State(initialValue: alarm.snoozeEnabled)
        _selectedSound = State(initialValue: alarm.soundName)
        _alarmLabel = State(initialValue: alarm.label)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient to match app theme
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
                
                VStack(spacing: 30) {
                    // Time Picker Section
                    VStack {
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .background(Color.clear)
                            .colorScheme(.dark)
                            .accentColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                            .scaleEffect(1.1)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 25) {
                        if !alarm.createdFromSleepNow {
                            HStack {
                                Text("Label")
                                    .foregroundColor(.white)
                                Spacer()
                                TextField("Alarm", text: $alarmLabel)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        HStack {
                            Text("Snooze")
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $snoozeEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.894, green: 0.729, blue: 0.306)))
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Sound")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(["Radar", "Apex", "Beacon"], id: \.self) { sound in
                                    Button(action: {
                                        selectedSound = sound
                                    }) {
                                        Text(sound)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedSound == sound ? .black : .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(selectedSound == sound ? 
                                                          Color(red: 0.894, green: 0.729, blue: 0.306) : 
                                                          Color.white.opacity(0.2))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateAlarm()
                    }
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private func updateAlarm() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: selectedTime)
        
        alarmManager.updateAlarm(
            alarm: alarm,
            newTime: timeString,
            newLabel: alarmLabel,
            newSnoozeEnabled: snoozeEnabled,
            newSoundName: selectedSound
        )
        dismiss()
    }
}

#Preview {
    AlarmsView(alarmManager: AlarmManager())
}


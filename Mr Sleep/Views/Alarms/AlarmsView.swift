//
//  AlarmsView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

/*
 * Alarm Management Interface
 * 
 * This view provides comprehensive alarm management functionality:
 * - Display all created alarms in a clean, iOS Clock app-style interface
 * - Toggle alarms on/off with visual feedback
 * - Create new manual alarms with time picker
 * - Edit existing alarms (time, sound, labels)
 * - Delete alarms with swipe gestures
 * - Sound selection with preview functionality
 * - Category-based visual organization (Quick Boost, Recovery, Full Recharge)
 * - Integration with AlarmManager for data persistence
 */

import SwiftUI
import AVFoundation

class SoundPreviewManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var isPlayingSystemSound = false
    
    func playSound(_ soundName: String) {
        // Always stop any currently playing sound first
        stopCurrentSound()
        
        // Map sound names to actual file names
        let fileName: String
        switch soundName.lowercased() {
        case "sunrise", "morning":
            fileName = "morning-alarm-clock"
        case "calm":
            fileName = "smooth-alarm-clock"
        case "classic":
            fileName = "alarm-clock"
        default:
            fileName = soundName.lowercased()
        }
        
        // Try to find the sound file in the bundle
        let possibleExtensions = ["mp3", "wav", "m4a", "caf"]
        var soundURL: URL?
        
        for ext in possibleExtensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                soundURL = url
                break
            }
        }
        
        if let url = soundURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = 0 // Play once
                audioPlayer?.play()
            } catch {
                playSystemSoundForName(soundName)
            }
        } else {
            // Fallback to different system sounds for each alarm type
            playSystemSoundForName(soundName)
        }
    }
    
    private func playSystemSoundForName(_ soundName: String) {
        // Use different system sounds to differentiate between alarm types
        let systemSoundID: SystemSoundID
        
        switch soundName.lowercased() {
        case "sunrise", "morning":
            systemSoundID = 1007 // Horn sound (morning-like)
        case "calm":
            systemSoundID = 1013 // SMS-like gentle sound
        case "classic":
            systemSoundID = 1005 // Classic alarm beep
        default:
            systemSoundID = 1007 // Default to sunrise-like sound
        }
        
        // Play the sound 3 times
        playSystemSoundRepeated(systemSoundID, repeatCount: 3)
    }
    
    private func playSystemSoundRepeated(_ soundID: SystemSoundID, repeatCount: Int) {
        guard repeatCount > 0 && !isPlayingSystemSound else { return }
        
        if repeatCount == 3 {
            isPlayingSystemSound = true
        }
        
        AudioServicesPlaySystemSound(soundID)
        
        if repeatCount > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.isPlayingSystemSound else { return }
                self.playSystemSoundRepeated(soundID, repeatCount: repeatCount - 1)
            }
        } else {
            isPlayingSystemSound = false
        }
    }
    
    func stopCurrentSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingSystemSound = false
        // Note: Can't stop system sounds once started, but we prevent new repeats
    }
}

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
                                        onToggle: { 
                                            alarmManager.toggleAlarm(alarm) 
                                        },
                                        onDelete: { 
                                            alarmManager.removeAlarm(alarm) 
                                        },
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
                        // Manual alarm - show sound info
                        VStack(alignment: .leading, spacing: 2) {
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
    @State private var selectedSound = "Sunrise"
    @StateObject private var soundPreview = SoundPreviewManager()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let soundOptions = ["Sunrise", "Calm", "Classic"]
    
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
                                    soundPreview.playSound(sound)
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
                        soundPreview.stopCurrentSound()
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
        .alert("Alarm Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addAlarm() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: selectedTime)
        
        let _ = alarmManager.addManualAlarm(time: timeString, soundName: selectedSound)
        soundPreview.stopCurrentSound()
        dismiss()
    }
}

struct EditAlarmView: View {
    @ObservedObject var alarmManager: AlarmManager
    let alarm: AlarmItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    @State private var selectedSound: String
    @StateObject private var soundPreview = SoundPreviewManager()
    
    init(alarmManager: AlarmManager, alarm: AlarmItem) {
        self.alarmManager = alarmManager
        self.alarm = alarm
        
        // Parse the time string to create a Date
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let parsedTime = formatter.date(from: alarm.time) ?? Date()
        
        // Initialize state with alarm values
        _selectedTime = State(initialValue: parsedTime)
        // Map legacy names to current labels for UI
        let initialSound = alarm.soundName.lowercased() == "smooth" ? "Calm" : alarm.soundName
        _selectedSound = State(initialValue: initialSound)
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
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Sound")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(["Sunrise", "Calm", "Classic"], id: \.self) { sound in
                                    Button(action: {
                                        selectedSound = sound
                                        soundPreview.playSound(sound)
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
                        soundPreview.stopCurrentSound()
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
        
        
        // Update UI alarm
        alarmManager.updateAlarm(
            alarm: alarm,
            newTime: timeString,
            newSoundName: selectedSound
        )
        soundPreview.stopCurrentSound()
        dismiss()
    }
}

#Preview {
    AlarmsView(alarmManager: AlarmManager.shared)
}

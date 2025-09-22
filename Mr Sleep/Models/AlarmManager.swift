//
//  AlarmManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

/*
 * Alarm Data Management System
 * 
 * This file handles all alarm-related data operations:
 * - AlarmItem model definition with sleep category integration
 * - AlarmManager singleton for centralized alarm storage
 * - UserDefaults persistence for alarm data
 * - Alarm creation from sleep calculations and manual input
 * - Alarm editing, deletion, and state management
 * - Category-based labeling (Quick Boost, Recovery, Full Recharge)
 * - Sound assignment and management
 * - Integration with sleep cycle calculations
 */

import SwiftUI
import Foundation

// MARK: - Alarm Item Model
struct AlarmItem: Identifiable, Codable, Equatable {
    var id: UUID
    var time: String
    var isEnabled: Bool
    var label: String
    var category: String // "Quick Boost", "Recovery", "Full Recharge"
    var cycles: Int
    var createdFromSleepNow: Bool = false
    var soundName: String = "Sunrise"
    var shouldAutoReset: Bool = false
    
    init(time: String, isEnabled: Bool, label: String, category: String, cycles: Int, createdFromSleepNow: Bool = false, soundName: String = "Sunrise", shouldAutoReset: Bool = false) {
        self.id = UUID()
        self.time = time
        self.isEnabled = isEnabled
        self.label = label
        self.category = category
        self.cycles = cycles
        self.createdFromSleepNow = createdFromSleepNow
        self.soundName = soundName
        self.shouldAutoReset = shouldAutoReset
    }
    
    // Equatable conformance
    static func == (lhs: AlarmItem, rhs: AlarmItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Alarm Manager
class AlarmManager: ObservableObject {
    static let shared = AlarmManager()
    
    @Published var alarms: [AlarmItem] = []
    
    private init() {
        loadAlarms()
    }
    
    // MARK: - Basic Alarm Operations
    
    func addAlarm(time: String, category: String, cycles: Int) -> UUID {
        let label = generateAlarmLabel(category: category, cycles: cycles)
        let alarm = AlarmItem(
            time: time,
            isEnabled: true,
            label: label,
            category: category,
            cycles: cycles,
            createdFromSleepNow: true,
            soundName: "Morning"
        )
        alarms.append(alarm)
        saveAlarms()
        return alarm.id
    }
    
    func addManualAlarm(time: String, soundName: String) -> UUID {
        let alarm = AlarmItem(
            time: time,
            isEnabled: true,
            label: "Alarm",
            category: "Manual",
            cycles: 0,
            createdFromSleepNow: false,
            soundName: soundName,
            shouldAutoReset: true
        )
        alarms.append(alarm)
        saveAlarms()
        return alarm.id
    }
    
    func removeAlarm(_ alarm: AlarmItem) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func toggleAlarm(_ alarm: AlarmItem) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
        }
    }
    
    func updateAlarm(alarm: AlarmItem, newTime: String, newSoundName: String) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].time = newTime
            alarms[index].soundName = newSoundName
            saveAlarms()
        }
    }
    
    func clearAllAlarms() {
        alarms.removeAll()
        saveAlarms()
    }
    
    // MARK: - Helper Functions
    
    private func generateAlarmLabel(category: String, cycles: Int) -> String {
        let sleepHours = Double(cycles) * 1.5
        let hoursInt = Int(sleepHours)
        let minutes = Int((sleepHours - Double(hoursInt)) * 60)
        
        let hoursText = hoursInt > 0 ? "\(hoursInt)h" : ""
        let minutesText = minutes > 0 ? "\(minutes)m" : ""
        let durationText = [hoursText, minutesText].filter { !$0.isEmpty }.joined(separator: " ")
        
        return "💤 \(durationText) \(category)"
    }
    
    // MARK: - Data Persistence
    
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: "SavedAlarms")
        }
    }
    
    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: "SavedAlarms"),
           let decoded = try? JSONDecoder().decode([AlarmItem].self, from: data) {
            alarms = decoded
        }
    }
}
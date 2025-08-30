//
//  SleepCalculator.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import Foundation

class SleepCalculator {
    static let shared = SleepCalculator()
    
    private init() {}
    
    // Sleep cycle duration in minutes (90 minutes)
    private let sleepCycleDuration = 90
    
    // Time to fall asleep in minutes
    private let fallAsleepTime = 15
    
    func calculateWakeUpTimes() -> [Date] {
        let now = Date()
        let fallAsleepDate = Calendar.current.date(byAdding: .minute, value: fallAsleepTime, to: now)!
        
        var wakeUpTimes: [Date] = []
        
        // Calculate ALL wake-up times in desired order: 4,5,3,2,1,6 cycles
        let sleepCycles = [4, 5, 3, 2, 1, 6]
        
        for cycles in sleepCycles {
            let totalMinutes = cycles * sleepCycleDuration
            let rawWakeUpTime = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: fallAsleepDate)!
            let roundedWakeUpTime = roundToNearestQuarter(rawWakeUpTime)
            wakeUpTimes.append(roundedWakeUpTime)
        }
        
        return wakeUpTimes
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    func getSleepCycleCount(for cycles: Int) -> Int {
        return cycles
    }
    
    func getSleepDuration(for cycles: Int) -> Double {
        return Double(cycles) * 1.5 // Each cycle is 1.5 hours
    }
    
    private func roundToNearestQuarter(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let minute = components.minute else { return date }
        
        // Round to nearest 15-minute interval
        let roundedMinute: Int
        if minute < 8 {
            roundedMinute = 0
        } else if minute < 23 {
            roundedMinute = 15
        } else if minute < 38 {
            roundedMinute = 30
        } else if minute < 53 {
            roundedMinute = 45
        } else {
            roundedMinute = 0
            // Need to add an hour if rounding 53+ minutes to next hour
            var newComponents = components
            newComponents.minute = roundedMinute
            newComponents.hour = (components.hour ?? 0) + 1
            return calendar.date(from: newComponents) ?? date
        }
        
        var newComponents = components
        newComponents.minute = roundedMinute
        return calendar.date(from: newComponents) ?? date
    }
}

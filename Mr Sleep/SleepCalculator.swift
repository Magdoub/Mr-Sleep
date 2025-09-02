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
            let roundedWakeUpTime = roundToNearestFiveMinutes(rawWakeUpTime)
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
    
    func getCategoryForCycles(_ cycles: Int) -> String {
        switch cycles {
        case 1...2:
            return "Quick Boost"
        case 3...4:
            return "Recovery"
        case 5...:
            return "Full Recharge"
        default:
            return "Recovery"
        }
    }
    
    func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "Quick Boost":
            return "bolt-3D-icon"
        case "Recovery":
            return "heart-3D-icon"
        case "Full Recharge":
            return "battery-3D-icon"
        default:
            return "moon.fill"
        }
    }
    
    func getCategorizedWakeUpTimes() -> [(category: String, times: [(time: Date, cycles: Int)])] {
        let allTimes = calculateWakeUpTimes()
        let sleepCycles = [4, 5, 3, 2, 1, 6]
        
        var categorizedTimes: [String: [(time: Date, cycles: Int)]] = [:]
        
        for (index, time) in allTimes.enumerated() {
            let cycles = sleepCycles[index]
            let category = getCategoryForCycles(cycles)
            
            if categorizedTimes[category] == nil {
                categorizedTimes[category] = []
            }
            categorizedTimes[category]?.append((time: time, cycles: cycles))
        }
        
        // Return in desired order with times sorted by cycles ascending within each category
        let categoryOrder = ["Quick Boost", "Recovery", "Full Recharge"]
        return categoryOrder.compactMap { category in
            guard let times = categorizedTimes[category], !times.isEmpty else { return nil }
            let sortedTimes = times.sorted { $0.cycles < $1.cycles }
            return (category: category, times: sortedTimes)
        }
    }
    
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let minute = components.minute else { return date }
        
        // Round to nearest 5-minute interval
        let roundedMinute = ((minute + 2) / 5) * 5
        
        var newComponents = components
        
        if roundedMinute >= 60 {
            // Need to add an hour if rounding goes to 60+ minutes
            newComponents.minute = 0
            newComponents.hour = (components.hour ?? 0) + 1
        } else {
            newComponents.minute = roundedMinute
        }
        
        return calendar.date(from: newComponents) ?? date
    }
}

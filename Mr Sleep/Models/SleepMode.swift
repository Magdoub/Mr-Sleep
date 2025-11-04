//
//  SleepMode.swift
//  Mr Sleep
//
//  Created by Claude on 02/11/2025.
//

/*
 * Sleep Mode Selection
 *
 * This enum tracks whether the user is in "Sleep Now" or "Wake Up At" mode.
 * The selected mode is persisted to UserDefaults so it's restored on app launch.
 *
 * Modes:
 * - sleepNow: Calculate wake-up times based on sleeping now (existing functionality)
 * - wakeUpAt: Calculate bedtimes based on desired wake-up time (new functionality)
 */

import Foundation

enum SleepMode: String, Codable {
    case sleepNow = "sleep_now"
    case wakeUpAt = "wake_up_at"

    static let userDefaultsKey = "SelectedSleepMode"

    /// Load the saved mode from UserDefaults, defaulting to sleepNow
    static func loadFromUserDefaults() -> SleepMode {
        guard let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey),
              let mode = SleepMode(rawValue: savedMode) else {
            return .sleepNow // Default to Sleep Now mode
        }
        return mode
    }

    /// Save the current mode to UserDefaults
    func saveToUserDefaults() {
        UserDefaults.standard.set(self.rawValue, forKey: SleepMode.userDefaultsKey)
    }
}

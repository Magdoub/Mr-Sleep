//
//  LiveActivityTestHelper.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
import ActivityKit

class LiveActivityTestHelper {
    
    @MainActor
    static func createTestAlarmActivity() {
        let testAlarm = AlarmItem(
            time: "12:28 PM",
            isEnabled: true,
            label: "💗 It's Monday afternoon",
            category: "Test",
            cycles: 5,
            createdFromSleepNow: true,
            snoozeEnabled: true,
            soundName: "Radar",
            shouldAutoReset: false
        )
        
        AlarmLiveActivityManager.shared.startAlarmActivity(for: testAlarm)
        print("Test Live Activity created for alarm at \(testAlarm.time)")
    }
    
    @MainActor
    static func endTestActivity() {
        AlarmLiveActivityManager.shared.endCurrentActivity()
        print("Test Live Activity ended")
    }
    
    static func checkLiveActivitySupport() -> Bool {
        let isSupported = AlarmLiveActivityManager.shared.isSupported()
        print("Live Activities supported: \(isSupported)")
        return isSupported
    }
}
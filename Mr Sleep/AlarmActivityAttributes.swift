//
//  AlarmActivityAttributes.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)

struct AlarmActivityAttributes: ActivityAttributes {
    public typealias AlarmStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var alarmTime: String
        var alarmLabel: String
        var isActive: Bool
        var timeRemaining: String
        var currentTime: String
        var alarmId: String
    }
    
    var alarmId: String
    var originalAlarmTime: String
    var alarmLabel: String
}
#endif
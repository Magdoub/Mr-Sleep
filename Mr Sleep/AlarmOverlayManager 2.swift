//
//  AlarmOverlayManager.swift
//  Mr Sleep
//
//  Created by Magdoub on 08/09/2025.
//

import Foundation
import SwiftUI

class AlarmOverlayManager: ObservableObject {
    static let shared = AlarmOverlayManager()
    
    @Published var isShowingAlarm = false
    @Published var currentAlarm: AlarmItem?
    
    private init() {}
    
    func showAlarm(_ alarm: AlarmItem) {
        DispatchQueue.main.async {
            self.currentAlarm = alarm
            self.isShowingAlarm = true
            print("🚨 Showing alarm overlay for: \(alarm.label)")
        }
    }
    
    func dismissAlarm() {
        DispatchQueue.main.async {
            self.isShowingAlarm = false
            self.currentAlarm = nil
            print("✅ Alarm dismissed")
        }
    }
    
}
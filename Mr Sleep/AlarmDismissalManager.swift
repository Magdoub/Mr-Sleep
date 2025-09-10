//
//  AlarmDismissalManager.swift
//  Mr Sleep
//
//  Created by Claude on 10/09/2025.
//

import Foundation
import SwiftUI

class AlarmDismissalManager: ObservableObject {
    static let shared = AlarmDismissalManager()
    
    @Published var isShowingDismissalPage = false
    @Published var currentAlarm: AlarmItem?
    
    private init() {}
    
    func showDismissalPage(for alarm: AlarmItem) {
        DispatchQueue.main.async {
            print("📱 Showing dismissal page for alarm: \(alarm.label)")
            self.currentAlarm = alarm
            self.isShowingDismissalPage = true
        }
    }
    
    func dismissAlarm() {
        DispatchQueue.main.async {
            print("✅ Dismissal page closed")
            self.isShowingDismissalPage = false
            self.currentAlarm = nil
        }
    }
}
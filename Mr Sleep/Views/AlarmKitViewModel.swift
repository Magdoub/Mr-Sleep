import AlarmKit
import SwiftUI
import AppIntents
import Foundation

@Observable class AlarmKitViewModel {
    @MainActor var alarmManager = ItsukiAlarmManager.shared
    
    @MainActor var hasUpcomingAlarms: Bool {
        alarmManager.hasUpcomingAlarms
    }
    
    @MainActor var runningAlarms: [ItsukiAlarm] {
        alarmManager.runningAlarms
    }
    
    @MainActor var recentAlarms: [ItsukiAlarm] {
        alarmManager.recentAlarms
    }
    
    @MainActor var runningTraditionalAlarms: [ItsukiAlarm] {
        alarmManager.runningTraditionalAlarms
    }
    
    @MainActor var runningTimers: [ItsukiAlarm] {
        alarmManager.runningTimers
    }
    
    @MainActor var runningCustomAlarms: [ItsukiAlarm] {
        alarmManager.runningCustomAlarms
    }
    
    init() {
        // ViewModel initializes but doesn't duplicate manager initialization
    }
    
    // MARK: - Alarm Scheduling from Form
    
    func scheduleAlarm(with userInput: AlarmKitForm) async {
        let alarmID = UUID()
        
        do {
            if let schedule = userInput.schedule {
                print("📅 Scheduling alarm with schedule: \(schedule)")
                print("⏰ Alarm time: \(userInput.selectedDate)")
                
                // Simple scheduled alarm
                try await alarmManager.addAlarm(
                    title: "Alarm",
                    icon: "alarm",
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    schedule: schedule
                )
                print("✅ Alarm scheduled successfully")
            } else {
                print("❌ No schedule created from userInput")
            }
        } catch {
            print("💥 AlarmKit Error: \(error)")
            print("💥 Error localizedDescription: \(error.localizedDescription)")
            if let alarmError = error as? NSError {
                print("💥 Error code: \(alarmError.code)")
                print("💥 Error domain: \(alarmError.domain)")
                print("💥 Error userInfo: \(alarmError.userInfo)")
            }
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    // MARK: - Example Alarms (from sample code)
    
    func scheduleAlertOnlyExample() async {
        let alarmID = UUID()
        let schedule = createTwoMinutesFromNowSchedule()
        
        do {
            try await alarmManager.addAlarm(
                title: "Wake Up",
                icon: "alarm",
                metadata: MrSleepAlarmMetadata(wakeUpReason: .general),
                alarmID: alarmID,
                schedule: schedule
            )
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    func scheduleCountdownAlertExample() async {
        let alarmID = UUID()
        
        do {
            try await alarmManager.addCustom(
                title: "Food Ready",
                icon: "oven",
                metadata: MrSleepAlarmMetadata(wakeUpReason: .general),
                alarmID: alarmID,
                schedule: nil,
                countdownDuration: .init(preAlert: 15 * 60, postAlert: 15 * 60),
                secondaryIntent: RepeatIntent(alarmID: alarmID.uuidString)
            )
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    func scheduleCustomButtonAlertExample() async {
        let alarmID = UUID()
        let schedule = createTwoMinutesFromNowSchedule()
        
        do {
            try await alarmManager.addCustom(
                title: "Wake Up",
                icon: "alarm",
                metadata: MrSleepAlarmMetadata(wakeUpReason: .general),
                alarmID: alarmID,
                schedule: schedule,
                countdownDuration: nil,
                secondaryIntent: OpenMrSleepAppIntent(alarmID: alarmID.uuidString)
            )
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    // MARK: - Quick Sleep Timers
    
    // Removed complex quick setup methods since we simplified the UI
    
    // MARK: - Alarm Management
    
    func deleteAlarm(_ alarm: ItsukiAlarm) async {
        do {
            try await alarmManager.deleteAlarm(alarm.id)
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    func pauseAlarm(_ alarm: ItsukiAlarm) async {
        do {
            try await alarmManager.pauseAlarm(alarm.id)
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    func resumeAlarm(_ alarm: ItsukiAlarm) async {
        do {
            try await alarmManager.resumeAlarm(alarm.id)
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    func stopAlarm(_ alarm: ItsukiAlarm) async {
        do {
            try await alarmManager.stopAlarm(alarm.id)
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    func repeatAlarm(_ alarm: ItsukiAlarm) async {
        do {
            try await alarmManager.repeatAlarm(alarm.id)
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    // MARK: - Helper Methods
    // Removed secondaryIntent method since simplified UI doesn't use complex button behaviors
    
    private func createTwoMinutesFromNowSchedule() -> Alarm.Schedule {
        let twoMinsFromNow = Date.now.addingTimeInterval(2 * 60)
        let time = Alarm.Schedule.Relative.Time(
            hour: Calendar.current.component(.hour, from: twoMinsFromNow),
            minute: Calendar.current.component(.minute, from: twoMinsFromNow)
        )
        return .relative(.init(time: time))
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() async -> Bool {
        await alarmManager.checkAuthorization()
    }
    
    // MARK: - Grouping Helpers
    
    @MainActor var alarmsByType: [ItsukiAlarm.ItsukiAlarmType: [ItsukiAlarm]] {
        Dictionary(grouping: runningAlarms) { $0.alarmType }
    }
    
    @MainActor var alarmsByState: [Alarm.State: [ItsukiAlarm]] {
        Dictionary(grouping: runningAlarms) { $0.state }
    }
    
    @MainActor var alarmsBySleepContext: [MrSleepAlarmMetadata.SleepContext: [ItsukiAlarm]] {
        let alarmsWithContext = runningAlarms.compactMap { alarm -> (MrSleepAlarmMetadata.SleepContext, ItsukiAlarm)? in
            guard let context = alarm.metadata.sleepContext else { return nil }
            return (context, alarm)
        }
        return Dictionary(grouping: alarmsWithContext) { $0.0 }.mapValues { $0.map(\.1) }
    }
    
    // MARK: - Statistics
    
    @MainActor var totalActiveAlarms: Int {
        runningAlarms.count
    }
    
    @MainActor var countdowningAlarms: Int {
        runningAlarms.filter { $0.state == .countdown }.count
    }
    
    @MainActor var pausedAlarms: Int {
        runningAlarms.filter { $0.state == .paused }.count
    }
    
    @MainActor var scheduledAlarms: Int {
        runningAlarms.filter { $0.state == .scheduled }.count
    }
    
    @MainActor var alertingAlarms: Int {
        runningAlarms.filter { $0.state == .alerting }.count
    }
    
    // MARK: - Next Alarm Info
    
    @MainActor var nextAlarmTime: Date? {
        runningTraditionalAlarms.first?.fireDate
    }
    
    @MainActor var nextAlarmTitle: String? {
        runningTraditionalAlarms.first?.displayTitle
    }
    
    @MainActor var activeTimerCount: Int {
        runningTimers.filter { $0.state == .countdown }.count
    }
}
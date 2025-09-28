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
    
    func scheduleAlarmWithID(_ alarmID: UUID, with userInput: AlarmKitForm) async -> Bool {
        do {
            if let schedule = userInput.schedule {
                // Scheduled alarm
                try await alarmManager.addAlarm(
                    title: userInput.label.isEmpty ? "Alarm" : userInput.label,
                    icon: userInput.metadata.sleepContext?.icon ?? userInput.metadata.wakeUpReason.icon,
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    schedule: schedule
                )
                return true
            } else if let countdown = userInput.countdownDuration {
                // Timer/countdown
                try await alarmManager.addTimer(
                    title: userInput.label.isEmpty ? "Timer" : userInput.label,
                    icon: userInput.metadata.sleepContext?.icon ?? "timer",
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    duration: countdown.preAlert ?? 900 // 15 minutes default
                )
                return true
            } else if userInput.schedule != nil && userInput.countdownDuration != nil {
                // Custom alarm with both schedule and countdown
                try await alarmManager.addCustom(
                    title: userInput.label.isEmpty ? "Custom Alarm" : userInput.label,
                    icon: userInput.metadata.sleepContext?.icon ?? "alarm.waves.left.and.right",
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    schedule: userInput.schedule,
                    countdownDuration: userInput.countdownDuration,
                    secondaryIntent: secondaryIntent(alarmID: alarmID, userInput: userInput)
                )
                return true
            }
            return false
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
            return false
        }
    }
    
    func scheduleAlarm(with userInput: AlarmKitForm) async {
        let alarmID = UUID()
        
        do {
            if let schedule = userInput.schedule {
                // Scheduled alarm
                try await alarmManager.addAlarm(
                    title: userInput.label.isEmpty ? "Alarm" : userInput.label,
                    icon: userInput.metadata.sleepContext?.icon ?? userInput.metadata.wakeUpReason.icon,
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    schedule: schedule
                )
            } else if let countdown = userInput.countdownDuration {
                // Timer/countdown
                try await alarmManager.addTimer(
                    title: userInput.label.isEmpty ? "Timer" : userInput.label,
                    icon: userInput.metadata.sleepContext?.icon ?? "timer",
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    duration: countdown.preAlert ?? 900 // 15 minutes default
                )
            } else if userInput.schedule != nil && userInput.countdownDuration != nil {
                // Custom alarm with both schedule and countdown
                try await alarmManager.addCustom(
                    title: userInput.label.isEmpty ? "Custom Alarm" : userInput.label,
                    icon: userInput.metadata.sleepContext?.icon ?? "alarm.waves.left.and.right",
                    metadata: userInput.metadata,
                    alarmID: alarmID,
                    schedule: userInput.schedule,
                    countdownDuration: userInput.countdownDuration,
                    secondaryIntent: secondaryIntent(alarmID: alarmID, userInput: userInput)
                )
            }
        } catch {
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
    
    func scheduleQuickNap() async {
        let form = AlarmKitForm.quickNap()
        await scheduleAlarm(with: form)
    }
    
    func schedulePowerNap() async {
        let form = AlarmKitForm.powerNap()
        await scheduleAlarm(with: form)
    }
    
    func scheduleShortSleep() async {
        let form = AlarmKitForm.shortSleep()
        await scheduleAlarm(with: form)
    }
    
    func scheduleMorningAlarm() async {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let morningTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow) ?? Date()
        let form = AlarmKitForm.morningAlarm(at: morningTime)
        await scheduleAlarm(with: form)
    }
    
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
    
    // MARK: - Edit Alarm
    
    func editAlarm(_ existingAlarm: ItsukiAlarm, with userInput: AlarmKitForm) async {
        do {
            try await alarmManager.updateAlarm(
                existingAlarm,
                title: userInput.label.isEmpty ? "Alarm" : userInput.label,
                icon: userInput.metadata.sleepContext?.icon ?? userInput.metadata.wakeUpReason.icon,
                metadata: userInput.metadata,
                schedule: userInput.schedule,
                countdownDuration: userInput.countdownDuration,
                secondaryIntent: secondaryIntent(alarmID: existingAlarm.id, userInput: userInput)
            )
        } catch {
            await MainActor.run {
                alarmManager.error = error
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func secondaryIntent(alarmID: UUID, userInput: AlarmKitForm) -> (any LiveActivityIntent)? {
        guard let behavior = userInput.secondaryButtonBehavior else { return nil }
        
        switch behavior {
        case .countdown:
            return RepeatIntent(alarmID: alarmID.uuidString)
        case .custom:
            return OpenMrSleepAppIntent(alarmID: alarmID.uuidString)
        @unknown default:
            return nil
        }
    }
    
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
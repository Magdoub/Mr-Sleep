import AlarmKit
import AppIntents
import Foundation

// MARK: - Stop Intent
struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        Task {
            do {
                try await ItsukiAlarmManager.shared.stopAlarm(UUID(uuidString: alarmID)!)
            } catch {
                print("Failed to stop alarm: \(error)")
            }
        }
        return .result()
    }
    
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alarm")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

// MARK: - Pause Intent
struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        Task {
            do {
                try await ItsukiAlarmManager.shared.pauseAlarm(UUID(uuidString: alarmID)!)
            } catch {
                print("Failed to pause alarm: \(error)")
            }
        }
        return .result()
    }
    
    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

// MARK: - Resume Intent
struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        Task {
            do {
                try await ItsukiAlarmManager.shared.resumeAlarm(UUID(uuidString: alarmID)!)
            } catch {
                print("Failed to resume alarm: \(error)")
            }
        }
        return .result()
    }
    
    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

// MARK: - Repeat Intent
struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        Task {
            do {
                try await ItsukiAlarmManager.shared.repeatAlarm(UUID(uuidString: alarmID)!)
            } catch {
                print("Failed to repeat alarm: \(error)")
            }
        }
        return .result()
    }
    
    static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Repeat a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

// MARK: - Open App Intent
struct OpenMrSleepAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        // Stop the alarm and open the app
        Task {
            do {
                try await ItsukiAlarmManager.shared.stopAlarm(UUID(uuidString: alarmID)!)
            } catch {
                print("Failed to stop alarm when opening app: \(error)")
            }
        }
        return .result()
    }
    
    static var title: LocalizedStringResource = "Open Mr Sleep"
    static var description = IntentDescription("Opens the Mr Sleep app")
    static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

// MARK: - Snooze Intent
struct SnoozeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        Task {
            do {
                // Stop current alarm
                try await ItsukiAlarmManager.shared.stopAlarm(UUID(uuidString: alarmID)!)
                
                // Schedule a new alarm 9 minutes from now (standard snooze)
                let snoozeTime = Date().addingTimeInterval(9 * 60) // 9 minutes
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: snoozeTime)
                
                guard let hour = components.hour, let minute = components.minute else { return }
                
                let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
                let schedule = Alarm.Schedule.relative(.init(time: time, repeats: .never))
                
                try await ItsukiAlarmManager.shared.addAlarm(
                    title: "Snoozed Alarm",
                    icon: "alarm.waves.left.and.right",
                    metadata: MrSleepAlarmMetadata(wakeUpReason: .general),
                    alarmID: UUID(),
                    schedule: schedule
                )
                
            } catch {
                print("Failed to snooze alarm: \(error)")
            }
        }
        return .result()
    }
    
    static var title: LocalizedStringResource = "Snooze"
    static var description = IntentDescription("Snooze alarm for 9 minutes")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

// MARK: - Add Timer Intent (for Shortcuts)
struct AddTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Timer"
    static var description = IntentDescription("Add a new timer to Mr Sleep")
    
    @Parameter(title: "Duration (minutes)")
    var durationMinutes: Int
    
    @Parameter(title: "Title")
    var title: String?
    
    func perform() async throws -> some IntentResult {
        let timerTitle = title ?? "Timer"
        let duration = TimeInterval(durationMinutes * 60)
        
        try await ItsukiAlarmManager.shared.addTimer(
            title: timerTitle,
            icon: "timer",
            metadata: MrSleepAlarmMetadata(wakeUpReason: .general),
            alarmID: UUID(),
            duration: duration
        )
        
        return .result(
            dialog: IntentDialog(stringLiteral: "Timer set for \(durationMinutes) minutes")
        )
    }
}

// MARK: - Add Sleep Timer Intent (Mr Sleep specific)
struct AddSleepTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Sleep Timer"
    static var description = IntentDescription("Add a sleep timer to Mr Sleep")
    
    @Parameter(title: "Sleep Type")
    var sleepType: SleepTypeParameter
    
    func perform() async throws -> some IntentResult {
        let metadata = MrSleepAlarmMetadata(
            sleepContext: sleepType.context,
            wakeUpReason: .general
        )
        
        try await ItsukiAlarmManager.shared.addTimer(
            title: sleepType.context?.rawValue ?? "Sleep Timer",
            icon: sleepType.context?.icon ?? "moon",
            metadata: metadata,
            alarmID: UUID(),
            duration: sleepType.context?.duration ?? 1800 // 30 minutes default
        )
        
        return .result(
            dialog: IntentDialog(stringLiteral: "Sleep timer set for \(sleepType.displayName)")
        )
    }
}

// MARK: - Sleep Type Parameter for Shortcuts
struct SleepTypeParameter: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Sleep Type")
    static var defaultQuery = SleepTypeQuery()
    
    var id: String
    var displayName: String
    var context: MrSleepAlarmMetadata.SleepContext?
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: displayName))
    }
    
    static let quickNap = SleepTypeParameter(
        id: "quickNap",
        displayName: "Quick Nap (20 min)",
        context: .quickNap
    )
    
    static let powerNap = SleepTypeParameter(
        id: "powerNap", 
        displayName: "Power Nap (30 min)",
        context: .powerNap
    )
    
    static let shortSleep = SleepTypeParameter(
        id: "shortSleep",
        displayName: "Short Sleep (1.5 hours)",
        context: .shortSleep
    )
    
    static let normalSleep = SleepTypeParameter(
        id: "normalSleep",
        displayName: "Normal Sleep (6 hours)",
        context: .normalSleep
    )
    
    static let longSleep = SleepTypeParameter(
        id: "longSleep",
        displayName: "Long Sleep (8 hours)",
        context: .longSleep
    )
    
    static let deepSleep = SleepTypeParameter(
        id: "deepSleep",
        displayName: "Deep Sleep (9 hours)",
        context: .deepSleep
    )
}

struct SleepTypeQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SleepTypeParameter] {
        let allTypes = [
            SleepTypeParameter.quickNap,
            SleepTypeParameter.powerNap,
            SleepTypeParameter.shortSleep,
            SleepTypeParameter.normalSleep,
            SleepTypeParameter.longSleep,
            SleepTypeParameter.deepSleep
        ]
        
        return allTypes.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [SleepTypeParameter] {
        [
            SleepTypeParameter.quickNap,
            SleepTypeParameter.powerNap,
            SleepTypeParameter.shortSleep,
            SleepTypeParameter.normalSleep
        ]
    }
}

// MARK: - App Shortcuts Provider
struct MrSleepAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddSleepTimerIntent(),
            phrases: [
                "Set a \(.applicationName) timer",
                "Start a sleep timer with \(.applicationName)",
                "Add sleep timer in \(.applicationName)"
            ],
            shortTitle: "Sleep Timer",
            systemImageName: "moon.zzz"
        )
        
        AppShortcut(
            intent: AddTimerIntent(),
            phrases: [
                "Add a timer to \(.applicationName)",
                "Set a \(\.$durationMinutes) minute timer in \(.applicationName)"
            ],
            shortTitle: "Add Timer",
            systemImageName: "timer"
        )
    }
}
import AlarmKit
import Foundation

@dynamicMemberLookup
struct ItsukiAlarm: Codable, Identifiable, Sendable {
    var alarm: Alarm
    var metadata: MrSleepAlarmMetadata
    
    // Enhanced state tracking
    var presentationMode: AlarmPresentationState? = nil
    
    // Computed properties for enhanced information
    var id: UUID { alarm.id }
    
    init(alarm: Alarm, metadata: MrSleepAlarmMetadata) {
        self.alarm = alarm
        self.metadata = metadata
    }
    
    // Dynamic member lookup to access alarm properties directly
    subscript<T>(dynamicMember keyPath: KeyPath<Alarm, T>) -> T {
        return alarm[keyPath: keyPath]
    }
    
    // Enhanced state information that native Alarm lacks
    var fireDate: Date? {
        guard let schedule = alarm.schedule else { return nil }
        
        switch schedule {
        case .fixed(let date):
            return date
        case .relative(let relative):
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            
            let today = Calendar.current.date(from: components)!
            
            // If the time has passed today, schedule for tomorrow
            if today < Date() {
                return Calendar.current.date(byAdding: .day, value: 1, to: today)
            }
            return today
            
        @unknown default:
            return nil
        }
    }
    
    var startDate: Date? {
        // For countdown timers, when did the countdown start
        guard let countdown = alarm.countdownDuration else { return nil }
        
        switch alarm.state {
        case .countdown:
            if let preAlert = countdown.preAlert {
                return Date().addingTimeInterval(-TimeInterval(preAlert))
            }
            return Date()
        case .paused:
            // This would need to be tracked in presentation state
            return presentationMode?.startDate
        default:
            return nil
        }
    }
    
    var previouslyElapsedDuration: TimeInterval {
        // Time elapsed before any pauses
        presentationMode?.previouslyElapsedDuration ?? 0
    }
    
    var totalCountdownDuration: TimeInterval {
        alarm.countdownDuration?.preAlert ?? 0
    }
    
    // UI Helper properties
    var displayTitle: String {
        if !metadata.createdAt.timeIntervalSinceNow.isZero,
           let context = metadata.sleepContext {
            return context.rawValue
        }
        return "Alarm"
    }
    
    var displaySubtitle: String {
        metadata.wakeUpReason.rawValue
    }
    
    var displayIcon: String {
        metadata.sleepContext?.icon ?? metadata.wakeUpReason.icon
    }
    
    var stateColor: String {
        switch alarm.state {
        case .scheduled: "blue"
        case .countdown: "green"
        case .paused: "yellow"
        case .alerting: "red"
        @unknown default: "gray"
        }
    }
    
    var stateLabel: String {
        switch alarm.state {
        case .scheduled: "Scheduled"
        case .countdown: "Running"
        case .paused: "Paused"
        case .alerting: "Alert"
        @unknown default: "Unknown"
        }
    }
    
    // Check if this is a one-shot alarm
    var isOneShot: Bool {
        guard let schedule = alarm.schedule else { return true }
        
        switch schedule {
        case .relative(let relative):
            return relative.repeats == .never
        case .fixed:
            return true
        @unknown default:
            return true
        }
    }
    
    // Get scheduled time for display
    var scheduledTime: Date? {
        guard let schedule = alarm.schedule else { return nil }
        
        switch schedule {
        case .fixed(let date):
            return date
        case .relative(let relative):
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            return Calendar.current.date(from: components)
        @unknown default:
            return nil
        }
    }
    
    // Get scheduled weekdays for display
    var scheduledWeekdays: Set<Locale.Weekday>? {
        guard let schedule = alarm.schedule else { return nil }
        
        switch schedule {
        case .relative(let relative):
            switch relative.repeats {
            case .weekly(let days):
                return Set(days)
            case .never:
                return nil
            @unknown default:
                return nil
            }
        case .fixed:
            return nil
        @unknown default:
            return nil
        }
    }
    
    // Timer duration for display
    var timerDuration: TimeInterval? {
        alarm.countdownDuration?.preAlert
    }
    
    // Check if it's a timer vs scheduled alarm
    var isTimer: Bool {
        alarm.schedule == nil && alarm.countdownDuration != nil
    }
    
    // Check if it's a scheduled alarm
    var isScheduled: Bool {
        alarm.schedule != nil
    }
}

// MARK: - Alarm Presentation State Tracking
extension ItsukiAlarm {
    struct AlarmPresentationState: Codable {
        var mode: Mode?
        var startDate: Date?
        var previouslyElapsedDuration: TimeInterval = 0
        
        enum Mode: String, Codable {
            case alert
            case countdown  
            case paused
        }
    }
    
    mutating func updatePresentationState(oldAlarm: Alarm) {
        let newMode: AlarmPresentationState.Mode? = switch (oldAlarm.state, alarm.state) {
        case (.scheduled, .countdown):
            .countdown
        case (.countdown, .paused):
            .paused
        case (_, .alerting):
            .alert
        default:
            presentationMode?.mode
        }
        
        if presentationMode?.mode != newMode {
            if newMode == .countdown && presentationMode?.startDate == nil {
                presentationMode = AlarmPresentationState(
                    mode: newMode,
                    startDate: Date(),
                    previouslyElapsedDuration: 0
                )
            } else {
                presentationMode?.mode = newMode
            }
        }
        
        // Track elapsed time for pause/resume functionality
        if oldAlarm.state == .countdown && alarm.state == .paused {
            if let startDate = presentationMode?.startDate {
                let elapsed = Date().timeIntervalSince(startDate)
                presentationMode?.previouslyElapsedDuration += elapsed
            }
        }
        
        if oldAlarm.state == .paused && alarm.state == .countdown {
            presentationMode?.startDate = Date()
        }
    }
}

// MARK: - Convenience Extensions
extension ItsukiAlarm {
    enum ItsukiAlarmType: CaseIterable {
        case alarm
        case timer
        case custom
        
        var displayName: String {
            switch self {
            case .alarm: "Alarm"
            case .timer: "Timer"
            case .custom: "Custom"
            }
        }
    }
    
    var alarmType: ItsukiAlarmType {
        return switch (alarm.countdownDuration, alarm.schedule) {
        case (nil, .some): .alarm
        case (.some, nil): .timer
        case (.some, .some): .custom
        case (nil, nil): .custom
        }
    }
}
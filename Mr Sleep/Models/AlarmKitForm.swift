import AlarmKit
import Foundation

struct AlarmKitForm {
    var label = ""
    
    var selectedDate = Date.now
    var selectedDays = Set<Locale.Weekday>()
    
    var selectedPreAlert = CountdownInterval()
    var selectedPostAlert = CountdownInterval()
    
    var selectedSecondaryButton: SecondaryButtonOption = .none
    var selectedSleepContext: MrSleepAlarmMetadata.SleepContext? = nil
    var selectedWakeUpReason: MrSleepAlarmMetadata.WakeUpReason = .general
    
    var preAlertEnabled = false
    var scheduleEnabled = false
    
    var isValidAlarm: Bool {
        (preAlertEnabled && selectedPreAlert.interval > 0) || scheduleEnabled
    }
    
    var localizedLabel: LocalizedStringResource {
        if label.isEmpty {
            if let context = selectedSleepContext {
                return LocalizedStringResource(stringLiteral: context.rawValue)
            }
            return LocalizedStringResource("Alarm")
        }
        return LocalizedStringResource(stringLiteral: label)
    }
    
    func isSelected(day: Locale.Weekday) -> Bool {
        selectedDays.contains(day)
    }
    
    enum SecondaryButtonOption: String, CaseIterable {
        case none = "None"
        case countdown = "Countdown"
        case openApp = "Open App"
        
        var description: String {
            switch self {
            case .none: "Only the Stop button is displayed in the alarm alert."
            case .countdown: "Displays the Repeat option when the alarm is triggered."
            case .openApp: "Displays the Open App button when the alarm is triggered."
            }
        }
    }
    
    struct CountdownInterval {
        var hour = 0
        var min = 15
        var sec = 0
        
        var interval: TimeInterval {
            TimeInterval(hour * 60 * 60 + min * 60 + sec)
        }
        
        var formattedString: String {
            if hour > 0 {
                return String(format: "%dh %dm %ds", hour, min, sec)
            } else if min > 0 {
                return String(format: "%dm %ds", min, sec)
            } else {
                return String(format: "%ds", sec)
            }
        }
    }
    
    // MARK: AlarmKit Properties
    
    var countdownDuration: Alarm.CountdownDuration? {
        let preAlertCountdown: TimeInterval? = if preAlertEnabled {
            selectedPreAlert.interval
        } else { nil }
        
        let postAlertCountdown: TimeInterval? = if secondaryButtonBehavior == .countdown {
            selectedPostAlert.interval
        } else { nil }
        
        guard preAlertCountdown != nil || postAlertCountdown != nil else { return nil }
        
        return .init(preAlert: preAlertCountdown, postAlert: postAlertCountdown)
    }
    
    var schedule: Alarm.Schedule? {
        guard scheduleEnabled else { return nil }
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        
        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return nil }
        
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        return .relative(.init(
            time: time,
            repeats: selectedDays.isEmpty ? .never : .weekly(Array(selectedDays))
        ))
    }
    
    var secondaryButtonBehavior: AlarmPresentation.Alert.SecondaryButtonBehavior? {
        switch selectedSecondaryButton {
        case .none: nil
        case .countdown: .countdown
        case .openApp: .custom
        }
    }
    
    var metadata: MrSleepAlarmMetadata {
        MrSleepAlarmMetadata(
            sleepContext: selectedSleepContext,
            wakeUpReason: selectedWakeUpReason
        )
    }
}

// MARK: - Quick Setup Extensions
extension AlarmKitForm {
    static func quickNap() -> AlarmKitForm {
        var form = AlarmKitForm()
        form.selectedSleepContext = .quickNap
        form.preAlertEnabled = true
        form.selectedPreAlert = CountdownInterval(hour: 0, min: 20, sec: 0)
        form.label = "Quick Nap"
        return form
    }
    
    static func powerNap() -> AlarmKitForm {
        var form = AlarmKitForm()
        form.selectedSleepContext = .powerNap
        form.preAlertEnabled = true
        form.selectedPreAlert = CountdownInterval(hour: 0, min: 30, sec: 0)
        form.label = "Power Nap"
        return form
    }
    
    static func shortSleep() -> AlarmKitForm {
        var form = AlarmKitForm()
        form.selectedSleepContext = .shortSleep
        form.preAlertEnabled = true
        form.selectedPreAlert = CountdownInterval(hour: 1, min: 30, sec: 0)
        form.label = "Short Sleep"
        return form
    }
    
    static func morningAlarm(at time: Date) -> AlarmKitForm {
        var form = AlarmKitForm()
        form.scheduleEnabled = true
        form.selectedDate = time
        form.selectedWakeUpReason = .work
        form.selectedSecondaryButton = .openApp
        form.label = "Morning Alarm"
        return form
    }
}
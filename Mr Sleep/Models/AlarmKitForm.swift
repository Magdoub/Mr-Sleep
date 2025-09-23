import AlarmKit
import Foundation

struct AlarmKitForm {
    var selectedDate = Date.now
    var scheduleEnabled = false
    
    var isValidAlarm: Bool {
        scheduleEnabled
    }
    
    var localizedLabel: LocalizedStringResource {
        return LocalizedStringResource("Alarm")
    }
    
    // MARK: AlarmKit Properties
    
    var schedule: Alarm.Schedule? {
        guard scheduleEnabled else { return nil }
        
        // Use local time zone to ensure correct hour/minute extraction
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
        
        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return nil }
        
        print("📅 Creating schedule for hour: \(hour), minute: \(minute)")
        print("📅 Original selectedDate: \(selectedDate)")
        print("📅 Extracted components: hour=\(hour), minute=\(minute)")
        
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        return .relative(.init(
            time: time,
            repeats: .never
        ))
    }
    
    var metadata: MrSleepAlarmMetadata {
        MrSleepAlarmMetadata(
            sleepContext: nil,
            wakeUpReason: .general
        )
    }
}
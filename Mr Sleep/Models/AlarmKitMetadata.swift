import AlarmKit
import Foundation

struct MrSleepAlarmMetadata: AlarmMetadata {
    let createdAt: Date
    let sleepContext: SleepContext?
    let wakeUpReason: WakeUpReason
    
    init(sleepContext: SleepContext? = nil, wakeUpReason: WakeUpReason = .general) {
        self.createdAt = Date.now
        self.sleepContext = sleepContext
        self.wakeUpReason = wakeUpReason
    }
    
    enum SleepContext: String, Codable, CaseIterable {
        case quickNap = "Quick Nap"
        case powerNap = "Power Nap"
        case shortSleep = "Short Sleep"
        case normalSleep = "Normal Sleep"
        case longSleep = "Long Sleep"
        case deepSleep = "Deep Sleep"
        
        var duration: TimeInterval {
            switch self {
            case .quickNap: return 20 * 60      // 20 minutes
            case .powerNap: return 30 * 60      // 30 minutes
            case .shortSleep: return 90 * 60    // 1.5 hours
            case .normalSleep: return 6 * 60 * 60   // 6 hours
            case .longSleep: return 8 * 60 * 60     // 8 hours
            case .deepSleep: return 9 * 60 * 60     // 9 hours
            }
        }
        
        var icon: String {
            switch self {
            case .quickNap: "powersleep"
            case .powerNap: "bolt.circle"
            case .shortSleep: "moon.circle"
            case .normalSleep: "bed.double.circle"
            case .longSleep: "moon.stars.circle"
            case .deepSleep: "zzz"
            }
        }
        
        var color: String {
            switch self {
            case .quickNap: "blue"
            case .powerNap: "orange" 
            case .shortSleep: "purple"
            case .normalSleep: "indigo"
            case .longSleep: "mint"
            case .deepSleep: "cyan"
            }
        }
    }
    
    enum WakeUpReason: String, Codable, CaseIterable {
        case general = "General"
        case work = "Work"
        case workout = "Workout"
        case appointment = "Appointment"
        case medication = "Medication"
        case meeting = "Meeting"
        case travel = "Travel"
        case event = "Event"
        
        var icon: String {
            switch self {
            case .general: "alarm"
            case .work: "briefcase"
            case .workout: "figure.run"
            case .appointment: "calendar"
            case .medication: "pills"
            case .meeting: "person.3"
            case .travel: "airplane"
            case .event: "star"
            }
        }
    }
}
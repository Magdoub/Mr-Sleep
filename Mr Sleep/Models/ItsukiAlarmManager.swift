import AlarmKit
import SwiftUI
import Foundation
import AppIntents

@Observable 
class ItsukiAlarmManager {
    typealias AlarmConfiguration = AlarmKit.AlarmManager.AlarmConfiguration<MrSleepAlarmMetadata>
    
    static let shared = ItsukiAlarmManager()
    
    @MainActor var runningAlarms: [ItsukiAlarm] = []
    @MainActor var recentAlarms: [ItsukiAlarm] = []
    @MainActor var isAlarmKitAvailable: Bool = true
    @MainActor var alarmKitError: AlarmKitError? = nil
    
    @ObservationIgnored private let alarmManager: AlarmKit.AlarmManager?
    @ObservationIgnored private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults persistence
    private let runningAlarmsKey = "ItsukiAlarmManager.runningAlarms"
    private let recentAlarmsKey = "ItsukiAlarmManager.recentAlarms"
    
    var error: (any Error)? = nil {
        didSet {
            if error != nil {
                showError = true
            }
        }
    }
    
    var showError: Bool = false {
        didSet {
            if !showError {
                error = nil
            }
        }
    }
    
    @MainActor var hasUpcomingAlarms: Bool {
        !runningAlarms.isEmpty
    }
    
    private init() {
        // Safely initialize AlarmManager
        if #available(iOS 17.0, *) {
            self.alarmManager = AlarmKit.AlarmManager.shared
            
            Task { @MainActor in
                initializeLocalAlarms()
            }
            initializeRemoteAlarms()
            observeAlarms()
            observeAuthorizationUpdates()
        } else {
            self.alarmManager = nil
            Task { @MainActor in
                self.isAlarmKitAvailable = false
                self.alarmKitError = .unavailable("AlarmKit requires iOS 17.0 or later")
            }
        }
    }
    
    // MARK: - Initialization
    
    @MainActor private func initializeLocalAlarms() {
        do {
            if let data = userDefaults.data(forKey: runningAlarmsKey) {
                let decoder = JSONDecoder()
                runningAlarms = try decoder.decode([ItsukiAlarm].self, from: data)
            }
        } catch {
            print("Failed to load running alarms: \(error)")
            runningAlarms = []
        }
        
        do {
            if let data = userDefaults.data(forKey: recentAlarmsKey) {
                let decoder = JSONDecoder()
                recentAlarms = try decoder.decode([ItsukiAlarm].self, from: data)
            }
        } catch {
            print("Failed to load recent alarms: \(error)")
            recentAlarms = []
        }
    }
    
    private func initializeRemoteAlarms() {
        guard let alarmManager = alarmManager else {
            print("AlarmManager is not available - skipping remote alarm initialization")
            return
        }
        
        Task { @MainActor in
            do {
                let remoteAlarms = try alarmManager.alarms
                combineLocalRemoteAlarms(localRunningAlarms: runningAlarms, remoteAlarms: remoteAlarms)
            } catch {
                print("Failed to fetch initial remote alarms: \(error)")
                self.alarmKitError = .authorizationFailed(error)
            }
        }
    }
    
    private func combineLocalRemoteAlarms(localRunningAlarms: [ItsukiAlarm], remoteAlarms: [Alarm]) {
        Task { @MainActor in
            var updatedRunningAlarms: [ItsukiAlarm] = []
            var updatedRecentAlarms = recentAlarms
            
            // Process remote alarms
            for remoteAlarm in remoteAlarms {
                if let existing = localRunningAlarms.first(where: { $0.id == remoteAlarm.id }) {
                    // Update existing alarm with new state
                    var updatedAlarm = existing
                    let oldAlarm = updatedAlarm.alarm
                    updatedAlarm.alarm = remoteAlarm
                    updatedAlarm.updatePresentationState(oldAlarm: oldAlarm)
                    updatedRunningAlarms.append(updatedAlarm)
                } else {
                    // New alarm from remote (possibly from previous session)
                    switch remoteAlarm.state {
                    case .scheduled, .countdown, .paused:
                        // Create ItsukiAlarm with default metadata for orphaned alarms
                        let itsukiAlarm = ItsukiAlarm(
                            alarm: remoteAlarm, 
                            metadata: MrSleepAlarmMetadata()
                        )
                        updatedRunningAlarms.append(itsukiAlarm)
                    case .alerting:
                        // Move to recent if alerting
                        let itsukiAlarm = ItsukiAlarm(
                            alarm: remoteAlarm,
                            metadata: MrSleepAlarmMetadata()
                        )
                        updatedRecentAlarms.append(itsukiAlarm)
                    @unknown default:
                        break
                    }
                }
            }
            
            // Remove alarms that no longer exist remotely
            let remoteIds = Set(remoteAlarms.map(\.id))
            updatedRunningAlarms = updatedRunningAlarms.filter { remoteIds.contains($0.id) }
            
            // Handle alarms that were removed from remote but exist locally
            let localIds = Set(localRunningAlarms.map(\.id))
            let removedIds = localIds.subtracting(remoteIds)
            
            for removedId in removedIds {
                if let removedAlarm = localRunningAlarms.first(where: { $0.id == removedId }) {
                    // Alarm was likely fired/completed, move to recent
                    updatedRecentAlarms.append(removedAlarm)
                }
            }
            
            runningAlarms = updatedRunningAlarms
            recentAlarms = updatedRecentAlarms
            
            // Persist changes
            saveAlarmsToUserDefaults()
        }
    }
    
    private func observeAlarms() {
        guard let alarmManager = alarmManager else {
            print("AlarmManager is not available - skipping alarm observation")
            return
        }
        
        Task {
            do {
                for await remoteAlarms in alarmManager.alarmUpdates {
                    await MainActor.run {
                        combineLocalRemoteAlarms(localRunningAlarms: runningAlarms, remoteAlarms: remoteAlarms)
                    }
                }
            } catch {
                await MainActor.run {
                    self.alarmKitError = .observationFailed(error)
                }
            }
        }
    }
    
    private func observeAuthorizationUpdates() {
        guard let alarmManager = alarmManager else {
            print("AlarmManager is not available - skipping authorization observation")
            return
        }
        
        Task {
            do {
                for await _ in alarmManager.authorizationUpdates {
                    // Handle authorization changes if needed
                    await checkAuthorization()
                }
            } catch {
                await MainActor.run {
                    self.alarmKitError = .authorizationFailed(error)
                }
            }
        }
    }
    
    // MARK: - Data Persistence
    
    @MainActor private func saveAlarmsToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let runningData = try encoder.encode(runningAlarms)
            userDefaults.set(runningData, forKey: runningAlarmsKey)
            
            let recentData = try encoder.encode(recentAlarms)
            userDefaults.set(recentData, forKey: recentAlarmsKey)
        } catch {
            print("Failed to save alarms: \(error)")
        }
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() async -> Bool {
        guard let alarmManager = alarmManager else {
            await MainActor.run {
                self.alarmKitError = .unavailable("AlarmManager is not available")
                self.isAlarmKitAvailable = false
            }
            return false
        }
        
        do {
            switch alarmManager.authorizationState {
            case .notDetermined:
                do {
                    let state = try await alarmManager.requestAuthorization()
                    let isAuthorized = state == .authorized
                    await MainActor.run {
                        if !isAuthorized {
                            self.alarmKitError = .authorizationDenied
                        }
                    }
                    return isAuthorized
                } catch {
                    await MainActor.run {
                        self.alarmKitError = .authorizationFailed(error)
                    }
                    return false
                }
            case .denied: 
                await MainActor.run {
                    self.alarmKitError = .authorizationDenied
                }
                return false
            case .authorized: 
                await MainActor.run {
                    self.alarmKitError = nil // Clear any previous errors
                }
                return true
            @unknown default: 
                await MainActor.run {
                    self.alarmKitError = .unknown("Unknown authorization state")
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.alarmKitError = .authorizationFailed(error)
            }
            return false
        }
    }
    
    // MARK: - Alarm Operations
    
    func addAlarm(
        id: UUID = UUID(),
        title: String,
        icon: String,
        metadata: MrSleepAlarmMetadata,
        alarmID: UUID,
        schedule: Alarm.Schedule
    ) async throws {
        
        let attributes = AlarmAttributes(
            presentation: createAlarmPresentation(metadata: metadata, title: title),
            metadata: metadata,
            tintColor: .accentColor
        )
        
        let configuration = AlarmConfiguration(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmID.uuidString),
            secondaryIntent: nil
        )
        
        try await scheduleAlarm(id: alarmID, configuration: configuration, metadata: metadata, title: title)
    }
    
    func addTimer(
        title: String,
        icon: String,
        metadata: MrSleepAlarmMetadata,
        alarmID: UUID,
        duration: TimeInterval
    ) async throws {
        
        let attributes = AlarmAttributes(
            presentation: createAlarmPresentation(metadata: metadata, title: title),
            metadata: metadata,
            tintColor: .accentColor
        )
        
        let configuration = AlarmConfiguration(
            countdownDuration: .init(preAlert: duration, postAlert: nil),
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmID.uuidString),
            secondaryIntent: RepeatIntent(alarmID: alarmID.uuidString)
        )
        
        try await scheduleAlarm(id: alarmID, configuration: configuration, metadata: metadata, title: title)
    }
    
    func addCustom(
        title: String,
        icon: String, 
        metadata: MrSleepAlarmMetadata,
        alarmID: UUID,
        schedule: Alarm.Schedule?,
        countdownDuration: Alarm.CountdownDuration?,
        secondaryIntent: (any LiveActivityIntent)?
    ) async throws {
        
        let attributes = AlarmAttributes(
            presentation: createAlarmPresentation(metadata: metadata, title: title),
            metadata: metadata,
            tintColor: .accentColor
        )
        
        let configuration = AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmID.uuidString),
            secondaryIntent: secondaryIntent
        )
        
        try await scheduleAlarm(id: alarmID, configuration: configuration, metadata: metadata, title: title)
    }
    
    private func scheduleAlarm(
        id: UUID,
        configuration: AlarmConfiguration,
        metadata: MrSleepAlarmMetadata,
        title: String
    ) async throws {
        
        guard let alarmManager = alarmManager else {
            await MainActor.run {
                self.alarmKitError = .unavailable("AlarmManager is not available")
                self.isAlarmKitAvailable = false
            }
            throw AlarmError.notAuthorized
        }
        
        guard await checkAuthorization() else {
            throw AlarmError.notAuthorized
        }
        
        do {
            let alarm = try await alarmManager.schedule(id: id, configuration: configuration)
            
            let itsukiAlarm = ItsukiAlarm(alarm: alarm, metadata: metadata)
            
            await MainActor.run {
                // Add all scheduled alarms to runningAlarms
                runningAlarms.append(itsukiAlarm)
                saveAlarmsToUserDefaults()
                // Clear any previous errors on successful scheduling
                self.alarmKitError = nil
            }
        } catch {
            await MainActor.run {
                self.alarmKitError = .schedulingFailed(error)
            }
            throw error
        }
    }
    
    func deleteAlarm(_ alarmID: UUID) async throws {
        // Cancel the alarm using the correct AlarmKit API
        if let alarmManager = alarmManager {
            try? alarmManager.cancel(id: alarmID)
        }
        
        // Remove from local storage
        await MainActor.run {
            runningAlarms.removeAll(where: { $0.id == alarmID })
            recentAlarms.removeAll(where: { $0.id == alarmID })
            saveAlarmsToUserDefaults()
        }
    }
    
    // Note: AlarmKit doesn't provide direct pause/resume/stop/countdown methods
    // These actions are handled through Live Activity buttons and App Intents
    // The state changes come through the alarmUpdates stream
    
    func stopAlarm(_ alarmID: UUID) async throws {
        // Cancel the alarm
        if let alarmManager = alarmManager {
            try? alarmManager.cancel(id: alarmID)
        }
        
        // Move from running to recent
        await MainActor.run {
            if let alarm = runningAlarms.first(where: { $0.id == alarmID }) {
                runningAlarms.removeAll(where: { $0.id == alarmID })
                recentAlarms.append(alarm)
                saveAlarmsToUserDefaults()
            }
        }
    }
    
    func pauseAlarm(_ alarmID: UUID) async throws {
        // AlarmKit handles pause through Live Activity - state updates come via alarmUpdates
        // This method exists for compatibility with App Intents
        print("Pause alarm \(alarmID) - handled by AlarmKit internally")
    }
    
    func resumeAlarm(_ alarmID: UUID) async throws {
        // AlarmKit handles resume through Live Activity - state updates come via alarmUpdates
        // This method exists for compatibility with App Intents
        print("Resume alarm \(alarmID) - handled by AlarmKit internally")
    }
    
    func repeatAlarm(_ alarmID: UUID) async throws {
        // AlarmKit handles repeat through Live Activity - state updates come via alarmUpdates
        // This method exists for compatibility with App Intents
        print("Repeat alarm \(alarmID) - handled by AlarmKit internally")
    }
    
    private func updateAlarmState(alarmID: UUID, to state: Alarm.State) async {
        await MainActor.run {
            guard let firstIndex = runningAlarms.firstIndex(where: { $0.id == alarmID }) else { return }
            
            var alarm = runningAlarms[firstIndex]
            let oldAlarm = alarm.alarm
            
            // Update the state (this is a workaround since we can't directly modify alarm.state)
            // In a real implementation, this would be updated by the alarmUpdates stream
            // alarm.alarm.state = state  // This property is read-only
            
            // For now, we'll update our presentation state manually
            alarm.updatePresentationState(oldAlarm: oldAlarm)
            runningAlarms[firstIndex] = alarm
            saveAlarmsToUserDefaults()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createAlarmPresentation(metadata: MrSleepAlarmMetadata, title: String) -> AlarmPresentation {
        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: .stopButton
        )
        
        let countdownContent = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: title),
            pauseButton: .pauseButton
        )
        
        let pausedContent = AlarmPresentation.Paused(
            title: "Paused",
            resumeButton: .resumeButton
        )
        
        return AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent)
    }
    
    // MARK: - Quick Access Properties
    
    @MainActor var runningTraditionalAlarms: [ItsukiAlarm] {
        runningAlarms.filter { $0.alarmType == .alarm }.sorted { $0.fireDate ?? Date.distantFuture < $1.fireDate ?? Date.distantFuture }
    }
    
    @MainActor var runningTimers: [ItsukiAlarm] {
        runningAlarms.filter { $0.alarmType == .timer }.sorted { $0.metadata.createdAt > $1.metadata.createdAt }
    }
    
    @MainActor var runningCustomAlarms: [ItsukiAlarm] {
        runningAlarms.filter { $0.alarmType == .custom }.sorted { $0.metadata.createdAt > $1.metadata.createdAt }
    }
}

// MARK: - Error Types
enum AlarmError: LocalizedError {
    case notAuthorized
    case invalidConfiguration
    case scheduleInPast
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Permission required to schedule alarms. Please enable in Settings."
        case .invalidConfiguration:
            return "Invalid alarm configuration. Please check your settings."
        case .scheduleInPast:
            return "Cannot schedule alarm in the past."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

enum AlarmKitError: LocalizedError {
    case unavailable(String)
    case initializationFailed(Error)
    case authorizationFailed(Error)
    case authorizationDenied
    case schedulingFailed(Error)
    case observationFailed(Error)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            return "AlarmKit is not available: \(message)"
        case .initializationFailed(let error):
            return "Failed to initialize AlarmKit: \(error.localizedDescription)"
        case .authorizationFailed(let error):
            return "AlarmKit authorization failed: \(error.localizedDescription)"
        case .authorizationDenied:
            return "Permission denied for AlarmKit. Please enable in Settings → Privacy & Security → Alarms."
        case .schedulingFailed(let error):
            return "Failed to schedule alarm: \(error.localizedDescription)"
        case .observationFailed(let error):
            return "Failed to observe alarm updates: \(error.localizedDescription)"
        case .unknown(let message):
            return "Unknown AlarmKit error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unavailable:
            return "AlarmKit requires iOS 17.0 or later. Please update your device."
        case .authorizationDenied:
            return "Go to Settings → Privacy & Security → Alarms and enable permission for this app."
        case .initializationFailed, .schedulingFailed, .observationFailed, .authorizationFailed:
            return "Try restarting the app or your device."
        case .unknown:
            return "Please try again or restart the app."
        }
    }
}

// MARK: - Button Extensions
extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }
    
    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }
    
    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }
    
    static var repeatButton: Self {
        AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
    }
    
    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
    }
}
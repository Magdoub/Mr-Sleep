import AlarmKit
import SwiftUI
import Foundation

@Observable 
class ItsukiAlarmManager {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<MrSleepAlarmMetadata>
    
    static let shared = ItsukiAlarmManager()
    
    @MainActor var runningAlarms: [ItsukiAlarm] = []
    @MainActor var recentAlarms: [ItsukiAlarm] = []
    
    @ObservationIgnored private lazy var alarmManager = AlarmManager.shared
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

    var authorizationState: AlarmManager.AuthorizationState {
        // Always return .notDetermined until we explicitly check authorization
        // This prevents triggering authorization popup during property access
        return .notDetermined
    }

    private var _alarmManagerInitialized: Bool = false
    
    private init() {
        print("🔵 ItsukiAlarmManager.init() called")
        initializeLocalAlarms()
        // Don't initialize remote alarms or start observations here to avoid authorization popup
        // These will be initialized later when authorization is granted
        print("🔵 ItsukiAlarmManager.init() completed")
    }
    
    // MARK: - Initialization
    
    private func initializeLocalAlarms() {
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
        // Only fetch remote alarms if authorization is already granted
        // This prevents authorization popup during app initialization
        guard alarmManager.authorizationState == .authorized else {
            print("Skipping remote alarm initialization - authorization not granted")
            return
        }

        do {
            let remoteAlarms = try alarmManager.alarms
            combineLocalRemoteAlarms(localRunningAlarms: runningAlarms, remoteAlarms: remoteAlarms)
        } catch {
            print("Failed to fetch initial remote alarms: \(error)")
        }
    }

    func startObservingAlarmsIfAuthorized() {
        // Mark that alarmManager is now safe to access
        _alarmManagerInitialized = true

        // Only start observing if authorization is granted
        guard alarmManager.authorizationState == .authorized else {
            print("Skipping alarm observations - authorization not granted")
            return
        }

        print("Starting alarm observations - authorization granted")
        initializeRemoteAlarms()
        observeAlarms()
        observeAuthorizationUpdates()
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
        Task {
            for await remoteAlarms in alarmManager.alarmUpdates {
                combineLocalRemoteAlarms(localRunningAlarms: runningAlarms, remoteAlarms: remoteAlarms)
            }
        }
    }
    
    private func observeAuthorizationUpdates() {
        Task {
            for await _ in alarmManager.authorizationUpdates {
                // Handle authorization changes if needed
                // Note: Don't auto-request authorization here to avoid popup during onboarding

                // If authorization was just granted, initialize remote alarms
                if alarmManager.authorizationState == .authorized {
                    initializeRemoteAlarms()
                }
            }
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveAlarmsToUserDefaults() {
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
        // Mark that alarmManager is now safe to access
        _alarmManagerInitialized = true

        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let state = try await alarmManager.requestAuthorization()
                let isAuthorized = state == .authorized
                if isAuthorized {
                    // Start observing alarms now that authorization is granted
                    startObservingAlarmsIfAuthorized()
                }
                return isAuthorized
            } catch {
                await MainActor.run {
                    self.error = error
                }
                return false
            }
        case .denied:
            return false
        case .authorized:
            return true
        @unknown default:
            return false
        }
    }

    func checkAuthorizationWithoutRequest() -> Bool {
        print("🟢 checkAuthorizationWithoutRequest() called")
        // Mark that alarmManager is now safe to access
        _alarmManagerInitialized = true

        print("🟢 About to access alarmManager.authorizationState")
        let state = alarmManager.authorizationState
        print("🟢 authorizationState = \(state)")

        switch state {
        case .notDetermined, .denied:
            return false
        case .authorized:
            return true
        @unknown default:
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
        
        try await schedule(id: alarmID, configuration: configuration, metadata: metadata, title: title)
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
        
        try await schedule(id: alarmID, configuration: configuration, metadata: metadata, title: title)
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
        
        try await schedule(id: alarmID, configuration: configuration, metadata: metadata, title: title)
    }
    
    private func schedule(
        id: UUID,
        configuration: AlarmConfiguration,
        metadata: MrSleepAlarmMetadata,
        title: String
    ) async throws {
        
        guard await checkAuthorization() else {
            throw AlarmError.notAuthorized
        }
        
        let alarm = try await alarmManager.schedule(id: id, configuration: configuration)
        
        let itsukiAlarm = ItsukiAlarm(alarm: alarm, metadata: metadata)
        
        await MainActor.run {
            if alarm.state == .timer || alarm.state == .countdown {
                runningAlarms.append(itsukiAlarm)
            } else {
                runningAlarms.append(itsukiAlarm)
            }
            saveAlarmsToUserDefaults()
        }
    }
    
    func deleteAlarm(_ alarmID: UUID) async throws {
        // Check if alarm exists in system
        if runningAlarms.contains(where: { $0.id == alarmID }) {
            try alarmManager.cancel(id: alarmID)
        } else {
            // Just remove from recent if not in system
            await MainActor.run {
                recentAlarms.removeAll(where: { $0.id == alarmID })
            }
        }
        
        await MainActor.run {
            runningAlarms.removeAll(where: { $0.id == alarmID })
            saveAlarmsToUserDefaults()
        }
    }
    
    func pauseAlarm(_ alarmID: UUID) async throws {
        try alarmManager.pause(id: alarmID)
        await updateAlarmState(alarmID: alarmID, to: .paused)
    }
    
    func resumeAlarm(_ alarmID: UUID) async throws {
        try alarmManager.resume(id: alarmID)
        await updateAlarmState(alarmID: alarmID, to: .countdown)
    }
    
    func stopAlarm(_ alarmID: UUID) async throws {
        try alarmManager.stop(id: alarmID)
        
        // Move from running to recent
        await MainActor.run {
            if let alarm = runningAlarms.first(where: { $0.id == alarmID }) {
                runningAlarms.removeAll(where: { $0.id == alarmID })
                recentAlarms.append(alarm)
                saveAlarmsToUserDefaults()
            }
        }
    }
    
    func repeatAlarm(_ alarmID: UUID) async throws {
        try alarmManager.countdown(id: alarmID)
        await updateAlarmState(alarmID: alarmID, to: .countdown)
    }
    
    func updateAlarm(
        _ existingAlarm: ItsukiAlarm,
        title: String,
        icon: String,
        metadata: MrSleepAlarmMetadata,
        schedule: Alarm.Schedule?,
        countdownDuration: Alarm.CountdownDuration?,
        secondaryIntent: (any LiveActivityIntent)?
    ) async throws {
        
        // First, cancel the existing alarm
        try alarmManager.cancel(id: existingAlarm.id)
        
        // Create new alarm with same ID but updated configuration
        let attributes = AlarmAttributes(
            presentation: createAlarmPresentation(metadata: metadata, title: title),
            metadata: metadata,
            tintColor: .accentColor
        )
        
        let configuration = AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: existingAlarm.id.uuidString),
            secondaryIntent: secondaryIntent
        )
        
        guard await checkAuthorization() else {
            throw AlarmError.notAuthorized
        }
        
        let updatedAlarm = try await alarmManager.schedule(id: existingAlarm.id, configuration: configuration)
        
        let updatedItsukiAlarm = ItsukiAlarm(alarm: updatedAlarm, metadata: metadata)
        
        await MainActor.run {
            // Remove old alarm from running alarms
            runningAlarms.removeAll(where: { $0.id == existingAlarm.id })
            
            // Add updated alarm
            runningAlarms.append(updatedItsukiAlarm)
            
            saveAlarmsToUserDefaults()
        }
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
    
    var runningTraditionalAlarms: [ItsukiAlarm] {
        runningAlarms.filter { $0.alarmType == .alarm }.sorted { $0.fireDate ?? Date.distantFuture < $1.fireDate ?? Date.distantFuture }
    }
    
    var runningTimers: [ItsukiAlarm] {
        runningAlarms.filter { $0.alarmType == .timer }.sorted { $0.metadata.createdAt > $1.metadata.createdAt }
    }
    
    var runningCustomAlarms: [ItsukiAlarm] {
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
# AlarmKit Framework - Product Requirements Document

## Executive Summary

AlarmKit is a comprehensive SwiftUI-based alarm management framework designed for iOS applications (WWDC 2025 compatible). This framework provides developers with a robust, customizable alarm system featuring traditional alarms, timers, and advanced UI components with Lock Screen and Dynamic Island integration.

## Architecture Overview

### Core Components

#### 1. AlarmManager

The central orchestration point between the application and the alarm daemon store. It exposes functions for:

- Scheduling alarms
- Snoozying alarms  
- Cancelling alarms
- Managing alarm lifecycle

**Key Implementation Detail:**

```swift
class ItsukiAlarmManager {
    static let shared = ItsukiAlarmManager()
    
    private let runningAlarmWay = "ItsukiAlarm.running"
    private let recentAlarmWay = "ItsukiAlarm.recent"
    // Manages data between main app and extension
    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: groupId) ?? UserDefaults.standard
    }
}
```

#### 2. AlarmPresentation & AlarmMetadata

**AlarmPresentation** contains the core alarm configuration:

- `alert`: Required - defines the actual UI presented to the user (lock screen UI and dynamic island)
- `countdown`: Optional - countdown UI content (not provided by framework)
- `paused`: Optional - pause UI content (reference only)

**AlarmMetadata** provides additional contextual information:

- Icon, title, and creation date
- Used for Widget UI implementation

#### 3. AlarmAttributes & AlarmPresentationState

These define the Live Activity infrastructure:

- **AlarmAttributes**: Static data for the alarm
- **AlarmPresentationState**: Dynamic state including:
  - `fireDate`: Countdown start time
  - `previouslyElapsedDuration`: Time elapsed before most recent resumption
  - `startDate`: Most recent countdown resumption date
  - `totalCountdownDuration`: Total countdown duration

## Implementation Steps

### Step 1: Initial Setup

#### 1.1 Add Usage Description

```xml
<key>NSAlarmKitUsageDescription</key>
<string>Alarm from ItsukiAlarm</string>
```

#### 1.2 Create App Group

- Required for data sharing between widget extension and main app
- Format: `group.ItsukiAlarm`

#### 1.3 Add Widget Extension

- Must include `CountdownDuration` capability
- System may dismiss alarms without this extension

### Step 2: Request Authorization

```swift
private func checkAuthorization() async throws {
    switch alarmManager.authorizationState {
    case .notDetermined:
        let state = try await alarmManager.requestAuthorization()
        if state != .authorized {
            throw _Error.noAuthorized
        }
    case .denied:
        throw _Error.noAuthorized
    case .authorized:
        return
    default:
        throw _Error.unknownAuthState
    }
}
```

### Step 3: Configure Alarm Structure

```swift
let configuration = AlarmConfiguration(
    schedule: schedule,
    attributes: attributes,
    stopIntent: StopIntent(alarmID: alarmID),
    secondaryIntent: snoozeEnabled ? RepeatIntent(alarmID: alarmID) : nil,
    sound: .default
)

let alarm = try await alarmManager.schedule(
    id: alarmID, 
    configuration: configuration
)
```

### Step 4: Schedule Implementation

#### 4.1 Traditional Alarm (Fixed Time)

```swift
func createAlarmSchedule(date: Date, repeats: Bool) -> Alarm.Schedule {
    let schedule = Alarm.Schedule.fixed(date)
    return schedule
}
```

#### 4.2 Timer with Countdown

```swift
func createTimerSchedule(date: Date, repeats: Bool) -> Alarm.Schedule {
    let relativeSchedule = Alarm.Schedule.relative(relativeSchedule)
    return schedule
}
```

### Step 5: Create App Intents

#### 5.1 StopIntent Implementation

```swift
struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else {
            throw ItsukiAlarmManager._Error.badAlarmID
        }
        Task {
            @MainActor in
            try ItsukiAlarmManager.shared.stopAlarm(id)
        }
        return .result()
    }
}
```

#### 5.2 RepeatIntent Implementation (Snooze)

```swift
struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        // Implement snooze logic
        // Default snooze duration: 9 minutes
        guard let id = UUID(uuidString: alarmID) else {
            throw ItsukiAlarmManager._Error.badAlarmID
        }
        Task {
            @MainActor in
            try ItsukiAlarmManager.shared.repeatAlarm(id)
        }
        return .result()
    }
}
```

### Step 6: Implement Live Activity UI

```swift
struct CountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            let attributes = context.attributes
            let state = context.state
            
            VStack {
                // Main widget UI
                switch presentationMode {
                case .countdown:
                    Text(timerInterval: countdown.startDate...countdown.startDate.addingTimeInterval(
                        countdown.totalCountdownDuration - countdown.previouslyElapsed
                    ))
                case .paused:
                    Text("Paused")
                case .alert:
                    HStack {
                        Button(intent: PauseIntent(alarmID: id)) {
                            Text("Pause")
                        }
                        Button(intent: StopIntent(alarmID: id)) {
                            Text("Stop")
                        }
                    }
                }
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region implementation
                DynamicIslandExpandedRegion(.leading) {
                    // Leading content
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Trailing content
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Bottom content
                }
            } compactLeading: {
                // Compact leading
            } compactTrailing: {
                // Compact trailing
            } minimal: {
                // Minimal view
            }
        }
    }
}
```

### Step 7: State Management

#### 7.1 Update Presentation State

```swift
func updatePresentationState(alarmID: UUID, to state: Alarm.State) {
    guard let firstIndex = self.runningAlarms.firstIndex(where: { 
        $0.id == alarmID 
    }) else { return }
    
    var newAlarm = self.runningAlarms[firstIndex].alarm
    newAlarm.state = state
    self.runningAlarms[firstIndex].alarm = newAlarm
    
    // Sync with UserDefaults
    self.runningAlarms = runningAlarms
    self.recentAlarms = recentAlarms
}
```

#### 7.2 Alarm State Enum

```swift
enum AlarmState {
    case scheduled
    case countdown
    case paused
    case alert
}
```

## Key Features

### What AlarmKit Provides

#### Logic-wise:

- ✅ Complete alarm daemon store management
- ✅ Running alarm persistence and updates
- ✅ Pre-defined ActivityAttributes and ContentState structures
- ✅ Live Activity lifecycle management
- ✅ Authorization state management

#### UI-wise:

- ✅ Lock screen presentation on alert fire
- ✅ Dynamic Island presentation on alert fire
- ✅ Customizable UI properties (text, colors, tint, images)

### What AlarmKit Does NOT Provide

#### Logic-wise:

- ❌ No storage for fired alarms (implement using daemon store)
- ❌ No direct alarm information retrieval APIs
- ❌ No built-in alarm history

#### UI-wise:

- ❌ No countdown timer UI for widgets/dynamic island
- ❌ No main app UI (must be implemented separately)
- ❌ No default alarm management screens

## Data Persistence Strategy

### Custom Data Store Requirements

1. **Display additional alarm information**
   - Schedule details
   - Countdown duration
   - Current state

2. **Track running/scheduled alarms**
   - Active alarms list
   - Scheduled alarms queue

3. **Maintain fired alarm history**
   - Completed alarms
   - Dismissed alarms
   - Snoozed count

### UserDefaults Integration

```swift
// Store alarm data
private func persistAlarms() {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(runningAlarms) {
        userDefaults.set(data, forKey: self.runningAlarmKey)
    }
}

// Retrieve alarm data  
private func loadAlarms() -> [ItsukiAlarm] {
    guard let data = userDefaults.data(forKey: self.runningAlarmKey),
          let alarms = try? JSONDecoder().decode([ItsukiAlarm].self, from: data) 
    else { return [] }
    return alarms
}
```

## Alarm Operations

### Core Operations

| Operation | Description | Effect on State |
|-----------|-------------|-----------------|
| `schedule` | Create new alarm | → scheduled |
| `cancel` | Delete alarm including repeats | → removed |
| `countdown` | Start/repeat timer | → countdown |
| `pause` | Pause countdown | → paused |
| `resume` | Resume from pause | → countdown |
| `stop` | Stop alarm | → removed/rescheduled |
| `snooze` | Delay alarm | → countdown |

### State Transitions

```
scheduled → countdown → paused
    ↓           ↓         ↓
    ↓       alert ←-------↓
    ↓           ↓
    ↓       stopped/rescheduled
    ↓           ↓
    └-----------↓
            countdown (snooze)
```

## Critical Implementation Notes

### Required Configurations

1. **App Group**: Essential for widget ↔ main app communication
2. **Countdown Duration Capability**: Mandatory to prevent system dismissal
3. **Info.plist entries**: NSAlarmKitUsageDescription required

### Best Practices

1. **AlarmManager Singleton**: Use shared instance for consistency
2. **State Synchronization**: Always update both AlarmManager and UserDefaults
3. **Error Handling**: Implement comprehensive error states
4. **Memory Management**: Clean up fired alarms regularly
5. **Testing**: Account for simulator limitations (no sound)

### Common Pitfalls to Avoid

- ❗ Forgetting to add widget extension = alarms may be dismissed
- ❗ Not implementing App Group = data sharing fails
- ❗ Missing authorization checks = runtime crashes
- ❗ Not handling state transitions = UI inconsistencies

## Testing Checklist

- [ ] Authorization flow (all states)
- [ ] Alarm scheduling (fixed & relative)
- [ ] Snooze functionality
- [ ] Pause/Resume operations
- [ ] Widget data synchronization
- [ ] Dynamic Island transitions
- [ ] Lock screen presentation
- [ ] App termination/restoration
- [ ] Background alarm firing
- [ ] Multiple alarm management

## Conclusion

This PRD provides a comprehensive technical blueprint for implementing AlarmKit. Follow the steps sequentially, ensure all required configurations are in place, and implement proper state management for a robust alarm system integration.

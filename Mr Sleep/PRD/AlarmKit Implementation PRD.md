# AlarmKit Implementation PRD
## Product Requirements Document for Mr Sleep iOS App

### Overview
Implement a complete AlarmKit-powered alarm system as a separate "AK nav" tab in Mr Sleep, providing real functional alarms that can trigger notifications using iOS 26's AlarmKit framework.

### Architecture Components

#### 1. New Navigation Tab
- Add "AK" tab to `MainTabView.swift` 
- Create dedicated AlarmKit section separate from existing alarm UI

#### 2. Core AlarmKit Files
- **AlarmKitView.swift** - Main UI with alarm list and configuration
- **AlarmKitViewModel.swift** - ObservableObject managing AlarmManager.shared
- **AlarmKitForm.swift** - Configuration structure for alarm setup
- **AlarmKitMetadata.swift** - Custom metadata for Mr Sleep alarms
- **AlarmKitIntents.swift** - App Intents for Live Activity controls

#### 3. Key Features Implementation
- **Real Alarm Scheduling**: Using AlarmManager.shared.schedule()
- **Live Activities**: Dynamic Island integration with countdown/controls
- **Multiple Alarm Types**: 
  - Traditional scheduled alarms
  - Countdown timers with pre/post alert
  - Custom button behaviors (snooze, open app)
- **Authorization Handling**: Proper permissions for AlarmKit
- **Real-time Updates**: Sync between app and widget extensions

#### 4. Technical Implementation
- **Custom ItsukiAlarm wrapper**: Enhanced Alarm structure with presentation state tracking
- **ItsukiAlarmManager**: Singleton managing alarm operations and data persistence
- **State Management**: Real-time alarm state updates (scheduled, countdown, paused, alerting)
- **App Intents**: Stop, Pause, Resume, Repeat, and OpenApp intents for Live Activities

#### 5. UI Components
- **Alarm Configuration Form**: Time pickers, repeat days, countdown durations
- **Alarm List**: Display of active alarms with state indicators
- **Control Buttons**: Stop, pause, resume functionality
- **Example Alarm Templates**: Quick setup options for common use cases

#### 6. Integration Points
- Maintain existing Mr Sleep functionality unchanged
- Add AlarmKit as additive feature in new tab
- Use consistent UI design patterns with Mr Sleep theme
- Leverage existing app structure and conventions

---

## Implementation To-Do List

### Phase 1: Project Structure Setup
- [ ] Create `Views/AlarmKit/` folder in project hierarchy
- [ ] Create `Models/AlarmKit/` folder for data structures
- [ ] Add AlarmKit import statements to project

### Phase 2: Core Data Models
- [ ] Create `AlarmKitMetadata.swift` - Custom metadata structure for Mr Sleep alarms
- [ ] Create `AlarmKitForm.swift` - Configuration structure for alarm setup UI
- [ ] Create `ItsukiAlarm.swift` - Enhanced wrapper around native Alarm with state tracking
- [ ] Add sleep-specific metadata fields (wake-up context, sleep cycle info)

### Phase 3: Manager Layer
- [ ] Create `ItsukiAlarmManager.swift` - Singleton class for alarm operations
- [ ] Implement data persistence with UserDefaults
- [ ] Add alarm state tracking properties (runningAlarms, recentAlarms)
- [ ] Implement core alarm operations:
  - [ ] `scheduleAlarm()` with authorization check
  - [ ] `deleteAlarm()` with cleanup
  - [ ] `pauseAlarm()` and `resumeAlarm()`
  - [ ] `toggleAlarm()` enable/disable
- [ ] Add real-time state update methods
- [ ] Implement alarm updates observer from AlarmManager.shared

### Phase 4: App Intents for Live Activities
- [ ] Create `AlarmKitIntents.swift` file
- [ ] Implement `StopIntent` for alarm dismissal
- [ ] Implement `PauseIntent` for countdown pause
- [ ] Implement `ResumeIntent` for countdown resume
- [ ] Implement `RepeatIntent` for restart functionality
- [ ] Implement `OpenAppIntent` for custom button behavior
- [ ] Add proper error handling and UUID conversion

### Phase 5: ViewModel Layer
- [ ] Create `AlarmKitViewModel.swift` - ObservableObject for UI state
- [ ] Implement alarm list management (alarmsMap)
- [ ] Add authorization request handling
- [ ] Create example alarm functions:
  - [ ] `scheduleAlertOnlyExample()`
  - [ ] `scheduleCountdownAlertExample()`
  - [ ] `scheduleCustomButtonAlertExample()`
- [ ] Implement alarm presentation creation logic
- [ ] Add alarm scheduling with Live Activities support

### Phase 6: UI Components
- [ ] Create `AlarmKitView.swift` - Main container view
- [ ] Implement alarm list display with state indicators
- [ ] Create `AlarmKitAddView.swift` - Alarm configuration form
- [ ] Add time picker components for countdown/schedule
- [ ] Implement weekday selection for recurring alarms
- [ ] Add secondary button configuration UI
- [ ] Create alarm cell component with state colors/tags
- [ ] Add example alarm menu buttons

### Phase 7: Form Components
- [ ] Create countdown section with hour/min/sec pickers
- [ ] Implement schedule section with date picker
- [ ] Add days of week selection component
- [ ] Create secondary button picker (None/Countdown/Open App)
- [ ] Add form validation for required fields
- [ ] Implement dynamic form sections (show/hide based on toggles)

### Phase 8: Navigation Integration
- [ ] Add "AK" tab to `MainTabView.swift`
- [ ] Set up tab bar icon and title
- [ ] Integrate AlarmKitView as tab content
- [ ] Ensure proper navigation flow
- [ ] Test tab switching and state preservation

### Phase 9: Authorization & Permissions
- [ ] Implement authorization state checking
- [ ] Add permission request flow on first alarm creation
- [ ] Handle denied permission state with user guidance
- [ ] Add proper error messaging for permission issues
- [ ] Test authorization flow on fresh install

### Phase 10: Live Activities Integration
- [ ] Configure AlarmAttributes with custom presentation
- [ ] Implement Dynamic Island countdown display
- [ ] Add Live Activity button functionality
- [ ] Test pause/resume from Lock Screen
- [ ] Verify stop/repeat actions work correctly
- [ ] Test custom "Open App" button behavior

### Phase 11: Testing & Validation
- [ ] Test alarm scheduling and triggering
- [ ] Verify countdown timers work correctly
- [ ] Test pause/resume functionality
- [ ] Validate Live Activity controls
- [ ] Test authorization flow
- [ ] Verify alarm persistence across app launches
- [ ] Test multiple concurrent alarms
- [ ] Validate alarm deletion and cleanup

### Phase 12: UI Polish & Integration
- [ ] Apply Mr Sleep design theme to AlarmKit UI
- [ ] Ensure consistent color scheme and typography
- [ ] Add proper loading states and animations
- [ ] Implement error handling UI
- [ ] Add empty state for no alarms
- [ ] Test accessibility features
- [ ] Verify dark mode compatibility

### Phase 13: Final Integration
- [ ] Build and test complete implementation
- [ ] Verify no conflicts with existing Mr Sleep features
- [ ] Test on physical device for alarm notifications
- [ ] Validate Live Activities on Lock Screen
- [ ] Run full app regression testing
- [ ] Update project documentation

---

## Authorization Flow Details

### When Authorization Popup Appears
The authorization popup will appear at **the first time the user tries to schedule an alarm**.

#### Specific Trigger Points
1. **First Alarm Creation**: When user taps "Add" on their first alarm configuration
2. **App Launch Check**: Can optionally be requested on app startup (not recommended)
3. **Settings Access**: If user tries to access alarm features without permission

#### User Experience Flow
1. User opens AlarmKit tab → No popup yet
2. User configures their first alarm → No popup yet  
3. User taps "Schedule Alarm" → **Authorization popup appears**
4. User grants permission → Alarm is scheduled
5. Future alarms → No popup (already authorized)

---

## Technical Architecture Details

### ItsukiAlarm Wrapper
Enhanced wrapper around native `Alarm` providing:
- **Presentation State Tracking**: Current mode (alert, countdown, paused)
- **Enhanced State Information**: fireDate, startDate, previouslyElapsedDuration
- **UI Synchronization**: Bridges AlarmKit internal state with UI needs

### ItsukiAlarmManager Singleton
Central coordinator addressing AlarmKit limitations:
- **Data Persistence**: UserDefaults storage for custom data
- **State Management**: Manual state tracking for real-time updates  
- **Bridge to AlarmKit**: Wraps native AlarmManager.shared operations
- **Custom Operations**: Enhanced CRUD operations with metadata

This architecture is necessary because native AlarmKit only provides limited state information (id, schedule, countdownDuration) but UI requires rich real-time state tracking.

---

## Success Criteria

### Functional Requirements
- [ ] Real alarms that trigger iOS notifications
- [ ] Live Activities with Dynamic Island integration
- [ ] Pause/resume countdown functionality
- [ ] Multiple alarm types (scheduled, countdown, custom)
- [ ] Proper authorization handling
- [ ] Data persistence across app launches

### Non-Functional Requirements
- [ ] Consistent with Mr Sleep UI design
- [ ] No conflicts with existing features
- [ ] Responsive real-time updates
- [ ] Accessible and user-friendly
- [ ] Proper error handling and edge cases

### Integration Requirements
- [ ] Seamless tab navigation
- [ ] Preserved existing Mr Sleep functionality
- [ ] Consistent app performance
- [ ] Proper iOS 26+ compatibility
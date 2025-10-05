# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mr Sleep is a pure SwiftUI iOS app that calculates optimal wake-up times based on sleep cycle science. The app uses 90-minute sleep cycles and accounts for 15 minutes to fall asleep.

## ⚠️ AUTO-APPROVAL MODE ENABLED

**CURRENT WORKFLOW**: Claude can make changes automatically without prior approval.

**AUTO-APPROVED OPERATIONS** - All operations can proceed without explicit approval:
   - Code modifications
   - File creation/deletion
   - Configuration changes
   - Documentation updates
   - Git commits
   - Bash commands
   - Any other file system operations

**Working Mode:** Claude will explain what was done after making changes, rather than asking for permission beforehand.

## 🔍 AUTO-APPROVAL: Review After Changes

**CURRENT MODE**: Claude makes changes first, then explains what was done.

1. **Proceed with changes immediately** - Make necessary modifications without waiting
2. **Explain changes clearly after completion** - Describe what was modified and why
3. **Apply to all operations** - All changes are auto-approved

**This applies to:**
- All code modifications
- File creation or deletion
- Configuration updates
- Documentation changes
- Git operations
- Any file system operations
- Bash commands

**Remember**: User has enabled auto-approval for all operations.

## Build and Development Commands

```bash
# Open project in Xcode
open "Mr Sleep.xcodeproj"

# Build for physical device (iPhone 3)
~/Desktop/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "Mr Sleep.xcodeproj" -scheme "Mr Sleep" -destination "name=iPhone (3)" build
```

## Xcode Configuration

**IMPORTANT**: Always use the desktop Xcode installation:
- **Xcode Path**: `~/Desktop/Xcode.app` 
- **xcodebuild Path**: `~/Desktop/Xcode.app/Contents/Developer/usr/bin/xcodebuild`

All build commands should use the full path to the desktop Xcode.app installation to ensure compatibility and avoid conflicts with multiple Xcode versions.

## Architecture

### Framework and Dependencies
- **Pure SwiftUI** application with SwiftUI App lifecycle
- **AlarmKit framework** integration for real alarm scheduling and notifications
- **iOS 26.0+ minimum**, iPhone-only target
- **Bundle ID**: `com.magdoub.Mr-Sleeper`

### Core Architecture Pattern
- **MVVM-like structure** with singleton business logic
- **SleepCalculator.shared** - Singleton containing all sleep calculation logic
- **SleepNowView** - Main sleep calculation UI with embedded supporting components
- **State-driven UI** using SwiftUI `@State` properties extensively

### Key Components
- `Mr_SleepApp.swift` - App entry point with dark mode configuration
- `MainTabView.swift` - 5-tab navigation container managing app navigation
- `SleepNowView.swift` - Main sleep calculation UI with onboarding and supporting views
- `SingleAlarmView.swift` - Dedicated single alarm experience with AlarmKit integration
- `AlarmKitView.swift` - AlarmKit alarm management with full CRUD operations
- `AlarmKitViewModel.swift` - AlarmKit integration layer and alarm scheduling
- `SettingsView.swift` - User preferences and app configuration
- `SleepCalculator.swift` - Business logic singleton for sleep calculations
- `WakeUpTimeButton.swift` - Reusable button component for time display
- `SleepGuideView.swift` - Educational overlay about sleep hygiene

### Business Logic
- **Sleep cycles**: 90 minutes each (1-6 cycles supported)
- **Fall asleep buffer**: 15 minutes automatically added
- **Smart category ordering**: Time-based priority (7PM-6AM: Full Recharge first, 6AM-7PM: Quick Boost first)
- **Recommended sleep**: 4.5-6 hours highlighted as optimal
- **Real-time updates**: Timer publishes minute-level updates to UI
- **AlarmKit integration**: Real alarm scheduling with iOS notifications
- **Alarm ID tracking**: UUID-based reliable alarm creation and deletion
- **Alarm data management**: Create, edit, delete, toggle alarms with AlarmKit
- **Sound selection**: Multiple alarm tones with preview functionality
- **Enhanced UX**: Selection-based controls, haptic feedback, and optimized loading animations

## Code Patterns and Conventions

### SwiftUI Patterns
- Extensive use of `@State` for local UI state management
- `Timer.publish` for real-time clock updates
- LazyVGrid for efficient layout of time buttons
- Conditional rendering with SwiftUI's declarative syntax

### Styling Approach
- Custom dark blue gradient theme throughout
- Rounded corners and consistent spacing
- Grid-based layouts (2x2 for main times, 3-column for additional)
- Smooth animations and transitions

### State Management
- All UI state lives in SleepNowView as `@State` properties
- Business logic centralized in SleepCalculator singleton
- No external state management frameworks used

## Testing

**No testing infrastructure currently exists**. To add tests:
- Create new test targets in Xcode
- Focus unit tests on SleepCalculator logic
- Consider UI tests for core user flows

## Git Workflow

### Repository Information
- **Git Repository Location**: `/Users/magdoub/Documents/iOS projects/Mr Sleep/.git` (CONFIRMED: Git repo exists)
- **Working Directory for Git Commands**: `/Users/magdoub/Documents/iOS projects/Mr Sleep`
- **Remote Repository**: https://github.com/Magdoub/Mr-Sleep
- **Manual Commits**: Claude Code only commits when explicitly requested by user

### Commit Strategy
- **ONLY COMMIT WHEN EXPLICITLY REQUESTED**: Do not commit changes automatically
- **WAIT FOR USER INSTRUCTION**: Only create git commits when the user specifically asks for it
- **MANDATORY**: When committing, create clear, descriptive commit messages
- Commit messages should explain what was changed and why
- Include Claude Code attribution in all commit messages when committing
- Use present tense and imperative mood (e.g., "Add feature X", "Fix bug in Y", "Update Z configuration")

### Detailed Commit Guidelines

#### Commit Message Format
```
<type>(<scope>): <description>

<body>

<footer>
```

#### Commit Types
- **feat**: New feature or functionality
- **fix**: Bug fix
- **refactor**: Code refactoring without changing functionality
- **style**: Code formatting, missing semicolons, etc.
- **docs**: Documentation changes
- **test**: Adding or updating tests
- **chore**: Build process, auxiliary tool changes
- **perf**: Performance improvements
- **ci**: Continuous integration changes

#### Scope Examples
- **ui**: User interface changes
- **data**: Data models and persistence
- **alarm**: Alarm functionality
- **tracking**: Sleep tracking features
- **analytics**: Sleep analytics and insights
- **notifications**: Push notifications
- **health**: HealthKit integration
- **config**: Configuration and settings

#### Commit Message Examples
```
feat(sleep-tracking): Add sleep session logging with quality ratings

- Implement SleepSession data model with start/end times
- Add sleep quality rating (1-5 stars) and notes
- Create SleepTrackingManager singleton for data persistence
- Add UI for logging sleep sessions in ContentView

Closes #123
```

```
fix(alarm): Resolve alarm not triggering on device

- Fix AVAudioSession configuration for background audio
- Update alarm permissions handling
- Add proper error handling for alarm setup failures

Fixes #456
```

```
refactor(ui): Extract sleep analytics into separate view component

- Move analytics logic from ContentView to SleepAnalyticsView
- Improve code organization and reusability
- Maintain existing functionality while improving structure
```

#### ⚠️ IMPORTANT: Keep Commit Messages Short
**To avoid terminal hanging issues, prefer SHORT commit messages:**
- ✅ GOOD: `"Add alarm navigation feature"`
- ✅ GOOD: `"Fix popup dismiss behavior"`
- ✅ GOOD: `"Update tab navigation flow"`
- ❌ AVOID: Multi-line messages with bullets and special characters
- ❌ AVOID: Very long descriptions that cause terminal to hang

#### Commit Frequency Rules
1. **Only commit when user requests it** - no automatic commits
2. **Wait for explicit instruction** before creating any commits
3. **Group related changes** logically when committing
4. **Each commit should be meaningful** and well-described
5. **Commits are user-controlled** - never commit without permission

#### Pre-Commit Checklist
- [ ] All changes are tested and working
- [ ] Code follows project conventions
- [ ] Commit message follows the format above
- [ ] No temporary files or debug code left behind
- [ ] Changes are logically grouped in the commit

#### Post-Commit Actions
- Push commits to remote repository immediately
- Update any related issues or pull requests
- Document any breaking changes in commit body

## Development Notes

### Project Structure
```
Mr Sleep/
├── App/
│   ├── Mr_SleepApp.swift - App configuration and launch
│   └── MainTabView.swift - 5-tab navigation container
│
├── Views/
│   ├── Sleep/
│   │   ├── SleepNowView.swift - Primary sleep calculation UI with embedded views:
│   │   │   ├── OnboardingView - First-time user onboarding
│   │   │   ├── CalculatingWakeUpTimesView - Loading animation
│   │   │   └── FinishingUpView - Completion animation
│   │   ├── SingleAlarmView.swift - Single alarm experience with AlarmKit integration
│   │   ├── SleepGuideView.swift - Sleep education overlay
│   │   └── WakeUpTimeButton.swift - Reusable time selection component
│   ├── AlarmKit/
│   │   ├── AlarmKitView.swift - AlarmKit alarm management interface
│   │   ├── AlarmKitViewModel.swift - AlarmKit integration and scheduling
│   │   ├── AlarmKitAddView.swift - Alarm creation interface
│   │   └── AlarmKitEditView.swift - Alarm editing interface
│   └── Settings/
│       └── SettingsView.swift - App configuration
│
├── Models/
│   ├── SleepCalculator.swift - Core business logic
│   ├── AlarmKit/
│   │   ├── AlarmKitForm.swift - Alarm form data model
│   │   ├── AlarmKitMetadata.swift - Alarm metadata definitions
│   │   ├── AlarmKitIntents.swift - App intent integrations
│   │   ├── ItsukiAlarm.swift - Enhanced alarm data model
│   │   └── ItsukiAlarmManager.swift - Alarm management wrapper
│   └── Legacy alarm models (for reference)
│
├── Resources/
│   ├── Audio/
│   │   ├── morning-alarm-clock.mp3
│   │   ├── smooth-alarm-clock.mp3
│   │   └── alarm-clock.mp3
│   ├── Assets.xcassets/ - App icons and 3D moon icons
│   └── LaunchScreen.storyboard
│
├── Supporting Files/
│   └── Mr Sleep.entitlements
│
└── Preview Content/
    └── Preview Assets.xcassets/ - SwiftUI preview assets
```

### UI/UX Features
- **5-tab navigation**: Sleep Now, AlarmKit, Settings, Single, Additional tab
- **Real-time clock** with minute-level updates and animations
- **Streamlined onboarding flow** with 3-step interactive introduction and consolidated permission handling
- **Optimized loading animations** for wake-up time calculations (2.3s with haptic feedback)
- **Educational sleep guide** overlay with sleep hygiene tips
- **Smart categorized wake-up times** with time-based priority ordering (Quick Boost, Recovery, Full Recharge)
- **Enhanced single alarm experience**: Dedicated tab with countdown timers, progress rings, and selection-based adjustments
- **AlarmKit integration**: Real iOS notifications and alarm scheduling
- **Complete alarm management**: Create, edit, delete, toggle alarms with full functionality
- **UUID-based alarm tracking**: Reliable alarm deletion and management
- **Updated 3D icon assets** with alarm bell and rotating moon icons
- **Rich gradient backgrounds** and smooth spring animations
- **Sound preview**: Play alarm sounds when selecting them in the UI
- **Interactive breathing animations** and floating "zzz" effects
- **Haptic feedback integration**: Tactile responses for interactions and completion states
- **Selection-based controls**: OR logic for adjustment buttons with visual feedback

### Platform Specifics
- iPhone-only application (no iPad/Mac support)
- Portrait orientation assumed
- Dark mode preferred (configured in app launch)
- Uses native iOS date/time formatting

### Extension Opportunities
- **Testing infrastructure** - Add unit tests for SleepCalculator and UI tests for core flows
- **iPad support** - Add adaptive layouts for larger screens
- **Apple Watch companion** - Extend sleep tracking to watch
- **Internationalization** - Support multiple languages (currently English-only)
- **HealthKit integration** - Sleep data synchronization
- **Enhanced 3D animations** - More interactive moon phases and sleep visualizations

## Version History

### Version 4.2 (Current) - Smooth Alarm Setup & Permission Flow

**✨ Alarm Setup Loading State & Authorization Fix (October 2025):**
- ✅ **Smooth alarm setup loading**: Beautiful loading animation during alarm creation with "Setting up your alarm..." message
- ✅ **Success animation**: "Alarm set!" confirmation with haptic feedback and green checkmark before transitioning to active alarm
- ✅ **Fixed authorization flow**: Proper async permission handling that waits for user response to system popup
- ✅ **Consistent permission denial UX**: Shows settings sheet on first-time denial (matches returning user experience)
- ✅ **Loading phases**: Two-phase loading (loading → success) with smooth animations and transitions
- ✅ **No more UI glitches**: Loading state stays visible during permission request, prevents jarring "flash to main page"
- ✅ **State pollution fix**: Authorization request happens BEFORE ViewModel initialization to prevent premature state changes

**🔧 Technical Implementation:**
- **AlarmSetupLoadingView**: New loading component with rotating ring, pulsing alarm bell icon, animated dots, and success checkmark
- **AlarmSetupPhase enum**: Tracks loading phases (`.loading` and `.success`) for proper animation sequencing
- **SingleAlarmState.settingUpAlarm**: New state case for loading during alarm setup
- **Authorization order fix**: `checkAuthorization()` called BEFORE `viewModelContainer.initializeIfNeeded()` to prevent state pollution
- **Consistent denial handling**: Both first-time and returning users see permission sheet when permission denied
- **Accessibility support**: All animations respect `reduceMotion` accessibility setting

### Version 4.1 - Enhanced UX and Smart Priority System

**🎯 Smart Priority & User Experience (September 2025):**
- ✅ **Time-based category priority**: Dynamic ordering based on time of day (7PM-6AM: Full Recharge first, 6AM-7PM: Quick Boost first)
- ✅ **Improved permission flow**: Consolidated dual permission popups into single elegant modal with gradient design
- ✅ **Selection-based adjustment buttons**: OR logic for alarm adjustments (only one selectable at a time) with haptic feedback
- ✅ **Enhanced visual design**: Replaced Moon icon with alarm-bell-3D-icon, non-clickable sleep cycle info
- ✅ **Optimized loading experience**: Reduced animation time from 2.5s to 2.3s with haptic feedback completion
- ✅ **Refined copy**: Updated Quick Boost tagline to "Recharge without feeling like a zombie"
- ✅ **Updated 3D assets**: Refreshed alarm bell icon with improved visual quality

**🔧 Technical Implementation:**
- **SleepCalculator.swift**: Added `getDynamicCategoryOrder()` for intelligent time-based category prioritization
- **SingleAlarmView.swift**: Enhanced with selection-based UI patterns, haptic feedback integration, and streamlined permission handling
- **AlarmPermissionSheet**: Redesigned with gradient backgrounds, spring animations, and 3D icon integration
- **Loading animations**: Optimized timing calculations and added tactile feedback for completion states

### Version 4.0 - Stable 5-Tab AlarmKit Integration

**🚀 AlarmKit Integration & 5-Tab Navigation (September 2025):**
- ✅ **5-tab navigation**: Sleep Now, AlarmKit, Settings, Single, Additional tab structure
- ✅ **SingleAlarmView AlarmKit integration**: Real alarm scheduling with iOS notifications
- ✅ **UUID-based alarm tracking**: Reliable alarm creation and deletion using unique identifiers
- ✅ **Enhanced AlarmKitViewModel**: Added `scheduleAlarmWithID` method for precise alarm management
- ✅ **Improved data persistence**: SingleAlarmData now includes alarm IDs for reliable tracking
- ✅ **Fixed alarm deletion**: Alarms properly removed when canceled from Single tab
- ✅ **Backward compatibility**: Existing alarms without IDs still supported with fallback deletion
- ✅ **Real notifications**: Alarms now actually trigger iOS system notifications

**🔧 Technical Improvements:**
- **SingleAlarmData**: Enhanced with optional `alarmID` field and backward-compatible initializer
- **SingleAlarmState**: Updated to include alarm ID in active state for reliable tracking
- **AlarmKit scheduling**: Direct integration with iOS notification system
- **Error handling**: Improved feedback for alarm creation success/failure
- **Console logging**: Enhanced debugging with detailed alarm lifecycle logs

### Version 3.3 - Project Organization & Cleanup

**🗂️ Project Organization (September 2025):**
- ✅ **Organized folder structure**: Implemented clean MVVM-style organization with App/, Views/, Models/, Resources/ folders
- ✅ **Removed unused files**: Deleted backup files, build artifacts, unused extensions, and dead code
- ✅ **Fixed build issues**: Resolved file path conflicts and asset catalog references
- ✅ **Updated project configuration**: Corrected Xcode project structure and build settings
- ✅ **Maintained functionality**: All features preserved while improving maintainability

### Version 3.2 - Codebase Cleanup

**🧹 Code Cleanup (September 2025):**
- ✅ **Removed duplicate code**: Deleted unused `ContentView.swift` (1,189 lines)
- ✅ **Consolidated views**: Moved all UI components into `SleepNowView.swift`
- ✅ **Removed unused components**: Deleted `AlarmOverlayManager`, `AlarmCreationView`, `AlarmActivityAttributes`
- ✅ **Simplified architecture**: Direct `AlarmManager` integration without overlay layers
- ✅ **Maintained functionality**: All features preserved while reducing codebase by ~1,300 lines

**✅ What Currently Works:**
- 🎨 **Complete AlarmKit integration**: Full alarm management with real iOS notifications
- 🎵 **Sound selection**: Choose between Morning, Smooth, and Classic alarm tones with preview
- 💾 **Data persistence**: Alarms saved with AlarmKit and UUID tracking
- 🔄 **Smart sleep calculations**: Dynamic category ordering based on time of day for optimal recommendations
- 📱 **Enhanced single alarm experience**: Dedicated tab with countdown, progress visualization, and haptic feedback
- 🎯 **Reliable alarm management**: Create, edit, delete, toggle with UUID-based tracking
- 🎭 **Streamlined onboarding**: 3-step interactive introduction with improved permission flow
- 🌙 **Rich 3D animations**: Rotating moon icons, breathing effects, and updated alarm bell assets
- 🔔 **Real notifications**: Alarms actually trigger iOS system notifications
- 🎮 **Tactile feedback**: Haptic feedback for interactions and completion states
- 🎨 **Polished UI/UX**: Selection-based controls, gradient designs, and optimized loading times

**🔧 Current Technical Implementation:**
- **SingleAlarmView**: Complete alarm experience with AlarmKit integration, UUID tracking, and enhanced UX patterns
- **AlarmKitViewModel**: Enhanced with `scheduleAlarmWithID` for reliable alarm management
- **AlarmKitView**: Full AlarmKit alarm management interface
- **SleepCalculator**: Intelligent time-based category prioritization system
- **5-tab navigation**: Sleep Now, AlarmKit, Settings, Single, Additional with improved visual hierarchy

### Version 3.1 (Build 3) - Feature Complete
- Complete alarm UI implementation
- Sound selection and preview functionality
- Automatic navigation between tabs
- Data persistence system

### Version 3.0 (Build 2) - Initial Release
- Basic alarm UI implementation
- Sleep calculation features
- Initial data storage system
- add to memory: auto approval
- add what I told you to memory
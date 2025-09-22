# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mr Sleep is a pure SwiftUI iOS app that calculates optimal wake-up times based on sleep cycle science. The app uses 90-minute sleep cycles and accounts for 15 minutes to fall asleep.

## ⚠️ CRITICAL: Approval Required Before Any Changes

**MANDATORY WORKFLOW**: Before making ANY changes to this codebase, Claude MUST:

1. **Explain exactly what will be done** - Describe the specific changes, files to be modified, and the reasoning
2. **Wait for explicit user approval** - Do not proceed until the user confirms with "yes" or similar approval
3. **Apply to ALL changes** - This includes:
   - Code modifications
   - File creation/deletion
   - Configuration changes
   - Documentation updates
   - Git commits
   - Any other file system operations

**EXCEPTION: Bash Commands** - Diagnostic, build, test, and file listing commands can be executed without explicit approval.

**Example workflow:**
```
Claude: "I will add a new function to AlarmManager.swift to handle snooze functionality. This involves adding a snooze() method and updating the alarm state management. Do you approve?"

User: "yes"

Claude: [Proceeds with the approved changes]
```

**No exceptions** - Every change requires prior explanation and approval.

## 🔍 MANDATORY: Always Ask for Review

**CRITICAL REMINDER**: Before making ANY modifications to this codebase, Claude MUST:

1. **Stop and ask for review** - Never proceed directly with changes
2. **Explain the planned changes clearly** - What files will be modified and why
3. **Wait for explicit "yes" or approval** - Do not assume permission
4. **Apply to every single change** - No matter how small or obvious it seems

**This applies to:**
- All code modifications
- File creation or deletion
- Configuration updates
- Documentation changes
- Git operations
- Any file system operations

**EXCEPTION:** Bash commands for diagnostics, builds, tests, and file operations can proceed without approval.

**Remember**: The user wants to review and approve every change before it happens.

## Build and Development Commands

```bash
# Open project in Xcode
open "Mr Sleep.xcodeproj"

# Build for iOS Simulator using Xcode
~/Desktop/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "Mr Sleep.xcodeproj" -scheme "Mr Sleep" -destination "platform=iOS Simulator,name=iPhone 15" build

# Build for device
~/Desktop/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "Mr Sleep.xcodeproj" -scheme "Mr Sleep" -destination "generic/platform=iOS" build
```

## Xcode Configuration

**IMPORTANT**: Always use the desktop Xcode installation:
- **Xcode Path**: `~/Desktop/Xcode.app` 
- **xcodebuild Path**: `~/Desktop/Xcode.app/Contents/Developer/usr/bin/xcodebuild`

All build commands should use the full path to the desktop Xcode.app installation to ensure compatibility and avoid conflicts with multiple Xcode versions.

## Architecture

### Framework and Dependencies
- **Pure SwiftUI** application with SwiftUI App lifecycle
- **No external dependencies** - uses only SwiftUI and Foundation
- **iOS 26.0+ minimum**, iPhone-only target
- **Bundle ID**: `com.magdoub.Mr-Sleeper`

### Core Architecture Pattern
- **MVVM-like structure** with singleton business logic
- **SleepCalculator.shared** - Singleton containing all sleep calculation logic
- **SleepNowView** - Main sleep calculation UI with embedded supporting components
- **State-driven UI** using SwiftUI `@State` properties extensively

### Key Components
- `Mr_SleepApp.swift` - App entry point with dark mode configuration
- `MainTabView.swift` - Tab bar container managing app navigation
- `SleepNowView.swift` - Main sleep calculation UI with onboarding and supporting views
- `AlarmsView.swift` - Alarm management with native iOS Clock app experience
- `SettingsView.swift` - User preferences and app configuration
- `AlarmManager.swift` - Alarm data storage and UI management  
- `SleepCalculator.swift` - Business logic singleton for sleep calculations
- `WakeUpTimeButton.swift` - Reusable button component for time display
- `SleepGuideView.swift` - Educational overlay about sleep hygiene
- `AlarmDismissalView.swift` - UI component for alarm dismissal

### Business Logic
- **Sleep cycles**: 90 minutes each (3-8 cycles supported)
- **Fall asleep buffer**: 15 minutes automatically added
- **Recommended sleep**: 4.5-6 hours highlighted as optimal
- **Real-time updates**: Timer publishes minute-level updates to UI
- **Alarm creation**: One-tap alarm creation from sleep calculations
- **Alarm data management**: Create, edit, delete, toggle alarms
- **Sound selection**: Multiple alarm tones with preview functionality

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
│   └── MainTabView.swift - Tab navigation container
│
├── Views/
│   ├── Sleep/
│   │   ├── SleepNowView.swift - Primary sleep calculation UI with embedded views:
│   │   │   ├── OnboardingView - First-time user onboarding
│   │   │   ├── CalculatingWakeUpTimesView - Loading animation
│   │   │   └── FinishingUpView - Completion animation
│   │   ├── SleepGuideView.swift - Sleep education overlay
│   │   └── WakeUpTimeButton.swift - Reusable time selection component
│   ├── Alarms/
│   │   ├── AlarmsView.swift - Alarm management interface
│   │   └── AlarmDismissalView.swift - Alarm dismissal interface
│   └── Settings/
│       └── SettingsView.swift - App configuration
│
├── Models/
│   ├── SleepCalculator.swift - Core business logic
│   └── AlarmManager.swift - Alarm data management
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
- **Real-time clock** with minute-level updates and animations
- **Onboarding flow** with 3-step interactive introduction
- **Loading animations** for wake-up time calculations
- **Educational sleep guide** overlay with sleep hygiene tips
- **Categorized wake-up times** (Quick Boost, Recovery, Full Recharge)
- **3D icon assets** with rotating moon icons
- **Custom gradient backgrounds** and smooth animations
- **Read-only wake-up times**: Sleep calculations display only, no direct alarm creation
- **Complete alarm management**: Create, edit, delete, toggle alarms manually in Alarms tab
- **Sound preview**: Play alarm sounds when selecting them in the UI
- **Breathing animations** and floating "zzz" effects
- **⚠️ Visual-only alarms**: UI shows alarms but they don't actually trigger notifications

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

### Version 3.3 (Current) - Project Organization & Cleanup

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
- 🎨 **Complete alarm UI**: Full alarm management interface with create, edit, delete, toggle
- 🎵 **Sound selection**: Choose between Morning, Smooth, and Classic alarm tones with preview
- 💾 **Data persistence**: Alarms saved to UserDefaults and persist between app launches
- 🔄 **Sleep calculations**: Read-only wake-up time displays for information
- 📱 **Manual alarm creation**: Create alarms manually in the Alarms tab
- 🎯 **Alarm management**: Toggle alarms on/off, edit times and sounds
- 🎭 **Onboarding experience**: 3-step interactive introduction for new users
- 🌙 **3D animations**: Rotating moon icons and breathing effects

**🔧 Current Technical Implementation:**
- **SleepNowView**: Main UI with embedded onboarding, loading, and modal components
- **AlarmManager**: Direct alarm storage and UI management integration
- **AlarmsView**: Complete UI for alarm management with sound previews
- **AlarmDismissalView**: UI component for alarm dismissal

### Version 3.1 (Build 3) - Feature Complete
- Complete alarm UI implementation
- Sound selection and preview functionality
- Automatic navigation between tabs
- Data persistence system

### Version 3.0 (Build 2) - Initial Release
- Basic alarm UI implementation
- Sleep calculation features
- Initial data storage system
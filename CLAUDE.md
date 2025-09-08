# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mr Sleep is a pure SwiftUI iOS app that calculates optimal wake-up times based on sleep cycle science. The app uses 90-minute sleep cycles and accounts for 15 minutes to fall asleep.

## Build and Development Commands

```bash
# Open project in Xcode
open "Mr Sleep.xcodeproj"

# Build for iOS Simulator
xcodebuild -project "Mr Sleep.xcodeproj" -scheme "Mr Sleep" -destination "platform=iOS Simulator,name=iPhone 15" build

# Build for device
xcodebuild -project "Mr Sleep.xcodeproj" -scheme "Mr Sleep" -destination "generic/platform=iOS" build
```

## Architecture

### Framework and Dependencies
- **Pure SwiftUI** application with SwiftUI App lifecycle
- **No external dependencies** - uses only SwiftUI and Foundation
- **iOS 15.0+ minimum**, iPhone-only target
- **Bundle ID**: `com.magdoub.Mr-Sleeper`

### Core Architecture Pattern
- **MVVM-like structure** with singleton business logic
- **SleepCalculator.shared** - Singleton containing all sleep calculation logic
- **ContentView** - Main UI container with embedded child components
- **State-driven UI** using SwiftUI `@State` properties extensively

### Key Components
- `Mr_SleepApp.swift` - App entry point with dark mode configuration
- `MainTabView.swift` - Tab bar container managing app navigation
- `SleepNowView.swift` - Main sleep calculation and wake-up time selection
- `AlarmsView.swift` - Alarm management with native iOS Clock app experience
- `SettingsView.swift` - User preferences and app configuration
- `AlarmManager.swift` - Alarm data management and notification handling
- `SleepCalculator.swift` - Business logic singleton for sleep calculations
- `WakeUpTimeButton` - Reusable button component for time display
- `SleepGuideView` - Educational overlay about sleep hygiene

### Business Logic
- **Sleep cycles**: 90 minutes each (3-8 cycles supported)
- **Fall asleep buffer**: 15 minutes automatically added
- **Recommended sleep**: 4.5-6 hours highlighted as optimal
- **Real-time updates**: Timer publishes minute-level updates to UI
- **Alarm creation**: One-tap alarm creation from sleep calculations
- **Auto-reset alarms**: Manual alarms automatically disable after firing
- **Notification permissions**: Automatic request and management

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
- All UI state lives in ContentView as `@State` properties
- Business logic centralized in SleepCalculator singleton
- No external state management frameworks used

## Testing

**No testing infrastructure currently exists**. To add tests:
- Create new test targets in Xcode
- Focus unit tests on SleepCalculator logic
- Consider UI tests for core user flows

## Git Workflow

### Repository Information
- **Git Repository Location**: `/Users/magdoub/Documents/iOS projects/Mr Sleep/Mr Sleep/.git`
- **Remote Repository**: https://github.com/Magdoub/Mr-Sleep
- **Automated Commits**: Claude Code automatically commits all changes

### Commit Strategy
- **REQUIRED**: Every edit/change must be committed to git immediately after completion
- **MANDATORY**: Create a git commit with clear, descriptive commit messages for every change
- Commit messages should explain what was changed and why
- Always commit changes after completing any modification - no exceptions
- Include Claude Code attribution in all commit messages
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
1. **Every file change** must be committed immediately
2. **Every feature addition** gets its own commit
3. **Every bug fix** gets its own commit
4. **Every refactoring** gets its own commit
5. **Never** leave uncommitted changes at the end of a session

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

### Key Files Structure
- `/Mr Sleep/` - Main source directory
  - `Mr_SleepApp.swift` - App configuration and launch
  - `ContentView.swift` - Primary UI and all view logic
  - `SleepCalculator.swift` - Core business logic
- `/Assets.xcassets/` - App icons and custom moon icon
- `/Preview Content/` - SwiftUI preview assets

### UI/UX Features
- Real-time clock with minute-level updates
- Collapsible "more options" section
- Educational sleep guide overlay
- Recommended times highlighted visually
- Custom gradient backgrounds and button styling
- **Automatic navigation**: After creating an alarm, automatically switches to Alarms tab

### Platform Specifics
- iPhone-only application (no iPad/Mac support)
- Portrait orientation assumed
- Dark mode preferred (configured in app launch)
- Uses native iOS date/time formatting

### Extension Opportunities
- Could add iPad support with adaptive layouts
- Apple Watch companion app potential
- Internationalization support (currently English-only)
- Background notifications for optimal sleep times

## Version History

### Version 3.1 (Build 3) - January 2025
**🔔 Alarm System Overhaul - Now Fully Functional!**

- ✅ **Fixed alarm notifications**: Alarms now work reliably when phone is locked
- 🔄 **Smart repeat system**: Up to 6 notifications every 30 seconds for heavy sleepers
- 🔓 **Lock-aware behavior**: Notifications automatically stop when phone is unlocked
- 🎵 **Multiple alarm sounds**: Choose between Morning, Smooth, and Classic alarm tones
- 🎯 **Auto-toggle functionality**: Alarms automatically turn off when:
  - Phone is unlocked (without opening app)
  - App is opened
  - Any notification is tapped
  - All 6 notifications complete
- 🔊 **Critical alerts**: Bypass Do Not Disturb and volume settings
- 📱 **Live Activities**: Enhanced alarm display on lock screen
- 🎨 **Improved UI**: Better sound selection and alarm management

**Technical Improvements:**
- Pre-scheduling notification system for reliability
- Enhanced app lifecycle detection
- Robust background processing handling
- Comprehensive logging for debugging
- Multiple fallback mechanisms for alarm dismissal

### Version 3.0 (Build 2) - Previous Release
- Initial alarm functionality
- Basic notification system
- Sleep calculation features
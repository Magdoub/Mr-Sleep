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
- `ContentView.swift` - Main UI containing all app functionality and state
- `SleepCalculator.swift` - Business logic singleton for sleep calculations
- `WakeUpTimeButton` - Reusable button component for time display
- `SleepGuideView` - Educational overlay about sleep hygiene

### Business Logic
- **Sleep cycles**: 90 minutes each (3-8 cycles supported)
- **Fall asleep buffer**: 15 minutes automatically added
- **Recommended sleep**: 4.5-6 hours highlighted as optimal
- **Real-time updates**: Timer publishes minute-level updates to UI

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
- **Remote Repository**: https://github.com/Magdoub/Mr-Sleep
- **Automated Commits**: Claude Code automatically commits all changes

### Commit Strategy
- **REQUIRED**: Every edit/change must be committed to git
- Use descriptive commit messages explaining the purpose of changes
- Always commit changes after completing any modification
- Include Claude Code attribution in commit messages

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
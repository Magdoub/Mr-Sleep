# Master PRD: "Wake Up At" Feature

**Feature Name:** Wake Up At - Reverse Sleep Calculator
**Version:** 1.0
**Created:** November 2, 2025
**Status:** Planning Phase
**Priority:** High

---

## 📋 Executive Summary

### Overview
Add a complementary "Wake Up At" mode to Mr Sleep that calculates optimal bedtimes when users know what time they need to wake up. This feature provides the inverse functionality of the existing "Sleep Now" mode, creating a complete sleep planning experience.

### User Value Proposition
- **Current state:** Users can only calculate wake-up times based on sleeping now
- **Problem:** Many users know their target wake-up time (e.g., 7:00 AM for work) and want to know when to go to bed
- **Solution:** Toggle between "Sleep Now" (existing) and "Wake Up At" (new) modes
- **Benefit:** Complete flexibility in sleep planning for all user scenarios

### Key Design Principle
**Design First, Function Later** - Phase 1 focuses exclusively on UI/UX implementation with static/mock data to validate the design before adding calculation logic.

---

## 🎨 Design Principles Alignment

This feature MUST follow all design principles from:
**`/Users/magdoub/Desktop/Mr_Sleep_App_Design_Principles.md`**

### Visual Design Application
- **Background:** Same deep navy blue gradient (dark-to-darker tones)
- **Toggle:** Golden yellow for active state, light gray for inactive
- **Typography:** SF Pro Rounded with same hierarchy as Sleep Now view
- **Icons:** 3D moon icon with zzz animations (consistent with existing design)
- **Cards:** Same rounded corners (20-24px), subtle shadows, categorized sleep times

### Interaction Design Application
- **Toggle transition:** Smooth crossfade animation between modes
- **Haptic feedback:** Soft tap when toggling, selection feedback on time cards
- **Animation curve:** Ease-in-out to match relaxing context
- **Loading states:** Reuse existing CalculatingWakeUpTimesView component

### Copy & Tone
- **Motivational:** "Wake up Like a Boss" → "Sleep smart. Wake up perfect."
- **Category labels:** Same (Quick Boost, Recovery, Full Recharge)
- **Instructions:** Clear, friendly, emoji-enhanced where appropriate

---

## 👤 User Stories

### Primary User Story
> "As a working professional with a fixed wake-up time, I want to know the optimal times to go to bed tonight so that I wake up refreshed and aligned with my sleep cycles."

### Secondary User Stories
1. "As a student with early morning classes, I need to plan my bedtime based on when my alarm needs to go off."
2. "As a parent with school drop-off duties, I want to maximize sleep quality by hitting the right sleep cycles before my 6:30 AM alarm."
3. "As someone with an irregular schedule, I want to switch between 'sleep now' and 'wake up at X time' depending on my situation."

---

## 🎯 Feature Requirements

### Functional Requirements

#### FR-1: Mode Toggle
- **Description:** Users can toggle between "Sleep Now" and "Wake Up At" modes
- **Behavior:**
  - Toggle appears at top of screen below "Mr Sleep" header
  - Two-option segmented control design
  - Active state uses golden yellow styling
  - Inactive state uses light gray styling
  - Smooth crossfade transition (300ms) between modes
  - State persists across app sessions
- **Reference Design:** User-provided image showing toggle UI

#### FR-2: Wake-Up Time Selection (Phase 1 - Static)
- **Description:** Display a time picker for target wake-up time
- **Behavior (Phase 1):**
  - Show current time + 8 hours as default
  - Native iOS time picker wheel (hours and minutes)
  - Golden yellow accent color
  - No calculation logic yet (display mock data)

#### FR-3: Bedtime Recommendations (Phase 1 - Static)
- **Description:** Display categorized bedtime options
- **Behavior (Phase 1):**
  - Show 6 static mock bedtimes in same category layout as Sleep Now
  - Categories: Full Recharge, Recovery, Quick Boost
  - Same 3D icons: battery-3D-icon, heart-3D-icon, bolt-3D-icon
  - Display "Total Sleep" duration for each option
  - Card tap does nothing in Phase 1 (UI only)

#### FR-4: Visual Consistency
- **Description:** Match all visual design elements from Sleep Now view
- **Behavior:**
  - Same gradient background
  - Same moon icon with breathing animation
  - Same "zzz" floating animations
  - Same current time display at top
  - Same loading animations (if shown)

### Non-Functional Requirements

#### NFR-1: Performance
- Toggle switch response time < 100ms
- Mode transition animation smooth at 60fps
- No jank or lag during UI updates

#### NFR-2: Accessibility
- Toggle readable by VoiceOver
- Color contrast meets WCAG AA standards
- Time picker accessible with assistive technologies
- Support for Reduce Motion preference

#### NFR-3: Data Persistence
- Selected mode (Sleep Now vs Wake Up At) saved to UserDefaults
- Restore last mode on app launch

---

## 🎨 UI/UX Specifications

### Component Breakdown

#### 1. Mode Toggle (NEW)
```
┌─────────────────────────────────────────┐
│  ┌─────────────┬─────────────┐          │
│  │ Sleep Now   │ Wake Up At  │          │ ← Segmented Control
│  │   [GOLD]    │   [GRAY]    │          │
│  └─────────────┴─────────────┘          │
└─────────────────────────────────────────┘
```

**Specifications:**
- **Position:** Below "Mr Sleep" title, above current time
- **Width:** 280pt (centered)
- **Height:** 44pt
- **Corner Radius:** 22pt (pill shape)
- **Background:** Dark blue with subtle glow
- **Active segment:** Golden yellow (#E4BA4E), semibold text
- **Inactive segment:** Light gray (#A0A0A0), regular text
- **Font:** SF Pro Rounded, size 16pt
- **Animation:** Spring animation (response: 0.3, damping: 0.8)

**Component Type:** Custom SwiftUI segmented control or native Picker with custom styling

---

#### 2. Wake-Up Time Picker (NEW)
```
┌─────────────────────────────────────────┐
│         Set Your Wake-Up Time           │ ← Section Header (gold)
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     [  7  ] : [ 00 ]  AM        │   │ ← Time Picker Wheel
│  │                                 │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Specifications:**
- **Position:** Below toggle and current time display
- **Section Header:**
  - Text: "Set Your Wake-Up Time"
  - Font: SF Pro Rounded, size 20pt, semibold
  - Color: Golden yellow (#E4BA4E)
  - Icon: "🌅" emoji before text
- **Picker:**
  - Native iOS DatePicker in `.wheel` mode
  - Display components: `.hourAndMinute`
  - Accent color: Golden yellow
  - Background: Semi-transparent dark card
  - Corner radius: 20pt
  - Padding: 20pt
- **Default Value:** Current time + 8 hours (typical sleep duration)

---

#### 3. Bedtime Cards (ADAPTED FROM SLEEP NOW)
```
┌─────────────────────────────────────────┐
│  🔋 Full Recharge                       │ ← Category Header (gold)
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Go to Bed At         💤 7.5h   │   │ ← Card
│  │      11:30 PM                   │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  Go to Bed At         💤 9.0h   │   │
│  │       10:00 PM                  │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Specifications:**
- **Layout:** Same vertical stacking as Sleep Now view
- **Card Design:** Identical to existing WakeUpTimeButton component
- **Changes:**
  - Label: "Go to Bed At" instead of "Wake Up Time"
  - Times: Calculate backwards from wake-up time
  - Duration: Display total sleep time (e.g., "💤 7.5h")
- **Categories:** Same ordering logic (time-based priority)
- **Icons:** Same 3D icons (battery, heart, bolt)

---

#### 4. Current Time Display (EXISTING - REUSE)
```
Current time  10:30 PM
```
**No changes needed** - reuse existing component

---

#### 5. Moon Icon & Animations (EXISTING - REUSE)
```
     🌙
    zzz  zzz
       zzz
```
**No changes needed** - reuse existing breathing and zzz animations

---

## 🏗️ Technical Architecture

### Data Flow (Phase 2+ Only)

#### Reverse Sleep Calculation Logic
```
User Input: Wake-Up Time (e.g., 7:00 AM)
           ↓
Calculate: Subtract sleep cycles + fall asleep time
           ↓
Sleep Cycles: [1, 2, 3, 4, 5, 6] × 90 minutes
Fall Asleep Buffer: 15 minutes
           ↓
Bedtime Options:
  - 7:00 AM - (6 cycles × 90min) - 15min = 12:45 AM (9h)
  - 7:00 AM - (5 cycles × 90min) - 15min = 2:15 AM (7.5h)
  - 7:00 AM - (4 cycles × 90min) - 15min = 3:45 AM (6h)
  - 7:00 AM - (3 cycles × 90min) - 15min = 5:15 AM (4.5h)
  - 7:00 AM - (2 cycles × 90min) - 15min = 6:30 AM (3h)
  - 7:00 AM - (1 cycle × 90min) - 15min = 6:45 AM (1.5h)
           ↓
Round to nearest 5 minutes
           ↓
Categorize by duration:
  - Quick Boost: 1-2 cycles
  - Recovery: 3-4 cycles
  - Full Recharge: 5-6 cycles
           ↓
Apply time-based priority ordering
           ↓
Display in UI
```

### Component Architecture

#### New Files to Create
```
Mr Sleep/
├── Views/
│   └── Sleep/
│       └── WakeUpAtView.swift          [NEW - Phase 1]
├── Models/
│   └── SleepMode.swift                 [NEW - Phase 1]
│   └── SleepCalculator+Reverse.swift   [NEW - Phase 2]
```

#### Modified Files
```
Mr Sleep/
├── App/
│   └── Mr_SleepApp.swift               [MODIFY - Phase 1]
├── Views/
│   └── Sleep/
│       └── SleepContainerView.swift    [NEW - Phase 1]
```

### State Management

#### SleepMode Enum (NEW)
```swift
enum SleepMode: String, Codable {
    case sleepNow
    case wakeUpAt

    static let userDefaultsKey = "SelectedSleepMode"
}
```

#### WakeUpAtView State (NEW - Phase 1)
```swift
@State private var selectedWakeUpTime: Date = Date().addingTimeInterval(8 * 3600)
@State private var isLoading: Bool = false
@State private var mockBedtimes: [Date] = [] // Phase 1: static mock data
```

---

## 📅 Implementation Phases

### Phase 1: UI-Only Implementation (Design Validation) 🎨
**Goal:** Build and test the complete UI with no calculation logic

**Duration:** 2-3 hours
**Priority:** CRITICAL - Must validate design before proceeding

#### Deliverables:
1. ✅ Toggle switch UI (functional switching between views)
2. ✅ WakeUpAtView with time picker
3. ✅ Mock bedtime cards (6 static times)
4. ✅ All animations and transitions working
5. ✅ Mode persistence (UserDefaults)
6. ✅ **NO CALCULATION LOGIC** - hardcoded mock data only

#### Success Criteria:
- Toggle smoothly switches between Sleep Now and Wake Up At
- Time picker looks and feels native to the app design
- Mock bedtime cards match Sleep Now visual design exactly
- All animations smooth and bug-free
- User can navigate and interact with UI (even though it doesn't calculate)

---

### Phase 2: Calculation Logic Integration ⚙️
**Goal:** Add reverse sleep cycle calculation

**Duration:** 2-3 hours
**Prerequisites:** Phase 1 complete and approved

#### Deliverables:
1. ✅ SleepCalculator extension with reverse calculation method
2. ✅ Wire up time picker to trigger calculations
3. ✅ Display real calculated bedtimes
4. ✅ Category assignment logic
5. ✅ Time-based priority ordering
6. ✅ Unit tests for reverse calculations

---

### Phase 3: Advanced Features & Polish ✨
**Goal:** Add loading states, animations, and edge cases

**Duration:** 2-3 hours
**Prerequisites:** Phase 2 complete and tested

#### Deliverables:
1. ✅ Loading animation when time picker changes
2. ✅ Haptic feedback on toggle and card selection
3. ✅ Edge case handling (wake-up time in the past, etc.)
4. ✅ Smooth scrolling and layout polish
5. ✅ Accessibility audit and fixes
6. ✅ Performance optimization

---

### Phase 4: Alarm Integration (Optional) 🔔
**Goal:** Allow setting alarms from bedtime cards

**Duration:** 3-4 hours
**Prerequisites:** Phase 3 complete

#### Deliverables:
1. ✅ Tap bedtime card → confirm alarm modal
2. ✅ Reverse alarm setup (alarm set for wake-up time, bedtime as guidance)
3. ✅ Integration with AlarmKit
4. ✅ Data persistence for reverse alarms
5. ✅ Active alarm state management

---

## ✅ Detailed TODO Checklist

### Phase 1: UI-Only Implementation

#### Setup & Architecture
- [ ] Create `/PRD/WakeUpAt_Feature_Master_PRD.md` (this document)
- [ ] Create `SleepMode.swift` enum file
- [ ] Create `WakeUpAtView.swift` file
- [ ] Create `SleepContainerView.swift` wrapper file

#### Toggle Component
- [ ] Design custom segmented control component
- [ ] Implement two-segment toggle (Sleep Now | Wake Up At)
- [ ] Add golden yellow active state styling
- [ ] Add light gray inactive state styling
- [ ] Implement smooth spring animation on toggle
- [ ] Add haptic feedback on toggle tap
- [ ] Wire up toggle to switch between views
- [ ] Save selected mode to UserDefaults
- [ ] Restore mode on app launch

#### WakeUpAtView Structure
- [ ] Copy base layout from SingleAlarmView.swift
- [ ] Add same gradient background
- [ ] Add same moon icon with breathing animation
- [ ] Add same floating "zzz" animations
- [ ] Add current time display at top
- [ ] Add "Mr Sleep" header text

#### Time Picker Implementation
- [ ] Add "🌅 Set Your Wake-Up Time" section header
- [ ] Style header with golden yellow color
- [ ] Implement iOS DatePicker in wheel mode
- [ ] Set picker to .hourAndMinute display mode
- [ ] Apply golden yellow accent color
- [ ] Set default time to current time + 8 hours
- [ ] Add semi-transparent dark card background
- [ ] Apply 20pt corner radius and padding
- [ ] Center picker in view

#### Mock Bedtime Cards
- [ ] Create array of 6 static mock Date objects
- [ ] Use times: 11:30 PM, 10:00 PM, 12:45 AM, 1:00 AM, 3:00 AM, 5:00 AM
- [ ] Group mock times into categories:
  - [ ] Full Recharge: 11:30 PM (7.5h), 10:00 PM (9h)
  - [ ] Recovery: 12:45 AM (6h), 1:00 AM (4.5h)
  - [ ] Quick Boost: 3:00 AM (3h), 5:00 AM (1.5h)
- [ ] Reuse WakeUpTimeButton component (if possible)
- [ ] Change label to "Go to Bed At"
- [ ] Add sleep duration display (e.g., "💤 7.5h")
- [ ] Apply same card styling (rounded corners, shadows)
- [ ] Add same 3D category icons (battery, heart, bolt)

#### Layout & Spacing
- [ ] Match vertical spacing from SingleAlarmView
- [ ] Ensure consistent padding (horizontal: 20pt)
- [ ] Test layout on different iPhone screen sizes
- [ ] Verify scrolling works smoothly
- [ ] Add safe area handling (top and bottom)

#### Animations & Transitions
- [ ] Implement crossfade transition between Sleep Now and Wake Up At
- [ ] Set transition duration to 300ms
- [ ] Test animation smoothness (60fps target)
- [ ] Add breathing animation to moon icon (reuse existing)
- [ ] Add floating "zzz" animations (reuse existing)

#### Integration
- [ ] Update Mr_SleepApp.swift to show SleepContainerView instead of SingleAlarmView
- [ ] Ensure navigation doesn't break
- [ ] Test toggling between modes multiple times
- [ ] Verify state persistence works (kill and relaunch app)

#### Testing & Validation
- [ ] Test on iPhone 16 Pro simulator
- [ ] Test on physical device (if available)
- [ ] Verify all text is readable (contrast check)
- [ ] Test in light mode (should force dark mode)
- [ ] Test VoiceOver navigation
- [ ] Test Dynamic Type (larger text sizes)
- [ ] Check for memory leaks
- [ ] Verify no console errors or warnings

#### Design Review Checkpoint
- [ ] Compare with user-provided design image
- [ ] Get user feedback on UI implementation
- [ ] Make any requested design adjustments
- [ ] **STOP HERE - Do not proceed to Phase 2 until approved**

---

### Phase 2: Calculation Logic (TODO - After Phase 1 Approval)

#### SleepCalculator Extension
- [ ] Create `SleepCalculator+Reverse.swift` file
- [ ] Add `calculateBedtimes(for wakeUpTime: Date) -> [Date]` method
- [ ] Implement reverse calculation logic:
  - [ ] Subtract sleep cycles (90 min × 1-6)
  - [ ] Subtract fall asleep time (15 min)
  - [ ] Round to nearest 5 minutes
- [ ] Add `categorizeBedtimes(_ times: [Date]) -> [(category: String, times: [(time: Date, cycles: Int)])]`
- [ ] Test calculation logic with unit tests
- [ ] Verify edge cases (wake-up time in past, next day calculations)

#### UI Integration
- [ ] Remove mock data from WakeUpAtView
- [ ] Wire up time picker `onChange` to trigger calculation
- [ ] Display calculated bedtimes instead of static data
- [ ] Add loading state while calculating
- [ ] Update duration labels with real values
- [ ] Test dynamic updates when picker changes

---

### Phase 3: Polish & Advanced Features (TODO - After Phase 2)

#### Loading States
- [ ] Show CalculatingWakeUpTimesView when time picker changes
- [ ] Add 800ms delay to prevent flickering on quick changes
- [ ] Implement smooth fade transition to results
- [ ] Add haptic feedback when calculation completes

#### Error Handling
- [ ] Handle wake-up time in the past (show warning)
- [ ] Handle invalid time selections
- [ ] Add helpful error messages
- [ ] Prevent crashes from edge cases

#### Accessibility
- [ ] Add VoiceOver labels to all interactive elements
- [ ] Test with VoiceOver enabled
- [ ] Support Dynamic Type
- [ ] Test with Reduce Motion enabled
- [ ] Add accessibility identifiers for UI testing

#### Performance
- [ ] Profile with Instruments
- [ ] Optimize any slow rendering
- [ ] Reduce memory footprint
- [ ] Test on older devices (iPhone 12/13)

---

### Phase 4: Alarm Integration (TODO - Optional)

#### Bedtime Card Interaction
- [ ] Make bedtime cards tappable
- [ ] Show confirmation modal when tapped
- [ ] Display selected bedtime and wake-up time
- [ ] Add "Set Alarm" button in modal

#### Alarm Scheduling
- [ ] Schedule AlarmKit alarm for wake-up time
- [ ] Store bedtime as metadata (guidance only)
- [ ] Show active alarm state in UI
- [ ] Allow alarm cancellation
- [ ] Update SingleAlarmData model to support reverse alarms

#### Data Management
- [ ] Save reverse alarm data to UserDefaults
- [ ] Track alarm ID for deletion
- [ ] Handle alarm firing events
- [ ] Show welcome back screen after alarm fires

---

## 📊 Success Metrics

### Phase 1 Success Criteria
✅ **Design Validation:**
- [ ] User approves UI design
- [ ] Toggle feels intuitive and responsive
- [ ] Time picker matches app aesthetic
- [ ] Mock cards look identical to Sleep Now cards
- [ ] No visual bugs or layout issues

### Phase 2 Success Criteria
✅ **Functionality:**
- [ ] Calculations are accurate (match manual verification)
- [ ] Times update immediately when picker changes
- [ ] Categories assigned correctly
- [ ] All 6 bedtimes displayed for any wake-up time

### Phase 3 Success Criteria
✅ **Polish:**
- [ ] Animations smooth (no jank)
- [ ] Loading states feel natural
- [ ] Accessibility score: 100% (automated tools)
- [ ] No crashes or errors in testing

### Phase 4 Success Criteria (Optional)
✅ **Integration:**
- [ ] Alarms set correctly from bedtime cards
- [ ] AlarmKit integration stable
- [ ] Active alarm state persists across launches

---

## 🎨 Design Reference

### User-Provided Design
The user provided a sample design image showing:
- Toggle at top: "SLEEP NOW" and "Wake Up At"
- Current time display: "Current time 10:30 aM" and "Current time 10:30 PM"
- Toggle active state appears to use golden/yellow highlight
- Clean, minimal design consistent with app aesthetic

**Implementation Note:** Follow this design exactly in Phase 1.

---

## 🚀 Launch Strategy

### Phase 1 Launch (Internal Testing)
- Share build with 2-3 beta testers
- Gather feedback on UI/UX only
- Iterate on design based on feedback
- **DO NOT** release to App Store

### Phase 2 Launch (Beta Testing)
- Expand to 10-15 beta testers via TestFlight
- Test calculation accuracy
- Gather feedback on feature utility
- Fix any bugs discovered

### Phase 3 Launch (Soft Launch)
- Release to App Store as v5.2
- Monitor crash reports and analytics
- Gather user reviews and feedback
- Iterate based on real-world usage

### Phase 4 Launch (Full Feature)
- Release alarm integration as v5.3
- Update App Store screenshots and description
- Promote feature in app and marketing materials

---

## 📝 Notes & Considerations

### Design Decisions

#### Why Toggle Instead of Tab?
- **Cognitive Load:** Toggle keeps users in same mental context (sleep planning)
- **Visual Hierarchy:** Tabs suggest equal-weight features; this is a mode switch
- **Space Efficiency:** Toggle takes less vertical space than tab bar
- **User Intent:** Most users will use one mode per session, not switch frequently

#### Why Reuse Visual Components?
- **Consistency:** Users already understand the Sleep Now card layout
- **Development Speed:** Leverage existing, tested components
- **Brand Identity:** Maintain cohesive app aesthetic across all features
- **Maintenance:** One set of components to update/debug

### Future Enhancements (Post-Launch)
1. **Smart Defaults:** Learn user's typical wake-up time and pre-fill
2. **Weekday/Weekend Profiles:** Different wake-up times for different days
3. **Multiple Alarms:** Set multiple bedtime options as alarms
4. **Sleep Debt Tracking:** Recommend longer sleep if user has debt
5. **Integration with Health App:** Pull wake-up trends from Apple Health

### Technical Debt to Address
- [ ] Consider merging SleepCalculator and SleepCalculator+Reverse into single file
- [ ] Evaluate if WakeUpTimeButton component name still makes sense (now also bedtime button)
- [ ] Document calculation logic thoroughly for future maintainers

---

## 📚 Related Documentation

- **Design Principles:** `/Users/magdoub/Desktop/Mr_Sleep_App_Design_Principles.md`
- **Project Docs:** `/Users/magdoub/Documents/iOS projects/Mr Sleep/CLAUDE.md`
- **Existing Calculator:** `Mr Sleep/Models/SleepCalculator.swift`
- **Reference View:** `Mr Sleep/Views/Sleep/SingleAlarmView.swift`

---

## 📞 Stakeholders & Review

**Product Owner:** Magdoub
**Designer:** Magdoub (following established design system)
**Developer:** Claude Code (with Magdoub oversight)

**Review Checkpoints:**
1. ✅ Phase 1 Complete → Design review before proceeding
2. ✅ Phase 2 Complete → Calculation accuracy verification
3. ✅ Phase 3 Complete → Final polish review before beta
4. ✅ Phase 4 Complete → Launch readiness review

---

**Document Version:** 1.0
**Last Updated:** November 2, 2025
**Next Review:** After Phase 1 completion

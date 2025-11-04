# Wake Up At Feature - Phase 1: UI-Only Implementation

**Feature:** Wake Up At - Reverse Sleep Calculator
**Phase:** 1 of 4 (UI-Only / Design Validation)
**Master PRD:** [`WakeUpAt_Feature_Master_PRD.md`](./WakeUpAt_Feature_Master_PRD.md)
**Created:** November 2, 2025
**Status:** In Progress
**Priority:** CRITICAL (Design validation before proceeding)

---

## 🎯 Phase 1 Objective

**Build the complete "Wake Up At" UI with NO calculation logic to validate the design before investing in functionality.**

### Success Criteria
✅ User can toggle between "Sleep Now" and "Wake Up At" modes
✅ Time picker displays and feels natural in the app
✅ 6 mock bedtime cards display correctly
✅ All animations smooth and bug-free
✅ Visual design matches Sleep Now aesthetic
✅ **User approves UI/UX before Phase 2**

### Constraints
❌ **NO** calculation logic (all data hardcoded)
❌ **NO** actual alarm functionality
❌ **NO** time picker onChange logic
✅ Focus is 100% on visual design and user experience

---

## 📋 Implementation Overview

### What We're Building

```
┌─────────────────────────────────────────────────┐
│               🌙 Mr Sleep                       │
│                                                 │
│   ┌────────────────┬──────────────────┐        │
│   │  Sleep Now     │  Wake Up At ⭐   │  ← Toggle
│   └────────────────┴──────────────────┘        │
│                                                 │
│           Current time 10:30 PM                 │
│                                                 │
│         🌅 Set Your Wake-Up Time                │
│   ┌─────────────────────────────────┐          │
│   │     [  7  ] : [ 00 ]  AM        │  ← Picker
│   └─────────────────────────────────┘          │
│                                                 │
│         🔋 Full Recharge                        │
│   ┌─────────────────────────────────┐          │
│   │  Go to Bed At      💤 7.5h      │  ← Card  │
│   │      11:30 PM                   │          │
│   └─────────────────────────────────┘          │
│   ┌─────────────────────────────────┐          │
│   │  Go to Bed At      💤 9.0h      │          │
│   │       10:00 PM                  │          │
│   └─────────────────────────────────┘          │
│                                                 │
│         ❤️ Recovery                             │
│   [More cards...]                               │
└─────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture Decisions

### View Hierarchy
```
Mr_SleepApp
    └── SleepContainerView (NEW)
            ├── Toggle Component (Sleep Now | Wake Up At)
            │
            ├── Sleep Now Mode
            │   └── SingleAlarmView (EXISTING)
            │
            └── Wake Up At Mode
                └── WakeUpAtView (NEW - Phase 1)
                    ├── Gradient Background
                    ├── Moon Icon + zzz animations
                    ├── Current Time Display
                    ├── Time Picker (static)
                    └── Mock Bedtime Cards (6 hardcoded)
```

### State Management
- **Mode Selection:** UserDefaults persistence
- **Selected Mode:** `@State` in SleepContainerView
- **Mock Data:** Hardcoded Date array in WakeUpAtView

### Component Reuse Strategy
✅ **Reuse:** Gradient background, moon animations, current time display
✅ **Reuse:** WakeUpTimeButton component (just change label)
✅ **Reuse:** Category icons (battery, heart, bolt)
🆕 **New:** Toggle component, time picker, WakeUpAtView shell

---

## 📁 File Structure

### Files to Create

#### 1. `/Models/SleepMode.swift` (NEW)
**Purpose:** Enum to track Sleep Now vs Wake Up At mode
**Size:** ~30 lines
**Dependencies:** Foundation only

```swift
// Simple enum with UserDefaults persistence
enum SleepMode: String, Codable {
    case sleepNow
    case wakeUpAt

    static let userDefaultsKey = "SelectedSleepMode"
}
```

---

#### 2. `/Views/Sleep/WakeUpAtView.swift` (NEW)
**Purpose:** Wake Up At UI with time picker and mock bedtime cards
**Size:** ~400-500 lines
**Dependencies:** SwiftUI, Foundation

**Structure:**
```swift
struct WakeUpAtView: View {
    // Mock data (Phase 1)
    @State private var selectedWakeUpTime: Date = Date().addingTimeInterval(8 * 3600)
    @State private var mockBedtimes: [MockBedtime] = []

    var body: some View {
        ZStack {
            // Gradient background (copy from SingleAlarmView)
            // Moon icon + zzz animations (copy from SingleAlarmView)

            ScrollView {
                VStack {
                    // Current time display
                    // Time picker section
                    // Mock bedtime cards (categorized)
                }
            }
        }
    }

    private func generateMockData() {
        // Hardcode 6 bedtime dates
    }
}

struct MockBedtime: Identifiable {
    let id = UUID()
    let bedtime: Date
    let wakeUpTime: Date
    let cycles: Int
    let duration: Double // in hours
}
```

---

#### 3. `/Views/Sleep/SleepContainerView.swift` (NEW)
**Purpose:** Wrapper with toggle to switch between Sleep Now and Wake Up At
**Size:** ~200-250 lines
**Dependencies:** SwiftUI

**Structure:**
```swift
struct SleepContainerView: View {
    @EnvironmentObject var viewModelContainer: LazyAlarmKitContainer
    @State private var selectedMode: SleepMode = .sleepNow

    var body: some View {
        ZStack {
            // Same gradient background

            VStack(spacing: 0) {
                // Header: "Mr Sleep" title

                // Toggle component
                ModeToggle(selectedMode: $selectedMode)
                    .padding(.top, 10)

                // Content (switches based on mode)
                if selectedMode == .sleepNow {
                    SingleAlarmView()
                        .environmentObject(viewModelContainer)
                        .transition(.opacity)
                } else {
                    WakeUpAtView()
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            loadSelectedMode()
        }
        .onChange(of: selectedMode) { oldMode, newMode in
            saveSelectedMode(newMode)
        }
    }

    private func loadSelectedMode() { /* UserDefaults */ }
    private func saveSelectedMode(_ mode: SleepMode) { /* UserDefaults */ }
}

struct ModeToggle: View {
    @Binding var selectedMode: SleepMode

    var body: some View {
        // Custom segmented control
        // Golden yellow for active, gray for inactive
        // Spring animation on tap
    }
}
```

---

### Files to Modify

#### 1. `/App/Mr_SleepApp.swift` (MODIFY)
**Change:** Replace `SingleAlarmView()` with `SleepContainerView()`

**Before:**
```swift
var body: some Scene {
    WindowGroup {
        SingleAlarmView()
            .environmentObject(viewModelContainer)
            .preferredColorScheme(.dark)
    }
}
```

**After:**
```swift
var body: some Scene {
    WindowGroup {
        SleepContainerView()
            .environmentObject(viewModelContainer)
            .preferredColorScheme(.dark)
    }
}
```

---

## 🎨 Component Specifications

### 1. Toggle Component (ModeToggle)

#### Visual Design
```
┌────────────────────────────────┐
│  ┌─────────────┬─────────────┐ │
│  │ Sleep Now   │ Wake Up At  │ │
│  │   [GOLD]    │   [GRAY]    │ │
│  └─────────────┴─────────────┘ │
└────────────────────────────────┘
```

#### Specifications
- **Width:** 320pt (centered)
- **Height:** 48pt
- **Corner Radius:** 24pt (pill shape)
- **Background:** `Color(red: 0.08, green: 0.12, blue: 0.25).opacity(0.8)`
- **Active State:**
  - Background: Golden yellow `Color(red: 0.894, green: 0.729, blue: 0.306)`
  - Text: White, semibold
- **Inactive State:**
  - Background: Transparent
  - Text: Light gray `Color(red: 0.7, green: 0.7, blue: 0.7)`, regular
- **Font:** SF Pro Rounded, 17pt
- **Animation:** Spring (response: 0.35, dampingFraction: 0.75)
- **Haptic:** Light impact on tap

#### Code Pattern
```swift
struct ModeToggle: View {
    @Binding var selectedMode: SleepMode

    var body: some View {
        HStack(spacing: 0) {
            // Sleep Now button
            ModeButton(
                title: "Sleep Now",
                isSelected: selectedMode == .sleepNow,
                action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = .sleepNow
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            )

            // Wake Up At button
            ModeButton(
                title: "Wake Up At",
                isSelected: selectedMode == .wakeUpAt,
                action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = .wakeUpAt
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            )
        }
        .frame(width: 320, height: 48)
        .background(Color(red: 0.08, green: 0.12, blue: 0.25).opacity(0.8))
        .cornerRadius(24)
    }
}
```

---

### 2. Time Picker Section

#### Visual Design
```
         🌅 Set Your Wake-Up Time
   ┌─────────────────────────────────┐
   │     [  7  ] : [ 00 ]  AM        │
   └─────────────────────────────────┘
```

#### Specifications
- **Section Header:**
  - Text: "🌅 Set Your Wake-Up Time"
  - Font: SF Pro Rounded, 22pt, semibold
  - Color: Golden yellow `Color(red: 0.894, green: 0.729, blue: 0.306)`
  - Padding: 20pt horizontal, 30pt top, 15pt bottom
- **Time Picker:**
  - Type: `DatePicker` with `.wheel` style
  - Display: `.hourAndMinute`
  - Accent Color: Golden yellow
  - Background: `Color(red: 0.1, green: 0.15, blue: 0.3).opacity(0.6)`
  - Corner Radius: 20pt
  - Padding: 20pt
  - Default Value: Current time + 8 hours

#### Code Pattern
```swift
VStack(alignment: .leading, spacing: 15) {
    // Section header
    Text("🌅 Set Your Wake-Up Time")
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.top, 30)

    // Time picker
    DatePicker(
        "",
        selection: $selectedWakeUpTime,
        displayedComponents: [.hourAndMinute]
    )
    .datePickerStyle(.wheel)
    .labelsHidden()
    .tint(Color(red: 0.894, green: 0.729, blue: 0.306))
    .background(
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.1, green: 0.15, blue: 0.3).opacity(0.6))
    )
    .padding(.horizontal, 20)
}
```

---

### 3. Mock Bedtime Cards

#### Mock Data Generation
```swift
private func generateMockData() -> [MockBedtime] {
    let calendar = Calendar.current
    let baseDate = Date() // Today

    // Hardcode 6 bedtime options (Phase 1 - no calculation)
    let mockData: [(hour: Int, minute: Int, cycles: Int)] = [
        (23, 30, 5),  // 11:30 PM - 5 cycles (7.5h)
        (22, 0, 6),   // 10:00 PM - 6 cycles (9h)
        (0, 45, 4),   // 12:45 AM - 4 cycles (6h)
        (1, 15, 3),   // 1:15 AM - 3 cycles (4.5h)
        (3, 0, 2),    // 3:00 AM - 2 cycles (3h)
        (5, 15, 1)    // 5:15 AM - 1 cycle (1.5h)
    ]

    return mockData.map { data in
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = data.hour
        components.minute = data.minute

        let bedtime = calendar.date(from: components)!
        let wakeUpTime = selectedWakeUpTime
        let duration = Double(data.cycles) * 1.5

        return MockBedtime(
            bedtime: bedtime,
            wakeUpTime: wakeUpTime,
            cycles: data.cycles,
            duration: duration
        )
    }
}
```

#### Card Display Pattern
```swift
// Group by category (same logic as SleepCalculator)
private func categorizedMockData() -> [(category: String, bedtimes: [MockBedtime])] {
    let grouped = Dictionary(grouping: mockBedtimes) { bedtime in
        getCategoryForCycles(bedtime.cycles)
    }

    // Order: Full Recharge, Recovery, Quick Boost (or dynamic based on time)
    let categoryOrder = getDynamicCategoryOrder()

    return categoryOrder.compactMap { category in
        guard let bedtimes = grouped[category], !bedtimes.isEmpty else { return nil }
        let sorted = bedtimes.sorted { $0.cycles > $1.cycles }
        return (category: category, bedtimes: sorted)
    }
}

// Display
ForEach(categorizedMockData(), id: \.category) { group in
    VStack(alignment: .leading, spacing: 15) {
        // Category header
        HStack(spacing: 8) {
            Image(getCategoryIcon(group.category))
                .resizable()
                .frame(width: 30, height: 30)

            Text(group.category)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
        }
        .padding(.horizontal, 20)

        // Bedtime cards
        ForEach(group.bedtimes) { bedtime in
            BedtimeCard(bedtime: bedtime)
                .padding(.horizontal, 20)
        }
    }
}
```

#### BedtimeCard Component
```swift
struct BedtimeCard: View {
    let bedtime: MockBedtime

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Go to Bed At")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Text(formatTime(bedtime.bedtime))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Sleep")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text("💤 \(String(format: "%.1f", bedtime.duration))h")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.18, blue: 0.35).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
```

---

## 🔄 Implementation Order

### Step 1: Create SleepMode Enum ✅
**File:** `Models/SleepMode.swift`
**Time:** 5 minutes
**Test:** Can import SleepMode in other files

---

### Step 2: Create WakeUpAtView Shell ✅
**File:** `Views/Sleep/WakeUpAtView.swift`
**Time:** 30 minutes
**Components:**
- Gradient background (copy from SingleAlarmView)
- Moon icon + zzz animations (copy from SingleAlarmView)
- Current time display (copy from SingleAlarmView)
- Empty VStack for content

**Test:** View displays with background and animations

---

### Step 3: Add Time Picker ✅
**File:** `Views/Sleep/WakeUpAtView.swift` (add to Step 2)
**Time:** 20 minutes
**Components:**
- Section header "🌅 Set Your Wake-Up Time"
- DatePicker in wheel style
- Golden accent color
- Semi-transparent background

**Test:** Time picker displays and can be scrolled

---

### Step 4: Generate Mock Bedtime Data ✅
**File:** `Views/Sleep/WakeUpAtView.swift` (add to Step 2)
**Time:** 20 minutes
**Components:**
- MockBedtime struct
- generateMockData() function
- categorizedMockData() function
- Category helper functions (copied from SleepCalculator)

**Test:** Console log shows 6 mock bedtimes grouped by category

---

### Step 5: Display Bedtime Cards ✅
**File:** `Views/Sleep/WakeUpAtView.swift` (add to Step 2)
**Time:** 40 minutes
**Components:**
- BedtimeCard view component
- Category headers with icons
- ForEach loops for groups and cards
- Proper spacing and padding

**Test:** All 6 cards display correctly, grouped by category

---

### Step 6: Create SleepContainerView ✅
**File:** `Views/Sleep/SleepContainerView.swift`
**Time:** 40 minutes
**Components:**
- ModeToggle component
- Toggle state management
- View switching logic (if/else)
- Crossfade transition animation
- UserDefaults persistence

**Test:** Toggle switches between placeholder views smoothly

---

### Step 7: Wire Up Real Views ✅
**Files:**
- `Views/Sleep/SleepContainerView.swift` (modify)
- `App/Mr_SleepApp.swift` (modify)

**Time:** 15 minutes
**Changes:**
- Replace placeholder with SingleAlarmView (Sleep Now)
- Replace placeholder with WakeUpAtView (Wake Up At)
- Update app entry point to use SleepContainerView
- Pass environmentObject correctly

**Test:** Toggle switches between real Sleep Now and Wake Up At views

---

### Step 8: Polish & Test ✅
**Time:** 20 minutes
**Tasks:**
- Test toggle haptic feedback
- Test animations smoothness
- Verify layout on different screen sizes
- Check color consistency
- Test state persistence (kill app and reopen)

**Test:** Everything works smoothly, no bugs or glitches

---

## ✅ Testing Checklist

### Visual Validation
- [ ] Toggle displays correctly (golden for active, gray for inactive)
- [ ] Toggle animation smooth when switching
- [ ] Time picker displays with golden accent color
- [ ] Time picker wheel scrolls smoothly
- [ ] All 6 bedtime cards display
- [ ] Cards grouped into correct categories (Full Recharge, Recovery, Quick Boost)
- [ ] Category icons display (battery, heart, bolt)
- [ ] Card styling matches Sleep Now cards
- [ ] Gradient background matches Sleep Now
- [ ] Moon icon animates (breathing effect)
- [ ] zzz animations float correctly
- [ ] Current time displays at top

### Interaction Validation
- [ ] Tapping toggle switches mode immediately
- [ ] Haptic feedback fires on toggle tap
- [ ] Crossfade transition smooth (no jank)
- [ ] Time picker can be scrolled
- [ ] ScrollView scrolls smoothly
- [ ] No UI lag or stuttering

### State Persistence Validation
- [ ] Selected mode saves to UserDefaults
- [ ] Kill and reopen app → mode restored correctly
- [ ] Toggle state matches restored mode

### Layout Validation
- [ ] Test on iPhone 16 Pro simulator
- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone 16 Pro Max (large screen)
- [ ] Safe area handled correctly (top and bottom)
- [ ] No content cut off or overlapping

### Accessibility Validation
- [ ] Toggle readable by VoiceOver
- [ ] Time picker readable by VoiceOver
- [ ] All text meets contrast requirements
- [ ] Dynamic Type supported

---

## 🎨 Design Principles Reference

**Must Follow:** `/Users/magdoub/Desktop/Mr_Sleep_App_Design_Principles.md`

### Colors
- **Background:** Deep navy gradient `Color(red: 0.1, green: 0.25, blue: 0.5)` → `Color(red: 0.03, green: 0.08, blue: 0.2)`
- **Accent:** Golden yellow `Color(red: 0.894, green: 0.729, blue: 0.306)`
- **Secondary:** Light gray `Color(red: 0.7, green: 0.7, blue: 0.7)`
- **Card Background:** `Color(red: 0.12, green: 0.18, blue: 0.35).opacity(0.7)`

### Typography
- **Font:** SF Pro Rounded
- **Large Title:** 34pt, bold
- **Section Header:** 22pt, semibold
- **Time Display:** 32pt, bold
- **Body:** 17pt, regular
- **Caption:** 14pt, medium

### Spacing
- **Horizontal Padding:** 20pt
- **Vertical Spacing:** 15pt between cards, 30pt between sections
- **Corner Radius:** 20pt for cards, 24pt for toggle

### Animations
- **Transition:** Crossfade (opacity)
- **Duration:** 300ms
- **Curve:** Spring (response: 0.35, dampingFraction: 0.75)
- **Haptic:** Light impact

---

## 🚫 What NOT to Implement (Phase 1)

❌ Reverse sleep calculation logic
❌ Time picker onChange trigger
❌ Dynamic bedtime updates
❌ Alarm scheduling
❌ Card tap interaction
❌ Loading states
❌ Error handling
❌ Edge case validation

**These will be added in Phase 2 and beyond.**

---

## 📝 Notes & Gotchas

### Common Issues to Avoid
1. **Don't** try to calculate bedtimes in Phase 1 → just use mock data
2. **Don't** make cards tappable yet → they do nothing in Phase 1
3. **Don't** add loading animations → static view only
4. **Do** copy exact gradient from SingleAlarmView for consistency
5. **Do** reuse existing category icon names (battery-3D-icon, etc.)
6. **Do** test toggle state persistence thoroughly

### Performance Considerations
- Time picker is native iOS component → no performance issues expected
- 6 cards is small dataset → no need for lazy loading
- Animations should be smooth on all devices

### Future Considerations (Phase 2+)
- Time picker onChange will trigger calculation
- Cards will become tappable
- Need loading state between picker change and results update
- Need to handle edge cases (wake-up time in past, invalid selections)

---

## 🎯 Success Criteria (Phase 1)

### Must Have ✅
1. Toggle switches between Sleep Now and Wake Up At
2. Time picker displays with golden styling
3. 6 mock bedtime cards display correctly
4. Visual design matches Sleep Now exactly
5. All animations smooth (60fps)
6. State persists across app launches

### Nice to Have 🎁
1. Extra polish on toggle animation
2. Haptic feedback on all interactions
3. Smooth scroll performance
4. Perfect alignment and spacing

### User Approval Checkpoint 🛑
**STOP after Phase 1 complete.**
Get user feedback on:
- Toggle design and feel
- Time picker styling
- Card layout and spacing
- Overall visual consistency

**Do NOT proceed to Phase 2 until user approves UI.**

---

## 📚 Related Files

**Master PRD:** [`WakeUpAt_Feature_Master_PRD.md`](./WakeUpAt_Feature_Master_PRD.md)
**Design Principles:** `/Users/magdoub/Desktop/Mr_Sleep_App_Design_Principles.md`
**Reference View:** `Mr Sleep/Views/Sleep/SingleAlarmView.swift`
**Calculator:** `Mr Sleep/Models/SleepCalculator.swift`

---

**Document Version:** 1.0
**Last Updated:** November 2, 2025
**Next Phase:** Phase 2 - Calculation Logic (after user approval)

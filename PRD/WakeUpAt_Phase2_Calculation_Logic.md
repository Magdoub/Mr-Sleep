# Wake Up At Feature - Phase 2: Calculation Logic Implementation

**Feature:** Wake Up At - Reverse Sleep Calculator
**Phase:** 2 of 4 (Calculation Logic Integration)
**Master PRD:** [`WakeUpAt_Feature_Master_PRD.md`](./WakeUpAt_Feature_Master_PRD.md)
**Phase 1 (Complete):** [`WakeUpAt_Phase1_UI_Implementation.md`](./WakeUpAt_Phase1_UI_Implementation.md)
**Created:** November 16, 2025
**Status:** Ready to Implement
**Priority:** HIGH

---

## 🎯 Phase 2 Objective

**Implement reverse bedtime calculation logic while preserving the existing two-state flow UX.**

### Success Criteria
✅ Calculate button triggers real bedtime calculations
✅ Bedtime recommendations update based on selected wake-up time
✅ All 6 bedtimes calculated dynamically (1-6 sleep cycles)
✅ Categories assigned correctly based on cycle count
✅ Time-based category priority ordering works
✅ Calculations accurate to within 1 minute
✅ Existing animations and transitions preserved

### Constraints
✅ Preserve two-state flow (input → calculate → results)
✅ Keep all existing animations and UI
✅ No loading states needed (calculate button provides clear action)
✅ Maintain mock data structure (just replace hardcoded with calculated)

---

## 📋 Implementation Overview

### What We're Building

Replace the hardcoded mock data generation with real reverse sleep cycle calculations:

```swift
// BEFORE (Phase 1 - Mock Data)
let mockTimes: [(hour: Int, minute: Int, cycles: Int)] = [
    (23, 30, 5),  // Hardcoded
    (22, 0, 6),
    // ...
]

// AFTER (Phase 2 - Real Calculations)
let bedtimes = calculateBedtimes(for: selectedWakeUpTime)
// Returns: [(bedtime: Date, cycles: Int, duration: Double)]
```

---

## 🧮 Reverse Sleep Cycle Calculation Logic

### Mathematical Formula

```
Bedtime = Wake-Up Time - (Cycles × 90 minutes) - 15 minutes fall asleep buffer
```

### Examples

**Wake-Up Time:** 7:00 AM

| Cycles | Calculation | Bedtime | Total Sleep |
|--------|-------------|---------|-------------|
| 6 | 7:00 AM - (6 × 90min) - 15min | **12:45 AM** | 9.0h |
| 5 | 7:00 AM - (5 × 90min) - 15min | **2:15 AM** | 7.5h |
| 4 | 7:00 AM - (4 × 90min) - 15min | **3:45 AM** | 6.0h |
| 3 | 7:00 AM - (3 × 90min) - 15min | **5:15 AM** | 4.5h |
| 2 | 7:00 AM - (2 × 90min) - 15min | **6:30 AM** | 3.0h |
| 1 | 7:00 AM - (1 × 90min) - 15min | **7:45 AM** | 1.5h |

**Note:** 1 cycle = 1.5h would result in wake-up time in the past, so skip or handle as edge case.

---

## 🏗️ Implementation Plan

### Step 1: Create SleepCalculator Extension ✅

**File:** `/Models/SleepCalculator.swift` (add to existing file)

**Method:**
```swift
extension SleepCalculator {
    func calculateBedtimes(for wakeUpTime: Date) -> [(bedtime: Date, cycles: Int, duration: Double)] {
        var bedtimes: [(bedtime: Date, cycles: Int, duration: Double)] = []
        let calendar = Calendar.current

        // Calculate bedtimes for 1-6 cycles
        for cycles in 1...6 {
            // Each cycle is 90 minutes
            let cycleMinutes = cycles * 90

            // Add 15 minutes fall asleep buffer
            let totalMinutes = cycleMinutes + 15

            // Calculate bedtime by subtracting from wake-up time
            guard let bedtime = calendar.date(
                byAdding: .minute,
                value: -totalMinutes,
                to: wakeUpTime
            ) else { continue }

            // Round to nearest 5 minutes for cleaner display
            let roundedBedtime = roundToNearestFiveMinutes(bedtime)

            // Calculate total duration in hours
            let duration = Double(cycles) * 1.5

            bedtimes.append((bedtime: roundedBedtime, cycles: cycles, duration: duration))
        }

        return bedtimes
    }

    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: date)
        let roundedMinutes = (minutes / 5) * 5

        var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        components.minute = roundedMinutes

        return calendar.date(from: components) ?? date
    }
}
```

---

### Step 2: Update WakeUpAtView Data Model ✅

**File:** `/Views/WakeUpAtView.swift`

**Changes:**
1. Rename `MockBedtime` to `CalculatedBedtime` (semantic clarity)
2. Remove hardcoded mock data generation
3. Add real calculation trigger

**Updated Model:**
```swift
// Rename for clarity (or keep as MockBedtime, doesn't matter much)
struct CalculatedBedtime: Identifiable {
    let id = UUID()
    let bedtime: Date
    let wakeUpTime: Date
    let cycles: Int
    let duration: Double // in hours
}
```

---

### Step 3: Wire Calculate Button to Trigger Calculations ✅

**File:** `/Views/WakeUpAtView.swift`

**Update `calculateBedtimeButton` action:**
```swift
private var calculateBedtimeButton: some View {
    Button(action: {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // **NEW: Calculate real bedtimes**
        calculateRealBedtimes()

        // Slide to results state showing bedtime cards
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewState = .results
        }
    }) {
        Text("Calculate Bedtime")
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
            )
            .shadow(color: Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3), radius: 10, x: 0, y: 5)
    }
    .padding(.horizontal, 20)
}
```

---

### Step 4: Replace Mock Data with Calculated Data ✅

**File:** `/Views/WakeUpAtView.swift`

**Remove old `generateMockData()` method, add:**
```swift
private func calculateRealBedtimes() {
    // Use SleepCalculator to get bedtimes
    let calculated = SleepCalculator.shared.calculateBedtimes(for: selectedWakeUpTime)

    // Convert to CalculatedBedtime objects
    mockBedtimes = calculated.map { data in
        CalculatedBedtime(
            bedtime: data.bedtime,
            wakeUpTime: selectedWakeUpTime,
            cycles: data.cycles,
            duration: data.duration
        )
    }
}
```

**Remove call to `generateMockData()` in `onAppear`:**
```swift
// BEFORE
.onAppear {
    startAnimations()
    generateMockData()  // ❌ Remove this
}

// AFTER
.onAppear {
    startAnimations()
}
```

---

### Step 5: Update Category Assignment ✅

**File:** `/Views/WakeUpAtView.swift`

Category logic is already correct in Phase 1 implementation:
```swift
private func getCategoryForCycles(_ cycles: Int) -> String {
    switch cycles {
    case 1...2:
        return "Quick Boost"
    case 3...4:
        return "Recovery"
    case 5...:
        return "Full Recharge"
    default:
        return "Recovery"
    }
}
```

**No changes needed** - this already works with real data.

---

### Step 6: Verify Time-Based Priority Ordering ✅

**File:** `/Views/WakeUpAtView.swift`

Priority ordering logic is already correct in Phase 1:
```swift
private func getDynamicCategoryOrder() -> [String] {
    let currentHour = Calendar.current.component(.hour, from: Date())

    // If time is between 7:00 PM (19:00) and 6:00 AM, prioritize longer sleep
    if currentHour >= 19 || currentHour < 6 {
        return ["Full Recharge", "Recovery", "Quick Boost"]
    } else {
        // During daytime, prioritize shorter naps
        return ["Quick Boost", "Recovery", "Full Recharge"]
    }
}
```

**No changes needed** - this already works with real data.

---

## ✅ Implementation Checklist

### SleepCalculator Extension
- [ ] Add `calculateBedtimes(for wakeUpTime: Date)` method to SleepCalculator
- [ ] Implement reverse calculation logic (subtract cycles × 90min + 15min)
- [ ] Add `roundToNearestFiveMinutes()` helper method
- [ ] Test calculations manually with sample wake-up times
- [ ] Verify all 6 cycles (1-6) are calculated correctly
- [ ] Handle edge cases (wake-up time in past for 1 cycle)

### WakeUpAtView Updates
- [ ] Rename `MockBedtime` to `CalculatedBedtime` (optional, for clarity)
- [ ] Remove `generateMockData()` method entirely
- [ ] Add `calculateRealBedtimes()` method
- [ ] Wire up Calculate button to call `calculateRealBedtimes()`
- [ ] Remove `generateMockData()` call from `onAppear`
- [ ] Verify existing category assignment logic works with real data
- [ ] Verify existing priority ordering logic works with real data

### Testing
- [ ] Test with wake-up time: 7:00 AM
- [ ] Test with wake-up time: 12:00 PM (noon)
- [ ] Test with wake-up time: 11:59 PM (late night)
- [ ] Test with wake-up time: 6:00 AM (early morning)
- [ ] Verify bedtimes are rounded to nearest 5 minutes
- [ ] Verify categories assigned correctly (Quick Boost, Recovery, Full Recharge)
- [ ] Verify priority ordering changes based on time of day
- [ ] Test UI animations still work smoothly
- [ ] Test back button returns to input state correctly
- [ ] Test changing wake-up time and recalculating

### Edge Cases
- [ ] Handle wake-up time resulting in bedtime in the past (1 cycle case)
- [ ] Handle wake-up time at midnight (day boundary)
- [ ] Handle wake-up time near current time (very short sleep)
- [ ] Verify calculations work across day boundaries (e.g., wake at 2 AM)

---

## 🧪 Testing Scenarios

### Scenario 1: Morning Wake-Up
**Input:** Wake-up time = 7:00 AM
**Expected Output:**
- 6 cycles → 12:45 AM (9.0h) - Full Recharge
- 5 cycles → 2:15 AM (7.5h) - Full Recharge
- 4 cycles → 3:45 AM (6.0h) - Recovery
- 3 cycles → 5:15 AM (4.5h) - Recovery
- 2 cycles → 6:30 AM (3.0h) - Quick Boost
- 1 cycle → 7:45 AM (1.5h) - Skip (in past) or Quick Boost

### Scenario 2: Afternoon Nap
**Input:** Wake-up time = 2:00 PM
**Expected Output:**
- 6 cycles → 6:45 AM (9.0h) - Full Recharge
- 5 cycles → 8:15 AM (7.5h) - Full Recharge
- 4 cycles → 9:45 AM (6.0h) - Recovery
- 3 cycles → 11:15 AM (4.5h) - Recovery
- 2 cycles → 12:30 PM (3.0h) - Quick Boost
- 1 cycle → 1:45 PM (1.5h) - Quick Boost

### Scenario 3: Late Night Wake-Up
**Input:** Wake-up time = 1:00 AM
**Expected Output:**
- 6 cycles → 3:45 PM (previous day) (9.0h) - Full Recharge
- 5 cycles → 5:15 PM (previous day) (7.5h) - Full Recharge
- 4 cycles → 6:45 PM (previous day) (6.0h) - Recovery
- 3 cycles → 8:15 PM (previous day) (4.5h) - Recovery
- 2 cycles → 9:30 PM (previous day) (3.0h) - Quick Boost
- 1 cycle → 11:45 PM (previous day) (1.5h) - Quick Boost

---

## 🚫 What NOT to Implement (Phase 2)

❌ Loading animations (two-state flow already provides clear UX)
❌ onChange listener on time picker (only calculate on button tap)
❌ Caching or optimization (too early, implement in Phase 3)
❌ Alarm scheduling (Phase 4 feature)
❌ Card tap interaction (Phase 4 feature)
❌ Settings or preferences (Phase 3 or later)

**Keep it simple:** Just replace mock data with calculated data.

---

## 📊 Validation Criteria

### Calculation Accuracy
✅ Bedtimes match manual calculation within ±1 minute
✅ Rounding to nearest 5 minutes works correctly
✅ All 6 cycles calculated for any wake-up time
✅ Day boundary calculations work (e.g., wake at 2 AM → bed at 5 PM previous day)

### UI/UX Preservation
✅ Two-state flow unchanged (input → calculate → results → back)
✅ All animations smooth (logo slide, subtitle slide, state transitions)
✅ Category headers still fade in with stagger
✅ Back button still works correctly
✅ Haptic feedback still triggers

### Category Logic
✅ 1-2 cycles → Quick Boost
✅ 3-4 cycles → Recovery
✅ 5-6 cycles → Full Recharge
✅ Priority ordering changes based on time (7PM-6AM: Full Recharge first)

---

## 🎯 Success Metrics (Phase 2)

### Must Have ✅
1. Calculate button triggers real bedtime calculations
2. All 6 bedtimes calculated accurately
3. Categories assigned correctly
4. Priority ordering works
5. UI animations preserved
6. No regressions from Phase 1

### Nice to Have 🎁
1. Edge cases handled gracefully (1 cycle in past)
2. Perfect rounding to 5-minute intervals
3. Calculation happens instantly (no perceived delay)
4. Memory efficient (no leaks)

---

## 📝 Implementation Notes

### Why Not Add Loading State?
- **Calculate button** already provides clear user action
- **Calculations are instant** (<10ms) - no need to show loading
- **Two-state flow** naturally separates input from results
- **Adding loading would complicate UX** without benefit

### Why Not Use onChange on Time Picker?
- **User control:** Let users finalize their time before calculating
- **Avoid excessive calculations:** User might scroll through many times
- **Clear intent:** Calculate button makes action explicit
- **Phase 3 consideration:** Can add debounced onChange later if needed

### Why Keep mockBedtimes Variable Name?
- **Minimal changes:** Less refactoring, less risk of bugs
- **Semantics don't matter:** It's a private implementation detail
- **Can rename later:** If we want, but not necessary for Phase 2

---

## 🔄 Next Steps After Phase 2

### Phase 3: Polish & Advanced Features
- Add debounce if user changes time picker after viewing results
- Cache calculations for common wake-up times
- Add haptic feedback when calculation completes
- Handle edge cases (wake-up time in past, etc.)
- Accessibility audit and improvements

### Phase 4: Alarm Integration
- Make bedtime cards tappable
- Schedule AlarmKit alarm for wake-up time
- Store bedtime as metadata
- Integration with existing SingleAlarmView

---

## 📚 Related Documentation

- **Master PRD:** [`WakeUpAt_Feature_Master_PRD.md`](./WakeUpAt_Feature_Master_PRD.md)
- **Phase 1 Complete:** [`WakeUpAt_Phase1_UI_Implementation.md`](./WakeUpAt_Phase1_UI_Implementation.md)
- **Design Principles:** `/Users/magdoub/Desktop/Mr_Sleep_App_Design_Principles.md`
- **SleepCalculator:** `Mr Sleep/Models/SleepCalculator.swift`
- **WakeUpAtView:** `Mr Sleep/Views/WakeUpAtView.swift`

---

**Document Version:** 1.0
**Created:** November 16, 2025
**Ready to Implement:** Yes ✅
**Estimated Time:** 1-2 hours

//
//  WakeUpAtView.swift
//  Mr Sleep
//
//  Created by Claude on 02/11/2025.
//

/*
 * Wake Up At View - Reverse Sleep Calculator (Phase 1: UI Only)
 *
 * This view allows users to select a desired wake-up time and see suggested bedtimes.
 * Visual design matches SingleAlarmView for consistency.
 *
 * Phase 1 Implementation:
 * - UI-only with mock/hardcoded bedtime data
 * - NO calculation logic yet
 * - Time picker is static (doesn't trigger updates)
 * - Focus is on design validation
 *
 * Components:
 * - Same gradient background as Sleep Now
 * - Same moon icon with breathing animation
 * - Same zzz floating animations
 * - Current time display
 * - Time picker for wake-up time selection
 * - Mock bedtime cards (6 hardcoded times)
 */

import SwiftUI

// MARK: - Mock Bedtime Data Model
struct MockBedtime: Identifiable {
    let id = UUID()
    let bedtime: Date
    let wakeUpTime: Date
    let cycles: Int
    let duration: Double // in hours
}

// MARK: - Wake Up At View
struct WakeUpAtView: View {
    // MARK: - State Properties

    // Time picker state (Phase 1: static, doesn't trigger calculations)
    @State private var selectedWakeUpTime: Date = Date().addingTimeInterval(8 * 3600) // Default: 8 hours from now

    // Mock data (Phase 1: hardcoded)
    @State private var mockBedtimes: [MockBedtime] = []

    // Animation states
    @State private var currentTime = Date()
    @State private var timeAnimationTrigger = false
    @State private var contentOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 20
    @State private var timeOffset: CGFloat = 15
    @State private var categoryHeadersVisible: Bool = false

    // Moon animation
    @State private var currentMoonIcon = "moon-3D-icon"
    @State private var moonRotation: Double = 0
    @State private var moonBreathingScale: Double = 1.0

    // zzz animations
    @State private var zzzFloatingOffsets: [CGFloat] = [0, 0, 0]
    @State private var zzzOpacities: [Double] = [0.9, 0.8, 0.7]

    // Accessibility
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Timer for current time updates
    @State private var timeUpdateTimer: Timer?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient - SAME AS SLEEP NOW
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.25, blue: 0.5),
                    Color(red: 0.06, green: 0.15, blue: 0.35),
                    Color(red: 0.03, green: 0.08, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            // Main content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 25) {
                    Spacer(minLength: 20)

                    // App Title with animated moon and floating zzz - SAME AS SLEEP NOW
                    HStack(spacing: 15) {
                        HStack(spacing: 12) {
                            Image(currentMoonIcon)
                                .resizable()
                                .frame(width: 90, height: 90)
                                .scaleEffect(reduceMotion ? 1.0 : moonBreathingScale)
                                .rotationEffect(.degrees(reduceMotion ? 0 : moonRotation))
                                .accessibilityLabel("Moon icon")
                                .accessibilityHidden(true)

                            Text("Mr Sleep")
                                .font(.largeTitle)
                                .fontWeight(.medium)
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                        }

                        ForEach(0..<3) { index in
                            Text("z")
                                .font([.title, .title2, .title3][index])
                                .fontWeight(.light)
                                .foregroundColor(.white.opacity([0.9, 0.8, 0.7][index]))
                                .offset(x: [-5, -8, -10][index], y: [-5, -8, -12][index] + zzzFloatingOffsets[index])
                                .opacity(zzzOpacities[index])
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Mr Sleep app title")
                    .accessibilityAddTraits(.isHeader)
                    .opacity(contentOpacity)
                    .offset(y: titleOffset)

                    Spacer()

                    // Current time display - SAME AS SLEEP NOW
                    VStack(spacing: 8) {
                        Text("Current Time")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                            .accessibilityHidden(true)

                        Text(getCurrentTime())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundColor(.white)
                            .scaleEffect(timeAnimationTrigger ? 1.1 : 1.0)
                            .opacity(timeAnimationTrigger ? 0.7 : 1.0)
                            .offset(y: timeAnimationTrigger ? -2 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: timeAnimationTrigger)
                            .accessibilityHidden(true)
                            .frame(minWidth: 120)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Current time is \(getCurrentTime())")
                    .accessibilityAddTraits([.updatesFrequently, .playsSound])
                    .accessibilityValue(getCurrentTime())
                    .opacity(contentOpacity)
                    .offset(y: timeOffset)

                    // Wake-up message
                    VStack(spacing: 12) {
                        Text("Wake Up At . Sleep Smart")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Plan your bedtime for optimal sleep cycles")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Choose when you want to wake up")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Wake Up At . Sleep Smart. Plan your bedtime for optimal sleep cycles. Choose when you want to wake up.")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHint("Scroll down to set your wake-up time")
                    .opacity(contentOpacity)

                    // Time Picker Section
                    timePickerSection
                        .opacity(contentOpacity)
                        .padding(.top, 10)

                    // Mock Bedtime Cards
                    bedtimeCardsSection
                        .opacity(contentOpacity)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startAnimations()
            generateMockData()
            startTimeUpdates()
        }
        .onDisappear {
            stopTimeUpdates()
        }
    }

    // MARK: - Time Picker Section

    private var timePickerSection: some View {
        VStack(alignment: .center, spacing: 15) {
            // Section header
            Text("🌅 Set Your Wake-Up Time")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            // Time picker
            DatePicker(
                "",
                selection: $selectedWakeUpTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(Color(red: 0.894, green: 0.729, blue: 0.306))
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.15, blue: 0.3).opacity(0.6))
            )
            .padding(.horizontal, 20)
            .accessibilityLabel("Wake-up time picker")
            .accessibilityHint("Scroll to select your desired wake-up time")
        }
    }

    // MARK: - Bedtime Cards Section

    private var bedtimeCardsSection: some View {
        VStack(spacing: 20) {
            ForEach(Array(categorizedMockData().enumerated()), id: \.offset) { categoryIndex, categoryData in
                VStack(spacing: 12) {
                    // Category header
                    HStack(alignment: .center, spacing: 12) {
                        getCategoryIconImage(for: categoryData.category)
                            .frame(width: 40, height: 40)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(categoryData.category)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))

                            Text(getCategoryTagline(categoryData.category))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(categoryData.category). \(getCategoryTagline(categoryData.category))")
                    .accessibilityAddTraits(.isHeader)
                    .opacity(categoryHeadersVisible ? 1.0 : 0.0)
                    .scaleEffect(categoryHeadersVisible ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(categoryIndex) * 0.1), value: categoryHeadersVisible)

                    // Bedtime cards in this category
                    ForEach(categoryData.bedtimes) { bedtime in
                        BedtimeCard(bedtime: bedtime)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }

    private func generateMockData() {
        let calendar = Calendar.current
        var baseComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        // Phase 1: Hardcoded bedtime options (no calculation logic)
        let mockTimes: [(hour: Int, minute: Int, cycles: Int)] = [
            (23, 30, 5),  // 11:30 PM - 5 cycles (7.5h)
            (22, 0, 6),   // 10:00 PM - 6 cycles (9h)
            (0, 45, 4),   // 12:45 AM - 4 cycles (6h)
            (1, 15, 3),   // 1:15 AM - 3 cycles (4.5h)
            (3, 0, 2),    // 3:00 AM - 2 cycles (3h)
            (5, 15, 1)    // 5:15 AM - 1 cycle (1.5h)
        ]

        mockBedtimes = mockTimes.map { data in
            // Handle midnight crossing
            if data.hour < 12 && data.hour != 0 {
                // AM times (after midnight) should be next day
                baseComponents.day! += 1
            }

            baseComponents.hour = data.hour
            baseComponents.minute = data.minute

            let bedtime = calendar.date(from: baseComponents)!
            let duration = Double(data.cycles) * 1.5

            // Reset for next iteration
            baseComponents = calendar.dateComponents([.year, .month, .day], from: Date())

            return MockBedtime(
                bedtime: bedtime,
                wakeUpTime: selectedWakeUpTime,
                cycles: data.cycles,
                duration: duration
            )
        }
    }

    private func categorizedMockData() -> [(category: String, bedtimes: [MockBedtime])] {
        // Group bedtimes by category
        let grouped = Dictionary(grouping: mockBedtimes) { bedtime in
            getCategoryForCycles(bedtime.cycles)
        }

        // Order categories (same logic as SleepCalculator)
        let categoryOrder = getDynamicCategoryOrder()

        return categoryOrder.compactMap { category in
            guard let bedtimes = grouped[category], !bedtimes.isEmpty else { return nil }
            // Sort by cycles descending (longest sleep first in each category)
            let sorted = bedtimes.sorted { $0.cycles > $1.cycles }
            return (category: category, bedtimes: sorted)
        }
    }

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

    private func getCategoryTagline(_ category: String) -> String {
        switch category {
        case "Full Recharge":
            return "7.5-9h for maximum energy"
        case "Recovery":
            return "4.5-6h for solid rest"
        case "Quick Boost":
            return "1.5-3h for a power nap"
        default:
            return ""
        }
    }

    private func getCategoryIconImage(for category: String) -> some View {
        let iconName: String
        switch category {
        case "Quick Boost":
            iconName = "bolt-3D-icon"
        case "Recovery":
            iconName = "heart-3D-icon"
        case "Full Recharge":
            iconName = "battery-3D-icon"
        default:
            iconName = "moon.fill"
        }

        return Image(iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

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

    // MARK: - Animations

    private func startAnimations() {
        // Initial fade-in
        withAnimation(.easeOut(duration: 0.8)) {
            contentOpacity = 1.0
            titleOffset = 0
            timeOffset = 0
        }

        // Delayed category header reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                categoryHeadersVisible = true
            }
        }

        // Moon breathing animation
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                moonBreathingScale = 1.05
            }

            withAnimation(.linear(duration: 60.0).repeatForever(autoreverses: false)) {
                moonRotation = 360
            }
        }

        // zzz floating animations
        if !reduceMotion {
            for i in 0..<3 {
                let delay = Double(i) * 0.3
                let duration = 2.0 + Double(i) * 0.5

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        zzzFloatingOffsets[i] = -15
                    }

                    withAnimation(.easeInOut(duration: duration * 0.8).repeatForever(autoreverses: true)) {
                        zzzOpacities[i] = [0.3, 0.2, 0.1][i]
                    }
                }
            }
        }
    }

    private func startTimeUpdates() {
        // Update current time every minute
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            currentTime = Date()

            // Trigger micro animation
            timeAnimationTrigger = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                timeAnimationTrigger = false
            }
        }
    }

    private func stopTimeUpdates() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
}

// MARK: - Bedtime Card Component

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Go to bed at \(formatTime(bedtime.bedtime)) for \(String(format: "%.1f", bedtime.duration)) hours of sleep")
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    WakeUpAtView()
}

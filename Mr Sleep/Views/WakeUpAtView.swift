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

// MARK: - Wake Up View State
enum WakeUpViewState {
    case input    // Shows time picker and calculate button
    case results  // Shows bedtime cards and back button
}

// MARK: - Wake Up At View
struct WakeUpAtView: View {
    // MARK: - State Properties

    // Time picker state (Phase 1: static, doesn't trigger calculations)
    @State private var selectedWakeUpTime: Date = Date().addingTimeInterval(8 * 3600) // Default: 8 hours from now

    // Mock data (Phase 1: hardcoded)
    @State private var mockBedtimes: [MockBedtime] = []

    // View state (input vs results)
    @State private var viewState: WakeUpViewState = .input

    // Animation states
    @State private var contentOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = -50  // Logo slides from top
    @State private var subtitleOffset: CGFloat = 30  // Subtitle slides from bottom
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

                    // App Title with animated moon and floating zzz
                    VStack(spacing: 12) {
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
                        .offset(y: titleOffset)  // Logo slides from top

                        // Subtitle - ONLY show in input state
                        if viewState == .input {
                            Text("What time do you want to wake up at")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .offset(y: subtitleOffset)  // Subtitle slides from bottom
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Mr Sleep app title. What time do you want to wake up at")
                    .accessibilityAddTraits(.isHeader)
                    .opacity(contentOpacity)

                    Spacer()

                    // INPUT STATE: Subtitle, Time Picker, and Calculate Button
                    if viewState == .input {
                        VStack(spacing: 25) {
                            // Subtitle (already shown in header, keeping for input state)

                            // Time Picker Section
                            timePickerSection
                                .padding(.top, 10)

                            // Calculate Bedtime Button
                            calculateBedtimeButton
                                .padding(.top, 20)
                        }
                        .opacity(contentOpacity)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // RESULTS STATE: Bedtime Cards with Back Button
                    if viewState == .results {
                        VStack(spacing: 20) {
                            // Back button
                            HStack {
                                Button(action: {
                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()

                                    // Slide back to input state
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        viewState = .input
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text("Back")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                                }
                                .accessibilityLabel("Back to time picker")
                                .padding(.horizontal, 20)

                                Spacer()
                            }

                            // Results header text
                            VStack(spacing: 8) {
                                Text("If you want to wake up at \(formatWakeUpTime())")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                                    .multilineTextAlignment(.center)

                                Text("Go to bed at any of these times")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                            // Bedtime Cards
                            bedtimeCardsSection
                                .padding(.top, 20)
                                .padding(.bottom, 40)
                        }
                        .opacity(contentOpacity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
            // Phase 2: Calculations now triggered by Calculate button, not on appear
        }
    }

    // MARK: - Time Picker Section

    private var timePickerSection: some View {
        DatePicker(
            "",
            selection: $selectedWakeUpTime,
            displayedComponents: [.hourAndMinute]
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .tint(Color(red: 0.894, green: 0.729, blue: 0.306))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .accessibilityLabel("Wake-up time picker")
        .accessibilityHint("Scroll to select your desired wake-up time")
    }

    // MARK: - Calculate Bedtime Button

    private var calculateBedtimeButton: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // Phase 2: Calculate real bedtimes
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
        .accessibilityLabel("Calculate Bedtime")
        .accessibilityHint("Tap to see suggested bedtimes based on your selected wake-up time")
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

    private func formatWakeUpTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: selectedWakeUpTime)
    }

    // MARK: - Phase 2: Real Bedtime Calculation

    /// Calculate real bedtimes using SleepCalculator
    private func calculateRealBedtimes() {
        // Use SleepCalculator to get bedtimes for the selected wake-up time
        let calculated = SleepCalculator.shared.calculateBedtimes(for: selectedWakeUpTime)

        // Convert to MockBedtime objects (keeping same data structure)
        mockBedtimes = calculated.map { data in
            MockBedtime(
                bedtime: data.bedtime,
                wakeUpTime: selectedWakeUpTime,
                cycles: data.cycles,
                duration: data.duration
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
        // Initial fade-in and logo slide from top
        withAnimation(.easeOut(duration: 0.8)) {
            contentOpacity = 1.0
            titleOffset = 0
        }

        // Subtitle slide from bottom (delayed)
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            subtitleOffset = 0
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

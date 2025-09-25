//
//  SingleAlarmView.swift
//  Mr Sleep
//
//  Created by Claude on 25/09/2025.
//

/*
 * Single Alarm Experience - Exact SleepNowView Layout
 * 
 * This view looks and animates exactly like SleepNowView but with single alarm functionality:
 * - Same gradient background and animations
 * - Same moon icon, zzz animations, and time display
 * - Same categorized wake-up times layout
 * - Same loading animations (CalculatingWakeUpTimesView, FinishingUpView)
 * - Adds single alarm selection, adjustment, and active states
 * - State persistence across app launches
 */

import SwiftUI
import AVFoundation
import AudioToolbox
import AlarmKit

// MARK: - Single Alarm Data Model
struct SingleAlarmData: Codable {
    let alarmTime: Date
    let startTime: Date
    let cycles: Int
    let alarmID: UUID?
    
    static let userDefaultsKey = "SingleAlarmData"
    
    // Initializer for backward compatibility
    init(alarmTime: Date, startTime: Date, cycles: Int, alarmID: UUID? = nil) {
        self.alarmTime = alarmTime
        self.startTime = startTime
        self.cycles = cycles
        self.alarmID = alarmID
    }
}

// MARK: - Alarm Selection State
enum SingleAlarmState: Equatable {
    case none
    case selected(time: Date, cycles: Int, adjustmentMinutes: Int)
    case active(alarmTime: Date, startTime: Date, alarmID: UUID?)
}

// OnboardingStep is defined in SleepNowView.swift

// MARK: - Main Single Alarm View
struct SingleAlarmView: View {
    @Environment(AlarmKitViewModel.self) private var alarmViewModel
    
    // Single alarm state
    @State private var singleAlarmState: SingleAlarmState = .none
    @State private var showAdjustmentControls = false
    @State private var confirmationProgress: CGFloat = 0
    @State private var isDragging = false
    @State private var countdownDisplay = ""
    @State private var progressValue: Double = 0.0
    
    // Exact SleepNowView state variables
    @State private var isCreatingAlarm = false
    @State private var lastAlarmCreationTime: Date?
    @State private var categorizedWakeUpTimes: [(category: String, times: [(time: Date, cycles: Int)])] = []
    @State private var showSleepGuide = false
    @State private var currentTime = Date()
    @State private var timeAnimationTrigger = false
    @State private var zzzAnimation = false
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var contentOpacity: Double = 0
    @State private var titleOffset: CGFloat = -50
    @State private var timeOffset: CGFloat = 30
    @State private var zzzFloatingOffsets: [CGFloat] = [0, 0, 0]
    @State private var zzzOpacities: [Double] = [1.0, 0.8, 0.6]
    @State private var breathingScale: Double = 1.0
    @State private var currentMoonIcon: String = "moon-3D-icon"
    @State private var wakeUpTimeVisibility: [Bool] = [false, false, false, false, false, false]
    @State private var categoryHeadersVisible: Bool = false
    @State private var isCalculatingWakeUpTimes = false
    @State private var calculationProgress: Double = 0.0
    @State private var isFinishingUp = false
    @State private var hasCompletedInitialLoading = false
    
    // Timer to update time every second for real-time display
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let countdownTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient - Exact same as SleepNowView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.25, blue: 0.5), // Darker blue
                        Color(red: 0.06, green: 0.15, blue: 0.35), // Much darker blue
                        Color(red: 0.03, green: 0.08, blue: 0.2) // Very dark blue
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.container, edges: .all)
                
                // Handle different view states
                if case .active(let alarmTime, let startTime, _) = singleAlarmState {
                    activeAlarmView(alarmTime: alarmTime, startTime: startTime, geometry: geometry)
                } else if case .selected(let selectedTime, let cycles, let adjustmentMinutes) = singleAlarmState {
                    fullScreenAdjustmentView(selectedTime: selectedTime, cycles: cycles, adjustmentMinutes: adjustmentMinutes, geometry: geometry)
                } else if showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding, onComplete: startPostOnboardingLoading)
                } else if showSleepGuide {
                    SleepGuideView(showSleepGuide: $showSleepGuide)
                } else {
                    // Main content - exact copy of SleepNowView structure
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 25) {
                            Spacer(minLength: 20)
                        
                        // App Title with animated moon and floating zzz - EXACT COPY
                        HStack(spacing: 15) {
                            HStack(spacing: 12) {
                                Image(currentMoonIcon)
                                    .resizable()
                                    .frame(width: 90, height: 90)
                                    .accessibilityLabel("Moon icon")
                                    .accessibilityHidden(true)
                                Text("Mr Sleep")
                                    .font(.system(size: 36, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                            }
                            ForEach(0..<3) { index in
                                Text("z")
                                    .font(.system(size: [30, 25, 20][index], weight: .light))
                                    .foregroundColor(Color(red: [0.9, 0.85, 0.8][index], green: [0.9, 0.85, 0.8][index], blue: [0.95, 0.9, 0.85][index]))
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
                        
                        // Current time display with micro animation - EXACT COPY
                        VStack(spacing: 8) {
                            Text("Current Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                                .accessibilityHidden(true)
                            
                            Text(getCurrentTime())
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
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
                        
                        // Sleep message - EXACT COPY
                        VStack(spacing: 12) {
                            Text("Sleep Now . Wake up Like a Boss")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("You will feel refreshed and not tired")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("Set your alarm for a wake up time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                                .multilineTextAlignment(.center)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Sleep Now . Wake up like boss. You will feel refreshed and not tired. Set your alarm for a wake up time that suits you.")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHint("Scroll down to see wake-up time options")
                        .opacity(contentOpacity)
                        
                        
                        // Wake up times or loading animation - EXACT COPY
                        if isCalculatingWakeUpTimes {
                            CalculatingWakeUpTimesView(progress: calculationProgress)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Calculating wake-up times")
                                .accessibilityValue("\(Int(calculationProgress * 100)) percent complete")
                                .accessibilityAddTraits(.updatesFrequently)
                        } else if isFinishingUp {
                            FinishingUpView()
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Finishing up calculation")
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            // Categorized wake up times - EXACT COPY with single alarm selection
                            VStack(spacing: 20) {
                                ForEach(Array(categorizedWakeUpTimes.enumerated()), id: \.offset) { categoryIndex, categoryData in
                                    VStack(spacing: 12) {
                                        // Category header with icon and tagline - EXACT COPY
                                        HStack(alignment: .center, spacing: 12) {
                                            getCategoryIconImage(for: categoryData.category)
                                                .frame(width: 40, height: 40)
                                            
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
                                        .accessibilityAddTraits(.isHeader)
                                        .opacity(categoryHeadersVisible ? 1.0 : 0.0)
                                        .scaleEffect(categoryHeadersVisible ? 1.0 : 0.8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(categoryIndex) * 0.1), value: categoryHeadersVisible)
                                        
                                        // Times in this category - EXACT COPY with single alarm selection
                                        ForEach(Array(categoryData.times.enumerated()), id: \.offset) { timeIndex, timeData in
                                            let overallIndex = getOverallIndex(categoryIndex: categoryIndex, timeIndex: timeIndex)
                                            
                                            let isSelected = {
                                                if case .selected(let selectedTime, _, _) = singleAlarmState {
                                                    return Calendar.current.isDate(timeData.time, equalTo: selectedTime, toGranularity: .minute)
                                                }
                                                return false
                                            }()
                                            
                                            WakeUpTimeButton(
                                                wakeUpTime: SleepCalculator.shared.formatTime(timeData.time),
                                                currentTime: "",
                                                sleepDuration: formatSleepDurationSimple(cycles: timeData.cycles),
                                                isRecommended: false,
                                                cycles: timeData.cycles,
                                                pulseScale: 1.0,
                                                onTap: {
                                                    selectSingleAlarm(time: timeData.time, cycles: timeData.cycles)
                                                },
                                                isCreatingAlarm: isCreatingAlarm
                                            )
                                            .opacity(isSelected ? 0.8 : (overallIndex < wakeUpTimeVisibility.count && wakeUpTimeVisibility[overallIndex] ? 1.0 : 0.0))
                                            .scaleEffect(isSelected ? 1.05 : (overallIndex < wakeUpTimeVisibility.count && wakeUpTimeVisibility[overallIndex] ? 1.0 : 0.8))
                                            .offset(y: overallIndex < wakeUpTimeVisibility.count && wakeUpTimeVisibility[overallIndex] ? 0 : 20)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(overallIndex) * 0.15), value: overallIndex < wakeUpTimeVisibility.count ? wakeUpTimeVisibility[overallIndex] : false)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Wake-up time options grouped by category.")
                            .accessibilityHint("Swipe right on each option to activate.")
                        }
                        
                        Spacer()
                        
                        Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathingScale)
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            // Pre-calculate wake up times for instant display
            calculateWakeUpTimes()
            currentTime = Date()
            loadSavedAlarmState()
            
            // Only start animations and select moon if onboarding is not active AND initial loading hasn't been completed
            if !showOnboarding && !hasCompletedInitialLoading {
                selectNextMoonIcon()
                startEntranceAnimation()
                startBreathingEffect()
                startZzzAnimation()
            } else if !showOnboarding {
                // If we've already completed initial loading, just start the breathing effect and select moon
                selectNextMoonIcon()
                startBreathingEffect()
                startZzzAnimation()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateTimeAndCalculations()
            triggerTimeAnimation()
            selectNextMoonIcon()
        }
        .onReceive(timer) { _ in
            let newTime = Date()
            
            // Defensive check for valid time
            guard !newTime.timeIntervalSince1970.isNaN && 
                  !newTime.timeIntervalSince1970.isInfinite &&
                  !currentTime.timeIntervalSince1970.isNaN &&
                  !currentTime.timeIntervalSince1970.isInfinite else {
                print("Invalid time detected in timer, skipping update")
                return
            }
            
            let oldMinute = Calendar.current.component(.minute, from: currentTime)
            let newMinute = Calendar.current.component(.minute, from: newTime)
            
            // Trigger animation when minute changes (with bounds checking)
            if oldMinute != newMinute && oldMinute >= 0 && newMinute >= 0 && 
               oldMinute <= 59 && newMinute <= 59 {
                calculateWakeUpTimes()
                triggerTimeAnimation()
            }
            
            currentTime = newTime
            
            // Update countdown if in active state
            if case .active = singleAlarmState {
                updateCountdown()
            }
        }
        .onReceive(countdownTimer) { _ in
            if case .active = singleAlarmState {
                updateCountdown()
            }
        }
    }
    
    // MARK: - Helper Methods (exact copies from SleepNowView)
    private func updateTimeAndCalculations() {
        currentTime = Date()
        calculateWakeUpTimes()
    }
    
    private func triggerTimeAnimation() {
        // Defensive animation handling
        guard !timeAnimationTrigger else {
            return // Don't trigger if animation is already in progress
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            timeAnimationTrigger = true
        }
        
        // Reset animation after the spring completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                timeAnimationTrigger = false
            }
        }
    }
    
    private func calculateWakeUpTimes() {
        categorizedWakeUpTimes = SleepCalculator.shared.getCategorizedWakeUpTimes()
    }
    
    private func selectNextMoonIcon() {
        let moonIcons = ["moon-3D-icon", "moon-cool-3D-icon", "moon-mask-3D-icon"]
        
        // Get current index from UserDefaults (default to 0 for first launch)
        let currentIndex = UserDefaults.standard.integer(forKey: "moonIconIndex")
        
        // Set the current moon icon
        currentMoonIcon = moonIcons[currentIndex]
        
        // Calculate next index and save it for next launch
        let nextIndex = (currentIndex + 1) % moonIcons.count
        UserDefaults.standard.set(nextIndex, forKey: "moonIconIndex")
    }
    
    private func startEntranceAnimation() {
        // Immediate setup for smooth entrance
        hasCompletedInitialLoading = true
        
        // Start the entrance animation sequence
        withAnimation(.easeOut(duration: 0.8)) {
            contentOpacity = 1.0
            titleOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            timeOffset = 0
        }
        
        // Start calculating animation after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startCalculatingAnimation()
        }
    }
    
    private func startCalculatingAnimation() {
        isCalculatingWakeUpTimes = true
        calculationProgress = 0.0
        
        // Animate progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            calculationProgress += 0.02
            
            if calculationProgress >= 1.0 {
                timer.invalidate()
                showFinishingUpAnimation()
            }
        }
    }
    
    private func showFinishingUpAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCalculatingWakeUpTimes = false
            isFinishingUp = true
        }
        
        // Show finishing up briefly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isFinishingUp = false
                showWakeUpTimes()
            }
        }
    }
    
    private func showWakeUpTimes() {
        // Initialize visibility array
        let totalTimes = categorizedWakeUpTimes.flatMap { $0.times }.count
        wakeUpTimeVisibility = Array(repeating: false, count: totalTimes)
        
        // Show category headers first
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            categoryHeadersVisible = true
        }
        
        // Then animate wake-up times with staggered delays
        for i in 0..<wakeUpTimeVisibility.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    wakeUpTimeVisibility[i] = true
                }
            }
        }
    }
    
    private func startBreathingEffect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.02
            }
        }
    }
    
    private func startZzzAnimation() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                withAnimation(.easeInOut(duration: 2.0 + Double(i) * 0.2).repeatForever(autoreverses: true)) {
                    zzzFloatingOffsets[i] = [-3, -5, -7][i]
                    zzzOpacities[i] = [0.6, 0.4, 0.3][i]
                }
            }
        }
    }
    
    private func startPostOnboardingLoading() {
        // Called when onboarding completes - same as SleepNowView
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        withAnimation(.easeOut(duration: 0.5)) {
            showOnboarding = false
        }
        
        // Start animations after onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectNextMoonIcon()
            startEntranceAnimation()
            startBreathingEffect()
            startZzzAnimation()
        }
    }
    
    private func getOverallIndex(categoryIndex: Int, timeIndex: Int) -> Int {
        var totalIndex = 0
        
        for i in 0..<categoryIndex {
            if i < categorizedWakeUpTimes.count {
                totalIndex += categorizedWakeUpTimes[i].times.count
            }
        }
        
        return totalIndex + timeIndex
    }
    
    private func getCurrentTime() -> String {
        guard !currentTime.timeIntervalSince1970.isNaN && !currentTime.timeIntervalSince1970.isInfinite else {
            print("Invalid current time, using fallback")
            return "12:00 AM"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        let formattedTime = formatter.string(from: currentTime)
        return formattedTime.isEmpty ? "12:00 AM" : formattedTime
    }
    
    private func getCategoryTagline(_ category: String) -> String {
        switch category {
        case "Quick Boost":
            return "Recharge fast without feeling like a zombie"
        case "Recovery":
            return "Enough to reset your mind and body"
        case "Full Recharge":
            return "Wake up fully restored and ready"
        default:
            return ""
        }
    }
    
    @ViewBuilder
    private func getCategoryIconImage(for category: String) -> some View {
        let iconName = SleepCalculator.shared.getCategoryIcon(category)
        
        if iconName.contains("-3D-icon") {
            // Custom 3D icon from assets
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // System SF Symbol
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
        }
    }
    
    private func formatSleepDurationSimple(cycles: Int) -> String {
        let duration = SleepCalculator.shared.getSleepDuration(for: cycles)
        return String(format: "%.1fh", duration)
    }
    
    // MARK: - Single Alarm Specific Functions
    private func selectSingleAlarm(time: Date, cycles: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            singleAlarmState = .selected(time: time, cycles: cycles, adjustmentMinutes: 0)
        }
    }
    
    private func adjustSelectedTime(by minutes: Int) {
        if case .selected(let time, let cycles, let currentAdjustment) = singleAlarmState {
            let newAdjustment = currentAdjustment + minutes
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                singleAlarmState = .selected(time: time, cycles: cycles, adjustmentMinutes: newAdjustment)
            }
        }
    }
    
    private func confirmAlarm() {
        if case .selected(let baseTime, let cycles, let adjustmentMinutes) = singleAlarmState {
            let adjustedTime = Calendar.current.date(byAdding: .minute, value: adjustmentMinutes, to: baseTime) ?? baseTime
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Schedule the actual alarm using AlarmKit and get the ID
            Task {
                let alarmID = await scheduleAlarmKitAlarm(time: adjustedTime, cycles: cycles)
                
                // Save alarm data with the ID
                let alarmData = SingleAlarmData(alarmTime: adjustedTime, startTime: Date(), cycles: cycles, alarmID: alarmID)
                saveAlarmData(alarmData)
                
                // Update state with the alarm ID
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        singleAlarmState = .active(alarmTime: adjustedTime, startTime: Date(), alarmID: alarmID)
                    }
                }
            }
        }
    }
    
    private func cancelAlarm() {
        let warningFeedback = UINotificationFeedbackGenerator()
        warningFeedback.notificationOccurred(.warning)
        
        // Delete the AlarmKit alarm if it exists
        if case .active(let alarmTime, _, let alarmID) = singleAlarmState {
            Task {
                await deleteExistingAlarmKitAlarm(alarmID: alarmID, time: alarmTime)
            }
        }
        
        clearSavedAlarmData()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            singleAlarmState = .none
        }
    }
    
    private func updateCountdown() {
        guard case .active(let alarmTime, let startTime, _) = singleAlarmState else { return }
        
        let now = Date()
        let timeRemaining = alarmTime.timeIntervalSince(now)
        let totalTime = alarmTime.timeIntervalSince(startTime)
        
        if timeRemaining <= 0 {
            countdownDisplay = "00:00:00"
            progressValue = 1.0
            // Handle alarm trigger
            return
        }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        countdownDisplay = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        progressValue = min(1.0, max(0.0, 1.0 - (timeRemaining / totalTime)))
    }
    
    // MARK: - AlarmKit Integration
    private func scheduleAlarmKitAlarm(time: Date, cycles: Int) async -> UUID? {
        // Check for duplicate alarms at the same time
        let existingAlarms = await MainActor.run { alarmViewModel.runningAlarms }
        let hasExistingAlarm = existingAlarms.contains { alarm in
            guard let schedule = alarm.alarm.schedule else { return false }
            
            switch schedule {
            case .fixed(let alarmDate):
                return Calendar.current.isDate(alarmDate, equalTo: time, toGranularity: .minute)
            case .relative(let relative):
                let wakeUpComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                guard let wakeUpHour = wakeUpComponents.hour, let wakeUpMinute = wakeUpComponents.minute else { return false }
                return relative.time.hour == wakeUpHour && relative.time.minute == wakeUpMinute
            @unknown default:
                return false
            }
        }
        
        // If alarm already exists, don't create another one
        if hasExistingAlarm {
            print("Alarm already exists at \(SleepCalculator.shared.formatTime(time))")
            return nil
        }
        
        // Generate alarm ID
        let alarmID = UUID()
        
        // Create alarm form
        var alarmForm = AlarmKitForm()
        alarmForm.selectedDate = time
        alarmForm.scheduleEnabled = true
        alarmForm.label = "Single Alarm - \(SleepCalculator.shared.formatTime(time))"
        
        // Set metadata based on cycles
        switch cycles {
        case 3:
            alarmForm.selectedWakeUpReason = .workout
            alarmForm.selectedSleepContext = .quickNap
        case 4:
            alarmForm.selectedWakeUpReason = .work
            alarmForm.selectedSleepContext = .shortSleep
        case 5, 6:
            alarmForm.selectedWakeUpReason = .general
            alarmForm.selectedSleepContext = .normalSleep
        default:
            alarmForm.selectedWakeUpReason = .general
        }
        
        // Schedule the alarm with specific ID
        let success = await alarmViewModel.scheduleAlarmWithID(alarmID, with: alarmForm)
        
        if success {
            print("Scheduled single alarm for \(SleepCalculator.shared.formatTime(time)) with ID: \(alarmID)")
            return alarmID
        } else {
            print("Failed to schedule single alarm for \(SleepCalculator.shared.formatTime(time))")
            return nil
        }
    }
    
    private func deleteExistingAlarmKitAlarm(alarmID: UUID?, time: Date) async {
        let existingAlarms = await MainActor.run { alarmViewModel.runningAlarms }
        
        // First try to find by alarm ID (most reliable)
        if let alarmID = alarmID {
            if let alarm = existingAlarms.first(where: { $0.id == alarmID }) {
                await alarmViewModel.deleteAlarm(alarm)
                print("Deleted single alarm by ID: \(alarmID)")
                return
            } else {
                print("Could not find alarm with ID: \(alarmID), falling back to time-based search")
            }
        }
        
        // Fall back to time-based matching for backward compatibility
        for alarm in existingAlarms {
            guard let schedule = alarm.alarm.schedule else { continue }
            
            var matchesTime = false
            switch schedule {
            case .fixed(let alarmDate):
                matchesTime = Calendar.current.isDate(alarmDate, equalTo: time, toGranularity: .minute)
            case .relative(let relative):
                let wakeUpComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                guard let wakeUpHour = wakeUpComponents.hour, let wakeUpMinute = wakeUpComponents.minute else { continue }
                matchesTime = relative.time.hour == wakeUpHour && relative.time.minute == wakeUpMinute
            @unknown default:
                continue
            }
            
            if matchesTime {
                await alarmViewModel.deleteAlarm(alarm)
                print("Deleted single alarm at \(SleepCalculator.shared.formatTime(time)) by time matching")
                break
            }
        }
    }
    
    // MARK: - Data Persistence
    private func saveAlarmData(_ alarmData: SingleAlarmData) {
        if let encoded = try? JSONEncoder().encode(alarmData) {
            UserDefaults.standard.set(encoded, forKey: SingleAlarmData.userDefaultsKey)
        }
    }
    
    private func loadSavedAlarmState() {
        guard let data = UserDefaults.standard.data(forKey: SingleAlarmData.userDefaultsKey),
              let alarmData = try? JSONDecoder().decode(SingleAlarmData.self, from: data) else {
            return
        }
        
        // Check if alarm time hasn't passed
        if alarmData.alarmTime > Date() {
            singleAlarmState = .active(alarmTime: alarmData.alarmTime, startTime: alarmData.startTime, alarmID: alarmData.alarmID)
        } else {
            clearSavedAlarmData()
        }
    }
    
    private func clearSavedAlarmData() {
        UserDefaults.standard.removeObject(forKey: SingleAlarmData.userDefaultsKey)
    }
    
    // MARK: - Single Alarm UI Views
    private func adjustmentControlsView(selectedTime: Date, cycles: Int, adjustmentMinutes: Int) -> some View {
        let adjustedTime = Calendar.current.date(byAdding: .minute, value: adjustmentMinutes, to: selectedTime) ?? selectedTime
        
        return VStack(spacing: 20) {
            // Selected time display
            VStack(spacing: 8) {
                Text("Selected Wake-up Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(SleepCalculator.shared.formatTime(adjustedTime))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(formatSleepDurationSimple(cycles: cycles)) • \(cycles) cycles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Adjustment buttons
            HStack(spacing: 15) {
                adjustmentButton(label: "+5m", minutes: 5)
                adjustmentButton(label: "+10m", minutes: 10)
                adjustmentButton(label: "+15m", minutes: 15)
            }
            
            // Confirm button
            Button(action: confirmAlarm) {
                Text("Set Alarm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
                    )
            }
            .buttonStyle(.plain)
            
            // Cancel button
            Button("Cancel") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    singleAlarmState = .none
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func fullScreenAdjustmentView(selectedTime: Date, cycles: Int, adjustmentMinutes: Int, geometry: GeometryProxy) -> some View {
        let adjustedTime = Calendar.current.date(byAdding: .minute, value: adjustmentMinutes, to: selectedTime) ?? selectedTime
        
        return VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                // App Title with animated moon - smaller version
                HStack(spacing: 10) {
                    Image(currentMoonIcon)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .accessibilityHidden(true)
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathingScale)
                    
                    Text("Mr Sleep")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                }
                .padding(.top, 20)
                
                // Selected time display - large and prominent
                VStack(spacing: 16) {
                    Text("Set alarm for")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(SleepCalculator.shared.formatTime(adjustedTime))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingScale)
                    
                    Text("\(formatSleepDurationSimple(cycles: cycles)) • \(cycles) sleep cycles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                        )
                }
                
                // Adjustment buttons - bigger and more prominent
                VStack(spacing: 20) {
                    Text("Fine-tune your wake time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 20) {
                        fullScreenAdjustmentButton(label: "+5 min", minutes: 5)
                        fullScreenAdjustmentButton(label: "+10 min", minutes: 10)
                        fullScreenAdjustmentButton(label: "+15 min", minutes: 15)
                    }
                }
                
                // Confirm button - large and prominent
                Button(action: confirmAlarm) {
                    HStack {
                        Image(systemName: "alarm.waves.left.and.right.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Set Alarm")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.894, green: 0.729, blue: 0.306),
                                        Color(red: 0.94, green: 0.629, blue: 0.206)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                
                // Cancel button
                Button("Cancel") {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        singleAlarmState = .none
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    private func fullScreenAdjustmentButton(label: String, minutes: Int) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            adjustSelectedTime(by: minutes)
        }) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private func adjustmentButton(label: String, minutes: Int) -> some View {
        Button(action: {
            adjustSelectedTime(by: minutes)
        }) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private func activeAlarmView(alarmTime: Date, startTime: Date, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                // Alarm time
                VStack(spacing: 12) {
                    Text("Alarm set for")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(SleepCalculator.shared.formatTime(alarmTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: breathingScale)
                }
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0.0, to: progressValue)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progressValue)
                    
                    VStack(spacing: 4) {
                        Text("Time left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(countdownDisplay)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // Cancel button
                Button("Cancel Alarm") {
                    cancelAlarm()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
}

// CalculatingWakeUpTimesView and FinishingUpView are defined in SleepNowView.swift

// OnboardingView is defined in SleepNowView.swift

// SleepGuideView is defined in the original SleepGuideView.swift file

#Preview {
    SingleAlarmView()
}

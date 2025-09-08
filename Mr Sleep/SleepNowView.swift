//
//  SleepNowView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct SleepNowView: View {
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
    @State private var showAlarmInstructions = false
    @State private var selectedWakeUpTime = ""
    @State private var currentMoonIcon: String = "moon-3D-icon"
    @State private var wakeUpTimeVisibility: [Bool] = [false, false, false, false, false, false]
    @State private var categoryHeadersVisible: Bool = false
    @State private var isCalculatingWakeUpTimes = false
    @State private var calculationProgress: Double = 0.0
    @State private var isFinishingUp = false
    @State private var hasCompletedInitialLoading = false
    
    // Timer to update time every second for real-time display
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient - Darker blue theme (immediate, no animation)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.25, blue: 0.5), // Darker blue
                        Color(red: 0.06, green: 0.15, blue: 0.35), // Much darker blue
                        Color(red: 0.03, green: 0.08, blue: 0.2) // Very dark blue
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all) // Ensure it covers the entire screen including safe areas
                
                if showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding, onComplete: startPostOnboardingLoading)
                } else if showSleepGuide {
                    SleepGuideView(showSleepGuide: $showSleepGuide)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 25) {
                            Spacer(minLength: 20)
                        
                        // App Title with animated moon and floating zzz
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
                        
                        // Current time display with micro animation
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
                                .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: timeAnimationTrigger)
                                .accessibilityHidden(true)
                                .frame(minWidth: 120) // Fixed width to prevent layout shifts
                        }
                        .frame(maxWidth: .infinity) // Center the VStack
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current time is \(getCurrentTime())")
                        .accessibilityAddTraits([.updatesFrequently, .playsSound])
                        .accessibilityValue(getCurrentTime())
                        .opacity(contentOpacity)
                        .offset(y: timeOffset)
                        
                        // Sleep message
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
                        
                        // Wake up times or loading animation
                        if isCalculatingWakeUpTimes {
                            CalculatingWakeUpTimesView(progress: calculationProgress)
                                .frame(maxWidth: .infinity) // Center the loading view
                                .padding(.horizontal, 20)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Calculating wake-up times")
                                .accessibilityValue("\(Int(calculationProgress * 100)) percent complete")
                                .accessibilityAddTraits(.updatesFrequently)
                        } else if isFinishingUp {
                            FinishingUpView()
                                .frame(maxWidth: .infinity) // Center the finishing up view
                                .padding(.horizontal, 20)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Finishing up calculation")
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            // Categorized wake up times
                            VStack(spacing: 20) {
                                ForEach(Array(categorizedWakeUpTimes.enumerated()), id: \.offset) { categoryIndex, categoryData in
                                    VStack(spacing: 12) {
                                        // Category header with icon and tagline
                                        HStack(alignment: .center, spacing: 12) {
                                            getCategoryIconImage(for: categoryData.category)
                                                .frame(width: 40, height: 40) // Fixed size for icon alignment
                                            
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
                                        
                                        // Times in this category
                                        ForEach(Array(categoryData.times.enumerated()), id: \.offset) { timeIndex, timeData in
                                            let overallIndex = getOverallIndex(categoryIndex: categoryIndex, timeIndex: timeIndex)
                                            WakeUpTimeButton(
                                                wakeUpTime: SleepCalculator.shared.formatTime(timeData.time),
                                                currentTime: "", // No longer used
                                                sleepDuration: formatSleepDurationSimple(cycles: timeData.cycles),
                                                isRecommended: false,
                                                cycles: timeData.cycles,
                                                pulseScale: 1.0,
                                                action: {
                                                    selectedWakeUpTime = SleepCalculator.shared.formatTime(timeData.time)
                                                    showAlarmInstructions = true
                                                }
                                            )
                                            .opacity(overallIndex < wakeUpTimeVisibility.count && wakeUpTimeVisibility[overallIndex] ? 1.0 : 0.0)
                                            .scaleEffect(overallIndex < wakeUpTimeVisibility.count && wakeUpTimeVisibility[overallIndex] ? 1.0 : 0.8)
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
                        .frame(maxWidth: .infinity) // Ensure full width centering
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathingScale)
                        .padding()
                    }
                }
                
                // Alarm Instructions Modal
                if showAlarmInstructions {
                    AlarmInstructionsModal(
                        wakeUpTime: selectedWakeUpTime,
                        showModal: $showAlarmInstructions
                    )
                }
            }
        }
        .onAppear {
            // Pre-calculate wake up times for instant display
            calculateWakeUpTimes()
            currentTime = Date()
            
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
        }
    }
    
    // MARK: - Helper Methods (same as original ContentView)
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
    
    private func getOverallIndex(categoryIndex: Int, timeIndex: Int) -> Int {
        var totalIndex = 0
        for i in 0..<categoryIndex {
            totalIndex += categorizedWakeUpTimes[i].times.count
        }
        return totalIndex + timeIndex
    }
    
    private func startEntranceAnimation() {
        // Fast entrance animation for quick app launch
        
        // Phase 1: Title appears quickly (0.1s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
            contentOpacity = 1.0
            titleOffset = 0
        }
        
        // Phase 2: Time display appears (0.3s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.3)) {
            timeOffset = 0
        }
        
        // Phase 3: Start calculating animation (0.6s delay)
        startCalculatingAnimation()
    }
    
    private func startPostOnboardingEntranceAnimation() {
        // Post-onboarding entrance animation with proper timing
        
        // Phase 1: Title appears quickly (0.1s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
            contentOpacity = 1.0
            titleOffset = 0
        }
        
        // Phase 2: Time display appears (0.3s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.3)) {
            timeOffset = 0
        }
        
        // Phase 3: Start calculating animation after 1s (as requested)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isCalculatingWakeUpTimes = true
            }
            
            // Animate progress from 0 to 1 over 1.5 seconds
            startProgressAnimation()
            
            // After calculation animation completes (3.8s total), show finishing up
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isCalculatingWakeUpTimes = false
                    isFinishingUp = true
                }
                
                // Show finishing up for 1 second, then complete with micro interaction
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    triggerCompletionMicroInteraction()
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        isFinishingUp = false
                    }
                    
                    // Small delay before wake-up times start appearing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startWakeUpTimesAnimation()
                    }
                }
            }
        }
    }
    
    private func startCalculatingAnimation() {
        // Start calculating state after text appears (1.1s delay - 0.5s extra for smoothness)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isCalculatingWakeUpTimes = true
            }
            
            // Animate progress from 0 to 1 over 1.5 seconds
            startProgressAnimation()
            
            // After calculation animation completes (3.8s total), show finishing up
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isCalculatingWakeUpTimes = false
                    isFinishingUp = true
                }
                
                // Show finishing up for 1 second, then complete with micro interaction
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Only trigger micro interaction if not in onboarding
                    if !showOnboarding {
                        triggerCompletionMicroInteraction()
                    }
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        isFinishingUp = false
                        hasCompletedInitialLoading = true // Mark initial loading as completed
                    }
                    
                    // Small delay before wake-up times start appearing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startWakeUpTimesAnimation()
                    }
                }
            }
        }
    }
    
    private func startProgressAnimation() {
        let animationDuration = 3.8
        let steps = 60 // 60 steps for smooth animation
        let stepDuration = animationDuration / Double(steps)
        
        for i in 0...steps {
            let delay = Double(i) * stepDuration
            let progress = Double(i) / Double(steps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: stepDuration)) {
                    calculationProgress = progress
                }
            }
        }
    }
    
    private func startWakeUpTimesAnimation() {
        // First show category headers
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            categoryHeadersVisible = true
        }
        
        // Then show wake-up times with staggered animation after headers appear
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    wakeUpTimeVisibility[i] = true
                }
            }
        }
    }
    
    private func triggerCompletionMicroInteraction() {
        // Haptic feedback - gentle success notification
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare() // Prepare for better performance
        impactFeedback.impactOccurred()
        
        // Relaxing completion sound - try different system sounds:
        AudioServicesPlaySystemSound(1057) // Gentle notification beep
    }
    
    private func startPostOnboardingLoading() {
        // IMMEDIATELY reset ALL states to prevent card flash
        wakeUpTimeVisibility = [false, false, false, false, false, false]
        categoryHeadersVisible = false
        calculationProgress = 0.0
        isCalculatingWakeUpTimes = false
        isFinishingUp = false
        
        // IMMEDIATELY reset entrance animation states to initial values
        contentOpacity = 0.0
        titleOffset = -50
        timeOffset = 30
        
        // Reset ZZZ animation states
        zzzFloatingOffsets = [0, 0, 0]
        zzzOpacities = [1.0, 0.8, 0.6]
        breathingScale = 1.0
        
        // Select next moon icon for post-onboarding
        selectNextMoonIcon()
        
        // Start post-onboarding entrance sequence with proper timing
        startPostOnboardingEntranceAnimation()
        startBreathingEffect()
        startZzzAnimation()
    }
    
    private func startBreathingEffect() {
        // Start breathing effect quickly after entrance animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.02
            }
        }
    }
    
    private func startZzzAnimation() {
        // Simplified floating ZZZ animation for better device performance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                zzzFloatingOffsets[0] = -8.0
                zzzFloatingOffsets[1] = -10.0
                zzzFloatingOffsets[2] = -12.0
            }
            
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3)) {
                zzzOpacities[0] = 0.6
                zzzOpacities[1] = 0.4
                zzzOpacities[2] = 0.2
            }
        }
    }
    
    private func formatSleepDurationSimple(cycles: Int) -> String {
        let hours = Double(cycles) * 1.5
        return "\(hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours))h"
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
}

#Preview {
    SleepNowView()
}

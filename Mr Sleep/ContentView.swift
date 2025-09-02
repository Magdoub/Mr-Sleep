import SwiftUI
import AVFoundation
import AudioToolbox

struct ContentView: View {
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
    @State private var wakeUpTimeVisibility: [Bool] = [false, false, false, false, false, false]
    @State private var categoryHeadersVisible: Bool = false
    @State private var isCalculatingWakeUpTimes = false
    @State private var calculationProgress: Double = 0.0
    @State private var isFinishingUp = false
    
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
                                Image("moon-icon")
                                    .resizable()
                                    .frame(width: 72, height: 72)
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
                                    .offset(x: [-5, -8, -10][index], y: [-5 + zzzFloatingOffsets[index], -8 + zzzFloatingOffsets[index], -12 + zzzFloatingOffsets[index]][index])
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
                            Text("Wake Up Like A Boss")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            
                            VStack(spacing: 4) {
                                Text("Sleep now and wake up at these times.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                                    .multilineTextAlignment(.center)
                                
                                Text("You will feel refreshed and not tired")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal)
                            
                            Text("Here are your optimal wake-up times")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                .opacity(0.9)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Wake Up Like A Boss. Sleep now and wake up at these times. You will feel refreshed and not tired. Here are your optimal wake-up times.")
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
                                        // Category header with icon
                                        HStack(spacing: 8) {
                                            Image(systemName: SleepCalculator.shared.getCategoryIcon(categoryData.category))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                            
                                            Text(categoryData.category)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                            
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
                                                time: SleepCalculator.shared.formatTime(timeData.time),
                                                duration: formatSleepDuration(cycles: timeData.cycles),
                                                isRecommended: false, // Remove recommended highlighting
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
            
            
            startEntranceAnimation()
            startBreathingEffect()
            startZzzAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateTimeAndCalculations()
            triggerTimeAnimation()
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
    
    private func getOverallIndex(categoryIndex: Int, timeIndex: Int) -> Int {
        var totalIndex = 0
        for i in 0..<categoryIndex {
            totalIndex += categorizedWakeUpTimes[i].times.count
        }
        return totalIndex + timeIndex
    }
    
    private func createAlarm(for wakeUpTime: Date) {
        // No action - just display the times
        return
    }
    
    private func openClockAppFallback() {
        guard let clockURL = URL(string: "clock://") else {
            print("Failed to create fallback clock URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(clockURL) {
            UIApplication.shared.open(clockURL) { success in
                if !success {
                    print("Failed to open Clock app")
                }
            }
        } else {
            print("Cannot open Clock app")
        }
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
        impactFeedback.impactOccurred()
        
        // Relaxing completion sound using system sounds
        AudioServicesPlaySystemSound(1057) // Gentle notification sound
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
        
        // Start the complete entrance sequence immediately (no delay)
        startEntranceAnimation()
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
    
    private func formatSleepDuration(cycles: Int) -> String {
        let hours = Double(cycles) * 1.5
        let cycleText = cycles == 1 ? "cycle" : "cycles"
        let hoursText = hours == 1.0 ? "hour of sleep" : "hours of sleep"
        
        return "\(hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)) \(hoursText) • \(cycles) \(cycleText)"
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
}

struct SleepGuideView: View {
    @Binding var showSleepGuide: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: {
                        showSleepGuide = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                    }
                    .accessibilityLabel("Close sleep guide")
                    .accessibilityHint("Double tap to return to main screen")
                    .accessibilityAddTraits(.isButton)
                    
                    Spacer()
                    
                    Text("Sleep Cycle Guide")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .opacity(0)
                }
                .padding(.horizontal)
                .padding(.top, 80) // Top padding for Dynamic Island
                
                VStack(spacing: 30) {
                    // What are sleep cycles?
                    sleepSectionView(
                        icon: "moon.zzz.fill",
                        title: "What are Sleep Cycles?",
                        content: "Your sleep happens in cycles of about 90 minutes each. During each cycle, you move through different stages from light sleep to deep sleep and back to light sleep."
                    )
                    
                    // Why timing matters
                    sleepSectionView(
                        icon: "clock.fill",
                        title: "Why Timing Matters",
                        content: "Waking up during deep sleep makes you feel groggy and tired. But waking up during light sleep at the end of a cycle helps you feel refreshed and alert."
                    )
                    
                    // How to use alarms
                    sleepSectionView(
                        icon: "alarm.fill",
                        title: "Set Your Alarm Right",
                        content: "Instead of sleeping for exactly 8 hours, aim for complete cycles: 6 hours (4 cycles), 7.5 hours (5 cycles), or 9 hours (6 cycles). Your body will thank you!"
                    )
                    
                    // Sleep tips
                    sleepSectionView(
                        icon: "heart.fill",
                        title: "Better Sleep Tips",
                        content: "• Keep a consistent bedtime\n• Avoid screens 1 hour before bed\n• Keep your room cool and dark\n• Don't drink caffeine after 2 PM\n• Try relaxation techniques"
                    )
                    
                    // The 15-minute rule
                    sleepSectionView(
                        icon: "timer",
                        title: "The 15-Minute Rule",
                        content: "Most people take about 15 minutes to fall asleep. That's why Mr Sleep adds this time to your calculations automatically."
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 30)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.25, blue: 0.5),
                    Color(red: 0.06, green: 0.15, blue: 0.35),
                    Color(red: 0.03, green: 0.08, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .ignoresSafeArea()
    }
    
    private func sleepSectionView(icon: String, title: String, content: String) -> some View {
        VStack(spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                    .frame(width: 30)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(content)")
    }
}

struct WakeUpTimeButton: View {
    let time: String
    let duration: String
    let isRecommended: Bool
    let cycles: Int
    let pulseScale: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(time)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                    
                    Text(duration)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                }
                
                Spacer()
                
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Wake up at \(time), \(duration)")
        .accessibilityHint("Double tap to get instructions for setting an alarm")
        .accessibilityAddTraits([.isButton])
        .accessibility(value: Text("\(cycles) sleep cycles"))
    }
}

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    let onComplete: () -> Void
    @State private var currentStep = 0
    
    let onboardingSteps = [
        OnboardingStep(
            icon: "moon.zzz.fill",
            title: "Welcome to Mr Sleep",
            subtitle: "Your sleep companion",
            description: "Sleep happens in 90-minute cycles. Waking up at the end of a cycle helps you feel refreshed.",
            buttonText: "Tell me more"
        ),
        OnboardingStep(
            icon: "clock.fill",
            title: "Wake Up Smarter",
            subtitle: "Science-based wake times",
            description: "We calculate the best times for you to wake up based on when you plan to sleep.",
            buttonText: "How does it work?"
        ),
        OnboardingStep(
            icon: "alarm.fill",
            title: "Set & Sleep",
            subtitle: "Your path to ZERO brain fog",
            description: "Choose a wake-up time, set your alarm, and try to fall asleep in the next 15 minutes.",
            buttonText: "Let's sleep better!"
        )
    ]
    
    var body: some View {
        ZStack {
            // Same background as main app
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
            
            VStack(spacing: 0) {
                // Fixed content area
                VStack(spacing: 30) {
                    // Icon
                    Image(systemName: currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].icon : "moon.zzz.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentStep)
                        .accessibilityHidden(true)
                    
                    // Title and subtitle
                    VStack(spacing: 8) {
                        Text(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].title : "Loading...")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].subtitle : "")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Description with fixed frame
                    Text(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].description : "")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 120, alignment: .top) // Fixed minimum height
                }
                .frame(maxHeight: .infinity) // Take available space
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].title : "Loading"). \(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].subtitle : ""). \(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].description : "")")
                .accessibilityHint("Swipe left or right to navigate between steps")
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold && currentStep > 0 {
                                // Swipe right - go to previous step
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentStep -= 1
                                }
                            } else if value.translation.width < -threshold && currentStep < onboardingSteps.count - 1 {
                                // Swipe left - go to next step
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentStep += 1
                                }
                            }
                        }
                )
                
                // Bottom section with consistent positioning
                VStack(spacing: 25) {
                        // Step indicators
                        HStack(spacing: 12) {
                            ForEach(0..<onboardingSteps.count, id: \.self) { index in
                                Circle()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(
                                        index == currentStep ?
                                        Color(red: 1.0, green: 0.85, blue: 0.3) :
                                        Color.white.opacity(0.3)
                                    )
                                    .scaleEffect(index == currentStep ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
                            }
                        }
                        
                        // Action button
                        Button(action: {
                            if currentStep < onboardingSteps.count - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentStep += 1
                                }
                            } else {
                                // Completed onboarding - reset states BEFORE dismissal animation
                                onComplete()
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showOnboarding = false
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentStep >= 0 && currentStep < onboardingSteps.count ? 
                                     onboardingSteps[currentStep].buttonText : "Continue")
                                if currentStep < onboardingSteps.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color(red: 1.0, green: 0.85, blue: 0.3))
                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                            )
                        }
                        .accessibilityLabel(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].buttonText : "Continue")
                        .accessibilityHint(currentStep < onboardingSteps.count - 1 ? "Double tap to continue to next step" : "Double tap to complete onboarding and start using the app")
                        .accessibilityAddTraits(.isButton)
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
        }
    }
}

struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let buttonText: String
}

struct CalculatingWakeUpTimesView: View {
    let progress: Double
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    @State private var dotAnimation: [Double] = [0.3, 0.6, 1.0]
    
    var body: some View {
        VStack(spacing: 20) {
            // Main loading indicator with multiple animations
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: rotationAngle)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color(red: 1.0, green: 0.85, blue: 0.3),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Center pulsing dot
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
                    .opacity(0.8)
            }
            .scaleEffect(1.1)
            
            // Text with animated dots
            HStack(spacing: 2) {
                Text("Calculating wake-up times")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Text(".")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                            .opacity(dotAnimation[index])
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: dotAnimation[index]
                            )
                    }
                }
            }
            
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                .opacity(0.8)
                .accessibilityHidden(true)
        }
        .frame(height: 140)
        .onAppear {
            // Start animations
            rotationAngle = 360
            pulseScale = 1.3
            
            // Animate dots continuously
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.2)) {
                        dotAnimation[i] = 0.3
                    }
                }
            }
        }
    }
}

struct FinishingUpView: View {
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Simple pulsing checkmark or completion icon
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
            }
            
            // Finishing up text
            Text("Finishing up...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
        }
        .frame(height: 140)
        .onAppear {
            pulseScale = 1.2
        }
    }
}

struct AlarmInstructionsModal: View {
    let wakeUpTime: String
    @Binding var showModal: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showModal = false
                    }
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("⏰")
                        .font(.system(size: 48))
                        .accessibilityLabel("Alarm clock")
                    
                    Text("Set Your Alarm")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Wake up at \(wakeUpTime)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Set Your Alarm. Wake up at \(wakeUpTime)")
                .accessibilityAddTraits(.isHeader)
                
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("1.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Open the Clock app on your iPhone")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("2.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Tap the '+' button to add a new alarm")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("3.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Set the time to \(wakeUpTime) and save")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                    }
                }
                .padding(.horizontal, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Instructions for setting alarm. Step 1: Open the Clock app on your iPhone. Step 2: Tap the plus button to add a new alarm. Step 3: Set the time to \(wakeUpTime) and save.")
                
                // Sleep tip
                VStack(spacing: 8) {
                    Text("💤 Sleep Tip")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                    
                    Text("Try to fall asleep within the next 15 minutes for the best results!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                )
                
                // Close button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showModal = false
                    }
                }) {
                    Text("Got it!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 1.0, green: 0.85, blue: 0.3))
                        )
                }
                .accessibilityLabel("Got it")
                .accessibilityHint("Double tap to close this dialog and return to main screen")
                .accessibilityAddTraits(.isButton)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.12, green: 0.27, blue: 0.52),
                                Color(red: 0.08, green: 0.17, blue: 0.37)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .scaleEffect(showModal ? 1.0 : 0.8)
            .opacity(showModal ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showModal)
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    @State private var wakeUpTimes: [Date] = []
    @State private var moreWakeUpTimes: [Date] = []
    @State private var showMoreOptions = false
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
                    OnboardingView(showOnboarding: $showOnboarding)
                } else if showSleepGuide {
                    SleepGuideView(showSleepGuide: $showSleepGuide)
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                        Spacer()
                        
                        // App Title with animated moon and floating zzz
                        HStack(spacing: 15) {
                            HStack(spacing: 12) {
                                Image("moon-icon")
                                    .resizable()
                                    .frame(width: 72, height: 72)
                                    .accessibilityLabel("Moon icon")
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
                                    .animation(.easeInOut(duration: 2.5 + Double(index) * 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.5), value: zzzFloatingOffsets[index])
                                    .animation(.easeInOut(duration: 2.0 + Double(index) * 0.2).repeatForever(autoreverses: true).delay(Double(index) * 0.3), value: zzzOpacities[index])
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Mr Sleep app title with sleeping Z Z Z")
                        .opacity(contentOpacity)
                        .offset(y: titleOffset)
                        
                        Spacer()
                        
                        // Current time display with micro animation
                        VStack(spacing: 8) {
                            Text("Current Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                            
                            Text(getCurrentTime())
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                                .scaleEffect(timeAnimationTrigger ? 1.1 : 1.0)
                                .opacity(timeAnimationTrigger ? 0.7 : 1.0)
                                .offset(y: timeAnimationTrigger ? -2 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: timeAnimationTrigger)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current time is \(getCurrentTime())")
                        .accessibilityAddTraits(.updatesFrequently)
                        .opacity(contentOpacity)
                        .offset(y: timeOffset)
                        
                        // Sleep message
                        VStack(spacing: 12) {
                            Text("Wake Up Like A Boss")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                                .multilineTextAlignment(.center)
                            
                            Text("Sleep now and wake up at the end of a complete sleep cycle to avoid feeling tired.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("Pick a wake-up time. Set your Alarm")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                .opacity(0.9)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Wake Up Like A Boss. Sleep now and wake up at the end of a complete sleep cycle to avoid feeling tired. Pick a wake-up time and set your alarm.")
                        .accessibilityAddTraits(.isHeader)
                        .opacity(contentOpacity)
                        
                        // Wake up times grid - 2x2 layout for 4 options (recommended on top)
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(Array(wakeUpTimes.prefix(4).enumerated()), id: \.offset) { index, time in
                                let cycles = [4, 5, 3, 6][index] // Match SleepCalculator cycles order
                                WakeUpTimeButton(
                                    time: SleepCalculator.shared.formatTime(time),
                                    duration: formatSleepDuration(cycles: cycles),
                                    isRecommended: index < 2 && index >= 0, // First two are recommended (top row)
                                    pulseScale: 1.0,
                                    action: {}
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Wake-up time options")
                        
                        // More options toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMoreOptions.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text("More options")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: showMoreOptions ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                        }
                        .accessibilityLabel(showMoreOptions ? "Hide more wake-up time options" : "Show more wake-up time options")
                        .accessibilityHint("Double tap to \(showMoreOptions ? "hide" : "show") additional wake-up time options")
                        .padding(.top, 10)
                        
                        // Additional wake up times (collapsible)
                        if showMoreOptions {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                ForEach(Array(moreWakeUpTimes.prefix(4).enumerated()), id: \.offset) { index, time in
                                    let cycles = [1, 2, 7, 8][index] // Match SleepCalculator additional cycles order
                                    WakeUpTimeButton(
                                        time: SleepCalculator.shared.formatTime(time),
                                        duration: formatSleepDuration(cycles: cycles),
                                        isRecommended: false,
                                        pulseScale: 1.0,
                                        action: {}
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
                                        removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -20))
                                    ))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: showMoreOptions)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 15)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Additional wake-up time options")
                        }
                        
                        Spacer()
                        
                        
                        Spacer()
                        }
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
        wakeUpTimes = SleepCalculator.shared.calculateWakeUpTimes()
        moreWakeUpTimes = SleepCalculator.shared.calculateMoreWakeUpTimes()
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
        
        // Buttons appear immediately - no animation needed
        
        // Animation complete - no ZZZ animation needed
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
        // Floating ZZZ animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            for i in 0..<3 {
                withAnimation(.easeInOut(duration: 2.5 + Double(i) * 0.3).repeatForever(autoreverses: true).delay(Double(i) * 0.5)) {
                    zzzFloatingOffsets[i] = -8.0 - Double(i) * 2
                }
                withAnimation(.easeInOut(duration: 2.0 + Double(i) * 0.2).repeatForever(autoreverses: true).delay(Double(i) * 0.3)) {
                    zzzOpacities[i] = [0.6, 0.4, 0.2][i]
                }
            }
        }
    }
    
    private func formatSleepDuration(cycles: Int) -> String {
        let hours = Double(cycles) * 1.5
        let cycleText = cycles == 1 ? "cycle" : "cycles"
        
        if hours == floor(hours) {
            return "\(Int(hours)) hours • \(cycles) \(cycleText)"
        } else {
            let wholeHours = Int(hours)
            let minutes = Int((hours - Double(wholeHours)) * 60)
            if wholeHours == 0 {
                return "\(minutes) mins • \(cycles) \(cycleText)"
            } else {
                return "\(wholeHours)h \(minutes)m • \(cycles) \(cycleText)"
            }
        }
    }
    
    private func getCurrentTime() -> String {
        guard !currentTime.timeIntervalSince1970.isNaN && !currentTime.timeIntervalSince1970.isInfinite else {
            print("Invalid current time, using fallback")
            return "12:00 AM"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Prevent crashes from locale issues
        
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
                    
                    Spacer()
                    
                    Text("Sleep Cycle Guide")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                    
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
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                
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
    }
}

struct WakeUpTimeButton: View {
    let time: String
    let duration: String
    let isRecommended: Bool
    let pulseScale: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(time)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                
                Text(duration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                
                if isRecommended {
                    Text("RECOMMENDED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(isRecommended ? 0.25 : 0.15),
                                Color.white.opacity(isRecommended ? 0.15 : 0.08)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isRecommended ?
                                Color(red: 1.0, green: 0.85, blue: 0.3) :
                                Color.white.opacity(0.3),
                                lineWidth: isRecommended ? 2 : 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: isRecommended ? 6 : 3,
                        x: 0,
                        y: isRecommended ? 3 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(false)
        .accessibilityLabel("Wake up at \(time), \(duration)\(isRecommended ? ", recommended option" : "")")
        .accessibilityHint("Wake-up time option for setting your alarm")
        .accessibilityAddTraits(isRecommended ? [.isButton, .isSelected] : [.isButton])
    }
}

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentStep = 0
    
    let onboardingSteps = [
        OnboardingStep(
            icon: "moon.zzz.fill",
            title: "Welcome to Mr Sleep",
            subtitle: "Your sleep cycle companion",
            description: "Sleep happens in 90-minute cycles. Waking up at the end of a cycle (instead of in the middle) helps you feel more refreshed and alert.",
            buttonText: "Tell me more"
        ),
        OnboardingStep(
            icon: "clock.fill",
            title: "Perfect Timing",
            subtitle: "Science-backed wake times",
            description: "We calculate the best times for you to wake up based on when you plan to sleep. Each suggestion aligns with your natural sleep cycles.",
            buttonText: "How does it work?"
        ),
        OnboardingStep(
            icon: "alarm.fill",
            title: "Set & Sleep",
            subtitle: "Your path to better mornings",
            description: "Choose a wake-up time, set your alarm, and try to fall asleep in the next 15 minutes. Wake up refreshed instead of groggy!",
            buttonText: "Let's sleep better!"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
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
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Step content with bounds checking
                    if currentStep >= 0 && currentStep < onboardingSteps.count {
                        VStack(spacing: 30) {
                            // Icon
                            Image(systemName: onboardingSteps[currentStep].icon)
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentStep)
                            
                            // Title and subtitle
                            VStack(spacing: 8) {
                                Text(onboardingSteps[currentStep].title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                                    .multilineTextAlignment(.center)
                                
                                Text(onboardingSteps[currentStep].subtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Description
                            Text(onboardingSteps[currentStep].description)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(.horizontal, 20)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        // Fallback content for invalid step
                        VStack {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                            Text("Loading...")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom section
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
                                // Completed onboarding
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
                        
                        // Skip option (only on first two steps)
                        if currentStep < onboardingSteps.count - 1 {
                            Button(action: {
                                // Skip onboarding
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showOnboarding = false
                                }
                            }) {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
                .padding(.horizontal, 30)
            }
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

#Preview {
    ContentView()
}

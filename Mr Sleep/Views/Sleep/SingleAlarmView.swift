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
    let completedTime: Date? // Track when alarm was completed
    
    static let userDefaultsKey = "SingleAlarmData"
    
    // Initializer for backward compatibility
    init(alarmTime: Date, startTime: Date, cycles: Int, alarmID: UUID? = nil, completedTime: Date? = nil) {
        self.alarmTime = alarmTime
        self.startTime = startTime
        self.cycles = cycles
        self.alarmID = alarmID
        self.completedTime = completedTime
    }
    
    
    // Mark alarm as completed/fired
    func markCompleted() -> SingleAlarmData {
        return SingleAlarmData(
            alarmTime: alarmTime,
            startTime: startTime,
            cycles: cycles,
            alarmID: alarmID,
            completedTime: Date()
        )
    }
}

// MARK: - Alarm Selection State
enum SingleAlarmState: Equatable {
    case none
    case selected(time: Date, cycles: Int, adjustmentMinutes: Int)
    case settingUpAlarm(time: Date, cycles: Int) // New loading state
    case active(alarmTime: Date, startTime: Date, alarmID: UUID?)
}

// MARK: - Alarm Setup Loading Phases
enum AlarmSetupPhase {
    case loading
    case success
}

// MARK: - Supporting Views (Moved from SleepNowView)

struct CalculatingWakeUpTimesView: View {
    let progress: Double
    let reduceMotion: Bool
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
                            colors: [Color(red: 0.894, green: 0.729, blue: 0.306), Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(reduceMotion ? .none : .linear(duration: 2.0).repeatForever(autoreverses: false), value: rotationAngle)
                    .accessibilityHidden(true)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color(red: 0.894, green: 0.729, blue: 0.306),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: progress)
                    .accessibilityHidden(true)

                // Center pulsing dot
                Circle()
                    .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
                    .frame(width: 12, height: 12)
                    .scaleEffect(reduceMotion ? 1.0 : pulseScale)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
                    .opacity(0.8)
                    .accessibilityHidden(true)
            }
            .scaleEffect(1.1)
            
            // Text with animated dots
            HStack(spacing: 2) {
                Text("Calculating wake-up times")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white) // Better contrast

                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Text(".")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                            .opacity(reduceMotion ? 1.0 : dotAnimation[index])
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: dotAnimation[index]
                            )
                    }
                }
            }
            
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                .opacity(0.8)
                .accessibilityHidden(true)
        }
        .frame(height: 140)
        .onAppear {
            if !reduceMotion {
                // Start animations only if motion is not reduced
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
}

struct FinishingUpView: View {
    let reduceMotion: Bool
    @State private var pulseScale: Double = 1.0

    var body: some View {
        VStack(spacing: 20) {
            // Simple pulsing checkmark or completion icon - match CalculatingWakeUpTimesView positioning
            ZStack {
                Circle()
                    .fill(Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(reduceMotion ? 1.0 : pulseScale)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                    .accessibilityHidden(true)

                Image(systemName: "checkmark")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                    .accessibilityHidden(true)
            }
            .scaleEffect(1.1) // Match the CalculatingWakeUpTimesView scale

            // Finishing up text
            Text("Finishing up...")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white) // Better contrast

            // Progress percentage placeholder (invisible to match layout)
            Text("100%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                .opacity(0) // Invisible but maintains layout spacing
        }
        .frame(height: 140)
        .onAppear {
            if !reduceMotion {
                pulseScale = 1.2
            }
        }
    }
}

struct AlarmSetupLoadingView: View {
    let phase: AlarmSetupPhase
    let reduceMotion: Bool

    @State private var bellSwingAngle: Double = 0
    @State private var bellScalePulse: Double = 1.0
    @State private var bellBounceScale: Double = 1.0
    @State private var bellExitScale: Double = 1.0
    @State private var bellExitOpacity: Double = 1.0
    @State private var ringRotation: Double = 0
    @State private var ringPulseScale: Double = 1.0
    @State private var dotAnimation: [Double] = [0.3, 0.6, 1.0]
    @State private var burstOpacity: Double = 0
    @State private var burstScale: Double = 0.5
    @State private var rayRotation: Double = 0
    @State private var sparkleOpacity: [Double] = Array(repeating: 0, count: 8)
    @State private var sparkleOffsets: [CGFloat] = Array(repeating: 0, count: 8)
    @State private var thumbsUpScale: Double = 0.5
    @State private var thumbsUpOpacity: Double = 0
    @State private var thumbsUpRotation: Double = 5
    @State private var thumbsUpOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 30) {
                // Icon with phase-specific animation
                ZStack {
                    if phase == .loading {
                        // Rotating ring during loading with pulse
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.894, green: 0.729, blue: 0.306),
                                        Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(ringPulseScale)
                            .rotationEffect(.degrees(ringRotation))
                            .animation(reduceMotion ? .none : .timingCurve(0.4, 0.0, 0.2, 1.0, duration: 2.0).repeatForever(autoreverses: false), value: ringRotation)

                        // Subtle sparkles around ring with drift
                        ForEach(0..<8, id: \.self) { index in
                            Circle()
                                .fill(Color(red: 1.0, green: 0.85, blue: 0.4))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 55,
                                    y: sin(Double(index) * .pi / 4) * 55 + sparkleOffsets[index]
                                )
                                .opacity(sparkleOpacity[index])
                        }
                    }

                    // Success glow effect (no rays)
                    if phase == .success {
                        // Subtle golden glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.15),
                                        Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .opacity(burstOpacity * 0.7)
                    }

                    // Alarm bell icon (loading phase)
                    if phase == .loading {
                        Image("alarm-bell-3D-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .scaleEffect(bellBounceScale * bellScalePulse)
                            .rotationEffect(.degrees(bellSwingAngle))
                    }

                    // Bell exit during transition to success
                    if phase == .success {
                        Image("alarm-bell-3D-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .scaleEffect(bellBounceScale * bellScalePulse * bellExitScale)
                            .rotationEffect(.degrees(bellSwingAngle))
                            .opacity(bellExitOpacity)
                    }

                    // Thumbs-up icon (success phase)
                    if phase == .success {
                        Image("thumbs-up-3D-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .scaleEffect(thumbsUpScale)
                            .rotationEffect(.degrees(thumbsUpRotation))
                            .opacity(thumbsUpOpacity)
                            .offset(y: thumbsUpOffset)
                    }
                }
                .frame(height: 140)

                // Text with phase-specific message
                VStack(spacing: 12) {
                    if phase == .loading {
                        HStack(spacing: 2) {
                            Text("Setting up your alarm")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            HStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { index in
                                    Text(".")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                                        .opacity(reduceMotion ? 1.0 : dotAnimation[index])
                                        .animation(
                                            reduceMotion ? .none : .easeInOut(duration: 0.6)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                            value: dotAnimation[index]
                                        )
                                }
                            }
                        }

                        Text("Please wait a moment")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("Alarm set!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))

                        Text("Get ready to wake up refreshed")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if phase == .loading {
                startLoadingAnimation()
            } else {
                startSuccessAnimation()
            }
        }
        .onChange(of: phase) { oldPhase, newPhase in
            if newPhase == .success {
                startSuccessAnimation()
            }
        }
    }

    private func startLoadingAnimation() {
        if !reduceMotion {
            // Slower, gentler bell swing with scale pulse
            withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.2).repeatForever(autoreverses: true)) {
                bellSwingAngle = 8
            }

            // Bell scale pulse synchronized with swing
            withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.2).repeatForever(autoreverses: true)) {
                bellScalePulse = 1.03
            }

            // Ring rotation with cubic easing
            ringRotation = 360

            // Ring pulse
            withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 2.0).repeatForever(autoreverses: true)) {
                ringPulseScale = 1.02
            }

            // Sparkles - staggered fade in with drift
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.2).repeatForever(autoreverses: true)) {
                        sparkleOpacity[i] = 0.8
                    }

                    // Gentle vertical drift
                    withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.5 + Double(i) * 0.1).repeatForever(autoreverses: true)) {
                        sparkleOffsets[i] = CGFloat.random(in: -3...3)
                    }
                }
            }

            // Animate dots
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.2)) {
                        dotAnimation[i] = 0.3
                    }
                }
            }
        }
    }

    private func startSuccessAnimation() {
        // Haptic feedback - medium at start
        let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
        mediumFeedback.impactOccurred()

        if !reduceMotion {
            // Stage 1: Bell exit animation (0-0.2s)
            bellSwingAngle = 0
            bellScalePulse = 1.0
            withAnimation(.timingCurve(0.4, 0.0, 0.6, 1.0, duration: 0.2)) {
                bellExitScale = 0.5
                bellExitOpacity = 0
                bellSwingAngle = -10 // Slight rotation during exit
            }

            // Start burst effects early
            withAnimation(.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.6)) {
                burstOpacity = 1.0
                burstScale = 1.3
            }
            withAnimation(.linear(duration: 1.2)) {
                rayRotation = 20
            }

            // Stage 2: Thumbs-up entrance animation (0.2-0.5s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Success haptic when thumbs-up appears
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)

                // Entrance with scale, rotation, and upward slide
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    thumbsUpScale = 1.3
                    thumbsUpOpacity = 1.0
                    thumbsUpRotation = 0
                    thumbsUpOffset = 0
                }
            }

            // Stage 3: Thumbs-up settle with bounce (0.5-0.8s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    thumbsUpScale = 0.95
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    thumbsUpScale = 1.0
                }
            }

            // Fade out burst
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.3)) {
                    burstOpacity = 0
                }
            }
        } else {
            // Reduced motion: instant transition
            bellExitOpacity = 0
            thumbsUpScale = 1.0
            thumbsUpOpacity = 1.0
            thumbsUpRotation = 0
            thumbsUpOffset = 0
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

// MARK: - Main Single Alarm View
struct SingleAlarmView: View {
    @EnvironmentObject private var viewModelContainer: LazyAlarmKitContainer
    @Environment(\.scenePhase) private var scenePhase

    // Computed property for easy access
    private var alarmViewModel: AlarmKitViewModel? {
        viewModelContainer.viewModel
    }

    // Accessibility Environment Variables
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    // Single alarm state
    @State private var singleAlarmState: SingleAlarmState = .none
    @State private var showAdjustmentControls = false
    @State private var confirmationProgress: CGFloat = 0
    @State private var isDragging = false
    @State private var countdownDisplay = ""
    @State private var progressValue: Double = 0.0
    @State private var alarmSetupPhase: AlarmSetupPhase = .loading

    @State private var shouldReloadView = false
    @State private var isComingFromBackground = false
    
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
    @State private var showAlarmPermissionSheet = false
    @State private var pendingAlarmTime: Date?
    @State private var pendingAlarmCycles: Int?
    @State private var selectedAdjustment: Int = 0
    
    // Timer to update time every second for real-time display
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let countdownTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
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
                if case .settingUpAlarm = singleAlarmState {
                    // Show loading state during alarm setup
                    AlarmSetupLoadingView(phase: alarmSetupPhase, reduceMotion: reduceMotion)
                        .transition(.opacity)
                } else if case .active(let alarmTime, let startTime, _) = singleAlarmState {
                    activeAlarmView(alarmTime: alarmTime, startTime: startTime, geometry: geometry)
                } else if case .selected(let selectedTime, let cycles, _) = singleAlarmState {
                    fullScreenAdjustmentView(selectedTime: selectedTime, cycles: cycles, geometry: geometry)
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
                                    .font(.largeTitle)
                                    .fontWeight(.medium)
                                    .fontDesign(.rounded)
                                    .foregroundColor(.white) // Better contrast
                            }
                            ForEach(0..<3) { index in
                                Text("z")
                                    .font([.title, .title2, .title3][index])
                                    .fontWeight(.light)
                                    .foregroundColor(.white.opacity([0.9, 0.8, 0.7][index])) // Simplified and better contrast
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

                        // Test alarm button (only show when not in active state)
                        // COMMENTED OUT - Only used for testing, not needed in production
                        /*
                        if case .none = singleAlarmState {
                            Button(action: scheduleTestAlarm) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.badge.checkmark.fill")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .accessibilityHidden(true)
                                    Text("Test Alarm (1 min)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3), lineWidth: 1)
                                        )
                                        .accessibilityHidden(true)
                                )
                            }
                            .buttonStyle(.plain)
                            .opacity(contentOpacity)
                            .accessibilityLabel("Test alarm in 1 minute")
                            .accessibilityHint("Double tap to schedule a test alarm for one minute from now")
                            .accessibilityAddTraits(.isButton)
                        }
                        */

                        // Current time display with micro animation - EXACT COPY
                        VStack(spacing: 8) {
                            Text("Current Time")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9)) // Improved contrast
                                .accessibilityHidden(true)
                            
                            Text(getCurrentTime())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundColor(.white) // Better contrast
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
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white) // Better contrast
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)

                            Text("You will feel refreshed and not tired")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9)) // Improved contrast
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Text("Set your alarm for a wake up time")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                                .multilineTextAlignment(.center)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Sleep Now . Wake up like boss. You will feel refreshed and not tired. Set your alarm for a wake up time that suits you.")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHint("Scroll down to see wake-up time options")
                        .opacity(contentOpacity)
                        
                        
                        // Wake up times or loading animation - EXACT COPY
                        if isCalculatingWakeUpTimes {
                            CalculatingWakeUpTimesView(progress: calculationProgress, reduceMotion: reduceMotion)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Calculating wake-up times")
                                .accessibilityValue("\(Int(calculationProgress * 100)) percent complete")
                                .accessibilityAddTraits(.updatesFrequently)
                        } else if isFinishingUp {
                            FinishingUpView(reduceMotion: reduceMotion)
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
                                                .accessibilityHidden(true)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(categoryData.category). \(getCategoryTagline(categoryData.category))")
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
                        .scaleEffect(reduceMotion ? 1.0 : breathingScale)
                        .animation(reduceMotion ? .none : .easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathingScale)
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            // Initialize AlarmKitViewModel if onboarding is complete or user is returning
            if !showOnboarding {
                print("🟢 Initializing AlarmKitViewModel (onboarding complete or returning user)")
                viewModelContainer.initializeIfNeeded()
            }

            // Pre-calculate wake up times for instant display
            calculateWakeUpTimes()
            currentTime = Date()

            // Only load saved alarm state if NOT showing onboarding
            // This prevents accessing runningAlarms (which triggers authorization) during first launch
            if !showOnboarding {
                loadSavedAlarmState()
            }

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

            // Reset the background flag
            isComingFromBackground = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // DON'T reconcile if we're in the middle of setting up an alarm
                // This prevents the success animation from being interrupted when returning from permission popup
                if case .settingUpAlarm = singleAlarmState {
                    print("⏭️ Skipping reconciliation - alarm setup in progress")
                    return
                }

                // Mark that we're coming from background
                isComingFromBackground = true

                updateTimeAndCalculations()
                triggerTimeAnimation()
                selectNextMoonIcon()

                // Reconcile alarm state with system reality
                reconcileAlarmState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            print("App entered background")
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
        .overlay {
            if showAlarmPermissionSheet {
                AlarmPermissionSheet(
                    isPresented: $showAlarmPermissionSheet,
                    onEnable: {
                        requestAlarmPermission()
                    }
                )
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
            calculationProgress += 0.0217
            
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
        // Add haptic feedback when loading completes
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

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

        // DON'T create AlarmKitViewModel here - wait until user clicks "Set Alarm"
        // This prevents authorization popup immediately after onboarding

        withAnimation(.easeOut(duration: 0.5)) {
            showOnboarding = false
        }

        // Start animations after onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectNextMoonIcon()
            startEntranceAnimation()
            startBreathingEffect()
            startZzzAnimation()

            // Now that onboarding is complete, load any saved alarm state
            // This was skipped during .onAppear to avoid triggering authorization
            loadSavedAlarmState()
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
            return "Recharge without feeling like a zombie"
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

    private func requestAlarmPermission() {
        guard let alarmViewModel = alarmViewModel else {
            print("⚠️ AlarmKitViewModel not initialized")
            return
        }

        Task {
            let hasPermission = await alarmViewModel.alarmManager.checkAuthorization()
            await MainActor.run {
                if hasPermission {
                    // Permission granted, proceed with the pending alarm if any
                    if let pendingTime = pendingAlarmTime, let pendingCycles = pendingAlarmCycles {
                        scheduleConfirmedAlarm(time: pendingTime, cycles: pendingCycles)
                        // Clear pending alarm details
                        pendingAlarmTime = nil
                        pendingAlarmCycles = nil
                    }
                }
                // If permission is denied, the modal will handle it with "Open Settings" button
                // No need for a second popup
            }
        }
    }

    private func scheduleTestAlarm() {
        // Get current time
        let now = Date()
        let calendar = Calendar.current

        // Get components and round to next minute (ignore seconds)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        guard let currentMinute = components.minute else { return }

        components.minute = currentMinute + 1  // Add 1 minute
        components.second = 0                  // Set seconds to 0

        // Create the alarm time
        guard let alarmTime = calendar.date(from: components) else { return }

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        print("Scheduling test alarm for: \(SleepCalculator.shared.formatTime(alarmTime))")

        // Schedule alarm directly (bypass selection UI for quick testing)
        Task {
            let alarmID = await scheduleAlarmKitAlarm(time: alarmTime, cycles: 1)

            let alarmData = SingleAlarmData(
                alarmTime: alarmTime,
                startTime: Date(),
                cycles: 1,
                alarmID: alarmID
            )
            saveAlarmData(alarmData)

            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    singleAlarmState = .active(
                        alarmTime: alarmTime,
                        startTime: Date(),
                        alarmID: alarmID
                    )
                }
                updateCountdown()
            }
        }
    }

    private func selectSingleAlarm(time: Date, cycles: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            singleAlarmState = .selected(time: time, cycles: cycles, adjustmentMinutes: 0)
            selectedAdjustment = 0 // Reset adjustment when selecting new time
        }
    }

    private func setSelectedAdjustment(_ minutes: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedAdjustment = minutes
        }
    }

    private func confirmAlarm() {
        guard case .selected(let time, let cycles, _) = singleAlarmState else { return }

        let adjustedTime = Calendar.current.date(byAdding: .minute, value: selectedAdjustment, to: time) ?? time

        // Show loading state immediately
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            alarmSetupPhase = .loading
            singleAlarmState = .settingUpAlarm(time: adjustedTime, cycles: cycles)
        }

        // Check if AlarmKitViewModel already exists (returning user)
        if let alarmViewModel = alarmViewModel {
            // ViewModel exists, check permission
            let hasPermission = alarmViewModel.alarmManager.checkAuthorizationWithoutRequest()

            if hasPermission {
                // Permission already granted, proceed with alarm scheduling
                // Add delay to show loading animation (1.5s for consistent feel)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.scheduleConfirmedAlarm(time: adjustedTime, cycles: cycles)
                }
            } else {
                // Permission was previously denied, show "Open Settings" sheet
                // Hide loading state and show permission sheet
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    singleAlarmState = .selected(time: time, cycles: cycles, adjustmentMinutes: selectedAdjustment)
                }
                showAlarmPermissionSheet = true
                pendingAlarmTime = adjustedTime
                pendingAlarmCycles = cycles
            }
        } else {
            // First time - request authorization BEFORE creating ViewModel
            // This prevents state pollution where ViewModel init changes auth state
            print("🟡 First alarm - requesting authorization directly from AlarmManager")

            // Use async authorization check that waits for user response
            Task {
                // Request authorization BEFORE creating ViewModel
                // Access AlarmManager singleton directly to avoid state pollution
                let alarmManager = ItsukiAlarmManager.shared

                print("🟡 Requesting authorization (will wait for user to tap Allow/Don't Allow)...")
                let isAuthorized = await alarmManager.checkAuthorization()

                await MainActor.run {
                    if isAuthorized {
                        // User granted permission - NOW create ViewModel and schedule alarm
                        print("✅ Permission granted by user, creating ViewModel and scheduling alarm")
                        self.viewModelContainer.initializeIfNeeded()

                        // Add delay for first-time users to let loading animation breathe (1.5s for consistent feel)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.scheduleConfirmedAlarm(time: adjustedTime, cycles: cycles)
                        }
                    } else {
                        // User denied permission - show settings sheet (consistent with returning user flow)
                        print("❌ Permission denied by user, showing settings sheet")

                        // Store pending alarm for if user grants permission via Settings
                        self.pendingAlarmTime = adjustedTime
                        self.pendingAlarmCycles = cycles

                        // Return to main view and show permission sheet
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            self.singleAlarmState = .none
                        }

                        // Show permission sheet after brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.showAlarmPermissionSheet = true
                        }
                    }
                }
            }
        }
    }

    private func scheduleConfirmedAlarm(time: Date, cycles: Int) {
        // Schedule the actual alarm using AlarmKit and get the ID
        Task {
            let alarmID = await scheduleAlarmKitAlarm(time: time, cycles: cycles)

            // Show success phase (but don't save data yet to prevent race condition)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    alarmSetupPhase = .success
                }
            }

            // Wait to show success animation, then transition to active view
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds (increased from 0.8s)

            // NOW save alarm data AFTER success animation completes
            // This prevents loadSavedAlarmState() from triggering during success phase
            await MainActor.run {
                let truncatedAlarmTime = truncateToMinute(time)
                let alarmData = SingleAlarmData(alarmTime: truncatedAlarmTime, startTime: Date(), cycles: cycles, alarmID: alarmID)
                saveAlarmData(alarmData)

                // Update state with the alarm ID and transition to active view
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    singleAlarmState = .active(alarmTime: time, startTime: Date(), alarmID: alarmID)
                }
                // Update countdown immediately when alarm becomes active
                updateCountdown()
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
        guard case .active(let alarmTime, let startTime, let alarmID) = singleAlarmState else { return }

        let now = Date()
        let timeRemaining = floor(alarmTime.timeIntervalSince(now))  // Floor to avoid negative flicker
        let totalTime = alarmTime.timeIntervalSince(startTime)

        if timeRemaining <= 0 {
            countdownDisplay = "00:00"
            progressValue = 1.0

            // DON'T immediately delete the alarm when it reaches 0!
            // Let AlarmKit handle the alarm firing, then clean up later
            // Only clear our UI state after a grace period to allow the alarm to ring

            let timeSinceAlarmTime = now.timeIntervalSince(alarmTime)

            if timeSinceAlarmTime > 60 {  // 1 minute grace period after alarm time
                // Alarm should have fired by now and been dismissed - safe to clean up
                print("Alarm time passed by >1 minute, cleaning up UI state")
                Task {
                    await deleteExistingAlarmKitAlarm(alarmID: alarmID, time: alarmTime)
                }
                clearSavedAlarmData()

                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    singleAlarmState = .none
                }
            }
            // If < 1 minute past alarm time, keep the countdown at 00:00 but DON'T delete the alarm
            return
        }

        // Round up to nearest minute for consistency with minute-based alarm system
        let remainingMinutes = Int(ceil(timeRemaining / 60.0))
        let hours = remainingMinutes / 60
        let minutes = remainingMinutes % 60

        countdownDisplay = String(format: "%02d:%02d", hours, minutes)
        progressValue = min(1.0, max(0.0, 1.0 - (timeRemaining / totalTime)))
    }
    
    // MARK: - AlarmKit Integration
    private func scheduleAlarmKitAlarm(time: Date, cycles: Int) async -> UUID? {
        // Check for duplicate alarms at the same time
        let existingAlarms = await MainActor.run { alarmViewModel?.runningAlarms ?? [] }
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
        alarmForm.label = "Time to wake up"
        
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
        let success = await alarmViewModel?.scheduleAlarmWithID(alarmID, with: alarmForm) ?? false

        if success {
            print("Scheduled single alarm for \(SleepCalculator.shared.formatTime(time)) with ID: \(alarmID)")
            return alarmID
        } else {
            print("Failed to schedule single alarm for \(SleepCalculator.shared.formatTime(time))")
            return nil
        }
    }
    
    private func deleteExistingAlarmKitAlarm(alarmID: UUID?, time: Date) async {
        let existingAlarms = await MainActor.run { alarmViewModel?.runningAlarms ?? [] }
        
        // First try to find by alarm ID (most reliable)
        if let alarmID = alarmID {
            if let alarm = existingAlarms.first(where: { $0.id == alarmID }) {
                await alarmViewModel?.deleteAlarm(alarm)
                print("Deleted single alarm by ID: \(alarmID)")
                return
            } else {
                print("Alarm with ID \(alarmID) not found in running alarms (may have already fired), falling back to time-based search")
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
                await alarmViewModel?.deleteAlarm(alarm)
                print("Deleted single alarm at \(SleepCalculator.shared.formatTime(time)) by time matching")
                break
            }
        }
    }
    
    // MARK: - Helper Functions
    private func truncateToMinute(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
    
    // MARK: - State Reconciliation
    private func loadSavedAlarmData() -> SingleAlarmData? {
        guard let data = UserDefaults.standard.data(forKey: SingleAlarmData.userDefaultsKey),
              let alarmData = try? JSONDecoder().decode(SingleAlarmData.self, from: data) else {
            return nil
        }
        return alarmData
    }

    private func reconcileAlarmState() {
        guard let alarmData = loadSavedAlarmData() else {
            singleAlarmState = .none
            return
        }

        let now = Date()

        // Check for completion flag
        if alarmData.completedTime != nil {
            clearSavedAlarmData()
            singleAlarmState = .none
            return
        }

        // Clear if alarm time passed (with 2 minute grace period for snooze scenarios)
        if now.timeIntervalSince(alarmData.alarmTime) > 120 {
            Task {
                await deleteExistingAlarmKitAlarm(alarmID: alarmData.alarmID, time: alarmData.alarmTime)
            }
            clearSavedAlarmData()
            singleAlarmState = .none
            return
        }

        // Check if alarm still exists in AlarmKit (with grace period for recently scheduled alarms)
        Task { @MainActor in
            let runningAlarms = alarmViewModel?.runningAlarms ?? []
            let stillScheduled = alarmData.alarmID.map { id in
                runningAlarms.contains { $0.id == id }
            } ?? false

            if !stillScheduled {
                // Give recently scheduled alarms a grace period (2 minutes) before assuming they're missing
                // This prevents deleting valid alarms due to timing issues with AlarmKit's runningAlarms
                let timeSinceScheduled = now.timeIntervalSince(alarmData.startTime)

                if timeSinceScheduled < 120 && now < alarmData.alarmTime {
                    // Recently scheduled and still in future - assume it's valid even if not found
                    print("Alarm not found in runningAlarms but recently scheduled (\(Int(timeSinceScheduled))s ago) - keeping it")
                    singleAlarmState = .active(alarmTime: alarmData.alarmTime, startTime: alarmData.startTime, alarmID: alarmData.alarmID)
                    updateCountdown()
                } else {
                    // Alarm is older or time has passed - safe to clear
                    print("Alarm not found in runningAlarms and not recently scheduled - clearing")
                    clearSavedAlarmData()
                    singleAlarmState = .none
                }
            } else if now < alarmData.alarmTime {
                // Alarm still valid, restore active state
                singleAlarmState = .active(alarmTime: alarmData.alarmTime, startTime: alarmData.startTime, alarmID: alarmData.alarmID)
                updateCountdown()
            } else {
                // Alarm time passed but still in grace period - clear it anyway
                Task {
                    await deleteExistingAlarmKitAlarm(alarmID: alarmData.alarmID, time: alarmData.alarmTime)
                }
                clearSavedAlarmData()
                singleAlarmState = .none
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
        guard let alarmData = loadSavedAlarmData() else {
            return
        }

        let now = Date()

        // Check for completion flag
        if alarmData.completedTime != nil {
            print("Alarm was already completed, clearing saved data")
            clearSavedAlarmData()
            singleAlarmState = .none
            return
        }

        // Aggressive clear if alarm is stale (> 2 minutes past)
        if now.timeIntervalSince(alarmData.alarmTime) > 120 {
            print("Alarm is stale (>2 minutes past), clearing: \(SleepCalculator.shared.formatTime(alarmData.alarmTime))")
            Task {
                await deleteExistingAlarmKitAlarm(alarmID: alarmData.alarmID, time: alarmData.alarmTime)
            }
            clearSavedAlarmData()
            singleAlarmState = .none
            return
        }

        // Only restore if alarm is in the future
        if now < alarmData.alarmTime {
            singleAlarmState = .active(alarmTime: alarmData.alarmTime, startTime: alarmData.startTime, alarmID: alarmData.alarmID)
            print("Loaded active alarm for: \(SleepCalculator.shared.formatTime(alarmData.alarmTime))")
            // Update countdown immediately when loading active alarm
            updateCountdown()
        } else {
            // Alarm time passed but within grace period - still clear it
            print("Alarm time has passed for: \(SleepCalculator.shared.formatTime(alarmData.alarmTime)) - clearing")
            Task {
                await deleteExistingAlarmKitAlarm(alarmID: alarmData.alarmID, time: alarmData.alarmTime)
            }
            clearSavedAlarmData()
            singleAlarmState = .none
        }
    }
    
    private func clearSavedAlarmData() {
        UserDefaults.standard.removeObject(forKey: SingleAlarmData.userDefaultsKey)
    }
    
    
    
    // MARK: - Single Alarm UI Views
    
    private func fullScreenAdjustmentView(selectedTime: Date, cycles: Int, geometry: GeometryProxy) -> some View {
        let adjustedTime = Calendar.current.date(byAdding: .minute, value: selectedAdjustment, to: selectedTime) ?? selectedTime

        return VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                // Alarm bell icon
                Image("alarm-bell-3D-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
                    .scaleEffect(breathingScale)
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathingScale)
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
                    
                    Text("\(formatSleepDurationSimple(cycles: cycles)) • \(cycles) sleep \(cycles == 1 ? "cycle" : "cycles")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Time adjustment buttons - selection based
                VStack(spacing: 16) {
                    Text("Adjust wake time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 12) {
                        adjustmentSelectionButton(minutes: 0, label: "On time")
                        adjustmentSelectionButton(minutes: 5, label: "+5 min")
                        adjustmentSelectionButton(minutes: 10, label: "+10 min")
                        adjustmentSelectionButton(minutes: 15, label: "+15 min")
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

    private func adjustmentSelectionButton(minutes: Int, label: String) -> some View {
        let isSelected = selectedAdjustment == minutes

        return Button(action: {
            setSelectedAdjustment(minutes)
        }) {
            HStack(spacing: 4) {
                // Add checkmark icon when differentiate without color is enabled
                if differentiateWithoutColor && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.black)
                }

                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .black : .white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ?
                          Color(red: 0.894, green: 0.729, blue: 0.306) :
                          Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.clear : Color.white.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .accessibilityHidden(true)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(minutes == 0 ? "Set alarm for exact calculated time" : "Set alarm \(minutes) minutes later than calculated time")
        .accessibilityHint("Double tap to select this timing adjustment")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func activeAlarmView(alarmTime: Date, startTime: Date, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                // Alarm time
                VStack(spacing: 12) {
                    Text("Alarm set for")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .accessibilityHidden(true)

                    Text(SleepCalculator.shared.formatTime(alarmTime))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundColor(.white)
                        .scaleEffect(reduceMotion ? 1.0 : breathingScale)
                        .animation(reduceMotion ? .none : .easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: breathingScale)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Alarm set for \(SleepCalculator.shared.formatTime(alarmTime))")
                .accessibilityAddTraits(.isHeader)

                // Reassurance message
                Text("✓ Alarm is set. You can safely close the app.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .accessibilityLabel("Alarm is set. You can safely close the app.")

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                        .accessibilityHidden(true)

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
                        .animation(reduceMotion ? .none : .linear(duration: 0.1), value: progressValue)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("Time left")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                            .accessibilityHidden(true)

                        Text(countdownDisplay)
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundColor(.white)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Time remaining until alarm: \(countdownDisplay)")
                .accessibilityValue("\(Int(progressValue * 100)) percent complete")
                .accessibilityAddTraits(.updatesFrequently)
                
                // Cancel button
                Button("Cancel Alarm") {
                    cancelAlarm()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .accessibilityHidden(true)
                )
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel alarm")
                .accessibilityHint("Double tap to cancel the scheduled alarm")
                .accessibilityAddTraits(.isButton)
            }
            
            Spacer()
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    let onComplete: () -> Void
    @State private var currentStep = 0
    @State private var contentOffset: CGFloat = 0
    @State private var contentOpacity: Double = 1.0
    @State private var iconScale: Double = 1.0
    @State private var buttonScale: Double = 0.9
    @State private var buttonPressed: Bool = false
    @State private var progressScale: [Double] = [1.0, 1.0, 1.0]
    @State private var isTransitioning: Bool = false
    @State private var showInitialAnimation: Bool = false
    
    let onboardingSteps = [
        OnboardingStep(
            icon: "moon-sleepy-3D-icon",
            title: "Welcome to Mr Sleep",
            subtitle: "Your sleep companion",
            description: "Sleep happens in 90-minute cycles. Waking up at the end of a cycle helps you feel refreshed.",
            buttonText: "Tell me more"
        ),
        OnboardingStep(
            icon: "sleepy-human-3D-icon",
            title: "Wake Up Smarter",
            subtitle: "Science-based wake times",
            description: "We calculate the best times for you to wake up based on when you plan to sleep.",
            buttonText: "How does it work?"
        ),
        OnboardingStep(
            icon: "clock-3D-icon",
            title: "Set Alarm & Sleep",
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
                // Content with smooth sliding transitions
                VStack(spacing: 30) {
                    // Icon with unified animation
                    getOnboardingIconImage(for: currentStep)
                        .frame(width: 240, height: 240)
                        .scaleEffect(showInitialAnimation ? iconScale : 0.8)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0), value: showInitialAnimation)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: iconScale)
                        .accessibilityHidden(true)
                    
                    // Title and subtitle with unified sliding
                    VStack(spacing: 8) {
                        Text(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].title : "Loading...")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].subtitle : "")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Description
                    Text(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].description : "")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 120, alignment: .top)
                }
                .opacity(contentOpacity)
                .offset(x: contentOffset)
                .animation(.spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0), value: contentOffset)
                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: contentOpacity)
                .frame(maxHeight: .infinity) // Take available space
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].title : "Loading"). \(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].subtitle : ""). \(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].description : "")")
                .accessibilityHint("Swipe left or right to navigate between steps")
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            guard !isTransitioning else { return }
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold && currentStep > 0 {
                                // Swipe right - go to previous step
                                performStepTransition(to: currentStep - 1)
                            } else if value.translation.width < -threshold && currentStep < onboardingSteps.count - 1 {
                                // Swipe left - go to next step
                                performStepTransition(to: currentStep + 1)
                            }
                        }
                )
                
                // Bottom section with consistent positioning
                VStack(spacing: 25) {
                        // Step indicators with smooth animations
                        HStack(spacing: 12) {
                            ForEach(0..<onboardingSteps.count, id: \.self) { index in
                                Circle()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(
                                        index == currentStep ?
                                        Color(red: 0.894, green: 0.729, blue: 0.306) :
                                        Color.white.opacity(0.3)
                                    )
                                    .scaleEffect(index == currentStep ? 1.3 * progressScale[index] : progressScale[index])
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: currentStep)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0).repeatCount(1), value: progressScale[index])
                            }
                        }
                        
                        // Action button with enhanced interactions
                        Button(action: {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            if currentStep < onboardingSteps.count - 1 {
                                performStepTransition(to: currentStep + 1)
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
                                    .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
                                    .shadow(color: Color.black.opacity(buttonPressed ? 0.1 : 0.2), radius: buttonPressed ? 3 : 6, x: 0, y: buttonPressed ? 1 : 3)
                            )
                            .scaleEffect(buttonScale)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: buttonScale)
                        }
                        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                buttonPressed = pressing
                                buttonScale = pressing ? 0.95 : 1.0
                            }
                        }, perform: {})
                        .accessibilityLabel(currentStep >= 0 && currentStep < onboardingSteps.count ? onboardingSteps[currentStep].buttonText : "Continue")
                        .accessibilityHint(currentStep < onboardingSteps.count - 1 ? "Double tap to continue to next step" : "Double tap to complete onboarding and start using the app")
                        .accessibilityAddTraits(.isButton)
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            // Initial entrance animations
            startInitialAnimations()
        }
    }
    
    private func startInitialAnimations() {
        // Start with content off-screen
        contentOffset = 50
        contentOpacity = 0
        iconScale = 0.8
        buttonScale = 0.9
        
        // Smooth entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.2)) {
            showInitialAnimation = true
            contentOffset = 0
            contentOpacity = 1.0
            iconScale = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.5)) {
            buttonScale = 1.0
        }
        
        // Animate progress indicators
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            animateProgressIndicators()
        }
    }
    
    private func performStepTransition(to newStep: Int) {
        guard newStep >= 0 && newStep < onboardingSteps.count && !isTransitioning else { return }
        
        isTransitioning = true
        
        // Add subtle haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Determine slide direction
        let slideDirection: CGFloat = newStep > currentStep ? -100 : 100
        
        // Smooth slide out with crossfade
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            contentOffset = slideDirection
            contentOpacity = 0.3
            iconScale = 0.95
        }
        
        // Update step at the peak of transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentStep = newStep
        }
        
        // Slide in new content from opposite direction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            contentOffset = -slideDirection * 0.5 // Start from opposite side, closer
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0)) {
                contentOffset = 0
                contentOpacity = 1.0
                iconScale = 1.0
            }
            
            // Animate progress indicators with slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateProgressIndicators()
            }
            
            // Allow next transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTransitioning = false
            }
        }
    }
    
    private func animateProgressIndicators() {
        // Only animate the current step indicator with a subtle pulse
        let currentIndex = currentStep
        if currentIndex < progressScale.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                progressScale[currentIndex] = 1.15
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                    progressScale[currentIndex] = 1.0
                }
            }
        }
    }
    
    @ViewBuilder
    private func getOnboardingIconImage(for step: Int) -> some View {
        let iconName = step >= 0 && step < onboardingSteps.count ? onboardingSteps[step].icon : "moon.zzz.fill"
        
        if iconName.contains("-3D-icon") {
            // Custom 3D icon from assets
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // System SF Symbol
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
        }
    }
}

// SleepGuideView is defined in the original SleepGuideView.swift file

// MARK: - Alarm Permission Sheets

struct AlarmPermissionSheet: View {
    @Binding var isPresented: Bool
    let onEnable: () -> Void
    @EnvironmentObject private var viewModelContainer: LazyAlarmKitContainer

    @State private var iconScale: Double = 0.7
    @State private var iconRotation: Double = -10
    @State private var cardScale: Double = 0.8
    @State private var cardOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0
    @State private var benefitsOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var iconPulse: Double = 1.0

    @State private var permissionStatus: String = "unknown"

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.9),
                    Color(red: 0.05, green: 0.1, blue: 0.3).opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    dismissModal()
                }
            }

            VStack(spacing: 28) {
                // Large animated icon with pulse effect
                Image("permission-3D-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .scaleEffect(iconScale * iconPulse)
                    .rotationEffect(.degrees(iconRotation))
                    .opacity(contentOpacity)

                VStack(spacing: 18) {
                    Text(permissionStatus == "denied" ? "Alarm Permission Required" : "Enable Sleep Alarms")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(permissionStatus == "denied" ?
                         "Please enable Alarms in Settings to set wake-up times" :
                         "Wake up at the perfect time in your sleep cycle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 8)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                VStack(spacing: 16) {
                    // Primary action button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if permissionStatus == "denied" {
                                // Open Settings
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            } else {
                                onEnable()
                            }
                            dismissModal()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: permissionStatus == "denied" ? "gear" : "alarm.waves.left.and.right.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(permissionStatus == "denied" ? "Open Settings" : "Enable Alarms")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.894, green: 0.729, blue: 0.306),
                                    Color(red: 0.94, green: 0.629, blue: 0.206)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(26)
                        .shadow(color: Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)

                    // Cancel button
                    Button("Maybe Later") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            dismissModal()
                        }
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16, weight: .medium))
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset * 0.5)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.35).opacity(0.95),
                                Color(red: 0.08, green: 0.08, blue: 0.25).opacity(0.98),
                                Color(red: 0.05, green: 0.05, blue: 0.2).opacity(1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                    .shadow(color: Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.5), radius: 60, x: 0, y: 30)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .padding(.horizontal, 32)
        }
        .onAppear {
            checkPermissionStatus()
            startEntranceAnimation()
        }
    }

    private func checkPermissionStatus() {
        // Check permission WITHOUT triggering authorization request
        let hasPermission = viewModelContainer.viewModel?.alarmManager.checkAuthorizationWithoutRequest() ?? false
        permissionStatus = hasPermission ? "authorized" : "denied"
    }

    private func startEntranceAnimation() {
        // Start with background
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }

        // Card entrance with spring
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }

        // Icon animation with rotation and scale
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            iconScale = 1.0
            iconRotation = 0
        }

        // Content animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            contentOffset = 0
            contentOpacity = 1.0
        }

        // Benefits fade in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5)) {
            benefitsOpacity = 1.0
        }

        // Start continuous pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startIconPulse()
        }
    }

    private func startIconPulse() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            iconPulse = 1.05
        }
    }

    private func dismissModal() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            cardScale = 0.9
            cardOpacity = 0
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

struct PermissionBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 8)
    }
}


// MARK: - Notification Extensions
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

#Preview {
    SingleAlarmView()
}

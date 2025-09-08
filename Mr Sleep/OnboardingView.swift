//
//  OnboardingView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

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

struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let buttonText: String
}

#Preview {
    OnboardingView(showOnboarding: .constant(true), onComplete: {})
}

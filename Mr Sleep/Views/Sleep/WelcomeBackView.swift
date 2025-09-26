//
//  WelcomeBackView.swift
//  Mr Sleep
//
//  Created by Claude on 26/09/2025.
//

/*
 * Welcome Back Splash Screen - Simplified Version
 * 
 * This view appears when the user opens the app within 1 hour of an alarm firing.
 * Features:
 * - Beautiful animated splash screen with positive messaging
 * - "Welcome Back" title with fade-in animation
 * - "Hope you had some great sleep" subtitle
 * - Simple system icon animation
 * - 3-second auto-dismiss timer
 * - Smooth transition animations
 */

import SwiftUI

struct WelcomeBackView: View {
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    
    // Animation states
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var encouragementOpacity: Double = 0
    @State private var iconScale: Double = 0.5
    @State private var breathingScale: Double = 1.0
    @State private var iconRotation: Double = 0
    @State private var sparkleRotation: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOffset: CGFloat = -30
    @State private var encouragementOffset: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Background gradient - Same as rest of app
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.25, blue: 0.5), // Darker blue
                    Color(red: 0.06, green: 0.15, blue: 0.35), // Much darker blue
                    Color(red: 0.03, green: 0.08, blue: 0.2) // Very dark blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            // Main content
            VStack(spacing: 40) {
                Spacer()
                
                // Energized human icon with enhanced animations
                Image("energized-human-3D-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .scaleEffect(iconScale * breathingScale)
                    .rotationEffect(.degrees(iconRotation))
                
                // Welcome message
                VStack(spacing: 20) {
                    // Main title with staggered character animation
                    HStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 24))
                            .opacity(titleOpacity)
                            .rotationEffect(.degrees(sparkleRotation))
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                            .offset(y: titleOffset)
                        
                        Text("✨")
                            .font(.system(size: 24))
                            .opacity(titleOpacity)
                            .rotationEffect(.degrees(-sparkleRotation))
                    }
                    
                    // Subtitle with slide animation
                    Text("Hope you had some great sleep")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                        .opacity(subtitleOpacity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .offset(x: subtitleOffset)
                    
                    // Encouraging message with separate animation
                    Text("You're ready to conquer the day! 🌟")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(encouragementOpacity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .offset(x: encouragementOffset)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startWelcomeAnimation()
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismissWithAnimation()
            }
        }
    }
    
    // MARK: - Animation Functions
    
    private func startWelcomeAnimation() {
        // Icon entrance with bounce and rotation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
            iconScale = 1.0
        }
        
        // Add subtle rotation to icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                iconRotation = 3.0 // Gentle 3-degree rotation
            }
        }
        
        // Sparkle rotation animation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            sparkleRotation = 360
        }
        
        // Title slide up and fade in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        
        // Subtitle slide in from left
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }
        
        // Encouragement slide in from right
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7)) {
            encouragementOpacity = 1.0
            encouragementOffset = 0
        }
        
        // Start breathing effect - much gentler and slower
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.05
            }
        }
    }
    
    private func dismissWithAnimation() {
        // Staggered fade out animations
        withAnimation(.easeOut(duration: 0.4)) {
            encouragementOpacity = 0
            encouragementOffset = 30
        }
        
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            subtitleOpacity = 0
            subtitleOffset = -30
        }
        
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            titleOpacity = 0
            titleOffset = 30
        }
        
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            iconScale = 0.5
        }
        
        // Dismiss the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            isPresented = false
            onComplete()
        }
    }
}

#Preview {
    WelcomeBackView(
        isPresented: .constant(true),
        onComplete: {}
    )
}
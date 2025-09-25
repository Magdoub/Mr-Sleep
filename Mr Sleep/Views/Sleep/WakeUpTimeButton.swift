//
//  WakeUpTimeButton.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

/*
 * Wake-Up Time Interactive Component
 * 
 * This view creates clickable cards for wake-up times:
 * - Displays wake-up time in large, readable format
 * - Shows sleep duration and cycle information
 * - Visual distinction for recommended times
 * - Interactive button with press animations
 * - Creates alarms when tapped
 * - Shadow and visual feedback for clickability
 */

import SwiftUI

struct WakeUpTimeButton: View {
    let wakeUpTime: String
    let currentTime: String
    let sleepDuration: String
    let isRecommended: Bool
    let cycles: Int
    let pulseScale: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var breathingScale: Double = 1.0
    @State private var chevronPulse: Double = 1.0
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            HStack(spacing: 16) {
                // Left side - Wake Up Time
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wake Up Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                    Text(wakeUpTime)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                }
                
                Spacer()
                
                // Right side - Total Sleep with clickability indicators
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Total Sleep")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                        Image(systemName: "alarm")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                    }
                    
                    HStack(spacing: 8) {
                        Text(sleepDuration)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                        
                        // Chevron to indicate clickability
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306)) // Accent gold color
                            .scaleEffect(chevronPulse)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: chevronPulse)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20) // Increased for better touch target
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isPressed ? 0.14 : 0.11)) // Improved contrast
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isPressed ? 0.25 : 0.20), lineWidth: 1) // Better border visibility
                )
                .shadow(
                    color: Color.black.opacity(0.25), // Enhanced shadow
                    radius: isPressed ? 4 : 7, // Increased radius for better elevation
                    x: 0,
                    y: isPressed ? 2 : 3 // Slightly more lift
                )
        )
        .scaleEffect((isPressed ? 0.98 : 1.0) * breathingScale)
        .animation(.easeInOut(duration: 0.15), value: isPressed) // Slightly longer for smoother feel
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingScale)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Start subtle animations after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                breathingScale = 1.015 // Very subtle breathing effect
                chevronPulse = 1.1 // Gentle pulse on chevron
            }
        }
        .accessibilityLabel("Create alarm for \(wakeUpTime), \(sleepDuration) total sleep")
        .accessibilityHint("Tap to create alarm and go to Alarms tab")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    WakeUpTimeButton(
        wakeUpTime: "7:30 AM",
        currentTime: "11:30 PM",
        sleepDuration: "7.5h",
        isRecommended: true,
        cycles: 5,
        pulseScale: 1.0,
        onTap: { print("Preview button tapped") }
    )
    .padding()
    .background(Color.black)
}


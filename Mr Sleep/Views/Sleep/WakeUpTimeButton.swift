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
    let isCreatingAlarm: Bool

    // Accessibility Environment Variables
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var isPressed = false
    @State private var breathingScale: Double = 1.0
    @State private var chevronPulse: Double = 1.0
    
    var body: some View {
        Button(action: {
            // Don't perform action if creating alarm
            guard !isCreatingAlarm else { return }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            HStack(spacing: 16) {
                // Left side - Wake Up Time
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wake Up Time")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(differentiateWithoutColor ? .white : Color(red: 0.8, green: 0.8, blue: 0.85)) // High contrast support
                    Text(wakeUpTime)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundColor(.white) // Better contrast
                }
                
                Spacer()
                
                // Right side - Total Sleep with clickability indicators
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Total Sleep")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(differentiateWithoutColor ? .white : Color(red: 0.8, green: 0.8, blue: 0.85)) // High contrast support
                        Image(systemName: "alarm")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(differentiateWithoutColor ? .white : Color(red: 0.8, green: 0.8, blue: 0.85)) // High contrast support
                            .accessibilityHidden(true)
                    }
                    
                    HStack(spacing: 8) {
                        Text(sleepDuration)
                            .font(.headline)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundColor(.white) // Better contrast

                        // Chevron to indicate clickability
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold for better contrast
                            .scaleEffect(reduceMotion ? 1.0 : chevronPulse)
                            .animation(reduceMotion ? .none : .easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: chevronPulse)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: .infinity) // Move frame inside button for full-width clickability
            .padding(.horizontal, 18) // Move padding inside button for clickable padding areas
            .padding(.vertical, 20) // Move padding inside button for clickable padding areas
            .contentShape(Rectangle()) // Makes entire area including Spacer clickable
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(reduceTransparency ? Color.gray.opacity(0.3) : Color.white.opacity(isPressed ? 0.14 : 0.11)) // Solid background for reduce transparency
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(reduceTransparency ? Color.white.opacity(0.6) : Color.white.opacity(isPressed ? 0.25 : 0.20), lineWidth: reduceTransparency ? 2 : 1) // Better border for reduce transparency
                )
                .shadow(
                    color: Color.black.opacity(0.25), // Enhanced shadow
                    radius: isPressed ? 4 : 7, // Increased radius for better elevation
                    x: 0,
                    y: isPressed ? 2 : 3 // Slightly more lift
                )
        )
        .scaleEffect((isPressed ? 0.95 : 1.0) * (reduceMotion ? 1.0 : breathingScale))
        .opacity(isCreatingAlarm ? 0.6 : 1.0) // Visual feedback during alarm creation
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.15), value: isPressed) // Slightly longer for smoother feel
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: isCreatingAlarm) // Smooth opacity transition
        .animation(reduceMotion ? .none : .easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingScale)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            if !reduceMotion {
                // Start subtle animations after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    breathingScale = 1.015 // Very subtle breathing effect
                    chevronPulse = 1.1 // Gentle pulse on chevron
                }
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
        onTap: { print("Preview button tapped") },
        isCreatingAlarm: false
    )
    .padding()
    .background(Color.black)
}


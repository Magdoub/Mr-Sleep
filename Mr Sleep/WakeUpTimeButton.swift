//
//  WakeUpTimeButton.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

/*
 * Wake-Up Time Display Component
 * 
 * This view creates informational displays for wake-up times:
 * - Displays wake-up time in large, readable format
 * - Shows sleep duration and cycle information
 * - Visual distinction for recommended times
 * - Pulse animations for user attention
 * - Category integration (Quick Boost, Recovery, Full Recharge)
 * - Consistent styling across the app
 * - Read-only information display (no interaction)
 */

import SwiftUI

struct WakeUpTimeButton: View {
    let wakeUpTime: String
    let currentTime: String
    let sleepDuration: String
    let isRecommended: Bool
    let cycles: Int
    let pulseScale: Double
    
    var body: some View {
        // Removed button wrapper - now just displays information
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
                
                // Right side - Total Sleep only
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Sleep")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.8))
                    Text(sleepDuration)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.98))
                }
            }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .accessibilityLabel("Wake up at \(wakeUpTime), \(sleepDuration) total sleep")
        .accessibilityHint("Sleep time information display")
    }
}

#Preview {
    WakeUpTimeButton(
        wakeUpTime: "7:30 AM",
        currentTime: "11:30 PM",
        sleepDuration: "7.5h",
        isRecommended: true,
        cycles: 5,
        pulseScale: 1.0
    )
    .padding()
    .background(Color.black)
}


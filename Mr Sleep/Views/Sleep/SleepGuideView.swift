//
//  SleepGuideView.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

/*
 * Sleep Education & Tips Interface
 * 
 * This view provides educational content about sleep hygiene:
 * - Sleep science explanation (90-minute cycles)
 * - Best practices for better sleep quality
 * - Tips for falling asleep faster
 * - Educational content accessible from main interface
 * - Clean, readable format with sectioned information
 * - Modal presentation with smooth animations
 */

import SwiftUI

struct SleepGuideView: View {
    @Binding var showSleepGuide: Bool

    // Accessibility Environment Variables
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: {
                        showSleepGuide = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white) // Better contrast
                    }
                    .accessibilityLabel("Close sleep guide")
                    .accessibilityHint("Double tap to return to main screen")
                    .accessibilityAddTraits(.isButton)
                    
                    Spacer()
                    
                    Text("Sleep Cycle Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Image(systemName: "xmark")
                        .font(.headline)
                        .fontWeight(.medium)
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
                    .font(.title2)
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4)) // Brighter gold
                    .frame(width: 30)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white) // Better contrast
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95)) // Improved contrast
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(reduceTransparency ? Color.gray.opacity(0.4) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(reduceTransparency ? Color.white.opacity(0.6) : Color.white.opacity(0.15), lineWidth: reduceTransparency ? 2 : 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(content)")
    }
}

#Preview {
    SleepGuideView(showSleepGuide: .constant(true))
}


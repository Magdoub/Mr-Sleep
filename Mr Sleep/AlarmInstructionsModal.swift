//
//  AlarmInstructionsModal.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

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
                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Set Your Alarm. Wake up at \(wakeUpTime)")
                .accessibilityAddTraits(.isHeader)
                
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("1.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Open the Clock app on your iPhone")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("2.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Tap the '+' button to add a new alarm")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.95))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("3.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
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
                        .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                    
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
                                .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
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
    AlarmInstructionsModal(wakeUpTime: "7:30 AM", showModal: .constant(true))
}

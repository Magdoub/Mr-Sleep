//
//  LoadingViews.swift
//  Mr Sleep
//
//  Created by Magdoub on 17/08/2025.
//

import SwiftUI

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
                            colors: [Color(red: 0.894, green: 0.729, blue: 0.306), Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.3)],
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
                        Color(red: 0.894, green: 0.729, blue: 0.306),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Center pulsing dot
                Circle()
                    .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
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
                            .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
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
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
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
            // Simple pulsing checkmark or completion icon - match CalculatingWakeUpTimesView positioning
            ZStack {
                Circle()
                    .fill(Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
            }
            .scaleEffect(1.1) // Match the CalculatingWakeUpTimesView scale
            
            // Finishing up text
            Text("Finishing up...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
            
            // Progress percentage placeholder (invisible to match layout)
            Text("100%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.894, green: 0.729, blue: 0.306))
                .opacity(0) // Invisible but maintains layout spacing
        }
        .frame(height: 140)
        .onAppear {
            pulseScale = 1.2
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CalculatingWakeUpTimesView(progress: 0.7)
        FinishingUpView()
    }
    .padding()
    .background(Color.black)
}

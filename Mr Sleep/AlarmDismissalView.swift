//
//  AlarmDismissalView.swift
//  Mr Sleep
//
//  Created by Magdoub on 10/09/2025.
//

import SwiftUI

struct AlarmDismissalView: View {
    let alarm: AlarmItem
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient matching the reference image
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.7, blue: 0.9),
                        Color(red: 0.2, green: 0.5, blue: 0.8),
                        Color(red: 0.1, green: 0.3, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Current time display - exactly like the reference image
                    VStack(spacing: 8) {
                        Text(currentTimeDay)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(currentTimeString)
                            .font(.system(size: 80, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(.bottom, 100)
                    
                    Spacer()
                    
                    // Dismiss button (exactly matching reference design)
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.9, green: 0.3, blue: 0.3),
                                                Color(red: 0.8, green: 0.2, blue: 0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isAnimating ? 1.03 : 1.0)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isAnimating)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            print("🚨 AlarmDismissalView appeared - alarm should continue until dismissed")
            isAnimating = true
        }
    }
    
    private var currentTimeDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    AlarmDismissalView(
        alarm: AlarmItem(
            time: "7:30 AM",
            isEnabled: true,
            label: "Morning Alarm",
            category: "Quick Boost",
            cycles: 5,
            createdFromSleepNow: false,
            soundName: "Morning",
            shouldAutoReset: false
        ),
        onDismiss: {
            print("Dismiss button tapped in preview")
        }
    )
}
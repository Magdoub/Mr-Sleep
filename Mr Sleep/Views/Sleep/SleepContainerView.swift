//
//  SleepContainerView.swift
//  Mr Sleep
//
//  Created by Claude on 02/11/2025.
//

/*
 * Sleep Container View - Mode Toggle Wrapper
 *
 * This view wraps both SingleAlarmView (Sleep Now) and WakeUpAtView (Wake Up At)
 * and provides a toggle to switch between them.
 *
 * Features:
 * - Custom segmented toggle control
 * - Smooth crossfade transition between modes
 * - Mode persistence via UserDefaults
 * - Haptic feedback on toggle
 * - Same gradient background as child views
 */

import SwiftUI

struct SleepContainerView: View {
    @EnvironmentObject var viewModelContainer: LazyAlarmKitContainer
    @Environment(\.scenePhase) private var scenePhase

    // Mode selection state
    @State private var selectedMode: SleepMode = .sleepNow
    @State private var hasLoadedInitialMode = false

    // Onboarding state - hide toggle during onboarding (synced with child view)
    @State private var isOnboardingActive: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    // Computed property for toggle visibility
    private var shouldShowToggle: Bool {
        !isOnboardingActive
    }

    // Animation
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Background gradient - matches child views
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
                // Toggle at top (below safe area) - HIDDEN DURING ONBOARDING
                if shouldShowToggle {
                    ModeToggle(selectedMode: $selectedMode)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                        .zIndex(10) // Keep toggle above scrolling content
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Content (switches based on mode)
                ZStack {
                    if selectedMode == .sleepNow {
                        SingleAlarmView(isOnboardingActive: $isOnboardingActive)
                            .environmentObject(viewModelContainer)
                            .transition(.opacity)
                    } else {
                        WakeUpAtView()
                            .transition(.opacity)
                    }
                }
            }
        }
        .onAppear {
            // Always default to Sleep Now on fresh launch
            selectedMode = .sleepNow
            hasLoadedInitialMode = true
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // When returning from background, load saved mode
            if newPhase == .active && hasLoadedInitialMode {
                selectedMode = SleepMode.loadFromUserDefaults()
            }
        }
        .onChange(of: selectedMode) { oldMode, newMode in
            saveSelectedMode(newMode)
        }
    }

    // MARK: - Mode Persistence

    private func saveSelectedMode(_ mode: SleepMode) {
        mode.saveToUserDefaults()
    }
}

// MARK: - Mode Toggle Component

struct ModeToggle: View {
    @Binding var selectedMode: SleepMode

    // Microinteraction states
    @State private var selectedScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 1.0

    // Golden accent color
    private let goldenColor = Color(red: 0.894, green: 0.729, blue: 0.306)

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Glow layer (slides with pill)
            RoundedRectangle(cornerRadius: 22)
                .fill(goldenColor)
                .frame(width: 154, height: 42)
                .offset(x: selectedMode == .sleepNow ? -78 : 78)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 10)

            // SINGLE sliding pill - moves based on selection
            RoundedRectangle(cornerRadius: 22)
                .fill(goldenColor)
                .frame(width: 154, height: 42)
                .offset(x: selectedMode == .sleepNow ? -78 : 78)
                .shadow(color: goldenColor.opacity(0.3), radius: 6, x: 0, y: 2)
                .scaleEffect(selectedScale)

            // Text labels (static, on top of sliding pill)
            HStack(spacing: 0) {
                // Sleep Now button
                Button {
                    if selectedMode != .sleepNow {
                        selectMode(.sleepNow)
                    }
                } label: {
                    Text("Sleep Now")
                        .font(.system(size: 17, weight: selectedMode == .sleepNow ? .semibold : .regular, design: .rounded))
                        .foregroundColor(selectedMode == .sleepNow ? .white : Color(red: 0.6, green: 0.6, blue: 0.65))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sleep Now")
                .accessibilityAddTraits(selectedMode == .sleepNow ? [.isButton, .isSelected] : .isButton)

                // Wake Up At button
                Button {
                    if selectedMode != .wakeUpAt {
                        selectMode(.wakeUpAt)
                    }
                } label: {
                    Text("Wake Up At")
                        .font(.system(size: 17, weight: selectedMode == .wakeUpAt ? .semibold : .regular, design: .rounded))
                        .foregroundColor(selectedMode == .wakeUpAt ? .white : Color(red: 0.6, green: 0.6, blue: 0.65))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Wake Up At")
                .accessibilityAddTraits(selectedMode == .wakeUpAt ? [.isButton, .isSelected] : .isButton)
            }
        }
        .frame(width: 320, height: 48)
        .background(
            // Frosted glass background - blends with main gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        // Drag gesture for swipe-to-toggle
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe right → Wake Up At
                    if value.translation.width > 30 && selectedMode == .sleepNow {
                        selectMode(.wakeUpAt)
                    }
                    // Swipe left → Sleep Now
                    else if value.translation.width < -30 && selectedMode == .wakeUpAt {
                        selectMode(.sleepNow)
                    }
                }
        )
        // Animate pill sliding
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.7), value: selectedMode)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep mode toggle")
        .accessibilityHint("Switch between Sleep Now and Wake Up At modes. Swipe or tap to change.")
    }

    private func selectMode(_ mode: SleepMode) {
        // Haptic feedback - soft for premium feel
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        if reduceMotion {
            selectedMode = mode
            return
        }

        // Trigger glow pulse
        glowOpacity = 0.5
        glowScale = 1.2

        // Animate the pill sliding
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedMode = mode
        }

        // Scale bounce microinteraction
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            selectedScale = 1.06
        }

        // Settle animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.25)) {
                glowOpacity = 0.0
                glowScale = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SleepContainerView()
        .environmentObject(LazyAlarmKitContainer())
}

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
 * - Custom segmented toggle control at top
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

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            // Sleep Now button
            ModeButton(
                title: "Sleep Now",
                isSelected: selectedMode == .sleepNow,
                action: {
                    if selectedMode != .sleepNow {
                        if reduceMotion {
                            selectedMode = .sleepNow
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedMode = .sleepNow
                            }
                        }
                        // Haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            )

            // Wake Up At button
            ModeButton(
                title: "Wake Up At",
                isSelected: selectedMode == .wakeUpAt,
                action: {
                    if selectedMode != .wakeUpAt {
                        if reduceMotion {
                            selectedMode = .wakeUpAt
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedMode = .wakeUpAt
                            }
                        }
                        // Haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            )
        }
        .frame(width: 320, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.08, green: 0.12, blue: 0.25).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep mode toggle")
        .accessibilityHint("Switch between Sleep Now and Wake Up At modes")
    }
}

// MARK: - Mode Button Component

struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : Color(red: 0.7, green: 0.7, blue: 0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color(red: 0.894, green: 0.729, blue: 0.306))
                                .padding(2)
                                .shadow(color: Color(red: 0.894, green: 0.729, blue: 0.306).opacity(0.4), radius: 8, x: 0, y: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select \(title) mode")
    }
}

// MARK: - Preview

#Preview {
    SleepContainerView()
        .environmentObject(LazyAlarmKitContainer())
}

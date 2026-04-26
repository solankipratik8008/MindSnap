//
//  OnboardingView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// OnboardingView.swift
// MindSnap — CRASH FIXED VERSION
//
// WHAT CHANGED:
// Fixed crash when Face ID is enabled on last onboarding slide.
// After enabling Face ID → immediately mark as authenticated
// so lock screen doesn't trigger right after onboarding ends.
// The lock WILL work correctly next time app backgrounds.
// ============================================================

import SwiftUI

struct OnboardingPage {
    let systemImage: String
    let imageColor: Color
    let title: String
    let subtitle: String
    let backgroundGradient: [Color]
}

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPage = 0

    // --------------------------------------------------------
    // authService — Used for Face ID setup on last slide
    //
    // CRASH FIX: We now call authService.unlockWithoutBiometrics()
    // right after enabling Face ID so the app doesn't immediately
    // try to lock right after onboarding completes.
    // --------------------------------------------------------
    @State private var authService = AuthService()

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                systemImage: "brain.head.profile",
                imageColor: .purple,
                title: "Welcome to MindSnap",
                subtitle: "Your personal on-device smart journal.\nWrite freely. Understand your emotions.\nGrow every day.",
                backgroundGradient: [.purple, .purple]
            ),
            OnboardingPage(
                systemImage: "lock.shield.fill",
                imageColor: .green,
                title: "100% Private",
                subtitle: "Your journal never leaves your device.\nNo accounts. No cloud. No ads.\nJust you and your thoughts.",
                backgroundGradient: [.green, .green]
            ),
            OnboardingPage(
                systemImage: authService.biometricType == "Touch ID"
                    ? "touchid" : "faceid",
                imageColor: .blue,
                title: "Keep It Private",
                subtitle: "Lock MindSnap with \(authService.biometricType) so only you can read your journal entries.",
                backgroundGradient: [.blue, .blue]
            )
        ]
    }

    private var backgroundOpacity: Double {
        colorScheme == .dark ? 0.35 : 0.15
    }

    private var cardOpacity: Double {
        colorScheme == .dark ? 0.25 : 0.12
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    pages[currentPage].imageColor.opacity(backgroundOpacity),
                    pages[currentPage].imageColor.opacity(backgroundOpacity / 3),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {

                // ---- Skip Button ----
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            let haptic = UIImpactFeedbackGenerator(
                                style: .light
                            )
                            haptic.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                completeOnboarding()
                            }
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 50)

                // ---- Slides ----
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        slideView(for: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                }

                // ---- Bottom Controls ----
                bottomControls
                    .padding(.bottom, 40)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Subviews
    // --------------------------------------------------------

    @ViewBuilder
    private func slideView(for page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.imageColor.opacity(cardOpacity * 1.5))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(page.imageColor.opacity(cardOpacity * 2))
                    .frame(width: 120, height: 120)

                Image(systemName: page.systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(page.imageColor)
            }
            .transition(.scale.combined(with: .opacity))

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {

            // ---- Page Dots ----
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage
                              ? pages[currentPage].imageColor
                              : Color.secondary.opacity(0.3))
                        .frame(
                            width: index == currentPage ? 24 : 8,
                            height: 8
                        )
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: currentPage
                        )
                }
            }

            actionButton
        }
        .padding(.horizontal, 32)
    }

    private var actionButton: some View {
        VStack(spacing: 12) {
            Button {
                handleActionButton()
            } label: {
                Text(actionButtonTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(pages[currentPage].imageColor)
                    )
                    .shadow(
                        color: pages[currentPage].imageColor.opacity(
                            colorScheme == .dark ? 0.6 : 0.4
                        ),
                        radius: colorScheme == .dark ? 12 : 8,
                        x: 0,
                        y: 4
                    )
            }

            if currentPage == pages.count - 1 {
                Button("Skip for now") {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    completeOnboarding()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    private var actionButtonTitle: String {
        switch currentPage {
        case 0, 1:
            return "Next →"
        case pages.count - 1:
            if authService.isBiometricAvailable {
                return "Enable \(authService.biometricType)"
            } else {
                return "Get Started"
            }
        default:
            return "Next →"
        }
    }

    // --------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------

    // --------------------------------------------------------
    // handleActionButton()
    //
    // CRASH FIX: After enabling Face ID during onboarding,
    // we immediately call unlockWithoutBiometrics() so the
    // app doesn't try to lock right after onboarding ends.
    //
    // Flow:
    //   User taps "Enable Face ID"
    //     → isFaceIDEnabled = true
    //     → authService.unlockWithoutBiometrics() ← KEY FIX
    //     → completeOnboarding()
    //     → MainTabView appears
    //     → isAuthenticated is already true
    //     → Lock screen does NOT appear ✅
    //     → Next time app backgrounds → lock activates ✅
    // --------------------------------------------------------
    private func handleActionButton() {
        if currentPage < pages.count - 1 {
            // Next slide
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        } else {
            // Last slide — complete onboarding
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)

            if authService.isBiometricAvailable {
                // Enable Face ID
                isFaceIDEnabled = true

                // ---- CRASH FIX ----
                // Mark as authenticated immediately after enabling
                // Face ID so lock screen doesn't trigger right away.
                // Lock will activate correctly when app next
                // goes to background.
                authService.unlockWithoutBiometrics()
            }

            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
    OnboardingView()
}

#Preview("Dark Mode") {
    OnboardingView()
        .preferredColorScheme(.dark)
}

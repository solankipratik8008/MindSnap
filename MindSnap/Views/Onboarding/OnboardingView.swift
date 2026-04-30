//
//  OnboardingView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// OnboardingView.swift
// MindSnap — Premium Monochrome Onboarding
//
// SAFE UI UPDATE:
// 1. Keeps onboarding completion logic
// 2. Keeps Face ID setup logic
// 3. Keeps crash fix after enabling Face ID
// 4. Keeps AppStorage keys unchanged
// 5. Updates UI to professional black/white theme
// 6. Keeps small meaningful accent colors per page
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

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    @AppStorage("isFaceIDEnabled")
    private var isFaceIDEnabled = false

    @Environment(\.colorScheme)
    private var colorScheme

    @State private var currentPage = 0

    // Used for Face ID setup on last slide.
    // Important: after enabling Face ID, we call unlockWithoutBiometrics()
    // so the app does not immediately show the lock screen after onboarding.
    @State private var authService = AuthService()

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                systemImage: "brain.head.profile",
                imageColor: .purple,
                title: "Welcome to\nMindSnap",
                subtitle: "Reflect, track your mood, and build better habits with a private daily journal.",
                backgroundGradient: [.purple, .purple]
            ),
            OnboardingPage(
                systemImage: "lock.shield.fill",
                imageColor: .green,
                title: "Private by Design",
                subtitle: "Your journal stays personal, calm, and secure — built around privacy from day one.",
                backgroundGradient: [.green, .green]
            ),
            OnboardingPage(
                systemImage: authService.biometricType == "Touch ID"
                    ? "touchid"
                    : "faceid",
                imageColor: .blue,
                title: "Keep It Protected",
                subtitle: "Use \(authService.biometricType) to protect your journal when you leave the app.",
                backgroundGradient: [.blue, .blue]
            )
        ]
    }

    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var softBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.07)
        : Color.black.opacity(0.045)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.66)
        : Color.black.opacity(0.54)
    }

    private var tertiaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.38)
        : Color.black.opacity(0.34)
    }

    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.07)
    }

    private var primaryButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var primaryButtonText: Color {
        colorScheme == .dark ? .black : .white
    }

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.08)
    }

    private var pageAccent: Color {
        pages[currentPage].imageColor
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                topBar

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

                bottomControls
                    .padding(.bottom, 38)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Background
    // --------------------------------------------------------
    private var backgroundLayer: some View {
        ZStack {
            appBackground
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    pageAccent.opacity(colorScheme == .dark ? 0.20 : 0.12),
                    pageAccent.opacity(colorScheme == .dark ? 0.08 : 0.045),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.45), value: currentPage)

            VStack {
                Spacer()

                RadialGradient(
                    colors: [
                        primaryText.opacity(colorScheme == .dark ? 0.07 : 0.035),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 40,
                    endRadius: 360
                )
                .frame(height: 260)
            }
            .ignoresSafeArea()
        }
    }

    // --------------------------------------------------------
    // MARK: - Top Bar
    // --------------------------------------------------------
    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(primaryButtonBackground)
                        .frame(width: 32, height: 32)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(primaryButtonText)
                }

                Text("MindSnap")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
            }

            Spacer()

            if currentPage < pages.count - 1 {
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()

                    withAnimation(.easeInOut(duration: 0.3)) {
                        completeOnboarding()
                    }
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(softBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(height: 64)
    }

    // --------------------------------------------------------
    // MARK: - Slide View
    // --------------------------------------------------------
    @ViewBuilder
    private func slideView(for page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Spacer(minLength: 28)

            ZStack {
                Circle()
                    .fill(page.imageColor.opacity(colorScheme == .dark ? 0.16 : 0.09))
                    .frame(width: 190, height: 190)

                Circle()
                    .fill(cardBackground)
                    .frame(width: 150, height: 150)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: shadowColor,
                        radius: 18,
                        x: 0,
                        y: 10
                    )

                Circle()
                    .stroke(
                        page.imageColor.opacity(colorScheme == .dark ? 0.28 : 0.18),
                        lineWidth: 9
                    )
                    .frame(width: 168, height: 168)

                Image(systemName: page.systemImage)
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(page.imageColor)
            }
            .padding(.bottom, 4)
            .transition(.scale.combined(with: .opacity))

            VStack(spacing: 16) {
                
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Text(page.subtitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 34)
            }

            infoCard(for: page)
                .padding(.horizontal, 28)
                .padding(.top, 6)

            Spacer(minLength: 32)
        }
    }

    // --------------------------------------------------------
    // MARK: - Info Card
    // --------------------------------------------------------
    private func infoCard(for page: OnboardingPage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: currentPage == 0 ? "checkmark.seal.fill" :
                    currentPage == 1 ? "lock.fill" : "faceid")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(page.imageColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(page.imageColor.opacity(colorScheme == .dark ? 0.16 : 0.10))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(infoTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Text(infoSubtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
    }

    private var infoTitle: String {
        switch currentPage {
        case 0:
            return "Reflect in seconds"
        case 1:
            return "Built around privacy"
        default:
            return "Optional protection"
        }
    }

    private var infoSubtitle: String {
        switch currentPage {
        case 0:
            return "Track moods, write thoughts, and build consistency one small step at a time."
        case 1:
            return "Your journal content is not shown in widgets and stays personal."
        default:
            return "You can turn this on now or skip it and enable it later in Settings."
        }
    }

    // --------------------------------------------------------
    // MARK: - Bottom Controls
    // --------------------------------------------------------
    private var bottomControls: some View {
        VStack(spacing: 22) {
            pageDots

            actionButton
        }
        .padding(.horizontal, 30)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage
                        ? primaryText
                        : tertiaryText.opacity(0.45)
                    )
                    .frame(
                        width: index == currentPage ? 26 : 8,
                        height: 8
                    )
                    .animation(
                        .easeInOut(duration: 0.3),
                        value: currentPage
                    )
            }
        }
    }

    private var actionButton: some View {
        VStack(spacing: 12) {
            Button {
                handleActionButton()
            } label: {
                HStack(spacing: 8) {
                    Text(actionButtonTitle)
                        .font(.headline)
                        .fontWeight(.bold)

                    if currentPage < pages.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundStyle(primaryButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(primaryButtonBackground)
                        .overlay(
                            Capsule()
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.16)
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(.plain)

            if currentPage == pages.count - 1 {
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()

                    completeOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(secondaryText)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    private var actionButtonTitle: String {
        switch currentPage {
        case 0, 1:
            return "Next"
        case pages.count - 1:
            if authService.isBiometricAvailable {
                return "Enable \(authService.biometricType)"
            } else {
                return "Get Started"
            }
        default:
            return "Next"
        }
    }

    // --------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------
    private func handleActionButton() {
        if currentPage < pages.count - 1 {
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()

            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        } else {
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)

            if authService.isBiometricAvailable {
                isFaceIDEnabled = true

                // Important crash fix:
                // Prevent lock screen from appearing immediately
                // after onboarding finishes.
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

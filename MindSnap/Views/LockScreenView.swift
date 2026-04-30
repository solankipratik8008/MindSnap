//
//  LockScreenView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// LockScreenView.swift
// MindSnap — Premium Monochrome Lock Screen
//
// SAFE UI UPDATE:
// 1. Keeps existing AuthService logic
// 2. Keeps automatic Face ID/Touch ID prompt delay
// 3. Keeps manual unlock button
// 4. Keeps error message handling
// 5. Keeps Apple-safe "private smart journal" wording
// 6. Updates UI to professional black/white theme
// 7. Supports light and dark mode
// ============================================================

import SwiftUI

struct LockScreenView: View {

    let authService: AuthService

    @Environment(\.colorScheme) private var colorScheme

    @State private var isAnimating = false
    @State private var showingError = false

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

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {

            backgroundView

            VStack(spacing: 32) {
                Spacer()

                logoSection

                Spacer()

                lockSection

                Spacer()

                privacyBadge
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isAnimating = true

            // Longer delay on real device — Face ID needs more
            // time to initialize than simulator Touch ID.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                Task { @MainActor in
                    await authService.authenticate()
                }
            }
        }
        .onChange(of: authService.authError) { _, newError in
            withAnimation(.easeInOut(duration: 0.3)) {
                showingError = newError != nil
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.authError)
    }

    // --------------------------------------------------------
    // MARK: - Background
    // --------------------------------------------------------
    private var backgroundView: some View {
        ZStack {
            appBackground
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    primaryText.opacity(colorScheme == .dark ? 0.10 : 0.055),
                    primaryText.opacity(colorScheme == .dark ? 0.035 : 0.020),
                    Color.clear
                ],
                center: .top,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                RadialGradient(
                    colors: [
                        primaryText.opacity(colorScheme == .dark ? 0.07 : 0.035),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 20,
                    endRadius: 360
                )
                .frame(height: 280)
            }
            .ignoresSafeArea()
        }
    }

    // --------------------------------------------------------
    // MARK: - Logo Section
    // --------------------------------------------------------
    private var logoSection: some View {
        VStack(spacing: 18) {

            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(primaryText.opacity(colorScheme == .dark ? 0.08 : 0.045))
                    .frame(width: 124, height: 124)
                    .scaleEffect(isAnimating ? 1.12 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.6)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Circle()
                    .stroke(
                        primaryText.opacity(colorScheme == .dark ? 0.14 : 0.08),
                        lineWidth: 10
                    )
                    .frame(width: 112, height: 112)
                    .scaleEffect(isAnimating ? 1.04 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.6)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Inner circle
                Circle()
                    .fill(cardBackground)
                    .frame(width: 92, height: 92)
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

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(primaryText)
            }

            VStack(spacing: 6) {
                Text("MindSnap")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text("Your private smart journal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Lock Section
    // --------------------------------------------------------
    private var lockSection: some View {
        VStack(spacing: 18) {

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(softBackground)
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 1)
                        )

                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(primaryText)
                }

                Text("Journal Locked")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Text("Unlock to continue your private reflection.")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
            }

            // ---- Unlock Button ----
            Button {
                Task {
                    await authService.authenticate()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: biometricIcon)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Unlock with \(authService.biometricType)")
                        .font(.headline)
                        .fontWeight(.bold)
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
                        .shadow(
                            color: shadowColor,
                            radius: 14,
                            x: 0,
                            y: 8
                        )
                )
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))

            // ---- Error Message ----
            if let error = authService.authError {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)

                    Text(error)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(primaryText)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.16 : 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.red.opacity(0.20), lineWidth: 1)
                        )
                )
                .transition(
                    .opacity.combined(
                        with: .move(edge: .bottom)
                    )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 18,
                    x: 0,
                    y: 10
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Privacy Badge
    // --------------------------------------------------------
    private var privacyBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(primaryText)

            Text("Private on your device and iCloud")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(softBackground)
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Biometric Icon
    // --------------------------------------------------------
    private var biometricIcon: String {
        switch authService.biometricType {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        default:
            return "lock.open.fill"
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
    LockScreenView(authService: AuthService())
}

#Preview("Dark Mode") {
    LockScreenView(authService: AuthService())
        .preferredColorScheme(.dark)
}

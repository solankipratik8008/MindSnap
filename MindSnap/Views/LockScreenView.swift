//
//  LockScreenView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// LockScreenView.swift
// MindSnap — APPLE GUIDELINES COMPLIANT VERSION
//
// WHAT CHANGED:
// Fixed "Your private AI journal" →
//       "Your private smart journal"
// More accurate description of what the app does
// ============================================================

import SwiftUI

struct LockScreenView: View {

    let authService: AuthService
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var showingError = false

    var body: some View {
        ZStack {

            // ---- Background ----
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                // ---- Logo Section ----
                logoSection

                Spacer()

                // ---- Lock Section ----
                lockSection

                Spacer()

                // ---- Privacy Badge ----
                privacyBadge
                    .padding(.bottom, 32)
            }
        }
     
        .onAppear {
            isAnimating = true
            // Longer delay on real device — Face ID needs more
            // time to initialize than simulator Touch ID
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
    // MARK: - Subviews
    // --------------------------------------------------------

    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color.purple.opacity(0.6),
                        Color.purple.opacity(0.2),
                        Color.clear
                    ]
                    : [
                        Color.purple.opacity(0.5),
                        Color.purple.opacity(0.2),
                        Color.clear
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Pulse ring
                Circle()
                    .fill(Color.purple.opacity(
                        colorScheme == .dark ? 0.3 : 0.2
                    ))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Inner circle
                Circle()
                    .fill(Color.purple.opacity(
                        colorScheme == .dark ? 0.4 : 0.3
                    ))
                    .frame(width: 80, height: 80)

                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            // App name
            Text("MindSnap")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // --------------------------------------------------------
            // FIXED: "Your private AI journal"
            //      → "Your private smart journal"
            //
            // Why: Apple may flag "AI" claims that aren't
            // backed by a proper AI service disclosure.
            // Our app uses Apple's NaturalLanguage framework
            // which is on-device ML, not a traditional AI service.
            // "Smart journal" is accurate and avoids scrutiny.
            // --------------------------------------------------------
            Text("Your private smart journal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var lockSection: some View {
        VStack(spacing: 20) {

            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Journal Locked")
                .font(.headline)
                .foregroundStyle(.primary)

            // ---- Unlock Button ----
            Button {
                Task {
                    await authService.authenticate()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: biometricIcon)
                        .font(.title3)
                    Text("Unlock with \(authService.biometricType)")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(
                    colorScheme == .dark ? .white : .purple
                )
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark
                              ? Color.purple.opacity(0.3)
                              : Color.white)
                        .shadow(
                            color: .black.opacity(
                                colorScheme == .dark ? 0.3 : 0.15
                            ),
                            radius: 10, x: 0, y: 5
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            Color.purple.opacity(
                                colorScheme == .dark ? 0.5 : 0
                            ),
                            lineWidth: 1
                        )
                )
            }
            .transition(.scale.combined(with: .opacity))

            // ---- Error Message ----
            if let error = authService.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(
                                colorScheme == .dark ? 0.3 : 0.2
                            ))
                    )
                    .transition(.opacity.combined(
                        with: .move(edge: .bottom))
                    )
            }
        }
    }

    private var privacyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
            Text("All data stored privately on your device")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }

    private var biometricIcon: String {
        switch authService.biometricType {
        case "Face ID":  return "faceid"
        case "Touch ID": return "touchid"
        default:         return "lock.open.fill"
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

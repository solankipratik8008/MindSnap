//
//  AuthService.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// AuthService.swift
// MindSnap — CRASH FIXED VERSION
//
// WHAT CHANGED:
// Fixed crash when Face ID is enabled during onboarding.
// lockApp() now resets LAContext before locking to prevent
// stale context crashes after onboarding completes.
// ============================================================

import LocalAuthentication
import SwiftUI

@Observable
final class AuthService {

    // --------------------------------------------------------
    // MARK: - Properties
    // --------------------------------------------------------
    var isAuthenticated: Bool = false
    var isLocked: Bool = false
    var authError: String? = nil
    var isBiometricAvailable: Bool = false
    var biometricType: String = "Biometrics"

    private var context = LAContext()

    // --------------------------------------------------------
    // MARK: - Initializer
    // --------------------------------------------------------
    init() {
        checkBiometricAvailability()
    }

    // --------------------------------------------------------
    // MARK: - Public Methods
    // --------------------------------------------------------

    // --------------------------------------------------------
    // authenticate()
    //
    // Triggers Face ID / Touch ID prompt.
    // Success → isAuthenticated = true
    // Failure → authError with message
    // --------------------------------------------------------
    func authenticate() async {
        // Always create fresh context for each attempt
        context = LAContext()

        await MainActor.run {
            authError = nil
        }

        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            await authenticateWithPasscode()
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock MindSnap to access your journal"
            )

            await MainActor.run {
                if success {
                    // ---- SUCCESS HAPTIC ----
                    let unlockHaptic = UINotificationFeedbackGenerator()
                    unlockHaptic.notificationOccurred(.success)

                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAuthenticated = true
                        isLocked = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                // ---- ERROR HAPTIC ----
                let errorHaptic = UINotificationFeedbackGenerator()
                errorHaptic.notificationOccurred(.error)
                authError = handleAuthError(error)
            }
        }
    }

    
    // --------------------------------------------------------
    // authenticateForProtectedEntry()
    //
    // Used for opening one locked journal entry.
    // This does NOT change app lock state.
    // It returns true/false so HomeView can decide whether to open.
    // --------------------------------------------------------
    func authenticateForProtectedEntry(
        reason: String = "Unlock this private journal entry"
    ) async -> Bool {
        context = LAContext()

        await MainActor.run {
            authError = nil
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            await MainActor.run {
                if success {
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                }
            }

            return success
        } catch {
            await MainActor.run {
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.error)
                authError = handleAuthError(error)
            }

            return false
        }
    }
    // --------------------------------------------------------
    // lockApp()
    //
    // CRASH FIX: Resets LAContext before locking.
    // Prevents stale context issues after onboarding.
    // --------------------------------------------------------
    func lockApp() {
        let isFaceIDEnabled = UserDefaults.standard.bool(
            forKey: "isFaceIDEnabled"
        )
        guard isFaceIDEnabled else { return }

        // --------------------------------------------------------
        // CRASH FIX: Reset LAContext before locking
        //
        // Creating a fresh LAContext ensures the next
        // authentication attempt starts clean.
        // Stale contexts from onboarding caused crashes
        // because they were in an invalid state.
        // --------------------------------------------------------
        context = LAContext()

        withAnimation(.easeInOut(duration: 0.2)) {
            isAuthenticated = false
            isLocked = true
        }
    }

    // --------------------------------------------------------
    // unlockWithoutBiometrics()
    //
    // Bypasses biometric auth.
    // Used when Face ID is disabled OR right after onboarding.
    // --------------------------------------------------------
    func unlockWithoutBiometrics() {
        // Light haptic — subtle confirmation
        let lightHaptic = UIImpactFeedbackGenerator(style: .light)
        lightHaptic.impactOccurred()

        withAnimation {
            isAuthenticated = true
            isLocked = false
        }
    }

    // --------------------------------------------------------
    // checkBiometricAvailability()
    // --------------------------------------------------------
    func checkBiometricAvailability() {
        var error: NSError?
        let available = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        isBiometricAvailable = available
        if available {
            switch context.biometryType {
            case .faceID:   biometricType = "Face ID"
            case .touchID:  biometricType = "Touch ID"
            case .opticID:  biometricType = "Optic ID"
            default:        biometricType = "Biometrics"
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Private Helpers
    // --------------------------------------------------------

    private func authenticateWithPasscode() async {
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock MindSnap to access your journal"
            )
            await MainActor.run {
                if success {
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                    withAnimation {
                        isAuthenticated = true
                        isLocked = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                authError = handleAuthError(error)
            }
        }
    }

    private func handleAuthError(_ error: Error) -> String {
        guard let laError = error as? LAError else {
            return "Authentication failed. Please try again."
        }
        switch laError.code {
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancel:
            return "Authentication cancelled."
        case .userFallback:
            return "Please use your device passcode."
        case .biometryNotAvailable:
            return "\(biometricType) is not available on this device."
        case .biometryNotEnrolled:
            return "\(biometricType) is not set up. Please enable it in Settings."
        case .biometryLockout:
            return "\(biometricType) is locked. Please use your passcode."
        default:
            return "Authentication failed. Please try again."
        }
    }
}

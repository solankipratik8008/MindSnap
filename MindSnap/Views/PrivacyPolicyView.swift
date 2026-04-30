//
//  PrivacyPolicyView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// PrivacyPolicyView.swift
// MindSnap — Premium Monochrome In-App Privacy Policy
//
// SAFE UI UPDATE:
// 1. Keeps privacy policy text
// 2. Keeps GitHub Pages privacy URL
// 3. Keeps email contact link
// 4. Keeps all App Review friendly explanations
// 5. Updates UI to professional black/white theme
// 6. Keeps red/green/orange only where meaning is important
// ============================================================

import SwiftUI

struct PrivacyPolicyView: View {

    private let privacyPolicyURL = "https://solankipratik8008.github.io/mindsnap-privacy"

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSafari = false

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
        : Color.black.opacity(0.06)
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                headerSection

                bigPromiseSection

                dataCollectionSection

                dataStorageSection

                thirdPartySection

                yourRightsSection

                contactSection

                fullPolicyButton

                Text("Last updated: April 26, 2026")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(appBackground)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
        .tint(primaryText)
    }

    // --------------------------------------------------------
    // MARK: - Header
    // --------------------------------------------------------
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(softBackground)
                    .frame(width: 104, height: 104)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )

                Circle()
                    .fill(primaryButtonBackground)
                    .frame(width: 76, height: 76)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(primaryButtonText)
            }
            .shadow(
                color: shadowColor,
                radius: 14,
                x: 0,
                y: 7
            )

            VStack(spacing: 8) {
                Text("Your Privacy Matters")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)

                Text("MindSnap was built with privacy as the foundation, not an afterthought.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // --------------------------------------------------------
    // MARK: - Big Promise
    // --------------------------------------------------------
    private var bigPromiseSection: some View {
        VStack(spacing: 12) {
            promiseBullet(
                icon: "iphone",
                color: primaryText,
                title: "Private by Design",
                description: "Your journal, goals, mood results, and preferences are stored on your device and, if enabled, in your private iCloud account."
            )

            promiseBullet(
                icon: "person.slash.fill",
                color: primaryText,
                title: "No Account Required",
                description: "MindSnap works without creating an account. We don't know who you are and we don't need to."
            )

            promiseBullet(
                icon: "wifi.slash",
                color: .orange,
                title: "Works Offline",
                description: "Core journaling and goals work offline. Internet is only needed for optional iCloud sync and Apple services controlled by iOS."
            )
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 20))
    }

    // --------------------------------------------------------
    // MARK: - What We Collect
    // --------------------------------------------------------
    private var dataCollectionSection: some View {
        policySectionCard(
            title: "What We Collect",
            icon: "list.clipboard.fill",
            iconColor: primaryText
        ) {
            VStack(alignment: .leading, spacing: 12) {

                Text("We DO NOT collect for ourselves:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 8) {
                    notCollectedRow("Your journal entries")
                    notCollectedRow("Your name or email")
                    notCollectedRow("Your location")
                    notCollectedRow("Device identifiers")
                    notCollectedRow("Usage analytics")
                    notCollectedRow("Crash reports sent to us")
                    notCollectedRow("Health data for advertising or sale")
                }

                Divider()
                    .background(borderColor)
                    .padding(.vertical, 4)

                Text("Stored on your device, and optionally in your private iCloud:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 8) {
                    collectedRow(
                        "Journal entries you write",
                        note: "Device storage; private iCloud sync if available"
                    )

                    collectedRow(
                        "Mood analysis results",
                        note: "Computed on-device"
                    )

                    collectedRow(
                        "Goals, reminders, and progress",
                        note: "Used to run app features"
                    )

                    collectedRow(
                        "App preferences",
                        note: "Stored in UserDefaults"
                    )

                    collectedRow(
                        "Selected Apple Health totals",
                        note: "Only after you enable Health sync"
                    )
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - How Data Is Stored
    // --------------------------------------------------------
    private var dataStorageSection: some View {
        policySectionCard(
            title: "How Data Is Stored",
            icon: "internaldrive.fill",
            iconColor: primaryText
        ) {
            VStack(alignment: .leading, spacing: 10) {
                policyText("App data is stored in a local database on your iPhone.")

                policyText("Your data is protected by iOS built-in encryption and your device passcode or Face ID.")

                policyText("If iCloud sync is available and enabled by iOS, your journal and goal data may sync to your private iCloud account through Apple's CloudKit service. We do not operate a server that can read it.")

                policyText("Deleting the app removes local app data from your device. Data already synced with iCloud may remain in iCloud until removed according to Apple's iCloud settings and sync behavior.")

                policyText("iCloud backup follows your own iOS settings.")
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Third Party
    // --------------------------------------------------------
    private var thirdPartySection: some View {
        policySectionCard(
            title: "Third Party Services",
            icon: "building.2.fill",
            iconColor: primaryText
        ) {
            VStack(alignment: .leading, spacing: 10) {
                policyText("MindSnap uses zero third-party analytics, advertising, or tracking services.")

                policyText("Mood analysis happens entirely on your device. Your journal text is never sent anywhere.")

                policyText("Apple services may be used for optional features, including iCloud sync, Apple Health permission prompts, local notifications, speech recognition, Face ID / Touch ID, and App Store purchases if offered.")

                policyText("Apple Health sync is optional. MindSnap reads selected daily totals such as steps, distance, exercise minutes, and water only after you grant permission. MindSnap does not write Health data.")

                HStack(spacing: 7) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.caption)

                    Text("No ads, no third-party tracking, no data sale")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green.opacity(colorScheme == .dark ? 0.13 : 0.075))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.green.opacity(0.16), lineWidth: 1)
                        )
                )
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Your Rights
    // --------------------------------------------------------
    private var yourRightsSection: some View {
        policySectionCard(
            title: "Your Rights",
            icon: "hand.raised.fill",
            iconColor: primaryText
        ) {
            VStack(alignment: .leading, spacing: 10) {
                policyText("You stay in control of your data and permissions:")

                rightsRow(
                    icon: "trash.fill",
                    text: "Delete journal entries via Settings → Clear All Journal Data, or remove all MindSnap data via Settings → Delete Account & All Data"
                )

                rightsRow(
                    icon: "heart.text.square.fill",
                    text: "Turn Apple Health sync on or off anytime in MindSnap Settings and iOS Settings"
                )

                rightsRow(
                    icon: "arrow.down.circle.fill",
                    text: "Export your data by copying entries manually"
                )

                rightsRow(
                    icon: "lock.fill",
                    text: "Protect your journal with Face ID / Touch ID"
                )

                rightsRow(
                    icon: "iphone.slash",
                    text: "Delete the app to remove local app data from this device"
                )
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Contact
    // --------------------------------------------------------
    private var contactSection: some View {
        policySectionCard(
            title: "Contact",
            icon: "envelope.fill",
            iconColor: primaryText
        ) {
            VStack(alignment: .leading, spacing: 10) {
                policyText("If you have any questions about this privacy policy or MindSnap, please contact:")

                Button {
                    if let url = URL(string: "mailto:mindsnap.772@gmail.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 9) {
                        ZStack {
                            Circle()
                                .fill(softBackground)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(borderColor, lineWidth: 1)
                                )

                            Image(systemName: "envelope.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(primaryText)
                        }

                        Text("mindsnap.772@gmail.com")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)
                            .underline()

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(softBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Full Policy Button
    // --------------------------------------------------------
    private var fullPolicyButton: some View {
        Button {
            if let url = URL(string: privacyPolicyURL) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 17, weight: .semibold))

                Text("View Full Privacy Policy")
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundStyle(primaryButtonText)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(primaryButtonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.16)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: shadowColor,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Reusable Components
    // --------------------------------------------------------
    private func premiumCard(cornerRadius: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: 12,
                x: 0,
                y: 6
            )
    }

    private func policySectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(primaryButtonBackground)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(primaryButtonText)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Spacer()
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(premiumCard(cornerRadius: 20))
    }

    private func promiseBullet(
        icon: String,
        color: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        color == primaryText
                        ? softBackground
                        : color.opacity(colorScheme == .dark ? 0.16 : 0.10)
                    )
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(
                                color == primaryText
                                ? borderColor
                                : color.opacity(0.16),
                                lineWidth: 1
                            )
                    )

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)

                Text(description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func notCollectedRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.78))
                .font(.caption)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func collectedRow(_ text: String, note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(note)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func rightsRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(primaryText)
                .font(.caption)
                .frame(width: 17)

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func policyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(secondaryText)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PrivacyPolicyView()
    }
    .preferredColorScheme(.dark)
}

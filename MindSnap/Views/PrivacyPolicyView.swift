//
//  PrivacyPolicyView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// PrivacyPolicyView.swift
// MindSnap — In-app privacy policy screen
//
// WHAT THIS FILE DOES:
// Shows a beautiful in-app privacy policy that:
//   1. Reassures users their data is private
//   2. Explains exactly what data is/isn't collected
//   3. Links to the full web privacy policy
//
// WHY THIS MATTERS:
//   - Apple REQUIRES a privacy policy for App Store
//   - Users are more likely to trust and keep your app
    //   - Clear privacy language helps App Review and user trust
//   - Shows professionalism to recruiters
// ============================================================

import SwiftUI

struct PrivacyPolicyView: View {

    // --------------------------------------------------------
    // privacyPolicyURL — Your GitHub Pages URL
    //
    // REPLACE THIS with your actual GitHub Pages URL
    // after you set it up in Part B.
    // Format: https://yourgithubname.github.io/mindsnap-privacy
    // --------------------------------------------------------
    // Find this line and update it
    private let privacyPolicyURL = "https://solankipratik8008.github.io/mindsnap-privacy"

    // --------------------------------------------------------
    // @State private var showingSafari
    //
    // Controls whether the full web privacy policy
    // opens in Safari
    // --------------------------------------------------------
    @State private var showingSafari = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ---- Header ----
                headerSection

                // ---- The Big Promise ----
                bigPromiseSection

                // ---- What We Collect ----
                dataCollectionSection

                // ---- How Data Is Stored ----
                dataStorageSection

                // ---- Third Party ----
                thirdPartySection

                // ---- Your Rights ----
                yourRightsSection

                // ---- Contact ----
                contactSection

                // ---- Full Policy Link ----
                fullPolicyButton

                // ---- Last Updated ----
                Text("Last updated: April 26, 2026")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }

    // --------------------------------------------------------
    // MARK: - Sections
    // --------------------------------------------------------

    // --------------------------------------------------------
    // headerSection
    //
    // Big shield icon with "Your Privacy Matters" headline
    // Sets the tone immediately — users feel safe
    // --------------------------------------------------------
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Shield icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text("Your Privacy Matters")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("MindSnap was built with privacy as the foundation, not an afterthought.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // --------------------------------------------------------
    // bigPromiseSection
    //
    // The most important section — the core privacy promise
    // in a visually prominent green card
    // --------------------------------------------------------
    private var bigPromiseSection: some View {
        VStack(spacing: 12) {
            // Three promise bullets
            promiseBullet(
                icon: "iphone",
                color: .blue,
                    title: "Private by Design",
                    description: "Your journal, goals, mood results, and preferences are stored on your device and, if enabled, in your private iCloud account."
            )
            promiseBullet(
                icon: "person.slash.fill",
                color: .purple,
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }

    // --------------------------------------------------------
    // dataCollectionSection
    //
    // Clear breakdown of exactly what IS and ISN'T collected
    // Side by side comparison builds massive trust
    // --------------------------------------------------------
    private var dataCollectionSection: some View {
        policySectionCard(
            title: "What We Collect",
            icon: "list.clipboard.fill",
            iconColor: .blue
        ) {
            AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    // NOT collected list
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
                        .padding(.vertical, 4)

                    // IS stored locally
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
            )
        }
    }

    // --------------------------------------------------------
    // dataStorageSection
    // --------------------------------------------------------
    private var dataStorageSection: some View {
        policySectionCard(
            title: "How Data Is Stored",
            icon: "internaldrive.fill",
            iconColor: .purple
        ) {
            AnyView(
                VStack(alignment: .leading, spacing: 10) {

                    policyText("App data is stored in a local database on your iPhone.")
                    policyText("Your data is protected by iOS built-in encryption and your device passcode or Face ID.")
                    policyText("If iCloud sync is available and enabled by iOS, your journal and goal data may sync to your private iCloud account through Apple's CloudKit service. We do not operate a server that can read it.")
                    policyText("Deleting the app removes local app data from your device. Data already synced with iCloud may remain in iCloud until removed according to Apple's iCloud settings and sync behavior.")
                    policyText("iCloud backup follows your own iOS settings.")
                }
            )
        }
    }

    // --------------------------------------------------------
    // thirdPartySection
    // --------------------------------------------------------
    private var thirdPartySection: some View {
        policySectionCard(
            title: "Third Party Services",
            icon: "building.2.fill",
            iconColor: .orange
        ) {
            AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    policyText("MindSnap uses zero third-party analytics, advertising, or tracking services.")
                    policyText("Mood analysis happens entirely on your device. Your journal text is never sent anywhere.")
                    policyText("Apple services may be used for optional features, including iCloud sync, Apple Health permission prompts, local notifications, speech recognition, Face ID / Touch ID, and App Store purchases if offered.")
                    policyText("Apple Health sync is optional. MindSnap reads selected daily totals such as steps, distance, exercise minutes, and water only after you grant permission. MindSnap does not write Health data.")
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("No ads, no third-party tracking, no data sale")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.08))
                    )
                }
            )
        }
    }

    // --------------------------------------------------------
    // yourRightsSection
    // --------------------------------------------------------
    private var yourRightsSection: some View {
        policySectionCard(
            title: "Your Rights",
            icon: "hand.raised.fill",
            iconColor: .teal
        ) {
            AnyView(
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
            )
        }
    }

    // --------------------------------------------------------
    // contactSection
    // --------------------------------------------------------
    private var contactSection: some View {
        policySectionCard(
            title: "Contact",
            icon: "envelope.fill",
            iconColor: .blue
        ) {
            AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    policyText("If you have any questions about this privacy policy or MindSnap, please contact:")

                    // REPLACE with your actual email
                    Button {

                        if let url = URL(string: "mailto:mindsnap.772@gmail.com")  {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)

                            Text("mindsnap.772@gmail.com")
                                .foregroundStyle(.blue)
                                .underline()
                        }
                        .font(.subheadline)
                    }
                }
            )
        }
    }

    // --------------------------------------------------------
    // fullPolicyButton
    //
    // Links to the full web privacy policy
    // Required for App Store submission
    // --------------------------------------------------------
    private var fullPolicyButton: some View {
        Button {
            if let url = URL(string: privacyPolicyURL) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "safari.fill")
                Text("View Full Privacy Policy")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue)
            )
        }
    }

    // --------------------------------------------------------
    // MARK: - Reusable Components
    // --------------------------------------------------------

    // --------------------------------------------------------
    // policySectionCard — Reusable section container
    // --------------------------------------------------------
    private func policySectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.headline)
            }
            // Section content
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }

    // ---- Promise bullet point ----
    private func promiseBullet(
        icon: String,
        color: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // ---- Not collected row (red X) ----
    private func notCollectedRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.7))
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    // ---- Collected row (green checkmark) ----
    private func collectedRow(_ text: String, note: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(text)
                    .font(.subheadline)
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // ---- Rights row ----
    private func rightsRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.teal)
                .font(.caption)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // ---- Plain policy text ----
    private func policyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}

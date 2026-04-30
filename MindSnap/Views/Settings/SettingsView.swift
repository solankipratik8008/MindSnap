//
//  SettingsView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// SettingsView.swift
// MindSnap — Premium Monochrome Settings
//
// SAFE UI UPDATE:
// 1. Keeps all existing settings functionality
// 2. Keeps Face ID, Health, reminders, widgets, data deletion
// 3. Keeps crisis resources section for App Review safety
// 4. Keeps privacy policy navigation
// 5. Updates UI to professional black/white theme
// 6. Supports light and dark mode
// ============================================================

import SwiftUI
import SwiftData
import UserNotifications
import WidgetKit

// --------------------------------------------------------
// CrisisResource — Data model for a crisis helpline
// --------------------------------------------------------
struct CrisisResource {
    let country: String
    let flag: String
    let name: String
    let phone: String
    let description: String
}

enum AppColorScheme: String, CaseIterable {
    case light  = "Light"
    case dark   = "Dark"
    case system = "System"

    var colorScheme: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    var icon: String {
        switch self {
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var iconColor: Color {
        switch self {
        case .light:  return .orange
        case .dark:   return .indigo
        case .system: return .gray
        }
    }
}

struct SettingsView: View {

    // ---- Persistent preferences ----
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false
    @AppStorage("showMoodOnHome") private var showMoodOnHome = true
    @AppStorage("isDailyReminderEnabled") private var isDailyReminderEnabled = false
    @AppStorage("isHealthSyncEnabled") private var isHealthSyncEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("userName") private var userName = ""
    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme.system.rawValue

    @AppStorage(
        "widgetGoalIDs",
        store: UserDefaults(suiteName: "group.com.pratik.MindSnap")
    )
    private var widgetGoalIDsRaw = ""

    @AppStorage(
        "widgetIncludeJournalShortcut",
        store: UserDefaults(suiteName: "group.com.pratik.MindSnap")
    )
    private var widgetIncludeJournalShortcut = true

    // ---- Services ----
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Goal.createdAt, order: .reverse)
    private var settingsGoals: [Goal]

    @State private var notificationService = NotificationService()
    @State private var authService = AuthService()
    @State private var healthKitService = HealthKitService()

    // ---- UI State ----
    @State private var showingClearDataAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingDataClearedConfirmation = false
    @State private var showingAccountDeletedConfirmation = false
    @State private var showingNameEditor = false
    @State private var showingNotificationDeniedAlert = false
    @State private var showingHealthPermissionAlert = false
    @State private var tempName = ""

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"]
            as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"]
            as? String ?? "1"
    }

    private var selectedScheme: AppColorScheme {
        AppColorScheme(rawValue: appColorScheme) ?? .system
    }

    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    private var cardFill: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var rowFill: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.07)
        : Color.black.opacity(0.045)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.62)
        : Color.black.opacity(0.52)
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

    private var destructiveFill: Color {
        Color.red.opacity(colorScheme == .dark ? 0.18 : 0.10)
    }

    private func settingsIcon(
        systemName: String,
        fill: Color? = nil,
        foreground: Color? = nil
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(fill ?? primaryButtonBackground)
                .frame(width: 30, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(borderColor, lineWidth: fill == nil ? 1 : 0)
                )

            Image(systemName: systemName)
                .foregroundStyle(foreground ?? primaryButtonText)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        List {
            profileSection
            widgetGoalsSection
            securitySection
            appearanceSection
            notificationsSection
            healthSection
            dataSection
            supportSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(appBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .tint(primaryText)

        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Delete Everything", role: .destructive) {
                clearJournalData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete ALL journal entries.")
        }

        .alert("Delete Account & All Data?", isPresented: $showingDeleteAccountAlert) {
            Button("Delete Everything", role: .destructive) {
                deleteAccountAndAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("MindSnap does not create a separate server account, but this will permanently delete all MindSnap data on this device, including journal entries, goals, progress, reminders, points, preferences, and locally stored sync records. If iCloud sync is enabled, deletions are saved so they can sync through CloudKit.")
        }

        .alert("Data Cleared", isPresented: $showingDataClearedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All journal entries have been deleted.")
        }

        .alert("MindSnap Data Deleted", isPresented: $showingAccountDeletedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All MindSnap data and local reminders have been deleted. Health permissions are controlled by iOS Settings and can be changed there anytime.")
        }

        .alert("Notifications Disabled", isPresented: $showingNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                isDailyReminderEnabled = false
            }
        } message: {
            Text("Please enable notifications for MindSnap in iOS Settings.")
        }

        .alert("Apple Health Unavailable", isPresented: $showingHealthPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                isHealthSyncEnabled = false
            }
        } message: {
            Text("MindSnap needs permission to read activity data from Apple Health. You can change this anytime in iOS Settings.")
        }

        .sheet(isPresented: $showingNameEditor) {
            nameEditorSheet
        }

        .onAppear {
            Task {
                await notificationService.checkAuthorizationStatus()
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Profile
    // --------------------------------------------------------
    private var profileSection: some View {
        Section {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(primaryButtonBackground)
                        .frame(width: 52, height: 52)

                    if userName.isEmpty {
                        Image(systemName: "person.fill")
                            .foregroundStyle(primaryButtonText)
                            .font(.title3.weight(.semibold))
                    } else {
                        Text(String(userName.prefix(1)).capitalized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryButtonText)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(userName.isEmpty ? "Add Your Name" : userName)
                        .font(.headline)
                        .foregroundStyle(userName.isEmpty ? secondaryText : primaryText)

                    Text("Tap to edit your display name")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tertiaryText)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                tempName = userName
                showingNameEditor = true
            }
            .listRowBackground(cardFill)
        } header: {
            Text("Profile")
        }
    }

    // --------------------------------------------------------
    // MARK: - Widget
    // --------------------------------------------------------
    private var widgetGoalsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { widgetIncludeJournalShortcut },
                set: { newValue in
                    widgetIncludeJournalShortcut = newValue
                    WidgetCenter.shared.reloadAllTimelines()
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Journal Shortcut")
                            .foregroundStyle(primaryText)

                        Text("Show a private Write Journal action in widgets")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "square.and.pencil")
                }
            }
            .tint(primaryText)
            .listRowBackground(cardFill)

            if activeWidgetCandidateGoals.isEmpty {
                Text("Create an active goal to customize your widgets.")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                    .listRowBackground(cardFill)
            } else {
                ForEach(activeWidgetCandidateGoals.prefix(8), id: \.id) { goal in
                    Button {
                        toggleWidgetGoal(goal)
                    } label: {
                        HStack(spacing: 12) {
                            Text(goal.emoji)
                                .font(.title3)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.name)
                                    .foregroundStyle(primaryText)
                                    .lineLimit(1)

                                Text("\(goal.category.rawValue) • \(goal.goalType.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if selectedWidgetGoalIDs.contains(goal.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(primaryText)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(tertiaryText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        !selectedWidgetGoalIDs.contains(goal.id) &&
                        selectedWidgetGoalIDs.count >= 4
                    )
                    .listRowBackground(cardFill)
                }
            }
        } header: {
            Text("Widget")
        } footer: {
            Text("Choose up to 4 active goals for widgets. You can also include a private Write Journal shortcut. Widgets never show journal text or mood details.")
        }
    }

    // --------------------------------------------------------
    // MARK: - Security
    // --------------------------------------------------------
    private var securitySection: some View {
        Section {
            Toggle(isOn: $isFaceIDEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(authService.biometricType)")
                            .foregroundStyle(primaryText)

                        Text("Lock app on background")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(
                        systemName: authService.biometricType == "Touch ID"
                        ? "touchid"
                        : "faceid"
                    )
                }
            }
            .tint(primaryText)
            .listRowBackground(cardFill)
        } header: {
            Text("Security")
        } footer: {
            Text("Requires \(authService.biometricType) each time you open the app.")
        }
    }

    // --------------------------------------------------------
    // MARK: - Appearance
    // --------------------------------------------------------
    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $showMoodOnHome) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Mood on Home")
                            .foregroundStyle(primaryText)

                        Text("Display today's mood in header")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "face.smiling")
                }
            }
            .tint(primaryText)
            .listRowBackground(cardFill)

            VStack(alignment: .leading, spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                            .foregroundStyle(primaryText)

                        Text("Choose how MindSnap looks")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "paintpalette.fill")
                }

                Picker("Appearance", selection: $appColorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.rawValue) { scheme in
                        Label(scheme.rawValue, systemImage: scheme.icon)
                            .tag(scheme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .tint(primaryText)

                HStack(spacing: 6) {
                    Image(systemName: selectedScheme.icon)
                        .foregroundStyle(selectedScheme.iconColor)
                        .font(.caption)

                    Text(appearanceDescription)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(cardFill)

        } header: {
            Text("Appearance")
        } footer: {
            Text("'System' automatically follows your iPhone's appearance setting.")
        }
    }

    // --------------------------------------------------------
    // MARK: - Notifications
    // --------------------------------------------------------
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isDailyReminderEnabled },
                set: { handleReminderToggle($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .foregroundStyle(primaryText)

                        Text("Remind me to journal each day")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "bell.fill")
                }
            }
            .tint(primaryText)
            .listRowBackground(cardFill)

            if isDailyReminderEnabled && !notificationService.isAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)

                    Text("Notification permission required. Tap to open Settings.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .listRowBackground(cardFill)
            }

            if isDailyReminderEnabled {
                HStack {
                    Label {
                        Text("Reminder Time")
                            .foregroundStyle(primaryText)
                    } icon: {
                        settingsIcon(systemName: "clock.fill")
                    }

                    Spacer()

                    Picker("Hour", selection: Binding(
                        get: { reminderHour },
                        set: { newHour in
                            reminderHour = newHour

                            Task {
                                await notificationService
                                    .scheduleDailyReminder(hour: newHour)
                            }
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(hourLabel(for: hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(primaryText)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .listRowBackground(cardFill)
            }
        } header: {
            Text("Notifications")
        } footer: {
            if isDailyReminderEnabled && notificationService.isAuthorized {
                Text("Daily reminder at \(hourLabel(for: reminderHour)).")
            } else {
                Text("Get a daily nudge to keep your journaling streak alive.")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDailyReminderEnabled)
    }

    // --------------------------------------------------------
    // MARK: - Health
    // --------------------------------------------------------
    private var healthSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isHealthSyncEnabled },
                set: { handleHealthSyncToggle($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health Sync")
                            .foregroundStyle(primaryText)

                        Text("Auto-fill compatible progress goals")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "heart.fill")
                }
            }
            .tint(primaryText)
            .listRowBackground(cardFill)

            VStack(alignment: .leading, spacing: 8) {
                Label("Health Data Privacy", systemImage: "lock.shield.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)

                Text("MindSnap reads your Health data only to update your goal progress.")
                Text("MindSnap does not sell or share Health data.")
                Text("Health access is optional.")
                Text("You can disable Health permissions anytime in iPhone Settings.")
                Text("If Health access is off, manual progress entry still works.")
            }
            .font(.caption)
            .foregroundStyle(secondaryText)
            .padding(.vertical, 6)
            .listRowBackground(cardFill)
        } header: {
            Text("Health")
        } footer: {
            Text("MindSnap reads selected Apple Health activity totals, such as steps, distance, exercise minutes, and water. It never writes Health data.")
        }
    }

    // --------------------------------------------------------
    // MARK: - Data
    // --------------------------------------------------------
    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showingClearDataAlert = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear All Journal Data")
                            .foregroundStyle(.red)

                        Text("Permanently delete all entries")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(
                        systemName: "trash.fill",
                        fill: destructiveFill,
                        foreground: .red
                    )
                }
            }
            .listRowBackground(cardFill)

            Button(role: .destructive) {
                showingDeleteAccountAlert = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account & All Data")
                            .foregroundStyle(.red)

                        Text("Delete journals, goals, progress, reminders, points, and preferences")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(
                        systemName: "person.crop.circle.badge.xmark",
                        fill: destructiveFill,
                        foreground: .red
                    )
                }
            }
            .listRowBackground(cardFill)
        } header: {
            Text("Data")
        } footer: {
            Text("MindSnap does not create a separate server account. Deleting all data removes MindSnap records from this device; if iCloud sync is enabled, saved deletions can sync through Apple's CloudKit service.")
        }
    }

    // --------------------------------------------------------
    // MARK: - Mental Health Support
    // --------------------------------------------------------
    private var supportSection: some View {
        Section {
            Button {
                if let url = URL(string: "https://findahelpline.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Find a Helpline")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)

                        Text("findahelpline.com")
                            .font(.caption)
                            .foregroundStyle(secondaryText)

                        Text("Crisis support in 200+ countries")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "globe")
                }
            }
            .listRowBackground(cardFill)

            ForEach(regionalResources, id: \.country) { resource in
                Button {
                    if let url = URL(string: "tel:\(resource.phone.filter { $0.isNumber })") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(resource.flag)

                                Text(resource.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(primaryText)
                            }

                            Text(resource.phone)
                                .font(.caption)
                                .foregroundStyle(secondaryText)

                            Text(resource.description)
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                        }
                    } icon: {
                        settingsIcon(systemName: "phone.fill")
                    }
                }
                .listRowBackground(cardFill)
            }

            Button {
                if let url = URL(string: "https://www.crisistextline.org") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Crisis Text Line")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)

                        Text("crisistextline.org")
                            .font(.caption)
                            .foregroundStyle(secondaryText)

                        Text("Text-based support — USA, Canada, UK, Ireland")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "message.fill")
                }
            }
            .listRowBackground(cardFill)

        } header: {
            Text("Mental Health Support")
        } footer: {
            Text("MindSnap is a journaling tool, not a substitute for professional mental health care. If you are in crisis please reach out to the resources above.")
                .font(.caption)
        }
    }

    private var regionalResources: [CrisisResource] {[
        CrisisResource(
            country: "Canada",
            flag: "🇨🇦",
            name: "Crisis Services Canada",
            phone: "1-833-456-4566",
            description: "Free · 24/7 · Call or text"
        ),
        CrisisResource(
            country: "USA",
            flag: "🇺🇸",
            name: "988 Suicide & Crisis Lifeline",
            phone: "988",
            description: "Free · 24/7 · Call or text 988"
        ),
        CrisisResource(
            country: "India",
            flag: "🇮🇳",
            name: "iCall",
            phone: "9152987821",
            description: "Free · Mon-Sat 8am-10pm IST"
        ),
        CrisisResource(
            country: "UK",
            flag: "🇬🇧",
            name: "Samaritans",
            phone: "116 123",
            description: "Free · 24/7 · Call anytime"
        ),
        CrisisResource(
            country: "Australia",
            flag: "🇦🇺",
            name: "Lifeline Australia",
            phone: "13 11 14",
            description: "Free · 24/7 · Call or text"
        )
    ]}

    // --------------------------------------------------------
    // MARK: - About
    // --------------------------------------------------------
    private var aboutSection: some View {
        Section {
            HStack {
                Label {
                    Text("Version")
                        .foregroundStyle(primaryText)
                } icon: {
                    settingsIcon(systemName: "info.circle.fill")
                }

                Spacer()

                Text("\(appVersion) (\(buildNumber))")
                    .foregroundStyle(secondaryText)
            }
            .listRowBackground(cardFill)

            NavigationLink(destination: PrivacyPolicyView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy Policy")
                            .foregroundStyle(primaryText)

                        Text("Your data & privacy")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                    }
                } icon: {
                    settingsIcon(systemName: "hand.raised.fill")
                }
            }
            .foregroundStyle(primaryText)
            .listRowBackground(cardFill)

            HStack {
                Label {
                    Text("Made with")
                        .foregroundStyle(primaryText)
                } icon: {
                    settingsIcon(systemName: "heart.fill")
                }

                Spacer()

                Text("Pratik's ❤️")
                    .foregroundStyle(secondaryText)
                    .font(.subheadline)
            }
            .listRowBackground(cardFill)

        } header: {
            Text("About")
        }
    }

    // --------------------------------------------------------
    // MARK: - Name Editor
    // --------------------------------------------------------
    private var nameEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $tempName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("Only stored on your device.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(appBackground)
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingNameEditor = false
                    }
                    .foregroundStyle(secondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userName = tempName
                        showingNameEditor = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    private var appearanceDescription: String {
        switch selectedScheme {
        case .light:
            return "App always uses light mode"
        case .dark:
            return "App always uses dark mode"
        case .system:
            return "Follows your iPhone's appearance"
        }
    }

    private var activeWidgetCandidateGoals: [Goal] {
        settingsGoals.filter { $0.isActive }
    }

    private var selectedWidgetGoalIDs: [UUID] {
        widgetGoalIDsRaw
            .split(separator: ",")
            .compactMap { UUID(uuidString: String($0)) }
    }

    // --------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------
    private func handleReminderToggle(_ newValue: Bool) {
        if newValue {
            Task {
                await notificationService.checkAuthorizationStatus()

                if notificationService.isAuthorized {
                    isDailyReminderEnabled = true

                    await notificationService
                        .scheduleDailyReminder(hour: reminderHour)
                } else {
                    let granted = await notificationService
                        .requestPermission()

                    if granted {
                        await MainActor.run {
                            isDailyReminderEnabled = true
                        }

                        await notificationService
                            .scheduleDailyReminder(hour: reminderHour)
                    } else {
                        await MainActor.run {
                            isDailyReminderEnabled = false
                            showingNotificationDeniedAlert = true
                        }
                    }
                }
            }
        } else {
            isDailyReminderEnabled = false
            notificationService.cancelDailyReminder()
        }
    }

    private func handleHealthSyncToggle(_ newValue: Bool) {
        if newValue {
            guard healthKitService.isAvailable else {
                isHealthSyncEnabled = false
                showingHealthPermissionAlert = true
                return
            }

            Task {
                let granted = await healthKitService.requestAuthorization()

                await MainActor.run {
                    isHealthSyncEnabled = granted
                    showingHealthPermissionAlert = !granted
                }
            }
        } else {
            isHealthSyncEnabled = false
        }
    }

    private func clearJournalData() {
        do {
            let allEntries = try modelContext.fetch(
                FetchDescriptor<JournalEntry>()
            )

            for entry in allEntries {
                modelContext.delete(entry)
            }

            try modelContext.save()
            showingDataClearedConfirmation = true
        } catch {
            print("Failed to clear data: \(error)")
        }
    }

    private func deleteAccountAndAllData() {
        do {
            let allEntries = try modelContext.fetch(
                FetchDescriptor<JournalEntry>()
            )

            for entry in allEntries {
                modelContext.delete(entry)
            }

            let allGoals = try modelContext.fetch(
                FetchDescriptor<Goal>()
            )

            for goal in allGoals {
                modelContext.delete(goal)
            }

            let allCompletions = try modelContext.fetch(
                FetchDescriptor<GoalCompletion>()
            )

            for completion in allCompletions {
                modelContext.delete(completion)
            }

            try modelContext.save()

            clearMindSnapPreferences()
            clearNotifications()
            WidgetCenter.shared.reloadAllTimelines()

            showingAccountDeletedConfirmation = true
        } catch {
            print("Failed to delete account data: \(error)")
        }
    }

    private func clearMindSnapPreferences() {
        let keys = [
            "isFaceIDEnabled",
            "showMoodOnHome",
            "isDailyReminderEnabled",
            "isHealthSyncEnabled",
            "reminderHour",
            "userName",
            "appColorScheme",
            "hasCompletedOnboarding",
            "hasSeenTutorial",
            "lastActiveDate",
            "mindsnap_total_points",
            "reviewEntriesCount",
            "reviewFirstLaunchDate",
            "reviewHasRequested",
            "reviewLastRequestDate"
        ]

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        UserDefaults(suiteName: "group.com.pratik.MindSnap")?
            .removeObject(forKey: "widgetGoalIDs")

        isFaceIDEnabled = false
        showMoodOnHome = true
        isDailyReminderEnabled = false
        isHealthSyncEnabled = false
        reminderHour = 20
        userName = ""
        appColorScheme = AppColorScheme.system.rawValue

        UserPoints.reset()
    }

    private func toggleWidgetGoal(_ goal: Goal) {
        var selected = selectedWidgetGoalIDs

        if selected.contains(goal.id) {
            selected.removeAll { $0 == goal.id }
        } else {
            guard selected.count < 4 else { return }
            selected.append(goal.id)
        }

        let activeIDs = Set(activeWidgetCandidateGoals.map(\.id))

        widgetGoalIDsRaw = selected
            .filter { activeIDs.contains($0) }
            .map(\.uuidString)
            .joined(separator: ",")

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func clearNotifications() {
        notificationService.cancelDailyReminder()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        notificationService.resetBadgeCount()
    }

    private func hourLabel(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(
        for: [
            JournalEntry.self,
            Goal.self,
            GoalCompletion.self
        ],
        inMemory: true
    )
}

#Preview("Dark Mode") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(
        for: [
            JournalEntry.self,
            Goal.self,
            GoalCompletion.self
        ],
        inMemory: true
    )
    .preferredColorScheme(.dark)
}

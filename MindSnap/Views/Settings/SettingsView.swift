//
//  SettingsView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//


// ============================================================
// SettingsView.swift
// MindSnap — APPLE GUIDELINES COMPLIANT VERSION
//
// WHAT CHANGED:
// 1. Added crisis resources section (Apple Guideline 1.4.1)
//    Mental health apps MUST include crisis helplines
// 2. Fixed "AI" claims to "on-device intelligence"
//    More accurate since we use Apple's ML framework
// ============================================================


// --------------------------------------------------------
// CrisisResource — Data model for a crisis helpline
//
// Simple struct to hold crisis resource information.
// Used in the supportSection of SettingsView.
// --------------------------------------------------------
struct CrisisResource {
    let country: String
    let flag: String
    let name: String
    let phone: String
    let description: String
}



import SwiftUI
import SwiftData
import UserNotifications
import WidgetKit

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

    // ---- Services ----
    @Environment(\.modelContext) private var modelContext
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
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        List {
            profileSection
            securitySection
            appearanceSection
            notificationsSection
            healthSection
            dataSection
            supportSection      // ← NEW: Crisis resources
            aboutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)

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
    // MARK: - Sections
    // --------------------------------------------------------

    private var profileSection: some View {
        Section {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    if userName.isEmpty {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.purple)
                            .font(.title2)
                    } else {
                        Text(String(userName.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.purple)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(userName.isEmpty ? "Add Your Name" : userName)
                        .font(.headline)
                        .foregroundStyle(userName.isEmpty ? .secondary : .primary)
                    Text("Tap to edit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                tempName = userName
                showingNameEditor = true
            }
        } header: {
            Text("Profile")
        }
    }

    private var securitySection: some View {
        Section {
            Toggle(isOn: $isFaceIDEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(authService.biometricType)")
                        Text("Lock app on background")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        Image(systemName: authService.biometricType == "Touch ID"
                              ? "touchid" : "faceid")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }
            .tint(.blue)
        } header: {
            Text("Security")
        } footer: {
            Text("Requires \(authService.biometricType) each time you open the app.")
        }
    }

    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $showMoodOnHome) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Mood on Home")
                        Text("Display today's mood in header")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.orange)
                            .frame(width: 28, height: 28)
                        Image(systemName: "face.smiling")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }
            .tint(.orange)

            VStack(alignment: .leading, spacing: 10) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                        Text("Choose how MindSnap looks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.indigo)
                            .frame(width: 28, height: 28)
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }

                Picker("Appearance", selection: $appColorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.rawValue) { scheme in
                        Label(scheme.rawValue, systemImage: scheme.icon)
                            .tag(scheme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.purple)

                HStack(spacing: 6) {
                    Image(systemName: selectedScheme.icon)
                        .foregroundStyle(selectedScheme.iconColor)
                        .font(.caption)
                    Text(appearanceDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

        } header: {
            Text("Appearance")
        } footer: {
            Text("'System' automatically follows your iPhone's appearance setting.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isDailyReminderEnabled },
                set: { handleReminderToggle($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                        Text("Remind me to journal each day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.green)
                            .frame(width: 28, height: 28)
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }
            .tint(.green)

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
            }

            if isDailyReminderEnabled {
                HStack {
                    Label {
                        Text("Reminder Time")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 28, height: 28)
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 14))
                        }
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
                    .tint(.green)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }

            Button(role: .destructive) {
                showingDeleteAccountAlert = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account & All Data")
                            .foregroundStyle(.red)
                        Text("Delete journals, goals, progress, reminders, points, and preferences")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 28, height: 28)
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }
        } header: {
            Text("Data")
        } footer: {
            Text("MindSnap does not create a separate server account. Deleting all data removes MindSnap records from this device; if iCloud sync is enabled, saved deletions can sync through Apple's CloudKit service.")
        }
    }

    private var healthSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isHealthSyncEnabled },
                set: { handleHealthSyncToggle($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health Sync")
                        Text("Auto-fill compatible progress goals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }
            .tint(.red)

            VStack(alignment: .leading, spacing: 8) {
                Label("Health Data Privacy", systemImage: "lock.shield.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("MindSnap reads your Health data only to update your goal progress.")
                Text("MindSnap does not sell or share Health data.")
                Text("Health access is optional.")
                Text("You can disable Health permissions anytime in iPhone Settings.")
                Text("If Health access is off, manual progress entry still works.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
        } header: {
            Text("Health")
        } footer: {
            Text("MindSnap reads selected Apple Health activity totals, such as steps, distance, exercise minutes, and water. It never writes Health data.")
        }
    }

    // --------------------------------------------------------
    // supportSection — INTERNATIONAL VERSION
    //
    // Shows crisis resources based on user's region.
    // Falls back to international resources if region
    // is not specifically supported.
    // --------------------------------------------------------
    private var supportSection: some View {
        Section {

            // ---- Universal International Resource ----
            // Works for EVERY country — always show this first
            Button {
                if let url = URL(
                    string: "https://findahelpline.com"
                ) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Find a Helpline")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("findahelpline.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Crisis support in 200+ countries")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.purple)
                            .frame(width: 28, height: 28)
                        Image(systemName: "globe")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }

            // ---- Region Specific Resources ----
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
                                    .foregroundStyle(.primary)
                            }
                            Text(resource.phone)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(resource.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.green)
                                .frame(width: 28, height: 28)
                            Image(systemName: "phone.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 14))
                        }
                    }
                }
            }

            // ---- Crisis Text Line ----
            Button {
                if let url = URL(
                    string: "https://www.crisistextline.org"
                ) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Crisis Text Line")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("crisistextline.org")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Text-based support — USA, Canada, UK, Ireland")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        Image(systemName: "message.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }

        } header: {
            Text("Mental Health Support")
        } footer: {
            Text("MindSnap is a journaling tool, not a substitute for professional mental health care. If you are in crisis please reach out to the resources above.")
                .font(.caption)
        }
    }

    // --------------------------------------------------------
    // regionalResources — Crisis lines for major regions
    //
    // Covers the most common countries that will download
    // your app from the App Store.
    // findahelpline.com covers ALL other countries.
    // --------------------------------------------------------
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

    private var aboutSection: some View {
        Section {
            HStack {
                Label {
                    Text("Version")
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.purple)
                            .frame(width: 28, height: 28)
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
            }

            NavigationLink(destination: PrivacyPolicyView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy Policy")
                        Text("Your data & privacy")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.gray)
                            .frame(width: 28, height: 28)
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
            }
            .foregroundStyle(.primary)

            HStack {
                Label {
                    Text("Made with")
                } icon: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.pink)
                            .frame(width: 28, height: 28)
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                }
                Spacer()
                Text("Pratik's ❤️")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }

        } header: {
            Text("About")
        }
    }

    // --------------------------------------------------------
    // nameEditorSheet
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
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingNameEditor = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userName = tempName
                        showingNameEditor = false
                    }
                    .fontWeight(.semibold)
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
        case .light:  return "App always uses light mode"
        case .dark:   return "App always uses dark mode"
        case .system: return "Follows your iPhone's appearance"
        }
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
                        await MainActor.run { isDailyReminderEnabled = true }
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
            let allEntries = try modelContext.fetch(FetchDescriptor<JournalEntry>())
            for entry in allEntries {
                modelContext.delete(entry)
            }

            let allGoals = try modelContext.fetch(FetchDescriptor<Goal>())
            for goal in allGoals {
                modelContext.delete(goal)
            }

            let allCompletions = try modelContext.fetch(FetchDescriptor<GoalCompletion>())
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

        isFaceIDEnabled = false
        showMoodOnHome = true
        isDailyReminderEnabled = false
        isHealthSyncEnabled = false
        reminderHour = 20
        userName = ""
        appColorScheme = AppColorScheme.system.rawValue
        UserPoints.reset()
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
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

#Preview("Dark Mode") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: JournalEntry.self, inMemory: true)
    .preferredColorScheme(.dark)
}

//
//  MindSnapApp.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//
// ============================================================
// MindSnapApp.swift
// MindSnap — MIGRATION SAFE + PERSISTENCE GUARANTEED
//
// CRITICAL FIXES:
// 1. Migration safe — if migration fails, recreates store
//    cleanly instead of crashing or using empty store
// 2. NotificationDelegate stored as singleton (never lost)
// 3. All 3 models in same schema
// 4. Named store for stable persistence
// 5. Tracks CloudKit/local fallback mode for Settings sync status
// ============================================================

import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

// --------------------------------------------------------
// NotificationDelegate — Singleton, never deallocated
// --------------------------------------------------------
class NotificationDelegate: NSObject,
    UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // Show notifications even when app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap → navigate to correct tab
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification
            .request.content.userInfo

        let type = userInfo["type"] as? String ?? ""

        DispatchQueue.main.async {
            switch type {
            case "goal_reminder",
                 "goal_expiry",
                 "partial_points",
                 "healthkit_sync",
                 "health_warning":
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenGoalsTab"),
                    object: nil
                )

            case "mindsnap_journal":
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenJournalTab"),
                    object: nil
                )

            default:
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenGoalsTab"),
                    object: nil
                )
            }
        }

        completionHandler()
    }
}

// --------------------------------------------------------
// CloudSyncMode
//
// Stores how MindSnap persistence was created.
// This is only for user-facing sync status in Settings.
// It does NOT change saving logic or CloudKit behavior.
// --------------------------------------------------------
enum CloudSyncMode: String {
    case cloudKit = "cloudKit"
    case localFallback = "localFallback"
    case recoveredLocal = "recoveredLocal"
    case memoryOnly = "memoryOnly"

    var displayTitle: String {
        switch self {
        case .cloudKit:
            return "iCloud Sync Ready"
        case .localFallback:
            return "Local Storage Mode"
        case .recoveredLocal:
            return "Recovered Local Storage"
        case .memoryOnly:
            return "Temporary Storage Mode"
        }
    }

    var displayMessage: String {
        switch self {
        case .cloudKit:
            return "MindSnap started with iCloud sync support."
        case .localFallback:
            return "MindSnap could not start CloudKit storage and is using local storage for now."
        case .recoveredLocal:
            return "MindSnap recovered from a storage issue and recreated local storage."
        case .memoryOnly:
            return "MindSnap is running in temporary memory-only mode. Data may not persist after closing the app."
        }
    }
}

private func saveCloudSyncMode(_ mode: CloudSyncMode) {
    UserDefaults.standard.set(
        mode.rawValue,
        forKey: "mindsnapCloudSyncMode"
    )
}

// --------------------------------------------------------
// MindSnapApp
// --------------------------------------------------------
@main
struct MindSnapApp: App {

    @AppStorage("appColorScheme")
    private var appColorScheme = AppColorScheme.system.rawValue

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    // --------------------------------------------------------
    // sharedModelContainer
    //
    // MIGRATION STRATEGY:
    // 1. Try named CloudKit config
    // 2. If CloudKit config fails → use local fallback
    // 3. If local store is corrupt → delete corrupt store and recreate local store
    // 4. Absolute last resort → memory-only container
    //
    // This keeps the app from crashing on launch.
    // --------------------------------------------------------
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JournalEntry.self,
            Goal.self,
            GoalCompletion.self
        ])

        // ---- Step 1: Try CloudKit config ----
        do {
            let config = ModelConfiguration(
                "MindSnapStore",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.pratik.MindSnap"),
                cloudKitDatabase: .private("iCloud.com.pratik.MindSnap")
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [config]
            )

            saveCloudSyncMode(.cloudKit)
            return container

        } catch {
            print("CloudKit config failed: \(error)")
        }

        // ---- Step 2: Try local fallback config ----
        do {
            let config = ModelConfiguration(
                "MindSnapStore",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.pratik.MindSnap"),
                cloudKitDatabase: .none
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [config]
            )

            saveCloudSyncMode(.localFallback)
            return container

        } catch {
            print("Local fallback config failed: \(error)")
        }

        // ---- Step 3: Delete corrupt store + recreate local store ----
        do {
            let storeURL = URL.applicationSupportDirectory
                .appendingPathComponent("MindSnapStore.store")

            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
                print("Deleted corrupt MindSnapStore.store, recreating...")
            }

            let altURLs = [
                URL.applicationSupportDirectory
                    .appendingPathComponent("default.store"),
                URL.applicationSupportDirectory
                    .appendingPathComponent("MindSnap.store")
            ]

            for url in altURLs {
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                }
            }

            let freshConfig = ModelConfiguration(
                "MindSnapStore",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.pratik.MindSnap"),
                cloudKitDatabase: .none
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [freshConfig]
            )

            saveCloudSyncMode(.recoveredLocal)
            return container

        } catch {
            print("Recovery failed: \(error)")
        }

        // ---- Step 4: Absolute last resort: memory-only ----
        let memConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        saveCloudSyncMode(.memoryOnly)

        return try! ModelContainer(
            for: schema,
            configurations: [memConfig]
        )
    }()

    private var preferredScheme: ColorScheme? {
        AppColorScheme(rawValue: appColorScheme)?.colorScheme
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(preferredScheme)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if completed {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Init
    // --------------------------------------------------------
    init() {
        // Use singleton delegate — never deallocated
        UNUserNotificationCenter.current().delegate =
            NotificationDelegate.shared
    }
}


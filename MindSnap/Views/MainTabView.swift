//
//  MainTabView.swift
//  MindSnap
//
// ============================================================
// MainTabView.swift
// MindSnap — DEEP LINK + SCENE PHASE FIXED
//
// FIXES:
// 1. Notification tap → Goals tab opens after unlock
// 2. pendingTabSwitch stored when app is locked
// 3. Applied after Face ID unlock succeeds
// 4. Goals refresh on every foreground
// 5. Partial points awarded on new day
// ============================================================

import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications
import Combine

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var journalViewModel: JournalViewModel?
    @State private var authService = AuthService()

    // ---- Tab selection ----
    // 0 = Journal, 1 = Insights, 2 = Goals, 3 = Settings
    @State private var selectedTab: Int = 0

    // ---- Pending tab switch after unlock ----
    @State private var pendingTabSwitch: Int? = nil

    @AppStorage("isFaceIDEnabled")
    private var isFaceIDEnabled = false

    @AppStorage("hasSeenTutorial")
    private var hasSeenTutorial = false

    // Track last active date for partial points
    @AppStorage("lastActiveDate")
    private var lastActiveDateString = ""

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {

            // ---- App Content ----
            if let viewModel = journalViewModel {
                tabContent(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .progressViewStyle(
                        CircularProgressViewStyle()
                    )
            }

            // ---- Lock Screen ----
            if isFaceIDEnabled &&
               !authService.isAuthenticated {
                LockScreenView(authService: authService)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .bottom)
                            .combined(with: .opacity)
                    ))
                    .zIndex(1)
            }

            // ---- Tutorial ----
            if !hasSeenTutorial {
                CoachMarkView(
                    isShowingTutorial: Binding(
                        get: { !hasSeenTutorial },
                        set: { showing in
                            if !showing {
                                withAnimation(
                                    .easeInOut(duration: 0.4)
                                ) {
                                    hasSeenTutorial = true
                                }
                            }
                        }
                    )
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(
            .easeInOut(duration: 0.4),
            value: authService.isAuthenticated
        )
        .animation(
            .easeInOut(duration: 0.4),
            value: hasSeenTutorial
        )
        .onAppear {
            setupApp()
        }
        .onReceive(
            Timer.publish(
                every: 60,
                on: .main,
                in: .common
            ).autoconnect()
        ) { _ in
            checkNewDay()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .onChange(of: isFaceIDEnabled) { _, enabled in
            if !enabled {
                authService.unlockWithoutBiometrics()
            }
        }
        // ---- DEEP LINK FIX ----
        // After unlock → apply pending tab switch
        .onChange(of: authService.isAuthenticated) { _, auth in
            if auth, let pending = pendingTabSwitch {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.4
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = pending
                    }
                    pendingTabSwitch = nil
                }
            }
        }
        // ---- Notification → Goals tab ----
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("OpenGoalsTab")
            )
        ) { _ in
            navigateToTab(2)
        }
        // ---- Notification → Journal tab ----
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("OpenJournalTab")
            )
        ) { _ in
            navigateToTab(0)
        }
        // ---- URL deep links ----
        .onOpenURL { url in
            handleDeepLink(url: url)
        }
    }

    // --------------------------------------------------------
    // MARK: - Tab Content
    // --------------------------------------------------------
    private func tabContent(
        viewModel: JournalViewModel
    ) -> some View {
        TabView(selection: $selectedTab) {

            // 0: Journal
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(0)

            // 1: Insights
            InsightsView(entries: viewModel.entries)
                .tabItem {
                    Label(
                        "Insights",
                        systemImage: "chart.bar.fill"
                    )
                }
                .tag(1)

            // 2: Goals
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(2)

            // 3: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(
                    "Settings",
                    systemImage: "gearshape.fill"
                )
            }
            .tag(3)
        }
        .tint(.purple)
    }

    // --------------------------------------------------------
    // MARK: - Navigate To Tab
    //
    // If locked → store pending switch
    // After unlock → onChange(authService) applies it
    // --------------------------------------------------------
    private func navigateToTab(_ tab: Int) {
        if isFaceIDEnabled && !authService.isAuthenticated {
            pendingTabSwitch = tab
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Deep Link Handler
    // --------------------------------------------------------
    private func handleDeepLink(url: URL) {
        guard url.scheme == "mindsnap" else { return }
        switch url.host {
        case "goals":    navigateToTab(2)
        case "journal":  navigateToTab(0)
        case "insights": navigateToTab(1)
        default: break
        }
    }

    // --------------------------------------------------------
    // MARK: - Setup
    // --------------------------------------------------------
    private func setupApp() {
        if journalViewModel == nil {
            journalViewModel = JournalViewModel(
                modelContext: modelContext
            )
        }
        if !isFaceIDEnabled {
            authService.unlockWithoutBiometrics()
        } else {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.8
            ) {
                if !authService.isAuthenticated {
                    authService.lockApp()
                }
            }
        }
        checkNewDay()
    }

    // --------------------------------------------------------
    // MARK: - Scene Phase Handler
    // --------------------------------------------------------
    private func handleScenePhase(
        _ phase: ScenePhase
    ) {
        switch phase {
        case .background:
            authService.lockApp()
            WidgetCenter.shared.reloadAllTimelines()

        case .active:
            if !isFaceIDEnabled {
                authService.unlockWithoutBiometrics()
            }
            NotificationService().resetBadgeCount()
            journalViewModel?.fetchEntries()
            checkNewDay()

        default:
            break
        }
    }

    // --------------------------------------------------------
    // MARK: - New Day Check
    //
    // Awards partial points from yesterday if new day
    // --------------------------------------------------------
    private func checkNewDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        if lastActiveDateString != today {
            lastActiveDateString = today
            // Post notification so GoalsView awards partial pts
            NotificationCenter.default.post(
                name: NSNotification.Name("NewDayStarted"),
                object: nil
            )
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    MainTabView()
        .modelContainer(
            for: [
                JournalEntry.self,
                Goal.self,
                GoalCompletion.self
            ],
            inMemory: true
        )
}

//
//  GoalsView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
// ============================================================
// GoalsView.swift
// MindSnap — PREMIUM MONOCHROME GOALS SCREEN
//
// UI UPDATE:
// 1. Matches the new professional black/white MindSnap theme
// 2. Premium points/level banner
// 3. Cleaner section headers and empty state
// 4. Better light/dark mode support
// 5. Mood/color accents reduced to meaningful highlights only
//
// FUNCTIONALITY KEPT:
// 1. GoalViewModel setup
// 2. Add/edit goal sheets
// 3. Delete confirmation
// 4. NewDayStarted rollover
// 5. Health sync call
// 6. Sorting completed goals to bottom
// 7. Today/tomorrow sections
// 8. Context menu and swipe actions
// ============================================================

import SwiftUI
import SwiftData

struct GoalsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: GoalViewModel?
    @State private var showingAddGoal = false
    @State private var editingGoal: Goal? = nil
    @State private var goalToDelete: Goal? = nil
    @State private var showingDeleteAlert = false
    @State private var hasSyncedHealthThisSession = false

    @AppStorage("isHealthSyncEnabled")
    private var isHealthSyncEnabled = false

    private let goalGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // --------------------------------------------------------
    // MARK: - Theme
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

    private var softCardBackground: Color {
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

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.06)
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    mainContent(vm: vm)
                } else {
                    loadingState
                }
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addGoalButton
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = GoalViewModel(modelContext: modelContext)
            }

            viewModel?.handleNewDayRollover()

            if !hasSyncedHealthThisSession {
                hasSyncedHealthThisSession = true
                syncHealthProgressIfNeeded()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("NewDayStarted")
            )
        ) { _ in
            viewModel?.handleNewDayRollover()
            hasSyncedHealthThisSession = false
            syncHealthProgressIfNeeded(force: true)
        }
        .sheet(isPresented: $showingAddGoal) {
            if let vm = viewModel {
                AddGoalView(viewModel: vm)
            }
        }
        .sheet(item: $editingGoal) { goal in
            if let vm = viewModel {
                AddGoalView(viewModel: vm, existingGoal: goal)
            }
        }
        .alert(
            "Delete Goal",
            isPresented: $showingDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete,
                   let vm = viewModel {
                    vm.deleteGoal(goal)
                    goalToDelete = nil
                }
            }

            Button("Cancel", role: .cancel) {
                goalToDelete = nil
            }
        } message: {
            Text(
                "This will permanently delete \"\(goalToDelete?.name ?? "this goal")\" and all its history."
            )
        }
    }

    // --------------------------------------------------------
    // MARK: - Loading
    // --------------------------------------------------------
    private var loadingState: some View {
        ZStack {
            appBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(primaryText)

                Text("Loading Goals...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Add Button
    // --------------------------------------------------------
    private var addGoalButton: some View {
        Button {
            showingAddGoal = true
        } label: {
            ZStack {
                Circle()
                    .fill(primaryButtonBackground)
                    .frame(width: 38, height: 38)
                    .shadow(
                        color: shadowColor,
                        radius: 10,
                        x: 0,
                        y: 5
                    )

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(primaryButtonText)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Goal")
    }

    // --------------------------------------------------------
    // MARK: - Main Content
    // --------------------------------------------------------
    @ViewBuilder
    private func mainContent(vm: GoalViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {

                pointsBanner(vm: vm)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                if vm.showingDuplicateWarning {
                    duplicateWarningBanner
                        .padding(.horizontal, 16)
                }

                todaySection(vm: vm)

                if !vm.tomorrowsGoals.isEmpty {
                    tomorrowSection(vm: vm)
                }

                WeeklyProgressView(viewModel: vm)
                    .padding(.horizontal, 16)

                Spacer(minLength: 100)
            }
            .padding(.bottom, 10)
        }
        .background(appBackground)
    }

    // --------------------------------------------------------
    // MARK: - Points Banner
    // --------------------------------------------------------
    private func pointsBanner(vm: GoalViewModel) -> some View {
        let level = UserPoints.level
        let total = UserPoints.total
        let nextLevel = level.pointsToNext(currentPoints: total)
        let progress = nextLevel > 0
            ? Double(total) / Double(nextLevel)
            : 1.0

        return VStack(spacing: 0) {

            HStack(spacing: 0) {

                HStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(softCardBackground)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(borderColor, lineWidth: 1)
                            )

                        Text(level.emoji)
                            .font(.system(size: 26))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(level.rawValue)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)

                        Text("Current Level")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()

                VStack(spacing: 3) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.title3)

                        Text("\(vm.overallStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                            .monospacedDigit()
                    }

                    Text("day streak")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(softCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 10)

                VStack(spacing: 3) {
                    HStack(spacing: 4) {
                        Text("\(total)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                            .monospacedDigit()

                        Text("⭐️")
                            .font(.title3)
                    }

                    Text("Points")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            VStack(spacing: 7) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(softCardBackground)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(primaryText)
                            .frame(
                                width: geo.size.width *
                                CGFloat(min(1.0, progress)),
                                height: 8
                            )
                            .animation(
                                .spring(duration: 0.5),
                                value: progress
                            )
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(level.message)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)

                    Spacer()

                    if nextLevel > total {
                        Text("\(nextLevel - total) pts to next")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)
                    } else {
                        Text("Max level 🏆")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Today Section
    // --------------------------------------------------------
    @ViewBuilder
    private func todaySection(vm: GoalViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(tertiaryText)
                        .tracking(1.2)

                    let dateStr = Date().formatted(
                        .dateTime.weekday(.wide).month().day()
                    )

                    Text(dateStr)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(primaryText)
                }

                Spacer()

                let completed = vm.todaysGoals.filter {
                    vm.isCompletedToday($0)
                }.count
                let total = vm.todaysGoals.count

                Text("\(completed)/\(total)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryButtonText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(primaryButtonBackground)
                    )
            }
            .padding(.horizontal, 16)

            if vm.todaysGoals.isEmpty {
                emptyGoalsState
                    .padding(.horizontal, 16)
            } else {
                let highPriority = sortedGoals(
                    vm.todaysGoals.filter { $0.priority == .high },
                    vm: vm
                )

                if !highPriority.isEmpty {
                    VStack(spacing: 0) {
                        sectionLabel(
                            title: "HIGH PRIORITY",
                            systemImage: "exclamationmark.circle.fill",
                            color: .red
                        )
                        .padding(.bottom, 8)

                        LazyVGrid(columns: goalGridColumns, spacing: 12) {
                            ForEach(highPriority) { goal in
                                goalRow(goal: goal, vm: vm)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }

                let otherGoals = sortedGoals(
                    vm.todaysGoals.filter { $0.priority != .high },
                    vm: vm
                )

                if !otherGoals.isEmpty {
                    if !highPriority.isEmpty {
                        sectionLabel(
                            title: "OTHER GOALS",
                            systemImage: nil,
                            color: secondaryText
                        )
                        .padding(.bottom, 8)
                    }

                    LazyVGrid(columns: goalGridColumns, spacing: 12) {
                        ForEach(otherGoals) { goal in
                            goalRow(goal: goal, vm: vm)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private func sectionLabel(
        title: String,
        systemImage: String?,
        color: Color
    ) -> some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .tracking(1.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // --------------------------------------------------------
    // MARK: - Sort Goals
    // --------------------------------------------------------
    private func sortedGoals(
        _ goals: [Goal],
        vm: GoalViewModel
    ) -> [Goal] {
        goals.sorted { a, b in
            let aCompleted = vm.isCompletedToday(a)
            let bCompleted = vm.isCompletedToday(b)

            if aCompleted != bCompleted {
                return !aCompleted
            }

            return a.name < b.name
        }
    }

    // --------------------------------------------------------
    // MARK: - Goal Row
    // --------------------------------------------------------
    private func goalRow(goal: Goal, vm: GoalViewModel) -> some View {
        GoalRowView(
            goal: goal,
            viewModel: vm,
            isCompact: true,
            onEditGoal: {
                editingGoal = goal
            },
            onDeleteGoal: {
                goalToDelete = goal
                showingDeleteAlert = true
            }
        )
        .contextMenu {
            Button {
                editingGoal = goal
            } label: {
                Label("Edit Goal", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                goalToDelete = goal
                showingDeleteAlert = true
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                goalToDelete = goal
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                editingGoal = goal
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private func syncHealthProgressIfNeeded(force: Bool = false) {
        guard let vm = viewModel else { return }

        Task {
            await vm.syncTodaysHealthProgressIfEnabled(
                isEnabled: isHealthSyncEnabled,
                force: force
            )
        }
    }

    // --------------------------------------------------------
    // MARK: - Tomorrow Section
    // --------------------------------------------------------
    private func tomorrowSection(vm: GoalViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(
                title: "COMING UP TOMORROW",
                systemImage: "moon.stars.fill",
                color: secondaryText
            )

            LazyVGrid(columns: goalGridColumns, spacing: 12) {
                ForEach(
                    vm.tomorrowsGoals.filter {
                        $0.repeatType != .none
                    }
                ) { goal in
                    GoalRowView(
                        goal: goal,
                        viewModel: vm,
                        isTomorrowPreview: true,
                        isCompact: true
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // --------------------------------------------------------
    // MARK: - Empty State
    // --------------------------------------------------------
    private var emptyGoalsState: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(softCardBackground)
                    .frame(width: 104, height: 104)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )

                Image(systemName: "target")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(primaryText)
            }

            VStack(spacing: 8) {
                Text("No Goals Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Text("Tap + to add your first goal and start building better routines.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                showingAddGoal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .fontWeight(.bold)

                    Text("Add First Goal")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(primaryButtonText)
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .background(
                    Capsule()
                        .fill(primaryButtonBackground)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Duplicate Warning
    // --------------------------------------------------------
    private var duplicateWarningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange.opacity(0.90))

            Text("A goal with that name already exists today.")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange.opacity(0.95))

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.13 : 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

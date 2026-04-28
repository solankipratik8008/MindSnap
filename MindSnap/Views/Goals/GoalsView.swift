//
//  GoalsView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
// ============================================================
// GoalsView.swift
// MindSnap — ALL BUGS FIXED
//
// FIXES:
// 1. Points badge no longer clipped — moved inside scroll content
// 2. One-time goals cleanup on NewDayStarted notification
// 3. Completed goals sort to bottom of their section
// 4. Empty state when no goals exist
// 5. Delete confirmation alert before removing goal
// 6. Tomorrow section excludes one-time goals
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
    @AppStorage("isHealthSyncEnabled")
    private var isHealthSyncEnabled = false
    @State private var hasSyncedHealthThisSession = false

    private let goalGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    mainContent(vm: vm)
                } else {
                    ProgressView("Loading Goals...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // ---- Plus button top right ----
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
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
        // ---- One-time goals cleanup on new day ----
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

                // 👇 MOVED HERE
                WeeklyProgressView(viewModel: vm)
                    .padding(.horizontal, 16)

                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // --------------------------------------------------------
    // MARK: - Points Banner
    //
    // FIX: Was in toolbar (got clipped by nav bar safe area)
    // Now lives INSIDE the ScrollView as a card
    // --------------------------------------------------------
    private func pointsBanner(vm: GoalViewModel) -> some View {
        let level = UserPoints.level
        let total = UserPoints.total
        let nextLevel = level.pointsToNext(currentPoints: total)
        let progress = nextLevel > 0
            ? Double(total) / Double(nextLevel)
            : 1.0

        return VStack(spacing: 0) {

            // ---- Top row: Level + Streak + Points ----
            HStack(spacing: 0) {

                // Level info
                HStack(spacing: 10) {
                    Text(level.emoji)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(level.rawValue)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("Current Level")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }

                Spacer()

                // Streak
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.title3)
                        Text("\(vm.overallStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.90))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                )
                .padding(.horizontal, 12)

                // Points
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(total)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("⭐️")
                            .font(.title3)
                    }
                    Text("Total Points")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.90))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // ---- Progress bar to next level ----
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(
                                width: geo.size.width * CGFloat(min(1.0, progress)),
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
                        .foregroundStyle(.white.opacity(0.94))
                    Spacer()
                    if nextLevel > total {
                        Text("\(nextLevel - total) pts to next level")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.92))
                    } else {
                        Text("Max level! 🏆")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.94))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(colorScheme == .dark ? 0.68 : 0.76),
                    Color.green.opacity(colorScheme == .dark ? 0.34 : 0.44)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(
            color: Color.purple.opacity(colorScheme == .dark ? 0.0 : 0.10),
            radius: 10,
            x: 0,
            y: 5
        )
    }

    // --------------------------------------------------------
    // MARK: - Today Section
    // --------------------------------------------------------
    @ViewBuilder
    private func todaySection(vm: GoalViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                    let dateStr = Date().formatted(
                        .dateTime.weekday(.wide).month().day()
                    )
                    Text(dateStr)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                // Count badge
                let completed = vm.todaysGoals.filter {
                    vm.isCompletedToday($0)
                }.count
                let total = vm.todaysGoals.count
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                completed == total && total > 0
                                    ? Color.green
                                    : Color.purple
                            )
                    )
            }
            .padding(.horizontal, 16)

            if vm.todaysGoals.isEmpty {
                emptyGoalsState
                    .padding(.horizontal, 16)
            } else {
                // ---- High Priority section ----
                let highPriority = sortedGoals(
                    vm.todaysGoals.filter { $0.priority == .high },
                    vm: vm
                )
                if !highPriority.isEmpty {
                    VStack(spacing: 0) {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text("HIGH PRIORITY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                                .tracking(1.0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
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

                // ---- Other Goals ----
                let otherGoals = sortedGoals(
                    vm.todaysGoals.filter { $0.priority != .high },
                    vm: vm
                )
                if !otherGoals.isEmpty {
                    if !highPriority.isEmpty {
                        Text("OTHER GOALS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .tracking(1.0)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
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

    // --------------------------------------------------------
    // MARK: - Sort Goals
    //
    // FIX: Completed goals move to BOTTOM of their section
    // --------------------------------------------------------
    private func sortedGoals(
        _ goals: [Goal],
        vm: GoalViewModel
    ) -> [Goal] {
        goals.sorted { a, b in
            let aCompleted = vm.isCompletedToday(a)
            let bCompleted = vm.isCompletedToday(b)
            if aCompleted != bCompleted {
                return !aCompleted // incomplete first
            }
            return a.name < b.name
        }
    }

    // --------------------------------------------------------
    // MARK: - Goal Row with swipe actions
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
    //
    // FIX: Excludes one-time (.none) goals from tomorrow
    // --------------------------------------------------------
    private func tomorrowSection(vm: GoalViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("COMING UP TOMORROW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1.0)
            }
            .padding(.horizontal, 16)

            // Filter out one-time goals — they don't repeat
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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "target")
                    .font(.system(size: 44))
                    .foregroundStyle(.purple.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("No Goals Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Tap + to add your first goal\nand start building great habits!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
        )
    }

    // --------------------------------------------------------
    // MARK: - Duplicate Warning
    // --------------------------------------------------------
    private var duplicateWarningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange.opacity(0.85))

            Text("A goal with that name already exists today.")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange.opacity(0.9))

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.13 : 0.07))
        )
    }
}

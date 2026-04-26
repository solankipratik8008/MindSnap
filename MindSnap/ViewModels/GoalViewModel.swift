//
//  GoalViewModel.swift
//  MindSnap
//
// ============================================================
// GoalViewModel.swift
// MindSnap — PERSISTENCE FIXED + ALL FEATURES WORKING
//
// CRITICAL FIXES:
// 1. saveContext() called after EVERY change
// 2. fetchGoals() fetches ALL then filters in Swift
//    (SwiftData predicate bugs avoided)
// 3. Goals properly persist after app close
// 4. Partial points system working
// 5. Duplicate check working
// 6. Priority sorting working
// 7. One-time goals cleanup working
// ============================================================

import SwiftData
import SwiftUI
import Foundation
import UserNotifications

@Observable
class GoalViewModel {

    // --------------------------------------------------------
    // MARK: - Properties
    // --------------------------------------------------------
    var goals: [Goal] = []
    var completions: [GoalCompletion] = []
    var errorMessage: String? = nil

    // ---- Animation ----
    var lastPointsEarned: Int = 0
    var showingPointsAnimation: Bool = false
    var showingCelebration: Bool = false

    // ---- Health ----
    var healthyLimitWarning: String? = nil
    var showingHealthWarning: Bool = false

    // ---- Duplicate ----
    var duplicateGoalName: String? = nil
    var showingDuplicateWarning: Bool = false

    // ---- Honesty popup ----
    var honestyMessage: String = ""
    var showingHonestyPopup: Bool = false
    var pendingManualGoal: Goal? = nil
    var pendingManualValue: Int = 0
    var pendingManualValueDouble: Double = 0

    // ---- Partial points ----
    var partialPointsPreview: Int = 0
    var showingPartialPointsPreview: Bool = false

    private var modelContext: ModelContext
    private let notificationService = NotificationService()
    private let healthKitService = HealthKitService()

    private let honestyMessages = [
        "We trust your honesty! 🤝 You know what you accomplished.",
        "Your journey, your truth! 💪 Mark it as you experienced it.",
        "No phone? No problem! 📱 We believe in you.",
        "Health data may differ, but you know best! ✨",
        "Sometimes the phone stays home — that's okay! 🏃",
        "Your health is your story. 📖 Write it honestly!",
        "Forgot your phone? We've all been there! 😄",
        "Data is just numbers — your effort counts! 🌟"
    ]

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    var totalPoints: Int { UserPoints.total }
    var currentLevel: PointsLevel { UserPoints.level }

    // ---- Today's goals sorted by priority ----
    var todaysGoals: [Goal] {
        let priorityOrder: [GoalPriority] = [.high, .medium, .low]
        return goals
            .filter { $0.isActive && $0.isScheduledForToday }
            .sorted { a, b in
                let ai = priorityOrder.firstIndex(
                    of: a.priority
                ) ?? 1
                let bi = priorityOrder.firstIndex(
                    of: b.priority
                ) ?? 1
                if ai != bi { return ai < bi }
                return a.sortOrder < b.sortOrder
            }
    }

    // ---- Tomorrow's goals ----
    var tomorrowsGoals: [Goal] {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(
            byAdding: .day, value: 1, to: Date()
        ) else { return [] }

        return goals.filter { goal in
            guard goal.isActive else { return false }
            guard goal.repeatType != .none else { return false }

            let weekday = calendar.component(
                .weekday, from: tomorrow
            )
            let mondayBased = weekday == 1 ? 7 : weekday - 1

            switch goal.repeatType {
            case .daily:    return true
            case .weekdays: return mondayBased <= 5
            case .weekends: return mondayBased >= 6
            case .custom:
                return goal.customRepeatDaysArray
                    .contains(mondayBased)
            case .none:     return false
            }
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    // ---- Today's completions ----
    var todaysCompletions: [GoalCompletion] {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.filter {
            Calendar.current.startOfDay(
                for: $0.completedAt
            ) == today
        }
    }

    // ---- Is completed today ----
    func isCompletedToday(_ goal: Goal) -> Bool {
        todaysCompletions.contains {
            $0.goalID == goal.id && $0.isCompleted
        }
    }

    // ---- Is locked ----
    func isLockedForEditing(_ goal: Goal) -> Bool {
        isCompletedToday(goal)
    }

    // ---- Today's progress ----
    func todaysProgress(for goal: Goal) -> Int {
        Int(todaysProgressValue(for: goal).rounded(.down))
    }

    func todaysProgressValue(for goal: Goal) -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        if let completion = completions.first(where: {
            $0.goalID == goal.id &&
            Calendar.current.startOfDay(
                for: $0.completedAt
            ) == today
        }) {
            return completion.progressValue
        }

        return goal.currentProgressValue
    }

    // ---- Today's completion record ----
    func todaysCompletionRecord(
        for goal: Goal
    ) -> GoalCompletion? {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.first {
            $0.goalID == goal.id &&
            Calendar.current.startOfDay(
                for: $0.completedAt
            ) == today
        }
    }

    // ---- All goals done today ----
    var allGoalsCompletedToday: Bool {
        guard !todaysGoals.isEmpty else { return false }
        return todaysGoals.allSatisfy { isCompletedToday($0) }
    }

    // ---- Completed count ----
    var completedTodayCount: Int {
        todaysGoals.filter { isCompletedToday($0) }.count
    }

    // ---- Minutes until midnight ----
    var minutesUntilMidnight: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let midnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ) else { return 0 }
        return Int(midnight.timeIntervalSince(now) / 60)
    }

    // ---- Is about to expire ----
    func isAboutToExpire(_ goal: Goal) -> Bool {
        guard !isCompletedToday(goal) else { return false }
        guard goal.repeatType != .daily else { return false }
        return minutesUntilMidnight < 120
    }

    // ---- Partial points for a goal ----
    func partialPointsFor(_ goal: Goal) -> Int {
        let progress = todaysProgressValue(for: goal)
        guard progress > 0 && !isCompletedToday(goal) else {
            return 0
        }
        return goal.partialPoints(for: progress)
    }

    // ---- Weekly completions ----
    func weeklyCompletions(for goal: Goal) -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let weekStart = calendar.date(
            byAdding: .day,
            value: -daysFromMonday,
            to: today
        ) else {
            return Array(repeating: false, count: 7)
        }

        return (0..<7).map { offset in
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: weekStart
            ) else { return false }
            if day > today { return false }
            return completions.contains {
                $0.goalID == goal.id &&
                $0.isCompleted &&
                calendar.startOfDay(for: $0.completedAt) == day
            }
        }
    }

    // ---- Streak for one goal ----
    func streakCount(for goal: Goal) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var day = today

        while true {
            let done = completions.contains {
                $0.goalID == goal.id &&
                $0.isCompleted &&
                calendar.startOfDay(for: $0.completedAt) == day
            }
            if done {
                streak += 1
                guard let prev = calendar.date(
                    byAdding: .day, value: -1, to: day
                ) else { break }
                day = prev
            } else { break }
        }
        return streak
    }

    // ---- Overall streak ----
    var overallStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var day = today

        while true {
            let done = completions.contains {
                $0.isCompleted &&
                calendar.startOfDay(for: $0.completedAt) == day
            }
            if done {
                streak += 1
                guard let prev = calendar.date(
                    byAdding: .day, value: -1, to: day
                ) else { break }
                day = prev
            } else { break }
        }
        return streak
    }

    // ---- Weekly completion rate ----
    var weeklyCompletionRate: Double {
        guard !todaysGoals.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let daysElapsed = daysFromMonday + 1

        var total = 0
        var completed = 0

        for goal in todaysGoals {
            let weekly = weeklyCompletions(for: goal)
            total += daysElapsed
            completed += weekly.prefix(daysElapsed)
                .filter { $0 }.count
        }

        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    // --------------------------------------------------------
    // MARK: - Init
    // --------------------------------------------------------
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchGoals()
        fetchCompletions()
        awardPartialPointsForYesterday()
        cleanupExpiredOneTimeGoals()
    }

    // --------------------------------------------------------
    // MARK: - Fetch Goals
    //
    // PERSISTENCE FIX:
    // Fetch ALL goals with no predicate (avoids SwiftData
    // predicate caching bugs), then filter in Swift.
    // --------------------------------------------------------
    func fetchGoals() {
        do {
            let descriptor = FetchDescriptor<Goal>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
            let all = try modelContext.fetch(descriptor)
            goals = all.filter { $0.isActive }
        } catch {
            print("fetchGoals error: \(error)")
        }
    }

    // --------------------------------------------------------
    // MARK: - Fetch Completions
    // --------------------------------------------------------
    func fetchCompletions() {
        do {
            let descriptor = FetchDescriptor<GoalCompletion>(
                sortBy: [
                    SortDescriptor(
                        \.completedAt, order: .reverse
                    )
                ]
            )
            let ninetyDaysAgo = Calendar.current.date(
                byAdding: .day, value: -90, to: Date()
            ) ?? Date()
            let all = try modelContext.fetch(descriptor)
            completions = all.filter {
                $0.completedAt >= ninetyDaysAgo
            }
        } catch {
            print("fetchCompletions error: \(error)")
        }
    }

    // --------------------------------------------------------
    // MARK: - Save Context
    //
    // PERSISTENCE FIX:
    // Always save immediately after any change.
    // Never rely on automatic saves.
    // --------------------------------------------------------
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            print("saveContext error: \(error)")
        }
    }

    // --------------------------------------------------------
    // MARK: - Duplicate Check
    // --------------------------------------------------------
    func isDuplicateGoal(name: String) -> Bool {
        let trimmed = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return todaysGoals.contains {
            $0.name.lowercased() == trimmed
        }
    }

    func checkDuplicate(name: String) -> Bool {
        if isDuplicateGoal(name: name) {
            duplicateGoalName = name
            withAnimation(.spring(duration: 0.3)) {
                showingDuplicateWarning = true
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 3.0
            ) {
                withAnimation {
                    self.showingDuplicateWarning = false
                }
            }
            return true
        }
        return false
    }

    // --------------------------------------------------------
    // MARK: - Add Goal
    // --------------------------------------------------------
    func addGoal(
        name: String,
        emoji: String,
        sfSymbol: String,
        category: GoalCategory,
        activityType: GoalActivityType,
        goalType: GoalType,
        priority: GoalPriority,
        targetValue: Int,
        unit: String,
        repeatType: GoalRepeatType,
        customRepeatDays: [Int],
        reminders: [ReminderTime]
    ) {
        // Block duplicate
        if isDuplicateGoal(name: name) {
            _ = checkDuplicate(name: name)
            return
        }

        let goal = Goal(
            name: name,
            emoji: emoji,
            sfSymbol: sfSymbol,
            category: category,
            goalType: goalType,
            activityType: activityType,
            priority: priority,
            targetValue: targetValue,
            unit: unit,
            repeatType: repeatType,
            customRepeatDays: customRepeatDays
                .map { "\($0)" }
                .joined(separator: ","),
            reminders: reminders,
            sortOrder: goals.count,
            scheduledDate: Date()
        )

        modelContext.insert(goal)

        // ---- SAVE IMMEDIATELY ----
        saveContext()

        // ---- Award points ----
        let pts = goals.isEmpty ? 20 : 5
        awardPoints(pts)

        // ---- Schedule notifications ----
        Task {
            await notificationService.scheduleGoalReminders(
                goalID: goal.id.uuidString,
                goalName: goal.name,
                goalEmoji: goal.emoji,
                activityType: activityType,
                priority: priority,
                reminders: reminders
            )
            if repeatType != .daily && repeatType != .none {
                await notificationService
                    .scheduleGoalExpiryNotification(
                        goalID: goal.id.uuidString,
                        goalName: goal.name,
                        goalEmoji: goal.emoji
                    )
            }
        }

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        // ---- Refresh ----
        fetchGoals()
    }

    // --------------------------------------------------------
    // MARK: - Update Goal
    // --------------------------------------------------------
    func updateGoal(
        _ goal: Goal,
        name: String,
        emoji: String,
        sfSymbol: String,
        category: GoalCategory,
        activityType: GoalActivityType,
        priority: GoalPriority,
        goalType: GoalType,        // ADD
        targetValue: Int,           // ADD
        unit: String,               // ADD
        repeatType: GoalRepeatType,
        customRepeatDays: [Int],
        reminders: [ReminderTime]
    ){
        goal.name = name
        goal.emoji = emoji
        goal.sfSymbol = sfSymbol
        goal.category = category
        goal.activityType = activityType
        goal.priority = priority
        goal.repeatType = repeatType
        goal.customRepeatDays = customRepeatDays
            .map { "\($0)" }
            .joined(separator: ",")
        goal.reminders = reminders
        // FIX 1: Save goal type and target when editing
        goal.goalTypeRaw = goalType.rawValue
        goal.targetValue = targetValue
        goal.unit = unit

        // ---- SAVE IMMEDIATELY ----
        saveContext()

        notificationService.cancelGoalReminders(
            goalID: goal.id.uuidString
        )
        Task {
            await notificationService.scheduleGoalReminders(
                goalID: goal.id.uuidString,
                goalName: goal.name,
                goalEmoji: goal.emoji,
                activityType: activityType,
                priority: priority,
                reminders: reminders
            )
        }

        fetchGoals()
    }

    // --------------------------------------------------------
    // MARK: - Delete Goal
    // --------------------------------------------------------
    func deleteGoal(_ goal: Goal) {
        notificationService.cancelGoalReminders(
            goalID: goal.id.uuidString
        )
        goal.isActive = false

        // ---- SAVE IMMEDIATELY ----
        saveContext()
        fetchGoals()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.warning)
    }

    // --------------------------------------------------------
    // MARK: - Complete Checkbox Goal
    // --------------------------------------------------------
    func completeCheckboxGoal(_ goal: Goal) {
        // LOCK: If already completed + points given → block
        if let existing = todaysCompletionRecord(for: goal),
           existing.isCompleted && existing.isPointsAwarded {
            withAnimation {
                errorMessage = "✅ Goal completed! Great job!"
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 2
            ) { self.errorMessage = nil }
            return
        }

        if let existing = todaysCompletionRecord(for: goal) {
            if !existing.isCompleted {
                existing.isCompleted = true
                existing.toggleCount += 1
                if !existing.isPointsAwarded {
                    existing.isPointsAwarded = true
                    existing.pointsEarned = goal.pointsPerCompletion
                    awardPoints(goal.pointsPerCompletion)
                    goal.totalPointsEarned +=
                        goal.pointsPerCompletion
                }
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                checkAllGoalsCompleted()
            }
        } else {
            let c = GoalCompletion(
                goalID: goal.id,
                goalName: goal.name,
                currentValue: 1,
                targetValue: 1,
                pointsEarned: goal.pointsPerCompletion,
                isCompleted: true,
                completionSource: .manual,
                isPointsAwarded: true,
                toggleCount: 1
            )
            modelContext.insert(c)
            awardPoints(goal.pointsPerCompletion)
            goal.totalPointsEarned += goal.pointsPerCompletion

            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
            checkAllGoalsCompleted()
        }

        // ---- SAVE IMMEDIATELY ----
        saveContext()
        fetchCompletions()
    }

    // --------------------------------------------------------
    // MARK: - Increment Progress
    // --------------------------------------------------------
    func incrementProgress(_ goal: Goal) {
        if isLockedForEditing(goal) {
            withAnimation {
                errorMessage = "✅ Goal completed! Well done!"
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 2
            ) { self.errorMessage = nil }
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let newValue = todaysProgress(for: goal) + 1

        if let limit = goal.exceedsHealthyLimit(
            value: newValue
        ) {
            showHealthyLimitWarning(limit: limit)
        }

        if let existing = completions.first(where: {
            $0.goalID == goal.id &&
            calendar.startOfDay(for: $0.completedAt) == today
        }) {
            guard existing.currentValue < goal.targetValue
            else { return }

            existing.currentValue += 1
            existing.currentValueDouble = Double(existing.currentValue)
            goal.currentValue = existing.currentValue
            goal.currentValueDouble = Double(existing.currentValue)

            if existing.currentValue >= goal.targetValue &&
               !existing.isPointsAwarded {
                existing.isCompleted = true
                existing.isPointsAwarded = true
                existing.pointsEarned = goal.pointsPerCompletion
                awardPoints(goal.pointsPerCompletion)
                goal.totalPointsEarned +=
                    goal.pointsPerCompletion
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                checkAllGoalsCompleted()
            } else {
                showPartialPointsPreview(
                    goal: goal,
                    value: Double(existing.currentValue)
                )
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
            }
        } else {
            let isComplete = 1 >= goal.targetValue
            let c = GoalCompletion(
                goalID: goal.id,
                goalName: goal.name,
                currentValue: 1,
                targetValue: goal.targetValue,
                pointsEarned: isComplete
                    ? goal.pointsPerCompletion : 0,
                isCompleted: isComplete,
                completionSource: .manual,
                isPointsAwarded: isComplete,
                toggleCount: 1
            )
            modelContext.insert(c)
            goal.currentValue = 1
            goal.currentValueDouble = 1

            if isComplete {
                awardPoints(goal.pointsPerCompletion)
                goal.totalPointsEarned +=
                    goal.pointsPerCompletion
                checkAllGoalsCompleted()
            } else {
                showPartialPointsPreview(goal: goal, value: 1)
            }
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
        }

        // ---- SAVE IMMEDIATELY ----
        saveContext()
        fetchCompletions()
    }

    // --------------------------------------------------------
    // MARK: - Decrement Progress
    // --------------------------------------------------------
    func decrementProgress(_ goal: Goal) {
        if isLockedForEditing(goal) {
            withAnimation {
                errorMessage = "✅ Completed goals cannot be edited."
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 2
            ) { self.errorMessage = nil }
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let existing = completions.first(where: {
            $0.goalID == goal.id &&
            calendar.startOfDay(for: $0.completedAt) == today
        }) else { return }

        guard existing.currentValue > 0 else { return }
        existing.currentValue -= 1
        existing.currentValueDouble = Double(existing.currentValue)
        goal.currentValue = existing.currentValue
        goal.currentValueDouble = Double(existing.currentValue)
        existing.isCompleted =
            existing.currentValue >= goal.targetValue

        if existing.currentValue > 0 {
                showPartialPointsPreview(
                    goal: goal,
                    value: Double(existing.currentValue)
                )
        }

        // ---- SAVE IMMEDIATELY ----
        saveContext()
        fetchCompletions()

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // --------------------------------------------------------
    // MARK: - Manual Override (Honesty)
    // --------------------------------------------------------
    func requestManualOverride(goal: Goal, newValue: Int) {
        requestManualOverride(goal: goal, newValue: Double(newValue))
    }

    func requestManualOverride(goal: Goal, newValue: Double) {
        pendingManualGoal = goal
        pendingManualValue = Int(newValue.rounded(.down))
        pendingManualValueDouble = newValue
        honestyMessage = honestyMessages.randomElement()
            ?? honestyMessages[0]
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            showingHonestyPopup = true
        }
    }

    func confirmManualOverride() {
        guard let goal = pendingManualGoal else { return }
        let value = pendingManualValueDouble

        withAnimation { showingHonestyPopup = false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let existing = completions.first(where: {
            $0.goalID == goal.id &&
            calendar.startOfDay(for: $0.completedAt) == today
        }) {
            let wasCompleted = existing.isCompleted
            existing.currentValue = Int(value.rounded(.down))
            existing.currentValueDouble = value
            goal.currentValue = Int(value.rounded(.down))
            goal.currentValueDouble = value
            existing.completionSourceRaw =
                CompletionSource.edited.rawValue

            if value >= Double(goal.targetValue) && !wasCompleted {
                existing.isCompleted = true
                if !existing.isPointsAwarded {
                    existing.isPointsAwarded = true
                    existing.pointsEarned =
                        goal.pointsPerCompletion
                    awardPoints(goal.pointsPerCompletion)
                    goal.totalPointsEarned +=
                        goal.pointsPerCompletion
                }
                checkAllGoalsCompleted()
            } else if value < Double(goal.targetValue) {
                existing.isCompleted = false
                showPartialPointsPreview(
                    goal: goal, value: value
                )
            }
        } else {
            let isComplete = value >= Double(goal.targetValue)
            let c = GoalCompletion(
                goalID: goal.id,
                goalName: goal.name,
                currentValue: Int(value.rounded(.down)),
                currentValueDouble: value,
                targetValue: goal.targetValue,
                pointsEarned: isComplete
                    ? goal.pointsPerCompletion : 0,
                isCompleted: isComplete,
                completionSource: .edited,
                isPointsAwarded: isComplete,
                toggleCount: 1
            )
            modelContext.insert(c)
            goal.currentValue = Int(value.rounded(.down))
            goal.currentValueDouble = value

            if isComplete {
                awardPoints(goal.pointsPerCompletion)
                goal.totalPointsEarned +=
                    goal.pointsPerCompletion
                checkAllGoalsCompleted()
            } else {
                showPartialPointsPreview(
                    goal: goal, value: value
                )
            }
        }

        // ---- SAVE IMMEDIATELY ----
        saveContext()
        fetchCompletions()

        pendingManualGoal = nil
        pendingManualValue = 0
        pendingManualValueDouble = 0
    }

    func cancelManualOverride() {
        withAnimation { showingHonestyPopup = false }
        pendingManualGoal = nil
        pendingManualValue = 0
        pendingManualValueDouble = 0
    }

    // --------------------------------------------------------
    // MARK: - Award Partial Points at Day End
    // --------------------------------------------------------
    func awardPartialPointsForYesterday() {
        fetchCompletions()

        let calendar = Calendar.current
        let yesterday = calendar.date(
            byAdding: .day, value: -1, to: Date()
        )!
        let yesterdayStart =
            calendar.startOfDay(for: yesterday)

        let yesterdayPartials = completions.filter {
            calendar.startOfDay(for: $0.completedAt) ==
                yesterdayStart &&
            !$0.isCompleted &&
            $0.currentValue > 0 &&
            !$0.isPointsAwarded &&
            !$0.partialPointsAwarded
        }

        for completion in yesterdayPartials {
            guard let goal = goalForCompletion(completion) else {
                continue
            }

            let partial = goal.partialPoints(
                for: completion.currentValue
            )
            if partial > 0 {
                completion.pointsEarned = partial
                completion.isPointsAwarded = true
                completion.partialPointsAwarded = true
                completion.partialPointsAmount = partial
                UserPoints.add(partial)
                goal.totalPointsEarned += partial
            }
        }

        if !yesterdayPartials.isEmpty {
            saveContext()
            fetchCompletions()
            fetchGoals()
        }
    }

    // --------------------------------------------------------
    // MARK: - Cleanup One-Time Goals
    // --------------------------------------------------------
    func cleanupExpiredOneTimeGoals() {
        fetchGoals()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var changed = false

        for goal in goals {
            guard goal.repeatType == .none else { continue }
            let scheduled = calendar.startOfDay(
                for: goal.scheduledDate
            )
            if scheduled < today && goal.isActive {
                goal.isActive = false
                changed = true
            }
        }

        if changed {
            saveContext()
            fetchGoals()
        }
    }

    func handleNewDayRollover() {
        awardPartialPointsForYesterday()
        cleanupExpiredOneTimeGoals()
        fetchCompletions()
        fetchGoals()
    }

    func requestHealthKitAccess() async -> Bool {
        await healthKitService.requestAuthorization()
    }

    func syncTodaysHealthProgressIfEnabled(
        isEnabled: Bool
    ) async {
        guard isEnabled else { return }
        guard healthKitService.isAvailable else { return }

        _ = await healthKitService.requestAuthorization()

        for goal in todaysGoals where goal.goalType == .progress {
            guard let metric = await healthKitService.metricForToday(
                activityType: goal.activityType,
                preferredUnit: goal.unit
            ) else {
                continue
            }

            let value = normalizedHealthValue(metric.value, unit: goal.unit)
            guard value > 0 else { continue }

            await MainActor.run {
                applyHealthProgress(value, to: goal)
            }
        }

        await MainActor.run {
            saveContext()
            fetchCompletions()
            fetchGoals()
        }
    }

    // --------------------------------------------------------
    // MARK: - Monthly Report
    // --------------------------------------------------------
    func monthlyCompletionRate(for goal: Goal) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var totalDays = 0
        var completedDays = 0

        for dayOffset in 0..<30 {
            guard let day = calendar.date(
                byAdding: .day, value: -dayOffset, to: today
            ) else { continue }

            let weekday = calendar.component(
                .weekday, from: day
            )
            let mondayBased = weekday == 1 ? 7 : weekday - 1

            var wasScheduled = false
            switch goal.repeatType {
            case .daily:    wasScheduled = true
            case .weekdays: wasScheduled = mondayBased <= 5
            case .weekends: wasScheduled = mondayBased >= 6
            case .custom:
                wasScheduled = goal.customRepeatDaysArray
                    .contains(mondayBased)
            case .none:
                let s = calendar.startOfDay(
                    for: goal.scheduledDate
                )
                wasScheduled = s == day
            }

            if wasScheduled {
                totalDays += 1
                if completions.contains(where: {
                    $0.goalID == goal.id &&
                    $0.isCompleted &&
                    calendar.startOfDay(
                        for: $0.completedAt
                    ) == day
                }) {
                    completedDays += 1
                }
            }
        }

        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays)
    }

    // --------------------------------------------------------
    // MARK: - Private Helpers
    // --------------------------------------------------------
    private func awardPoints(_ points: Int) {
        guard points > 0 else { return }
        UserPoints.add(points)
        lastPointsEarned = points
        withAnimation { showingPointsAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { self.showingPointsAnimation = false }
        }
    }

    private func checkAllGoalsCompleted() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.allGoalsCompletedToday else { return }
            guard !self.todaysGoals.isEmpty else { return }
            UserPoints.add(25)
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                self.showingCelebration = true
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 3.5
            ) {
                withAnimation {
                    self.showingCelebration = false
                }
            }
        }
    }

    private func showPartialPointsPreview(
        goal: Goal,
        value: Double
    ) {
        let partial = goal.partialPoints(for: value)
        if partial > 0 {
            partialPointsPreview = partial
            withAnimation { showingPartialPointsPreview = true }
        }
    }

    private func showHealthyLimitWarning(
        limit: HealthyLimit
    ) {
        healthyLimitWarning =
            "\(limit.warningMessage)\nSource: \(limit.source)"
        withAnimation { showingHealthWarning = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { self.showingHealthWarning = false }
        }
    }

    private func goalForCompletion(
        _ completion: GoalCompletion
    ) -> Goal? {
        if let activeGoal = goals.first(where: {
            $0.id == completion.goalID
        }) {
            return activeGoal
        }

        do {
            let descriptor = FetchDescriptor<Goal>()
            return try modelContext.fetch(descriptor).first {
                $0.id == completion.goalID
            }
        } catch {
            print("goalForCompletion error: \(error)")
            return nil
        }
    }

    private func applyHealthProgress(
        _ value: Double,
        to goal: Goal
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let clampedValue = max(0, value)

        goal.currentValue = Int(clampedValue.rounded(.down))
        goal.currentValueDouble = clampedValue

        if let existing = todaysCompletionRecord(for: goal) {

            // Only update if new value is higher
            guard clampedValue > existing.progressValue else {
                return
            }

            existing.currentValue = Int(clampedValue.rounded(.down))
            existing.currentValueDouble = clampedValue
            existing.completionSourceRaw =
                CompletionSource.automatic.rawValue

            if clampedValue >= Double(goal.targetValue) &&
               !existing.isPointsAwarded {

                existing.isCompleted = true
                existing.isPointsAwarded = true
                existing.pointsEarned = goal.pointsPerCompletion

                awardPoints(goal.pointsPerCompletion)
                goal.totalPointsEarned += goal.pointsPerCompletion

                checkAllGoalsCompleted()
            }

        } else {

            let isComplete = clampedValue >= Double(goal.targetValue)

            let completion = GoalCompletion(
                goalID: goal.id,
                goalName: goal.name,
                currentValue: Int(clampedValue.rounded(.down)),
                currentValueDouble: clampedValue,
                targetValue: goal.targetValue,
                pointsEarned: isComplete
                    ? goal.pointsPerCompletion : 0,
                isCompleted: isComplete,
                completionSource: .automatic,
                isPointsAwarded: isComplete,
                toggleCount: 0,
                completedAt: today
            )

            modelContext.insert(completion)

            if isComplete {
                awardPoints(goal.pointsPerCompletion)
                goal.totalPointsEarned += goal.pointsPerCompletion
                checkAllGoalsCompleted()
            }
        }
    }

    private func normalizedHealthValue(_ value: Double, unit: String) -> Double {
        if isDecimalUnit(unit) {
            return (value * 10).rounded(.down) / 10
        }
        return value.rounded(.down)
    }

    private func isDecimalUnit(_ unit: String) -> Bool {
        let normalized = unit.lowercased()
        return normalized == "km" ||
            normalized == "miles" ||
            normalized == "mi" ||
            normalized == "l"
    }
}

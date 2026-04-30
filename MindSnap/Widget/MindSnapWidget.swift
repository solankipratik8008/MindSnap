//
//  MindSnapWidget.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// MindSnapWidget.swift
// MindSnap — Premium Monochrome Widget UI
//
// SAFE UI UPDATE:
// 1. Keeps Provider/data loading logic unchanged
// 2. Keeps App Group SwiftData reading unchanged
// 3. Keeps selected widget goals unchanged
// 4. Keeps journal shortcut deep links unchanged
// 5. Updates only widget visual design
// 6. Matches new professional black/white theme
// 7. Keeps widget privacy: no journal text, no mood details
// ============================================================

import WidgetKit
import SwiftUI
import SwiftData

// ============================================================
// MARK: - Timeline Provider
// ============================================================
struct MindSnapWidgetProvider: @MainActor TimelineProvider {

    func placeholder(in context: Context) -> MindSnapWidgetEntry {
        return MindSnapWidgetEntry.placeholder
    }

    @MainActor func getSnapshot(
        in context: Context,
        completion: @escaping (MindSnapWidgetEntry) -> Void
    ) {
        let entry = loadWidgetEntry() ?? MindSnapWidgetEntry.placeholder
        completion(entry)
    }

    @MainActor func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<MindSnapWidgetEntry>) -> Void
    ) {
        var entries: [MindSnapWidgetEntry] = []

        if let currentEntry = loadWidgetEntry() {
            entries.append(currentEntry)
        } else {
            entries.append(MindSnapWidgetEntry.placeholder)
        }

        let nextUpdate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: Date()
        ) ?? Date()

        let timeline = Timeline(
            entries: entries,
            policy: .after(nextUpdate)
        )

        completion(timeline)
    }

    @MainActor private func loadWidgetEntry() -> MindSnapWidgetEntry? {
        do {
            let config = ModelConfiguration(
                "MindSnapStore",
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.pratik.MindSnap")
            )

            let container = try ModelContainer(
                for: JournalEntry.self,
                Goal.self,
                GoalCompletion.self,
                configurations: config
            )

            let context = container.mainContext

            let descriptor = FetchDescriptor<JournalEntry>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let entries = try context.fetch(descriptor)
            let goals = try context.fetch(FetchDescriptor<Goal>())
            let completions = try context.fetch(
                FetchDescriptor<GoalCompletion>(
                    sortBy: [
                        SortDescriptor(\.completedAt, order: .reverse)
                    ]
                )
            )

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            let todaysEntries = entries.filter { entry in
                calendar.startOfDay(for: entry.date) == today
            }

            let streakCount = calculateStreak(
                from: entries,
                calendar: calendar
            )

            let goalSummary = todaysGoalSummary(
                goals: goals,
                completions: completions,
                today: today,
                calendar: calendar
            )

            let widgetGoals = widgetGoalSnapshots(
                goals: goals,
                completions: completions,
                today: today,
                calendar: calendar
            )

            let primaryGoal = widgetGoals.first

            return MindSnapWidgetEntry(
                date: Date(),
                todaysMood: nil,
                entryCount: todaysEntries.count,
                streakCount: streakCount,
                lastEntryPreview: nil,
                goalName: primaryGoal?.name ?? goalSummary.name,
                goalProgress: primaryGoal?.progress ?? goalSummary.progress,
                goalTarget: primaryGoal?.target ?? goalSummary.target,
                goalUnit: primaryGoal?.unit ?? goalSummary.unit,
                completedGoalsToday: goalSummary.completedCount,
                totalGoalsToday: goalSummary.totalCount,
                widgetGoals: widgetGoals,
                includeJournalShortcut: shouldIncludeJournalShortcut()
            )

        } catch {
            print("Widget data load failed: \(error)")
            return nil
        }
    }

    private func todaysGoalSummary(
        goals: [Goal],
        completions: [GoalCompletion],
        today: Date,
        calendar: Calendar
    ) -> (
        name: String?,
        progress: Double,
        target: Int,
        unit: String,
        completedCount: Int,
        totalCount: Int
    ) {
        let todaysGoals = goals.filter {
            $0.isActive && $0.isScheduledForToday
        }

        let todaysCompletions = completions.filter {
            calendar.startOfDay(for: $0.completedAt) == today
        }

        let completedCount = todaysGoals.filter { goal in
            if let completion = todaysCompletions.first(where: {
                $0.goalID == goal.id
            }) {
                return completion.isCompleted ||
                    completion.progressValue >= Double(goal.targetValue)
            }

            return goal.currentProgressValue >= Double(goal.targetValue)
        }.count

        let progressGoals = todaysGoals.filter {
            $0.goalType == .progress
        }

        let selectedGoal = progressGoals.max { left, right in
            progressValue(
                for: left,
                completions: todaysCompletions
            ) < progressValue(
                for: right,
                completions: todaysCompletions
            )
        } ?? todaysGoals.first

        guard let selectedGoal else {
            return (nil, 0, 0, "", completedCount, todaysGoals.count)
        }

        return (
            selectedGoal.name,
            progressValue(
                for: selectedGoal,
                completions: todaysCompletions
            ),
            selectedGoal.targetValue,
            selectedGoal.unit,
            completedCount,
            todaysGoals.count
        )
    }

    private func progressValue(
        for goal: Goal,
        completions: [GoalCompletion]
    ) -> Double {
        if let completion = completions.first(where: {
            $0.goalID == goal.id
        }) {
            return completion.progressValue
        }

        return goal.currentProgressValue
    }

    private func widgetGoalSnapshots(
        goals: [Goal],
        completions: [GoalCompletion],
        today: Date,
        calendar: Calendar
    ) -> [WidgetGoalSnapshot] {
        let todaysGoals = goals.filter {
            $0.isActive && $0.isScheduledForToday
        }

        let todaysCompletions = completions.filter {
            calendar.startOfDay(for: $0.completedAt) == today
        }

        let selectedIDs = selectedWidgetGoalIDs()

        let selectedGoals = selectedIDs.compactMap { id in
            todaysGoals.first { $0.id == id }
        }

        let fallbackGoals = todaysGoals.filter { goal in
            !selectedIDs.contains(goal.id)
        }

        let orderedGoals: [Goal]

        if selectedGoals.isEmpty {
            orderedGoals = Array(
                todaysGoals
                    .sorted { first, second in
                        if first.priority != second.priority {
                            return priorityRank(first.priority) < priorityRank(second.priority)
                        }

                        return first.createdAt > second.createdAt
                    }
                    .prefix(1)
            )
        } else {
            orderedGoals = Array((selectedGoals + fallbackGoals).prefix(4))
        }

        return orderedGoals.map { goal in
            let completion = todaysCompletions.first {
                $0.goalID == goal.id
            }

            return WidgetGoalSnapshot(
                id: goal.id,
                name: goal.name,
                emoji: goal.emoji,
                progress: completion?.progressValue ??
                    goal.currentProgressValue,
                target: goal.targetValue,
                unit: goal.unit,
                calories: shouldShowCalories(for: goal)
                    ? completion?.latestHealthCalories ?? 0
                    : 0
            )
        }
    }

    private func selectedWidgetGoalIDs() -> [UUID] {
        let raw = UserDefaults(suiteName: "group.com.pratik.MindSnap")?
            .string(forKey: "widgetGoalIDs") ?? ""

        return raw
            .split(separator: ",")
            .compactMap { UUID(uuidString: String($0)) }
    }

    private func shouldIncludeJournalShortcut() -> Bool {
        UserDefaults(suiteName: "group.com.pratik.MindSnap")?
            .object(forKey: "widgetIncludeJournalShortcut") as? Bool ?? true
    }

    private func shouldShowCalories(for goal: Goal) -> Bool {
        switch goal.activityType {
        case .walking, .running, .cycling, .swimming, .gym, .yoga:
            return true
        default:
            let unit = goal.unit.lowercased()

            return unit == "cal" ||
                unit == "cals" ||
                unit == "calorie" ||
                unit == "calories" ||
                unit == "kcal"
        }
    }

    private func calculateStreak(
        from entries: [JournalEntry],
        calendar: Calendar
    ) -> Int {
        let today = calendar.startOfDay(for: Date())

        let uniqueDays = Set(entries.map { entry in
            calendar.startOfDay(for: entry.date)
        })

        guard !uniqueDays.isEmpty else { return 0 }

        let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: today
        ) ?? today

        var currentDay = uniqueDays.contains(today) ? today : yesterday

        guard uniqueDays.contains(currentDay) else { return 0 }

        var streak = 0

        while uniqueDays.contains(currentDay) {
            streak += 1

            currentDay = calendar.date(
                byAdding: .day,
                value: -1,
                to: currentDay
            ) ?? currentDay
        }

        return streak
    }
}

// ============================================================
// MARK: - Small Widget View
// ============================================================
// ============================================================
// MARK: - Small Widget View
// Premium glass-style journal shortcut
// ============================================================
// ============================================================
// MARK: - Small Widget View
// Clean premium journal shortcut
// ============================================================
struct MindSnapSmallWidgetView: View {

    let entry: MindSnapWidgetEntry

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.085)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.94, green: 0.94, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.66)
        : Color.black.opacity(0.54)
    }

    private var glassFill: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.09)
        : Color.white.opacity(0.78)
    }

    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.12)
        : Color.black.opacity(0.07)
    }

    private var inverseBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var inverseText: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(backgroundGradient)

            VStack(alignment: .leading, spacing: 0) {

                // Top header
                HStack(spacing: 7) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(inverseBackground)
                            .frame(width: 24, height: 24)

                        Image("WidgetLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }

                    Text("MindSnap")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 11))

                        Text("\(entry.streakCount)")
                            .font(.system(size: 11, weight: .bold))
                            .monospacedDigit()
                    }
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(glassFill)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }

                Spacer(minLength: 8)

                // Center icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(inverseBackground)
                        .frame(width: 52, height: 52)

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(inverseText)
                }

                Spacer(minLength: 8)

                // Main text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Write Journal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(entry.entryCount == 1 ? "1 entry today" : "\(entry.entryCount) entries today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                // Bottom privacy row
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(secondaryText)

                    Text("Private shortcut")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
            }
            .padding(14)
        }
        .widgetURL(URL(string: "mindsnap://journal"))
    }
}
// ============================================================
// MARK: - Medium Widget View
// ============================================================
// ============================================================
// MARK: - Medium Widget View
// Premium dashboard-style journal + goals widget
// ============================================================
struct MindSnapMediumWidgetView: View {

    let entry: MindSnapWidgetEntry

    @Environment(\.colorScheme) private var colorScheme

    private var visibleGoals: [WidgetGoalSnapshot] {
        Array(entry.widgetGoals.prefix(4))
    }

    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.09),
                    Color(red: 0.02, green: 0.02, blue: 0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.97, green: 0.97, blue: 0.98),
                    Color(red: 0.92, green: 0.92, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.66)
        : Color.black.opacity(0.54)
    }

    private var glassFill: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.10)
        : Color.white.opacity(0.72)
    }

    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.14)
        : Color.black.opacity(0.07)
    }

    private var inverseBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var inverseText: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(backgroundGradient)

            // Decorative soft glow
            Circle()
                .fill(primaryText.opacity(colorScheme == .dark ? 0.08 : 0.045))
                .frame(width: 150, height: 150)
                .offset(x: 140, y: -72)

            Circle()
                .fill(primaryText.opacity(colorScheme == .dark ? 0.04 : 0.03))
                .frame(width: 130, height: 130)
                .offset(x: -145, y: 72)

            VStack(alignment: .leading, spacing: 9) {
                header

                if visibleGoals.isEmpty {
                    emptyWidgetState
                } else {
                    goalGrid
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 11)
            .padding(.bottom, 10)
        }
        .widgetURL(URL(string: "mindsnap://goals"))
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(inverseBackground)
                    .frame(width: 26, height: 26)

                Image("WidgetLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("MindSnap")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text("Today’s progress")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if entry.includeJournalShortcut {
                Link(destination: URL(string: "mindsnap://journal")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 9, weight: .bold))

                        Text("Journal")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(glassFill)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }
            }

            Text("\(entry.completedGoalsToday)/\(max(entry.totalGoalsToday, 1))")
                .font(.system(size: 11, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(inverseText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(inverseBackground)
                )
        }
    }

    private var goalGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 7),
                GridItem(.flexible(), spacing: 7)
            ],
            spacing: 7
        ) {
            ForEach(visibleGoals, id: \.id) { goal in
                compactGoalTile(goal)
            }
        }
    }

    private func compactGoalTile(_ goal: WidgetGoalSnapshot) -> some View {
        let isDone = goal.progressRatio >= 1
        let percent = Int(goal.progressRatio * 100)

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isDone ? inverseBackground : glassFill)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 1)
                        )

                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(inverseText)
                    } else {
                        Text(goal.emoji)
                            .font(.system(size: 12))
                    }
                }

                Text(goal.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 2)

                Text(isDone ? "Done" : "\(percent)%")
                    .font(.system(size: 10, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.12)
                              : Color.black.opacity(0.08))

                    Capsule()
                        .fill(inverseBackground)
                        .frame(
                            width: max(
                                6,
                                geo.size.width * CGFloat(goal.progressRatio)
                            )
                        )
                }
            }
            .frame(height: 5)

            HStack(spacing: 4) {
                Text(goalProgressText(goal))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                if goal.calories > 0 {
                    Text("🔥 \(Int(goal.calories))")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(
            maxWidth: .infinity,
            minHeight: 52,
            maxHeight: 54,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(glassFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private var emptyWidgetState: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(inverseBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: entry.includeJournalShortcut ? "square.and.pencil" : "target")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(inverseText)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.includeJournalShortcut ? "Write Journal" : "No goals selected")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(primaryText)

                Text(entry.includeJournalShortcut ? "Capture a private moment" : "Choose goals in Settings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(glassFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private func goalProgressText(_ goal: WidgetGoalSnapshot) -> String {
        if goal.target <= 0 {
            return "Progress"
        }

        let progress = formatGoalValue(goal.progress, unit: goal.unit)
        let target = formatGoalValue(Double(goal.target), unit: goal.unit)

        if goal.unit.isEmpty {
            return "\(progress) / \(target)"
        }

        return "\(progress) / \(target) \(goal.unit)"
    }

    private func formatGoalValue(_ value: Double, unit: String) -> String {
        let normalized = unit.lowercased()

        if normalized == "km" ||
            normalized == "miles" ||
            normalized == "mi" ||
            normalized == "l" {
            if abs(value) > 0 && abs(value) < 1 {
                return value.formatted(.number.precision(.fractionLength(1...2)))
            }

            return value.formatted(.number.precision(.fractionLength(0...1)))
        }

        return "\(Int(value.rounded(.down)))"
    }
}

// ============================================================
// MARK: - Lock Screen Widgets
// ============================================================
// ============================================================
// MARK: - Lock Screen Widgets
// ============================================================
struct MindSnapAccessoryCircularView: View {

    let entry: MindSnapWidgetEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.22), lineWidth: 5)

            Circle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 30, height: 30)

            Image(systemName: "square.and.pencil")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .widgetURL(URL(string: "mindsnap://journal"))
    }
}

struct MindSnapAccessoryRectangularView: View {

    let entry: MindSnapWidgetEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.includeJournalShortcut ? "square.and.pencil" : "target")
                .font(.caption)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 1) {
                Text("MindSnap")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(entry.includeJournalShortcut
                     ? "Write Journal · 🔥 \(entry.streakCount)"
                     : "\(entry.completedGoalsToday)/\(max(entry.totalGoalsToday, 1)) goals today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "mindsnap://journal"))
    }
}

struct MindSnapAccessoryInlineView: View {

    let entry: MindSnapWidgetEntry

    var body: some View {
        Text(entry.includeJournalShortcut
             ? "MindSnap · Write Journal · 🔥 \(entry.streakCount)"
             : "MindSnap · \(entry.completedGoalsToday)/\(max(entry.totalGoalsToday, 1)) goals")
            .widgetURL(URL(string: "mindsnap://journal"))
    }
}



// ============================================================
// MARK: - Main Widget Configuration
// ============================================================
@main
struct MindSnapWidget: Widget {

    let kind: String = "MindSnapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MindSnapWidgetProvider()
        ) { entry in
            MindSnapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MindSnap Journal & Goals")
        .description("Quick journal and goal progress.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// ============================================================
// MARK: - Helpers
// ============================================================
private func priorityRank(_ priority: GoalPriority) -> Int {
    switch priority {
    case .high:
        return 0
    case .medium:
        return 1
    case .low:
        return 2
    }
}

// ============================================================
// MARK: - Widget Entry View Router
// ============================================================
struct MindSnapWidgetEntryView: View {

    let entry: MindSnapWidgetEntry

    @Environment(\.widgetFamily)
    private var family

    var body: some View {
        switch family {
        case .systemSmall:
            MindSnapSmallWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }

        case .systemMedium:
            MindSnapMediumWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }

        case .accessoryCircular:
            MindSnapAccessoryCircularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }

        case .accessoryRectangular:
            MindSnapAccessoryRectangularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }

        case .accessoryInline:
            MindSnapAccessoryInlineView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }

        default:
            MindSnapSmallWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
    }
}

// ============================================================
// MARK: - Previews
// ============================================================
#Preview("Small Widget", as: .systemSmall) {
    MindSnapWidget()
} timeline: {
    MindSnapWidgetEntry.placeholder

    MindSnapWidgetEntry(
        date: Date(),
        todaysMood: nil,
        entryCount: 2,
        streakCount: 5,
        lastEntryPreview: nil,
        goalName: "Walk",
        goalProgress: 4200,
        goalTarget: 10000,
        goalUnit: "steps",
        completedGoalsToday: 1,
        totalGoalsToday: 4,
        widgetGoals: [
            WidgetGoalSnapshot(
                id: UUID(),
                name: "Walk",
                emoji: "🚶",
                progress: 4200,
                target: 10000,
                unit: "steps",
                calories: 120
            )
        ],
        includeJournalShortcut: true
    )
}

#Preview("Medium Widget", as: .systemMedium) {
    MindSnapWidget()
} timeline: {
    MindSnapWidgetEntry.placeholder

    MindSnapWidgetEntry(
        date: Date(),
        todaysMood: nil,
        entryCount: 2,
        streakCount: 5,
        lastEntryPreview: nil,
        goalName: "Walk",
        goalProgress: 4200,
        goalTarget: 10000,
        goalUnit: "steps",
        completedGoalsToday: 1,
        totalGoalsToday: 4,
        widgetGoals: [
            WidgetGoalSnapshot(
                id: UUID(),
                name: "Walk",
                emoji: "🚶",
                progress: 4200,
                target: 10000,
                unit: "steps",
                calories: 120
            ),
            WidgetGoalSnapshot(
                id: UUID(),
                name: "Water",
                emoji: "💧",
                progress: 5,
                target: 8,
                unit: "glasses",
                calories: 0
            ),
            WidgetGoalSnapshot(
                id: UUID(),
                name: "Read",
                emoji: "📚",
                progress: 15,
                target: 30,
                unit: "pages",
                calories: 0
            )
        ],
        includeJournalShortcut: true
    )
}

#Preview("Lock Screen Circular", as: .accessoryCircular) {
    MindSnapWidget()
} timeline: {
    MindSnapWidgetEntry.placeholder
}

#Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
    MindSnapWidget()
} timeline: {
    MindSnapWidgetEntry.placeholder
}

#Preview("Lock Screen Inline", as: .accessoryInline) {
    MindSnapWidget()
} timeline: {
    MindSnapWidgetEntry.placeholder
}

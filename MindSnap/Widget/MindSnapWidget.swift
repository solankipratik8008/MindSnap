//
//  MindSnapWidget.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// MindSnapWidget.swift
// MindSnap — The actual widget implementation
//
// WHAT THIS FILE DOES:
// This file contains everything the widget needs to run:
//   1. Provider — fetches data and builds a timeline
//   2. Small widget view — shows private journal shortcut + streak
//   3. Medium widget view — shows private journal stats
//   4. Widget configuration — registers the widget with iOS
//
// HOW WIDGETS WORK (important concept!):
// Widgets are NOT live views — they are SNAPSHOTS.
// iOS asks your Provider: "give me entries for the next hour"
// You return TimelineEntry objects with dates.
// iOS renders each entry at its scheduled time.
// This is why we can't use @State or live data in widgets.
//
// TIMELINE PROVIDER:
// Think of it like a TV schedule:
//   "At 9am show this, at 12pm show this, at 6pm show this"
// The Provider builds that schedule using your SwiftData.
//
// MVVM ROLE: This file is the Widget layer — separate from
//            the main app's MVVM. Widgets have their own
//            architecture pattern using Provider + Entry + View
// ============================================================

import WidgetKit
import SwiftUI
import SwiftData

// ============================================================
// MARK: - Timeline Provider
//
// The Provider is the brain of the widget.
// It has 3 required methods:
//   1. placeholder() — shown while widget loads
//   2. getSnapshot()  — shown in widget picker gallery
//   3. getTimeline()  — the actual live data schedule
// ============================================================
struct MindSnapWidgetProvider: @MainActor TimelineProvider {

    // --------------------------------------------------------
    // placeholder(in:)
    //
    // Returns a fake entry shown while the widget is loading.
    // Should return INSTANTLY — no async work here.
    // iOS shows this as a blurred/redacted preview.
    // --------------------------------------------------------
    func placeholder(in context: Context) -> MindSnapWidgetEntry {
        // Return our pre-built placeholder from WidgetEntry.swift
        return MindSnapWidgetEntry.placeholder
    }

    // --------------------------------------------------------
    // getSnapshot(in:completion:)
    //
    // Returns a single entry for the widget gallery preview.
    // When user is browsing widgets to add, they see this.
    // Should look good and representative of real data.
    // --------------------------------------------------------
    @MainActor func getSnapshot(
        in context: Context,
        completion: @escaping (MindSnapWidgetEntry) -> Void
    ) {
        // For snapshot, try to get real data
        // If that fails, use placeholder
        let entry = loadWidgetEntry() ?? MindSnapWidgetEntry.placeholder
        completion(entry)
    }

    // --------------------------------------------------------
    // getTimeline(in:completion:)
    //
    // This is called when the widget needs to update.
    // We build a schedule of future updates.
    //
    // .atEnd policy means: when the last entry's date passes,
    // call getTimeline again to get fresh data.
    // --------------------------------------------------------
    @MainActor func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<MindSnapWidgetEntry>) -> Void
    ) {
        // Load current data from SwiftData
        var entries: [MindSnapWidgetEntry] = []

        // Get the current entry with real data
        if let currentEntry = loadWidgetEntry() {
            entries.append(currentEntry)
        } else {
            // No data available — use placeholder
            entries.append(MindSnapWidgetEntry.placeholder)
        }

        // Schedule next update in 1 hour
        // .atEnd means: refresh when the last entry expires
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

    // --------------------------------------------------------
    // loadWidgetEntry() — Private helper
    //
    // Fetches journal data from SwiftData and builds a
    // MindSnapWidgetEntry with real user data.
    //
    // Returns nil if no data is available or fetch fails.
    //
    // NOTE: Widgets use a SEPARATE ModelContainer from the app.
    // We create our own container here just for reading data.
    // In a full App Group setup, both containers point to
    // the same SQLite file via the shared group container.
    // --------------------------------------------------------
    @MainActor private func loadWidgetEntry() -> MindSnapWidgetEntry? {
        do {
            // Create a read-only SwiftData container
            // This reads the same database as the main app
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

            // Fetch all entries sorted by date (newest first)
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

            // ---- Calculate today's data ----
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Filter entries from today only
            let todaysEntries = entries.filter { entry in
                calendar.startOfDay(for: entry.date) == today
            }

            // ---- Calculate streak ----
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
                widgetGoals: widgetGoals
            )

        } catch {
            // If anything fails, return nil
            // getTimeline will use placeholder instead
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
        let orderedGoals = selectedGoals.isEmpty
            ? Array(todaysGoals.prefix(4))
            : Array((selectedGoals + fallbackGoals).prefix(4))

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

    private func shouldShowCalories(for goal: Goal) -> Bool {
        switch goal.activityType {
        case .walking, .running, .cycling, .swimming, .gym, .yoga:
            return true
        default:
            let unit = goal.unit.lowercased()
            return unit == "cal" || unit == "cals" ||
                unit == "calorie" || unit == "calories" ||
                unit == "kcal"
        }
    }

    // --------------------------------------------------------
    // calculateStreak(from:calendar:)
    //
    // Same streak logic as JournalViewModel but standalone
    // because the widget can't access the ViewModel directly.
    // --------------------------------------------------------
    private func calculateStreak(
        from entries: [JournalEntry],
        calendar: Calendar
    ) -> Int {
        let today = calendar.startOfDay(for: Date())

        // Get unique days that have entries
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
//
// Shown when user picks the SMALL widget size (2x2 grid).
// Very compact — shows private journal shortcut and streak.
// ============================================================
struct MindSnapSmallWidgetView: View {

    // The data entry to display
    let entry: MindSnapWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.10),
                            Color(.systemBackground).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 7) {
                HStack {
                    Text("MindSnap")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text("🔥 \(entry.streakCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(height: 14)

                ZStack {
                    Circle()
                        .fill(Color(.systemBackground).opacity(0.90))
                        .frame(width: 44, height: 44)
                    if let goal = entry.widgetGoals.first {
                        Text(goal.emoji)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.purple)
                    }
                }

                Text(entry.widgetGoals.first?.name ?? "Journal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 9, weight: .semibold))
                    Text(
                        entry.widgetGoals.first.map {
                            "\(Int($0.progressRatio * 100))%"
                        } ??
                        (entry.goalTarget > 0
                            ? "\(Int(entry.goalProgressRatio * 100))%"
                            : "\(entry.completedGoalsToday) goals"
                        )
                    )
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
        }
        .widgetURL(URL(string: "mindsnap://journal"))
    }
}

// ============================================================
// MARK: - Medium Widget View
//
// Shown when user picks the MEDIUM widget size (4x2 grid).
// More space — shows private goal progress plus journal stats.
// ============================================================
struct MindSnapMediumWidgetView: View {

    let entry: MindSnapWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.14),
                            Color.blue.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 14) {
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.82))
                            .frame(width: 64, height: 64)
                        Image(systemName: "target")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.purple)
                    }

                    Text("\(Int(entry.goalProgressRatio * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("Goals")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 7) {
                    Text("Goals")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(entry.widgetGoals.first?.name ?? entry.goalName ?? "Today")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if !entry.widgetGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(entry.widgetGoals.prefix(2), id: \.id) { goal in
                                HStack(spacing: 6) {
                                    Text(goal.emoji)
                                    Text(goal.name)
                                        .lineLimit(1)
                                    Spacer(minLength: 4)
                                    Text("\(Int(goal.progressRatio * 100))%")
                                        .monospacedDigit()
                                    if goal.calories > 0 {
                                        Text("🔥 \(Int(goal.calories))")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.primary)
                            }
                        }
                    } else {
                        Text(entry.goalTarget > 0 && !entry.goalUnit.isEmpty
                             ? "\(entry.formattedGoalProgress) / \(entry.formattedGoalTarget) \(entry.goalUnit)"
                             : "\(entry.completedGoalsToday)/\(max(entry.totalGoalsToday, 1)) complete")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    ProgressView(value: entry.goalProgressRatio)
                        .tint(.purple)

                    Text("🔥 \(entry.streakCount) streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
        .widgetURL(URL(string: "mindsnap://goals"))
    }
}

// ============================================================
// MARK: - Lock Screen Widgets
// ============================================================
struct MindSnapAccessoryCircularView: View {
    let entry: MindSnapWidgetEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.18), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.08, min(entry.goalProgressRatio, 1)))
                .stroke(
                    Color.purple,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Image(systemName: "target")
                    .font(.caption)
                Text("\(Int(entry.goalProgressRatio * 100))")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(2)
        .widgetURL(URL(string: "mindsnap://goals"))
    }
}

struct MindSnapAccessoryRectangularView: View {
    let entry: MindSnapWidgetEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "target")
                .font(.caption)
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 1) {
                Text("Goals")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(
                    entry.goalTarget > 0
                        ? "\(Int(entry.goalProgressRatio * 100))% complete"
                        : "🔥 \(entry.streakCount)"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "mindsnap://goals"))
    }
}

struct MindSnapAccessoryInlineView: View {
    let entry: MindSnapWidgetEntry

    var body: some View {
        Text(entry.goalTarget > 0 ? "Goals \(Int(entry.goalProgressRatio * 100))%" : "🔥 \(entry.streakCount)")
            .widgetURL(URL(string: "mindsnap://goals"))
    }
}

// ============================================================
// MARK: - Main Widget Configuration
//
// This is the @main entry point for the widget extension.
// It registers the widget with iOS and defines:
//   - Which sizes are supported
//   - What the widget is called in the picker
//   - Which view to show for each size
// ============================================================
@main
struct MindSnapWidget: Widget {

    // Unique identifier for this widget
    // Must be unique across all widgets in your app
    let kind: String = "MindSnapWidget"

    var body: some WidgetConfiguration {

        // StaticConfiguration = no user customization needed
        // (vs IntentConfiguration which allows user settings)
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
// MARK: - Widget Entry View (Router)
//
// This View reads the current widget family size and
// returns the appropriate view (small or medium).
//
// @Environment(\.widgetFamily) tells us which size iOS
// is currently rendering.
// ============================================================
struct MindSnapWidgetEntryView: View {
    
    let entry: MindSnapWidgetEntry
    
    // This environment value tells us which size widget
    // is being rendered right now
    @Environment(\.widgetFamily) var family
    
    
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
                WidgetGoalSnapshot(id: UUID(), name: "Walk", emoji: "🚶", progress: 4200, target: 10000, unit: "steps", calories: 120)
            ]
        )
    }
    
    #Preview("Medium Widget", as: .systemMedium) {
        MindSnapWidget()
    } timeline: {
        MindSnapWidgetEntry.placeholder
        MindSnapWidgetEntry(    
            date: Date(),
            todaysMood: nil,
            entryCount: 1,
            streakCount: 12,
            lastEntryPreview: nil,
            goalName: "Morning Run",
            goalProgress: 3.2,
            goalTarget: 5,
            goalUnit: "km",
            completedGoalsToday: 2,
            totalGoalsToday: 5,
            widgetGoals: [
                WidgetGoalSnapshot(id: UUID(), name: "Run", emoji: "🏃", progress: 3.2, target: 5, unit: "km", calories: 220),
                WidgetGoalSnapshot(id: UUID(), name: "Walk", emoji: "🚶", progress: 4200, target: 10000, unit: "steps", calories: 120)
            ]
        )
    }

    #Preview("Lock Screen Circular", as: .accessoryCircular) {
        MindSnapWidget()
    } timeline: {
        MindSnapWidgetEntry(
            date: Date(),
            todaysMood: nil,
            entryCount: 1,
            streakCount: 2,
            lastEntryPreview: nil,
            goalName: "Walk",
            goalProgress: 3900,
            goalTarget: 10000,
            goalUnit: "steps",
            completedGoalsToday: 1,
            totalGoalsToday: 3,
            widgetGoals: [
                WidgetGoalSnapshot(id: UUID(), name: "Walk", emoji: "🚶", progress: 3900, target: 10000, unit: "steps", calories: 0)
            ]
        )
    }

    #Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
        MindSnapWidget()
    } timeline: {
        MindSnapWidgetEntry(
            date: Date(),
            todaysMood: nil,
            entryCount: 1,
            streakCount: 2,
            lastEntryPreview: nil,
            goalName: "Goals",
            goalProgress: 3900,
            goalTarget: 10000,
            goalUnit: "steps",
            completedGoalsToday: 1,
            totalGoalsToday: 3,
            widgetGoals: [
                WidgetGoalSnapshot(id: UUID(), name: "Walk", emoji: "🚶", progress: 3900, target: 10000, unit: "steps", calories: 0)
            ]
        )
    }

    #Preview("Lock Screen Inline", as: .accessoryInline) {
        MindSnapWidget()
    } timeline: {
        MindSnapWidgetEntry(
            date: Date(),
            todaysMood: nil,
            entryCount: 1,
            streakCount: 2,
            lastEntryPreview: nil,
            goalName: "Goals",
            goalProgress: 3900,
            goalTarget: 10000,
            goalUnit: "steps",
            completedGoalsToday: 1,
            totalGoalsToday: 3,
            widgetGoals: [
                WidgetGoalSnapshot(id: UUID(), name: "Walk", emoji: "🚶", progress: 3900, target: 10000, unit: "steps", calories: 0)
            ]
        )
    }
}

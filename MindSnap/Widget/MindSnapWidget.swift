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

            return MindSnapWidgetEntry(
                date: Date(),
                todaysMood: nil,
                entryCount: todaysEntries.count,
                streakCount: streakCount,
                lastEntryPreview: nil
            )

        } catch {
            // If anything fails, return nil
            // getTimeline will use placeholder instead
            print("Widget data load failed: \(error)")
            return nil
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
            // ---- Background ----
            ContainerRelativeShape()
                .fill(
                    Color.purple.opacity(0.15).gradient
                )

            VStack(spacing: 8) {

                // ---- Top: App name ----
                Text("MindSnap")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.purple)

                Text("Private journal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                // ---- Bottom: Streak counter ----
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.caption2)
                    Text("\(entry.streakCount) day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }
}

// ============================================================
// MARK: - Medium Widget View
//
// Shown when user picks the MEDIUM widget size (4x2 grid).
// More space — shows private stats without mood or entry text.
// ============================================================
struct MindSnapMediumWidgetView: View {

    let entry: MindSnapWidgetEntry

    var body: some View {
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(
                    Color.purple.opacity(0.12).gradient
                )

            HStack(spacing: 16) {

                // ---- Left Side: Private journal shortcut ----
                VStack(spacing: 6) {
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.purple)

                    Text("Journal")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("Private")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)

                // Vertical divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // ---- Right Side: Stats + Preview ----
                VStack(alignment: .leading, spacing: 8) {

                    // App name
                    Text("MindSnap")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    // Entry count today
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        Text("\(entry.entryCount) \(entry.entryCount == 1 ? "entry" : "entries") today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Streak
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.caption2)
                        Text("\(entry.streakCount) day streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text("Open MindSnap to write or review your private entries.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
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
            // Return the right view based on widget family
            MindSnapWidgetEntryView(entry: entry)
                // Give the widget access to SwiftData
                .modelContainer(
                    try! ModelContainer(for: JournalEntry.self)
                )
        }
        // Name shown in the widget picker
        .configurationDisplayName("MindSnap")
        // Description shown in the widget picker
        .description("See private journaling stats and your streak.")
        // Which sizes this widget supports
        .supportedFamilies([.systemSmall, .systemMedium])
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
                    Color.purple.opacity(0.15)
                }
        case .systemMedium:
            MindSnapMediumWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.purple.opacity(0.15)
                }
        default:
            MindSnapSmallWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.purple.opacity(0.15)
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
            lastEntryPreview: nil
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
            lastEntryPreview: nil
        )
    }
}

//
//  WidgetEntry.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// WidgetEntry.swift
// MindSnap — The data model for the home screen widget
//
// WHAT THIS FILE DOES:
// Widgets work differently from regular SwiftUI views.
// A widget needs a "Timeline Entry" — a snapshot of data
// at a specific point in time.
//
// Think of it like this:
//   - Your app runs live and updates instantly
//   - A widget is more like a series of SNAPSHOTS
//   - iOS asks "what should the widget show at 9am? at 12pm?"
//   - You provide TimelineEntry objects with that data
//
// This file defines WHAT DATA the widget needs to display.
//
// IMPORTANT: This file must be added to BOTH targets:
//   - MindSnap (main app)
//   - MindSnapWidget (widget extension)
// Right click the file → Show File Inspector →
// Check both targets in "Target Membership"
// ============================================================

import WidgetKit // Required for TimelineEntry protocol
import SwiftUI   // Required for Color
import Foundation

struct WidgetGoalSnapshot: Hashable {
    let id: UUID
    let name: String
    let emoji: String
    let progress: Double
    let target: Int
    let unit: String
    let calories: Double

    var progressRatio: Double {
        guard target > 0 else { return 0 }
        return min(progress / Double(target), 1)
    }
}

// --------------------------------------------------------
// MindSnapWidgetEntry
//
// Conforms to TimelineEntry — required by WidgetKit.
// TimelineEntry requires ONE property: 'date'
// The date tells iOS WHEN to display this snapshot.
//
// We add our own custom properties on top:
//   - todaysMood: legacy field kept nil for widget privacy
//   - entryCount: how many entries today
//   - streakCount: current journaling streak
//   - lastEntryPreview: legacy field kept nil for widget privacy
//   - goal progress summary for privacy-safe goal widgets
// --------------------------------------------------------
struct MindSnapWidgetEntry: TimelineEntry {

    // --------------------------------------------------------
    // date — REQUIRED by TimelineEntry protocol
    //
    // This is when iOS should display this widget snapshot.
    // Example: if date = 9am, widget shows this data at 9am.
    // We usually set this to Date() meaning "show now"
    // --------------------------------------------------------
    let date: Date

    // --------------------------------------------------------
    // todaysMood — Kept for compatibility, but intentionally nil
    //
    // Do not expose private mood data on widgets.
    // --------------------------------------------------------
    let todaysMood: MoodType?

    // --------------------------------------------------------
    // entryCount — How many entries written today
    //
    // Used to show "2 entries today" in the medium widget.
    // --------------------------------------------------------
    let entryCount: Int

    // --------------------------------------------------------
    // streakCount — Consecutive days journaled
    //
    // Shows the 🔥 streak number in the widget.
    // --------------------------------------------------------
    let streakCount: Int

    // --------------------------------------------------------
    // lastEntryPreview — Kept for compatibility, but intentionally nil
    //
    // Do not expose journal text snippets on widgets.
    // --------------------------------------------------------
    let lastEntryPreview: String?

    let goalName: String?
    let goalProgress: Double
    let goalTarget: Int
    let goalUnit: String
    let completedGoalsToday: Int
    let totalGoalsToday: Int
    let widgetGoals: [WidgetGoalSnapshot]

    // --------------------------------------------------------
    // placeholder — Static placeholder for widget gallery
    //
    // iOS shows this when the widget is loading or when
    // displayed in the widget picker gallery.
    //
    // 'static' means we call it on the TYPE not an instance:
    //   MindSnapWidgetEntry.placeholder
    // --------------------------------------------------------
    static let placeholder = MindSnapWidgetEntry(
        date: Date(),
        todaysMood: nil,
        entryCount: 1,
        streakCount: 7,
        lastEntryPreview: nil,
        goalName: "Walk",
        goalProgress: 3200,
        goalTarget: 10000,
        goalUnit: "steps",
        completedGoalsToday: 1,
        totalGoalsToday: 3,
        widgetGoals: [
            WidgetGoalSnapshot(
                id: UUID(),
                name: "Walk",
                emoji: "🚶",
                progress: 3200,
                target: 10000,
                unit: "steps",
                calories: 0
            )
        ]
    )
}

extension MindSnapWidgetEntry {
    var goalProgressRatio: Double {
        guard goalTarget > 0 else { return 0 }
        return min(goalProgress / Double(goalTarget), 1)
    }

    var formattedGoalProgress: String {
        formatGoalValue(goalProgress)
    }

    var formattedGoalTarget: String {
        formatGoalValue(Double(goalTarget))
    }

    private func formatGoalValue(_ value: Double) -> String {
        let normalizedUnit = goalUnit.lowercased()
        if normalizedUnit == "km" ||
            normalizedUnit == "miles" ||
            normalizedUnit == "mi" ||
            normalizedUnit == "l" {
            return String(format: "%.1f", value)
        }
        return "\(Int(value.rounded(.down)))"
    }
}

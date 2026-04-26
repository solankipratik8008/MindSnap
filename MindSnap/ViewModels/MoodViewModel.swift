//
//  MoodViewModel.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// MoodViewModel.swift
// MindSnap — ViewModel for the Insights/Charts screen
//
// WHAT THIS FILE DOES:
// This ViewModel takes all the journal entries and crunches
// the mood data into formats that charts and summaries can use.
//
// It answers questions like:
//   - What was my mood each day for the last 7 days?
//   - What was my most common mood this week?
//   - What is my average sentiment score this month?
//   - How many days did I feel Happy in the last 30 days?
//
// MVVM ROLE: ViewModel layer
//            InsightsView and MoodChartView bind to this.
//            All the number crunching lives here — zero math
//            in the Views themselves.
//
// WHY A SEPARATE VIEWMODEL?
// JournalViewModel handles CRUD (create/read/update/delete).
// MoodViewModel handles ANALYTICS (trends, averages, charts).
// Keeping them separate follows the
// Single Responsibility Principle — each class does ONE thing.
// ============================================================

import SwiftUI
import SwiftData

// --------------------------------------------------------
// MoodDataPoint — A single point on the mood chart
//
// This is a small helper struct that holds the data for
// ONE bar or point on the chart.
//
// Example: { date: April 14, mood: .happy, score: 0.82 }
//
// WHY A STRUCT?
// Structs are value types — perfect for simple data containers
// that don't need identity or inheritance.
// Identifiable lets ForEach loop over them in SwiftUI.
// --------------------------------------------------------
struct MoodDataPoint: Identifiable {

    // Unique ID required by Identifiable protocol
    // Swift Charts needs this to track each point
    let id = UUID()

    // The date this data point represents
    let date: Date

    // The dominant mood for this day
    let mood: MoodType

    // The average sentiment score for this day
    // Could be average of multiple entries on same day
    let averageScore: Double

    // How many entries were written on this day
    let entryCount: Int

    // --------------------------------------------------------
    // shortLabel — Computed property
    //
    // Returns a short string for the chart's X-axis label.
    // Example: "Mon", "Tue", "Apr 14"
    // --------------------------------------------------------
    var shortLabel: String {
        let formatter = DateFormatter()
        // "EEE" format = abbreviated weekday: Mon, Tue, Wed...
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// --------------------------------------------------------
// MoodSummary — A summary of mood stats for a time period
//
// Used to display the text summary below the chart:
// "You felt Happy 4 out of 7 days this week"
// --------------------------------------------------------
struct MoodSummary {
    // The most frequently occurring mood in the period
    let dominantMood: MoodType

    // How many days had entries in this period
    let daysWithEntries: Int

    // Total days in the period (7 or 30)
    let totalDays: Int

    // Average sentiment score across all entries
    let averageScore: Double

    // How many times the dominant mood appeared
    let dominantMoodCount: Int

    // --------------------------------------------------------
    // summaryText — Human readable summary sentence
    //
    // Builds a natural language sentence from the data.
    // Example: "You felt Happy 4 out of 7 days this week 😊"
    // --------------------------------------------------------
    var summaryText: String {
        return "You felt \(dominantMood.displayName) \(dominantMoodCount) out of \(daysWithEntries) days \(dominantMood.emoji)"
    }

    // --------------------------------------------------------
    // scoreDescription — Describes the average score in words
    //
    // Converts the raw number into friendly language.
    // Example: 0.45 → "Generally positive"
    // --------------------------------------------------------
    var scoreDescription: String {
        switch averageScore {
        case 0.5...1.0:   return "Very positive 🌟"
        case 0.1..<0.5:   return "Generally positive ☀️"
        case -0.1..<0.1:  return "Balanced and neutral 😐"
        case -0.5..<(-0.1): return "Somewhat difficult 🌧️"
        default:          return "Challenging period 💙"
        }
    }
}

// --------------------------------------------------------
// TimePeriod — Enum for switching between 7 and 30 day views
//
// Used by the segmented picker in InsightsView.
// --------------------------------------------------------
enum TimePeriod: String, CaseIterable {
    case week  = "7 Days"
    case month = "30 Days"

    // How many days back to look
    var days: Int {
        switch self {
        case .week:  return 7
        case .month: return 30
        }
    }
}

// --------------------------------------------------------
// MoodViewModel — Main ViewModel class
// --------------------------------------------------------
@Observable
class MoodViewModel {

    // --------------------------------------------------------
    // entries — All journal entries passed from JournalViewModel
    //
    // We receive this from InsightsView which gets it from
    // JournalViewModel. We don't fetch from SwiftData ourselves
    // because JournalViewModel already has the data.
    // No point fetching twice!
    // --------------------------------------------------------
    var entries: [JournalEntry] = []

    // --------------------------------------------------------
    // selectedPeriod — Currently selected time range
    //
    // Changing this automatically updates all computed data
    // because computed properties read this value.
    // --------------------------------------------------------
    var selectedPeriod: TimePeriod = .week

    // --------------------------------------------------------
    // MARK: - Computed Properties for Charts
    // All of these recalculate automatically when entries
    // or selectedPeriod changes.
    // --------------------------------------------------------

    // --------------------------------------------------------
    // chartData
    //
    // Returns an array of MoodDataPoint — one per day —
    // for the selected time period.
    //
    // This is what Swift Charts reads to draw the bar chart.
    //
    // HOW IT WORKS:
    // 1. Generate a list of dates (last 7 or 30 days)
    // 2. For each date, find all entries written that day
    // 3. Calculate the average score and dominant mood
    // 4. Create a MoodDataPoint for that day
    // 5. Return the full array (including empty days)
    // --------------------------------------------------------
    var chartData: [MoodDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Generate all dates in the selected period
        // e.g. for 7 days: [today, yesterday, 2 days ago...]
        var dataPoints: [MoodDataPoint] = []

        for dayOffset in 0..<selectedPeriod.days {
            // Calculate the date for this offset
            // dayOffset 0 = today, 1 = yesterday, etc.
            guard let date = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: today
            ) else { continue }

            // Find all entries written on this specific day
            let dayEntries = entries.filter { entry in
                calendar.startOfDay(for: entry.date) == date
            }

            // Calculate average sentiment score for this day
            // If no entries, score is 0.0 (neutral)
            let avgScore: Double
            if dayEntries.isEmpty {
                avgScore = 0.0
            } else {
                // Reduce adds up all scores, then we divide by count
                let total = dayEntries.reduce(0.0) { sum, entry in
                    sum + entry.sentimentScore
                }
                avgScore = total / Double(dayEntries.count)
            }

            // Find the dominant mood for this day
            // If no entries, default to neutral
            let dominantMood: MoodType
            if dayEntries.isEmpty {
                dominantMood = .neutral
            } else {
                // Count how many times each mood appears
                // and pick the most common one
                dominantMood = mostCommonMood(in: dayEntries)
            }

            // Create the data point for this day
            let dataPoint = MoodDataPoint(
                date: date,
                mood: dominantMood,
                averageScore: avgScore,
                entryCount: dayEntries.count
            )
            dataPoints.append(dataPoint)
        }

        // Reverse so oldest date is first (left side of chart)
        return dataPoints.reversed()
    }

    // --------------------------------------------------------
    // moodSummary
    //
    // Returns a MoodSummary struct with stats for the period.
    // Used to display the text summary below the chart.
    // --------------------------------------------------------
    var moodSummary: MoodSummary {
        // Only look at days that actually have entries
        let pointsWithEntries = chartData.filter {
            $0.entryCount > 0
        }

        // If no entries at all, return a neutral summary
        guard !pointsWithEntries.isEmpty else {
            return MoodSummary(
                dominantMood: .neutral,
                daysWithEntries: 0,
                totalDays: selectedPeriod.days,
                averageScore: 0.0,
                dominantMoodCount: 0
            )
        }

        // Calculate overall average score
        let totalScore = pointsWithEntries.reduce(0.0) {
            $0 + $1.averageScore
        }
        let avgScore = totalScore / Double(pointsWithEntries.count)

        // Find the most common mood across all data points
        let dominant = mostCommonMoodInPoints(pointsWithEntries)

        // Count how many days had the dominant mood
        let dominantCount = pointsWithEntries.filter {
            $0.mood == dominant
        }.count

        return MoodSummary(
            dominantMood: dominant,
            daysWithEntries: pointsWithEntries.count,
            totalDays: selectedPeriod.days,
            averageScore: avgScore,
            dominantMoodCount: dominantCount
        )
    }

    // --------------------------------------------------------
    // moodDistribution
    //
    // Returns a dictionary of how many days each mood appeared.
    // Example: [.happy: 3, .calm: 2, .neutral: 1, .sad: 1]
    //
    // Used to draw the mood distribution bar in InsightsView.
    // --------------------------------------------------------
    var moodDistribution: [MoodType: Int] {
        var distribution: [MoodType: Int] = [:]

        // Initialize all moods to 0
        for mood in MoodType.allCases {
            distribution[mood] = 0
        }

        // Count days for each mood (only days with entries)
        for point in chartData where point.entryCount > 0 {
            distribution[point.mood, default: 0] += 1
        }

        return distribution
    }

    // --------------------------------------------------------
    // totalEntriesInPeriod
    //
    // Total number of journal entries in the selected period.
    // Shown as a stat in the InsightsView header.
    // --------------------------------------------------------
    var totalEntriesInPeriod: Int {
        chartData.reduce(0) { $0 + $1.entryCount }
    }

    // --------------------------------------------------------
    // MARK: - Public Methods
    // --------------------------------------------------------

    // --------------------------------------------------------
    // updateEntries(_:)
    //
    // Called by InsightsView when the entries array changes.
    // Passing entries in keeps this ViewModel in sync with
    // JournalViewModel without needing a second database fetch.
    // --------------------------------------------------------
    func updateEntries(_ newEntries: [JournalEntry]) {
        entries = newEntries
    }

    // --------------------------------------------------------
    // MARK: - Private Helpers
    // --------------------------------------------------------

    // --------------------------------------------------------
    // mostCommonMood(in:)
    //
    // Finds the mood that appears most often in an array
    // of JournalEntry objects.
    //
    // HOW IT WORKS:
    // 1. Count how many times each mood appears
    // 2. Return the mood with the highest count
    // 3. If tied, the first one wins (Swift Dictionary order)
    // --------------------------------------------------------
    private func mostCommonMood(in entries: [JournalEntry]) -> MoodType {
        // Build a frequency dictionary: [.happy: 3, .calm: 1]
        var moodCounts: [MoodType: Int] = [:]
        for entry in entries {
            // If key exists: increment. If not: start at 1.
            moodCounts[entry.moodType, default: 0] += 1
        }

        // Find the mood with the maximum count
        // max(by:) compares dictionary entries by their value
        return moodCounts.max(by: {
            $0.value < $1.value
        })?.key ?? .neutral
    }

    // --------------------------------------------------------
    // mostCommonMoodInPoints(_:)
    //
    // Same as above but for MoodDataPoint arrays instead of
    // JournalEntry arrays. Used in moodSummary calculation.
    // --------------------------------------------------------
    private func mostCommonMoodInPoints(
        _ points: [MoodDataPoint]
    ) -> MoodType {
        var moodCounts: [MoodType: Int] = [:]
        for point in points {
            moodCounts[point.mood, default: 0] += 1
        }
        return moodCounts.max(by: {
            $0.value < $1.value
        })?.key ?? .neutral
    }
}

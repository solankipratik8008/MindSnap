//
//  InsightsView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//
// ============================================================
// InsightsView.swift
// MindSnap — UPDATED WITH CALENDAR VIEW
//
// WHAT CHANGED:
// Added CalendarMoodView below the mood charts.
// Users can now see their mood history in a calendar format
// and tap any day to see what they wrote.
// ============================================================

import SwiftUI
import SwiftData

struct InsightsView: View {

    let entries: [JournalEntry]
    @State private var viewModel = MoodViewModel()

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    if entries.isEmpty {
                        // ---- Empty State ----
                        emptyInsightsState
                    } else {
                        // ---- Stats Header ----
                        statsHeaderSection

                        // ---- Time Period Picker ----
                        periodPickerSection

                        // ---- Mood Chart ----
                        MoodChartView(
                            data: viewModel.chartData,
                            selectedPeriod: viewModel.selectedPeriod
                        )
                        .padding(.horizontal, 16)

                        // ---- Mood Summary ----
                        moodSummarySection

                        // ---- Mood Distribution ----
                        moodDistributionSection

                        // --------------------------------------------------------
                        // Calendar Mood View — NEW
                        //
                        // Shows a full month calendar where each day
                        // with a journal entry shows the mood emoji.
                        // User can tap any day to see their entries.
                        //
                        // This is the most visually impressive feature
                        // in the Insights tab — perfect for App Store
                        // screenshots and portfolio showcase.
                        // --------------------------------------------------------
                        calendarSection

                        // ---- Recent Entries ----
                        recentMoodListSection
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.updateEntries(entries)
        }
        .onChange(of: entries) { _, newEntries in
            viewModel.updateEntries(newEntries)
        }
    }

    // --------------------------------------------------------
    // MARK: - Calendar Section
    //
    // NEW: Beautiful mood calendar showing entire month.
    // Positioned between mood distribution and recent entries
    // so it flows naturally in the scroll view.
    // --------------------------------------------------------
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ---- Section Header ----
            HStack {
                // Calendar icon + title
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "calendar")
                            .foregroundStyle(.purple)
                            .font(.system(size: 16))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mood Calendar")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Tap any day to see your entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            // ---- The Calendar ----
            CalendarMoodView(entries: entries)
                .padding(.horizontal, 16)
        }
    }

    // --------------------------------------------------------
    // MARK: - Empty State
    // --------------------------------------------------------
    private var emptyInsightsState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)

            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 50))
                    .foregroundStyle(.purple.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Insights Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start journaling to see your\nmood trends and patterns here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.title3)
                Text("Write at least 3 entries to\nsee meaningful mood patterns.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.2),
                                    lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    // --------------------------------------------------------
    // MARK: - Stats Header
    // --------------------------------------------------------
    private var statsHeaderSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Entries",
                value: "\(viewModel.totalEntriesInPeriod)",
                subtitle: "in \(viewModel.selectedPeriod.days) days",
                color: .purple,
                icon: "square.and.pencil"
            )
            statCard(
                title: "Avg Score",
                value: String(
                    format: "%+.2f",
                    viewModel.moodSummary.averageScore
                ),
                subtitle: viewModel.moodSummary.scoreDescription,
                color: viewModel.moodSummary.dominantMood.color,
                icon: "chart.line.uptrend.xyaxis"
            )
            statCard(
                title: "Top Mood",
                value: viewModel.moodSummary.dominantMood.emoji,
                subtitle: viewModel.moodSummary.dominantMood.displayName,
                color: viewModel.moodSummary.dominantMood.color,
                icon: "heart.fill"
            )
        }
        .padding(.horizontal, 16)
    }

    private func statCard(
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 5, x: 0, y: 2
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Period Picker
    // --------------------------------------------------------
    private var periodPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Period")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)

            Picker("Period", selection: Binding(
                get: { viewModel.selectedPeriod },
                set: { viewModel.selectedPeriod = $0 }
            )) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
    }

    // --------------------------------------------------------
    // MARK: - Mood Summary
    // --------------------------------------------------------
    private var moodSummarySection: some View {
        VStack(spacing: 12) {
            Text(viewModel.moodSummary.summaryText)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(viewModel.moodSummary.scoreDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    viewModel.moodSummary.dominantMood.color
                        .opacity(0.08)
                )
        )
        .padding(.horizontal, 16)
    }

    // --------------------------------------------------------
    // MARK: - Mood Distribution
    // --------------------------------------------------------
    private var moodDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Breakdown")
                .font(.headline)

            ForEach(MoodType.allCases, id: \.self) { mood in
                let count = viewModel.moodDistribution[mood] ?? 0
                let total = viewModel.selectedPeriod.days

                HStack(spacing: 10) {
                    Text(mood.emoji)
                        .font(.subheadline)
                        .frame(width: 24)

                    Text(mood.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 55, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(mood.color)
                                .frame(
                                    width: total > 0
                                        ? geo.size.width *
                                          CGFloat(count) /
                                          CGFloat(total)
                                        : 0,
                                    height: 8
                                )
                                .animation(
                                    .easeInOut(duration: 0.4),
                                    value: count
                                )
                        }
                    }
                    .frame(height: 8)

                    Text("\(count)d")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal, 16)
    }

    // --------------------------------------------------------
    // MARK: - Recent Entries List
    // --------------------------------------------------------
    private var recentMoodListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.headline)

            let recentEntries = Array(entries.prefix(5))

            if recentEntries.isEmpty {
                Text("No entries yet. Start journaling!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(recentEntries) { entry in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(entry.moodType.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Text(entry.moodType.emoji)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.shortDate)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(entry.previewText)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text(String(format: "%+.2f",
                                    entry.sentimentScore))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.moodType.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(entry.moodType.color
                                        .opacity(0.12))
                            )
                    }
                    .padding(.vertical, 4)

                    if entry.id != recentEntries.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal, 16)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: JournalEntry.self,
        configurations: config
    )

    let samples: [(String, MoodType, Double)] = [
        ("Amazing day! Got the promotion!", .happy, 0.88),
        ("Peaceful morning walk.", .calm, 0.35),
        ("Just a regular Tuesday.", .neutral, 0.02),
        ("Deadline stress today.", .anxious, -0.41),
        ("Really missing home.", .sad, -0.63),
        ("Had lunch with an old friend.", .happy, 0.72),
        ("Quiet evening reading.", .calm, 0.29)
    ]

    let entries = samples.map { text, mood, score in
        JournalEntry(
            text: text,
            moodType: mood,
            sentimentScore: score
        )
    }

    InsightsView(entries: entries)
        .modelContainer(container)
}

//
//  InsightsView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//
// ============================================================
// InsightsView.swift
// MindSnap — Premium Monochrome Insights
//
// SAFE UI UPDATE:
// 1. Keeps the same MoodViewModel logic
// 2. Keeps chart, summary, distribution, calendar, recent entries
// 3. Keeps CalendarMoodView integration
// 4. Updates UI to professional black/white theme
// 5. Mood colors remain only as useful emotional accents
// ============================================================

import SwiftUI
import SwiftData

struct InsightsView: View {

    let entries: [JournalEntry]

    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = MoodViewModel()

    // --------------------------------------------------------
    // MARK: - Premium Theme
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

    private var softBackground: Color {
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

    private func premiumCard(cornerRadius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: 12,
                x: 0,
                y: 6
            )
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    if entries.isEmpty {
                        emptyInsightsState
                    } else {
                        statsHeaderSection
                        periodPickerSection

                        MoodChartView(
                            data: viewModel.chartData,
                            selectedPeriod: viewModel.selectedPeriod
                        )
                        .padding(.horizontal, 16)

                        moodSummarySection
                        moodDistributionSection
                        calendarSection
                        recentMoodListSection
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(appBackground)
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
    // --------------------------------------------------------
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(primaryButtonBackground)
                            .frame(width: 34, height: 34)

                        Image(systemName: "calendar")
                            .foregroundStyle(primaryButtonText)
                            .font(.system(size: 16, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mood Calendar")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)

                        Text("Tap any day to see your entries")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)

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
                    .fill(softBackground)
                    .frame(width: 122, height: 122)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(primaryText.opacity(0.78))
            }

            VStack(spacing: 8) {
                Text("No Insights Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Text("Start journaling to see your mood trends and patterns here.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)

                Text("Write at least 3 entries to see meaningful mood patterns.")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.orange.opacity(0.18), lineWidth: 1)
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
                color: primaryText,
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
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(subtitle)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(premiumCard(cornerRadius: 18))
    }

    // --------------------------------------------------------
    // MARK: - Period Picker
    // --------------------------------------------------------
    private var periodPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time Period")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(primaryText)
                .padding(.horizontal, 16)

            Picker("Period", selection: Binding(
                get: { viewModel.selectedPeriod },
                set: { viewModel.selectedPeriod = $0 }
            )) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .tint(primaryText)
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
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(viewModel.moodSummary.scoreDescription)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    viewModel.moodSummary.dominantMood.color
                        .opacity(colorScheme == .dark ? 0.13 : 0.075)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            viewModel.moodSummary.dominantMood.color
                                .opacity(colorScheme == .dark ? 0.18 : 0.13),
                            lineWidth: 1
                        )
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
                .foregroundStyle(primaryText)

            ForEach(MoodType.allCases, id: \.self) { mood in
                let count = viewModel.moodDistribution[mood] ?? 0
                let total = viewModel.selectedPeriod.days

                HStack(spacing: 10) {
                    Text(mood.emoji)
                        .font(.subheadline)
                        .frame(width: 24)

                    Text(mood.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .frame(width: 55, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(softBackground)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(mood.color.opacity(colorScheme == .dark ? 0.90 : 0.78))
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
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 20))
        .padding(.horizontal, 16)
    }

    // --------------------------------------------------------
    // MARK: - Recent Entries List
    // --------------------------------------------------------
    private var recentMoodListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.headline)
                .foregroundStyle(primaryText)

            let recentEntries = Array(entries.prefix(5))

            if recentEntries.isEmpty {
                Text("No entries yet. Start journaling!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(recentEntries) { entry in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(entry.moodType.color.opacity(colorScheme == .dark ? 0.18 : 0.11))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            entry.moodType.color.opacity(0.18),
                                            lineWidth: 1
                                        )
                                )

                            Text(entry.moodType.emoji)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.shortDate)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(secondaryText)

                            Text(entry.previewText)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(primaryText)
                        }

                        Spacer()

                        Text(String(format: "%+.2f", entry.sentimentScore))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.moodType.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(entry.moodType.color.opacity(colorScheme == .dark ? 0.16 : 0.10))
                            )
                    }
                    .padding(.vertical, 4)

                    if entry.id != recentEntries.last?.id {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
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

    NavigationStack {
        InsightsView(entries: entries)
            .modelContainer(container)
    }
}

#Preview("Dark Mode") {
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
        ("Really missing home.", .sad, -0.63)
    ]

    let entries = samples.map { text, mood, score in
        JournalEntry(
            text: text,
            moodType: mood,
            sentimentScore: score
        )
    }

    NavigationStack {
        InsightsView(entries: entries)
            .modelContainer(container)
    }
    .preferredColorScheme(.dark)
}

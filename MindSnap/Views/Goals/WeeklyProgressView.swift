//
//  WeeklyProgressView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//

// ============================================================
// WeeklyProgressView.swift
// MindSnap — STREAK FIXED + OVERALL STREAK DISPLAY
//
// WHAT CHANGED:
// 1. Fixed streak badge — now shows correctly always
// 2. Added overall streak from GoalViewModel
// 3. Fixed dark mode card colors
// 4. Added partial points info
// 5. Better weekly completion display
// ============================================================

import SwiftUI
import SwiftData

struct WeeklyProgressView: View {

    let viewModel: GoalViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var animatedPoints: Int = 0
    @State private var animatedStreak: Int = 0

    private let weekDayLabels = [
        "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"
    ]
    
    private var brandPrimary: Color {
        Color(red: 0.50, green: 0.12, blue: 0.85)
    }

    private var brandSecondary: Color {
        Color(red: 0.88, green: 0.12, blue: 0.68)
    }

    private var brandAccent: Color {
        Color(red: 0.10, green: 0.78, blue: 0.85)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBanner
            weeklyOverview
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBackground)
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.35)
                        : brandPrimary.opacity(0.10),
                    radius: 14,
                    x: 0,
                    y: 6
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedPoints = viewModel.totalPoints
                animatedStreak = viewModel.overallStreak
            }
        }
        .onChange(of: viewModel.totalPoints) { _, newPoints in
            withAnimation(.spring(duration: 0.5)) {
                animatedPoints = newPoints
            }
        }
        .onChange(of: viewModel.overallStreak) { _, newStreak in
            withAnimation(.spring(duration: 0.5)) {
                animatedStreak = newStreak
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Card Background
    // --------------------------------------------------------
    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.13, green: 0.12, blue: 0.16)
            : Color.white
    }
    // --------------------------------------------------------
    // MARK: - Top Banner
    // --------------------------------------------------------
    private var topBanner: some View {
        ZStack {
            LinearGradient(
                colors: [
                    brandPrimary.opacity(colorScheme == .dark ? 0.95 : 0.92),
                    brandSecondary.opacity(colorScheme == .dark ? 0.86 : 0.84),
                    brandAccent.opacity(colorScheme == .dark ? 0.30 : 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Minimal premium shine instead of large bubbles
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18),
                    Color.white.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.20 : 0.30),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .padding(0.5)

            VStack(spacing: 10) {

                HStack(alignment: .center, spacing: 12) {

                    HStack(spacing: 9) {
                        Text(viewModel.currentLevel.emoji)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentLevel.rawValue)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Current Level")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 1) {
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.subheadline)

                            Text("\(animatedStreak)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }

                        Text("day streak")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.13 : 0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    )

                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(spacing: 4) {
                            Text("\(animatedPoints)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                                .monospacedDigit()

                            Text("⭐")
                                .font(.title3)
                        }

                        Text("Total Points")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.74))
                    }
                }

                VStack(spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.22))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.white.opacity(0.86)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(
                                        8,
                                        geo.size.width *
                                        CGFloat(UserPoints.progressToNextLevel)
                                    ),
                                    height: 8
                                )
                                .shadow(
                                    color: .white.opacity(0.18),
                                    radius: 4,
                                    x: 0,
                                    y: 1
                                )
                                .animation(
                                    .spring(duration: 0.8),
                                    value: viewModel.totalPoints
                                )
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(viewModel.currentLevel.message)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(1)

                        Spacer()

                        if viewModel.currentLevel != .champion {
                            Text("\(UserPoints.pointsToNextLevel) pts to next level")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.76))
                                .lineLimit(1)
                        } else {
                            Text("Max Level! 🏆")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.82))
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 140)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22
            )
        )
    }

    // --------------------------------------------------------
    // MARK: - Weekly Overview
    // --------------------------------------------------------
    private var weeklyOverview: some View {
        VStack(spacing: 14) {

            // Today completion row
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("This Week")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(
                        "\(viewModel.completedTodayCount) of " +
                        "\(viewModel.todaysGoals.count) goals today"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Completion ring
                ZStack {
                    Circle()
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color(.systemGray5),
                            lineWidth: 5
                        )
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(
                            from: 0,
                            to: CGFloat(
                                viewModel.weeklyCompletionRate
                            )
                        )
                        .stroke(
                            LinearGradient(
                                colors: [brandPrimary, brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 5,
                                lineCap: .round
                            )
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(
                            .spring(duration: 0.8),
                            value: viewModel.weeklyCompletionRate
                        )

                    Text(
                        "\(Int(viewModel.weeklyCompletionRate * 100))%"
                    )
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(brandSecondary)
                }
            }

            Divider()
                .background(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color(.systemGray5)
                )

            // Day dots grid
            dayDotsGrid

            // Partial points info
            if hasPartialProgress {
                partialPointsInfo
                    .transition(.opacity.combined(
                        with: .move(edge: .bottom)
                    ))
            }

            // All done banner
            if viewModel.allGoalsCompletedToday &&
               !viewModel.todaysGoals.isEmpty {
                allDoneBanner
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .animation(
            .spring(duration: 0.3),
            value: viewModel.allGoalsCompletedToday
        )
    }

    // --------------------------------------------------------
    // MARK: - Day Dots Grid
    // --------------------------------------------------------
    private var dayDotsGrid: some View {
        VStack(spacing: 10) {

            // Day labels
            HStack(spacing: 0) {
                ForEach(
                    Array(weekDayLabels.enumerated()),
                    id: \.offset
                ) { index, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(
                            isToday(index: index)
                                ? .bold : .regular
                        )
                        .foregroundStyle(
                            isToday(index: index)
                                 ? brandSecondary
                                : Color.secondary
                        )
                        .frame(maxWidth: .infinity)
                }
            }

            if viewModel.todaysGoals.isEmpty {
                Text("Add goals to see your weekly progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(
                    viewModel.todaysGoals.prefix(3)
                ) { goal in
                    goalWeekRow(goal: goal)
                }

                if viewModel.todaysGoals.count > 3 {
                    Text(
                        "+ \(viewModel.todaysGoals.count - 3)" +
                        " more goals"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                }
            }
        }
    }

    private func goalWeekRow(goal: Goal) -> some View {
        HStack(spacing: 0) {
            ForEach(
                Array(
                    viewModel.weeklyCompletions(for: goal)
                        .enumerated()
                ),
                id: \.offset
            ) { index, completed in
                let isTodayIndex = currentDayIndex() == index
                let isFuture = index > currentDayIndex()

                ZStack {
                    Circle()
                        .fill(
                            isFuture
                                ? Color(.systemGray5).opacity(
                                    colorScheme == .dark
                                        ? 0.3 : 0.5
                                  )
                                : completed
                                    ? goal.color
                                    : colorScheme == .dark
                                        ? Color.white.opacity(0.12)
                                        : Color(.systemGray4)
                                            .opacity(0.4)
                        )
                        .frame(width: 10, height: 10)
                        .animation(
                            .spring(duration: 0.3),
                            value: completed
                        )

                    if isTodayIndex {
                        Circle()
                            .stroke(goal.color, lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Partial Points Info
    // --------------------------------------------------------
    private var hasPartialProgress: Bool {
        viewModel.todaysGoals.contains { goal in
            let progress = viewModel.todaysProgress(for: goal)
            return progress > 0 &&
                !viewModel.isCompletedToday(goal) &&
                goal.goalType == .progress
        }
    }

    private var partialPointsInfo: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.todaysGoals) { goal in
                let progress = viewModel.todaysProgress(for: goal)
                if progress > 0 &&
                   !viewModel.isCompletedToday(goal) &&
                   goal.goalType == .progress {
                    let partial = goal.partialPoints(
                        for: progress
                    )
                    if partial > 0 {
                        HStack(spacing: 6) {
                            Text(goal.emoji)
                                .font(.caption)
                            Text(
                                "\(progress)/\(goal.targetValue)" +
                                " \(goal.unit)"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            Spacer()
                            Text("~\(partial) pts at day end")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(
                    colorScheme == .dark ? 0.12 : 0.07
                ))
        )
    }

    // --------------------------------------------------------
    // MARK: - All Done Banner
    // --------------------------------------------------------
    private var allDoneBanner: some View {
        HStack(spacing: 8) {
            Text("🎉")
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 1) {
                Text("All goals completed today!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Bonus +25 ⭐ awarded")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+25 ⭐")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(brandSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            brandPrimary.opacity(colorScheme == .dark ? 0.18 : 0.07),
                            brandSecondary.opacity(colorScheme == .dark ? 0.16 : 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brandSecondary.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------
    private func isToday(index: Int) -> Bool {
        index == currentDayIndex()
    }

    private func currentDayIndex() -> Int {
        let weekday = Calendar.current.component(
            .weekday, from: Date()
        )
        return (weekday + 5) % 7
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self, GoalCompletion.self,
        configurations: config
    )
    let viewModel = GoalViewModel(
        modelContext: container.mainContext
    )
    ScrollView {
        WeeklyProgressView(viewModel: viewModel)
            .padding(16)
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}

#Preview("Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self, GoalCompletion.self,
        configurations: config
    )
    let viewModel = GoalViewModel(
        modelContext: container.mainContext
    )
    ScrollView {
        WeeklyProgressView(viewModel: viewModel)
            .padding(16)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
    .modelContainer(container)
}

//
//  WeeklyProgressView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//

// ============================================================
// WeeklyProgressView.swift
// MindSnap — Premium Monochrome Weekly Progress Card
//
// UI UPDATE:
// 1. Matches the new black/white professional MindSnap theme
// 2. Removes purple/pink heavy branding
// 3. Keeps achievement colors as small meaningful accents
// 4. Improves light/dark mode card contr ast
// 5. Keeps same progress/streak/points display
//
// FUNCTIONALITY KEPT:
// 1. Animated total points
// 2. Animated overall streak
// 3. Weekly completion rate
// 4. Weekly goal dots
// 5. Partial points info
// 6. All goals completed banner
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

    // --------------------------------------------------------
    // MARK: - Theme
    // --------------------------------------------------------
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

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.06)
    }

    private var progressTrackColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.10)
        : Color.black.opacity(0.065)
    }

    private var progressFillColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        VStack(spacing: 0) {
            topBanner

            weeklyOverview
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
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
    // MARK: - Top Banner
    // --------------------------------------------------------
    private var topBanner: some View {
        VStack(spacing: 14) {

            HStack(alignment: .center, spacing: 12) {

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(softBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(borderColor, lineWidth: 1)
                            )

                        Text(viewModel.currentLevel.emoji)
                            .font(.system(size: 26))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.currentLevel.rawValue)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)

                        Text("Current Level")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.subheadline)

                        Text("\(animatedStreak)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }

                    Text("day streak")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(softBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(animatedPoints)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                            .contentTransition(.numericText())
                            .monospacedDigit()

                        Text("⭐")
                            .font(.title3)
                    }

                    Text("Points")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
            }

            VStack(spacing: 7) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(progressTrackColor)
                            .frame(height: 8)

                        Capsule()
                            .fill(progressFillColor)
                            .frame(
                                width: max(
                                    8,
                                    geo.size.width *
                                    CGFloat(UserPoints.progressToNextLevel)
                                ),
                                height: 8
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
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)

                    Spacer()

                    if viewModel.currentLevel != .champion {
                        Text("\(UserPoints.pointsToNextLevel) pts to next")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(softBackground)
                                    .overlay(
                                        Capsule()
                                            .stroke(borderColor, lineWidth: 1)
                                    )
                            )
                    } else {
                        Text("Max Level 🏆")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(softBackground)
                                    .overlay(
                                        Capsule()
                                            .stroke(borderColor, lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                cardBackground

                LinearGradient(
                    colors: [
                        progressFillColor.opacity(colorScheme == .dark ? 0.10 : 0.045),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    // --------------------------------------------------------
    // MARK: - Weekly Overview
    // --------------------------------------------------------
    private var weeklyOverview: some View {
        VStack(spacing: 14) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)

                    Text(
                        "\(viewModel.completedTodayCount) of " +
                        "\(viewModel.todaysGoals.count) goals today"
                    )
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                }

                Spacer()

                completionRing
            }

            Divider()
                .background(borderColor)

            dayDotsGrid

            if hasPartialProgress {
                partialPointsInfo
                    .transition(
                        .opacity.combined(with: .move(edge: .bottom))
                    )
            }

            if viewModel.allGoalsCompletedToday &&
               !viewModel.todaysGoals.isEmpty {
                allDoneBanner
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
        )
        .animation(
            .spring(duration: 0.3),
            value: viewModel.allGoalsCompletedToday
        )
    }

    // --------------------------------------------------------
    // MARK: - Completion Ring
    // --------------------------------------------------------
    private var completionRing: some View {
        ZStack {
            Circle()
                .stroke(progressTrackColor, lineWidth: 5)
                .frame(width: 52, height: 52)

            Circle()
                .trim(
                    from: 0,
                    to: CGFloat(viewModel.weeklyCompletionRate)
                )
                .stroke(
                    progressFillColor,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round
                    )
                )
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))
                .animation(
                    .spring(duration: 0.8),
                    value: viewModel.weeklyCompletionRate
                )

            Text("\(Int(viewModel.weeklyCompletionRate * 100))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(primaryText)
        }
    }

    // --------------------------------------------------------
    // MARK: - Day Dots Grid
    // --------------------------------------------------------
    private var dayDotsGrid: some View {
        VStack(spacing: 10) {

            HStack(spacing: 0) {
                ForEach(
                    Array(weekDayLabels.enumerated()),
                    id: \.offset
                ) { index, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(
                            isToday(index: index)
                            ? .bold
                            : .regular
                        )
                        .foregroundStyle(
                            isToday(index: index)
                            ? primaryText
                            : secondaryText
                        )
                        .frame(maxWidth: .infinity)
                }
            }

            if viewModel.todaysGoals.isEmpty {
                Text("Add goals to see your weekly progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
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
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
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
                            ? softBackground
                            : completed
                                ? goal.color.opacity(colorScheme == .dark ? 0.90 : 0.78)
                                : progressTrackColor
                        )
                        .frame(width: 10, height: 10)
                        .animation(
                            .spring(duration: 0.3),
                            value: completed
                        )

                    if isTodayIndex {
                        Circle()
                            .stroke(
                                goal.color.opacity(0.82),
                                lineWidth: 1.5
                            )
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
                    let partial = goal.partialPoints(for: progress)

                    if partial > 0 {
                        HStack(spacing: 6) {
                            Text(goal.emoji)
                                .font(.caption)

                            Text(
                                "\(progress.formatted(.number.precision(.fractionLength(0...1))))/\(goal.targetValue) \(goal.unit)"
                            )
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                            Spacer()

                            Text("~\(partial) pts at day end")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange.opacity(0.92))
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.065))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            Color.orange.opacity(colorScheme == .dark ? 0.16 : 0.18),
                            lineWidth: 1
                        )
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - All Done Banner
    // --------------------------------------------------------
    private var allDoneBanner: some View {
        HStack(spacing: 9) {
            Text("🎉")
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text("All goals completed today!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)

                Text("Bonus +25 ⭐ awarded")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            Text("+25 ⭐")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(primaryText)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(softBackground)
                        .overlay(
                            Capsule()
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(softBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 1)
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
            .weekday,
            from: Date()
        )
        return (weekday + 5) % 7
    }
}

// ============================================================
// MARK: - Preview
// ============================================================
#Preview("Light") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self,
        GoalCompletion.self,
        configurations: config
    )

    let viewModel = GoalViewModel(
        modelContext: container.mainContext
    )

    ScrollView {
        WeeklyProgressView(viewModel: viewModel)
            .padding(16)
    }
    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
    .modelContainer(container)
}

#Preview("Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self,
        GoalCompletion.self,
        configurations: config
    )

    let viewModel = GoalViewModel(
        modelContext: container.mainContext
    )

    ScrollView {
        WeeklyProgressView(viewModel: viewModel)
            .padding(16)
    }
    .background(Color(red: 0.03, green: 0.03, blue: 0.035))
    .preferredColorScheme(.dark)
    .modelContainer(container)
}

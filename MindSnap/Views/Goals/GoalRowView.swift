//
//  GoalRowView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//
// ============================================================
// GoalRowView.swift
// MindSnap — ALL PADDING FIXED + EXPIRY ANIMATION
//
// FIXES:
// 1. All padding syntax fixed (no more crashes)
// 2. Priority banner working correctly
// 3. Partial points preview working
// 4. Manual edit honesty popup working
// 5. Lock warning working
// 6. Expiry pulse animation working
// 7. Dark mode fully working
// ============================================================

import SwiftUI
import SwiftData
import UIKit

struct GoalRowView: View {

    let goal: Goal
    let viewModel: GoalViewModel
    var isTomorrowPreview: Bool = false
    var isCompact: Bool = false

    @State private var completionPulse = false
    @State private var showingBurst = false
    @State private var showingPoints = false
    @State private var isPressed = false
    @State private var showingLockedWarning = false
    @State private var expiryPulse = false
    @State private var showingManualEditSheet = false
    @State private var manualEditValue: Double = 0
    @State private var manualEditText: String = "0"
    @State private var isResyncingHealth = false

    @FocusState private var isManualEditFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var isHealthTrackedGoal: Bool {
        goal.isHealthKitLinked ||
        HealthKitService.healthSupportedActivityTypes.contains(goal.activityType) ||
        isCaloriesUnit(goal.unit)
    }

    private var caloriesBurned: Double {
        viewModel.caloriesBurned(for: goal)
    }

    private var shouldShowCalories: Bool {
        guard !isTomorrowPreview else { return false }
        guard caloriesBurned > 0 else { return false }

        switch goal.activityType {
        case .walking, .running, .cycling, .swimming, .gym, .yoga:
            return true
        default:
            return isCaloriesUnit(goal.unit)
        }
    }
    private var todaysProgress: Double {
        if isTomorrowPreview {
            return 0
        }

        return viewModel.todaysProgressValue(for: goal)
    }

    private var isCompleted: Bool {
        if isTomorrowPreview {
            return false
        }

        return viewModel.isCompletedToday(goal)
    }

    private var isLocked: Bool {
        if isTomorrowPreview {
            return false
        }

        return viewModel.isLockedForEditing(goal)
    }

    private var isExpiring: Bool {
        viewModel.isAboutToExpire(goal)
    }

    private var weeklyDots: [Bool] {
        viewModel.weeklyCompletions(for: goal)
    }

    private var streak: Int {
        viewModel.streakCount(for: goal)
    }

    private var partialPoints: Int {
        viewModel.partialPointsFor(goal)
    }

    private var progressPercent: Double {
        guard goal.targetValue > 0 else { return 0 }
        return min(1, max(0, todaysProgress / Double(goal.targetValue)))
    }

    private var progressPercentText: String {
        "\(Int((progressPercent * 100).rounded()))%"
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {
            cardContent
                .contentShape(Rectangle())

            if !isTomorrowPreview {
                ActivityCompletionView(
                    style: goal.animationStyle,
                    color: goal.color,
                    isShowing: showingBurst
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(showingBurst ? 1 : 0)
                .allowsHitTesting(false)
                .zIndex(10)
            }

            VStack {
                PointsPopupView(
                    points: max(viewModel.lastPointsEarned, 1),
                    isShowing: showingPoints
                )
                Spacer()
            }
            .opacity(showingPoints ? 1 : 0)
            .allowsHitTesting(false)
            .zIndex(11)



            if showingLockedWarning {
                VStack {
                    Spacer()
                    lockedWarningToast
                        .padding(.bottom, 8)
                }
                .transition(
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                )
            }
        }
        .onAppear {
            if isExpiring && !isCompleted {
                startExpiryPulse()
            }
            manualEditValue = todaysProgress
            manualEditText = formattedProgress(todaysProgress)
        }
        .sheet(isPresented: $showingManualEditSheet) {
            honestyEditSheet
        }
        .sheet(
            isPresented: Binding(
                get: {
                    viewModel.showingHonestyPopup &&
                    viewModel.pendingManualGoal?.id == goal.id
                },
                set: { showing in
                    if !showing {
                        viewModel.cancelManualOverride()
                    }
                }
            )
        ) {
            honestyConfirmSheet
        }
    }

    // --------------------------------------------------------
    // MARK: - Card Content
    // --------------------------------------------------------
    private var cardContent: some View {
        Group {
            if isCompact {
                compactCardContent
            } else {
                fullCardContent
            }
        }
    }

    private var fullCardContent: some View {
        VStack(spacing: 0) {

            // Priority banner (High only)
            if goal.priority == .high && !isTomorrowPreview {
                priorityBanner
            }

            // Top Row
            HStack(spacing: 12) {
                goalIcon
                goalInfo
                Spacer()
                if isTomorrowPreview {
                    tomorrowBadge
                } else {
                    actionControl
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Progress bar
            if goal.goalType == .progress && !isTomorrowPreview {
                progressBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }

            // Partial points preview
            if goal.goalType == .progress &&
               !isTomorrowPreview &&
               !isCompleted &&
               partialPoints > 0 {
                partialPointsPreview
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }

            // Manual edit button
            if goal.goalType == .progress &&
               !isTomorrowPreview &&
               !isLocked {
                manualEditButton
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }

            if isHealthTrackedGoal &&
               goal.goalType == .progress &&
               !isTomorrowPreview &&
               !isLocked {
                healthSyncActionRow
                    .padding(.horizontal, 14)
                    .padding(.bottom, 7)
            }

            // Weekly dots
            weeklyDotsRow
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

            // Expiry warning
            if isExpiring && !isCompleted && !isTomorrowPreview {
                expiryWarningBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardBorderColor, lineWidth: 1.5)
        )
        .overlay(
            // Expiry pulse border
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    Color.orange.opacity(
                        isExpiring && !isCompleted &&
                        expiryPulse ? 0.8 : 0
                    ),
                    lineWidth: 2
                )
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: expiryPulse
                )
        )
        .shadow(
            color: cardShadowColor,
            radius: isCompleted ? 8 : 3,
            x: 0, y: 2
        )
        .scaleEffect(completionPulse ? 1.035 : (isPressed ? 0.97 : 1.0))
        .opacity(isTomorrowPreview ? 0.5 : 1.0)
        .shadow(
            color: completionPulse
                ? goal.color.opacity(colorScheme == .dark ? 0.28 : 0.22)
                : cardShadowColor,
            radius: completionPulse ? 14 : (isCompleted ? 8 : 3),
            x: 0,
            y: completionPulse ? 6 : 2
        )
        .animation(.spring(duration: 0.2), value: isPressed)
        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: completionPulse)
        .animation(.spring(duration: 0.3), value: isCompleted)
    }

    // --------------------------------------------------------
    // MARK: - Compact Card Content
    // --------------------------------------------------------
    private var compactCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                compactGoalIcon

                Spacer(minLength: 6)

                if isTomorrowPreview {
                    compactTomorrowBadge
                } else {
                    compactCompletionButton
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isCompleted ? goal.color : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 4) {
                    if streak > 0 && !isTomorrowPreview {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)

                        Text("\(streak)d streak")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(isTomorrowPreview ? "Tomorrow" : goal.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            if goal.goalType == .progress {
                compactProgressRing
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("\(formattedProgress(todaysProgress)) / \(formattedProgress(Double(goal.targetValue))) \(goal.unit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Spacer(minLength: 8)

                Text(isCompleted ? "Completed" : "Tap to complete")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isCompleted ? goal.color : .secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 8)
            }

            if !isTomorrowPreview && goal.goalType == .progress && !isLocked {
                compactActionsRow
            }

            if shouldShowCalories {
                compactCaloriesRow
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(compactCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(compactCardBorderColor, lineWidth: 1)
        )
        .shadow(
            color: completionPulse
                ? goal.color.opacity(colorScheme == .dark ? 0.26 : 0.20)
                : (colorScheme == .dark ? .clear : goal.color.opacity(0.07)),
            radius: completionPulse ? 14 : 8,
            x: 0,
            y: completionPulse ? 7 : 4
        )
        .scaleEffect(completionPulse ? 1.04 : (isPressed ? 0.97 : 1.0))
        .opacity(isTomorrowPreview ? 0.58 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: completionPulse)
        .animation(.spring(duration: 0.3), value: isCompleted)
    }

    private var compactGoalIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            goal.color.opacity(colorScheme == .dark ? 0.24 : 0.14),
                            goal.secondaryColor.opacity(colorScheme == .dark ? 0.14 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(goal.color)
            } else if goal.emoji.count == 1 &&
                      goal.emoji.unicodeScalars.first?.properties.isEmoji == true {
                Text(goal.emoji)
                    .font(.system(size: 19))
            } else {
                Image(systemName: goal.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(goal.color)
            }
        }
    }

    private var compactCompletionButton: some View {
        Button {
            if goal.goalType == .checkbox {
                handleCheckboxTap()
            } else if isLocked {
                showLockedWarning()
            }
        } label: {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isCompleted ? goal.color : Color(.systemGray3))
        }
        .buttonStyle(.plain)
    }

    private var compactTomorrowBadge: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(7)
            .background(
                Circle()
                    .fill(Color(.systemGray5).opacity(colorScheme == .dark ? 0.25 : 0.8))
            )
    }

    private var compactProgressRing: some View {
        ZStack {
            Circle()
                .stroke(
                    colorScheme == .dark
                    ? Color.white.opacity(0.10)
                    : Color.black.opacity(0.06),
                    lineWidth: 7
                )
                .frame(width: 74, height: 74)

            Circle()
                .trim(from: 0, to: progressPercent)
                .stroke(
                    LinearGradient(
                        colors: [
                            goal.color.opacity(0.92),
                            goal.secondaryColor.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .frame(width: 74, height: 74)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.45), value: progressPercent)

            VStack(spacing: 1) {
                Text(progressPercentText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(goal.color)

                if !goal.unit.isEmpty {
                    Text(goal.unit)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var compactActionsRow: some View {
        if isHealthTrackedGoal {
            HStack(spacing: 6) {
                compactEditButton
                compactSyncButton
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            HStack(spacing: 6) {
                Button {
                    if isLocked {
                        showLockedWarning()
                    } else {
                        viewModel.decrementProgress(goal)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(.systemGray5).opacity(colorScheme == .dark ? 0.25 : 0.9)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(todaysProgress > 0 ? goal.color : Color(.systemGray3))
                .disabled(todaysProgress == 0 && !isLocked)

                compactEditButton

                Button {
                    if isLocked {
                        showLockedWarning()
                    } else {
                        handleProgressIncrement()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(goal.color.opacity(colorScheme == .dark ? 0.13 : 0.08)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(goal.color)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var compactEditButton: some View {
        Button {
            manualEditValue = todaysProgress
            manualEditText = rawProgressInput(todaysProgress)
            showingManualEditSheet = true
        } label: {
            Label("Edit", systemImage: "pencil")
                .font(.system(size: 10, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray5).opacity(colorScheme == .dark ? 0.25 : 0.9))
        )
    }

    private var compactSyncButton: some View {
        Button {
            resyncHealthFromCard()
        } label: {
            HStack(spacing: 4) {
                if isResyncingHealth {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }

                Text("Sync")
            }
            .font(.system(size: 10, weight: .semibold))
            .lineLimit(1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(goal.color)
        .disabled(isResyncingHealth || viewModel.isHealthSyncInProgress)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(goal.color.opacity(colorScheme == .dark ? 0.13 : 0.08))
        )
    }

    private var compactCaloriesRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.orange.opacity(0.9))

            Text("\(Int(caloriesBurned)) cal")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var compactCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    colorScheme == .dark
                    ? Color(red: 0.15, green: 0.15, blue: 0.17)
                    : Color.white
                )

            LinearGradient(
                colors: [
                    goal.color.opacity(colorScheme == .dark ? 0.10 : 0.035),
                    Color(red: 0.88, green: 0.12, blue: 0.68)
                        .opacity(colorScheme == .dark ? 0.05 : 0.025),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    private var compactCardBorderColor: Color {
        if isCompleted {
            return goal.color.opacity(colorScheme == .dark ? 0.25 : 0.14)
        }

        if goal.priority == .high {
            return Color.red.opacity(colorScheme == .dark ? 0.22 : 0.16)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.045)
    }

    // --------------------------------------------------------
    // MARK: - Priority Banner
    // --------------------------------------------------------
    private var priorityBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: goal.priority.icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(goal.priority.color.opacity(0.85))

            Text("\(goal.priority.emoji) \(goal.priority.displayName) Priority")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(goal.priority.color.opacity(0.85))

            Spacer()

            if goal.activityType == .medicine {
                Text("💊 Reminder")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(goal.priority.color.opacity(0.75))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(
            goal.priority.color.opacity(
                colorScheme == .dark ? 0.10 : 0.045
            )
        )
    }

    // --------------------------------------------------------
    // MARK: - Locked Warning Toast
    // --------------------------------------------------------
    private var lockedWarningToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.white)
                .font(.caption)
            Text("Completed — editing locked ✅")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.9))
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .allowsHitTesting(false)
    }

    // --------------------------------------------------------
    // MARK: - Expiry Warning Bar
    // --------------------------------------------------------
    private var expiryWarningBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.caption2)
                .foregroundStyle(.orange)

            Text(
                "Expires in ~" +
                "\(viewModel.minutesUntilMidnight / 60)h " +
                "\(viewModel.minutesUntilMidnight % 60)m"
            )
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.orange)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(
                    colorScheme == .dark ? 0.15 : 0.08
                ))
        )
    }

    // --------------------------------------------------------
    // MARK: - Tomorrow Badge
    // --------------------------------------------------------
    private var tomorrowBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "moon.stars.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Tomorrow")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray5))
        )
    }

    // --------------------------------------------------------
    // MARK: - Goal Icon
    // --------------------------------------------------------
    // --------------------------------------------------------
    // MARK: - Goal Icon
    //
    // FIX: Added .padding(4) buffer + clipShape removed from
    // parent to stop emoji/icon being clipped at edges
    // --------------------------------------------------------
    private var goalIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            goal.color.opacity(
                                colorScheme == .dark ? 0.35 : 0.18
                            ),
                            goal.secondaryColor.opacity(
                                colorScheme == .dark ? 0.2 : 0.1
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50) // FIX: was 48, needs buffer

            if isCompleted {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                goal.color,
                                goal.secondaryColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                // FIX: Use Text for emoji goals, Image for SF Symbols
                if goal.emoji.count == 1 &&
                   goal.emoji.unicodeScalars.first?.properties.isEmoji == true {
                    Text(goal.emoji)
                        .font(.system(size: 22))
                } else {
                    Image(systemName: goal.sfSymbol)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            goal.color,
                            goal.secondaryColor
                        )
                        .font(.system(size: 20, weight: .semibold))
                }
            }

            // Lock badge on completed
            if isLocked && !isTomorrowPreview {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(
                                Circle().fill(Color.green)
                            )
                            .offset(x: 4, y: 4)
                    }
                }
                .frame(width: 50, height: 50)
            }
        }
        .frame(width: 54, height: 54) // FIX: outer frame larger than inner circle
        // NO clipShape here — that was causing the clipping!
    }

    // --------------------------------------------------------
    // MARK: - Goal Info
    // --------------------------------------------------------
    private var goalInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                // Priority dot for medium/low
                if goal.priority != .high && !isTomorrowPreview {
                    Circle()
                        .fill(goal.priority.color)
                        .frame(width: 6, height: 6)
                }

                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        isTomorrowPreview
                            ? .secondary
                            : isCompleted
                                ? goal.color
                                : Color.primary
                    )
                    .strikethrough(
                        isCompleted && !isTomorrowPreview,
                        color: goal.color
                    )
                    .lineLimit(1)

                // Repeat badge
                if goal.repeatType == .none {
                    Text("Today only")
                        .font(.system(size: 9))
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.12))
                        )
                } else if goal.repeatType != .daily {
                    Text(goal.repeatType.shortDescription)
                        .font(.system(size: 9))
                        .fontWeight(.medium)
                        .foregroundStyle(goal.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(goal.color.opacity(0.12))
                        )
                }
            }

            HStack(spacing: 6) {
                if streak > 0 && !isTomorrowPreview {
                    Label(
                        "\(streak) day streak",
                        systemImage: "flame.fill"
                    )
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
                } else {
                    Text(
                        isTomorrowPreview
                            ? "Scheduled for tomorrow"
                            : goal.category.rawValue
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Action Control
    // --------------------------------------------------------
    @ViewBuilder
    private var actionControl: some View {
        if goal.goalType == .checkbox {
            checkboxControl
        } else {
            progressControl
        }
    }

    private var checkboxControl: some View {
        Button {
            handleCheckboxTap()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        isCompleted
                            ? LinearGradient(
                                colors: [
                                    goal.color,
                                    goal.secondaryColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.1)
                                        : Color(.systemGray5),
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.08)
                                        : Color(.systemGray5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .frame(width: 38, height: 38)
                    .animation(
                        .spring(duration: 0.3, bounce: 0.4),
                        value: isCompleted
                    )

                Image(systemName:
                    isCompleted ? "checkmark" : "circle"
                )
                .font(.system(
                    size: isCompleted ? 16 : 18,
                    weight: .bold
                ))
                .foregroundStyle(
                    isCompleted ? .white : Color(.systemGray3)
                )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.85 : 1.0)
    }

    @ViewBuilder
    private var progressControl: some View {
        if isHealthTrackedGoal {
            VStack(spacing: 1) {
                Text(formattedProgress(todaysProgress))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(isCompleted ? goal.color : .primary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: todaysProgress)
                    .frame(minWidth: 52)

                if !goal.unit.isEmpty {
                    Text("/ \(formattedProgress(Double(goal.targetValue))) \(goal.unit)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } else {
        HStack(spacing: 8) {
            Button {
                if isLocked {
                    showLockedWarning()
                } else {
                    viewModel.decrementProgress(goal)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(
                        isLocked
                            ? Color(.systemGray5)
                            : todaysProgress > 0
                                ? goal.color.opacity(0.8)
                                : Color(.systemGray4)
                    )
            }
            .buttonStyle(.plain)
            .disabled(todaysProgress == 0 && !isLocked)

            VStack(spacing: 1) {
                Text(formattedProgress(todaysProgress))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        isCompleted ? goal.color : .primary
                    )
                    .contentTransition(.numericText())
                    .animation(
                        .spring(duration: 0.3),
                        value: todaysProgress
                    )
                    .frame(minWidth: 28)

                if !goal.unit.isEmpty {
                    Text("/ \(formattedProgress(Double(goal.targetValue))) \(goal.unit)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 44)

            Button {
                if isLocked {
                    showLockedWarning()
                } else {
                    handleProgressIncrement()
                }
            } label: {
                Image(systemName:
                    isCompleted
                        ? "lock.circle.fill"
                        : "plus.circle.fill"
                )
                .font(.title3)
                .foregroundStyle(
                    isCompleted
                        ? Color(.systemGray4)
                        : todaysProgress > 0
                            ? goal.color
                            : Color(.systemGray3)
                )
            }
            .buttonStyle(.plain)
        }
        }
    }

    // --------------------------------------------------------
    // MARK: - Progress Bar
    // --------------------------------------------------------
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.10)
                        : Color.black.opacity(0.055)
                    )
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                goal.color.opacity(0.9),
                                goal.secondaryColor.opacity(0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(
                            6,
                            geo.size.width *
                            min(
                                1,
                                CGFloat(todaysProgress) /
                                CGFloat(max(1, goal.targetValue))
                            )
                        ),
                        height: 6
                    )
                    .shadow(
                        color: goal.color.opacity(colorScheme == .dark ? 0.18 : 0.12),
                        radius: 3,
                        x: 0,
                        y: 1
                    )
                    .animation(.spring(duration: 0.4), value: todaysProgress)
            }
        }
        .frame(height: 6)
    }

    // --------------------------------------------------------
    // MARK: - Partial Points Preview
    // --------------------------------------------------------
    private var partialPointsPreview: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.leadinghalf.filled")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.orange.opacity(0.85))

            Text("~\(partialPoints) pts at day end")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange.opacity(0.85))

            Spacer()

            let pct = Int(
                todaysProgress /
                Double(max(1, goal.targetValue)) * 100
            )

            Text("\(pct)%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.orange.opacity(0.85))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.055))
        )
    }

    // --------------------------------------------------------
    // MARK: - Manual Edit Button
    // --------------------------------------------------------
    private var manualEditButton: some View {
        Button {
            manualEditValue = todaysProgress
            manualEditText = rawProgressInput(todaysProgress)
            showingManualEditSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.85))

                Text("Edit manually")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Left your phone behind?")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var healthSyncActionRow: some View {
        HStack(spacing: 8) {
            Button {
                resyncHealthFromCard()
            } label: {
                HStack(spacing: 5) {
                    if isResyncingHealth {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .semibold))
                    }

                    Text("Re-sync")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(goal.color.opacity(0.9))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(goal.color.opacity(colorScheme == .dark ? 0.12 : 0.075))
                )
            }
            .buttonStyle(.plain)
            .disabled(isResyncingHealth || viewModel.isHealthSyncInProgress)

            if let lastSync = viewModel.lastHealthSyncDate(for: goal) {
                Text(lastSync.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            if shouldShowCalories {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.orange.opacity(0.85))

                    Text("\(Int(caloriesBurned)) cal")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)

                    if isCaloriesUnit(goal.unit) {
                        Text("• \(max(0, goal.targetValue - Int(caloriesBurned))) left")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Honesty Edit Sheet
    // --------------------------------------------------------
    private var honestyEditSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {

                VStack(spacing: 12) {
                    Text("🤝")
                        .font(.system(size: 60))

                    Text("Manual Entry")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(
                        "Left your phone behind? No worries — " +
                        "log what you actually did. " +
                        "We trust your honesty!"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                }
                .padding(.top, 20)

                HStack(spacing: 12) {
                    Text(goal.emoji)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(goal.name)
                            .font(.headline)
                        Text(
                            "Target: \(goal.targetValue) " +
                            "\(goal.unit)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                )

                VStack(spacing: 12) {
                    Text("How much did you actually do?")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(spacing: 8) {
                        TextField("0", text: $manualEditText)
                            .keyboardType(allowsDecimalProgress ? .decimalPad : .numberPad)
                            .focused($isManualEditFocused)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(goal.color)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .onChange(of: manualEditText) { _, newValue in
                                updateManualEditValue(from: newValue)
                            }

                        HStack(spacing: 4) {
                            Text("Target: \(formattedProgress(Double(goal.targetValue)))")
                            if !goal.unit.isEmpty {
                                Text(goal.unit)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if manualEditValue > 0 {
                        if manualEditValue >= Double(goal.targetValue) {
                            Text(
                                "🎉 Full " +
                                "\(goal.pointsPerCompletion)" +
                                " pts — Goal complete!"
                            )
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        } else {
                            let pts = goal.partialPoints(for: manualEditValue)
                            if pts > 0 {
                                Text(
                                    "~\(pts) partial pts " +
                                    "for your effort 💪"
                                )
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )

                if isHealthTrackedGoal {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.caption)
                                .foregroundStyle(.pink)
                            Text(
                                viewModel.isUsingManualHealthOverride(for: goal)
                                    ? "Manual override is active"
                                    : "Apple Health sync available"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        if let lastSync = viewModel.lastHealthSyncDate(for: goal) {
                            Text("Last synced: \(lastSync.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            dismissKeyboard()
                            isManualEditFocused = false
                            isResyncingHealth = true
                            Task {
                                _ = await viewModel.resyncWithAppleHealth(for: goal)
                                await MainActor.run {
                                    manualEditValue = todaysProgress
                                    manualEditText = rawProgressInput(todaysProgress)
                                    isResyncingHealth = false
                                    showingManualEditSheet = false
                                }
                            }
                        } label: {
                            HStack {
                                if isResyncingHealth {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text("Re-sync with Apple Health")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isResyncingHealth || viewModel.isHealthSyncInProgress)
                    }
                    .padding(.horizontal, 4)
                }

                Spacer()

                Button {
                    saveManualProgress()
                } label: {
                    Text("Save My Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            goal.color,
                                            goal.secondaryColor
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .disabled(!isManualEditValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .navigationBarLeading
                ) {
                    Button("Save") {
                        saveManualProgress()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        isManualEditValid ? goal.color : .secondary
                    )
                    .disabled(!isManualEditValid)
                }
                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {
                    Button("Cancel") {
                        showingManualEditSheet = false
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        saveManualProgress()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            manualEditValue = todaysProgress
            manualEditText = rawProgressInput(todaysProgress)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isManualEditFocused = true
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Honesty Confirm Sheet
    // --------------------------------------------------------
    private var honestyConfirmSheet: some View {
        VStack(spacing: 24) {
            Text("🤝")
                .font(.system(size: 52))
                .padding(.top, 24)

            Text(viewModel.honestyMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button {
                    viewModel.confirmManualOverride()
                } label: {
                    Text("Yes, I did it! ✅")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(Color.green)
                        )
                }

                Button {
                    viewModel.cancelManualOverride()
                } label: {
                    Text("Let me reconsider")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }

    // --------------------------------------------------------
    // MARK: - Weekly Dots
    // --------------------------------------------------------
    private var weeklyDotsRow: some View {
        HStack(spacing: 0) {
            let days = ["M", "T", "W", "T", "F", "S", "S"]

            ForEach(Array(weeklyDots.enumerated()), id: \.offset) { index, completed in
                let isToday = isCurrentDay(index: index)
                let isFuture = isFutureDay(index: index)

                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            completed
                            ? goal.color.opacity(isTomorrowPreview ? 0.35 : 0.85)
                            : isToday
                                ? goal.color.opacity(0.22)
                                : isFuture
                                    ? Color(.systemGray5).opacity(0.45)
                                    : Color(.systemGray4).opacity(0.35)
                        )
                        .frame(width: isToday ? 9 : 7, height: isToday ? 9 : 7)
                        .overlay {
                            if isToday {
                                Circle()
                                    .stroke(goal.color.opacity(0.75), lineWidth: 1)
                            }
                        }
                        .animation(.spring(duration: 0.25), value: completed)

                    Text(days[index])
                        .font(.system(size: 8, weight: isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isToday
                            ? goal.color.opacity(0.85)
                            : Color.secondary.opacity(0.55)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Adaptive Card Colors
    // --------------------------------------------------------
    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    colorScheme == .dark
                    ? Color(red: 0.15, green: 0.15, blue: 0.17)
                    : Color.white
                )

            if !isTomorrowPreview {
                LinearGradient(
                    colors: [
                        goal.color.opacity(colorScheme == .dark ? 0.10 : 0.035),
                        goal.secondaryColor.opacity(colorScheme == .dark ? 0.06 : 0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
    }

    private var cardBorderColor: Color {
        if isTomorrowPreview {
            return Color.clear
        }

        if isCompleted {
            return goal.color.opacity(colorScheme == .dark ? 0.24 : 0.14)
        }

        if goal.priority == .high {
            return goal.priority.color.opacity(colorScheme == .dark ? 0.22 : 0.16)
        }

        if isExpiring {
            return Color.orange.opacity(colorScheme == .dark ? 0.22 : 0.16)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.045)
    }

    private var cardShadowColor: Color {
        if colorScheme == .dark {
            return Color.clear
        }

        if isCompleted {
            return goal.color.opacity(0.06)
        }

        if goal.priority == .high {
            return goal.priority.color.opacity(0.07)
        }

        return Color.black.opacity(0.045)
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------
    private func isCurrentDay(index: Int) -> Bool {
        let weekday = Calendar.current.component(
            .weekday, from: Date()
        )
        return index == (weekday + 5) % 7
    }

    private func isFutureDay(index: Int) -> Bool {
        let weekday = Calendar.current.component(
            .weekday, from: Date()
        )
        return index > (weekday + 5) % 7
    }

    private func handleCheckboxTap() {
        if isLocked {
            showLockedWarning()
            return
        }

        withAnimation(.spring(duration: 0.15)) {
            isPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(duration: 0.15)) {
                isPressed = false
            }
        }

        let wasCompleted = isCompleted

        if !wasCompleted {
            triggerCompletionAnimations()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                viewModel.completeCheckboxGoal(goal)
            }
        } else {
            viewModel.completeCheckboxGoal(goal)
        }
    }

    private func handleProgressIncrement() {
        let wasCompleted = isCompleted

        let predictedProgress = todaysProgress + 1
        let willComplete =
            !wasCompleted &&
            predictedProgress >= Double(goal.targetValue)

        if willComplete {
            triggerCompletionAnimations()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                viewModel.incrementProgress(goal)
            }
        } else {
            viewModel.incrementProgress(goal)
        }
    }

    private func resyncHealthFromCard() {
        guard !isResyncingHealth else { return }
        isResyncingHealth = true
        Task {
            _ = await viewModel.resyncWithAppleHealth(for: goal)
            await MainActor.run {
                manualEditValue = todaysProgress
                manualEditText = rawProgressInput(todaysProgress)
                isResyncingHealth = false
            }
        }
    }

    private func triggerCompletionAnimations() {
        showingBurst = false
        showingPoints = false
        completionPulse = false

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
                completionPulse = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            showingBurst = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showingPoints = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                completionPulse = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            showingBurst = false
            showingPoints = false
        }
    }

    private func showLockedWarning() {
        guard !showingLockedWarning else { return }
        UIImpactFeedbackGenerator(style: .rigid)
            .impactOccurred()

        withAnimation(.spring(duration: 0.3)) {
            showingLockedWarning = true
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.0
        ) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingLockedWarning = false
            }
        }
    }

    private var isManualEditValid: Bool {
        let sanitized = sanitizedManualInput(manualEditText)
        guard let value = Double(sanitized), value >= 0 else {
            return false
        }
        return value <= Double(max(goal.targetValue * 2, goal.targetValue, 1))
    }

    private func saveManualProgress() {
        guard isManualEditValid else { return }
        dismissKeyboard()
        isManualEditFocused = false
        updateManualEditValue(from: manualEditText)
        showingManualEditSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.requestManualOverride(
                goal: goal,
                newValue: manualEditValue
            )
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func updateManualEditValue(from text: String) {
        let sanitized = sanitizedManualInput(text)
        if sanitized != text {
            manualEditText = sanitized
            return
        }

        guard let value = Double(sanitized) else {
            manualEditValue = 0
            return
        }

        let maxValue = Double(max(goal.targetValue * 2, goal.targetValue, 1))
        if value > maxValue {
            manualEditValue = maxValue
            manualEditText = formattedProgress(maxValue)
        } else {
            manualEditValue = value
        }
    }

    private func sanitizedManualInput(_ text: String) -> String {
        var result = ""
        var hasDecimal = false

        for character in text {
            if character.isNumber {
                result.append(character)
            } else if allowsDecimalProgress && character == "." && !hasDecimal {
                hasDecimal = true
                result.append(character)
            }
        }

        return result
    }

    private var allowsDecimalProgress: Bool {
        let normalized = goal.unit.lowercased()
        return normalized == "km" ||
            normalized == "miles" ||
            normalized == "mi" ||
            normalized == "l"
    }

    private func isCaloriesUnit(_ unit: String) -> Bool {
        let normalized = unit.lowercased()
        return normalized == "cal" ||
            normalized == "cals" ||
            normalized == "calorie" ||
            normalized == "calories" ||
            normalized == "kcal"
    }

    private func formattedProgress(_ value: Double) -> String {
        if allowsDecimalProgress {
            return value.formatted(.number.precision(.fractionLength(0...1)))
        }
        return Int(value.rounded(.down)).formatted(.number)
    }

    private func rawProgressInput(_ value: Double) -> String {
        if allowsDecimalProgress {
            return value.formatted(
                .number
                    .precision(.fractionLength(0...1))
                    .grouping(.never)
            )
        }
        return String(Int(value.rounded(.down)))
    }

    private func startExpiryPulse() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            expiryPulse = true
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light") {
    let config = ModelConfiguration(
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: Goal.self, GoalCompletion.self,
        configurations: config
    )
    let vm = GoalViewModel(
        modelContext: container.mainContext
    )
    ScrollView {
        VStack(spacing: 12) {
            GoalRowView(
                goal: Goal(
                    name: "Morning Run",
                    emoji: "🏃",
                    sfSymbol: "figure.run",
                    category: .fitness,
                    goalType: .progress,
                    activityType: .running,
                    priority: .medium,
                    targetValue: 5,
                    unit: "km"
                ),
                viewModel: vm
            )
            GoalRowView(
                goal: Goal(
                    name: "Read",
                    emoji: "📚",
                    sfSymbol: "book.fill",
                    category: .mind,
                    goalType: .progress,
                    activityType: .reading,
                    priority: .medium,
                    targetValue: 30,
                    unit: "min"
                ),
                viewModel: vm
            )
        }
        .padding(16)
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}

#Preview("Dark") {
    let config = ModelConfiguration(
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: Goal.self, GoalCompletion.self,
        configurations: config
    )
    let vm = GoalViewModel(
        modelContext: container.mainContext
    )
    GoalRowView(
        goal: Goal(
            name: "Daily Water",
            emoji: "💧",
            sfSymbol: "drop.fill",
            category: .health,
            goalType: .progress,
            activityType: .water,
            priority: .medium,
            targetValue: 8,
            unit: "glasses"
        ),
        viewModel: vm
    )
    .padding(16)
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
    .modelContainer(container)
}

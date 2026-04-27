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

struct GoalRowView: View {

    let goal: Goal
    let viewModel: GoalViewModel
    var isTomorrowPreview: Bool = false

    @State private var showingBurst = false
    @State private var showingPoints = false
    @State private var isPressed = false
    @State private var showingLockedWarning = false
    @State private var expiryPulse = false
    @State private var showingManualEditSheet = false
    @State private var manualEditValue: Double = 0
    @State private var manualEditText: String = "0"
    @FocusState private var isManualEditFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var isHealthTrackedGoal: Bool {
        goal.isHealthKitLinked ||
        goal.activityType == .walking ||
        goal.activityType == .running ||
        goal.activityType == .cycling
    }

    private var todaysProgress: Double {
        viewModel.todaysProgressValue(for: goal)
    }

    private var isCompleted: Bool {
        viewModel.isCompletedToday(goal)
    }

    private var isLocked: Bool {
        viewModel.isLockedForEditing(goal)
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
            }

            VStack {
                PointsPopupView(
                    points: viewModel.lastPointsEarned,
                    isShowing: showingPoints
                )
                Spacer()
            }
            .allowsHitTesting(false)

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
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1.5)
        )
        .overlay(
            // Expiry pulse border
            RoundedRectangle(cornerRadius: 18)
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
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isTomorrowPreview ? 0.5 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .animation(.spring(duration: 0.3), value: isCompleted)
    }

    // --------------------------------------------------------
    // MARK: - Priority Banner
    // --------------------------------------------------------
    private var priorityBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: goal.priority.icon)
                .font(.system(size: 10))
                .foregroundStyle(goal.priority.color)

            Text(
                "\(goal.priority.emoji) " +
                "\(goal.priority.displayName) Priority"
            )
            .font(.system(size: 10))
            .fontWeight(.semibold)
            .foregroundStyle(goal.priority.color)

            Spacer()

            if goal.activityType == .medicine {
                Text("💊 Take your medicine!")
                    .font(.system(size: 10))
                    .fontWeight(.medium)
                    .foregroundStyle(goal.priority.color)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(
            goal.priority.color.opacity(
                colorScheme == .dark ? 0.15 : 0.08
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
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color(.systemGray5)
                    )
                    .frame(height: 7)

                RoundedRectangle(cornerRadius: 5)
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
                    .frame(
                        width: max(
                            7,
                            geo.size.width *
                            min(
                                1,
                                CGFloat(todaysProgress) /
                                CGFloat(max(1, goal.targetValue))
                            )
                        ),
                        height: 7
                    )
                    .animation(
                        .spring(duration: 0.4),
                        value: todaysProgress
                    )
            }
        }
        .frame(height: 7)
    }

    // --------------------------------------------------------
    // MARK: - Partial Points Preview
    // --------------------------------------------------------
    private var partialPointsPreview: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.leadinghalf.filled")
                .font(.caption2)
                .foregroundStyle(.orange)

            Text("~\(partialPoints) pts at day end")
                .font(.caption2)
                .foregroundStyle(.orange)
                .fontWeight(.medium)

            Spacer()

            let pct = Int(
                todaysProgress /
                Double(max(1, goal.targetValue)) * 100
            )
            Text("\(pct)%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(
                    colorScheme == .dark ? 0.12 : 0.07
                ))
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
            HStack(spacing: 5) {
                Image(systemName: "pencil.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Edit manually")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Left your phone behind?")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
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

                Spacer()

                Button {
                    isManualEditFocused = false
                    updateManualEditValue(from: manualEditText)
                    showingManualEditSheet = false
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.3
                    ) {
                        viewModel.requestManualOverride(
                            goal: goal,
                            newValue: manualEditValue
                        )
                    }
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
                        isManualEditFocused = false
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
            let days = ["M","T","W","T","F","S","S"]
            ForEach(
                Array(weeklyDots.enumerated()),
                id: \.offset
            ) { index, completed in
                let isToday = isCurrentDay(index: index)
                let isFuture = isFutureDay(index: index)

                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(
                                isFuture
                                    ? Color(.systemGray5)
                                        .opacity(0.4)
                                    : completed
                                        ? goal.color
                                        : colorScheme == .dark
                                            ? Color.white
                                                .opacity(0.15)
                                            : Color(.systemGray4)
                                                .opacity(0.5)
                            )
                            .frame(width: 8, height: 8)
                            .animation(
                                .spring(duration: 0.3),
                                value: completed
                            )

                        if isToday {
                            Circle()
                                .stroke(
                                    goal.color,
                                    lineWidth: 1.5
                                )
                                .frame(width: 13, height: 13)
                        }
                    }

                    Text(days[index])
                        .font(.system(size: 8))
                        .foregroundStyle(
                            isToday
                                ? goal.color
                                : Color.secondary.opacity(0.6)
                        )
                        .fontWeight(isToday ? .bold : .regular)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Adaptive Card Colors
    // --------------------------------------------------------
    private var cardBackground: some View {
        Group {
            if isTomorrowPreview {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        colorScheme == .dark
                            ? Color(
                                red: 0.14, green: 0.14,
                                blue: 0.15
                              )
                            : Color(.systemGray6)
                    )
            } else if isCompleted {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(goal.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    Color(
                                        red: 0.17,
                                        green: 0.17,
                                        blue: 0.18
                                    ).opacity(0.85)
                                )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(goal.color.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.97))
                        )
                }
            } else {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(
                            red: 0.17, green: 0.17,
                            blue: 0.18
                        ))
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                }
            }
        }
    }

    private var cardBorderColor: Color {
        if isTomorrowPreview { return Color.clear }
        if isCompleted {
            return goal.color.opacity(
                colorScheme == .dark ? 0.5 : 0.25
            )
        }
        if goal.priority == .high {
            return goal.priority.color.opacity(0.3)
        }
        if isExpiring {
            return Color.orange.opacity(0.3)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    private var cardShadowColor: Color {
        if isCompleted {
            return goal.color.opacity(
                colorScheme == .dark ? 0.2 : 0.1
            )
        }
        if goal.priority == .high {
            return goal.priority.color.opacity(0.1)
        }
        return Color.black.opacity(
            colorScheme == .dark ? 0.0 : 0.05
        )
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
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.15
        ) {
            withAnimation(.spring(duration: 0.15)) {
                isPressed = false
            }
        }

        let wasCompleted = isCompleted
        viewModel.completeCheckboxGoal(goal)
        if !wasCompleted { triggerCompletionAnimations() }
    }

    private func handleProgressIncrement() {
        let wasCompleted = isCompleted
        viewModel.incrementProgress(goal)
        if !wasCompleted && viewModel.isCompletedToday(goal) {
            triggerCompletionAnimations()
        }
    }

    private func triggerCompletionAnimations() {
        showingBurst = false
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.1
        ) { showingBurst = true }

        showingPoints = false
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2
        ) { showingPoints = true }
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

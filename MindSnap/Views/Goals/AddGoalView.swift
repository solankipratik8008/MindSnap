//
//  AddGoalView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
// ============================================================
// AddGoalView.swift
// MindSnap — Premium Monochrome Add/Edit Goal
//
// SAFE UI UPDATE:
// 1. Based on your working AddGoalView file
// 2. Keeps existingGoal parameter
// 3. Keeps [ReminderTime] reminders
// 4. Keeps HealthKit access logic
// 5. Keeps notification/reminder logic
// 6. Keeps duplicate validation
// 7. Keeps addGoal/updateGoal signatures
// 8. Keeps edit-mode loading
// 9. Removes broken spellCheckingDisabled modifier
// 10. Updates only UI/theme safely
// ============================================================

import SwiftUI
import SwiftData
import UserNotifications

struct AddGoalView: View {

    let viewModel: GoalViewModel
    var existingGoal: Goal? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("isHealthSyncEnabled")
    private var isHealthSyncEnabled = false
    
    @AppStorage("hasSeenAddGoalCoachMark")
    private var hasSeenAddGoalCoachMark = false

    // ---- Basic info ----
    @State private var goalName = ""
    @State private var selectedEmoji = "⭐"
    @State private var selectedSymbol = "star.fill"
    @State private var selectedCategory = GoalCategory.fitness
    @State private var selectedType = GoalType.checkbox
    @State private var selectedActivityType = GoalActivityType.custom
    @State private var selectedPriority = GoalPriority.medium
    
    
    @State private var showingAddGoalCoachMark = false
    @State private var addGoalCoachStep = 0
    @State private var addGoalCoachAnimate = false

    // ---- Progress ----
    @State private var targetValue = 1
    @State private var selectedUnit = ""
    @State private var availableUnits: [SmartUnit] = []

    // ---- Repeat ----
    @State private var selectedRepeatType = GoalRepeatType.daily
    @State private var customRepeatDays: [Int] = [1, 2, 3, 4, 5]

    // ---- Reminders ----
    @State private var reminders: [ReminderTime] = []
    @State private var showingTimePicker = false
    @State private var newReminderTime = Date()

    // ---- UI state ----
    @State private var showingPresets = true
    @State private var showingEmojiPicker = false
    @State private var aiSuggestedEmoji = ""
    @State private var healthySuggestion = ""
    @State private var healthWarning = ""
    @State private var showingHealthWarning = false
    @State private var showingDuplicateError = false
    @State private var showingPermissionDenied = false
    @State private var showingHealthManualNotice = false

    private var isEditMode: Bool {
        existingGoal != nil
    }

    private var shouldRequestHealthAccess: Bool {
        selectedType == .progress &&
        HealthKitService.healthSupportedActivityTypes.contains(selectedActivityType)
    }

    private let dayLabels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    private let goalSymbols: [(String, String)] = [
        ("figure.run", "Run"),
        ("dumbbell.fill", "Gym"),
        ("figure.walk", "Walk"),
        ("figure.mind.and.body", "Yoga"),
        ("drop.fill", "Water"),
        ("moon.stars.fill", "Sleep"),
        ("book.fill", "Read"),
        ("brain.head.profile", "Meditate"),
        ("leaf.fill", "Eat Well"),
        ("graduationcap.fill", "Learn"),
        ("paintbrush.fill", "Create"),
        ("phone.fill", "Call"),
        ("heart.fill", "Health"),
        ("bicycle", "Cycle"),
        ("music.note", "Music"),
        ("laptopcomputer", "Code"),
        ("pills.fill", "Medicine"),
        ("star.fill", "Custom"),
        ("flame.fill", "Streak"),
        ("trophy.fill", "Win")
    ]

    private let customEmojis = [
        "🏃", "🏋️", "🧘", "🚶", "🏊", "🚴", "🤸", "⚽", "🏀", "🎾",
        "💧", "😴", "🥗", "💊", "❤️", "🧠", "🦷", "👁", "🦵", "🦴",
        "📚", "🎓", "✍️", "🎵", "💻", "🗣️", "🎨", "📸", "🍳", "🌱",
        "📞", "👨‍👩‍👧‍👦", "🤝", "📌", "🎁", "☕", "🌅", "🌙", "⭐", "🔥",
        "💪", "🏆", "🎯", "✅", "💡", "🚀", "🌈", "⚡", "🎉", "🙏"
    ]

    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    private var cardFill: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var rowFill: Color {
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

    private func premiumCard(cornerRadius: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: 12,
                x: 0,
                y: 6
            )
    }

    private func premiumRow(cornerRadius: CGFloat = 14) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(rowFill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {

                        if !isEditMode {
                            presetGoalsSection
                        }

                        if showingDuplicateError {
                            duplicateErrorBanner
                                .transition(
                                    .move(edge: .top)
                                    .combined(with: .opacity)
                                )
                        }

                        goalNameSection
                        prioritySection
                        categorySection
                        goalTypeSection

                        if selectedType == .progress {
                            progressTargetSection
                        }

                        iconPickerSection
                        repeatSection
                        remindersSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .background(appBackground)

                if showingAddGoalCoachMark {
                    addGoalCoachMarkOverlay
                        .transition(.opacity)
                        .zIndex(50)
                }
            }
            .background(appBackground)
            .background(appBackground)
            .navigationTitle(isEditMode ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(secondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Update" : "Add Goal") {
                        Task {
                            await saveGoal()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? tertiaryText
                        : primaryText
                    )
                    .disabled(goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable notifications for MindSnap in iOS Settings to receive goal reminders.")
            }
            .alert("Manual Progress Still Works", isPresented: $showingHealthManualNotice) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Health access was not enabled. MindSnap saved your goal, and you can still update this goal manually.")
            }
        }
        .onAppear {
            if let goal = existingGoal {
                loadExistingGoal(goal)
            }

            updateUnitsForActivity()
            presentAddGoalCoachMarkIfNeeded()
        }
        .onChange(of: goalName) { _, newName in
            let detected = GoalActivityType.detect(from: newName)

            if detected != .custom {
                selectedActivityType = detected
                updateUnitsForActivity()

                if detected == .medicine {
                    selectedPriority = .high
                }
            }

            let suggested = PresetGoal.suggestEmoji(for: newName)

            if suggested != "⭐" {
                aiSuggestedEmoji = suggested

                withAnimation(.spring(duration: 0.3)) {
                    selectedEmoji = suggested
                }
            }
        }
        .onChange(of: selectedActivityType) { _, _ in
            updateUnitsForActivity()
        }
        .onChange(of: targetValue) { _, newValue in
            checkHealthyLimit(value: newValue)
        }
        .animation(.easeInOut(duration: 0.3), value: showingDuplicateError)
    }

    // --------------------------------------------------------
    // MARK: - Duplicate Error Banner
    // --------------------------------------------------------
    private var duplicateErrorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline)

            Text("'\(goalName)' already exists in today's goals!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.13 : 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.20), lineWidth: 1)
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Preset Goals Section
    // --------------------------------------------------------
    private var presetGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick Add", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingPresets.toggle()
                    }
                } label: {
                    Image(systemName: showingPresets ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(rowFill)
                                .overlay(
                                    Circle()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            if showingPresets {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 10
                ) {
                    ForEach(PresetGoal.all, id: \.name) { preset in
                        presetCard(preset: preset)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 20))
    }

    private func presetCard(preset: PresetGoal) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(
                            preset.activityType.color.opacity(
                                colorScheme == .dark ? 0.20 : 0.11
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    preset.activityType.color.opacity(
                                        colorScheme == .dark ? 0.24 : 0.16
                                    ),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: preset.sfSymbol)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            preset.activityType.color,
                            preset.activityType.secondaryColor
                        )
                        .font(.system(size: 18, weight: .semibold))

                    if preset.priority == .high {
                        VStack {
                            HStack {
                                Spacer()

                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 2, y: -2)
                            }

                            Spacer()
                        }
                        .frame(width: 48, height: 48)
                    }
                }

                Text(preset.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(premiumRow(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Goal Name Section
    // --------------------------------------------------------
    private var goalNameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Goal Name", systemImage: "pencil")

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showingEmojiPicker.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                selectedCategory.color.opacity(
                                    colorScheme == .dark ? 0.18 : 0.10
                                )
                            )
                            .frame(width: 52, height: 52)
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedCategory.color.opacity(
                                            colorScheme == .dark ? 0.30 : 0.16
                                        ),
                                        lineWidth: 1
                                    )
                            )

                        Text(selectedEmoji)
                            .font(.system(size: 26))
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    TextField("e.g. Morning Run, Take Medicine...", text: $goalName)
                        .font(.body)
                        .foregroundStyle(primaryText)
                        .tint(primaryText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)

                    if !aiSuggestedEmoji.isEmpty && aiSuggestedEmoji != "⭐" {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(primaryText)

                            Text("Suggested \(aiSuggestedEmoji)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(secondaryText)
                        }
                    }
                }
            }
            .padding(14)
            .background(premiumCard(cornerRadius: 18))

            if showingEmojiPicker {
                emojiPickerGrid
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var emojiPickerGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose Emoji")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(secondaryText)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 10),
                spacing: 8
            ) {
                ForEach(customEmojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji

                        withAnimation {
                            showingEmojiPicker = false
                        }
                    } label: {
                        Text(emoji)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(
                                        selectedEmoji == emoji
                                        ? selectedCategory.color.opacity(
                                            colorScheme == .dark ? 0.20 : 0.12
                                        )
                                        : Color.clear
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(premiumCard(cornerRadius: 18))
    }

    // --------------------------------------------------------
    // MARK: - Priority Section
    // --------------------------------------------------------
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Priority", systemImage: "exclamationmark.circle.fill")

            HStack(spacing: 10) {
                ForEach(GoalPriority.allCases, id: \.self) { priority in
                    priorityCard(priority: priority)
                }
            }

            HStack(spacing: 7) {
                Image(systemName: selectedPriority.icon)
                    .font(.caption)
                    .foregroundStyle(selectedPriority.color)

                Text(selectedPriority.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPriority.color.opacity(colorScheme == .dark ? 0.12 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPriority.color.opacity(0.16), lineWidth: 1)
                    )
            )
        }
    }

    private func priorityCard(priority: GoalPriority) -> some View {
        let isSelected = selectedPriority == priority

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                selectedPriority = priority
            }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? priority.color
                            : rowFill
                        )
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.clear : borderColor,
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: priority.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : priority.color)
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)

                Text(priority.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? priority.color : secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                        ? priority.color.opacity(colorScheme == .dark ? 0.14 : 0.075)
                        : cardFill
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                ? priority.color.opacity(0.34)
                                : borderColor,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Category Section
    // --------------------------------------------------------
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Category", systemImage: "square.grid.2x2")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GoalCategory.allCases, id: \.self) { category in
                        categoryPill(category: category)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private func categoryPill(category: GoalCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        isSelected ? primaryButtonText : category.color,
                        isSelected ? primaryButtonText.opacity(0.70) : category.secondaryColor
                    )
                    .font(.system(size: 13, weight: .semibold))

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? primaryButtonText : primaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? primaryButtonBackground
                        : rowFill
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected
                                ? Color.clear
                                : borderColor,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Goal Type Section
    // --------------------------------------------------------
    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Tracking Type", systemImage: "chart.bar.fill")

            HStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { type in
                    goalTypeCard(type: type)
                }
            }
        }
    }

    private func goalTypeCard(type: GoalType) -> some View {
        let isSelected = selectedType == type

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedType = type

                if type == .checkbox {
                    targetValue = 1
                    selectedUnit = ""
                } else {
                    if targetValue <= 1 {
                        targetValue = 5
                    }

                    if selectedUnit.isEmpty {
                        selectedUnit = availableUnits.first?.label ?? "times"
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: type.icon)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            isSelected ? selectedCategory.color : secondaryText,
                            isSelected ? selectedCategory.secondaryColor : tertiaryText
                        )
                        .font(.title3)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(selectedCategory.color)
                            .font(.caption)
                    }
                }

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Text(type.description)
                    .font(.caption2)
                    .foregroundStyle(secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                        ? selectedCategory.color.opacity(colorScheme == .dark ? 0.13 : 0.065)
                        : cardFill
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                ? selectedCategory.color.opacity(0.30)
                                : borderColor,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Progress Target Section
    // --------------------------------------------------------
    private var progressTargetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Daily Target", systemImage: "target")

            VStack(spacing: 14) {
                targetAmountCard

                if showingHealthWarning && !healthWarning.isEmpty {
                    healthWarningBanner
                }

                if !availableUnits.isEmpty && selectedActivityType.needsUnit {
                    unitPickerSection
                }

                if !healthySuggestion.isEmpty {
                    healthySuggestionBanner
                }
            }
        }
    }

    private var targetAmountCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Target Amount")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)

                HStack(spacing: 14) {
                    Button {
                        if targetValue > 1 {
                            targetValue -= smartDecrement
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(
                                targetValue > 1
                                ? selectedCategory.color
                                : tertiaryText
                            )
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 2) {
                        Text("\(targetValue)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryText)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.3), value: targetValue)
                            .frame(minWidth: 60)

                        if !selectedUnit.isEmpty {
                            Text(selectedUnit)
                                .font(.caption)
                                .foregroundStyle(selectedCategory.color)
                                .fontWeight(.medium)
                        }
                    }

                    Button {
                        targetValue += smartIncrement
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(selectedCategory.color)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 7) {
                Text("Quick set")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 6
                ) {
                    ForEach(quickValues, id: \.self) { value in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                targetValue = value
                            }
                        } label: {
                            Text("\(value)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    targetValue == value
                                    ? primaryButtonText
                                    : selectedCategory.color
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(
                                            targetValue == value
                                            ? primaryButtonBackground
                                            : selectedCategory.color.opacity(colorScheme == .dark ? 0.13 : 0.075)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 110)
            }
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 18))
    }

    private var healthWarningBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)

            Text(healthWarning)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.14 : 0.075))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var healthySuggestionBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.green)
                .font(.caption)

            Text(healthySuggestion)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(colorScheme == .dark ? 0.11 : 0.065))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var unitPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableUnits) { unit in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedUnit = unit.label
                                healthySuggestion = unit.suggestion
                            }
                        } label: {
                            Text(unit.label)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    selectedUnit == unit.label
                                    ? primaryButtonText
                                    : selectedCategory.color
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedUnit == unit.label
                                            ? primaryButtonBackground
                                            : rowFill
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    selectedUnit == unit.label
                                                    ? Color.clear
                                                    : borderColor,
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selectedUnit == unit.label ? 1.05 : 1.0)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Icon Picker Section
    // --------------------------------------------------------
    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Icon", systemImage: "square.grid.3x3")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(goalSymbols, id: \.0) { symbol, name in
                        symbolButton(symbol: symbol, name: name)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private func symbolButton(symbol: String, name: String) -> some View {
        let isSelected = selectedSymbol == symbol

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                selectedSymbol = symbol
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? primaryButtonBackground
                            : rowFill
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.clear : borderColor,
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: symbol)
                        .symbolRenderingMode(isSelected ? .monochrome : .palette)
                        .foregroundStyle(
                            isSelected ? primaryButtonText : selectedCategory.color,
                            isSelected ? primaryButtonText.opacity(0.70) : selectedCategory.secondaryColor
                        )
                        .font(.system(size: 20, weight: .semibold))
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)

                Text(name)
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? primaryText : secondaryText)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Repeat Section
    // --------------------------------------------------------
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Repeat Schedule", systemImage: "arrow.clockwise")

            VStack(spacing: 0) {
                ForEach(GoalRepeatType.allCases, id: \.self) { repeatType in
                    repeatTypeRow(repeatType: repeatType)

                    if repeatType != GoalRepeatType.allCases.last {
                        Divider()
                            .padding(.leading, 44)
                    }
                }

                if selectedRepeatType == .custom {
                    Divider()

                    customDaySelector
                        .padding(14)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(premiumCard(cornerRadius: 18))
            .animation(.easeInOut(duration: 0.2), value: selectedRepeatType)

            if selectedRepeatType == .none {
                HStack(spacing: 7) {
                    Image(systemName: "1.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)

                    Text("This goal will only appear today and automatically disappear tomorrow.")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.16), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func repeatTypeRow(repeatType: GoalRepeatType) -> some View {
        let isSelected = selectedRepeatType == repeatType
        let accentColor: Color = repeatType == .none ? .orange : selectedCategory.color

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? accentColor : rowFill)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.clear : borderColor,
                                lineWidth: 1
                            )
                    )

                Image(systemName: repeatType.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : secondaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(repeatType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(primaryText)

                    if repeatType == .none {
                        Text("Today only")
                            .font(.system(size: 9))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange))
                    }
                }

                Text(repeatType.description)
                    .font(.caption2)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? accentColor : tertiaryText)
                .font(.title3)
        }
        .padding(14)
        .contentShape(Rectangle())
        .background(
            isSelected
            ? accentColor.opacity(colorScheme == .dark ? 0.11 : 0.055)
            : Color.clear
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRepeatType = repeatType
            }

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private var customDaySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Days")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(secondaryText)

            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let isSelected = customRepeatDays.contains(day)

                    Button {
                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                            if isSelected {
                                if customRepeatDays.count > 1 {
                                    customRepeatDays.removeAll { $0 == day }
                                }
                            } else {
                                customRepeatDays.append(day)
                                customRepeatDays.sort()
                            }
                        }
                    } label: {
                        Text(dayLabels[day - 1])
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(isSelected ? primaryButtonText : secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? primaryButtonBackground : rowFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                isSelected ? Color.clear : borderColor,
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Reminders Section
    // --------------------------------------------------------
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Reminders", systemImage: "bell.fill")

            VStack(spacing: 0) {
                if reminders.isEmpty {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundStyle(secondaryText)
                            .font(.caption)

                        Text("No reminders set")
                            .font(.subheadline)
                            .foregroundStyle(secondaryText)

                        Spacer()
                    }
                    .padding(16)
                } else {
                    ForEach(reminders) { reminder in
                        reminderRow(reminder: reminder)

                        if reminder.id != reminders.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }

                Divider()

                Button {
                    requestPermissionThenShowPicker()
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(primaryButtonBackground)
                                .frame(width: 30, height: 30)

                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(primaryButtonText)
                        }

                        Text("Add Reminder")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(primaryText)

                        Spacer()
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(premiumCard(cornerRadius: 18))

            if selectedActivityType == .medicine {
                HStack(spacing: 7) {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.red)
                        .font(.caption)

                    Text("Medicine reminders use prominent, time-sensitive alerts when available.")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.12 : 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
    }

    private func reminderRow(reminder: ReminderTime) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(selectedCategory.color.opacity(colorScheme == .dark ? 0.18 : 0.10))
                    .frame(width: 32, height: 32)

                Image(systemName: "bell.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selectedCategory.color)
            }

            Text(reminder.timeString)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(primaryText)

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    reminders.removeAll { $0.id == reminder.id }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }

    // --------------------------------------------------------
    // MARK: - Request Permission then show picker
    // --------------------------------------------------------
    private func requestPermissionThenShowPicker() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    newReminderTime = Calendar.current.date(
                        bySettingHour: 8,
                        minute: 0,
                        second: 0,
                        of: Date()
                    ) ?? Date()

                    showingTimePicker = true

                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound, .badge]
                    ) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                newReminderTime = Calendar.current.date(
                                    bySettingHour: 8,
                                    minute: 0,
                                    second: 0,
                                    of: Date()
                                ) ?? Date()

                                showingTimePicker = true
                            } else {
                                showingPermissionDenied = true
                            }
                        }
                    }

                case .denied:
                    showingPermissionDenied = true

                default:
                    showingPermissionDenied = true
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Time Picker Sheet
    // --------------------------------------------------------
    private var timePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(rowFill)
                        .frame(width: 82, height: 82)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 1)
                        )

                    Image(systemName: "bell.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(primaryText)
                }
                .padding(.top, 20)

                Text("Set Reminder Time")
                    .font(.headline)
                    .foregroundStyle(primaryText)

                DatePicker(
                    "Reminder Time",
                    selection: $newReminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)

                Button {
                    addReminderFromPicker()
                } label: {
                    Text("Add Reminder")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryButtonText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(primaryButtonBackground)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Reminder") {
                        addReminderFromPicker()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingTimePicker = false
                    }
                    .foregroundStyle(secondaryText)
                }
            }
        }
        .presentationDetents([.height(440), .large])
        .presentationDragIndicator(.visible)
    }

    // --------------------------------------------------------
    // MARK: - Shared Section Label
    // --------------------------------------------------------
    private func sectionLabel(
        _ title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(secondaryText)
    }

    // --------------------------------------------------------
    // MARK: - Smart Helpers
    // --------------------------------------------------------
    private var smartIncrement: Int {
        switch selectedUnit {
        case "steps":
            return 500
        case "ml":
            return 100
        default:
            return 1
        }
    }

    private var smartDecrement: Int {
        switch selectedUnit {
        case "steps":
            return 500
        case "ml":
            return 100
        default:
            return 1
        }
    }

    private var quickValues: [Int] {
        switch selectedUnit {
        case "glasses":
            return [6, 8, 10, 12]
        case "steps":
            return [5000, 8000, 10000, 15000]
        case "minutes":
            return [15, 30, 45, 60]
        case "hours":
            return [1, 2, 4, 8]
        case "km":
            return [1, 3, 5, 10]
        case "miles":
            return [1, 3, 5, 10]
        case "pages":
            return [10, 20, 30, 50]
        case "ml":
            return [500, 1000, 1500, 2000]
        default:
            return [1, 2, 3, 5]
        }
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------
    private func updateUnitsForActivity() {
        availableUnits = selectedActivityType.unitOptions

        if selectedUnit.isEmpty ||
            !availableUnits.map({ $0.label }).contains(selectedUnit) {
            selectedUnit = availableUnits.first?.label ?? ""
            healthySuggestion = availableUnits.first?.suggestion ?? ""
        }
    }

    private func checkHealthyLimit(value: Int) {
        guard let limit = selectedActivityType.healthyLimit else {
            showingHealthWarning = false
            healthWarning = ""
            return
        }

        if selectedUnit == limit.unit && value > limit.maxValue {
            healthWarning = limit.warningMessage

            withAnimation(.easeInOut(duration: 0.3)) {
                showingHealthWarning = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingHealthWarning = false
            }

            healthWarning = ""
        }
    }

    private func addReminderFromPicker() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: newReminderTime)
        let minute = calendar.component(.minute, from: newReminderTime)
        let newReminder = ReminderTime(hour: hour, minute: minute)

        let isDuplicate = reminders.contains {
            $0.hour == hour && $0.minute == minute
        }

        if !isDuplicate {
            withAnimation(.spring(duration: 0.3)) {
                reminders.append(newReminder)

                reminders.sort {
                    ($0.hour * 60 + $0.minute) <
                    ($1.hour * 60 + $1.minute)
                }
            }

            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        }

        showingTimePicker = false
    }

    private func applyPreset(_ preset: PresetGoal) {
        withAnimation(.spring(duration: 0.3)) {
            goalName = preset.name
            selectedEmoji = preset.emoji
            selectedSymbol = preset.sfSymbol
            selectedCategory = preset.category
            selectedType = preset.goalType
            selectedActivityType = preset.activityType
            selectedPriority = preset.priority
            targetValue = preset.targetValue
            selectedRepeatType = preset.repeatType
            showingPresets = false

            updateUnitsForActivity()

            selectedUnit = preset.unit.isEmpty
                ? (availableUnits.first?.label ?? "")
                : preset.unit

            healthySuggestion = availableUnits
                .first(where: { $0.label == selectedUnit })?.suggestion ?? ""
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func loadExistingGoal(_ goal: Goal) {
        goalName = goal.name
        selectedEmoji = goal.emoji
        selectedSymbol = goal.sfSymbol
        selectedCategory = goal.category
        selectedType = goal.goalType
        selectedActivityType = goal.activityType
        selectedPriority = goal.priority
        targetValue = goal.targetValue
        selectedRepeatType = goal.repeatType
        customRepeatDays = goal.customRepeatDaysArray
        reminders = goal.reminders

        updateUnitsForActivity()

        selectedUnit = goal.unit.isEmpty
            ? (availableUnits.first?.label ?? "")
            : goal.unit

        healthySuggestion = availableUnits
            .first(where: { $0.label == selectedUnit })?.suggestion ?? ""
    }

    // --------------------------------------------------------
    // MARK: - Save Goal
    // --------------------------------------------------------
    private func saveGoal() async {
        let trimmedName = goalName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !isEditMode && viewModel.isDuplicateGoal(name: trimmedName) {
            withAnimation(.spring(duration: 0.3)) {
                showingDuplicateError = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    self.showingDuplicateError = false
                }
            }

            UINotificationFeedbackGenerator()
                .notificationOccurred(.error)

            return
        }

        var shouldShowManualHealthNotice = false

        if shouldRequestHealthAccess {
            let granted = await viewModel.requestHealthKitAccess()

            if granted {
                isHealthSyncEnabled = true
            }

            shouldShowManualHealthNotice = !granted
        }

        if let existing = existingGoal {
            viewModel.updateGoal(
                existing,
                name: trimmedName,
                emoji: selectedEmoji,
                sfSymbol: selectedSymbol,
                category: selectedCategory,
                activityType: selectedActivityType,
                priority: selectedPriority,
                goalType: selectedType,
                targetValue: targetValue,
                unit: selectedUnit,
                repeatType: selectedRepeatType,
                customRepeatDays: customRepeatDays,
                reminders: reminders
            )
        } else {
            viewModel.addGoal(
                name: trimmedName,
                emoji: selectedEmoji,
                sfSymbol: selectedSymbol,
                category: selectedCategory,
                activityType: selectedActivityType,
                goalType: selectedType,
                priority: selectedPriority,
                targetValue: selectedType == .progress ? targetValue : 1,
                unit: selectedType == .progress ? selectedUnit : "",
                repeatType: selectedRepeatType,
                customRepeatDays: customRepeatDays,
                reminders: reminders
            )
        }

        if shouldShowManualHealthNotice {
            showingHealthManualNotice = true
        } else {
            dismiss()
        }
    }

    // --------------------------------------------------------
    // MARK: - sfSymbolFor
    // --------------------------------------------------------
    private func sfSymbolFor(category: GoalCategory) -> String {
        switch category {
        case .fitness:
            return "figure.run"
        case .mind:
            return "brain.head.profile"
        case .health:
            return "heart.fill"
        case .social:
            return "person.2.fill"
        case .creativity:
            return "paintbrush.fill"
        case .custom:
            return "star.fill"
        }
    }
    
    
    // --------------------------------------------------------
    // MARK: - Add Goal Coach Mark
    // --------------------------------------------------------
    private struct AddGoalCoachStep {
        let emoji: String
        let title: String
        let message: String
        let bullets: [String]
        let accent: Color
    }

    private var addGoalCoachSteps: [AddGoalCoachStep] {
        [
            AddGoalCoachStep(
                emoji: "⚡",
                title: "Quick Add Presets",
                message: "Use ready-made goals when you want to start fast. Presets fill in useful details automatically.",
                bullets: [
                    "Tap a preset to auto-fill",
                    "Good for common habits",
                    "You can still customize after"
                ],
                accent: .yellow
            ),
            AddGoalCoachStep(
                emoji: "✍️",
                title: "Name Your Goal",
                message: "Write a clear goal name. MindSnap can suggest emojis and detect activity types from what you type.",
                bullets: [
                    "Example: Morning Run",
                    "Emoji can be changed",
                    "Activity can be detected"
                ],
                accent: .blue
            ),
            AddGoalCoachStep(
                emoji: "🚨",
                title: "Set Priority",
                message: "Priority helps important goals stand out. High priority goals appear more clearly on the Goals screen.",
                bullets: [
                    "High for must-do goals",
                    "Medium for normal goals",
                    "Low for flexible goals"
                ],
                accent: .red
            ),
            AddGoalCoachStep(
                emoji: "📊",
                title: "Choose Tracking Type",
                message: "Checkbox goals are simple yes/no goals. Progress goals track numbers like steps, glasses, pages, or minutes.",
                bullets: [
                    "Checkbox: complete once",
                    "Progress: track amount",
                    "Progress goals can earn partial points"
                ],
                accent: .purple
            ),
            AddGoalCoachStep(
                emoji: "🎯",
                title: "Set Daily Target",
                message: "For progress goals, choose a realistic target and unit. Smaller targets are easier to keep consistently.",
                bullets: [
                    "Set target amount",
                    "Choose the right unit",
                    "Use quick values"
                ],
                accent: .green
            ),
            AddGoalCoachStep(
                emoji: "🔁",
                title: "Repeat Schedule",
                message: "Choose when your goal should appear. Daily is best for habits, while custom days work well for flexible routines.",
                bullets: [
                    "Daily, weekdays, weekends",
                    "Custom selected days",
                    "Today-only goals disappear tomorrow"
                ],
                accent: .teal
            ),
            AddGoalCoachStep(
                emoji: "🔔",
                title: "Add Reminders",
                message: "Reminders help you come back at the right time. If notifications are disabled, MindSnap will guide you.",
                bullets: [
                    "Add one or more times",
                    "Medicine reminders are prominent",
                    "Permission is required"
                ],
                accent: .orange
            ),
            AddGoalCoachStep(
                emoji: "❤️",
                title: "Health-Compatible Goals",
                message: "Some progress goals can use Apple Health when you allow it. If not, manual progress still works.",
                bullets: [
                    "Walking, running, workouts",
                    "Optional Health permission",
                    "Manual update is always available"
                ],
                accent: .pink
            ),
            AddGoalCoachStep(
                emoji: "✨",
                title: "You’re Ready",
                message: "Create goals that are simple, realistic, and easy to repeat. Consistency matters more than intensity.",
                bullets: [
                    "Start with one goal",
                    "Keep it realistic",
                    "Tap Add Goal when ready"
                ],
                accent: .indigo
            )
        ]
    }

    private var currentAddGoalCoachStep: AddGoalCoachStep {
        addGoalCoachSteps[addGoalCoachStep]
    }

    private var isLastAddGoalCoachStep: Bool {
        addGoalCoachStep == addGoalCoachSteps.count - 1
    }

    private func presentAddGoalCoachMarkIfNeeded() {
        guard !isEditMode else { return }
        guard !hasSeenAddGoalCoachMark else { return }
        guard !showingTimePicker else { return }
        guard !showingPermissionDenied else { return }
        guard !showingHealthManualNotice else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard !isEditMode else { return }
            guard !hasSeenAddGoalCoachMark else { return }
            guard !showingTimePicker else { return }
            guard !showingPermissionDenied else { return }
            guard !showingHealthManualNotice else { return }

            addGoalCoachStep = 0

            withAnimation(.easeInOut(duration: 0.25)) {
                showingAddGoalCoachMark = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(duration: 0.45, bounce: 0.30)) {
                    addGoalCoachAnimate = true
                }
            }
        }
    }

    private func nextAddGoalCoachStep() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        if isLastAddGoalCoachStep {
            completeAddGoalCoachMark()
        } else {
            withAnimation(.easeInOut(duration: 0.20)) {
                addGoalCoachAnimate = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                addGoalCoachStep += 1

                withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                    addGoalCoachAnimate = true
                }
            }
        }
    }

    private func previousAddGoalCoachStep() {
        guard addGoalCoachStep > 0 else { return }

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        withAnimation(.easeInOut(duration: 0.20)) {
            addGoalCoachAnimate = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            addGoalCoachStep -= 1

            withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                addGoalCoachAnimate = true
            }
        }
    }

    private func completeAddGoalCoachMark() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        hasSeenAddGoalCoachMark = true

        withAnimation(.easeInOut(duration: 0.25)) {
            addGoalCoachAnimate = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingAddGoalCoachMark = false
            }
        }
    }

    private var addGoalCoachMarkOverlay: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.82 : 0.70)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                addGoalCoachCard
                    .padding(.horizontal, 22)
                    .padding(.bottom, 34)
                    .opacity(addGoalCoachAnimate ? 1 : 0)
                    .offset(y: addGoalCoachAnimate ? 0 : 34)
                    .scaleEffect(addGoalCoachAnimate ? 1 : 0.96)
            }
        }
    }

    private var addGoalCoachCard: some View {
        VStack(spacing: 18) {
            addGoalCoachProgressHeader
            addGoalCoachEmoji

            VStack(spacing: 8) {
                Text(currentAddGoalCoachStep.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Text(currentAddGoalCoachStep.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            addGoalCoachBullets
            addGoalCoachButtons
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            currentAddGoalCoachStep.accent.opacity(
                                colorScheme == .dark ? 0.25 : 0.15
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0 : 0.18),
                    radius: 26,
                    x: 0,
                    y: 14
                )
        )
    }

    private var addGoalCoachProgressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("ADD GOAL GUIDE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(secondaryText)
                    .tracking(1.0)

                Spacer()

                Text("\(addGoalCoachStep + 1)/\(addGoalCoachSteps.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(rowFill)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(rowFill)
                        .frame(height: 8)

                    Capsule()
                        .fill(currentAddGoalCoachStep.accent)
                        .frame(
                            width: geo.size.width *
                            CGFloat(addGoalCoachStep + 1) /
                            CGFloat(addGoalCoachSteps.count),
                            height: 8
                        )
                        .animation(.spring(duration: 0.35), value: addGoalCoachStep)
                }
            }
            .frame(height: 8)
        }
    }

    private var addGoalCoachEmoji: some View {
        ZStack {
            Circle()
                .fill(
                    currentAddGoalCoachStep.accent.opacity(
                        colorScheme == .dark ? 0.16 : 0.09
                    )
                )
                .frame(width: 96, height: 96)

            Circle()
                .fill(rowFill)
                .frame(width: 74, height: 74)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )

            Text(currentAddGoalCoachStep.emoji)
                .font(.system(size: 42))
        }
        .id("addGoalCoachEmoji-\(addGoalCoachStep)")
        .transition(.scale.combined(with: .opacity))
    }

    private var addGoalCoachBullets: some View {
        VStack(spacing: 8) {
            ForEach(currentAddGoalCoachStep.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(currentAddGoalCoachStep.accent)
                        .padding(.top, 1)

                    Text(bullet)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(rowFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private var addGoalCoachButtons: some View {
        VStack(spacing: 10) {
            Button {
                nextAddGoalCoachStep()
            } label: {
                HStack(spacing: 8) {
                    if isLastAddGoalCoachStep {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                    }

                    Text(isLastAddGoalCoachStep ? "Start Creating Goals" : "Continue")
                        .font(.headline)
                        .fontWeight(.bold)

                    if !isLastAddGoalCoachStep {
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundStyle(primaryButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(primaryButtonBackground)
                )
            }
            .buttonStyle(.plain)

            HStack {
                if addGoalCoachStep > 0 {
                    Button {
                        previousAddGoalCoachStep()
                    } label: {
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(secondaryText)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if !isLastAddGoalCoachStep {
                    Button {
                        completeAddGoalCoachMark()
                    } label: {
                        Text("Skip Guide")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self,
        GoalCompletion.self,
        configurations: config
    )

    let viewModel = GoalViewModel(modelContext: container.mainContext)

    AddGoalView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("Edit Mode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self,
        GoalCompletion.self,
        configurations: config
    )

    let viewModel = GoalViewModel(modelContext: container.mainContext)

    let goal = Goal(
        name: "Morning Run",
        emoji: "🏃",
        sfSymbol: "figure.run",
        category: .fitness,
        goalType: .progress,
        activityType: .running,
        priority: .medium,
        targetValue: 5,
        unit: "km"
    )

    AddGoalView(viewModel: viewModel, existingGoal: goal)
        .modelContainer(container)
}

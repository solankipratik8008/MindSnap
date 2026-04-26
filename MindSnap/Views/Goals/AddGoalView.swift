//
//  AddGoalView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
// ============================================================
// AddGoalView.swift
// MindSnap — FULLY FIXED
//
// FIXES:
// 1. Uses existingGoal (not editingGoal) parameter
// 2. No hasReminder / reminderTime — uses [ReminderTime]
// 3. Correct GoalCategory cases: fitness/mind/health/social/creativity/custom
// 4. Correct scheduleGoalReminders signature
// 5. Correct cancelGoalReminders signature
// 6. activityType before goalType in addGoal call
// 7. Correct sfSymbolFor switch cases
// ============================================================

import SwiftUI
import SwiftData
import UserNotifications

struct AddGoalView: View {

    let viewModel: GoalViewModel
    var existingGoal: Goal? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // ---- Basic info ----
    @State private var goalName = ""
    @State private var selectedEmoji = "⭐"
    @State private var selectedSymbol = "star.fill"
    @State private var selectedCategory = GoalCategory.fitness
    @State private var selectedType = GoalType.checkbox
    @State private var selectedActivityType = GoalActivityType.custom
    @State private var selectedPriority = GoalPriority.medium

    // ---- Progress ----
    @State private var targetValue = 1
    @State private var selectedUnit = ""
    @State private var availableUnits: [SmartUnit] = []

    // ---- Repeat ----
    @State private var selectedRepeatType = GoalRepeatType.daily
    @State private var customRepeatDays: [Int] = [1,2,3,4,5]

    // ---- Reminders — uses [ReminderTime] array ----
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

    private var isEditMode: Bool { existingGoal != nil }

    private let dayLabels = ["Mo","Tu","We","Th","Fr","Sa","Su"]

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
        "🏃","🏋️","🧘","🚶","🏊","🚴","🤸","⚽","🏀","🎾",
        "💧","😴","🥗","💊","❤️","🧠","🦷","👁","🦵","🦴",
        "📚","🎓","✍️","🎵","💻","🗣️","🎨","📸","🍳","🌱",
        "📞","👨‍👩‍👧‍�","🤝","📌","🎁","☕","🌅","🌙","⭐","🔥",
        "💪","🏆","🎯","✅","💡","🚀","🌈","⚡","🎉","🙏"
    ]

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Presets
                    if !isEditMode {
                        presetGoalsSection
                    }

                    // Duplicate error
                    if showingDuplicateError {
                        duplicateErrorBanner
                            .transition(.move(edge: .top)
                                .combined(with: .opacity))
                    }

                    // Name
                    goalNameSection

                    // Priority
                    prioritySection

                    // Category
                    categorySection

                    // Goal type
                    goalTypeSection

                    // Progress target (only for progress type)
                    if selectedType == .progress {
                        progressTargetSection
                    }

                    // Icon
                    iconPickerSection

                    // Repeat
                    repeatSection

                    // Reminders
                    remindersSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditMode ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Update" : "Add Goal") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        goalName.isEmpty ? Color.secondary : Color.purple
                    )
                    .disabled(goalName.isEmpty)
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
        }
        .onAppear {
            if let goal = existingGoal {
                loadExistingGoal(goal)
            }
            updateUnitsForActivity()
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
                .foregroundStyle(.yellow)
                .font(.subheadline)
            Text("'\(goalName)' already exists in today's goals!")
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(colorScheme == .dark ? 0.15 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
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
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingPresets.toggle()
                    }
                } label: {
                    Image(systemName: showingPresets ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        .background(RoundedRectangle(cornerRadius: 16).fill(cardFill))
    }

    private func presetCard(preset: PresetGoal) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    preset.category.color.opacity(colorScheme == .dark ? 0.35 : 0.2),
                                    preset.category.secondaryColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: preset.sfSymbol)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            preset.category.color,
                            preset.category.secondaryColor
                        )
                        .font(.system(size: 18))

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
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(rowFill))
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Goal Name Section
    // --------------------------------------------------------
    private var goalNameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Goal Name", systemImage: "pencil")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showingEmojiPicker.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedCategory.color.opacity(colorScheme == .dark ? 0.25 : 0.12))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Circle().stroke(
                                    selectedCategory.color.opacity(colorScheme == .dark ? 0.5 : 0.2),
                                    lineWidth: 1.5
                                )
                            )
                        Text(selectedEmoji)
                            .font(.system(size: 26))
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("e.g. Morning Run, Take Medicine...", text: $goalName)
                        .font(.body)

                    if !aiSuggestedEmoji.isEmpty && aiSuggestedEmoji != "⭐" {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                            Text("AI suggested \(aiSuggestedEmoji)")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardFill))

            if showingEmojiPicker {
                emojiPickerGrid
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var emojiPickerGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose Emoji")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 10),
                spacing: 8
            ) {
                ForEach(customEmojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        withAnimation { showingEmojiPicker = false }
                    } label: {
                        Text(emoji)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(
                                    selectedEmoji == emoji
                                        ? selectedCategory.color.opacity(0.2)
                                        : Color.clear
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardFill))
    }

    // --------------------------------------------------------
    // MARK: - Priority Section
    // --------------------------------------------------------
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Priority", systemImage: "exclamationmark.circle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(GoalPriority.allCases, id: \.self) { priority in
                    priorityCard(priority: priority)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: selectedPriority.icon)
                    .font(.caption)
                    .foregroundStyle(selectedPriority.color)
                Text(selectedPriority.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedPriority.color.opacity(colorScheme == .dark ? 0.12 : 0.07))
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
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? priority.color : Color(.systemGray5))
                        .frame(width: 36, height: 36)
                    Image(systemName: priority.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? .white : priority.color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(duration: 0.3, bounce: 0.3), value: isSelected)

                Text(priority.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? priority.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? priority.color.opacity(colorScheme == .dark ? 0.15 : 0.08) : cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? priority.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
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
            Label("Category", systemImage: "square.grid.2x2")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

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
                        isSelected ? .white : category.color,
                        isSelected ? .white.opacity(0.7) : category.secondaryColor
                    )
                    .font(.system(size: 13))

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [category.color, category.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [
                                    category.color.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                    category.color.opacity(colorScheme == .dark ? 0.15 : 0.07)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                    )
                    .overlay(
                        Capsule().stroke(
                            category.color.opacity(isSelected ? 0 : colorScheme == .dark ? 0.3 : 0.15),
                            lineWidth: 1
                        )
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Goal Type Section
    // --------------------------------------------------------
    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tracking Type", systemImage: "chart.bar.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

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
                    if targetValue <= 1 { targetValue = 5 }
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
                            isSelected ? selectedCategory.color : .secondary,
                            isSelected ? selectedCategory.secondaryColor : Color(.systemGray4)
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
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Text(type.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? selectedCategory.color.opacity(colorScheme == .dark ? 0.18 : 0.08)
                            : cardFill
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected
                                    ? selectedCategory.color.opacity(0.4)
                                    : Color.white.opacity(colorScheme == .dark ? 0.06 : 0),
                                lineWidth: 1.5
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
            Label("Daily Target", systemImage: "target")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                // Stepper
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Amount")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 14) {
                            Button {
                                if targetValue > 1 { targetValue -= smartDecrement }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(targetValue > 1 ? selectedCategory.color : Color(.systemGray4))
                            }
                            .buttonStyle(.plain)

                            VStack(spacing: 2) {
                                Text("\(targetValue)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
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

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Quick set")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
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
                                        .foregroundStyle(targetValue == value ? .white : selectedCategory.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(targetValue == value ? selectedCategory.color : selectedCategory.color.opacity(0.12))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(width: 110)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(cardFill))

                // Health warning
                if showingHealthWarning && !healthWarning.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(healthWarning)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Unit picker
                if !availableUnits.isEmpty && selectedActivityType.needsUnit {
                    unitPickerSection
                }

                // Health suggestion
                if !healthySuggestion.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(healthySuggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(colorScheme == .dark ? 0.12 : 0.07))
                    )
                }
            }
        }
    }

    private var unitPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

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
                                .foregroundStyle(selectedUnit == unit.label ? .white : selectedCategory.color)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedUnit == unit.label
                                                ? LinearGradient(
                                                    colors: [selectedCategory.color, selectedCategory.secondaryColor],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                  )
                                                : LinearGradient(
                                                    colors: [
                                                        selectedCategory.color.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                                        selectedCategory.color.opacity(colorScheme == .dark ? 0.15 : 0.07)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                  )
                                        )
                                        .overlay(
                                            Capsule().stroke(
                                                selectedCategory.color.opacity(selectedUnit == unit.label ? 0 : colorScheme == .dark ? 0.3 : 0.2),
                                                lineWidth: 1
                                            )
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selectedUnit == unit.label ? 1.05 : 1.0)
                        .animation(.spring(duration: 0.3, bounce: 0.3), value: selectedUnit)
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
            Label("Icon", systemImage: "square.grid.3x3")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

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
                                ? LinearGradient(
                                    colors: [selectedCategory.color, selectedCategory.secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [
                                        colorScheme == .dark ? Color.white.opacity(0.1) : Color(.systemGray5),
                                        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: symbol)
                        .symbolRenderingMode(isSelected ? .monochrome : .palette)
                        .foregroundStyle(
                            isSelected ? .white : selectedCategory.color,
                            isSelected ? .white.opacity(0.7) : selectedCategory.secondaryColor
                        )
                        .font(.system(size: 20))
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)

                Text(name)
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? selectedCategory.color : .secondary)
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
            Label("Repeat Schedule", systemImage: "arrow.clockwise")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(GoalRepeatType.allCases, id: \.self) { repeatType in
                    repeatTypeRow(repeatType: repeatType)
                    if repeatType != GoalRepeatType.allCases.last {
                        Divider().padding(.leading, 44)
                    }
                }

                if selectedRepeatType == .custom {
                    Divider()
                    customDaySelector
                        .padding(14)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(cardFill))
            .animation(.easeInOut(duration: 0.2), value: selectedRepeatType)

            if selectedRepeatType == .none {
                HStack(spacing: 6) {
                    Image(systemName: "1.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("This goal will only appear today and automatically disappear tomorrow.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.07))
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
                    .fill(isSelected ? accentColor : Color(.systemGray5))
                    .frame(width: 30, height: 30)
                Image(systemName: repeatType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(repeatType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

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
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? accentColor : Color(.systemGray4))
                .font(.title3)
        }
        .padding(14)
        .contentShape(Rectangle())
        .background(isSelected ? accentColor.opacity(colorScheme == .dark ? 0.12 : 0.06) : Color.clear)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRepeatType = repeatType
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var customDaySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Days")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

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
                            .foregroundStyle(isSelected ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? selectedCategory.color : Color(.systemGray5))
                            )
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                            .animation(.spring(duration: 0.2), value: isSelected)
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
            Label("Reminders", systemImage: "bell.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                if reminders.isEmpty {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("No reminders set")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(16)
                } else {
                    ForEach(reminders) { reminder in
                        reminderRow(reminder: reminder)
                        if reminder.id != reminders.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }

                Divider()

                // Add reminder button — requests permission on tap
                Button {
                    requestPermissionThenShowPicker()
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(selectedCategory.color)
                                .frame(width: 28, height: 28)
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("Add Reminder")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedCategory.color)
                        Spacer()
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(cardFill))

            if selectedActivityType == .medicine {
                HStack(spacing: 6) {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text("Medicine reminders use prominent, time-sensitive alerts when available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.12 : 0.07))
                )
            }
        }
    }

    private func reminderRow(reminder: ReminderTime) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(selectedCategory.color.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(selectedCategory.color)
            }

            Text(reminder.timeString)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

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
    // FIX: Permission requested HERE when user taps Add Reminder
    // --------------------------------------------------------
    private func requestPermissionThenShowPicker() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    newReminderTime = Calendar.current.date(
                        bySettingHour: 8, minute: 0, second: 0, of: Date()
                    ) ?? Date()
                    showingTimePicker = true

                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound, .badge]
                    ) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                newReminderTime = Calendar.current.date(
                                    bySettingHour: 8, minute: 0, second: 0, of: Date()
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
                        .fill(
                            LinearGradient(
                                colors: [
                                    selectedCategory.color.opacity(0.2),
                                    selectedCategory.secondaryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(selectedCategory.color)
                }
                .padding(.top, 20)

                Text("Set Reminder Time")
                    .font(.headline)

                DatePicker(
                    "Reminder Time",
                    selection: $newReminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)

                Button {
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
                            reminders.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }

                    showingTimePicker = false
                } label: {
                    Text("Add Reminder")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [selectedCategory.color, selectedCategory.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showingTimePicker = false }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // --------------------------------------------------------
    // MARK: - Adaptive Colors
    // --------------------------------------------------------
    private var cardFill: Color {
        colorScheme == .dark
            ? Color(red: 0.17, green: 0.17, blue: 0.18)
            : Color.white
    }

    private var rowFill: Color {
        colorScheme == .dark
            ? Color(red: 0.2, green: 0.2, blue: 0.22)
            : Color(.systemGray6)
    }

    // --------------------------------------------------------
    // MARK: - Smart Helpers
    // --------------------------------------------------------
    private var smartIncrement: Int {
        switch selectedUnit {
        case "steps": return 500
        case "ml":    return 100
        default:      return 1
        }
    }

    private var smartDecrement: Int {
        switch selectedUnit {
        case "steps": return 500
        case "ml":    return 100
        default:      return 1
        }
    }

    private var quickValues: [Int] {
        switch selectedUnit {
        case "glasses": return [6, 8, 10, 12]
        case "steps":   return [5000, 8000, 10000, 15000]
        case "minutes": return [15, 30, 45, 60]
        case "hours":   return [1, 2, 4, 8]
        case "km":      return [1, 3, 5, 10]
        case "miles":   return [1, 3, 5, 10]
        case "pages":   return [10, 20, 30, 50]
        case "ml":      return [500, 1000, 1500, 2000]
        case "laps":    return [10, 20, 30, 40]
        default:        return [1, 2, 3, 5]
        }
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------
    private func updateUnitsForActivity() {
        availableUnits = selectedActivityType.unitOptions
        if selectedUnit.isEmpty || !availableUnits.map({ $0.label }).contains(selectedUnit) {
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
            withAnimation(.easeInOut(duration: 0.3)) { showingHealthWarning = true }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { showingHealthWarning = false }
            healthWarning = ""
        }
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
        // FIX: Goal uses [ReminderTime] — no hasReminder/reminderTime
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
    private func saveGoal() {
        // Duplicate check (new goals only)
        if !isEditMode && viewModel.isDuplicateGoal(name: goalName) {
            withAnimation(.spring(duration: 0.3)) { showingDuplicateError = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { self.showingDuplicateError = false }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        if let existing = existingGoal {
            // ---- EDIT MODE ----
            viewModel.updateGoal(
                existing,
                name: goalName,
                emoji: selectedEmoji,
                sfSymbol: selectedSymbol,
                category: selectedCategory,
                activityType: selectedActivityType,
                priority: selectedPriority,
                goalType: selectedType,           // ADD
                targetValue: targetValue,          // ADD
                unit: selectedUnit,                // ADD
                repeatType: selectedRepeatType,
                customRepeatDays: customRepeatDays,
                reminders: reminders
            )
        } else {
            // ---- CREATE MODE ----
            // FIX: activityType before goalType
            viewModel.addGoal(
                name: goalName,
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
        dismiss()
    }

    // --------------------------------------------------------
    // MARK: - sfSymbolFor (correct GoalCategory cases)
    // --------------------------------------------------------
    private func sfSymbolFor(category: GoalCategory) -> String {
        switch category {
        case .fitness:    return "figure.run"
        case .mind:       return "brain.head.profile"
        case .health:     return "heart.fill"
        case .social:     return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .custom:     return "star.fill"
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self, GoalCompletion.self,
        configurations: config
    )
    let viewModel = GoalViewModel(modelContext: container.mainContext)
    AddGoalView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("Edit Mode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Goal.self, GoalCompletion.self,
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

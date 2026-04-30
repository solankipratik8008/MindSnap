//
//  CalendarMoodView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-22.
//

// ============================================================
// CalendarMoodView.swift
// MindSnap — Premium Monochrome Mood Calendar
//
// SAFE UI UPDATE:
// 1. Keeps same calendar calculation logic
// 2. Keeps month navigation
// 3. Keeps selected day detail
// 4. Keeps entry preview
// 5. Keeps haptics
// 6. Updates UI to professional black/white theme
// 7. Mood colors remain only as useful emotional accents
// ============================================================

import SwiftUI
import SwiftData

struct CalendarMoodView: View {

    let entries: [JournalEntry]

    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date? = nil
    @State private var animationDirection: Int = 1
    @State private var showingEntries = false

    @Environment(\.colorScheme) private var colorScheme

    private let calendar = Calendar.current

    // --------------------------------------------------------
    // MARK: - Premium Theme
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
    // MARK: - Computed Properties
    // --------------------------------------------------------
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        guard let firstDay = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: currentMonth
            )
        ) else {
            return []
        }

        guard let range = calendar.range(
            of: .day,
            in: .month,
            for: firstDay
        ) else {
            return []
        }

        let firstWeekday = calendar.component(
            .weekday,
            from: firstDay
        )

        let paddingDays = (firstWeekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: paddingDays)

        for day in range {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDay
            ) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private var weekdayHeaders: [String] {
        ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    }

    private var selectedDayEntries: [JournalEntry] {
        guard let day = selectedDay else { return [] }

        return entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: day)
        }
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 16) {
                monthHeader
                weekdayRow

                dayGrid
                    .id(currentMonth)
                    .transition(
                        .asymmetric(
                            insertion: .move(
                                edge: animationDirection > 0
                                ? .trailing
                                : .leading
                            )
                            .combined(with: .opacity),
                            removal: .move(
                                edge: animationDirection > 0
                                ? .leading
                                : .trailing
                            )
                            .combined(with: .opacity)
                        )
                    )

                moodLegend
            }
            .padding(16)
            .background(premiumCard(cornerRadius: 22))

            if let day = selectedDay {
                selectedDayDetail(for: day)
                    .transition(
                        .opacity.combined(
                            with: .move(edge: .top)
                        )
                    )
                    .padding(.top, 12)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: selectedDay)
    }

    // --------------------------------------------------------
    // MARK: - Month Header
    // --------------------------------------------------------
    private var monthHeader: some View {
        HStack {
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(primaryText)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(softBackground)
                            .overlay(
                                Circle()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(monthTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)

                Text("Mood history")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(
                        isCurrentMonthOrLater
                        ? tertiaryText
                        : primaryText
                    )
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(
                                isCurrentMonthOrLater
                                ? softBackground.opacity(0.65)
                                : softBackground
                            )
                            .overlay(
                                Circle()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(isCurrentMonthOrLater)
        }
    }

    // --------------------------------------------------------
    // MARK: - Weekday Row
    // --------------------------------------------------------
    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayHeaders, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 2)
    }

    // --------------------------------------------------------
    // MARK: - Day Grid
    // --------------------------------------------------------
    private var dayGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 4),
            count: 7
        )

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Day Cell
    // --------------------------------------------------------
    private func dayCell(for date: Date) -> some View {
        let dayEntries = entriesFor(date: date)
        let dominantMood = dominantMoodFor(entries: dayEntries)

        let isSelected = selectedDay.map {
            calendar.isDate($0, inSameDayAs: date)
        } ?? false

        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        let dayNumber = calendar.component(.day, from: date)

        return Button {
            if !isFuture {
                withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                    if isSelected {
                        selectedDay = nil
                    } else {
                        selectedDay = date

                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                    }
                }
            }
        } label: {
            ZStack {
                if let mood = dominantMood {
                    Circle()
                        .fill(
                            mood.color.opacity(
                                colorScheme == .dark ? 0.26 : 0.14
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(
                                    mood.color.opacity(
                                        colorScheme == .dark ? 0.20 : 0.16
                                    ),
                                    lineWidth: 1
                                )
                        )
                } else if isToday {
                    Circle()
                        .fill(softBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(primaryText.opacity(0.20), lineWidth: 1)
                        )
                }

                if isSelected {
                    Circle()
                        .stroke(primaryText, lineWidth: 2.5)
                        .frame(width: 43, height: 43)
                }

                VStack(spacing: 1) {
                    if let mood = dominantMood {
                        Text(mood.emoji)
                            .font(.system(size: 18))
                    } else {
                        Text("\(dayNumber)")
                            .font(.system(size: 14))
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(
                                isFuture
                                ? tertiaryText.opacity(0.65)
                                : isToday
                                    ? primaryText
                                    : secondaryText
                            )

                        if isToday {
                            Circle()
                                .fill(primaryText)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.55 : 1.0)
    }

    // --------------------------------------------------------
    // MARK: - Mood Legend
    // --------------------------------------------------------
    private var moodLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mood.color.opacity(colorScheme == .dark ? 0.85 : 0.70))
                            .frame(width: 8, height: 8)

                        Text(mood.emoji)
                            .font(.caption2)

                        Text(mood.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal, 8)
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

    // --------------------------------------------------------
    // MARK: - Selected Day Detail
    // --------------------------------------------------------
    private func selectedDayDetail(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedSelectedDate(date))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(primaryText)

                    if selectedDayEntries.isEmpty {
                        Text("No entries this day")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    } else {
                        Text("\(selectedDayEntries.count) \(selectedDayEntries.count == 1 ? "entry" : "entries")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedDay = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(primaryText)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(softBackground)
                                .overlay(
                                    Circle()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            if selectedDayEntries.isEmpty {
                HStack {
                    Spacer()

                    VStack(spacing: 8) {
                        Text("📝")
                            .font(.largeTitle)

                        Text("Nothing written this day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ForEach(selectedDayEntries) { entry in
                    entryDetailRow(entry: entry)

                    if entry.id != selectedDayEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 20))
    }

    // --------------------------------------------------------
    // MARK: - Entry Detail Row
    // --------------------------------------------------------
    private func entryDetailRow(entry: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {

            ZStack {
                Circle()
                    .fill(
                        entry.moodType.color.opacity(
                            colorScheme == .dark ? 0.22 : 0.11
                        )
                    )
                    .frame(width: 44, height: 44)
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

            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    Text(entry.moodType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.moodType.color)

                    Spacer()

                    Text(entryTime(entry.date))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }

                Text(entry.previewText)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(String(format: "Score: %+.2f", entry.sentimentScore))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.moodType.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    entry.moodType.color.opacity(
                                        colorScheme == .dark ? 0.16 : 0.10
                                    )
                                )
                        )

                    if !entry.tags.isEmpty {
                        Text("\(entry.tags.count) tags")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------
    private func navigateMonth(by value: Int) {
        animationDirection = value

        withAnimation(.easeInOut(duration: 0.35)) {
            currentMonth = calendar.date(
                byAdding: .month,
                value: value,
                to: currentMonth
            ) ?? currentMonth

            selectedDay = nil
        }

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    private func entriesFor(date: Date) -> [JournalEntry] {
        entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }

    private func dominantMoodFor(
        entries: [JournalEntry]
    ) -> MoodType? {
        guard !entries.isEmpty else { return nil }

        var moodCounts: [MoodType: Int] = [:]

        for entry in entries {
            moodCounts[entry.moodType, default: 0] += 1
        }

        return moodCounts.max(by: { $0.value < $1.value })?.key
    }

    private var isCurrentMonthOrLater: Bool {
        let currentComponents = calendar.dateComponents(
            [.year, .month],
            from: Date()
        )

        let displayComponents = calendar.dateComponents(
            [.year, .month],
            from: currentMonth
        )

        guard
            let currentYear = currentComponents.year,
            let currentMonthNum = currentComponents.month,
            let displayYear = displayComponents.year,
            let displayMonthNum = displayComponents.month
        else {
            return false
        }

        if displayYear > currentYear {
            return true
        }

        if displayYear == currentYear &&
            displayMonthNum >= currentMonthNum {
            return true
        }

        return false
    }

    private func formattedSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private func entryTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
    let calendar = Calendar.current

    let sampleData: [(Int, MoodType, Double, String)] = [
        (1, .happy, 0.82, "Great start to the month!"),
        (3, .calm, 0.35, "Peaceful morning walk."),
        (5, .anxious, -0.45, "Big presentation today."),
        (8, .happy, 0.91, "Weekend was amazing!"),
        (10, .neutral, 0.02, "Regular Tuesday."),
        (12, .sad, -0.67, "Feeling a bit down."),
        (15, .calm, 0.41, "Good meditation session."),
        (17, .happy, 0.78, "Got great news!"),
        (19, .anxious, -0.38, "Deadline coming up."),
        (22, .happy, 0.88, "Best day in a while!")
    ]

    let entries = sampleData.compactMap { day, mood, score, text -> JournalEntry? in
        var components = calendar.dateComponents(
            [.year, .month],
            from: Date()
        )
        components.day = day

        guard let date = calendar.date(from: components) else {
            return nil
        }

        let entry = JournalEntry(
            text: text,
            moodType: mood,
            sentimentScore: score
        )
        entry.date = date
        return entry
    }

    ScrollView {
        CalendarMoodView(entries: entries)
            .padding(16)
    }
    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

#Preview("Dark Mode") {
    let calendar = Calendar.current

    let sampleData: [(Int, MoodType, Double, String)] = [
        (1, .happy, 0.82, "Great start to the month!"),
        (3, .calm, 0.35, "Peaceful morning walk."),
        (5, .anxious, -0.45, "Big presentation today."),
        (8, .happy, 0.91, "Weekend was amazing!"),
        (10, .neutral, 0.02, "Regular Tuesday.")
    ]

    let entries = sampleData.compactMap { day, mood, score, text -> JournalEntry? in
        var components = calendar.dateComponents(
            [.year, .month],
            from: Date()
        )
        components.day = day

        guard let date = calendar.date(from: components) else {
            return nil
        }

        let entry = JournalEntry(
            text: text,
            moodType: mood,
            sentimentScore: score
        )
        entry.date = date
        return entry
    }

    ScrollView {
        CalendarMoodView(entries: entries)
            .padding(16)
    }
    .background(Color(red: 0.03, green: 0.03, blue: 0.035))
    .preferredColorScheme(.dark)
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

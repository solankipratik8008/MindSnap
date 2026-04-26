//
//  CalendarMoodView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-22.
//

// ============================================================
// CalendarMoodView.swift
// MindSnap — Beautiful animated mood calendar
//
// WHAT THIS FILE DOES:
// Shows a full month calendar in the Insights tab where:
//   - Each day has a colored mood dot
//   - Days with entries are highlighted with mood color
//   - Tapping a day shows what the user wrote
//   - Month can be navigated with arrows
//   - Smooth animations between months
//
// VISUAL DESIGN:
//   ┌─────────────────────────────┐
//   │  ← April 2026 →            │
//   │  Mo Tu We Th Fr Sa Su      │
//   │  ○  ○  😊 ○  😌 ○  ○      │
//   │  😢 ○  ○  😰 ○  ○  😊     │
//   │  ○  😐 ○  ○  😊 ○  ○      │
//   └─────────────────────────────┘
//   ┌─────────────────────────────┐
//   │ Apr 14 — 😊 Happy           │
//   │ "Today was absolutely..."   │
//   └─────────────────────────────┘
//
// MVVM ROLE: View layer
//            Receives entries array from InsightsView
//            All calendar calculation logic is internal
// ============================================================

import SwiftUI
import SwiftData

struct CalendarMoodView: View {

    // --------------------------------------------------------
    // entries — All journal entries
    // We filter by month/day internally
    // --------------------------------------------------------
    let entries: [JournalEntry]

    // --------------------------------------------------------
    // currentMonth — Which month is currently displayed
    // Starts as current month, arrows change it
    // --------------------------------------------------------
    @State private var currentMonth: Date = Date()

    // --------------------------------------------------------
    // selectedDay — Which day user tapped
    // nil = no day selected
    // Date = show entries for that day below calendar
    // --------------------------------------------------------
    @State private var selectedDay: Date? = nil

    // --------------------------------------------------------
    // animationDirection — Which way to animate month change
    // 1 = forward (next month slides in from right)
    // -1 = backward (prev month slides in from left)
    // --------------------------------------------------------
    @State private var animationDirection: Int = 1

    // --------------------------------------------------------
    // showingEntries — Controls entry detail sheet
    // --------------------------------------------------------
    @State private var showingEntries = false

    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // calendar — Shared calendar instance
    // --------------------------------------------------------
    private let calendar = Calendar.current

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------

    // --------------------------------------------------------
    // monthTitle — "April 2026" style string
    // --------------------------------------------------------
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    // --------------------------------------------------------
    // daysInMonth — Array of dates for current month grid
    //
    // Includes padding days from previous month to fill
    // the first row. E.g. if month starts on Wednesday,
    // Monday and Tuesday are filled with previous month days.
    //
    // Returns 42 dates (6 rows × 7 days) for consistent grid.
    // --------------------------------------------------------
    private var daysInMonth: [Date?] {
        // Get first day of current month
        guard let firstDay = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: currentMonth
            )
        ) else { return [] }

        // Get number of days in month
        guard let range = calendar.range(
            of: .day,
            in: .month,
            for: firstDay
        ) else { return [] }

        // Get weekday of first day (1=Sun, 2=Mon... 7=Sat)
        let firstWeekday = calendar.component(
            .weekday,
            from: firstDay
        )

        // Adjust for Monday-first calendar
        // iOS weekday: 1=Sun, 2=Mon... we want 1=Mon
        let paddingDays = (firstWeekday + 5) % 7

        // Build array: nil for padding + dates for month
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

        // Pad end to complete last row
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    // --------------------------------------------------------
    // weekdayHeaders — ["Mo", "Tu", "We"...]
    // --------------------------------------------------------
    private var weekdayHeaders: [String] {
        ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    }

    // --------------------------------------------------------
    // selectedDayEntries — Entries for the selected day
    // --------------------------------------------------------
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

            // ---- Calendar Card ----
            VStack(spacing: 16) {

                // ---- Month Navigation Header ----
                monthHeader

                // ---- Weekday Labels ----
                weekdayRow

                // ---- Day Grid ----
                // Animated transition between months
                dayGrid
                    .id(currentMonth) // Forces re-render on month change
                    .transition(
                        .asymmetric(
                            insertion: .move(
                                edge: animationDirection > 0
                                    ? .trailing : .leading
                            ).combined(with: .opacity),
                            removal: .move(
                                edge: animationDirection > 0
                                    ? .leading : .trailing
                            ).combined(with: .opacity)
                        )
                    )

                // ---- Legend ----
                moodLegend
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(
                            colorScheme == .dark ? 0.3 : 0.08
                        ),
                        radius: 12, x: 0, y: 4
                    )
            )

            // ---- Selected Day Detail ----
            if let day = selectedDay {
                selectedDayDetail(for: day)
                    .transition(.opacity.combined(
                        with: .move(edge: .top)
                    ))
                    .padding(.top, 12)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: selectedDay)
    }

    // --------------------------------------------------------
    // MARK: - Subviews
    // --------------------------------------------------------

    // --------------------------------------------------------
    // monthHeader
    //
    // Shows month name with left/right navigation arrows.
    // Tapping arrows animates to previous/next month.
    // --------------------------------------------------------
    private var monthHeader: some View {
        HStack {
            // ---- Previous month button ----
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple.opacity(0.7))
            }

            Spacer()

            // ---- Month + Year title ----
            Text(monthTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Spacer()

            // ---- Next month button ----
            // Disabled if current month is this month
            // (can't see future entries)
            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        isCurrentMonthOrLater
                            ? Color.gray.opacity(0.3)
                            : Color.purple.opacity(0.7)
                    )
            }
            .disabled(isCurrentMonthOrLater)
        }
    }

    // --------------------------------------------------------
    // weekdayRow — Mo Tu We Th Fr Sa Su header
    // --------------------------------------------------------
    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayHeaders, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // --------------------------------------------------------
    // dayGrid — The main calendar grid
    //
    // 7 columns × n rows grid of day cells.
    // Each cell shows:
    //   - Day number
    //   - Mood emoji (if entry exists)
    //   - Colored circle background (if entry exists)
    //   - Selected state (purple ring)
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
                    // Empty padding cell
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    // --------------------------------------------------------
    // dayCell(for:)
    //
    // A single day cell in the calendar grid.
    //
    // States:
    //   Has entry → colored circle + mood emoji
    //   No entry  → plain day number
    //   Selected  → purple ring around cell
    //   Today     → underline below number
    //   Future    → grayed out
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
                    // Toggle selection — tap again to deselect
                    if isSelected {
                        selectedDay = nil
                    } else {
                        selectedDay = date
                        // Light haptic on day tap
                        let haptic = UIImpactFeedbackGenerator(
                            style: .light
                        )
                        haptic.impactOccurred()
                    }
                }
            }
        } label: {
            ZStack {
                // ---- Background circle (if has entries) ----
                if let mood = dominantMood {
                    Circle()
                        .fill(mood.color.opacity(
                            colorScheme == .dark ? 0.35 : 0.2
                        ))
                        .frame(width: 40, height: 40)
                }

                // ---- Selected ring ----
                if isSelected {
                    Circle()
                        .stroke(Color.purple, lineWidth: 2.5)
                        .frame(width: 42, height: 42)
                }

                VStack(spacing: 0) {
                    if let mood = dominantMood {
                        // Has entry — show emoji
                        Text(mood.emoji)
                            .font(.system(size: 18))
                    } else {
                        // No entry — show day number
                        Text("\(dayNumber)")
                            .font(.system(size: 14))
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(
                                isFuture
                                    ? Color.secondary.opacity(0.4)
                                    : isToday
                                        ? Color.purple
                                        : Color.primary
                            )

                        // Today indicator dot
                        if isToday {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // moodLegend — Small colored dots with mood names
    // --------------------------------------------------------
    private var moodLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mood.color.opacity(0.7))
                            .frame(width: 8, height: 8)
                        Text(mood.emoji)
                            .font(.caption2)
                        Text(mood.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // --------------------------------------------------------
    // selectedDayDetail(for:)
    //
    // Shows a card below the calendar with entries
    // for the selected day.
    //
    // States:
    //   Has entries → shows each entry with mood + preview
    //   No entries  → shows "No entries" message
    // --------------------------------------------------------
    private func selectedDayDetail(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // ---- Header ----
            HStack {
                // Date title
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedSelectedDate(date))
                        .font(.headline)
                        .fontWeight(.bold)

                    if selectedDayEntries.isEmpty {
                        Text("No entries this day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(selectedDayEntries.count) \(selectedDayEntries.count == 1 ? "entry" : "entries")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Close button
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedDay = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }

            if selectedDayEntries.isEmpty {
                // ---- Empty state ----
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("📝")
                            .font(.largeTitle)
                        Text("Nothing written this day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                // ---- Entry list ----
                ForEach(selectedDayEntries) { entry in
                    entryDetailRow(entry: entry)

                    if entry.id != selectedDayEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(
                        colorScheme == .dark ? 0.3 : 0.08
                    ),
                    radius: 8, x: 0, y: 3
                )
        )
    }

    // --------------------------------------------------------
    // entryDetailRow(entry:)
    //
    // A single entry row in the selected day detail card.
    // Shows: emoji, mood name, time, and text preview.
    // --------------------------------------------------------
    private func entryDetailRow(entry: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {

            // ---- Mood emoji in colored circle ----
            ZStack {
                Circle()
                    .fill(entry.moodType.color.opacity(
                        colorScheme == .dark ? 0.3 : 0.15
                    ))
                    .frame(width: 44, height: 44)
                Text(entry.moodType.emoji)
                    .font(.title3)
            }

            // ---- Entry details ----
            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    // Mood name
                    Text(entry.moodType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.moodType.color)

                    Spacer()

                    // Time of entry
                    Text(entryTime(entry.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Entry text preview
                Text(entry.previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Score badge
                HStack(spacing: 4) {
                    Text(String(format: "Score: %+.2f",
                                entry.sentimentScore))
                        .font(.caption2)
                        .foregroundStyle(entry.moodType.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(entry.moodType.color.opacity(
                                    colorScheme == .dark ? 0.2 : 0.1
                                ))
                        )

                    // Tags if any
                    if !entry.tags.isEmpty {
                        Text("\(entry.tags.count) tags")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------

    // --------------------------------------------------------
    // navigateMonth(by:)
    // Moves calendar forward or backward by one month
    // --------------------------------------------------------
    private func navigateMonth(by value: Int) {
        animationDirection = value
        withAnimation(.easeInOut(duration: 0.35)) {
            currentMonth = calendar.date(
                byAdding: .month,
                value: value,
                to: currentMonth
            ) ?? currentMonth
            // Clear selection when changing months
            selectedDay = nil
        }

        // Light haptic on month change
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    // --------------------------------------------------------
    // entriesFor(date:)
    // Returns all entries written on a specific date
    // --------------------------------------------------------
    private func entriesFor(date: Date) -> [JournalEntry] {
        entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }

    // --------------------------------------------------------
    // dominantMoodFor(entries:)
    // Returns the most common mood from a set of entries
    // Returns nil if no entries
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // isCurrentMonthOrLater
    // True if displaying current or future month
    // Used to disable the "next month" button
    // --------------------------------------------------------
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
        else { return false }

        if displayYear > currentYear { return true }
        if displayYear == currentYear &&
           displayMonthNum >= currentMonthNum { return true }
        return false
    }

    // --------------------------------------------------------
    // formattedSelectedDate(_:)
    // "Wednesday, April 14" style string
    // --------------------------------------------------------
    private func formattedSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    // --------------------------------------------------------
    // entryTime(_:)
    // "9:30 AM" style time string
    // --------------------------------------------------------
    private func entryTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    let calendar = Calendar.current

    // Create sample entries for this month
    let sampleData: [(Int, MoodType, Double, String)] = [
        (1,  .happy,   0.82, "Great start to the month!"),
        (3,  .calm,    0.35, "Peaceful morning walk."),
        (5,  .anxious, -0.45, "Big presentation today."),
        (8,  .happy,   0.91, "Weekend was amazing!"),
        (10, .neutral, 0.02, "Regular Tuesday."),
        (12, .sad,     -0.67, "Feeling a bit down."),
        (15, .calm,    0.41, "Good meditation session."),
        (17, .happy,   0.78, "Got great news!"),
        (19, .anxious, -0.38, "Deadline coming up."),
        (22, .happy,   0.88, "Best day in a while!")
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
    .background(Color(.systemGroupedBackground))
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

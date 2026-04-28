//
//  JournalViewModel.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
// ============================================================
// JournalViewModel.swift
// MindSnap — PAGINATION + PERFORMANCE FIXED
// ============================================================

import SwiftData
import SwiftUI
import Foundation
import WidgetKit

@Observable
class JournalViewModel {

    // ---- Paginated entries ----
    var entries: [JournalEntry] = []

    // ---- Pagination state ----
    var isLoadingMore: Bool = false
    var hasMoreEntries: Bool = true
    var totalEntryCount: Int = 0

    // ---- Search ----
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                searchEntries()
            }
        }
    }
    var searchResults: [JournalEntry] = []
    var isSearching: Bool = false
    var errorMessage: String? = nil

    // ---- Pagination config ----
    private let pageSize = 50
    private var currentOffset = 0
     var isSearchMode: Bool { !searchText.isEmpty }

    private var modelContext: ModelContext
    private let sentimentService = SentimentService()

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    private func sortEntriesPinnedFirst(_ entries: [JournalEntry]) -> [JournalEntry] {
        entries.sorted { first, second in
            if first.isPinned != second.isPinned {
                return first.isPinned && !second.isPinned
            }

            return first.date > second.date
        }
    }
    var displayedEntries: [JournalEntry] {
        isSearchMode
            ? sortEntriesPinnedFirst(searchResults)
            : sortEntriesPinnedFirst(entries)
    }

    var filteredEntries: [JournalEntry] { displayedEntries }

    var streakCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueDays = Set(entries.map {
            calendar.startOfDay(for: $0.date)
        })
        guard !uniqueDays.isEmpty else { return 0 }

        let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: today
        ) ?? today
        var currentDay = uniqueDays.contains(today) ? today : yesterday
        guard uniqueDays.contains(currentDay) else { return 0 }

        var streak = 0
        while uniqueDays.contains(currentDay) {
            streak += 1
            currentDay = calendar.date(
                byAdding: .day,
                value: -1,
                to: currentDay
            ) ?? currentDay
        }
        return streak
    }

    var todaysMood: MoodType? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.first {
            calendar.startOfDay(for: $0.date) == today
        }?.moodType
    }

    // --------------------------------------------------------
    // MARK: - Init
    // --------------------------------------------------------
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchEntries()
    }

    // --------------------------------------------------------
    // MARK: - Fetch First Page
    // --------------------------------------------------------
    func fetchEntries() {
        do {
            let countDescriptor = FetchDescriptor<JournalEntry>()
            totalEntryCount = (
                try? modelContext.fetchCount(countDescriptor)
            ) ?? 0

            var descriptor = FetchDescriptor<JournalEntry>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = pageSize
            descriptor.fetchOffset = 0

            let fetched = try modelContext.fetch(descriptor)
            entries = sortEntriesPinnedFirst(fetched)
            currentOffset = entries.count
            hasMoreEntries = entries.count == pageSize

        } catch {
            errorMessage = "Failed to load entries."
        }
    }

    // --------------------------------------------------------
    // MARK: - Load More (Pagination)
    // --------------------------------------------------------
    func loadMoreIfNeeded(currentEntry entry: JournalEntry) {
        guard let index = entries.firstIndex(
            where: { $0.id == entry.id }
        ) else { return }

        let thresholdIndex = max(0, entries.count - 10)
        if index >= thresholdIndex {
            loadMore()
        }
    }

    func loadMore() {
        guard !isLoadingMore &&
              hasMoreEntries &&
              !isSearchMode else { return }

        isLoadingMore = true

        do {
            var descriptor = FetchDescriptor<JournalEntry>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = pageSize
            descriptor.fetchOffset = currentOffset

            let newEntries = try modelContext.fetch(descriptor)
            let sorted = sortEntriesPinnedFirst(newEntries)
            entries.append(contentsOf: sorted)
            entries = sortEntriesPinnedFirst(entries)
            currentOffset += newEntries.count
            hasMoreEntries = newEntries.count == pageSize

        } catch {
            print("loadMore error: \(error)")
        }

        isLoadingMore = false
    }

    // --------------------------------------------------------
    // MARK: - Search
    // --------------------------------------------------------
    func searchEntries() {
        guard !searchText.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        do {
            var descriptor = FetchDescriptor<JournalEntry>()
            descriptor.fetchLimit = 500

            let all = try modelContext.fetch(descriptor)
            let query = searchText.lowercased()

            let filtered = all.filter { entry in
                entry.text.lowercased().contains(query) ||
                entry.tags.contains {
                    $0.lowercased().contains(query)
                }
            }

            searchResults = sortEntriesPinnedFirst(filtered)
                .prefix(100)
                .map { $0 }

        } catch {
            print("searchEntries error: \(error)")
        }

        isSearching = false
    }

    // --------------------------------------------------------
    // MARK: - CRUD
    // --------------------------------------------------------
    func saveEntry(
        text: String,
        richTextData: Data? = nil,
        tags: [String] = [],
        reflectionPrompt: String? = nil,
        moodType: MoodType? = nil
    ) {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            errorMessage = "Please write something before saving."
            return
        }

        let result = sentimentService.analyze(text: trimmed)
        let finalMood = moodType ?? result.mood

        let newEntry = JournalEntry(
            text: trimmed,
            richTextData: richTextData,
            moodType: finalMood,
            sentimentScore: result.score,
            tags: tags,
            reflectionPromptUsed: reflectionPrompt
        )

        modelContext.insert(newEntry)
        saveContext()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        entries.insert(newEntry, at: 0)
        entries = sortEntriesPinnedFirst(entries)
        currentOffset += 1
        totalEntryCount += 1
    }

    func updateEntry(
        _ entry: JournalEntry,
        text: String,
        richTextData: Data? = nil,
        tags: [String] = [],
        reflectionPrompt: String? = nil,
        moodType: MoodType? = nil
    ) {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            errorMessage = "Entry text cannot be empty."
            return
        }

        let result = sentimentService.analyze(text: trimmed)
        let finalMood = moodType ?? result.mood

        entry.text = trimmed
        entry.richTextData = richTextData
        entry.moodType = finalMood
        entry.sentimentScore = result.score
        entry.tags = tags
        entry.reflectionPromptUsed = reflectionPrompt

        saveContext()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
    }
    
    func togglePin(_ entry: JournalEntry) {
        entry.isPinned.toggle()

        entries = sortEntriesPinnedFirst(entries)
        searchResults = sortEntriesPinnedFirst(searchResults)

        saveContext()

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        searchResults.removeAll { $0.id == entry.id }
        totalEntryCount = max(0, totalEntryCount - 1)
        currentOffset = max(0, currentOffset - 1)

        modelContext.delete(entry)
        saveContext()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.warning)
    }

    func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            guard index < filteredEntries.count else { continue }
            deleteEntry(filteredEntries[index])
        }
    }

    // --------------------------------------------------------
    // MARK: - Stats
    // --------------------------------------------------------
    var moodCounts: [MoodType: Int] {
        var counts: [MoodType: Int] = [:]
        for entry in entries {
            counts[entry.moodType, default: 0] += 1
        }
        return counts
    }

    var journalStreak: Int { streakCount }

    var weeklyEntries: [JournalEntry] {
        let weekAgo = Calendar.current.date(
            byAdding: .day, value: -7, to: Date()
        ) ?? Date()
        return entries.filter { $0.date >= weekAgo }
    }

    var monthlyEntries: [JournalEntry] {
        let monthAgo = Calendar.current.date(
            byAdding: .day, value: -30, to: Date()
        ) ?? Date()
        return entries.filter { $0.date >= monthAgo }
    }

    func entries(for mood: MoodType) -> [JournalEntry] {
        entries.filter { $0.moodType == mood }
    }

    func entries(for date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        return entries.filter {
            calendar.startOfDay(for: $0.date) == day
        }
    }

    var hasEntryToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.contains {
            calendar.startOfDay(for: $0.date) == today
        }
    }

    func entriesForInsights() -> [JournalEntry] {
        do {
            let ninetyDaysAgo = Calendar.current.date(
                byAdding: .day, value: -90, to: Date()
            ) ?? Date()

            var descriptor = FetchDescriptor<JournalEntry>()
            descriptor.fetchLimit = 1000

            let all = try modelContext.fetch(descriptor)
            return all
                .filter { $0.date >= ninetyDaysAgo }
                .sorted { $0.date > $1.date }
        } catch {
            return entries
        }
    }

    // --------------------------------------------------------
    // MARK: - Private
    // --------------------------------------------------------
    private func saveContext() {
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

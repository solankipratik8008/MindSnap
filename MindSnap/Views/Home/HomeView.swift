//
//  HomeView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
// // ============================================================
// HomeView.swift
// MindSnap — INFINITE SCROLL PAGINATION FIXED
// Uses entry.date (not createdAt), no isPinned
// ============================================================

import SwiftUI
import SwiftData

struct HomeView: View {

    let viewModel: JournalViewModel

    @AppStorage("userName") private var userName = ""
    @AppStorage("showMoodOnHome") private var showMoodOnHome = true

    @State private var showingEditor = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: JournalEntry? = nil
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedMoodFilter: MoodType? = nil
    @State private var previousStreakCount: Int = 0

    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection

                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    if showingFilters {
                        moodFilterChips
                            .padding(.bottom, 8)
                            .transition(
                                .move(edge: .top)
                                .combined(with: .opacity)
                            )
                    }

                    if viewModel.displayedEntries.isEmpty {
                        emptyStateView
                    } else {
                        entryList
                    }
                }
            }
            .navigationTitle("MindSnap")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    entryCountBadge
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingFilters.toggle()
                        }
                    } label: {
                        Image(
                            systemName: showingFilters
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle"
                        )
                        .foregroundStyle(
                            selectedMoodFilter != nil
                                ? Color.purple : Color.primary
                        )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.purple)
                    }
                }
            }
            .animation(
                .easeInOut(duration: 0.2),
                value: showingFilters
            )
        }
        .sheet(isPresented: $showingEditor, onDismiss: {
            selectedEntry = nil
        }) {
            EntryEditorView(
                viewModel: viewModel,
                existingEntry: selectedEntry
            )
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    viewModel.deleteEntry(entry)
                    entryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text("This entry will be permanently deleted.")
        }
        .alert("Oops", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: searchText) { _, text in
            viewModel.searchText = text
        }
        .onAppear {
            previousStreakCount = viewModel.streakCount
            viewModel.fetchEntries()
        }
        .onChange(of: viewModel.streakCount) { _, newStreak in
            checkStreakMilestone(newStreak: newStreak)
            previousStreakCount = newStreak
        }
    }

    // --------------------------------------------------------
    // MARK: - Header
    // --------------------------------------------------------
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(personalizedGreeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if showMoodOnHome {
                        if let mood = viewModel.todaysMood {
                            HStack(spacing: 6) {
                                Text(mood.emoji).font(.title2)
                                Text("Feeling \(mood.displayName)")
                                    .font(.headline)
                                    .foregroundStyle(mood.color)
                            }
                        } else {
                            Text("How are you feeling today?")
                                .font(.headline)
                        }
                    } else {
                        Text("Ready to journal?").font(.headline)
                    }
                }

                Spacer()

                Button {
                    let haptic = UIImpactFeedbackGenerator(
                        style: .light
                    )
                    haptic.impactOccurred()
                } label: {
                    VStack(spacing: 2) {
                        Text("🔥").font(.title2)
                        Text("\(viewModel.streakCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        Text("day streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }

            Button {
                let haptic = UIImpactFeedbackGenerator(
                    style: .medium
                )
                haptic.impactOccurred()
                selectedEntry = nil
                showingEditor = true
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("New Entry").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // --------------------------------------------------------
    // MARK: - Entry Count Badge
    // --------------------------------------------------------
    private var entryCountBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "book.fill")
                .font(.caption)
                .foregroundStyle(.purple)
            Text("\(viewModel.totalEntryCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.purple)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.purple.opacity(
                    colorScheme == .dark ? 0.2 : 0.1
                ))
                .overlay(
                    Capsule()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Search Bar
    // --------------------------------------------------------
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            TextField("Search entries, moods, tags...", text: $searchText)
                .font(.subheadline)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.17, green: 0.17, blue: 0.18)
                        : Color.white
                )
                .shadow(
                    color: .black.opacity(
                        colorScheme == .dark ? 0 : 0.05
                    ),
                    radius: 4, x: 0, y: 2
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Mood Filter Chips
    // --------------------------------------------------------
    private var moodFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    label: "All",
                    emoji: "📋",
                    isSelected: selectedMoodFilter == nil
                ) {
                    withAnimation { selectedMoodFilter = nil }
                }
                ForEach(MoodType.allCases, id: \.self) { mood in
                    filterChip(
                        label: mood.displayName,
                        emoji: mood.emoji,
                        isSelected: selectedMoodFilter == mood
                    ) {
                        withAnimation {
                            selectedMoodFilter =
                                selectedMoodFilter == mood
                                    ? nil : mood
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(
        label: String,
        emoji: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(emoji).font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple : Color(.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------
    // MARK: - Entry List with Infinite Scroll
    // --------------------------------------------------------
    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredEntries) { entry in
                    entryRow(entry: entry)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(
                                currentEntry: entry
                            )
                        }
                }

                if !viewModel.isSearchMode &&
                   viewModel.hasMoreEntries {
                    loadMoreTrigger
                }

                if !viewModel.hasMoreEntries &&
                   viewModel.totalEntryCount > 50 {
                    endOfEntriesMessage
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var loadMoreTrigger: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingMore {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading more entries...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 16)
            } else {
                Button {
                    viewModel.loadMore()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                            .font(.caption)
                        Text("Load more entries")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.purple)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(
                                colorScheme == .dark ? 0.15 : 0.08
                            ))
                    )
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
            }
            Spacer()
        }
    }

    private var endOfEntriesMessage: some View {
        VStack(spacing: 6) {
            Text("✨").font(.title2)
            Text("You've reached the beginning!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("\(viewModel.totalEntryCount) entries total")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    // --------------------------------------------------------
    // MARK: - Entry Row
    // --------------------------------------------------------
    private func entryRow(entry: JournalEntry) -> some View {
        EntryRowView(entry: entry)
            .onTapGesture {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                selectedEntry = entry
                showingEditor = true
            }
            .contextMenu {
                Button {
                    selectedEntry = entry
                    showingEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive) {
                    entryToDelete = entry
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    entryToDelete = entry
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    selectedEntry = entry
                    showingEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }

    // --------------------------------------------------------
    // MARK: - Filtered Entries
    // --------------------------------------------------------
    private var filteredEntries: [JournalEntry] {
        var result = viewModel.displayedEntries
        if let mood = selectedMoodFilter {
            result = result.filter { $0.moodType == mood }
        }
        return result
    }

    // --------------------------------------------------------
    // MARK: - Empty State
    // --------------------------------------------------------
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(
                            colorScheme == .dark ? 0.25 : 0.12
                        ))
                        .frame(width: 100, height: 100)

                    if searchText.isEmpty && selectedMoodFilter == nil {
                        Image(systemName: "book.fill")
                            .font(.system(size: 44))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.purple, .blue)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundStyle(.purple)
                    }
                }

                VStack(spacing: 8) {
                    if searchText.isEmpty && selectedMoodFilter == nil {
                        Text("Start Your Journal")
                            .font(.title2).fontWeight(.bold)
                        Text("Write your first entry to begin.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            selectedEntry = nil
                            showingEditor = true
                        } label: {
                            Text("Write First Entry ✍️")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule().fill(Color.purple)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    } else {
                        Text("No Results Found")
                            .font(.title2).fontWeight(.bold)
                        Button {
                            searchText = ""
                            viewModel.searchText = ""
                            selectedMoodFilter = nil
                        } label: {
                            Text("Clear Filters")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        colorScheme == .dark
                            ? Color(red: 0.15, green: 0.15, blue: 0.17)
                            : Color.white
                    )
            )
            .padding(.horizontal, 16)
            Spacer()
        }
    }

    // --------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------
    private var personalizedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12:  timeGreeting = "Good Morning ☀️"
        case 12..<17: timeGreeting = "Good Afternoon 🌤️"
        case 17..<21: timeGreeting = "Good Evening 🌇"
        default:      timeGreeting = "Good Night 🌙"
        }

        let trimmedName = userName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmedName.isEmpty { return timeGreeting }
        let parts = timeGreeting.components(separatedBy: " ")
        if parts.count >= 3 {
            return "\(parts[0]) \(parts[1]) \(trimmedName) \(parts[2])"
        }
        return "\(timeGreeting) \(trimmedName)"
    }

    private func checkStreakMilestone(newStreak: Int) {
        guard newStreak > previousStreakCount else { return }
        let milestones = [7, 14, 30, 60, 100]
        if milestones.contains(newStreak) {
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            if newStreak >= 30 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    haptic.notificationOccurred(.success)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                    haptic.notificationOccurred(.success)
                }
            }
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: JournalEntry.self,
        configurations: config
    )
    let viewModel = JournalViewModel(
        modelContext: container.mainContext
    )
    HomeView(viewModel: viewModel)
        .modelContainer(container)
}

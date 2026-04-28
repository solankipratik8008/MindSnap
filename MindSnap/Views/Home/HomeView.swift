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
    @AppStorage("homeMoodOverrideRaw")
    private var homeMoodOverrideRaw = ""
    
    @State private var showingEditor = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: JournalEntry? = nil
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingHomeMoodPicker = false
    @State private var selectedMoodFilter: MoodType? = nil
    @State private var previousStreakCount: Int = 0
    
    @Environment(\.colorScheme) private var colorScheme
    private var brandPrimary: Color {
        Color(red: 0.50, green: 0.12, blue: 0.85)
    }

    private var brandSecondary: Color {
        Color(red: 0.88, green: 0.12, blue: 0.68)
    }

    private var brandAccent: Color {
        Color(red: 0.10, green: 0.78, blue: 0.85)
    }
    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                contentScrollView
            }
            .navigationTitle("MindSnap")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    entryCountBadge
                        .padding(.leading, 4)
                        .padding(.vertical, 4)
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
        .sheet(isPresented: $showingHomeMoodPicker) {
            HomeMoodPickerSheet(
                selectedMoodRaw: $homeMoodOverrideRaw,
                currentMood: displayedHomeMood
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
        // --------------------------------------------------------
        // MARK: - Header
        // --------------------------------------------------------
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                moodProfileHeader

                Spacer()

                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                } label: {
                    VStack(spacing: 2) {
                        Text("🔥")
                            .font(.title3)

                        Text("\(viewModel.streakCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)

                        Text("day streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(colorScheme == .dark ? 0.14 : 0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.orange.opacity(0.14), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                selectedEntry = nil
                showingEditor = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))

                    Text("New Entry")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: [
                            brandPrimary.opacity(0.92),
                            brandSecondary.opacity(0.86)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: brandPrimary.opacity(colorScheme == .dark ? 0.0 : 0.14),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
        
        private var moodProfileHeader: some View {
            HStack(spacing: 12) {
                Button {
                    showingHomeMoodPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        brandPrimary,
                                        brandSecondary,
                                        displayedHomeMood.color.opacity(0.65)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 64, height: 64)
                        
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                        
                        Text(displayedHomeMood.emoji)
                            .font(.system(size: 30))
                            .frame(width: 46, height: 46)
                            .minimumScaleFactor(0.75)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [brandPrimary, brandSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGroupedBackground), lineWidth: 2.5)
                            )
                            .offset(x: 3, y: 3)
                    }
                    .frame(width: 72, height: 72)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose Home mood")
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(showMoodOnHome ? "Feeling \(displayedHomeMood.displayName)" : "Ready to journal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(showMoodOnHome ? displayedHomeMood.color : .primary)
                        .lineLimit(1)
                }
            }
        }
        
        private var contentScrollView: some View {
            ScrollView {
                VStack(spacing: 12) {
                    headerSection
                        .padding(.top, 2)
                    
                    VStack(spacing: 7) {
                        searchBar
                        
                        if showingFilters {
                            moodFilterChips
                                .transition(
                                    .move(edge: .top)
                                    .combined(with: .opacity)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if viewModel.displayedEntries.isEmpty {
                        emptyStateView
                            .padding(.horizontal, 16)
                    } else {
                        entryListContent
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        
        // --------------------------------------------------------
        // MARK: - Entry Count Badge
        // --------------------------------------------------------
        private var entryCountBadge: some View {
            HStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.purple)
                Text("\(viewModel.totalEntryCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minWidth: 58, minHeight: 36)
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
            .fixedSize()
            .contentShape(Capsule())
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
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    colorScheme == .dark
                    ? Color(red: 0.16, green: 0.16, blue: 0.18)
                    : Color.white.opacity(0.96)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : brandPrimary.opacity(0.06),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark
                    ? Color.clear
                    : brandPrimary.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
    }
        
        // --------------------------------------------------------
        // MARK: - Mood Filter Chips
        // --------------------------------------------------------
        private var moodFilterChips: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
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
                Text(emoji)
                    .font(.caption2)

                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [brandPrimary, brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(.systemGray5),
                                Color(.systemGray5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
        
        // --------------------------------------------------------
        // MARK: - Entry List with Infinite Scroll
        // --------------------------------------------------------
        private var entryList: some View {
            ScrollView {
                entryListContent
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        }
        
        private var entryListContent: some View {
            LazyVStack(spacing: 14) {
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
        private var displayedHomeMood: MoodType {
            if let override = MoodType(rawValue: homeMoodOverrideRaw) {
                return override
            }
            return viewModel.todaysMood ?? .neutral
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
    
    private struct HomeMoodPickerSheet: View {
        @Binding var selectedMoodRaw: String
        let currentMood: MoodType
        
        @Environment(\.dismiss) private var dismiss
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(spacing: 18) {
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 42, height: 5)
                    .padding(.top, 8)
                
                VStack(spacing: 6) {
                    Text("Home mood")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This only changes the Home header display.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 10) {
                    ForEach(MoodType.allCases, id: \.self) { mood in
                        Button {
                            selectedMoodRaw = mood.rawValue
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(mood.emoji)
                                    .font(.title3)
                                
                                Text(mood.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if mood == currentMood {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.purple)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        mood == currentMood
                                        ? Color.purple.opacity(colorScheme == .dark ? 0.22 : 0.12)
                                        : Color(.secondarySystemGroupedBackground)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button {
                    selectedMoodRaw = ""
                    dismiss()
                } label: {
                    Text("Use today's journal mood")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.purple.opacity(colorScheme == .dark ? 0.22 : 0.1))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
            .background(Color(.systemGroupedBackground))
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


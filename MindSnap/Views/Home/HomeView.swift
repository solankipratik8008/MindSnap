//
//  HomeView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
// ============================================================
// HomeView.swift
// MindSnap — INFINITE SCROLL PAGINATION FIXED
// Uses entry.date (not createdAt), no isPinned
//
// UI UPDATE:
// 1. Professional black/white theme
// 2. Light/Dark mode adaptive styling
// 3. Premium cards, chips, buttons, and mood picker
//
// FUNCTIONALITY KEPT:
// 1. Journal pagination
// 2. Search/filter logic
// 3. Entry tap/edit/delete/pin actions
// 4. Home mood override
// 5. Streak milestone haptics
// ============================================================

import SwiftUI
import SwiftData

struct HomeView: View {
    
    let viewModel: JournalViewModel
    
    @AppStorage("userName") private var userName = ""
    @AppStorage("showMoodOnHome") private var showMoodOnHome = true
    @AppStorage("homeMoodOverrideRaw")
    private var homeMoodOverrideRaw = ""
    
    @AppStorage("hasSeenHomeCoachMark")
    private var hasSeenHomeCoachMark = false
    
    @State private var showingEditor = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: JournalEntry? = nil
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingHomeMoodPicker = false
    @State private var selectedMoodFilter: MoodType? = nil
    @State private var previousStreakCount: Int = 0
    @State private var entryAuthService = AuthService()
    @State private var unlockingEntryID: UUID? = nil
    @State private var lockErrorMessage: String? = nil
    
    @State private var showingHomeCoachMark = false
    @State private var homeCoachStep = 0
    @State private var homeCoachAnimate = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }
    
    private var softCardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.12, green: 0.12, blue: 0.13)
        : Color(red: 0.985, green: 0.985, blue: 0.99)
    }
    
    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.04, green: 0.04, blue: 0.05)
    }
    
    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.62)
        : Color.black.opacity(0.52)
    }
    
    private var tertiaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.38)
        : Color.black.opacity(0.32)
    }
    
    private var primaryButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var primaryButtonText: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.07)
    }
    
    private var chipBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.06)
    }
    
    private var selectedChipBackground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var selectedChipText: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.06)
    }
    
    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ZStack {
                appBackground
                    .ignoresSafeArea()
                
                contentScrollView

                if showingHomeCoachMark {
                    homeCoachMarkOverlay
                        .transition(.opacity)
                        .zIndex(50)
                }
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
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            selectedMoodFilter != nil
                            ? primaryText
                            : primaryText.opacity(0.88)
                        )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(primaryText)
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
        .alert("Locked Journal", isPresented: Binding(
            get: { lockErrorMessage != nil },
            set: { if !$0 { lockErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                lockErrorMessage = nil
            }
        } message: {
            Text(lockErrorMessage ?? "")
        }
        .onChange(of: searchText) { _, text in
            viewModel.searchText = text
        }
        .onAppear {
            previousStreakCount = viewModel.streakCount
            viewModel.fetchEntries()
            presentHomeCoachMarkIfNeeded()
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                moodProfileHeader
                
                Spacer()
                
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                } label: {
                    VStack(spacing: 3) {
                        Text("🔥")
                            .font(.title3)
                        
                        Text("\(viewModel.streakCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                            .monospacedDigit()
                        
                        Text("day streak")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .shadow(
                                color: shadowColor,
                                radius: 12,
                                x: 0,
                                y: 6
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
                HStack(spacing: 9) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("New Entry")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(primaryButtonBackground)
                .foregroundStyle(primaryButtonText)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(appBackground)
    }
    
    private var moodProfileHeader: some View {
        HStack(spacing: 13) {
            Button {
                showingHomeMoodPicker = true
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    primaryText.opacity(0.95),
                                    primaryText.opacity(0.28),
                                    displayedHomeMood.color.opacity(0.50)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 66, height: 66)
                    
                    Circle()
                        .fill(cardBackground)
                        .frame(width: 57, height: 57)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .shadow(
                            color: shadowColor,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
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
                        .foregroundStyle(primaryButtonText)
                        .frame(width: 23, height: 23)
                        .background(
                            Circle()
                                .fill(primaryButtonBackground)
                        )
                        .overlay(
                            Circle()
                                .stroke(appBackground, lineWidth: 2.6)
                        )
                        .offset(x: 3, y: 3)
                }
                .frame(width: 74, height: 74)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose Home mood")
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                
                Text(showMoodOnHome ? "Feeling \(displayedHomeMood.displayName)" : "Ready to journal")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(showMoodOnHome ? displayedHomeMood.color : primaryText)
                    .lineLimit(1)
            }
        }
    }
    
    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: 13) {
                headerSection
                    .padding(.top, 2)
                
                VStack(spacing: 8) {
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
        HStack(spacing: 5) {
            Image(systemName: "book.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(primaryText)
            
            Text("\(viewModel.totalEntryCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minWidth: 58, minHeight: 36)
        .background(
            Capsule()
                .fill(cardBackground)
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
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
                .foregroundStyle(secondaryText)
                .font(.subheadline)
            
            TextField("Search entries, moods, tags...", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(primaryText)
                .tint(primaryText)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
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
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.caption2)
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? selectedChipText : primaryText)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? selectedChipBackground : chipBackground)
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
                        .tint(primaryText)
                    
                    Text("Loading more entries...")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
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
                    .foregroundStyle(primaryText)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(chipBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
            }
            Spacer()
        }
    }
    
    private var endOfEntriesMessage: some View {
        VStack(spacing: 7) {
            Text("✨")
                .font(.title2)
            
            Text("You've reached the beginning!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
            
            Text("\(viewModel.totalEntryCount) entries total")
                .font(.caption2)
                .foregroundStyle(tertiaryText)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    // --------------------------------------------------------
    // MARK: - Entry Row
    // --------------------------------------------------------
    private func entryRow(entry: JournalEntry) -> some View {
        EntryRowView(entry: entry)
            .overlay(alignment: .topTrailing) {
                if unlockingEntryID == entry.id {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(primaryText)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(cardBackground)
                                .overlay(
                                    Circle()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                        .padding(12)
                }
            }
            .onTapGesture {
                openEntry(entry)
            }
            .contextMenu {
                Button {
                    toggleEntryLock(entry)
                } label: {
                    Label(
                        entry.isLocked ? "Unlock Entry" : "Lock Entry",
                        systemImage: entry.isLocked ? "lock.open" : "lock"
                    )
                }

                Button {
                    viewModel.togglePin(entry)
                } label: {
                    Label(
                        entry.isPinned ? "Unpin Entry" : "Pin Entry",
                        systemImage: entry.isPinned ? "pin.slash" : "pin"
                    )
                }

                Button {
                    openEntry(entry)
                } label: {
                    Label(
                        entry.isLocked ? "Unlock & Edit" : "Edit",
                        systemImage: entry.isLocked ? "lock.open" : "pencil"
                    )
                }

                Divider()

                Button(role: .destructive) {
                    entryToDelete = entry
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    toggleEntryLock(entry)
                } label: {
                    Label(
                        entry.isLocked ? "Unlock" : "Lock",
                        systemImage: entry.isLocked ? "lock.open" : "lock"
                    )
                }
                .tint(entry.isLocked ? .green : .black)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    entryToDelete = entry
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    openEntry(entry)
                } label: {
                    Label(
                        entry.isLocked ? "Unlock" : "Edit",
                        systemImage: entry.isLocked ? "lock.open" : "pencil"
                    )
                }
                .tint(.blue)

                Button {
                    viewModel.togglePin(entry)
                } label: {
                    Label(
                        entry.isPinned ? "Unpin" : "Pin",
                        systemImage: entry.isPinned ? "pin.slash" : "pin"
                    )
                }
                .tint(.orange)
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
                        .fill(chipBackground)
                        .frame(width: 102, height: 102)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 1)
                        )
                    
                    if searchText.isEmpty && selectedMoodFilter == nil {
                        Image(systemName: "book.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(primaryText)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(primaryText)
                    }
                }
                
                VStack(spacing: 9) {
                    if searchText.isEmpty && selectedMoodFilter == nil {
                        Text("Start Your Journal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                        
                        Text("Write your first entry to begin.")
                            .font(.subheadline)
                            .foregroundStyle(secondaryText)
                        
                        Button {
                            selectedEntry = nil
                            showingEditor = true
                        } label: {
                            Text("Write First Entry ✍️")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(primaryButtonText)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(primaryButtonBackground)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    } else {
                        Text("No Results Found")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)
                        
                        Button {
                            searchText = ""
                            viewModel.searchText = ""
                            selectedMoodFilter = nil
                        } label: {
                            Text("Clear Filters")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(primaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(chipBackground)
                                        .overlay(
                                            Capsule()
                                                .stroke(borderColor, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: shadowColor,
                        radius: 14,
                        x: 0,
                        y: 8
                    )
            )
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    private func openEntry(_ entry: JournalEntry) {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        if entry.isLocked {
            unlockAndOpenEntry(entry)
        } else {
            selectedEntry = entry
            showingEditor = true
        }
    }

    private func unlockAndOpenEntry(_ entry: JournalEntry) {
        unlockingEntryID = entry.id

        Task {
            let success = await entryAuthService.authenticateForProtectedEntry(
                reason: "Unlock this private journal entry"
            )

            await MainActor.run {
                unlockingEntryID = nil

                if success {
                    selectedEntry = entry
                    showingEditor = true
                } else {
                    lockErrorMessage = entryAuthService.authError ??
                    "This journal entry is locked."
                }
            }
        }
    }

    private func toggleEntryLock(_ entry: JournalEntry) {
        if entry.isLocked {
            unlockAndToggleEntryLock(entry)
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                entry.isLocked = true
            }

            saveEntryLockState()

            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
        }
    }

    private func unlockAndToggleEntryLock(_ entry: JournalEntry) {
        unlockingEntryID = entry.id

        Task {
            let success = await entryAuthService.authenticateForProtectedEntry(
                reason: "Unlock this journal entry to remove the lock"
            )

            await MainActor.run {
                unlockingEntryID = nil

                if success {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        entry.isLocked = false
                    }

                    saveEntryLockState()

                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                } else {
                    lockErrorMessage = entryAuthService.authError ??
                    "Could not unlock this journal entry."
                }
            }
        }
    }

    private func saveEntryLockState() {
        do {
            try modelContext.save()
        } catch {
            lockErrorMessage = "Could not update journal lock. Please try again."
            print("Failed to save journal lock state: \(error)")
        }
    }
    
    
    // --------------------------------------------------------
    // MARK: - Home Coach Mark
    // --------------------------------------------------------
    private struct HomeCoachStep {
        let emoji: String
        let title: String
        let message: String
        let bullets: [String]
        let accent: Color
    }

    private var homeCoachSteps: [HomeCoachStep] {
        [
            HomeCoachStep(
                emoji: "🏠",
                title: "Welcome to Your Home",
                message: "This is your private journal dashboard where you can write, search, protect, and revisit your thoughts.",
                bullets: [
                    "See your daily mood",
                    "Track your journal streak",
                    "Open your saved entries"
                ],
                accent: .blue
            ),
            HomeCoachStep(
                emoji: "✍️",
                title: "Write a New Entry",
                message: "Tap New Entry whenever you want to capture a thought, feeling, memory, or reflection.",
                bullets: [
                    "Rich text editor",
                    "Mood detection",
                    "Tags, prompts, voice, and images"
                ],
                accent: .purple
            ),
            HomeCoachStep(
                emoji: "🔍",
                title: "Find Anything Fast",
                message: "Use search and filters when your journal grows. You can find old entries by mood, keyword, tags, or memories.",
                bullets: [
                    "Search entry text",
                    "Filter by mood",
                    "Clear filters anytime"
                ],
                accent: .teal
            ),
            HomeCoachStep(
                emoji: "📌",
                title: "Pin Important Entries",
                message: "Long-press or swipe an entry to pin meaningful memories so they stay easy to find.",
                bullets: [
                    "Pin special moments",
                    "Unpin anytime",
                    "Use long-press menu"
                ],
                accent: .orange
            ),
            HomeCoachStep(
                emoji: "🔒",
                title: "Lock Private Journals",
                message: "Some thoughts are extra private. Lock any journal entry and unlock it with Face ID, Touch ID, or passcode.",
                bullets: [
                    "Hide journal preview",
                    "Unlock before editing",
                    "Protect sensitive entries"
                ],
                accent: .green
            ),
            HomeCoachStep(
                emoji: "✨",
                title: "You’re Ready",
                message: "Small reflections become powerful over time. Write honestly, protect what matters, and let MindSnap help you understand your patterns.",
                bullets: [
                    "Swipe for quick actions",
                    "Long-press for more options",
                    "Keep building your journal"
                ],
                accent: .yellow
            )
        ]
    }

    private var currentHomeCoachStep: HomeCoachStep {
        homeCoachSteps[homeCoachStep]
    }

    private var isLastHomeCoachStep: Bool {
        homeCoachStep == homeCoachSteps.count - 1
    }

    private func presentHomeCoachMarkIfNeeded() {
        guard !hasSeenHomeCoachMark else { return }
        guard !showingEditor else { return }
        guard !showingHomeMoodPicker else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            guard !hasSeenHomeCoachMark else { return }
            guard !showingEditor else { return }
            guard !showingHomeMoodPicker else { return }

            homeCoachStep = 0

            withAnimation(.easeInOut(duration: 0.25)) {
                showingHomeCoachMark = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(duration: 0.45, bounce: 0.30)) {
                    homeCoachAnimate = true
                }
            }
        }
    }

    private func nextHomeCoachStep() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        if isLastHomeCoachStep {
            completeHomeCoachMark()
        } else {
            withAnimation(.easeInOut(duration: 0.20)) {
                homeCoachAnimate = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                homeCoachStep += 1

                withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                    homeCoachAnimate = true
                }
            }
        }
    }

    private func previousHomeCoachStep() {
        guard homeCoachStep > 0 else { return }

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        withAnimation(.easeInOut(duration: 0.20)) {
            homeCoachAnimate = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            homeCoachStep -= 1

            withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                homeCoachAnimate = true
            }
        }
    }

    private func completeHomeCoachMark() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        hasSeenHomeCoachMark = true

        withAnimation(.easeInOut(duration: 0.25)) {
            homeCoachAnimate = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingHomeCoachMark = false
            }
        }
    }

    private var homeCoachMarkOverlay: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.82 : 0.70)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                homeCoachCard
                    .padding(.horizontal, 22)
                    .padding(.bottom, 34)
                    .opacity(homeCoachAnimate ? 1 : 0)
                    .offset(y: homeCoachAnimate ? 0 : 34)
                    .scaleEffect(homeCoachAnimate ? 1 : 0.96)
            }
        }
    }

    private var homeCoachCard: some View {
        VStack(spacing: 18) {
            homeCoachProgressHeader

            homeCoachEmoji

            VStack(spacing: 8) {
                Text(currentHomeCoachStep.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Text(currentHomeCoachStep.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            homeCoachBullets

            homeCoachButtons
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            currentHomeCoachStep.accent.opacity(
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

    private var homeCoachProgressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("HOME GUIDE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(secondaryText)
                    .tracking(1.0)

                Spacer()

                Text("\(homeCoachStep + 1)/\(homeCoachSteps.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(chipBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(chipBackground)
                        .frame(height: 8)

                    Capsule()
                        .fill(currentHomeCoachStep.accent)
                        .frame(
                            width: geo.size.width *
                            CGFloat(homeCoachStep + 1) /
                            CGFloat(homeCoachSteps.count),
                            height: 8
                        )
                        .animation(
                            .spring(duration: 0.35),
                            value: homeCoachStep
                        )
                }
            }
            .frame(height: 8)
        }
    }

    private var homeCoachEmoji: some View {
        ZStack {
            Circle()
                .fill(
                    currentHomeCoachStep.accent.opacity(
                        colorScheme == .dark ? 0.16 : 0.09
                    )
                )
                .frame(width: 96, height: 96)

            Circle()
                .fill(chipBackground)
                .frame(width: 74, height: 74)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )

            Text(currentHomeCoachStep.emoji)
                .font(.system(size: 42))
        }
        .id("homeCoachEmoji-\(homeCoachStep)")
        .transition(.scale.combined(with: .opacity))
    }

    private var homeCoachBullets: some View {
        VStack(spacing: 8) {
            ForEach(currentHomeCoachStep.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(currentHomeCoachStep.accent)
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
                .fill(chipBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private var homeCoachButtons: some View {
        VStack(spacing: 10) {
            Button {
                nextHomeCoachStep()
            } label: {
                HStack(spacing: 8) {
                    if isLastHomeCoachStep {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                    }

                    Text(isLastHomeCoachStep ? "Start Using Home" : "Continue")
                        .font(.headline)
                        .fontWeight(.bold)

                    if !isLastHomeCoachStep {
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
                if homeCoachStep > 0 {
                    Button {
                        previousHomeCoachStep()
                    } label: {
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(secondaryText)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if !isLastHomeCoachStep {
                    Button {
                        completeHomeCoachMark()
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
    
    // --------------------------------------------------------
    // MARK: - Sheet Theme
    // --------------------------------------------------------
    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }
    
    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.62)
        : Color.black.opacity(0.52)
    }
    
    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.07)
    }
    
    private var selectedBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.12)
        : Color.black.opacity(0.06)
    }
    
    private var buttonBackground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var buttonText: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 8)
            
            VStack(spacing: 7) {
                Text("Home Mood")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                
                Text("This updates the mood shown on your Home screen.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
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
                                .foregroundStyle(primaryText)
                            
                            Spacer()
                            
                            if mood == currentMood {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(primaryText)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    mood == currentMood
                                    ? selectedBackground
                                    : cardBackground
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(borderColor, lineWidth: 1)
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
                    .foregroundStyle(buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(buttonBackground)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .background(appBackground)
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

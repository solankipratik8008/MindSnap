//
//  EntryRowView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//
// ============================================================
// EntryRowView.swift
// MindSnap — UPDATED WITH PIN BADGE
//
// WHAT CHANGED:
// Added pin indicator to mood banner when entry is pinned.
// Shows a pin icon next to the date in the banner.
// Dark mode adaptive colors maintained.
// ============================================================

import SwiftUI
import SwiftData

struct EntryRowView: View {

    let entry: JournalEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {

            // ================================================
            // MOOD GRADIENT BANNER
            // ================================================
            moodBanner

            // ================================================
            // CARD BODY
            // ================================================
            cardBody
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(
                        colorScheme == .dark ? 0.0 : 0.08
                    ),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    entry.moodType.color.opacity(
                        colorScheme == .dark ? 0.4 : 0.15
                    ),
                    lineWidth: colorScheme == .dark ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // --------------------------------------------------------
    // MARK: - Mood Banner
    //
    // The colored gradient cover at top of card.
    // UPDATED: Shows pin icon when entry is pinned.
    // --------------------------------------------------------
    private var moodBanner: some View {
        ZStack {
            // ---- Gradient background ----
            LinearGradient(
                colors: [
                    entry.moodType.color.opacity(
                        colorScheme == .dark ? 0.7 : 0.85
                    ),
                    entry.moodType.color.opacity(
                        colorScheme == .dark ? 0.4 : 0.55
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // ---- Decorative circles ----
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 100, height: 100)
                .offset(x: 120, y: -20)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 60, height: 60)
                .offset(x: -80, y: 30)

            // ---- Content row ----
            HStack(spacing: 12) {

                // ---- Big mood emoji ----
                Text(entry.moodType.emoji)
                    .font(.system(size: 36))
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: 4, x: 0, y: 2
                    )

                // ---- Mood name + time label ----
                VStack(alignment: .leading, spacing: 3) {
                    Text("Feeling \(entry.moodType.displayName)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(timeOfDayLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // ---- Date + Pin badge (right side) ----
                VStack(alignment: .trailing, spacing: 4) {

                    // ---- Pin indicator ----
                    // NEW: Shows pin icon when entry is pinned
                    // Rotated 45° matches iOS Notes pin style
                    if entry.isPinned {
                        HStack(spacing: 3) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(45))
                            Text("Pinned")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                // Semi-transparent white pill
                                .fill(Color.white.opacity(0.25))
                        )
                    }

                    // ---- Date ----
                    Text(entry.shortDate)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    // ---- Sentiment score ----
                    Text(String(format: "%+.2f", entry.sentimentScore))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        // --------------------------------------------------------
        // Height adapts when pin badge is showing
        // Slightly taller to accommodate the extra badge
        // --------------------------------------------------------
        .frame(height: entry.isPinned ? 88 : 72)
    }

    // --------------------------------------------------------
    // MARK: - Card Body
    // --------------------------------------------------------
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ---- Entry text preview ----
            Text(entry.previewText)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            // ---- Tags row ----
            if !entry.tags.isEmpty {
                tagsRow
            }

            // ---- Bottom row ----
            HStack {
                Text(entry.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if !entry.tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(entry.moodType.color)
                        Text("\(entry.tags.count) tags")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    // --------------------------------------------------------
    // MARK: - Tags Row
    // --------------------------------------------------------
    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(entry.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
            }
        }
    }

    // --------------------------------------------------------
    // timeOfDayLabel
    // Returns contextual label based on entry write time
    // --------------------------------------------------------
    private var timeOfDayLabel: String {
        let hour = Calendar.current.component(
            .hour,
            from: entry.date
        )
        switch hour {
        case 5..<9:   return "Morning reflection ☀️"
        case 9..<12:  return "Late morning check-in 🌤️"
        case 12..<14: return "Midday thoughts 🌞"
        case 14..<17: return "Afternoon journal 🌤️"
        case 17..<20: return "Evening reflection 🌇"
        case 20..<23: return "Night journal 🌙"
        default:      return "Late night thoughts 🌃"
        }
    }
}

// ============================================================
// Preview — All mood types + pinned state
// ============================================================
#Preview("Light Mode") {
    let sampleEntries: [(String, MoodType, Double, [String], Bool)] = [
        ("Today was absolutely wonderful! Got the job offer!", .happy, 0.88, ["Work", "❤️"], true),
        ("Quiet Sunday morning. Made coffee, read a book.", .calm, 0.31, ["☕️"], false),
        ("Regular day at work. Nothing special happened.", .neutral, 0.04, [], false),
        ("Feeling overwhelmed with the deadline coming up.", .anxious, -0.38, ["Work"], false),
        ("Really struggling today. Everything feels heavy.", .sad, -0.71, ["💙"], false)
    ]

    ScrollView {
        VStack(spacing: 14) {
            ForEach(sampleEntries, id: \.0) { text, mood, score, tags, pinned in
                let entry = JournalEntry(
                    text: text,
                    moodType: mood,
                    sentimentScore: score,
                    tags: tags,
                    isPinned: pinned
                )
                EntryRowView(entry: entry)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

#Preview("Dark Mode") {
    let sampleEntries: [(String, MoodType, Double, Bool)] = [
        ("Today was absolutely wonderful!", .happy, 0.88, true),
        ("Quiet morning. Feeling at peace.", .calm, 0.31, false),
        ("Feeling overwhelmed today.", .anxious, -0.38, false)
    ]

    ScrollView {
        VStack(spacing: 14) {
            ForEach(sampleEntries, id: \.0) { text, mood, score, pinned in
                let entry = JournalEntry(
                    text: text,
                    moodType: mood,
                    sentimentScore: score,
                    isPinned: pinned
                )
                EntryRowView(entry: entry)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

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
    private var brandPrimary: Color {
        Color(red: 0.50, green: 0.12, blue: 0.85)
    }

    private var bannerPrimaryTextColor: Color {
        colorScheme == .dark ? .white : Color.black.opacity(0.82)
    }

    private var bannerSecondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.78) : Color.black.opacity(0.55)
    }
    private var brandSecondary: Color {
        Color(red: 0.88, green: 0.12, blue: 0.68)
    }

    private var brandAccent: Color {
        Color(red: 0.10, green: 0.78, blue: 0.85)
    }

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
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    colorScheme == .dark
                    ? Color(red: 0.15, green: 0.15, blue: 0.17)
                    : Color.white
                )
                .shadow(
                    color: colorScheme == .dark
                    ? Color.clear
                    : brandPrimary.opacity(0.055),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    entry.moodType.color.opacity(
                        colorScheme == .dark ? 0.22 : 0.10
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // --------------------------------------------------------
    // MARK: - Mood Banner
    //
    // The colored gradient cover at top of card.
    // UPDATED: Shows pin icon when entry is pinned.
    // --------------------------------------------------------
    private var moodBanner: some View {
        ZStack {
            LinearGradient(
                colors: [
                    entry.moodType.color.opacity(colorScheme == .dark ? 0.30 : 0.26),
                    brandAccent.opacity(colorScheme == .dark ? 0.18 : 0.12),
                    brandPrimary.opacity(colorScheme == .dark ? 0.16 : 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Clean premium highlight instead of large background bubbles
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.06 : 0.14),
                    Color.white.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            HStack(spacing: 12) {
                Text(entry.moodType.emoji)
                    .font(.system(size: 23))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.10 : 0.06),
                        radius: 3,
                        x: 0,
                        y: 1
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Feeling \(entry.moodType.displayName)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(bannerPrimaryTextColor)
                        .lineLimit(1)

                    Text(timeOfDayLabel)
                        .font(.caption2)
                        .foregroundStyle(bannerSecondaryTextColor)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if entry.isPinned {
                        HStack(spacing: 3) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.88)
                                        : brandSecondary
                                )
                                .rotationEffect(.degrees(45))

                            Text("Pinned")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.88)
                                        : brandSecondary
                                )
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.14)
                                        : Color.white.opacity(0.72)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            brandSecondary.opacity(colorScheme == .dark ? 0.18 : 0.22),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }

                    Text(entry.shortDate)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(bannerPrimaryTextColor)

                    Text(String(format: "%+.2f", entry.sentimentScore))
                        .font(.caption2)
                        .foregroundStyle(bannerSecondaryTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(colorScheme == .dark ? 0.13 : 0.28))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: entry.isPinned ? 82 : 66)
    }

    // --------------------------------------------------------
    // MARK: - Card Body
    // --------------------------------------------------------
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.previewText)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !entry.tags.isEmpty {
                tagsRow
            }

            HStack {
                Text(entry.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if !entry.tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(entry.moodType.color.opacity(0.85))

                        Text("\(entry.tags.count) tags")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            colorScheme == .dark
            ? Color(red: 0.14, green: 0.14, blue: 0.16)
            : Color.white
        )
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
                                .fill(
                                    entry.moodType.color.opacity(
                                        colorScheme == .dark ? 0.13 : 0.08
                                    )
                                )
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

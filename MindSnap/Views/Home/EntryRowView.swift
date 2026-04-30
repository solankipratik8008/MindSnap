//
//  EntryRowView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//
// ============================================================
// EntryRowView.swift
// MindSnap — PREMIUM MONOCHROME JOURNAL CARD
//
// UI UPDATE:
// 1. Black/white premium card style
// 2. Subtle mood accent, not full colorful branding
// 3. Cleaner pinned badge
// 4. Better light/dark mode contrast
//
// FUNCTIONALITY KEPT:
// 1. Shows journal preview
// 2. Shows mood, date, sentiment, tags
// 3. Shows pinned state
// 4. No save/edit/delete/sync logic touched
// ============================================================

import SwiftUI
import SwiftData

struct EntryRowView: View {

    let entry: JournalEntry
    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var cardBodyBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.10, green: 0.10, blue: 0.11)
        : Color.white
    }

    private var bannerBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.13, green: 0.13, blue: 0.14)
        : Color(red: 0.965, green: 0.965, blue: 0.972)
    }

    private var primaryText: Color {
        colorScheme == .dark
        ? Color.white
        : Color(red: 0.05, green: 0.05, blue: 0.055)
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

    private var softBorderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.06)
        : Color.black.opacity(0.045)
    }

    private var moodAccent: Color {
        entry.moodType.color
    }

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.055)
    }

    private var pinBadgeBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.11)
        : Color.black.opacity(0.055)
    }

    private var chipBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.07)
        : Color.black.opacity(0.045)
    }

    var body: some View {
        if entry.isLocked {
            lockedCard
        } else {
            VStack(spacing: 0) {

                // ================================================
                // MOOD BANNER
                // ================================================
                moodBanner

                // ================================================
                // CARD BODY
                // ================================================
                cardBody
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackground)
                    .shadow(
                        color: shadowColor,
                        radius: 14,
                        x: 0,
                        y: 7
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // --------------------------------------------------------
    // MARK: - Locked Card
    // --------------------------------------------------------
    private var lockedCard: some View {
        VStack(spacing: 0) {
            ZStack {
                bannerBackground

                LinearGradient(
                    colors: [
                        primaryText.opacity(colorScheme == .dark ? 0.10 : 0.045),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(borderColor, lineWidth: 1)
                            )

                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(primaryText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Locked Journal")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)

                        Text("Unlock with Face ID or passcode")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        if entry.isPinned {
                            pinnedBadge
                        }

                        Text(entry.shortDate)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(primaryText)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .frame(height: entry.isPinned ? 84 : 70)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 9) {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption)
                        .foregroundStyle(secondaryText)

                    Text("This entry is hidden for privacy.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .lineLimit(2)

                    Spacer()
                }

                HStack(spacing: 8) {
                    Text(entry.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(tertiaryText)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption2)

                        Text("Private")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(chipBackground)
                            .overlay(
                                Capsule()
                                    .stroke(softBorderColor, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(cardBodyBackground)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // --------------------------------------------------------
    // MARK: - Mood Banner
    // --------------------------------------------------------
    private var moodBanner: some View {
        ZStack {
            bannerBase

            HStack(spacing: 12) {
                moodIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text("Feeling \(entry.moodType.displayName)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(primaryText)
                        .lineLimit(1)

                    Text(timeOfDayLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 5) {
                    if entry.isPinned {
                        pinnedBadge
                    }

                    Text(entry.shortDate)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)

                    sentimentBadge
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .frame(height: entry.isPinned ? 84 : 68)
    }

    private var bannerBase: some View {
        ZStack {
            bannerBackground

            LinearGradient(
                colors: [
                    moodAccent.opacity(colorScheme == .dark ? 0.18 : 0.10),
                    Color.clear,
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.035 : 0.40),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var moodIcon: some View {
        ZStack {
            Circle()
                .fill(cardBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(
                            moodAccent.opacity(colorScheme == .dark ? 0.34 : 0.24),
                            lineWidth: 1.2
                        )
                )

            Text(entry.moodType.emoji)
                .font(.system(size: 23))
        }
        .shadow(
            color: shadowColor,
            radius: 5,
            x: 0,
            y: 3
        )
    }

    private var pinnedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "pin.fill")
                .font(.caption2)
                .rotationEffect(.degrees(45))

            Text("Pinned")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(primaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(pinBadgeBackground)
                .overlay(
                    Capsule()
                        .stroke(softBorderColor, lineWidth: 1)
                )
        )
    }

    private var sentimentBadge: some View {
        Text(String(format: "%+.2f", entry.sentimentScore))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(secondaryText)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(chipBackground)
                    .overlay(
                        Capsule()
                            .stroke(softBorderColor, lineWidth: 1)
                    )
            )
    }

    // --------------------------------------------------------
    // MARK: - Card Body
    // --------------------------------------------------------
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.previewText)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(primaryText)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !entry.tags.isEmpty {
                tagsRow
            }

            HStack(spacing: 8) {
                Text(entry.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(tertiaryText)
                    .lineLimit(1)

                Spacer()

                if !entry.tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)

                        Text("\(entry.tags.count) tags")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(chipBackground)
                    )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(cardBodyBackground)
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
                        .foregroundStyle(secondaryText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(chipBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            moodAccent.opacity(
                                                colorScheme == .dark ? 0.14 : 0.10
                                            ),
                                            lineWidth: 1
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
    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
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
    .background(Color(red: 0.03, green: 0.03, blue: 0.035))
    .preferredColorScheme(.dark)
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

//
//  JournalEntry.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// JournalEntry.swift
// MindSnap — UPDATED WITH isPinned
//
// WHAT CHANGED:
// Added isPinned property so users can pin important
// journal entries to the top of their list.
// ============================================================

import SwiftData
import Foundation

@Model
class JournalEntry {

    // --------------------------------------------------------
    // id — Unique identifier
    // --------------------------------------------------------
    var id: UUID

    // --------------------------------------------------------
    // date — When the entry was written
    // --------------------------------------------------------
    var date: Date

    // --------------------------------------------------------
    // text — The actual journal entry content
    // --------------------------------------------------------
    var text: String

    // Optional archived rich text for formatting and inline images.
    var richTextData: Data?

    // --------------------------------------------------------
    // moodType — The detected emotional mood
    // --------------------------------------------------------
    var moodType: MoodType

    // --------------------------------------------------------
    // sentimentScore — Raw score from NaturalLanguage
    // Range: -1.0 (very negative) to +1.0 (very positive)
    // --------------------------------------------------------
    var sentimentScore: Double

    // --------------------------------------------------------
    // tags — User applied labels
    // Can include text tags AND emoji tags
    // --------------------------------------------------------
    var tags: [String]

    // --------------------------------------------------------
    // reflectionPromptUsed — Which prompt user picked
    // nil = no prompt used
    // --------------------------------------------------------
    var reflectionPromptUsed: String?

    // --------------------------------------------------------
    // isPinned — Whether this entry is pinned to top
    //
    // NEW FEATURE:
    // true  = pinned → shown in "Pinned" section at top
    // false = normal → sorted by date (newest first)
    //
    // User pins by swiping right on an entry row.
    // Default is false — entries start unpinned.
    // --------------------------------------------------------
    var isPinned: Bool = false

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------

    // Full readable date — "Wednesday, April 22, 2026"
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    // Short date for small spaces — "Apr 22"
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // First 100 characters of entry text
    var previewText: String {
        return String(text.prefix(100))
    }

    // --------------------------------------------------------
    // MARK: - Initializer
    // --------------------------------------------------------
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        text: String,
        richTextData: Data? = nil,
        moodType: MoodType = .neutral,
        sentimentScore: Double = 0.0,
        tags: [String] = [],
        reflectionPromptUsed: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.richTextData = richTextData
        self.moodType = moodType
        self.sentimentScore = sentimentScore
        self.tags = tags
        self.reflectionPromptUsed = reflectionPromptUsed
        self.isPinned = isPinned
    }
}

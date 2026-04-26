//
//  MoodType.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//


// ============================================================
// MoodType.swift
// MindSnap — Mood enumeration model
//
// WHAT THIS FILE DOES:
// Defines the 5 possible mood states a journal entry can have.
// Each mood has a display name, an emoji, and a color.
// This enum is used everywhere — in the Model, Views, Charts,
// and the Widget.
//
// MVVM ROLE: Model layer
//            Pure data definition. Zero logic, zero UI code.
//
// WHY AN ENUM?
// An enum is perfect here because the mood is always exactly
// one of 5 fixed options — never a free-form value.
// ============================================================

import SwiftUI // Needed for 'Color' — SwiftUI's color type

// --------------------------------------------------------
// MoodType Enum
//
// Conforms to:
//   String       → raw value is a readable string ("Happy")
//                  makes it easy to display and debug
//   Codable      → can be saved/loaded from SwiftData storage
//   CaseIterable → lets us loop over all 5 cases (used in Charts)
//   Hashable     → lets us use MoodType in Sets and Dictionaries
// --------------------------------------------------------
enum MoodType: String, Codable, CaseIterable, Hashable {

    // The 5 mood states
    // The string after '=' is the raw value — stored in the database
    case happy   = "Happy"
    case calm    = "Calm"
    case neutral = "Neutral"
    case anxious = "Anxious"
    case sad     = "Sad"

    // --------------------------------------------------------
    // displayName
    //
    // Returns the human-readable name of the mood.
    // Same as rawValue here, but having a separate property
    // means we could localize it later (e.g. French, Spanish)
    // without changing the stored rawValue in the database.
    // --------------------------------------------------------
    var displayName: String {
        return self.rawValue
    }

    // --------------------------------------------------------
    // emoji
    //
    // Returns a single emoji that represents this mood visually.
    // Used in EntryRowView, the Widget, and the Insights chart.
    //
    // 'switch self' checks which case this enum value is
    // and returns the matching emoji string.
    // --------------------------------------------------------
    var emoji: String {
        switch self {
        case .happy:   return "😊"
        case .calm:    return "😌"
        case .neutral: return "😐"
        case .anxious: return "😰"
        case .sad:     return "😢"
        }
    }

    // --------------------------------------------------------
    // color
    //
    // Returns a SwiftUI Color for each mood.
    // Used to color-code chart bars, entry rows, and badges.
    //
    // Color palette chosen for accessibility and intuition:
    //   Happy   → green  (positive, energetic)
    //   Calm    → teal   (peaceful, cool)
    //   Neutral → gray   (neither positive nor negative)
    //   Anxious → orange (alert, warning)
    //   Sad     → blue   (traditional sadness association)
    // --------------------------------------------------------
    var color: Color {
        switch self {
        case .happy:   return Color.green
        case .calm:    return Color.teal
        case .neutral: return Color.gray
        case .anxious: return Color.orange
        case .sad:     return Color.blue
        }
    }

    // --------------------------------------------------------
    // sentimentRange
    //
    // Defines which NaturalLanguage sentiment score range
    // maps to this mood. Scores run from -1.0 (very negative)
    // to +1.0 (very positive).
    //
    // This is used by SentimentService in Phase 3 to convert
    // a raw score like 0.72 into .happy
    //
    // We use a ClosedRange<Double> (e.g. 0.5...1.0) which
    // means "from 0.5 up to and including 1.0"
    // --------------------------------------------------------
    var sentimentRange: ClosedRange<Double> {
        switch self {
        case .happy:   return  0.5...1.0
        case .calm:    return  0.1...0.49
        case .neutral: return -0.1...0.09
        case .anxious: return -0.49 ... -0.11
        case .sad:     return -1.0 ... -0.5
        }
    }

    // --------------------------------------------------------
    // reflectionPrompts
    //
    // Returns 3 writing prompt suggestions for this mood.
    // Shown in the EntryEditorView to help users who aren't
    // sure what to write about.
    //
    // These are defined directly on the model so they travel
    // with the mood wherever it's used — no need for a
    // separate lookup table or ViewModel logic.
    // --------------------------------------------------------
    var reflectionPrompts: [String] {
        switch self {
        case .happy:
            return [
                "What made today great?",
                "Who would you like to share this feeling with?",
                "How can you create more moments like this?"
            ]
        case .calm:
            return [
                "What brought you peace today?",
                "What are you grateful for right now?",
                "Describe your ideal calm day."
            ]
        case .neutral:
            return [
                "What was ordinary but good today?",
                "What would have made today better?",
                "What are you looking forward to?"
            ]
        case .anxious:
            return [
                "What is one thing within your control right now?",
                "What would you tell a friend feeling this way?",
                "What do you need most right now?"
            ]
        case .sad:
            return [
                "What emotion is underneath the sadness?",
                "What has helped you through hard days before?",
                "What is one small kind thing you can do for yourself today?"
            ]
        }
    }

    // --------------------------------------------------------
    // init(fromScore:)
    //
    // A custom initializer that takes a sentiment score (Double)
    // and returns the matching MoodType.
    //
    // 'static' means you call it on the TYPE, not an instance:
    //   MoodType.from(score: 0.7) → .happy
    //
    // We loop through ALL cases (thanks to CaseIterable) and
    // check if the score falls inside that mood's range.
    // If nothing matches (shouldn't happen), we default to .neutral
    // --------------------------------------------------------
    static func from(score: Double) -> MoodType {
        // Loop through every mood case: .happy, .calm, .neutral, etc.
        for mood in MoodType.allCases {
            // Check if the score falls within this mood's range
            // e.g. does 0.72 fall inside 0.5...1.0? Yes → return .happy
            if mood.sentimentRange.contains(score) {
                return mood
            }
        }
        // Fallback: score didn't match any range (edge case like exactly -0.1)
        return .neutral
    }
}

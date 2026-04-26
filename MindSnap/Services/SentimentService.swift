//
//  SentimentService.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//
// ============================================================
// SentimentService.swift
// MindSnap — IMPROVED VERSION (CRASH FIXED)
//
// FIX: Safe array slicing in getKeywordScore()
// The crash was caused by unsafe array index access.
// Now uses safe bounds-checked slicing.
// ============================================================

import NaturalLanguage
import Foundation

final class SentimentService {

    private let tagger = NLTagger(tagSchemes: [.sentimentScore])

    private let positiveKeywords: [String: Double] = [
        "happy": 0.7, "happiness": 0.7, "joyful": 0.8,
        "joy": 0.75, "excited": 0.7, "exciting": 0.65,
        "great": 0.6, "wonderful": 0.8, "amazing": 0.8,
        "fantastic": 0.8, "awesome": 0.75, "excellent": 0.7,
        "good": 0.5, "love": 0.75, "loved": 0.75,
        "loving": 0.7, "grateful": 0.7, "thankful": 0.65,
        "blessed": 0.7, "lucky": 0.6,
        "proud": 0.65, "accomplished": 0.7, "confident": 0.6,
        "optimistic": 0.65, "hopeful": 0.55, "cheerful": 0.7,
        "delighted": 0.8, "thrilled": 0.8, "pleased": 0.6,
        "glad": 0.6, "content": 0.45, "satisfied": 0.5,
        "peaceful": 0.4, "calm": 0.35, "relaxed": 0.4,
        "refreshed": 0.5, "energized": 0.6, "motivated": 0.6,
        "fine": 0.3, "okay": 0.2, "ok": 0.2, "alright": 0.25,
        "better": 0.45, "improved": 0.45, "well": 0.4,
        "won": 0.7, "win": 0.7, "success": 0.7,
        "succeeded": 0.7, "achieved": 0.65,
        "finished": 0.4, "completed": 0.4, "done": 0.3,
        "promoted": 0.75, "hired": 0.7, "accepted": 0.6
    ]

    private let negativeKeywords: [String: Double] = [
        "sad": -0.65, "sadness": -0.65, "unhappy": -0.6,
        "depressed": -0.8, "depression": -0.8, "miserable": -0.8,
        "terrible": -0.75, "awful": -0.75, "horrible": -0.8,
        "bad": -0.5, "worst": -0.8, "hate": -0.7,
        "hated": -0.7, "crying": -0.65, "cry": -0.6,
        "cried": -0.65, "tears": -0.55, "heartbroken": -0.85,
        "broken": -0.55, "hurt": -0.6, "pain": -0.6,
        "painful": -0.65, "suffering": -0.75, "lonely": -0.7,
        "alone": -0.45, "empty": -0.6, "hopeless": -0.8,
        "lost": -0.5, "failure": -0.7, "failed": -0.65,
        "disappointed": -0.65, "disappointment": -0.65,
        "devastated": -0.85, "exhausted": -0.55, "tired": -0.4,
        "anxious": -0.65, "anxiety": -0.7, "worried": -0.6,
        "worry": -0.55, "nervous": -0.55, "stressed": -0.65,
        "stress": -0.6, "overwhelmed": -0.7, "panic": -0.75,
        "scared": -0.65, "fear": -0.65, "afraid": -0.65,
        "angry": -0.6, "anger": -0.6, "frustrated": -0.6,
        "frustration": -0.6, "upset": -0.55, "annoyed": -0.45
    ]

    private let negationWords: Set<String> = [
        "not", "no", "never", "don't", "doesn't", "didn't",
        "won't", "wouldn't", "can't", "cannot", "couldn't",
        "isn't", "aren't", "wasn't", "weren't", "hardly",
        "barely", "neither", "nor", "nothing", "nowhere"
    ]

    private let intensifierWords: Set<String> = [
        "very", "really", "so", "extremely", "incredibly",
        "absolutely", "totally", "completely", "utterly",
        "deeply", "truly", "super", "quite", "pretty",
        "especially", "particularly", "exceptionally"
    ]

    private let diminisherWords: Set<String> = [
        "bit", "little", "somewhat", "slightly", "kind",
        "sort", "rather", "fairly", "mildly", "vaguely"
    ]

    // --------------------------------------------------------
    // MARK: - Public Methods
    // --------------------------------------------------------

    func analyze(text: String) -> (mood: MoodType, score: Double) {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            return (mood: .neutral, score: 0.0)
        }

        let nlpScore = getNLPScore(for: trimmed)
        let keywordScore = getKeywordScore(for: trimmed)

        let finalScore: Double
        let textLength = trimmed.count
        let keywordStrength = abs(keywordScore)

        if keywordStrength > 0.6 {
            finalScore = (nlpScore * 0.25) + (keywordScore * 0.75)
        } else if textLength < 30 {
            finalScore = (nlpScore * 0.3) + (keywordScore * 0.7)
        } else if textLength < 100 {
            finalScore = (nlpScore * 0.5) + (keywordScore * 0.5)
        } else {
            finalScore = (nlpScore * 0.7) + (keywordScore * 0.3)
        }

        let clampedScore = min(1.0, max(-1.0, finalScore))
        let mood = MoodType.from(score: clampedScore)
        return (mood: mood, score: clampedScore)
    }

    func analyzeMultiple(entries: [JournalEntry]) {
        for entry in entries {
            let result = analyze(text: entry.text)
            entry.moodType = result.mood
            entry.sentimentScore = result.score
        }
    }

    // --------------------------------------------------------
    // MARK: - Private Layer Methods
    // --------------------------------------------------------

    private func getNLPScore(for text: String) -> Double {
        tagger.string = text
        let (tag, _) = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )
        let rawScore = Double(tag?.rawValue ?? "0") ?? 0.0
        return min(1.0, max(-1.0, rawScore))
    }

    private func getKeywordScore(for text: String) -> Double {
        // --------------------------------------------------------
        // CRASH FIX:
        // Previously used unsafe array slicing:
        //   let lookbackRange = max(0, index - 2)..<index
        //   let precedingWords = Array(words[lookbackRange])
        //
        // This crashed when index was 0 or 1 because Swift
        // Array subscript with Range requires valid bounds.
        //
        // FIX: Use a safe helper function that checks bounds
        // before accessing the array.
        // --------------------------------------------------------

        // Tokenize text into clean lowercase words
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { word in
                word.trimmingCharacters(in: .punctuationCharacters)
            }
            .filter { !$0.isEmpty }

        // Guard against empty word list
        guard !words.isEmpty else { return 0.0 }

        var scores: [Double] = []

        for (index, word) in words.enumerated() {

            // ---- Check for keyword match ----
            var keywordScore: Double? = nil

            if let positiveScore = positiveKeywords[word] {
                keywordScore = positiveScore
            } else if let negativeScore = negativeKeywords[word] {
                keywordScore = negativeScore
            }

            guard var score = keywordScore else { continue }

            // ---- SAFE: Get preceding words ----
            // This replaces the unsafe array slicing that caused
            // the crash. We manually check bounds before accessing.
            let precedingWords = safePrecedingWords(
                words: words,
                currentIndex: index,
                lookback: 2
            )

            // ---- Check for negation ----
            let isNegated = precedingWords.contains {
                negationWords.contains($0)
            }
            if isNegated {
                score = -score * 0.85
            }

            // ---- Check for intensifiers ----
            let hasIntensifier = precedingWords.contains {
                intensifierWords.contains($0)
            }
            if hasIntensifier {
                score = score * 1.3
            }

            // ---- Check for diminishers ----
            let hasDiminisher = precedingWords.contains {
                diminisherWords.contains($0)
            }
            if hasDiminisher {
                score = score * 0.6
            }

            scores.append(score)
        }

        guard !scores.isEmpty else { return 0.0 }

        // Sort by magnitude and take top 3
        let sortedByMagnitude = scores.sorted {
            abs($0) > abs($1)
        }
        let topScores = Array(sortedByMagnitude.prefix(3))
        let average = topScores.reduce(0.0, +) / Double(topScores.count)

        return min(1.0, max(-1.0, average))
    }

    // --------------------------------------------------------
    // safePrecedingWords(words:currentIndex:lookback:)
    //
    // SAFE array access helper — returns preceding words
    // without risk of index out of bounds crash.
    //
    // Parameters:
    //   words        — the full word array
    //   currentIndex — current position in the array
    //   lookback     — how many words back to look
    //
    // Returns:
    //   Array of words before currentIndex (up to lookback)
    //   Empty array if currentIndex is 0
    //
    // Example:
    //   words = ["I", "am", "very", "happy"]
    //   currentIndex = 3 ("happy"), lookback = 2
    //   returns ["am", "very"] ← safe! ✅
    //
    //   currentIndex = 0 ("I"), lookback = 2
    //   returns [] ← no crash! ✅
    // --------------------------------------------------------
    private func safePrecedingWords(
        words: [String],
        currentIndex: Int,
        lookback: Int
    ) -> [String] {
        // If we're at the first word there's nothing before it
        guard currentIndex > 0 else { return [] }

        // Calculate safe start index
        // max(0, ...) prevents negative indices
        let safeStart = max(0, currentIndex - lookback)

        // Calculate safe end index
        // min(..., words.count) prevents out of bounds
        let safeEnd = min(currentIndex, words.count)

        // Final safety check
        guard safeStart < safeEnd else { return [] }

        // Now safe to slice
        return Array(words[safeStart..<safeEnd])
    }
}

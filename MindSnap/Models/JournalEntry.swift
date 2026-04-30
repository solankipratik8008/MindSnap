import SwiftData
import Foundation

@Model
class JournalEntry {

    // --------------------------------------------------------
    // id — Unique identifier
    // --------------------------------------------------------
    var id: UUID = UUID()

    // --------------------------------------------------------
    // date — When the entry was written
    // --------------------------------------------------------
    var date: Date = Date()

    // --------------------------------------------------------
    // text — The actual journal entry content
    // --------------------------------------------------------
    var text: String = ""

    // Optional archived rich text for formatting and inline images.
    var richTextData: Data? = nil

    // --------------------------------------------------------
    // moodType — STORED AS STRING (CloudKit safe)
    // --------------------------------------------------------
    var moodTypeRaw: String = MoodType.neutral.rawValue

    // --------------------------------------------------------
    // sentimentScore
    // --------------------------------------------------------
    var sentimentScore: Double = 0.0

    // --------------------------------------------------------
    // tags
    // --------------------------------------------------------
    var tags: [String] = []

    // --------------------------------------------------------
    // reflectionPromptUsed
    // --------------------------------------------------------
    var reflectionPromptUsed: String? = nil

    // --------------------------------------------------------
    // isPinned
    // --------------------------------------------------------
    var isPinned: Bool = false

    // --------------------------------------------------------
    // isLocked — Requires Face ID / Touch ID / passcode to open
    // --------------------------------------------------------
    var isLocked: Bool = false

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------

    var moodType: MoodType {
        get { MoodType(rawValue: moodTypeRaw) ?? .neutral }
        set { moodTypeRaw = newValue.rawValue }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var previewText: String {
        if isLocked {
            return "Locked journal entry"
        }

        return String(text.prefix(100))
    }

    // --------------------------------------------------------
    // MARK: - Initializer
    // --------------------------------------------------------
    init(
        text: String,
        richTextData: Data? = nil,
        moodType: MoodType = .neutral,
        sentimentScore: Double = 0.0,
        tags: [String] = [],
        reflectionPromptUsed: String? = nil,
        isPinned: Bool = false,
        isLocked: Bool = false
    ) {
        self.text = text
        self.richTextData = richTextData
        self.moodTypeRaw = moodType.rawValue
        self.sentimentScore = sentimentScore
        self.tags = tags
        self.reflectionPromptUsed = reflectionPromptUsed
        self.isPinned = isPinned
        self.isLocked = isLocked
    }
}

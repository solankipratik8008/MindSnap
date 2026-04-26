import SwiftData
import SwiftUI
import Foundation

// --------------------------------------------------------
// MARK: - Supporting Models
// --------------------------------------------------------

struct HealthyLimit {
    let maxValue: Int
    let unit: String
    let warningMessage: String
    let source: String
}

// ========================================================
// MARK: - Goal Model
// ========================================================

@Model
class Goal {

    var id: UUID = UUID()
    var createdAt: Date = Date()

    var name: String = ""
    var emoji: String = "⭐"
    var sfSymbol: String = "star.fill"

    var categoryRaw: String = GoalCategory.custom.rawValue
    var goalTypeRaw: String = GoalType.checkbox.rawValue
    var activityTypeRaw: String = GoalActivityType.custom.rawValue
    var priorityRaw: String = GoalPriority.medium.rawValue

    var targetValue: Int = 1
    var currentValue: Int = 0
    var currentValueDouble: Double = 0
    var unit: String = ""

    var repeatTypeRaw: String = GoalRepeatType.daily.rawValue
    var customRepeatDays: String = "1,2,3,4,5"

    var remindersData: Data? = nil

    var totalPointsEarned: Int = 0

    var sortOrder: Int = 0
    var isActive: Bool = true
    var isHealthKitLinked: Bool = false

    var scheduledDate: Date = Date()

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------

    var category: GoalCategory {
        get {
            GoalCategory(rawValue: categoryRaw)
                ?? GoalCategory(rawValue: categoryRaw.lowercased())
                ?? .custom
        }
        set { categoryRaw = newValue.rawValue }
    }

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw.lowercased()) ?? .checkbox }
        set { goalTypeRaw = newValue.rawValue }
    }

    var activityType: GoalActivityType {
        get { GoalActivityType(rawValue: activityTypeRaw.lowercased()) ?? .custom }
        set { activityTypeRaw = newValue.rawValue }
    }

    var repeatType: GoalRepeatType {
        get {
            GoalRepeatType(rawValue: repeatTypeRaw)
                ?? GoalRepeatType(rawValue: repeatTypeRaw.lowercased())
                ?? legacyRepeatType(from: repeatTypeRaw)
                ?? .daily
        }
        set { repeatTypeRaw = newValue.rawValue }
    }

    var priority: GoalPriority {
        get { GoalPriority(rawValue: priorityRaw.lowercased()) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var reminders: [ReminderTime] {
        get {
            guard let data = remindersData else { return [] }
            return (try? JSONDecoder().decode([ReminderTime].self, from: data)) ?? []
        }
        set {
            remindersData = try? JSONEncoder().encode(newValue)
        }
    }

    var customRepeatDaysArray: [Int] {
        customRepeatDays.split(separator: ",").compactMap { Int($0) }
    }

    var isScheduledForToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if repeatType == .none {
            return calendar.isDate(scheduledDate, inSameDayAs: today)
        }

        let weekday = calendar.component(.weekday, from: today)
        let mondayBased = weekday == 1 ? 7 : weekday - 1

        switch repeatType {
        case .daily: return true
        case .weekdays: return mondayBased <= 5
        case .weekends: return mondayBased >= 6
        case .custom: return customRepeatDaysArray.contains(mondayBased)
        case .none: return false
        }
    }

    var pointsPerCompletion: Int {
        goalType == .checkbox ? 10 : 15
    }

    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentProgressValue / Double(targetValue), 1.0)
    }

    var currentProgressValue: Double {
        currentValueDouble > 0 ? currentValueDouble : Double(currentValue)
    }

    var animationStyle: GoalAnimationStyle {
        switch activityType {
        case .water:
            return .wave
        case .reading, .studying:
            return .stars
        case .running, .cycling:
            return .speedLines
        case .gym:
            return .powerBurst
        case .meditation, .yoga:
            return .calmPulse
        case .sleep:
            return .moonStars
        case .walking:
            return .stepTrail
        default:
            return .confetti
        }
    }

    func partialPoints(for progress: Int) -> Int {
        partialPoints(for: Double(progress))
    }

    func partialPoints(for progress: Double) -> Int {
        guard targetValue > 0 else { return 0 }
        let pct = min(progress / Double(targetValue), 1.0)
        return Int(Double(pointsPerCompletion) * pct)
    }

    func exceedsHealthyLimit(value: Int) -> HealthyLimit? {
        if let limit = activityType.healthyLimit,
           unit == limit.unit,
           value > limit.maxValue {
            return limit
        }
        return nil
    }

    private func legacyRepeatType(from rawValue: String) -> GoalRepeatType? {
        switch rawValue.lowercased() {
        case "every day": return .daily
        case "weekdays": return .weekdays
        case "weekends": return .weekends
        case "custom days": return .custom
        case "one time only", "today only": return GoalRepeatType.none
        default: return nil
        }
    }

    // --------------------------------------------------------
    // MARK: - Initializers
    // --------------------------------------------------------

    init() {}

    convenience init(
        name: String,
        emoji: String,
        sfSymbol: String,
        category: GoalCategory,
        goalType: GoalType,
        activityType: GoalActivityType,
        priority: GoalPriority,
        targetValue: Int,
        unit: String,
        repeatType: GoalRepeatType = .daily,
        customRepeatDays: String = "1,2,3,4,5",
        reminders: [ReminderTime] = [],
        sortOrder: Int = 0,
        scheduledDate: Date = Date()
    ) {
        self.init()
        self.name = name
        self.emoji = emoji
        self.sfSymbol = sfSymbol
        self.category = category
        self.goalType = goalType
        self.activityType = activityType
        self.priority = priority
        self.targetValue = targetValue
        self.unit = unit
        self.repeatType = repeatType
        self.customRepeatDays = customRepeatDays
        self.reminders = reminders
        self.sortOrder = sortOrder
        self.scheduledDate = scheduledDate
    }

    convenience init(
        name: String,
        emoji: String,
        sfSymbol: String,
        category: GoalCategory,
        goalType: GoalType,
        activityType: GoalActivityType,
        priority: GoalPriority
    ) {
        self.init(
            name: name,
            emoji: emoji,
            sfSymbol: sfSymbol,
            category: category,
            goalType: goalType,
            activityType: activityType,
            priority: priority,
            targetValue: 1,
            unit: "",
            repeatType: .daily,
            customRepeatDays: "1,2,3,4,5",
            reminders: [],
            sortOrder: 0,
            scheduledDate: Date()
        )
    }

}

extension Goal {
    var color: Color { activityType == .custom ? category.color : activityType.color }
    var secondaryColor: Color { activityType == .custom ? category.secondaryColor : activityType.secondaryColor }
}

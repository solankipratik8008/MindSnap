//
//  Goal.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//
// ============================================================
// Goal.swift
// MindSnap — MIGRATION FIXED + ALL DEFAULTS SET
//
// CRITICAL FIX:
// All new properties now have default values.
// This prevents SwiftData migration crashes when
// upgrading from older versions of the app.
//
// RULE: Every @Model property MUST have a default value
// or be Optional — never a mandatory field without default.
// ============================================================

import SwiftData
import SwiftUI
import Foundation

// --------------------------------------------------------
// GoalPriority
// --------------------------------------------------------
enum GoalPriority: String, Codable, CaseIterable {
    case high   = "High"
    case medium = "Medium"
    case low    = "Low"

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .high:   return "🔴"
        case .medium: return "🟡"
        case .low:    return "🟢"
        }
    }

    var color: Color {
        switch self {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }

    var icon: String {
        switch self {
        case .high:   return "exclamationmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low:    return "checkmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .high:
            return "High priority - prominent reminder"
        case .medium:
            return "Important — standard reminder"
        case .low:
            return "Optional — subtle reminder"
        }
    }
}

// --------------------------------------------------------
// GoalRepeatType
// --------------------------------------------------------
enum GoalRepeatType: String, Codable, CaseIterable {
    case daily    = "Every Day"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom   = "Custom Days"
    case none     = "One Time Only"

    var icon: String {
        switch self {
        case .daily:    return "arrow.clockwise"
        case .weekdays: return "briefcase.fill"
        case .weekends: return "sun.max.fill"
        case .custom:   return "calendar.badge.checkmark"
        case .none:     return "1.circle.fill"
        }
    }

    var shortDescription: String {
        switch self {
        case .daily:    return "Every day"
        case .weekdays: return "Mon – Fri"
        case .weekends: return "Sat – Sun"
        case .custom:   return "Custom"
        case .none:     return "Today only"
        }
    }

    var description: String {
        switch self {
        case .daily:    return "Repeats every day"
        case .weekdays: return "Repeats Monday to Friday"
        case .weekends: return "Repeats Saturday and Sunday"
        case .custom:   return "Repeats on selected days"
        case .none:     return "Shows today only, gone tomorrow"
        }
    }
}

// --------------------------------------------------------
// GoalType
// --------------------------------------------------------
enum GoalType: String, Codable, CaseIterable {
    case checkbox = "checkbox"
    case progress = "progress"

    var displayName: String {
        switch self {
        case .checkbox: return "Daily Checkbox"
        case .progress: return "Progress Target"
        }
    }

    var icon: String {
        switch self {
        case .checkbox: return "checkmark.circle.fill"
        case .progress: return "chart.bar.fill"
        }
    }

    var description: String {
        switch self {
        case .checkbox: return "Mark as done each day"
        case .progress: return "Track progress toward a target"
        }
    }
}

// --------------------------------------------------------
// GoalActivityType
// --------------------------------------------------------
enum GoalActivityType: String, Codable, CaseIterable {
    case running     = "running"
    case walking     = "walking"
    case cycling     = "cycling"
    case swimming    = "swimming"
    case gym         = "gym"
    case yoga        = "yoga"
    case water       = "water"
    case sleep       = "sleep"
    case reading     = "reading"
    case studying    = "studying"
    case meditation  = "meditation"
    case eating      = "eating"
    case medicine    = "medicine"
    case social      = "social"
    case creative    = "creative"
    case custom      = "custom"

    var needsUnit: Bool {
        switch self {
        case .social, .eating, .medicine: return false
        default: return true
        }
    }

    var defaultPriority: GoalPriority {
        switch self {
        case .medicine: return .high
        case .water, .sleep: return .medium
        default: return .medium
        }
    }

    var unitOptions: [SmartUnit] {
        switch self {
        case .running:
            return [
                SmartUnit(label: "km",
                    suggestion: "5 km is a great daily run"),
                SmartUnit(label: "miles",
                    suggestion: "3 miles is a solid distance"),
                SmartUnit(label: "minutes",
                    suggestion: "30 mins of running is excellent")
            ]
        case .walking:
            return [
                SmartUnit(label: "steps",
                    suggestion: "10,000 steps is the NHS daily goal"),
                SmartUnit(label: "km",
                    suggestion: "5 km walk takes about 60 mins"),
                SmartUnit(label: "miles",
                    suggestion: "3 miles is about 6,000 steps"),
                SmartUnit(label: "minutes",
                    suggestion: "30 mins brisk walk is great")
            ]
        case .cycling:
            return [
                SmartUnit(label: "km",
                    suggestion: "10 km cycling takes about 30 mins"),
                SmartUnit(label: "miles",
                    suggestion: "6 miles is a solid daily ride"),
                SmartUnit(label: "minutes",
                    suggestion: "30 mins cycling burns ~300 calories")
            ]
        case .swimming:
            return [
                SmartUnit(label: "laps",
                    suggestion: "20 laps is a solid swim session"),
                SmartUnit(label: "minutes",
                    suggestion: "30 mins swimming is excellent cardio"),
                SmartUnit(label: "meters",
                    suggestion: "500m is a good beginner target")
            ]
        case .gym:
            return [
                SmartUnit(label: "minutes",
                    suggestion: "45-60 mins is optimal (NHS)"),
                SmartUnit(label: "sets",
                    suggestion: "15-20 sets per muscle group per week"),
                SmartUnit(label: "sessions",
                    suggestion: "3-4 sessions per week is ideal")
            ]
        case .yoga:
            return [
                SmartUnit(label: "minutes",
                    suggestion: "20-30 mins daily yoga improves flexibility"),
                SmartUnit(label: "sessions",
                    suggestion: "Daily practice brings best results")
            ]
        case .water:
            return [
                SmartUnit(label: "glasses",
                    suggestion: "8 glasses (2L) is the daily minimum (WHO)"),
                SmartUnit(label: "ml",
                    suggestion: "2000-3700ml per day (WHO)"),
                SmartUnit(label: "L",
                    suggestion: "2-3.7L per day depending on activity"),
                SmartUnit(label: "oz",
                    suggestion: "64-128oz per day is recommended")
            ]
        case .sleep:
            return [
                SmartUnit(label: "hours",
                    suggestion: "7-9 hours is recommended for adults (CDC)")
            ]
        case .reading:
            return [
                SmartUnit(label: "minutes",
                    suggestion: "30 mins daily reading improves cognition"),
                SmartUnit(label: "pages",
                    suggestion: "20 pages/day = 12 books per year"),
                SmartUnit(label: "hours",
                    suggestion: "1 hour of reading per day is excellent")
            ]
        case .studying:
            return [
                SmartUnit(label: "minutes",
                    suggestion: "25-50 min Pomodoro sessions work best"),
                SmartUnit(label: "hours",
                    suggestion: "2-4 hours focused study is optimal"),
                SmartUnit(label: "sessions",
                    suggestion: "3 focused sessions per day works well")
            ]
        case .meditation:
            return [
                SmartUnit(label: "minutes",
                    suggestion: "10-20 mins daily reduces stress significantly"),
                SmartUnit(label: "sessions",
                    suggestion: "1-2 sessions per day is ideal")
            ]
        case .medicine:
            return [
                SmartUnit(label: "tablets",
                    suggestion: "Follow your doctor's prescription"),
                SmartUnit(label: "doses",
                    suggestion: "Never skip prescribed doses"),
                SmartUnit(label: "times",
                    suggestion: "Take at the same time each day")
            ]
        default:
            return [
                SmartUnit(label: "minutes",
                    suggestion: "Track your time"),
                SmartUnit(label: "sessions",
                    suggestion: "Count your sessions"),
                SmartUnit(label: "times",
                    suggestion: "Count occurrences")
            ]
        }
    }

    var healthyLimit: HealthyLimit? {
        switch self {
        case .water:
            return HealthyLimit(
                maxValue: 15, unit: "glasses",
                warningMessage: "⚠️ More than 15 glasses may cause water intoxication.",
                source: "WHO / Mayo Clinic"
            )
        case .running:
            return HealthyLimit(
                maxValue: 90, unit: "minutes",
                warningMessage: "⚠️ Running more than 90 mins daily increases injury risk.",
                source: "American Heart Association"
            )
        case .gym:
            return HealthyLimit(
                maxValue: 90, unit: "minutes",
                warningMessage: "⚠️ More than 90 mins of intense training can lead to overtraining.",
                source: "NHS"
            )
        case .sleep:
            return HealthyLimit(
                maxValue: 10, unit: "hours",
                warningMessage: "⚠️ Sleeping more than 10 hours may indicate an underlying condition.",
                source: "CDC"
            )
        case .studying:
            return HealthyLimit(
                maxValue: 8, unit: "hours",
                warningMessage: "⚠️ More than 8 hours causes cognitive fatigue. Take breaks!",
                source: "Harvard Medical School"
            )
        default:
            return nil
        }
    }

    var animationStyle: GoalAnimationStyle {
        switch self {
        case .water:                    return .wave
        case .reading, .studying:       return .stars
        case .running, .cycling:        return .speedLines
        case .gym:                      return .powerBurst
        case .meditation, .yoga:        return .calmPulse
        case .sleep:                    return .moonStars
        case .walking:                  return .stepTrail
        default:                        return .confetti
        }
    }

    static func detect(from name: String) -> GoalActivityType {
        let lower = name.lowercased()
        if lower.contains("run") || lower.contains("jog") {
            return .running
        }
        if lower.contains("walk") { return .walking }
        if lower.contains("cycle") || lower.contains("bike") ||
           lower.contains("cycling") { return .cycling }
        if lower.contains("swim") { return .swimming }
        if lower.contains("gym") || lower.contains("lift") ||
           lower.contains("weight") ||
           lower.contains("workout") { return .gym }
        if lower.contains("yoga") { return .yoga }
        if lower.contains("water") || lower.contains("drink") ||
           lower.contains("hydrat") { return .water }
        if lower.contains("sleep") ||
           lower.contains("rest") { return .sleep }
        if lower.contains("read") ||
           lower.contains("book") { return .reading }
        if lower.contains("study") ||
           lower.contains("learn") { return .studying }
        if lower.contains("meditat") ||
           lower.contains("mindful") { return .meditation }
        if lower.contains("medicine") ||
           lower.contains("tablet") ||
           lower.contains("pill") ||
           lower.contains("medication") { return .medicine }
        if lower.contains("eat") || lower.contains("food") ||
           lower.contains("diet") { return .eating }
        if lower.contains("call") || lower.contains("friend") ||
           lower.contains("family") ||
           lower.contains("social") { return .social }
        if lower.contains("draw") || lower.contains("art") ||
           lower.contains("paint") || lower.contains("creat") ||
           lower.contains("music") { return .creative }
        return .custom
    }
}

// --------------------------------------------------------
// GoalAnimationStyle
// --------------------------------------------------------
enum GoalAnimationStyle: String, Codable {
    case wave, stars, speedLines, powerBurst
    case calmPulse, moonStars, stepTrail, confetti
}

// --------------------------------------------------------
// SmartUnit
// --------------------------------------------------------
struct SmartUnit: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let suggestion: String
}

// --------------------------------------------------------
// HealthyLimit
// --------------------------------------------------------
struct HealthyLimit {
    let maxValue: Int
    let unit: String
    let warningMessage: String
    let source: String
}

// --------------------------------------------------------
// ReminderTime
// --------------------------------------------------------
struct ReminderTime: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int

    var timeString: String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// --------------------------------------------------------
// GoalCategory
// --------------------------------------------------------
enum GoalCategory: String, Codable, CaseIterable {
    case fitness    = "Fitness"
    case mind       = "Mind"
    case health     = "Health"
    case social     = "Social"
    case creativity = "Creativity"
    case custom     = "Custom"

    var symbol: String {
        switch self {
        case .fitness:    return "figure.run"
        case .mind:       return "brain.head.profile"
        case .health:     return "heart.fill"
        case .social:     return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .custom:     return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .fitness:
            return Color(red: 1.0, green: 0.5, blue: 0.1)
        case .mind:
            return Color(red: 0.6, green: 0.3, blue: 0.9)
        case .health:
            return Color(red: 0.1, green: 0.6, blue: 0.9)
        case .social:
            return Color(red: 0.1, green: 0.75, blue: 0.4)
        case .creativity:
            return Color(red: 0.95, green: 0.3, blue: 0.5)
        case .custom:
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .fitness:
            return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .mind:
            return Color(red: 0.3, green: 0.2, blue: 0.8)
        case .health:
            return Color(red: 0.0, green: 0.8, blue: 0.8)
        case .social:
            return Color(red: 0.0, green: 0.9, blue: 0.7)
        case .creativity:
            return Color(red: 0.7, green: 0.1, blue: 0.8)
        case .custom:
            return Color(red: 0.0, green: 0.4, blue: 0.9)
        }
    }
}

// --------------------------------------------------------
// @Model Goal
//
// MIGRATION FIX:
// Every property has a default value.
// No mandatory fields without defaults.
// This ensures clean migration on any device.
// --------------------------------------------------------
@Model
class Goal {

    // ---- Identity ----
    var id: UUID = UUID()
    var createdAt: Date = Date()

    // ---- Display ----
    var name: String = ""
    var emoji: String = "⭐"
    var sfSymbol: String = "star.fill"

    // ---- Type fields (stored as String for SwiftData) ----
    var categoryRaw: String = GoalCategory.custom.rawValue
    var goalTypeRaw: String = GoalType.checkbox.rawValue
    var activityTypeRaw: String = GoalActivityType.custom.rawValue

    // ---- Priority (NEW — has default) ----
    var priorityRaw: String = GoalPriority.medium.rawValue

    // ---- Progress ----
    var targetValue: Int = 1
    var unit: String = ""

    // ---- Repeat ----
    var repeatTypeRaw: String = GoalRepeatType.daily.rawValue
    var customRepeatDays: String = "1,2,3,4,5"

    // ---- Reminders (stored as JSON Data) ----
    var remindersData: Data? = nil

    // ---- Points ----
    var totalPointsEarned: Int = 0
    var partialPointsEarned: Int = 0

    // ---- State ----
    var sortOrder: Int = 0
    var isActive: Bool = true

    // ---- HealthKit ----
    var isHealthKitLinked: Bool = false
    var healthKitTypeIdentifier: String = ""

    // ---- One-time goal date (NEW — has default) ----
    var scheduledDate: Date = Date()

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .checkbox }
        set { goalTypeRaw = newValue.rawValue }
    }

    var activityType: GoalActivityType {
        get { GoalActivityType(rawValue: activityTypeRaw) ?? .custom }
        set { activityTypeRaw = newValue.rawValue }
    }

    var repeatType: GoalRepeatType {
        get { GoalRepeatType(rawValue: repeatTypeRaw) ?? .daily }
        set { repeatTypeRaw = newValue.rawValue }
    }

    var priority: GoalPriority {
        get { GoalPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var reminders: [ReminderTime] {
        get {
            guard let data = remindersData else { return [] }
            return (try? JSONDecoder().decode(
                [ReminderTime].self, from: data
            )) ?? []
        }
        set {
            remindersData = try? JSONEncoder().encode(newValue)
        }
    }

    var customRepeatDaysArray: [Int] {
        get {
            customRepeatDays
                .split(separator: ",")
                .compactMap { Int($0) }
        }
        set {
            customRepeatDays = newValue
                .map { "\($0)" }
                .joined(separator: ",")
        }
    }

    // --------------------------------------------------------
    // isScheduledForToday
    // --------------------------------------------------------
    var isScheduledForToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if repeatType == .none {
            let scheduled = calendar.startOfDay(
                for: scheduledDate
            )
            return scheduled == today
        }

        let weekday = calendar.component(.weekday, from: today)
        let mondayBased = weekday == 1 ? 7 : weekday - 1

        switch repeatType {
        case .daily:    return true
        case .weekdays: return mondayBased <= 5
        case .weekends: return mondayBased >= 6
        case .custom:
            return customRepeatDaysArray.contains(mondayBased)
        case .none:     return false
        }
    }

    var color: Color { category.color }
    var secondaryColor: Color { category.secondaryColor }

    var pointsPerCompletion: Int {
        switch goalType {
        case .checkbox: return 10
        case .progress: return 15
        }
    }

    func partialPoints(for progress: Int) -> Int {
        guard goalType == .progress && targetValue > 0 else {
            return 0
        }
        let pct = min(
            1.0,
            Double(progress) / Double(targetValue)
        )
        return Int(Double(pointsPerCompletion) * pct)
    }

    var animationStyle: GoalAnimationStyle {
        activityType.animationStyle
    }

    var healthyLimit: HealthyLimit? {
        activityType.healthyLimit
    }

    func exceedsHealthyLimit(value: Int) -> HealthyLimit? {
        guard let limit = healthyLimit else { return nil }
        if unit == limit.unit && value > limit.maxValue {
            return limit
        }
        return nil
    }

    // --------------------------------------------------------
    // MARK: - Initializer
    // --------------------------------------------------------
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String = "",
        emoji: String = "⭐",
        sfSymbol: String = "star.fill",
        category: GoalCategory = .custom,
        goalType: GoalType = .checkbox,
        activityType: GoalActivityType = .custom,
        priority: GoalPriority = .medium,
        targetValue: Int = 1,
        unit: String = "",
        repeatType: GoalRepeatType = .daily,
        customRepeatDays: String = "1,2,3,4,5",
        reminders: [ReminderTime] = [],
        totalPointsEarned: Int = 0,
        partialPointsEarned: Int = 0,
        sortOrder: Int = 0,
        isActive: Bool = true,
        isHealthKitLinked: Bool = false,
        healthKitTypeIdentifier: String = "",
        scheduledDate: Date = Date()
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.emoji = emoji
        self.sfSymbol = sfSymbol
        self.categoryRaw = category.rawValue
        self.goalTypeRaw = goalType.rawValue
        self.activityTypeRaw = activityType.rawValue
        self.priorityRaw = priority.rawValue
        self.targetValue = targetValue
        self.unit = unit
        self.repeatTypeRaw = repeatType.rawValue
        self.customRepeatDays = customRepeatDays
        self.totalPointsEarned = totalPointsEarned
        self.partialPointsEarned = partialPointsEarned
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.isHealthKitLinked = isHealthKitLinked
        self.healthKitTypeIdentifier = healthKitTypeIdentifier
        self.scheduledDate = scheduledDate
        self.remindersData = try? JSONEncoder().encode(reminders)
    }
}

// --------------------------------------------------------
// PresetGoal
// --------------------------------------------------------
struct PresetGoal {
    let name: String
    let emoji: String
    let sfSymbol: String
    let category: GoalCategory
    let activityType: GoalActivityType
    let goalType: GoalType
    let targetValue: Int
    let unit: String
    let defaultHour: Int
    let repeatType: GoalRepeatType
    let priority: GoalPriority

    static func suggestEmoji(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("run") || lower.contains("jog") {
            return "🏃"
        }
        if lower.contains("gym") || lower.contains("lift") ||
           lower.contains("weight") { return "🏋️" }
        if lower.contains("walk") { return "🚶" }
        if lower.contains("swim") { return "🏊" }
        if lower.contains("bike") || lower.contains("cycle") {
            return "🚴"
        }
        if lower.contains("yoga") { return "🧘" }
        if lower.contains("water") || lower.contains("drink") ||
           lower.contains("hydrat") { return "💧" }
        if lower.contains("sleep") { return "😴" }
        if lower.contains("eat") || lower.contains("food") {
            return "🥗"
        }
        if lower.contains("meditat") { return "🧘" }
        if lower.contains("read") || lower.contains("book") {
            return "📚"
        }
        if lower.contains("study") || lower.contains("learn") {
            return "🎓"
        }
        if lower.contains("medicine") || lower.contains("tablet") ||
           lower.contains("pill") { return "💊" }
        if lower.contains("music") { return "🎵" }
        if lower.contains("code") { return "💻" }
        if lower.contains("call") || lower.contains("family") {
            return "📞"
        }
        if lower.contains("draw") || lower.contains("art") ||
           lower.contains("paint") { return "🎨" }
        return "⭐"
    }

    static let all: [PresetGoal] = [
        PresetGoal(
            name: "Morning Run", emoji: "🏃",
            sfSymbol: "figure.run", category: .fitness,
            activityType: .running, goalType: .progress,
            targetValue: 5, unit: "km", defaultHour: 7,
            repeatType: .daily, priority: .medium
        ),
        PresetGoal(
            name: "Gym Session", emoji: "🏋️",
            sfSymbol: "dumbbell.fill", category: .fitness,
            activityType: .gym, goalType: .progress,
            targetValue: 60, unit: "minutes", defaultHour: 7,
            repeatType: .weekdays, priority: .medium
        ),
        PresetGoal(
            name: "Daily Water", emoji: "💧",
            sfSymbol: "drop.fill", category: .health,
            activityType: .water, goalType: .progress,
            targetValue: 8, unit: "glasses", defaultHour: 9,
            repeatType: .daily, priority: .medium
        ),
        PresetGoal(
            name: "Take Medicine", emoji: "💊",
            sfSymbol: "pills.fill", category: .health,
            activityType: .medicine, goalType: .checkbox,
            targetValue: 1, unit: "", defaultHour: 8,
            repeatType: .daily, priority: .high
        ),
        PresetGoal(
            name: "Read", emoji: "📚",
            sfSymbol: "book.fill", category: .mind,
            activityType: .reading, goalType: .progress,
            targetValue: 30, unit: "minutes", defaultHour: 21,
            repeatType: .daily, priority: .low
        ),
        PresetGoal(
            name: "Meditate", emoji: "🧘",
            sfSymbol: "brain.head.profile", category: .mind,
            activityType: .meditation, goalType: .progress,
            targetValue: 10, unit: "minutes", defaultHour: 8,
            repeatType: .daily, priority: .medium
        ),
        PresetGoal(
            name: "Sleep 8hrs", emoji: "😴",
            sfSymbol: "moon.stars.fill", category: .health,
            activityType: .sleep, goalType: .progress,
            targetValue: 8, unit: "hours", defaultHour: 22,
            repeatType: .daily, priority: .high
        ),
        PresetGoal(
            name: "Walk", emoji: "🚶",
            sfSymbol: "figure.walk", category: .fitness,
            activityType: .walking, goalType: .progress,
            targetValue: 10000, unit: "steps", defaultHour: 18,
            repeatType: .daily, priority: .low
        ),
        PresetGoal(
            name: "Healthy Eating", emoji: "🥗",
            sfSymbol: "leaf.fill", category: .health,
            activityType: .eating, goalType: .checkbox,
            targetValue: 1, unit: "", defaultHour: 12,
            repeatType: .daily, priority: .medium
        ),
        PresetGoal(
            name: "Study", emoji: "🎓",
            sfSymbol: "graduationcap.fill", category: .mind,
            activityType: .studying, goalType: .progress,
            targetValue: 60, unit: "minutes", defaultHour: 19,
            repeatType: .weekdays, priority: .medium
        ),
        PresetGoal(
            name: "Creative Time", emoji: "🎨",
            sfSymbol: "paintbrush.fill", category: .creativity,
            activityType: .creative, goalType: .progress,
            targetValue: 30, unit: "minutes", defaultHour: 17,
            repeatType: .daily, priority: .low
        ),
        PresetGoal(
            name: "Call Family", emoji: "📞",
            sfSymbol: "phone.fill", category: .social,
            activityType: .social, goalType: .checkbox,
            targetValue: 1, unit: "", defaultHour: 18,
            repeatType: .daily, priority: .medium
        )
    ]
}

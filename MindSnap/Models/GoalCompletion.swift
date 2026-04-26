//
//  GoalCompletion.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//
// ============================================================
// GoalCompletion.swift
// MindSnap — MIGRATION FIXED + ALL DEFAULTS SET
//
// CRITICAL FIX:
// Every property has a default value.
// No mandatory fields without defaults.
// ============================================================

import SwiftData
import SwiftUI
import Foundation

// --------------------------------------------------------
// CompletionSource
// --------------------------------------------------------
enum CompletionSource: String, Codable {
    case manual    = "manual"
    case automatic = "automatic"
    case edited    = "edited"
    case partial   = "partial"
}

// --------------------------------------------------------
// @Model GoalCompletion
//
// MIGRATION FIX:
// All properties have default values.
// --------------------------------------------------------
@Model
class GoalCompletion {

    var id: UUID = UUID()
    var goalID: UUID = UUID()
    var goalName: String = ""
    var completedAt: Date = Date()

    // ---- Progress ----
    var currentValue: Int = 0
    var currentValueDouble: Double = 0
    var targetValue: Int = 1

    // ---- Points ----
    var pointsEarned: Int = 0
    var isPointsAwarded: Bool = false
    var partialPointsAwarded: Bool = false
    var partialPointsAmount: Int = 0

    // ---- State ----
    var isCompleted: Bool = false
    var completionSourceRaw: String = CompletionSource.manual.rawValue
    var toggleCount: Int = 0
    var notes: String = ""

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    var completionSource: CompletionSource {
        get {
            CompletionSource(rawValue: completionSourceRaw)
                ?? .manual
        }
        set { completionSourceRaw = newValue.rawValue }
    }

    var completionPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(
            1.0,
            progressValue / Double(targetValue)
        )
    }

    var progressValue: Double {
        currentValueDouble > 0 ? currentValueDouble : Double(currentValue)
    }

    var isPartialCompletion: Bool {
        currentValue > 0 && !isCompleted
    }

    var completionDay: Date {
        Calendar.current.startOfDay(for: completedAt)
    }

    // --------------------------------------------------------
    // MARK: - Initializer
    // --------------------------------------------------------
    init(
        id: UUID = UUID(),
        goalID: UUID,
        goalName: String = "",
        currentValue: Int = 0,
        currentValueDouble: Double? = nil,
        targetValue: Int = 1,
        pointsEarned: Int = 0,
        isCompleted: Bool = false,
        completionSource: CompletionSource = .manual,
        isPointsAwarded: Bool = false,
        partialPointsAwarded: Bool = false,
        partialPointsAmount: Int = 0,
        toggleCount: Int = 0,
        notes: String = "",
        completedAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.goalName = goalName
        self.currentValue = currentValue
        self.currentValueDouble = currentValueDouble ?? Double(currentValue)
        self.targetValue = targetValue
        self.pointsEarned = pointsEarned
        self.isCompleted = isCompleted
        self.completionSourceRaw = completionSource.rawValue
        self.isPointsAwarded = isPointsAwarded
        self.partialPointsAwarded = partialPointsAwarded
        self.partialPointsAmount = partialPointsAmount
        self.toggleCount = toggleCount
        self.notes = notes
        self.completedAt = completedAt
    }
}

// --------------------------------------------------------
// UserPoints — Global points using UserDefaults
// --------------------------------------------------------
struct UserPoints {

    private static let totalKey = "mindsnap_total_points"

    static var total: Int {
        UserDefaults.standard.integer(forKey: totalKey)
    }

    static func add(_ points: Int) {
        guard points > 0 else { return }
        let current = UserDefaults.standard.integer(
            forKey: totalKey
        )
        UserDefaults.standard.set(
            current + points,
            forKey: totalKey
        )
    }

    static func subtract(_ points: Int) {
        let current = UserDefaults.standard.integer(
            forKey: totalKey
        )
        UserDefaults.standard.set(
            max(0, current - points),
            forKey: totalKey
        )
    }

    static func reset() {
        UserDefaults.standard.set(0, forKey: totalKey)
    }

    static var level: PointsLevel {
        PointsLevel.level(for: total)
    }

    static var progressToNextLevel: Double {
        level.progressToNext(currentPoints: total)
    }

    static var pointsToNextLevel: Int {
        level.pointsToNext(currentPoints: total)
    }
}

// --------------------------------------------------------
// PointsLevel — Gamification
// --------------------------------------------------------
enum PointsLevel: String, CaseIterable {
    case beginner       = "Beginner"
    case buildingHabits = "Building Habits"
    case goalGetter     = "Goal Getter"
    case consistent     = "Consistent"
    case champion       = "Champion"

    var emoji: String {
        switch self {
        case .beginner:       return "🌱"
        case .buildingHabits: return "🌿"
        case .goalGetter:     return "⭐"
        case .consistent:     return "🔥"
        case .champion:       return "🏆"
        }
    }

    var color: Color {
        switch self {
        case .beginner:       return .green
        case .buildingHabits: return .blue
        case .goalGetter:     return .purple
        case .consistent:     return .orange
        case .champion:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }

    var minPoints: Int {
        switch self {
        case .beginner:       return 0
        case .buildingHabits: return 101
        case .goalGetter:     return 301
        case .consistent:     return 601
        case .champion:       return 1001
        }
    }

    var maxPoints: Int {
        switch self {
        case .beginner:       return 100
        case .buildingHabits: return 300
        case .goalGetter:     return 600
        case .consistent:     return 1000
        case .champion:       return Int.max
        }
    }

    var message: String {
        switch self {
        case .beginner:
            return "Just getting started! 🌱"
        case .buildingHabits:
            return "Building strong habits! 💪"
        case .goalGetter:
            return "Goals are your superpower! ⭐"
        case .consistent:
            return "Unstoppable consistency! 🔥"
        case .champion:
            return "You're a MindSnap Champion! 🏆"
        }
    }

    func progressToNext(currentPoints: Int) -> Double {
        if self == .champion { return 1.0 }
        let inLevel = currentPoints - minPoints
        let range = maxPoints - minPoints
        guard range > 0 else { return 1.0 }
        return min(1.0, Double(inLevel) / Double(range))
    }

    func pointsToNext(currentPoints: Int) -> Int {
        if self == .champion { return 0 }
        return max(0, maxPoints + 1 - currentPoints)
    }

    static func level(for points: Int) -> PointsLevel {
        if points >= 1001 { return .champion }
        if points >= 601  { return .consistent }
        if points >= 301  { return .goalGetter }
        if points >= 101  { return .buildingHabits }
        return .beginner
    }
}

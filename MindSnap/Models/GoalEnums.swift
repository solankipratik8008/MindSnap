//
//  GoalEnums.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-26.
//
import SwiftUI

// MARK: - Animation
enum GoalAnimationStyle {
    case wave
    case stars
    case speedLines
    case powerBurst
    case calmPulse
    case moonStars
    case stepTrail
    case confetti
}

// MARK: - Priority
enum GoalPriority: String, CaseIterable, Codable {
    case low, medium, high

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "exclamationmark"
        }
    }

    var displayName: String { rawValue.capitalized }

    var description: String {
        switch self {
        case .low: return "Nice-to-have goal. Keep it light and sustainable."
        case .medium: return "Important goal. Worth steady daily attention."
        case .high: return "Essential goal. MindSnap will keep it prominent."
        }
    }

    var emoji: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🔵"
        case .high: return "🔴"
        }
    }
}

// MARK: - Type
enum GoalType: String, CaseIterable, Codable {
    case checkbox, progress

    var icon: String {
        switch self {
        case .checkbox: return "checkmark.circle"
        case .progress: return "chart.bar"
        }
    }

    var displayName: String {
        switch self {
        case .checkbox: return "Checklist"
        case .progress: return "Progress"
        }
    }

    var description: String {
        switch self {
        case .checkbox: return "Tap once when it is done"
        case .progress: return "Track a number toward a target"
        }
    }
}

// MARK: - Repeat
enum GoalRepeatType: String, CaseIterable, Codable {
    case daily, weekdays, weekends, custom, none

    var shortDescription: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom"
        case .none: return "Today only"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max"
        case .weekdays: return "briefcase"
        case .weekends: return "moon.stars"
        case .custom: return "slider.horizontal.3"
        case .none: return "nosign"
        }
    }

    var description: String {
        switch self {
        case .daily: return "Repeats every day"
        case .weekdays: return "Repeats Monday through Friday"
        case .weekends: return "Repeats Saturday and Sunday"
        case .custom: return "Choose specific days"
        case .none: return "Only appears today"
        }
    }
}

// MARK: - Category
enum GoalCategory: String, CaseIterable, Codable {
    case fitness, mind, health, social, creativity, custom

    var color: Color {
        switch self {
        case .fitness: return .orange
        case .mind: return .purple
        case .health: return .red
        case .social: return .teal
        case .creativity: return .pink
        case .custom: return .gray
        }
    }

    var secondaryColor: Color { color.opacity(0.6) }

    var symbol: String {
        switch self {
        case .fitness: return "figure.walk"
        case .mind: return "brain.head.profile"
        case .health: return "heart.fill"
        case .social: return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .custom: return "star.fill"
        }
    }
}

// MARK: - Activity
enum GoalActivityType: String, CaseIterable, Codable {
    case running
    case walking
    case cycling
    case swimming
    case gym
    case yoga
    case water
    case sleep
    case reading
    case studying
    case meditation
    case eating
    case medicine
    case social
    case creative
    case custom
}

extension GoalActivityType {
    var color: Color {
        switch self {
        case .running, .walking, .cycling, .swimming, .gym, .yoga:
            return .orange
        case .water:
            return .cyan
        case .sleep:
            return .indigo
        case .reading, .studying, .meditation:
            return .purple
        case .eating, .medicine:
            return .pink
        case .social:
            return .teal
        case .creative:
            return .pink
        case .custom:
            return .blue
        }
    }

    var secondaryColor: Color {
        switch self {
        case .water:
            return .blue
        case .sleep:
            return .pink
        case .running, .walking, .cycling, .swimming, .gym, .yoga:
            return .red
        case .reading, .studying, .meditation:
            return .indigo
        case .social:
            return .green
        case .eating, .medicine, .creative:
            return .red
        case .custom:
            return .purple
        }
    }
}

// MARK: - Unit
enum SmartUnit: String, CaseIterable, Codable, Identifiable {
    case steps
    case km
    case miles
    case minutes
    case hours
    case glasses
    case ml
    case liters
    case pages
    case sessions
    case times
    case count

    var id: String { rawValue }

    var label: String {
        switch self {
        case .steps: return "steps"
        case .km: return "km"
        case .miles: return "miles"
        case .minutes: return "minutes"
        case .hours: return "hours"
        case .glasses: return "glasses"
        case .ml: return "ml"
        case .liters: return "L"
        case .pages: return "pages"
        case .sessions: return "sessions"
        case .times: return "times"
        case .count: return "count"
        }
    }

    var suggestion: String {
        switch self {
        case .steps: return "10,000 steps is a strong daily walking goal"
        case .km: return "5 km is a solid daily distance"
        case .miles: return "3 miles is a good daily target"
        case .minutes: return "30 minutes is a healthy daily target"
        case .hours: return "7-9 hours is recommended for sleep"
        case .glasses: return "8 glasses is a common daily hydration goal"
        case .ml: return "2000 ml is a common hydration target"
        case .liters: return "2 L is a common hydration target"
        case .pages: return "20 pages per day builds a strong reading habit"
        case .sessions: return "1 session per day is a good start"
        case .times: return "Track how many times you complete it"
        case .count: return "Track your count"
        }
    }
}

extension GoalActivityType {
    static func detect(from name: String) -> GoalActivityType {
        let lower = name.lowercased()

        if lower.contains("run") || lower.contains("jog") { return .running }
        if lower.contains("walk") { return .walking }
        if lower.contains("cycle") || lower.contains("bike") { return .cycling }
        if lower.contains("swim") { return .swimming }
        if lower.contains("gym") || lower.contains("workout") || lower.contains("lift") { return .gym }
        if lower.contains("yoga") { return .yoga }
        if lower.contains("water") || lower.contains("drink") || lower.contains("hydrat") { return .water }
        if lower.contains("sleep") { return .sleep }
        if lower.contains("read") || lower.contains("book") { return .reading }
        if lower.contains("study") || lower.contains("learn") { return .studying }
        if lower.contains("meditat") || lower.contains("mindful") { return .meditation }
        if lower.contains("medicine") || lower.contains("tablet") || lower.contains("pill") { return .medicine }
        if lower.contains("eat") || lower.contains("food") { return .eating }
        if lower.contains("call") || lower.contains("friend") || lower.contains("family") { return .social }
        if lower.contains("draw") || lower.contains("art") || lower.contains("paint") { return .creative }

        return .custom
    }

    var needsUnit: Bool {
        switch self {
        case .social, .eating, .medicine:
            return false
        default:
            return true
        }
    }

    var unitOptions: [SmartUnit] {
        switch self {
        case .walking:
            return [.steps, .km, .miles, .minutes]
        case .running:
            return [.km, .miles, .minutes]
        case .cycling:
            return [.km, .miles, .minutes]
        case .water:
            return [.glasses, .ml, .liters]
        case .sleep:
            return [.hours]
        case .reading:
            return [.minutes, .pages, .hours]
        case .studying:
            return [.minutes, .hours, .sessions]
        case .meditation, .yoga:
            return [.minutes, .sessions]
        case .gym:
            return [.minutes, .sessions]
        default:
            return [.minutes, .sessions, .times]
        }
    }

    var healthyLimit: HealthyLimit? {
        switch self {
        case .water:
            return HealthyLimit(maxValue: 15, unit: "glasses", warningMessage: "Too much water can be harmful.", source: "Health guidance")
        case .running:
            return HealthyLimit(maxValue: 90, unit: "minutes", warningMessage: "Too much running may increase injury risk.", source: "Fitness guidance")
        case .sleep:
            return HealthyLimit(maxValue: 10, unit: "hours", warningMessage: "Sleeping too much may indicate an issue.", source: "Health guidance")
        default:
            return nil
        }
    }
}

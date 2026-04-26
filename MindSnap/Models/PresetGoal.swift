//
//  PresetGoal.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-26.
//
import Foundation

struct PresetGoal: Identifiable {
    let id = UUID()
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

    static let all: [PresetGoal] = [
        PresetGoal(name: "Morning Run", emoji: "🏃", sfSymbol: "figure.run", category: .fitness, activityType: .running, goalType: .progress, targetValue: 5, unit: "km", defaultHour: 7, repeatType: .daily, priority: .medium),
        PresetGoal(name: "Gym Session", emoji: "🏋️", sfSymbol: "dumbbell.fill", category: .fitness, activityType: .gym, goalType: .progress, targetValue: 45, unit: "minutes", defaultHour: 7, repeatType: .weekdays, priority: .medium),
        PresetGoal(name: "Daily Water", emoji: "💧", sfSymbol: "drop.fill", category: .health, activityType: .water, goalType: .progress, targetValue: 8, unit: "glasses", defaultHour: 9, repeatType: .daily, priority: .medium),
        PresetGoal(name: "Read", emoji: "📚", sfSymbol: "book.fill", category: .mind, activityType: .reading, goalType: .progress, targetValue: 30, unit: "minutes", defaultHour: 21, repeatType: .daily, priority: .low),
        PresetGoal(name: "Meditate", emoji: "🧘", sfSymbol: "brain.head.profile", category: .mind, activityType: .meditation, goalType: .progress, targetValue: 10, unit: "minutes", defaultHour: 8, repeatType: .daily, priority: .medium),
        PresetGoal(name: "Sleep 8hrs", emoji: "😴", sfSymbol: "moon.stars.fill", category: .health, activityType: .sleep, goalType: .progress, targetValue: 8, unit: "hours", defaultHour: 22, repeatType: .daily, priority: .high),
        PresetGoal(name: "Walk", emoji: "🚶", sfSymbol: "figure.walk", category: .fitness, activityType: .walking, goalType: .progress, targetValue: 10000, unit: "steps", defaultHour: 18, repeatType: .daily, priority: .low),
        PresetGoal(name: "Healthy Eating", emoji: "🥗", sfSymbol: "leaf.fill", category: .health, activityType: .eating, goalType: .checkbox, targetValue: 1, unit: "", defaultHour: 12, repeatType: .daily, priority: .medium),
        PresetGoal(name: "Learn Something", emoji: "🎓", sfSymbol: "graduationcap.fill", category: .mind, activityType: .studying, goalType: .progress, targetValue: 30, unit: "minutes", defaultHour: 19, repeatType: .weekdays, priority: .medium),
        PresetGoal(name: "Creative Time", emoji: "🎨", sfSymbol: "paintbrush.fill", category: .creativity, activityType: .creative, goalType: .progress, targetValue: 30, unit: "minutes", defaultHour: 17, repeatType: .daily, priority: .low),
        PresetGoal(name: "Call Family", emoji: "📞", sfSymbol: "phone.fill", category: .social, activityType: .social, goalType: .checkbox, targetValue: 1, unit: "", defaultHour: 18, repeatType: .daily, priority: .medium),
        PresetGoal(name: "Yoga", emoji: "🧘", sfSymbol: "figure.mind.and.body", category: .fitness, activityType: .yoga, goalType: .progress, targetValue: 20, unit: "minutes", defaultHour: 7, repeatType: .daily, priority: .low),
        PresetGoal(name: "Take Medicine", emoji: "💊", sfSymbol: "pills.fill", category: .health, activityType: .medicine, goalType: .checkbox, targetValue: 1, unit: "", defaultHour: 8, repeatType: .daily, priority: .high)
    ]

    static func suggestEmoji(for text: String) -> String {
        let t = text.lowercased()
        if t.contains("run") { return "🏃" }
        if t.contains("walk") { return "🚶" }
        if t.contains("water") { return "💧" }
        if t.contains("sleep") { return "😴" }
        if t.contains("read") { return "📚" }
        if t.contains("study") { return "🎓" }
        if t.contains("learn") { return "🎓" }
        if t.contains("medicine") || t.contains("pill") { return "💊" }
        if t.contains("gym") || t.contains("workout") { return "🏋️" }
        if t.contains("yoga") || t.contains("meditat") { return "🧘" }
        if t.contains("eat") || t.contains("food") { return "🥗" }
        if t.contains("call") || t.contains("family") { return "📞" }
        if t.contains("draw") || t.contains("art") || t.contains("paint") { return "🎨" }
        return "⭐"
    }
}

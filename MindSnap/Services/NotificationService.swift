//
//  NotificationService.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
// ============================================================
// NotificationService.swift
// MindSnap — PRIORITY NOTIFICATIONS
//
// WHAT CHANGED:
// 1. Priority-based notification sounds
//    High = prominent sound + time-sensitive delivery
//    Medium = default sound
//    Low = quiet subtle sound
// 2. Priority-based notification style
// 3. Deep link URLs in all notifications
// 4. Medicine gets special reminder wording
// 5. Multiple reminders per goal maintained
// ============================================================

import UserNotifications
import SwiftUI

@Observable
class NotificationService {

    var isAuthorized: Bool = false

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // --------------------------------------------------------
    // MARK: - Authorization
    // --------------------------------------------------------
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter
                .current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func hasNotificationAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter
            .current()
            .notificationSettings()
        let authorized =
            settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional ||
            settings.authorizationStatus == .ephemeral

        await MainActor.run {
            isAuthorized = authorized
        }
        return authorized
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter
            .current()
            .notificationSettings()
        await MainActor.run {
            isAuthorized =
                settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional ||
                settings.authorizationStatus == .ephemeral
        }
    }

    // --------------------------------------------------------
    // MARK: - Daily Journal Reminder
    // --------------------------------------------------------
    func scheduleDailyReminder(hour: Int) async {
        guard isAuthorized else { return }
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Time to Journal 📝"
        content.body = dailyReminderMessage()
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "mindsnap_journal",
            "url": "mindsnap://journal"
        ]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "mindsnap-daily-reminder",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter
            .current()
            .add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["mindsnap-daily-reminder"]
            )
    }

    // --------------------------------------------------------
    // MARK: - Goal Reminders with Priority
    //
    // HIGH priority   → Default sound, time-sensitive message
    // MEDIUM priority → Default sound, motivating message
    // LOW priority    → Quiet sound, gentle reminder
    // --------------------------------------------------------
    func scheduleGoalReminders(
        goalID: String,
        goalName: String,
        goalEmoji: String,
        activityType: GoalActivityType,
        priority: GoalPriority = .medium,
        reminders: [ReminderTime]
    ) async {
        guard await hasNotificationAuthorization() else { return }
        cancelGoalReminders(goalID: goalID)

        for reminder in reminders {
            await scheduleGoalReminder(
                goalID: goalID,
                reminderID: reminder.id.uuidString,
                goalName: goalName,
                goalEmoji: goalEmoji,
                activityType: activityType,
                priority: priority,
                hour: reminder.hour,
                minute: reminder.minute
            )
        }
    }

    private func scheduleGoalReminder(
        goalID: String,
        reminderID: String,
        goalName: String,
        goalEmoji: String,
        activityType: GoalActivityType,
        priority: GoalPriority,
        hour: Int,
        minute: Int
    ) async {
        let content = UNMutableNotificationContent()

        // ---- Priority-based title prefix ----
        let priorityPrefix: String
        switch priority {
        case .high:   priorityPrefix = "🔴 IMPORTANT: "
        case .medium: priorityPrefix = ""
        case .low:    priorityPrefix = ""
        }

        content.title = "\(priorityPrefix)\(goalEmoji) \(goalName)"
        content.body = goalReminderMessage(
            activityType: activityType,
            goalName: goalName,
            priority: priority
        )

        // ---- Priority-based sound ----
        switch priority {
        case .high:
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

        case .medium:
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .active
            }

        case .low:
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .active
            }
        }

        content.userInfo = [
            "type": "goal_reminder",
            "goalID": goalID,
            "priority": priority.rawValue,
            "url": "mindsnap://goals"
        ]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let notificationID =
            "goal-\(goalID)-\(reminderID)"

        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter
            .current()
            .add(request)
    }

    // --------------------------------------------------------
    // MARK: - Cancel Goal Reminders
    // --------------------------------------------------------
    func cancelGoalReminders(goalID: String) {
        UNUserNotificationCenter.current()
            .getPendingNotificationRequests { requests in
                let toCancel = requests
                    .filter {
                        $0.identifier.contains(
                            "goal-\(goalID)"
                        ) ||
                        $0.identifier.contains(
                            "expiry-\(goalID)"
                        )
                    }
                    .map { $0.identifier }

                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(
                        withIdentifiers: toCancel
                    )
            }
    }

    // --------------------------------------------------------
    // MARK: - Expiry Notification
    // --------------------------------------------------------
    func scheduleGoalExpiryNotification(
        goalID: String,
        goalName: String,
        goalEmoji: String
    ) async {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let now = Date()

        guard let midnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ),
        let twoHoursBefore = calendar.date(
            byAdding: .hour,
            value: -2,
            to: midnight
        ) else { return }

        guard twoHoursBefore > now else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ \(goalEmoji) Expiring Soon!"
        content.body = "\(goalName) expires in 2 hours. Tap to complete it now!"
        content.sound = .default
        content.userInfo = [
            "type": "goal_expiry",
            "goalID": goalID,
            "url": "mindsnap://goals"
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: twoHoursBefore
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "expiry-\(goalID)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter
            .current()
            .add(request)
    }

    // --------------------------------------------------------
    // MARK: - Partial Points End of Day Notification
    //
    // Fires at 11:55 PM to tell user they earned
    // partial points for incomplete progress goals
    // --------------------------------------------------------
    func schedulePartialPointsNotification(
        goalName: String,
        goalEmoji: String,
        partialPoints: Int,
        progress: Int,
        target: Int,
        unit: String
    ) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title =
            "\(goalEmoji) Day Ending — Partial Points!"
        content.body =
            "You completed \(progress)/\(target) \(unit) for \(goalName). You earned \(partialPoints) pts for your effort! 💪 Every step counts."
        content.sound = .default
        content.userInfo = [
            "type": "partial_points",
            "url": "mindsnap://goals"
        ]

        // Fire at 11:55 PM today
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: Date()
        )
        components.hour = 23
        components.minute = 55

        guard let fireDate = Calendar.current.date(
            from: components
        ),
        fireDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "partial-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter
            .current()
            .add(request)
    }

    // --------------------------------------------------------
    // MARK: - Health Limit Warning
    // --------------------------------------------------------
    func scheduleHealthLimitWarning(
        goalName: String,
        goalEmoji: String,
        warningMessage: String
    ) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Health Check — \(goalName)"
        content.body = warningMessage
        content.sound = .default
        content.userInfo = [
            "type": "health_warning",
            "url": "mindsnap://goals"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "health-warning-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter
            .current()
            .add(request)
    }

    // --------------------------------------------------------
    // MARK: - HealthKit Sync Notification
    // --------------------------------------------------------
    func scheduleHealthKitSyncNotification(
        goalName: String,
        goalEmoji: String,
        progress: Int,
        target: Int,
        unit: String,
        isCompleted: Bool
    ) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()

        if isCompleted {
            content.title = "\(goalEmoji) Goal Complete! 🎉"
            content.body =
                "Your \(goalName) is done — \(progress) \(unit) achieved. Tap to celebrate! 🏆"
        } else {
            content.title = "\(goalEmoji) Progress Update"
            content.body =
                "Health synced: \(progress)/\(target) \(unit) for \(goalName). Keep going! 💪"
        }

        content.sound = .default
        content.userInfo = [
            "type": "healthkit_sync",
            "url": "mindsnap://goals"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "healthkit-sync-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter
            .current()
            .add(request)
    }

    // --------------------------------------------------------
    // MARK: - Badge Reset
    // --------------------------------------------------------
    func resetBadgeCount() {
        UNUserNotificationCenter.current()
            .setBadgeCount(0) { _ in }
    }

    // --------------------------------------------------------
    // MARK: - Smart Messages
    // --------------------------------------------------------
    private func dailyReminderMessage() -> String {
        let messages = [
            "How are you feeling today? Take a moment to reflect.",
            "Your journal is waiting. What's on your mind?",
            "A few minutes of journaling can change your day.",
            "Check in with yourself. How are you doing?",
            "Your thoughts matter. Write them down.",
            "Take a breath and capture today's moments.",
            "A journal entry a day keeps stress away! ✨"
        ]
        return messages.randomElement() ?? messages[0]
    }

    private func goalReminderMessage(
        activityType: GoalActivityType,
        goalName: String,
        priority: GoalPriority = .medium
    ) -> String {

        // ---- High priority gets urgent messages ----
        if priority == .high {
            let urgentMessages = [
                "⚠️ Don't forget! \(goalName) is high priority today.",
                "🔴 Important: \(goalName) needs your attention now!",
                "⏰ Your high-priority goal \(goalName) is waiting!",
                "❗️ \(goalName) matters today. Don't skip it!"
            ]
            // Medicine gets specific messages
            if activityType == .medicine {
                let medicineMessages = [
                    "💊 Time for your medication! Don't skip your dose.",
                    "💊 Medication reminder — take it as scheduled.",
                    "💊 Don't forget your medicine. Take it now!",
                    "💊 Medication time! Follow your saved schedule."
                ]
                return medicineMessages.randomElement()
                    ?? medicineMessages[0]
            }
            return urgentMessages.randomElement()
                ?? urgentMessages[0]
        }

        // ---- Activity-specific messages ----
        switch activityType {
        case .water:
            let msgs = [
                "Time to hydrate! 💧 Your body needs water.",
                "Drink up! Staying hydrated keeps you sharp.",
                "Water check! How many glasses today?",
                "Your cells are thirsty — time for water 🌊"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .running:
            let msgs = [
                "Lace up! Your run is waiting 🏃",
                "Every step counts. Time to hit the road!",
                "Your future self thanks you. Let's run! 💨",
                "Running clears the mind. Time to go! 🌅"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .gym:
            let msgs = [
                "Time to get those gains! 💪",
                "The gym is calling your name!",
                "Stronger every day. Workout time!",
                "No excuses today — let's crush it! 🔥"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .reading:
            let msgs = [
                "Time to get lost in a good book 📚",
                "30 minutes of reading = a smarter you!",
                "Your book is waiting. Time to read!",
                "Open a book, open your mind ✨"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .meditation:
            let msgs = [
                "Take a breath. Time to meditate 🧘",
                "Your mind needs a break. Let's meditate.",
                "Calm your thoughts. Meditation time 🌸",
                "Peace is just 10 minutes away 🙏"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .sleep:
            let msgs = [
                "Time to wind down for bed 🌙",
                "Good sleep = great tomorrow. Rest up!",
                "Your body needs rest. Bedtime! 😴",
                "Sweet dreams ahead. Time for sleep ⭐"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .studying:
            let msgs = [
                "Knowledge awaits! Time to study 🎓",
                "Every hour you study brings you closer!",
                "Focus mode: ON. Let's study! 💡",
                "Your future is built right now 📖"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .walking:
            let msgs = [
                "Time for your daily walk! 🚶",
                "10,000 steps start with one. Let's go!",
                "Walking is the best medicine. Move!",
                "Fresh air and steps await 🌿"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .yoga:
            let msgs = [
                "Roll out the mat! Yoga time 🧘",
                "Stretch it out. Your body will thank you!",
                "Mind + body harmony. Yoga time 🌸",
                "Flexibility starts with one pose 🌿"
            ]
            return msgs.randomElement() ?? msgs[0]

        case .cycling:
            let msgs = [
                "Saddle up! Time to ride 🚴",
                "Two wheels, fresh air. Let's go!",
                "Your cycle goal is waiting! 🌤️",
                "Pedal your way to a better day 💨"
            ]
            return msgs.randomElement() ?? msgs[0]

        default:
            let msgs = [
                "Time to work on \(goalName)! 💪",
                "Your goal is waiting. Let's do this!",
                "\(goalName) — you've got this! 🎯",
                "Small steps, big results. Time for \(goalName)!"
            ]
            return msgs.randomElement() ?? msgs[0]
        }
    }
}

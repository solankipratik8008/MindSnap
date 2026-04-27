//
//  ReviewService.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//

// ============================================================
// ReviewService.swift
// MindSnap — Smart App Store review prompt
//
// WHAT THIS FILE DOES:
// Smartly asks users for an App Store review at the
// right moment — when they're most likely to be happy
// with the app.
//
// WHEN WE ASK:
//   After 3rd journal entry saved → user is engaged
//   After 7 day streak → user loves the app
//   After 3 days of use → user has formed a habit
//
// HOW IT WORKS:
// Apple's SKStoreReviewController handles everything:
//   - Shows the native star rating popup
//   - Submits review directly to App Store
//   - Apple controls max frequency (3 times per year)
//   - We just call requestReview() at the right moment
//
// WHY THIS IS SAFE:
// Apple won't always show the prompt — they decide
// when it's appropriate. We just request it and
// Apple does the rest. No risk of annoying users.
// ============================================================


import StoreKit
import SwiftUI
import UIKit
final class ReviewService {

    // --------------------------------------------------------
    // Shared instance — use this everywhere
    // --------------------------------------------------------
    static let shared = ReviewService()
    private init() {}

    // --------------------------------------------------------
    // UserDefaults keys
    // --------------------------------------------------------
    private let entriesCountKey = "reviewEntriesCount"
    private let goalsCountKey = "reviewGoalsCreatedCount"
    private let firstLaunchKey = "reviewFirstLaunchDate"
    private let hasRequestedKey = "reviewHasRequested"
    private let lastRequestKey = "reviewLastRequestDate"

    // Replace YOUR_APP_ID after the app is live on the App Store.
    static let appStoreReviewURL =
        "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review"

    // --------------------------------------------------------
    // trackEntryCreated()
    //
    // Call this every time user saves a new journal entry.
    // After 3rd entry → ask for review.
    //
    // WHY 3rd ENTRY:
    // User has written 3 entries which means:
    //   - They understand the app
    //   - They like it enough to keep using it
    //   - They're in a positive mindset (just journaled)
    // This is the BEST moment to ask for a review.
    // --------------------------------------------------------
    func trackEntryCreated() {
        // Increment entry count
        let count = UserDefaults.standard.integer(
            forKey: entriesCountKey
        ) + 1
        UserDefaults.standard.set(count, forKey: entriesCountKey)

        // Record first launch date if not set
        if UserDefaults.standard.object(forKey: firstLaunchKey) == nil {
            UserDefaults.standard.set(
                Date(),
                forKey: firstLaunchKey
            )
        }

        // Ask after 3rd entry
        if count == 3 {
            requestReview()
        }
    }

    // --------------------------------------------------------
    // trackStreakMilestone(streak:)
    //
    // Call this when user hits a streak milestone.
    // After 7 day streak → ask for review.
    //
    // WHY 7 DAY STREAK:
    // User has journaled 7 days in a row which means:
    //   - They LOVE the app
    //   - They've built a habit
    //   - They will almost certainly give 5 stars
    // --------------------------------------------------------
    func trackStreakMilestone(streak: Int) {
        if streak == 7 {
            requestReview()
        }
    }

    func trackGoalCreated() {
        let count = UserDefaults.standard.integer(
            forKey: goalsCountKey
        ) + 1
        UserDefaults.standard.set(count, forKey: goalsCountKey)

        if UserDefaults.standard.object(forKey: firstLaunchKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchKey)
        }

        if count == 5 {
            requestReview()
        }
    }

    // --------------------------------------------------------
    // requestReview()
    //
    // The actual review request.
    //
    // Uses Apple's native SKStoreReviewController which:
    //   - Shows the official iOS star rating popup
    //   - Submits directly to App Store
    //   - Apple limits this to 3 times per year max
    //   - Won't show if user already rated this version
    //
    // We add our own cooldown (30 days) on top of Apple's
    // limits to be extra respectful of user experience.
    // --------------------------------------------------------
    // ✅ REPLACE WITH — uses new iOS 18 API
    func requestReview() {
        guard !UserDefaults.standard.bool(forKey: hasRequestedKey) else {
            return
        }

        // Check 30 day cooldown
        if let lastRequest = UserDefaults.standard.object(
            forKey: lastRequestKey
        ) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents(
                [.day],
                from: lastRequest,
                to: Date()
            ).day ?? 0
            guard daysSinceLastRequest >= 30 else { return }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // ---- NEW API for iOS 16+ ----
            // @Environment(\.requestReview) is the modern way
            // but since we're in a service class we use
            // the scene-based approach with updated API
            Task { @MainActor in
                guard let scene = UIApplication.shared
                    .connectedScenes
                    .first(where: {
                        $0.activationState == .foregroundActive
                    }) as? UIWindowScene else { return }

                AppStore.requestReview(in: scene)
            }

            UserDefaults.standard.set(
                Date(),
                forKey: self.lastRequestKey
            )
            UserDefaults.standard.set(
                true,
                forKey: self.hasRequestedKey
            )
        }
    }
}

//
//  CoachMarkView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//
// ============================================================
// CoachMarkView.swift
// MindSnap — UPDATED COACH MARKS
//
// WHAT CHANGED:
// 1. Updated steps to include Goals tab
// 2. Added step for pin feature
// 3. Added step for mood calendar
// 4. Added step for goal points system
// 5. Added step for multiple reminders
// 6. Better animations between steps
// 7. Fixed dismiss bug from previous version
// ============================================================

import SwiftUI

struct CoachMarkStep {
    let title: String
    let description: String
    let emoji: String
    let position: CoachMarkPosition
    let accentColor: Color
}

enum CoachMarkPosition {
    case top
    case bottom
    case center
}

struct CoachMarkView: View {

    @Binding var isShowingTutorial: Bool

    @State private var currentStep = 0
    @State private var animateIn = false
    @State private var isCompleting = false

    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // MARK: - Tutorial Steps
    //
    // Updated to cover all features including Goals
    // --------------------------------------------------------
    private let steps: [CoachMarkStep] = [

        // ---- Step 1: Welcome ----
        CoachMarkStep(
            title: "Welcome to MindSnap! 👋",
            description: "Your personal on-device smart journal and habit tracker. Let's take a quick tour of everything MindSnap can do for you!",
            emoji: "🧠",
            position: .center,
            accentColor: .purple
        ),

        // ---- Step 2: Journal ----
        CoachMarkStep(
            title: "Write Your First Entry ✍️",
            description: "Tap 'New Entry' to start journaling. Our on-device intelligence automatically detects your mood as you type — no internet needed!",
            emoji: "📝",
            position: .bottom,
            accentColor: .purple
        ),

        // ---- Step 3: Mood detection ----
        CoachMarkStep(
            title: "Smart Mood Detection 🧘",
            description: "As you write, MindSnap analyses your words and shows your mood in real time. You can also override the detected mood or use the mood check-in wheel.",
            emoji: "😊",
            position: .bottom,
            accentColor: .orange
        ),

        // ---- Step 4: Pin entries ----
        CoachMarkStep(
            title: "Pin Important Entries 📌",
            description: "Swipe RIGHT on any journal entry to pin it to the top of your list. Perfect for capturing your most meaningful moments where you can always find them.",
            emoji: "📌",
            position: .center,
            accentColor: .orange
        ),

        // ---- Step 5: Search ----
        CoachMarkStep(
            title: "Search Your Journal 🔍",
            description: "Use the search bar at the top to instantly find any entry by keywords, mood, or tags. Your entire journal history is always at your fingertips.",
            emoji: "🔍",
            position: .bottom,
            accentColor: .blue
        ),

        // ---- Step 6: Insights ----
        CoachMarkStep(
            title: "Discover Your Mood Patterns 📊",
            description: "Tap 'Insights' to see beautiful mood charts, weekly trends, and a calendar view showing how you've felt every day. Understand yourself better over time.",
            emoji: "📈",
            position: .top,
            accentColor: .blue
        ),

        // ---- Step 7: Calendar ----
        CoachMarkStep(
            title: "Mood Calendar 🗓️",
            description: "In Insights, scroll down to see your mood calendar. Each day shows a coloured emoji based on how you felt. Tap any day to read what you wrote!",
            emoji: "🗓️",
            position: .top,
            accentColor: .teal
        ),

        // ---- Step 8: Goals ----
        CoachMarkStep(
            title: "Set Daily Goals 🎯",
            description: "Tap the 'Goals' tab to set daily habits like running, reading, or drinking water. Track your progress and earn points for every goal you complete!",
            emoji: "🎯",
            position: .top,
            accentColor: .green
        ),

        // ---- Step 9: Points ----
        CoachMarkStep(
            title: "Earn Points & Level Up ⭐",
            description: "Complete goals to earn points. Reach milestones to level up from Beginner all the way to Champion 🏆. Complete ALL goals today for a bonus +25 points!",
            emoji: "⭐",
            position: .center,
            accentColor: .yellow
        ),

        // ---- Step 10: Reminders ----
        CoachMarkStep(
            title: "Smart Goal Reminders 🔔",
            description: "Set multiple daily reminders for each goal. Water goals can remind you at 9am, 12pm, 3pm and 6pm. Each activity gets smart, motivating notifications.",
            emoji: "🔔",
            position: .center,
            accentColor: .red
        ),

        // ---- Step 11: Settings ----
        CoachMarkStep(
            title: "Customise Your Experience ⚙️",
            description: "In Settings you can enable Face ID lock, set a daily journal reminder, switch between light and dark mode, and view your privacy policy.",
            emoji: "⚙️",
            position: .top,
            accentColor: .gray
        ),

        // ---- Step 12: Privacy ----
        CoachMarkStep(
            title: "100% Private by Design 🔒",
            description: "Everything stays on your device. No accounts, no cloud, no ads. Your journal and goals are encrypted and never leave your iPhone. You're in control.",
            emoji: "🔒",
            position: .center,
            accentColor: .green
        )
    ]

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {

            // ---- Dark overlay ----
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .onTapGesture {
                    advanceStep()
                }

            // ---- Tutorial card ----
            VStack(spacing: 0) {

                if steps[currentStep].position == .bottom ||
                   steps[currentStep].position == .center {
                    Spacer()
                }

                tutorialCard
                    .padding(.horizontal, 22)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 40)
                    .animation(
                        .spring(duration: 0.5, bounce: 0.3),
                        value: animateIn
                    )
                    // Prevent tap-through
                    .onTapGesture { }

                if steps[currentStep].position == .top ||
                   steps[currentStep].position == .center {
                    Spacer()
                }

                if steps[currentStep].position == .bottom {
                    Spacer().frame(height: 80)
                }
                if steps[currentStep].position == .top {
                    Spacer().frame(height: 80)
                }
            }
        }
        .onAppear {
            withAnimation(
                .spring(duration: 0.5, bounce: 0.3)
                .delay(0.3)
            ) {
                animateIn = true
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Tutorial Card
    // --------------------------------------------------------
    private var tutorialCard: some View {
        VStack(spacing: 20) {

            // ---- Progress dots ----
            progressDots

            // ---- Emoji ----
            ZStack {
                Circle()
                    .fill(
                        steps[currentStep].accentColor.opacity(
                            colorScheme == .dark ? 0.2 : 0.12
                        )
                    )
                    .frame(width: 88, height: 88)

                Text(steps[currentStep].emoji)
                    .font(.system(size: 48))
                    .id("emoji\(currentStep)")
                    .transition(
                        .scale.combined(with: .opacity)
                    )
                    .animation(
                        .spring(duration: 0.4, bounce: 0.3),
                        value: currentStep
                    )
            }

            // ---- Content ----
            VStack(spacing: 10) {
                Text(steps[currentStep].title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .id("title\(currentStep)")
                    .transition(.opacity)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: currentStep
                    )

                Text(steps[currentStep].description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .id("desc\(currentStep)")
                    .transition(.opacity)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: currentStep
                    )
            }
            .padding(.horizontal, 4)

            // ---- Step counter ----
            Text("Step \(currentStep + 1) of \(steps.count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // ---- Buttons ----
            VStack(spacing: 10) {

                // Got it / Finish button
                Button {
                    advanceStep()
                } label: {
                    HStack(spacing: 8) {
                        if isLastStep {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                        }
                        Text(isLastStep ? "Start Using MindSnap! 🚀" : "Got it →")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
               
                    .background(
                        Group {
                            if isCompleting {
                                Capsule()
                                    .fill(Color.gray)
                            } else {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                steps[currentStep].accentColor,
                                                steps[currentStep].accentColor
                                                    .opacity(0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    )
                }
                .disabled(isCompleting)

                // Skip button
                if !isLastStep {
                    Button("Skip Tutorial") {
                        completeTutorial()
                    }
                    .font(.subheadline)
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color.white.opacity(0.4)
                            : Color.secondary
                    )
                    .disabled(isCompleting)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    colorScheme == .dark
                        ? Color(
                            red: 0.15, green: 0.15, blue: 0.17
                          )
                        : Color.white
                )
                .shadow(
                    color: .black.opacity(
                        colorScheme == .dark ? 0.5 : 0.2
                    ),
                    radius: 28, x: 0, y: 14
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    steps[currentStep].accentColor.opacity(
                        colorScheme == .dark ? 0.25 : 0.1
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Progress Dots
    // --------------------------------------------------------
    private var progressDots: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(0..<steps.count, id: \.self) { index in

                    let isActive = index == currentStep
                    let isPast = index < currentStep

                    Capsule()
                        .fill(
                            isPast
                                ? steps[index].accentColor
                                    .opacity(0.5)
                                : isActive
                                    ? steps[currentStep].accentColor
                                    : Color.gray.opacity(0.25)
                        )
                        .frame(
                            width: isActive ? 22 : isPast ? 8 : 6,
                            height: 6
                        )
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: currentStep
                        )
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 12)
    }

    // --------------------------------------------------------
    // MARK: - Computed Properties
    // --------------------------------------------------------
    private var isLastStep: Bool {
        currentStep == steps.count - 1
    }

    // --------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------
    private func advanceStep() {
        guard !isCompleting else { return }

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        if isLastStep {
            completeTutorial()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep += 1
            }
        }
    }

    private func completeTutorial() {
        guard !isCompleting else { return }
        isCompleting = true

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isShowingTutorial = false
            }
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        CoachMarkView(
            isShowingTutorial: .constant(true)
        )
    }
}

#Preview("Dark") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        CoachMarkView(
            isShowingTutorial: .constant(true)
        )
    }
    .preferredColorScheme(.dark)
}

//
//  CoachMarkView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//

// ============================================================
// CoachMarkView.swift
// MindSnap — Premium Engaging Coach Marks
//
// SAFE UI UPDATE:
// 1. Keeps same binding: @Binding var isShowingTutorial
// 2. Keeps same completion behavior
// 3. Does not touch app data, journals, goals, CloudKit, HealthKit
// 4. Adds more engaging first-time user guidance
// 5. Matches premium black/white theme
// 6. Keeps accent colors only for meaningful feature highlights
// ============================================================

import SwiftUI

struct CoachMarkStep {
    let title: String
    let description: String
    let emoji: String
    let position: CoachMarkPosition
    let accentColor: Color
    let bullets: [String]
    let actionHint: String
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
    @State private var emojiPulse = false

    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var softBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.07)
        : Color.black.opacity(0.045)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.66)
        : Color.black.opacity(0.54)
    }

    private var tertiaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.38)
        : Color.black.opacity(0.34)
    }

    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.07)
    }

    private var primaryButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var primaryButtonText: Color {
        colorScheme == .dark ? .black : .white
    }

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.18)
    }

    private var current: CoachMarkStep {
        steps[currentStep]
    }

    // --------------------------------------------------------
    // MARK: - Tutorial Steps
    // --------------------------------------------------------
    private let steps: [CoachMarkStep] = [

        CoachMarkStep(
            title: "Welcome to MindSnap",
            description: "A private journal and goal tracker designed to help you understand your mood, build routines, and stay consistent.",
            emoji: "🧠",
            position: .center,
            accentColor: .purple,
            bullets: [
                "Write private journal entries",
                "Track mood patterns",
                "Build daily goals"
            ],
            actionHint: "Let’s take a quick tour"
        ),

        CoachMarkStep(
            title: "Write Your Thoughts",
            description: "Use New Entry to write anything on your mind. Your journal is your private space to reflect without pressure.",
            emoji: "✍️",
            position: .bottom,
            accentColor: .blue,
            bullets: [
                "Use the rich journal editor",
                "Add tags and reflections",
                "Focus mode helps you write calmly"
            ],
            actionHint: "Try writing a short entry today"
        ),

        CoachMarkStep(
            title: "Smart Mood Detection",
            description: "MindSnap can detect your mood while you write and show helpful emotional feedback, while still letting you choose your own mood.",
            emoji: "😊",
            position: .bottom,
            accentColor: .orange,
            bullets: [
                "Mood updates while typing",
                "Manual mood override available",
                "Mood check-in gives more control"
            ],
            actionHint: "Your mood is yours to adjust"
        ),

        CoachMarkStep(
            title: "Pin What Matters",
            description: "Important memories should not get lost. Pin meaningful entries so they stay easy to find later.",
            emoji: "📌",
            position: .center,
            accentColor: .orange,
            bullets: [
                "Swipe right to pin entries",
                "Pinned entries stay near the top",
                "Great for important moments"
            ],
            actionHint: "Pin entries worth remembering"
        ),

        CoachMarkStep(
            title: "Search Your Journal",
            description: "Your journal becomes more useful over time. Search helps you quickly find old thoughts, emotions, tags, or moments.",
            emoji: "🔍",
            position: .bottom,
            accentColor: .blue,
            bullets: [
                "Search by keyword",
                "Find entries faster",
                "Great when your journal grows"
            ],
            actionHint: "Search is your memory shortcut"
        ),

        CoachMarkStep(
            title: "Understand Your Patterns",
            description: "Insights turns your entries into mood trends, charts, recent patterns, and a calendar view so you can understand yourself better.",
            emoji: "📊",
            position: .top,
            accentColor: .teal,
            bullets: [
                "Mood trend chart",
                "Mood breakdown",
                "Recent emotional patterns"
            ],
            actionHint: "Write regularly to unlock better insights"
        ),

        CoachMarkStep(
            title: "Mood Calendar",
            description: "Your calendar shows how you felt across days. Tap a day to revisit what you wrote and understand what shaped your mood.",
            emoji: "🗓️",
            position: .top,
            accentColor: .teal,
            bullets: [
                "Emoji mood history",
                "Tap days to view entries",
                "Spot good and difficult weeks"
            ],
            actionHint: "Patterns become clearer with time"
        ),

        CoachMarkStep(
            title: "Build Daily Goals",
            description: "Goals help you turn small actions into momentum. Track habits like walking, reading, water, sleep, workouts, and more.",
            emoji: "🎯",
            position: .top,
            accentColor: .green,
            bullets: [
                "Checkbox and progress goals",
                "Daily or custom repeat schedules",
                "Quick add useful goal presets"
            ],
            actionHint: "Start with one easy goal"
        ),

        CoachMarkStep(
            title: "Earn Points & Level Up",
            description: "Completing goals gives points, streaks, level progress, and small celebrations to make consistency feel rewarding.",
            emoji: "⭐",
            position: .center,
            accentColor: .yellow,
            bullets: [
                "Earn points for completed goals",
                "Build streaks",
                "Finish all goals for bonus points"
            ],
            actionHint: "Small wins stack up"
        ),

        CoachMarkStep(
            title: "Use Smart Reminders",
            description: "Add reminders for goals or journaling so MindSnap can gently bring you back at the right time.",
            emoji: "🔔",
            position: .center,
            accentColor: .red,
            bullets: [
                "Daily journal reminder",
                "Multiple goal reminders",
                "Medicine and routine reminders"
            ],
            actionHint: "Reminders keep habits alive"
        ),

        CoachMarkStep(
            title: "Protect Your Privacy",
            description: "MindSnap is built for personal reflection. You can use Face ID or Touch ID, control Health access, and review privacy settings anytime.",
            emoji: "🔒",
            position: .center,
            accentColor: .green,
            bullets: [
                "Face ID / Touch ID lock",
                "Optional Apple Health sync",
                "No third-party tracking"
            ],
            actionHint: "You stay in control"
        ),

        CoachMarkStep(
            title: "Make It Yours",
            description: "Settings lets you customize appearance, privacy, reminders, widgets, Health sync, and support resources.",
            emoji: "⚙️",
            position: .top,
            accentColor: .gray,
            bullets: [
                "Light, dark, or system appearance",
                "Widget goal selection",
                "Privacy policy and support links"
            ],
            actionHint: "You are ready to use MindSnap"
        )
    ]

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {

            Color.black.opacity(colorScheme == .dark ? 0.82 : 0.72)
                .ignoresSafeArea()
                .onTapGesture {
                    advanceStep()
                }

            VStack(spacing: 0) {

                if current.position == .bottom || current.position == .center {
                    Spacer()
                }

                tutorialCard
                    .padding(.horizontal, 22)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 34)
                    .scaleEffect(animateIn ? 1 : 0.96)
                    .animation(
                        .spring(duration: 0.50, bounce: 0.30),
                        value: animateIn
                    )
                    .onTapGesture { }

                if current.position == .top || current.position == .center {
                    Spacer()
                }

                if current.position == .bottom {
                    Spacer().frame(height: 76)
                }

                if current.position == .top {
                    Spacer().frame(height: 76)
                }
            }
        }
        .onAppear {
            withAnimation(
                .spring(duration: 0.50, bounce: 0.30)
                .delay(0.20)
            ) {
                animateIn = true
            }

            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                emojiPulse = true
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Tutorial Card
    // --------------------------------------------------------
    private var tutorialCard: some View {
        VStack(spacing: 18) {

            topProgressArea

            emojiSection

            contentSection

            bulletSection

            stepCounter

            actionButtons
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            current.accentColor.opacity(
                                colorScheme == .dark ? 0.24 : 0.14
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(
                    color: shadowColor,
                    radius: 26,
                    x: 0,
                    y: 14
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Top Progress Area
    // --------------------------------------------------------
    private var topProgressArea: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Quick Tour")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(secondaryText)
                    .tracking(0.8)

                Spacer()

                Text("\(currentStep + 1)/\(steps.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(softBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }

            progressBar
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(softBackground)
                    .frame(height: 8)

                Capsule()
                    .fill(current.accentColor)
                    .frame(
                        width: geo.size.width *
                        CGFloat(currentStep + 1) /
                        CGFloat(steps.count),
                        height: 8
                    )
                    .animation(
                        .spring(duration: 0.35),
                        value: currentStep
                    )
            }
        }
        .frame(height: 8)
    }

    // --------------------------------------------------------
    // MARK: - Emoji
    // --------------------------------------------------------
    private var emojiSection: some View {
        ZStack {
            Circle()
                .fill(
                    current.accentColor.opacity(
                        colorScheme == .dark ? 0.16 : 0.09
                    )
                )
                .frame(width: 98, height: 98)
                .scaleEffect(emojiPulse ? 1.08 : 1.0)

            Circle()
                .fill(softBackground)
                .frame(width: 74, height: 74)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )

            Text(current.emoji)
                .font(.system(size: 42))
                .id("emoji-\(currentStep)")
                .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(duration: 0.35, bounce: 0.28), value: currentStep)
    }

    // --------------------------------------------------------
    // MARK: - Content
    // --------------------------------------------------------
    private var contentSection: some View {
        VStack(spacing: 9) {
            Text(current.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .id("title-\(currentStep)")
                .transition(.opacity)

            Text(current.description)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(4)
                .minimumScaleFactor(0.88)
                .fixedSize(horizontal: false, vertical: true)
                .id("desc-\(currentStep)")
                .transition(.opacity)
        }
        .padding(.horizontal, 2)
        .animation(.easeInOut(duration: 0.22), value: currentStep)
    }

    // --------------------------------------------------------
    // MARK: - Bullets
    // --------------------------------------------------------
    private var bulletSection: some View {
        VStack(spacing: 8) {
            ForEach(current.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(current.accentColor)
                        .padding(.top, 1)

                    Text(bullet)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(softBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Step Counter / Hint
    // --------------------------------------------------------
    private var stepCounter: some View {
        Text(current.actionHint)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(current.accentColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
    }

    // --------------------------------------------------------
    // MARK: - Buttons
    // --------------------------------------------------------
    private var actionButtons: some View {
        VStack(spacing: 10) {

            Button {
                advanceStep()
            } label: {
                HStack(spacing: 8) {
                    if isLastStep {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                    }

                    Text(isLastStep ? "Start Using MindSnap" : "Continue")
                        .font(.headline)
                        .fontWeight(.bold)

                    if !isLastStep {
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundStyle(primaryButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            isCompleting
                            ? Color.gray
                            : primaryButtonBackground
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.14)
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isCompleting)

            HStack {
                if currentStep > 0 {
                    Button {
                        previousStep()
                    } label: {
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(secondaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCompleting)
                }

                Spacer()

                if !isLastStep {
                    Button {
                        completeTutorial()
                    } label: {
                        Text("Skip Tour")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCompleting)
                }
            }
            .padding(.horizontal, 6)
        }
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
            withAnimation(.easeInOut(duration: 0.22)) {
                currentStep += 1
            }
        }
    }

    private func previousStep() {
        guard !isCompleting else { return }
        guard currentStep > 0 else { return }

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        withAnimation(.easeInOut(duration: 0.22)) {
            currentStep -= 1
        }
    }

    private func completeTutorial() {
        guard !isCompleting else { return }

        isCompleting = true

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeInOut(duration: 0.35)) {
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
        Color(red: 0.96, green: 0.96, blue: 0.97)
            .ignoresSafeArea()

        CoachMarkView(
            isShowingTutorial: .constant(true)
        )
    }
}

#Preview("Dark") {
    ZStack {
        Color(red: 0.03, green: 0.03, blue: 0.035)
            .ignoresSafeArea()

        CoachMarkView(
            isShowingTutorial: .constant(true)
        )
    }
    .preferredColorScheme(.dark)
}

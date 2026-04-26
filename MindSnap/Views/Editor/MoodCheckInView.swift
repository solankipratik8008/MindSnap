//
//  MoodCheckInView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-22.
//

// ============================================================
// MoodCheckInView.swift
// MindSnap — Beautiful mood check-in popup
//
// WHAT THIS FILE DOES:
// Shows a beautiful animated mood selector sheet when user
// opens a new entry. This gives the user a moment to pause
// and consciously check in with their emotions before writing.
//
// EXPERIENCE FLOW:
// 1. User taps "New Entry"
// 2. This sheet slides up with a beautiful animation
// 3. User sees 5 mood options in a circular layout
// 4. Tapping a mood:
//    - Scales up with spring animation
//    - Background gradient shifts to mood color
//    - Haptic feedback fires
//    - Mood name and description appear
// 5. User taps "Start Writing" → sheet dismisses
// 6. Selected mood is passed back to EntryEditorView
//
// MVVM ROLE: View layer
//            Receives a callback closure that passes the
//            selected mood back to EntryEditorView.
// ============================================================

import SwiftUI

struct MoodCheckInView: View {

    // --------------------------------------------------------
    // onMoodSelected — Callback when user picks a mood
    //
    // When user taps "Start Writing", we call this closure
    // with the selected mood. EntryEditorView uses this to
    // pre-set the mood before AI analysis runs.
    // --------------------------------------------------------
    let onMoodSelected: (MoodType) -> Void

    // --------------------------------------------------------
    // @Environment(\.dismiss)
    // Dismisses the sheet when user taps "Start Writing"
    // --------------------------------------------------------
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // selectedMood — Currently highlighted mood
    //
    // Starts as .neutral and changes when user taps a mood.
    // Drives ALL the animations on this screen.
    // --------------------------------------------------------
    @State private var selectedMood: MoodType = .neutral

    // --------------------------------------------------------
    // animateIn — Controls entrance animations
    //
    // Set to true in .onAppear to trigger the staggered
    // entrance animation of each mood bubble.
    // --------------------------------------------------------
    @State private var animateIn = false

    // --------------------------------------------------------
    // pulsing — Controls the selected mood pulse animation
    // --------------------------------------------------------
    @State private var pulsing = false

    // --------------------------------------------------------
    // Mood descriptions — shown below the wheel
    //
    // Each mood has a short empathetic description that
    // helps users identify with the emotion.
    // --------------------------------------------------------
    private var moodDescription: String {
        switch selectedMood {
        case .happy:
            return "Something good happened! ✨\nCapture this feeling."
        case .calm:
            return "You're in a peaceful state 🌿\nPerfect time to reflect."
        case .neutral:
            return "Just checking in 📝\nHow was your day?"
        case .anxious:
            return "Feeling some tension 💭\nWriting can help you process it."
        case .sad:
            return "Having a tough moment 💙\nYour feelings are valid."
        }
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {

            // ---- Animated background ----
            // Smoothly shifts color based on selected mood
            animatedBackground

            VStack(spacing: 0) {

                // ---- Top handle bar ----
                // Visual indicator that this is a sheet
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                // ---- Header ----
                headerSection

                Spacer()

                // ---- Mood Wheel ----
                moodWheelSection

                Spacer()

                // ---- Mood Description ----
                moodDescriptionSection

                Spacer()

                // ---- Start Writing Button ----
                startWritingButton
                    .padding(.bottom, 40)
            }
        }
        // Make sheet taller for better visual impact
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            // Trigger entrance animations after brief delay
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) {
                animateIn = true
            }
            // Start pulse animation
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Subviews
    // --------------------------------------------------------

    // --------------------------------------------------------
    // animatedBackground
    //
    // Full screen gradient that smoothly transitions between
    // mood colors as the user taps different moods.
    // This is what makes the UI feel truly premium.
    // --------------------------------------------------------
    private var animatedBackground: some View {
        ZStack {
            // Base system background
            Color(.systemBackground)
                .ignoresSafeArea()

            // Mood color overlay — shifts smoothly
            RadialGradient(
                colors: [
                    selectedMood.color.opacity(
                        colorScheme == .dark ? 0.4 : 0.2
                    ),
                    selectedMood.color.opacity(
                        colorScheme == .dark ? 0.15 : 0.05
                    ),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            // Animate the gradient change smoothly
            .animation(.easeInOut(duration: 0.4), value: selectedMood)
        }
    }

    // --------------------------------------------------------
    // headerSection
    //
    // Title and subtitle with staggered entrance animation
    // --------------------------------------------------------
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("How are you feeling")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text("right now?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(selectedMood.color)
                // Animate color change when mood changes
                .animation(.easeInOut(duration: 0.3), value: selectedMood)

            Text("Tap to select your mood")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        // Entrance animation
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
        .animation(.spring(duration: 0.5).delay(0.1), value: animateIn)
    }

    // --------------------------------------------------------
    // moodWheelSection
    //
    // The star of the show — circular mood selector.
    //
    // Layout:
    //         😊          ← top center
    //      😌     😰       ← middle row
    //      😢     😐       ← bottom row
    //
    // Each bubble:
    //   - Large emoji in colored circle
    //   - Selected = scale up + glow ring + bounce
    //   - Unselected = smaller, muted
    //   - Entrance = staggered scale animation
    // --------------------------------------------------------
    private var moodWheelSection: some View {
        VStack(spacing: 20) {

            // ---- Top: Happy (center) ----
            HStack {
                Spacer()
                moodBubble(mood: .happy, delay: 0.0)
                Spacer()
            }

            // ---- Middle row: Calm + Anxious ----
            HStack(spacing: 48) {
                moodBubble(mood: .calm, delay: 0.1)
                // Center connecting lines (decorative)
                centerDecoration
                moodBubble(mood: .anxious, delay: 0.1)
            }

            // ---- Bottom row: Sad + Neutral ----
            HStack(spacing: 48) {
                moodBubble(mood: .sad, delay: 0.2)
                // Empty space to match middle row
                Color.clear
                    .frame(width: 60, height: 60)
                moodBubble(mood: .neutral, delay: 0.2)
            }
        }
        .padding(.horizontal, 40)
    }

    // --------------------------------------------------------
    // moodBubble(mood:delay:)
    //
    // A single tappable mood bubble in the wheel.
    //
    // Visual states:
    //   Selected:   large (110pt), colored bg, glow ring,
    //               emoji scale 1.2, spring bounce on tap
    //   Unselected: normal (80pt), muted bg, no ring
    //
    // Parameters:
    //   mood  — which MoodType this bubble represents
    //   delay — entrance animation delay (staggered effect)
    // --------------------------------------------------------
    private func moodBubble(mood: MoodType, delay: Double) -> some View {
        let isSelected = selectedMood == mood
        let size: CGFloat = isSelected ? 110 : 80

        return Button {
            selectMood(mood)
        } label: {
            ZStack {
                // ---- Outer glow ring (selected only) ----
                if isSelected {
                    Circle()
                        .stroke(mood.color.opacity(0.3), lineWidth: 3)
                        .frame(width: size + 20, height: size + 20)
                        .scaleEffect(pulsing ? 1.08 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                            value: pulsing
                        )
                }

                // ---- Background circle ----
                Circle()
                    .fill(
                        isSelected
                            ? mood.color.opacity(
                                colorScheme == .dark ? 0.35 : 0.2
                              )
                            : Color(.systemGray5).opacity(0.8)
                    )
                    .frame(width: size, height: size)
                    // Colored border when selected
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected
                                    ? mood.color.opacity(0.6)
                                    : Color.clear,
                                lineWidth: 2.5
                            )
                    )
                    // Shadow glow when selected
                    .shadow(
                        color: isSelected
                            ? mood.color.opacity(0.4)
                            : Color.clear,
                        radius: isSelected ? 16 : 0
                    )

                // ---- Emoji ----
                Text(mood.emoji)
                    .font(.system(size: isSelected ? 46 : 34))
                    // Slight scale up on the emoji itself
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
        }
        // Spring animation for size/scale changes
        .animation(
            .spring(duration: 0.4, bounce: 0.5),
            value: isSelected
        )
        // Entrance animation — scale from 0
        .scaleEffect(animateIn ? 1.0 : 0.0)
        .animation(
            .spring(duration: 0.5, bounce: 0.4).delay(delay + 0.2),
            value: animateIn
        )
    }

    // --------------------------------------------------------
    // centerDecoration
    //
    // Decorative element in the center of the wheel.
    // Shows a small pulsing circle that matches the mood color.
    // --------------------------------------------------------
    private var centerDecoration: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(
                    selectedMood.color.opacity(0.3),
                    lineWidth: 1.5
                )
                .frame(width: 50, height: 50)
                .scaleEffect(pulsing ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: pulsing
                )

            // Inner filled circle
            Circle()
                .fill(selectedMood.color.opacity(
                    colorScheme == .dark ? 0.3 : 0.15
                ))
                .frame(width: 36, height: 36)

            // Mood initial letter or small emoji
            Text(selectedMood.emoji)
                .font(.system(size: 16))
        }
        .animation(.easeInOut(duration: 0.3), value: selectedMood)
    }

    // --------------------------------------------------------
    // moodDescriptionSection
    //
    // Shows the mood name and empathetic description.
    // Animates smoothly when mood changes.
    // --------------------------------------------------------
    private var moodDescriptionSection: some View {
        VStack(spacing: 8) {
            // Mood name badge
            HStack(spacing: 8) {
                Text(selectedMood.emoji)
                    .font(.title3)
                Text("Feeling \(selectedMood.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedMood.color)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(selectedMood.color.opacity(
                        colorScheme == .dark ? 0.2 : 0.1
                    ))
            )
            .animation(.easeInOut(duration: 0.3), value: selectedMood)

            // Empathetic description
            Text(moodDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)
                // Fade in/out when mood changes
                .id(selectedMood) // Forces re-render on mood change
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.25), value: selectedMood)
        }
        // Entrance animation
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.4), value: animateIn)
    }

    // --------------------------------------------------------
    // startWritingButton
    //
    // The CTA button that dismisses the sheet and starts
    // the journal entry with the selected mood.
    // --------------------------------------------------------
    private var startWritingButton: some View {
        VStack(spacing: 12) {
            Button {
                // Pass selected mood back to EntryEditorView
                onMoodSelected(selectedMood)
                // Dismiss the sheet
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Text("Start Writing")
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(selectedMood.color)
                        // Gradient for premium look
                        .overlay(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
                .shadow(
                    color: selectedMood.color.opacity(0.5),
                    radius: 12, x: 0, y: 6
                )
                // Animate button color when mood changes
                .animation(.easeInOut(duration: 0.3), value: selectedMood)
            }
            .padding(.horizontal, 32)

            // Skip option — goes straight to writing
            // with neutral mood
            Button("Skip mood check-in") {
                onMoodSelected(.neutral)
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        // Entrance animation
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
        .animation(.spring(duration: 0.5).delay(0.5), value: animateIn)
    }

    // --------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------

    // --------------------------------------------------------
    // selectMood(_:)
    //
    // Called when user taps a mood bubble.
    // Updates selectedMood and fires haptic feedback.
    // --------------------------------------------------------
    private func selectMood(_ mood: MoodType) {
        // Only fire haptic if selecting a DIFFERENT mood
        guard mood != selectedMood else { return }

        // Update selected mood → triggers all animations
        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
            selectedMood = mood
        }

        // ---- Haptic Feedback ----
        // UIImpactFeedbackGenerator creates a physical "tap"
        // feeling on the device. .medium is noticeable but
        // not too strong.
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// ============================================================
// Preview — Both modes
// ============================================================
#Preview("Light Mode") {
    MoodCheckInView { mood in
        print("Selected: \(mood.displayName)")
    }
}

#Preview("Dark Mode") {
    MoodCheckInView { mood in
        print("Selected: \(mood.displayName)")
    }
    .preferredColorScheme(.dark)
}

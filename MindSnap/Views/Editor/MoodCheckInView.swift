//
//  MoodCheckInView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-22.
//

// ============================================================
// MoodCheckInView.swift
// MindSnap — Premium Monochrome Mood Check-In
//
// UI UPDATE:
// 1. Matches the new professional black/white MindSnap theme
// 2. Cleaner mood selector with premium cards and soft motion
// 3. Better light/dark mode support
// 4. Keeps mood colors only as meaningful emotional accents
//
// FUNCTIONALITY KEPT:
// 1. User selects mood
// 2. Haptic feedback still works
// 3. Start Writing passes selected mood back
// 4. Skip passes neutral mood back
// 5. Sheet dismiss behavior unchanged
// ============================================================

import SwiftUI

struct MoodCheckInView: View {

    let onMoodSelected: (MoodType) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedMood: MoodType = .neutral
    @State private var animateIn = false
    @State private var pulsing = false

    // --------------------------------------------------------
    // MARK: - Theme
    // --------------------------------------------------------
    private var appBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.03, green: 0.03, blue: 0.035)
        : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var innerBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.06)
        : Color.black.opacity(0.045)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.62)
        : Color.black.opacity(0.52)
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
        : Color.black.opacity(0.08)
    }

    private var moodDescription: String {
        switch selectedMood {
        case .happy:
            return "Something good happened. Capture this feeling and give yourself credit for the moment."
        case .calm:
            return "You feel steady and peaceful. This is a good time to reflect with clarity."
        case .neutral:
            return "A simple check-in is enough. Write what happened and how your day is going."
        case .anxious:
            return "There may be some tension right now. Writing can help you slow it down."
        case .sad:
            return "This may be a heavy moment. Your feelings are valid, and you can write safely here."
        }
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        ZStack {
            animatedBackground

            VStack(spacing: 0) {

                sheetHandle

                headerSection
                    .padding(.top, 8)

                Spacer(minLength: 24)

                selectedMoodHero

                Spacer(minLength: 24)

                moodGridSection

                Spacer(minLength: 20)

                moodDescriptionSection

                Spacer(minLength: 24)

                startWritingButton
                    .padding(.bottom, 34)
            }
            .padding(.horizontal, 22)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.28).delay(0.08)) {
                animateIn = true
            }

            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Background
    // --------------------------------------------------------
    private var animatedBackground: some View {
        ZStack {
            appBackground
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    selectedMood.color.opacity(colorScheme == .dark ? 0.18 : 0.10),
                    selectedMood.color.opacity(colorScheme == .dark ? 0.07 : 0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 30,
                endRadius: 420
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.35), value: selectedMood)
        }
    }

    private var sheetHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(tertiaryText.opacity(0.55))
            .frame(width: 44, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 18)
    }

    // --------------------------------------------------------
    // MARK: - Header
    // --------------------------------------------------------
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("How are you feeling?")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)

            Text("Choose a mood before you start writing.")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -18)
        .animation(.spring(duration: 0.5).delay(0.1), value: animateIn)
    }

    // --------------------------------------------------------
    // MARK: - Selected Mood Hero
    // --------------------------------------------------------
    private var selectedMoodHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(
                        selectedMood.color.opacity(colorScheme == .dark ? 0.32 : 0.22),
                        lineWidth: 10
                    )
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulsing ? 1.05 : 0.98)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                        value: pulsing
                    )

                Circle()
                    .fill(cardBackground)
                    .frame(width: 112, height: 112)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: selectedMood.color.opacity(colorScheme == .dark ? 0.10 : 0.18),
                        radius: 18,
                        x: 0,
                        y: 10
                    )

                Text(selectedMood.emoji)
                    .font(.system(size: 54))
                    .scaleEffect(pulsing ? 1.04 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                        value: pulsing
                    )
            }

            HStack(spacing: 8) {
                Text("Feeling")
                    .font(.headline)
                    .foregroundStyle(secondaryText)

                Text(selectedMood.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(selectedMood.color)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.92)
        .animation(.spring(duration: 0.55, bounce: 0.28).delay(0.18), value: animateIn)
        .animation(.easeInOut(duration: 0.25), value: selectedMood)
    }

    // --------------------------------------------------------
    // MARK: - Mood Grid
    // --------------------------------------------------------
    private var moodGridSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                moodOption(.happy, delay: 0.05)
                moodOption(.calm, delay: 0.10)
                moodOption(.neutral, delay: 0.15)
            }

            HStack(spacing: 12) {
                moodOption(.anxious, delay: 0.20)
                moodOption(.sad, delay: 0.25)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 18)
        .animation(.spring(duration: 0.55).delay(0.25), value: animateIn)
    }

    private func moodOption(_ mood: MoodType, delay: Double) -> some View {
        let isSelected = selectedMood == mood

        return Button {
            selectMood(mood)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? mood.color.opacity(colorScheme == .dark ? 0.24 : 0.14)
                            : innerBackground
                        )
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? mood.color.opacity(0.70) : borderColor,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    Text(mood.emoji)
                        .font(.system(size: isSelected ? 30 : 26))
                }

                Text(mood.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundStyle(isSelected ? mood.color : secondaryText)
                    .lineLimit(1)
            }
            .frame(width: 92, height: 96)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? selectedCardTint(for: mood) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .scaleEffect(animateIn ? 1 : 0.80)
        .opacity(animateIn ? 1 : 0)
        .animation(
            .spring(duration: 0.45, bounce: 0.32).delay(delay),
            value: animateIn
        )
        .animation(
            .spring(duration: 0.28, bounce: 0.35),
            value: isSelected
        )
    }

    private func selectedCardTint(for mood: MoodType) -> Color {
        mood.color.opacity(colorScheme == .dark ? 0.10 : 0.065)
    }

    // --------------------------------------------------------
    // MARK: - Mood Description
    // --------------------------------------------------------
    private var moodDescriptionSection: some View {
        VStack(spacing: 10) {
            Text(moodDescription)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 18)
                .id(selectedMood)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.easeInOut(duration: 0.22), value: selectedMood)
        }
        .padding(.horizontal, 4)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.38), value: animateIn)
    }

    // --------------------------------------------------------
    // MARK: - Start Writing Button
    // --------------------------------------------------------
    private var startWritingButton: some View {
        VStack(spacing: 12) {
            Button {
                onMoodSelected(selectedMood)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Text("Start Writing")
                        .font(.headline)
                        .fontWeight(.bold)

                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(primaryButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    Capsule()
                        .fill(primaryButtonBackground)
                        .overlay(
                            Capsule()
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.18)
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: colorScheme == .dark
                    ? Color.clear
                    : Color.black.opacity(0.14),
                    radius: 14,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(.plain)

            Button {
                onMoodSelected(.neutral)
                dismiss()
            } label: {
                Text("Skip mood check-in")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryText)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 24)
        .animation(.spring(duration: 0.5).delay(0.45), value: animateIn)
    }

    // --------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------
    private func selectMood(_ mood: MoodType) {
        guard mood != selectedMood else { return }

        withAnimation(.spring(duration: 0.35, bounce: 0.42)) {
            selectedMood = mood
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// ============================================================
// Preview
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

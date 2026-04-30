//
//  ReflectionPromptView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// ReflectionPromptView.swift
// MindSnap — Premium Monochrome Reflection Prompt Card
//
// UI UPDATE:
// 1. Matches the new professional black/white MindSnap theme
// 2. Cleaner card layout for light and dark mode
// 3. Mood color is kept only as a small meaningful accent
// 4. More premium selected/unselected states
//
// FUNCTIONALITY KEPT:
// 1. Receives prompt text
// 2. Receives mood
// 3. Receives selected state
// 4. Calls onTap when tapped
// 5. No data/model/save logic changed
// ============================================================

import SwiftUI

struct ReflectionPromptView: View {

    // --------------------------------------------------------
    // MARK: - Inputs
    // --------------------------------------------------------
    let prompt: String
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // --------------------------------------------------------
    // MARK: - Theme
    // --------------------------------------------------------
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var selectedBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.045)
    }

    private var iconBackground: Color {
        isSelected
        ? mood.color.opacity(colorScheme == .dark ? 0.22 : 0.14)
        : Color.black.opacity(colorScheme == .dark ? 0.0 : 0.0)
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
        ? Color.white.opacity(0.40)
        : Color.black.opacity(0.36)
    }

    private var borderColor: Color {
        if isSelected {
            return mood.color.opacity(colorScheme == .dark ? 0.42 : 0.32)
        } else {
            return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.07)
        }
    }

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(isSelected ? 0.08 : 0.05)
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {

                leadingIcon

                VStack(alignment: .leading, spacing: 6) {
                    Text(prompt)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundStyle(primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    statusText
                }

                Spacer(minLength: 8)

                trailingIcon
            }
            .padding(14)
            .background(cardShape)
            .overlay(cardBorder)
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .contentShape(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.20), value: isSelected)
    }

    // --------------------------------------------------------
    // MARK: - Subviews
    // --------------------------------------------------------
    private var leadingIcon: some View {
        ZStack {
            Circle()
                .fill(isSelected ? mood.color : selectedBackground)
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected
                            ? mood.color.opacity(0.45)
                            : borderColor,
                            lineWidth: 1
                        )
                )

            Image(
                systemName: isSelected
                ? "checkmark"
                : "quote.opening"
            )
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(
                isSelected
                ? .white
                : primaryText.opacity(0.78)
            )
        }
    }

    private var statusText: some View {
        HStack(spacing: 5) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(mood.color)

                Text("Using this prompt")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(mood.color)
            } else {
                Image(systemName: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(tertiaryText)

                Text("Tap to use this prompt")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(tertiaryText)
            }
        }
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if isSelected {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(mood.color.opacity(0.85))
                .padding(.top, 2)
        } else {
            Image(systemName: "arrow.right.circle")
                .font(.title3)
                .foregroundStyle(secondaryText)
                .padding(.top, 1)
        }
    }

    private var cardShape: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(isSelected ? selectedBackground : cardBackground)
            .shadow(
                color: shadowColor,
                radius: isSelected ? 10 : 7,
                x: 0,
                y: isSelected ? 5 : 3
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(borderColor, lineWidth: isSelected ? 1.4 : 1)
    }
}

// ============================================================
// MARK: - Previews
// ============================================================
#Preview("Light Mode") {
    ScrollView {
        VStack(spacing: 16) {

            Text("Unselected Prompts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(MoodType.allCases, id: \.self) { mood in
                ReflectionPromptView(
                    prompt: mood.reflectionPrompts[0],
                    mood: mood,
                    isSelected: false,
                    onTap: {
                        print("Tapped: \(mood.displayName) prompt")
                    }
                )
                .padding(.horizontal)
            }

            Divider()
                .padding(.vertical, 8)

            Text("Selected State")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ReflectionPromptView(
                prompt: "What made today great?",
                mood: .happy,
                isSelected: true,
                onTap: {}
            )
            .padding(.horizontal)

            ReflectionPromptView(
                prompt: "What is one thing within your control right now?",
                mood: .anxious,
                isSelected: true,
                onTap: {}
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }
    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: 16) {

            Text("Unselected Prompts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(MoodType.allCases, id: \.self) { mood in
                ReflectionPromptView(
                    prompt: mood.reflectionPrompts[0],
                    mood: mood,
                    isSelected: false,
                    onTap: {}
                )
                .padding(.horizontal)
            }

            Divider()
                .padding(.vertical, 8)

            Text("Selected State")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ReflectionPromptView(
                prompt: "What made today great?",
                mood: .happy,
                isSelected: true,
                onTap: {}
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }
    .background(Color(red: 0.03, green: 0.03, blue: 0.035))
    .preferredColorScheme(.dark)
}

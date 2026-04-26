//
//  ReflectionPromptView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// ReflectionPromptView.swift
// MindSnap — A reusable card for displaying a single prompt
//
// WHAT THIS FILE DOES:
// This is a small, reusable View that displays ONE reflection
// prompt as a beautifully styled card.
//
// It is used inside EntryEditorView's prompt section to show
// each individual prompt suggestion.
//
// MVVM ROLE: View layer
//            Pure presentation component. Receives data via
//            properties and fires a callback when tapped.
//            No logic, no ViewModel needed — too simple.
//
// WHY A SEPARATE FILE?
// Even though this is a small View, separating it means:
//   - We can reuse it in other screens later (e.g. InsightsView)
//   - EntryEditorView stays cleaner and easier to read
//   - We can update the card design in just one place
// ============================================================

import SwiftUI

struct ReflectionPromptView: View {

    // --------------------------------------------------------
    // prompt — The suggestion text to display
    //
    // Example: "What made today great?"
    // Passed in by the parent View (EntryEditorView)
    // --------------------------------------------------------
    let prompt: String

    // --------------------------------------------------------
    // mood — The mood this prompt belongs to
    //
    // Used to color-code the card to match the current mood.
    // Example: .happy prompts get a green tint
    // --------------------------------------------------------
    let mood: MoodType

    // --------------------------------------------------------
    // isSelected — Whether this prompt is currently chosen
    //
    // true  = user tapped this prompt → show selected style
    // false = normal unselected style
    // --------------------------------------------------------
    let isSelected: Bool

    // --------------------------------------------------------
    // onTap — Callback closure when user taps the card
    //
    // A closure is a block of code passed as a parameter.
    // The PARENT decides what happens when tapped.
    // This View just says "I was tapped" and lets the parent
    // handle the logic. This is called the "callback pattern."
    //
    // () -> Void means:
    //   ()   = takes no parameters
    //   Void = returns nothing
    // --------------------------------------------------------
    let onTap: () -> Void

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {

                // ---- Left Icon ----
                // Changes based on selected state
                ZStack {
                    // Circular background behind the icon
                    Circle()
                        .fill(isSelected
                              ? mood.color
                              : mood.color.opacity(0.12))
                        .frame(width: 36, height: 36)

                    // Icon inside the circle
                    Image(systemName: isSelected
                          ? "checkmark"
                          : "quote.opening")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected
                                         ? .white
                                         : mood.color)
                }

                // ---- Prompt Text ----
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt)
                        .font(.subheadline)
                        // Selected = primary color, unselected = secondary
                        .foregroundStyle(isSelected
                                         ? Color.primary
                                         : Color.secondary)
                        .multilineTextAlignment(.leading)
                        // Allow text to wrap to multiple lines
                        .fixedSize(horizontal: false, vertical: true)

                    // Small "Tap to use" hint when not selected
                    if !isSelected {
                        Text("Tap to use this prompt")
                            .font(.caption2)
                            .foregroundStyle(mood.color.opacity(0.7))
                    } else {
                        // "Selected" confirmation when chosen
                        Text("✓ Using this prompt")
                            .font(.caption2)
                            .foregroundStyle(mood.color)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                // ---- Right Arrow (only when not selected) ----
                if !isSelected {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(mood.color.opacity(0.4))
                        .font(.title3)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? mood.color.opacity(0.08)
                          : Color(.systemBackground))
                    // Shadow lifts the card off the background
                    .shadow(
                        color: Color.black.opacity(isSelected ? 0.08 : 0.05),
                        radius: isSelected ? 6 : 4,
                        x: 0,
                        y: 2
                    )
            )
            // Colored border — stronger when selected
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        mood.color.opacity(isSelected ? 0.5 : 0.15),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        // Scale down slightly when pressed — tactile feel
        .buttonStyle(.plain)
        // Animate the selection state change smoothly
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// ============================================================
// ReflectionPromptCard_Previews
//
// Shows all 5 mood types with selected and unselected states
// so we can check every visual variation at once.
// ============================================================
#Preview {
    ScrollView {
        VStack(spacing: 16) {

            // ---- Section: Unselected prompts ----
            Text("Unselected Prompts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Show one prompt for each mood type, unselected
            ForEach(MoodType.allCases, id: \.self) { mood in
                ReflectionPromptView(
                    prompt: mood.reflectionPrompts[0],
                    mood: mood,
                    isSelected: false,
                    onTap: {
                        // Preview only — no action needed
                        print("Tapped: \(mood.displayName) prompt")
                    }
                )
                .padding(.horizontal)
            }

            Divider()
                .padding(.vertical, 8)

            // ---- Section: Selected state ----
            Text("Selected State")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Show the happy prompt in selected state
            ReflectionPromptView(
                prompt: "What made today great?",
                mood: .happy,
                isSelected: true,
                onTap: {}
            )
            .padding(.horizontal)

            // Show the anxious prompt in selected state
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
    .background(Color(.systemGroupedBackground))
}

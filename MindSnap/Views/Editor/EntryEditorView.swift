
// EntryEditorView.swift
// MindSnap — RICH TEXT EDITOR
//
// ============================================================
// EntryEditorView.swift
// MindSnap — RICH TEXT TOOLBAR FIXED
//
// CRITICAL FIX:
// Toolbar is now injected directly into UITextView
// via inputAccessoryView. This is the ONLY reliable
// way to show a formatting toolbar above the keyboard
// on real iPhone devices.
//
// ToolbarItemGroup(placement: .keyboard) does NOT work
// reliably with UIViewRepresentable on real devices.
// ============================================================

import SwiftUI
import SwiftData
import UIKit
import PhotosUI

// ============================================================
// FormattingAction — what toolbar button does
// ============================================================
enum FormattingAction {
    case bold, italic, underline
    case bulletList, numberedList, quote
    case table, image, voice, dismiss
}

// ============================================================
// RichTextEditor
//
// UIViewRepresentable wrapping UITextView.
// inputAccessoryView handles the toolbar — works on
// ALL real devices reliably.
// ============================================================
struct RichTextEditor: UIViewRepresentable {

    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    var onTextChange: (NSAttributedString) -> Void
    var onFormattingAction: (FormattingAction) -> Void

    // --------------------------------------------------------
    // Coordinator
    // --------------------------------------------------------
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ tv: UITextView) {
            parent.attributedText = tv.attributedText
            parent.selectedRange = tv.selectedRange
            parent.onTextChange(tv.attributedText)
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            parent.selectedRange = tv.selectedRange
        }

        // ---- Toolbar button tapped ----
        @objc func toolbarButtonTapped(_ sender: UIButton) {
            guard let action = FormattingAction.from(
                tag: sender.tag
            ) else { return }
            parent.onFormattingAction(action)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        context.coordinator.textView = tv

        // ---- Basic setup ----
        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.isUserInteractionEnabled = true
        tv.backgroundColor = .clear
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.textColor = UIColor.label
        tv.textContainerInset = UIEdgeInsets(
            top: 12, left: 8, bottom: 12, right: 8
        )

        // ---- TOOLBAR FIX ----
        // Attach formatting toolbar as inputAccessoryView
        // This shows reliably on ALL real iPhone devices
        tv.inputAccessoryView = makeToolbar(
            coordinator: context.coordinator
        )

        return tv
    }

    func updateUIView(
        _ tv: UITextView,
        context: Context
    ) {
        if tv.attributedText != attributedText {
            let range = tv.selectedRange
            tv.attributedText = attributedText
            if range.location <= attributedText.length {
                tv.selectedRange = range
            }
        }
    }

    // --------------------------------------------------------
    // makeToolbar — Creates the formatting toolbar
    //
    // This is attached as inputAccessoryView so it
    // appears ABOVE the keyboard on every real device.
    // --------------------------------------------------------
    private func makeToolbar(
        coordinator: Coordinator
    ) -> UIView {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = UIColor.systemPurple

        // ---- Helper to make button ----
        func btn(
            icon: String,
            tag: Int,
            title: String? = nil
        ) -> UIBarButtonItem {
            let button = UIButton(type: .system)
            button.tag = tag
            button.addTarget(
                coordinator,
                action: #selector(
                    Coordinator.toolbarButtonTapped(_:)
                ),
                for: .touchUpInside
            )
            button.tintColor = UIColor.systemPurple

            let img = UIImage(systemName: icon)?
                .withConfiguration(
                    UIImage.SymbolConfiguration(pointSize: 16)
                )

            if let img = img {
                button.setImage(img, for: .normal)
            } else if let title = title {
                button.setTitle(title, for: .normal)
                button.titleLabel?.font =
                    UIFont.systemFont(
                        ofSize: 15, weight: .semibold
                    )
            }

            button.frame = CGRect(
                x: 0, y: 0, width: title == nil ? 36 : 56, height: 36
            )
            return UIBarButtonItem(customView: button)
        }

        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let fixed = UIBarButtonItem(
            barButtonSystemItem: .fixedSpace,
            target: nil,
            action: nil
        )
        fixed.width = 4

        let items: [UIBarButtonItem] = [
            // Bold
            btn(icon: "bold", tag: 0),
            fixed,
            // Italic
            btn(icon: "italic", tag: 1),
            fixed,
            // Underline
            btn(icon: "underline", tag: 2),
            fixed,
            // Separator
            UIBarButtonItem(
                barButtonSystemItem: .fixedSpace,
                target: nil, action: nil
            ),
            // Bullet list
            btn(icon: "list.bullet", tag: 3),
            fixed,
            // Numbered list
            btn(icon: "list.number", tag: 4),
            fixed,
            // Quote
            btn(icon: "text.quote", tag: 5),
            fixed,
            // Table
            btn(icon: "tablecells", tag: 6),
            fixed,
            // Photo
            btn(icon: "photo", tag: 7),
            fixed,
            // Mic
            btn(icon: "mic", tag: 8),
            space,
            // Dismiss keyboard
            btn(icon: "", tag: 9, title: "Done")
        ]

        toolbar.items = items
        return toolbar
    }
}

// ---- Map tag → FormattingAction ----
extension FormattingAction {
    static func from(tag: Int) -> FormattingAction? {
        switch tag {
        case 0: return .bold
        case 1: return .italic
        case 2: return .underline
        case 3: return .bulletList
        case 4: return .numberedList
        case 5: return .quote
        case 6: return .table
        case 7: return .image
        case 8: return .voice
        case 9: return .dismiss
        default: return nil
        }
    }
}

// ============================================================
// EntryEditorView
// ============================================================
struct EntryEditorView: View {

    let viewModel: JournalViewModel
    let existingEntry: JournalEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // ---- Rich text ----
    @State private var attributedText = NSAttributedString(
        string: "",
        attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ]
    )
    @State private var selectedRange = NSRange(
        location: 0, length: 0
    )
    @State private var plainText = ""

    // ---- Image picker ----
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // ---- Other state ----
    @State private var selectedTags: [String] = []
    @State private var selectedPrompt: String? = nil
    @State private var showingPrompts = false
    @State private var showingTagSelector = false
    @State private var userSelectedMood: MoodType = .neutral
    @State private var aiDetectedMood: MoodType = .neutral
    @State private var userHasOverridden = false
    @State private var showingMoodCheckIn = false

    @State private var speechService = SpeechService()
    @State private var showingSpeechError = false

    private let sentimentService = SentimentService()
    private var isEditMode: Bool { existingEntry != nil }

    private var finalMood: MoodType {
        userHasOverridden ? userSelectedMood : aiDetectedMood
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.17, green: 0.17, blue: 0.18)
            : Color(.systemBackground)
    }

    private var editorBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.13, green: 0.13, blue: 0.14)
            : Color(.systemGray6)
    }

    private let availableTags = [
        "Work", "Family", "Health", "Friends",
        "Travel", "Food", "Exercise", "Learning",
        "Gratitude", "Goals"
    ]

    private let moodEmojis = [
        "😊","😢","😰","😌","😐",
        "😤","😔","🥰","😅","😴"
    ]
    private let activityEmojis = [
        "🏃","🍕","☕️","📚","🎵",
        "🎮","🌙","🌅","💪","🧘"
    ]
    private let feelingEmojis = [
        "❤️","🔥","⭐️","✨","💭",
        "🙏","💡","🌈","🎯","💫"
    ]

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // ---- Mood Banner ----
                        smartMoodBanner
                            .padding(.horizontal, 16)

                        // ---- Rich Text Editor ----
                        richTextEditorSection
                            .padding(.horizontal, 16)

                        // ---- Recording Banner ----
                        if speechService.isRecording {
                            recordingBanner
                                .padding(.horizontal, 16)
                        }

                        // ---- Prompts ----
                        reflectionPromptsSection
                            .padding(.horizontal, 16)

                        // ---- Tags ----
                        tagAndEmojiSection
                            .padding(.horizontal, 16)

                        // ---- Selected Tags ----
                        if !selectedTags.isEmpty {
                            selectedTagsDisplay
                                .padding(.horizontal, 16)
                        }

                        // ---- Mood Override ----
                        moodOverrideBar
                            .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(
                isEditMode ? "Edit Entry" : "New Entry"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .navigationBarLeading
                ) {
                    Button("Cancel") {
                        if speechService.isRecording {
                            speechService.stopRecording()
                        }
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {
                    Button(isEditMode ? "Update" : "Save") {
                        saveEntry()
                    }
                    .disabled(plainText.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        plainText.isEmpty
                            ? Color.secondary : Color.purple
                    )
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .alert(
                "Microphone Error",
                isPresented: $showingSpeechError
            ) {
                Button("Open Settings") {
                    if let url = URL(
                        string: UIApplication
                            .openSettingsURLString
                    ) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(
                    speechService.errorMessage ??
                    "Could not access microphone."
                )
            }
        }
        .sheet(isPresented: $showingMoodCheckIn) {
            MoodCheckInView { mood in
                userSelectedMood = mood
                aiDetectedMood = mood
                userHasOverridden = false
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, item in
            Task { await loadImage(from: item) }
        }
        .onAppear {
            if let entry = existingEntry {
                loadExistingEntry(entry)
            } else {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3
                ) {
                    showingMoodCheckIn = true
                }
            }
        }
        .onChange(of: plainText) { _, text in
            if text.count > 10 {
                let result = sentimentService.analyze(text: text)
                aiDetectedMood = result.mood
            }
        }
        .onChange(of: speechService.transcribedText) { _, text in
            if !text.isEmpty { appendToRichText(text) }
        }
        .onChange(of: speechService.errorMessage) { _, err in
            if err != nil { showingSpeechError = true }
        }
    }

    // --------------------------------------------------------
    // MARK: - Rich Text Editor Section
    // --------------------------------------------------------
    private var richTextEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("What's on your mind?")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Voice button
                Button {
                    dismissKeyboard()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await speechService.toggleRecording() }
                } label: {
                    Image(systemName:
                        speechService.isRecording
                            ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        speechService.isRecording ? .red : .purple
                    )
                }
                .buttonStyle(.plain)
            }

            // ---- THE EDITOR ----
            // Toolbar is INSIDE the UITextView as
            // inputAccessoryView — shows on all real devices
            RichTextEditor(
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                onTextChange: { newText in
                    plainText = newText.string
                },
                onFormattingAction: { action in
                    handleFormattingAction(action)
                }
            )
            .frame(minHeight: 220)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(editorBackground)
            )

            // Hint
            if plainText.isEmpty {
                Text("Bold, italic, lists and more — " +
                     "use the toolbar above the keyboard")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
        )
    }

    // --------------------------------------------------------
    // MARK: - Handle Formatting Actions
    // --------------------------------------------------------
    private func handleFormattingAction(
        _ action: FormattingAction
    ) {
        switch action {
        case .bold:          applyBold()
        case .italic:        applyItalic()
        case .underline:     applyUnderline()
        case .bulletList:    insertBulletList()
        case .numberedList:  insertNumberedList()
        case .quote:         insertQuote()
        case .table:         insertTable()
        case .image:         showingImagePicker = true
        case .voice:
            Task { await speechService.toggleRecording() }
        case .dismiss:
            dismissKeyboard()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    // --------------------------------------------------------
    // MARK: - Smart Mood Banner
    // --------------------------------------------------------
    private var smartMoodBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text(finalMood.emoji)
                        .font(.system(size: 36))
                        .id(finalMood)
                        .transition(
                            .scale.combined(with: .opacity)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            userHasOverridden
                                ? "Your Mood"
                                : "Detected Mood"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                        Text(finalMood.displayName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(finalMood.color)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if userHasOverridden {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                            Text("You chose")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    } else if plainText.count > 10 {
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                            Text("Detected on device")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    } else {
                        Text("\(plainText.count) chars")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if plainText.count > 10 {
                scoreBar
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(finalMood.color.opacity(
                    colorScheme == .dark ? 0.15 : 0.08
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            finalMood.color.opacity(0.25),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.3), value: finalMood)
    }

    private var scoreBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("😢 Negative")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Positive 😊")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    let score = sentimentService
                        .analyze(text: plainText).score
                    let displayScore = (score + 1) / 2
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .gray, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                8,
                                geo.size.width *
                                CGFloat(displayScore)
                            ),
                            height: 6
                        )
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: plainText
                        )
                }
            }
            .frame(height: 6)
        }
    }

    // --------------------------------------------------------
    // MARK: - Recording Banner
    // --------------------------------------------------------
    private var recordingBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(speechService.isRecording ? 1 : 0)
                .animation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                    value: speechService.isRecording
                )
            Text("Recording... speak now")
                .font(.subheadline)
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(
                    colorScheme == .dark ? 0.15 : 0.08
                ))
        )
    }

    // --------------------------------------------------------
    // MARK: - Reflection Prompts
    // --------------------------------------------------------
    private var reflectionPromptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingPrompts.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Reflection Prompts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(
                            showingPrompts ? 180 : 0
                        ))
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: showingPrompts
                        )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackground)
                )
            }
            .buttonStyle(.plain)

            if showingPrompts {
                VStack(spacing: 8) {
                    ForEach(
                        finalMood.reflectionPrompts,
                        id: \.self
                    ) { prompt in
                        Button {
                            appendToRichText("\n\(prompt)\n\n")
                            withAnimation {
                                showingPrompts = false
                            }
                        } label: {
                            HStack {
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName:
                                    "arrow.right.circle"
                                )
                                .foregroundStyle(.purple)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(cardBackground)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(
                    with: .move(edge: .top)
                ))
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Tags
    // --------------------------------------------------------
    private var tagAndEmojiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingTagSelector.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.purple)
                    Text("Add Tags & Emojis")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    if !selectedTags.isEmpty {
                        Text("(\(selectedTags.count))")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(
                            showingTagSelector ? 180 : 0
                        ))
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: showingTagSelector
                        )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackground)
                )
            }
            .buttonStyle(.plain)

            if showingTagSelector {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 80))
                        ],
                        spacing: 8
                    ) {
                        ForEach(availableTags, id: \.self) { tag in
                            let isSelected =
                                selectedTags.contains(tag)
                            Button {
                                toggleTag(tag)
                            } label: {
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(
                                            isSelected
                                                ? Color.purple
                                                : Color(.systemGray5)
                                        )
                                    )
                                    .foregroundStyle(
                                        isSelected ? .white : .primary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider()

                    Text("Mood Emojis")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    emojiRow(emojis: moodEmojis)

                    Text("Activities")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    emojiRow(emojis: activityEmojis)

                    Text("Feelings")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    emojiRow(emojis: feelingEmojis)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackground)
                )
                .transition(.opacity.combined(
                    with: .move(edge: .top)
                ))
            }
        }
    }

    private func emojiRow(emojis: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(emojis, id: \.self) { emoji in
                    let isSelected = selectedTags.contains(emoji)
                    Button {
                        toggleTag(emoji)
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(
                                        isSelected
                                            ? Color.purple
                                                .opacity(
                                                colorScheme == .dark
                                                    ? 0.3 : 0.15
                                            )
                                            : Color(.systemGray5)
                                    )
                                    .overlay(
                                        Circle().stroke(
                                            isSelected
                                                ? Color.purple
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                    )
                            )
                            .scaleEffect(isSelected ? 1.15 : 1.0)
                            .animation(
                                .spring(
                                    duration: 0.3, bounce: 0.5
                                ),
                                value: isSelected
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Selected Tags Display
    // --------------------------------------------------------
    private var selectedTagsDisplay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                            Button {
                                selectedTags.removeAll {
                                    $0 == tag
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(
                                        size: 8, weight: .bold
                                    ))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(
                                    colorScheme == .dark
                                        ? 0.25 : 0.12
                                ))
                        )
                        .foregroundStyle(.purple)
                    }
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Mood Override Bar
    // --------------------------------------------------------
    private var moodOverrideBar: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text("Override Mood")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if userHasOverridden {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            userHasOverridden = false
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName:
                                "arrow.counterclockwise"
                            )
                            .font(.caption2)
                            Text("Use Detection")
                                .font(.caption2)
                        }
                        .foregroundStyle(.purple)
                    }
                }
            }

            HStack(spacing: 0) {
                ForEach(
                    MoodType.allCases, id: \.self
                ) { mood in
                    let isSelected = finalMood == mood
                    Button {
                        withAnimation(
                            .spring(duration: 0.3, bounce: 0.5)
                        ) {
                            userSelectedMood = mood
                            userHasOverridden = true
                        }
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(
                                    size: isSelected ? 28 : 22
                                ))
                                .scaleEffect(
                                    isSelected ? 1.1 : 1.0
                                )
                                .animation(
                                    .spring(
                                        duration: 0.3,
                                        bounce: 0.5
                                    ),
                                    value: isSelected
                                )

                            Circle()
                                .fill(
                                    isSelected
                                        ? mood.color
                                        : Color.clear
                                )
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    isSelected
                                        ? mood.color.opacity(
                                            colorScheme == .dark
                                                ? 0.2 : 0.1
                                          )
                                        : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(editorBackground)
            )
        }
    }

    // --------------------------------------------------------
    // MARK: - Formatting Functions
    // --------------------------------------------------------
    private func applyBold() {
        applyFontTrait(.traitBold)
    }

    private func applyItalic() {
        applyFontTrait(.traitItalic)
    }

    private func applyUnderline() {
        let range = selectedRange
        guard range.length > 0 else { return }
        let mutable = NSMutableAttributedString(
            attributedString: attributedText
        )
        let current = mutable.attribute(
            .underlineStyle,
            at: range.location,
            effectiveRange: nil
        ) as? Int ?? 0

        if current == 0 {
            mutable.addAttribute(
                .underlineStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: range
            )
        } else {
            mutable.removeAttribute(
                .underlineStyle, range: range
            )
        }
        attributedText = mutable
    }

    private func applyFontTrait(
        _ trait: UIFontDescriptor.SymbolicTraits
    ) {
        let range = selectedRange
        guard range.length > 0 else { return }

        let mutable = NSMutableAttributedString(
            attributedString: attributedText
        )

        mutable.enumerateAttribute(
            .font, in: range, options: []
        ) { value, subRange, _ in
            let font = value as? UIFont
                ?? UIFont.preferredFont(forTextStyle: .body)
            var traits = font.fontDescriptor.symbolicTraits

            if traits.contains(trait) {
                traits.remove(trait)
            } else {
                traits.insert(trait)
            }

            let desc = font.fontDescriptor
                .withSymbolicTraits(traits)
                ?? font.fontDescriptor
            let newFont = UIFont(
                descriptor: desc,
                size: font.pointSize
            )
            mutable.addAttribute(
                .font, value: newFont, range: subRange
            )
        }
        attributedText = mutable
    }

    private func insertBulletList() {
        appendToRichText("\n• ")
    }

    private func insertNumberedList() {
        let lines = plainText
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
        let count = lines.filter {
            $0.first?.isNumber == true
        }.count
        appendToRichText("\n\(count + 1). ")
    }

    private func insertQuote() {
        let quote = NSMutableAttributedString(
            string: "\n",
            attributes: [
                .font: UIFont.preferredFont(
                    forTextStyle: .body
                ),
                .foregroundColor: UIColor.label
            ]
        )
        let quoteText = NSMutableAttributedString(
            string: "❝ Quote here ❞",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 16),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        quote.append(quoteText)
        quote.append(NSAttributedString(string: "\n"))
        appendAttributedText(quote)
    }

    private func insertTable() {
        appendToRichText(
            "\n\n| Column 1 | Column 2 |\n" +
            "|----------|----------|\n" +
            "| Cell 1   | Cell 2   |\n\n"
        )
    }

    private func appendToRichText(_ text: String) {
        let mutable = NSMutableAttributedString(
            attributedString: attributedText
        )
        mutable.append(NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(
                    forTextStyle: .body
                ),
                .foregroundColor: UIColor.label
            ]
        ))
        attributedText = mutable
        plainText = mutable.string
    }

    private func appendAttributedText(
        _ text: NSAttributedString
    ) {
        let mutable = NSMutableAttributedString(
            attributedString: attributedText
        )
        mutable.append(text)
        attributedText = mutable
        plainText = mutable.string
    }

    private func loadImage(
        from item: PhotosPickerItem?
    ) async {
        guard let item = item else { return }
        do {
            if let data = try await item.loadTransferable(
                type: Data.self
            ),
               let image = UIImage(data: data) {
                await MainActor.run { insertImage(image) }
            }
        } catch {
            print("Image load error: \(error)")
        }
    }

    private func insertImage(_ image: UIImage) {
        let mutable = NSMutableAttributedString(
            attributedString: attributedText
        )
        mutable.append(NSAttributedString(string: "\n"))

        let attachment = NSTextAttachment()
        let maxWidth: CGFloat = 260
        let scale = maxWidth / image.size.width
        attachment.bounds = CGRect(
            x: 0, y: 0,
            width: maxWidth,
            height: image.size.height * scale
        )
        attachment.image = image

        mutable.append(
            NSAttributedString(attachment: attachment)
        )
        mutable.append(NSAttributedString(
            string: "\n",
            attributes: [
                .font: UIFont.preferredFont(
                    forTextStyle: .body
                ),
                .foregroundColor: UIColor.label
            ]
        ))
        attributedText = mutable
        plainText = mutable.string
    }

    // --------------------------------------------------------
    // MARK: - Load / Save Entry
    // --------------------------------------------------------
    private func loadExistingEntry(_ entry: JournalEntry) {
        if let data = entry.richTextData,
           let restored = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtfd],
            documentAttributes: nil
           ) {
            attributedText = restored
        } else {
            attributedText = NSAttributedString(
                string: entry.text,
                attributes: [
                    .font: UIFont.preferredFont(
                        forTextStyle: .body
                    ),
                    .foregroundColor: UIColor.label
                ]
            )
        }
        plainText = entry.text
        selectedTags = entry.tags
        selectedPrompt = entry.reflectionPromptUsed
        userSelectedMood = entry.moodType
        aiDetectedMood = entry.moodType
    }

    private func saveEntry() {
        if speechService.isRecording {
            speechService.stopRecording()
        }
        let text = plainText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !text.isEmpty else { return }
        let richTextData = archivedRichTextData()

        if let existing = existingEntry {
            viewModel.updateEntry(
                existing,
                text: text,
                richTextData: richTextData,
                tags: selectedTags,
                reflectionPrompt: selectedPrompt,
                moodType: finalMood
            )
        } else {
            viewModel.saveEntry(
                text: text,
                richTextData: richTextData,
                tags: selectedTags,
                reflectionPrompt: selectedPrompt,
                moodType: finalMood
            )
        }
        dismiss()
    }

    private func archivedRichTextData() -> Data? {
        let fullRange = NSRange(
            location: 0,
            length: attributedText.length
        )
        return try? attributedText.data(
            from: fullRange,
            documentAttributes: [
                .documentType:
                    NSAttributedString.DocumentType.rtfd
            ]
        )
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("New Entry") {
    let config = ModelConfiguration(
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: JournalEntry.self,
        configurations: config
    )
    let viewModel = JournalViewModel(
        modelContext: container.mainContext
    )
    EntryEditorView(
        viewModel: viewModel,
        existingEntry: nil
    )
    .modelContainer(container)
}

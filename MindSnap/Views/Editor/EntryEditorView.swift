// EntryEditorView.swift
// MindSnap — RICH TEXT EDITOR
//
// ============================================================
// EntryEditorView.swift
// MindSnap — PREMIUM MONOCHROME EDITOR
//
// UI UPDATE:
// 1. Professional black/white editor theme
// 2. Custom safe top bar to prevent Cancel/Save overlap
// 3. Focus writing mode
// 4. First-time coach mark for Focus mode
// 5. Subtle moving pencil animation while typing
//
// FUNCTIONALITY KEPT:
// 1. Rich text editor
// 2. Formatting toolbar through inputAccessoryView
// 3. Voice journaling
// 4. Image picker
// 5. Mood detection / override
// 6. Tags / emojis
// 7. Save / update journal logic
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
// ============================================================
struct RichTextEditor: UIViewRepresentable {

    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var caretRect: CGRect
    @Binding var isEditorFocused: Bool

    var onTextChange: (NSAttributedString) -> Void
    var onFormattingAction: (FormattingAction) -> Void

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        private func updateCaretRect(_ tv: UITextView) {
            guard let selectedRange = tv.selectedTextRange else {
                parent.caretRect = .zero
                return
            }

            let rect = tv.caretRect(for: selectedRange.end)
            parent.caretRect = rect
        }

        func textViewDidChange(_ tv: UITextView) {
            parent.attributedText = tv.attributedText
            parent.selectedRange = tv.selectedRange
            parent.onTextChange(tv.attributedText)
            updateCaretRect(tv)
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            parent.selectedRange = tv.selectedRange
            updateCaretRect(tv)
        }

        func textViewDidBeginEditing(_ tv: UITextView) {
            parent.isEditorFocused = true
            updateCaretRect(tv)
        }

        func textViewDidEndEditing(_ tv: UITextView) {
            parent.isEditorFocused = false
            parent.caretRect = .zero
        }

        @objc func toolbarButtonTapped(_ sender: UIButton) {
            guard let action = FormattingAction.from(tag: sender.tag) else {
                return
            }
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

        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.isUserInteractionEnabled = true
        tv.backgroundColor = .clear
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.textColor = UIColor.label
        tv.tintColor = UIColor.label
        // Disable iOS writing suggestions/autocorrection for journaling
        // Keep spelling correction, but avoid AutoFill/contact-style suggestions
        tv.autocorrectionType = .no
        tv.spellCheckingType = .yes

        // Keep typing natural, avoid unwanted smart formatting changes
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.smartInsertDeleteType = .no

        // Natural sentence capitalization
        tv.autocapitalizationType = .sentences

        // Prevent name/contact/password/autofill style suggestions
        tv.textContentType = .none
        tv.textContainerInset = UIEdgeInsets(
            top: 12,
            left: 8,
            bottom: 12,
            right: 8
        )

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

    private func makeToolbar(
        coordinator: Coordinator
    ) -> UIView {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = UIColor.label
        toolbar.barTintColor = UIColor.systemBackground
        toolbar.backgroundColor = UIColor.systemBackground
        toolbar.isTranslucent = false

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
            button.tintColor = UIColor.label

            let img = UIImage(systemName: icon)?
                .withConfiguration(
                    UIImage.SymbolConfiguration(pointSize: 16)
                )

            if let img = img {
                button.setImage(img, for: .normal)
            } else if let title = title {
                button.setTitle(title, for: .normal)
                button.setTitleColor(.label, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(
                    ofSize: 16,
                    weight: .bold
                )
            }

            button.frame = CGRect(
                x: 0,
                y: 0,
                width: title == nil ? 36 : 68,
                height: 36
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

        toolbar.items = [
            btn(icon: "bold", tag: 0),
            fixed,
            btn(icon: "italic", tag: 1),
            fixed,
            btn(icon: "underline", tag: 2),
            fixed,
            btn(icon: "list.bullet", tag: 3),
            fixed,
            btn(icon: "list.number", tag: 4),
            fixed,
            btn(icon: "text.quote", tag: 5),
            fixed,
            btn(icon: "tablecells", tag: 6),
            fixed,
            btn(icon: "photo", tag: 7),
            fixed,
            btn(icon: "mic", tag: 8),
            space,
            btn(icon: "", tag: 9, title: "Done")
        ]

        return toolbar
    }
}

// ============================================================
// FormattingAction mapping
// ============================================================
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
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var plainText = ""

    // ---- Image picker ----
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // ---- Editor state ----
    @State private var selectedTags: [String] = []
    @State private var selectedPrompt: String? = nil
    @State private var showingPrompts = false
    @State private var showingTagSelector = false
    @State private var isFocusMode = false

    // ---- Mood state ----
    @State private var userSelectedMood: MoodType = .neutral
    @State private var aiDetectedMood: MoodType = .neutral
    @State private var userHasOverridden = false
    @State private var showingMoodCheckIn = false

    // ---- Speech ----
    @State private var speechService = SpeechService()
    @State private var showingSpeechError = false
    @State private var lastSpeechTranscript = ""

    // ---- Writing animation ----
    @State private var showingWritingIndicator = false
    @State private var typingHideTask: DispatchWorkItem?
    @State private var caretRect: CGRect = .zero
    @State private var isEditorFocused = false
    @State private var pencilPosition: CGPoint = .zero
    @State private var lastCaretPosition: CGPoint = .zero
    @State private var pencilMovingForward = true
    @State private var pencilStrokePhase = false

    // ---- Coach mark ----
    @AppStorage("hasSeenJournalFullscreenCoachMark")
    private var hasSeenJournalFullscreenCoachMark = false
    @State private var showJournalFullscreenCoachMark = false

    private let sentimentService = SentimentService()
    private var isEditMode: Bool { existingEntry != nil }

    private var canSave: Bool {
        !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var finalMood: MoodType {
        userHasOverridden ? userSelectedMood : aiDetectedMood
    }

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

    private var editorBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.12, green: 0.12, blue: 0.13)
        : Color(red: 0.985, green: 0.985, blue: 0.99)
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

    private var chipBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.07)
        : Color.black.opacity(0.055)
    }

    private var primaryButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var primaryButtonText: Color {
        colorScheme == .dark ? .black : .white
    }

    private var selectedSoftBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.10)
        : Color.black.opacity(0.055)
    }

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.06)
    }

    private var disabledButtonBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.055)
    }

    private let availableTags = [
        "Work", "Family", "Health", "Friends",
        "Travel", "Food", "Exercise", "Learning",
        "Gratitude", "Goals"
    ]

    private let moodEmojis = [
        "😊", "😢", "😰", "😌", "😐",
        "😤", "😔", "🥰", "😅", "😴"
    ]

    private let activityEmojis = [
        "🏃", "🍕", "☕️", "📚", "🎵",
        "🎮", "🌙", "🌅", "💪", "🧘"
    ]

    private let feelingEmojis = [
        "❤️", "🔥", "⭐️", "✨", "💭",
        "🙏", "💡", "🌈", "🎯", "💫"
    ]

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        NavigationStack {
            ZStack {
                appBackground
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }

                if isFocusMode {
                    focusModeContent
                } else {
                    normalEditorContent
                }

                if showJournalFullscreenCoachMark {
                    journalFullscreenCoachMarkOverlay
                        .transition(.opacity)
                        .zIndex(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                entryTopBar
            }
            .alert(
                "Microphone Error",
                isPresented: $showingSpeechError
            ) {
                Button("Open Settings") {
                    if let url = URL(
                        string: UIApplication.openSettingsURLString
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
                presentJournalFullscreenCoachMarkIfNeeded()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingMoodCheckIn = true
                }
            }
        }
        .onChange(of: showingMoodCheckIn) { _, isShowing in
            if !isShowing {
                presentJournalFullscreenCoachMarkIfNeeded()
            }
        }
        .onChange(of: plainText) { _, text in
            if text.count > 10 {
                let result = sentimentService.analyze(text: text)
                aiDetectedMood = result.mood
            }
        }
        .onChange(of: speechService.transcribedText) { _, text in
            appendSpeechDelta(text)
        }
        .onChange(of: speechService.errorMessage) { _, err in
            if err != nil {
                showingSpeechError = true
            }
        }
        .onDisappear {
            typingHideTask?.cancel()
            speechService.cancelRecording()
        }
    }

    // --------------------------------------------------------
    // MARK: - Custom Top Bar
    // --------------------------------------------------------
    private var entryTopBar: some View {
        ZStack {
            Text(isEditMode ? "Edit Entry" : "New Entry")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(primaryText)
                .lineLimit(1)

            HStack {
                Button {
                    if speechService.isRecording {
                        speechService.stopRecording()
                    }
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                        .frame(width: 100, height: 48)
                        .background(
                            Capsule()
                                .fill(cardBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                                .shadow(
                                    color: shadowColor,
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    saveEntry()
                } label: {
                    Text(isEditMode ? "Update" : "Save")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            canSave ? primaryButtonText : secondaryText
                        )
                        .frame(width: 100, height: 48)
                        .background(
                            Capsule()
                                .fill(
                                    canSave
                                    ? primaryButtonBackground
                                    : disabledButtonBackground
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            canSave ? Color.clear : borderColor,
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: canSave ? shadowColor : Color.clear,
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            appBackground
                .opacity(0.96)
                .ignoresSafeArea(edges: .top)
        )
    }

    // --------------------------------------------------------
    // MARK: - Normal Editor Content
    // --------------------------------------------------------
    private var normalEditorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                smartMoodBanner
                    .padding(.horizontal, 16)

                richTextEditorSection
                    .padding(.horizontal, 16)

                if speechService.isRecording {
                    recordingBanner
                        .padding(.horizontal, 16)
                }

                reflectionPromptsSection
                    .padding(.horizontal, 16)

                tagAndEmojiSection
                    .padding(.horizontal, 16)

                if !selectedTags.isEmpty {
                    selectedTagsDisplay
                        .padding(.horizontal, 16)
                }

                moodOverrideBar
                    .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // --------------------------------------------------------
    // MARK: - Focus Mode
    // --------------------------------------------------------
    private var focusModeContent: some View {
        GeometryReader { geo in
            let editorHeight = max(260, geo.size.height - 185)

            VStack(spacing: 10) {

                // ----------------------------------------------------
                // Fixed focus mode control bar
                // ----------------------------------------------------
                HStack(spacing: 8) {
                    Button {
                        toggleFocusMode()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .font(.caption)

                            Text("Compact")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(cardBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        Text(finalMood.emoji)
                            .font(.caption)

                        Text(finalMood.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(finalMood.color)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(cardBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )

                    Spacer(minLength: 6)

                    Button {
                        dismissKeyboard()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.caption)

                            Text("Done")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(cardBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        toggleSpeechRecording()
                    } label: {
                        Image(
                            systemName: speechService.isRecording
                            ? "stop.circle.fill"
                            : "mic.circle.fill"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            speechService.isRecording ? .red : primaryText
                        )
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(cardBackground)
                                .overlay(
                                    Circle()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if speechService.isRecording {
                    recordingBanner
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Write freely")
                                .font(.headline)
                                .foregroundStyle(primaryText)

                            if showingWritingIndicator && !plainText.isEmpty {
                                writingIndicator
                                    .transition(
                                        .opacity.combined(with: .move(edge: .top))
                                    )
                            }
                        }

                        Spacer()

                        if plainText.count > 10 {
                            HStack(spacing: 5) {
                                Image(systemName: "brain")
                                    .font(.caption2)

                                Text("On device")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(secondaryText)
                        } else {
                            Text("\(plainText.count) chars")
                                .font(.caption2)
                                .foregroundStyle(tertiaryText)
                        }
                    }

                    editorBox(minHeight: editorHeight, cornerRadius: 22)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .shadow(
                            color: shadowColor,
                            radius: 14,
                            x: 0,
                            y: 7
                        )
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 8)
        }
    }

    // --------------------------------------------------------
    // MARK: - Main Rich Text Section
    // --------------------------------------------------------
    private var richTextEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("What's on your mind?")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    if showingWritingIndicator && !plainText.isEmpty {
                        writingIndicator
                            .transition(
                                .opacity.combined(with: .move(edge: .top))
                            )
                    }
                }

                Spacer()

                Button {
                    if showJournalFullscreenCoachMark {
                        dismissJournalFullscreenCoachMark()
                    }
                    toggleFocusMode()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)

                        Text("Focus")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(chipBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button {
                    dismissKeyboard()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.caption)

                        Text("Done")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(chipBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button {
                    toggleSpeechRecording()
                } label: {
                    Image(
                        systemName: speechService.isRecording
                        ? "stop.circle.fill"
                        : "mic.circle.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        speechService.isRecording ? .red : primaryText
                    )
                }
                .buttonStyle(.plain)
            }

            editorBox(minHeight: 240, cornerRadius: 18)

            if plainText.isEmpty {
                Text("Use the toolbar above the keyboard for bold, lists, images, voice, and more.")
                    .font(.caption2)
                    .foregroundStyle(tertiaryText)
                    .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    private func editorBox(
        minHeight: CGFloat,
        cornerRadius: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            RichTextEditor(
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                caretRect: $caretRect,
                isEditorFocused: $isEditorFocused,
                onTextChange: { newText in
                    plainText = newText.string
                    handleTypingAnimation(for: newText.string)
                },
                onFormattingAction: { action in
                    handleFormattingAction(action)
                }
            )
            .frame(minHeight: minHeight)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(editorBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .onChange(of: caretRect) { _, newValue in
                guard isEditorFocused else { return }
                updatePencilPosition(from: newValue)
            }

            if isEditorFocused &&
                showingWritingIndicator &&
                !plainText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty {
                magicPencilOverlay
                    .transition(.opacity)
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Coach Mark
    // --------------------------------------------------------
    private func presentJournalFullscreenCoachMarkIfNeeded() {
        guard !hasSeenJournalFullscreenCoachMark else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard !showingMoodCheckIn else { return }

            withAnimation(.easeInOut(duration: 0.22)) {
                showJournalFullscreenCoachMark = true
            }
        }
    }

    private func dismissJournalFullscreenCoachMark() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showJournalFullscreenCoachMark = false
            hasSeenJournalFullscreenCoachMark = true
        }
    }

    private var journalFullscreenCoachMarkOverlay: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.42 : 0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissJournalFullscreenCoachMark()
                }

            VStack {
                Spacer()
                    .frame(height: 290)

                HStack {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Image(systemName: "arrow.up")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(primaryText)
                            .padding(.trailing, 92)

                        coachMarkBubble(
                            title: "Focus Writing",
                            message: "Tap Focus to open a clean writing space with fewer distractions.",
                            buttonTitle: "Got it"
                        ) {
                            dismissJournalFullscreenCoachMark()
                        }
                    }
                    .padding(.trailing, 30)
                }

                Spacer()
            }
        }
    }

    private func coachMarkBubble(
        title: String,
        message: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(primaryText)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()

                Button(buttonTitle) {
                    action()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(primaryButtonText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(primaryButtonBackground)
                )
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: 270, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.16),
                    radius: 18,
                    x: 0,
                    y: 10
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Focus Mode Helper
    // --------------------------------------------------------
    private func toggleFocusMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isFocusMode.toggle()

            if isFocusMode {
                showingPrompts = false
                showingTagSelector = false
                showJournalFullscreenCoachMark = false
                hasSeenJournalFullscreenCoachMark = true
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Pencil Animation
    // --------------------------------------------------------
    private var magicPencilOverlay: some View {
        GeometryReader { geo in
            let safeDistanceX: CGFloat = pencilMovingForward ? 28 : 34
            let safeDistanceY: CGFloat = 14

            let baseX = min(
                max(pencilPosition.x + safeDistanceX, 30),
                geo.size.width - 32
            )

            let baseY = min(
                max(pencilPosition.y + safeDistanceY, 28),
                geo.size.height - 28
            )

            let strokeX: CGFloat = pencilMovingForward
                ? (pencilStrokePhase ? 2 : -1)
                : (pencilStrokePhase ? -2 : 1)

            let strokeY: CGFloat = pencilStrokePhase ? -1.5 : 1.5

            let angle: Double = pencilMovingForward
                ? (pencilStrokePhase ? -22 : -12)
                : (pencilStrokePhase ? 202 : 190)

            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.035)
                    )
                    .frame(width: 20, height: 20)
                    .blur(radius: 1)

                Image(systemName: "pencil.tip")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(primaryText.opacity(0.78))
                    .rotationEffect(.degrees(angle))
                    .offset(x: strokeX, y: strokeY)

                Image(systemName: "sparkles")
                    .font(.system(size: 6, weight: .semibold))
                    .foregroundStyle(secondaryText.opacity(0.75))
                    .offset(
                        x: pencilStrokePhase ? 10 : 8,
                        y: pencilStrokePhase ? -9 : -7
                    )
                    .opacity(showingWritingIndicator ? 0.75 : 0.25)
            }
            .position(x: baseX, y: baseY)
            .animation(
                .spring(response: 0.20, dampingFraction: 0.70),
                value: pencilPosition
            )
            .animation(
                .easeInOut(duration: 0.12),
                value: pencilStrokePhase
            )
            .animation(
                .easeInOut(duration: 0.12),
                value: pencilMovingForward
            )
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }

    private var writingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil.tip")
                .font(.caption)
                .foregroundStyle(primaryText)

            Text("Writing your thoughts...")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(secondaryText)

            Image(systemName: "sparkles")
                .font(.caption2)
                .foregroundStyle(secondaryText)
        }
    }

    private func handleTypingAnimation(for text: String) {
        typingHideTask?.cancel()

        guard !text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingWritingIndicator = false
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            showingWritingIndicator = true
            pencilStrokePhase.toggle()
        }

        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.35)) {
                showingWritingIndicator = false
            }
        }

        typingHideTask = task
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.75,
            execute: task
        )
    }

    private func updatePencilPosition(from caret: CGRect) {
        let newPoint = CGPoint(x: caret.maxX, y: caret.midY)

        if newPoint.x > lastCaretPosition.x {
            pencilMovingForward = true
        } else if newPoint.x < lastCaretPosition.x {
            pencilMovingForward = false
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            pencilPosition = newPoint
        }

        lastCaretPosition = newPoint
    }

    // --------------------------------------------------------
    // MARK: - Formatting Actions
    // --------------------------------------------------------
    private func handleFormattingAction(
        _ action: FormattingAction
    ) {
        switch action {
        case .bold:
            applyBold()

        case .italic:
            applyItalic()

        case .underline:
            applyUnderline()

        case .bulletList:
            insertBulletList()

        case .numberedList:
            insertNumberedList()

        case .quote:
            insertQuote()

        case .table:
            insertTable()

        case .image:
            showingImagePicker = true

        case .voice:
            toggleSpeechRecording()

        case .dismiss:
            dismissKeyboard()
        }
    }

    private func toggleSpeechRecording() {
        if !speechService.isRecording {
            lastSpeechTranscript = ""
        }

        Task {
            await speechService.toggleRecording()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
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
                        .foregroundStyle(secondaryText)

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
                                .foregroundStyle(primaryText)

                            Text("You chose")
                                .font(.caption2)
                                .foregroundStyle(primaryText)
                        }
                    } else if plainText.count > 10 {
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                                .font(.caption2)
                                .foregroundStyle(primaryText)

                            Text("Detected on device")
                                .font(.caption2)
                                .foregroundStyle(primaryText)
                        }
                    } else {
                        Text("\(plainText.count) chars")
                            .font(.caption2)
                            .foregroundStyle(tertiaryText)
                    }
                }
            }

            if plainText.count > 10 {
                scoreBar
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
        .animation(.easeInOut(duration: 0.3), value: finalMood)
    }

    private var scoreBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("😢 Negative")
                    .font(.caption2)
                    .foregroundStyle(secondaryText)

                Spacer()

                Text("Positive 😊")
                    .font(.caption2)
                    .foregroundStyle(secondaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(chipBackground)
                        .frame(height: 6)

                    let score = sentimentService
                        .analyze(text: plainText).score
                    let displayScore = (score + 1) / 2

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.72),
                                    Color.gray.opacity(0.72),
                                    Color.green.opacity(0.72)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                8,
                                geo.size.width * CGFloat(displayScore)
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
                .fontWeight(.medium)
                .foregroundStyle(.red)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    Color.red.opacity(
                        colorScheme == .dark ? 0.15 : 0.08
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.20), lineWidth: 1)
                )
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
                        .foregroundStyle(primaryText)

                    Text("Reflection Prompts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .rotationEffect(.degrees(showingPrompts ? 180 : 0))
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: showingPrompts
                        )
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if showingPrompts {
                VStack(spacing: 8) {
                    ForEach(finalMood.reflectionPrompts, id: \.self) { prompt in
                        Button {
                            appendToRichText("\n\(prompt)\n\n")
                            selectedPrompt = prompt

                            withAnimation {
                                showingPrompts = false
                            }
                        } label: {
                            HStack {
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundStyle(primaryText)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(primaryText)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(borderColor, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(
                    .opacity.combined(with: .move(edge: .top))
                )
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Tags and Emojis
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
                        .foregroundStyle(primaryText)

                    Text("Add Tags & Emojis")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)

                    if !selectedTags.isEmpty {
                        Text("(\(selectedTags.count))")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .rotationEffect(.degrees(showingTagSelector ? 180 : 0))
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: showingTagSelector
                        )
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if showingTagSelector {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(secondaryText)

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 80))
                        ],
                        spacing: 8
                    ) {
                        ForEach(availableTags, id: \.self) { tag in
                            let isSelected = selectedTags.contains(tag)

                            Button {
                                toggleTag(tag)
                            } label: {
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(
                                                isSelected
                                                ? primaryButtonBackground
                                                : chipBackground
                                            )
                                    )
                                    .foregroundStyle(
                                        isSelected
                                        ? primaryButtonText
                                        : primaryText
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider()
                        .background(borderColor)

                    Text("Mood Emojis")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(secondaryText)

                    emojiRow(emojis: moodEmojis)

                    Text("Activities")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(secondaryText)

                    emojiRow(emojis: activityEmojis)

                    Text("Feelings")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(secondaryText)

                    emojiRow(emojis: feelingEmojis)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
                .transition(
                    .opacity.combined(with: .move(edge: .top))
                )
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
                                        ? selectedSoftBackground
                                        : chipBackground
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isSelected
                                                ? primaryText.opacity(0.55)
                                                : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .scaleEffect(isSelected ? 1.15 : 1.0)
                            .animation(
                                .spring(response: 0.30, dampingFraction: 0.65),
                                value: isSelected
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Selected Tags
    // --------------------------------------------------------
    private var selectedTagsDisplay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected")
                .font(.caption)
                .foregroundStyle(secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)

                            Button {
                                selectedTags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(chipBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                        .foregroundStyle(primaryText)
                    }
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Mood Override
    // --------------------------------------------------------
    private var moodOverrideBar: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundStyle(primaryText)

                Text("Override Mood")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(secondaryText)

                Spacer()

                if userHasOverridden {
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                            userHasOverridden = false
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)

                            Text("Use Detection")
                                .font(.caption2)
                        }
                        .foregroundStyle(primaryText)
                    }
                }
            }

            HStack(spacing: 0) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    let isSelected = finalMood == mood

                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.65)) {
                            userSelectedMood = mood
                            userHasOverridden = true
                        }

                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: isSelected ? 28 : 22))
                                .scaleEffect(isSelected ? 1.1 : 1.0)

                            Circle()
                                .fill(isSelected ? mood.color : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    isSelected
                                    ? selectedSoftBackground
                                    : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(editorBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1)
                    )
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
                .underlineStyle,
                range: range
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
            .font,
            in: range,
            options: []
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
                .font,
                value: newFont,
                range: subRange
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
                .font: UIFont.preferredFont(forTextStyle: .body),
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

        mutable.append(
            NSAttributedString(
                string: text,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label
                ]
            )
        )

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

    // --------------------------------------------------------
    // MARK: - Speech
    // --------------------------------------------------------
    private func appendSpeechDelta(_ text: String) {
        guard !text.isEmpty else {
            lastSpeechTranscript = ""
            return
        }

        let addition: String

        if text.hasPrefix(lastSpeechTranscript) {
            addition = String(
                text.dropFirst(lastSpeechTranscript.count)
            )
        } else {
            addition = text
        }

        lastSpeechTranscript = text

        guard !addition.isEmpty else { return }

        appendToRichText(addition)
    }

    // --------------------------------------------------------
    // MARK: - Image
    // --------------------------------------------------------
    private func loadImage(
        from item: PhotosPickerItem?
    ) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    insertImage(image)
                }
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
            x: 0,
            y: 0,
            width: maxWidth,
            height: image.size.height * scale
        )

        attachment.image = image

        mutable.append(
            NSAttributedString(attachment: attachment)
        )

        mutable.append(
            NSAttributedString(
                string: "\n",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label
                ]
            )
        )

        attributedText = mutable
        plainText = mutable.string
    }

    // --------------------------------------------------------
    // MARK: - Load / Save
    // --------------------------------------------------------
    private func loadExistingEntry(_ entry: JournalEntry) {
        if let data = entry.richTextData,
           let restored = try? NSAttributedString(
            data: data,
            options: [
                .documentType:
                    NSAttributedString.DocumentType.rtfd
            ],
            documentAttributes: nil
           ) {
            attributedText = restored
        } else {
            attributedText = NSAttributedString(
                string: entry.text,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
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

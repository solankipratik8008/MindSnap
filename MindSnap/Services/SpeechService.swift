//
//  SpeechService.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-22.
//

// ============================================================
// SpeechService.swift
// MindSnap — Voice input and speech transcription service
//
// WHAT THIS FILE DOES:
// Handles everything related to voice recording and
// speech-to-text transcription using Apple's Speech framework.
//
// HOW IT WORKS:
// 1. User taps mic button → we start recording
// 2. Apple's SFSpeechRecognizer listens in real-time
// 3. Words appear in the text editor AS the user speaks
// 4. User taps mic again → recording stops
// 5. Final transcription is kept in the text editor
//
// COMPLETELY ON-DEVICE:
// Uses Apple's Speech framework with on-device recognition.
// No audio is sent to any server.
// Works offline after initial setup.
//
// MVVM ROLE: Service layer
//            Called by EntryEditorView.
//            Handles ONE job — speech transcription.
// ============================================================

import Speech        // Apple's speech recognition framework
import AVFoundation  // For audio recording engine
import SwiftUI       // For @Observable

// --------------------------------------------------------
// SpeechService
//
// @Observable so EntryEditorView can react to:
//   - isRecording changes (update mic button UI)
//   - transcribedText changes (update text editor)
//   - errorMessage changes (show error if needed)
// --------------------------------------------------------
@Observable
final class SpeechService: NSObject {

    // --------------------------------------------------------
    // isRecording — Is the mic currently active?
    //
    // true  = recording in progress → show stop button
    // false = not recording → show start button
    // EntryEditorView reads this to animate the mic button
    // --------------------------------------------------------
    var isRecording = false

    // --------------------------------------------------------
    // transcribedText — Live transcription result
    //
    // Updates in REAL-TIME as user speaks.
    // EntryEditorView appends this to the journal text.
    // --------------------------------------------------------
    var transcribedText = ""

    // --------------------------------------------------------
    // errorMessage — Any error that occurred
    //
    // nil    = no error
    // String = show this to the user
    // --------------------------------------------------------
    var errorMessage: String? = nil

    // --------------------------------------------------------
    // isAvailable — Can this device use speech recognition?
    //
    // Some devices/regions may not support it.
    // EntryEditorView reads this to show/hide the mic button.
    // --------------------------------------------------------
    var isAvailable = false

    // --------------------------------------------------------
    // Private properties — Internal speech recognition setup
    // --------------------------------------------------------

    // SFSpeechRecognizer — Apple's speech recognition engine
    // Locale.current means it uses the device's language
    private var speechRecognizer: SFSpeechRecognizer?

    // The current recognition request
    // Feeds audio buffers to the recognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    // The current recognition task
    // We keep a reference so we can cancel it
    private var recognitionTask: SFSpeechRecognitionTask?

    // AVAudioEngine — captures audio from the microphone
    private let audioEngine = AVAudioEngine()
    private var inputTapInstalled = false
    private var isStartingRecording = false

    // --------------------------------------------------------
    // init()
    //
    // Set up the speech recognizer and check availability.
    // --------------------------------------------------------
    override init() {
        super.init()
        // Use device's current locale for best accuracy
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        speechRecognizer?.delegate = self
        checkAvailability()
    }

    deinit {
        cleanupRecognition(cancelTask: true)
        speechRecognizer?.delegate = nil
        speechRecognizer = nil
    }

    // --------------------------------------------------------
    // MARK: - Public Methods
    // --------------------------------------------------------

    // --------------------------------------------------------
    // requestPermission()
    //
    // Asks user for speech recognition permission.
    // iOS shows a system alert the first time.
    // Returns true if granted, false if denied.
    // --------------------------------------------------------
    func requestPermission() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        // Request microphone permission
        let micStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        let granted = speechStatus == .authorized && micStatus
        await MainActor.run {
            isAvailable = granted
        }
        return granted
    }

    // --------------------------------------------------------
    // startRecording()
    //
    // Starts capturing audio and transcribing in real-time.
    //
    // Steps:
    //   1. Check/request permissions
    //   2. Set up audio session for recording
    //   3. Create recognition request
    //   4. Start audio engine
    //   5. Feed audio to recognizer
    //   6. Get real-time transcription results
    // --------------------------------------------------------
    func startRecording() async {
        guard !isRecording && !isStartingRecording else { return }
        isStartingRecording = true
        defer { isStartingRecording = false }

        // ---- Step 1: Check permissions ----

        if !isAvailable {
            let granted = await requestPermission()
            if !granted {
                await MainActor.run {
                    errorMessage = "Please enable microphone and speech recognition in iOS Settings."
                }
                return
            }
        }

        // ---- Step 2: Cancel any existing task ----
        guard speechRecognizer?.supportsOnDeviceRecognition == true else {
            await MainActor.run {
                isAvailable = false
                errorMessage = "On-device speech recognition is not available for your current language or device."
            }
            return
        }

        cleanupRecognition(cancelTask: true, deactivateSession: false)

        // ---- Step 3: Set up audio session ----
        // AVAudioSession manages the audio hardware
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // .record = we want to record audio
            // .measurement = accurate audio levels
            // .duckOthers = lower other audio while recording
            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: .duckOthers
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            await MainActor.run {
                errorMessage = "Could not set up audio session."
            }
            return
        }

        // ---- Step 4: Create recognition request ----
        // SFSpeechAudioBufferRecognitionRequest processes
        // audio buffers from the microphone in real-time
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            await MainActor.run {
                errorMessage = "Could not create recognition request."
            }
            return
        }

        // shouldReportPartialResults = true means we get
        // transcription updates AS the user speaks
        // (not just at the end)
        recognitionRequest.shouldReportPartialResults = true

        // Privacy promise: never fall back to server recognition.
        recognitionRequest.requiresOnDeviceRecognition = true

        // ---- Step 5: Start recognition task ----
        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest
        ) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                // Update transcribed text with latest result
                // .bestTranscription is the most accurate version
                let newText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    guard self.isRecording else { return }
                    self.transcribedText = newText
                }
                isFinal = result.isFinal
            }

            // Stop if final result or error
            if error != nil || isFinal {
                DispatchQueue.main.async {
                    self.cleanupRecognition(cancelTask: false)
                }
            }
        }

        // ---- Step 6: Set up audio engine ----
        // inputNode = the microphone input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // installTap captures audio buffers
        // bufferSize: 1024 = process 1024 samples at a time
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { [weak self] buffer, _ in
            // Feed each audio buffer to the recognizer
            self?.recognitionRequest?.append(buffer)
        }
        inputTapInstalled = true

        // ---- Step 7: Start the audio engine ----
        audioEngine.prepare()
        do {
            try audioEngine.start()
            await MainActor.run {
                isRecording = true
                transcribedText = ""
                errorMessage = nil
            }
        } catch {
            cleanupRecognition(cancelTask: true)
            await MainActor.run {
                errorMessage = "Could not start audio engine."
            }
        }
    }

    // --------------------------------------------------------
    // stopRecording()
    //
    // Stops the audio engine and finalizes transcription.
    // Called when user taps the mic button again.
    // --------------------------------------------------------
    func stopRecording() {
        // Signal end of audio to the recognizer
        // This triggers the final transcription result
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        cleanupRecognition(cancelTask: false)
    }

    func cancelRecording() {
        cleanupRecognition(cancelTask: true)
    }

    // --------------------------------------------------------
    // toggleRecording()
    //
    // Convenience method — tap once to start, tap again to stop.
    // This is what EntryEditorView calls on button tap.
    // --------------------------------------------------------
    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }

    // --------------------------------------------------------
    // MARK: - Private Helpers
    // --------------------------------------------------------

    // --------------------------------------------------------
    // checkAvailability()
    //
    // Checks if speech recognition is available on this device.
    // --------------------------------------------------------
    private func checkAvailability() {
        isAvailable =
            (speechRecognizer?.isAvailable ?? false) &&
            (speechRecognizer?.supportsOnDeviceRecognition ?? false)
    }

    private func cleanupRecognition(
        cancelTask: Bool,
        deactivateSession: Bool = true
    ) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if inputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            inputTapInstalled = false
        }
        audioEngine.reset()

        recognitionRequest?.endAudio()
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionTask = nil
        recognitionRequest = nil

        if deactivateSession {
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        }

        isRecording = false
    }
}

// ============================================================
// MARK: - SFSpeechRecognizerDelegate
//
// Called when speech recognizer availability changes.
// e.g. when user goes offline and on-device recognition
// is not available.
// ============================================================
extension SpeechService: SFSpeechRecognizerDelegate {
    func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ) {
        DispatchQueue.main.async {
            guard self.speechRecognizer === speechRecognizer else { return }
            self.isAvailable =
                available &&
                speechRecognizer.supportsOnDeviceRecognition
        }
    }
}

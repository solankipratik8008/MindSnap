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
// SAFE UPDATE:
// 1. Keeps the same speech-to-text functionality
// 2. Prevents SwiftUI Observation crash:
//    "AttributeGraph precondition failure: setting value during update"
// 3. Ignores private audio/task objects from SwiftUI observation
// 4. Updates UI-facing values safely on the main queue
//
// FUNCTIONALITY KEPT:
// 1. Mic permission request
// 2. Speech recognition permission request
// 3. On-device speech recognition only
// 4. Live transcription
// 5. Start / stop / cancel recording
// ============================================================

import Speech
import AVFoundation
import SwiftUI
import Observation

// --------------------------------------------------------
// SpeechService
// --------------------------------------------------------
@Observable
final class SpeechService: NSObject {

    // --------------------------------------------------------
    // UI-facing observable state
    // --------------------------------------------------------
    var isRecording = false
    var transcribedText = ""
    var errorMessage: String? = nil
    var isAvailable = false

    // --------------------------------------------------------
    // Private non-UI properties
    //
    // IMPORTANT:
    // These should not be observed by SwiftUI.
    // They are internal audio/speech engine objects.
    // --------------------------------------------------------
    @ObservationIgnored
    private var speechRecognizer: SFSpeechRecognizer?

    @ObservationIgnored
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    @ObservationIgnored
    private var recognitionTask: SFSpeechRecognitionTask?

    @ObservationIgnored
    private let audioEngine = AVAudioEngine()

    @ObservationIgnored
    private var inputTapInstalled = false

    @ObservationIgnored
    private var isStartingRecording = false

    // --------------------------------------------------------
    // init()
    // --------------------------------------------------------
    override init() {
        super.init()

        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        speechRecognizer?.delegate = self

        checkAvailability()
    }

    deinit {
        cleanupRecognition(
            cancelTask: true,
            updateRecordingState: false
        )

        speechRecognizer?.delegate = nil
        speechRecognizer = nil
    }

    // --------------------------------------------------------
    // MARK: - Public Methods
    // --------------------------------------------------------

    func requestPermission() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        let granted = speechStatus == .authorized && micStatus

        await MainActor.run {
            self.isAvailable = granted
        }

        return granted
    }

    func startRecording() async {
        guard !isRecording && !isStartingRecording else { return }

        isStartingRecording = true
        defer { isStartingRecording = false }

        // ---- Step 1: Check permissions ----
        if !isAvailable {
            let granted = await requestPermission()

            if !granted {
                await MainActor.run {
                    self.errorMessage = "Please enable microphone and speech recognition in iOS Settings."
                }
                return
            }
        }

        // ---- Step 2: Make sure on-device recognition is available ----
        guard speechRecognizer?.supportsOnDeviceRecognition == true else {
            await MainActor.run {
                self.isAvailable = false
                self.errorMessage = "On-device speech recognition is not available for your current language or device."
            }
            return
        }

        // Clean previous recognition objects before starting a new session.
        // Do NOT update isRecording here, because we are about to set it true.
        cleanupRecognition(
            cancelTask: true,
            deactivateSession: false,
            updateRecordingState: false
        )

        // ---- Step 3: Set up audio session ----
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: .duckOthers
            )

            try audioSession.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            await MainActor.run {
                self.errorMessage = "Could not set up audio session."
            }
            return
        }

        // ---- Step 4: Create recognition request ----
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            await MainActor.run {
                self.errorMessage = "Could not create recognition request."
            }
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true

        // ---- Step 5: Start recognition task ----
        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest
        ) { [weak self] result, error in
            guard let self else { return }

            var isFinal = false

            if let result = result {
                let newText = result.bestTranscription.formattedString

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard self.isRecording else { return }

                    self.transcribedText = newText
                }

                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                DispatchQueue.main.async { [weak self] in
                    self?.cleanupRecognition(
                        cancelTask: false,
                        updateRecordingState: true
                    )
                }
            }
        }

        // ---- Step 6: Set up audio engine ----
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        inputTapInstalled = true

        // ---- Step 7: Start audio engine ----
        audioEngine.prepare()

        do {
            try audioEngine.start()

            await MainActor.run {
                self.isRecording = true
                self.transcribedText = ""
                self.errorMessage = nil
            }
        } catch {
            cleanupRecognition(
                cancelTask: true,
                updateRecordingState: true
            )

            await MainActor.run {
                self.errorMessage = "Could not start audio engine."
            }
        }
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        recognitionTask?.finish()

        cleanupRecognition(
            cancelTask: false,
            updateRecordingState: true
        )
    }

    func cancelRecording() {
        cleanupRecognition(
            cancelTask: true,
            updateRecordingState: true
        )
    }

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

    private func checkAvailability() {
        let available =
            (speechRecognizer?.isAvailable ?? false) &&
            (speechRecognizer?.supportsOnDeviceRecognition ?? false)

        DispatchQueue.main.async { [weak self] in
            self?.isAvailable = available
        }
    }

    private func cleanupRecognition(
        cancelTask: Bool,
        deactivateSession: Bool = true,
        updateRecordingState: Bool = true
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

        // IMPORTANT:
        // Do not set isRecording directly here.
        // Dispatching prevents:
        // "AttributeGraph precondition failure: setting value during update"
        if updateRecordingState {
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = false
            }
        }
    }
}

// ============================================================
// MARK: - SFSpeechRecognizerDelegate
// ============================================================
extension SpeechService: SFSpeechRecognizerDelegate {

    func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.speechRecognizer === speechRecognizer else { return }

            self.isAvailable =
                available &&
                speechRecognizer.supportsOnDeviceRecognition
        }
    }
}

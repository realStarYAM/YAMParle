//
//  SpeechService.swift
//  YAMParle
//

import AVFoundation
import SwiftUI

@MainActor
@Observable
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private var activeRequestID: UUID?
    private var activeUtterance: AVSpeechUtterance?

    var isSpeaking: Bool = false
    var currentSpokenText: String = ""

    // Engine: "apple" or "elevenlabs"
    var preferredEngine: String {
        didSet {
            UserDefaults.standard.set(preferredEngine, forKey: "yamparle_preferred_engine")
        }
    }

    // Settings persisted via UserDefaults
    var selectedVoiceIdentifier: String {
        didSet {
            UserDefaults.standard.set(selectedVoiceIdentifier, forKey: "yamparle_voice_id")
        }
    }

    var rate: Float {
        didSet {
            UserDefaults.standard.set(rate, forKey: "yamparle_speech_rate")
        }
    }

    var pitch: Float {
        didSet {
            UserDefaults.standard.set(pitch, forKey: "yamparle_speech_pitch")
        }
    }

    var volume: Float {
        didSet {
            UserDefaults.standard.set(volume, forKey: "yamparle_speech_volume")
        }
    }

    var speakOnTap: Bool {
        didSet {
            UserDefaults.standard.set(speakOnTap, forKey: "yamparle_speak_on_tap")
        }
    }

    var clearAfterSpeaking: Bool {
        didSet {
            UserDefaults.standard.set(clearAfterSpeaking, forKey: "yamparle_clear_after_speaking")
        }
    }

    override init() {
        self.preferredEngine = UserDefaults.standard.string(forKey: "yamparle_preferred_engine") ?? "apple"

        let savedVoice = UserDefaults.standard.string(forKey: "yamparle_voice_id")
        let defaultVoice = AVSpeechSynthesisVoice(language: "fr-FR")?.identifier ?? ""
        self.selectedVoiceIdentifier = savedVoice ?? defaultVoice

        let savedRate = UserDefaults.standard.float(forKey: "yamparle_speech_rate")
        self.rate = savedRate > 0 ? savedRate : AVSpeechUtteranceDefaultSpeechRate

        let savedPitch = UserDefaults.standard.float(forKey: "yamparle_speech_pitch")
        self.pitch = savedPitch > 0 ? savedPitch : 1.0

        let savedVolume = UserDefaults.standard.float(forKey: "yamparle_speech_volume")
        self.volume = UserDefaults.standard.object(forKey: "yamparle_speech_volume") != nil ? savedVolume : 1.0

        self.speakOnTap = UserDefaults.standard.bool(forKey: "yamparle_speak_on_tap")
        self.clearAfterSpeaking = UserDefaults.standard.bool(forKey: "yamparle_clear_after_speaking")

        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration error: \(error)")
        }
    }

    var availableFrenchVoices: [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let frVoices = allVoices.filter { $0.language.lowercased().hasPrefix("fr") }
        if frVoices.isEmpty {
            return allVoices
        }
        return frVoices.sorted { $0.name < $1.name }
    }

    // MARK: - Smart Unified Speak (with Offline fallback)
    func speakItem(_ item: AACItem) {
        let requestID = beginRequest(text: item.text)

        if item.audioSourceType == "recording", let fileName = item.localAudioFileName, !fileName.isEmpty,
           AudioRecorderService.shared.fileExists(fileName: fileName) {
            AudioRecorderService.shared.playAudio(fileName: fileName, onFinished: completion(for: requestID))
            return
        }

        if item.audioSourceType == "elevenlabs", speakElevenLabs(text: item.spokenText, requestID: requestID) {
            return
        }

        speakAppleVoice(text: item.spokenText, requestID: requestID)
    }

    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let requestID = beginRequest(text: trimmed)

        if preferredEngine == "elevenlabs", speakElevenLabs(text: trimmed, requestID: requestID) {
            return
        }

        speakAppleVoice(text: trimmed, requestID: requestID)
    }

    private func beginRequest(text: String) -> UUID {
        stop()
        let requestID = UUID()
        activeRequestID = requestID
        // Pending generation is stoppable too, before any audio starts.
        isSpeaking = true
        currentSpokenText = text
        return requestID
    }

    private func finishRequest(_ requestID: UUID) {
        guard activeRequestID == requestID else { return }
        activeRequestID = nil
        activeUtterance = nil
        isSpeaking = false
        currentSpokenText = ""
    }

    private func completion(for requestID: UUID) -> () -> Void {
        { [weak self] in
            Task { @MainActor in
                self?.finishRequest(requestID)
            }
        }
    }

    private func speakElevenLabs(text: String, requestID: UUID) -> Bool {
        if let cached = ElevenLabsService.shared.getCachedFile(for: text) {
            ElevenLabsService.shared.playCachedItem(cached, onFinished: completion(for: requestID))
            return true
        }
        guard ElevenLabsService.shared.hasApiKey else { return false }

        ElevenLabsService.shared.generateAndCache(text: text) { [weak self] result in
            Task { @MainActor in
                // Let generation populate the cache, but never revive interrupted speech.
                guard let self = self, self.activeRequestID == requestID else { return }
                switch result {
                case .success(let cached):
                    ElevenLabsService.shared.playCachedItem(cached, onFinished: self.completion(for: requestID))
                case .failure:
                    self.speakAppleVoice(text: text, requestID: requestID)
                }
            }
        }
        return true
    }

    private func speakAppleVoice(text: String, requestID: UUID, rateMultiplier: Float = 1.0) {
        guard activeRequestID == requestID else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            finishRequest(requestID)
            return
        }

        setupAudioSession()

        let utterance = AVSpeechUtterance(string: trimmed)

        if !selectedVoiceIdentifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        }

        utterance.rate = min(max(rate * rateMultiplier, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = min(max(pitch, 0.5), 2.0)
        utterance.volume = min(max(volume, 0.0), 1.0)

        currentSpokenText = trimmed
        activeUtterance = utterance
        synthesizer.speak(utterance)
    }

    func stop() {
        // Invalidate identities before stopping engines, which can deliver callbacks.
        activeRequestID = nil
        activeUtterance = nil
        isSpeaking = false
        currentSpokenText = ""
        synthesizer.stopSpeaking(at: .immediate)
        ElevenLabsService.shared.stopPlayback()
        AudioRecorderService.shared.stopPlayback()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard let activeUtterance = self.activeUtterance,
                  ObjectIdentifier(activeUtterance) == utteranceID else { return }
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finishUtterance(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finishUtterance(utterance)
    }

    private nonisolated func finishUtterance(_ utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard let activeUtterance = self.activeUtterance,
                  ObjectIdentifier(activeUtterance) == utteranceID,
                  let requestID = self.activeRequestID else { return }
            self.finishRequest(requestID)
        }
    }
}

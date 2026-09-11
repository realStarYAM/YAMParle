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
        // 1. Personal microphone recording
        if item.audioSourceType == "recording", let fileName = item.localAudioFileName, !fileName.isEmpty {
            if AudioRecorderService.shared.fileExists(fileName: fileName) {
                isSpeaking = true
                currentSpokenText = item.text
                AudioRecorderService.shared.playAudio(fileName: fileName) { [weak self] in
                    self?.isSpeaking = false
                    self?.currentSpokenText = ""
                }
                return
            }
        }

        // 2. ElevenLabs
        if item.audioSourceType == "elevenlabs" {
            // Check if cached locally
            if let cached = ElevenLabsService.shared.getCachedFile(for: item.spokenText) {
                isSpeaking = true
                currentSpokenText = item.text
                ElevenLabsService.shared.playCachedItem(cached) { [weak self] in
                    self?.isSpeaking = false
                    self?.currentSpokenText = ""
                }
                return
            } else if ElevenLabsService.shared.hasApiKey {
                // Attempt to stream/cache online
                ElevenLabsService.shared.generateAndCache(text: item.spokenText) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let cached):
                        self.isSpeaking = true
                        self.currentSpokenText = item.text
                        ElevenLabsService.shared.playCachedItem(cached) { [weak self] in
                            self?.isSpeaking = false
                            self?.currentSpokenText = ""
                        }
                    case .failure:
                        // Offline or error fallback: never block communication!
                        self.speakAppleVoice(text: item.spokenText)
                    }
                }
                return
            }
        }

        // 3. Apple Voice fallback or primary
        speakAppleVoice(text: item.spokenText)
    }

    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Check if ElevenLabs is the preferred engine and has a cached file or online capability
        if preferredEngine == "elevenlabs" {
            if let cached = ElevenLabsService.shared.getCachedFile(for: trimmed) {
                isSpeaking = true
                currentSpokenText = trimmed
                ElevenLabsService.shared.playCachedItem(cached) { [weak self] in
                    self?.isSpeaking = false
                    self?.currentSpokenText = ""
                }
                return
            } else if ElevenLabsService.shared.hasApiKey {
                ElevenLabsService.shared.generateAndCache(text: trimmed) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let cached):
                        self.isSpeaking = true
                        self.currentSpokenText = trimmed
                        ElevenLabsService.shared.playCachedItem(cached) { [weak self] in
                            self?.isSpeaking = false
                            self?.currentSpokenText = ""
                        }
                    case .failure:
                        self.speakAppleVoice(text: trimmed)
                    }
                }
                return
            }
        }

        speakAppleVoice(text: trimmed)
    }

    private func speakAppleVoice(text: String, rateMultiplier: Float = 1.0) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
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
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            currentSpokenText = ""
        }
        ElevenLabsService.shared.stopPlayback()
        AudioRecorderService.shared.stopPlayback()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentSpokenText = ""
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentSpokenText = ""
        }
    }
}

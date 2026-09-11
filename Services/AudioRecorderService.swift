//
//  AudioRecorderService.swift
//  YAMParle
//

import Foundation
import AVFoundation

@Observable
final class AudioRecorderService: NSObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    static let shared = AudioRecorderService()

    var isRecording: Bool = false
    var isPlaying: Bool = false
    var currentlyPlayingFileName: String? = nil
    var recordingDuration: TimeInterval = 0
    var errorMessage: String? = nil

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    private var recordingsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("AudioRecordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    override init() {
        super.init()
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startRecording(fileName: String? = nil) -> String? {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            errorMessage = "Impossible de configurer le microphone: \(error.localizedDescription)"
            return nil
        }

        let recordingId = fileName ?? "rec_\(UUID().uuidString).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(recordingId)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            recordingDuration = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingDuration = self.audioRecorder?.currentTime ?? 0
            }
            return recordingId
        } catch {
            errorMessage = "Échec du démarrage de l'enregistrement: \(error.localizedDescription)"
            isRecording = false
            return nil
        }
    }

    func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
    }

    func playAudio(fileName: String, onFinished: (() -> Void)? = nil) {
        stopPlayback()

        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            errorMessage = "Fichier audio introuvable"
            onFinished?()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            currentlyPlayingFileName = fileName
        } catch {
            errorMessage = "Impossible de lire le fichier: \(error.localizedDescription)"
            isPlaying = false
            currentlyPlayingFileName = nil
            onFinished?()
        }
    }

    func stopPlayback() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingFileName = nil
    }

    func fileExists(fileName: String) -> Bool {
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    func deleteAudio(fileName: String) {
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
        if currentlyPlayingFileName == fileName {
            stopPlayback()
        }
    }

    func getFileURL(fileName: String) -> URL {
        recordingsDirectory.appendingPathComponent(fileName)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlayingFileName = nil
        }
    }
}

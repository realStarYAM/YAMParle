//
//  ElevenLabsService.swift
//  YAMParle
//

import Foundation
import AVFoundation

struct ElevenLabsCachedItem: Identifiable, Equatable {
    let id: String
    let phrase: String
    let voiceName: String
    let voiceId: String
    let fileName: String
    let fileSize: String
    let date: Date
    let localUrl: URL
}

@Observable
final class ElevenLabsService: NSObject, AVAudioPlayerDelegate {
    static let shared = ElevenLabsService()

    private let keychainApiKeyName = "yamparle_elevenlabs_api_key"

    var voiceId: String {
        didSet {
            UserDefaults.standard.set(voiceId, forKey: "yamparle_elevenlabs_voice_id")
        }
    }

    var selectedModelId: String {
        didSet {
            UserDefaults.standard.set(selectedModelId, forKey: "yamparle_elevenlabs_model_id")
        }
    }

    var voiceName: String {
        didSet {
            UserDefaults.standard.set(voiceName, forKey: "yamparle_elevenlabs_voice_name")
        }
    }

    var isGenerating: Bool = false
    var isPlaying: Bool = false
    var currentlyPlayingId: String? = nil
    var errorMessage: String? = nil
    var cachedItems: [ElevenLabsCachedItem] = []

    private var audioPlayer: AVAudioPlayer?

    let availableModels = [
        ("eleven_multilingual_v2", "Multilingue v2 (Recommandé)"),
        ("eleven_flash_v2_5", "Flash v2.5 (Ultra-rapide)"),
        ("eleven_turbo_v2_5", "Turbo v2.5 (Haute vitesse)")
    ]

    var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("ElevenLabsCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    override init() {
        self.voiceId = UserDefaults.standard.string(forKey: "yamparle_elevenlabs_voice_id") ?? "21m00Tcm4TlvDq8ikWAM"
        self.selectedModelId = UserDefaults.standard.string(forKey: "yamparle_elevenlabs_model_id") ?? "eleven_multilingual_v2"
        self.voiceName = UserDefaults.standard.string(forKey: "yamparle_elevenlabs_voice_name") ?? "Rachel (Français)"
        super.init()
        loadCachedItems()
    }

    // MARK: - Secure API Key Storage
    func getApiKey() -> String? {
        KeychainService.load(key: keychainApiKeyName)
    }

    func setApiKey(_ key: String) {
        if key.isEmpty {
            KeychainService.delete(key: keychainApiKeyName)
        } else {
            KeychainService.save(key: keychainApiKeyName, value: key.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    var hasApiKey: Bool {
        guard let key = getApiKey(), !key.isEmpty else { return false }
        return true
    }

    var maskedApiKey: String {
        KeychainService.maskedKey(getApiKey())
    }

    // MARK: - Generation & Caching
    func generateAndCache(text: String, voiceIdOverride: String? = nil, voiceNameOverride: String? = nil, completion: @escaping (Result<ElevenLabsCachedItem, Error>) -> Void) {
        guard let apiKey = getApiKey(), !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "ElevenLabs", code: 401, userInfo: [NSLocalizedDescriptionKey: "Clé API ElevenLabs manquante. Veuillez la configurer dans Réglages > Parole et Son."])))
            return
        }

        let targetVoiceId = voiceIdOverride ?? self.voiceId
        let targetVoiceName = voiceNameOverride ?? self.voiceName
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            completion(.failure(NSError(domain: "ElevenLabs", code: 400, userInfo: [NSLocalizedDescriptionKey: "Le texte est vide."])))
            return
        }

        isGenerating = true
        errorMessage = nil

        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(targetVoiceId)"
        guard let url = URL(string: urlString) else {
            isGenerating = false
            completion(.failure(NSError(domain: "ElevenLabs", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let payload: [String: Any] = [
            "text": cleanText,
            "model_id": selectedModelId,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            isGenerating = false
            completion(.failure(NSError(domain: "ElevenLabs", code: 400, userInfo: [NSLocalizedDescriptionKey: "Erreur d'encodage de la requête"])))
            return
        }
        request.httpBody = bodyData

        let session = URLSession(configuration: .default)
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isGenerating = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let message = "Erreur ElevenLabs (\(httpResponse.statusCode))"
                    self.errorMessage = message
                    completion(.failure(NSError(domain: "ElevenLabs", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    return
                }

                guard let audioData = data, !audioData.isEmpty else {
                    let err = NSError(domain: "ElevenLabs", code: 204, userInfo: [NSLocalizedDescriptionKey: "Aucune donnée audio reçue"])
                    self.errorMessage = err.localizedDescription
                    completion(.failure(err))
                    return
                }

                // Save audio file locally
                let fileId = UUID().uuidString
                let fileName = "el_\(fileId).mp3"
                let fileURL = self.cacheDirectory.appendingPathComponent(fileName)

                do {
                    try audioData.write(to: fileURL)

                    // Save metadata plist
                    let metaDict: [String: Any] = [
                        "phrase": cleanText,
                        "voiceName": targetVoiceName,
                        "voiceId": targetVoiceId,
                        "date": Date()
                    ]
                    let metaURL = self.cacheDirectory.appendingPathComponent("el_\(fileId).plist")
                    (metaDict as NSDictionary).write(to: metaURL, atomically: true)

                    self.loadCachedItems()

                    if let cached = self.cachedItems.first(where: { $0.fileName == fileName }) {
                        completion(.success(cached))
                    } else {
                        let item = ElevenLabsCachedItem(
                            id: fileId,
                            phrase: cleanText,
                            voiceName: targetVoiceName,
                            voiceId: targetVoiceId,
                            fileName: fileName,
                            fileSize: "\(audioData.count / 1024) Ko",
                            date: Date(),
                            localUrl: fileURL
                        )
                        completion(.success(item))
                    }
                } catch {
                    self.errorMessage = "Échec d'enregistrement du fichier audio: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Load & Manage Cached Items
    func loadCachedItems() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else {
            cachedItems = []
            return
        }

        var results: [ElevenLabsCachedItem] = []
        let audioFiles = files.filter { $0.pathExtension == "mp3" }

        for fileURL in audioFiles {
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let metaURL = cacheDirectory.appendingPathComponent("\(baseName).plist")

            var phrase = "Phrase personnalisée"
            var vName = self.voiceName
            var vId = self.voiceId
            var date = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()

            if let dict = NSDictionary(contentsOf: metaURL) as? [String: Any] {
                phrase = dict["phrase"] as? String ?? phrase
                vName = dict["voiceName"] as? String ?? vName
                vId = dict["voiceId"] as? String ?? vId
                if let metaDate = dict["date"] as? Date {
                    date = metaDate
                }
            }

            let sizeBytes = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            let sizeString = "\(max(1, sizeBytes / 1024)) Ko"

            let item = ElevenLabsCachedItem(
                id: baseName,
                phrase: phrase,
                voiceName: vName,
                voiceId: vId,
                fileName: fileURL.lastPathComponent,
                fileSize: sizeString,
                date: date,
                localUrl: fileURL
            )
            results.append(item)
        }

        cachedItems = results.sorted(by: { $0.date > $1.date })
    }

    func deleteCachedItem(_ item: ElevenLabsCachedItem) {
        stopPlayback()
        try? FileManager.default.removeItem(at: item.localUrl)
        let metaURL = cacheDirectory.appendingPathComponent("\(item.id).plist")
        try? FileManager.default.removeItem(at: metaURL)
        loadCachedItems()
    }

    // MARK: - Playback
    func playCachedItem(_ item: ElevenLabsCachedItem, onFinished: (() -> Void)? = nil) {
        playFile(url: item.localUrl, identifier: item.id, onFinished: onFinished)
    }

    func playFile(url: URL, identifier: String, onFinished: (() -> Void)? = nil) {
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            currentlyPlayingId = identifier
        } catch {
            errorMessage = "Erreur de lecture: \(error.localizedDescription)"
            isPlaying = false
            currentlyPlayingId = nil
            onFinished?()
        }
    }

    func stopPlayback() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingId = nil
    }

    func getCachedFile(for phrase: String) -> ElevenLabsCachedItem? {
        let clean = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cachedItems.first(where: { $0.phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == clean })
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlayingId = nil
        }
    }
}

//
//  SpeechAndSoundSettingsView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import AVFoundation

struct SpeechAndSoundSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var speechService = SpeechService.shared
    @Bindable var elevenLabsService = ElevenLabsService.shared
    @Bindable var audioRecorder = AudioRecorderService.shared
    @Bindable var themeManager = ThemeManager.shared

    // ElevenLabs setup state
    @State private var apiKeyInput: String = ""
    @State private var showApiKeyPrompt: Bool = false
    @State private var phraseToDownload: String = "Bonjour, ravi de vous voir !"
    @State private var showDownloadSuccess: Bool = false

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        Form {
            mainEngineSection
            appleVoiceSection
            elevenLabsSection
            offlineDownloadSection
            cachedAudioSection
            playbackBehaviorSection
        }
        .navigationTitle("Parole et Son")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fermer") {
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .alert("Configurer la clé API ElevenLabs", isPresented: $showApiKeyPrompt) {
            SecureField("Clé secrète (sk_...)", text: $apiKeyInput)
            Button("Enregistrer") {
                if !apiKeyInput.isEmpty {
                    ElevenLabsService.shared.setApiKey(apiKeyInput)
                }
            }
            Button("Supprimer la clé", role: .destructive) {
                ElevenLabsService.shared.setApiKey("")
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("La clé API sera chiffrée et stockée de manière sécurisée dans le Trousseau de clés (Keychain) de votre appareil.")
        }
        .alert("Téléchargement réussi", isPresented: $showDownloadSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("L'audio a été sauvegardé en local et peut désormais être lu hors ligne.")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var mainEngineSection: some View {
        Section {
            Picker("Moteur de voix", selection: $speechService.preferredEngine) {
                Label("Voix Apple (Intégrée)", systemImage: "apple.logo").tag("apple")
                Label("ElevenLabs (IA Studio)", systemImage: "waveform.circle.fill").tag("elevenlabs")
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)

            if speechService.preferredEngine == "elevenlabs" {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Secours automatique hors-ligne")
                            .font(.subheadline.weight(.bold))
                        Text("Si vous êtes hors ligne, YAMParle utilisera automatiquement les audios téléchargés ou la synthèse Apple locale.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("MOTEUR PRINCIPAL")
                .font(.caption.weight(.bold))
        }
    }

    @ViewBuilder
    private var appleVoiceSection: some View {
        Section {
            Picker("Voix système française", selection: $speechService.selectedVoiceIdentifier) {
                ForEach(speechService.availableFrenchVoices, id: \.identifier) { voice in
                    HStack {
                        Text(voice.name)
                        Spacer()
                        Text(voice.quality == .enhanced ? "Haute qualité" : "Standard")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(voice.quality == .enhanced ? theme.accentColor : .secondary)
                    }
                    .tag(voice.identifier)
                }
            }

            Button {
                speechService.speak(text: "Bonjour ! Voici la voix Apple sélectionnée pour YAMParle.")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.headline)
                    Text("Tester cette voix Apple")
                        .fontWeight(.bold)
                }
                .foregroundColor(theme.accentColor)
            }

            // Vitesse
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Vitesse de parole", systemImage: "speedometer")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1fx", speechService.rate * 2))
                        .font(.caption.bold().monospaced())
                        .foregroundColor(theme.accentColor)
                }
                Slider(
                    value: $speechService.rate,
                    in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate,
                    step: 0.02
                )
                .tint(theme.accentColor)
            }
            .padding(.vertical, 2)

            // Hauteur
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Hauteur (Pitch)", systemImage: "waveform.path")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.2f", speechService.pitch))
                        .font(.caption.bold().monospaced())
                        .foregroundColor(theme.accentColor)
                }
                Slider(
                    value: $speechService.pitch,
                    in: 0.5...1.5,
                    step: 0.05
                )
                .tint(theme.accentColor)
            }
            .padding(.vertical, 2)

            // Volume
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Volume audio", systemImage: "speaker.wave.3.fill")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(speechService.volume * 100))%")
                        .font(.caption.bold().monospaced())
                        .foregroundColor(theme.accentColor)
                }
                Slider(
                    value: $speechService.volume,
                    in: 0.0...1.0,
                    step: 0.05
                )
                .tint(theme.accentColor)
            }
            .padding(.vertical, 2)
        } header: {
            Text("VOIX APPLE (FONCTIONNE SANS INTERNET)")
                .font(.caption.weight(.bold))
        }
    }

    @ViewBuilder
    private var elevenLabsSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clé API ElevenLabs")
                        .font(.subheadline.weight(.semibold))
                    Text(elevenLabsService.hasApiKey ? "Protégée dans le Trousseau (Keychain)" : "Non configurée")
                        .font(.caption2)
                        .foregroundColor(elevenLabsService.hasApiKey ? Color(hex: "#30D158") : .secondary)
                }

                Spacer()

                Button {
                    apiKeyInput = ElevenLabsService.shared.getApiKey() ?? ""
                    showApiKeyPrompt = true
                } label: {
                    Text(elevenLabsService.hasApiKey ? "Modifier" : "Configurer")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.cardBackground)
                        .clipShape(Capsule())
                }
            }

            HStack {
                Text("Voice ID")
                    .font(.subheadline)
                Spacer()
                TextField("Identifiant voix", text: $elevenLabsService.voiceId)
                    .multilineTextAlignment(.trailing)
                    .font(.caption.monospaced())
            }

            Picker("Modèle IA", selection: $elevenLabsService.selectedModelId) {
                ForEach(elevenLabsService.availableModels, id: \.0) { model in
                    Text(model.1).tag(model.0)
                }
            }

            Button {
                elevenLabsService.generateAndCache(text: "Bonjour ! Voici un test de votre voix ElevenLabs de synthèse.") { result in
                    if case .success(let item) = result {
                        elevenLabsService.playCachedItem(item)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if elevenLabsService.isGenerating {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "waveform")
                    }
                    Text(elevenLabsService.isGenerating ? "Génération en cours..." : "Tester la voix ElevenLabs")
                        .fontWeight(.bold)
                }
                .foregroundColor(elevenLabsService.hasApiKey ? theme.accentColor : .secondary)
            }
            .disabled(!elevenLabsService.hasApiKey || elevenLabsService.isGenerating)
        } header: {
            Text("ELEVENLABS (VOIX IA RÉALISTES)")
                .font(.caption.weight(.bold))
        }
    }

    @ViewBuilder
    private var offlineDownloadSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Téléchargez les phrases fréquentes pour les avoir disponibles même dans les transports ou sans réseau.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Ex: J'ai besoin d'aide...", text: $phraseToDownload)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)

                Button {
                    elevenLabsService.generateAndCache(text: phraseToDownload) { result in
                        if case .success = result {
                            showDownloadSuccess = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Télécharger pour utilisation hors ligne")
                    }
                    .fontWeight(.bold)
                }
                .disabled(!elevenLabsService.hasApiKey || phraseToDownload.isEmpty || elevenLabsService.isGenerating)
            }
            .padding(.vertical, 2)
        } header: {
            Text("PRÉ-CHARGEMENT AUDIO HORS LIGNE")
                .font(.caption.weight(.bold))
        }
    }

    @ViewBuilder
    private var cachedAudioSection: some View {
        Section {
            if elevenLabsService.cachedItems.isEmpty {
                Text("Aucun fichier ElevenLabs en cache local.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(elevenLabsService.cachedItems) { item in
                    HStack(spacing: 12) {
                        Button {
                            if elevenLabsService.currentlyPlayingId == item.id {
                                elevenLabsService.stopPlayback()
                            } else {
                                elevenLabsService.playCachedItem(item)
                            }
                        } label: {
                            Image(systemName: elevenLabsService.currentlyPlayingId == item.id ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.accentColor)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.phrase)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text(item.fileSize)
                                Text("•")
                                Text(item.date, style: .date)
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            elevenLabsService.deleteCachedItem(item)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(Color(hex: "#FF3B30").opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text("FICHIERS AUDIO ENREGISTRÉS (\(elevenLabsService.cachedItems.count))")
                .font(.caption.weight(.bold))
        }
    }

    @ViewBuilder
    private var playbackBehaviorSection: some View {
        Section {
            Toggle("Lire immédiatement au toucher", isOn: $speechService.speakOnTap)
            Toggle("Effacer le texte après la lecture", isOn: $speechService.clearAfterSpeaking)
        } header: {
            Text("COMPORTEMENT DE LECTURE")
                .font(.caption.weight(.bold))
        }
    }
}

#Preview {
    NavigationStack {
        SpeechAndSoundSettingsView()
    }
}

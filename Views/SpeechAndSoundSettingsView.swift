//
//  SpeechAndSoundSettingsView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import AVFoundation

/// Réglages de voix, dans l’ordre des besoins : d’abord la voix principale, un essai
/// immédiat, puis le rythme, le comportement de lecture. ElevenLabs, le préchargement
/// et le cache sont une section avancée repliée — rien ici n’oblige à un compte en ligne
/// pour parler avec les voix Apple de l’appareil.
struct SpeechAndSoundSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var speechService = SpeechService.shared
    @Bindable var elevenLabsService = ElevenLabsService.shared
    @Bindable var themeManager = ThemeManager.shared

    @State private var apiKeyInput = ""
    @State private var showApiKeyPrompt = false
    @State private var testPhrase = "Bonjour ! Voici comment je parle avec vous."
    @State private var phraseToDownload = "J’ai besoin d’aide, s’il vous plaît."
    @State private var showDownloadSuccess = false
    @State private var showDownloadFailure = false
    @State private var showAdvanced = false

    private var theme: AppTheme { themeManager.currentTheme }
    private var usesElevenLabs: Bool { speechService.preferredEngine == "elevenlabs" }
    private var canTest: Bool { !testPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        Form {
            mainVoiceSection
            testSection
            rhythmSection
            behaviorSection
            advancedSection
        }
        // Rythme resserré, proche des Réglages natifs d’iPadOS.
        .listSectionSpacing(.compact)
        .contentMargins(.vertical, YAMSpacing.small, for: .scrollContent)
        .navigationTitle("Parole et son")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fermer") { dismiss() }
                    .fontWeight(.bold)
            }
        }
        .onAppear { showAdvanced = usesElevenLabs }
        .alert("Configurer la clé API ElevenLabs", isPresented: $showApiKeyPrompt) {
            SecureField("Clé secrète (sk_...)", text: $apiKeyInput)
            Button("Enregistrer") {
                if !apiKeyInput.isEmpty {
                    elevenLabsService.setApiKey(apiKeyInput)
                }
            }
            Button("Supprimer la clé", role: .destructive) {
                elevenLabsService.setApiKey("")
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("La clé est chiffrée dans le trousseau (Keychain) de cet appareil. Elle n’est envoyée qu’à ElevenLabs.")
        }
        .alert("Audio disponible hors ligne", isPresented: $showDownloadSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Cet enregistrement reste dans l’appareil et sera relu sans réseau.")
        }
        .alert("Téléchargement impossible", isPresented: $showDownloadFailure) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Vérifiez la clé API et la connexion. La voix Apple reste disponible pendant ce temps.")
        }
    }

    // MARK: - 1. Voix principale

    private var mainVoiceSection: some View {
        Section {
            Picker("Voix principale", selection: $speechService.preferredEngine) {
                Label("Voix Apple de l’appareil", systemImage: "apple.logo").tag("apple")
                Label("Voix IA ElevenLabs", systemImage: "waveform.circle.fill").tag("elevenlabs")
            }
            .pickerStyle(.segmented)

            Picker("Voix française", selection: $speechService.selectedVoiceIdentifier) {
                ForEach(speechService.availableFrenchVoices, id: \.identifier) { voice in
                    HStack(spacing: YAMSpacing.medium) {
                        Text(voice.name)
                        Spacer(minLength: YAMSpacing.medium)
                        Text(voice.quality == .enhanced ? "Haute qualité" : "Standard")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(voice.quality == .enhanced ? theme.accentColor : theme.secondaryTextColor)
                    }
                    .tag(voice.identifier)
                }
            }

            LabeledContent("Sans réseau", value: "Voix Apple utilisée")
        } header: {
            Text("Voix principale")
        } footer: {
            Text("Choisir ElevenLabs n’enlève rien aux voix Apple : hors réseau, sans clé ou en cas d’échec, YAMParle revient à la voix de l’appareil.")
        }
    }

    // MARK: - 2. Essai

    private var testSection: some View {
        Section {
            TextField("Phrase d’essai", text: $testPhrase, axis: .vertical)
                .font(.body)
                .lineLimit(1...3)
                .accessibilityLabel("Phrase écoutée pendant l’essai")

            HStack(spacing: YAMSpacing.medium) {
                Button(action: runTest) {
                    Label(speechService.isSpeaking ? "Arrêter" : "Écouter l’essai", systemImage: speechService.isSpeaking ? "stop.fill" : "play.fill")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: YAMLayout.rowHeight)
                        .background(theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canTest && !speechService.isSpeaking)

                Text(usesElevenLabs ? "Avec ElevenLabs : génération à la première écoute, puis hors ligne." : "Avec la voix Apple : aucune connexion nécessaire.")
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("Essai")
        }
    }

    private func runTest() {
        if speechService.isSpeaking {
            speechService.stop()
            return
        }
        speechService.speak(text: testPhrase)
    }

    // MARK: - 3. Rythme et volume

    private var rhythmSection: some View {
        Section {
            sliderRow(
                title: "Vitesse",
                symbol: "speedometer",
                value: $speechService.rate,
                range: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate,
                step: 0.02,
                readout: String(format: "%.1fx", speechService.rate * 2)
            )

            sliderRow(
                title: "Hauteur",
                symbol: "waveform.path",
                value: $speechService.pitch,
                range: 0.5...1.5,
                step: 0.05,
                readout: String(format: "%.2f", speechService.pitch)
            )

            sliderRow(
                title: "Volume",
                symbol: "speaker.wave.3.fill",
                value: $speechService.volume,
                range: 0.0...1.0,
                step: 0.05,
                readout: "\(Int(speechService.volume * 100))%"
            )
        } header: {
            Text("Rythme et volume")
        } footer: {
            Text("Ces trois réglages s’appliquent aux voix Apple, donc aussi au secours automatique quand ElevenLabs n’est pas joignable. Une voix IA téléchargée garde le rythme de sa génération.")
        }
    }

    private func sliderRow(
        title: String,
        symbol: String,
        value: Binding<Float>,
        range: ClosedRange<Float>,
        step: Float,
        readout: String
    ) -> some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            HStack(spacing: YAMSpacing.medium) {
                Label(title, systemImage: symbol)
                    .font(.callout)
                    .foregroundStyle(theme.primaryTextColor)
                Spacer(minLength: YAMSpacing.medium)
                Text(readout)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(theme.accentColor)
            }
            Slider(value: value, in: range, step: step)
                .tint(theme.accentColor)
                .accessibilityLabel(title)
        }
        .padding(.vertical, YAMSpacing.tiny)
    }

    // MARK: - 4. Comportement

    private var behaviorSection: some View {
        Section {
            Toggle(isOn: $speechService.speakOnTap) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Lire au toucher d’une carte")
                        .font(.callout)
                    Text("La carte ajoute sa phrase et la lit tout de suite.")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: $speechService.clearAfterSpeaking) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Effacer après la lecture")
                        .font(.callout)
                    Text("La phrase est vidée au début de la lecture, et rétablie sur demande.")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } header: {
            Text("Comportement")
        }
    }

    // MARK: - 5. Avancé

    private var advancedSection: some View {
        Section {
            YAMAdvancedSection(
                title: "Voix IA, préchargement et cache",
                summary: advancedSummary,
                isExpanded: $showAdvanced
            ) {
                elevenLabsKeyRow
                elevenLabsVoiceRows
                offlinePreloadRow
                cacheRow
            }
        } footer: {
            Text("Cette section reste repliée tant que vous n’en avez pas besoin. Les phrases se lisent très bien sans elle.")
        }
    }

    private var advancedSummary: String {
        var parts: [String] = []
        parts.append(elevenLabsService.hasApiKey ? "clé enregistrée" : "aucune clé")
        let count = elevenLabsService.cachedItems.count
        parts.append(count == 0 ? "aucun audio en cache" : "\(count) audio\(count > 1 ? "s" : "") en cache")
        return parts.joined(separator: ", ") + "."
    }

    private var elevenLabsKeyRow: some View {
        HStack(alignment: .center, spacing: YAMSpacing.medium) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Clé API")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(theme.primaryTextColor)
                Text(elevenLabsService.hasApiKey ? elevenLabsService.maskedApiKey : "Non configurée")
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer(minLength: YAMSpacing.medium)

            Button {
                apiKeyInput = elevenLabsService.getApiKey() ?? ""
                showApiKeyPrompt = true
            } label: {
                Text(elevenLabsService.hasApiKey ? "Modifier" : "Configurer")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(theme.primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minHeight: YAMLayout.chipHeight)
                    .background(theme.secondaryCardBackground, in: Capsule())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var elevenLabsVoiceRows: some View {
        HStack(spacing: YAMSpacing.medium) {
            Text("Identifiant de voix")
                .font(.callout)
                .foregroundStyle(theme.primaryTextColor)
            Spacer(minLength: YAMSpacing.medium)
            TextField("pMs9uV…", text: $elevenLabsService.voiceId)
                .font(.footnote.monospaced())
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 200)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }

        Picker("Modèle IA", selection: $elevenLabsService.selectedModelId) {
            ForEach(elevenLabsService.availableModels, id: \.0) { model in
                Text(model.1).tag(model.0)
            }
        }

        Button(action: testElevenLabsVoice) {
            HStack(spacing: YAMSpacing.medium) {
                if elevenLabsService.isGenerating {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "waveform")
                        .font(.subheadline)
                }
                Text(elevenLabsService.isGenerating ? "Génération en cours…" : "Tester la voix IA")
                    .font(.callout.weight(.semibold))
            }
            .foregroundStyle(elevenLabsService.hasApiKey ? theme.accentColor : theme.secondaryTextColor)
            .frame(maxWidth: .infinity, minHeight: YAMLayout.rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!elevenLabsService.hasApiKey || elevenLabsService.isGenerating)
    }

    private func testElevenLabsVoice() {
        elevenLabsService.generateAndCache(text: testPhrase) { result in
            if case .success(let item) = result {
                elevenLabsService.playCachedItem(item)
            }
        }
    }

    private var offlinePreloadRow: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            Text("Téléchargez à l’avance les phrases utilisées sans réseau : elles restent lisibles dans les transports comme en zone blanche.")
                .font(.footnote)
                .foregroundStyle(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Phrase à préparer", text: $phraseToDownload)
                .font(.subheadline)

            Button(action: preloadPhrase) {
                HStack(spacing: YAMSpacing.medium) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.subheadline)
                    Text(elevenLabsService.isGenerating ? "Préparation en cours…" : "Préparer hors ligne")
                        .font(.callout.weight(.semibold))
                }
                .foregroundStyle(theme.accentColor)
                .frame(maxWidth: .infinity, minHeight: YAMLayout.rowHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(
                !elevenLabsService.hasApiKey
                || phraseToDownload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || elevenLabsService.isGenerating
            )

            if !elevenLabsService.hasApiKey {
                Label("Configurez d’abord une clé API pour préparer des audios.", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(theme.primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, YAMSpacing.small)
    }

    private func preloadPhrase() {
        elevenLabsService.generateAndCache(text: phraseToDownload) { result in
            switch result {
            case .success: showDownloadSuccess = true
            case .failure: showDownloadFailure = true
            }
        }
    }

    @ViewBuilder
    private var cacheRow: some View {
        if elevenLabsService.cachedItems.isEmpty {
            Text("Aucun audio ElevenLabs en cache sur cet appareil.")
                .font(.footnote)
                .foregroundStyle(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            ForEach(elevenLabsService.cachedItems) { item in
                HStack(spacing: YAMSpacing.medium) {
                    Button {
                        if elevenLabsService.currentlyPlayingId == item.id {
                            elevenLabsService.stopPlayback()
                        } else {
                            elevenLabsService.playCachedItem(item)
                        }
                    } label: {
                        Image(systemName: elevenLabsService.currentlyPlayingId == item.id ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(elevenLabsService.currentlyPlayingId == item.id ? "Arrêter : \(item.phrase)" : "Écouter : \(item.phrase)")

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.phrase)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(theme.primaryTextColor)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(item.fileSize) · \(item.date, format: .dateTime.day().month())")
                            .font(.footnote)
                            .foregroundStyle(theme.secondaryTextColor)
                    }

                    Spacer(minLength: YAMSpacing.medium)

                    Button(role: .destructive) {
                        elevenLabsService.deleteCachedItem(item)
                    } label: {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundStyle(YAMTone.destructive)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Retirer du cache : \(item.phrase)")
                }
                .padding(.vertical, YAMSpacing.tiny)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpeechAndSoundSettingsView()
    }
    .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
}

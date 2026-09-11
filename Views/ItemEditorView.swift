//
//  ItemEditorView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

/// Formulaire d’une phrase, en trois niveaux : Contenu, Apparence, Voix.
///
/// Le texte et la catégorie suffisent à créer une carte utilisable ; la prononciation
/// alternative et le moteur individuel sont rangés dans une section repliable, pour ne pas
/// faire concurrence au trajet du quotidien. L’aperçu dessine la vraie carte de l’accueil.
struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable private var themeManager = ThemeManager.shared

    let existingItem: AACItem?
    let defaultCategoryId: String
    let initialText: String?
    let categories: [AACCategory]

    @State private var text: String = ""
    @State private var label: String = ""
    @State private var speechText: String = ""
    @State private var selectedCategoryId: String = ""
    @State private var selectedIcon: String = "bubble.left.fill"
    @State private var selectedColorHex: String = "#1E73F2"
    @State private var sortOrder: Int = 0
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customImageData: Data? = nil

    /// Source vocale de cette carte : "apple", "elevenlabs", "recording".
    @State private var audioSourceType: String = "apple"
    @State private var localAudioFileName: String? = nil

    @State private var showAdvancedVoice = false
    @State private var saveError: String?

    @Bindable private var audioRecorder = AudioRecorderService.shared
    @Bindable private var elevenLabs = ElevenLabsService.shared

    private let iconChoices: [YAMIconChoice] = [
        YAMIconChoice(symbol: "bubble.left.fill", title: "Phrase"),
        YAMIconChoice(symbol: "bubble.left.and.bubble.right.fill", title: "Échange"),
        YAMIconChoice(symbol: "hand.wave.fill", title: "Salutation"),
        YAMIconChoice(symbol: "heart.fill", title: "Affection"),
        YAMIconChoice(symbol: "sun.max.fill", title: "Jour"),
        YAMIconChoice(symbol: "moon.stars.fill", title: "Nuit"),
        YAMIconChoice(symbol: "bed.double.fill", title: "Coucher"),
        YAMIconChoice(symbol: "questionmark.bubble.fill", title: "Question"),
        YAMIconChoice(symbol: "hand.thumbsup.fill", title: "Accord"),
        YAMIconChoice(symbol: "hand.thumbsdown.fill", title: "Refus"),
        YAMIconChoice(symbol: "face.smiling.fill", title: "Sourire"),
        YAMIconChoice(symbol: "exclamationmark.bubble.fill", title: "Attention"),
        YAMIconChoice(symbol: "clock.fill", title: "Attente"),
        YAMIconChoice(symbol: "sparkles", title: "Nouveauté"),
        YAMIconChoice(symbol: "arrow.counterclockwise.circle.fill", title: "Répéter"),
        YAMIconChoice(symbol: "lifepreserver.fill", title: "Aide"),
        YAMIconChoice(symbol: "figure.walk.departure", title: "Départ"),
        YAMIconChoice(symbol: "checkmark.circle.fill", title: "Oui"),
        YAMIconChoice(symbol: "xmark.circle.fill", title: "Non"),
        YAMIconChoice(symbol: "person.fill", title: "Personne"),
        YAMIconChoice(symbol: "person.2.fill", title: "Deux personnes"),
        YAMIconChoice(symbol: "house.fill", title: "Maison"),
        YAMIconChoice(symbol: "building.2.fill", title: "Bâtiment"),
        YAMIconChoice(symbol: "fork.knife", title: "Repas"),
        YAMIconChoice(symbol: "cup.and.saucer.fill", title: "Boisson"),
        YAMIconChoice(symbol: "drop.fill", title: "Eau"),
        YAMIconChoice(symbol: "cube.fill", title: "Objet"),
        YAMIconChoice(symbol: "tshirt.fill", title: "Vêtement"),
        YAMIconChoice(symbol: "figure.walk", title: "Marche"),
        YAMIconChoice(symbol: "brain.head.profile", title: "Tête"),
        YAMIconChoice(symbol: "cross.fill", title: "Santé"),
        YAMIconChoice(symbol: "pills.fill", title: "Médicament"),
        YAMIconChoice(symbol: "car.fill", title: "Voiture"),
        YAMIconChoice(symbol: "tree.fill", title: "Extérieur"),
        YAMIconChoice(symbol: "cart.fill", title: "Courses"),
        YAMIconChoice(symbol: "star.fill", title: "Préférence"),
    ]

    init(
        existingItem: AACItem?,
        defaultCategoryId: String,
        initialText: String? = nil,
        categories: [AACCategory]
    ) {
        self.existingItem = existingItem
        self.defaultCategoryId = defaultCategoryId
        self.initialText = initialText
        self.categories = categories
    }

    private var theme: AppTheme { themeManager.currentTheme }
    private var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedLabel: String { label.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedSpeech: String { speechText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedText.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                contentSection
                appearanceSection
                voiceSection
                errorSection
            }
            .listSectionSpacing(.compact)
            .contentMargins(.vertical, YAMSpacing.small, for: .scrollContent)
            .navigationTitle(existingItem == nil ? "Nouvelle phrase" : "Modifier la phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: saveItem)
                        .disabled(!canSave)
                        .fontWeight(.bold)
                }
            }
            .onAppear(perform: loadValues)
        }
        .tint(theme.accentColor)
        .preferredColorScheme(themeManager.appearance.colorScheme)
    }

    // MARK: - 1. Contenu

    private var contentSection: some View {
        Section {
            TextField("Texte complet de la phrase", text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(2...5)
                .accessibilityLabel("Texte de la phrase")

            TextField("Étiquette courte sur le bouton (facultatif)", text: $label)
                .font(.subheadline)
                .accessibilityLabel("Étiquette affichée sur la carte")

            Picker("Catégorie", selection: $selectedCategoryId) {
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.iconName)
                        .tag(category.id)
                }
            }
            .pickerStyle(.menu)

            Stepper("Position dans la grille : \(sortOrder)", value: $sortOrder, in: 0...500)
                .font(.subheadline)
        } header: {
            Text("Contenu")
        } footer: {
            Text("La carte ajoute toujours le texte complet à votre phrase. L’étiquette ne sert qu’à la reconnaître dans la grille, et l’ordre choisi reste stable d’une ouverture à l’autre.")
        }
    }

    // MARK: - 2. Apparence

    private var appearanceSection: some View {
        Section {
            cardPreview
                .listRowBackground(Color.clear)

            photoRow

            // L’icône ne sert plus que si aucune photo n’est choisie : inutile d’afficher deux sources concurrentes.
            if customImageData == nil {
                YAMIconChoiceGrid(selection: $selectedIcon, choices: iconChoices)
            }

            YAMSwatchGrid(selection: $selectedColorHex)
        } header: {
            Text("Apparence")
        } footer: {
            Text("L’aperçu est la carte elle-même : même texte, même dessin que sur l’écran principal. Une phrase longue agrandit la carte, elle n’est jamais réduite pour rentrer.")
        }
    }

    /// Aperçu fondé sur `YAMCardFace`, le dessin partagé par l’accueil et la recherche.
    private var cardPreview: some View {
        VStack(alignment: .center, spacing: YAMSpacing.small) {
            HStack {
                Spacer(minLength: 0)
                YAMCardFace(
                    label: previewLabel,
                    symbolName: selectedIcon,
                    imageData: customImageData,
                    tint: Color(hex: selectedColorHex),
                    audioBadgeTitle: previewBadgeTitle
                )
                .frame(width: YAMLayout.gridCardMinWidth)
                .yamSurface(theme)
                Spacer(minLength: 0)
            }

            if audioSourceType == "apple" && !trimmedSpeech.isEmpty {
                Text("Le texte prononcé diffère de l’affiche : « \(trimmedSpeech) ».")
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aperçu de la carte : \(previewLabel)")
        .accessibilityHint(previewBadgeTitle == nil ? "Voix du profil." : "Voix personnalisée sur cette carte.")
    }

    private var previewLabel: String {
        if !trimmedLabel.isEmpty { return trimmedLabel }
        if !trimmedText.isEmpty { return trimmedText }
        return "Votre phrase"
    }

    /// Le badge suit exactement ce que la carte de l’accueil afficherait.
    private var previewBadgeTitle: String? {
        switch audioSourceType {
        case "recording": return "Voix enregistrée"
        case "elevenlabs": return "Voix IA"
        default: return nil
        }
    }

    private var photoRow: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: YAMSpacing.medium) {
                    Label("Photo de l’appareil", systemImage: "photo.on.rectangle.angled")
                        .font(.callout)
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer(minLength: 0)
                    Text(customImageData == nil ? "Aucune photo" : "Photo choisie")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .frame(minHeight: YAMSpacing.minimumTarget)
                .contentShape(Rectangle())
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    // Charger en deux temps : `if let … = try? await …` est rejeté par
                    // l’analyseur de grammaire des contrôles statiques. Un échec de
                    // transfert laisse la photo déjà choisie en place.
                    let transferred = try? await newItem?.loadTransferable(type: Data.self)
                    if let data = transferred {
                        customImageData = data
                    }
                }
            }

            if customImageData != nil {
                Button(role: .destructive, action: removePhoto) {
                    Label("Retirer la photo et revenir à l’icône", systemImage: "trash")
                        .font(.footnote.weight(.medium))
                        .frame(minHeight: YAMLayout.rowHeight)
                }
            }
        }
    }

    // MARK: - 3. Voix

    private var voiceSection: some View {
        Section {
            LabeledContent("Voix de cette carte", value: voiceSummary)

            Button(action: testVoice) {
                HStack(spacing: YAMSpacing.medium) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(theme.accentColor)
                    Text("Écouter ce que dira cette carte")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: YAMLayout.rowHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            YAMAdvancedSection(
                title: "Voix personnalisée pour cette carte",
                summary: advancedSummary,
                isExpanded: $showAdvancedVoice
            ) {
                Picker("Moteur de cette carte", selection: $audioSourceType) {
                    Text("Voix du profil").tag("apple")
                    Text("Enregistrement personnel").tag("recording")
                    Text("Voix IA ElevenLabs").tag("elevenlabs")
                }
                .pickerStyle(.menu)

                if audioSourceType == "apple" {
                    TextField("Prononciation alternative (facultatif)", text: $speechText)
                        .font(.subheadline)
                        .accessibilityLabel("Texte prononcé à la place du texte affiché")
                }

                if audioSourceType == "elevenlabs" {
                    elevenLabsRow
                }

                if audioSourceType == "recording" {
                    recordingRow
                }
            }
        } header: {
            Text("Voix")
        } footer: {
            Text("Sans réglage ici, la carte parle avec la voix principale du profil. Aucun compte en ligne n’est nécessaire pour communiquer.")
        }
    }

    private var voiceSummary: String {
        switch audioSourceType {
        case "recording": return "Enregistrement personnel"
        case "elevenlabs": return "Voix IA ElevenLabs"
        default: return trimmedSpeech.isEmpty ? "Voix du profil" : "Prononciation alternative"
        }
    }

    /// Une section repliée ne doit pas masquer un réglage déjà actif.
    private var advancedSummary: String {
        let usesEngine = audioSourceType != "apple"
        let usesSpeechText = !trimmedSpeech.isEmpty
        guard usesEngine || usesSpeechText else { return "Aucun réglage avancé sur cette carte." }
        var parts: [String] = []
        if usesSpeechText { parts.append("texte prononcé différent") }
        if usesEngine { parts.append("moteur individuel") }
        return "Actif : " + parts.joined(separator: " et ") + "."
    }

    private var elevenLabsRow: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            if let cached = elevenLabs.getCachedFile(for: trimmedText) {
                HStack(spacing: YAMSpacing.medium) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(YAMTone.positive)
                        .accessibilityHidden(true)
                    Text("Audio déjà téléchargé (\(cached.fileSize))")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer(minLength: 0)
                    Button("Écouter") { elevenLabs.playCachedItem(cached) }
                        .font(.footnote.weight(.semibold))
                        .buttonStyle(.bordered)
                }
            } else {
                Button(action: generatePreview) {
                    HStack(spacing: YAMSpacing.medium) {
                        if elevenLabs.isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.subheadline)
                        }
                        Text(elevenLabs.isGenerating ? "Téléchargement…" : "Générer et télécharger cet audio")
                            .font(.callout.weight(.medium))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: YAMLayout.rowHeight, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .disabled(!elevenLabs.hasApiKey || !canSave || elevenLabs.isGenerating)

                if !elevenLabs.hasApiKey {
                    Text("Aucune clé ElevenLabs n’est enregistrée dans les réglages. Les voix Apple restent disponibles sans compte.")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, YAMSpacing.small)
    }

    private var recordingRow: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            if audioRecorder.isRecording {
                HStack(spacing: YAMSpacing.medium) {
                    Circle()
                        .fill(YAMTone.destructive)
                        .frame(width: YAMLayout.recordingDotSize, height: YAMLayout.recordingDotSize)
                        .accessibilityHidden(true)
                    Text(String(format: "Enregistrement en cours (%.1f s)", audioRecorder.recordingDuration))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer(minLength: 0)
                    Button("Terminer") { audioRecorder.stopRecording() }
                        .font(.footnote.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(YAMTone.destructive)
                }
            } else {
                HStack(spacing: YAMSpacing.medium) {
                    Button(action: startRecording) {
                        Label(localAudioFileName == nil ? "Enregistrer ma voix" : "Réenregistrer", systemImage: "mic.circle.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                            .frame(minHeight: YAMLayout.rowHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    if let fileName = localAudioFileName, audioRecorder.fileExists(fileName: fileName) {
                        Button {
                            audioRecorder.playAudio(fileName: fileName)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(theme.accentColor)
                        }
                        .accessibilityLabel("Écouter l’enregistrement")

                        Button(role: .destructive) {
                            audioRecorder.deleteAudio(fileName: fileName)
                            localAudioFileName = nil
                        } label: {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundStyle(YAMTone.destructive)
                        }
                        .accessibilityLabel("Supprimer l’enregistrement")
                    }
                }
            }

            Text("Le micro est demandé pour cet enregistrement seulement ; l’audio reste sur l’appareil.")
                .font(.footnote)
                .foregroundStyle(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, YAMSpacing.small)
    }

    // MARK: - Erreur de sauvegarde

    @ViewBuilder
    private var errorSection: some View {
        if let saveError {
            Section {
                Label(saveError, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(theme.primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Actions

    private func loadValues() {
        if let item = existingItem {
            text = item.text
            label = item.label ?? ""
            speechText = item.speechText ?? ""
            selectedCategoryId = item.categoryId
            selectedIcon = item.iconName
            selectedColorHex = item.customColorHex
                ?? categories.first(where: { $0.id == item.categoryId })?.colorHex
                ?? "#1E73F2"
            customImageData = item.customImageData
            sortOrder = item.sortOrder
            audioSourceType = item.audioSourceType
            localAudioFileName = item.localAudioFileName
            // Un réglage avancé déjà présent ne doit pas être caché sans signe visible.
            showAdvancedVoice = item.audioSourceType != "apple" || !(item.speechText?.isEmpty ?? true)
        } else {
            text = initialText ?? ""
            selectedCategoryId = defaultCategoryId.isEmpty ? (categories.first?.id ?? "") : defaultCategoryId
            selectedColorHex = categories.first(where: { $0.id == selectedCategoryId })?.colorHex ?? "#1E73F2"
            showAdvancedVoice = false
        }
    }

    private func removePhoto() {
        customImageData = nil
        selectedPhotoItem = nil
    }

    private func testVoice() {
        let spoken = trimmedSpeech.isEmpty ? trimmedText : trimmedSpeech
        SpeechService.shared.speak(text: spoken.isEmpty ? "Test de voix YAMParle" : spoken)
    }

    private func generatePreview() {
        elevenLabs.generateAndCache(text: trimmedText) { _ in }
    }

    private func startRecording() {
        audioRecorder.requestMicrophonePermission { granted in
            guard granted else { return }
            let fileName = "rec_btn_\(UUID().uuidString.prefix(8)).m4a"
            localAudioFileName = audioRecorder.startRecording(fileName: fileName)
        }
    }

    private func saveItem() {
        guard canSave else { return }
        let isNew = existingItem == nil
        let item = existingItem ?? AACItem(
            text: trimmedText,
            categoryId: selectedCategoryId,
            userProfileId: ProfileManager.shared.activeProfileId,
            audioSourceType: audioSourceType
        )
        let previous = (
            item.text, item.label, item.speechText, item.categoryId, item.iconName,
            item.customColorHex, item.customImageData, item.sortOrder,
            item.audioSourceType, item.localAudioFileName
        )

        item.text = trimmedText
        item.label = trimmedLabel.isEmpty ? nil : trimmedLabel
        item.speechText = trimmedSpeech.isEmpty ? nil : trimmedSpeech
        item.categoryId = selectedCategoryId
        item.iconName = selectedIcon
        item.customColorHex = selectedColorHex
        item.customImageData = customImageData
        item.sortOrder = sortOrder
        item.audioSourceType = audioSourceType
        item.localAudioFileName = localAudioFileName

        if isNew { modelContext.insert(item) }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Un enregistrement raté se dit ; il ne se fait pas en silence.
            if isNew {
                modelContext.delete(item)
            } else {
                (
                    item.text, item.label, item.speechText, item.categoryId, item.iconName,
                    item.customColorHex, item.customImageData, item.sortOrder,
                    item.audioSourceType, item.localAudioFileName
                ) = previous
            }
            saveError = "La phrase n’a pas pu être enregistrée sur cet appareil. Réessayez."
        }
    }
}

#Preview("Nouvelle phrase") {
    NavigationStack {
        ItemEditorView(existingItem: nil, defaultCategoryId: "", categories: [])
    }
    .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
}

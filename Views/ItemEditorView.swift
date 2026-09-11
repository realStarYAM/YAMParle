//
//  ItemEditorView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

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

    // Audio source selection: "apple", "elevenlabs", "recording"
    @State private var audioSourceType: String = "apple"
    @State private var localAudioFileName: String? = nil

    @Bindable var audioRecorder = AudioRecorderService.shared
    @Bindable var elevenLabs = ElevenLabsService.shared

    private let availableSymbols = [
        "bubble.left.fill", "bubble.left.and.bubble.right.fill", "hand.wave.fill",
        "heart.fill", "sun.max.fill", "moon.stars.fill", "bed.double.fill",
        "questionmark.bubble.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill",
        "face.smiling.fill", "exclamationmark.bubble.fill", "clock.fill",
        "sparkles", "arrow.counterclockwise.circle.fill", "lifepreserver.fill",
        "figure.walk.departure", "checkmark.circle.fill", "xmark.circle.fill",
        "person.fill", "person.2.fill", "house.fill", "building.2.fill",
        "fork.knife", "cup.and.saucer.fill", "drop.fill", "cube.fill",
        "tshirt.fill", "figure.walk", "brain.head.profile", "cross.fill",
        "pills.fill", "car.fill", "tree.fill", "cart.fill", "star.fill"
    ]

    private let paletteColors = [
        "#1E73F2", "#30D158", "#FF9F0A", "#40CBE0",
        "#FF375F", "#BF5AF2", "#5E5CE6", "#FFD60A",
        "#AC8E68", "#64D2FF", "#FF453A", "#8E8E93"
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

    var body: some View {
        NavigationStack {
            Form {
                // 1. Aperçu
                Section("Aperçu du bouton") {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Capsule()
                                .fill(Color(hex: selectedColorHex))
                                .frame(width: 36, height: 5)
                                .padding(.top, 6)

                            ZStack(alignment: .topTrailing) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: selectedColorHex).opacity(0.15))
                                        .frame(width: 58, height: 58)

                                    if let data = customImageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 54, height: 54)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: selectedIcon)
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundColor(Color(hex: selectedColorHex))
                                    }
                                }

                                // Custom audio badge indicator
                                if audioSourceType != "apple" {
                                    Image(systemName: audioSourceType == "recording" ? "mic.fill" : "waveform.badge.magnifyingglass")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(audioSourceType == "recording" ? Color.red : Color.purple)
                                        .clipShape(Circle())
                                        .offset(x: 4, y: -4)
                                }
                            }

                            Text(label.isEmpty ? (text.isEmpty ? "Texte" : text) : label)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 6)
                        }
                        .frame(width: 130, height: 130)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color(hex: selectedColorHex).opacity(0.35), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // 2. Texte de la phrase et étiquette
                Section("Texte & Étiquette") {
                    TextField("Texte complet de la phrase", text: $text, axis: .vertical)
                        .font(.body)
                        .lineLimit(2...4)

                    TextField("Étiquette courte sur le bouton (optionnel)", text: $label)
                        .font(.subheadline)
                }

                // 3. Source vocale (Apple, ElevenLabs, Enregistrement personnel)
                Section("Source vocale de ce bouton") {
                    Picker("Moteur audio", selection: $audioSourceType) {
                        Text("Voix Apple").tag("apple")
                        Text("ElevenLabs IA").tag("elevenlabs")
                        Text("Enregistrement personnel").tag("recording")
                    }
                    .pickerStyle(.segmented)

                    if audioSourceType == "apple" {
                        TextField("Prononciation alternative (optionnel)", text: $speechText)
                            .font(.subheadline)

                        Button {
                            let toSpeak = speechText.isEmpty ? text : speechText
                            SpeechService.shared.speak(text: toSpeak.isEmpty ? "Test de voix YAMParle" : toSpeak)
                        } label: {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text("Tester la voix Apple")
                            }
                            .foregroundColor(Color.yamAccent)
                        }
                    } else if audioSourceType == "elevenlabs" {
                        VStack(alignment: .leading, spacing: 8) {
                            if let cached = ElevenLabsService.shared.getCachedFile(for: text) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Fichier audio téléchargé (\(cached.fileSize))")
                                        .font(.caption)
                                    Spacer()
                                    Button("Écouter") {
                                        ElevenLabsService.shared.playCachedItem(cached)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                Button {
                                    ElevenLabsService.shared.generateAndCache(text: text) { _ in }
                                } label: {
                                    HStack {
                                        if ElevenLabsService.shared.isGenerating {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "arrow.down.circle.fill")
                                        }
                                        Text(ElevenLabsService.shared.isGenerating ? "Téléchargement..." : "Générer et télécharger l'audio")
                                    }
                                }
                                .disabled(!ElevenLabsService.shared.hasApiKey || text.isEmpty || ElevenLabsService.shared.isGenerating)
                            }
                        }
                        .padding(.vertical, 4)
                    } else if audioSourceType == "recording" {
                        VStack(alignment: .leading, spacing: 8) {
                            if audioRecorder.isRecording {
                                HStack {
                                    Circle().fill(Color.red).frame(width: 10, height: 10)
                                    Text("Enregistrement (\(String(format: "%.1fs", audioRecorder.recordingDuration)))")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.red)
                                    Spacer()
                                    Button("Terminer") {
                                        audioRecorder.stopRecording()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                            } else {
                                HStack {
                                    Button {
                                        audioRecorder.requestMicrophonePermission { granted in
                                            if granted {
                                                let fileName = "rec_btn_\(UUID().uuidString.prefix(8)).m4a"
                                                localAudioFileName = audioRecorder.startRecording(fileName: fileName)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "mic.circle.fill")
                                            Text(localAudioFileName != nil ? "Réenregistrer" : "Enregistrer ma voix")
                                        }
                                        .foregroundColor(.red)
                                    }

                                    Spacer()

                                    if let fileName = localAudioFileName, audioRecorder.fileExists(fileName: fileName) {
                                        Button {
                                            audioRecorder.playAudio(fileName: fileName)
                                        } label: {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(Color.yamAccent)
                                        }

                                        Button(role: .destructive) {
                                            audioRecorder.deleteAudio(fileName: fileName)
                                            localAudioFileName = nil
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 4. Catégorie & Position dans la grille
                Section("Organisation") {
                    Picker("Catégorie", selection: $selectedCategoryId) {
                        ForEach(categories) { cat in
                            Label(cat.name, systemImage: cat.iconName)
                                .tag(cat.id)
                        }
                    }

                    Stepper("Position dans la grille : \(sortOrder)", value: $sortOrder, in: 0...500)
                }

                // 5. Couleur du bouton
                Section("Couleur du bouton") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(paletteColors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 38)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    )
                                    .shadow(color: Color(hex: hex).opacity(selectedColorHex == hex ? 0.6 : 0.2), radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // 6. Image / Photo facultative
                Section("Image ou Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Label("Choisir une photo de l'appareil", systemImage: "photo.on.rectangle.angled")
                            Spacer()
                            if customImageData != nil {
                                Text("Photo sélectionnée")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                customImageData = data
                            }
                        }
                    }

                    if customImageData != nil {
                        Button(role: .destructive) {
                            customImageData = nil
                            selectedPhotoItem = nil
                        } label: {
                            Label("Supprimer la photo (utiliser l'icône)", systemImage: "trash")
                        }
                    }
                }

                // 7. SF Symbols Selection (si aucune photo)
                if customImageData == nil {
                    Section("Choisir une icône") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(availableSymbols, id: \.self) { sym in
                                Button {
                                    selectedIcon = sym
                                } label: {
                                    Image(systemName: sym)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == sym ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == sym ? Color(hex: selectedColorHex) : Color(UIColor.tertiarySystemFill))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "Nouvelle phrase" : "Modifier la phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let item = existingItem {
                    text = item.text
                    label = item.label ?? ""
                    speechText = item.speechText ?? ""
                    selectedCategoryId = item.categoryId
                    selectedIcon = item.iconName
                    selectedColorHex = item.customColorHex ?? categories.first(where: { $0.id == item.categoryId })?.colorHex ?? "#1E73F2"
                    customImageData = item.customImageData
                    sortOrder = item.sortOrder
                    audioSourceType = item.audioSourceType
                    localAudioFileName = item.localAudioFileName
                } else {
                    if let prefill = initialText, !prefill.isEmpty {
                        text = prefill
                    }
                    selectedCategoryId = defaultCategoryId.isEmpty ? (categories.first?.id ?? "cat_conversation") : defaultCategoryId
                    selectedColorHex = categories.first(where: { $0.id == selectedCategoryId })?.colorHex ?? "#1E73F2"
                }
            }
        }
    }

    private func saveItem() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpeech = speechText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : speechText.trimmingCharacters(in: .whitespacesAndNewlines)
        let activeProfileId = ProfileManager.shared.activeProfileId

        if let item = existingItem {
            item.text = trimmedText
            item.label = trimmedLabel
            item.speechText = trimmedSpeech
            item.categoryId = selectedCategoryId
            item.iconName = selectedIcon
            item.customColorHex = selectedColorHex
            item.customImageData = customImageData
            item.sortOrder = sortOrder
            item.audioSourceType = audioSourceType
            item.localAudioFileName = localAudioFileName
        } else {
            let newItem = AACItem(
                text: trimmedText,
                label: trimmedLabel,
                speechText: trimmedSpeech,
                iconName: selectedIcon,
                customImageData: customImageData,
                categoryId: selectedCategoryId,
                customColorHex: selectedColorHex,
                sortOrder: sortOrder,
                isFavorite: false,
                isCustom: true,
                userProfileId: activeProfileId,
                audioSourceType: audioSourceType,
                localAudioFileName: localAudioFileName
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
    }
}

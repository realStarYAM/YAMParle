//
//  AACViewModel.swift
//  YAMParle
//

import SwiftUI
import SwiftData

enum AppMode: String, CaseIterable, Identifiable {
    case pictograms = "Pictogrammes"
    case writing = "Écriture"

    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .pictograms: return "square.grid.2x2.fill"
        case .writing: return "keyboard.fill"
        }
    }
}

struct PhraseToken: Identifiable, Equatable {
    let id: UUID = UUID()
    let text: String
    let speechText: String
    let iconName: String
    let customImageData: Data?
    let colorHex: String?
}

@Observable
final class AACViewModel {
    var currentAppMode: AppMode = .pictograms
    var phraseTokens: [PhraseToken] = []
    var selectedCategoryId: String = "cat_mots_rapides"
    var searchText: String = ""
    var isEditingMode: Bool = false

    // Writing mode text state
    var writingText: String = ""

    // Native Keyboard Text Input
    var isTextInputVisible: Bool = false
    var typedText: String = ""

    // Sheets & Dialogs
    var showingFavorites: Bool = false
    var showingSettings: Bool = false
    var showingItemEditor: Bool = false
    var itemToEdit: AACItem? = nil
    var activeCategoryForNewItem: String = "cat_mots_rapides"

    // Feedback alert
    var alertMessage: String? = nil
    var showAlert: Bool = false

    var speechService = SpeechService.shared

    var currentPhraseText: String {
        phraseTokens.map { $0.text }.joined(separator: " ")
    }

    var currentPhraseSpokenText: String {
        phraseTokens.map { $0.speechText }.joined(separator: " ")
    }

    func addToken(from item: AACItem, categoryColor: String? = nil) {
        let token = PhraseToken(
            text: item.text,
            speechText: item.spokenText,
            iconName: item.iconName,
            customImageData: item.customImageData,
            colorHex: item.customColorHex ?? categoryColor
        )
        phraseTokens.append(token)

        if speechService.speakOnTap {
            speechService.speak(text: item.spokenText)
        }
    }

    func addTypedTextToPhrase() {
        let trimmed = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let token = PhraseToken(
            text: trimmed,
            speechText: trimmed,
            iconName: "keyboard",
            customImageData: nil,
            colorHex: "#1E73F2"
        )
        phraseTokens.append(token)
        typedText = ""

        if speechService.speakOnTap {
            speechService.speak(text: trimmed)
        }
    }

    func speakTypedText() {
        let trimmed = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        speechService.speak(text: trimmed)
    }

    func removeLastToken() {
        guard !phraseTokens.isEmpty else { return }
        phraseTokens.removeLast()
    }

    func removeToken(at index: Int) {
        guard phraseTokens.indices.contains(index) else { return }
        phraseTokens.remove(at: index)
    }

    func clearPhrase() {
        phraseTokens.removeAll()
    }

    func speakCurrentPhrase() {
        let textToSpeak = currentPhraseSpokenText
        guard !textToSpeak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        speechService.speak(text: textToSpeak)

        if speechService.clearAfterSpeaking {
            phraseTokens.removeAll()
        }
    }

    func speakSingleWord(_ text: String) {
        speechService.speak(text: text)
    }

    func saveCurrentPhraseAsFavorite(context: ModelContext) {
        let trimmed = currentPhraseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let favorite = FavoritePhrase(text: trimmed)
        context.insert(favorite)
        try? context.save()

        alertMessage = "Phrase ajoutée aux favoris !"
        showAlert = true
    }

    func openEditorForNewItem(categoryId: String) {
        itemToEdit = nil
        activeCategoryForNewItem = categoryId
        showingItemEditor = true
    }

    func openEditor(for item: AACItem) {
        itemToEdit = item
        activeCategoryForNewItem = item.categoryId
        showingItemEditor = true
    }
}

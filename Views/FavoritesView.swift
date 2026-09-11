//
//  FavoritesView.swift
//  YAMParle
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoritePhrase.dateAdded, order: .reverse) private var favorites: [FavoritePhrase]

    @Bindable var viewModel: AACViewModel

    @State private var newPhraseText: String = ""
    @State private var isAddingNewPhrase: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Section to add current phrase or new custom phrase
                Section {
                    if !viewModel.currentPhraseText.isEmpty {
                        Button {
                            viewModel.saveCurrentPhraseAsFavorite(context: modelContext)
                        } label: {
                            Label("Enregistrer la phrase actuelle: \"\(viewModel.currentPhraseText)\"", systemImage: "star.fill")
                                .font(.headline)
                                .foregroundColor(Color.yamAccent)
                        }
                    }

                    if isAddingNewPhrase {
                        HStack {
                            TextField("Nouvelle phrase favorite...", text: $newPhraseText)
                                .font(.body)

                            Button("Ajouter") {
                                addCustomFavorite()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newPhraseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button {
                            isAddingNewPhrase = true
                        } label: {
                            Label("Ajouter une phrase personnalisée", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                } header: {
                    Text("Ajout rapide")
                }

                // List of saved favorites
                Section {
                    if favorites.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "star.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Aucune phrase favorite pour l'instant")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(favorites) { fav in
                            favoriteRow(fav: fav)
                        }
                        .onDelete(perform: deleteFavorites)
                    }
                } header: {
                    Text("Phrases enregistrées (\(favorites.count))")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Phrases favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private func favoriteRow(fav: FavoritePhrase) -> some View {
        HStack(spacing: 12) {
            // Star pinned indicator
            Button {
                fav.isPinned.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: fav.isPinned ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(fav.isPinned ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(fav.isPinned ? "Retirer des épinglés" : "Épingler")

            // Phrase Text
            Text(fav.text)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Speak immediately
            Button {
                viewModel.speechService.speak(text: fav.text)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.body.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.yamAccent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lire: \(fav.text)")

            // Insert into current phrase bar
            Button {
                let token = PhraseToken(
                    text: fav.text,
                    speechText: fav.text,
                    iconName: "quote.bubble.fill",
                    customImageData: nil,
                    colorHex: "#1E73F2"
                )
                viewModel.phraseTokens.append(token)
                dismiss()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Charger dans la barre de phrase")
        }
        .padding(.vertical, 4)
    }

    private func addCustomFavorite() {
        let clean = newPhraseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        let fav = FavoritePhrase(text: clean, isPinned: false)
        modelContext.insert(fav)
        try? modelContext.save()

        newPhraseText = ""
        isAddingNewPhrase = false
    }

    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }
        try? modelContext.save()
    }
}

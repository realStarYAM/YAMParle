//
//  SearchView.swift
//  YAMParle
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable private var themeManager = ThemeManager.shared

    @Bindable var viewModel: AACViewModel
    let categories: [AACCategory]
    let allItems: [AACItem]
    let onSelectPhrase: (String) -> Void
    let onEditPhrase: (AACItem) -> Void

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var filteredItems: [AACItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return allItems
        }
        return allItems.filter { item in
            item.text.localizedCaseInsensitiveContains(trimmed) ||
            (item.label?.localizedCaseInsensitiveContains(trimmed) ?? false) ||
            (item.speechText?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input Card
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .foregroundColor(theme.accentColor)

                    TextField("Rechercher une phrase ou un mot...", text: $query)
                        .font(.body)
                        .focused($isSearchFocused)
                        .submitLabel(.search)

                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isSearchFocused ? theme.accentColor : theme.borderColor, lineWidth: isSearchFocused ? 2 : 1)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Instant Results List
                if filteredItems.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Aucun résultat pour « \(query) »")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            let cat = categories.first(where: { $0.id == item.categoryId })
                            let catColor = cat?.color ?? theme.accentColor

                            HStack(spacing: 12) {
                                // Category color icon container
                                ZStack {
                                    Circle()
                                        .fill(catColor.opacity(0.18))
                                        .frame(width: 44, height: 44)

                                    if let data = item.customImageData, let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: item.iconName)
                                            .font(.body.weight(.bold))
                                            .foregroundColor(catColor)
                                    }
                                }

                                // Phrase Name + Category
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.text)
                                        .font(.system(.body, design: theme.fontDesign, weight: .bold))
                                        .foregroundColor(theme.primaryTextColor)

                                    HStack(spacing: 6) {
                                        if let catName = cat?.name {
                                            Text(catName)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(catColor)
                                        }

                                        if item.hasCustomAudio {
                                            Text(item.audioSourceType == "recording" ? "• Micro" : "• ElevenLabs")
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(item.audioSourceType == "recording" ? Color(hex: "#FF3B30") : Color(hex: "#AF52DE"))
                                        }
                                    }
                                }

                                Spacer()

                                // Bouton Parler (🔊)
                                Button {
                                    SpeechService.shared.speakItem(item)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.body.weight(.bold))
                                        .foregroundColor(.white)
                                        .frame(width: 38, height: 38)
                                        .background(theme.accentColor)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Lire cette phrase")

                                // Bouton Modifier (✏️)
                                Button {
                                    dismiss()
                                    onEditPhrase(item)
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.secondary)
                                        .frame(width: 38, height: 38)
                                        .background(Color.secondary.opacity(0.12))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Modifier cette phrase")
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectPhrase(item.text)
                                dismiss()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Rechercher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
        .tint(theme.accentColor)
    }
}

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Bindable private var themeManager = ThemeManager.shared

    let categories: [AACCategory]
    let allItems: [AACItem]
    let onSelectPhrase: (String) -> Void
    let onEditPhrase: (AACItem) -> Void
    @State private var query = ""

    private var theme: AppTheme { themeManager.currentTheme }
    private var filteredItems: [AACItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allItems }
        return allItems.filter { item in
            [item.text, item.displayLabel, item.spokenText].contains { value in
                value.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive], locale: .current) != nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                        ForEach(filteredItems) { item in
                            ModernAACCard(
                                item: item,
                                categoryColor: categories.first { $0.id == item.categoryId }?.color ?? theme.accentColor,
                                onTap: {
                                    onSelectPhrase(item.text)
                                    dismiss()
                                },
                                onSpeak: { SpeechService.shared.speakItem(item) },
                                onEdit: {
                                    onEditPhrase(item)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .background { YAMAmbientBackground(theme: theme) }
            .searchable(text: $query, prompt: "Une phrase, un mot…")
            .navigationTitle("Rechercher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
        }
        .tint(theme.accentColor)
    }
}

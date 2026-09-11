import SwiftUI
import SwiftData

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable private var themeManager = ThemeManager.shared
    var existingCategory: AACCategory? = nil

    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColorHex = "#1E73F2"
    @State private var saveError: String?

    private let icons: [(symbol: String, title: String)] = [
        ("folder.fill", "Dossier"), ("bubble.left.fill", "Conversation"), ("tag.fill", "Étiquette"),
        ("star.fill", "Étoile"), ("heart.fill", "Cœur"), ("house.fill", "Maison"),
        ("person.fill", "Personne"), ("figure.walk", "Déplacement"), ("cart.fill", "Courses"),
        ("fork.knife", "Repas"), ("pills.fill", "Santé"), ("book.fill", "Livre"),
        ("briefcase.fill", "Travail"), ("globe.europe.africa.fill", "Monde"), ("tv.fill", "Télévision"), ("gift.fill", "Cadeau")
    ]
    private let colors: [(hex: String, title: String)] = [
        ("#1E73F2", "Bleu"), ("#30D158", "Vert"), ("#FF9F0A", "Orange"), ("#40CBE0", "Turquoise"),
        ("#FF375F", "Rose"), ("#BF5AF2", "Violet"), ("#5E5CE6", "Indigo"), ("#FFD60A", "Jaune"),
        ("#AC8E68", "Brun"), ("#64D2FF", "Bleu ciel"), ("#FF453A", "Rouge"), ("#8E8E93", "Gris")
    ]
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        NavigationStack {
            Form {
                Section("Aperçu") {
                    Label(name.isEmpty ? "Votre catégorie" : name, systemImage: selectedIcon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .padding(YAMSpacing.medium)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(Color(hex: selectedColorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
                }
                Section("Nom") {
                    TextField("Exemple : Musique, Émotions…", text: $name, axis: .vertical)
                        .font(.body)
                        .accessibilityLabel("Nom de la catégorie")
                }
                Section("Couleur") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: YAMSpacing.medium)], spacing: YAMSpacing.medium) {
                        ForEach(colors, id: \.hex) { color in
                            Button { selectedColorHex = color.hex } label: {
                                Circle().fill(Color(hex: color.hex))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if selectedColorHex == color.hex {
                                            Image(systemName: "checkmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .black)
                                        }
                                    }
                                    .frame(width: YAMSpacing.minimumTarget, height: YAMSpacing.minimumTarget)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(color.title)
                            .accessibilityAddTraits(selectedColorHex == color.hex ? [.isSelected] : [])
                        }
                    }
                }
                Section("Icône") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: YAMSpacing.medium)], spacing: YAMSpacing.medium) {
                        ForEach(icons, id: \.symbol) { icon in
                            Button { selectedIcon = icon.symbol } label: {
                                Image(systemName: icon.symbol)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon.symbol ? theme.onAccentColor : theme.primaryTextColor)
                                    .frame(width: YAMSpacing.minimumTarget, height: YAMSpacing.minimumTarget)
                                    .background(selectedIcon == icon.symbol ? theme.accentColor : theme.secondaryCardBackground,
                                                in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
                            }
                            .buttonStyle(.yamPress)
                            .accessibilityLabel(icon.title)
                            .accessibilityAddTraits(selectedIcon == icon.symbol ? [.isSelected] : [])
                        }
                    }
                }
                if let saveError {
                    Section { Label(saveError, systemImage: "exclamationmark.triangle") }
                }
            }
            .navigationTitle(existingCategory == nil ? "Nouvelle catégorie" : "Modifier la catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: saveCategory)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let category = existingCategory {
                    name = category.name
                    selectedIcon = category.iconName
                    selectedColorHex = category.colorHex
                }
            }
        }
        .tint(theme.accentColor)
    }

    private func saveCategory() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = existingCategory ?? AACCategory(
            id: "cat_custom_\(UUID().uuidString)", name: trimmed,
            iconName: selectedIcon, colorHex: selectedColorHex,
            sortOrder: 100, isCustom: true, userProfileId: ProfileManager.shared.activeProfileId
        )
        let previous = (category.name, category.iconName, category.colorHex)
        category.name = trimmed
        category.iconName = selectedIcon
        category.colorHex = selectedColorHex
        if existingCategory == nil { modelContext.insert(category) }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            if existingCategory == nil {
                modelContext.delete(category)
            } else {
                (category.name, category.iconName, category.colorHex) = previous
            }
            saveError = "La catégorie n’a pas pu être enregistrée. Réessayez."
        }
    }
}

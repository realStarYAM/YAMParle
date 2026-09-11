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

    private let icons: [YAMIconChoice] = [
        YAMIconChoice(symbol: "folder.fill", title: "Dossier"),
        YAMIconChoice(symbol: "bubble.left.fill", title: "Conversation"),
        YAMIconChoice(symbol: "tag.fill", title: "Étiquette"),
        YAMIconChoice(symbol: "star.fill", title: "Étoile"),
        YAMIconChoice(symbol: "heart.fill", title: "Cœur"),
        YAMIconChoice(symbol: "house.fill", title: "Maison"),
        YAMIconChoice(symbol: "person.fill", title: "Personne"),
        YAMIconChoice(symbol: "figure.walk", title: "Déplacement"),
        YAMIconChoice(symbol: "cart.fill", title: "Courses"),
        YAMIconChoice(symbol: "fork.knife", title: "Repas"),
        YAMIconChoice(symbol: "pills.fill", title: "Santé"),
        YAMIconChoice(symbol: "book.fill", title: "Livre"),
        YAMIconChoice(symbol: "briefcase.fill", title: "Travail"),
        YAMIconChoice(symbol: "globe.europe.africa.fill", title: "Monde"),
        YAMIconChoice(symbol: "tv.fill", title: "Télévision"),
        YAMIconChoice(symbol: "gift.fill", title: "Cadeau"),
    ]
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    previewRow
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Aperçu")
                }

                Section {
                    TextField("Exemple : Musique, Émotions…", text: $name, axis: .vertical)
                        .font(.body)
                        .accessibilityLabel("Nom de la catégorie")
                } header: {
                    Text("Nom")
                } footer: {
                    Text("Renommer une catégorie conserve son identifiant et toutes les phrases qui y sont rattachées.")
                }

                Section {
                    YAMIconChoiceGrid(selection: $selectedIcon, choices: icons)
                } header: {
                    Text("Icône")
                }

                Section {
                    YAMSwatchGrid(selection: $selectedColorHex)
                } header: {
                    Text("Couleur")
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(theme.primaryTextColor)
                    }
                }
            }
            .listSectionSpacing(.compact)
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

    /// L’aperçu reprend le dessin des tuiles de la colonne Catégories, mais sans modèle
    /// éphémère : il se contente des valeurs en cours de saisie.
    private var previewRow: some View {
        HStack(spacing: YAMSpacing.medium) {
            Image(systemName: selectedIcon)
                .font(.footnote.weight(theme.iconWeight))
                .foregroundStyle(theme.accentColor)
                .frame(width: 26, height: 30)
                .background(Color(hex: selectedColorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Votre catégorie" : name)
                .font(.system(.callout, design: theme.fontDesign, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: YAMSpacing.medium)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: YAMLayout.rowHeight)
        .background(
            Color(hex: selectedColorHex).opacity(0.12),
            in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Aperçu de la catégorie \(name.isEmpty ? "sans nom" : name)")
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

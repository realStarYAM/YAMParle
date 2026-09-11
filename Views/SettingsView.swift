import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable private var profileManager = ProfileManager.shared
    @Bindable private var themeManager = ThemeManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @AppStorage("yamparle_high_contrast") private var highContrast = false
    @AppStorage("yamparle_haptic_feedback") private var hapticFeedback = true
    @AppStorage("yamparle_grid_card_size") private var gridCardSize = 1.0

    private var theme: AppTheme { themeManager.currentTheme }
    private var activeProfile: UserProfile? {
        profiles.first { $0.id == profileManager.activeProfileId } ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        UserProfilesView()
                    } label: {
                        settingsRow(
                            activeProfile?.name ?? "Utilisateur par défaut",
                            subtitle: activeProfile?.isDefault == true ? "Profil par défaut · Gérer les utilisateurs" : "Profil actif · Gérer les utilisateurs",
                            icon: activeProfile?.avatarSymbol ?? "person.crop.circle"
                        )
                    }
                } header: { Text("Votre espace") }

                Section {
                    NavigationLink {
                        ThemeSelectionView()
                    } label: {
                        settingsRow("Thèmes et apparence", subtitle: "\(theme.name) · \(themeManager.appearance.title)", icon: "paintpalette")
                    }
                } header: { Text("Apparence") }

                Section {
                    NavigationLink {
                        SpeechAndSoundSettingsView()
                            .onDisappear {
                                if let profile = activeProfile {
                                    profileManager.saveCurrentSettingsToProfile(profile, in: modelContext)
                                }
                            }
                    } label: {
                        settingsRow("Parole et son", subtitle: "Voix, vitesse et lecture au toucher", icon: "waveform")
                    }
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        settingsRow("Catégories", subtitle: "Organiser et renommer vos catégories", icon: "square.grid.2x2")
                    }
                } header: { Text("Communication") }

                Section {
                    Toggle(isOn: $highContrast) {
                        settingsRow("Contraste renforcé", subtitle: "Bordures plus visibles, fond sans décor", icon: "circle.lefthalf.filled")
                    }
                    Toggle(isOn: $hapticFeedback) {
                        settingsRow("Retour haptique", subtitle: "Si votre appareil le prend en charge", icon: "hand.tap")
                    }
                    VStack(alignment: .leading, spacing: YAMSpacing.small) {
                        settingsRow("Taille des cartes", subtitle: "Moins de cartes, plus d’espace pour toucher", icon: "rectangle.expand.vertical")
                        Picker("Taille des cartes", selection: $gridCardSize) {
                            Text("Compacte").tag(0.8)
                            Text("Standard").tag(1.0)
                            Text("Grande").tag(1.3)
                        }
                        .pickerStyle(.menu)
                        .frame(minHeight: YAMSpacing.minimumTarget)
                    }
                } header: {
                    Text("Confort d’utilisation")
                } footer: {
                    Text("La taille du texte et la réduction des animations suivent les réglages d’accessibilité de l’iPad. L’ordre des phrases reste stable. Ces préférences de confort s’appliquent à tous les profils.")
                }

                Section {
                    LabeledContent("Application", value: "YAMParle")
                    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                        LabeledContent("Version", value: version)
                    }
                    Text("Vos phrases sont enregistrées sur cet appareil. Aucun export de sauvegarde n’est proposé dans cet écran.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                } header: { Text("À propos et données") }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .contentMargins(.vertical, YAMSpacing.medium, for: .scrollContent)
            // Contenu centré dans la fenêtre : les lignes ne s’étirent pas sur toute la tablette.
            .frame(maxWidth: YAMLayout.windowContentWidth)
            .frame(maxWidth: .infinity)
            .background { YAMAmbientBackground(theme: theme) }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
        }
        .tint(theme.accentColor)
        .preferredColorScheme(themeManager.appearance.colorScheme)
    }

    private func settingsRow(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(alignment: .center, spacing: YAMSpacing.large) {
            Image(systemName: icon)
                .font(.body.weight(theme.iconWeight))
                .foregroundStyle(theme.accentColor)
                .frame(width: 28, height: 28)
                .background(theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(theme.primaryTextColor)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Cellule fine, mais cible tactile de 44 pt conservée sur toute la largeur de la ligne.
        .frame(minHeight: YAMSpacing.minimumTarget)
        .contentShape(Rectangle())
    }
}

struct CategoryManagementView: View {
    @Query(sort: \AACCategory.sortOrder) private var categories: [AACCategory]
    @Bindable private var profileManager = ProfileManager.shared
    @State private var editingCategory: AACCategory?
    @State private var addingCategory = false

    var body: some View {
        List {
            Section {
                ForEach(categories.filter { $0.userProfileId == profileManager.activeProfileId }) { category in
                    Button { editingCategory = category } label: {
                        Label(category.name, systemImage: category.iconName)
                            .font(.callout)
                            .frame(minHeight: YAMSpacing.minimumTarget)
                            .contentShape(Rectangle())
                    }
                }
                Button { addingCategory = true } label: {
                    Label("Nouvelle catégorie", systemImage: "folder.badge.plus")
                        .font(.callout)
                        .frame(minHeight: YAMSpacing.minimumTarget)
                        .contentShape(Rectangle())
                }
            } footer: {
                Text("Pour modifier une phrase, utilisez son bouton Options sur l’écran principal. Renommer une catégorie conserve toutes ses phrases.")
            }
        }
        .navigationTitle("Catégories")
        .sheet(item: $editingCategory) { category in CategoryEditorView(existingCategory: category) }
        .sheet(isPresented: $addingCategory) { CategoryEditorView() }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

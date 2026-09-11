//
//  ThemeSelectionView.swift
//  YAMParle
//
//  Page Réglages › Apparence › Thèmes : choix clair/sombre, thème actuel,
//  recherche, catégories, favoris, aperçu détaillé avec Appliquer et
//  Réinitialiser. Le catalogue entier vit dans ThemeRegistry.
//

import SwiftUI
import SwiftData

struct ThemeSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var profileManager = ProfileManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var query = ""
    @State private var tab: ThemeGalleryTab = .all
    @State private var selectedDefinition: ThemeDefinition?

    private var theme: AppTheme { themeManager.currentTheme }
    private var activeProfile: UserProfile? {
        profiles.first { $0.id == profileManager.activeProfileId } ?? profiles.first
    }
    private var favorites: Set<String> { themeManager.favorites(for: activeProfile?.id) }

    private var visibleDefinitions: [ThemeDefinition] {
        ThemeRegistry.shared.definitions(in: tab, favorites: favorites)
            .yamFiltered(by: query)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YAMSpacing.large) {
                appearanceCard
                if let error = themeManager.saveError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(theme.primaryTextColor)
                        .padding(YAMSpacing.medium)
                        .yamSurface(theme)
                }
                currentThemeCard
                searchField
                tabBar
                resultsSummary
                themeGrid
            }
            .padding(YAMSpacing.large)
            .padding(.bottom, YAMSpacing.section * 3)
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
        }
        .background { YAMAmbientBackground(theme: theme) }
        .navigationTitle("Thèmes et apparence")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.appearance.colorScheme)
        .sheet(item: $selectedDefinition) { definition in
            ThemeDetailSheet(definition: definition)
                .yamSheetPresentation(.window)
        }
    }

    /// Carte d'origine : l'apparence claire/sombre, inchangée.
    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            Text("Un espace qui vous ressemble.")
                .font(.system(.title3, design: theme.fontDesign, weight: .bold))
                .foregroundStyle(theme.primaryTextColor)
            Text("Les mêmes repères, une autre ambiance. Le thème est enregistré pour \(activeProfile?.name ?? "votre profil").")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
            Picker("Apparence", selection: $themeManager.appearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            .pickerStyle(.menu)
            .frame(minHeight: YAMSpacing.minimumTarget)
            Text("Clair, sombre ou automatique : ce choix s’applique à tous les profils sur cet appareil.")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(YAMSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yamSurface(theme)
    }

    /// Thème actuellement appliqué, clairement indiqué, avec réinitialisation.
    private var currentThemeCard: some View {
        let current = theme
        return VStack(alignment: .leading, spacing: YAMSpacing.medium) {
            Text("Thème actuel")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryTextColor)
            HStack(alignment: .top, spacing: YAMSpacing.large) {
                ThemeMiniature(theme: current)
                    .frame(maxWidth: 260)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: YAMSpacing.small) {
                    HStack(spacing: YAMSpacing.small) {
                        Image(systemName: current.icon)
                            .font(.body.weight(current.iconWeight))
                            .foregroundStyle(current.accentColor)
                        Text(current.name)
                            .font(.system(.body, design: current.fontDesign, weight: .semibold))
                            .foregroundStyle(current.primaryTextColor)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(current.accentColor)
                            .accessibilityHidden(true)
                    }
                    Text(current.subtitle)
                        .font(.footnote)
                        .foregroundStyle(current.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button {
                        themeManager.resetToClassic(profile: activeProfile, in: modelContext)
                    } label: {
                        Label("Réinitialiser", systemImage: "arrow.counterclockwise")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(current.accentColor)
                            .frame(minHeight: YAMSpacing.minimumTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(current.id == "classic")
                    .accessibilityHint("Restaure le thème Classique pour \(activeProfile?.name ?? "ce profil").")
                }
            }
        }
        .padding(YAMSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yamSurface(theme)
        .accessibilityElement(children: .combine)
        .accessibilityValue("Thème actuel : \(current.name)")
    }

    private var searchField: some View {
        HStack(spacing: YAMSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.secondaryTextColor)
                .accessibilityHidden(true)
            TextField("Rechercher : Windows XP, Ubuntu, Algérie…", text: $query)
                .font(.body)
                .foregroundStyle(theme.primaryTextColor)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel("Rechercher un thème")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.secondaryTextColor)
                        .frame(width: YAMSpacing.minimumTarget, height: YAMSpacing.minimumTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Effacer la recherche")
            }
        }
        .padding(.horizontal, YAMSpacing.large)
        .padding(.vertical, YAMSpacing.small)
        .background(theme.inputBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(theme.borderColor, lineWidth: 1)
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: YAMSpacing.small) {
                ForEach(ThemeGalleryTab.allCases) { candidate in
                    let isSelected = tab == candidate
                    let count = ThemeRegistry.shared.definitions(in: candidate, favorites: favorites).count
                    Button {
                        YAMFeedback.selection()
                        tab = candidate
                    } label: {
                        Text(candidate.title)
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(minHeight: YAMLayout.chipHeight)
                            .background(isSelected ? theme.accentColor : theme.secondaryCardBackground, in: Capsule())
                            .foregroundStyle(isSelected ? theme.onAccentColor : theme.primaryTextColor)
                            .overlay {
                                Capsule().strokeBorder(isSelected ? .clear : theme.borderColor, lineWidth: 1)
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(candidate.title), \(count) thème\(count == 1 ? "" : "s")")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var resultsSummary: some View {
        let count = visibleDefinitions.count
        return Text("\(count) thème\(count == 1 ? "" : "s")")
            .font(.caption)
            .foregroundStyle(theme.secondaryTextColor)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var themeGrid: some View {
        if visibleDefinitions.isEmpty {
            emptyState
        } else {
            LazyVGrid(
                columns: typeSize.isAccessibilitySize
                    ? [GridItem(.flexible())]
                    : [GridItem(.adaptive(minimum: 240, maximum: 360), spacing: YAMSpacing.medium)],
                spacing: YAMSpacing.medium
            ) {
                ForEach(visibleDefinitions) { definition in
                    ThemeGalleryCard(
                        definition: definition,
                        isCurrent: definition.id == themeManager.activeThemeId,
                        isFavorite: favorites.contains(definition.id)
                    ) {
                        YAMFeedback.selection()
                        selectedDefinition = definition
                    } onToggleFavorite: {
                        themeManager.toggleFavorite(definition.id, for: activeProfile?.id)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: YAMSpacing.small) {
            Image(systemName: tab == .favorites ? "star" : "magnifyingglass")
                .font(.title2)
                .foregroundStyle(theme.secondaryTextColor)
            Text(tab == .favorites ? "Aucun favori pour l'instant." : "Aucun thème ne correspond.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(theme.primaryTextColor)
            Text(tab == .favorites
                 ? "Touchez l'étoile d'une carte de thème pour la retrouver ici."
                 : "Essayez un autre mot : « Windows », « Ubuntu », « Algérie »…")
                .font(.footnote)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(YAMSpacing.section)
        .yamSurface(theme)
    }
}

//
//  ThemeMiniature — miniature d'écran d'accueil d'un thème.
//  Composant d'origine, conservé à l'identique.
//

struct ThemeMiniature: View {
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.secondaryTextColor.opacity(0.35))
                    .frame(height: 6)
                Text("Parler")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .foregroundStyle(theme.onAccentColor)
                    .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
            }
            .padding(8)
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius / 2))
            HStack(spacing: 7) {
                VStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == 0 ? theme.accentColor.opacity(0.3) : theme.secondaryTextColor.opacity(0.15))
                            .frame(height: 6)
                    }
                }
                .frame(width: 30)
                miniaturePhrase("Bonjour", symbol: "hand.wave")
                miniaturePhrase("Merci", symbol: "heart")
            }
        }
        .padding(YAMSpacing.medium)
        .background { YAMAmbientBackground(theme: theme) }
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius * 0.7))
    }

    private func miniaturePhrase(_ title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(theme.iconWeight))
                .foregroundStyle(theme.accentColor)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(theme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius / 2))
    }
}

#Preview {
    NavigationStack { ThemeSelectionView() }
        .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

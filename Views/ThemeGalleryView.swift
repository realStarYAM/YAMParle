//
//  ThemeGalleryView.swift
//  YAMParle
//
//  Briques de la galerie de thèmes : carte de thème, badge de catégorie,
//  fiche détaillée (grand aperçu, palette, Appliquer, Favoris, Réinitialiser)
//  et aperçu agrandi dessiné avec les jetons du thème.
//

import SwiftUI
import SwiftData

/// Badge de catégorie : symbole + titre, dans les teintes du thème affiché.
struct ThemeCategoryBadge: View {
    let category: ThemeCategory
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.symbol)
                .font(.caption2)
            Text(category.title)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundStyle(theme.secondaryTextColor)
        .background(theme.secondaryCardBackground, in: Capsule())
        .overlay {
            Capsule().strokeBorder(theme.borderColor, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// Carte de la grille : miniature, nom, catégorie, état, étoile favori.
/// La carte ouvre la fiche détaillée ; l'étoile agit séparément.
struct ThemeGalleryCard: View {
    let definition: ThemeDefinition
    let isCurrent: Bool
    let isFavorite: Bool
    var onOpen: () -> Void
    var onToggleFavorite: () -> Void

    private var theme: AppTheme { ThemeRegistry.shared.theme(for: definition.id) }

    var body: some View {
        Button(action: onOpen) {
            cardContent
        }
        .buttonStyle(.yamPress)
        .overlay(alignment: .topTrailing) {
            favoriteButton.padding(6)
        }
        .accessibilityLabel("\(definition.name), catégorie \(definition.category.title). \(definition.subtitle)")
        .accessibilityValue(isCurrent ? "Thème actuel" : "Thème disponible")
        .accessibilityHint("Ouvre l'aperçu du thème avec les boutons Appliquer et Favoris.")
        .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.medium) {
            ThemeMiniature(theme: theme)
                .accessibilityHidden(true)
            HStack(spacing: YAMSpacing.small) {
                Image(systemName: definition.icon)
                    .font(.body.weight(definition.iconWeight))
                    .foregroundStyle(theme.accentColor)
                    .accessibilityHidden(true)
                Text(definition.name)
                    .font(.system(.body, design: definition.fontDesign, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            Text(definition.subtitle)
                .font(.footnote)
                .foregroundStyle(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                ThemeCategoryBadge(category: definition.category, theme: theme)
                Spacer(minLength: 0)
                Text(isCurrent ? "Thème actuel" : "Aperçu et application")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
            }
        }
        .foregroundStyle(theme.primaryTextColor)
        .padding(YAMSpacing.large)
        .yamSurface(theme, selected: isCurrent)
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.callout)
                .foregroundStyle(isFavorite ? theme.accentColor : theme.secondaryTextColor)
                .frame(width: YAMSpacing.minimumTarget, height: YAMSpacing.minimumTarget)
                .background(theme.cardBackground.opacity(0.92), in: Circle())
                .overlay {
                    Circle().strokeBorder(theme.borderColor, lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Favori")
        .accessibilityValue(isFavorite ? "Ajouté aux favoris" : "Pas encore favori")
        .accessibilityHint("Fait basculer ce thème dans les favoris du profil en cours.")
    }
}

/// Fiche détaillée : grand aperçu, informations, palette, actions.
struct ThemeDetailSheet: View {
    let definition: ThemeDefinition

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var profileManager = ProfileManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    private var activeProfile: UserProfile? {
        profiles.first { $0.id == profileManager.activeProfileId } ?? profiles.first
    }
    private var theme: AppTheme { ThemeRegistry.shared.theme(for: definition.id) }
    private var isCurrent: Bool { themeManager.activeThemeId == definition.id }
    private var isFavorite: Bool { themeManager.isFavorite(definition.id, for: activeProfile?.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: YAMSpacing.section) {
                    ThemeLargePreview(theme: theme)
                        .accessibilityHidden(true)
                    header
                    paletteSection
                    controls
                }
                .padding(YAMSpacing.page)
                .padding(.bottom, YAMSpacing.section * 2)
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
            }
            .background {
                ZStack {
                    theme.backgroundColor
                    if theme.ornament == .glow {
                        RadialGradient(
                            colors: [theme.accentColor.opacity(0.1), .clear],
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 420
                        )
                    }
                }
                .ignoresSafeArea()
            }
            .navigationTitle(definition.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .tint(theme.accentColor)
        .preferredColorScheme(themeManager.appearance.colorScheme)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            HStack(spacing: YAMSpacing.small) {
                Image(systemName: definition.icon)
                    .font(.title3.weight(definition.iconWeight))
                    .foregroundStyle(theme.accentColor)
                ThemeCategoryBadge(category: definition.category, theme: theme)
                Spacer(minLength: 0)
                if isCurrent {
                    Label("Thème actuel", systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                }
            }
            Text(definition.subtitle)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.medium) {
            Text("Palette")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryTextColor)
            HStack(spacing: YAMSpacing.section) {
                paletteDot("Accent", theme.accentColor)
                paletteDot("Panneau", theme.cardBackground)
                paletteDot("Fond", theme.backgroundColor)
                paletteDot("Texte", theme.primaryTextColor)
                paletteDot("Bordure", theme.borderColor)
            }
        }
    }

    private func paletteDot(_ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .overlay {
                    Circle().strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
                }
            Text(label)
                .font(.caption2)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Couleur \(label)")
    }

    private var controls: some View {
        VStack(spacing: YAMSpacing.medium) {
            if isCurrent {
                Label("Thème actuel", systemImage: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .frame(maxWidth: .infinity, minHeight: YAMSpacing.minimumTarget)
                    .background(theme.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                    .accessibilityLabel("Ce thème est celui en cours")
            } else {
                Button {
                    themeManager.setTheme(id: definition.id, profile: activeProfile, in: modelContext)
                    dismiss()
                } label: {
                    Label("Appliquer", systemImage: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.onAccentColor)
                        .frame(maxWidth: .infinity, minHeight: YAMSpacing.minimumTarget)
                        .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                }
                .buttonStyle(.yamPress)
                .accessibilityHint("Applique ce thème à \(activeProfile?.name ?? "votre profil") sans changer la disposition.")
            }

            Button {
                themeManager.toggleFavorite(definition.id, for: activeProfile?.id)
            } label: {
                Label(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris", systemImage: isFavorite ? "star.slash" : "star")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(theme.primaryTextColor)
                    .frame(maxWidth: .infinity, minHeight: YAMSpacing.minimumTarget)
                    .background(theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                            .strokeBorder(theme.borderColor, lineWidth: 1)
                    }
            }
            .buttonStyle(.yamPress)
            .accessibilityValue(isFavorite ? "Dans les favoris" : "Hors favoris")

            if definition.id != "classic" {
                Button {
                    themeManager.resetToClassic(profile: activeProfile, in: modelContext)
                } label: {
                    Label("Réinitialiser au thème par défaut", systemImage: "arrow.counterclockwise")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(theme.destructiveColor)
                        .frame(maxWidth: .infinity, minHeight: YAMSpacing.minimumTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Restaure le thème Classique.")
            }
        }
    }
}

/// Grand aperçu : une miniature d'écran d'accueil dessinée uniquement avec
/// les jetons du thème (couleurs, coins, panneaux, boutons, bordures).
struct ThemeLargePreview: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("YAMParle", systemImage: theme.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
                Text("\(theme.badgeName.isEmpty ? "Aperçu" : theme.badgeName)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.secondaryCardBackground, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(theme.borderColor, lineWidth: 1)
                    }
            }
            HStack(spacing: 8) {
                previewChip("Bonjour", selected: true)
                previewChip("Merci", selected: false)
                previewChip("Oui", selected: false)
            }
            HStack(spacing: 10) {
                previewCard("Bonjour !", symbol: "hand.wave")
                previewCard("J'ai faim", symbol: "fork.knife")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Votre phrase")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryTextColor)
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                    .fill(theme.inputBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                            .strokeBorder(theme.borderColor, lineWidth: 1)
                    }
                    .frame(height: 44)
                    .overlay(alignment: .leading) {
                        Text("Bonjour, j'aimerais…")
                            .font(.footnote)
                            .foregroundStyle(theme.secondaryTextColor)
                            .padding(.leading, 10)
                    }
            }
            Label("Parler", systemImage: "speaker.wave.2.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.onAccentColor)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                theme.backgroundColor
                if theme.ornament == .glow {
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.14), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 320
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: max(12, theme.cornerRadius), style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: max(12, theme.cornerRadius), style: .continuous)
                .strokeBorder(theme.borderColor, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private func previewChip(_ label: String, selected: Bool) -> some View {
        Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(selected ? theme.onAccentColor : theme.primaryTextColor)
            .background(selected ? theme.selectedColor : theme.cardBackground, in: Capsule())
            .overlay {
                Capsule().strokeBorder(selected ? theme.accentColor : theme.borderColor, lineWidth: selected ? 2 : 1)
            }
    }

    private func previewCard(_ label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.body.weight(theme.iconWeight))
                .foregroundStyle(theme.accentColor)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(10)
        .yamSurface(theme)
    }
}

#Preview {
    ThemeDetailSheet(definition: ThemeRegistry.shared.definitions[10])
        .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

//
//  ThemeRegistry.swift
//  YAMParle
//
//  Registre central des thèmes : un catalogue de données pures (voir
//  ThemeDefinition) et une mise en forme paresseuse des objets AppTheme.
//
//  Performance : les ~100 définitions sont de simples valeurs (codes hexa,
//  chiffres) — aucun Color, aucune image n'existe tant qu'un thème n'est
//  pas affiché. L'AppTheme d'un thème est construit une seule fois puis
//  mis en cache ; la galerie défile donc aussi vite qu'une liste de texte.
//  Aucune ressource graphique n'est chargée en bloc.
//

import SwiftUI

/// Agrégat du catalogue : chaque fichier `Models/Themes/ThemeData*.swift`
/// apporte une catégorie. Ajouter un thème = ajouter une ligne ; ajouter
/// une catégorie = ajouter un fichier + un cas dans ThemeCategory.
enum ThemeCatalog {
    static let all: [ThemeDefinition] =
        essentials + windows + linux + macos + anime + pays
}

/// Registre des thèmes. Le rendu d'un thème est demandé par identifiant ;
/// les thèmes d'origine sont servis par leurs définitions statiques
/// d'origine pour un rendu strictement identique.
final class ThemeRegistry {
    static let shared = ThemeRegistry()

    private(set) var definitions: [ThemeDefinition]
    private let index: [String: Int]
    private var materialized: [String: AppTheme] = [:]

    init() {
        definitions = ThemeCatalog.all
        index = Dictionary(uniqueKeysWithValues: definitions.enumerated().map { ($1.id, $0) })
    }

    /// Thème affiché pour un identifiant. Un identifiant inconnu retombe
    /// sur le thème Classique, comme avant l'existence du registre.
    func theme(for id: String) -> AppTheme {
        if let cached = materialized[id] {
            return cached
        }
        let theme: AppTheme
        if let legacy = AppTheme.legacyInstances[id] {
            // Thèmes d'origine : rendu strictement identique au stock.
            theme = legacy
        } else if let position = index[id], let definition = definitions[safe: position] {
            theme = definition.asAppTheme()
        } else {
            theme = AppTheme.classic
        }
        materialized[id] = theme
        return theme
    }

    func definition(for id: String) -> ThemeDefinition? {
        guard let position = index[id] else { return nil }
        return definitions[safe: position]
    }

    func definitions(in category: ThemeCategory) -> [ThemeDefinition] {
        definitions.filter { $0.category == category }
    }

    /// Thèmes visibles pour un onglet de la galerie.
    func definitions(in tab: ThemeGalleryTab, favorites: Set<String>) -> [ThemeDefinition] {
        if let category = tab.category {
            return definitions(in: category)
        }
        switch tab {
        case .favorites:
            return definitions.filter { favorites.contains($0.id) }
        case .all:
            return definitions
        default:
            return definitions
        }
    }
}

private extension Array {
    subscript(safe position: Int) -> Element? {
        indices.contains(position) ? self[position] : nil
    }
}

extension ThemeDefinition {
    /// Transforme les données pures en `AppTheme` affichable. Les couleurs
    /// adaptatives clair/sombre sont construites ici, une seule fois par
    /// thème (mise en cache par le ThemeRegistry).
    func asAppTheme() -> AppTheme {
        func adaptive(_ pair: ThemeColorPair) -> Color {
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(Color(hex: pair.dark))
                    : UIColor(Color(hex: pair.light))
            })
        }
        return AppTheme(
            id: id,
            name: name,
            subtitle: subtitle,
            icon: icon,
            accentColor: adaptive(accent),
            secondaryAccentColor: adaptive(secondaryAccent),
            highlightColor: adaptive(accent),
            backgroundColor: adaptive(background),
            cardBackground: adaptive(surface),
            secondaryCardBackground: adaptive(surfaceSecondary),
            inputBackground: adaptive(surface),
            primaryTextColor: adaptive(textPrimary),
            secondaryTextColor: adaptive(textSecondary),
            onAccentColor: adaptive(onAccent),
            borderColor: adaptive(border),
            borderWidth: borderWidth,
            shadowColor: Color.black.opacity(shadowOpacity),
            cornerRadius: max(12, cornerRadius),
            buttonCornerRadius: max(10, buttonCornerRadius),
            fontDesign: fontDesign,
            previewPalette: [adaptive(accent), adaptive(secondaryAccent), adaptive(background)],
            badgeName: badgeName,
            iconWeight: iconWeight,
            ornament: ornament,
            selectedColor: adaptive(selectedColor),
            destructiveColor: adaptive(destructiveColor),
            buttonStyle: buttonStyle == .bevel ? .filled : buttonStyle,
            cardStyle: cardStyle == .bevel ? .solid : cardStyle,
            category: category
        )
    }
}

extension String {
    /// Forme pliable : minuscules, sans accents. Pour une recherche qui
    /// trouve « Windows XP », « ubuntu », « Algérie » comme « algerie ».
    var yamFolded: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr"))
    }
}

extension Array where Element == ThemeDefinition {
    /// Filtre une liste de thèmes par une recherche libre.
    func yamFiltered(by query: String) -> [ThemeDefinition] {
        let folded = query.trimmingCharacters(in: .whitespacesAndNewlines).yamFolded
        guard !folded.isEmpty else { return self }
        return filter { definition in
            let haystack = (
                definition.name
                + " " + definition.subtitle
                + " " + definition.badgeName
                + " " + definition.category.title
            ).yamFolded
            return haystack.contains(folded)
        }
    }
}

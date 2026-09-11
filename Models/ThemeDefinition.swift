//
//  ThemeDefinition.swift
//  YAMParle
//
//  Données pures d'un thème : des codes hexadécimaux et quelques paramètres,
//  sans aucun objet graphique. Le catalogue entier (centaines de thèmes)
//  reste donc léger en mémoire ; les `Color` ne sont construits que quand
//  un thème est réellement affiché (voir ThemeRegistry).
//

import SwiftUI

/// Catégories de la galerie Réglages › Apparence › Thèmes.
public enum ThemeCategory: String, CaseIterable, Identifiable, Hashable {
    case essentials, windows, linux, macos, anime, country

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .essentials: return "Essentiels"
        case .windows: return "Windows"
        case .linux: return "Linux"
        case .macos: return "macOS"
        case .anime: return "Anime"
        case .country: return "Pays"
        }
    }

    public var symbol: String {
        switch self {
        case .essentials: return "sparkles"
        case .windows: return "square.grid.2x2"
        case .linux: return "terminal.fill"
        case .macos: return "desktopcomputer"
        case .anime: return "theatermasks.fill"
        case .country: return "globe"
        }
    }
}

/// Onglets de la galerie : les catégories, plus « Tous » et « Favoris ».
public enum ThemeGalleryTab: String, CaseIterable, Identifiable, Hashable {
    case all, essentials, windows, linux, macos, anime, country, favorites

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "Tous"
        case .essentials: return "Essentiels"
        case .windows: return "Windows"
        case .linux: return "Linux"
        case .macos: return "macOS"
        case .anime: return "Anime"
        case .country: return "Pays"
        case .favorites: return "Favoris"
        }
    }

    /// Catégorie associée ; nil pour « Tous » et « Favoris ».
    public var category: ThemeCategory? {
        switch self {
        case .all, .favorites: return nil
        case .essentials: return .essentials
        case .windows: return .windows
        case .linux: return .linux
        case .macos: return .macos
        case .anime: return .anime
        case .country: return .country
        }
    }
}

/// Rendu des boutons dominants d'un thème (appliqué aux actions principales).
public enum ThemeButtonStyle: String, CaseIterable, Hashable {
    /// Corps plein de couleur d'accent, texte contrasté — rendu d'origine de l'app.
    case filled
    /// Fond teinté de l'accent, texte de base, contour fin.
    case tinted
    /// Fond transparent, contour et texte d'accent.
    case outline
    /// Dégradé accent → accent secondaire.
    case gradient
    /// Corps plein + arêtes biseautées (panneaux rétro).
    case bevel
}

/// Rendu des panneaux et cartes d'un thème (appliqué aux surfaces `yamSurface`).
public enum ThemeCardStyle: String, CaseIterable, Hashable {
    /// Fond plein, bordure fine, ombre légère — rendu d'origine de l'app.
    case solid
    /// Comme solid, ombre un peu plus marquée.
    case raised
    /// Sans ombre, bordure fine.
    case flat
    /// Arête supérieure sombre, effet d'enfoncement.
    case inset
    /// Arêtes biseautées claires/sombres, panneaux rétro.
    case bevel
    /// Fond translucide, style vitre (désactivé si « réduire la transparence »).
    case glass
    /// Dégradé vertical surface → surface secondaire.
    case gradient
}

/// Couleurs déclarées en hexadécimal, en clair et en sombre.
///
/// Une déclaration reste du texte : nulle image, nulle ressource lourde.
public struct ThemeColorPair: Hashable {
    public let light: String
    public let dark: String

    public init(_ light: String, _ dark: String) {
        self.light = light
        self.dark = dark
    }

    public init(_ both: String) {
        self.light = both
        self.dark = both
    }

    public static func p(_ light: String, _ dark: String) -> ThemeColorPair {
        ThemeColorPair(light, dark)
    }

    public static func p(_ both: String) -> ThemeColorPair {
        ThemeColorPair(both)
    }

    /// Couleur adaptative clair/sombre ; construite à la demande, mise en cache
    /// par le ThemeRegistry.
    public var adaptive: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

/// Utilitaires hexadécimaux partagés par le catalogue (dérivations sûres).
public enum ThemePalette {
    public static func components(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (Int(value >> 16 & 0xFF), Int(value >> 8 & 0xFF), Int(value & 0xFF))
    }

    /// Luminance relative WCAG d'une couleur hexadécimale.
    public static func luminance(_ hex: String) -> Double {
        let c = components(hex)
        let r = Double(c.r) / 255
        let g = Double(c.g) / 255
        let b = Double(c.b) / 255
        func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// Mélange deux couleurs hexadécimales, `t` dans [0, 1].
    public static func mix(_ a: String, _ b: String, _ t: Double) -> String {
        let ca = components(a), cb = components(b)
        func channel(_ x: Int, _ y: Int) -> Int { Int((Double(x) * (1 - t) + Double(y) * t).rounded()) }
        return String(format: "#%02X%02X%02X", channel(ca.r, cb.r), channel(ca.g, cb.g), channel(ca.b, cb.b))
    }

    /// Blanc ou noir selon la luminance de la surface : le texte obtenu est
    /// toujours celui qui maximise le contraste (croisement WCAG ≈ 0.2).
    public static func recommendedOn(_ hex: String) -> String {
        luminance(hex) > 0.2 ? "#101418" : "#FFFFFF"
    }
}

/// Déclaration complète d'un thème, uniquement des données.
///
/// Champs exigés par la galerie : background, surface, surfaceSecondary, accent,
/// secondaryAccent, textPrimary, textSecondary, border, selectedColor,
/// destructiveColor, cornerRadius, shadow (opacité), buttonStyle, cardStyle.
/// Les champs optionnels reçoivent des valeurs cohérentes quand ils sont omis :
/// la surface secondaire est dérivée entre surface et fond, la couleur « sur
/// accent » suit la luminance de l'accent (contraste garanti), la sélection
/// reprend l'accent.
public struct ThemeDefinition: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let icon: String
    public let category: ThemeCategory
    public let accent: ThemeColorPair
    public let secondaryAccent: ThemeColorPair
    public let background: ThemeColorPair
    public let surface: ThemeColorPair
    public let surfaceSecondary: ThemeColorPair
    public let textPrimary: ThemeColorPair
    public let textSecondary: ThemeColorPair
    public let border: ThemeColorPair
    public let selectedColor: ThemeColorPair
    public let destructiveColor: ThemeColorPair
    public let onAccent: ThemeColorPair
    public let cornerRadius: CGFloat
    public let buttonCornerRadius: CGFloat
    public let shadowOpacity: Double
    public let borderWidth: CGFloat
    public let fontDesign: Font.Design
    public let iconWeight: Font.Weight
    public let ornament: AppTheme.Ornament
    public let badgeName: String
    public let buttonStyle: ThemeButtonStyle
    public let cardStyle: ThemeCardStyle

    public init(
        _ id: String,
        _ name: String,
        _ subtitle: String,
        _ icon: String,
        _ category: ThemeCategory,
        _ accent: ThemeColorPair,
        _ secondaryAccent: ThemeColorPair,
        _ background: ThemeColorPair,
        _ surface: ThemeColorPair,
        textPrimary: ThemeColorPair = ThemeColorPair("#202735", "#F4F5F8"),
        textSecondary: ThemeColorPair = ThemeColorPair("#586174", "#B6BDCD"),
        border: ThemeColorPair = ThemeColorPair("#D9DEE8", "#414958"),
        surfaceSecondary: ThemeColorPair? = nil,
        selectedColor: ThemeColorPair? = nil,
        destructiveColor: ThemeColorPair = ThemeColorPair("#A62C22", "#FF9A90"),
        onAccent: ThemeColorPair? = nil,
        cornerRadius: CGFloat = 14,
        buttonCornerRadius: CGFloat = 11,
        shadowOpacity: Double = 0.05,
        borderWidth: CGFloat = 1,
        fontDesign: Font.Design = .default,
        iconWeight: Font.Weight = .medium,
        ornament: AppTheme.Ornament = .glow,
        badgeName: String = "",
        buttonStyle: ThemeButtonStyle = .filled,
        cardStyle: ThemeCardStyle = .solid
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.accent = accent
        self.secondaryAccent = secondaryAccent
        self.background = background
        self.surface = surface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.border = border
        self.surfaceSecondary = surfaceSecondary ?? ThemeColorPair(
            ThemePalette.mix(surface.light, background.light, 0.55),
            ThemePalette.mix(surface.dark, background.dark, 0.55)
        )
        self.selectedColor = selectedColor ?? accent
        self.destructiveColor = destructiveColor
        self.onAccent = onAccent ?? ThemeColorPair(
            ThemePalette.recommendedOn(accent.light),
            ThemePalette.recommendedOn(accent.dark)
        )
        // Règle principale : les thèmes ne modifient jamais la structure ou la géométrie de YAMParle.
        // Les cartes et boutons conservent toujours les arrondis modernes de l'application.
        self.cornerRadius = max(12, cornerRadius)
        self.buttonCornerRadius = max(10, buttonCornerRadius)
        self.shadowOpacity = shadowOpacity
        self.borderWidth = borderWidth
        self.fontDesign = fontDesign
        self.iconWeight = iconWeight
        self.ornament = ornament
        self.badgeName = badgeName
        self.buttonStyle = buttonStyle == .bevel ? .filled : buttonStyle
        self.cardStyle = cardStyle == .bevel ? .solid : cardStyle
    }
}

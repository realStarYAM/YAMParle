import SwiftUI

public struct AppTheme: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let icon: String
    public let accentColor: Color
    public let secondaryAccentColor: Color
    public let highlightColor: Color
    public let backgroundColor: Color
    public let cardBackground: Color
    public let secondaryCardBackground: Color
    public let inputBackground: Color
    public let primaryTextColor: Color
    public let secondaryTextColor: Color
    public let onAccentColor: Color
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let shadowColor: Color
    public let cornerRadius: CGFloat
    public let buttonCornerRadius: CGFloat
    public let fontDesign: Font.Design
    public let previewPalette: [Color]
    public let badgeName: String
    public let iconWeight: Font.Weight
    public let ornament: Ornament

    public enum Ornament {
        case glow, line, orbit
    }

    public static func == (lhs: AppTheme, rhs: AppTheme) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    private static func adaptive(_ light: String, _ dark: String) -> Color {
        let lightColor = UIColor(Color(hex: light))
        let darkColor = UIColor(Color(hex: dark))
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }

    private static func make(
        id: String, name: String, subtitle: String, icon: String,
        accent: String, darkAccent: String, secondary: String,
        background: String, darkBackground: String,
        surface: String = "#FFFFFF", darkSurface: String,
        elevated: String, darkElevated: String,
        radius: CGFloat, buttonRadius: CGFloat,
        design: Font.Design = .default, weight: Font.Weight = .medium,
        ornament: Ornament = .glow, badge: String
    ) -> AppTheme {
        let tint = adaptive(accent, darkAccent)
        return AppTheme(
            id: id, name: name, subtitle: subtitle, icon: icon,
            accentColor: tint,
            secondaryAccentColor: adaptive(secondary, darkAccent),
            highlightColor: tint,
            backgroundColor: adaptive(background, darkBackground),
            cardBackground: adaptive(surface, darkSurface),
            secondaryCardBackground: adaptive(elevated, darkElevated),
            inputBackground: adaptive(surface, darkSurface),
            primaryTextColor: adaptive("#202735", "#F4F5F8"),
            secondaryTextColor: adaptive("#586174", "#B6BDCD"),
            onAccentColor: adaptive("#FFFFFF", "#131925"),
            borderColor: adaptive("#D9DEE8", "#414958"),
            borderWidth: 1,
            shadowColor: Color.black.opacity(0.045),
            cornerRadius: radius, buttonCornerRadius: buttonRadius,
            fontDesign: design,
            previewPalette: [tint, Color(hex: secondary), adaptive(background, darkBackground)],
            badgeName: badge, iconWeight: weight, ornament: ornament
        )
    }

    public static let classic = make(
        id: "classic", name: "Classique", subtitle: "Lumière douce, encre et iris.",
        icon: "bubble.left.and.bubble.right.fill",
        accent: "#5551C9", darkAccent: "#B7B4FF", secondary: "#7074A5",
        background: "#F4F5FA", darkBackground: "#141722", darkSurface: "#202431",
        elevated: "#ECECF7", darkElevated: "#2C3042",
        radius: 24, buttonRadius: 18, badge: "Iris"
    )

    public static let dragonBall = make(
        id: "dragon_ball", name: "Dragon Ball", subtitle: "Orange martial, bleu nuit, énergie contenue.",
        icon: "bolt.circle.fill",
        accent: "#AD4706", darkAccent: "#FFB86C", secondary: "#2555A0",
        background: "#FFF7ED", darkBackground: "#131B2D", darkSurface: "#202C43",
        elevated: "#FCEBD9", darkElevated: "#2A3850",
        radius: 22, buttonRadius: 16, design: .rounded, weight: .bold,
        ornament: .orbit, badge: "Énergie"
    )

    public static let windows = make(
        id: "windows", name: "Windows", subtitle: "Bleu Fluent et panneaux nets.",
        icon: "square.grid.2x2.fill",
        accent: "#0067AC", darkAccent: "#8FCFFF", secondary: "#287A91",
        background: "#F0F5FA", darkBackground: "#121C27", darkSurface: "#202D3B",
        elevated: "#E4EEF7", darkElevated: "#2B3B4D",
        radius: 12, buttonRadius: 10, ornament: .line, badge: "Fluent"
    )

    public static let macOS = make(
        id: "macos", name: "macOS", subtitle: "Surfaces nacrées et accents bleus.",
        icon: "desktopcomputer",
        accent: "#245BC4", darkAccent: "#A6C2FF", secondary: "#6958AF",
        background: "#F3F3F6", darkBackground: "#19191F", darkSurface: "#28282F",
        elevated: "#EAEAF1", darkElevated: "#36363F",
        radius: 26, buttonRadius: 20, badge: "Nacre"
    )

    public static let ubuntu = make(
        id: "ubuntu", name: "Ubuntu", subtitle: "Aubergine, terre cuite et chaleur.",
        icon: "circle.hexagongrid.fill",
        accent: "#AF401A", darkAccent: "#FFB397", secondary: "#753767",
        background: "#FBF4F7", darkBackground: "#251522", darkSurface: "#382333",
        elevated: "#F1E4ED", darkElevated: "#493143",
        radius: 18, buttonRadius: 14, design: .rounded,
        ornament: .orbit, badge: "Aubergine"
    )

    public static let linuxMint = make(
        id: "linux_mint", name: "Linux Mint", subtitle: "Sauge, vert profond et calme.",
        icon: "leaf.fill",
        accent: "#306C42", darkAccent: "#A5D7A8", secondary: "#59795C",
        background: "#F2F7F2", darkBackground: "#15201B", darkSurface: "#24342B",
        elevated: "#E3EEE4", darkElevated: "#32473A",
        radius: 22, buttonRadius: 18, badge: "Sauge"
    )

    public static let dragon = make(
        id: "dragon", name: "Dragon", subtitle: "Obsidienne, braise et détails cuivrés.",
        icon: "flame.fill",
        accent: "#AC373D", darkAccent: "#FFADA7", secondary: "#926735",
        background: "#FAF4F0", darkBackground: "#21191B", darkSurface: "#342729",
        elevated: "#F1E5DE", darkElevated: "#493537",
        radius: 16, buttonRadius: 12, weight: .semibold,
        ornament: .line, badge: "Obsidienne"
    )

    public static let allThemes: [AppTheme] = [
        .classic, .dragonBall, .windows, .macOS, .ubuntu, .linuxMint, .dragon
    ]

    public static func theme(for id: String) -> AppTheme {
        allThemes.first(where: { $0.id == id }) ?? .classic
    }
}

//
//  AppTheme.swift
//  YAMParle
//

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
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let shadowColor: Color
    public let cornerRadius: CGFloat
    public let buttonCornerRadius: CGFloat
    public let fontDesign: Font.Design
    public let previewPalette: [Color]
    public let isDark: Bool
    public let badgeName: String

    public static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - 1. Classique
    public static let classic = AppTheme(
        id: "classic",
        name: "Classique",
        subtitle: "Thème d'origine de YAMParle, sobre et adapté à la CAA",
        icon: "sparkles",
        accentColor: Color(hex: "#1E73F2"),
        secondaryAccentColor: Color(hex: "#30D158"),
        highlightColor: Color(hex: "#FF9F0A"),
        backgroundColor: Color(UIColor.systemGroupedBackground),
        cardBackground: Color(UIColor.secondarySystemGroupedBackground),
        secondaryCardBackground: Color(UIColor.tertiarySystemGroupedBackground),
        inputBackground: Color(UIColor.secondarySystemGroupedBackground),
        primaryTextColor: Color.primary,
        secondaryTextColor: Color.secondary,
        borderColor: Color.primary.opacity(0.08),
        borderWidth: 1.2,
        shadowColor: Color.black.opacity(0.04),
        cornerRadius: 16,
        buttonCornerRadius: 12,
        fontDesign: .rounded,
        previewPalette: [Color(hex: "#1E73F2"), Color(hex: "#30D158"), Color(hex: "#FF9F0A"), Color(hex: "#FFFFFF")],
        isDark: false,
        badgeName: "Standard"
    )

    // MARK: - 2. Dragon Ball
    public static let dragonBall = AppTheme(
        id: "dragon_ball",
        name: "Dragon Ball",
        subtitle: "Style énergique anime : orange gi, bleu martial et jaune ki éclatant",
        icon: "bolt.fill",
        accentColor: Color(hex: "#FF6F00"),
        secondaryAccentColor: Color(hex: "#1565C0"),
        highlightColor: Color(hex: "#FFD600"),
        backgroundColor: Color(hex: "#0D1326"),
        cardBackground: Color(hex: "#16203D"),
        secondaryCardBackground: Color(hex: "#222F55"),
        inputBackground: Color(hex: "#101830"),
        primaryTextColor: Color(hex: "#FFFFFF"),
        secondaryTextColor: Color(hex: "#FFE082"),
        borderColor: Color(hex: "#FF8F00").opacity(0.5),
        borderWidth: 1.8,
        shadowColor: Color(hex: "#FF6F00").opacity(0.28),
        cornerRadius: 14,
        buttonCornerRadius: 12,
        fontDesign: .rounded,
        previewPalette: [Color(hex: "#FF6F00"), Color(hex: "#1565C0"), Color(hex: "#FFD600"), Color(hex: "#0D1326")],
        isDark: true,
        badgeName: "Énergie Anime"
    )

    // MARK: - 3. Windows
    public static let windows = AppTheme(
        id: "windows",
        name: "Windows",
        subtitle: "Style moderne Fluent : bleu ciel, bleu profond et surfaces nettes",
        icon: "window.casement.closed",
        accentColor: Color(hex: "#0078D4"),
        secondaryAccentColor: Color(hex: "#005A9E"),
        highlightColor: Color(hex: "#00B7C3"),
        backgroundColor: Color(hex: "#F3F5F9"),
        cardBackground: Color(hex: "#FFFFFF"),
        secondaryCardBackground: Color(hex: "#E8EDF5"),
        inputBackground: Color(hex: "#FFFFFF"),
        primaryTextColor: Color(hex: "#182433"),
        secondaryTextColor: Color(hex: "#5C6F84"),
        borderColor: Color(hex: "#0078D4").opacity(0.22),
        borderWidth: 1.2,
        shadowColor: Color(hex: "#0078D4").opacity(0.08),
        cornerRadius: 10,
        buttonCornerRadius: 8,
        fontDesign: .default,
        previewPalette: [Color(hex: "#0078D4"), Color(hex: "#00B7C3"), Color(hex: "#005A9E"), Color(hex: "#F3F5F9")],
        isDark: false,
        badgeName: "Fluent"
    )

    // MARK: - 4. macOS
    public static let macOS = AppTheme(
        id: "macos",
        name: "macOS",
        subtitle: "Élégance sobre Apple : gris clair, blanc pur et douceur visuelle",
        icon: "apple.logo",
        accentColor: Color(hex: "#007AFF"),
        secondaryAccentColor: Color(hex: "#5856D6"),
        highlightColor: Color(hex: "#34C759"),
        backgroundColor: Color(hex: "#E9EBEE"),
        cardBackground: Color(hex: "#FFFFFF").opacity(0.95),
        secondaryCardBackground: Color(hex: "#F2F3F5"),
        inputBackground: Color(hex: "#FFFFFF"),
        primaryTextColor: Color(hex: "#1C1C1E"),
        secondaryTextColor: Color(hex: "#6C6C70"),
        borderColor: Color.black.opacity(0.08),
        borderWidth: 1.0,
        shadowColor: Color.black.opacity(0.07),
        cornerRadius: 18,
        buttonCornerRadius: 14,
        fontDesign: .default,
        previewPalette: [Color(hex: "#007AFF"), Color(hex: "#5856D6"), Color(hex: "#E9EBEE"), Color(hex: "#FFFFFF")],
        isDark: false,
        badgeName: "Cupertino"
    )

    // MARK: - 5. Ubuntu
    public static let ubuntu = AppTheme(
        id: "ubuntu",
        name: "Ubuntu",
        subtitle: "Ambiance Linux Ubuntu : aubergine chaleureuse, orange vif et noir",
        icon: "circle.hexagongrid.fill",
        accentColor: Color(hex: "#E95420"),
        secondaryAccentColor: Color(hex: "#77216F"),
        highlightColor: Color(hex: "#F77F00"),
        backgroundColor: Color(hex: "#2C001E"),
        cardBackground: Color(hex: "#431235"),
        secondaryCardBackground: Color(hex: "#521A42"),
        inputBackground: Color(hex: "#380D2A"),
        primaryTextColor: Color(hex: "#FFFFFF"),
        secondaryTextColor: Color(hex: "#F2D5EB"),
        borderColor: Color(hex: "#E95420").opacity(0.45),
        borderWidth: 1.5,
        shadowColor: Color.black.opacity(0.35),
        cornerRadius: 14,
        buttonCornerRadius: 10,
        fontDesign: .rounded,
        previewPalette: [Color(hex: "#E95420"), Color(hex: "#77216F"), Color(hex: "#2C001E"), Color(hex: "#FFFFFF")],
        isDark: true,
        badgeName: "Linux Canonical"
    )

    // MARK: - 6. Linux Mint
    public static let linuxMint = AppTheme(
        id: "linux_mint",
        name: "Linux Mint",
        subtitle: "Vert menthe frais, blanc épuré et gris sobre : légèreté et simplicité",
        icon: "leaf.fill",
        accentColor: Color(hex: "#70B833"),
        secondaryAccentColor: Color(hex: "#2E7D32"),
        highlightColor: Color(hex: "#87CF3E"),
        backgroundColor: Color(hex: "#F2F6F3"),
        cardBackground: Color(hex: "#FFFFFF"),
        secondaryCardBackground: Color(hex: "#E3ECE5"),
        inputBackground: Color(hex: "#FFFFFF"),
        primaryTextColor: Color(hex: "#1C3123"),
        secondaryTextColor: Color(hex: "#4E6B56"),
        borderColor: Color(hex: "#70B833").opacity(0.35),
        borderWidth: 1.2,
        shadowColor: Color(hex: "#70B833").opacity(0.08),
        cornerRadius: 14,
        buttonCornerRadius: 10,
        fontDesign: .default,
        previewPalette: [Color(hex: "#70B833"), Color(hex: "#2E7D32"), Color(hex: "#F2F6F3"), Color(hex: "#1C3123")],
        isDark: false,
        badgeName: "Minty Fresh"
    )

    // MARK: - 7. Dragon
    public static let dragon = AppTheme(
        id: "dragon",
        name: "Dragon",
        subtitle: "Fantasy & puissance : noir d'obsidienne, rouge braise, or impérial et vert écaille",
        icon: "flame.fill",
        accentColor: Color(hex: "#D32F2F"),
        secondaryAccentColor: Color(hex: "#FFB300"),
        highlightColor: Color(hex: "#1B5E20"),
        backgroundColor: Color(hex: "#121215"),
        cardBackground: Color(hex: "#1C1C22"),
        secondaryCardBackground: Color(hex: "#282830"),
        inputBackground: Color(hex: "#16161B"),
        primaryTextColor: Color(hex: "#FFF7E6"),
        secondaryTextColor: Color(hex: "#E6C687"),
        borderColor: Color(hex: "#D32F2F").opacity(0.5),
        borderWidth: 1.8,
        shadowColor: Color(hex: "#D32F2F").opacity(0.25),
        cornerRadius: 16,
        buttonCornerRadius: 12,
        fontDesign: .serif,
        previewPalette: [Color(hex: "#D32F2F"), Color(hex: "#FFB300"), Color(hex: "#1B5E20"), Color(hex: "#121215")],
        isDark: true,
        badgeName: "Magie & Feu"
    )

    // All available themes
    public static let allThemes: [AppTheme] = [
        .classic,
        .dragonBall,
        .windows,
        .macOS,
        .ubuntu,
        .linuxMint,
        .dragon
    ]

    public static func theme(for id: String) -> AppTheme {
        allThemes.first(where: { $0.id == id }) ?? .classic
    }
}

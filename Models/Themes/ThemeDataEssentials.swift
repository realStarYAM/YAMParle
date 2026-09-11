//
//  ThemeDataEssentials.swift
//  YAMParle
//
//  Les trois thèmes d'origine de YAMParle, conservés à l'identique.
//  Un thème par ligne : le catalogue reste lisible comme une table de données.
//

import SwiftUI

extension ThemeCatalog {
    static let essentials: [ThemeDefinition] = [
        ThemeDefinition("classic", "Classique", "Lumière douce, encre et iris.", "bubble.left.and.bubble.right.fill", .essentials, .p("#5551C9", "#B7B4FF"), .p("#7074A5", "#B7B4FF"), .p("#F4F5FA", "#141722"), .p("#FFFFFF", "#202431"), textPrimary: .p("#202735", "#F4F5F8"), textSecondary: .p("#586174", "#B6BDCD"), surfaceSecondary: .p("#ECECF7", "#2C3042"), onAccent: .p("#FFFFFF", "#131925"), cornerRadius: 18, buttonCornerRadius: 13, ornament: .glow, badgeName: "Iris"),
        ThemeDefinition("dragon_ball", "Dragon Ball", "Orange martial, bleu nuit, énergie contenue.", "bolt.circle.fill", .essentials, .p("#AD4706", "#FFB86C"), .p("#2555A0", "#FFB86C"), .p("#FFF7ED", "#131B2D"), .p("#FFFFFF", "#202C43"), textPrimary: .p("#202735", "#F4F5F8"), textSecondary: .p("#586174", "#B6BDCD"), surfaceSecondary: .p("#FCEBD9", "#2A3850"), onAccent: .p("#FFFFFF", "#131925"), cornerRadius: 16, buttonCornerRadius: 12, fontDesign: .rounded, iconWeight: .bold, ornament: .orbit, badgeName: "Énergie"),
        ThemeDefinition("dragon", "Dragon", "Obsidienne, braise et détails cuivrés.", "flame.fill", .essentials, .p("#AC373D", "#FFADA7"), .p("#926735", "#FFADA7"), .p("#FAF4F0", "#21191B"), .p("#FFFFFF", "#342729"), textPrimary: .p("#202735", "#F4F5F8"), textSecondary: .p("#586174", "#B6BDCD"), surfaceSecondary: .p("#F1E5DE", "#493537"), onAccent: .p("#FFFFFF", "#131925"), cornerRadius: 12, buttonCornerRadius: 9, iconWeight: .semibold, ornament: .line, badgeName: "Obsidienne")
    ]
}

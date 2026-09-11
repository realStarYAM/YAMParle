//
//  ThemeManager.swift
//  YAMParle
//

import SwiftUI
import SwiftData

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let userDefaultsKey = "yamparle_active_theme_id"

    var activeThemeId: String {
        didSet {
            UserDefaults.standard.set(activeThemeId, forKey: userDefaultsKey)
        }
    }

    var currentTheme: AppTheme {
        AppTheme.theme(for: activeThemeId)
    }

    private init() {
        self.activeThemeId = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "classic"
    }

    /// Applique un thème donné. Si un UserProfile et un ModelContext sont passés, sauvegarde également dans SwiftData.
    @MainActor
    func setTheme(id: String, profile: UserProfile? = nil, in context: ModelContext? = nil) {
        let theme = AppTheme.theme(for: id)
        withAnimation(.easeInOut(duration: 0.25)) {
            self.activeThemeId = theme.id
        }

        if let profile {
            profile.themeId = theme.id
            profile.themeColorHex = theme.accentColor.toHex() ?? profile.themeColorHex
            if let context {
                try? context.save()
            }
        }
    }

    /// Synchronise le thème avec celui du profil actif
    @MainActor
    func syncTheme(from profile: UserProfile?) {
        guard let profile else { return }
        let targetThemeId = profile.themeId.isEmpty ? "classic" : profile.themeId
        if targetThemeId != activeThemeId {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.activeThemeId = targetThemeId
            }
        }
    }

    /// Réinitialise au thème Classique
    @MainActor
    func resetToClassic(profile: UserProfile? = nil, in context: ModelContext? = nil) {
        setTheme(id: "classic", profile: profile, in: context)
    }
}

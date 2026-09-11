import SwiftUI
import SwiftData

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Système"
        case .light: return "Clair"
        case .dark: return "Sombre"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let userDefaultsKey = "yamparle_active_theme_id"
    private static let favoritesKeyPrefix = "yamparle_theme_favorites_"
    private static let fallbackProfileId = "sans_profil"

    /// Favoris de la galerie de thèmes, par profil. La clé UserDefaults est
    /// propre à chaque profil utilisateur : chaque profil garde ses favoris.
    private(set) var favoritesByProfile: [String: Set<String>] = [:]

    var activeThemeId: String {
        didSet { UserDefaults.standard.set(activeThemeId, forKey: userDefaultsKey) }
    }
    var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "yamparle_appearance") }
    }
    var saveError: String?

    var currentTheme: AppTheme { AppTheme.theme(for: activeThemeId) }

    private init() {
        activeThemeId = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "classic"
        appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "yamparle_appearance") ?? "system") ?? .system
    }

    @MainActor
    func setTheme(id: String, profile: UserProfile? = nil, in context: ModelContext? = nil) {
        let theme = AppTheme.theme(for: id)
        activeThemeId = theme.id
        saveError = nil
        if let profile {
            profile.themeId = theme.id
            profile.themeColorHex = theme.accentColor.toHex()
            if let context {
                do {
                    try context.save()
                } catch {
                    saveError = "Le thème est appliqué, mais sa sauvegarde dans le profil a échoué. Réessayez."
                }
            }
        }
    }

    @MainActor
    func syncTheme(from profile: UserProfile?) {
        guard let profile else { return }
        activeThemeId = AppTheme.theme(for: profile.themeId).id
    }

    @MainActor
    func resetToClassic(profile: UserProfile? = nil, in context: ModelContext? = nil) {
        setTheme(id: "classic", profile: profile, in: context)
    }

    // MARK: - Favoris de la galerie de thèmes

    private static func favoritesKey(_ profileId: String) -> String {
        favoritesKeyPrefix + profileId
    }

    /// Favoris sauvegardés pour un profil ( UserDefaults, par identifiant
    /// de profil ). Lecture paresseuse : le dossier n'est chargé qu'au
    /// premier besoin, et la lecture est sans effet de bord.
    func favorites(for profileId: String?) -> Set<String> {
        let pid = profileId ?? Self.fallbackProfileId
        if let cached = favoritesByProfile[pid] {
            return cached
        }
        let stored = UserDefaults.standard.stringArray(forKey: Self.favoritesKey(pid)) ?? []
        return Set(stored)
    }

    func isFavorite(_ themeId: String, for profileId: String?) -> Bool {
        favorites(for: profileId).contains(themeId)
    }

    func toggleFavorite(_ themeId: String, for profileId: String?) {
        let pid = profileId ?? Self.fallbackProfileId
        var next = favorites(for: pid)
        if next.contains(themeId) {
            next.remove(themeId)
        } else {
            next.insert(themeId)
        }
        favoritesByProfile[pid] = next
        UserDefaults.standard.set(next.sorted(), forKey: Self.favoritesKey(pid))
        YAMFeedback.selection()
    }
}

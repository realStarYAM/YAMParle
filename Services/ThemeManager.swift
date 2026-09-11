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
}

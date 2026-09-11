import SwiftUI
import SwiftData

struct ThemeSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var profileManager = ProfileManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    private var theme: AppTheme { themeManager.currentTheme }
    private var activeProfile: UserProfile? {
        profiles.first { $0.id == profileManager.activeProfileId } ?? profiles.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Un espace qui vous ressemble.")
                        .font(.system(.title, design: theme.fontDesign, weight: .bold))
                        .foregroundStyle(theme.primaryTextColor)
                    Text("Les mêmes repères, une autre ambiance. Le thème est enregistré pour \(activeProfile?.name ?? "votre profil").")
                        .font(.body)
                        .foregroundStyle(theme.secondaryTextColor)
                    Picker("Apparence", selection: $themeManager.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: 56)
                    Text("Clair, sombre ou automatique : ce choix s’applique à tous les profils sur cet appareil.")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(24)
                .yamSurface(theme)

                if let error = themeManager.saveError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.body)
                        .foregroundStyle(theme.primaryTextColor)
                        .padding(16)
                        .yamSurface(theme)
                }

                LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 290), spacing: 20)], spacing: 20) {
                    ForEach(AppTheme.allThemes) { candidate in
                        themeCard(candidate)
                    }
                }
            }
            .padding(24)
        }
        .background { YAMAmbientBackground(theme: theme) }
        .navigationTitle("Thèmes et apparence")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.appearance.colorScheme)
    }

    private func themeCard(_ candidate: AppTheme) -> some View {
        let selected = candidate.id == themeManager.activeThemeId
        return Button {
            YAMFeedback.selection()
            themeManager.setTheme(id: candidate.id, profile: activeProfile, in: modelContext)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                ThemeMiniature(theme: candidate)
                    .accessibilityHidden(true)
                HStack(spacing: 12) {
                    Image(systemName: candidate.icon)
                        .font(.title2.weight(candidate.iconWeight))
                        .foregroundStyle(candidate.accentColor)
                    Text(candidate.name)
                        .font(.system(.title3, design: candidate.fontDesign, weight: .semibold))
                    Spacer(minLength: 0)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(candidate.accentColor)
                }
                Text(candidate.subtitle)
                    .font(.body)
                    .foregroundStyle(candidate.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                Text(selected ? "Thème actif" : "Choisir ce thème")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(candidate.accentColor)
            }
            .foregroundStyle(candidate.primaryTextColor)
            .padding(20)
            .yamSurface(candidate, selected: selected)
        }
        .buttonStyle(.yamPress)
        .accessibilityLabel("\(candidate.name). \(candidate.subtitle)")
        .accessibilityValue(selected ? "Thème actif" : "Non sélectionné")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityHint("Applique ce thème à votre profil sans changer la disposition.")
    }
}

struct ThemeMiniature: View {
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.secondaryTextColor.opacity(0.35))
                    .frame(height: 8)
                Text("Parler")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .foregroundStyle(theme.onAccentColor)
                    .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
            }
            .padding(12)
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius / 2))
            HStack(spacing: 10) {
                VStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == 0 ? theme.accentColor.opacity(0.3) : theme.secondaryTextColor.opacity(0.15))
                            .frame(height: 8)
                    }
                }
                .frame(width: 40)
                miniaturePhrase("Bonjour", symbol: "hand.wave")
                miniaturePhrase("Merci", symbol: "heart")
            }
        }
        .padding(16)
        .background { YAMAmbientBackground(theme: theme) }
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius * 0.7))
    }

    private func miniaturePhrase(_ title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.body.weight(theme.iconWeight))
                .foregroundStyle(theme.accentColor)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius / 2))
    }
}

#Preview {
    NavigationStack { ThemeSelectionView() }
        .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

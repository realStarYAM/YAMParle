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
            VStack(alignment: .leading, spacing: YAMSpacing.large) {
                VStack(alignment: .leading, spacing: YAMSpacing.small) {
                    Text("Un espace qui vous ressemble.")
                        .font(.system(.title3, design: theme.fontDesign, weight: .bold))
                        .foregroundStyle(theme.primaryTextColor)
                    Text("Les mêmes repères, une autre ambiance. Le thème est enregistré pour \(activeProfile?.name ?? "votre profil").")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                    Picker("Apparence", selection: $themeManager.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: YAMSpacing.minimumTarget)
                    Text("Clair, sombre ou automatique : ce choix s’applique à tous les profils sur cet appareil.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(YAMSpacing.large)
                .frame(maxWidth: YAMLayout.windowContentWidth, alignment: .leading)
                .yamSurface(theme)

                if let error = themeManager.saveError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(theme.primaryTextColor)
                        .padding(YAMSpacing.medium)
                        .yamSurface(theme)
                }

                LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 212), spacing: YAMSpacing.medium)], spacing: YAMSpacing.medium) {
                    ForEach(AppTheme.allThemes) { candidate in
                        themeCard(candidate)
                    }
                }
            }
            .padding(YAMSpacing.large)
            .frame(maxWidth: YAMLayout.windowContentWidth)
            .frame(maxWidth: .infinity)
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
            VStack(alignment: .leading, spacing: YAMSpacing.medium) {
                ThemeMiniature(theme: candidate)
                    .accessibilityHidden(true)
                HStack(spacing: YAMSpacing.small) {
                    Image(systemName: candidate.icon)
                        .font(.body.weight(candidate.iconWeight))
                        .foregroundStyle(candidate.accentColor)
                    Text(candidate.name)
                        .font(.system(.body, design: candidate.fontDesign, weight: .semibold))
                    Spacer(minLength: 0)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.callout)
                        .foregroundStyle(candidate.accentColor)
                }
                Text(candidate.subtitle)
                    .font(.footnote)
                    .foregroundStyle(candidate.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                Text(selected ? "Thème actif" : "Choisir ce thème")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(candidate.accentColor)
            }
            .foregroundStyle(candidate.primaryTextColor)
            .padding(YAMSpacing.large)
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
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.secondaryTextColor.opacity(0.35))
                    .frame(height: 6)
                Text("Parler")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .foregroundStyle(theme.onAccentColor)
                    .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
            }
            .padding(8)
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius / 2))
            HStack(spacing: 7) {
                VStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == 0 ? theme.accentColor.opacity(0.3) : theme.secondaryTextColor.opacity(0.15))
                            .frame(height: 6)
                    }
                }
                .frame(width: 30)
                miniaturePhrase("Bonjour", symbol: "hand.wave")
                miniaturePhrase("Merci", symbol: "heart")
            }
        }
        .padding(YAMSpacing.medium)
        .background { YAMAmbientBackground(theme: theme) }
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius * 0.7))
    }

    private func miniaturePhrase(_ title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(theme.iconWeight))
                .foregroundStyle(theme.accentColor)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(theme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.cornerRadius / 2))
    }
}

#Preview {
    NavigationStack { ThemeSelectionView() }
        .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

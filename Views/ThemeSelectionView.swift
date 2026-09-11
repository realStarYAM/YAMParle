//
//  ThemeSelectionView.swift
//  YAMParle
//

import SwiftUI
import SwiftData

struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var themeManager = ThemeManager.shared
    @Bindable var profileManager = ProfileManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showResetAlert: Bool = false

    private var activeProfile: UserProfile? {
        profiles.first(where: { $0.id == profileManager.activeProfileId }) ?? profiles.first
    }

    var body: some View {
        List {
            // Profile context header
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.accentColor.opacity(0.18))
                            .frame(width: 44, height: 44)

                        Image(systemName: "paintpalette.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thème pour : \(activeProfile?.name ?? "Utilisateur")")
                            .font(.headline)
                        Text("Thème actif : \(themeManager.currentTheme.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Quick reset button
                    Button {
                        showResetAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Classique")
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            } footer: {
                Text("Chaque profil utilisateur conserve son propre thème visuel. Vos préférences sont sauvegardées automatiquement sur cet appareil.")
            }

            // List of all 7 themes
            Section("Thèmes disponibles") {
                ForEach(AppTheme.allThemes) { theme in
                    themeCard(for: theme)
                }
            }

            // Bouton réinitialiser au thème classique
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Réinitialiser au thème Classique")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Thèmes")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Réinitialiser le thème ?",
            isPresented: $showResetAlert
        ) {
            Button("Réinitialiser au thème Classique", role: .destructive) {
                themeManager.resetToClassic(profile: activeProfile, in: modelContext)
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Voulez-vous rétablir le thème Classique par défaut pour ce profil ?")
        }
    }

    // MARK: - Theme Card Preview
    @ViewBuilder
    private func themeCard(for theme: AppTheme) -> some View {
        let isSelected = theme.id == themeManager.activeThemeId

        VStack(alignment: .leading, spacing: 12) {
            // Header: Icon + Name + Badge + Selection Checkmark
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.accentColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: theme.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(theme.name)
                            .font(.system(.headline, design: theme.fontDesign, weight: .bold))
                            .foregroundColor(.primary)

                        Text(theme.badgeName)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.accentColor.opacity(0.15))
                            .foregroundColor(theme.accentColor)
                            .clipShape(Capsule())
                    }

                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.accentColor)
                }
            }

            // Visual Preview Canvas
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(theme.borderColor, lineWidth: theme.borderWidth)
                    )

                HStack(spacing: 12) {
                    // Mini Mock AAC Button
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.2))
                                .frame(width: 32, height: 32)

                            Image(systemName: "bubble.left.fill")
                                .font(.caption.weight(.bold))
                                .foregroundColor(theme.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bonjour")
                                .font(.system(.subheadline, design: theme.fontDesign, weight: .bold))
                                .foregroundColor(theme.primaryTextColor)
                            Text("AAC")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius / 1.5, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius / 1.5, style: .continuous)
                            .strokeBorder(theme.borderColor, lineWidth: 1)
                    )
                    .shadow(color: theme.shadowColor, radius: 4, y: 2)

                    Spacer()

                    // Palette circles
                    HStack(spacing: 6) {
                        ForEach(0..<theme.previewPalette.count, id: \.self) { i in
                            Circle()
                                .fill(theme.previewPalette[i])
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(10)
            }
            .frame(height: 64)

            // Bouton Appliquer
            Button {
                themeManager.setTheme(id: theme.id, profile: activeProfile, in: modelContext)
            } label: {
                HStack {
                    Spacer()
                    if isSelected {
                        Label("Thème actif", systemImage: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(theme.accentColor)
                    } else {
                        Text("Appliquer le thème \(theme.name)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? theme.accentColor.opacity(0.12) : theme.accentColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? theme.accentColor : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        ThemeSelectionView()
    }
    .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

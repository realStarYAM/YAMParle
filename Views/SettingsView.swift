//
//  SettingsView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var speechService = SpeechService.shared
    @Bindable var profileManager = ProfileManager.shared
    @Bindable var themeManager = ThemeManager.shared

    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @AppStorage("yamparle_high_contrast") private var highContrast: Bool = false
    @AppStorage("yamparle_haptic_feedback") private var hapticFeedback: Bool = true
    @AppStorage("yamparle_grid_card_size") private var gridCardSize: Double = 1.0

    @State private var showResetConfirmation: Bool = false
    @State private var showExportSuccess: Bool = false

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var activeProfile: UserProfile? {
        profiles.first(where: { $0.id == profileManager.activeProfileId }) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            List {
                // 1. Profil Utilisateur Actif
                Section {
                    NavigationLink {
                        UserProfilesView()
                    } label: {
                        HStack(spacing: 14) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(theme.accentColor.opacity(0.18))
                                    .frame(width: 50, height: 50)

                                if let data = activeProfile?.avatarImageData, let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 46, height: 46)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: activeProfile?.avatarSymbol ?? "person.crop.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(theme.accentColor)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(activeProfile?.name ?? "Utilisateur")
                                        .font(.headline.weight(.bold))
                                    if activeProfile?.isDefault == true {
                                        Text("Défaut")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("Changer, créer ou dupliquer un profil")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("PROFIL ACTIF")
                        .font(.caption.weight(.bold))
                }

                // 2. Personnalisation & Thèmes
                Section {
                    NavigationLink {
                        ThemeSelectionView()
                    } label: {
                        settingsRow(
                            icon: theme.icon,
                            iconColor: theme.accentColor,
                            title: "Thèmes Visuels",
                            subtitle: "Classique, Dragon Ball, Windows, macOS, Ubuntu...",
                            badge: theme.name
                        )
                    }
                } header: {
                    Text("APPARENCE")
                        .font(.caption.weight(.bold))
                }

                // 3. Parole et Son
                Section {
                    NavigationLink {
                        SpeechAndSoundSettingsView()
                    } label: {
                        settingsRow(
                            icon: "waveform.circle.fill",
                            iconColor: Color(hex: "#AF52DE"),
                            title: "Parole et Son",
                            subtitle: "Voix Apple, ElevenLabs IA, enregistrements personnels",
                            badge: activeProfile?.preferredVoiceEngine == "elevenlabs" ? "ElevenLabs" : "Voix Apple"
                        )
                    }
                } header: {
                    Text("VOIX & AUDIO")
                        .font(.caption.weight(.bold))
                }

                // 4. Accessibilité & Ergonomie
                Section {
                    Toggle(isOn: $hapticFeedback) {
                        HStack(spacing: 12) {
                            settingsIcon(name: "hand.tap.fill", color: Color(hex: "#FF9500"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Retour haptique au toucher")
                                    .font(.subheadline.weight(.semibold))
                                Text("Vibration légère lors de la sélection des phrases")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Toggle(isOn: $highContrast) {
                        HStack(spacing: 12) {
                            settingsIcon(name: "circle.lefthalf.filled", color: Color(hex: "#007AFF"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contraste renforcé")
                                    .font(.subheadline.weight(.semibold))
                                Text("Accentue les bordures des cartes et des boutons")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            settingsIcon(name: "square.grid.2x2.fill", color: Color(hex: "#34C759"))
                            Text("Taille des boutons de la grille")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(gridCardSize == 1.0 ? "Standard" : (gridCardSize > 1.0 ? "Grande" : "Compacte"))
                                .font(.caption.weight(.bold))
                                .foregroundColor(theme.accentColor)
                        }
                        Slider(value: $gridCardSize, in: 0.8...1.3, step: 0.1)
                            .tint(theme.accentColor)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("ACCESSIBILITÉ ET DISPOSITION")
                        .font(.caption.weight(.bold))
                }

                // 5. Données et Réinitialisation
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            settingsIcon(name: "arrow.triangle.2.circlepath", color: Color(hex: "#FF3B30"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restaurer les phrases par défaut")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(hex: "#FF3B30"))
                                Text("Réinitialise les catégories et phrases initiales")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button {
                        showExportSuccess = true
                    } label: {
                        HStack(spacing: 12) {
                            settingsIcon(name: "square.and.arrow.up.fill", color: Color(hex: "#5856D6"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sauvegarder ce profil AAC")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.primaryTextColor)
                                Text("Enregistre vos phrases favorites en sécurité")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("GESTION DU CONTENU")
                        .font(.caption.weight(.bold))
                }

                // 6. À propos
                Section {
                    HStack {
                        Text("Application")
                        Spacer()
                        Text("YAMParle CAA / AAC")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.7.0 Premium")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Thème actuel")
                        Spacer()
                        Text(theme.name)
                            .foregroundColor(theme.accentColor)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("À PROPOS")
                        .font(.caption.weight(.bold))
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                }
            }
            .confirmationDialog(
                "Restaurer les phrases d'origine ?",
                isPresented: $showResetConfirmation
            ) {
                Button("Restaurer tout le catalogue", role: .destructive) {
                    DataSeedService.seedInitialDataIfNeeded(in: modelContext)
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Cette action restaurera les 10 catégories initiales et leurs phrases d'origine.")
            }
            .alert("Profil sauvegardé", isPresented: $showExportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vos catégories et phrases sont sauvegardées sur cet appareil.")
            }
        }
        .tint(theme.accentColor)
    }

    // MARK: - Row Helpers
    @ViewBuilder
    private func settingsIcon(name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 32, height: 32)

            Image(systemName: name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        badge: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(name: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(theme.primaryTextColor)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(iconColor.opacity(0.15))
                            .foregroundColor(iconColor)
                            .clipShape(Capsule())
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, AACCategory.self, AACItem.self], inMemory: true)
}

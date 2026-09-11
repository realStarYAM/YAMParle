//
//  UserProfilesView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import PhotosUI

/// Gestion des profils : une liste lisible, un seul badge, et des actions de gestion
/// séparées du geste courant « utiliser ce profil ».
///
/// Le changement de profil efface la phrase en cours de composition : quand un brouillon
/// existe, la demande est confirmée avant de basculer.
struct UserProfilesView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var profileManager = ProfileManager.shared
    @Bindable var themeManager = ThemeManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    /// La phrase en cours sur l’écran principal, transmise par l’appelant.
    var hasUnsavedDraft = false
    /// Fourni quand l’écran est présenté en feuille : « Fermer » remonte à l’accueil.
    var onClose: (() -> Void)? = nil

    @State private var showingCreateSheet = false
    @State private var profileToRename: UserProfile?
    @State private var newProfileName = ""
    @State private var profileToDelete: UserProfile?
    @State private var profileToActivate: UserProfile?

    private var theme: AppTheme { themeManager.currentTheme }
    private var canDeleteProfiles: Bool { profiles.count > 1 }

    var body: some View {
        List {
            Section {
                ForEach(profiles) { profile in
                    profileRow(profile)
                }
            } header: {
                Text("Profils")
            } footer: {
                Text("Chaque profil garde ses catégories, ses phrases, son thème et ses réglages de voix. Ils ne se mélangent jamais, même sur le même iPad.")
            }

            Section {
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("Créer un profil", systemImage: "person.badge.plus")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity, minHeight: YAMSpacing.minimumTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } footer: {
                Text("Un nouveau profil reçoit quatre catégories de départ, vides de tout contenu personnel. Rien n’est copié depuis un autre utilisateur sans que vous le demandiez.")
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("Profils")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer", action: onClose) }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateUserProfileSheet()
        }
        .alert("Renommer le profil", isPresented: renameBinding) {
            TextField("Nom du profil", text: $newProfileName)
            Button("Enregistrer", action: commitRename)
            Button("Annuler", role: .cancel) { profileToRename = nil }
        } message: {
            Text("Le nom apparaît dans l’en-tête de l’écran principal. Les phrases et catégories suivent le profil, elles ne sont pas renommées.")
        }
        .confirmationDialog(
            "Supprimer ce profil ?",
            isPresented: deleteBinding,
            titleVisibility: .visible
        ) {
            Button("Supprimer définitivement", role: .destructive, action: commitDelete)
            Button("Annuler", role: .cancel) { profileToDelete = nil }
        } message: {
            Text("Les phrases, catégories et réglages de « \(profileToDelete?.name ?? "") » seront supprimés de cet iPad. Cette action est irréversible.")
        }
        .yamProfileSwitchConfirmation(isPresented: activateBinding, onConfirm: confirmActivate)
    }

    // MARK: - Ligne de profil

    private func profileRow(_ profile: UserProfile) -> some View {
        let isActive = profile.id == profileManager.activeProfileId

        return HStack(alignment: .center, spacing: YAMSpacing.large) {
            avatar(for: profile)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: YAMSpacing.small) {
                    Text(profile.name)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    // Un seul badge dans la liste : « Par défaut ». Le profil actif se lit
                    // par la coche, pas par une étiquette de plus.
                    if profile.isDefault {
                        Text("Par défaut")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.secondaryTextColor)
                            .padding(.horizontal, YAMSpacing.small)
                            .padding(.vertical, 2)
                            .background(theme.secondaryCardBackground, in: Capsule())
                    }
                }

                Text(summary(for: profile))
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: YAMSpacing.medium)

            if isActive {
                Label("Profil actif", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(theme.accentColor)
                    .accessibilityLabel("Profil actif")
            } else {
                Button {
                    requestActivation(of: profile)
                } label: {
                    Text("Utiliser")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(minHeight: YAMSpacing.minimumTarget)
                        .background(theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.yamPress)
                .accessibilityLabel("Utiliser le profil \(profile.name)")
            }

            rowMenu(for: profile, isActive: isActive)
        }
        .padding(.vertical, YAMSpacing.tiny)
        .contentShape(Rectangle())
    }

    private func avatar(for profile: UserProfile) -> some View {
        ZStack {
            Circle()
                .fill(profile.themeColor.opacity(0.18))
                .frame(width: YAMLayout.avatarSize, height: YAMLayout.avatarSize)

            if let data = profile.avatarImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: YAMLayout.avatarGlyphSize, height: YAMLayout.avatarGlyphSize)
                    .clipShape(Circle())
            } else {
                Image(systemName: profile.avatarSymbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(profile.themeColor)
            }
        }
        .accessibilityHidden(true)
    }

    private func rowMenu(for profile: UserProfile, isActive: Bool) -> some View {
        Menu {
            Button {
                profileToRename = profile
                newProfileName = profile.name
            } label: { Label("Renommer", systemImage: "pencil") }

            Button {
                requestActivation(of: profile)
            } label: { Label("Utiliser ce profil", systemImage: "person.crop.circle") }
                .disabled(isActive)

            Button {
                duplicate(profile)
            } label: { Label("Dupliquer", systemImage: "doc.on.doc") }

            Button {
                profileManager.setDefaultProfile(profile, in: modelContext, allProfiles: profiles)
            } label: {
                Label("Définir comme profil par défaut", systemImage: "star")
            }
            .disabled(profile.isDefault)

            Divider()

            Button(role: .destructive) {
                profileToDelete = profile
            } label: { Label("Supprimer le profil", systemImage: "trash") }
                .disabled(!canDeleteProfiles)
        } label: {
            Image(systemName: "ellipsis")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.secondaryTextColor)
                .frame(width: YAMLayout.cardOptionsWidth, height: YAMSpacing.minimumTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Options pour : \(profile.name)")
        .accessibilityHint("Renommer, dupliquer, définir par défaut ou supprimer.")
    }

    private func summary(for profile: UserProfile) -> String {
        let engine = profile.preferredVoiceEngine == "elevenlabs" ? "voix IA" : "voix Apple"
        return "\(profile.activeTheme.name) · \(engine)"
    }

    // MARK: - Actions

    private var activateBinding: Binding<Bool> {
        Binding(get: { profileToActivate != nil }, set: { if !$0 { profileToActivate = nil } })
    }

    private var renameBinding: Binding<Bool> {
        Binding(get: { profileToRename != nil }, set: { if !$0 { profileToRename = nil } })
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { profileToDelete != nil }, set: { if !$0 { profileToDelete = nil } })
    }

    /// Un profil actif ne se change pas en silence quand une phrase est en cours.
    private func requestActivation(of profile: UserProfile) {
        guard profile.id != profileManager.activeProfileId else { return }
        if hasUnsavedDraft {
            profileToActivate = profile
        } else {
            activate(profile)
        }
    }

    private func confirmActivate() {
        guard let profile = profileToActivate else { return }
        profileToActivate = nil
        activate(profile)
    }

    private func activate(_ profile: UserProfile) {
        profileManager.activeProfileId = profile.id
        profileManager.applyProfileSettings(profile)
    }

    private func duplicate(_ profile: UserProfile) {
        let copy = profileManager.duplicateProfile(profile, newName: "\(profile.name) (Copie)", in: modelContext)
        requestActivation(of: copy)
    }

    private func commitRename() {
        defer { profileToRename = nil }
        let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let profile = profileToRename, !trimmed.isEmpty else { return }
        let previous = profile.name
        profile.name = trimmed
        do {
            try modelContext.save()
        } catch {
            profile.name = previous
        }
    }

    private func commitDelete() {
        defer { profileToDelete = nil }
        guard let target = profileToDelete else { return }
        profileManager.deleteProfile(target, in: modelContext, remainingProfiles: profiles)
    }
}

// MARK: - Création

struct CreateUserProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var profileManager = ProfileManager.shared
    @Bindable var themeManager = ThemeManager.shared

    @State private var name = ""
    @State private var selectedSymbol = "person.crop.circle.fill"
    @State private var selectedColorHex = "#1E73F2"
    @State private var selectedThemeId: String = ThemeManager.shared.activeThemeId
    @State private var setAsDefault = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var customImageData: Data?
    @State private var saveError: String?

    private let avatarChoices: [YAMIconChoice] = [
        YAMIconChoice(symbol: "person.crop.circle.fill", title: "Silhouette"),
        YAMIconChoice(symbol: "person.fill", title: "Personne"),
        YAMIconChoice(symbol: "figure.stand", title: "Debout"),
        YAMIconChoice(symbol: "figure.stand.dress", title: "Robe"),
        YAMIconChoice(symbol: "face.smiling.fill", title: "Sourire"),
        YAMIconChoice(symbol: "heart.circle.fill", title: "Cœur"),
        YAMIconChoice(symbol: "star.circle.fill", title: "Étoile"),
        YAMIconChoice(symbol: "sparkles", title: "Étincelles"),
    ]

    private var theme: AppTheme { themeManager.currentTheme }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exemple : Marie, Lucas…", text: $name)
                        .font(.body)
                        .accessibilityLabel("Nom du profil")
                } header: {
                    Text("Nom")
                }

                Section {
                    photoRow
                    if customImageData == nil {
                        YAMIconChoiceGrid(selection: $selectedSymbol, choices: avatarChoices)
                    }
                } header: {
                    Text("Avatar")
                }

                Section {
                    YAMSwatchGrid(selection: $selectedColorHex, swatches: YAMSwatch.profilePalette)
                } header: {
                    Text("Couleur du profil")
                }

                Section {
                    Picker("Thème visuel", selection: $selectedThemeId) {
                        ForEach(AppTheme.allThemes) { candidate in
                            Label(candidate.name, systemImage: candidate.icon).tag(candidate.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Définir comme profil par défaut", isOn: $setAsDefault)
                        .font(.callout)
                } header: {
                    Text("Ambiance")
                } footer: {
                    Text("Le thème appartient au profil, l’apparence claire ou sombre à l’appareil. Vous pourrez les modifier plus tard dans Réglages.")
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(theme.primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle("Nouveau profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer", action: createUser)
                        .disabled(trimmedName.isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
        .tint(theme.accentColor)
        .preferredColorScheme(themeManager.appearance.colorScheme)
    }

    private var photoRow: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: YAMSpacing.medium) {
                    Label("Photo de l’appareil", systemImage: "photo.on.rectangle")
                        .font(.callout)
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer(minLength: 0)
                    Text(customImageData == nil ? "Aucune photo" : "Photo choisie")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .frame(minHeight: YAMSpacing.minimumTarget)
                .contentShape(Rectangle())
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    // Même écriture en deux temps que le formulaire de phrase : un
                    // transfert raté ne retire pas la photo déjà choisie.
                    let transferred = try? await newItem?.loadTransferable(type: Data.self)
                    if let data = transferred {
                        customImageData = data
                    }
                }
            }

            if customImageData != nil {
                Button(role: .destructive) {
                    customImageData = nil
                    selectedPhotoItem = nil
                } label: {
                    Label("Retirer la photo", systemImage: "trash")
                        .font(.footnote.weight(.medium))
                        .frame(minHeight: YAMLayout.rowHeight)
                }
            }
        }
    }

    private func createUser() {
        guard !trimmedName.isEmpty else { return }
        let newId = "user_\(UUID().uuidString.prefix(8))"
        let newProfile = UserProfile(
            id: newId,
            name: trimmedName,
            avatarSymbol: selectedSymbol,
            avatarImageData: customImageData,
            isDefault: setAsDefault,
            themeColorHex: selectedColorHex,
            themeId: selectedThemeId,
            selectedVoiceIdentifier: SpeechService.shared.selectedVoiceIdentifier,
            speechRate: SpeechService.shared.rate,
            speechPitch: SpeechService.shared.pitch,
            speechVolume: SpeechService.shared.volume,
            speakOnTap: SpeechService.shared.speakOnTap,
            clearAfterSpeaking: SpeechService.shared.clearAfterSpeaking
        )
        modelContext.insert(newProfile)
        DataSeedService.seedStarterCategories(for: newId, in: modelContext)
        if setAsDefault {
            profileManager.setDefaultProfile(newProfile, in: modelContext, allProfiles: profiles)
        }

        do {
            try modelContext.save()
            profileManager.activeProfileId = newId
            profileManager.applyProfileSettings(newProfile)
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = "Le profil n’a pas pu être créé. Vérifiez l’espace disponible et réessayez."
        }
    }

    private var profiles: [UserProfile] {
        (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
    }
}

#Preview {
    NavigationStack {
        UserProfilesView()
    }
    .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
}

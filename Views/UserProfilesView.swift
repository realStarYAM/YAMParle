//
//  UserProfilesView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import PhotosUI

struct UserProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var profileManager = ProfileManager.shared
    @Bindable var themeManager = ThemeManager.shared
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showingCreateSheet: Bool = false
    @State private var profileToRename: UserProfile? = nil
    @State private var newProfileName: String = ""
    @State private var profileToDelete: UserProfile? = nil
    @State private var showDeleteConfirmation: Bool = false

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        List {
            Section {
                ForEach(profiles) { profile in
                    let isActive = profile.id == profileManager.activeProfileId

                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            // Large Avatar
                            ZStack {
                                Circle()
                                    .fill(profile.themeColor.opacity(0.18))
                                    .frame(width: 52, height: 52)

                                if let data = profile.avatarImageData, let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: profile.avatarSymbol)
                                        .font(.title2.weight(.bold))
                                        .foregroundColor(profile.themeColor)
                                }
                            }

                            // Info
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(profile.name)
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(theme.primaryTextColor)

                                    if profile.isDefault {
                                        Text("DÉFAUT")
                                            .font(.system(size: 9, weight: .black, design: .rounded))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15))
                                            .foregroundColor(.secondary)
                                            .clipShape(Capsule())
                                    }

                                    if isActive {
                                        Text("ACTIF")
                                            .font(.system(size: 9, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(theme.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }

                                HStack(spacing: 6) {
                                    Text("Thème : \(profile.activeTheme.name)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(profile.activeTheme.accentColor)

                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(profile.preferredVoiceEngine == "elevenlabs" ? "ElevenLabs" : "Voix Apple")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Select button if not active
                            if !isActive {
                                Button {
                                    profileManager.activeProfileId = profile.id
                                    profileManager.applyProfileSettings(profile)
                                } label: {
                                    Text("Activer")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(theme.accentColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(theme.accentColor.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Bottom Actions Row
                        HStack(spacing: 8) {
                            if !profile.isDefault {
                                Button {
                                    profileManager.setDefaultProfile(profile, in: modelContext, allProfiles: profiles)
                                } label: {
                                    Label("Défaut", systemImage: "star")
                                        .font(.caption.weight(.bold))
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }

                            Button {
                                profileToRename = profile
                                newProfileName = profile.name
                            } label: {
                                Label("Renommer", systemImage: "pencil")
                                    .font(.caption.weight(.bold))
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)

                            Button {
                                let copy = profileManager.duplicateProfile(profile, newName: "\(profile.name) (Copie)", in: modelContext)
                                profileManager.activeProfileId = copy.id
                                profileManager.applyProfileSettings(copy)
                            } label: {
                                Label("Dupliquer", systemImage: "doc.on.doc")
                                    .font(.caption.weight(.bold))
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)

                            Spacer()

                            if profiles.count > 1 {
                                Button(role: .destructive) {
                                    profileToDelete = profile
                                    showDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Color(hex: "#FF3B30"))
                                }
                                .buttonStyle(.bordered)
                                .tint(Color(hex: "#FF3B30"))
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("PROFILS AAC ENREGISTRÉS (\(profiles.count))")
                    .font(.caption.weight(.bold))
            } footer: {
                Text("Chaque profil enregistre séparément ses catégories, phrases de communication, son thème visuel et sa configuration vocale.")
            }

            // Bouton création profil
            Section {
                Button {
                    showingCreateSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.headline)
                        Text("Créer un nouveau profil utilisateur")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundColor(theme.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Profils AAC")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateUserProfileSheet()
        }
        .alert("Renommer le profil", isPresented: Binding(
            get: { profileToRename != nil },
            set: { if !$0 { profileToRename = nil } }
        )) {
            TextField("Nom du profil", text: $newProfileName)
            Button("Enregistrer") {
                if let prof = profileToRename, !newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    prof.name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? modelContext.save()
                }
                profileToRename = nil
            }
            Button("Annuler", role: .cancel) {
                profileToRename = nil
            }
        }
        .confirmationDialog(
            "Supprimer ce profil ?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer définitivement", role: .destructive) {
                if let target = profileToDelete {
                    profileManager.deleteProfile(target, in: modelContext, remainingProfiles: profiles)
                }
                profileToDelete = nil
            }
            Button("Annuler", role: .cancel) {
                profileToDelete = nil
            }
        } message: {
            Text("Toutes les phrases, catégories et paramètres associés à « \(profileToDelete?.name ?? "") » seront définitivement supprimés.")
        }
    }
}

// MARK: - CreateUserProfileSheet
struct CreateUserProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var profileManager = ProfileManager.shared
    @Bindable var themeManager = ThemeManager.shared

    @State private var name: String = ""
    @State private var selectedSymbol: String = "person.crop.circle.fill"
    @State private var selectedColorHex: String = "#1E73F2"
    @State private var selectedThemeId: String = ThemeManager.shared.activeThemeId
    @State private var setAsDefault: Bool = false

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customImageData: Data? = nil

    private let symbols = [
        "person.crop.circle.fill", "person.fill", "figure.stand",
        "figure.stand.dress", "face.smiling.fill", "heart.circle.fill",
        "star.circle.fill", "sparkles"
    ]

    private let paletteColors = [
        "#1E73F2", "#30D158", "#FF9F0A", "#40CBE0",
        "#FF375F", "#BF5AF2", "#5E5CE6", "#FFD60A"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom de l'utilisateur") {
                    TextField("Ex: Marie, Lucas...", text: $name)
                        .font(.body)
                }

                Section("Avatar / Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Label("Choisir une photo", systemImage: "photo.on.rectangle")
                            Spacer()
                            if customImageData != nil {
                                Text("Photo sélectionnée")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                customImageData = data
                            }
                        }
                    }

                    if customImageData != nil {
                        Button(role: .destructive) {
                            customImageData = nil
                            selectedPhotoItem = nil
                        } label: {
                            Text("Supprimer la photo")
                        }
                    }

                    if customImageData == nil {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(symbols, id: \.self) { sym in
                                Button {
                                    selectedSymbol = sym
                                } label: {
                                    Image(systemName: sym)
                                        .font(.title2)
                                        .foregroundColor(selectedSymbol == sym ? .white : Color(hex: selectedColorHex))
                                        .frame(width: 50, height: 50)
                                        .background(selectedSymbol == sym ? Color(hex: selectedColorHex) : Color(UIColor.tertiarySystemFill))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Couleur du profil") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 10) {
                        ForEach(paletteColors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 36)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Thème visuel initial") {
                    Picker("Thème", selection: $selectedThemeId) {
                        ForEach(AppTheme.allThemes) { th in
                            HStack {
                                Image(systemName: th.icon)
                                Text(th.name)
                            }
                            .tag(th.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Toggle("Définir comme profil par défaut", isOn: $setAsDefault)
                }
            }
            .navigationTitle("Nouvel utilisateur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        createUser()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .tint(themeManager.currentTheme.accentColor)
    }

    private func createUser() {
        let newId = "user_\(UUID().uuidString.prefix(8))"
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let newProfile = UserProfile(
            id: newId,
            name: trimmed,
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

        // Seed default categories & phrases for this user
        let seedCategories: [(id: String, name: String, icon: String, color: String, phrases: [String])] = [
            ("cat_conversation", "Conversation", "bubble.left.and.bubble.right.fill", "#1E73F2", [
                "Bonjour", "Bonsoir", "Bonne journée", "Bonne nuit", "Comment ça va ?", "Ça va bien", "Ça ne va pas bien",
                "Comment tu t’appelles ?", "Ravi de vous voir", "Excusez-moi", "Attendez un instant", "Quoi de neuf ?",
                "Je n’ai pas compris, pouvez-vous répéter ?", "Pourriez-vous m’aider ?", "Je l’aime", "Je n’aime pas ça",
                "À plus tard", "Au revoir", "Oui", "Non", "Peut-être"
            ]),
            ("cat_besoins", "Besoins", "heart.fill", "#FF2D55", [
                "J’ai faim", "J’ai soif", "Je veux aller aux toilettes", "J’ai froid", "J’ai chaud", "Je suis fatigué",
                "J’ai mal", "Où ai-je mal ?", "J’ai besoin de repos", "J’ai besoin de mes médicaments", "Aidez-moi s’il vous plaît",
                "Je veux m’asseoir", "Je veux me lever", "Je veux marcher"
            ]),
            ("cat_emotions", "Émotions", "face.smiling.fill", "#FF9500", [
                "Je suis content", "Je suis triste", "Je suis en colère", "J’ai peur", "Je suis inquiet", "Je suis surpris",
                "Je me sens calme", "Je me sens seul", "Je suis fier", "Je suis déçu", "Je me sens dépassé",
                "J’ai besoin d’un câlin", "Merci beaucoup"
            ]),
            ("cat_activites", "Activités", "figure.walk", "#34C759", [
                "Je veux écouter de la musique", "Je veux regarder la télévision", "Je veux lire un livre", "Je veux dessiner",
                "Je veux jouer", "Je veux aller dehors", "Je veux faire une promenade", "Je veux utiliser ma tablette",
                "Je veux cuisiner", "Je veux téléphoner", "Je veux me reposer", "C’est amusant"
            ])
        ]

        var sortOrder = 0
        for catData in seedCategories {
            let catId = "cat_\(UUID().uuidString.prefix(8))"
            let cat = AACCategory(
                id: catId,
                name: catData.name,
                iconName: catData.icon,
                colorHex: catData.color,
                sortOrder: sortOrder,
                isCustom: false,
                userProfileId: newId
            )
            modelContext.insert(cat)
            sortOrder += 1

            var itemOrder = 0
            for phrase in catData.phrases {
                let item = AACItem(
                    text: phrase,
                    categoryId: catId,
                    sortOrder: itemOrder,
                    userProfileId: newId
                )
                modelContext.insert(item)
                itemOrder += 1
            }
        }

        try? modelContext.save()

        // Switch to newly created profile
        profileManager.activeProfileId = newId
        profileManager.applyProfileSettings(newProfile)
    }
}

//
//  ProfileManager.swift
//  YAMParle
//

import SwiftUI
import SwiftData

@Observable
final class ProfileManager {
    static let shared = ProfileManager()

    private let userDefaultsKey = "yamparle_active_profile_id"

    var activeProfileId: String {
        didSet {
            UserDefaults.standard.set(activeProfileId, forKey: userDefaultsKey)
        }
    }

    private init() {
        self.activeProfileId = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "default_user"
    }

    @MainActor
    func ensureDefaultProfileExists(in context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? context.fetch(descriptor)) ?? []

        if let defaultProfile = existing.first(where: { $0.isDefault }) {
            if activeProfileId.isEmpty || !existing.contains(where: { $0.id == activeProfileId }) {
                activeProfileId = defaultProfile.id
            }
            if let active = existing.first(where: { $0.id == activeProfileId }) {
                applyProfileSettings(active)
            } else {
                applyProfileSettings(defaultProfile)
            }
            return defaultProfile
        }

        if let first = existing.first {
            first.isDefault = true
            try? context.save()
            activeProfileId = first.id
            applyProfileSettings(first)
            return first
        }

        // Create initial default profile
        let defaultProfile = UserProfile(
            id: "default_user",
            name: "Utilisateur par défaut",
            avatarSymbol: "person.crop.circle.fill",
            isDefault: true,
            themeColorHex: "#1E73F2",
            themeId: "classic",
            selectedVoiceIdentifier: SpeechService.shared.selectedVoiceIdentifier,
            speechRate: SpeechService.shared.rate,
            speechPitch: SpeechService.shared.pitch,
            speechVolume: SpeechService.shared.volume,
            speakOnTap: SpeechService.shared.speakOnTap,
            clearAfterSpeaking: SpeechService.shared.clearAfterSpeaking,
            preferredVoiceEngine: "apple"
        )
        context.insert(defaultProfile)
        try? context.save()
        activeProfileId = defaultProfile.id
        applyProfileSettings(defaultProfile)
        return defaultProfile
    }

    @MainActor
    func applyProfileSettings(_ profile: UserProfile) {
        let speech = SpeechService.shared
        if !profile.selectedVoiceIdentifier.isEmpty {
            speech.selectedVoiceIdentifier = profile.selectedVoiceIdentifier
        }
        speech.rate = profile.speechRate
        speech.pitch = profile.speechPitch
        speech.volume = profile.speechVolume
        speech.speakOnTap = profile.speakOnTap
        speech.clearAfterSpeaking = profile.clearAfterSpeaking
        speech.preferredEngine = profile.preferredVoiceEngine

        // Synchroniser le thème actif avec celui du profil
        ThemeManager.shared.syncTheme(from: profile)
    }

    @MainActor
    func saveCurrentSettingsToProfile(_ profile: UserProfile, in context: ModelContext) {
        let speech = SpeechService.shared
        profile.selectedVoiceIdentifier = speech.selectedVoiceIdentifier
        profile.speechRate = speech.rate
        profile.speechPitch = speech.pitch
        profile.speechVolume = speech.volume
        profile.speakOnTap = speech.speakOnTap
        profile.clearAfterSpeaking = speech.clearAfterSpeaking
        profile.preferredVoiceEngine = speech.preferredEngine
        profile.themeId = ThemeManager.shared.activeThemeId
        try? context.save()
    }

    @MainActor
    func duplicateProfile(_ source: UserProfile, newName: String, in context: ModelContext) -> UserProfile {
        let newId = "user_\(UUID().uuidString.prefix(8))"
        let duplicatedProfile = UserProfile(
            id: newId,
            name: newName,
            avatarSymbol: source.avatarSymbol,
            avatarImageData: source.avatarImageData,
            isDefault: false,
            themeColorHex: source.themeColorHex,
            themeId: source.themeId,
            selectedVoiceIdentifier: source.selectedVoiceIdentifier,
            speechRate: source.speechRate,
            speechPitch: source.speechPitch,
            speechVolume: source.speechVolume,
            speakOnTap: source.speakOnTap,
            clearAfterSpeaking: source.clearAfterSpeaking,
            preferredVoiceEngine: source.preferredVoiceEngine,
            elevenLabsVoiceId: source.elevenLabsVoiceId,
            elevenLabsModelId: source.elevenLabsModelId
        )
        context.insert(duplicatedProfile)

        // Copy all categories from source
        let catDescriptor = FetchDescriptor<AACCategory>()
        let allCategories = (try? context.fetch(catDescriptor)) ?? []
        let sourceCategories = allCategories.filter { $0.userProfileId == source.id }

        // Category ID map: old ID -> new ID
        var categoryMap: [String: String] = [:]

        for cat in sourceCategories {
            let newCatId = "cat_\(UUID().uuidString.prefix(8))"
            categoryMap[cat.id] = newCatId
            let newCat = AACCategory(
                id: newCatId,
                name: cat.name,
                iconName: cat.iconName,
                colorHex: cat.colorHex,
                sortOrder: cat.sortOrder,
                isCustom: cat.isCustom,
                userProfileId: newId
            )
            context.insert(newCat)
        }

        // Copy all items from source
        let itemDescriptor = FetchDescriptor<AACItem>()
        let allItems = (try? context.fetch(itemDescriptor)) ?? []
        let sourceItems = allItems.filter { $0.userProfileId == source.id }

        for item in sourceItems {
            let targetCatId = categoryMap[item.categoryId] ?? item.categoryId
            let newItem = AACItem(
                text: item.text,
                label: item.label,
                speechText: item.speechText,
                iconName: item.iconName,
                customImageData: item.customImageData,
                categoryId: targetCatId,
                customColorHex: item.customColorHex,
                sortOrder: item.sortOrder,
                isFavorite: item.isFavorite,
                isCustom: item.isCustom,
                userProfileId: newId,
                audioSourceType: item.audioSourceType,
                localAudioFileName: item.localAudioFileName
            )
            context.insert(newItem)
        }

        // Copy favorites from source
        let favDescriptor = FetchDescriptor<FavoritePhrase>()
        let allFavorites = (try? context.fetch(favDescriptor)) ?? []
        let sourceFavorites = allFavorites.filter { $0.userProfileId == source.id }

        for fav in sourceFavorites {
            let newFav = FavoritePhrase(
                text: fav.text,
                dateAdded: Date(),
                isPinned: fav.isPinned,
                userProfileId: newId
            )
            context.insert(newFav)
        }

        try? context.save()
        return duplicatedProfile
    }

    @MainActor
    func deleteProfile(_ profile: UserProfile, in context: ModelContext, remainingProfiles: [UserProfile]) {
        let profileId = profile.id
        context.delete(profile)

        // Delete associated categories
        let catDescriptor = FetchDescriptor<AACCategory>()
        if let allCats = try? context.fetch(catDescriptor) {
            for cat in allCats where cat.userProfileId == profileId {
                context.delete(cat)
            }
        }

        // Delete associated items
        let itemDescriptor = FetchDescriptor<AACItem>()
        if let allItems = try? context.fetch(itemDescriptor) {
            for item in allItems where item.userProfileId == profileId {
                context.delete(item)
            }
        }

        // Delete associated favorites
        let favDescriptor = FetchDescriptor<FavoritePhrase>()
        if let allFavs = try? context.fetch(favDescriptor) {
            for fav in allFavs where fav.userProfileId == profileId {
                context.delete(fav)
            }
        }

        // Fallback active profile if current was deleted
        if activeProfileId == profileId {
            let nextProfile = remainingProfiles.first(where: { $0.id != profileId })
            activeProfileId = nextProfile?.id ?? "default_user"
            if let nextProfile {
                applyProfileSettings(nextProfile)
            }
        }

        try? context.save()
    }

    @MainActor
    func setDefaultProfile(_ profile: UserProfile, in context: ModelContext, allProfiles: [UserProfile]) {
        for p in allProfiles {
            p.isDefault = (p.id == profile.id)
        }
        try? context.save()
    }
}

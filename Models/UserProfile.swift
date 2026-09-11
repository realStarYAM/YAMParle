//
//  UserProfile.swift
//  YAMParle
//

import SwiftUI
import SwiftData

@Model
final class UserProfile {
    var id: String = UUID().uuidString
    var name: String = ""
    var avatarSymbol: String = "person.crop.circle.fill"
    @Attribute(.externalStorage) var avatarImageData: Data? = nil
    var isDefault: Bool = false
    var themeColorHex: String = "#1E73F2"
    var themeId: String = "classic"
    var selectedVoiceIdentifier: String = ""
    var speechRate: Float = 0.5
    var speechPitch: Float = 1.0
    var speechVolume: Float = 1.0
    var speakOnTap: Bool = false
    var clearAfterSpeaking: Bool = false
    var preferredVoiceEngine: String = "apple"
    var elevenLabsVoiceId: String? = nil
    var elevenLabsModelId: String? = "eleven_multilingual_v2"
    var createdAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        name: String,
        avatarSymbol: String = "person.crop.circle.fill",
        avatarImageData: Data? = nil,
        isDefault: Bool = false,
        themeColorHex: String = "#1E73F2",
        themeId: String = "classic",
        selectedVoiceIdentifier: String = "",
        speechRate: Float = 0.5,
        speechPitch: Float = 1.0,
        speechVolume: Float = 1.0,
        speakOnTap: Bool = false,
        clearAfterSpeaking: Bool = false,
        preferredVoiceEngine: String = "apple",
        elevenLabsVoiceId: String? = nil,
        elevenLabsModelId: String? = "eleven_multilingual_v2",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarSymbol = avatarSymbol
        self.avatarImageData = avatarImageData
        self.isDefault = isDefault
        self.themeColorHex = themeColorHex
        self.themeId = themeId
        self.selectedVoiceIdentifier = selectedVoiceIdentifier
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.speechVolume = speechVolume
        self.speakOnTap = speakOnTap
        self.clearAfterSpeaking = clearAfterSpeaking
        self.preferredVoiceEngine = preferredVoiceEngine
        self.elevenLabsVoiceId = elevenLabsVoiceId
        self.elevenLabsModelId = elevenLabsModelId
        self.createdAt = createdAt
    }

    var themeColor: Color {
        Color(hex: themeColorHex)
    }

    var activeTheme: AppTheme {
        AppTheme.theme(for: themeId)
    }
}

//
//  AACItem.swift
//  YAMParle
//

import SwiftUI
import SwiftData

@Model
final class AACItem {
    var id: String = UUID().uuidString
    var text: String = ""
    var label: String? = nil
    var speechText: String? = nil
    var iconName: String = "bubble.left.fill"
    @Attribute(.externalStorage) var customImageData: Data? = nil
    var categoryId: String = ""
    var customColorHex: String? = nil
    var sortOrder: Int = 0
    var isFavorite: Bool = false
    var isCustom: Bool = false
    var userProfileId: String = "default_user"
    var audioSourceType: String = "apple" // "apple", "elevenlabs", "recording"
    var localAudioFileName: String? = nil

    init(
        id: String = UUID().uuidString,
        text: String,
        label: String? = nil,
        speechText: String? = nil,
        iconName: String = "bubble.left.fill",
        customImageData: Data? = nil,
        categoryId: String,
        customColorHex: String? = nil,
        sortOrder: Int = 0,
        isFavorite: Bool = false,
        isCustom: Bool = false,
        userProfileId: String = "default_user",
        audioSourceType: String = "apple",
        localAudioFileName: String? = nil
    ) {
        self.id = id
        self.text = text
        self.label = label
        self.speechText = speechText
        self.iconName = iconName
        self.customImageData = customImageData
        self.categoryId = categoryId
        self.customColorHex = customColorHex
        self.sortOrder = sortOrder
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.userProfileId = userProfileId
        self.audioSourceType = audioSourceType
        self.localAudioFileName = localAudioFileName
    }

    var hasCustomAudio: Bool {
        if audioSourceType == "recording" || audioSourceType == "elevenlabs" {
            return true
        }
        return localAudioFileName != nil && !(localAudioFileName?.isEmpty ?? true)
    }

    var displayLabel: String {
        if let customLabel = label, !customLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customLabel
        }
        return text
    }

    var spokenText: String {
        if let customSpeech = speechText, !customSpeech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customSpeech
        }
        return text
    }

    var effectiveColor: Color? {
        if let customColorHex, !customColorHex.isEmpty {
            return Color(hex: customColorHex)
        }
        return nil
    }
}

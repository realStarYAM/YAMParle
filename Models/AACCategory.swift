//
//  AACCategory.swift
//  YAMParle
//

import SwiftUI
import SwiftData

@Model
final class AACCategory {
    var id: String = UUID().uuidString
    var name: String = ""
    var iconName: String = "folder.fill"
    var colorHex: String = "#1E73F2"
    var sortOrder: Int = 0
    var isCustom: Bool = false
    var userProfileId: String = "default_user"

    init(
        id: String = UUID().uuidString,
        name: String,
        iconName: String,
        colorHex: String,
        sortOrder: Int = 0,
        isCustom: Bool = false,
        userProfileId: String = "default_user"
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isCustom = isCustom
        self.userProfileId = userProfileId
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

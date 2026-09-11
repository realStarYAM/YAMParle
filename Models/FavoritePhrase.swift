//
//  FavoritePhrase.swift
//  YAMParle
//

import Foundation
import SwiftData

@Model
final class FavoritePhrase {
    var id: String = UUID().uuidString
    var text: String = ""
    var dateAdded: Date = Date()
    var isPinned: Bool = false
    var userProfileId: String = "default_user"

    init(
        id: String = UUID().uuidString,
        text: String,
        dateAdded: Date = Date(),
        isPinned: Bool = false,
        userProfileId: String = "default_user"
    ) {
        self.id = id
        self.text = text
        self.dateAdded = dateAdded
        self.isPinned = isPinned
        self.userProfileId = userProfileId
    }
}

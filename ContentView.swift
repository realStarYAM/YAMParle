//
//  ContentView.swift
//  YAMParle
//
//  Created by adel mehenni on 10/09/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Bindable var themeManager = ThemeManager.shared

    var body: some View {
        MainAACView()
            .tint(themeManager.currentTheme.accentColor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
}

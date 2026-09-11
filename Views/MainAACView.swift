//
//  MainAACView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import AVFoundation

struct MainAACView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \AACCategory.sortOrder) private var allCategories: [AACCategory]
    @Query(sort: \AACItem.sortOrder) private var allItems: [AACItem]
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @Bindable var speechService = SpeechService.shared
    @Bindable var profileManager = ProfileManager.shared
    @Bindable var themeManager = ThemeManager.shared

    // Active state
    @State private var textInput: String = ""
    @State private var selectedCategoryId: String = "cat_conversation"
    @FocusState private var isTextEditorFocused: Bool

    // Sheets
    @State private var showingProfilesSheet: Bool = false
    @State private var showingFullScreen: Bool = false
    @State private var showingSearch: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingNewPhraseEditor: Bool = false
    @State private var showingSaveCurrentPhrase: Bool = false
    @State private var showingNewCategoryEditor: Bool = false
    @State private var itemToEdit: AACItem? = nil

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var isIPadLandscape: Bool {
        horizontalSizeClass == .regular
    }

    private var activeProfile: UserProfile? {
        profiles.first(where: { $0.id == profileManager.activeProfileId }) ?? profiles.first
    }

    private var userCategories: [AACCategory] {
        let filtered = allCategories.filter { $0.userProfileId == profileManager.activeProfileId }
        if filtered.isEmpty {
            let defaultCats = allCategories.filter { $0.userProfileId == "default_user" }
            return defaultCats.isEmpty ? allCategories : defaultCats
        }
        return filtered
    }

    private var userItems: [AACItem] {
        let profileItems = allItems.filter { $0.userProfileId == profileManager.activeProfileId }
        return profileItems.isEmpty ? allItems.filter { $0.userProfileId == "default_user" } : profileItems
    }

    private var displayedItems: [AACItem] {
        userItems.filter { $0.categoryId == selectedCategoryId }
    }

    private var activeCategory: AACCategory? {
        userCategories.first(where: { $0.id == selectedCategoryId }) ?? userCategories.first
    }

    private func countForCategory(_ catId: String) -> Int {
        userItems.filter { $0.categoryId == catId }.count
    }

    private var wordCount: Int {
        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? 0 : trimmed.split(separator: " ").count
    }

    // Grid columns for phrases
    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = isIPadLandscape ? 170 : 130
        return [GridItem(.adaptive(minimum: minWidth, maximum: 260), spacing: 14)]
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if isIPadLandscape {
                    // IPAD LANDSCAPE LAYOUT: Main area on left, sleek unified sidebar on right
                    HStack(spacing: 16) {
                        // Left/Center: Top Text Editor + Grid of phrases
                        VStack(spacing: 16) {
                            topTextEditorArea
                                .frame(height: 155)

                            phrasesGridArea
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Right: Unified Commands + Categories Sidebar
                        rightSidebarView
                            .frame(width: 210)
                    }
                    .padding(16)
                } else {
                    // IPHONE & IPAD PORTRAIT: Responsive stacked layout
                    VStack(spacing: 12) {
                        topTextEditorArea
                            .frame(height: 115)

                        // Compact commands bar
                        compactCommandsBar

                        // Categories horizontal bar
                        categoriesHorizontalBar

                        // Grid of phrases
                        phrasesGridArea
                    }
                    .padding(12)
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top Leading: Logo + Profile Switcher
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        brandingBadge
                        profileSwitcherPill
                    }
                }

                // Top Trailing: Action Icons
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.primaryTextColor)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(theme.borderColor, lineWidth: 1))
                    }
                    .accessibilityLabel("Rechercher")

                    Button {
                        isTextEditorFocused.toggle()
                    } label: {
                        Image(systemName: isTextEditorFocused ? "keyboard.chevron.compact.down.fill" : "keyboard.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isTextEditorFocused ? theme.accentColor : theme.primaryTextColor)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(isTextEditorFocused ? theme.accentColor : theme.borderColor, lineWidth: 1))
                    }
                    .accessibilityLabel("Afficher ou masquer le clavier")

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.primaryTextColor)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(theme.borderColor, lineWidth: 1))
                    }
                    .accessibilityLabel("Réglages")
                }
            }
            .toolbar {
                // Native System Keyboard accessory toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Button {
                        speakText()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Parler")
                        }
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        deleteLastWord()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "delete.backward")
                            Text("Mot")
                        }
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        clearAllText()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Effacer")
                        }
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()

                    Button("Terminé") {
                        isTextEditorFocused = false
                    }
                    .fontWeight(.bold)
                }
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                FullScreenTextView(text: textInput) {
                    speakText()
                }
            }
            .sheet(isPresented: $showingProfilesSheet) {
                NavigationStack {
                    UserProfilesView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Fermer") {
                                    showingProfilesSheet = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingSearch) {
                SearchView(
                    viewModel: AACViewModel(),
                    categories: userCategories,
                    allItems: userItems,
                    onSelectPhrase: { phrase in
                        appendPhrase(phrase)
                    },
                    onEditPhrase: { item in
                        itemToEdit = item
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNewPhraseEditor) {
                ItemEditorView(
                    existingItem: nil,
                    defaultCategoryId: selectedCategoryId,
                    initialText: nil,
                    categories: userCategories
                )
            }
            .sheet(isPresented: $showingSaveCurrentPhrase) {
                ItemEditorView(
                    existingItem: nil,
                    defaultCategoryId: selectedCategoryId,
                    initialText: textInput,
                    categories: userCategories
                )
            }
            .sheet(isPresented: $showingNewCategoryEditor) {
                CategoryEditorView()
            }
            .sheet(item: $itemToEdit) { item in
                ItemEditorView(
                    existingItem: item,
                    defaultCategoryId: item.categoryId,
                    initialText: nil,
                    categories: userCategories
                )
            }
            .onAppear {
                DataSeedService.seedInitialDataIfNeeded(in: modelContext)
                let defaultProf = profileManager.ensureDefaultProfileExists(in: modelContext)
                themeManager.syncTheme(from: activeProfile ?? defaultProf)

                if selectedCategoryId.isEmpty || !userCategories.contains(where: { $0.id == selectedCategoryId }) {
                    if let firstCat = userCategories.first(where: { $0.id.contains("conversation") }) ?? userCategories.first {
                        selectedCategoryId = firstCat.id
                    }
                }
            }
        }
        .tint(theme.accentColor)
    }

    // MARK: - Top Bar Components

    private var brandingBadge: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.accentColor, theme.secondaryAccentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: -1) {
                Text("YAMParle")
                    .font(.system(size: 16, weight: .black, design: theme.fontDesign))
                    .foregroundColor(theme.primaryTextColor)

                Text("COMMUNICATION AAC")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(theme.accentColor)
                    .tracking(0.8)
            }
        }
    }

    private var profileSwitcherPill: some View {
        Menu {
            Section("Profils AAC") {
                ForEach(profiles) { profile in
                    Button {
                        profileManager.activeProfileId = profile.id
                        profileManager.applyProfileSettings(profile)
                        if let firstCat = userCategories.first {
                            selectedCategoryId = firstCat.id
                        }
                    } label: {
                        HStack {
                            Text(profile.name)
                            if profile.id == profileManager.activeProfileId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                showingProfilesSheet = true
            } label: {
                Label("Gérer les profils...", systemImage: "person.2.circle")
            }
        } label: {
            HStack(spacing: 8) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: 28, height: 28)

                    if let data = activeProfile?.avatarImageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 26, height: 26)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: activeProfile?.avatarSymbol ?? "person.crop.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.accentColor)
                    }
                }

                Text(activeProfile?.name ?? "Profil")
                    .font(.system(size: 13, weight: .bold, design: theme.fontDesign))
                    .foregroundColor(theme.primaryTextColor)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(theme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(theme.borderColor, lineWidth: 1)
            )
            .shadow(color: theme.shadowColor, radius: 2, y: 1)
        }
        .accessibilityLabel("Profil actif : \(activeProfile?.name ?? ""). Touchez pour changer.")
    }

    // MARK: - Modern Phrase Editor Area
    private var topTextEditorArea: some View {
        ZStack(alignment: .topLeading) {
            // Elevated background card
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .strokeBorder(
                            isTextEditorFocused ? theme.accentColor : theme.borderColor,
                            lineWidth: isTextEditorFocused ? 2.5 : theme.borderWidth
                        )
                )
                .shadow(
                    color: isTextEditorFocused ? theme.accentColor.opacity(0.25) : theme.shadowColor,
                    radius: isTextEditorFocused ? 8 : 4,
                    y: isTextEditorFocused ? 3 : 2
                )

            // Elegant placeholder
            if textInput.isEmpty && !isTextEditorFocused {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(theme.accentColor.opacity(0.8))

                    Text("Touchez pour taper au clavier ou sélectionnez des phrases ci-dessous...")
                        .font(.system(size: isIPadLandscape ? 20 : 15, weight: .medium, design: theme.fontDesign))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.8))
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .allowsHitTesting(false)
            }

            // Native SwiftUI TextEditor
            TextEditor(text: $textInput)
                .font(.system(size: isIPadLandscape ? 28 : 20, weight: .bold, design: theme.fontDesign))
                .foregroundColor(theme.primaryTextColor)
                .tint(theme.accentColor)
                .focused($isTextEditorFocused)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .background(Color.clear)
                .scrollContentBackground(.hidden)

            // Bottom bar info & quick clear
            VStack {
                Spacer()
                HStack(alignment: .center, spacing: 8) {
                    if !textInput.isEmpty {
                        // Word count badge
                        Text("\(wordCount) mot\(wordCount > 1 ? "s" : "")")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(theme.secondaryTextColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(theme.cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(theme.borderColor, lineWidth: 0.8))

                        Spacer()

                        // Inline Clear Button
                        Button(action: clearAllText) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Effacer")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#FF3B30"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#FF3B30").opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.yamPress)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextEditorFocused = true
        }
        .accessibilityLabel("Zone de composition de la phrase")
    }

    // MARK: - Phrases Grid Area
    private var phrasesGridArea: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 14) {
                ForEach(displayedItems) { item in
                    ModernAACCard(
                        item: item,
                        categoryColor: activeCategory?.color ?? theme.accentColor,
                        isSelected: false,
                        onTap: {
                            handlePhraseTap(item)
                        },
                        onSpeak: {
                            speechService.speakItem(item)
                        },
                        onEdit: {
                            itemToEdit = item
                        }
                    )
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Right Sidebar on iPad Landscape
    private var rightSidebarView: some View {
        VStack(spacing: 12) {
            // Action Command Buttons
            VStack(spacing: 7) {
                // 🔊 HERO BUTTON: Parler
                YAMActionButton(
                    title: speechService.isSpeaking ? "En cours..." : "Parler",
                    icon: "speaker.wave.3.fill",
                    variant: .hero(theme.accentColor),
                    isSpeaking: speechService.isSpeaking,
                    height: 48
                ) {
                    speakText()
                }

                HStack(spacing: 7) {
                    // ⌫ Dernier mot
                    YAMActionButton(
                        title: "Mot",
                        icon: "delete.backward.fill",
                        variant: .warning,
                        height: 38
                    ) {
                        deleteLastWord()
                    }

                    // ❌ Effacer tout
                    YAMActionButton(
                        title: "Effacer",
                        icon: "trash.fill",
                        variant: .destructive,
                        height: 38
                    ) {
                        clearAllText()
                    }
                }

                HStack(spacing: 7) {
                    // ⛶ Plein écran
                    YAMActionButton(
                        title: "Plein écran",
                        icon: "arrow.up.left.and.arrow.down.right",
                        variant: .secondary,
                        height: 38
                    ) {
                        showingFullScreen = true
                    }

                    // ➕ Menu Ajouter
                    Menu {
                        Button {
                            showingNewPhraseEditor = true
                        } label: {
                            Label("Nouvelle phrase", systemImage: "plus.bubble.fill")
                        }

                        Button {
                            showingSaveCurrentPhrase = true
                        } label: {
                            Label("Enregistrer la phrase actuelle", systemImage: "square.and.arrow.down.fill")
                        }
                        .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button {
                            showingNewCategoryEditor = true
                        } label: {
                            Label("Nouvelle catégorie", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Ajouter")
                                .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color(hex: "#30D158"))
                        .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                    }
                }
            }

            Divider()
                .overlay(theme.borderColor)

            // Categories Section Title
            HStack {
                Text("CATÉGORIES")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)
                    .tracking(0.6)

                Spacer()

                Button {
                    showingNewCategoryEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.accentColor)
                }
                .accessibilityLabel("Ajouter une catégorie")
            }
            .padding(.horizontal, 4)

            // Categories Vertical Rail
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(userCategories) { cat in
                        ModernCategoryTile(
                            category: cat,
                            isSelected: cat.id == selectedCategoryId,
                            count: countForCategory(cat.id)
                        ) {
                            selectedCategoryId = cat.id
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.borderColor, lineWidth: theme.borderWidth)
        )
        .shadow(color: theme.shadowColor, radius: 5, y: 2)
    }

    // MARK: - Compact Commands Bar on iPhone
    private var compactCommandsBar: some View {
        HStack(spacing: 8) {
            // Hero Parler Button
            Button {
                speakText()
            } label: {
                HStack(spacing: 6) {
                    if speechService.isSpeaking {
                        Image(systemName: "waveform")
                            .symbolEffect(.variableColor.iterative.reversing)
                    } else {
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    Text("Parler")
                }
                .font(.system(.subheadline, design: theme.fontDesign, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(theme.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                .shadow(color: theme.accentColor.opacity(0.35), radius: 4, y: 2)
            }
            .buttonStyle(.yamPress)

            // Dernier mot
            Button {
                deleteLastWord()
            } label: {
                Image(systemName: "delete.backward.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#FF9500"))
                    .frame(width: 44, height: 46)
                    .background(Color(hex: "#FF9500").opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.yamPress)
            .accessibilityLabel("Effacer le dernier mot")

            // Effacer tout
            Button {
                clearAllText()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#FF3B30"))
                    .frame(width: 44, height: 46)
                    .background(Color(hex: "#FF3B30").opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.yamPress)
            .accessibilityLabel("Effacer tout le texte")

            // Plein écran
            Button {
                showingFullScreen = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#AF52DE"))
                    .frame(width: 44, height: 46)
                    .background(Color(hex: "#AF52DE").opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.yamPress)
            .accessibilityLabel("Mode plein écran")

            // Ajouter menu
            Menu {
                Button {
                    showingNewPhraseEditor = true
                } label: {
                    Label("Nouvelle phrase", systemImage: "plus.bubble.fill")
                }

                Button {
                    showingSaveCurrentPhrase = true
                } label: {
                    Label("Enregistrer la phrase", systemImage: "square.and.arrow.down.fill")
                }

                Button {
                    showingNewCategoryEditor = true
                } label: {
                    Label("Nouvelle catégorie", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#30D158"))
                    .frame(width: 44, height: 46)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                            .strokeBorder(theme.borderColor, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Horizontal Categories for iPhone / Portrait
    private var categoriesHorizontalBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(userCategories) { cat in
                    let isSelected = cat.id == selectedCategoryId
                    let count = countForCategory(cat.id)

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        selectedCategoryId = cat.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 13, weight: .bold))

                            Text(cat.name)
                                .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: theme.fontDesign))

                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(isSelected ? cat.color : theme.secondaryTextColor)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.white : theme.backgroundColor)
                                    )
                            }
                        }
                        .foregroundColor(isSelected ? .white : theme.primaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSelected ? cat.color : theme.cardBackground)
                        )
                        .overlay(
                            Capsule().strokeBorder(isSelected ? Color.clear : theme.borderColor, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? cat.color.opacity(0.35) : Color.clear, radius: 3, y: 1.5)
                    }
                    .buttonStyle(.yamPress(scale: 0.96))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Logic Actions
    private func handlePhraseTap(_ item: AACItem) {
        appendPhrase(item.text)
        if speechService.speakOnTap {
            speechService.speakItem(item)
        }
    }

    private func appendPhrase(_ phrase: String) {
        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            textInput = phrase
        } else {
            textInput = trimmed + " " + phrase
        }
    }

    private func speakText() {
        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        speechService.speak(text: trimmed)

        if speechService.clearAfterSpeaking {
            textInput = ""
        }
    }

    private func deleteLastWord() {
        var words = textInput.split(separator: " ").map(String.init)
        if !words.isEmpty {
            words.removeLast()
            textInput = words.joined(separator: " ")
            if !textInput.isEmpty {
                textInput += " "
            }
        } else {
            textInput = ""
        }
    }

    private func clearAllText() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
            textInput = ""
        }
    }
}

#Preview {
    MainAACView()
        .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
}

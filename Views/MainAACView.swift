import SwiftUI
import SwiftData

struct MainAACView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: \AACCategory.sortOrder) private var allCategories: [AACCategory]
    @Query(sort: \AACItem.sortOrder) private var allItems: [AACItem]
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @Bindable private var speechService = SpeechService.shared
    @Bindable private var profileManager = ProfileManager.shared
    @Bindable private var themeManager = ThemeManager.shared
    @AppStorage("yamparle_grid_card_size") private var gridCardSize = 1.0

    @State private var textInput = ""
    @State private var clearedText = ""
    @State private var selectedCategoryId = ""
    @State private var sheet: AACSheet?
    @State private var pendingEdit: AACItem?
    @State private var fullScreenText: String?
    @State private var showingFullScreen = false
    @FocusState private var isEditorFocused: Bool

    private enum AACSheet: Identifiable {
        case profiles, search, settings, newPhrase, savePhrase, newCategory
        case edit(AACItem)

        var id: String {
            switch self {
            case .profiles: return "profiles"
            case .search: return "search"
            case .settings: return "settings"
            case .newPhrase: return "newPhrase"
            case .savePhrase: return "savePhrase"
            case .newCategory: return "newCategory"
            case .edit(let item): return "edit-\(item.id)"
            }
        }
    }

    private var theme: AppTheme { themeManager.currentTheme }
    private var activeProfile: UserProfile? {
        profiles.first { $0.id == profileManager.activeProfileId } ?? profiles.first
    }
    private var effectiveProfileId: String { activeProfile?.id ?? profileManager.activeProfileId }
    private var userCategories: [AACCategory] {
        allCategories.filter { $0.userProfileId == effectiveProfileId }
    }
    private var userItems: [AACItem] {
        allItems.filter { $0.userProfileId == effectiveProfileId }
    }
    private var activeCategory: AACCategory? {
        userCategories.first { $0.id == selectedCategoryId } ?? userCategories.first
    }
    private var displayedItems: [AACItem] {
        guard let category = activeCategory else { return [] }
        return userItems.filter { $0.categoryId == category.id }
    }
    private var columns: [GridItem] {
        if typeSize.isAccessibilitySize { return [GridItem(.flexible())] }
        return [GridItem(.adaptive(minimum: 200 * min(max(gridCardSize, 0.8), 1.3)), spacing: 16, alignment: .top)]
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 960 && !typeSize.isAccessibilitySize
                let compactComposer = geometry.size.width < 700 || typeSize.isAccessibilitySize

                Group {
                    if wide {
                        VStack(spacing: 24) {
                            if !isEditorFocused { header }
                            composer(compact: false)
                            HStack(alignment: .top, spacing: 24) {
                                categorySidebar.frame(width: 248)
                                VStack(alignment: .leading, spacing: 16) {
                                    libraryHeader
                                    ScrollView {
                                        phraseGrid
                                            .padding(.bottom, 16)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                        .padding(28)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                header
                                composer(compact: compactComposer)
                                compactCategories
                                libraryHeader
                                phraseGrid
                            }
                            .padding(16)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .background { YAMAmbientBackground(theme: theme) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(speechService.isSpeaking ? "Arrêter" : "Parler", action: toggleSpeech)
                        .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !speechService.isSpeaking)
                    Spacer()
                    Button("Masquer le clavier") { isEditorFocused = false }
                }
            }
            .sheet(item: $sheet, onDismiss: presentPendingEditor) { destination in
                sheetContent(destination)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(themeManager.appearance.colorScheme)
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                FullScreenTextView(text: fullScreenText ?? textInput) {
                    speechService.speak(text: fullScreenText ?? textInput)
                }
            }
            .onAppear {
                DataSeedService.seedInitialDataIfNeeded(in: modelContext)
                let profile = profileManager.ensureDefaultProfileExists(in: modelContext)
                themeManager.syncTheme(from: activeProfile ?? profile)
                validateCategory()
            }
            .onChange(of: userCategories.map(\.id)) { _, _ in validateCategory() }
            .onChange(of: profileManager.activeProfileId) { _, _ in
                speechService.stop()
                textInput = ""
                clearedText = ""
                selectedCategoryId = ""
                if let profile = activeProfile { profileManager.applyProfileSettings(profile) }
                validateCategory()
            }
            .onChange(of: textInput) { _, text in
                if !text.isEmpty { clearedText = "" }
            }
        }
        .tint(theme.accentColor)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                branding
                Spacer(minLength: 16)
                profileMenu
                headerActions
            }
            VStack(alignment: .leading, spacing: 12) {
                branding
                profileMenu
                headerActions
            }
        }
    }

    private var branding: some View {
        HStack(spacing: 12) {
            Image(systemName: theme.icon)
                .font(.title2.weight(theme.iconWeight))
                .foregroundStyle(theme.onAccentColor)
                .frame(width: 48, height: 48)
                .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("YAMParle")
                    .font(.system(.title2, design: theme.fontDesign, weight: .bold))
                    .foregroundStyle(theme.primaryTextColor)
                Text("À votre rythme.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .combine)
    }

    private var profileMenu: some View {
        Menu {
            ForEach(profiles) { profile in
                Button {
                    profileManager.activeProfileId = profile.id
                } label: {
                    Label(profile.name, systemImage: profile.id == effectiveProfileId ? "checkmark.circle" : "person.circle")
                }
            }
            Divider()
            Button { sheet = .profiles } label: { Label("Gérer les profils", systemImage: "person.2") }
        } label: {
            HStack(spacing: 10) {
                if let data = activeProfile?.avatarImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 32, height: 32).clipShape(Circle())
                } else {
                    Image(systemName: activeProfile?.avatarSymbol ?? "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(theme.accentColor)
                }
                Text(activeProfile?.name ?? "Utilisateur par défaut")
                    .font(.body.weight(.medium))
                Image(systemName: "chevron.down").font(.caption.weight(.bold))
            }
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .yamSurface(theme)
        }
        .accessibilityLabel("Profil actif : \(activeProfile?.name ?? "Utilisateur par défaut")")
        .accessibilityHint("Changer de profil ou gérer les utilisateurs.")
    }

    private var headerActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { searchButton; settingsButton }
            VStack(alignment: .leading, spacing: 12) { searchButton; settingsButton }
        }
    }

    private var searchButton: some View {
        YAMActionButton(title: "Rechercher", icon: "magnifyingglass", isFullWidth: false) {
            isEditorFocused = false
            sheet = .search
        }
    }

    private var settingsButton: some View {
        YAMActionButton(title: "Réglages", icon: "slider.horizontal.3", isFullWidth: false) {
            isEditorFocused = false
            sheet = .settings
        }
    }

    private func composer(compact: Bool) -> some View {
        CommunicationComposer(
            text: $textInput, focus: $isEditorFocused, theme: theme, compact: compact,
            isSpeaking: speechService.isSpeaking, canRestore: !clearedText.isEmpty,
            onSpeak: toggleSpeech, onClearOrRestore: clearOrRestore,
            onSave: { sheet = .savePhrase }, onDeleteWord: deleteLastWord,
            onFullScreen: {
                fullScreenText = textInput
                isEditorFocused = false
                showingFullScreen = true
            }
        )
    }

    private var categorySidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Catégories")
                .font(.headline)
                .foregroundStyle(theme.primaryTextColor)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 12)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(userCategories) { category in categoryButton(category) }
                }
            }
            Button { sheet = .newCategory } label: {
                Label("Nouvelle catégorie", systemImage: "folder.badge.plus")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
        }
        .padding(16)
        .yamSurface(theme)
    }

    private var compactCategories: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catégories")
                .font(.headline)
                .foregroundStyle(theme.primaryTextColor)
                .accessibilityAddTraits(.isHeader)
            if typeSize.isAccessibilitySize {
                DisclosureGroup(activeCategory?.name ?? "Choisir une catégorie") {
                    ForEach(userCategories) { category in categoryButton(category) }
                }
                .font(.body)
                .padding(16)
                .yamSurface(theme)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(userCategories) { category in
                            categoryButton(category).frame(minWidth: 200)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func categoryButton(_ category: AACCategory) -> some View {
        ModernCategoryTile(
            category: category, isSelected: category.id == activeCategory?.id,
            count: userItems.filter { $0.categoryId == category.id }.count
        ) { selectedCategoryId = category.id }
    }

    private var libraryHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) { libraryTitle; Spacer(); addMenu }
            VStack(alignment: .leading, spacing: 12) { libraryTitle; addMenu }
        }
    }

    private var libraryTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activeCategory?.name ?? "Vos phrases")
                .font(.system(.title2, design: theme.fontDesign, weight: .bold))
                .foregroundStyle(theme.primaryTextColor)
                .accessibilityAddTraits(.isHeader)
            Text(speechService.speakOnTap ? "Touchez une carte pour ajouter et parler." : "Touchez une carte pour composer votre phrase.")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
        }
    }

    private var addMenu: some View {
        Menu {
            Button { sheet = .newPhrase } label: { Label("Nouvelle phrase", systemImage: "plus.bubble") }
                .disabled(userCategories.isEmpty)
            Button { sheet = .savePhrase } label: { Label("Enregistrer la phrase actuelle", systemImage: "bookmark") }
                .disabled(userCategories.isEmpty || textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button { sheet = .newCategory } label: { Label("Nouvelle catégorie", systemImage: "folder.badge.plus") }
        } label: {
            YAMActionLabel(title: "Ajouter", icon: "plus", theme: theme)
        }
    }

    private var phraseGrid: some View {
        Group {
            if displayedItems.isEmpty {
                ContentUnavailableView {
                    Label(userCategories.isEmpty ? "Votre espace de communication" : "Aucune phrase ici", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text(userCategories.isEmpty ? "Créez une catégorie, puis ajoutez vos premières phrases." : "Ajoutez une phrase à cette catégorie pour la retrouver en un toucher.")
                } actions: {
                    Button(userCategories.isEmpty ? "Créer une catégorie" : "Ajouter une phrase") {
                        sheet = userCategories.isEmpty ? .newCategory : .newPhrase
                    }
                    .frame(minHeight: 56)
                }
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(displayedItems) { item in
                        ModernAACCard(
                            item: item, categoryColor: activeCategory?.color ?? theme.accentColor,
                            speaksOnTap: speechService.speakOnTap,
                            onTap: {
                                appendPhrase(item.text)
                                if speechService.speakOnTap { speechService.speakItem(item) }
                            },
                            onSpeak: { speechService.speakItem(item) },
                            onEdit: { sheet = .edit(item) }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ destination: AACSheet) -> some View {
        switch destination {
        case .profiles:
            NavigationStack {
                UserProfilesView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Fermer") { sheet = nil } }
                    }
            }
        case .search:
            SearchView(
                categories: userCategories, allItems: userItems,
                onSelectPhrase: appendPhrase,
                onEditPhrase: { item in pendingEdit = item; sheet = nil }
            )
        case .settings:
            SettingsView()
        case .newCategory:
            CategoryEditorView()
        case .newPhrase, .savePhrase:
            if userCategories.isEmpty {
                CategoryEditorView()
            } else {
                ItemEditorView(
                    existingItem: nil, defaultCategoryId: activeCategory?.id ?? "",
                    initialText: destination.id == "savePhrase" ? textInput : nil, categories: userCategories
                )
            }
        case .edit(let item):
            ItemEditorView(existingItem: item, defaultCategoryId: item.categoryId, categories: userCategories)
        }
    }

    private func presentPendingEditor() {
        if let item = pendingEdit {
            pendingEdit = nil
            sheet = .edit(item)
        }
    }

    private func validateCategory() {
        if !userCategories.contains(where: { $0.id == selectedCategoryId }) {
            selectedCategoryId = (userCategories.first { $0.id.contains("conversation") } ?? userCategories.first)?.id ?? ""
        }
    }

    private func appendPhrase(_ phrase: String) {
        let current = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        textInput = current.isEmpty ? phrase : current + " " + phrase
    }

    private func toggleSpeech() {
        if speechService.isSpeaking {
            speechService.stop()
            return
        }
        let phrase = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phrase.isEmpty else { return }
        speechService.speak(text: phrase)
        if speechService.clearAfterSpeaking {
            clearedText = textInput
            textInput = ""
        }
    }

    private func clearOrRestore() {
        if textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textInput = clearedText
            clearedText = ""
        } else {
            clearedText = textInput
            textInput = ""
        }
    }

    private func deleteLastWord() {
        var words = textInput.split(whereSeparator: { $0.isWhitespace })
        guard !words.isEmpty else { return }
        clearedText = textInput
        words.removeLast()
        textInput = words.joined(separator: " ")
    }
}

#Preview("iPad · Clair", traits: .landscapeLeft) {
    ContentView()
        .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
        .environment(\.colorScheme, .light)
}

#Preview("iPad · Sombre", traits: .landscapeLeft) {
    ContentView()
        .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
        .environment(\.colorScheme, .dark)
}

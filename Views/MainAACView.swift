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
    @State private var profileToActivate: UserProfile?
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

        /// Les écrans de gestion s’ouvrent en fenêtre centrée, les formulaires en feuille entière.
        var sheetKind: YAMSheetKind {
            switch self {
            case .settings, .profiles: return .window
            case .search, .newPhrase, .savePhrase, .newCategory, .edit: return .sheet
            }
        }
    }

    private var theme: AppTheme { themeManager.currentTheme }
    /// Une phrase en cours de composition n’est pas encore enregistrée : changer de profil l’efface.
    private var hasUnsavedDraft: Bool {
        !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
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
        return [GridItem(.adaptive(minimum: YAMLayout.gridCardMinWidth * min(max(gridCardSize, 0.8), 1.3)), spacing: YAMLayout.gridSpacing, alignment: .top)]
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 960 && !typeSize.isAccessibilitySize
                let compactComposer = geometry.size.width < 700 || typeSize.isAccessibilitySize

                Group {
                    if wide {
                        VStack(spacing: YAMSpacing.large) {
                            if !isEditorFocused { header }
                            composer(compact: false)
                            HStack(alignment: .top, spacing: YAMSpacing.large) {
                                categorySidebar.frame(width: YAMLayout.categorySidebarWidth)
                                VStack(alignment: .leading, spacing: YAMSpacing.medium) {
                                    libraryHeader
                                    ScrollView {
                                        phraseGrid
                                            .padding(.bottom, YAMSpacing.medium)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                        .padding(YAMSpacing.page)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: YAMSpacing.large) {
                                header
                                composer(compact: compactComposer)
                                compactCategories
                                libraryHeader
                                phraseGrid
                            }
                            .padding(YAMSpacing.pageCompact)
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
                    .yamSheetPresentation(destination.sheetKind)
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
            .yamProfileSwitchConfirmation(isPresented: profileSwitchBinding, onConfirm: confirmProfileSwitch)
        }
        .tint(theme.accentColor)
    }

    private var profileSwitchBinding: Binding<Bool> {
        Binding(get: { profileToActivate != nil }, set: { if !$0 { profileToActivate = nil } })
    }

    /// Le menu de l’en-tête et la gestion des profils posent la même question au même moment.
    private func requestProfileSwitch(to profile: UserProfile) {
        guard profile.id != profileManager.activeProfileId else { return }
        guard hasUnsavedDraft else {
            activate(profile)
            return
        }
        profileToActivate = profile
    }

    private func confirmProfileSwitch() {
        guard let profile = profileToActivate else { return }
        profileToActivate = nil
        activate(profile)
    }

    private func activate(_ profile: UserProfile) {
        profileManager.activeProfileId = profile.id
        profileManager.applyProfileSettings(profile)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: YAMSpacing.large) {
                branding
                Spacer(minLength: YAMSpacing.large)
                profileMenu
                headerActions
            }
            VStack(alignment: .leading, spacing: YAMSpacing.medium) {
                branding
                profileMenu
                headerActions
            }
        }
    }

    private var branding: some View {
        HStack(spacing: YAMSpacing.medium) {
            Image(systemName: theme.icon)
                .font(.body.weight(theme.iconWeight))
                .foregroundStyle(theme.onAccentColor)
                .frame(width: 32, height: 32)
                .background(theme.accentColor, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("YAMParle")
                    .font(.system(.title3, design: theme.fontDesign, weight: .bold))
                    .foregroundStyle(theme.primaryTextColor)
                Text("À votre rythme.")
                    .font(.footnote)
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
                    requestProfileSwitch(to: profile)
                } label: {
                    Label(profile.name, systemImage: profile.id == effectiveProfileId ? "checkmark.circle.fill" : "person.circle")
                }
            }
            Divider()
            Button { sheet = .profiles } label: { Label("Gérer les profils", systemImage: "person.2") }
        } label: {
            HStack(spacing: YAMSpacing.small) {
                if let data = activeProfile?.avatarImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 24, height: 24).clipShape(Circle())
                } else {
                    Image(systemName: activeProfile?.avatarSymbol ?? "person.crop.circle")
                        .font(.body)
                        .foregroundStyle(theme.accentColor)
                }
                Text(activeProfile?.name ?? "Utilisateur par défaut")
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down").font(.caption2.weight(.bold))
            }
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 10)
            .frame(minHeight: YAMSpacing.minimumTarget)
            .yamSurface(theme)
        }
        .accessibilityLabel("Profil actif : \(activeProfile?.name ?? "Utilisateur par défaut")")
        .accessibilityHint("Changer de profil ou gérer les utilisateurs.")
    }

    private var headerActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: YAMSpacing.medium) { searchButton; settingsButton }
            VStack(alignment: .leading, spacing: YAMSpacing.small) { searchButton; settingsButton }
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
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            Text("Catégories")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.secondaryTextColor)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 4)
            ScrollView {
                VStack(spacing: YAMSpacing.small) {
                    ForEach(userCategories) { category in categoryButton(category) }
                }
            }
            Button { sheet = .newCategory } label: {
                Label("Nouvelle catégorie", systemImage: "folder.badge.plus")
                    .font(.footnote.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: YAMSpacing.minimumTarget)
                    .contentShape(Rectangle())
            }
        }
        .padding(YAMSpacing.medium)
        .yamSurface(theme)
    }

    private var compactCategories: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.small) {
            Text("Catégories")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.secondaryTextColor)
                .accessibilityAddTraits(.isHeader)
            if typeSize.isAccessibilitySize {
                DisclosureGroup(activeCategory?.name ?? "Choisir une catégorie") {
                    ForEach(userCategories) { category in categoryButton(category) }
                }
                .font(.callout)
                .padding(YAMSpacing.medium)
                .yamSurface(theme)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: YAMSpacing.medium) {
                        ForEach(userCategories) { category in
                            categoryButton(category).frame(minWidth: 152)
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
            HStack(alignment: .center, spacing: YAMSpacing.large) { libraryTitle; Spacer(); addMenu }
            VStack(alignment: .leading, spacing: YAMSpacing.medium) { libraryTitle; addMenu }
        }
    }

    private var libraryTitle: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(activeCategory?.name ?? "Vos phrases")
                .font(.system(.title3, design: theme.fontDesign, weight: .bold))
                .foregroundStyle(theme.primaryTextColor)
                .accessibilityAddTraits(.isHeader)
            Text(speechService.speakOnTap ? "Touchez une carte pour ajouter et parler." : "Touchez une carte pour composer votre phrase.")
                .font(.footnote)
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
                    .frame(minHeight: YAMSpacing.minimumTarget)
                }
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: YAMLayout.gridSpacing) {
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
                UserProfilesView(hasUnsavedDraft: hasUnsavedDraft, onClose: { sheet = nil })
            }
        case .search:
            SearchView(
                categories: userCategories, allItems: userItems,
                onSelectPhrase: appendPhrase,
                onEditPhrase: { item in pendingEdit = item; sheet = nil }
            )
        case .settings:
            SettingsView(hasUnsavedDraft: hasUnsavedDraft)
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

// Portrait : à vérifier dans Xcode en basculant l’appareil du canvas (pas de trait dédié).
// La disposition large exige 960 pt de largeur ; à 834 pt (iPad Pro 11" en portrait),
// l’écran principal bascule en page verticale défilante avec catégories horizontales.
#Preview("iPad · Réglages") {
    SettingsView()
        .modelContainer(for: [AACCategory.self, AACItem.self, FavoritePhrase.self, UserProfile.self], inMemory: true)
        .frame(maxWidth: YAMLayout.windowMaxWidth)
}

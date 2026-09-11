import SwiftUI

/// Espacements de l’interface. Volontairement compacts : l’application cible l’iPad,
/// où de grandes marges donnaient l’impression d’une interface zoomée.
/// Les valeurs restent exprimées en points et s’appliquent en plus du Dynamic Type.
enum YAMSpacing {
    static let tiny: CGFloat = 4
    static let small: CGFloat = 6
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let section: CGFloat = 16
    /// Marge extérieure d’une page large (iPad en paysage, Split View confortable).
    static let page: CGFloat = 18
    /// Marge extérieure d’une page étroite (portrait, fenêtre petite).
    static let pageCompact: CGFloat = 12
    /// Cible tactile minimale : 44 pt, plancher Apple, jamais réduit sous cette valeur.
    static let minimumTarget: CGFloat = 44
}

/// Dimensions des éléments : cartes, colonnes, compositeur, fenêtres modales, formulaires.
/// Un seul endroit pour changer les proportions de l’application.
enum YAMLayout {
    /// Largeur de la colonne Catégories en disposition large.
    static let categorySidebarWidth: CGFloat = 208
    /// Largeur minimale d’une carte de phrase ; plus elle est petite, plus la grille tient de cartes.
    static let gridCardMinWidth: CGFloat = 168
    static let gridSpacing: CGFloat = 10
    /// Hauteur minimale d’une carte de phrase, hors texte qui dépasse.
    static let cardMinHeight: CGFloat = 92
    static let cardSymbolSize: CGFloat = 19
    static let cardArtworkSize: CGFloat = 36
    /// Marge intérieure d’une face de carte : le libellé est aligné sous l’illustration.
    static let cardFaceLeadingPadding: CGFloat = 12
    static let cardFaceVerticalPadding: CGFloat = 10
    /// Colonne des options d’une carte (bouton ⋯) : 40 × 44 pt.
    static let cardOptionsWidth: CGFloat = 40
    /// Hauteur du champ « Votre phrase ».
    static let composerEditorHeight: CGFloat = 64
    static let composerPadding: CGFloat = 14
    /// Commande principale « Parler » : dominante, mais plus énorme.
    static let heroHeight: CGFloat = 56
    static let controlHeight: CGFloat = YAMSpacing.minimumTarget
    static let rowHeight: CGFloat = 44
    /// Petites puces `.bordered` : le style ajoute ~4 pt de marge verticale de chaque côté, la cible dépasse 44 pt.
    static let chipHeight: CGFloat = 36
    /// Fenêtre Réglages : carte centrée façon iPadOS, jamais plein écran.
    static let windowMaxWidth: CGFloat = 744
    /// Colonne de contenu à l’intérieur de la fenêtre, pour éviter les lignes kilométriques.
    static let windowContentWidth: CGFloat = 744
    /// Grilles de choix des formulaires : dessin de la pastille et largeur de colonne.
    static let swatchGlyphSize: CGFloat = 34
    static let swatchColumnMinWidth: CGFloat = 48
    static let iconColumnMinWidth: CGFloat = 56
    /// Avatar d’un profil dans la liste de gestion.
    static let avatarSize: CGFloat = 38
    static let avatarGlyphSize: CGFloat = 34
    /// Témoin de l’enregistrement en cours dans les formulaires.
    static let recordingDotSize: CGFloat = 10
}

/// Tons sémantiques qui ne suivent pas le thème choisi : suppression, avertissement, confirmation.
/// Ils colorent l’icône, le fond teinté et le contour — jamais le libellé seul, qui garde la
/// couleur de texte du thème dont le contraste est vérifié par les tests numériques.
enum YAMTone {
    static let destructive = Color(uiColor: .systemRed)
    static let warning = Color(uiColor: .systemOrange)
    static let positive = Color(uiColor: .systemGreen)
}

/// Style de présentation d’une feuille.
enum YAMSheetKind {
    /// Fenêtre centrée de type Réglages iPadOS : largeur bornée, hauteur adaptée au contenu.
    case window
    /// Feuille standard, hauteur maximale, pour les formulaires et la recherche.
    case sheet
}

/// Applique le style de présentation choisi à une feuille.
///
/// - iPadOS 18 et plus : `presentationSizing(.form)` donne une carte centrée, ni plein écran,
///   dont la hauteur suit le contenu. C’est le comportement natif des Réglages iPadOS.
/// - iPadOS 17 : les detents sont ignorées en largeur régulière ; on borne donc la largeur du
///   contenu, et les detents restent actives pour l’iPhone et Split View.
struct YAMSheetPresentation: ViewModifier {
    let kind: YAMSheetKind

    @ViewBuilder
    func body(content: Content) -> some View {
        switch kind {
        case .window:
            if #available(iOS 18.0, *) {
                content
                    .presentationSizing(.form)
            } else {
                content
                    .frame(maxWidth: YAMLayout.windowMaxWidth)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        case .sheet:
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

extension View {
    func yamSheetPresentation(_ kind: YAMSheetKind = .sheet) -> some View {
        modifier(YAMSheetPresentation(kind: kind))
    }

    /// Confirmations partagées : un changement de profil efface la phrase en cours de composition.
    /// L’écran qui présente la liste des profils et l’en-tête de l’accueil posent la même question,
    /// avec le même libellé, pour ne jamais surprendre deux fois différemment.
    func yamProfileSwitchConfirmation(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        confirmationDialog(
            "Changer de profil ?",
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button("Changer de profil", action: onConfirm)
            Button("Garder ce profil", role: .cancel) { }
        } message: {
            Text("Votre phrase en cours de composition sera effacée et la lecture arrêtée.")
        }
    }
}

enum YAMFeedback {
    static func selection() {
        let enabled = UserDefaults.standard.object(forKey: "yamparle_haptic_feedback") as? Bool
        guard enabled != false else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct YAMPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scaleAmount: CGFloat = 0.985
    var opacityAmount: Double = 0.82

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scaleAmount : 1)
            .opacity(configuration.isPressed ? opacityAmount : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == YAMPressButtonStyle {
    static var yamPress: YAMPressButtonStyle { YAMPressButtonStyle() }
    static func yamPress(scale: CGFloat) -> YAMPressButtonStyle { YAMPressButtonStyle(scaleAmount: scale) }
}

private struct YAMSurface: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage("yamparle_high_contrast") private var highContrast = false
    let theme: AppTheme
    var selected = false

    func body(content: Content) -> some View {
        content
            .background(selected ? theme.secondaryCardBackground : theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? theme.accentColor : (highContrast || contrast == .increased ? theme.primaryTextColor : theme.borderColor),
                        lineWidth: highContrast || contrast == .increased || selected ? 2 : theme.borderWidth
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: theme.shadowColor, radius: 8, y: 3)
    }
}

extension View {
    func yamSurface(_ theme: AppTheme, selected: Bool = false) -> some View {
        modifier(YAMSurface(theme: theme, selected: selected))
    }
}

struct YAMAmbientBackground: View {
    let theme: AppTheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage("yamparle_high_contrast") private var highContrast = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.backgroundColor
            if !reduceTransparency && !highContrast && contrast != .increased {
                switch theme.ornament {
                case .glow:
                    RadialGradient(colors: [theme.accentColor.opacity(0.1), .clear], center: .topTrailing, startRadius: 0, endRadius: 460)
                case .line:
                    Rectangle()
                        .fill(theme.secondaryAccentColor.opacity(0.14))
                        .frame(height: 2)
                case .orbit:
                    Circle()
                        .stroke(theme.secondaryAccentColor.opacity(0.07), lineWidth: 26)
                        .frame(width: 340, height: 340)
                        .offset(x: 150, y: -220)
                    }
            }
        }
        .clipped()
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum YAMActionButtonVariant {
    case hero(Color), primary(Color), secondary, destructive, warning, neutral

    /// Les actions dominantes gardent un corps de texte supérieur aux actions secondaires.
    var isDominant: Bool {
        switch self {
        case .hero, .primary: return true
        default: return false
        }
    }

    /// Les actions qui annulent ou dégradent une donnée portent un ton visible,
    /// sans que la couleur soit le seul indice : le libellé reste explicite.
    var carriesTone: Bool {
        switch self {
        case .destructive, .warning: return true
        default: return false
        }
    }
}

struct YAMActionLabel: View {
    let title: String
    let icon: String
    let theme: AppTheme

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(.callout, design: theme.fontDesign, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minHeight: YAMSpacing.minimumTarget)
            .background(theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
    }
}

struct YAMActionButton: View {
    let title: String
    let icon: String
    var variant: YAMActionButtonVariant = .secondary
    var isSpeaking = false
    var isFullWidth = true
    var height: CGFloat = YAMLayout.controlHeight
    var action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Bindable private var themeManager = ThemeManager.shared
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        Button {
            YAMFeedback.selection()
            action()
        } label: {
            Label(title, systemImage: isSpeaking ? "stop.fill" : icon)
                .font(.system(variant.isDominant ? .body : .callout, design: theme.fontDesign, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(foreground, iconForeground)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: max(height, YAMSpacing.minimumTarget))
                .background(background, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
                .overlay {
                    if variant.carriesTone {
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                            .strokeBorder(tone.opacity(0.65), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.yamPress)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var tone: Color {
        switch variant {
        case .destructive: return YAMTone.destructive
        case .warning: return YAMTone.warning
        default: return theme.accentColor
        }
    }

    private var foreground: Color {
        switch variant {
        case .hero, .primary: return theme.onAccentColor
        default: return theme.primaryTextColor
        }
    }

    /// Le ton ne colore que le pictogramme : le texte garde un contraste testé sur sa surface.
    private var iconForeground: Color {
        switch variant {
        case .hero, .primary: return theme.onAccentColor
        case .destructive, .warning: return tone
        default: return theme.primaryTextColor
        }
    }

    private var background: Color {
        switch variant {
        case .hero(let color), .primary(let color): return color
        case .destructive: return YAMTone.destructive.opacity(0.12)
        case .warning: return YAMTone.warning.opacity(0.14)
        case .neutral: return .clear
        default: return theme.secondaryCardBackground
        }
    }
}

/// Le dessin d’une carte de phrase : illustration, libellé, badge de voix.
///
/// L’accueil, la recherche et l’aperçu des formulaires partagent ce rendu. Un formulaire
/// ne redessine donc pas « sa » carte à part : ce que l’on voit dans l’aperçu est ce que
/// l’on touchera sur l’écran principal, y compris pour un libellé très long.
struct YAMCardFace: View {
    let label: String
    let symbolName: String
    var imageData: Data? = nil
    var tint: Color = Color.clear
    /// « Voix enregistrée » ou « Voix IA » ; nil quand la carte parle avec la voix du profil.
    var audioBadgeTitle: String? = nil

    @Bindable private var themeManager = ThemeManager.shared
    @ScaledMetric(relativeTo: .body) private var symbolSize: CGFloat = YAMLayout.cardSymbolSize
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        VStack(alignment: .leading, spacing: YAMSpacing.medium) {
            artwork
                .accessibilityHidden(true)

            Text(label)
                .font(.system(.body, design: theme.fontDesign, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let audioBadgeTitle {
                Label(audioBadgeTitle, systemImage: "waveform")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: YAMLayout.cardMinHeight, alignment: .topLeading)
        .padding(.leading, YAMLayout.cardFaceLeadingPadding)
        .padding(.vertical, YAMLayout.cardFaceVerticalPadding)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var artwork: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: YAMLayout.cardArtworkSize, height: YAMLayout.cardArtworkSize)
                .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
        } else {
            Image(systemName: symbolName)
                .font(.system(size: symbolSize, weight: theme.iconWeight))
                .foregroundStyle(theme.accentColor)
                .frame(
                    minWidth: YAMLayout.cardArtworkSize,
                    minHeight: YAMLayout.cardArtworkSize * 3 / 4
                )
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
        }
    }
}

struct ModernAACCard: View {
    let item: AACItem
    let categoryColor: Color
    var isSelected = false
    var speaksOnTap = false
    let onTap: () -> Void
    let onSpeak: () -> Void
    let onEdit: () -> Void

    @Bindable private var themeManager = ThemeManager.shared
    private var theme: AppTheme { themeManager.currentTheme }
    private var color: Color { item.effectiveColor ?? categoryColor }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                YAMFeedback.selection()
                onTap()
            } label: {
                YAMCardFace(
                    label: item.displayLabel,
                    symbolName: item.iconName,
                    imageData: item.customImageData,
                    tint: color,
                    audioBadgeTitle: audioBadgeTitle
                )
            }
            .buttonStyle(.yamPress)
            .accessibilityLabel(item.displayLabel)
            .accessibilityHint(speaksOnTap ? "Ajoute à votre phrase et lit à voix haute." : "Ajoute à votre phrase.")
            .accessibilityAction(named: "Lire à voix haute", onSpeak)
            .accessibilityAction(named: "Modifier", onEdit)

            Menu {
                Button(action: onSpeak) { Label("Lire à voix haute", systemImage: "speaker.wave.2") }
                Button(action: onEdit) { Label("Modifier la phrase", systemImage: "pencil") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(theme.secondaryTextColor)
                    .frame(width: YAMLayout.cardOptionsWidth, height: YAMSpacing.minimumTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Options pour : \(item.displayLabel)")
        }
        .yamSurface(theme, selected: isSelected)
    }

    private var audioBadgeTitle: String? {
        guard item.hasCustomAudio else { return nil }
        return item.audioSourceType == "recording" ? "Voix enregistrée" : "Voix IA"
    }
}

struct ModernCategoryTile: View {
    let category: AACCategory
    let isSelected: Bool
    let count: Int
    let onSelect: () -> Void

    @Bindable private var themeManager = ThemeManager.shared
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        Button {
            YAMFeedback.selection()
            onSelect()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.footnote.weight(theme.iconWeight))
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 26, height: 30)
                    .background(category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                Text(category.name)
                    .font(.system(.callout, design: theme.fontDesign, weight: isSelected ? .semibold : .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                } else {
                    Text("\(count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minHeight: YAMLayout.rowHeight)
            .background(isSelected ? theme.secondaryCardBackground : theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                    .strokeBorder(isSelected ? theme.accentColor : .clear, lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.yamPress)
        .accessibilityLabel(category.name)
        .accessibilityValue("\(count) phrases")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Choices des formulaires

/// Pastille de couleur avec son nom, pour que le choix ne se lise pas seulement à l’œil.
struct YAMSwatch: Identifiable {
    let hex: String
    let title: String
    var id: String { hex }

    static let palette: [YAMSwatch] = [
        YAMSwatch(hex: "#1E73F2", title: "Bleu"),
        YAMSwatch(hex: "#30D158", title: "Vert"),
        YAMSwatch(hex: "#FF9F0A", title: "Orange"),
        YAMSwatch(hex: "#40CBE0", title: "Turquoise"),
        YAMSwatch(hex: "#FF375F", title: "Rose"),
        YAMSwatch(hex: "#BF5AF2", title: "Violet"),
        YAMSwatch(hex: "#5E5CE6", title: "Indigo"),
        YAMSwatch(hex: "#FFD60A", title: "Jaune"),
        YAMSwatch(hex: "#AC8E68", title: "Brun"),
        YAMSwatch(hex: "#64D2FF", title: "Bleu ciel"),
        YAMSwatch(hex: "#FF453A", title: "Rouge"),
        YAMSwatch(hex: "#8E8E93", title: "Gris"),
    ]

    /// Les teintes proposées aux profils, plus sobres que la palette complète des cartes.
    static let profilePalette: [YAMSwatch] = Array(palette.prefix(8))
}

/// Symbole proposé à un choix d’icône, toujours accompagné de son nom.
struct YAMIconChoice: Identifiable {
    let symbol: String
    let title: String
    var id: String { symbol }
}

/// Grille de pastilles de couleur : sélection marquée par une coche, pas seulement par un anneau.
struct YAMSwatchGrid: View {
    @Binding var selection: String
    var swatches: [YAMSwatch] = YAMSwatch.palette

    @Bindable private var themeManager = ThemeManager.shared
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: YAMLayout.swatchColumnMinWidth), spacing: YAMSpacing.medium)],
            spacing: YAMSpacing.medium
        ) {
            ForEach(swatches) { swatch in
                Button {
                    YAMFeedback.selection()
                    selection = swatch.hex
                } label: {
                    Circle()
                        .fill(Color(hex: swatch.hex))
                        .frame(width: YAMLayout.swatchGlyphSize, height: YAMLayout.swatchGlyphSize)
                        .overlay {
                            if selection == swatch.hex {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black)
                            }
                        }
                        .frame(width: YAMSpacing.minimumTarget, height: YAMSpacing.minimumTarget)
                        .background(
                            selection == swatch.hex ? theme.secondaryCardBackground : .clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay {
                            if selection == swatch.hex {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(theme.accentColor, lineWidth: 2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(swatch.title)
                .accessibilityAddTraits(selection == swatch.hex ? [.isSelected] : [])
            }
        }
        .padding(.vertical, YAMSpacing.small)
    }
}

/// Grille d’icônes SF Symbols : cible de 44 pt, nom lu par VoiceOver, sélection annoncée.
struct YAMIconChoiceGrid: View {
    @Binding var selection: String
    let choices: [YAMIconChoice]

    @Bindable private var themeManager = ThemeManager.shared
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: YAMLayout.iconColumnMinWidth), spacing: YAMSpacing.medium)],
            spacing: YAMSpacing.medium
        ) {
            ForEach(choices) { choice in
                Button {
                    YAMFeedback.selection()
                    selection = choice.symbol
                } label: {
                    Image(systemName: choice.symbol)
                        .font(.title2)
                        .foregroundStyle(selection == choice.symbol ? theme.onAccentColor : theme.primaryTextColor)
                        .frame(width: YAMSpacing.minimumTarget, height: YAMSpacing.minimumTarget)
                        .background(
                            selection == choice.symbol ? theme.accentColor : theme.secondaryCardBackground,
                            in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                        )
                }
                .buttonStyle(.yamPress)
                .accessibilityLabel(choice.title)
                .accessibilityAddTraits(selection == choice.symbol ? [.isSelected] : [])
            }
        }
        .padding(.vertical, YAMSpacing.small)
    }
}

/// Section avancée repliable : les réglages que l’on touche rarement ne font plus
/// la concurrence aux réglages du quotidien, sans devenir introuvables.
struct YAMAdvancedSection<Content: View>: View {
    let title: String
    let summary: String?
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    @Bindable private var themeManager = ThemeManager.shared
    private var theme: AppTheme { themeManager.currentTheme }

    init(title: String, summary: String? = nil, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.summary = summary
        self._isExpanded = isExpanded
        self.content = content
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(theme.primaryTextColor)
                if let summary {
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(theme.accentColor)
        .accessibilityElement(children: .contain)
    }
}

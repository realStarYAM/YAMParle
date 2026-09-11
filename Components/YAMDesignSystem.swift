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

/// Dimensions des éléments : cartes, colonnes, compositeur, fenêtres modales.
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
                .foregroundStyle(foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: max(height, YAMSpacing.minimumTarget))
                .background(background, in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
        }
        .buttonStyle(.yamPress)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var foreground: Color {
        switch variant {
        case .hero, .primary: return theme.onAccentColor
        default: return theme.primaryTextColor
        }
    }

    private var background: Color {
        switch variant {
        case .hero(let color), .primary(let color): return color
        default: return theme.secondaryCardBackground
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
    @ScaledMetric(relativeTo: .body) private var symbolSize: CGFloat = YAMLayout.cardSymbolSize
    private var theme: AppTheme { themeManager.currentTheme }
    private var color: Color { item.effectiveColor ?? categoryColor }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                YAMFeedback.selection()
                onTap()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if let data = item.customImageData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: YAMLayout.cardArtworkSize, height: YAMLayout.cardArtworkSize)
                                .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
                        } else {
                            Image(systemName: item.iconName)
                                .font(.system(size: symbolSize, weight: theme.iconWeight))
                                .foregroundStyle(theme.accentColor)
                                .frame(
                                    minWidth: YAMLayout.cardArtworkSize,
                                    minHeight: YAMLayout.cardArtworkSize * 3 / 4
                                )
                                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
                        }
                    }
                    .accessibilityHidden(true)

                    Text(item.displayLabel)
                        .font(.system(.body, design: theme.fontDesign, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if item.hasCustomAudio {
                        Label(item.audioSourceType == "recording" ? "Voix enregistrée" : "Voix IA", systemImage: "waveform")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: YAMLayout.cardMinHeight, alignment: .topLeading)
                .padding(.leading, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
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
                    .frame(width: 40, height: YAMSpacing.minimumTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Options pour : \(item.displayLabel)")
        }
        .yamSurface(theme, selected: isSelected)
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

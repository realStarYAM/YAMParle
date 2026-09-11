import SwiftUI

enum YAMSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let section: CGFloat = 24
    static let page: CGFloat = 28
    static let minimumTarget: CGFloat = 56
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
            .shadow(color: theme.shadowColor, radius: 14, y: 5)
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
                    RadialGradient(colors: [theme.accentColor.opacity(0.1), .clear], center: .topTrailing, startRadius: 0, endRadius: 620)
                case .line:
                    Rectangle()
                        .fill(theme.secondaryAccentColor.opacity(0.14))
                        .frame(height: 3)
                case .orbit:
                    Circle()
                        .stroke(theme.secondaryAccentColor.opacity(0.07), lineWidth: 36)
                        .frame(width: 460, height: 460)
                        .offset(x: 180, y: -300)
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
}

struct YAMActionLabel: View {
    let title: String
    let icon: String
    let theme: AppTheme

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(.body, design: theme.fontDesign, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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
    var height: CGFloat = YAMSpacing.minimumTarget
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
                .font(.system(.body, design: theme.fontDesign, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
    @ScaledMetric(relativeTo: .title3) private var symbolSize: CGFloat = 25
    private var theme: AppTheme { themeManager.currentTheme }
    private var color: Color { item.effectiveColor ?? categoryColor }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                YAMFeedback.selection()
                onTap()
            } label: {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        if let data = item.customImageData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
                        } else {
                            Image(systemName: item.iconName)
                                .font(.system(size: symbolSize, weight: theme.iconWeight))
                                .foregroundStyle(theme.accentColor)
                                .frame(minWidth: 48, minHeight: 48)
                                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: theme.buttonCornerRadius / 2))
                        }
                    }
                    .accessibilityHidden(true)

                    Text(item.displayLabel)
                        .font(.system(.title3, design: theme.fontDesign, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if item.hasCustomAudio {
                        Label(item.audioSourceType == "recording" ? "Voix enregistrée" : "Voix IA", systemImage: "waveform")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                .padding(.leading, 20)
                .padding(.vertical, 20)
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
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.secondaryTextColor)
                    .frame(width: 48, height: 56)
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
            HStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.body.weight(theme.iconWeight))
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 32, height: 36)
                    .background(category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                Text(category.name)
                    .font(.system(.body, design: theme.fontDesign, weight: isSelected ? .semibold : .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(theme.accentColor)
                } else {
                    Text("\(count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
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

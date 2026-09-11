//
//  YAMDesignSystem.swift
//  YAMParle
//

import SwiftUI

// MARK: - Press Scale Button Style
struct YAMPressButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96
    var opacityAmount: Double = 0.9

    init(scaleAmount: CGFloat = 0.96, opacityAmount: Double = 0.9) {
        self.scaleAmount = scaleAmount
        self.opacityAmount = opacityAmount
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? opacityAmount : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == YAMPressButtonStyle {
    static var yamPress: YAMPressButtonStyle { YAMPressButtonStyle() }
    static func yamPress(scale: CGFloat) -> YAMPressButtonStyle { YAMPressButtonStyle(scaleAmount: scale) }
}

// MARK: - Action Button Variants
enum YAMActionButtonVariant {
    case hero(Color)
    case primary(Color)
    case secondary
    case destructive
    case warning
    case neutral
}

// MARK: - Reusable Action Button
struct YAMActionButton: View {
    let title: String
    let icon: String
    let variant: YAMActionButtonVariant
    var isSpeaking: Bool = false
    var isFullWidth: Bool = true
    var height: CGFloat = 42
    var action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Bindable private var themeManager = ThemeManager.shared

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    init(
        title: String,
        icon: String,
        variant: YAMActionButtonVariant = .secondary,
        isSpeaking: Bool = false,
        isFullWidth: Bool = true,
        height: CGFloat = 42,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.isSpeaking = isSpeaking
        self.isFullWidth = isFullWidth
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if isSpeaking {
                    Image(systemName: "waveform")
                        .font(.system(size: 16, weight: .black))
                        .symbolEffect(.variableColor.iterative.reversing)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: theme.fontDesign))
                    .lineLimit(1)

                if isFullWidth {
                    Spacer(minLength: 0)
                }
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                    .strokeBorder(borderStrokeColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, y: 1.5)
        }
        .buttonStyle(.yamPress)
        .opacity(isEnabled ? 1.0 : 0.45)
    }

    private var foregroundColor: Color {
        switch variant {
        case .hero, .primary:
            return .white
        case .destructive:
            return Color(hex: "#FF3B30")
        case .warning:
            return Color(hex: "#FF9500")
        case .secondary, .neutral:
            return theme.primaryTextColor
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .hero(let color):
            return color
        case .primary(let color):
            return color
        case .destructive:
            return Color(hex: "#FF3B30").opacity(0.12)
        case .warning:
            return Color(hex: "#FF9500").opacity(0.12)
        case .secondary:
            return theme.secondaryCardBackground
        case .neutral:
            return theme.cardBackground
        }
    }

    private var borderStrokeColor: Color {
        switch variant {
        case .hero, .primary:
            return Color.white.opacity(0.2)
        case .destructive:
            return Color(hex: "#FF3B30").opacity(0.3)
        case .warning:
            return Color(hex: "#FF9500").opacity(0.3)
        case .secondary, .neutral:
            return theme.borderColor
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .hero, .primary:
            return 1.0
        default:
            return 1.0
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .hero(let color):
            return color.opacity(0.35)
        case .primary(let color):
            return color.opacity(0.25)
        default:
            return theme.shadowColor
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .hero:
            return 5
        default:
            return 2
        }
    }
}

// MARK: - Modern AAC Phrase Card
struct ModernAACCard: View {
    let item: AACItem
    let categoryColor: Color
    var isSelected: Bool = false
    let onTap: () -> Void
    let onSpeak: () -> Void
    let onEdit: () -> Void

    @Bindable private var themeManager = ThemeManager.shared

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    init(
        item: AACItem,
        categoryColor: Color,
        isSelected: Bool = false,
        onTap: @escaping () -> Void,
        onSpeak: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) {
        self.item = item
        self.categoryColor = categoryColor
        self.isSelected = isSelected
        self.onTap = onTap
        self.onSpeak = onSpeak
        self.onEdit = onEdit
    }

    private var effectiveTint: Color {
        item.effectiveColor ?? categoryColor
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Top header: Icon + Audio Badge + Category Accent Bar
                HStack(alignment: .center, spacing: 8) {
                    // Symbol or Photo in circular container
                    ZStack {
                        Circle()
                            .fill(effectiveTint.opacity(0.16))
                            .frame(width: 40, height: 40)

                        if let data = item.customImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: item.iconName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(effectiveTint)
                        }
                    }

                    // Audio indicator badge (Micro or Waveform)
                    if item.hasCustomAudio {
                        HStack(spacing: 3) {
                            Image(systemName: item.audioSourceType == "recording" ? "mic.fill" : "waveform")
                                .font(.system(size: 9, weight: .heavy))
                            Text(item.audioSourceType == "recording" ? "VOIX" : "IA")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(item.audioSourceType == "recording" ? Color(hex: "#FF3B30") : Color(hex: "#8E44AD"))
                        )
                    }

                    Spacer()

                    // Category Pill Accent Pill
                    Capsule()
                        .fill(effectiveTint)
                        .frame(width: 22, height: 5)
                }

                // Phrase label
                Text(item.displayLabel)
                    .font(.system(.body, design: theme.fontDesign, weight: .bold))
                    .foregroundColor(theme.primaryTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(minHeight: 88)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? effectiveTint : theme.borderColor,
                        lineWidth: isSelected ? 2.5 : theme.borderWidth
                    )
            )
            .shadow(
                color: isSelected ? effectiveTint.opacity(0.3) : theme.shadowColor,
                radius: isSelected ? 6 : 3,
                y: isSelected ? 2 : 1.5
            )
        }
        .buttonStyle(.yamPress(scale: 0.95))
        .contextMenu {
            Button(action: onSpeak) {
                Label("Lire à voix haute", systemImage: "speaker.wave.2.fill")
            }
            Button(action: onEdit) {
                Label("Modifier cette phrase", systemImage: "pencil")
            }
        }
    }
}

// MARK: - Modern Category Row (iPad Sidebar)
struct ModernCategoryTile: View {
    let category: AACCategory
    let isSelected: Bool
    let count: Int
    let onSelect: () -> Void

    @Bindable private var themeManager = ThemeManager.shared

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    init(
        category: AACCategory,
        isSelected: Bool,
        count: Int,
        onSelect: @escaping () -> Void
    ) {
        self.category = category
        self.isSelected = isSelected
        self.count = count
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onSelect()
        }) {
            HStack(spacing: 10) {
                // Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.22) : category.color.opacity(0.18))
                        .frame(width: 30, height: 30)

                    Image(systemName: category.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .white : category.color)
                }

                // Name
                Text(category.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: theme.fontDesign))
                    .foregroundColor(isSelected ? .white : theme.primaryTextColor)
                    .lineLimit(1)

                Spacer(minLength: 4)

                // Count Badge
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? category.color : theme.secondaryTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white : theme.cardBackground)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                    .fill(isSelected ? category.color : theme.secondaryCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : theme.borderColor, lineWidth: 1)
            )
            .shadow(color: isSelected ? category.color.opacity(0.35) : Color.clear, radius: 4, y: 1.5)
        }
        .buttonStyle(.yamPress(scale: 0.97))
    }
}

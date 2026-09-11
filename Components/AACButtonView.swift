//
//  AACButtonView.swift
//  YAMParle
//

import SwiftUI

struct AACButtonView: View {
    let item: AACItem
    let categoryColor: Color
    let isEditing: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            if isEditing {
                onEdit()
            } else {
                onSelect()
            }
        } label: {
            VStack(spacing: 8) {
                // Top Category accent strip
                HStack {
                    Capsule()
                        .fill(item.effectiveColor ?? categoryColor)
                        .frame(width: 32, height: 4)
                }
                .padding(.top, 6)

                // Icon or Photo
                ZStack {
                    Circle()
                        .fill((item.effectiveColor ?? categoryColor).opacity(0.15))
                        .frame(width: 58, height: 58)

                    if let data = item.customImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: item.iconName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(item.effectiveColor ?? categoryColor)
                    }
                }
                .frame(height: 60)

                // Label Text
                Text(item.text)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 112)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isEditing
                            ? Color.yamAccent
                            : (item.effectiveColor ?? categoryColor).opacity(0.25),
                        lineWidth: isEditing ? 2 : 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(AACPressButtonStyle(isPressed: $isPressed))
        .overlay(alignment: .topTrailing) {
            if isEditing {
                HStack(spacing: -4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.white, Color.yamAccent)
                            .background(Circle().fill(Color.white))
                    }
                    .accessibilityLabel("Modifier \(item.text)")

                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.white, Color.red)
                            .background(Circle().fill(Color.white))
                    }
                    .accessibilityLabel("Supprimer \(item.text)")
                }
                .padding(4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.text)
        .accessibilityHint(isEditing ? "Touchez pour modifier ce pictogramme" : "Ajoute \(item.text) à la phrase")
        .accessibilityAddTraits(.isButton)
    }
}

// Custom button style to track press state smoothly
struct AACPressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

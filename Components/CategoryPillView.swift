//
//  CategoryPillView.swift
//  YAMParle
//

import SwiftUI

struct CategoryPillView: View {
    let category: AACCategory
    let isSelected: Bool
    let count: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? .white : category.color)

                Text(category.name)
                    .font(.system(.subheadline, design: .rounded, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? category.color : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white : Color.primary.opacity(0.08))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: isSelected ? category.color.opacity(0.3) : Color.clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(count) mots")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

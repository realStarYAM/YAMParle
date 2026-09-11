//
//  CategoryEditorView.swift
//  YAMParle
//

import SwiftUI
import SwiftData

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColorHex: String = "#1E73F2"

    private let availableIcons = [
        "folder.fill", "bubble.left.fill", "tag.fill", "star.fill",
        "heart.fill", "house.fill", "person.fill", "figure.walk",
        "cart.fill", "fork.knife", "pills.fill", "book.fill",
        "briefcase.fill", "globe.europe.africa.fill", "tv.fill", "gift.fill"
    ]

    private let paletteColors = [
        "#1E73F2", "#30D158", "#FF9F0A", "#40CBE0",
        "#FF375F", "#BF5AF2", "#5E5CE6", "#FFD60A",
        "#AC8E68", "#64D2FF", "#FF453A", "#8E8E93"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom de la catégorie") {
                    TextField("Ex: Musique, Émotions...", text: $name)
                        .font(.body)
                }

                Section("Couleur") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(paletteColors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 38)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    )
                                    .shadow(color: Color(hex: hex).opacity(selectedColorHex == hex ? 0.6 : 0.2), radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Icône") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 54, height: 54)
                                    .background(selectedIcon == icon ? Color(hex: selectedColorHex) : Color(UIColor.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Nouvelle catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveCategory()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func saveCategory() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newCategory = AACCategory(
            id: "cat_custom_\(UUID().uuidString.prefix(8))",
            name: trimmed,
            iconName: selectedIcon,
            colorHex: selectedColorHex,
            sortOrder: 100,
            isCustom: true,
            userProfileId: ProfileManager.shared.activeProfileId
        )
        modelContext.insert(newCategory)
        try? modelContext.save()
    }
}

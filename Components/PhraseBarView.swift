//
//  PhraseBarView.swift
//  YAMParle
//

import SwiftUI
import SwiftData

struct PhraseBarView: View {
    @Bindable var viewModel: AACViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Tokens scroll area (Current constructed phrase)
            HStack(alignment: .center, spacing: 10) {
                if viewModel.phraseTokens.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Appuyez sur des mots ou écrivez au clavier...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .accessibilityLabel("Zone de phrase vide. Touchez des pictogrammes ou le bouton Écrire pour composer un message.")
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.phraseTokens.enumerated()), id: \.element.id) { index, token in
                                    tokenCard(token: token, index: index)
                                        .id(token.id)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: viewModel.phraseTokens.count) { _, _ in
                            if let lastId = viewModel.phraseTokens.last?.id {
                                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                                    proxy.scrollTo(lastId, anchor: .trailing)
                                }
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 64)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            // Bottom row: Action controls
            HStack(spacing: 8) {
                // Speak Button (Main Hero action)
                Button {
                    viewModel.speakCurrentPhrase()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.speechService.isSpeaking ? "waveform.and.person.filled" : "speaker.wave.3.fill")
                            .font(.title3.weight(.bold))
                            .symbolEffect(.bounce, value: viewModel.speechService.isSpeaking)

                        Text("Parler")
                            .font(.body.weight(.bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(viewModel.phraseTokens.isEmpty ? Color.gray.opacity(0.5) : Color.yamAccent)
                    )
                    .shadow(color: viewModel.phraseTokens.isEmpty ? Color.clear : Color.yamAccent.opacity(0.35), radius: 4, y: 2)
                }
                .disabled(viewModel.phraseTokens.isEmpty)
                .accessibilityLabel("Parler")
                .accessibilityHint("Lit à voix haute toute la phrase construite")

                // Native Keyboard Input Switch ("⌨️ Écrire")
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        viewModel.currentAppMode = .writing
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.body.weight(.semibold))
                        Text("Écrire")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(Color.yamAccent)
                    .padding(.horizontal, 12)
                    .frame(height: 50)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Écrire au clavier")
                .accessibilityHint("Ouvre le mode écriture plein écran avec clavier natif")

                // Favorite current phrase
                Button {
                    viewModel.saveCurrentPhraseAsFavorite(context: modelContext)
                } label: {
                    Image(systemName: "star.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(viewModel.phraseTokens.isEmpty ? Color.secondary.opacity(0.5) : Color.yellow)
                        .frame(width: 48, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                }
                .disabled(viewModel.phraseTokens.isEmpty)
                .accessibilityLabel("Ajouter aux favoris")
                .accessibilityHint("Enregistre la phrase actuelle dans vos phrases favorites")

                // Backspace (Delete last word)
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        viewModel.removeLastToken()
                    }
                } label: {
                    Image(systemName: "delete.backward.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(viewModel.phraseTokens.isEmpty ? Color.secondary.opacity(0.5) : Color.primary)
                        .frame(width: 48, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                }
                .disabled(viewModel.phraseTokens.isEmpty)
                .accessibilityLabel("Effacer le dernier mot")
                .accessibilityHint("Retire le dernier élément de la phrase")

                // Clear All (Trash)
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        viewModel.clearPhrase()
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(viewModel.phraseTokens.isEmpty ? Color.secondary.opacity(0.5) : Color.red)
                        .frame(width: 48, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                }
                .disabled(viewModel.phraseTokens.isEmpty)
                .accessibilityLabel("Effacer toute la phrase")
                .accessibilityHint("Vide complètement la zone de phrase")
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(Color(UIColor.systemBackground))
    }

    @ViewBuilder
    private func tokenCard(token: PhraseToken, index: Int) -> some View {
        Button {
            viewModel.speakSingleWord(token.speechText)
        } label: {
            HStack(spacing: 6) {
                tokenThumbnail(token: token)

                Text(token.text)
                    .font(.body.weight(.bold))
                    .foregroundColor(.primary)

                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        viewModel.removeToken(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Supprimer \(token.text)")
            }
            .padding(.leading, 6)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(tokenBorderColor(token: token), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(token.text)")
        .accessibilityHint("Touchez pour prononcer ce mot individuellement")
    }

    @ViewBuilder
    private func tokenThumbnail(token: PhraseToken) -> some View {
        if let data = token.customImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else {
            Image(systemName: token.iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(tokenBgColor(token: token))
                .clipShape(Circle())
        }
    }

    private func tokenBgColor(token: PhraseToken) -> Color {
        if let hex = token.colorHex {
            return Color(hex: hex)
        }
        return Color.yamAccent
    }

    private func tokenBorderColor(token: PhraseToken) -> Color {
        if let hex = token.colorHex {
            return Color(hex: hex).opacity(0.4)
        }
        return Color.yamAccent.opacity(0.4)
    }
}

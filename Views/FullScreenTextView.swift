//
//  FullScreenTextView.swift
//  YAMParle
//

import SwiftUI

struct FullScreenTextView: View {
    @Environment(\.dismiss) private var dismiss
    let text: String
    let onSpeak: () -> Void

    @State private var isFaceToFace: Bool = false
    @State private var isPaperWhite: Bool = false
    @State private var copiedToClipboard: Bool = false
    @Bindable private var speechService = SpeechService.shared
    @Bindable private var themeManager = ThemeManager.shared

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        ZStack {
            // Background: Paper White or Pure Obsidian
            (isPaperWhite ? Color(hex: "#FAFAFC") : Color(hex: "#0A0A0E"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Minimalist Controls Bar
                HStack(spacing: 12) {
                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                            Text("Fermer")
                                .font(.system(size: 15, weight: .bold, design: theme.fontDesign))
                        }
                        .foregroundColor(isPaperWhite ? .black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isPaperWhite ? Color.black.opacity(0.08) : Color.white.opacity(0.14))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Fermer le plein écran")

                    Spacer()

                    // Face-to-Face 180° Rotation Toggle
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            isFaceToFace.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .bold))
                            Text(isFaceToFace ? "Vue normale" : "Face-à-face (180°)")
                                .font(.system(size: 13, weight: .bold, design: theme.fontDesign))
                        }
                        .foregroundColor(isFaceToFace ? .white : (isPaperWhite ? .black : .white))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isFaceToFace
                            ? theme.accentColor
                            : (isPaperWhite ? Color.black.opacity(0.08) : Color.white.opacity(0.14))
                        )
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Pivoter le texte à 180 degrés pour la personne en face")

                    // High contrast toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPaperWhite.toggle()
                        }
                    } label: {
                        Image(systemName: isPaperWhite ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isPaperWhite ? .black : .white)
                            .frame(width: 38, height: 38)
                            .background(isPaperWhite ? Color.black.opacity(0.08) : Color.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Inverser le contraste")

                    // Copy button
                    Button {
                        UIPasteboard.general.string = text
                        copiedToClipboard = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedToClipboard = false
                        }
                    } label: {
                        Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(copiedToClipboard ? Color(hex: "#30D158") : (isPaperWhite ? .black : .white))
                            .frame(width: 38, height: 38)
                            .background(isPaperWhite ? Color.black.opacity(0.08) : Color.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Copier le message")
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer()

                // Giant Readable Message Area
                ScrollView {
                    Text(text.isEmpty ? "..." : text)
                        .font(.system(size: 64, weight: .black, design: theme.fontDesign))
                        .foregroundColor(isPaperWhite ? Color(hex: "#101014") : Color(hex: "#F5F5FA"))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.35)
                        .lineSpacing(10)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                }
                .rotationEffect(.degrees(isFaceToFace ? 180 : 0))

                Spacer()

                // Bottom Hero Speak Button
                HStack {
                    Button(action: onSpeak) {
                        HStack(spacing: 12) {
                            if speechService.isSpeaking {
                                Image(systemName: "waveform")
                                    .font(.system(size: 24, weight: .black))
                                    .symbolEffect(.variableColor.iterative.reversing)
                            } else {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 24, weight: .bold))
                            }

                            Text(speechService.isSpeaking ? "Lecture en cours..." : "Lire à voix haute")
                                .font(.system(size: 20, weight: .bold, design: theme.fontDesign))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 420)
                        .frame(height: 64)
                        .background(theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: theme.accentColor.opacity(0.4), radius: 10, y: 4)
                    }
                    .buttonStyle(.yamPress)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    FullScreenTextView(text: "Bonjour ! Comment allez-vous aujourd'hui ?") { }
}

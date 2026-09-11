import SwiftUI

struct FullScreenTextView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String
    let onSpeak: () -> Void

    @State private var isFaceToFace = false
    @State private var isPaperWhite = false
    @State private var copied = false
    @Bindable private var speechService = SpeechService.shared
    @Bindable private var themeManager = ThemeManager.shared
    @ScaledMetric(relativeTo: .largeTitle) private var messageSize: CGFloat = 64
    private var theme: AppTheme { themeManager.currentTheme }

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? "Votre phrase apparaîtra ici." : text)
                .font(.system(size: messageSize, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(isPaperWhite ? Color.black : theme.primaryTextColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 300)
                .padding(24)
        }
        .rotationEffect(.degrees(isFaceToFace ? 180 : 0))
        .safeAreaInset(edge: .top) {
            HStack(spacing: YAMSpacing.large) {
                YAMActionButton(title: "Fermer", icon: "xmark", isFullWidth: false) { dismiss() }
                Spacer(minLength: 0)
                Menu {
                    Button(isFaceToFace ? "Vue normale" : "Face-à-face à 180 degrés", systemImage: "arrow.triangle.2.circlepath") {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { isFaceToFace.toggle() }
                    }
                    Button(isPaperWhite ? "Revenir au thème" : "Papier blanc", systemImage: "circle.lefthalf.filled") {
                        isPaperWhite.toggle()
                    }
                    Button(copied ? "Copié" : "Copier le message", systemImage: copied ? "checkmark" : "doc.on.doc") {
                        UIPasteboard.general.string = text
                        copied = true
                    }
                } label: {
                    YAMActionLabel(title: "Options d’affichage", icon: "ellipsis", theme: theme)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Options d’affichage et copie")
            }
            .padding(YAMSpacing.large)
            .background(theme.backgroundColor)
        }
        .safeAreaInset(edge: .bottom) {
            YAMActionButton(
                title: speechService.isSpeaking ? "Arrêter" : "Parler",
                icon: speechService.isSpeaking ? "stop.fill" : "speaker.wave.2.fill",
                variant: .hero(theme.accentColor), height: YAMLayout.heroHeight
            ) {
                if speechService.isSpeaking { speechService.stop() } else { onSpeak() }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !speechService.isSpeaking)
            .frame(maxWidth: 440)
            .padding(YAMSpacing.large)
            .frame(maxWidth: .infinity)
            .background(theme.backgroundColor)
        }
        .background(isPaperWhite ? Color.white : theme.backgroundColor)
    }
}

#Preview {
    FullScreenTextView(text: "Bonjour, je suis heureux de vous voir.") { }
}

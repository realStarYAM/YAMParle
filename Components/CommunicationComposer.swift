import SwiftUI

struct CommunicationComposer: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    let theme: AppTheme
    let compact: Bool
    let isSpeaking: Bool
    let canRestore: Bool
    let onSpeak: () -> Void
    let onClearOrRestore: () -> Void
    let onSave: () -> Void
    let onDeleteWord: () -> Void
    let onFullScreen: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title2) private var editorHeight: CGFloat = 96

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var actionColumns: [GridItem] {
        [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 220 : 140), spacing: 12)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Votre phrase")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if isSpeaking {
                    Label("Lecture en cours", systemImage: "waveform")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }

            if compact {
                editor
                speakButton
            } else {
                HStack(alignment: .center, spacing: 24) {
                    editor
                    speakButton.frame(width: 180)
                }
            }

            Rectangle().fill(theme.borderColor).frame(height: 1).accessibilityHidden(true)

            LazyVGrid(columns: actionColumns, spacing: 12) {
                YAMActionButton(
                    title: focus.wrappedValue ? "Masquer" : "Clavier",
                    icon: focus.wrappedValue ? "keyboard.chevron.compact.down" : "keyboard"
                ) { focus.wrappedValue.toggle() }
                .accessibilityLabel(focus.wrappedValue ? "Masquer le clavier" : "Afficher le clavier iOS")

                YAMActionButton(
                    title: isEmpty && canRestore ? "Rétablir" : "Effacer",
                    icon: isEmpty && canRestore ? "arrow.uturn.backward" : "delete.left"
                ) { onClearOrRestore() }
                .disabled(isEmpty && !canRestore)
                .accessibilityHint("Un texte effacé peut être rétabli tant que vous ne composez pas une nouvelle phrase.")

                YAMActionButton(title: "Enregistrer", icon: "bookmark") { onSave() }
                    .disabled(isEmpty)

                Menu {
                    Button(action: onDeleteWord) { Label("Effacer le dernier mot", systemImage: "delete.backward") }
                        .disabled(isEmpty)
                    Button(action: onFullScreen) { Label("Afficher en plein écran", systemImage: "arrow.up.left.and.arrow.down.right") }
                        .disabled(isEmpty)
                } label: {
                    YAMActionLabel(title: "Plus", icon: "ellipsis", theme: theme)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("Autres actions sur la phrase")
            }
        }
        .padding(20)
        .yamSurface(theme, selected: focus.wrappedValue)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(.title2, design: theme.fontDesign, weight: .medium))
                .foregroundStyle(theme.primaryTextColor)
                .tint(theme.accentColor)
                .scrollContentBackground(.hidden)
                .focused(focus)
                .accessibilityLabel("Votre phrase")
                .accessibilityHint("Écrivez au clavier ou ajoutez des phrases depuis les cartes.")
            if text.isEmpty {
                Text("Que souhaitez-vous dire ?")
                    .font(.system(.title2, design: theme.fontDesign, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
                    .padding(.horizontal, 5)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: editorHeight)
    }

    private var speakButton: some View {
        YAMActionButton(
            title: isSpeaking ? "Arrêter" : "Parler",
            icon: isSpeaking ? "stop.fill" : "speaker.wave.2.fill",
            variant: .hero(theme.accentColor),
            height: 72,
            action: onSpeak
        )
        .disabled(isEmpty && !isSpeaking)
        .accessibilityHint(isSpeaking ? "Arrête la lecture en cours." : "Lit votre phrase à voix haute.")
    }
}

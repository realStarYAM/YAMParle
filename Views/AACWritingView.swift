//
//  AACWritingView.swift
//  YAMParle
//

import SwiftUI
import SwiftData
import AudioToolbox

struct AACWritingView: View {
    @Bindable var viewModel: AACViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isInputFocused: Bool

    @State private var isFullScreen: Bool = false
    @State private var showingAlertFeedback: Bool = false

    // Quick phrases suggestions row
    private let suggestions = [
        "Bonjour",
        "Bonsoir",
        "Je vais bien",
        "Bonne nuit",
        "Bonne journée",
        "S'il vous plaît",
        "J'ai besoin d'aide",
        "À plus tard"
    ]

    var body: some View {
        VStack(spacing: 12) {
            // 1. TOP: Quick Response Buttons ("Oui", "Non", "Merci")
            topQuickResponseRow

            // 2 & 4. CENTER + RIGHT COLUMN
            HStack(alignment: .top, spacing: 12) {
                // LEFT: Center Text Area + Suggestions
                VStack(spacing: 12) {
                    // Center: High-contrast large text area
                    centerTextArea

                    // Under: Row of quick suggestions / phrases
                    suggestionsRow
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // RIGHT: Vertical action buttons column
                rightActionsColumn
                    .frame(width: 80)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(14)
        .background(Color(UIColor.systemGroupedBackground))
        .toolbar {
            // Native accessory toolbar above the system keyboard
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    viewModel.speakSingleWord(viewModel.writingText)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Parler")
                    }
                }
                .disabled(viewModel.writingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    addCurrentTextToYAMParlePhrase()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Ajouter")
                    }
                }
                .disabled(viewModel.writingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Button("Terminé") {
                    isInputFocused = false
                }
                .fontWeight(.bold)
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            fullScreenMessageView
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }

    // MARK: - 1. Top Quick Response Row ("Oui", "Non", "Merci")
    private var topQuickResponseRow: some View {
        HStack(spacing: 12) {
            // OUI
            Button {
                triggerQuickResponse("Oui")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2.weight(.bold))
                    Text("Oui")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#30D158"))
                )
                .shadow(color: Color(hex: "#30D158").opacity(0.35), radius: 4, y: 2)
            }
            .accessibilityLabel("Oui")
            .accessibilityHint("Prononce Oui immédiatement")

            // NON
            Button {
                triggerQuickResponse("Non")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2.weight(.bold))
                    Text("Non")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#FF453A"))
                )
                .shadow(color: Color(hex: "#FF453A").opacity(0.35), radius: 4, y: 2)
            }
            .accessibilityLabel("Non")
            .accessibilityHint("Prononce Non immédiatement")

            // MERCI
            Button {
                triggerQuickResponse("Merci")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.title2.weight(.bold))
                    Text("Merci")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#5E5CE6"))
                )
                .shadow(color: Color(hex: "#5E5CE6").opacity(0.35), radius: 4, y: 2)
            }
            .accessibilityLabel("Merci")
            .accessibilityHint("Prononce Merci immédiatement")
        }
    }

    // MARK: - 2. Center Text Area
    private var centerTextArea: some View {
        ZStack(alignment: .topLeading) {
            // High-contrast dark background box
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.11, green: 0.12, blue: 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(isInputFocused ? Color.yamAccent : Color.white.opacity(0.12), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)

            // Native TextEditor or multi-line TextField
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.writingText.isEmpty && !isInputFocused {
                    Text("Touchez ici pour écrire avec le clavier...")
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.45))
                        .padding(.top, 18)
                        .padding(.horizontal, 18)
                        .allowsHitTesting(false)
                }

                TextField("", text: $viewModel.writingText, axis: .vertical)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .tint(Color.yamAccent)
                    .focused($isInputFocused)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .padding(18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Zone de texte de saisie")
        .accessibilityHint("Touchez pour faire apparaître le clavier et saisir du texte")
    }

    // MARK: - 3. Suggestions Row
    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { item in
                    Button {
                        appendSuggestion(item)
                    } label: {
                        Text(item)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ajouter la suggestion: \(item)")
                }
            }
            .padding(.vertical, 2)
        }
        .frame(height: 52)
    }

    // MARK: - 4. Right Action Buttons Column
    private var rightActionsColumn: some View {
        VStack(spacing: 8) {
            // Parler (Hero action)
            actionButton(
                icon: viewModel.speechService.isSpeaking ? "waveform.and.person.filled" : "speaker.wave.3.fill",
                title: "Parler",
                backgroundColor: Color.yamAccent,
                foregroundColor: .white
            ) {
                speakText()
            }
            .accessibilityLabel("Parler")
            .accessibilityHint("Lit à voix haute le texte saisi")

            // Supprimer dernier mot
            actionButton(
                icon: "delete.backward.fill",
                title: "Mot",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: .primary
            ) {
                deleteLastWord()
            }
            .accessibilityLabel("Supprimer le dernier mot")

            // Effacer tout
            actionButton(
                icon: "trash.fill",
                title: "Effacer",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: .red
            ) {
                clearText()
            }
            .accessibilityLabel("Effacer tout le texte")

            // Alerte / Notification
            actionButton(
                icon: "bell.fill",
                title: "Alerte",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: .orange
            ) {
                triggerAlert()
            }
            .accessibilityLabel("Déclencher une alerte sonore pour attirer l'attention")

            // Plein écran / Focus
            actionButton(
                icon: "arrow.up.left.and.arrow.down.right",
                title: "Plein écran",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: .purple
            ) {
                isFullScreen = true
            }
            .accessibilityLabel("Afficher le texte en plein écran géant")

            // Ajouter à la phrase YAMParle
            actionButton(
                icon: "plus.circle.fill",
                title: "Ajouter",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: Color(hex: "#30D158")
            ) {
                addCurrentTextToYAMParlePhrase()
            }
            .accessibilityLabel("Ajouter le texte à la phrase YAMParle")

            // Clavier (Toggle Focus)
            actionButton(
                icon: isInputFocused ? "keyboard.chevron.compact.down.fill" : "keyboard.fill",
                title: "Clavier",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: isInputFocused ? Color.yamAccent : .secondary
            ) {
                isInputFocused.toggle()
            }
            .accessibilityLabel(isInputFocused ? "Fermer le clavier" : "Ouvrir le clavier")

            // Micro (Dictée)
            actionButton(
                icon: "mic.fill",
                title: "Micro",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: .secondary
            ) {
                isInputFocused = true
            }
            .accessibilityLabel("Activer le micro pour la dictée vocale")

            // Réglages
            actionButton(
                icon: "gearshape.fill",
                title: "Réglages",
                backgroundColor: Color(UIColor.secondarySystemGroupedBackground),
                foregroundColor: .secondary
            ) {
                viewModel.showingSettings = true
            }
            .accessibilityLabel("Ouvrir les réglages vocaux")
        }
    }

    // MARK: - Action Button Helper
    @ViewBuilder
    private func actionButton(
        icon: String,
        title: String,
        backgroundColor: Color,
        foregroundColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(foregroundColor)

                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(foregroundColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Full Screen Message Display
    private var fullScreenMessageView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isFullScreen = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }

                Spacer()

                Text(viewModel.writingText.isEmpty ? "..." : viewModel.writingText)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(32)

                Spacer()

                Button {
                    speakText()
                } label: {
                    Label("Lire à voix haute", systemImage: "speaker.wave.3.fill")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.yamAccent)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Logic Actions

    private func triggerQuickResponse(_ text: String) {
        viewModel.speechService.speak(text: text)
        appendSuggestion(text)
    }

    private func appendSuggestion(_ phrase: String) {
        let cleanCurrent = viewModel.writingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanCurrent.isEmpty {
            viewModel.writingText = phrase
        } else {
            viewModel.writingText = cleanCurrent + " " + phrase
        }
    }

    private func speakText() {
        let trimmed = viewModel.writingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.speechService.speak(text: trimmed)

        if viewModel.speechService.clearAfterSpeaking {
            viewModel.writingText = ""
        }
    }

    private func deleteLastWord() {
        var words = viewModel.writingText.split(separator: " ").map(String.init)
        if !words.isEmpty {
            words.removeLast()
            viewModel.writingText = words.joined(separator: " ")
            if !viewModel.writingText.isEmpty {
                viewModel.writingText += " "
            }
        } else {
            viewModel.writingText = ""
        }
    }

    private func clearText() {
        withAnimation(reduceMotion ? nil : .snappy) {
            viewModel.writingText = ""
        }
    }

    private func triggerAlert() {
        AudioServicesPlayAlertSound(SystemSoundID(1005))
        viewModel.speechService.speak(text: "Attention s'il vous plaît !")
    }

    private func addCurrentTextToYAMParlePhrase() {
        let trimmed = viewModel.writingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let token = PhraseToken(
            text: trimmed,
            speechText: trimmed,
            iconName: "keyboard",
            customImageData: nil,
            colorHex: "#1E73F2"
        )
        viewModel.phraseTokens.append(token)
        viewModel.alertMessage = "Texte ajouté à la phrase principale !"
        viewModel.showAlert = true
    }
}

#Preview {
    let vm = AACViewModel()
    vm.writingText = "Bonjour, je voudrais un verre d'eau s'il vous plaît."
    return AACWritingView(viewModel: vm)
}

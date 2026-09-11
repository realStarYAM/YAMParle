"""Contrôles statiques de la seconde passe de la refonte.

Les trois écrans conservés (nouvelle phrase, profils, parole et son) ont été remaniés
d’après les propositions de Docs/REFONTE-UI.md. Ces tests lisent les sources SwiftUI :
ils ne compilent rien et ne rendent rien. Ils verrouillent la structure annoncée dans le
document, pour qu’une retouche ultérieure ne remette pas les réglages rares au premier plan,
ne supprime pas la confirmation de changement de profil, ou ne fasse pas mentir l’aperçu.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EDITOR = (ROOT / 'Views/ItemEditorView.swift').read_text()
PROFILES = (ROOT / 'Views/UserProfilesView.swift').read_text()
VOICE = (ROOT / 'Views/SpeechAndSoundSettingsView.swift').read_text()
CATEGORIES = (ROOT / 'Views/CategoryEditorView.swift').read_text()
DESIGN = (ROOT / 'Components/YAMDesignSystem.swift').read_text()
MAIN = (ROOT / 'Views/MainAACView.swift').read_text()
SETTINGS = (ROOT / 'Views/SettingsView.swift').read_text()
SEED = (ROOT / 'Services/DataSeedService.swift').read_text()


def must(source, needle, where):
    """assertIn sans noyer la sortie dans un fichier de 20 Ko."""
    if needle not in source:
        raise AssertionError(f'{where} : « {needle} » attendu')


def must_not(source, needle, where):
    if needle in source:
        raise AssertionError(f'{where} : « {needle} » ne devrait plus apparaître')


def order_of(source, markers, where):
    positions = []
    for marker in markers:
        if marker not in source:
            raise AssertionError(f'{where} : section « {marker} » absente')
        positions.append(source.index(marker))
    if positions != sorted(positions):
        raise AssertionError(f'{where} : ordre annoncé par le document non respecté {markers}')


class ComposerEditorTests(unittest.TestCase):
    def test_three_levels_in_order(self):
        order_of(EDITOR, ('Text("Contenu")', 'Text("Apparence")', 'Text("Voix")'), 'Nouvelle phrase')

    def test_alternative_speech_and_engine_are_advanced(self):
        # Les deux réglages rares vivent dans la section repliée, pas au premier niveau.
        advanced = EDITOR[EDITOR.index('YAMAdvancedSection'):]
        must(advanced, 'Prononciation alternative', 'Nouvelle phrase · avancé')
        must(advanced, 'Moteur de cette carte', 'Nouvelle phrase · avancé')
        must(EDITOR, 'showAdvancedVoice', 'Nouvelle phrase')

    def test_collapsed_section_still_announces_active_settings(self):
        must(EDITOR, 'advancedSummary', 'Nouvelle phrase')
        must(EDITOR, 'Aucun réglage avancé sur cette carte.', 'Nouvelle phrase')
        # Une fiche déjà personnalisée s’ouvre sur son réglage, sans le cacher replié.
        must(EDITOR, 'showAdvancedVoice = item.audioSourceType != "apple"', 'Nouvelle phrase')

    def test_native_bar_keeps_cancel_and_save(self):
        must(EDITOR, 'ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }', 'Nouvelle phrase · barre native')
        must(EDITOR, 'Button("Enregistrer", action: saveItem)', 'Nouvelle phrase · barre native')

    def test_preview_is_the_real_card(self):
        must(EDITOR, 'YAMCardFace(', 'Nouvelle phrase · aperçu')
        must(EDITOR, '.frame(width: YAMLayout.gridCardMinWidth)', 'Nouvelle phrase · aperçu')
        must(EDITOR, '.yamSurface(theme)', 'Nouvelle phrase · aperçu')
        # Le badge de l’aperçu suit ce que la carte de l’accueil afficherait.
        face = DESIGN[DESIGN.index('struct YAMCardFace'):DESIGN.index('struct ModernAACCard')]
        must(face, 'audioBadgeTitle', 'YAMCardFace')
        must(DESIGN[DESIGN.index('struct ModernAACCard'):], 'YAMCardFace(', 'ModernAACCard')

    def test_save_failure_is_said_out_loud(self):
        must_not(EDITOR, 'try? modelContext.save()', 'Nouvelle phrase')
        must(EDITOR, 'try modelContext.save()', 'Nouvelle phrase')
        must(EDITOR, 'saveError =', 'Nouvelle phrase')
        must(EDITOR, 'modelContext.delete(item)', 'Nouvelle phrase')

    def test_choice_grids_are_shared_and_labelled(self):
        must(EDITOR, 'YAMIconChoiceGrid(selection: $selectedIcon, choices: iconChoices)', 'Nouvelle phrase · icônes')
        must(EDITOR, 'YAMSwatchGrid(selection: $selectedColorHex)', 'Nouvelle phrase · couleurs')
        titles = re.findall(r'YAMIconChoice\(symbol: "([^"]+)", title: "([^"]+)"\)', EDITOR)
        self.assertGreaterEqual(len(titles), 20)
        for symbol, title in titles:
            self.assertTrue(title.strip(), f'{symbol} sans nom')
        # Les formulaires de catégorie partagent les mêmes grilles.
        must(CATEGORIES, 'YAMIconChoiceGrid', 'Catégories')
        must(CATEGORIES, 'YAMSwatchGrid', 'Catégories')


class ProfileListTests(unittest.TestCase):
    def test_single_badge_for_default_profile(self):
        must(PROFILES, 'Text("Par défaut")', 'Profils')
        must_not(PROFILES, 'DÉFAUT', 'Profils · badge unique')
        must_not(PROFILES, 'ACTIF', 'Profils · pas de second badge')
        must(PROFILES, 'checkmark.circle.fill', 'Profils · coche')
        must(PROFILES, 'accessibilityLabel("Profil actif")', 'Profils · VoiceOver')

    def test_management_actions_are_separated(self):
        menu = PROFILES[PROFILES.index('private func rowMenu'):PROFILES.index('private func summary')]
        for action in ('Renommer', 'Dupliquer', 'Définir comme profil par défaut', 'Supprimer le profil'):
            self.assertIn(action, menu)
        must(menu, 'Button(role: .destructive)', 'Profils · menu')
        must(menu, 'Label("Dupliquer", systemImage: "doc.on.doc")', 'Profils · menu')
        must(menu, 'Divider()', 'Profils · suppression à l’écart')

    def test_switch_with_draft_needs_confirmation(self):
        must(PROFILES, 'var hasUnsavedDraft = false', 'Profils')
        must(PROFILES, 'requestActivation(of: profile)', 'Profils')
        must(PROFILES, '.yamProfileSwitchConfirmation(isPresented: activateBinding, onConfirm: confirmActivate)', 'Profils')
        # L’en-tête de l’accueil passe par la même question.
        must(MAIN, 'requestProfileSwitch(to: profile)', 'Accueil')
        must(MAIN, '.yamProfileSwitchConfirmation(isPresented: profileSwitchBinding, onConfirm: confirmProfileSwitch)', 'Accueil')
        must(PROFILES, 'if hasUnsavedDraft {', 'Profils · garde du brouillon')

    def test_draft_state_reaches_both_paths(self):
        must(MAIN, 'UserProfilesView(hasUnsavedDraft: hasUnsavedDraft, onClose: { sheet = nil })', 'Accueil · feuille profils')
        must(MAIN, 'SettingsView(hasUnsavedDraft: hasUnsavedDraft)', 'Accueil · réglages')
        must(SETTINGS, 'UserProfilesView(hasUnsavedDraft: hasUnsavedDraft)', 'Réglages · profils')
        must(SETTINGS, 'var hasUnsavedDraft = false', 'Réglages')

    def test_delete_is_guarded(self):
        must(PROFILES, 'profiles.count > 1', 'Profils · suppression')
        must(PROFILES, 'Cette action est irréversible.', 'Profils · suppression')
        must(PROFILES, 'Supprimer définitivement', 'Profils · suppression')

    def test_creation_does_not_write_data_from_the_view(self):
        must(PROFILES, 'DataSeedService.seedStarterCategories(for: newId, in: modelContext)', 'Profils · création')
        must_not(PROFILES, 'AACItem(', 'Profils · pas de données écrites depuis la vue')
        must(SEED, 'static func seedStarterCategories', 'DataSeedService')


class VoiceSettingsTests(unittest.TestCase):
    def test_everyday_sections_come_first(self):
        order_of(VOICE, ('Text("Voix principale")', 'Text("Essai")', 'Text("Rythme et volume")', 'Text("Comportement")'), 'Parole et son')

    def test_cloud_and_cache_are_advanced(self):
        advanced = VOICE[VOICE.index('YAMAdvancedSection'):]
        for marker in ('Clé API', 'Modèle IA', 'Préparer hors ligne', 'Aucun audio ElevenLabs en cache'):
            must(advanced, marker, 'Parole et son · section avancée')
        must(VOICE, '.onAppear { showAdvanced = usesElevenLabs }', 'Parole et son')

    def test_apple_voice_never_requires_an_account(self):
        must(VOICE, 'compte en ligne', 'Parole et son · en-tête')
        must(VOICE, 'sans clé ou en cas d’échec, YAMParle revient à la voix de l’appareil', 'Parole et son · secours')
        must(VOICE, 'aucune connexion nécessaire', 'Parole et son · essai')
        must(VOICE, 'Voix Apple utilisée', 'Parole et son · hors réseau')
        must(EDITOR, 'Aucune clé ElevenLabs n’est enregistrée', 'Nouvelle phrase · secours')

    def test_test_phrase_is_editable_and_stoppable(self):
        must(VOICE, 'TextField("Phrase d’essai"', 'Parole et son · essai')
        must(VOICE, 'speechService.isSpeaking', 'Parole et son · essai')
        must(VOICE, '"Arrêter"', 'Parole et son · essai')

    def test_rhythm_sliders_declare_their_scope(self):
        must(VOICE, 'Ces trois réglages s’appliquent aux voix Apple', 'Parole et son · portée des réglages')
        for label in ('Vitesse', 'Hauteur', 'Volume'):
            must(VOICE, f'title: "{label}"', 'Parole et son · rythme')

    def test_no_hardcoded_system_tones(self):
        for source, name in ((VOICE, 'Parole et son'), (PROFILES, 'Profils'), (EDITOR, 'Nouvelle phrase')):
            with self.subTest(view=name):
                must_not(source, 'Color(hex: "#FF3B30")', name)
                must_not(source, 'Color(hex: "#30D158")', name)
                must_not(source, '.foregroundColor(.green)', name)
        must(DESIGN, 'enum YAMTone', 'Design system')
        must(VOICE, 'YAMTone.destructive', 'Parole et son')


class SharedComponentsTests(unittest.TestCase):
    def test_semantic_variants_render_differently(self):
        button = DESIGN[DESIGN.index('struct YAMActionButton'):]
        for accessor in ('private var tone', 'private var iconForeground', 'carriesTone'):
            must(button, accessor, 'YAMActionButton')
        # Un fond teinté et une bordure, jamais un libellé seul en rouge.
        must(button, 'YAMTone.destructive.opacity', 'YAMActionButton · fond teinté')
        must(button, 'strokeBorder(tone.opacity', 'YAMActionButton · contour du ton')

    def test_shared_tokens_used_by_forms(self):
        for token in ('cardOptionsWidth', 'avatarSize', 'swatchColumnMinWidth', 'iconColumnMinWidth', 'recordingDotSize'):
            must(DESIGN, f'static let {token}: CGFloat', 'Design system · jetons')
        must(DESIGN, 'YAMLayout.cardOptionsWidth', 'Design system · carte')
        must(PROFILES, 'YAMLayout.cardOptionsWidth', 'Profils · menu ⋯')
        must(PROFILES, 'YAMLayout.avatarSize', 'Profils · avatar')

    def test_sheets_still_split_window_and_form(self):
        must(MAIN, 'case .settings, .profiles: return .window', 'Accueil · feuilles')
        must(MAIN, 'case .search, .newPhrase, .savePhrase, .newCategory, .edit: return .sheet', 'Accueil · feuilles')

    def test_no_stale_api_references(self):
        combined = DESIGN + EDITOR + PROFILES + VOICE + CATEGORIES + MAIN
        must_not(combined, 'showDeleteConfirmation', 'référence obsolète')
        must_not(combined, 'initialColorHex', 'référence obsolète')
        for match in re.finditer(r'\+ Section', combined):
            self.fail(f'accumulation invalide de sections près de {match.start()}')


if __name__ == '__main__':
    unittest.main(verbosity=2)

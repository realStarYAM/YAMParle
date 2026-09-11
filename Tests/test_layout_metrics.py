"""Contrôles statiques des dimensions compactes de l’interface iPad.

Ces tests lisent les sources SwiftUI : ils ne compilent pas et ne rendent pas
SwiftUI. Ils vérifient que la passe « compacte » reste cohérente et que les
planchers d’accessibilité (44 pt, Dynamic Type, VoiceOver) ne disparaissent pas.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESIGN = (ROOT / 'Components/YAMDesignSystem.swift').read_text()
COMPOSER = (ROOT / 'Components/CommunicationComposer.swift').read_text()
MAIN = (ROOT / 'Views/MainAACView.swift').read_text()
SETTINGS = (ROOT / 'Views/SettingsView.swift').read_text()

# Écrans conservés, repris à la seconde passe : mêmes règles de densité et d’accessibilité.
EDITOR = (ROOT / 'Views/ItemEditorView.swift').read_text()
PROFILES = (ROOT / 'Views/UserProfilesView.swift').read_text()
VOICE = (ROOT / 'Views/SpeechAndSoundSettingsView.swift').read_text()
CATEGORIES = (ROOT / 'Views/CategoryEditorView.swift').read_text()

CORE_FILES = {
    'Components/YAMDesignSystem.swift': DESIGN,
    'Components/CommunicationComposer.swift': COMPOSER,
    'Views/MainAACView.swift': MAIN,
    'Views/SettingsView.swift': SETTINGS,
}

SECOND_PASS_FILES = {
    'Views/ItemEditorView.swift': EDITOR,
    'Views/UserProfilesView.swift': PROFILES,
    'Views/SpeechAndSoundSettingsView.swift': VOICE,
    'Views/CategoryEditorView.swift': CATEGORIES,
}

SCANNED_FILES = {**CORE_FILES, **SECOND_PASS_FILES}


def _section_body(section):
    return re.search(rf'enum {section} \{{(.*?)\n\}}', DESIGN, re.S).group(1)


def token(name, source=DESIGN, section='YAMSpacing', _seen=()):
    body = _section_body(section)
    match = re.search(rf'static let {name}: CGFloat = ([\d.]+|((?:YAMSpacing|YAMLayout))\.(\w+))', body)
    if not match:
        raise AssertionError(f'Jeton {section}.{name} introuvable')
    value = match.group(1)
    if value[0].isdigit():
        return float(value)
    target = (match.group(2), match.group(3))  # ('YAMSpacing'|'YAMLayout', nom du jeton)
    if target in _seen:
        raise AssertionError(f'Référence circulaire pour {section}.{name}')
    return token(target[1], section=target[0], _seen=_seen + (target,))


def spacing(name):
    return token(name, section='YAMSpacing')


def layout(name):
    return token(name, section='YAMLayout')


class SpacingTests(unittest.TestCase):
    def test_rythme_is_compact_and_ordered(self):
        self.assertEqual(spacing('tiny'), 4)
        self.assertLess(spacing('small'), spacing('medium'))
        self.assertLess(spacing('medium'), spacing('large'))
        self.assertLess(spacing('large'), spacing('section'))
        self.assertLessEqual(spacing('section'), 18)

    def test_page_margins_are_reduced(self):
        self.assertLessEqual(spacing('page'), 20, 'marge large encore trop généreuse')
        self.assertLessEqual(spacing('pageCompact'), 14, 'marge compacte encore trop généreuse')
        self.assertLess(spacing('pageCompact'), spacing('page'))

    def test_touch_target_floor_is_preserved(self):
        self.assertGreaterEqual(spacing('minimumTarget'), 44, 'plancher tactile Apple : 44 pt')
        self.assertLessEqual(spacing('minimumTarget'), 48, 'au-delà, la redevient visuallement zoomée')
        self.assertGreaterEqual(layout('rowHeight'), 44)


class LayoutTests(unittest.TestCase):
    def test_cards_are_lower_than_before(self):
        self.assertGreaterEqual(layout('cardMinHeight'), 80, 'carte trop écrasée pour un pictogramme et un libellé')
        self.assertLessEqual(layout('cardMinHeight'), 110, 'hauteur de carte encore trop grande')
        self.assertLessEqual(layout('gridCardMinWidth'), 180, 'largeur de carte : plus petite = plus de cartes visibles')
        self.assertLessEqual(layout('gridSpacing'), 12)

    def test_composer_block_is_shorter(self):
        self.assertLessEqual(layout('composerEditorHeight'), 72)
        self.assertLessEqual(layout('composerPadding'), 16)

    def test_hero_button_stays_dominant_but_smaller(self):
        self.assertGreaterEqual(layout('heroHeight'), spacing('minimumTarget'), 'Parler reste une grande cible')
        self.assertLessEqual(layout('heroHeight'), 64, 'Parler ne doit plus être énorme')
        self.assertGreater(layout('heroHeight'), layout('controlHeight'))

    def test_category_column_is_narrower(self):
        self.assertLessEqual(layout('categorySidebarWidth'), 220)
        self.assertGreaterEqual(layout('categorySidebarWidth'), 180)

    def test_settings_window_width(self):
        for name in ('windowMaxWidth', 'windowContentWidth'):
            with self.subTest(token=name):
                self.assertGreaterEqual(layout(name), 700)
                self.assertLessEqual(layout(name), 780)


class PresentationTests(unittest.TestCase):
    def test_settings_sheet_uses_window_style(self):
        self.assertIn('case .settings, .profiles: return .window', MAIN)
        self.assertIn('.yamSheetPresentation(destination.sheetKind)', MAIN)
        self.assertIn('presentationSizing(.form)', DESIGN)
        self.assertIn('.presentationDetents([.medium, .large])', DESIGN)
        self.assertNotIn('.presentationDetents([.large])\n                    .presentationDragIndicator', MAIN)

    def test_editors_keep_full_sheet(self):
        self.assertIn('return .sheet', MAIN)
        self.assertIn('case .sheet:\n', DESIGN)


class AccessibilityTests(unittest.TestCase):
    def test_no_hard_coded_minimum_heights_in_core_files(self):
        for name, source in SCANNED_FILES.items():
            for match in re.finditer(r'minHeight:\s*(\d+)', source):
                self.fail(f'{name}: minHeight codé en dur ({match.group(1)}) au lieu d’un jeton')

    def test_fonts_still_scale_with_dynamic_type(self):
        for name, source in SCANNED_FILES.items():
            for match in re.finditer(r'\.font\(\.system\(size:\s*[\d.]+', source):
                self.fail(f'{name}: taille de police figée ({match.group(0)}) — Dynamic Type perdu')
        self.assertIn('@ScaledMetric', DESIGN)
        self.assertIn('@ScaledMetric', COMPOSER)
        self.assertIn('isAccessibilitySize', MAIN)

    def test_voiceover_labels_survive(self):
        combined = ''.join(SCANNED_FILES.values())
        minimums = {
            'accessibilityLabel': 12,
            'accessibilityHint': 5,
            'accessibilityAddTraits': 4,
            'accessibilityValue': 1,
            'accessibilityAction': 2,
        }
        for label, minimum in minimums.items():
            self.assertGreaterEqual(combined.count(label), minimum, f'{label} semble avoir disparu')

    def test_second_pass_files_stay_on_tokens(self):
        """La passe 2 ne réintroduit ni hauteur fixe ni couleur système codée en dur."""
        for name, source in SECOND_PASS_FILES.items():
            with self.subTest(view=name):
                self.assertIn('YAMSpacing', source, f'{name} ne suit plus le rythme partagé')
                for match in re.finditer(r'Color\(hex: "#[0-9A-Fa-f]{6}"\)', source):
                    self.fail(f'{name}: teinte figée {match.group(0)} hors des jetons du thème')


class SettingsRowTests(unittest.TestCase):
    def test_rows_are_compact_and_secondary_text_is_smaller(self):
        self.assertIn('.listSectionSpacing(.compact)', SETTINGS)
        self.assertIn('.frame(maxWidth: YAMLayout.windowContentWidth)', SETTINGS)
        self.assertIn('navigationBarTitleDisplayMode(.inline)', SETTINGS)
        row = re.search(r'func settingsRow.*?\n    \}', SETTINGS, re.S).group(0)
        self.assertIn('.font(.footnote)', row, 'texte secondaire à réduire')
        self.assertNotIn('.font(.title3', row)
        self.assertNotIn('.padding(.vertical, 8)', row)


if __name__ == '__main__':
    unittest.main(verbosity=2)

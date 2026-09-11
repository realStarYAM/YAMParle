"""Static palette checks; these do not render or compile SwiftUI."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "Models/AppTheme.swift").read_text()
THEMES = {
    name: dict(re.findall(r'(\w+):\s*"([^"]*)"', arguments))
    for name, arguments in re.findall(
        r'public static let (\w+) = make\((.*?)\n    \)', SOURCE, re.S
    )
}


def luminance(hex_color):
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in rgb]
    return sum(channel * weight for channel, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(a, b):
    bright, dark = sorted((luminance(a), luminance(b)), reverse=True)
    return (bright + 0.05) / (dark + 0.05)


class ThemeContrastTests(unittest.TestCase):
    def test_persisted_identifiers_are_preserved(self):
        self.assertEqual(
            {theme['id'] for theme in THEMES.values()},
            {'classic', 'dragon_ball', 'windows', 'macos', 'ubuntu', 'linux_mint', 'dragon'},
        )

    def test_factory_text_tokens(self):
        # Fail visibly if the factory changes, rather than checking stale constants.
        for declaration in (
            'primaryTextColor: adaptive("#202735", "#F4F5F8")',
            'secondaryTextColor: adaptive("#586174", "#B6BDCD")',
            'onAccentColor: adaptive("#FFFFFF", "#131925")',
        ):
            self.assertIn(declaration, SOURCE)

    def test_body_and_secondary_text_meet_aa(self):
        for name, theme in THEMES.items():
            for mode, text_colors, surfaces in (
                ('light', ('#202735', '#586174'), (theme['background'], theme.get('surface', '#FFFFFF'), theme['elevated'])),
                ('dark', ('#F4F5F8', '#B6BDCD'), (theme['darkBackground'], theme['darkSurface'], theme['darkElevated'])),
            ):
                for text in text_colors:
                    for surface in surfaces:
                        with self.subTest(theme=name, mode=mode, text=text, surface=surface):
                            self.assertGreaterEqual(contrast(text, surface), 4.5)

    def test_primary_action_labels_meet_aa(self):
        for name, theme in THEMES.items():
            for mode, text, background in (
                ('light', '#FFFFFF', theme['accent']),
                ('dark', '#131925', theme['darkAccent']),
            ):
                with self.subTest(theme=name, mode=mode):
                    self.assertGreaterEqual(contrast(text, background), 4.5)

    def test_accent_text_and_symbols_meet_aa(self):
        for name, theme in THEMES.items():
            for mode, accent, surfaces in (
                ('light', theme['accent'], (theme['background'], theme.get('surface', '#FFFFFF'), theme['elevated'])),
                ('dark', theme['darkAccent'], (theme['darkBackground'], theme['darkSurface'], theme['darkElevated'])),
            ):
                for surface in surfaces:
                    with self.subTest(theme=name, mode=mode, surface=surface):
                        self.assertGreaterEqual(contrast(accent, surface), 4.5)


if __name__ == '__main__':
    unittest.main(verbosity=2)

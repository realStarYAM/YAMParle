"""Static checks for the theme catalog (no rendering, no compilation).

- Catalog completeness (≥ 100 themes, expected categories, unique ids).
- Legacy fidelity: the seven original themes keep their exact colors.
- Accessible contrast (WCAG AA 4.5) in light AND dark mode for every theme:
  body/secondary text on background, surface and secondary surface;
  accent (icons, labels, selection) on the same surfaces;
  on-accent text on the accent (and on the secondary accent when the
  button style is a gradient); destructive text on the surfaces.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Models" / "Themes"

PAIR = r'\.p\("#([0-9A-Fa-f]{6})",\s*"#([0-9A-Fa-f]{6})"\)'


def luminance(hex_color):
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in rgb]
    return sum(channel * weight for channel, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(a, b):
    bright, dark = sorted((luminance(a), luminance(b)), reverse=True)
    return (bright + 0.05) / (dark + 0.05)


def parse_catalog():
    definitions = []
    for path in sorted(DATA_DIR.glob("*.swift")):
        for line in path.read_text().splitlines():
            stripped = line.strip()
            if not stripped.startswith("ThemeDefinition("):
                continue
            assert stripped.endswith(")") or stripped.endswith("),"), \
                "une définition par ligne, terminée par ): %s" % stripped[:80]
            if stripped.endswith("),"):
                stripped = stripped[:-1]
            inner = stripped[len("ThemeDefinition("):-1]
            match = re.match(
                r'"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*(\.\w+),\s*(.+)$', inner
            )
            assert match, "en-tête de définition inattendu: %s" % stripped[:80]
            theme_id, name, subtitle, icon, category, rest = match.groups()
            pairs = list(re.finditer(PAIR, rest))
            assert len(pairs) >= 4, "4 paires positionnelles attendues: %s" % theme_id
            positional = [('#' + a, '#' + b) for a, b in (m.groups() for m in pairs[:4])]
            keywords = rest[pairs[3].end():]
            entry = {
                'id': theme_id, 'name': name, 'subtitle': subtitle,
                'icon': icon, 'category': category,
                'accent': positional[0], 'secondaryAccent': positional[1],
                'background': positional[2], 'surface': positional[3],
            }
            for key in ('textPrimary', 'textSecondary', 'border', 'surfaceSecondary',
                        'selectedColor', 'destructiveColor', 'onAccent'):
                m = re.search(key + r':\s*' + PAIR, keywords)
                entry[key] = ('#' + m.group(1), '#' + m.group(2)) if m else None
            for key in ('cornerRadius', 'buttonCornerRadius', 'shadowOpacity', 'borderWidth',
                        'fontDesign', 'iconWeight', 'ornament', 'badgeName',
                        'buttonStyle', 'cardStyle'):
                m = re.search(key + r':\s*([\w.]+)', keywords)
                value = m.group(1) if m else None
                entry[key] = value[1:] if value and value.startswith('.') else value
            definitions.append(entry)
    return definitions


def parse_legacy():
    source = (ROOT / "Models" / "AppTheme.swift").read_text()
    return {
        name: dict(re.findall(r'(\w+):\s*"([^"]*)"', arguments))
        for name, arguments in re.findall(
            r'public static let (\w+) = make\((.*?)\n    \)', source, re.S
        )
    }


class ThemeCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = parse_catalog()
        cls.by_id = {theme['id']: theme for theme in cls.catalog}
        cls.legacy = parse_legacy()

    def test_catalog_is_large_and_unique(self):
        ids = [theme['id'] for theme in self.catalog]
        self.assertEqual(len(ids), len(set(ids)), "identifiants de thème en double")
        self.assertGreaterEqual(len(ids), 100)

    def test_categories_are_complete(self):
        counts = {}
        for theme in self.catalog:
            counts[theme['category']] = counts.get(theme['category'], 0) + 1
        self.assertEqual(counts.get('.essentials'), 3)
        self.assertEqual(counts.get('.windows'), 13)
        self.assertEqual(counts.get('.linux'), 19)
        # 18 générations + le thème macOS d'origine (Nacre).
        self.assertEqual(counts.get('.macos'), 19)
        self.assertEqual(counts.get('.anime'), 13)
        self.assertGreaterEqual(counts.get('.country'), 30)

    def test_every_definition_is_well_formed(self):
        styles_buttons = {'filled', 'tinted', 'outline', 'gradient', 'bevel'}
        styles_cards = {'solid', 'raised', 'flat', 'inset', 'bevel', 'glass', 'gradient'}
        ornaments = {'glow', 'line', 'orbit'}
        for theme in self.catalog:
            with self.subTest(theme=theme['id']):
                self.assertTrue(re.fullmatch(r'#[0-9A-Fa-f]{6}', theme['accent'][0]))
                for key in ('accent', 'secondaryAccent', 'background', 'surface'):
                    self.assertEqual(len(theme[key]), 2)
                self.assertIn(theme['buttonStyle'] or 'filled', styles_buttons)
                self.assertIn(theme['cardStyle'] or 'solid', styles_cards)
                self.assertIn(theme['ornament'] or 'glow', ornaments)

    def test_legacy_themes_keep_their_exact_colors(self):
        """Les sept thèmes d'origine : le catalogue ne doit pas dériver du rendu actuel."""
        expected_category = {
            'classic': '.essentials', 'dragon_ball': '.essentials', 'dragon': '.essentials',
            'windows': '.windows', 'macos': '.macos', 'ubuntu': '.linux', 'linux_mint': '.linux',
        }
        for name, args in self.legacy.items():
            theme = self.by_id.get(args.get('id', name))
            with self.subTest(theme=name):
                self.assertIsNotNone(theme, "thème d'origine absent du catalogue")
                self.assertEqual(theme['category'], expected_category[args['id']])
                self.assertEqual(theme['accent'], (args['accent'], args['darkAccent']))
                self.assertEqual(theme['background'], (args['background'], args['darkBackground']))
                self.assertEqual(theme['surface'], (args.get('surface', '#FFFFFF'), args['darkSurface']))
                self.assertEqual(theme['surfaceSecondary'], (args['elevated'], args['darkElevated']))

    def _resolve(self, theme, key, default):
        return theme[key] or default

    def test_accessible_contrast_in_both_modes(self):
        for theme in self.catalog:
            text_primary = self._resolve(theme, 'textPrimary', ('#202735', '#F4F5F8'))
            text_secondary = self._resolve(theme, 'textSecondary', ('#586174', '#B6BDCD'))
            on_accent = theme['onAccent'] or (
                '#101418' if luminance(theme['accent'][0]) > 0.2 else '#FFFFFF',
                '#101418' if luminance(theme['accent'][1]) > 0.2 else '#FFFFFF',
            )
            destructive = self._resolve(theme, 'destructiveColor', ('#A62C22', '#FF9A90'))
            problems = []
            for i, mode in ((0, 'light'), (1, 'dark')):
                surfaces = (theme['background'][i], theme['surface'][i],
                            self._resolve(theme, 'surfaceSecondary', theme['background'])[i])
                for label, text in (('textPrincipal', text_primary), ('texteSecondaire', text_secondary)):
                    for surface in surfaces:
                        if contrast(text[i], surface) < 4.5:
                            problems.append("%s %s/%s %.2f" % (label, text[i], surface, contrast(text[i], surface)))
                for surface in surfaces:
                    if contrast(theme['accent'][i], surface) < 4.5:
                        problems.append("accent %s/%s %.2f" % (theme['accent'][i], surface, contrast(theme['accent'][i], surface)))
                    if contrast(destructive[i], surface) < 4.5:
                        problems.append("destructif %s/%s %.2f" % (destructive[i], surface, contrast(destructive[i], surface)))
                if contrast(on_accent[i], theme['accent'][i]) < 4.5:
                    problems.append("texteSurAccent %s/%s %.2f" % (on_accent[i], theme['accent'][i], contrast(on_accent[i], theme['accent'][i])))
                if theme['buttonStyle'] == 'gradient' and contrast(on_accent[i], theme['secondaryAccent'][i]) < 4.5:
                    problems.append("texteSurDegradé %s/%s %.2f" % (on_accent[i], theme['secondaryAccent'][i], contrast(on_accent[i], theme['secondaryAccent'][i])))
            with self.subTest(theme=theme['id']):
                self.assertEqual(problems, [], "contraste insuffisant :\n  " + "\n  ".join(problems))


if __name__ == '__main__':
    unittest.main(verbosity=2)

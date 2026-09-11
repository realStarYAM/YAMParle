"""Grammar-only check of the redesigned UI and supporting code.

Requires tree-sitter==0.26.0 and tree-sitter-swift==0.7.3.
Not xcodebuild: types, frameworks and macros are NOT checked.
The parser rejects `if let x = try? await …`, so photo loading is written in two
steps in the forms; ElevenLabsService still uses a construct the parser rejects
and stays outside this check.
"""
from pathlib import Path
import sys
from tree_sitter import Language, Parser
import tree_sitter_swift

root = Path(__file__).resolve().parents[1]
parser = Parser(Language(tree_sitter_swift.language()))
files = [root / path for path in (
    'Components/YAMDesignSystem.swift', 'Components/CommunicationComposer.swift',
    'ContentView.swift', 'Models/AppTheme.swift', 'Models/ThemeDefinition.swift',
    'Models/Themes/ThemeDataEssentials.swift', 'Models/Themes/ThemeDataWindows.swift',
    'Models/Themes/ThemeDataLinux.swift', 'Models/Themes/ThemeDataMacOS.swift',
    'Models/Themes/ThemeDataAnime.swift', 'Models/Themes/ThemeDataPays.swift',
    'Services/ThemeManager.swift', 'Services/ThemeRegistry.swift',
    'Services/SpeechService.swift', 'Services/AudioRecorderService.swift',
    'Services/DataSeedService.swift', 'Views/MainAACView.swift',
    'Views/SettingsView.swift', 'Views/ThemeSelectionView.swift',
    'Views/ThemeGalleryView.swift',
    'Views/SearchView.swift', 'Views/CategoryEditorView.swift', 'Views/FullScreenTextView.swift',
    'Views/ItemEditorView.swift', 'Views/UserProfilesView.swift',
    'Views/SpeechAndSoundSettingsView.swift',
)]
errors = []
for path in files:
    source = path.read_bytes()
    tree = parser.parse(source)
    if tree.root_node.has_error:
        pending = [tree.root_node]
        while pending:
            node = pending.pop()
            if node.type == 'ERROR' or node.is_missing:
                line = source[:node.start_byte].count(b'\n') + 1
                errors.append(f'{path.relative_to(root)}:{line}: {node.type}: {source[node.start_byte:node.end_byte][:100]!r}')
            pending.extend(reversed(node.children))
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'{len(files)} scoped Swift files parsed without grammar errors. Types and SDK APIs NOT checked.')

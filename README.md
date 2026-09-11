# YAMParle

Application de communication alternative et améliorée (CAA/AAC) pour iPad, en SwiftUI avec SwiftData.

## Refonte de l’interface

- [Proposition complète, écran par écran et design system](Docs/REFONTE-UI.md)
- [Contrôle de densité iPad Pro 11″](Docs/apercu-compact.html) : avant / après, paysage et portrait, à l’échelle 1 px = 1 pt. Maquette de vérification des proportions, pas l’app iOS.
- [Maquette web de référence avec sept thèmes et modes clair/sombre](Docs/apercu-interface.html) : télécharger le fichier puis l’ouvrir dans un navigateur. Ce n’est pas l’application iOS.
- [Écran principal SwiftUI](Views/MainAACView.swift)
- [Composants réutilisables et jetons](Components/YAMDesignSystem.swift), dont la carte partagée `YAMCardFace`
- [Compositeur avec clavier iOS natif](Components/CommunicationComposer.swift)
- [Checklist iPad et contrôles statiques](Tests/VALIDATION.md), dont les sections « Densité iPad · passe compacte » et « Seconde passe · formulaires, profils, voix »
- [Protocole d’intégration dans l’app iOS existante](#intégration-dans-xcode)

La **passe 2** reprend les trois écrans que la première livraison avait laissés en l’état : `ItemEditorView` en trois sections avec un aperçu dessiné par la carte réelle, `UserProfilesView` en liste lisible avec confirmation avant changement de profil, `SpeechAndSoundSettingsView` ordonné par besoin (voix principale, essai, rythme, comportement, puis section avancée ElevenLabs et cache).

## Intégration dans Xcode

Ce dépôt contient les sources, mais **aucun projet `.xcodeproj` ou workspace**. Il n’est donc pas directement compilable par une commande `xcodebuild` depuis ce checkout.

1. Utiliser le projet iOS existant, ou créer une application iOS SwiftUI dans Xcode 15 ou ultérieur, avec une cible iPadOS/iOS **17 minimum**. SwiftData et Observation sont requis.
2. Ajouter les sources de `Models`, `Services`, `ViewModels`, `Components`, `Views`, `ContentView.swift`, `YAMParleApp.swift` et les ressources `Assets.xcassets` à la cible de l’application. Les formulaires repris (`ItemEditorView`, `UserProfilesView`, `SpeechAndSoundSettingsView`, `CategoryEditorView`) sont désormais dans le périmètre de la refonte et doivent rester compilés avec le socle commun.
3. Conserver **un seul point d’entrée `@main`** : `YAMParleApp`. Si Xcode a généré une autre structure `App`, la retirer de la cible plutôt que créer un doublon. Ne pas importer les fichiers de `Docs` ou `Tests` dans les sources compilées de l’app.
4. Pour l’enregistrement audio, fournir `NSMicrophoneUsageDescription` dans la configuration de la cible. Tester l’autorisation refusée et accordée. L’application ne doit pas exiger ElevenLabs pour les voix Apple.
5. Compiler sur simulateur iPad, ouvrir les previews de `MainAACView` puis tester sur iPad réel. La sélection d’apparence sauvegardée peut forcer le rendu de preview ; choisir Système pour suivre le mode d’environnement.
6. Avant tout test sur des données importantes, sauvegarder le conteneur existant. Le mécanisme de récupération de magasin dans `YAMParleApp.swift` est préexistant et potentiellement destructif en cas d’erreur d’ouverture. Il n’est pas remplacé par cette refonte.

Les modèles SwiftData et leurs identifiants de thèmes restent inchangés ; aucun schéma ni migration de données supplémentaire n’est introduit.

## Contrôles exécutables sans Xcode

Contrastes des palettes, dimensions de la passe compacte et structure de la passe 2 :

```sh
python3 -m unittest discover -s Tests -p 'test_*.py' -v
```

Vérification optionnelle de grammaire sur les fichiers ciblés :

```sh
python3 -m venv .venv
.venv/bin/pip install tree-sitter==0.26.0 tree-sitter-swift==0.7.3
.venv/bin/python Tests/check_swift_syntax.py
```

Ces contrôles ne compilent pas SwiftUI et ne vérifient pas les API du SDK, les macros, le comportement audio, SwiftData ni l’accessibilité sur appareil. Ils ne remplacent pas les tests Xcode et iPad.

Deux conventions d’écriture méritent d’être connues avant d’intervenir dans les formulaires :

- `if let x = try? await …` est **rejeté par l’analyseur de grammaire** utilisé par les contrôles statiques (pas par Swift ni par SwiftUI). Les formulaires chargent donc la photo sélectionnée en deux temps, ce qui évite au passage d’effacer une photo déjà choisie quand le transfert échoue.
- Chaque section de formulaire vit dans sa propre sous-vue `@ViewBuilder`. C’est la forme que SwiftUI attend pour que les sections restent des sections dans une `Form` ou une `List`, et cela garde chaque écran lisible.

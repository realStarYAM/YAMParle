# YAMParle · Refonte iPad

## Direction proposée

**La communication au premier plan.** Une interface calme, adulte et lumineuse, avec un accent iris, des surfaces opaques légèrement teintées, des cartes généreuses et un seul bouton dominant : **Parler**. Le caractère futuriste vient des volumes, du dessin des icônes et des nuances, pas d’effets lumineux derrière le texte.

Le thème change l’ambiance, jamais la place des actions. Cette stabilité protège la mémoire motrice. Aucun tri automatique des phrases selon la fréquence, aucune animation de réorganisation, aucun décor animé.

![Direction claire, maquette web illustrative](apercu-clair.png)

> Les illustrations et [l’aperçu interactif](apercu-interface.html) sont des maquettes web de référence, pas des captures du code SwiftUI exécuté. Elles permettent de comparer les sept univers et les modes clair/sombre. Seules la sélection du thème, l’apparence, la composition et l’annulation sont interactives dans cette maquette. Les pictogrammes web sont illustratifs ; l’application utilise SF Symbols.

## 1. Hiérarchie de l’écran principal

```text
YAMParle · À votre rythme         Profil actif   Rechercher   Réglages
┌──────────────────────────────────────────────────────────────────┐
│ Votre phrase                                                     │
│ Texte libre / clavier iOS natif                       [ PARLER ]  │
│                                                                  │
│ [ Clavier ]  [ Effacer / Rétablir ]  [ Enregistrer ]  [ Plus ]    │
└──────────────────────────────────────────────────────────────────┘
┌───────────────────┐  Conversation                      [ Ajouter ]
│ Catégories        │  Touchez une carte pour composer votre phrase.
│ ✓ Conversation    │  ┌────────────┐ ┌────────────┐ ┌────────────┐
│   Émotions        │  │ Icône   ⋯  │ │ Icône   ⋯  │ │ Icône   ⋯  │
│   Repas           │  │ Bonjour    │ │ Bonsoir    │ │ Merci      │
│   …               │  └────────────┘ └────────────┘ └────────────┘
│ Nouvelle catégorie│  Autres phrases…
└───────────────────┘
```

1. **Message et Parler** : premier niveau, toujours associés visuellement.
2. **Composition** : clavier, effacement réversible, enregistrement.
3. **Choix des phrases** : catégories puis grille, lecture de gauche à droite.
4. **Gestion** : Ajouter, options de carte et Réglages, moins dominants.
5. **Personnalisation** : profil et thème, en dehors du trajet habituel pour parler.

Les fonctions secondaires ne sont pas supprimées : dernier mot et plein écran sont dans **Plus** ; nouvelle phrase et nouvelle catégorie dans **Ajouter**. L’enregistrement de la phrase courante reste directement accessible.

### Adaptation à la fenêtre

- À partir de **960 pt** de largeur, hors tailles de texte d’accessibilité : panneau des catégories de **208 pt**, grille adaptative à droite, défilements séparés des catégories et des phrases.
- En fenêtre étroite, portrait ou Split View : page verticale défilante, catégories horizontales. Une largeur régulière ne signifie pas « paysage ».
- Sous **700 pt**, le bouton Parler passe sous le texte. En Dynamic Type d’accessibilité, la grille passe à une colonne et les catégories se choisissent dans une liste dépliable.
- L’ouverture du clavier ne change pas la branche de disposition selon la hauteur. En disposition large, l’en-tête de navigation s’efface pendant la saisie pour libérer de la place, sans remplacer le compositeur. La barre native du clavier garde Parler/Arrêter et Masquer le clavier.
- Sur fenêtre compacte, la page entière peut défiler : la barre du clavier conserve l’action Parler pendant la saisie. Il reste à vérifier les très petites hauteurs avec Stage Manager.

## 2. Écran par écran

### A. Communiquer · implémenté

**En-tête.** Identité discrète, profil avec avatar, recherche et réglages explicitement libellés. Pas de rangée de petites icônes ambiguës de 36 pt.

**Compositeur.** `TextEditor` natif, texte lisible, curseur iOS, sélection/correction/collage système. L’espace réservé « Que souhaitez-vous dire ? » ne reçoit pas les interactions et n’est pas lu une deuxième fois par VoiceOver.

**Parler.** Accent plein, hauteur minimale 56 pt — dominante, mais plus énorme que le reste des commandes. Désactivé pour un message vide. Devient **Arrêter** pendant la lecture, y compris pendant une génération ElevenLabs en attente. Il ne change pas d’emplacement.

**Effacer.** Effacement immédiat, sans confirmation gênant la communication ; le même bouton devient **Rétablir**. Une nouvelle composition invalide ce rétablissement. Ce n’est pas un historique multi-niveaux.

**Carte.** Symbole ou photo, texte en `.title3`, options visibles `⋯`. Pas de réduction automatique de la taille du texte. Une phrase longue agrandit sa carte. Le toucher ajoute `item.text`, jamais l’étiquette abrégée. Si « parler au toucher » est activé, il lit aussi l’élément via son moteur/audio propre.

**Actions de carte.** Lire sans ajouter et modifier, dans un menu explicite et en actions VoiceOver. Pas de geste long obligatoire pour découvrir la modification.

**États vides.** Une catégorie vide propose Ajouter une phrase ; un profil sans catégorie propose Créer une catégorie. Aucune substitution silencieuse par les phrases d’un autre profil.

### B. Rechercher · implémenté

Feuille native avec recherche système, mêmes cartes que l’accueil, filtrage du texte, de l’étiquette et du texte prononcé. Recherche insensible à la casse et aux accents. Une carte ajoute le texte puis ferme la recherche ; la lecture seule passe par son menu. La modification attend la fermeture de la recherche avant d’ouvrir l’éditeur, pour éviter deux feuilles concurrentes.

État sans résultat avec la requête, bouton Fermer toujours disponible. La recherche ne change ni l’ordre enregistré ni la catégorie choisie à l’accueil.

### C. Nouvelle phrase / Modifier · remanié (passe 2)

`ItemEditorView` suit l’ordre annoncé : trois sections **« Contenu »** (texte complet, étiquette facultative, catégorie, position), **« Apparence »** (aperçu, photo, icône, couleur) puis **« Voix »** (résumé de la voix choisie et écoute immédiate). Annuler et Enregistrer restent dans la barre native.

- **L’aperçu est la carte elle-même**, dessinée par `YAMCardFace` — le même composant que `ModernAACCard` sur l’accueil et dans la recherche. Le badge « Voix enregistrée » / « Voix IA » n’apparaît dans l’aperçu que là où il apparaîtrait sur la carte, et une phrase longue agrandit l’aperçu comme elle agrandirait la carte. Un écart entre les deux n’est pas un détail cosmétique : c’est l’outil qui ment sur son résultat.
- Quand le texte prononcé diffère de l’affiche, une ligne sous l’aperçu le dit explicitement, au lieu de le laisser deviner.
- **Le texte prononcé alternatif et le moteur individuel** vivent dans `YAMAdvancedSection` « Voix personnalisée pour cette carte », repliée par défaut. Son résumé indique ce qui est actif, et une fiche déjà personnalisée s’ouvre développée : replier ne doit pas masquer.
- Icônes et couleurs sont proposées par les grilles partagées `YAMIconChoiceGrid` et `YAMSwatchGrid` : cible de 44 pt, nom de chaque symbole et de chaque teinte lu par VoiceOver, sélection marquée par une coche et un état `.isSelected` (formulaires de phrase et de catégorie identiques).
- **Les erreurs de sauvegarde sont dites.** L’enregistrement passe par `try modelContext.save()` ; en cas d’échec, la fiche reste ouverte, un message s’affiche, et l’écriture est annulée (nouvelle carte retirée, modification restaurée). Le `try? modelContext.save()` silencieux a disparu de ce formulaire.
- L’enregistrement depuis le compositeur préremplit toujours le texte et la catégorie active.

Ces choix ne sont pas des gains de place pour la place : la section avancée rassemble ce dont on n’a pas besoin à chaque phrase, et rien de ce qui existait n’a été supprimé.

### D. Catégories · implémenté

Accès depuis Réglages → Communication. Liste des catégories du seul profil actif. Création et modification du nom, du symbole et de la couleur. Un aperçu présente les choix ; chaque symbole et couleur a un libellé d’accessibilité.

Renommer garde l’identifiant et les phrases rattachées. Les erreurs de sauvegarde restent visibles dans la feuille. La suppression et le réordonnancement ne sont pas ajoutés ici : ils demandent une confirmation adaptée et une stratégie explicite pour les phrases rattachées.

### E. Réglages · implémenté

La fenêtre s’ouvre en **carte centrée**, plus en feuille plein écran : `presentationSizing(.form)` sur iPadOS 18 et plus, contenu porté à 744 pt de large au maximum et centré, titre `.inline`, sections en rythme compact. Sur iPadOS 17, où les detents sont ignorées en largeur régulière, la largeur du contenu reste bornée à 744 pt et la feuille occupe la hauteur disponible. Les formulaires (nouvelle phrase, catégorie, recherche) gardent la feuille entière.

Cinq groupes, sans fausse fonction de sauvegarde :

1. **Votre espace** : profil actif, statut par défaut, gestion des utilisateurs.
2. **Apparence** : thème et choix Système/Clair/Sombre.
3. **Communication** : parole et son, catégories.
4. **Confort d’utilisation** : contraste renforcé, retour haptique si disponible, taille des cartes.
5. **À propos et données** : version réellement fournie par le bundle et stockage local.

Les réglages de confort concernent l’appareil ; le thème concerne le profil. Le faux bouton « Sauvegarder ce profil » de l’ancien écran, qui n’effectuait pas d’export, n’est pas repris. Le bouton de restauration qui réappelait simplement l’initialiseur n’est pas repris non plus. Aucun nouveau service d’export n’est annoncé.

### F. Thèmes et apparence · implémenté

Galerie de sept cartes avec miniature de la disposition, nom, description et indicateur de sélection. Une pression applique le thème au profil actif. La sélection repose sur une coche et un libellé, pas seulement sur la couleur.

Système suit le réglage iPadOS ; Clair et Sombre le forcent. L’apparence est globale à l’appareil, indépendante de l’identifiant de thème sauvegardé dans chaque profil. En cas d’échec de la sauvegarde SwiftData, la galerie l’indique sans prétendre que le profil est enregistré.

### G. Profils · remanié (passe 2)

Accès par le profil de l’en-tête ou par Réglages. La liste est redevenue une liste : avatar, nom, ligne de contexte (thème et voix), et **un seul badge — « Par défaut »**. Le profil actif ne porte pas une étiquette de plus, il porte une coche, annoncée à VoiceOver par `accessibilityLabel("Profil actif")`. Deux badges empilés disaient presque la même chose ; la place était mieux employée à lire un nom long.

- **Actions de gestion séparées du geste courant :** « Utiliser » est le bouton de la ligne, tandis que renommer, dupliquer, définir par défaut et supprimer sont regroupés dans un menu `⋯` par profil, avec la suppression isolée par un séparateur et son rôle destructeur. Les quatre puces alignées sous chaque ligne, qui réduisaient chaque profil à un bloc de boutons, ont disparu.
- **Confirmation avant changement de profil quand une phrase est en cours.** L’appelant transmet `hasUnsavedDraft` ; la demande passe par `requestActivation`, et `yamProfileSwitchConfirmation` pose la même question dans la liste et dans le menu d’en-tête — un seul texte partagé, deux chemins, une seule promesse. Sans brouillon, le changement reste immédiat : on ne punit pas l’usage normal.
- La suppression exige une confirmation distincte, nomme le profil concerné et n’est proposée que s’il en reste au moins un.
- **La création d’un profil n’écrit plus de données depuis la vue.** Le catalogue de départ (quatre catégories, phrases du premier jour) est fourni par `DataSeedService.seedStarterCategories(for:in:)`, et l’échec de sauvegarde est affiché au lieu d’être avalé.
- Changer de profil continue d’arrêter la lecture, de retirer le brouillon de l’ancien profil et de réévaluer la catégorie sélectionnée. Les avatars, la création et la duplication existants sont conservés.

### H. Parole et son · remanié (passe 2)

`SpeechAndSoundSettingsView` suit l’ordre des besoins : **« Voix principale »** (moteur et voix française), **« Essai »** (phrase modifiable, écoute, arrêt), **« Rythme et volume »** (vitesse, hauteur, volume), **« Comportement »** (lire au toucher, effacer après lecture), puis **`YAMAdvancedSection` « Voix IA, préchargement et cache »** — clé API, voix et modèle ElevenLabs, préparation hors ligne et fichiers en cache. La section avancée s’ouvre seule si le moteur IA est déjà actif, et son résumé dit s’il y a une clé et combien d’audios sont en cache.

- **Rien n’oblige à un compte cloud.** Les voix Apple restent le chemin par défaut, le secours hors ligne est écrit dans l’écran, et le test de la voix IA désactivé explique qu’aucune clé n’est enregistrée plutôt que de laisser un bouton muet.
- Le test d’essai partage une seule phrase éditable pour les deux moteurs, avec un bouton qui devient Arrêter pendant la lecture.
- Le libellé « Rythme et volume » annonce sa portée : ces trois réglages s’appliquent aux voix Apple, donc aussi au secours automatique ; un audio IA téléchargé garde le rythme de sa génération. L’ancien écran laissait croire au contraire.
- Les couleurs système codées en dur (`#30D158`, `#FF3B30`, `.green`) sont remplacées par `YAMTone`, qui colore icône, fond teinté et contour, jamais un libellé seul.
- À la sortie, les préférences prises en charge par `ProfileManager` sont enregistrées dans le profil actif (comportement inchangé, déjà en place).

Pour le bouton Arrêter, la fin des lectures enregistrées/ElevenLabs et l’interruption entre moteurs avaient été corrigées : une réponse réseau tardive peut alimenter le cache mais ne relance plus une lecture interrompue. Les préécoutes des autres éditeurs qui appellent directement les services restent à tester séparément.

### I. Plein écran / Face-à-face · implémenté

Message agrandi et défilant, avec Fermer en haut et Parler/Arrêter fixé en bas, même pour un message long. Le menu offre rotation à 180°, papier blanc et copie. Seule la zone du message pivote ; les commandes restent orientées vers l’utilisateur. La rotation animée est supprimée avec Réduire les animations.

## 3. Design system

### Palette sémantique · Classique Iris

| Rôle | Clair | Sombre |
|---|---|---|
| Fond | `#F4F5FA` | `#141722` |
| Surface principale | `#FFFFFF` | `#202431` |
| Surface secondaire | `#ECECF7` | `#2C3042` |
| Accent interactif | `#5551C9` | `#B7B4FF` |
| Texte sur accent | `#FFFFFF` | `#131925` |
| Texte principal | `#202735` | `#F4F5F8` |
| Texte secondaire | `#586174` | `#B6BDCD` |
| Bordure | `#D9DEE8` | `#414958` |

Les couleurs utilisent des fournisseurs `UIColor` adaptatifs : elles réagissent au mode système même lorsque le thème reste identique. Le texte sur accent n’est **pas systématiquement blanc**, notamment en mode sombre. Les palettes de texte et de boutons sont testées numériquement à **4,5:1 minimum** sur leurs fonds opaques. Cela ne constitue pas une validation d’accessibilité de toute l’application, des photos ou de tous les mélanges transparents.

### Typographie

- Police système, donc SF sur iPad ; design `.default` ou `.rounded` selon le thème.
- Identité et titre de catégorie : `.title3`, gras.
- Message : `.title2`, medium, adaptable à Dynamic Type.
- Texte de carte : `.body`, semibold ; pas de limite arbitraire à deux lignes.
- Commandes et catégories : `.callout`, medium/semibold ; Parler garde `.body`.
- Aide et libellés de section : `.footnote` ; métadonnées secondaires : `.caption2`.
- Plein écran : base 64 pt avec `@ScaledMetric` ; le texte défile, il n’est pas réduit pour rentrer.
- Pas de police décorative fantasy dans les phrases, y compris avec Dragon.

### Géométrie et rythme

Les valeurs ci-dessous sont les jetons `YAMSpacing` et `YAMLayout` de `Components/YAMDesignSystem.swift`. La passe « compacte » les a réduites d’environ un tiers, sans toucher au plancher tactile : aucune cible ne descend sous **44 pt**.

| Jeton | Valeur |
|---|---|
| Espacements `tiny / small / medium / large / section` | 4 / 6 / 8 / 12 / 16 pt |
| Marge de page large / compacte (`page` / `pageCompact`) | 18 / 12 pt |
| Cible tactile minimale (`minimumTarget`) | 44 pt, jamais moins |
| Rayon panneau Classique | 18 pt, continu |
| Rayon bouton Classique | 13 pt, continu |
| Panneau catégorie | 208 pt de large |
| Carte standard | minimum 168 pt de large, hauteur minimale 92 pt |
| Écart de grille | 10 pt |
| Taille de carte choisie | 0,8 / 1 / 1,3 × largeur de base |
| Compositeur « Votre phrase » | champ de 64 pt de haut, respiration 14 pt |
| Commande principale | au moins 44 pt ; Parler au moins 56 pt |
| Catégorie | au moins 44 pt de haut |
| Options de carte (`cardOptionsWidth`) | 40 × 44 pt, même largeur pour le menu `⋯` des profils |
| Marge intérieure d’une carte (`cardFaceLeadingPadding` / `cardFaceVerticalPadding`) | 12 pt à gauche, 10 pt vertical |
| Ligne de réglages, de formulaire et de menu | `rowHeight` 44 pt de contenu, icône de 28 pt |
| Grilles de choix des formulaires (`swatchColumnMinWidth` / `iconColumnMinWidth`) | colonne ≥ 48 pt (pastilles de couleur, dessin 34 pt) et ≥ 56 pt (icônes, cible 44 pt) |
| Avatar d’un profil (`avatarSize` / `avatarGlyphSize`) | 38 pt de disque, 34 pt de dessin |
| Petites puces d’action (`chipHeight`) | 36 pt de contenu + marge du style `.bordered`, soit ≥ 44 pt visés |
| Fenêtre Réglages | 744 pt de large au plus, contenu centré, hauteur adaptée |
| Bordure standard | 1 pt ; sélection / contraste renforcé : 2 pt |
| Ombre | noir 4,5 %, rayon 8 pt, décalage vertical 3 pt |

La taille de carte modifie le nombre de colonnes, pas seulement l’icône. Les boutons adoptent une hauteur minimale plutôt qu’une hauteur fixe, pour accueillir les grands caractères. Une carte de 168 pt au lieu de 200 pt fait tenir une colonne de plus sur un iPad Pro 11 pouces en paysage, donc plus de phrases visibles sans défilement.

### États et mouvement

- **Normal** : surface opaque, bord fin, contraste de texte stable.
- **Pressé** : échelle 0,985 et opacité 0,82 pendant 160 ms ; pas de rebond.
- **Sélectionné** : fond secondaire, bord accentué et coche.
- **Désactivé** : désactivation native et opacité réduite, sans changer de place.
- **Saisie** : bord du compositeur accentué, focus natif.
- **Lecture** : libellé Arrêter et indication de lecture, sans animation de waveform en boucle.
- **Réduire les animations** : pas de mise à l’échelle ni de rotation animée.
- **Réduire la transparence / contraste augmenté** : suppression du décor de fond ; cartes opaques.
- **Contraste renforcé dans l’app** : bordures renforcées et décor supprimé.
- **Actions de suppression et d’avertissement** : `YAMTone` (`destructive`, `warning`, `positive`) colore l’icône, le fond teinté et le contour. Le libellé garde la couleur de texte du thème, dont le contraste est testé — un texte rouge sur blanc n’est pas lisible, et une couleur seule ne dit rien à VoiceOver.
- Retour haptique conditionné au réglage ; il n’est jamais indispensable et certains iPad ne le produisent pas.

## 4. Les six univers demandés

Classique reste le point de départ. Chacun des six thèmes conserve son identifiant existant et dispose de deux palettes complètes.

| Thème | Accent clair / sombre | Surfaces et ambiance | Forme / icône / décor |
|---|---|---|---|
| Dragon Ball | `#AD4706` / `#FFB86C` | Crème chaude / bleu martial profond | Rayons 16/12, arrondi, éclair, orbite discrète |
| Windows | `#0067AC` / `#8FCFFF` | Gris bleu / ardoise bleue | Rayons 10/8, fenêtres SF, ligne nette |
| macOS | `#245BC4` / `#A6C2FF` | Nacre / graphite neutre | Rayons 18/14, écran SF, halo léger |
| Ubuntu | `#AF401A` / `#FFB397` | Rose aubergine / prune | Rayons 13/10, arrondi, motif circulaire SF, orbite |
| Linux Mint | `#306C42` / `#A5D7A8` | Sauge pâle / forêt | Rayons 15/12, feuille SF, halo léger |
| Dragon | `#AC373D` / `#FFADA7` | Pierre chaude / obsidienne rouge | Rayons 12/9, flamme SF, filet cuivré |

Ce ne sont pas des fonds d’écran plaqués sur des boutons inchangés : palettes, surfaces, rayons, graisse des symboles, identité d’en-tête et accents décoratifs varient. Les icônes **sémantiques** Parler, Clavier, Recherche et les pictogrammes personnels ne sont volontairement pas remplacés par des personnages ou logos : on change leur traitement, pas leur signification.

Aucune illustration ni police de franchise n’est embarquée. Les noms des univers servent à identifier les inspirations demandées, sans affiliation. Toute future utilisation de personnages, logos ou ressources officielles doit faire l’objet d’une vérification des droits.

![Direction sombre, maquette web illustrative](apercu-sombre.png)

## 5. Architecture SwiftUI

```text
ContentView
 ├─ ThemeManager → AppTheme + AppAppearance
 └─ MainAACView                 État de navigation, requêtes SwiftData, actions
     ├─ CommunicationComposer  TextEditor natif + commandes
     ├─ ModernCategoryTile     Catégorie sélectionnable
     ├─ ModernAACCard          Carte, menu et actions accessibles
     ├─ SearchView             Réutilise ModernAACCard
     ├─ SettingsView
     │   ├─ ThemeSelectionView → ThemeMiniature
     │   ├─ CategoryManagementView → CategoryEditorView
     │   ├─ SpeechAndSoundSettingsView (existant)
     │   └─ UserProfilesView (existant)
     ├─ ItemEditorView         Contenu · Apparence · Voix, aperçu = YAMCardFace
     └─ FullScreenTextView

Socle : YAMSpacing · YAMLayout · YAMSurface · YAMActionButton · YAMActionLabel
        YAMPressButtonStyle · YAMAmbientBackground · YAMFeedback · YAMTone
        YAMCardFace · YAMIconChoiceGrid · YAMSwatchGrid · YAMAdvancedSection
        yamProfileSwitchConfirmation
Données et audio : modèles SwiftData existants · ProfileManager · SpeechService
                   DataSeedService (catalogue de départ d’un profil)
```

`YAMCardFace` est le point de jonction des deux passes : l’accueil, la recherche et l’aperçu du
formulaire partagent un seul dessin de carte, donc un seul endroit où changer une carte.
`YAMAdvancedSection` est partagée par la fiche de phrase et les réglages de voix, pour que
« ce que l’on range » se ressemble d’un écran à l’autre. `yamProfileSwitchConfirmation` est
partagée par l’en-tête de l’accueil et la liste des profils : même question, même formule.

- [Écran principal complet](../Views/MainAACView.swift), intégré aux vraies données : aucun faux modèle de production.
- [Compositeur réutilisable](../Components/CommunicationComposer.swift), piloté par bindings et closures.
- [Composants et jetons](../Components/YAMDesignSystem.swift).
- [Thèmes](../Models/AppTheme.swift) et [persistance de l’apparence](../Services/ThemeManager.swift).
- [Réglages](../Views/SettingsView.swift), [galerie de thèmes](../Views/ThemeSelectionView.swift), [recherche](../Views/SearchView.swift).

Les composants visuels ne sauvegardent pas les phrases. `MainAACView` coordonne les actions et une seule destination de feuille. Les formulaires et SwiftData restent responsables de l’écriture, avec une différence assumée depuis la passe 2 : un échec de sauvegarde s’affiche et l’écriture partielle est annulée, au lieu d’être ignorée. Le catalogue de départ d’un nouveau profil est fourni par `DataSeedService`, non par la vue qui le crée. Les singletons existants sont conservés pour limiter la portée de migration ; leur injection en dépendances est une amélioration possible, pas une condition cachée à l’utilisation du code livré.

## 6. Limites et validation avant diffusion

**Ce qui est livré :** code SwiftUI de l’accueil, recherche, réglages, thèmes, création/modification des catégories et plein écran ; composants réutilisables ; corrections ciblées de cycle audio et d’isolation des profils. La **passe 2** reprend les trois écrans conservés : fiche de phrase en trois sections avec aperçu partagé, liste des profils avec confirmation de brouillon, réglages de voix réordonnés autour de l’usage et non du fournisseur.

**Ce qui a été vérifié ici :** tests numériques des palettes et de la densité, structure de la passe 2 verrouillée par `Tests/test_refonte_pass2.py`, parsing de grammaire sur 17 fichiers ciblés (les trois écrans repris s’y ajoutent, leur ancien blocage du parseur ayant été levé), cohérence des appels en lecture de code, absence d’erreurs d’espacement dans le diff, aperçu web clair/sombre et Dragon Ball dans Chrome.

**Ce qui ne l’a pas été :** compilation SwiftUI, exécution sur iPad, VoiceOver, Switch Control, rendu des SF Symbols, claviers flottant/matériel, animations, performance et sauvegarde après redémarrage. La passe 2 n’a été vue dans aucun simulateur : ses sections, ses grilles et sa confirmation sont à ouvrir sur iPad avant d’être décrites comme testées. L’environnement est Linux et le dépôt fourni ne contient ni `.xcodeproj`, ni workspace, ni cible de tests Apple.

Voir le [protocole de validation](../Tests/VALIDATION.md) et les [instructions d’intégration](../README.md). Ne pas confondre parsing syntaxique, calcul de contraste et validation native.

### Risques préexistants à traiter avant une version de production

- La récupération du magasin dans `YAMParleApp` peut supprimer les fichiers de données en cas d’échec d’ouverture. Cette refonte ne modifie pas ce mécanisme : sauvegarde et migration non destructrice sont nécessaires avant diffusion.
- Les écrans de la refonte disent leurs échecs de sauvegarde (`try` + message, avec annulation de l’écriture) ; les écrans antérieurs à la refonte — `FavoritesView`, `AACWritingView`, `PhraseBarView`, une partie de `ProfileManager` (duplication, suppression, sauvegarde des réglages) — utilisent encore `try? save()` et passent donc en silence. Unifier ces chemins reste à faire, et n’est pas caché par la passe 2.
- Le brouillon composé est du texte libre : sa lecture ne rejoue pas une séquence d’enregistrements ni les métadonnées individuelles des cartes. Cela préserve le comportement actuel ; une composition audio par tokens serait un autre chantier.
- « Effacer après lecture » garde le comportement existant : effacement au lancement de la lecture, avec rétablissement désormais possible, pas attente de la fin effective du son.
- Pas d’export, de sauvegarde cloud ou de synchronisation ajouté.

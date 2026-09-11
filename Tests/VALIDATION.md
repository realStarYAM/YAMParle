# Validation de la refonte

## Résultats disponibles dans l’environnement Linux

- `test_design_tokens.py` : 5 tests, couvrant les sept identifiants persistés et les paires de couleurs en clair/sombre. Les contrastes testés concernent texte principal, secondaire, accent et texte des actions sur surfaces opaques. Pas les photos personnalisées, tous les composites transparents ou les écrans legacy.
- `check_swift_syntax.py` : analyse de grammaire sur 14 fichiers explicitement listés. Ni résolution des types, ni macros, ni SDK iOS. Le parseur tiers rejette des constructions préexistantes de `ItemEditorView`, `UserProfilesView` et `ElevenLabsService` ; ces fichiers ne sont pas dans ce contrôle.
- `git diff --check` : absence d’erreurs d’espacement.
- La maquette HTML est inspectée dans Chrome. Elle n’est pas un test de l’application native.

**Aucune compilation ou exécution SwiftUI n’a été réalisée dans cet environnement.**

## Matrice d’acceptation iPad · à exécuter

Cocher uniquement après exécution dans le vrai projet Xcode.

### Présentation et accessibilité

- [ ] iPad 11 pouces et 13 pouces, portrait/paysage, iPadOS 17 minimum et version actuellement ciblée.
- [ ] Fenêtres de 320, 600, 820, 960 et 1194 pt ; changement de taille dans Stage Manager.
- [ ] Claviers docké, flottant et matériel : curseur, sélection et composition conservés ; aucune boucle ouverture/fermeture ; boutons atteignables.
- [ ] Ouvrir le clavier en paysage large : l’en-tête se retire sans remplacer le TextEditor ni perdre son focus. Tester très faible hauteur disponible.
- [ ] Tailles de texte standard, XXXL, Accessibilité 1 et 5 : libellés lisibles, grille à une colonne en accessibilité, aucune superposition.
- [ ] VoiceOver : ordre en-tête → compositeur → commandes → catégories → grille ; libellés complets ; catégorie sélectionnée annoncée ; carte et menu distincts.
- [ ] VoiceOver : actions personnalisées Lire/Modifier fonctionnelles. La recherche annonce seulement l’ajout, même si la lecture au toucher est activée à l’accueil.
- [ ] Switch Control et Accès complet au clavier : toutes les fonctions atteignables sans geste long obligatoire.
- [ ] Réduire les animations : aucune réduction d’échelle ni rotation animée. Réduire la transparence et contraste accru : décor retiré.
- [ ] Contraste renforcé dans l’app : bordures visibles et fond sans décor. Comparer avec Accessibility Inspector.
- [ ] Aucun symbole SF absent sur la version minimale ; contrôle des photos claires/sombres et libellés très longs.
- [ ] Taille des cartes compacte/standard/grande réellement différente, sans changer l’ordre.

### Communication

- [ ] Démarrage neuf : utilisateur par défaut et catalogue disponibles ; Parler désactivé quand le texte est vide.
- [ ] Clavier natif : ponctuation, emoji, accents, retours à la ligne, copier/coller, texte long.
- [ ] Carte : ajoute `text`, pas `displayLabel`. Lecture seule : emploie `spokenText` ou l’enregistrement de l’élément sans ajouter.
- [ ] Lecture au toucher désactivée puis activée ; aide de la grille correspond au comportement.
- [ ] Effacer → Rétablir, saisie après effacement, suppression du dernier mot avec espaces et retours à la ligne.
- [ ] Enregistrer préremplit phrase/catégorie ; Annuler ne sauvegarde rien ; fermeture de clavier sans perte du message.
- [ ] Recherche insensible aux accents ; résultat vide ; ajout ; lecture sans ajout ; modification après fermeture de la recherche sans erreur de présentation de feuille.
- [ ] Plein écran avec texte de plusieurs écrans : Fermer et Parler/Arrêter restent visibles. En face-à-face, le début de phrase est accessible depuis la bonne orientation.

### Profils et thèmes

- [ ] Changer de profil depuis l’en-tête et depuis la gestion : aucune phrase/catégorie de l’autre profil ; ancienne lecture stoppée ; brouillon effacé.
- [ ] Profil vide : état vide explicite, création possible, pas de repli sur le catalogue d’un autre utilisateur.
- [ ] Créer/renommer une catégorie : phrases rattachées conservées ; catégorie sélectionnée valide au retour.
- [ ] Supprimer une catégorie sélectionnée par un autre chemin existant : l’accueil sélectionne une catégorie restante.
- [ ] Les sept thèmes × modes clair et sombre ; mode Système suit l’appareil, y compris dans les feuilles.
- [ ] Changer de thème ne réordonne pas les phrases ni les commandes.
- [ ] Fermer/relancer : thème du profil et apparence de l’appareil conservés ; anciennes clés de thèmes toujours reconnues.
- [ ] Réglages parole pris en charge par ProfileManager conservés après sortie puis changement de profil.
- [ ] Échec de sauvegarde simulé : les écrans thème/catégorie ne prétendent pas que la sauvegarde a réussi.
- [ ] Initialisation du catalogue après absence de `cat_conversation` : aucune suppression des catégories/phrases d’un autre profil.

### Cycle de lecture

- [ ] Apple, enregistrement et ElevenLabs en cache : début, fin naturelle et arrêt actualisent Parler/Arrêter.
- [ ] ElevenLabs à générer : Arrêter accessible pendant l’attente ; succès ou échec après arrêt ne relance ni audio ni secours Apple.
- [ ] Réponses réseau dans le désordre : une ancienne réponse ne remplace ni n’arrête la demande la plus récente.
- [ ] Passage rapide Apple → enregistrement → ElevenLabs → Apple : pas de chevauchement ni ancien callback qui efface le nouvel état.
- [ ] Fichier absent/corrompu, échec `prepareToPlay`/`play`, erreur de décodage : retour à un état non bloqué.
- [ ] Enregistrement manquant / clé absente / génération échouée : secours Apple comme prévu.
- [ ] Tests séparés des préécoutes audio dans les éditeurs/réglages qui contournent SpeechService.
- [ ] « Effacer après lecture » : comportement existant au lancement, avec possibilité de rétablir ; Arrêter fonctionne même si le compositeur est vide.

## Points hors périmètre

Pas de test automatisé iOS/XCTest annoncé : aucune cible Apple n’est fournie dans ce dépôt. Ajouter la suite native au projet réel après intégration, notamment pour les callbacks audio et les scénarios de focus clavier. Les problèmes de récupération du magasin, de sauvegarde silencieuse dans les formulaires legacy et d’export doivent être traités avant diffusion sur des données réelles.

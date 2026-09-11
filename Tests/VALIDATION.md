# Validation de la refonte

## Résultats disponibles dans l’environnement Linux

- `test_design_tokens.py` : 5 tests, couvrant les sept identifiants persistés et les paires de couleurs en clair/sombre.
- `test_layout_metrics.py` : 15 tests sur les dimensions compactes — jetons d’espacement et de mise en page, plancher tactile de 44 pt, largeur de la fenêtre Réglages bornée à 700–780 pt, hauteurs de carte et de compositeur, style de présentation des feuilles, et absence de hauteurs figées, de corps de texte codés en dur ou de teintes système hors jetons dans les fichiers de base **et** dans les quatre fichiers repris à la passe 2. Les contrastes testés concernent texte principal, secondaire, accent et texte des actions sur surfaces opaques. Pas les photos personnalisées, tous les composites transparents ni les écrans antérieurs à la refonte.
- `test_refonte_pass2.py` : 23 tests sur la structure annoncée par le document : trois sections de la fiche de phrase et leur ordre, réglages rares repliés mais annoncés, aperçu dessiné par la carte réelle, erreurs de sauvegarde dites, badge « Par défaut » unique et coche du profil actif, actions de gestion séparées, confirmation de brouillon sur les deux chemins de changement de profil, ordre des écrans de voix et relégation d’ElevenLabs en section avancée.
- `check_swift_syntax.py` : analyse de grammaire sur 17 fichiers explicitement listés. Ni résolution des types, ni macros, ni SDK iOS. `ItemEditorView` et `UserProfilesView` y sont entrés à la passe 2 : leur seul rejet venait de `if let … = try? await …`, écrit en deux temps depuis. `ElevenLabsService` reste hors de ce contrôle, son `resourceValues(forKeys:)` interrompt toujours le parseur.
- `git diff --check` : absence d’erreurs d’espacement.
- La maquette HTML est inspectée dans Chrome. Elle n’est pas un test de l’application native.

**Aucune compilation ou exécution SwiftUI n’a été réalisée dans cet environnement.** La passe 2 n’a donc été vue sur aucun appareil.


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

### Densité iPad · passe compacte

À cocher après exécution sur iPad Pro 11 pouces, **paysage et portrait**.

- [ ] Écran principal paysage (1194 × 834 pt) : une colonne de cartes de plus qu’avant la passe, aucune barre de défilement horizontale, colonne Catégories de 208 pt.
- [ ] Écran principal portrait (834 × 1194 pt) : page verticale défilante, en-tête sur une ligne si possible, bloc « Votre phrase » de hauteur réduite à 64 pt de champ.
- [ ] Fenêtre Réglages : carte centrée, jamais plein écran, largeur de contenu ≤ 744 pt, titre `.inline`, Fermer toujours accessible ; les cinq sections restent lisibles sans défilement excessif.
- [ ] Sur iPadOS 17 (si encore visé) : la fenêtre Réglages occupe la hauteur de la feuille mais le contenu reste centré à 744 pt — vérifier l’absence de bandes vides incohérentes.
- [ ] Toutes les cibles tactiles mesurées ≥ 44 pt : Parler, commandes du compositeur, cartes, catégories, lignes de réglages, puces d’édition.
- [ ] VoiceOver : libellés, valeurs et actions personnalisées toujours présents sur les cartes, les catégories et les lignes de réglages ; ordre en-tête → compositeur → commandes → catégories → grille inchangé.
- [ ] Dynamic Type : corps par défaut, XXXL, Accessibilité 1 et 5 — rien ne se chevauche, la grille passe à une colonne, les cartes gardent leur texte intégral.
- [ ] Les trois tailles de carte (compacte / standard / grande) restent visiblement différentes et plus denses qu’avant la passe.
- [ ] Réduire la transparence / contraste augmenté : décor absent, bordures visibles ; l’ombre volontairement réduite ne crée aucun halo résiduel.
- [ ] Contraste renforcé dans l’app : bordures visibles et fond sans décor. Comparer avec Accessibility Inspector.
- [ ] Aucun symbole SF absent sur la version minimale ; contrôle des photos claires/sombres et libellés très longs.
- [ ] Taille des cartes compacte/standard/grande réellement différente, sans changer l’ordre.

### Seconde passe · formulaires, profils, voix

À cocher après exécution sur iPad. Ces trois écrans n’ont été vérifiés que statiquement ici : structure, jetons, labels.

**Nouvelle phrase / Modifier**

- [ ] Trois sections dans l’ordre : Contenu, Apparence, Voix. Le clavier iOS reste utilisable dans les deux champs de texte, sans focus perdu en descendant.
- [ ] L’aperçu est identique à la carte obtenue sur l’accueil : même texte (l’étiquette si elle existe, sinon le texte), même icône ou photo, même teinte, même largeur minimale. Une phrase de six mots agrandit l’aperçu et la carte de la même façon.
- [ ] Le badge « Voix enregistrée » / « Voix IA » n’apparaît dans l’aperçu que quand il apparaît sur la carte ; « Prononciation alternative » se dit en dessous, pas sur la carte.
- [ ] Icônes et pastilles de couleur : cible de 44 pt sous le doigt, sélection marquée d’une coche, chaque choix nommé par VoiceOver (y compris « Jaune », « Brun », qui ne se décrivent pas par la couleur seule).
- [ ] Section « Voix personnalisée » repliée sur une fiche neuve ; ouverte d’office sur une fiche déjà enregistrée avec moteur individuel ou prononciation alternative ; son résumé annonce ce qui est actif.
- [ ] Échec de sauvegarde simulé (conteneur en lecture, contrainte violée) : la fiche reste ouverte, le message s’affiche, aucune demi-phrase n’apparaît sur l’accueil après fermeture.
- [ ] Retirer la photo fait revenir l’icône choisie, sans effacer la couleur ni le texte.
- [ ] Micro refusé : le bouton d’enregistrement ne laisse pas l’écran en état d’enregistrement fantôme.

**Profils**

- [ ] Un seul badge « Par défaut » visible ; le profil actif porte la coche et l’annonce ; les noms longs et les avatars photo ne poussent pas le hors-champ.
- [ ] « Utiliser » sans brouillon : changement immédiat, lecture stoppée, brouillon vidé, catégorie réévaluée.
- [ ] « Utiliser » avec une phrase en cours, depuis la liste **et** depuis le menu d’en-tête : la même confirmation s’affiche dans les deux cas, avec la même formule, et « Garder ce profil » laisse tout en place.
- [ ] Renommer conserve phrases et catégories ; un nom vidé au clavier n’écrase pas le nom existant.
- [ ] Dupliquer produit un profil complet (catégories, phrases, favoris) et ne modifie pas l’original ; la suppression n’est proposée qu’à partir de deux profils et nomme le profil concerné.
- [ ] Créer un profil : quatre catégories de départ présentes, aucun contenu copié d’un autre profil, et « Définir comme par défaut » respected.
- [ ] VoiceOver : ligne de profil lue d’un bloc (nom, badge, contexte), puis le bouton « Utiliser », puis le menu `⋯` avec ses quatre actions.

**Parole et son**

- [ ] Ordre à l’écran : Voix principale, Essai, Rythme et volume, Comportement, puis section avancée repliée. Aucun compte ElevenLabs n’est demandé pour lire avec les voix Apple.
- [ ] Essai : la phrase modifiée est celle qui est lue ; le bouton devient Arrêter pendant la lecture et fonctionne avec ElevenLabs comme avec Apple.
- [ ] Les trois curseurs n’affectent que les voix Apple, comme l’annonce leur pied de section ; une voix IA téléchargée garde son rythme.
- [ ] Section avancée : ouverture automatique quand le moteur IA est actif, clé masquée à l’écran, enregistrement et suppression de clé fonctionnels, cache listé avec écoute, arrêt et retrait.
- [ ] Échec de génération : l’alerte d’échec s’affiche, la voix Apple reste disponible, aucun bouton ne reste en attente.
- [ ] Les réglages pris en charge par `ProfileManager` survivent à la sortie de l’écran, puis à un changement de profil.

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

Pas de test automatisé iOS/XCTest annoncé : aucune cible Apple n’est fournie dans ce dépôt. Ajouter la suite native au projet réel après intégration, notamment pour les callbacks audio et les scénarios de focus clavier. Les problèmes de récupération du magasin, de sauvegarde silencieuse dans les écrans antérieurs à la refonte et dans `ProfileManager`, et d’export doivent être traités avant diffusion sur des données réelles. Depuis la passe 2, la fiche de phrase, la création et le renommage de profil, ainsi que la fiche de catégorie, annulent leur écriture et l’annoncent ; ce n’est pas encore le cas des autres chemins.

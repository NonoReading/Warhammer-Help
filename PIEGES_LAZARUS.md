# Pièges Lazarus / Free Pascal accumulés

*Sorti de CONTEXT.md (section 4) le 19/10/2026. Ajouter ici tout nouveau piège.*

- **Un contrôle créé en code APRÈS `MiseEnFormeDesChamp(Self)` (début de `FormCreate`) n'est pas mis en forme** : il garde la police blanche du formulaire. Une grille affiche alors des lignes blanc sur blanc (invisibles, sauf la ligne sélectionnée) et des en-têtes pâles. Parade : `MiseAJourUnContenaire(<conteneur>)` (globalfonts.pas) sur le panneau qui possède ses enfants, avant de le remplir. Vu le 12/11/2026 (tableau des règles de l'étape Livre de WinCreation, `TPanelOptionRegle`).

- **Type de sort V1 de plusieurs mots : la clé de traduction garde l'ESPACE.** Le code fait `'RULES-SPELLV1_' + UpperCase(liste)` (xmlexportimport.pas) : « Master Rune » donne `RULES-SPELLV1_MASTER RUNE`, pas `MASTER_RUNE`. Avec un souligné dans INTERFACE*.Xml, la colonne « Spell type » affiche la clé brute. Vu le 31/10/2026 (Master Rune, Klauser Rune, Tree Song).
- **Dans un `<Trappings>` V1, « + » et « / » sont des séparateurs** (`SeparateurEnsemble` / `SeparateurMulti`, chargeconstantes.pas) : « damage +1 » coupe l'objet en deux et `ChargeMetierEquipement` (winmetier.pas, `For IndL := 0 to 1`) plante en « List index (1) out of bounds » à la sélection de la carrière. Le « ; » sépare les objets. Vu le 31/10/2026 sur la faux d'Amethyst Wizard (Realms of Sorcery).
- **`Pos` rend 0 quand il ne trouve rien, et `Copy(X, 1, 0)` rend une chaîne VIDE.** Remplacer
  une longueur fixe par un `Pos` paraît toujours plus sûr — ça ne l'est pas : la constante
  n'avait pas de cas de retour à zéro. Deux chaînes vides étant égales, un test d'égalité se
  met alors à répondre « oui » pour **tout**. Vu le 05/09/2026 (§2.46) : la grille
  d'augmentation des talents affichait quatre fois le même talent. Parade employée :
  `Pos('_', X + '_')`, qui rend `Length(X) + 1` quand le séparateur est absent, donc `Copy`
  rend le code entier.
- **Un identifiant du projet porte TOUJOURS son préfixe de livre.** Tout test sur ses premiers
  caractères doit passer par `DecoupeCodeValeur` d'abord (§2.46). Un test de position fixe sur
  un code complet ne lève aucune erreur : il répond simplement « non » pour toujours.

- **Trois mécanismes distincts régissent les Talents/Compétences de spécialisation d'une
  famille générique (ex. "Magie des Arcanes", `RULES-T0088_*`) — ne pas les confondre :**
  1. **Le calcul XP/pool** (`chargetalent.pas`, champ `CodeTalentGenerique`) lit bien la balise
     XML `<Generique>` du Talent/Compétence. Sans cette balise, un repli automatique dérive un
     générique à partir du code lui-même (`CodeSansLivre` + tout avant le `_`) - un talent qui
     n'a pas `<Generique>` forme alors son propre pool isolé au lieu de rejoindre la famille
     partagée. Bug trouvé et corrigé le 28/09/2026 (Log.txt, 2 cas : TRIBE-T0207/T0208 et
     TEMPLE-T0001_DARK).
  2. **Le popup de choix de spécialisation** (`winspecialisation.pas`, `TWinSpecialisations.
     AjouteLigne`) **ignore complètement la balise `<Generique>`.** Il compare uniquement le
     PREFIXE du code du talent lui-même (`ExtractStringBefore(CodeSansLivre(Code),'_')`) au
     préfixe demandé - jamais `PTalent.CodeGenerique`. Un talent dont l'id ne partage pas ce
     préfixe (ex. `GRIM-T0205` pour la famille `T0088`) n'apparaît donc JAMAIS dans le popup,
     même si `<Generique>"RULES-T0088_*"</Generique>` est parfaitement renseigné.
  3. **La classification "liste maître vs. popup de spécialisation" dans WinTalents
     (`wintalent.pas` ~l.172, `if ... PTalent.SousTalent = false ...`) dépend du BLOC XML
     PARENT, pas d'un champ visible dans le Talent lui-même.** Un `<Talent>` déclaré dans
     `<DATA_TALENT>` a `SousTalent = false` (xmlexportimport.pas ~l.1614) et apparaît TOUJOURS
     dans la liste maître de WinTalents, même s'il porte un `<Generique>` par ailleurs correct.
     Seul un `<Talent>` déclaré dans `<DATA_TALENT_SPECIALIZATION>` a `SousTalent = true`
     (xmlexportimport.pas ~l.1793) et reste invisible de la liste maître, pour ne ressortir que
     via le popup de spécialisation. C'était la VRAIE cause du bug signalé par Nono le
     28/09/2026 : "Arcane Magic (Wild)" et 8 autres talents de domaine avaient été saisis dans
     `<DATA_TALENT>` (avec `Attribut`/`Explanation`/`Skill`/`Max`/`PDF`/`Test`, comme un talent
     ordinaire) au lieu de `<DATA_TALENT_SPECIALIZATION>` (juste `Description` + `Generique`) -
     ils apparaissaient donc comme des talents à part entière dans WinTalents, alors que les 8
     Lores de base du Rulebook (déjà correctement en `DATA_TALENT_SPECIALIZATION`) restaient
     invisibles comme attendu. Les mécanismes 2 (id hors famille) et 3 (mauvais bloc) sont
     INDÉPENDANTS : le 1er corrigeait le popup, le 2e corrigeait la liste maître - les deux
     étaient nécessaires. Bug trouvé et corrigé le 28/09/2026 (Log.txt, 9 cas :
     HORNE-T0197/198/199, GRIM-T0203/204/205/206, TRIBE-T0207/208, tous renommés en
     `RULES-T0088_XXX` ET déplacés vers `DATA_TALENT_SPECIALIZATION`).

  Consequence pratique pour tout nouveau Talent/Compétence de spécialisation, quel que soit
  le livre qui l'introduit :
  - **Le placer dans `DATA_TALENT_SPECIALIZATION`, jamais `DATA_TALENT`** (voir
    `GABARIT_LIVRE_XML.md`), avec seulement `Description` + `Generique` (le texte de saveur du
    livre source va en commentaire XML, ce bloc ne le charge pas).
  - **Utiliser le préfixe COMPLET de la famille comme id** (`RULES-T0088_XXX`, pas
    `GRIM-T0088_XXX` ni `GRIM-TXXXX`) - le préfixe livre (`RULES-`, `GRIM-`...) est de toute
    facon retiré par `CodeSansLivre` avant comparaison, donc il n'apporte AUCUNE protection
    contre les collisions ; seul le code du milieu (`T0088`) compte pour le regroupement, dans
    les mécanismes 1 et 2. Garder `RULES-` (le livre d'origine de la famille) est la convention
    déjà en place ailleurs dans le corpus (`RULES-T0172_TZEENTCH` introduit par Enemy in Shadows
    Companion, `RULES-T0080_MANANN`/`RULES-T0080_STROMFELS` introduits par Sea of Claws) : ça
    garde tous les membres d'une famille lisiblement groupés sous un seul préfixe, meme si ça ne
    change rien au matching lui-même.
  - Idée de Nono (28/09/2026, à construire dans une prochaine session) : un XSD pourrait figer
    ces règles à la validation - id au format `LIVRE-CODE` ou `LIVRE-CODE_*`, et deux
    `complexType` de `<Talent>` distincts selon le bloc parent (`DATA_TALENT` interdit
    `<Generique>` ; `DATA_TALENT_SPECIALIZATION` l'exige et interdit
    `Attribut`/`Explanation`/`Skill`/`Max`/`PDF`/`Test`). Le code Pascal ne valide pas contre un
    XSD au chargement (pas de support XSD natif dans l'unit DOM de FPC) : validation prévue en
    hors-ligne (script Python, comme les checks de bien-formé déjà en place), pas à l'exécution.
    Même question à traiter pour les Compétences (`DATA_SKILL`/`DATA_SKILL_SPECIALIZATION`,
    non auditées dans cette passe - a verifier).
  - **Fait le 28/09/2026** : `valider_corpus.py` + hook `.git/hooks/pre-commit` branchent cette
    validation sur chaque commit touchant un livre WFRP4/WFRP5 - voir §1.2.

- **Ne jamais appeler une primitive « sur toute l'image » à l'intérieur d'une boucle qui
  parcourt déjà toute l'image.** `RemplacerPixelParTransparent` (`pdfutils.pas`) appelait
  `Img.ReplaceColor` pour chaque pixel de fond rencontré, et `ReplaceColor` reparcourt le
  bitmap entier. Le piège était doublé par une asymétrie : le test de couleur avait une
  **tolérance** alors que `ReplaceColor` exige la couleur **exacte**, donc chaque pixel
  d'anti-aliasing survivait au remplacement, re-matchait, et déclenchait un balayage
  complet de plus. Des centaines de balayages pour une icône. Réécrit le 31/08/2026 en un
  seul passage : quelques millisecondes.
- **`img.Colors[x, y]` est un accesseur coûteux**, pas un accès mémoire. C'est l'interface
  `TFPColor` de FPImage : chaque lecture convertit le pixel BGRA en quatre canaux 16 bits.
  Le lire une fois par canal dans une comparaison le fait donc payer quatre fois. Pour
  parcourir une image, passer par `ScanLine[y]`, qui rend un `PBGRAPixel` sur la ligne —
  et parcourir en **lignes**, pas en colonnes : les données sont rangées en lignes.
- **Après une écriture directe via `ScanLine`, `Img.InvalidateBitmap` est obligatoire.**
  BGRABitmap garde une copie LCL du bitmap ; sans invalidation elle n'est pas reconstruite
  et `SaveToFile` peut écrire l'image d'AVANT les modifications. Panne silencieuse : aucune
  erreur, juste un fichier inchangé.
- **Attention aux échelles de couleur qui se mélangent.** `TFPColor` va de 0 à 65535,
  `TBGRAPixel` de 0 à 255, et la conversion est un facteur **257** (pas 256). Un seuil de
  tolérance écrit en pensant au 0-255 mais appliqué à du 16 bits est 257 fois trop serré —
  c'était le cas du `MaxDiff = 2000` de l'ancien `TestCouleur`, soit 3 % et non 2000.

- **Toute nouvelle liste globale `ListXxx` doit être ajoutée au bloc de RAZ de `ChargerLivre`**
  (`warhammersource.pas`, `if ForceMaj then`), avec son compteur `NbXxx`. Créer la liste dans
  `FormCreate` ne suffit pas : sans le `.Clear`, chaque rechargement (changement de livre actif ou
  de langue) empile le contenu par-dessus l'ancien, et le bug ne se voit **pas** au premier
  lancement. Symptôme typique : une donnée affichée deux fois, puis trois. Arrivé deux fois
  (`ListArmureBonusModif`, `ListArmureSimplifiee`, §2.5). Contre-exemples à ne pas toucher :
  `ListTexte` et `ListTraduction`, volontairement hors de la RAZ (§2.8).
  Contrôle rapide : comparer les `ListXxx := TListXxx.Create` de `FormCreate` aux `ListXxx.Clear`
  du bloc de RAZ.
- **Un commentaire XML est un nœud enfant comme un autre.** Une boucle
  `Node := Parent.FirstChild; While Assigned(Node) do ... Node.Attributes.GetNamedItem(...)`
  plante sur un commentaire (`Attributes` vaut `nil` → *access violation reading from `$10`*), et sur
  un bloc sans attribut elle rejoue silencieusement les valeurs du nœud précédent. Toujours poser
  `if Node.NodeName = <balise attendue> then` avant de lire. Vu deux fois : doublon silencieux
  (§2.11), puis plantage au lancement (§2.13). Les commentaires de documentation se posent **avant**
  la balise du bloc, pas dedans.
- Une fonction Pascal qui renvoie un `record` **ne garantit pas** l'initialisation de son `Result` :
  si aucune branche ne l'affecte (cas de `ChercheLivre`/`ChercheLivreLibelle` quand rien n'est
  trouvé), les champs entiers contiennent n'importe quoi. Tester le drapeau `RechercheTrouve` plutôt
  que le contenu du record.
- Colonne 0 réservée dans un `TStringGrid` (les données commencent à `Cells[1]`)
- `ColCount` = dernier indice + 1, sinon les écritures sont perdues sans erreur
- `StrictDelimiter := True` **avant** `Delimiter` et `DelimitedText`, sinon les espaces séparent
- Les gestionnaires d'événements doivent être dans la section `published`
- Les contrôles créés dynamiquement qui recouvrent une ScrollBox doivent avoir `Parent := Self`
- `Parent` est une propriété de `TControl` → ne jamais nommer une variable locale `Parent`
  (erreur "Duplicate identifier")
- `TColor` s'écrit en BGR, pas en RGB (`#FF8080` → `$8080FF`)
- Homonymie de globales : une variable déclarée dans deux unités compile sans erreur ; la
  dernière unité du `uses` gagne. `Ctrl+Clic` mène à la déclaration réellement utilisée.
  Convention à tenir : les globales partagées vivent uniquement dans `ChargeConstantes`.
- Éditer un `.lfm` à la main : fermer Lazarus d'abord, remplacer les blocs, ne pas les ajouter
- Ne jamais comparer un `CodeTalent`/`CodeSort`/etc. par position brute (`copy(Code,1,N)`) en
  supposant l'absence de préfixe de livre (`LIVRE-CODE`) : ça casse dès qu'un livre est ajouté
  et que le code se retrouve préfixé. Utiliser `DecoupeCodeValeur`/`CodeValeur` (unitcalcul.pas)
  ou `CompareRechercheValeur`, qui gèrent déjà le découpage. Bug réel trouvé le 15/08/2026 dans
  `TWinPersonnages.SortAffiche` (winpersonnage.pas) : `copy(Tal,1,5) = TalentSortBenediction`
  ne matchait plus depuis l'ajout d'un livre, empêchant l'ajout automatique des sorts liés à un
  talent de Bénédiction - corrigé en insérant `DecoupeCodeValeur(Tal)` avant la comparaison.
- `CompareRechercheValeur` fait une comparaison EXACTE du code (après retrait du préfixe de
  livre), pas une comparaison de préfixe : `(LivreRecherche=LivreValeur) and
  (CodeRecherche=CodeValeur)`. Pour les catégories de talent qui existent en variantes
  suffixées par divinité/domaine (Miracle `T0080_*`, Domaine `T0088_*` - voir
  `BOOK_RULESBOOK.Xml`), comparer avec `CompareRechercheValeur(Code, TalentSortMiracle)` ne
  matche donc jamais, même sans problème de préfixe de livre. Bug réel trouvé le 15/08/2026
  dans `TWinPersonnages.ButtonSortClick` (winpersonnage.pas) : les trois vérifications
  (Domaine/Miracle/MagieMineure) utilisaient `CompareRechercheValeur` contre les constantes
  brutes `TalentSortDomaine`/`TalentSortMiracle`/`TalentSortMagieMineure` - corrigé en
  `DecoupeCodeValeur(...)` puis `copy(CodeValeur,1,5) = TalentSortXXX` (comparaison de préfixe
  sur les 5 premiers caractères, cohérente aussi pour MagieMineure/T0089 qui n'a pas de
  variante suffixée).
- Retirer le préfixe de livre d'un seul côté d'une comparaison (`ExtractStringAfter(Code,
  SeparateurLivre) = AutreCode`) casse tout aussi sûrement que ne pas le retirer du tout :
  si `AutreCode` garde son préfixe, la comparaison ne matche plus jamais. Toujours traiter
  les DEUX côtés avec la même fonction (`CompareRechercheValeur`, qui découpe les deux
  valeurs en interne) plutôt que de découper à la main un seul argument. Bug réel trouvé le
  16/08/2026 dans `PdfPersonnageCreationFeldo2P` (pdfpersonnage.pas) : le calcul de
  Fortune/Resolve comparait `ExtractStringAfter(PRaceAttribut.CodeRace, SeparateurChance) =
  Personnage.Race`, alors que `Personnage.Race` garde son préfixe livre (`RULES-RACE_HUM`) -
  la base de race n'était donc jamais ajoutée, et Fortune/Resolve affichaient exactement la
  moitié de Fate/Resilience (qui, eux, passent par `PdfPersonnageAttribut`, correcte).
  Repéré par Nono en comparant un rendu PDF réel aux données du XML de sauvegarde. Corrigé
  avec `CompareRechercheValeur(Personnage.Race, PRaceAttribut.CodeRace)`.
- Variante du piège ci-dessus, cette fois sans `CompareRechercheValeur` disponible :
  `PdfPersonnageAttribut` (pdfpersonnage.pas) compare les bonus d'attribut donnés par un
  talent (`PTalent.Attribut`, liste ';' de codes AVEC préfixe livre, ex. `"RULES-ATTR_WP"`)
  par ÉGALITÉ DE CHAÎNE STRICTE (`Attr = Attribut`), pas via `CompareRechercheValeur`. Il faut
  donc toujours lui passer un code d'attribut complet (préfixé), jamais une constante nue
  comme `ConstCaracE`/`ConstCaracFM` - sinon la comparaison échoue systématiquement et
  silencieusement, et les bonus d'attribut venant de talents sont ignorés. Bug réel trouvé le
  16/08/2026 dans la nouvelle fonction `PersonnageCorruptionTotal` (§2.7, Étape 3) : appelait
  `PdfPersonnageAttribut(Personnage, ConstCaracE, Bonus)` avec la constante nue, alors que
  `PdfPersonnageCreationFeldo2P` passe toujours `PAttribut.CodeAttribut` (préfixé, via
  `ListeAttribut`) - `WinPersonnage` affichait 7 là où le PDF affichait 8. Corrigé en
  récupérant le code complet via `ChercheAttribut(ConstCaracE)` (chargeattribut.pas, déjà
  prefix-safe comme `ChercheRaceAttribut`) avant l'appel.
- `TStringGrid.Cells[Col, Row]` (et toute propriété indexée avec getter/setter, plus
  généralement) n'est pas une vraie variable (l-value) : `+=` dessus échoue à la
  compilation avec "Variable identifier expected" (pas une erreur logique, une erreur de
  compilation). Utiliser une réaffectation complète : `Cells[C,R] := Cells[C,R] + '...';`.
  Bug réel trouvé le 16/08/2026 dans `TWinArmors.TabArmorSelection` (winarmor.pas) en
  construisant le texte de malus à partir de plusieurs entrées de `ListArmureBonusModif`.
- **Nouveau contrôle ajouté sur un `TTabSheet` de `WinPersonnage` invisible à l'exécution
  (mais présent dans le `.lfm`, compile sans erreur)** : `MiseEnFormeDesChamp(self)`
  (`globalfonts.pas`, appelée dans `Initialisation()`) crée dynamiquement, pour CHAQUE
  `TTabSheet` du formulaire, un `TShape` plein cadre (`Align := alClient`) par-dessus tout
  le contenu de l'onglet, pour donner le fond noir/thème (`MiseAJourUnContenaire`,
  `globalfonts.pas` ~ligne 52). Ce `TShape` passe devant les contrôles existants sauf s'ils
  sont explicitement ramenés au premier plan - d'où le `ButtonHistorique.BringToFront;` déjà
  présent en fin d'`AfficheImageRace()`. Tout nouveau contrôle posé sur un onglet (existant
  ou nouveau) doit recevoir son propre `.BringToFront;` au même endroit, sinon il compile et
  s'affiche dans l'éditeur Lazarus mais reste invisible une fois l'appli lancée. Bug réel
  trouvé le 16/08/2026 avec `StringGridCorruption`/`ButtonCorruptionAjoute`/
  `ButtonCorruptionSupprime` (nouvel onglet Corruption) - confirmé par Nono : c'est la
  méthode connue (et seule connue) pour avoir un fond noir homogène sur les onglets de ce
  projet, donc pas un bug à corriger à la source, juste un réflexe à avoir pour tout nouvel
  ajout.
- **Un `TRadioButton`/`TCheckBox` natif Windows devient illisible dès qu'il passe `Enabled :=
  True`, même avec `Font.Color` fixé.** Signalé par Nono le 12/09/2026 sur `WinMutation`
  (`GroupBoxMutationType`/`Entree`, désactivés à l'ouverture puis activés en cours de scénario) :
  les trois libellés (Randomly/Give the result of your throw/Select) restaient lisibles tant que
  le `GroupBox` était désactivé (rendu Windows en gris imposé, visible sur fond noir), puis
  disparaissaient dès qu'il devenait actif. Le thème Windows (UxTheme) dessine la légende d'un
  `TRadioButton` actif dans sa propre teinte et ignore `Font.Color` - confirmé en écartant deux
  pistes qui n'ont eu aucun effet visible : fixer `Font.Color` directement, puis désactiver le
  thème du contrôle via l'API Win32 `SetWindowTheme` (première dépendance directe à l'unité
  `Windows` du projet, abandonnée ensuite). Corrigé en réutilisant le procédé déjà en place pour
  les `TTabSheet` ci-dessus : un `TShape` en fond (`Align := alClient`) posé sur le `TGroupBox`
  parent (`MiseAJourUnContenaire`, `globalfonts.pas`) - étant fenêtré, le `RadioButton` reste au
  premier plan par-dessus, et un fond clair rend sa légende lisible quelle que soit la teinte que
  le thème lui impose, sans avoir à la maîtriser. Réflexe à retenir : si un texte de contrôle
  natif Windows disparaît sans raison apparente (surtout après un changement d'état
  Enabled/Visible), poser un fond derrière plutôt que de chercher à teinter le contrôle
  lui-même - `CheckBox` n'est pas encore touché mais appartient à la même famille.
- **Pattern récurrent - variable record réutilisée d'un tour de boucle à l'autre pendant un
  chargement XML, jamais remise à vide/zéro avant d'être ajoutée au tableau** : ce projet
  charge presque tout le XML avec UNE SEULE variable record locale par type de donnée
  (`PersonnageTalent`, `PArmureBonus`, etc.), réutilisée pour toutes les entrées d'un même
  tableau (voire plusieurs tableaux différents dans `PersonnageXmlChargement`). Tout champ non
  explicitement réaffecté à chaque itération garde la valeur du tour précédent (voire d'un
  tableau totalement différent chargé plus haut dans la même fonction) - ce n'est PAS remis à
  zéro automatiquement par le `for`/`while`. Déjà rencontré deux fois : `PArmureBonus.Malus`
  (15/08/2026, xmlexportimport.pas, voir plus haut) et `PersonnageTalent.Asterisque`
  (16/08/2026, chargepersonnage.pas, `PersonnageXmlChargement` - `.Asterisque` jamais
  initialisé aux trois sites de chargement `CreationTalent`/`AugmentationTalent`/
  `MetierTalent`, ce qui affichait des `(-1)` parasites à côté de chaque talent sur le PDF ;
  une deuxième erreur s'y ajoutait, la boucle de calcul des astérisques pour
  `AugmentationTalent` testait `PersonnageTalent.Asterisque` - la variable de boucle du
  chargement XML, sans rapport - au lieu de `Personnage.AugmentationTalent[indiceTalent]
  .Asterisque`). Réflexe à avoir : quand une variable record locale est réutilisée pour
  peupler un tableau dans une boucle de chargement XML, vérifier que TOUS ses champs sont
  explicitement réaffectés à chaque itération, pas seulement ceux qui viennent du XML lu à cet
  endroit précis. Même famille : `CalculTotaux`/`MajTables` (`winpersonnage.pas`) reconstruisent
  `Personnage.AugmentationTalent` depuis la grille `TabTalent` à CHAQUE ouverture de personnage ; la
  variable `PersonnageTalent` poussée dans le tableau doit voir son `Asterisque` remis à 0 (voir 2.102).
- Ajouter un contrôle dans l'IDE (glisser-déposer un `TRadioButton`/`TBCButton`/`TStringGrid`
  etc.) ne câble PAS son `OnClick`/`OnDblClick` tout seul, même si le gestionnaire existe déjà
  dans le `.pas` (écrit par Claude, pas créé via double-clic dans l'IDE). Il faut explicitement
  aller dans l'Inspecteur d'objets (onglet Events) et choisir le nom du gestionnaire dans le
  menu déroulant pour CHAQUE contrôle. Tant que ce n'est pas fait, le code compile sans erreur
  (les procédures existent, juste non référencées par aucun contrôle) mais la fenêtre reste
  figée dans son état de départ - aucun retour visuel n'indique l'oubli. Repéré le 17/08/2026
  (CONTEXT.md §2.7, étape 6) : Nono avait ajouté tous les nouveaux contrôles de `WinMutation`
  mais pas câblé leurs événements, ce qui laissait le bouton "Randomly" (Hasard) visible même
  après avoir sélectionné un autre mode - diagnostiqué en relisant le `.lfm` (aucune ligne
  `OnClick =` sur les nouveaux contrôles).
- **`Personnage` (et tous les records associés : `PersonnageMetier`, `PersonnageAttribut`,
  `PersonnageCompetence`, etc., `winpersonnage.pas`) ne sont PAS des champs propres à chaque
  fenêtre `TWinPersonnages`** : ce sont des variables globales UNIQUES au niveau de l'unité
  (déclarées avec des initialiseurs `= false`/`= ''` typiques d'un bloc `var` d'unité, pas d'un
  champ de classe), partagées par TOUTES les instances de fenêtre ouvertes. Repéré le
  17/08/2026 en concevant le changement de langue en direct (§2.8) : impossible de savoir "quel
  personnage est ouvert dans quelle fenêtre" en lisant cette donnée, puisqu'elle est écrasée par
  la dernière fenêtre créée/chargée, quel que soit le nombre de fenêtres réellement visibles à
  l'écran. Pas corrigé (hors scope de ce chantier, comportement pré-existant) - juste contourné
  en identifiant les fenêtres via `Screen.Forms` + `is TWinPersonnages`/`is TWinCreations`
  plutôt que via cette donnée interne. À garder en tête pour tout futur chantier touchant à
  l'ouverture simultanée de plusieurs personnages : deux fenêtres ouvertes en même temps
  partagent aujourd'hui le même `Personnage` en mémoire.

- **Une grille vide plante `Selection(1, 1)` : poser une garde.** `TabTalentSelection(Self, 1, 1)`
  (`wintalent.pas`) lit `Cells[1, 1]` ; sur une grille qui n'a que la ligne d'en-tête, c'est
  `EGridException "Index out of range Cell[Col=1 Row=1]"`. Cas vécu : `TabAugmentationTalentDblClick`
  ouvrait `TWintTalent` avec le code BRUT d'une ligne à choix multiple (`A/B_*`) ; `WinCharger` filtre
  le catalogue par ÉGALITÉ STRICTE sur ce code, ne trouve rien, et la grille reste à une ligne. Corrigé
  par une garde (la branche ne s'exécute plus si le code contient `SeparateurMulti`). Plus généralement,
  quand on recopie une forme qui marche, recopier aussi ses gardes (`if Node.Data <> nil` du nœud
  « Au choix », garde `ELEMENT_NODE`, voir 2.77).
- **Le sélecteur de spécialisation exige un `_*` LITTÉRAL dans le code.** Deux gardiens testent
  `Pos(ValeurGenerique, Code) > 0` (ou `ListeTalent(Code).Count > 0`, qui ne renvoie rien sans `_*`) :
  `TabAugmentationTalentDblClick` (`winpersonnage.pas`, talent auto-accordé par la carrière) et
  `TabTalentSelection` (`wintalent.pas`, talent ajouté à la main). Un talent à spécialisation saisi sans
  `_*` (dans son `<Talent id>` ET dans la référence de carrière) n'affiche donc aucune spécialisation, sans
  message. Modèle à suivre : `RULES-T0012_*` (Bless), pas `NATIO-T0014` (Kenjutsu, qui ne partage que la
  forme des stubs).
- **Un dossier Windows à espace final est tronqué en silence par `CreateDir`**, mais pas à l'ouverture
  d'un fichier : toute écriture réutilisant la chaîne avec l'espace échoue ensuite en « chemin introuvable ».
  Cas vécu : nom de personnage terminé par un espace, dossier créé vide, puis `ReadXMLFile('')` plantait
  (`try…finally` sans `except`) à CHAQUE démarrage, le rescan de `ChargerPersonnages` retombant dessus.
  Parades : `Trim` de tout nom avant de le mettre dans un chemin ; vérifier le booléen retourné par la
  fonction d'écriture ; ignorer un dossier sans XML dans le rescan.
- **Un chemin construit à la main doit passer par `ConstCheminPersonnage`** : la vérification « nom déjà
  pris » de `wincreation.pas` testait `GetCurrentDir + nom` et ne pouvait donc presque jamais se déclencher
  (à corriger, voir `A FAIRE.txt`).
- **Une référence de mise en page prise en pixels trop tôt est fausse.** La LCL peut remettre à l'échelle DPI
  entre la fin de `FormCreate` et le premier affichage réel (WinArmure est dessinée en 144 PPI, les autres en
  120). Capturer la référence au premier passage réel de la procédure d'ajustement (`FenetreInitialisee` dans
  `TMenu`), ou la stocker en unités à 96 PPI et la reconvertir avec `Form.PixelsPerInch` à chaque
  `Appliquer` (`ancrageproportionnel.pas`, voir 2.64).
- **Une union « est-ce une arme » ne se recopie pas** : utiliser `TypeEquipMetierArme` (`chargeconstantes.pas`,
  calculée dans `warhammersource.pas`) au lieu de `TypeEquipCC+','+TypeEquipCT+','+TypeEquipMU`. Dans
  `GetTypeMetierEquipement`, un préfixe non listé tombe dans `else` (Divers) : lister les préfixes
  explicitement (`EquipementTR`) pour qu'un nouveau ne passe pas inaperçu.
- **PowerShell : indexer un scalaire donne un CARACTÈRE** (`$ids[0]` sur une chaîne), pas le premier élément
  d'un tableau à un élément. Forcer `@(...)` avant d'indexer, et pour tout script de substitution en masse
  imprimer et relire un aperçu « ancien -> nouveau » avant d'écrire.
- **Diagnostic d'un écran qui affiche 0, vide ou un libellé générique non résolu** : chercher d'abord une
  valeur en dur SANS préfixe `RULES-` passée à une fonction `Cherche*` ou `CompareRechercheValeur`
  (`VerifieRecherche` est strict depuis le 06/09/2026). Cette classe de bug n'est pas garantie épuisée.
- **Un diagnostic par traces temporaires** (un fichier écrit à deux endroits, comparés) a localisé un bug que
  la seule lecture du code n'avait pas trouvé (astérisques dupliquées, voir 2.102) ; les retirer ensuite.
- **Un composant maison doit vivre dans un paquet, et le projet doit le necessiter** : le fichier `.lfm` d une fenetre qui l utilise ne s ouvre dans l IDE que si le paquet est installe (erreur « classe introuvable, pas enregistree via RegisterClass »). Piege cumule le 09/10/2026 : (1) un vieux `.ppu` reste dans `lib/x86_64-win64/` du projet apres le deplacement du .pas vers le paquet et masque le paquet : lazbuild compile « avec succes » une version perimee, d ou des tests A/B sans effet ; supprimer le `.ppu`/.o orphelin et verifier la date du `.ppu` du paquet ; (2) un enregistrement du projet par l IDE peut effacer la dependance ajoutee a la main dans le `.lpi` ; (3) `lazbuild projet.lpi` ne recompile pas un paquet modifie : compiler d abord `lazbuild paquet.lpk`.
- **Dessin d un TGraphicControl** : LCL pose l origine du DC a la position du controle ; la remettre a 0 au lieu de la restaurer decale tout ce qui se dessine apres.

---


## Pieges de code dupliques (ex PIEGE-A-GARDER de A_FAIRE.xml)

- Rendu des armes DUPLIQUE Normal/Feldo2P (PdfPersonnageCreation et PdfBlocArmesDonnees) ; bloc Talents AUSSI duplique (PdfPersonnageCreation ~l.1403 et PdfBlocTalents ~l.3078) : modifier aux DEUX endroits.

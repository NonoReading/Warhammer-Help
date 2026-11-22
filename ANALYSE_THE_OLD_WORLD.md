# Analyse de faisabilite : Warhammer The Old World RPG (Cubicle 7, 2025)

Sources : LIVRES\The Old World\Player's Guide.pdf et Gamemaster's Guide.pdf (extraction pdftotext -layout, 20/11/2026).
Lu : sommaire des 2 livres, creation de personnage (p.12-26), table des carrieres, feuille de perso, debut de la 1re carriere.
NON lu en detail : talents (p.73-81), lores (p.82-88), equipement (p.90-105), magie (p.153-174), Gamemaster's Guide (PNJ, creatures, objets magiques).

## Ce que c'est
Un vrai jeu de role (pas le jeu de figurines), nouvelle edition non-WFRP. Systeme different de la V1/V2/V4/V5.

## Systeme (differences majeures avec nos 4 versions)
- Pas de d100 sous caracteristique : reserve de d10 = valeur de Caracteristique ; reussite si le de <= valeur de Competence. Caracteristiques de 2 a 6, competences de 2 a 6.
- 9 caracteristiques : WS BS S T I Ag Re Fel + Fate (Fate compte comme une caracteristique a la creation).
- 16 competences FIXES, sans specialisations : Melee, Defence, Shooting, Throwing, Brawn, Toil, Survival, Endurance, Awareness, Dexterity, Athletics, Stealth, Willpower, Recall, Leadership, Charm.
- Lores (savoirs) = nouvelle famille de donnees : Academic, Cultural, Enemy, Environment, Magic, Trade (p.82-88).
- Status = 3 paliers (Brass / Silver / Gold) au lieu des niveaux de carriere et de l'argent classique ; pieces = 3 cases cochees selon le Status.
- Resilience = Endurance + armure ; degats > Resilience = Blessure, sinon etat Staggered. Plus de PB / table de blessures.
- Magie : Wind unique par Wizard Level, Casting dice pool, Miscast pool, sorts « Formalised / Memorised ». 8 vents de magie, lores de magie (Battle Magic, Elementalism, Illusion, Necromancy...).
- Progression : XP + Endeavours entre aventures ; les echecs en Endeavour cochent des « ticks » par competence (la feuille de perso a des cases a cocher).

## Creation de personnage (5 etapes, p.12)
1. Origine : Bretonnian, Dwarf, Halfling, High Elf, Wood Elf, Empire (Human). 4 lignes de caracteristiques de depart (Dwarf / Elf / Halfling / Human), +1 a 3 caracteristiques tirees sur un d10 (rejets si doublon). 1 XP bonus si on laisse le hasard decider.
2. Carriere : d100, table par origine (30 carrieres de base dans le Player's Guide, corrige le 20/11 : voir TOW_DONNEES.md). 1 XP bonus si on garde le tirage. Option « Life in Disgrace » (Status plus bas, +1 XP).
3. Contacts : 4 familles (Great and Good, Comrades in Arms, Common Folk, Wanderers and Wastrels), p.56-60.
4. Finitions : details et liens avec les autres PJ.
5. Grim Portent : evenement fondateur du groupe + liens (p.64).
Une carriere donne : Origins admises, Status, Favoured Characteristics (3), bonus +1 a N competences parmi une liste, Lore(s), Trappings, Assets, Contacts, 1 Career Talent. Pas de schema de niveaux de carriere (pas de 1/2/3/4).

## Talents (p.73-81, lu par sondage : ~52 talents, chacun avec « Cost: n XP » et « Requirements: »)
- Cout fixe de 1 a 5 XP, achat unique sauf mention. Pas de niveaux de talent, pas de « max = bonus de caracteristique ».
- Prerequis de 4 sortes : caracteristique minimale (« Strength 5+ »), origine (« Bretonnian (Human) Origin »), lore, talent, objet (« Musician's Gear »). Combinables.
- Un talent « Wizard » achete plusieurs fois = niveau de Wizard Level (exception a l'achat unique).
- Chaque carriere donne 1 Career Talent propre (texte long, p.26-55), plus des Talents d'origine.
- Effets : texte libre de regles (+dés, Glorious/Grim, rerolls). Aucun pourcentage a coder comme effet ; une partie seulement est calculable (ex. Resilience).
- Donc le modele XML talent existant (prerequis par talent/competence/caracteristique) est assez proche ; il faut ajouter : prerequis d'origine, de lore, d'objet.

## Avancement (p.66)
- 1 XP par seance (+1 a la discretion du MJ). Caracteristique +1 = XP egale a la nouvelle valeur (-1 si Favoured Characteristic de la carriere). Maximum par origine (tableau p.66).
- Competences : plus d'XP. Elles montent par Endeavours : chaque de rate cree un tick, quand les ticks depassent le rang la competence monte de +1. A suivre par competence dans le perso (champ nouveau).
- Lore : Endeavour « Study Lore ». Statut/carriere : Endeavour « Change Career ».

## Magie (p.153-174, lu : principes et miscasts ; PAS lu : les sorts par lore)
- Seulement avec le talent Wizard ; son Level = max de la Miscast Pool avant debordement. Un seul « sort » par Lore de magie a connaitre + Wizard Level.
- Sort = CV (nombre de reussites), Target, Range, Duration, Potency (= reussites du dernier jet). Casting Test = test Willpower « Exacting » (plusieurs actions).
- Miscast Pool : chaque 9 obtenu s'ajoute ; si pool > Wizard Level, jet de tous les des + table de miscast (1-38+, p.159). Armure ou bouclier = test Grim.
- Sorts « Formal » (grimoire / memorises) ou improvises ; 4 lores de combat (Battle Magic, Elementalism, Illusion, Necromancy) ; 8 vents.
- Pour le projet : donnees de sorts a 5 champs (CV, Target, Range, Duration, effet) + la table de miscast (38 entrees) ; l'etat « miscast pool » et les effets durables de miscast sont des champs de feuille.

## Sorts par lore (p.160-174, LUS en entier le 20/11)
- 4 lores de magie dans le Player's Guide, 42 sorts formels : Battle Magic 10, Elementalism 11, Illusion 10, Necromancy 11. (Les 8 vents, High / Dark Magic et les lores des autres origines sont decrits sans liste de sorts.)
- Fiche d'un sort : nom, CV (1 a 5, un cas « Varies »), Target (Creature / Zone / Object / Self / Corpse / « Potency Zones »...), Range (Self / Close / Short / Medium / Long), Duration (Instant / Immediate / Battle / Potency turns / Potency Days / Until sunrise / Permanent / Varies), Effect = texte libre avec formules (« 5+Potency Damage », « Speed Fast »).
- Valeurs non standard a prevoir comme texte libre : Target « Handful of arrows », « Potency undead creatures », « A spirit whose name you know » ; Range « - » (Seance) ; Duration « Varies ».
- Sorts improvises : pas de liste, une table commune de CV par palier (Petty 2 / Cardinal 4 / Advanced 8 / Master 12+, requis Wizard 1 a 4) + une table de modificateurs (+1 portee, +2, +3, double) + des exemples par lore (Creation / Control / Divine). Formaliser un sort improvise divise sa CV par 2 (Endeavour Formalise Spell).
- Sorts de depart du perso (VERIFIE p.27 et p.37) : seules 2 carrieres de base donnent de la magie, via leur Career Talent. Arcane Wizard (Silver ; origines Bretonnian / High Elf / Empire) : Wizard Level 1 + grimoire avec 3 sorts de la Magic Lore choisie, +1d a l'Endeavour Formalise Spell. Hedge Wizard (Brass ; Bretonnian / Empire / Wood Elf) : Wizard Level 1 + 3 sorts memorises de la Magic Lore choisie, SANS grimoire, +1d a Memorise Spell. Dans les deux cas le joueur CHOISIT les 3 sorts ; pas de tirage. Autres carrieres (Priest etc.) : non verifie.
- Format d'une carriere (fiche a 2 colonnes, identique pour les 26) : Origins, Status (Brass/Silver/Gold), Favoured Characteristics (3), Skill Bonuses (+1 a 4 parmi une liste de 6), Lore (avec choix), Trappings, Assets (avec choix), Contacts (2 familles), Career Talents (nom + texte). Les listes « choisir un » sont du texte a parser, pas des codes.
- Renvois vers le Gamemaster's Guide (Corruption p.128, Skeleton warrior p.128) : donnees de PNJ / creatures hors perso.
- Mapping donnees : 1 sort ~ 7 champs, tres proche du modele sort existant du projet (CV ~ niveau, Range, Duration, Effect) ; ajouter Potency comme notion (pas stockee).

## Gamemaster's Guide (lu par sondage le 20/11 : structure, profils de PNJ, Corruption, objets magiques ; PAS lus : fiches des PNJ nommes, Dark Threads, creatures une a une)
- Livre surtout narratif / outils de MJ (ville de Talagaad, Grim Portents, Dark Threads, evenements, aventures). Peu de donnees de personnage joueur. Chapitres : I Introduction, II Contacts (PNJ nommes), III Etre MJ, IV Evenements, V Corruption, VI Objets magiques, VII Allies et antagonistes (PNJ, creatures, 4 types), p.138+ bestiaire par faction.
- Hors perimetre perso : Dark Threads, Grim Portents du MJ, evenements, PNJ, bestiaire. Un WinLivre TOW pourrait les stocker, mais pas WinCreation.
- Profils de PNJ (p.91) : WS BS S T I Ag Re Fel (sans Fate), Speed (Slow / Normal / Fast), Resilience (« 4 (armoured) » = armure ignorable), Type (Minion / Brute / Champion / Monstrosity), Skills (Default X + exceptions), Attacks (Range, des/cible, Dam, 1H/2H, traits), Protection (Athletics ou Defence en des/cible), capacites speciales, Typical Trappings, et pour Brute / Monstrosity un bloc d'effets selon le nombre de Blessures (0 / 1-2 / 3). Minion = vaincu au 1er Wound ; Brute / Monstrosity = plusieurs Wounds sans table ; Champion = table de Blessures comme un PJ. Format ressemble a un « bestiaire V4/V5 » (WinLivre creature) mais avec des champs nouveaux (Type, Default Skill, Protection, blocs par Wounds).
- Corruption (p.70-79) : etat suivi par perso = Vulnerable -> Tarnished -> Tainted -> Damned. Exposition quotidienne : test Willpower avec malus -1d / -2d / echec auto selon la gravite (Subtle / Profane / Ruinous / Soul-Searing). Chaque « Path » (Child of the Forest, Blood Must Flow, Secrets of Sorcery, Dark Obsession...) donne des BOONS permanents avec contrepartie (ex. Armoured Hide +1 Resilience, Bulging Muscles +2 Strength, Unnatural Alacrity attaque supplementaire, tous Casting Tests Glorious mais chaque 9 = 2 des de Miscast). Un Damned devient PNJ apres une derniere seance. Pour le projet : un champ « etat de corruption » + une liste de boons et de contreparties par path, effets partiellement calculables (+Resilience, +Strength) et le reste en texte.
- Objets magiques (p.81-88) : traites comme des Assets, non achetables. Fiche d'arme magique : nom, texte, Max Range ou Optimum Range, Damage (« S+2 », « 6 »), 1H/2H, Traits en texte. Exemples : Dragon Bow, Duellist Blades, Headsman's Axe, Grotargg's Hammer, Morning Star of Fracasse ; aussi objets arcanes (Book of Ashur, Crystal Ball, Dispel Scroll, Staff of Power, Wyrdstone (consommable, ajoute des des a la Miscast Pool), Ring of Taal...). Les effets sont du texte libre.
- Renvois utiles pour la magie du Player's Guide : Corruption p.128 PDF (necromancie), Skeleton warrior p.128 (PDF) = stat block cite par le sort Raise the Dead.

## Ce que ca demanderait au projet
- Une 5e/6e famille de regles « WFRPTOW » : nouveau code de version dans l'INI, dans chargeconstantes.pas, wincreation.pas, winpersonnage.pas, warhammersource.pas, winlivre.pas, pdfpersonnage*.pas, chargecoutxp.pas, xmlexportimport.pas (70 occurrences de WFRP5 dans 10 .pas a revoir, comme repere de portee).
- Schema XML (XSD) : nouvelles balises pour Lore, Status, Origine -> caracteristiques de depart, Favoured Characteristics, Skill Bonuses « +1 a 4 parmi », Assets, Contacts, Grim Portent, Endeavours, Wizard Level / Miscast.
- WinCreation : phases a repenser (origine -> +1 d10 x3 -> carriere d100 -> contacts -> finitions -> grim portent). Le hasard des 3 +1 est une mecanique nouvelle.
- WinPersonnage : pas de tables de competences a pourcentage ; reserve de des, ticks d'Endeavour, Resilience, Status.
- PDF : feuille officielle de 2 pages existante (sa structure est decrite p.14-15 du Player's Guide) ; il faudrait un PDF a part (comme PDF V5).
- Donnees : ~26 carrieres, 6 origines, ~16 competences, ~ talents (p.73-81), lores, trappings, sorts. Volume plus petit que les livres V4/V5, mais saisie a refaire entierement (aucune reutilisation directe des donnees WFRP).
- Livres : seulement l'anglais (pas de traduction FR, cf. regle du projet).

## Reutilisable
- Moteur de scripts d'ecran, WinLivre (arbre + fiches), mecanisme livre/mod, XSD, PDF par gabarit, tests --dump / --dumppdf.
- Structure « origine + carriere + hasard + XP bonus » proche de WFRP4/5 dans l'esprit, mais les tables sont a refaire.

## Estimation honnete
Gros chantier, comparable a l'ajout d'une version complete (type V5) : le systeme de des et de competences fixes est incompatible avec le modele %-sous-caracteristique du projet. Ce n'est pas un ajout de livre. A decider avec Nono s'il vaut le cout, et dans quel ordre par rapport a WinLivre V1 (derniere etape).

## Reponses de Nono (20/11/2026)
1. Seuls Player's Guide et Gamemaster's Guide existent (confirme : seuls ces 2 PDF dans LIVRES\The Old World).
2. Creation de personnage seulement pour l'instant.
3. Mode TOW dans les fenetres existantes (plus lourd, accepte) : une fenetre de creation (WinCreation) et une de gestion des personnages (WinPersonnage), pas de nouvelles fenetres.

## Questions ouvertes pour Nono (traitees ci-dessus)
1. Tous les livres de la gamme TOW ou seulement Player's + Gamemaster's ?
2. Objectif : creation de perso seule (comme V5) ou aussi WinLivre complet ?
3. Version a part (V6) ou mode a part dans WinCreation ?

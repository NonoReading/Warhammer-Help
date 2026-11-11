# Gabarit de reference pour saisir un nouveau livre (BOOK_*.Xml)

Ce fichier n'est PAS un des trois fichiers de suivi (CONTEXT.md/Log.txt/A FAIRE.txt) : c'est
une reference technique de structure XML, a consulter avant de saisir un nouveau livre au lieu
de rouvrir un livre existant pour retrouver le format a chaque fois. Extension .md volontaire
(pas .Xml) pour ne jamais etre charge comme un livre par le programme.

A METTRE A JOUR si un bloc DATA_* nouveau est rencontre, ou si un champ change de convention.

## En-tete obligatoire de tout BOOK_*.Xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<DATA_BOOK>
<CODE_BOOK>"XXXX"</CODE_BOOK>
<BOOK>"BOOK NOM EN MAJUSCULES SANS PONCTUATION"</BOOK>
<language>"ENGLISH"</language>
<VERSION>"WFRP4"</VERSION>
<OFFICIAL>"1"</OFFICIAL>       <!-- 1 = Cubicle7 officiel, 2 = fan/Community Content -->
<COMPLETE>"1"</COMPLETE>       <!-- 0 tant que la saisie n'est pas finie -->
<REVISION>"AAAAMMJJ"</REVISION>  <!-- facultatif, ecrit par WinLivre (Publier une revision) ; distinct de VERSION -->
<REVISION_LABEL>"Texte libre"</REVISION_LABEL>  <!-- facultatif, libelle saisi a la publication, juste apres REVISION -->
<DISCLAIMER>"..."</DISCLAIMER> <!-- A NE JAMAIS OUBLIER (rate deux fois de suite, 26/09/2026) :
     copier le texte exact de la page de copyright du livre source (page 2 en general,
     "No part of this publication may be reproduced..." + "(c) Copyright Games Workshop
     Limited [annee]..."). Un livre existant qui n'en a pas est un oubli a corriger, pas
     un exemple a suivre. -->
<DATA_LABEL>
<Label language="ENGLISH">
<Text name="XXXX-BOOK NOM EN MAJUSCULES SANS PONCTUATION">"Titre affiche"</Text>
</Label>
<Label language="FRANCAIS">
<Text name="XXXX-BOOK NOM EN MAJUSCULES SANS PONCTUATION">"Titre affiche"</Text>
</Label>
</DATA_LABEL>
... blocs DATA_* du contenu ...
</DATA_BOOK>
```

- `CODE_BOOK` : prefixe court unique (4-6 lettres), reutilise devant chaque id (`XXXX-...`).
- Le nom du fichier peut avoir des underscores OU des espaces (les deux existent deja dans
  DATABASE/WFRP4) ; la valeur de `<BOOK>` doit correspondre exactement a l'entree ajoutee dans
  `INI.TXT` (cle `BOOKWFRP4=`, liste `[BOOK ...]` concatenee sans separateur) pour que le livre
  soit cochable dans le menu.
- Pas d'apostrophe dans `<BOOK>`/`CODE_BOOK` (aucun livre existant n'en a).

## DATA_SPELL (sorts)

```xml
<DATA_SPELL>
<Sort id="XXXX-CODE_01">
<Description language="ENGLISH">"Nom du sort"</Description>
<Explanation language="ENGLISH">"Texte integral en anglais, guillemets internes sans echappement particulier."</Explanation>
<Target>"1"</Target>                    <!-- ou "You", "AoE (BATTR_WP)m", "AoE (ATTR_WP) miles" -->
<Duration>"Instant"</Duration>          <!-- ou "(BATTR_WP) Rounds/minutes/hours", "(ATTR_WP) days", "Special" -->
<Range>"Touch"</Range>                  <!-- ou "You", "(ATTR_WP)m" -->
<Talent>"RULES-T0088_XXX"</Talent>      <!-- Talent qui donne acces (Domain Magic) ou RULES-T0089 (Minor Magic) -->
<Level>"3"</Level>                      <!-- Casting Number (CN) du livre -->
<TypSpell>"Domain Magic"</TypSpell>     <!-- ou "Minor Magic" pour les Petty Spells -->
</Sort>
</DATA_SPELL>
```

- `(ATTR_WP)` = valeur pleine de Volonte, `(BATTR_WP)` = Bonus de Volonte (meme logique pour
  les autres caracteristiques : `ATTR_S`, `BATTR_S`, etc., a verifier au cas par cas).
- Les 8 Lores arcaniques du Rulebook ont deja leur Talent, pas besoin d'en creer :
  `RULES-T0088_BETE` (Beasts), `RULES-T0088_MORT` (Death), `RULES-T0088_FEU` (Fire),
  `RULES-T0088_CIEUX` (Heavens), `RULES-T0088_METAL` (Metal), `RULES-T0088_VIE` (Life),
  `RULES-T0088_LUMIERE` (Light), `RULES-T0088_OMBRE` (Shadows). Pour une Lore qui n'existe nulle
  part encore (culte, domaine specifique), creer un Talent de **specialisation** dedie (voir
  `DATA_TALENT_SPECIALIZATION` ci-dessous, PAS `DATA_TALENT`) et y rattacher les sorts, **avec
  un id `RULES-T0088_XXX`** (jamais le prefixe du livre courant) : le prefixe de livre est
  retire avant toute comparaison de regroupement (`CodeSansLivre`), donc il ne protege
  d'aucune collision ; seul le code apres le livre (`T0088`) identifie la famille, dans les
  DEUX mecanismes qui en dependent (calcul XP via `<Generique>`, ET classification
  liste-maitre/popup via le bloc XML parent - voir juste en dessous). Bug trouve et corrige le
  28/09/2026 sur 9 talents (HORNE-T0197/198/199, GRIM-T0203/204/205/206, TRIBE-T0207/208) :
  saisis a tort dans `DATA_TALENT`, ils apparaissaient comme des Talents independants dans
  WinTalents au lieu de rejoindre le popup de choix de specialisation. Detail dans CONTEXT.md §4.
- Petty Spells : `Talent = "RULES-T0089"`, `TypSpell = "Minor Magic"`.

## DATA_TALENT (nouveau talent INDEPENDANT, PAS une specialisation)

```xml
<DATA_TALENT>
<Talent id="XXXX-T0000">
<Attribut>""</Attribut>
<Description language="ENGLISH">"Nom du talent"</Description>
<Short language="ENGLISH">""</Short>
<Explanation language="ENGLISH">"Texte integral."</Explanation>
<Skill>""</Skill>
<Max>"1"</Max>
<PDF>""</PDF>
<Test language="ENGLISH">"Attribut ou competence testee, ou vide"</Test>
</Talent>
</DATA_TALENT>
```

## DATA_TALENT_SPECIALIZATION (specialisation d'un talent generique existant)

**A utiliser des qu'un talent est une variante/domaine d'un talent generique deja en base**
(Arcane Magic (Domaine), Bless (Dieu), Vice (Type), Rune Magic (Type), etc.) - JAMAIS
`DATA_TALENT` pour ce cas, meme si le talent generique lui-meme vient d'un autre livre. Ce bloc
ne charge que `Description` et `Generique` (xmlexportimport.pas ~l.1785-1848) - pas de
`Attribut`/`Explanation`/`Skill`/`Max`/`PDF`/`Test` : si le livre source a un texte de saveur,
le garder en commentaire XML juste au-dessus de l'entree plutot que de l'inventer un champ.
Une entree ici est invisible dans la liste maitre de WinTalents (winpersonnage.pas/wintalent.pas
filtrent `SousTalent = false`) : elle n'apparait que via le popup de choix de specialisation
du talent generique, exactement comme les 8 Lores du Rulebook.

```xml
<DATA_TALENT_SPECIALIZATION>
<Talent id="RULES-T0088_XXX">
<Description language="ENGLISH">"Arcane Magic (Nom du domaine)"</Description>
  <!-- Texte de saveur du livre source, garde en commentaire (non charge par ce bloc). -->
<Generique>"RULES-T0088_*"</Generique>
</Talent>
</DATA_TALENT_SPECIALIZATION>
```

## DATA_CAREER (nouvelle carriere)

```xml
<DATA_CAREER>
<Career id="XXXX-WORKnnn">
<Description language="ENGLISH">"Nom de la carriere"</Description>
<Explanation language="ENGLISH">"Texte integral."</Explanation>
<Skill>"RULES-COMPCOMB_BASE"</Skill>   <!-- competence "signature" utilisee ailleurs -->
<Class>"RULES-CLASS_WARR"</Class>     <!-- classe (Warrior, Academic, Rogue, etc.) -->
<SUBCHAPTER_LEVEL>
<Level id="1">
<Description language="ENGLISH">"Nom du niveau 1"</Description>
<Salary>"TIERS_BRASS 1"</Salary>
</Level>
<!-- Level id="2", "3", "4"... -->
</SUBCHAPTER_LEVEL>
<SUBCHAPTER_ATTR>
<Attribut name="RULES-ATTR_WS">"1"</Attribut>
<!-- une ligne par caracteristique, valeur = nombre d'avancees offertes -->
</SUBCHAPTER_ATTR>
<SUBCHAPTER_SKILL>
<Skill name="RULES-COMPXXX">"1"</Skill>
  <!-- commentaire = nom anglais de la competence, niveau = numero du Level qui la debloque -->
</SUBCHAPTER_SKILL>
<SUBCHAPTER_TALENT>
<Talent name="RULES-T0000">"1"</Talent>
  <!-- idem, "/" pour un choix ("RULES-T0096/RULES-T0121"), "_*" pour une famille -->
</SUBCHAPTER_TALENT>
<SUBCHAPTER_ITEM>
<Item name="Nom de l'objet ou code RULES-...">"1"</Item>
  <!-- niveau qui debloque l'objet ; repeter la ligne = plusieurs exemplaires -->
</SUBCHAPTER_ITEM>
</Career>
</DATA_CAREER>
```

### Equipement generique d'une carriere (« une arme au choix »)

Une ligne `Item` de `SUBCHAPTER_ITEM` peut etre un objet precis ou un choix. Trois formes pour les armes :

| Ligne `Item name=` | Sens pour le joueur | Condition |
|---|---|---|
| code d'une arme (`RULES-COMB_SWORD`) | cette arme | la fiche `Weapon` existe |
| code de competence de combat (`RULES-COMP_MELEE__BASIC`, `RULES-COMP_RANGED__BOW`) | une arme de cette competence | les armes portent cette competence dans leur `Skill` ; les munitions sont exclues |
| `..._*` de competence (`RULES-COMP_MELEE__*`) | une arme de n'importe quelle specialisation de cette famille | idem |
| `RULES-COMB_*` / `RULES-PROJ_*` (ancien joker) | n'importe quelle arme (corps a corps / tir), choisie par prefixe de code | exige une fiche `Weapon id="RULES-COMB_*"` : son `Description` est le libelle affiche (« Melee Weapon (Any) ») ; a ne creer que si aucune competence ne convient |

Preferer le code de competence : le libelle vient de la competence et aucune fiche factice n'est a creer. Dans WinLivre le choix se fait dans une liste de libelles ; le code reste dans le XML (la liste ne propose pas encore la forme `__*`, qui se saisit a la main pour l'instant).

## Autres blocs deja rencontres (a detailler ici la prochaine fois qu'on les utilise)

`DATA_WEAPON`, `DATA_ARMOR`, `DATA_TRAPPING`, `DATA_CAREER_SPECIE` (rattacher une
carriere a une Race entiere), `DATA_SPECIE_CAREER_CHOICE`, `DATA_SKILL`, `DATA_RACE`,
`DATA_SPECIE`, `DATA_NATION`, `DATA_SPELL_TALENT`. Liste complete des DATA_* existants :
voir `grep -hoE "^<DATA_[A-Z_]+>" DATABASE/WFRP4/*.Xml | sort -u`.

## Conventions de codes (a lire avant de saisir quoi que ce soit)

- **Identifiant** = `<CODE_BOOK>-<TYPE>_<n>` : `PARRA-RACE_HPARR` (ethnie), `PARRA-TRAP_001` (objet), `LUSTR-WORK123` (carriere), `NATIO-T0017` (talent). Le prefixe est celui du livre qui DEFINIT la fiche.
- **Exception** : une specialisation d'un element du Rulebook garde `RULES-` meme dans un autre livre (`RULES-COMPLANG_STRIG`, `RULES-T0088_XXX`) ; seul le code apres le prefixe identifie la famille.
- **Separateurs** : `/` = au choix (`RULES-T0103/RULES-T0078`), `_*` = une specialisation a choisir (`RULES-COMPCHEV_*`), `RULES-T*` = talent aleatoire, `,` = liste (`SpellTypes`, talents d'un trait).
- **Libelles** : tout texte affiche est un `Text name="..."` de `DATA_LABEL` ou de INTERFACE.Xml ; les champs ne portent que le code (`RULES-LAB_193`).
- **Races et ethnies, vocabulaire inverse** : `DATA_SPECIE` = les ETHNIES (`RULES-RACE_HUM`), son champ `Ethnic` = la RACE (`RULES-SPECIE_HUMAN`) ; `DATA_RACE` = les races.
- **Guillemets** : le texte d'une balise est entre guillemets doubles litteraux, `<Max>"1"</Max>`, sauf `<Page>` (`<Page>38</Page>`).
- **`<Page>`** : page du livre anglais source, `"45-46"` pour plusieurs pages ; sert d'affichage quand le texte est absent (version sans licence).

## DATA_SPECIE (ethnie), modele : BOOK_PARRAVONESE_STRIGANY_SIGNALLER.Xml

```xml
<DATA_SPECIE>
<Specie id="PARRA-RACE_HPARR">
<Description language="ENGLISH">"Humans (Parravonese)"</Description>
<Explanation language="ENGLISH">"Texte du livre."</Explanation>
<Ethnic>"RULES-SPECIE_HUMAN"</Ethnic>          <!-- la RACE -->
<SUBCHAPTER_ATTR>
<Attribut name="RULES-ATTR_WS">"2d10+20"</Attribut>   <!-- une ligne par caracteristique -->
<Attribut name="RULES-ATTR_Fate">"2"</Attribut>
<Attribut name="RULES-ATTR_Wound">"1xBATTR_S+2xBATTR_T+1xBATTR_WP"</Attribut>
</SUBCHAPTER_ATTR>
<SUBCHAPTER_SKILL>
<Skill>"RULES-COMPSOINANI"</Skill>             <!-- pas d'attribut name ici -->
<Skill>"RULES-COMPCHEV_*"</Skill>              <!-- Ride (Any) : choix a la creation -->
</SUBCHAPTER_SKILL>
<SUBCHAPTER_TALENT>
<Talent>"RULES-T0103/RULES-T0078"</Talent>     <!-- A ou B -->
<Talent>"RULES-T*"</Talent>                    <!-- un talent aleatoire par ligne -->
</SUBCHAPTER_TALENT>
<SUBCHAPTER_CAREER>
<Career name="RULES-WORK02">"1"</Career>       <!-- poids dans le d100 ; X = hors tirage ; - = non tirable -->
</SUBCHAPTER_CAREER>
<Page>1</Page>
</Specie>
</DATA_SPECIE>
```

Les poids de `SUBCHAPTER_CAREER` totalisent 100 par ethnie ; les fourchettes ne se saisissent jamais. Race du Rulebook : copier les caracteristiques de `RULES-RACE_HUM` quand le livre n'en donne pas.

## DATA_TRAPPING (objet divers)

```xml
<DATA_TRAPPING>
<Trapping id="PARRA-TRAP_001">
<Description language="ENGLISH">"Signal Tower"</Description>
<Theme>"RULES-LAB_193"</Theme>      <!-- Tools and Kits ; liste des codes dans le XSD -->
<Availability>"RULES-DISPO_COMMON"</Availability>   <!-- facultatif -->
<Price>"3PA 2SB"</Price>            <!-- facultatif : CO, PA, SB -->
<Encumbrance>"0"</Encumbrance>
<Page>2</Page>
</Trapping>
</DATA_TRAPPING>
```

## DATA_SKILL_SPECIALIZATION

```xml
<DATA_SKILL_SPECIALIZATION>
<Skill id="RULES-COMPLANG_STRIG">
<Description language="ENGLISH">"Language (Strigany)"</Description>
<Generique>"RULES-COMPLANG_*"</Generique>
<Page>124</Page>
</Skill>
</DATA_SKILL_SPECIALIZATION>
```

Jamais dans `DATA_SKILL` : une competence qui a un `Generique` y serait une competence independante.

## Blocs de carriere et de tirage

Voir les annotations `xs:documentation` de `SCHEMA_WFRP4.xsd` et `SCHEMA_COMMON.xsd` : `DATA_CAREER_SPECIE`, `DATA_CAREER_ROLL`, `DATA_CAREER_SUBCHOICE`, `DATA_SPECIE_CAREER_CHOICE`, `DATA_CAREER_BONUS`, `DATA_CAREER_ADAPTATION`, `DATA_CLASS_ITEM`, `DATA_SPECIE_TRAIT`, `DATA_RANDOM_TALENT`, `DATA_RANDOM_SPECIE`, et les effets (`ModifyCarac`, `ModifySkill`...).

## Pieges connus (voir aussi A FAIRE.txt "REGLES DE METHODE")

- Les commentaires XML `<!-- ... -->` a l'interieur d'un bloc peuvent faire planter le parseur
  ou dupliquer une entree sur certains blocs (DATA_LABEL, DATA_SPECIE_CAREER_CHOICE,
  DATA_SKILL_SPECIALIZATION touches, DATA_ROLL non confirme) : mettre le commentaire de synthese
  AVANT le bloc `<DATA_...>`, pas a l'interieur, sauf sur les blocs deja verifies surs
  (DATA_RACE, DATA_RULE, DATA_CAREER_ROLL, DATA_CAREER_SPECIE, DATA_TALENT,
  DATA_CAREER, DATA_SPELL - tous utilises avec commentaires inline dans les livres existants).
- WinLivre ne sait pas editer `DATA_SPELL_TALENT` : saisie XML a la main uniquement.

## BOOKNAME

Tout nouveau livre porte `<BOOKNAME>` (nom d affichage sans BOOK, sous `<BOOK>` dans l en-tete). `<BOOK>` reste la CLE des personnages, de l INI et des Text ; BOOKNAME n est lu que par XmlNomAffichageLivre, en repli quand aucun libelle traduit n existe (grille Livres du menu, racine de WinLivre).

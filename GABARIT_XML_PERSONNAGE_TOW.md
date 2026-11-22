# Gabarit : XML d'un personnage The Old World (WFRPTOW)

Un perso TOW est ecrit et lu par le moteur commun (`PersonnageXmlCreation` / `PersonnageXmlChargement` de
`chargepersonnage.pas`), comme V1/V2/V4/V5. Depuis la suite 299 il n'y a plus de type `TPersonnageTow` ni de
`chargepersonnagetow.pas` : la creation et les fenetres TOW travaillent directement sur `StructurePersonnage`
(atouts et contacts = `LignesTow`, sorts = lignes d'equipement de type sort ; aides `TowAjouteLigne` / `TowAjouteEquip` /
`TowAjouteSort` dans `chargecreationtow.pas`). Il n'y a plus de format a part
ni de lecture de l'ancien format (`<PLAYER><CHAPTER_ATTR>`, table rase du 22/11/2026).

Test : `WarhammerHelp.exe --tow <dossier sortie> <fichier.xml>` ecrit `<nom>.txt`, `<nom>.reecrit.xml`, `<nom>.relu.txt`
(les deux .txt doivent etre identiques).
Exemples : `TRAVAIL\TOW\perso_test_tow.xml`, `TRAVAIL\PERSOS_TEST\WFRPTOW\TEST Priest TOW\*.xml`.

```
PLAYER
├── Name / Specie (origine) / Career / Xp / CurrentXp / HeightUnit ...        (balises communes)
├── StatusTow (BRASS|SILVER|GOLD) / StatusLevelTow / FateTow (depart) / FortuneTow (courante)
├── WizardLevelTow / GrimPortentTow / NotesTow                                (ecrits seulement si non vides / non nuls)
├── CHAPTER_CREATION
│   ├── SUBCHAPTER_ATTR            <Attribut name="RULES-ATTR_WS">"3"</Attribut>      (9 caracteristiques, pas de %)
│   ├── SUBCHAPTER_SKILLSPECIE     <Skill name="RULES-COMP_MELEE" ticks="1">"2"</Skill>   (16 competences, rang en valeur)
│   └── SUBCHAPTER_TALENT          <Talent name=".." choice=".." source="origin|career">"1"</Talent>
├── CHAPTER_ITEM
│   ├── SUBCHAPTER_WEAPON / ARMOR / MISC   <Item name=".." text="precision">""</Item>
│   └── SUBCHAPTER_SPELL                   <Item name="RULES-SPELL_.." text="Formalised">"0"</Item>
├── TOW_LINES                      <Line name=".." kind="ASSET|CONTACT" family="..">"texte"</Line>
└── TOW_LORES                      <Lore name="RULES-LORE_..">"precision"</Lore>
```

Qui porte quoi :

| Donnee | Ou | Remarque |
|---|---|---|
| Lore | `TOW_LORES`, `StructurePersonnage.LoresTow` | Un lore est possede ou non : ni rang ni ticks (Player's Guide p.82). `text` = precision (« City Lore » / Talagaad). |
| Ticks d'une competence | attribut `ticks` de `Skill`, `StructurePersonnageCompetence.TicksTow` | Absent si 0. |
| Choix d'un talent | attribut `choice` de `Talent`, `ChoixTow` | Code d'un dieu ou d'une Magic Lore, ou texte libre (Hatred, Honour Bound). |
| Provenance d'un talent | attribut `source` de `Talent`, `SourceTow` | `origin`, `career`... Distinct de `StructurePersonnageTalent.Source` (talents deduits d'une mutation). |
| Precision d'objet, texte d'un sort | attribut `text` de `Item`, `StructurePersonnageEquipement.TexteTow` | Distinct de `QualiteEquipement`, lue comme une liste de qualites. |
| Atouts, contacts | `TOW_LINES` (`kind` ASSET / CONTACT) | Seules lignes qui n'ont pas encore leur champ. |

Aucun calcul derive (Resilience, Wounds, Speed) : seulement PDF / WinPersonnage.
Codes = ceux de `DATABASE\WFRPTOW\BOOK_RULESBOOK.Xml`. Les attributs `choice`, `source`, `ticks` et `text` ne sont ecrits
que s'ils ne sont pas vides, donc le XML de V1/V2/V4/V5 n'est pas modifie.

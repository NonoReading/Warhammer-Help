# Plan de decoupage : Warhammer The Old World (WFRPTOW), creation de personnage

Base : ANALYSE_THE_OLD_WORLD.md + reponses de Nono du 20/11/2026.
Perimetre : Player's Guide + Gamemaster's Guide (les 2 seuls livres), CREATION DE PERSONNAGE SEULEMENT,
mode TOW dans WinCreation et WinPersonnage (pas de nouvelle fenetre), anglais seulement (pas de traduction).
Hors perimetre : WinLivre TOW (a decider plus tard), bestiaire / PNJ / Dark Threads du Gamemaster's Guide.

## Regles de conduite
- Chaque etape est COMPILEE, TESTEE (script d'ecran / --dump) et COMMITEE avant la suivante.
- Avant et apres chaque etape qui touche du code partage : `python TRAVAIL/tester_ecran.py --sans-compil` (campagne V1/V2/V4/V5)
  doit rester identique (references TRAVAIL\ECRAN\REFERENCES). Aucune regression V1 a V5 acceptee.
- Le code TOW passe par des switchs sur le code de version, comme V1 dans WinCreation (decision 26/10), jamais par copie de la fenetre.
- Donnees saisies d'apres le livre (TXT d'abord, PDF seulement si besoin), jamais de memoire ; chaque lot est compare au livre.

## Etape 0 : lecture complementaire des sources (aucun code) — FAITE le 20/11, voir TOW_DONNEES.md
(30 carrieres et non 26 ; phase « Final Steps » en plus ; 10 dieux a saisir pour Priest ; 2 points a trancher.)
Non lu a ce jour : talents p.73-81 (seulement par sondage), lores p.82-88, equipement p.90-105, les 26 carrieres une a une,
contacts p.56-60, Grim Portent p.64, tableau des maximums par origine p.66, feuille de perso p.14-15.
Livrable : TOW_DONNEES.md = liste exacte des tables a saisir (nombre de lignes par table) + les cas qui ne rentrent pas.
Sortie : on sait chiffrer le volume de saisie et lever les derniers doutes avant de figer le schema.

## Etape 1 : cadre de version (petit, sans effet visible)
- Nouveau code de version WFRPTOW (INI.TXT VERSION=...), constante dans chargeconstantes.pas, repli propre partout ailleurs.
- Cartographier les ~70 occurrences de WFRP5 (10 .pas) : a chacune, note « TOW pareil / TOW different / TOW sans objet ».
- Un livre vide TOW charge sans erreur ; les 4 versions existantes inchangees (campagne d'ecran).
Test : lancer les 3 programmes avec VERSION=WFRPTOW, aucun plantage, ecrans vides mais affiches.

## Etape 2 : schema XML (XSD) et donnees de base
- Balises : Origin (6) avec caracteristiques de depart, Characteristic (9 dont Fate), Skill (16 fixes, sans specialisation),
  Lore (6 familles), Status (Brass/Silver/Gold), Career (30) avec Favoured Characteristics, Skill Bonuses « +1 a N parmi »,
  Lore, Trappings, Assets, Contacts, Career Talent ; Talent (cout fixe 1-5, prerequis : caracteristique / origine / lore / talent / objet).
- Codes RULES-... pour les donnees choisies (decision 05/11), libelles affiches, jamais les codes.
- Livre TOW saisi par lots : Origines + caracteristiques + competences -> Talents -> Carrieres -> Equipement -> Sorts (42, 4 lores) -> table de miscast.
Test : controle XSD complet (tester_tout.py --xsd) 0 ecart ; relecture lot par lot contre le livre.

## Etape 3 : modele de personnage
- Structure Personnage TOW (XML + objet) : 9 caracteristiques, 16 competences a rang et ticks, Status, Resilience,
  Wizard Level, lores, contacts, Grim Portent. Reserve de d10 : pas de pourcentage.
- Calculs derives (Resilience = Endurance + armure, etc.) seulement sur PDF / WinPersonnage, comme pour les autres versions.
- Lecture / ecriture XML du personnage, --dump TOW (lignes dediees dans warhammersource.pas).
Test : un personnage ecrit a la main en XML se relit et se re-dumpe sans perte.

## Etape 4 : WinCreation mode TOW (le plus gros morceau)
Phases a refaire dans la fenetre existante, une par une, chacune avec son script d'ecran :
 4a Origine (6) + ligne de caracteristiques de depart + 3 tirages +1 d10 (rejet des doublons) + 1 XP si hasard.
 4b Carriere : d100 par origine (table p.26-55) ou choix, 1 XP si tirage garde, option « Life in Disgrace ».
 4c Competences : +1 a N parmi la liste, Lore(s), Career Talent, Trappings, Assets.
 4d Magie de depart : Arcane Wizard / Hedge Wizard seulement (3 sorts a choisir dans la Magic Lore). Autres carrieres : a verifier a l'etape 0.
 4e Contacts (2 familles par carriere).
 4f Finitions et Grim Portent.
Tests : un script par phase, puis creation_hasard TOW sur 5 graines, references --maj-reference, `--dump` compare.

## Etape 5 : WinPersonnage mode TOW (gestion)
- Ouverture / affichage d'un personnage TOW : caracteristiques, competences (rang + ticks), Status, Resilience, talents, sorts, lores.
- Evolution : XP (caracteristique = valeur nouvelle -1 si Favoured), achat de talents (cout fixe + prerequis), Endeavours (ticks par competence).
- Magie : Wizard Level, sorts connus, miscast pool (champ de fiche).
Test : scripts d'ecran personnage_xp_tow, personnage_talent_tow, comme pour V1/V2/V4/V5.

## Etape 6 : PDF
Feuille officielle TOW de 2 pages (Player's Guide p.14-15) : gabarit par superposition comme PDF V5, case « Donnees seules »,
validation par impression sur la feuille officielle (--dumppdf pour verifier, jamais pdftotext).

## Etape 7 : cloture
Tests complets (campagne d'ecran, XSD), mise a jour Log / CONTEXT / A_FAIRE, decision de Nono sur la suite (WinLivre TOW, Corruption, bestiaire).

## Ordre et dependances
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7. Les etapes 4 et 5 ne peuvent pas aller en parallele (le modele de l'etape 3 doit etre stable).
Premiere tranche utile et peu risquee : etapes 0 a 2 (aucune modification de comportement des versions existantes).

## Points a trancher par Nono avant l'etape 1
- Nom de la version dans l'INI (WFRPTOW ou WFRP6).
- Moment de lancement par rapport a WinLivre V1 (derniere etape du projet).

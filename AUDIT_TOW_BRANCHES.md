# Audit des branches `WFRPTOW` (22/11/2026, lecture seule, aucun code touche)

89 occurrences de `WFRPTOW` dans les .pas (hors chargecreationtow.pas), classees en 4 familles.
Critere : la branche **double-t-elle un mecanisme commun V1-V5** (risque de bug « oubli d une ligne »)
ou **ne fait-elle que poser des donnees TOW** (legitime, regle « dans le moule » respectee) ?

## A. DOUBLONS DU CHEMIN COMMUN (a fusionner, par risque decroissant)

| # | Endroit | Ce qui double | Risque |
|---|---------|---------------|--------|
| A1 | `TowSauvegarde` (wincreation.pas:8009) vs `PhaseSaveSauvegarde` (:2493) | Fin de creation : XP, dossier, ecriture XML, rafraichissement menu. **Deja un bug** (RecherchePersonnage oublie, corrige 22/11). A verifier : `Personnage.LivresAcceptes := LivresPersonnages` n est pas pose, `ObjetsPropres` non plus | ELEVE |
| A2 | `TowAssemble` + `TowChoisit*` (chargecreationtow.pas) vs remplissage progressif de `Personnage` par les phases V1-V5 | TOW reassemble le perso d un coup a la fin depuis des tableaux (`TowCompLibres`, `TowLoreChoix`, `TowEqChoix`...) ; V1-V5 le remplissent a chaque phase | ELEVE (tout changement de phase doit etre repete des deux cotes) |
| A3 (CLOS 22/11 : 8 boutons Hasard et 4 double-clics lus, rien de commun reutilisable, « trop complique », voir Log suite 306) | 37 procedures `TWinCreations.Tow*` + sorties anticipees `Exit` : lignes 1529, 1643, 3026, 3244, 3385, 3454, 5185, 5241, 5952, 6018, 6483, 8321, 8844, 9208, 9484, 9542 | Chaque phase (race, carriere, attributs, talents, competences, equipement) a sa branche TOW qui **sort avant** le code commun | ELEVE (le code commun n est jamais exerce par TOW) |
| A4 (CLOS 22/11 : les Verif* de TOW controlent d autres regles que V1-V5, rien a fusionner) | Verifications de fin de phase : wincreation.pas 3775, 3818, 3824, 3840, 3882, 3916 | Les `Verif*` communes sont court-circuitees par `TowEquipComplet`, `TowTalFait`... | MOYEN |
| A5 (CLOS 22/11 : TowMajRecap reutiliser TowPoseTalents / TowPoseCompetences tirerait au hasard et decalerait les tests a graine ; garde son calcul propre) | `TowMajRecap` + `TowInit*` (3701-3716) | Rafraichissement de la page : meme role que `UpdateSheet*` | MOYEN |
| A6 | `warhammersource.pas:3783` (--dump) : « format TOW a part, l ancien chargeur plante » | Contredit :4028 (« le chargeur commun suffit »). Commentaire probablement perime : a verifier et retirer | MOYEN |
| A7 (FAIT 22/11 : mode retire, voir Log suite 307) | Mode `--towcreer` (warhammersource.pas:2375-2440) | Refait la creation en ligne de commande avec `TowAssemble` ; double la fenetre | FAIBLE (outil de test) |

## B. DONNEES / AFFICHAGE SEULEMENT (legitime, a garder)

- winpersonnage.pas : 3528 (codes d attributs vides), 5236 (colonne Bonus = ticks), 5879 (titre), 5937 (race / metier en cours), 5984-5997 (colonnes d attributs, comme V1), 6086 et 6147 (libelles et ticks), 6162 (colonnes cachees), 6368 (categories 6 et 7), 6446 (precision de ligne), 6450 (Assets / Contacts en `LignesTow`), 6617 (pas de boutons d ajout), 4371 (chargement par le chemin commun), 4699.
- winmetier.pas : 1568, 1677, 1812 (image de carriere ; reste « cas special winmetier.pas:1812 » de CONTEXT).
- winraces.pas : 297 (10 colonnes), 909, 1003 (donnees d origine).
- pdfpersonnage.pas:689, chargepersonnage.pas:277, chargeconstantes.pas:580, warhammersource.pas:246.

## C. A TRANCHER AVEC TOI

1. **Fin de creation (A1)** : faire passer TOW par `PhaseSaveSauvegarde` en remplissant `Personnage` (donc supprimer `TowSauvegarde`) ?
2. **Assemblage (A2)** : faire remplir `Personnage` phase par phase comme V1-V5 plutot que `TowAssemble` a la fin ? C est le plus gros chantier (la creation TOW est faite en 8 phases tout autour de ces tableaux).
3. **Garder `--towcreer`** (A7) comme outil de test, ou le remplacer par des scripts d ecran ?

## D. Constat

Les doublons A1-A5 sont tous dans la **creation** (wincreation.pas + chargecreationtow.pas). L affichage
de la fiche (winpersonnage.pas) est deja passe dans le moule : ses branches sont des differences de donnees.
Les bugs de la suite 303 (fiche non ouverte apres creation, Assets / objets) viennent de A1 et A2.

# The Old World : cartographie des tests `ValVersion = 'WFRP5'` (etape 1, 20/11/2026)

Methode : Grep `WFRP5` dans les .pas = 70 lignes, dont ~35 sont des commentaires. Les ~35 tests de code se rangent ainsi.
Verdict : « pareil » = TOW suit la branche WFRP5 ; « different » = TOW aura sa propre branche ; « sans objet » = rien a faire pour TOW.

## Cadre de version (fait)
- Les versions viennent des DOSSIERS de DATABASE\ : un dossier = une version, reconnue des qu'un livre porte OFFICIAL "0" et une balise VERSION (warhammersource.pas ChargerListeVersions). Ajouter WFRPTOW = creer DATABASE\WFRPTOW\BOOK_RULESBOOK.Xml (fait, livre vide) + `LibelleVersion` (« WFRPTOW (2025) », fait). Aucune constante de version dans chargeconstantes.pas : le code de version est la valeur de INI.TXT.
- Dossiers derives de ValVersion : DATABASE\<v>\, SAVED_CARACTERS\<v>\, PICTURES\<v>\NIV\ : suivent tout seuls.

## wincreation.pas (21 tests) : TOW different pour presque tout
- Libelles XP des boutons hasard (759) : different (TOW : pas de XP, sauf +1 XP origine / carriere / caracteristiques).
- Attributs : 10 colonnes supposees partout (ChargerImageRecapitulatif ligne 1563, ChargerImageAttributs ligne 1694, TabAttribut 1..10). TOW = 8 caracteristiques + Fate : different, a refaire. **C'est ce qui empeche d'ouvrir WinCreation sur un livre vide.**
- Fortune / Fate V5 (2006-2014), bonus de caracteristique V5 (3177 ; TotalBonusCaracV5), colonne 6 / lignes 1-10 (6018-6124, 6486) : le mecanisme « 3 x +1 par d10 » de TOW ressemble au bonus V5 mais avec des regles propres : different.
- Argent (2235, 4428, 4484) : TOW = Brass / Silver / Gold, pas de formule de des : different.
- 4293 / 4315 / 4631 / 6057-6067 / 6099 / 6541 / 6615 / 7161-7169 : a lire un par un a l'etape 4.

## winpersonnage.pas (18 tests)
- Cases PDF « donnees seules » et « fond officiel » (5833-5837) : propres au PDF V5 : sans objet pour TOW (PDF = etape 6).
- Momentum (1930, 5845) : sans objet (talents Momentum = V4/V5).
- Couts d'XP, changement de carriere V5 (7063), PanelResolve : different (XP TOW = 1 a 4 par talent, carrieres sans niveaux).
- Autres (1931, 1987, 3130, 3505, 4658, 5080, 9009, 10405) : a lire a l'etape 5.

## Autres fichiers
- chargecoutxp.pas (29, 103, 114) : couts d'XP V5 : TOW different (talents 2 a 4 XP, competences / caracteristiques a definir a l'etape 5).
- pdfpersonnage.pas (2273, 7903) : bascule vers pdfpersonnagev5 par un Hook ; TOW aura son propre Hook (etape 6).
- chargetalent.pas / chargeconstantes.pas / warhammersource.pas / winlivre.pas / xmlexportimport.pas : seulement des commentaires ou le libelle de version : rien a faire.

## Conclusion
Le cadre de version est trivial (un dossier + un libelle). Le vrai travail est dans WinCreation (attributs, argent, phases) et WinPersonnage (couts, PDF) : etapes 2 a 6. Les 4 versions existantes n'ont pas change (un libelle ajoute dans une liste ; la pile d'appel ajoutee a la sortie des scripts d'ecran).

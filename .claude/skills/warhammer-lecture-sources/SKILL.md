---
name: warhammer-lecture-sources
description: Regles pour lire les livres Warhammer (TXT, PDF) et en tirer des donnees sans conclure trop vite. A utiliser des qu'on cherche une information dans un livre, un PDF_TEXTE ou LIVRES, ou qu'on veut declarer qu'une donnee est absente d'un livre.
---

# Lire les livres sans se tromper

Regles de Nono, nees d'erreurs reelles (aout-octobre 2026).

## Ordre de recherche

- **TXT d'abord, PDF seulement si besoin franc.** Les TXT sont deja generes : `PDF_TEXTE\PDF_TEXTE_V2\<Livre>.txt`, `PDF_TEXTE\PDF_TEXTE_V4\` (sous-dossiers Aventures, Enemy Within...), et quelques-uns dans `LIVRES\`. Les deux repertoires n'ont pas le meme contenu : chercher dans les deux.
- `Glob PDF_TEXTE\**\*.txt` AVANT toute extraction. Fouiller avec Grep. S'il n'y a pas de TXT, en creer un une fois (`pdftotext -layout`).
- Ouvrir le PDF seulement pour la geometrie (colonnes, encadres), les images, ou un TXT absent/faux.
- **Controle visible** : avant toute recherche dans un livre, ecrire « Source : TXT <chemin> » ou « Source : PDF, parce que <raison> ».
- Exception : pour les **tableaux de carriere** la mise en page est perdue dans le TXT ; le texte courant, lui, est fiable.

## Pieges de lecture

- **Un marqueur compte n'est pas un marqueur lu.** Avant de conclure depuis un comptage, sortir le contexte autour des occurrences (des « Career Path » etaient des fiches de PNJ).
- **Un grep aplatit la mise en page.** Deux colonnes melangees dans un resultat ne rendent pas la source inexploitable : `pdftotext -layout` conserve les positions.
- **L'extraction perd les attributs de caractere.** `pdftotext` ne transporte pas l'italique, le gras, la couleur. Avant de declarer une donnee absente d'un PDF, verifier qu'elle ne tient pas dans ce que l'extraction jette : `pdftohtml -xml` conserve les balises `<i>`.
- **Quand une donnee n'est pas la ou je regarde, elle est ailleurs.** L'hypothese par defaut n'est jamais « elle manque ». Pour un talent ou une competence, le premier « ailleurs » est la base.
  - (a) Ancrer un comptage de balises sur le bloc parent attendu : `DATA_CAREER_ROLL` et `DATA_SPECIE_CAREER_DIRECT` partagent des noms d'enfants.
  - (b) Ne pas deduire l'absence d'une donnee de l'absence d'un nom de balise : les livres n'ont pas tous la meme structure (le Rulebook range ses tables de tirage dans `DATA_CAREER_ROLL`, Middenheim sous `SUBCHAPTER_CAREER` dans chaque `<Specie>`). Lister les balises reellement presentes dans ce fichier, puis chercher par le contenu.
- **Avant de dire « ce livre n'a pas X »**, lister les balises presentes dans ce fichier et chercher par le contenu.

## Personnages

- PDF de personnage : `--dumppdf`, jamais pdftotext (voir memoire du projet).

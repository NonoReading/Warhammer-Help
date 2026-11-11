---
name: warhammer-donnees-xml
description: Regles pour ecrire ou lire les donnees XML Warhammer (races, ethnies, enumerations du code, XML de personnage, ajout de lots de donnees). A utiliser avant d'ajouter des ethnies, races ou objets, de toucher a Personnage.*, ou de lire un fichier DATABASE.
---

# Donnees XML : regles de Nono

## Race et ethnie : les balises disent l'inverse des identifiants

- `DATA_RACE` porte les **races** (`RULES-SPECIE_HUMAN`, `RULES-SPECIE_HELF`...).
- `DATA_SPECIE` porte les **ethnies** (`RULES-RACE_HUM` « Humans (Reikland) », `MIDDE-RACE_HMIDL`...).
- Dans chaque `<Specie>`, le champ qui remonte a la race s'appelle `<Ethnic>` :
  ```xml
  <Specie id="RULES-RACE_HUM">              <!-- balise Specie, id RACE_  : une ETHNIE -->
    <Ethnic>"RULES-SPECIE_HUMAN"</Ethnic>   <!-- balise Ethnic, id SPECIE_ : la RACE   -->
  ```
- Coherent dans toute la base, ce n'est pas un bug. Modele : **une race, N ethnies** (neuf ethnies humaines pointent sur `RULES-SPECIE_HUMAN`, douze Hauts Elfes sur `RULES-SPECIE_HELF`).

## Scission des ethnies

« Ce qu'il faut eviter, c'est le bete doublon dont juste le nom change ; si au moins une donnee de creation change, alors on double. » Comparer competences, talents, caracteristiques et table de carriere. Tout identique : une seule ethnie. Une seule donnee differente : on scinde (les onze Hauts Elfes de HEPG). La table de tirage porte autant de lignes que d'ethnies.

## Avant d'ajouter des donnees

- **Controle de collision sur la nature de donnee qu'on AJOUTE**, pas seulement sur celles qu'on reference : avant d'ecrire N objets d'une nature, indexer les libelles de cette nature dans tout `DATABASE\`. (Trois ethnies en doublon sont parties parce que seules les competences citees avaient ete verifiees.)
- **Avant d'introduire une valeur nouvelle dans un champ existant**, verifier si c'est un libelle libre ou une **enumeration portee par le code** (`TypSpell` : y ajouter « Ritual » sans verifier a laisse deux bugs).
- **Lire `GABARIT_XML_PERSONNAGE.md`** avant de toucher au code qui lit/ecrit un XML de personnage ou aux champs `Personnage.*`. Pour les livres : `GABARIT_LIVRE_XML.md`. Ne pas deviner le role d'un chapitre XML a partir de son nom.

## Enregistrement depuis WinLivre

Pas actif (edition WinLivre = derniere etape). Un bloc XML nouveau se teste en CHARGEMENT et affichage seulement ; un bloc lu mais non exporte est un bug a corriger au moment ou on ecrit l'export, verifie en RELISANT le code d'export.

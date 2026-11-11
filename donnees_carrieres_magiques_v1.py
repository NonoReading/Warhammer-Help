# -*- coding: utf-8 -*-
"""Donnees des carrieres MAGIQUES V1 (Core, section 4 « Magic », p.141-152 imprimees), lues sur les IMAGES du PDF
(rendu 170 dpi, pages PDF 146-148 et 152-159 : decalage de 5 puis 7 avec les planches couleur).

Huit ecoles de quatre niveaux : Alchemist, Wizard, Demonologist, Elementalist, Illusionist, Necromancer
(magiciens), Cleric, Druidic Priest (pretres). Chaque niveau est une carriere (RULES-WORK_<ECOLE>_<N>) :
  - les competences du livre sont celles GAGNEES A CE NIVEAU (pas cumulees) ;
  - Advance Scheme : plafonds cumules, comme les autres carrieres ;
  - les equipements (trappings) ne sont donnes qu a l entree au niveau 1 ;
  - entree et sorties « du niveau suivant » : ajoutees ici (le livre dit « of next level »).
Format : voir donnees_carrieres_avancees_v1.py.
"""

# Advance Scheme par ecole : une liste de quatre dictionnaires (niveaux 1 a 4)
_MAGICIEN = [
    dict(W=2, I=10, Int=10),
    dict(WS=10, BS=10, S=1, T=1, W=3, I=20, Dex=10, Ld=10, Int=20, Cl=10, WP=10),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=30, Dex=20, Ld=20, Int=30, Cl=20, WP=20),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=40, Dex=30, Ld=30, Int=30, Cl=30, WP=30),
]
_ALCHEMIST = [
    dict(W=2, I=10, Dex=10, Int=10),
    dict(WS=10, BS=10, S=1, T=1, W=3, I=20, Dex=20, Ld=10, Int=20, Cl=10, WP=10),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=30, Dex=30, Ld=20, Int=30, Cl=20, WP=20),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=40, Dex=40, Ld=30, Int=30, Cl=30, WP=30),
]
_CLERIC = [
    dict(W=2, I=10, Cl=10, WP=10, Fel=10),
    dict(WS=10, BS=10, S=1, T=1, W=3, I=20, Dex=10, Ld=10, Int=10, Cl=10, WP=20, Fel=10),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=20, Dex=20, Ld=20, Int=20, Cl=20, WP=30, Fel=20),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=30, Dex=30, Ld=30, Int=30, Cl=30, WP=30, Fel=30),
]
_DRUIDIC = [
    dict(W=2, I=10, WP=10),
    dict(WS=10, BS=10, S=1, T=1, W=3, I=20, Dex=10, Ld=10, Int=10, Cl=10, WP=20, Fel=10),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=20, Dex=20, Ld=20, Int=30, Cl=20, WP=20, Fel=20),
    dict(WS=10, BS=10, S=1, T=1, W=4, I=30, Dex=30, Ld=30, Int=30, Cl=30, WP=30, Fel=30),
]

BM = "Battle Magic"


def _cast(type_, n):
    return f"Cast Spells - {type_} level {n}"


# ecole : page, avancement, competences par niveau, equipement du niveau 1, sorties hors niveau suivant,
# cout de base en EP par niveau (x niveau), texte du livre sur la penalite ou la regle propre a l ecole
ECOLES = [
    dict(nom="Alchemist", page=141, adv=_ALCHEMIST, cout=100,
         skills=[
             ["Arcane Language - Magick", "Cast Spells - Petty Magic only", "Chemistry", "Metallurgy"],
             [_cast(BM, 1), "Herb Lore", "Magical Sense", "Prepare Poison"],
             [_cast(BM, 2), "Magical Awareness", "Manufacture Potions", "Meditation", "Rune Lore"],
             [_cast(BM, 3), "Arcane Language - Dwarvish or Elvish", "Identify Magical Artifact",
              "Manufacture Scrolls"],
         ],
         trappings=["D4 books from: Treatise on ye Properties of Matter, De Lapis Philosophorum, "
                    "On the Ennoblement of Base Metal, Brimstone and Its Nature, Rudiments of Alchemy",
                    "Hand Weapon", "Wizard's Staff", "10D6 Gold Crowns"],
         exits=["Wizard, level 1"],
         note="Magic points : 2D4 au niveau 1 puis 4D4 par niveau (nains et halflings : 1D4 puis 2D4). "
              "Un alchemiste ne lance que des sorts d un niveau inferieur au sien (niveau 1 : Petty Magic seulement)."),
    dict(nom="Wizard", page=142, adv=_MAGICIEN, cout=100,
         skills=[
             [_cast(BM, 1), "Identify Plants", "Magical Sense", "Rune Lore", "Scroll Lore"],
             [_cast(BM, 2), "Evaluate", "Herb Lore", "Magical Awareness", "Meditation"],
             [_cast(BM, 3), "Demon Lore", "Identify Magical Artifact", "Identify Undead", "Prepare Poison"],
             [_cast(BM, 4), "Arcane Language - Dwarvish or Elvish", "Manufacture Potions", "Manufacture Scrolls"],
         ],
         trappings=["Hand Weapon", "Wizard's Staff", "10D6 Gold Crowns"],
         exits=["Demonologist, level 1", "Elementalist, level 1", "Illusionist, level 1", "Necromancer, level 1"],
         note="Magic points : 4D4 par niveau (nains et halflings : 2D4). Apres le niveau 1, le magicien peut se "
              "specialiser (Demonologist, Elementalist, Illusionist, Necromancer)."),
    dict(nom="Demonologist", page=145, adv=_MAGICIEN, cout=200,
         skills=[
             ["Arcane Language - Demonology", _cast("Demonic Battle Magic", 1), "Demon Lore"],
             [_cast("Demonic Battle Magic", 2), "Identify Undead", "Meditation"],
             [_cast("Demonic Battle Magic", 3), "Identify Magical Artifact", "Magical Awareness"],
             ["Astronomy", _cast("Demonic Battle Magic", 4), "Manufacture Potions", "Manufacture Scrolls"],
         ],
         trappings=["Must be of Evil or Chaotic alignment", "Hand Weapon", "Wizard's Staff", "10D6 Gold Crowns"],
         exits=["Illusionist, level 1", "Necromancer, level 1", "Wizard, level 2"],
         note="Alignement Evil ou Chaotic obligatoire. A chaque niveau gagne : une nouvelle infirmite (Disability) "
              "et D6 points de folie (Insanity Points). Magic points : 4D4 par niveau (nains et halflings : 2D4)."),
    dict(nom="Elementalist", page=146, adv=_MAGICIEN, cout=200,
         skills=[
             ["Arcane Language - Elemental Magick", _cast("Elemental Battle Magic", 1), "Dousing", "Herb Lore",
              "Metallurgy"],
             ["Astronomy", _cast("Elemental Battle Magic", 2), "Identify Undead", "Meditation"],
             ["Arcane Language - Druidic", _cast("Elemental Battle Magic", 3), "Demon Lore",
              "Identify Magical Artifact", "Magical Awareness"],
             ["Arcane Language - Dwarvish or Elvish", _cast("Elemental Battle Magic", 4), "Manufacture Potions"],
         ],
         trappings=["Hand Weapon", "Wizard's Staff", "10D6 Gold Crowns"],
         exits=["Illusionist, level 1", "Wizard, level 2"],
         note="Un elementaliste ne peut jamais devenir Demonologist ni Necromancer. Magic points : 4D4 par niveau "
              "(nains et halflings : 2D4)."),
    dict(nom="Illusionist", page=147, adv=_MAGICIEN, cout=200,
         skills=[
             ["Arcane Language - Illusionist Magick", _cast("Illusionist Battle Magic", 1), "Evaluate"],
             [_cast("Illusionist Battle Magic", 2), "Hypnotise", "Meditation"],
             [_cast("Illusionist Battle Magic", 3), "Identify Undead", "Magical Awareness"],
             [_cast("Illusionist Battle Magic", 4), "Identify Magical Artifact", "Manufacture Potions",
              "Manufacture Scrolls"],
         ],
         trappings=["Hand Weapon", "Wizard's Staff", "10D6 Gold Crowns"],
         exits=["Demonologist, level 1", "Elementalist, level 1", "Necromancer, level 1", "Wizard, level 2"],
         note="Magic points : 4D4 par niveau (nains et halflings : 2D4)."),
    dict(nom="Necromancer", page=148, adv=_MAGICIEN, cout=200,
         skills=[
             ["Arcane Language - Necromancy", _cast("Necromantic Battle Magic", 1), "Identify Undead"],
             [_cast("Necromantic Battle Magic", 2), "Demon Lore", "Meditation"],
             [_cast("Necromantic Battle Magic", 3), "Magical Awareness", "Manufacture Drugs"],
             [_cast("Necromantic Battle Magic", 4), "Identify Magical Artifact", "Manufacture Potions",
              "Manufacture Scrolls"],
         ],
         trappings=["Hand Weapon", "Wizard's Staff", "10D6 Gold Crowns"],
         exits=["Demonologist, level 1", "Wizard, level 2"],
         # penalites propres a chaque niveau, dans l ordre du livre
         penalites=["Cadaverous Appearance, Morbidity, 10% chance of contracting Tomb Rot",
                    "1 Disability (magical Disability table), 30% chance of Tomb Rot",
                    "1 Disability (magical Disability table), 50% chance of Tomb Rot",
                    "1 Disability (magical Disability table), 70% chance of Tomb Rot"],
         note="Alignement Evil ou Chaotic. Magic points : 4D4 par niveau (nains et halflings : 2D4)."),
    dict(nom="Cleric", page=150, adv=_CLERIC, cout=100, pretre=True,
         skills=[
             ["Arcane Language", "Cast Spells - Clerical 1", "Meditation", "Public Speaking"],
             ["Cast Spells - Clerical 2", "Identify Undead", "Magical Sense"],
             ["Cast Spells - Clerical 3", "Magical Awareness", "Manufacture Scrolls"],
             ["Cast Spells - Clerical 4", "Manufacture Potions"],
         ],
         trappings=["Clerical Robes", "Religious Token", "D6 Gold Crowns"],
         exits=[],
         exits_niveau4=["Witch-hunter", "Demagogue"],
         note="Pretre : le passage d un niveau coute 100 EP par niveau pour UN jet sur la table d avancement du clerc "
              "(Cleric Advance Table), le resultat doit etre suivi. Competences du culte en plus (voir la divinite). "
              "Langue arcanique selon la religion. Magic points : 2D8 par niveau, toutes races. Strictures selon la religion."),
    dict(nom="Druidic Priest", page=151, adv=_DRUIDIC, cout=100, pretre=True,
         skills=[
             ["Arcane Language - Druidic", "Cast Spells - Druidic 1", "Heal Wounds", "Herb Lore", "Meditation", "Ride"],
             ["Cast Spells - Druidic 2", "Charm Animal", "Cure Disease", "Divination", "Magical Sense"],
             ["Astronomy", "Cast Spells - Druidic 3", "Magical Awareness", "Prepare Poison"],
             ["Cast Spells - Druidic 4", "Manufacture Potions", "Rune Lore"],
         ],
         trappings=["Hand Weapon", "White Robes"],
         exits=[],
         note="Humains seulement, alignement Neutral. Le passage d un niveau coute 100 EP par niveau pour UN jet sur "
              "la table d avancement du druide (Druid Advance Table). Competences du culte (Old Faith) en plus. "
              "Magic points : 2D8 par niveau. Esprit familier au niveau 1. Aucune sortie."),
]

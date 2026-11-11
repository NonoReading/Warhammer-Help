#!/usr/bin/env python3
"""Libelles EN/FR des categories d equipement V2 (menu Equipements, WinEquipement).

Le theme d un article V2 est le code RULES-EQCAT2_<SOUS-CATEGORIE OU CATEGORIE EN MAJUSCULES> (meme regle
que extraire_armes_v2.code, repetee dans xmlexportimport.pas : CodeThemeEquipementV2). Les categories
Mounts, Livestock et Vehicles n ont pas de libelle ici : elles prennent les themes V4 existants
(Montures et animaux, Vehicules). Les armes et armures (Melee Weapons, Missile Weapons, Advanced Armour)
ont leurs propres fenetres.

Usage : python libelles_equipement_v2.py   (idempotent : remplace les lignes deja ecrites)
"""
import extraire_armes_v2 as ea

CATEGORIES = {
    "Carrying Equipment": "Contenants et bagages",
    "Clothing": "Vêtements",
    "Food and Drink": "Nourriture et boissons",
    "Lighting": "Éclairage",
    "Lodging": "Logement",
    "Miscellanea": "Divers",
    "Services": "Services",
    "Special Equipment": "Équipement spécial",
    "Tools": "Outils",
    "Travel Services": "Services de voyage",
    "Musical Instruments": "Instruments de musique",
    "Reading and Writing": "Lecture et écriture",
    "Personal Equipment": "Équipement personnel",
    "Draughts": "Potions",
    "Oddities": "Curiosités",
    "Poisons": "Poisons",
    "Religious Equipment": "Équipement religieux",
    "Replacements and Appendages": "Prothèses et appendices",
    "Common Services": "Services courants",
    "Skilled Services": "Services qualifiés",
    "Mount Gear": "Harnachement",
    "Barding": "Barde",
    "Familiars": "Familiers",
    "Magic Items": "Objets magiques",
    "Armour Runes": "Runes d'armure",
    "Weapon Runes": "Runes d'arme",
    "Talismanic Runes": "Runes talismaniques",
}


# disponibilites (RULES-DISPO2_*), toutes celles du livre : l equipement en emploie plus que les armes
DISPONIBILITES = {
    "Abundant": "Très abondant", "Plentiful": "Abondant", "Common": "Courant", "Average": "Moyen",
    "Scarce": "Peu courant", "Rare": "Rare", "Very Rare": "Très rare", "Extremely Rare": "Extrêmement rare",
}


# fiche d un animal V2 (WinAnimal) : intitules des lignes de competences, talents et regles speciales
FICHE_ANIMAL = {
    "RULES-ANIMV2_SKILLS": ("Skills", "Compétences"),
    "RULES-ANIMV2_TALENTS": ("Talents", "Talents"),
    "RULES-ANIMV2_SPECIAL": ("Special Rules", "Règles spéciales"),
}


def main():
    en = ['<Text name="%s">"%s"</Text>' % (ea.code("RULES-EQCAT2_", k), k) for k in CATEGORIES]
    fr = ['<Text name="%s">"%s"</Text>' % (ea.code("RULES-EQCAT2_", k), v) for k, v in CATEGORIES.items()]
    en += ['<Text name="%s">"%s"</Text>' % (ea.code("RULES-DISPO2_", k), k) for k in DISPONIBILITES]
    fr += ['<Text name="%s">"%s"</Text>' % (ea.code("RULES-DISPO2_", k), v) for k, v in DISPONIBILITES.items()]
    en += ['<Text name="%s">"%s"</Text>' % (k, v[0]) for k, v in FICHE_ANIMAL.items()]
    fr += ['<Text name="%s">"%s"</Text>' % (k, v[1]) for k, v in FICHE_ANIMAL.items()]
    for code, anglais, francais in (            # fabrication des potions (Realms of Sorcery), fiche WinLivre
            ("764", "Lag time", "Délai d'effet"), ("765", "Volatility", "Volatilité"),
            ("766", "Ingredient cost", "Coût des ingrédients"), ("767", "Ingredient locale", "Provenance des ingrédients"),
            ("768", "Ingredient difficulty", "Difficulté des ingrédients"),
            ("769", "Creation difficulty", "Difficulté de fabrication"), ("770", "Creation time", "Temps de fabrication"),
            ("771", "Academic Knowledge", "Savoir requis"), ("772", "Powers", "Pouvoirs"),     # objets magiques
            ("773", "History", "Histoire"), ("774", "Effect", "Effet"),                           # + effet d'une potion
            ("775", "Rune type", "Type de rune"), ("776", "Inscription number", "Nombre d'inscription"),   # runes
            ("777", "Empowerment (successes)", "Empowerment (réussites requises)"),
            ("778", "Permanent effect", "Effet permanent"), ("779", "Temporary effect", "Effet temporaire")):
        en.append('<Text name="RULES-LAB_%s">"%s"</Text>' % (code, anglais))
        fr.append('<Text name="RULES-LAB_%s">"%s"</Text>' % (code, francais))
    # message du bouton XML (export) refuse en WFRP2
    en.append('<Text name="RULES-MESS_072">"The XML export does not cover WFRP2 data: nothing was written."</Text>')
    fr.append('<Text name="RULES-MESS_072">"L\'export XML ne couvre pas les données WFRP2 : rien n\'a été écrit."</Text>')
    ea.ecrit_libelles(en, ea.INTERFACE["EN"])
    ea.ecrit_libelles(fr, ea.INTERFACE["FR"])
    print("%d libelles par langue" % len(en))


if __name__ == "__main__":
    main()

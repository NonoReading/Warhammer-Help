#!/usr/bin/env python3
"""Cree les talents de lore manquants dans les livres V2 ou les sorts sont ecrits.

Les sorts d'une lore sans talent ne pouvaient pas etre accordes (voir
lier_sorts_talents_v2.py). Chaque talent est ajoute a DATA_TALENT_SPECIALIZATION du livre
qui decrit la lore, avec le generique de sa famille (SpellMode AUTO deja porte par le generique).
Relancable : un talent deja present n'est jamais redouble.

Usage : python creer_talents_lores_v2.py   (puis lier_sorts_talents_v2.py)
"""
import re
import sys

ARCANE = "RULES-T_ARCANE_LORE__*"
DIVINE = "RULES-T_DIVINE_LORE__*"
PETTY = "RULES-T_PETTY_MAGIC__*"
WITCH = "SOE-T_WITCH_LORE__*"

TALENTS = {
    "SORCERERS_OF_THE_SOUTH": [
        ("RULES-T_ARCANE_LORE__ILLUSIONE", "Arcane Lore (Illusione)", ARCANE)],
    "REALM_OF_THE_ICE_QUEEN": [
        ("RULES-T_WITCH_LORE__HAG", "Witch Lore (Hag)", WITCH),
        ("RULES-T_WITCH_LORE__ICE", "Witch Lore (Ice)", WITCH),
        ("RULES-T_PETTY_MAGIC__HAG", "Petty Magic (Hag)", PETTY),
        ("RULES-T_PETTY_MAGIC__ICE", "Petty Magic (Ice)", PETTY),
        ("RULES-T_DIVINE_LORE__DAZH", "Divine Lore (Dazh)", DIVINE),
        ("RULES-T_DIVINE_LORE__TOR", "Divine Lore (Tor)", DIVINE),
        ("RULES-T_DIVINE_LORE__URSUN", "Divine Lore (Ursun)", DIVINE)],
    "TOME_OF_SALVATION": [
        ("RULES-T_DIVINE_LORE__GUNNDRED", "Divine Lore (Gunndred)", DIVINE),
        ("RULES-T_DIVINE_LORE__HANDRICH", "Divine Lore (Handrich)", DIVINE),
        ("RULES-T_DIVINE_LORE__KHAINE", "Divine Lore (Khaine)", DIVINE)],
}


def main():
    for livre, talents in TALENTS.items():
        chemin = r"DATABASE\WFRP2\BOOK_%s.Xml" % livre
        with open(chemin, encoding="utf-8", newline="") as f:
            texte = f.read()
        eol = "\r\n" if "\r\n" in texte else "\n"
        blocs = ""
        for code, desc, gen in talents:
            if 'id="%s"' % code in texte:
                continue
            blocs += ('<Talent id="%s">' + eol + '<Description language="ENGLISH">"%s"</Description>' + eol
                      + '<Generique>"%s"</Generique>' + eol + '</Talent>' + eol) % (code, desc, gen)
        if not blocs:
            print(livre, ": rien a ajouter")
            continue
        if "</DATA_TALENT_SPECIALIZATION>" in texte:
            texte = texte.replace("</DATA_TALENT_SPECIALIZATION>", blocs + "</DATA_TALENT_SPECIALIZATION>", 1)
        else:
            fin = texte.index("</DATA_SPELL_TALENT>") + len("</DATA_SPELL_TALENT>")
            texte = (texte[:fin] + eol + "<DATA_TALENT_SPECIALIZATION>" + eol + blocs
                     + "</DATA_TALENT_SPECIALIZATION>" + texte[fin:])
        with open(chemin, "w", encoding="utf-8", newline="") as f:
            f.write(texte)
        print(livre, ":", blocs.count("<Talent id="), "talents ajoutes")


if __name__ == "__main__":
    sys.exit(main())

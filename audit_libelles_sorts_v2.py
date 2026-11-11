#!/usr/bin/env python3
"""Audit des libelles de domaines de magie V2 : liste les <Lore> des livres de DATABASE/WFRP2 dont le code
RULES-SPELLV2_<LORE> n a pas de libelle dans INTERFACE.Xml (EN) ou INTERFACE_FRANCAIS.Xml (FR).
Sans libelle, WinLivre affiche le code brut dans la colonne Type des sorts.

Usage : python audit_libelles_sorts_v2.py   (ne modifie rien ; code de sortie 1 s il manque des libelles)
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

import extraire_armes_v2 as ea

RACINE = Path(__file__).resolve().parent
DATABASE = RACINE / "DATABASE"


def libelles(fichier):
    t = (DATABASE / fichier).read_text(encoding="utf-8")
    return set(re.findall(r'<Text name="(RULES-SPELLV2_[^"]+)"', t))


def lores():
    """{lore: [livres]} pour tous les BOOK_*.Xml de WFRP2."""
    res = defaultdict(list)
    for livre in sorted((DATABASE / "WFRP2").glob("BOOK_*.Xml")):
        for lore in set(re.findall(r'<Lore>"([^"]*)"</Lore>', livre.read_text(encoding="utf-8"))):
            res[lore].append(livre.stem.replace("BOOK_", ""))
    return res


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    en, fr = libelles("INTERFACE.Xml"), libelles("INTERFACE_FRANCAIS.Xml")
    manque = 0
    for lore, livres in sorted(lores().items()):
        code = ea.code("RULES-SPELLV2_", lore)
        absent = [l for l, s in (("EN", en), ("FR", fr)) if code not in s]
        if absent:
            manque += 1
            print("%-45s %-8s %s" % (lore, "+".join(absent), ", ".join(livres)))
    print("%d domaine(s) sans libelle" % manque)
    return 1 if manque else 0


if __name__ == "__main__":
    sys.exit(main())

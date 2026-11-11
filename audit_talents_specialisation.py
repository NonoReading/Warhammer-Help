#!/usr/bin/env python3
"""Audit : talents declares en vrais talents (bloc DATA_TALENT) dont le nom a la forme « Nom (Precision) » et dont le nom
de base est deja un talent a specialisations (Divine Lore, Petty Magic, Extra Spell...), donc des specialisations mal
rangees (confusion nouveau talent / specialisation). Ne modifie rien.
Usage : python audit_talents_specialisation.py
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
BLOC = re.compile(r"<DATA_TALENT>(.*?)</DATA_TALENT>", re.S)
TALENT = re.compile(r'<Talent id="([^"]+)">\s*<Description language="ENGLISH">"([^"]+)"</Description>')


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    par_livre = {}
    bases = defaultdict(int)
    for f in sorted((RACINE / "DATABASE" / "WFRP2").glob("BOOK_*.Xml")):
        txt = f.read_text(encoding="utf-8", errors="replace")
        liste = []
        for m in BLOC.finditer(txt):
            for i, d in TALENT.findall(m.group(1)):
                mm = re.match(r"^(.+?) \((.+)\)$", d)
                if mm:
                    liste.append((i, d, mm.group(1)))
                    bases[mm.group(1)] += 1
        par_livre[f.name] = liste
    for livre, liste in par_livre.items():
        if liste:
            print("== %s : %d" % (livre, len(liste)))
            for i, d, b in liste:
                print("   %-55s %s" % (d, i))
    print("\nBases les plus frequentes :")
    for b, n in sorted(bases.items(), key=lambda x: -x[1])[:25]:
        print("  %3d  %s" % (n, b))


if __name__ == "__main__":
    main()

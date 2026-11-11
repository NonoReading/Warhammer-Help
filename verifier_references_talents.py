#!/usr/bin/env python3
"""Controle : tout code de talent cite dans un livre d'un dossier (WFRP4 ou WFRP5) est declare comme fiche <Talent id>
dans ce dossier. Une specialisation citee sans fiche (PREFIXE-T_NOM_X) est acceptee si sa famille PREFIXE-T_NOM_* est
declaree. Ne modifie rien. Usage : python verifier_references_talents.py WFRP4|WFRP5
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
ID = re.compile(r'<Talent id="([^"]+)"')
REF = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+-T_[A-Za-z0-9_*]+)")
REF_NUM = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+-T0[A-Z0-9]*(?:_[A-Za-z0-9*]+)*)")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    fichiers = sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"))
    textes = {f.name: f.read_text(encoding="utf-8", errors="replace") for f in fichiers}
    declares = set()
    for t in textes.values():
        declares.update(ID.findall(t))
    # RULES-T_X : aussi les fiches sans prefixe de livre propre a la famille
    familles = {c.rsplit("_", 1)[0] + "_*" for c in declares if "_" in c[c.find("-T_"):] and not c.endswith("_*")}
    orphelins = defaultdict(list)
    numeriques = defaultdict(int)
    for nom, t in textes.items():
        t_sans_commentaires = re.sub(r"<!--.*?-->", "", t, flags=re.S)
        for c in set(REF.findall(t_sans_commentaires)):
            if c in declares:
                continue
            # specialisation dont la famille est declaree ?
            fam = (c.split("__", 1)[0] + "__*") if "__" in c else (c.rsplit("_", 1)[0] + "_*")
            if fam in declares:
                continue
            # famille declaree par un autre livre : meme nom de famille, prefixe de livre different
            if any(d.endswith("-" + fam.split("-", 1)[1]) for d in declares if d.endswith("__*")):
                continue
            orphelins[c].append(nom)
        for c in REF_NUM.findall(t_sans_commentaires):
            numeriques[c] += 1
    print("%s : %d talents declares ; %d codes cites sans fiche ; %d codes a numero restants" % (
        dossier, len(declares), len(orphelins), len(numeriques)))
    for c, livres in sorted(orphelins.items())[:60]:
        print("  orphelin  %-45s %s" % (c, ", ".join(sorted(set(livres)))))
    for c, n in sorted(numeriques.items())[:20]:
        print("  numerique %-45s %d" % (c, n))


if __name__ == "__main__":
    main()

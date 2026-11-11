#!/usr/bin/env python3
"""Controle : tout code de competence cite dans un livre d'un dossier (WFRP4 ou WFRP5) est declare comme fiche
<Skill id> dans ce dossier. Une specialisation citee sans fiche (PREFIXE-COMP_FAMILLE__SPEC) est acceptee si sa famille
PREFIXE-COMP_FAMILLE__* est declaree (meme sous un autre prefixe de livre). Signale aussi les anciens codes (COMPxxx
sans '_') restants, les alias (id avec '/') et les codes nus des balises <PDF>. Ne modifie rien.
Usage : python verifier_references_competences.py WFRP4|WFRP5
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
ID = re.compile(r'<Skill id="([^"]+)"')
REF = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+-COMP_[A-Za-z0-9_*]+)")
ANCIEN = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+-COMP[A-Z]+(?:_[A-Za-z0-9*]+)*)")
PDF = re.compile(r'<PDF>"([^"]*)"</PDF>')


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    fichiers = sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"))
    textes = {f.name: re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)
              for f in fichiers}
    declares = set()
    alias = []
    for t in textes.values():
        for c in ID.findall(t):
            declares.add(c)
            if "/" in c:
                alias.append(c)
    familles_noms = {c.split("-", 1)[1] for c in declares if c.endswith("__*")}
    orphelins = defaultdict(list)
    anciens = defaultdict(int)
    pdf_inconnus = defaultdict(int)
    for nom, t in textes.items():
        for c in set(REF.findall(t)):
            if c in declares:
                continue
            fam = (c.split("__", 1)[0] + "__*") if "__" in c else ""
            if fam in declares:
                continue
            if fam and fam.split("-", 1)[1] in familles_noms:
                continue
            orphelins[c].append(nom)
        for c in ANCIEN.findall(t):
            anciens[c] += 1
        for m in PDF.findall(t):
            for tok in m.split(","):
                tok = tok.strip()
                if tok.startswith("COMP"):
                    if not any(d.endswith("-" + tok) for d in declares):
                        pdf_inconnus[tok] += 1
    print("%s : %d competences declarees, %d alias, %d codes cites sans fiche, %d anciens codes restants, "
          "%d codes nus de <PDF> sans fiche" % (dossier, len(declares), len(alias), len(orphelins), len(anciens),
                                                 len(pdf_inconnus)))
    for c, livres in sorted(orphelins.items())[:60]:
        print("  orphelin  %-45s %s" % (c, ", ".join(sorted(set(livres)))))
    for c, n in sorted(anciens.items())[:20]:
        print("  ancien    %-45s %d" % (c, n))
    for c, n in sorted(pdf_inconnus.items())[:20]:
        print("  pdf nu    %-45s %d" % (c, n))


if __name__ == "__main__":
    main()

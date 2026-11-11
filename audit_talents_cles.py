#!/usr/bin/env python3
"""Audit : cle d un talent = code sans son prefixe de livre (RULES-T_X, GAFX-T_X -> T_X). Ne modifie rien.
Liste 1 : cles presentes dans plusieurs livres (doublons voulus), avec la liste des livres.
Liste 2 : meme libelle anglais mais cles differentes (a renommer pour que les talents se reconnaissent).
Liste 3 : meme cle mais contenu different (Explanation ou autres champs) : a trancher.
Usage : python audit_talents_cles.py [fichier_rapport] [dossiers separes par des virgules, ex WFRP2,WFRP4]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
DOSSIERS = sys.argv[2].split(",") if len(sys.argv) > 2 else ["WFRP2"]
BLOC = re.compile(r"<DATA_TALENT>(.*?)</DATA_TALENT>", re.S)
FICHE = re.compile(r'<Talent id="([^"]+)">(.*?)</Talent>', re.S)
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)
EXPL = re.compile(r'<Explanation language="ENGLISH">"(.*?)"</Explanation>', re.S)


def cle(code):
    return code.split("-", 1)[1] if "-" in code else code


def norm(s):
    return re.sub(r"\s+", " ", s).strip().lower()


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    sortie = open(sys.argv[1], "w", encoding="utf-8") if len(sys.argv) > 1 else sys.stdout
    fiches = []  # (livre, code, libelle, explication)
    for f in sorted(p for d in DOSSIERS for p in (RACINE / "DATABASE" / d).glob("*.[Xx]ml")):
        txt = f.read_text(encoding="utf-8", errors="replace")
        for b in BLOC.finditer(txt):
            for code, corps in FICHE.findall(b.group(1)):
                d = DESC.search(corps)
                e = EXPL.search(corps)
                fiches.append((f.parent.name + "/" + f.name, code, d.group(1) if d else "", e.group(1) if e else ""))
    print("%d fiches de talents" % len(fiches), file=sortie)
    par_cle = defaultdict(list)
    par_lib = defaultdict(list)
    for fi in fiches:
        par_cle[cle(fi[1])].append(fi)
        par_lib[norm(fi[2])].append(fi)

    print("\n=== 1. Cles presentes dans plusieurs fiches (%d cles) ===" % sum(1 for v in par_cle.values() if len(v) > 1), file=sortie)
    for k, v in sorted(par_cle.items()):
        if len(v) > 1:
            print("%s : %s" % (k, ", ".join(x[1].split("-", 1)[0] for x in v)), file=sortie)

    print("\n=== 2. Meme libelle, cles differentes ===", file=sortie)
    n2 = 0
    for lib, v in sorted(par_lib.items()):
        cles = sorted({cle(x[1]) for x in v})
        if lib and len(cles) > 1:
            n2 += 1
            print("%s : %s" % (v[0][2], " | ".join("%s (%s)" % (x[1], x[0].split("/")[-1][:30]) for x in v)), file=sortie)
    print("-> %d libelles" % n2, file=sortie)

    print("\n=== 3. Meme cle, explication differente ===", file=sortie)
    n3 = 0
    for k, v in sorted(par_cle.items()):
        if len(v) > 1 and len({norm(x[3]) for x in v}) > 1:
            n3 += 1
            print("%s" % k, file=sortie)
            for x in v:
                print("    %-30s %s" % (x[1].split("-", 1)[0], x[3][:110].replace("\n", " ")), file=sortie)
    print("-> %d cles" % n3, file=sortie)


if __name__ == "__main__":
    main()

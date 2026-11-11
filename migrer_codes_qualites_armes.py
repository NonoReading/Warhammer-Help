#!/usr/bin/env python3
"""Migration des codes de qualites d'arme V4 / V5 (LIVRE-WEAPB04, LIVRE-WEAPB_03) vers des codes a nom :
LIVRE-WEAPB_NOM (nom = libelle anglais de la fiche en majuscules, ponctuation -> _, parenthese finale
« (Rating) » ignoree). Le livre reste le prefixe. En cas de collision dans un livre, le nouveau nom garde l'ancien
numero en suffixe (WEAPB_NOM_04).
Par defaut : a blanc (table + collisions + references orphelines). --appliquer reecrit DATABASE/<dossier> et
SAVED_CARACTERS/<dossier>.
Usage : python migrer_codes_qualites_armes.py WFRP4|WFRP5 [fichier_table.tsv] [--appliquer]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
FICHE = re.compile(r'<(BonusMalus|Craftsmanship) id="([A-Z0-9]+-WEAPB_?\d+)">(.*?)</\1>', re.S)
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)
REF = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+-WEAPB_?\d+)(?![0-9])")


def slug(libelle):
    return re.sub(r"[^A-Za-z0-9]+", "_", libelle.upper()).strip("_")


def sans_parenthese(libelle):
    return re.sub(r"\s*\([^)]*\)\s*$", "", libelle.strip())


def lire(f):
    return re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    sortie = Path(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    fichiers_base = [f for f in sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml")) if "_FRANCAIS" not in f.name]

    fiches = {}   # ancien code -> libelle
    for f in fichiers_base:
        for _, code, corps in FICHE.findall(lire(f)):
            d = DESC.search(corps)
            fiches.setdefault(code, d.group(1).strip() if d else "")

    table, cas = {}, []
    pris = defaultdict(dict)   # livre -> {nouveau nom: ancien code}
    for code, lib in sorted(fiches.items()):
        livre, reste = code.split("-", 1)
        base = slug(sans_parenthese(lib))
        if not base:
            cas.append("libelle vide : %s" % code)
            continue
        nouveau = "WEAPB_" + base
        if nouveau in pris[livre]:
            nouveau = "%s_%s" % (nouveau, reste[5:].lstrip("_"))
            cas.append("collision : %s -> %s (deja pris par %s)" % (code, nouveau, pris[livre][nouveau.rsplit("_", 1)[0]]))
        pris[livre][nouveau] = code
        table[code] = "%s-%s" % (livre, nouveau)

    print("%s : %d qualites d'arme" % (dossier, len(table)))
    print("\n== Cas a trancher : %d" % len(cas))
    for c in cas:
        print("  " + c)
    if sortie:
        with open(sortie, "w", encoding="utf-8") as f:
            for a, n in sorted(table.items()):
                f.write("%s\t%s\t%s\n" % (a, n, fiches[a]))
        print("\nTable ecrite dans %s" % sortie)
    appliquer(dossier, table, "--appliquer" in sys.argv)


def appliquer(dossier, table, reel):
    fichiers = sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"))
    fichiers += sorted((RACINE / "SAVED_CARACTERS" / dossier).rglob("*.[Xx]ml"))
    inconnus = defaultdict(int)
    total = modifies = 0
    for f in fichiers:
        brut = f.read_bytes().decode("utf-8")

        def remplace(m):
            nonlocal total
            if m.group(1) not in table:
                inconnus[m.group(1)] += 1
                return m.group(0)
            total += 1
            return table[m.group(1)]

        txt = REF.sub(remplace, brut)
        if txt != brut:
            modifies += 1
            if reel:
                f.write_bytes(txt.encode("utf-8"))
    print("\n== %s : %d references reecrites dans %d fichiers%s" % (
        "APPLIQUE" if reel else "A BLANC", total, modifies, "" if reel else " (rien ecrit)"))
    print("   codes WEAPB sans fiche : %d" % len(inconnus))
    for k, n in sorted(inconnus.items(), key=lambda x: -x[1])[:25]:
        print("     %s (%d)" % (k, n))


if __name__ == "__main__":
    main()

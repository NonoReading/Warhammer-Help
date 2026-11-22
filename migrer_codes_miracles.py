#!/usr/bin/env python3
"""Migration des codes de miracles V4 / V5 (LIVRE-MIRAC_DIEU_012) vers des codes a nom : LIVRE-MIRAC_DIEU_NOM
(nom = libelle anglais de la fiche en majuscules, ponctuation -> _, parenthese finale ignoree). Le livre, MIRAC_ et
le dieu sont gardes. En cas de collision (meme livre, meme dieu, meme nom), le nouveau nom garde l'ancien numero
en suffixe (MIRAC_DIEU_NOM_012). Les fichiers _FRANCAIS ne servent pas a construire la table mais sont reecrits.
Par defaut : a blanc (table + collisions). --appliquer reecrit DATABASE/<dossier> et SAVED_CARACTERS/<dossier>.
Usage : python migrer_codes_miracles.py WFRP4|WFRP5 [fichier_table.tsv] [--appliquer]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
FICHE = re.compile(r'<Sort id="([A-Z0-9]+-MIRAC_[A-Z]+_\d+)">(.*?)</Sort>', re.S)
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)


def slug(libelle):
    return re.sub(r"[^A-Za-z0-9]+", "_", libelle.upper()).strip("_")


def lire(f):
    return re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    sortie = Path(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    fichiers_base = [f for f in sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml")) if "_FRANCAIS" not in f.name]

    fiches = {}
    for f in fichiers_base:
        for code, corps in FICHE.findall(lire(f)):
            d = DESC.search(corps)
            if d or code not in fiches:
                fiches[code] = d.group(1).strip() if d else fiches.get(code, "")

    table, cas = {}, []
    pris = defaultdict(dict)
    for code, lib in sorted(fiches.items()):
        livre, reste = code.split("-", 1)
        pref, num = reste.rsplit("_", 1)      # pref = MIRAC_DIEU
        base = slug(lib)
        if not base:
            cas.append("libelle vide : %s" % code)
            continue
        nouveau = "%s_%s" % (pref, base)
        cle = (livre, pref)
        if nouveau in pris[cle]:
            avant = pris[cle][nouveau]
            nouveau = "%s_%s" % (nouveau, num)
            cas.append("collision : %s -> %s (deja pris par %s)" % (code, nouveau, avant))
        pris[cle][nouveau] = code
        table[code] = "%s-%s" % (livre, nouveau)

    print("%s : %d miracles" % (dossier, len(table)))
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
    ref = re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(re.escape(k) for k in sorted(table, key=len, reverse=True)) +
                     r")(?![0-9])")
    fichiers = sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"))
    fichiers += sorted((RACINE / "SAVED_CARACTERS" / dossier).rglob("*.[Xx]ml"))
    total = modifies = 0
    for f in fichiers:
        brut = f.read_bytes().decode("utf-8")
        txt, n = ref.subn(lambda m: table[m.group(1)], brut)
        total += n
        if txt != brut:
            modifies += 1
            if reel:
                f.write_bytes(txt.encode("utf-8"))
    print("\n== %s : %d references reecrites dans %d fichiers%s" % (
        "APPLIQUE" if reel else "A BLANC", total, modifies, "" if reel else " (rien ecrit)"))


if __name__ == "__main__":
    main()

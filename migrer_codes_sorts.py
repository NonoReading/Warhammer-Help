#!/usr/bin/env python3
"""Migration des codes de sorts V4 / V5 (LIVRE-COLOR_012) vers des codes a nom : LIVRE-COLOR_NOM
(nom = libelle anglais de la fiche en majuscules, ponctuation -> _, parenthese finale ignoree). Le livre et le
prefixe de liste (COLOR_, ARCAN_, SPELL_, PETTY_, RITUAL_...) sont gardes : le jeu reconnait un sort miracle, mineur
ou arcane a MIRAC_ / SPELL_ / ARCAN_ dans son code. Les sorts deja a nom (MIRAC_) ne bougent pas. En cas de
collision (meme livre, meme liste, meme nom), le nouveau nom garde l'ancien numero en suffixe (COLOR_NOM_012).
Les fichiers _FRANCAIS ne servent pas a construire la table mais sont reecrits.
Par defaut : a blanc (table + collisions + references orphelines). --appliquer reecrit DATABASE/<dossier> et
SAVED_CARACTERS/<dossier>.
Usage : python migrer_codes_sorts.py WFRP4|WFRP5 [fichier_table.tsv] [--appliquer]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
FICHE = re.compile(r'<Sort id="([A-Z0-9]+-[A-Z]+_\d+)">(.*?)</Sort>', re.S)
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)


def slug(libelle):
    return re.sub(r"[^A-Za-z0-9]+", "_", libelle.upper()).strip("_")


def sans_parenthese(libelle):
    return re.sub(r"\s*\((?:[A-Z0-9]{1,5}|Rating)\)\s*$", "", libelle.strip())


def lire(f):
    return re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    sortie = Path(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    fichiers_base = [f for f in sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml")) if "_FRANCAIS" not in f.name]

    fiches = {}   # ancien code -> libelle
    for f in fichiers_base:
        for code, corps in FICHE.findall(lire(f)):
            d = DESC.search(corps)
            # un bloc partiel (surcharge du talent seul) peut preceder la fiche : garder le libelle non vide
            if d or code not in fiches:
                fiches[code] = d.group(1).strip() if d else fiches.get(code, "")

    table, cas = {}, []
    pris = defaultdict(dict)   # (livre, prefixe) -> {nouveau nom: ancien code}
    for code, lib in sorted(fiches.items()):
        livre, reste = code.split("-", 1)
        pref, num = reste.rsplit("_", 1)
        base = slug(sans_parenthese(lib))
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

    print("%s : %d sorts" % (dossier, len(table)))
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
    # une seule passe : un code ancien est reconnu seulement s'il est dans la table (les autres numeros, ARMO_01...,
    # ne sont jamais touches)
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

#!/usr/bin/env python3
"""Migration generique des codes numerotes LIVRE-PREFIXE_012 / LIVRE-PREFIXE12 vers LIVRE-PREFIXE_NOM
(nom = libelle anglais de la fiche en majuscules, ponctuation -> _). Pour les types RUNE, MAGIC, STAR, DISEASE,
AFFLICT, ADAPT (fiche = element a attribut id ou name, avec <Description language="ENGLISH">). Le livre PERSO (donnees
de test) n'est pas touche. Collision (meme livre, meme prefixe, meme nom) : l'ancien numero reste en suffixe.
Les fichiers _FRANCAIS ne servent pas a construire la table mais sont reecrits.
Par defaut : a blanc. --appliquer reecrit DATABASE/<dossier> et SAVED_CARACTERS/<dossier>.
Usage : python migrer_codes_fiches.py WFRP4 RUNE,MAGIC,... [fichier_table.tsv] [--appliquer]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)


def slug(libelle):
    return re.sub(r"[^A-Za-z0-9]+", "_", libelle.upper()).strip("_")


def lire(f):
    return re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    prefixes = sys.argv[2].split(",")
    sortie = Path(sys.argv[3]) if len(sys.argv) > 3 and not sys.argv[3].startswith("--") else None
    alt = "|".join(prefixes)
    fiche = re.compile(r'<(\w+) (?:id|name)="((?!PERSO-)[A-Z0-9]+-(?:%s)_?\d+)">(.*?)</\1>' % alt, re.S)
    fichiers_base = [f for f in sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml")) if "_FRANCAIS" not in f.name]

    fiches = {}
    for f in fichiers_base:
        for _, code, corps in fiche.findall(lire(f)):
            d = DESC.search(corps)
            if d or code not in fiches:
                fiches[code] = d.group(1).strip() if d else fiches.get(code, "")

    table, cas = {}, []
    pris = defaultdict(dict)
    decoupe = re.compile(r"^([A-Z0-9]+)-(%s)_?(\d+)$" % alt)
    for code, lib in sorted(fiches.items()):
        livre, pref, num = decoupe.match(code).groups()
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

    par = defaultdict(int)
    for c in table:
        par[decoupe.match(c).group(2)] += 1
    print("%s : %d fiches (%s)" % (dossier, len(table), ", ".join("%s %d" % kv for kv in sorted(par.items()))))
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

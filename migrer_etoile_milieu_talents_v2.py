#!/usr/bin/env python3
"""V2 : codes de talents avec un '*' au milieu -> format '__' de V4 / V5 (24/10/2026, demande de Nono).
  RULES-T_ARCANE_LORE_*_HIGH_MAGIC -> RULES-T_ARCANE_LORE__HIGH_MAGIC   (specialisation)
  RULES-T_ARCANE_LORE_*_*           -> RULES-T_ARCANE_LORE__*            (generique de la specialisation)
  RULES-T_ARCANE_LORE_*             -> RULES-T_ARCANE_LORE__*            (generique de la famille, si la famille a des '_*_')
Les familles sans '_*_' (T_LESSER_MAGIC_*, T_LANGUAGE_*, T_SIGNS_*...) ne sont PAS touchees : CodeFamilleTalent lit encore
l'ancien format.
Reecrit : DATABASE/WFRP2/*.xml, SAVED_CARACTERS/WFRP2/**/*.xml, images portant un code de talent, scripts *.py.
Usage : python migrer_etoile_milieu_talents_v2.py [--appliquer]   (sans option : simulation)
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
MILIEU = re.compile(r"(?<![A-Za-z0-9_])[A-Z0-9]+-(T_[A-Za-z0-9_]*?)_\*_")
SIMPLE = re.compile(r"(?<![A-Za-z0-9_])[A-Z0-9]+-(T_[A-Za-z0-9_]*[A-Za-z0-9])_\*(?![A-Za-z0-9_*])")
CODE = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+)-(T_[A-Za-z0-9_]*?(?:_\*(?:_[A-Za-z0-9_*]+)?)?)(?![A-Za-z0-9_*])")


def familles(fichiers):
    noms = set()
    for f in fichiers:
        noms.update(MILIEU.findall(f.read_text(encoding="utf-8", errors="replace")))
    # 2e passe (24/10/2026) : familles a '_*' simple (LESSER_MAGIC, PETTY_MAGIC, WITCH_LORE...), seulement dans la base V2
    for f in (RACINE / "DATABASE" / "WFRP2").glob("*.[Xx]ml"):
        for m in SIMPLE.findall(f.read_text(encoding="utf-8", errors="replace")):
            noms.add(m)
    return noms


def convertit_nom(nom, fam, stats):
    if "__" in nom:
        return nom
    if "_*_" in nom:
        base, reste = nom.split("_*_", 1)
        stats["specialisations" if reste != "*" else "generiques"] += 1
        return base + "__" + reste
    if nom.endswith("_*") and nom[:-2] in fam:
        stats["generiques"] += 1
        return nom[:-2] + "__*"
    # specialisation a l'ancien format '_' simple d'une famille convertie (LEOP-T_DIVINE_LORE_GRIMNIR) : son generique
    # devient FAMILLE__*, elle doit suivre
    for f in sorted(fam, key=len, reverse=True):
        if nom.startswith(f + "_") and not nom.startswith(f + "_*"):
            stats["anciennes"] += 1
            return f + "__" + nom[len(f) + 1:]
    return nom


def reecrit(txt, fam, stats):
    def r(m):
        n = convertit_nom(m.group(2), fam, stats)
        return m.group(0) if n == m.group(2) else "%s-%s" % (m.group(1), n)
    return CODE.sub(r, txt)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    reel = "--appliquer" in sys.argv
    fichiers = sorted((RACINE / "DATABASE" / "WFRP2").glob("*.[Xx]ml"))
    if (RACINE / "SAVED_CARACTERS" / "WFRP2").exists():
        fichiers += sorted((RACINE / "SAVED_CARACTERS" / "WFRP2").rglob("*.[Xx]ml"))
    fichiers += sorted(RACINE.glob("*.py"))
    fam = familles(fichiers)
    print("familles a '_*_' :", sorted(fam))
    stats = defaultdict(int)
    for f in fichiers:
        if f.name == Path(__file__).name:
            continue
        brut = f.read_bytes().decode("utf-8", errors="strict")
        txt = reecrit(brut, fam, stats)
        if txt != brut:
            stats["fichiers"] += 1
            print("  ", f.relative_to(RACINE))
            if reel:
                f.write_bytes(txt.encode("utf-8"))
    for f in sorted((RACINE / "DATABASE" / "WFRP2").glob("PICTURES*/**/*")):
        m = re.fullmatch(r"([A-Z0-9]+)-(T_[A-Za-z0-9_*]*)", f.stem) if f.is_file() else None
        if m:
            n = convertit_nom(m.group(2), fam, stats)
            if n != m.group(2):
                stats["images"] += 1
                if reel and not f.with_name("%s-%s%s" % (m.group(1), n, f.suffix)).exists():
                    f.rename(f.with_name("%s-%s%s" % (m.group(1), n, f.suffix)))
    print(dict(stats))
    print("APPLIQUE" if reel else "SIMULATION (rien n'est ecrit)")


if __name__ == "__main__":
    main()

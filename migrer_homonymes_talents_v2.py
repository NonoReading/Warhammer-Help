#!/usr/bin/env python3
"""V2 : 7 vrais homonymes de talents distingues par une cle propre (25/10/2026, accord de Nono).
La cle d un talent = ce qui suit le premier « - » ; ici le livre garde sa cle d origine pour une version et les autres prennent le suffixe du livre :
  DOTF-T_BLADEMASTER garde sa cle ; NDM-T_BLADEMASTER -> NDM-T_BLADEMASTER_NDM ; TCHN-T_BLADEMASTER -> TCHN-T_BLADEMASTER_TCHN
  TCHN-T_BRAVEHEART, TCHN-T_HORSEMASTER, TDRG-T_FIRE_BLOODED, RELE-T_ELEMENTAL_MAGIC, COTO-T_WITCHCRAFT, UTOC-T_HIGH_MAGIC (meme regle).
Reecrit : DATABASE/WFRP2/*.xml, SAVED_CARACTERS/WFRP2/**/*.xml, images portant le code, scripts *.py (sauf celui-ci).
Usage : python migrer_homonymes_talents_v2.py [--appliquer]   (sans option : simulation)
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
RENOMMES = {
    "NDM": ["T_BLADEMASTER"],
    "TCHN": ["T_BLADEMASTER", "T_BRAVEHEART", "T_HORSEMASTER"],
    "TDRG": ["T_FIRE_BLOODED"],
    "RELE": ["T_ELEMENTAL_MAGIC"],
    "COTO": ["T_WITCHCRAFT"],
    "UTOC": ["T_HIGH_MAGIC"],
}
CIBLES = {"%s-%s" % (livre, cle): "%s-%s_%s" % (livre, cle, livre) for livre, cles in RENOMMES.items() for cle in cles}
MOTIF = re.compile(r"(?<![A-Za-z0-9_])(%s)(?![A-Za-z0-9_*])" % "|".join(re.escape(c) for c in CIBLES))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    reel = "--appliquer" in sys.argv
    fichiers = sorted((RACINE / "DATABASE" / "WFRP2").glob("*.[Xx]ml"))
    if (RACINE / "SAVED_CARACTERS" / "WFRP2").exists():
        fichiers += sorted((RACINE / "SAVED_CARACTERS" / "WFRP2").rglob("*.[Xx]ml"))
    fichiers += sorted(RACINE.glob("*.py"))
    stats = defaultdict(int)
    for f in fichiers:
        if f.name == Path(__file__).name:
            continue
        brut = f.read_bytes().decode("utf-8", errors="strict")
        n = len(MOTIF.findall(brut))
        if n:
            stats["fichiers"] += 1
            stats["references"] += n
            print("  %-60s %d" % (f.relative_to(RACINE), n))
            if reel:
                f.write_bytes(MOTIF.sub(lambda m: CIBLES[m.group(1)], brut).encode("utf-8"))
    for f in sorted((RACINE / "DATABASE" / "WFRP2").glob("PICTURES*/**/*")):
        if f.is_file() and f.stem in CIBLES:
            stats["images"] += 1
            print("  image", f.relative_to(RACINE))
            nouveau = f.with_name(CIBLES[f.stem] + f.suffix)
            if reel and not nouveau.exists():
                f.rename(nouveau)
    print(dict(stats))
    print("APPLIQUE" if reel else "SIMULATION (rien n'est ecrit)")


if __name__ == "__main__":
    main()

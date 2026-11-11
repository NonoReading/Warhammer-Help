#!/usr/bin/env python3
"""Carrieres V2 reservees a une race : ajoute <Career name="..">"-"</Career> (indisponible) dans le
SUBCHAPTER_CAREER des ethnies concernees (16/10/2026). Meme notation que la V4 (chargeracemetier.pas).

Seules les restrictions SURES du texte des carrieres sont codees ; l'origine d'un elfe (sylvestre ou
non) n'existe pas dans le Core V2 et reste au MJ. Shieldbreaker n'y est pas (la note ne parle que de
la carriere de DEPART). Une carriere deja pesee dans la table d'une ethnie n'est jamais touchee.
Relancable : les lignes "-" sont recalculees. Usage : python interdire_carrieres_v2.py [--dry]
"""
import re
import sys
from pathlib import Path

LIVRE = Path(__file__).parent / "DATABASE" / "WFRP2" / "BOOK_RULESBOOK.Xml"
NAIN, ELFE, HALF, HUM = "DWARF", "ELF", "HALFLING", "HUMAN"
# carriere -> races QUI PEUVENT la prendre
SEULEMENT = {
    "RULES-CARE_DAEMON_SLAYER": [NAIN], "RULES-CARE_GIANT_SLAYER": [NAIN],
    "RULES-CARE_RUNEBEARER": [NAIN], "RULES-CARE_TROLL_SLAYER": [NAIN],
    "CCOMP-CARE_APPRENTICE_RUNESMITH": [NAIN], "CCOMP-CARE_JOURNEYMAN_RUNESMITH": [NAIN],
    "CCOMP-CARE_MASTER_RUNESMITH": [NAIN], "CCOMP-CARE_RUNELORD": [NAIN],
    "RULES-CARE_ENVOY": [ELFE], "RULES-CARE_GHOST_STRIDER": [ELFE],
    "RULES-CARE_KITHBAND_WARRIOR": [ELFE],
    "RULES-CARE_FIELDWARDEN": [HALF],
    "RULES-CARE_APPRENTICE_WIZARD": [ELFE, HUM], "RULES-CARE_HEDGE_WIZARD": [ELFE, HUM],
}


def main(argv):
    t = LIVRE.read_text(encoding="utf-8")
    total = 0

    def espece(m):
        global_race = m.group(1)
        corps = m.group(0)
        b = re.search(r"<SUBCHAPTER_CAREER>\n(.*?)</SUBCHAPTER_CAREER>", corps, flags=re.S)
        if not b:
            return corps
        lignes = [l for l in b.group(1).split("\n") if l and not l.endswith('"-"</Career>')]
        pesees = {re.search(r'name="([^"]+)"', l).group(1) for l in lignes}
        ajouts = []
        for code, races in SEULEMENT.items():
            if code in pesees:
                continue
            if global_race not in races:
                ajouts.append('<Career name="%s">"-"</Career>' % code)
            else:  # race autorisee : 'X' = eligible hors tirage (sinon la carriere n'a aucune race)
                ajouts.append('<Career name="%s">"X"</Career>' % code)
        nonlocal_total[0] += len(ajouts)
        nouveau = "\n".join(lignes + ajouts) + "\n"
        return corps[:b.start(1)] + nouveau + corps[b.end(1):]

    nonlocal_total = [0]
    t2 = re.sub(r'<Specie id="RULES-RACE_([A-Z]+)">.*?</Specie>', espece, t, flags=re.S)
    print("%d lignes d'indisponibilite" % nonlocal_total[0])
    if "--dry" not in argv:
        LIVRE.write_text(t2, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

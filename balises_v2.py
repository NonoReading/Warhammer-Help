#!/usr/bin/env python3
"""Liste les balises filles (avec le nombre d'occurrences) de chaque element d'un chapitre sur tous les livres d'un dossier.
Usage : python balises_v2.py <dossier WFRP2> <DATA_xxx> [DATA_yyy ...]
Sert a ecrire les fiches WinLivre : chaque balise rencontree doit avoir son champ.
"""

import sys
from collections import Counter
from pathlib import Path

from lxml import etree

RACINE = Path(__file__).resolve().parent


def main() -> int:
    dossier, chapitres = sys.argv[1], sys.argv[2:]
    for chapitre in chapitres:
        comptes, attributs = Counter(), Counter()
        for livre in sorted((RACINE / "DATABASE" / dossier).glob("BOOK_*.Xml")):
            racine = etree.parse(str(livre), etree.XMLParser(remove_comments=True)).getroot()
            for bloc in racine.iter(chapitre):
                for el in bloc:
                    for enfant in el:
                        comptes[enfant.tag] += 1
                        for k in enfant.attrib:
                            attributs[f"{enfant.tag}@{k}"] += 1
        print(chapitre)
        for tag, n in comptes.most_common():
            print(f"   {n:6d} {tag}")
        for tag, n in attributs.most_common():
            print(f"   {n:6d} {tag}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Verifie l'ORDRE des balises que WinLivre ecrit (--winlivretest) pour chaque livre de DATABASE\\WFRP1.

L'export de test est bati a neuf, element par element, alors que la fenetre reecrit les elements deja presents
(leurs balises gardent leur place) : une validation XSD de la sortie serait faussee par les balises non affichees.
On compare donc, pour chaque element a id, la suite de ses balises enfants a celle du livre d'origine (valide au schema),
limitee aux balises presentes dans la sortie : un ecart = une balise ecrite a la mauvaise place.
Usage : python valider_export_winlivre_v1.py [filtre sur le nom]
"""

import subprocess
import sys
from pathlib import Path

from lxml import etree

RACINE = Path(__file__).resolve().parent
SORTIE = RACINE / "TEST_WL_SORTIE.xml"
ARBRE = RACINE / "TEST_WL_ARBRE.txt"


def enfants(el):
    return [c.tag for c in el if isinstance(c.tag, str)]


def index(doc):
    """(balise, id) -> element, pour les elements portant un id."""
    return {(e.tag, e.get("id")): e for e in doc.iter() if isinstance(e.tag, str) and e.get("id")}


def main() -> int:
    filtre = sys.argv[1].lower() if len(sys.argv) > 1 else ""
    echecs = 0
    for livre in sorted((RACINE / "DATABASE" / "WFRP1").glob("BOOK_*.Xml")):
        if filtre and filtre not in livre.name.lower():
            continue
        SORTIE.unlink(missing_ok=True)
        subprocess.run(["./WarhammerHelp.exe", "--winlivretest", str(livre), str(SORTIE), str(ARBRE)],
                       cwd=RACINE, timeout=300)
        if not SORTIE.exists():
            print(f"{livre.name} : ECHEC (pas de sortie)")
            echecs += 1
            continue
        origine = index(etree.parse(str(livre)))
        sortie = index(etree.parse(str(SORTIE)))
        mauvais = []
        for cle, el in sortie.items():
            ref = origine.get(cle)
            if ref is None:
                continue
            ecrit = enfants(el)
            attendu = [t for t in enfants(ref) if t in set(ecrit)]
            if ecrit != attendu:
                mauvais.append((cle, ecrit, attendu))
        if not mauvais:
            print(f"{livre.name} : OK : ordre des balises respecte ({len(sortie)} elements)")
        else:
            echecs += 1
            print(f"{livre.name} : {len(mauvais)} element(s) dans le mauvais ordre")
            for cle, ecrit, attendu in mauvais[:3]:
                print(f"   {cle[0]} {cle[1]}\n      ecrit   : {','.join(ecrit)}\n      attendu : {','.join(attendu)}")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())

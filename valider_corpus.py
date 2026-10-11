#!/usr/bin/env python3
"""Valide les livres XML du corpus contre SCHEMA_WFRP4.xsd / SCHEMA_WFRP5.xsd.

Usage :
  python valider_corpus.py                 -> valide tout le corpus (DATABASE/WFRP4 + WFRP5)
  python valider_corpus.py fichier1.xml ... -> valide seulement les fichiers donnes

Le schema applique a un fichier est choisi d'apres son dossier parent (WFRP4/WFRP5).
Code de sortie 0 si tout valide, 1 sinon (utilise par le hook pre-commit).
"""

import sys
from pathlib import Path

from lxml import etree

RACINE = Path(__file__).resolve().parent
SCHEMAS = {
    "WFRP4": RACINE / "SCHEMA_WFRP4.xsd",
    "WFRP5": RACINE / "SCHEMA_WFRP5.xsd",
}


def schema_pour(chemin: Path):
    for parent in chemin.parents:
        if parent.name in SCHEMAS:
            return SCHEMAS[parent.name]
    return None


def charger_schemas():
    caches = {}
    for version, chemin_xsd in SCHEMAS.items():
        caches[version] = etree.XMLSchema(etree.parse(str(chemin_xsd)))
    return caches


def fichiers_par_defaut():
    fichiers = []
    for version in SCHEMAS:
        dossier = RACINE / "DATABASE" / version
        if dossier.is_dir():
            fichiers.extend(sorted(dossier.glob("*.Xml")) + sorted(dossier.glob("*.xml")))
    return fichiers


def main(argv):
    cibles = [Path(a) for a in argv[1:]] if len(argv) > 1 else fichiers_par_defaut()
    cibles = [c for c in cibles if c.suffix.lower() == ".xml"]

    if not cibles:
        print("Aucun fichier XML a valider.")
        return 0

    schemas = charger_schemas()
    schema_traduction = etree.XMLSchema(etree.parse(str(RACINE / "SCHEMA_TRADUCTION.xsd")))
    erreurs = 0

    for chemin in cibles:
        xsd_chemin = schema_pour(chemin.resolve())
        if xsd_chemin is None:
            continue  # pas un livre WFRP4/WFRP5 (ex. INTERFACE.Xml) : hors perimetre du XSD
        version = xsd_chemin.stem.replace("SCHEMA_", "")
        schema = schemas[version]
        try:
            doc = etree.parse(str(chemin))
        except etree.XMLSyntaxError as e:
            print(f"[MAL FORME] {chemin} : {e}")
            erreurs += 1
            continue
        # Livre de traduction (balise TRANSLATION_OF) : valide contre SCHEMA_TRADUCTION.xsd,
        # qui n accepte que des libelles. Un livre non anglais SANS cette balise est un livre
        # normal et suit le schema de sa version.
        if doc.getroot().find("TRANSLATION_OF") is not None:
            schema = schema_traduction
        if not schema.validate(doc):
            print(f"[INVALIDE] {chemin} ({version})")
            for err in schema.error_log:
                print(f"    ligne {err.line} : {err.message}")
            erreurs += 1

    if erreurs:
        print(f"\n{erreurs} livre(s) invalide(s).")
        return 1

    print(f"{len(cibles)} livre(s) verifie(s), tous valides.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

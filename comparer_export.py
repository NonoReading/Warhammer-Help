#!/usr/bin/env python3
"""Compare un livre exporte (DATABASE_EXPORT) a son livre d'origine (DATABASE/WFRP4|WFRP5).

Principe : aller-retour XML source -> chargement -> export ; l'export doit redonner les
memes donnees. Comparaison SEMANTIQUE : commentaires et espaces ignores, ordre des freres
ignore. Chaque element devient une empreinte (chemin, attributs tries, texte) ; on compte
les empreintes de chaque cote et on rapporte ce qui manque ou ce qui est en trop.

L'export ne contient que la version de INI.TXT : on ne compare qu'a DATABASE/<cette version>
(WFRP4 et WFRP5 ont des livres de meme nom).

Usage :
  python comparer_export.py                    -> tous les livres exportes
  python comparer_export.py "archives of the empire ii" -> livres dont le nom contient ce texte
  python comparer_export.py -v ...             -> liste aussi chaque empreinte en ecart
Code de sortie 0 si aucun ecart, 1 sinon.
"""

import re
import sys
from collections import Counter
from pathlib import Path

from lxml import etree

RACINE = Path(__file__).resolve().parent
EXPORT = RACINE / "DATABASE_EXPORT"


def version_ini() -> str:
    """Version chargee par le programme (INI.TXT, VERSION=WFRP4|WFRP5) : celle qu'il exporte."""
    for ligne in (RACINE / "INI.TXT").read_text(encoding="utf-8", errors="replace").splitlines():
        if ligne.strip().upper().startswith("VERSION="):
            return ligne.split("=", 1)[1].strip()
    return "WFRP4"


SOURCES = [RACINE / "DATABASE" / version_ini()]


def cle_nom(chemin: Path) -> str:
    """Nom normalise : espaces et underscores confondus, casse ignoree."""
    return re.sub(r"[\s_]+", "_", chemin.stem).lower()


def texte(el) -> str:
    t = (el.text or "").strip()
    if len(t) >= 2 and t[0] == '"' and t[-1] == '"':
        t = t[1:-1]
    t = re.sub(r"\s+", " ", t)
    # un entier signe "+10" vaut "10" : le moteur relit les modificateurs en nombre
    return re.sub(r"^\+(\d+)$", r"\1", t)


# Balises facultatives dont la valeur par defaut equivaut a l'absence : le moteur ne distingue pas
# <Encumbrance>"0"</Encumbrance> d'une balise absente, l'export ne peut donc pas les distinguer.
DEFAUTS = {("Encumbrance", "0"), ("Modifier", ""), ("Carries", "0"), ("Magic", "0"), ("EyeRolls", "1")}


TEXTES_TALENT = {"Short", "Explanation", "PDF", "Test", "Max"}


def empreintes(chemin: Path, prefixe: str = "") -> Counter:
    """prefixe : ne garde que les empreintes dont le chemin commence par lui (ex. les libelles
    francais du fichier _FRANCAIS, que la source anglaise porte dans son propre DATA_LABEL)."""
    arbre = etree.parse(str(chemin), etree.XMLParser(remove_comments=True))
    cpt = Counter()

    def visite(el, parent_path):
        nom = etree.QName(el).localname
        attrs = tuple(sorted((k, v.strip()) for k, v in el.attrib.items()))
        # <ModifyDamage name="CC" if="COND">3</..> = <Modificateur Type="ModifyDamage" Cible="CC"
        # Facteur="3" Filtre="COND"/> : deux ecritures du meme modificateur conditionnel
        if "if" in el.attrib and "name" in el.attrib and nom.startswith("Modif"):
            nom, attrs = "Modificateur", tuple(sorted([
                ("Type", etree.QName(el).localname), ("Cible", el.attrib["name"].strip()),
                ("Facteur", re.sub(r"^\+", "", texte(el))), ("Filtre", el.attrib["if"].strip())]))
            path = parent_path + "/" + nom
            cpt[(path, attrs, "")] += 1
            return
        # Le libelle du titre du livre (<Text name="XXX-BOOK ...">) est synthetise au chargement
        # quand le livre ne le declare pas : l'export l'ecrit toujours. Ni ce libelle ni un
        # DATA_LABEL qui ne contiendrait que lui ne comptent comme ecart.
        if nom == "Text" and "-BOOK " in el.attrib.get("name", ""):
            return
        if nom == "DATA_LABEL" and not any(
                "-BOOK " not in t.attrib.get("name", "") for t in el.iter("Text")):
            return
        # memes ecritures sans condition : l'export ecrit la forme generique <Modificateur>
        if nom in ("ModifyDamage", "ModifArmour") and "name" in el.attrib and "if" not in el.attrib:
            attrs = tuple(sorted([("Type", nom), ("Cible", el.attrib["name"].strip()),
                                  ("Facteur", re.sub(r"^\+", "", texte(el)))]))
            cpt[(parent_path + "/Modificateur", attrs, "")] += 1
            return
        # <ModifySkill name="COMP">10</ModifySkill> numerique (talent) = <Modificateur Type="ModifySkill"
        # Cible=COMP Facteur=10> : le drapeau "Bonus"/"ChooseDice" n'est pas un modificateur chiffre
        if nom == "ModifySkill" and "name" in el.attrib and re.fullmatch(r"[+-]?\d+", texte(el)):
            attrs = tuple(sorted([("Type", nom), ("Cible", el.attrib["name"].strip()),
                                  ("Facteur", re.sub(r"^\+", "", texte(el)))]))
            cpt[(parent_path + "/Modificateur", attrs, "")] += 1
            return
        # <Modifier name="COMP">-10</Modifier> d'une qualite d'armure = <ModifySkillGear name=..>
        if nom == "Modifier" and "name" in el.attrib:
            nom = "ModifySkillGear"
        path = parent_path + "/" + nom
        if (etree.QName(el).localname, texte(el)) in DEFAUTS and not attrs:
            return
        # texte facultatif d'un talent : declare vide = absent (le moteur ne les distingue pas)
        if parent_path.endswith("/Talent") and nom in TEXTES_TALENT and texte(el) == "":
            return
        if path.startswith(prefixe):
            cpt[(path, attrs, texte(el))] += 1
        for enfant in el:
            if isinstance(enfant.tag, str):
                visite(enfant, path)

    visite(arbre.getroot(), "")
    return cpt


def trouver_sources():
    table = {}
    for dossier in SOURCES:
        for f in dossier.glob("*.[Xx][Mm][Ll]"):
            table[cle_nom(f)] = f
    return table


def main():
    args = [a for a in sys.argv[1:] if a != "-v"]
    verbeux = "-v" in sys.argv[1:]
    filtre = args[0].lower().replace(" ", "_") if args else ""
    sources = trouver_sources()
    total_ecarts = 0
    for exporte in sorted(EXPORT.glob("*.[Xx][Mm][Ll]")):
        cle = cle_nom(exporte)
        if filtre and filtre not in cle:
            continue
        source = sources.get(cle)
        if source is None:
            print(f"SANS SOURCE : {exporte.name}")
            continue
        a, b = empreintes(source), empreintes(exporte)
        francais = exporte.with_name(exporte.stem + "_FRANCAIS" + exporte.suffix)
        # seulement si le livre n a PAS de fichier francais source : sinon ses libelles francais sont ailleurs
        if francais.exists() and (cle + "_francais") not in sources:
            b += empreintes(francais, "/DATA_BOOK/DATA_LABEL/")
        manque, en_trop = a - b, b - a
        n = sum(manque.values()) + sum(en_trop.values())
        total_ecarts += n
        etat = "OK" if n == 0 else f"{n} ecarts"
        print(f"{etat:>12}  {exporte.name}")
        if n == 0:
            continue
        # Resume par chemin : ce qui manque (M) ou est en trop (T), sans les attributs/valeurs.
        resume = Counter()
        for (path, _, _), c in manque.items():
            resume[("M", path)] += c
        for (path, _, _), c in en_trop.items():
            resume[("T", path)] += c
        for (sens, path), c in sorted(resume.items(), key=lambda x: -x[1])[:25]:
            print(f"      {sens} {c:5d}  {path}")
        if verbeux:
            for (path, attrs, t), c in list(manque.items())[:200]:
                print(f"    - {c}x {path} {dict(attrs)} {t[:80]!r}")
            for (path, attrs, t), c in list(en_trop.items())[:200]:
                print(f"    + {c}x {path} {dict(attrs)} {t[:80]!r}")
    sys.exit(1 if total_ecarts else 0)


if __name__ == "__main__":
    main()

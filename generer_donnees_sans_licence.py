#!/usr/bin/env python3
"""Genere une copie des livres XML sans texte de livre (version sans licence).

Usage :
  python generer_donnees_sans_licence.py [SORTIE]      (defaut : DATABASE_SANS_LICENCE)

Lit DATABASE/WFRP4 et DATABASE/WFRP5 (jamais modifies), ecrit dans SORTIE/<version>/ :
  - le contenu des balises de prose (Explanation, Personality, Contraction, Symptoms,
    SpecialRule, ...) est vide ; noms (<Description>), chiffres, liens et <Page> restent ;
  - les commentaires XML sont retires (notes de saisie qui citent le livre) ;
  - les images ne sont pas copiees ;
  - seuls les livres de la liste blanche LIVRES_COMPLETS sont copies tels quels, texte complet
    (les livres de fan tiers sont vides comme les officiels).
Rapport : balises videes par livre, fiches videes SANS <Page> (l'interface n'aura alors
ni description ni page), et textes longs restants hors liste (a examiner).
"""
import re
import sys
from collections import Counter
from pathlib import Path

RACINE = Path(__file__).resolve().parent
VERSIONS = ["WFRP1", "WFRP2", "WFRP4", "WFRP5", "WFRPTOW"]
PROSE = ["Explanation", "Personality", "Contraction", "Symptoms", "SpecialRule",
         "Incubation", "Treatment", "Cure", "Effect", "Special", "Rules"]
SEUIL_RESTE = 90  # caracteres : au-dela, un texte non vide est signale
PROSE_LONGUE = ["Text", "Short", "Target", "Test"]  # videes seulement au-dela du seuil

RE_PROSE = re.compile(r"<(%s)((?:\s[^>]*)?)>(.*?)</\1>" % "|".join(PROSE), re.S)
RE_LONG = re.compile(r"<(%s)((?:\s[^>]*)?)>(.*?)</\1>" % "|".join(PROSE_LONGUE), re.S)
# V1 / V2 : autres balises de prose (videes au-dela du seuil seulement ; les listes Skills / Talents /
# Trappings sont des noms de donnees de jeu et restent).
PROSE_LONGUE_V12 = ["Note", "SpecialRules", "Conditions", "Consequences", "Powers", "PermanentEffect",
                    "TemporaryEffect", "History", "Ingredient", "Ingredients", "Trials", "Strictures",
                    "Rule", "Blessings", "Variations", "SideEffects"]
RE_LONG_V12 = re.compile(r"<(%s)((?:\s[^>]*)?)>(.*?)</\1>" % "|".join(PROSE_LONGUE_V12), re.S)
RE_COMMENT =re.compile(r"<!--.*?-->[ \t]*\r?\n?", re.S)
RE_FICHE = re.compile(r"<(\w+)\s+id=\"[^\"]*\"[^>]*>.*?</\1>", re.S)
RE_TEXTE = re.compile(r"<(\w+)(?:\s[^>]*)?>\"([^<\"]{%d,})\"</\1>" % SEUIL_RESTE)
GARDER = {"DISCLAIMER", "Description", "Name"}
# Livres gardes tels quels, texte complet : LISTE BLANCHE de noms de fichiers. Un livre de fan n'est
# pas libre de droits : seul un livre dont l'auteur est Nono, ou dont l'auteur a donne son accord
# (a noter dans Log.txt), peut figurer ici.
LIVRES_COMPLETS = {"BOOK_PERSO.Xml"}


def est_livre_complet(nom):
    return nom.lower() in {n.lower() for n in LIVRES_COMPLETS}


def vide_prose(texte, compteur, v12=False):
    def rempl(m):
        if m.group(3).strip() in ("", '""'):
            return m.group(0)
        compteur[m.group(1)] += 1
        return "<%s%s>\"\"</%s>" % (m.group(1), m.group(2), m.group(1))
    def rempl_long(m):
        v = m.group(3).strip().strip('"')
        if len(v) < SEUIL_RESTE:
            return m.group(0)
        compteur[m.group(1)] += 1
        return "<%s%s>\"\"</%s>" % (m.group(1), m.group(2), m.group(1))
    texte = RE_PROSE.sub(rempl, texte)
    texte = RE_LONG.sub(rempl_long, texte)
    return RE_LONG_V12.sub(rempl_long, texte) if v12 else texte


def sans_page(avant, apres):
    """Fiches dont une prose a ete videe alors qu'elles n'ont aucune <Page>."""
    manque = []
    for m in RE_FICHE.finditer(avant):
        bloc = m.group(0)
        if not RE_PROSE.search(bloc):
            continue
        if re.search(r"<Page>\s*[^<\s]", bloc):
            continue
        if any(m2.group(3).strip() not in ("", '""') for m2 in RE_PROSE.finditer(bloc)):
            ident = re.match(r"<\w+\s+id=\"([^\"]*)\"", bloc).group(1)
            manque.append(ident)
    return manque


def main():
    sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "DATABASE_SANS_LICENCE"
    total = Counter()
    for version in VERSIONS:
        source = RACINE / "DATABASE" / version
        if not source.is_dir():
            continue
        dest = sortie / version
        dest.mkdir(parents=True, exist_ok=True)
        for f in sorted(source.glob("*.[Xx][Mm][Ll]")):
            brut = f.read_bytes()
            texte = brut.decode("utf-8-sig", errors="replace")
            if est_livre_complet(f.name):
                (dest / f.name).write_bytes(brut)
                print("%s/%s : livre complet (liste blanche), copie telle quelle" % (version, f.name))
                continue
            compteur = Counter()
            manque = sans_page(texte, None)
            texte2 = vide_prose(texte, compteur, version in ("WFRP1", "WFRP2"))
            texte2 = RE_COMMENT.sub("", texte2)
            (dest / f.name).write_text(texte2, encoding="utf-8", newline="")
            reste = [(t, len(v)) for t, v in RE_TEXTE.findall(texte2) if t not in GARDER]
            rest_c = Counter(t for t, _ in reste)
            n = sum(compteur.values())
            total.update(compteur)
            print("%s/%s : %d textes vides (%d -> %d octets)"
                  % (version, f.name, n, len(texte.encode()), len(texte2.encode())))
            if manque:
                print("   sans <Page> : %d fiche(s), ex. %s" % (len(manque), ", ".join(manque[:3])))
            if rest_c:
                print("   textes longs restants : " + ", ".join("%s x%d" % kv for kv in rest_c.most_common(6)))
    print("TOTAL par balise :", dict(total))
    print("Sortie :", sortie)


if __name__ == "__main__":
    main()

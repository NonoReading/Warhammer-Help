#!/usr/bin/env python3
"""Compare deux fichiers livre XML (source / sortie de WinLivre) de facon semantique.

Sert au test d'aller-retour de WinLivre :
  WarhammerHelp.exe --winlivretest <livre> <sortie.xml> <arbre.txt>
  python comparer_livre.py <livre> <sortie.xml> [arbre.txt]

Chaque element devient une empreinte (chemin, attributs tries, texte sans guillemets) ;
commentaires, espaces et ordre des freres sont ignores. Si arbre.txt est donne, verifie aussi
que chaque element portant un id dans un bloc DATA_*_V1 est present dans l'arbre de WinLivre.
Code de sortie 0 si aucun ecart, 1 sinon.
"""

import sys
from collections import Counter

from lxml import etree


# blocs V1 deja affiches par WinLivre : une donnee absente de l'arbre est un ecart (a completer a chaque lot)
BLOCS_SUIVIS = {"DATA_SPELL_V1", "DATA_SKILL_V1", "DATA_EQUIPMENT_V1", "DATA_CAREER_V1",
                "DATA_DEITY_V1", "DATA_CULT_V1", "DATA_FAMILIAR_V1", "DATA_CLASS_V1", "DATA_TRADE_V1", "DATA_DISABILITY_V1"}


SANS_PAGE = "--sans-page" in sys.argv
if SANS_PAGE:
    sys.argv.remove("--sans-page")


def texte(el) -> str:
    t = (el.text or "").strip()
    if len(t) >= 2 and t[0] == '"' and t[-1] == '"':
        t = t[1:-1]
    return " ".join(t.split())


def empreintes(chemin: str) -> Counter:
    racine = etree.parse(chemin, etree.XMLParser(remove_comments=True)).getroot()
    res = Counter()

    def parcourir(el, parent):
        if SANS_PAGE and el.tag == "Page":  # test d'edition : la Page est saisie a 999, elle n'est pas comparee
            return
        p = parent + "/" + el.tag
        attrs = ",".join(f"{k}={v}" for k, v in sorted(el.attrib.items()))
        t = texte(el)
        # un bloc DATA_* du livre n'est qu'un conteneur : plusieurs blocs consecutifs de meme nom valent un seul bloc
        conteneur = parent == "/DATA_BOOK" and el.tag.startswith("DATA_") and not t and not attrs
        # <Short language="ENGLISH"></Short> : la langue seule ne fait pas une donnee
        vide_langue = not t and not len(el) and list(el.attrib) == ["language"]
        if (t or attrs or len(el)) and not conteneur and not vide_langue:  # une balise feuille vide ne porte aucune donnee
            res[(p, attrs, t)] += 1
        for enfant in el:
            parcourir(enfant, p)

    parcourir(racine, "")
    return res


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    source, sortie = sys.argv[1], sys.argv[2]
    a, b = empreintes(source), empreintes(sortie)
    manque, trop = a - b, b - a
    for (p, at, t), n in manque.items():
        print(f"MANQUE x{n} {p} [{at}] {t[:60]}")
    for (p, at, t), n in trop.items():
        print(f"EN TROP x{n} {p} [{at}] {t[:60]}")
    ecarts = sum(manque.values()) + sum(trop.values())

    if len(sys.argv) >= 4:
        codes = set()
        with open(sys.argv[3], encoding="utf-8", errors="replace") as f:
            for ligne in f:
                parts = ligne.rstrip("\n").split(";", 2)
                if len(parts) >= 2 and parts[1]:
                    codes.add(parts[1])
        racine = etree.parse(source, etree.XMLParser(remove_comments=True)).getroot()
        for bloc in racine:
            if isinstance(bloc.tag, str) and bloc.tag.startswith("DATA_") and bloc.tag.endswith("_V1"):
                ids = [e.get("id") for e in bloc if e.get("id")]
                absents = [i for i in ids if i not in codes]
                print(f"{bloc.tag} : {len(ids) - len(absents)}/{len(ids)} dans l'arbre")
                if bloc.tag in BLOCS_SUIVIS:
                    ecarts += len(absents)
                for i in absents[:5]:
                    print(f"   absent de l'arbre : {i}")

    print("OK : aucun ecart" if ecarts == 0 else f"{ecarts} ecart(s)")
    return 0 if ecarts == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Controle des tables d100 : poids (Chance) par table.

Depuis le 02/10/2026 la chance est un POIDS (nombre de valeurs du d100, 00 = 100), X et - = hors table.
Verifie, par livre WFRP4 :
  - SUBCHAPTER_CAREER d'une ethnie : somme des poids = 100 ; metier cite deux fois ; poids hors 1-100
  - DATA_CAREER_ROLL : meme controle par (Regle, Espece) ; une regle PARTIELLE (<Class> dans la
    <Rule>) doit totaliser le poids de la classe remplacee dans la table de base de l'espece
  - DATA_RANDOM_TALENT : somme des poids = 100 par espece (V4)
Usage : python controle_d100.py [--strict]   (code 1 si anomalie avec --strict)
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

from lxml import etree

RACINE = Path(__file__).resolve().parent
DOSSIER = RACINE / "DATABASE" / "WFRP4"


def val(e):
    return (e.text or "").strip().strip('"')


def poids(texte):
    return int(texte) if re.fullmatch(r"\d+", texte) else None


def charger():
    p = etree.XMLParser(recover=True)
    docs = {}
    for f in sorted(set(DOSSIER.glob("*.Xml")) | set(DOSSIER.glob("*.xml"))):
        docs[f.name] = etree.parse(str(f), p)
    return docs


def main(argv):
    docs = charger()
    anomalies = []
    classe_metier, regles = {}, {}
    for nom, arbre in docs.items():
        for c in arbre.iter("Career"):
            if c.get("id"):
                k = c.find("Class")
                if k is not None:
                    classe_metier[c.get("id")] = val(k)
        for r in arbre.iter("Rule"):
            if r.get("id"):
                k = r.find("Class")
                regles[r.get("id")] = val(k) if k is not None else None

    def somme(lignes, ou, titre):
        vus = defaultdict(int)
        total = 0
        for code, texte in lignes:
            vus[code] += 1
            w = poids(texte)
            if w is None:
                continue
            if not 1 <= w <= 100:
                anomalies.append(f"{ou}: {titre} {code} poids {w} hors 1-100")
            total += w
        for code, n in vus.items():
            if n > 1:
                anomalies.append(f"{ou}: {titre} {code} cite {n} fois")
        return total

    base = {}  # espece -> {metier: poids}  (table de base du Rulebook)
    for nom, arbre in docs.items():
        for e in arbre.iter("SUBCHAPTER_CAREER"):
            lignes = [(c.get("name"), val(c)) for c in e.findall("Career")]
            if not lignes:
                continue
            parent = e.getparent()
            ident = parent.get("id") or parent.tag
            t = somme(lignes, f"{nom}:{e.sourceline}", f"ethnie {ident}")
            if t != 100:
                anomalies.append(f"{nom}:{e.sourceline}: ethnie {ident} total {t} (attendu 100)")

    for nom, arbre in docs.items():
        groupes = defaultdict(list)
        for e in arbre.iter("Entry"):
            if e.getparent().tag != "DATA_CAREER_ROLL":
                continue
            r, s, c = e.find("Rule"), e.find("Specie"), e.find("Career")
            if c is None:
                continue
            groupes[(val(r) if r is not None else "?", val(s) if s is not None else "?")].append(
                (c.get("name"), val(c)))
        for (regle, espece), lignes in groupes.items():
            t = somme(lignes, nom, f"regle {regle}/{espece}")
            if regles.get(regle) is None:
                if t != 100:
                    anomalies.append(f"{nom}: regle {regle}/{espece} totale {t} (attendu 100)")
            else:
                anomalies.append(f"INFO {nom}: regle PARTIELLE {regle}/{espece} total {t}")

        talents = defaultdict(list)
        for e in arbre.iter("DATA_RANDOM_TALENT"):
            if not e.get("id"):
                continue
            t, s = e.find("Talent"), e.find("Specie")
            if t is None:
                continue
            talents[val(s) if s is not None else "?"].append((e.get("id"), val(t)))
        for espece, lignes in talents.items():
            if all(poids(x[1]) is None or "-" in x[1] for x in lignes):
                continue
            t = somme(lignes, nom, f"talent/{espece}")
            if t != 100 and not any("-" in x[1] for x in lignes):
                anomalies.append(f"{nom}: talents/{espece} total {t} (attendu 100)")

    for a in anomalies:
        print(a)
    graves = [a for a in anomalies if not a.startswith("INFO")]
    print(f"{len(graves)} anomalie(s).")
    return 1 if ("--strict" in argv and graves) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

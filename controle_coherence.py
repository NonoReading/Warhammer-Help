#!/usr/bin/env python3
"""Controle de coherence des livres XML : references pendantes.

Complete valider_corpus.py (structure XSD) : ici on verifie qu'un code CITE (carriere, arme,
objet, talent, libelle...) est DEFINI quelque part dans le corpus de la meme version.

Usage :
  python controle_coherence.py                  -> tout le corpus (WFRP4 puis WFRP5)
  python controle_coherence.py fichier1.xml ... -> ne rapporte que les references de ces livres
                                                   (les definitions viennent toujours du corpus entier)
  --strict                                      -> code de sortie 1 s'il reste une reference pendante

Signale tout bloc de premier niveau present deux fois dans un livre (le programme n'en lit que le premier).

Controle aussi, sur le corpus entier, qu'aucun livre (hors traduction) ne partage le libelle <BOOK> d'un autre.

Definitions reconnues : attribut id=, <Text name=> (libelles, INTERFACE*.Xml compris) et
name= des balises DEF_TAGS (Corruption, Disease, Affliction : entrees qui se definissent par
name=). Sont ignores : PREFIXES_ENUM (enumerations du programme, sans entree XML) et
MOTIFS_ADMIS (codes generiques resolus par le programme). Le resultat sans --strict est un
AVERTISSEMENT (code 0) : le hook pre-commit l'affiche sans bloquer.
"""

import os
import re
import sys
from collections import Counter
from pathlib import Path

from lxml import etree

RACINE = Path(__file__).resolve().parent
VERSIONS = ("WFRP4", "WFRP5")

# Balises dont name= DEFINIT l'entree (au lieu d'y faire reference).
DEF_TAGS = {"Corruption", "Disease", "Affliction"}
# Balises dont le contenu est du texte libre, jamais une reference.
TAGS_TEXTE = {"Text", "Description", "Explanation", "Name"}
# Prefixes de code qui sont des enumerations du programme (aucune entree XML).
PREFIXES_ENUM = ("WTYPE",)
# Blocs ou un meme id= revient legitimement (une ligne par colonne d'ethnie).
BLOCS_MATRICE = {"DATA_RANDOM_TALENT"}
# Codes generiques resolus par le programme (pas d'entree exacte).
MOTIFS_ADMIS = (re.compile(r"^[A-Z0-9]{3,6}-LORE_\*$"),)

CODE = re.compile(r"^[A-Z0-9]{3,6}-[A-Za-z0-9_*]+$")
SEPARATEURS = re.compile(r"[+/;,]")


def fichiers_version(version):
    dossier = RACINE / "DATABASE" / version
    if not dossier.is_dir():
        return []
    return sorted(set(dossier.glob("*.Xml")) | set(dossier.glob("*.xml")))


def fichiers_interface():
    return sorted((RACINE / "DATABASE").glob("INTERFACE*.Xml"))


def charger(fichiers):
    parseur = etree.XMLParser(recover=True)
    return {f: etree.parse(str(f), parseur) for f in fichiers}


def definitions(docs):
    defs = set()
    for arbre in docs.values():
        for e in arbre.iter():
            if not isinstance(e.tag, str):
                continue
            if e.get("id"):
                defs.add(e.get("id"))
            if e.get("name") and (e.tag == "Text" or e.tag in DEF_TAGS):
                defs.add(e.get("name"))
    return defs


def codes_cites(element):
    """Codes cites par un element : attribut name= ou contenu entre guillemets."""
    valeurs = []
    if element.get("name"):
        valeurs.append(element.get("name"))
    else:
        texte = (element.text or "").strip().strip('"')
        if texte:
            valeurs.append(texte)
    for valeur in valeurs:
        for morceau in SEPARATEURS.split(valeur):
            morceau = morceau.strip().strip('"')
            if CODE.match(morceau):
                yield morceau


def est_admis(code):
    if code.split("-", 1)[1].split("_", 1)[0] in PREFIXES_ENUM:
        return True
    return any(m.match(code) for m in MOTIFS_ADMIS)


def controle(version, cibles):
    docs = charger(fichiers_version(version) + fichiers_interface())
    defs = definitions(docs)
    pendantes = []
    for chemin, arbre in docs.items():
        if "INTERFACE" in chemin.name:
            continue
        if cibles and chemin.resolve() not in cibles:
            continue
        for e in arbre.iter():
            if not isinstance(e.tag, str) or e.tag in TAGS_TEXTE:
                continue
            # condition d'un modificateur (if=) : doit etre declaree par un DATA_CONDITION (ou un libelle)
            cond = (e.get("if") or "").strip()
            if cond and CODE.match(cond) and cond not in defs:
                pendantes.append((chemin.name, e.sourceline, e.tag + " if=", cond))
            if e.get("name") and e.tag in DEF_TAGS:
                continue
            for code in codes_cites(e):
                if code not in defs and not est_admis(code):
                    pendantes.append((chemin.name, e.sourceline, e.tag, code))
    return pendantes


def libelles_partages(version):
    """Livres (hors traductions, balise TRANSLATION_OF) qui portent le meme libelle d'en-tete <BOOK>.

    Le champ Livre des elements stocke ce libelle : deux livres qui le partagent se confondent
    (retrait par XmlRetireLivre, filtres par livre). Les traductions le partagent par construction.
    """
    par_libelle = {}
    for chemin, arbre in charger(fichiers_version(version)).items():
        racine = arbre.getroot()
        if racine is None or racine.find("TRANSLATION_OF") is not None:
            continue
        noeud = racine.find("BOOK")
        libelle = (noeud.text or "").strip().strip('"') if noeud is not None else ""
        if libelle:
            par_libelle.setdefault(libelle, []).append(chemin.name)
    return {l: f for l, f in par_libelle.items() if len(f) > 1}


def actions_classe_sans_cible(version):
    """Remove / Replace de DATA_CLASS_ITEM dont la cible n'est donnee a la classe par aucun livre."""
    docs = charger(fichiers_version(version))
    donnes = {}
    for doc in docs.values():
        for classe in doc.iter("Class"):
            if classe.getparent() is None or classe.getparent().tag != "DATA_CLASS_ITEM":
                continue
            for item in classe.iter("Item"):
                for part in item.get("name", "").split("+"):
                    donnes.setdefault(classe.get("name"), set()).add(part.strip())
    manques = []
    for f, doc in docs.items():
        for classe in doc.iter("Class"):
            if classe.getparent() is None or classe.getparent().tag != "DATA_CLASS_ITEM":
                continue
            for balise in classe:
                if balise.tag == "Remove":
                    cible = (balise.text or "").strip().strip('"')
                elif balise.tag == "Replace":
                    cible = balise.get("from", "")
                else:
                    continue
                if cible not in donnes.get(classe.get("name"), set()):
                    manques.append((f.name, balise.sourceline, balise.tag, classe.get("name"), cible))
    return manques


def blocs_en_double(version):
    """Blocs de premier niveau (DATA_*) presents deux fois dans un livre.

    BookNode.FindNode (programme) ne renvoie que le PREMIER bloc de ce nom : le second est
    ignore en silence au chargement.
    """
    doubles = []
    for f, doc in charger(fichiers_version(version)).items():
        vus = {}
        for bloc in doc.getroot():
            if not isinstance(bloc.tag, str):
                continue
            if bloc.tag in vus:
                doubles.append((f.name, bloc.sourceline, bloc.tag, vus[bloc.tag]))
            else:
                vus[bloc.tag] = bloc.sourceline
    return doubles


def ids_en_double(version):
    """Entrees de meme tag et de meme id= dans un meme livre (le programme en garde une seule)."""
    doubles = []
    for f, doc in charger(fichiers_version(version)).items():
        vus = {}
        for e in doc.getroot().iter():
            if not isinstance(e.tag, str) or not e.get("id"):
                continue
            parent = e.getparent()
            if parent is not None and parent.tag in BLOCS_MATRICE:
                continue
            if parent is None or parent.getparent() is not doc.getroot() and parent is not doc.getroot():
                continue
            cle = (parent.tag, e.tag, e.get("id"))
            if cle in vus:
                doubles.append((f.name, e.sourceline, e.tag, e.get("id"), vus[cle]))
            else:
                vus[cle] = e.sourceline
    return doubles


def elements_egares(version):
    """Enfant direct d'un bloc DATA_* dont la balise est rare pour ce bloc dans tout le corpus.

    Un <Foo> egare dans un DATA_TALENT serait traite comme une entree : on signale les balises
    vues moins de 3 fois (corpus entier) sous ce nom de bloc.
    """
    docs = charger(fichiers_version(version))
    total = {}
    emplacements = []
    for f, doc in docs.items():
        for bloc in doc.getroot():
            if not isinstance(bloc.tag, str) or not bloc.tag.startswith("DATA_"):
                continue
            for e in bloc:
                if isinstance(e.tag, str):
                    total.setdefault(bloc.tag, Counter())[e.tag] += 1
                    emplacements.append((f.name, e.sourceline, bloc.tag, e.tag))
    return [(f, l, b, t) for f, l, b, t in emplacements if total[b][t] < 3 and sum(total[b].values()) >= 10]


def balises_sans_code(version):
    """Blocs DATA_* du corpus dont le nom n'apparait dans aucune unite Pascal : ni lu ni exporte."""
    sources = "".join(p.read_text(encoding="utf-8", errors="replace") for p in RACINE.glob("*.pas"))
    manques = {}
    for f, doc in charger(fichiers_version(version)).items():
        for bloc in doc.getroot():
            if isinstance(bloc.tag, str) and bloc.tag.startswith("DATA_") and f"'{bloc.tag}'" not in sources:
                manques.setdefault(bloc.tag, []).append(f.name)
    return manques


def main(argv):
    strict = "--strict" in argv
    args = [a for a in argv[1:] if a != "--strict"]
    cibles = {Path(a).resolve() for a in args}
    total = 0
    for version in VERSIONS:
        fichiers = {f.resolve() for f in fichiers_version(version)}
        if cibles and not (cibles & fichiers):
            continue
        pendantes = controle(version, cibles & fichiers if cibles else None)
        for livre, ligne, balise, code in pendantes:
            print(f"{version}/{livre}:{ligne}: <{balise}> reference pendante {code}")
        total += len(pendantes)
        for livre, ligne, balise, classe, cible in actions_classe_sans_cible(version):
            print(f"{version}/{livre}:{ligne}: <{balise}> de {classe} : cible absente {cible} (ignoree)")
            total += 1
        for livre, ligne, balise, premiere in blocs_en_double(version):
            if cibles and (RACINE / "DATABASE" / version / livre).resolve() not in cibles:
                continue
            print(f"{version}/{livre}:{ligne}: bloc <{balise}> en double (premier ligne {premiere}, ignore au chargement)")
            total += 1
        if not cibles:
            for livre, ligne, balise, code, premiere in ids_en_double(version):
                print(f"{version}/{livre}:{ligne}: <{balise}> id en double {code} (premier ligne {premiere})")
                total += 1
            for livre, ligne, bloc, balise in elements_egares(version):
                print(f"{version}/{livre}:{ligne}: <{balise}> rare dans {bloc} (element egare ?)")
                total += 1
            for balise, livres in balises_sans_code(version).items():
                print(f"{version}: bloc <{balise}> inconnu du programme ({', '.join(livres[:3])})")
                total += 1
            for libelle, noms in libelles_partages(version).items():
                print(f"{version}: libelle de livre partage \"{libelle}\" : {', '.join(noms)}")
                total += 1
    if total:
        print(f"{total} anomalie(s) (references pendantes, libelles de livre partages ; avertissement).")
    else:
        print("Coherence : aucune reference pendante.")
    return 1 if (strict and total) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

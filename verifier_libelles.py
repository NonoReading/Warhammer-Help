#!/usr/bin/env python3
"""Verification de masse des libelles anglais : cherche chaque <Text> ANGLAIS des livres
dans le texte brut des livres (LIVRES/*.txt, PDF_TEXTE/**/*.txt) et liste ceux introuvables.

Usage : python verifier_libelles.py [WFRP4|WFRP5] [--casse] [--corpus-livres]
  --casse          : passe sensible a la casse (cas "Language (khazalid)")
  --corpus-livres  : ne cherche que dans LIVRES/ (les livres modelises), sinon aussi PDF_TEXTE/

Un libelle introuvable n'est pas une erreur : aller voir le livre (faux positifs : conventions
du programme, libelles de l'interface, noms construits).
"""
import re, sys, glob, collections, html
from pathlib import Path

RACINE = Path(__file__).resolve().parent
IGNORE = re.compile(r"(LAB_|MESS_|PDF_|_NAME$|^[A-Z]+-BOOK |INTERFACE)")

def norm(t, casse):
    t = t.replace("\u2019", "'").replace("\u2018", "'").replace("`", "'")
    t = t.replace("\u2013", "-").replace("\u2014", "-").replace("\ufb01", "fi").replace("\ufb02", "fl")
    t = re.sub(r"-\s*\n\s*", "", t)
    t = re.sub(r"\s+", " ", t)
    return t if casse else t.lower()

def main(argv):
    casse = "--casse" in argv
    seul = "--corpus-livres" in argv
    version = next((a for a in argv[1:] if a.startswith("WFRP")), "WFRP4")
    fichiers = list((RACINE / "LIVRES").glob("*.txt"))
    if not seul:
        fichiers += [Path(p) for p in glob.glob(str(RACINE / "PDF_TEXTE" / "**" / "*.txt"), recursive=True)]
    corpus = norm("\n".join(f.read_text(encoding="utf-8", errors="replace") for f in fichiers), casse)
    print(f"{len(fichiers)} fichiers texte, {len(corpus)//1000} Ko ({'sensible' if casse else 'insensible'} a la casse)")
    manques = collections.defaultdict(list)
    total = 0
    composes = 0
    proches = 0
    for f in sorted((RACINE / "DATABASE" / version).glob("BOOK*.[xX]ml")):
        t = f.read_text(encoding="utf-8", errors="replace")
        courant, genre = "", ""
        for ligne in t.splitlines():
            e = re.search(r'<(\w+) id="([^"]+)"', ligne)
            if e:
                genre, courant = e.group(1), e.group(2)
                continue
            d = re.search(r'<Description language="ENGLISH">"([^"]*)"</Description>', ligne)
            if not d:
                continue
            val = html.unescape(d.group(1))
            if len(val) < 3 or not re.search(r"[A-Za-z]{3}", val) or IGNORE.search(courant):
                continue
            total += 1
            if norm(val, casse) not in corpus:
                c = re.match(r"^(.*?)\s*\((.*)\)\s*$", val)
                if c and (norm(c.group(2), casse) in corpus) and (norm(c.group(1), casse) in corpus):
                    composes += 1   # "Base (Spec)" : les deux moities existent, forme composee construite
                    continue
                mots = re.findall(r"[^\W_]+", norm(val, casse))
                if len(mots) >= 2 and re.search(r".{0,150}?".join(map(re.escape, mots)), corpus, re.S):
                    proches += 1    # mots dans l'ordre a moins de 150 car. : mise en page en tableau
                    continue
                manques[(f.name, genre)].append((courant, val))
    n = sum(len(v) for v in manques.values())
    print(f"{n} introuvables sur {total} ({composes} formes composees 'Base (Spec)' dont les deux moities existent, non listees ; {proches} dont les mots se suivent de pres : tableaux, non listes)")
    for (livre, fam), l in sorted(manques.items()):
        print(f"\n## {livre} / {fam} ({len(l)})")
        for nom, val in l:
            print(f"  {nom}\t{val}")

if __name__ == "__main__":
    main(sys.argv)

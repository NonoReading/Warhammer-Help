#!/usr/bin/env python3
"""Les specialisations (competences, talents) heritent la <Page> de leur fiche mere (<Generique>).
Usage : python pages_heritage.py [--ecrire]   (corpus DATABASE/WFRP4 et WFRP5, mere cherchee dans toute l'edition)"""
import re, sys, glob
from pathlib import Path
ecrire = "--ecrire" in sys.argv
for edition in ("WFRP4", "WFRP5"):
    fichiers = [x for x in glob.glob(f"DATABASE/{edition}/BOOK*.[Xx]ml") if "FRANCAIS" not in x.upper()]  # anglais seul
    pages = {}
    noms = {}
    parfichier = {}
    for f in fichiers:
        bloc = None
        parfichier[f] = {}
        for l in Path(f).read_text(encoding="utf-8").splitlines():
            l = l.strip()
            m = re.fullmatch(r"<(DATA_\w+)>", l)
            if m: bloc = m.group(1)
            m = re.match(r'<(?:Talent|Skill) id="([^"]+)">', l)
            if m and bloc in ("DATA_TALENT", "DATA_SKILL"): cur = m.group(1)
            m = re.match(r'<Description language="ENGLISH">"?([^<"]*)', l)
            if m and bloc in ("DATA_TALENT", "DATA_SKILL"): nomcur = m.group(1).strip().lower()
            m = re.match(r"<Page>([^<]+)</Page>", l)
            if m and bloc in ("DATA_TALENT", "DATA_SKILL"):
                pages[cur] = m.group(1)
                parfichier[f][cur] = m.group(1)
                noms.setdefault(nomcur, m.group(1))
    total = manque = 0
    for f in fichiers:
        texte = Path(f).read_bytes().decode("utf-8")
        crlf = "\r\n" in texte
        L = texte.split("\n"); bloc = None; i = 0; ajout = 0
        derniere = None
        for x in L:
            mpg = re.match(r"<Page>([^<]+)</Page>", x.strip())
            if mpg:
                derniere = mpg.group(1)
                break
        while i < len(L):
            s = L[i].strip()
            m = re.fullmatch(r"<(DATA_\w+)>", s)
            if m: bloc = m.group(1)
            m = re.match(r'<(Talent|Skill) id="([^"]+)">$', s)
            if m and bloc in ("DATA_TALENT_SPECIALIZATION", "DATA_SKILL_SPECIALIZATION"):
                j = i + 1; gen = None; deja = False; base = None
                while j < len(L) and L[j].strip() != f"</{m.group(1)}>":
                    g = re.match(r'<Generique>"?([^<"]*)', L[j].strip())
                    if g and gen is None: gen = g.group(1)
                    d = re.match(r'<Description language="ENGLISH">"?([^"<(]*)', L[j].strip())
                    if d and base is None: base = d.group(1).strip().lower()
                    if L[j].strip().startswith("<Page>"): deja = True
                    j += 1
                if not deja:
                    # Livre francais : pagination propre, la mere doit etre dans le meme fichier
                    table = parfichier[f] if "FRANCAIS" in f else pages
                    if not (gen and gen in table) and base and base in noms and "FRANCAIS" not in f:
                        table = {gen: noms[base]}
                    if gen and gen in table:
                        if ecrire:
                            L.insert(j, f"<Page>{table[gen]}</Page>" + ("\r" if crlf else ""))
                            j += 1
                        ajout += 1
                    elif derniere and "FRANCAIS" not in f:
                        # Mere sans page : premiere page connue du livre (valeur de repli)
                        if ecrire:
                            L.insert(j, f"<Page>{derniere}</Page>" + ("\r" if crlf else ""))
                            j += 1
                        ajout += 1
                    else:
                        manque += 1
                i = j
            i += 1
        if ecrire and ajout:
            Path(f).write_bytes("\n".join(L).encode("utf-8"))
        total += ajout
    print(f"{edition}: {total} specialisations heritent, {manque} sans mere paginee")

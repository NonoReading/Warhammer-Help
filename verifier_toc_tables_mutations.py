# -*- coding: utf-8 -*-
"""Compare les tables de mutations 3-1 a 3-5 du TXT de Tome of Corruption avec les
<Chance> du XML (V2-TOC-RESTES). Lecture seule. Usage : python verifier_toc_tables_mutations.py"""
import re

TXT = r"PDF_TEXTE\PDF_TEXTE_V2\Tome of Corruption.txt"
XML = r"DATABASE\WFRP2\BOOK_TOME_OF_CORRUPTION.Xml"

# (titre dans le TXT, lore dans le XML ou None pour la table 3-1)
TABLES = [("Table 3–1: Mutations", None), ("Table 3–2: Mutations of Khorne", "Khorne"),
          ("Table 3–3: Mutations of Nurgle", "Nurgle"), ("Table 3–4: Mutations of Slaanesh", "Slaanesh"),
          ("Table 3–5: Mutations of Tzeentch", "Tzeentch")]

def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())

xml = open(XML, encoding="utf-8").read()
noms = {}
for m in re.finditer(r'<Corruption name="(TOC-MUTA_[^"]+)">\s*<Description language="ENGLISH">"([^"]*)"', xml):
    noms[m.group(1)] = m.group(2)
chances = {}
for m in re.finditer(r'<Chance name="([^"]+)"( lore="([^"]+)")?>"([^"]+)"</Chance>', xml):
    lore = m.group(3)
    chances.setdefault(lore, []).append((m.group(1), m.group(4)))

lignes = open(TXT, encoding="utf-8").read().split("\n")
ENTREE = re.compile(r"(\d{2,3}(?:[–-]\d{2,3})?)\s{2,}(\S+(?: \S+)*)\s{2,}(\d(?:[–/-]\d)*|[Tt]wo [Tt]otals|Varies)\s{2,}(\d{1,3})(?=\s{2,}|\s*$)")

for titre, lore in TABLES:
    debut = [i for i, l in enumerate(lignes) if titre in l and l.strip().startswith("Table")]
    if not debut:
        print(titre, ": titre introuvable")
        continue
    # les tables peuvent tenir sur 2 pages : on lit 2 x 70 lignes apres le titre
    attendu = {}
    for i in debut:
        fenetre = 900 if lore is None else 70
        for l in lignes[i:i + fenetre]:
            if lore is None and "Table 3–2" in l:
                break
            for m in ENTREE.finditer(l):
                roll = m.group(1).replace("–", "-")
                if lore is None and len(roll) < 7:
                    continue
                if roll not in attendu:
                    attendu[roll] = (m.group(2).strip(), m.group(3), m.group(4))
    xml_t = chances.get(lore, [])
    xml_d = {}
    for roll, code in xml_t:
        xml_d.setdefault(roll, noms.get(code, "?" + code))
    print("==", titre, ": TXT", len(attendu), "entrees, XML", len(xml_t))
    for roll, (nom, fear, page) in attendu.items():
        x = xml_d.get(roll)
        if x is None:
            print("  absent du XML :", roll, nom)
        elif norm(x) != norm(nom):
            print("  difference :", roll, "TXT =", nom, "| XML =", x)
    for roll, x in xml_d.items():
        if roll not in attendu:
            print("  absent du TXT (ou non lu) :", roll, x)

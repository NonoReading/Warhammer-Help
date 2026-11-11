# -*- coding: utf-8 -*-
"""Deplace des items de A_FAIRE.xml vers A_FAIRE_ARCHIVE.xml (etat clos, date de cloture).
Usage : python archiver_item_a_faire.py JJ/MM/AAAA ID1 [ID2 ...]"""
import re
import sys

date = sys.argv[1]
ids = sys.argv[2:]
src = open("A_FAIRE.xml", encoding="utf-8", newline="").read()
arc = open("A_FAIRE_ARCHIVE.xml", encoding="utf-8", newline="").read()
for i in ids:
    m = re.search(r'  <Item id="%s" section="([^"]*)" etat="[^"]*"([^>]*)>.*?</Item>\r?\n' % re.escape(i), src, re.S)
    if not m:
        print("introuvable :", i)
        continue
    bloc = m.group(0)
    entete = '  <Item id="%s" section="%s" etat="clos" cloture="%s">' % (i, m.group(1), date)
    bloc = re.sub(r'^  <Item [^>]*>', entete, bloc)
    src = src.replace(m.group(0), "")
    fin = arc.rindex("</AFaire>")
    arc = arc[:fin] + bloc + arc[fin:]
    print("archive :", i)
open("A_FAIRE.xml", "w", encoding="utf-8", newline="").write(src)
open("A_FAIRE_ARCHIVE.xml", "w", encoding="utf-8", newline="").write(arc)

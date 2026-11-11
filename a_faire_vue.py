"""Vue de A_FAIRE.xml : ce qui reste vraiment a faire.

Usage : python a_faire_vue.py [--tout]
  (defaut)  items 'ouvert' et 'en_cours', groupes par section
  --tout    ajoute les compteurs par etat

Controles (affiches en tete, a lire AVANT la liste) :
  - item ouvert mais "CLOS [id]" present dans Log.txt  -> PERIME, a passer en clos
  - item clos/abandonne sans date de cloture            -> a corriger
  - texte contenant FAIT / VALIDE / TESTE / VERIFIE      -> historique a deplacer dans Log.txt
"""
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
racine = ET.parse(RACINE / "A_FAIRE.xml").getroot()
log = (RACINE / "Log.txt").read_text(encoding="utf-8", errors="replace")

items = list(racine)
actifs = [i for i in items if i.get("etat") in ("ouvert", "en_cours")]

perimes = [i for i in actifs if f"CLOS [{i.get('id')}]" in log]
sans_date = [i for i in items if i.get("etat") in ("clos", "abandonne") and not i.get("cloture")]
mots = re.compile(r"\b(FAIT|VALIDE|TESTE|VERIFIE)\b")
historique = [i for i in actifs if mots.search(i.find("Texte").text or "")]

if perimes:
    print("PERIMES (ouverts mais clos dans Log.txt) :")
    for i in perimes:
        print("  ", i.get("id"))
if sans_date:
    print("CLOS SANS DATE :", ", ".join(i.get("id") for i in sans_date))
if historique:
    print("HISTORIQUE DANS LE TEXTE :", ", ".join(i.get("id") for i in historique))
if perimes or sans_date or historique:
    print()

perimes_ids = {i.get("id") for i in perimes}
par_section = defaultdict(list)
for i in actifs:
    if i.get("id") not in perimes_ids:
        par_section[i.get("section")].append(i)

for sec, liste in par_section.items():
    print(f"--- {sec} ({len(liste)}) ---")
    for i in liste:
        txt = (i.find("Texte").text or "").strip()
        marque = "*" if i.get("etat") == "en_cours" else " "
        print(f"{marque}[{i.get('id')}] {txt[:140]}{'...' if len(txt) > 140 else ''}")
    print()

if "--tout" in sys.argv:
    print(dict(Counter(i.get("etat") for i in items)))

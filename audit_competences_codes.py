"""Inventaire des competences d une version : familles, alias (id avec /), orphelins.
Usage : python audit_competences_codes.py WFRP4
Ecrit audit_competences_codes_<version>.txt
"""
import re
import sys
import glob
import os
import collections

os.chdir(os.path.dirname(os.path.abspath(__file__)))
version = sys.argv[1] if len(sys.argv) > 1 else "WFRP4"
re_skill = re.compile(r'<Skill id="([^"]+)">(.*?)</Skill>', re.S)
re_desc = re.compile(r'<Description language="ENGLISH">"([^"]*)"')
re_gen = re.compile(r'<Generique>"([^"]*)"')

familles = collections.defaultdict(list)
alias = []
simples = []
for f in sorted(glob.glob(f"DATABASE/{version}/*.[Xx]ml")):
    if "FRANCAIS" in f:
        continue
    texte = open(f, encoding="utf-8", errors="replace").read()
    for m in re_skill.finditer(texte):
        code, corps = m.group(1), m.group(2)
        d = re_desc.search(corps)
        g = re_gen.search(corps)
        desc = d.group(1) if d else "?"
        liv = os.path.basename(f)
        if "/" in code:
            alias.append((liv, code, desc))
        elif g:
            familles[g.group(1)].append((code, desc))
        else:
            simples.append((code, desc))

with open(f"audit_competences_codes_{version}.txt", "w", encoding="utf-8") as out:
    out.write(f"== ALIAS (id avec /) : {len(alias)}\n")
    for a in alias:
        out.write(f"{a[0]} | {a[1]} | {a[2]}\n")
    out.write(f"\n== FAMILLES : {len(familles)}\n")
    for g in sorted(familles):
        out.write(f"{g}  ({len(familles[g])} spec)  ex: {familles[g][0][1]}\n")
    out.write(f"\n== SIMPLES : {len(simples)}\n")
    for s in simples:
        out.write(f"{s[0]} | {s[1]}\n")
print("ok")

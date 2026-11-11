"""Audit des formes de codes (LIVRE-TYPE_CODE[__SPEC]) par version et par type de donnee.
Usage : python audit_codes_types.py WFRP4   (ou WFRP2, WFRP5)
Ecrit audit_codes_types_<version>.txt
"""
import re
import sys
import glob
import collections
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
version = sys.argv[1] if len(sys.argv) > 1 else "WFRP4"
motif = re.compile(r'\b(?:Code|CodeCarriere|CodeTalent)\s*=\s*"([A-Z0-9]+-[^"]+)"')
tout = re.compile(r'"([A-Z0-9]{2,6}-[A-Z][A-Z0-9_]*)"')

par_prefixe = collections.defaultdict(lambda: collections.Counter())
exemples = {}
for f in glob.glob(f"DATABASE/{version}/*.[Xx]ml"):
    texte = open(f, encoding="utf-8", errors="replace").read()
    for code in set(tout.findall(texte)):
        livre, reste = code.split("-", 1)
        m = re.match(r'([A-Z]+)(_|\d)', reste)
        if m:
            forme = m.group(1) + ("_" if m.group(2) == "_" else "<num>")
        else:
            forme = "(autre)"
        par_prefixe[forme][livre] += 1
        exemples.setdefault(forme, set())
        if len(exemples[forme]) < 4:
            exemples[forme].add(code)

with open(f"audit_codes_types_{version}.txt", "w", encoding="utf-8") as out:
    for forme in sorted(par_prefixe, key=lambda k: -sum(par_prefixe[k].values())):
        total = sum(par_prefixe[forme].values())
        out.write(f"{forme:12} {total:7}  ex: {', '.join(sorted(exemples[forme]))}\n")
print("ok", version)

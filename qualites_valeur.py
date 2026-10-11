# Analyse du 04/10/2026 : pour chaque code de qualite utilise dans les <Quality> des armes et armures (WFRP4 et WFRP5),
# dit s'il apparait toujours avec une valeur ("Reload 3"), toujours sans, ou melange. Ne modifie rien.
# Usage : python qualites_valeur.py   (depuis la racine du projet). Base du chantier "valeur obligatoire" (A FAIRE.txt).
import re, glob, collections, sys
import xml.etree.ElementTree as ET
for ed in ("WFRP4", "WFRP5"):
    avec = collections.Counter(); sans = collections.Counter(); ex = {}
    libs = {}
    for f in glob.glob(f"DATABASE/{ed}/*.Xml") + glob.glob(f"DATABASE/{ed}/*.xml"):
        if "FRANCAIS" in f.upper():
            continue
        try:
            root = ET.parse(f).getroot()
        except Exception as e:
            print("illisible", f, e); continue
        for bm in root.iter("BonusMalus"):
            d = bm.find("Description")
            if d is not None:
                libs[bm.get("id")] = (d.text or "").strip('"')
        for tag in ("Weapon", "Armor"):
            for w in root.iter(tag):
                q = w.find("Quality")
                if q is None or not q.text: continue
                t = q.text.strip().strip('"')
                if t in ("", "-"): continue
                for part in t.split(","):
                    part = part.strip()
                    if not part: continue
                    m = part.split(" ", 1)
                    code = m[0]
                    if len(m) > 1 and m[1].strip():
                        avec[code] += 1; ex.setdefault(code, m[1].strip())
                    else:
                        sans[code] += 1
    codes = sorted(set(avec) | set(sans))
    print(f"=== {ed} : {len(codes)} codes de qualite utilises")
    print("-- toujours AVEC valeur :")
    for c in codes:
        if avec[c] and not sans[c]: print(f"   {c:28} {libs.get(c,''):22} avec={avec[c]} ex='{ex[c]}'")
    print("-- toujours SANS valeur :")
    for c in codes:
        if sans[c] and not avec[c]: print(f"   {c:28} {libs.get(c,''):22} sans={sans[c]}")
    print("-- MELANGE (a trancher) :")
    for c in codes:
        if sans[c] and avec[c]: print(f"   {c:28} {libs.get(c,''):22} avec={avec[c]} sans={sans[c]} ex='{ex[c]}'")

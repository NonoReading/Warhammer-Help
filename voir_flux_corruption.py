#!/usr/bin/env python3
"""Diagnostic : affiche le flux de lecture (colonne gauche puis droite) des pages du livre donnees.
  python voir_flux_corruption.py 165 166"""
import sys

import extraire_carrieres_corruption_v2 as CC

sys.stdout.reconfigure(encoding="utf-8")
pages = {int(a) for a in sys.argv[1:]}
for p, s, t in CC.flux():
    if p in pages:
        print("p.%s %5.1f | %s" % (p, s, t))

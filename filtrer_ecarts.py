"""Ecarts d'un livre pour une balise : python filtrer_ecarts.py <livre.Xml> <motif> (apres tester_winlivre_v1.py sur ce livre)."""
import subprocess
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent
r = subprocess.run([sys.executable, "comparer_livre.py", sys.argv[1], str(RACINE / "TEST_WL_SORTIE.xml")],
                   cwd=RACINE, capture_output=True, text=True)
for ligne in r.stdout.splitlines():
    if sys.argv[2] in ligne:
        print(ligne[:300])

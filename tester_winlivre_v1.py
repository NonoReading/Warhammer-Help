#!/usr/bin/env python3
"""Test d'aller-retour de WinLivre sur tous les livres de DATABASE\\WFRP1.

Pour chaque livre : WarhammerHelp.exe --winlivretest (XML ecrit par la fenetre + liste des noeuds),
puis comparer_livre.py (ecarts de donnees + donnees absentes de l'arbre).
Usage : python tester_winlivre_v1.py [filtre sur le nom]
"""

import atexit
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

RACINE = Path(__file__).resolve().parent
sys.path.insert(0, str(RACINE / "TRAVAIL"))
from lancer_isole import lancer  # noqa: E402  (essai isole : INI.TXT du projet jamais touche)

TMP = Path(tempfile.mkdtemp(prefix="wl_aller_retour_"))
SORTIE = TMP / "TEST_WL_SORTIE.xml"
ARBRE = TMP / "TEST_WL_ARBRE.txt"
atexit.register(shutil.rmtree, TMP, True)  # le dossier temporaire ne reste plus apres l'essai
LOGS = []  # error.log de chaque essai (lu par tester_tout.py)


XSD = False
EDIT = False
_SCHEMAS = {}


def valider_xsd(xml: Path, dossier: str) -> list:
    """Erreurs de validation du XML (ecrit par WinLivre) contre SCHEMA_<dossier>.xsd."""
    from lxml import etree
    if dossier not in _SCHEMAS:
        _SCHEMAS[dossier] = etree.XMLSchema(etree.parse(str(RACINE / f"SCHEMA_{dossier}.xsd")))
    schema = _SCHEMAS[dossier]
    try:
        doc = etree.parse(str(xml))
    except etree.XMLSyntaxError as e:
        return [f"mal forme : {e}"]
    if schema.validate(doc):
        return []
    # chemin du parent (sans indices) en tete du message : on voit tout de suite quel element est fautif
    sans_indice = re.compile(r"\[\d+\]")
    erreurs = [f"ligne {e.line} : {sans_indice.sub('', e.path or '')} : {e.message[:160]}" for e in schema.error_log]
    # chapitres vides crees par le test lui-meme (DATA_RULE_SPECIE, DATA_RANDOM_TALENT) : pas un defaut du programme
    return [e for e in erreurs if "Missing child element(s)" not in e or
            not ("'DATA_RULE_SPECIE'" in e or "'DATA_RANDOM_TALENT'" in e)]


def main() -> int:
    global XSD
    args = sys.argv[1:]
    if "--xsd" in args:  # valide aussi chaque XML ecrit par la fenetre contre le schema de la version
        XSD = True
        args.remove("--xsd")
    global EDIT
    if "--edit" in args:  # test d'edition : Page saisie a 999 dans chaque fiche, retrouvee dans le XML ecrit
        EDIT = True
        args.remove("--edit")
    dossier = "WFRP1"
    if args and args[0].upper().startswith("WFRP"):  # ex. : python tester_winlivre_v1.py WFRP2 salvation
        dossier = args.pop(0).upper()
    filtre = args[0].lower() if args else ""
    echecs = 0
    total = Counter()
    total_xsd = Counter()
    for livre in sorted((RACINE / "DATABASE" / dossier).glob("BOOK_*.Xml")):
        if filtre and filtre not in livre.name.lower():
            continue
        if livre.stem.endswith("_FRANCAIS"):  # libelles seulement, jamais de donnees de jeu (A_FAIRE.xml)
            continue
        for f in (SORTIE, ARBRE):
            f.unlink(missing_ok=True)
        LOGS.append(lancer(["--winlivretest", str(livre), str(SORTIE), str(ARBRE)] + (["edit"] if EDIT else []),
                           version=dossier).error_log)
        if not SORTIE.exists():
            print(f"{livre.name} : ECHEC (pas de sortie)")
            echecs += 1
            continue
        if EDIT:
            # test d'edition : la Page de chaque fiche a ete saisie a 999 ; autant de <Page>999</Page> que de fiches modifiees
            attendu = 0
            for ligne in ARBRE.read_text(encoding="utf-8", errors="replace").splitlines():
                if ligne.startswith("PAGE_MODIFIEE;"):
                    attendu = int(ligne.split(";")[1])
            trouve = len(re.findall(r"<Page>\"?999\"?</Page>", SORTIE.read_text(encoding="utf-8")))
            etat = "OK" if trouve == attendu else "ECART"
            if etat == "ECART":
                echecs += 1
            grilles = 0
            for ligne in ARBRE.read_text(encoding="utf-8", errors="replace").splitlines():
                if ligne.startswith("GRILLES_AJOUT_RETRAIT;"):
                    grilles = int(ligne.split(";")[1])
            # ajout puis retrait d'une ligne sur chaque grille visible : le XML ecrit doit rester celui du livre (Page exceptee)
            r = subprocess.run([sys.executable, "comparer_livre.py", "--sans-page", str(livre), str(SORTIE)],
                               cwd=RACINE, capture_output=True, text=True)
            if r.returncode != 0:
                etat = "ECART"
                echecs += 1
            print(f"{livre.name} : edition Page=999 : {trouve} ecrites / {attendu} saisies ; {grilles} grilles ajout+retrait : {etat}")
            if r.returncode != 0:
                for ligne in r.stdout.strip().splitlines()[:6]:
                    print(f"      {ligne}")
            if XSD:
                erreurs = valider_xsd(SORTIE, dossier)
                if erreurs:
                    echecs += 1
                    print(f"   XSD : {len(erreurs)} erreur(s)")
                    for e in erreurs[:3]:
                        print(f"      {e}")
            continue
        r = subprocess.run([sys.executable, "comparer_livre.py", str(livre), str(SORTIE), str(ARBRE)],
                           cwd=RACINE, capture_output=True, text=True)
        derniere = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "?"
        print(f"{livre.name} : {derniere}")
        if XSD:
            # le XML ecrit par la fenetre doit respecter le schema (ordre des balises compris : xs:sequence)
            erreurs = valider_xsd(SORTIE, dossier)
            if erreurs:
                echecs += 1
                for e in erreurs:  # resume par nature d'erreur (sans le numero de ligne)
                    total_xsd[e.split(" : ", 1)[1][:170]] += 1
                if filtre:  # XML fautif garde dans TRAVAIL pour le relire
                    shutil.copyfile(SORTIE, RACINE / "TRAVAIL" / "XSD_ERREUR.xml")
                print(f"   XSD : {len(erreurs)} erreur(s)")
                for e in erreurs[:(40 if filtre else 3)]:
                    print(f"      {e}")
        if r.returncode != 0:
            echecs += 1
            lignes = r.stdout.strip().splitlines()
            # regroupement par chemin de balise (sans attributs ni valeur), plus lisible que les lignes brutes
            groupes = {}
            for ligne in lignes:
                m = re.match(r"(MANQUE|EN TROP) x(\d+) (\S+)", ligne)
                if m:
                    cle = (m.group(1), m.group(3))
                    groupes[cle] = groupes.get(cle, 0) + int(m.group(2))
            for (genre, chemin), n in groupes.items():
                # total par element (/DATA_BOOK/DATA_x/Element) pour le resume final
                total["/".join(chemin.split("/")[:4])] += n
            if filtre:
                for (genre, chemin), n in sorted(groupes.items(), key=lambda g: -g[1])[:60]:
                    print(f"   {n:6d} {genre} {chemin}")
                if len(groupes) > 60:
                    print(f"   ... ({len(groupes) - 60} chemins de plus)")
    if total_xsd:
        print("Resume XSD (erreurs de schema par nature) :")
        for msg, n in total_xsd.most_common(25):
            print(f"   {n:6d} {msg}")
    if total:
        print("Resume tous livres (ecarts par element) :")
        for chemin, n in total.most_common():
            print(f"   {n:7d} {chemin}")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())

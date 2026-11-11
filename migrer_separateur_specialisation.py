#!/usr/bin/env python3
"""Passage du separateur de specialisation des talents de '_' a '__' (24/10/2026, decision de Nono).
  RULES-T_BLESS_*       -> RULES-T_BLESS__*       (generique : famille + '__*')
  RULES-T_BLESS_SIGMAR  -> RULES-T_BLESS__SIGMAR  (specialisation : famille + '__' + specialisation)
  RULES-T_WILL_OF_IRON  inchange                  (talent sans specialisation : pas de '__')
La famille d'une specialisation est le plus court prefixe de son nom (apres le premier '-') dont le generique
'<prefixe>_*' est declare dans le meme dossier, tous livres confondus. Idempotent : un nom qui contient deja '__' est
laisse tel quel.
Reecrit : DATABASE/<dossier>/*.xml, SAVED_CARACTERS/<dossier>/**/*.xml, les images portant un code de talent, et les
scripts extraire_*_v2.py / lier_sorts_talents_v2.py / ajouter_cultes_v2.py (avec les familles de WFRP2).
Usage : python migrer_separateur_specialisation.py [--appliquer]   (sans option : simulation, rien n'est ecrit)
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
# WFRP2 est exclu : ses specialisations s'ecrivent T_ARCANE_LORE_*_ALL_EIGHT_WINDS (un '*' au milieu du code), a analyser
# a part ; ses scripts d'extraction restent donc eux aussi inchanges.
DOSSIERS = ("WFRP4", "WFRP5")
GENERIQUE = re.compile(r'<Talent id="[A-Z0-9]+-(T_[A-Za-z0-9_]*)_\*"')
CODE = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+)-(T_[A-Za-z0-9_]*\*?)")


def sans_commentaires(txt):
    return re.sub(r"<!--.*?-->", "", txt, flags=re.S)


def familles_du_dossier(dossier):
    noms = set()
    for f in (RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"):
        noms.update(GENERIQUE.findall(sans_commentaires(f.read_text(encoding="utf-8", errors="replace"))))
    return noms


def convertit_nom(nom, familles, stats):
    """nom = partie apres le premier '-' (T_...). Renvoie le nouveau nom."""
    if "__" in nom:
        return nom
    if nom.endswith("_*"):
        stats["generiques"] += 1
        return nom[:-2] + "__*"
    mots = nom.split("_")
    for i in range(2, len(mots)):          # au moins 'T' + 1 mot pour la famille, 1 mot de specialisation
        prefixe = "_".join(mots[:i])
        if prefixe in familles:
            stats["specialisations"] += 1
            return prefixe + "__" + "_".join(mots[i:])
    return nom


def reecrit_texte(txt, familles, stats):
    def remplace(m):
        nouveau = convertit_nom(m.group(2), familles, stats)
        return m.group(0) if nouveau == m.group(2) else "%s-%s" % (m.group(1), nouveau)
    return CODE.sub(remplace, txt)


def traite_fichier(f, familles, stats, reel):
    brut = f.read_bytes().decode("utf-8", errors="strict")
    txt = reecrit_texte(brut, familles, stats)
    if txt != brut:
        stats["fichiers"] += 1
        if reel:
            f.write_bytes(txt.encode("utf-8"))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    reel = "--appliquer" in sys.argv
    toutes = {d: familles_du_dossier(d) for d in DOSSIERS}
    for d in DOSSIERS:
        print("%s : %d familles" % (d, len(toutes[d])))
        stats = defaultdict(int)
        fichiers = sorted((RACINE / "DATABASE" / d).glob("*.[Xx]ml"))
        fichiers += sorted((RACINE / "SAVED_CARACTERS" / d).rglob("*.[Xx]ml")) if (RACINE / "SAVED_CARACTERS" / d).exists() else []
        for f in fichiers:
            traite_fichier(f, toutes[d], stats, reel)
        # images portant un code de talent
        for f in sorted((RACINE / "DATABASE" / d).glob("PICTURES*/**/*")):
            m = re.fullmatch(r"([A-Z0-9]+)-(T_[A-Za-z0-9_]*)", f.stem) if f.is_file() else None
            if not m:
                continue
            nouveau = convertit_nom(m.group(2), toutes[d], stats)
            if nouveau != m.group(2):
                cible = f.with_name("%s-%s%s" % (m.group(1), nouveau, f.suffix))
                stats["images"] += 1
                if reel and not cible.exists():
                    f.rename(cible)
        print("   generiques %d, specialisations %d, fichiers %d, images %d" % (
            stats["generiques"], stats["specialisations"], stats["fichiers"], stats["images"]))
    print("APPLIQUE" if reel else "SIMULATION (rien n'est ecrit)")


if __name__ == "__main__":
    main()

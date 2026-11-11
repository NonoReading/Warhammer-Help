# -*- coding: utf-8 -*-
"""Copie le texte legal (disclaimer) des sources des livres de fans V2 dans <DISCLAIMER>.

Usage : python ajouter_disclaimer_v2.py          (a blanc : affiche ce qui serait ecrit)
        python ajouter_disclaimer_v2.py --ecrire (ecrit dans les BOOK_*.Xml)
Regle : texte lu dans le fichier source principal du livre (table SOURCES ci-dessous) ;
pas de bloc legal trouve = pas de <DISCLAIMER>. Deja present = jamais ecrase.
"""
import os, re, sys
from xml.sax.saxutils import escape

RACINE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(RACINE, "DATABASE", "WFRP2")
SRC = os.path.join(RACINE, "PDF_TEXTE", "PDF_TEXTE_V2", "Homebrew & Fan Material")

# fichier de livre -> morceau du nom du TXT source (insensible a la casse)
SOURCES = {
    "ACADEMICS_HANDBOOK": "Academics Handbook",
    "ARABY_SAND_AND_GOLD": "Araby - Sand & Gold",
    "ARANAI_ARCANE": "Magic Overhaul - Arcane",
    "ARANAI_RUNE": "Magic Overhaul - Rune",
    "CANNONS_GUNNES": "Cannons and Gunnes",
    "CARAVAN_CAREERS": "Caravan Careers",
    "CAREER_EXPANSION": "Career Expansion 2.2",
    "CHILDREN_OF_THE_OLD_ONES": "Children of the Old Ones, Part 1",
    "CODEX_GREENSKINS": "Codex Greenskins",
    "DEATHS_REBIRTH": "Death's Rebirth",
    "DEFENDERS_OF_THE_FOREST": "Defenders of the Forest",
    "DRUIDS_OLD_FAITH": "Druids and the Old Faith",
    "DWARF_RELIGION": "Dwarf Religion",
    "ELEMENTALISM": "WFRP2 - Elementalism",
    "ELVEN_WARDANCERS": "Elven Wardancers",
    "EXPANDED_WEAPONRY": "Expanded WFRP2 Weaponry",
    "GOTREK_AND_FELIX": "Gotrek-and-Felix",
    "GROGNARD_CAREERS": "Careers" + os.sep + "Ambassador",
    "HANDRICH_RANALD": "Expanded Lores of Handrich",
    "HEDGE_MAGIC_SPELL_CREATION": "Hedge Magic Spell Creation",
    "HUGELSTEINS_CURIOSITIES": "Hugelsteins Curiosities",
    "LEOPOI": "wfrp_priest_spells",
    "LIBER_FANATICA": "Character Compendium",
    "LICHE": "WFRP2 - Liche",
    "LOST_IN_TRANSLATION_MAGIC": "Lost in Translation",
    "MAGIC_OF_ARABY": "The Magic of Araby",
    "NORSCA": "Norsca - WFRP2",
    "OLD_WORLD_ANIMALS": "Old World Animals 2016",
    "RACES_REGIONS": "OptionalCharacterCreationRules-Races_and_Regions",
    "RETURN_OF_ELEMENTALISM": "Return of Elementalism",
    "RUNE_EXPANSION": "Rune Expansion",
    "SORCERERS_OF_THE_SOUTH": "Sorcerers of the South",
    "SPEARS_OF_THE_MAIDEN": "Spears Of the Maiden",
    "THE_DARK_PATH": "The Dark Path",
    "THE_NORTHMEN": "The Northmen",
    "THOUSAND_ISLAS": "Thousand Islas",
    "TOME_OF_DRAGONS": "Tome of Dragons",
    "TRADES_OLD_WORLD": "Trades of the Old World part 1",
    "UNOFFICIAL_TOME_OF_CAREERS": "Tome of Careers V2.0a",
}

MOTIFS_DEBUT = re.compile(r"completely unofficial|unofficial and in no way|Copyright\s*[©�]|[©�]\s*Copyright", re.I)
MOTIFS_FIN = re.compile(r"respective owners|All rights reserved\.?\s*$|status (is )?intended|ownership to them", re.I)


def trouver_source(morceau):
    m = morceau.lower()
    trouves = []
    for d, _, fs in os.walk(SRC):
        for f in fs:
            p = os.path.join(d, f)
            if f.endswith(".txt") and m in p.lower():
                trouves.append(p)
    return sorted(trouves)


def extraire(chemin):
    lignes = [re.sub(r"\s+", " ", l).strip() for l in open(chemin, encoding="utf-8", errors="replace").read().splitlines()]
    for i, l in enumerate(lignes):
        if MOTIFS_DEBUT.search(l) and l[:1].isupper() or l[:1] in "©�" and MOTIFS_DEBUT.search(l):
            bloc = []
            for j in range(i, min(i + 9, len(lignes))):
                if lignes[j]:
                    bloc.append(lignes[j])
                if MOTIFS_FIN.search(lignes[j]):
                    break
            else:
                pass
            # une ligne de debut sur deux colonnes est trop melangee : on l'ecarte
            t = " ".join(bloc).replace("�", "©")
            if "...." in t:
                continue
            return t
    return ""


def main():
    ecrire = "--ecrire" in sys.argv
    for nom in sorted(os.listdir(DB)):
        if not nom.startswith("BOOK_") or not nom.endswith(".Xml"):
            continue
        cle = nom[5:-4]
        if cle not in SOURCES:
            continue
        chemin_xml = os.path.join(DB, nom)
        xml = open(chemin_xml, encoding="utf-8", newline="").read()
        if "<DISCLAIMER>" in xml:
            print("[deja]", cle)
            continue
        srcs = trouver_source(SOURCES[cle])
        if not srcs:
            print("[source introuvable]", cle, "<-", SOURCES[cle])
            continue
        texte = ""
        for s in srcs:
            texte = extraire(s)
            if texte:
                break
        if not texte:
            print("[pas de bloc legal]", cle, "(", os.path.basename(srcs[0]), ")")
            continue
        print("[ok]", cle, "<-", os.path.basename(s))
        print("     ", texte[:260])
        if ecrire:
            m = re.search(r"<COMPLETE>[^\n]*</COMPLETE>(\r?\n)", xml)
            if not m:
                print("   !! balise COMPLETE introuvable")
                continue
            bloc = '<DISCLAIMER>"' + escape(texte) + '"</DISCLAIMER>' + m.group(1)
            xml = xml[:m.end()] + bloc + xml[m.end():]
            open(chemin_xml, "w", encoding="utf-8", newline="").write(xml)


main()

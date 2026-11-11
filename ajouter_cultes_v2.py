#!/usr/bin/env python3
"""Cultes de l'Initiate V2 (Career Compendium appendice V p.245, repris du Rulebook chapitre 8) :
un DATA_CAREER_BONUS dans BOOK_RULESBOOK.Xml de WFRP2, une entree par culte, greffee sur la carriere
Initiate (le bonus d'Initiate = une competence ou un talent de depart en plus de la carriere).
Les options du Pretre ne sont PAS ecrites ici (etape suivante : condition "meme culte").

Usage : python ajouter_cultes_v2.py        (idempotent : remplace le bloc s'il existe)
"""
import re
from pathlib import Path

CIBLE = Path(__file__).parent / "DATABASE" / "WFRP2" / "BOOK_RULESBOOK.Xml"
INITIATE = "RULES-CARE_INITIATE"
# (code, nom du culte, competence, talent)
CULTES = [
    ("MANANN",   "Cult of Manann",      "RULES-COMP_SWIM", ""),
    ("MORR",     "Cult of Morr",        "RULES-COMP_INTIMIDATE", ""),
    ("MYRMIDIA", "Cult of Myrmidia",    "", "RULES-T_STRIKE_TO_INJURE"),
    ("RANALD",   "Cult of Ranald",      "RULES-COMP_SLEIGHT_OF_HAND", ""),
    ("SHALLYA",  "Cult of Shallya",     "RULES-COMP_HEAL", ""),
    ("SIGMAR",   "Cult of Sigmar",      "RULES-COMP_COMMON_KNOWLEDGE_DWARFS", ""),
    ("TAAL",     "Cult of Taal & Rhya", "RULES-COMP_OUTDOOR_SURVIVAL", ""),
    ("ULRIC",    "Cult of Ulric",       "", "RULES-T_STRIKE_MIGHTY_BLOW"),
    ("VERENA",   "Cult of Verena",      "RULES-COMP_PERCEPTION", ""),
]


def bloc():
    s = ["<DATA_CAREER_BONUS>"]
    for code, nom, comp, tal in CULTES:
        i = "RULES-CULT_%s" % code
        s += ['<CareerBonus id="%s">' % i,
              '<Description language="ENGLISH">"%s"</Description>' % nom.replace("&", "&amp;"),
              '<Career>"%s"</Career>' % INITIATE, '<Specie>""</Specie>',
              '<Level id="%s_1">' % i, '<Order>"1"</Order>',
              '<Skill>"%s"</Skill>' % comp, '<Talent>"%s"</Talent>' % tal, "</Level>", "</CareerBonus>"]
    s.append("</DATA_CAREER_BONUS>")
    return "\n".join(s) + "\n"


def main():
    x = CIBLE.read_text(encoding="utf-8")
    x = re.sub(r"<DATA_CAREER_BONUS>.*?</DATA_CAREER_BONUS>\n", "", x, flags=re.S)
    fin = "</DATA_BOOK>"
    i = x.rindex(fin)
    CIBLE.write_text(x[:i] + bloc() + x[i:], encoding="utf-8", newline="\n")
    print("%d cultes ecrits dans %s" % (len(CULTES), CIBLE.name))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Materiel de depart des carrieres V2 en SUBCHAPTER_ITEM (forme V4 : <Item name="CODE">"niveau"</Item>,
quantite en attribut, "A/B" = choix avec quantite "a/b" par branche, "A+B" = ensemble), a partir du texte
<Trappings> de chaque carriere (le texte du livre y reste). Armes et armures reconnues = codes du
catalogue V2 (RULES-COMB_V2_*, RULES-PROJ_V2_*, RULES-ARMO_V2_*, extraire_armes_v2.py) ; le reste = texte libre
anglais (objet divers). V2 n a qu un niveau de carriere : toujours "1".

Regles de l analyseur : virgules de premier niveau = elements ; " or " = choix ; "Any one of: A, B, C" = choix
sur les elements qui suivent ; "Light/Medium/Heavy Armour (X and Y)" = une armure par piece ; "<arme> with
<munitions>" = l arme + un objet de munitions ; "N <objet>", "One/Two... set(s) of", "A Pair of" = quantite.
Gardes en texte (pas de qualite de fabrication en V2) : tout ce qui est "Best/Good/Poor Craftsmanship",
l argent (gc), "Any N weapons".
TABLE ne sert qu aux exceptions saisies a la main (elle l emporte sur l analyseur).

Usage : python structurer_trappings_v2.py [--dry] [--liste]
Ordre : relancer apres extraire_carrieres_v2.py (qui reecrit les carrieres) et extraire_armes_v2.py.
"""
import re
import sys
from xml.sax.saxutils import escape

import extraire_competences_talents_v2 as ct

ARME_CC = "RULES-COMB_V2_"
ARME_CT = "RULES-PROJ_V2_"
ARMURE = "RULES-ARMO_V2_"

# carriere : [(nom ou code, quantite), ...] : exceptions saisies a la main (aucune a ce jour)
TABLE = {}

# alias de noms de catalogue (cle en minuscules, sans pluriel) -> code
ALIAS = {
    "knuckle-duster": ARME_CC + "GAUNTLET_KNUCKLE_DUSTER",
    "hand weapon": ARME_CC + "HAND_WEAPON_SWORD_ETC",
    "hand weapon (hatchet)": ARME_CC + "HAND_WEAPON_SWORD_ETC",
    "great weapon (halberd)": ARME_CC + "HALBERD",
    "great weapon (two-handed axe)": ARME_CC + "GREAT_WEAPON",
    "great weapon (two-handed pick)": ARME_CC + "GREAT_WEAPON",
    "demilance": ARME_CC + "DEMILANCE_CAVALRY_SPEAR",
    "knife": ARME_CC + "DAGGER",
    "throwing knives": ARME_CT + "THROWING_DAGGER_STAR",
    "throwing knives/stars": ARME_CT + "THROWING_DAGGER_STAR",
    "throwing axes/hammer": ARME_CT + "THROWING_AXE_HAMMER",
    "throwing daggers/stars": ARME_CT + "THROWING_DAGGER_STAR",
    "throwing knife": ARME_CT + "THROWING_DAGGER_STAR",
    "throwing knife/star": ARME_CT + "THROWING_DAGGER_STAR",
    "throwing dagger/star": ARME_CT + "THROWING_DAGGER_STAR",
    "throwing axe": ARME_CT + "THROWING_AXE_HAMMER",
    "throwing axe/hammer": ARME_CT + "THROWING_AXE_HAMMER",
    "pistol": ARME_CT + "PISTOL",
}
ARMURES_PAR_NIVEAU = ("light", "medium", "heavy")
NOMBRES = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "a pair of": 2, "pair of": 2}
NOTE_QUALITE = re.compile(r"\b(best|good|poor)\s+craftsm[ae]nship\b", re.I)


def catalogue(xml):
    """nom normalise -> code, pour les armes et armures du livre."""
    res = {}
    for m in re.finditer(r'<(Weapon|Armor) id="([^"]*)">\s*<Description language="ENGLISH">"([^"]*)"', xml):
        res.setdefault(m.group(3).lower(), m.group(2))     # melee avant distance : Spear = melee
    # nom + variantes entre parentheses du catalogue ("Hand Weapon (sword etc)" -> "hand weapon")
    for nom, code in list(res.items()):
        court = re.sub(r"\s*\(.*\)$", "", nom)
        res.setdefault(court, code)
        for part in court.split("/"):
            res.setdefault(part.strip(), code)
    # prefixe de code selon le type : une arme a distance n a pas le meme prefixe qu une arme de melee
    res.update(ALIAS)
    return res


def singulier(nom):
    n = nom.strip().lower()
    for fin, rep in (("ies", "y"), ("ses", "s"), ("s", "")):
        if n.endswith(fin) and len(n) > len(fin) + 2:
            return n[:-len(fin)] + rep
    return n


# noms du Career Compendium pour des armures du Core ("Chain Shirt" = Mail Shirt : la maille du Rulebook)
ALIAS_ARMURE = {"full plate": "full plate armour", "full leather": "full leather armour",
                "chain shirt": "mail shirt", "full mail": "full mail armour"}


def cherche(nom, cat):
    n = nom.strip().lower()
    n = ALIAS_ARMURE.get(n, n)
    for k in (n, singulier(n)):
        if k in cat:
            return cat[k]
    return None


def coupe(texte, sep):
    """coupe sur sep hors parentheses."""
    res, prof, cur, i = [], 0, "", 0
    while i < len(texte):
        c = texte[i]
        if c == "(":
            prof += 1
        elif c == ")":
            prof -= 1
        if prof == 0 and texte.startswith(sep, i) and not (sep == "," and i > 0 and texte[i - 1].isdigit() and texte[i + 1:i + 2].isdigit()):
            res.append(cur)
            cur = ""
            i += len(sep)
            continue
        cur += c
        i += 1
    res.append(cur)
    return [r.strip() for r in res if r.strip()]


def normalise(t):
    t = t.replace("�", "'").replace("Craftsmenship", "Craftsmanship").replace("craftsmenship", "craftsmanship")
    return re.sub(r"\s+", " ", t).strip()


def majuscule(t):
    return t[:1].upper() + t[1:]


def element(t, cat, rapport):
    """un element sans choix : liste de (nom, quantite)."""
    t = t.strip().rstrip(".")
    # armure en niveau : Light Armour (Leather Jack and Leather Skullcap)
    m = re.match(r"^(light|medium|heavy) armour \((.+)\)$", t, re.I)
    if m:
        res = []
        for p in re.split(r",\s*and\s+|,\s*|\s+and\s+", m.group(2)):
            p = p.strip()
            if NOTE_QUALITE.search(p):
                res.append((majuscule(p) + " (armour)", 1))
                rapport.append("fabrication en texte : " + p)
            else:
                c = cherche(p, cat)
                if c:
                    res.append((c, 1))
                else:
                    res.append((majuscule(p), 1))
                    rapport.append("armure inconnue : " + p)
        return res
    # arme + munitions : "Crossbow with 10 bolts", "Pistol with Powder and Ammunition for 10 Shots"
    m = re.match(r"^(.+?)\s+(?:with|and)\s+(.+)$", t, re.I)
    if m and cherche(re.sub(r"^(a )?pair of ", "", m.group(1), flags=re.I), cat) and not NOTE_QUALITE.search(t):
        arme = element(m.group(1), cat, rapport)
        n = re.match(r"^(\d+)\s+(.+)$", m.group(2))
        if n:
            return arme + [(majuscule(n.group(2)), int(n.group(1)))]
        return arme + [(majuscule(m.group(2)), 1)]
    q = 1
    m = re.match(r"^(a pair of|pair of|one|two|three|four|five|six)\s+(?:sets? of\s+)?(.+)$", t, re.I)
    sets = False
    if m:
        q = NOMBRES[m.group(1).lower()]
        t = m.group(2)
        sets = bool(re.match(r"^(a pair of|pair of)$", m.group(1), re.I) is None and re.search(r"sets? of", t) is None
                    and re.match(r"^(one|two|three|four|five|six)\s+sets? of", m.group(0), re.I))
    else:
        m = re.match(r"^(\d+)\s+(?:sets? of\s+)?(.+)$", t, re.I)
        if m and not re.match(r"^\d+[,d]", t) and "gc" not in t.split()[1:2]:
            q = int(m.group(1))
            sets = bool(re.match(r"^\d+\s+sets? of", t, re.I))
            t = m.group(2)
    y = re.match(r"^yards of (.+)$", t, re.I)
    if y:
        return [(majuscule(y.group(1)) + " (yards)", q)]
    if re.search(r"\bgc\b", t) or NOTE_QUALITE.search(t) or re.match(r"^any (one|two|three|four|five|six)\b", t, re.I):
        nom = majuscule(t) + (" (set)" if sets else "")
        if not re.search(r"\bgc\b", t):
            rapport.append("garde en texte : " + t)
        return [(majuscule(t) if q == 1 and not sets else nom, q)]
    c = cherche(t, cat)
    if c:
        return [(c, q)]
    return [(majuscule(t) + (" (set)" if sets else ""), q)]


def branche(t, cat, rapport):
    return element(t, cat, rapport)


def analyse(texte, cat, rapport):
    texte = normalise(texte)
    parts = coupe(texte, ",")
    items, groupe = [], None          # groupe = liste de parties d un "Any one of:"
    sortie = []
    for p in parts:
        m = re.match(r"^any one of:\s*(.*)$", p, re.I)
        if m:
            groupe = [m.group(1)]
            sortie.append(("GROUPE", groupe))
        elif groupe is not None:
            groupe.append(p)
        else:
            sortie.append(("SIMPLE", p))
    # un "Any one of:" ne couvre que ce qui le suit jusqu au prochain "Any one of:" ; ici : le dernier groupe
    res = []
    for genre, p in sortie:
        if genre == "GROUPE":
            branches = [x for x in p if x]
            res.append(melange(branches, cat, rapport))
        else:
            if re.match(r"^\d+ or more\b", p, re.I):
                res.append([(majuscule(p), 1)])
                continue
            # "Bow or Crossbow with 10 Arrows or Bolts" : armes en choix + munitions en choix
            m = re.match(r"^(.+?)\s+with\s+(\d+)\s+(arrows|bolts)(?:\s+or\s+(arrows|bolts))?$", p, re.I)
            if m and " or " in m.group(1) and all(cherche(w, cat) for w in re.split(r"\s+or\s+", m.group(1))):
                armes = [cherche(w, cat) for w in re.split(r"\s+or\s+", m.group(1))]
                muni = m.group(3).capitalize() + ("/" + m.group(4).capitalize() if m.group(4) else "")
                res.append([("/".join(armes), 1)])
                res.append([(muni, int(m.group(2)))])
                continue
            if re.match(r"^(best|good|poor) craftsmanship", p, re.I) and " or " in p:
                res.append([(majuscule(p), 1)])
                rapport.append("fabrication en texte : " + p)
                continue
            paire = re.match(r"^(?:a )?pair of (.+)$", p, re.I)
            if paire and " or " in paire.group(1):
                res.append([(n, 2) for n, q in melange(coupe(paire.group(1), " or "), cat, rapport)][:1]
                           if False else paire_choix(coupe(paire.group(1), " or "), cat, rapport))
                continue
            res.append(melange(coupe(p, " or "), cat, rapport) if len(coupe(p, " or ")) > 1 else element(p, cat, rapport))
    return res


def paire_choix(branches, cat, rapport):
    """"A Pair of X or Y" : la paire vaut pour chaque branche."""
    elems = [element(b, cat, rapport)[0][0] for b in branches]
    return [("/".join(elems), 2)]


def melange(branches, cat, rapport):
    """plusieurs branches (choix) -> [(code1/code2, quantite ou 'q1/q2')] (un seul element), plus
    les munitions eventuelles."""
    elems = [element(b, cat, rapport) for b in branches]
    # une branche a plusieurs elements (arme + munitions) : le premier fait le choix, les autres suivent
    premiers = [e[0] for e in elems]
    suites = [x for e in elems for x in e[1:]]
    noms = "/".join(n for n, q in premiers)
    qs = [q for n, q in premiers]
    qt = str(qs[0]) if len(set(qs)) == 1 else "/".join(str(x) for x in qs)
    res = [(noms, qt)]
    for x in suites:
        res.append(x)
        rapport.append("munitions en choix : " + noms)
    return res


ARGENT = re.compile(r"^(\d+(?:,\d{3})*|\d*d\d+(?:\+\d+)?)\s*gc(?:\s+in coin(?:\s*(?:and|or|/)\s*trade goods)?)?$", re.I)


def separe_argent(items):
    """(items sans argent, formule 'NCO' ou 'XdYCO' ou '') : les lignes 'N gc' deviennent StartMoney."""
    reste, formule = [], ""
    for nom, q in items:
        m = ARGENT.match(nom.strip())
        if m and not formule:
            formule = m.group(1).replace(",", "") + "CO"
        else:
            reste.append((nom, q))
    return reste, formule


def bloc(items):
    out = ["<SUBCHAPTER_ITEM>"]
    for nom, q in items:
        q = str(q)
        # "/" separe les choix dans un nom d objet : une formule "(1d10+2)/3" y serait coupee (WinLivre plante)
        nom = re.sub(r"(?<=[\dd)])/(?=\d)", " divided by ", nom)
        attr = ' quantite="%s"' % q if q != "1" else ""
        out.append('<Item name="%s"%s>"1"</Item>' % (escape(nom, {'"': "&quot;"}), attr))
    out.append("</SUBCHAPTER_ITEM>")
    return chr(10).join(out) + chr(10)


def aplati(res):
    items = []
    for lst in res:
        items += lst
    return items


def main(argv):
    # --compendium : les carrieres du Career Compendium ; le catalogue d objets reste celui du Core
    if "--corruption" in argv or "--bestiary" in argv or "--skaven" in argv or "--ndm" in argv:
        argv = list(argv) + ["--compendium"]
    cible = (ct.LIVRE.with_name("BOOK_NIGHTS_DARK_MASTERS.Xml") if "--ndm" in argv else
             ct.LIVRE.with_name("BOOK_CHILDREN_OF_THE_HORNED_RAT.Xml") if "--skaven" in argv else
             ct.LIVRE.with_name("BOOK_OLD_WORLD_BESTIARY.Xml") if "--bestiary" in argv else
             ct.LIVRE.with_name("BOOK_TOME_OF_CORRUPTION.Xml") if "--corruption" in argv else
             ct.LIVRE.with_name("BOOK_CAREER_COMPENDIUM.Xml") if "--compendium" in argv else ct.LIVRE)
    xml_core = ct.LIVRE.read_text(encoding="utf-8")
    xml = cible.read_text(encoding="utf-8")
    xml = re.sub(r"<SUBCHAPTER_ITEM>.*?</SUBCHAPTER_ITEM>[\r\n]?", "", xml, flags=re.S)   # idempotent (carrieres V2 seulement)
    xml = re.sub(r"<StartMoney>[^\n]*</StartMoney>[\r\n]?", "", xml)
    cat = catalogue(xml_core)
    n, rapports = 0, []
    absent = []
    for m in list(re.finditer(r'<Career id="([^"]*)">.*?<Trappings>"([^"]*)"</Trappings>\n', xml, re.S)):
        pass
    sortie = []
    for m in re.finditer(r'<Career id="([^"]*)">.*?<Trappings>"([^"]*)"</Trappings>\n', xml, re.S):
        code, texte = m.group(1), m.group(2)
        rap = []
        items = TABLE.get(code) or aplati(analyse(texte, cat, rap))
        sortie.append((m.end(), code, texte, items))
        for r in rap:
            rapports.append("%s : %s" % (re.sub(r"^[A-Z]+-CARE_", "", code), r))
        n += 1
    for fin, code, texte, items in reversed(sortie):
        items, argent = separe_argent(items)
        xml = xml[:fin] + ('<StartMoney>"%s"</StartMoney>' % argent + chr(10) if argent else "") + bloc(items) + xml[fin:]
    # controle : tout code RULES- cite existe
    for fin, code, texte, items in sortie:
        for nom, q in items:
            for c in nom.split("/"):
                if c.startswith("RULES-") and 'id="%s"' % c not in xml_core and 'id="%s"' % c not in xml:
                    absent.append("%s : %s" % (code, c))
    print("Carrieres : %d" % n)
    if "--liste" in argv:
        for fin, code, texte, items in sortie:
            print("%s | %s" % (re.sub(r"^[A-Z]+-CARE_", "", code), texte))
            for nom, q in items:
                print("    %-70s x%s" % (nom.replace("RULES-", ""), q))
    for r in rapports:
        print("  A VOIR : " + r)
    for a in absent:
        print("  MANQUE : " + a)
    if absent or "--dry" in argv or "--liste" in argv:
        return 1 if absent else 0
    cible.write_text(xml, encoding="utf-8", newline=chr(10))
    print("Ecrit : %s" % cible)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

#!/usr/bin/env python3
"""Migration des codes de competences V4 / V5 (RULES-COMPCHARM, RULES-COMPSAVOIR_BETE) vers la logique des talents :
LIVRE-COMP_NOM, specialisation LIVRE-COMP_FAMILLE__SPEC, generique LIVRE-COMP_FAMILLE__*.
Regles : nom = libelle anglais de la fiche en majuscules (ponctuation -> _) ; famille = libelle sans parenthese
finale, specialisation = contenu de la parenthese. En cas de collision dans une famille, la specialisation garde
son ancien suffixe. Les alias (id « A/B ») sont supprimes : une carriere cite « A/B » dans ses references.
Etape 1 (par defaut, a blanc) : table ancien -> nouveau + collisions. --appliquer reecrit DATABASE/<dossier> et
SAVED_CARACTERS/<dossier>.
Usage : python migrer_codes_competences.py WFRP4|WFRP5 [fichier_table.tsv] [--appliquer]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
FICHE = re.compile(r'<Skill id="([^"]+)">(.*?)</Skill>', re.S)
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)
ANCIEN = re.compile(r"^([A-Z0-9]+)-(COMP[A-Z]+)(?:_(.+))?$")
REF = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+-COMP[A-Z]+(?:_[A-Za-z0-9*]+)*)")


# Codes nus de <PDF> qui ne correspondent a aucune fiche (coquille de la donnee) : corriges avant la conversion
NUS_CORRIGES = {"COMPDISC_URBAN": "COMPDISC_URB", "COMPCHARM BEGGING": "COMPCHARM", "COMPVOILE": "COMPVOILE_*"}
# Codes cites avec un livre mais sans fiche (V4 : Sail sans specialisation, cite par Dwarf Player's Guide) : renvoyes
# sur la competence simple, comme en V5
ORPHELINS_CORRIGES = {"RULES-COMPVOILE": "RULES-COMP_SAIL"}


def slug(libelle):
    return re.sub(r"[^A-Za-z0-9]+", "_", libelle.upper()).strip("_")


def decoupe(libelle):
    """« Lore (Beasts) » -> ('Lore', 'Beasts') ; « Charm » -> ('Charm', '')."""
    m = re.match(r"^(.*?)\s*\(([^)]*)\)\s*$", libelle.strip())
    return (m.group(1), m.group(2)) if m else (libelle.strip(), "")


def fiches_du_dossier(dossier):
    res = []  # (fichier, code, libelle)
    for f in sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml")):
        txt = re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)
        for code, corps in FICHE.findall(txt):
            d = DESC.search(corps)
            res.append((f.name, code, d.group(1).strip() if d else ""))
    return res


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    sortie = Path(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    fiches = [x for x in fiches_du_dossier(dossier) if "_FRANCAIS" not in x[0]]

    alias = sorted({c for _, c, _ in fiches if "/" in c})
    uniques = {}
    for fichier, code, lib in fiches:
        if "/" not in code:
            uniques.setdefault(code, lib)

    # Famille de chaque ancien radical (COMPCOMB) : libelle du generique « Melee (Any) » sans parenthese
    famille_nom = {}
    for code, lib in uniques.items():
        m = ANCIEN.match(code)
        if m and m.group(3) == "*":
            famille_nom[(m.group(1), m.group(2))] = slug(decoupe(lib)[0])

    table, origine, cas = {}, {}, []
    pris = defaultdict(dict)   # (pref, famille) -> {nouveau suffixe: ancien code}
    for code, lib in sorted(uniques.items()):
        m = ANCIEN.match(code)
        if not m:
            cas.append("code non reconnu : %s" % code)
            continue
        pref, rad, suf = m.group(1), m.group(2), m.group(3)
        fam = famille_nom.get((pref, rad)) or next((n for (p, r), n in famille_nom.items() if r == rad), None)
        if suf is None:
            base, _ = decoupe(lib)
            table[code] = "%s-COMP_%s" % (pref, slug(base))
            origine[code] = "simple"
        elif suf == "*":
            table[code] = "%s-COMP_%s__*" % (pref, fam)
            origine[code] = "generique"
        else:
            if fam is None:
                cas.append("famille inconnue : %s" % code)
                continue
            _, spec = decoupe(lib)
            nouveau_suf = slug(spec) if spec else slug(suf)
            if not nouveau_suf or nouveau_suf in pris[(pref, fam)]:
                nouveau_suf = slug(suf)
                origine[code] = "ancien suffixe"
                if nouveau_suf in pris[(pref, fam)]:
                    cas.append("collision : %s et %s" % (code, pris[(pref, fam)][nouveau_suf]))
            else:
                origine[code] = "libelle"
            pris[(pref, fam)][nouveau_suf] = code
            table[code] = "%s-COMP_%s__%s" % (pref, fam, nouveau_suf)

    inverse = defaultdict(list)
    for a, n in table.items():
        inverse[n].append(a)
    collisions = {n: a for n, a in inverse.items() if len(a) > 1}

    print("%s : %d competences, %d alias a supprimer, %d familles" % (dossier, len(table), len(alias), len(famille_nom)))
    print("  origine : %s" % {o: sum(1 for v in origine.values() if v == o) for o in set(origine.values())})
    print("\n== Collisions : %d" % len(collisions))
    for n, a in sorted(collisions.items()):
        print("  %s <- %s" % (n, ", ".join("%s \"%s\"" % (x, uniques.get(x, "")) for x in a)))
    print("\n== Cas a trancher : %d" % len(cas))
    for c in cas:
        print("  " + c)
    if sortie:
        with open(sortie, "w", encoding="utf-8") as f:
            for a, n in sorted(table.items()):
                f.write("%s\t%s\t%s\n" % (a, n, origine[a]))
        print("\nTable ecrite dans %s" % sortie)
    appliquer(dossier, table, alias, "--appliquer" in sys.argv)


def appliquer(dossier, table, alias, reel):
    fichiers = sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"))
    fichiers += sorted((RACINE / "SAVED_CARACTERS" / dossier).rglob("*.[Xx]ml"))
    inconnus = defaultdict(int)
    total = modifies = supprimees = 0
    for f in fichiers:
        brut = f.read_bytes().decode("utf-8")
        txt = brut
        for a in alias:
            txt, n = re.subn(r'<Skill id="%s">.*?</Skill>[ \t]*(?:\r?\n)?' % re.escape(a), "", txt, flags=re.S)
            supprimees += n

        def remplace(m):
            nonlocal total
            if m.group(1) not in table:
                if m.group(1) in ORPHELINS_CORRIGES and dossier == "WFRP4":
                    total += 1
                    return ORPHELINS_CORRIGES[m.group(1)]
                inconnus[m.group(1)] += 1
                return m.group(0)
            total += 1
            return table[m.group(1)]

        txt = REF.sub(remplace, txt)

        # Codes nus (sans livre) dans <PDF>"COMPESQU,COMPCHEV_*" des talents : lus par WinPersonnage
        def pdf(m):
            nonlocal total
            res = []
            for tok in m.group(1).split(","):
                t = tok.strip()
                t = NUS_CORRIGES.get(t, t)
                nouveau = table.get("RULES-" + t) if t.startswith("COMP") and not t.startswith("COMP_") else None
                if nouveau:
                    total += 1
                    res.append(nouveau.split("-", 1)[1])
                else:
                    if t.startswith("COMP") and not t.startswith("COMP_"):
                        inconnus["nu:" + t] += 1
                    res.append(t)
            return '<PDF>"%s"</PDF>' % ",".join(res)

        txt = re.sub(r'<PDF>"([^"]*)"</PDF>', pdf, txt)
        if txt != brut:
            modifies += 1
            if reel:
                f.write_bytes(txt.encode("utf-8"))
    print("\n== %s : %d references reecrites dans %d fichiers, %d alias supprimes%s" % (
        "APPLIQUE" if reel else "A BLANC", total, modifies, supprimees, "" if reel else " (rien ecrit)"))
    print("   codes COMP sans correspondance : %d" % len(inconnus))
    for k, n in sorted(inconnus.items(), key=lambda x: -x[1])[:25]:
        print("     %s (%d)" % (k, n))


if __name__ == "__main__":
    main()

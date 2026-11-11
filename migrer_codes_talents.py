#!/usr/bin/env python3
"""Migration des codes de talents a numero (RULES-T0056, NATIO-T0001_*) vers des codes a nom (RULES-T_FRENZY).
Etape 1 (par defaut) : construit la table ancien -> nouveau pour un dossier (WFRP4 ou WFRP5) et l ecrit dans un
fichier TSV, plus un rapport de collisions / cas a trancher. Ne modifie rien.
Regles : le nom vient du Rulebook WFRP2 (meme libelle anglais) pour un talent RULES ; sinon T_ + libelle anglais en
majuscules (apostrophes et ponctuation -> _). Une specialisation (T0012_SIGMAR) garde son suffixe : T_BLESS_SIGMAR ;
le generique (T0012_*) devient T_BLESS_* (libelle sans parenthese finale).
Usage : python migrer_codes_talents.py WFRP4|WFRP5 [fichier_table.tsv]
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent
FICHE = re.compile(r'<Talent id="([^"]+)">(.*?)</Talent>', re.S)
DESC = re.compile(r'<Description language="ENGLISH">"(.*?)"</Description>', re.S)
CODE_NUM = re.compile(r"^([A-Z0-9]+)-(T0[A-Z0-9]*)(_.+)?$")


def slug(libelle):
    s = re.sub(r"[^A-Za-z0-9]+", "_", libelle.upper()).strip("_")
    return s


def sans_parenthese(libelle):
    return re.sub(r"\s*\([^)]*\)\s*$", "", libelle).strip()


def norm(s):
    return re.sub(r"\s+", " ", s).strip().lower()


def talents_du_dossier(dossier):
    res = []  # (fichier, code, libelle)
    for f in sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml")):
        txt = re.sub(r"<!--.*?-->", "", f.read_text(encoding="utf-8", errors="replace"), flags=re.S)
        for code, corps in FICHE.findall(txt):
            d = DESC.search(corps)
            res.append((f.name, code, d.group(1) if d else ""))
    return res


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    dossier = sys.argv[1]
    sortie = Path(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None

    # Cles a nom du Rulebook V2, par libelle
    v2 = {}
    for fichier, code, lib in talents_du_dossier("WFRP2"):
        if fichier == "BOOK_RULESBOOK.Xml" and code.startswith("RULES-T_"):
            v2.setdefault(norm(lib), code)

    # Un livre de traduction (_FRANCAIS) reprend les codes de l'anglais : il n'entre pas dans la table
    fiches = [x for x in talents_du_dossier(dossier) if "_FRANCAIS" not in x[0]]
    # Libelle du generique / de la fiche de base, par (prefixe, radical numerique)
    base_lib = {}
    for fichier, code, lib in fiches:
        m = CODE_NUM.match(code)
        if m and (not m.group(3) or m.group(3) == "_*"):
            base_lib[(m.group(1), m.group(2))] = lib

    # Familles : (prefixe, radical) ayant au moins une fiche avec suffixe (_* ou _X)
    generiques = {(CODE_NUM.match(c).group(1), CODE_NUM.match(c).group(2)) for _, c, _ in fiches
                  if CODE_NUM.match(c) and CODE_NUM.match(c).group(3)}
    table = {}      # ancien code -> nouveau code
    origine = {}    # ancien code -> raison
    cas = []        # cas a trancher
    for fichier, code, lib in fiches:
        m = CODE_NUM.match(code)
        if not m:
            continue
        pref, rad, suf = m.group(1), m.group(2), m.group(3) or ""
        if not suf and (pref, rad) in base_lib and "(" in base_lib[(pref, rad)] and (pref, rad) not in generiques:
            lib_base = base_lib[(pref, rad)]   # fiche terminale « Nom (Precision) » : le libelle complet
        else:
            lib_base = sans_parenthese(base_lib.get((pref, rad), lib))
        cle_v2 = v2.get(norm(lib_base))
        if pref == "RULES" and cle_v2:
            nom = cle_v2.split("-", 1)[1]
            raison = "rulebook V2"
        else:
            nom = "T_" + slug(lib_base)
            raison = "libelle"
        if not lib_base:
            cas.append("sans libelle : %s (%s)" % (code, fichier))
            continue
        nouveau = "%s-%s%s" % (pref, nom, suf)
        if code in table and table[code] != nouveau:
            cas.append("code declare deux fois avec des libelles differents : %s" % code)
        table[code] = nouveau
        origine[code] = raison

    # Decisions de Nono : nom impose pour une famille (alias d une fiche supprimee, ou clef distincte)
    for code in list(table):
        m = CODE_NUM.match(code)
        if (m.group(1), m.group(2)) in IMPOSES.get(dossier, {}):
            table[code] = "%s-%s%s" % (m.group(1), IMPOSES[dossier][(m.group(1), m.group(2))], m.group(3) or "")
            origine[code] = "decision"
    supprimes = SUPPRIMES.get(dossier, [])

    # Collisions : deux anciens codes -> meme nouveau code (hors fiches supprimees)
    inverse = defaultdict(list)
    for a, n in table.items():
        m = CODE_NUM.match(a)
        if (m.group(1), m.group(2)) in supprimes:
            continue
        inverse[n].append(a)
    collisions = {n: a for n, a in inverse.items() if len(a) > 1}

    # Nouveaux codes qui existent deja ailleurs (WFRP2 ou meme dossier)
    existants = defaultdict(list)
    for fichier, code, lib in fiches:
        if not CODE_NUM.match(code):
            existants[code].append(fichier)
    deja = {n: existants[n] for n in inverse if n in existants}
    libelles = {code: lib for fichier, code, lib in fiches}

    print("%s : %d talents a numero convertis, %d via le Rulebook V2, %d via le libelle" % (
        dossier, len(table), sum(1 for v in origine.values() if v == "rulebook V2"),
        sum(1 for v in origine.values() if v == "libelle")))
    print("\n== Collisions (plusieurs anciens codes -> meme nouveau code) : %d" % len(collisions))
    for n, a in sorted(collisions.items()):
        print("  %s <- %s" % (n, ", ".join("%s \"%s\"" % (x, libelles.get(x, "")) for x in a)))
    print("\n== Nouveau code deja declare a nom dans le meme dossier (fusion) : %d" % len(deja))
    for n, lieux in sorted(deja.items())[:40]:
        print("  %s : %s" % (n, "; ".join(lieux)))
    print("\n== Cas a trancher : %d" % len(cas))
    for c in cas:
        print("  " + c)
    if sortie:
        with open(sortie, "w", encoding="utf-8") as f:
            for a, n in sorted(table.items()):
                f.write("%s\t%s\t%s\n" % (a, n, origine[a]))
        print("\nTable ecrite dans %s" % sortie)
    appliquer(dossier, table, supprimes, "--appliquer" in sys.argv)


# Decisions de Nono (24/10/2026) : Bless / Invoke gardent la famille Divine Lore, l ancienne famille Deity est
# supprimee et ses references renvoyees sur elle ; le trait Hardy des creatures garde sa propre clef.
IMPOSES = {"WFRP5": {("RULES", "T0015"): "T_BLESS", ("RULES", "T0071"): "T_INVOKE"},
           "WFRP4": {("RULES", "T0HAR"): "T_HARDY_TRAIT"}}
SUPPRIMES = {"WFRP5": [("RULES", "T0015"), ("RULES", "T0071")]}
# Specialisations declarees hors d un bloc DATA_TALENT lu par le script : famille connue a la main
EXTRA_BASE = {"WFRP5": {("TEMPLE", "T0001"): "T_ARCANE_MAGIC"}}

REF = re.compile(r"(?<![A-Za-z0-9_])([A-Z0-9]+)-(T0[A-Z0-9]*)((?:_[A-Za-z0-9*]+)*)")


def appliquer(dossier, table, supprimes, reel):
    base = {}  # (prefixe, radical) -> nom
    for code, nouveau in table.items():
        m = CODE_NUM.match(code)
        suf = m.group(3) or ""
        nom = nouveau.split("-", 1)[1]
        base[(m.group(1), m.group(2))] = nom[:len(nom) - len(suf)] if suf else nom
    base.update(EXTRA_BASE.get(dossier, {}))
    fichiers = sorted((RACINE / "DATABASE" / dossier).glob("*.[Xx]ml"))
    fichiers += sorted((RACINE / "SAVED_CARACTERS" / dossier).rglob("*.[Xx]ml"))
    inconnus = defaultdict(int)
    total = 0
    modifies = 0
    supprimees = 0
    for f in fichiers:
        brut = f.read_bytes().decode("utf-8")
        txt = brut
        for pref, rad in supprimes:
            txt, n = re.subn(r'<Talent id="%s-%s(?:_[^"]*)?">.*?</Talent>[ \t]*(?:\r?\n)?' % (pref, rad), "", txt, flags=re.S)
            supprimees += n

        def remplace(m):
            nonlocal total
            cle = (m.group(1), m.group(2))
            if cle not in base:
                inconnus["%s-%s" % cle] += 1
                return m.group(0)
            total += 1
            return "%s-%s%s" % (m.group(1), base[cle], m.group(3))

        txt = REF.sub(remplace, txt)
        if txt != brut:
            modifies += 1
            if reel:
                f.write_bytes(txt.encode("utf-8"))
    print("\n== %s : %d references reecrites dans %d fichiers, %d fiches supprimees%s" % (
        "APPLIQUE" if reel else "A BLANC", total, modifies, supprimees, "" if reel else " (rien ecrit)"))
    print("   codes T0 sans correspondance : %d" % len(inconnus))
    for k, n in sorted(inconnus.items(), key=lambda x: -x[1])[:25]:
        print("     %s (%d)" % (k, n))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Compare les entrees/sorties de carriere du livre "Master Career Entries and Exits" (WFRP V2)
aux <Entries>/<Exits> des carrieres de DATABASE/WFRP2 (Rulebook et Career Compendium).

Le livre est en deux colonnes (8 pages) : chaque page est lue colonne gauche puis colonne droite,
une carriere commence a une ligne "Nom (Livre page) Entries: ...", suivie de "Exits: ...".
Mode mesure seul : n ecrit rien dans les livres.

Usage : python comparer_entrees_sorties_v2.py [--detail]
"""
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent
SOURCE = RACINE / "PDF_TEXTE" / "PDF_TEXTE_V2" / "Master Career Entries and Exits.txt"
LIVRES = [RACINE / "DATABASE" / "WFRP2" / n for n in ("BOOK_RULESBOOK.Xml", "BOOK_CAREER_COMPENDIUM.Xml")]
ENTETE = re.compile(r"^(.+?) \(([A-Za-z]+) (\d+)\) Entries:\s*(.*)$")


# graphies du livre ramenees au nom de la carriere : coquilles et precisions de culte
ALIAS = {"rouge": "rogue", "jailor": "jailer", "tombraider": "tombrobber", "anointedprest": "anointedpriest",
         "navigation": "navigator"}


def cle(nom):
    nom = re.sub(r"\([^)]*\)", "", nom)
    k = re.sub(r"[^a-z]", "", nom.lower())
    k = re.sub(r"^(initiate|priest)of[a-z]+$", r"\1", k)
    return ALIAS.get(k, k)


def nettoie(brut):
    """Retire notes de bas de liste (*...), numeros de page et le point mis a la place d une virgule."""
    brut = brut.split("*")[0].replace("Vampire, Hunter", "Vampire Hunter")  # virgule en trop (Fieldwarden)
    brut = re.sub(r"\.\s+(?=[A-Z])", ", ", brut)
    return ", ".join(x for x in (y.strip() for y in brut.split(",")) if x and not x.isdigit())


def debut_colonne_droite(lignes):
    """Position de la colonne droite d une page : la plus frequente parmi les fins de blanc >= 4."""
    comptes = {}
    for l in lignes:
        for m in re.finditer(r"(?<=\S) {4,}(?=[^ ​])", l):
            comptes[m.end()] = comptes.get(m.end(), 0) + 1
        if len(l) - len(l.lstrip()) >= 40:
            n = len(l) - len(l.lstrip())
            comptes[n] = comptes.get(n, 0) + 1
    return max(comptes, key=comptes.get) if comptes else 80


def coupe(l, idx):
    """(gauche, droite) d une ligne a deux colonnes. La colonne gauche peut remplir la largeur
    (3 espaces seulement avant la droite) : on cherche la coupure la plus proche de idx."""
    if len(l.replace("​", "").rstrip()) < idx - 1:
        return l.strip(), ""
    for d in (0, 1, -1, 2, -2, 3, -3):
        p = idx + d
        if 0 < p < len(l) and l[p - 1] in " ​" and l[p] not in " ​":
            return l[:p].strip(), l[p:].strip()
    return l.strip(), ""


def lignes_en_flux(texte):
    """Une liste de lignes dans l ordre de lecture : page par page, colonne gauche puis droite."""
    flux = []
    for page in re.split(r"\f|^\s*Web Enhancement\s*$", texte, flags=re.M):
        lignes = [l for l in page.split("\n") if l.strip().replace("​", "") not in ("", "Web Enhancement")]
        idx = debut_colonne_droite(lignes)
        if "--colonnes" in sys.argv:
            print("page de %d lignes, colonne droite en %d" % (len(lignes), idx))
        gauche, droite = [], []
        for l in lignes:
            g, d = coupe(l, idx)
            g, d = g.replace("​", "").strip(), d.replace("​", "").strip()
            if g:
                gauche.append(g)
            if d:
                droite.append(d)
        flux += gauche + droite
    return flux


def lire_livre_maitre():
    texte = SOURCE.read_text(encoding="utf-8", errors="replace")
    texte = texte[texte.index("\nAbbot (ToS"):]  # l introduction (page 1) n a pas de carriere
    flux = lignes_en_flux(texte)
    fiches, courant = [], None
    for l in flux:
        m = ENTETE.match(l)
        if m:
            courant = {"nom": m.group(1).strip(), "src": m.group(2) + " " + m.group(3), "texte": m.group(4)}
            fiches.append(courant)
        elif courant is not None:
            courant["texte"] += " " + l
    for f in fiches:
        t = f["texte"]
        entrees, _, sorties = t.partition("Exits:")
        f["entries_brut"], f["exits_brut"] = nettoie(entrees), nettoie(sorties)
    return fiches


def lire_xml():
    careers = {}
    for livre in LIVRES:
        texte = livre.read_text(encoding="utf-8")
        for m in re.finditer(r'<Career id="([^"]+)">(.*?)</Career>', texte, re.S):
            corps = m.group(2)

            def champ(nom):
                x = re.search(r"<%s>\"(.*?)\"</%s>" % (nom, nom), corps, re.S)
                return x.group(1) if x else ""
            nom = re.search(r'<Description language="ENGLISH">"(.*?)"', corps).group(1)
            careers[m.group(1)] = {"id": m.group(1), "nom": nom, "livre": livre.name,
                                   "entries": champ("Entries"), "exits": champ("Exits"),
                                   "codes": champ("ExitCodes"), "source": champ("Source")}
    return careers


def liste(brut, connus):
    """Decoupe "A, B, C" ; recolle "Hedgecraft, Apprentice" quand le morceau seul n est pas une carriere."""
    brut = brut.strip().rstrip(".")
    if not brut or brut.lower() in ("none", "any"):
        return [brut.lower()] if brut else []
    morceaux = [x.strip() for x in re.split(r",", brut) if x.strip()]
    res = []
    for x in morceaux:
        if res and cle(x) not in connus and cle(res[-1] + x) in connus:
            res[-1] = res[-1] + " " + x
        else:
            res.append(x)
    return res


def texte_et_code(x, par_nom):
    """(texte a ecrire, code de carriere ou None) pour un nom cite par le livre."""
    m = re.match(r"^(.*?)(\s*\(.*\))?$", x)
    base, qual = m.group(1), m.group(2) or ""
    cs = par_nom.get(cle(base))
    if not cs:
        return x, None
    typo = re.sub(r"[^a-z]", "", base.lower()) in ALIAS
    return (cs[0]["nom"] + qual if typo else x), cs[0]["id"]


def ecrire(fiches, par_nom, connus):
    """Remplace Entries / Exits / ExitCodes de chaque carriere par ceux du livre maitre."""
    par_cle = {cle(f["nom"]): f for f in fiches}
    for livre in LIVRES:
        texte = livre.read_text(encoding="utf-8")
        n = 0

        def refait(m):
            nonlocal n
            corps = m.group(2)
            nom = re.search(r'<Description language="ENGLISH">"(.*?)"', corps).group(1)
            f = par_cle.get(cle(nom))
            if not f:
                return m.group(0)
            entrees = [texte_et_code(x, par_nom)[0] for x in liste(f["entries_brut"], connus)]
            sorties = [texte_et_code(x, par_nom) for x in liste(f["exits_brut"], connus)]
            codes = []
            for _, c in sorties:
                if c and c not in codes:
                    codes.append(c)
            nouveau = {"Entries": ", ".join(entrees) or "None",
                       "Exits": ", ".join(t for t, _ in sorties) or "None",
                       "ExitCodes": ",".join(codes)}
            for champ, val in nouveau.items():
                val = val.replace("&", "&amp;").replace("<", "&lt;")
                motif = r"<%s>\".*?\"</%s>" % (champ, champ)
                if champ == "ExitCodes":  # facultatif : absent quand aucune sortie n a de code
                    if not val:
                        corps = re.sub(motif + r"\r?\n", "", corps, flags=re.S)
                        continue
                    if not re.search(motif, corps, flags=re.S):
                        corps = re.sub(r"(</Exits>)(\r?\n)", lambda x: '%s%s<ExitCodes>"%s"</ExitCodes>%s' % (x.group(1), x.group(2), val, x.group(2)), corps, count=1)
                        continue
                corps, k = re.subn(motif, lambda _: '<%s>"%s"</%s>' % (champ, val, champ), corps, flags=re.S)
                if not k:
                    sys.exit("champ %s absent de %s" % (champ, m.group(1)))
            n += 1
            return m.group(0).replace(m.group(2), corps)
        nouveau_texte = re.sub(r'<Career id="([^"]+)">(.*?)</Career>', refait, texte, flags=re.S)
        livre.write_text(nouveau_texte, encoding="utf-8", newline="")
        print("%s : %d carrieres reecrites" % (livre.name, n))


def main():
    detail = "--detail" in sys.argv
    fiches = lire_livre_maitre()
    careers = lire_xml()
    par_nom = {}
    for c in careers.values():
        par_nom.setdefault(cle(c["nom"]), []).append(c)
    connus = set(par_nom) | {cle(f["nom"]) for f in fiches}
    print("livre maitre : %d carrieres lues ; XML : %d carrieres" % (len(fiches), len(careers)))

    absentes, ecarts, identiques = [], [], 0
    for f in fiches:
        trouve = par_nom.get(cle(f["nom"]))
        if not trouve:
            absentes.append(f["nom"])
            continue
        for c in trouve:
            e_livre, e_xml = set(map(cle, liste(f["entries_brut"], connus))), set(map(cle, liste(c["entries"], connus)))
            x_livre, x_xml = set(map(cle, liste(f["exits_brut"], connus))), set(map(cle, liste(c["exits"], connus)))
            if e_livre == e_xml and x_livre == x_xml:
                identiques += 1
            else:
                ecarts.append((f, c, e_livre - e_xml, e_xml - e_livre, x_livre - x_xml, x_xml - x_livre))
    sans_fiche = [c["nom"] for c in careers.values() if cle(c["nom"]) not in {cle(f["nom"]) for f in fiches}]
    print("identiques : %d ; avec ecart : %d ; dans le livre mais pas au XML : %d ; au XML mais pas dans le livre : %d"
          % (identiques, len(ecarts), len(absentes), len(sans_fiche)))
    print("absentes du XML :", ", ".join(absentes) or "-")
    print("au XML sans fiche :", ", ".join(sans_fiche) or "-")
    n_e = sum(1 for e in ecarts if e[2] or e[3])
    n_x = sum(1 for e in ecarts if e[4] or e[5])
    print("ecarts d entrees : %d carrieres ; ecarts de sorties : %d carrieres" % (n_e, n_x))
    # noms cites par le livre que le XML ne connait pas (carrieres d autres livres : pas de code)
    inconnus = {}
    for f in fiches:
        for brut in (f["entries_brut"], f["exits_brut"]):
            for x in liste(brut, connus):
                if cle(x) and cle(x) not in par_nom and cle(x) not in ("none", "any"):
                    inconnus.setdefault(x, []).append(f["nom"])
    print("noms cites sans carriere au XML (%d) : %s" % (len(inconnus), "; ".join(
        "%s (%d)" % (k, len(v)) for k, v in sorted(inconnus.items()))))
    if "--ecrire" in sys.argv:
        ecrire(fiches, par_nom, connus)
        return
    if detail:
        for f, c, ea, eb, xa, xb in ecarts:
            print("\n%s (%s)" % (f["nom"], c["id"]))
            if ea or eb:
                print("  Entries  livre+ %s | xml+ %s" % (sorted(ea), sorted(eb)))
            if xa or xb:
                print("  Exits    livre+ %s | xml+ %s" % (sorted(xa), sorted(xb)))


if __name__ == "__main__":
    main()

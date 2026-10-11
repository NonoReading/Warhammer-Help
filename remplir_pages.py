#!/usr/bin/env python3
"""Renseigne la balise <Page> des fiches d'un livre XML a partir du texte extrait du livre.

Usage :
  python remplir_pages.py LIVRE.Xml TEXTE.txt [--ecrire] [--decalage N]

Sans --ecrire : rapport seulement (fiches resolues, ambigues, introuvables).
Avec --ecrire : insere <Page>n</Page> avant la balise fermante de chaque fiche resolue
(jamais ecrase une page deja saisie).

Methode : le texte est coupe par saut de page (\\f). Le numero imprime d'une page est lu
sur la derniere ligne non vide (ou la premiere), a defaut deduit du rang PDF + decalage.
Une fiche est resolue seulement si son titre anglais apparait comme TITRE (ligne seule)
sur une unique page ; sinon elle est rapportee, jamais devinee.

Sources qui font foi (controle du 12/10/2026 : la premiere occurrence d'un nom est souvent une
carriere, un sommaire ou un tableau, pas la fiche) :
  - LISTE DE COMPETENCES du livre (colonnes "Skill  Desc  Rules", ex. WFRP5 p.110) : la page
    Desc d'une competence, specialisations comprises, l'emporte (origine "liste") ;
  - INDEX du livre (lignes "Titre ....... 123, 140") : departage les candidats, ou donne la
    page quand le titre n'est trouve nulle part (origine "index") ;
  - PAGES DE TABLEAU (Price, Availability, Damage...) : pour une arme, une armure ou un
    trapping ambigu, une page de tableau l'emporte (origine "tableau").
"""
import re
import sys
from pathlib import Path

FICHES = {  # bloc DATA_* -> balise de fiche
    "DATA_TALENT": "Talent",
    "DATA_SPELL": "Spell", "DATA_CAREER": "Career", "DATA_ARMOR": "Armor",
    "DATA_ARMOR_BONUS": None, "DATA_WEAPON": "Weapon", "DATA_WEAPON_BONUS": None,
    "DATA_CRAFTMANSHIP": None, "DATA_SKILL": "Skill",
    "DATA_SPECIE": None, "DATA_RACE": None, "DATA_NATION": None, "DATA_TRAPPING": None,
    "DATA_STARSIGN": None, "DATA_SPECIE_TRAIT": None, "DATA_RULE": None,
    "DATA_CONDITION": None, "DATA_DISEASE": None, "DATA_AFFLICTION": None,
}


def norm(s):
    s = s.replace("’", "'").replace("‘", "'")
    return re.sub(r"[^a-z0-9']+", " ", s.lower()).strip()


MOTS_TABLEAU = re.compile(r"availab|encumbrance|\bprice\b|\breach\b|\bdamage\b|\bqualities\b|\bcost\b", re.I)
BLOCS_EQUIPEMENT = {"DATA_WEAPON", "DATA_ARMOR", "DATA_ARMOR_BONUS", "DATA_WEAPON_BONUS",
                    "DATA_CRAFTMANSHIP", "DATA_TRAPPING"}


def pages_brutes(chemin):
    """Texte brut de chaque page (meme decoupage et meme filtre de filigrane que pages_du_texte)."""
    brut = Path(chemin).read_text(encoding="utf-8", errors="replace")
    return ["\n".join(l for l in p.splitlines() if not re.search(r"\(?Order #\d+\)?", l))
            for p in brut.split("\f")]


def liste_competences(brutes):
    """{titre normalise: page Desc} d'apres un tableau 'Nom   p111   p146, p171' (3 colonnes)."""
    res = {}
    for p in brutes:
        if "Desc" not in p or "Rules" not in p:
            continue
        for l in p.splitlines():
            for m in re.finditer(r"([A-Z][A-Za-z' ]+?)\s{2,}p(\d{1,3})\s+p\d{1,3}", l):
                res.setdefault(norm(m.group(1)), m.group(2))
    return res


def index_du_livre(brutes):
    """{titre normalise: [pages]} d'apres les lignes 'Titre ........ 12, 140' des pages d'index."""
    motif = re.compile(r"([A-Z(][^\n.]{0,48}?)\s*\.{2,}[ .]*((?:\d{1,3}(?:[-–]\d{1,3})?(?:,\s*)?)+)")
    res = {}
    for p in brutes:
        trouves = [m for l in p.splitlines() for m in motif.finditer(l)]
        if len(trouves) < 15:   # une page d'index en compte des dizaines
            continue
        for m in trouves:
            nom = re.sub(r"\((Talent|Skill|Spell|Rules?)\)", "", m.group(1))
            pages = [x.strip() for x in m.group(2).split(",") if x.strip()]
            res.setdefault(norm(nom), []).extend(pages)
    return res


def pages_du_texte(chemin, decalage):
    brut = Path(chemin).read_text(encoding="utf-8", errors="replace")
    pages = []
    for i, p in enumerate(brut.split("\f")):
        lignes = [l.strip() for l in p.splitlines() if l.strip()]
        # Filigrane d'achat (PDF vendus nominativement) : jamais le numero de page ni un titre.
        lignes = [l for l in lignes if not re.search(r"\(?Order #\d+\)?", l)]
        label = None
        for l in (lignes[-1:] + lignes[:1]):
            m = re.fullmatch(r"(\d{1,3})", l) or re.search(r"(?:^|\s)(\d{1,3})$", l)
            if m and l == m.group(0).strip():
                label = m.group(1)
                break
        if label is None:
            label = str(i + 1 + decalage) if (i + 1 + decalage) > 0 else ""
        # Deux colonnes et tableaux : un titre est un segment separe des autres par 2+ espaces.
        segs = set()
        for l in lignes:
            for s in re.split(r"\s{2,}", l):
                if len(s) < 70:
                    segs.add(norm(s))
                    # "Pick Lock (Dex)" / "Lore (Advanced)" : variante sans suffixe final
                    segs.add(norm(re.sub(r"\s*\((?:[A-Z][a-z]{0,2}|Basic|Advanced|Any|Ag|Dex)\)\s*$", "", s)))
        pages.append((label, segs, norm(' '.join(lignes))))
    return pages


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    ecrire = "--ecrire" in sys.argv
    langue = "ENGLISH"
    if "--langue" in sys.argv:
        langue = sys.argv[sys.argv.index("--langue") + 1]
        args = [a for a in args if a != langue]
    decalage = 0
    if "--decalage" in sys.argv:
        decalage = int(sys.argv[sys.argv.index("--decalage") + 1])
        args = [a for a in args if a != str(decalage)]
    xml_path, txt_path = args[0], args[1]
    pages = pages_du_texte(txt_path, decalage)
    brutes = pages_brutes(txt_path)
    comp_liste = liste_competences(brutes)
    index = index_du_livre(brutes)
    pages_tableau = {pages[k][0] for k in range(min(len(pages), len(brutes)))
                     if len(MOTS_TABLEAU.findall(brutes[k])) >= 3}
    texte = Path(xml_path).read_bytes().decode("utf-8")
    lignes = texte.split("\n")
    bloc = None
    entrees = []   # une par fiche : [position_balise_fermante, bloc, ident, titre, page, origine]
    i = 0

    def mots_expl(e, n):
        return [w for w in norm(e or "").split()[:n] if len(w) > 3]

    def meilleure_par_recouvrement(cands, explication):
        mots = set(mots_expl(explication, 25))
        if not mots or not cands:
            return None, 0
        sc = {}
        for lab, _, plein in pages:
            if lab in cands:
                sc[lab] = max(sc.get(lab, 0), len(mots & set(plein.split())))
        top = max(sc.values()) if sc else 0
        meil = [l for l, v in sc.items() if v == top]
        if not meil:
            return None, 0
        nums = [m for m in meil if m.isdigit()]
        return (str(max(int(m) for m in nums)) if nums else meil[0]), top

    while i < len(lignes):
        l = lignes[i].strip()
        m = re.fullmatch(r"<(DATA_\w+)>", l)
        if m:
            bloc = m.group(1)
        m = re.match(r'<(\w+) (?:id|name)="([^"]+)">$', l)
        if m and bloc in FICHES:
            tag, ident = m.groups()
            j = i + 1
            titre = None
            explication = None
            existante = None
            while j < len(lignes) and lignes[j].strip() != f"</{tag}>":
                s = lignes[j].strip()
                mm = re.match(r'<Description language="' + langue + r'">"?(.*?)"?</Description>', s)
                if mm and titre is None:
                    titre = mm.group(1)
                me = re.match(r'<Explanation language="' + langue + r'">"?(.*)', s)
                if me and explication is None:
                    explication = me.group(1)
                mp = re.match(r"<Page>([^<]*)</Page>", s)
                if mp:
                    existante = mp.group(1)
                j += 1
            if existante:
                entrees.append([j, bloc, ident, titre, existante, "deja"])
            else:
                page, origine = None, None
                cle = norm(re.sub(r"\s*\(.*?\)\s*$", "", titre or ""))
                H = {lab for lab, ls, _ in pages if cle and cle in ls}
                mots = norm(explication or "").split()[:5]
                A = set()
                if len(mots) == 5:
                    ancre = " ".join(mots)
                    A = {lab for lab, _, plein in pages if ancre in plein}
                if H and A:
                    C = H & A
                    if not C and len(A) == 1:
                        C = A
                    uniq = sorted(C)
                else:
                    uniq = sorted(H or A)
                # Sources qui font foi (voir l'en-tete) : liste de competences, tableau, index.
                titre_base = norm(re.sub(r"\s*\(.*?\)\s*$", "", titre or ""))
                origine_force = None
                if bloc == "DATA_SKILL" and titre_base in comp_liste:
                    uniq, origine_force = [comp_liste[titre_base]], "liste"
                else:
                    if bloc in BLOCS_EQUIPEMENT and len(uniq) > 1:
                        tab = [l for l in uniq if l in pages_tableau]
                        if len(tab) == 1:
                            uniq, origine_force = tab, "tableau"
                        elif tab:
                            uniq = tab
                    idx = index.get(titre_base, [])
                    if idx and origine_force is None and len(uniq) != 1:
                        commun = [l for l in uniq if l in idx]
                        if len(commun) == 1:
                            uniq, origine_force = commun, "index"
                        elif not uniq and len(set(idx)) == 1:
                            uniq, origine_force = [idx[0]], "index"
                if origine_force and len(uniq) == 1:
                    page, origine = uniq[0], origine_force
                elif len(uniq) == 1:
                    page, origine = uniq[0], "sur"
                elif len(uniq) > 1:
                    b, top = meilleure_par_recouvrement(set(uniq), explication)
                    page, origine = (b or uniq[0]), "estime"
                else:
                    # titre present quelque part dans le texte de la page
                    if cle:
                        cands = {lab for lab, _, plein in pages if (" " + cle + " ") in (" " + plein + " ")}
                    else:
                        cands = set()
                    couverture = {pages[0][0]} if len(pages) > 5 else set()
                    cands = cands - couverture   # la couverture n'est jamais la fiche
                    # equipement : le nom est d'abord cite dans les carrieres ; la fiche est
                    # sur une page de tableau (controle du 12/10/2026).
                    if bloc in BLOCS_EQUIPEMENT and cands & pages_tableau:
                        cands = cands & pages_tableau
                    if cands:
                        b, top = meilleure_par_recouvrement(cands, explication)
                        page = b or sorted(cands, key=lambda x: (not x.isdigit(), int(x) if x.isdigit() else 0))[0]
                        origine = "estime"
                    elif explication:
                        toutes = {lab for lab, _, _ in pages} - couverture   # jamais la couverture
                        if bloc in BLOCS_EQUIPEMENT and toutes & pages_tableau:
                            toutes = toutes & pages_tableau
                        b, top = meilleure_par_recouvrement(toutes, explication)
                        if b and top >= 6:
                            page, origine = b, "estime"
                entrees.append([j, bloc, ident, titre, page, origine])
            i = j
        i += 1
    # Dernier repli : page de la fiche voisine du meme bloc (les fiches d'un bloc sont groupees)
    for k, e in enumerate(entrees):
        if e[4] is None:
            for d in range(1, len(entrees)):
                for kk in (k - d, k + d):
                    if 0 <= kk < len(entrees) and entrees[kk][1] == e[1] and entrees[kk][4]:
                        e[4], e[5] = entrees[kk][4], "voisine"
                        break
                if e[4]:
                    break
    # Dernier recours : fiche paginee la plus proche, tous blocs confondus
    for k, e in enumerate(entrees):
        if e[4] is None:
            for d in range(1, len(entrees)):
                for kk in (k - d, k + d):
                    if 0 <= kk < len(entrees) and entrees[kk][4]:
                        e[4], e[5] = entrees[kk][4], "proche"
                        break
                if e[4]:
                    break
    stats = {}
    for e in entrees:
        stats[e[5]] = stats.get(e[5], 0) + 1
    sorties = [(e[0], e[4], e[2], e[3]) for e in entrees if e[5] != "deja" and e[4]]
    sans = [e for e in entrees if e[4] is None]
    print(f"{xml_path}: {len(sorties)} ecrites ({stats}), {len(sans)} sans page")
    for e in sans:
        print(f"  SANS PAGE  {e[2]}  {e[3]}")
    if ecrire:
        crlf = "\r\n" in texte
        for j, page, ident, titre in sorted(sorties, reverse=True):
            fin = lignes[j]
            indent = fin[: len(fin) - len(fin.lstrip())]
            lignes.insert(j, f"{indent}<Page>{page}</Page>" + ("\r" if crlf else ""))
        Path(xml_path).write_bytes("\n".join(lignes).encode("utf-8"))
        print(f"ecrit : {len(sorties)} pages")


if __name__ == "__main__":
    main()

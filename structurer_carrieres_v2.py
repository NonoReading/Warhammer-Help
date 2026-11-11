#!/usr/bin/env python3
"""Competences et talents des carrieres V2 en SUBCHAPTER_SKILL / SUBCHAPTER_TALENT (forme V4 :
<Skill name="CODE">"1"</Skill>, "A/B" = choix, "CODE_*" = specialisation a choisir), a partir des textes
<Skills> et <Talents> de chaque carriere (le texte du livre y reste). V2 n a qu un niveau : toujours "1".

Meme lecture que les races (extraire_races_v2.py : decoupe, "A or B", "Trade (X, Y or Z)") plus :
"(any)", "(any one)", "(any three)" = autant de lignes "CODE_*" ; les specialisations nommees par une
carriere sont creees dans DATA_SKILL_SPECIALIZATION / DATA_TALENT_SPECIALIZATION si elles n y sont pas.

Usage : python structurer_carrieres_v2.py [--dry] [--liste]
Ordre : apres extraire_carrieres_v2.py, extraire_races_v2.py (qui reecrit les blocs de specialisation) ;
structurer_trappings_v2.py peut passer avant ou apres.
"""
import re
import sys
from xml.sax.saxutils import escape

import extraire_competences_talents_v2 as ct
import extraire_races_v2 as er

NOMBRES = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10}
NOMBRES_RE = "|".join(NOMBRES)          # one|two|... pour les expressions "(any three)"
# les 14 vertus de chevalerie de Knights of the Grail (Virtue of X / Grail Virtue of X)
VERTUS_CHEVALERIE = ("Audacity", "Confidence", "Discipline", "Duty", "Empathy", "Heroism", "the Ideal",
                     "the Impetuous Knight", "the Joust", "Knightly Temper", "Noble Disdain", "the Penitent", "Purity",
                     "Stoicism")


def codes_catalogue(xml):
    # prefixe de livre libre (RULES-, ROS-...) : le Core est en RULES-, les livres suivants gardent leur prefixe
    comp = {er.propre(m.group(2)).lower(): m.group(1) for m in
            re.finditer(r'<Skill id="([A-Z]+-COMP_[A-Z_0-9*]+)">(?:\s*<(?!Description)[^>]*>[^<]*</[^>]*>)*\s*<Description[^>]*>"([^"]*)"', xml)}
    tal = {er.propre(m.group(2)).lower(): m.group(1) for m in
           re.finditer(r'<Talent id="([A-Z]+-T_[A-Z_0-9*]+)">(?:\s*<(?!Description)[^>]*>[^<]*</[^>]*>)*\s*<Description[^>]*>"([^"]*)"', xml)}
    return comp, tal


def lit_specialisations(xml, balise):
    """specialisations deja ecrites : id -> (libelle, generique)."""
    res = {}
    for m in re.finditer(r'<%s id="([^"]*)">\s*<Description[^>]*>"([^"]*)"</Description>\s*<Generique>"([^"]*)"</Generique>' % balise, xml):
        res[m.group(1)] = (m.group(2), m.group(3), "0")
    return res


RENOMME = {"street fighter": "Street Fighting", "animal trainer": "Animal Training", "pubic speaking": "Public Speaking",
           "armoured caster": "Armoured Casting",
           # coquilles et variantes du Career Compendium (16/10/2026)
           "strong minded": "Strong-minded", "stout hearted": "Stout-hearted", "cool headed": "Coolheaded",
           "cool-headed": "Coolheaded", "fleet-footed": "Fleet Footed", "navigate": "Navigation",
           "intimidation": "Intimidate", "prepare poisons": "Prepare Poison", "master orater": "Master Orator",
           "seasonsed traveller": "Seasoned Traveller", "arcane language (magick)": "Speak Arcane Language (Magick)",
           # Career Expansion 2.2 (fan)
           "scale sheer surfaces": "Scale Sheer Surface", "lighting reflexes": "Lightning Reflexes",
           # Unofficial Tome of Careers (fan) : fautes de frappe et variantes de nom
           "resistant to poison": "Resistance to Poison", "dodge": "Dodge Blow", "channeling": "Channelling",
           "seasoned traveler": "Seasoned Traveller", "slight of hand": "Sleight of Hand", "very resistant": "Very Resilient",
           "lightening reflexes": "Lightning Reflexes", "oreintation": "Orientation", "stouthearted": "Stout-hearted",
           "stout- hearted": "Stout-hearted", "quickdraw": "Quick Draw", "ettiquette": "Etiquette",
           "supper numerate": "Super Numerate", "marksmanship": "Marksman", "drive cart": "Drive",
           "performer (acrobatics)": "Performer (Acrobat)", "aethyric atttunement": "Aethyric Attunement",
           "deal maker": "Dealmaker", "street wise": "Streetwise", "strike-to-stun": "Strike to Stun",
           "magic sense": "Magical Sense", "performer (singer)": "Performer (Singer)",
           "evalute": "Evaluate", "lighting parry": "Lightning Parry", "magic sense": "Magical Sense", "pick locks": "Pick Lock", "performance (storytelling)": "Performer (Storyteller)",
           "strong- minded": "Strong-minded", "sharp shooter": "Sharpshooter",
           "warrior": "Warrior Born", "mime": "Mimic",
           "specialist weapon group-great weapon": "Specialist Weapon Group (Two-handed)",
           "specialist weapon-crossbow pistol": "Specialist Weapon Group (Crossbow)"}


def corrige(nom):
    """coquilles du livre et variantes de nom -> nom du catalogue."""
    nom = nom.strip().strip(",").strip()
    m = re.match(r"^specialist weapons? (?:group )?\((.*)\)$", nom, re.I)
    if m:
        # le Core ecrit "Two-handed Weapon" dans deux carrieres (Cavalry or ..., Flail or ...) : le groupe est Two-handed
        groupe = re.sub(r"^two-handed weapon$", "Two-handed", m.group(1), flags=re.I)
        return "Specialist Weapon Group (%s)" % groupe
    # Unofficial Tome of Careers : "Advanced Knowledge (X)" du fan = Academic Knowledge (X) ; "Lore (Lore of the X)" =
    # Arcane Lore (X) ; "Norse Ceremonies&amp;one more" = deux specialisations a choisir
    m = re.match(r"^advanced knowledge\s*\((.*)\)$", nom, re.I)
    if m:
        return "Academic Knowledge (%s)" % m.group(1).replace("&amp;one more", "").strip()
    m = re.match(r"^lore\s*\(lore of the (.*)\)$", nom, re.I)
    if m:
        return "Arcane Lore (%s)" % m.group(1)
    return RENOMME.get(nom.lower(), nom)


def mere_de(base, codes, mere_suffixe):
    """(code de la mere, code generique '..._*', prefixe des specialisations) ; la mere peut s appeler 'X (Various)' ou 'X'."""
    mere = codes.get("%s (%s)" % (base.lower(), mere_suffixe.lower()))
    if mere:
        pre = mere[:-1]
        return mere, mere, pre
    mere = codes.get(base.lower())
    if mere:
        if mere.endswith("__*"):             # mere deja generique (RULES-T_ARCANE_LORE__*) : les specialisations ajoutent le nom
            return mere, mere, mere[:-1]
        return mere, mere + "__*", mere + "__"
    return None, None, None


def unitaire(nom, codes, specs, mere_suffixe, rapport):
    """un nom du livre -> liste de codes (plusieurs pour '(any three)')."""
    nom = corrige(nom)
    m = re.match(r"^(.*?)\s*\((.*)\)$", nom)
    if m:
        base, spec = m.group(1), m.group(2).strip()
        mere, gen, pre = mere_de(base, codes, mere_suffixe)
        if not mere:
            rapport.append("mere introuvable : " + nom)
            return [nom]
        a = re.match(r"^any(?:\s+(%s))?$" % NOMBRES_RE, spec, re.I)
        if a:
            return [gen] * (NOMBRES[a.group(1).lower()] if a.group(1) else 1)
        sid = pre + re.sub(r"[^A-Z0-9]+", "_", spec.upper()).strip("_")
        if sid not in codes.values():
            specs.setdefault(sid, ("%s (%s)" % (base, spec), gen, "0"))
        return [sid]
    code = codes.get(nom.lower())
    if not code:
        rapport.append("code introuvable : " + nom)
        return [nom]
    return [code]


def unitaire_liste(morceau, codes, specs, mere_suffixe, rapport):
    res = []
    for alt in er.decoupe(morceau, [" or "]):
        m2 = re.match(r"^(.*?)\s*\((.*)\)$", alt)
        if m2 and re.search(r"(,|/|\s+or\s+)", m2.group(2)):
            for sp in re.split(r"\s*(?:,\s*or\s+|,\s*|\s+or\s+|/)", m2.group(2)):
                res += unitaire("%s (%s)" % (m2.group(1), sp.strip()), codes, specs, mere_suffixe, rapport)
        else:
            res += unitaire(alt, codes, specs, mere_suffixe, rapport)
    return res


def lignes(texte, codes, specs, mere_suffixe, rapport):
    texte = re.sub(r"\s+", " ", texte.replace("�", "'")).strip(" .,")
    # "Rune (any two with an Inscription Number of 10 or less)" : le choix est libre, la condition reste dans le
    # texte du livre ; retiree avant le decoupage sur " or "
    texte = re.sub(r"\((any (?:%s)) with [^)]*\)" % NOMBRES_RE, r"(\1)", texte, flags=re.I)
    # Knights of the Grail : "Virtue of Knighthood (any one)" et "Grail Virtue (the one that matches ...)" sont des
    # choix parmi 14 talents distincts (chacun avec sa regle), donc une liste d alternatives, pas un talent generique
    texte = re.sub(r"Virtue of Knighthood \(any one\)", " or ".join("Virtue of " + v for v in VERTUS_CHEVALERIE), texte)
    texte = re.sub(r"Grail Virtue \(the one that matches [^)]*\)", " or ".join("Grail Virtue of " + v for v in VERTUS_CHEVALERIE), texte)
    res, apres = [], []
    morceaux = er.decoupe(texte, [", and ", ", ", " and "])
    # "Any one of: A, B, C" : choix sur le reste de la liste, sauf si le premier element porte deja une liste
    # de specialisations entre parentheses ("Any one of: Trade (X, Y or Z)") : le choix ne couvre que lui
    for i, mo in enumerate(morceaux):
        a = re.match(r"^any (%s) of:\s*(.*)$" % NOMBRES_RE, mo, re.I)
        if a:
            n = NOMBRES[a.group(1).lower()]
            premier = a.group(2)
            if re.search(r"\(.*(,|or).*\)", premier):
                morceaux[i] = premier
            else:
                reste = [premier] + morceaux[i + 1:]
                del morceaux[i:]
                alternatives = []
                for r in reste:
                    alternatives += unitaire_liste(r, codes, specs, mere_suffixe, rapport)
                apres = ["/".join(alternatives)] * n
                break
    for morceau in morceaux:
        choix = []
        for alt in er.decoupe(morceau, [" or "]):
            m2 = re.match(r"^(.*?)\s*\((.*)\)$", alt)
            if m2 and re.search(r"(,|/|\s+or\s+)", m2.group(2)):
                for sp in re.split(r"\s*(?:,\s*or\s+|,\s*|\s+or\s+|/)", m2.group(2)):
                    choix += unitaire("%s (%s)" % (m2.group(1), sp.strip()), codes, specs, mere_suffixe, rapport)
            else:
                choix += unitaire(alt, codes, specs, mere_suffixe, rapport)
        if len(choix) > 1 and re.search(r"\(any (%s)\)" % NOMBRES_RE.replace("one|", ""), morceau, re.I):
            res += choix                      # "(any three)" : trois lignes, pas un choix
        else:
            res.append("/".join(choix))
    return res + apres


def bloc(balise, ligne_balise, codes):
    out = ["<%s>" % balise]
    for c in codes:
        out.append('<%s name="%s">"1"</%s>' % (ligne_balise, escape(c, {'"': "&quot;"}), ligne_balise))
    out.append("</%s>" % balise)
    return chr(10).join(out) + chr(10)


def ecrit_specs(xml, balise, bloc_nom, specs, deja):
    neuves = {k: v for k, v in specs.items() if k not in deja}
    if not neuves:
        return xml, 0
    corps = []
    for sid, (desc, gen, page) in neuves.items():
        corps += ['<%s id="%s">' % (balise, sid),
                  '<Description language="ENGLISH">"%s"</Description>' % escape(desc),
                  '<Generique>"%s"</Generique>' % gen, "</%s>" % balise]
    txt = chr(10).join(corps) + chr(10)
    fin = "</%s>" % bloc_nom
    if fin in xml:
        xml = xml.replace(fin, txt + fin, 1)
    else:
        xml = xml.replace("</DATA_BOOK>", "<%s>" % bloc_nom + chr(10) + txt + fin + chr(10) + "</DATA_BOOK>", 1)
    return xml, len(neuves)


def main(argv):
    # --compendium : les carrieres du Career Compendium ; le catalogue (competences, talents,
    # specialisations) reste celui du Core, les specialisations nouvelles vont dans le Compendium
    # --corruption : les carrieres du Tome of Corruption, meme regime que le Compendium (catalogue du Core,
    # complete par les autres livres de talents)
    # --bestiary : les carrieres de shaman de l Old World Bestiary, meme regime
    # --skaven : les carrieres de Children of the Horned Rat, meme regime
    # --ndm : les carrieres de Night's Dark Masters, meme regime
    # --expansion : les carrieres de la Career Expansion 2.2 (fan, Jackdays), meme regime
    # --tome : les carrieres de l Unofficial Tome of Careers V2.0a (fan, Wolph42), meme regime
    # --trades : Trades of the Old World, meme regime que --araby (seule la cible change)
    # --dreb : Death's Rebirth, idem
    # --darkpath : The Dark Path, idem
    # --spears : Spears of the Maiden, idem
    trades = "--trades" in argv
    dreb = "--dreb" in argv
    darkpath = "--darkpath" in argv
    spears = "--spears" in argv
    zoats = "--zoats" in argv
    caravan = "--caravan" in argv
    wardancers = "--wardancers" in argv
    sots = "--sots" in argv
    gotrek = "--gotrek" in argv
    liche = "--liche" in argv
    reelem = "--reelem" in argv
    druids = "--druids" in argv
    litmagic = "--litmagic" in argv
    greenskins = "--greenskins" in argv
    norsca = "--norsca" in argv
    northmen = "--northmen" in argv
    swords = "--swords" in argv
    arabysg = "--arabysg" in argv
    thousandislas = "--thousandislas" in argv
    if (trades or dreb or darkpath or spears or zoats or caravan or wardancers or sots or gotrek or liche or reelem
            or druids or litmagic or greenskins or norsca or northmen or swords or arabysg
            or thousandislas):
        argv = list(argv) + ["--araby"]
    if ("--corruption" in argv or "--bestiary" in argv or "--skaven" in argv or "--ndm" in argv
            or "--expansion" in argv or "--tome" in argv or "--grognard" in argv or "--leopoi" in argv
            or "--defenders" in argv or "--araby" in argv):
        argv = list(argv) + ["--compendium"]
    cible = (ct.LIVRE.with_name("BOOK_TRADES_OLD_WORLD.Xml") if trades else
             ct.LIVRE.with_name("BOOK_DEATHS_REBIRTH.Xml") if dreb else
             ct.LIVRE.with_name("BOOK_THE_DARK_PATH.Xml") if darkpath else
             ct.LIVRE.with_name("BOOK_SPEARS_OF_THE_MAIDEN.Xml") if spears else
             ct.LIVRE.with_name("BOOK_ZOATS.Xml") if zoats else
             ct.LIVRE.with_name("BOOK_CARAVAN_CAREERS.Xml") if caravan else
             ct.LIVRE.with_name("BOOK_ELVEN_WARDANCERS.Xml") if wardancers else
             ct.LIVRE.with_name("BOOK_SORCERERS_OF_THE_SOUTH.Xml") if sots else
             ct.LIVRE.with_name("BOOK_GOTREK_AND_FELIX.Xml") if gotrek else
             ct.LIVRE.with_name("BOOK_LICHE.Xml") if liche else
             ct.LIVRE.with_name("BOOK_RETURN_OF_ELEMENTALISM.Xml") if reelem else
             ct.LIVRE.with_name("BOOK_DRUIDS_OLD_FAITH.Xml") if druids else
             ct.LIVRE.with_name("BOOK_LOST_IN_TRANSLATION_MAGIC.Xml") if litmagic else
             ct.LIVRE.with_name("BOOK_CODEX_GREENSKINS.Xml") if greenskins else
             ct.LIVRE.with_name("BOOK_NORSCA.Xml") if norsca else
             ct.LIVRE.with_name("BOOK_THE_NORTHMEN.Xml") if northmen else
             ct.LIVRE.with_name("BOOK_SWORDS_OF_THE_SOUTH.Xml") if swords else
             ct.LIVRE.with_name("BOOK_ARABY_SAND_AND_GOLD.Xml") if arabysg else
             ct.LIVRE.with_name("BOOK_THOUSAND_ISLAS.Xml") if thousandislas else
             ct.LIVRE.with_name("BOOK_MAGIC_OF_ARABY.Xml") if "--araby" in argv else
             ct.LIVRE.with_name("BOOK_DEFENDERS_OF_THE_FOREST.Xml") if "--defenders" in argv else
             ct.LIVRE.with_name("BOOK_LEOPOI.Xml") if "--leopoi" in argv else
             ct.LIVRE.with_name("BOOK_GROGNARD_CAREERS.Xml") if "--grognard" in argv else
             ct.LIVRE.with_name("BOOK_UNOFFICIAL_TOME_OF_CAREERS.Xml") if "--tome" in argv else
             ct.LIVRE.with_name("BOOK_CAREER_EXPANSION.Xml") if "--expansion" in argv else
             ct.LIVRE.with_name("BOOK_NIGHTS_DARK_MASTERS.Xml") if "--ndm" in argv else
             ct.LIVRE.with_name("BOOK_CHILDREN_OF_THE_HORNED_RAT.Xml") if "--skaven" in argv else
             ct.LIVRE.with_name("BOOK_OLD_WORLD_BESTIARY.Xml") if "--bestiary" in argv else
             ct.LIVRE.with_name("BOOK_TOME_OF_CORRUPTION.Xml") if "--corruption" in argv else
             ct.LIVRE.with_name("BOOK_CAREER_COMPENDIUM.Xml") if "--compendium" in argv else ct.LIVRE)
    xml_core = ct.LIVRE.read_text(encoding="utf-8")
    xml = cible.read_text(encoding="utf-8")
    comp, tal = codes_catalogue(xml_core)
    sp_comp = lit_specialisations(xml_core, "Skill")
    sp_tal = lit_specialisations(xml_core, "Talent")
    if cible != ct.LIVRE:
        sp_comp.update(lit_specialisations(xml, "Skill"))
        sp_tal.update(lit_specialisations(xml, "Talent"))
    if "--compendium" in argv:
        # Realms of Sorcery : competence Runecraft, talents Rune et Master Rune et leurs specialisations
        # (les carrieres de runesmith y renvoient) ; le Core garde la priorite sur les noms
        # Knights of the Grail : talents Birth Sword, Virtues of Knighthood et Grail Virtues
        # Tome of Corruption : Inured to Chaos, Chosen of Chaos, Controlled Corruption, Daemonic Aura, Scales...
        for nom_livre in ("BOOK_REALMS_OF_SORCERY.Xml", "BOOK_KNIGHTS_OF_THE_GRAIL.Xml", "BOOK_TOME_OF_CORRUPTION.Xml",
                          "BOOK_CHILDREN_OF_THE_HORNED_RAT.Xml", "BOOK_SHADES_OF_EMPIRE.Xml"):
            xml_livre = ct.LIVRE.with_name(nom_livre).read_text(encoding="utf-8")
            comp_r, tal_r = codes_catalogue(xml_livre)
            for k, v in comp_r.items():
                comp.setdefault(k, v)
            for k, v in tal_r.items():
                tal.setdefault(k, v)
            sp_comp.update(lit_specialisations(xml_livre, "Skill"))
            sp_tal.update(lit_specialisations(xml_livre, "Talent"))
    if "--tome" in argv or "--grognard" in argv or "--leopoi" in argv or "--defenders" in argv or "--araby" in argv:
        # la Career Expansion 2.2 a deja cree des talents que le Tome reprend (Focused Strike, Politic...) ; ses propres
        # talents (UTOC-T_...) passent ensuite
        xml_exp = ct.LIVRE.with_name("BOOK_CAREER_EXPANSION.Xml").read_text(encoding="utf-8")
        comp_x, tal_x = codes_catalogue(xml_exp)
        for k, v in tal_x.items():
            tal.setdefault(k, v)
        for k, v in comp_x.items():
            comp.setdefault(k, v)
    if "--grognard" in argv or "--leopoi" in argv or "--defenders" in argv or "--araby" in argv:
        # les competences et talents du Tome (UTOC-...) que les fiches de Grognard reprennent
        xml_tome = ct.LIVRE.with_name("BOOK_UNOFFICIAL_TOME_OF_CAREERS.Xml").read_text(encoding="utf-8")
        comp_t, tal_t = codes_catalogue(xml_tome)
        for k, v in tal_t.items():
            tal.setdefault(k, v)
        for k, v in comp_t.items():
            comp.setdefault(k, v)
    if "--expansion" in argv or "--tome" in argv or "--defenders" in argv or "--araby" in argv:
        # les talents nouveaux de l extension elle-meme (JCE-T_...) ; le Core garde la priorite sur les noms
        comp_e, tal_e = codes_catalogue(xml)
        for k, v in tal_e.items():
            tal.setdefault(k, v)
        for k, v in comp_e.items():
            comp.setdefault(k, v)
    deja_c, deja_t = dict(sp_comp), dict(sp_tal)
    # les specialisations existantes comptent comme codes connus
    rapport, sortie = [], []

    def traite(m):
        corps = m.group(0)
        code = m.group(1)
        corps = re.sub(r"<SUBCHAPTER_SKILL>.*?</SUBCHAPTER_SKILL>\n?", "", corps, flags=re.S)
        corps = re.sub(r"<SUBCHAPTER_TALENT>.*?</SUBCHAPTER_TALENT>\n?", "", corps, flags=re.S)
        sk = re.search(r'<Skills>"([^"]*)"</Skills>', corps)
        ta = re.search(r'<Talents>"([^"]*)"</Talents>', corps)
        rap = []
        txt_s, txt_t = (sk.group(1) if sk else ""), (ta.group(1) if ta else "")
        if "--tome" in argv or "--grognard" in argv or "--leopoi" in argv or "--defenders" in argv or "--araby" in argv:
            # fautes de ponctuation du fan : points au lieu de virgules, "None" pour une liste vide
            txt_s = txt_s.replace("Dodge Blow. Follow Trail. Gossip", "Dodge Blow, Follow Trail, Gossip")
            txt_s = txt_s.replace("Blather or Academic, Knowledge (Law)", "Blather or Academic Knowledge (Law)")
            txt_s = txt_s.replace("Performer (singer one) +any", "Performer (Singer), Performer (any one)")
            txt_s = txt_s.replace("Secret Tongue (", "Secret Language (")
            txt_s = txt_s.replace("Sense Magic", "Magical Sense")  # Death's Rebirth, Blood Reaper
            txt_s = re.sub(r"Two of: ", "Any two of: ", txt_s)
            txt_s, txt_t = ("" if txt_s.strip().lower() == "none" else txt_s), ("" if txt_t.strip().lower() == "none" else txt_t)
            # le fan range parfois un talent dans la liste des competences (Magical Sense, Public Speaking) ou
            # l inverse : le nom est deplace vers la liste ou le catalogue le connait
            def deplace(source, cat_ici, cat_autre):
                gardes, bouges = [], []
                for p in re.split(r",\s*", source):
                    alts = [corrige(a).lower() for a in re.split(r"\s+or\s+", p)]
                    # "Trade (Apothecary)" : on compare le nom de base, la mere s appelle "Trade (Various)"
                    bases = [re.sub(r"\s*\(.*$", "", a) for a in alts]
                    def connu(cat, a, b):
                        return a in cat or b in cat or b + " (various)" in cat
                    ailleurs = all(connu(cat_autre, a, b) and not connu(cat_ici, a, b) for a, b in zip(alts, bases))
                    (bouges if ailleurs else gardes).append(p)
                return ", ".join(gardes), bouges
            txt_s, vers_t = deplace(txt_s, comp, tal)
            txt_t, vers_s = deplace(txt_t, tal, comp)
            txt_t = ", ".join(x for x in [txt_t] + vers_t if x)
            txt_s = ", ".join(x for x in [txt_s] + vers_s if x)
        cs = lignes(txt_s, comp, sp_comp, "VARIOUS", rap) if txt_s else []
        ct_ = lignes(txt_t, tal, sp_tal, "VARIOUS", rap) if txt_t else []
        for r in rap:
            rapport.append("%s : %s" % (re.sub(r"^[A-Z]+-CARE_", "", code), r))
        sortie.append((code, sk.group(1) if sk else "", cs, ta.group(1) if ta else "", ct_))
        ajout = bloc("SUBCHAPTER_SKILL", "Skill", cs) + bloc("SUBCHAPTER_TALENT", "Talent", ct_)
        # apres le materiel s il existe, sinon apres Trappings
        for fin in ("</SUBCHAPTER_ITEM>\n", "</Trappings>\n"):
            i = corps.find(fin)
            if i >= 0:
                i += len(fin)
                return corps[:i] + ajout + corps[i:]
        rapport.append("%s : ni Trappings ni materiel" % code)
        return corps

    xml2 = re.sub(r'<Career id="([A-Z]+-CARE_[A-Z_0-9]+)">.*?</Career>', traite, xml, flags=re.S)
    print("Carrieres : %d" % len(sortie))
    if "--liste" in argv:
        for code, st, cs, tt, ct_ in sortie:
            print("%s\n  S: %s\n   -> %s\n  T: %s\n   -> %s" % (re.sub(r"^[A-Z]+-CARE_", "", code), st, ", ".join(c.replace("RULES-", "") for c in cs),
                                                                   tt, ", ".join(c.replace("RULES-", "") for c in ct_)))
    for r in rapport:
        print("  A VOIR : " + r)
    nc = sum(1 for k in sp_comp if k not in deja_c)
    nt = sum(1 for k in sp_tal if k not in deja_t)
    print("Specialisations a ajouter : %d de competence, %d de talent" % (nc, nt))
    if "--dry" in argv or "--liste" in argv:
        return 1 if rapport else 0
    xml2, a = ecrit_specs(xml2, "Skill", "DATA_SKILL_SPECIALIZATION", sp_comp, deja_c)
    xml2, b = ecrit_specs(xml2, "Talent", "DATA_TALENT_SPECIALIZATION", sp_tal, deja_t)
    cible.write_text(xml2, encoding="utf-8", newline=chr(10))
    print("Ecrit : %s (%d specialisations de competence, %d de talent)" % (cible, a, b))
    return 1 if rapport else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

# Cree PICTURES_DEFAULT\CLASS et \SPECIE pour WFRP1 / WFRP2 (images propres, publiables).
# 1) reutilise l image V4 de meme nom (PICTURES_DEFAULT de WFRP4), 2) sinon dessine un badge
# rouge / or a pictogramme de classe. Usage : python creer_images_defaut.py [--ecrire]
# Sans --ecrire : rapport seulement (rien n est cree). Ne remplace jamais un fichier existant.
import os, re, shutil, sys
from PIL import Image, ImageDraw

RACINE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(RACINE, "DATABASE")
ROUGE, OR, BRUN = (140, 42, 30), (222, 178, 84), (52, 34, 22)
ECRIRE = "--ecrire" in sys.argv

def norm(s):
    s = re.sub(r"[^A-Z]", "", s.upper())
    return s[:-1] if s.endswith("S") else s

def nom_court(code):
    return code.split("-", 1)[1].split("_", 1)[1] if "-" in code else code

# ---------- pictogrammes (dessines sur 1024 puis reduits a 256) ----------
def glyphe(d, c):
    if c == "ACAD":      # livre ouvert
        d.polygon([(512, 330), (512, 740), (270, 690), (270, 280)], fill=OR)
        d.polygon([(512, 330), (512, 740), (754, 690), (754, 280)], fill=OR)
        d.line([(512, 330), (512, 740)], fill=ROUGE, width=18)
    elif c == "BURG":    # maison
        d.polygon([(512, 250), (790, 480), (230, 480)], fill=OR)
        d.rectangle([290, 480, 734, 760], fill=OR)
        d.rectangle([465, 580, 559, 760], fill=ROUGE)
    elif c == "COUR":    # couronne
        d.polygon([(270, 690), (230, 360), (390, 520), (512, 320), (634, 520), (794, 360), (754, 690)], fill=OR)
        d.rectangle([270, 700, 754, 770], fill=OR)
    elif c == "PEAS":    # epi de ble
        d.line([(512, 770), (512, 280)], fill=OR, width=26)
        for i in range(4):
            y = 330 + i * 100
            d.ellipse([410, y, 505, y + 70], fill=OR)
            d.ellipse([519, y, 614, y + 70], fill=OR)
        d.ellipse([480, 230, 544, 330], fill=OR)
    elif c == "RANG":    # arbre
        d.rectangle([485, 640, 539, 790], fill=OR)
        for top, larg in ((250, 150), (360, 200), (480, 250)):
            d.polygon([(512, top), (512 + larg, top + 220), (512 - larg, top + 220)], fill=OR)
    elif c == "RIVE":    # barque et voile
        d.polygon([(250, 600), (774, 600), (680, 740), (344, 740)], fill=OR)
        d.line([(512, 600), (512, 250)], fill=OR, width=22)
        d.polygon([(530, 270), (530, 570), (740, 570)], fill=OR)
    elif c == "ROGU":    # masque
        d.ellipse([260, 330, 764, 700], fill=OR)
        d.ellipse([330, 450, 460, 540], fill=ROUGE)
        d.ellipse([564, 450, 694, 540], fill=ROUGE)
    elif c == "SEAF":    # ancre
        d.ellipse([462, 230, 562, 330], outline=OR, width=26)
        d.line([(512, 330), (512, 760)], fill=OR, width=30)
        d.line([(400, 400), (624, 400)], fill=OR, width=26)
        d.arc([280, 480, 744, 860], 20, 160, fill=OR, width=30)
    elif c == "WARR":    # epees croisees
        import math
        for sens in (1, -1):
            xp, xm = (300, 724)[::sens]          # pointe en haut, pommeau en bas
            pointe, pommeau = (xp, 270), (xm, 770)
            dx, dy = pommeau[0] - pointe[0], pommeau[1] - pointe[1]
            n = math.hypot(dx, dy)
            ux, uy = dx / n, dy / n
            d.line([pointe, pommeau], fill=OR, width=44)
            gx, gy = pointe[0] + ux * n * 0.68, pointe[1] + uy * n * 0.68
            d.line([(gx - uy * 95, gy + ux * 95), (gx + uy * 95, gy - ux * 95)], fill=OR, width=40)
            d.ellipse([pommeau[0] - 34, pommeau[1] - 34, pommeau[0] + 34, pommeau[1] + 34], fill=OR)
    else:                # silhouette (especes) : tete et epaules
        d.ellipse([402, 260, 622, 480], fill=OR)
        d.pieslice([280, 520, 744, 980], 180, 360, fill=OR)

def badge(classe, chemin):
    g = 1024
    im = Image.new("RGBA", (g, g), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([8, 8, g - 8, g - 8], fill=OR)
    d.ellipse([40, 40, g - 40, g - 40], fill=ROUGE)
    glyphe(d, classe)
    im = im.resize((256, 256), Image.LANCZOS)
    im.save(chemin)

# ---------- classe d un metier V2 (pas de classe dans les donnees) ----------
MOTS = [
    ("SEAF", ["SEA", "MATE", "NAVIGATOR", "WHALER", "PIRATE", "ADMIRAL", "SAILOR", "MARINE", "REAVER", "SWAMP_SKIMMER", "CORSAIR"]),
    ("RIVE", ["FERRY", "BOAT", "FISHER", "SMUGGLER", "RIVER", "BARGE", "SKIMMER"]),
    ("ACAD", ["WIZARD", "MAGE", "MAGUS", "PRIEST", "SCHOLAR", "STUDENT", "SCRIBE", "SEER", "ASTROLOG", "APPRENTICE", "MAGISTER",
              "ABBOT", "MONK", "FRIAR", "CANTOR", "PILGRIM", "SORCER", "WARLOCK", "WITCH", "CULT", "SHAMAN", "DRUID", "RUNE",
              "ALCHEM", "PHYSICIAN", "CATECHIST", "EXORCIST", "MYSTIC", "CENOBITE", "ANCHORITE", "PRELATE", "VITKI", "SKALD",
              "FAMILIAR", "DOOMWEAVER", "CLERIC", "VIGILANT", "HEDGE", "HAG", "FROGWIFE", "WISE_WOMAN", "EMBALMER", "ENGINEER", "MALEDICTOR", "CATACLYST"]),
    ("WARR", ["KNIGHT", "WARRIOR", "CHAMPION", "GUARD", "SOLDIER", "MERCENARY", "SLAYER", "FIGHTER", "BERSERKER", "CAPTAIN",
              "SERGEANT", "VETERAN", "THUG", "BRUTE", "MILITIA", "MAN_AT_ARMS", "TEMPLAR", "CRUSADER", "MARAUDER", "STORMVERMIN",
              "BESTIGOR", "CHAOS", "DUEL", "BODYGUARD", "CAVALRY", "ARCHER", "PISTOLIER", "OUTRIDER", "SQUIRE", "ENFORCER",
              "STRELTSI", "SHIELD", "HUNTER", "VAMPIRE", "DEMON", "SCOURGE", "GRANDMASTER", "TARGETEER", "SKIRMISHER", "WARLEADER",
              "CLAN", "ASSASSIN", "ZEALOT", "GRAIL", "RAVEN", "KITHBAND", "KILLER", "THRALL", "SOULFLAYER", "EXALTED"]),
    ("COUR", ["NOBLE", "COURTIER", "HERALD", "STEWARD", "VALET", "POLITICIAN", "AMBASSADOR", "ATAMAN", "FOREMAN", "MEDIATOR", "DILETTANTE"]),
    ("BURG", ["MERCHANT", "TRADE", "BURGHER", "GUILD", "INNKEEPER", "ARTISAN", "APOTHECARY", "LAWYER", "LITIGANT", "BARBER", "BEADLE", "PAMPHLET", "NEWSSHEET", "TOLL", "EXCISE"]),
    ("RANG", ["RANGER", "WOODSMAN", "SCOUT", "TRAPPER", "HERD", "HORSE", "TAMER", "TRAINER", "DROVER", "SHEPHERD", "BADLAND", "NOMAD", "FARMER", "CHARCOAL", "GAMEKEEPER", "SWAMPAIRE", "EXPLORER"]),
    ("ROGU", ["THIEF", "ROGUE", "BURGLAR", "OUTLAW", "HIGHWAY", "SPY", "GAMBLER", "MINSTREL", "VAGABOND", "RAPSCALLION", "CRIME", "CONVICT", "RACONTEUR", "NIGHT_RUNNER", "GUTTER", "FACELESS", "TOMB", "BONE_PICKER", "SEWER", "JACK"]),
]
def classe_de(nom):
    n = nom.upper()
    for c, mots in MOTS:
        if any(m in n for m in mots):
            return c
    return "PEAS"

# ---------- lecture des livres ----------
def lire_ids(version, balise):
    res = []
    for f in sorted(os.listdir(os.path.join(DB, version))):
        if not f.upper().endswith(".XML"):
            continue
        txt = open(os.path.join(DB, version, f), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'<%s id="([^"]+)">' % balise, txt):
            fin = txt.find("</%s>" % balise, m.end())
            bloc = txt[m.end():fin]
            cl = re.search(r"<Class>\"([^\"]+)\"", bloc)
            res.append((m.group(1), cl.group(1) if cl else ""))
    return res

V1_CLASSES = {"RULES-CLASS_WARRIOR": "WARR", "RULES-CLASS_RANGER": "RANG", "RULES-CLASS_ROGUE": "ROGU", "RULES-CLASS_ACADEMIC": "ACAD"}
ALIAS_ESPECE = {"ELF": "HELF", "ELFDARK": "DELF", "ELFWOOD": "WELF", "BLACKORC": "BORC", "COMMONORC": "CORC", "GOBLIN": "CGOB",
                "HILLGOBLIN": "HGOB", "NIGHTGOBLIN": "NGOB", "HOBGOBLIN": "HGOB", "SAURU": "LIZARD", "SKINK": "LIZARD",
                "SLANN": "LIZARD", "KROXIGOR": "LIZARD", "CHAMELEON": "LIZARD", "OGREKINGDOM": "OGRE", "OGREWANDERER": "OGRE"}

def main():
    v4c = {norm(nom_court(os.path.splitext(f)[0])): f for f in os.listdir(os.path.join(DB, "WFRP4", "PICTURES_DEFAULT", "CLASS"))}
    v4s = {norm(nom_court(os.path.splitext(f)[0])): f for f in os.listdir(os.path.join(DB, "WFRP4", "PICTURES_DEFAULT", "SPECIE"))}
    for v in ("WFRP1", "WFRP2"):
        for genre, balise, ref, sub in (("metier", "Career", v4c, "CLASS"), ("espece", "Specie", v4s, "SPECIE")):
            sortie = os.path.join(DB, v, "PICTURES_DEFAULT", sub)
            srcdir = os.path.join(DB, "WFRP4", "PICTURES_DEFAULT", sub)
            if ECRIRE:
                os.makedirs(sortie, exist_ok=True)
            vus, copies, dessines, existants = set(), 0, 0, 0
            # Especes : seulement celles qui ont une image officielle (le reste = creatures de bestiaire)
            jouables = set(re.sub(r"(_TRANS)?\d*\.png$", "", f, flags=re.I) for f in os.listdir(os.path.join(DB, v, "PICTURES", sub)))
            for code, cl in lire_ids(v, balise):
                if code in vus or (genre == "espece" and code not in jouables):
                    continue
                vus.add(code)
                nom = nom_court(code)
                cible = os.path.join(sortie, code + ("1" if genre == "espece" else "") + ".png")
                if os.path.exists(cible) and "--forcer" not in sys.argv:
                    existants += 1
                    continue
                cle = norm(nom)
                if genre == "espece":
                    cle = ALIAS_ESPECE.get(cle, cle)
                if cle in ref:
                    copies += 1
                    if ECRIRE:
                        shutil.copyfile(os.path.join(srcdir, ref[cle]), cible)
                else:
                    dessines += 1
                    if genre == "metier":
                        classe = V1_CLASSES.get(cl) or classe_de(nom)
                    else:
                        classe = "ESP"
                    if ECRIRE:
                        badge(classe, cible)
            print(v, sub, "fiches", len(vus), "deja la", existants, "copiees de V4", copies, "dessinees", dessines)

main()

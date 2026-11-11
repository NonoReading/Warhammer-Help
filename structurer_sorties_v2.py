#!/usr/bin/env python3
"""Structure les SORTIES de carriere V2 et marque les carrieres de BASE (16/10/2026).

Les <Exits> V2 sont du texte ("Charlatan, Demagogue, Outlaw"). Ce script ajoute, juste apres
chaque <Exits>, une ligne <ExitCodes> en codes de carriere (separes par des virgules) et, pour
les 60 carrieres de base du Core (Table 3-2, page 30), une ligne <Basic>"1"</Basic>.

Les noms sont resolus sur l'ensemble des livres de DATABASE/WFRP2 (Core d'abord). Une
precision entre parentheses ("Priest (Morr only)") est ignoree. Les noms introuvables sont
listes (A VOIR) et laisses de cote. Relancable sans risque : les lignes existantes sont
remplacees. Usage : python structurer_sorties_v2.py [--dry]
"""
import re
import sys
from pathlib import Path

DOSSIER = Path(__file__).parent / "DATABASE" / "WFRP2"
CORE = DOSSIER / "BOOK_RULESBOOK.Xml"

BASE = """Agitator, Apprentice Wizard, Bailiff, Barber-Surgeon, Boatman, Bodyguard, Bone Picker,
Bounty Hunter, Burgher, Camp Follower, Charcoal-Burner, Coachman, Entertainer, Envoy,
Estalian Diestro, Ferryman, Fieldwarden, Fisherman, Grave Robber, Hedge Wizard, Hunter,
Initiate, Jailer, Kislevite Kossar, Kithband Warrior, Marine, Mercenary, Messenger, Militiaman,
Miner, Noble, Norse Berserker, Outlaw, Outrider, Peasant, Pit Fighter, Protagonist,
Rat Catcher, Roadwarden, Rogue, Runebearer, Scribe, Seaman, Servant, Shieldbreaker, Smuggler,
Soldier, Squire, Student, Thief, Thug, Toll Keeper, Tomb Robber, Tradesman, Troll Slayer,
Vagabond, Valet, Watchman, Woodsman, Zealot"""

# Carrieres de BASE du Career Compendium (etiquette "Basic" ou "Basic / Special" en haut de page,
# relevee dans le PDF le 16/10/2026) : 54 + Apprentice Runesmith, Apprentice Witch, Pilgrim, Slave,
# Steppes Nomad, Wise Woman.
BASE_CCOMP = """Anchorite, Apothecary, Badlander, Bear Tamer, Bondsman, Cadet, Carcassonne Shepherd,
Cartographer, Cenobite, Chekist, Chimneysweep, Deepwatcher, Dilettante, Drover, Dung Collector,
Embalmer, Ex-Convict, Exciseman, Farmer, Freeholder, Frogwife, Gambler, Grail Pilgrim, Grave Warden,
Hedgecraft Apprentice, Herrimault, Horned Hunter, Horse Coper, Knight Errant, Lamplighter, Litigant,
Man-at-Arms, Marauder, Mediator, Monk, Muleskinner, Newssheet Vendor, Penitent, Raconteur, Reaver,
Riverwarden, Seer, Sewer Jack, Skald, Stevedore, Streltsi, Strigany Mystic, Swamp Skimmer, Swampaire,
Temple Guardian, Village Elder, Wall Warden, Whaler, Wrecker, Apprentice Runesmith, Apprentice Witch,
Pilgrim, Slave, Steppes Nomad, Wise Woman"""


def cle(nom):
    nom = re.sub(r"\(.*?\)", "", nom)
    return re.sub(r"[^a-z0-9]+", "", nom.lower())


def main(argv):
    livres = [CORE] + sorted(p for p in DOSSIER.glob("BOOK_*.Xml") if p != CORE)
    textes = {p: p.read_text(encoding="utf-8") for p in livres}
    # nom (cle) -> code, Core prioritaire
    codes = {}
    for p in livres:
        for code, nom in re.findall(
                r'<Career id="([^"]+)">\s*<Description language="ENGLISH">"([^"]*)"', textes[p]):
            codes.setdefault(cle(nom), code)
    base = {cle(n) for n in BASE.replace("\n", " ").split(",") if n.strip()}
    if len(base) != 60:
        print("ATTENTION : %d carrieres de base lues, 60 attendues" % len(base))
    base_cc = {cle(n) for n in BASE_CCOMP.replace(chr(10), " ").split(",") if n.strip()}
    if len(base_cc) != 60:
        print("ATTENTION : %d carrieres de base du Compendium lues, 60 attendues" % len(base_cc))
    inconnus = set()
    for p in livres:
        def traite(m):
            corps = m.group(0)
            corps = re.sub(r"<ExitCodes>.*?</ExitCodes>\n?", "", corps, flags=re.S)
            if p == CORE or p.name == "BOOK_CAREER_COMPENDIUM.Xml":
                # Core et Compendium : liste BASE ; les autres livres posent Basic eux-memes (extracteur du livre)
                corps = re.sub(r"<Basic>.*?</Basic>\n?", "", corps, flags=re.S)
            nom = re.search(r'<Description language="ENGLISH">"([^"]*)"', corps).group(1)
            ex = re.search(r'<Exits>"([^"]*)"</Exits>\n?', corps)
            ajout = ""
            if ex:
                liste = []
                for n in ex.group(1).split(","):
                    if not n.strip():
                        continue
                    c = codes.get(cle(n))
                    dieu = re.search(r" of (\w+)$", nom)
                    if not c and cle(n) == "cultmagus" and dieu:
                        # sortie generique du Tome of Corruption : le Cult Magus du meme dieu
                        c = codes.get(cle("Cult Magus of " + dieu.group(1)))
                    if c:
                        if c not in liste:
                            liste.append(c)
                    else:
                        inconnus.add("%s : %s" % (nom, n.strip()))
                if liste:
                    ajout += '<ExitCodes>"%s"</ExitCodes>\n' % ",".join(liste)
            if (p == CORE and cle(nom) in base) or (p.name == "BOOK_CAREER_COMPENDIUM.Xml" and cle(nom) in base_cc):
                ajout += '<Basic>"1"</Basic>\n'
            if ajout:
                i = corps.find("</Exits>\n")
                i = i + len("</Exits>\n") if i >= 0 else corps.rfind("</Career>")
                corps = corps[:i] + ajout + corps[i:]
            return corps
        textes[p] = re.sub(r'<Career id="[^"]+">.*?</Career>', traite, textes[p], flags=re.S)
    for c in sorted(inconnus):
        print("  A VOIR (nom de sortie sans carriere) : " + c)
    if "--dry" in argv:
        return 0
    for p in livres:
        p.write_text(textes[p], encoding="utf-8", newline="\n")
        n1 = len(re.findall(r"<ExitCodes>", textes[p]))
        n2 = len(re.findall(r"<Basic>", textes[p]))
        print("%s : %d lignes ExitCodes, %d carrieres de base" % (p.name, n1, n2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

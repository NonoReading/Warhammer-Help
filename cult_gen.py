#!/usr/bin/env python3
"""Ajoute un culte a DATA_CULT_V1 de BOOK_REALM_OF_DIVINE_MAGIC.Xml a partir d un fichier texte.

Usage : python cult_gen.py cultes_src/MANANN.txt
Format du fichier :
  id: MANANN
  deity: RULES-DEITY_MANANN
  title: Manann Cult
  page: 196
  INITIATE R: Bless Token, Blessed Sacraments, ...     (R = Required, H = Honors)
  INITIATE H: ...
  1 R: ...   1 H: ...   2 R: ... jusqu a 4
  gift 1: texte du don
  gift MARINER: texte du don
Les noms de prieres sont resolus d apres les Description du livre (parentheses ignorees :
« Summon Least (Water) Elemental » = Summon Least Elemental). Un nom introuvable arrete le script.
"""

import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape

RACINE = Path(__file__).resolve().parent
LIVRE = RACINE / "DATABASE" / "WFRP1" / "BOOK_REALM_OF_DIVINE_MAGIC.Xml"

ALIAS = {
    "knowenemy": "knowenemies",
    "knowfollowers": "knowfollower",
    "mastershand": "thetouchofthemastershand",
    "themastershand": "thetouchofthemastershand",
    "selfdefence": "selfdefense",
    "lightofdaydarknessofnight": "lightofdaydarknessofnight",
    "radiantarmor": "radiantarmordarklingarmor",
    "darklingarmor": "radiantarmordarklingarmor",
    "summongreaterelementals": "summongreaterelemental",
    "shelterofelementals": "shelteragainstelementals",
    "banishdivinealtar": "banishdivineavatar",
    "summonlesserelementals": "summonlesserelemental",
    "blesssacraments": "blessedsacraments",
    "identifydivineinstruments": "identifydivineinstrument",
    "summonavatar": "summondivineavatar",
    "speakwithdepartedfaithful": "speakwiththedepartedfaithful",
    "summonskeletalwarrior": "summonskeletalwarriorofkhaine",
    "summonskeletalwarband": "summonskeletalwarbandofkhaine",
    "summonmarshlight": "summonmarshlightofkhaine",
    "summonghost": "summonghostofkhaine",
    "summonwraith": "summonwraithofkhaine",
    "summonspecter": "summonspecterofkhaine",
    "divinewisdom": "divinevision",  # « Divine Wisdom » n existe qu a la liste d Ormazd : coquille du livre
    "scourgetheenemy": "scourgeenemy",
    "evademagicalalarm": "evademagicalarm",
    "greatsacramentofprayer": "grantsacramentofprayer",
    "contactsoulofhefaithful": "contactsoulofthefaithful",
    "contactsoulofthefaithful": "contactsoulofthefaithful",
    "contactsoulooffaithful": "contactsoulofthefaithful",
    "contactsouloffaithful": "contactsoulofthefaithful",
}


def norm(nom):
    nom = re.sub(r"\([^)]*\)", "", nom).lower()
    nom = re.sub(r"[^a-z]", "", nom)
    return ALIAS.get(nom, nom)


def charger_prieres(texte):
    prieres = {}
    for m in re.finditer(r'<SpellV1 id="([^"]+)">\s*<Description language="ENGLISH">"([^"]+)"', texte):
        prieres[norm(m.group(2))] = m.group(1)
        # variantes « A / B » : chaque moitie est aussi un nom valide
        for part in m.group(2).split("/"):
            prieres.setdefault(norm(part), m.group(1))
    return prieres


def main():
    src = Path(sys.argv[1]).read_text(encoding="utf-8")
    with LIVRE.open(encoding="utf-8", newline="") as f:
        texte = f.read()
    eol = "\r\n" if "\r\n" in texte else "\n"
    prieres = charger_prieres(texte)
    champs, lignes_p, dons = {}, [], []
    erreurs = []
    for ligne in src.splitlines():
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#"):
            continue
        cle, _, val = ligne.partition(":")
        cle, val = cle.strip(), val.strip()
        mg = re.match(r"gift (.+)", cle, re.I)
        mp = re.match(r"(INITIATE|[1-4]) ([RH])$", cle)
        if mg:
            dons.append((mg.group(1).upper(), val))
        elif mp:
            kind = "REQUIRED" if mp.group(2) == "R" else "HONOR"
            for nom in val.split(","):
                nom = nom.strip()
                if not nom:
                    continue
                pid = prieres.get(norm(nom))
                if pid is None:
                    erreurs.append(f"{cle} : priere inconnue « {nom} »")
                else:
                    lignes_p.append((mp.group(1), kind, pid))
        else:
            champs[cle] = val
    if erreurs:
        print("\n".join(erreurs))
        sys.exit(1)
    cid = "WRDM-CULT_" + champs["id"]
    if f'id="{cid}"' in texte:
        print("culte deja present :", cid)
        sys.exit(1)
    out = [f'<Cult id="{cid}">',
           f'<Description language="ENGLISH">"{escape(champs["title"])}"</Description>']
    if champs.get("deity"):  # absent quand la divinite n est pas dans le livre de base
        out.append(f'<Deity>"{champs["deity"]}"</Deity>')
    for rang, kind, pid in lignes_p:
        out.append(f'<Prayer><Rank>"{rang}"</Rank><Kind>"{kind}"</Kind><Value>"{pid}"</Value></Prayer>')
    for rang, txt in dons:
        out.append(f'<Gift><Rank>"{rang}"</Rank><Text language="ENGLISH">"{escape(txt)}"</Text></Gift>')
    out.append(f'<Page>"{champs["page"]}"</Page>')
    out.append("</Cult>")
    texte = texte.replace("</DATA_CULT_V1>", eol.join(out) + eol + "</DATA_CULT_V1>")
    with LIVRE.open("w", encoding="utf-8", newline="") as f:
        f.write(texte)
    print(f"{cid} ajoute : {len(lignes_p)} prieres, {len(dons)} dons")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Relie les sorts V2 du Rulebook (WFRP2) aux talents Arcane/Dark/Divine Lore.

Pour chaque <SpellV2> dont le champ <Lore> est une lore de talent (Beasts, Fire,
Chaos, Sigmar...), ecrit un bloc DATA_SPELL_TALENT : acheter le talent
"Arcane Lore (Fire)" accorde alors tous les sorts de la Lore of Fire
(SpellMode AUTO, lu par SortAffiche dans winpersonnage.pas).

Petty Magic (Arcane / Divine / Hedge) accorde tous les sorts de son type ; Lesser Magic
(un talent par sort) accorde le sort du meme nom (25/10/2026).
Relancable : le bloc existant est remplace, jamais duplique.

Usage : python lier_sorts_talents_v2.py
"""
import glob
import re
import sys

FICHIER = r"DATABASE\WFRP2\BOOK_RULESBOOK.Xml"

LORES = {
    "Lore of Beasts": "RULES-T_ARCANE_LORE__BEASTS",
    "Lore of Death": "RULES-T_ARCANE_LORE__DEATH",
    "Lore of Fire": "RULES-T_ARCANE_LORE__FIRE",
    "Lore of The Heavens": "RULES-T_ARCANE_LORE__HEAVENS",
    "Lore of Life": "RULES-T_ARCANE_LORE__LIFE",
    "Lore of Light": "RULES-T_ARCANE_LORE__LIGHT",
    "Lore of Metal": "RULES-T_ARCANE_LORE__METAL",
    "Lore of Shadow": "RULES-T_ARCANE_LORE__SHADOW",
    "Lore of Chaos": "RULES-T_DARK_LORE__CHAOS",
    "Lore of Necromancy": "RULES-T_DARK_LORE__NECROMANCY",
    "Lore of Manann": "RULES-T_DIVINE_LORE__MANANN",
    "Lore of Morr": "RULES-T_DIVINE_LORE__MORR",
    "Lore of Myrmidia": "RULES-T_DIVINE_LORE__MYRMIDIA",
    "Lore of Ranald": "RULES-T_DIVINE_LORE__RANALD",
    "Lore of Shallya": "RULES-T_DIVINE_LORE__SHALLYA",
    "Lore of Sigmar": "RULES-T_DIVINE_LORE__SIGMAR",
    "Lore of Taal And Rhya": "RULES-T_DIVINE_LORE__TAAL_RHYA",
    "Lore of Ulric": "RULES-T_DIVINE_LORE__ULRIC",
    "Lore of Verena": "RULES-T_DIVINE_LORE__VERENA",
    "Petty Magic (Arcane)": "RULES-T_PETTY_MAGIC__ARCANE",
    "Petty Magic (Divine)": "RULES-T_PETTY_MAGIC__DIVINE",
    "Petty Magic (Hedge)": "RULES-T_PETTY_MAGIC__HEDGE",
}

# Lesser Magic : un talent par sort, RULES-SPEL_X -> RULES-T_LESSER_MAGIC__X.
LORE_LESSER = "Lesser Magic"


LORES.update({
    "Lore of Nurgle": "RULES-T_DARK_LORE__NURGLE",
    "Lore of Slaanesh": "RULES-T_DARK_LORE__SLAANESH",
    "Lore of Tzeentch": "RULES-T_DARK_LORE__TZEENTCH",
    "Lore of Plague": "RULES-T_DARK_LORE__PLAGUE",
    "Lore of Stealth": "RULES-T_DARK_LORE__STEALTH",
    "Lore of Warp": "RULES-T_DARK_LORE__WARP",
    "Lore of Hashut": "RULES-T_DARK_LORE__CHAOS_DWARF",
    "Lore of Spirits": "RULES-T_DIVINE_LORE__SPIRITS",
    "Petty Magic (Warp)": "RULES-T_PETTY_MAGIC__WARP",
    "Petty Magic (Chaos)": "RULES-T_PETTY_MAGIC__CHAOS",
    "Petty Magic (Elemental)": "RULES-T_PETTY_MAGIC__ELEMENTAL",
    "Witch Lore (Hedge)": "SOE-T_WITCH_LORE__HEDGE",
    # Talents crees par creer_talents_lores_v2.py
    "Lore of Illusione": "RULES-T_ARCANE_LORE__ILLUSIONE",
    "Witch Lore (Hag)": "RULES-T_WITCH_LORE__HAG",
    "Witch Lore (Ice)": "RULES-T_WITCH_LORE__ICE",
    "Petty Magic (Hag)": "RULES-T_PETTY_MAGIC__HAG",
    "Petty Magic (Ice)": "RULES-T_PETTY_MAGIC__ICE",
    "Lore of Dazh": "RULES-T_DIVINE_LORE__DAZH",
    "Lore of Tor": "RULES-T_DIVINE_LORE__TOR",
    "Lore of Ursun": "RULES-T_DIVINE_LORE__URSUN",
    "Lore of Gunndred": "RULES-T_DIVINE_LORE__GUNNDRED",
    "Lore of Handrich": "RULES-T_DIVINE_LORE__HANDRICH",
    "Lore of Khaine": "RULES-T_DIVINE_LORE__KHAINE",
})
LORES["Lore of Taal and Rhya"] = LORES["Lore of Taal And Rhya"]
for _nom in ("Beasts", "Death", "Fire", "Heavens", "Life", "Light", "Metal", "Shadow"):
    LORES["Arcane Lore (%s)" % _nom] = "RULES-T_ARCANE_LORE__" + _nom.upper()


def autres_livres():
    """Ajoute, dans les autres livres V2, les sorts des lores connues non encore relies.

    Les blocs ecrits par d'autres scripts (Araby, Druids...) sont conserves tels quels.
    """
    total = 0
    for chemin in sorted(glob.glob(r"DATABASE\WFRP2\BOOK_*.Xml")):
        if chemin.endswith("BOOK_RULESBOOK.Xml"):
            continue
        with open(chemin, encoding="utf-8", newline="") as f:
            texte = f.read()
        if "<DATA_SPELL_V2>" not in texte:
            continue
        debut = texte.index("<DATA_SPELL_V2>")
        fin = texte.index("</DATA_SPELL_V2>") + len("</DATA_SPELL_V2>")
        ancien = re.search(r"<DATA_SPELL_TALENT>(.*?)</DATA_SPELL_TALENT>", texte, re.S)
        deja = set(re.findall(r'<Sort id="([^"]+)"', ancien.group(1))) if ancien else set()
        neuf = []
        for m in re.finditer(r'<SpellV2 id="([^"]+)">(.*?)</SpellV2>', texte[debut:fin], re.S):
            lore = re.search(r'<Lore>"([^"]*)"</Lore>', m.group(2))
            talent = LORES.get(lore.group(1)) if lore else None
            if talent and m.group(1) not in deja:
                neuf.append('<Sort id="%s">\n<Talent>"%s"</Talent>\n</Sort>' % (m.group(1), talent))
        if not neuf:
            continue
        eol = "\r\n" if "\r\n" in texte else "\n"
        ajout = "\n".join(neuf).replace("\n", eol)
        if ancien:
            pos = ancien.end() - len("</DATA_SPELL_TALENT>")
            texte = texte[:pos] + ajout + eol + texte[pos:]
        else:
            texte = (texte[:fin] + eol + "<DATA_SPELL_TALENT>" + eol + ajout + eol
                     + "</DATA_SPELL_TALENT>" + texte[fin:])
        with open(chemin, "w", encoding="utf-8", newline="") as f:
            f.write(texte)
        print("%s : %d sorts ajoutes" % (chemin, len(neuf)))
        total += len(neuf)
    print("autres livres : %d sorts relies" % total)


def main():
    with open(FICHIER, encoding="utf-8", newline="") as f:
        texte = f.read()

    debut = texte.index("<DATA_SPELL_V2>")
    fin = texte.index("</DATA_SPELL_V2>") + len("</DATA_SPELL_V2>")
    bloc_sorts = texte[debut:fin]

    lignes = []
    inconnus = set()
    for m in re.finditer(r'<SpellV2 id="([^"]+)">(.*?)</SpellV2>', bloc_sorts, re.S):
        code, corps = m.group(1), m.group(2)
        lore = re.search(r'<Lore>"([^"]*)"</Lore>', corps)
        if not lore:
            continue
        talent = LORES.get(lore.group(1))
        if lore.group(1) == LORE_LESSER:
            talent = code.replace("RULES-SPEL_", "RULES-T_LESSER_MAGIC__")
        if talent is None:
            inconnus.add(lore.group(1))
            continue
        lignes.append('<Sort id="%s">\n<Talent>"%s"</Talent>\n</Sort>' % (code, talent))

    nouveau = "<DATA_SPELL_TALENT>\n" + "\n".join(lignes) + "\n</DATA_SPELL_TALENT>"

    # Remplace un bloc deja ecrit par ce script, sinon l'insere juste apres DATA_SPELL_V2.
    ancien = re.search(r"\n?<DATA_SPELL_TALENT>.*?</DATA_SPELL_TALENT>", texte, re.S)
    if ancien:
        texte = texte[:ancien.start()] + "\n" + nouveau + texte[ancien.end():]
    else:
        texte = texte[:fin] + "\n" + nouveau + texte[fin:]

    with open(FICHIER, "w", encoding="utf-8", newline="") as f:
        f.write(texte)

    print("%d sorts relies" % len(lignes))
    print("lores ignorees (voulu) :", ", ".join(sorted(inconnus)) or "aucune")
    autres_livres()


if __name__ == "__main__":
    sys.exit(main())

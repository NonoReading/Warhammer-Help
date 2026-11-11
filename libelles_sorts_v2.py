#!/usr/bin/env python3
"""Libelles EN/FR des domaines de magie V2 (WinSorts : colonne Type des sorts DATA_SPELL_V2).

Le type d un sort V2 est le code RULES-SPELLV2_<LORE EN MAJUSCULES> (meme regle que CodeLibelleV2 dans
xmlexportimport.pas, LitSortsV2Noeud). Le Lore vient de la balise <Lore> du livre : Rulebook et Realms of Sorcery.

Usage : python libelles_sorts_v2.py   (idempotent : remplace les lignes deja ecrites)
"""
import extraire_armes_v2 as ea

LORES = {
    "Petty Magic (Arcane)": "Magie mineure (arcanique)",
    "Petty Magic (Divine)": "Magie mineure (divine)",
    "Petty Magic (Hedge)": "Magie mineure (sorcier de village)",
    "Lesser Magic": "Magie inférieure",
    "Lore of Beasts": "Domaine des Bêtes",
    "Lore of Death": "Domaine de la Mort",
    "Lore of Fire": "Domaine du Feu",
    "Lore of The Heavens": "Domaine des Cieux",
    "Lore of Life": "Domaine de la Vie",
    "Lore of Light": "Domaine de la Lumière",
    "Lore of Metal": "Domaine du Métal",
    "Lore of Shadow": "Domaine de l'Ombre",
    "Rituals": "Rituels",
    "Lore of Chaos": "Domaine du Chaos",
    "Lore of Necromancy": "Domaine de la Nécromancie",
    "Lore of Manann": "Domaine de Manann",
    "Lore of Morr": "Domaine de Morr",
    "Lore of Myrmidia": "Domaine de Myrmidia",
    "Lore of Ranald": "Domaine de Ranald",
    "Lore of Handrich": "Domaine de Handrich",
    "Lore of Shallya": "Domaine de Shallya",
    "Lore of Sigmar": "Domaine de Sigmar",
    "Lore of Taal And Rhya": "Domaine de Taal et Rhya",
    "Lore of Ulric": "Domaine d'Ulric",
    "Lore of Verena": "Domaine de Verena",
    # livres de fans (audit_libelles_sorts_v2.py liste ce qui manque)
    "Arcane Lore": "Domaine arcanique",
    "Astral Magic": "Magie astrale",
    "Lore of Athel Loren": "Domaine d'Athel Loren",
    "Lore of Esmeralda": "Domaine d'Esmeralda",
    "Lore of Gork": "Domaine de Gork",
    "Lore of Grimnir": "Domaine de Grimnir",
    "Lore of Grungni": "Domaine de Grungni",
    "Lore of Hashut": "Domaine de Hashut",
    "Lore of Azyata": "Domaine d'Azyata",
    "Lore of Ormazd": "Domaine d'Ormazd",
    "Lore of Sand": "Domaine du sable",
    "Lore of Hedge": "Domaine du sorcier de village",
    "Lore of Hoeth": "Domaine de Hoeth",
    "Lore of Illusione": "Domaine de l'Illusione",
    "Lore of Isha": "Domaine d'Isha",
    "Lore of Khakkekk": "Domaine de Khakkekk",
    "Lore of Liadriel": "Domaine de Liadriel",
    "Lore of Mork": "Domaine de Mork",
    "Lore of Solkan": "Domaine de Solkan",
    "Lore of the Horned Rat": "Domaine du Rat Cornu",
    "Lore of the Ifrit": "Domaine des Ifrits",
    "Lore of the Jann": "Domaine des Jann",
    "Lore of the Marid": "Domaine des Marids",
    "Lore of the Wilds": "Domaine des Étendues sauvages",
    "Mirth and Mayhem": "Joie et Désordre",
    "Petty Magic (Blood)": "Magie mineure (sang)",
    "Petty Magic (Divine, Myrmidia)": "Magie mineure (divine, Myrmidia)",
    "Petty Magic (Sand)": "Magie mineure (sable)",
    "Petty Magic (Divine, Taal)": "Magie mineure (divine, Taal)",
    "Petty Magic (Elemental)": "Magie mineure (élémentaire)",
    "Elemental Magic": "Magie élémentaire",
    "Petty Magic (Djinn)": "Magie mineure (djinn)",
    "Petty Magic (Nagash)": "Magie mineure (Nagash)",
    "Petty Magic (Necromancy)": "Magie mineure (nécromancie)",
    "Common Magic": "Magie commune",
    "Petty Magic (Beasts)": "Magie mineure (Bêtes)",
    "Petty Magic (Death)": "Magie mineure (Mort)",
    "Petty Magic (Fire)": "Magie mineure (Feu)",
    "Petty Magic (Heavens)": "Magie mineure (Cieux)",
    "Petty Magic (Life)": "Magie mineure (Vie)",
    "Petty Magic (Light)": "Magie mineure (Lumière)",
    "Petty Magic (Metal)": "Magie mineure (Métal)",
    "Petty Magic (Shadow)": "Magie mineure (Ombre)",
    "Arcane Lore (Beasts)": "Savoir arcanique (Bêtes)",
    "Arcane Lore (Death)": "Savoir arcanique (Mort)",
    "Arcane Lore (Fire)": "Savoir arcanique (Feu)",
    "Arcane Lore (Heavens)": "Savoir arcanique (Cieux)",
    "Arcane Lore (Life)": "Savoir arcanique (Vie)",
    "Arcane Lore (Light)": "Savoir arcanique (Lumière)",
    "Arcane Lore (Metal)": "Savoir arcanique (Métal)",
    "Arcane Lore (Shadow)": "Savoir arcanique (Ombre)",
    "Petty Magic (Waaagh!)": "Magie mineure (Waaagh!)",
    "Waaagh! Lore (The Little Waaagh!)": "Savoir Waaagh! (le Petit Waaagh!)",
    "Waaagh! Lore (The Big Waaagh!)": "Savoir Waaagh! (le Grand Waaagh!)",
    "Way of the Body": "Voie du Corps",
    "Way of the Mind": "Voie de l'Esprit",
}


def main():
    en = ['<Text name="%s">"%s"</Text>' % (ea.code("RULES-SPELLV2_", k), k) for k in LORES]
    fr = ['<Text name="%s">"%s"</Text>' % (ea.code("RULES-SPELLV2_", k), v) for k, v in LORES.items()]
    en.append('<Text name="RULES-LAB_757">"Spell lists"</Text>')            # champ SpellLists (Realms of Sorcery)
    fr.append('<Text name="RULES-LAB_757">"Listes de sorts"</Text>')
    en.append('<Text name="RULES-LAB_781">"Cult"</Text>')                    # champ Cult (Tome of Salvation)
    fr.append('<Text name="RULES-LAB_781">"Culte"</Text>')
    for code, anglais, francais in (            # champs d un rituel (Realms of Sorcery)
            ("758", "Ritual type", "Type de rituel"), ("759", "Arcane language", "Langage arcanique"),
            ("760", "Magic (minimum)", "Magie (minimum)"), ("761", "XP cost", "Coût en PX"),
            ("762", "Conditions", "Conditions"), ("763", "Consequences", "Conséquences")):
        en.append('<Text name="RULES-LAB_%s">"%s"</Text>' % (code, anglais))
        fr.append('<Text name="RULES-LAB_%s">"%s"</Text>' % (code, francais))
    ea.ecrit_libelles(en, ea.INTERFACE["EN"])
    ea.ecrit_libelles(fr, ea.INTERFACE["FR"])
    print("%d libelles par langue" % len(en))


if __name__ == "__main__":
    main()

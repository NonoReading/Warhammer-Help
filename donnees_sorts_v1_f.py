"""Sorts V1, partie F : sorts du Necromancer (Core p.175-178, lus sur les images du PDF, PDF = page imprimee + 9).

Meme format que donnees_sorts_v1_a.py. Total Control : niveau laisse en blanc dans le livre, saisi niveau 4 (sous l intitule Level Four).
Les profils des squelettes champion / heros ne sont pas saisis ici (ils vont avec les creatures).
"""

NECROMANTIC = "Necromantic"

SORTS_F = [
    ("Destroy Undead", NECROMANTIC, "1", "2", "24 yards", "Instantaneous", "Dust from a grave, or water blessed by a cleric", "oui", "176",
     "Against a group of Skeletons, Zombies or Ethereal Undead within 24 yards: 1D6 of them crumble to dust (or vanish) unless each passes a Will Power test."),
    ("Hand of Death", NECROMANTIC, "1", "1 per touch", "Not applicable", "Until the Necromancer is wounded", "Part of a corpse's shroud", "",
     "176", "A touch (hit roll ignoring unarmed modifiers) automatically causes 1D6 Wounds regardless of Toughness or armour; each touch costs 1 more magic point; no weapon may be used; magical armour reduces the damage by its plus."),
    ("Summon Skeleton Champion", NECROMANTIC, "1", "4", "Not Applicable", "Until dawn the following day", "A skeleton, corpse, or enchanted skull", "", "176",
     "Summons a single Skeleton Champion (M4 WS35 BS27 S4 T3 W5 I30 A1, 18 for Dex / Ld / Int / Cl / WP) within 6 yards; it can lead a group of Undead within 24 yards and crumbles to dust at dawn."),
    ("Summon Skeletons", NECROMANTIC, "1", "4", "Not Applicable", "Until dawn the following day", "Corpses, skeletons or enchanted skull", "", "176",
     "Summons a group of D6 normal Skeletons within 6 yards of the summoner, or around the caster on a battlefield or burial site."),
    ("Zone of Life", NECROMANTIC, "1", "4", "Not Applicable", "1 hour per level", "A holy relic", "", "176",
     "A 12-yard Zone in which the caster may forbid any Undead (Ethereal included) to enter or to fire missiles or cast magic into it; the caster casts nothing else and does not meditate; Zones may not overlap."),

    ("Control Undead", NECROMANTIC, "2", "3", "48 yards", "Instantaneous", "A religious symbol or wood from a coffin", "oui", "176",
     "Against a group of Skeletons or Zombies within 48 yards: each one failing a Will Power test is taken over by the caster; no limit on number, one spell per group."),
    ("Extend Control", NECROMANTIC, "2", "3", "Not Applicable", "1 hour per level", "Brain of a magician", "", "177",
     "Extends the Necromancer's normal Undead control range from 24 to 48 yards."),
    ("Hand of Dust", NECROMANTIC, "2", "3 per touch", "Not Applicable", "Until caster is wounded", "The right hand of a hanged murderer", "", "177",
     "A touch (no weapon) automatically causes 2D6 Wounds regardless of Toughness or armour; each touch costs 3 more magic points; no Magic test; magical armour reduces the damage by its plus."),
    ("Stop Instability", NECROMANTIC, "2", "2", "48 yards", "Until next period of instability occurs", "A pint of blood", "", "177",
     "A group of Undead or ethereal creatures within 48 yards ignores its next instability, even if magically induced; one such spell per group."),
    ("Summon Skeleton Minor Hero", NECROMANTIC, "2", "8", "Not Applicable", "Until dawn the following day", "Corpse, skeleton or enchanted skull", "", "177",
     "Summons a single Skeleton Minor Hero (M4 WS45 BS37 S4 T4 W9 I40 A2, 28 for Dex / Ld / Int / Cl / WP) within 6 yards; it can lead an Undead unit and collapses to dust at sunrise."),

    ("Annihilate Undead", NECROMANTIC, "3", "12", "24 yards", "Instantaneous", "The flayed skin of a fresh corpse", "oui", "177",
     "All Undead, Ethereal included, within 24 yards must pass a Will Power test or be destroyed."),
    ("Life in Death", NECROMANTIC, "3", "10", "Personal", "1 hour per level", "A fresh human heart", "oui", "177",
     "If the caster is slain, his spirit (Move 6, invulnerable) may take over a living creature's body within 2D4 rounds (host tests Will Power to resist); the Necromancer keeps Ld, Int, Cl, WP, skills and magic points, the rest are the host's; he is destroyed if he finds no body."),
    ("Raise Dead", NECROMANTIC, "3", "12", "Around the caster", "Until dawn the following day", "A graveyard or burial site", "", "178",
     "Cast in a graveyard: raises one group of 6D6 Skeletons, 6D6 Zombies, 3D6 Ghouls or D6 Mummies, obeying the summoner until dismissed or sunrise."),
    ("Summon Skeleton Horde", NECROMANTIC, "3", "12", "Not Applicable", "Until dawn the following day", "Burial site or the enchanted finger bones of 6 skeletons", "", "178",
     "Summons a horde of 6D6 normal Skeletons in a single group within 6 yards."),

    ("Curse of Undead", NECROMANTIC, "4", "12", "48 yards", "Until creature is destroyed or dispelled", "The withered hand of a Liche", "oui", "178",
     "On a sentient humanoid under 10 feet within 48 yards that fails a Will Power test: it loses 1 Strength each round, and at zero becomes one of the Undead (Will Power, Dexterity and Fellowship 10, magic lost), to be controlled like a Skeleton."),
    ("Summon Skeleton Major Hero", NECROMANTIC, "4", "12", "Not Applicable", "Until dawn the following day", "The enchanted skull of a legendary hero", "", "178",
     "Summons a single Skeleton Major Hero (M4 WS55 BS47 S4 T4 W13 I50 A3, 28 for Dex / Ld / Int / Cl / WP) within 6 yards; it can lead an Undead unit."),
    ("Total Control", NECROMANTIC, "4", "12", "2400 yards", "Until dawn", "Essence of vampire", "", "178",
     "Extends the Necromancer's Undead control to a radius of 2400 yards until dawn of the following day."),
    ("Wind of Death", NECROMANTIC, "4", "35", "2800 yards", "Instant", "The enchanted dust from 5 mummies", "", "178",
     "A black wind over a 2,400-yard radius causes 2D6 Wounds regardless of Toughness and armour on every living creature it passes over, the caster included; no Magic test."),
]

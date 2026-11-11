"""Sorts V1, partie C : sorts du Demonologist (Core p.161-166, lus sur les images du PDF, PDF = page imprimee + 9).

Meme format que donnees_sorts_v1_a.py. Les regles d invocation (pentagramme, marchandage, invocations successives, effets
de pouvoir d invocation) ne sont pas des sorts : elles restent hors de ce fichier.
Les sorts de pouvoir d invocation (Summon Energy, Great Power, Total Power, Magical Aid) donnent un handicap a l apprentissage
et 1 point de folie par lancement : regles notees dans l effet.
"""

DEMONIC = "Demonic"

SORTS_C = [
    ("Bind Demon", DEMONIC, "1", "3", "48 yards", "6 rounds", "The skull of a Chaos Warrior, bound with an iron circlet", "oui", "162",
     "Up to D6 Lesser Demons or Demonic Servants, or one Greater Demon, fail a Will Power test and are held in complete stasis for the next game turn, counting as prone."),
    ("Dispel Lesser Demon", DEMONIC, "1", "1", "24 yards", "Instantaneous", "A religious symbol of good or law, blessed by a cleric of the same religion", "oui", "162",
     "Dispels a single Lesser Demon within 24 yards back to its own plane unless it passes a Will Power test."),
    ("Summon Guardian", DEMONIC, "1", "3", "Not applicable", "1 hour per level", "The heart of a Human or Demi-Human, ritually sacrificed", "", "162",
     "Summons a single Lesser Demon within 6 yards, serving 1 hour per level if controlled; requires a previous summoning and bargain; one at a time."),
    ("Summon Steed", DEMONIC, "1", "1", "Not applicable", "2 hours per level", "A piece from the thigh bone of a Chaos Beastman", "", "162",
     "Summons a Demonic Steed (Demonic Servant profile), usually a Warhorse with flaming eyes and mouth; only as the result of a bargain with a Lesser or Greater Demon."),
    ("Zone of Demonic Protection", DEMONIC, "1", "2", "Personal", "1 hour per level", "A miniature pentagram made from solid gold (value 500 GC)", "", "162",
     "A 6-yard Zone in which the caster may forbid Demons to enter, fire missiles or cast or use magic; the caster casts nothing else and does not meditate; Zones may not overlap."),

    ("Stop Demonic Instability", DEMONIC, "2", "3", "48 yards", "Until next period of instability occurs", "The blood of a new-born child", "", "162",
     "A group of Lesser Demons or Demonic Servants, or one Greater Demon, is unaffected by its next period of instability; one such spell per group."),
    ("Summon Energy", DEMONIC, "2", "3", "Not applicable", "Variable", "Any magical potion, or the heart of a Demonologist", "oui", "162",
     "Summoning-power spell: on a successful Will Power test adds 4D6 magic points (not beyond the Power Level), but the caster then regains only 1 point per day; a failed test reduces all characteristics by 1 or 10 for D6 rounds and gives stupidity. A new Disability on learning, 1 Insanity point per casting."),
    ("Summon Lesser Demons", DEMONIC, "2", "5", "Not applicable", "1 hour per level", "Six Human or Demi-Human hearts, from ritually sacrificed victims", "", "163",
     "Summons a group of 3D6 Lesser Demons within 6 yards, one Will Power control check each; only if one of them was previously summoned, controlled and bargained with."),
    ("Summon Magical Aid", DEMONIC, "2", "4", "Varies", "Until the next sunrise", "Any magical scroll, or the heart of a Demonic Servant", "oui", "163",
     "On a successful Will Power test, one Battle Magic or Demonic spell of the caster's own level or lower can be learned temporarily and cast once. A new Disability on learning, 1 Insanity point per casting."),
    ("Zone of Demonic Nullification", DEMONIC, "2", "5", "Not applicable", "1 hour per level", "The blood of any Demon", "", "163",
     "A 6-yard Zone in which any Demon becomes unstable and disappears; the caster may bar Demons from firing missiles or magic into it; the caster casts nothing else and does not meditate."),

    ("Dispel Demon Horde", DEMONIC, "3", "10", "48 yards", "Instantaneous", "1 pint of ichor from any Greater Demon", "oui", "165",
     "Dispels a whole group of Lesser Demons within 48 yards; each Demon failing a Will Power test returns to its own plane."),
    ("Spread Insanity", DEMONIC, "3", "8", "24 yards", "10D6 rounds", "The brain of a lunatic", "oui", "165",
     "Every creature within 24 yards makes a Will Power test, then a Leadership test; those failing flee for at least 10D6 game turns. A new Disability on learning, 1 Insanity point per casting."),
    ("Summon Demon Horde", DEMONIC, "3", "8", "Not applicable", "1 hour per level", "36 Human or Demi-Human hearts, ritually sacrificed", "", "165",
     "Summons a group of 6D6 Lesser Demons within 6 yards, one Will Power control check each; only if one of them was previously summoned, controlled and bargained with."),
    ("Summon Great Power", DEMONIC, "3", "6", "Not applicable", "6D6 rounds", "The heart of a Lesser Demon", "oui", "165",
     "Summoning-power spell: on a successful Will Power test all the caster's characteristics rise by +1 or +10, above normal maxima, for 6D6 combat rounds; a failure reduces them by 1 or 10 for D6 rounds and gives stupidity. A new Disability on learning, 1 Insanity point per casting."),

    ("Demonic Portal", DEMONIC, "4", "20", "48 yards", "10D6 turns", "Any magical ring", "", "165",
     "Opens a portal releasing 6D6 uncontrolled Lesser Demons and one Greater Demon at the start of every game turn, hostile to the caster too; the remaining Demons become unstable and vanish when it closes."),
    ("Dispel Greater Demon", DEMONIC, "4", "25", "24 yards", "Instantaneous", "Part of the body of a cleric of Good alignment", "oui", "165",
     "Dispels a single Greater Demon within 24 yards back to its own plane unless it passes a Will Power test."),
    ("Summon Greater Demon", DEMONIC, "4", "25", "Not applicable", "Until task completed", "The pure heart of a Good cleric, slain in ritual sacrifice", "", "166",
     "Summons a single Greater Demon within 6 yards, only if it was previously summoned, controlled and bargained with; it stays until one task is completed, it is dispelled, or it or the summoner is slain."),
    ("Summon Total Power", DEMONIC, "4", "40", "Not applicable", "Until the next sunrise", "The heart of a Greater Demon", "oui", "166",
     "Summoning-power spell: on a successful Will Power test all characteristics rise by +2 or +20 and magic points by 10D6 (above the Power Level) until daybreak, and the spell cannot be cast again for as many days as points gained; a failure reduces them by 2 or 20% for D6 x 10 game turns. A new Disability on learning, 1 Insanity point per casting."),
]

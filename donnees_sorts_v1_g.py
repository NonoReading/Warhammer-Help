"""Sorts V1, partie G : sorts du Druidic Priest (Core p.180-181, PDF = page imprimee + 9) et sorts propres a certains cultes
(Core p.199-201 : Ranald et Shallya, lus sur le texte OCR de la section Religion and Belief).

Meme format que donnees_sorts_v1_a.py. Les sorts de culte sont dans la liste « Clerical » (sorts reserves aux Clerics du culte
cite dans l effet) ; les quatre de Shallya sont des sorts de specialiste.
"""

DRUIDIC = "Druidic"
CLERICAL = "Clerical"

SORTS_G = [
    ("Animal Mastery", DRUIDIC, "1", "1 per turn", "6 yards", "1+ turns", "A tooth from any animal", "oui", "180",
     "Telepathic contact with any non-fantastic animal of low intelligence (6-14) within 6 yards: the caster communicates and may command it (Will Power test for the animal if the order is dangerous or unnatural); extendable."),
    ("Cure Poison", DRUIDIC, "1", "1", "Touch", "Instantaneous", "Powdered malachite", "", "180",
     "Negates the effect of one poisoned wound or dose of poison on the caster or a touched creature, if cast within one hour of the poisoning."),
    ("Delouse", DRUIDIC, "1", "1", "Touch", "Instantaneous", "A pinch of pepper", "", "180",
     "Removes parasitic infestations of all kinds from one creature touched."),
    ("Heal Animal", DRUIDIC, "1", "1", "Touch", "Instantaneous", "A sprig of mistletoe", "", "180",
     "Restores one non-fantastic, non-giant animal to full health (wounds, poisons, disease); not the dead, not the effects of critical hits."),

    ("Giant Animal Mastery", DRUIDIC, "2", "2 per turn", "12 yards", "1+ turns", "A tooth of a giant animal", "oui", "180",
     "As Animal Mastery, against non-fantastic giant animals (giant rats, giant spiders...), who may test Will Power to resist."),
    ("Hail Storm", DRUIDIC, "2", "4 per round", "48 yards", "1+ rounds", "A handful of white quartz gravel", "", "180",
     "A violent hailstorm even underground: anyone caught takes D6 Wounds at Strength 0 each round and must pass a Cool test to attack; firm surfaces become difficult ground, visibility 10 yards, no missile fire, fire damage reduced by 2D4, fire-based magic dispelled."),
    ("Shapechange", DRUIDIC, "2", "12 plus 2 per turn", "Personal", "1+ turns", "The skin of the animal to be changed into", "", "180",
     "The caster takes the form of any non-fantastic, non-giant animal, gaining its characteristics (not Intelligence) and abilities, but casting nothing; reverts if rendered unconscious; 12 points for the first turn, 2 per further turn."),
    ("Tanglethorn", DRUIDIC, "2", "2 per turn", "24 yards", "1+ turns", "A briar or bramble", "", "180",
     "Plants in an area of up to four square yards per level partially animate: creatures make a Strength test each round or count as prone, and take 2D6 Wounds at Strength 0 per round (location rolled, Toughness and armour apply)."),

    ("Animate Tree", DRUIDIC, "3", "10 plus 4 per round", "Touch", "1+ turns", "A seed or berry from the type of tree to be animated", "", "181",
     "Animates one tree as a Treeman under the caster's control (Bestiary); the caster must keep concentration (Will Power check if hit); 10 magic points for 1 turn, 4 per further round."),
    ("Decompose", DRUIDIC, "3", "6", "48 yards", "Instantaneous", "A dried leaf", "oui", "181",
     "A ray of dark green light up to 48 yards makes anything organic in its path (wood, leather, clothing) rot to dust; characters' or monsters' clothing and armour may test Will Power; Zombies struck become Skeletons; nothing living is affected."),
    ("Tap Earthpower", DRUIDIC, "3", "3", "Personal", "Variable", "A stone circle", "", "181",
     "Only inside a stone circle: the caster regains D4 magic points per round, up to the Power Level, for as long as he stays in the circle."),
    ("Zone of Purity", DRUIDIC, "3", "3", "Personal", "1 hour", "A bronze dagger", "", "181",
     "A 12-yard Zone: Druidic Priests and normal animals enter and leave freely, everything else must pass a Will Power test or be excluded, with a modifier of 0% for Elves and giant animals and Rangers, -10% Humans and Halflings, -20% Dwarfs, -40% everything else."),

    ("Create Bog", DRUIDIC, "4", "6", "48 yards", "3 turns", "A ball of mud", "", "181",
     "Out of doors on bare ground only: up to 48 square yards of soft marsh counting as difficult ground for 3 turns; creatures in it when it hardens are trapped unless they pass a Strength test, counting as prone."),
    ("Create Sacred Grove", DRUIDIC, "4", "4 per day", "None", "Variable", "A suitable location and a golden sickle", "", "181",
     "Creates or re-dedicates a Sacred Grove, or a desecrated stone circle; the area is first marked with Zone of Purity, then dedication rites run from the full moon for a full lunar month."),

    ("Evade Magic Alarm", CLERICAL, "1", "3", "1 yard", "See below", "None", "", "199",
     "Cleric of Ranald only: makes a Magic Alarm spell inactive for a number of game turns equal to the caster's Will Power."),
    ("Pick Magic Lock", CLERICAL, "1", "4", "1 yard", "See below", "None", "", "199",
     "Cleric of Ranald only: makes a Magic Lock spell inactive for a number of game turns equal to the caster's Will Power, during which the lock can be picked."),
    ("Cure Poison", CLERICAL, "1", "4", "Touch", "Permanent", "None", "", "200",
     "Cleric of Shallya only: negates the effect of one dose of any poison on a character touched."),
    ("Treat Illness", CLERICAL, "2", "4", "Touch", "Permanent", "None", "", "200",
     "Cleric of Shallya only: the recipient makes a Disease test with a bonus equal to the caster's Will Power; if successful the disease breaks and recovery begins."),
    ("Cure Insanity", CLERICAL, "3", "6", "Touch", "Permanent", "None", "oui", "200",
     "Cleric of Shallya only: the recipient tests Magic; on a failure the spell takes effect and a Cool test with a bonus equal to the caster's Will Power removes one disorder."),
    ("Heal Injury", CLERICAL, "3", "8", "Touch", "Permanent", "None", "", "200",
     "Cleric of Shallya only: a Toughness test with a bonus equal to the caster's Will Power restores one body location incapacitated by a critical hit; does not replace severed limbs."),
]

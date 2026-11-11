"""Sorts V1, partie E : sorts de l Illusionist (Core p.171-175, lus sur les images du PDF, PDF = page imprimee + 9).

Meme format que donnees_sorts_v1_a.py. Banish Illusion est imprime « Spell Level: 1 » sous l intitule Level Two :
saisi niveau 2 (le texte de Verena le donne niveau 2).
"""

ILLUSION = "Illusion"

SORTS_E = [
    ("Assume Illusionary Appearance", ILLUSION, "1", "1 per 5D6 minutes", "Personal", "5 to 30 minutes", "A mask of the creature or person to be impersonated", "",
     "172", "The caster looks like any other living bipedal creature under 10 feet tall, or a specific individual; Intelligence test to see through it; renewable with more magic points."),
    ("Bewilder Foe", ILLUSION, "1", "4", "24 yards", "1 round", "A small firework", "oui", "172",
     "Not an illusion: a single target within 24 yards that fails a Magic test is bewildered for a round, moving at half speed in a random direction, unable to attack or parry, counting as prone; its magic and concentration end."),
    ("Camouflage Illusion", ILLUSION, "1", "2", "Personal", "1 hour per level", "Silvered mirror", "", "172",
     "The caster appears 2 yards from the real position: a very difficult target, attackers -10 WS and BS; a viewer may test Intelligence when the caster moves."),
    ("Cloak Activity", ILLUSION, "1", "1 per 2D6 rounds", "Personal", "2 to 12 rounds", "A piece of woollen fleece", "", "172",
     "The caster performs any act while appearing to do something innocent; a victim struck sees nothing but may test Intelligence; can filch items from a table unseen (a watcher may test at half chance, a victim of a theft on the person tests normally)."),
    ("Clone Image", ILLUSION, "1", "2 per image", "Personal", "1 hour per level", "Small mannikins of the caster", "", "172",
     "Up to one clone image per level, each staying within 2 yards of the caster and moving individually; only one is the real Illusionist; the group counts as a single illusion."),

    ("Banish Illusion", ILLUSION, "2", "3", "48 yards", "Instantaneous", "A magnifying glass", "", "172",
     "Base 50% to destroy a target illusion, +10% per level the caster exceeds the illusion's caster, -5% per level the illusion's caster exceeds the caster."),
    ("Confound Foe", ILLUSION, "2", "8", "Personal", "Instant", "An hour-glass with crushed diamonds instead of sand (value 100 GC)", "", "173",
     "Cast by an Illusionist who suffered damage that round, even if the caster has been killed: negates all combat damage sustained during that round."),
    ("Ghostly Appearance", ILLUSION, "2", "3 per 5D6 turns", "Personal", "5 to 30 minutes", "The shroud from an Undead creature", "", "173",
     "The caster looks like any Undead creature or a specific one and causes the same psychological reactions, but can still cast spells; Intelligence test to see through it; renewable."),
    ("Hallucinate", ILLUSION, "2", "4", "48 yards", "Instantaneous", "A piece of clay worked into a model of the desired creature", "oui", "173",
     "A group or individual failing a Will Power test sees itself charged by a creature of the caster's choice and makes the resulting psychological tests; if they succeed, the illusion is dispelled."),
    ("Illusionary Buildings", ILLUSION, "2", "2 per building section", "1,200 yards", "Until the caster moves", "Small models of buildings", "", "173",
     "Creates the appearance of a village or farmstead anywhere within 1,200 yards, 2 magic points per 8 x 8 yard section; viewers within 24 yards may test Intelligence."),
    ("Illusionary Woods", ILLUSION, "2", "5 per 12 x 12 yard section", "1,200 yards", "Until the caster moves", "Small model trees", "", "173",
     "Creates the appearance of a wood within 1,200 yards, hiding creatures inside from view while they see out normally; viewers within 24 yards may test Intelligence."),

    ("Illusionary Enemy", ILLUSION, "3", "6", "48 yards", "1 hour per level", "The teeth of a Chameleoleech", "", "173",
     "An illusion of up to 24 humanoids, or ten Undead, or a single monster or Lesser Demon, appearing within 48 yards and controlled by the caster, reproducing special abilities and psychological effects; Intelligence test to see through it."),
    ("Illusion of Mighty Appearance", ILLUSION, "3", "6 per 5D6 turns", "Personal", "5 to 30 minutes", "Mask", "", "174",
     "The caster assumes the appearance of any creature, reproducing its special abilities and psychological effects; Intelligence test to see through it; renewable."),
    ("Universal Confusion", ILLUSION, "3", "8", "Sight", "1 round", "The eyes of a Chimera", "", "174",
     "An individual or group in line of sight is completely disoriented from the next round, moving only at half pace aimlessly; missile fire -10 BS and -10 to hit in combat."),
    ("Vanish", ILLUSION, "3", "6", "Personal", "D6 rounds", "A golden hoop of at least 6\" diameter", "", "174",
     "The caster vanishes into another dimension for D6 rounds, doing nothing but seeing the place left behind; may return before expiry within 24 yards of the point; if it expires inside he is expelled 4D6 yards away (killed if inside a wall); all maintained Illusions are dispelled."),

    ("Destroy Illusions", ILLUSION, "4", "8", "1,200 yards", "Instant", "A crystal prism", "", "174",
     "All illusions within 1,200 yards, maintained by any character, including the caster, are instantly dispelled."),
    ("Illusionary Army", ILLUSION, "4", "12 per hour", "Sight", "1+ hours", "Small model figures of the troops desired by the caster", "", "174",
     "An illusion of 2D6 groups of up to 20 humanoid or Undead troops in sight, controlled and moved as if real; viewers may test Intelligence for each group."),
    ("Illusion of Darkness", ILLUSION, "4", "15", "96 yards", "2 hours", "A ball of pitch", "", "174",
     "A 24-yard circle of magical darkness anywhere within 96 yards, not lit by any light: creatures move at quarter pace in a random direction, missile fire and combat are impossible."),
    ("Teleport", ILLUSION, "4", "20", "Personal", "2D6 rounds", "A potion of flying or the hand of any Demon", "", "175",
     "Like Vanish: the caster may return to the scene or to any place within 100 miles already visited; at most three times a day; if it expires in the other dimension the caster is expelled 4D6 yards away; all maintained Illusions are dispelled."),
]

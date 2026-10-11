#!/usr/bin/env python3
"""Lance remplir_pages.py sur tous les livres (rapport, ou --ecrire). Table livre XML -> texte."""
import subprocess, sys
W4 = "DATABASE/WFRP4/"; W5 = "DATABASE/WFRP5/"; L = "LIVRES/"; P = "PDF_TEXTE/"
TABLE = [
 (W4+"BOOK_RULESBOOK.Xml", L+"RULEBOOK.txt"),
 (W5+"BOOK_RULESBOOK.Xml", L+"WFRP5_Core_Rulebook_01_09_26.txt"),
 (W4+"BOOK ARCHIVES OF THE EMPIRE I.Xml", L+"Archives_of_the_Empire_I.txt"),
 (W4+"BOOK_ARCHIVES_OF_THE_EMPIRE_II.Xml", L+"Archives_of_the_Empire_II.txt"),
 (W4+"BOOK_ARCHIVES_OF_THE_EMPIRE_III.Xml", L+"Archives_of_the_Empire_III.txt"),
 (W4+"BOOK ENEMY IN SHADOWS COMPANION.Xml", L+"Enemy_in_Shadows_Companion.txt"),
 (W4+"BOOK_DEATH_ON_THE_REIK_COMPANION.Xml", L+"Death_on_the_Reik_Companion.txt"),
 (W4+"BOOK THE HORNED RAT COMPANION.Xml", L+"The_Horned_Rat_Companion.txt"),
 (W4+"BOOK LUSTRIA.xml", L+"Lustria.txt"),
 (W4+"BOOK TRIBES AND TRIBULATIONS.Xml", P+"Tribes and Tribulations.txt"),
 (W4+"BOOK UNOFFICIAL GRIMOIRE.Xml", P+"Other help/Unofficial Grimoire 1.2 PDF.txt"),
 (W4+"BOOK_DEFT_STEPS_LIGHT_FINGERS.Xml", P+"Deft Steps Light Fingers.txt"),
 (W4+"BOOK_DWARF_PLAYERS_GUIDE.Xml", P+"Dwarf Player's Guide.txt"),
 (W4+"BOOK_GREEN_IZ_BEST.Xml", L+"Green_iz_Best.txt"),
 (W4+"BOOK_HIGH_ELF_PLAYERS_GUIDE.Xml", P+"High Elf Player's Guide.txt"),
 (W4+"BOOK_LORDS_OF_NAGGAROTH.Xml", L+"Lords_of_Naggaroth.txt"),
 (W4+"BOOK_MIDDENHEIM_CITY_OF_THE_WHITE_WOLF.Xml", L+"Middenheim_-_City_of_the_White_Wolf.txt"),
 (W4+"BOOK_NATIONS_OF_MANKIND.Xml", P+"Nations of Mankind.txt"),
 (W4+"BOOK_PARRAVONESE_STRIGANY_SIGNALLER.Xml", P+"Parravonese, Strigany, and Signaller Career.txt"),
 (W4+"BOOK_REIKLAND_MISCELLANEA.Xml", P+"Reikland Miscellanea.txt"),
 (W4+"BOOK_ROUGH_NIGHTS_AND_HARD_DAYS.Xml", L+"Rough_Nights_And_Hard_Days.txt"),
 (W4+"BOOK_SALZENMUND_CITY_OF_SALT_AND_SILVER.Xml", L+"Salzenmund.txt"),
 (W4+"BOOK_SEA_OF_CLAWS.Xml", L+"Sea_of_Claws.txt"),
 (W4+"BOOK_SEA_WARDENS_OF_COTHIQUE.Xml", P+"Sea Wardens of Cothique.txt"),
 (W4+"BOOK_SULLASARAS_SPELLS_OF_UNRIVALLED_UTILITY.Xml", P+"Sullasara's Spells of Unrivalled Utility.txt"),
 (W4+"BOOK_SYLVANIA_THE_CURSED_COUNTY.Xml", P+"Sylvania - The Cursed County.txt"),
 (W4+"BOOK_TEMPLE_OF_SPITE.Xml", P+"Temple of Spite.txt"),
 (W4+"BOOK_UP_IN_ARMS.Xml", L+"Up_In_Arms.txt"),
 (W4+"BOOK_WINDS_OF_MAGIC.Xml", L+"Winds_Of_Magic.txt"),
 (W4+"BOOK_WOOD_ELF_WARDANCER.Xml", P+"Fan/Wood Elf Wardancer Career 1.2.txt"),
]
for x, t, *lg in TABLE:
    r = subprocess.run([sys.executable, "remplir_pages.py", x, t] + (['--langue', lg[0]] if lg else []) + sys.argv[1:], capture_output=True, text=True, encoding="utf-8", errors="replace", env={**__import__("os").environ, "PYTHONIOENCODING": "utf-8"})
    sortie = r.stdout.splitlines()
    print(sortie[0] if sortie else (x + " : ERREUR " + r.stderr.strip()[-120:]))

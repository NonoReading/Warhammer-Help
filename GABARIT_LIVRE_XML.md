# Template for entering a new book (BOOK_*.Xml)

A technical reference for the XML structure of a book. Use it when you enter a new book, instead of
reopening an existing book to find the format again. The `.md` extension is deliberate (not
`.Xml`) so the program never loads this file as a book. The schemas (`SCHEMA_*.xsd`) carry the
per-block annotations; this guide gives the overview and the conventions.

## Required header of every BOOK_*.Xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<DATA_BOOK>
<CODE_BOOK>"XXXX"</CODE_BOOK>
<BOOK>"BOOK NAME IN CAPITALS WITHOUT PUNCTUATION"</BOOK>
<language>"ENGLISH"</language>
<VERSION>"WFRP4"</VERSION>
<OFFICIAL>"1"</OFFICIAL>       <!-- 1 = official Cubicle 7 book, 2 = fan / Community Content -->
<COMPLETE>"1"</COMPLETE>       <!-- 0 while the entry is not finished -->
<REVISION>"YYYYMMDD"</REVISION>  <!-- optional, written by WinLivre (Publish a revision); distinct from VERSION -->
<REVISION_LABEL>"Free text"</REVISION_LABEL>  <!-- optional, label typed at publication, right after REVISION -->
<DISCLAIMER>"..."</DISCLAIMER> <!-- DO NOT FORGET: copy the exact text of the copyright page of the
     source book (usually page 2: "No part of this publication may be reproduced..." +
     "(c) Copyright Games Workshop Limited [year]..."). An existing book without one is an
     omission to fix, not an example to follow. -->
<DATA_LABEL>
<Label language="ENGLISH">
<Text name="XXXX-BOOK BOOK NAME IN CAPITALS WITHOUT PUNCTUATION">"Displayed title"</Text>
</Label>
<Label language="FRANCAIS">
<Text name="XXXX-BOOK BOOK NAME IN CAPITALS WITHOUT PUNCTUATION">"Displayed title"</Text>
</Label>
</DATA_LABEL>
... DATA_* content blocks ...
</DATA_BOOK>
```

- `CODE_BOOK`: unique short prefix (4-6 letters), reused in front of every id (`XXXX-...`).
- The file name may contain underscores OR spaces (both exist in DATABASE/WFRP4); the value of
  `<BOOK>` must match exactly the entry added to `INI.TXT` (key `BOOKWFRP4=`, the `[BOOK ...]`
  list concatenated without a separator) for the book to be tickable in the menu.
- No apostrophe in `<BOOK>` / `CODE_BOOK` (no existing book has one).
- Every new book also carries `<BOOKNAME>` (display name without "BOOK", placed under `<BOOK>` in
  the header). `<BOOK>` stays the KEY used by characters, by INI and by `Text`; `BOOKNAME` is only
  a fallback shown when no translated label exists (menu book grid, WinLivre root).

## DATA_SPELL (spells)

```xml
<DATA_SPELL>
<Sort id="XXXX-CODE_01">
<Description language="ENGLISH">"Spell name"</Description>
<Explanation language="ENGLISH">"Full English text, inner quotation marks need no special escaping."</Explanation>
<Target>"1"</Target>                    <!-- or "You", "AoE (BATTR_WP)m", "AoE (ATTR_WP) miles" -->
<Duration>"Instant"</Duration>          <!-- or "(BATTR_WP) Rounds/minutes/hours", "(ATTR_WP) days", "Special" -->
<Range>"Touch"</Range>                  <!-- or "You", "(ATTR_WP)m" -->
<Talent>"RULES-T0088_XXX"</Talent>      <!-- Talent that gives access (Arcane Magic) or RULES-T0089 (Petty Magic) -->
<Level>"3"</Level>                      <!-- Casting Number (CN) from the book -->
<TypSpell>"Domain Magic"</TypSpell>     <!-- or "Minor Magic" for Petty Spells -->
</Sort>
</DATA_SPELL>
```

- `(ATTR_WP)` = full Willpower value, `(BATTR_WP)` = Willpower Bonus (same logic for the other
  characteristics: `ATTR_S`, `BATTR_S`, etc.; check case by case).
- The 8 arcane Lores of the Rulebook already have their Talent, no need to create one:
  `RULES-T0088_BETE` (Beasts), `RULES-T0088_MORT` (Death), `RULES-T0088_FEU` (Fire),
  `RULES-T0088_CIEUX` (Heavens), `RULES-T0088_METAL` (Metal), `RULES-T0088_VIE` (Life),
  `RULES-T0088_LUMIERE` (Light), `RULES-T0088_OMBRE` (Shadows). For a Lore that exists nowhere yet
  (a cult, a specific domain), create a dedicated **specialisation** Talent (see
  `DATA_TALENT_SPECIALIZATION` below, NOT `DATA_TALENT`) and attach the spells to it, **with an id
  `RULES-T0088_XXX`** (never the prefix of the current book). The book prefix is stripped before
  any grouping comparison (`CodeSansLivre`), so it protects against no collision; only the code
  after the book prefix (`T0088`) identifies the family, in BOTH mechanisms that depend on it (XP
  calculation through `<Generique>`, AND master-list / popup classification through the parent
  XML block). A talent entered by mistake in `DATA_TALENT` appears as an independent Talent in
  WinTalents instead of joining the specialisation popup.
- Petty Spells: `Talent = "RULES-T0089"`, `TypSpell = "Minor Magic"`.

## DATA_TALENT (a new INDEPENDENT talent, NOT a specialisation)

```xml
<DATA_TALENT>
<Talent id="XXXX-T0000">
<Attribut>""</Attribut>
<Description language="ENGLISH">"Talent name"</Description>
<Short language="ENGLISH">""</Short>
<Explanation language="ENGLISH">"Full text."</Explanation>
<Skill>""</Skill>
<Max>"1"</Max>
<PDF>""</PDF>
<Test language="ENGLISH">"Characteristic or skill tested, or empty"</Test>
</Talent>
</DATA_TALENT>
```

## DATA_TALENT_SPECIALIZATION (specialisation of an existing generic talent)

**Use it whenever a talent is a variant / domain of a generic talent already in the database**
(Arcane Magic (Domain), Bless (God), Vice (Type), Rune Magic (Type), etc.). NEVER use
`DATA_TALENT` for this case, even if the generic talent itself comes from another book. This
block loads only `Description` and `Generique`: no `Attribut` / `Explanation` / `Skill` / `Max` /
`PDF` / `Test`. If the source book has flavour text, keep it as an XML comment just above the
entry rather than inventing a field. An entry here is invisible in the WinTalents master list
(it is filtered as a sub-talent): it only appears through the specialisation popup of the generic
talent, exactly like the 8 Lores of the Rulebook.

```xml
<DATA_TALENT_SPECIALIZATION>
<Talent id="RULES-T0088_XXX">
<Description language="ENGLISH">"Arcane Magic (Domain name)"</Description>
  <!-- Flavour text from the source book, kept as a comment (not loaded by this block). -->
<Generique>"RULES-T0088_*"</Generique>
</Talent>
</DATA_TALENT_SPECIALIZATION>
```

## DATA_CAREER (a new career)

```xml
<DATA_CAREER>
<Career id="XXXX-WORKnnn">
<Description language="ENGLISH">"Career name"</Description>
<Explanation language="ENGLISH">"Full text."</Explanation>
<Skill>"RULES-COMPCOMB_BASE"</Skill>   <!-- "signature" skill used elsewhere -->
<Class>"RULES-CLASS_WARR"</Class>     <!-- class (Warrior, Academic, Rogue, etc.) -->
<SUBCHAPTER_LEVEL>
<Level id="1">
<Description language="ENGLISH">"Level 1 name"</Description>
<Salary>"TIERS_BRASS 1"</Salary>
</Level>
<!-- Level id="2", "3", "4"... -->
</SUBCHAPTER_LEVEL>
<SUBCHAPTER_ATTR>
<Attribut name="RULES-ATTR_WS">"1"</Attribut>
<!-- one line per characteristic, value = number of advances offered -->
</SUBCHAPTER_ATTR>
<SUBCHAPTER_SKILL>
<Skill name="RULES-COMPXXX">"1"</Skill>
  <!-- comment = English name of the skill, value = number of the Level that unlocks it -->
</SUBCHAPTER_SKILL>
<SUBCHAPTER_TALENT>
<Talent name="RULES-T0000">"1"</Talent>
  <!-- same; "/" for a choice ("RULES-T0096/RULES-T0121"), "_*" for a family -->
</SUBCHAPTER_TALENT>
<SUBCHAPTER_ITEM>
<Item name="Item name or RULES-... code">"1"</Item>
  <!-- level that unlocks the item; repeat the line = several copies -->
</SUBCHAPTER_ITEM>
</Career>
</DATA_CAREER>
```

### Generic career equipment ("a weapon of your choice")

An `Item` line of `SUBCHAPTER_ITEM` can be a specific item or a choice. Three forms for weapons:

| `Item name=` line | Meaning for the player | Condition |
|---|---|---|
| a weapon code (`RULES-COMB_SWORD`) | that weapon | the `Weapon` entry exists |
| a combat skill code (`RULES-COMP_MELEE__BASIC`, `RULES-COMP_RANGED__BOW`) | a weapon of that skill | the weapons carry that skill in their `Skill`; ammunition is excluded |
| a skill `..._*` (`RULES-COMP_MELEE__*`) | a weapon of any specialisation of that family | same |
| `RULES-COMB_*` / `RULES-PROJ_*` (old wildcard) | any weapon (melee / ranged), chosen by code prefix | needs a `Weapon id="RULES-COMB_*"` entry: its `Description` is the displayed label ("Melee Weapon (Any)"); create it only when no skill fits |

Prefer the skill code: the label comes from the skill and no dummy entry has to be created. In
WinLivre the choice is made from a list of labels; the code stays in the XML (the list does not
yet offer the `__*` form, which is typed by hand for now).

## DATA_WEAPON (weapon)

```xml
<DATA_WEAPON>
<Weapon id="RULES-COMB_SWORD">
<Description language="ENGLISH">"Sword"</Description>
<Skill>"RULES-COMP_MELEE__BASIC"</Skill>   <!-- combat skill; "-" = no skill (ammunition) -->
<Damage>"+(BATTR_S)+4"</Damage>            <!-- formula: characteristic bonus + constant -->
<Availability>"RULES-DISPO_COMMON"</Availability>   <!-- COMMON / LIMITED / RARE / EXOTIC -->
<Reach>"RULES-WEAPR_MID"</Reach>
<Price>"1CO"</Price>                       <!-- CO, PA, SB -->
<Encumbrance>"1"</Encumbrance>
<Quality>"RULES-WEAPB_DEFENSIVE,RULES-WEAPB_UNDAMAGING"</Quality>   <!-- see DATA_WEAPON_BONUS; "-" = none -->
<Hand>"1"</Hand>
<Ammunition>"0"</Ammunition>
<Type>"RULES-WTYPE_SWORD"</Type>
<Page>92</Page>
</Weapon>
</DATA_WEAPON>
```

- **`Description` and `Damage` are mandatory**, with `Description`, `Skill`, `Damage` first, in that
  order (`Skill` is optional for the schema, but every book gives it: `-` = no skill). The rest is
  optional and in any order (a book may omit `Availability` and `Price`), except `Page`, which
  comes last.
- **`Skill`**: combat skill code (`RULES-COMP_MELEE__BASIC`, `__PARRY`, `RULES-COMP_RANGED__*`...),
  see `DATA_SKILL_SPECIALIZATION`. `-` = no skill: the weapon sheet then shows no skill line.
- **`Damage`**: formula evaluated at use. `(BATTR_S)` = Strength Bonus, `+4` = constant.
- **`Reach`**: melee weapon = reach code `RULES-WEAPR_*` (PERSO, SHORT, CLOSE, MID, LONG, BIG, HUGE);
  ranged weapon = range in yards (`"100"`) or a Strength formula (`"(BATTR_S)X3"` in the Rulebook,
  `"(BATTR_S)x3"` in Archives II: the text is displayed as is, upper or lower case).
- **Ammunition**: an arrow, bolt or bullet is a `Weapon` with an id `RULES-MUNI_*`
  (`RULES-MUNI_ARROW`): `Skill` = skill of the weapon that fires it (`RULES-COMP_RANGED__BOW`),
  `Ammunition` = number of projectiles in the lot (12), `Damage` and `Reach` = modifiers added to
  those of the weapon (`"+1"`, `"+50"`, `"-10"`, `"/2"`), `Hand` = 0. The sheet of an ammunition
  does not show the skill.
- **`Quality`**: codes separated by commas, from the `DATA_WEAPON_BONUS` catalogue
  (`RULES-WEAPB_*`); a rated quality takes its value after a space (`RULES-WEAPB_RELOAD 2`,
  `RULES-WEAPB_SHIELD 3`). A numeric quality carried by the weapon (Might, Protection) also
  modifies the bearer.
- **`Hand`**: number of hands (`1` or `2`; 0 for ammunition). **`Ammunition`**: 0 for an ordinary
  weapon, number of projectiles of the lot for ammunition. **`Type`**: `RULES-WTYPE_*` code
  (weapon family, e.g. sword, axe; used by per-weapon-type bonuses).
- **`InherentCraftsmanship`**: code of a craftsmanship (`DATA_CRAFTMANSHIP`) already built into the
  weapon.
- **Modifiers** (`ModifyCarac`, `ModifyDamage`...): the numeric effects of the carried weapon, as in
  the XSD (`ModificateursEffets`).
- The Rulebook weapons are the most complete: use them as a model (`RULES-COMB_SWORD` for melee, a
  bow for ranged).

### DATA_WEAPON_BONUS (weapon qualities and flaws)

```xml
<DATA_WEAPON_BONUS>
<BonusMalus id="RULES-WEAPB_DEFENSIVE">
<Description language="ENGLISH">"Defensive"</Description>
<Explanation language="ENGLISH">"Defensive weapons are designed to parry..."</Explanation>
<Short language="ENGLISH">"+1 SL when opposing an attack"</Short>
<Modifier>"+"</Modifier>
<Page>298</Page>
</BonusMalus>
</DATA_WEAPON_BONUS>
```

- `Description` = name, `Explanation` = text of the book, `Short` = one-line summary shown in lists
  and on the PDF.
- **`Modifier`**: `+` = quality, `-` = flaw (Slow, Undamaging...). Mandatory.
- **`NeedsValue` `"1"`**: the quality must receive a rating when a weapon cites it (`Reload 3`,
  `Blast 5`, `Repeater`).
- `WeaponQuality`: other qualities granted by this one (`Parry` = Balanced + Defensive), shown with
  the carried weapon. `Talent`: talent granted to the bearer.
- Numeric effect = `ModifyCarac`, `ModifyDamage`... from the common group (a CARRIED weapon quality
  modifies the bearer). Without a numeric effect, the quality is only text.

## DATA_ARMOR (armour)

```xml
<DATA_ARMOR>
<Armor id="RULES-ARMO_MAIL_SHIRT">
<Description language="ENGLISH">"Mail Shirt"</Description>
<Availability>"RULES-DISPO_LIMITED"</Availability>
<Price>"2CO"</Price>                       <!-- optional: pieces that cannot be bought -->
<Encumbrance>"2"</Encumbrance>
<Quality>"RULES-ARMOB_FLEXIBLE,RULES-ARMOB_NOT_DISCREET"</Quality>
<Location>"RULES-ARMOL_BODY"</Location>
<ArmorPoint>"2"</ArmorPoint>
<Type>"RULES-ARMOT_MAIL"</Type>
<Page>300</Page>
</Armor>
</DATA_ARMOR>
```

- **Mandatory order** (the schema tolerates no other): `Description`, `Availability`, `Price`,
  `Encumbrance`, `Quality`, `Location`, `ArmorPoint`, `Type`, `InherentCraftsmanship`, `Page`.
  Mandatory: everything except `Price`, `Type`, `InherentCraftsmanship` and `Page`. A piece without
  a quality writes `"-"`.
- **`Location`**: `RULES-ARMOL_HEAD`, `_ARM`, `_BODY`, `_LEG` (and `_SHIELD` for a shield); a piece
  covering several zones lists them separated by a comma (`RULES-ARMOL_ARM,RULES-ARMOL_BODY`).
- **`ArmorPoint`**: armour points (AP) of the piece, per zone covered.
- **`Quality`**: `RULES-ARMOB_*` codes from the `DATA_ARMOR_BONUS` catalogue, separated by commas.
- **`Type`**: material `RULES-ARMOT_*` (`SOFTLEATHER`, `BOILLEDLEATHER`, `MAIL`, `PLATE`); absent
  on WFRP5 shields.
- **`InherentCraftsmanship`**: craftsmanship already built in (as for weapons).
- `DATA_ARMOR_BONUS` (armour qualities, `BonusMalus` `RULES-ARMOB_*`): `Description`,
  `Explanation`, then `Modifier` = **short free text** of the effect (`"combinable with Plate"`,
  not a `+` / `-` as for weapons) and optionally `NeedsValue`, `Corruption`, `Talent`,
  `ModifyCarac`...
- `DATA_ARMOR_SIMP`: armours of the optional "Quick Armour" rule (one line = a complete set:
  `Availability`, `Price`, `Encumbrance`, `Quality`, `ArmorPoint`, no `Location`). The setting is
  global (INI); it is not decided per book.

## DATA_CRAFTMANSHIP (craftsmanship: item quality, rune, enchantment)

```xml
<DATA_CRAFTMANSHIP>
<Craftsmanship id="DWARF-RUNE_RUNE_OF_CLEAVING">
<Description language="ENGLISH">"Rune of Cleaving"</Description>
<Explanation language="ENGLISH">"The weapon inflicts +1 Damage for each Rune of Cleaving."</Explanation>
<Short language="ENGLISH">"Weapon rune, 10 SLs"</Short>
<Max>"3"</Max>                              <!-- maximum number that can be placed on one item -->
<Applies>Weapon</Applies>                   <!-- Weapon / Armour / Misc; absent = any item -->
<ModifyDamage name="CC">1</ModifyDamage>
<Modifier>""</Modifier>
<Page>127</Page>
</Craftsmanship>
</DATA_CRAFTMANSHIP>
```

- This is what the player picks in the **Craftsmanship** column of the equipment; `Applies` filters
  the proposed list according to the item (weapon, armour, miscellaneous).
- **`Modifier`**: nature of the craftsmanship: `BONUS`, `PRACTICAL`, `UNRELIABLE`, `BULKY` or empty
  (rune, enchantment). It drives the "with equipment" column of the PDF, never the total
  (Practical / Unreliable).
- **`Encumbrance`**: added encumbrance. **`RangeBonus`**: range bonus of ranged weapons.
  **`WeaponQuality`**: added weapon qualities (`RULES-WEAPB_*` codes). **`AlternateWeapon`**: code
  of another weapon the item becomes. **`Talent`**: talent granted (set on the chosen weapon or
  armour).
- Numeric effects: `ModifyDamage`, `ModifyCarac`, `ModifArmour`... from the common group; a
  conditional effect carries `if="CODE-COND_xx"` (`DATA_CONDITION`) and is only displayed.
- `Explanation` is optional, `Short` is mandatory. Order: `Description`, `Explanation`, `Short`,
  then the other tags in any order, `Page` last.
- **Value of numeric effects**: without quotation marks, sign included
  (`<ModifyCarac name="RULES-ATTR_I">+10</ModifyCarac>`, `<ModifyDamage name="CC">1</ModifyDamage>`),
  unlike text tags (`Max`, `Modifier`, `Talent`, `WeaponQuality` in quotation marks; `Applies`
  without: `<Applies>Weapon</Applies>`). The `name` of a `ModifyDamage` = `CC` (melee) or `CT`
  (ranged).
- One magical ability with two versions (melee / ranged) = **two entries** (`..._05A` and `..._05B`
  in Archives II, name followed by "(Melee)" / "(Ranged)").
- A craftsmanship that only adds a **standard** weapon quality (Fast, Precise...) creates no
  `WeaponQuality`: the book writes the code in `Explanation` / `Short` ("add RULES-WEAPB_FAST") and
  the player adds it by hand.

## DATA_STARSIGN (star signs, optional rule)

```xml
<DATA_STARSIGN>
<StarSign id="ARCH2-STAR_WYMUND_THE_ANCHORITE">
<Range>"01-05"</Range>                      <!-- d100 range that designates this sign -->
<Description language="ENGLISH">"Wymund the Anchorite"</Description>
<Title language="ENGLISH">"Sign of Enduring"</Title>
<Classical>"Wymenos"</Classical>            <!-- classical name -->
<Ascendant>"Midwinter"</Ascendant>
<Dates>"Vorhexen 12th - Vorhexen 27th"</Dates>
<God>"Manaan"</God>
<Appearance language="ENGLISH">"A stern face"</Appearance>
<Personality language="ENGLISH">"People born under..."</Personality>
<Modifier name="RULES-ATTR_Fel">"2"</Modifier>      <!-- one line per modified characteristic -->
<Modifier name="RULES-ATTR_Int">"-3"</Modifier>
<Page>39</Page>
</StarSign>
</DATA_STARSIGN>
```

- The nine description tags (`Range` to `Personality`) are all mandatory, in that order; `Title`,
  `Appearance` and `Personality` are translatable. Full order: those nine, then the `Variant`s, then
  the `Modifier` / `Talent` (mixed), then `Page`. `Range`: `"96-00"` (the final 00 means 100);
  `God`, `Dates`, `Ascendant` are free text (`"Vallich (Smithing and Ship Building (Nordland))"`).
- The `Modifier` of a sign is **in quotation marks** (`"2"`, `"-3"`), unlike the `ModifyCarac` of
  other blocks. A characteristic of the sign = `RULES-ATTR_*` code (`_S`, `_T`, `_Ag`, `_Int`,
  `_WP`, `_Fel`, `_I`, `_WS`, `_BS`). A `Talent` may be a specialisation to choose
  (`"RULES-T_CRAFTSMAN__*"`).
- **Effects**: `Modifier name="RULES-ATTR_xx"` (signed value added to the characteristic) and/or
  `Talent` (code of a granted talent). No effect = a purely narrative sign.
- **`Variant range="1-3"`**: a sign with variants (Witchling Star) triggers a **d10 sub-roll**; each
  `Variant` carries the range that selects it (`"1-3"`, or a single digit: `range="10"`) and its own
  `Talent` / `Modifier` (the `Talent` before the `Modifier`). Effects outside a `Variant` apply to
  every variant.
- The block applies only if the book carries the `STARSIGN` option (see `DATA_OPTION_RULE`); the
  "Star signs" checkbox of the Book step of WinCreation decides for the character being created.

## DATA_DISEASE (diseases) and DATA_AFFLICTION (afflictions)

```xml
<DATA_DISEASE>
<Disease name="RULES-DISEASE_BLOOD_ROT">             <!-- attribute name = the code (no id) -->
<Description language="ENGLISH">"Blood Rot"</Description>
<Contraction language="ENGLISH">"As a development of another disease or a Critical Wound."</Contraction>
<Incubation language="ENGLISH">"Instant"</Incubation>
<Duration language="ENGLISH">"1d10 days"</Duration>
<Symptoms language="ENGLISH">"Blight, Fever (Severe), Malaise"</Symptoms>   <!-- optional -->
<Page>186</Page>
</Disease>
</DATA_DISEASE>

<DATA_AFFLICTION>
<Affliction name="GRIM-AFFLICT_ALLERGY">
<Description language="ENGLISH">"Allergy"</Description>
<Explanation language="ENGLISH">"(Chaos Lore 01-05 / ...) You develop a severe allergic response..."</Explanation>
<Page>31</Page>
</Affliction>
</DATA_AFFLICTION>
```

- These two catalogues feed the **Pathology** tab of WinPersonnage ("+ Affliction" / "+ Disease"
  buttons). The **`name`** attribute is the code stored on the character (`BOOK-DISEASE_NAME`,
  `BOOK-AFFLICT_NAME`): never rename it afterwards.
- Numeric effects are **without quotation marks**
  (`<ModifyCaracAleatoire name="RULES-ATTR_T">10</ModifyCaracAleatoire>`,
  `<ModifySkillAttribut name="RULES-ATTR_Fel">-10</ModifySkillAttribut>`); an affliction with an
  effect carries a single one of these tags in the Grimoire.
- **Disease**: `Contraction`, `Incubation`, `Duration` are mandatory (text of the book,
  translatable), `Symptoms` optional. No chance table (the book has no d100 roll).
- **Affliction**: `Description` + `Explanation`; the d100 ranges per caster category stay as text in
  `Explanation`.
- **Permanent numeric effects** (optional, after the texts): `ModifyCarac` (fixed value) or
  `ModifyCaracAleatoire` (value = a die face, rolled once when added and remembered),
  `ModifySkillAttribut`... from the common group. A disease without a numeric effect is only text.

## DATA_CORRUPTION_* (Chaos corruption and mutations)

Five blocks work together for the Rulebook V4 corruption roll:

```xml
<DATA_CORRUPTION_PHYSICAL>                     <!-- per race: d100 range that gives a PHYSICAL corruption -->
<Specie name="RULES-RACE_HUM">"01-50"</Specie>
<Specie name="RULES-RACE_HELF">"-"</Specie>    <!-- "-" = never physical -->
</DATA_CORRUPTION_PHYSICAL>
<DATA_CORRUPTION_MENTAL>                       <!-- same, MENTAL: the two ranges complement each other -->
<Specie name="RULES-RACE_HUM">"51-100"</Specie>
</DATA_CORRUPTION_MENTAL>

<DATA_CORRUPTION_PHYSICAL_CHANCE>              <!-- 2nd roll: d100 range -> mutation code -->
<Chance name="01-05">"RULES-CORPHY_ANIMALISTIC_LEGS"</Chance>
</DATA_CORRUPTION_PHYSICAL_CHANCE>
<DATA_CORRUPTION_TABLE_PHYSICAL>               <!-- catalogue: code -> name, text, effects -->
<Corruption name="RULES-CORPHY_ANIMALISTIC_LEGS">
<Description language="ENGLISH">"Animalistic Legs"</Description>
<Explanation language="ENGLISH">"+1 Movement"</Explanation>
<ModifyCarac name="RULES-ATTR_Move">+1</ModifyCarac>
<Page>184</Page>
</Corruption>
</DATA_CORRUPTION_TABLE_PHYSICAL>
```

- The catalogue (`*_TABLE_*`) and the chance table (`*_CHANCE`) are **deliberately separate**: a book
  can renumber its chance table without changing the codes already stored on characters. The
  **code** (`name` of `Corruption`, `RULES-CORPHY_*` / `RULES-CORMEN_*`) is therefore stable, never
  a range.
- **A book that adds a race** (Archives II, Ogre): only `DATA_CORRUPTION_PHYSICAL` and
  `DATA_CORRUPTION_MENTAL` are needed, with one `Specie name="<race code>"` line (`"01-10"`
  physical, `"11-100"` mental: the two ranges cover 1 to 100 with no gap). The chance tables and
  catalogues stay those of the Rulebook.
- Ranges: `"01-05"`; the final `00` means 100 (`"96-00"`); `"-"` = no range (the race never has
  that type).
- `DATA_CORRUPTION_TABLE_MENTAL`: `Description`, `Explanation`, `ModifyCarac*`.
  `DATA_CORRUPTION_TABLE_PHYSICAL`: `Description`, `Explanation`, then a mix of `ModifyCarac` /
  `ModifArmour` (one per location) / `ModifySkill` / `ModifySkillAttribut` / `Weapon` (natural
  weapon). Many effects stay as text: only the simple deltas are numeric.
- **WFRP2** (`SCHEMA_WFRP2.xsd`): `DATA_CORRUPTION_TABLE_DIVINE` + `DATA_CORRUPTION_DIVINE_CHANCE`
  (Marks of the Gods: one table **per god**, `Lore` = divine lore, d100 range carried by
  `Chance name lore`) and `DATA_CORRUPTION_TABLE_MUTATION` + `DATA_CORRUPTION_MUTATION_CHANCE`
  (Chaos Mutations: a **d1000** roll `"001-005"`; `Fear` = fear points, `MutationType` = `Single` /
  `Multiple N`, `Cosmetic`, `MutationBase` for successive takings of a mutation with per-rank
  effects).

## DATA_OPTION_RULE (optional rule wired to the engine)

```xml
<DATA_OPTION_RULE>
<OptionRule id="ARCH2-OPTR_01">
<Code>"STARSIGN"</Code>
<Description language="ENGLISH">"Star Signs"</Description>
<Explanation language="ENGLISH">"The following is an optional system..."</Explanation>
<Page>39</Page>
</OptionRule>
</DATA_OPTION_RULE>
```

- **`Code`** = a switch known to the engine; there are only three: `QUICKARMOUR` (simplified
  armours, Rulebook), `STARSIGN` (star signs, `DATA_STARSIGN`) and `CAREERALT` (alternative class and
  career table, `DATA_RULE` + `DATA_CAREER_ROLL`). A new code has no effect until the engine reads it.
- The user's choice is global (an `OPTION...` line of `INI.TXT`, remembered per book); for
  `STARSIGN` and `CAREERALT` the Book step of WinCreation also lets the user decide for the
  character being created. `QUICKARMOUR` stays global (it is decided per campaign).
- `Code`, `Description` and `Explanation` are all three mandatory, in that order, `Page` last.
  `Description` / `Explanation` are shown to the player in the options window: write there what the
  option changes for them (Archives II copies the introduction of the book, with "(p.39)" at the
  end).

## DATA_RULE (book rule: career roll, background, ethnicity)

```xml
<DATA_RULE>
<Rule id="LUSTR-RULE_LUSTRIA">
<Description language="ENGLISH">"Lustrian Class and Career Table"</Description>
<Explanation language="ENGLISH">"Offers a Lustria-specific table to roll your starting Class and Career..."</Explanation>
<Page>192</Page>
</Rule>
</DATA_RULE>
```

- A `Rule` is a **label** (id + text) that other blocks cite: `DATA_CAREER_ROLL` (a d100 career table
  that REPLACES the Rulebook's), `DATA_RULE_SPECIE` (skills / talents given to an ethnicity),
  `DATA_RULE_BACKGROUND` (background roll), `DATA_RULE_BACKGROUND_COUNT`, `DATA_RULE_SKILL_ROLL`,
  `DATA_RULE_TALENT_ROLL`. See the XSD annotations for the form of each.
- `Explanation` (optional, translatable) = what the rule implies for creation: the player reads it
  in the rules window and ticks or unticks it (one checkbox per book in the Book step).
- `Class`: base class replaced by a **partial** rule (Seafarer); absent = a total rule.
  `StartingMutation`: chance in % (1 to 99) of starting with a mutation, a d100 roll offered after
  the career ("Special" lines of Races and Regional Options).
- Order: `Description`, `Explanation`, `Class`, `StartingMutation`, `Page`; only `Description` is
  mandatory. `Class` = class code (`"RULES-CLASS_RIVE"` in Sea of Claws, Seafarer rule).
- Not to be confused with `DATA_OPTION_RULE`: that one wires an engine switch (`Code`), `DATA_RULE`
  carries data only.

## Other blocks (to be detailed here the next time they are used)

`DATA_TRAPPING`, `DATA_CAREER_SPECIE` (attach a career to a whole Race), `DATA_SPECIE_CAREER_CHOICE`,
`DATA_SKILL`, `DATA_RACE`, `DATA_SPECIE`, `DATA_NATION`, `DATA_SPELL_TALENT`. The complete list of
existing DATA_* blocks is in the `xs:element` declarations of the schemas.

## Code conventions (read before entering anything)

- **Identifier** = `<CODE_BOOK>-<TYPE>_<n>`: `PARRA-RACE_HPARR` (ethnicity), `PARRA-TRAP_001` (item),
  `LUSTR-WORK123` (career), `NATIO-T0017` (talent). The prefix is that of the book that DEFINES the
  entry.
- **Exception**: a specialisation of a Rulebook element keeps `RULES-` even in another book
  (`RULES-COMPLANG_STRIG`, `RULES-T0088_XXX`); only the code after the prefix identifies the family.
- **Separators**: `/` = either (`RULES-T0103/RULES-T0078`), `_*` = a specialisation to choose
  (`RULES-COMPCHEV_*`), `RULES-T*` = random talent, `,` = list (`SpellTypes`, talents of a trait).
- **Labels**: every displayed text is a `Text name="..."` of `DATA_LABEL` or of INTERFACE.Xml; fields
  carry only the code (`RULES-LAB_193`).
- **Races and ethnicities, inverted vocabulary**: `DATA_SPECIE` = the ETHNICITIES
  (`RULES-RACE_HUM`), its `Ethnic` field = the RACE (`RULES-SPECIE_HUMAN`); `DATA_RACE` = the races.
- **Quotation marks**: the text of a tag is between literal double quotes, `<Max>"1"</Max>`, except
  `<Page>` (`<Page>38</Page>`), `<Applies>Weapon</Applies>` and the value of numeric effects
  `ModifyCarac` / `ModifyDamage`... (`<ModifyCarac name="RULES-ATTR_Move">+1</ModifyCarac>`). The
  `Modifier name=...` of a star sign, however, is between quotation marks.
- **`<Page>`**: page of the English source book, `"45-46"` for several pages; it is what is shown
  when the text is absent (version without licensed text).

## DATA_SPECIE (ethnicity), model: BOOK_PARRAVONESE_STRIGANY_SIGNALLER.Xml

```xml
<DATA_SPECIE>
<Specie id="PARRA-RACE_HPARR">
<Description language="ENGLISH">"Humans (Parravonese)"</Description>
<Explanation language="ENGLISH">"Text of the book."</Explanation>
<Ethnic>"RULES-SPECIE_HUMAN"</Ethnic>          <!-- the RACE -->
<SUBCHAPTER_ATTR>
<Attribut name="RULES-ATTR_WS">"2d10+20"</Attribut>   <!-- one line per characteristic -->
<Attribut name="RULES-ATTR_Fate">"2"</Attribut>
<Attribut name="RULES-ATTR_Wound">"1xBATTR_S+2xBATTR_T+1xBATTR_WP"</Attribut>
</SUBCHAPTER_ATTR>
<SUBCHAPTER_SKILL>
<Skill>"RULES-COMPSOINANI"</Skill>             <!-- no name attribute here -->
<Skill>"RULES-COMPCHEV_*"</Skill>              <!-- Ride (Any): a choice at creation -->
</SUBCHAPTER_SKILL>
<SUBCHAPTER_TALENT>
<Talent>"RULES-T0103/RULES-T0078"</Talent>     <!-- A or B -->
<Talent>"RULES-T*"</Talent>                    <!-- one random talent per line -->
</SUBCHAPTER_TALENT>
<SUBCHAPTER_CAREER>
<Career name="RULES-WORK02">"1"</Career>       <!-- weight in the d100; X = outside the roll; - = cannot be rolled -->
</SUBCHAPTER_CAREER>
<Page>1</Page>
</Specie>
</DATA_SPECIE>
```

The weights of `SUBCHAPTER_CAREER` total 100 per ethnicity; the ranges are never entered. For a
Rulebook race: copy the characteristics of `RULES-RACE_HUM` when the book gives none.

## DATA_TRAPPING (miscellaneous item)

```xml
<DATA_TRAPPING>
<Trapping id="PARRA-TRAP_001">
<Description language="ENGLISH">"Signal Tower"</Description>
<Theme>"RULES-LAB_193"</Theme>      <!-- Tools and Kits; the list of codes is in the XSD -->
<Availability>"RULES-DISPO_COMMON"</Availability>   <!-- optional -->
<Price>"3PA 2SB"</Price>            <!-- optional: CO, PA, SB -->
<Encumbrance>"0"</Encumbrance>
<Page>2</Page>
</Trapping>
</DATA_TRAPPING>
```

## DATA_SKILL_SPECIALIZATION

```xml
<DATA_SKILL_SPECIALIZATION>
<Skill id="RULES-COMPLANG_STRIG">
<Description language="ENGLISH">"Language (Strigany)"</Description>
<Generique>"RULES-COMPLANG_*"</Generique>
<Page>124</Page>
</Skill>
</DATA_SKILL_SPECIALIZATION>
```

Never in `DATA_SKILL`: a skill that has a `Generique` would become an independent skill there.

## Career and roll blocks

See the `xs:documentation` annotations of `SCHEMA_WFRP4.xsd` and `SCHEMA_COMMON.xsd`:
`DATA_CAREER_SPECIE`, `DATA_CAREER_ROLL`, `DATA_CAREER_SUBCHOICE`, `DATA_SPECIE_CAREER_CHOICE`,
`DATA_CAREER_BONUS`, `DATA_CAREER_ADAPTATION`, `DATA_CLASS_ITEM`, `DATA_SPECIE_TRAIT`,
`DATA_RANDOM_TALENT`, `DATA_RANDOM_SPECIE`, and the effects (`ModifyCarac`, `ModifySkill`...).

## Known pitfalls

- XML comments `<!-- ... -->` inside a block can crash the parser or duplicate an entry on some
  blocks (DATA_LABEL, DATA_SPECIE_CAREER_CHOICE, DATA_SKILL_SPECIALIZATION affected, DATA_ROLL not
  confirmed): put the summary comment BEFORE the `<DATA_...>` block, not inside it, except on blocks
  already verified safe (DATA_RACE, DATA_RULE, DATA_CAREER_ROLL, DATA_CAREER_SPECIE, DATA_TALENT,
  DATA_CAREER, DATA_SPELL: all used with inline comments in existing books).
- WinLivre cannot edit `DATA_SPELL_TALENT`: enter it by hand in the XML only.

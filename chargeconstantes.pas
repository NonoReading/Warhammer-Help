unit ChargeConstantes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Graphics, Controls, Grids, StdCtrls, Forms, lcltype, LCLIntf,
  ComCtrls, ExtCtrls, SysUtils, fppdf, fpttf;

Const
      // séparateurs connus
      SeparateurMulti     	        = '/';
      // "les deux ensemble" (ex. Storm Lantern+Lamp Oil) - a ne pas confondre avec
      // SeparateurMulti qui veut dire "au choix" partout dans le projet (CONTEXT.md).
      SeparateurEnsemble                = '+';
      Separateurtabulation              = #9;
      SeparateurRetourLigne             = #13#10;
      SeparateurChance                  = '-';
      SeparateurDetail                  = ':';
      SeparateurLivre                   = '-';
      ValeurSousCompetence		= '_';
      ValeurGenerique			= '_*';
      // Talents V4 / V5 (24/10/2026) : une specialisation s'ecrit FAMILLE__SPEC (RULES-T_BLESS__SIGMAR), son generique
      // FAMILLE__* ; un talent sans specialisation n'a pas de '__'. '__*' contient '_*' : les tests Pos(ValeurGenerique, ...)
      // valent donc aussi pour les generiques de talents.
      SeparateurSpecialisationTalent	= '__';
      ValeurGeneriqueTalent		= '__*';
      ValeurNonRenseignee               = '?';

      // Fichier XML de personnages
      ConstXmlRace			= 'Specie';
      // Attention au vocabulaire : ConstXmlRace ('Specie') désigne l'ETHNIE
      // (ex. "Humans (Reikland)"), alors que ConstXmlEspece ('Race') désigne la
      // RACE générique qui regroupe plusieurs ethnies (ex. "Human").
      ConstXmlEspece			= 'Race';
      // Balise d'entree du bloc DATA_NATION (ex. <Nation id="RULES-NATION_EMPIRE">) - PAS
      // le meme role que ConstXmlNationality juste en dessous, qui est le POINTEUR pose sur
      // une ethnie ; meme separation que <Race>/<Ethnic> ci-dessus, pour la meme raison.
      ConstXmlNation			= 'Nation';
      // Ne pas confondre avec ConstXmlRegle ('RULES') plus bas, qui n'est pas une règle de
      // jeu mais la liste des livres acceptés d'un personnage (chargepersonnage.pas).
      ConstXmlRegleJeu			= 'Rule';
      ConstXmlWork			= 'Career';
      ConstXmlCarac			= 'Attribut';
      ConstXmlTalent			= 'Talent';
      ConstXmlCompetence		= 'Skill';
      ConstXmlNvWork			= 'Level';
      ConstXmlItem			= 'Item';
      ConstXmlXp			= 'Xp';
      ConstXmlXp25Total                 = 'Xp25';
      ConstXmlXpCurrent			= 'CurrentXp';
      ConstXmlName			= 'Name';
      ConstXmlPersonnage		= 'PLAYER';
      // Racine du fichier GROUPE_<Nom>.xml (CONTEXT.md 2.100) : juste une liste d'inventaire
      // partage (animaux/vehicules/bateaux), meme sous-chapitre que le "Divers" personnage.
      ConstXmlGroupe                    = 'GROUPE';
      ConstXmlChapitreCreation		= 'CHAPTER_CREATION';
      ConstXmlChapitreAugmentation	= 'CHAPTER_INCREASE';
      ConstXmlChapitreCompetence	= 'CHAPTER_SKILL';
      ConstXmlChapitreTalent            = 'CHAPTER_TALENT';
      ConstXmlChapitreCoutXp            = 'CHAPTER_XP';
      ConstXmlSousChapitreCarac	        = 'SUBCHAPTER_ATTR';
      // V2 : <Advances><Advance name="RULES-ATTR_xx">"5"</Advance></Advances> d'une carriere
      ConstXmlAdvances                  = 'Advances';
      ConstXmlExitCodes                 = 'ExitCodes';
      ConstXmlBasic                     = 'Basic';
      ConstXmlAdvance                   = 'Advance';
      ConstXmlArgentDepart              = 'StartMoney';
      ConstXmlSousChapitreTalent	= 'SUBCHAPTER_TALENT';
      ConstXmlSousChapitreCompetence    = 'SUBCHAPTER_SKILL';
      ConstXmlSousChapitreCompMetier    = 'SUBCHAPTER_SKILLCAREER';
      ConstXmlSousChapitreTalMetier     = 'SUBCHAPTER_TALENTCAREER';
      ConstXmlSousChapitreCompSpecie    = 'SUBCHAPTER_SKILLSPECIE';
      ConstXmlSousChapitreCompCreation  = 'SUBCHAPTER_SKILLCREATION';
      // Pendant de SUBCHAPTER_SKILLSPECIE (ci-dessus) pour les avancees gratuites d'une
      // APPARTENANCE (<SkillChoice> d'un CareerBonus, ex. Reiksguard palier 4) et non d'un
      // choix de creation - champ dedie plutot que reutiliser CreationCompetence35, pour ne
      // pas melanger deux sources differentes (CONTEXT.md, meme raison que
      // DATA_CAREER_BONUS/DATA_SPELL_TALENT). Ecrit au niveau du personnage, a cote de
      // MEMBERSHIP, pas sous CHAPTER_CREATION : ce n'est pas une donnee de creation.
      ConstXmlSousChapitreCompAppartenance = 'SUBCHAPTER_SKILLAPPARTENANCE';
      // V2 : avance gratuite de creation (Core p.14, etape 7), champ dedie a cote de
      // MEMBERSHIP : jamais melangee a AugmentationAttribut (les avances achetees).
      ConstXmlSousChapitreAvanceGratuite   = 'SUBCHAPTER_FREEADVANCE';
      ConstXmlChapitreOldWork		= 'CHAPTER_OLDCAREER';
      ConstXmlChapitreEquipement	= 'CHAPTER_ITEM';
      ConstXmlChapitreCorruption	= 'CHAPTER_CORRUPTION';
      ConstXmlChapitreDestin	= 'CHAPTER_FATE';
      ConstXmlChapitreResilience	= 'CHAPTER_RESILIENCE';
      ConstXmlChapitreResolve	= 'CHAPTER_RESOLVE';
      ConstXmlChapitreMutation	        = 'CHAPTER_MUTATION';
      ConstXmlChapitreAffliction	= 'CHAPTER_AFFLICTION';
      ConstXmlChapitreDisease	        = 'CHAPTER_DISEASE';
      // Talents dont les effets sont lies a une carriere+niveau precis, fige a l'octroi
      // (ex. Virtue of the Quest, NATIO-T0017). Voir StructurePersonnageTalentCarriereRequise,
      // CONTEXT.md 2.78.
      ConstXmlChapitreTalentCarriere    = 'CHAPTER_TALENT_CAREER_LINK';
      ConstXmlSousChapitreArme          = 'SUBCHAPTER_WEAPON';
      ConstXmlSousChapitreArmure        = 'SUBCHAPTER_ARMOR';
      ConstXmlSousChapitreArmureSimp    = 'SUBCHAPTER_ARMOR_SET';
      ConstXmlSousChapitreDivers        = 'SUBCHAPTER_MISC';
      ConstXmlSousChapitreSort          = 'SUBCHAPTER_SPELL';
      ConstXmlSousChapitreEquipement    = 'SUBCHAPTER_ITEM';
      ConstXmlSousChapitreNiveau        = 'SUBCHAPTER_LEVEL';
      ConstXmlSousChapitreRace          = 'SUBCHAPTER_SPECIE';
      ConstXmlData                      = 'name';
      ConstXmlEquipementPorte            = 'worn';
      ConstXmlEquipementQuantite         = 'quantite';
      // Identifiant d'instance d'un animal du personnage (A1, A2...) et animal qui transporte
      // l'objet (CONTEXT.md 2.84). Ne pas confondre avec 'worn' (ConstXmlEquipementPorte).
      ConstXmlEquipementId               = 'id';
      ConstXmlEquipementPortePar         = 'carriedby';
      ConstXmlCodeLivre                 = 'CODE_BOOK';
      ConstXmlLibelleLivre              = 'BOOK';
      ConstXmlVersionLivre              = 'VERSION';
      ConstXmlOfficielLivre             = 'OFFICIAL';
      ConstXmlCompletLivre              = 'COMPLETE';
      ConstXmlTraductionDe              = 'TRANSLATION_OF';
      ConstXmlDisclaimerLivre           = 'DISCLAIMER';
      ConstXmlNomLivre                  = 'BOOKNAME';
      ConstXmlRegle                     = 'RULES';
      ConstXmlOptions                   = 'OPTIONS';
      // Appartenances du personnage (regiment, ordre de chevalerie, culte) : les codes
      // des CareerBonus auxquels il adhere. Voir CONTEXT.md 2.44.
      ConstXmlAppartenance              = 'MEMBERSHIP';
      // Adaptations FACULTATIVES retenues par le joueur (codes separes par des virgules), Adapting Careers.
      ConstXmlChoixAdaptation           = 'ADAPTATION_CHOICE';
      ConstXmlDataBook                  = 'DATA_BOOK';
      ConstXmlDataAttributCost          = 'DATA_ATTRIBUT_COST';
      ConstXmlDataSkillCost             = 'DATA_SKILL_COST';
      ConstXmlDataAttribut              = 'DATA_ATTRIBUT';
      ConstXmlDataLabel                 = 'DATA_LABEL';
      ConstXmlDataTalent                = 'DATA_TALENT';
      ConstXmlDataTalentSpe             = 'DATA_TALENT_SPECIALIZATION';
      ConstXmlDataSkill                 = 'DATA_SKILL';
      // WFRP1 : competences sans caracteristique ni cout, lues comme DATA_SKILL (nom, effet)
      ConstXmlDataSkillV1               = 'DATA_SKILL_V1';
      // WFRP1 : carrieres lues comme DATA_CAREER (competences au niveau 1, la valeur est la chance en %)
      ConstXmlDataCareerV1              = 'DATA_CAREER_V1';
      ConstXmlAdvanceSchemeV1           = 'AdvanceScheme';
      // WFRP1 : liens entre carrieres (carriere 1 > carriere 2), hors des carrieres
      ConstXmlDataCareerLinkV1          = 'DATA_CAREER_LINK_V1';
      ConstXmlLinkV1                    = 'Link';
      ConstXmlDataCareerLinkV2          = 'DATA_CAREER_LINK_V2';
      // WFRP1 : table des metiers de l Artisan
      ConstXmlDataTradeV1               = 'DATA_TRADE_V1';
      ConstXmlTradeV1                   = 'Trade';
      ConstXmlRollV1                    = 'Roll';
      ConstXmlExitCodeV1                = 'ExitCode';
      ConstXmlNoteV1                    = 'Note';
      // WFRP1 : Destin et regles de la race, classes de carriere
      ConstXmlFatePointsV1              = 'FatePoints';
      ConstXmlRuleV1                    = 'Rule';
      ConstXmlDataClassV1               = 'DATA_CLASS_V1';
      ConstXmlRequirementV1             = 'Requirement';
      ConstXmlRaceRequirementV1         = 'RaceRequirement';
      ConstXmlMoneyV1                   = 'Money';
      ConstXmlSpecieV1                  = 'Specie';
      // WFRP1 : tirage des competences de depart (d100 classe x race) et modificateur d age de leur nombre
      ConstXmlDataSkillRollV1           = 'DATA_SKILL_ROLL_V1';
      ConstXmlDataSkillCountAgeV1       = 'DATA_SKILL_COUNT_AGE_V1';
      ConstXmlDataMagicPointGainV1      = 'DATA_MAGIC_POINT_GAIN_V1';
      ConstXmlDice                      = 'Dice';
      ConstXmlMagicPoints               = 'MagicPoints';
      // WFRP1 : alignement (RULES-V1ALIGN_xxx) et points de folie de la fiche (vides / 0 = alignement standard de la race / aucun)
      ConstXmlAlignmentPerso            = 'Alignment';
      ConstXmlInsanityPoints            = 'InsanityPoints';
      // WFRP1 : bloc Background de la feuille (texte libre)
      ConstXmlBirthPlaceV1              = 'BirthPlace';
      ConstXmlParentsJobV1              = 'ParentsOccupation';
      ConstXmlFamilyMembersV1           = 'FamilyMembers';
      // les cinq alignements dans l'ordre de la ligne du livre (V1)
      CodesAlignementV1: array[0..4] of String = ('RULES-V1ALIGN_CHAOS', 'RULES-V1ALIGN_EVIL', 'RULES-V1ALIGN_NEUTRAL',
                                                  'RULES-V1ALIGN_GOOD', 'RULES-V1ALIGN_LAW');
      // WFRP1 : handicaps des magiciens (tables, stades) et leur memorisation dans la fiche
      ConstXmlDataDisabilityV1          = 'DATA_DISABILITY_V1';
      ConstXmlDataDisabilityRollV1      = 'DATA_DISABILITY_ROLL_V1';
      ConstXmlStageV1                   = 'Stage';
      // WFRP1 : table d'avancement du Cleric / Druidic Priest
      ConstXmlDataPriestAdvanceV1       = 'DATA_PRIEST_ADVANCE_V1';
      ConstXmlRangeV1                   = 'Range';
      ConstXmlResultV1                  = 'Result';
      ConstXmlEPGiftV1                  = 'EPGift';
      ConstXmlFatePointV1               = 'FatePoint';
      ConstXmlBlessingV1                = 'Blessing';
      ConstXmlFamiliarSkillsV1          = 'FamiliarSkills';
      // WFRP1 : table des familiers du Druidic Priest et memorisation du familier dans la fiche
      ConstXmlDataFamiliarV1            = 'DATA_FAMILIAR_V1';
      ConstXmlFamiliarV1                = 'DruidFamiliar';
      // WFRP1 : liste de prix (216 objets), un EquipmentV1 par objet
      ConstXmlDataEquipmentV1           = 'DATA_EQUIPMENT_V1';
      ConstXmlCategoryV1                = 'Category';
      ConstXmlSubCategoryV1             = 'SubCategory';
      ConstXmlCostV1                    = 'Cost';
      ConstXmlEncumbranceV1             = 'Encumbrance';
      ConstXmlAvailabilityV1            = 'Availability';
      ConstXmlCombatModifiersV1         = 'CombatModifiers';
      ConstXmlArmourPointsV1            = 'ArmourPoints';
      ConstXmlLocationsV1               = 'Locations';
      ConstXmlDisabilitiesV1            = 'Disabilities';
      ConstXmlSpellsLearnedV1           = 'SpellsLearned';
      ConstXmlSpellFailuresV1           = 'SpellFailures';
      ConstXmlEvilWizardV1              = 'EvilWizard';
      ConstXmlClasseV1                  = 'ClassV1';
      ConstXmlCulteV1                   = 'CultV1';
      ConstXmlAgeMinV1                  = 'AgeMin';
      ConstXmlAgeMaxV1                  = 'AgeMax';
      ConstXmlTrappingsV1               = 'Trappings';
      ConstXmlBonusV1                   = 'Bonus';
      ConstXmlBonusKind                 = 'Kind';
      ConstXmlBonusValue                = 'Value';
      ConstXmlDataSkillSpe              = 'DATA_SKILL_SPECIALIZATION';
      ConstXmlDataSpecie                = 'DATA_SPECIE';
      ConstXmlDataCareer                = 'DATA_CAREER';
      ConstXmlDataWeapon                = 'DATA_WEAPON';
      ConstXmlDataWeaponBonus           = 'DATA_WEAPON_BONUS';
      ConstXmlDataArmor                 = 'DATA_ARMOR';
      ConstXmlDataArmorSimplified       = 'DATA_ARMOR_SIMP';
      ConstXmlDataArmorBonus            = 'DATA_ARMOR_BONUS';
      // Regles optionnelles activables/desactivables par livre via le toggle .INI
      // (A FAIRE.txt "TOGGLE .INI PAR LIVRE", CONTEXT.md 2.89, 22/09/2026).
      ConstXmlDataOptionRule             = 'DATA_OPTION_RULE';
      ConstXmlOptionRule                 = 'OptionRule';
      ConstXmlCode                       = 'Code';
      ConstXmlDataTrapping              = 'DATA_TRAPPING';
      ConstXmlDataSpell                 = 'DATA_SPELL';
      ConstXmlDataSpellTalent           = 'DATA_SPELL_TALENT';
      // Les "Trait (Any)" des ethnies (Provincial / Dukedom / City State / Clan /
      // Region / Kingdom Trait). Bloc de LIVRE, cite depuis SUBCHAPTER_TALENT d'une
      // ethnie : une meme liste sert plusieurs ethnies. CONTEXT.md 2.41.
      ConstXmlDataSpecieTrait           = 'DATA_SPECIE_TRAIT';
      // Appartenance qui greffe des donnees sur une carriere (regiment, ordre de
      // chevalerie, culte). Bloc de LIVRE, purement ADDITIF : le livre qui l'apporte
      // n'a pas a modifier le fichier du livre qui declare la carriere ou l'ethnie.
      // CONTEXT.md 2.44.
      ConstXmlDataCareerBonus           = 'DATA_CAREER_BONUS';
      // Substitutions de talents/competences/trappings d'une carriere pour une ethnie
      // (Adapting Careers du High Elf Player's Guide p.60-62). Bloc de LIVRE, additif.
      ConstXmlDataCareerAdaptation      = 'DATA_CAREER_ADAPTATION';
      ConstXmlCareerAdaptation          = 'Adaptation';
      ConstXmlRemove                    = 'Remove';
      ConstXmlAdd                       = 'Add';
      ConstXmlReplace                   = 'Replace';
      ConstXmlFrom                      = 'from';
      ConstXmlOptional                  = 'Optional';
      ConstXmlStanding                  = 'Standing';
      ConstXmlDataRandomTalent          = 'DATA_RANDOM_TALENT';
      ConstXmlDataSpecieCreation        = 'DATA_RANDOM_SPECIE';
      ConstXmlDataCraftsmanship         = 'DATA_CRAFTMANSHIP';
      ConstXmlDataEspece                = 'DATA_RACE';
      // Regroupement POLITIQUE/culturel d'ethnies (l'Empire, a terme Bretonnia/Kislev/
      // Cathay...), distinct de DATA_RACE qui est BIOLOGIQUE (RULES-SPECIE_HUMAN reunit
      // aussi la Tilee, hors Empire). Meme moule que DATA_RACE : table declarable par
      // n'importe quel livre, une ethnie cite son code via <Nationality> (facultatif,
      // contrairement a <Ethnic>). Voir ChargeNation.pas. CONTEXT.md 2.51.
      ConstXmlDataNation                = 'DATA_NATION';
      ConstXmlDataRegle                 = 'DATA_RULE';
      ConstXmlDataRegleMetier           = 'DATA_CAREER_ROLL';
      ConstXmlDataRegleEthnie           = 'DATA_RULE_SPECIE';
      ConstXmlDataRegleFond             = 'DATA_RULE_BACKGROUND';
      ConstXmlDataFondCompte            = 'DATA_RULE_BACKGROUND_COUNT';
      ConstXmlDataFondCompetence        = 'DATA_RULE_SKILL_ROLL';
      ConstXmlDataFondTalent            = 'DATA_RULE_TALENT_ROLL';
      ConstXmlFondNbCompetence          = 'Skills';
      ConstXmlFondNbTalent              = 'Talents';
      ConstXmlDataSpecieCareerChoix     = 'DATA_SPECIE_CAREER_CHOICE';
      ConstXmlDataCareerSpecie    = 'DATA_CAREER_SPECIE';
      ConstXmlDataCareerSubChoice       = 'DATA_CAREER_SUBCHOICE';
      ConstXmlDataPhysicalCorruption    = 'DATA_CORRUPTION_PHYSICAL';
      ConstXmlDataMentalCorruption      = 'DATA_CORRUPTION_MENTAL';
      ConstXmlDataCorruptionTablePhys   = 'DATA_CORRUPTION_TABLE_PHYSICAL';
      ConstXmlDataCorruptionTableMent   = 'DATA_CORRUPTION_TABLE_MENTAL';
      ConstXmlDataCorruptionPhysChance  = 'DATA_CORRUPTION_PHYSICAL_CHANCE';
      ConstXmlDataCorruptionMentChance  = 'DATA_CORRUPTION_MENTAL_CHANCE';
      // Marques des Dieux (WFRP2, Tome of Salvation) : table par dieu, le lore divin designe la table
      ConstXmlDataCorruptionTableDivine  = 'DATA_CORRUPTION_TABLE_DIVINE';
      ConstXmlDataCorruptionDivineChance = 'DATA_CORRUPTION_DIVINE_CHANCE';
      ConstXmlDataCorruptionTableMutation  = 'DATA_CORRUPTION_TABLE_MUTATION';
      ConstXmlDataCorruptionMutationChance = 'DATA_CORRUPTION_MUTATION_CHANCE';
      ConstXmlLoreAttribut               = 'lore';
      ConstXmlDataDisease               = 'DATA_DISEASE';
      ConstXmlDataAffliction            = 'DATA_AFFLICTION';
      ConstXmlDataClassItem             = 'DATA_CLASS_ITEM';
      ConstXmlContraction               = 'Contraction';
      ConstXmlIncubation                = 'Incubation';
      ConstXmlDuration                  = 'Duration';
      ConstXmlSymptoms                  = 'Symptoms';
      ConstXmlChance                    = 'Chance';
      ConstXmlLibelle                   = 'Libelle';
      ConstXmlEffet                     = 'Effet';
      ConstXmlDescription               = 'Description';
      ConstXmlDescriptionFeminine       = 'DescriptionFeminine';
      ConstXmlExplanation               = 'Explanation';
      ConstXmlShort                     = 'Short';
      // Code complet (prefixe de livre inclus) de l'entree generique dont depend une
      // specialisation de DATA_SKILL_SPECIALIZATION/DATA_TALENT_SPECIALIZATION - remplace
      // la deduction par radical quand la specialisation vient d'un livre different de sa
      // generique. Voir CONTEXT.md 2.67.
      ConstXmlGenerique                 = 'Generique';
      ConstXmlMax                       = 'Max';
      // Accessoires d arme (fabrication) : bonus de portee et qualites d arme ajoutees.
      ConstXmlFabPortee                 = 'RangeBonus';
      ConstXmlFabQualiteArme            = 'WeaponQuality';
      ConstXmlFabArmeAlternative        = 'AlternateWeapon';
      ConstXmlFabApplique               = 'Applies';
      // Fabrication D'ORIGINE d'une entree DATA_WEAPON/DATA_ARMOR (Incandescent Spear Durable
      // 3/Fine 3, gromril Durable 4/Fine 1...) : meme format "CODE val,CODE val" que
      // PersonnageEquipement.QualiteEquipement, copie automatiquement dessus a l acquisition
      // (chantier "objets a fabrication integree", A FAIRE.txt).
      ConstXmlFabIntegree               = 'InherentCraftsmanship';
      ConstXmlForPdf                    = 'PDF';
      ConstXmlTest                      = 'Test';
      // Marque un talent comme TRAIT DE CREATURE (Rulebook p.338-341) : acquis a la naissance
      // par la race, jamais achete ni choisi. Voir CONTEXT.md 2.15.
      ConstXmlTrait                     = 'Trait';
      // Acces aux sorts porte par le TALENT, en donnees, a la place des quatre constantes
      // TalentSortXxx comparees par prefixe (winpersonnage.pas). Deux axes independants :
      //  <Magic>     priorite d'ouverture du catalogue de sorts
      //              1 = exclusif (un Domaine ecarte tout le reste)
      //              2 = cumulable (Miracle, Magie Mineure)
      //              0 = n'ouvre jamais le catalogue (Benediction)
      //  <SpellMode> comment les sorts arrivent a l'achat du talent
      //              AUTO   = les sorts qui citent ce talent sont ajoutes (Benediction)
      //              CHOICE = une ligne "a choisir" est ajoutee (Miracle)
      //              NONE   = rien (Domaine, Magie Mineure)
      // Voir CONTEXT.md 2.18.
      ConstXmlMagie                     = 'Magic';
      ConstXmlModeSort                  = 'SpellMode';
      // Valeurs de <TypSpell> ouvertes par ce talent, separees par des virgules, en anglais
      // ("Arcane Magic,Domain Magic,Ritual"). Sur l'entree generique ; herite par ChercheTalent.
      ConstXmlTypesSort                 = 'SpellTypes';
      //  TARIF DES SORTS OUVERTS PAR CE TALENT. Cinq champs, tous portes par les entrees
      //  GENERIQUES (T0012_*, T0080_*, T0088_*, T0089, T0172_*) et reportes sur les
      //  specialisations par ChercheTalent, comme Magic et SpellMode.
      //
      //     cout = XpMultiplier x max( XpFloor , ceil( n / XpDivisor ) )
      //
      //  ou n est le nombre de sorts DEJA connus dans le meme XpPool.
      //     XpMultiplier  0 = gratuit (Benediction), sinon 50 ou 100
      //     XpFloor       plancher : 1 = le premier sort est deja payant (Domaine, Chaos)
      //                              0 = le premier est gratuit (Miracle)
      //     XpDivisor     largeur d'un palier. Vide = aucune progression, donc forfait.
      //                   Accepte un nombre ou un bonus d'attribut note (BATTR_x).
      //     XpFree        sorts offerts a l'achat du talent, donc gratuits. Accepte la
      //                   meme notation. C'est la regle "you memorise a number of spells
      //                   equal to your Willpower Bonus" de Petty Magic.
      //     XpPool        compteur partage. Deux talents portant le meme pool comptent
      //                   leurs sorts ENSEMBLE - c'est le cas d'Arcane et de Domain.
      //                   Vide = le talent compte seul.
      //  Voir CONTEXT.md 2.31 pour les tables du Rulebook dont ces valeurs sortent.
      ConstXmlXpMultiplicateur          = 'XpMultiplier';
      ConstXmlXpPlancher                = 'XpFloor';
      ConstXmlXpDiviseur                = 'XpDivisor';
      ConstXmlXpOfferts                 = 'XpFree';
      ConstXmlXpGroupe                  = 'XpPool';
      ConstModeSortAuto                 = 'AUTO';
      ConstModeSortChoix                = 'CHOICE';
      ConstModeSortAucun                = 'NONE';
      // Valeurs de <Magic>, nommees pour que le code ne compare pas des chiffres nus.
      ConstMagieAucune                  = 0;
      ConstMagieExclusive               = 1;
      ConstMagieCumulable               = 2;
      // Valeur "vrai" d'une balise XML booleenne (meme convention que <OFFICIAL>/<COMPLETE>).
      ConstVrai                         = '1';
      ConstXmlEthnic                    = 'Ethnic';
      // Pointeur FACULTATIF pose sur une ethnie vers son code DATA_NATION (vide = aucune
      // nation, cas de la plupart des ethnies non-humaines). CONTEXT.md 2.51.
      ConstXmlNationality               = 'Nationality';
      ConstXmlMutationDepart            = 'StartingMutation';
      // Details physiques d'une ethnie : Age et Height (deja definis plus bas pour la fiche)
      // servent aussi de balises de formule ; Eye/Hair portent le libelle en name= et la
      // plage 2d10 en contenu.
      ConstXmlSousChapitrePhysique      = 'SUBCHAPTER_PHYSICAL';
      ConstXmlPhysTailleExplose         = 'HeightExplode';
      ConstXmlPhysNbTirageYeux          = 'EyeRolls';
      ConstXmlPhysYeux                  = 'Eye';
      ConstXmlPhysCheveux               = 'Hair';
      // V2 (Core, tables 2-6 a 2-17) : tables d100 / d10 par race (name= resultat, contenu = plage) et
      // tables communes DATA_PERSONAL_TABLE (Table id=, Entry name= detail=).
      ConstXmlPhysTailleFemme           = 'HeightFemale';
      ConstXmlPhysTailleHomme           = 'HeightMale';
      ConstXmlPhysPoids                 = 'Weight';
      ConstXmlPhysAge                   = 'AgeRoll';
      ConstXmlPhysFratrie               = 'Siblings';
      ConstXmlPhysNaissance             = 'Birthplace';
      ConstXmlPhysLocalite              = 'BirthplaceSettlement';
      ConstXmlPhysNaissanceHumaine      = 'BirthplaceHuman';
      ConstXmlPhysNaissanceEffet        = 'BirthplaceEffect';
      ConstXmlPhysParticulariteEffet    = 'OddityEffect';
      ConstXmlPhysForme                 = 'Form';
      ConstXmlPhysFormeAnimal           = 'FormAnimal';
      ConstXmlPhysParticularite         = 'Oddity';
      ConstXmlDataTablePersonnelle      = 'DATA_PERSONAL_TABLE';
      ConstXmlTable                     = 'Table';
      ConstXmlDetail                    = 'detail';
      // Noms d'une ethnie : bloc de tables (Name : name= libelle, part= partie, sex= M/F facultatif,
      // contenu = plage du de) et modeles d'assemblage (NamePattern, sex= facultatif).
      ConstXmlSousChapitreNoms          = 'SUBCHAPTER_NAMES';
      ConstXmlNom                       = 'Name';
      ConstXmlNomModele                 = 'NamePattern';
      // Signes astraux (DATA_STARSIGN) : un StarSign par signe, Variant = sous-tirage (Witchling Star),
      // Modifier name= code de caracteristique, Talent = code de talent. Range, Title... sont propres au bloc.
      ConstXmlDataSigneAstral           = 'DATA_STARSIGN';
      ConstXmlSigneAstral               = 'StarSign';
      ConstXmlSignePlage                = 'Range';
      ConstXmlSigneTitre                = 'Title';
      ConstXmlSigneClassique            = 'Classical';
      ConstXmlSigneAscendant            = 'Ascendant';
      ConstXmlSigneDates                = 'Dates';
      ConstXmlSigneDieu                 = 'God';
      ConstXmlSigneApparence            = 'Appearance';
      ConstXmlSignePersonnalite         = 'Personality';
      ConstXmlSigneVariante             = 'Variant';
      ConstXmlSigneModificateur         = 'Modifier';
      // Fiche de personnage : code du signe (balise StarSign = ConstXmlSigneAstral) et plage de sa variante
      // (sous-tirage du Witchling Star), vide si le signe n'en a pas.
      ConstXmlSigneVariantePerso        = 'StarSignVariant';
      // Specialisation choisie pour le talent generique du signe (Craftsman, Impassioned Zeal)
      ConstXmlSigneTalentPerso          = 'StarSignTalent';
      // Sous-bloc V2 de la fiche (details personnels du Core V2) : absent des fiches V4/V5.
      ConstXmlFicheV2                   = 'V2';
      ConstXmlFicheSexe                 = 'Gender';
      ConstXmlFichePoids                = 'Weight';
      ConstXmlFicheFratrie              = 'Siblings';
      ConstXmlFicheSigneDistinctif      = 'DistinguishingMark';
      ConstXmlFicheNaissance            = 'Birthplace';
      ConstXmlFicheAstreV2              = 'StarSignV2';
      // Monnaie du personnage : couronnes d'or, pistoles d'argent, sous de laiton
      ConstXmlMonnaieCO                 = 'GoldCrowns';
      ConstXmlMonnaiePA                 = 'SilverShillings';
      ConstXmlMonnaieSB                 = 'BrassPennies';
      ConstXmlNomPartie                 = 'part';
      ConstXmlNomSexe                   = 'sex';
      // NamePattern rule="CODE" : modele tire seulement si le joueur choisit cette regle de nom
      // (absent : modele ordinaire). La regle se declare par <NameRule>"id de libelle"</NameRule>
      // avec l'attribut code="CODE" dans le meme SUBCHAPTER_NAMES.
      ConstXmlNomRegle                  = 'rule';
      ConstXmlNomRegleDecl              = 'NameRule';
      ConstXmlNomRegleCode              = 'code';
      // Nombre de competences de race a choisir dans chaque colonne (3 et 3 partout, sauf
      // le Skink de Lustria qui en prend 2 et 2). Absentes = 3. Voir CONTEXT.md 2.15.
      ConstXmlNbSkill5                  = 'Skill5';
      ConstXmlNbSkill3                  = 'Skill3';
      // Dossier d'icones de niveau propre a l'ethnie, sous \PICTURES\. Balise absente ou
      // vide = dossier NIV generique. Voir CheminNiveauImage dans ChargeRace.
      ConstXmlPictureLevel              = 'PictureLevel';
      // V1 : cout en EP d'entree dans un niveau de carriere magique.
      ConstXmlEntryCost                 = 'EntryCost';
      // Carriere DONT CELLE-CI EST LA SUITE. Balise facultative de <Career>, absente pour
      // l'immense majorite des metiers. Contient un code de metier, ou plusieurs separes
      // par SeparateurMulti. Sa presence, combinee a un premier <Level> superieur a 1, dit
      // qu'on n'entre pas dans ce metier : on y arrive en montant de niveau depuis le
      // parent. Voir CONTEXT.md, chantier des carrieres avancees.
      ConstXmlMetierParent              = 'Parent';
      ConstXmlSousChapitreMetier        = 'SUBCHAPTER_CAREER';
      ConstXmlClass                     = 'Class';
      ConstXmlEquipement                = 'Item';
      ConstXmlArme                      = 'Weapon';
      ConstXmlDamage                    = 'Damage';
      ConstXmlDisponibilite             = 'Availability';
      ConstXmlPorteeArme                = 'Reach';
      ConstXmlPrix                      = 'Price';
      ConstXmlEncombrement              = 'Encumbrance';
      ConstXmlCapacite                  = 'Carries';
      ConstXmlProfilAnimal              = 'AnimalProfile';
      ConstXmlTraitsAnimal              = 'AnimalTraits';
      ConstXmlProfilBateau              = 'BoatProfile';
      ConstXmlProfilVehicule            = 'VehicleProfile';
      ConstPrefixeTraitBateau           = 'SEAOF-BOATTRAIT_';  // libelles decrivant les traits d un bateau (Sea of Claws p.97-99)
      ConstXmlTheme                     = 'Theme';
      ConstXmlAcheteur                  = 'Buyer';
      ConstXmlLocalite                  = 'Locality';
      ConstXmlSaison                    = 'Season';
      ConstXmlQualite                   = 'Quality';
      ConstXmlMains                     = 'Hand';
      ConstXmlMunition                  = 'Ammunition';
      ConstXmlArmure                    = 'Armor';
      ConstXmlArmureSimplifiee          = 'ArmorSimp';
      ConstXmlTrapping                  = 'Trapping';
      ConstXmlEmplacement               = 'Location';
      ConstXmlProtection                = 'ArmorPoint';
      ConstXmlType                      = 'Type';
      ConstXmlNiveau                    = 'Level';
      ConstXmlSalaire                   = 'Salary';
      ConstXmlBonus                     = 'BonusMalus';
      ConstXmlPositifNegatif            = 'Modifier';
      ConstXmlFabrication               = 'Craftsmanship';
      ConstXmlSort                      = 'Sort';
      ConstXmlPorteeSort                = 'Range';
      ConstXmlCible                     = 'Target';
      ConstXmlDuree                     = 'Duration';
      ConstXmlChoix                     = 'Choice';
      ConstXmlAlternative               = 'Alternative';
      ConstXmlEntry                     = 'Entry';
      // Trait d'ETHNIE (bloc DATA_SPECIE_TRAIT, CONTEXT.md 2.41). La balise ne s'appelle
      // PAS 'Trait' : ce nom est deja pris plus haut par ConstXmlTrait, le drapeau
      // "trait de creature" d'un talent (2.15). Deux notions differentes, deux balises.
      ConstXmlSpecieTrait               = 'SpecieTrait';
      ConstXmlTraitOption               = 'Option';
      // Un CareerBonus (bloc DATA_CAREER_BONUS, CONTEXT.md 2.44) porte N paliers. Le
      // palier reutilise ConstXmlNiveau ('Level') comme balise, et ConstXmlOrder pour
      // SON numero - 'Level' ne peut pas servir aux deux.
      ConstXmlCareerBonus               = 'CareerBonus';
      ConstXmlId                        = 'id';
      ConstXmlAttribut                  = 'Attribut';
      ConstXmlOrder                     = 'Order';
      ConstXmlCout                      = 'Cost';
      ConstXmlTexte                     = 'Text';
      ConstXmlLabel                     = 'Label';
      ConstXmlLanguage                  = 'language';
      ConstXmlTypeSort                  = 'TypSpell';
      ConstXmlXpFixe                    = 'XpFixed';
      // <Basic>1</Basic> sur une competence ou une specialisation : competence de base du livre.
      ConstXmlDeBase                    = 'Basic';
      // Talent octroye / retire automatiquement a un niveau de carriere (03/10/2026), en donnees :
      // <GrantAt>CODE_METIER/NIVEAU</GrantAt> = octroi gratuit (NbAugm -1) a l'entree dans ce
      // niveau, lie a ce metier+niveau (TalentCarriereRequise, affichage barre ailleurs) ;
      // <LoseAt>CODE_METIER/NIVEAU</LoseAt> = perdu des ce niveau, ou au-dela. Virtue of the Quest.
      ConstXmlOctroiCarriere            = 'GrantAt';
      ConstXmlRetraitCarriere           = 'LoseAt';
      ConstXmlOptionXpDiv25             = 'XpDiv25';
      ConstXmlOptionFeldo2P             = 'PdfFeldo2P';
      ConstXmlOptionQuickArmor          = 'QuickArmor';
      // Present = le personnage ne gere pas les munitions (absent = gerees, cas des fiches existantes).
      ConstXmlOptionSansMunition        = 'NoAmmo';
      // PDF : present = astérisques numérotées cachées (NoAsterisk) ou seulement leurs montants
      // "+10", "-10%" (NoAmount). Absent = tout affiché (fiches existantes).
      ConstXmlOptionSansAsterisque      = 'NoAsterisk';
      ConstXmlOptionSansMontant         = 'NoAmount';
      // PDF Feldo : present = habillage Warhammer (bandeaux rouges, filets or, zebrage parchemin).
      ConstXmlOptionStylePdf            = 'PdfStyle';
      // Present = habillage Warhammer en niveaux de gris (absent = en couleurs, fiches existantes).
      ConstXmlOptionPdfSansCouleur      = 'PdfNoColor';
      ConstXmlOptionPdfEconomie         = 'PdfInkSaver';
      // Present = le personnage utilise les talents Momentum (regles WFRP5 en WFRP4) : ses talents
      // portent le code MOMENTUM-T_xxx du livre BOOK_MOMENTUM au lieu de RULES-T_xxx.
      ConstXmlOptionMomentum            = 'Momentum';
      ConstCodeLivreMomentum            = 'MOMENTUM';
      // code du livre dans les livres acceptes du perso ([BOOK MOMENTUM]) : a passer a VerifieFiltre
      ConstFiltreLivreMomentum          = 'BOOK MOMENTUM';
      ConstXmlAge                       = 'Age';
      ConstXmlHeight                    = 'Height';
      ConstXmlHairColors                = 'HairColors';
      ConstXmlEyeColors                 = 'EyeColors';
      // Ambitions court/long terme (bloc PDF PdfBlocAmbitions, pdfpersonnage.pas), saisie
      // libre du joueur - jusqu'ici jamais stockees, le bloc PDF ne dessinait qu'un cadre
      // vide a completer a la main. Demande de Nono, 27/09/2026.
      ConstXmlAmbitionCourt              = 'AmbitionShort';
      ConstXmlAmbitionLong               = 'AmbitionLong';
      // Pendant "groupe" des deux precedentes (ambitions du groupe/de la Party, pas du
      // personnage seul) - meme principe, saisie libre. Stockees sur CHAQUE personnage en
      // attendant le chantier GROUPE (A FAIRE.txt, biens partages) qui unifiera un jour une
      // entite groupe ; jusque-la, chaque membre garde sa propre copie du texte. 27/09/2026.
      ConstXmlAmbitionGroupeCourt        = 'AmbitionPartyShort';
      ConstXmlAmbitionGroupeLong         = 'AmbitionPartyLong';
      // Nom du fichier GROUPE_<Nom>.xml auquel ce personnage appartient, absent = solo.
      // Etape 1 de la conception CONTEXT.md 2.100, 27/09/2026.
      ConstXmlGroupeId                   = 'GroupeId';
      // Objets crees dans WinPersonnage, propres au personnage (sans livre) : bloc de fiche
      // dont le contenu a le format d'un DATA_TRAPPING de livre. Ils sont injectes dans les
      // listes sous ce libelle de livre a chaque chargement de la fiche. 08/10/2026.
      ConstXmlObjetsPropres              = 'CUSTOM_ITEMS';
      ConstLivreObjetsPropres            = 'PERSO-OBJETS';
      ConstPrefixeObjetPropre            = 'PERSO-OBJ-';
      // Qualites creees pour un objet propre (<BonusMalus>) : meme bloc, meme injection. Le code
      // garde WEAPB / ARMOB, que la liste des qualites de WinLivre et du PDF reconnait.
      ConstPrefixeQualiteArme            = 'PERSO-WEAPB-';
      ConstPrefixeQualiteArmure          = 'PERSO-ARMOB-';
      ConstXmlModifieAttribut           = 'ModifyCarac';
      // Pendant de ModifyCarac pour un effet permanent dont la table source fixe le montant
      // par un jet de de (ex. Unofficial Grimoire, Debilitation "-1d10 Toughness") plutot
      // qu'une valeur fixe : le contenu de la balise donne la face du de (10), tire UNE FOIS a
      // l'ajout de l'entree sur la fiche et mémorisé (StructurePersonnagePathologie.
      // ValeurAleatoire, chargepersonnage.pas) - jamais retire au recalcul, contrairement a
      // Facteur qui est constant. Ajout du 27/09/2026, a la demande de Nono.
      ConstXmlModifieAttributAleatoire  = 'ModifyCaracAleatoire';
      ConstXmlModifieCompetence         = 'ModifySkill';
      ConstXmlModifieCompetenceAttribut = 'ModifySkillAttribut';
      ConstXmlModifieArmure             = 'ModifArmour';
      // Pendant "par type d'arme" des deux ci-dessus, ajoute au 2.44/3d-3 pour le palier
      // Knight des Ordres de Chevalerie ("+10 CC avec les lances, les epees a deux mains
      // ou les boucliers") : un bonus qui ne s'applique qu'a CERTAINES armes d'une meme
      // competence, donc impossible a representer par ModifySkill seul (qui bonifie toute
      // la competence). name= vise StructureArme.TypeArme (nouveau champ, non un code de
      // competence) ; l'attribut skill= optionnel restreint en plus a une competence
      // precise (ex. "Two-handed Swords" = TypeArme SWORD + skill RULES-COMPCOMB_2M, pour
      // exclure l'Epee de base ou les armes d'escrime qui portent aussi TypeArme SWORD).
      ConstXmlModifieArme               = 'ModifyWeapon';
      // Attribut (pas balise - collision avec ConstXmlDataSkill = 'DATA_SKILL' ci-dessus,
      // repere a la compilation) portant le filtre CodeCompetence facultatif de
      // <ModifyWeapon>.
      ConstXmlModifieArmeCompetence     = 'skill';
      // Pendant "degat" de ModifyWeapon, meme moule mais Facteur additionne au Degat
      // (CalculDegat) au lieu d'un pourcentage - CONTEXT.md, chantier moteur generique,
      // migration de Mighty Blow/Accurate Shot (11/09/2026). Cible ne vise pas un type
      // d'arme precis (StructureArme.TypeArme) mais une CATEGORIE large - voir
      // ConstCibleModifieDegatCC/CT ci-dessous - ces deux talents bonifient TOUTES les
      // armes de contact/a distance, pas une famille en particulier.
      ConstXmlModifieDegat              = 'ModifyDamage';
      // Cinquieme pendant du meme moule, cote bateau : <ModifBoat name="MSAIL">-1</ModifBoat>
      // sur un DATA_TRAPPING d'amenagement (Fore-and-Aft Rudder, Smoothing...). Cible =
      // colonne du profil (CREW/MSAIL/MOAR/MAN/SIZE/T/W). 24/09/2026, chantier "AMENAGEMENTS
      // DE BATEAU : CALCUL DE L'EFFET SUR LE NAVIRE".
      ConstXmlModifieBateau             = 'ModifBoat';
      // Sixieme pendant du meme moule, cote Reload d'une arme a distance : <Modificateur
      // Type="ModifyReloadRate" Cible="RELOAD" Facteur="-1"/> sur un DATA_CRAFTMANSHIP
      // (Rune of Reloading, Dwarf Player's Guide). Facteur additionne au chiffre de la
      // Qualite RULES-WEAPB_RELOAD "Reload N" de l'arme (FabricationModificateurQualite, meme
      // mecanisme que Rune of Cleaving/ModifyDamage) - plancher a 1 pour une arme portant
      // la Qualite Salvo (UPINA-WEAPB_SALVO, Up in Arms), qui ne se recharge jamais totalement.
      // Affichage pas encore cable (chantier ouvert, A FAIRE.txt). 26/09/2026.
      ConstXmlModifieRechargement       = 'ModifyReloadRate';
      ConstCibleModifieRechargement     = 'RELOAD';
      // Septieme pendant du meme moule, generalisation de BonusAccurate (qualite d'arme
      // catalogue RULES-WEAPB_ACCURATE, +10 pour toucher) a une fabrication/rune : <Modificateur
      // Type="ModifyAccurate" Cible="ACCURATE" Facteur="10"/> sur un DATA_CRAFTMANSHIP
      // (Rune of Accuracy, Dwarf Player's Guide, Max 3 - Niveau multiplie deja le Facteur
      // dans FabricationModificateurQualite). S'ajoute a Pourcent a cote du Ord(Pos(
      // BonusAccurate, PArme.ListeBonus)) existant, dans les DEUX blocs armes de
      // pdfpersonnage.pas (meme reflexe que Reload/Rune of Reloading). 27/09/2026.
      ConstXmlModifieAccuracy           = 'ModifyAccurate';
      ConstCibleModifieAccuracy         = 'ACCURATE';
      // Les qualites d'ARME portent leur effet en donnees, plus de code de qualite en dur
      // (03/10/2026) : <ModifyAccurate name="ACCURATE">10</ModifyAccurate> sur Accurate,
      // <ModifyReloadRate name="RELOAD">1</ModifyReloadRate> sur Reload (Facteur x N = chiffre de
      // base), <ModifyReloadMin name="RELOAD">1</ModifyReloadMin> sur Salvo (plancher du chiffre
      // de Reload), <ModifArmour name="RULES-ARMOL_SHIELD">1</ModifArmour> sur Shield (PA = Facteur x N).
      // Lus par FabricationModificateurQualite sur PArme.ListeBonus (meme liste que les runes).
      ConstXmlModifieRechargementMin    = 'ModifyReloadMin';
      // Nombre de mains du personnage : base humanoide + <ModifyHands name="HANDS">-1</ModifyHands>
      // sur toute source (main perdue : mutation, affliction, blessure ; main de plus : creature).
      // Bonus aux tests de lutte (Tentacles d'un familier, Realms of Sorcery 7-2 : +10 %). Charge et AFFICHE seulement,
      // comme ModifyTestSL/ModifyCN : la lutte n'est ni une competence ni une arme, rien a calculer. 18/10/2026.
      ConstXmlModifieLutte              = 'ModifyGrapple';
      ConstCibleModifieLutte            = 'GRAPPLE';
      ConstXmlModifieMains              = 'ModifyHands';
      ConstCibleModifieMains            = 'HANDS';
      ConstMainsBase                    = 2;
      // Malus/bonus de competence d'une piece PORTEE (qualite d'armure : <Modifier name="competence">-10),
      // distinct de ModifySkill : il alimente la colonne "avec equipement" du PDF (module par
      // Practical/Unreliable piece par piece), jamais le Total. Decision Nono 04/10/2026.
      ConstXmlModifieCompetenceEquip    = 'ModifySkillGear';
      // La competence (Cible) entre dans les competences de METIER de toutes les carrieres du personnage,
      // au palier donne par la valeur (1 = des le niveau 1) : Perfect Pitch -> Chant. Remplace <Skill>/<AddSkill> des talents.
      ConstXmlModifieCompetenceCarriere = 'AddSkillToCareer';
      // Bonus de Success Levels sur un test de competence (Robes de Winds of Magic : +1/+2/+3 SL
      // en Channelling). Charge comme les autres modificateurs de fabrication mais seulement
      // AFFICHE (resume de la fabrication), jamais calcule dans une feuille de sort. 29/09/2026.
      ConstXmlModifieTestSL             = 'ModifyTestSL';
      // Reduction de CN des sorts d'une Lore (Enchanted Staff de Winds of Magic : -1 CN, min 0).
      // Comme ModifyTestSL : charge et AFFICHE seulement, jamais calcule. 29/09/2026.
      ConstXmlModifieCN                 = 'ModifyCN';
      // Reduction fixe des Degats RECUS (Amulet of Thrice-Blessed Copper : -1 a toutes les attaques
      // portees contre le porteur). Comme ModifyTestSL/ModifyCN : charge et AFFICHE seulement, la
      // feuille ne suit pas les degats subis. 30/09/2026.
      ConstXmlModifieDegatRecu          = 'ModifyDamageReceived';
      // Quatrieme pendant du meme moule que ModifyCarac/ModifySkill/ModifyWeapon, pour les
      // paliers de CareerBonus qui n'ont AUCUN equivalent chiffre (palier 4 "Knight of the
      // Inner Circle" de la quasi-totalite des Ordres de Chevalerie - trait automatique
      // conditionnel, relance de des, Blessures Critiques en plus, arme qui devient
      // magique, ignorer une Qualite, immunite...). <SpecialRule name="Nom court">Texte
      // descriptif</SpecialRule> : name= (ConstXmlData) porte le libelle court, le contenu
      // texte la description complete. Affichee sur le PDF comme un "talent virtuel" de
      // plus dans le bloc Talents - decision Nono, CONTEXT.md 2.51, 08/09/2026.
      ConstXmlSpecialRule               = 'SpecialRule';
      // Cinquieme pendant du meme moule (ModifyCarac/ModifySkill/ModifyWeapon/SpecialRule),
      // pour un palier de CareerBonus qui offre un CHOIX parmi les competences RACIALES DU
      // PERSONNAGE (ex. palier 4 "Knight of the Inner Circle" du Reiksguard, Nations of
      // Mankind p.8 : "choose 3 Empire Province Racial Skills to give a free +5 Advances
      // to"). Pas de liste de codes a saisir : le pool est implicitement les competences de
      // l'ETHNIE DU PERSONNAGE (ListRaceCompetence, meme source que TabRaceCompetence en
      // creation), pas une liste portee par le livre. <SkillChoice Count="3" Value="5"/> -
      // Count = nombre de competences a choisir, Value = nombre d'avancees gratuites
      // accordees a CHACUNE (donc Count x Value avancees au total). Champ dedie prevu cote
      // fiche personnage (pas CreationCompetence35/SUBCHAPTER_SKILLSPECIE, qui vient de la
      // creation et non d'une appartenance) - a faire dans un point de compilation suivant.
      ConstXmlSkillChoice               = 'SkillChoice';
      ConstXmlSkillChoiceCount          = 'Count';
      ConstXmlSkillChoiceValue          = 'Value';
      ConstXmlOpinions                  = 'OPINIONS';
      ConstXmlOpinion                   = 'Opinion';
      ConstXmlTarget                    = 'target';
      ConstXmlSource                    = 'source';

      // Generalisation du case de calcul de talents de pdfpersonnage.pas (voir
      // ChargeTalentEffet) : <Effet Cible="..." Forme="..." Facteur="..." Carac="..."/>
      // pose sur N'IMPORTE QUEL talent, remplace le repérage par code de talent en dur.
      // "Carac" et non "Attribut" pour ne pas reprendre le nom de la balise <Attribut>
      // existante (ConstXmlCarac ci-dessus), qui porte les caracteristiques de TEST du
      // talent - notion differente, meme mot aurait pretait a confusion.
      // "ConstXmlEffetTalent" et non "ConstXmlEffet" : ce dernier existe deja (l.132),
      // jamais utilise ailleurs dans le projet (verifie), mais on ne le reprend pas sans
      // savoir a quoi il etait destine a l'origine.
      ConstXmlEffetTalent               = 'Effet';
      ConstXmlEffetCible                = 'Cible';
      ConstXmlEffetForme                = 'Forme';
      ConstXmlEffetFacteur              = 'Facteur';
      ConstXmlEffetCarac                = 'Carac';

      // Moteur generique de bonus/malus "par source" (chargemodificateur.pas, CONTEXT.md) :
      // <Modificateur Type="ModifySkill|ModifyWeapon|..." Cible="..." Facteur="N"/>, posable
      // sur n'importe quel Talent. Balise NEUVE et non <ModifySkill>/<ModifyWeapon> : ces deux
      // noms sont deja pris - ModifySkill par CareerBonus (bonus chiffre) ET par <Talent> lui
      // meme (ConstXmlModifieCompetence, annotation "Inverse de"/"Bonus" a l'affichage, sans
      // rapport). Type reutilise les valeurs ConstXmlModifieCompetence/ConstXmlModifieArme
      // existantes, Cible/Facteur les constantes ci-dessus.
      ConstXmlModificateur              = 'Modificateur';
      ConstXmlModificateurFiltre        = 'Filtre';

      // Les trois Formes de <Effet>, vocabulaire ferme.
      ConstFormeEffetAdditif                = 'Additif';
      ConstFormeEffetProportionnelAttribut  = 'ProportionnelAttribut';
      ConstFormeEffetDrapeau                = 'Drapeau';

      // Les Cibles de <Effet> aujourd'hui prises en charge, vocabulaire ferme : les noms
      // des variables de calcul historiques de pdfpersonnage.pas (Mouv/Chance/Determine ne
      // sont pas ici, deja sorties du case le 06/09/2026 vers le mecanisme ModifyCarac).
      // TBonusCC/TBonusCT ne sont plus ici depuis le 11/09/2026 - Mighty Blow/Accurate Shot
      // migres vers ModifyDamage (ConstCibleModifieDegatCC/CT ci-dessous), meme mecanisme
      // "par source" que ModifyWeapon plutot que ce moteur Effet dedie.
      ConstCibleEffetDurACuire           = 'DurACuire';
      ConstCibleEffetBonusEncomb         = 'BonusEncomb';
      ConstCibleEffetBonusSprint         = 'BonusSprint';
      ConstCibleEffetAmePure             = 'AmePure';
      // Cibles de <Modificateur Type="ModifyDamage">, vocabulaire ferme : categorie large de
      // l'arme (Corps-a-Corps/Corps-a-Tir), pas un type precis - meme convention que
      // EquipementCC/EquipementCT (prefixe de CodeArme) plus bas dans ce fichier.
      ConstCibleModifieDegatCC           = 'CC';
      ConstCibleModifieDegatCT           = 'CT';
      // Sorts et Miracles : donnee seulement, aucun calcul de degats de sort cote PDF (CONTEXT.md 2.105).
      ConstCibleModifieDegatSort         = 'SORT';

      // constantes de passage d'étapes de création de personnages
      ConstSuivant			= 1;

      // constantes de caractéristiques
      ConstCaracCC			= 'RULES-ATTR_WS';
      ConstCaracCT			= 'RULES-ATTR_BS';
      ConstCaracF			= 'RULES-ATTR_S';
      ConstCaracE			= 'RULES-ATTR_T';
      ConstCaracI			= 'RULES-ATTR_I';
      ConstCaracAg			= 'RULES-ATTR_Ag';
      ConstCaracDex			= 'RULES-ATTR_Dex';
      ConstCaracInt			= 'RULES-ATTR_Int';
      ConstCaracFM			= 'RULES-ATTR_WP';
      ConstCaracSoc			= 'RULES-ATTR_Fel';
      ConstCaracDestin		        = 'RULES-ATTR_Fate';
      ConstCaracResil			= 'RULES-ATTR_Resil';
      ConstCaracPointSupp               = 'RULES-ATTR_Supp';
      ConstCaracBlessure                = 'RULES-ATTR_Wound';
      ConstCaracMouvement               = 'RULES-ATTR_Move';
      ConstBonusCaracCC			= 'BATTR_WS';
      ConstBonusCaracCT			= 'BATTR_BS';
      ConstBonusCaracF			= 'BATTR_S';
      ConstBonusCaracE			= 'BATTR_T';
      ConstBonusCaracI			= 'BATTR_I';
      ConstBonusCaracAg			= 'BATTR_Ag';
      ConstBonusCaracDex		= 'BATTR_Dex';
      ConstBonusCaracInt		= 'BATTR_Int';
      ConstBonusCaracFM			= 'BATTR_WP';
      ConstBonusCaracSoc		= 'BATTR_Fel';

      // Cout Xp évolution carrière
      ConstXpNouveauNiveau              = 100;
      ConstXpChangerMetier              = 100;
      ConstXpChangerMetierIncomplet     = 200;
      ConstXpChangerClasse              = 100;

      // image de fond et icones - generales, communes a toutes les editions
      ConstCheminLogo1                  = '\PICTURES\BACK\LOGO1.png';
      ConstCheminLogo2                  = '\PICTURES\BACK\LOGO2.png';
      ConstCheminBack                   = '\PICTURES\BACK\BACK.jpg';
      ConstCheminSheetTitle             = '\PICTURES\BACK\SHEETTITLE.png';
      ConstCheminSheetPage              = '\PICTURES\BACK\SHEETPAGE.png';
      ConstCheminSheetBack              = '\PICTURES\BACK\UNDER.png';
      ConstCheminXp                     = '\PICTURES\BACK\XP.jpg';
      ConstCheminScroll                 = '\PICTURES\BACK\SCROLL.png';
      ConstCheminBoutonRace             = '\PICTURES\BACK\BUTTON_SPECIES.png';
      ConstCheminBoutonMetier           = '\PICTURES\BACK\BUTTON_CLASS.png';
      ConstCheminBoutonCompetence       = '\PICTURES\BACK\BUTTON_SKILL.png';
      ConstCheminBoutonTalent           = '\PICTURES\BACK\BUTTON_TALENT.png';
      ConstCheminBoutonArme             = '\PICTURES\BACK\BUTTON_WEAPON.png';
      ConstCheminBoutonArmure           = '\PICTURES\BACK\BUTTON_ARMOR.png';
      ConstCheminBoutonSort             = '\PICTURES\BACK\BUTTON_SPELL.png';
      ConstCheminImageArme              = '\PICTURES\WEAPON\';
      ConstCheminImageArmure            = '\PICTURES\ARMOR\';
      // ConstCheminImageNiveau/ConstCheminImageNiveauRacine sont passées en Var (section
      // plus bas) le 14/09/2026 (CONTEXT.md §2.70) pour suivre ValVersion, comme
      // ConstCheminImageRace/Metier/Sort - déclaration déplacée, pas supprimée.
      ConstCheminImagePolice            = '\FONT\';

      // chemin des textes
      ConstCheminLivreExport            = '\DATABASE_EXPORT\';
      // Libellés/messages d'interface (RULES-LAB_*/RULES-MESS_*) : sortis du RULESBOOK vers un
      // livre a part le 13/09/2026 (demande de Nono, CONTEXT.md §2.70) pour ne pas etre
      // duplique entre WFRP4\ et WFRP5\. Vit directement sous DATABASE\, hors du dossier
      // d'edition, charge par un appel explicite (pas de scan) - warhammersource.pas.
      ConstCheminInterface              = '\DATABASE\';
      ConstFichierInterface             = 'INTERFACE';
      ConstFichierInterfaceFrancais     = 'INTERFACE_FRANCAIS';
      // Valeur du tag <BOOK> d'INTERFACE.Xml/INTERFACE_FRANCAIS.Xml (Livre dans ListTexte/
      // ListTraduction) - sert de filtre à Traduit() pour retraduire les libellés
      // d'interface sans toucher aux autres livres (CONTEXT.md §2.70).
      ConstInterfaceBook                 = 'INTERFACE';
      ConstFichierIni                   = '\INI.TXT';
      ConstCheminTravail                = '\TRAVAIL\';
      ConstIniLangue                    = 'LANG=';
      // Préfixe seul (pas de '=') depuis le 13/09/2026 : une ligne par édition dans le .INI,
      // ex. 'BOOKWFRP4=', 'BOOKWFRP5=' (ChargeIni/SauveIni, warhammersource.pas, CONTEXT.md
      // §2.70).
      ConstIniLivre                     = 'BOOK';
      // Préfixe seul (pas de '='), même principe que ConstIniLivre : une ligne par livre
      // dans le .INI, ex. 'OPTIONRULEBOOK=QUICKARMOUR' (ChargeIni/SauveIni,
      // warhammersource.pas, A FAIRE.txt "TOGGLE .INI PAR LIVRE", 22/09/2026).
      ConstIniOption                    = 'OPTION';
      // Code de l'option Quick Armour (Rulebook p.301, les 3 <ArmorSimp>) - premier cas
      // du chantier toggle .INI.
      ConstOptionQuickArmour            = 'QUICKARMOUR';
      // Signes astraux (DATA_STARSIGN, Archives of the Empire II p.39) et carriere
      // alternative (DATA_RULE/DATA_CAREER_ROLL, Sea of Claws et Lustria) - etendus au
      // toggle .INI le 22/09/2026 (CONTEXT.md 2.89).
      ConstOptionStarSign               = 'STARSIGN';
      ConstOptionCareerAlt              = 'CAREERALT';
      // Cases de l'etape Livre de WinCreation (creation en cours seulement, cochees par defaut) :
      // cle = prefixe + livre, dans ReglesDesactiveesCreation.
      ConstCleSousMetier                = 'SOUSMETIER-';   // DATA_CAREER_SUBCHOICE (second jet)
      ConstCleChoixMetier               = 'CHOIXMETIER-';  // DATA_SPECIE_CAREER_CHOICE (choix par espece)
      ConstCleMutationDepart            = 'MUTATION-';     // StartingMutation des regles V2 (ajout a l'origine)
      ConstIniVersion                   = 'VERSION=';
      // Langue de l'interface (RULES-LAB_*/RULES-MESS_*), décorrélée de ConstIniLangue (qui
      // reste la langue des livres/données) - Nono, 13/09/2026, CONTEXT.md §2.70.
      ConstIniLangueInterface           = 'LANGINTERFACE=';
      // Unite de taille proposee par defaut dans WinPhysique : CM ou INCH (absente : CM si les
      // livres sont en francais, INCH sinon). Chaque fiche garde l'unite de sa valeur (HeightUnit).
      ConstIniUniteTaille               = 'HEIGHTUNIT=';
      ConstIniImagesDefautSeul          = 'DEFAULTLICENSELESS=';
      ConstUniteCm                      = 'CM';
      ConstUniteInch                    = 'INCH';
      ConstXmlHeightUnit                = 'HeightUnit';
      ConstAnglais                      = 'ENGLISH';

      // Police
      ConstPoliceTaille                 = 10;
      ConstPoliceBtTaille               = 20;
//
      // Souris
      WM_LBUTTONDOWN                    = $0201;
      WM_LBUTTONUP                      = $0202;

      // case à cocher
      CheckCharUnchecked                = #$E2#$98#$90; // U+2610 en UTF-8 (octets, evite le cast Unicode vers AnsiString)
      CheckCharChecked                  = #$E2#$98#$91; // U+2611 en UTF-8

      // couleurs générales
      CouleurGrisFonce: TColor          = $B4B4B4;
      CouleurDefColor:  Tcolor          = $E8F0F0;
      CouleurDefInverse:Tcolor          = $130000;
      CouleurButton:    Tcolor          = $ACBDBD;

      // compétence de race
      NbMaxCompetence                   = 12;

      // Talents qui donnent des bonus
      TalentGenerique                   = 'RULES-T*';
      // TalentAmePure / TalentDurACuire / TalentCostaud / TalentCoutPuissant /
      // TalenttirPrecis / TalentSprinteur SUPPRIMEES le 10/09/2026 : generalisees en
      // <Effet Cible="..."/> (ChargeTalentEffet, PersonnageTalentEffet dans
      // pdfpersonnage.pas), plus de code de talent en dur pour ces six-la. Voir
      // A FAIRE.txt "GENERICISER LE CASE DE CALCUL DES TALENTS".
      // TalentVeloce / TalentChanceux / TalentObstine deja mortes depuis le 06/09/2026
      // (migrees vers ModifyCarac/PersonnageTalentAttributModif) mais pas encore
      // retirees ici - hors perimetre de ce chantier, voir A FAIRE.txt.
      TalentHaineSacree                 = 'T_HOLY_HATRED';
      // TalentSortBenediction / TalentSortMiracle / TalentSortMagieMineure / TalentSortDomaine
      // ('T0012'/'T0080'/'T0089'/'T0088') SUPPRIMEES le 23/08/2026 : la liste des talents qui
      // donnent acces aux sorts vit maintenant dans les donnees, balises <Magic>/<SpellMode>
      // (voir ConstXmlMagie plus haut). Ajouter un talent magique ne demande plus de recompiler.
      // CONTEXT.md 2.18.

      // Type d'équipement et de sorts
      EquipementCC                      = 'COMB_';
      EquipementCT                      = 'PROJ_';
      EquipementMU                      = 'MUNI_';
      // Code d'un objet de texte pur propre a un personnage (TEXTE-1, TEXTE-2...), sans fiche ni livre.
      PrefixeEquipementTexte            = 'TEXTE-';
      // Code d'une ligne Familier (FAMILIER-1...) : NomLibre porte le nom du personnage familier.
      PrefixeEquipementFamilier         = 'FAMILIER-';
      EquipementAR                      = 'ARMO_';
      EquipementTR                      = 'TRAP_';
      EquipementQualite                 = '(Q)';
      // Fabrication marqueur posee sur un objet (Q) tant que le joueur n a pas choisi de vraie qualite
      // Case a cocher de l equipement de niveau (WinPersonnage), decochee par defaut
      CaseVide                          = '[   ]';
      CaseCochee                        = '[ X ]';
      CodeQualiteAAjouter               = 'RULES-QUALITY_AJOUT';
      BonusBras                         = 'RULES-ARMOL_ARM';
      BonusCorps                        = 'RULES-ARMOL_BODY';
      BonusJambes                       = 'RULES-ARMOL_LEG';
      // Emplacement de PROTECTION seulement (jamais une piece d'armure) : les PA du bouclier quand on s'en sert pour parer.
      BonusBouclier                     = 'RULES-ARMOL_SHIELD';
      BonusTete                         = 'RULES-ARMOL_HEAD';
      SortBenediction                   = 'BENED_';
      SortMiracle                       = 'MIRAC_';
      SortMineur                        = 'SPELL_';
      SortArcane                        = 'ARCAN_';
      SortCouleur                       = 'COLOR_';
      FabricationBonus                  = 'BONUS';
      FabricationMalus                  = 'MALUS';
      // Meme convention que FabricationBonus/FabricationMalus (valeur du champ <Modifier>),
      // mais signale en plus le cas Bulky (Rulebook p.284) : la piece reste a Enc 1 meme
      // portee, au lieu du plancher 0 habituel. FabricationEstBulky (chargefabrication.pas)
      // le lit. A FAIRE.txt, chantier qualites de fabrication.
      FabricationBulky                  = 'BULKY';
      // Modulent le malus ARMOB (PersonnageArmureBonusCompetenceModifPortee, chargepersonnage.pas)
      // de LA piece qui porte la qualite/le defaut : Practical le reduit de 10 (plancher 0),
      // Unreliable le double (Rulebook, DATA_CRAFTMANSHIP). FabricationEstPractical/
      // FabricationEstUnreliable (chargefabrication.pas) les lisent. CONTEXT.md 2.59.
      FabricationPractical               = 'PRACTICAL';
      FabricationUnreliable              = 'UNRELIABLE';
      SortChaos                         = 'CHAOS_';
      // Les constantes RaceHumain/RaceElf/RaceNain/... ('SPECIE_HUMAN', 'SPECIE_ELF', ...)
      // ont été supprimées le 20/08/2026 : elles n'étaient utilisées nulle part, et la liste
      // des RACES est désormais portée par le bloc XML DATA_RACE (voir ChargeEspece.pas).
      CorruptionPhysique                = 'RULES-CORRUPTION_PHYSICAL';
      CorruptionMentale                 = 'RULES-CORRUPTION_MENTAL';
      CorruptionDivine                  = 'RULES-CORRUPTION_DIVINE';
      CorruptionMutation                = 'RULES-CORRUPTION_MUTATION';   // Tome of Corruption (WFRP2), tirage D1000
      // "GM's Choice" (Physical Corruption Table, 96-00) - pas une vraie mutation, une
      // instruction de consulter le MJ (CONTEXT.md §2.7). Seule la table Physical a ce cas ;
      // Mental n'a pas d'entrée équivalente à 96-00 ("Worried Jitters", une entrée normale).
      CorruptionChoixMJ                 = 'CORPHY_GM_S_CHOICE';

      KEY_ESC                           = #27;

      ConstLangue                           = '%LANG%';
      ConstLivre                            = '%BOOK%';
      ConstRulesBook                        = 'BOOK RULESBOOK';
      ConstBookUpInArms                     = 'BOOK UP IN ARMS';
      ConstBookWindsOfMagic                 = 'BOOK WINDS OF MAGIC';
      ConstBookArchiveEmpire1               = 'BOOK ARCHIVES OF THE EMPIRE I';
      ConstBookArchiveEmpire2               = 'BOOK ARCHIVES OF THE EMPIRE II';
      ConstBookArchiveEmpire3               = 'BOOK ARCHIVES OF THE EMPIRE III';
      ConstBookRoughNightsHardDays          = 'BOOK ROUGH NIGHTS AND HARD DAYS';
      ConstBookDeathOnTheReikCompanion      = 'BOOK DEATH ON THE REIK COMPANION';
      ConstBookEnemyInShadowsCompanion      = 'BOOK ENEMY IN SHADOWS COMPANION';
      ConstBookMiddenheimCityOftheWhiteWolf = 'BOOK MIDDENHEIM CITY OF THE WHITE WOLF';
      ConstBookSalzenmundCityOfSaltAndSilver= 'BOOK SALZENMUND CITY OF SALT AND SILVER';
      ConstBookSeaOfClaws                   = 'BOOK SEA OF CLAWS';
      ConstBookTheHornedRatCompanion        = 'BOOK THE HORNED RAT COMPANION';

      ConstDebutAttribut                    = 'ATTR_';
      ConstDebutCompetence                  = 'COMP';
      ConstSelectionne                      = 'X';
      ConstCodeRaceCreationGenerique        = 'x';

      ConstLivreOfficiel                    = 'O';
      ConstLivreFacultatif                  = 'F';
      // Valeur de la balise <OFFICIAL> d'un livre de fan (0 = livre de règles, 1 = supplément
      // officiel, 2 = livre de fan). Sert à la fois au 'F' de la colonne O/F du tableau des
      // livres et au préfixe "(F)" devant le nom du livre (chargetexte.pas, GetTexteLibelle).
      ConstLivreFanOfficiel                 = 2;

      ConstLabSelSpe                        = 'RULES-LAB_129';
      ConstLabAdd                           = 'RULES-LAB_143';
      // Ligne "aucune" en tete de la liste des appartenances proposees. Elle est
      // toujours presente : le programme ne sait pas deviner qu'un soldat est un
      // mercenaire sans regiment. CONTEXT.md 2.44.
      ConstLabSansAppartenance              = 'RULES-LAB_178';

      ConstTransparent                      = '_TRANS';

      ConstPAttribut                        = 'PAttribut';
      ConstPTexte                           = 'PTexte';
      ConstPCompetence                      = 'PCompetence';
      ConstPTalent                          = 'PTalent';
      ConstPRace                            = 'PRace';
      ConstPEspece                          = 'PEspece';
      ConstPNation                          = 'PNation';
      ConstPTrait                           = 'PTrait';
      ConstPTraitOption                     = 'PTraitOption';
      ConstPCareerBonus                     = 'PCareerBonus';
      ConstPRegle                           = 'PRegle';
      ConstPMetier                          = 'PMetier';
      ConstPArme                            = 'PArme';
      ConstPArmeBonus                       = 'PArmeBonus';
      ConstPArmure                          = 'PArmure';
      ConstPArmureSimplifiee                = 'PArmureSimplifiee';
      ConstPTrapping                        = 'PTrapping';
      ConstPArmureBonus                     = 'PArmureBonus';
      ConstPSort                            = 'PSort';
      ConstPFabrication                     = 'PFabrication';
      ConstPCorruptionTable                 = 'PCorruptionTable';
      ConstPRaceCouleur                     = 'PRaceCouleur';
      ConstPMetierNiveau                    = 'PMetierNiveau';
      ConstPDisease                          = 'PDisease';
      ConstPAdaptation                      = 'PAdaptation';
      ConstPSigneAstral                     = 'PSigneAstral';
      ConstPAffliction                      = 'PAffliction';

      ConstCEsquive                         = 'RULES-COMP_DODGE';
      ConstCCalme                           = 'RULES-COMP_COOL';
      ConstCResitance                       = 'RULES-COMP_ENDURANCE';
      ConstCCommandement                    = 'RULES-COMP_LEADERSHIP';
      ConstCIntuition                       = 'RULES-COMP_INTUITION';

      ConstCompetenceInverseDe              = 'ChooseDice';
      ConstCompetenceBonus                  = 'Bonus';

      ConstOrigineRace                      = 'RACE';
      ConstOrigineMetier                    = 'METIER';

Var
  NomPersonnage:       String;
  CodeLivre:           String;
  NomLivre:            String;
  NeedUpdate:          Boolean = false;
  SelectWinMetierRace: String = '';
  ChoixWinMetierRace:  String = '';
  SelectWinRace:       String = '';
  ChoixWinRace:        String = '';
  SelectWinMetier:     String = '';
  SelectWinArme:       String = '';
  // Codes des competences du personnage (virgules), poses par WinPersonnage avant d ouvrir WinWeapon :
  // non vide = la case "selon mes competences" est proposee. 20/09/2026.
  SelectWinArmeCompetences: String = '';
  ChoixWinArme:        String = '';
  // Code de l'arme / armure a montrer (double-clic sur l'equipement de WinPersonnage) : la fiche
  // s'ouvre en consultation, ligne deja selectionnee. Vide = comportement habituel.
  VoirWinArme:         String = '';
  VoirWinArmure:       String = '';
  // Selection d'un objet du catalogue DATA_TRAPPING depuis WinPersonnage (WinEquipement).
  SelectWinTrapping:   String = '';
  ChoixWinTrapping:    String = '';
  SelectWinArmure:     String = '';
  ChoixWinArmure:      String = '';
  SelectWinArmureSimp: String = '';
  ChoixWinArmureSimp:  String = '';
  SelectWinSort:       String = '';
  ChoixWinSort:        String = '';
  SelectWinFabrication:String = '';
  SelectWinFabricationType:String = '';
  ChoixWinFabrication: String = '';
  SelectWinTalent:     String = '';
  ChoixWinTalent:      String = '';
  SelectWinAttribut:   String = '';
  ChoixWinAttribut:    String = '';
  SelectWinBase:       Boolean = False;   // filtre des carrieres V1 / V2 : carrieres de base seulement
  ChoixWinBase:        Boolean = False;
  SelectWinCompetence: String = '';
  ChoixWinCompetence:  String = '';
  RecherchePersonnage: String = '';
  ChoixWinTypeFichier: String = '';
  SelectWinEquipement: String = '';
  SelWinLibelle:       String = '';
  SelWinType:          String = '';
  ChoixWinEquipement:  String = '';
  // Choix d'une APPARTENANCE (regiment, ordre, culte) dans WinSpecialisation. Choix... =
  // la liste des codes candidats, separes par des virgules, calculee par
  // AppartenancesCandidates ; Select... = le code retenu, VIDE si le joueur a repondu
  // "aucune" ou ferme la fenetre. ChoixWinTypeFichier vaut alors ConstXmlDataCareerBonus,
  // aucune constante de type n'a eu a etre creee. CONTEXT.md 2.44.
  SelectWinCareerBonus:String = '';
  ChoixWinCareerBonus: String = '';
  // Choix de N competences RACIALES au titre d'un <SkillChoice> d'appartenance (ex.
  // Reiksguard palier 4) - WinChoixCompetenceAppartenance. ChoixCompetenceAppartenanceRace
  // = l'ethnie DONT le pool de competences vient (Personnage.Race, pas celle du
  // CareerBonus) ; ChoixCompetenceAppartenanceCount = combien en choisir.
  // SelectCompetenceAppartenance = les codes retenus separes par des virgules, VIDE si le
  // joueur ferme sans valider (le bouton Valider n'est actif qu'a exactement Count coches
  // - jamais de reponse partielle).
  ChoixCompetenceAppartenanceRace:  String  = '';
  ChoixCompetenceAppartenanceCount: Integer = 0;
  SelectCompetenceAppartenance:     String  = '';
  // Choix de Grail Virtue (NATIO-T0002) dans WinSpecialisation, restreint aux noms deja
  // pris en Knightly Virtue (NATIO-T0001) sur la fiche - le livre l'exige (Nations of
  // Mankind p.13). ChoixWinVertuGrail = la liste des codes NATIO-T0002_* candidats,
  // separes par des virgules, calculee par TabAugmentationTalentDblClick
  // (winpersonnage.pas) a partir de TabTalent ; VIDE = ce n'est pas un choix de Grail
  // Virtue, ChargeSpecialisation retombe sur son comportement habituel. Un seul
  // consommateur aujourd'hui, code en dur - meme esprit que le SkillChoice du Reiksguard
  // (2.51) en son temps. CONTEXT.md 2.78.
  ChoixWinVertuGrail:               String  = '';
  SelectWinLivre:      String = '';
  ChoixWinLivre:       String = '';
  ListeLivre:          String = '';
  // Sélection de livres cochés, une entrée par édition (Name=Version, Value=liste des
  // codes) - une seule liste partagée entre éditions au catalogue très différent (WFRP4
  // ~20 livres, WFRP5 1 seul aujourd'hui) faisait qu'un enregistrement fait sur l'une
  // écrasait la sélection utile à l'autre au redémarrage (Nono, 13/09/2026, CONTEXT.md
  // §2.70). ListeLivre ci-dessus reste la sélection RÉSOLUE de l'édition active (lue par
  // PeuplerTabLivre/WinFiltre, inchangés) - synchronisée depuis cette table à chaque
  // changement de version (ChargeIni/ComboBoxVersionSelect, warhammersource.pas).
  ListeLivreParVersion: TStringList;
  // Options desactivees par livre (toggle .INI, A FAIRE.txt "TOGGLE .INI PAR LIVRE",
  // 22/09/2026) : Names = code Livre, Values = liste des codes d'option desactivees
  // separes par virgule (ex. 'QUICKARMOUR'). Une option absente de la liste reste
  // active par defaut - meme principe que ListeLivreParVersion ci-dessus.
  ListeOptionDesactiveeParLivre: TStringList;
  // Ids des regles de tirage decochees pour la creation en cours (videe a l'ouverture de WinCreation)
  ReglesDesactiveesCreation: TStringList = nil;
  WinFiltreAppelant:   String = '';
  SelectWinGroupe:     String = '';
  ChoixWinGroupe:      String = '';
  SelectWinQuickArmor: Boolean= false;
  // Faux : WinWeapon ne propose pas les munitions (option {NoAmmo} du personnage) ; remis a vrai a la fermeture.
  SelectWinMunitions:  Boolean= true;
  // Option Momentum du personnage ouvert : 0 = pas de filtre (consultation), 1 = talents WFRP4 seulement,
  // 2 = talents Momentum (WFRP5) a la place de leurs equivalents WFRP4. Pose par WinPersonnage, remis a 0 a sa fermeture.
  SelectWinMomentum:   Integer= 0;
  SelectWinF:          Integer = 0;
  SelectWinE:          Integer = 0;
  SelectWinFM:         Integer = 0;

  // Fenêtre WinMutation (CONTEXT.md §2.7) - même principe Select.../Choix... que les autres
  // fenêtres modales : WinPersonnage renseigne les entrées avant ShowModal, WinMutation
  // renseigne le résultat avant de se fermer.
  MutationCodeRace:             String  = '';    // entrée : Personnage.Race, pour le tirage Physical/Mental
  MutationResilienceDisponible: Boolean = false;  // entrée : Résilience totale actuelle > 0
  MutationLoreDivin:            String  = '';    // entrée : lore du dieu (Marque divine, WFRP2) ; '' = mutation de corruption
  MutationDieuChaos:            String  = '';    // entrée : dieu (Khorne...) dont on tire la table 3-2 a 3-5 ; '' = table 3-1
  MutationDuChaos:              Boolean = false;  // entrée : mutation du Tome of Corruption (WFRP2), tirage D1000
  MutationChoix:                String  = '';    // sortie : '' (annulé) / 'RESILIENCE' / 'MUTATION'
  // sortie (si MUTATION) : référence stockée sur le personnage (Personnage.Mutations, CONTEXT.md
  // §2.7) - le code stable du catalogue (ex. "RULES-CORMEN_007"), pas le texte résolu ni la
  // plage de jet, pour rester cohérent avec le reste du projet (codes stockés, texte retraduit
  // à l'affichage) et rester valide même si un futur livre renumérote les tables de chance, et
  // permettre de retrouver/retirer une mutation précise plus tard (mutation perdue, rare mais
  // prévu par le livre).
  MutationCode:                 String  = '';
  MutationLibelle:              String  = '';    // sortie : nom de la mutation tirée (si MUTATION)
  MutationEffet:                String  = '';    // sortie : texte de l'effet de la mutation tirée

  // Fenetres WinAfflictionCatalogue/WinDiseaseCatalogue en mode selection (ajout du
  // 27/09/2026, a la demande de Nono) - meme principe sortie que WinMutation ci-dessus, mais
  // pas d'entree (pas de tirage D100, pas de jauge de Resilience) : un double-clic sur une
  // ligne renseigne PathologieCode/PathologieLibelle puis ferme la fenetre.
  PathologieCode:               String  = '';    // sortie : '' (annule) ou Code choisi
  PathologieLibelle:            String  = '';

  // Constantes de thèmes des données des arbres d'affichages
  ConstArbreAttribut:       String;
  ConstArbreCompetence:     String;
  ConstArbreTalent:         String;
  ConstArbreAuChoix:        String;
  ConstArbreEnsemble:       String;
  ConstArbreMetierPossible: String;
  ConstArbreRacePossible:   String;
  ConstArbreEquipement:     String;
  ConstArbreCorruption:     String;

  TypeEquipCC:              String;
  TypeEquipCT:              String;
  TypeEquipMU:              String;
  // Union TypeEquipCC+','+TypeEquipCT+','+TypeEquipMU ("cet equipement de metier est-il une
  // arme ?", teste par InList sur PMetierEquipement.TypeEquipement), centralisee le
  // 15/09/2026 (audit "listes fermees") - recalculee avec TypeEquipCC/CT/MU dans
  // warhammersource.pas, jamais assignee ailleurs.
  TypeEquipMetierArme:      String;
  TypeEquipWe:              String;
  TypeEquipDI:              String;
  TypeEquipAN:              String;
  TypeEquipAR:              String;
  TypeEquipARS:             String;
  TypeEquipSp:              String;

  TypeSortBenediction:     String = 'Blessing';
  TypeSortMiracle:         String = 'Miracle';
  TypeSortMineur:          String = 'Minor Magic';
  TypeSortArcane:          String = 'Arcane Magic';
  TypeSortCouleur:         String = 'Domain Magic';
  TypeSortChaos:           String = 'Chaos Magic';

  ListBook:                array of String;
  ListGroup:               array of String;

  NbLivreRace:             Integer;
  NbLivreMetier:           Integer;

  ValLangue:               String = ConstAnglais;
  ValVersion:              String = '';
  ValLangueInterface:      String = ConstAnglais;
  UniteTaille:             String = ConstUniteInch;   // unite par defaut de la taille, lue dans l'INI
  ImagesDefautSeul:        Boolean = False;           // DEFAULTLICENSELESS=1 : ignore PICTURES et masque les descriptions (test de la version publiable)

  // ConstCheminLivre/ConstCheminPersonnage - Var (pas Const) depuis le 13/09/2026
  // (CONTEXT.md §2.70) : doivent changer ensemble avec ValVersion (WFRP4/WFRP5) le jour ou
  // le rechargement a chaud est cable. Memes valeurs par defaut qu'avant, seule la nature
  // de la declaration change ici.
  ConstCheminLivre:       String = '\DATABASE\WFRP4\';
  ConstCheminPersonnage:  String = '\SAVED_CARACTERS\WFRP4\';

  // Deux interrupteurs jamais affectés ailleurs dans le projet : declarés, testés, mais
  // laissés à false, ce qui désactivait silencieusement les mécanismes correspondants.
  //  - AvecSousMetier      -> DATA_CAREER_SUBCHOICE (second jet de dé pour un sous-métier),
  //                           chargemetiersousmetier.pas. Activé le 21/08/2026 : 22 entrées
  //                           dans Up in Arms et 8 dans Winds of Magic, saisies de longue date
  //                           et jamais utilisées jusque-là.
  //  - AvecRaceChoixMetier -> DATA_SPECIE_CAREER_CHOICE (substitution d'un métier par un
  //                           autre selon l'ethnie), chargemetierracechoixmetier.pas.
  //                           Activé le 21/08/2026 : les entrées existaient depuis Lustria
  //                           mais n'avaient jamais rien produit (repéré par Nono en testant
  //                           la substitution Boatman -> Beachcomber des Norses).
  AvecSousMetier:          Boolean = true;
  AvecRaceChoixMetier:     Boolean = true;

  ConstPoliceNom:          String = 'Arial.ttf';
  ConstPoliceGras:         String = ' Bold';
  ConstPoliceItalique:     String = ' Italic';
  ConstPoliceCarlson:      String = 'Caslon Antique';
  ConstPoliceArial:        String = 'Arial';

  PdfFontBack:             Integer;
  PdfFontValue:            Integer;
  PdfFontBold:             Integer;
  PdfFontEnCours:          Integer;
  PdfFontTaille:           Integer;
  PdfFontItalique:         Integer;

  PdfFamilyName:           String;
  PdfIsBold:               Boolean;
  PdfIsItalic:             Boolean;

  LivresCharges:           String;
  LivresLivres:            String;

  LivreLangue:             String;
  ListeLangue:             String;

  ImageTmp:                String;

  LivreNbRace:             Integer;
  LivreNbMetier:           Integer;
  // Compteurs de l'import du livre en cours (affiches dans TabLivre, menu principal)
  LivreNbCompetence:       Integer;
  LivreNbTalent:           Integer;
  LivreNbArme:             Integer;
  LivreNbArmure:           Integer;
  LivreNbTrapping:         Integer;
  LivreNbSort:             Integer;
  LivreNbTrait:            Integer;

  // chemins génériques
  ConstCheminImageRace:    String    = '\DATABASE\WFRP4\BOOKS\%BOOK%\PICTURE\SPECIE\';
  ConstCheminImageMetier:  String    = '\DATABASE\WFRP4\BOOKS\%BOOK%\PICTURE\CLASS\';
  ConstCheminImageSort:    String    = '\DATABASE\WFRP4\BOOKS\%BOOK%\PICTURE\SPELL\';

  // Icones de niveau - Var (pas Const) depuis le 14/09/2026 (CONTEXT.md §2.70), même
  // raison que ConstCheminLivre plus haut : doivent changer avec ValVersion. Racine des
  // dossiers d'icones de niveau : ConstCheminImageNiveau reste le dossier PAR DEFAUT ; une
  // ethnie peut en designer un autre sous cette racine via la balise <PictureLevel> (ex :
  // NIV_HELF pour les Hauts Elfes, dont le livre utilise des glyphes et des couleurs qui
  // lui sont propres).
  // Fonds et logos du PDF : Var (pas Const) pour suivre ValVersion (PdfCheminsSelonVersion).
  // Defaut WFRP4 : une version sans ses propres fichiers retombe sur WFRP4\PDF\.
  ConstCheminPdfFront         : String = '\PICTURES\WFRP4\PDF\FRONT.png';
  ConstCheminPdfBack          : String = '\PICTURES\WFRP4\PDF\BACK.png';
  ConstCheminPdfShadow        : String = '\PICTURES\WFRP4\PDF\SHADOW.png';
  ConstCheminPdfMetierBack    : String = '\PICTURES\WFRP4\PDF\PDF_BACKSHEET.jpg';
  ConstCheminPdfMetierAdvance : String = '\PICTURES\WFRP4\PDF\PDF_ADVANCE_SCHEME.png';
  ConstCheminPdfMetierLigneG  : String = '\PICTURES\WFRP4\PDF\PDF_LINE_LEFT.png';
  ConstCheminPdfMetierLigneD  : String = '\PICTURES\WFRP4\PDF\PDF_LINE_RIGHT.png';
  ConstCheminPdfWarhammer     : String = '\PICTURES\WFRP4\PDF\PDF_WARHAMMER.png';
  ConstCheminPdfRolePlay      : String = '\PICTURES\WFRP4\PDF\PDF_ROLEPLAY.png';
  ConstCheminPdfUbersreik     : String = '\PICTURES\WFRP4\PDF\PDF_UBERSREIK.png';

  ConstCheminImageNiveau:       String = '\PICTURES\WFRP4\NIV\';
  ConstCheminImageNiveauRacine: String = '\PICTURES\WFRP4\';

  AttributNiveau:          String;

  CodeRecherche:           String;
  LivreRecherche:          String;
  CodeValeur:              String;
  LivreValeur:             String;

  RechercheTrouve:         Boolean = false;
  LivreComplet:            Boolean = false;

  ChoixWinJetRace:    String;    // race en cours, pour TalentAleatoire
  SelectWinJet:       Integer;   // 0 = annulé
  SelectWinJetTalent: String;    // code du talent obtenu, '' = annulé
  ChoixWinJetDeja:    TStringList;
  ChoixWinJetValeur:  Integer;

  // Indices d'image des pastilles d'etat des tableaux d'avancement. Elles vivent dans le
  // MEME dossier et la MEME liste d'images que les icones de niveau de carriere, et elles
  // occupaient 5, 6 et 7 - c'est-a-dire juste au-dessus des quatre niveaux de l'epoque.
  // Deplacees a 20-22 le 31/08/2026 : High Elf Player's Guide apporte une carriere a CINQ
  // niveaux, et le niveau 5 serait venu reclamer l'indice de CouleurNot. Vingt niveaux de
  // carriere mettraient des annees a arriver, s'ils arrivent.
  CouleurNot:     String = '20';
  CouleurOk:      String = '21';
  CouleurKo:      String = '22';
  CouleurFondNot: TColor = TColor($8487F0);   // rouge saumon (20.png) - action requise
  CouleurFondOk:  TColor = TColor($57ED71);   // vert (21.png)
  CouleurFondKo:  TColor = TColor($7F7F7F);   // gris (22.png)

procedure NettoyerElementsFenetre(Fenetre: TWinControl);
procedure AdjustGridColumnsWidth(Grid: TStringGrid; MaxHeight: Integer; ForceMax: Boolean; MaxWidth: boolean; AutoSizeCol: Boolean = true; AddHeight: Integer = 0; AddWidth: Integer = 0; ForceScroll: TScrollStyle = ssautoboth; ScaleDpi: Boolean = true);
Function GridAjouteColonne(Grid: TStringGrid; Caption: String = ''; Widths: Integer = 0; Align: TAlignment = taLeftJustify): Integer;
procedure ClearStringGrid(Grid: TStringGrid);
Procedure DeleteData(ATreeView: TTreeView; ANode: TTreeNode);
Function AjouteAccolade(Filtre: String): String;
Function EnleveAccolade(Filtre: String): String;
Function VerifieFiltre(Valeur: String; Liste: String): Boolean;
Function ReplaceTilde(Ligne: String): String;
Function LivreOrdre(Livre: String): String;
Function OptionDesactivee(Livre, CodeOption: String): Boolean;
Function RegleDesactivee(Livre, CodeRegle: String): Boolean;
Function BasculeCreationActive(CodeRegle: String): Boolean;
Procedure BasculeRegleCreation(CodeRegle: String);
Procedure SauveIniOptions();
Function CheminFichier(TypeDonnee: String; Livre: String): String;
function extractnumbers(line: string): String;
Function LivreRepertoireTravail(CodeLivre, Langue: String): String;
Function LivreFichierActuel(CodeLivre, Langue: String): String;
Function CheminImage(Chemin: String): String;
procedure PdfCheminsSelonVersion(const Version: String);
Function CheminImageClasse(CodeClasse: String): String;
Function CheminIconeEspece(const CodeEspece: String): String;
Function AfficheIconeEspece(Img: TImage; const CodeEspece, Nom: String): Boolean;
Function AfficheIconeSort(Img: TImage; const CodeTalent, Libelle: String): Boolean;

type
  // Emplacements d'origine des deux illustrations de race d'une fenetre (lus une fois).
  TZoneImagesRace = record
    Init:   Boolean;
    R1, R2: TRect;
  end;

// Une seule illustration presente : elle prend la place des deux. Aucune ou deux : emplacements d'origine.
procedure PlaceImagesRace(Img1, Img2: TImage; var Z: TZoneImagesRace; A1, A2: Boolean);
function CleValeurLivre(const Valeur: String): String;
function ValeurLivreEgale(const Valeur, Mot: String): Boolean;
function IndexAlignementV1(const Code: String): Integer;

implementation

// Rang d'un code d'alignement V1 dans CodesAlignementV1, -1 si inconnu
function IndexAlignementV1(const Code: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(CodesAlignementV1) do
    if CodesAlignementV1[I] = Code then
      Exit(I);
end;

// Cle de comparaison d une donnee a choisir des livres V1 / V2, que le livre stocke le MOT anglais (« Melee Weapons »)
// ou le CODE (« RULES-EQCAT2_MELEE_WEAPONS ») : prefixe « RULES-xxx_ » retire, majuscules, espaces / « - » / « / » -> « _ ».
function CleValeurLivre(const Valeur: String): String;
var
  P: Integer;
begin
  Result := Trim(Valeur);
  if Copy(Result, 1, 6) = 'RULES-' then
    begin
      P := Pos('_', Result);
      if P > 0 then Result := Copy(Result, P + 1, MaxInt);
    end;
  Result := StringReplace(StringReplace(StringReplace(UpperCase(Result), ' ', '_', [rfReplaceAll]),
    '-', '_', [rfReplaceAll]), '/', '_', [rfReplaceAll]);
end;

// Vrai si la valeur du livre (mot ou code) designe le mot donne.
function ValeurLivreEgale(const Valeur, Mot: String): Boolean;
begin
  Result := CleValeurLivre(Valeur) = CleValeurLivre(Mot);
end;

procedure NettoyerElementsFenetre(Fenetre: TWinControl);
  var
    i: Integer;
    Control: TControl;
  begin
    // Parcourir tous les contrôles de la fenêtre
    for i := 0 to Fenetre.ControlCount - 1 do
      begin
        Control := Fenetre.Controls[i];

        // Vérifier le type de contrôle et nettoyer en conséquence
        if Control is TStringGrid then
          TStringGrid(Control).Clear
        else if Control is TEdit then
          TEdit(Control).Text := ''
        else if Control is TComboBox then
          TComboBox(Control).Clear;
      end;
  end;

procedure AdjustGridColumnsWidth(Grid: TStringGrid; MaxHeight: Integer; ForceMax: Boolean; MaxWidth: boolean; AutoSizeCol: Boolean = true; AddHeight: Integer = 0; AddWidth: Integer = 0; ForceScroll: TScrollStyle = ssautoboth; ScaleDpi: Boolean = true);
  var
    Col:   Integer;
    Lig:   Integer;
    TotalC:Integer = 0;
    TotalL:Integer = 0;
    Asc:   Integer = 0;
    Form:  TForm;
    MultiLarg:  Integer;
    LignesCell: String;
    LigneCell:  String;
  begin
    // Hauteur
    For Lig := 0 to Grid.RowCount -1 do
      TotalL:= TotalL + Grid.RowHeights[Lig];

    // chercher la taille maximal si elle n'est pas renseignée
    if MaxHeight = 0 then
      Begin
        Form := TForm(Grid.owner);
        MaxHeight := Form.Height;
      end;

    // agrandir à une taille max
    if ForceMax then
      begin
        Grid.Height := MaxHeight - Grid.Top - 10;
        if (Grid.Top + TotalL + 10) > MaxHeight then
          Asc := 20;
      end
    else
      begin
        if (MaxHeight > 0) and ((Grid.Top + TotalL + 10) > MaxHeight) then
          begin
            TotalL := MaxHeight - Grid.Top - 10;
            Asc    := 20;
          end;
        Grid.Height := TotalL + 5;
      end;

    // Largeur
    if AutoSizeCol then
      for Col := 1 to Grid.ColCount - 1 do
        if Grid.ColWidths[Col] <> 0 then
          begin
            // Colonne a cellules multilignes (LineEnding) : AutoSizeColumn mesurerait le texte
            // entier sur une ligne ; on prend la plus longue LIGNE. 20/09/2026.
            MultiLarg := 0;
            for Lig := 1 to Grid.RowCount - 1 do
              if Pos(LineEnding, Grid.Cells[Col, Lig]) > 0 then
                begin
                  LignesCell := Grid.Cells[Col, Lig];
                  while LignesCell <> '' do
                    begin
                      if Pos(LineEnding, LignesCell) > 0 then
                        begin
                          LigneCell  := Copy(LignesCell, 1, Pos(LineEnding, LignesCell) - 1);
                          LignesCell := Copy(LignesCell, Pos(LineEnding, LignesCell) + Length(LineEnding), Length(LignesCell));
                        end
                      else
                        begin
                          LigneCell  := LignesCell;
                          LignesCell := '';
                        end;
                      if Grid.Canvas.TextWidth(LigneCell) + 16 > MultiLarg then
                        MultiLarg := Grid.Canvas.TextWidth(LigneCell) + 16;
                    end;
                end;
            if MultiLarg > 0 then
              Grid.ColWidths[Col] := MultiLarg
            else
              Grid.AutoSizeColumn(Col);
          end;
    for Col := 0 to Grid.ColCount - 1 do
      TotalC:= TotalC + Grid.ColWidths[Col];
    if not MaxWidth then
      Grid.Width := TotalC + 5
    else if Grid.Width > (TotalC + 5) then
      Grid.Width := TotalC + 5;
    // ScaleFormToDesign recalcule la taille de la fenêtre PROPRIÉTAIRE (pas juste la
    // grille) à partir de sa taille actuelle - un rappel de cette fonction sur une fenêtre
    // déjà mise à l'échelle une première fois (au FormCreate) la remet à l'échelle une
    // deuxième fois par-dessus, cumulant l'agrandissement (bug du 18/08/2026, découvert
    // via RafraichirLibellesMenu qui rappelle AdjustGridColumnsWidth à chaque changement
    // de langue en direct, CONTEXT.md §2.8) - ScaleDpi=false permet de sauter ce rappel
    // pour un simple rafraîchissement de contenu, sans toucher les appels existants
    // (paramètre optionnel, true par défaut = comportement inchangé partout ailleurs).
    if ScaleDpi then
      Grid.ScaleFormToDesign(96);
    if not MaxWidth then
      if  Asc > 0 then
        Grid.Width := Grid.Width + Asc;

    // forcer les tailles ajustées
    if AddHeight > 0 then
      Grid.Height := Grid.Height + AddHeight;
    if AddWidth > 0 then
      Grid.Width := Grid.Width + AddWidth;

    // les ascenseurs
    if ForceScroll <> ssAutoBoth then
      Grid.ScrollBars := ForceScroll
    else
      if Grid.Rowcount * Grid.RowHeights[1] > Grid.Height then
        if TotalC > Grid.Width then
          Grid.ScrollBars := ssboth
        else
          Grid.ScrollBars := ssVertical
      else
        if TotalC > Grid.Width then
          Grid.ScrollBars := ssHorizontal
        else
          Grid.ScrollBars := ssnone;

    // L'ascenseur horizontal mange le bas de la grille : sans ce complement, la derniere
    // ligne passe dessous (deux lignes dont une seule visible). Hauteur plafonnee (Asc,
    // ForceMax) : on ne depasse pas le plafond. 20/09/2026.
    if (Asc = 0) and (not ForceMax) and (Grid.ScrollBars in [ssHorizontal, ssBoth, ssAutoHorizontal, ssAutoBoth]) and (TotalC > Grid.Width) then
      Grid.Height := Grid.Height + GetSystemMetrics(SM_CYHSCROLL);

    Grid.Invalidate;

  end;


procedure ClearStringGrid(Grid: TStringGrid);
  var
    Row, Col: Integer;
  begin
    for Row := 1 to Grid.RowCount - 1 do
      for Col := 1 to Grid.ColCount - 1 do
        Grid.Cells[Col, Row] := ''; // Effacer le contenu de la cellule
  end;

Procedure DeleteData(ATreeView: TTreeView; ANode: TTreeNode);
begin
  if ANode = nil then
    exit;

  // Destroy the Data.
  if (ANode.Data <> nil) then
  begin
    TObject(ANode.Data).Free;
    ANode.Data := nil;
  end;

  // Now delete Data in the children, grandchildren etc. of the node...
  if ANode.HasChildren then
    DeleteData(ATreeView, ANode.GetFirstChild);

  // ... and delete Data in the siblings of the node.
  ANode := ANode.GetNextSibling;
  if ANode <> nil then
    DeleteData(ATreeView, ANode);
end;

Function AjouteAccolade(Filtre: String): String;
begin
  Result := '[' + Filtre + ']';
end;

Function EnleveAccolade(Filtre: String): String;
begin
  result := StringReplace(Filtre, '[', '', [rfReplaceAll]);
  result := StringReplace(result, ']', '', [rfReplaceAll]);
end;

Function ReplaceTilde(Ligne: String): String;
Begin
  result := StringReplace(Ligne, '''', '’', [rfReplaceAll]);
  result := StringReplace(result, '"', '“', [rfReplaceAll]);
  result := StringReplace(result, '''', '’', [rfReplaceAll]);

end;

Function SupprimeDetail(Ligne: String): String;
var
  SeparatorPos: Integer;
begin
  SeparatorPos := Pos(SeparateurDetail, Ligne);
  if SeparatorPos > 0 then
    Result := Copy(Ligne, 1, SeparatorPos - 1)
  else
    Result := Ligne;
end;

Function VerifieFiltre(Valeur: String; Liste: String): Boolean;
  var
    Strings:    TStringList;
    Ind:        Integer;
    Res:        Boolean = false;
    Val:        String;
  begin
    AttributNiveau := '';
    if (Liste = '') then
      Res := true
    else if (pos(ValeurGenerique, Liste) > 0) then
      Res := (pos(Valeur,copy(Liste,1,pos(ValeurGenerique, Liste))) > 0)
    else if (pos(',',Valeur) = 0) then
      begin
        if Pos(SeparateurDetail, liste) = 0 then
          Res := (Pos(AjouteAccolade(Valeur), Liste) > 0)
        else
          begin
            Strings   := TStringList.Create;
            ExtractStrings([']'], [], PChar(Liste), Strings);
            for Ind := 0 to (Strings.count-1) Do
              begin
                Val := Strings[Ind];
                Val := SupprimeDetail(Val);
                Val := EnleveAccolade(Val);
                if (Val = Valeur) then
                  begin
                    Res := true;
                    AttributNiveau := Strings[Ind];
                    break;
                  end;
              end;
            Strings.free;
          end
      end
    else
      begin
        Strings   := TStringList.Create;
        ExtractStrings([','], [], PChar(Valeur), Strings);
        for Ind := 0 to (Strings.count-1) Do
          begin
            Strings[Ind] := SupprimeDetail(Strings[Ind]);
            Strings[Ind] := AjouteAccolade(Strings[Ind]);
            AttributNiveau := Strings[Ind];
            if (Strings[Ind] = Liste) then
              Res := true
            else if (pos(ValeurGenerique, Strings[Ind]) > 0) and (pos(Valeur,copy(Strings[Ind],1,pos(ValeurGenerique, Strings[Ind]))) > 0) then
              Res := true
            else if (pos(ValeurGenerique, Liste) > 0) and (pos(Strings[Ind],copy(Liste,1,pos(ValeurGenerique, Liste))) > 0) then
              Res := true;
            if Res = true then
              break;
          end;
        Strings.free;
      end;
    Result := Res;
  end;

// Une regle de tirage (DATA_RULE) peut etre decochee a l'etape « Livre » de WinCreation. Le choix ne
// vaut que pour la creation en cours : il n'est ni ecrit dans l'INI ni dans le personnage.
Function RegleDesactivee(Livre, CodeRegle: String): Boolean;
  begin
    // Etat par defaut = reglage global du livre (INI, option CAREERALT) ; la case de l'etape Livre de
    // WinCreation l'inverse pour la creation en cours.
    Result := OptionDesactivee(Livre, ConstOptionCareerAlt) <> BasculeCreationActive(CodeRegle);
  end;

// Le code a-t-il ete bascule par une case de l'etape Livre pour la creation en cours ?
Function BasculeCreationActive(CodeRegle: String): Boolean;
  begin
    Result := Assigned(ReglesDesactiveesCreation) and (ReglesDesactiveesCreation.IndexOf(CodeRegle) >= 0);
  end;

Procedure BasculeRegleCreation(CodeRegle: String);
  var
    Ind: Integer;
  begin
    if ReglesDesactiveesCreation = nil then
      ReglesDesactiveesCreation := TStringList.Create;
    Ind := ReglesDesactiveesCreation.IndexOf(CodeRegle);
    if Ind >= 0 then
      ReglesDesactiveesCreation.Delete(Ind)
    else
      ReglesDesactiveesCreation.Add(CodeRegle);
  end;

Function OptionDesactivee(Livre, CodeOption: String): Boolean;
  Var
    Liste: TStringList;
  begin
    Result := false;
    Liste  := TStringList.Create;
    try
      Liste.CommaText := ListeOptionDesactiveeParLivre.Values[Livre];
      Result := Liste.IndexOf(CodeOption) >= 0;
    finally
      Liste.Free;
    end;
  end;

// Reecrit uniquement les lignes OPTION<Livre>=... du .INI, en preservant tout le
// reste tel quel (langue, version, selection de livres...) - permet a une fenetre
// qui n'a pas acces a TMenu (WinOptionRegle, pas de dependance circulaire vers
// warhammersource.pas) de persister le toggle immediatement, meme principe que
// TMenu.SauveIni pour le reste (A FAIRE.txt "TOGGLE .INI PAR LIVRE", 22/09/2026).
Procedure SauveIniOptions();
  Var
    FilePathLoc: String;
    Lignes:      TStringList;
    Ind:         Integer;
  begin
    FilePathLoc := GetCurrentDir + ConstFichierIni;
    Lignes       := TStringList.Create;
    try
      if FileExists(FilePathLoc) then
        Lignes.LoadFromFile(FilePathLoc);
      for Ind := Lignes.Count - 1 downto 0 do
        if Pos(ConstIniOption, Lignes[Ind]) = 1 then
          Lignes.Delete(Ind);
      for Ind := 0 to ListeOptionDesactiveeParLivre.Count - 1 do
        if ListeOptionDesactiveeParLivre.Names[Ind] <> '' then
          Lignes.Add(ConstIniOption + ListeOptionDesactiveeParLivre.Names[Ind] + '=' + ListeOptionDesactiveeParLivre.ValueFromIndex[Ind]);
      Lignes.SaveToFile(FilePathLoc);
    finally
      Lignes.Free;
    end;
  end;

Function LivreOrdre(Livre: String): String;
  Var
    Res:   String;
  begin
    if Livre = ConstRulesBook then
      res   := '0'
    else if Livre = ConstBookUpInArms then
      res   := '1'
    else if Livre = ConstBookWindsOfMagic then
      res   := '1'
    else if Livre = ConstBookArchiveEmpire1 then
      res   := '1'
    else if Livre = ConstBookArchiveEmpire2 then
      res   := '1'
    else if Livre = ConstBookArchiveEmpire3 then
      res   := '1'
    else if Livre = ConstBookRoughNightsHardDays then
      res   := '1'
    else if Livre = ConstBookDeathOnTheReikCompanion then
      res   := '1'
    else if Livre = ConstBookEnemyInShadowsCompanion then
      res   := '1'
    else if Livre = ConstBookMiddenheimCityOftheWhiteWolf then
      res   := '1'
    else if Livre = ConstBookSalzenmundCityOfSaltAndSilver then
      res   := '1'
    else if Livre = ConstBookSeaOfClaws then
      res   := '1'
    else if Livre = ConstBookTheHornedRatCompanion then
      res   := '1'
    else
      res   := '2';
    Result  := res;
  end;

Function CheminFichier(TypeDonnee: String; Livre: String): String;
  var
    Path:      String;
  begin
    // chercher le livre dans la langue
    Path := GetCurrentDir+StringReplace(StringReplace(TypeDonnee, ConstLangue, ValLangue, [rfReplaceAll]), ConstLivre, Livre, [rfReplaceAll]);
    if FileExists(Path) then
      result := Path
    else if ValLangue <> ConstAnglais then
      begin
        // si la langue n'est pas l'anglais, chercher en anglais
        Path := GetCurrentDir+StringReplace(StringReplace(TypeDonnee, ConstLangue, ConstAnglais, [rfReplaceAll]), ConstLivre, Livre, [rfReplaceAll]);
        if FileExists(Path) then
          result := Path
        else
          result := '';
      end
    else
      result := '';

  end;

Function GridAjouteColonne(Grid: TStringGrid; Caption: String = ''; Widths: Integer = 0; Align: TAlignment = taLeftJustify): Integer;
  var
    Nb: Integer;
  begin
    Grid.Columns.Add;
    Nb := Grid.ColCount - 1;
    Grid.Columns[Nb-1].title.caption := Caption;
    Grid.ColWidths[Nb]               := Widths;
    Grid.Columns[Nb-1].Alignment     := Align;
    result := Nb;
  end;

function extractnumbers(line: string): String;
  const
    n = ['0'..'9'];
  var
    i: integer;
  begin
    i := 1;
    extractnumbers :='';
    while  i < length(line) do
    begin
      if line[i] in n then extractnumbers := extractnumbers + line[i];
      inc(i);
    end;
  end;

Function LivreRepertoireTravail(CodeLivre, Langue: String): String;
  begin
    Result := GetCurrentDir + ConstCheminTravail + CodeLivre + '_' + Langue;
  end;

Function LivreFichierActuel(CodeLivre, Langue: String): String;
  var
    SearchRec:   TSearchRec;
    PlusRecent:  String;
    Repertoire:  String;
  begin
    Result     := '';
    PlusRecent := '';
    Repertoire := LivreRepertoireTravail(CodeLivre, Langue);
    if not DirectoryExists(Repertoire) then Exit;
    if FindFirst(Repertoire + PathDelim + '*.xml', faAnyFile, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Attr and faDirectory) = 0 then
            if PlusRecent = '' then
              PlusRecent := SearchRec.Name
            else if CompareText(SearchRec.Name, PlusRecent) > 0 then
              PlusRecent := SearchRec.Name;
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    if PlusRecent <> '' then
      Result := IncludeTrailingPathDelimiter(Repertoire) + PlusRecent;
  end;

// Repli d'images (CONTEXT.md 2.117) : Chemin est le chemin COMPLET d'une image. S'il
// existe, il est rendu tel quel (PICTURES gagne toujours). Sinon, le meme chemin sous
// PICTURES_DEFAULT (images propres, publiables) est rendu s'il existe. Si aucun des deux
// n'existe, le chemin d'origine est rendu : le comportement d'une image absente ne change pas.
Function CheminImage(Chemin: String): String;
  var
    Repli: String;
  begin
    Result := Chemin;
    Repli  := StringReplace(Chemin, '\PICTURES\', '\PICTURES_DEFAULT\', [rfIgnoreCase]);
    // Option .INI DEFAULTLICENSELESS=1 : PICTURES est ignore, on voit ce que verrait une
    // installation publique ; une image absente de PICTURES_DEFAULT reste absente.
    if ImagesDefautSeul then
      begin
        Result := Repli;
        Exit;
      end;
    if FileExists(Chemin) then
      Exit;
    if (Repli <> Chemin) and FileExists(Repli) then
      Result := Repli;
  end;

// Fonds et logos du PDF de la version : \PICTURES\<Version>\PDF\<fichier> s'il existe (avec le
// repli PICTURES_DEFAULT de CheminImage), sinon celui de WFRP4 (seule edition garnie aujourd'hui).
procedure PdfCheminsSelonVersion(const Version: String);
  function Choisit(const Fichier: String): String;
    begin
      Result := '\PICTURES\' + Version + '\PDF\' + Fichier;
      if not FileExists(CheminImage(GetCurrentDir + Result)) then
        Result := '\PICTURES\WFRP4\PDF\' + Fichier;
    end;
  begin
    ConstCheminPdfFront := Choisit('FRONT.png');
    ConstCheminPdfBack := Choisit('BACK.png');
    ConstCheminPdfShadow := Choisit('SHADOW.png');
    ConstCheminPdfMetierBack := Choisit('PDF_BACKSHEET.jpg');
    ConstCheminPdfMetierAdvance := Choisit('PDF_ADVANCE_SCHEME.png');
    ConstCheminPdfMetierLigneG := Choisit('PDF_LINE_LEFT.png');
    ConstCheminPdfMetierLigneD := Choisit('PDF_LINE_RIGHT.png');
    ConstCheminPdfWarhammer := Choisit('PDF_WARHAMMER.png');
    ConstCheminPdfRolePlay := Choisit('PDF_ROLEPLAY.png');
    ConstCheminPdfUbersreik := Choisit('PDF_UBERSREIK.png');
  end;

// Image d'une classe de carriere : le code complet (RULES-CLASS_ACAD) d'abord, puis le nom
// court sans prefixe de livre (CLASS_ACAD), seul nom des fichiers historiques. Meme repli que
// pour les ethnies et les metiers (CONTEXT.md 2.27).
Function CheminImageClasse(CodeClasse: String): String;
  var
    Court: String;
  begin
    Result := CheminImage(GetCurrentDir + ConstCheminImageNiveau + CodeClasse + '.png');
    if FileExists(Result) then
      Exit;
    Court := Copy(CodeClasse, Pos('-', CodeClasse) + 1, MaxInt);
    if (Court <> CodeClasse) and (Court <> '') and
       FileExists(CheminImage(GetCurrentDir + ConstCheminImageNiveau + Court + '.png')) then
      Result := CheminImage(GetCurrentDir + ConstCheminImageNiveau + Court + '.png');
  end;

// Icone de l'une des quatre races de base : <code de la race>.png dans le dossier des
// illustrations de race (PICTURES\SPECIE, voir ConstCheminImageRace), a cote des
// illustrations d'ethnie. Une race sans fichier (gobelins, orcs, lezards...) : ''.
function CheminIconeEspece(const CodeEspece: String): String;
begin
  Result := CheminImage(GetCurrentDir + ConstCheminImageRace + CodeEspece + '.png');
  if not FileExists(Result) then
    Result := '';
end;

// Affiche une icone en grand, avec un nom dans un cadre au milieu (brun fonce, filet or).
// Rend False (image inchangee) si le fichier n'existe pas.
function AfficheIconeFichier(Img: TImage; const Chemin, Nom: String): Boolean;
var
  Pic:    TPicture;
  Bmp:    TBitmap;
  Cadre:  TRect;
  LargTxt: Integer;
begin
  Result := False;
  if (Chemin = '') or not FileExists(Chemin) then
    Exit;
  Pic := TPicture.Create;
  Bmp := TBitmap.Create;
  try
    Pic.LoadFromFile(Chemin);
    Bmp.PixelFormat := pf24bit;   // 32 bits : le GDI laisse alpha=0, cadre et texte invisibles
    Bmp.SetSize(Pic.Width, Pic.Height);
    Bmp.Canvas.Brush.Color := clFuchsia;   // couleur transparente
    Bmp.Canvas.FillRect(0, 0, Bmp.Width, Bmp.Height);
    Bmp.Canvas.Draw(0, 0, Pic.Graphic);
    // cadre du nom, au milieu de l'icone (brun fonce, filet or, texte or) ; pas de nom : icone seule
    if Nom <> '' then
      begin
      Bmp.Canvas.Font.Name  := 'Arial';
      Bmp.Canvas.Font.Size  := 22;
      Bmp.Canvas.Font.Style := [Graphics.fsBold];
      LargTxt := Bmp.Canvas.TextWidth(Nom);
      Cadre.Left   := (Bmp.Width - LargTxt) div 2 - 14;
      Cadre.Right  := Cadre.Left + LargTxt + 28;
      Cadre.Top    := Bmp.Height div 2 - 26;
      Cadre.Bottom := Bmp.Height div 2 + 26;
      if Cadre.Left < 2 then Cadre.Left := 2;
      if Cadre.Right > Bmp.Width - 2 then Cadre.Right := Bmp.Width - 2;
      Bmp.Canvas.Brush.Color := TColor($14202A);   // BGR : brun fonce
      Bmp.Canvas.Pen.Color   := TColor($3FA9D9);   // BGR : or
      Bmp.Canvas.Pen.Width   := 3;
      Bmp.Canvas.RoundRect(Cadre.Left, Cadre.Top, Cadre.Right, Cadre.Bottom, 12, 12);
      Bmp.Canvas.Font.Color  := TColor($3FA9D9);
      Bmp.Canvas.Brush.Style := bsClear;
      Bmp.Canvas.TextOut(Cadre.Left + (Cadre.Right - Cadre.Left - LargTxt) div 2,
                         Cadre.Top + (Cadre.Bottom - Cadre.Top - Bmp.Canvas.TextHeight(Nom)) div 2, Nom);
      end;
    Bmp.TransparentColor := clFuchsia;
    Bmp.Transparent      := True;
    Img.Picture.Bitmap.Assign(Bmp);
    Img.Transparent := True;
    Result := True;
  finally
    Bmp.Free;
    Pic.Free;
  end;
end;


// Icone de la race (CheminIconeEspece) avec le nom de la race au milieu.
function AfficheIconeEspece(Img: TImage; const CodeEspece, Nom: String): Boolean;
begin
  Result := AfficheIconeFichier(Img, CheminIconeEspece(CodeEspece), Nom);
end;

// Sort dont le talent n'a pas d'illustration : embleme generique de sa famille (divine,
// arcane, chaos), sans nom - les libelles de talent portent des "(au choix)" ou des noms
// trop longs pour un cadre.
procedure PlaceImagesRace(Img1, Img2: TImage; var Z: TZoneImagesRace; A1, A2: Boolean);
var
  U: TRect;
begin
  if not Z.Init then
    begin
      Z.R1   := Img1.BoundsRect;
      Z.R2   := Img2.BoundsRect;
      Z.Init := True;
    end;
  UnionRect(U, Z.R1, Z.R2);
  Img1.BoundsRect := Z.R1;
  Img2.BoundsRect := Z.R2;
  if A1 and not A2 then
    Img1.BoundsRect := U
  else if A2 and not A1 then
    Img2.BoundsRect := U;
end;

function AfficheIconeSort(Img: TImage; const CodeTalent, Libelle: String): Boolean;
var
  Famille: String;
begin
  if (Pos('T_BLESS', CodeTalent) > 0) or (Pos('T_INVOKE', CodeTalent) > 0) then
    Famille := 'GENERIC_DIVINE'
  else if Pos('T_CHAOS_MAGIC', CodeTalent) > 0 then
    Famille := 'GENERIC_CHAOS'
  else
    Famille := 'GENERIC_ARCANE';
  Result := AfficheIconeFichier(Img,
              CheminImage(GetCurrentDir + ConstCheminImageSort + Famille + '.png'), '');
end;

end.

unit ChargePersonnage;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

interface

uses
  Classes, SysUtils, ChargeConstantes, XMLRead, XMLWrite, DOM,
  Unitcalcul, ChargeRace, ChargeMetier, ChargeAttribut, ChargeCompetence,
  ChargeTalent, ChargeArme, ChargeArmure, ChargeArmureSimplifie,
  ChargeTalentCompetenceModif,
  ChargeMetierTalent,
  ChargeSort, ChargeCorruptionTable, ChargeTrapping,
  ChargeCorruptionCompetenceModif, ChargeCorruptionTalent, ChargeSigneAstral,
  ChargeCorruptionEquipement, ChargeArmureBonusTalent, ChargeArmeBonusTalent,
  ChargeModificateur, 
  ChargeAffliction, ChargeDisease, 
  ChargeAfflictionCompetenceModif,
  ChargeFabrication,
  XmlExportImport;

Type
  StructurePersonnageAttribut   = Record
     CodeAttribut:          String;
     Valeur:                Integer;
     Bonus:                 String;
  end;


Type
  StructurePersonnageCompetence = Record
     CodeCompetence:        String;
     Valeur:                Integer;
     Bonus:                 String;
  end;

Type
  StructurePersonnageTalent     = Record
     CodeTalent:            String;
     Valeur:                Integer;
     Asterisque:            Integer;
     // Code de ce qui a accorde ce talent automatiquement (ex. une mutation), vide si le
     // joueur l'a choisi/achete normalement. Pas encore alimente ni serialise en XML : premiere
     // etape du chantier "traits de creature", CONTEXT.md/A FAIRE.txt.
     Source:                String;
  end;
  // Nomme, requis par le compilateur comme type de retour de fonction (PersonnageMutationTalent) -
  // un "array of ..." anonyme n'est pas accepte a cet endroit.
  TArrayPersonnageTalent = array of StructurePersonnageTalent;

Type
  StructurePersonnageEquipement = Record
     TypeEquipement:        String;
     CodeEquipement:        String;
     QualiteEquipement:     String;
     CoutXp:                Integer;
     // Meme principe que StructurePersonnageTalent.Source : code de ce qui a accorde cette
     // ligne automatiquement (ex. une mutation), vide si achetee/choisie normalement.
     Source:                String;
     // Vrai si la piece est portee (par opposition a transportee). Ne s'applique qu'aux
     // armes/armures/sets d'armure (TypeEquipWe/Ar/ArS) ; sans effet sur Divers/Sorts.
     Porte:                 Boolean;
     // Nombre d'exemplaires de CETTE ligne possedes par le personnage (ex. "10 Shots" d'une
     // carriere = 1 ligne Pistol + 1 ligne Shot a Quantite=10). Le catalogue reste unitaire
     // (StructureTrapping.Prix/Encombrement pour UN exemplaire) ; toujours 1 pour l'instant,
     // rien ne pose encore une autre valeur (CONTEXT.md 2.77bis, en attendant la Phase E).
     Quantite:              Integer;
     // Identifiant d'instance, seulement pour un animal (A1, A2... propre au personnage, deux
     // Riding Horse restant distincts) ; vide pour tout le reste. CONTEXT.md 2.84.
     IdInstance:            String;
     // IdInstance de l'animal qui TRANSPORTE cette ligne, vide si elle est sur le personnage.
     // Distinct de Porte (= vetu). Le calcul d'encombrement viendra a l'etape 2.
     PortePar:              String;
     // Objet de texte pur ajoute depuis WinPersonnage (+Text) : code TEXTE-<N>, nom et encombrement
     // propres a la ligne, ni fiche ni livre. NomLibre vide = objet normal (EncLibre alors ignore).
     NomLibre:              String;
     EncLibre:              Integer;
  end;
  TArrayPersonnageEquipement = array of StructurePersonnageEquipement;

// Premier identifiant A<N> non utilise par la liste d'equipement.
Function IdAnimalLibre(const Liste: TArrayPersonnageEquipement): String;

Type
  // Une entree par qualite d'armure PORTEE, en gardant le lien vers la piece qui la porte -
  // contrairement a PersonnageArmureQualites (liste aplatie, toute pochette possedee comptee,
  // lien piece->qualite perdu). Necessaire pour moduler un malus par Practical/Unreliable de LA
  // piece qui le porte (CONTEXT.md 2.59/A FAIRE.txt).
  StructurePersonnageArmureQualitePortee = Record
     CodeEquipement:        String;
     CodeQualite:           String;
  end;
  TArrayPersonnageArmureQualitePortee = array of StructurePersonnageArmureQualitePortee;

  // Un element POSSEDE par le personnage et susceptible de porter des modificateurs
  // (chantier modificateurs generiques, etape b). PersonnageSourcesModif les enumere tous
  // au meme format ; PersonnageModificateurUnique interroge ListModificateur pour chacun.
  StructureSourceModif = Record
     TypeSource:            String;   // SourceModif* (chargemodificateur.pas)
     Code:                  String;   // code de l'element qui porte le modificateur
     Multiplicateur:        Integer;  // rang du talent, niveau de la qualite de fabrication, 1 sinon
     NiveauAtteint:         Integer;  // palier atteint (CareerBonus) ; ignore pour les autres sources
     ValeurAleatoire:       Integer;  // valeur tiree (Affliction) ; ignoree pour les autres sources
     ValeursEffets:         String;   // jets par attribut d'une mutation a plusieurs effets aleatoires ("code=valeur;...")
     IgnoreFiltre:          Boolean;  // provisoire : les fabrications comptent les effets conditionnels
     Groupe:                Integer;  // rang de la piece d'equipement qui porte la source (0 = aucune) : sert au maximum par piece (bouclier)
  end;
  TArraySourceModif = array of StructureSourceModif;
  TArrayEntiersAleatoires = array of Integer;
  TArrayCodesAleatoires   = array of String;

Type
  // historique de corruption : Montant positif = corruption gagnée, négatif = perdue/purifiée
  StructurePersonnageCorruption  = Record
     Montant:               Integer;
     Libelle:               String;
  end;

Type
  // mutation obtenue par le personnage (CONTEXT.md §2.7) - référence (Code stable du catalogue,
  // ex. "RULES-CORMEN_007") vers ListCorruptionTable (ChargeCorruptionTable.pas), pas le texte
  // résolu ni la plage de jet : cohérent avec le reste du projet (codes stockés, texte retraduit
  // à l'affichage via ChercheCorruptionTable), reste valide si un futur livre renumérote sa table
  // de chance (DATA_CORRUPTION_..._CHANCE), et nécessaire pour retrouver/retirer une mutation
  // précise (perte de mutation, rare mais prévue par le livre).
  StructurePersonnageMutation    = Record
     Code:                  String;
     // Jet Nd10 valide a la prise pour une mutation a <ModifyCaracAleatoire> (Tome of Corruption,
     // ex. "+1d10 % Agility"), deja signe ; 0 sinon. Une prise = une entree, donc un jet par prise.
     ValeurAleatoire:       Integer;
     // Mutation a PLUSIEURS <ModifyCaracAleatoire> : un jet par attribut, "code=valeur;code=valeur"
     // (valeurs deja signees). Vide = un seul jet, dans ValeurAleatoire.
     ValeursEffets:         String;
  end;

Type
  // Affliction ou maladie possedee par le personnage (Unofficial Grimoire / Litany of
  // Pestilence, ajout du 27/09/2026) - meme principe que StructurePersonnageMutation : juste
  // le Code stable du catalogue (ChargeAffliction/ChargeDisease), texte et modificateurs
  // resolus a l'affichage. Un seul onglet commun cote IHM (Nono), distingue par TypeChapitre
  // ('AFFLICTION' ou 'DISEASE') pour savoir quel catalogue/quelle liste de modificateurs
  // interroger.
  StructurePersonnagePathologie  = Record
     TypeChapitre:          String;
     Code:                  String;
     // Resultat du tirage 1dFace fait UNE FOIS a l'ajout de cette entree sur la fiche, pour un
     // catalogue dont le <ModifyCaracAleatoire> fixe le montant par un jet de de (ex.
     // Debilitation "-1d10 Toughness") plutot qu'une valeur fixe - deja negatif si c'est une
     // perte. 0 si l'entree ne porte aucun modificateur aleatoire. Ajout du 27/09/2026, a la
     // demande de Nono.
     ValeurAleatoire:       Integer;
  end;

Type
  // Lien entre un Talent accorde automatiquement par une carriere et la carriere+niveau
  // requis pour que ses effets restent actifs (ex. Virtue of the Quest, NATIO-T0017,
  // Nations of Mankind p.12 : accorde a l'entree en Questing Knight, effets en sommeil -
  // pas de vrai retrait - tant que le personnage n'est pas dans cette carriere+niveau).
  // Fige au moment de l'octroi (pas recalcule depuis un historique) : compare a
  // Personnage.MetierEnCours a l'affichage (WinPersonnage/PDF) pour barrer le talent sans
  // le retirer. Generique, pas cable a NATIO-T0017 specifiquement - reutilisable si un
  // autre livre a le meme besoin. CONTEXT.md 2.78.
  StructurePersonnageTalentCarriereRequise = Record
     CodeTalent:            String;
     CodeMetier:            String;
     NiveauMetier:          Integer;
  end;

Type
  StructurePersonnageMetier     = Record
     CodeMetier:            String;
     NiveauMetier:          Integer;
     CoutXp:                Integer;
  end;

Type
  StructurePersonnageXpAttribut = Record
     CodeAttribut:          String;
     Debut:                 Integer;
     Fin:                   Integer;
     CoutXp:                Integer;
  end;

Type
  StructurePersonnageXpCompetence = Record
     CodeCompetence:        String;
     Debut:                 Integer;
     Fin:                   Integer;
     CoutXp:                Integer;
  end;

Type
  StructurePersonnageXpTalent = Record
     CodeTalent:            String;
     Debut:                 Integer;
     Fin:                   Integer;
     CoutXp:                Integer;
  end;


Type
  StructurePersonnage = Record
     NomPersonnage:              String;
     LivresAcceptes:             String;
     XpTotal:                    Integer;
     Xp25Total:                  Integer;
     XpActuel:                   Integer;
     Race:                       String;
     MetierEnCours:              StructurePersonnageMetier;
     CreationAttribut:           array of StructurePersonnageAttribut;
     CreationCompetence35:       array of StructurePersonnageCompetence;
     CreationCompetence40:       array of StructurePersonnageCompetence;
     CreationTalent:             array of StructurePersonnageTalent;
     MetierAncien:               array of StructurePersonnageMetier;
     MetierCompetence:           array of StructurePersonnageCompetence;
     MetierTalent:               array of StructurePersonnageTalent;
     AugmentationAttribut:       array of StructurePersonnageAttribut;
     AugmentationCompetence:     array of StructurePersonnageCompetence;
     AugmentationTalent:         array of StructurePersonnageTalent;
     Equipement:                 array of StructurePersonnageEquipement;
     Corruption:                 array of StructurePersonnageCorruption;
     Destin:                     array of StructurePersonnageCorruption;  // registre des points de Destin depenses/gagnes (meme forme que Corruption)
     Resilience:                 array of StructurePersonnageCorruption;  // idem Resilience
     Resolve:                    array of StructurePersonnageCorruption;  // registre de Resolution
     Mutations:                  array of StructurePersonnageMutation;
     Pathologies:                array of StructurePersonnagePathologie;
     XpCoutAttribut:             array of StructurePersonnageXpAttribut;
     XpCoutTalent:               array of StructurePersonnageXpTalent;
     XpCoutCompetence:           array of StructurePersonnageXpCompetence;
     LivresObligatoires:         String;
     Options:                    String;
     // Objets propres au personnage (sans livre) : contenu XML de <CUSTOM_ITEMS>, au format
     // d'un DATA_TRAPPING de livre. Vide = aucun. Injecte dans les listes au chargement.
     ObjetsPropres:              String;
     Age:                     Integer;
     // V1 : points de magie gagnes aux niveaux des carrieres magiques (0 = aucun)
     PointsMagie:                Integer;
     // V1 : alignement choisi (RULES-V1ALIGN_xxx), '' = standard de la race ; points de folie (0 = aucun)
     AlignementV1:               String;
     FolieV1:                    Integer;
     // V1 : bloc Background de la feuille, saisie libre
     NaissanceV1, ParentsV1, FamilleV1: String;
     // V1 : handicaps des magiciens "CODE=stade;CODE=stade" et marque mauvais / chaotique (Wizard)
     HandicapsV1:                String;
     FamilierV1:                 String;   // code du familier du Druidic Priest (RULES-FAMILIAR_xxx), '' si aucun
     MagicienMauvaisV1:          Boolean;
     ClasseV1:                   String;   // code de la classe V1 (DATA_CLASS_V1), '' si fiche anterieure
     CulteV1:                    String;   // code du culte de l'Initiate / Priest (DATA_CULT_V1, WRDM-CULT_xxx), '' si aucun
     // V1 : sorts appris "CODE|source|cout;CODE|source|cout" et tentatives ratees "CODE|source|Int;..." (voir chargemetierattribut.pas)
     SortsV1:                    String;
     EchecsSortsV1:              String;
     Height:                  Integer;
     HeightUnit:                 String;    // unite de Height : CM ou INCH (absente = INCH, anciennes fiches)
     HairColors:                 String;
     EyeColors:                  String;
     // Sous-bloc V2 (details personnels du Core V2, vide/0 pour un personnage V4/V5)
     PoidsV2:                    Integer;   // livres, 0 = non defini
     SexeV2:                     String;    // 'F' ou 'M', vide = non defini (fiches anterieures)
     FratrieV2:                  String;    // nombre de freres et soeurs, vide = non tire
     SigneDistinctifV2:          String;
     NaissanceV2:                String;
     AstreV2:                    String;    // libelle du signe astral V2 (sans effet sur les caracteristiques)
     AmbitionCourt:              String;    // saisie libre, panneau Ambitions du PDF
     AmbitionLong:               String;    // saisie libre, panneau Ambitions du PDF
     AmbitionGroupeCourt:        String;    // saisie libre, ambitions du groupe/de la Party
     AmbitionGroupeLong:         String;    // saisie libre, ambitions du groupe/de la Party
     GroupeId:                   String;    // nom du groupe (sans prefixe GROUPE_ ni .xml), vide = personnage solo (CONTEXT.md 2.100)
     MonnaieCO:                  Integer;   // couronnes d'or (0 = aucune, balise omise du XML)
     MonnaiePA:                  Integer;   // pistoles d'argent
     MonnaieSB:                  Integer;   // sous de laiton
     SigneAstral:                String;    // code du signe astral (Archives II p.39), vide = aucun
     SigneAstralVariante:        String;    // plage du sous-tirage d10 du Witchling Star, vide sinon
     SigneAstralTalent:          String;    // specialisation choisie du talent generique du signe (RULES-T0092_MINNER), vide sinon
     Asterisque:                 Integer;
     // Appartenances : les codes des CareerBonus (regiment, ordre de chevalerie, culte)
     // dont ce personnage est membre, separes par des virgules, vide si aucune.
     // C'est une donnee de la FICHE et non une deduction de la carriere en cours : le
     // livre precise qu'on garde les competences et talents acquis meme apres avoir
     // quitte le regiment ou change de carriere. CONTEXT.md 2.44.
     Appartenance:               String;
     // Adaptations de carriere FACULTATIVES acceptees (codes, virgules) : le Choix de AdapterElement.
     ChoixAdaptation:            String;
     // Competences choisies au titre d'un <SkillChoice> d'appartenance (ex. Reiksguard
     // palier 4, "choisis 3 competences raciales, +5 avancees gratuites chacune") - Valeur
     // porte le nombre d'avancees offertes, jamais lu par CalculTableExperience (meme
     // principe que CreationCompetence35, mais champ separe : source differente, jamais
     // melangee). Vide si le personnage n'a fait aucun choix de ce type.
     CompetenceAppartenance:     array of StructurePersonnageCompetence;
     // V2 : avance gratuite de creation (une seule, ecrite par la phase 7 de WinCreation).
     // Valeur = pas de l'avance (+5 principal, +1 secondaire). Compte dans le total de la
     // caracteristique mais JAMAIS dans le cout en XP ; les avances achetees restent dans
     // AugmentationAttribut.
     AvanceGratuiteAttribut:     array of StructurePersonnageAttribut;
     // Talents dont les effets sont lies a une carriere+niveau precis, fige a l'octroi -
     // voir StructurePersonnageTalentCarriereRequise. Vide si aucun talent de ce genre.
     TalentCarriereRequise:      array of StructurePersonnageTalentCarriereRequise;
  end;

  StructureChoixCreation = record
    Origine, CodeSource, CodeParent, CodeChoisi: String;
    CodeSpecialise: String;
    Rang: Integer;
    Aleatoire: Boolean;
    Jet: Integer;
  end;

  // XML
  function PersonnageXmlCreation(Personnage: StructurePersonnage; Xp: Integer; XpRestante: Integer; fileName: string; PersonnageName: String): Boolean;
  function PersonnageXmlChargement(fileName: string): StructurePersonnage;
  function PersonnageXmlFichierActuel(const Directory: string): string;
  // Don d'un objet : ajoute la ligne d'equipement (et, pour un objet propre, ses elements
  // CUSTOM_ITEMS) a la fiche Fichier, enregistree sous un nouveau fichier date. Faux si echec.
  function PersonnageDonneObjet(const Fichier: String; Equipement: StructurePersonnageEquipement;
    const Elements: String): Boolean;
  // Lecture allegee de Personnage.GroupeId depuis un fichier, sans charger toute la fiche
  // (CONTEXT.md 2.100).
  function PersonnageGroupeIdFichier(const FileName: String): String;
  function PersonnageResumeFichier(const FileName: String; out Personnage: StructurePersonnage): Boolean;
  function PersonnageLivre(ListeLivre: String; Livre: String): string;
  Function PersonnageTalentAsterisque(var Personnage:StructurePersonnage; CodeTalent: String): Integer;
  // Option Momentum : remplace, dans tous les talents du personnage (crees, achetes, menu de carriere,
  // couts d'Xp, talents lies a une carriere), le code V4 RULES-T_xxx par MOMENTUM-T_xxx (Momentum vrai)
  // ou l'inverse. Les talents sans equivalent dans l'autre livre ne changent pas.
  Procedure PersonnageTalentsMomentum(var Personnage: StructurePersonnage; Momentum: Boolean);
  // Effets à delta pur des mutations obtenues (CONTEXT.md §2.7, étape 8) - somme, pour un code
  // d'attribut/compétence donné, tous les <ModifyCarac>/<ModifySkill> des mutations présentes
  // dans Personnage.Mutations. Ce sont ici de vrais modificateurs additionnés au Total
  // (PdfPersonnageAttribut/PdfPersonnageCompetence, pdfpersonnage.pas). Implementation deleguee
  // a PersonnageMutationModificateur depuis le 11/09/2026 (migration ModifyCarac sur le moteur
  // generique, meme chantier que Talent/CareerBonus).
  Function PersonnageMutationAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Texte d'effet a afficher a cote du libelle d'une Mutation possedee (PDF, pdfpersonnage.pas)
  // - meme principe que PersonnagePathologieEffetTexte plus bas, ajout du 27/09/2026 a la
  // demande de Nono (initialement fait pour Affliction/Disease seulement, etendu ici).
  Function PersonnageMutationEffetTexte(PersonnageMutation: StructurePersonnageMutation): String;
  Function PersonnageMutationFaceAleatoire(Code: String; out CodeAttribut: String; out Signe: Integer): Integer;
  // Tous les <ModifyCaracAleatoire> du catalogue pour la mutation Code (face totale signee, attribut) :
  // un jet a montrer par entree. Listes paralleles, vides si la mutation n'en porte pas.
  Procedure PersonnageMutationEffetsAleatoires(Code: String; out Faces: TArrayEntiersAleatoires; out Attributs: TArrayCodesAleatoires);
  // Jet d'une mutation pour l'attribut Cible : valeur de ValeursEffets si renseignee, sinon ValeurAleatoire.
  Function MutationValeurEffet(ValeurAleatoire: Integer; ValeursEffets, Cible: String): Integer;
  // Libelle de race a afficher : celui de la race, suivi de "(Mutant)" si le personnage a gagne une mutation
  // (Tome of Corruption p.25). Etiquette seule : Personnage.Race reste la race d'origine, qui pilote
  // les caracteristiques (Mouvement, Blessures...).
  Function PersonnageRaceLibelle(Personnage: StructurePersonnage; LibelleRace: String): String;
  // Meme principe que PersonnageMutationAttributModif ci-dessus, mais pour les effets
  // permanents chiffrables des Afflictions/Maladies possedees (Personnage.Pathologies) -
  // ajout du 27/09/2026, a la demande de Nono. CodeSource = StructureAffliction.Code /
  // StructureDisease.Code, filtre par TypeChapitre pour interroger la bonne liste.
  Function PersonnageAfflictionAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  Function PersonnageAfflictionModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // Renvoie la face de de (ex. 10) et l'attribut vise du <ModifyCaracAleatoire> porte par
  // l'entree Code du catalogue Affliction, 0/'' si aucun. Ne tire rien elle-meme : le tirage
  // est montre a Nono et valide/corrige par lui via WinJetPathologie (winpersonnage.pas), le
  // resultat confirme est ensuite stocke directement dans PersonnagePathologie.ValeurAleatoire
  // par l'appelant. Ajout du 27/09/2026, a la demande de Nono (le premier jet etait fait en
  // silence par le programme, sans montrer le resultat - corrige suite a sa remarque).
  Function PersonnageAfflictionFaceAleatoire(Code: String; out CodeAttribut: String): Integer;
  Function PersonnageDiseaseAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  Function PersonnageDiseaseModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // Texte d'effet a afficher a cote du libelle d'une Affliction/Maladie possedee (PDF,
  // pdfpersonnage.pas) - demande de Nono le 27/09/2026 : si l'entree porte un modificateur
  // chiffrable (ModifyCarac fixe ou aleatoire, ModifySkillAttribut), affiche le montant et
  // l'attribut vise (ex. "-7 Strength") ; sinon, affiche le texte libre du catalogue
  // (StructureAffliction.Effet / StructureDisease.Symptoms), tel quel (troncature eventuelle
  // laissee a l'appelant, qui connait la largeur disponible).
  Function PersonnagePathologieEffetTexte(PersonnagePathologie: StructurePersonnagePathologie): String;
  // <ModifySkillAttribut> des Afflictions (ex. Disfigurement/Stench, Unofficial Grimoire,
  // "-10 to all Fellowship Tests") - meme principe que le pendant Mutation dans
  // PersonnageMutationCompetenceModif (ListCorruptionCompetenceAttributModif), liste separee
  // ListAfflictionCompetenceAttributModif (ChargeAfflictionCompetenceModif). Ajout du
  // 27/09/2026, a la demande de Nono. Aucune Disease connue n'a besoin de ce pendant pour
  // l'instant, pas de fonction dediee cote Disease.
  Function PersonnageAfflictionCompetenceModif(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  // Moteur generique (ChargeCorruptionModificateur) cote Mutation - pendant de
  // PersonnageTalentModificateur, sans filtre de palier (une mutation presente compte
  // toujours). CodeSource = StructureCorruptionTable.Code. CONTEXT.md, chantier moteur
  // generique, etape "migrer ModifyCarac d'Attribut" (11/09/2026).
  Function PersonnageMutationModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // <ModifySkill> des mutations - lit desormais ListCorruptionModificateur (TypeModif =
  // ConstXmlModifieCompetence) depuis le 11/09/2026. Reste une fonction dediee (pas un
  // simple appel a PersonnageMutationModificateur) : gere en plus la famille de
  // sous-competences (CodeGenerique) et le pendant <ModifySkillAttribut>
  // (ListCorruptionCompetenceAttributModif, broadcast par attribut de rattachement, hors
  // moteur generique - pas dans ce chantier).
  Function PersonnageMutationCompetenceModif(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  // <ModifArmour> des mutations - implementation deleguee a PersonnageMutationModificateur
  // depuis le 11/09/2026 (migration ModifySkill/ModifyArmour sur le moteur generique).
  Function PersonnageMutationArmureModif(Personnage: StructurePersonnage; CodeLocalisation: String): Integer;
  // Talents accordes automatiquement par les mutations du personnage (ex. Fleshy Tentacle ->
  // Tentacles, cas par cas dans le XML - <Talent> sous <Corruption>, chargecorruptiontalent.pas).
  // Calcule a la volee depuis Personnage.Mutations, meme principe que
  // PersonnageMutationArmureModif juste au-dessus : rien n'est stocke sur la fiche, donc si une
  // mutation disparait un jour de Personnage.Mutations, le talent calcule disparait avec elle
  // sans purge explicite a ecrire. CONTEXT.md, chantier "traits de creature".
  // Renvoie aussi le talent gagne par le signe astral du personnage (meme principe, memes appelants).
  Function PersonnageMutationTalent(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  // Vrai si CodeTalent a un lien enregistre dans Personnage.TalentCarriereRequise ET que
  // le personnage n'est plus dans la carriere+niveau requis - le talent reste possede
  // (pas retire) mais doit s'afficher barre (WinPersonnage/Pdf). Faux si CodeTalent n'a
  // aucun lien enregistre (talent normal) ou si le personnage est toujours dans la
  // carriere+niveau requis. CONTEXT.md 2.78, Virtue of the Quest.
  Function PersonnageTalentEstBarre(Personnage: StructurePersonnage; CodeTalent: String): Boolean;
  // Meme principe que PersonnageMutationTalent juste au-dessus, mais pour l'arme/armure
  // accordee par une mutation (<Weapon>/<Armor> sous <Corruption>, chargecorruptionequipement.pas).
  // Calcule a la volee, rien de stocke sur la fiche : meme cascade gratuite au retrait d'une
  // mutation. CONTEXT.md, chantier "traits de creature".
  Function PersonnageMutationEquipement(Personnage: StructurePersonnage): TArrayPersonnageEquipement;
  // Lignes d'arme SUPPLEMENTAIRES que les accessoires d'une arme lui donnent (Bayonet = Spear,
  // <AlternateWeapon> de la fabrication). Calcule a la volee pour le PDF, rien de stocke sur la
  // fiche. Source = '@' + code de la fabrication ; l'arme equipee reste une ligne a part entiere.
  Function PersonnageAccessoireEquipement(Personnage: StructurePersonnage): TArrayPersonnageEquipement;
  // Code de la fabrication qui a fabrique cette ligne alternative, '' si c'est une vraie ligne.
  Function EquipementAlternatifFabrication(PEquipement: StructurePersonnageEquipement): String;
  // Exposees pour ChargeGroupe (CONTEXT.md 2.100) : le fichier GROUPE_<Nom>.xml reutilise
  // telles quelles les lignes d'equipement "Divers/Animal" d'un personnage.
  Function XmlAttributEquipementInstance(Equipement: StructurePersonnageEquipement): String;
  Function XmlAttributEquipementQuantite(Quantite: Integer): String;
  Procedure LitEquipementInstance(Node: TDOMNode; var Equipement: StructurePersonnageEquipement);
  // Meme principe que PersonnageMutationTalent, mais la source est une qualite d'objet porte
  // (ex. NATIO-ARMOB_16 "Fear" -> RULES-T0049 "Frightening", Skull Trophies) plutot qu'une
  // mutation - <Talent> sous <ArmureBonus>, chargearmurebonustalent.pas. Calcule a la volee
  // depuis Personnage.Equipement : le retrait de l'objet porte fait disparaitre le talent
  // accorde sans purge explicite a ecrire. CONTEXT.md, chantier "traits de creature".
  Function PersonnageArmureBonusTalent(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  // Meme principe que PersonnageArmureBonusTalent ci-dessus, cote arme (<Talent> sous
  // <ArmeBonus> OU pose via Fabrication, chargearmebonustalent.pas) - chantier "objets
  // magiques Archives II", desormais alimente par DATA_CRAFTMANSHIP (25/09/2026, Nono :
  // ces qualites doivent etre recreables via Fabrication, pas figees en XML sur une arme).
  Function PersonnageArmeBonusTalent(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  Function PersonnageTalentsOctroyes(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  // Niveau de carriere (1 a 4) auquel la carriere en cours propose ce talent, ou -1 si elle ne
  // le propose pas. Meme regle que la colonne niveau de WinPersonnage (NiveauMetierTalentMax) :
  // meme code, ou meme radical (livre + code coupe au premier '_'), sur chaque branche d'un
  // choix "A/B", apres Adapting Careers.
  Function PersonnageTalentNiveauMetier(const Personnage: StructurePersonnage; CodeTalent: String): Integer;
  Function PersonnageTalentArmureModif(Personnage: StructurePersonnage; CodeLocalisation: String): Integer;
  // Même principe que PersonnageMutationAttributModif, mais sur les <ModifyCarac> déclarés
  // directement sur un TALENT (DATA_TALENT) plutôt que sur une mutation. Ajoutée le
  // 06/09/2026 - CONTEXT.md, chantier "résolveur générique Attribut/Compétence" : premier
  // pas, un seul appelant pour l'instant (Mouvement dans PdfPersonnageCreation/Feldo2P, en
  // remplacement du cas TalentVeloce du case sur AugmentationTalent/CreationTalent).
  // Implementation deleguee a PersonnageTalentModificateur depuis le 11/09/2026 (migration
  // ModifyCarac sur le moteur generique) - l'annotation d'affichage
  // (PersonnageTalentAsterisque) lit desormais la meme ListTalentModificateur.
  Function PersonnageTalentAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Moteur generique "par source" (chargemodificateur.pas, CONTEXT.md chantier "inversion
  // des recherches") : boucle sur les Talents possedes par le personnage et additionne les
  // <Modificateur Type="..." Cible="..."/> qui correspondent, au lieu d'une fonction dediee
  // par croisement source/cible. Filtre optionnel (ex. skill= pour restreindre un ModifyWeapon
  // a une competence precise), vide si non utilise. Premiere source branchee sur ce format ;
  // les autres (CareerBonus, Mutation...) suivront dans un chantier separe.
  Function PersonnageTalentModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // Greffes des appartenances (regiments, ordres, cultes) - CONTEXT.md 2.44
  Procedure PersonnageAppliqueGreffes(var Personnage: StructurePersonnage);
  // Effet AddSkillToCareer d'un talent possede (Perfect Pitch -> Chant) : competence ajoutee aux competences de metier, idempotent
  Procedure PersonnageAppliqueTalentsCompetences(var Personnage: StructurePersonnage);
  // Niveau atteint par le personnage dans un metier donne (le plus haut entre la carriere en
  // cours et les carrieres passees) - CONTEXT.md 2.50 etape 3. Sert de filtre de palier pour
  // PersonnageCareerBonusAttributModif : contrairement a PersonnageAppliqueGreffes (qui greffe
  // tous les paliers d'une appartenance sans filtrer, l'ecran/le PDF filtrant ensuite par le
  // Valeur tague sur MetierCompetence/MetierTalent), un bonus d'ATTRIBUT est additionne
  // directement au Total et ne peut pas se permettre ce flou.
  // V1 : competences gratuites du familier du Druidic Priest (premiere au niveau 1, seconde au niveau 2), separees par ';'
  Function CompetencesFamilierV1(Personnage: StructurePersonnage): String;
  Function PersonnageNiveauDansMetier(Personnage: StructurePersonnage; CodeMetier: String): Integer;
  // Même principe que PersonnageTalentAttributModif, mais sur les <ModifyCarac> déclarés dans
  // un palier de DATA_CAREER_BONUS - n'additionne un modificateur que si le personnage a
  // l'appartenance ET a atteint le palier qui le porte. Implementation deleguee a
  // PersonnageCareerBonusModificateur depuis le 11/09/2026 (migration ModifyCarac).
  Function PersonnageCareerBonusAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Moteur generique (ChargeCareerBonusModificateur) cote CareerBonus - pendant de
  // PersonnageTalentModificateur ci-dessus, avec en plus le filtre de palier que les Talents
  // n'ont pas : boucle sur les Appartenances du personnage, ne compte un modificateur que si
  // son Niveau est atteint (PersonnageNiveauDansMetier). CONTEXT.md, chantier moteur
  // generique, etape "brancher CareerBonus" (11/09/2026). Remplace en interne les anciennes
  // PersonnageCareerBonusCompetenceModif/ArmeModif, dont les signatures ne changent pas.
  Function PersonnageCareerBonusModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // Pendant Competence de PersonnageCareerBonusAttributModif ci-dessus - ajouté au 2.44/3d-3 :
  // le palier Knight ("+10 CC avec les lances") se représente comme un bonus chiffré sur
  // Melee (Cavalry) plutôt qu'un simple octroi de compétence. Implementation deleguee a
  // PersonnageCareerBonusModificateur depuis le 11/09/2026 (branchement CareerBonus sur le
  // moteur generique).
  Function PersonnageCareerBonusCompetenceModif(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  // V2 : valeur de l'avance gratuite de creation sur cette caracteristique (0 si aucune).
  Function PersonnageAvanceGratuite(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Pendant "par type d'arme" des deux precedents - ajoute le 07/09/2026 : le palier Knight ne
  // bonifie que CERTAINES armes d'une meme competence ("+10 CC avec les lances, les epees a
  // deux mains ou les boucliers", pas tout Melee (Cavalry)/Melee (2 mains)/Melee (Base)).
  // Prend l'ARME ELLE-MEME en parametre (pas son seul CodeCompetence) car le filtre porte sur
  // StructureArme.TypeArme, et FACULTATIVEMENT sur CodeCompetence en plus (voir ChargeMetier).
  // A appeler par ARME possedee, pas par competence generale - PdfPersonnageArmes
  // (pdfpersonnage.pas) est le seul appelant prevu, une ligne d'arme a la fois. Implementation
  // deleguee a PersonnageCareerBonusModificateur depuis le 11/09/2026.
  Function PersonnageCareerBonusArmeModif(Personnage: StructurePersonnage; PArme: StructureArme): Integer;
  // Pendant "regle narrative" des trois PersonnageCareerBonusXxxModif ci-dessus
  // (ListCareerBonusSpecialRule) - ajoute le 08/09/2026 pour le palier 4 ("Knight of the
  // Inner Circle") des Ordres de Chevalerie, qui n'a le plus souvent aucun equivalent
  // chiffre. Renvoie les regles acquises par le personnage (Appartenance + palier
  // atteint) - l'APPELANT est proprietaire de la liste rendue et doit la liberer, meme
  // contrat que NiveauxDuCareerBonus (ChargeMetier). Affichee sur le PDF comme un "talent
  // virtuel" de plus (pdfpersonnage.pas, les deux gabarits).
  Function PersonnageCareerBonusSpecialRule(Personnage: StructurePersonnage): TListCareerBonusSpecialRule;
  // Même principe que PersonnageTalentAttributModif, mais sur les <ModifyCarac> déclarés
  // directement sur une ARME (DATA_ARME) - CONTEXT.md 2.50 étape 3. Une arme n'a pas de
  // niveau : toute arme présente dans Personnage.Equipement compte, comme pour l'armure (pas
  // de distinction "possédé" / "porté" dans ce modèle). Implementation deleguee a
  // PersonnageArmeModificateur depuis le 11/09/2026 (migration ModifyCarac).
  // Pendant "par type d'arme" de PersonnageTalentModificateur, meme principe que
  // PersonnageCareerBonusArmeModif - chantier "moteur generique", etape ModifyWeapon sur
  // Talent (CONTEXT.md, 11/09/2026). Prend l'ARME ELLE-MEME en parametre (TypeArme +
  // CodeCompetence en filtre optionnel), a appeler par arme possedee.
  Function PersonnageTalentArmeModif(Personnage: StructurePersonnage; PArme: StructureArme): Integer;
  Function PersonnageArmeAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Moteur generique (ChargeArmeModificateur) cote Arme - pendant de
  // PersonnageTalentModificateur, sans filtre de niveau/palier. CodeSource = CodeArme.
  Function PersonnageArmeModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // Modificateurs des QUALITES d'armure (<ModifyCarac> sur DATA_ARMURE_BONUS) et migration en
  // vrai calcul de l'ancien mecanisme decoratif ListArmureBonusModif (<Modifier name="..."> lie
  // a une competence, jusqu'ici jamais soustrait du Total - cause du bug Stechzeug Bracers,
  // A FAIRE.txt). CONTEXT.md 2.50 etape 3, point 4/5. Toute piece d'armure equipee (normale ET
  // simplifiee) compte, qualite par qualite dans sa ListeBonus. Implementation deleguee a
  // PersonnageArmureBonusModificateur depuis le 11/09/2026 (migration ModifyCarac).
  Function PersonnageArmureBonusAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Regle unique « porte » : tout ce qui est rattache a un objet (qualites, fabrications, runes,
  // talents octroyes) ne compte que si l'objet est porte. Arme, armure, armure simplifiee et
  // objet divers sont portables ; tout autre type d'equipement compte toujours.
  Function EquipementCompte(PersonnageEquipement: StructurePersonnageEquipement): Boolean;
  // Option {NoAmmo} du personnage : rend le personnage sans ses munitions (armes dont le code
  // porte MUNI_), pour le PDF. Sans l'option, le personnage est rendu tel quel.
  Function PersonnageSansMunitions(Personnage: StructurePersonnage): StructurePersonnage;
  // Moteur generique (ChargeArmureBonusModificateur) cote qualite d'armure - pendant de
  // PersonnageTalentModificateur. CodeSource = CodeArmureBonus ; a appeler avec les codes
  // rendus par PersonnageArmureQualites (une entree par qualite portee, pas par piece).
  Function PersonnageArmureBonusModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  // Qualites d'armure PORTEE, piece par piece (contrairement a PersonnageArmureQualites, qui
  // aplatit et compte l'equipement possede non porte) - base pour moduler le malus ARMOB par
  // Practical/Unreliable de la piece (CONTEXT.md 2.59). Meme extraction catalogue+fabrication
  // et meme resolution des alternatives que PersonnageArmureBonusTalent.
  Function PersonnageArmureQualitesPortees(Personnage: StructurePersonnage): TArrayPersonnageArmureQualitePortee;
  // Moteur generique cote FABRICATION (ChargeFabrication.ListFabricationModificateur) : somme,
  // sur les pieces d'armure PORTEES, des modificateurs (TypeModif, Cible) declares par leurs
  // qualites de fabrication (QualiteEquipement, "CODE niveau"), multiplies par le niveau.
  // Pilote : Rune of Stone (+1 PA par rune). 19/09/2026.
  Function PersonnageFabricationArmureModif(Personnage: StructurePersonnage; CodeLocalisation: String): Integer;
  // Meme somme pour n'importe quel TypeModif (ModifArmour, ModifyCarac...) : PersonnageFabricationArmureModif
  // en est le cas ModifArmour. Rune of Fortitude (+10 Endurance par rune). 20/09/2026.
  Function PersonnageFabricationModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String): Integer;
  Function PersonnageSourcesModif(Personnage: StructurePersonnage): TArraySourceModif;
  Function PersonnageModificateurUnique(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''; SansFabrication: Boolean = False; MaxParPiece: Boolean = False; SeulementFabrication: Boolean = False): Integer;
  // Mains : une arme est a distance si son code porte le prefixe EquipementCT. Deux budgets
  // separes (contact / distance, jamais utilises ensemble). Nombre de mains = base + ModifyHands.
  Function ArmeEstADistance(CodeArme: String): Boolean;
  Function PersonnageNombreMains(Personnage: StructurePersonnage): Integer;
  // V1 : alignement de la fiche (code RULES-V1ALIGN_xxx) ; a defaut, le standard de la race (Bon pour les Elfes, Neutre pour les autres)
  Function PersonnageAlignementV1(Personnage: StructurePersonnage): String;
  Function PersonnageMainsUtilisees(Personnage: StructurePersonnage; ADistance: Boolean): Integer;
  Function PersonnageMainsDepassees(Personnage: StructurePersonnage): Boolean;
  Function PersonnageCompetenceModificateur(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  Function PersonnageFabricationAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  // Malus/bonus ARMOB d'une competence, piece PORTEE par piece PORTEE, module par
  // Practical/Unreliable DE LA piece qui le porte (reduit de 10 plancher 0 / double - Rulebook,
  // CONTEXT.md 2.59). Destine a la colonne "avec equipement" du Pdf Feldo2P.
  Function PersonnageArmureBonusCompetenceModifPortee(Personnage: StructurePersonnage; CodeCompetence: String): Integer;

implementation

uses
  ChargeMetierAttribut;

////////////////////////////////////////////////////////////////////////////////
//                                 XML                                        //
////////////////////////////////////////////////////////////////////////////////



function PersonnageXmlFichierActuel(const Directory: string): string;
var
  SearchRec:       TSearchRec;
  HighestFileName: string;
begin
  HighestFileName := '';

  if FindFirst(Directory + PathDelim + '*.xml', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
      begin
        // Vérifier si le fichier a l'extension .xml
        if UpperCase(ExtractFileExt(SearchRec.Name)) = UpperCase('.xml') then
        begin
          // Comparer le nom du fichier avec le nom le plus élevé trouvé jusqu'à présent
          if HighestFileName = '' then
            HighestFileName := SearchRec.Name
          else if CompareText(SearchRec.Name, HighestFileName) > 0 then
            HighestFileName := SearchRec.Name;
        end;
      end;
    until FindNext(SearchRec) <> 0;
  end;

  if HighestFileName <> '' then
    Result := IncludeTrailingPathDelimiter(Directory) + HighestFileName
  else
    Result := '';
end;

// Lecture allegee de Personnage.GroupeId, sans charger toute la fiche (CONTEXT.md 2.100,
// utilisee par ChargeGroupe pour lister les membres d'un groupe sans ouvrir chaque
// personnage en entier).
function PersonnageGroupeIdFichier(const FileName: String): String;
var
  XMLDoc:     TXMLDocument;
  PlayerNode: TDOMNode;
begin
  Result := '';
  XMLDoc := TXMLDocument.Create;
  try
    ReadXMLFile(XMLDoc, FileName);
    PlayerNode := XMLDoc.DocumentElement;
    if Assigned(PlayerNode) and (PlayerNode.NodeName = ConstXmlPersonnage) then
      if Assigned(PlayerNode.FindNode(ConstXmlGroupeId)) then
        Result := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlGroupeId).TextContent));
  finally
    XMLDoc.Free;
  end;
end;

// Lecture allegee pour la liste du menu (ChargerPersonnages) : seulement metier, niveau, race,
// XP et livres obligatoires, sans construire toute la fiche (la lecture complete de chaque
// personnage rendait le demarrage long). Rend False si la fiche a un bloc d'objets propres :
// il faut alors la charger en entier (l'injection de ces objets conditionne chercheMetier).
function PersonnageResumeFichier(const FileName: String; out Personnage: StructurePersonnage): Boolean;
var
  XMLDoc:     TXMLDocument;
  PlayerNode: TDOMNode;
  Metier:     StructurePersonnageMetier;

  function Texte(const Balise: String): String;
    var
      N: TDOMNode;
    begin
      N := PlayerNode.FindNode(Balise);
      if Assigned(N) then
        Result := RemoveQuotes(UTF8Encode(N.TextContent))
      else
        Result := '';
    end;

begin
  Result := False;
  XMLDoc := TXMLDocument.Create;
  try
    ReadXMLFile(XMLDoc, FileName);
    PlayerNode := XMLDoc.DocumentElement;
    if Assigned(PlayerNode) and (PlayerNode.NodeName = ConstXmlPersonnage) then
      if not Assigned(PlayerNode.FindNode(ConstXmlObjetsPropres)) then
        begin
          Personnage.XpTotal            := StrToIntDef(Texte(ConstXmlXp), 0);
          Personnage.XpActuel           := StrToIntDef(Texte(ConstXmlXpCurrent), 0);
          Metier.CodeMetier             := Texte(ConstXmlWork);
          Metier.NiveauMetier           := StrToIntDef(Texte(ConstXmlNvWork), 0);
          Personnage.MetierEnCours      := Metier;
          Personnage.Race               := Texte(ConstXmlRace);
          Personnage.LivresObligatoires := StringReplace(Texte(ConstXmlLibelleLivre),
                                             AjouteAccolade(ConstLivreObjetsPropres), '', [rfReplaceAll]);
          Result := True;
        end;
  finally
    XMLDoc.Free;
  end;
end;

Function XmlAttributEquipementPorte(Porte: Boolean): String;
  // Attribut XML optionnel ajoute a la ligne d'equipement : absent si non porte, pour que
  // les fiches deja sauvegardees (sans le champ) soient lues comme "rien d'equipe".
  begin
    if Porte then
      Result := ' '+ConstXmlEquipementPorte+'="1"'
    else
      Result := '';
  end;

Function XmlAttributEquipementQuantite(Quantite: Integer): String;
  // Meme principe que XmlAttributEquipementPorte : absent si Quantite=1 (cas normal), pour
  // que les fiches deja sauvegardees (sans le champ) soient lues comme "un seul exemplaire".
  begin
    if Quantite <> 1 then
      Result := ' '+ConstXmlEquipementQuantite+'="'+IntToStr(Quantite)+'"'
    else
      Result := '';
  end;

Function XmlAttributEquipementInstance(Equipement: StructurePersonnageEquipement): String;
  // Attributs id (animal) et carriedby (objet confie a un animal), absents si vides pour que
  // les fiches deja sauvegardees restent lisibles. Ne passe pas par RemoveQuotes : A1, A2...
  begin
    Result := '';
    if Equipement.IdInstance <> '' then
      Result := Result + ' '+ConstXmlEquipementId+'="'+Equipement.IdInstance+'"';
    if Equipement.PortePar <> '' then
      Result := Result + ' '+ConstXmlEquipementPortePar+'="'+Equipement.PortePar+'"';
    if Equipement.NomLibre <> '' then
      Result := Result + ' '+ConstXmlNom+'="'+Equipement.NomLibre+'" '+ConstXmlEncombrement+'="'+IntToStr(Equipement.EncLibre)+'"';
  end;

Function IdAnimalLibre(const Liste: TArrayPersonnageEquipement): String;
  var
    N, Ind:  Integer;
    Pris:    Boolean;
  begin
    N := 0;
    repeat
      Inc(N);
      Result := 'A' + IntToStr(N);
      Pris   := False;
      for Ind := 0 to High(Liste) do
        if Liste[Ind].IdInstance = Result then
          Pris := True;
    until not Pris;
  end;

Procedure LitEquipementInstance(Node: TDOMNode; var Equipement: StructurePersonnageEquipement);
  // Lit id et carriedby de la ligne ; remet a vide si absents (Equipement est une variable
  // reutilisee d'une ligne a l'autre, sinon la valeur de la ligne precedente resterait).
  begin
    Equipement.IdInstance := '';
    Equipement.PortePar   := '';
    Equipement.NomLibre   := '';
    Equipement.EncLibre   := 0;
    if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementId)) then
      Equipement.IdInstance := UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementId).NodeValue);
    if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementPortePar)) then
      Equipement.PortePar   := UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementPortePar).NodeValue);
    if Assigned(Node.Attributes.GetNamedItem(ConstXmlNom)) then
      begin
        Equipement.NomLibre := UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlNom).NodeValue);
        if Assigned(Node.Attributes.GetNamedItem(ConstXmlEncombrement)) then
          Equipement.EncLibre := StrToIntDef(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEncombrement).NodeValue), 0);
      end;
  end;

Function PersonnageLivre(ListeLivre: String; Livre: String): String;
Var
  AjoutLivre: String;
Begin
   // Un livre vide n'a rien a faire dans la liste : c'est ce qui produisait le "[]" que Nono
   // trainait de longue date, visible en fin de fiche sous la forme "[BOOK RULESBOOK][]".
   // Il apparait des qu'un element n'est pas retrouve dans les listes chargees - du texte
   // libre d'equipement, un code d'un livre decoche, ou une recherche faite sur la mauvaise
   // variable (deux cas corriges juste en dessous). CONTEXT.md 2.19.
   // Meme chose pour le livre virtuel des objets propres au personnage : il n'a pas de fichier, la
   // fiche l'embarque (CUSTOM_ITEMS), donc il ne doit jamais etre exige a l'ouverture.
   if (Livre = '') or (Livre = ConstLivreObjetsPropres) then
     begin
       Result := ListeLivre;
       Exit;
     end;
   AjoutLivre   := AjouteAccolade(Livre);
   if Pos(AjoutLivre, ListeLivre) = 0 then
     ListeLivre := ListeLivre + AjoutLivre;
   result       := ListeLivre;
end;

Function CodeNormalise(Code, Livre: String): String;
  // Ajoute le prefixe de livre a un code avant ecriture, mais SEULEMENT si l'element a ete
  // retrouve dans les listes chargees (Livre non vide).
  //
  // Deux raisons a cette prudence :
  //  - l'equipement melange des codes et du TEXTE LIBRE ("Practical Tunic and Robes") ; le
  //    texte libre n'est jamais retrouve, donc jamais prefixe ;
  //  - un code inconnu (livre decoche, coquille) ressort intact et reste reperable, plutot
  //    que de recevoir un prefixe invente.
  //
  // Le test sur Livre n'est fiable que depuis le 22/08/2026 : avant, les fonctions Cherche*
  // renvoyaient l'enregistrement de l'appel PRECEDENT quand elles ne trouvaient rien, donc
  // .Livre etait celui d'un autre element (CONTEXT.md 2.17).
  //
  // XmlCreeCodeLivre est idempotente : un code deja prefixe ressort tel quel.
  begin
    if Livre <> '' then
      Result := XmlCreeCodeLivre(Livre, Code)
    else
      Result := Code;
  end;

// Premier element enfant d'un noeud (la ligne d'equipement fabriquee peut etre precedee de blancs).
function PremierElement(Parent: TDOMNode): TDOMNode;
  begin
    Result := Parent.FirstChild;
    while Assigned(Result) and (Result.NodeType <> ELEMENT_NODE) do
      Result := Result.NextSibling;
  end;

function XmlDocDeTexte(const Texte: String): TXMLDocument;
  var
    Flux: TStringStream;
  begin
    Result := nil;
    Flux   := TStringStream.Create(Texte);
    try
      ReadXMLFile(Result, Flux);
    finally
      Flux.Free;
    end;
  end;

// Le fichier de la fiche cible n'est jamais modifie : l'objet est ajoute dans un nouveau
// fichier date, comme le fait l'enregistrement d'une fiche (la plus recente par nom l'emporte).
function PersonnageDonneObjet(const Fichier: String; Equipement: StructurePersonnageEquipement;
  const Elements: String): Boolean;
var
  Doc, DocLigne, DocElem:                 TXMLDocument;
  Racine, Chapitre, SousChapitre, Noeud:  TDOMNode;
  Objets, Existant, Copie:                TDOMNode;
  NomSousChapitre, CodeFiche, Livre:      String;
  Ligne, Typ, Id:                         String;
  Cible:                                  String;
  Deja:                                   Boolean;
  PArme:                                  StructureArme;
  PArmure:                                StructureArmure;
  PArmureSimplifiee:                      StructureArmureSimplifiee;
begin
  Result := False;
  Doc := nil; DocLigne := nil; DocElem := nil;
  // Rien de ce qui lie l'objet a l'ancien proprietaire ne le suit.
  Equipement.IdInstance := '';
  Equipement.PortePar   := '';
  Equipement.Porte      := False;
  Livre                 := '';
  Typ                   := TrimRight(Equipement.TypeEquipement);
  if Typ = TrimRight(TypeEquipWe) then
    begin
      PArme.CodeArme  := '';
      PArme           := ChercheArme(Equipement.CodeEquipement);
      NomSousChapitre := ConstXmlSousChapitreArme;
      Livre           := PArme.Livre;
      CodeFiche       := CodeNormalise(Equipement.CodeEquipement, PArme.Livre);
    end
  else if Typ = TrimRight(TypeEquipAr) then
    begin
      PArmure.CodeArmure := '';
      PArmure            := ChercheArmure(Equipement.CodeEquipement);
      NomSousChapitre    := ConstXmlSousChapitreArmure;
      Livre              := PArmure.Livre;
      CodeFiche          := CodeNormalise(Equipement.CodeEquipement, PArmure.Livre);
    end
  else if Typ = TrimRight(TypeEquipArS) then
    begin
      PArmureSimplifiee.CodeArmure := '';
      PArmureSimplifiee            := ChercheArmureSimplifiee(Equipement.CodeEquipement);
      NomSousChapitre              := ConstXmlSousChapitreArmureSimp;
      Livre                        := PArmureSimplifiee.Livre;
      CodeFiche                    := CodeNormalise(Equipement.CodeEquipement, PArmureSimplifiee.Livre);
    end
  else
    begin
      NomSousChapitre := ConstXmlSousChapitreDivers;
      CodeFiche       := Equipement.CodeEquipement;
    end;
  Ligne := XmlLigneDonnee(ConstXmlItem, CodeFiche, QualiteSansMarqueur(Equipement.QualiteEquipement),
             XmlAttributEquipementPorte(False)+XmlAttributEquipementInstance(Equipement)
             +XmlAttributEquipementQuantite(Equipement.Quantite));
  try
    ReadXMLFile(Doc, Fichier);
    Racine := Doc.DocumentElement;
    if not (Assigned(Racine) and (Racine.NodeName = ConstXmlPersonnage)) then Exit;
    DocLigne := XmlDocDeTexte('<R>' + Ligne + '</R>');

    Chapitre := Racine.FindNode(ConstXmlChapitreEquipement);
    if not Assigned(Chapitre) then
      begin
        Chapitre := Doc.CreateElement(ConstXmlChapitreEquipement);
        Racine.AppendChild(Chapitre);
      end;
    SousChapitre := Chapitre.FindNode(NomSousChapitre);
    if not Assigned(SousChapitre) then
      begin
        SousChapitre := Doc.CreateElement(NomSousChapitre);
        Chapitre.AppendChild(SousChapitre);
      end;
    SousChapitre.AppendChild(Doc.ImportNode(PremierElement(DocLigne.DocumentElement), True));

    // Livre de l'objet : la fiche cible doit l'exiger pour pouvoir le relire.
    Noeud := Racine.FindNode(ConstXmlLibelleLivre);
    if Assigned(Noeud) and (Livre <> '') then
      Noeud.TextContent := UTF8Decode('"' + PersonnageLivre(RemoveQuotes(UTF8Encode(Noeud.TextContent)), Livre) + '"');

    // Objet propre : son element et ses qualites propres rejoignent le CUSTOM_ITEMS de la cible
    if Trim(Elements) <> '' then
      begin
        DocElem := XmlDocDeTexte('<' + ConstXmlObjetsPropres + '>' + Elements + '</' + ConstXmlObjetsPropres + '>');
        Objets  := Racine.FindNode(ConstXmlObjetsPropres);
        if not Assigned(Objets) then
          begin
            Objets := Doc.CreateElement(ConstXmlObjetsPropres);
            Racine.AppendChild(Objets);
          end;
        Noeud := DocElem.DocumentElement.FirstChild;
        while Assigned(Noeud) do
          begin
            if Noeud.NodeType = ELEMENT_NODE then
              begin
                Id       := UTF8Encode(TDOMElement(Noeud).GetAttribute('id'));
                Deja     := False;
                Existant := Objets.FirstChild;
                while Assigned(Existant) and not Deja do
                  begin
                    if (Existant.NodeType = ELEMENT_NODE)
                       and (UTF8Encode(TDOMElement(Existant).GetAttribute('id')) = Id) then
                      Deja := True;
                    Existant := Existant.NextSibling;
                  end;
                if not Deja then
                  begin
                    Copie := Doc.ImportNode(Noeud, True);
                    Objets.AppendChild(Copie);
                  end;
              end;
            Noeud := Noeud.NextSibling;
          end;
      end;

    Cible := ExtractFilePath(Fichier) + FormatDateTime('yyyymmdd', Date) + '-' + FormatDateTime('hhnnss', Time) + '.xml';
    if FileExists(Cible) then Exit;
    WriteXMLFile(Doc, Cible);
    Result := FileExists(Cible);
  finally
    DocElem.Free;
    DocLigne.Free;
    Doc.Free;
  end;
end;

function PersonnageXmlCreation(Personnage: StructurePersonnage; Xp: Integer; XpRestante: Integer; fileName: string; PersonnageName: String): Boolean;
var
  XMLContent:            TStringList;
  PRace:                  StructureRace;
  PMetier:                StructureMetier;
  PAttribut:              StructureAttribut;
  PCompetence:            StructureCompetence;
  PTalent:                StructureTalent;
  PArme:                  StructureArme;
  PArmure:                StructureArmure;
  PArmureSimplifiee:      StructureArmureSimplifiee;
  PSort:                  StructureSort;
  PCorruptionTable:       StructureCorruptionTable;
  PAffliction:            StructureAffliction;
  PDisease:               StructureDisease;
  ListeLivres:            String = '';
  procedure EcritGenerales;
  begin
      // Générales
      XMLContent.Add(XmlLigne(ConstXmlName, PersonnageName));
      XMLContent.Add(XmlLigne(ConstXmlRace, Personnage.Race));
      PRace := ChercheRace(Personnage.Race);
      ListeLivres:= PersonnageLivre(ListeLivres, PRAce.livre);
      // Le signe astral vient d'un livre : sans lui, ses effets disparaitraient en silence.
      if Personnage.SigneAstral <> '' then
        ListeLivres:= PersonnageLivre(ListeLivres, ChercheSigneAstral(Personnage.SigneAstral).Livre);
      XMLContent.Add(XmlCommentaire(PRace.Libelle));
      XMLContent.Add(XmlLigne(ConstXmlAge, IntToStr(Personnage.Age)));
      if Personnage.PointsMagie > 0 then
        XMLContent.Add(XmlLigne(ConstXmlMagicPoints, IntToStr(Personnage.PointsMagie)));
      if Personnage.AlignementV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlAlignmentPerso, Personnage.AlignementV1));
      if Personnage.FolieV1 > 0 then
        XMLContent.Add(XmlLigne(ConstXmlInsanityPoints, IntToStr(Personnage.FolieV1)));
      if Personnage.NaissanceV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlBirthPlaceV1, Personnage.NaissanceV1));
      if Personnage.ParentsV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlParentsJobV1, Personnage.ParentsV1));
      if Personnage.FamilleV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlFamilyMembersV1, Personnage.FamilleV1));
      if Personnage.HandicapsV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlDisabilitiesV1, Personnage.HandicapsV1));
      if Personnage.FamilierV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlFamiliarV1, Personnage.FamilierV1));
      if Personnage.SortsV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlSpellsLearnedV1, Personnage.SortsV1));
      if Personnage.EchecsSortsV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlSpellFailuresV1, Personnage.EchecsSortsV1));
      if Personnage.MagicienMauvaisV1 then
        XMLContent.Add(XmlLigne(ConstXmlEvilWizardV1, '1'));
      if Personnage.ClasseV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlClasseV1, Personnage.ClasseV1));
      if Personnage.CulteV1 <> '' then
        XMLContent.Add(XmlLigne(ConstXmlCulteV1, Personnage.CulteV1));
      XMLContent.Add(XmlLigne(ConstXmlHeight, IntToStr(Personnage.Height)));
      XMLContent.Add(XmlLigne(ConstXmlHeightUnit, Personnage.HeightUnit));
      XMLContent.Add(XmlLigne(ConstXmlHairColors, Personnage.HairColors));
      XMLContent.Add(XmlLigne(ConstXmlEyeColors, Personnage.EyeColors));
      // Sous-bloc V2 : ecrit seulement si une donnee existe (les fiches V4/V5 restent inchangees)
      if (Personnage.SexeV2 <> '') or (Personnage.PoidsV2 <> 0) or (Personnage.FratrieV2 <> '') or (Personnage.SigneDistinctifV2 <> '')
         or (Personnage.NaissanceV2 <> '') or (Personnage.AstreV2 <> '') then
        begin
          XMLContent.Add(XmlDebut(ConstXmlFicheV2));
          if Personnage.SexeV2 <> '' then
            XMLContent.Add(XmlLigne(ConstXmlFicheSexe, Personnage.SexeV2));
          if Personnage.PoidsV2 <> 0 then
            XMLContent.Add(XmlLigne(ConstXmlFichePoids, IntToStr(Personnage.PoidsV2)));
          if Personnage.FratrieV2 <> '' then
            XMLContent.Add(XmlLigne(ConstXmlFicheFratrie, Personnage.FratrieV2));
          if Personnage.SigneDistinctifV2 <> '' then
            XMLContent.Add(XmlLigne(ConstXmlFicheSigneDistinctif, Personnage.SigneDistinctifV2));
          if Personnage.NaissanceV2 <> '' then
            XMLContent.Add(XmlLigne(ConstXmlFicheNaissance, Personnage.NaissanceV2));
          if Personnage.AstreV2 <> '' then
            XMLContent.Add(XmlLigne(ConstXmlFicheAstreV2, Personnage.AstreV2));
          XMLContent.Add(XmlFin(ConstXmlFicheV2));
        end;
      XMLContent.Add(XmlLigne(ConstXmlAmbitionCourt, Personnage.AmbitionCourt));
      XMLContent.Add(XmlLigne(ConstXmlAmbitionLong, Personnage.AmbitionLong));
      XMLContent.Add(XmlLigne(ConstXmlAmbitionGroupeCourt, Personnage.AmbitionGroupeCourt));
      XMLContent.Add(XmlLigne(ConstXmlAmbitionGroupeLong, Personnage.AmbitionGroupeLong));
      if Personnage.GroupeId <> '' then
        XMLContent.Add(XmlLigne(ConstXmlGroupeId, Personnage.GroupeId));
      if Personnage.MonnaieCO <> 0 then
        XMLContent.Add(XmlLigne(ConstXmlMonnaieCO, IntToStr(Personnage.MonnaieCO)));
      if Personnage.MonnaiePA <> 0 then
        XMLContent.Add(XmlLigne(ConstXmlMonnaiePA, IntToStr(Personnage.MonnaiePA)));
      if Personnage.MonnaieSB <> 0 then
        XMLContent.Add(XmlLigne(ConstXmlMonnaieSB, IntToStr(Personnage.MonnaieSB)));
      if Personnage.SigneAstral <> '' then
        begin
          XMLContent.Add(XmlLigne(ConstXmlSigneAstral, Personnage.SigneAstral));
          if Personnage.SigneAstralVariante <> '' then
            XMLContent.Add(XmlLigne(ConstXmlSigneVariantePerso, Personnage.SigneAstralVariante));
          if Personnage.SigneAstralTalent <> '' then
            XMLContent.Add(XmlLigne(ConstXmlSigneTalentPerso, Personnage.SigneAstralTalent));
        end;

      XMLContent.Add(XmlLigne(ConstXmlWork, Personnage.MetierEnCours.CodeMetier));
      PMetier := chercheMetier(Personnage.MetierEnCours.CodeMetier);
      ListeLivres:= PersonnageLivre(ListeLivres, PMetier.livre);
      XMLContent.Add(XmlCommentaire(PMetier.Libelle));

      XMLContent.Add(XmlLigne(ConstXmlNvWork, IntToStr(Personnage.MetierEnCours.NiveauMetier)));
      XMLContent.Add(XmlLigne(ConstXmlXp, InttoStr(Xp)));
      if Pos(AjouteAccolade(ConstXmlOptionXpDiv25), Personnage.Options) > 0 then
        XMLContent.Add(XmlLigne(ConstXmlXp25Total, InttoStr(trunc(Xp/25))));
      XMLContent.Add(XmlLigne(ConstXmlXpCurrent, InttoStr(XpRestante)));
  end;

  procedure EcritCreation;
  var
  PersonnageAttribut:     StructurePersonnageAttribut;
  PersonnageCompetence:   StructurePersonnageCompetence;
  PersonnageTalent:       StructurePersonnageTalent;
  begin
      // Création
      XMLContent.Add(XmlDebut(ConstXmlChapitreCreation));
        // Attributs
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCarac));
        for PersonnageAttribut in Personnage.CreationAttribut do
          begin
            PAttribut := ChercheAttribut(PersonnageAttribut.CodeAttribut);
            // Le code d'attribut est normalise avec son prefixe de livre avant ecriture.
            // Les augmentations viennent de TabAttribut (WinPersonnage), dont la ligne de
            // codes est semee par AttributInit a partir des constantes ConstCaracXxx, qui
            // valent 'ATTR_WS' SANS prefixe - d'ou des fiches melangeant les deux formes,
            // et un filtre de sorts qui ne matchait plus (CONTEXT.md 2.19). XmlCreeCodeLivre
            // est idempotente : elle ne prefixe que si le code ne l'est pas deja.
            XMLContent.Add(XmlLigneDonnee(ConstXmlCarac,
              XmlCreeCodeLivre(PAttribut.Livre, PersonnageAttribut.CodeAttribut),
              IntToStr(PersonnageAttribut.Valeur)));
            XMLContent.Add(XmlCommentaire(PAttribut.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCarac));

        // Compétences 3 et 5
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCompSpecie));
        for PersonnageCompetence in Personnage.CreationCompetence35 do
          Begin
            PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
            XMLContent.Add(XmlLigneDonnee(ConstXmlCompetence,
              CodeNormalise(PersonnageCompetence.CodeCompetence, PCompetence.Livre),
              IntToStr(PersonnageCompetence.Valeur)));
            ListeLivres:= PersonnageLivre(ListeLivres, PCompetence.livre);
            XMLContent.Add(XmlCommentaire(PCompetence.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCompSpecie));

        // Compétences 40 pts
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCompCreation));
        for PersonnageCompetence in Personnage.CreationCompetence40 do
          begin
            PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
            XMLContent.Add(XmlLigneDonnee(ConstXmlCompetence,
              CodeNormalise(PersonnageCompetence.CodeCompetence, PCompetence.Livre),
              IntToStr(PersonnageCompetence.Valeur)));
            ListeLivres:= PersonnageLivre(ListeLivres, PCompetence.livre);
            XMLContent.Add(XmlCommentaire(PCompetence.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCompCreation));

        // Talents
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreTalent));
        for Personnagetalent in Personnage.CreationTalent do
          Begin
            PTalent := ChercheTalent(PersonnageTalent.CodeTalent);
            XMLContent.Add(XmlLigneDonnee(ConstXmlTalent,
              CodeNormalise(PersonnageTalent.CodeTalent, PTalent.Livre),
              IntToStr(PersonnageTalent.Valeur)));
            ListeLivres:= PersonnageLivre(ListeLivres, PTalent.livre);
            XMLContent.Add(XmlCommentaire(PTalent.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreTalent));
      XMLContent.Add(XmlFin(ConstXmlChapitreCreation));
  end;

  procedure EcritAugmentation;
  var
  PersonnageAttribut:     StructurePersonnageAttribut;
  PersonnageCompetence:   StructurePersonnageCompetence;
  PersonnageTalent:       StructurePersonnageTalent;
  begin
      // Augmentation
      XMLContent.Add(XmlDebut(ConstXmlChapitreAugmentation));
        // Attributs
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCarac));
        for PersonnageAttribut in Personnage.AugmentationAttribut do
          begin
            PAttribut := ChercheAttribut(PersonnageAttribut.CodeAttribut);
            // Le code d'attribut est normalise avec son prefixe de livre avant ecriture.
            // Les augmentations viennent de TabAttribut (WinPersonnage), dont la ligne de
            // codes est semee par AttributInit a partir des constantes ConstCaracXxx, qui
            // valent 'ATTR_WS' SANS prefixe - d'ou des fiches melangeant les deux formes,
            // et un filtre de sorts qui ne matchait plus (CONTEXT.md 2.19). XmlCreeCodeLivre
            // est idempotente : elle ne prefixe que si le code ne l'est pas deja.
            XMLContent.Add(XmlLigneDonnee(ConstXmlCarac,
              XmlCreeCodeLivre(PAttribut.Livre, PersonnageAttribut.CodeAttribut),
              IntToStr(PersonnageAttribut.Valeur)));
            XMLContent.Add(XmlCommentaire(PAttribut.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCarac));

        // Compétences
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCompMetier));
        for PersonnageCompetence in Personnage.AugmentationCompetence do
          begin
            PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
            XMLContent.Add(XmlLigneDonnee(ConstXmlCompetence,
              CodeNormalise(PersonnageCompetence.CodeCompetence, PCompetence.Livre),
              IntToStr(PersonnageCompetence.Valeur)));
            ListeLivres:= PersonnageLivre(ListeLivres, PCompetence.livre);
            XMLContent.Add(XmlCommentaire(PCompetence.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCompMetier));

        // Talents
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreTalent));
        for Personnagetalent in Personnage.AugmentationTalent do
          Begin
            PTalent := ChercheTalent(PersonnageTalent.CodeTalent);
            XMLContent.Add(XmlLigneDonnee(ConstXmlTalent,
              CodeNormalise(PersonnageTalent.CodeTalent, PTalent.Livre),
              IntToStr(PersonnageTalent.Valeur)));
            ListeLivres:= PersonnageLivre(ListeLivres, PTalent.livre);
            XMLContent.Add(XmlCommentaire(PTalent.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreTalent));
      XMLContent.Add(XmlFin(ConstXmlChapitreAugmentation));
  end;

  procedure EcritCarriere;
  var
  PersonnageCompetence:   StructurePersonnageCompetence;
  PersonnageMetier:       StructurePersonnageMetier;
  PersonnageTalent:       StructurePersonnageTalent;
  begin
      // Compétence de Metier en cours
      XMLContent.Add(XmlDebut(ConstXmlChapitreCompetence));
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCompMetier));
        for PersonnageCompetence in Personnage.MetierCompetence do
          begin
            PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
            XMLContent.Add(XmlLigneDonnee(ConstXmlCompetence,
              CodeNormalise(PersonnageCompetence.CodeCompetence, PCompetence.Livre),
              IntToStr(PersonnageCompetence.Valeur)));
            ListeLivres:= PersonnageLivre(ListeLivres, PCompetence.livre);
            XMLContent.Add(XmlCommentaire(PCompetence.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCompMetier));
      XMLContent.Add(XmlFin(ConstXmlChapitreCompetence));

      // Talents de Metier en cours
      XMLContent.Add(XmlDebut(ConstXmlChapitreTalent));
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreTalMetier));
        for PersonnageTalent in Personnage.MetierTalent do
          begin
            PTalent     := ChercheTalent(PersonnageTalent.CodeTalent);
            XMLContent.Add(XmlLigneDonnee(ConstXmlTalent,
              CodeNormalise(PersonnageTalent.CodeTalent, PTalent.Livre),
              IntToStr(PersonnageTalent.Valeur)));
            ListeLivres := PersonnageLivre(ListeLivres, PTalent.livre);
            XMLContent.Add(XmlCommentaire(PTalent.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreTalMetier));
      XMLContent.Add(XmlFin(ConstXmlChapitreTalent));

      // anciens métiers
      XMLContent.Add(XmlDebut(ConstXmlChapitreOldWork));
        For PersonnageMetier in Personnage.MetierAncien do
          begin
            // chercheMetier portait sur Personnage.MetierEnCours et non sur le metier de la
            // boucle : la liste des livres recevait le livre du metier COURANT pour chaque
            // ancien metier. Corrige en meme temps que le prefixe. CONTEXT.md 2.19.
            PMetier := chercheMetier(PersonnageMetier.CodeMetier);
            XMLContent.Add(XmlLigneDonnee(ConstXmlWork,
              CodeNormalise(PersonnageMetier.CodeMetier, PMetier.Livre)+SeparateurMulti+IntToStr(PersonnageMetier.NiveauMetier),
              IntToStr(PersonnageMetier.CoutXp)));
            ListeLivres:= PersonnageLivre(ListeLivres, PMetier.livre);
            XMLContent.Add(XmlCommentaire(PMetier.Libelle));
          end;
      XMLContent.Add(XmlFin(ConstXmlChapitreOldWork));
  end;

  procedure EcritEquipement;
  var
  PersonnageEquipement:   StructurePersonnageEquipement;
  begin
      // Equipement
      XMLContent.Add(XmlDebut(ConstXmlChapitreEquipement));

        // Armes
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreArme));
        for PersonnageEquipement in Personnage.Equipement do
          if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe) then
            begin
             PArme.CodeArme:='';
             PArme := ChercheArme(PersonnageEquipement.CodeEquipement);
             XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
               CodeNormalise(PersonnageEquipement.CodeEquipement, PArme.Livre),
               QualiteSansMarqueur(PersonnageEquipement.QualiteEquipement),
               XmlAttributEquipementPorte(PersonnageEquipement.Porte)+XmlAttributEquipementInstance(PersonnageEquipement)
               +XmlAttributEquipementQuantite(PersonnageEquipement.Quantite)));
             ListeLivres:= PersonnageLivre(ListeLivres, PArme.livre);
             if (PArme.CodeArme <> '') then
               XMLContent.Add(XmlCommentaire(PArme.Libelle));
            end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreArme));

        // Armures
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreArmure));
        for PersonnageEquipement in Personnage.Equipement do
          if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAr) then
            begin
             PArmure.CodeArmure:='';
             PArmure := ChercheArmure(PersonnageEquipement.CodeEquipement);
             XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
               CodeNormalise(PersonnageEquipement.CodeEquipement, PArmure.Livre),
               QualiteSansMarqueur(PersonnageEquipement.QualiteEquipement),
               XmlAttributEquipementPorte(PersonnageEquipement.Porte)+XmlAttributEquipementInstance(PersonnageEquipement)
               +XmlAttributEquipementQuantite(PersonnageEquipement.Quantite)));
             ListeLivres:= PersonnageLivre(ListeLivres, PArmure.livre);
             if (PArmure.CodeArmure<>'') then
               XMLContent.Add(XmlCommentaire(PArmure.Libelle));
            end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreArmure));

        // Set d'armure
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreArmureSimp));
        for PersonnageEquipement in Personnage.Equipement do
          if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipArS) then
            begin
              PArmureSimplifiee.CodeArmure:='';
              PArmureSimplifiee := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement);
              XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                CodeNormalise(PersonnageEquipement.CodeEquipement, PArmureSimplifiee.Livre),
                QualiteSansMarqueur(PersonnageEquipement.QualiteEquipement),
                XmlAttributEquipementPorte(PersonnageEquipement.Porte)+XmlAttributEquipementInstance(PersonnageEquipement)
                +XmlAttributEquipementQuantite(PersonnageEquipement.Quantite)));
              // etait PArmure.livre : le livre de l'armure du bloc PRECEDENT. CONTEXT.md 2.19.
              ListeLivres:= PersonnageLivre(ListeLivres, PArmureSimplifiee.livre);
              if (PArmureSimplifiee.CodeArmure<>'') then
                XMLContent.Add(XmlCommentaire(PArmureSimplifiee .Libelle));
            end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreArmureSimp));

        // Divers
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreDivers));
        for PersonnageEquipement in Personnage.Equipement do
          if (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipDi))
             or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAN)) then
             XMLContent.Add(XmlLigneDonnee(ConstXmlItem, PersonnageEquipement.CodeEquipement, QualiteSansMarqueur(PersonnageEquipement.QualiteEquipement),
               XmlAttributEquipementPorte(PersonnageEquipement.Porte)+XmlAttributEquipementInstance(PersonnageEquipement)
               +XmlAttributEquipementQuantite(PersonnageEquipement.Quantite)));
        XMLContent.Add(XmlFin(ConstXmlSousChapitreDivers));

        // Sorts
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreSort));
        for PersonnageEquipement in Personnage.Equipement do
          if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipSp) then
            begin
             PSort.CodeSort:='';
             PSort := ChercheSort(PersonnageEquipement.CodeEquipement);
             XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
               CodeNormalise(PersonnageEquipement.CodeEquipement, PSort.Livre),
               IntToStr(PersonnageEquipement.CoutXp)));
             ListeLivres:= PersonnageLivre(ListeLivres, PSort.livre);
             if (PSort.CodeSort<>'') then
               XMLContent.Add(XmlCommentaire(PSort.Libelle));
            end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreSort));

      XMLContent.Add(XmlFin(ConstXmlChapitreEquipement));
  end;

  procedure EcritSuivi;
  var
  PersonnageCorruption:   StructurePersonnageCorruption;
  PersonnageMutation:     StructurePersonnageMutation;
  PersonnagePathologie:   StructurePersonnagePathologie;
  PersonnageTalentCarriere: StructurePersonnageTalentCarriereRequise;
  begin
      // Historique de corruption
      XMLContent.Add(XmlDebut(ConstXmlChapitreCorruption));
        for PersonnageCorruption in Personnage.Corruption do
          XMLContent.Add(XmlLigneDonnee(ConstXmlItem, IntToStr(PersonnageCorruption.Montant), PersonnageCorruption.Libelle));
      XMLContent.Add(XmlFin(ConstXmlChapitreCorruption));

      // Registres de Destin, de Resilience et de Resolution (meme forme que l'historique de corruption)
      XMLContent.Add(XmlDebut(ConstXmlChapitreDestin));
        for PersonnageCorruption in Personnage.Destin do
          XMLContent.Add(XmlLigneDonnee(ConstXmlItem, IntToStr(PersonnageCorruption.Montant), PersonnageCorruption.Libelle));
      XMLContent.Add(XmlFin(ConstXmlChapitreDestin));
      XMLContent.Add(XmlDebut(ConstXmlChapitreResilience));
        for PersonnageCorruption in Personnage.Resilience do
          XMLContent.Add(XmlLigneDonnee(ConstXmlItem, IntToStr(PersonnageCorruption.Montant), PersonnageCorruption.Libelle));
      XMLContent.Add(XmlFin(ConstXmlChapitreResilience));
      XMLContent.Add(XmlDebut(ConstXmlChapitreResolve));
        for PersonnageCorruption in Personnage.Resolve do
          XMLContent.Add(XmlLigneDonnee(ConstXmlItem, IntToStr(PersonnageCorruption.Montant), PersonnageCorruption.Libelle));
      XMLContent.Add(XmlFin(ConstXmlChapitreResolve));

      // Mutations obtenues (CONTEXT.md §2.7) - référence (Code stable du catalogue), pas le texte
      XMLContent.Add(XmlDebut(ConstXmlChapitreMutation));
        for PersonnageMutation in Personnage.Mutations do
          begin
            PCorruptionTable.Code := '';
            PCorruptionTable := ChercheCorruptionTable(PersonnageMutation.Code);
            if PersonnageMutation.ValeursEffets <> '' then
              XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                CodeNormalise(PersonnageMutation.Code, PCorruptionTable.Livre), '',
                ' valeursEffets="' + PersonnageMutation.ValeursEffets + '"'))
            else if PersonnageMutation.ValeurAleatoire <> 0 then
              XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                CodeNormalise(PersonnageMutation.Code, PCorruptionTable.Livre), '',
                ' valeurAleatoire="' + IntToStr(PersonnageMutation.ValeurAleatoire) + '"'))
            else
              XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                CodeNormalise(PersonnageMutation.Code, PCorruptionTable.Livre), ''));
            if (PCorruptionTable.Code <> '') then
              XMLContent.Add(XmlCommentaire(PCorruptionTable.Libelle));
          end;
      XMLContent.Add(XmlFin(ConstXmlChapitreMutation));

      // Afflictions possedees (Unofficial Grimoire) - reference (Code stable du catalogue),
      // pas le texte. Meme principe que Mutation, un chapitre par type (Nono : un seul
      // onglet cote IHM, mais Personnage.Pathologies distingue par TypeChapitre).
      XMLContent.Add(XmlDebut(ConstXmlChapitreAffliction));
        for PersonnagePathologie in Personnage.Pathologies do
          if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
            begin
              PAffliction := ChercheAffliction(PersonnagePathologie.Code);
              // ValeurAleatoire (jet 1dFace valide par Nono a l'ajout, ex. Weakness "-7
              // Strength") sauvegardee en attribut XML pour survivre au rechargement - sans
              // quoi elle retomberait a 0 (perte silencieuse du malus) ou, pire, resterait a
              // une valeur non initialisee (bug signale par Nono le 27/09/2026).
              if PersonnagePathologie.ValeurAleatoire <> 0 then
                XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                  CodeNormalise(PersonnagePathologie.Code, PAffliction.Livre), '',
                  ' valeurAleatoire="' + IntToStr(PersonnagePathologie.ValeurAleatoire) + '"'))
              else
                XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                  CodeNormalise(PersonnagePathologie.Code, PAffliction.Livre), ''));
              if (PAffliction.Code <> '') then
                XMLContent.Add(XmlCommentaire(PAffliction.Libelle));
            end;
      XMLContent.Add(XmlFin(ConstXmlChapitreAffliction));

      // Maladies possedees (Litany of Pestilence) - meme principe qu'Affliction ci-dessus.
      XMLContent.Add(XmlDebut(ConstXmlChapitreDisease));
        for PersonnagePathologie in Personnage.Pathologies do
          if PersonnagePathologie.TypeChapitre = ConstXmlChapitreDisease then
            begin
              PDisease := ChercheDisease(PersonnagePathologie.Code);
              XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
                CodeNormalise(PersonnagePathologie.Code, PDisease.Livre), ''));
              if (PDisease.Code <> '') then
                XMLContent.Add(XmlCommentaire(PDisease.Libelle));
            end;
      XMLContent.Add(XmlFin(ConstXmlChapitreDisease));

      // Talents dont les effets sont lies a une carriere+niveau precis (CONTEXT.md 2.78,
      // Virtue of the Quest) - fige au moment de l'octroi, compare a MetierEnCours a
      // l'affichage pour barrer le talent sans le retirer.
      XMLContent.Add(XmlDebut(ConstXmlChapitreTalentCarriere));
        for PersonnageTalentCarriere in Personnage.TalentCarriereRequise do
          begin
            PTalent := ChercheTalent(PersonnageTalentCarriere.CodeTalent);
            PMetier := chercheMetier(PersonnageTalentCarriere.CodeMetier);
            XMLContent.Add(XmlLigneDonnee(ConstXmlItem,
              CodeNormalise(PersonnageTalentCarriere.CodeTalent, PTalent.Livre),
              CodeNormalise(PersonnageTalentCarriere.CodeMetier, PMetier.Livre)+SeparateurMulti+IntToStr(PersonnageTalentCarriere.NiveauMetier)));
            ListeLivres := PersonnageLivre(ListeLivres, PTalent.Livre);
            XMLContent.Add(XmlCommentaire(PTalent.Libelle+' / '+PMetier.Libelle));
          end;
      XMLContent.Add(XmlFin(ConstXmlChapitreTalentCarriere));
  end;

  procedure EcritFin;
  var
  PersonnageCompetence:   StructurePersonnageCompetence;
  PersonnageAttribut:     StructurePersonnageAttribut;
  PersonnageXpAttribut:   StructurePersonnageXpAttribut;
  PersonnageXpCompetence: StructurePersonnageXpCompetence;
  PersonnageXpTalent:     StructurePersonnageXpTalent;
  begin
      // Livres
      XMLContent.Add(XmlLigne(ConstXmlLibelleLivre, ListeLivres));
      if Personnage.LivresAcceptes  = '' then
        Personnage.LivresAcceptes := ListeLivres;
      XMLContent.Add(XmlLigne(ConstXmlRegle,Personnage.LivresAcceptes));

      // Cout Xp hors norme
      XMLContent.Add(XmlDebut(ConstXmlChapitreCoutXp));

        // Attribut
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCarac));
        For PersonnageXpAttribut in Personnage.XpCoutAttribut do
          begin
            PAttribut := ChercheAttribut(PersonnageXpAttribut.CodeAttribut);
            // Le code est colle a ":debut-fin" : seul le code est prefixe.
            XMLContent.Add(XmlLigneDonnee(ConstXmlCarac,
              CodeNormalise(PersonnageXpAttribut.CodeAttribut, PAttribut.Livre)+DriveSeparator+IntToStr(PersonnageXpAttribut.Debut)+SeparateurChance+IntToStr(PersonnageXpAttribut.Fin),
              IntToStr(PersonnageXpAttribut.CoutXp)));
            PAttribut.CodeAttribut := '';
            PAttribut := ChercheAttribut(PersonnageXpAttribut.CodeAttribut);
            if (PAttribut.CodeAttribut <> '') then
              XMLContent.Add(XmlCommentaire(PAttribut.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCarac));

        // Compétence
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreCompetence));
        For PersonnageXpCompetence in Personnage.XpCoutCompetence do
          begin
            PCompetence := ChercheCompetence(PersonnageXpCompetence.CodeCompetence);
            // Le code est colle a ":debut-fin" : seul le code est prefixe.
            XMLContent.Add(XmlLigneDonnee(ConstXmlCompetence,
              CodeNormalise(PersonnageXpCompetence.CodeCompetence, PCompetence.Livre)+DriveSeparator+IntToStr(PersonnageXpCompetence.Debut)+SeparateurChance+IntToStr(PersonnageXpCompetence.Fin),
              IntToStr(PersonnageXpCompetence.CoutXp)));
            PCompetence.CodeCompetence := '';
            PCompetence := ChercheCompetence(PersonnageXpCompetence.CodeCompetence);
            if (PCompetence.CodeCompetence <> '') then
              XMLContent.Add(XmlCommentaire(PCompetence.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreCompetence));

        // Talent
        XMLContent.Add(XmlDebut(ConstXmlSousChapitreTalent));
        For PersonnageXpTalent in Personnage.XpCoutTalent do
          begin
            PTalent := ChercheTalent(PersonnageXpTalent.CodeTalent);
            // Le code est colle a ":debut-fin" : seul le code est prefixe.
            XMLContent.Add(XmlLigneDonnee(ConstXmlTalent,
              CodeNormalise(PersonnageXpTalent.CodeTalent, PTalent.Livre)+DriveSeparator+IntToStr(PersonnageXpTalent.Debut)+SeparateurChance+IntToStr(PersonnageXpTalent.Fin),
              IntToStr(PersonnageXpTalent.CoutXp)));
            PTalent.CodeTalent := '';
            PTalent := ChercheTalent(PersonnageXpTalent.CodeTalent);
            if (PTalent.CodeTalent <> '') then
              XMLContent.Add(XmlCommentaire(PTalent.Libelle));
          end;
        XMLContent.Add(XmlFin(ConstXmlSousChapitreTalent));

      XMLContent.Add(XmlFin(ConstXmlChapitreCoutXp));

      // Options
      XMLContent.Add(XmlLigne(ConstXmlOptions, Personnage.Options));

      // Objets propres au personnage : recopies tels quels (voir ObjetsPropres).
      if Personnage.ObjetsPropres <> '' then
        begin
          XMLContent.Add(XmlDebut(ConstXmlObjetsPropres));
          XMLContent.Add(Personnage.ObjetsPropres);
          XMLContent.Add(XmlFin(ConstXmlObjetsPropres));
        end;

      // Appartenances - voir CONTEXT.md 2.44.
      XMLContent.Add(XmlLigne(ConstXmlAppartenance, Personnage.Appartenance));
      XMLContent.Add(XmlLigne(ConstXmlChoixAdaptation, Personnage.ChoixAdaptation));

      // Competences choisies au titre d'un <SkillChoice> d'appartenance - champ dedie,
      // voir ChargeConstantes.ConstXmlSousChapitreCompAppartenance et le commentaire sur
      // StructurePersonnage.CompetenceAppartenance ci-dessus.
      XMLContent.Add(XmlDebut(ConstXmlSousChapitreCompAppartenance));
      for PersonnageCompetence in Personnage.CompetenceAppartenance do
        begin
          PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
          XMLContent.Add(XmlLigneDonnee(ConstXmlCompetence,
            CodeNormalise(PersonnageCompetence.CodeCompetence, PCompetence.Livre),
            IntToStr(PersonnageCompetence.Valeur)));
          ListeLivres:= PersonnageLivre(ListeLivres, PCompetence.livre);
          XMLContent.Add(XmlCommentaire(PCompetence.Libelle));
        end;
      XMLContent.Add(XmlFin(ConstXmlSousChapitreCompAppartenance));

      // Avance gratuite de creation V2 (champ dedie, voir StructurePersonnage).
      XMLContent.Add(XmlDebut(ConstXmlSousChapitreAvanceGratuite));
      for PersonnageAttribut in Personnage.AvanceGratuiteAttribut do
        begin
          PAttribut := ChercheAttribut(PersonnageAttribut.CodeAttribut);
          XMLContent.Add(XmlLigneDonnee(ConstXmlCarac,
            XmlCreeCodeLivre(PAttribut.Livre, PersonnageAttribut.CodeAttribut),
            IntToStr(PersonnageAttribut.Valeur)));
          XMLContent.Add(XmlCommentaire(PAttribut.Libelle));
        end;
      XMLContent.Add(XmlFin(ConstXmlSousChapitreAvanceGratuite));
  end;

begin
  Result := False; // Initialise le résultat à False
  XMLContent := TStringList.Create;
  try
    try
      // Construire le contenu XML
      XMLContent.Add(XmlDataBase());

      // Personnage
      XMLContent.Add(XmlDebut(ConstXmlPersonnage));

      EcritGenerales;
      EcritCreation;
      EcritAugmentation;
      EcritCarriere;
      EcritEquipement;
      EcritSuivi;
      EcritFin;
      XMLContent.Add(XmlFin(ConstXmlPersonnage));

      // Enregistrer le contenu XML dans un fichier
      XMLContent.SaveToFile(fileName);

      Result := True; // Définit le résultat à True si l'enregistrement s'est bien déroulé

    except
      on E: Exception do
        XmlSignale('Erreur lors de la creation de la fiche ' + fileName + ' : ' + E.Message);
    end;
  finally
    XMLContent.Free;
  end;
end;

function PersonnageXmlChargement(fileName: string): StructurePersonnage;
var
  XMLDoc:                     TXMLDocument;
  PlayerNode, ChapterRaceNode, ChapterItemNode, ItemNode, SubChapterNode, Node: TDOMNode;
  Code:                       String;
  Personnage:                 StructurePersonnage;
  PersonnageMetier:           StructurePersonnageMetier;
  PersonnageAttribut:         StructurePersonnageAttribut;
  PersonnageCompetence:       StructurePersonnageCompetence;
  PersonnageTalent:           StructurePersonnageTalent;
  PersonnageEquipement:       StructurePersonnageEquipement;
  PersonnageCorruption:       StructurePersonnageCorruption;
  PersonnageMutation:         StructurePersonnageMutation;
  PersonnagePathologie:       StructurePersonnagePathologie;
  PersonnageTalentCarriere:   StructurePersonnageTalentCarriereRequise;
  PersonnageXpAttribut:       StructurePersonnageXpAttribut;
  PersonnageXpCompetence:     StructurePersonnageXpCompetence;
  PersonnageXpTalent:         StructurePersonnageXpTalent;
  Asterisque:                 Integer = 0;
  FluxObjets:                 TStringStream;
  procedure LitIdentite;
  begin
    // Lire le nom du joueur
    Personnage.CreationAttribut     := [];
    Personnage.CreationCompetence35 := [];
    Personnage.CreationCompetence40 := [];
    Personnage.CreationTalent       := [];
    Personnage.Equipement           := [];
    Personnage.Corruption           := [];
    Personnage.Destin               := [];
    Personnage.Resilience           := [];
    Personnage.Resolve              := [];
    Personnage.Mutations            := [];
    Personnage.Pathologies          := [];
    Personnage.TalentCarriereRequise := [];
    Personnage.XpCoutAttribut       := [];
    Personnage.XpCoutCompetence     := [];
    Personnage.XpCoutTalent         := [];
    Personnage.CompetenceAppartenance := [];
    Personnage.AvanceGratuiteAttribut := [];

    Personnage.NomPersonnage        := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlName).TextContent));
    Personnage.XpTotal              := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlXp).TextContent)),0);
    // Le record n'est pas remis a zero : sans balise Xp25 (perso ancien, V1 / V2), Xp25Total gardait
    // une valeur au hasard (32763 constate sur la page Xp). Valeur par defaut = Xp / 25, comme a l'ecriture.
    Personnage.Xp25Total              := Personnage.XpTotal div 25;
    Personnage.XpActuel               := 0;
    if Assigned(PlayerNode.FindNode(ConstXmlXp25Total)) then
      Personnage.Xp25Total            := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlXp25Total).TextContent)),0);
    if Assigned(PlayerNode.FindNode(ConstXmlXpCurrent)) then
      Personnage.XpActuel           := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlXpCurrent).TextContent)),0);
    PersonnageMetier.CodeMetier     := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlWork).TextContent));
    PersonnageMetier.NiveauMetier   := StrToInt(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlNvWork).TextContent)));
    Personnage.MetierEnCours        := PersonnageMetier;
    Personnage.Race                 := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlRace).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlLibelleLivre)) then
      // [PERSO-OBJETS] : enregistre par erreur dans les fiches de test d'avant la correction de PersonnageLivre
      Personnage.LivresObligatoires := StringReplace(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlLibelleLivre).TextContent)),
                                         AjouteAccolade(ConstLivreObjetsPropres), '', [rfReplaceAll]);
    if Assigned(PlayerNode.FindNode(ConstXmlRegle)) then
      Personnage.LivresAcceptes     := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlRegle).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlOptions)) then
      Personnage.Options            := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlOptions).TextContent));
    // Objets propres : le contenu du bloc est garde en texte XML, puis injecte dans les listes
    // (l'injection est appelee meme sans bloc, pour retirer ceux du personnage precedent).
    Personnage.ObjetsPropres        := '';
    SubChapterNode := PlayerNode.FindNode(ConstXmlObjetsPropres);
    if Assigned(SubChapterNode) then
      begin
        FluxObjets := TStringStream.Create('');
        try
          Node := SubChapterNode.FirstChild;
          while Assigned(Node) do
            begin
              if Node.NodeType = ELEMENT_NODE then
                WriteXML(Node, FluxObjets);
              Node := Node.NextSibling;
            end;
          Personnage.ObjetsPropres := Trim(FluxObjets.DataString);
        finally
          FluxObjets.Free;
        end;
      end;
    InjecteObjetsPropres(Personnage.ObjetsPropres);
    // Balise absente des fiches enregistrees avant le 04/09/2026 : le test Assigned
    // suffit a les charger sans erreur, Appartenance reste vide. CONTEXT.md 2.44.
    Personnage.Appartenance         := '';
    Personnage.ChoixAdaptation      := '';
    if Assigned(PlayerNode.FindNode(ConstXmlChoixAdaptation)) then
      Personnage.ChoixAdaptation    := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlChoixAdaptation).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlAppartenance)) then
      Personnage.Appartenance       := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAppartenance).TextContent));

    // Competences choisies au titre d'un <SkillChoice> d'appartenance - champ dedie, voir
    // ChargeConstantes.ConstXmlSousChapitreCompAppartenance. Balise absente des fiches
    // enregistrees avant ce chantier : le test Assigned suffit, le tableau reste vide.
    SubChapterNode := PlayerNode.FindNode(ConstXmlSousChapitreCompAppartenance);
    if Assigned(SubChapterNode) then
      begin
        Node := SubChapterNode.FirstChild;
        while Assigned(Node) do
          begin
            if Node.NodeName = ConstXmlCompetence then
              begin
                PersonnageCompetence.CodeCompetence := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                PersonnageCompetence.Valeur          := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                Personnage.CompetenceAppartenance    += [PersonnageCompetence];
              end;
            Node := Node.NextSibling;
          end;
      end;

    // Avance gratuite de creation V2 : balise absente des fiches anterieures, tableau vide.
    SubChapterNode := PlayerNode.FindNode(ConstXmlSousChapitreAvanceGratuite);
    if Assigned(SubChapterNode) then
      begin
        Node := SubChapterNode.FirstChild;
        while Assigned(Node) do
          begin
            if Node.NodeName = ConstXmlCarac then
              begin
                PersonnageAttribut.CodeAttribut  := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                PersonnageAttribut.Valeur        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                Personnage.AvanceGratuiteAttribut += [PersonnageAttribut];
              end;
            Node := Node.NextSibling;
          end;
      end;

    if Assigned(PlayerNode.FindNode(ConstXmlAge)) then
      Personnage.Age                := StrToInt(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAge).TextContent)));
    Personnage.PointsMagie        := 0;
    if Assigned(PlayerNode.FindNode(ConstXmlMagicPoints)) then
      Personnage.PointsMagie      := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlMagicPoints).TextContent)), 0);
    Personnage.AlignementV1       := '';
    if Assigned(PlayerNode.FindNode(ConstXmlAlignmentPerso)) then
      Personnage.AlignementV1     := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAlignmentPerso).TextContent));
    Personnage.FolieV1            := 0;
    if Assigned(PlayerNode.FindNode(ConstXmlInsanityPoints)) then
      Personnage.FolieV1          := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlInsanityPoints).TextContent)), 0);
    Personnage.NaissanceV1        := '';
    if Assigned(PlayerNode.FindNode(ConstXmlBirthPlaceV1)) then
      Personnage.NaissanceV1      := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlBirthPlaceV1).TextContent));
    Personnage.ParentsV1          := '';
    if Assigned(PlayerNode.FindNode(ConstXmlParentsJobV1)) then
      Personnage.ParentsV1        := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlParentsJobV1).TextContent));
    Personnage.FamilleV1          := '';
    if Assigned(PlayerNode.FindNode(ConstXmlFamilyMembersV1)) then
      Personnage.FamilleV1        := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlFamilyMembersV1).TextContent));
    Personnage.HandicapsV1        := '';
    if Assigned(PlayerNode.FindNode(ConstXmlDisabilitiesV1)) then
      Personnage.HandicapsV1      := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlDisabilitiesV1).TextContent));
    Personnage.FamilierV1         := '';
    if Assigned(PlayerNode.FindNode(ConstXmlFamiliarV1)) then
      Personnage.FamilierV1       := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlFamiliarV1).TextContent));
    Personnage.SortsV1            := '';
    if Assigned(PlayerNode.FindNode(ConstXmlSpellsLearnedV1)) then
      Personnage.SortsV1          := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlSpellsLearnedV1).TextContent));
    Personnage.EchecsSortsV1      := '';
    if Assigned(PlayerNode.FindNode(ConstXmlSpellFailuresV1)) then
      Personnage.EchecsSortsV1    := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlSpellFailuresV1).TextContent));
    Personnage.MagicienMauvaisV1  := Assigned(PlayerNode.FindNode(ConstXmlEvilWizardV1));
    Personnage.ClasseV1           := '';
    if Assigned(PlayerNode.FindNode(ConstXmlClasseV1)) then
      Personnage.ClasseV1         := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlClasseV1).TextContent));
    Personnage.CulteV1            := '';
    if Assigned(PlayerNode.FindNode(ConstXmlCulteV1)) then
      Personnage.CulteV1          := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlCulteV1).TextContent));
    // Fiche sans <HeightUnit> : taille enregistree en pouces (avant l'unite par fiche)
    Personnage.HeightUnit         := ConstUniteInch;
    if Assigned(PlayerNode.FindNode(ConstXmlHeight)) then
      Personnage.Height             := StrToInt(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlHeight).TextContent)));
    if Assigned(PlayerNode.FindNode(ConstXmlHeightUnit)) then
      Personnage.HeightUnit         := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlHeightUnit).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlHairColors)) then
      Personnage.HairColors         := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlHairColors).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlEyeColors)) then
      Personnage.EyeColors          := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlEyeColors).TextContent));
    // Sous-bloc V2 facultatif
    Personnage.SexeV2               := '';
    Personnage.PoidsV2              := 0;
    Personnage.FratrieV2            := '';
    Personnage.SigneDistinctifV2    := '';
    Personnage.NaissanceV2          := '';
    Personnage.AstreV2              := '';
    if Assigned(PlayerNode.FindNode(ConstXmlFicheV2)) then
      with PlayerNode.FindNode(ConstXmlFicheV2) do
        begin
          if Assigned(FindNode(ConstXmlFicheSexe)) then
            Personnage.SexeV2           := RemoveQuotes(UTF8Encode(FindNode(ConstXmlFicheSexe).TextContent));
          if Assigned(FindNode(ConstXmlFichePoids)) then
            Personnage.PoidsV2          := StrToIntDef(RemoveQuotes(UTF8Encode(FindNode(ConstXmlFichePoids).TextContent)), 0);
          if Assigned(FindNode(ConstXmlFicheFratrie)) then
            Personnage.FratrieV2        := RemoveQuotes(UTF8Encode(FindNode(ConstXmlFicheFratrie).TextContent));
          if Assigned(FindNode(ConstXmlFicheSigneDistinctif)) then
            Personnage.SigneDistinctifV2 := RemoveQuotes(UTF8Encode(FindNode(ConstXmlFicheSigneDistinctif).TextContent));
          if Assigned(FindNode(ConstXmlFicheNaissance)) then
            Personnage.NaissanceV2      := RemoveQuotes(UTF8Encode(FindNode(ConstXmlFicheNaissance).TextContent));
          if Assigned(FindNode(ConstXmlFicheAstreV2)) then
            Personnage.AstreV2          := RemoveQuotes(UTF8Encode(FindNode(ConstXmlFicheAstreV2).TextContent));
        end;
    if Assigned(PlayerNode.FindNode(ConstXmlAmbitionCourt)) then
      Personnage.AmbitionCourt      := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAmbitionCourt).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlAmbitionLong)) then
      Personnage.AmbitionLong       := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAmbitionLong).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlAmbitionGroupeCourt)) then
      Personnage.AmbitionGroupeCourt := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAmbitionGroupeCourt).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlAmbitionGroupeLong)) then
      Personnage.AmbitionGroupeLong  := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlAmbitionGroupeLong).TextContent));
    // Fiche sans groupe : personnage solo
    Personnage.GroupeId             := '';
    if Assigned(PlayerNode.FindNode(ConstXmlGroupeId)) then
      Personnage.GroupeId           := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlGroupeId).TextContent));
    // Fiche sans monnaie : 0
    Personnage.MonnaieCO            := 0;
    Personnage.MonnaiePA            := 0;
    Personnage.MonnaieSB            := 0;
    if Assigned(PlayerNode.FindNode(ConstXmlMonnaieCO)) then
      Personnage.MonnaieCO          := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlMonnaieCO).TextContent)), 0);
    if Assigned(PlayerNode.FindNode(ConstXmlMonnaiePA)) then
      Personnage.MonnaiePA          := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlMonnaiePA).TextContent)), 0);
    if Assigned(PlayerNode.FindNode(ConstXmlMonnaieSB)) then
      Personnage.MonnaieSB          := StrToIntDef(RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlMonnaieSB).TextContent)), 0);
    // Fiche sans signe astral : aucun
    Personnage.SigneAstral          := '';
    Personnage.SigneAstralVariante  := '';
    Personnage.SigneAstralTalent    := '';
    if Assigned(PlayerNode.FindNode(ConstXmlSigneAstral)) then
      Personnage.SigneAstral        := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlSigneAstral).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlSigneVariantePerso)) then
      Personnage.SigneAstralVariante := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlSigneVariantePerso).TextContent));
    if Assigned(PlayerNode.FindNode(ConstXmlSigneTalentPerso)) then
      Personnage.SigneAstralTalent := RemoveQuotes(UTF8Encode(PlayerNode.FindNode(ConstXmlSigneTalentPerso).TextContent));
    Personnage.Asterisque           := 0;
  end;

  procedure LitCreation;
  begin
    ChapterRaceNode := PlayerNode.FindNode(ConstXmlChapitreCreation);
    if Assigned(ChapterRaceNode) then
      begin
        // Lire les caractéristiques de la sous-section CARAC
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCarac);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlCarac then
                  begin
                    PersonnageAttribut.CodeAttribut  := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageAttribut.Valeur        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.CreationAttribut      += [PersonnageAttribut];
                  end;
                Node := Node.NextSibling;
              end;
          end;

        // Lire les compétences de la sous-section COMP
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCompSpecie);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlCompetence then
                  begin
                    PersonnageCompetence.CodeCompetence:= RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageCompetence.Valeur        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.CreationCompetence35    += [PersonnageCompetence];
                  end;
                Node := Node.NextSibling;
              end;
          end;

        // Lire les autres compétences de la sous-section COMP
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCompCreation);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlCompetence then
                  begin
                    PersonnageCompetence.CodeCompetence:= RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageCompetence.Valeur        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.CreationCompetence40    += [PersonnageCompetence];
                  end;
                Node := Node.NextSibling;
              end;
          end;

        // Lire les talents de la sous-section TALENT
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreTalent);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlTalent then
                  begin
                    PersonnageTalent.CodeTalent     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageTalent.Valeur         := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    PersonnageTalent.Asterisque     := 0;
                    Personnage.CreationTalent       += [PersonnageTalent];
                  end;
                  Node := Node.NextSibling;
                end;
            end;
        end;

    ChapterRaceNode := PlayerNode.FindNode(ConstXmlChapitreAugmentation);
    if Assigned(ChapterRaceNode) then
    begin
      // Lire les caractéristiques de la sous-section CARAC
      SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCarac);
      if Assigned(SubChapterNode) then
        begin
          Node := SubChapterNode.FirstChild;
          while Assigned(Node) do
            begin
              if Node.NodeName = ConstXmlCarac then
                begin
                  PersonnageAttribut.CodeAttribut  := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                  PersonnageAttribut.Valeur        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  Personnage.AugmentationAttribut  += [PersonnageAttribut];
                end;
              Node := Node.NextSibling;
            end;
        end;

      // Lire les compétences de la sous-section COMP
      SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCompMetier);
      if Assigned(SubChapterNode) then
        begin
          Node := SubChapterNode.FirstChild;
          while Assigned(Node) do
            begin
              if Node.NodeName = ConstXmlCompetence then
                begin
                  PersonnageCompetence.CodeCompetence:= RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                  PersonnageCompetence.Valeur        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  Personnage.AugmentationCompetence  += [PersonnageCompetence];
                end;
              Node := Node.NextSibling;
            end;
        end;


      // Lire les talents de la sous-section TALENT
      SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreTalent);
      if Assigned(SubChapterNode) then
        begin
          Node := SubChapterNode.FirstChild;
          while Assigned(Node) do
            begin
              if Node.NodeName = ConstXmlTalent then
                begin
                  PersonnageTalent.CodeTalent     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                  PersonnageTalent.Valeur         := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  PersonnageTalent.Asterisque     := 0;
                  Personnage.AugmentationTalent   += [PersonnageTalent];
                end;
                Node := Node.NextSibling;
              end;
          end;
      end;
  end;

  procedure LitCarriere;
  begin
    // carrière
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreOldWork);
      if Assigned(ChapterItemNode) then
        begin
          ItemNode := ChapterItemNode.FirstChild;
          while Assigned(ITemNode) do
            begin
              if (ItemNode.NodeType = ELEMENT_NODE) then
                begin
                  Code := RemoveQuotes(UTF8Encode(ITemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                  PersonnageMetier.CodeMetier   := ExtractStringBefore(Code,SeparateurMulti);
                  PersonnageMetier.NiveauMetier := StrToIntDef(ExtractStringAfter(Code,SeparateurMulti),0);
                  PersonnageMetier.CoutXp       := StrToIntDef(RemoveQuotes(UTF8Encode(ITemNode.TextContent)),0);
                  Personnage.MetierAncien       += [PersonnageMetier];
                end;
              ItemNode := ItemNode.NextSibling;
            end;
        end;
  end;

  procedure LitEquipement;
  begin
    // Equipement
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreEquipement);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        if Assigned(ITemNode) then
          begin
            // Lire armes
            SubChapterNode := ChapterItemNode.FindNode(ConstXmlSousChapitreArme);
            if Assigned(SubChapterNode) then
              begin
                Node := SubChapterNode.FirstChild;
                while Assigned(Node) do
                  begin
                    if (Node.NodeType = ELEMENT_NODE) then
                      begin
                        PersonnageEquipement.CodeEquipement     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                        PersonnageEquipement.TypeEquipement     := TrimRight(TypeEquipWe);
                        PersonnageEquipement.QualiteEquipement  := RemoveQuotes(UTF8Encode(Node.TextContent));
                        PersonnageEquipement.Porte              := Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementPorte));
                        LitEquipementInstance(Node, PersonnageEquipement);
                        if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                          PersonnageEquipement.Quantite         := StrToIntDef(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite).NodeValue), 1)
                        else
                          PersonnageEquipement.Quantite         := 1;
                        Personnage.Equipement                   += [PersonnageEquipement];
                      end;
                    Node  := Node.NextSibling;
                  end;
              end;

            // Lire armures
            SubChapterNode := ChapterItemNode.FindNode(ConstXmlSousChapitreArmure);
            if Assigned(SubChapterNode) then
              begin
                Node := SubChapterNode.FirstChild;
                while Assigned(Node) do
                  begin
                    if (Node.NodeType = ELEMENT_NODE) then
                      begin
                        PersonnageEquipement.CodeEquipement     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                        PersonnageEquipement.TypeEquipement     := TrimRight(TypeEquipAr);
                        PersonnageEquipement.QualiteEquipement  := RemoveQuotes(UTF8Encode(Node.TextContent));
                        PersonnageEquipement.Porte              := Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementPorte));
                        LitEquipementInstance(Node, PersonnageEquipement);
                        if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                          PersonnageEquipement.Quantite         := StrToIntDef(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite).NodeValue), 1)
                        else
                          PersonnageEquipement.Quantite         := 1;
                        Personnage.Equipement                   += [PersonnageEquipement];
                      end;
                    Node  := Node.NextSibling;
                  end;
              end;

            // Lire set d'armures
            SubChapterNode := ChapterItemNode.FindNode(ConstXmlSousChapitreArmureSimp);
            if Assigned(SubChapterNode) then
              begin
                Node := SubChapterNode.FirstChild;
                while Assigned(Node) do
                  begin
                    if (Node.NodeType = ELEMENT_NODE) then
                      begin
                        PersonnageEquipement.CodeEquipement     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                        PersonnageEquipement.TypeEquipement     := TrimRight(TypeEquipArS);
                        PersonnageEquipement.QualiteEquipement  := RemoveQuotes(UTF8Encode(Node.TextContent));
                        PersonnageEquipement.Porte              := Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementPorte));
                        LitEquipementInstance(Node, PersonnageEquipement);
                        if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                          PersonnageEquipement.Quantite         := StrToIntDef(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite).NodeValue), 1)
                        else
                          PersonnageEquipement.Quantite         := 1;
                        Personnage.Equipement                   += [PersonnageEquipement];
                      end;
                    Node  := Node.NextSibling;
                  end;
              end;

            // Lire les autres équipements
            SubChapterNode := ChapterItemNode.FindNode(ConstXmlSousChapitreDivers);
            if Assigned(SubChapterNode) then
              begin
                Node := SubChapterNode.FirstChild;
                while Assigned(Node) do
                  begin
                    if (Node.NodeType = ELEMENT_NODE) then
                      begin
                        PersonnageEquipement.CodeEquipement     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                        // Un animal est range dans Divers a la sauvegarde : retrouve par son profil.
                        if TrappingEstAnimal(ChercheTrapping(PersonnageEquipement.CodeEquipement)) then
                          PersonnageEquipement.TypeEquipement   := TrimRight(TypeEquipAN)
                        else
                          PersonnageEquipement.TypeEquipement   := TrimRight(TypeEquipDi);
                        PersonnageEquipement.QualiteEquipement  := RemoveQuotes(UTF8Encode(Node.TextContent));
                        PersonnageEquipement.Porte              := Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementPorte));
                        LitEquipementInstance(Node, PersonnageEquipement);
                        // Fiche anterieure au rattachement : l'animal recoit son identifiant ici.
                        if ((PersonnageEquipement.TypeEquipement = TrimRight(TypeEquipAN)) or TrappingEstPorteur(ChercheTrapping(PersonnageEquipement.CodeEquipement))) and (PersonnageEquipement.IdInstance = '') then
                          PersonnageEquipement.IdInstance := IdAnimalLibre(Personnage.Equipement);
                        if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                          PersonnageEquipement.Quantite         := StrToIntDef(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite).NodeValue), 1)
                        else
                          PersonnageEquipement.Quantite         := 1;
                        Personnage.Equipement                   += [PersonnageEquipement];
                      end;
                    Node  := Node.NextSibling;
                  end;
              end;

          // Lire les sorts
          SubChapterNode := ChapterItemNode.FindNode(ConstXmlSousChapitreSort);
          if Assigned(SubChapterNode) then
            begin
              Node := SubChapterNode.FirstChild;
              while Assigned(Node) do
                begin
                  if (Node.NodeType = ELEMENT_NODE) then
                    begin
                      PersonnageEquipement.CodeEquipement     := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                      PersonnageEquipement.TypeEquipement     := TrimRight(TypeEquipSp);
                      PersonnageEquipement.CoutXp             := StrToIntdef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                      PersonnageEquipement.Porte              := False;
                      PersonnageEquipement.IdInstance := '';
                      PersonnageEquipement.PortePar   := '';
                      Personnage.Equipement                   += [PersonnageEquipement];
                    end;
                  Node := Node.NextSibling;
                end;
            end;
        end;
      end;
  end;

  procedure LitSuivi;
  begin
    // Historique de corruption
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreCorruption);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnageCorruption.Montant := StrToIntDef(RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue)),0);
                PersonnageCorruption.Libelle := RemoveQuotes(UTF8Encode(ItemNode.TextContent));
                Personnage.Corruption        += [PersonnageCorruption];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;

    // Registres de Destin, de Resilience et de Resolution
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreDestin);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnageCorruption.Montant := StrToIntDef(RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue)),0);
                PersonnageCorruption.Libelle := RemoveQuotes(UTF8Encode(ItemNode.TextContent));
                Personnage.Destin += [PersonnageCorruption];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreResilience);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnageCorruption.Montant := StrToIntDef(RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue)),0);
                PersonnageCorruption.Libelle := RemoveQuotes(UTF8Encode(ItemNode.TextContent));
                Personnage.Resilience += [PersonnageCorruption];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreResolve);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnageCorruption.Montant := StrToIntDef(RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue)),0);
                PersonnageCorruption.Libelle := RemoveQuotes(UTF8Encode(ItemNode.TextContent));
                Personnage.Resolve += [PersonnageCorruption];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;

    // Mutations obtenues (CONTEXT.md §2.7) - référence (Code stable du catalogue), pas le texte
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreMutation);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnageMutation.Code            := RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                PersonnageMutation.ValeurAleatoire := 0;
                if Assigned(ItemNode.Attributes.GetNamedItem('valeurAleatoire')) then
                  PersonnageMutation.ValeurAleatoire := StrToIntDef(UTF8Encode(ItemNode.Attributes.GetNamedItem('valeurAleatoire').NodeValue), 0);
                PersonnageMutation.ValeursEffets := '';
                if Assigned(ItemNode.Attributes.GetNamedItem('valeursEffets')) then
                  PersonnageMutation.ValeursEffets := UTF8Encode(ItemNode.Attributes.GetNamedItem('valeursEffets').NodeValue);
                Personnage.Mutations    += [PersonnageMutation];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;

    // Afflictions possedees (Unofficial Grimoire) - reference (Code stable du catalogue).
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreAffliction);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnagePathologie.TypeChapitre    := ConstXmlChapitreAffliction;
                PersonnagePathologie.Code            := RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                // Champ absent (vieux fichier, ou aucun jet aleatoire pour cette entree) = 0 -
                // sans ce := 0 explicite, PersonnagePathologie (variable locale reutilisee a
                // chaque tour de boucle) contient la valeur du tour precedent, ou une valeur
                // memoire non initialisee au premier tour (bug signale par Nono le 27/09/2026).
                PersonnagePathologie.ValeurAleatoire := 0;
                if Assigned(ItemNode.Attributes.GetNamedItem('valeurAleatoire')) then
                  PersonnagePathologie.ValeurAleatoire := StrToIntDef(UTF8Encode(ItemNode.Attributes.GetNamedItem('valeurAleatoire').NodeValue), 0);
                Personnage.Pathologies             += [PersonnagePathologie];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;

    // Maladies possedees (Litany of Pestilence) - meme principe qu'Affliction ci-dessus.
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreDisease);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnagePathologie.TypeChapitre    := ConstXmlChapitreDisease;
                PersonnagePathologie.Code            := RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                // Aucune Disease ne porte de <ModifyCaracAleatoire> pour l'instant, mais meme
                // reinitialisation explicite que cote Affliction ci-dessus par prudence (voir
                // le commentaire correspondant).
                PersonnagePathologie.ValeurAleatoire := 0;
                Personnage.Pathologies             += [PersonnagePathologie];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;

    // Talents dont les effets sont lies a une carriere+niveau precis (CONTEXT.md 2.78,
    // Virtue of the Quest) - voir StructurePersonnageTalentCarriereRequise.
    ChapterItemNode := PlayerNode.FindNode(ConstXmlChapitreTalentCarriere);
    if Assigned(ChapterItemNode) then
      begin
        ItemNode := ChapterItemNode.FirstChild;
        while Assigned(ItemNode) do
          begin
            if (ItemNode.NodeType = ELEMENT_NODE) then
              begin
                PersonnageTalentCarriere.CodeTalent   := RemoveQuotes(UTF8Encode(ItemNode.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                Code                                   := RemoveQuotes(UTF8Encode(ItemNode.TextContent));
                PersonnageTalentCarriere.CodeMetier   := ExtractStringBefore(Code, SeparateurMulti);
                PersonnageTalentCarriere.NiveauMetier := StrToIntDef(ExtractStringAfter(Code, SeparateurMulti),0);
                Personnage.TalentCarriereRequise      += [PersonnageTalentCarriere];
              end;
            ItemNode := ItemNode.NextSibling;
          end;
      end;
  end;

  procedure LitExperience;
  begin
    ChapterRaceNode := PlayerNode.FindNode(ConstXmlChapitreCompetence);
    if Assigned(ChapterRaceNode) then
      begin
        // Lire les caractéristiques de la sous-section CARAC
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCompMetier);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if (Node.NodeType = ELEMENT_NODE) then
                  begin
                    PersonnageCompetence.CodeCompetence := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageCompetence.Valeur         := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.MetierCompetence         += [PersonnageCompetence];
                  end;
                Node := Node.NextSibling;
              end;
          end;
      end;

    ChapterRaceNode := PlayerNode.FindNode(ConstXmlChapitreTalent);
    if Assigned(ChapterRaceNode) then
      begin
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreTalMetier);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if (Node.NodeType = ELEMENT_NODE) then
                  begin
                    PersonnageTalent.CodeTalent := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageTalent.Valeur     := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    PersonnageTalent.Asterisque := 0;
                    Personnage.MetierTalent     += [PersonnageTalent];
                  end;
                Node := Node.NextSibling;
              end;
          end;
      end;

    // Cout d'XP hors normes
    ChapterRaceNode := PlayerNode.FindNode(ConstXmlChapitreCoutXp);
    if Assigned(ChapterRaceNode) then
      begin
        // Cout pour les attributs
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCarac);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlCarac then
                  begin
                    Code := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageXpAttribut.CodeAttribut  := ExtractStringBefore(Code,DriveSeparator);
                    PersonnageXpAttribut.Debut         := StrToIntDef(ExtractStringBefore(ExtractStringAfter(Code,DriveSeparator),SeparateurChance),0);
                    PersonnageXpAttribut.Fin           := StrToIntDef(ExtractStringAfter(ExtractStringAfter(Code,DriveSeparator),SeparateurChance),0);
                    PersonnageXpAttribut.CoutXp        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.XpCoutAttribut          += [PersonnageXpAttribut];
                  end;
                Node := Node.NextSibling;
              end;
          end;

        // Cout pour les Competences
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreCompetence);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlCompetence then
                  begin
                    Code := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageXpCompetence.CodeCompetence  := ExtractStringBefore(Code,DriveSeparator);
                    PersonnageXpCompetence.Debut           := StrToIntDef(ExtractStringBefore(ExtractStringAfter(Code,DriveSeparator),SeparateurChance),0);
                    PersonnageXpCompetence.Fin             := StrToIntDef(ExtractStringAfter(ExtractStringAfter(Code,DriveSeparator),SeparateurChance),0);
                    PersonnageXpCompetence.CoutXp          := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.XpCoutCompetence            += [PersonnageXpCompetence];
                  end;
                Node := Node.NextSibling;
              end;
          end;

        // Cout pour les Talents
        SubChapterNode := ChapterRaceNode.FindNode(ConstXmlSousChapitreTalent);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if Node.NodeName = ConstXmlTalent then
                  begin
                    Code := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    PersonnageXpTalent.CodeTalent  := ExtractStringBefore(Code,DriveSeparator);
                    PersonnageXpTalent.Debut       := StrToIntDef(ExtractStringBefore(ExtractStringAfter(Code,DriveSeparator),SeparateurChance),0);
                    PersonnageXpTalent.Fin         := StrToIntDef(ExtractStringAfter(ExtractStringAfter(Code,DriveSeparator),SeparateurChance),0);
                    PersonnageXpTalent.CoutXp      := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                    Personnage.XpCoutTalent        += [PersonnageXpTalent];
                  end;
                Node := Node.NextSibling;
              end;
          end;
      end;
  end;

  procedure LitAsterisques;
  var
    IndiceTalent: Integer;  // compteur de boucle : doit etre local a la procedure
  begin
    // Lire Les talents de création
    for IndiceTalent := 0 to high(Personnage.CreationTalent) Do
      if Personnage.CreationTalent[indiceTalent].Asterisque = 0  then
        begin
          Asterisque := PersonnageTalentAsterisque(Personnage, Personnage.CreationTalent[indiceTalent].CodeTalent);
          if Asterisque <> 0 then
            begin
              Personnage.Asterisque := Asterisque;
              Personnage.CreationTalent[indiceTalent].Asterisque := Asterisque;
            end;
        end;

    // Lire Les talents ajoutés
    for IndiceTalent := 0 to high(Personnage.AugmentationTalent) Do
      if Personnage.AugmentationTalent[indiceTalent].Asterisque = 0  then
        begin
          Asterisque := PersonnageTalentAsterisque(Personnage, Personnage.AugmentationTalent[indiceTalent].CodeTalent);
          if Asterisque <> 0 then
            Personnage.Asterisque := Asterisque;
          Personnage.AugmentationTalent[indiceTalent].Asterisque := Asterisque;
        end;
  end;

begin
  XMLDoc := TXMLDocument.Create;
  try
    ReadXMLFile(XMLDoc, FileName);

    PlayerNode := XMLDoc.DocumentElement;
    if Assigned(PlayerNode) and (PlayerNode.NodeName = ConstXmlPersonnage) then
    begin
      LitIdentite;
      LitCreation;
      LitCarriere;
      LitEquipement;
      LitSuivi;
      LitExperience;
      LitAsterisques;

    end;
  finally
    // Les noeuds appartiennent au document : seul XMLDoc se libere
    XMLDoc.Free;
  end;

  result := Personnage;
end;

// Ecrit dans la fiche les competences et talents greffes par les APPARTENANCES du
// personnage (regiments de l'Empire, ordres de chevalerie, cultes). CONTEXT.md 2.44.
//
// POURQUOI ON ECRIT AU LIEU DE CALCULER A L'AFFICHAGE (decision Nono, 04/09/2026) :
// le livre traite ces elements "as if added to their Career". Or dans le projet, etre
// une competence de carriere ne se joue pas dans la grille mais dans
// Personnage.MetierCompetence, qui alimente CalculTableExperience - donc les tables
// d'avance, le cout XP et le PDF. En les ecrivant ici, tout le reste marche sans qu'aucun
// ecran n'ait a connaitre les appartenances. C'est aussi ce qui satisfait naturellement la
// regle de persistance du livre : "If you leave your Regiment ... you maintain all
// additional Skills and Talents."
//
// La Valeur portee est le NUMERO DU PALIER, exactement comme les competences de metier
// ecrites en une fois pour les quatre niveaux a l'entree dans une carriere : c'est
// CalculTableExperience qui filtre ensuite sur Valeur <= niveau courant.
//
// Un element portant SeparateurMulti ('A/B') est greffe TEL QUEL, code de choix compris :
// les deux tableaux d'augmentation savent le resoudre. ListeMetierCompetence et
// ListeTalent aplatissent les branches du '/', la colonne "Spe" s'affiche des que la liste
// rendue compte plus d'une entree, WinSpecialisation propose les branches, et le
// double-clic reecrit le code retenu dans MetierCompetence / MetierTalent. Verifie le
// 04/09/2026 des deux cotes. Ce n'est donc pas a cette procedure de trancher le choix.
Procedure PersonnageAppliqueGreffes(var Personnage: StructurePersonnage);
var
  GreffeCompetence:     String;
  GreffeTalent:         String;
  Liste:                TStringList;
  Ind:                  Integer;
  Code:                 String;
  Trouve:               Boolean;
  PNiveau:              Integer;
  PersonnageCompetence: StructurePersonnageCompetence;
  PersonnageTalent:     StructurePersonnageTalent;
  Appartenances:        TStringList;
  IndApp:               Integer;
  Paliers:              TListCareerBonusNiveau;
  Palier:               StructureCareerBonusNiveau;
begin
  if Trim(Personnage.Appartenance) = '' then
    Exit;

  Appartenances := TStringList.Create;
  try
    ExtractStrings([','], [], PChar(Personnage.Appartenance), Appartenances);
    for IndApp := 0 to Appartenances.Count - 1 do
      begin
        if Trim(Appartenances[IndApp]) = '' then
          continue;
        // NiveauxDuCareerBonus rend une liste dont l'APPELANT est proprietaire.
        Paliers := NiveauxDuCareerBonus(Trim(Appartenances[IndApp]));
        try
          for Palier in Paliers do
            begin
              if Palier.Niveau <= 0 then
                continue;
              PNiveau          := Palier.Niveau;
              GreffeCompetence := Palier.ListeCompetence;
              GreffeTalent     := Palier.ListeTalent;

              // Competences du palier
              if Trim(GreffeCompetence) <> '' then
                begin
                  Liste := TStringList.Create;
                  try
                    ExtractStrings([','], [], PChar(GreffeCompetence), Liste);
                    for Ind := 0 to Liste.Count - 1 do
                      begin
                        Code := Trim(Liste[Ind]);
                        if Code = '' then
                          continue;
                        Trouve := false;
                        for PersonnageCompetence in Personnage.MetierCompetence do
                          if CompareRechercheValeur(PersonnageCompetence.CodeCompetence, Code) then
                            begin
                              Trouve := true;
                              break;
                            end;
                        if not Trouve then
                          begin
                            PersonnageCompetence                := Default(StructurePersonnageCompetence);
                            PersonnageCompetence.CodeCompetence := Code;
                            PersonnageCompetence.Valeur         := PNiveau;
                            Personnage.MetierCompetence         += [PersonnageCompetence];
                          end;
                      end;
                  finally
                    Liste.Free;
                  end;
                end;

              // Talents du palier
              if Trim(GreffeTalent) <> '' then
                begin
                  Liste := TStringList.Create;
                  try
                    ExtractStrings([','], [], PChar(GreffeTalent), Liste);
                    for Ind := 0 to Liste.Count - 1 do
                      begin
                        Code := Trim(Liste[Ind]);
                        if Code = '' then
                          continue;
                        Trouve := false;
                        for PersonnageTalent in Personnage.MetierTalent do
                          if CompareRechercheValeur(PersonnageTalent.CodeTalent, Code) then
                            begin
                              Trouve := true;
                              break;
                            end;
                        if not Trouve then
                          begin
                            PersonnageTalent            := Default(StructurePersonnageTalent);
                            PersonnageTalent.CodeTalent := Code;
                            PersonnageTalent.Valeur     := PNiveau;
                            Personnage.MetierTalent     += [PersonnageTalent];
                          end;
                      end;
                  finally
                    Liste.Free;
                  end;
                end;
            end;
        finally
          Paliers.Free;
        end;
      end;
  finally
    Appartenances.Free;
  end;
end;

// Effet AddSkillToCareer d'un talent possede (Perfect Pitch -> Chant) : la competence (Cible) entre dans les
// competences de METIER du personnage, au palier donne par Facteur, comme une greffe d'appartenance - donc
// achetable au tarif de carriere (il n'y a plus de grille separee des competences
// ajoutees par un talent). Idempotent : appelee a chaque calcul, elle suit un talent acquis plus tard et survit au changement
// de carriere (MetierCompetence repart de zero a l'entree). Le rabais de 5 XP du livre n'est pas traite (A FAIRE.txt).
Procedure PersonnageAppliqueTalentsCompetences(var Personnage: StructurePersonnage);
  function Possede(const CodeTalent: String): Boolean;
  var
    PT: StructurePersonnageTalent;
  begin
    Result := False;
    for PT in Personnage.CreationTalent do
      if (PT.Valeur > 0) and MemeTalent(PT.CodeTalent, CodeTalent) then Exit(True);
    for PT in Personnage.AugmentationTalent do
      if (PT.Valeur > 0) and MemeTalent(PT.CodeTalent, CodeTalent) then Exit(True);
  end;
var
  Modif:  StructureModificateur;
  PC:     StructurePersonnageCompetence;
  Trouve: Boolean;
begin
  for Modif in ListModificateur do
    begin
      if (Modif.TypeSource <> SourceModifTalent) or (Modif.TypeModif <> ConstXmlModifieCompetenceCarriere) then
        continue;
      if (Modif.Cible = '') or not Possede(Modif.CodeSource) then
        continue;
      Trouve := False;
      for PC in Personnage.MetierCompetence do
        if CompareRechercheValeur(PC.CodeCompetence, Modif.Cible) then
          begin
            Trouve := True;
            break;
          end;
      if Trouve then
        continue;
      PC                := Default(StructurePersonnageCompetence);
      PC.CodeCompetence := Modif.Cible;
      PC.Valeur         := Modif.Facteur;
      Personnage.MetierCompetence += [PC];
    end;
end;

Procedure PersonnageTalentsMomentum(var Personnage: StructurePersonnage; Momentum: Boolean);
var
  Ind: Integer;
begin
  for Ind := 0 to High(Personnage.CreationTalent) do
    Personnage.CreationTalent[Ind].CodeTalent := CodeTalentVersion(Personnage.CreationTalent[Ind].CodeTalent, Momentum);
  for Ind := 0 to High(Personnage.AugmentationTalent) do
    Personnage.AugmentationTalent[Ind].CodeTalent := CodeTalentVersion(Personnage.AugmentationTalent[Ind].CodeTalent, Momentum);
  for Ind := 0 to High(Personnage.MetierTalent) do
    Personnage.MetierTalent[Ind].CodeTalent := CodeTalentVersion(Personnage.MetierTalent[Ind].CodeTalent, Momentum);
  for Ind := 0 to High(Personnage.XpCoutTalent) do
    Personnage.XpCoutTalent[Ind].CodeTalent := CodeTalentVersion(Personnage.XpCoutTalent[Ind].CodeTalent, Momentum);
  for Ind := 0 to High(Personnage.TalentCarriereRequise) do
    Personnage.TalentCarriereRequise[Ind].CodeTalent := CodeTalentVersion(Personnage.TalentCarriereRequise[Ind].CodeTalent, Momentum);
end;

Function PersonnageTalentAsterisque(var Personnage:StructurePersonnage; CodeTalent: String): Integer;
var
  Trouve:                 Boolean = False;
  Asterisque:             Integer = 0;
  indiceAttribut:         Integer = 0;
  indiceTalent:           Integer = 0;
  indiceCompetence:       Integer = 0;
begin
  // En Free Pascal, une variable locale initialisee (= valeur) est une constante typee :
  // elle n'est initialisee qu'une fois au demarrage du programme, pas a chaque appel.
  // Sans cette remise a zero explicite, un talent qui ne matche rien heritait de la
  // derniere asterisque laissee par l'appel precedent (Strike Mighty Blow/Strike to
  // Stun/Very Resilient/Knight of the Order of the Hammer partageant tous "(4)" a tort,
  // signale par Nono le 11/09/2026). Meme famille de piege que ChercheCompetence, §2.17.
  Asterisque := 0;
  // traiter les talents qui augmentent les attributs. ListTalentAttributModif -> filtre sur
  // ListTalentModificateur (TypeModif = ConstXmlModifieAttribut) depuis le 11/09/2026,
  // migration ModifyCarac sur le moteur generique - meme donnee, CodeSource remplace
  // CodeTalent et Cible/Facteur remplacent CodeAttribut/Valeur.
  For indiceTalent := 0 to (ListModificateur.count - 1) Do
    if (ListModificateur[indiceTalent].TypeSource = SourceModifTalent)
       and (ListModificateur[indiceTalent].TypeModif = ConstXmlModifieAttribut)
       and CompareRechercheValeur(ListModificateur[indiceTalent].CodeSource, CodeTalent) then
      begin
        Trouve := False;
        for indiceAttribut := 0 to High(Personnage.CreationAttribut) do
          if CompareRechercheValeur(ListModificateur[indiceTalent].Cible, Personnage.CreationAttribut[indiceAttribut].CodeAttribut) then
            begin
              Asterisque := Personnage.Asterisque + 1;
              Trouve     := true;
              break;
            end;
        if Trouve = True then
          begin
            if Personnage.CreationAttribut[indiceAttribut].Bonus <> '' then
              Personnage.CreationAttribut[indiceAttribut].Bonus += '-' ;
            // ValeurDonnee (texte brut) -> Valeur (Integer) le 06/09/2026 : le signe n'est
            // plus recopie tel quel depuis le XML, on le reconstruit - meme convention que
            // PdfPersonnageCreation l.2326 pour Personnage.Corruption[].Montant.
            if ListModificateur[indiceTalent].Facteur > 0 then
              Personnage.CreationAttribut[indiceAttribut].Bonus += '+' + IntToStr(ListModificateur[indiceTalent].Facteur)+' (' + IntToStr(Asterisque) + ')'
            else
              Personnage.CreationAttribut[indiceAttribut].Bonus += IntToStr(ListModificateur[indiceTalent].Facteur)+' (' + IntToStr(Asterisque) + ')';
          end;
      end;

  // traiter les talents qui impactent les compétences créées.
  for indiceTalent := 0 to (ListTalentCompetenceModif.count - 1) Do
    begin
      if CompareRechercheValeur(ListTalentCompetenceModif[indiceTalent].CodeTalent, CodeTalent) then
        begin
          // gérer les compétences 35
          For indiceCompetence := 0 to High(Personnage.CreationCompetence35) do
            if CompareRechercheValeur(ListTalentCompetenceModif[indiceTalent].CodeCompetence, Personnage.CreationCompetence35[indiceCompetence].CodeCompetence) then
              begin
                if Asterisque = 0 then
                  Asterisque := Personnage.Asterisque + 1;
                if CountOccurrences(Personnage.CreationCompetence35[indiceCompetence].Bonus, '(' + IntToStr(Asterisque) + ')') = 0 then
                  begin
                    if Personnage.CreationCompetence35[indiceCompetence].Bonus <> '' then
                      Personnage.CreationCompetence35[indiceCompetence].Bonus += '-';
                    case ListTalentCompetenceModif[indiceTalent].TypeModif of
                      ConstCompetenceInverseDe:
                        Personnage.CreationCompetence35[indiceCompetence].Bonus += '><(' + IntToStr(Asterisque) + ')';
                      ConstCompetenceBonus:
                        Personnage.CreationCompetence35[indiceCompetence].Bonus += 'B(' + IntToStr(Asterisque) + ')';
                      else
                        // TypeModif ni ChooseDice ni Bonus (donnee de livre inattendue) - rendu
                        // visible plutot que silencieusement ignore, meme famille de piege que
                        // les six TypSpell. A FAIRE.txt, arbitrage Nono du 15/09/2026.
                        Personnage.CreationCompetence35[indiceCompetence].Bonus += '?(' + IntToStr(Asterisque) + ')';
                    end;
                  end;
              end;
          // gérer les compétences 35
          For indiceCompetence := 0 to High(Personnage.CreationCompetence40) do
            if CompareRechercheValeur(ListTalentCompetenceModif[indiceTalent].CodeCompetence, Personnage.CreationCompetence40[indiceCompetence].CodeCompetence) then
              begin
                if Asterisque = 0 then
                  Asterisque := Personnage.Asterisque + 1;
                if CountOccurrences(Personnage.CreationCompetence40[indiceCompetence].Bonus, '(' + IntToStr(Asterisque) + ')') = 0 then
                  begin
                    if Personnage.CreationCompetence40[indiceCompetence].Bonus <> '' then
                      Personnage.CreationCompetence40[indiceCompetence].Bonus += '-';
                    case ListTalentCompetenceModif[indiceTalent].TypeModif of
                      ConstCompetenceInverseDe:
                        Personnage.CreationCompetence40[indiceCompetence].Bonus += '><(' + IntToStr(Asterisque) + ')';
                      ConstCompetenceBonus:
                        Personnage.CreationCompetence40[indiceCompetence].Bonus += 'B(' + IntToStr(Asterisque) + ')';
                      else
                        // Voir la meme garde sur CreationCompetence35 ci-dessus.
                        Personnage.CreationCompetence40[indiceCompetence].Bonus += '?(' + IntToStr(Asterisque) + ')';
                    end;
                  end;
              end;
          // gérer les compétence augmentées
          For indiceCompetence := 0 to High(Personnage.AugmentationCompetence) do
            if CompareRechercheValeur(ListTalentCompetenceModif[indiceTalent].CodeCompetence, Personnage.AugmentationCompetence[indiceCompetence].CodeCompetence) then
              begin
                if Asterisque = 0 then
                  Asterisque := Personnage.Asterisque + 1;
                if CountOccurrences(Personnage.AugmentationCompetence[indiceCompetence].Bonus, '(' + IntToStr(Asterisque) + ')') = 0 then
                  begin
                    if Personnage.AugmentationCompetence[indiceCompetence].Bonus <> '' then
                      Personnage.AugmentationCompetence[indiceCompetence].Bonus += '-';
                    case ListTalentCompetenceModif[indiceTalent].TypeModif of
                      ConstCompetenceInverseDe:
                        Personnage.AugmentationCompetence[indiceCompetence].Bonus += '><(' + IntToStr(Asterisque) + ')';
                      ConstCompetenceBonus:
                        Personnage.AugmentationCompetence[indiceCompetence].Bonus += 'B(' + IntToStr(Asterisque) + ')';
                      else
                        // Voir la meme garde sur CreationCompetence35 ci-dessus.
                        Personnage.AugmentationCompetence[indiceCompetence].Bonus += '?(' + IntToStr(Asterisque) + ')';
                    end;
                  end;
              end;

        end;
    end;

  Result := Asterisque;

end;

Function PersonnageMutationAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageMutationModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
    // V1 : malus chiffres des handicaps des magiciens (meme ligne que les mutations, ecran et PDF)
    if Personnage.HandicapsV1 <> '' then
      Result := Result + MalusHandicapsV1(Personnage.HandicapsV1, CodeAttribut);
  end;

Function PersonnageMutationModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    PersonnageMutation: StructurePersonnageMutation;
    indiceModif:        Integer;
  begin
    Result := 0;
    for PersonnageMutation in Personnage.Mutations do
      for indiceModif := 0 to (ListModificateur.Count - 1) do
        if (ListModificateur[indiceModif].TypeSource = SourceModifMutation)
           and (ListModificateur[indiceModif].TypeModif = TypeModif)
           and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnageMutation.Code)
           and CompareRechercheValeur(ListModificateur[indiceModif].Cible, Cible)
           and ((Trim(ListModificateur[indiceModif].Filtre) = '')
                or CompareRechercheValeur(ListModificateur[indiceModif].Filtre, Filtre)) then
          if ListModificateur[indiceModif].Aleatoire then
            Result := Result + MutationValeurEffet(PersonnageMutation.ValeurAleatoire, PersonnageMutation.ValeursEffets, ListModificateur[indiceModif].Cible)
          else
            Result := Result + ListModificateur[indiceModif].Facteur;
  end;

// Valeur du jet pour l'attribut Cible dans "code=valeur;code=valeur" ; a defaut (mutation a un seul
// jet, ou attribut absent de la liste) ValeurAleatoire.
Function MutationValeurEffet(ValeurAleatoire: Integer; ValeursEffets, Cible: String): Integer;
  var
    Liste: TStringList;
    Ind:   Integer;
    Paire: String;
  begin
    Result := ValeurAleatoire;
    if ValeursEffets = '' then
      Exit;
    Liste := TStringList.Create;
    try
      ExtractStrings([';'], [], PChar(ValeursEffets), Liste);
      for Ind := 0 to Liste.Count - 1 do
        begin
          Paire := Liste[Ind];
          if (Pos('=', Paire) > 0) and CompareRechercheValeur(Copy(Paire, 1, Pos('=', Paire) - 1), Cible) then
            begin
              Result := StrToIntDef(Copy(Paire, Pos('=', Paire) + 1, Length(Paire)), ValeurAleatoire);
              Exit;
            end;
        end;
    finally
      Liste.Free;
    end;
  end;

Procedure PersonnageMutationEffetsAleatoires(Code: String; out Faces: TArrayEntiersAleatoires; out Attributs: TArrayCodesAleatoires);
  var
    indiceModif: Integer;
  begin
    Faces     := nil;
    Attributs := nil;
    for indiceModif := 0 to (ListModificateur.Count - 1) do
      if (ListModificateur[indiceModif].TypeSource = SourceModifMutation)
         and ListModificateur[indiceModif].Aleatoire
         and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, Code) then
        begin
          SetLength(Faces, Length(Faces) + 1);
          SetLength(Attributs, Length(Attributs) + 1);
          Faces[High(Faces)]         := ListModificateur[indiceModif].Facteur;
          Attributs[High(Attributs)] := ListModificateur[indiceModif].Cible;
        end;
  end;

// Face totale (10 x nombre de des, ex. 20 pour 2d10), attribut et signe (+1 gain, -1 perte) du
// <ModifyCaracAleatoire> d'une mutation du catalogue ; 0 si elle n'en porte pas. Ne tire rien :
// le jet est valide par Nono (WinJetPathologie), puis range dans PersonnageMutation.ValeurAleatoire.
Function PersonnageMutationFaceAleatoire(Code: String; out CodeAttribut: String; out Signe: Integer): Integer;
  var
    indiceModif: Integer;
  begin
    Result       := 0;
    CodeAttribut := '';
    Signe        := 1;
    for indiceModif := 0 to (ListModificateur.Count - 1) do
      if (ListModificateur[indiceModif].TypeSource = SourceModifMutation)
         and ListModificateur[indiceModif].Aleatoire
         and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, Code) then
        begin
          Result       := Abs(ListModificateur[indiceModif].Facteur);
          if ListModificateur[indiceModif].Facteur < 0 then Signe := -1;
          CodeAttribut := ListModificateur[indiceModif].Cible;
          break;
        end;
  end;

Function PersonnageRaceLibelle(Personnage: StructurePersonnage; LibelleRace: String): String;
  var
    PRaceMutant: StructureRace;
  begin
    Result := LibelleRace;
    if (Length(Personnage.Mutations) = 0) or (Personnage.Race = 'TOC-RACE_MUTANT') then Exit;
    PRaceMutant := ChercheRace('TOC-RACE_MUTANT');
    if PRaceMutant.Libelle <> '' then
      Result := LibelleRace + ' (' + PRaceMutant.Libelle + ')';
  end;

Function PersonnageMutationEffetTexte(PersonnageMutation: StructurePersonnageMutation): String;
  // Meme principe que PersonnagePathologieEffetTexte (voir plus bas), mais pour les Mutations -
  // ajout du 27/09/2026, a la demande de Nono. Contrairement a Affliction, ListCorruptionModificateur
  // melange plusieurs TypeModif (ModifyCarac/ModifySkill/ModifArmour) : il faut filtrer, sinon un
  // ModifArmour matcherait a tort la recherche ModifyCarac. Aucun <ModifyCaracAleatoire> cote
  // Mutation (reserve aux Afflictions) : pas de branche Aleatoire ici, contrairement au pendant
  // Affliction - le champ StructureModificateur.Aleatoire n'est meme pas initialise pour les
  // entrees Mutation/Talent/CareerBonus/Arme/ArmureBonus, donc ne jamais le lire ici.
  var
    indiceModif: Integer;

  function AvecSigne(Valeur: Integer): String;
    begin
      if Valeur > 0 then
        Result := '+' + IntToStr(Valeur)
      else
        Result := IntToStr(Valeur);
    end;

  begin
    Result := '';
    // <ModifyCarac> : montant fixe ou jet + attribut vise ; plusieurs effets = separes par une virgule.
    for indiceModif := 0 to (ListModificateur.Count - 1) do
      if (ListModificateur[indiceModif].TypeSource = SourceModifMutation)
           and (ListModificateur[indiceModif].TypeModif = ConstXmlModifieAttribut)
         and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnageMutation.Code) then
        begin
          if Result <> '' then
            Result := Result + ', ';
          if ListModificateur[indiceModif].Aleatoire then
            Result := Result + AvecSigne(MutationValeurEffet(PersonnageMutation.ValeurAleatoire, PersonnageMutation.ValeursEffets, ListModificateur[indiceModif].Cible)) + ' ' + ChercheAttribut(ListModificateur[indiceModif].Cible).Libelle
          else
            Result := Result + AvecSigne(ListModificateur[indiceModif].Facteur) + ' ' + ChercheAttribut(ListModificateur[indiceModif].Cible).Libelle;
        end;
    if Result <> '' then
      Exit;
    // <ModifySkill> : montant fixe + competence visee.
    for indiceModif := 0 to (ListModificateur.Count - 1) do
      if (ListModificateur[indiceModif].TypeSource = SourceModifMutation)
           and (ListModificateur[indiceModif].TypeModif = ConstXmlModifieCompetence)
         and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnageMutation.Code) then
        begin
          Result := AvecSigne(ListModificateur[indiceModif].Facteur) + ' ' + ChercheCompetence(ListModificateur[indiceModif].Cible).Libelle;
          Exit;
        end;
    // <ModifySkillAttribut> : montant + attribut de rattachement des competences visees.
    for indiceModif := 0 to (ListCorruptionCompetenceAttributModif.Count - 1) do
      if CompareRechercheValeur(ListCorruptionCompetenceAttributModif[indiceModif].CodeCorruption, PersonnageMutation.Code) then
        begin
          Result := AvecSigne(ListCorruptionCompetenceAttributModif[indiceModif].Valeur) + ' ' + ChercheAttribut(ListCorruptionCompetenceAttributModif[indiceModif].CodeAttribut).Libelle + ' Tests';
          Exit;
        end;
    // Aucun modificateur chiffrable reconnu (ex. ModifArmour, ou aucun modificateur du tout) :
    // texte libre du catalogue.
    Result := ChercheCorruptionTable(PersonnageMutation.Code).Effet;
  end;

Function PersonnageAfflictionAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageAfflictionModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageAfflictionModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    PersonnagePathologie: StructurePersonnagePathologie;
    indiceModif:          Integer;
  begin
    Result := 0;
    for PersonnagePathologie in Personnage.Pathologies do
      if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
        for indiceModif := 0 to (ListModificateur.Count - 1) do
          if (ListModificateur[indiceModif].TypeSource = SourceModifAffliction)
             and (ListModificateur[indiceModif].TypeModif = TypeModif)
             and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnagePathologie.Code)
             and CompareRechercheValeur(ListModificateur[indiceModif].Cible, Cible)
             and ((Trim(ListModificateur[indiceModif].Filtre) = '')
                  or CompareRechercheValeur(ListModificateur[indiceModif].Filtre, Filtre)) then
            begin
              // <ModifyCaracAleatoire> : le montant fixe (Facteur) n'est qu'une face de de, la
              // vraie valeur a additionner est celle tiree une fois a l'ajout et memorisee sur
              // cette entree (voir StructurePersonnagePathologie.ValeurAleatoire).
              if ListModificateur[indiceModif].Aleatoire then
                Result := Result + PersonnagePathologie.ValeurAleatoire
              else
                Result := Result + ListModificateur[indiceModif].Facteur;
            end;
  end;

Function PersonnageAfflictionFaceAleatoire(Code: String; out CodeAttribut: String): Integer;
  var
    indiceModif: Integer;
  begin
    Result       := 0;
    CodeAttribut := '';
    for indiceModif := 0 to (ListModificateur.Count - 1) do
      if (ListModificateur[indiceModif].TypeSource = SourceModifAffliction)
         and ListModificateur[indiceModif].Aleatoire
         and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, Code) then
        begin
          Result       := ListModificateur[indiceModif].Facteur;
          CodeAttribut := ListModificateur[indiceModif].Cible;
          break;
        end;
  end;

Function PersonnageDiseaseAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageDiseaseModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageDiseaseModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    PersonnagePathologie: StructurePersonnagePathologie;
    indiceModif:          Integer;
  begin
    Result := 0;
    for PersonnagePathologie in Personnage.Pathologies do
      if PersonnagePathologie.TypeChapitre = ConstXmlChapitreDisease then
        for indiceModif := 0 to (ListModificateur.Count - 1) do
          if (ListModificateur[indiceModif].TypeSource = SourceModifMaladie)
             and (ListModificateur[indiceModif].TypeModif = TypeModif)
             and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnagePathologie.Code)
             and CompareRechercheValeur(ListModificateur[indiceModif].Cible, Cible)
             and ((Trim(ListModificateur[indiceModif].Filtre) = '')
                  or CompareRechercheValeur(ListModificateur[indiceModif].Filtre, Filtre)) then
            Result := Result + ListModificateur[indiceModif].Facteur;
  end;

Function PersonnagePathologieEffetTexte(PersonnagePathologie: StructurePersonnagePathologie): String;
  var
    indiceModif: Integer;

  function AvecSigne(Valeur: Integer): String;
    begin
      if Valeur > 0 then
        Result := '+' + IntToStr(Valeur)
      else
        Result := IntToStr(Valeur);
    end;

  begin
    Result := '';
    if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
      begin
        // <ModifyCaracAleatoire>/<ModifyCarac> : le montant tire/fixe et l'attribut vise.
        for indiceModif := 0 to (ListModificateur.Count - 1) do
          if (ListModificateur[indiceModif].TypeSource = SourceModifAffliction)
             and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnagePathologie.Code) then
            begin
              if ListModificateur[indiceModif].Aleatoire then
                Result := AvecSigne(PersonnagePathologie.ValeurAleatoire) + ' ' + ChercheAttribut(ListModificateur[indiceModif].Cible).Libelle
              else
                Result := AvecSigne(ListModificateur[indiceModif].Facteur) + ' ' + ChercheAttribut(ListModificateur[indiceModif].Cible).Libelle;
              Exit;
            end;
        // <ModifySkillAttribut> : montant + attribut de rattachement des competences visees.
        for indiceModif := 0 to (ListAfflictionCompetenceAttributModif.Count - 1) do
          if CompareRechercheValeur(ListAfflictionCompetenceAttributModif[indiceModif].CodeSource, PersonnagePathologie.Code) then
            begin
              Result := AvecSigne(ListAfflictionCompetenceAttributModif[indiceModif].Valeur) + ' ' + ChercheAttribut(ListAfflictionCompetenceAttributModif[indiceModif].CodeAttribut).Libelle + ' Tests';
              Exit;
            end;
        // Aucun modificateur chiffrable : texte libre du catalogue.
        Result := ChercheAffliction(PersonnagePathologie.Code).Effet;
      end
    else
      begin
        // <ModifyCarac> : montant fixe + attribut vise (aucune Disease n'en porte encore dans
        // les livres chargés ; meme rendu que l'Affliction des qu'une en declare un).
        for indiceModif := 0 to (ListModificateur.Count - 1) do
          if (ListModificateur[indiceModif].TypeSource = SourceModifMaladie)
             and (ListModificateur[indiceModif].TypeModif = ConstXmlModifieAttribut)
             and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnagePathologie.Code) then
            begin
              Result := AvecSigne(ListModificateur[indiceModif].Facteur) + ' ' + ChercheAttribut(ListModificateur[indiceModif].Cible).Libelle;
              Exit;
            end;
        // Aucun modificateur chiffrable : texte libre des Symptoms.
        Result := ChercheDisease(PersonnagePathologie.Code).Symptoms;
      end;
  end;

Function PersonnageAfflictionCompetenceModif(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  var
    PersonnagePathologie: StructurePersonnagePathologie;
    PCompetence:          StructureCompetence;
    AttributCompetence:   String;
    indiceModif:          Integer;
  begin
    Result := 0;
    PCompetence        := ChercheCompetence(CodeCompetence);
    AttributCompetence := PCompetence.CodeAttribut;
    if AttributCompetence = '' then Exit;

    for PersonnagePathologie in Personnage.Pathologies do
      if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
        for indiceModif := 0 to (ListAfflictionCompetenceAttributModif.Count - 1) do
          if CompareRechercheValeur(ListAfflictionCompetenceAttributModif[indiceModif].CodeSource, PersonnagePathologie.Code)
             and CompareRechercheValeur(ListAfflictionCompetenceAttributModif[indiceModif].CodeAttribut, AttributCompetence) then
            Result := Result + ListAfflictionCompetenceAttributModif[indiceModif].Valeur;
  end;

Function PersonnageTalentAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    // Multiplie par PersonnageTalent.Valeur (niveau du talent) dans PersonnageTalentModificateur
    // depuis le 06/09/2026 : un talent a niveaux multiples (Max different de "1", ex. Luck/
    // Chanceux RULES-T0020, Strong-Minded/Obstine RULES-T0107) donne son ModifyCarac autant de
    // fois que de niveaux pris, comme le faisait l'ancien case (Chance := Chance + Val). Sans
    // effet sur le pilote Fleet Footed (RULES-T0162, Max="1", Valeur toujours 1).
    Result := PersonnageTalentModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageTalentModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    PersonnageTalent: StructurePersonnageTalent;
    indiceModif:      Integer;
  begin
    Result := 0;
    for PersonnageTalent in Personnage.CreationTalent do
      for indiceModif := 0 to (ListModificateur.Count - 1) do
        if (ListModificateur[indiceModif].TypeSource = SourceModifTalent)
           and (ListModificateur[indiceModif].TypeModif = TypeModif)
           and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnageTalent.CodeTalent)
           and CompareRechercheValeur(ListModificateur[indiceModif].Cible, Cible)
           and ((Trim(ListModificateur[indiceModif].Filtre) = '')
                or CompareRechercheValeur(ListModificateur[indiceModif].Filtre, Filtre)) then
          Result := Result + ListModificateur[indiceModif].Facteur * PersonnageTalent.Valeur;
    // Personnage.MetierTalent n'est PAS une liste de talents possedes : c'est le menu de la
    // table de carriere en cours (tous paliers), qui sert seulement a proposer des choix sur
    // l'ecran Augmentation et a memoriser la specialite resolue pour un talent '_*'. Un
    // talent achete depuis cette liste est deja compte via Personnage.AugmentationTalent
    // (boucle suivante) - le boucler ici aussi comptait un bonus pour n'importe quel talent
    // simplement LISTE dans la table de carriere, jamais realise, y compris jamais pris.
    // Boucle ajoutee par erreur le 11/09/2026, retiree le 26/09/2026 (confirme par Nono).
    for PersonnageTalent in Personnage.AugmentationTalent do
      for indiceModif := 0 to (ListModificateur.Count - 1) do
        if (ListModificateur[indiceModif].TypeSource = SourceModifTalent)
           and (ListModificateur[indiceModif].TypeModif = TypeModif)
           and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnageTalent.CodeTalent)
           and CompareRechercheValeur(ListModificateur[indiceModif].Cible, Cible)
           and ((Trim(ListModificateur[indiceModif].Filtre) = '')
                or CompareRechercheValeur(ListModificateur[indiceModif].Filtre, Filtre)) then
          Result := Result + ListModificateur[indiceModif].Facteur * PersonnageTalent.Valeur;
  end;

Function PersonnageTalentArmeModif(Personnage: StructurePersonnage; PArme: StructureArme): Integer;
  begin
    Result := 0;
    if Trim(PArme.TypeArme) = '' then
      Exit;
    Result := PersonnageTalentModificateur(Personnage, ConstXmlModifieArme, PArme.TypeArme, PArme.CodeCompetence);
  end;

Function PersonnageNiveauDansMetier(Personnage: StructurePersonnage; CodeMetier: String): Integer;
  var
    IndMetier: Integer;
  begin
    Result := 0;
    if CompareRechercheValeur(Personnage.MetierEnCours.CodeMetier, CodeMetier) then
      Result := Personnage.MetierEnCours.NiveauMetier;
    for IndMetier := 0 to High(Personnage.MetierAncien) do
      if CompareRechercheValeur(Personnage.MetierAncien[IndMetier].CodeMetier, CodeMetier) then
        if Personnage.MetierAncien[IndMetier].NiveauMetier > Result then
          Result := Personnage.MetierAncien[IndMetier].NiveauMetier;
  end;

Function CompetencesFamilierV1(Personnage: StructurePersonnage): String;
  var
    PFamilier: StructureFamilierV1;
    Niveau:    Integer;
    IndMetier: Integer;
  begin
    Result := '';
    if Personnage.FamilierV1 = '' then
      Exit;
    PFamilier := ChercheFamilierV1(Personnage.FamilierV1);
    // niveau le plus haut atteint comme Druidic Priest (V1 : un code de carriere par niveau)
    Niveau := 0;
    if TableAvancementPretreV1(Personnage.MetierEnCours.CodeMetier) = 'DRUID' then
      Niveau := NiveauCarriereV1(Personnage.MetierEnCours.CodeMetier);
    for IndMetier := 0 to High(Personnage.MetierAncien) do
      if (TableAvancementPretreV1(Personnage.MetierAncien[IndMetier].CodeMetier) = 'DRUID') and
         (NiveauCarriereV1(Personnage.MetierAncien[IndMetier].CodeMetier) > Niveau) then
        Niveau := NiveauCarriereV1(Personnage.MetierAncien[IndMetier].CodeMetier);
    if Niveau >= 1 then
      Result := PFamilier.Comp1;
    if Niveau >= 2 then
      Result := Result + ';' + PFamilier.Comp2;
  end;

Function PersonnageCareerBonusAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageCareerBonusModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageCareerBonusModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    Appartenances:  TStringList;
    IndApp:         Integer;
    IndModif:       Integer;
    NiveauAtteint:  Integer;
    PBonus:         StructureCareerBonus;
    CodeApp:        String;
  begin
    Result := 0;
    if Trim(Personnage.Appartenance) = '' then
      Exit;
    Appartenances := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Personnage.Appartenance), Appartenances);
      for IndApp := 0 to Appartenances.Count - 1 do
        begin
          CodeApp := Trim(Appartenances[IndApp]);
          if CodeApp = '' then
            continue;
          PBonus        := ChercheCareerBonus(CodeApp);
          NiveauAtteint := PersonnageNiveauDansMetier(Personnage, PBonus.CodeMetier);
          if NiveauAtteint <= 0 then
            continue;
          for IndModif := 0 to (ListModificateur.Count - 1) do
            if (ListModificateur[IndModif].TypeSource = SourceModifCareerBonus)
               and (ListModificateur[IndModif].TypeModif = TypeModif)
               and CompareRechercheValeur(ListModificateur[IndModif].CodeSource, CodeApp)
               and CompareRechercheValeur(ListModificateur[IndModif].Cible, Cible)
               and ((Trim(ListModificateur[IndModif].Filtre) = '')
                    or CompareRechercheValeur(ListModificateur[IndModif].Filtre, Filtre))
               and (ListModificateur[IndModif].Niveau <= NiveauAtteint) then
              Result := Result + ListModificateur[IndModif].Facteur;
        end;
    finally
      Appartenances.Free;
    end;
  end;

Function PersonnageAvanceGratuite(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
var
  PAttribut: StructurePersonnageAttribut;
begin
  Result := 0;
  for PAttribut in Personnage.AvanceGratuiteAttribut do
    if CompareRechercheValeur(PAttribut.CodeAttribut, CodeAttribut) then
      Result := Result + PAttribut.Valeur;
end;

Function PersonnageCareerBonusCompetenceModif(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  begin
    Result := PersonnageCareerBonusModificateur(Personnage, ConstXmlModifieCompetence, CodeCompetence);
  end;

Function PersonnageCareerBonusArmeModif(Personnage: StructurePersonnage; PArme: StructureArme): Integer;
  begin
    Result := 0;
    if Trim(PArme.TypeArme) = '' then
      Exit;
    Result := PersonnageCareerBonusModificateur(Personnage, ConstXmlModifieArme, PArme.TypeArme, PArme.CodeCompetence);
  end;

Function PersonnageCareerBonusSpecialRule(Personnage: StructurePersonnage): TListCareerBonusSpecialRule;
  var
    Appartenances:  TStringList;
    IndApp:         Integer;
    IndRegle:       Integer;
    NiveauAtteint:  Integer;
    PBonus:         StructureCareerBonus;
    CodeApp:        String;
  begin
    Result := TListCareerBonusSpecialRule.Create;
    if Trim(Personnage.Appartenance) = '' then
      Exit;
    Appartenances := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Personnage.Appartenance), Appartenances);
      for IndApp := 0 to Appartenances.Count - 1 do
        begin
          CodeApp := Trim(Appartenances[IndApp]);
          if CodeApp = '' then
            continue;
          // Meme filtre de palier que PersonnageCareerBonusArmeModif ci-dessus.
          PBonus        := ChercheCareerBonus(CodeApp);
          NiveauAtteint := PersonnageNiveauDansMetier(Personnage, PBonus.CodeMetier);
          if NiveauAtteint <= 0 then
            continue;
          for IndRegle := 0 to (ListCareerBonusSpecialRule.Count - 1) do
            if CompareRechercheValeur(ListCareerBonusSpecialRule[IndRegle].CodeBonus, CodeApp)
               and (ListCareerBonusSpecialRule[IndRegle].Niveau <= NiveauAtteint) then
              Result.Add(ListCareerBonusSpecialRule[IndRegle]);
        end;
    finally
      Appartenances.Free;
    end;
  end;

Function PersonnageArmeAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageArmeModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageArmeModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    IndModif:             Integer;
  begin
    Result := 0;
    for PersonnageEquipement in Personnage.Equipement do
      if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe) then
        for IndModif := 0 to (ListModificateur.Count - 1) do
          if (ListModificateur[IndModif].TypeSource = SourceModifArme)
             and (ListModificateur[IndModif].TypeModif = TypeModif)
             and CompareRechercheValeur(ListModificateur[IndModif].CodeSource, PersonnageEquipement.CodeEquipement)
             and CompareRechercheValeur(ListModificateur[IndModif].Cible, Cible)
             and ((Trim(ListModificateur[IndModif].Filtre) = '')
                  or CompareRechercheValeur(ListModificateur[IndModif].Filtre, Filtre)) then
            Result := Result + ListModificateur[IndModif].Facteur;
  end;

Function PersonnageSansMunitions(Personnage: StructurePersonnage): StructurePersonnage;
  var
    Ind: Integer;
    Nb:  Integer;
  begin
    Result := Personnage;
    if Pos(AjouteAccolade(ConstXmlOptionSansMunition), Personnage.Options) = 0 then exit;
    Nb := 0;
    SetLength(Result.Equipement, Length(Personnage.Equipement)); // copie propre : on ne touche pas au tableau de l'appelant
    for Ind := 0 to High(Personnage.Equipement) do
      if not ((TrimRight(Personnage.Equipement[Ind].TypeEquipement) = TrimRight(TypeEquipWe))
              and (Pos(EquipementMU, Personnage.Equipement[Ind].CodeEquipement) > 0)) then
        begin
          Result.Equipement[Nb] := Personnage.Equipement[Ind];
          Inc(Nb);
        end;
    SetLength(Result.Equipement, Nb);
  end;

Function EquipementCompte(PersonnageEquipement: StructurePersonnageEquipement): Boolean;
  var
    Type_: String;
  begin
    Type_ := TrimRight(PersonnageEquipement.TypeEquipement);
    if (Type_ = TrimRight(TypeEquipWe)) or (Type_ = TrimRight(TypeEquipAR))
       or (Type_ = TrimRight(TypeEquipARS)) or (Type_ = TrimRight(TypeEquipDI)) then
      Result := PersonnageEquipement.Porte
    else
      Result := True;
  end;

Function PersonnageArmureQualites(Personnage: StructurePersonnage): TStringList;
// Un code de qualite (ListeBonus) par occurrence, pour chaque piece d'armure equipee -
// normale (TypeEquipAR, ChercheArmure) ou simplifiee (TypeEquipARS, ChercheArmureSimplifiee).
// Pas de deduplication : deux pieces portant la meme qualite cumulent. Suffixe numerique
// optionnel ("ARMOB_18 2") retire ; les alternatives ("ARMOB_02/ARMOB_04") sont gardees
// telles quelles, comme l'annotation existante (pdfpersonnage.pas) qui ne les resout pas
// non plus. L'APPELANT est proprietaire de la liste rendue et doit la liberer - meme
// contrat que NiveauxDuCareerBonus (chargemetier.pas, 2.44).
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    PArmure:              StructureArmure;
    PArmureSimplifiee:    StructureArmureSimplifiee;
    ListeBonus:           String;
    Liste:                TStringList;
    Element:              String;
    Ind:                  Integer;
  begin
    Result := TStringList.Create;
    Liste  := TStringList.Create;
    try
      for PersonnageEquipement in Personnage.Equipement do
        begin
          if not EquipementCompte(PersonnageEquipement) then
            continue;
          ListeBonus := '';
          if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAR) then
            begin
              PArmure    := ChercheArmure(PersonnageEquipement.CodeEquipement);
              ListeBonus := PArmure.ListeBonus;
            end
          else if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipARS) then
            begin
              PArmureSimplifiee := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement);
              ListeBonus         := PArmureSimplifiee.ListeBonus;
            end;
          if (ListeBonus <> '') and (ListeBonus <> '-') then
            begin
              Liste.Clear;
              ExtractStrings([','], [], PChar(ListeBonus), Liste);
              for Ind := 0 to Liste.Count - 1 do
                begin
                  Element := Trim(Liste[Ind]);
                  if Pos(' ', Element) > 0 then
                    Element := Trim(ExtractStringBefore(Element, ' '));
                  if Element <> '' then
                    Result.Add(Element);
                end;
            end;
        end;
    finally
      Liste.Free;
    end;
  end;

Function PersonnageArmureQualitesPortees(Personnage: StructurePersonnage): TArrayPersonnageArmureQualitePortee;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    ListeQualites:        String;
    Liste:                TStringList;
    Alternatives:         TStringList;
    Element:              String;
    Code:                 String;
    Ind, IndAlt:          Integer;
    Entree:               StructurePersonnageArmureQualitePortee;
  begin
    Result       := [];
    Liste        := TStringList.Create;
    Alternatives := TStringList.Create;
    try
      for PersonnageEquipement in Personnage.Equipement do
        if EquipementCompte(PersonnageEquipement)
           and ((TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAR))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipARS))) then
          begin
            // Meme double source que PersonnageArmureBonusTalent : qualites du catalogue
            // (StructureArmure/ArmureSimplifiee.ListeBonus) et qualites de fabrication ajoutees
            // par le joueur (PersonnageEquipement.QualiteEquipement).
            if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAR) then
              ListeQualites := ChercheArmure(PersonnageEquipement.CodeEquipement).ListeBonus
            else
              ListeQualites := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement).ListeBonus;
            if PersonnageEquipement.QualiteEquipement <> '' then
              begin
                if ListeQualites <> '' then
                  ListeQualites := ListeQualites + ',';
                ListeQualites := ListeQualites + PersonnageEquipement.QualiteEquipement;
              end;

            Liste.Clear;
            ExtractStrings([','], [], PChar(ListeQualites), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                if Pos(' ', Element) > 0 then
                  Element := Trim(ExtractStringBefore(Element, ' '));

                Alternatives.Clear;
                ExtractStrings([SeparateurMulti], [], PChar(Element), Alternatives);
                for IndAlt := 0 to Alternatives.Count - 1 do
                  begin
                    Code := Trim(Alternatives[IndAlt]);
                    if Code <> '' then
                      begin
                        Entree.CodeEquipement := PersonnageEquipement.CodeEquipement;
                        Entree.CodeQualite    := Code;
                        Result                += [Entree];
                      end;
                  end;
              end;
          end;
    finally
      Alternatives.Free;
      Liste.Free;
    end;
  end;

Function PersonnageFabricationArmureModif(Personnage: StructurePersonnage; CodeLocalisation: String): Integer;
  begin
    Result := PersonnageFabricationModificateur(Personnage, ConstXmlModifieArmure, CodeLocalisation);
  end;

Function PersonnageFabricationAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageFabricationModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageFabricationModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String): Integer;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    Liste:                TStringList;
    Element:              String;
    Code:                 String;
    Niveau:               Integer;
    Ind, IndModif:        Integer;
  begin
    Result := 0;
    Liste  := TStringList.Create;
    try
      for PersonnageEquipement in Personnage.Equipement do
        if EquipementCompte(PersonnageEquipement)
           and ((TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAR))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipARS))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe))
                // Objet generique (DATA_TRAPPING, ex. Ring/Talisman/Robe) - ajoute le 28/09/2026 :
                // le bouton Fabrication de WinPersonnage acceptait deja une qualite sur ce type de
                // ligne (SelectWinFabricationType='Misc'), mais l'effet n'etait jamais lu ici. Voir
                // A FAIRE.txt "il faut pouvoir ajouter des bonus sur des objets generiques".
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipDI)))
           and (PersonnageEquipement.QualiteEquipement <> '') then
          begin
            Liste.Clear;
            ExtractStrings([','], [], PChar(PersonnageEquipement.QualiteEquipement), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                Code    := Element;
                Niveau  := 1;
                if Pos(' ', Element) > 0 then
                  begin
                    Code   := Trim(ExtractStringBefore(Element, ' '));
                    Niveau := StrToIntDef(Trim(Copy(Element, Pos(' ', Element) + 1, Length(Element))), 1);
                  end;
                for IndModif := 0 to ListModificateur.Count - 1 do
                  if EntreeFabrication(ListModificateur[IndModif]) and (ListModificateur[IndModif].TypeModif = TypeModif)
                     and CompareRechercheValeur(ListModificateur[IndModif].CodeSource, Code)
                     and CompareRechercheValeur(ListModificateur[IndModif].Cible, Cible) then
                    Result := Result + ListModificateur[IndModif].Facteur * Niveau;
              end;
          end;
    finally
      Liste.Free;
    end;
  end;

// Enumere les elements possedes qui peuvent porter des modificateurs, avec la meme portee
// que les huit fonctions Personnage<Source>Modificateur qu'elle remplace (etape b : meme
// resultat que l'existant, les corrections de comportement viennent a l'etape c).
Function PersonnageSourcesModif(Personnage: StructurePersonnage): TArraySourceModif;
  var
    Sources:              TArraySourceModif;
    Nb:                   Integer;
    PersonnageTalent:     StructurePersonnageTalent;
    PersonnageMutation:   StructurePersonnageMutation;
    PersonnagePathologie: StructurePersonnagePathologie;
    PersonnageEquipement: StructurePersonnageEquipement;
    Appartenances:        TStringList;
    Qualites:             TStringList;
    Liste:                TStringList;
    Element, Code:        String;
    CodeApp:              String;
    Niveau, Ind:          Integer;
    Rang:                 Integer;

  procedure Ajouter(const TypeSource, CodeSource: String; Multiplicateur: Integer = 1;
                    NiveauAtteint: Integer = 0; ValeurAleatoire: Integer = 0; IgnoreFiltre: Boolean = False; Groupe: Integer = 0;
                    ValeursEffets: String = '');
    begin
      if Nb >= Length(Sources) then
        SetLength(Sources, Nb * 2 + 16);
      Sources[Nb].TypeSource      := TypeSource;
      Sources[Nb].Code            := CodeSource;
      Sources[Nb].Multiplicateur  := Multiplicateur;
      Sources[Nb].NiveauAtteint   := NiveauAtteint;
      Sources[Nb].ValeurAleatoire := ValeurAleatoire;
      Sources[Nb].ValeursEffets   := ValeursEffets;
      Sources[Nb].IgnoreFiltre    := IgnoreFiltre;
      Sources[Nb].Groupe          := Groupe;
      Inc(Nb);
    end;

  begin
    Sources := nil;
    Nb      := 0;

    // Talents : creation + augmentations, multiplies par le rang (voir PersonnageTalentModificateur).
    for PersonnageTalent in Personnage.CreationTalent do
      Ajouter(SourceModifTalent, PersonnageTalent.CodeTalent, PersonnageTalent.Valeur);
    for PersonnageTalent in Personnage.AugmentationTalent do
      Ajouter(SourceModifTalent, PersonnageTalent.CodeTalent, PersonnageTalent.Valeur);

    for PersonnageMutation in Personnage.Mutations do
      Ajouter(SourceModifMutation, PersonnageMutation.Code, 1, 0, PersonnageMutation.ValeurAleatoire, False, 0, PersonnageMutation.ValeursEffets);

    for PersonnagePathologie in Personnage.Pathologies do
      if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
        Ajouter(SourceModifAffliction, PersonnagePathologie.Code, 1, 0, PersonnagePathologie.ValeurAleatoire)
      else if PersonnagePathologie.TypeChapitre = ConstXmlChapitreDisease then
        Ajouter(SourceModifMaladie, PersonnagePathologie.Code);

    // Bonus d'appartenance : seulement ceux dont le metier est atteint, avec le palier atteint.
    if Trim(Personnage.Appartenance) <> '' then
      begin
        Appartenances := TStringList.Create;
        try
          ExtractStrings([','], [], PChar(Personnage.Appartenance), Appartenances);
          for Ind := 0 to Appartenances.Count - 1 do
            begin
              CodeApp := Trim(Appartenances[Ind]);
              if CodeApp = '' then
                continue;
              Niveau := PersonnageNiveauDansMetier(Personnage, ChercheCareerBonus(CodeApp).CodeMetier);
              if Niveau > 0 then
                Ajouter(SourceModifCareerBonus, CodeApp, 1, Niveau);
            end;
        finally
          Appartenances.Free;
        end;
      end;

    // Armes PORTEES seulement (etape d : avant, une arme possedee mais rangee comptait).
    Rang := 0;
    for PersonnageEquipement in Personnage.Equipement do
      begin
        Inc(Rang);
        if EquipementCompte(PersonnageEquipement) and (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe)) then
          Ajouter(SourceModifArme, PersonnageEquipement.CodeEquipement, 1, 0, 0, False, Rang);
      end;

    // Qualites d'armure du catalogue, une par occurrence (comme PersonnageArmureBonusModificateur).
    Qualites := PersonnageArmureQualites(Personnage);
    try
      for Ind := 0 to Qualites.Count - 1 do
        Ajouter(SourceModifArmureBonus, Qualites[Ind]);
    finally
      Qualites.Free;
    end;

    // Qualites de fabrication des pieces PORTEES (armure, arme, objet generique), avec leur niveau.
    Liste := TStringList.Create;
    try
      Rang := 0;
      for PersonnageEquipement in Personnage.Equipement do
        begin
        Inc(Rang);
        if EquipementCompte(PersonnageEquipement)
           and ((TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAR))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipARS))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipDI)))
           and (PersonnageEquipement.QualiteEquipement <> '') then
          begin
            Liste.Clear;
            ExtractStrings([','], [], PChar(PersonnageEquipement.QualiteEquipement), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                Code    := Element;
                Niveau  := 1;
                if Pos(' ', Element) > 0 then
                  begin
                    Code   := Trim(ExtractStringBefore(Element, ' '));
                    Niveau := StrToIntDef(Trim(Copy(Element, Pos(' ', Element) + 1, Length(Element))), 1);
                  end;
                Ajouter(SourceModifFabrication, Code, Niveau, 0, 0, True, Rang);
              end;
          end;
        end;
    finally
      Liste.Free;
    end;

    // Qualites PROPRES des armes portees (Shield 2, Reload 3...) : sources de fabrication, niveau = valeur du jeton.
    // Une alternative "A/B" n'est pas un effet cumulable : elle reste hors du collecteur.
    Liste := TStringList.Create;
    try
      Rang := 0;
      for PersonnageEquipement in Personnage.Equipement do
        begin
        Inc(Rang);
        if EquipementCompte(PersonnageEquipement) and (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe)) then
          begin
            Liste.Clear;
            ExtractStrings([','], [], PChar(ChercheArme(PersonnageEquipement.CodeEquipement).ListeBonus), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                if (Element = '') or (Element = '-') or (Pos(SeparateurMulti, Element) > 0) then
                  continue;
                Code   := Element;
                Niveau := 1;
                if Pos(' ', Element) > 0 then
                  begin
                    Code   := Trim(ExtractStringBefore(Element, ' '));
                    Niveau := StrToIntDef(Trim(Copy(Element, Pos(' ', Element) + 1, Length(Element))), 1);
                  end;
                Ajouter(SourceModifFabrication, Code, Niveau, 0, 0, True, Rang);
              end;
          end;
        end;
    finally
      Liste.Free;
    end;

    SetLength(Sources, Nb);
    Result := Sources;
  end;

// Somme des modificateurs (TypeModif, Cible[, Filtre]) de tous les elements possedes : un seul
// parcours de ListModificateur par source, quel que soit le type d'element.
Function PersonnageModificateurUnique(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''; SansFabrication: Boolean = False; MaxParPiece: Boolean = False; SeulementFabrication: Boolean = False): Integer;
  var
    Sources:   TArraySourceModif;
    Source:    StructureSourceModif;
    IndModif:  Integer;
    Entree:    StructureModificateur;
    Compatible: Boolean;
    Totaux:    array of Integer;  // MaxParPiece : un total par piece d'equipement
    Apport, I, Meilleur: Integer;
  begin
    Result  := 0;
    Totaux  := nil;
    Sources := PersonnageSourcesModif(Personnage);
    for Source in Sources do
      if not (SansFabrication and (Source.TypeSource = SourceModifFabrication))
         and not (SeulementFabrication and (Source.TypeSource <> SourceModifFabrication)) then
      for IndModif := 0 to ListModificateur.Count - 1 do
        begin
          Entree := ListModificateur[IndModif];
          if Entree.TypeModif <> TypeModif then
            continue;
          // Les entrees de fabrication viennent de trois types d'element (fabrication, qualite
          // d'arme, trapping) rangees dans la meme liste d'origine.
          if Source.TypeSource = SourceModifFabrication then
            Compatible := (Entree.TypeSource = SourceModifFabrication) or (Entree.TypeSource = SourceModifQualiteArme)
                          or (Entree.TypeSource = SourceModifTrapping)
          else
            Compatible := Entree.TypeSource = Source.TypeSource;
          if not Compatible then
            continue;
          if not CompareRechercheValeur(Entree.CodeSource, Source.Code) then
            continue;
          if not CompareRechercheValeur(Entree.Cible, Cible) then
            continue;
          if not Source.IgnoreFiltre then
            if not ((Trim(Entree.Filtre) = '') or CompareRechercheValeur(Entree.Filtre, Filtre)) then
              continue;
          if (Source.TypeSource = SourceModifCareerBonus) and (Entree.Niveau > Source.NiveauAtteint) then
            continue;
          if Entree.Aleatoire then
            Apport := MutationValeurEffet(Source.ValeurAleatoire, Source.ValeursEffets, Entree.Cible)
          else
            Apport := Entree.Facteur * Source.Multiplicateur;
          if MaxParPiece and (Source.Groupe > 0) then
            begin
              if Source.Groupe >= Length(Totaux) then
                SetLength(Totaux, Source.Groupe + 1);
              Totaux[Source.Groupe] := Totaux[Source.Groupe] + Apport;
            end
          else
            Result := Result + Apport;
        end;
    // MaxParPiece (bouclier) : une seule piece sert a la fois, on garde la meilleure
    Meilleur := 0;
    for I := 0 to Length(Totaux) - 1 do
      if Totaux[I] > Meilleur then Meilleur := Totaux[I];
    Result := Result + Meilleur;
  end;

Function ArmeEstADistance(CodeArme: String): Boolean;
  begin
    Result := Pos(EquipementCT, CodeArme) > 0;
  end;

Function PersonnageAlignementV1(Personnage: StructurePersonnage): String;
begin
  if Personnage.AlignementV1 <> '' then
    Result := Personnage.AlignementV1
  else if Pos('ELF', Personnage.Race) > 0 then
    Result := 'RULES-V1ALIGN_GOOD'
  else
    Result := 'RULES-V1ALIGN_NEUTRAL';
end;

Function PersonnageNombreMains(Personnage: StructurePersonnage): Integer;
  begin
    Result := ConstMainsBase + PersonnageModificateurUnique(Personnage, ConstXmlModifieMains, ConstCibleModifieMains);
    if Result < 0 then
      Result := 0;
  end;

Function PersonnageMainsUtilisees(Personnage: StructurePersonnage; ADistance: Boolean): Integer;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
  begin
    Result := 0;
    for PersonnageEquipement in Personnage.Equipement do
      if EquipementCompte(PersonnageEquipement)
         and (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe))
         and (ArmeEstADistance(PersonnageEquipement.CodeEquipement) = ADistance) then
        Result := Result + ChercheArme(PersonnageEquipement.CodeEquipement).Mains;
  end;

Function PersonnageMainsDepassees(Personnage: StructurePersonnage): Boolean;
  var
    Mains: Integer;
  begin
    Mains  := PersonnageNombreMains(Personnage);
    Result := (PersonnageMainsUtilisees(Personnage, False) > Mains)
              or (PersonnageMainsUtilisees(Personnage, True) > Mains);
  end;

// Etape d : total des modificateurs <ModifySkill> d'une competence, toutes sources possedees
// confondues, par le collecteur unique. Reprend la regle de famille des mutations (une
// specialisation herite des effets visant sa competence generique) pour toutes les sources, et
// ajoute les deux effets "par attribut de rattachement" (mutation, affliction), qui vivent dans
// des listes a part, hors moteur.
Function PersonnageCompetenceModificateur(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  var
    PCompetence:        StructureCompetence;
    PGenerique:         StructureCompetence;
    CodeGenerique:      String;
    AttributCompetence: String;
    PersonnageMutation: StructurePersonnageMutation;
    PersonnagePathologie: StructurePersonnagePathologie;
    IndModif:           Integer;
  begin
    CodeGenerique := '';
    PCompetence   := ChercheCompetence(CodeCompetence);
    if PCompetence.SousCompetence then
      begin
        if PCompetence.CodeGenerique <> '' then
          CodeGenerique := PCompetence.CodeGenerique
        else
          begin
            CodeGenerique := CodeGeneriqueDeduit(PCompetence.CodeCompetence);
            for PGenerique in ListCompetence do
              if CodeSansLivre(PGenerique.CodeCompetence) = CodeSansLivre(CodeGenerique) then
                begin
                  CodeGenerique := PGenerique.CodeCompetence;
                  break;
                end;
          end;
      end;
    AttributCompetence := PCompetence.CodeAttribut;
    if (AttributCompetence = '') and (CodeGenerique <> '') then
      AttributCompetence := ChercheCompetence(CodeGenerique).CodeAttribut;

    Result := PersonnageModificateurUnique(Personnage, ConstXmlModifieCompetence, CodeCompetence);
    if CodeGenerique <> '' then
      Result := Result + PersonnageModificateurUnique(Personnage, ConstXmlModifieCompetence, CodeGenerique);

    if AttributCompetence = '' then
      Exit;
    // Qualites d'armes PORTEES ("+10% Fellowship Tests") : seules les sources de fabrication,
    // mutations et afflictions ayant leurs listes dediees ci-dessous.
    Result := Result + PersonnageModificateurUnique(Personnage, ConstXmlModifieCompetenceAttribut, AttributCompetence, '', False, False, True);
    for PersonnageMutation in Personnage.Mutations do
      for IndModif := 0 to (ListCorruptionCompetenceAttributModif.Count - 1) do
        if CompareRechercheValeur(ListCorruptionCompetenceAttributModif[IndModif].CodeCorruption, PersonnageMutation.Code)
           and CompareRechercheValeur(ListCorruptionCompetenceAttributModif[IndModif].CodeAttribut, AttributCompetence) then
          Result := Result + ListCorruptionCompetenceAttributModif[IndModif].Valeur;
    // Afflictions : l'ancienne fonction ne regarde que l'attribut de la competence elle-meme.
    AttributCompetence := PCompetence.CodeAttribut;
    if AttributCompetence <> '' then
      for PersonnagePathologie in Personnage.Pathologies do
        if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
          for IndModif := 0 to (ListAfflictionCompetenceAttributModif.Count - 1) do
            if CompareRechercheValeur(ListAfflictionCompetenceAttributModif[IndModif].CodeSource, PersonnagePathologie.Code)
               and CompareRechercheValeur(ListAfflictionCompetenceAttributModif[IndModif].CodeAttribut, AttributCompetence) then
              Result := Result + ListAfflictionCompetenceAttributModif[IndModif].Valeur;
  end;

Function PersonnageArmureBonusCompetenceModifPortee(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  var
    QualitesPortees:    TArrayPersonnageArmureQualitePortee;
    PiecesTraitees:      TStringList;
    Ind, IndModif:       Integer;
    IndListe:            Integer;
    Piece:               String;
    SousTotalPiece:      Integer;
    PieceEstPractical:   Boolean;
    PieceEstUnreliable:  Boolean;
  begin
    Result          := 0;
    QualitesPortees := PersonnageArmureQualitesPortees(Personnage);
    PiecesTraitees  := TStringList.Create;
    try
      for Ind := 0 to Length(QualitesPortees) - 1 do
        begin
          Piece := QualitesPortees[Ind].CodeEquipement;
          if PiecesTraitees.IndexOf(Piece) >= 0 then
            continue;
          PiecesTraitees.Add(Piece);

          // Malus/bonus ARMOB de CETTE piece pour CodeCompetence, et qualites Practical/
          // Unreliable de la MEME piece (peuvent cohabiter parmi ses qualites de catalogue
          // et de fabrication, cf. PersonnageArmureQualitesPortees).
          SousTotalPiece     := 0;
          PieceEstPractical  := False;
          PieceEstUnreliable := False;
          for IndModif := 0 to Length(QualitesPortees) - 1 do
            if QualitesPortees[IndModif].CodeEquipement = Piece then
              begin
                if FabricationEstPractical(QualitesPortees[IndModif].CodeQualite) then
                  PieceEstPractical := True;
                if FabricationEstUnreliable(QualitesPortees[IndModif].CodeQualite) then
                  PieceEstUnreliable := True;
              end;
          for IndModif := 0 to Length(QualitesPortees) - 1 do
            if QualitesPortees[IndModif].CodeEquipement = Piece then
              For IndListe := 0 to (ListModificateur.Count - 1) do
                if EntreeCompetenceEquip(ListModificateur[IndListe])
                   and CompareRechercheValeur(ListModificateur[IndListe].CodeSource, QualitesPortees[IndModif].CodeQualite)
                   and CompareRechercheValeur(ListModificateur[IndListe].Cible, CodeCompetence) then
                  SousTotalPiece := SousTotalPiece + ListModificateur[IndListe].Facteur;

          // Practical/Unreliable ne modulent que des PENALITES (Rulebook : "penalties for
          // wearing it are reduced"/"penalties ... are doubled"), jamais un bonus.
          if SousTotalPiece < 0 then
            begin
              if PieceEstPractical then
                begin
                  SousTotalPiece := SousTotalPiece + 10;
                  if SousTotalPiece > 0 then
                    SousTotalPiece := 0;
                end;
              // Ordre Practical puis Unreliable arbitraire si une piece cumulait les deux (cas
              // non couvert par le Rulebook, non rencontre dans les livres actuels).
              if PieceEstUnreliable then
                SousTotalPiece := SousTotalPiece * 2;
            end;

          Result := Result + SousTotalPiece;
        end;
    finally
      PiecesTraitees.Free;
    end;
  end;

Function PersonnageArmureBonusAttributModif(Personnage: StructurePersonnage; CodeAttribut: String): Integer;
  begin
    Result := PersonnageArmureBonusModificateur(Personnage, ConstXmlModifieAttribut, CodeAttribut);
  end;

Function PersonnageArmureBonusModificateur(Personnage: StructurePersonnage; TypeModif, Cible: String; Filtre: String = ''): Integer;
  var
    Qualites: TStringList;
    Ind:      Integer;
    IndModif: Integer;
  begin
    Result   := 0;
    Qualites := PersonnageArmureQualites(Personnage);
    try
      for Ind := 0 to Qualites.Count - 1 do
        for IndModif := 0 to (ListModificateur.Count - 1) do
          if (ListModificateur[IndModif].TypeSource = SourceModifArmureBonus)
             and (ListModificateur[IndModif].TypeModif = TypeModif)
             and CompareRechercheValeur(ListModificateur[IndModif].CodeSource, Qualites[Ind])
             and CompareRechercheValeur(ListModificateur[IndModif].Cible, Cible)
             and ((Trim(ListModificateur[IndModif].Filtre) = '')
                  or CompareRechercheValeur(ListModificateur[IndModif].Filtre, Filtre)) then
            Result := Result + ListModificateur[IndModif].Facteur;
    finally
      Qualites.Free;
    end;
  end;

Function PersonnageMutationCompetenceModif(Personnage: StructurePersonnage; CodeCompetence: String): Integer;
  var
    PersonnageMutation: StructurePersonnageMutation;
    indiceModif:        Integer;
    PCompetence:        StructureCompetence;
    PGenerique:         StructureCompetence;
    CodeGenerique:      String;
    AttributCompetence: String;
  begin
    Result        := 0;
    // Certains effets de mutation visent une FAMILLE de compétences (ex. "-10 to all Language
    // Tests", CORPHY_013) plutôt qu'une compétence précise - même mécanisme que les sous-
    // compétences ailleurs (ex. PdfPersonnageCompetence) : si CodeCompetence est une sous-
    // compétence (ex. RULES-COMPLANG_BRET), on teste aussi sa forme générique (COMPLANG_*).
    CodeGenerique := '';
    PCompetence   := ChercheCompetence(CodeCompetence);
    if PCompetence.SousCompetence then
      begin
        // Lien explicite (CONTEXT.md 2.67), remplace la recherche par radical utilisee avant
        // que le champ <Generique> existe : la specialisation et son entree generique peuvent
        // venir de deux livres differents (ex. LUSTR-COMPPROJ_SARBAC specialise
        // RULES-COMPPROJ_*), et ChercheCompetence/CompareRechercheValeur plus bas exigent le
        // MEME livre pour matcher. Repli sur l'ancienne recherche par radical si le champ n'est
        // pas renseigne (donnee pas encore migree, ou specialisation sans generique identifiee).
        if PCompetence.CodeGenerique <> '' then
          CodeGenerique := PCompetence.CodeGenerique
        else
          begin
            CodeGenerique := CodeGeneriqueDeduit(PCompetence.CodeCompetence);
            for PGenerique in ListCompetence do
              if CodeSansLivre(PGenerique.CodeCompetence) = CodeSansLivre(CodeGenerique) then
                begin
                  CodeGenerique := PGenerique.CodeCompetence;
                  break;
                end;
          end;
      end;
    // Une sous-compétence (ex. RULES-COMPLANG_BRET) n'a pas son propre <Attribut> dans le XML,
    // seule l'entrée générique (RULES-COMPLANG_*) l'a - on va le chercher là si besoin.
    AttributCompetence := PCompetence.CodeAttribut;
    if (AttributCompetence = '') and (CodeGenerique <> '') then
      AttributCompetence := ChercheCompetence(CodeGenerique).CodeAttribut;
    for PersonnageMutation in Personnage.Mutations do
      for indiceModif := 0 to (ListModificateur.Count - 1) do
        if (ListModificateur[indiceModif].TypeSource = SourceModifMutation)
           and (ListModificateur[indiceModif].TypeModif = ConstXmlModifieCompetence)
           and CompareRechercheValeur(ListModificateur[indiceModif].CodeSource, PersonnageMutation.Code)
           and (CompareRechercheValeur(ListModificateur[indiceModif].Cible, CodeCompetence)
                or ((CodeGenerique <> '') and CompareRechercheValeur(ListModificateur[indiceModif].Cible, CodeGenerique))) then
          Result := Result + ListModificateur[indiceModif].Facteur;

    // Effets visant TOUTES les compétences d'un attribut de rattachement (ex. "-20 to all
    // Fellowship Tests", CORPHY_011) - sans toucher l'attribut lui-même (CONTEXT.md §2.7,
    // étape 8). <ModifySkillAttribut>, liste et comparaison séparées de celles ci-dessus.
    for PersonnageMutation in Personnage.Mutations do
      for indiceModif := 0 to (ListCorruptionCompetenceAttributModif.Count - 1) do
        if CompareRechercheValeur(ListCorruptionCompetenceAttributModif[indiceModif].CodeCorruption, PersonnageMutation.Code)
           and (AttributCompetence <> '')
           and CompareRechercheValeur(ListCorruptionCompetenceAttributModif[indiceModif].CodeAttribut, AttributCompetence) then
          Result := Result + ListCorruptionCompetenceAttributModif[indiceModif].Valeur;
  end;

Function PersonnageMutationArmureModif(Personnage: StructurePersonnage; CodeLocalisation: String): Integer;
  // Effets de mutation donnant des Points d'Armure (ex. "+2 Armour Points to all locations",
  // CORPHY_012/016/017, CONTEXT.md §2.7, étape 8) - PDF uniquement, réutilise les 4
  // emplacements de l'armure portée (BonusTete/BonusBras/BonusCorps/BonusJambes).
  begin
    Result := PersonnageMutationModificateur(Personnage, ConstXmlModifieArmure, CodeLocalisation);
  end;

Function PersonnageMutationTalent(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  var
    PersonnageMutation: StructurePersonnageMutation;
    indiceModif:        Integer;
    PTalent:             StructurePersonnageTalent;
    PCorruptionTable:    StructureCorruptionTable;
    TotalPeur:           Integer;
    Peur:                Integer;
  begin
    Result    := [];
    TotalPeur := 0;
    for PersonnageMutation in Personnage.Mutations do
      begin
        for indiceModif := 0 to (ListCorruptionTalent.Count - 1) do
          if CompareRechercheValeur(ListCorruptionTalent[indiceModif].CodeCorruption, PersonnageMutation.Code) then
            begin
              PTalent.CodeTalent := ListCorruptionTalent[indiceModif].CodeTalent;
              PTalent.Valeur     := 1;
              PTalent.Asterisque := 0;
              PTalent.Source     := PersonnageMutation.Code;
              Result             += [PTalent];
            end;
        // Points de peur du Tome of Corruption (p.26) : somme des mutations du Chaos ; seuls les
        // entiers simples comptent ("Varies", "0-1", "1/2/3" restent a l'appreciation du MJ).
        for PCorruptionTable in ListCorruptionTable do
          if (PCorruptionTable.TypeCorruption = CorruptionMutation)
             and (PCorruptionTable.Code = PersonnageMutation.Code)
             and TryStrToInt(PCorruptionTable.Peur, Peur) and (Peur > 0) then
            TotalPeur += Peur;
      end;
    // 1 Menacing, 2 a 4 Unsettling, 5 a 9 Frightening, 10 et plus Terrifying : le plus haut remplace les autres.
    PTalent.CodeTalent := '';
    if TotalPeur >= 10 then PTalent.CodeTalent := 'RULES-T_TERRIFYING'
    else if TotalPeur >= 5 then PTalent.CodeTalent := 'RULES-T_FRIGHTENING'
    else if TotalPeur >= 2 then PTalent.CodeTalent := 'RULES-T_UNSETTLING'
    else if TotalPeur = 1 then PTalent.CodeTalent := 'RULES-T_MENACING';
    if PTalent.CodeTalent <> '' then
      begin
        PTalent.Valeur     := 1;
        PTalent.Asterisque := 0;
        PTalent.Source     := CorruptionMutation;
        Result             += [PTalent];
      end;
    // Option Momentum : ces talents sont calcules, pas stockes, donc suivent la version choisie ici
    if (Pos(AjouteAccolade(ConstXmlOptionMomentum), Personnage.Options) > 0) and LivreMomentumCharge() and VerifieFiltre(ConstFiltreLivreMomentum,Personnage.LivresAcceptes) then
      for indiceModif := 0 to High(Result) do
        Result[indiceModif].CodeTalent := CodeTalentVersion(Result[indiceModif].CodeTalent, True);
  end;

Function PersonnageTalentEstBarre(Personnage: StructurePersonnage; CodeTalent: String): Boolean;
  var
    Ind: Integer;
  begin
    Result := false;
    for Ind := 0 to High(Personnage.TalentCarriereRequise) do
      if Personnage.TalentCarriereRequise[Ind].CodeTalent = CodeTalent then
        begin
          Result := (Personnage.MetierEnCours.CodeMetier <> Personnage.TalentCarriereRequise[Ind].CodeMetier) or
                     (Personnage.MetierEnCours.NiveauMetier <> Personnage.TalentCarriereRequise[Ind].NiveauMetier);
          break;
        end;
  end;

Function PersonnageMutationEquipement(Personnage: StructurePersonnage): TArrayPersonnageEquipement;
  var
    PersonnageMutation:  StructurePersonnageMutation;
    indiceModif:         Integer;
    PEquipement:          StructurePersonnageEquipement;
  begin
    Result := [];
    for PersonnageMutation in Personnage.Mutations do
      for indiceModif := 0 to (ListCorruptionEquipement.Count - 1) do
        if CompareRechercheValeur(ListCorruptionEquipement[indiceModif].CodeCorruption, PersonnageMutation.Code) then
          begin
            if ListCorruptionEquipement[indiceModif].EstArme then
              PEquipement.TypeEquipement := TypeEquipWe
            else
              PEquipement.TypeEquipement := TypeEquipAr;
            PEquipement.CodeEquipement    := ListCorruptionEquipement[indiceModif].CodeEquipement;
            PEquipement.QualiteEquipement := '';
            PEquipement.CoutXp            := 0;
            PEquipement.Source            := PersonnageMutation.Code;
            // Une arme/armure de mutation fait partie du corps, ne se retire pas comme un
            // achat normal : toujours consideree portee. A confirmer si un cas reel contredit
            // cette hypothese.
            PEquipement.Porte             := True;
            PEquipement.Quantite          := 1;
            Result                        += [PEquipement];
          end;
  end;

Function PersonnageAccessoireEquipement(Personnage: StructurePersonnage): TArrayPersonnageEquipement;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    PEquipement:          StructurePersonnageEquipement;
    Liste:                TStringList;
    Ind:                  Integer;
  begin
    Result := [];
    for PersonnageEquipement in Personnage.Equipement do
      if (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe)) and
         (PersonnageEquipement.QualiteEquipement <> '') then
        begin
          Liste := TStringList.Create;
          try
            // une entree par accessoire : "CODE niveau,CODE niveau" -> on garde le code de fabrication
            ExtractStrings([','], [], PChar(PersonnageEquipement.QualiteEquipement), Liste);
            for Ind := 0 to Liste.Count - 1 do
              if ChercheFabrication(ExtractStringBefore(Liste[Ind], ' ')).ArmeAlternative <> '' then
                begin
                  PEquipement                   := PersonnageEquipement;
                  PEquipement.CodeEquipement    := ChercheFabrication(ExtractStringBefore(Liste[Ind], ' ')).ArmeAlternative;
                  PEquipement.QualiteEquipement := '';
                  PEquipement.CoutXp            := 0;
                  PEquipement.Source            := '@' + ExtractStringBefore(Liste[Ind], ' ');
                  PEquipement.Quantite          := 1;
                  PEquipement.IdInstance        := '';
                  Result                        += [PEquipement];
                end;
          finally
            Liste.Free;
          end;
        end;
  end;

Function EquipementAlternatifFabrication(PEquipement: StructurePersonnageEquipement): String;
  begin
    if (Length(PEquipement.Source) > 1) and (PEquipement.Source[1] = '@') then
      Result := Copy(PEquipement.Source, 2, Length(PEquipement.Source))
    else
      Result := '';
  end;

Function PersonnageArmureBonusTalent(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    indiceModif:          Integer;
    PTalent:              StructurePersonnageTalent;
    Liste:                TStringList;
    Alternatives:         TStringList;
    Element:              String;
    Code:                 String;
    Ind, IndAlt:          Integer;
    ListeQualites:        String;
  begin
    Result       := [];
    Liste        := TStringList.Create;
    Alternatives := TStringList.Create;
    try
      for PersonnageEquipement in Personnage.Equipement do
        if ((TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAr))
            or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipArS)))
           and EquipementCompte(PersonnageEquipement) then
          begin
            // Les qualites d'un objet vivent a deux endroits : celles du catalogue
            // (StructureArmure/StructureArmureSimplifiee.ListeBonus, ex. NATIO-ARMOB_16 sur
            // Skull Trophies - c'est CE champ que "Fear 1" affiche sur la fiche, chargearmure.pas)
            // et celles ajoutees par le joueur en fabrication (PersonnageEquipement.QualiteEquipement,
            // TabEquipement colonne Fabrication, winpersonnage.pas). Les deux sont scannees, au cas
            // ou une qualite de fabrication accorderait un jour un talent elle aussi.
            if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAr) then
              ListeQualites := ChercheArmure(PersonnageEquipement.CodeEquipement).ListeBonus
            else
              ListeQualites := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement).ListeBonus;
            if PersonnageEquipement.QualiteEquipement <> '' then
              begin
                if ListeQualites <> '' then
                  ListeQualites := ListeQualites + ',';
                ListeQualites := ListeQualites + PersonnageEquipement.QualiteEquipement;
              end;

            // Meme decoupage que GetAllArmureBonusLibelle (chargearmurebonus.pas) : virgules
            // entre qualites, suffixe numerique separe par un espace (ignore ici, seul le code
            // importe pour l'octroi), alternatives separees par SeparateurMulti.
            Liste.Clear;
            ExtractStrings([','], [], PChar(ListeQualites), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                if Pos(' ', Element) > 0 then
                  Element := Trim(ExtractStringBefore(Element, ' '));

                Alternatives.Clear;
                ExtractStrings([SeparateurMulti], [], PChar(Element), Alternatives);
                for IndAlt := 0 to Alternatives.Count - 1 do
                  begin
                    Code := Trim(Alternatives[IndAlt]);
                    for indiceModif := 0 to (ListArmureBonusTalent.Count - 1) do
                      if CompareRechercheValeur(ListArmureBonusTalent[indiceModif].CodeArmureBonus, Code) then
                        begin
                          PTalent.CodeTalent := ListArmureBonusTalent[indiceModif].CodeTalent;
                          PTalent.Valeur     := 1;
                          PTalent.Asterisque := 0;
                          PTalent.Source     := PersonnageEquipement.CodeEquipement;
                          Result             += [PTalent];
                        end;
                  end;
              end;
          end;
    finally
      Alternatives.Free;
      Liste.Free;
    end;
  end;

Function PersonnageArmeBonusTalent(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    indiceModif:          Integer;
    PTalent:              StructurePersonnageTalent;
    Liste:                TStringList;
    Alternatives:         TStringList;
    Element:              String;
    Code:                 String;
    Ind, IndAlt:          Integer;
    ListeQualites:        String;
  begin
    Result       := [];
    Liste        := TStringList.Create;
    Alternatives := TStringList.Create;
    try
      for PersonnageEquipement in Personnage.Equipement do
        if ((TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe))
            // Objet generique (DATA_TRAPPING : anneau, amulette...) : seulement la fabrication.
            // Ex. Seed of Rebirth -> trait Regenerate (RULES-T0REG). 30/09/2026.
            or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipDI)))
           and EquipementCompte(PersonnageEquipement) then
          begin
            // Meme double source que PersonnageArmureBonusTalent : qualites du catalogue
            // (StructureArme.ListeBonus) et qualites de fabrication ajoutees par le joueur
            // (PersonnageEquipement.QualiteEquipement).
            if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe) then
              ListeQualites := ChercheArme(PersonnageEquipement.CodeEquipement).ListeBonus
            else
              ListeQualites := '';
            if PersonnageEquipement.QualiteEquipement <> '' then
              begin
                if ListeQualites <> '' then
                  ListeQualites := ListeQualites + ',';
                ListeQualites := ListeQualites + PersonnageEquipement.QualiteEquipement;
              end;

            // Meme decoupage que GetAllArmeBonusLibelle (chargearmebonus.pas) : virgules entre
            // qualites, suffixe numerique separe par un espace (ignore ici, seul le code
            // importe pour l'octroi), alternatives separees par SeparateurMulti.
            Liste.Clear;
            ExtractStrings([','], [], PChar(ListeQualites), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                if Pos(' ', Element) > 0 then
                  Element := Trim(ExtractStringBefore(Element, ' '));

                Alternatives.Clear;
                ExtractStrings([SeparateurMulti], [], PChar(Element), Alternatives);
                for IndAlt := 0 to Alternatives.Count - 1 do
                  begin
                    Code := Trim(Alternatives[IndAlt]);
                    for indiceModif := 0 to (ListArmeBonusTalent.Count - 1) do
                      if CompareRechercheValeur(ListArmeBonusTalent[indiceModif].CodeArmeBonus, Code) then
                        begin
                          PTalent.CodeTalent := ListArmeBonusTalent[indiceModif].CodeTalent;
                          PTalent.Valeur     := 1;
                          PTalent.Asterisque := 0;
                          PTalent.Source     := PersonnageEquipement.CodeEquipement;
                          Result             += [PTalent];
                        end;
                  end;
              end;
          end;
    finally
      Alternatives.Free;
      Liste.Free;
    end;
  end;

// Radical d'un talent a specialisation : voir RadicalTalent dans chargetalent.pas (le code de sa
// famille sans '_*', RULES-T_BLESS_SIGMAR -> RULES-T_BLESS ; un talent sans famille est son propre radical).

// Le talent de carriere peut etre un CHOIX "A/B" (RULES-T0161/NATIO-T0015_*) : chaque branche
// est testee, avec les deux regles habituelles (meme code, ou meme radical).
Function TalentCarriereCorrespond(CodeCarriere, CodeLigne: String): Boolean;
  var
    Branches: TStringList;
    IndBr:    Integer;
  begin
    Result := False;
    Branches := TStringList.Create;
    try
      Branches.StrictDelimiter := True;
      Branches.Delimiter       := SeparateurMulti;
      Branches.DelimitedText   := CodeCarriere;
      for IndBr := 0 to Branches.Count - 1 do
        if MemeTalent(Branches[IndBr], CodeLigne)
           or MemeTalent(RadicalTalent(Branches[IndBr]), RadicalTalent(CodeLigne)) then
          begin
            Result := True;
            Break;
          end;
    finally
      Branches.Free;
    end;
  end;

Function PersonnageTalentNiveauMetier(const Personnage: StructurePersonnage; CodeTalent: String): Integer;
  var
    PMetierTalent: StructureMetierTalent;
    CodeMetier:    String;
  begin
    Result     := -1;
    CodeMetier := Personnage.MetierEnCours.CodeMetier;
    for PMetierTalent in ListMetierTalent do
      if CompareRechercheValeur(PMetierTalent.CodeMetier, CodeMetier) then
        // Adapting Careers : le talent substitue remplace le code brut de la carriere.
        if TalentCarriereCorrespond(AdapterElement(CodeMetier, Personnage.Race, Personnage.ChoixAdaptation,
                                    PMetierTalent.NiveauMetier, ConstXmlTalent, PMetierTalent.CodeTalent),
                                    CodeTalent) then
          begin
            Result := PMetierTalent.NiveauMetier;
            Break;
          end;
  end;

// Tous les talents accordes automatiquement (mutation, qualite d'armure, qualite d'arme ou
// d'objet). Construit element par element : la concatenation directe des trois tableaux dans un
// for..in (A() + B() + C()) faisait planter l'ecran WinPersonnage (ACCESS VIOLATION dans
// System.Move) des qu'un personnage avait des talents accordes, ex. Charlatant chanceux.
Function PersonnageTalentsOctroyes(Personnage: StructurePersonnage): TArrayPersonnageTalent;
  var
    Liste:  TArrayPersonnageTalent;
    Talent: StructurePersonnageTalent;
    Nb:     Integer;

  procedure Ajouter;
    begin
      for Talent in Liste do
        begin
          SetLength(Result, Nb + 1);
          Result[Nb] := Talent;
          Inc(Nb);
        end;
    end;

  begin
    Result := nil;
    Nb     := 0;
    Liste := PersonnageMutationTalent(Personnage);
    Ajouter;
    Liste := PersonnageArmureBonusTalent(Personnage);
    Ajouter;
    Liste := PersonnageArmeBonusTalent(Personnage);
    Ajouter;
  end;

Function PersonnageTalentArmureModif(Personnage: StructurePersonnage; CodeLocalisation: String): Integer;
  // Talents donnant des Points d'Armure - meme principe que PersonnageMutationArmureModif
  // juste au-dessus, mais la source est un talent du personnage au lieu d'une mutation.
  // Premier usage : le trait Armour (Rating) (RULES-T0ARM), que le Skink porte en
  // "Armour 1 (Scaly Skin)". CONTEXT.md 2.15. Migre sur le moteur generique le 11/09/2026
  // (meme pathway que ModifyWeapon/ModifyDamage) - l'ancienne liste dediee
  // ListTalentArmureModif et son unite ChargeTalentArmureModif sont retirees.
  begin
    Result := PersonnageTalentModificateur(Personnage, ConstXmlModifieArmure, CodeLocalisation);
  end;

end.



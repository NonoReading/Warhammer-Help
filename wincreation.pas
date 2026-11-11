unit WinCreation;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}
interface

uses
  PdfUtils,
  Classes, SysUtils, StrUtils, Math, Forms, Controls, Graphics, Dialogs, MessageTest, ExtCtrls, Grids,
  ComCtrls, StdCtrls, CheckLst, Spin, Buttons, GuideAide, ChargeConstantes,ChargeEspece, GlobalFonts, ChargeRace,
  ChargeRegle, ChargeTirageMetier, ChargeSigneAstral, WinOptionRegle,
  Types, ChargeMetier, ChargeAttribut, ChargeRaceAttribut, ChargeMetierNiveau,
  ChargeMetierAttribut, UnitCalcul, ChargeRaceTalent, ChargeTalent,
  ChargeTalentCreation, ChargeRaceCompetence, ChargeCompetence, ChargeRaceCreation,
  ChargeMetierCompetence, ChargeArme, ChargeArmure, ChargeTrapping, ChargeMetierEquipement, ChargeClassEquipement, ChargeFabrication,
  WinMetier, WinRaces, ChargeTexte, WinTalent, WinCompetence, ChargeLivre,
  ChargeMetierSousMetier, ChargeMetierRaceChoixMetier, WinSpecialisation,
  ChargeMetierTalent, ChargePersonnage, WinJetPathologie, BGRABitmap, BGRABitmapTypes, BCButton,
  BCLabel, WinLanceDe, WinPhysique, ChargeRacePhysique, BCLabelContour, Menus, WinMutation, CreationV1, FenetreApprentissageV1;

type
  { TWinCreations }
  TWinCreations = class(TForm)
    AffMetierSousMetier: TMemo;
    MemoMetierRegles: TMemo;
    ButtonAttributHasard: TBCButton;
    ButtonLibellePhase: TBCButton;
    ButtonMetierCompetenceHasard: TBCButton;
    ButtonMetierEquipementHasard: TBCButton;
    ButtonNomHasard: TBCButton;
    ButtonMetierHasard: TBCButton;
    ButtonMetierSelectionner: TBCButton;
    ButtonMetierSousMetierSelectionner: TBCButton;
    ButtonMetierSousMetierValider: TBCButton;
    ButtonMetierValider: TBCButton;
    ButtonPhaseSuivante: TBCButton;
    ButtonRaceCompetenceHasard: TBCButton;
    ButtonRaceHasard: TBCButton;
    ButtonRaceSelectionner: TBCButton;
    ButtonRaceValider: TBCButton;
    ButtonTalentHasard: TBCButton;
    ButtonTotalMetierCompetence: TButton;
    ComboBoxRegle: TComboBox;
    ComboRaceCreation: TComboBox;
    EditMetierResultat: TSpinEdit;
    EditMetierSousMetierResultat: TSpinEdit;
    EditNomPersonnag: TEdit;
    ButtonPhysique: TBCButton;
    ButtonNom: TBCButton;
    LabSigne: TEdit;
    ComboBoxSigne: TComboBox;
    ButtonSigne: TBCButton;
    ButtonSigneSpe: TButton;
    MemoSigne: TMemo;
    ComboBoxSexeNom: TComboBox;
    CheckBoxNoble: TCheckBox;
    LabNoble: TEdit;
    ComboBoxRegleNom: TComboBox;
    // Phase 2.3 : formes (7-1), animaux (7-3) et particularites (7-2) coches ; le tirage coche, la main decoche
    ClbFamilierForme, ClbFamilierAnimal, ClbFamilierParticularite: TCheckListBox;
    CodesRegleNom: TStringList;   // code de la regle de chaque item du combo (0 = aucune)
    LabPhysiqueResume: TEdit;
    EditRaceResultat: TSpinEdit;
    GroupBoxAttribut: TGroupBox;
    GroupBoxMetier: TGroupBox;
    GroupBoxRegle: TGroupBox;
    GroupBoxRace: TGroupBox;
    ImageScroll: TImage;
    LabDestin: TEdit;
    LabelAttribut: TBCLabelContour;
    LabelCompetence: TBCLabelContour;
    LabelMetier: TBCLabelContour;
    LabelRace: TBCLabelContour;
    LabelTalent: TBCLabelContour;
    LabLivre: TEdit;
    LabNomPersonnage: TEdit;
    LabPointSupp: TEdit;
    LabRegle: TEdit;
    LabResilience: TEdit;
    LibMetier: TEdit;
    LibRace: TEdit;
    ImageRace1: TImage;
    ImageRace2: TImage;
    ImageMetier: TImage;
    ImageWar: TImage;
    PageEtapes: TPageControl;
    RadioButtonAttributHasard: TRadioButton;
    RadioButtonAttributHasardAffecte: TRadioButton;
    RadioButtonAttributResultat: TRadioButton;
    RadioButtonAttributRepartition: TRadioButton;
    RadioButtonAttributResultatAffecte: TRadioButton;
    RadioButtonMetierChoix: TRadioButton;
    RadioButtonMetierHasard: TRadioButton;
    RadioButtonMetierResultat: TRadioButton;
    RadioButtonRaceChoix: TRadioButton;
    RadioButtonRaceHasard: TRadioButton;
    RadioButtonRaceResultat: TRadioButton;
    RecapTalent: TStringGrid;
    RecapComp: TStringGrid;
    RecapAttribut: TStringGrid;
    TabCreationChoix: TStringGrid;
    TabAttribut: TStringGrid;
    TabAttributLanceDe: TStringGrid;
    TabCreationHasard: TStringGrid;
    TabLivre: TStringGrid;
    PanneauRegles: TPanelOptionRegle;
    TabMetier: TStringGrid;
    TabMetierCompetence: TStringGrid;
    TabMetierEquipement: TStringGrid;
    TabRace: TStringGrid;
    TabRaceCompetence: TStringGrid;
    TabSheetAttribut: TTabSheet;
    TabSheetCompMetier: TTabSheet;
    TabSheetCompRace: TTabSheet;
    TabSheetEquipement: TTabSheet;
    TabSheetLivre: TTabSheet;
    TabSheetMetier: TTabSheet;
    TabSheetNom: TTabSheet;
    TabSheetClan: TTabSheet;
    LabClanTexte: TLabel;
    TabClan: TStringGrid;
    ButtonClanHasard: TBCButton;
    EditClanJet: TEdit;
    TabSheetMutation: TTabSheet;
    LabMutationTexte: TLabel;
    LabMutationChoisie: TLabel;
    ButtonMutationChoix: TBCButton;
    TabSheetFamilier: TTabSheet;
    LabFamilierTexte: TLabel;
    LabFamilierChoisi: TLabel;
    ButtonFamilierHasard: TBCButton;
    TabSheetSigne: TTabSheet;
    TabSheetAppartenance: TTabSheet;
    LabAppartenanceTexte: TLabel;
    LabAppartenanceChoisie: TLabel;
    ButtonAppartenanceChoix: TBCButton;
    TabSheetRace: TTabSheet;
    TabSheetTalent: TTabSheet;
    TabTalent: TStringGrid;
    TrackBarPointSupp: TTrackBar;

    // générales
    procedure ButtonMetierSelectionnerClick({%H-}Sender: TObject);
    procedure ButtonMetierSousMetierSelectionnerClick({%H-}Sender: TObject);
    procedure ButtonMetierSousMetierValiderClick({%H-}Sender: TObject);
    procedure ButtonRaceSelectionnerClick({%H-}Sender: TObject);
    procedure ButtonTalentHasardClick(Sender: TObject);
    procedure ComboRaceCreationSelect({%H-}Sender: TObject);
    procedure FormCloseQuery({%H-}Sender: TObject; var {%H-}CanClose: Boolean);
    procedure FormCreate({%H-}Sender: TObject);
    procedure ChargerImage();
    Procedure ChargeImageNiveau(Niveau: Integer);
    Procedure ChargeImagesNiveau();
    procedure LibMetierDblClick({%H-}Sender: TObject);
    procedure LibRaceDblClick({%H-}Sender: TObject);
    procedure RecapAttributSelectEditor({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure RecapCompDblClick({%H-}Sender: TObject);
    procedure RecapCompSelectEditor({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure RecapTalentDblClick({%H-}Sender: TObject);
    procedure RecapTalentSelectEditor({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure TabCreationChoixDblClick(Sender: TObject);
    procedure TabCreationChoixPrepareCanvas(Sender: TObject; aCol,
      aRow: Integer; aState: TGridDrawState);
    procedure TabCreationHasardDblClick(Sender: TObject);
    procedure TabCreationHasardPrepareCanvas(Sender: TObject; aCol,
      aRow: Integer; aState: TGridDrawState);
    procedure TabLivreDblClick({%H-}Sender: TObject);
    procedure ReglesChangees(Sender: TObject);
    procedure TabMetierCompetenceDblClick({%H-}Sender: TObject);
    procedure TabMetierEquipementDblClick({%H-}Sender: TObject);
    procedure TabRaceCompetenceDblClick({%H-}Sender: TObject);
    procedure TabTalentDblClick({%H-}Sender: TObject);
    Procedure TalentFenetre(Choix: Integer; CodeTalent: String);
    Procedure CompetenceFenetre(CodeCompetence: String);
    Procedure RaceFenetre(CodeRace: String);
    Procedure MetierFenetre(CodeMetier: String);
    procedure ChargerLivre();
    Procedure ReconstruitChoixCreation();
    Procedure AfficheChoixCreation();

    // Phases
    procedure ButtonPhaseSuivanteClick({%H-}Sender: TObject);
    procedure ButtonPhysiqueClick({%H-}Sender: TObject);
    procedure ButtonNomClick({%H-}Sender: TObject);
    procedure ButtonNomHasardClick({%H-}Sender: TObject);
    procedure ChargeReglesNom();
    procedure TabSheetNomShow({%H-}Sender: TObject);
    procedure ButtonSigneClick({%H-}Sender: TObject);
    procedure ButtonSigneSpeClick({%H-}Sender: TObject);
    procedure MajTexteSigne();
    Function TalentMaxCreation(CodeTalent: String): Integer;
    procedure AjouteTalentSigne();
    // Phase intermediaire 2.1 (V2) : clan de naissance d'une race qui en declare (Skaven)
    procedure RemplirGridClan();
    procedure TabClanClick({%H-}Sender: TObject);
    procedure ButtonClanHasardClick({%H-}Sender: TObject);
    procedure EditClanJetChange({%H-}Sender: TObject);
    procedure SelectionneClan(const Clan: String);
    procedure AjouteEffetsClan();
    procedure AjouteEffetsFamilier();
    procedure AppliqueEffetsListe(Liste: String);
    // Phase intermediaire 2.2 (V2) : mutation de depart d'une race qui en declare (Mutant)
    procedure AfficheSeulOnglet(Onglet: TTabSheet; Suffixe, Titre: String);
    procedure AfficheSousPhaseClan();
    procedure AfficheSousPhaseMutation();
    // Phase intermediaire 3.0 (V2) : chance de mutation de depart d'une regle (balise StartingMutation de la regle),
    // proposee apres le metier ; le joueur lance le d100 ou passe a l'etape suivante
    function  ChanceMutationRegle(): Integer;
    procedure AfficheSousPhaseMutationChance();
    procedure RetireMutationChance();
    // Phase intermediaire 2.3 (V2) : forme et particularites d'un familier cree
    procedure AfficheSousPhaseFamilier();
    procedure ClbFamilierClickCheck(Sender: TObject);
    procedure MajFamilierDepuisCoches();
    procedure CocheFamilier(Liste: TCheckListBox; const Nom: String);
    procedure ButtonFamilierHasardClick({%H-}Sender: TObject);
    procedure AfficheSousPhaseSigne();
    procedure MajRecapAttribut();
    procedure AfficheSousPhaseAppartenance();
    procedure ButtonAppartenanceChoixClick({%H-}Sender: TObject);
    procedure MajLibelleAppartenance();
    procedure ChoisitAppartenance();
    procedure AcquiertCompetencesAppartenanceV2();
    procedure ButtonMutationChoixClick({%H-}Sender: TObject);
    procedure ComboBoxSigneSelect({%H-}Sender: TObject);
    procedure ChargeSignesAstraux();
    procedure AppliqueSigneAstral(Indice: Integer);
    procedure ChangementPhase(Changement: Integer);
    Function PageEtapesChange(): boolean;
    Procedure PhaseSave(NouvellePhase: Integer);

    // XML
    function XmlCalculXp(): Integer;

    // Race
    procedure ChargeTabRaces(Livre: String='');
    procedure TabRaceDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; {%H-}aState: TGridDrawState);
    procedure TabRacePrepareCanvas({%H-}Sender: TObject; {%H-}aCol, aRow: Integer;
      {%H-}aState: TGridDrawState);
    procedure TrackBarPointSuppChange({%H-}Sender: TObject);
    procedure UpdateSheetMetier(Hasard: Boolean);
    procedure AfficheImageRace();
    procedure RemplitTalentsRace();
    procedure ButtonRaceHasardClick({%H-}Sender: TObject);
    procedure ButtonRaceValiderClick({%H-}Sender: TObject);
    procedure RadioButtonRaceHasardClick({%H-}Sender: TObject);
    procedure RadioButtonRaceClick({%H-}Sender: TObject);
    procedure TabRaceResultat(Resul: Integer);
    // Guide du joueur (GuideAide.pas) : boutons Aide (etape affichee) et ? Question
    procedure ButtonGuideClick({%H-}Sender: TObject);
    procedure ButtonQuestionClick({%H-}Sender: TObject);

    // Métier
    procedure ChargeTabMetier();
    procedure ChargeComboRegle();
    procedure ComboBoxRegleSelect({%H-}Sender: TObject);
    function  RegleEnCours(): String;
    procedure TabMetierDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; {%H-}aState: TGridDrawState);
    procedure TabMetierPrepareCanvas({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
      {%H-}aState: TGridDrawState);
    procedure UpdateSheetRace(Hasard: Boolean);
    procedure AfficheImageMetier();
    procedure ButtonMetierHasardClick({%H-}Sender: TObject);
    procedure ButtonMetierValiderClick({%H-}Sender: TObject);
    procedure RadioButtonMetierHasardClick({%H-}Sender: TObject);
    procedure RadioButtonMetierClick({%H-}Sender: TObject);
    procedure TabMetierResultat(Resul: Integer);
    procedure AfficheMetierAutresRegles(Resul: Integer; CodeMetier: String);

    // Attributs
    procedure ChargeTabAttribut();
    procedure TabAttributDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure TabAttributSelectEditor({%H-}Sender: TObject; aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure ButtonAttributHasardClick({%H-}Sender: TObject);
    procedure ButtonClemenceClick({%H-}Sender: TObject);
    procedure ClemenceChoisie(Sender: TObject);
    procedure GridAvanceDblClick({%H-}Sender: TObject);
    procedure RemplirGridAvance();
    procedure AfficheAvanceGratuiteV1();
    procedure GridRaceDblClick({%H-}Sender: TObject);
    procedure RemplirGridRace();
    function  AvancesGratuitesPossibles(): TStringList;
    function  NbAvancesGratuites(): Integer;
    procedure UpdateSheetAttribut(Hasard: boolean);
    Procedure CalculTabAttribut(Hasard: Boolean; Affectation: Boolean);
    procedure TabAttributLanceDeEditingDone({%H-}Sender: TObject);
    procedure TabAttributLanceDeSelectCell({%H-}Sender: TObject; aCol,
      aRow: Integer; var CanSelect: Boolean);
    procedure RadioButtonAttributClick({%H-}Sender: TObject);
    procedure ComboBoxSelectAttribut(Sender: TObject);
    procedure TabAttributLanceDeSetEditText({%H-}Sender: TObject; {%H-}ACol, ARow: Integer;
      const {%H-}Value: string);
    procedure TabAttributLanceDeClickCombo();
    function RepartitionMax(): Integer;

    // Talent
    //function TalentTest(Num: Integer; Code: String; Hasard: Boolean): Boolean;
    Function LibelleChoixMultiple(Code: String): String;
    Function ChoixCreationComplet(): Boolean;
    Function RangSuivant(Source, ParentLigne: String): Integer;
    Function ListeTalentsDejaPris(Exclu: String): TStringList;
    Procedure AjouteTalentsResolus();

    // Compétences de race
    procedure TabRaceCompetenceDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; {%H-}aState: TGridDrawState);
    procedure TabRaceCompetenceMouseDown({%H-}Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure ButtonRaceCompetenceHasardClick({%H-}Sender: TObject);
    procedure ClickRaceCompetence(aCol, aRow: Integer);
    procedure CalculNbRaceCompetence();

    // Compétence de métier
    procedure TabMetierCompetenceDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure TabMetierCompetenceSelectEditor({%H-}Sender: TObject; aCol,
      {%H-}aRow: Integer; var Editor: TWinControl);
    procedure TabMetierCompetenceValidateEntry({%H-}Sender: TObject; aCol,
      {%H-}aRow: Integer; const OldValue: string; var NewValue: String);
    procedure CalculTotalMetierCompetence();
    procedure ButtonMetierCompetenceHasardClick({%H-}Sender: TObject);
    function CompetenceAuHasard(Grille: TStringGrid; const CodeGen: String): String;
    procedure ButtonEquipementHasardClick({%H-}Sender: TObject);

    // Equipement
//    procedure TabMetierEquipementDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
//      aRect: TRect; {%H-}aState: TGridDrawState);
    procedure TabMetierEquipementSelectEditor({%H-}Sender: TObject; {%H-}aCol,
      {%H-}aRow: Integer; var Editor: TWinControl);
    procedure TabSelectEditor({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);

  private
    EditJetNom:     TEdit;
    FJetNomSaisi:   Boolean;
    // V2 : argent de depart de la carriere (phase du materiel)
    ButtonArgent:   TBCButton;
    EditArgent:     TEdit;
    FormuleArgent:  String;
    FEditingCol: Integer;
    FEditingRow: Integer;
    // Phase intermediaire "Background" (Liber Fanatica : DATA_RULE_BACKGROUND, _COUNT, _SKILL_ROLL, _TALENT_ROLL),
    // creee en code : d100 du background, d10 du nombre de competences/talents, tirages, puis ajout au personnage
    TabSheetFond:   TTabSheet;
    GroupBoxFond:   TGroupBox;
    LabFondTexte:   TLabel;
    ComboFond:      TComboBox;
    ComboFond2:     TComboBox;
    ButtonFondRegle, ButtonFondD10, ButtonFondRelance, ButtonFondIgnore: TBCButton;
    GridFond:       TStringGrid;
    CodesFond:      TStringList;   // code de la regle de chaque item des deux combos
    procedure CreeOngletFond();
    function  FondActif(): Boolean;
    procedure AfficheSousPhaseFond();
    procedure ButtonFondRegleClick(Sender: TObject);
    procedure ButtonFondD10Click(Sender: TObject);
    procedure ButtonFondRelanceClick(Sender: TObject);
    procedure ButtonFondIgnoreClick(Sender: TObject);
    procedure ComboFondChange(Sender: TObject);
    procedure GridFondDblClick(Sender: TObject);
    procedure TireLigneFond(Genre: Char; const Regle: String; Ligne: Integer);
    function  FondComplet(): Boolean;
    procedure AppliqueFond();
    procedure ButtonArgentClick(Sender: TObject);
    procedure AfficheArgentDepart();
    procedure EditJetNomChange(Sender: TObject);
    procedure EditJetNomKeyPress(Sender: TObject; var Key: Char);
    // V1 : etapes de creation posees sur les onglets (voir CreationV1.pas)
    procedure PrepareV1();
    procedure AfficheOngletV1();
    function  VerifOngletV1(): Boolean;
    procedure AfficheCompetencesRaceV1();
    function  CompetenceDeRaceV1(const Code: String): Boolean;
    function  NbCompetencesRaceV1(): Integer;

  public
    // Creation sans ecran (--creer) : deroule les phases avec les boutons Hasard, race et carriere imposees.
    // Les messages de validation vont dans Rapport au lieu d'ouvrir une fenetre. Vrai si le perso est enregistre.
    function CreationAuto(const CodeRace, CodeMetier, Nom: String; Rapport: TStrings; const CodeRegle: String = ''): Boolean;
  end;

Const
  PhaseDebut = 0;
  // 9 étapes depuis le 21/08/2026 : le choix des livres est devenu l'étape 0, avant l'ethnie
  // (idée de Nono, CONTEXT.md §2.14). Ajouter une étape demande de toucher, dans l'ordre :
  // PhaseMax, ListPhase (ChargerImage), les deux case de PageEtapesChange et PhaseSave, et
  // l'ordre des TTabSheet dans le .lfm - rien d'autre ne code un numéro d'étape en dur.
  PhaseMax   = 8;

var
  WinCreations:                  TWinCreations;

  // Phases
  PhaseEnCours:                  Integer = 0;
  ListPhase:                     TStringList;

  // Vrai si le signe astral en cours vient du tirage et n'a pas ete change ensuite : +25 XP
  // (Archives of the Empire II p.39). Un signe choisi a la main ne donne rien.
  SigneTire:                     Boolean = False;
  SignesCombo:                   array of Integer; // rang du combo (hors « aucun ») -> indice dans ListSigneAstral
  // Phase intermediaire "2.1" : le numero des phases V4 ne change pas, le clan s'insere apres la race.
  SousPhaseClan:                 Boolean = False;
  // Phase intermediaire 2.2 : mutation de depart (apres le clan quand la race a les deux)
  SousPhaseMutation:             Boolean = False;
  SousPhaseFamilier:             Boolean = False;
  // Resultat du tirage du familier : texte (forme, particularites) range dans Personnage.NaissanceV2 et effets a
  // appliquer a l'enregistrement final (AjouteEffetsFamilier) ; vide tant que rien n'est tire.
  FamilierTexte:                 String = '';
  FamilierEffets:                String = '';
  // Phase intermediaire 3.1 : appartenance (culte, regiment, ordre), apres le choix du metier
  SousPhaseAppartenance:         Boolean = False;
  FondIgnore:                    Boolean = False;   // le joueur a passe la phase Background (bouton Ignorer)
  SousPhaseFond:                 Boolean = False;   // phase intermediaire "Background" (Liber Fanatica), apres la race
  // Phase intermediaire 4.1 : signe astral, juste apres les caracteristiques (Archives of the Empire II p.39)
  SousPhaseSigne:                Boolean = False;
  // Phase intermediaire 3.0 : chance de mutation de depart d'une regle (jet d100 propose apres le metier)
  SousPhaseMutationChance:       Boolean = False;
  MutationChanceJet:             Integer = 0;       // 0 = pas encore lance
  MutationChanceFaite:           Boolean = False;   // etape deja passee pour cette race / cette regle
  MutationDepartOk:              Boolean = False;
  MutationDepart:                StructurePersonnageMutation;
  MutationDepartLibelle:         String = '';
  ClanChoisi:                    String = '';

  // Pour les images
  ColorLoc:                      TColor;
  ColorList:                     array of TColor;
  // ListImage et Path etaient absents d'ici : non declares, ils se resolvaient sur les
  // globales de WinRaces (derniere unite de la clause uses a les declarer), si bien que
  // cette fenetre remplissait la liste d'images d'une AUTRE fenetre. Sans consequence tant
  // que tout le monde chargeait les memes icones generiques ; devenu faux le jour ou les
  // icones dependent du livre. Declares ici le 30/08/2026.
  ListImage:                     TImageList;
  Path:                          String;

  // Race
  RaceEnCours:                   String;
  RaceLibEnCours:                String;
  LastRandomRaceResultat:        Integer = 0;
  LastCheckRaceResultat:         Integer = 0;
  ModDesti:                      Boolean = false;
  // Vrai quand le radio des 100 points est coche (Rulebook, 3e palier des attributs)
  ModRepartition:                Boolean = false;
    // Compétence
    NbRaceCompetenceTab:         Integer = 0;
    CompetenceRaceStates:        array of array of Boolean;
    NbRaceComp:                  Integer = 0;
    NbTrois:                     Integer = 0;
    NbCinq:                      Integer = 0;
    // Talent
    TalentRaceChoix1:            String;
    TalentRaceChoix2:            String;
    TalentRaceChoix3:            String;
    TalentRaceChoix4:            String;
    //NbGenerique:                 Integer = 0;

  // Métier
  MetierEnCours:                 String;
  MetierLibEnCours:              String;
  MetierEnCoursPrincipal:        String;
  LastRandomMetierResultat:      Integer = 0;
  CodesRegleCombo:               TStringList;     // codes des regles du combo ('' = table par defaut), meme index
  RaceRegleCombo:                String = '#';    // race pour laquelle le combo a ete rempli
  DesMetier:                     Integer = 100;   // d100, ou d1000 (table maitre du Career Compendium V2)
  LastCheckMetierResultat:       Integer = 0;
  LastCheckMetierSousMetierResul:Integer = 0;
    // Compétences
    NbMetierCompetenceTab:       Integer = 0;
    TotalMetierCompetence:       Integer = 0;
    // Equipement
    NbMetierEquipementTab:       Integer = 0;

  // fenêtre de choix
  FenMetier:                   TWinMetiers;
  FenRace:                     TWinRace;
  FenTalent:                   TWintTalent;
  FenCompetence:               TWinCompetence;
  FenSpecialisation:           TWinSpecialisations;
  FenLanceDe:                  TWinLanceDes;

  // gérer click sur les choix de talents multiples
  FirstClick1:                 Boolean = true;
  FirstClick2:                 Boolean = true;
  FirstClick3:                 Boolean = true;
  FirstClick4:                 Boolean = true;

  // objet personnage
  Personnage:                  StructurePersonnage;
  PersonnageAttribut:          StructurePersonnageAttribut;
  PersonnageCompetence:        StructurePersonnageCompetence;
  PersonnageTalent:            StructurePersonnageTalent;
  PersonnageEquipement:        StructurePersonnageEquipement;
  PersonnageMetier:            StructurePersonnageMetier;

  // Livres
  LivresPersonnages:           String;

  // Tableau CHOIX
  ColChoixOrigine: Integer = 1;
  ColChoixLib:     Integer = 2;   // libellé du code source
  ColChoixLibSel:  Integer = 3;   // libellé du choix retenu
  ColChoixSource:  Integer = 4;   // caché
  ColChoixSel:     Integer = 5;   // caché
  ColChoixParent:  Integer = 6;   // caché
  ColChoixRang:    Integer = 7;   // caché

  // Tableau ALÉATOIRE
  ColHasOrigine:   Integer = 1;
  ColHasLib:       Integer = 2;
  ColHasJet:       Integer = 3;
  ColHasLibSel:    Integer = 4;
  ColHasSource:    Integer = 5;   // caché
  ColHasSel:       Integer = 6;   // caché
  ColHasRang:      Integer = 7;   // caché
  ColHasParent:    Integer = 8;   // caché
  ColHasLibSpe:    Integer = 9;   // libellé de la spécialisation retenue
  ColHasSpe:       Integer = 10;  // caché

//  ChoixWinJetDeja: TStringList;

  ListeChoixCreation: array of StructureChoixCreation;

implementation

var
  JetBlessureV2, JetDestinV2, JetMouvementV2: Integer;   // d10 des tables V2 2-2 et 2-3, et du Mouvement en table (familier cree) (0 = pas tire)
  ClemenceRow: Integer = 0;               // V2 : ligne remplacee par la Clemence de Shallya (0 = non utilisee)
  ButtonClemence: TBCButton = nil;
  GridRace: TStringGrid = nil;            // V2 : grille des races de la phase 2 (a la place de la table de tirage)
  GridAvance: TStringGrid = nil;          // V2 : grille de l'avance gratuite (phase 7)
  AvanceGratuiteCode: String = '';        // V2 : caracteristique de l'avance gratuite (etape 7 du Core p.14)
  AvanceGratuiteCode2: String = '';       // V2 : seconde avance gratuite (familier lie : deux avances, Realms of Sorcery p.189)
  CreationV1Obj: TCreationV1 = nil;       // V1 : caracteristiques, classe, age et competences (onglets Attributs, Metier...)

{$R *.lfm}

var
  RapportAuto:  TStrings = nil;           // --creer : recueille les messages au lieu de les afficher
  MessageRecu:  Boolean  = False;

// Remplace Dialogs.ShowMessage dans cette unite : en creation automatique le message est note, pas affiche
procedure ShowMessage(const Msg: String);
  begin
    if RapportAuto <> nil then
      begin
        RapportAuto.Add('MESSAGE : ' + Msg);
        MessageRecu := True;
      end
    else
      Dialogs.ShowMessage(Msg);
  end;

var
  ChoixAdaptationCle:   String = '';
  ChoixAdaptationMemo:  String = '';

// Adaptations facultatives (Adapting Careers) du couple carriere/ethnie en cours : demandees
// une seule fois par couple (l'ecran est reconstruit a chaque affichage), memorisees ensuite.
function ChoixAdaptationCreation(): String;
begin
  if (MetierEnCours = '') or (RaceEnCours = '') then
    begin
      Result := '';
      Exit;
    end;
  if ChoixAdaptationCle <> MetierEnCours + '|' + RaceEnCours then
    begin
      ChoixAdaptationCle  := MetierEnCours + '|' + RaceEnCours;
      ChoixAdaptationMemo := DemanderAdaptationsFacultatives(MetierEnCours, RaceEnCours, '');
    end;
  Result := ChoixAdaptationMemo;
end;

{ TWinCreations }

////////////////////////////////////////////////////////////////////////////////
//                                GENERIQUES                                  //
////////////////////////////////////////////////////////////////////////////////

// V2 et V1 : pas de table de tirage de la race, une grille des races (double-clic = choisir, Hasard = tirage egal)
function RaceParGrille(): Boolean;
  begin
    Result := (ValVersion = 'WFRP2') or (ValVersion = 'WFRP1');
  end;

// Libelle d'une ligne de competence : un code "A/B" (choix) n'a pas de fiche, donc pas de
// libelle ; on affiche alors les libelles des branches ("A / B"), pour que la ligne ne soit pas vide.
function LibelleCompetenceLigne(const Code: String): String;
  var
    Branches: TStringList;
    Ind:      Integer;
  begin
    Result := ChercheCompetence(Code).Libelle;
    if (Result <> '') or (Pos(SeparateurMulti, Code) = 0) then
      exit;
    Branches := TStringList.Create;
    try
      Branches.StrictDelimiter := True;
      Branches.Delimiter       := SeparateurMulti;
      Branches.DelimitedText   := Code;
      for Ind := 0 to Branches.Count - 1 do
        begin
          if Result <> '' then
            Result := Result + ' / ';
          Result := Result + ChercheCompetence(Branches[Ind]).Libelle;
        end;
    finally
      Branches.Free;
    end;
  end;

// Etape affichee -> ancre du guide de creation (DOC\HTML, ancres step-N / extras)
procedure TWinCreations.ButtonGuideClick(Sender: TObject);
  var
    Ancre: String;
  begin
    if PageEtapes.ActivePage = TabSheetLivre then Ancre := 'step-0'
    else if PageEtapes.ActivePage = TabSheetRace then Ancre := 'step-1'
    else if PageEtapes.ActivePage = TabSheetMetier then Ancre := 'step-2'
    else if PageEtapes.ActivePage = TabSheetAttribut then Ancre := 'step-3'
    else if PageEtapes.ActivePage = TabSheetTalent then Ancre := 'step-4'
    else if PageEtapes.ActivePage = TabSheetCompRace then Ancre := 'step-5'
    else if PageEtapes.ActivePage = TabSheetCompMetier then Ancre := 'step-6'
    else if PageEtapes.ActivePage = TabSheetEquipement then Ancre := 'step-7'
    else if PageEtapes.ActivePage = TabSheetNom then Ancre := 'step-8'
    else Ancre := 'extras';
    OuvreGuide(GuideCreation, Ancre);
  end;

procedure TWinCreations.ButtonQuestionClick(Sender: TObject);
  begin
    OuvreGuide(GuideQuestions, '');
  end;

procedure TWinCreations.FormCreate(Sender: TObject);
  var
    Bmp: TBGRABitmap;
    I: Integer;
    Flux: TMemoryStream;
  begin
    MiseEnFormeDesChamp(self);
    CreeBoutonGuide(Self, GetTexteLibelle('RULES-HELP_LAB_GUIDE', 'Help'), 'RULES-HELP_BTN_GUIDE',
      ClientWidth - 300, 4, 140, @ButtonGuideClick);
    CreeBoutonGuide(Self, GetTexteLibelle('RULES-HELP_LAB_QUESTION', '? Question'), 'RULES-HELP_BTN_QUESTION',
      ClientWidth - 150, 4, 140, @ButtonQuestionClick);
    // grilles sans saisie : ligne entiere selectionnee, couleur commune
    SelectionGrilleWarhammer(TabLivre);
    SelectionGrilleWarhammer(TabTalent);
    SelectionGrilleWarhammer(TabMetier);
    SelectionGrilleWarhammer(RecapAttribut);
    SelectionGrilleWarhammer(RecapTalent);
    SelectionGrilleWarhammer(RecapComp);
    SelectionGrilleWarhammer(TabCreationChoix);
    SelectionGrilleWarhammer(TabCreationHasard);
    ChargerImage();
    ChargerLivre();
    ChargeComboRegle();
    ChangementPhase(ConstSuivant);
    EditRaceResultat.MinValue    := 0;
    EditRaceResultat.MaxValue    := 100;
    EditMetierResultat.MinValue  := 0;
    EditMetierResultat.MaxValue  := 100;

    // charges les images des niveaux
    ChargeImagesNiveau();

    if FileExists(CheminImage(GetCurrentDir+ConstCheminScroll)) then
       begin
         Bmp := TBGRABitmap.Create(CheminImage(GetCurrentDir+ConstCheminScroll));
         ImageScroll.Picture.Bitmap.Assign(Bmp);
         Bmp.Free;
         ImageScroll.SendToBack;
       end;

    LastRandomRaceResultat              := 0;
    LastRandomMetierResultat            := 0;
    LastCheckRaceResultat               := 0;
    LastCheckMetierResultat             := 0;
    LastCheckMetierSousMetierResul      := 0;

    LabelRace.Caption                          := GetTexteLibelle('RULES-LAB_042');
    LabelMetier.Caption                        := GetTexteLibelle('RULES-LAB_006');
    LabelAttribut.Caption                      := GetTexteLibelle('RULES-LAB_008');
    LabelTalent.Caption                        := GetTexteLibelle('RULES-LAB_007');
    LabelCompetence.Caption                    := GetTexteLibelle('RULES-LAB_009');
    Self.Caption                               := GetTexteLibelle('RULES-LAB_081');
    GroupBoxRace.Caption                       := GetTexteLibelle('RULES-LAB_084');
    GroupBoxAttribut.Caption                   := GetTexteLibelle('RULES-LAB_084');
    GroupBoxMetier.Caption                     := GetTexteLibelle('RULES-LAB_084');
    GroupBoxRegle.Caption                      := GetTexteLibelle('RULES-LAB_618');
    ButtonAttributHasard .Caption              := GetTexteLibelle('RULES-LAB_085');
    ButtonRaceHasard.Caption                   := GetTexteLibelle('RULES-LAB_085');
    ButtonTalentHasard.Caption                 := GetTexteLibelle('RULES-LAB_085');
    ButtonRaceCompetenceHasard.Caption         := GetTexteLibelle('RULES-LAB_085');
    ButtonMetierHasard.Caption                 := GetTexteLibelle('RULES-LAB_085');
    ButtonMetierCompetenceHasard .Caption      := GetTexteLibelle('RULES-LAB_085');
    ButtonRaceValider.Caption                  := GetTexteLibelle('RULES-LAB_086');
    ButtonMetierValider.Caption                := GetTexteLibelle('RULES-LAB_086');
    ButtonRaceSelectionner.Caption             := GetTexteLibelle('RULES-LAB_004');
    ButtonMetierSelectionner.Caption           := GetTexteLibelle('RULES-LAB_004');
    TabSheetRace.Caption                       := GetTexteLibelle('RULES-LAB_042');
    TabSheetMetier.Caption                     := GetTexteLibelle('RULES-LAB_006');
    TabSheetAttribut.Caption                   := GetTexteLibelle('RULES-LAB_008');
    TabSheetTalent.Caption                     := GetTexteLibelle('RULES-LAB_007');
    TabSheetCompRace.Caption                   := GetTexteLibelle('RULES-LAB_087');
    TabSheetCompMetier.Caption                 := GetTexteLibelle('RULES-LAB_088');
    TabSheetEquipement.Caption                 := GetTexteLibelle('RULES-LAB_013');
    TabSheetNom.Caption                        := GetTexteLibelle('RULES-LAB_014');
    ButtonPhysique.Caption                     := GetTexteLibelle('RULES-LAB_266');
    ButtonNom.Caption                          := GetTexteLibelle('RULES-LAB_267');
    LabSigne.Text                              := GetTexteLibelle('RULES-LAB_272');
    ButtonSigne.Caption                        := GetTexteLibelle('RULES-LAB_273');
    // Bouton de specialisation du talent generique du signe (Craftsman...), pose en code sous le memo
    // Les controles du signe quittent l'onglet Nom pour la phase intermediaire 4.1 (memes positions)
    TabSheetSigne.Caption                      := GetTexteLibelle('RULES-LAB_793');
    LabSigne.Parent                            := TabSheetSigne;
    ComboBoxSigne.Parent                       := TabSheetSigne;
    ButtonSigne.Parent                         := TabSheetSigne;
    MemoSigne.Parent                           := TabSheetSigne;
    ButtonSigne.BringToFront;
    MemoSigne.Height                           := MemoSigne.Height - 36;
    ButtonSigneSpe                             := TButton.Create(Self);
    ButtonSigneSpe.Parent                      := MemoSigne.Parent;
    ButtonSigneSpe.SetBounds(MemoSigne.Left, MemoSigne.Top + MemoSigne.Height + 4, MemoSigne.Width, 30);
    ButtonSigneSpe.Caption                     := GetTexteLibelle('RULES-LAB_275');
    ButtonSigneSpe.Visible                     := False;
    ButtonSigneSpe.OnClick                     := @ButtonSigneSpeClick;
    ButtonMetierEquipementHasard.Caption       := GetTexteLibelle('RULES-LAB_085');
    ButtonNomHasard.Caption                    := GetTexteLibelle('RULES-LAB_085');
    ComboBoxSexeNom.Items[0]                   := GetTexteLibelle('RULES-LAB_268');
    ComboBoxSexeNom.Items[1]                   := GetTexteLibelle('RULES-LAB_269');
    ComboBoxSexeNom.ItemIndex                  := 0;
    // Regle de nom (declaree par les livres, <NameRule>) : un combo cree en code remplace la case Noble
    CheckBoxNoble.Visible                      := False;
    LabNoble.Visible                           := False;
    ComboBoxRegleNom                           := TComboBox.Create(Self);
    ComboBoxRegleNom.Parent                    := CheckBoxNoble.Parent;
    ComboBoxRegleNom.SetBounds(CheckBoxNoble.Left, CheckBoxNoble.Top, 180, 28);
    ComboBoxRegleNom.Style                     := csDropDownList;
    ComboBoxRegleNom.Visible                   := False;
    CodesRegleNom                              := TStringList.Create;
    CreeOngletFond();
    TabSheetNom.OnShow                       := @TabSheetNomShow;
    TabSheetClan.Caption                       := GetTexteLibelle('RULES-LAB_785');
    LabClanTexte.Caption                       := GetTexteLibelle('RULES-LAB_786');
    ButtonClanHasard.Caption                   := GetTexteLibelle('RULES-LAB_085');
    TabSheetMutation.Caption                   := GetTexteLibelle('RULES-LAB_787');
    LabMutationTexte.Caption                   := GetTexteLibelle('RULES-LAB_788');
    ButtonMutationChoix.Caption                := GetTexteLibelle('RULES-LAB_789');
    TabSheetFamilier.Caption                   := GetTexteLibelle('RULES-LAB_795');
    LabFamilierTexte.Caption                   := GetTexteLibelle('RULES-LAB_796');
    ButtonFamilierHasard.Caption               := GetTexteLibelle('RULES-LAB_085');
    TabSheetAppartenance.Caption               := GetTexteLibelle('RULES-LAB_790');
    LabAppartenanceTexte.Caption               := GetTexteLibelle('RULES-LAB_791');
    ButtonAppartenanceChoix.Caption            := GetTexteLibelle('RULES-LAB_792');
    RadioButtonRaceHasard.Caption              := GetTexteLibelle('RULES-LAB_085')+' (20xp)';
    RadioButtonMetierHasard.Caption            := GetTexteLibelle('RULES-LAB_085')+' (50xp)';
    RadioButtonAttributHasard.Caption          := GetTexteLibelle('RULES-LAB_085')+' (50xp)';
    RadioButtonRaceResultat.Caption            := GetTexteLibelle('RULES-LAB_089')+' (20xp)';
    RadioButtonMetierResultat.Caption          := GetTexteLibelle('RULES-LAB_089')+' (50xp)';
    RadioButtonAttributResultat.Caption        := GetTexteLibelle('RULES-LAB_089')+' (50xp)';
    RadioButtonRaceChoix.Caption               := GetTexteLibelle('RULES-LAB_084')+' (0xp)';
    RadioButtonMetierChoix.Caption             := GetTexteLibelle('RULES-LAB_084')+' (0xp)';
    RadioButtonAttributHasardAffecte.Caption   := GetTexteLibelle('RULES-LAB_090')+' (25xp)';
    RadioButtonAttributResultatAffecte.Caption := GetTexteLibelle('RULES-LAB_091')+' (25xp)';
    RadioButtonAttributRepartition.Caption     := GetTexteLibelle('RULES-LAB_316')+' (0xp)';
    LabPointSupp.Caption                       := GetTexteLibelle('RULES-LAB_092');
    LabDestin.Caption                          := GetTexteLibelle('RULES-LAB_093');
    LabResilience.Caption                      := GetTexteLibelle('RULES-LAB_094');
    LabNomPersonnage.Caption                   := GetTexteLibelle('RULES-LAB_095');
    ButtonMetierSousMetierSelectionner.Caption := GetTexteLibelle('RULES-LAB_004');
    ButtonPhaseSuivante.Caption                := GetTexteLibelle('RULES-LAB_134');
    LabRegle.Caption                           := GetTexteLibelle('RULES-LAB_135');
    LabLivre.Caption                           := GetTexteLibelle('RULES-LAB_137');

    ButtonRaceCompetenceHasard.BringToFront;
    ButtonMetierCompetenceHasard.BringToFront;
    ButtonMetierEquipementHasard.BringToFront;
    ButtonNomHasard.BringToFront;
    ButtonClanHasard.BringToFront;
    LabClanTexte.BringToFront;
    ButtonMutationChoix.BringToFront;
    LabMutationTexte.BringToFront;
    LabMutationChoisie.BringToFront;
    ButtonFamilierHasard.BringToFront;
    LabFamilierTexte.BringToFront;
    LabFamilierChoisi.BringToFront;
    LabFamilierTexte.Height := 32;
    LabFamilierChoisi.Top    := 330;
    LabFamilierChoisi.Height := 100;
    ClbFamilierForme         := TCheckListBox.Create(Self);
    ClbFamilierAnimal        := TCheckListBox.Create(Self);
    ClbFamilierParticularite := TCheckListBox.Create(Self);
    ClbFamilierForme.SetBounds(8, 48, 320, 270);
    ClbFamilierAnimal.SetBounds(340, 48, 320, 270);
    ClbFamilierParticularite.SetBounds(672, 48, 320, 270);
    // Police noire sur fond blanc : la police du formulaire est blanche (meme reflexe que EditJetNom)
    ClbFamilierForme.ParentFont            := False;
    ClbFamilierAnimal.ParentFont           := False;
    ClbFamilierParticularite.ParentFont    := False;
    ClbFamilierForme.Font.Color            := clBlack;
    ClbFamilierAnimal.Font.Color           := clBlack;
    ClbFamilierParticularite.Font.Color    := clBlack;
    ClbFamilierForme.Color                 := clWhite;
    ClbFamilierAnimal.Color                := clWhite;
    ClbFamilierParticularite.Color         := clWhite;
    ClbFamilierForme.Parent                := TabSheetFamilier;
    ClbFamilierAnimal.Parent               := TabSheetFamilier;
    ClbFamilierParticularite.Parent        := TabSheetFamilier;
    ClbFamilierForme.OnClickCheck          := @ClbFamilierClickCheck;
    ClbFamilierAnimal.OnClickCheck         := @ClbFamilierClickCheck;
    ClbFamilierParticularite.OnClickCheck  := @ClbFamilierClickCheck;
    ButtonAppartenanceChoix.BringToFront;
    LabAppartenanceTexte.BringToFront;
    LabAppartenanceChoisie.BringToFront;
    // Le TShape pose par MiseEnFormeDesChamp sur chaque onglet cache les controles non
    // fenetres (TBCButton) : meme piege que les boutons ci-dessus (CONTEXT.md 4).
    ButtonPhysique.BringToFront;
    // Jet du de du nom (un jet par morceau de table, separes par /) : saisi, le bouton Nom l'utilise ;
    // vide ou non retouche, le bouton tire. Meme principe que les jets de WinPhysique.
    EditJetNom := TEdit.Create(Self);
    EditJetNom.Parent := ButtonNom.Parent;
    EditJetNom.SetBounds(ButtonNom.Left + ButtonNom.Width + 8, ButtonNom.Top, 90, 28);
    EditJetNom.ParentFont := False;
    EditJetNom.Font.Color := clBlack;
    EditJetNom.OnChange   := @EditJetNomChange;
    EditJetNom.OnKeyPress := @EditJetNomKeyPress;
    EditJetNom.Hint       := GetTexteLibelle('RULES-LAB_749');
    EditJetNom.ShowHint   := True;
    FJetNomSaisi          := False;
    ButtonNom.BringToFront;
    ButtonSigne.BringToFront;

    KeyPreview := true;

    // Aide F1 (AideContextuelle.pas ; textes RULES-HELP_CREA_xxx)
    ButtonPhaseSuivante.HelpKeyword              := 'RULES-HELP_CREA_SUIVANT';
    RadioButtonRaceHasard.HelpKeyword            := 'RULES-HELP_CREA_MODE_HASARD';
    RadioButtonRaceResultat.HelpKeyword          := 'RULES-HELP_CREA_MODE_RESULTAT';
    RadioButtonRaceChoix.HelpKeyword             := 'RULES-HELP_CREA_MODE_CHOIX';
    RadioButtonMetierHasard.HelpKeyword          := 'RULES-HELP_CREA_MODE_HASARD';
    RadioButtonMetierResultat.HelpKeyword        := 'RULES-HELP_CREA_MODE_RESULTAT';
    RadioButtonMetierChoix.HelpKeyword           := 'RULES-HELP_CREA_MODE_CHOIX';
    ButtonRaceHasard.HelpKeyword                 := 'RULES-HELP_CREA_RACE_HASARD';
    ButtonRaceSelectionner.HelpKeyword           := 'RULES-HELP_CREA_RACE_SELECT';
    ButtonRaceValider.HelpKeyword                := 'RULES-HELP_CREA_RACE_VALIDE';
    ButtonMetierHasard.HelpKeyword               := 'RULES-HELP_CREA_METIER_HASARD';
    ButtonMetierSelectionner.HelpKeyword         := 'RULES-HELP_CREA_METIER_SELECT';
    ButtonMetierValider.HelpKeyword              := 'RULES-HELP_CREA_METIER_VALIDE';
    ComboBoxRegle.HelpKeyword                    := 'RULES-HELP_CREA_REGLE';
    RadioButtonAttributHasard.HelpKeyword        := 'RULES-HELP_CREA_ATTR_HASARD';
    RadioButtonAttributResultat.HelpKeyword      := 'RULES-HELP_CREA_ATTR_RESULTAT';
    RadioButtonAttributHasardAffecte.HelpKeyword := 'RULES-HELP_CREA_ATTR_HASARD_AFFECTE';
    RadioButtonAttributResultatAffecte.HelpKeyword := 'RULES-HELP_CREA_ATTR_RESULTAT_AFFECTE';
    RadioButtonAttributRepartition.HelpKeyword   := 'RULES-HELP_CREA_ATTR_REPARTITION';
    ButtonTalentHasard.HelpKeyword               := 'RULES-HELP_CREA_TALENT_HASARD';
    ButtonRaceCompetenceHasard.HelpKeyword       := 'RULES-HELP_CREA_COMP_HASARD';
    ButtonMetierCompetenceHasard.HelpKeyword     := 'RULES-HELP_CREA_COMP_HASARD';
    ButtonMetierEquipementHasard.HelpKeyword     := 'RULES-HELP_CREA_EQUIP_HASARD';
    ButtonNomHasard.HelpKeyword                  := 'RULES-HELP_CREA_NOM_HASARD';

    LivresPersonnages := LivresCharges;

    // Regles optionnelles des livres coches, a droite de la liste des livres : chaque creation
    // repart avec toutes les regles cochees (le choix ne vaut que pour ce personnage)
    if Assigned(ReglesDesactiveesCreation) then
      ReglesDesactiveesCreation.Clear;
    PanneauRegles              := TPanelOptionRegle.Create(Self, true, 235, 300, 140);
    PanneauRegles.Parent       := TabSheetLivre;
    PanneauRegles.Left         := TabLivre.Left + TabLivre.Width + 16;
    PanneauRegles.Top          := TabLivre.Top;
    PanneauRegles.Width        := TabSheetLivre.ClientWidth - PanneauRegles.Left - 8;
    PanneauRegles.Height       := TabLivre.Height;
    PanneauRegles.Anchors      := [akLeft, akTop, akRight, akBottom];
    PanneauRegles.FiltreLivres := LivresPersonnages;
    PanneauRegles.OnChangement := @ReglesChangees;
    PanneauRegles.Charger();

    // Par defaut, chaque selecteur est sur "au hasard" (le bouton Hasard est donc visible)
    // (OnClick coupe : Checked le declencherait avant qu'une race/un metier existe)
    RadioButtonRaceHasard.OnClick      := nil;
    RadioButtonMetierHasard.OnClick    := nil;
    RadioButtonAttributHasard.OnClick  := nil;
    RadioButtonRaceHasard.Checked      := true;
    RadioButtonMetierHasard.Checked    := true;
    RadioButtonAttributHasard.Checked  := true;
    RadioButtonRaceHasard.OnClick      := @RadioButtonRaceHasardClick;
    RadioButtonMetierHasard.OnClick    := @RadioButtonMetierHasardClick;
    RadioButtonAttributHasard.OnClick  := @RadioButtonAttributClick;
    // V2 et V1 : la race se choisit (pas de table de tirage), seuls le choix libre reste
    if RaceParGrille() then
      begin
        RadioButtonRaceHasard.Visible    := false;
        RadioButtonRaceResultat.Visible  := false;
        RadioButtonRaceChoix.Checked     := true;
        // V2 : pas de cout en xp selon la methode (regle propre a V4/V5)
        for I := 0 to ComponentCount - 1 do
          if (Components[I] is TRadioButton) and (Pos('xp)', TRadioButton(Components[I]).Caption) > 0) then
            TRadioButton(Components[I]).Caption :=
              Trim(Copy(TRadioButton(Components[I]).Caption, 1, LastDelimiter('(', TRadioButton(Components[I]).Caption) - 1));
        // phase 2 : plus de choix de type, de regles ni de table de tirage ; seul reste le bouton Selectionner
        GroupBoxRace.Visible             := false;
        LabRegle.Visible                 := false;
        ComboRaceCreation.Visible        := false;
        TabRace.Visible                  := false;
        // a la place : une grille des races, double-clic = choisir (comme le bouton Selectionner)
        GridRace := TStringGrid.Create(Self);
        GridRace.Parent       := TabRace.Parent;
        GridRace.Left         := TabRace.Left;
        GridRace.Top          := TabRace.Top;
        GridRace.Width        := TabRace.Width;
        GridRace.Height       := 200;
        GridRace.ColCount     := 4;
        GridRace.RowCount     := 1;
        GridRace.FixedCols    := 0;
        GridRace.ColWidths[0] := 36;
        GridRace.ColWidths[1] := 0;
        GridRace.ColWidths[2] := 220;
        GridRace.ColWidths[3] := 200;
        GridRace.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_014');
        GridRace.Cells[3, 0]  := GetTexteLibelle('RULES-LAB_128');
        GridRace.OnDblClick   := @GridRaceDblClick;
        StylesTStringGrid(GridRace);
        // bouton Hasard visible a sa place habituelle (comme les autres phases), tirage egal entre les races
        ButtonRaceHasard.Visible := True;
      end;
    if ValVersion = 'WFRP2' then
      begin
        // Clemence de Shallya (Core p.19) : bouton clone de celui du tirage
        Flux := TMemoryStream.Create;
        try
          Flux.WriteComponent(ButtonAttributHasard);
          Flux.Position := 0;
          ButtonClemence := TBCButton(TComponentClass(ButtonAttributHasard.ClassType).Create(nil));
          Flux.ReadComponent(ButtonClemence);
        finally
          Flux.Free;
        end;
        ButtonClemence.Name    := 'ButtonClemence';
        ButtonClemence.Parent  := ButtonAttributHasard.Parent;
        ButtonClemence.Left    := ButtonAttributHasard.Left - ButtonAttributHasard.Width - 16;
        ButtonClemence.Caption := GetTexteLibelle('RULES-LAB_730');
        ButtonClemence.OnClick := @ButtonClemenceClick;
        ButtonClemence.Enabled := false;
        ButtonClemence.Visible := true;
        // Argent de depart (phase du materiel) : bouton clone de celui du tirage de materiel, sert d'etiquette
        // et de jet ; champ a sa droite ; a droite de la grille du materiel
        Flux := TMemoryStream.Create;
        try
          Flux.WriteComponent(ButtonMetierEquipementHasard);
          Flux.Position := 0;
          ButtonArgent := TBCButton(TComponentClass(ButtonMetierEquipementHasard.ClassType).Create(nil));
          Flux.ReadComponent(ButtonArgent);
        finally
          Flux.Free;
        end;
        ButtonArgent.Name    := 'ButtonArgent';
        ButtonArgent.Parent  := TabMetierEquipement.Parent;
        ButtonArgent.SetBounds(TabMetierEquipement.Left + TabMetierEquipement.Width + 16, TabMetierEquipement.Top, 256, 45);
        ButtonArgent.Caption := GetTexteLibelle('RULES-LAB_750');
        ButtonArgent.OnClick := @ButtonArgentClick;
        ButtonArgent.Visible := false;
        EditArgent := TEdit.Create(Self);
        EditArgent.Parent     := TabMetierEquipement.Parent;
        EditArgent.SetBounds(ButtonArgent.Left, ButtonArgent.Top + ButtonArgent.Height + 8, 120, 28);
        EditArgent.ParentFont := False;
        EditArgent.Font.Color := clBlack;
        EditArgent.Visible    := false;
        // Avance gratuite (Core p.14, etape 7) : grille a droite des competences de carriere (phase 7)
        GridAvance := TStringGrid.Create(Self);
        GridAvance.Parent       := TabMetierCompetence.Parent;
        GridAvance.Left         := TabMetierCompetence.Left + TabMetierCompetence.Width + 16;
        GridAvance.Top          := TabMetierCompetence.Top;
        GridAvance.Width        := TabMetierCompetence.Parent.ClientWidth - GridAvance.Left - 8;
        GridAvance.Height       := 330;
        GridAvance.ColCount     := 5;
        GridAvance.RowCount     := 1;
        GridAvance.FixedCols    := 0;
        GridAvance.Options      := GridAvance.Options - [goRangeSelect] + [goRowSelect];
        GridAvance.ColWidths[0] := 36;
        GridAvance.ColWidths[1] := 140;
        GridAvance.ColWidths[2] := 70;
        GridAvance.ColWidths[3] := 70;
        GridAvance.ColWidths[4] := 120;
        GridAvance.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_734');
        GridAvance.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_735');
        GridAvance.Cells[3, 0]  := GetTexteLibelle('RULES-LAB_736');
        GridAvance.Cells[4, 0]  := GetTexteLibelle('RULES-LAB_732');
        GridAvance.OnDblClick   := @GridAvanceDblClick;
        // meme apparence que les autres grilles (police, fond, ligne choisie rouge et or)
        StylesTStringGrid(GridAvance);
        AvanceGratuiteCode := '';
        AvanceGratuiteCode2 := '';
        // le compteur x / 40 Pts de la phase 7 n'a plus d'objet en V2
        ButtonTotalMetierCompetence.Visible := false;
      end;
    UpdateSheetRace(false);
    UpdateSheetMetier(false);
    UpdateSheetAttribut(false);
    if ValVersion = 'WFRP1' then
      PrepareV1();
  end;

// V1 : les onglets Attributs et Metier perdent leurs controles de V2/V4/V5 et recoivent ceux de CreationV1 ;
// les caracteristiques passent avant la classe (la classe depend des caracteristiques) et la phase des
// talents est sautee (en V1 les competences remplacent les talents).
procedure TWinCreations.PrepareV1();
  var
    I: Integer;
    Texte: String;
  procedure Vide(Onglet: TTabSheet);
    var
      J: Integer;
    begin
      for J := 0 to Onglet.ControlCount - 1 do
        if not (Onglet.Controls[J] is TShape) then
          Onglet.Controls[J].Visible := False;
    end;
  begin
    Vide(TabSheetAttribut);
    Vide(TabSheetMetier);
    // phases : Attributs avant Metier (la liste des libelles suit)
    TabSheetAttribut.PageIndex := TabSheetMetier.PageIndex;
    Texte := ListPhase[2];
    ListPhase[2] := ListPhase[3];
    ListPhase[3] := Texte;
    FreeAndNil(CreationV1Obj);   // reste d'une fenetre precedente
    GridAvance := nil;           // idem : la grille a disparu avec la fenetre precedente
    Vide(TabSheetCompMetier);
    Vide(TabSheetEquipement);
    // nom et physique : seuls le nom, le bouton Physique et son resume servent en V1
    // (ni signe, ni noblesse, ni hasard : WinPhysique tire la taille) ; le generateur de noms sert
    // des qu'un livre V1 porte des tables de noms (Apocrypha 2), sans regle de nom
    Vide(TabSheetNom);
    LabNomPersonnage.Visible := True;
    EditNomPersonnag.Visible := True;
    ButtonNom.Visible        := True;
    ComboBoxSexeNom.Visible  := True;
    EditJetNom.Visible       := True;
    ButtonPhysique.Visible   := True;
    LabPhysiqueResume.Visible := True;
    LabPhysiqueResume.Text   := '';
    // le bouton modele est masque a l'etape des competences (AfficheCompetencesRaceV1) : sans cela,
    // les boutons copies pour un second personnage naitraient masques
    ButtonRaceCompetenceHasard.Visible := True;
    CreationV1Obj := TCreationV1.Create(Self, TabSheetAttribut, TabSheetMetier, TabSheetCompRace, TabSheetCompMetier,
                                        TabSheetEquipement, ButtonRaceCompetenceHasard);
    for I := 0 to TabSheetAttribut.ControlCount - 1 do
      TabSheetAttribut.Controls[I].BringToFront;
  end;

// V1 : l'onglet qui vient de s'afficher se remplit depuis les choix des etapes precedentes
procedure TWinCreations.AfficheOngletV1();
  begin
    if (PhaseEnCours < 0) or (PhaseEnCours >= PageEtapes.PageCount) then Exit;
    if PageEtapes.Pages[PhaseEnCours] = TabSheetAttribut then
      CreationV1Obj.AfficheCaracteristiques()
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetMetier then
      CreationV1Obj.AfficheClasses()
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetCompRace then
      begin
        AfficheCompetencesRaceV1();
        CreationV1Obj.AfficheAgeCompetences();
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetCompMetier then
      CreationV1Obj.AfficheCarrieres()
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetEquipement then
      CreationV1Obj.AfficheEquipement()
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetNom then
      AfficheAvanceGratuiteV1();
  end;

// V1 : avance gratuite (Core p.4, etape 11 de la creation) choisie dans le schema de la carriere de base,
// grille posee sous le nom et le physique ; meme grille et meme double-clic que V2
procedure TWinCreations.AfficheAvanceGratuiteV1();
  begin
    MetierEnCours := CreationV1Obj.CodeCarriere;
    if GridAvance = nil then
      begin
        GridAvance := TStringGrid.Create(Self);
        GridAvance.Parent       := TabSheetNom;
        GridAvance.Left         := EditNomPersonnag.Left;
        GridAvance.Top          := ButtonPhysique.Top + ButtonPhysique.Height + 24;
        if GridAvance.Top < LabPhysiqueResume.Top + LabPhysiqueResume.Height + 24 then
          GridAvance.Top := LabPhysiqueResume.Top + LabPhysiqueResume.Height + 24;
        GridAvance.Width        := 440;
        GridAvance.Height       := 330;
        GridAvance.ColCount     := 5;
        GridAvance.RowCount     := 1;
        GridAvance.FixedCols    := 0;
        GridAvance.Options      := GridAvance.Options - [goRangeSelect] + [goRowSelect];
        GridAvance.ColWidths[0] := 36;
        GridAvance.ColWidths[1] := 140;
        GridAvance.ColWidths[2] := 70;
        GridAvance.ColWidths[3] := 70;
        GridAvance.ColWidths[4] := 120;
        GridAvance.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_734');
        GridAvance.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_735');
        GridAvance.Cells[3, 0]  := GetTexteLibelle('RULES-LAB_736');
        GridAvance.Cells[4, 0]  := GetTexteLibelle('RULES-LAB_732');
        GridAvance.OnDblClick   := @GridAvanceDblClick;
        StylesTStringGrid(GridAvance);
        AvanceGratuiteCode  := '';
        AvanceGratuiteCode2 := '';
      end;
    GridAvance.Visible := True;
    RemplirGridAvance();
  end;

// V1 : competences de race, toutes acquises d'office (cases du groupe 4 cochees) ; seuls restent les choix « A/B »
procedure TWinCreations.AfficheCompetencesRaceV1();
  var
    CodesCompetenceRace: TStringList;
    CodeCompetenceRace:  String;
    I, Nb:               Integer;
  begin
    CodesCompetenceRace := CodesRaceEffectifs('S', RegleEnCours(), RaceEnCours);
    try
      Nb := CodesCompetenceRace.Count;
      SetLength(CompetenceRaceStates[4], Nb + 2);
      SetLength(CompetenceRaceStates[5], Nb + 2);
      for I := 0 to High(CompetenceRaceStates[4]) do
        begin
          CompetenceRaceStates[4, I] := False;
          CompetenceRaceStates[5, I] := False;
        end;
      NbCinq  := 0;
      NbTrois := 0;
      NbRaceCompetenceTab        := 0;
      TabRaceCompetence.RowCount := 1;
      for CodeCompetenceRace in CodesCompetenceRace do
        begin
          Inc(NbRaceCompetenceTab);
          TabRaceCompetence.RowCount := NbRaceCompetenceTab + 1;
          TabRaceCompetence.Cells[1, NbRaceCompetenceTab] := CodeCompetenceRace;
          TabRaceCompetence.Cells[2, NbRaceCompetenceTab] := '';
          TabRaceCompetence.Cells[3, NbRaceCompetenceTab] := LibelleCompetenceLigne(CodeCompetenceRace);
          CompetenceRaceStates[4, NbRaceCompetenceTab]    := True;
        end;
    finally
      CodesCompetenceRace.Free;
    end;
    TabRaceCompetence.Height := TabRaceCompetence.DefaultRowHeight * TabRaceCompetence.RowCount + 5;
    AdjustGridColumnsWidth(TabRaceCompetence, TabSheetCompRace.ClientHeight, False, True);
    TabRaceCompetence.ColWidths[2] := 0;
    TabRaceCompetence.ColWidths[4] := 0;
    TabRaceCompetence.ColWidths[5] := 0;
    ButtonRaceCompetenceHasard.Visible := False;
    CreationV1Obj.CompetenceDeRace  := @CompetenceDeRaceV1;
    CreationV1Obj.NbCompetencesRace := @NbCompetencesRaceV1;
  end;

// Competences de race comptees dans le total des competences initiales (Core p.16) : la premiere est
// obligatoire, la seconde (au choix) n'est donnee que si le personnage en a deux ou plus.
function TWinCreations.NbCompetencesRaceV1(): Integer;
  begin
    Result := TabRaceCompetence.RowCount - 1;
  end;

// La race donne-t-elle deja cette competence ? (les choix « A/B » non resolus ne comptent pas)
function TWinCreations.CompetenceDeRaceV1(const Code: String): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 1 to TabRaceCompetence.RowCount - 1 do
      if TabRaceCompetence.Cells[1, I] = Code then
        Exit(True);
  end;

// V1 : controle de l'onglet que l'on quitte (la phase 0, le choix des livres, reste celle des autres versions)
function TWinCreations.VerifOngletV1(): Boolean;
  var
    I: Integer;
  begin
    Result := True;
    if PageEtapes.Pages[PhaseEnCours] = TabSheetRace then
      begin
        Result := RaceEnCours <> '';
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_002'));
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetAttribut then
      begin
        Result := CreationV1Obj.CaracComplete();
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_004'));
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetMetier then
      begin
        Result := CreationV1Obj.CodeClasse <> '';
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_003'));
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetCompRace then
      begin
        for I := 1 to Min(TabRaceCompetence.RowCount - 1, CreationV1Obj.NbCompetencesVoulu()) do
          if (Pos(ValeurGenerique, TabRaceCompetence.Cells[1, I]) > 0) or
             (Pos(SeparateurMulti, TabRaceCompetence.Cells[1, I]) > 0) then
            begin
              ShowMessage(GetTexteLibelle('RULES-MESS_042'));
              Exit(False);
            end;
        Result := (CreationV1Obj.NbCompetencesVoulu() > 0) and
                  (CreationV1Obj.NbCompetencesPrises() = CreationV1Obj.NbCompetencesATirer());
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_085'));
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetCompMetier then
      begin
        Result := CreationV1Obj.CarriereComplete();
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_086'));
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetEquipement then
      begin
        Result := CreationV1Obj.EquipementComplet();
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_087'));
      end
    else if PageEtapes.Pages[PhaseEnCours] = TabSheetNom then
      begin
        // meme controle du nom que VerifNom (un espace en bord casserait le dossier du personnage)
        EditNomPersonnag.Text := Trim(EditNomPersonnag.Text);
        if EditNomPersonnag.Text = '' then
          begin
            ShowMessage(GetTexteLibelle('RULES-MESS_017'));
            Exit(False);
          end;
        if DirectoryExists(GetCurrentDir + ConstCheminPersonnage + EditNomPersonnag.Text) then
          begin
            ShowMessage(GetTexteLibelle('RULES-MESS_018'));
            Exit(False);
          end;
        Result := Personnage.Height > 0;
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_088'));
      end;
  end;

procedure TWinCreations.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  var
    i: Integer;
  begin
    ColorLoc := clDefault;
    SetLength(ColorList, 0);
    for i := Low(CompetenceRaceStates) to High(CompetenceRaceStates) do
      SetLength(CompetenceRaceStates[i], 0);
    SetLength(CompetenceRaceStates, 0);
    MetierEnCours := '';
    RaceEnCours   := '';
  end;

procedure TWinCreations.ButtonMetierSelectionnerClick(Sender: TObject);
  var
    PMetier: StructureMetier;
  begin
    // ouvrir les métiers
    SelectWinMetierRace := RaceEnCours;
    SelectWinLivre      := LivresPersonnages;
    FenMetier           := TWinMetiers.Create(Application);
    FenMetier.Position  := poOwnerFormCenter;
    FenMetier.ShowModal;

    // V1 / V2 : on ne commence que dans une carriere de base (Core V2 chapitre III, « All Starting
    // Careers are Basic Careers »). La carriere avancee reste visible dans la fenetre, seule sa
    // selection est refusee (meme principe que winpersonnage.pas, changement de carriere).
    if (ChoixWinMetierRace <> '') and ((ValVersion = 'WFRP2') or (ValVersion = 'WFRP1')) and
       not EstMetierDeBase(ChoixWinMetierRace) then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_123'));
        ChoixWinMetierRace := '';
      end;

    if ChoixWinMetierRace <> '' then
      begin
        PMetier          := chercheMetier(ChoixWinMetierRace);
        MetierEnCours    := PMetier.CodeMetier;
        MetierLibEnCours := PMetier.Libelle;
        // Le metier vient de changer : les icones de niveau peuvent en dependre.
        ChargeImagesNiveau();
        AfficheImageMetier();
        UpdateSheetMetier(true);
      end;

    SelectWinMetierRace:= '';
    ChoixWinMetierRace := '';
  end;


procedure TWinCreations.ButtonMetierSousMetierSelectionnerClick(Sender: TObject);
  var
    PMetier: StructureMetier;
  begin
    // ouvrir les métiers
    SelectWinMetier     := MetierEnCours;
    SelectWinMetierRace := RaceEnCours;
    FenMetier           := TWinMetiers.Create(Application);
    FenMetier.Position  := poOwnerFormCenter;
    FenMetier.ShowModal;

    if ChoixWinMetierRace <> '' then
      begin
        PMetier          := chercheMetier(ChoixWinMetierRace);
        MetierEnCours    := PMetier.CodeMetier;
        MetierLibEnCours := PMetier.Libelle;
        // Le metier vient de changer : les icones de niveau peuvent en dependre.
        ChargeImagesNiveau();
        AfficheImageMetier();
        UpdateSheetMetier(true);
      end;

    SelectWinMetierRace:= '';
    ChoixWinMetierRace := '';
    ButtonMetierSousMetierSelectionner.enabled := false;
  end;


procedure TWinCreations.ButtonMetierSousMetierValiderClick(Sender: TObject);
  Var
    PMetier:  StructureMetier;
  begin
    if (EditMetierSousMetierResultat.Value = 0) then
       ShowMessage(GetTexteLibelle('RULES-MESS_019'))
    else
    begin
      LastCheckMetierSousMetierResul := EditMetierSousMetierResultat.Value;
      MetierEnCours := ResultMetierSousMetier(MetierEnCoursPrincipal, LastCheckMetierSousMetierResul, LivresPersonnages);
      // Idem. Si MetierEnCours porte encore un choix multiple, la resolution ne trouvera
      // pas de metier et retombera sur l'ethnie : sans effet, pas d'erreur.
      ChargeImagesNiveau();
      if pos(SeparateurMulti,MetierEnCours) = 0 then
        begin
          PMetier          := chercheMetier(MetierEnCours);
          MetierLibEnCours := PMetier.Libelle;
          AfficheImageMetier();
          UpdateSheetMetier(true);
        end
      else
        begin
          ButtonMetierSousMetierValider.enabled       := false;
          ButtonMetierSousMetierSelectionner.visible  := true;
          ButtonMetierSousMetierSelectionner.BringToFront;
        end;
    end
  end;

procedure TWinCreations.ButtonRaceSelectionnerClick(Sender: TObject);
begin
  // ouvrir les métiers
  SelectWinRace     := ConstSelectionne;
  SelectWinLivre    := LivresPersonnages;
  FenRace           := TWinRace.Create(Application);
  FenRace.Position  := poOwnerFormCenter;
  FenRace.ShowModal;

  if ChoixWinRace <> '' then
    begin
      TabRaceResultat(0);
      AfficheImageRace();
      UpdateSheetRace(true);
      RemplirGridRace();
    end;

  SelectWinRace  := '';
  ChoixWinRace   := '';
  SelectWinLivre := '';
end;

procedure TWinCreations.ButtonTalentHasardClick(Sender: TObject);
  var
    Ind:      Integer;
    NbTour:   Integer = 0;
    ListOpt:  TStringList;
    ListLibre:TStringList;
    Deja:     TStringList;
    IndOpt:   Integer;
    Jet:      Integer;
    CodeTire: String;
    NbEssai:  Integer;
  begin

    repeat
      // 1 - resoudre les choix
      for Ind := 0 to High(ListeChoixCreation) do
        if (ListeChoixCreation[Ind].CodeChoisi = '') and (not ListeChoixCreation[Ind].Aleatoire) then
          begin
            ListOpt := ListeTalent(ListeChoixCreation[Ind].CodeSource);
            // Ecarter les talents deja pris. Le tirage des CHOIX n'avait pas cette protection,
            // contrairement au tirage aleatoire juste en dessous (TalentDejaPossede) : ca ne se
            // voyait pas tant qu'aucune ethnie ne proposait DEUX FOIS la meme liste. Le Skink de
            // Lustria est le premier ("2 talents parmi les 6 listes", p.160) et tombait deux fois
            // sur le meme talent. CONTEXT.md 2.15.
            Deja      := ListeTalentsDejaPris('');
            ListLibre := TStringList.Create;
            for IndOpt := 0 to ListOpt.Count - 1 do
              if not TalentDejaPossede(ListOpt[IndOpt], Deja) then
                ListLibre.Add(ListOpt[IndOpt]);
            // Repli sur la liste complete si tout est deja pris : mieux vaut un doublon qu'un
            // choix vide qui bloquerait l'etape.
            if ListLibre.Count > 0 then
              ListeChoixCreation[Ind].CodeChoisi := ListLibre[Random(ListLibre.Count)]
            else if ListOpt.Count > 0 then
              ListeChoixCreation[Ind].CodeChoisi := ListOpt[Random(ListOpt.Count)];
            ListLibre.Free;
            Deja.Free;
            ListOpt.Free;
          end;
      ReconstruitChoixCreation();

      // 2 - resoudre les tirages
      for Ind := 0 to High(ListeChoixCreation) do
        if (ListeChoixCreation[Ind].CodeChoisi = '') and ListeChoixCreation[Ind].Aleatoire then
          begin
            Deja := ListeTalentsDejaPris('');
            NbEssai := 0;
            repeat
              Jet      := Random(100) + 1;
              CodeTire := TalentAleatoire(Jet, RaceEnCours);
              NbEssai  := NbEssai + 1;
            until ((CodeTire <> '') and (not TalentDejaPossede(CodeTire, Deja))) or (NbEssai >= 100);
            Deja.Free;
            if CodeTire <> '' then
              begin
                ListeChoixCreation[Ind].Jet        := Jet;
                ListeChoixCreation[Ind].CodeChoisi := CodeTire;
              end;
          end;
      ReconstruitChoixCreation();

      // 3 - resoudre les specialisations
      for Ind := 0 to High(ListeChoixCreation) do
        if (Pos(ValeurGenerique, ListeChoixCreation[Ind].CodeChoisi) > 0)
           and (ListeChoixCreation[Ind].CodeSpecialise = '') then
          begin
            ListOpt := ListeTalent(ListeChoixCreation[Ind].CodeChoisi);
            if ListOpt.Count > 0 then
              ListeChoixCreation[Ind].CodeSpecialise := ListOpt[Random(ListOpt.Count)];
            ListOpt.Free;
          end;
      ReconstruitChoixCreation();

      NbTour := NbTour + 1;
    until ChoixCreationComplet() or (NbTour >= 10);
  end;

procedure TWinCreations.ComboRaceCreationSelect(Sender: TObject);
  begin
    ChargeTabRaces(ComboRaceCreation.Text);
  end;

procedure TWinCreations.ChargerImage();
    procedure ChargerImagePhases();
      begin
          ListPhase := TStringList.Create;
          ListPhase.Add(GetTexteLibelle('RULES-LAB_173'));   // étape 0 : choix des livres
          ListPhase.Add(GetTexteLibelle('RULES-LAB_026'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_027'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_028'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_029'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_030'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_031'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_032'));
          ListPhase.Add(GetTexteLibelle('RULES-LAB_033'));
          PageEtapes.ActivePageIndex := 0;
          PhaseEnCours := -1;
          // Logo
          if FileExists(CheminImage(GetCurrentDir+ConstCheminLogo1)) then
              ImageWar.Picture.LoadFromFile(CheminImage(GetCurrentDir+ConstCheminLogo1));
      end;

    procedure ChargerImageRecapitulatif();
      var
        I: Integer;
        PAttribut: StructureAttribut;
      begin
          // Attribut
          RecapAttribut.ColCount     := 11;
          RecapAttribut.RowCount     := 2;
          RecapAttribut.ColWidths[0] := 0;
          for I := 1 to 10 do
            begin
              PAttribut := ListeAttribut.Items[I-1];
              RecapAttribut.ColWidths[I]:= 43;
              RecapAttribut.Cells[I, 0] := PAttribut.Resume;
            end;
          // Talent
          RecapTalent.RowCount       := 10;
          RecapTalent.ColCount       := 3;
          RecapTalent.ColWidths[0]   := 0;
          RecapTalent.ColWidths[1]   := 208;
          RecapTalent.ColWidths[2]   := 0;
          // Compétences
          RecapComp.ColCount         := 6;
          RecapComp.ColWidths[0]     := 0;
          RecapComp.ColWidths[1]     := 128;
          RecapComp.ColWidths[2]     := 40;
          RecapComp.ColWidths[3]     := 40;
          RecapComp.ColWidths[4]     := 0;
          RecapComp.ColWidths[5]     := 0;
      end;

    procedure ChargerImageRace();
      begin
          // Mise en forme du tableau de choix des Races
          TabRace.Options          := TabRace.Options + [goEditing, goAlwaysShowEditor];
          TabRace.ColCount         := 5;
          TabRace.RowCount         := NbRace+1;
          TabRace.ColWidths[0]     := 30;
          TabRace.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_006');
          TabRace.ColWidths[1]     := 0;
          TabRace.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
          TabRace.ColWidths[2]     := 140;
          TabRace.Cells[3, 0]      := GetTexteLibelle('RULES-LAB_023');
          TabRace.ColWidths[3]     := 105;
          TabRace.Cells[4, 0]      := 'Sel';
          TabRace.ColWidths[4]     := 0;
          TabRace.Height           := TabRace.DefaultRowHeight * TabRace.RowCount + 5;
          ChargeTabRaces();
          AdjustGridColumnsWidth(TabRace, TabSheetRace.ClientHeight, false, true);
      end;

    procedure ChargerImageMetier();
      begin
          // Mise en forme du tableau de choix des Metiers
          // Grille de consultation : activée pour que l'ascenseur et la molette répondent
          // (un contrôle désactivé n'accepte aucune souris), mais SANS les options d'édition -
          // c'est ce que le Enabled=False d'origine cherchait à empêcher. TabMetierDrawCell
          // continue de peindre les cellules lui-même, l'aspect ne change donc pas.
          TabMetier.Options          := TabMetier.Options - [goEditing, goAlwaysShowEditor];
          TabMetier.ColCount         := 6;
          TabMetier.RowCount         := 1;
          TabMetier.ColWidths[0]     := 30;
          TabMetier.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_006');
          TabMetier.ColWidths[1]     := 0;
          TabMetier.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
          TabMetier.ColWidths[2]     := 140;
          TabMetier.Cells[3, 0]      := GetTexteLibelle('RULES-LAB_023');
          TabMetier.ColWidths[3]     := 80;
          TabMetier.Cells[4, 0]      := 'Sel';
          TabMetier.ColWidths[4]     := 0;
          TabMetier.Cells[5, 0]      := 'Tri';   // clé de tri sur la valeur de début, colonne masquée
          TabMetier.ColWidths[5]     := 0;
      end;

    procedure ChargerImageAttributs();
      var
        I, J: Integer;
        ComboBoxAttribut: TComboBox;
        PAttribut: StructureAttribut;
      begin
          // Mise en forme du tableau de choix des Attributs
          TabAttribut.Options          := TabAttribut.Options + [goEditing, goAlwaysShowEditor];
          TabAttribut.ColCount         := 1;
          TabAttribut.RowCount         := NbAttribut +1;
          TabAttribut.ColWidths[0]     := 30;
          TabAttribut.Columns.add;
          TabAttribut.Columns[0].Title.Caption  := GetTexteLibelle('RULES-LAB_001');
          TabAttribut.ColWidths[1]     := 0;
          TabAttribut.Columns.add;
          TabAttribut.Columns[1].Title.Caption      := GetTexteLibelle('RULES-LAB_019');
          TabAttribut.ColWidths[2]     := 30;
          TabAttribut.Columns[1].Alignment:= tacenter;
          TabAttribut.Columns.add;
          TabAttribut.Columns[2].Title.Caption      := GetTexteLibelle('RULES-LAB_008');
          TabAttribut.ColWidths[3]     := 175;
          TabAttribut.Columns.add;
          TabAttribut.Columns[3].Title.Caption      := GetTexteLibelle('RULES-LAB_020');
          TabAttribut.ColWidths[4]     := 80;
          TabAttribut.Columns.add;
          TabAttribut.Columns[4].Title.Caption      := GetTexteLibelle('RULES-LAB_022');
          TabAttribut.ColWidths[5]     := 90;
          TabAttribut.Columns.add;
          TabAttribut.Columns[5].Title.Caption      := GetTexteLibelle('RULES-LAB_021');
          TabAttribut.ColWidths[6]     := 90;
          TabAttribut.Columns.add;
          TabAttribut.Columns[6].Title.Caption      := '';
          TabAttribut.ColWidths[7]     := 0;
          TabAttribut.Height           := TabAttribut.DefaultRowHeight * TabAttribut.RowCount + 5;
          // Mise en forme du tableau de lancé de dé des attributs
          TabAttributLanceDe.Options     := TabAttributLanceDe.Options + [goEditing, goAlwaysShowEditor];
          TabAttributLanceDe.ColCount    := 12;
          TabAttributLanceDe.RowCount    := 3;
          TabAttributLanceDe.ColWidths[0]:= 20;
          TabAttributLanceDe.OnSetEditText := @TabAttributLanceDeSetEditText;
          For I := 1 to 10 do
            begin
              TabAttributLanceDe.Cells[I, 0]  := 'D'+IntToStr(I);
              TabAttributLanceDe.ColWidths[I] := 53;
            end;
          TabAttributLanceDe.Cells[I+1, 0]    := GetTexteLibelle('RULES-LAB_021');
          TabAttributLanceDe.ColWidths[I+1]   := 56;
          TabAttributLanceDe.Height           := TabAttributLanceDe.DefaultRowHeight * TabAttributLanceDe.RowCount + 5;
          TabAttributLanceDe.Width            := 620;
          // Création du composant TComboBox personnalisé pour la ligne 2
           for I := 1 to 11 do
           begin
             ComboBoxAttribut                := TComboBox.Create(Self);
             ComboBoxAttribut.Style          := csDropDownList;
             ComboBoxAttribut.Parent         := TabAttributLanceDe;
             ComboBoxAttribut.DropDownCount  := 10;
             ComboBoxAttribut.Visible        := false; // On le cache initialement
             ComboBoxAttribut.Items.Add(ValeurNonRenseignee);
             for J := 0 to 9 do
             begin
                PAttribut := ListeAttribut.Items[J];
                ComboBoxAttribut.Items.Add(PAttribut.Resume);
             end;
             ComboBoxAttribut.ItemIndex       := 0; // Sélectionner le premier élément
             ComboBoxAttribut.OnChange        := @ComboBoxSelectAttribut;
             TabAttributLanceDe.Objects[I, 2] := ComboBoxAttribut;
           end;
           // Charger les Attributs
          ChargeTabAttribut();
      end;

    procedure ChargerImageTalents();
      begin
           // Mise en forme du tableau de choix des Talents
           TabTalent.Options          := TabTalent.Options + [goAlwaysShowEditor];
           TabTalent.ColCount         := 3;
           TabTalent.RowCount         := 10;
           TabTalent.ColWidths[0]     := 30;
           TabTalent.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_001');
           TabTalent.ColWidths[1]     := 0;
           TabTalent.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_007');
           TabTalent.ColWidths[2]     := 200;
           TabTalent.Height           := TabTalent.DefaultRowHeight * TabTalent.RowCount + 5;
           TabTalent.Width            := 235;

           // Talent avec choix
          TabCreationChoix.RowCount := 1;
          TabCreationChoix.ColCount := 8;
          TabCreationChoix.FixedRows := 1;
          TabCreationChoix.Options := TabCreationChoix.Options + [goRowSelect];
          TabCreationChoix.Cells[ColChoixOrigine, 0] := GetTexteLibelle('RULES-LAB_174');
          TabCreationChoix.Cells[ColChoixLib, 0]     := GetTexteLibelle('RULES-LAB_175');
          TabCreationChoix.Cells[ColChoixLibSel, 0]  := GetTexteLibelle('RULES-LAB_176');
          TabCreationChoix.ColWidths[0]               := 0;
          TabCreationChoix.ColWidths[ColChoixOrigine] := 0;
          TabCreationChoix.ColWidths[ColChoixLib]     := 250;
          TabCreationChoix.ColWidths[ColChoixLibSel]  := 250;
          TabCreationChoix.ColWidths[ColChoixSource]  := 0;
          TabCreationChoix.ColWidths[ColChoixSel]     := 0;
          TabCreationChoix.ColWidths[ColChoixParent]  := 0;
          TabCreationChoix.ColWidths[ColChoixRang]    := 0;
          TabCreationChoix.Width:= 2000;

          // --- Tableau ALÉATOIRE
          TabCreationHasard.RowCount := 1;
          TabCreationHasard.ColCount := 11;
          TabCreationHasard.FixedRows := 1;
          TabCreationHasard.Options := TabCreationChoix.Options + [goRowSelect];
          TabCreationHasard.ColWidths[0]             := 0;
          TabCreationHasard.ColWidths[ColHasOrigine] := 0;
          TabCreationHasard.ColWidths[ColHasLib] := 250;
          TabCreationHasard.ColWidths[ColHasJet] := 250;
          TabCreationHasard.ColWidths[ColHasLibSel] := 250;
          TabCreationHasard.ColWidths[ColHasSource] := 0;
          TabCreationHasard.ColWidths[ColHasSel] := 0;
          TabCreationHasard.ColWidths[ColHasRang] := 0;
          TabCreationHasard.ColWidths[ColHasParent] := 0;
          TabCreationHasard.ColWidths[ColHasLibSpe] := 250;
          TabCreationHasard.ColWidths[ColHasSpe] := 0;
          TabCreationHasard.Width:= 2000;
      end;

    procedure ChargerImageCompetencesRace();
      var
        I, J: Integer;
      begin
           // Mise en forme dy tableau de choix des Compétences de race
           TabRaceCompetence.Options          := TabRaceCompetence.Options + [goEditing, goAlwaysShowEditor];
           TabRaceCompetence.ColCount         := 1;
           TabRaceCompetence.RowCount         := 1;
           TabRaceCompetence.ColWidths[0]     := 30;
           TabRaceCompetence.Columns.Add;
           TabRaceCompetence.Columns[0].Title.Caption      := GetTexteLibelle('RULES-LAB_001');
           TabRaceCompetence.ColWidths[1]     := 0;
           TabRaceCompetence.Columns.Add;
           TabRaceCompetence.Columns[1].Title.Caption      := GetTexteLibelle('RULES-LAB_019');
           TabRaceCompetence.ColWidths[2]     := 30;
           TabRaceCompetence.Columns[1].Alignment := taCenter;
           TabRaceCompetence.Columns.Add;
           TabRaceCompetence.Columns[2].Title.Caption      := GetTexteLibelle('RULES-LAB_009');
           TabRaceCompetence.ColWidths[3]     := 265;
           TabRaceCompetence.Columns.Add;
           // valeurs par defaut : reecrites par ethnie au remplissage du tableau (voir plus bas,
           // "Competences de race") - toutes les races en prennent 3 et 3, le Skink 2 et 2
           TabRaceCompetence.Columns[3].Title.Caption      := '3x 5pts';
           TabRaceCompetence.ColWidths[4]     := 80;
           TabRaceCompetence.Columns.Add;
           TabRaceCompetence.Columns[4].Title.Caption      := '3x 3pts';
           TabRaceCompetence.ColWidths[5]     := 90;
           // définir la case à cocher et l'initialiser
           SetLength(CompetenceRaceStates, 6, NbMaxCompetence + 1);
           for I := 4 to 5 do
             for J := 1 to NbMaxCompetence do
               CompetenceRaceStates[I, J] := false;
      end;

    procedure ChargerImageCompetencesMetier();
      begin
           // Mise en forme dy tableau de choix des Compétences de métier
           TabMetierCompetence.Options          := TabMetierCompetence.Options + [goEditing, goAlwaysShowEditor];
           TabMetierCompetence.ColCount         := 1;
           TabMetierCompetence.RowCount         := 1;
           TabMetierCompetence.ColWidths[0]     := 30;
           TabMetierCompetence.Columns.Add;
           TabMetierCompetence.Columns[0].title.caption      := GetTexteLibelle('RULES-LAB_001');
           TabMetierCompetence.ColWidths[1]     := 0;
           TabMetierCompetence.Columns.Add;
           TabMetierCompetence.Columns[1].title.caption      := 'R';
           TabMetierCompetence.ColWidths[2]     := 30;
           TabMetierCompetence.Columns[1].Alignment:=Tacenter;
           TabMetierCompetence.Columns.Add;
           TabMetierCompetence.Columns[2].title.caption      := GetTexteLibelle('RULES-LAB_009');
           TabMetierCompetence.ColWidths[3]     := 345;
           TabMetierCompetence.Columns.Add;
           TabMetierCompetence.Columns[3].title.caption      := '40 Pts';
           TabMetierCompetence.ColWidths[4]     := 90;
           TabMetierCompetence.Columns.Add;
           TabMetierCompetence.Columns[4].title.caption      := GetTexteLibelle('RULES-LAB_078');
           TabMetierCompetence.ColWidths[5]     := 80;
           TabMetierCompetence.Columns.Add;
           TabMetierCompetence.Columns[5].title.caption      := '';
           TabMetierCompetence.ColWidths[6]     := 0;
      end;

    procedure ChargerImageEquipementMetier();
      begin
          // Mise en forme dy tableau de choix des équipement de métier
          TabMetierEquipement.Options          := TabMetierEquipement.Options + [goEditing, goAlwaysShowEditor];
          TabMetierEquipement.ColCount         := 8;
          TabMetierEquipement.RowCount         := 1;
          TabMetierEquipement.ColWidths[0]     := 30;
          TabMetierEquipement.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_001');
          TabMetierEquipement.ColWidths[1]     := 0;
          TabMetierEquipement.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_013');
          TabMetierEquipement.ColWidths[2]     := 200;
          TabMetierEquipement.Cells[3, 0]      := GetTexteLibelle('RULES-LAB_010');
          TabMetierEquipement.ColWidths[3]     := 0;
          TabMetierEquipement.Cells[4, 0]      := GetTexteLibelle('RULES-LAB_078');
          TabMetierEquipement.ColWidths[4]     := 75;
          TabMetierEquipement.Cells[5, 0]      := '';
          TabMetierEquipement.ColWidths[5]     := 0;
          TabMetierEquipement.Cells[6, 0]      := '';
          TabMetierEquipement.ColWidths[6]     := 0;
          // Col 7, cachee : pour une ligne "au choix", une quantite par code de la col 3 (memes
          // rangs, separees par ','), lue au double-clic pour poser la col 5.
          TabMetierEquipement.Cells[7, 0]      := '';
          TabMetierEquipement.ColWidths[7]     := 0;
      end;

  begin
    // PHASES
    ChargerImagePhases();
    // 0 - RECAPITULATIF
    ChargerImageRecapitulatif();
    // 1 - RACE
    ChargerImageRace();
    // 2 - METIER
    ChargerImageMetier();
    // 3 - ATTRIBUTS
    ChargerImageAttributs();
    // 4 - TALENTS
    ChargerImageTalents();
    // 5 - COMPETENCES DE RACES
    ChargerImageCompetencesRace();
    // 6 - COMPETENCE DE METIER
    ChargerImageCompetencesMetier();
    // 7 - EQUIPEMENT DE METIER
    ChargerImageEquipementMetier();
  end;

procedure TWinCreations.TabSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
  // pour ne pas pouvoir saisir dans certaines tables
  begin
    Editor := nil;
  end;

// Recharge icones et couleurs de niveau pour le couple metier/ethnie du moment. Les deux
// changent en cours de creation, dans les deux sens : cette procedure est donc appelee a
// chaque fois que l'un des deux est fixe.
procedure TWinCreations.ChargeImagesNiveau();
  var
    IndNiv: Integer;
    MaxNiv: Integer;
  begin
    if not Assigned(ListImage) then
      ListImage := TImageList.Create(nil);
    ListImage.Clear;
    SetLength(ColorList, 0);
    // Dimensionne sur la donnee et non sur une constante : voir MaxNiveauMetier.
    // Pas MaxNiveauMetier : le dossier NIV contient aussi des pastilles de couleur
    // rangees apres le dernier niveau. Voir MaxIndiceIconeNiveau.
    MaxNiv := MaxIndiceIconeNiveau();
    SetLength(ColorList, MaxNiv + 1);
    For IndNiv := 0 to MaxNiv Do
      ChargeImageNiveau(IndNiv);
  end;

procedure TWinCreations.ChargeImageNiveau(Niveau: Integer);
  // pour afficher les images des niveaux
  begin
      Picture  := TPicture.Create;
      Bitmap   := TBitmap.Create;
      try
        // Meme resolution que la fiche de personnage : le metier d'abord - sa
        // declaration prouve que son livre est charge - puis l'ethnie, puis sa race,
        // puis \PICTURES\NIV\. Voir CheminNiveauImageMetierRace dans ChargeMetier.
        Path   := CheminNiveauImageMetierRace(MetierEnCours, RaceEnCours, Niveau);
        // Icone absente pour ce niveau : on ajoute QUAND MEME une image, neutre, sinon
        // les index de ListImage se decalent d'un cran et chaque niveau afficherait
        // l'icone du suivant. Le cas se produit des qu'un livre amene un niveau plus haut
        // que ce que PICTURES\NIV\ contient.
        if FileExists(Path) then
          begin
            Picture.LoadFromFile(Path);
            Bitmap.Assign(Picture.graphic);
            ColorLoc := CouleurFondIcone(Bitmap);
          end
        else
          begin
            Bitmap.SetSize(8, 8);
            Bitmap.Canvas.Brush.Color := CouleurGrisFonce;
            Bitmap.Canvas.FillRect(0, 0, 8, 8);
            ColorLoc := CouleurGrisFonce;
          end;
        ListImage.Add(Bitmap, nil); // Ajout de l'image au TImageList
        ColorList[Niveau] := ColorLoc;
      finally
        Picture.Free;
        Bitmap.Free;
      end;
  end;

procedure TWinCreations.LibMetierDblClick(Sender: TObject);
  begin
    MetierFenetre(MetierEnCours);
  end;

procedure TWinCreations.LibRaceDblClick(Sender: TObject);
  begin
    RaceFenetre(RaceEnCours);
  end;


////////////////////////////////////////////////////////////////////////////////
//                               PHASES                                       //
////////////////////////////////////////////////////////////////////////////////

procedure TWinCreations.PhaseSave(NouvellePhase: Integer);
    procedure PhaseSaveRace();
      begin
      Personnage.Race                              := RaceEnCours;
      Personnage.CreationAttribut                  := [];
      Personnage.CreationCompetence35              := [];
      Personnage.CreationCompetence40              := [];
      Personnage.CreationTalent                    := [];
      Personnage.Equipement                        := [];
      Personnage.MetierAncien                      := [];
      Personnage.MetierCompetence                  := [];
      Personnage.MetierTalent                      := [];
      // L'APPARTENANCE (regiment, ordre, culte) est conditionnee par l'ethnie : changer
      // d'ethnie invalide ce qui a pu etre choisi. CONTEXT.md 2.44.
      Personnage.Appartenance                      := '';
      // Les details physiques (Rulebook p.40) dependent de l'ethnie : on repart de zero
      Personnage.Age                               := 0;
      Personnage.Height                            := 0;
      Personnage.HeightUnit                        := UniteTaille;
      Personnage.HairColors                        := '';
      Personnage.EyeColors                         := '';
      Personnage.SexeV2                            := '';
      Personnage.ClasseV1                          := '';
      Personnage.PoidsV2                           := 0;
      Personnage.FratrieV2                         := '';
      Personnage.SigneDistinctifV2                 := '';
      Personnage.NaissanceV2                       := '';
      ClanChoisi                                   := '';
      Personnage.AstreV2                           := '';
      LabPhysiqueResume.Text                       := '';
      // Nouvelle creation : pas de signe astral herite d'une creation precedente
      Personnage.SigneAstral                       := '';
      Personnage.SigneAstralVariante               := '';
      Personnage.SigneAstralTalent                 := '';
      SigneTire                                    := False;
      ChargeTabMetier();
      // Mutation de depart (race qui declare StartingMutation, ex. Mutant du Tome of Corruption p.25) :
      // choisie en phase 2.2 (ChangementPhase), ajoutee apres cet enregistrement.
      Personnage.Mutations := [];
      MutationChanceFaite  := False;
      end;

    procedure PhaseSaveMetier();
      begin
      PersonnageMetier.CodeMetier   := MetierEnCours;
      PersonnageMetier.NiveauMetier := 1;
      PersonnageMetier.CoutXp       := 0;
      Personnage.MetierEnCours      := PersonnageMetier;
      Personnage.ChoixAdaptation    := ChoixAdaptationCreation();
      Personnage.MetierAncien       += [PersonnageMetier];
      end;

    procedure PhaseSaveAttributs();
      var
        IndTab: Integer;
      begin
      For IndTab := 1 to (TabAttribut.Rowcount-1) do
        begin
          if TabAttribut.Cells[5, IndTab] <> '' then
            begin
              PersonnageAttribut.CodeAttribut := TabAttribut.Cells[7, IndTab];
              PersonnageAttribut.Valeur       := StrToIntdef(TabAttribut.Cells[5, IndTab],0);
              Personnage.CreationAttribut     += [PersonnageAttribut];
            end;
        end;
      MajRecapAttribut();
      end;

    procedure PhaseSaveTalents();
      var
        IndTab: Integer;
        PTalent: StructureTalent;
      begin
       AjouteTalentsResolus();
       for IndTab := 1 to (TabTalent.RowCount-1) do
         begin
           if TabTalent.Cells[1, IndTab] <> '' then
             begin
               PersonnageTalent.CodeTalent                  := TabTalent.Cells[1, IndTab];
               PersonnageTalent.Valeur                      := 1;
               Personnage.CreationTalent                    += [PersonnageTalent];
             end;
         end;
       IndTab := 0;
       For PersonnageTalent in Personnage.CreationTalent do
         Begin
           PTalent                      := ChercheTalent(PersonnageTalent.CodeTalent);
           // RecapTalent est dimensionnee une fois pour toutes a 10 lignes dans
           // ChargerImage : au-dela, l'ecriture levait EGridException (Index Out of range).
           // Personne n'avait plus de 10 talents de creation avant le Skink, qui en cumule
           // 6 traits + 2 choix + les specialisations. CONTEXT.md 2.15.
           if IndTab >= RecapTalent.RowCount then
             RecapTalent.RowCount := IndTab + 1;
           RecapTalent.Cells[1, IndTab] := PTalent.Libelle;
           RecapTalent.Cells[2, IndTab] := PTalent.CodeTalent;
           Inc(IndTab);
         end;
       RecapTalent.visible := true;
      end;

    procedure PhaseSaveCompetencesRace();
      var
        IndTab: Integer;
        PCompetence: StructureCompetence;
        PRace: StructureRace;
      begin
      Prace := chercheRace(RaceEnCours);
      for IndTab := 1 to TabRaceCompetence.RowCount - 1 do
        begin
          if CompetenceRaceStates[4, IndTab] then
            begin
              NbRaceComp                                   := NbRaceComp + 1;
              PersonnageCompetence.CodeCompetence          := TabRaceCompetence.Cells[1, IndTab];
              // V2 : pas de +3, la competence est acquise une fois (meme convention que les prises de la phase 7)
              if ValVersion = 'WFRP2' then
                PersonnageCompetence.Valeur                := 1
              else
                PersonnageCompetence.Valeur                := PRace.Point3;
              Personnage.CreationCompetence35              += [PersonnageCompetence];
            end;
          if CompetenceRaceStates[5, IndTab] then
            begin
              NbRaceComp                                   := NbRaceComp + 1;
              PersonnageCompetence.CodeCompetence          := TabRaceCompetence.Cells[1, IndTab];
              PersonnageCompetence.Valeur                  := PRAce.Point5;
              Personnage.CreationCompetence35              += [PersonnageCompetence];
            end;
        end;

      IndTab := 0;
      For PersonnageCompetence in Personnage.CreationCompetence35 do
         Begin
           PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
           // meme precaution que RecapTalent : la grille n'est jamais agrandie a la saisie
           if IndTab >= RecapComp.RowCount then
             RecapComp.RowCount := IndTab + 1;
           RecapComp.Cells[1, IndTab] := PCompetence.Libelle;
           RecapComp.Cells[2, IndTab] := IntToStr(PersonnageCompetence.Valeur);
           RecapComp.Cells[5, IndTab] := PCompetence.CodeCompetence;
           Inc(Indtab);
         end;
      RecapComp.visible := true;
      end;

    procedure PhaseSaveCompetencesMetier();
      var
        IndTab: Integer = 0;
        NbMetierComp: Integer = 0;
        DebMetierRec: Integer = 0;
        Row: Integer;
        NbAdd: Integer = 0;
        PCompetence: StructureCompetence;
        PMetierCompetence: StructureMetierCompetence;
        PMetierTalent: StructureMetierTalent;

      begin
      DebMetierRec := NbRaceComp;
      // V2 : l'avance gratuite devient une augmentation d'un palier, si la carriere en donne encore
      // le plafond (le choix a pu etre fait avant un changement de carriere)
      Personnage.AugmentationAttribut := [];
      Personnage.AvanceGratuiteAttribut := [];
      if (ValVersion = 'WFRP2') and (AvanceGratuiteCode <> '')
         and (PlafondAvanceMetier(MetierEnCours, AvanceGratuiteCode) > 0) then
        begin
          PersonnageAttribut.CodeAttribut := AvanceGratuiteCode;
          PersonnageAttribut.Valeur       := PasAvanceV2(AvanceGratuiteCode);
          PersonnageAttribut.Bonus        := '';
          Personnage.AvanceGratuiteAttribut += [PersonnageAttribut];
        end;
      if (ValVersion = 'WFRP2') and (AvanceGratuiteCode2 <> '') and (NbAvancesGratuites() >= 2)
         and (PlafondAvanceMetier(MetierEnCours, AvanceGratuiteCode2) > 0) then
        begin
          PersonnageAttribut.CodeAttribut := AvanceGratuiteCode2;
          PersonnageAttribut.Valeur       := PasAvanceV2(AvanceGratuiteCode2);
          PersonnageAttribut.Bonus        := '';
          Personnage.AvanceGratuiteAttribut += [PersonnageAttribut];
        end;
      for IndTab := 1 to TabMetierCompetence.RowCount - 1 do
        begin
          // ajout si quantité
          if StrToIntdef(TabMetierCompetence.Cells[4, IndTab],0) > 0 then
            begin
              NbMetierComp                        := NbMetierComp + 1;
              PersonnageCompetence.CodeCompetence := TabMetierCompetence.Cells[1, IndTab];
              PersonnageCompetence.Valeur         := StrToIntdef(TabMetierCompetence.Cells[4, IndTab],0);
              Personnage.CreationCompetence40     += [PersonnageCompetence];
            end;
          // liste des compétesnces de ce métier
          PersonnageCompetence.CodeCompetence     := TabMetierCompetence.Cells[1, IndTab];
          PersonnageCompetence.Valeur             := 1;
          Personnage.MetierCompetence             += [PersonnageCompetence];
        end;

      // Adapting Careers (DATA_CAREER_ADAPTATION) : la competence peut etre remplacee
      // pour l'ethnie du personnage ; vide = simplement retiree. Facultatives : pas
      // encore branchees (Choix vide).
      for PMetierCompetence in ListMetierCompetence do
        if (PMetierCompetence.CodeMetier = MetierEnCours) and (PMetierCompetence.NiveauMetier <> 1) then
          begin
            PersonnageCompetence.CodeCompetence := AdapterElement(MetierEnCours, Personnage.Race, Personnage.ChoixAdaptation,
                                                     PMetierCompetence.NiveauMetier, ConstXmlCompetence,
                                                     PMetierCompetence.CodeCompetence);
            if PersonnageCompetence.CodeCompetence = '' then
              continue;
            PersonnageCompetence.Valeur         := PMetierCompetence.NiveauMetier;
            Personnage.MetierCompetence         += [PersonnageCompetence];
          end;

      // V2 : la competence de l'appartenance (choisie en phase 3.1) est acquise ICI, avant le
      // recapitulatif, pour qu'elle y figure.
      if ValVersion = 'WFRP2' then
        AcquiertCompetencesAppartenanceV2;

      IndTab := 0;
      For PersonnageCompetence in Personnage.CreationCompetence40 do
        Begin
          PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
          Row         := FindRowByText(RecapComp, PCompetence.CodeCompetence, 4);
          if Row = -1 then
            begin
              Row     := DebMetierRec + NbAdd;
              NbAdd   := NbAdd + 1;
              if Row >= RecapComp.RowCount then
                RecapComp.RowCount := Row + 1;
              RecapComp.Cells[1, Row] := PCompetence.Libelle;
              RecapComp.Cells[3, Row] := IntToStr(PersonnageCompetence.Valeur);
              RecapComp.Cells[5, Row] := PCompetence.CodeCompetence;
              Inc(IndTab);
            end;
        end;

      // liste des talents de ce métier (tous niveaux)
      for PMetierTalent in ListMetierTalent do
         if (PMetierTalent.CodeMetier = MetierEnCours) then
           begin
             PersonnageTalent.CodeTalent := AdapterElement(MetierEnCours, Personnage.Race, Personnage.ChoixAdaptation,
                                              PMetierTalent.NiveauMetier, ConstXmlTalent,
                                              PMetierTalent.CodeTalent);
             if PersonnageTalent.CodeTalent = '' then
               continue;
             PersonnageTalent.Valeur     := PMetierTalent.NiveauMetier;
             Personnage.MetierTalent     += [PersonnageTalent];
           end;

      // Les APPARTENANCES greffent leurs competences et talents sur la carriere,
      // "as if added to their Career". L'appel vient APRES les deux boucles
      // ci-dessus, qui repartent d'une liste vide : place avant, il serait efface.
      // CONTEXT.md 2.44.
      PersonnageAppliqueGreffes(Personnage);
      end;

    procedure PhaseSaveEquipements();
      var
        IndTab: Integer;
        StringsCodeEns: TStringList;
        StringsTypeEns: TStringList;
        IndEns: Integer;
      begin
      // V2 : argent de depart de la carriere dans la bourse (en couronnes d'or)
      if (ValVersion = 'WFRP2') and Assigned(EditArgent) then
        if EditArgent.Visible then
          Personnage.MonnaieCO := StrToIntDef(EditArgent.Text, 0)
        else
          Personnage.MonnaieCO := 0;
      for IndTab := 1 to TabMetierEquipement.RowCount - 1 do
        begin
          if Pos(SeparateurEnsemble, TabMetierEquipement.Cells[1, IndTab]) > 0 then
            begin
              // ensemble : la ligne porte deux codes joints par SeparateurEnsemble
              // (AfficheImageMetier) - une seule ligne de creation, mais les deux
              // objets doivent exister separement dans Personnage.Equipement.
              StringsCodeEns := TStringList.Create;
              StringsTypeEns := TStringList.Create;
              ExtractStrings([SeparateurEnsemble], [], PChar(TabMetierEquipement.Cells[1, IndTab]), StringsCodeEns);
              ExtractStrings([SeparateurEnsemble], [], PChar(TabMetierEquipement.Cells[6, IndTab]), StringsTypeEns);
              for IndEns := 0 to StringsCodeEns.Count - 1 do
                begin
                  PersonnageEquipement.CodeEquipement    := StringsCodeEns[IndEns];
                  PersonnageEquipement.QualiteEquipement := QualiteDepuisCode(PersonnageEquipement.CodeEquipement);
                  PersonnageEquipement.TypeEquipement    := StringsTypeEns[IndEns];
                  // Fabrication D'ORIGINE (gromril, Jade Longsword...) : posee seulement si
                  // le joueur n'a pas deja un (Q) a choisir. CONTEXT.md 2.29.
                  if PersonnageEquipement.QualiteEquipement = '' then
                    PersonnageEquipement.QualiteEquipement := FabricationDuCatalogue(PersonnageEquipement.CodeEquipement, PersonnageEquipement.TypeEquipement);
                  PersonnageEquipement.Porte             := False;
                  PersonnageEquipement.Quantite          := StrToIntDef(TabMetierEquipement.Cells[5, IndTab], 1);
                  Personnage.Equipement                  += [PersonnageEquipement];
                end;
              StringsCodeEns.Free;
              StringsTypeEns.Free;
            end
          else
            begin
              PersonnageEquipement.CodeEquipement          := TabMetierEquipement.Cells[1, IndTab];
              PersonnageEquipement.QualiteEquipement       := QualiteDepuisCode(PersonnageEquipement.CodeEquipement);
              PersonnageEquipement.TypeEquipement          := TabMetierEquipement.Cells[6, IndTab];
              // Fabrication D'ORIGINE (gromril, Jade Longsword...) : posee seulement si le
              // joueur n'a pas deja un (Q) a choisir. CONTEXT.md 2.29.
              if PersonnageEquipement.QualiteEquipement = '' then
                PersonnageEquipement.QualiteEquipement := FabricationDuCatalogue(PersonnageEquipement.CodeEquipement, PersonnageEquipement.TypeEquipement);
              // Comme un achat en jeu (winpersonnage.pas) : l'equipement de depart arrive
              // non porte, a cocher explicitement ensuite.
              PersonnageEquipement.Porte                   := False;
              // Col 5, cachee : quantite posee par AfficheImageMetier (CONTEXT.md 2.77).
              // Vide (choix multiple, ou aucune quantite du livre) = 1 exemplaire.
              PersonnageEquipement.Quantite                := StrToIntDef(TabMetierEquipement.Cells[5, IndTab], 1);
              Personnage.Equipement                        += [PersonnageEquipement];
            end;
        end;
      end;

    procedure PhaseSaveSauvegarde();
      var
        Xp: Integer;
        directoryPath: String;
      begin
      if ValVersion = 'WFRP1' then
        Xp := 0   // V1 : pas encore de calcul d'XP (evolution du personnage a venir dans WinPersonnage)
      else
        begin
          AjouteEffetsClan();
          AjouteEffetsFamilier();
          AjouteTalentSigne();
          Xp := XmlCalculXp();
        end;
      Personnage.LivresAcceptes:=LivresPersonnages;
      directoryPath := GetCurrentDir+ConstCheminPersonnage+EditNomPersonnag.text;
      // installation neuve : SAVED_CARACTERS\<version> n'existe pas encore (CreateDir n'est pas recursif)
      ForceDirectories(GetCurrentDir+ConstCheminPersonnage);
      if not CreateDir(directoryPath) then
          ShowMessage(GetTexteLibelle('RULES-MESS_001')+' '+directoryPath)
      else
        begin
          if PersonnageXmlCreation(Personnage, Xp, Xp, directoryPath + '\' + FormatDateTime('yyyymmdd', Date) + '-' + FormatDateTime('hhnnss', Time) + '.xml', EditNomPersonnag.text) then
            begin
              NeedUpdate          := true;
              RecherchePersonnage := EditNomPersonnag.text;
              close;
            end
          else
            ShowMessage(GetTexteLibelle('RULES-MESS_066'));
        end;
      end;

    // V1 : le personnage est assemble d'un coup depuis les choix de CreationV1Obj, puis ecrit.
    // Pas de talents (les competences les remplacent), classe enregistree dans Personnage.ClasseV1,
    // equipement du livre en texte seulement (pas de lien vers les objets).
    procedure PhaseSaveCreationV1();
      var
        I:     Integer;
        Codes: TStringList;
        CodeCulte: String;
      begin
      Personnage.CreationAttribut     := [];
      Personnage.CreationCompetence35 := [];
      Personnage.CreationCompetence40 := [];
      Personnage.MetierAncien         := [];
      Personnage.MetierCompetence     := [];
      for I := 0 to CreationV1Obj.NbLignes() - 1 do
        begin
          PersonnageAttribut.CodeAttribut := CreationV1Obj.LigneCode(I);
          PersonnageAttribut.Valeur       := CreationV1Obj.LigneValeur(I);
          Personnage.CreationAttribut     += [PersonnageAttribut];
        end;
      // competences de race (acquises d'office, choix « A/B » deja resolus) puis competences de l'age
      for I := 1 to Min(TabRaceCompetence.RowCount - 1, CreationV1Obj.NbCompetencesVoulu()) do
        if CompetenceRaceStates[4, I] then
          begin
            PersonnageCompetence.CodeCompetence := TabRaceCompetence.Cells[1, I];
            PersonnageCompetence.Valeur         := 1;
            Personnage.CreationCompetence35     += [PersonnageCompetence];
          end;
      for I := 0 to CreationV1Obj.NbCompetencesPrises() - 1 do
        begin
          PersonnageCompetence.CodeCompetence := CreationV1Obj.CodePris(I);
          PersonnageCompetence.Valeur         := 1;
          Personnage.CreationCompetence40     += [PersonnageCompetence];
        end;
      Personnage.ClasseV1             := CreationV1Obj.CodeClasse;
      // carriere de base (et metier de l'Artisan)
      PersonnageMetier.CodeMetier   := CreationV1Obj.CodeCarriere;
      PersonnageMetier.NiveauMetier := 1;
      PersonnageMetier.CoutXp       := 0;
      Personnage.MetierEnCours      := PersonnageMetier;
      Personnage.MetierAncien       += [PersonnageMetier];
      // Initiate (Realm of Divine Magic) : choix du culte et quatre prieres Petty de depart
      if EstInitiateV1(CreationV1Obj.CodeCarriere) then
        begin
          CodeCulte := ChoisirCulteV1(Self);
          if CodeCulte <> '' then
            begin
              Personnage.CulteV1 := CodeCulte;
              ShowMessage(GetTexteLibelle('RULES-MESS_111') + ' ' + ChercheCulteV1(CodeCulte).Libelle + #13#10 +
                          GetTexteLibelle('RULES-MESS_112') + ' ' +
                          AccordePrieresInitiateV1(Personnage.SortsV1, ChercheCulteV1(CodeCulte).Libelle));
            end;
        end;
      Codes := TStringList.Create;
      try
        CreationV1Obj.CompetencesCarriere(Codes);
        for I := 0 to Codes.Count - 1 do
          begin
            PersonnageCompetence.CodeCompetence := Codes[I];
            PersonnageCompetence.Valeur         := 1;
            Personnage.MetierCompetence         += [PersonnageCompetence];
          end;
      finally
        Codes.Free;
      end;
      Personnage.MonnaieCO := CreationV1Obj.ArgentDepart();
      // objets choisis dans la liste de prix : ligne Divers a nom libre (nom et encombrement du livre),
      // CodeEquipement garde le code EquipmentV1 pour retrouver l'objet (alerte du familier)
      Personnage.Equipement := [];
      Codes := TStringList.Create;
      try
        CreationV1Obj.ObjetsChoisis(Codes);
        for I := 0 to Codes.Count - 1 do
          begin
            PersonnageEquipement                   := Default(StructurePersonnageEquipement);
            PersonnageEquipement.TypeEquipement    := TrimRight(TypeEquipDi);
            PersonnageEquipement.CodeEquipement    := Codes[I];
            PersonnageEquipement.NomLibre          := ChercheObjetV1(Codes[I]).Libelle;
            PersonnageEquipement.EncLibre          := StrToIntDef(ChercheObjetV1(Codes[I]).Encombrement, 0);
            PersonnageEquipement.Quantite          := 1;
            Personnage.Equipement                  += [PersonnageEquipement];
          end;
      finally
        Codes.Free;
      end;
      // avance gratuite : un pas du schema, sans cout en EP
      Personnage.AvanceGratuiteAttribut := [];
      if (AvanceGratuiteCode <> '') and (PlafondAvanceMetier(MetierEnCours, AvanceGratuiteCode) > 0) then
        begin
          PersonnageAttribut.CodeAttribut := AvanceGratuiteCode;
          PersonnageAttribut.Valeur       := PasAvance(AvanceGratuiteCode);
          PersonnageAttribut.Bonus        := '';
          Personnage.AvanceGratuiteAttribut += [PersonnageAttribut];
        end;
      PhaseSaveSauvegarde();
      end;

    // V1 : l'ordre des onglets n'est pas celui des autres versions ; on enregistre selon l'onglet quitte
    procedure PhaseSaveV1();
      begin
      if NouvellePhase < 1 then Exit;
      if PageEtapes.Pages[NouvellePhase - 1] = TabSheetRace then
        begin
          PhaseSaveRace();
          CreationV1Obj.ChoisitRace(RaceEnCours);
        end;
      // caracteristiques et classe : gardees par CreationV1Obj jusqu'a l'enregistrement du personnage,
      // qui a lieu en quittant l'onglet du nom
      if PageEtapes.Pages[NouvellePhase - 1] = TabSheetNom then
        PhaseSaveCreationV1();
      end;

  Begin
    if ValVersion = 'WFRP1' then
      begin
        PhaseSaveV1();
        Exit;
      end;
    // supprimer les éléments des phases suivants
    // NouvellePhase est la phase où l'on ARRIVE : chaque branche enregistre donc le résultat de
    // la phase précédente et efface ce qui vient après.
    case NouvellePhase of
      1: Begin         // Livres
           // Le choix des livres vient d'être quitté. Rien à enregistrer ici : LivresPersonnages
           // est déjà tenu à jour par TabLivreDblClick, et il n'est recopié dans le personnage
           // qu'à la sauvegarde finale (phase 9).
           //
           // Pas d'invalidation à prévoir non plus : la création n'avance que vers l'avant
           // (ButtonPhaseSuivante -> ChangementPhase(ConstSuivant), il n'existe aucun bouton
           // retour, et les onglets des autres phases sont TabVisible=False). Le jour où un
           // retour arrière existera, c'est ici qu'il faudra tout remettre à zéro.
         end;

      2: PhaseSaveRace();
      3: PhaseSaveMetier();
      4: PhaseSaveAttributs();
      5: PhaseSaveTalents();
      6: PhaseSaveCompetencesRace();
      7: PhaseSaveCompetencesMetier();
      8: PhaseSaveEquipements();
      9: PhaseSaveSauvegarde();
      end;
  end;

// Entrer dans une carriere ouvre le droit a une APPARTENANCE (regiment, ordre de
// chevalerie, culte). A la creation il n'y a pas de garde de niveau : on est par
// definition au niveau 1. Rien n'est propose s'il ne reste aucun candidat.
// CONTEXT.md 2.44.
procedure TWinCreations.ChoisitAppartenance();
  var
    CandidatsAppart: String;
  begin
    CandidatsAppart := AppartenancesCandidates(MetierEnCours, Personnage.Race,
                                               Personnage.Appartenance);
    if CandidatsAppart <> '' then
      begin
        ChoixWinTypeFichier         := ConstXmlDataCareerBonus;
        ChoixWinCareerBonus         := CandidatsAppart;
        // Remise a vide OBLIGATOIRE : fermer la fenetre sans double-cliquer ne
        // touche pas a SelectWin..., qui garderait sinon une reponse precedente.
        SelectWinCareerBonus        := '';
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        if SelectWinCareerBonus <> '' then
          if Trim(Personnage.Appartenance) = '' then
            Personnage.Appartenance := SelectWinCareerBonus
          else
            Personnage.Appartenance := Personnage.Appartenance + ',' + SelectWinCareerBonus;
      end;
  end;

// V2 : la competence d'une appartenance (culte de l'Initiate...) est ACQUISE a la
// creation, en plus de celles de la carriere. Prises comme dans la grille : la valeur
// d'une entree = nombre de prises (PdfPersonnageCompetence prend le max des deux listes),
// donc une competence deja prise s'ajoute (2 prises = +10 %, Skill Mastery, Core p.90).
procedure TWinCreations.AcquiertCompetencesAppartenanceV2();
  var
    Apparts, Codes:  TStringList;
    Paliers:         TListCareerBonusNiveau;
    Palier:          StructureCareerBonusNiveau;
    PerComp:         StructurePersonnageCompetence;
    IndApp, IndCode, IndPrise: Integer;
    Prises:          Integer;
    Trouve:          Boolean;
  begin
    if Trim(Personnage.Appartenance) = '' then
      Exit;
    Apparts := TStringList.Create;
    Codes   := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Personnage.Appartenance), Apparts);
      for IndApp := 0 to Apparts.Count - 1 do
        begin
          Paliers := NiveauxDuCareerBonus(Trim(Apparts[IndApp]));
          try
            for Palier in Paliers do
              begin
                Codes.Clear;
                if Trim(Palier.ListeCompetence) <> '' then
                  ExtractStrings([','], [], PChar(Palier.ListeCompetence), Codes);
                for IndCode := 0 to Codes.Count - 1 do
                  begin
                    // un choix "A/B" ou une specialisation a choisir n'est pas acquis ici
                    if (Pos(SeparateurMulti, Codes[IndCode]) > 0) or (Pos(ValeurGenerique, Codes[IndCode]) > 0) then
                      continue;
                    Trouve := False;
                    for IndPrise := 0 to High(Personnage.CreationCompetence40) do
                      if CompareRechercheValeur(Personnage.CreationCompetence40[IndPrise].CodeCompetence, Trim(Codes[IndCode])) then
                        begin
                          Inc(Personnage.CreationCompetence40[IndPrise].Valeur);
                          Trouve := True;
                          break;
                        end;
                    if not Trouve then
                      begin
                        Prises := 1;
                        for PerComp in Personnage.CreationCompetence35 do
                          if CompareRechercheValeur(PerComp.CodeCompetence, Trim(Codes[IndCode])) then
                            begin
                              Prises := 2;
                              break;
                            end;
                        PerComp                := Default(StructurePersonnageCompetence);
                        PerComp.CodeCompetence := Trim(Codes[IndCode]);
                        PerComp.Valeur         := Prises;
                        Personnage.CreationCompetence40 += [PerComp];
                      end;
                  end;
              end;
          finally
            Paliers.Free;
          end;
        end;
    finally
      Codes.Free;
      Apparts.Free;
    end;
  end;

Procedure TWinCreations.TalentFenetre(Choix: Integer; CodeTalent: String);
  BEGIN
    // ouvrir les Talents
    if (Choix = 1) and (FirstClick1 = true) then
        FirstClick1 := false
    else if (choix = 2) and (FirstClick2 = true) then
        FirstClick2 := false
    else if (choix = 3) and (FirstClick3 = true) then
        FirstClick3 := false
    else if (choix = 4) and (FirstClick4 = true) then
        FirstClick4 := false
    else if (CodeTalent <> '') then
      begin
        SelectWinTalent     := CodeTalent;
        FenTalent           := TWintTalent.Create(Application);
        FenTalent.Position  := poOwnerFormCenter;
        FenTalent.ShowModal;
        SelectWinTalent     := '';
        ChoixWinTalent      := '';
      end;
  end;

Procedure TWinCreations.CompetenceFenetre(CodeCompetence: String);
  BEGIN
      SelectWinCompetence     := CodeCompetence;
      FenCompetence           := TWinCompetence.Create(Application);
      FenCompetence.Position  := poOwnerFormCenter;
      FenCompetence.ShowModal;
      SelectWinCompetence     := '';
      ChoixWinCompetence      := '';
  end;

Procedure TWinCreations.RaceFenetre(CodeRace: String);
  BEGIN
      SelectWinRace     := CodeRace;
      FenRace           := TWinRace.Create(Application);
      FenRace.Position  := poOwnerFormCenter;
      FenRace.ShowModal;
      SelectWinRace     := '';
      ChoixWinRace      := '';
  end;

Procedure TWinCreations.MetierFenetre(CodeMetier: String);
  BEGIN
      SelectWinMetier     := CodeMetier;
      FenMetier           := TWinMetiers.Create(Application);
      FenMetier.Position  := poOwnerFormCenter;
      FenMetier.ShowModal;
      SelectWinMetier     := '';
      ChoixWinMetierRace  := '';
  end;


procedure TWinCreations.RecapAttributSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
  begin
    Editor := nil;
  end;

procedure TWinCreations.RecapCompDblClick(Sender: TObject);
  begin
    CompetenceFenetre(RecapComp.Cells[5, RecapComp.Row]);
  end;

procedure TWinCreations.RecapCompSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
  begin
    Editor := nil;
  end;

procedure TWinCreations.RecapTalentDblClick(Sender: TObject);
  begin
    TalentFenetre(0,RecapTalent.Cells[2,RecapTalent.Row]);
  end;

procedure TWinCreations.RecapTalentSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
  begin
    Editor := nil;
  end;

procedure TWinCreations.TabCreationHasardDblClick(Sender: TObject);
  var
    Ind:      Integer;
    Source:   String;
    CodeParentLigne:   String;
    Jet:      Integer;
    CodeTire: String;
  begin
    if TabCreationHasard.Row < 1 then Exit;

    // colonne spécialisation : choisir la spécialité du talent tiré
        if TabCreationHasard.Col = ColHasLibSpe then
          begin
            if Pos(ValeurGenerique, TabCreationHasard.Cells[ColHasSel, TabCreationHasard.Row]) = 0 then Exit;
            ChoixWinTypeFichier := ConstXmlSousChapitreTalent;
            ChoixWinTalent      := TabCreationHasard.Cells[ColHasSel, TabCreationHasard.Row];
            SelectWinTalent     := '';
            FenSpecialisation           := TWinSpecialisations.Create(Application);
            FenSpecialisation.Position  := poOwnerFormCenter;
            FenSpecialisation.ShowModal;
            if SelectWinTalent = '' then Exit;

            for Ind := 0 to High(ListeChoixCreation) do
              if (ListeChoixCreation[Ind].CodeSource = TabCreationHasard.Cells[ColHasSource, TabCreationHasard.Row])
                 and (ListeChoixCreation[Ind].CodeParent = TabCreationHasard.Cells[ColHasParent, TabCreationHasard.Row])
                   and (ListeChoixCreation[Ind].Rang = StrToIntDef(TabCreationHasard.Cells[ColHasRang, TabCreationHasard.Row], 0)) then
                begin
                  ListeChoixCreation[Ind].CodeSpecialise := SelectWinTalent;
                  break;
                end;
            ReconstruitChoixCreation();
            Exit;
          end;

    Source := TabCreationHasard.Cells[ColHasSource, TabCreationHasard.Row];
    CodeParentLigne := TabCreationHasard.Cells[ColHasParent, TabCreationHasard.Row];

    ChoixWinJetRace := RaceEnCours;
    ChoixWinJetValeur := StrToIntDef(TabCreationHasard.Cells[ColHasJet, TabCreationHasard.Row], 0);
    ChoixWinJetDeja := ListeTalentsDejaPris(TabCreationHasard.Cells[ColHasSel, TabCreationHasard.Row]);
    FenLanceDe                 := TWinLanceDes.Create(Application);
    FenLanceDe.Position        := poOwnerFormCenter;
    FenLanceDe.ShowModal;
    ChoixWinJetDeja.Free;
    ChoixWinJetDeja := nil;
    if SelectWinJetTalent = '' then Exit;
    Jet      := SelectWinJet;
    CodeTire := SelectWinJetTalent;

    for Ind := 0 to High(ListeChoixCreation) do
          if (ListeChoixCreation[Ind].CodeSource = Source)
             and (ListeChoixCreation[Ind].CodeParent = CodeParentLigne)
               and (ListeChoixCreation[Ind].Rang = StrToIntDef(TabCreationHasard.Cells[ColHasRang, TabCreationHasard.Row], 0)) then
        begin
          ListeChoixCreation[Ind].Jet        := Jet;
          ListeChoixCreation[Ind].CodeChoisi := CodeTire;
          ListeChoixCreation[Ind].CodeSpecialise := '';
          break;
        end;

    ReconstruitChoixCreation();
  end;

procedure TWinCreations.TabCreationHasardPrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
  begin
    if aRow < 1 then Exit;
    if TabCreationHasard.Cells[ColHasSel, aRow] = '' then
      TabCreationHasard.Canvas.Brush.Color := CouleurFondNot;
  end;

procedure TWinCreations.TabCreationChoixDblClick(Sender: TObject);
  var
    Ind:    Integer;
    Source: String;
    CodeParentLigne: String;
    ListOptLigne: TStringList;
    RienAChoisir: Boolean;
  begin
    if TabCreationChoix.Row < 1 then Exit;
    Source := TabCreationChoix.Cells[ColChoixSource, TabCreationChoix.Row];
    CodeParentLigne := TabCreationChoix.Cells[ColChoixParent, TabCreationChoix.Row];

    // Une ligne dont la source est un talent CONCRET n'a rien a choisir : c'est un talent
    // accorde sec par une option de trait (CONTEXT.md 2.41). Sans cette garde, le double
    // clic ouvrirait le catalogue COMPLET des talents - ChargeSpecialisation bascule sur
    // le catalogue des qu'un code n'a ni '/' ni '_*' - et laisserait le joueur remplacer
    // un talent que le livre lui impose.
    if ChercheTrait(Source).CodeTrait = '' then
      begin
        ListOptLigne := ListeTalent(Source);
        RienAChoisir := (ListOptLigne.Count = 0);
        ListOptLigne.Free;
        if RienAChoisir then
          Exit;
      end;

    ChoixWinTypeFichier        := ConstXmlSousChapitreTalent;
    ChoixWinTalent             := Source;
    SelectWinTalent            := '';
    FenSpecialisation          := TWinSpecialisations.Create(Application);
    FenSpecialisation.Position := poOwnerFormCenter;
    FenSpecialisation.ShowModal;

    if SelectWinTalent <> '' then
      begin
        for Ind := 0 to High(ListeChoixCreation) do
          if (ListeChoixCreation[Ind].CodeSource = Source)
             and (ListeChoixCreation[Ind].CodeParent = CodeParentLigne)
               and (ListeChoixCreation[Ind].Rang = StrToIntDef(TabCreationChoix.Cells[ColChoixRang, TabCreationChoix.Row], 0)) then            begin
              ListeChoixCreation[Ind].CodeChoisi := SelectWinTalent;
              break;
            end;
        ReconstruitChoixCreation();
      end;
    SelectWinTalent := '';
  end;

procedure TWinCreations.TabCreationChoixPrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
  begin
    if aRow < 1 then Exit;
    if TabCreationChoix.Cells[ColChoixSel, aRow] = '' then
      TabCreationChoix.Canvas.Brush.Color := CouleurFondNot;
  end;

procedure TWinCreations.TabLivreDblClick(Sender: TObject);
  var
    ind:  Integer;
  begin
    // cocher ou décocher le livre en cours (sauf RULESBOOK qui est en 1)
    if (TabLivre.Row > 1) then
      if TabLivre.Cells[2, TabLivre.Row] <> '' then
        if TabLivre.Cells[1, TabLivre.Row] <> ConstSelectionne then
          TabLivre.Cells[1, TabLivre.Row] := ConstSelectionne
        else
          TabLivre.Cells[1, TabLivre.Row] := '';

     // actualiser les livres que se personnages veut prendre en compte
     LivresPersonnages := '';
     for Ind := 1 to TabLivre.RowCount - 1 do
       if TabLivre.Cells[1, Ind] = ConstSelectionne then
         LivresPersonnages := LivresPersonnages + AjouteAccolade(TabLivre.Cells[3, Ind]);

     // les regles proposees suivent les livres coches
     if Assigned(PanneauRegles) then
       begin
         PanneauRegles.FiltreLivres := LivresPersonnages;
         PanneauRegles.Charger();
       end;
     ReglesChangees(nil);
  end;

// Une regle vient d'etre cochee / decochee, ou un livre ajoute / retire : la liste des regles de
// tirage proposees pour la race en cours est recalculee.
procedure TWinCreations.ReglesChangees(Sender: TObject);
  begin
    if RaceEnCours <> '' then
      ChargeComboRegle();
  end;

procedure TWinCreations.TabMetierCompetenceDblClick(Sender: TObject);
  begin
    if (TabMetierCompetence.Cells[5, TabMetierCompetence.Row] = ConstArbreAuChoix) then
      begin
        ChoixWinTypeFichier         := ConstXmlSousChapitreCompetence;
        ChoixWinCompetence          := TabMetierCompetence.Cells[6, TabMetierCompetence.Row];
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        if SelectWinCompetence <> '' then
          begin
            TabMetierCompetence.Cells[5, TabMetierCompetence.Row] := '';
            TabMetierCompetence.Cells[1, TabMetierCompetence.Row] := SelectWinCompetence;
            TabMetierCompetence.Cells[3, TabMetierCompetence.Row] := SelWinLibelle;
          end;
      end
    else
      CompetenceFenetre(TabMetierCompetence.Cells[1, TabMetierCompetence.Row]);
  end;

procedure TWinCreations.TabMetierEquipementDblClick(Sender: TObject);
var
  Codes:           TStringList;
  Quantites:       TStringList;
  IndChoix:        Integer;
  QuantiteChoisie: Integer;
begin
  if TabMetierEquipement.Cells[2, TabMetierEquipement.Row] = ConstArbreAuChoix then
    begin
      ChoixWinTypeFichier         := ConstXmlChapitreEquipement;
      ChoixWinEquipement          := TabMetierEquipement.Cells[3, TabMetierEquipement.Row];
      FenSpecialisation           := TWinSpecialisations.Create(Application);
      FenSpecialisation.Position  := poOwnerFormCenter;
      FenSpecialisation.ShowModal;
      if SelectWinEquipement <> '' then
        begin
          TabMetierEquipement.Cells[1, TabMetierEquipement.Row] := SelectWinEquipement;
          // Quantite de la branche retenue : meme rang dans la col 7 que le code dans la col 3.
          // Sans correspondance (ou sans quantite par branche), on garde celle de l'item.
          QuantiteChoisie := StrToIntDef(TabMetierEquipement.Cells[5, TabMetierEquipement.Row], 1);
          if TabMetierEquipement.Cells[7, TabMetierEquipement.Row] <> '' then
            begin
              Codes      := TStringList.Create;
              Quantites  := TStringList.Create;
              try
                ExtractStrings([','], [], PChar(TabMetierEquipement.Cells[3, TabMetierEquipement.Row]), Codes);
                ExtractStrings([','], [], PChar(TabMetierEquipement.Cells[7, TabMetierEquipement.Row]), Quantites);
                IndChoix := Codes.IndexOf(SelectWinEquipement);
                if (IndChoix >= 0) and (IndChoix < Quantites.Count) then
                  QuantiteChoisie := StrToIntDef(Quantites[IndChoix], 1);
              finally
                Codes.Free;
                Quantites.Free;
              end;
            end;
          TabMetierEquipement.Cells[2, TabMetierEquipement.Row] := SelWinLibelle + QuantiteSuffixe(QuantiteChoisie);
          TabMetierEquipement.Cells[4, TabMetierEquipement.Row] := '';
          TabMetierEquipement.Cells[5, TabMetierEquipement.Row] := IntToStr(QuantiteChoisie);
          TabMetierEquipement.Cells[6, TabMetierEquipement.Row] := SelWinType;
        end;
    end;
end;

procedure TWinCreations.TabRaceCompetenceDblClick(Sender: TObject);
  begin
    // Meme moule que TabMetierCompetenceDblClick, mais SANS colonne technique : un code
    // d'ethnie encore au choix se reconnait a lui seul - il porte ValeurGenerique
    // ("Trade (Any)") ou SeparateurMulti ("Trade (Farming or Mining)"). Une fois resolu il
    // ne porte plus ni l'un ni l'autre, donc la condition s'eteint d'elle-meme.
    // CONTEXT.md 2.45.
    if (Pos(ValeurGenerique, TabRaceCompetence.Cells[1, TabRaceCompetence.Row]) > 0) or
       (Pos(SeparateurMulti, TabRaceCompetence.Cells[1, TabRaceCompetence.Row]) > 0) then
      begin
        ChoixWinTypeFichier         := ConstXmlSousChapitreCompetence;
        ChoixWinCompetence          := TabRaceCompetence.Cells[1, TabRaceCompetence.Row];
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        if SelectWinCompetence <> '' then
          begin
            TabRaceCompetence.Cells[1, TabRaceCompetence.Row] := SelectWinCompetence;
            TabRaceCompetence.Cells[3, TabRaceCompetence.Row] := SelWinLibelle;
          end;
      end
    else
      CompetenceFenetre(TabRaceCompetence.Cells[1, TabRaceCompetence.Row]);
  end;

procedure TWinCreations.TabTalentDblClick(Sender: TObject);
  begin
    TalentFenetre(0, TabTalent.Cells[1, TabTalent.Row]);
  end;

// V2 : la carriere a-t-elle un materiel de depart en donnees (niveau 1) ?
function MetierAMaterielDepart(const CodeMetier: String): Boolean;
  var
    PMetierEquipement: StructureMetierEquipement;
  begin
    Result := False;
    for PMetierEquipement in ListMetierEquipement do
      if CompareRechercheValeur(PMetierEquipement.CodeMetier, CodeMetier) and (PMetierEquipement.NiveauMetier = 1) then
        Exit(True);
  end;

procedure TWinCreations.ChangementPhase(Changement: Integer);
  var
    i: Integer;
    TabSheet: TTabSheet;
    SautSave: Boolean;
  begin
    SautSave := False;
    if (PhaseEnCours <> -1) and (Changement > 0) and (not PageEtapesChange()) then
      begin
         Exit;
      end;
    if SousPhaseClan then
      begin
        // Fin de la phase 2.1 : la race est deja enregistree (PhaseSaveRace), on y ajoute le clan
        Personnage.NaissanceV2 := ClanChoisi;
        SousPhaseClan          := False;
        SautSave               := True;
        // La race a aussi une mutation de depart : phase 2.2 avant de passer au metier
        if RaceAMutationDepart(RaceEnCours) then
          begin
            AfficheSousPhaseMutation();
            Exit;
          end;
        if RaceATirageFamilier(RaceEnCours) then
          begin
            AfficheSousPhaseFamilier();
            Exit;
          end;
        if FondActif() then
          begin
            AfficheSousPhaseFond();
            Exit;
          end;
      end
    else if SousPhaseMutation then
      begin
        // Fin de la phase 2.2 : la race est deja enregistree (PhaseSaveRace), on y ajoute la mutation
        Personnage.Mutations   += [MutationDepart];
        SousPhaseMutation      := False;
        SautSave               := True;
        if RaceATirageFamilier(RaceEnCours) then
          begin
            AfficheSousPhaseFamilier();
            Exit;
          end;
        if FondActif() then
          begin
            AfficheSousPhaseFond();
            Exit;
          end;
      end
    else if SousPhaseFamilier then
      begin
        // Fin de la phase 2.3 : la race est deja enregistree (PhaseSaveRace), la forme tiree devient le "lieu de
        // naissance" du familier (affichee sur la fiche) et ses effets sont appliques a l'enregistrement final.
        Personnage.NaissanceV2 := FamilierTexte;
        SousPhaseFamilier      := False;
        SautSave               := True;
        if FondActif() then
          begin
            AfficheSousPhaseFond();
            Exit;
          end;
      end
    else if SousPhaseFond then
      begin
        // Fin de la phase 2.4 (Liber Fanatica) : la race est deja enregistree (PhaseSaveRace) ; le background devient
        // la regle de tirage de la carriere et ses competences/talents sont ajoutes au personnage.
        SousPhaseFond          := False;
        SautSave               := True;
        AppliqueFond();
      end
    else if SousPhaseSigne then
      begin
        // Fin de la phase 4.1 : les caracteristiques sont deja enregistrees (PhaseSaveAttributs), le signe
        // est dans Personnage ; le recapitulatif des caracteristiques prend maintenant son modificateur.
        SousPhaseSigne         := False;
        SautSave               := True;
        MajRecapAttribut();
      end
    else if (Changement > 0) and (PhaseEnCours = TabSheetAttribut.PageIndex) and (NbSigneAstralPermis() > 0) then
      begin
        // Phase intermediaire 4.1 (toutes versions, seulement si un livre charge porte des signes) :
        // les caracteristiques sont enregistrees maintenant, puis l'onglet s'affiche a la place des talents.
        PhaseSave(PhaseEnCours + Changement);
        AfficheSousPhaseSigne();
        Exit;
      end
    else if SousPhaseMutationChance then
      begin
        // Fin de la phase 3.0 : le metier est deja enregistre ; la mutation (si le jet a reussi et qu'elle a ete
        // choisie) est ajoutee ; l'appartenance (3.1) vient ensuite si le metier en propose une.
        SousPhaseMutationChance := False;
        SautSave                := True;
        if MutationDepartOk then
          Personnage.Mutations += [MutationDepart];
        MutationChanceFaite     := True;
        if AppartenancesCandidates(MetierEnCours, Personnage.Race, Personnage.Appartenance) <> '' then
          begin
            AfficheSousPhaseAppartenance();
            Exit;
          end;
      end
    else if (Changement > 0) and (PhaseEnCours = TabSheetMetier.PageIndex) and (not MutationChanceFaite)
            and (ChanceMutationRegle() > 0) then
      begin
        // Phase intermediaire 3.0 (V2) : le metier est enregistre maintenant, puis l'onglet s'affiche a la place
        // des competences ; PhaseEnCours reste au metier.
        PhaseSave(PhaseEnCours + Changement);
        AfficheSousPhaseMutationChance();
        Exit;
      end
    else if SousPhaseAppartenance then
      begin
        // Fin de la phase 3.1 : le metier est deja enregistre (PhaseSaveMetier) et Personnage.Appartenance
        // a ete remplie par le bouton ; les greffes sont appliquees a la phase des competences du metier.
        SousPhaseAppartenance  := False;
        SautSave               := True;
      end
    else if (Changement > 0) and (PhaseEnCours = TabSheetMetier.PageIndex)
            and (AppartenancesCandidates(MetierEnCours, Personnage.Race, Personnage.Appartenance) <> '') then
      begin
        // Phase intermediaire 3.1 (toutes versions) : le metier est enregistre maintenant, puis l'onglet
        // s'affiche a la place des attributs. PhaseEnCours reste au metier.
        PhaseSave(PhaseEnCours + Changement);
        AfficheSousPhaseAppartenance();
        Exit;
      end
    else if (ValVersion = 'WFRP2') and (Changement > 0) and (PhaseEnCours = TabSheetRace.PageIndex)
            and (RaceAClan(RaceEnCours) or RaceAMutationDepart(RaceEnCours) or RaceATirageFamilier(RaceEnCours)
                 or FondActif()) then
      begin
        // Phases intermediaires 2.1 (clan), 2.2 (mutation), 2.3 (familier cree) puis 2.4 (background) : la race est
        // enregistree maintenant (elle efface la naissance et les mutations), puis l'onglet s'affiche a la place du
        // metier. PhaseEnCours reste a la race.
        PhaseSave(PhaseEnCours + Changement);
        if RaceAClan(RaceEnCours) then
          AfficheSousPhaseClan()
        else if RaceAMutationDepart(RaceEnCours) then
          AfficheSousPhaseMutation()
        else if RaceATirageFamilier(RaceEnCours) then
          AfficheSousPhaseFamilier()
        else
          AfficheSousPhaseFond();
        Exit;
      end;
    if not SautSave then
      PhaseSave(PhaseEnCours + changement);
    // V2 : tant que le materiel de depart d'une carriere n'est pas structure (SUBCHAPTER_ITEM, 5 carrieres
    // test faites), la phase du materiel est sautee, mais on enregistre quand meme l'arrivee a la suivante.
    if (ValVersion = 'WFRP2') and (PhaseEnCours + changement = TabSheetEquipement.PageIndex) and (Changement <> 0)
       and (not MetierAMaterielDepart(MetierEnCours)) then
      begin
        Changement := Changement * 2;
        PhaseSave(PhaseEnCours + changement);
      end;
    // V1 : les competences remplacent les talents, la phase des talents est sautee
    if (ValVersion = 'WFRP1') and (PhaseEnCours + changement = TabSheetTalent.PageIndex) and (Changement <> 0) then
      begin
        Changement := Changement * 2;
        PhaseSave(PhaseEnCours + changement);
      end;
    // gérer le changement de phase (avant ou arrière) pour activer/désactiver les onglets
    PhaseEnCours := PhaseEnCours + changement;
    if PhaseEnCours < PhaseDebut then PhaseEnCours := PhaseDebut;
    if PhaseEnCours > PhaseMax   then PhaseEnCours := PhaseMax;
    for i := 0 to PageEtapes.PageCount - 1 do
    begin
      TabSheet := PageEtapes.Pages[i];
      if (i = PhaseEnCours) then
        Begin
          TabSheet.TabVisible := true;
          ButtonLibellePhase.Caption := Format(GetTexteLibelle('RULES-LAB_315'), [i+1, PhaseMax+1, ListPhase[i]]);
          TabSheet.Caption := Format(GetTexteLibelle('RULES-LAB_1002'), [i+1, PhaseMax+1]);
        end
      else
        TabSheet.TabVisible := False;
    end;
    // V2 : la valeur actuelle des caracteristiques n'existe qu'apres la phase 4
    if RaceParGrille() then
      RemplirGridRace();
    if ValVersion = 'WFRP2' then
      RemplirGridAvance();
    if ValVersion = 'WFRP1' then
      AfficheOngletV1();
  end;

procedure TWinCreations.TabMetierEquipementSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
  begin
    Editor := nil;
  end;

Function TWinCreations.PageEtapesChange(): boolean;
  // Phase 0 : choix des livres
  function VerifLivres: Boolean;
    begin
      // Au moins un livre doit rester coché : LivresPersonnages part de LivresCharges
      // (les livres actifs du menu principal), le joueur ne fait qu'en retirer.
      if LivresPersonnages = '' then
         begin
            ShowMessage(GetTexteLibelle('RULES-MESS_056'));
            Result := False;
         end
      else
            Result := true;
    end;

  // Phase 1 : choix de la race
  function VerifRace: Boolean;
    begin
      if RaceEnCours = '' then
         begin
            ShowMessage(GetTexteLibelle('RULES-MESS_002'));
            Result := False;
         end
      else
            Result := true;
    end;

  // Phase 2 : choix du metier
  function VerifMetier: Boolean;
    begin
      if MetierEnCours = '' then
         begin
            ShowMessage(GetTexteLibelle('RULES-MESS_003'));
            Result := False;
         end
      else
            Result := true;
    end;

  // Phase 3 : choix des attributs
  function VerifAttributs: Boolean;
    var
      Vide: Integer;
      IndTab: Integer;
    begin
      Vide  := 0;
      for IndTab := 1 to 10 do
        // V2 : seules les caracteristiques a formule de des ont un jet (8 sur 10 lignes)
        If (TabAttribut.Cells[5, Indtab] = '') and (Pos('+', TabAttribut.Cells[4, Indtab]) > 0) then
          Vide := Vide+1;

      if Vide > 0 then
          begin
           ShowMessage(GetTexteLibelle('RULES-MESS_004'));
           Result := False;
          end
        else if RadioButtonAttributRepartition.Checked and (StrToIntDef(TabAttributLanceDe.Cells[11, 1], 0) <> 100) then
          begin
           ShowMessage(GetTexteLibelle('RULES-MESS_065'));
           Result := False;
          end
        else
           Result := true;
    end;

  // Phase 4 : choix des talents
  function VerifTalents: Boolean;
    var
      Ok: Boolean;
    begin
      Ok := True;
      if not ChoixCreationComplet() then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_005'));
          Ok := False;
        end;
      result := Ok;
    end;

  // Phase 5 : choix des competences de race
  function VerifCompetencesRace: Boolean;
    var
      Ok: Boolean;
      IndTab: Integer;
      PRaceNb: StructureRace;
    begin
      Ok := True;
      // Le nombre attendu vient de l'ethnie, il n'est plus ecrit en dur : toutes les
      // races du livre de regles en prennent 3 et 3, le Skink de Lustria 2 et 2
      // (CONTEXT.md 2.15). MESS_013/014 portent un %d, d'ou le Format.
      PRaceNb := ChercheRace(RaceEnCours);
      if (ValVersion <> 'WFRP2') and (NbCinq <> PRaceNb.NbPoint5) and (Ok) then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-MESS_013'), [PRaceNb.NbPoint5]));
          Ok := False;
        end;
      if (ValVersion <> 'WFRP2') and (NbTrois <> PRaceNb.NbPoint3) and (Ok) then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-MESS_014'), [PRaceNb.NbPoint3]));
          Ok := False;
        end;
      // Pendant de la branche 6 : on refuse de quitter la phase tant qu'une ligne
      // COCHEE porte encore un code non resolu. Ici la "quantite saisie" est une case
      // a cocher, d'ou le test sur CompetenceRaceStates[4] / [5]. CONTEXT.md 2.45.
      for IndTab := 1 to TabRaceCompetence.RowCount - 1 do
        if (CompetenceRaceStates[4, IndTab] or CompetenceRaceStates[5, IndTab]) and
           ((Pos(ValeurGenerique, TabRaceCompetence.Cells[1, IndTab]) > 0) or
            (Pos(SeparateurMulti, TabRaceCompetence.Cells[1, IndTab]) > 0)) then
          begin
            ShowMessage(GetTexteLibelle('RULES-MESS_042'));
            Ok := False;
          end;
      result := Ok;
    end;

  // Phase 6 : choix des competences de metier
  function VerifCompetencesMetier: Boolean;
    var
      Ok: Boolean;
      IndTab: Integer;
    begin
      Ok := True;
      if (ValVersion <> 'WFRP2') and (TotalMetierCompetence <> 40) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_015'));
          Ok := False;
        end;
      for IndTab := 1 to TabMetierCompetence.RowCount - 1 do
        if (StrToIntDef(TabMetierCompetence.Cells[4, IndTab],0) <> 0) and (TabMetierCompetence.Cells[5, IndTab] = ConstArbreAuChoix) then
          begin
            ShowMessage(GetTexteLibelle('RULES-MESS_042'));
            Ok := False;
          end;
      result := Ok;
    end;

  // Phase 7 : choix des equipements
  function VerifEquipement: Boolean;
    var
      Ok: Boolean;
      IndTab: Integer;
    begin
      Ok := True;
      for IndTab := 1 to TabMetierEquipement.RowCount - 1 do
        If (TabMetierEquipement.Cells[1, IndTab] = '') then
          begin
            ShowMessage(GetTexteLibelle('RULES-MESS_016'));
            Ok := False;
            Break;
          end;
      result := Ok;
    end;

  // Phase 8 : choix du nom de personnage
  function VerifNom: Boolean;
    var
      Ok: Boolean;
    begin
      Ok := True;
      // Un espace en debut/fin est invisible pour Nono mais casse la creation du
      // dossier : CreateDir l'accepte en le tronquant silencieusement, puis
      // l'ecriture du XML avec le nom non tronque echoue (dossier vide) - crash au
      // demarrage suivant en tentant de charger un personnage sans fichier XML.
      EditNomPersonnag.text := Trim(EditNomPersonnag.text);
      if EditNomPersonnag.text = '' then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_017'));
          Ok := False;
        end
      else
        begin
          if DirectoryExists(GetCurrentDir+ConstCheminPersonnage+EditNomPersonnag.text) then
            begin
              ShowMessage(GetTexteLibelle('RULES-MESS_018'));
              Ok := False;
            end;
        end;
      result := Ok;
    end;

  // Phase intermediaire 2.1 : un clan doit etre choisi (liste ou tirage)
  function VerifClan: Boolean;
    begin
      Result := ClanChoisi <> '';
      if not Result then
        ShowMessage(GetTexteLibelle('RULES-MESS_078'));
    end;

  begin
    Result := True;
    if SousPhaseClan then
      begin
        Result := VerifClan;
        Exit;
      end;
    // Phase 3.1 : l'appartenance reste facultative (comme l'ancienne fenetre, qu'on pouvait fermer)
    if SousPhaseAppartenance or SousPhaseSigne then
      Exit;
    // Phase 3.0 : passer sans lancer le jet (ou apres un echec) est permis ; un jet reussi exige la mutation
    if SousPhaseMutationChance then
      begin
        Result := not ((MutationChanceJet > 0) and (MutationChanceJet <= ChanceMutationRegle()) and (not MutationDepartOk));
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_079'));
        Exit;
      end;
    if SousPhaseMutation then
      begin
        Result := MutationDepartOk;
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_079'));
        Exit;
      end;
    if SousPhaseFond then
      begin
        Result := FondComplet();
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_108', 'Roll the d10 and settle every choice before continuing.'));
        Exit;
      end;
    if SousPhaseFamilier then
      begin
        Result := FamilierTexte <> '';
        if not Result then
          ShowMessage(GetTexteLibelle('RULES-MESS_080'));
        Exit;
      end;
    if (ValVersion = 'WFRP1') and (PhaseEnCours > 0) then
      begin
        Result := VerifOngletV1();
        Exit;
      end;
    case PhaseEnCours of
      0: Result := VerifLivres;
      1: Result := VerifRace;
      2: Result := VerifMetier;
      3: Result := VerifAttributs;
      4: Result := VerifTalents;
      5: Result := VerifCompetencesRace;
      6: Result := VerifCompetencesMetier;
      7: Result := VerifEquipement;
      8: Result := VerifNom;
    end;
  end;

procedure TWinCreations.ButtonPhaseSuivanteClick(Sender: TObject);
  begin
    ChangementPhase(ConstSuivant);
  end;

// Details physiques : meme fenetre que sur la fiche (WinPersonnage). Le resultat va
// directement dans Personnage, ecrit a la sauvegarde de la phase 9.
procedure TWinCreations.ButtonPhysiqueClick(Sender: TObject);
  var
    FenPhysique: TWinPhysique;
  begin
    PhysiqueCodeRace := Personnage.Race;
    PhysiqueAge      := Personnage.Age;
    // V1 : age de l'etape des competences (non modifiable ici), taille selon le sexe, ni yeux ni cheveux
    PhysiqueV1       := ValVersion = 'WFRP1';
    if PhysiqueV1 then
      begin
        PhysiqueCodeRace := ChercheRace(RaceEnCours).Espece;
        PhysiqueAge      := CreationV1Obj.AgeChoisi();
      end;
    PhysiqueTaille   := Personnage.Height;
    PhysiqueUnite    := Personnage.HeightUnit;
    PhysiqueYeux     := Personnage.EyeColors;
    PhysiqueCheveux  := Personnage.HairColors;
    PhysiqueV2        := ValVersion = 'WFRP2';
    PhysiqueSexeSeul  := (ValVersion <> 'WFRP1') and (ValVersion <> 'WFRP2');
    PhysiqueFemme     := Personnage.SexeV2 = 'F';
    PhysiquePoids     := Personnage.PoidsV2;
    PhysiqueFratrie   := Personnage.FratrieV2;
    PhysiqueSigne     := Personnage.SigneDistinctifV2;
    PhysiqueNaissance := Personnage.NaissanceV2;
    PhysiqueAstre     := Personnage.AstreV2;
    FenPhysique          := TWinPhysique.Create(Application);
    FenPhysique.Position := poOwnerFormCenter;
    try
      FenPhysique.ShowModal;
    finally
      FenPhysique.Free;
      PhysiqueV1 := False;
    end;
    if PhysiqueValide and (ValVersion = 'WFRP1') then
      begin
        Personnage.Age        := PhysiqueAge;
        Personnage.Height     := PhysiqueTaille;
        Personnage.HeightUnit := PhysiqueUnite;
        Personnage.SexeV2     := IfThen(PhysiqueFemme, 'F', 'M');
        LabPhysiqueResume.Text := IntToStr(Personnage.Age) + ' - ' + FormateTaille(Personnage.Height, Personnage.HeightUnit)
                                     + ' - ' + IfThen(PhysiqueFemme, GetTexteLibelle('RULES-LAB_743'), GetTexteLibelle('RULES-LAB_744'));
      end
    else if PhysiqueValide then
      begin
        Personnage.Age        := PhysiqueAge;
        Personnage.Height     := PhysiqueTaille;
        Personnage.HeightUnit := PhysiqueUnite;
        Personnage.EyeColors  := PhysiqueYeux;
        Personnage.HairColors := PhysiqueCheveux;
        Personnage.SexeV2            := IfThen(PhysiqueFemme, 'F', 'M');
        Personnage.PoidsV2           := PhysiquePoids;
        Personnage.FratrieV2         := PhysiqueFratrie;
        Personnage.SigneDistinctifV2 := PhysiqueSigne;
        Personnage.NaissanceV2       := PhysiqueNaissance;
        Personnage.AstreV2           := PhysiqueAstre;
        LabPhysiqueResume.Text := IntToStr(Personnage.Age) + ' - ' + FormateTaille(Personnage.Height, Personnage.HeightUnit)
                                     + ' - ' + Personnage.HairColors + ' - ' + Personnage.EyeColors;
      end;
  end;

// Generateur de noms de l'ethnie (Rulebook p.38-39, Dwarf Player's Guide p.39) : le resultat
// remplace le contenu du champ Nom, que le joueur peut ensuite retoucher.
procedure TWinCreations.EditJetNomChange(Sender: TObject);
  begin
    FJetNomSaisi := True;
  end;

procedure TWinCreations.EditJetNomKeyPress(Sender: TObject; var Key: Char);
  begin
    if not (Key in ['0'..'9', '/', #8, #13]) then
      Key := #0;
  end;

procedure TWinCreations.ButtonNomClick(Sender: TObject);
  var
    Nom, Jets: String;
  begin
    if not RaceANoms(Personnage.Race) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_270'));
        Exit;
      end;
    // Jet saisi a la main : on le rejoue ; sinon tirage, et le champ montre les jets tires.
    if FJetNomSaisi then
      Jets := Trim(EditJetNom.Text)
    else
      Jets := '';
    Nom := TireNomJets(Personnage.Race, IfThen(ComboBoxSexeNom.ItemIndex = 1, 'F', 'M'), IfThen(ComboBoxRegleNom.ItemIndex > 0, CodesRegleNom[ComboBoxRegleNom.ItemIndex], ''), Jets);
    EditJetNom.Text := Jets;
    FJetNomSaisi    := False;
    if Nom = '' then
      ShowMessage(GetTexteLibelle('RULES-LAB_270'))
    else
      EditNomPersonnag.Text := Nom;
  end;

// Hasard de la derniere phase : sexe et nom (un nom deja pris par un autre personnage est
// retire), details physiques, puis signe astral si un livre en propose (le signe tire donne
// +25 XP, comme ButtonSigneClick) avec sa specialisation au hasard s'il accorde un talent generique.
procedure TWinCreations.ButtonNomHasardClick(Sender: TObject);
  var
    Nom, Yeux, Cheveux: String;
    SexeTire:           String;
    Essai, Age, Taille: Integer;
    DetailsV2:          StructureDetailsV2;
  begin
    // 1 - nom
    if RaceANoms(Personnage.Race) then
      begin
        ComboBoxSexeNom.ItemIndex := Random(2);
        for Essai := 1 to 20 do
          begin
            Nom := TireNom(Personnage.Race, IfThen(ComboBoxSexeNom.ItemIndex = 1, 'F', 'M'),
                           IfThen(ComboBoxRegleNom.ItemIndex > 0, CodesRegleNom[ComboBoxRegleNom.ItemIndex], ''));
            if (Nom <> '') and not DirectoryExists(GetCurrentDir + ConstCheminPersonnage + Trim(Nom)) then
              Break;
          end;
        if Nom <> '' then
          EditNomPersonnag.Text := Nom;
      end;

    // 2 - details physiques (V2 : tables 2-6 a 2-17, sexe tire au hasard)
    // meme sexe que le nom tire ci-dessus quand la race a des noms, sinon au hasard
    if RaceANoms(Personnage.Race) then
      SexeTire := IfThen(ComboBoxSexeNom.ItemIndex = 1, 'F', 'M')
    else
      SexeTire := IfThen(Random(2) = 0, 'F', 'M');
    if (ValVersion = 'WFRP2') and TireDetailsV2(Personnage.Race, SexeTire = 'F', DetailsV2) then
      begin
        Personnage.SexeV2      := SexeTire;
        Personnage.Age         := DetailsV2.Age;
        Personnage.HeightUnit  := UniteTaille;
        Personnage.Height      := ConvertitTaille(DetailsV2.Taille, ConstUniteInch, UniteTaille);
        Personnage.EyeColors   := DetailsV2.Yeux;
        Personnage.HairColors  := DetailsV2.Cheveux;
        Personnage.PoidsV2           := DetailsV2.Poids;
        Personnage.FratrieV2         := IfThen(DetailsV2.Fratrie >= 0, IntToStr(DetailsV2.Fratrie), '');
        Personnage.SigneDistinctifV2 := DetailsV2.Signe;
        Personnage.NaissanceV2       := DetailsV2.Naissance;
        // Un clan choisi en phase 2.1 n'est pas retire par le hasard des details personnels
        if ClanChoisi <> '' then
          Personnage.NaissanceV2     := ClanChoisi;
        Personnage.AstreV2           := DetailsV2.SigneAstral;
        LabPhysiqueResume.Text := IntToStr(Personnage.Age) + ' - ' + FormateTaille(Personnage.Height, Personnage.HeightUnit)
                                     + ' - ' + Personnage.HairColors + ' - ' + Personnage.EyeColors;
      end
    else if TireDetailsPhysiques(Personnage.Race, Age, Taille, Yeux, Cheveux) then
      begin
        Personnage.Age         := Age;
        Personnage.HeightUnit  := UniteTaille;
        Personnage.Height      := ConvertitTaille(Taille, ConstUniteInch, UniteTaille);
        Personnage.EyeColors   := Yeux;
        Personnage.HairColors  := Cheveux;
        LabPhysiqueResume.Text := IntToStr(Personnage.Age) + ' - ' + FormateTaille(Personnage.Height, Personnage.HeightUnit)
                                     + ' - ' + Personnage.HairColors + ' - ' + Personnage.EyeColors;
      end;
    // Le signe astral n'est plus tire ici : il a sa phase 4.1 (avant les talents)
  end;

// Remplit le combo des regles de nom avec celles que l'ethnie declare (NameRule) ; masque si elle
// n'en declare aucune. L'item 0 = pas de regle (noms ordinaires) ; CodesRegleNom garde les codes.
procedure TWinCreations.ChargeReglesNom();
  var
    Regles: TStringList;
    I:      Integer;
    Ancien: String;
  begin
    Regles := TStringList.Create;
    try
      Ancien := '';
      if ComboBoxRegleNom.ItemIndex > 0 then
        Ancien := CodesRegleNom[ComboBoxRegleNom.ItemIndex];
      ReglesNomRace(Personnage.Race, Regles);
      ComboBoxRegleNom.Items.Clear;
      CodesRegleNom.Clear;
      ComboBoxRegleNom.Items.Add(GetTexteLibelle('RULES-LAB_314'));
      CodesRegleNom.Add('');
      for I := 0 to Regles.Count - 1 do
        begin
          ComboBoxRegleNom.Items.Add(GetTexteLibelle(Regles.ValueFromIndex[I], Regles.ValueFromIndex[I]));
          CodesRegleNom.Add(Regles.Names[I]);
        end;
      ComboBoxRegleNom.ItemIndex := 0;
      for I := 1 to CodesRegleNom.Count - 1 do
        if CodesRegleNom[I] = Ancien then
          ComboBoxRegleNom.ItemIndex := I;
      ComboBoxRegleNom.Visible := Regles.Count > 0;
    finally
      Regles.Free;
    end;
  end;

procedure TWinCreations.TabSheetNomShow(Sender: TObject);
  begin
    // V1 : pas de regle de nom, mais le combo doit quand meme avoir son entree 0 (ButtonNomClick lit CodesRegleNom) ;
    // il reste cache puisque ReglesNomRace ne renvoie rien
    ChargeReglesNom();
  end;

// Signes astraux (Archives of the Empire II p.39-50) : systeme optionnel apres la determination des
// caracteristiques. Les effets ne sont pas ecrits dans les valeurs : le signe est memorise sur le
// personnage (SigneAstral) et calcule au vol (PersonnageMutationTalent, PdfPersonnageAttribut).
// Remplit la liste des signes (ceux des livres choisis a l'etape 0) ; rien n'est montre si aucun
// livre charge n'en porte.
procedure TWinCreations.ChargeSignesAstraux();
  var
    Ind:    Integer;
    IndSel: Integer;
    Actif:  Boolean;
  begin
    Actif                := NbSigneAstralPermis() > 0;
    LabSigne.Visible     := Actif;
    ComboBoxSigne.Visible:= Actif;
    ButtonSigne.Visible  := Actif;
    MemoSigne.Visible    := Actif;
    if not Actif then
      ButtonSigneSpe.Visible := False;
    if not Actif then
      Exit;
    ComboBoxSigne.Items.Clear;
    ComboBoxSigne.Items.Add(GetTexteLibelle('RULES-LAB_274'));
    IndSel := 0;
    SetLength(SignesCombo, 0);
    for Ind := 0 to ListSigneAstral.Count - 1 do
      if SigneAstralPermis(Ind) then
        begin
          SetLength(SignesCombo, Length(SignesCombo) + 1);
          SignesCombo[High(SignesCombo)] := Ind;
          ComboBoxSigne.Items.Add(ListSigneAstral[Ind].Libelle);
          if ListSigneAstral[Ind].CodeSigne = Personnage.SigneAstral then
            IndSel := Length(SignesCombo);
        end;
    ComboBoxSigne.ItemIndex := IndSel;   // sans quoi la variante d'un signe deja retenu serait retiree
    AppliqueSigneAstral(IndSel);
  end;

// Indice 0 = aucun signe ; sinon Indice - 1 est le rang dans ListSigneAstral. Un signe a variantes
// (Witchling Star) tire son sous-tirage d10 a chaque application.
procedure TWinCreations.AppliqueSigneAstral(Indice: Integer);
  begin
    if (Indice <= 0) or (Indice > Length(SignesCombo)) then
      begin
        Indice                         := 0;
        Personnage.SigneAstral         := '';
        Personnage.SigneAstralVariante := '';
        Personnage.SigneAstralTalent   := '';
        SigneTire                      := False;
      end
    else
      begin
        Personnage.SigneAstral         := ListSigneAstral[SignesCombo[Indice - 1]].CodeSigne;
        // Un signe deja retenu garde sa variante (retour en arriere dans les etapes)
        if not ((Personnage.SigneAstralVariante <> '') and (ComboBoxSigne.ItemIndex = Indice)) then
          Personnage.SigneAstralVariante := SigneAstralTireVariante(Personnage.SigneAstral);
      end;
    ComboBoxSigne.ItemIndex := Indice;
    MajTexteSigne();
  end;

// Texte du signe retenu, et bouton de specialisation s'il accorde un talent generique
procedure TWinCreations.MajTexteSigne();
  var
    CodeGenerique: String;
  begin
    CodeGenerique := SigneAstralTalentGenerique(Personnage.SigneAstral, Personnage.SigneAstralVariante);
    MemoSigne.Text := ResumeSigneAstral(Personnage.SigneAstral, Personnage.SigneAstralVariante);
    if CodeGenerique <> '' then
      begin
        if Personnage.SigneAstralTalent <> '' then
          MemoSigne.Text := MemoSigne.Text + LineEnding + ChercheTalent(Personnage.SigneAstralTalent).Libelle
        else
          MemoSigne.Text := MemoSigne.Text + LineEnding + GetTexteLibelle('RULES-LAB_276');
      end;
    if SigneTire and (Personnage.SigneAstral <> '') then
      MemoSigne.Text := MemoSigne.Text + LineEnding + '+25 XP';
    ButtonSigneSpe.Visible := MemoSigne.Visible and (CodeGenerique <> '');
  end;

// Meme calcul de plafond que TabAugmentationTalentCalcul (winpersonnage.pas) : MaxiTalent est
// soit un nombre, soit une formule "(BXX)" (bonus de la caracteristique XX). Ici la caracteristique
// est lue dans TabAttribut (encore chargee a la phase 9) plutot que dans la grille de progression,
// modificateur du signe astral inclus (meme calcul que RecapAttribut, ligne au-dessus).
function TWinCreations.TalentMaxCreation(CodeTalent: String): Integer;
  var
    PTalent:   StructureTalent;
    ValeurMax: Integer;
    Calcul:    String;
    Carac:     String;
    IndTab:    Integer;
    Total:     Integer;
  begin
    Result  := 0;
    PTalent := ChercheTalent(CodeTalent);
    if PTalent.MaxiTalent = '' then
      Exit;
    if TryStrToInt(PTalent.MaxiTalent, ValeurMax) then
      Exit(ValeurMax);
    Calcul := PTalent.MaxiTalent;
    Carac  := StringReplace(ExtractStringAfter(Calcul, '(B'),')','',[rfReplaceAll]);
    for IndTab := 1 to (TabAttribut.Rowcount-1) do
      if CodeSansLivre(TabAttribut.Cells[7, IndTab]) = Carac then
        begin
          Total  := StrToIntDef(TabAttribut.Cells[6, IndTab], 0)
                    + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, TabAttribut.Cells[7, IndTab]);
          Result := Trunc(Total / 10);
          Break;
        end;
  end;

// Affiche seul l'onglet d'une phase intermediaire, avec "Phase 2.n sur N - titre" ("2.n" : le premier %d devient %s).
procedure TWinCreations.AfficheSeulOnglet(Onglet: TTabSheet; Suffixe, Titre: String);
  var
    i: Integer;
  begin
    for i := 0 to PageEtapes.PageCount - 1 do
      PageEtapes.Pages[i].TabVisible := (PageEtapes.Pages[i] = Onglet);
    ButtonLibellePhase.Caption := Format(StringReplace(GetTexteLibelle('RULES-LAB_315'), '%d', '%s', []),
      [IntToStr(PhaseEnCours + 1) + Suffixe, PhaseMax + 1, Titre]);
  end;

procedure TWinCreations.AfficheSousPhaseClan();
  begin
    SousPhaseClan := True;
    ClanChoisi    := '';
    RemplirGridClan();
    AfficheSeulOnglet(TabSheetClan, '.1', GetTexteLibelle('RULES-LAB_785'));
  end;

procedure TWinCreations.AfficheSousPhaseSigne();
  begin
    SousPhaseSigne := True;
    ChargeSignesAstraux();
    AfficheSeulOnglet(TabSheetSigne, '.1', GetTexteLibelle('RULES-LAB_793'));
  end;

// Recapitulatif des caracteristiques : valeur de creation + modificateur du signe astral retenu
procedure TWinCreations.MajRecapAttribut();
  var
    IndTab: Integer;
  begin
    for IndTab := 1 to (TabAttribut.Rowcount-1) do
      if IndTab <= 10 then
        RecapAttribut.Cells[IndTab, 1] := IntToStr(StrToIntDef(TabAttribut.Cells[6, IndTab], 0)
          + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, TabAttribut.Cells[7, IndTab]));
    RecapAttribut.Visible := True;
  end;

procedure TWinCreations.AfficheSousPhaseAppartenance();
  begin
    SousPhaseAppartenance := True;
    MajLibelleAppartenance();
    AfficheSeulOnglet(TabSheetAppartenance, '.1', GetTexteLibelle('RULES-LAB_790'));
  end;

// Libelles (pas les codes) des appartenances deja retenues
procedure TWinCreations.MajLibelleAppartenance();
  var
    Codes:   TStringList;
    Ind:     Integer;
    Libelle: String;
  begin
    Libelle := '';
    Codes   := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Personnage.Appartenance), Codes);
      for Ind := 0 to Codes.Count - 1 do
        begin
          if Libelle <> '' then
            Libelle := Libelle + ', ';
          Libelle := Libelle + ChercheCareerBonus(Trim(Codes[Ind])).Libelle;
        end;
    finally
      Codes.Free;
    end;
    LabAppartenanceChoisie.Caption := Libelle;
  end;

// Meme fenetre de choix qu'avant ; on peut en prendre plusieurs tant qu'il reste des candidats
procedure TWinCreations.ButtonAppartenanceChoixClick(Sender: TObject);
  begin
    ChoisitAppartenance();
    MajLibelleAppartenance();
  end;

procedure TWinCreations.AfficheSousPhaseMutation();
  begin
    SousPhaseMutation          := True;
    MutationDepartOk           := False;
    MutationDepartLibelle      := '';
    LabMutationChoisie.Caption := '';
    // l'onglet est partage avec l'etape « chance de mutation » : on remet ses textes d'origine
    LabMutationTexte.Caption    := GetTexteLibelle('RULES-LAB_788');
    ButtonMutationChoix.Caption := GetTexteLibelle('RULES-LAB_789');
    ButtonMutationChoix.Enabled := True;
    AfficheSeulOnglet(TabSheetMutation, '.2', GetTexteLibelle('RULES-LAB_787'));
  end;

// Chance (1 a 99) de mutation de depart de la regle choisie ; 0 = aucune (V2 seulement).
function TWinCreations.ChanceMutationRegle(): Integer;
  begin
    Result := 0;
    if (ValVersion <> 'WFRP2') or (RegleEnCours() = '') then
      Exit;
    // Case « chance de mutation de depart » du livre de la regle decochee a l'etape Livre : aucun jet
    if BasculeCreationActive(ConstCleMutationDepart + ChercheRegle(RegleEnCours()).Livre) then
      Exit;
    Result := StrToIntDef(Trim(ChercheRegle(RegleEnCours()).MutationDepart), 0);
    if (Result < 1) or (Result > 99) then
      Result := 0;
  end;

// Phase intermediaire 3.0 : meme onglet que la mutation de depart (2.2), mais le joueur lance d'abord le d100 ;
// passer a l'etape suivante sans lancer = le MJ ignore la chance (RULES-LAB_1008).
procedure TWinCreations.AfficheSousPhaseMutationChance();
  begin
    SousPhaseMutationChance     := True;
    MutationChanceJet           := 0;
    MutationDepartOk            := False;
    MutationDepartLibelle       := '';
    LabMutationChoisie.Caption  := '';
    LabMutationTexte.Caption    := Format(GetTexteLibelle('RULES-LAB_1008'), [ChanceMutationRegle()]);
    ButtonMutationChoix.Caption := GetTexteLibelle('RULES-LAB_1009');
    ButtonMutationChoix.Enabled := True;
    AfficheSeulOnglet(TabSheetMutation, '.1', GetTexteLibelle('RULES-LAB_787'));
  end;

// Retire du personnage la mutation ajoutee par l'etape 3.0 (regle changee apres coup).
procedure TWinCreations.RetireMutationChance();
  var
    Reste: array of StructurePersonnageMutation;
    Mut:   StructurePersonnageMutation;
  begin
    if not MutationChanceFaite then
      Exit;
    if MutationDepartOk then
      begin
        Reste := [];
        for Mut in Personnage.Mutations do
          if Mut.Code <> MutationDepart.Code then
            Reste += [Mut];
        Personnage.Mutations := Reste;
      end;
    MutationDepartOk    := False;
    MutationChanceFaite := False;
  end;

// Tirage (ou choix) de la mutation de depart : meme fenetre que l'onglet Mutation de WinPersonnage,
// avec relance Shallya's Mercy ; annuler ou fermer sans choisir ne valide rien.
procedure TWinCreations.ButtonMutationChoixClick(Sender: TObject);
  var
    Mutation: StructurePersonnageMutation;
    Chance:   Integer;
    Saisie:   String;
  begin
    if SousPhaseMutationChance then
      begin
        Chance := ChanceMutationRegle();
        // un seul jet par passage ; apres un echec le bouton est inactif
        if MutationChanceJet = 0 then
          begin
            // le programme propose un tirage, que le joueur remplace par son propre jet de de (1 a 100, 00 = 100) ;
            // annuler la saisie ne lance rien
            Saisie := IntToStr(Random(100) + 1);
            repeat
              if not InputQuery(GetTexteLibelle('RULES-LAB_1009'), GetTexteLibelle('RULES-LAB_1012'), Saisie) then
                Exit;
              MutationChanceJet := StrToIntDef(Trim(Saisie), 0);
              if (MutationChanceJet < 1) or (MutationChanceJet > 100) then
                begin
                  MutationChanceJet := 0;
                  ShowMessage(GetTexteLibelle('RULES-LAB_1013'));
                end;
            until MutationChanceJet > 0;
            // le resultat reste affiche dans le texte de l'etape (et pas seulement dans la boite de message)
            if MutationChanceJet <= Chance then
              begin
                LabMutationTexte.Caption := LabMutationTexte.Caption + sLineBreak + sLineBreak
                                            + Format(GetTexteLibelle('RULES-LAB_1010'), [MutationChanceJet, Chance]);
                ShowMessage(Format(GetTexteLibelle('RULES-LAB_1010'), [MutationChanceJet, Chance]));
                ButtonMutationChoix.Caption := GetTexteLibelle('RULES-LAB_789');
              end
            else
              begin
                LabMutationTexte.Caption := LabMutationTexte.Caption + sLineBreak + sLineBreak
                                            + Format(GetTexteLibelle('RULES-LAB_1011'), [MutationChanceJet, Chance]);
                ButtonMutationChoix.Enabled := False;
                ShowMessage(Format(GetTexteLibelle('RULES-LAB_1011'), [MutationChanceJet, Chance]));
                Exit;
              end;
          end;
      end;
    MutationCodeRace             := Personnage.Race;
    MutationResilienceDisponible := False;
    MutationLoreDivin            := '';
    MutationDuChaos              := True;
    WinMutations                 := TWinMutations.Create(Application);
    WinMutations.Position        := poOwnerFormCenter;
    WinMutations.ShowModal;
    if MutationChoix = 'MUTATION' then
      begin
        Mutation := Default(StructurePersonnageMutation);
        Mutation.Code := MutationCode;
        // Effet "+Nd10 %" : jet montre et valide ; annuler = pas de mutation retenue.
        if JetMutationValide(MutationCode, MutationLibelle, Mutation.ValeurAleatoire, Mutation.ValeursEffets) then
          begin
            MutationDepart             := Mutation;
            MutationDepartOk           := True;
            MutationDepartLibelle      := MutationLibelle;
            LabMutationChoisie.Caption := MutationLibelle;
          end;
      end;
    MutationChoix   := '';
    MutationCode    := '';
    MutationLibelle := '';
    MutationEffet   := '';
    MutationDuChaos := False;
  end;

// Phase intermediaire 2.1 (V2) : liste des clans de la race (table de naissance), colonne 0 = plage du d100.
procedure TWinCreations.RemplirGridClan();
  var
    Clans: TStringList;
    Ind:   Integer;
    Barre: Integer;
  begin
    Clans := TStringList.Create;
    try
      ListeClansRace(RaceEnCours, Clans);
      TabClan.ColCount        := 2;
      TabClan.FixedRows       := 1;
      TabClan.RowCount        := Clans.Count + 1;
      TabClan.Cells[0, 0]     := 'd100';
      TabClan.Cells[1, 0]     := GetTexteLibelle('RULES-LAB_785');
      EditClanJet.Text        := '';
      TabClan.ColWidths[0]    := 70;
      TabClan.ColWidths[1]    := 900;
      for Ind := 0 to Clans.Count - 1 do
        begin
          Barre := Pos('|', Clans[Ind]);
          TabClan.Cells[0, Ind + 1] := Copy(Clans[Ind], 1, Barre - 1);
          TabClan.Cells[1, Ind + 1] := Copy(Clans[Ind], Barre + 1, MaxInt);
        end;
    finally
      Clans.Free;
    end;
  end;

procedure TWinCreations.TabClanClick(Sender: TObject);
  begin
    if TabClan.Row >= 1 then
      ClanChoisi := TabClan.Cells[1, TabClan.Row];
  end;

// Selectionne le clan dans la grille (ligne surlignee) et le retient.
procedure TWinCreations.SelectionneClan(const Clan: String);
  var
    Ind: Integer;
  begin
    for Ind := 1 to TabClan.RowCount - 1 do
      if TabClan.Cells[1, Ind] = Clan then
        begin
          TabClan.Row := Ind;
          ClanChoisi  := Clan;
          Break;
        end;
  end;

// Tirage au hasard : le jet est affiche dans la zone de saisie (la modifier le remplace).
procedure TWinCreations.ButtonClanHasardClick(Sender: TObject);
  var
    Jet: Integer;
  begin
    SelectionneClan(TireClanRace(RaceEnCours, Jet));
    EditClanJet.OnChange := nil;
    EditClanJet.Text     := IntToStr(Jet);
    EditClanJet.OnChange := @EditClanJetChange;
  end;

// Jet de d100 donne par le joueur (00 = 100) : le clan correspondant est selectionne.
procedure TWinCreations.EditClanJetChange(Sender: TObject);
  var
    Jet: Integer;
  begin
    Jet := StrToIntDef(Trim(EditClanJet.Text), -1);
    if Jet = 0 then
      Jet := 100;
    if (Jet >= 1) and (Jet <= 100) then
      SelectionneClan(ClanRaceParJet(RaceEnCours, Jet));
  end;

// Effets structures du clan (competences, talents, objets de depart), ajoutes a l'enregistrement final comme
// ceux du signe astral. Lus d'apres le texte de naissance du personnage : un clan retouche a la main
// (WinPhysique) qui ne correspond plus a aucune ligne du livre n'a donc aucun effet.
procedure TWinCreations.AjouteEffetsClan();
  begin
    if (ValVersion <> 'WFRP2') or (Personnage.NaissanceV2 = '') then
      Exit;
    AppliqueEffetsListe(EffetsNaissanceRace(Personnage.Race, Personnage.NaissanceV2));
  end;

procedure TWinCreations.AfficheSousPhaseFamilier();
  begin
    SousPhaseFamilier         := True;
    FamilierTexte             := '';
    FamilierEffets            := '';
    LabFamilierChoisi.Caption := '';
    ListeLignesFamilier(RaceEnCours, ConstXmlPhysForme, ClbFamilierForme.Items);
    ListeLignesFamilier(RaceEnCours, ConstXmlPhysFormeAnimal, ClbFamilierAnimal.Items);
    ListeLignesFamilier(RaceEnCours, ConstXmlPhysParticularite, ClbFamilierParticularite.Items);
    AfficheSeulOnglet(TabSheetFamilier, '.3', GetTexteLibelle('RULES-LAB_795'));
  end;

procedure TWinCreations.CocheFamilier(Liste: TCheckListBox; const Nom: String);
  var
    Ind: Integer;
  begin
    Ind := Liste.Items.IndexOf(Nom);
    if Ind >= 0 then
      Liste.Checked[Ind] := True;
  end;

// Texte et effets du familier d'apres les coches (formes, animaux de la forme animale, particularites).
// Aucune forme cochee : rien n'est tire et la phase ne se valide pas.
procedure TWinCreations.MajFamilierDepuisCoches();
  var
    Ind: Integer;
    Animaux, Nom, Formes, Particularites, Effet: String;
  begin
    Animaux := '';
    for Ind := 0 to ClbFamilierAnimal.Items.Count - 1 do
      if ClbFamilierAnimal.Checked[Ind] then
        begin
          if Animaux <> '' then
            Animaux := Animaux + ', ';
          Animaux := Animaux + ClbFamilierAnimal.Items[Ind];
        end;
    Formes := '';
    FamilierEffets := '';
    for Ind := 0 to ClbFamilierForme.Items.Count - 1 do
      if ClbFamilierForme.Checked[Ind] then
        begin
          Nom := ClbFamilierForme.Items[Ind];
          Effet := EffetsParticulariteRace(RaceEnCours, Nom);
          if Effet <> '' then
            begin
              if FamilierEffets <> '' then
                FamilierEffets := FamilierEffets + ';';
              FamilierEffets := FamilierEffets + Effet;
            end;
          if (Animaux <> '') and (Pos('Animalistic', Nom) > 0) then
            Nom := Nom + ' (' + Animaux + ')';
          if Formes <> '' then
            Formes := Formes + ', ';
          Formes := Formes + Nom;
        end;
    Particularites := '';
    for Ind := 0 to ClbFamilierParticularite.Items.Count - 1 do
      if ClbFamilierParticularite.Checked[Ind] then
        begin
          Nom := ClbFamilierParticularite.Items[Ind];
          Effet := EffetsParticulariteRace(RaceEnCours, Nom);
          if Effet <> '' then
            begin
              if FamilierEffets <> '' then
                FamilierEffets := FamilierEffets + ';';
              FamilierEffets := FamilierEffets + Effet;
            end;
          if Particularites <> '' then
            Particularites := Particularites + ', ';
          Particularites := Particularites + Nom;
        end;
    if Formes = '' then
      begin
        FamilierTexte  := '';
        FamilierEffets := '';
      end
    else if Particularites = '' then
      FamilierTexte := Formes
    else
      FamilierTexte := Formes + ' - ' + Particularites;
    LabFamilierChoisi.Caption := FamilierTexte;
  end;

procedure TWinCreations.ClbFamilierClickCheck(Sender: TObject);
  begin
    MajFamilierDepuisCoches();
  end;

// Tirage de la forme (7-1, animal 7-3) et des particularites (7-2) : il coche les listes, que la main peut ensuite
// corriger ; relancer remplace le tirage precedent.
procedure TWinCreations.ButtonFamilierHasardClick(Sender: TObject);
  var
    Formes, Particularites: TStringList;
    Ind, Parenthese: Integer;
    Effets, Forme: String;
  begin
    Formes         := TStringList.Create;
    Particularites := TStringList.Create;
    try
      TireFamilierV2(RaceEnCours, Formes, Particularites, Effets);
      ClbFamilierForme.CheckAll(cbUnchecked);
      ClbFamilierAnimal.CheckAll(cbUnchecked);
      ClbFamilierParticularite.CheckAll(cbUnchecked);
      for Ind := 0 to Formes.Count - 1 do
        begin
          Forme      := Formes[Ind];
          Parenthese := Pos(' (', Forme);
          if Parenthese > 0 then
            begin
              CocheFamilier(ClbFamilierAnimal, Copy(Forme, Parenthese + 2, Length(Forme) - Parenthese - 2));
              Forme := Copy(Forme, 1, Parenthese - 1);
            end;
          CocheFamilier(ClbFamilierForme, Forme);
        end;
      for Ind := 0 to Particularites.Count - 1 do
        CocheFamilier(ClbFamilierParticularite, Particularites[Ind]);
      MajFamilierDepuisCoches();
    finally
      Particularites.Free;
      Formes.Free;
    end;
  end;

// Effets de la forme tiree (talents, arme naturelle), ajoutes a l'enregistrement final. Gardes par le texte de naissance :
// une forme retouchee a la main (WinPhysique) n'a plus d'effet, comme pour le clan.
procedure TWinCreations.AjouteEffetsFamilier();
  begin
    if (ValVersion <> 'WFRP2') or (FamilierTexte = '') or (Personnage.NaissanceV2 <> FamilierTexte) then
      Exit;
    AppliqueEffetsListe(FamilierEffets);
  end;

// Applique une liste d'effets "Genre:CODE;..." (clan, particularite de forme d'un familier) au personnage en creation.
// Genres : Skill, Talent (Talent:CODE=N pour un talent a niveau), Item (objet de depart, non porte),
// Natural (arme naturelle : objet toujours porte), Grapple (bonus de lutte, seulement affiche : rien a ecrire ici).
procedure TWinCreations.AppliqueEffetsListe(Liste: String);
  var
    Effets:   TStringList;
    Ind, Ind2, Niveau: Integer;
    Genre, Code: String;
    Trouve:   Boolean;
    PComp:    StructurePersonnageCompetence;
    PTalent:  StructurePersonnageTalent;
    PEquip:   StructurePersonnageEquipement;
  begin
    Effets := TStringList.Create;
    try
      Effets.Delimiter       := ';';
      Effets.StrictDelimiter := True;
      Effets.DelimitedText   := Liste;
      for Ind := 0 to Effets.Count - 1 do
        begin
          Genre := Copy(Effets[Ind], 1, Pos(':', Effets[Ind]) - 1);
          Code  := Copy(Effets[Ind], Pos(':', Effets[Ind]) + 1, MaxInt);
          Niveau := 1;
          if Pos('=', Code) > 0 then
            begin
              Niveau := StrToIntDef(Copy(Code, Pos('=', Code) + 1, MaxInt), 1);
              Code   := Copy(Code, 1, Pos('=', Code) - 1);
            end;
          if Code = '' then
            Continue;
          Trouve := False;
          if Genre = 'Skill' then
            begin
              for Ind2 := 0 to High(Personnage.CreationCompetence35) do
                if Personnage.CreationCompetence35[Ind2].CodeCompetence = Code then
                  Trouve := True;
              if not Trouve then
                begin
                  PComp := Default(StructurePersonnageCompetence);
                  PComp.CodeCompetence := Code;
                  PComp.Valeur         := 1;
                  Personnage.CreationCompetence35 += [PComp];
                end;
            end
          else if Genre = 'Talent' then
            begin
              for Ind2 := 0 to High(Personnage.CreationTalent) do
                if Personnage.CreationTalent[Ind2].CodeTalent = Code then
                  Trouve := True;
              if not Trouve then
                begin
                  PTalent := Default(StructurePersonnageTalent);
                  PTalent.CodeTalent := Code;
                  PTalent.Valeur     := Niveau;
                  Personnage.CreationTalent += [PTalent];
                end;
            end
          else if (Genre = 'Item') or (Genre = 'Natural') then
            begin
              PEquip := Default(StructurePersonnageEquipement);
              PEquip.CodeEquipement := Code;
              if ChercheArme(Code).CodeArme <> '' then
                PEquip.TypeEquipement := TypeEquipWe
              else if ChercheArmure(Code).CodeArmure <> '' then
                PEquip.TypeEquipement := TypeEquipAr
              else
                PEquip.TypeEquipement := TypeEquipDI;
              PEquip.QualiteEquipement := QualiteDepuisCode(Code);
              if PEquip.QualiteEquipement = '' then
                PEquip.QualiteEquipement := FabricationDuCatalogue(Code, PEquip.TypeEquipement);
              PEquip.Porte    := Genre = 'Natural';
              PEquip.Quantite := 1;
              Personnage.Equipement += [PEquip];
            end;
        end;
    finally
      Effets.Free;
    end;
  end;

// Le signe n'existe qu'a la creation (Archives II p.39) : son talent est ecrit dans CreationTalent, comme
// un talent de depart. Un talent deja pris gagne un niveau (une seule ligne), plafonne au maximum du
// talent (bonus de caracteristique) s'il en a un : le livre ne dit pas ce qu'il advient du niveau perdu,
// choix retenu ici, on ne depasse simplement pas le maximum, comme le fait deja la grille de progression.
procedure TWinCreations.AjouteTalentSigne();
  var
    PEffet:    StructureSigneEffet;
    PTalent:   StructurePersonnageTalent;
    Code:      String;
    Ind:       Integer;
    Trouve:    Boolean;
    ValeurMax: Integer;
  begin
    if Personnage.SigneAstral = '' then
      Exit;
    for PEffet in ListSigneEffet do
      if (PEffet.CodeSigne = Personnage.SigneAstral) and (PEffet.CodeTalent <> '')
         and ((PEffet.Variante = '') or (PEffet.Variante = Personnage.SigneAstralVariante)) then
        begin
          Code := PEffet.CodeTalent;
          if Pos(ValeurGenerique, Code) > 0 then
            Code := Personnage.SigneAstralTalent;
          if Code = '' then
            Continue;
          Trouve := False;
          for Ind := 0 to High(Personnage.CreationTalent) do
            if Personnage.CreationTalent[Ind].CodeTalent = Code then
              begin
                ValeurMax := TalentMaxCreation(Code);
                if (ValeurMax <= 0) or (Personnage.CreationTalent[Ind].Valeur < ValeurMax) then
                  Personnage.CreationTalent[Ind].Valeur := Personnage.CreationTalent[Ind].Valeur + 1;
                Trouve := True;
                Break;
              end;
          if not Trouve then
            begin
              PTalent.CodeTalent := Code;
              PTalent.Valeur     := 1;
              PTalent.Asterisque := 0;
              PTalent.Source     := '';
              Personnage.CreationTalent += [PTalent];
            end;
        end;
  end;

// Le joueur choisit toujours la specialisation (Craftsman : le metier ; Impassioned Zeal : l'objet du zele)
procedure TWinCreations.ButtonSigneSpeClick(Sender: TObject);
  var
    CodeGenerique: String;
  begin
    CodeGenerique := SigneAstralTalentGenerique(Personnage.SigneAstral, Personnage.SigneAstralVariante);
    if CodeGenerique = '' then
      Exit;
    ChoixWinTypeFichier := ConstXmlSousChapitreTalent;
    ChoixWinTalent      := CodeGenerique;
    SelectWinTalent     := '';
    FenSpecialisation           := TWinSpecialisations.Create(Application);
    FenSpecialisation.Position  := poOwnerFormCenter;
    FenSpecialisation.ShowModal;
    if SelectWinTalent <> '' then
      Personnage.SigneAstralTalent := SelectWinTalent;
    SelectWinTalent := '';
    MajTexteSigne();
  end;

procedure TWinCreations.ButtonSigneClick(Sender: TObject);
  var
    Jet:  Integer;
    Code: String;
    Ind:  Integer;
  begin
    Code := TireSigneAstral(Jet);
    if Code = '' then
      Exit;
    for Ind := 0 to High(SignesCombo) do
      if ListSigneAstral[SignesCombo[Ind]].CodeSigne = Code then
        begin
          Personnage.SigneAstralVariante := '';
          Personnage.SigneAstralTalent   := '';
          ComboBoxSigne.ItemIndex        := -1;
          SigneTire                      := True;
          AppliqueSigneAstral(Ind + 1);
          Break;
        end;
  end;

procedure TWinCreations.ComboBoxSigneSelect(Sender: TObject);
  var
    Indice: Integer;
  begin
    Indice                         := ComboBoxSigne.ItemIndex;
    Personnage.SigneAstralVariante := '';
    Personnage.SigneAstralTalent   := '';
    SigneTire                      := False;
    AppliqueSigneAstral(Indice);
  end;

////////////////////////////////////////////////////////////////////////////////
//                                 XML                                        //
////////////////////////////////////////////////////////////////////////////////

function TWinCreations.XmlCalculXp(): Integer;
  var
    Total: Integer = 0;
//    RadioGroup1.ItemIndex
  begin
    if RadioButtonRaceHasard.Checked or RadioButtonRaceResultat.Checked then
      Total := Total + 20;
    if RadioButtonMetierHasard.Checked or RadioButtonMetierResultat.checked then
      Total := Total + 50;
    if RadioButtonAttributHasard.Checked or RadioButtonAttributResultat.checked then
      Total := Total + 50
    else if not RadioButtonAttributRepartition.Checked then
      Total := Total + 25;
    if SigneTire and (Personnage.SigneAstral <> '') then
      Total := Total + 25;
    Result := Total;
  end;

////////////////////////////////////////////////////////////////////////////////
//                                 RACE                                       //
////////////////////////////////////////////////////////////////////////////////

procedure TWinCreations.TabRaceDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
  begin
    // Vérifier si la ligne actuelle doit avoir une couleur spéciale
    if TabRace.Cells[4, aRow] = '1' then
      TabRace.Canvas.Brush.Color := clLtGray  // Changer la couleur de fond en vert
    else
      TabRace.Canvas.Brush.Color := clWhite; // Utiliser la couleur de fond par défaut

    // Dessiner la cellule avec la couleur modifiée
    TabRace.Canvas.FillRect(aRect);
    TabRace.Canvas.TextOut(aRect.Left + 2, aRect.Top + 2, TabRace.Cells[aCol, aRow]);
  end;

procedure TWinCreations.TabRacePrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
  begin
    if (ARow = 0) then
    begin
      TabRace.Canvas.Brush.Color := clBtnFace; // Couleur de fond de l'en-tête désactivé
      TabRace.Canvas.Font.Color := ClBlack; // Couleur du texte de l'en-tête désactivé
    end;
  end;

Procedure TWinCreations.ChargeTabRaces(Livre: String='');
  Var
    IndTabRace:    Integer;
    PRaceCreation: StructureRaceCreation;
    PRace:         StructureRace;
    OldLivre:      String = '';
    Ind:           Integer;
  Begin
    if Livre = '' then
      begin
        ComboRaceCreation.Style    := csDropDownList;
        for PRaceCreation in ListRaceCreation do
          begin
            if OldLivre <> PRaceCreation.Livre then
              begin
                ComboRaceCreation.Items.add(PRaceCreation.Livre);
                OldLivre := PRaceCreation.Livre
              end;
          end;
        Livre := ConstRulesBook;
        for ind := 0 to ComboRaceCreation.items.count -1 do
          if ComboRaceCreation.items[Ind] = Livre then
            begin
              ComboRaceCreation.itemindex := Ind;
              break;
            end;

      end;

    if TabRace.RowCount>0 then
      begin
        ClearStringGrid(TabRace);
        TabRace.Rowcount := 1;
      end;

    IndTabRace        := 0;

    For PRaceCreation in ListRaceCreation do
      begin
        if PRaceCreation.Livre = Livre then
          begin
            PRace := chercheRace(PRaceCreation.CodeRace);
            Inc(IndTabRace);
            TabRace.Rowcount := IndTabRace+1;
            TabRace.Cells[1, IndTabRace] := PRace.CodeRace;
            TabRace.Cells[2, IndTabRace] := PRace.Libelle;
            TabRace.Cells[3, IndTabRace] := PRaceCreation.Chance;
          end;
    end;
    AdjustGridColumnsWidth(TabRace,0,false,false);
  end;

// V2 : jet de l'argent de depart (formule "1d10CO") ; sans objet pour un montant fixe
procedure TWinCreations.ButtonArgentClick(Sender: TObject);
  begin
    if (Pos('d', FormuleArgent) > 0) and not EditArgent.ReadOnly then
      EditArgent.Text := IntToStr(LanceFormule(Copy(FormuleArgent, 1, Length(FormuleArgent) - 2), False));
  end;

// V2 : montre l'argent de depart de la carriere choisie (champ et bouton caches s'il n'y en a pas)
procedure TWinCreations.AfficheArgentDepart();
  var
    Base: String;
    EstDe: Boolean;
  begin
    if (ValVersion <> 'WFRP2') or (ButtonArgent = nil) then Exit;
    FormuleArgent := ArgentDepartMetier(MetierEnCours);
    ButtonArgent.Visible := FormuleArgent <> '';
    EditArgent.Visible   := FormuleArgent <> '';
    if FormuleArgent = '' then Exit;
    Base  := Copy(FormuleArgent, 1, Length(FormuleArgent) - 2);
    EstDe := Pos('d', Base) > 0;
    EditArgent.ReadOnly  := not EstDe;
    ButtonArgent.Enabled := EstDe;
    if EstDe then
      EditArgent.Text := IntToStr(LanceFormule(Base, False))
    else
      EditArgent.Text := Base;
  end;

procedure TWinCreations.ButtonRaceHasardClick(Sender: TObject);
  begin
       // V2 et V1 : pas de table de tirage, chaque race de la grille a la meme chance (meme effet qu'un double-clic)
       if RaceParGrille() then
         begin
           if (GridRace <> nil) and (GridRace.RowCount > 1) then
             begin
               GridRace.Row := Random(GridRace.RowCount - 1) + 1;
               GridRaceDblClick(Sender);
             end;
           Exit;
         end;
       LastRandomRaceResultat := (Random(100) + 1);
       TabRaceResultat(LastRandomRaceResultat);
       AfficheImageRace();
       UpdateSheetRace(true);
  end;

procedure TWinCreations.ButtonRaceValiderClick(Sender: TObject);
  begin
       if (EditRaceResultat.Value = 0) then
          ShowMessage(GetTexteLibelle('RULES-MESS_19'))
       else
       begin
         LastCheckRaceResultat := EditRaceResultat.Value;
         TabRaceResultat(LastCheckRaceResultat);
         AfficheImageRace();
         UpdateSheetRace(true);
       end
  end;

var
  ZoneImagesRace: TZoneImagesRace;

Procedure TWinCreations.AfficheImageRace();
  Var
    indTabAttribut:          integer;
    PRaceAttribut:           StructureRaceAttribut;
    CheminImage1:            String;
    CheminImage2:            String;

  begin
    NbRaceCompetenceTab      := 0;


    if RaceEnCours <> '' then
      begin
       CheminImage1       := CheminRaceImage(RaceEnCours,'2');
       CheminImage2       := CheminRaceImage(RaceEnCours,'1');
       end
    else
      begin
        CheminImage1       := '';
        CheminImage2       := '';
      end;
    if FileExists(CheminImage1) then
       ImageRace1.Picture.LoadFromFile(CheminImage1)
    else
       ImageRace1.Picture := nil;

    if FileExists(CheminImage2) then
       ImageRace2.Picture.LoadFromFile(CheminImage2)
    else
       ImageRace2.Picture := nil;
    // ethnie sans illustration : icone de sa race de base, nom de la race au milieu
    if (RaceEnCours <> '') and not FileExists(CheminImage1) and not FileExists(CheminImage2) then
      AfficheIconeEspece(ImageRace1, ChercheRace(RaceEnCours).Espece,
                         ChercheEspece(ChercheRace(RaceEnCours).Espece).Libelle);
    // une seule illustration (ou l'icone de race) : elle prend la place des deux
    PlaceImagesRace(ImageRace1, ImageRace2, ZoneImagesRace,
                    (ImageRace1.Picture.Graphic <> nil) and not ImageRace1.Picture.Graphic.Empty,
                    (ImageRace2.Picture.Graphic <> nil) and not ImageRace2.Picture.Graphic.Empty);

    LibRace.Text            := RaceLibEnCours;
    LibRace.visible         := (RaceLibEnCours <> '');

    UpdateSheetRace(false);

    // ATTRIBUTS

    For PRaceAttribut in ListRaceAttribut do
      if CompareRechercheValeur(PRaceAttribut.CodeRace, RaceEnCours) then
        for IndTabAttribut := 0 to TabAttribut.RowCount -1 do
           if TabAttribut.Cells[7, IndTabAttribut] = PRaceAttribut.CodeAttribut then
             begin
                TabAttribut.Cells[4, IndTabAttribut] := PRaceAttribut.CalculRace;
                if CompareRechercheValeur(PRaceAttribut.CodeAttribut, ConstCaracPointSupp) then
                  begin
                    LabPointSupp.Text           := PRaceAttribut.CalculRace+' '+GetTexteLibelle('RULES-LAB_119');
                    TrackBarPointSupp.Min       := 0;
                    TrackBarPointSupp.Max       := StrToInt(PRaceAttribut.CalculRace);
                    TrackBarPointSupp.Frequency := 1;
                  end;
             end;

    // TALENTS
    RemplitTalentsRace();
  end;

// Talents de l'ethnie, ou ceux que la regle choisie en phase Metier leur substitue. Appelee a
// l'affichage de la race ET quand le joueur change de regle (la regle est choisie APRES la race).
Procedure TWinCreations.RemplitTalentsRace();
  Var
    Talent1:                 String;
    Multi:                   boolean;
    NbTalentTab:             Integer;
    PTalent:                 StructureTalent;
    CodesTalentRace:         TStringList;
    CodeTalentRace:          String;
    IndTab:                  Integer;
  begin
    NbTalentTab := 0;
    // une regle qui change les talents ne doit pas laisser ceux de la selection precedente
    for IndTab := 1 to TabTalent.RowCount - 1 do
      begin
        TabTalent.Cells[1, IndTab] := '';
        TabTalent.Cells[2, IndTab] := '';
      end;
    CodesTalentRace := CodesRaceEffectifs('T', RegleEnCours(), RaceEnCours);
    try
      For CodeTalentRace in CodesTalentRace do
        Begin
          Multi   := (pos(SeparateurMulti, CodeTalentRace) > 0);
          if Multi then
             Begin
               Talent1 := ExtractStringBefore(CodeTalentRace, SeparateurMulti);
             end
          else
             begin
               Talent1 := CodeTalentRace;
             end;

             For PTalent in ListTalent do
               if CompareRechercheValeur(PTalent.CodeTalent, Talent1)
                  and (not CompareRechercheValeur(PTalent.CodeTalent, TalentGenerique))
                    and (not Multi) then
                 begin
                   NbTalentTab                     := NbTalentTab + 1;
                   // grille dimensionnee a 10 lignes au chargement : le Troglagob (V2) en a 11 sans choix
                   if NbTalentTab >= TabTalent.RowCount then
                     TabTalent.RowCount := NbTalentTab + 1;
                   TabTalent.Cells[1, NbTalentTab] := PTalent.CodeTalent;
                   TabTalent.Cells[2, NbTalentTab] := PTalent.Libelle;
                 end;
        end;
    finally
      CodesTalentRace.Free;
    end;
    ReconstruitChoixCreation();
    ButtonTalentHasard.visible   := (Length(ListeChoixCreation) > 0);
    ButtonTalentHasard.BringToFront;
  end;

procedure TWinCreations.TabRaceResultat(Resul: Integer);
  var
    IndTab: Integer;
    Deb: Integer;
    Fin: Integer;
    Ch: String;
    IndS: Integer;
    Trouve: Boolean = false;
    PRace: StructureRace;
  begin
    for IndTab := 1 to TabRace.RowCount - 1 do
      begin
        Ch := TabRace.Cells[3, IndTab];
        IndS := Pos(SeparateurChance, Ch);
        if IndS > 0 then
          begin
            Deb := StrToInt(Copy(Ch, 1, IndS-1));
            Fin := StrToInt(Copy(Ch, IndS+1, Length(Ch)));
          end
        else
          begin
            Deb := StrToInt(Ch);
            Fin := StrToInt(Ch);
          end;

        if ChoixWinRace <> '' then
          begin
            if TabRace.Cells[1, Indtab] = ChoixWinRace then
              begin
                IndS := Pos(SeparateurChance, Ch);
                if IndS > 0 then
                  Resul := StrToInt(Copy(Ch, 1, IndS-1))
                else
                  Resul := StrToInt(Ch);
              end
            else
              Deb := 101;
          end;

        if (Deb <= Resul) and (Resul <= Fin) then
          begin
            RaceEnCours              := TabRace.Cells[1, indTab];
            RaceLibEnCours           := TabRace.Cells[2, indTab];
            // L'ethnie vient de changer : elle intervient dans la resolution des icones.
            ChargeImagesNiveau();
            TabRace.Cells[4, IndTab] := '1';
            TabRace.Invalidate;
            Break;
            Trouve := True;
          end;
      end;
    if (ChoixWinRace <> '') and not Trouve then
      begin
        PRace          := chercheRace(ChoixWinRace);
        RaceEnCours    := Prace.CodeRace;
        RaceLibEnCours := PRace.Libelle;
        // Idem.
        ChargeImagesNiveau();
      end;
  end;

procedure TWinCreations.RadioButtonRaceClick(Sender: TObject);
  begin
    LastRandomRaceResultat := 0;
    LastCheckRaceResultat  := 0;
    RaceEnCours            := '';
    RaceLibEnCours         := '';
    TabRaceResultat(0);
    AfficheImageRace();
    UpdateSheetRace(false);
  end;

procedure TWinCreations.RadioButtonRaceHasardClick(Sender: TObject);
  begin
    LastRandomRaceResultat := 0;
    LastCheckRaceResultat  := 0;
    RaceEnCours            := '';
    RaceLibEnCours         := '';
    TabRaceResultat(0);
    AfficheImageRace();
    UpdateSheetRace(false);
  end;

procedure TWinCreations.UpdateSheetRace(Hasard: Boolean);
  Begin
    // Au Hasard
    ButtonRaceHasard.Visible  := RadioButtonRaceHasard.Checked or RaceParGrille();
    ButtonRaceHasard.Enabled  := (LastRandomRaceResultat = 0) or RaceParGrille();
    ButtonRaceHasard.BringToFront;

    // donner le résultat de votre lancé de dé
    EditRaceResultat.Visible  := RadioButtonRaceResultat.Checked;
    EditRaceResultat.enabled  := (LastCheckRaceResultat = 0);
    ButtonRaceValider.Visible := RadioButtonRaceResultat.Checked;
    ButtonRaceValider.Enabled := (LastCheckRaceResultat = 0);
    ButtonRaceValider.BringToFront;

    // choisir votre race
    ButtonRaceSelectionner.visible := RadioButtonRaceChoix.Checked;
    ButtonRaceSelectionner.BringToFront;

    // choisir les livres ou les règles
    ComboRaceCreation.Enabled := (not RadioButtonRaceHasard.Checked and not RadioButtonRaceResultat.Checked and not RadioButtonRaceChoix.Checked);

    if Hasard then
      GroupBoxRace.enabled    := false;

  end;


////////////////////////////////////////////////////////////////////////////////
//                               METIER                                       //
////////////////////////////////////////////////////////////////////////////////

procedure TWinCreations.TabMetierPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
  begin
    TabMetier.Canvas.Brush.Color := clBtnFace; // Couleur de fond de l'en-tête désactivé
    TabMetier.Canvas.Font.Color := ClBlack; // Couleur du texte de l'en-tête désactivé
  end;

procedure TWinCreations.TabMetierDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
  begin
    // Vérifier si la ligne actuelle doit avoir une couleur spéciale
    if TabMetier.Cells[4, aRow] = '1' then
      TabMetier.Canvas.Brush.Color := clLtGray  // Changer la couleur de fond en vert
    else
      TabMetier.Canvas.Brush.Color := clWhite; // Utiliser la couleur de fond par défaut

    // Dessiner la cellule avec la couleur modifiée
    TabMetier.Canvas.FillRect(aRect);
    TabMetier.Canvas.TextOut(aRect.Left + 2, aRect.Top + 2, TabMetier.Cells[aCol, aRow]);
  end;

// La liste des règles disponibles pour la RACE EN COURS : la table de tirage par défaut (celle
// du livre de règles) en premier, puis une ligne par règle optionnelle apportée par un livre
// chargé ET qui couvre cette race (RegleCouvreRace, le même test que le tirage). CodesRegleCombo
// suit le combo ligne à ligne. La règle choisie est gardée si elle existe encore pour la race.
Procedure TWinCreations.ChargeComboRegle();
  Var
    PRegle:  StructureRegle;
    Gardee:  String;
    Ind:     Integer;
  Begin
    if CodesRegleCombo = nil then
      CodesRegleCombo := TStringList.Create;
    Gardee := RegleEnCours();
    ComboBoxRegle.Items.Clear;
    CodesRegleCombo.Clear;
    ComboBoxRegle.Items.Add(GetTexteLibelle(ConstRulesBook, '', '', true));
    CodesRegleCombo.Add('');
    For PRegle in ListRegle do
      if RegleConcerneRace(PRegle.CodeRegle, RaceEnCours) and not RegleDesactivee(PRegle.Livre, PRegle.CodeRegle)
         and (Pos(AjouteAccolade(PRegle.Livre), LivresPersonnages) > 0) then
        begin
          ComboBoxRegle.Items.Add(PRegle.Libelle);
          CodesRegleCombo.Add(PRegle.CodeRegle);
        end;
    Ind := CodesRegleCombo.IndexOf(Gardee);
    if Ind < 0 then
      Ind := 0;
    ComboBoxRegle.ItemIndex := Ind;
    RaceRegleCombo          := RaceEnCours;
    GroupBoxRegle.Visible   := (CodesRegleCombo.Count > 1);
  end;

// ---- Phase intermediaire "Background" (Liber Fanatica) -------------------------------------------------

// Vrai si un livre charge porte la table du background pour la race en cours (version V2 seulement).
function TWinCreations.FondActif(): Boolean;
  begin
    Result := (ValVersion = 'WFRP2') and RegleFondDisponible(RaceEnCours);
  end;

procedure TWinCreations.CreeOngletFond();
  var
    Conteneur: TPanel;
  // Meme mise en page que les autres phases intermediaires (Clan, Appartenance) : libelle blanc en haut, grille a
  // police noire, boutons clones de ButtonClanHasard (meme style) alignes en bas.
  function Bouton(X: Integer; const Legende: String; Clic: TNotifyEvent): TBCButton;
    var
      Flux: TMemoryStream;
    begin
      Flux := TMemoryStream.Create;
      try
        Flux.WriteComponent(ButtonClanHasard);
        Flux.Position := 0;
        Result := TBCButton(TComponentClass(ButtonClanHasard.ClassType).Create(nil));
        Flux.ReadComponent(Result);
      finally
        Flux.Free;
      end;
      Result.Name    := 'ButtonFond' + IntToStr(X);
      Result.Parent  := TabSheetFond;
      Result.SetBounds(X, 776, 256, 45);
      Result.Caption := Legende;
      Result.OnClick := Clic;
    end;
  begin
    CodesFond                  := TStringList.Create;
    // Les composants des onglets du formulaire sont styles par MiseAJourUnContenaire (globalfonts.pas) d'apres leur
    // proprietaire : l'onglet et ses champs appartiennent donc a un conteneur propre, style en bloc a la fin.
    Conteneur                  := TPanel.Create(Self);
    Conteneur.Visible          := False;
    Conteneur.Parent           := Self;
    TabSheetFond               := TTabSheet.Create(Conteneur);
    TabSheetFond.PageControl   := PageEtapes;
    TabSheetFond.Caption       := GetTexteLibelle('RULES-LAB_803', 'Background');
    TabSheetFond.TabVisible    := False;

    // Cadre "Background" comme le cadre "Regle" de la phase Metier : les deux combos et le jet du d100
    GroupBoxFond               := TGroupBox.Create(Conteneur);
    GroupBoxFond.Parent        := TabSheetFond;
    GroupBoxFond.SetBounds(0, 0, 1000, 110);
    GroupBoxFond.Caption       := GetTexteLibelle('RULES-LAB_803', 'Background');

    LabFondTexte               := TLabel.Create(Conteneur);
    LabFondTexte.Parent        := GroupBoxFond;
    LabFondTexte.SetBounds(12, 60, 970, 20);
    LabFondTexte.AutoSize      := False;

    ComboFond                  := TComboBox.Create(Conteneur);
    ComboFond.Parent           := GroupBoxFond;
    ComboFond.Style            := csDropDownList;
    ComboFond.SetBounds(12, 24, 480, 28);
    ComboFond.OnChange         := @ComboFondChange;

    ComboFond2                 := TComboBox.Create(Conteneur);
    ComboFond2.Parent          := GroupBoxFond;
    ComboFond2.Style           := csDropDownList;
    ComboFond2.SetBounds(504, 24, 480, 28);
    ComboFond2.Visible         := False;

    GridFond                   := TStringGrid.Create(Conteneur);
    GridFond.Parent            := TabSheetFond;
    GridFond.SetBounds(0, 120, 1000, 640);
    GridFond.Anchors           := [akTop, akLeft, akRight, akBottom];
    GridFond.ColCount          := 5;
    GridFond.FixedCols         := 0;
    GridFond.FixedRows         := 1;
    GridFond.RowCount          := 1;
    GridFond.Options           := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect, goSmoothScroll];
    GridFond.ColWidths[0]      := 0;     // genre (S / T)
    GridFond.ColWidths[1]      := 0;     // code
    GridFond.ColWidths[2]      := 800;   // libelle
    GridFond.ColWidths[3]      := 180;   // jet
    GridFond.ColWidths[4]      := 0;     // regle de provenance
    GridFond.Cells[2, 0]       := GetTexteLibelle('RULES-LAB_803', 'Background');
    GridFond.Cells[3, 0]       := 'd100';
    GridFond.OnDblClick        := @GridFondDblClick;

    ButtonFondRegle  := Bouton(8,   GetTexteLibelle('RULES-LAB_800', 'Roll background'), @ButtonFondRegleClick);
    ButtonFondD10    := Bouton(272, GetTexteLibelle('RULES-LAB_805', 'Roll the d10'), @ButtonFondD10Click);
    ButtonFondRelance := Bouton(536, GetTexteLibelle('RULES-LAB_806', 'Re-roll the line'), @ButtonFondRelanceClick);

    // Mise en forme commune (fond de l'onglet, cadre, listes, grille, libelle), puis les boutons repassent au
    // premier plan : le fond de l'onglet (TShape en alClient) est cree en dernier et les couvrirait.
    ButtonFondIgnore := Bouton(800, GetTexteLibelle('RULES-LAB_807', 'Ignore'), @ButtonFondIgnoreClick);
    ButtonFondIgnore.Width := 192;
    MiseAJourUnContenaire(Conteneur);
    ButtonFondRegle.BringToFront;
    ButtonFondD10.BringToFront;
    ButtonFondRelance.BringToFront;
    ButtonFondIgnore.BringToFront;
  end;

procedure TWinCreations.AfficheSousPhaseFond();
  var
    PRegle: StructureRegle;
  begin
    SousPhaseFond := True;
    CodesFond.Clear;
    ComboFond.Items.Clear;
    ComboFond2.Items.Clear;
    for PRegle in ListRegle do
      if RegleConcerneRace(PRegle.CodeRegle, RaceEnCours) and not RegleDesactivee(PRegle.Livre, PRegle.CodeRegle)
         and (FondATable(PRegle.CodeRegle, 'S') or FondATable(PRegle.CodeRegle, 'T')) then
        begin
          CodesFond.Add(PRegle.CodeRegle);
          ComboFond.Items.Add(PRegle.Libelle);
          ComboFond2.Items.Add(PRegle.Libelle);
        end;
    if CodesFond.Count > 0 then
      begin
        ComboFond.ItemIndex  := 0;
        ComboFond2.ItemIndex := 0;
      end;
    ComboFond2.Visible := False;
    FondIgnore         := False;
    GridFond.RowCount  := 1;
    LabFondTexte.Caption := '';
    TabSheetFond.Caption := IntToStr(PhaseEnCours + 1) + '.4 sur ' + IntToStr(PhaseMax + 1);
    AfficheSeulOnglet(TabSheetFond, '.4', GetTexteLibelle('RULES-LAB_803', 'Background'));
  end;

// Un autre background invalide les tirages deja faits.
procedure TWinCreations.ComboFondChange(Sender: TObject);
  begin
    FondIgnore           := False;
    GridFond.RowCount    := 1;
    ComboFond2.Visible   := False;
    LabFondTexte.Caption := GetTexteLibelle('RULES-LAB_803', 'Background');
  end;

procedure TWinCreations.ButtonFondRegleClick(Sender: TObject);
  var
    Jet, Ind: Integer;
  begin
    Jet := Random(100) + 1;
    Ind := CodesFond.IndexOf(RegleFondTirage(RaceEnCours, Jet));
    if Ind < 0 then
      Exit;
    ComboFond.ItemIndex := Ind;
    ComboFondChange(nil);
    LabFondTexte.Caption := GetTexteLibelle('RULES-LAB_803', 'Background') + ' (d100 : ' + IntToStr(Jet) + ')';
  end;

// Tire une competence ('S') ou un talent ('T') du background Regle et l'ecrit dans la ligne Ligne de la grille,
// sans reprendre un code deja present (sauf les codes generiques, dont le choix vient apres).
procedure TWinCreations.TireLigneFond(Genre: Char; const Regle: String; Ligne: Integer);
  var
    Code, Libelle: String;
    Jet, Essai, I: Integer;
    Doublon: Boolean;
  begin
    Essai := 0;
    repeat
      Code := FondTire(Regle, Genre, Jet);
      Doublon := False;
      if Pos(ValeurGenerique, Code) = 0 then
        for I := 1 to GridFond.RowCount - 1 do
          if (I <> Ligne) and (GridFond.Cells[1, I] = Code) then
            Doublon := True;
      Inc(Essai);
    until (Code = '') or (not Doublon) or (Essai >= 50);
    if Code = '' then
      Exit;
    if Genre = 'S' then
      Libelle := ChercheCompetence(Code).Libelle
    else
      Libelle := ChercheTalent(Code).Libelle;
    GridFond.Cells[0, Ligne] := Genre;
    GridFond.Cells[1, Ligne] := Code;
    GridFond.Cells[2, Ligne] := Libelle;
    GridFond.Cells[3, Ligne] := 'd100 : ' + IntToStr(Jet);
    GridFond.Cells[4, Ligne] := Regle;
  end;

// d10 du nombre de competences et de talents. Un 10 demande un second background (choisi ou tire), puis le d10 est
// relance (un nouveau 10 aussi) ; une competence et un talent viennent alors du second background.
procedure TWinCreations.ButtonFondD10Click(Sender: TObject);
  var
    Jet, NbComp, NbTal, I, Garde, Ind, ExtraS, ExtraT: Integer;
    Second, A2: Boolean;
    Regle1, Regle2, Texte, Espece: String;
  begin
    if ComboFond.ItemIndex < 0 then
      Exit;
    FondIgnore := False;
    Regle1 := CodesFond[ComboFond.ItemIndex];
    A2     := False;
    Garde  := 0;
    Texte  := '';
    repeat
      if not FondTireCompte(Jet, NbComp, NbTal, Second) then
        Exit;
      Texte := Texte + 'd10 : ' + IntToStr(Jet) + '  ';
      if Second then
        A2 := True;
      Inc(Garde);
    until (not Second) or (Garde >= 20);
    if A2 then
      begin
        if not ComboFond2.Visible then
          begin
            ComboFond2.Visible := True;
            Ind := CodesFond.IndexOf(RegleFondTirage(RaceEnCours, Random(100) + 1));
            if Ind >= 0 then
              ComboFond2.ItemIndex := Ind;
          end;
        Regle2 := CodesFond[ComboFond2.ItemIndex];
      end
    else
      begin
        ComboFond2.Visible := False;
        Regle2 := Regle1;
      end;
    LabFondTexte.Caption := GetTexteLibelle('RULES-LAB_803', 'Background') + ' - ' + Texte
                            + IntToStr(NbComp) + ' / ' + IntToStr(NbTal);
    // Liber Fanatica : l'humain tire une competence et un talent de plus, le halfling une competence OU un talent
    // (au choix du joueur), au lieu du talent aleatoire du Rulebook. Les lignes en plus viennent du 1er background.
    ExtraS := 0;
    ExtraT := 0;
    Espece := ChercheRace(RaceEnCours).Espece;
    if CompareRechercheValeur(Espece, 'RULES-SPECIE_HUMAN') then
      begin
        ExtraS := 1;
        ExtraT := 1;
      end
    else if CompareRechercheValeur(Espece, 'RULES-SPECIE_HALFLING') then
      begin
        // --creer (RapportAuto) : pas de boite, la competence est choisie d'office
        if (RapportAuto <> nil) or
           (QuestionDlg('Halfling', 'Un tirage de plus : competence ou talent ?', mtConfirmation,
                        [mrYes, 'Competence', mrNo, 'Talent'], 0) = mrYes) then
          ExtraS := 1
        else
          ExtraT := 1;
      end;
    GridFond.RowCount := 1 + NbComp + NbTal + ExtraS + ExtraT;
    for I := 1 to NbComp do
      TireLigneFond('S', IfThen(A2 and (I = NbComp), Regle2, Regle1), I);
    for I := 1 to NbTal do
      TireLigneFond('T', IfThen(A2 and (I = NbTal), Regle2, Regle1), NbComp + I);
    for I := 1 to ExtraS do
      TireLigneFond('S', Regle1, NbComp + NbTal + I);
    for I := 1 to ExtraT do
      TireLigneFond('T', Regle1, NbComp + NbTal + ExtraS + I);
  end;

// Passe la phase et enchaine sur la suivante : aucun tirage, aucune competence ni talent ajoute, la regle de carriere reste celle par defaut.
procedure TWinCreations.ButtonFondIgnoreClick(Sender: TObject);
  begin
    FondIgnore           := True;
    ComboFond2.Visible   := False;
    GridFond.RowCount    := 1;
    LabFondTexte.Caption := GetTexteLibelle('RULES-LAB_803', 'Background') + ' - ' + GetTexteLibelle('RULES-LAB_807', 'Ignore');
    ButtonPhaseSuivanteClick(nil);
  end;

procedure TWinCreations.ButtonFondRelanceClick(Sender: TObject);
  var
    L: Integer;
  begin
    L := GridFond.Row;
    if (L < 1) or (L >= GridFond.RowCount) or (GridFond.Cells[0, L] = '') then
      Exit;
    TireLigneFond(GridFond.Cells[0, L][1], GridFond.Cells[4, L], L);
  end;

// Double-clic sur une competence generique ("Common Knowledge (Various)") : choix de la specialisation.
procedure TWinCreations.GridFondDblClick(Sender: TObject);
  var
    L: Integer;
  begin
    L := GridFond.Row;
    if (L < 1) or (L >= GridFond.RowCount) then
      Exit;
    if (GridFond.Cells[0, L] = 'S') and (Pos(ValeurGenerique, GridFond.Cells[1, L]) > 0) then
      begin
        SelectWinCompetence         := '';
        ChoixWinTypeFichier         := ConstXmlSousChapitreCompetence;
        ChoixWinCompetence          := GridFond.Cells[1, L];
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        if SelectWinCompetence <> '' then
          begin
            GridFond.Cells[1, L] := SelectWinCompetence;
            GridFond.Cells[2, L] := SelWinLibelle;
          end;
      end;
  end;

// Rien a valider tant que le d10 n'est pas tire et que chaque competence "au choix" n'est pas precisee.
function TWinCreations.FondComplet(): Boolean;
  var
    I: Integer;
  begin
    Result := FondIgnore or (GridFond.RowCount > 1);
    for I := 1 to GridFond.RowCount - 1 do
      if (GridFond.Cells[1, I] = '') or (Pos(ValeurGenerique, GridFond.Cells[1, I]) > 0)
         or (Pos(SeparateurMulti, GridFond.Cells[1, I]) > 0) then
        Result := False;
  end;

// Fin de la phase : le background retenu devient la regle du tirage de carriere, les competences et talents tires
// s'ajoutent au personnage (la race vient d'etre enregistree, qui avait vide ces listes).
procedure TWinCreations.AppliqueFond();
  var
    I, Ind: Integer;
  begin
    if FondIgnore then
      Exit;
    for I := 1 to GridFond.RowCount - 1 do
      if GridFond.Cells[0, I] = 'S' then
        begin
          PersonnageCompetence.CodeCompetence := GridFond.Cells[1, I];
          PersonnageCompetence.Valeur         := 1;
          Personnage.CreationCompetence35     += [PersonnageCompetence];
        end
      else if GridFond.Cells[0, I] = 'T' then
        begin
          PersonnageTalent.CodeTalent         := GridFond.Cells[1, I];
          PersonnageTalent.Valeur             := 1;
          Personnage.CreationTalent           += [PersonnageTalent];
        end;
    if RaceRegleCombo <> RaceEnCours then
      ChargeComboRegle();
    Ind := CodesRegleCombo.IndexOf(CodesFond[ComboFond.ItemIndex]);
    if Ind >= 0 then
      begin
        ComboBoxRegle.ItemIndex := Ind;
        ComboBoxRegleSelect(nil);
      end;
  end;

// '' = table de tirage par défaut (celle des SUBCHAPTER_CAREER, livre de règles).
Function TWinCreations.RegleEnCours(): String;
  Begin
    if (CodesRegleCombo = nil) or (ComboBoxRegle.ItemIndex <= 0) or (ComboBoxRegle.ItemIndex >= CodesRegleCombo.Count) then
      Result := ''
    else
      Result := CodesRegleCombo[ComboBoxRegle.ItemIndex];
  end;

Procedure TWinCreations.ComboBoxRegleSelect(Sender: TObject);
  Begin
    // la regle change : la mutation de depart eventuellement obtenue avec l'ancienne ne vaut plus
    RetireMutationChance();
    ChargeTabMetier();
    // une regle peut remplacer les talents de l'ethnie, deja affiches a la phase Race
    RemplitTalentsRace();
  end;

Procedure TWinCreations.ChargeTabMetier();
  Var
    IndTabMetier:  Integer;
    PMetier:       StructureMetier;
    Tirage:        TListTirageMetier;
    Ligne:         StructureTirageMetier;

  Begin
    // la liste des règles dépend de la race : la refaire si elle a changé
    if RaceRegleCombo <> RaceEnCours then
      ChargeComboRegle();

    IndTabMetier        := 0;
    TabMetier.RowCount  := 1;

    // Les bornes ne sont plus dans le XML (il ne porte que le poids de chaque métier) : elles
    // se calculent dans la langue active, dans l'ordre des tables imprimées (classe puis
    // libellé). Règle non applicable à l'ethnie, partielle ou totale : voir ChargeTirageMetier.
    Tirage := TListTirageMetier.Create;
    try
      CalculeTirageMetier(RaceEnCours, RegleEnCours(), Tirage);
      DesMetier                   := DesDuTirage(Tirage);
      EditMetierResultat.MaxValue := DesMetier;
      For Ligne in Tirage do
        begin
          PMetier := ChercheMetier(Ligne.CodeMetier);
          Inc(IndTabMetier);
          TabMetier.RowCount := TabMetier.RowCount + 1;
          TabMetier.Cells[1, IndTabMetier] := PMetier.CodeMetier;
          TabMetier.Cells[2, IndTabMetier] := PMetier.Libelle;
          TabMetier.Cells[3, IndTabMetier] := FormateTranche(Ligne.Debut, Ligne.Fin, DesMetier);
          TabMetier.Cells[5, IndTabMetier] := Format('%.3d', [Ligne.Debut]);
        end;
    finally
      Tirage.Free;
    end;

    // pas de table de tirage pour cette ethnie (V5) : pas de jet, le metier se choisit
    ButtonMetierHasard.Enabled := (TabMetier.RowCount > 1);

    AdjustGridColumnsWidth(TabMetier, TabSheetMetier.ClientHeight, false, false);
  end;

procedure TWinCreations.ButtonMetierHasardClick(Sender: TObject);
  begin
     LastRandomMetierResultat := (Random(DesMetier) + 1);
     TabMetierResultat(LastRandomMetierResultat);
     AfficheImageMetier();
     UpdateSheetMetier(true);
  end;

// Equipement de classe effectif pour une classe : les ajouts de tous les livres acceptes, dans
// l'ordre de chargement, puis les actions (Remove / Replace) appliquees dans le meme ordre.
// Un objet cible absent est ignore en silence ; une partie d'un ensemble A+B se retire ou se
// remplace seule ; un choix "A/B" ne se retire qu'en entier (code complet). L'appelant libere.
function ClasseEquipementEffectif(const Classe: String): TListClassEquipement;
var
  P, N:    StructureClassEquipement;
  I, K, J: Integer;
  Codes:   TStringList;
  Types:   TStringList;
  CodeEns: String;
  TypEns:  String;
begin
  Result := TListClassEquipement.Create;
  if Classe = '' then
    Exit;
  for P in ListClassEquipement do
    if CompareRechercheValeur(P.CodeClasse, Classe) then
      begin
        if P.Action = '' then
          begin
            Result.Add(P);
            Continue;
          end;
        for I := 0 to Result.Count - 1 do
          begin
            N := Result[I];
            if N.Equipement = P.Cible then
              begin
                if P.Action = 'REMOVE' then
                  Result.Delete(I)
                else
                  begin
                    N.Equipement     := P.Equipement;
                    N.TypeEquipement := P.TypeEquipement;
                    if P.QuantiteListe <> '' then
                      begin
                        N.QuantiteListe := P.QuantiteListe;
                        N.Quantite      := 1;
                      end
                    else if P.Quantite > 0 then
                      begin
                        N.Quantite      := P.Quantite;
                        N.QuantiteListe := '';
                      end;
                    Result[I] := N;
                  end;
                Break;
              end
            else if Pos(SeparateurEnsemble, N.Equipement) > 0 then
              begin
                Codes := TStringList.Create;
                Types := TStringList.Create;
                try
                  ExtractStrings([SeparateurEnsemble], [], PChar(N.Equipement), Codes);
                  ExtractStrings([SeparateurEnsemble], [], PChar(N.TypeEquipement), Types);
                  K := Codes.IndexOf(P.Cible);
                  if K >= 0 then
                    begin
                      if P.Action = 'REMOVE' then
                        begin
                          Codes.Delete(K);
                          if K < Types.Count then
                            Types.Delete(K);
                        end
                      else
                        begin
                          Codes[K] := P.Equipement;
                          if K < Types.Count then
                            Types[K] := P.TypeEquipement;
                        end;
                      if Codes.Count = 0 then
                        Result.Delete(I)
                      else
                        begin
                          CodeEns := '';
                          TypEns  := '';
                          for J := 0 to Codes.Count - 1 do
                            begin
                              if CodeEns <> '' then CodeEns := CodeEns + SeparateurEnsemble;
                              CodeEns := CodeEns + Codes[J];
                            end;
                          for J := 0 to Types.Count - 1 do
                            begin
                              if TypEns <> '' then TypEns := TypEns + SeparateurEnsemble;
                              TypEns := TypEns + Types[J];
                            end;
                          N.Equipement     := CodeEns;
                          N.TypeEquipement := TypEns;
                          if (P.Action = 'REPLACE') and (P.Quantite > 0) then
                            N.Quantite := P.Quantite;
                          Result[I] := N;
                        end;
                      Break;
                    end;
                finally
                  Codes.Free;
                  Types.Free;
                end;
              end;
          end;
      end;
end;

Procedure TWinCreations.AfficheImageMetier();
  // Phase 2 : le metier est choisi, on remplit les grilles des etapes suivantes. Les blocs
  // sont appeles dans l'ordre d'origine ; les deux boucles d'equipement (Carriere puis
  // Classe) partagent EcritLigneEnsemble / EcritLigneSimple, qui ecrivent la ligne
  // NbMetierEquipementTab de TabMetierEquipement.

  // Ligne d'ensemble : la ligne porte deux codes joints par SeparateurEnsemble ; les deux
  // objets sont acquis en meme temps (ex. Storm Lantern + Lamp Oil), une seule ligne de
  // creation = une seule coche d'avancement (CONTEXT.md, chantier equipement/avancement) -
  // pas un choix, donc pas de ConstArbreAuChoix/double-clic.
  procedure EcritLigneEnsemble(const Equipement, TypeEq: String; Quantite: Integer);
    var
      StringsCodeEns: TStringList;
      StringsTypeEns: TStringList;
      IndEns:         Integer;
      CodeUnit:       String;
      LibUnit:        String;
      TypUnit:        String;
      LibEns:         String;
      CodeEns:        String;
      TypEns:         String;
      PArme:          StructureArme;
      PArmure:        StructureArmure;
      PTrapping:      StructureTrapping;
    begin
      StringsCodeEns := TStringList.Create;
      StringsTypeEns := TStringList.Create;
      ExtractStrings([SeparateurEnsemble], [], PChar(Equipement), StringsCodeEns);
      ExtractStrings([SeparateurEnsemble], [], PChar(TypeEq), StringsTypeEns);
      LibEns  := '';
      CodeEns := '';
      TypEns  := '';
      For IndEns := 0 to StringsCodeEns.Count - 1 do
        begin
          CodeUnit := StringsCodeEns[IndEns];
          if InList(StringsTypeEns[IndEns],TypeEquipMetierArme) then
              begin
                PArme    := ChercheArme(CodeUnit);
                LibUnit  := PArme.Libelle;
                TypUnit  := TypeEquipWe;
              end
            else if StringsTypeEns[IndEns] = TypeEquipAR then
              begin
                PArmure  := ChercheArmure(CodeUnit);
                LibUnit  := PArmure.Libelle;
                TypUnit  := TypeEquipAr;
              end
            else if StringsTypeEns[IndEns] = TypeEquipDI then
              begin
                PTrapping := ChercheTrapping(CodeUnit);
                if PTrapping.CodeTrapping <> '' then
                  LibUnit := PTrapping.Libelle
                else
                  LibUnit := CodeUnit;
                TypUnit  := TypeEquipDi;
              end;
          if LibEns  <> '' then LibEns  := LibEns  + ' + ';
          LibEns  := LibEns  + LibUnit;
          if CodeEns <> '' then CodeEns := CodeEns + SeparateurEnsemble;
          CodeEns := CodeEns + CodeUnit;
          if TypEns  <> '' then TypEns  := TypEns  + SeparateurEnsemble;
          TypEns  := TypEns  + TypUnit;
        end;
      StringsCodeEns.Free;
      StringsTypeEns.Free;
      TabMetierEquipement.Cells[1, NbMetierEquipementTab] := CodeEns;
      TabMetierEquipement.Cells[2, NbMetierEquipementTab] := LibEns + QuantiteSuffixe(Quantite);
      TabMetierEquipement.Cells[5, NbMetierEquipementTab] := IntToStr(Quantite);
      TabMetierEquipement.Cells[6, NbMetierEquipementTab] := TypEns;
    end;

  // Ligne simple (un seul objet, pas de choix). Un code Divers peut en realite etre un
  // Trapping catalogue (RULES-TRAP_xxx) - la classification reste TypeEquipDI (CONTEXT.md
  // 2.77bis), seul l'affichage est resolu ici, comme winlivre.pas:1200. Col 5, cachee :
  // quantite (CONTEXT.md 2.77), lue a l'etape 8 pour PersonnageEquipement.Quantite au lieu
  // de rester figee a 1.
  procedure EcritLigneSimple(const Code, TypeEq: String; Quantite: Integer);
    var
      Lib:       String;
      Typ:       String;
      PArme:     StructureArme;
      PArmure:   StructureArmure;
      PTrapping: StructureTrapping;
    begin
      if InList(TypeEq,TypeEquipMetierArme) then
          begin
            PArme   := ChercheArme(Code);
            Lib     := PArme.Libelle;
            Typ     := TypeEquipWe;
          end
        else if TypeEq = TypeEquipAR then
          begin
            PArmure := ChercheArmure(Code);
            Lib     := PArmure.Libelle;
            Typ     := TypeEquipAr;
          end
        else if TypeEq = TypeEquipDI then
          begin
            PTrapping := ChercheTrapping(Code);
            if PTrapping.CodeTrapping <> '' then
              Lib := PTrapping.Libelle
            else
              Lib := Code;
            Typ     := TypeEquipDi;
          end;
      Lib := Lib + QuantiteSuffixe(Quantite);
      TabMetierEquipement.Cells[1, NbMetierEquipementTab] := Code;
      TabMetierEquipement.Cells[2, NbMetierEquipementTab] := Lib;
      TabMetierEquipement.Cells[5, NbMetierEquipementTab] := IntToStr(Quantite);
      TabMetierEquipement.Cells[6, NbMetierEquipementTab] := Typ;
    end;

  procedure AfficheEnteteMetier();
    var
      indTabAttribut:  integer;
      PMetierAttribut: StructureMetierAttribut;
      CheminImage1:    String;
    begin
      if MetierEnCours <> '' then
         CheminImage1       := CheminMetierImage(MetierEnCours)
      else
          CheminImage1      := '';

      if FileExists(CheminImage1) then
         ImageMetier.Picture.LoadFromFile(CheminImage1)
      else
         ImageMetier.Picture := nil;

      LibMetier.Text            := MetierLibEnCours;
      LibMetier.visible         := (MetierLibEnCours <> '');

      UpdateSheetMetier(false);

      For PMetierAttribut in ListMetierAttribut do
        if CompareRechercheValeur(PMetierAttribut.CodeMetier, MetierEnCours) then
          for IndTabAttribut := 0 to TabAttribut.RowCount -1 do
            if (TabAttribut.Cells[7, IndTabAttribut] = PMetierAttribut.CodeAttribut) and (PMetierAttribut.NiveauMetier > 0) then
              TabAttribut.Cells[2, IndTabAttribut] := IntToStr(PMetierAttribut.NiveauMetier);
    end;

  procedure AfficheCompetencesRace();
    var
      PCompetence:       StructureCompetence;
      PRaceEntete:       StructureRace;
      PRaceCompetence:   StructureRaceCompetence;
      CodesCompetenceRace: TStringList;
      CodeCompetenceRace:  String;
      PMetierCompetence: StructureMetierCompetence;
    begin
      // Compétences de race
      // En-tetes des deux colonnes de choix : le nombre ET la valeur viennent de l'ethnie
      // (NbPoint5/NbPoint3 et Point5/Point3), plus rien n'est ecrit en dur - un Skink affiche
      // "2x 5pts" et "2x 3pts". CONTEXT.md 2.15.
      PRaceEntete := ChercheRace(RaceEnCours);
      TabRaceCompetence.Columns[3].Title.Caption := Format('%dx %dpts', [PRaceEntete.NbPoint5, PRaceEntete.Point5]);
      TabRaceCompetence.Columns[4].Title.Caption := Format('%dx %dpts', [PRaceEntete.NbPoint3, PRaceEntete.Point3]);

      // Les lignes sont recreees : les cases 5pts/3pts, indexees par numero de ligne, le sont
      // aussi (remise a zero). Le tableau est REDIMENSIONNE au nombre reel de competences de
      // race : NbMaxCompetence (12) est plus petit que la liste des Hauts Elfes d'Ellyrion (13),
      // et la 13e ligne lisait hors du tableau (case cochee au hasard).
      SetLength(CompetenceRaceStates[4], ListRaceCompetence.Count + 2);
      SetLength(CompetenceRaceStates[5], ListRaceCompetence.Count + 2);
      for IndTab := 0 to High(CompetenceRaceStates[4]) do
        begin
          CompetenceRaceStates[4, IndTab] := false;
          CompetenceRaceStates[5, IndTab] := false;
        end;
      NbCinq := 0;
      NbTrois := 0;
      NbRaceCompetenceTab          := 0;
      TabRaceCompetence.RowCount   := 1;
      NbRaceComp                   := 0;
      // Competences de l'ethnie, ou celles que la regle choisie en phase Metier leur substitue
      CodesCompetenceRace := CodesRaceEffectifs('S', RegleEnCours(), RaceEnCours);
      try
        For CodeCompetenceRace in CodesCompetenceRace do
          Begin
             NbRaceCompetenceTab                             := NbRaceCompetenceTab + 1;
             TabRaceCompetence.RowCount                      := NbRaceCompetenceTab + 1;
             TabRaceCompetence.Cells[1,NbRaceCompetenceTab]  := CodeCompetenceRace;
             PCompetence                                     := ChercheCompetence(CodeCompetenceRace);
             TabRaceCompetence.Cells[3,NbRaceCompetenceTab]  := LibelleCompetenceLigne(CodeCompetenceRace);
             PMetierCompetence                               := ChercheMetierCompetence(MetierEnCours,CodeCompetenceRace);
             if PMetierCompetence.CodeMetier <> '' then
               TabRaceCompetence.Cells[2,NbRaceCompetenceTab]:= IntToStr(PMetierCompetence.NiveauMetier);
          end;
      finally
        CodesCompetenceRace.Free;
      end;
      TabRaceCompetence.Height      := TabRaceCompetence.DefaultRowHeight * TabRaceCompetence.RowCount + 5;
      AdjustGridColumnsWidth(TabRaceCompetence, TabSheetCompRace.ClientHeight, false, true);
      // V2 : pas de +5/+3, toutes les competences de race sont acquises. Les cases du groupe 4
      // sont cochees d'office (PhaseSaveCompetencesRace les enregistre) et les deux colonnes
      // de points sont masquees ; seuls restent les choix "A ou B" (double-clic).
      if ValVersion = 'WFRP2' then
        begin
          for IndTab := 1 to NbRaceCompetenceTab do
            CompetenceRaceStates[4, IndTab] := True;
          NbCinq := 0;
          NbTrois := 0;
          // colonne R (niveau de carriere de la competence) : sans objet en V2
          TabRaceCompetence.ColWidths[2] := 0;
          TabRaceCompetence.ColWidths[4] := 0;
          TabRaceCompetence.ColWidths[5] := 0;
        end;
    end;

  procedure AfficheCompetencesMetier();
    var
      PCompetence:       StructureCompetence;
      PMetierCompetence: StructureMetierCompetence;
      CodeCompAdapt:     String;
      CodesRace:         TStringList;
    begin
      // Competences effectives de l'ethnie (celles que la regle choisie leur substitue, le cas echeant)
      CodesRace := CodesRaceEffectifs('S', RegleEnCours(), RaceEnCours);
      try
      // Compétences de Métier
      NbMetierCompetenceTab         := 0;
      TabMetierCompetence.RowCount  := 1;
      NbTrois                       := 0;
      NbCinq                        := 0;
      for PMetierCompetence in ListMetierCompetence do
        if CompareRechercheValeur(PMetierCompetence.CodeMetier, MetierEnCours) and (PMetierCompetence.NiveauMetier = 1) then
          Begin
               // Adapting Careers : competence de niveau 1 remplacee (ou retiree) pour l'ethnie.
               CodeCompAdapt := AdapterElement(MetierEnCours, RaceEnCours, ChoixAdaptationCreation(), 1,
                                                     ConstXmlCompetence, PMetierCompetence.CodeCompetence);
               if CodeCompAdapt = '' then
                 continue;
               NbMetierCompetenceTab        := NbMetierCompetenceTab + 1;
               TabMetierCompetence.RowCount := NbMetierCompetenceTab + 1;
               TabMetierCompetence.Cells[1,NbMetierCompetenceTab] := CodeCompAdapt;
               PCompetence                  := ChercheCompetence(CodeCompAdapt);
               TabMetierCompetence.Cells[3,NbMetierCompetenceTab] := LibelleCompetenceLigne(CodeCompAdapt);

               if (Pos(ValeurGenerique, PCompetence.CodeCompetence) > 0) or (pos(SeparateurMulti, PCompetence.CodeCompetence) > 0) then
                 begin
                   TabMetierCompetence.Cells[5,NbMetierCompetenceTab] := ConstArbreAuChoix;
                   TabMetierCompetence.Cells[6,NbMetierCompetenceTab] := PCompetence.CodeCompetence;
                 end;

               if CodesRace.IndexOf(CodeCompAdapt) >= 0 then
                  TabMetierCompetence.Cells[2,NbMetierCompetenceTab] := IntToStr(PMetierCompetence.NiveauMetier);
           end;
      TabMetierCompetence.Height          := TabMetierCompetence.DefaultRowHeight * TabMetierCompetence.RowCount + 5;
      // V2 : pas de 40 points. Chaque competence de carriere est acquise une fois ; si la race
      // la donne deja, elle est prise deux fois = +10 % (Skill Mastery, Core p.90). La colonne 4
      // porte ce nombre de prises (1 ou 2), non modifiable.
      if ValVersion = 'WFRP2' then
        for IndTab := 1 to NbMetierCompetenceTab do
          if CodesRace.IndexOf(TabMetierCompetence.Cells[1, IndTab]) >= 0 then
            TabMetierCompetence.Cells[4, IndTab] := '2'
          else
            TabMetierCompetence.Cells[4, IndTab] := '1';
      CalculTotalMetierCompetence();
      AdjustGridColumnsWidth(TabMetierCompetence, TabSheetCompMetier.ClientHeight, false, true);
      // V2 : tant que les competences de carriere ne sont pas en donnees, la grille reste vide : cachee
      if ValVersion = 'WFRP2' then
        TabMetierCompetence.Visible := NbMetierCompetenceTab > 0;
      // V2 : colonne R sans objet, et la colonne des 40 points devient le nombre de prises
      if ValVersion = 'WFRP2' then
        begin
          TabMetierCompetence.ColWidths[2] := 0;
          TabMetierCompetence.Columns[3].Title.Caption := GetTexteLibelle('RULES-LAB_737');
        end;
      finally
        CodesRace.Free;
      end;
    end;

  procedure AfficheEquipementMetier();
    var
      PMetierEquipement: StructureMetierEquipement;
      ListeCode:         String;
      ListeQuantites:    String;
    begin
      // Equipement de métier
      NbMetierEquipementTab        := 0;
      TabMetierEquipement.RowCount := 1;
      For PMetierEquipement in ListMetierEquipement do
        if CompareRechercheValeur(PMetierEquipement.CodeMetier, MetierEnCours) and (PMetierEquipement.NiveauMetier = 1) then
          Begin
             NbMetierEquipementTab        := NbMetierEquipementTab + 1;
             TabMetierEquipement.RowCount := NbMetierEquipementTab + 1;
             if Pos(SeparateurEnsemble, PMetierEquipement.Equipement) > 0 then
               EcritLigneEnsemble(PMetierEquipement.Equipement, PMetierEquipement.TypeEquipement, PMetierEquipement.Quantite)
             else
               begin
                 ListeCode                    := GetListeEquipement(PMetierEquipement.Equipement, PMetierEquipement.TypeEquipement, PMetierEquipement.QuantiteListe, ListeQuantites);

                 if Pos(',',ListeCode) > 0 then
                   begin
                     TabMetierEquipement.Cells[2, NbMetierEquipementTab]   := ConstArbreAuchoix;
                     TabMetierEquipement.Cells[3, NbMetierEquipementTab]   := ListeCode;
                     TabMetierEquipement.Cells[7, NbMetierEquipementTab]   := ListeQuantites;
                     // Quantite de l'item entier (col 5) tant qu'aucune branche n'est choisie ;
                     // le double-clic la remplace par celle de la branche retenue.
                     TabMetierEquipement.Cells[5, NbMetierEquipementTab]   := IntToStr(PMetierEquipement.Quantite);
                   end
                 else
                   EcritLigneSimple(PMetierEquipement.Equipement, PMetierEquipement.TypeEquipement, PMetierEquipement.Quantite);
               end;
          end;
    end;

  procedure AfficheEquipementClasse();
    var
      PMetierClasse:    StructureMetier;
      PClassEquipement: StructureClassEquipement;
      ListClasseEff:    TListClassEquipement;
    begin
      // Equipement de Classe (Rulebook p.37, "Class Trappings", CONTEXT.md chantier "AUDIT DES
      // TXT" Rulebook) : donne une fois en plus de l'equipement de la Carriere choisie (pas de
      // niveau, pas de choix "/" ni de doublon de logique - meme boucle que ci-dessus, juste une
      // source differente). <Class> de la Carriere deja charge dans StructureMetier.LibelleGroupe.
      PMetierClasse := ChercheMetier(MetierEnCours);
      ListClasseEff := ClasseEquipementEffectif(PMetierClasse.LibelleGroupe);
      try
        For PClassEquipement in ListClasseEff do
          if CompareRechercheValeur(PClassEquipement.CodeClasse, PMetierClasse.LibelleGroupe) then
            Begin
               NbMetierEquipementTab        := NbMetierEquipementTab + 1;
               TabMetierEquipement.RowCount := NbMetierEquipementTab + 1;
               if Pos(SeparateurEnsemble, PClassEquipement.Equipement) > 0 then
                 EcritLigneEnsemble(PClassEquipement.Equipement, PClassEquipement.TypeEquipement, PClassEquipement.Quantite)
               else
                 EcritLigneSimple(PClassEquipement.Equipement, PClassEquipement.TypeEquipement, PClassEquipement.Quantite);
            end;
      finally
        ListClasseEff.Free;
      end;

      AdjustGridColumnsWidth(TabMetierEquipement, TabSheetEquipement.ClientHeight, false, true, true, 10);
    end;

begin
  AfficheEnteteMetier();

  // COMPETENCES
  if MetierEnCours <> '' then
    begin
      AfficheCompetencesRace();
      AfficheCompetencesMetier();
      AfficheEquipementMetier();
      AfficheArgentDepart();
      AfficheEquipementClasse();
    end;
end;

procedure TWinCreations.ButtonMetierValiderClick(Sender: TObject);
begin
     if (EditMetierResultat.Value = 0) then
        ShowMessage(GetTexteLibelle('RULES-MESS_019'))
     else
     begin
       LastCheckMetierResultat := EditMetierResultat.Value;
       TabMetierResultat(LastCheckMetierResultat);
       AfficheImageMetier();
       UpdateSheetMetier(true);
     end
end;

procedure TWinCreations.RadioButtonMetierHasardClick(Sender: TObject);
  begin
    LastRandomMetierResultat := 0;
    LastCheckMetierResultat  := 0;
    LastCheckMetierSousMetierResul := 0;
    MetierEnCours            := '';
    MetierLibEnCours         := '';
    TabMetierResultat(0);
    AfficheImageMetier();
    UpdateSheetMetier(false);
  end;

procedure TWinCreations.RadioButtonMetierClick(Sender: TObject);
  begin
    LastRandomMetierResultat := 0;
    LastCheckMetierResultat  := 0;
    LastCheckMetierSousMetierResul := 0;
    MetierEnCours            := '';
    MetierLibEnCours         := '';
    TabMetierResultat(0);
    AfficheImageMetier();
    UpdateSheetMetier(false);
  end;

procedure TWinCreations.UpdateSheetMetier(Hasard: Boolean);
  Begin
    if CreationV1Obj <> nil then Exit;   // V1 : onglet rempli par CreationV1
    // Au Hasard
    ButtonMetierHasard.Visible  := RadioButtonMetierHasard.Checked;
    ButtonMetierHasard.Enabled  := (LastRandomMetierResultat = 0);
    ButtonMetierHasard.BringToFront;

    // donner le résultat de votre lancé de dé
    EditMetierResultat.Visible  := RadioButtonMetierResultat.Checked;
    EditMetierResultat.enabled  := (LastCheckMetierResultat = 0);
    ButtonMetierValider.Visible := RadioButtonMetierResultat.Checked;
    ButtonMetierValider.Enabled := (LastCheckMetierResultat = 0);
    ButtonMetierValider.BringToFront;

    // choisir votre Metier
    ButtonMetierSelectionner.visible:= RadioButtonMetierChoix.Checked;
    ButtonMetierSelectionner.BringToFront;

    // Sous-métier / substitution raciale : leur visibilité est pilotée par TabMetierResultat,
    // mais le BringToFront doit être refait ICI, car UpdateSheetMetier s'exécute APRES et
    // remonte les autres boutons au premier plan. Sans ça ils restaient sous le TShape de
    // fond que MiseAJourUnContenaire (globalfonts.pas) crée en alClient sur chaque onglet -
    // les TMemo y échappent (contrôles fenêtrés), pas les TBCButton.
    if ButtonMetierSousMetierValider.Visible then
      ButtonMetierSousMetierValider.BringToFront;
    if ButtonMetierSousMetierSelectionner.Visible then
      ButtonMetierSousMetierSelectionner.BringToFront;

    if Hasard then
       GroupBoxMetier.Enabled   := false;
  end;

////////////////////////////////////////////////////////////////////////////////
//                             ATTRIBUTS                                      //
////////////////////////////////////////////////////////////////////////////////


procedure TWinCreations.RadioButtonAttributClick(Sender: TObject);
  var
    I:         Integer;
    WasRepart: Boolean;
  begin
    WasRepart := ModRepartition;
    UpdateSheetAttribut(false);
    // Entree dans la repartition : 10 partout (= 100) ; sortie : on efface les valeurs
    // Ligne 2 : le nom de l'attribut en texte (les combos sont masques dans ce mode)
    if ModRepartition and not WasRepart then
      for I := 1 to 10 do
        begin
          TabAttributLanceDe.Cells[I, 1] := '10';
          TabAttributLanceDe.Cells[I, 2] := TabAttribut.Cells[1, I];
        end
    else if WasRepart and not ModRepartition then
      for I := 1 to 10 do
        begin
          TabAttributLanceDe.Cells[I, 1] := '';
          TabAttributLanceDe.Cells[I, 2] := '';
        end;
    CalculTabAttribut(false, (ModDesti=false));
    if not ModRepartition then
      TabAttributLanceDeClickCombo();
  end;

procedure TWinCreations.TabAttributLanceDeEditingDone(Sender: TObject);
  var
    CellValue: Integer;
  begin
    if (FEditingRow = 1) and (FEditingCol > 0) and ModRepartition then
    begin
      // Repartition des 100 points : 4 mini, 18 maxi (V4) ou 16 (V5)
      CellValue := StrToIntDef(TabAttributLanceDe.Cells[FEditingCol, FEditingRow], 0);
      if (CellValue < 4) or (CellValue > RepartitionMax()) then
      begin
        TabAttributLanceDe.Cells[FEditingCol, FEditingRow] := '10';
        ShowMessage(Format(GetTexteLibelle('RULES-MESS_064'), [4, RepartitionMax()]));
        CalculTabAttribut(false, false);
      end;
    end
    else if (FEditingRow = 1) and (FEditingCol > 0) then
    begin
      // Récupérer la valeur de la cellule
      CellValue := StrToIntDef(TabAttributLanceDe.Cells[FEditingCol, FEditingRow], 0);

      // Vérifier les limites de valeur
      if (CellValue > 0) and ((CellValue < 2) or (CellValue > 20)) then
      begin
        // Rétablir la valeur précédente
        TabAttributLanceDe.Cells[FEditingCol, FEditingRow] := '';
        ShowMessage(GetTexteLibelle('RULES-MESS_020'));
      end;
    end;
  end;

procedure TWinCreations.TabAttributLanceDeSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  var
    ComboBoxAttribut: TComboBox;
    cellRect: TRect;
  begin
    FEditingCol := aCol;
    FEditingRow := aRow;
    CanSelect := true;

    if (CanSelect = True) and (aRow = 2) and (not ModRepartition) then
    Begin
      ComboBoxAttribut := TabAttributLanceDe.Objects[ACol, ARow] as TComboBox;
      if Assigned(ComboBoxAttribut) then
      begin
        // Récupérer la cellule sélectionnée
        cellRect := TabAttributLanceDe.CellRect(aCol, aRow);

        // Afficher le composant TComboBox dans la cellule sélectionnée
        ComboBoxAttribut.SetBounds(cellRect.Left, cellRect.Top, cellRect.Width, cellRect.Height);
        ComboBoxAttribut.Visible := True;
      end;
    end;
  end;

procedure TWinCreations.TabAttributDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  ImageIndex: Integer;
  CellWidth, CellHeight: Integer;
  MaxWidth, MaxHeight, ImageWidth, ImageHeight: Integer;
  AspectRatio: Double;
  LeftOffset, TopOffset: Integer;
  ImageRect: TRect;
  TopLeftPixelColor: TColor;
  Bitmap: TBitmap;
begin

  if (aRow > 0) then
    begin
      TabAttribut.Canvas.Font.Color := clBlack;
      if (aCol = 2) then
        begin
          // Récupérer la valeur de la cellule correspondante (colonne 2)
          ImageIndex := StrToIntDef(TabAttribut.Cells[aCol, aRow], -1);

          // Vérifier que la valeur est valide et se situe dans la plage d'index d'image
          if (ImageIndex >= 0) and (ImageIndex < ListImage.Count) then
            begin
              // Calculer la taille de la cellule
              CellWidth := aRect.Right - aRect.Left;
              CellHeight := aRect.Bottom - aRect.Top;

              // Calculer la taille maximale pour l'image en utilisant la taille de la cellule
              // et en ajustant l'aspect ratio de l'image
              MaxWidth := CellWidth;
              MaxHeight := CellHeight;
              ImageWidth := ListImage.Width;
              ImageHeight := ListImage.Height;
              if ImageWidth > 0 then
                begin
                  AspectRatio := ImageHeight / ImageWidth;
                  if ImageWidth > MaxWidth then
                    begin
                      ImageWidth := MaxWidth;
                      ImageHeight := Round(ImageWidth * AspectRatio);
                    end;
                  if ImageHeight > MaxHeight then
                    begin
                      ImageHeight := MaxHeight;
                      ImageWidth := Round(ImageHeight / AspectRatio);
                    end;
                end;

              // Calculer la position de l'image pour centrer verticalement et horizontalement
              // dans la cellule
              LeftOffset := (CellWidth - ImageWidth) div 2;
              TopOffset := (CellHeight - ImageHeight) div 2;
              ImageRect := Rect(aRect.Left + LeftOffset, aRect.Top + TopOffset, aRect.Left + LeftOffset + ImageWidth, aRect.Top + TopOffset + ImageHeight);

              // Obtenir la couleur du pixel en haut à gauche de l'image
              Bitmap := TBitmap.Create;
              try
                if (ImageIndex >= 0) and (ImageIndex < Length(ColorList)) then
                  TopLeftPixelColor := ColorList[ImageIndex]
                else
                  begin
                    ListImage.GetBitmap(ImageIndex, Bitmap);
                    TopLeftPixelColor := Bitmap.Canvas.Pixels[0, 0];
                  end;
              finally
                Bitmap.Free;
              end;

              // Dessiner l'image dans la cellule avec la taille ajustée
              ListImage.Draw(TabAttribut.Canvas, ImageRect.Left, ImageRect.Top, ImageIndex);
            end
          else
            // Dessiner du texte par défaut si la valeur de l'index d'image est invalide
            TabAttribut.DefaultDrawCell(aCol, aRow, aRect, aState);
        end
      else if (aCol >= 3) and (aCol <= 6) then
        begin
          // Obtenir la couleur du pixel en haut à gauche de l'image de la cellule précédente (colonne 2)
          Bitmap := TBitmap.Create;
          try
            ImageIndex := StrToIntDef(TabAttribut.Cells[2, aRow], -1);
            if (ImageIndex >= 0) and (ImageIndex < ListImage.Count) then
              begin
                if (ImageIndex >= 0) and (ImageIndex < Length(ColorList)) then
                  TopLeftPixelColor := ColorList[ImageIndex]
                else
                  begin
                    ListImage.GetBitmap(ImageIndex, Bitmap);
                    TopLeftPixelColor := Bitmap.Canvas.Pixels[0, 0];
                  end;
              end
            else
              TopLeftPixelColor := clNone;
          finally
            Bitmap.Free;
          end;

          // Changer la couleur de fond de la cellule avec la couleur du pixel en haut à gauche de l'image
          if TopLeftPixelColor <> clNone then
            begin
              TabAttribut.Canvas.Brush.Color := TopLeftPixelColor;
              TabAttribut.Canvas.FillRect(aRect);
            end;

          // Changer la couleur du texte pour les colonnes 3 à 6
          TabAttribut.Canvas.Font.Color := clBlack;

          // Dessiner le texte de la cellule
          TabAttribut.DefaultDrawCell(aCol, aRow, aRect, aState);
        end
      else
        begin
          // Dessiner normalement le contenu textuel des autres cellules
          TabAttribut.DefaultDrawCell(aCol, aRow, aRect, aState);
        end;
    end
  else
    TabAttribut.DefaultDrawCell(aCol, aRow, aRect, aState);
end;

procedure TWinCreations.TabAttributSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
  begin
      // seul le lancé de dé est modifiable
    if (aCol <> 5)  then
      Editor := nil;
  end;

procedure TWinCreations.TrackBarPointSuppChange(Sender: TObject);
  begin
    // Récupérer la valeur actuelle du TrackBar
    CalculTabAttribut(false, (ModDesti=false));
  end;

Procedure TWinCreations.ChargeTabAttribut();
  Var
    IndTabAttribut:  Integer;
    PAttribut:       StructureAttribut;
  Begin
    IndTabAttribut        := 0;
    For PAttribut in ListeAttribut do
      begin
        Inc(IndTabAttribut);
        TabAttribut.Cells[1, IndTabAttribut] := PAttribut.Resume;
        TabAttribut.Cells[3, IndTabAttribut] := PAttribut.Libelle;
        TabAttribut.Cells[7, IndTabAttribut] := PAttribut.CodeAttribut;
      end;
  end;

procedure TWinCreations.TabAttributLanceDeSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
  begin
    if aRow = 1 then
      Begin
        CalculTabAttribut(false, false);
      end;
  end;

function TWinCreations.RepartitionMax(): Integer;
  begin
    // Rulebook V4 : 18 maxi par caracteristique ; V5 : 16
    if ValVersion = 'WFRP5' then
      Result := 16
    else
      Result := 18;
  end;

procedure TWinCreations.TabAttributLanceDeClickCombo();
  Var
    CellRect:             TRect;
    I:                    Integer;
  begin
    for I := 1 to 11 do
      begin
        CellRect := TabAttributLanceDe.CellRect(I, 2);
        // simuler un click de souris
        TabAttributLanceDe.Perform(WM_LBUTTONDOWN, 0, CellRect.Left or (CellRect.Top shl 16));
        TabAttributLanceDe.Perform(WM_LBUTTONUP, 0, CellRect.Left or (CellRect.Top shl 16));
      end;
  end;

procedure TWinCreations.ButtonAttributHasardClick(Sender: TObject);
  begin
    CalculTabAttribut(True, (RadioButtonAttributHasard.checked));
    UpdateSheetAttribut(true);
  end;

// Clemence de Shallya (Core V2 p.19) : une caracteristique du profil principal est remplacee par la
// moyenne de la race (base + 11). Le menu liste les 8 caracteristiques tirees avec leur valeur.
procedure TWinCreations.ButtonClemenceClick(Sender: TObject);
var
  MenuCl: TPopupMenu;
  Item: TMenuItem;
  I:    Integer;
  P:    TPoint;
begin
  MenuCl := TPopupMenu.Create(Self);
  for I := 1 to 8 do
    // seulement les caracteristiques que la moyenne ameliore (valeur < base + 11)
    if StrToIntDef(TabAttribut.Cells[6, I], 0) <
       StrToIntDef(Copy(TabAttribut.Cells[4, I], Pos('+', TabAttribut.Cells[4, I]) + 1, 9), 0) + 11 then
    begin
      Item         := TMenuItem.Create(MenuCl);
      Item.Caption := TabAttribut.Cells[3, I] + ' (' + TabAttribut.Cells[6, I] + ' -> ' +
        IntToStr(StrToIntDef(Copy(TabAttribut.Cells[4, I], Pos('+', TabAttribut.Cells[4, I]) + 1, 9), 0) + 11) + ')';
      Item.Tag     := I;
      Item.OnClick := @ClemenceChoisie;
      MenuCl.Items.Add(Item);
    end;
  if MenuCl.Items.Count = 0 then
    ShowMessage(GetTexteLibelle('RULES-LAB_731'))
  else
    begin
      P := ButtonClemence.ClientToScreen(Point(0, 0));
      MenuCl.PopUp(P.X, P.Y);
    end;
end;

procedure TWinCreations.ClemenceChoisie(Sender: TObject);
begin
  ClemenceRow := (Sender as TMenuItem).Tag;
  CalculTabAttribut(False, True);
end;

// Avance gratuite V2 : un palier (+5 % en profil principal, +1 en secondaire) dans une caracteristique
// dont la carriere de depart donne un plafond d'avances (<Advances>). Les bonus SB et TB ne s'avancent pas.
function TWinCreations.AvancesGratuitesPossibles(): TStringList;
var
  PAvance: StructureMetierAvance;
begin
  Result := TStringList.Create;
  for PAvance in ListMetierAvance do
    if CompareRechercheValeur(PAvance.CodeMetier, MetierEnCours) and (PAvance.Plafond > 0)
       and (Result.IndexOf(PAvance.CodeAttribut) < 0)
       and (Pos('_SB', PAvance.CodeAttribut) = 0) and (Pos('_TB', PAvance.CodeAttribut) = 0) then
      Result.Add(PAvance.CodeAttribut);
end;

// Nombre d'avances gratuites : un familier lie (ethnie animale de la race Familiar) en a deux, tout
// autre personnage une seule (le familier cree aussi : Realms of Sorcery p.189).
function TWinCreations.NbAvancesGratuites(): Integer;
begin
  if (Pos('_FAMILIAR_', RaceEnCours) > 0) and (Pos('_CREATED', RaceEnCours) = 0) then
    Result := 2
  else
    Result := 1;
end;

function LibelleAttributTab(Tab: TStringGrid; Code: String): String;
var
  I: Integer;
begin
  Result := Code;
  for I := 1 to Tab.RowCount - 1 do
    if Tab.Cells[7, I] = Code then
      Exit(Tab.Cells[3, I]);
end;

// V2 : une ligne par race des livres choisis, la race en cours est cochee.
procedure TWinCreations.RemplirGridRace();
var
  PRace: StructureRace;
  N:     Integer;
  Lignes: TStringList;
  Champs: TStringArray;
begin
  if GridRace = nil then Exit;
  // lignes triees par libelle de race puis par libelle de livre (cle : libelle #1 livre #1 code)
  Lignes := TStringList.Create;
  try
    Lignes.CaseSensitive := False;
    for PRace in ListRace do
      if Pos(AjouteAccolade(PRace.Livre), LivresPersonnages) > 0 then
        Lignes.Add(PRace.Libelle + #1 + GetTexteLibelle(PRace.Livre, '', '', true) + #1 + PRace.CodeRace);
    Lignes.Sort;
    N := 0;
    for N := 1 to Lignes.Count do
      begin
        Champs := Lignes[N - 1].Split([#1]);
        GridRace.RowCount := N + 1;
        if Champs[2] = RaceEnCours then
          GridRace.Cells[0, N] := '✔'
        else
          GridRace.Cells[0, N] := '';
        GridRace.Cells[1, N] := Champs[2];
        GridRace.Cells[2, N] := Champs[0];
        GridRace.Cells[3, N] := Champs[1];
      end;
    N := Lignes.Count;
  finally
    Lignes.Free;
  end;
  if N = 0 then
    GridRace.RowCount := 1;
  // largeur fixee ici (page affichee) : a la creation la page n'a pas encore sa taille
  GridRace.ScrollBars    := ssAutoVertical;
  GridRace.Width         := 520;
  GridRace.ColWidths[0]  := 36;
  GridRace.ColWidths[3]  := 200;
  GridRace.ColWidths[2]  := GridRace.Width - GridRace.ColWidths[0] - GridRace.ColWidths[3] - 24;
  // remontee en haut de la page (le cadre "Type de choix" est cache en V2) et bornee a la page :
  // plus haute que la page, l'ascenseur sortait de l'ecran
  // le bouton Selectionner passe en haut, la grille se met juste dessous
  ButtonRaceSelectionner.Top := 48;
  ButtonRaceSelectionner.BringToFront;
  GridRace.Top           := ButtonRaceSelectionner.Top + ButtonRaceSelectionner.Height + 8;
  GridRace.Anchors       := [akTop, akLeft, akBottom];
  // bouton Hasard sous la grille, ancre en bas : il descend avec la page, la grille grandit au-dessus
  ButtonRaceHasard.Anchors := [akLeft, akBottom];
  ButtonRaceHasard.Left    := GridRace.Left;
  ButtonRaceHasard.Top     := TabSheetRace.ClientHeight - ButtonRaceHasard.Height - 8;
  ButtonRaceHasard.BringToFront;
  GridRace.Height        := GridRace.DefaultRowHeight * GridRace.RowCount + 5;
  if GridRace.Height > ButtonRaceHasard.Top - GridRace.Top - 8 then
    GridRace.Height      := ButtonRaceHasard.Top - GridRace.Top - 8;
end;

procedure TWinCreations.GridRaceDblClick(Sender: TObject);
begin
  if GridRace.Row < 1 then Exit;
  ChoixWinRace := GridRace.Cells[1, GridRace.Row];
  if ChoixWinRace <> '' then
    begin
      TabRaceResultat(0);
      AfficheImageRace();
      UpdateSheetRace(true);
      RemplirGridRace();
    end;
  ChoixWinRace := '';
end;

// Remplit la grille de l'avance gratuite : une ligne par caracteristique dont la carriere donne un plafond.
// La valeur actuelle vient de TabAttribut (phase 4), vide si elle n'est pas encore tiree.
procedure TWinCreations.RemplirGridAvance();
var
  Codes:   TStringList;
  I, J:    Integer;
  Suffixe: String;
begin
  if GridAvance = nil then Exit;
  Codes := AvancesGratuitesPossibles();
  try
    if Codes.IndexOf(AvanceGratuiteCode) < 0 then
      AvanceGratuiteCode := '';
    if (Codes.IndexOf(AvanceGratuiteCode2) < 0) or (NbAvancesGratuites() < 2) then
      AvanceGratuiteCode2 := '';
    if (AvanceGratuiteCode = '') and (AvanceGratuiteCode2 <> '') then
      begin
        AvanceGratuiteCode  := AvanceGratuiteCode2;
        AvanceGratuiteCode2 := '';
      end;
    GridAvance.RowCount := Codes.Count + 1;
    for I := 0 to Codes.Count - 1 do
      begin
        if PasAvance(Codes[I]) >= 5 then Suffixe := ' %' else Suffixe := '';
        GridAvance.Cells[0, I + 1] := '';
        GridAvance.Cells[2, I + 1] := '';
        if ValVersion = 'WFRP1' then
          begin
            // V1 : libelle et valeur viennent des lignes de CreationV1Obj, pas de TabAttribut
            GridAvance.Cells[1, I + 1] := Codes[I];
            for J := 0 to CreationV1Obj.NbLignes() - 1 do
              if CreationV1Obj.LigneCode(J) = Codes[I] then
                begin
                  GridAvance.Cells[1, I + 1] := CreationV1Obj.LigneLibelle(J);
                  GridAvance.Cells[2, I + 1] := IntToStr(CreationV1Obj.LigneValeur(J));
                end;
          end
        else
          begin
            GridAvance.Cells[1, I + 1] := LibelleAttributTab(TabAttribut, Codes[I]);
            for J := 1 to TabAttribut.RowCount - 1 do
              if TabAttribut.Cells[7, J] = Codes[I] then
                GridAvance.Cells[2, I + 1] := TabAttribut.Cells[6, J];
          end;
        GridAvance.Cells[3, I + 1] := '+' + IntToStr(PlafondAvanceMetier(MetierEnCours, Codes[I])) + Suffixe;
        GridAvance.Cells[4, I + 1] := '+' + IntToStr(PasAvance(Codes[I])) + Suffixe;
        // le code reste dans l'objet de la ligne, jamais affiche
        GridAvance.Objects[0, I + 1] := TObject(PtrInt(I));
        if (Codes[I] = AvanceGratuiteCode) or (Codes[I] = AvanceGratuiteCode2) then
          GridAvance.Cells[0, I + 1] := '✔';
      end;
  finally
    Codes.Free;
  end;
end;

// Double-clic : choisit l'avance de la ligne, ou la retire si elle l'est deja.
procedure TWinCreations.GridAvanceDblClick(Sender: TObject);
var
  Codes: TStringList;
  Ligne: Integer;
begin
  Ligne := GridAvance.Row;
  if Ligne < 1 then Exit;
  Codes := AvancesGratuitesPossibles();
  try
    if Ligne - 1 >= Codes.Count then Exit;
    if AvanceGratuiteCode2 = Codes[Ligne - 1] then
      AvanceGratuiteCode2 := ''
    else if AvanceGratuiteCode = Codes[Ligne - 1] then
      begin
        // retrait de la premiere : la seconde (s'il y en a une) prend sa place
        AvanceGratuiteCode  := AvanceGratuiteCode2;
        AvanceGratuiteCode2 := '';
      end
    else if AvanceGratuiteCode = '' then
      AvanceGratuiteCode := Codes[Ligne - 1]
    else if NbAvancesGratuites() < 2 then
      AvanceGratuiteCode := Codes[Ligne - 1]
    else
      AvanceGratuiteCode2 := Codes[Ligne - 1];
  finally
    Codes.Free;
  end;
  RemplirGridAvance();
end;

procedure TWinCreations.CalculTabAttribut(Hasard: Boolean; Affectation: Boolean);
var
  PartDe:               String;
  TypeDe:               Integer;
  NbDe:                 Integer;
  PlusDe:               Integer;
  TotalDe:              Integer;
  I,J:                  Integer;
  Ch:                   String;
  IndS:                 Integer;
  TotL:                 Integer;
  ComboBoxAttribut:     TComboBox;
  Index:                Integer;
  Car:                  String;
  ColCombo, RowCombo:   Integer;
  BF, BE, BFM:          Integer;
  Jet:                  PInteger;
begin
  TotL := 0;
    // vider les colonnes
    For I:= 1 to TabAttribut.RowCount -1 do
    begin
      TabAttribut.Cells[5, I] := '';
      TabAttribut.Cells[6, I] := '';
    end;

  For I:= 1 to TabAttribut.RowCount -1 do
    begin
      Ch := TabAttribut.Cells[4, I];
      // V2 : seules 8 caracteristiques se tirent (2d10+...), les suivantes sont fixes
      if (I <= 10) and (Pos('+', Ch) > 0) then
      // caractéristoqies normales
          begin
            // séparer les dé du bonus
            IndS := Pos('+', Ch);
            PartDe := Copy(Ch, 1, IndS-1);
            PlusDe := StrToInt(Copy(Ch, IndS+1, Length(Ch)));
            // séparer le nombre de dé du type
            IndS := Pos('d', PartDe);
             if IndS > 0 then
               begin
                 NbDe  := StrToInt(Copy(PartDe, 1, IndS-1));
                 TypeDe:= StrToInt(Copy(PartDe, IndS+1, Length(PartDe)));
               end
             else
               begin
                 NbDe  := 1;
                 TypeDe:= StrToInt(Copy(PartDe, 2, IndS));
               end;

             if Hasard then
               begin
                 TotalDe    := 0;
                 for J := 1 to NbDe Do
                   TotalDe := TotalDe + (Random(TypeDe) + 1);
                 TabAttributLanceDe.Cells[i, 1] := intToStr(TotalDe);
               end
             else
                TotalDe := StrToIntDef(TabAttributLanceDe.Cells[i, 1],0);

             TotL := TotL + TotalDe;
             Index:= -1;
             ComboBoxAttribut := TabAttributLanceDe.Objects[I, 2] as TComboBox;
             if ModRepartition then
               begin
                 // pas d'affectation : la colonne I va a l'attribut I
                 Index    := I;
                 ColCombo := I;
               end
             else if Affectation then
               begin
                 Car                        := TabAttribut.cells[1, I];
                 Index                      := ComboBoxAttribut.Items.IndexOf(Car);
                 if Index > 0 then
                   begin
                    ComboBoxAttribut.enabled   := true;
                    ComboBoxAttribut.ItemIndex := Index;
                    ColCombo                   := I;
                   end
               end
             else
               begin
                 Car   := ComboBoxAttribut.Text;
                 if Car <> ValeurNonRenseignee then
                   begin
                     Index := ComboBoxAttribut.Items.IndexOf(Car);
                     TabAttributLanceDe.MouseToCell(ComboBoxAttribut.Left, ComboBoxAttribut.Top, ColCombo, RowCombo);
                   end
               end;

          if Index > 0 then
            begin
              TabAttribut.Cells[5, Index] := TabAttributLanceDe.Cells[ColCombo, 1];
              TabAttribut.Cells[6, Index] := IntToStr(StrToIntDef(TabAttributLanceDe.Cells[Index, 1],0)+ PlusDe);
              // Clemence de Shallya (V2) : la caracteristique choisie vaut base + 11 (moyenne de 2d10)
              if (ValVersion = 'WFRP2') and (ClemenceRow = Index) then
                TabAttribut.Cells[6, Index] := IntToStr(PlusDe + 11);
              if TabAttribut.Cells[7, Index] = ConstCaracE then
                BE := StrToInt(TabAttribut.Cells[6, Index])
              else if TabAttribut.Cells[7, Index] = ConstCaracF then
                BF := StrToInt(TabAttribut.Cells[6, Index])
              else if TabAttribut.Cells[7, Index] = ConstCaracFM then
                BFM := StrToInt(TabAttribut.Cells[6, Index]);
              end
          end
     else if TabAttribut.Cells[7, I] = ConstCaracBlessure then
       begin
          TabAttribut.Cells[6, I] := IntToStr(CalculBlessure(Ch, BF, BE, BFM));
       end
     else if ValVersion = 'WFRP2' then
       begin
         // V2 : bonus = dizaine de la caracteristique ; autres valeurs fixes recopiees
         // (Blessures et Destin : tables 2-2 et 2-3, pas encore structurees)
         if TabAttribut.Cells[7, I] = 'RULES-ATTR_SB' then
           TabAttribut.Cells[6, I] := IntToStr(BF div 10)
         else if TabAttribut.Cells[7, I] = 'RULES-ATTR_TB' then
           TabAttribut.Cells[6, I] := IntToStr(BE div 10)
         else if ((TabAttribut.Cells[7, I] = 'RULES-ATTR_W') or (TabAttribut.Cells[7, I] = 'RULES-ATTR_FP')
                  or (TabAttribut.Cells[7, I] = 'RULES-ATTR_M'))
                 and (Pos(':', Ch) > 0) then
           begin
             // tables 2-2 / 2-3 (et Mouvement du familier cree) : un d10 par table, tire au Hasard (ou une fois en saisie manuelle)
             if TabAttribut.Cells[7, I] = 'RULES-ATTR_W' then
               Jet := @JetBlessureV2
             else if TabAttribut.Cells[7, I] = 'RULES-ATTR_M' then
               Jet := @JetMouvementV2
             else
               Jet := @JetDestinV2;
             if Hasard or ((Jet^ = 0) and not RadioButtonAttributHasard.Checked
                           and not RadioButtonAttributHasardAffecte.Checked) then
               Jet^ := Random(10) + 1;
             if Jet^ > 0 then
               begin
                 TabAttribut.Cells[5, I] := IntToStr(Jet^);
                 TabAttribut.Cells[6, I] := IntToStr(ValeurTableD10(Ch, Jet^));
               end;
           end
         else if StrToIntDef(Ch, -1) >= 0 then
           TabAttribut.Cells[6, I] := Ch;
       end
     else if TabAttribut.Cells[7, I] = ConstCaracDestin then
       begin
         TabAttribut.Cells[5, I]  := IntToStr(TrackBarPointSupp.Max - TrackBarPointSupp.Position);
          TabAttribut.Cells[6, I] := IntToStr(StrToInt(TabAttribut.Cells[4, I]) + StrToIntDef(TabAttribut.Cells[5, I],0));
       end
     else if TabAttribut.Cells[7, I] = ConstCaracResil then
       begin
         TabAttribut.Cells[5, I] := IntToStr(TrackBarPointSupp.Position);
         TabAttribut.Cells[6, I] := IntToStr(StrToInt(TabAttribut.Cells[4, I]) + StrToIntDef(TabAttribut.Cells[5, I],0));
       end
    end;
    TabAttributLanceDe.Cells[11, 1] := InttoStr(TotL);
    if ModRepartition then
      TabAttributLanceDe.Cells[11, 0] := Format(GetTexteLibelle('RULES-LAB_317'), [100 - TotL])
    else
      TabAttributLanceDe.Cells[11, 0] := GetTexteLibelle('RULES-LAB_021');
    UpdateSheetAttribut(false);
end;

procedure TWinCreations.ComboBoxSelectAttribut(Sender: TObject);
Var
   AttEnCours:        String;
   AttLigne:          String;
   ComboBoxAttribut:  TCombobox;
   Col, Row, C:       Integer;
   Index:             Integer;
begin
  ComboBoxAttribut := Sender as TComboBox;
  TabAttributLanceDe.MouseToCell(ComboBoxAttribut.Left, ComboBoxAttribut.Top, Col, Row);

  AttEnCours       := ComboBoxAttribut.Text;

  //// voir si elle n'est pas déjà utilisée
  for C := 1 to TabAttributLanceDe.colCount -2 do
    if (C <> Col) then
      begin
        ComboBoxAttribut :=   TabAttributLanceDe.Objects[C, TabAttributLanceDe.Row] as TComboBox;
        if Assigned(ComboBoxAttribut) then
          begin
            AttLigne       := ComboBoxAttribut.Text;

            if (AttLigne <> '') and (AttLigne = AttEncours) then
               begin
                  Index := ComboBoxAttribut.Items.IndexOf(ValeurNonRenseignee);
                  ComboBoxAttribut.ItemIndex := Index;
               end;
          end;
      end;

  CalculTabAttribut(False, (RadioButtonAttributHasard.checked));
end;

procedure TWinCreations.UpdateSheetAttribut(Hasard: boolean);
Var
  I: Integer;
Begin
  if CreationV1Obj <> nil then Exit;   // V1 : onglet rempli par CreationV1
  ButtonAttributHasard.Visible    := (RadioButtonAttributHasard.Checked or RadioButtonAttributHasardAffecte.Checked);
  ButtonAttributHasard.BringToFront;
  ModDesti                        := (RadioButtonAttributHasardAffecte.Checked or RadioButtonAttributResultatAffecte.Checked);
  ModRepartition                  := RadioButtonAttributRepartition.Checked;
  if ModRepartition then
    for I := 1 to 11 do
      if Assigned(TabAttributLanceDe.Objects[I, 2]) then
        (TabAttributLanceDe.Objects[I, 2] as TComboBox).Visible := false;
  TabAttributLanceDe.visible      := true;
  TabAttribut.enabled             := false;
  if ValVersion = 'WFRP2' then
    begin
      // V2 : 8 caracteristiques tirees (pas de D9, D10) et ni Destin/Resilience ni
      // points supplementaires (Destin = table 2-3)
      for I := 9 to 10 do
        begin
          TabAttributLanceDe.ColWidths[I] := 0;
          if Assigned(TabAttributLanceDe.Objects[I, 2]) then
            (TabAttributLanceDe.Objects[I, 2] as TComboBox).Visible := false;
        end;
      // le Core impose l'ordre de la table 2-1 : ni affectation libre ni 100 points
      RadioButtonAttributHasardAffecte.Visible   := false;
      RadioButtonAttributResultatAffecte.Visible := false;
      RadioButtonAttributRepartition.Visible     := false;
      if Assigned(ButtonClemence) then
        ButtonClemence.Enabled := (ClemenceRow = 0) and (TabAttribut.Cells[6, 1] <> '');
      TrackBarPointSupp.Visible := false;
      LabDestin.Visible         := false;
      LabResilience.Visible     := false;
      LabPointSupp.Visible      := false;
    end;

  if Hasard then
    begin
      // Tirage fait : plus de nouveau tirage, mais les 100 points restent permis (dernier palier du Rulebook)
      RadioButtonAttributHasard.Enabled          := false;
      RadioButtonAttributResultat.Enabled        := false;
      RadioButtonAttributHasardAffecte.Enabled   := false;
      RadioButtonAttributResultatAffecte.Enabled := false;
      ButtonAttributHasard.Enabled:= false;
    end;
end;




////////////////////////////////////////////////////////////////////////////////
//                              TALENTS                                       //
////////////////////////////////////////////////////////////////////////////////

// Information seule : ce que donne le MEME jet sous chacune des autres règles qui touchent
// l'ethnie (la table de base comprise), quand le métier diffère de celui retenu. La règle
// choisie dans le combo reste la seule qui compte. Une règle qui ne couvre pas l'ethnie
// retombe sur la table de base (RegleCouvreRace) : elle n'apporte rien et est ignorée.
procedure TWinCreations.AfficheMetierAutresRegles(Resul: Integer; CodeMetier: String);
  var
    Tirage:   TListTirageMetier;
    Lignes:   TStringList;
    Courante: String;
    PRegle:   StructureRegle;

  procedure Essaie(CodeRegle, LibRegle: String);
    var
      Ligne: StructureTirageMetier;
    begin
      if CodeRegle = Courante then
        exit;
      if (CodeRegle <> '') and not RegleCouvreRace(CodeRegle, RaceEnCours) then
        exit;
      CalculeTirageMetier(RaceEnCours, CodeRegle, Tirage);
      For Ligne in Tirage do
        if (Ligne.Debut <= Resul) and (Resul <= Ligne.Fin) then
          begin
            if Ligne.CodeMetier <> CodeMetier then
              Lignes.Add(Format(GetTexteLibelle('RULES-LAB_578'), [LibRegle, ChercheMetier(Ligne.CodeMetier).Libelle]));
            break;
          end;
    end;

  begin
    MemoMetierRegles.Visible := false;
    if (CodeMetier = '') or (ListRegle.Count = 0) then
      exit;
    Courante := RegleEnCours();
    Tirage   := TListTirageMetier.Create;
    Lignes   := TStringList.Create;
    try
      Essaie('', GetTexteLibelle(ConstRulesBook, '', '', true));
      For PRegle in ListRegle do
        if not RegleDesactivee(PRegle.Livre, PRegle.CodeRegle) then
          Essaie(PRegle.CodeRegle, PRegle.Libelle);
      if Lignes.Count > 0 then
        begin
          Lignes.Insert(0, GetTexteLibelle('RULES-LAB_577'));
          MemoMetierRegles.Lines.Assign(Lignes);
          MemoMetierRegles.Visible := true;
        end;
    finally
      Lignes.Free;
      Tirage.Free;
    end;
  end;

procedure TWinCreations.TabMetierResultat(Resul: Integer);
  var
    IndTab:   Integer;
    Deb:      Integer = 0;
    Fin:      Integer = 0;
    Ch:       String;
    IndS:     Integer;
    SousM:    Boolean = False;
    RaceC:    Boolean = False;
  begin
    MemoMetierRegles.Visible := false;
    for IndTab := 1 to TabMetier.RowCount-1 do
      begin
        Ch := TabMetier.Cells[3, IndTab];
        DebutFin(Ch, Deb, Fin);
        // d1000 : le livre imprime 1000 sous la forme 000
        if Deb = 0 then
          Deb := 1000;
        if Fin = 0 then
          Fin := 1000;
        if ChoixWinMetierRace <> '' then
          begin
            if TabMEtier.Cells[1, Indtab] = ChoixWinMetierRace then
              begin
                IndS := Pos(SeparateurChance, Ch);
                if IndS > 0 then
                  Resul := StrToInt(Copy(Ch, 1, IndS-1))
                else
                  Resul := StrToInt(Ch);
              end
            else
              Deb := DesMetier + 1;
          end;

        if (Deb <= Resul) and (Resul <= Fin) then
          begin
            AffMetierSousMetier.text := TexteMetierSousMetier(TabMetier.Cells[1, indTab], LivresPersonnages);
            if AffMetierSousMetier.text <> '' then
              SousM := True
            else
              begin
                AffMetierSousMetier.text := TexteMetierRaceChoixMetier(TabMetier.Cells[1, indTab], RaceEnCours, LivresPersonnages);
                if AffMetierSousMetier.text <> '' then
                  RaceC := True;
              end;
            if not SousM and not RaceC then
              begin
                MetierEnCours              := TabMetier.Cells[1, indTab];
                MetierLibEnCours           := TabMetier.Cells[2, indTab];
                TabMetier.Cells[4, IndTab] := '1';
                TabMetier.TopRow           := indtab;
                TabMetier.Invalidate;
                AfficheMetierAutresRegles(Resul, MetierEnCours);
              end
            else
              begin
                if SousM then
                  begin
                    // second jet de dé
                    MetierEnCoursPrincipal                := TabMetier.Cells[1, indTab];
                    EditMetierSousMetierResultat.visible  := true;
                    ButtonMetierSousMetierValider.visible := true;
                    ButtonMetierSousMetierValider.BringToFront;
                    AffMetierSousMetier.visible           := true;
                  end
                else
                  begin
                    MetierEnCours                              := ResultMetierRaceChoixMetier(TabMetier.Cells[1, indTab], RaceEnCours, LivresPersonnages);
                    ButtonMetierSousMetierSelectionner.visible := true;
                    ButtonMetierSousMetierSelectionner.BringToFront;
                    AffMetierSousMetier.visible                := true;
                  end;
              end;
            Break;
          end
      end;
  end;

////////////////////////////////////////////////////////////////////////////////
//                          COMPETENCES DE RACE                               //
////////////////////////////////////////////////////////////////////////////////


procedure TWinCreations.TabRaceCompetenceDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  CheckChar: string;
  ImageIndex: Integer;

  // Couleur de fond de l'icone de la ligne (colonne 2) : ColorList, sinon pixel en haut a gauche ;
  // clNone si la ligne n'a pas d'icone valide.
  function CouleurFondLigne(Ligne: Integer): TColor;
  var
    Indice: Integer;
    Bitmap: TBitmap;
  begin
    Result := clNone;
    Indice := StrToIntDef(TabRaceCompetence.Cells[2, Ligne], -1);
    if (Indice < 0) or (Indice >= ListImage.Count) then
      exit;
    if Indice < Length(ColorList) then
      Result := ColorList[Indice]
    else
      begin
        Bitmap := TBitmap.Create;
        try
          ListImage.GetBitmap(Indice, Bitmap);
          Result := Bitmap.Canvas.Pixels[0, 0];
        finally
          Bitmap.Free;
        end;
      end;
  end;

  // Remplit la cellule avec la couleur de fond de l'icone de sa ligne.
  procedure RemplirFondIcone;
  var
    Couleur: TColor;
  begin
    Couleur := CouleurFondLigne(aRow);
    if Couleur <> clNone then
      begin
        TabRaceCompetence.Canvas.Brush.Color := Couleur;
        TabRaceCompetence.Canvas.FillRect(aRect);
      end;
  end;

  // Colonne 2 : icone, reduite au cadre de la cellule en gardant ses proportions, centree.
  procedure DessineIcone;
  var
    CellWidth, CellHeight: Integer;
    ImageWidth, ImageHeight: Integer;
    AspectRatio: Double;
    LeftOffset, TopOffset: Integer;
  begin
    CellWidth := aRect.Right - aRect.Left;
    CellHeight := aRect.Bottom - aRect.Top;
    ImageWidth := ListImage.Width;
    ImageHeight := ListImage.Height;
    if ImageWidth > 0 then
      begin
        AspectRatio := ImageHeight / ImageWidth;
        if ImageWidth > CellWidth then
          begin
            ImageWidth := CellWidth;
            ImageHeight := Round(ImageWidth * AspectRatio);
          end;
        if ImageHeight > CellHeight then
          begin
            ImageHeight := CellHeight;
            ImageWidth := Round(ImageHeight / AspectRatio);
          end;
      end;
    LeftOffset := (CellWidth - ImageWidth) div 2;
    TopOffset := (CellHeight - ImageHeight) div 2;
    ListImage.Draw(TabRaceCompetence.Canvas, aRect.Left + LeftOffset, aRect.Top + TopOffset, ImageIndex);
  end;

begin
  if (aCol = 2) and (aRow > 0) then
    begin
      ImageIndex := StrToIntDef(TabRaceCompetence.Cells[aCol, aRow], -1);
      if (ImageIndex >= 0) and (ImageIndex < ListImage.Count) then
        DessineIcone
      else
        // index d'image invalide : texte par defaut
        TabRaceCompetence.DefaultDrawCell(aCol, aRow, aRect, aState);
    end
  else if (aCol = 3) then
    begin
      RemplirFondIcone;
      TabRaceCompetence.Canvas.Font.Color := clBlack;
      TabRaceCompetence.DefaultDrawCell(aCol, aRow, aRect, aState);
    end
  else if (aCol in [4,5]) and (aRow > 0) and (aRow <= NbRaceCompetenceTab) then
    begin
      RemplirFondIcone;
      if CompetenceRaceStates[aCol, aRow] then
        CheckChar := CheckCharChecked
      else
        CheckChar := CheckCharUnchecked;
      TabRaceCompetence.Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, CheckChar);
    end
  else
    TabRaceCompetence.DefaultDrawCell(aCol, aRow, aRect, aState);
end;

procedure TWinCreations.ClickRaceCompetence(aCol, aRow: Integer);
Begin
  if (aCol in [4,5]) and (ValVersion <> 'WFRP2') then
  begin
    CompetenceRaceStates[ACol, ARow] := not CompetenceRaceStates[ACol, ARow];
    TabRaceCompetence.InvalidateCell(ACol, ARow);
    if CompetenceRaceStates[ACol, ARow] = true then
      begin
        case aCol of
          4: begin
               CompetenceRaceStates[5, ARow]    := false;
               TabRaceCompetence.InvalidateCell(5, ARow);
             end;
          5: begin
               CompetenceRaceStates[4, ARow]    := false;
               TabRaceCompetence.InvalidateCell(4, ARow);
             end;
         end;
      end;
      CalculNbRaceCompetence();
  end;
end;


procedure TWinCreations.TabRaceCompetenceMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
begin
  TabRaceCompetence.MouseToCell(X, Y, ACol, ARow);
  if (ARow > 0) then
    ClickRaceCompetence(aCol, aRow);
end;

procedure TWinCreations.ButtonRaceCompetenceHasardClick(Sender: TObject);
  var
    IndTab:    Integer;
    IndPass:   Integer;
    PRaceNb:   StructureRace;
    Choix:     String;
  begin
    // le nombre a atteindre vient de l'ethnie (3 et 3 partout, 2 et 2 pour le Skink)
    PRaceNb := ChercheRace(RaceEnCours);
    // vérifier s'il reste des Cing ou trois
    if (ValVersion <> 'WFRP2') and ((NbCinq < PRaceNb.NbPoint5) or (NbTrois < PRaceNb.NbPoint3)) then
      for IndPass := 1 to 3 do
          for IndTab := 1 to TabRaceCompetence.RowCount-1 do
              if (not CompetenceRaceStates[4, IndTab]) and (not CompetenceRaceStates[5, IndTab]) then
                if ((IndPass in [1,2]) and (StrToIntDef(TabRaceCompetence.Cells[2, IndTab],0) > 0)) or (IndPass = 3) then
                  if (IndPass in [1,3]) and (NbCinq < PRaceNb.NbPoint5) then
                    ClickRaceCompetence(4, IndTab)
                  else if (IndPass in [2,3]) and (NbTrois < PRaceNb.NbPoint3) then
                    ClickRaceCompetence(5, IndTab);
    // resoudre les lignes cochees encore au choix ("Trade (Any)", "A or B")
    for IndTab := 1 to TabRaceCompetence.RowCount-1 do
      if (CompetenceRaceStates[4, IndTab] or CompetenceRaceStates[5, IndTab]) and
         ((Pos(ValeurGenerique, TabRaceCompetence.Cells[1, IndTab]) > 0) or
          (Pos(SeparateurMulti, TabRaceCompetence.Cells[1, IndTab]) > 0)) then
        begin
          Choix := CompetenceAuHasard(TabRaceCompetence, TabRaceCompetence.Cells[1, IndTab]);
          if Choix <> '' then
            begin
              TabRaceCompetence.Cells[1, IndTab] := Choix;
              TabRaceCompetence.Cells[3, IndTab] := ChercheCompetence(Choix).Libelle;
            end;
        end;
  end;

function TWinCreations.CompetenceAuHasard(Grille: TStringGrid; const CodeGen: String): String;
  var
    Opts:    TStringList;
    Libres:  TStringList;
    Filtres: TStringList;
    I, J:    Integer;
    Deja:    Boolean;
  begin
    Result  := '';
    Opts    := ListeMetierCompetence(CodeGen);
    Libres  := TStringList.Create;
    Filtres := TStringList.Create;
    try
      for I := 0 to Opts.Count - 1 do
        if VerifieFiltre(ChercheCompetence(Opts[I]).Livre, LivresPersonnages) then
          begin
            Filtres.Add(Opts[I]);
            Deja := False;
            for J := 1 to Grille.RowCount - 1 do
              if Grille.Cells[1, J] = Opts[I] then
                Deja := True;
            if not Deja then
              Libres.Add(Opts[I]);
          end;
      // repli : mieux vaut un doublon ou un livre hors selection qu'un choix vide qui bloque l'etape
      if Libres.Count > 0 then
        Result := Libres[Random(Libres.Count)]
      else if Filtres.Count > 0 then
        Result := Filtres[Random(Filtres.Count)]
      else if Opts.Count > 0 then
        Result := Opts[Random(Opts.Count)];
    finally
      Opts.Free;
      Libres.Free;
      Filtres.Free;
    end;
  end;

procedure TWinCreations.CalculNbRaceCompetence();
Var
  IndTab: Integer;
Begin
  NbTrois := 0;
  NbCinq  := 0;
  for IndTab := 1 to TabRaceCompetence.RowCount -1 do
    begin
      if CompetenceRaceStates[4, IndTab] then
        NbCinq := NbCinq + 1;
      if CompetenceRaceStates[5, IndTab] then
        NbTrois:= NbTrois + 1;
    end;
end;


////////////////////////////////////////////////////////////////////////////////
//                         COMPETENCES DE METIER                              //
////////////////////////////////////////////////////////////////////////////////


procedure TWinCreations.TabMetierCompetenceDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
  Var
    ImageIndex: Integer;
    CellWidth, CellHeight: Integer;
    MaxWidth, MaxHeight, ImageWidth, ImageHeight: Integer;
    AspectRatio: Double;
    LeftOffset, TopOffset: Integer;
    ImageRect: TRect;
    TopLeftPixelColor: TColor;
    Bitmap: TBitmap;
  begin
    if (aCol = 2) and (aRow > 0) then
        begin
        // Récupérer la valeur de la cellule correspondante (colonne 2)
        ImageIndex := StrToIntDef(TabMetierCompetence.Cells[aCol, aRow], -1);

        // Vérifier que la valeur est valide et se situe dans la plage d'index d'image
        if (ImageIndex >= 0) and (ImageIndex < ListImage.Count) then
        begin
          // Calculer la taille de la cellule
          CellWidth := aRect.Right - aRect.Left;
          CellHeight := aRect.Bottom - aRect.Top;

          // Calculer la taille maximale pour l'image en utilisant la taille de la cellule
          // et en ajustant l'aspect ratio de l'image
          MaxWidth := CellWidth;
          MaxHeight := CellHeight;
          ImageWidth := ListImage.Width;
          ImageHeight := ListImage.Height;
          if ImageWidth > 0 then
          begin
            AspectRatio := ImageHeight / ImageWidth;
            if ImageWidth > MaxWidth then
            begin
              ImageWidth := MaxWidth;
              ImageHeight := Round(ImageWidth * AspectRatio);
            end;
            if ImageHeight > MaxHeight then
            begin
              ImageHeight := MaxHeight;
              ImageWidth := Round(ImageHeight / AspectRatio);
            end;
          end;

          // Calculer la position de l'image pour centrer verticalement et horizontalement
          // dans la cellule
          LeftOffset := (CellWidth - ImageWidth) div 2;
          TopOffset := (CellHeight - ImageHeight) div 2;
          ImageRect := Rect(aRect.Left + LeftOffset, aRect.Top + TopOffset, aRect.Left + LeftOffset + ImageWidth, aRect.Top + TopOffset + ImageHeight);

          // Obtenir la couleur du pixel en haut à gauche de l'image
          Bitmap := TBitmap.Create;
          try
            if (ImageIndex >= 0) and (ImageIndex < Length(ColorList)) then
              TopLeftPixelColor := ColorList[ImageIndex]
            else
              begin
                ListImage.GetBitmap(ImageIndex, Bitmap);
                TopLeftPixelColor := Bitmap.Canvas.Pixels[0, 0];
              end;
          finally
            Bitmap.Free;
          end;

          // Dessiner l'image dans la cellule avec la taille ajustée
          ListImage.Draw(TabMetierCompetence.Canvas, ImageRect.Left, ImageRect.Top, ImageIndex);
        end
        else
          // Dessiner du texte par défaut si la valeur de l'index d'image est invalide
          TabMetierCompetence.DefaultDrawCell(aCol, aRow, aRect, aState);
      end
      else if (aCol > 2) and (aRow > 0) then
      begin
        // Obtenir la couleur du pixel en haut à gauche de l'image de la cellule précédente (colonne 2)
        Bitmap := TBitmap.Create;
        try
          ImageIndex := StrToIntDef(TabMetierCompetence.Cells[2, aRow], -1);
          if (ImageIndex >= 0) and (ImageIndex < ListImage.Count) then
          begin
            if (ImageIndex >= 0) and (ImageIndex < Length(ColorList)) then
              TopLeftPixelColor := ColorList[ImageIndex]
            else
              begin
                ListImage.GetBitmap(ImageIndex, Bitmap);
                TopLeftPixelColor := Bitmap.Canvas.Pixels[0, 0];
              end;
          end
          else
            TopLeftPixelColor := clNone;
        finally
          Bitmap.Free;
        end;

        // Changer la couleur de fond de la cellule avec la couleur du pixel en haut à gauche de l'image
        if TopLeftPixelColor <> clNone then
        begin
          TabMetierCompetence.Canvas.Brush.Color := TopLeftPixelColor;
          TabMetierCompetence.Canvas.FillRect(aRect);
        end;

        // Changer la couleur du texte
        TabMetierCompetence.Canvas.Font.Color := clBlack;

        // Dessiner le texte de la cellule
        TabMetierCompetence.DefaultDrawCell(aCol, aRow, aRect, aState);
      end
     else
      begin
        // Dessiner normalement le contenu textuel des autres cellules
        TabMetierCompetence.DefaultDrawCell(aCol, aRow, aRect, aState);
      end;

  end;

procedure TWinCreations.TabMetierCompetenceSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
  begin
    // seul la saisie des 40 points est modifiable (jamais en V2 : nombre de prises calcule)
    if (aCol <> 4) or (ValVersion = 'WFRP2') then
      Editor := nil;
  end;


procedure TWinCreations.TabMetierCompetenceValidateEntry(Sender: TObject; aCol,
  aRow: Integer; const OldValue: string; var NewValue: String);
  var
    Value: Integer;
  begin
    // Vérifiez si la colonne concernée est celle qui doit contenir les chiffres entre 0 et 10
    if aCol = 4 then
    begin
      if NewValue <> '' then
      begin
        // Vérifiez si la valeur est un entier valide
        if TryStrToInt(NewValue, Value) then
          begin
            // Vérifiez si la valeur est comprise entre 0 et 10
            if (Value < 0) or (Value > 10) then
              begin
                // La valeur est en dehors de la plage autorisée, vous pouvez afficher un message d'erreur
                ShowMessage(GetTexteLibelle('RULES-MESS_022'));
                // Rétablir la valeur précédente
                NewValue := OldValue;
              end;
          end
        else
          begin
            // La valeur n'est pas un entier valide, vous pouvez afficher un message d'erreur
            ShowMessage(GetTexteLibelle('RULES-MESS_023'));
            // Rétablir la valeur précédente
            NewValue := OldValue;
          end;
        CalculTotalMetierCompetence();
      end;
    end;
  end;

procedure TWinCreations.CalculTotalMetierCompetence();
  Var
    IndTab:   Integer;
  Begin
    TotalMetierCompetence                := 0;
    for IndTab := 1 to TabMetierCompetence.RowCount-1 do
      TotalMetierCompetence            := TotalMetierCompetence + StrToIntDef(TabMetierCompetence.Cells[4, IndTab],0);
    if ValVersion = 'WFRP2' then
      ButtonTotalMetierCompetence.Caption := ''
    else
      ButtonTotalMetierCompetence.Caption := IntToStr(TotalMetierCompetence)+' / 40 Pts';
  end;

procedure TWinCreations.ButtonMetierCompetenceHasardClick(Sender: TObject);
  Var
    Codes:    TStringList;
    IndTab:   Integer;
    NbLignes: Integer;
    Choix:    String;
  Begin
    // 1 - resoudre les lignes encore au choix ("Trade (Any)", "A or B")
    for IndTab := 1 to TabMetierCompetence.RowCount - 1 do
      if TabMetierCompetence.Cells[5, IndTab] = ConstArbreAuChoix then
        begin
          Choix := CompetenceAuHasard(TabMetierCompetence, TabMetierCompetence.Cells[6, IndTab]);
          if Choix <> '' then
            begin
              TabMetierCompetence.Cells[5, IndTab] := '';
              TabMetierCompetence.Cells[1, IndTab] := Choix;
              TabMetierCompetence.Cells[3, IndTab] := ChercheCompetence(Choix).Libelle;
            end;
        end;
    // 2 - repartir les 40 points sur 8 lignes au plus (5 chacune s'il y en a 8 ou plus)
    // (V2 : rien a repartir, les prises sont deja calculees ; l'avance gratuite se tire ici)
    if ValVersion = 'WFRP2' then
      begin
        Codes := AvancesGratuitesPossibles();
        try
          if (AvanceGratuiteCode = '') and (Codes.Count > 0) then
            AvanceGratuiteCode := Codes[Random(Codes.Count)];
          // seconde avance (familier lie) : une autre caracteristique que la premiere
          if (NbAvancesGratuites() >= 2) and (AvanceGratuiteCode2 = '') and (Codes.Count > 1) then
            repeat
              AvanceGratuiteCode2 := Codes[Random(Codes.Count)];
            until AvanceGratuiteCode2 <> AvanceGratuiteCode;
          RemplirGridAvance();
        finally
          Codes.Free;
        end;
        exit;
      end;
    NbLignes := TabMetierCompetence.RowCount - 1;
    if NbLignes > 8 then NbLignes := 8;
    if NbLignes > 0 then
      for IndTab := 1 to TabMetierCompetence.RowCount - 1 do
        if IndTab <= NbLignes then
          TabMetierCompetence.Cells[4, IndTab] := IntToStr(40 div NbLignes + Ord(IndTab <= 40 mod NbLignes))
        else
          TabMetierCompetence.Cells[4, IndTab] := '';
    CalculTotalMetierCompetence
  end;

procedure TWinCreations.ButtonEquipementHasardClick(Sender: TObject);
  var
    Row, I, IndChoix, Quantite: Integer;
    Codes, Quantites:           TStringList;
    Cand:                       array of Integer;
    Res, Code, Lib, Typ:        String;
    PArme:                      StructureArme;
    PArmure:                    StructureArmure;
    PTrapping:                  StructureTrapping;
    Ok:                         Boolean;
  begin
    for Row := 1 to TabMetierEquipement.RowCount - 1 do
      if TabMetierEquipement.Cells[2, Row] = ConstArbreAuChoix then
        begin
          Codes     := TStringList.Create;
          Quantites := TStringList.Create;
          try
            ExtractStrings([','], [], PChar(TabMetierEquipement.Cells[3, Row]), Codes);
            ExtractStrings([','], [], PChar(TabMetierEquipement.Cells[7, Row]), Quantites);
            // candidats : armes et armures limitees aux livres retenus (comme la fenetre de choix)
            Cand := nil;
            for I := 0 to Codes.Count - 1 do
              begin
                DecoupeCodeValeur(Codes[I]);
                Ok := True;
                case Copy(CodeValeur, 1, 5) of
                  EquipementCC, EquipementCT, EquipementMU:
                    Ok := VerifieFiltre(ChercheArme(Codes[I]).Livre, LivresPersonnages);
                  EquipementAR:
                    Ok := VerifieFiltre(ChercheArmure(Codes[I]).Livre, LivresPersonnages);
                end;
                if Ok then
                  begin
                    SetLength(Cand, Length(Cand) + 1);
                    Cand[High(Cand)] := I;
                  end;
              end;
            if Length(Cand) > 0 then
              begin
                IndChoix := Cand[Random(Length(Cand))];
                Res      := Codes[IndChoix];
                DecoupeCodeValeur(Res);
                case Copy(CodeValeur, 1, 5) of
                  EquipementCC, EquipementCT, EquipementMU:
                    begin
                      PArme := ChercheArme(Res);
                      Code  := PArme.CodeArme;
                      Lib   := PArme.Libelle;
                      Typ   := TypeEquipWe;
                    end;
                  EquipementAR:
                    begin
                      PArmure := ChercheArmure(Res);
                      Code    := PArmure.CodeArmure;
                      Lib     := PArmure.Libelle;
                      Typ     := TypeEquipAr;
                    end;
                else
                  begin
                    PTrapping := ChercheTrapping(Res);
                    Code      := Res;
                    if PTrapping.CodeTrapping <> '' then
                      Lib := PTrapping.Libelle
                    else
                      Lib := Res;
                    Typ       := TypeEquipDi;
                  end;
                end;
                // quantite de la branche retenue (meme rang dans la col 7), sinon celle de l'item
                Quantite := StrToIntDef(TabMetierEquipement.Cells[5, Row], 1);
                if IndChoix < Quantites.Count then
                  Quantite := StrToIntDef(Quantites[IndChoix], Quantite);
                TabMetierEquipement.Cells[1, Row] := Code;
                TabMetierEquipement.Cells[2, Row] := Lib + QuantiteSuffixe(Quantite);
                TabMetierEquipement.Cells[4, Row] := '';
                TabMetierEquipement.Cells[5, Row] := IntToStr(Quantite);
                TabMetierEquipement.Cells[6, Row] := Typ;
              end;
          finally
            Codes.Free;
            Quantites.Free;
          end;
        end;
  end;

procedure TWinCreations.ChargerLivre();
  var
    i:             Integer = 0;
    strings:       TStringList;
    Ind:           Integer;
    Ordre:         String;
    Livre:         String;
    PLivre:        StructureLivre;
  begin
    TabLivre.Clear;
    // mise en forme du tableau de création du Livre
    TabLivre.ColCount         := 8;
    TabLivre.RowCount         := 10;
    TabLivre.ColWidths[0]     := 0;
    TabLivre.ColWidths[1]     := 20;
    TabLivre.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabLivre.ColWidths[2]     := 230;
    TabLivre.ColWidths[3]     := 0;
    TabLivre.ColWidths[4]     := 0;
    TabLivre.Cells[5, 0]      := 'R';
    TabLivre.ColWidths[5]     := 0;
    TabLivre.Cells[6, 0]      := 'W';
    TabLivre.ColWidths[6]     := 0;
    TabLivre.Cells[7, 0]      := 'B';
    TabLivre.ColWidths[7]     := 70;

    strings       := TStringList.Create;
    ExtractStrings(['['], [], PChar(LivresCharges), Strings);
    for Ind := 0 to (Strings.count - 1) Do
      begin
        inc(I);
        if TabLivre.RowCount <= I then
          TabLivre.RowCount      := TabLivre.RowCount + 1;
        Livre                    := Strings[ind];
        Livre                    := StringReplace(StringReplace(Livre, '[', '', [rfReplaceAll]), ']', '', [rfReplaceAll]);
        TabLivre.Cells[1, I]     := ConstSelectionne;
        TabLivre.Cells[2, I]     := GetTexteLibelle(Livre,'','',true);
        TabLivre.Cells[3, I]     := Livre;
        PLivre                   := ChercheLivreLibelle(Livre);
        Ordre                    := IntToStr(PLivre.Officiel);
        if Ordre  = '2' then
          TabLivre.Cells[7, I]   := ConstLivreFacultatif
        else
          TabLivre.Cells[7, I]   := ConstLivreOfficiel;
        TabLivre.Cells[4, I]     := Ordre+Livre;
      end;
    Strings.Free;
    // les lignes vides (RowCount de depart = 10) seraient triees EN TETE par SortColRow
    if I >= 1 then
      TabLivre.RowCount := I + 1;
    TabLivre.SortColRow(true,4);
    AdjustGridColumnsWidth(TabLivre, TabSheetLivre.ClientHeight, false, true);
  end;

Procedure TWinCreations.ReconstruitChoixCreation();
  var
    Sauve:      array of StructureChoixCreation;
    Nouvelle:   StructureChoixCreation;
    CodesTalentRace: TStringList;
    CodeTalentRace:  String;
    Ind, Ind2:  Integer;
    Ind3:       Integer;
    ListOpt:    TStringList;
    ListTal:    TStringList;
  begin
    // 1 - sauver l'état courant (choix faits et jets obtenus)
    Sauve := Copy(ListeChoixCreation, 0, Length(ListeChoixCreation));
    ListeChoixCreation := [];

    // 2 - racines : talents de race
    CodesTalentRace := CodesRaceEffectifs('T', RegleEnCours(), RaceEnCours);
    try
    For CodeTalentRace in CodesTalentRace do
        begin
          // Un TRAIT D'ETHNIE se comporte ici comme un choix entre talents : ses
          // options remplacent la liste des talents. Voir CONTEXT.md 2.41. Les deux
          // fonctions ont le meme contrat - liste toujours creee, a liberer par nous.
          if ChercheTrait(CodeTalentRace).CodeTrait <> '' then
            ListOpt := OptionsDuTrait(CodeTalentRace)
          else
            ListOpt := ListeTalent(CodeTalentRace);
          if ListOpt.Count > 1 then
            begin
              Nouvelle.Origine    := ConstOrigineRace;
              Nouvelle.CodeSource := CodeTalentRace;
              Nouvelle.CodeParent := '';
              Nouvelle.CodeChoisi := '';
              Nouvelle.Aleatoire  := False;
              Nouvelle.Jet        := 0;
              Nouvelle.Rang := RangSuivant(Nouvelle.CodeSource, Nouvelle.CodeParent);
              ListeChoixCreation  += [Nouvelle];
            end
          else if CompareRechercheValeur(CodeTalentRace, TalentGenerique) then
            begin
              Nouvelle.Origine    := ConstOrigineRace;
              Nouvelle.CodeSource := CodeTalentRace;
              Nouvelle.CodeParent := '';
              Nouvelle.CodeChoisi := '';
              Nouvelle.Aleatoire  := True;
              Nouvelle.Jet        := 0;
              Nouvelle.Rang := RangSuivant(Nouvelle.CodeSource, Nouvelle.CodeParent);
              ListeChoixCreation  += [Nouvelle];
            end;
          ListOpt.Free;
        end;
    finally
      CodesTalentRace.Free;
    end;

    // 3 - réinjecter les choix et jets mémorisés
    for Ind := 0 to High(ListeChoixCreation) do
      for Ind2 := 0 to High(Sauve) do
        if (Sauve[Ind2].CodeSource = ListeChoixCreation[Ind].CodeSource)
          and (Sauve[Ind2].CodeParent = ListeChoixCreation[Ind].CodeParent)
            and (Sauve[Ind2].Rang = ListeChoixCreation[Ind].Rang) then
              begin
                ListeChoixCreation[Ind].CodeChoisi     := Sauve[Ind2].CodeChoisi;
                ListeChoixCreation[Ind].CodeSpecialise := Sauve[Ind2].CodeSpecialise;
                ListeChoixCreation[Ind].Jet            := Sauve[Ind2].Jet;
                break;
              end;

    // 4 - lignes filles engendrées par les choix retenus
    Ind := 0;
    while Ind <= High(ListeChoixCreation) do
      begin
        // UNE OPTION DE TRAIT ENGENDRE PLUSIEURS LIGNES FILLES, une par talent accordé
        // par la province choisie ("Northern Kislev : Night Vision, One Random Talent").
        // C'est le seul endroit du moteur où une ligne en engendre plus d'une ; le Rang,
        // posé en 2.15 pour le Skink, suffit à les distinguer. CONTEXT.md 2.41.
        // Chaque élément garde les formes connues et se route tout seul : un code concret
        // arrive déjà résolu, un A/B attend un choix, un RULES-T* part au tableau Hasard.
        if (ListeChoixCreation[Ind].CodeChoisi <> '')
          and (ChercheTraitOption(ListeChoixCreation[Ind].CodeChoisi).CodeOption <> '') then
          begin
            ListTal := TStringList.Create;
            ExtractStrings([','], [' '], PChar(ChercheTraitOption(ListeChoixCreation[Ind].CodeChoisi).ListeTalent), ListTal);
            for Ind3 := 0 to ListTal.Count - 1 do
              begin
                Nouvelle.Origine    := ListeChoixCreation[Ind].Origine;
                Nouvelle.CodeSource := ListTal[Ind3];
                Nouvelle.CodeParent := ListeChoixCreation[Ind].CodeSource;
                Nouvelle.Aleatoire  := CompareRechercheValeur(ListTal[Ind3], TalentGenerique);
                // Un talent accordé sec n'est pas un choix : il arrive résolu. Le
                // double-clic est neutralisé pour ces lignes (voir TabCreationChoixDblClick).
                if Nouvelle.Aleatoire or (Pos(SeparateurMulti, ListTal[Ind3]) > 0)
                   or (Pos(ValeurGenerique, ListTal[Ind3]) > 0) then
                  Nouvelle.CodeChoisi := ''
                else
                  Nouvelle.CodeChoisi := ListTal[Ind3];
                Nouvelle.CodeSpecialise := '';
                Nouvelle.Jet        := 0;
                Nouvelle.Rang := RangSuivant(Nouvelle.CodeSource, Nouvelle.CodeParent);
                ListeChoixCreation  += [Nouvelle];
                for Ind2 := 0 to High(Sauve) do
                  if (Sauve[Ind2].CodeSource = Nouvelle.CodeSource)
                     and (Sauve[Ind2].CodeParent = Nouvelle.CodeParent)
                       and (Sauve[Ind2].Rang = Nouvelle.Rang) then
                         begin
                           ListeChoixCreation[High(ListeChoixCreation)].CodeChoisi     := Sauve[Ind2].CodeChoisi;
                           ListeChoixCreation[High(ListeChoixCreation)].CodeSpecialise := Sauve[Ind2].CodeSpecialise;
                           ListeChoixCreation[High(ListeChoixCreation)].Jet            := Sauve[Ind2].Jet;
                           break;
                         end;
              end;
            ListTal.Free;
          end
        else if (ListeChoixCreation[Ind].CodeChoisi <> '')
          and CompareRechercheValeur(ListeChoixCreation[Ind].CodeChoisi, TalentGenerique)
            and (Pos(ValeurGenerique, ListeChoixCreation[Ind].CodeChoisi) = 0) then          begin
            Nouvelle.Origine    := ListeChoixCreation[Ind].Origine;
            Nouvelle.CodeSource := ListeChoixCreation[Ind].CodeChoisi;
            Nouvelle.CodeParent := ListeChoixCreation[Ind].CodeSource;
            Nouvelle.CodeChoisi := '';
            Nouvelle.Aleatoire  := True;
            Nouvelle.Jet        := 0;
            Nouvelle.Rang := RangSuivant(Nouvelle.CodeSource, Nouvelle.CodeParent);
            ListeChoixCreation  += [Nouvelle];
            // réinjecter aussi son jet éventuel
            for Ind2 := 0 to High(Sauve) do
              if (Sauve[Ind2].CodeSource = Nouvelle.CodeSource)
                 and (Sauve[Ind2].CodeParent = Nouvelle.CodeParent)
                   and (Sauve[Ind2].Rang = Nouvelle.Rang) then
                     begin
                       ListeChoixCreation[High(ListeChoixCreation)].CodeChoisi     := Sauve[Ind2].CodeChoisi;
                       ListeChoixCreation[High(ListeChoixCreation)].CodeSpecialise := Sauve[Ind2].CodeSpecialise;
                       ListeChoixCreation[High(ListeChoixCreation)].Jet            := Sauve[Ind2].Jet;
                       break;
                     end;
            end;
        Ind := Ind + 1;
      end;

    AfficheChoixCreation();
  end;

Procedure TWinCreations.AfficheChoixCreation();
  var
    Ind:      Integer;
    LigChoix: Integer = 0;
    LigHasard:Integer = 0;
    PTalent:  StructureTalent;
    Lib:      String;
  begin
    TabCreationChoix.RowCount  := 1;
    TabCreationHasard.RowCount := 1;

    for Ind := 0 to High(ListeChoixCreation) do
      begin
        // libellé du code source
        PTalent := ChercheTalent(ListeChoixCreation[Ind].CodeSource);
        Lib     := PTalent.Libelle;
        // Un trait d'ethnie n'est ni un talent ni un choix A/B : les deux appels
        // ci-dessus rendent une chaine vide, son libelle est dans sa propre table.
        if Lib = '' then
          Lib := ChercheTrait(ListeChoixCreation[Ind].CodeSource).Libelle;
        if Lib = '' then
          Lib := LibelleChoixMultiple(ListeChoixCreation[Ind].CodeSource);

        if ListeChoixCreation[Ind].Aleatoire then
          begin
            LigHasard := LigHasard + 1;
            TabCreationHasard.RowCount := LigHasard + 1;
            TabCreationHasard.Cells[ColHasOrigine, LigHasard] := ListeChoixCreation[Ind].Origine;
            TabCreationHasard.Cells[ColHasLib, LigHasard]     := Lib;
            TabCreationHasard.Cells[ColHasSource, LigHasard]  := ListeChoixCreation[Ind].CodeSource;
            TabCreationHasard.Cells[ColHasSel, LigHasard]     := ListeChoixCreation[Ind].CodeChoisi;
            TabCreationHasard.Cells[ColHasRang, LigHasard]    := IntToStr(ListeChoixCreation[Ind].Rang);
            TabCreationHasard.Cells[ColHasParent, LigHasard]  := ListeChoixCreation[Ind].CodeParent;
            if ListeChoixCreation[Ind].Jet > 0 then
              begin
                TabCreationHasard.Cells[ColHasJet, LigHasard] := IntToStr(ListeChoixCreation[Ind].Jet);
                PTalent := ChercheTalent(ListeChoixCreation[Ind].CodeChoisi);
                TabCreationHasard.Cells[ColHasLibSel, LigHasard] := PTalent.Libelle;
              end
            else
              begin
                TabCreationHasard.Cells[ColHasJet, LigHasard]    := '';
                TabCreationHasard.Cells[ColHasLibSel, LigHasard] := GetTexteLibelle(ConstLabSelSpe);
              end;
            // spécialisation éventuelle
            TabCreationHasard.Cells[ColHasSpe, LigHasard] := ListeChoixCreation[Ind].CodeSpecialise;
            if Pos(ValeurGenerique, ListeChoixCreation[Ind].CodeChoisi) > 0 then
              begin
                if ListeChoixCreation[Ind].CodeSpecialise = '' then
                  TabCreationHasard.Cells[ColHasLibSpe, LigHasard] := GetTexteLibelle(ConstLabSelSpe)
                else
                  begin
                    PTalent := ChercheTalent(ListeChoixCreation[Ind].CodeSpecialise);
                    TabCreationHasard.Cells[ColHasLibSpe, LigHasard] := PTalent.Libelle;
                  end;
              end
            else
              TabCreationHasard.Cells[ColHasLibSpe, LigHasard] := '';
          end
        else
          begin
            LigChoix := LigChoix + 1;
            TabCreationChoix.RowCount := LigChoix + 1;
            TabCreationChoix.Cells[ColChoixOrigine, LigChoix] := ListeChoixCreation[Ind].Origine;
            TabCreationChoix.Cells[ColChoixLib, LigChoix]     := Lib;
            TabCreationChoix.Cells[ColChoixSource, LigChoix]  := ListeChoixCreation[Ind].CodeSource;
            TabCreationChoix.Cells[ColChoixSel, LigChoix]     := ListeChoixCreation[Ind].CodeChoisi;
            TabCreationChoix.Cells[ColChoixParent, LigChoix]  := ListeChoixCreation[Ind].CodeParent;
            // Le rang n'etait PAS ecrit ici (il l'est depuis toujours dans le tableau Hasard,
            // ColHasRang). TabCreationChoixDblClick le relit pour retrouver la bonne entree :
            // sans lui, StrToIntDef('',0) donnait 0 pour toutes les lignes, donc le choix
            // atterrissait toujours sur la premiere. Invisible tant qu'une ethnie n'avait pas
            // deux lignes de meme source - le Skink de Lustria est la premiere. CONTEXT.md 2.15.
            TabCreationChoix.Cells[ColChoixRang, LigChoix]    := IntToStr(ListeChoixCreation[Ind].Rang);
            if ListeChoixCreation[Ind].CodeChoisi = '' then
              TabCreationChoix.Cells[ColChoixLibSel, LigChoix] := GetTexteLibelle(ConstLabSelSpe)
            else
              begin
                PTalent := ChercheTalent(ListeChoixCreation[Ind].CodeChoisi);
                TabCreationChoix.Cells[ColChoixLibSel, LigChoix] := PTalent.Libelle;
              end;
          end;
      end;
    AdjustGridColumnsWidth(TabCreationChoix,  382, False, False, True);
    AdjustGridColumnsWidth(TabCreationHasard, 790, False, False, True);
  end;

Function TWinCreations.ChoixCreationComplet(): Boolean;
  var Ind: Integer;
  begin
    Result := True;
    for Ind := 0 to High(ListeChoixCreation) do
      begin
        if ListeChoixCreation[Ind].CodeChoisi = '' then
          begin
            Result := False;
            Break;
          end;
        if (Pos(ValeurGenerique, ListeChoixCreation[Ind].CodeChoisi) > 0)
           and (ListeChoixCreation[Ind].CodeSpecialise = '') then
          begin
            Result := False;
            Break;
          end;
      end;
  end;

Function TWinCreations.LibelleChoixMultiple(Code: String): String;
  var
    Liste:   TStringList;
    Ind:     Integer;
    PTalent: StructureTalent;
  begin
    Result := '';
    Liste  := ListeTalent(Code);
    for Ind := 0 to Liste.Count - 1 do
      begin
        PTalent := ChercheTalent(Liste[Ind]);
        if Result <> '' then
          Result := Result + ' / ';   // "ou"
        Result := Result + PTalent.Libelle;
      end;
    Liste.Free;
  end;


Function TWinCreations.RangSuivant(Source, ParentLigne: String): Integer;
  var Ind: Integer;
  begin
    Result := 0;
    for Ind := 0 to High(ListeChoixCreation) do
      if (ListeChoixCreation[Ind].CodeSource = Source)
         and (ListeChoixCreation[Ind].CodeParent = ParentLigne) then
        Result := Result + 1;
  end;

Function TWinCreations.ListeTalentsDejaPris(Exclu: String): TStringList;
  var
    Ind: Integer;
  begin
    Result := TStringList.Create;
    for Ind := 1 to TabTalent.RowCount - 1 do
      if (TabTalent.Cells[1, Ind] <> '') and (TabTalent.Cells[1, Ind] <> Exclu) then
        Result.Add(TabTalent.Cells[1, Ind]);
    for Ind := 0 to High(ListeChoixCreation) do
      if (ListeChoixCreation[Ind].CodeChoisi <> '') and (ListeChoixCreation[Ind].CodeChoisi <> Exclu) then
        Result.Add(ListeChoixCreation[Ind].CodeChoisi);
  end;

Procedure TWinCreations.AjouteTalentsResolus();
  var
    Ind:     Integer;
    Lig:     Integer;
    PTalent: StructureTalent;
    CodeFinal: String;
  begin
    // se placer après la dernière ligne remplie
    Lig := 0;
    for Ind := 1 to TabTalent.RowCount - 1 do
      if TabTalent.Cells[1, Ind] <> '' then
        Lig := Ind;

    for Ind := 0 to High(ListeChoixCreation) do
      begin
        CodeFinal := ListeChoixCreation[Ind].CodeSpecialise;
        if CodeFinal = '' then
          CodeFinal := ListeChoixCreation[Ind].CodeChoisi;
        // Une option de trait n'est PAS un talent : elle a engendré ses lignes filles,
        // ce sont elles qui produisent les talents. Sans ce test, la province choisie
        // partait dans la fiche comme un talent au libellé vide. CONTEXT.md 2.41.
        if (CodeFinal <> '') and (not CompareRechercheValeur(CodeFinal, TalentGenerique))
           and (ChercheTraitOption(CodeFinal).CodeOption = '') then
          begin
            PTalent := ChercheTalent(CodeFinal);            Lig     := Lig + 1;
            if Lig >= TabTalent.RowCount then
              TabTalent.RowCount := Lig + 1;
            TabTalent.Cells[1, Lig] := PTalent.CodeTalent;
            TabTalent.Cells[2, Lig] := PTalent.Libelle;
          end;
      end;
  end;

// --creer : meme enchainement que le joueur (boutons Hasard puis Phase suivante), sans fenetre.
// Pas de details physiques ni de mutation de depart (refuse), appartenance laissee vide.
function TWinCreations.CreationAuto(const CodeRace, CodeMetier, Nom: String; Rapport: TStrings; const CodeRegle: String = ''): Boolean;
  var
    Garde: Integer;
    Etape: String;
    IndRegle: Integer;
    Ind: Integer;
    Choix: String;
  begin
    Result       := False;
    RapportAuto  := Rapport;
    MessageRecu  := False;
    NeedUpdate   := False;
    try
      Garde := 0;
      repeat
        Inc(Garde);
        Etape := Format('phase %d', [PhaseEnCours + 1]);
        if SousPhaseClan then
          begin
            Etape := 'clan';
            ButtonClanHasardClick(nil);
            Rapport.Add('Clan : ' + ClanChoisi);
          end
        else if SousPhaseMutation then
          begin
            Rapport.Add('ECHEC : mutation de depart non geree par --creer');
            Exit;
          end
        else if SousPhaseFamilier then
          begin
            Etape := 'forme du familier';
            ButtonFamilierHasardClick(nil);
            Rapport.Add('Familier : ' + FamilierTexte + ' | effets ' + FamilierEffets);
          end
        else if SousPhaseFond then
          begin
            Etape := 'background';
            ButtonFondRegleClick(nil);
            ButtonFondD10Click(nil);
            for Ind := 1 to GridFond.RowCount - 1 do
              if (GridFond.Cells[0, Ind] = 'S') and (Pos(ValeurGenerique, GridFond.Cells[1, Ind]) > 0) then
                begin
                  Choix := CompetenceAuHasard(GridFond, GridFond.Cells[1, Ind]);
                  if Choix <> '' then
                    begin
                      GridFond.Cells[1, Ind] := Choix;
                      GridFond.Cells[2, Ind] := ChercheCompetence(Choix).Libelle;
                    end;
                end;
            Rapport.Add('Background : ' + ComboFond.Text);
          end
        else if SousPhaseSigne then
          begin
            Etape := 'signe astral';
            ButtonSigneClick(nil);
            Rapport.Add('Signe : ' + Personnage.SigneAstral);
          end
        else if SousPhaseMutationChance then
          Etape := 'chance de mutation (passee)'
        else if SousPhaseAppartenance then
          Etape := 'appartenance (laissee vide)'
        else if PhaseEnCours = TabSheetRace.PageIndex then
          begin
            ChoixWinRace := CodeRace;
            TabRaceResultat(0);
            AfficheImageRace();
            UpdateSheetRace(true);
            RemplirGridRace();
            ChoixWinRace := '';
            if RaceEnCours <> CodeRace then
              begin
                Rapport.Add('ECHEC : race introuvable : ' + CodeRace);
                Exit;
              end;
          end
        else if PhaseEnCours = TabSheetMetier.PageIndex then
          begin
            MetierEnCours    := CodeMetier;
            MetierLibEnCours := ChercheMetier(CodeMetier).Libelle;
            if ChercheMetier(CodeMetier).CodeMetier = '' then
              begin
                Rapport.Add('ECHEC : carriere introuvable : ' + CodeMetier);
                Exit;
              end;
            // Regle optionnelle demandee (5e parametre de --creer) : meme geste que le joueur dans le combo
            if CodeRegle <> '' then
              begin
                IndRegle := CodesRegleCombo.IndexOf(CodeRegle);
                if IndRegle < 0 then
                  begin
                    Rapport.Add('ECHEC : regle introuvable pour cette ethnie : ' + CodeRegle);
                    Exit;
                  end;
                ComboBoxRegle.ItemIndex := IndRegle;
                ComboBoxRegleSelect(nil);
                Rapport.Add('Regle : ' + CodeRegle);
              end;
            ChargeImagesNiveau();
            AfficheImageMetier();
            UpdateSheetMetier(true);
          end
        else if PhaseEnCours = TabSheetAttribut.PageIndex then
          ButtonAttributHasardClick(nil)
        else if PhaseEnCours = TabSheetTalent.PageIndex then
          ButtonTalentHasardClick(nil)
        else if PhaseEnCours = TabSheetCompRace.PageIndex then
          ButtonRaceCompetenceHasardClick(nil)
        else if PhaseEnCours = TabSheetCompMetier.PageIndex then
          ButtonMetierCompetenceHasardClick(nil)
        else if PhaseEnCours = TabSheetEquipement.PageIndex then
          ButtonEquipementHasardClick(nil)
        else if PhaseEnCours = TabSheetNom.PageIndex then
          EditNomPersonnag.Text := Nom;
        Rapport.Add('Fin de : ' + Etape);
        ChangementPhase(ConstSuivant);
        if MessageRecu then
          begin
            Rapport.Add('ECHEC : validation refusee a : ' + Etape);
            Exit;
          end;
      until NeedUpdate or (Garde > 40);
      Result := NeedUpdate;
      if not Result then
        Rapport.Add('ECHEC : creation non terminee');
    finally
      RapportAuto := nil;
    end;
  end;

end.

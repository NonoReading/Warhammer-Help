unit WinPersonnage;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}
interface

uses
  PdfUtils,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, ComCtrls, Menus, LCLIntf, Spin, MaskEdit, Math, BGRABitmap, BGRABitmapTypes,
  BCButton, BCLabel, BCLabelContour, PanelReserve, ChargeConstantes, ChargeEspece, ChargeRace, ChargeRaceAttribut,
  UnitCalcul, ChargeMetier, ChargeMetierAttribut, ChargeTalent, ChargeSigneAstral,
  ChargeMetierTalent, ChargeMetierNiveau, ChargeCompetence, ChargeLivre,
  ChargeAttributAugmentation, ChargeAttribut, ChargeCompetenceAugmentation,
  GlobalFonts, ChargeArme, ChargeArmure, ChargeTrapping, ChargeMetierEquipement,
  WinMetier, WinEquipement, WinWeapon, WinArmor, ChargeArmureSimplifie,
  ChargeSort, WinSpell, ChargeTexte, winFabrication, ChargeFabrication,
  WinTalent, WinCompetence, WinSpecialisation, ChargePersonnage,
  ChargeMetierCompetence, PdfPersonnage, Types, WinMutation, ChargeCorruptionTable,
  ChargeRaceMetier, WinChoixCompetenceAppartenance, WinAnimal, WinPhysique,
  ChargeAffliction, ChargeDisease, WinAfflictionCatalogue, WinDiseaseCatalogue,
  WinJetPathologie, WinAmbition, WinGroupe, ChargeGroupe, WinObjetPropre, XmlExportImport;
type

  StructureXpEtat = record
    Total:        Integer;
    Depense:      Integer;
    Restante:     Integer;
    Augmentation: Integer;
  end;

  { TWinPersonnages }

  TWinPersonnages = class(TForm)
    ButtonCorruptionAjoute: TBCButton;
    ButtonCorruptionSupprime: TBCButton;
    ButtonCorruptionMutation: TBCButton;
    ButtonEquipement: TBCButton;
    ButtonTexte: TBCButton;
    ButtonObjet: TBCButton;  // cree dans FormCreate (copie de ButtonTexte) : +Objet propre au personnage
    ButtonSpecCompetence: TBCButton;  // +Specialisation propre, page Competence (visible sur une ligne a choisir)
    ButtonSpecTalent: TBCButton;      // idem, page Talent
    ButtonPhysique: TBCButton;
    CheckBoxSansAsterisque: TCheckBox;   // onglet PDF : cree dans FormCreate
    CheckBoxSansMontant:    TCheckBox;
    CheckBoxStylePdf:       TCheckBox;   // onglet PDF : habillage Warhammer du PDF Feldo
    CheckBoxCouleurPdf:     TCheckBox;   // idem : en couleurs (decoche = niveaux de gris)
    CheckBoxEconomiePdf:    TCheckBox;   // idem : economie d'encre (sans fonds pleins)
    LabEconomiePdf:         TLabelContour;
    LabCouleurPdf:          TLabelContour;
    LabSansAsterisque:      TLabelContour;
    LabSansMontant:         TLabelContour;
    LabStylePdf:            TLabelContour;
    PageMonnaie: TPage;  // creee dans FormCreate : monnaie du personnage (CO/PA/SB)
    PagePdf: TPage;      // creee dans FormCreate : options propres au PDF (PDF Feldo 2p...)
    PageReserve: TPage;  // creee dans FormCreate : registres de Destin, de Resilience et de Resolution
    PanelDestin, PanelResilience, PanelResolve: TPanelReserve;
    ComboBoxNvMetier: TComboBox;
    EditHairColors: TEdit;
    EditEyeColors: TEdit;
    EditSigne: TEdit;
    EditHeight: TEdit;
    ButtonArme: TBCButton;
    ButtonArmure: TBCButton;
    ButtonAugmentation: TBCButton;
    ButtonDelete: TBCButton;
    ButtonFabrication: TBCButton;
    LabPorteAide: TLabelContour;
    ButtonHistorique: TBCButton;
    ButtonPdf: TBCButton;
    ButtonRaceSelectionner: TBCButton;
    ButtonSauvegarde: TBCButton;
    ButtonLigneGauche: TButton;
    ButtonSort: TBCButton;
    CheckBoxCalcul: TCheckBox;
    CheckBoxQuickArmor: TCheckBox;
    CheckBoxMunition: TCheckBox;
    CheckBoxXp: TCheckBox;
    CheckBoxPdfFeldo2p: TCheckBox;
    CheckBoxXpDiv25: TCheckBox;
    EditAge: TEdit;
    EditNeedTheoXp: TSpinEdit;
    EditNeedRealXp: TSpinEdit;
    EditTotalXp: TEdit;
    LabelCorruptionLeft: TEdit;
    EditTotalXp25: TEdit;
    ImageBackMetier: TImage;
    ImageMetier: TImage;
    ImageRace1: TImage;
    ImageRace2: TImage;
    ImageBackRace: TImage;
    ImageSheetPage: TImage;
    ImageSheetXp: TImage;
    ImageWar: TImage;
    ImageSheetTitle: TImage;
    LabAugmentation: TBCLabelContour;
    LabelPdfFeldo2p: TLabelContour;
    LabQuickArmor: TLabelContour;
    LabMunition: TLabelContour;
    LabEquipement: TBCLabelContour;
    LabelMetier: TBCLabelContour;
    LabelNeedRealXp: TEdit;
    LabelNeedTheoXp: TEdit;
    LabelRace: TBCLabelContour;
    LabelXp: TLabelContour;
    LabelXpDiv25: TEdit;
    LabEyeColors: TBCLabelContour;
    LabHeight: TBCLabelContour;
    LabTabAttribut: TBCLabelContour;
    LabTabAvancement: TBCLabelContour;
    LabTabCarriere: TBCLabelContour;
    LabAge: TBCLabelContour;
    LabTabCompetence: TBCLabelContour;
    LabTabExperience: TBCLabelContour;
    LabelCalcul: TLabelContour;
    LabHairColors: TBCLabelContour;
    LabTabNiveau: TBCLabelContour;
    LabTabTalent: TBCLabelContour;
    MemoMutationEffet: TMemo;
    TabPathologie: TStringGrid;
    MemoPathologieEffet: TMemo;
    ButtonPathologieAjouteAffliction: TBCButton;
    ButtonPathologieAjouteDisease: TBCButton;
    TabSheetPathologie: TPage;
    TabSheetAmbition: TPage;
    TabAmbition: TStringGrid;
    TabSheetGroupe: TPage;
    TabGroupe: TStringGrid;
    PageExperience: TNotebook;
    ListBoxExperience: TListBox;
    LabelAppartenance: TBCLabelContour;
    LibAppartenance: TEdit;
    LibMetier: TEdit;
    LibRace: TEdit;
    PersonnageNom: TBCLabelContour;
    RadioButtonChanger: TRadioButton;
    RadioButtonRAS: TRadioButton;
    RadioButtonSuivant: TRadioButton;
    RadioGroupEvolution: TRadioGroup;
    StaticTextPersonnage: TStaticText;
    TabMutation: TStringGrid;
    StringGridCorruption: TStringGrid;
    TabAugmentationMjXp: TStringGrid;
    TabLivre: TStringGrid;
    TabMJXp: TStringGrid;
    TabSheetMutation: TPage;
    TabSheetCorruption: TPage;
    TabSheetMjCost: TPage;
    TabSheetLivre: TPage;
    TabSort: TStringGrid;
    TabEquipement: TStringGrid;
    ListBoxEquipementCategorie: TListBox;
    TabEquipementAffichage: TStringGrid;
    TabHistorique: TStringGrid;
    TabAugmentationTalent: TStringGrid;
    TabAugmentationCompetence: TStringGrid;
    TabAugmentationAttribut: TStringGrid;
    TabExperience: TStringGrid;
    TabAvancement: TStringGrid;
    TabCarriere: TStringGrid;
    TabCompetence: TStringGrid;
    TabMetierEquipement: TStringGrid;
    TabNiveau: TStringGrid;
    TabSheetAttribut: TPage;
    TabSheetCompetence: TPage;
    TabSheetTalent: TPage;
    TabSheetXP: TPage;
    TabSheetEvolution: TPage;
    TabSheetHistorique: TPage;
    TabTalent: TStringGrid;
    TabAttribut: TStringGrid;
    ToggleBoxGauche: TToggleBox;
    ToggleBoxDroite: TToggleBox;

  // Générales
  procedure ButtonCorruptionMutationClick(Sender: TObject);
  procedure EditAgeKeyPress(Sender: TObject; var Key: char);
  procedure ButtonArmureClick({%H-}Sender: TObject);
  procedure ButtonArmeClick({%H-}Sender: TObject);
  procedure ButtonEquipementClick({%H-}Sender: TObject);
  procedure ButtonTexteClick({%H-}Sender: TObject);
  procedure ButtonObjetClick({%H-}Sender: TObject);
  procedure ButtonSpecialisationClick(Sender: TObject);
  procedure MajBoutonsSpecialisation(LigneComp, LigneTal: Integer);
  procedure MajBoutonsSpecialisationDiffere({%H-}Data: PtrInt);
  procedure ModifierObjetPropre(Ligne: Integer);
  function LibelleObjetPropre(const Balise, Code: String): String;
  function SaisieTexteLibre(var Nom: String; var Enc: Integer): Boolean;
  procedure ButtonFabricationClick({%H-}Sender: TObject);
  procedure ButtonDeleteClick({%H-}Sender: TObject);
  procedure ButtonCorruptionAjouteClick({%H-}Sender: TObject);
  procedure ButtonCorruptionSupprimeClick({%H-}Sender: TObject);
  procedure ButtonHistoriqueClick({%H-}Sender: TObject);
  procedure ButtonPhysiqueClick({%H-}Sender: TObject);
  procedure ButtonQuitterClick({%H-}Sender: TObject);
  procedure ButtonRaceSelectionnerClick({%H-}Sender: TObject);
  procedure ButtonSortClick({%H-}Sender: TObject);
  procedure CheckBoxXpDiv25Change(Sender: TObject);
  procedure CheckBoxXpDiv25Click(Sender: TObject);
  procedure CheckBoxSansAsterisqueClick(Sender: TObject);
  procedure CheckBoxStylePdfClick(Sender: TObject);
  procedure ComboBoxNvMetierChange({%H-}Sender: TObject);
  procedure EditTotalXp25KeyPress(Sender: TObject; var Key: char);
  procedure EditTotalXp25KeyUp(Sender: TObject; var Key: Word;
    Shift: TShiftState);
  procedure EditTotalXpKeyPress(Sender: TObject; var Key: char);
  procedure EditTotalXpKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
    );
  procedure FormClose({%H-}Sender: TObject; var {%H-}CloseAction: TCloseAction);
  procedure FormCreate({%H-}Sender: TObject);
  procedure FormResize({%H-}Sender: TObject);
  procedure AjustePositionTables();
  procedure EditHeightKeyPress(Sender: TObject; var Key: char);
  procedure Label1Click(Sender: TObject);
  procedure PageExperienceChange({%H-}Sender: TObject);
  procedure ListBoxExperienceClick({%H-}Sender: TObject);
  procedure RadioButtonRASChange({%H-}Sender: TObject);
  procedure RadioButtonSuivantChange({%H-}Sender: TObject);
  procedure StaticTextPersonnageClick(Sender: TObject);
  procedure StringGrid1Click(Sender: TObject);
  procedure TabAttributDrawCell({%H-}Sender: TObject; aCol, aRow: Integer;
    aRect: TRect; aState: TGridDrawState);
  procedure TabAttributSelectEditor({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
    var Editor: TWinControl);
  procedure TabAugmentationAttributEditingDone({%H-}Sender: TObject);
  procedure TabAugmentationAttributKeyUp({%H-}Sender: TObject; var Key: Word;
    {%H-}Shift: TShiftState);
  procedure TabAugmentationAttributMouseDown(Sender: TObject;
    Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure TabAugmentationCompetenceEditingDone({%H-}Sender: TObject);
  procedure TabAugmentationCompetenceKeyUp({%H-}Sender: TObject; var {%H-}Key: Word;
    {%H-}Shift: TShiftState);
  procedure TabAugmentationCompetenceMouseDown(Sender: TObject;
    Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure TabAugmentationTalentDblClick({%H-}Sender: TObject);
  procedure TabAugmentationTalentEditingDone({%H-}Sender: TObject);
  procedure TabAugmentationTalentKeyDown({%H-}Sender: TObject; var Key: Word;
    {%H-}Shift: TShiftState);
  procedure TabCarriereDblClick({%H-}Sender: TObject);
  procedure TabDrawCell(Sender: TObject; aCol, aRow: Integer;
    aRect: TRect; aState: TGridDrawState);
  Procedure ChargeImageNiveau(Niveau: Integer);
  Procedure ChargeImagesNiveau();
  function ChercherValeurParCode(const Chaine: string; const CodeRecherche: string): string;
  Procedure Initialisation();
  procedure InitialisationImages();
  procedure InitialisationTablesPersonnage();
  procedure InitialisationTablesSuivi();
  procedure InitialisationTablesEquipement();
  procedure InitialisationTablesDivers();
  Procedure AugmentationAjouteXpMj(TypeDonnee: String);
  procedure CalculXpGlobal(Mode25: boolean);

  // Attribut
  procedure TabAugmentationAttributGetEditText({%H-}Sender: TObject; ACol,
    ARow: Integer; var Value: string);
  procedure TabAugmentationAttributSelectCell({%H-}Sender: TObject; {%H-}aCol,
    aRow: Integer; var {%H-}CanSelect: Boolean);
  procedure TabAugmentationAttributSelectEditor({%H-}Sender: TObject; aCol,
    aRow: Integer; var Editor: TWinControl);
  Procedure AttributInit();
  Procedure TabAugmentationAttributCalcul(ARow: Integer; var Value: string);

  // Compétences
  procedure TabAugmentationCompetenceGetEditText({%H-}Sender: TObject; ACol,
    ARow: Integer; var Value: string);
  procedure TabAugmentationCompetenceSelectCell({%H-}Sender: TObject; {%H-}aCol,
    aRow: Integer; var {%H-}CanSelect: Boolean);
  procedure TabAugmentationCompetenceSelectEditor({%H-}Sender: TObject; aCol,
    aRow: Integer; var Editor: TWinControl);
  procedure TabLivreDblClick({%H-}Sender: TObject);
  procedure TabMetierEquipementDblClick({%H-}Sender: TObject);
  procedure TabMetierEquipementClick({%H-}Sender: TObject);
  procedure TabMetierEquipementSelectEditor({%H-}Sender: TObject; {%H-}aCol,
    {%H-}aRow: Integer; var Editor: TWinControl);
  procedure TabMutationClick(Sender: TObject);
  procedure TabMutationDblClick({%H-}Sender: TObject);
  procedure TabPathologieClick(Sender: TObject);
  procedure TabPathologieDblClick({%H-}Sender: TObject);
  procedure ButtonPathologieAjouteAfflictionClick({%H-}Sender: TObject);
  procedure ButtonPathologieAjouteDiseaseClick({%H-}Sender: TObject);
  procedure TabAmbitionDblClick({%H-}Sender: TObject);
  procedure AfficheAmbition();
  procedure TabGroupeDblClick({%H-}Sender: TObject);
  procedure AfficheGroupe();
  procedure TabSheetMjCostContextPopup(Sender: TObject; MousePos: TPoint;
    var Handled: Boolean);
  procedure TabSortDblClick({%H-}Sender: TObject);
  procedure TabTalentDblClick({%H-}Sender: TObject);
  procedure TabAugmentationCompetenceCalcul(ARow: Integer; var Value: string);
  procedure TabAugmentationCompetenceDblClick({%H-}Sender: TObject);
  procedure TabCompetenceDblClick({%H-}Sender: TObject);

  // Talents
  procedure TabAugmentationTalentSelectEditor({%H-}Sender: TObject; aCol,
    aRow: Integer; var Editor: TWinControl);
  procedure TabAugmentationTalentGetEditText({%H-}Sender: TObject; ACol,
    ARow: Integer; var Value: string);
  procedure TabAugmentationTalentSelectCell({%H-}Sender: TObject; {%H-}aCol,
    aRow: Integer; var {%H-}CanSelect: Boolean);
  procedure TabAugmentationTalentCalcul(ARow: Integer; var Value: string);
  procedure TalentAsterisc();
  Procedure SortAffiche();

  // Expérience
  procedure CalculAvancement();
  function  CalculExperience(TypeXp: String; Gratuit: Integer; Total: Integer; Code:String): Integer;
  function  CalculXpEtat(): StructureXpEtat;
  procedure CalculTableExperience();
  procedure CalculTotaux();
  function AjusteDetailsCalcul(): Boolean;
  procedure CalculXpNecessaire(ChangementClasse: Boolean);
  Function CalculXpMj(TypeDonnee: String; CodeDonnee:String): Integer;
  Function CalculOptionXpDiv25(Xp: Integer): Integer;
  Function CalculOptionXpDiv25Inverse(Xp: Integer): Integer;

  // Xml
  Function XmlDebut(TypeDonnee: string): String;
  Function XmlFin(TypeDonnee: string): String;
  Function XmlLigne(TypeDonnee: string; Valeur: String): String;
  Function XmlLigneDonnee(TypeDonnee: string; Valeur: String; Donnee: String): String;

  // Chargement
  function XmlPersonnageFichierActuel(const Directory: string): string;
  procedure XmlChargePersonnage(const FileName: string);
  procedure XmlChargePersonnageGeneral(const FileName: string);
  procedure XmlChargePersonnageRaceMetier();
  procedure XmlChargePersonnageCompetencesTalentsAugmentations();
  procedure XmlChargePersonnageEquipementSorts();
  procedure XmlChargePersonnageSuivi(const FileName: string);
  procedure AfficheImageRace();
  procedure AfficheImageMetier();
  procedure NiveauMetierTalentMax();
  procedure ChargeAugmentation();
  procedure EffaceDonnee(Tableau: TStringGrid; NbLig: Integer);

  // Sauvegarde
  procedure ButtonSauvegardeClick({%H-}Sender: TObject);
  procedure MajTables();
  procedure MajTablesAugmentations();
  procedure MajTablesEvolutionCarriere();
  procedure MajTablesPersonnage();
  Function XmlSauvegarde(): Boolean;
  procedure ButtonAugmentationClick({%H-}Sender: TObject);
  procedure RadioButtonChangerChange({%H-}Sender: TObject);
  Function CarriereDeSuite(): String;
  Procedure MarqueNiveauEnCours();
  Procedure ListeNvMetier(Codes: TStringList);
  Procedure ChargeComboNvMetier();
  procedure CheckBoxCalculChange({%H-}Sender: TObject);
  procedure CheckBoxXpChange({%H-}Sender: TObject);
  Function VerifieLivre(ListeLivre: String; Livre: String): String;

  // PDF
  procedure ButtonPdfClick({%H-}Sender: TObject);

  //Equipement
  Procedure ChargerMetierEquipement(CodeMetier: String; NiveauMetier: Integer);
  Procedure TabEquipementAffiche();
  procedure TabEquipementSelectEditor({%H-}Sender: TObject; aCol, aRow: Integer;
    var Editor: TWinControl);
  procedure TabEquipementSelectCell({%H-}Sender: TObject; {%H-}aCol, aRow: Integer;
    var {%H-}CanSelect: Boolean);
  procedure TabEquipementDblClick({%H-}Sender: TObject);
  // Rattachement d'un objet a un animal (CONTEXT.md 2.84, etape 3) : colonnes cachees 10 (id de
  // l'animal) et 11 (animal porteur), colonne 12 = nom du porteur.
  procedure TabEquipementMouseMove({%H-}Sender: TObject; {%H-}Shift: TShiftState; X, Y: Integer);
  procedure TabEquipementMouseDown({%H-}Sender: TObject; Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: Integer);
  procedure TabEquipementPopup({%H-}Sender: TObject);
  // Scission de l'affichage par categorie (CONTEXT.md, etape 2) : TabEquipement reste la grille
  // complete de sauvegarde (masquee), TabEquipementAffichage montre seulement la categorie
  // choisie dans ListBoxEquipementCategorie.
  procedure ListBoxEquipementCategorieClick({%H-}Sender: TObject);
  procedure RafraichitTabEquipementAffichage();
  function CategorieEquipementLigne(Ligne: Integer): Integer;
  function LigneEquipementReelle(Ligne: Integer): Integer;
  procedure TabEquipementAffichageSetEditText({%H-}Sender: TObject; ACol, ARow: Integer; const Value: string);
  procedure MenuConfierClick(Sender: TObject);
  function MainsLibresPourArme(Ligne: Integer): Boolean;
  procedure MenuPorteClick({%H-}Sender: TObject);
  procedure MenuReprendreClick({%H-}Sender: TObject);
  // Partage d'un animal/vehicule/bateau avec le groupe (CONTEXT.md 2.100, etape 4).
  procedure MenuPartageGroupeClick({%H-}Sender: TObject);
  procedure MenuDonnerClick({%H-}Sender: TObject);
  procedure AttribueIdAnimaux;
  procedure RafraichitPorteurs;
  function LigneEstAnimal(Ligne: Integer): Boolean;
  procedure CodesObjetsPropresUtilises(Codes: TStrings);
  function EquipementDeLigne(Ligne: Integer): StructurePersonnageEquipement;
  function ChargeAnimalGrille(IdAnimal: String): Integer;
  function CodesFittingGrille(IdAnimal: String): String;
  function CapaciteAnimalGrille(IdAnimal: String): Integer;
  function LibelleAnimalOuGroupe(IdAnimal: String): String;
  procedure AvertitSurcharge(IdAnimal: String);
  function XpSortCout(CodeSort: String): String;
  function ValeurTarifSort(Expression: String; Defaut: Integer): Integer;
  function TalentSort(CodeSort: String): StructureTalent;
  function PoolTalent(PTalent: StructureTalent): String;
  Procedure AfficheFabrication();
  Function ChoixNonFait(): Boolean;
  procedure AjouteEquipementNiveau();

  // Corruption
  Function  CalculCorruptionLost(): Integer;
  procedure CalculCorruptionLeft();
  procedure StringGridCorruptionEditingDone({%H-}Sender: TObject);
  // Destin, Resilience et Resolution : totaux lus sur le tableau des attributs
  procedure MajReserves();
  procedure RegistreDestinChange({%H-}Sender: TObject);
  procedure RegistreResilienceChange({%H-}Sender: TObject);
  procedure AppliqueRegistre(Panel: TPanelReserve; const CodeAttribut: String; ColAtt: Integer; var Applique: Integer);
  procedure AfficheMutations();
  procedure AfficheDiseasesAfflictions();

  private
    FCurrentTabSheet: TPage;
    FVerrouPerso: PtrUInt;  // mutex du personnage ouvert dans cette fenetre (0 = aucun)
    ReservesChargement: Boolean;  // vrai pendant le remplissage des registres : pas d'effet sur les attributs
    DestinApplique, ResilienceApplique: Integer;  // somme des lignes deja repercutee sur CreationAttribut
    // Monnaie du personnage (CO/PA/SB), creee par code dans AjustePositionTables.
    EditMonnaie: array[0..2] of TEdit;
    LabMonnaie:  array[0..2] of TLabel;
    procedure PlaceChampsMonnaie();
    procedure PersonnageVoisinClick(Sender: TObject);

  public

  end;

var
  WinPersonnages: TWinPersonnages;
  // données générales en cours
  RaceEnCours:    String = '';
  RaceBlessure:   String = '';
  MetierEnCours:  String = '';
  MetierNvEnCours:String = '';
  MetierComplet:  String = '';
  WorkEnCours:    String = '';
  // gestion des images et couleurs
  picture:        TPicture;
  ListImage:      TImageList;
  Bitmap:         TBitmap;
  Path:           String;
  ColorLoc:       TColor;
  ColorList:      array of TColor;
  // attributs
  LigAttRace:     Integer = 1;
  LigAttLance:    Integer = 2;
  LigAttTalent:   Integer = 3;
  LigAttMutation: Integer = 4;
  // Afflictions/Maladies (Unofficial Grimoire/Litany of Pestilence) : ligne de detail propre,
  // separee de Mutation a la demande de Nono le 27/09/2026 - ce n'est pas une Mutation.
  LigAttPathologie: Integer = 5;
  LigAttCareer:   Integer = 6;
  LigAttObjet:    Integer = 7;
  // Signe astral (Archives of the Empire II) : ligne de detail propre, comme Career et Objet
  LigAttSigne:    Integer = 8;
  LigAttBase:     Integer = 9;
  LigAttImage:    Integer =10;
  LigAttBonus:    Integer =11;
  LigAttTotal:    Integer =12;
  LigAttXp:       Integer =13;
  LigAttActuel:   Integer =14;
  LigAttCode:     Integer =15;
  LigAttAsterisc: Integer =16;
  ColAttLib:      Integer = 1;
  ColAttCC:       Integer = 2;
  ColAttCT:       Integer = 3;
  ColAttF:        Integer = 4;
  ColAttE:        Integer = 5;
  ColAttI:        Integer = 6;
  ColAttAgi:      Integer = 7;
  ColAttDex:      Integer = 8;
  ColAttInt:      Integer = 9;
  ColAttFM:       Integer =10;
  ColAttSoc:      Integer =11;
  ColAttDestin:   Integer =12;
  ColAttResil:    Integer =13;
  ColAttBlessure: Integer =14;
  // compétences
  ColCompCode:    Integer = 1;
  ColCompImage:   Integer = 2;
  ColCompLib:     Integer = 3;
  ColCompCarac:   Integer = 4;
  ColCompAtt:     Integer = 5;
  ColComp35:      Integer = 6;
  ColComp40:      Integer = 7;
  ColCompWork:    Integer = 8;
  ColCompMutation:Integer = 9;
  // Avancees gratuites accordees par un <SkillChoice> d'appartenance (ex. Reiksguard
  // palier 4) - Personnage.CompetenceAppartenance, ChargeConstantes. Meme role que
  // ColComp35/ColComp40 (colonne cachee qui alimente ColCompBonus et le calcul du Xp
  // "gratuit"), champ dedie plutot que reutiliser ColComp35 - CONTEXT.md. Placee juste
  // avant ColCompBonus (comme ColComp35/40/Work/Mutation) - demande de Nono.
  ColCompAppartenance: Integer =10;
  // Bonus de Carriere (<ModifyCarac>/<ModifySkill> de palier, PersonnageCareerBonusCompetenceModif)
  // sur une Competence, ex. Reiksguard "+10 CC avec les lances" - pendant Competence de
  // LigAttCareer sur TabAttribut (winpersonnage.pas §2.61), meme raison : deja compte dans
  // ColCompTotal via PdfPersonnageCompetence mais jusqu'ici invisible a l'ecran, rendant le
  // total Attribut+Bonus incomprehensible. Colonne cachee, jamais dans ColCompBonus (meme
  // traitement que ColCompMutation : un bonus de Carriere n'est pas un avancement achete).
  ColCompCareer: Integer =11;
  ColCompBonus:   Integer =12;
  ColCompTotal:   Integer =13;
  ColCompStat:    Integer =14;
  ColCompXp:      Integer =15;
  ColCompActuel:  Integer =16;
  ColCompTravail: Integer =17;
  ColCompAsterisc:Integer =18;
  // talent
  ColTalCode:     Integer = 1;
  ColTalLib:      Integer = 3;
  ColTalNb:       Integer = 4;
  ColTalMax:      Integer = 5;
  ColTalXp:       Integer = 6;
  ColTalAsterisk: Integer = 8;
  ColTalNbCrea:   Integer = 9;
  ColTalNbAugm:   Integer =10;

  // expérience
  LigXpTotal:     Integer = 1;
  LigXpDepense:   Integer = 2;
  LigXpRestant:   Integer = 3;
  LigXpCout:      Integer = 4;
  ColXpLib:       Integer = 1;
  ColXpDonnee:    Integer = 3;
  // augmentation attribut
  ColAugmAttCode:    Integer = 3;
  ColAugmAttActuel:  Integer = 4;
  ColAugmAttMoins5:  Integer = 5;
  ColAugmAttNouveau: Integer = 6;
  ColAugmAttPlus5:   Integer = 7;
  ColAugmAttCout:    Integer = 8;
  ColAugmAttReel:    Integer = 9;
  // augmentation compétence
  ColAugmCompCode:   Integer = 1;
  ColAugmCompLib:    Integer = 3;
  ColAugmCompActuel: Integer = 4;
  ColAugmCompMoins5: Integer = 5;
  ColAugmCompNouveau:Integer = 6;
  ColAugmCompPlus5:  Integer = 7;
  ColAugmCompCout:   Integer = 8;
  ColAugmCompSpe:    Integer = 9;
  ColAugmCompSpeSel: Integer =10;
  ColAugmCompWork:   Integer =11;
  ColAugmCompReel:   Integer =12;
  ColAugmCompTri:    Integer =13;
  // Position gardee d'un personnage a l'autre (fleches < >, PersonnageVoisinClick) : page de
  // PageExperience et categorie d'equipement. -1 = rien a restaurer (premiere ouverture).
  PageVoisinSauvee:      Integer = -1;
  CategorieVoisinSauvee: Integer = -1;
  // augmentation talent
  ColAugmTalCode:   Integer = 1;
  ColAugmTalLib:    Integer = 3;
  ColAugmTalActuel: Integer = 4;
  ColAugmTalNouveau:Integer = 5;
  ColAugmTalCout:   Integer = 6;
  ColAugmTalSpe:    Integer = 7;
  ColAugmTalSpeSel: Integer = 8;
  ColAugmTalWork:   Integer = 9;
  ColAugmTalSort:   Integer =10;
  ColAugmTalReel:   Integer =11;
  ColAugmTalSortSel:Integer =12;
  // augmentation spéciales
  ColAugmMjXpType:  integer = 1;
  ColAugmMjXpCode:  integer = 2;
  ColAugmMjXpDebut: integer = 3;
  ColAugmMjXpFin:   integer = 4;
  ColAugmMjXpCout:  integer = 5;
  ColAugmMjXpReel:  integer = 6;
  ColAugmMjXpNew:   integer = 7;


  // Augmentation
  PreviousRowIndexA:    Integer = 0;
  PreviousRowIndexC:    Integer = 0;
  PreviousRowIndexT:    Integer = 0;
  // Li
  ListeSavAtt:    String = '';
  ListeSavComp:   String = '';
  ListeSavTal:    String = '';

  NvMetier:       String = '';
  NvNiveau:       String = '';
  NvMetierChoisi: String = '';

  FenMetier:          TWinMetiers;
  FenArme:            TWinWeapons;
  FenEquipement:      TWinEquipements;
  FenArmure:          TWinArmors;
  FenSort:            TWinSpells;
  FenFabrication:     TWinFabrications;
  FenTalent:          TWintTalent;
  FenCompetence:      TWinCompetence;
  FenSpecialisation:  TWinSpecialisations;
  FenChoixCompetenceAppartenance: TWinChoixCompetenceAppartenance;

  NbEquipement: Integer;

  FabAjoute:    Boolean = false;

  // Fiche affichee = version courante du personnage (true) ou un instantane de l'historique,
  // en lecture seule (false, TabHistorique.Cells[0,1] <> ConstSelectionne). Lu par
  // RafraichitTabEquipementAffichage pour ne pas reafficher les boutons d'ajout/action sur un
  // instantane, en plus du filtre par categorie (25/09/2026).
  EquipementModifiable: Boolean = true;

  Personnage:                 StructurePersonnage;
  PersonnageMetier:           StructurePersonnageMetier;
  PersonnageAttribut:         StructurePersonnageAttribut;
  PersonnageCompetence:       StructurePersonnageCompetence;
  PersonnageTalent:           StructurePersonnageTalent;
  PersonnageEquipement:       StructurePersonnageEquipement;
  PersonnageXpAttribut:       StructurePersonnageXpAttribut;
  PersonnageXpCompetence:     StructurePersonnageXpCompetence;
  PersonnageXpTalent:         StructurePersonnageXpTalent;

  // verrue
  PremierAjustage:            integer = 3;

implementation

{$R *.lfm}

function CreateMutexW(Attr: Pointer; Initial: LongBool; Nom: PWideChar): PtrUInt; stdcall; external 'kernel32.dll' name 'CreateMutexW';
function CloseHandle(Poignee: PtrUInt): LongBool; stdcall; external 'kernel32.dll' name 'CloseHandle';
function ErreurSysteme(): LongWord; stdcall; external 'kernel32.dll' name 'GetLastError';

// Un personnage ouvert tient un mutex nomme d'apres son dossier (libere par Windows a la fin
// du processus, meme apres un plantage). Poignee = 0 si le mutex est impossible a creer.
// DejaExistant = vrai quand une autre fenetre (ou un autre WarhammerHelp) tient deja ce personnage.
function MutexPersonnage(const Dossier: String; out DejaExistant: Boolean): PtrUInt;
  const
    ERREUR_DEJA_EXISTANT = 183;
  begin
    Result       := CreateMutexW(nil, True, PWideChar(UnicodeString('Local\WarhammerHelp_Perso_' + UpperCase(Dossier))));
    DejaExistant := (Result <> 0) and (ErreurSysteme() = ERREUR_DEJA_EXISTANT);
  end;


Function TWinPersonnages.XmlDebut(TypeDonnee: string): String;
  begin
    Result := '<'+TypeDonnee+'>';
  end;

Function TWinPersonnages.XmlFin(TypeDonnee: string): String;
  begin
    Result := '</'+TypeDonnee+'>';
  end;

Function TWinPersonnages.XmlLigne(TypeDonnee: string; Valeur: String): String;
  begin
    Result := XmlDebut(TypeDonnee) + '"' + Valeur + '"' + XmlFin(TypeDonnee);
  end;

function TWinPersonnages.XmlLigneDonnee(TypeDonnee: string; Valeur: String; Donnee: String): String;
  begin
    Result := XmlDebut(TypeDonnee+' name="'+Valeur+'"') + '"' + Donnee + '"' + XmlFin(TypeDonnee);
  end;

function TWinPersonnages.XmlPersonnageFichierActuel(const Directory: string): string;
var
  SearchRec:       TSearchRec;
  HighestFileName: string;
  NbFichier:       Integer = 0;
  OrdreTri:        Integer = 9999;
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

          // ajout de l'historique
          NbFichier := NbFichier + 1;
          if NbFichier >= TabHistorique.RowCount then
            TabHistorique.RowCount := TabHistorique.RowCount + 1;
          TabHistorique.cells[1,NbFichier] := SearchRec.Name;
          TabHistorique.cells[2,NbFichier] := Directory + PathDelim + SearchRec.Name;
          TabHistorique.cells[3,NbFichier] := IntToStr(OrdreTri - NbFichier);
        end;
      end;
      TabHistorique.SortColRow(true, 3);
    until FindNext(SearchRec) <> 0;
  end;

  if HighestFileName <> '' then
    Result := IncludeTrailingPathDelimiter(Directory) + HighestFileName
  else
    Result := '';
end;

procedure TWinPersonnages.ButtonAugmentationClick(Sender: TObject);
Var
  XpDispo:          Integer;
  CarriereComplete: Boolean;
  MaxNiveau:        Integer;
begin
  // calculs XP disponible et état carrière
  XpDispo          := (StrToIntDef(extractnumbers(tabExperience.Cells[ColXpDonnee,LigXpRestant]),0) - StrToIntDef(extractnumbers(tabExperience.Cells[ColXpDonnee,LigXpCout]),0));
  CarriereComplete := ((TabAvancement.Cells[2,1] = CouleurOk) and (TabAvancement.Cells[2,2] = CouleurOk) and (TabAvancement.Cells[2,3] = CouleurOk));
  // calcul Xp, Métier, Nv en changement de carrière
  if radiobuttonsuivant.Checked and CarriereComplete then
    begin
      // Combo visible = ce niveau ouvre sur plusieurs carrieres, c'est elle qui designe
      // laquelle. Combo cachee = aucune bifurcation, on continue dans la carriere en cours,
      // exactement comme avant.
      if ComboBoxNvMetier.Visible and (NvMetierChoisi <> '') then
        NvMetier := NvMetierChoisi
      else
        NvMetier := CarriereDeSuite();
      NvNiveau := IntToStr(StrToInt(MetierNvEnCours)+1);
    end
  else if radiobuttonChanger.Checked and CarriereComplete then
    begin
      NvMetier := NvMetierChoisi;
      NvNiveau := '1';
    end
  else if radiobuttonChanger.Checked and Not CarriereComplete then
    begin
      NvMetier := NvMetierChoisi;
      NvNiveau := '1';
   end
  else
    begin
      NvMetier := '';
      NvNiveau := '';
    end;

  // Dernier niveau de la carriere EN COURS. Etait ecrit '4' en dur, ce qui refusait le
  // passage au niveau 5 des carrieres qui en ont cinq (le Mage de High Elf Player's Guide).
  // MaxNiveau = 0 signifie carriere inconnue de ListMetierNiveau : on ne bloque pas, le
  // reste de la chaine de controles ci-dessous s'applique quand meme.
  MaxNiveau        := ChercheMaxMetierNiveau(CarriereDeSuite());

  // tests
  if radiobuttonsuivant.Checked and (MaxNiveau > 0) and (StrToIntDef(MetierNvEnCours, 0) >= MaxNiveau) then
    ShowMEssage(GetTexteLibelle('RULES-MESS_043'))
  // Combo visible et rien de selectionne : le joueur n'a pas dit vers quelle carriere il
  // monte. On ne choisit pas a sa place - continuer dans la carriere en cours est une
  // decision, pas un defaut.
  else if radiobuttonsuivant.Checked and ComboBoxNvMetier.Visible and (ComboBoxNvMetier.ItemIndex < 0) then
    ShowMEssage(GetTexteLibelle('RULES-MESS_058'))
  else if (XpDispo < 0) then
    ShowMEssage(GetTexteLibelle('RULES-MESS_025'))
  else if StrToIntDef(EditTotalXp.Text,0) < StrToIntDef(tabExperience.Cells[ColXpDonnee,LigXpTotal],0) then
    ShowMEssage(GetTexteLibelle('RULES-MESS_026'))
  else if radiobuttonChanger.Checked and (NvMetier = '') then
    ShowMEssage(GetTexteLibelle('RULES-MESS_027'))
  else if radiobuttonsuivant.Checked and Not CarriereComplete then
    ShowMEssage(GetTexteLibelle('RULES-MESS_028'))
  else if radiobuttonsuivant.Checked and CarriereComplete and (XpDispo < EditNeedRealXp.Value) then
    ShowMEssage(GetTexteLibelle('RULES-MESS_029')+IntToStr(EditNeedRealXp.Value))
  else if radiobuttonChanger.Checked and CarriereComplete and (XpDispo < EditNeedRealXp.Value)  then
    ShowMEssage(GetTexteLibelle('RULES-MESS_030')+IntToStr(EditNeedRealXp.Value))
  else if radiobuttonChanger.Checked and Not CarriereComplete and (XpDispo < EditNeedRealXp.Value) then
    ShowMEssage(GetTexteLibelle('RULES-MESS_031')+IntToStr(EditNeedRealXp.Value))
  else if (radiobuttonChanger.Checked or radiobuttonsuivant.Checked) and ChoixNonFait() then
    ShowMEssage(GetTexteLibelle('RULES-MESS_032'))
  // Bloque Valider tant qu'un Miracle/sort a choix (ModeSort=CHOIX, colonne "Spell" posee
  // par SortAffiche) n'est pas resolu - la resolution elle-meme (TabAugmentationTalentDblClick)
  // ne depend pas de Valider, contrairement au bouton +Spell qui a cause l'impasse du
  // 18/09/2026 (A FAIRE.txt, tentative AjoutMineur). AjoutMineur retire : cette detection
  // directe sur la colonne le rend inutile.
  else if RechercherDansColonne(TabAugmentationTalent, ConstArbreAuChoix, ColAugmTalSort) <> -1 then
    ShowMEssage(GetTexteLibelle('RULES-MESS_033'))
  else
    begin
      AjouteEquipementNiveau();
      MajTables();
    end;
end;

procedure TWinPersonnages.ButtonPdfClick(Sender: TObject);
begin
  // Personnage.XpTotal/Xp25Total/XpActuel ne sont ecrits qu'au chargement du XML
  // (chargepersonnage.pas), jamais resynchronises pendant la session - sans ceci, le Pdf
  // genere depuis cette fenetre affiche les valeurs du fichier a l'ouverture, pas celles
  // de l'ecran (CONTEXT.md, chantier Depense/Restante Xp).
  Personnage.XpTotal   := StrToIntDef(EditTotalXp.Text, 0);
  Personnage.Xp25Total := StrToIntDef(EditTotalXp25.Text, 0);
  Personnage.XpActuel  := CalculXpEtat().Restante;

  // Options d'astérisques : Personnage.Options n'est reécrit qu'à la sauvegarde, or le PDF le lit.
  Personnage.Options := StringReplace(Personnage.Options, AjouteAccolade(ConstXmlOptionSansAsterisque), '', [rfReplaceAll]);
  Personnage.Options := StringReplace(Personnage.Options, AjouteAccolade(ConstXmlOptionSansMontant), '', [rfReplaceAll]);
  if CheckBoxSansAsterisque.Checked then
    Personnage.Options += AjouteAccolade(ConstXmlOptionSansAsterisque)
  else if CheckBoxSansMontant.Checked then
    Personnage.Options += AjouteAccolade(ConstXmlOptionSansMontant);
  Personnage.Options := StringReplace(Personnage.Options, AjouteAccolade(ConstXmlOptionStylePdf), '', [rfReplaceAll]);
  Personnage.Options := StringReplace(Personnage.Options, AjouteAccolade(ConstXmlOptionPdfSansCouleur), '', [rfReplaceAll]);
  if CheckBoxStylePdf.Checked then
    Personnage.Options += AjouteAccolade(ConstXmlOptionStylePdf);
  if not CheckBoxCouleurPdf.Checked then
    Personnage.Options += AjouteAccolade(ConstXmlOptionPdfSansCouleur);
  Personnage.Options := StringReplace(Personnage.Options, AjouteAccolade(ConstXmlOptionPdfEconomie), '', [rfReplaceAll]);
  if CheckBoxEconomiePdf.Checked then
    Personnage.Options += AjouteAccolade(ConstXmlOptionPdfEconomie);

  if (CheckBoxPdfFeldo2p.Checked = false) then
    PdfPersonnageCreation(Personnage, true)
  else
    PdfPersonnageCreationFeldo2P(Personnage);
end;

procedure TWinPersonnages.TabSortDblClick(Sender: TObject);
Var
  PSort: StructureSort;
begin
  // ouvrir les métiers
  SelectWinSort     := TabSort.Cells[3, TabSort.Row];
  SelectWinLivre    := Personnage.LivresAcceptes;
  FenSort           := TWinSpells.Create(Application);
  FenSort.Position  := poOwnerFormCenter;
  FenSort.ShowModal;

  if ChoixWinSort <> '' then
    begin
      pSort                         := ChercheSort(ChoixWinSort);
      TabSort.Cells[1, TabSort.Row] := PSort.CodeSort;
      TabSort.Cells[2, TabSort.Row] := PSort.Libelle;
    end;
  SelectWinSort  := '';
  SelectWinLivre := '';
  ChoixWinSort   := '';
end;

procedure TWinPersonnages.TabTalentDblClick(Sender: TObject);
begin
  // ouvrir les Talents
  FCurrentTabSheet    := TPage(PageExperience.Page[PageExperience.PageIndex]);
  SelectWinTalent     := TabTalent.Cells[ColTalCode, TabTalent.Row];
  FenTalent           := TWintTalent.Create(Application);
  FenTalent.Position  := poOwnerFormCenter;
  FenTalent.Show;
  SelectWinTalent := '';
  ChoixWinTalent  := '';
end;

procedure TWinPersonnages.ButtonSauvegardeClick(Sender: TObject);
begin
  // sur echec la fenetre reste ouverte (message deja affiche par XmlSauvegarde)
  if XmlSauvegarde() then
    Close;
end;

procedure TWinPersonnages.CheckBoxCalculChange(Sender: TObject);
Var
  Largeur: Integer = 0;
  Hauteur: Integer = 1;
begin
  if CheckBoxCalcul.Checked then
    Begin
      Largeur := 50;
      Hauteur := TabAttribut.DefaultRowHeight;
    end;

  TabTalent.ColWidths[5]               := Largeur;

  // Race, Lance et Talent sont toujours renseignes : ils suivent la case. Les lignes et colonnes
  // dont la source peut manquer (mutation, carriere, objet, signe, avancees...) ne se montrent
  // que si elles contiennent quelque chose : AjusteDetailsCalcul.
  TabAttribut.RowHeights[LigAttRace]     := Hauteur;
  TabAttribut.RowHeights[LigAttLance]    := Hauteur;
  TabAttribut.RowHeights[LigAttTalent]   := Hauteur;
  AjusteDetailsCalcul();

  TabAttribut.ColWidths[ColAttDestin]  := Largeur;
  TabAttribut.ColWidths[ColAttResil]   := Largeur;

  TabTalent.ColWidths[9]               := Largeur;
  TabTalent.ColWidths[10]              := Largeur;

  AjustePositionTables();
end;

// Regle des lignes vides (Nono, 21/09/2026) : les lignes de detail des caracteristiques et les
// colonnes de detail des competences ne s'affichent que si la case « Calcul » est cochee ET
// qu'elles contiennent une valeur non nulle. Renvoie vrai si une taille a change (l'appelant doit
// alors recalculer la mise en page).
function TWinPersonnages.AjusteDetailsCalcul(): Boolean;
  var
    Actif:   Boolean;
    Change:  Boolean;   // une taille a change (Result n'est pas visible des sous-procedures)

  function LigneNonVide(Lig: Integer): Boolean;
    var
      IndCol: Integer;
    begin
      Result := False;
      for IndCol := 2 to TabAttribut.ColCount - 1 do
        if StrToIntDef(TabAttribut.Cells[IndCol, Lig], 0) <> 0 then
          Exit(True);
    end;

  function ColonneNonVide(Col: Integer): Boolean;
    var
      IndLig: Integer;
    begin
      Result := False;
      for IndLig := 1 to TabCompetence.RowCount - 1 do
        if StrToIntDef(TabCompetence.Cells[Col, IndLig], 0) <> 0 then
          Exit(True);
    end;

  procedure PoseLigne(Lig: Integer);
    var
      Hauteur: Integer;
    begin
      if Actif and LigneNonVide(Lig) then
        Hauteur := TabAttribut.DefaultRowHeight
      else
        Hauteur := 1;
      if TabAttribut.RowHeights[Lig] <> Hauteur then
        begin
          TabAttribut.RowHeights[Lig] := Hauteur;
          Change := True;
        end;
    end;

  procedure PoseColonne(Col: Integer);
    var
      Largeur: Integer;
    begin
      if Actif and ColonneNonVide(Col) then
        Largeur := 50
      else
        Largeur := 0;
      if TabCompetence.ColWidths[Col] <> Largeur then
        begin
          TabCompetence.ColWidths[Col] := Largeur;
          Change := True;
        end;
    end;

  begin
    Change := False;
    Actif  := CheckBoxCalcul.Checked;
    PoseLigne(LigAttMutation);
    PoseLigne(LigAttPathologie);
    PoseLigne(LigAttCareer);
    PoseLigne(LigAttObjet);
    PoseLigne(LigAttSigne);
    PoseColonne(ColComp35);
    PoseColonne(ColComp40);
    PoseColonne(ColCompWork);
    PoseColonne(ColCompMutation);
    PoseColonne(ColCompCareer);
    PoseColonne(ColCompAppartenance);
    Result := Change;
  end;

procedure TWinPersonnages.CheckBoxXpChange(Sender: TObject);
  Var
    Largeur: Integer = 0;
    Hauteur: Integer = 1;
  begin
    if CheckBoxXp.Checked then
      Begin
        Largeur := 50;
        Hauteur := TabAttribut.DefaultRowHeight;
      end;

    TabCompetence.ColWidths[ColCompXp] := Largeur;
    TabTalent.ColWidths[6]             := Largeur;
    TabCarriere.ColWidths[4]           := Largeur;
    TabEquipement.ColWidths[5]         := Largeur;
    TabAttribut.RowHeights[LigAttXp]   := Hauteur;

    AjustePositionTables();
  end;

procedure TWinPersonnages.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if FVerrouPerso <> 0 then
    begin
      CloseHandle(FVerrouPerso);
      FVerrouPerso := 0;
    end;
  NettoyerElementsFenetre(self);
  EffaceDonnee(TabAttribut, 17);   // = RowCount de l'initialisation (LigAttAsterisc + 1)
  EffaceDonnee(TabCompetence, 1);
  EffaceDonnee(TabTalent, 1);
  EffaceDonnee(TabCarriere, 1);
  EffaceDonnee(TabEquipement, 1);
  ListImage.Clear;
  PremierAjustage := 3;
end;

procedure TWinPersonnages.EffaceDonnee(Tableau: TStringGrid; NbLig: Integer);
  var
    I, J: Integer;
  begin
    for I := 1 to Tableau.ColCount - 1 do
      for J := 1 to Tableau.RowCount - 1 do
        Tableau.Cells[I, J] := '';
    Tableau.RowCount := NbLig;
  end;

procedure TWinPersonnages.ButtonHistoriqueClick(Sender: TObject);
begin
  EffaceDonnee(TabAttribut, 17);   // = RowCount de l'initialisation (LigAttAsterisc + 1)
  EffaceDonnee(TabCompetence, 1);
  EffaceDonnee(TabTalent, 1);
  EffaceDonnee(TabCarriere, 1);
  EffaceDonnee(TabEquipement, 1);
  AttributInit();
  XmlChargePersonnage(TabHistorique.Cells[2, TabHistorique.Row]);
end;

// Details physiques : ouvre WinPhysique (tirage Rulebook p.40 ou saisie libre) et recopie le
// resultat dans les quatre champs de la fiche, lus a la sauvegarde. Age et taille sont
// vides ou a 0 tant que rien n'a ete saisi : la fenetre tire alors d'elle-meme.
procedure TWinPersonnages.ButtonPhysiqueClick(Sender: TObject);
var
  FenPhysique: TWinPhysique;
begin
  PhysiqueCodeRace := Personnage.Race;
  PhysiqueAge      := StrToIntDef(EditAge.Text, 0);
  PhysiqueTaille   := StrToIntDef(EditHeight.Text, 0);
  PhysiqueUnite    := Personnage.HeightUnit;
  PhysiqueYeux     := EditEyeColors.Text;
  PhysiqueCheveux  := EditHairColors.Text;
  FenPhysique          := TWinPhysique.Create(Application);
  FenPhysique.Position := poOwnerFormCenter;
  try
    FenPhysique.ShowModal;
  finally
    FenPhysique.Free;
  end;
  if PhysiqueValide then
    begin
      EditAge.Text        := IntToStr(PhysiqueAge);
      EditHeight.Text     := IntToStr(PhysiqueTaille);
      Personnage.HeightUnit := PhysiqueUnite;
      EditEyeColors.Text  := PhysiqueYeux;
      EditHairColors.Text := PhysiqueCheveux;
    end;
end;

procedure TWinPersonnages.ButtonQuitterClick(Sender: TObject);
begin
  Close;
end;

procedure TWinPersonnages.ButtonArmeClick(Sender: TObject);
  Var
    PArme: StructureArme;
    IndCompArme: Integer;
  begin
    // ouvrir les métiers
    SelectWinArme     := ConstSelectionne;
    SelectWinLivre    := Personnage.LivresAcceptes;
    // Competences du personnage, pour la case qui limite la liste des armes.
    SelectWinArmeCompetences := '';
    for IndCompArme := 1 to TabCompetence.RowCount - 1 do
      if TabCompetence.Cells[ColCompCode, IndCompArme] <> '' then
        begin
          if SelectWinArmeCompetences <> '' then SelectWinArmeCompetences := SelectWinArmeCompetences + ',';
          SelectWinArmeCompetences := SelectWinArmeCompetences + TabCompetence.Cells[ColCompCode, IndCompArme];
        end;
    SelectWinMunitions := CheckBoxMunition.Checked;
    FenArme           := TWinWeapons.Create(Application);
    FenArme.Position  := poOwnerFormCenter;
    FenArme.ShowModal;
    SelectWinMunitions := True;

    if ChoixWinArme <> '' then
      begin
        pArme := ChercheArme(ChoixWinArme);
        TabEquipement.RowCount                          := TabEquipement.RowCount + 1;
        TabEquipement.Cells[0, TabEquipement.RowCount-1]:= '+';
        TabEquipement.Cells[1, TabEquipement.RowCount-1]:= IntToStr(TabEquipement.RowCount);
        TabEquipement.Cells[2, TabEquipement.RowCount-1]:= PArme.CodeArme;
        TabEquipement.Cells[3, TabEquipement.RowCount-1]:= TypeEquipWe;
        TabEquipement.Cells[4, TabEquipement.RowCount-1]:= PArme.Libelle;
        // Fabrication D'ORIGINE de l'arme (Jade Longsword...) : posee automatiquement, comme au
        // livre. CONTEXT.md 2.29, chantier "objets a fabrication integree".
        TabEquipement.Cells[7, TabEquipement.RowCount-1]:= PArme.Fabrication;
        AdjustGridColumnsWidth(TabEquipement, 0, false, false);
        RafraichitTabEquipementAffichage();
      end;
    SelectWinArme  := '';
    SelectWinArmeCompetences := '';
    SelectWinLivre := '';
    ChoixWinArme   := '';
end;

// Ajoute un objet du catalogue DATA_TRAPPING (ligne Divers, quantite 1). La ligne est ecrite
// a la sauvegarde comme les Divers de carriere, ChercheTrapping resout son libelle.
procedure TWinPersonnages.ButtonEquipementClick(Sender: TObject);
  Var
    PTrapping: StructureTrapping;
  begin
    SelectWinTrapping := ConstSelectionne;
    SelectWinLivre    := Personnage.LivresAcceptes;
    // Catalogue filtre sur le meme theme Montures/Navires/Vehicules que la categorie choisie
    // dans ListBoxEquipementCategorie (0) - sinon tous les Divers s'y melangent, gene relevee
    // par Nono sur les vehicules. Categorie 3 (Divers) : l'inverse, memes mecanisme et valeurs
    // que TMenu.TabBibliothequeDblClick/ButtonEquipementClick (warhammersource.pas).
    if ListBoxEquipementCategorie.ItemIndex = 0 then
      ModeEquipements := meVehicules
    else
      ModeEquipements := meHorsVehicules;
    FenEquipement     := TWinEquipements.Create(Application);
    ModeEquipements   := meTout;
    FenEquipement.Position := poOwnerFormCenter;
    FenEquipement.ShowModal;

    if ChoixWinTrapping <> '' then
      begin
        PTrapping := ChercheTrapping(ChoixWinTrapping);
        TabEquipement.RowCount                          := TabEquipement.RowCount + 1;
        TabEquipement.Cells[0, TabEquipement.RowCount-1]:= '+';
        TabEquipement.Cells[1, TabEquipement.RowCount-1]:= IntToStr(TabEquipement.RowCount);
        TabEquipement.Cells[2, TabEquipement.RowCount-1]:= PTrapping.CodeTrapping;
        // Un animal (profil renseigne) est de type Animal, pas Divers : comme au chargement
        // (chargepersonnage.pas, SUBCHAPTER_DIVERS) ; sinon le porteur n'est pas reconnu.
        if TrappingEstAnimal(PTrapping) then
          TabEquipement.Cells[3, TabEquipement.RowCount-1]:= TypeEquipAN
        else
          TabEquipement.Cells[3, TabEquipement.RowCount-1]:= TypeEquipDI;
        TabEquipement.Cells[4, TabEquipement.RowCount-1]:= PTrapping.Libelle;
        // Fabrication D'ORIGINE du Trapping (objet pre-enchante du catalogue) : posee
        // automatiquement, meme mecanisme que PArme.Fabrication ci-dessus. Brique (b), 28/09/2026.
        TabEquipement.Cells[7, TabEquipement.RowCount-1]:= PTrapping.Fabrication;
        TabEquipement.Cells[9, TabEquipement.RowCount-1]:= '1';
        AdjustGridColumnsWidth(TabEquipement, 0, false, false);
        RafraichitTabEquipementAffichage();
      end;
    SelectWinTrapping := '';
    SelectWinLivre    := '';
    ChoixWinTrapping  := '';
end;

// Saisie du nom et de l'encombrement d'un objet de texte pur. Vrai si Nono a valide.
function TWinPersonnages.SaisieTexteLibre(var Nom: String; var Enc: Integer): Boolean;
  var
    Saisie:   String;
    NomSaisi: String;
  begin
    Result   := False;
    NomSaisi := Nom;
    if not InputQuery(GetTexteLibelle('RULES-LAB_644'), GetTexteLibelle('RULES-LAB_645'), NomSaisi) then exit;
    // Le nom est ecrit dans un attribut XML : guillemets et signes XML remplaces par une apostrophe.
    NomSaisi := StringReplace(NomSaisi, '"', '''', [rfReplaceAll]);
    NomSaisi := StringReplace(NomSaisi, '<', '''', [rfReplaceAll]);
    NomSaisi := StringReplace(NomSaisi, '>', '''', [rfReplaceAll]);
    NomSaisi := StringReplace(NomSaisi, '&', '''', [rfReplaceAll]);
    NomSaisi := Trim(NomSaisi);
    if NomSaisi = '' then exit;
    Saisie := IntToStr(Enc);
    if not InputQuery(GetTexteLibelle('RULES-LAB_644'), GetTexteLibelle('RULES-LAB_646'), Saisie) then exit;
    Enc    := StrToIntDef(Trim(Saisie), 0);
    if Enc < 0 then Enc := 0;
    Nom    := NomSaisi;
    Result := True;
  end;

// +Texte : objet Divers sans fiche ni livre, juste un nom et un encombrement (code TEXTE-<N>).
procedure TWinPersonnages.ButtonTexteClick(Sender: TObject);
  var
    Nom:   String;
    Enc:   Integer;
    N:     Integer;
    Ligne: Integer;
  begin
    Nom := '';
    Enc := 0;
    if not SaisieTexteLibre(Nom, Enc) then exit;
    N := 1;
    while RechercherDansColonne(TabEquipement, PrefixeEquipementTexte + IntToStr(N), 2) >= 0 do
      Inc(N);
    TabEquipement.RowCount := TabEquipement.RowCount + 1;
    Ligne := TabEquipement.RowCount - 1;
    TabEquipement.Cells[0, Ligne]  := '+';
    TabEquipement.Cells[1, Ligne]  := IntToStr(TabEquipement.RowCount);
    TabEquipement.Cells[2, Ligne]  := PrefixeEquipementTexte + IntToStr(N);
    TabEquipement.Cells[3, Ligne]  := TypeEquipDI;
    TabEquipement.Cells[4, Ligne]  := Nom;
    TabEquipement.Cells[9, Ligne]  := '1';
    TabEquipement.Cells[13, Ligne] := Nom;
    TabEquipement.Cells[14, Ligne] := IntToStr(Enc);
    AdjustGridColumnsWidth(TabEquipement, 0, false, false);
    RafraichitTabEquipementAffichage();
  end;

// Libelle d'un objet propre deja injecte dans les listes, selon son type (arme, armure, divers).
function TWinPersonnages.LibelleObjetPropre(const Balise, Code: String): String;
  begin
    if Balise = 'Weapon' then
      Result := ChercheArme(Code).Libelle
    else if Balise = 'Armor' then
      Result := ChercheArmure(Code).Libelle
    else
      Result := ChercheTrapping(Code).Libelle;
  end;

// +Objet : cree un objet propre du type de la categorie affichee (armes, armures, divers), le range
// dans la fiche, l'injecte dans les listes et ajoute sa ligne d'equipement.
procedure TWinPersonnages.ButtonObjetClick(Sender: TObject);
  var
    Code:    String;
    Xml:     String;
    Balise:  String;
    Fabrication: String;
    Ligne:   Integer;
  begin
    case ListBoxEquipementCategorie.ItemIndex of
      1: Balise := 'Weapon';
      2: Balise := 'Armor';
    else
      Balise := 'Trapping';
    end;
    Code := CodeObjetPropreSuivant(Personnage.ObjetsPropres);
    Xml  := Personnage.ObjetsPropres;
    if not SaisirObjetPropre(ButtonTexte, Balise, Code, Xml) then exit;
    Personnage.ObjetsPropres := Xml;
    InjecteObjetsPropres(Personnage.ObjetsPropres);
    TabEquipement.RowCount := TabEquipement.RowCount + 1;
    Ligne := TabEquipement.RowCount - 1;
    TabEquipement.Cells[0, Ligne] := '+';
    TabEquipement.Cells[1, Ligne] := IntToStr(TabEquipement.RowCount);
    TabEquipement.Cells[2, Ligne] := Code;
    if Balise = 'Weapon' then
      begin
        TabEquipement.Cells[3, Ligne] := TypeEquipWe;
        Fabrication := ChercheArme(Code).Fabrication;
      end
    else if Balise = 'Armor' then
      begin
        TabEquipement.Cells[3, Ligne] := TypeEquipAr;
        Fabrication := ChercheArmure(Code).Fabrication;
      end
    else
      begin
        TabEquipement.Cells[3, Ligne] := TypeEquipDI;
        TabEquipement.Cells[9, Ligne] := '1';
        Fabrication := ChercheTrapping(Code).Fabrication;
      end;
    TabEquipement.Cells[4, Ligne] := LibelleObjetPropre(Balise, Code);
    TabEquipement.Cells[7, Ligne] := Fabrication;
    AdjustGridColumnsWidth(TabEquipement, 0, false, false);
    RafraichitTabEquipementAffichage();
  end;

// Le bouton +Specialisation d'une page n'apparait que si la ligne courante attend encore son choix
// (cellule Specialisation = "Selectionner"). LigneComp / LigneTal : ligne a tester, <= 0 = ligne courante.
procedure TWinPersonnages.MajBoutonsSpecialisation(LigneComp, LigneTal: Integer);
  begin
    if not Assigned(ButtonSpecCompetence) then exit;
    if LigneComp <= 0 then LigneComp := TabAugmentationCompetence.Row;
    if LigneTal  <= 0 then LigneTal  := TabAugmentationTalent.Row;
    ButtonSpecCompetence.Visible :=
      (LigneComp > 0) and (LigneComp < TabAugmentationCompetence.RowCount) and
      (ColAugmCompSpe < TabAugmentationCompetence.ColCount) and
      (TabAugmentationCompetence.Cells[ColAugmCompSpe, LigneComp] = GetTexteLibelle(ConstLabSelSpe));
    ButtonSpecTalent.Visible :=
      (LigneTal > 0) and (LigneTal < TabAugmentationTalent.RowCount) and
      (ColAugmTalSpe < TabAugmentationTalent.ColCount) and
      (TabAugmentationTalent.Cells[ColAugmTalSpe, LigneTal] = GetTexteLibelle(ConstLabSelSpe));
    // sous la liste des rubriques (Competence / Talent), meme emplacement pour les deux, et seulement
    // sur sa page : l'ancien emplacement dans la page se retrouvait sous la grille
    ButtonSpecCompetence.Visible := ButtonSpecCompetence.Visible and (PageExperience.PageIndex = TabSheetCompetence.PageIndex);
    ButtonSpecTalent.Visible     := ButtonSpecTalent.Visible and (PageExperience.PageIndex = TabSheetTalent.PageIndex);
    // assez large et haut pour le libelle complet (la liste de rubriques est etroite)
    ButtonSpecCompetence.SetBounds(ListBoxExperience.Left, ListBoxExperience.Top + ListBoxExperience.Height + 8,
                                   Max(ListBoxExperience.Width, 240), Max(ButtonTexte.Height, 44));
    ButtonSpecTalent.SetBounds(ButtonSpecCompetence.Left, ButtonSpecCompetence.Top,
                               ButtonSpecCompetence.Width, ButtonSpecCompetence.Height);
    ButtonSpecCompetence.BringToFront;
    ButtonSpecTalent.BringToFront;
  end;

// Rejoue la mise a jour apres le traitement en cours : le changement de page remplit parfois les
// grilles apres l'evenement, la ligne courante n'est alors correcte qu'ensuite.
procedure TWinPersonnages.MajBoutonsSpecialisationDiffere(Data: PtrInt);
  begin
    MajBoutonsSpecialisation(0, 0);
  end;

// Codes qui retiennent un objet propre a l'enregistrement : lignes d'equipement (objets) et codes de
// competence/talent du personnage (specialisations propres). Une specialisation creee puis jamais
// prise n'y figure nulle part : elle est elaguee a l'enregistrement (ObjetsPropresUtiles).
procedure TWinPersonnages.CodesObjetsPropresUtilises(Codes: TStrings);
  var
    I: Integer;
  begin
    for I := 1 to TabEquipement.RowCount - 1 do
      Codes.Add(TabEquipement.Cells[2, I]);
    for I := 1 to TabCompetence.RowCount - 1 do
      Codes.Add(TabCompetence.Cells[ColCompCode, I]);
    for I := 1 to TabTalent.RowCount - 1 do
      Codes.Add(TabTalent.Cells[ColTalCode, I]);
    for I := 1 to TabAugmentationCompetence.RowCount - 1 do
      Codes.Add(TabAugmentationCompetence.Cells[ColAugmCompSpeSel, I]);
    for I := 1 to TabAugmentationTalent.RowCount - 1 do
      Codes.Add(TabAugmentationTalent.Cells[ColAugmTalSpeSel, I]);
    for I := 0 to High(Personnage.CreationCompetence35) do
      Codes.Add(Personnage.CreationCompetence35[I].CodeCompetence);
    for I := 0 to High(Personnage.CreationCompetence40) do
      Codes.Add(Personnage.CreationCompetence40[I].CodeCompetence);
    for I := 0 to High(Personnage.CreationTalent) do
      Codes.Add(Personnage.CreationTalent[I].CodeTalent);
    for I := 0 to High(Personnage.MetierCompetence) do
      Codes.Add(Personnage.MetierCompetence[I].CodeCompetence);
    for I := 0 to High(Personnage.MetierTalent) do
      Codes.Add(Personnage.MetierTalent[I].CodeTalent);
    for I := 0 to High(Personnage.AugmentationCompetence) do
      Codes.Add(Personnage.AugmentationCompetence[I].CodeCompetence);
    for I := 0 to High(Personnage.AugmentationTalent) do
      Codes.Add(Personnage.AugmentationTalent[I].CodeTalent);
    for I := 0 to High(Personnage.CompetenceAppartenance) do
      Codes.Add(Personnage.CompetenceAppartenance[I].CodeCompetence);
  end;

// +Specialisation : cree une specialisation propre au personnage sous le generique de la ligne courante,
// la range dans la fiche (<CUSTOM_ITEMS>), l'injecte, puis rouvre la fenetre de choix pour la prendre.
procedure TWinPersonnages.ButtonSpecialisationClick(Sender: TObject);
  var
    EstTalent: Boolean;
    CodeParent: String;
    Nom:       String = '';
    Xml:       String;
    Code:      String;
  begin
    EstTalent := (Sender = ButtonSpecTalent);
    if EstTalent then
      CodeParent := TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row]
    else
      CodeParent := TabAugmentationCompetence.Cells[ColAugmCompCode, TabAugmentationCompetence.Row];
    if not InputQuery(GetTexteLibelle('RULES-LAB_689'), GetTexteLibelle('RULES-LAB_690'), Nom) then exit;
    Xml  := Personnage.ObjetsPropres;
    Code := AjouteSpecialisationPropre(Xml, EstTalent, CodeParent, Nom);
    if Code = '' then exit;
    Personnage.ObjetsPropres := Xml;
    InjecteObjetsPropres(Personnage.ObjetsPropres);
    if EstTalent then
      begin
        TabAugmentationTalent.Col := ColAugmTalSpe;
        TabAugmentationTalentDblClick(nil);
      end
    else
      begin
        TabAugmentationCompetence.Col := ColAugmCompSpe;
        TabAugmentationCompetenceDblClick(nil);
      end;
    MajBoutonsSpecialisation(0, 0);
  end;

// Reouvre la fiche d'un objet propre (double-clic sur sa ligne) : nom et valeurs sont relus des listes.
procedure TWinPersonnages.ModifierObjetPropre(Ligne: Integer);
  var
    Code:   String;
    Xml:    String;
    Balise: String;
    I:      Integer;
  begin
    Code := TabEquipement.Cells[2, Ligne];
    Xml  := ObjetPropreXml(Personnage.ObjetsPropres, Code);
    if Xml = '' then exit;
    Balise := BaliseObjetPropre(Xml);
    Xml  := Personnage.ObjetsPropres;
    if not SaisirObjetPropre(ButtonTexte, Balise, Code, Xml) then exit;
    Personnage.ObjetsPropres := Xml;
    InjecteObjetsPropres(Personnage.ObjetsPropres);
    // le nom peut avoir change : toutes les lignes de cet objet le reprennent
    for I := 1 to TabEquipement.RowCount - 1 do
      if TabEquipement.Cells[2, I] = Code then
        TabEquipement.Cells[4, I] := LibelleObjetPropre(Balise, Code);
    RafraichitTabEquipementAffichage();
  end;

procedure TWinPersonnages.ButtonFabricationClick(Sender: TObject);
  begin
    if (TabEquipement.Row > 0)
            // Une ligne qui cite un talent est un sort : pas de fabrication dessus.
      // Remplace la liste fermee des six TypSpell, qui laissait passer les rituels.
      and (TalentSort(TabEquipement.Cells[2, TabEquipement.Row]).CodeTalent = '') then
        begin
          SelectWinFabrication     := TabEquipement.Cells[7,TabEquipement.row];
          // Type de l objet : la fenetre ne propose que les fabrications qui s y appliquent.
          if TrimRight(TabEquipement.Cells[3,TabEquipement.row]) = TrimRight(TypeEquipWe) then
            SelectWinFabricationType := 'Weapon'
          else if (TrimRight(TabEquipement.Cells[3,TabEquipement.row]) = TrimRight(TypeEquipAR))
               or (TrimRight(TabEquipement.Cells[3,TabEquipement.row]) = TrimRight(TypeEquipARS)) then
            SelectWinFabricationType := 'Armour'
          else
            SelectWinFabricationType := 'Misc';
          FenFabrication          := TWinFabrications.Create(Application);
          FenFabrication.Position  := poOwnerFormCenter;
          FenFabrication.ShowModal;

          if ChoixWinFabrication <> '' then
            begin
              TabEquipement.Cells[7,TabEquipement.row] := QualiteSansMarqueur(ChoixWinFabrication);
              FabAjoute := true;
            end;

          SelectWinFabrication:= '';
          SelectWinFabricationType := '';
          ChoixWinFabrication := '';
          AfficheFabrication();
          RafraichitTabEquipementAffichage();
        end;
  end;

procedure TWinPersonnages.ButtonDeleteClick(Sender: TObject);
  var
    Reponse:  Integer;
    i:        Integer;
  begin
    if (TabEquipement.Row > 0)
      // Une ligne qui cite un talent est un sort : il se retire par son ecran, pas ici.
      // Remplace la liste fermee des six TypSpell, qui laissait passer les rituels.
      and (TalentSort(TabEquipement.Cells[2, TabEquipement.Row]).CodeTalent = '') then
        begin
          Reponse := MessageDlg(GetTexteLibelle('RULES-MESS_039'), mtConfirmation, mbYesNo, 0);
          if Reponse = mrYes then
            begin
              // Un animal retire rend ses objets au personnage.
              if TabEquipement.Cells[10, TabEquipement.Row] <> '' then
                for i := 1 to TabEquipement.RowCount - 1 do
                  if TabEquipement.Cells[11, i] = TabEquipement.Cells[10, TabEquipement.Row] then
                    TabEquipement.Cells[11, i] := '';
              // Décale les lignes suivantes vers le haut
              for i := TabEquipement.Row to TabEquipement.RowCount - 2 do
                TabEquipement.Rows[i].Assign(TabEquipement.Rows[i + 1]);

              // Supprime la dernière ligne, maintenant en double
              TabEquipement.RowCount := TabEquipement.RowCount - 1;
              RafraichitPorteurs;
            end
        end;
  end;

procedure TWinPersonnages.ButtonCorruptionAjouteClick(Sender: TObject);
  begin
    StringGridCorruption.RowCount                                     := StringGridCorruption.RowCount + 1;
    StringGridCorruption.Cells[1, StringGridCorruption.RowCount - 1]   := '0';
    StringGridCorruption.Row                                          := StringGridCorruption.RowCount - 1;
    StringGridCorruption.Col                                          := 1;
    CalculCorruptionLeft();
  end;

procedure TWinPersonnages.ButtonCorruptionSupprimeClick(Sender: TObject);
  var
    Reponse:  Integer;
    i:        Integer;
  begin
    if StringGridCorruption.Row > 0 then
      begin
        Reponse := MessageDlg(GetTexteLibelle('RULES-MESS_053'), mtConfirmation, mbYesNo, 0);
        if Reponse = mrYes then
          begin
            // Décale les lignes suivantes vers le haut
            for i := StringGridCorruption.Row to StringGridCorruption.RowCount - 2 do
              StringGridCorruption.Rows[i].Assign(StringGridCorruption.Rows[i + 1]);

            // Supprime la dernière ligne, maintenant en double
            StringGridCorruption.RowCount := StringGridCorruption.RowCount - 1;

            CalculCorruptionLeft();
          end;
      end;
  end;

Function TWinPersonnages.CalculCorruptionLost(): Integer;
  var
    IndLig: Integer;
    Lost:   Integer;
  begin
    Lost := 0;
    for IndLig := 1 to StringGridCorruption.RowCount - 1 do
      Lost := Lost + StrToIntDef(StringGridCorruption.Cells[1, IndLig], 0);
    Result := Lost;
  end;

procedure TWinPersonnages.CalculCorruptionLeft();
  var
    Restant: Integer;
  begin
    Restant := PersonnageCorruptionTotal(Personnage) - CalculCorruptionLost();

    LabelCorruptionLeft.Text    := IntToStr(Restant);
    LabelCorruptionLeft.Enabled := False;

    // Déclencheur du chantier mutation (CONTEXT.md §2.7) : le bouton n'est actif que quand la
    // capacité de corruption est épuisée.
    ButtonCorruptionMutation.Enabled := (Restant <= 0);
  end;

procedure TWinPersonnages.StringGridCorruptionEditingDone(Sender: TObject);
  begin
    CalculCorruptionLeft();
  end;

// Totaux affiches par les trois blocs, lus sur le tableau des attributs (meme lecture que ResilienceTotale
// pour le bouton Mutation). La Resolution a pour maximum la Resilience : si celle-ci baisse, elle baisse aussi.
procedure TWinPersonnages.MajReserves();
  begin
    PanelDestin.SetMaximum(StrToIntDef(TabAttribut.Cells[ColAttDestin, LigAttTotal], 0));
    PanelResilience.SetMaximum(StrToIntDef(TabAttribut.Cells[ColAttResil, LigAttTotal], 0));
    PanelResolve.SetMaximum(StrToIntDef(TabAttribut.Cells[ColAttResil, LigAttTotal], 0));
  end;

// Repercute sur le personnage la variation de la somme d'un registre depuis la derniere fois : meme voie que
// le bouton Mutation (Personnage.CreationAttribut + ligne "points de creation" du tableau des attributs).
procedure TWinPersonnages.AppliqueRegistre(Panel: TPanelReserve; const CodeAttribut: String; ColAtt: Integer; var Applique: Integer);
  var
    Delta:       Integer;
    IndAttribut: Integer;
    Trouve:      Boolean;
  begin
    if ReservesChargement then Exit;
    Delta := Panel.Somme - Applique;
    if Delta = 0 then Exit;
    Trouve := False;
    for IndAttribut := 0 to High(Personnage.CreationAttribut) do
      if CompareRechercheValeur(Personnage.CreationAttribut[IndAttribut].CodeAttribut, CodeAttribut) then
        begin
          Personnage.CreationAttribut[IndAttribut].Valeur := Personnage.CreationAttribut[IndAttribut].Valeur + Delta;
          Trouve := True;
          break;
        end;
    if not Trouve then
      begin
        PersonnageAttribut.CodeAttribut := CodeAttribut;
        PersonnageAttribut.Valeur       := Delta;
        PersonnageAttribut.Bonus        := '';
        Personnage.CreationAttribut     += [PersonnageAttribut];
      end;
    TabAttribut.Cells[ColAtt, LigAttLance] := IntToStr(StrToIntDef(TabAttribut.Cells[ColAtt, LigAttLance], 0) + Delta);
    CalculTotaux();
    Applique := Panel.Somme;
    MajReserves();
  end;

procedure TWinPersonnages.RegistreDestinChange(Sender: TObject);
  begin
    AppliqueRegistre(PanelDestin, ConstCaracDestin, ColAttDestin, DestinApplique);
  end;

procedure TWinPersonnages.RegistreResilienceChange(Sender: TObject);
  begin
    AppliqueRegistre(PanelResilience, ConstCaracResil, ColAttResil, ResilienceApplique);
  end;

// Onglet Mutations (CONTEXT.md §2.7, étape 7) - liste en lecture seule des mutations
// obtenues, résolues depuis Personnage.Mutations (juste un Code) via ChercheCorruptionTable.
// Colonne 0 réservée/en-tête (convention du projet), 1 = Type, 2 = Libellé, 3 = Code (caché,
// sert à retrouver l'Effet dans TabMutationClick).
procedure TWinPersonnages.AfficheMutations();
  var
    PersonnageMutation: StructurePersonnageMutation;
    PCorruptionTable:   StructureCorruptionTable;
    IndLig:             Integer;
  begin
    TabMutation.RowCount := 1;
    IndLig := 0;
    for PersonnageMutation in Personnage.Mutations do
      begin
        PCorruptionTable := ChercheCorruptionTable(PersonnageMutation.Code);

        IndLig := IndLig + 1;
        TabMutation.RowCount              := IndLig + 1;
        TabMutation.Cells[1, IndLig]      := GetTexteLibelle(PCorruptionTable.TypeCorruption);
        TabMutation.Cells[2, IndLig]      := PCorruptionTable.Libelle;
        TabMutation.Cells[3, IndLig]      := PersonnageMutation.Code;
      end;

    MemoMutationEffet.Text := '';
  end;

procedure TWinPersonnages.TabMutationClick(Sender: TObject);
  var
    PCorruptionTable: StructureCorruptionTable;
  begin
    if (TabMutation.Row < 1) then Exit;

    PCorruptionTable       := ChercheCorruptionTable(TabMutation.Cells[3, TabMutation.Row]);
    MemoMutationEffet.Text := TexteOuPageMutation(PCorruptionTable.Effet, PCorruptionTable.Livre, PCorruptionTable.Code);
  end;

// Retrait d'une mutation - premiere fois que Personnage.Mutations peut se retrecir. Ce qu'elle
// accordait (PersonnageMutationTalent/PersonnageMutationEquipement, chargepersonnage.pas) est
// calcule a la volee depuis cette meme liste : la cascade est donc automatique, rien d'autre a
// purger. CONTEXT.md, chantier "traits de creature".
procedure TWinPersonnages.TabMutationDblClick(Sender: TObject);
  var
    Reponse:        Integer;
    Ind:            Integer;
    IndSupp:        Integer;
    LibelleMutation: String;
  begin
    if (TabMutation.Row < 1) then Exit;

    Reponse := MessageDlg(GetTexteLibelle('RULES-MESS_060'), mtConfirmation, mbYesNo, 0);
    if Reponse <> mrYes then Exit;

    // Libellé capturé AVANT le retrait : une fois l'entrée sortie de Personnage.Mutations, plus
    // aucun moyen de savoir laquelle c'était - la ligne à 0 ci-dessous est la seule trace qui
    // survit dans l'historique de Corruption (conception validée avec Nono le 12/09/2026).
    LibelleMutation := TabMutation.Cells[2, TabMutation.Row];

    // TabMutation.Row est 1-based (ligne 0 = en-tete), Personnage.Mutations est 0-based -
    // meme correspondance que le remplissage dans AfficheMutations juste au-dessus.
    IndSupp := TabMutation.Row - 1;
    for Ind := IndSupp to High(Personnage.Mutations) - 1 do
      Personnage.Mutations[Ind] := Personnage.Mutations[Ind + 1];
    SetLength(Personnage.Mutations, Length(Personnage.Mutations) - 1);

    // Ligne compensatoire à 0 : ne change pas le total de points de Corruption (contrairement à
    // "Mutation acceptée"/"Résilience dépensée"), juste une trace narrative pour le souvenir.
    StringGridCorruption.RowCount                                   := StringGridCorruption.RowCount + 1;
    StringGridCorruption.Cells[1, StringGridCorruption.RowCount - 1] := '0';
    StringGridCorruption.Cells[2, StringGridCorruption.RowCount - 1] := GetTexteLibelle('RULES-LAB_179') + ' : ' + LibelleMutation;
    CalculCorruptionLeft();

    AfficheMutations();
  end;

// Onglet commun Afflictions/Maladies (ajout du 27/09/2026, a la demande de Nono) - meme
// principe qu'AfficheMutations ci-dessus, mais deux catalogues au lieu d'un : TypeChapitre
// distingue Affliction/Disease pour resoudre via ChercheAffliction/ChercheDisease. Colonne
// 0 reservee/en-tete, 1 = Type (Affliction/Disease), 2 = Libelle, 3 = Code (cache, sert a
// retrouver l'Effet dans TabPathologieClick et a retirer l'entree dans TabPathologieDblClick).
procedure TWinPersonnages.AfficheDiseasesAfflictions();
  var
    PersonnagePathologie: StructurePersonnagePathologie;
    PAffliction:          StructureAffliction;
    PDisease:             StructureDisease;
    IndLig:               Integer;
  begin
    TabPathologie.RowCount := 1;
    IndLig := 0;
    for PersonnagePathologie in Personnage.Pathologies do
      begin
        IndLig := IndLig + 1;
        TabPathologie.RowCount        := IndLig + 1;
        TabPathologie.Cells[3, IndLig]:= PersonnagePathologie.Code;
        if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
          begin
            PAffliction := ChercheAffliction(PersonnagePathologie.Code);
            TabPathologie.Cells[1, IndLig] := GetTexteLibelle('RULES-LAB_296');
            TabPathologie.Cells[2, IndLig] := PAffliction.Libelle;
          end
        else
          begin
            PDisease := ChercheDisease(PersonnagePathologie.Code);
            TabPathologie.Cells[1, IndLig] := GetTexteLibelle('RULES-LAB_281');
            TabPathologie.Cells[2, IndLig] := PDisease.Libelle;
          end;
      end;

    MemoPathologieEffet.Text := '';
  end;

procedure TWinPersonnages.TabPathologieClick(Sender: TObject);
  var
    PersonnagePathologie: StructurePersonnagePathologie;
  begin
    if (TabPathologie.Row < 1) then Exit;
    if (TabPathologie.Row - 1) > High(Personnage.Pathologies) then Exit;

    PersonnagePathologie := Personnage.Pathologies[TabPathologie.Row - 1];
    if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
      MemoPathologieEffet.Text := TexteOuPage(ChercheAffliction(PersonnagePathologie.Code).Effet, ConstXmlDataAffliction, ChercheAffliction(PersonnagePathologie.Code).Livre, PersonnagePathologie.Code)
    else
      MemoPathologieEffet.Text := TexteOuPage(ChercheDisease(PersonnagePathologie.Code).Symptoms, ConstXmlDataDisease, ChercheDisease(PersonnagePathologie.Code).Livre, PersonnagePathologie.Code);
  end;

// Retrait, meme principe que TabMutationDblClick - Personnage.Pathologies peut se retrecir,
// rien d'autre a purger (les modificateurs sont recalcules a la volee depuis cette meme
// liste, PersonnageAfflictionModificateur/PersonnageDiseaseModificateur, chargepersonnage.pas).
procedure TWinPersonnages.TabPathologieDblClick(Sender: TObject);
  var
    Reponse: Integer;
    Ind:     Integer;
    IndSupp: Integer;
  begin
    if (TabPathologie.Row < 1) then Exit;

    Reponse := MessageDlg(GetTexteLibelle('RULES-MESS_060'), mtConfirmation, mbYesNo, 0);
    if Reponse <> mrYes then Exit;

    // TabPathologie.Row est 1-based (ligne 0 = en-tete), Personnage.Pathologies est 0-based -
    // meme correspondance que le remplissage dans AfficheDiseasesAfflictions.
    IndSupp := TabPathologie.Row - 1;
    for Ind := IndSupp to High(Personnage.Pathologies) - 1 do
      Personnage.Pathologies[Ind] := Personnage.Pathologies[Ind + 1];
    SetLength(Personnage.Pathologies, Length(Personnage.Pathologies) - 1);

    AfficheDiseasesAfflictions();
    CalculTotaux();
  end;

procedure TWinPersonnages.ButtonPathologieAjouteAfflictionClick(Sender: TObject);
  var
    PersonnagePathologie: StructurePersonnagePathologie;
    CodeAttribut:         String;
    Face:                 Integer;
  begin
    PathologieCode    := '';
    PathologieLibelle := '';

    WinAfflictionCat          := TWinAfflictionCatalogue.Create(Application);
    WinAfflictionCat.Position := poOwnerFormCenter;
    WinAfflictionCat.ShowModal;

    if PathologieCode <> '' then
      begin
        PersonnagePathologie.TypeChapitre    := ConstXmlChapitreAffliction;
        PersonnagePathologie.Code            := PathologieCode;
        PersonnagePathologie.ValeurAleatoire := 0;

        // Certaines Afflictions (ex. Debilitation "-1d10 Toughness") fixent leur malus par un
        // jet de de plutot qu'une valeur fixe (<ModifyCaracAleatoire>) - le jet est montre a
        // Nono et valide/corrige par lui (WinJetPathologie), jamais tire en silence. Annuler
        // cette fenetre annule l'ajout de l'Affliction elle-meme.
        Face := PersonnageAfflictionFaceAleatoire(PathologieCode, CodeAttribut);
        if Face > 0 then
          begin
            JetPathologieFace     := Face;
            JetPathologieLibelle  := Format(GetTexteLibelle('RULES-LAB_297'), [Face, PathologieLibelle + ' (' + ChercheAttribut(CodeAttribut).Libelle + ')']);
            WinJetPathologieForm          := TWinJetPathologie.Create(Application);
            WinJetPathologieForm.Position := poOwnerFormCenter;
            WinJetPathologieForm.ShowModal;
            if JetPathologieResultat = 0 then Exit;
            PersonnagePathologie.ValeurAleatoire := -JetPathologieResultat;
          end;

        Personnage.Pathologies            += [PersonnagePathologie];
        AfficheDiseasesAfflictions();
        CalculTotaux();
      end;
  end;

procedure TWinPersonnages.ButtonPathologieAjouteDiseaseClick(Sender: TObject);
  var
    PersonnagePathologie: StructurePersonnagePathologie;
  begin
    PathologieCode    := '';
    PathologieLibelle := '';

    WinDiseaseCat          := TWinDiseaseCatalogue.Create(Application);
    WinDiseaseCat.Position := poOwnerFormCenter;
    WinDiseaseCat.ShowModal;

    if PathologieCode <> '' then
      begin
        PersonnagePathologie.TypeChapitre := ConstXmlChapitreDisease;
        PersonnagePathologie.Code         := PathologieCode;
        Personnage.Pathologies            += [PersonnagePathologie];
        AfficheDiseasesAfflictions();
        CalculTotaux();
      end;
  end;

// Ambitions court/long terme (personnage et groupe) : saisie libre, fenetre dediee
// WinAmbition - demande de Nono, 27/09/2026. Le groupe est stocke sur CHAQUE personnage en
// attendant le chantier GROUPE (A FAIRE.txt). Onglet dedie de PageExperience (TabSheetAmbition/
// TabAmbition), meme principe que TabPathologie/TabMutation : lecture seule, double-clic ouvre
// la fenetre de saisie.
procedure TWinPersonnages.AfficheAmbition();
  var
    GroupeComplet: StructureGroupe;
  begin
    TabAmbition.RowCount           := 5;
    TabAmbition.Cells[1, 1]        := GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT') + GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT');
    TabAmbition.Cells[2, 1]        := Personnage.AmbitionCourt;
    TabAmbition.Cells[1, 2]        := GetTexteLibelle('RULES-PDF_AMBITION3A_LONG') + GetTexteLibelle('RULES-PDF_AMBITION3B_LONG');
    TabAmbition.Cells[2, 2]        := Personnage.AmbitionLong;
    TabAmbition.Cells[1, 3]        := GetTexteLibelle('RULES-PDF_PARTY1_PARTY') + ' - ' + GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT') + GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT');
    TabAmbition.Cells[1, 4]        := GetTexteLibelle('RULES-PDF_PARTY1_PARTY') + ' - ' + GetTexteLibelle('RULES-PDF_AMBITION3A_LONG') + GetTexteLibelle('RULES-PDF_AMBITION3B_LONG');
    // Dans un groupe, l'ambition de groupe vient du fichier de groupe (CONTEXT.md 2.100) et
    // plus jamais de Personnage.AmbitionGroupeCourt/Long (devenu lecture seule/non tenu a jour).
    if Personnage.GroupeId <> '' then
      begin
        GroupeComplet            := ChargeGroupeComplet(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId);
        TabAmbition.Cells[2, 3]  := GroupeComplet.AmbitionCourt;
        TabAmbition.Cells[2, 4]  := GroupeComplet.AmbitionLong;
      end
    else
      begin
        TabAmbition.Cells[2, 3] := Personnage.AmbitionGroupeCourt;
        TabAmbition.Cells[2, 4] := Personnage.AmbitionGroupeLong;
      end;
  end;

procedure TWinPersonnages.TabAmbitionDblClick(Sender: TObject);
  var
    GroupeComplet: StructureGroupe;
  begin
    if TabAmbition.Row < 1 then Exit;

    AmbitionCourtIn            := Personnage.AmbitionCourt;
    AmbitionLongIn             := Personnage.AmbitionLong;
    AmbitionGroupeLectureSeule := (Personnage.GroupeId <> '');
    if AmbitionGroupeLectureSeule then
      begin
        // Dans un groupe : l'ambition de groupe vient du fichier de groupe, lecture seule
        // ici - se saisit desormais dans WinGroupe. CONTEXT.md 2.100.
        GroupeComplet         := ChargeGroupeComplet(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId);
        AmbitionGroupeCourtIn := GroupeComplet.AmbitionCourt;
        AmbitionGroupeLongIn  := GroupeComplet.AmbitionLong;
      end
    else
      begin
        // Solo : comportement inchange, saisie ici comme avant.
        AmbitionGroupeCourtIn := Personnage.AmbitionGroupeCourt;
        AmbitionGroupeLongIn  := Personnage.AmbitionGroupeLong;
      end;

    WinAmbitionForm          := TWinAmbition.Create(Application);
    WinAmbitionForm.Position := poOwnerFormCenter;
    WinAmbitionForm.ShowModal;

    if not AmbitionValide then Exit;

    Personnage.AmbitionCourt := AmbitionCourtOut;
    Personnage.AmbitionLong  := AmbitionLongOut;
    if not AmbitionGroupeLectureSeule then
      begin
        Personnage.AmbitionGroupeCourt := AmbitionGroupeCourtOut;
        Personnage.AmbitionGroupeLong  := AmbitionGroupeLongOut;
      end;
    AfficheAmbition();
  end;

// Groupe (biens partages) : apercu affiche dans TabGroupe, onglet dedie de PageExperience,
// meme principe que TabAmbition - lecture seule, double-clic ouvre WinGroupe. CONTEXT.md
// 2.100, 27/09/2026.
procedure TWinPersonnages.AfficheGroupe();
  var
    Membres: TStringList;
  begin
    TabGroupe.RowCount    := 2;
    TabGroupe.Cells[1, 1] := GetTexteLibelle('RULES-LAB_301');
    TabGroupe.Cells[2, 1] := Personnage.GroupeId;
    if Personnage.GroupeId <> '' then
      begin
        Membres := ListeMembresGroupe(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId);
        try
          Membres.Sort;
          TabGroupe.RowCount    := 3;
          TabGroupe.Cells[1, 2] := GetTexteLibelle('RULES-LAB_303');
          TabGroupe.Cells[2, 2] := Membres.CommaText;
        finally
          Membres.Free;
        end;
      end;
  end;

procedure TWinPersonnages.TabGroupeDblClick(Sender: TObject);
  var
    Bien: StructurePersonnageEquipement;
  begin
    GroupeDirectoireIn := GetCurrentDir + ConstCheminPersonnage;
    GroupeIdIn         := Personnage.GroupeId;
    GroupeEquipementIn := Personnage.Equipement;

    WinGroupeForm          := TWinGroupe.Create(Application);
    WinGroupeForm.Position := poOwnerFormCenter;
    WinGroupeForm.ShowModal;

    // Biens repris (bouton "Reprendre", CONTEXT.md 2.100 etape 6) : rejoignent la grille,
    // IdInstance conserve pour que ses eventuels objets confies (locaux) continuent de le
    // retrouver. Independant de GroupeValide - une reprise n'est pas un changement de GroupeId.
    for Bien in GroupeBiensRepris do
      begin
        TabEquipement.RowCount                           := TabEquipement.RowCount + 1;
        TabEquipement.Cells[0, TabEquipement.RowCount-1]  := '+';
        TabEquipement.Cells[1, TabEquipement.RowCount-1]  := IntToStr(TabEquipement.RowCount);
        TabEquipement.Cells[2, TabEquipement.RowCount-1]  := Bien.CodeEquipement;
        TabEquipement.Cells[3, TabEquipement.RowCount-1]  := TypeEquipAN;
        TabEquipement.Cells[4, TabEquipement.RowCount-1]  := ChercheTrapping(Bien.CodeEquipement).Libelle;
        TabEquipement.Cells[7, TabEquipement.RowCount-1]  := Bien.QualiteEquipement;
        TabEquipement.Cells[9, TabEquipement.RowCount-1]  := IntToStr(Bien.Quantite);
        TabEquipement.Cells[10, TabEquipement.RowCount-1] := Bien.IdInstance;
      end;
    if Length(GroupeBiensRepris) > 0 then
      begin
        AdjustGridColumnsWidth(TabEquipement, 0, false, false);
        RafraichitPorteurs;
      end;

    if GroupeValide then
      begin
        Personnage.GroupeId := GroupeIdOut;
        AfficheGroupe();
      end;
  end;

procedure TWinPersonnages.ButtonArmureClick(Sender: TObject);
  Var
    PArmure:           StructureArmure;
    PArmureSimplifiee: StructureArmureSimplifiee;
  begin
    // ouvrir les métiers
    SelectWinQuickArmor := CheckBoxQuickArmor.Checked;
    SelectWinArmure     := ConstSelectionne;
    SelectWinLivre      := Personnage.LivresAcceptes;
    FenArmure           := TWinArmors.Create(Application);
    FenArmure.Position  := poOwnerFormCenter;
    FenArmure.ShowModal;

    if ChoixWinArmure <> '' then
      begin
        TabEquipement.RowCount  := TabEquipement.RowCount + 1;
        TabEquipement.Cells[0, TabEquipement.RowCount-1]:= '+';
        TabEquipement.Cells[1, TabEquipement.RowCount-1]:= IntToStr(TabEquipement.RowCount);
        if (CheckBoxQuickArmor.Checked = true) then
          begin
            PArmureSimplifiee := ChercheArmureSimplifiee(ChoixWinArmure);
            TabEquipement.Cells[2, TabEquipement.RowCount-1]:= PArmureSimplifiee.CodeArmure;
            TabEquipement.Cells[3, TabEquipement.RowCount-1]:= TypeEquipArS;
            TabEquipement.Cells[4, TabEquipement.RowCount-1]:= PArmureSimplifiee.Libelle;
          end
        else
          begin
            pArmure           := ChercheArmure(ChoixWinArmure);
            TabEquipement.Cells[2, TabEquipement.RowCount-1]:= PArmure.CodeArmure;
            TabEquipement.Cells[3, TabEquipement.RowCount-1]:= TypeEquipAr;
            TabEquipement.Cells[4, TabEquipement.RowCount-1]:= PArmure.Libelle;
            // Fabrication D'ORIGINE de l'armure (gromril, Ithilmar/Dragon...) : posee
            // automatiquement, comme au livre. CONTEXT.md 2.29.
            TabEquipement.Cells[7, TabEquipement.RowCount-1]:= PArmure.Fabrication;
          end;
        AdjustGridColumnsWidth(TabEquipement, 0, false, false);
        RafraichitTabEquipementAffichage();
      end;
    SelectWinArmure := '';
    SelectWinLivre  := '';
    ChoixWinArmure  := '';
end;

procedure TWinPersonnages.EditAgeKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['0'..'9', #8, #9]) then Key := #0;
end;

procedure TWinPersonnages.ButtonCorruptionMutationClick(Sender: TObject);
  var
    ResilienceTotale:   Integer;
    Lost:               Integer;
    PersonnageMutation: StructurePersonnageMutation;
  begin
    ResilienceTotale := StrToIntDef(TabAttribut.Cells[ColAttResil, LigAttTotal], 0);

    MutationCodeRace             := Personnage.Race;
    MutationResilienceDisponible := (ResilienceTotale > 0);

    WinMutations           := TWinMutations.Create(Application);
    WinMutations.Position  := poOwnerFormCenter;
    WinMutations.ShowModal;

    Lost := CalculCorruptionLost();

    if MutationChoix = 'RESILIENCE' then
      begin
        // Une ligne -1 dans le registre de Résilience : RegistreResilienceChange (AppliqueRegistre)
        // décrémente Personnage.CreationAttribut (ATTR_Resil, peut devenir négatif, la base de race est
        // intouchable), met à jour la ligne "points de création" de TabAttribut et recalcule les totaux.
        // Sans risque de passer sous 0 au total : le bouton n'est actif que si ResilienceTotale > 0
        // (conception validée avec Nono le 16/08/2026, CONTEXT.md §2.7). Même voie que le registre
        // (08/10/2026) : la dépense apparaît ainsi dans l'onglet Destin / Résilience.
        PanelResilience.AjouteLigne(-1, GetTexteLibelle('RULES-LAB_169'));

        StringGridCorruption.RowCount                                   := StringGridCorruption.RowCount + 1;
        StringGridCorruption.Cells[1, StringGridCorruption.RowCount - 1] := IntToStr(-Lost);
        StringGridCorruption.Cells[2, StringGridCorruption.RowCount - 1] := GetTexteLibelle('RULES-LAB_169');
      end
    else if MutationChoix = 'MUTATION' then
      begin
        // Ligne compensatoire qui remet l'historique à 0. La mutation elle-même n'est PAS
        // mémorisée ici : Personnage.Corruption garde son rôle d'origine (ledger de points), la
        // mutation est stockée à part dans Personnage.Mutations (référence Code stable du
        // catalogue, pas le texte résolu ni la plage de jet - conception révisée avec Nono les
        // 16 et 17/08/2026, CONTEXT.md §2.7, pour permettre de retrouver/retirer une mutation
        // précise plus tard et rester valide si un futur livre renumérote sa table de chance).
        StringGridCorruption.RowCount                                   := StringGridCorruption.RowCount + 1;
        StringGridCorruption.Cells[1, StringGridCorruption.RowCount - 1] := IntToStr(-Lost);
        StringGridCorruption.Cells[2, StringGridCorruption.RowCount - 1] := GetTexteLibelle('RULES-LAB_170');

        PersonnageMutation.Code := MutationCode;
        Personnage.Mutations    += [PersonnageMutation];
        AfficheMutations();
      end;

    CalculCorruptionLeft();

    MutationChoix := '';
    MutationCode  := '';
    MutationLibelle := '';
    MutationEffet   := '';
  end;

procedure TWinPersonnages.ButtonRaceSelectionnerClick(Sender: TObject);
  Var
    PMetierActuel: StructureMetier;
    PMetierNv:     StructureMetier;
    ChangeClasse:  Boolean;
  begin
    pMetierActuel       := ChercheMetier(MetierEnCours);
    // ouvrir les métiers
    ButtonRaceSelectionner.Caption := GetTexteLibelle('RULES-LAB_004');
    NvMetierChoisi      := '';
    SelectWinMetierRace := RaceEnCours;
    SelectWinLivre      := Personnage.LivresAcceptes;
    FenMetier           := TWinMetiers.Create(Application);
    FenMetier.Position  := poOwnerFormCenter;
    FenMetier.ShowModal;

    // CARRIERE AVANCEE : un metier dont le premier <Level> declare est superieur a 1 ne
    // s'entame pas. On y arrive en montant de niveau depuis sa carriere parente, jamais par
    // un changement de carriere - c'est le cas du Storm Weaver, du Loremaster of Hoeth et du
    // Smith-priest of Vaul, qui n'existent qu'a partir du niveau 3.
    //
    // Le refus laisse NvMetierChoisi vide et le libelle du bouton inchange : on retombe donc
    // exactement dans l'etat "l'utilisateur a annule", qui est deja gere plus bas.
    //
    // Le test est ici et pas dans WinMetier, qui est aussi la fenetre de consultation : ces
    // carrieres doivent rester VISIBLES et consultables, seule leur selection est refusee.
    if (ChoixWinMetierRace <> '') and (ChercheMinMetierNiveau(ChoixWinMetierRace) > 1) then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_057') + IntToStr(ChercheMinMetierNiveau(ChoixWinMetierRace)));
        ChoixWinMetierRace := '';
      end;

    if ChoixWinMetierRace <> '' then
      begin
        NvMetierChoisi := ChoixWinMetierRAce;
        pMetierNv      := ChercheMEtier(ChoixWinMetierRAce);
        ChangeClasse   := (PMetierNV.LibelleGroupe <> PMetierActuel.LibelleGroupe);
        CalculXpNecessaire(ChangeClasse);
        ButtonRaceSelectionner.Caption := PMetierNv.Libelle;
      end;

    SelectWinMetierRace:= '';
    SelectWinLivre     := '';
    ChoixWinMetierRace := '';
    ChargerMetierEquipement(NvMetierChoisi, 1);
    TabEquipementAffiche();
  end;

// Valeur d'un champ de tarification : soit un nombre ecrit tel quel, soit un bonus
// d'attribut note (BATTR_x) - la MEME notation que <Max> des talents, et la decoupe est
// recopiee de TabAugmentationTalentSetEditText ligne ~3480 pour qu'elles ne divergent pas.
// Le 'B' est mange par le delimiteur '(B', ce qui laisse 'ATTR_Int', a comparer sans le
// prefixe de livre (CodeSansLivre) a la ligne de codes de TabAttribut, qui le porte depuis
// §2.49 ("RULES-ATTR_Int").
//
// Defaut est rendu quand l'expression est vide OU quand l'attribut cite n'existe pas : un
// libelle mal orthographie dans les donnees ne doit pas faire planter une fiche.
function TWinPersonnages.ValeurTarifSort(Expression: String; Defaut: Integer): Integer;
  var
    Carac: String;
    Ind:   Integer;
  begin
    Result := Defaut;
    if Expression = '' then
      Exit;
    if TryStrToInt(Expression, Result) then
      Exit;
    Carac  := StringReplace(ExtractStringAfter(Expression, '(B'), ')', '', [rfReplaceAll]);
    Result := Defaut;
    For Ind := 1 to TabAttribut.ColCount - 1 do
      if CodeSansLivre(TabAttribut.Cells[Ind, LigAttCode]) = Carac then
        begin
          Result := Trunc(StrToIntDef(TabAttribut.Cells[Ind, LigAttTotal], 0) / 10);
          Exit;
        end;
  end;

// Talent porteur du tarif d'un sort : le PREMIER de ceux que le sort cite. Prendre le
// premier suffit parce qu'un sort ne cite jamais que des specialisations d'UNE seule
// famille - verifie sur les 719 sorts des seize livres charges le 02/09/2026 - et que
// toutes les specialisations d'une famille heritent du meme tarif.
//
// Une structure vide (CodeTalent = '') est la reponse normale pour une ligne de
// TabEquipement qui n'est pas un sort : une arme, une armure. C'est ainsi qu'elles sont
// ecartees du comptage, sans avoir a les reconnaitre.
function TWinPersonnages.TalentSort(CodeSort: String): StructureTalent;
  var
    PSort:      StructureSort;
    Talents:    String;
    Liste:      TStringList;
    Ind:        Integer;
  begin
    Result := Default(StructureTalent);
    if CodeSort = '' then
      Exit;
    PSort := ChercheSort(CodeSort);
    if PSort.CodeSort = '' then
      Exit;
    // TalentsDuSort et non PSort.ListeTalent : la relation talent/sort a une seconde
    // source depuis le 03/09/2026, le bloc DATA_SPELL_TALENT. CONTEXT.md 2.39.
    Talents := TalentsDuSort(PSort);
    if Talents = '' then
      Exit;

    Liste := TStringList.Create;
    try
      // meme decoupe que SortTalentAccessible : un sort peut citer plusieurs talents, et le
      // OU entre eux est la seule relation que le modele connaisse.
      ExtractStrings([',', ' '], [], PChar(Talents), Liste);
      For Ind := 0 to Liste.Count - 1 do
        begin
          Result := ChercheTalent(Liste[Ind]);
          if Result.CodeTalent <> '' then
            Exit;
        end;
      Result := Default(StructureTalent);
    finally
      Liste.Free;
    end;
  end;

// Groupe de comptage d'un talent. C'est ce qui remplace l'ancien test sur TypSpell : deux
// sorts sont dans le meme groupe quand leurs talents remontent a la meme entree generique,
// ce qui fait que l'arcanique et le domaine comptent ensemble sans qu'aucune donnee ne le
// declare - ils citent le meme talent. XpGroupe ne sert qu'a forcer un partage entre deux
// familles distinctes, cas qu'aucun livre ne presente aujourd'hui.
//
// Le groupe est bati sur le code du talent TROUVE, pas sur la chaine ecrite dans le sort :
// les deux peuvent differer du prefixe de livre, et deux ecritures du meme talent auraient
// alors fabrique deux groupes distincts - donc des sorts moins chers, en silence.
function TWinPersonnages.PoolTalent(PTalent: StructureTalent): String;
  begin
    if PTalent.CodeTalent = '' then
      Result := ''
    else if PTalent.XpGroupe <> '' then
      Result := PTalent.XpGroupe
    else
      Result := CodeTalentGenerique(PTalent);
  end;

// COUT D'UN SORT, LU DANS LE TALENT QUI L'OUVRE (chantier du 02/09/2026, CONTEXT.md 2.31).
//
//    cout = XpMultiplier x max( XpFloor , ceil( n / XpDivisor ) )
//
// n = sorts DEJA connus dans le meme groupe. C'est l'entree des tables du livre ("No. of
// Spells Currently Known") ; le sort en cours est deja dans la grille quand on arrive ici,
// il est donc exclu du comptage par son code.
//
// CE QUI DISPARAIT : la cascade de tests sur TypSpell. Elle traitait comme une enumeration
// fermee un champ que les supplements remplissent librement - les 17 rituels de Winds of
// Magic, arrives avec une valeur inconnue, tombaient a cout nul sans que rien ne le dise.
// Un talent sans tarification declaree coute maintenant 0 parce que c'est ECRIT dans les
// donnees (les benedictions), pas parce que le code ne sait pas quoi en faire.
function TWinPersonnages.XpSortCout(CodeSort: String): String;
  Var
    PSort:    StructureSort;
    PTalent:  StructureTalent;
    Pool:     String;
    CoutXp:   Integer = 0;
    NbConnus: Integer = 0;
    Offerts:  Integer = 0;
    Diviseur: Integer = 0;
    Palier:   Integer = 0;
    Ind:      Integer = 0;
  begin
    // Cout fixe porte par le sort lui-meme (<XpFixed>, rituels de Winds of Magic : le livre
    // imprime un "Learning XP" propre a chacun). Il court-circuite la formule du talent.
    PSort := ChercheSort(CodeSort);
    if (PSort.CodeSort <> '') and (PSort.XpFixe <> '') then
      begin
        Result := IntToStr(CalculOptionXpDiv25(StrToIntDef(PSort.XpFixe, 0)));
        Exit;
      end;

    PTalent := TalentSort(CodeSort);
    Pool    := PoolTalent(PTalent);
    if Pool <> '' then
      begin
        // un sort a cout fixe ne compte pas dans le groupe : il ne rencherit pas les autres
        For Ind := 1 to TabEquipement.RowCount - 1 do
          if (TabEquipement.Cells[2, Ind] <> CodeSort) and
             (ChercheSort(TabEquipement.Cells[2, Ind]).XpFixe = '') and
             (PoolTalent(TalentSort(TabEquipement.Cells[2, Ind])) = Pool) then
            Inc(NbConnus);

        // PLANCHER A 1 SUR LES BONUS D'ATTRIBUT : un personnage dont l'attribut est
        // inferieur a 10 a un bonus de ZERO. L'ancien code le forcait deja a 1, sans quoi
        // la division levait une exception ; ce plancher accordait au passage un sort
        // offert au lieu d'aucun en Magie Mineure. Les deux effets sont conserves.
        if PTalent.XpOfferts <> '' then
          begin
            Offerts := ValeurTarifSort(PTalent.XpOfferts, 0);
            if Offerts < 1 then
              Offerts := 1;
          end;

        if NbConnus < Offerts then
          // sorts accordes par le talent lui-meme : "you manifest, and permanently
          // memorise, a number of spells equal to your Willpower Bonus"
          CoutXp := 0
        else
          begin
            // DIVISEUR ABSENT ET DIVISEUR NUL NE SONT PAS LA MEME CHOSE. Absent = le tarif
            // ne progresse pas, c'est un forfait (Magie du Chaos, 100 XP a chaque fois).
            // Nul = un bonus d'attribut qui vaut zero, et la c'est le plancher a 1 qui
            // s'applique, comme avant.
            if PTalent.XpDiviseur = '' then
              Palier := 1
            else
              begin
                Diviseur := ValeurTarifSort(PTalent.XpDiviseur, 1);
                if Diviseur < 1 then
                  Diviseur := 1;
                Palier := Ceil(NbConnus / Diviseur);
              end;
            CoutXp := PTalent.XpMultiplicateur * Max(PTalent.XpPlancher, Palier);
          end;
      end;

    // montant d'XP
    Result:= IntToStr(CalculOptionXpDiv25(CoutXp));
  end;

function TWinPersonnages.ChoixNonFait(): Boolean;
  var
    Ind: Integer;
    Res: Boolean = false;
  begin
    for Ind := 1 to TabMetierEquipement.Rowcount - 1 do
      // un choix non resolu ne bloque que si la ligne est cochee (equipement de niveau facultatif)
      if (TabMetierEquipement.Cells[2, Ind] = ConstArbreAuChoix) and (TabMetierEquipement.Cells[0, Ind] = CaseCochee) then
        Res := true;
    Result := Res;
  end;

procedure TWinPersonnages.ButtonSortClick(Sender: TObject);
  Var
    PSort:        StructureSort;
    PTalent:      StructureTalent;
    Ind:          Integer;
    ListeTalent:  String;
  begin
    // Quels talents ouvrent le catalogue de sorts : lu dans les DONNEES (balise <Magic>), plus
    // en dur. Avant le 23/08/2026, les quatre talents concernes etaient nommes par les constantes
    // TalentSortXxx et reconnus sur leurs 5 PREMIERS CARACTERES ; ajouter un talent magique
    // demandait donc de recompiler. CONTEXT.md 2.18.
    //
    // Les deux passes ne sont pas symetriques et c'est voulu : ConstMagieExclusive ecarte tout le
    // reste (avoir un Domaine arcanique interdit d'apprendre Miracles et Magie Mineure), alors que
    // ConstMagieCumulable s'additionne. C'est exactement l'ancien comportement, ecrit en donnees.
    //
    // ChercheTalent reporte <Magic> de l'entree generique (T0088_*) sur la specialisation
    // (T0088_FEU), qui ne porte qu'une Description - voir le repli dans chargetalent.pas.
    ListeTalent := '';
    For Ind := 1 to TabTalent.RowCount-1 do
      begin
        PTalent := ChercheTalent(TabTalent.Cells[ColTalCode, ind]);
        if PTalent.Magie = ConstMagieExclusive then
          ListeTalent := ListeTalent+' '+TabTalent.Cells[ColTalCode, ind];
      end;

    // si aucun domainge, on peut ajouter les autres
    if ListeTalent = '' then
      For Ind := 1 to TabTalent.RowCount-1 do
        begin
          PTalent := ChercheTalent(TabTalent.Cells[ColTalCode, ind]);
          if PTalent.Magie = ConstMagieCumulable then
            ListeTalent := ListeTalent+' '+TabTalent.Cells[ColTalCode, ind];
        end;

    if ListeTalent = '' then
      showMessage(GetTexteLibelle('RULES-MESS_037'))
    else
      begin
      SelectWinSort     := ListeTalent;
      SelectWinLivre    := Personnage.LivresAcceptes;
      FenSort           := TWinSpells.Create(Application);
      FenSort.Position  := poOwnerFormCenter;
      FenSort.ShowModal;
      if ChoixWinSort <> '' then
        begin
          pSort := ChercheSort(ChoixWinSort);
          if RechercherDansColonne(TabEquipement,PSort.CodeSort,2) = -1 then
            begin
              TabEquipement.RowCount                          := TabEquipement.RowCount + 1;
              TabEquipement.Cells[0, TabEquipement.RowCount-1]:= '+';
              TabEquipement.Cells[1, TabEquipement.RowCount-1]:= IntToStr(TabEquipement.RowCount);
              TabEquipement.Cells[2, TabEquipement.RowCount-1]:= PSort.CodeSort;
              TabEquipement.Cells[3, TabEquipement.RowCount-1]:= PSort.TypeSort;
              TabEquipement.Cells[4, TabEquipement.RowCount-1]:= PSort.Libelle;
              TabEquipement.Cells[5, TabEquipement.RowCount-1]:= XpSortCout(PSort.CodeSort);
              AdjustGridColumnsWidth(TabEquipement, 0, false, false);
              RafraichitTabEquipementAffichage();
              CalculTableExperience();
            end
          else
            ShowMEssage(GetTexteLibelle('RULES-MESS_036'));
        end;
      end;
    SelectWinSort  := '';
    SelectWinLivre := '';
    ChoixWinSort   := '';
end;

procedure TWinPersonnages.CalculXpGlobal(Mode25: boolean);
  // A l'activation de l'option, EditTotalXp25 n'avait jamais ete alimente (reste a "0"
  // tant que Nono ne tape pas dedans a la main) : XmlSauvegarde lit alors un Total de 0,
  // ecrasant Xp/CurrentXp du personnage a l'enregistrement suivant. Meme conversion que
  // EditTotalXpKeyUp (Trunc/25), declenchee ici a la coche plutot qu'a la frappe.
  // La ligne "Total" de tabExperience (LigXpTotal) n'est sinon rafraichie qu'au chargement
  // du personnage (l.3582) : sans la reposer ici, elle reste affichee en unites brutes
  // (2675) alors que Spent/Remaining basculent deja en unites divisees (107) - constate
  // par Nono a l'ecran juste apres la coche.
begin
  if Mode25 then
    begin
      EditTotalXp25.Text := IntToStr(Trunc(StrToIntDef(EditTotalXp.Text,0) / 25));
      tabExperience.Cells[ColXpDonnee, LigXpTotal] := EditTotalXp25.Text;
    end
  else
    tabExperience.Cells[ColXpDonnee, LigXpTotal] := EditTotalXp.Text;
  CalculTableExperience();
end;

procedure TWinPersonnages.CheckBoxXpDiv25Change(Sender: TObject);
begin
  CalculXpGlobal(CheckBoxXpDiv25.Checked);
end;

// Cacher le tout implique cacher les montants : la seconde case est cochee et verrouillee.
procedure TWinPersonnages.CheckBoxStylePdfClick(Sender: TObject);
begin
  CheckBoxCouleurPdf.Enabled  := CheckBoxStylePdf.Checked;
  CheckBoxEconomiePdf.Enabled := CheckBoxStylePdf.Checked;
end;

procedure TWinPersonnages.CheckBoxSansAsterisqueClick(Sender: TObject);
begin
  if CheckBoxSansAsterisque.Checked then
    CheckBoxSansMontant.Checked := True;
  CheckBoxSansMontant.Enabled := not CheckBoxSansAsterisque.Checked;
end;

procedure TWinPersonnages.CheckBoxXpDiv25Click(Sender: TObject);
begin
  EditTotalXp25.Enabled := CheckBoxXpDiv25.checked;
  EditTotalXp.Enabled   := not CheckBoxXpDiv25.checked;
end;

procedure TWinPersonnages.CalculXpNecessaire(ChangementClasse: Boolean);
  Var
    XpNeed:   Integer=0;
  Begin
    if RadioButtonSuivant.checked or RadioButtonChanger.checked then
      begin
        if RadioButtonSuivant.checked then
          XpNeed := ConstXpNouveauNiveau
        else if ((TabAvancement.Cells[2,1] = CouleurOk) and (TabAvancement.Cells[2,2] = CouleurOk) and (TabAvancement.Cells[2,3] = CouleurOk)) then
          XpNeed := ConstXpChangerMetier
        else
          XpNeed := ConstXpChangerMetierIncomplet;
        if ChangementClasse then
          XpNeed := XpNeed + ConstXpChangerClasse;
        EditNeedRealXp.MinValue  := 0;
        XpNeed:= CalculOptionXpDiv25(XpNeed);
        EditNeedRealXp.MaxValue  := XpNeed;
      end;

    EditNeedTheoXp.value     := XpNeed;
    EditNeedRealXp.value     := XpNeed;
    EditNeedTheoXp.Visible   := (XpNeed<>0);
    EditNeedRealXp.Visible   := (XpNeed<>0);
    LabelNeedTheoXp.Visible  := (XpNeed<>0);
    LabelNeedRealXp.Visible  := (XpNeed<>0);
  end;

// Codes des carrieres accessibles en montant D'UN niveau depuis la carriere en cours.
//   - entree 0 : TOUJOURS la carriere actuelle. Bifurquer reste un choix, pas une
//     obligation : un Mage qui monte doit pouvoir rester Mage.
//   - suivantes : les carrieres avancees qui declarent la carriere en cours comme parente
//     ET qui commencent exactement au niveau vise, ET que l'ethnie du personnage peut
//     prendre. Le filtre par ethnie regle tout seul le cas du Smith-priest of Vaul, que le
//     livre ouvre aussi aux Elfes Sylvains.
//
// Carriere dans laquelle se poursuit la progression au niveau suivant. Ordinairement la
// carriere en cours. Une variante qui s'arrete avant ce niveau (Max < niveau vise, ex.
// Guild Engineer, seul niveau 2) rend la main a son PREMIER parent declare : le livre laisse
// alors revenir a la carriere d'origine ou prendre une autre variante. Max = 0 (carriere
// inconnue) ou pas de parent : la carriere en cours, comme avant.
Function TWinPersonnages.CarriereDeSuite(): String;
  var
    Liste:      TStringList;
    NiveauVise: Integer;
    Max:        Integer;
  begin
    Result     := MetierEnCours;
    NiveauVise := StrToIntDef(MetierNvEnCours, 0) + 1;
    Max        := ChercheMaxMetierNiveau(MetierEnCours);
    if (Max = 0) or (Max >= NiveauVise) then
      Exit;
    if Trim(ChercheMetier(MetierEnCours).MetierParent) = '' then
      Exit;
    Liste := TStringList.Create;
    try
      ExtractStrings([SeparateurMulti], [], PChar(ChercheMetier(MetierEnCours).MetierParent), Liste);
      if Liste.Count > 0 then
        Result := Trim(Liste[0]);
    finally
      Liste.Free;
    end;
  end;

// Coche dans TabNiveau la ligne du niveau en cours. Les lignes sont SEQUENTIELLES (voir
// AfficheImageMetier : niveau - niveau minimum du metier + 1), pas indexees par le numero
// de niveau : indexer par le numero plantait sur une variante a un seul niveau (Guild
// Engineer, niveau 2, grille a une ligne) et cochait la mauvaise ligne d'une carriere
// avancee des le niveau 4 (Smith-priest : lignes 1 a 3 pour les niveaux 3 a 5).
Procedure TWinPersonnages.MarqueNiveauEnCours();
  var
    Ligne: Integer;
    Ind:   Integer;
  begin
    for Ind := 1 to TabNiveau.RowCount - 1 do
      TabNiveau.Cells[0, Ind] := '';
    Ligne := StrToIntDef(MetierNvEnCours, 0) - Max(ChercheMinMetierNiveau(MetierEnCours), 1) + 1;
    if (Ligne >= 1) and (Ligne < TabNiveau.RowCount) then
      TabNiveau.Cells[0, Ligne] := ConstSelectionne;
  end;

// Une seule entree = pas de bifurcation. La combo reste alors cachee et le comportement
// d'origine s'applique mot pour mot.
//
// APPELEE A DEUX ENDROITS - remplissage de la combo et validation - et c'est volontaire :
// l'ordre etant deterministe, l'indice choisi par l'utilisateur designe le meme metier aux
// deux appels. Aucun etat a conserver entre les deux, donc aucun risque de desynchronisation
// si la liste des livres change entre-temps.
Procedure TWinPersonnages.ListeNvMetier(Codes: TStringList);
  var
    PMetier:    StructureMetier;
    NiveauVise: Integer;
    Base:       String;

  // Le metier est-il ouvert a l'ethnie du personnage ? Un 'X' compte : il veut dire
  // "eligible hors tirage", ce qui est exactement le cas d'une carriere avancee. Seul
  // SeparateurChance ('-'), qui signifie explicitement indisponible, exclut.
  Function EthnieAutorise(CodeMetier: String): Boolean;
    var
      PRaceMetier: StructureRaceMetier;
    begin
      Result := false;
      for PRaceMetier in ListRaceMetier do
        if CompareRechercheValeur(PRaceMetier.CodeRace, RaceEnCours) and
           CompareRechercheValeur(PRaceMetier.CodeMetier, CodeMetier) and
           (PRaceMetier.Chance <> SeparateurChance) then
          begin
            Result := true;
            break;
          end;
    end;

  begin
    Codes.Clear;
    if Trim(MetierEnCours) = '' then
      Exit;
    NiveauVise := StrToIntDef(MetierNvEnCours, 0) + 1;
    if NiveauVise < 2 then
      Exit;
    // Base = la carriere en cours, ou son parent si elle s'arrete avant le niveau vise
    // (variante a niveau unique : Guild Engineer, Sky Pilot...).
    Base := CarriereDeSuite();
    Codes.Add(Base);
    for PMetier in ListMetier do
      if EstMetierEnfantDe(PMetier.CodeMetier, Base) and
         (ChercheMinMetierNiveau(PMetier.CodeMetier) = NiveauVise) and
         EthnieAutorise(PMetier.CodeMetier) then
        Codes.Add(PMetier.CodeMetier);
  end;

// Remplit la combo, ou la laisse cachee s'il n'y a rien a demander.
// Elle sort d'ici TOUJOURS sur ItemIndex = -1 : celui qui la voit apparaitre doit poser un
// choix explicite, la validation le lui refusera sinon (MESS_058).
Procedure TWinPersonnages.ChargeComboNvMetier();
  var
    Codes: TStringList;
    Ind:   Integer;
  begin
    ComboBoxNvMetier.Items.Clear;
    ComboBoxNvMetier.ItemIndex := -1;
    ComboBoxNvMetier.Visible   := false;
    if not RadioButtonSuivant.Checked then
      Exit;
    Codes := TStringList.Create;
    try
      ListeNvMetier(Codes);
      if Codes.Count < 2 then
        Exit;
      for Ind := 0 to Codes.Count - 1 do
        ComboBoxNvMetier.Items.Add(ChercheMetier(Codes[Ind]).Libelle);
      // Repose apres le remplissage : ajouter des items peut repositionner l'index.
      ComboBoxNvMetier.ItemIndex := -1;
      ComboBoxNvMetier.Visible   := true;
      ComboBoxNvMetier.BringToFront;
    finally
      Codes.Free;
    end;
  end;

// Le corps d'origine chargeait l'equipement de NvMetierChoisi AU NIVEAU 1 : il avait ete
// ecrit pour le changement de carriere. Ici on monte d'un niveau dans une carriere qui
// commence justement plus haut - c'est le niveau VISE qu'il faut charger, pas le 1.
procedure TWinPersonnages.ComboBoxNvMetierChange(Sender: TObject);
  var
    Codes: TStringList;
  begin
    NvMetierChoisi := '';
    if ComboBoxNvMetier.ItemIndex < 0 then
      Exit;
    Codes := TStringList.Create;
    try
      ListeNvMetier(Codes);
      if ComboBoxNvMetier.ItemIndex < Codes.Count then
        begin
          NvMetierChoisi := Codes[ComboBoxNvMetier.ItemIndex];
          ChargerMetierEquipement(NvMetierChoisi, StrToIntDef(MetierNvEnCours, 0) + 1);
          TabEquipementAffiche();
        end;
    finally
      Codes.Free;
    end;
  end;

procedure TWinPersonnages.EditTotalXp25KeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['0'..'9', #8, #9]) then Key := #0;
end;

procedure TWinPersonnages.EditTotalXp25KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    ValInt: Integer = 0 ;
  begin
    ValInt := StrToIntDef(EditTotalXp25.Text,0) * 25;
    EditTotalXp.Text := IntToStr(ValInt);
  end;

procedure TWinPersonnages.EditTotalXpKeyPress(Sender: TObject; var Key: char);
begin
    if not (Key in ['0'..'9', #8, #9]) then Key := #0;
end;

procedure TWinPersonnages.EditTotalXpKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    ValInt: Integer = 0 ;
  begin
    ValInt := Trunc(StrToIntDef(EditTotalXp.Text,0) / 25);
    EditTotalXp25.Text := IntToStr(ValInt);
  end;

Procedure TWinPersonnages.SortAffiche();
  var
    PSort:   StructureSort;
    PTalent: StructureTalent;
    Tal:     String;
    Ind:     Integer;
  begin
    EffaceDonnee(TabSort,1);
    for ind := 1 to TabAugmentationTalent.RowCount - 1 do
      if StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalNouveau, Ind], 0) > StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalActuel, Ind], 0) then
        begin
          // Prendre la SPECIALISATION choisie quand il y en a une, pas le code generique.
          // Pour une Benediction, le dieu EST la specialisation : les sorts citent
          // RULES-T0012_SIGMAR, jamais RULES-T0012_*, donc le code generique ne matchait
          // aucun sort et aucune benediction n'etait jamais accordee. Meme lecture que
          // MajTables ligne ~4226. Trouve par Nono le 22/08/2026 sur un pretre guerrier
          // de Sigmar. CONTEXT.md 2.18.
          if TabAugmentationTalent.Cells[ColAugmTalSpeSel, Ind] <> '' then
            Tal := TabAugmentationTalent.Cells[ColAugmTalSpeSel, Ind]
          else
            Tal := TabAugmentationTalent.Cells[ColAugmTalCode, Ind];
          // Comment les sorts arrivent a l'achat du talent : lu dans les DONNEES (<SpellMode>),
          // plus en dur. AUTO = les sorts qui citent ce talent sont accordes d'office (une
          // Benediction depend du dieu et ne s'achete pas), CHOICE = une ligne "a choisir" est
          // posee (un Miracle se choisit). Ancien equivalent : copy(CodeValeur,1,5) compare a
          // TalentSortBenediction / TalentSortMiracle. CONTEXT.md 2.18.
          PTalent := ChercheTalent(Tal);
          if PTalent.ModeSort = ConstModeSortAuto then
            begin
              For Psort in ListSort do
                // TalentsDuSort : voir CONTEXT.md 2.39, la relation a une seconde source.
                if Pos(Tal, TalentsDuSort(PSort)) > 0 then
                  Begin
                    TabSort.RowCount                       := TabSort.RowCount + 1;
                    TabSort.Cells[1, TabSort.RowCount-1]   := PSort.CodeSort;
                    TabSort.Cells[2, TabSort.RowCount-1]   := PSort.Libelle;
                    TabSort.Cells[3, TabSort.RowCount-1]   := Tal;
                  end;
            end
          else if PTalent.ModeSort = ConstModeSortChoix then
            begin
              // Choix du sort precis (un Miracle se choisit, contrairement a une
              // Benediction qui est automatique) : pose directement dans la ligne du
              // talent, meme table et meme principe que la colonne Specialisation juste a
              // cote (resolu par double-clic, voir TabAugmentationTalentDblClick). Ne pas
              // ecraser un choix deja fait si SortAffiche est rappelee entre-temps (ex.
              // specialisation d'une AUTRE ligne resolue juste apres).
              if TabAugmentationTalent.Cells[ColAugmTalSortSel, Ind] = '' then
                TabAugmentationTalent.Cells[ColAugmTalSort, Ind] := ConstArbreAuChoix;
              TabAugmentationTalent.ColWidths[ColAugmTalSort] := 200;
            end
        end;
    TabSort.visible := (TabSort.RowCount > 1);
    AdjustGridColumnsWidth(TabSort, PageExperience.Height, false, false);
    TabSort.Top    := TabAugmentationTalent.Top + TabAugmentationTalent.Height + 10;
  end;

Procedure TWinPersonnages.AttributInit();
  Begin
    tabAttribut.Cells[ColAttCC, LigAttCode]      := ConstCaracCC;
    tabAttribut.Cells[ColAttCT, LigAttCode]      := ConstCaracCT;
    tabAttribut.Cells[ColAttF, LigAttCode]       := ConstCaracF;
    tabAttribut.Cells[ColAttE, LigAttCode]       := ConstCaracE;
    tabAttribut.Cells[ColAttI, LigAttCode]       := ConstCaracI;
    tabAttribut.Cells[ColAttAgi, LigAttCode]     := ConstCaracAg;
    tabAttribut.Cells[ColAttDex, LigAttCode]     := ConstCaracDex;
    tabAttribut.Cells[ColAttInt, LigAttCode]     := ConstCaracInt;
    tabAttribut.Cells[ColAttFM, LigAttCode]      := ConstCaracFM;
    tabAttribut.Cells[ColAttSoc, LigAttCode]     := ConstCaracSoc;
    tabAttribut.Cells[ColAttDestin, LigAttCode]  := ConstCaracDestin;
    tabAttribut.Cells[ColAttResil, LigAttCode]   := ConstCaracResil;
    tabAttribut.Cells[ColAttBlessure, LigAttCode]:= ConstCaracBlessure;
  end;

procedure TWinPersonnages.InitialisationImages();
  var
    Bmp:      TBGRABitmap;
begin
  // charges les images des niveaux
  ChargeImagesNiveau();

  // Logo
  if FileExists(CheminImage(GetCurrentDir+ConstCheminLogo1)) then
      ImageWar.Picture.LoadFromFile(CheminImage(GetCurrentDir+ConstCheminLogo1));

  if FileExists(CheminImage(GetCurrentDir+ConstCheminSheetTitle)) then
     begin
       Bmp := TBGRABitmap.Create(CheminImage(GetCurrentDir+ConstCheminSheetTitle));
       ImageSheetTitle.Picture.Bitmap.Assign(Bmp);
       Bmp.Free;
       ImageSheetTitle.Transparent := True;
       ImageSheetTitle.SendToBack;
     end;
  if FileExists(CheminImage(GetCurrentDir+ConstCheminSheetBack)) then
     begin
       Bmp := TBGRABitmap.Create(CheminImage(GetCurrentDir+ConstCheminSheetBack));
       ImageBackRace.Picture.Bitmap.Assign(Bmp);
       ImageBackMetier.Picture.Bitmap.Assign(Bmp);
       Bmp.Free;
       ImageBackRace.Transparent := True;
       ImageBackRace.SendToBack;
       ImageBackMetier.Transparent := True;
       ImageBackMetier.SendToBack;
     end;

    if FileExists(CheminImage(GetCurrentDir+ConstCheminSheetPage)) then
       begin
         Bmp := TBGRABitmap.Create(CheminImage(GetCurrentDir+ConstCheminSheetPage));
         ImageSheetPage.Picture.Bitmap.Assign(Bmp);
         Bmp.Free;
         ImageSheetPage.Transparent := True;
         ImageSheetPage.SendToBack;
       end;

    if FileExists(CheminImage(GetCurrentDir+ConstCheminXp)) then
       begin
         Bmp := TBGRABitmap.Create(CheminImage(GetCurrentDir+ConstCheminXp));
         ImageSheetXp.Picture.Bitmap.Assign(Bmp);
         Bmp.Free;
         ImageSheetXp.Transparent := True;
         ImageSheetXp.SendToBack;
       end;
end;

procedure TWinPersonnages.InitialisationTablesPersonnage();
  var
    I:        Integer;
begin
  // Mise en forme du tableau des attributs
  TabAttribut.Clear;
  TabAttribut.Options          := TabAttribut.Options + [goEditing, goAlwaysShowEditor];
  TabAttribut.ColCount         := 1;
  TabAttribut.RowCount         := 17;
  For I := 0 to 13 do
    begin
      if TabAttribut.Columns.Count <= I then
        TabAttribut.Columns.Add;
      if I > ColAttLib then
        begin
          TabAttribut.ColWidths[I]  := 53;
          TabAttribut.Columns[I].Alignment := taCenter;
        end;
    end;

  AttributInit();

  TabAttribut.ColWidths[0]             := 20;
  TabAttribut.ColWidths[ColAttLib]     := 100;
  TabAttribut.ColWidths[ColAttDestin]  := 0;
  TabAttribut.ColWidths[ColAttResil]   := 0;
  TabAttribut.ColWidths[ColAttBlessure]:= 0;

  TabAttribut.Cells[ColAttLib, LigAttRace]    := GetTexteLibelle('RULES-LAB_042');
  TabAttribut.Cells[ColAttLib, LigAttLance]   := GetTexteLibelle('RULES-LAB_022');
  TabAttribut.Cells[ColAttLib, LigAttTalent]  := GetTexteLibelle('RULES-LAB_007');
  TabAttribut.Cells[ColAttLib, LigAttMutation]:= GetTexteLibelle('RULES-LAB_172');
  TabAttribut.Cells[ColAttLib, LigAttPathologie]:= GetTexteLibelle('RULES-LAB_298');
  TabAttribut.Cells[ColAttLib, LigAttCareer]  := GetTexteLibelle('RULES-LAB_181');
  TabAttribut.Cells[ColAttLib, LigAttObjet]   := GetTexteLibelle('RULES-LAB_182');
  TabAttribut.Cells[ColAttLib, LigAttSigne]   := GetTexteLibelle('RULES-LAB_272');
  TabAttribut.Cells[ColAttLib, LigAttBase]    := GetTexteLibelle('RULES-LAB_043');
  TabAttribut.Cells[ColAttLib, LigAttImage]   := GetTexteLibelle('RULES-LAB_019');
  TabAttribut.Cells[ColAttLib, LigAttBonus]   := GetTexteLibelle('RULES-LAB_040');
  TabAttribut.Cells[ColAttLib, LigAttTotal]   := GetTexteLibelle('RULES-LAB_041');
  TabAttribut.Cells[ColAttLib, LigAttXp]      := GetTexteLibelle('RULES-LAB_035');
  TabAttribut.Cells[ColAttLib, LigAttAsterisc]:= '*';

  TabAttribut.RowHeights[LigAttRace]    := 1;
  TabAttribut.RowHeights[LigAttLance]   := 1;
  TabAttribut.RowHeights[LigAttTalent]  := 1;
  TabAttribut.RowHeights[LigAttMutation]:= 1;
  TabAttribut.RowHeights[LigAttPathologie]:= 1;
  TabAttribut.RowHeights[LigAttCareer]  := 1;
  TabAttribut.RowHeights[LigAttObjet]   := 1;
  TabAttribut.RowHeights[LigAttSigne]   := 1;
  TabAttribut.RowHeights[LigAttXp]      := 1;
  TabAttribut.RowHeights[LigAttImage]   := 1;
  TabAttribut.RowHeights[LigAttActuel]  := 1;
  TabAttribut.RowHeights[LigAttCode]    := 1;
  TabAttribut.RowHeights[LigAttAsterisc]:= 1;


  // Mise en forme du tableau des talents
  TabTalent.Options                  := TabTalent.Options + [goEditing, goAlwaysShowEditor];
  TabTalent.ColCount                 := 11;
  TabTalent.RowCount                 := 1;
  TabTalent.ColWidths[0]             := 20;
  TabTalent.ColWidths[ColTalCode]    := 0;                           // code talent
  TabTalent.ColWidths[2]             := 0;                           // image
  TabTalent.Cells[ColTalLib, 0]      := GetTexteLibelle('RULES-LAB_007');  // libellé talent
  TabTalent.ColWidths[ColTalLib]     := 200;
  TabTalent.Cells[ColTalNb, 0]       := GetTexteLibelle('RULES-LAB_045');  // nb talent
  TabTalent.ColWidths[ColTalNb]      := 53;
  TabTalent.Cells[ColTalMax, 0]      := GetTexteLibelle('RULES-LAB_044');  // Max Talent
  TabTalent.ColWidths[ColTalMax]     := 0;
  TabTalent.Cells[ColTalXp, 0]       := GetTexteLibelle('RULES-LAB_035');  // XP
  TabTalent.ColWidths[ColTalXp]      := 0;
  TabTalent.Cells[7, 0]              := GetTexteLibelle('RULES-LAB_016');  //
  TabTalent.ColWidths[7]             := 0;
  TabTalent.Cells[ColTalAsterisk, 0] := '*';                         // astérisque pour PDF
  TabTalent.ColWidths[ColTalAsterisk]:= 0;
  TabTalent.Cells[ColTalNbCrea, 0]   := GetTexteLibelle('RULES-LAB_079');  // nb création
  TabTalent.ColWidths[ColTalNbCrea]  := 0;
  TabTalent.Cells[ColTalNbAugm,0]    := GetTexteLibelle('RULES-LAB_103');  // nb augmentation
  TabTalent.ColWidths[ColTalNbAugm]  := 0;

  // Mise en forme du tableau des Niveaux
  TabNiveau.Options          := TabNiveau.Options + [goEditing, goAlwaysShowEditor];
  TabNiveau.ColCount         := 1;
  // Une ligne d'entete plus un niveau par rang existant. C'etait fige a 5, ce qui faisait
  // ecrire hors bornes des le premier metier a cinq niveaux : l.2989 se sert du NUMERO DE
  // NIVEAU comme indice de ligne.
  TabNiveau.RowCount         := MaxNiveauMetier() + 1;
  TabNiveau.ColWidths[0]     := 20;
  TabNiveau.Columns.Add;
  TabNiveau.ColWidths[1]     := 0;
  TabNiveau.Columns.Add;
  TabNiveau.Columns[1].Alignment := taCenter;
  TabNiveau.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_019');
  TabNiveau.ColWidths[2]     := 40;
  TabNiveau.Columns.Add;
  TabNiveau.Cells[3, 0]      := GetTexteLibelle('RULES-LAB_046');
  TabNiveau.ColWidths[3]     := 140;

  // Mise en forme du tableau des Compétences
  TabCompetence.Options                   := TabCompetence.Options + [goEditing, goAlwaysShowEditor];
  TabCompetence.ColCount                  := 19;
  TabCompetence.RowCount                  := 1;
  TabCompetence.ColWidths[0]              := 20;
  TabCompetence.ColWidths[ColCompCode]    := 0;
  TabCompetence.Cells[ColCompImage, 0]    := GetTexteLibelle('RULES-LAB_019');
  TabCompetence.ColWidths[ColCompImage]   := 0;
  TabCompetence.Cells[ColCompLib, 0]      := GetTexteLibelle('RULES-LAB_003');
  TabCompetence.ColWidths[ColCompLib]     := 180;
  TabCompetence.Cells[ColCompCarac, 0]    := GetTexteLibelle('RULES-LAB_008');
  TabCompetence.ColWidths[ColCompCarac]   := 50;
  TabCompetence.Cells[ColCompAtt, 0]      := GetTexteLibelle('RULES-LAB_025');
  TabCompetence.ColWidths[ColCompAtt]     := 50;
  TabCompetence.Cells[ColComp35, 0]       := '3p/5p';
  TabCompetence.ColWidths[ColComp35]      := 0;
  TabCompetence.Cells[ColComp40, 0]       := '40pts';
  TabCompetence.ColWidths[ColComp40]      := 0;
  TabCompetence.Cells[ColCompWork, 0]     := GetTexteLibelle('RULES-LAB_006');
  TabCompetence.ColWidths[ColCompWork]    := 0;
  TabCompetence.Cells[ColCompMutation, 0] := GetTexteLibelle('RULES-LAB_172');
  TabCompetence.ColWidths[ColCompMutation]:= 0;
  TabCompetence.Cells[ColCompAppartenance, 0]   := GetTexteLibelle('RULES-LAB_188');
  TabCompetence.ColWidths[ColCompAppartenance]  := 0;
  // RULES-LAB_189 ("Career Bonus"/"Bonus de carriere"), pas RULES-LAB_181 ("Career") : ce
  // dernier est deja pris par ColCompWork (RULES-LAB_006, egalement "Career" en anglais) -
  // les deux colonnes affichaient le meme intitule, signale par Nono.
  TabCompetence.Cells[ColCompCareer, 0]   := GetTexteLibelle('RULES-LAB_189');
  TabCompetence.ColWidths[ColCompCareer]  := 0;
  TabCompetence.Cells[ColCompBonus, 0]    := GetTexteLibelle('RULES-LAB_034');
  TabCompetence.ColWidths[ColCompBonus]   := 50;
  TabCompetence.Cells[ColCompTotal, 0]    := GetTexteLibelle('RULES-LAB_021');
  TabCompetence.ColWidths[ColCompTotal]   := 50;
  TabCompetence.Cells[ColCompStat, 0]     := 'Stat';
  TabCompetence.ColWidths[ColCompStat]    := 0;
  TabCompetence.Cells[ColCompXp, 0]       := GetTexteLibelle('RULES-LAB_035');
  TabCompetence.ColWidths[ColCompXp]      := 0;
  TabCompetence.Cells[ColCompActuel, 0]   := GetTexteLibelle('RULES-LAB_016');
  TabCompetence.ColWidths[ColCompActuel]  := 0;
  TabCompetence.Cells[ColCompTravail, 0]  := 'W';
  TabCompetence.ColWidths[ColCompTravail] := 0;
  TabCompetence.Cells[ColCompAsterisc, 0] := '*';
  TabCompetence.ColWidths[ColCompAsterisc]:= 0;

  // Mise en forme du tableau des carrières
  TabCarriere.Options                  := TabCarriere.Options + [goEditing, goAlwaysShowEditor];
  TabCarriere.ColCount                 := 5;
  TabCarriere.RowCount                 := 1;
  TabCarriere.ColWidths[0]             := 20;
  TabCarriere.Columns.Add;
  TabCarriere.ColWidths[1]             := 0;
  TabCarriere.Columns.Add;
  TabCarriere.Cells[2, 0]              := GetTexteLibelle('RULES-LAB_019');
  TabCarriere.Columns[1].Alignment     := taCenter;
  TabCarriere.ColWidths[2]             := 40;
  TabCarriere.Columns.Add;
  TabCarriere.Cells[3, 0]              := GetTexteLibelle('RULES-LAB_003');
  TabCarriere.ColWidths[3]             := 120;
  TabCarriere.Columns.Add;
  TabCarriere.Cells[4, 0]              := GetTexteLibelle('RULES-LAB_035');
  TabCarriere.ColWidths[4]             := 0;

  // Mise en forme du tableau d'état d'avancement
  TabAvancement.Options                  := TabAvancement.Options + [goEditing, goAlwaysShowEditor];
  TabAvancement.ColCount                 := 6;
  TabAvancement.RowCount                 := 4;
  TabAvancement.ColWidths[0]             := 20;
  TabAvancement.ColWidths[1]             := 0;
  TabAvancement.ColWidths[2]             := 0;
  TabAvancement.Cells[3, 0]              := GetTexteLibelle('RULES-LAB_047');
  TabAvancement.ColWidths[3]             := 100;
  TabAvancement.Cells[4, 0]              := GetTexteLibelle('RULES-LAB_048');
  TabAvancement.ColWidths[4]             := 40;
  TabAvancement.Cells[5, 0]              := GetTexteLibelle('RULES-LAB_049');
  TabAvancement.ColWidths[5]             := 40;
  TabAvancement.Cells[3, 1]              := GetTexteLibelle('RULES-LAB_008');
  TabAvancement.Cells[3, 2]              := GetTexteLibelle('RULES-LAB_009');
  TabAvancement.Cells[3, 3]              := GetTexteLibelle('RULES-LAB_007');
  TabAvancement.cells[4, 2]              := '8';        // 8 compétences
  TabAvancement.cells[4, 3]              := '1';        // 1 Talent

  // Mise en forme du tableau d'état d'avancement
  TabExperience.Options                         := TabExperience.Options + [goEditing, goAlwaysShowEditor];
  TabExperience.ColCount                        := 1;
  TabExperience.RowCount                        := 5;
  TabExperience.ColWidths[0]                    := 20;
  TabExperience.Columns.add;
  TabExperience.ColWidths[1]                    := 100;
  TabExperience.Columns.add;
  TabExperience.ColWidths[2]                    := 0;
  TabExperience.Columns.add;
  TabExperience.ColWidths[3]                    := 50;
  TabExperience.Columns[2].Alignment            := taRightJustify;
  tabExperience.Cells[ColXpLib, 0]              := GetTexteLibelle('RULES-LAB_047');
  tabExperience.Cells[ColXpLib, LigXpTotal]     := GetTexteLibelle('RULES-LAB_021');
  tabExperience.Cells[ColXpLib, LigXpDepense]   := GetTexteLibelle('RULES-LAB_050');
  tabExperience.Cells[ColXpLib, LigXpRestant]   := GetTexteLibelle('RULES-LAB_051');
  tabExperience.Cells[ColXpLib, LigXpCout]      := GetTexteLibelle('RULES-LAB_015');
  tabExperience.Cells[ColXpDonnee, 0]           := GetTexteLibelle('RULES-LAB_025');

  // Mise en forme du tableau des augmentation d'attribut
  TabAugmentationAttribut.Options                     := TabAugmentationAttribut.Options + [goEditing, goAlwaysShowEditor];
  TabAugmentationAttribut.ColCount                    := 10;
  TabAugmentationAttribut.RowCount                    := 11;
  TabAugmentationAttribut.ColWidths[0]                := 20;
  TabAugmentationAttribut.ColWidths[1]                := 0;
  TabAugmentationAttribut.Cells[1, 0]                 := GetTexteLibelle('RULES-LAB_008');
  TabAugmentationAttribut.ColWidths[2]                := 0;
  TabAugmentationAttribut.Cells[ColAugmAttCode, 0]    := GetTexteLibelle('RULES-LAB_001');
  TabAugmentationAttribut.ColWidths[ColAugmAttCode]   := 80;
  TabAugmentationAttribut.Cells[ColAugmAttActuel, 0]  := GetTexteLibelle('RULES-LAB_016');
  TabAugmentationAttribut.ColWidths[ColAugmAttActuel] := 80;
  TabAugmentationAttribut.Cells[ColAugmAttNouveau, 0] := GetTexteLibelle('RULES-LAB_017');
  TabAugmentationAttribut.ColWidths[ColAugmAttNouveau]:= 80;
  TabAugmentationAttribut.Cells[ColAugmAttMoins5, 0]  := '-5';
  TabAugmentationAttribut.ColWidths[ColAugmAttMoins5] := 50;
  TabAugmentationAttribut.Cells[ColAugmAttPlus5, 0]   := '+5';
  TabAugmentationAttribut.ColWidths[ColAugmAttPlus5]  := 50;
  TabAugmentationAttribut.Cells[ColAugmAttNouveau, 0] := GetTexteLibelle('RULES-LAB_017');
  TabAugmentationAttribut.ColWidths[ColAugmAttNouveau]:= 80;
  TabAugmentationAttribut.Cells[ColAugmAttCout, 0]    := GetTexteLibelle('RULES-LAB_015');
  TabAugmentationAttribut.ColWidths[ColAugmAttCout]   := 80;
  TabAugmentationAttribut.Cells[ColAugmAttReel, 0]    := GetTexteLibelle('RULES-LAB_139');
  TabAugmentationAttribut.ColWidths[ColAugmAttReel]   := 80;

  // Mise en forme du tableau des augmentation de Compétences
  TabAugmentationCompetence.Options                      := TabAugmentationCompetence.Options + [goEditing, goAlwaysShowEditor];
  TabAugmentationCompetence.ColCount                     := 14;
  TabAugmentationCompetence.RowCount                     := 11;
  TabAugmentationCompetence.ColWidths[0]                 := 20;
  TabAugmentationCompetence.ColWidths[ColAugmCompCode]   := 0;
  TabAugmentationCompetence.ColWidths[2]                 := 0;
  TabAugmentationCompetence.Cells[ColAugmCompLib, 0]     := GetTexteLibelle('RULES-LAB_009');
  TabAugmentationCompetence.ColWidths[ColAugmCompLib]    := 200;
  TabAugmentationCompetence.Cells[ColAugmCompActuel, 0]  := GetTexteLibelle('RULES-LAB_016');
  TabAugmentationCompetence.ColWidths[ColAugmCompActuel] := 70;
  TabAugmentationCompetence.Cells[ColAugmCompNouveau, 0] := GetTexteLibelle('RULES-LAB_019');
  TabAugmentationCompetence.ColWidths[ColAugmCompNouveau]:= 70;
  TabAugmentationCompetence.Cells[ColAugmCompMoins5, 0]  := '-5';
  TabAugmentationCompetence.ColWidths[ColAugmCompMoins5] := 50;
  TabAugmentationCompetence.Cells[ColAugmCompPlus5, 0]   := '+5';
  TabAugmentationCompetence.ColWidths[ColAugmCompPlus5]  := 50;
  TabAugmentationCompetence.Cells[ColAugmCompCout, 0]    := GetTexteLibelle('RULES-LAB_015');
  TabAugmentationCompetence.ColWidths[ColAugmCompCout]   := 70;
  TabAugmentationCompetence.Cells[ColAugmCompSpe, 0]     := GetTexteLibelle('RULES-LAB_078');
  TabAugmentationCompetence.ColWidths[ColAugmCompSpe]    := 200;
  TabAugmentationCompetence.Cells[ColAugmCompSpeSel, 0]  := 'Spé Choisie';
  TabAugmentationCompetence.ColWidths[ColAugmCompSpeSel] := 0;
  TabAugmentationCompetence.Cells[ColAugmCompWork, 0]    := 'Work';
  TabAugmentationCompetence.ColWidths[ColAugmCompWork]   := 0;
  TabAugmentationCompetence.Cells[ColAugmCompReel, 0]    := GetTexteLibelle('RULES-LAB_139');
  TabAugmentationCompetence.ColWidths[ColAugmCompReel]   := 50;
  TabAugmentationCompetence.Cells[ColAugmCompTri, 0]     := 'Tri';
  TabAugmentationCompetence.ColWidths[ColAugmCompTri]    := 0;

  // Mise en forme du tableau des ajout des talents
  TabAugmentationTalent.Options                     := TabAugmentationTalent.Options + [goEditing, goAlwaysShowEditor];
  TabAugmentationTalent.ColCount                    := 13;
  TabAugmentationTalent.RowCount                    := 11;
  TabAugmentationTalent.ColWidths[0]                := 20;
  TabAugmentationTalent.ColWidths[ColAugmTalCode]   := 0;
  TabAugmentationTalent.ColWidths[2]                := 0;
  TabAugmentationTalent.Cells[ColAugmTalLib, 0]     := GetTexteLibelle('RULES-LAB_007');
  TabAugmentationTalent.ColWidths[ColAugmTalLib]    := 280;
  TabAugmentationTalent.Cells[ColAugmTalActuel, 0]  := GetTexteLibelle('RULES-LAB_016');
  TabAugmentationTalent.ColWidths[ColAugmTalActuel] := 80;
  TabAugmentationTalent.Cells[ColAugmTalNouveau, 0] := GetTexteLibelle('RULES-LAB_019');
  TabAugmentationTalent.ColWidths[ColAugmTalNouveau]:= 80;
  TabAugmentationTalent.Cells[ColAugmTalCout, 0]    := GetTexteLibelle('RULES-LAB_015');
  TabAugmentationTalent.ColWidths[ColAugmTalCout]   := 80;
  TabAugmentationTalent.Cells[ColAugmTalSpe, 0]     := GetTexteLibelle('RULES-LAB_078');
  TabAugmentationTalent.ColWidths[ColAugmTalSpe]    := 200;
  TabAugmentationTalent.Cells[ColAugmTalSpeSel, 0]  := 'Spé Choisie';
  TabAugmentationTalent.ColWidths[ColAugmTalSpeSel] := 0;
  TabAugmentationTalent.Cells[ColAugmTalWork, 0]    := 'Work';
  TabAugmentationTalent.ColWidths[ColAugmTalWork]   := 0;
  // Colonne "choisir un sort" (Miracle/Petty a choix, ModeSort=CHOIX) : reservee de longue
  // date (voir ColAugmTalWork juste au-dessus) mais jamais cablee - posee/resolue depuis
  // SortAffiche/TabAugmentationTalentDblClick, sur le meme principe que la colonne
  // Specialisation juste a cote. Largeur mise a 0 par defaut, agrandie par SortAffiche
  // seulement quand une ligne en a besoin (evite une colonne vide en permanence).
  TabAugmentationTalent.Cells[ColAugmTalSort, 0]    := GetTexteLibelle('RULES-LAB_083');
  TabAugmentationTalent.ColWidths[ColAugmTalSort]   := 0;
  TabAugmentationTalent.Cells[ColAugmTalSortSel, 0] := 'Sort Choisi';
  TabAugmentationTalent.ColWidths[ColAugmTalSortSel]:= 0;
  TabAugmentationTalent.Cells[ColAugmTalReel, 0]    := GetTexteLibelle('RULES-LAB_139');
  TabAugmentationTalent.ColWidths[ColAugmTalReel]   := 50;
end;

procedure TWinPersonnages.InitialisationTablesSuivi();
begin
  // Mise en forme de la table des historiques
  TabHistorique.Options        := TabHistorique.Options + [goEditing, goAlwaysShowEditor];
  TabHistorique.ColCount       := 4;
  TabHistorique.RowCount       := 2;
  TabHistorique.ColWidths[0]   := 20;
  TabHistorique.Cells[1, 0]    := GetTexteLibelle('RULES-LAB_036');
  TabHistorique.ColWidths[1]   := 200;
  TabHistorique.Cells[2, 0]    := GetTexteLibelle('RULES-LAB_037');
  TabHistorique.ColWidths[2]   := 0;
  TabHistorique.Cells[3, 0]    := 'Ordre';
  TabHistorique.ColWidths[3]   := 0;

  // Mise en forme de la table de l'historique de corruption
  StringGridCorruption.Options        := StringGridCorruption.Options + [goEditing, goAlwaysShowEditor];
  StringGridCorruption.ColCount       := 3;
  StringGridCorruption.RowCount       := 1;
  StringGridCorruption.ColWidths[0]   := 20;
  StringGridCorruption.Cells[1, 0]    := GetTexteLibelle('RULES-LAB_162');
  StringGridCorruption.ColWidths[1]   := 80;
  StringGridCorruption.Cells[2, 0]    := GetTexteLibelle('RULES-LAB_163');
  StringGridCorruption.ColWidths[2]   := 300;

  // Mise en forme de la table des mutations obtenues (CONTEXT.md §2.7, étape 7) - lecture
  // seule, pas de goEditing (contrairement à StringGridCorruption). Colonne 3 = Code, cachée.
  TabMutation.ColCount       := 4;
  TabMutation.RowCount       := 1;
  TabMutation.ColWidths[0]   := 20;
  TabMutation.Cells[1, 0]    := GetTexteLibelle('RULES-LAB_171');
  TabMutation.ColWidths[1]   := 100;
  TabMutation.Cells[2, 0]    := GetTexteLibelle('RULES-LAB_002');
  TabMutation.ColWidths[2]   := 300;
  TabMutation.ColWidths[3]   := 0;
  MemoMutationEffet.ReadOnly := True;

  // Onglet commun Afflictions/Maladies (ajout du 27/09/2026, a la demande de Nono) - meme
  // principe que TabMutation ci-dessus : lecture seule, colonne 1 = Type (Affliction/
  // Maladie), colonne 2 = Libelle, colonne 3 = Code cache (sert au retrait et a
  // ChercheAffliction/ChercheDisease).
  TabPathologie.ColCount       := 4;
  TabPathologie.RowCount       := 1;
  TabPathologie.ColWidths[0]   := 20;
  TabPathologie.Cells[1, 0]    := GetTexteLibelle('RULES-LAB_171');
  TabPathologie.ColWidths[1]   := 100;
  TabPathologie.Cells[2, 0]    := GetTexteLibelle('RULES-LAB_002');
  TabPathologie.ColWidths[2]   := 300;
  TabPathologie.ColWidths[3]   := 0;
  MemoPathologieEffet.ReadOnly := True;
  ButtonPathologieAjouteAffliction.Caption := '+'+GetTexteLibelle('RULES-LAB_296');
  ButtonPathologieAjouteDisease.Caption    := '+'+GetTexteLibelle('RULES-LAB_281');

  // Onglet Ambitions (ajout du 27/09/2026, a la demande de Nono) - lecture seule, apercu des
  // 4 champs texte libre (Personnage.AmbitionCourt/Long/GroupeCourt/GroupeLong) ; double-clic
  // sur une ligne ouvre la fenetre de saisie WinAmbition (les 4 champs s'y editent ensemble).
  TabSheetAmbition.Caption     := GetTexteLibelle('RULES-LAB_300');
  TabAmbition.ColCount         := 3;
  TabAmbition.RowCount         := 1;
  TabAmbition.ColWidths[0]     := 20;
  TabAmbition.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_171');
  TabAmbition.ColWidths[1]     := 150;
  TabAmbition.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_002');
  TabAmbition.ColWidths[2]     := 400;

  // Groupe (biens partages, CONTEXT.md 2.100) : meme principe que TabAmbition ci-dessus.
  TabSheetGroupe.Caption       := GetTexteLibelle('RULES-LAB_301');
  TabGroupe.ColCount           := 3;
  TabGroupe.RowCount           := 1;
  TabGroupe.ColWidths[0]       := 20;
  TabGroupe.Cells[1, 0]        := GetTexteLibelle('RULES-LAB_171');
  TabGroupe.ColWidths[1]       := 150;
  TabGroupe.Cells[2, 0]        := GetTexteLibelle('RULES-LAB_002');
  TabGroupe.ColWidths[2]       := 400;
end;

procedure TWinPersonnages.InitialisationTablesEquipement();
begin
  // Mise en forme de la table des Equipements. TabEquipement reste la grille complete de
  // sauvegarde (masquee, CONTEXT.md etape 2) : toute la mise en forme des colonnes et les
  // procedures existantes (ajout, suppression, Confier a...) continuent d'operer dessus sans
  // changement. Seuls les evenements d'interaction utilisateur sont branches sur
  // TabEquipementAffichage, la grille visible et filtree par ListBoxEquipementCategorie.
  TabEquipement.Options        := TabEquipement.Options + [goEditing, goAlwaysShowEditor];
  TabEquipement.ColCount       := 15;
  TabEquipement.RowCount       := 2;
  TabEquipement.ColWidths[0]   := 20;
  TabEquipement.Cells[1, 0]    := GetTexteLibelle('RULES-LAB_052');
  TabEquipement.ColWidths[1]   := 0;
  TabEquipement.Cells[2, 0]    := GetTexteLibelle('RULES-LAB_001');
  TabEquipement.ColWidths[2]   := 0;
  TabEquipement.Cells[3, 0]    := GetTexteLibelle('RULES-LAB_018');
  TabEquipement.ColWidths[3]   := 200;
  TabEquipement.Cells[4, 0]    := GetTexteLibelle('RULES-LAB_003');
  TabEquipement.ColWidths[4]   := 300;
  TabEquipement.Cells[5, 0]    := GetTexteLibelle('RULES-LAB_035');
  TabEquipement.ColWidths[5]   := 0;
  TabEquipement.Cells[6, 0]    := GetTexteLibelle('RULES-LAB_120');
  TabEquipement.ColWidths[6]   := 100;
  TabEquipement.Cells[7, 0]    := '';
  TabEquipement.ColWidths[7]   := 0;
  TabEquipement.Cells[8, 0]    := GetTexteLibelle('RULES-LAB_180');
  TabEquipement.ColWidths[8]   := 60;
  TabEquipement.Cells[9, 0]    := GetTexteLibelle('RULES-LAB_203');
  TabEquipement.ColWidths[9]   := 60;
  // Colonnes cachees : identifiant d'instance de l'animal et animal porteur (CONTEXT.md 2.84).
  TabEquipement.Cells[10, 0]   := 'Id';
  TabEquipement.ColWidths[10]  := 0;
  TabEquipement.Cells[11, 0]   := 'PortePar';
  TabEquipement.ColWidths[11]  := 0;
  TabEquipement.Cells[12, 0]   := GetTexteLibelle('RULES-LAB_254');
  TabEquipement.ColWidths[12]  := 150;
  // Colonnes cachees : nom et encombrement d'un objet de texte pur (+Texte), vides pour un objet normal.
  TabEquipement.Cells[13, 0]   := 'NomLibre';
  TabEquipement.ColWidths[13]  := 0;
  TabEquipement.Cells[14, 0]   := 'EncLibre';
  TabEquipement.ColWidths[14]  := 0;

  // Grille d'affichage (visible) et liste de categories, memes evenements que TabEquipement
  // avant la scission (branches ici et non plus sur TabEquipement, cf. commentaire ci-dessus).
  TabEquipementAffichage.Options          := TabEquipementAffichage.Options + [goEditing, goAlwaysShowEditor];
  TabEquipementAffichage.OnDrawCell       := @TabDrawCell;
  TabEquipementAffichage.OnSelectEditor   := @TabEquipementSelectEditor;
  TabEquipementAffichage.OnSelectCell     := @TabEquipementSelectCell;
  TabEquipementAffichage.OnDblClick       := @TabEquipementDblClick;
  TabEquipementAffichage.OnMouseDown      := @TabEquipementMouseDown;
  TabEquipementAffichage.OnMouseMove      := @TabEquipementMouseMove;
  TabEquipementAffichage.OnSetEditText    := @TabEquipementAffichageSetEditText;
  TabEquipementAffichage.ShowHint         := True;
  TabEquipementAffichage.PopupMenu        := TPopupMenu.Create(Self);
  TabEquipementAffichage.PopupMenu.OnPopup := @TabEquipementPopup;

  // Ordre = valeur renvoyee par CategorieEquipementLigne (0 a 4).
  ListBoxEquipementCategorie.Items.Clear;
  ListBoxEquipementCategorie.Items.Add(GetTexteLibelle('RULES-LAB_286'));
  ListBoxEquipementCategorie.Items.Add(GetTexteLibelle('RULES-LAB_063'));
  ListBoxEquipementCategorie.Items.Add(GetTexteLibelle('RULES-LAB_065'));
  ListBoxEquipementCategorie.Items.Add(GetTexteLibelle('RULES-LAB_064'));
  ListBoxEquipementCategorie.Items.Add(GetTexteLibelle('RULES-LAB_083'));
  ListBoxEquipementCategorie.ItemIndex := 3;
  RafraichitTabEquipementAffichage();

  // Mise en forme dy tableau de choix des équipement de métier
  TabMetierEquipement.Options          := TabMetierEquipement.Options + [goEditing, goAlwaysShowEditor];
  TabMetierEquipement.ColCount         := 7;
  TabMetierEquipement.RowCount         := 1;
  // colonne 0 = case a cocher : colonne normale (une colonne fixe est noire, texte noir, et un clic
  // dessus ne change pas Col)
  TabMetierEquipement.FixedCols        := 0;
  TabMetierEquipement.ColWidths[0]     := 50;
  TabMetierEquipement.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_001');
  TabMetierEquipement.ColWidths[1]     := 0;
  TabMetierEquipement.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_013');
  TabMetierEquipement.ColWidths[2]     := 200;
  TabMetierEquipement.Cells[3, 0]      := GetTexteLibelle('RULES-LAB_010');
  TabMetierEquipement.ColWidths[3]     := 0;
  TabMetierEquipement.Cells[4, 0]      := GetTexteLibelle('RULES-LAB_018');
  TabMetierEquipement.ColWidths[4]     := 0;
  TabMetierEquipement.Cells[5, 0]      := GetTexteLibelle('RULES-LAB_120');
  TabMetierEquipement.ColWidths[5]     := 100;
  TabMetierEquipement.ColWidths[6]     := 0;   // quantite du livre (cachee)
  TabMetierEquipement.OnClick          := @TabMetierEquipementClick;
end;

procedure TWinPersonnages.InitialisationTablesDivers();
  var
    I:        Integer;
    strings:  TStringList;
    Livre:    String;
    Ordre:    String;
    PLivre:   StructureLivre;
begin
  // mise en forme du tableau des choix des sorts
  TabSort.Options          := TabSort.Options + [goEditing, goAlwaysShowEditor];
  TabSort.ColCount         := 4;
  TabSort.RowCount         := 1;
  TabSort.ColWidths[0]     := 30;
  TabSort.Cells[1, 0]      := GetTexteLibelle('RULES-LAB_001');
  TabSort.ColWidths[1]     := 0;
  TabSort.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_002');
  TabSort.ColWidths[2]     := 400;
  TabSort.Cells[3, 0]      := GetTexteLibelle('RULES-LAB_007');
  TabSort.ColWidths[3]     := 0;

  // mise en forme du tableau de création du Livre
  TabLivre.ColCount         := 5;
  TabLivre.RowCount         := 1;
  TabLivre.ColWidths[0]     := 20;
  TabLivre.Cells[1, 0]      := ConstSelectionne;
  TabLivre.ColWidths[1]     := 20;
  TabLivre.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
  TabLivre.ColWidths[2]     := 230;
  TabLivre.ColWidths[3]     := 0;
  TabLivre.ColWidths[4]     := 0;

  // mise en forme des couts des augmentation spéciales (mj)
  TabAugmentationMjXp.ColCount                   := 8;
  TabAugmentationMjXp.RowCount                   := 1;
  TabAugmentationMjXp.ColWidths[0]               := 20;
  TabAugmentationMjXp.Cells[ColAugmMjXpType, 0]  := GetTexteLibelle('RULES-LAB_018');  // Type
  TabAugmentationMjXp.ColWidths[ColAugmMjXpType] := 100;
  TabAugmentationMjXp.Cells[ColAugmMjXpCode, 0]  := GetTexteLibelle('RULES-LAB_001');  // Code
  TabAugmentationMjXp.ColWidths[ColAugmMjXpCode] := 100;
  TabAugmentationMjXp.Cells[ColAugmMjXpDebut, 0] := GetTexteLibelle('RULES-LAB_141');  // Début
  TabAugmentationMjXp.ColWidths[ColAugmMjXpDebut]:= 100;
  TabAugmentationMjXp.Cells[ColAugmMjXpFin, 0]   := GetTexteLibelle('RULES-LAB_142');  // Fin
  TabAugmentationMjXp.ColWidths[ColAugmMjXpFin]  := 100;
  TabAugmentationMjXp.Cells[ColAugmMjXpCout, 0]  := GetTexteLibelle('RULES-LAB_015');  // Coût
  TabAugmentationMjXp.ColWidths[ColAugmMjXpCout] := 100;
  TabAugmentationMjXp.Cells[ColAugmMjXpReel, 0]  := GetTexteLibelle('RULES-LAB_139');  // Coût réel
  TabAugmentationMjXp.ColWidths[ColAugmMjXpReel] := 100;
  TabAugmentationMjXp.Cells[ColAugmMjXpNew, 0]   := 'N';                         // nouvelle ligne
  TabAugmentationMjXp.ColWidths[ColAugmMjXpNew]  := 0;

  strings       := TStringList.Create;
  ExtractStrings(['['], [], PChar(LivresCharges), Strings);
  for I := 0 to (Strings.count - 1) Do
    begin
      TabLivre.RowCount        := TabLivre.RowCount + 1;
      Livre                    := Strings[I];
      Livre                    := StringReplace(StringReplace(Livre, '[', '', [rfReplaceAll]), ']', '', [rfReplaceAll]);
      TabLivre.Cells[2, I+1]   := GetTexteLibelle(Livre,'','',true);
      TabLivre.Cells[3, I+1]   := Livre;
      PLivre                   := ChercheLivreLibelle(Livre);
      Ordre                    := IntToStr(PLivre.Officiel);
      TabLivre.Cells[4, I+1]   := Ordre+Livre;
    end;
  strings.free;
  TabLivre.SortColRow(true,4);

  // rendre inactif
  LibRace.ReadOnly           := True;
  LibMetier.ReadOnly         := True;
end;

procedure TWinPersonnages.Initialisation();
begin
  PreviousRowIndexA := 0;
  PreviousRowIndexC := 0;
  PreviousRowIndexT := 0;

  MiseEnFormeDesChamp(self);

  InitialisationImages();
  InitialisationTablesPersonnage();
  InitialisationTablesSuivi();
  InitialisationTablesEquipement();
  InitialisationTablesDivers();
end;

procedure TWinPersonnages.FormCreate(Sender: TObject);
  var
    Chemin:    String;
    DejaOuvert: Boolean;
    I:         Integer;
    Fleche:    TButton;
  begin
    // +Objet : bouton copie de +Texte (objet propre au personnage, WinObjetPropre)
    ButtonObjet         := TBCButtonContour.Create(Self);
    ButtonObjet.Assign(ButtonTexte);
    ButtonObjet.Parent  := ButtonTexte.Parent;
    ButtonObjet.Anchors := [];
    ButtonObjet.SetBounds(ButtonTexte.Left, ButtonTexte.Top, ButtonTexte.Width, ButtonTexte.Height);
    ButtonObjet.OnClick := @ButtonObjetClick;
    // +Specialisation : un bouton par page d'augmentation, visible seulement sur une ligne dont le
    // choix de specialisation n'est pas encore fait (MajBoutonsSpecialisation)
    ButtonSpecCompetence         := TBCButtonContour.Create(Self);
    ButtonSpecCompetence.Assign(ButtonTexte);
    ButtonSpecCompetence.Parent  := ListBoxExperience.Parent;
    ButtonSpecCompetence.Anchors := [akTop, akLeft];
    ButtonSpecCompetence.OnClick := @ButtonSpecialisationClick;
    ButtonSpecCompetence.Visible := False;
    ButtonSpecTalent             := TBCButtonContour.Create(Self);
    ButtonSpecTalent.Assign(ButtonTexte);
    ButtonSpecTalent.Parent      := ListBoxExperience.Parent;
    ButtonSpecTalent.Anchors     := [akTop, akLeft];
    ButtonSpecTalent.OnClick     := @ButtonSpecialisationClick;
    ButtonSpecTalent.Visible     := False;
    // Destin / Resilience / Resolution : page creee ici (derniere du TNotebook, comme son entree dans ListBoxExperience)
    PageExperience.Pages.Add(GetTexteLibelle('RULES-LAB_654'));
    PageReserve := TPage(PageExperience.Page[PageExperience.PageCount - 1]);
    // trois blocs de 270 de large : Destin, Resilience (les lignes modifient la valeur du personnage) et
    // Resolution (reserve, maximum = Resilience)
    ReservesChargement    := True;
    PanelDestin           := TPanelReserve.Create(Self);
    PanelDestin.Parent    := PageReserve;
    PanelDestin.Cumul     := False;
    PanelDestin.SetBounds(16, 8, 270, 330);
    PanelDestin.Initialiser(ButtonTexte, GetTexteLibelle('RULES-LAB_652'));
    PanelDestin.Placer(270);
    PanelDestin.OnChange  := @RegistreDestinChange;
    PanelResilience       := TPanelReserve.Create(Self);
    PanelResilience.Parent := PageReserve;
    PanelResilience.Cumul := False;
    PanelResilience.SetBounds(296, 8, 270, 330);
    PanelResilience.Initialiser(ButtonTexte, GetTexteLibelle('RULES-LAB_659'));
    PanelResilience.Placer(270);
    PanelResilience.OnChange := @RegistreResilienceChange;
    PanelResolve          := TPanelReserve.Create(Self);
    PanelResolve.Parent   := PageReserve;
    PanelResolve.SetBounds(576, 8, 270, 330);
    PanelResolve.Initialiser(ButtonTexte, GetTexteLibelle('RULES-LAB_653'));
    PanelResolve.Placer(270);
    // Onglet Monnaie : les trois champs CO/PA/SB (crees par PlaceChampsMonnaie) y sont poses
    PageExperience.Pages.Add(GetTexteLibelle('RULES-LAB_694'));
    PageMonnaie := TPage(PageExperience.Page[PageExperience.PageCount - 1]);
    // Onglet PDF : derniere page, apres Reserves. Les options d'impression y sont regroupees ;
    // la case PDF Feldo 2p y est deplacee (elle etait a cote du bouton PDF).
    PageExperience.Pages.Add(GetTexteLibelle('RULES-LAB_691'));
    PagePdf := TPage(PageExperience.Page[PageExperience.PageCount - 1]);
    CheckBoxPdfFeldo2p.Parent  := PagePdf;
    CheckBoxPdfFeldo2p.Anchors := [akTop, akLeft];
    CheckBoxPdfFeldo2p.SetBounds(16, 16, CheckBoxPdfFeldo2p.Width, CheckBoxPdfFeldo2p.Height);
    LabelPdfFeldo2p.Parent     := PagePdf;
    LabelPdfFeldo2p.Anchors    := [akTop, akLeft];
    LabelPdfFeldo2p.SetBounds(CheckBoxPdfFeldo2p.Left + CheckBoxPdfFeldo2p.Width + 4, 16, LabelPdfFeldo2p.Width, LabelPdfFeldo2p.Height);
    // Asterisques : deux options, cacher le tout ou seulement les montants (voir pdfpersonnage.pas)
    CheckBoxSansAsterisque         := TCheckBox.Create(Self);
    CheckBoxSansAsterisque.Parent  := PagePdf;
    CheckBoxSansAsterisque.SetBounds(16, 48, CheckBoxPdfFeldo2p.Width, CheckBoxPdfFeldo2p.Height);
    CheckBoxSansAsterisque.OnClick := @CheckBoxSansAsterisqueClick;
    LabSansAsterisque              := TLabelContour.Create(Self);
    LabSansAsterisque.Parent       := PagePdf;
    LabSansAsterisque.Font.Color   := clWhite;
    LabSansAsterisque.SetBounds(CheckBoxSansAsterisque.Left + CheckBoxSansAsterisque.Width + 4, 48, 300, 20);
    CheckBoxSansMontant            := TCheckBox.Create(Self);
    CheckBoxSansMontant.Parent     := PagePdf;
    CheckBoxSansMontant.SetBounds(16, 80, CheckBoxPdfFeldo2p.Width, CheckBoxPdfFeldo2p.Height);
    LabSansMontant                 := TLabelContour.Create(Self);
    LabSansMontant.Parent          := PagePdf;
    LabSansMontant.Font.Color      := clWhite;
    LabSansMontant.SetBounds(CheckBoxSansMontant.Left + CheckBoxSansMontant.Width + 4, 80, 300, 20);
    // Habillage Warhammer du PDF Feldo (bandeaux, zebrage) : voir PdfStyle dans pdfpersonnage.pas
    CheckBoxStylePdf               := TCheckBox.Create(Self);
    CheckBoxStylePdf.Parent        := PagePdf;
    CheckBoxStylePdf.SetBounds(16, 112, CheckBoxPdfFeldo2p.Width, CheckBoxPdfFeldo2p.Height);
    CheckBoxStylePdf.OnClick       := @CheckBoxStylePdfClick;
    CheckBoxCouleurPdf             := TCheckBox.Create(Self);
    CheckBoxCouleurPdf.Parent      := PagePdf;
    CheckBoxCouleurPdf.SetBounds(40, 144, CheckBoxPdfFeldo2p.Width, CheckBoxPdfFeldo2p.Height);
    CheckBoxCouleurPdf.Checked     := True;
    LabCouleurPdf                  := TLabelContour.Create(Self);
    LabCouleurPdf.Parent           := PagePdf;
    LabCouleurPdf.Font.Color       := clWhite;
    LabCouleurPdf.SetBounds(CheckBoxCouleurPdf.Left + CheckBoxCouleurPdf.Width + 4, 144, 400, 20);
    CheckBoxEconomiePdf            := TCheckBox.Create(Self);
    CheckBoxEconomiePdf.Parent     := PagePdf;
    CheckBoxEconomiePdf.SetBounds(40, 176, CheckBoxPdfFeldo2p.Width, CheckBoxPdfFeldo2p.Height);
    LabEconomiePdf                 := TLabelContour.Create(Self);
    LabEconomiePdf.Parent          := PagePdf;
    LabEconomiePdf.Font.Color      := clWhite;
    LabEconomiePdf.SetBounds(CheckBoxEconomiePdf.Left + CheckBoxEconomiePdf.Width + 4, 176, 400, 20);
    LabStylePdf                    := TLabelContour.Create(Self);
    LabStylePdf.Parent             := PagePdf;
    LabStylePdf.Font.Color         := clWhite;
    LabStylePdf.SetBounds(CheckBoxStylePdf.Left + CheckBoxStylePdf.Width + 4, 112, 400, 20);
    // Grilles sans edition (livres, MJ XP, mutations, pathologies, ambitions, groupe) : ligne entiere
    // selectionnee, meme couleur que les fenetres de choix, visible meme sans le focus
    SelectionGrilleWarhammer(TabLivre);
    SelectionGrilleWarhammer(TabAugmentationMjXp);
    SelectionGrilleWarhammer(TabMutation);
    SelectionGrilleWarhammer(TabPathologie);
    SelectionGrilleWarhammer(TabAmbition);
    SelectionGrilleWarhammer(TabGroupe);
    // Initialisation
    Initialisation();

    // personnage retenu : on ne peut plus lui donner d'objet depuis une autre fenetre
    FVerrouPerso := MutexPersonnage(NomPersonnage, DejaOuvert);
    // chargement du personnage
    Chemin := XmlPersonnageFichierActuel(GetCurrentDir+ConstCheminPersonnage+NomPersonnage);
    XmlChargePersonnage(Chemin);

    // fleches precedent / suivant (pratique pour les tests) : creees ici, sans toucher au .lfm
    for I := 0 to 1 do
      begin
        Fleche         := TButton.Create(Self);
        Fleche.Parent  := Self;
        Fleche.SetBounds(4 + I * 34, 4, 30, 24);
        Fleche.Caption := Copy('<>', I + 1, 1);
        Fleche.Tag     := I * 2 - 1;
        Fleche.OnClick := @PersonnageVoisinClick;
      end;

    KeyPreview := true;

    // PageIndex de depart (5, fixe dans le .lfm) ne declenche pas OnPageChanged tout
    // seul : synchronise la liste laterale et force le premier repaint de la page
    // active (meme raison que dans PageExperienceChange).
    PageExperienceChange(nil);

    // arrive par les fleches < > : se repositionner sur la page et la categorie d'equipement
    // laissees sur le personnage precedent
    if (PageVoisinSauvee >= 0) and (PageVoisinSauvee < PageExperience.PageCount) then
      begin
        PageExperience.PageIndex := PageVoisinSauvee;
        PageExperienceChange(nil);
      end;
    if (CategorieVoisinSauvee >= 0) and (CategorieVoisinSauvee < ListBoxEquipementCategorie.Items.Count) then
      begin
        ListBoxEquipementCategorie.ItemIndex := CategorieVoisinSauvee;
        RafraichitTabEquipementAffichage();
      end;
    PageVoisinSauvee      := -1;
    CategorieVoisinSauvee := -1;
  end;

// Ferme la fiche et rouvre celle du personnage voisin dans l ordre alphabetique des dossiers
// de SAVED_CARACTERS (meme mecanisme que l Enregistrer : Menu.FormActivate rouvre RecherchePersonnage).
procedure TWinPersonnages.PersonnageVoisinClick(Sender: TObject);
  var
    Noms:  TStringList;
    Rech:  TSearchRec;
    Base:  String;
    Ind:   Integer;
  begin
    Base := GetCurrentDir + ConstCheminPersonnage;
    Noms := TStringList.Create;
    try
      if FindFirst(Base + '*', faDirectory, Rech) = 0 then
        begin
          repeat
            if ((Rech.Attr and faDirectory) <> 0) and (Rech.Name <> '.') and (Rech.Name <> '..') then
              Noms.Add(Rech.Name);
          until FindNext(Rech) <> 0;
          FindClose(Rech);
        end;
      Noms.Sort;
      Ind := Noms.IndexOf(NomPersonnage);
      if (Ind < 0) or (Noms.Count < 2) then
        Exit;
      Ind := (Ind + TButton(Sender).Tag + Noms.Count) mod Noms.Count;
      RecherchePersonnage   := Noms[Ind];
      PageVoisinSauvee      := PageExperience.PageIndex;
      CategorieVoisinSauvee := ListBoxEquipementCategorie.ItemIndex;
    finally
      Noms.Free;
    end;
    Close;
  end;

// Ancrage des controles (A FAIRE.txt, demande de Nono le 05/09/2026) - premiere etape sur
// WinPersonnage : rappeler le moteur de positionnement existant (AjustePositionTables, deja
// utilise par les deux cases de detail Xp/Calcul) aussi sur le redimensionnement de la
// fenetre, plutot que d ajouter des Anchors qui seraient de toute facon ecrases par les
// affectations .Left/.Top/.Width en dur de cette fonction.
procedure TWinPersonnages.FormResize(Sender: TObject);
  begin
    AjustePositionTables();
  end;


var
  ZoneImagesRace: TZoneImagesRace;

Procedure TWinPersonnages.AfficheImageRace();
  Var
    CheminImage1:   String;
    CheminImage2:   String;
    IndTabAttribut: Integer;
    IndSauve:       Integer;
    PRaceAttribut:  StructureRaceAttribut;
  begin

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

    // ATTRIBUTS
    IndTabAttribut := 1;
    for PRaceAttribut in ListRaceAttribut do
      if CompareRechercheValeur(PRaceAttribut.CodeRace, RaceEnCours) and (IndTabAttribut < ColAttBlessure) then
        begin
          Inc(IndTabAttribut);
          if IndTabAttribut = ColAttBlessure then
            RaceBlessure := PRaceAttribut.CalculRace
          else
            if CountOccurrences(PRaceAttribut.CalculRace,'+') > 0 then
              TabAttribut.Cells[IndTabAttribut, LigAttRace] := ExtractStringAfter(PRaceAttribut.CalculRace,'+')
            else
              TabAttribut.Cells[IndTabAttribut, LigAttRace] := PRaceAttribut.CalculRace;
            end;

    Self.Caption                               := GetTexteLibelle('RULES-LAB_081');
    LabelRace.Caption                          := GetTexteLibelle('RULES-LAB_042');
    LabelMetier.Caption                        := GetTexteLibelle('RULES-LAB_006');
    LabTabAttribut.Caption                     := GetTexteLibelle('RULES-LAB_008');
    LabTabTalent.Caption                       := GetTexteLibelle('RULES-LAB_007');
    LabTabCompetence.Caption                   := GetTexteLibelle('RULES-LAB_009');
    LabTabCarriere.Caption                     := GetTexteLibelle('RULES-LAB_096');
    LabTabExperience.Caption                   := GetTexteLibelle('RULES-LAB_097');
    LabTabAvancement.Caption                   := GetTexteLibelle('RULES-LAB_098');
    LabelCalcul.Caption                        := GetTexteLibelle('RULES-LAB_020');
    LabelXp.Caption                            := GetTexteLibelle('RULES-LAB_035');
    StaticTextPersonnage.Caption               := GetTexteLibelle('RULES-LAB_081');
    LabEquipement.Caption                      := GetTexteLibelle('RULES-LAB_100');
    ButtonAugmentation.Caption                 := GetTexteLibelle('RULES-LAB_101');
    ButtonSauvegarde.Caption                   := GetTexteLibelle('RULES-LAB_102');
    LabAugmentation.Caption                    := GetTexteLibelle('RULES-LAB_103');
    TabSheetAttribut.Caption                   := GetTexteLibelle('RULES-LAB_008');
    TabSheetTalent.Caption                     := GetTexteLibelle('RULES-LAB_007');
    TabSheetCompetence.Caption                 := GetTexteLibelle('RULES-LAB_009');
    TabSheetXP.Caption                         := GetTexteLibelle('RULES-LAB_104');
    TabSheetEvolution.Caption                  := GetTexteLibelle('RULES-LAB_105');
    TabSheetHistorique.Caption                 := GetTexteLibelle('RULES-LAB_036');
    TabSheetCorruption.Caption                 := GetTexteLibelle('RULES-LAB_156');
    TabSheetMutation.Caption                   := GetTexteLibelle('RULES-LAB_172');
    TabSheetPathologie.Caption                 := GetTexteLibelle('RULES-LAB_296')+'/'+GetTexteLibelle('RULES-LAB_281');
    ButtonCorruptionAjoute.Caption             := '+'+GetTexteLibelle('RULES-LAB_164');
    ButtonCorruptionSupprime.Caption           := '-'+GetTexteLibelle('RULES-LAB_165');
    ButtonRaceSelectionner.Caption             := GetTexteLibelle('RULES-LAB_004');
    ButtonHistorique.Caption                   := GetTexteLibelle('RULES-LAB_107');
    ButtonArme.Caption                         := '+'+GetTexteLibelle('RULES-LAB_063');
    ButtonArmure.Caption                       := '+'+GetTexteLibelle('RULES-LAB_065');
    ButtonSort.Caption                         := '+'+GetTexteLibelle('RULES-LAB_083');
    ButtonEquipement.Caption                   := '+'+GetTexteLibelle('RULES-LAB_202');
    ButtonTexte.Caption                        := '+'+GetTexteLibelle('RULES-LAB_644');
    ButtonObjet.Caption                        := '+'+GetTexteLibelle('RULES-LAB_648');
    ButtonSpecCompetence.Caption               := '+'+GetTexteLibelle('RULES-LAB_689');
    ButtonSpecTalent.Caption                   := '+'+GetTexteLibelle('RULES-LAB_689');
    LabTabNiveau.Caption                       := GetTexteLibelle('RULES-LAB_019');
    RadioButtonRAS.Caption                     := GetTexteLibelle('RULES-LAB_113');
    RadioButtonSuivant.Caption                 := GetTexteLibelle('RULES-LAB_114');
    RadioButtonChanger.Caption                 := GetTexteLibelle('RULES-LAB_115');
    ButtonFabrication.Caption                  := '+'+GetTexteLibelle('RULES-LAB_125');
    ButtonDelete.Caption                       := '-'+GetTexteLibelle('RULES-LAB_126');
    LabPorteAide.Caption                       := GetTexteLibelle('RULES-LAB_259');
    LabelNeedTheoXp.caption                    := GetTexteLibelle('RULES-LAB_131');
    LabelNeedRealXp.Caption                    := GetTexteLibelle('RULES-LAB_132');
    TabSheetLivre.Caption                      := GetTexteLibelle('RULES-LAB_128');
    TabSheetMjCost.Caption                     := GetTexteLibelle('RULES-LAB_140');
    // ListBoxExperience remplace la bande d'onglets de PageExperience (scission de
    // l'equipement, 24/09/2026) : reconstruit dans le meme ordre que les pages du
    // TNotebook (voir winpersonnage.lfm), ItemIndex preserve pour ne pas changer de
    // page en changeant de langue.
    IndSauve := ListBoxExperience.ItemIndex;
    ListBoxExperience.Items.Clear;
    ListBoxExperience.Items.Add(TabSheetAttribut.Caption);
    ListBoxExperience.Items.Add(TabSheetCompetence.Caption);
    ListBoxExperience.Items.Add(TabSheetTalent.Caption);
    ListBoxExperience.Items.Add(TabSheetXP.Caption);
    ListBoxExperience.Items.Add(TabSheetEvolution.Caption);
    ListBoxExperience.Items.Add(TabSheetHistorique.Caption);
    ListBoxExperience.Items.Add(TabSheetLivre.Caption);
    ListBoxExperience.Items.Add(TabSheetMjCost.Caption);
    ListBoxExperience.Items.Add(TabSheetCorruption.Caption);
    ListBoxExperience.Items.Add(TabSheetMutation.Caption);
    ListBoxExperience.Items.Add(TabSheetPathologie.Caption);
    ListBoxExperience.Items.Add(TabSheetAmbition.Caption);
    ListBoxExperience.Items.Add(TabSheetGroupe.Caption);
    PageReserve.Caption                        := GetTexteLibelle('RULES-LAB_654');
    ListBoxExperience.Items.Add(PageReserve.Caption);
    PageMonnaie.Caption                        := GetTexteLibelle('RULES-LAB_694');
    ListBoxExperience.Items.Add(PageMonnaie.Caption);
    PagePdf.Caption                            := GetTexteLibelle('RULES-LAB_691');
    ListBoxExperience.Items.Add(PagePdf.Caption);
    LabSansAsterisque.Caption                  := GetTexteLibelle('RULES-LAB_692');
    LabSansMontant.Caption                     := GetTexteLibelle('RULES-LAB_693');
    LabStylePdf.Caption                        := GetTexteLibelle('RULES-LAB_695');
    LabCouleurPdf.Caption                      := GetTexteLibelle('RULES-LAB_696');
    LabEconomiePdf.Caption                     := GetTexteLibelle('RULES-LAB_698');
    ListBoxExperience.ItemIndex                := IndSauve;
    LabQuickArmor.Caption                      := GetTexteLibelle('RULES-LAB_149');
    LabMunition.Caption                        := GetTexteLibelle('RULES-LAB_643');
    LabAge.Caption                             := GetTexteLibelle('RULES-PDF_MAIN4_AGE');
    LabHeight.Caption                          := GetTexteLibelle('RULES-PDF_MAIN4_HEIGHT');
    LabHairColors.Caption                      := GetTexteLibelle('RULES-PDF_MAIN4_HAIR');
    LabEyeColors.Caption                       := GetTexteLibelle('RULES-PDF_MAIN4_EYES');
    ButtonPhysique.Caption                     := GetTexteLibelle('RULES-LAB_266');

    ButtonHistorique.BringToFront;
    StringGridCorruption.BringToFront;
    ButtonCorruptionAjoute.BringToFront;
    ButtonCorruptionSupprime.BringToFront;
    ButtonCorruptionMutation.BringToFront;
    // Nouvel onglet Mutations (CONTEXT.md §2.7, étape 7) - même piège TShape/BringToFront que
    // les autres contrôles d'onglet (CONTEXT.md §4).
    TabMutation.BringToFront;
    MemoMutationEffet.BringToFront;
    // Nouvel onglet commun Afflictions/Maladies (ajout du 27/09/2026) - meme piege
    // TShape/BringToFront que les autres controles d'onglet (CONTEXT.md §4).
    TabPathologie.BringToFront;
    MemoPathologieEffet.BringToFront;
    ButtonPathologieAjouteAffliction.BringToFront;
    ButtonPathologieAjouteDisease.BringToFront;

  end;

procedure TWinPersonnages.ChargeImageNiveau(Niveau: Integer);
  // pour afficher les images des niveaux
  begin
      Picture  := TPicture.Create;
      Bitmap   := TBitmap.Create;
      try
        // Le metier l'emporte sur l'ethnie : voir CheminNiveauImageMetierRace dans
        // ChargeMetier. Un metier ne declare un dossier que s'il vient d'un livre, et il
        // n'existe que si ce livre est charge - sa declaration prouve donc que le
        // supplement est actif. A defaut : ethnie, puis race, puis \PICTURES\NIV\.
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

// Recharge les icones et les couleurs de niveau pour l'ethnie du personnage affiche.
// Appelee a l'ouverture, RaceEnCours etant alors vide - donc dossier generique - puis a
// chaque affichage d'un personnage, son ethnie pouvant designer son propre dossier.
procedure TWinPersonnages.ChargeImagesNiveau();
  var
    IndNiv: Integer;
    MaxNiv: Integer;
  begin
    if not Assigned(ListImage) then
      ListImage := TImageList.Create(nil);
    ListImage.Clear;
    SetLength(ColorList, 0);
    // Dimensionne sur la donnee et non sur une constante. Cette fenetre montait deja a 7
    // "au cas ou" ; le maximum reel remplace cette marge arbitraire.
    // Pas MaxNiveauMetier : le dossier NIV contient aussi des pastilles de couleur
    // rangees apres le dernier niveau. Voir MaxIndiceIconeNiveau.
    MaxNiv := MaxIndiceIconeNiveau();
    SetLength(ColorList, MaxNiv + 1);
    For IndNiv := 0 to MaxNiv Do
      ChargeImageNiveau(IndNiv);
  end;

procedure TWinPersonnages.TabAttributDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
  var
    ImageIndex: Integer;
    CellWidth, CellHeight: Integer;
    MaxWidth, MaxHeight, ImageWidth, ImageHeight: Integer;
    AspectRatio: Double;
    LeftOffset, TopOffset: Integer;
    ImageRect: TRect;
    TopLeftPixelColor: TColor;
    Bitmap: TBitmap;

    CellText: string;
    TextWidth: Integer;
    TextX: Integer;
    TextY: Integer;
  begin
    if aRow = 0 then
      begin

        // Dessiner le texte de l'entête centré horizontalement et verticalement
        TabAttribut.Canvas.Font.Color := clWhite;
        TabAttribut.Canvas.Font.Style := [fsBold];
        TabAttribut.Canvas.Font.Size  := 10;
        TabAttribut.Canvas.Font.Name  := ConstPoliceArial;

        // Calculer la position x et y du texte pour l'alignement centré
        if aCol > 0 then
        begin
          // Dessiner le fond de la cellule de l'entête
          TabAttribut.Canvas.Brush.Color := clBlack;
          TabAttribut.Canvas.FillRect(aRect);
          CellText  := TabAttribut.Columns[aCol-1].Title.Caption; //TabAttribut.Cells[aCol, aRow];
          TextWidth := TabAttribut.Canvas.TextWidth(CellText);
          TextX     := aRect.Left + (aRect.Right - aRect.Left - TextWidth) div 2;
          TextY     := aRect.Top + (aRect.Bottom - aRect.Top - TabAttribut.Canvas.TextHeight(CellText)) div 2;

          // Dessiner le texte de l'entête
          TabAttribut.Canvas.TextRect(aRect, TextX, TextY, CellText);
        end;
      end
    else if (aRow = LigAttImage) then
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
          LeftOffset:= (CellWidth - ImageWidth) div 2;
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
    else
      begin
        // Obtenir la couleur du pixel en haut à gauche de l'image de la cellule précédente (colonne 2)
        Bitmap := TBitmap.Create;
        try
          ImageIndex := StrToIntDef(TabAttribut.Cells[aCol, LigAttImage], -1);
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

        // Calculer la position x du texte pour l'alignement horizontal centré
        // en utilisant la largeur de la cellule et la largeur du texte
        CellText := TabAttribut.Cells[aCol, aRow];
        TextWidth := TabAttribut.Canvas.TextWidth(CellText);
        TextX := aRect.Left + (aRect.Right - aRect.Left - TextWidth) div 2;

        // Dessiner le texte avec l'alignement vertical centré
        TabAttribut.Canvas.FillRect(aRect);
        TabAttribut.Canvas.TextRect(aRect, TextX, aRect.Top + (aRect.Bottom - aRect.Top - TabAttribut.Canvas.TextHeight(CellText)) div 2, CellText);
      end;
  end;

Function TWinPersonnages.CalculXpMj(TypeDonnee: String; CodeDonnee:String): Integer;
  var
    IndLig:    Integer;
    Total:     Integer;
    Ajoute:    Boolean;
  begin
    Total := 0;
    For IndLig := 1 to TabAugmentationMjXp.RowCount-1 do
      begin
        if (TabAugmentationMjXp.Cells[ColAugmMjXpType, IndLig] = TypeDonnee) then
          begin
            // Code prefixe EN PREMIER : CompareRechercheValeur n'est pas symetrique, elle
            // n'accepte le livre absent que sur le second argument.
            if TypeDonnee = ConstXmlCarac then
              Ajoute := CompareRechercheValeur(TabAugmentationMjXp.Cells[ColAugmMjXpCode, IndLig], CodeDonnee)
            else
              Ajoute := (TabAugmentationMjXp.Cells[ColAugmMjXpCode, IndLig] = CodeDonnee);
            if Ajoute then
              Total := Total
                       - StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpCout, IndLig],0)
                       + StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpReel, IndLig],0);
          end;
      end;
    if (CheckBoxXpDiv25.checked = True) then
       Total := Total * 25;
    result := total;
  end;

procedure TWinPersonnages.CalculTotaux();
  Var
    IndCol:              Integer;
    Total:               Integer = 0;
    IndLig:              Integer;
    TabAtt:              String;
    TabComp:             String;
    IndAugm:             Integer;
    IndOld:              Integer;
    PersonnageAttribut:  StructurePersonnageAttribut;
    PersonnageCompetence:StructurePersonnageCompetence;
    PersonnageTalent:    StructurePersonnageTalent;
    PersonnageEquipement:StructurePersonnageEquipement;
    OldAugmentationTalent: TArrayPersonnageTalent;
    DonneeAttribut:      StructureDonnee;
    DonneeCompetence:    StructureDonnee;
    Bonus:               String;
    NivMetier:           Integer;
    ValCareer:           Integer;
    ValObjet:            Integer;
    ValSigne:            Integer;
  begin
    // Personnage.AugmentationAttribut n'est normalement resynchronise depuis la grille
    // TabAttribut qu'a l'interieur de CalculTableExperience (juste avant la sauvegarde) -
    // trop tard pour PdfPersonnageAttribut ci-dessous, appele ICI. Meme source que le
    // resync fait avant sauvegarde (winpersonnage.pas ~l.4859), refait ici pour que
    // Personnage soit a jour a chaque recalcul d'ecran, pas seulement a la sauvegarde.
    // CONTEXT.md, chantier accesseur unique, pilote Attributs.
    Personnage.AugmentationAttribut := [];
    // Les indices sont des COLONNES (une par caracteristique) : ColCount, pas RowCount. Les deux
    // valaient 15 jusqu'a l'ajout de LigAttSigne, d'ou un decalage qui ne se voyait pas.
    For IndAugm := 1 to TabAttribut.ColCount - 1 do
      if StrToIntDef(TabAttribut.Cells[IndAugm, LigAttBonus],0) > 0 then
        begin
          PersonnageAttribut.CodeAttribut  := TabAttribut.Cells[IndAugm, LigAttCode];
          PersonnageAttribut.Valeur        := StrToIntDef(TabAttribut.Cells[IndAugm, LigAttBonus],0);
          Personnage.AugmentationAttribut  += [PersonnageAttribut];
        end;

    // Meme raisonnement pour Personnage.AugmentationCompetence, lu par PdfPersonnageCompetence
    // plus bas (etape Competences de l'accesseur unique, CONTEXT.md 10/09/2026) : sans ce
    // resync ici, PdfPersonnageCompetence lirait une valeur en retard d'un cycle, celle laissee
    // par le dernier CalculTableExperience. Meme source (TabCompetence.Cells[ColCompWork, ...])
    // et meme forme que le resync deja fait avant sauvegarde (winpersonnage.pas ~l.4892).
    Personnage.AugmentationCompetence := [];
    For IndAugm := 1 to TabCompetence.Rowcount - 1 do
      if StrToIntDef(TabCompetence.Cells[ColCompWork, IndAugm],0) > 0 then
        begin
          PersonnageCompetence.CodeCompetence := TabCompetence.Cells[ColCompCode, IndAugm];
          PersonnageCompetence.Valeur         := StrToIntDef(TabCompetence.Cells[ColCompWork, IndAugm],0);
          Personnage.AugmentationCompetence   += [PersonnageCompetence];
        end;

    // Meme raisonnement pour Personnage.AugmentationTalent et Personnage.Equipement : lus
    // par PdfPersonnageAttribut/PdfPersonnageCompetence ci-dessous (talent a bonus direct
    // d'Attribut/Competence, arme/armure magique), residu du chantier accesseur unique
    // laisse ouvert le 11/09/2026 (CONTEXT.md 2.52). Meme source et meme forme que le
    // resync deja fait avant sauvegarde (winpersonnage.pas ~l.4922 et ~l.4932).
    // OldAugmentationTalent conserve l'Asterisque deja calcule par PersonnageXmlChargement
    // (chargepersonnage.pas) avant que ce resync ne remplace le tableau - sans quoi la
    // variable locale PersonnageTalent, jamais remise a zero explicitement ci-dessous,
    // ferait heriter chaque talent reconstruit de l'Asterisque laisse par l'appel
    // precedent (meme famille de piege que PersonnageTalentAsterisque). Signale par Nono
    // le 11/09/2026 sur Gunther Krieg (Strike Mighty Blow/Strike to Stun/Very Resilient/
    // Knight of the Order of the Hammer partageant tous "(4)" a tort).
    OldAugmentationTalent := Personnage.AugmentationTalent;
    Personnage.AugmentationTalent := [];
    for IndAugm := 1 to TabTalent.Rowcount - 1 do
      // <> 0, meme raison que l'autre resync (~l.5429) : une Vertu nommee porte un NbAugm
      // negatif volontaire. CONTEXT.md 2.78, prises multiples.
      if StrToIntDef(TabTalent.Cells[ColTalNbAugm, IndAugm],0) <> 0 then
        begin
          PersonnageTalent.CodeTalent    := TabTalent.Cells[ColTalCode, IndAugm];
          PersonnageTalent.Valeur        := StrToIntDef(TabTalent.Cells[ColTalNbAugm, IndAugm],0);
          PersonnageTalent.Asterisque    := 0;
          for IndOld := 0 to high(OldAugmentationTalent) do
            if CompareRechercheValeur(OldAugmentationTalent[IndOld].CodeTalent, PersonnageTalent.CodeTalent) then
              begin
                PersonnageTalent.Asterisque := OldAugmentationTalent[IndOld].Asterisque;
                break;
              end;
          Personnage.AugmentationTalent  += [PersonnageTalent];
        end;

    // Competence <Skill> d'un talent possede : ajoutee aux competences de carriere (Perfect Pitch -> Chant)
    PersonnageAppliqueTalentsCompetences(Personnage);

    // Un animal ajoute depuis le dernier chargement recoit son identifiant avant la copie.
    AttribueIdAnimaux;
    Personnage.Equipement := [];
    for IndAugm := 1 to TabEquipement.RowCount - 1 do
      begin
        PersonnageEquipement.CodeEquipement := TabEquipement.Cells[2, IndAugm];
        // Colonne 9 = Quantite (vide ou invalide = 1).
        PersonnageEquipement.Quantite       := StrToIntDef(TabEquipement.Cells[9, IndAugm], 1);
        if PersonnageEquipement.Quantite < 1 then PersonnageEquipement.Quantite := 1;
        PersonnageEquipement.IdInstance     := TabEquipement.Cells[10, IndAugm];
        PersonnageEquipement.NomLibre       := TabEquipement.Cells[13, IndAugm];
        PersonnageEquipement.EncLibre       := StrToIntDef(TabEquipement.Cells[14, IndAugm], 0);
        PersonnageEquipement.PortePar       := TabEquipement.Cells[11, IndAugm];
        If TalentSort(TabEquipement.Cells[2, IndAugm]).CodeTalent <> ''
           then
          begin
            PersonnageEquipement.TypeEquipement    := TypeEquipSp;
            PersonnageEquipement.QualiteEquipement := '';
            PersonnageEquipement.CoutXp            := CalculOptionXpDiv25Inverse(StrToIntDef(TabEquipement.Cells[5, IndAugm],0));
            PersonnageEquipement.Porte              := False;
          end
        else
          begin
            PersonnageEquipement.TypeEquipement    := TabEquipement.Cells[3, IndAugm];
            PersonnageEquipement.QualiteEquipement := TabEquipement.Cells[7, IndAugm];
            PersonnageEquipement.CoutXp            := 0;
            PersonnageEquipement.Porte              := TabEquipement.Cells[8, IndAugm] <> '';
          end;
        Personnage.Equipement += [PersonnageEquipement];
      end;

    // Attributs
    for IndCol := 2 to TabAttribut.ColCount-1 do
      begin
        // Bonus d'appartenance (Ordre/Regiment/Culte, CONTEXT.md §2.50/§2.51) et bonus
        // d'objet magique (arme/armure) - jusqu'ici invisibles a l'ecran, seulement pris en
        // compte dans LigAttTotal via PdfPersonnageAttribut plus bas, ce qui rendait le total
        // incomprehensible (Initial + Augmented <> Current des qu'un de ces bonus existait).
        // Signale par Nono le 12/09/2026 sur un Knight du Reiksguard (+10 Fel/+10 WP a
        // Knight of the Inner Circle) - CONTEXT.md §2.61 (suite).
        ValCareer := PersonnageCareerBonusAttributModif(Personnage, TabAttribut.Cells[IndCol, LigAttCode]);
        ValObjet  := PersonnageArmeAttributModif(Personnage, TabAttribut.Cells[IndCol, LigAttCode])
                     + PersonnageArmureBonusAttributModif(Personnage, TabAttribut.Cells[IndCol, LigAttCode])
                     + PersonnageFabricationAttributModif(Personnage, TabAttribut.Cells[IndCol, LigAttCode]);
        if ValCareer <> 0 then
          TabAttribut.Cells[IndCol, LigAttCareer] := IntToStr(ValCareer);
        if ValObjet <> 0 then
          TabAttribut.Cells[IndCol, LigAttObjet] := IntToStr(ValObjet);
        // Signe astral : meme raison, sans cette ligne Initial + Augmented <> Current
        ValSigne  := SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, TabAttribut.Cells[IndCol, LigAttCode]);
        if ValSigne <> 0 then
          TabAttribut.Cells[IndCol, LigAttSigne] := IntToStr(ValSigne);

        Total  := StrToIntdef(TabAttribut.Cells[IndCol, LigAttRace],0) +
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttLance],0)+
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttTalent],0)+
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttMutation],0)+
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttPathologie],0)+
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttCareer],0)+
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttObjet],0)+
                  StrToIntdef(TabAttribut.Cells[IndCol, LigAttSigne],0);
        TabAttribut.Cells[IndCol, LigAttBase] := IntToStr(Total);
        // Total toujours calcule par l'accesseur unique PdfPersonnageAttribut (deja utilise
        // par le PDF), qui reste la source de verite - LigAttBase ci-dessus n'est qu'un
        // detail affiche a l'ecran, desormais complet (Career/Objet inclus ci-dessus) donc
        // Initial + Augmented = Current.
        DonneeAttribut := PdfPersonnageAttribut(Personnage, TabAttribut.Cells[IndCol, LigAttCode], Bonus);
        TabAttribut.Cells[IndCol, LigAttTotal]:= IntToStr(DonneeAttribut.Total);
      end;

    // Compétences
    for IndLig := 1 to TabCompetence.RowCount-1 do
      begin
        for IndCol := 1 to TabAttribut.Colcount-1 do
          begin
            TabAtt := TabAttribut.Cells[IndCol, LigAttcode];
            TabComp:= TabCompetence.Cells[ColCompStat, IndLig];
            if CompareRechercheValeur(TabComp, TabAtt) then
              begin
                TabCompetence.Cells[ColCompAtt, IndLig] := TabAttribut.Cells[IndCol, LigAttTotal];
                break
              end;
          end;
        // Bonus de Carriere sur cette Competence (pendant Competence de ValCareer sur
        // TabAttribut plus haut) - meme raison : sans cette colonne, ColCompAtt + ColCompBonus
        // ne retombait pas sur ColCompTotal des qu'un tel bonus existait, rendant le total
        // incomprehensible a l'ecran alors qu'il etait deja correct dans le PDF.
        ValCareer := PersonnageCareerBonusCompetenceModif(Personnage, TabCompetence.Cells[ColCompCode, IndLig]);
        if ValCareer <> 0 then
          TabCompetence.Cells[ColCompCareer, IndLig] := IntToStr(ValCareer);
        // ColCompMutation volontairement absent de ColCompBonus : ColCompBonus correspond aux
        // avancements réellement achetés (utilisé ailleurs, ex. ligne ~3814, pour calculer le
        // coût Xp / combien de compétences ont été augmentées) - un effet de mutation n'est
        // pas un avancement acheté, il ne doit compter que dans le Total. Signalé par Nono le
        // 17/08/2026 (même souci repéré côté PDF, corrigé en même temps dans pdfpersonnage.pas).
        TabCompetence.Cells[ColCompBonus, IndLig] := IntToStr(StrToIntDef(TabCompetence.Cells[ColComp35, IndLig],0) +
                                                              StrToIntDef(TabCompetence.Cells[ColComp40, IndLig],0) +
                                                              StrToIntDef(TabCompetence.Cells[ColCompWork, IndLig],0) +
                                                              StrToIntDef(TabCompetence.Cells[ColCompAppartenance, IndLig],0));
        // Total desormais calcule par l'accesseur unique PdfPersonnageCompetence (deja utilise
        // par le PDF), meme demarche que pour les Attributs ci-dessus : il ajoute notamment les
        // bonus d'appartenance (Ordre/Regiment) et d'armure sur une Competence, absents de
        // l'addition locale precedente (ColCompBonus + ColCompAtt + ColCompMutation).
        DonneeCompetence := PdfPersonnageCompetence(Personnage, TabCompetence.Cells[ColCompCode, IndLig], NivMetier);
        TabCompetence.Cells[ColCompTotal, IndLig] := IntToStr(DonneeCompetence.Total);
      end;

    // Les valeurs viennent d'etre recalculees : une ligne ou colonne de detail peut apparaitre
    // ou disparaitre (regle des lignes vides).
    if AjusteDetailsCalcul() then
      AjustePositionTables();
  end;

procedure TWinPersonnages.TabAttributSelectEditor(Sender: TObject; aCol,
    aRow: Integer; var Editor: TWinControl);
  begin
    Editor := nil;
  end;

procedure TWinPersonnages.TabAugmentationAttributEditingDone(Sender: TObject);
  var
    Value: String;
  begin
    if TabAugmentationAttribut.Col = ColAugmAttNouveau then
      begin
        Value := TabAugmentationAttribut.Cells[ColAugmAttNouveau, TabAugmentationAttribut.Row];
        TabAugmentationAttributCalcul(TabAugmentationAttribut.Row, Value);
        TabAugmentationAttribut.Cells[ColAugmAttNouveau, TabAugmentationAttribut.Row] := Value;
      end
    else if TabAugmentationAttribut.Col = ColAugmAttReel then
      CalculTableExperience();
  end;

procedure TWinPersonnages.TabAugmentationAttributKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  Value: String = '0';
begin
  if ((Key >= 96) and (Key <= 106)) or (Key = 8) then
    if TabAugmentationAttribut.Col = ColAugmAttNouveau then
      begin
         if TabAugmentationAttribut.Cells[ColAugmAttNouveau, TabAugmentationAttribut.row] <> '' then
          Value := TabAugmentationAttribut.Cells[ColAugmAttNouveau, TabAugmentationAttribut.row];
        TabAugmentationAttributCalcul(TabAugmentationAttribut.Row, Value);
        if Value = '0' then Value := '';
        TabAugmentationAttribut.Cells[ColAugmAttNouveau, TabAugmentationAttribut.Row] := Value;
      end
    else if TabAugmentationAttribut.Col = ColAugmAttReel then
      CalculTableExperience();
end;

procedure TWinPersonnages.TabAugmentationAttributMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Nouveau: Integer = 0;
  aRow:    Integer = 0;
  aCol:    Integer = 0;
  Value:   String;
begin
  TabAugmentationAttribut.MouseToCell(X, Y, ACol, ARow);
  if (aRow > 0) and ((aCol = colAugmAttPlus5) or (aCol = ColAugmAttMoins5)) then
    begin
      Nouveau := StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttNouveau, ARow],0);
       if aCol = colAugmAttPlus5 then
         Nouveau += 5
       else if aCol = colAugmAttMoins5 then
         if (Nouveau - 5) >= StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttActuel, ARow],0) then
           Nouveau -= 5;
       Value := IntToStr(Nouveau);
       TabAugmentationAttributCalcul(ARow, Value);
       if Value = '0' then
         Value := '';
       TabAugmentationAttribut.Cells[ColAugmAttNouveau, ARow] := Value;
       CalculTableExperience();
    end;
end;

procedure TWinPersonnages.TabAugmentationCompetenceEditingDone(Sender: TObject);
  var
    Value: String;
  begin
    if TabAugmentationCompetence.Col = ColAugmCompNouveau then
      begin
        Value := TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row];
        TabAugmentationCompetenceCalcul(TabAugmentationCompetence.Row, Value);
        TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row] := Value;
      end
    else if TabAugmentationCompetence.Col = ColAugmCompReel then
      CalculTableExperience();

  end;

procedure TWinPersonnages.TabAugmentationCompetenceKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
  var
    Value: String = '0';
  begin
    if ((Key >= 96) and (Key <= 106)) or (Key = 8) then
      if TabAugmentationCompetence.Col = ColAugmCompNouveau then
        begin
          if TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row] <> '' then
            Value := TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row];
          TabAugmentationCompetenceCalcul(TabAugmentationCompetence.Row, Value);
          if Value = '0' then Value := '';
          TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row] := Value;
        end
      else if TabAugmentationCompetence.Col = ColAugmCompReel then
        CalculTableExperience();
  end;

procedure TWinPersonnages.TabAugmentationCompetenceMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  var
    Nouveau: Integer = 0;
    aRow:    Integer = 0;
    aCol:    Integer = 0;
    Value:   String;
  begin
    TabAugmentationCompetence.MouseToCell(X, Y, ACol, ARow);
    if (aRow > 0) and ((aCol = colAugmCompPlus5) or (aCol = ColAugmCompMoins5)) then
      begin
        Nouveau := StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompNouveau, ARow],0);
         if aCol = colAugmCompPlus5 then
           Nouveau += 5
         else if aCol = colAugmCompMoins5 then
           if (Nouveau - 5) >= StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompActuel, ARow],0) then
             Nouveau -= 5;
         Value := IntToStr(Nouveau);
         TabAugmentationCompetenceCalcul(ARow, Value);
         if Value = '0' then
           Value := '';
         TabAugmentationCompetence.Cells[ColAugmCompNouveau, ARow] := Value;
         CalculTableExperience();
      end;
  end;
procedure TWinPersonnages.TabAugmentationCompetenceDblClick(Sender: TObject);
  var
    Ind:         Integer;
    Trouve:      Boolean = false;
    PCompetence: StructureCompetence;
    Value:       String;
    Ind2:        Integer;
  begin
    if (TabAugmentationCompetence.Col = ColAugmCompSpe) and (TabAugmentationCompetence.Cells[ColAugmCompSpe, TabAugmentationCompetence.Row] = GetTexteLibelle(ConstLabSelSpe))  then
      begin
        // ajouter une spécialité
        ChoixWinTypeFichier         := ConstXmlSousChapitreCompetence;
        ChoixWinCompetence          := TabAugmentationCompetence.Cells[ColAugmCompCode, TabAugmentationCompetence.Row];
        SelectWinLivre              := Personnage.LivresAcceptes;
        // les specialisations propres du personnage vivent dans le livre virtuel des objets propres
        if SelectWinLivre <> '' then
          SelectWinLivre := SelectWinLivre + AjouteAccolade(ConstLivreObjetsPropres);
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        SelectWinLivre := '';
        if SelectWinCompetence <> '' then
          begin
            TabAugmentationCompetence.Cells[ColAugmCompSpe, TabAugmentationCompetence.Row]    := GetTexteLibelle('RULES-LAB_130');
            TabAugmentationCompetence.Cells[ColAugmCompSpeSel, TabAugmentationCompetence.Row] := SelectWinCompetence;
            PCompetence                                                                       := ChercheCompetence(SelectWinCompetence);

            TabAugmentationCompetence.Cells[ColAugmCompLib, TabAugmentationCompetence.Row] := PCompetence.Libelle;

            // A - récupérer la valeur si la spécialisation existe déjà (AVANT tout renommage)
            for Ind := 1 to TabCompetence.RowCount - 1 do
              if TabCompetence.Cells[ColCompCode, Ind] = SelectWinCompetence then
                begin
                  Value := TabCompetence.Cells[ColCompBonus, Ind];
                  if TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row]
                     = TabAugmentationCompetence.Cells[ColAugmCompActuel, TabAugmentationCompetence.Row] then
                    TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row] := Value;
                  TabAugmentationCompetence.Cells[ColAugmCompActuel, TabAugmentationCompetence.Row] := Value;
                  Value := TabAugmentationCompetence.Cells[ColAugmCompNouveau, TabAugmentationCompetence.Row];
                  TabAugmentationCompetenceCalcul(TabAugmentationCompetence.Row, Value);
                  break;
                end;

            // B - le choix devient le code de référence de la ligne
            TabAugmentationCompetence.Cells[ColAugmCompCode, TabAugmentationCompetence.Row] := SelectWinCompetence;

            // C - propager au tableau métier (persistance)
            for Ind2 := 0 to High(Personnage.MetierCompetence) do
              if Personnage.MetierCompetence[Ind2].CodeCompetence = ChoixWinCompetence then
                begin
                  Personnage.MetierCompetence[Ind2].CodeCompetence := SelectWinCompetence;
                  break;
                end;
          end;
      end
    else if (TabAugmentationCompetence.Col = ColAugmCompLib) and (TabAugmentationCompetence.Cells[ColAugmCompLib, TabAugmentationCompetence.Row] = GetTexteLibelle(ConstLabAdd))  then
      begin
        // ajouter une compétence
        ChoixWinTypeFichier         := ConstXmlSousChapitreCompetence;
        ChoixWinCompetence          := '';
        FenCompetence               := TWinCompetence.Create(Application);
        FenCompetence.Position      := poOwnerFormCenter;
        FenCompetence.ShowModal;
        if SelectWinCompetence <> '' then
          begin
            // vérifier que cela n'existe pas déjà dans la table
            for Ind := 1 to TabAugmentationCompetence.RowCount - 1 do
              if SelectWinCompetence = TabAugmentationCompetence.Cells[ColAugmCompCode, Ind] then
                begin
                  trouve := true;
                  break;
                end;
            if Trouve then
               ShowMessage(GetTexteLibelle('RULES-MESS_047'))  // déjà présent
            else
              begin
                // ajouter la compétence et ajouter une nouvelle ligne dans la table
                PCompetence                                                                     := ChercheCompetence(SelectWinCompetence);
                TabAugmentationCompetence.Cells[ColAugmCompCode, TabAugmentationCompetence.Row] := PCompetence.CodeCompetence;
                TabAugmentationCompetence.Cells[ColAugmCompLib, TabAugmentationCompetence.Row]  := PCompetence.Libelle;
                AugmentationAjouteXpMj(ConstXmlCompetence);
              end;
          end;
      end
    else if (TabAugmentationCompetence.Col <> ColAugmCompPlus5) and (TabAugmentationCompetence.Col <> ColAugmCompMoins5) then
      begin
        // ouvrir les compétence
        SelectWinCompetence     := TabAugmentationCompetence.Cells[ColAugmCompCode,TabAugmentationCompetence.Row];
        FenCompetence           := TWinCompetence.Create(Application);
        FenCompetence.Position  := poOwnerFormCenter;
        FenCompetence.ShowModal;
      end;
    SelectWinCompetence     := '';
    MajBoutonsSpecialisation(0, 0);
  end;

procedure TWinPersonnages.TabAugmentationTalentDblClick(Sender: TObject);
  var
    PTalent:  StructureTalent;
    PSort:    StructureSort;
    Ind:      Integer;
    Ind2:     Integer;
    Trouve:   Boolean = false;
    NbMaxGen: Integer;
    DejaPris: Boolean;
  begin
    if (TabAugmentationTalent.Col = ColAugmTalSpe) and (TabAugmentationTalent.Cells[ColAugmTalSpe, TabAugmentationTalent.Row] = GetTexteLibelle(ConstLabSelSpe))  then
      begin
        ChoixWinTypeFichier         := ConstXmlSousChapitreTalent;
        ChoixWinTalent              := TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row];

        // Grail Virtue (NATIO-T0002_*) : le livre exige d'avoir deja la Knightly Virtue du
        // meme nom (Nations of Mankind p.13) - le pool propose a WinSpecialisation est
        // donc restreint aux noms deja RESOLUS en NATIO-T0001_* sur TabTalent (exclut le
        // code generique lui-meme, au cas ou une ligne serait restee non specialisee). Un
        // seul consommateur aujourd'hui, code en dur comme le fut le SkillChoice du
        // Reiksguard avant lui (2.51). CONTEXT.md 2.78.
        if ChoixWinTalent = 'NATIO-T0002_*' then
          begin
            ChoixWinVertuGrail := '';
            for Ind := 1 to TabTalent.RowCount - 1 do
              if (Pos('NATIO-T0001_', TabTalent.Cells[ColTalCode, Ind]) = 1) and
                 (TabTalent.Cells[ColTalCode, Ind] <> 'NATIO-T0001_*') then
                begin
                  if ChoixWinVertuGrail <> '' then
                    ChoixWinVertuGrail := ChoixWinVertuGrail + ',';
                  ChoixWinVertuGrail := ChoixWinVertuGrail + 'NATIO-T0002_' +
                                        ExtractStringAfter(TabTalent.Cells[ColTalCode, Ind], 'NATIO-T0001_');
                end;
            if ChoixWinVertuGrail = '' then
              begin
                ShowMessage(GetTexteLibelle('RULES-MESS_063'));
                Exit;
              end;
          end;

        SelectWinLivre              := Personnage.LivresAcceptes;
        if SelectWinLivre <> '' then
          SelectWinLivre := SelectWinLivre + AjouteAccolade(ConstLivreObjetsPropres);
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        SelectWinLivre     := '';
        ChoixWinVertuGrail := '';    // remise a vide obligatoire, meme raison que SelectWinLivre juste au-dessus
        if SelectWinTalent <> '' then
          begin
            // Anti-doublon : une specialisation deja prise (Audacity...) ne doit pas
            // pouvoir etre reprise une deuxieme fois - necessaire des qu'un talent
            // generique a plusieurs prises distinctes (Max>1, ex. Knightly Virtue) peut
            // etre re-propose plusieurs sessions de suite, chaque fois avec le pool
            // complet des noms. CONTEXT.md 2.78, prises multiples.
            DejaPris := false;
            for Ind := 1 to TabTalent.RowCount - 1 do
              if TabTalent.Cells[ColTalCode, Ind] = SelectWinTalent then
                DejaPris := true;
            if DejaPris then
              begin
                ShowMessage(GetTexteLibelle('RULES-MESS_047'));
                SelectWinTalent := '';
                Exit;
              end;

            TabAugmentationTalent.Cells[ColAugmTalSpe, TabAugmentationTalent.Row] := GetTexteLibelle('RULES-LAB_130');
            TabAugmentationTalent.Cells[ColAugmTalSpeSel, TabAugmentationTalent.Row] := SelectWinTalent;
            PTalent := ChercheTalent(SelectWinTalent);
            TabAugmentationTalent.Cells[ColAugmTalLib, TabAugmentationTalent.Row] := PTalent.Libelle;

            // A - récupérer la valeur si le talent choisi existe déjà dans la fiche
            for Ind := 1 to TabTalent.RowCount - 1 do
              if TabTalent.Cells[ColTalCode, Ind] = SelectWinTalent then
                begin
                  TabAugmentationTalent.Cells[ColAugmTalActuel, TabAugmentationTalent.Row]  := TabTalent.Cells[ColTalNb, Ind];
                  if TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.Row] = '' then
                    TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.Row] := TabTalent.Cells[ColTalNb, Ind];
                  break;
                end;

            // B - le choix devient le code de référence de la ligne
            TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row] := SelectWinTalent;

            // C - propager au tableau métier (persistance) - SAUF pour un talent
            // generique a plusieurs prises distinctes (Max>1) : le remplacer figerait la
            // carriere sur cette seule Vertu et empecherait d'en reprendre une autre a la
            // prochaine session. Le code generique doit rester en place dans
            // Personnage.MetierTalent pour que la case carriere reste proposable (elle est
            // retrouvee et comptee separement via une ligne dediee dans TabTalent, voir
            // MajTables). CONTEXT.md 2.78, prises multiples.
            if not (TryStrToInt(ChercheTalent(ChoixWinTalent).MaxiTalent, NbMaxGen) and (NbMaxGen > 1)) then
              for Ind2 := 0 to High(Personnage.MetierTalent) do
                if Personnage.MetierTalent[Ind2].CodeTalent = ChoixWinTalent then
                  begin
                    Personnage.MetierTalent[Ind2].CodeTalent := SelectWinTalent;
                    break;
                  end;

            // D - recalculer les sorts accordes par ce talent, AVEC la specialisation.
            // Sans cet appel, SortAffiche n'avait tourne qu'a la saisie de la colonne
            // "Nouveau", donc AVANT ce choix : la ligne portait encore le code generique
            // RULES-T0012_*, qui ne correspond a aucune benediction (elles citent le dieu,
            // RULES-T0012_SIGMAR). TabSort restait vide, et MajTables ne fait que recopier
            // TabSort dans la fiche - d'ou un pretre sans aucune benediction. Trouve par
            // Nono le 03/09/2026 sur "pretre 2". Meme famille que CONTEXT.md 2.18.
            SortAffiche();
          end;
      end
    else if (TabAugmentationTalent.Col = ColAugmTalSort) and (TabAugmentationTalent.Cells[ColAugmTalSort, TabAugmentationTalent.Row] <> '') then
      begin
        // Choisir le sort precis d'un talent ModeSort=CHOIX (un Miracle se choisit,
        // contrairement a une Benediction qui est automatique - voir SortAffiche, qui pose
        // cette colonne). Meme principe que TabSortDblClick, qui ne depend pas de la
        // validation : SelectWinSort filtre sur le code du talent (specialisation deja
        // resolue sinon code generique), jamais sur TabTalent qui ne contient pas encore ce
        // talent tant que Valider n'a pas ete clique - c'est precisement ce qui bloquait le
        // bouton +Spell (A FAIRE.txt, tentative AjoutMineur du 18/09/2026).
        if TabAugmentationTalent.Cells[ColAugmTalSpeSel, TabAugmentationTalent.Row] <> '' then
          SelectWinSort := TabAugmentationTalent.Cells[ColAugmTalSpeSel, TabAugmentationTalent.Row]
        else
          SelectWinSort := TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row];
        SelectWinLivre    := Personnage.LivresAcceptes;
        FenSort           := TWinSpells.Create(Application);
        FenSort.Position  := poOwnerFormCenter;
        FenSort.ShowModal;
        if ChoixWinSort <> '' then
          begin
            PSort                                                                    := ChercheSort(ChoixWinSort);
            TabAugmentationTalent.Cells[ColAugmTalSort, TabAugmentationTalent.Row]    := PSort.Libelle;
            TabAugmentationTalent.Cells[ColAugmTalSortSel, TabAugmentationTalent.Row] := PSort.CodeSort;
          end;
        SelectWinSort  := '';
        SelectWinLivre := '';
        ChoixWinSort   := '';
      end
    else if (TabAugmentationTalent.Col = ColAugmTalLib) and (TabAugmentationTalent.Cells[ColAugmTalLib, TabAugmentationTalent.Row] = GetTexteLibelle(ConstLabAdd))  then
      begin
        // ajouter un talent
        ChoixWinTypeFichier     := ConstXmlSousChapitreTalent;
        ChoixWinTalent          := '';
        FenTalent               := TWintTalent.Create(Application);
        FenTalent.Position      := poOwnerFormCenter;
        FenTalent.ShowModal;
        if SelectWinTalent <> '' then
          begin
            // vérifier que cela n'existe pas déjà dans la table
            for Ind := 1 to TabAugmentationTalent.RowCount - 1 do
              if SelectWinTalent = TabAugmentationTalent.Cells[ColAugmTalCode, Ind] then
                begin
                  trouve := true;
                  break;
                end;
            if Trouve then
               ShowMessage(GetTexteLibelle('RULES-MESS_047'))  // déjà présent
            else
              begin
                // ajouter le talent et ajouter une nouvelle ligne dans la table
                PTalent                                                                := ChercheTalent(SelectWinTalent);
                TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row] := PTalent.CodeTalent;
                TabAugmentationTalent.Cells[ColAugmtalLib, TabAugmentationTalent.Row]  := PTalent.Libelle;
                AugmentationAjouteXpMj(ConstXmlTalent);
              end;
          end;
      end
    // Un choix multiple 'A/B' non resolu (ex. RULES-T0161/NATIO-T0015_*, Norscan Mercenary)
    // n'existe comme code litteral dans aucune entree du catalogue - WinTalent.WinCharger
    // ne trouve alors aucune ligne et TabTalentSelection(Self,1,1), appele sans garde juste
    // apres, plante (EGridException Cell[Col=1 Row=1]). Releve par Nono le 18/09/2026 en
    // double-cliquant le libelle (colonne Lib, pas la colonne "choisir spe") de Mark of the
    // Gods via Norscan Mercenary. Un '_*' seul (generique non specialise) ne plante pas : son
    // entree generique existe litteralement dans le catalogue.
    else if Pos(SeparateurMulti, TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row]) = 0 then
      begin
        // ouvrir les Talents
        SelectWinTalent     := TabAugmentationTalent.Cells[ColAugmTalCode, TabAugmentationTalent.Row];
        FenTalent           := TWintTalent.Create(Application);
        FenTalent.Position  := poOwnerFormCenter;
        FenTalent.ShowModal;
        ChoixWinTalent      := '';
      end;
    SelectWinTalent := '';
    MajBoutonsSpecialisation(0, 0);
  end;

procedure TWinPersonnages.TabAugmentationTalentEditingDone(Sender: TObject);
  var
    Value: String;
  begin
    if TabAugmentationTalent.Col = ColAugmTalNouveau then
      begin
        Value := TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.Row];
        TabAugmentationTalentCalcul(TabAugmentationTalent.Row, Value);
        TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.Row] := Value;
      end
    else if TabAugmentationTalent.Col = ColAugmTalReel then
      CalculTableExperience();
  end;

procedure TWinPersonnages.TabAugmentationTalentKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
  var
    Value: String = '0';
  begin
    if ((Key >= 96) and (Key <= 106)) or (Key = 8) then
      if TabAugmentationTalent.Col = ColAugmTalNouveau then
        begin
          SortAffiche();
          if TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.row] <> '' then
            Value := TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.row];
          TabAugmentationTalentCalcul(TabAugmentationTalent.row, Value);
          if Value = '0' then Value := '';
          TabAugmentationTalent.Cells[ColAugmTalNouveau, TabAugmentationTalent.row] := Value;
        end
      else if TabAugmentationTalent.Col = ColAugmTalReel then
        CalculTableExperience();
  end;

procedure TWinPersonnages.TabCarriereDblClick(Sender: TObject);
  begin
        // ouvrir les métiers
      SelectWinMetier     := TabCarriere.Cells[1,TabCArriere.Row];
      FenMetier           := TWinMetiers.Create(Application);
      FenMetier.Position  := poOwnerFormCenter;
      FenMetier.ShowModal;
      SelectWinMetier     := '';
  end;

procedure TWinPersonnages.TabCompetenceDblClick(Sender: TObject);
  begin
    // ouvrir les compétence
    SelectWinCompetence     := TabCompetence.Cells[1,TabCompetence.Row];
    FenCompetence           := TWinCompetence.Create(Application);
    FenCompetence.Position  := poOwnerFormCenter;
    FenCompetence.ShowModal;
    SelectWinCompetence     := '';
  end;

procedure TWinPersonnages.XmlChargePersonnageGeneral(const FileName: string);
begin

  Personnage := PersonnageXmlChargement(FileName);
  if (Pos(AjouteAccolade(ConstXmlOptionXpDiv25), Personnage.Options) > 0) then
    begin
      EditTotalXp25.Enabled     := True;
      EditTotalXp.Enabled       := False;
      CheckBoxXpDiv25.Checked   := True;
    end
  else
    begin
      EditTotalXp25.Enabled     := False;
      EditTotalXp.Enabled       := true;
    end;
  if (Pos(AjouteAccolade(ConstXmlOptionFeldo2P),Personnage.Options) > 0) then
    CheckBoxPdfFeldo2p.Checked:= True;
  if (Pos(AjouteAccolade(ConstXmlOptionQuickArmor),Personnage.Options) > 0) then
    CheckBoxQuickArmor.Checked:= True;
  // Munitions gerees par defaut (fiches existantes sans la balise).
  CheckBoxMunition.Checked := Pos(AjouteAccolade(ConstXmlOptionSansMunition), Personnage.Options) = 0;
  // Asterisques du PDF : affichees par defaut (fiches existantes sans la balise).
  CheckBoxSansAsterisque.Checked := Pos(AjouteAccolade(ConstXmlOptionSansAsterisque), Personnage.Options) > 0;
  CheckBoxSansMontant.Checked    := CheckBoxSansAsterisque.Checked
    or (Pos(AjouteAccolade(ConstXmlOptionSansMontant), Personnage.Options) > 0);
  CheckBoxSansMontant.Enabled    := not CheckBoxSansAsterisque.Checked;
  CheckBoxStylePdf.Checked       := Pos(AjouteAccolade(ConstXmlOptionStylePdf), Personnage.Options) > 0;
  CheckBoxCouleurPdf.Checked     := Pos(AjouteAccolade(ConstXmlOptionPdfSansCouleur), Personnage.Options) = 0;
  CheckBoxCouleurPdf.Enabled     := CheckBoxStylePdf.Checked;
  CheckBoxEconomiePdf.Checked    := Pos(AjouteAccolade(ConstXmlOptionPdfEconomie), Personnage.Options) > 0;
  CheckBoxEconomiePdf.Enabled    := CheckBoxStylePdf.Checked;

  // nom du joueur
  PersonnageNom.Caption     := Personnage.NomPersonnage;
  EditAge.Text              := IntToStr(Personnage.Age);
  // Dans l'unite de la fiche (Personnage.HeightUnit) ; WinPhysique permet d'en changer
  EditHeight.Text           := IntToStr(Personnage.Height);
  PlaceChampsMonnaie();   // cree les champs si besoin
  EditMonnaie[0].Text       := IntToStr(Personnage.MonnaieCO);
  EditMonnaie[1].Text       := IntToStr(Personnage.MonnaiePA);
  EditMonnaie[2].Text       := IntToStr(Personnage.MonnaieSB);
  EditHairColors.Text       := Personnage.HairColors;
  EditEyeColors.Text        := Personnage.EyeColors;
  // Signe astral (Archives of the Empire II) : lecture seule, choisi a la creation.
  EditSigne.Visible         := Personnage.SigneAstral <> '';
  if EditSigne.Visible then
    begin
      EditSigne.Text        := GetTexteLibelle('RULES-LAB_272') + ' : ' + ChercheSigneAstral(Personnage.SigneAstral).Libelle;
      EditSigne.Hint        := ResumeSigneAstral(Personnage.SigneAstral, Personnage.SigneAstralVariante);
      EditSigne.ShowHint    := True;
    end;
  // Texte brut (IntToStr), pas Format('%.0n',...) : cette case est relue et reparsee par
  // StrToIntDef/comparee en texte a EditTotalXp.Text (winpersonnage.pas, tests de validation
  // de carriere) - un separateur de milliers y faisait echouer StrToIntDef (0 renvoye) et
  // ratait toute comparaison avec EditTotalXp.Text, toujours brut. Meme format que l'ecriture
  // faite apres validation de carriere (MajTables) plus bas, qui etait deja brute.
  if (EditTotalXp25.Enabled = True) then
    tabExperience.Cells[ColXpDonnee, LigXpTotal] := IntToStr(Personnage.Xp25Total)
  else
    tabExperience.Cells[ColXpDonnee, LigXpTotal] := IntToStr(Personnage.XpTotal);
  // EditTotalXp/EditTotalXp25 lus par CalculTableExperience (Restant Xp) des le premier
  // recalcul declenche pendant ce chargement (l.~3291 plus bas) - sans cette init, le champ
  // est encore vide a ce moment-la et le Restant sort negatif (bug constate avec Nono le
  // 11/09/2026, apparu au premier calcul apres ouverture d'un personnage).
  EditTotalXp.text   := IntToStr(Personnage.XpTotal);
  EditTotalXp25.text := IntToStr(Personnage.Xp25Total);

  // Ambitions (saisie libre, WinAmbition) : apercu affiche dans TabAmbition, page dediee
  // de PageExperience (voir AfficheAmbition plus bas). 27/09/2026.
  AfficheAmbition();
  // Groupe (biens partages, WinGroupe) : meme principe, apercu dans TabGroupe. CONTEXT.md
  // 2.100, 27/09/2026.
  AfficheGroupe();
end;

procedure TWinPersonnages.XmlChargePersonnageRaceMetier();
var
  Nb:                    Integer = 1;
  PRace:                 StructureRace;
  PMetier:               StructureMetier;
  PAttribut:             StructureAttribut;
begin
  // Race
  RaceEnCours               := Personnage.Race;
  PRace                     := ChercheRace(RaceEnCours);
  LibRace.Caption           := PRace.Libelle;
  AfficheImageRace();

  // Metier
  PersonnageMetier := Personnage.MetierEnCours;
  MetierEnCours    := PersonnageMetier.CodeMetier;
  MetierNvEnCours  := IntToStr(PersonnageMetier.NiveauMetier);
  PMetier          := ChercheMetier(MetierEnCours);
  LibMetier.Caption:= PMetier.Libelle;
  // Appartenance (regiment, ordre de chevalerie, culte) - CONTEXT.md 2.44. Simple
  // affichage en lecture, la liste elle-meme se construit dans MajTables.
  LibAppartenance.Caption := LibelleAppartenances(Personnage.Appartenance);

  // Les icones de niveau sont rechargees ICI et pas plus haut : la resolution a besoin du
  // METIER autant que de l'ethnie, et MetierEnCours n'est connu qu'a partir de cette
  // ligne. Toujours AVANT que les grilles ne soient remplies et redessinees.
  ChargeImagesNiveau();

  AfficheImageMetier();

  // Attributs
  for PersonnageAttribut in Personnage.CreationAttribut do
    begin
      Inc(Nb);
      PAttribut                               := ChercheAttribut(PersonnageAttribut.CodeAttribut);
      TabAttribut.Columns[Nb-1].Title.Caption := PAttribut.Resume;
      TabAttribut.Cells[Nb, LigAttLance]      := IntToStr(PersonnageAttribut.Valeur);
    end;
end;

procedure TWinPersonnages.XmlChargePersonnageCompetencesTalentsAugmentations();
var
  IndTab:                Integer;
  NbTalent:              Integer = 0;
  NbCompetence:          Integer = 0;
  NbCarriere:            Integer = 0;
  Lig:                   Integer = 0;
  PTalent:               StructureTalent;
  PCompetence:           StructureCompetence;
  PMetier:               StructureMetier;
  PAttribut:             StructureAttribut;
  ValMutation:           Integer;
  ValTalent:             Integer;
  ValPathologie:         Integer;
begin
  // Lire les compétences de la sous-section COMP
  for PersonnageCompetence in Personnage.CreationCompetence35 do
    begin
      Lig  := FindRowByText(TabCompetence, PersonnageCompetence.CodeCompetence, ColCompCode);
      if Lig = -1 then
        begin
          NbCompetence            := NbCompetence + 1;
          TabCompetence.RowCount  := TabCompetence.RowCount + 1;
          Lig                     := NbCompetence;
        end;
      TabCompetence.Cells[ColCompCode , Lig] := PersonnageCompetence.CodeCompetence;
      if (CheckBoxXpDiv25.checked = true) then
        TabCompetence.Cells[ColComp35, Lig]  := IntToStr(5)
      else
        TabCompetence.Cells[ColComp35, Lig]  := IntToStr(PersonnageCompetence.Valeur);
      PCompetence                            := ChercheCompetence(TabCompetence.Cells[1, lig]);
      TabCompetence.Cells[ColCompLib, Lig]   := PCompetence.Libelle;
      TabCompetence.Cells[ColCompStat, Lig]  := PCompetence.CodeAttribut;
      PAttribut                              := ChercheAttribut(PCompetence.CodeAttribut);
      TabCompetence.Cells[ColCompCarac, Lig] := PAttribut.Resume;
    end;

  // Lire les compétences de la sous-section COMP
  for PersonnageCompetence in Personnage.CreationCompetence40 do
    begin
      Lig  := FindRowByText(TabCompetence, PersonnageCompetence.CodeCompetence, ColCompCode);
      if Lig = -1 then
        begin
          NbCompetence            := NbCompetence + 1;
          TabCompetence.RowCount  := TabCompetence.RowCount + 1;
          Lig                     := NbCompetence;
        end;
      TabCompetence.Cells[ColCompCode , Lig] := PersonnageCompetence.CodeCompetence;
      TabCompetence.Cells[ColComp40, Lig]    := IntToStr(PersonnageCompetence.Valeur);
      PCompetence                            := ChercheCompetence(TabCompetence.Cells[1, lig]);
      TabCompetence.Cells[ColCompLib, Lig]   := PCompetence.Libelle;
      TabCompetence.Cells[ColCompStat, Lig]  := PCompetence.CodeAttribut;
      PAttribut                              := ChercheAttribut(PCompetence.CodeAttribut);
      TabCompetence.Cells[ColCompCarac, Lig] := PAttribut.Resume;
    end;

  // Avancees gratuites d'un <SkillChoice> d'appartenance (Personnage.CompetenceAppartenance,
  // ColCompAppartenance) - meme boucle que les deux ci-dessus, colonne dediee.
  for PersonnageCompetence in Personnage.CompetenceAppartenance do
    begin
      Lig  := FindRowByText(TabCompetence, PersonnageCompetence.CodeCompetence, ColCompCode);
      if Lig = -1 then
        begin
          NbCompetence            := NbCompetence + 1;
          TabCompetence.RowCount  := TabCompetence.RowCount + 1;
          Lig                     := NbCompetence;
        end;
      TabCompetence.Cells[ColCompCode , Lig]         := PersonnageCompetence.CodeCompetence;
      TabCompetence.Cells[ColCompAppartenance, Lig]  := IntToStr(PersonnageCompetence.Valeur);
      PCompetence                            := ChercheCompetence(TabCompetence.Cells[1, lig]);
      TabCompetence.Cells[ColCompLib, Lig]   := PCompetence.Libelle;
      TabCompetence.Cells[ColCompStat, Lig]  := PCompetence.CodeAttribut;
      PAttribut                              := ChercheAttribut(PCompetence.CodeAttribut);
      TabCompetence.Cells[ColCompCarac, Lig] := PAttribut.Resume;
    end;


  // Lire les talents de la sous-section TALENT
  For PersonnageTalent in Personnage.CreationTalent do
    begin
      Inc(NbTalent);
      TabTalent.RowCount              := TabTalent.RowCount + 1;
      TabTalent.Cells[ColTalCode, NbTalent]    := PersonnageTalent.CodeTalent;
      TabTalent.Cells[ColTalNb, NbTalent]    := IntToStr(StrToIntDef(TabTalent.Cells[ColTalNb, NbTalent],0) + PersonnageTalent.Valeur);
      TabTalent.Cells[ColTalNbCrea, NbTalent]    := IntToStr(PersonnageTalent.Valeur);
      PTalent                         := ChercheTalent(TabTalent.Cells[ColTalCode, NbTalent]);
      TabTalent.Cells[ColTalLib, NbTalent]    := PTalent.Libelle;
      if PTalent.SousTalent then
        PTalent                       := ChercheTalent(Copy(PTalent.CodeTalent, 1, Pos('_', PTalent.CodeTalent) - 1)+'_*');
      TabTalent.Cells[ColTalMax, NbTalent]    := Ptalent.MaxiTalent;
      end;

  // Personnage.MetierTalent n'est PAS une liste de talents possedes : c'est le menu de la
  // table de carriere en cours (tous paliers), qui sert uniquement (1) a proposer les choix
  // sur l'ecran Augmentation au palier atteint et (2) a memoriser la specialite resolue pour
  // un talent '_*'/choix multiple. Un talent n'est reellement possede que via CreationTalent
  // (creation) ou AugmentationTalent (achete en Xp, y compris depuis cette liste) - ne jamais
  // l'ajouter ici. Confirme par Nono le 26/09/2026 apres la tentative de fusion ci-dessus,
  // qui affichait a tort les 16 talents du menu de carriere comme acquis. A FAIRE.txt.

  // carrières
  for PersonnageMetier in Personnage.MetierAncien do
    begin
      Inc(NbCarriere);
      TabCarriere.RowCount             := TabCarriere.RowCount + 1;
      TabCarriere.Cells[1,NbCarriere]  := PersonnageMetier.CodeMetier;
      TabCarriere.Cells[2,NbCarriere]  := IntToStr(PersonnageMetier.NiveauMetier);
      PMetier                          := chercheMetier(PersonnageMetier.CodeMetier);
      TabCarriere.Cells[3,NbCarriere]  := PMetier.Libelle;
      TabCarriere.Cells[4,NbCarriere]  := IntToStr(CalculOptionXpDiv25(PersonnageMetier.CoutXp));
    end;

  // Augmentation

  // attribut
  For PersonnageAttribut in Personnage.AugmentationAttribut do
    For IndTab := 1 to TabAttribut.ColCount - 1 do
      // Comparaison qui ignore le prefixe de livre : la ligne de codes de TabAttribut est semee
      // par AttributInit a partir des constantes ConstCaracXxx ('ATTR_WS', sans prefixe), alors
      // que la fiche contient desormais 'RULES-ATTR_WS'. Un '=' brut ne matchait plus et les
      // augmentations de caracteristiques disparaissaient de l'ecran. CONTEXT.md 2.19.
      //
      // ATTENTION A L'ORDRE DES ARGUMENTS : CompareRechercheValeur n'est PAS symetrique.
      // VerifieRecherche accepte le cas "livre absent" uniquement sur le SECOND argument
      // (LivreValeur = ''). Le code PREFIXE doit donc venir en premier, le code court en
      // second - c'est la convention de tout le reste du programme (ChercheTalent fait
      // CompareRechercheValeur(PTalent.CodeTalent, CodeTalent)). Inverse, la comparaison
      // renvoie toujours False.
      if CompareRechercheValeur(PersonnageAttribut.CodeAttribut, TabAttribut.Cells[IndTab, LigAttCode]) then
        TabAttribut.Cells[IndTab, LigAttBonus] := IntToStr(PersonnageAttribut.Valeur);

  // compétence
  For PersonnageCompetence in Personnage.AugmentationCompetence do
    begin
      Lig  := FindRowByText(TabCompetence, PersonnageCompetence.CodeCompetence, ColCompCode);
      if Lig = -1 then
        begin
          NbCompetence            := NbCompetence + 1;
          TabCompetence.RowCount  := TabCompetence.RowCount + 1;
          Lig                     := NbCompetence;
        end;
      TabCompetence.Cells[ColCompCode , Lig] := PersonnageCompetence.CodeCompetence;
      TabCompetence.Cells[ColCompWork, Lig]  := IntToStr(PersonnageCompetence.Valeur);
      PCompetence                            := ChercheCompetence(TabCompetence.Cells[1, lig]);
      TabCompetence.Cells[ColCompLib, Lig]   := PCompetence.Libelle;
      TabCompetence.Cells[ColCompStat, Lig]  := PCompetence.CodeAttribut;
      PAttribut                              := ChercheAttribut(PCompetence.CodeAttribut);
      TabCompetence.Cells[ColCompCarac, Lig] := PAttribut.Resume;
    end;

  // Talent
    For PersonnageTalent in Personnage.AugmentationTalent do
      begin
        Lig  := FindRowByText(TabTalent, PersonnageTalent.CodeTalent, 1);
        if Lig = -1 then
          begin
            NbTalent            := NbTalent + 1;
            TabTalent.RowCount  := TabTalent.RowCount + 1;
            Lig                 := NbTalent;
          end;
          TabTalent.Cells[ColTalCode, Lig]    := PersonnageTalent.CodeTalent;
          // Abs() : une Vertu nommee (Knightly Virtue...) porte un NbAugm negatif volontaire
          // (deja comptee en cout ailleurs, cf MajTables) - le nombre AFFICHE doit rester
          // positif (1 possedee, pas -1). Ne change rien pour les autres talents, dont
          // Valeur n'est jamais negative. CONTEXT.md 2.78, prises multiples.
          TabTalent.Cells[ColTalNb, Lig]    := IntToStr(StrToIntDef(TabTalent.Cells[ColTalNb, Lig],0) + Abs(PersonnageTalent.Valeur));
          TabTalent.Cells[ColTalNbAugm, Lig]   := IntToStr(PersonnageTalent.Valeur);
          PTalent                    := ChercheTalent(TabTalent.Cells[ColTalCode, Lig]);
          TabTalent.Cells[ColTalLib, Lig]    := PTalent.Libelle;
          if PTalent.SousTalent then
            PTalent                  := ChercheTalent(Copy(PTalent.CodeTalent, 1, Pos('_', PTalent.CodeTalent) - 1)+'_*');
          TabTalent.Cells[ColTalMax, Lig]    := Ptalent.MaxiTalent;
          TabTalent.Cells[ColTalXp, Lig]    := IntToStr(CalculExperience(ConstXmlTalent, 0, StrToIntDef(TabTalent.Cells[ColTalNbAugm, Lig],0), PersonnageTalent.CodeTalent));
        end;

  // Talents accordes par une mutation (ex. Fleshy Tentacle -> Tentacles) ou par une qualite
  // d'objet porte (ex. NATIO-ARMOB_16 "Fear" -> Frightening, Skull Trophies) - calcules a la
  // volee (PersonnageMutationTalent/PersonnageArmureBonusTalent, chargepersonnage.pas), deja
  // affiches au PDF, maintenant aussi a l'ecran. Fusionnes avec une ligne existante si le
  // joueur possede deja le meme talent achete normalement (ex. Frightening) - jamais dans
  // ColTalNbAugm/ColTalXp, qui restent reserves aux augmentations payees en Xp : un octroi
  // automatique ne coute rien.
  For PersonnageTalent in PersonnageTalentsOctroyes(Personnage) do
    begin
      Lig  := FindRowByText(TabTalent, PersonnageTalent.CodeTalent, 1);
      if Lig = -1 then
        begin
          NbTalent            := NbTalent + 1;
          TabTalent.RowCount  := TabTalent.RowCount + 1;
          Lig                 := NbTalent;
        end;
      TabTalent.Cells[ColTalCode, Lig] := PersonnageTalent.CodeTalent;
      TabTalent.Cells[ColTalNb, Lig]   := IntToStr(StrToIntDef(TabTalent.Cells[ColTalNb, Lig],0) + PersonnageTalent.Valeur);
      PTalent                          := ChercheTalent(TabTalent.Cells[ColTalCode, Lig]);
      TabTalent.Cells[ColTalLib, Lig]  := PTalent.Libelle;
      if PTalent.SousTalent then
        PTalent                       := ChercheTalent(Copy(PTalent.CodeTalent, 1, Pos('_', PTalent.CodeTalent) - 1)+'_*');
      TabTalent.Cells[ColTalMax, Lig]  := Ptalent.MaxiTalent;
    end;

  // Mutation (CONTEXT.md §2.7) - effets à delta pur des mutations obtenues, même fonction
  // que celle utilisée pour le PDF (PersonnageMutationAttributModif, chargepersonnage.pas)
  // pour rester cohérent entre l'écran et le PDF.
  // Afflictions/Maladies possédées (Personnage.Pathologies) - ligne dédiée séparée de Mutation
  // depuis le 27/09/2026, à la demande de Nono ("ce n'est pas une Mutation") ; regroupées avec
  // Mutation uniquement au PDF (RULES-LAB_299, pdfpersonnage.pas), qui n'a qu'une seule colonne.
  for IndTab := 1 to TabAttribut.ColCount - 1 do
    begin
      // Ligne Talent : <ModifyCarac> des talents par le collecteur (comme le PDF), a la place de
      // l'ancien champ <Attribut> (+5 en dur), plus lu depuis le 03/10/2026.
      ValTalent := PersonnageTalentAttributModif(Personnage, TabAttribut.Cells[IndTab, LigAttCode]);
      if ValTalent <> 0 then
        TabAttribut.Cells[IndTab, LigAttTalent] := IntToStr(ValTalent);

      ValMutation := PersonnageMutationAttributModif(Personnage, TabAttribut.Cells[IndTab, LigAttCode]);
      if ValMutation <> 0 then
        TabAttribut.Cells[IndTab, LigAttMutation] := IntToStr(ValMutation);

      ValPathologie := PersonnageAfflictionAttributModif(Personnage, TabAttribut.Cells[IndTab, LigAttCode])
                        + PersonnageDiseaseAttributModif(Personnage, TabAttribut.Cells[IndTab, LigAttCode]);
      if ValPathologie <> 0 then
        TabAttribut.Cells[IndTab, LigAttPathologie] := IntToStr(ValPathologie);
    end;
end;

procedure TWinPersonnages.XmlChargePersonnageEquipementSorts();
var
  PArme:                 StructureArme;
  PArmure:               StructureArmure;
  PArmureSimplifiee:     StructureArmureSimplifiee;
  PTrapping:             StructureTrapping;
  PSort:                 StructureSort;
  Ind:                   Integer;
begin
  // Compétence métier
  for PersonnageCompetence in Personnage.MetierCompetence do
    for Ind := 1 to TabCompetence.RowCount - 1 do
      if TabCompetence.Cells[ColCompCode, Ind] = PersonnageCompetence.CodeCompetence then
        if (TabCompetence.Cells[ColCompImage, Ind] < '1') or (IntToStr(PersonnageCompetence.Valeur) < TabCompetence.Cells[ColCompImage, Ind]) then
          TabCompetence.Cells[ColCompImage, Ind] := IntToStr(PersonnageCompetence.Valeur);

  // équipement et sorts
  NbEquipement := 0;
  TabEquipement.RowCount := 1;
  for PersonnageEquipement in Personnage.Equipement do
    begin
      Inc(NbEquipement);
      TabEquipement.RowCount                 := TabEquipement.RowCount + 1;
      TabEquipement.Cells[2, NbEquipement]   := PersonnageEquipement.CodeEquipement;
      TabEquipement.Cells[3, NbEquipement]   := TrimRight(PersonnageEquipement.TypeEquipement);
      TabEquipement.Cells[9, NbEquipement]   := IntToStr(PersonnageEquipement.Quantite);
      TabEquipement.Cells[10, NbEquipement]  := PersonnageEquipement.IdInstance;
      TabEquipement.Cells[11, NbEquipement]  := PersonnageEquipement.PortePar;
      if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe) then
          begin
            PArme := chercheArme(PersonnageEquipement.CodeEquipement);
            TabEquipement.Cells[4, NbEquipement]   := PArme.Libelle;
            TabEquipement.Cells[7, NbEquipement]   := PersonnageEquipement.QualiteEquipement;
            if PersonnageEquipement.Porte then
              TabEquipement.Cells[8, NbEquipement] := 'X';
          end
      else if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAr) then
          Begin
            PArmure := ChercheArmure(PersonnageEquipement.CodeEquipement);
            TabEquipement.Cells[4, NbEquipement]   := PArmure.Libelle;
            TabEquipement.Cells[7, NbEquipement]   := PersonnageEquipement.QualiteEquipement;
            if PersonnageEquipement.Porte then
              TabEquipement.Cells[8, NbEquipement] := 'X';
          end
      else if TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipArS) then
          Begin
            PArmureSimplifiee := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement);
            TabEquipement.Cells[4, NbEquipement]   := PArmureSimplifiee.Libelle;
            TabEquipement.Cells[7, NbEquipement]   := PersonnageEquipement.QualiteEquipement;
            if PersonnageEquipement.Porte then
              TabEquipement.Cells[8, NbEquipement] := 'X';
          end
      else if (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipDi))
              or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAN)) then
          Begin
            // Cf. ChargerMetierEquipement : un code Divers deja possede par le personnage
            // peut etre un Trapping catalogue (RULES-TRAP_xxx), resolu sans changer sa
            // classification TypeEquipDI (CONTEXT.md 2.77bis).
            PTrapping := ChercheTrapping(PersonnageEquipement.CodeEquipement);
            if PersonnageEquipement.NomLibre <> '' then
              begin
                TabEquipement.Cells[4, NbEquipement]  := PersonnageEquipement.NomLibre;
                TabEquipement.Cells[13, NbEquipement] := PersonnageEquipement.NomLibre;
                TabEquipement.Cells[14, NbEquipement] := IntToStr(PersonnageEquipement.EncLibre);
              end
            else if PTrapping.CodeTrapping <> '' then
              TabEquipement.Cells[4, NbEquipement] := PTrapping.Libelle
            else
              TabEquipement.Cells[4, NbEquipement] := PersonnageEquipement.CodeEquipement;
            TabEquipement.Cells[7, NbEquipement]   := PersonnageEquipement.QualiteEquipement;
            if PersonnageEquipement.Porte then
              TabEquipement.Cells[8, NbEquipement] := 'X';
          end
      else if TrimRight(PersonnageEquipement.TypeEquipement) =TrimRight(TypeEquipSp) then
          begin
            PSort := ChercheSort(PersonnageEquipement.CodeEquipement);
            TabEquipement.Cells[3, NbEquipement]   := PSort.TypeSort;
            TabEquipement.Cells[9, NbEquipement]   := '';
            TabEquipement.Cells[4, NbEquipement]   := PSort.Libelle;
            TabEquipement.Cells[5, NbEquipement]   := IntToStr(CalculOptionXpDiv25(PersonnageEquipement.CoutXp));
          end;
    end;
  RafraichitPorteurs;

  // Armes portees au-dela du nombre de mains (main perdue depuis, ou ancien personnage) :
  // on previent sans rien retirer.
  if PersonnageMainsDepassees(Personnage) then
    ShowMessage(GetTexteLibelle('RULES-LAB_473') + ' : '
                + IntToStr(PersonnageMainsUtilisees(Personnage, False)) + ' / '
                + IntToStr(PersonnageMainsUtilisees(Personnage, True)) + ' / '
                + IntToStr(PersonnageNombreMains(Personnage)));
end;

procedure TWinPersonnages.XmlChargePersonnageSuivi(const FileName: string);
var
  Lig:                   Integer = 0;
  Ind:                   Integer;
  PersonnageCorruption:  StructurePersonnageCorruption;
  ValMutation:           Integer;
begin
  // historique de corruption
  StringGridCorruption.RowCount := 1;
  for PersonnageCorruption in Personnage.Corruption do
    begin
      StringGridCorruption.RowCount                                       := StringGridCorruption.RowCount + 1;
      StringGridCorruption.Cells[1, StringGridCorruption.RowCount - 1]    := IntToStr(PersonnageCorruption.Montant);
      StringGridCorruption.Cells[2, StringGridCorruption.RowCount - 1]    := PersonnageCorruption.Libelle;
    end;
  CalculCorruptionLeft();

  // registres de Destin, de Resilience et de Resolution (les lignes de Destin et de Resilience sont DEJA
  // comprises dans Personnage.CreationAttribut : on ne fait que les afficher)
  ReservesChargement := True;
  PanelDestin.Vider;
  for PersonnageCorruption in Personnage.Destin do
    PanelDestin.AjouteLigne(PersonnageCorruption.Montant, PersonnageCorruption.Libelle);
  PanelResilience.Vider;
  for PersonnageCorruption in Personnage.Resilience do
    PanelResilience.AjouteLigne(PersonnageCorruption.Montant, PersonnageCorruption.Libelle);
  PanelResolve.Vider;
  for PersonnageCorruption in Personnage.Resolve do
    PanelResolve.AjouteLigne(PersonnageCorruption.Montant, PersonnageCorruption.Libelle);
  DestinApplique      := PanelDestin.Somme;
  ResilienceApplique  := PanelResilience.Somme;
  ReservesChargement  := False;
  MajReserves();

  // mutations obtenues (CONTEXT.md §2.7)
  AfficheMutations();

  // afflictions/maladies possedees (ajout du 27/09/2026)
  AfficheDiseasesAfflictions();

  // livres
  for Lig := 1 to TabLivre.RowCount - 1 do
    begin
      if (pos(ajouteaccolade(TabLivre.Cells[3, Lig]),Personnage.LivresAcceptes) > 0) or (TabLivre.Cells[3, Lig] = ConstRulesBook) then
        TabLivre.Cells[1, Lig] := ConstSelectionne
      else
        TabLivre.Cells[1, Lig] := '';
    end;

  // Augmentation Xp Mj Attribut
  Lig := 0;
  For PersonnageXpAttribut in Personnage.XpCoutAttribut do
    begin
      Inc(Lig);
      TabAugmentationMjXp.Rowcount                     := TabAugmentationMjXp.Rowcount + 1;
      TabAugmentationMjXp.Cells[ColAugmMjXpType, Lig]  := ConstXmlCarac;
      TabAugmentationMjXp.Cells[ColAugmMjXpCode, Lig]  := PersonnageXpAttribut.CodeAttribut;
      TabAugmentationMjXp.Cells[ColAugmMjXpDebut, Lig] := IntToStr(PersonnageXpAttribut.Debut);
      TabAugmentationMjXp.Cells[ColAugmMjXpFin, Lig]   := IntToStr(PersonnageXpAttribut.Fin);
      TabAugmentationMjXp.Cells[ColAugmMjXpCout, Lig]  := IntToStr(CalculExperience(ConstXmlCarac, PersonnageXpAttribut.Debut, PersonnageXpAttribut.Fin, ''));
      TabAugmentationMjXp.Cells[ColAugmMjXpReel, Lig]  := IntToStr(PersonnageXpAttribut.CoutXp);
    end;

  // Augmentation Xp Mj Competence
  For PersonnageXpCompetence in Personnage.XpCoutCompetence do
    begin
      Inc(Lig);
      TabAugmentationMjXp.Rowcount                     := TabAugmentationMjXp.Rowcount + 1;
      TabAugmentationMjXp.Cells[ColAugmMjXpType, Lig]  := ConstXmlCompetence;
      TabAugmentationMjXp.Cells[ColAugmMjXpCode, Lig]  := PersonnageXpCompetence.CodeCompetence;
      TabAugmentationMjXp.Cells[ColAugmMjXpDebut, Lig] := IntToStr(PersonnageXpCompetence.Debut);
      TabAugmentationMjXp.Cells[ColAugmMjXpFin, Lig]   := IntToStr(PersonnageXpCompetence.Fin);
      TabAugmentationMjXp.Cells[ColAugmMjXpCout, Lig]  := IntToStr(CalculExperience(ConstXmlCompetence, PersonnageXpCompetence.Debut, PersonnageXpCompetence.Fin, ''));
      TabAugmentationMjXp.Cells[ColAugmMjXpReel, Lig]  := IntToStr(PersonnageXpCompetence.CoutXp);
    end;

  // Augmentation Xp Mj Talent
  For PersonnageXpTalent in Personnage.XpCoutTalent do
    begin
      Inc(Lig);
      TabAugmentationMjXp.Rowcount                     := TabAugmentationMjXp.Rowcount + 1;
      TabAugmentationMjXp.Cells[ColAugmMjXpType, Lig]  := ConstXmlTalent;
      TabAugmentationMjXp.Cells[ColAugmMjXpCode, Lig]  := PersonnageXpTalent.CodeTalent;
      TabAugmentationMjXp.Cells[ColAugmMjXpDebut, Lig] := IntToStr(PersonnageXpTalent.Debut);
      TabAugmentationMjXp.Cells[ColAugmMjXpFin, Lig]   := IntToStr(PersonnageXpTalent.Fin);
      TabAugmentationMjXp.Cells[ColAugmMjXpCout, Lig]  := IntToStr(CalculExperience(ConstXmlTalent, PersonnageXpTalent.Debut, PersonnageXpTalent.Fin, ''));
      TabAugmentationMjXp.Cells[ColAugmMjXpReel, Lig]  := IntToStr(PersonnageXpTalent.CoutXp);
    end;

  // Colonne des modificateurs (CONTEXT.md §2.7, etape d bis du chantier 2.105) : meme collecteur
  // que le PDF (PersonnageCompetenceModificateur, chargepersonnage.pas), moins la part de
  // carriere qui a sa propre colonne - ainsi les colonnes se recomposent toujours en Total,
  // quelle que soit la source (mutation, affliction, talent, arme, armure, fabrication).
  for Ind := 1 to TabCompetence.RowCount - 1 do
    begin
      ValMutation := PersonnageCompetenceModificateur(Personnage, TabCompetence.Cells[ColCompCode, Ind])
                     - PersonnageCareerBonusCompetenceModif(Personnage, TabCompetence.Cells[ColCompCode, Ind]);
      if ValMutation <> 0 then
        TabCompetence.Cells[ColCompMutation, Ind] := IntToStr(ValMutation);
    end;

  AfficheImageMetier();
  TabTalent.SortColRow(true, 3);
  tabCompetence.SortColRow(true, ColCompLib);
  CalculTotaux();
  NiveauMetierTalentMax();
  MarqueNiveauEnCours();
  CalculTableExperience();
  ChargeAugmentation();
  CalculAvancement();

  For Ind := 1 to TabHistorique.RowCount-1 do
    if TabHistorique.Cells[2, Ind] = FileName then
      TabHistorique.Cells[0, Ind] := ConstSelectionne
    else
      TabHistorique.Cells[0, Ind] := '';
  ButtonAugmentation.Visible := (TabHistorique.Cells[0, 1] = ConstSelectionne);
  // Boutons d'ajout/action d'equipement : combine ce meme critere (lecture seule sur un
  // instantane de l'historique) avec le filtre par categorie de ListBoxEquipementCategorie.
  EquipementModifiable := (TabHistorique.Cells[0, 1] = ConstSelectionne);
  RafraichitTabEquipementAffichage();
  ToggleBoxGauche.left := ToggleBoxGauche.left + 1;
  AjustePositionTables();
  AfficheFabrication();
  TalentAsterisc();
end;

procedure TWinPersonnages.XmlChargePersonnage(const FileName: string);
begin
  XmlChargePersonnageGeneral(FileName);
  XmlChargePersonnageRaceMetier();
  XmlChargePersonnageCompetencesTalentsAugmentations();
  XmlChargePersonnageEquipementSorts();
  XmlChargePersonnageSuivi(FileName);
end;

Procedure TWinPersonnages.TalentAsterisc();
  var
    PTalent: StructureTalent;
    IndT:    Integer;
    IndS:    Integer;
    Strings: TStringList;
    IndA:    Integer;
    Acc:     Boolean;
  begin
    for indT := 1 to TabTalent.RowCount - 1 do
      begin
        PTalent := ChercheTalent(TabTalent.Cells[ColTalCode, IndT]);
        if PTalent.TalentPdf <> '' then
          begin
            strings    := TStringList.Create;
            ExtractStrings([','], [], PChar(PTalent.TalentPdf), Strings);
            for IndS := 0 to (Strings.count-1) Do
              begin
                if copy(Strings[Inds],1,Length(ConstDebutAttribut)) = ConstDebutAttribut then
                  begin
                    for IndA := 1 to 11 do
                      if TabAttribut.Cells[IndA, LigAttCode] = Strings[IndS] then
                        begin
                          if TabAttribut.Cells[IndA, LigAttAsterisc] <> '' then
                            TabAttribut.Cells[IndA, LigAttAsterisc] := TabAttribut.Cells[IndA, LigAttAsterisc] + ',';
                          TabAttribut.Cells[IndA, LigAttAsterisc] := IntToStr(IndT);
                          TabTalent.Cells[ColTalAsterisk, IndT]                := IntToStr(IndT);
                          break
                        end;
                  end
                else if copy(Strings[Inds],1,Length(ConstDebutCompetence)) = ConstDebutCompetence then
                  begin
                    for IndA := 1 to TabCompetence.RowCount-1 do
                      begin
                        // Radicaux compares SANS le prefixe de livre : la reference du talent
                        // et la competence de la fiche peuvent venir de deux livres differents
                        // (meme piege que winspecialisation.pas/wincompetence.pas).
                        if ExtractStringBefore(CodeSansLivre(tabCompetence.Cells[ColCompCode, IndA]),'_') = ExtractStringBefore(CodeSansLivre(Strings[IndS]), '_') then
                          begin
                            Acc := false;
                            // Strings[IndS] (le "COMPXXX" du <PDF> du talent) ne porte jamais de
                            // prefixe de livre - comparer sa partie centrale, pas le code complet
                            // prefixe de la fiche. Et c'est la reference du talent qui dit si elle
                            // vise toute la famille (ValeurGenerique dans Strings[IndS]), pas le
                            // code de la competence.
                            if (CodeSansLivre(tabCompetence.Cells[ColCompCode, IndA]) = Strings[IndS]) then
                              Acc := True
                            else if Pos(ValeurGenerique, Strings[IndS]) > 0 then
                              Acc := true;
                            if Acc = True then
                              Begin
                                if TabCompetence.Cells[ColCompAsterisc, IndA] <> '' then
                                  TabCompetence.Cells[ColCompAsterisc, IndA] := TabCompetence.Cells[ColCompAsterisc, IndA] + ',';
                                TabCompetence.Cells[ColCompAsterisc, IndA] := IntToStr(IndT);
                                TabTalent.Cells[ColTalAsterisk, IndT]                   := IntToStr(IndT);
                              end;
                            break;
                          end;
                      end;
                  end;
              end;
            strings.free;
          end;
      end;
  end;

procedure TWinPersonnages.RadioButtonChangerChange(Sender: TObject);
begin
  ChargerMetierEquipement('',0);
  NvMetierChoisi := '';
  ButtonRaceSelectionner.visible := RadioButtonChanger.checked;
  ButtonRaceSelectionner.BringToFront;
  // La combo occupe le meme emplacement que le bouton : elle doit disparaitre ici.
  ChargeComboNvMetier();
  CalculXpNecessaire(false);
end;


procedure TWinPersonnages.NiveauMetierTalentMax();
  var
    aRow:            Integer;
    IndAttribut:     Integer;
    PMetierTalent:   StructureMetierTalent;

  // Le talent de carriere peut etre un CHOIX "A/B" (ex. RULES-T0161/NATIO-T0015_* : Slayer ou
  // Mark of the Gods, Norscan Mercenary). Le code brut ne ressemble alors a aucun talent
  // possede : on teste chaque branche, avec les deux regles habituelles (meme code, ou meme
  // radical a la specialisation pres). Sans cela un Mark of the Eagle n'etait jamais compte
  // dans l'avancement. 20/09/2026.
  // Radical d'un talent a specialisation : le code AVEC son livre, coupe au premier '_'
  // (RULES-T0012_ANIMAL -> RULES-T0012). Garder le livre est necessaire : T0012 existe aussi dans
  // DWARF et NATIO (21 radicaux partages), et les cinq premiers caracteres du code sans livre
  // confondaient ces talents. Un code sans '_' (RULES-T*) est son propre radical.
  function RadicalTalent(Code: String): String;
    var
      P: Integer;
    begin
      P := Pos('_', Code);
      if P > 0 then
        Result := Copy(Code, 1, P - 1)
      else
        Result := Code;
    end;

  function TalentCarriereCorrespond(CodeCarriere, CodeLigne: String): Boolean;
    var
      Branches: TStringList;
      IndBr:    Integer;
    begin
      Result := False;
      Branches                 := TStringList.Create;
      try
        Branches.StrictDelimiter := True;
        Branches.Delimiter       := SeparateurMulti;
        Branches.DelimitedText   := CodeCarriere;
        for IndBr := 0 to Branches.Count - 1 do
          if CompareRechercheValeur(Branches[IndBr], CodeLigne)
             or (RadicalTalent(Branches[IndBr]) = RadicalTalent(CodeLigne)) then
            begin
              Result := True;
              Break;
            end;
      finally
        Branches.Free;
      end;
    end;

  begin
    for aRow := 1 to TabTalent.RowCount-1 do
    begin
      // Niveau talent
      For PMetierTalent in ListMetierTalent do
        if CompareRechercheValeur(PMetierTalent.CodeMetier, MetierEnCours) then
          begin
            // Second test : meme talent a la specialisation pres (T0012_* contre T0012_ANIMAL).
            // Les cinq premiers caracteres sont le radical. On redecoupe les deux codes ici au
            // lieu de relire CodeValeur / CodeRecherche, les globales laissees par l'appel de
            // gauche : meme resultat, mais sans dependre de cet etat partage. CONTEXT.md 2.49.
            // Adapting Careers : le talent substitue remplace le code brut de la carriere (20/09/2026).
            if TalentCarriereCorrespond(AdapterElement(MetierEnCours, Personnage.Race, Personnage.ChoixAdaptation, PMetierTalent.NiveauMetier,
                                        ConstXmlTalent, PMetierTalent.CodeTalent),
                                        TabTalent.Cells[ColTalCode, ARow]) then
              begin
                TabTalent.Cells[2, Arow] := IntToStr(PMetierTalent.NiveauMetier);
                Break;
              end
          end;

      // Max
      if TabTalent.Cells[ColTalMax, aRow] <> '1' then
        begin
          for IndAttribut := 1 to TabAttribut.Colcount-1 do
            begin
              if '(B'+CodeSansLivre(TabAttribut.Cells[IndAttribut, LigAttCode])+')' = TabTalent.Cells[ColTalMax, aRow] then
                begin
                  TabTalent.Cells[ColTalMax, aRow] := IntToStr(Floor(StrToIntDef(TabAttribut.Cells[IndAttribut, LigAttTotal],0) / 10));
                  Break;
                end;
            end;
        end;
    end;
    TabEquipementAffiche();
  end;

Procedure TWinPersonnages.AfficheImageMetier();
var
  indTabAttribut:     integer;
  PMetierAttribut:    StructureMetierAttribut;
  PMetierNiveau:      StructureMetierNiveau;
  CheminImage1:       String;
  NvMin:              Integer;
  NvMax:              Integer;
  IndNv:              Integer;
begin
  if MetierEnCours <> '' then
     CheminImage1     := CheminMetierImage(MetierEnCours)
  else
     CheminImage1     := '';

  if FileExists(CheminImage1) then
     ImageMetier.Picture.LoadFromFile(CheminImage1)
  else
     ImageMetier.Picture := nil;

  // bonus de race d'attributs
  for PMetierAttribut in ListMetierAttribut do
    if CompareRechercheValeur(PMetierAttribut.CodeMetier, MetierEnCours) then
      for IndTabAttribut := 1 to TabAttribut.ColCount -1 do
        if CompareRechercheValeur(PMetierAttribut.CodeAttribut, TabAttribut.Cells[IndTabAttribut,LigAttCode]) and (PMetierAttribut.NiveauMetier > 0) then
          TabAttribut.Cells[IndTabAttribut,LigAttImage] := IntToStr(PMetierAttribut.NiveauMetier);

  // Liste des Niveaux
  // Le tableau ne montre QUE les niveaux que CE metier possede. Les lignes etaient
  // auparavant indexees par le NUMERO de niveau, dans une grille dimensionnee une fois pour
  // toutes a la creation de la fenetre sur le maximum GLOBAL. Deux consequences, les deux
  // vues par Nono le 31/08/2026 :
  //   - une carriere avancee, qui commence au niveau 3, laissait deux lignes vides en tete ;
  //   - une carriere a quatre niveaux laissait une ligne vide en queue depuis que le lot 2
  //     a porte ce maximum global a 5 - regression du chantier de la veille.
  //
  // Les lignes sont desormais SEQUENTIELLES, et c'est sans danger pour les icones : TabDrawCell
  // lit l'indice d'image dans le CONTENU de la cellule - la colonne 2, qui porte le numero de
  // niveau - et non dans le numero de ligne.
  NvMin := ChercheMinMetierNiveau(MetierEnCours);
  NvMax := ChercheMaxMetierNiveau(MetierEnCours);
  // Metier inconnu ou incoherent : on retombe sur l'affichage historique plutot que de
  // presenter une grille vide.
  if (NvMin < 1) or (NvMax < NvMin) then
    begin
      NvMin := 1;
      NvMax := MaxNiveauMetier();
    end;
  TabNiveau.RowCount := NvMax - NvMin + 2;

  // Vidage explicite, qui n'existait nulle part : sans lui, passer d'un metier a cinq
  // niveaux a un metier a trois laissait les lignes de l'ancien a l'ecran.
  for IndNv := 1 to TabNiveau.RowCount - 1 do
    begin
      TabNiveau.Cells[2, IndNv] := '';
      TabNiveau.Cells[3, IndNv] := '';
    end;

  for IndNv := NvMin to NvMax do
    For PMetierNiveau in ListMetierNiveau do
      if CompareRechercheValeur(PMetierNiveau.CodeMetier, MetierEnCours)
         and (PMetierNiveau.NiveauMetier = IndNv) then
        begin
          TabNiveau.Cells[2, IndNv - NvMin + 1] := IntToStr(PMetierNiveau.NiveauMetier);
          TabNiveau.Cells[3, IndNv - NvMin + 1] := PMetierNiveau.Libelle;
          break;
        end;
end;

Procedure TwinPersonnages.TabAugmentationAttributCalcul(ARow: Integer; var Value: string);
  var
    CellValue: Integer;
    ValeurMin: Integer = 0;
    ValeurMax: Integer = 99;
    Xp:        Integer = 0;
  begin
    if TryStrToInt(Value, CellValue) then
      begin
        // Appliquer les limites minimale et maximale
        ValeurMin := StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttActuel, ARow],0);
        CellValue := Min(Max(CellValue, ValeurMin), ValeurMax);
        // Formater la valeur avec un nombre de décimales spécifié
        if StrToIntDef(Value,0) >= ValeurMin then
          begin
            Value := IntToStr(CellValue);
            Xp    := CalculExperience(ConstXmlCarac, StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttActuel, aRow],0), CellValue, '');
            if Xp > 0 then
              TabAugmentationAttribut.Cells[ColAugmAttCout, aRow] := IntToStr(Xp)
            else
              TabAugmentationAttribut.Cells[ColAugmAttCout, aRow] := '';
            if TabAugmentationAttribut.Cells[2, aRow] = CouleurKo then
              TabAugmentationAttribut.Cells[ColAugmAttReel, aRow]   := IntToStr(StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttCout, aRow],0) * 2)
            else
              TabAugmentationAttribut.Cells[ColAugmAttReel, aRow]   := TabAugmentationAttribut.Cells[ColAugmAttCout, aRow];
            CalculTableExperience();
          end;
      end;
  end;

procedure TWinPersonnages.TabAugmentationAttributGetEditText(Sender: TObject;
  ACol, ARow: Integer; var Value: string);
  begin
    // Vérifier si la colonne actuelle correspond à la colonne que vous souhaitez formater
    if ACol = ColAugmAttNouveau then
    begin
      TabAugmentationAttributCalcul(Arow, Value);
      PreviousRowIndexA := aRow;
    end;
  end;

procedure TWinPersonnages.TabAugmentationAttributSelectCell(Sender: TObject;
  aCol, aRow: Integer; var CanSelect: Boolean);
var
  CellValue: Integer;
  ValeurMin: Integer = 0;
  ValeurMax: Integer = 99;
  Xp:        Integer = 0;
begin
  if (aCol = ColAugmAttNouveau) and (PreviousRowIndexA > 0) then
    begin
      // Appliquer les limites minimale et maximale
      ValeurMin := StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttActuel, PreviousRowIndexA],0);
      CellValue := Min(Max(StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttNouveau, PreviousRowIndexA],0), ValeurMin), ValeurMax);
      // Formater la valeur avec un nombre de décimales spécifié
      TabAugmentationAttribut.Cells[ColAugmAttNouveau, PreviousRowIndexA] := IntToStr(CellValue);
      Xp    := CalculExperience(ConstXmlCarac, StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttActuel, PreviousRowIndexA ],0), StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttNouveau, PreviousRowIndexA ],0), '');
      if Xp > 0 then
        TabAugmentationAttribut.Cells[ColAugmAttCout, PreviousRowIndexA ] := IntToStr(Xp)
      else
        TabAugmentationAttribut.Cells[ColAugmAttCout, PreviousRowIndexA ] := '';
      if TabAugmentationAttribut.Cells[2, PreviousRowIndexA] = CouleurKo then
        TabAugmentationAttribut.Cells[ColAugmAttReel, PreviousRowIndexA]   := IntToStr(StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttCout, PreviousRowIndexA],0) * 2)
      else
        TabAugmentationAttribut.Cells[ColAugmAttReel, PreviousRowIndexA]   := TabAugmentationAttribut.Cells[ColAugmAttCout, PreviousRowIndexA];

      PreviousRowIndexA := aRow;
      CalculTableExperience();
    end;
end;

procedure TWinPersonnages.TabAugmentationAttributSelectEditor(Sender: TObject;
  aCol, aRow: Integer; var Editor: TWinControl);
begin
  if ((aCol <> ColAugmAttNouveau) and (ACol <> ColAugmAttReel)) or (aRow = 0) or ((aCol = ColAugmAttNouveau) and (CheckBoxXpDiv25.checked = true)) then
     Editor := nil;
end;

procedure TWinPersonnages.TabAugmentationCompetenceCalcul(ARow: Integer; var Value: string);
  var
    CellValue: Integer;
    ValeurMin: Integer = 0;
    ValeurMax: Integer = 99;
    Xp:        Integer = 0;
  begin
    // Vérifier si la cellule en cours d'édition contient une valeur numérique valide
    if TryStrToInt(Value, CellValue) then
    begin
      // Appliquer les limites minimale et maximale
      ValeurMin := StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompActuel, ARow],0);
      CellValue := Min(Max(CellValue, ValeurMin), ValeurMax);
      // Formater la valeur avec un nombre de décimales spécifié
      if StrToIntDef(Value,0) >= ValeurMin then
        begin
          Value := IntToStr(CellValue);
          Xp    := CalculExperience(ConstXmlCompetence, StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompActuel, aRow],0), CellValue, '');
          if Xp > 0 then
            TabAugmentationCompetence.Cells[ColAugmCompCout, aRow] := IntToStr(Xp)
          else
            TabAugmentationCompetence.Cells[ColAugmCompCout, aRow] := '';
          if TabAugmentationCompetence.Cells[2, ARow] = CouleurKo then
            TabAugmentationCompetence.Cells[ColAugmCompReel, aRow]   := IntToStr(Xp * 2)
          else
            TabAugmentationCompetence.Cells[ColAugmCompReel, aRow]   := IntToStr(Xp);
          CalculTableExperience();
        end;
    end;
  end;

procedure TWinPersonnages.TabAugmentationCompetenceGetEditText(Sender: TObject;
  ACol, ARow: Integer; var Value: string);
begin
  // Vérifier si la colonne actuelle correspond à la colonne que vous souhaitez formater
  if ACol = ColAugmCompNouveau then
  begin
    TabAugmentationCompetenceCalcul(Arow, Value);
    PreviousRowIndexC := aRow;
  end;
end;

procedure TWinPersonnages.TabAugmentationCompetenceSelectCell(Sender: TObject;
  aCol, aRow: Integer; var CanSelect: Boolean);
var
  CellValue: Integer;
  ValeurMin: Integer = 0;
  ValeurMax: Integer = 99;
  Xp:        Integer = 0;
begin
  MajBoutonsSpecialisation(aRow, 0);
  if (aCol = ColAugmCompNouveau) and (PreviousRowIndexC > 0) then
    begin
      // Appliquer les limites minimale et maximale
      ValeurMin := StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompActuel, PreviousRowIndexC],0);
      CellValue := Min(Max(StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompNouveau, PreviousRowIndexC],0), ValeurMin), ValeurMax);
      // Formater la valeur avec un nombre de décimales spécifié
      TabAugmentationCompetence.Cells[ColAugmCompNouveau, PreviousRowIndexC] := IntToStr(CellValue);
      Xp    := CalculExperience(ConstXmlCompetence, StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompActuel, PreviousRowIndexC ],0), StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompNouveau, PreviousRowIndexC ],0), '');
      if Xp > 0 then
        TabAugmentationCompetence.Cells[ColAugmCompCout, PreviousRowIndexC ] := IntToStr(Xp)
      else
        TabAugmentationCompetence.Cells[ColAugmCompCout, PreviousRowIndexC ] := '';
      if TabAugmentationCompetence.Cells[2, ARow] = CouleurKo then
        TabAugmentationCompetence.Cells[ColAugmCompReel, PreviousRowIndexC]   := IntToStr(StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompCout, PreviousRowIndexC],0) * 2)
      else
        TabAugmentationCompetence.Cells[ColAugmCompReel, PreviousRowIndexC]   := IntToStr(StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompCout, PreviousRowIndexC],0));

      PreviousRowIndexC := aRow;
      CalculTableExperience();
    end;
end;

procedure TWinPersonnages.TabAugmentationCompetenceSelectEditor(
  Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if ((aCol <> ColAugmCompNouveau) and (aCol <> ColAugmCompReel))
         or (aRow = 0)
         or ((TabAugmentationCompetence.Cells[ColAugmCompSpe, aRow] = GetTexteLibelle(ConstLabSelSpe)))
         or ((TabAugmentationCompetence.Cells[ColAugmCompLib, aRow] = GetTexteLibelle(ConstLabAdd)))
         or ((aCol = ColAugmCompNouveau) and (CheckBoxXpDiv25.checked = true))
         then
     Editor := nil;
end;

procedure TWinPersonnages.TabLivreDblClick(Sender: TObject);
begin
  // cocher ou décocher le livre en cours (sauf RULESBOOK qui est en 1)
  if (TabLivre.Row > 1) then
    if TabLivre.Cells[2, TabLivre.Row] <> '' then
      if TabLivre.Cells[1, TabLivre.Row] <> ConstSelectionne then
        TabLivre.Cells[1, TabLivre.Row] := ConstSelectionne
      else
        TabLivre.Cells[1, TabLivre.Row] := '';
end;

// Colonne 0 : case a cocher de l'equipement de niveau (decochee par defaut).
procedure TWinPersonnages.TabMetierEquipementClick(Sender: TObject);
  begin
    if (TabMetierEquipement.Col = 0) and (TabMetierEquipement.Row > 0) then
      if TabMetierEquipement.Cells[0, TabMetierEquipement.Row] = CaseCochee then
        TabMetierEquipement.Cells[0, TabMetierEquipement.Row] := CaseVide
      else
        TabMetierEquipement.Cells[0, TabMetierEquipement.Row] := CaseCochee;
  end;

// Ajoute a TabEquipement les lignes cochees de l'equipement de niveau ; TabEquipement est ensuite
// recopiee dans Personnage.Equipement (MajTables). Le suffixe (Q) donne la fabrication marqueur
// "qualite a ajouter" (QualiteDepuisCode). Le type d'une ligne issue d'un choix est deduit du code.
procedure TWinPersonnages.AjouteEquipementNiveau();
  var
    Ind:     Integer;
    Code:    String;
    Qualite: String;
    Typ:     String;
  begin
    for Ind := 1 to TabMetierEquipement.RowCount - 1 do
      if (TabMetierEquipement.Cells[0, Ind] = CaseCochee) and (TabMetierEquipement.Cells[1, Ind] <> '') then
        begin
          Code    := TabMetierEquipement.Cells[1, Ind];
          Qualite := QualiteDepuisCode(Code);
          Typ     := TabMetierEquipement.Cells[4, Ind];
          if Typ = '' then
            if ChercheArme(Code).CodeArme <> '' then
              Typ := TypeEquipWe
            else if ChercheArmure(Code).CodeArmure <> '' then
              Typ := TypeEquipAr
            else if TrappingEstAnimal(ChercheTrapping(Code)) then
              Typ := TypeEquipAN
            else
              Typ := TypeEquipDI;
          TabEquipement.RowCount                          := TabEquipement.RowCount + 1;
          TabEquipement.Cells[0, TabEquipement.RowCount-1]:= '+';
          TabEquipement.Cells[1, TabEquipement.RowCount-1]:= IntToStr(TabEquipement.RowCount);
          TabEquipement.Cells[2, TabEquipement.RowCount-1]:= Code;
          TabEquipement.Cells[3, TabEquipement.RowCount-1]:= Typ;
          TabEquipement.Cells[4, TabEquipement.RowCount-1]:= TabMetierEquipement.Cells[2, Ind];
          TabEquipement.Cells[7, TabEquipement.RowCount-1]:= Qualite;
          TabEquipement.Cells[9, TabEquipement.RowCount-1]:= IntToStr(StrToIntDef(TabMetierEquipement.Cells[6, Ind], 1));
          TabMetierEquipement.Cells[0, Ind]               := CaseVide;
        end;
    RafraichitTabEquipementAffichage();
  end;

procedure TWinPersonnages.TabMetierEquipementDblClick(Sender: TObject);
  begin
    if (TabMetierEquipement.col = 2) and (TabMetierEquipement.Cells[2, TabMetierEquipement.Row] = ConstArbreAuchoix) then
      Begin
        ChoixWinTypeFichier         := ConstXmlChapitreEquipement;
        ChoixWinEquipement          := TabMetierEquipement.Cells[3, TabMetierEquipement.Row];
        SelectWinLivre              := Personnage.LivresAcceptes;
        FenSpecialisation           := TWinSpecialisations.Create(Application);
        FenSpecialisation.Position  := poOwnerFormCenter;
        FenSpecialisation.ShowModal;
        SelectWinLivre := '';
        if SelectWinEquipement <> '' then
          begin
            TabMetierEquipement.Cells[1, TabMetierEquipement.Row] := SelectWinEquipement;
            TabMetierEquipement.Cells[2, TabMetierEquipement.Row] := SelWinLibelle;
          end;
      end;
  end;

procedure TWinPersonnages.TabMetierEquipementSelectEditor(Sender: TObject;
  aCol, aRow: Integer; var Editor: TWinControl);
begin
  Editor := nil;
end;

procedure TWinPersonnages.TabSheetMjCostContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
begin

end;

procedure TWinPersonnages.TabAugmentationTalentCalcul(ARow: Integer; var Value: string);
  var
    CellValue: Integer;
    ValeurMin: Integer = 0;
    ValeurMax: Integer = 1;
    Xp:        Integer = 0;
    PTalent:   StructureTalent;
    Calcul:    String;
    Ind:       Integer;
    Carac:     String;
  begin
    // Vérifier si la cellule en cours d'édition contient une valeur numérique valide
    if TryStrToInt(Value, CellValue) then
    begin
      // Appliquer les limites minimale et maximale
      ValeurMin := StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalActuel, ARow],0);
      PTalent := ChercheTalent(TabAugmentationTalent.Cells[ColAugmTalCode, ARow]);
      if PTalent.MaxiTalent <> '' then
        if not TryStrToInt(PTalent.MaxiTalent, ValeurMax) then
          begin
            Calcul := PTalent.MaxiTalent;
            Carac  := StringReplace(ExtractStringAfter(Calcul, '(B'),')','',[rfReplaceAll]);
            For Ind := 1 to TabAttribut.ColCount - 1 do
              if (CodeSansLivre(tabAttribut.Cells[Ind, LigAttCode]) = Carac) then                begin
                  ValeurMax := trunc(StrToIntDef(tabAttribut.Cells[Ind, LigAttTotal],0) / 10);
                  break;
                end;
          end;

      CellValue := Min(Max(CellValue, ValeurMin), ValeurMax);
      // Formater la valeur avec un nombre de décimales spécifié
      Value := IntToStr(CellValue);
      Xp    := CalculExperience(ConstXmlTalent, StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalActuel, aRow],0), CellValue, '');
      // afficher cout normal
      if Xp > 0 then
        TabAugmentationTalent.Cells[ColAugmTalCout, aRow] := IntToStr(Xp)
      else
        TabAugmentationTalent.Cells[ColAugmTalCout, aRow] := '';
      // calcul cout réel (x2)
      if TabAugmentationTalent.Cells[2, ARow] = CouleurKo then
        TabAugmentationTalent.Cells[ColAugmTalReel, aRow]   := IntToStr(StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalCout, aRow],0) * 2)
      else
        TabAugmentationTalent.Cells[ColAugmTalReel, aRow] := TabAugmentationTalent.Cells[ColAugmTalCout, aRow];
    end;
    CalculTableExperience();
  end;

procedure TWinPersonnages.TabAugmentationTalentGetEditText(Sender: TObject;
  ACol, ARow: Integer; var Value: string);
begin
  // Vérifier si la colonne actuelle correspond à la colonne que vous souhaitez formater
  if (ACol = ColAugmTalNouveau) then
    begin
      PreviousRowIndexT := aRow;
      TabAugmentationTalentCalcul(ARow, Value);
    end;
  SortAffiche();

end;

procedure TWinPersonnages.TabAugmentationTalentSelectCell(Sender: TObject;
  aCol, aRow: Integer; var CanSelect: Boolean);
var
  CellValue: Integer;
  ValeurMin: Integer = 0;
  ValeurMax: Integer = 1;
  Xp:        Integer = 0;
  Ind:       Integer = 0;
begin
  MajBoutonsSpecialisation(0, aRow);
  if PreviousRowIndexT > 0 then
  begin
    // Appliquer les limites minimale et maximale
    ValeurMin := StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalActuel, PreviousRowIndexT],0);
    for Ind := 1 to TabTalent.RowCount - 1 do
      if TabTalent.Cells[ColTalCode, Ind] = TabAugmentationTalent.Cells[ColAugmTalCode, PreviousRowIndexT] then
        begin
          ValeurMax := StrToIntDef(TabTalent.Cells[ColTalMax, Ind],1);
          Break;
        end;
    CellValue := Min(Max(StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalNouveau, PreviousRowIndexT],0), ValeurMin), ValeurMax);
    // Formater la valeur avec un nombre de décimales spécifié
    TabAugmentationTalent.Cells[ColAugmTalNouveau, PreviousRowIndexT] := IntToStr(CellValue);
    Xp    := CalculExperience(ConstXmlTalent, StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalActuel, PreviousRowIndexT ],0), StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalNouveau, PreviousRowIndexT ],0), '');
    if Xp > 0 then
      TabAugmentationTalent.Cells[ColAugmTalCout, PreviousRowIndexT ] := IntToStr(Xp)
    else
      TabAugmentationTalent.Cells[ColAugmTalCout, PreviousRowIndexT ] := '';
    // calcul cout réel (x2)
    if TabAugmentationTalent.Cells[2, ARow] = CouleurKo then
      TabAugmentationTalent.Cells[ColAugmTalReel, PreviousRowIndexT]   := IntToStr(StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalCout, PreviousRowIndexT],0) * 2)
    else
      TabAugmentationTalent.Cells[ColAugmTalReel, PreviousRowIndexT] := TabAugmentationTalent.Cells[ColAugmTalCout, PreviousRowIndexT];
    PreviousRowIndexT := aRow;
    CalculTableExperience();
  end;
end;

procedure TWinPersonnages.TabAugmentationTalentSelectEditor(Sender: TObject;
  aCol, aRow: Integer; var Editor: TWinControl);
begin
  if ((aCol <> ColAugmTalNouveau) and (aCol <> ColAugmTalReel))
         or (aRow = 0)
         or (TabAugmentationTalent.Cells[ColAugmTalLib, ARow] = GetTexteLibelle(ConstLabAdd)) then
     Editor := nil;
end;

procedure TWinPersonnages.TabDrawCell(Sender: TObject; aCol,
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

  CellText: string;
  TextWidth: Integer;
  TextX: Integer;
  TextY: integer;
  Grid:  TStringGrid;
  LignesTexte: TStringList;
  IndLigneTxt: Integer;
  HautLigneTxt: Integer;
  BandeTxt: TRect;
begin
    Grid := TStringGrid(Sender);
    if (aCol > 0) then
     begin
       if aRow = 0 then
         begin
           // Dessiner le fond de la cellule de l'entête
           Grid.Canvas.Brush.Color := clBlack;
           Grid.Canvas.FillRect(aRect);

           // Dessiner le texte de l'entête centré horizontalement et verticalement
           Grid.Canvas.Font.Color := clWhite;
           Grid.Canvas.Font.Style := [fsBold];
           Grid.Canvas.Font.Size  := 10;
           Grid.Canvas.Font.Name  := ConstPoliceArial;

           // Calculer la position x et y du texte pour l'alignement centré
           if aCol > 0 then
           begin
             CellText  := Grid.Cells[aCol, aRow]; //Grid.Columns[aCol-1].Title.Caption; //
             TextWidth := Grid.Canvas.TextWidth(CellText);
             TextX     := aRect.Left + (aRect.Right - aRect.Left - TextWidth) div 2;
             TextY     := aRect.Top + (aRect.Bottom - aRect.Top - Grid.Canvas.TextHeight(CellText)) div 2;

             // Dessiner le texte de l'entête
             Grid.Canvas.TextRect(aRect, TextX, TextY, CellText);
           end;
         end
     else if (aCol = ColCompImage) then
        begin
          // Récupérer la valeur de la cellule correspondante (colonne 2)
          ImageIndex := StrToIntDef(Grid.Cells[aCol, aRow], -1);

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
            LeftOffset:= (CellWidth - ImageWidth) div 2;
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
            ListImage.Draw(Grid.Canvas, ImageRect.Left, ImageRect.Top, ImageIndex);
          end
          else
            // Dessiner du texte par défaut si la valeur de l'index d'image est invalide
            Grid.DefaultDrawCell(aCol, aRow, aRect, aState);
        end
      else
        begin
          // Obtenir la couleur du pixel en haut à gauche de l'image de la cellule précédente (colonne 2)
          Bitmap := TBitmap.Create;
          try
            ImageIndex := StrToIntDef(Grid.Cells[ColCompImage, aRow], -1);
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
            Grid.Canvas.Brush.Color := TopLeftPixelColor;
            Grid.Canvas.FillRect(aRect);
          end;

          // Changer la couleur du texte pour les colonnes 3 à 6
          // Ligne grisee si l'equipement (arme ou armure, colonne 3) n'est pas "porte"
          // (colonne 8 vide) : visibilite immediate de ce qui est reellement sur soi,
          // demande par Nono suite au signalement "armure a 0 PA" du 26/09/2026 (case
          // "porte" non cochee, invisible jusque-la dans la grille).
          if (Grid = TabEquipementAffichage) and
             (Grid.Cells[8, aRow] = '') and
             ((TrimRight(Grid.Cells[3, aRow]) = TrimRight(TypeEquipAR)) or
              (TrimRight(Grid.Cells[3, aRow]) = TrimRight(TypeEquipARS)) or
              (TrimRight(Grid.Cells[3, aRow]) = TrimRight(TypeEquipWe))) then
            Grid.Canvas.Font.Color := clGray
          else
            Grid.Canvas.Font.Color := clBlack;

          // Calculer la position x du texte pour l'alignement horizontal centré
          // en utilisant la largeur de la cellule et la largeur du texte
          CellText := Grid.Cells[aCol, aRow];
          TextWidth := Grid.Canvas.TextWidth(CellText);
          if ACol = 3 then
            TextX := aRect.Left + 5 //(aRect.Right - aRect.Left + 5)
          else
            TextX := aRect.Left + (aRect.Right - aRect.Left - TextWidth) div 2;

          // Dessiner le texte avec l'alignement vertical centré
          Grid.Canvas.FillRect(aRect);
          if Pos(LineEnding, CellText) > 0 then
            begin
              // Cellule multiligne (fabrications de TabEquipement) : une ligne par element, le
              // bloc centre verticalement. 20/09/2026.
              LignesTexte := TStringList.Create;
              try
                LignesTexte.Text := CellText;
                // Hauteur d'une ligne = celle de l'AfficheFabrication (TextHeight + 2), lue une
                // seule fois ; chaque ligne a sa propre bande, decoupee dans la cellule.
                HautLigneTxt := Grid.Canvas.TextHeight('Ag') + 2;
                if HautLigneTxt < 14 then HautLigneTxt := 14;
                TextY := aRect.Top + (aRect.Bottom - aRect.Top - LignesTexte.Count * HautLigneTxt) div 2;
                if TextY < aRect.Top then TextY := aRect.Top;
                for IndLigneTxt := 0 to LignesTexte.Count - 1 do
                  begin
                    BandeTxt := Rect(aRect.Left, TextY + IndLigneTxt * HautLigneTxt, aRect.Right, TextY + (IndLigneTxt + 1) * HautLigneTxt);
                    if BandeTxt.Bottom > aRect.Bottom then BandeTxt.Bottom := aRect.Bottom;
                    if BandeTxt.Top >= BandeTxt.Bottom then Continue;
                    if aCol = 3 then
                      TextX := aRect.Left + 5
                    else
                      TextX := aRect.Left + (aRect.Right - aRect.Left - Grid.Canvas.TextWidth(LignesTexte[IndLigneTxt])) div 2;
                    Grid.Canvas.TextRect(BandeTxt, TextX, BandeTxt.Top + 1, LignesTexte[IndLigneTxt]);
                  end;
              finally
                LignesTexte.Free;
              end;
            end
          else
            Grid.Canvas.TextRect(aRect, TextX, aRect.Top + (aRect.Bottom - aRect.Top - Grid.Canvas.TextHeight(CellText)) div 2, CellText);

          // Virtue of the Quest (CONTEXT.md 2.78) : talent possede mais dont les effets
          // sont en sommeil hors de la carriere+niveau qui l'a accorde - barre plutot que
          // retire (le vrai retrait n'est pas encore mecanise).
          if (Grid = TabTalent) and (aCol = ColTalLib) and
             PersonnageTalentEstBarre(Personnage, TabTalent.Cells[ColTalCode, aRow]) then
            Grid.Canvas.Line(TextX, aRect.Top + (aRect.Bottom - aRect.Top) div 2,
                              TextX + TextWidth, aRect.Top + (aRect.Bottom - aRect.Top) div 2);
        end;
      end;
  end;

// Trois champs de monnaie (Couronne d'or, Pistole d'argent, Sou de laiton) sur la ligne
// d'aide de l'equipement, alignes a droite de la grille. Saisie seule : pas encore sauvegardes.
// Trois champs de monnaie (Couronne d'or, Pistole d'argent, Sou de laiton) sur la page Monnaie,
// l'un sous l'autre : libelle puis champ.
procedure TWinPersonnages.PlaceChampsMonnaie();
  const
    Libelles: array[0..2] of String = ('RULES-LAB_222', 'RULES-LAB_223', 'RULES-LAB_224');
    LargeurEdit = 80;
  var
    i, Y, LargeurLib: Integer;
  begin
    LargeurLib := 0;
    for i := 0 to 2 do
      begin
        if EditMonnaie[i] = nil then
          begin
            EditMonnaie[i]         := TEdit.Create(Self);
            EditMonnaie[i].Parent  := PageMonnaie;
            EditMonnaie[i].Text    := '0';
            EditMonnaie[i].NumbersOnly := True;
            LabMonnaie[i]          := TLabelContour.Create(Self);
            LabMonnaie[i].Parent   := PageMonnaie;
            LabMonnaie[i].Font.Color := clWhite;
          end;
        LabMonnaie[i].Caption := GetTexteLibelle(Libelles[i]);
        if LabMonnaie[i].Width > LargeurLib then LargeurLib := LabMonnaie[i].Width;
      end;
    Y := 16;
    for i := 0 to 2 do
      begin
        LabMonnaie[i].SetBounds(16, Y + 3, LabMonnaie[i].Width, LabMonnaie[i].Height);
        EditMonnaie[i].SetBounds(16 + LargeurLib + 8, Y, LargeurEdit, EditMonnaie[i].Height);
        Y := Y + EditMonnaie[i].Height + 8;
      end;
  end;

procedure TWinPersonnages.AjustePositionTables();
  var
    StartTB:    Integer = 0;
    EditLeft:   Integer = 0;
  begin
    // MaxHeight=0 fait retomber AdjustGridColumnsWidth sur Form.Height (chargeconstantes.pas)
    // pour decider si une marge de 20 doit s'ajouter a la Largeur (place reservee a un
    // ascenseur si le contenu depasserait la hauteur de fenetre). Form.Height est la hauteur
    // EN DIRECT, qui change a chaque tick pendant un redimensionnement (AjustePositionTables
    // est maintenant rappelee sur OnResize) - cette marge de 20 apparaissait/disparaissait
    // donc au fil du drag, decalant TabCompetence/TabEquipement et tout ce qui en depend en
    // cascade (PageExperience, TabEquipement, les 6 boutons d'equipement). Bug trouve en
    // testant l'ancrage le 12/09/2026 (Nono : "meme sans Anchors, ca bouge"). Corrige en
    // passant une hauteur fixe, largement superieure au contenu de ces grilles, plutot que 0 -
    // la marge ascenseur ne peut alors plus jamais se declencher au fil d'un redimensionnement.
    // ScaleDpi=false sur les 16 appels de cette fonction (meme correctif que RafraichirLibellesMenu,
    // CONTEXT.md 2.8) : AdjustGridColumnsWidth appelle Grid.ScaleFormToDesign(96), qui remet a
    // l'echelle DPI la fenetre PROPRIETAIRE ENTIERE a chaque appel - inoffensif une fois au
    // demarrage, cumulatif si rappele sans repartir d'un etat neuf. Garde par precaution (meme
    // anti-motif que 2.8) mais N'EST PAS la cause du saut de CheckBoxQuickArmor/boutons
    // equipement au redimensionnement signale par Nono le 12/09/2026 - diagnostic en direct
    // (CONTEXT.md 2.64) : Self.Width est la seule valeur qui bouge pendant le drag, tout le
    // reste (TabEquipement, boutons) reste fixe. Artefact d'affichage Windows, ferme tel quel.
    AdjustGridColumnsWidth(TabAttribut, 9999, false, false, false, 0, 0, ssnone, false);
    AdjustGridColumnsWidth(TabTalent, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabCarriere, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabCompetence, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabNiveau, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabAvancement, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabExperience, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabEquipement, 9999, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabAugmentationAttribut, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabAugmentationCompetence, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabAugmentationTalent, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabHistorique, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabSort, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabLivre, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);
    AdjustGridColumnsWidth(TabAugmentationMjXp, PageExperience.Height - 40, false, false, true, 0, 0, ssautoboth, false);

    // Ligne 2
       // Colonne données générique
    LabAge.left               := LabTabAttribut.left;
    LabHeight.left            := LabTabAttribut.left;
    LabHairColors.left        := LabTabAttribut.left;
    LabEyeColors.left         := LabTabAttribut.left;

    LabAge.Top                := TabAttribut.Top   + TabAttribut.Height   + 3;
    LabHeight.Top             := LabAge.Top        + LabAge.Height        + 3;
    LabHairColors.Top         := LabHeight.Top     + LabHeight.Height     + 3;
    LabEyeColors.Top          := LabHairColors.Top + LabHairColors.Height + 3;

    EditLeft                  := LabTabAttribut.left + ( PremierAjustage * ( max(max(max(LabAge.Width, LabHeight.Width), LabHairColors.Width), LabEyeColors.Width) ) );
    PremierAjustage           := 1;

    EditAge.top               := LabAge.Top          + Round(LabAge.Height / 3);
    EditHeight.top            := LabHeight.Top       + Round(LabHeight.Height / 3);
    EditHairColors.top        := LabHairColors.Top   + Round(LabHairColors.Height / 3);
    EditEyeColors.top         := LabEyeColors.Top    + Round(LabEyeColors.Height / 3);

    EditAge.left              := EditLeft;
    EditHeight.left           := EditLeft;
    EditHairColors.left       := EditLeft;
    EditEyeColors.left        := EditLeft;

    // Bouton de tirage des details physiques : sous les quatre champs, sur toute leur largeur
    ButtonPhysique.Left       := LabTabAttribut.left;
    ButtonPhysique.Top        := LabEyeColors.Top + LabEyeColors.Height + 3;
    ButtonPhysique.Width      := EditLeft + EditAge.Width - LabTabAttribut.left;
    // Signe astral : sous le bouton, meme largeur
    EditSigne.Left            := ButtonPhysique.Left;
    EditSigne.Top             := ButtonPhysique.Top + ButtonPhysique.Height + 3;
    EditSigne.Width           := ButtonPhysique.Width;

       // Colonne Carrière
    LabTabCarriere.Left       := EditLeft + EditAge.Width + 10;
    TabCarriere.left          := LabTabCarriere.left;
    LabTabCarriere.Top        := TabAttribut.Top + TabAttribut.Height + 10;
    TabCarriere.Top           := LabTabCarriere.Top + LabTabCarriere.Height;// + 20;

       // Colonne Expérience
    LabTabExperience.Left     := TabCarriere.left + TabCarriere.Width + 20;
    LabTabExperience.Top      := LabTabCarriere.Top;
    TabExperience.left        := LabTabExperience.left;
    TabExperience.Top         := TabCarriere.Top;

    // Ligne 3
       // Colonne Talents
    LabTabTalent.Top          := TabCarriere.Top + Max(TabCarriere.Height, TabExperience.Height) + 15;
    // La colonne de gauche (details physiques, bouton Roll, signe astral) peut etre plus haute que
    // les tableaux Carriere/Experience : la ligne des talents passe sous elle, sinon Roll chevauche
    // le libelle « Talent ».
    if EditSigne.Visible then
      LabTabTalent.Top        := Max(LabTabTalent.Top, EditSigne.Top + EditSigne.Height + 15)
    else
      LabTabTalent.Top        := Max(LabTabTalent.Top, ButtonPhysique.Top + ButtonPhysique.Height + 15);
    TabTalent.Top             := LabTabTalent.Top + LabTabTalent.Height;// + 20;
    LabTabCompetence.Top      := LabTabTalent.Top;
    TabCompetence.Top         := TabTalent.Top;

      // colonne Compétences
    TabCompetence.left        := TabTalent.left + TabTalent.Width + 40;
    LabTabCompetence.Left     := TabCompetence.left;

    if (TabCompetence.left + TabCompetence.Width) > (TabAttribut.left + TabAttribut.Width) then
      StartTB                 := TabCompetence.left + TabCompetence.Width
    else
      StartTB                 := TabAttribut.left + TabAttribut.Width;
    ToggleBoxDroite.Left      := StartTB + 10;
    ListBoxExperience.Left    := ToggleBoxDroite.Left + 20;
    // ListBoxExperience remplace la bande d'onglets de PageExperience (scission de
    // l'equipement, 24/09/2026) : largeur fixe, PageExperience demarre juste apres.
    ListBoxExperience.Width   := 130;
    PageExperience.left       := ListBoxExperience.Left + ListBoxExperience.Width + 8;
    // La Largeur doit suivre le Left, sinon le bord droit part hors fenetre quand
    // ToggleBoxDroite.Left grandit (cases de detail Xp/Calcul, Nono le 12/09/2026) -
    // PageExperience garde 20 de marge avec le bord droit du client, comme les autres
    // marges de cette fonction.
    PageExperience.Width      := Self.ClientWidth - PageExperience.left - 20;

    LabAugmentation.Left      := ToggleBoxDroite.Left + 20;
    LabAugmentation.top       := 0;

    ButtonAugmentation.Left   := LabAugmentation.Left;
    ButtonAugmentation.Top    := LabAugmentation.Top + LabAugmentation.Height + 10;
    ButtonSauvegarde.Left     := ButtonAugmentation.Left + ButtonAugmentation.Width + 10;
    ButtonSauvegarde.Top      := ButtonAugmentation.Top;

    PageExperience.Top        := ButtonAugmentation.Top + ButtonAugmentation.Height + 10;
    ListBoxExperience.Top     := PageExperience.Top;
    ListBoxExperience.Height  := PageExperience.Height;

    // colonne 4

    StaticTextPersonnage.left := ToggleBoxGauche.left + floor((ToggleBoxdroite.left - ToggleBoxGauche.left) / 2) - floor(StaticTextPersonnage.Width / 2);
    LabEquipement.left        := ToggleBoxdroite.left + 100;
    LabEquipement.Top         := PageExperience.Top + PageExperience.Height + 50;

    ButtonLigneGauche.left    := ToggleBoxGauche.Left + 10;
    ButtonLigneGauche.Width   := ToggleBoxDroite.Left - ToggleBoxGauche.left - 10;
    ButtonPdf.Left            := ToggleBoxDroite.left - ButtonPdf.width - 10;

    ButtonSauvegarde.left     := PageExperience.left;

    TabEquipement.Left        := PageExperience.left;
    TabEquipement.Top         := LabEquipement.top + LabEquipement.Height + 5 + LabPorteAide.Height + 5;

    // Liste de categories + grille d'affichage filtree (CONTEXT.md etape 2) : meme agencement
    // que ListBoxExperience/PageExperience, a l'emplacement de l'ancien TabEquipement (desormais
    // masque, cf. commentaire a son affectation OnSelectEditor plus haut).
    ListBoxEquipementCategorie.Left    := ListBoxExperience.Left;
    ListBoxEquipementCategorie.Top     := TabEquipement.Top;
    ListBoxEquipementCategorie.Width   := 130;
    ListBoxEquipementCategorie.Height  := TabEquipement.Height;

    TabEquipementAffichage.Left   := ListBoxEquipementCategorie.Left + ListBoxEquipementCategorie.Width + 8;
    TabEquipementAffichage.Top    := TabEquipement.Top;
    TabEquipementAffichage.Width  := TabEquipement.Width - ListBoxEquipementCategorie.Width - 8;
    TabEquipementAffichage.Height := TabEquipement.Height;

    ButtonArme.left           := TabEquipementAffichage.left + TabEquipementAffichage.Width + 10;
    ButtonArmure.left         := ButtonArme.left;
    ButtonFabrication.left    := ButtonArme.left;
    ButtonDelete.left         := ButtonArme.left;
    ButtonSort.left           := ButtonArme.left;
    ButtonEquipement.left     := ButtonArme.left;
    ButtonTexte.left          := ButtonArme.left;
    ButtonObjet.left          := ButtonArme.left;
    CheckBoxQuickArmor.left   := ButtonArme.left;
    LabQuickArmor.left        := CheckBoxQuickArmor.left + CheckBoxQuickArmor.Width + 10;
    CheckBoxMunition.left     := ButtonArme.left;
    LabMunition.left          := CheckBoxMunition.left + CheckBoxMunition.Width + 10;

    ButtonArme.Top            := TabEquipement.Top;
    CheckBoxQuickArmor.Top    := ButtonArme.Top + ButtonArme.Height + 10;
    LabQuickArmor.Top         := ButtonArme.Top + ButtonArme.Height + 10;
    CheckBoxMunition.Top      := CheckBoxQuickArmor.Top + CheckBoxQuickArmor.Height + 10;
    LabMunition.Top           := CheckBoxMunition.Top;
    ButtonArmure.Top          := CheckBoxMunition.Top + CheckBoxMunition.Height + 10;
    ButtonDelete.Top          := ButtonArmure.Top + ButtonArmure.Height + 10;
    ButtonFabrication.Top     := ButtonDelete.Top + ButtonDelete.Height + 10;
    ButtonSort.Top            := ButtonFabrication.Top + ButtonFabrication.Height + 10;
    ButtonEquipement.Top      := ButtonSort.Top + ButtonSort.Height + 10;
    ButtonTexte.Top           := ButtonEquipement.Top + ButtonEquipement.Height + 10;
    // meme place que +Sort (categorie Sorts) : les deux ne sont jamais visibles ensemble
    ButtonObjet.Top           := ButtonSort.Top;
    // Texte d'aide : sous le titre LabEquipement, au-dessus du tableau (decale vers le bas).
    LabPorteAide.Left         := LabEquipement.Left;
    LabPorteAide.Top          := LabEquipement.Top + LabEquipement.Height + 5;
    PlaceChampsMonnaie();

    ImageSheetTitle.Width     := ToggleBoxDroite.Left;
    ImageSheetPage.Width      := ToggleBoxDroite.Left;
    ImageSheetXp.Left         := ToggleBoxDroite.Left;
    ImageSheetXp.Width        := Self.Width - ToggleBoxDroite.Left;
    ImageSheetXp.Height       := Self.Height;
  end;

procedure TWinPersonnages.EditHeightKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['0'..'9', #8, #9]) then Key := #0;
end;

procedure TWinPersonnages.Label1Click(Sender: TObject);
begin

end;

procedure TWinPersonnages.PageExperienceChange(Sender: TObject);
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to PageExperience.PageCount  -1 do
    For J := TPage(PageExperience.Page[I]).ControlCount - 1 downto 0 do
      if TPage(PageExperience.Page[I]).Controls[J] is TPanel then
        TPanel(TPage(PageExperience.Page[I]).Controls[J]).SendToBack;
  // Synchronise la liste laterale sur la page reellement active (PageIndex change
  // aussi par du code, pas seulement par clic dans la liste - CodesFittingGrille etc.
  // n'existent pas ici, mais d'autres ecrans font PageExperience.PageIndex := ... direct).
  if ListBoxExperience.ItemIndex <> PageExperience.PageIndex then
    ListBoxExperience.ItemIndex := PageExperience.PageIndex;
  MajReserves();
  // le bouton +Specialisation suit la page active, quelle que soit la facon dont elle a change
  MajBoutonsSpecialisation(0, 0);
  Application.QueueAsyncCall(@MajBoutonsSpecialisationDiffere, 0);
  // TNotebook (contrairement a TPageControl) est un TCustomControl "fait main" qui
  // bascule Visible sur ses pages au lieu d'un vrai controle a onglets Windows - les
  // controles natifs (RadioButton...) de la page qui redevient visible ratent parfois
  // leur premier repaint (texte absent jusqu'a un redessin force). Invalidation forcee
  // de la page active et de ses enfants pour eviter d'avoir a "refaire l'affichage"
  // a la main (24/09/2026, scission de l'equipement par categorie).
  // ECHEC : n'a pas resolu le texte invisible (RadioButtonRAS/Suivant/Changer,
  // page Evolution) - teste par Nono le 24/09/2026 au soir, symptome inchange.
  if (PageExperience.PageIndex >= 0) and (PageExperience.PageIndex < PageExperience.PageCount) then
    begin
      for J := TPage(PageExperience.Page[PageExperience.PageIndex]).ControlCount - 1 downto 0 do
        if TPage(PageExperience.Page[PageExperience.PageIndex]).Controls[J] is TControl then
          TControl(TPage(PageExperience.Page[PageExperience.PageIndex]).Controls[J]).Invalidate;
      TPage(PageExperience.Page[PageExperience.PageIndex]).Invalidate;
    end;
end;

procedure TWinPersonnages.ListBoxExperienceClick(Sender: TObject);
begin
  // TNotebook n'a pas d'evenement OnPageChanged publie dans cette LCL (OnChange y est
  // commente dans extctrls.pp) : PageExperienceChange ne se declenche pas tout seul au
  // changement de PageIndex, contrairement a TPageControl.OnChange - appel direct,
  // necessaire pour la synchro de la liste ET le repaint force (24/09/2026).
  // ECHEC egalement (voir PageExperienceChange ci-dessus) : symptome inchange.
  if (ListBoxExperience.ItemIndex >= 0) and (ListBoxExperience.ItemIndex <> PageExperience.PageIndex) then
    begin
      PageExperience.PageIndex := ListBoxExperience.ItemIndex;
      PageExperienceChange(Self);
    end;
  MajBoutonsSpecialisation(0, 0);
end;

procedure TWinPersonnages.RadioButtonRASChange(Sender: TObject);
begin
  ChargerMetierEquipement('',0);
  NvMetierChoisi := '';
  ChargeComboNvMetier();
  TabEquipementAffiche();
  CalculXpNecessaire(false);
end;

procedure TWinPersonnages.TabEquipementAffiche();
  begin
      TabMetierEquipement.visible := ( (RadioButtonSuivant.checked) or (RadioButtonChanger.Checked) );
  end;

// Seule la colonne Quantite (9) est saisissable, et seulement sur un objet Divers ou une
// munition (arme dont le code porte MUNI_) ou petite arme de lancer (competence Projectile
// Lancer, COMPPROJ_LANC, encombrement 0 : couteau, fleche, pierre...). Une arme de lancer
// encombrante (javelot) se saisit ligne par ligne.
procedure TWinPersonnages.TabEquipementSelectEditor(Sender: TObject; aCol, aRow: Integer;
    var Editor: TWinControl);
  var
    Code:     String;
    PArme:    StructureArme;
    Editable: Boolean;
  begin
    Editable := false;
    if (aCol = 9) and (aRow > 0) then
      begin
        Code := TabEquipementAffichage.Cells[2, aRow];
        Editable := (TrimRight(TabEquipementAffichage.Cells[3, aRow]) = TrimRight(TypeEquipDI))
                    or ((Pos(EquipementMU, Code) > 0) and CheckBoxMunition.Checked);
        if (not Editable) and (TrimRight(TabEquipementAffichage.Cells[3, aRow]) = TrimRight(TypeEquipWe)) then
          begin
            PArme    := ChercheArme(Code);
            Editable := (Pos('COMPPROJ_LANC', PArme.CodeCompetence) > 0) and (PArme.Encombrement = 0);
          end;
      end;
    if not Editable then
      Editor := nil;
  end;

// Double-clic sur un animal ou une monture de l'inventaire : ouvre sa fiche.
procedure TWinPersonnages.TabEquipementDblClick(Sender: TObject);
  var
    PTrapping:  StructureTrapping;
    LigneTexte: Integer;
    NomTexte:   String;
    EncTexte:   Integer;
  begin
    // Objet propre au personnage : le double-clic rouvre sa fiche.
    LigneTexte := LigneEquipementReelle(TabEquipementAffichage.Row);
    if (LigneTexte > 0) and (Pos(ConstPrefixeObjetPropre, TabEquipement.Cells[2, LigneTexte]) = 1) then
      begin
        if EquipementModifiable then ModifierObjetPropre(LigneTexte);
        exit;
      end;
    // Objet de texte pur : le double-clic modifie son nom et son encombrement.
    if (LigneTexte > 0) and (TabEquipement.Cells[13, LigneTexte] <> '') then
      begin
        NomTexte := TabEquipement.Cells[13, LigneTexte];
        EncTexte := StrToIntDef(TabEquipement.Cells[14, LigneTexte], 0);
        if EquipementModifiable and SaisieTexteLibre(NomTexte, EncTexte) then
          begin
            TabEquipement.Cells[4, LigneTexte]  := NomTexte;
            TabEquipement.Cells[13, LigneTexte] := NomTexte;
            TabEquipement.Cells[14, LigneTexte] := IntToStr(EncTexte);
            RafraichitTabEquipementAffichage();
          end;
        exit;
      end;
    if (TabEquipement.Row < 1) or (TabEquipement.Row >= TabEquipement.RowCount) then exit;
    PTrapping := ChercheTrapping(TabEquipement.Cells[2, TabEquipement.Row]);
    if PTrapping.ProfilAnimal <> '' then
      begin
        AttribueIdAnimaux;
        AfficheFicheAnimal(PTrapping, ChargeAnimalGrille(TabEquipement.Cells[10, TabEquipement.Row]));
      end
    else if PTrapping.ProfilBateau <> '' then
      begin
        AttribueIdAnimaux;
        AfficheFicheAnimal(PTrapping, -1, CodesFittingGrille(TabEquipement.Cells[10, TabEquipement.Row]));
      end
    else if PTrapping.ProfilVehicule <> '' then
      AfficheFicheAnimal(PTrapping);
  end;

function TWinPersonnages.LigneEstAnimal(Ligne: Integer): Boolean;
  begin
    Result := (Ligne > 0) and (Ligne < TabEquipement.RowCount)
      and TrappingEstPorteur(ChercheTrapping(TabEquipement.Cells[2, Ligne]));
  end;

// Categorie d'une ligne de TabEquipement pour ListBoxEquipementCategorie (CONTEXT.md etape 2) :
// 0 Montures/Navires/Vehicules, 1 Armes, 2 Armures, 3 Divers, 4 Sorts. Un bateau/vehicule garde
// le type Divers (colonne 3) - LigneEstAnimal (profil animal/bateau/vehicule) est donc teste en
// premier. Un sort n'a pas de TypeEquip fixe (TypeSort est un libelle libre, ex. "Petty Magic") :
// identifie comme ButtonFabricationClick/TabEquipementSelectCell, par TalentSort.
function TWinPersonnages.CategorieEquipementLigne(Ligne: Integer): Integer;
  var
    Typ: String;
  begin
    if LigneEstAnimal(Ligne) then
      Result := 0
    else if TalentSort(TabEquipement.Cells[2, Ligne]).CodeTalent <> '' then
      Result := 4
    else
      begin
        Typ := TrimRight(TabEquipement.Cells[3, Ligne]);
        if Typ = TrimRight(TypeEquipWe) then
          Result := 1
        else if (Typ = TrimRight(TypeEquipAr)) or (Typ = TrimRight(TypeEquipArS)) then
          Result := 2
        else
          Result := 3;
      end;
  end;

// Ligne reelle dans TabEquipement (grille complete de sauvegarde) correspondant a la ligne
// Ligne de TabEquipementAffichage (grille visible, filtree par categorie) : retrouvee par le
// Code (colonne 2), copie a l'identique entre les deux grilles.
function TWinPersonnages.LigneEquipementReelle(Ligne: Integer): Integer;
  begin
    if (Ligne < 1) or (Ligne >= TabEquipementAffichage.RowCount) then
      Result := -1
    else
      Result := RechercherDansColonne(TabEquipement, TabEquipementAffichage.Cells[2, Ligne], 2);
  end;

// Categorie choisie dans ListBoxEquipementCategorie (CategorieEquipementLigne) : reconstruit
// TabEquipementAffichage a partir de TabEquipement, qui reste toujours complet (source de la
// sauvegarde, CONTEXT.md etape 2).
procedure TWinPersonnages.RafraichitTabEquipementAffichage();
  var
    Ligne, IndAffiche, Col, Categorie: Integer;
  begin
    Categorie := ListBoxEquipementCategorie.ItemIndex;

    TabEquipementAffichage.RowCount := 1;
    TabEquipementAffichage.ColCount := TabEquipement.ColCount;
    for Col := 0 to TabEquipement.ColCount - 1 do
      begin
        TabEquipementAffichage.ColWidths[Col] := TabEquipement.ColWidths[Col];
        TabEquipementAffichage.Cells[Col, 0]  := TabEquipement.Cells[Col, 0];
      end;

    IndAffiche := 0;
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      if CategorieEquipementLigne(Ligne) = Categorie then
        begin
          Inc(IndAffiche);
          TabEquipementAffichage.RowCount := IndAffiche + 1;
          TabEquipementAffichage.Rows[IndAffiche].Assign(TabEquipement.Rows[Ligne]);
        end;

    // Largeur des colonnes ajustee au contenu REELLEMENT affiche (la categorie filtree),
    // pas a TabEquipement (masque, toujours complet : ses largeurs, recalculees par
    // AdjustGridColumnsWidth a chaque ajout/suppression, ne correspondent plus a ce qui est
    // visible depuis la scission par categorie du 25/09/2026 - copiees telles quelles ci-dessus,
    // elles restent celles du dernier ajout, pas celles de la categorie choisie). AutoSizeColumn
    // ne touche que la largeur de la colonne, jamais celle de la grille (contrainte par
    // l'ancrage proportionnel, ancrageproportionnel.pas) - colonnes cachees (largeur 0,
    // Code/Fabrication/Id/PortePar) inchangees.
    for Col := 1 to TabEquipementAffichage.ColCount - 1 do
      if TabEquipementAffichage.ColWidths[Col] <> 0 then
        TabEquipementAffichage.AutoSizeColumn(Col);

    // Boutons d'ajout/action visibles seulement s'ils ont une utilite dans la categorie
    // affichee (meme decoupage que CategorieEquipementLigne). ButtonEquipement (+Equipment,
    // catalogue DATA_TRAPPING) sert aussi bien aux Divers qu'aux Montures/Navires/Vehicules,
    // qui s'ajoutent par ce meme bouton (ils sont retypes AN au chargement, cf. CONTEXT.md).
    ButtonArme.Visible        := EquipementModifiable and (Categorie = 1);
    ButtonArmure.Visible      := EquipementModifiable and (Categorie = 2);
    ButtonEquipement.Visible  := EquipementModifiable and ((Categorie = 0) or (Categorie = 3));
    ButtonTexte.Visible       := EquipementModifiable and (Categorie = 3);
    ButtonObjet.Visible       := EquipementModifiable and (Categorie in [1, 2, 3]);
    ButtonSort.Visible        := EquipementModifiable and (Categorie = 4);
    // Fabrication et Suppression ne s'appliquent jamais a un sort (ButtonFabricationClick/
    // ButtonDeleteClick le refusent deja par le test TalentSort).
    ButtonFabrication.Visible := EquipementModifiable and (Categorie <> 4);
    ButtonDelete.Visible      := EquipementModifiable and (Categorie <> 4);
  end;

procedure TWinPersonnages.ListBoxEquipementCategorieClick(Sender: TObject);
  begin
    RafraichitTabEquipementAffichage();
  end;

// Propage vers TabEquipement (grille de sauvegarde) une edition faite directement dans
// TabEquipementAffichage : seule la colonne Quantite (9) est editable en place, cf.
// TabEquipementSelectEditor.
procedure TWinPersonnages.TabEquipementAffichageSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
  var
    LigneReelle: Integer;
  begin
    LigneReelle := LigneEquipementReelle(ARow);
    if LigneReelle > 0 then
      TabEquipement.Cells[ACol, LigneReelle] := Value;
  end;

// Identifiant A<N> pour chaque animal de la grille qui n'en a pas encore (meme regle que
// IdAnimalLibre de ChargePersonnage, mais sur la grille, seule a jour avant la sauvegarde).
procedure TWinPersonnages.AttribueIdAnimaux;
  var
    Ligne, Suivant, Ind: Integer;
    Id:                  String;
    Pris:                Boolean;
  begin
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      if LigneEstAnimal(Ligne) and (TabEquipement.Cells[10, Ligne] = '') then
        begin
          Suivant := 0;
          repeat
            Inc(Suivant);
            Id   := 'A' + IntToStr(Suivant);
            Pris := False;
            for Ind := 1 to TabEquipement.RowCount - 1 do
              if TabEquipement.Cells[10, Ind] = Id then
                Pris := True;
          until not Pris;
          TabEquipement.Cells[10, Ligne] := Id;
        end;
  end;

// Colonne 12 : nom de l'animal porteur. Un porteur disparu (id introuvable) est oublie.
procedure TWinPersonnages.RafraichitPorteurs;
  var
    Ligne, Ind: Integer;
    Trouve:     Boolean;
    BienGroupe: StructurePersonnageEquipement;
  begin
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      begin
        TabEquipement.Cells[12, Ligne] := '';
        if TabEquipement.Cells[11, Ligne] = '' then continue;
        Trouve := False;
        for Ind := 1 to TabEquipement.RowCount - 1 do
          if TabEquipement.Cells[10, Ind] = TabEquipement.Cells[11, Ligne] then
            begin
              TabEquipement.Cells[12, Ligne] := TabEquipement.Cells[4, Ind] + ' (' + TabEquipement.Cells[10, Ind] + ')';
              Trouve := True;
              break;
            end;
        // Pas trouve localement : peut-etre un bien du groupe (CONTEXT.md 2.100, etape 5).
        if not Trouve and (Personnage.GroupeId <> '') then
          begin
            BienGroupe := ChercheBienGroupe(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId, TabEquipement.Cells[11, Ligne]);
            if BienGroupe.CodeEquipement <> '' then
              begin
                TabEquipement.Cells[12, Ligne] := ChercheTrapping(BienGroupe.CodeEquipement).Libelle
                  + ' (' + BienGroupe.IdInstance + ', ' + GetTexteLibelle('RULES-LAB_301') + ')';
                Trouve := True;
              end;
          end;
        if not Trouve then
          TabEquipement.Cells[11, Ligne] := '';
      end;
    RafraichitTabEquipementAffichage();
  end;

function TWinPersonnages.EquipementDeLigne(Ligne: Integer): StructurePersonnageEquipement;
  var
    Typ: String;
  begin
    Result.CodeEquipement    := TabEquipement.Cells[2, Ligne];
    Result.QualiteEquipement := TabEquipement.Cells[7, Ligne];
    Result.NomLibre          := TabEquipement.Cells[13, Ligne];
    Result.EncLibre          := StrToIntDef(TabEquipement.Cells[14, Ligne], 0);
    Result.Quantite          := StrToIntDef(TabEquipement.Cells[9, Ligne], 1);
    if Result.Quantite < 1 then Result.Quantite := 1;
    Typ := TrimRight(TabEquipement.Cells[3, Ligne]);
    if Typ = TrimRight(TypeEquipWe) then Result.TypeEquipement := TypeEquipWe
    else if Typ = TrimRight(TypeEquipAr) then Result.TypeEquipement := TypeEquipAr
    else if Typ = TrimRight(TypeEquipArS) then Result.TypeEquipement := TypeEquipArS
    else if Typ = TrimRight(TypeEquipAN) then Result.TypeEquipement := TypeEquipAN
    else Result.TypeEquipement := TypeEquipDI;
  end;

// Encombrement brut de tout ce qui est confie a l'animal IdAnimal (lu dans la grille).
function TWinPersonnages.ChargeAnimalGrille(IdAnimal: String): Integer;
  var
    Ligne: Integer;
  begin
    Result := 0;
    if IdAnimal = '' then exit;
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      if TabEquipement.Cells[11, Ligne] = IdAnimal then
        Result := Result + PdfEquipementEncombrementBrut(EquipementDeLigne(Ligne));
  end;

// Codes des amenagements confies au bateau IdAnimal (lus dans la grille), format
// "CODE niveau,CODE niveau" attendu par FabricationModificateurQualite. Niveau force a 1
// (present/absent) quelle que soit la quantite achetee : Smoothing se paie "par 5 yards
// de Size" (plusieurs unites pour couvrir tout le bateau) mais son effet (M+1) ne se
// cumule pas avec le nombre d'unites - meme logique pour tout autre amenagement. 24/09/2026.
function TWinPersonnages.CodesFittingGrille(IdAnimal: String): String;
  var
    Ligne: Integer;
  begin
    Result := '';
    if IdAnimal = '' then exit;
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      if TabEquipement.Cells[11, Ligne] = IdAnimal then
        begin
          if Result <> '' then Result := Result + ',';
          Result := Result + TabEquipement.Cells[2, Ligne] + ' 1';
        end;
  end;

function TWinPersonnages.CapaciteAnimalGrille(IdAnimal: String): Integer;
  var
    Ligne:      Integer;
    Trouve:     Boolean;
    BienGroupe: StructurePersonnageEquipement;
  begin
    Result := 0;
    Trouve := False;
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      if TabEquipement.Cells[10, Ligne] = IdAnimal then
        begin
          Result := ChercheTrapping(TabEquipement.Cells[2, Ligne]).Capacite
                    * StrToIntDef(TabEquipement.Cells[9, Ligne], 1);
          Trouve := True;
        end;
    // Pas trouve localement : peut-etre un bien du groupe (CONTEXT.md 2.100, etape 5).
    if not Trouve and (Personnage.GroupeId <> '') then
      begin
        BienGroupe := ChercheBienGroupe(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId, IdAnimal);
        if BienGroupe.CodeEquipement <> '' then
          Result := ChercheTrapping(BienGroupe.CodeEquipement).Capacite * BienGroupe.Quantite;
      end;
  end;

// Libelle d'affichage d'un animal/vehicule/bateau, qu'il soit local ou dans le groupe
// (CONTEXT.md 2.100, etape 5) - utilise par AvertitSurcharge quand l'id n'est plus local.
function TWinPersonnages.LibelleAnimalOuGroupe(IdAnimal: String): String;
  var
    Ligne:      Integer;
    BienGroupe: StructurePersonnageEquipement;
  begin
    Result := '';
    for Ligne := 1 to TabEquipement.RowCount - 1 do
      if TabEquipement.Cells[10, Ligne] = IdAnimal then
        Exit(TabEquipement.Cells[4, Ligne]);
    if Personnage.GroupeId <> '' then
      begin
        BienGroupe := ChercheBienGroupe(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId, IdAnimal);
        if BienGroupe.CodeEquipement <> '' then
          Result := ChercheTrapping(BienGroupe.CodeEquipement).Libelle;
      end;
  end;

// Avertissement (jamais un blocage) quand la charge depasse la capacite <Carries>.
procedure TWinPersonnages.AvertitSurcharge(IdAnimal: String);
  var
    Charge, Capacite: Integer;
  begin
    Charge   := ChargeAnimalGrille(IdAnimal);
    Capacite := CapaciteAnimalGrille(IdAnimal);
    if (Capacite > 0) and (Charge > Capacite) then
      ShowMessage(LibelleAnimalOuGroupe(IdAnimal) + ' (' + IdAnimal + ') : '
        + GetTexteLibelle('RULES-LAB_257') + ' ' + IntToStr(Charge) + ' / ' + IntToStr(Capacite)
        + ' - ' + GetTexteLibelle('RULES-LAB_258'));
  end;

// Le clic droit ne deplace pas la ligne courante d'une grille : on la selectionne avant le menu.
// Survol de la colonne Worn (8) : rappelle comment declarer un objet porte.
procedure TWinPersonnages.TabEquipementMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  var
    Colonne, Ligne: Integer;
    Aide:           String;
  begin
    TabEquipementAffichage.MouseToCell(X, Y, Colonne, Ligne);
    if Colonne = 8 then Aide := GetTexteLibelle('RULES-LAB_259') else Aide := '';
    if TabEquipementAffichage.Hint <> Aide then
      begin
        TabEquipementAffichage.Hint := Aide;
        Application.CancelHint;
      end;
  end;

// Le clic (gauche ou droit) se fait sur la grille d'affichage (filtree) : on retrouve la
// ligne correspondante dans TabEquipement (grille complete de sauvegarde) par son Code
// (colonne 2, identique dans les deux grilles) avant tout traitement base sur TabEquipement.Row.
procedure TWinPersonnages.TabEquipementMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  var
    Colonne, Ligne, LigneReelle: Integer;
  begin
    if Button <> mbRight then exit;
    TabEquipementAffichage.MouseToCell(X, Y, Colonne, Ligne);
    if Ligne > 0 then
      begin
        TabEquipementAffichage.Row := Ligne;
        LigneReelle := LigneEquipementReelle(Ligne);
        if LigneReelle > 0 then
          TabEquipement.Row := LigneReelle;
      end;
  end;

procedure TWinPersonnages.TabEquipementPopup(Sender: TObject);
  var
    Ligne, Ind: Integer;
    Item:       TMenuItem;
    MenuPop:    TPopupMenu;
    Bien:       StructurePersonnageEquipement;
    Donner:     TMenuItem;
    Rech:       TSearchRec;
  begin
    MenuPop := TabEquipementAffichage.PopupMenu;
    MenuPop.Items.Clear;
    Ligne := TabEquipement.Row;
    if (Ligne < 1) or (TalentSort(TabEquipement.Cells[2, Ligne]).CodeTalent <> '') then exit;
    AttribueIdAnimaux;
    // Un animal ne se porte pas et ne se confie pas a un autre animal : la seule action
    // possible est de le partager avec le groupe (CONTEXT.md 2.100, etape 4), si le
    // personnage en a un.
    if LigneEstAnimal(Ligne) then
      begin
        if Personnage.GroupeId <> '' then
          begin
            Item         := TMenuItem.Create(MenuPop);
            Item.Caption := GetTexteLibelle('RULES-LAB_308');
            Item.OnClick := @MenuPartageGroupeClick;
            MenuPop.Items.Add(Item);
          end;
        Exit;
      end;
    // Un animal ne se porte pas sur soi : "Porte" est reserve aux autres objets (deja garanti plus haut)
    Item         := TMenuItem.Create(MenuPop);
    Item.Caption := GetTexteLibelle('RULES-LAB_180');
    Item.Checked := TabEquipement.Cells[8, Ligne] <> '';
    Item.OnClick := @MenuPorteClick;
    MenuPop.Items.Add(Item);
    for Ind := 1 to TabEquipement.RowCount - 1 do
      if LigneEstAnimal(Ind) then
        begin
          Item         := TMenuItem.Create(MenuPop);
          Item.Caption := GetTexteLibelle('RULES-LAB_255') + ' ' + TabEquipement.Cells[4, Ind]
                          + ' (' + TabEquipement.Cells[10, Ind] + ')';
          Item.Hint    := TabEquipement.Cells[10, Ind];
          Item.OnClick := @MenuConfierClick;
          MenuPop.Items.Add(Item);
        end;
    // Animaux/vehicules/bateaux du groupe (CONTEXT.md 2.100, etape 5) : meme menu, mais la
    // ressource vient de GROUPE_<Nom>.xml au lieu de la grille locale.
    if Personnage.GroupeId <> '' then
      for Bien in ListeBiensGroupe(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId) do
        begin
          Item         := TMenuItem.Create(MenuPop);
          Item.Caption := GetTexteLibelle('RULES-LAB_255') + ' ' + ChercheTrapping(Bien.CodeEquipement).Libelle
                          + ' (' + Bien.IdInstance + ', ' + GetTexteLibelle('RULES-LAB_301') + ')';
          Item.Hint    := Bien.IdInstance;
          Item.OnClick := @MenuConfierClick;
          MenuPop.Items.Add(Item);
        end;
    if TabEquipement.Cells[11, Ligne] <> '' then
      begin
        Item         := TMenuItem.Create(MenuPop);
        Item.Caption := GetTexteLibelle('RULES-LAB_256');
        Item.OnClick := @MenuReprendreClick;
        MenuPop.Items.Add(Item);
      end;
    // Donner a un autre personnage : un sous-menu par dossier de fiche
    Donner := TMenuItem.Create(MenuPop);
    Donner.Caption := GetTexteLibelle('RULES-LAB_661');
    if FindFirst(GetCurrentDir + ConstCheminPersonnage + '*', faDirectory, Rech) = 0 then
      begin
        repeat
          if ((Rech.Attr and faDirectory) <> 0) and (Rech.Name <> '.') and (Rech.Name <> '..')
             and (Rech.Name <> NomPersonnage)
             and (PersonnageXmlFichierActuel(GetCurrentDir + ConstCheminPersonnage + Rech.Name) <> '') then
            begin
              Item         := TMenuItem.Create(Donner);
              Item.Caption := Rech.Name;
              Item.OnClick := @MenuDonnerClick;
              Donner.Add(Item);
            end;
        until FindNext(Rech) <> 0;
        FindClose(Rech);
      end;
    if Donner.Count > 0 then
      MenuPop.Items.Add(Donner)
    else
      Donner.Free;
  end;

// Donne l'objet de la ligne a un autre personnage : ecrit dans la fiche la plus recente du
// destinataire, retire la ligne chez nous et enregistre. Quantite entiere ; porte et confie
// sont remis a zero. Le destinataire est ecrit d'abord : en cas d'echec rien n'est retire ici.
procedure TWinPersonnages.MenuDonnerClick(Sender: TObject);
  var
    Ligne, I:  Integer;
    Nom:       String;
    Fichier:   String;
    Bien:      StructurePersonnageEquipement;
    Elements:  String;
    Poignee:   PtrUInt;
    Ouvert:    Boolean;
    Codes:     TStringList;
    Avant:     String;
  begin
    Ligne := TabEquipement.Row;
    if Ligne < 1 then exit;
    Nom := StringReplace(TMenuItem(Sender).Caption, '&', '', [rfReplaceAll]);
    // Blocage : un destinataire ouvert (ici ou dans un autre WarhammerHelp) enregistrerait par
    // dessus le don ; on teste son mutex sans le garder.
    Poignee := MutexPersonnage(Nom, Ouvert);
    if Poignee <> 0 then CloseHandle(Poignee);
    if Ouvert then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_664') + ' ' + Nom);
        exit;
      end;
    if MessageDlg(GetTexteLibelle('RULES-LAB_662') + ' ' + Nom + ' ?', mtConfirmation, mbYesNo, 0) <> mrYes then exit;
    Fichier := PersonnageXmlFichierActuel(GetCurrentDir + ConstCheminPersonnage + Nom);
    Bien    := EquipementDeLigne(Ligne);
    Elements := ObjetPropreAvecQualites(Personnage.ObjetsPropres, Bien.CodeEquipement);
    if (Fichier = '') or not PersonnageDonneObjet(Fichier, Bien, Elements) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_663'));
        exit;
      end;
    for I := Ligne to TabEquipement.RowCount - 2 do
      TabEquipement.Rows[I].Assign(TabEquipement.Rows[I + 1]);
    TabEquipement.RowCount := TabEquipement.RowCount - 1;
    RafraichitPorteurs;
    RafraichitTabEquipementAffichage();
    // XmlSauvegarde n'ecrit que Personnage (la grille n'y est recopiee que par MajTables, a la
    // validation) : on retire donc aussi la ligne de Personnage.Equipement, et l'element propre.
    for I := 0 to High(Personnage.Equipement) do
      if (Personnage.Equipement[I].CodeEquipement = Bien.CodeEquipement)
         and (TrimRight(Personnage.Equipement[I].TypeEquipement) = TrimRight(Bien.TypeEquipement)) then
        begin
          Personnage.Equipement[I] := Personnage.Equipement[High(Personnage.Equipement)];
          SetLength(Personnage.Equipement, High(Personnage.Equipement));
          Break;
        end;
    if Personnage.ObjetsPropres <> '' then
      begin
        Codes := TStringList.Create;
        try
          CodesObjetsPropresUtilises(Codes);
          Avant := Personnage.ObjetsPropres;
          Personnage.ObjetsPropres := ObjetsPropresUtiles(Personnage.ObjetsPropres, Codes);
          // une specialisation elaguee ne doit plus etre proposee par la fenetre de choix
          if Personnage.ObjetsPropres <> Avant then
            InjecteObjetsPropres(Personnage.ObjetsPropres);
        finally
          Codes.Free;
        end;
      end;
    // l'echec est deja signale a l'ecran par XmlSauvegarde ; la fenetre reste ouverte de toute facon
    XmlSauvegarde();
  end;

procedure TWinPersonnages.MenuConfierClick(Sender: TObject);
  var
    Id: String;
  begin
    Id := TMenuItem(Sender).Hint;
    if (TabEquipement.Row < 1) or (Id = '') then exit;
    TabEquipement.Cells[11, TabEquipement.Row] := Id;
    // confie a un animal : plus porte sur soi (carriedby l'emporte sur worn)
    TabEquipement.Cells[8, TabEquipement.Row]  := '';
    RafraichitPorteurs;
    AvertitSurcharge(Id);
  end;

// Vrai si l'arme de la ligne peut etre portee sans depasser le nombre de mains ; sinon avertit.
// Deux budgets separes : armes de contact d'un cote, armes a distance de l'autre (on n'utilise
// pas les deux familles en meme temps).
function TWinPersonnages.MainsLibresPourArme(Ligne: Integer): Boolean;
  var
    Ind, Utilisees, Voulues, Mains: Integer;
    ADistance:                      Boolean;
  begin
    Result := True;
    if TrimRight(TabEquipement.Cells[3, Ligne]) <> TrimRight(TypeEquipWe) then exit;
    Voulues := ChercheArme(TabEquipement.Cells[2, Ligne]).Mains;
    if Voulues <= 0 then exit;
    Mains     := PersonnageNombreMains(Personnage);
    ADistance := ArmeEstADistance(TabEquipement.Cells[2, Ligne]);
    Utilisees := 0;
    for Ind := 1 to TabEquipement.RowCount - 1 do
      if (Ind <> Ligne) and (TabEquipement.Cells[8, Ind] <> '')
         and (TrimRight(TabEquipement.Cells[3, Ind]) = TrimRight(TypeEquipWe))
         and (ArmeEstADistance(TabEquipement.Cells[2, Ind]) = ADistance) then
        Utilisees := Utilisees + ChercheArme(TabEquipement.Cells[2, Ind]).Mains;
    if Utilisees + Voulues > Mains then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_473') + ' : ' + IntToStr(Utilisees + Voulues)
                    + ' / ' + IntToStr(Mains));
        Result := False;
      end;
  end;

procedure TWinPersonnages.MenuPorteClick(Sender: TObject);
  begin
    if TabEquipement.Row < 1 then exit;
    if TabEquipement.Cells[8, TabEquipement.Row] = '' then
      begin
        // Une arme ne se porte que si le personnage a assez de mains libres (somme des mains
        // des armes deja portees + celle-ci <= PersonnageNombreMains).
        if not MainsLibresPourArme(TabEquipement.Row) then
          exit;
        TabEquipement.Cells[8, TabEquipement.Row]  := 'X';
        // porte sur soi : ne peut plus etre confie a un animal (carriedby l'emporte sur worn)
        TabEquipement.Cells[11, TabEquipement.Row] := '';
        RafraichitPorteurs;
      end
    else
      TabEquipement.Cells[8, TabEquipement.Row] := '';
    RafraichitTabEquipementAffichage();
  end;

procedure TWinPersonnages.MenuReprendreClick(Sender: TObject);
  begin
    if TabEquipement.Row < 1 then exit;
    TabEquipement.Cells[11, TabEquipement.Row] := '';
    RafraichitPorteurs;
  end;

// Partage un animal/vehicule/bateau avec le groupe (CONTEXT.md 2.100, etape 4) : le bien
// quitte la grille du personnage pour rejoindre le fichier GROUPE_<Nom>.xml. Ce qu'il
// transportait redevient porte par le personnage (reprise automatique, decision de Nono -
// le vrai lien inter-fichiers carriedby -> groupe est laisse a l'etape 5).
procedure TWinPersonnages.MenuPartageGroupeClick(Sender: TObject);
  var
    Ligne, I: Integer;
    IdAnimal: String;
    Bien:     StructurePersonnageEquipement;
  begin
    Ligne := TabEquipement.Row;
    if (Ligne < 1) or not LigneEstAnimal(Ligne) or (Personnage.GroupeId = '') then exit;

    IdAnimal := TabEquipement.Cells[10, Ligne];
    Bien             := EquipementDeLigne(Ligne);
    Bien.IdInstance  := IdAnimal;

    if not GroupeAjouteBien(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId, Bien) then exit;

    // Reprise automatique de tout ce que cet animal transportait.
    if IdAnimal <> '' then
      for I := 1 to TabEquipement.RowCount - 1 do
        if TabEquipement.Cells[11, I] = IdAnimal then
          TabEquipement.Cells[11, I] := '';

    // Decale les lignes suivantes vers le haut, meme mecanique que ButtonDeleteClick.
    for I := Ligne to TabEquipement.RowCount - 2 do
      TabEquipement.Rows[I].Assign(TabEquipement.Rows[I + 1]);
    TabEquipement.RowCount := TabEquipement.RowCount - 1;

    RafraichitPorteurs;
    RafraichitTabEquipementAffichage();
  end;

procedure TWinPersonnages.TabEquipementSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
  var
    EstSort:     Boolean;
    LigneReelle: Integer;
  begin
    // Selection dans la grille d'affichage (filtree) : on garde TabEquipement.Row synchronise
    // sur la ligne reelle correspondante, pour que ButtonFabricationClick/ButtonDeleteClick et
    // le menu contextuel (bases sur TabEquipement.Row) agissent sur le bon objet.
    LigneReelle := LigneEquipementReelle(aRow);
    if LigneReelle > 0 then
      TabEquipement.Row := LigneReelle;
    // Meme test que ButtonFabricationClick/ButtonDeleteClick : une ligne qui cite un
    // talent est un sort, ni fabrication ni suppression ne s'y appliquent.
    EstSort := (aRow > 0) and (TalentSort(TabEquipementAffichage.Cells[2, aRow]).CodeTalent <> '');
    ButtonFabrication.Enabled := not EstSort;
    ButtonDelete.Enabled      := not EstSort;
  end;

procedure TWinPersonnages.RadioButtonSuivantChange(Sender: TObject);
begin
  ChargerMetierEquipement(MetierEnCours, StrToInt(MetierNvEnCours) + 1);
  NvMetierChoisi := '';
  ChargeComboNvMetier();
  TabEquipementAffiche();
  CalculXpNecessaire(false);
end;

procedure TWinPersonnages.StaticTextPersonnageClick(Sender: TObject);
begin

end;

procedure TWinPersonnages.StringGrid1Click(Sender: TObject);
begin

end;

procedure TWinPersonnages.CalculAvancement();
  Var
    Ind:         Integer;
    Val:         Integer;
    Nb:          Integer = 0;
  begin
    TabAvancement.cells[4, 1] := IntToStr(2 + StrToInt(MetierNvEnCours));
    Val                       := 5 * StrToInt(MetierNvEnCours);

    // Attributs
    // Bornes : 2 = premiere caracteristique (1 est la colonne des libelles),
    // 11 = Sociabilite. Destin (12), Resilience (13) et Blessure (14) sont exclus
    // volontairement : ils ne montent pas par l'experience.
    Nb := 0;
    for Ind := 2 to 11 do
        if (StrToIntDef(TabAttribut.Cells[Ind, LigAttImage],0) >= 1) and
           (StrToIntDef(TabAttribut.Cells[Ind, LigAttImage],0) <= StrToInt(MetierNvEnCours)) and
           (StrToIntDef(TabAttribut.Cells[Ind, LigAttBonus],0) >= Val) then
           Nb := Nb +1;
    For Ind := 1 to TabAugmentationAttribut.RowCount-1 do
      if TabAugmentationAttribut.Cells[2, ind] <> CouleurKo then
        if StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttNouveau, Ind],0) >= Val then
          TabAugmentationAttribut.Cells[2, ind] := CouleurOk
        else
          TabAugmentationAttribut.Cells[2, ind] := CouleurNot;

    TabAvancement.Cells[5, 1] := IntToStr(Nb);
    if Nb < StrToInt(TabAvancement.Cells[4, 1]) then
      TabAvancement.Cells[2, 1] := CouleurNot
    else
      TabAvancement.Cells[2, 1] := CouleurOk;

    // Compétences
    Nb := 0;
    for Ind := 1 to TabCompetence.RowCount-1 do
      begin
        if (StrToIntDef(TabCompetence.Cells[ColCompImage, Ind],0) >= 1) and
           (StrToIntDef(TabCompetence.Cells[ColCompImage, Ind],0) <= StrToInt(MetierNvEnCours)) and
           (StrToIntDef(TabCompetence.Cells[ColCompBonus, Ind],0) >= Val) then
           Nb := Nb +1;
      end;
    For Ind := 1 to TabAugmentationCompetence.RowCount-1 do
      if TabAugmentationCompetence.Cells[2, ind] <> CouleurKo then
        if StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompNouveau, Ind],0) >= Val then
          TabAugmentationCompetence.Cells[2, ind] := CouleurOk
        else
          TabAugmentationCompetence.Cells[2, ind] := CouleurNot;
    TabAvancement.Cells[5, 2] := IntToStr(Nb);
    if Nb < StrToInt(TabAvancement.Cells[4, 2]) then
      TabAvancement.Cells[2, 2] := CouleurNot
    else
      TabAvancement.Cells[2, 2] := CouleurOk;

    // Talents
    Nb := 0;
    for Ind := 1 to TabTalent.RowCount-1 do
        if (StrToIntDef(TabTalent.Cells[2, Ind],0) = StrToInt(MetierNvEnCours)) then
           Nb := Nb +1;
    TabAvancement.Cells[5, 3] := IntToStr(Nb);
    For Ind := 1 to TabAugmentationTalent.RowCount-1 do
      if TabAugmentationTalent.Cells[2, ind] <> CouleurKo then
        if StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalNouveau, Ind],0) >= 1 then
          TabAugmentationTalent.Cells[2, ind] := CouleurOk
        else
          TabAugmentationTalent.Cells[2, ind] := CouleurNot;
    if Nb < StrToInt(TabAvancement.Cells[4, 3]) then
      TabAvancement.Cells[2, 3] := CouleurNot
    else
      TabAvancement.Cells[2, 3] := CouleurOk;

  end;

function TWinPersonnages.CalculExperience(TypeXp: String; Gratuit: Integer; Total: Integer; Code: String): Integer;
  var
    Xp:                      Integer =0;
    AffecteBonus:            Integer;
    AffecteGratuit:          Integer;
    RestantBonus:            Integer;
    RestantGratuit:          Integer;
    Min:                     Integer = 0;
    Max:                     Integer = 5;
    PAttributAugmentation:   StructureAttributAugmentation;
    PCompetenceAugmentation: StructureCompetenceAugmentation;
    i:                       Integer;
  begin
    if TypeXp = ConstXmlTalent then
      Begin
        if Total > Gratuit then
          begin
            for i := gratuit to (Total-1) do
      	      Xp := Xp + 100 + (100 * i);
          end;
      end
    else
        begin
        // calcul du restant total
        RestantGratuit := Gratuit;
        RestantBonus   := Total - RestantGratuit;

        //boucle 5 par 5
        While (RestantBonus > 0) or (RestantGratuit > 0) do
          Begin
            // calculer l'affectation en gratuit
	    If RestantGratuit > 0 then
              begin
	        if RestantGratuit >= 5 then
	            AffecteGratuit := 5
	        else
	            AffecteGratuit := RestantGratuit;
                RestantGratuit     := RestantGratuit - AffecteGratuit;
              end
            else
              AffecteGratuit := 0;

            // calculer l'affectation en payant
            If AffecteGratuit < 5 then
              begin
	        if RestantBonus <= (5 - AffecteGratuit) then
	            AffecteBonus   := RestantBonus
	        else
	            AffecteBonus   := 5;
	        RestantBonus       := RestantBonus - AffecteBonus;
              end
	    else
	       AffecteBonus := 0;

            // calcul le coût en XP
            if AffecteBonus > 0 then
              begin
                case TypeXp Of
                  ConstXmlCarac:
                    begin
                      PAttributAugmentation := ChercheAttributAugmentation(Min, Max);
                      Xp := Xp + (AffecteBonus * PAttributAugmentation.Cout);
                    end;
                  ConstXmlCompetence:
                    begin
                      PCompetenceAugmentation := ChercheCompetenceAugmentation(Min, Max);
                      Xp := Xp + (AffecteBonus * PCompetenceAugmentation.Cout);
                    end;
                end;
              end;

            // augmenter les bornes
            if Min = 0 then
              Min := 1;
            Min := Min + 5;
            Max := Max + 5;
          end;
    end;

    // augmentation Xp MJ et Talent
    if Code <> '' then
      case TypeXp Of
        ConstXmlCarac:
          Xp := Xp + CalculXpMj(ConstXmlCarac, Code);
        ConstXmlCompetence:
          Xp := Xp + CalculXpMj(ConstXmlCompetence, Code);
        ConstXmlTalent:
          Xp := Xp + CalculXpMj(ConstXmlTalent, Code);
      end;
    // coût total
    result := CalculOptionXpDiv25(Xp);
  end;

function TWinPersonnages.CalculXpEtat(): StructureXpEtat;
  var
    Ind:            Integer;
    Xp:             Integer;
    Gratuit:        Integer;
    Total:          Integer;
  Begin
    Result.Depense      := 0;
    Result.Augmentation := 0;

    // Attributs
    For Ind := 2 to TabAttribut.ColCount-1 do
      begin
        if TabAttribut.Cells[Ind, LigAttBonus] <> '' then
          begin
            Gratuit  := 0;
            Total    := StrToInt(TabAttribut.Cells[Ind, LigAttBonus]);
            Xp       := CalculExperience(ConstXmlCarac, Gratuit, Total, TabAttribut.Cells[Ind, LigAttCode]);
            if Xp = 0 then
              TabAttribut.Cells[Ind, LigAttXp] := ''
            else
              begin
                TabAttribut.Cells[Ind, LigAttXp] := IntToStr(Xp);
                Result.Depense := Result.Depense + Xp;
              end;
           end;

      end;

    // Compétences
    For Ind := 1 to TabCompetence.RowCount-1 do
      begin
        if TabCompetence.Cells[ColCompBonus, Ind] <> '' then
          begin
            Gratuit   := StrToIntDef(TabCompetence.Cells[ColComp35, Ind],0) +
                         StrToIntDef(TabCompetence.Cells[ColComp40, Ind],0) +
                         StrToIntDef(TabCompetence.Cells[ColCompAppartenance, Ind],0);
            Total     := StrToIntDef(TabCompetence.Cells[ColCompBonus, ind],0);
            Xp        := CalculExperience(ConstXmlCompetence, Gratuit, Total, TabCompetence.Cells[ColCompCode, Ind]);
            if Xp = 0 then
              TabCompetence.Cells[ColCompXp, Ind] := ''
            else
              begin
                TabCompetence.Cells[ColCompXp, Ind] := IntToStr(Xp);
                Result.Depense := Result.Depense + Xp;
              end;
          end;
      end;

    // Talents
    For Ind := 1 to TabTalent.RowCount-1 do
      Begin
        //Xp := StrToIntDef(TabTalent.Cells[ColTalXp, Ind],0);
        Xp := CalculExperience(ConstXmlTalent, 0, StrToIntDef(TabTalent.Cells[ColTalNbAugm, Ind],0), TabTalent.Cells[ColTalCode, Ind]);
        if Xp = 0 then
          TabTalent.Cells[ColTalXp, Ind] := ''
        else
          begin
            TabTalent.Cells[ColTalXp, Ind] := IntToStr(Xp);
            Result.Depense := Result.Depense + Xp;
          end;

      end;

    // Carrières
    For Ind := 1 to TabCarriere.RowCount-1 do
      Begin
        Xp := StrToIntDef(TabCarriere.Cells[4, Ind],0);
        if Xp > 0 then
          Result.Depense := Result.Depense + Xp;
      end;

    // Augmentation
      // Attribut
      For ind := 1 to TabAugmentationAttribut.RowCount-1 do
        begin
          Xp := StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttReel, Ind],0);
          if Xp > 0 then
            Result.Augmentation := Result.Augmentation + Xp;
        end;
      // Compétence
      For ind := 1 to TabAugmentationCompetence.RowCount-1 do
        begin
          Xp := StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompReel, Ind],0);
          if Xp > 0 then
            Result.Augmentation := Result.Augmentation + Xp;
        end;
      // Talents
      For ind := 1 to TabAugmentationTalent.RowCount-1 do
        begin
          Xp := StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalReel, Ind],0);
          if Xp > 0 then
            Result.Augmentation := Result.Augmentation + Xp;
        end;

    // Sorts
    For Ind := 1 to TabEquipement.RowCount-1 do
      begin
        Xp := StrToIntDef(TabEquipement.Cells[5, Ind],0);
        if Xp > 0 then
          if TabEquipement.Cells[0, Ind] = '+' then
            Result.Augmentation := Result.Augmentation + Xp
          else
            Result.Depense      := Result.Depense + Xp;
      end;

    // Total et Restant Xp
    // Total lu depuis EditTotalXp/EditTotalXp25 (valeur affichee, a jour) et non
    // Personnage.XpTotal/Xp25Total (charge une seule fois a l'ouverture du fichier,
    // jamais resynchronise si le Total est releve en cours de session - cf CONTEXT.md,
    // bug PDF Feldo du 11/09/2026).
    if CheckBoxXpDiv25.Checked = true then
      Result.Total := StrToIntDef(EditTotalXp25.Text,0)
    else
      Result.Total := StrToIntDef(EditTotalXp.Text,0);

    Result.Restante := Result.Total - Result.Depense;
  end;

procedure TWinPersonnages.CalculTableExperience();
  var
    XpEtat: StructureXpEtat;
  Begin
    XpEtat := CalculXpEtat();

    // Table des XP
    tabExperience.Cells[ColXpDonnee, LigXpDepense] := Format('%.0n',[XpEtat.Depense/1])+' ';
    tabExperience.Cells[ColXpDonnee, LigXpRestant] := Format('%.0n',[XpEtat.Restante/1])+' ';
    tabExperience.Cells[ColXpDonnee, LigXpCout]    := Format('%.0n',[XpEtat.Augmentation/1])+' ';

    // couleur
    if (XpEtat.Augmentation = 0) then
      tabExperience.Cells[2, LigXpCout] := ''
    else if (XpEtat.Augmentation > XpEtat.Restante) then
      tabExperience.Cells[2, LigXpCout] := CouleurNot
    else
      tabExperience.Cells[2, LigXpCout] := CouleurOk;

  end;

Procedure TWinPersonnages.ChargeAugmentation();
  Var
    NbC:               Integer;
    ListComp:          TStringList;

    // Attributs : ceux de la carriere puis les autres (cases rouges).
    procedure AugmentationAttributs;
      var
        Ind: Integer;
        PAttribut: StructureAttribut;
      begin
        TabAugmentationAttribut.RowCount := StrToInt(MetierNvEnCours) + 3;
        For Ind := 2 to 11 do
          if (StrToIntDef(TabAttribut.Cells[Ind, LigAttImage],0) > 0) and (StrToIntDef(TabAttribut.Cells[Ind, LigAttImage],0) <= StrToInt(MetierNvEnCours)) then
            begin
              NbC := NbC + 1;
              if TabAugmentationAttribut.RowCount <= NbC then
                TabAugmentationAttribut.RowCount := TabAugmentationAttribut.RowCount + 1;
              TabAugmentationAttribut.Cells[1, NbC] := TabAttribut.Cells[Ind, LigAttCode];
              PAttribut := ChercheAttribut(TabAttribut.Cells[Ind, LigAttCode]);
              TabAugmentationAttribut.Cells[ColAugmAttCode, NbC]   := PAttribut.Resume;
              TabAugmentationAttribut.Cells[ColAugmAttActuel, NbC] := TabAttribut.Cells[ind, LigAttBonus];
              TabAugmentationAttribut.Cells[ColAugmAttNouveau, NbC]:= TabAttribut.Cells[ind, LigAttBonus];
              TabAugmentationAttribut.Cells[ColAugmAttMoins5, NbC] := '-';
              TabAugmentationAttribut.Cells[ColAugmAttPlus5, NbC]  := '+';
            end;
        // Attribut hors carrière
        For Ind := 2 to 11 do
          if (StrToIntDef(TabAttribut.Cells[Ind, LigAttImage],0) = 0) or (StrToIntDef(TabAttribut.Cells[Ind, LigAttImage],0) > StrToInt(MetierNvEnCours)) then
            begin
              NbC := NbC + 1;
              if TabAugmentationAttribut.RowCount <= NbC then
                TabAugmentationAttribut.RowCount := TabAugmentationAttribut.RowCount + 1;
              TabAugmentationAttribut.Cells[1, NbC] := TabAttribut.Cells[Ind, LigAttCode];
              PAttribut := ChercheAttribut(TabAttribut.Cells[Ind, LigAttCode]);
              TabAugmentationAttribut.Cells[2, Nbc]                := CouleurKo;
              TabAugmentationAttribut.Cells[ColAugmAttCode, NbC]   := PAttribut.Resume;
              TabAugmentationAttribut.Cells[ColAugmAttActuel, NbC] := TabAttribut.Cells[ind, LigAttBonus];
              TabAugmentationAttribut.Cells[ColAugmAttNouveau, NbC]:= TabAttribut.Cells[ind, LigAttBonus];
              TabAugmentationAttribut.Cells[ColAugmAttMoins5, NbC] := '-';
              TabAugmentationAttribut.Cells[ColAugmAttPlus5, NbC]  := '+';
            end;
      end;

    // Competences de la carriere (jusqu au niveau en cours) ; ListComp passe au bloc des talents.
    procedure AugmentationCompetencesCarriere;
      var
        Ind: Integer;
        PCompetence: StructureCompetence;
        ListBranche: TStringList;
        IndBranche: Integer;
        LibBranche: String;
      begin
        For PersonnageCompetence in Personnage.MetierCompetence do
          begin
            if PersonnageCompetence.Valeur <= StrToInt(MetierNvEnCours) then
              begin
                PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
                NbC := NbC + 1;
                if TabAugmentationCompetence.RowCount <= NbC then
                  TabAugmentationCompetence.RowCount     := TabAugmentationCompetence.RowCount + 1;

                // Un code de CHOIX 'A/B' n'existe dans aucune table : ChercheCompetence compare
                // les codes a l'identique (VerifieRecherche) et rend l'enregistrement vide. La
                // ligne s'affichait donc sans libelle ET sans code, et comme la fenetre de
                // specialisation recoit justement cette cellule Code, elle s'ouvrait vide. On
                // reprend alors le code BRUT, et on compose le libelle avec celui de chaque
                // branche. WinSpecialisation sait deja eclater le '/', et le bloc "propager au
                // tableau metier" du double-clic retrouve la ligne par ce meme code brut.
                // Vaut pour tout choix A/B, y compris ceux du Rulebook (Play (Drum or Fife)).
                if (PCompetence.CodeCompetence = '') and (Pos(SeparateurMulti, PersonnageCompetence.CodeCompetence) > 0) then
                  begin
                    LibBranche  := '';
                    ListBranche := ListeMetierCompetence(PersonnageCompetence.CodeCompetence);
                    for IndBranche := 0 to ListBranche.Count - 1 do
                      begin
                        // Un choix par ligne, comme les talents (hauteurs reposees apres le tri).
                        if LibBranche <> '' then
                          LibBranche := LibBranche + ' ' + SeparateurMulti + LineEnding;
                        LibBranche := LibBranche + ChercheCompetence(ListBranche[IndBranche]).Libelle;
                      end;
                    ListBranche.Free;
                    TabAugmentationCompetence.Cells[ColAugmCompCode, NbC] := PersonnageCompetence.CodeCompetence;
                    TabAugmentationCompetence.Cells[ColAugmCompLib, NbC]  := LibBranche;
                  end
                else
                  begin
                    TabAugmentationCompetence.Cells[ColAugmCompCode, NbC]  := PCompetence.CodeCompetence;
                    TabAugmentationCompetence.Cells[ColAugmCompLib, NbC]  := PCompetence.Libelle;
                  end;
                For Ind := 1 to TabCompetence.rowCount -1 do
                  begin
                    if CompareRechercheValeur(PCompetence.CodeCompetence, TabCompetence.Cells[ColCompCode, Ind]) then
                      begin
                        TabAugmentationCompetence.Cells[2, NbC]  := TabCompetence.Cells[ColCompImage, Ind];
                        TabAugmentationCompetence.Cells[ColAugmCompActuel, NbC]  := TabCompetence.Cells[ColCompBonus, Ind];
                        TabAugmentationCompetence.Cells[ColAugmCompNouveau, NbC]  := TabCompetence.Cells[ColCompBonus, Ind];
                        break;
                      end;
                  end;
                ListComp.Free;
                ListComp := ListeMetierCompetence(PersonnageCompetence.CodeCompetence);
                if (ListComp.Count > 1) or (Pos(ValeurGenerique, PersonnageCompetence.CodeCompetence) > 0) then
                  TabAugmentationCompetence.Cells[ColAugmCompSpe, NbC] := GetTexteLibelle(ConstLabSelSpe);
                TabAugmentationCompetence.Cells[ColAugmCompWork, NbC]  := TabCompetence.Cells[ColCompTravail, Ind];
                // tri
                TabAugmentationCompetence.Cells[ColAugmCompTri, NbC]   := '0'+TabAugmentationCompetence.Cells[ColAugmCompLib, NbC];
                TabAugmentationCompetence.Cells[ColAugmCompMoins5, NbC]:= '-';
                TabAugmentationCompetence.Cells[ColAugmCompPlus5, NbC] := '+';
              end;
          end;
      end;

    // Competences hors carriere, tri puis hauteurs de ligne ; NbC continue le compte du bloc precedent.
    procedure AugmentationCompetencesHorsCarriere;
      var
        Ind, Ind2: Integer;
        Trouve: Boolean;
      begin
        For Ind2 :=1 to TabCompetence.RowCount - 1 do
          begin
            Trouve := False;
            For Ind := 1 to TabAugmentationCompetence.RowCount - 1 do
              if TabAugmentationCompetence.Cells[ColAugmCompCode, Ind] = TabCompetence.Cells[ColCompCode, Ind2] then
                begin
                  Trouve := True;
                  break;
                end;
            if Trouve = false then
              begin
                NbC := NbC + 1;
                if TabAugmentationCompetence.RowCount <= NbC then
                  TabAugmentationCompetence.RowCount     := TabAugmentationCompetence.RowCount + 1;

                TabAugmentationCompetence.Cells[ColAugmCompCode, NbC]    := TabCompetence.Cells[ColCompCode, Ind2];
                TabAugmentationCompetence.Cells[ColAugmCompLib, NbC]     := TabCompetence.Cells[ColCompLib, Ind2];
                TabAugmentationCompetence.Cells[2, NbC]              := CouleurKo;
                TabAugmentationCompetence.Cells[ColAugmCompTri, NbC]   := '1'+TabAugmentationCompetence.Cells[ColAugmCompLib, Ind2];

                TabAugmentationCompetence.Cells[ColAugmCompActuel, NbC]  := TabCompetence.Cells[ColCompBonus, Ind2];
                TabAugmentationCompetence.Cells[ColAugmCompNouveau, NbC] := TabCompetence.Cells[ColCompBonus, Ind2];
                TabAugmentationCompetence.Cells[ColAugmCompWork, NbC]    := TabCompetence.Cells[ColCompTravail, Ind2];
                TabAugmentationCompetence.Cells[ColAugmCompMoins5, NbC]:= '-';
                TabAugmentationCompetence.Cells[ColAugmCompPlus5, NbC] := '+';
              end;
          end;
        TabAugmentationCompetence.SortColRow(true, ColAugmComptri);
        // Le tri deplace les textes mais pas les hauteurs de ligne : on les repose d'apres le
        // nombre de lignes de chaque libelle (choix "A / B / C" ecrits un par ligne).
        for Ind := 1 to TabAugmentationCompetence.RowCount - 1 do
          begin
            NbC := Length(TabAugmentationCompetence.Cells[ColAugmCompLib, Ind])
                   - Length(StringReplace(TabAugmentationCompetence.Cells[ColAugmCompLib, Ind], LineEnding, '', [rfReplaceAll]));
            NbC := (NbC div Length(LineEnding)) + 1;
            if NbC > 1 then
              TabAugmentationCompetence.RowHeights[Ind] := NbC * 18
            else
              TabAugmentationCompetence.RowHeights[Ind] := TabAugmentationCompetence.DefaultRowHeight;
          end;
      end;

    // Talents du niveau en cours.
    procedure AugmentationTalentsCarriere;
      var
        PTalent: StructureTalent;
        IndT: Integer;
        ListBranche: TStringList;
        IndBranche: Integer;
        LibBranche: String;
      begin
        For PersonnageTalent in Personnage.MetierTalent do
          if PersonnageTalent.Valeur = StrToInt(MetierNvEnCours) then
            begin
             ListComp.Free;
             ListComp := ListeTalent(PersonnageTalent.CodeTalent);
             NbC := NbC + 1;
             TabAugmentationTalent.rowCount      := TabAugmentationTalent.rowCount + 1;
             TabAugmentationTalent.Cells[ColAugmTalCode, NbC] := PersonnageTalent.CodeTalent;
             PTalent                             := ChercheTalent(PersonnageTalent.CodeTalent);
             // Meme repli que pour les competences : un code de CHOIX 'A/B' n'existe dans
             // aucune table, ChercheTalent rend l'enregistrement vide et la ligne s'affichait
             // sans libelle. Ici la cellule Code porte deja le code BRUT (ligne au-dessus),
             // donc seul le libelle est a composer, branche par branche.
             if (PTalent.CodeTalent = '') and (Pos(SeparateurMulti, PersonnageTalent.CodeTalent) > 0) then
               begin
                 LibBranche  := '';
                 ListBranche := ListeTalent(PersonnageTalent.CodeTalent);
                 for IndBranche := 0 to ListBranche.Count - 1 do
                   begin
                     // Un choix par ligne (comme les fabrications de TabEquipement) : la liste
                     // des branches d'un talent "A / B / C..." ne tenait pas sur une ligne.
                     if LibBranche <> '' then
                       LibBranche := LibBranche + ' ' + SeparateurMulti + LineEnding;
                     LibBranche := LibBranche + ChercheTalent(ListBranche[IndBranche]).Libelle;
                   end;
                 if ListBranche.Count > 1 then
                   TabAugmentationTalent.RowHeights[NbC] := ListBranche.Count * 18;
                 ListBranche.Free;
                 TabAugmentationTalent.Cells[ColAugmTalLib, NbC] := LibBranche;
               end
             else
               TabAugmentationTalent.Cells[ColAugmTalLib, NbC] := PTalent.Libelle;
             if (ListComp.Count > 1) or (Pos(ValeurGenerique, PersonnageTalent.CodeTalent) > 0) then
               TabAugmentationTalent.Cells[ColAugmTalSpe, NbC]:= GetTexteLibelle(ConstLabSelSpe);
             TabAugmentationTalent.Cells[ColAugmTalWork, NbC]  := PersonnageTalent.CodeTalent;

             for IndT := 1 to TabTalent.RowCount - 1 do
               begin
                 if CompareRechercheValeur(PersonnageTalent.CodeTalent, TabTalent.Cells[ColTalCode, IndT]) then
                   begin
                     TabAugmentationTalent.Cells[ColAugmTalActuel, NbC]  := TabTalent.Cells[ColTalNb, IndT];
                     TabAugmentationTalent.Cells[ColAugmTalNouveau, NbC] := TabTalent.Cells[ColTalNb, IndT];
                     break;
                   end
                 // "Meme talent parent" : on compare les codes jusqu'au '_' inclus. C'etait
                 // ecrit en 12 caracteres FIXES, ce qui donnait "RULES-T0088_" par coincidence
                 // de longueurs et cassait des qu'un prefixe de livre ou un code n'avait pas la
                 // taille attendue.
                 // Le '_' ajoute dans le Pos n'est PAS decoratif : un talent SANS specialite n'a
                 // pas de '_', Pos rendrait 0, Copy(...,1,0) rendrait une chaine VIDE des deux
                 // cotes et TOUS les talents se seraient equivalus (constate le 05/09/2026 : la
                 // grille d'augmentation affichait quatre fois le meme talent). Avec le '_'
                 // ajoute, un code sans specialite se compare en entier.
                 else if (Copy(TabTalent.Cells[ColTalCode, IndT], 1, Pos('_', TabTalent.Cells[ColTalCode, IndT] + '_')) =
                          Copy(PersonnageTalent.CodeTalent, 1, Pos('_', PersonnageTalent.CodeTalent + '_'))) then
                   begin
                     TabAugmentationTalent.Cells[ColAugmTalCode, NbC]   := TabTalent.Cells[ColTalCode, IndT];
                     TabAugmentationTalent.Cells[ColAugmTalLib, NbC]    := TabTalent.Cells[ColTalLib, IndT];
                     TabAugmentationTalent.Cells[ColAugmTalSpe, NbC]    := '';
                     TabAugmentationTalent.Cells[ColAugmTalActuel, NbC] := TabTalent.Cells[ColTalNb, IndT];
                     TabAugmentationTalent.Cells[ColAugmTalNouveau, NbC]:= TabTalent.Cells[ColTalNb, IndT];
                   end;
               end;
           end;
      end;

    // Talents hors carriere.
    procedure AugmentationTalentsHorsCarriere;
      var
        Ind, Ind2: Integer;
        Trouve: Boolean;
      begin
        For Ind2 := 1 to TabTalent.RowCount - 1 do
          begin
            Trouve := False;
            For Ind := 1 to TabAugmentationTalent.RowCount - 1 do
              if TabAugmentationTalent.Cells[ColAugmCompCode, Ind] = TabTalent.Cells[ColCompCode, Ind2] then
                begin
                  Trouve := True;
                  break;
                end;
            if Trouve = false then
              begin
                NbC := NbC + 1;
                TabAugmentationTalent.rowCount := TabAugmentationTalent.rowCount + 1;
                TabAugmentationTalent.Cells[ColAugmTalCode, NbC]   := TabTalent.Cells[ColTalCode, Ind2];
                TabAugmentationTalent.Cells[2, NbC]                := CouleurKo;
                TabAugmentationTalent.Cells[ColAugmTalLib, NbC]    := TabTalent.Cells[ColTalLib, Ind2];
                TabAugmentationTalent.Cells[ColAugmTalSpe, NbC]    := '';
                TabAugmentationTalent.Cells[ColAugmTalActuel, NbC] := TabTalent.Cells[ColTalNb, Ind2];
                TabAugmentationTalent.Cells[ColAugmTalNouveau, NbC]:= TabTalent.Cells[ColTalNb, Ind2];
              end;
          end;
      end;

  Begin
    // Attributs
    NbC := 0;
    AugmentationAttributs;

    // Compétences
    NbC := 0;
    ListComp := nil;
    TabAugmentationCompetence.RowCount := 1;
    AugmentationCompetencesCarriere;

    // Compétences hors carrière
    AugmentationCompetencesHorsCarriere;

    // Compétence Ajout nouvelle
    AugmentationAjouteXpMj(ConstXmlCompetence);

    // Talents
    // Repart d'une grille vide comme les competences (RowCount := 1 plus haut) : sans cela les
    // 10 lignes initiales restaient vides avant la ligne <ajouter>.
    TabAugmentationTalent.RowCount := 1;
    NbC := 0;
    AugmentationTalentsCarriere;
    // Talents hors carrière
    AugmentationTalentsHorsCarriere;
    // Compétence Ajout nouvelle
    AugmentationAjouteXpMj(ConstXmlTalent);

    // Expérience
    EditTotalXp.text   := IntToStr(Personnage.XpTotal);
    EditTotalXp25.text := IntToStr(Personnage.Xp25Total);

    ListComp.Free;
  end;

Function TWinPersonnages.VerifieLivre(ListeLivre: String; Livre: String): String;
  begin
    If Pos(AjouteAccolade(Livre), ListeLivre) > 0 then
      Result := ListeLivre
    else
      result := ListeLivre + AjouteAccolade(Livre);
  end;

procedure TWinPersonnages.MajTablesAugmentations();
  var
    IndAugm:                  Integer;
    IndActu:                  Integer;
    Trouve:                   Boolean;
    PTalent:                  StructureTalent;
    PCompetence:              StructureCompetence;
    PAttribut:                StructureAttribut;
    PSort:                    StructureSort;
    NbMaxGen:                 Integer;
    TrouveGenerique:          Boolean;
    PTalentGenerique:         StructureTalent;
  begin
    // raz table augmentation spéciales
    For IndAugm := TabAugmentationMjXp.RowCount - 1 downto 1 do
      if TabAugmentationMjXp.Cells[ColAugmMjXpNew, IndAugm] = ConstSelectionne then
        For IndActu := 1 To TabAugmentationMjXp.ColCount -1 do
          begin
            TabAugmentationMjXp.Cells[IndActu, IndAugm] := '';
            TabAugmentationMjXp.RowCount                := TabAugmentationMjXp.RowCount - 1;
          end;

    // Attribut
    Personnage.AugmentationAttribut      := [];
    for IndAugm := 1 to TabAugmentationAttribut.Rowcount-1 do
      if StrToIntDef(TabAugmentationAttribut.Cells[ColAugmAttCout, indAugm],0) > 0 then
        for IndActu := 1 to TabAttribut.ColCount-1 do
          if TabAttribut.Cells[IndActu, LigAttCode] = TabAugmentationAttribut.Cells[1, indAugm] then
            begin
              TabAttribut.Cells[IndActu, LigAttBonus]   := TabAugmentationAttribut.Cells[ColAugmAttNouveau, indAugm];
              if TabAugmentationAttribut.Cells[ColAugmAttCout, IndAugm] <> TabAugmentationAttribut.Cells[ColAugmAttReel, IndAugm] then
                begin
                  TabAugmentationMjXp.RowCount  := TabAugmentationMjXp.RowCount + 1;
                  TabAugmentationMjXp.Cells[ColAugmMjXpType, TabAugmentationMjXp.RowCount-1]  := ConstXmlCarac;
                  // Le code complet (RULES-ATTR_WS) et non le resume traduit : la colonne 3
                  // de TabAugmentationAttribut porte PAttribut.Resume, qui change avec la
                  // langue et faisait perdre silencieusement la reduction. La colonne 1 porte
                  // le code court (ATTR_WS), que ChercheAttribut complete avec son prefixe.
                  TabAugmentationMjXp.Cells[ColAugmMjXpCode, TabAugmentationMjXp.RowCount-1]  := ChercheAttribut(TabAugmentationAttribut.Cells[1, indAugm]).CodeAttribut;
                  TabAugmentationMjXp.Cells[ColAugmMjXpDebut, TabAugmentationMjXp.RowCount-1] := TabAugmentationAttribut.Cells[ColAugmAttActuel, indAugm];
                  TabAugmentationMjXp.Cells[ColAugmMjXpFin, TabAugmentationMjXp.RowCount-1]   := TabAugmentationAttribut.Cells[ColAugmAttNouveau, indAugm];
                  TabAugmentationMjXp.Cells[ColAugmMjXpCout, TabAugmentationMjXp.RowCount-1]  := TabAugmentationAttribut.Cells[ColAugmAttCout, indAugm];
                  TabAugmentationMjXp.Cells[ColAugmMjXpReel, TabAugmentationMjXp.RowCount-1]  := TabAugmentationAttribut.Cells[ColAugmAttReel, indAugm];
                  TabAugmentationMjXp.Cells[ColAugmMjXpNew, TabAugmentationMjXp.RowCount-1]   := ConstSelectionne;
                end;
              break;
            end;
    TabAugmentationAttribut.enabled := false;

    // Compétence
    for IndAugm := 1 to TabAugmentationCompetence.Rowcount-1 do
      if StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompCout, indAugm],0) > 0 then
        begin
          Trouve := false;
          for IndActu := 1 to TabCompetence.RowCount-1 do
            if TabCompetence.Cells[ColCompCode, IndActu] = TabAugmentationCompetence.Cells[ColAugmCompCode, indAugm] then
              begin
                // mettre à jour le total : on ajoute la différence réellement achetée
                // (Nouveau - Actuel), pas la valeur Actuel elle-même - sinon chaque
                // augmentation ajoutait en trop la valeur de départ. Signalé par Nono
                // le 25/09/2026 (ex. 15->20 sauvegardait comme +15 au lieu de +5).
                TabCompetence.Cells[ColCompWork, IndActu] := IntToStr(StrToIntDef(TabCompetence.Cells[ColCompWork, IndActu],0) +
                                                                      StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompNouveau, indAugm],0) -
                                                                      StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompActuel, indAugm],0));
                if TabAugmentationCompetence.Cells[ColAugmCompSpeSel, indAugm] <> '' then
                  begin
                    TabCompetence.Cells[ColCompCode, IndActu] := TabAugmentationCompetence.Cells[ColAugmCompSpeSel, indAugm];
                    TabCompetence.Cells[ColCompLib, IndActu]  := TabAugmentationCompetence.Cells[ColAugmCompLib, indAugm];
                  end;
                PCompetence := chercheCompetence(TabAugmentationCompetence.Cells[ColAugmCompCode,indAugm]);

                trouve := true;
                break;
              end;

          if not trouve then
            begin
              PCompetence := chercheCompetence(TabAugmentationCompetence.Cells[ColAugmCompCode,indAugm]);
              TabCompetence.RowCount := TabCompetence.rowCount + 1;
              TabCompetence.Cells[ColCompCode, TabCompetence.RowCount-1]  := PCompetence.CodeCompetence;
              TabCompetence.Cells[ColCompLib, TabCompetence.RowCount-1]   := PCompetence.Libelle;
              TabCompetence.Cells[ColCompWork, TabCompetence.RowCount-1]  := IntToStr(StrToIntDef(TabAugmentationCompetence.Cells[ColAugmCompNouveau, indAugm],0));
              TabCompetence.Cells[ColCompStat, TabCompetence.RowCount-1]  := PCompetence.CodeAttribut;
              PAttribut := chercheAttribut(PCompetence.CodeAttribut);
              TabCompetence.Cells[ColCompCarac, TabCompetence.RowCount-1] := GetTexteLibelle(PAttribut.Resume);
            end;

          if TabAugmentationCompetence.Cells[ColAugmCompCout, IndAugm] <> TabAugmentationCompetence.Cells[ColAugmCompReel, IndAugm] then
            begin
              TabAugmentationMjXp.RowCount  := TabAugmentationMjXp.RowCount + 1;
              TabAugmentationMjXp.Cells[ColAugmMjXpType, TabAugmentationMjXp.RowCount-1]  := ConstXmlCompetence;
              TabAugmentationMjXp.Cells[ColAugmMjXpCode, TabAugmentationMjXp.RowCount-1]  := TabAugmentationCompetence.Cells[ColAugmCompCode, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpDebut, TabAugmentationMjXp.RowCount-1] := TabAugmentationCompetence.Cells[ColAugmCompActuel, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpFin, TabAugmentationMjXp.RowCount-1]   := TabAugmentationCompetence.Cells[ColAugmCompNouveau, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpCout, TabAugmentationMjXp.RowCount-1]  := TabAugmentationCompetence.Cells[ColAugmCompCout, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpReel, TabAugmentationMjXp.RowCount-1]  := TabAugmentationCompetence.Cells[ColAugmCompReel, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpNew, TabAugmentationMjXp.RowCount-1]   := ConstSelectionne;
            end;

        end;
    TabAugmentationCompetence.enabled := false;

    // Talents
    for IndAugm := 1 to TabAugmentationTalent.Rowcount-1 do
      if StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalCout, indAugm],0) > 0 then
        begin
          Trouve := false;
          for IndActu := 1 to TabTalent.RowCount-1 do
            if TabTalent.Cells[ColCompCode, IndActu] = TabAugmentationTalent.Cells[ColAugmTalCode, indAugm] then
              begin
                TabTalent.Cells[ColTalNbAugm, IndActu] := IntToStr(StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm],0) -
                                                                      StrToIntDef(TabTalent.Cells[ColTalNbCrea, IndActu],0));
                TabTalent.Cells[ColTalNb, IndActu] := IntToStr(StrToIntDef(TabTalent.Cells[ColTalNbCrea, IndActu],0) +
                                                                      StrToIntDef(TabTalent.Cells[ColTalNbAugm, IndActu],0));
                Trouve := True;
                break;
              end;

          if not trouve then
            begin
              if TabAugmentationTalent.Cells[ColAugmTalSpeSel,indAugm] <> '' then
                PTalent := chercheTalent(TabAugmentationTalent.Cells[ColAugmTalSpeSel,indAugm])
              else
                PTalent := chercheTalent(TabAugmentationTalent.Cells[ColAugmTalCode,indAugm]);
              TabTalent.RowCount := TabTalent.rowCount + 1;
              TabTalent.Cells[ColTalCode, TabTalent.RowCount-1]   := PTalent.CodeTalent;
              TabTalent.Cells[ColTalLib, TabTalent.RowCount-1]   := PTalent.Libelle;

              // Talent generique a plusieurs prises distinctes (Max>1, ex. Knightly
              // Virtue) resolu en une specialisation nommee : "Nouveau" porte le TOTAL
              // cumule de prises voulues (ex. 2), pas le rang de CE stub precis (une
              // Vertu nommee ne se reprend jamais deux fois - Nb fixe a 1, garanti par
              // l'anti-doublon de TabAugmentationTalentDblClick). Le total cumule est
              // maintenu A PART sur une ligne separee sous le code GENERIQUE (colonne
              // Work, jamais ecrasee) : c'est elle que le chargement retrouvera par
              // correspondance EXACTE au prochain palier, avant le repli par radical qui,
              // lui, accroche un stub sans <Max> et bloquerait tout achat au-dela de 1.
              // CONTEXT.md 2.78, prises multiples.
              if (TabAugmentationTalent.Cells[ColAugmTalSpeSel,indAugm] <> '') and
                 (Pos(ValeurGenerique, TabAugmentationTalent.Cells[ColAugmTalWork,indAugm]) > 0) and
                 TryStrToInt(ChercheTalent(TabAugmentationTalent.Cells[ColAugmTalWork,indAugm]).MaxiTalent, NbMaxGen) and
                 (NbMaxGen > 1) then
                begin
                  // NbAugm a -1 (pas 0) : le cout de CETTE Vertu est deja compte sur la
                  // ligne generique juste en dessous, mais la ligne doit quand meme survivre
                  // a l'enregistrement - or Personnage.AugmentationTalent (chargepersonnage.pas,
                  // ce qui est ecrit dans le fichier du personnage) ne reprend que les lignes
                  // dont NbAugm <> 0 (ChargeAugmentation/MajTables plus bas). Un negatif
                  // survit a la sauvegarde ET reste a cout nul dans CalculExperience
                  // (Total(-1) > Gratuit(0) est faux) sans toucher cette fonction partagee.
                  // Mis a '1' au premier essai : facturait 100 Xp en trop par Vertu. Mis a
                  // '0' au deuxieme essai : la ligne disparaissait carrement a l'enregistrement
                  // (vu par Nono en jeu). CONTEXT.md 2.78, prises multiples. ATTENTION : si un
                  // ModifyCarac est un jour branche sur une Vertu nommee (Grail Virtue of the
                  // Ideal), il devra lire Abs(Valeur), pas Valeur brute (signe invers sinon).
                  TabTalent.Cells[ColTalNb, TabTalent.RowCount-1]     := '1';
                  TabTalent.Cells[ColTalNbAugm, TabTalent.RowCount-1] := '-1';
                  TabTalent.Cells[ColTalMax, TabTalent.RowCount-1]    := '1';

                  TrouveGenerique := false;
                  for IndActu := 1 to TabTalent.RowCount-1 do
                    if TabTalent.Cells[ColTalCode, IndActu] = TabAugmentationTalent.Cells[ColAugmTalWork,indAugm] then
                      begin
                        TabTalent.Cells[ColTalNb, IndActu]     := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
                        TabTalent.Cells[ColTalNbAugm, IndActu] := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
                        // Max REEL du talent (pas le total achete) : c'est cette donnee que
                        // relit TabAugmentationTalentSelectCell pour borner "Nouveau" au
                        // changement de cellule - la laisser vide y ferait retomber la
                        // borne a 1 par defaut. CONTEXT.md 2.78, prises multiples.
                        TabTalent.Cells[ColTalMax, IndActu]    := IntToStr(NbMaxGen);
                        TrouveGenerique := true;
                        break;
                      end;
                  if not TrouveGenerique then
                    begin
                      PTalentGenerique := ChercheTalent(TabAugmentationTalent.Cells[ColAugmTalWork,indAugm]);
                      TabTalent.RowCount := TabTalent.RowCount + 1;
                      TabTalent.Cells[ColTalCode, TabTalent.RowCount-1]   := PTalentGenerique.CodeTalent;
                      TabTalent.Cells[ColTalLib, TabTalent.RowCount-1]    := PTalentGenerique.Libelle;
                      TabTalent.Cells[ColTalNb, TabTalent.RowCount-1]     := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
                      TabTalent.Cells[ColTalNbAugm, TabTalent.RowCount-1] := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
                      TabTalent.Cells[ColTalMax, TabTalent.RowCount-1]    := IntToStr(NbMaxGen);
                    end;
                end
              else
                begin
                  TabTalent.Cells[ColTalNb ,TabTalent.RowCount-1]   := IntToStr(StrToIntDef(TabTalent.Cells[ColTalNb ,TabTalent.RowCount-1],0) + StrToIntDef(TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm],0));
                  TabTalent.Cells[ColTalNbAugm,TabTalent.RowCount-1]   := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
                  TabTalent.Cells[ColTalMax, TabTalent.RowCount-1]   := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
                end;
            end;

          if TabAugmentationTalent.Cells[ColAugmTalCout, IndAugm] <> TabAugmentationTalent.Cells[ColAugmTalReel, IndAugm] then
            begin
              TabAugmentationMjXp.RowCount  := TabAugmentationMjXp.RowCount + 1;
              TabAugmentationMjXp.Cells[ColAugmMjXpType, TabAugmentationMjXp.RowCount-1]  := ConstXmlTalent;
              TabAugmentationMjXp.Cells[ColAugmMjXpCode, TabAugmentationMjXp.RowCount-1]  := TabAugmentationTalent.Cells[ColAugmTalCode, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpDebut, TabAugmentationMjXp.RowCount-1] := TabAugmentationTalent.Cells[ColAugmTalActuel, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpFin, TabAugmentationMjXp.RowCount-1]   := TabAugmentationTalent.Cells[ColAugmTalNouveau, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpCout, TabAugmentationMjXp.RowCount-1]  := TabAugmentationTalent.Cells[ColAugmTalCout, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpReel, TabAugmentationMjXp.RowCount-1]  := TabAugmentationTalent.Cells[ColAugmTalReel, indAugm];
              TabAugmentationMjXp.Cells[ColAugmMjXpNew, TabAugmentationMjXp.RowCount-1]   := ConstSelectionne;
            end;

        end;

    // Colonne 1 vide = ligne "a choisir" (ConstArbreAuChoix) jamais resolue : ne rien
    // ajouter plutot que d'accorder un sort fantome (ChercheSort('') renvoyait une
    // StructureSort vide, d'ou une ligne d'equipement fantome avant ce garde-fou).
    For IndAugm := 1 to TabSort.RowCount-1 do
      if TabSort.Cells[1, indAugm] <> '' then
        begin
          PSort := ChercheSort(TabSort.Cells[1, indAugm]);
          TabEquipement.RowCount                           := TabEquipement.RowCount + 1;
          TabEquipement.Cells[1, TabEquipement.RowCount-1] := '';
          TabEquipement.Cells[2, TabEquipement.RowCount-1] := PSort.CodeSort;
          TabEquipement.Cells[3, TabEquipement.RowCount-1] := PSort.TypeSort;
          TabEquipement.Cells[4, TabEquipement.RowCount-1] := PSort.Libelle;
          TabEquipement.Cells[5, TabEquipement.RowCount-1] := '0';
        end;

    // Sort choisi via la colonne "Spell" du tableau de talents (ModeSort=CHOIX, resolu par
    // TabAugmentationTalentDblClick - voir A FAIRE.txt, tentative AjoutMineur du 18/09/2026,
    // pour l'impasse que ce mecanisme remplace).
    For IndAugm := 1 to TabAugmentationTalent.RowCount-1 do
      if TabAugmentationTalent.Cells[ColAugmTalSortSel, indAugm] <> '' then
        begin
          PSort := ChercheSort(TabAugmentationTalent.Cells[ColAugmTalSortSel, indAugm]);
          TabEquipement.RowCount                           := TabEquipement.RowCount + 1;
          TabEquipement.Cells[1, TabEquipement.RowCount-1] := '';
          TabEquipement.Cells[2, TabEquipement.RowCount-1] := PSort.CodeSort;
          TabEquipement.Cells[3, TabEquipement.RowCount-1] := PSort.TypeSort;
          TabEquipement.Cells[4, TabEquipement.RowCount-1] := PSort.Libelle;
          TabEquipement.Cells[5, TabEquipement.RowCount-1] := '0';
        end;
    RafraichitTabEquipementAffichage();
    TabAugmentationTalent.enabled := false;

    // Expérience
    tabExperience.Cells[ColXpDonnee,LigXpTotal] := EditTotalXp.Text;
    EditTotalXp.enabled := false;
  end;

procedure TWinPersonnages.MajTablesEvolutionCarriere();
  var
    PTalent:                  StructureTalent;
    PMetierCompetence:        StructureMetierCompetence;
    PMetierTalent:            StructureMetierTalent;
    Ind:                      Integer;
    CandidatsAppart:          String;
    Appartenances:            TStringList;
    IndApp:                   Integer;
    Paliers:                  TListCareerBonusNiveau;
    Palier:                   StructureCareerBonusNiveau;
    PersonnageTalentCarriere: StructurePersonnageTalentCarriereRequise;
    DejaLie:                  Boolean;
    IndTalCar:                Integer;
    NbLiensGardes:            Integer;
  begin
    // évolution de carrière
      if RadioButtonSuivant.checked or RadioButtonChanger.checked then
        begin
          // carrièrere
          Personnage.MetierEnCours.NiveauMetier        := StrToInt(NvNiveau);
          Personnage.MetierEnCours.CodeMetier          := NvMetier;
          // Adapting Careers : entree dans un nouveau niveau 1, on redemande les facultatives
          if StrToInt(NvNiveau) = 1 then
            Personnage.ChoixAdaptation := DemanderAdaptationsFacultatives(NvMetier, Personnage.Race, Personnage.ChoixAdaptation);
          TabCarriere.Cells[4, TabCarriere.Rowcount-1] := IntToStr(EditNeedRealXp.value);

          TabCarriere.RowCount := TabCarriere.RowCount + 1;
          TabCarriere.Cells[1, TabCarriere.RowCount - 1] := NvMetier;
          TabCarriere.Cells[2, TabCarriere.RowCount - 1] := NvNiveau;

          // ancienne carrières
          Personnage.MetierAncien := [];
          for Ind := 1 to TabCarriere.Rowcount - 1 do
            begin
              PersonnageMetier.CodeMetier   := TabCarriere.Cells[1, Ind];
              PersonnageMetier.NiveauMetier := StrToIntDef(TabCarriere.Cells[2, Ind],0);
              PersonnageMetier.CoutXp       := CalculOptionXpDiv25Inverse(StrToIntDef(TabCarriere.Cells[4, Ind],0));
              Personnage.MetierAncien       += [PersonnageMetier];
            end;

          // Competence
          if StrToInt(NvNiveau) = 1 then
            begin
              Personnage.MetierCompetence := [];
              for PMetierCompetence in ListMetierCompetence do
                if CompareRechercheValeur(PMetierCompetence.CodeMetier, NvMetier) then
                  begin
                    // Adapting Careers : substitution selon l'ethnie (Choix vide = seules
                    // les adaptations imposees s'appliquent).
                    PersonnageCompetence.CodeCompetence := AdapterElement(NvMetier, Personnage.Race, Personnage.ChoixAdaptation,
                                                             PMetierCompetence.NiveauMetier, ConstXmlCompetence,
                                                             PMetierCompetence.CodeCompetence);
                    if PersonnageCompetence.CodeCompetence = '' then
                      continue;
                    PersonnageCompetence.Valeur         := PMetierCompetence.NiveauMetier;
                    Personnage.MetierCompetence         += [PersonnageCompetence];
                  end;

              Personnage.MetierTalent := [];
              for PMetierTalent in ListMetierTalent do
                if CompareRechercheValeur(PMetierTalent.CodeMetier, NvMetier) then
                  begin
                    PersonnageTalent.CodeTalent := AdapterElement(NvMetier, Personnage.Race, Personnage.ChoixAdaptation,
                                                     PMetierTalent.NiveauMetier, ConstXmlTalent,
                                                     PMetierTalent.CodeTalent);
                    if PersonnageTalent.CodeTalent = '' then
                      continue;
                    // PMetierTalent.NiveauMetier reste stocke tel quel : ce champ sert aussi de
                    // FILTRE "a quel niveau de carriere ce talent apparait" ailleurs (ex.
                    // CalculAvancement, ~L5977 : "PersonnageTalent.Valeur = StrToInt(MetierNvEnCours)"
                    // pour proposer les talents nouvellement debloques au palier atteint) - le
                    // remettre a 1 ici cassait cette comparaison des le niveau 2. Le vrai bug
                    // (un pick de carriere compte pour "NiveauMetier" rangs au lieu d'1 dans le
                    // calcul de degats) est corrige au point de consommation, dans
                    // PersonnageTalentModificateur (chargepersonnage.pas), pas ici.
                    PersonnageTalent.Valeur     := PMetierTalent.NiveauMetier;
                    Personnage.MetierTalent     += [PersonnageTalent];
                  end;

              // Entrer dans une carriere ouvre le droit a une APPARTENANCE (regiment,
              // ordre de chevalerie, culte). Le choix est REDEMANDE a chaque entree en
              // carriere et il est CUMULATIF : on n'en retire jamais une, parce que le
              // livre dit qu'on garde ce qu'elle a donne meme apres l'avoir quittee. Un
              // personnage qui refuse repond "aucune", et rien n'est propose s'il ne
              // reste aucun candidat. CONTEXT.md 2.44.
              CandidatsAppart := AppartenancesCandidates(NvMetier, Personnage.Race,
                                                         Personnage.Appartenance);
              if CandidatsAppart <> '' then
                begin
                  ChoixWinTypeFichier         := ConstXmlDataCareerBonus;
                  ChoixWinCareerBonus         := CandidatsAppart;
                  // Remise a vide OBLIGATOIRE : fermer la fenetre sans double-cliquer ne
                  // touche pas a SelectWin..., qui garderait sinon la reponse du choix
                  // precedent.
                  SelectWinCareerBonus        := '';
                  SelectWinLivre              := Personnage.LivresAcceptes;
                  FenSpecialisation           := TWinSpecialisations.Create(Application);
                  FenSpecialisation.Position  := poOwnerFormCenter;
                  FenSpecialisation.ShowModal;
                  SelectWinLivre := '';
                  if SelectWinCareerBonus <> '' then
                    if Trim(Personnage.Appartenance) = '' then
                      Personnage.Appartenance := SelectWinCareerBonus
                    else
                      Personnage.Appartenance := Personnage.Appartenance + ',' + SelectWinCareerBonus;
                end;

              // Les APPARTENANCES (regiment, ordre, culte) greffent leurs competences et
              // talents sur la carriere, "as if added to their Career". L'appel vient
              // APRES les deux boucles ci-dessus, qui repartent d'une liste vide : place
              // avant, il serait efface. CONTEXT.md 2.44.
              PersonnageAppliqueGreffes(Personnage);
              // Rafraichit l'affichage sans attendre un nouveau passage dans MajTables,
              // pour capter le choix qui vient d'etre fait. CONTEXT.md 2.44.
              LibAppartenance.Caption := LibelleAppartenances(Personnage.Appartenance);
            end;

          // <SkillChoice> d'une appartenance DEJA acquise (ex. Reiksguard palier 4,
          // ConstXmlSkillChoice) - hors du bloc "= 1" ci-dessus, exprès : contrairement aux
          // greffes Skill/Talent normales (ecrites d'un coup a l'entree en carriere puis
          // filtrees par CalculTableExperience selon le niveau), un SkillChoice exige une
          // DECISION du joueur, prise au moment ou le palier qui le porte est reellement
          // atteint - donc a CHAQUE avancement de niveau, pas seulement au premier.
          Appartenances := TStringList.Create;
          try
            ExtractStrings([','], [], PChar(Personnage.Appartenance), Appartenances);
            for IndApp := 0 to Appartenances.Count - 1 do
              begin
                if Trim(Appartenances[IndApp]) = '' then
                  continue;
                Paliers := NiveauxDuCareerBonus(Trim(Appartenances[IndApp]));
                try
                  for Palier in Paliers do
                    if (Palier.Niveau = StrToInt(NvNiveau)) and (Palier.NbChoixCompetence > 0) then
                      begin
                        ChoixCompetenceAppartenanceRace          := Personnage.Race;
                        ChoixCompetenceAppartenanceCount         := Palier.NbChoixCompetence;
                        SelectCompetenceAppartenance             := '';
                        FenChoixCompetenceAppartenance           := TWinChoixCompetenceAppartenance.Create(Application);
                        FenChoixCompetenceAppartenance.Position  := poOwnerFormCenter;
                        FenChoixCompetenceAppartenance.ShowModal;
                        if SelectCompetenceAppartenance <> '' then
                          begin
                            CandidatsAppart := SelectCompetenceAppartenance;
                            for Ind := 1 to CountOccurrences(CandidatsAppart, ',') + 1 do
                              begin
                                PersonnageCompetence                := Default(StructurePersonnageCompetence);
                                PersonnageCompetence.CodeCompetence := Trim(ExtractChaine(',', CandidatsAppart, Ind));
                                PersonnageCompetence.Valeur          := Palier.ValeurChoixCompetence;
                                Personnage.CompetenceAppartenance   += [PersonnageCompetence];
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

          // Talents octroyes / retires a un niveau de carriere, en donnees (<GrantAt> et
          // <LoseAt> du talent, ex. Virtue of the Quest NATIO-T0017 : octroi a l'entree en
          // Questing Knight niveau 3, perdu des le niveau 4 de Grail Knight, Nations of Mankind
          // p.12). Octroi gratuit en Xp (NbAugm='-1', meme trick que les Vertus bretonnes
          // nommees, 2.78) ; Personnage.TalentCarriereRequise garde le lien carriere+niveau pour
          // que l'affichage barre le talent si le personnage n'y est plus. Le retrait supprime
          // la ligne ET le lien (sinon un lien orphelin subsisterait).
          for IndTalCar := 0 to ListTalent.Count - 1 do
            begin
              PTalent := ListTalent[IndTalCar];
              if (PTalent.OctroiCarriere = '') and (PTalent.RetraitCarriere = '') then
                Continue;
              if (PTalent.RetraitCarriere <> '')
                 and (NvMetier = ExtractStringBefore(PTalent.RetraitCarriere, SeparateurMulti))
                 and (StrToIntDef(NvNiveau, 0) >= StrToIntDef(ExtractStringAfter(PTalent.RetraitCarriere, SeparateurMulti), 0)) then
                begin
                  for Ind := TabTalent.RowCount - 1 downto 1 do
                    if TabTalent.Cells[ColTalCode, Ind] = PTalent.CodeTalent then
                      TabTalent.DeleteRow(Ind);
                  NbLiensGardes := 0;
                  for Ind := 0 to High(Personnage.TalentCarriereRequise) do
                    if Personnage.TalentCarriereRequise[Ind].CodeTalent <> PTalent.CodeTalent then
                      begin
                        Personnage.TalentCarriereRequise[NbLiensGardes] := Personnage.TalentCarriereRequise[Ind];
                        Inc(NbLiensGardes);
                      end;
                  SetLength(Personnage.TalentCarriereRequise, NbLiensGardes);
                end
              else if (PTalent.OctroiCarriere <> '')
                 and (NvMetier = ExtractStringBefore(PTalent.OctroiCarriere, SeparateurMulti))
                 and (StrToIntDef(NvNiveau, 0) = StrToIntDef(ExtractStringAfter(PTalent.OctroiCarriere, SeparateurMulti), 0)) then
                begin
                  DejaLie := false;
                  for Ind := 0 to High(Personnage.TalentCarriereRequise) do
                    if Personnage.TalentCarriereRequise[Ind].CodeTalent = PTalent.CodeTalent then
                      DejaLie := true;
                  if not DejaLie then
                    begin
                      TabTalent.RowCount := TabTalent.RowCount + 1;
                      TabTalent.Cells[ColTalCode, TabTalent.RowCount-1]   := PTalent.CodeTalent;
                      TabTalent.Cells[ColTalLib, TabTalent.RowCount-1]    := ChercheTalent(PTalent.CodeTalent).Libelle;
                      TabTalent.Cells[ColTalNb, TabTalent.RowCount-1]     := '1';
                      TabTalent.Cells[ColTalNbAugm, TabTalent.RowCount-1] := '-1';
                      TabTalent.Cells[ColTalMax, TabTalent.RowCount-1]    := '1';

                      PersonnageTalentCarriere              := Default(StructurePersonnageTalentCarriereRequise);
                      PersonnageTalentCarriere.CodeTalent    := PTalent.CodeTalent;
                      PersonnageTalentCarriere.CodeMetier    := NvMetier;
                      PersonnageTalentCarriere.NiveauMetier  := StrToIntDef(NvNiveau, 0);
                      Personnage.TalentCarriereRequise      += [PersonnageTalentCarriere];
                    end;
                end;
            end;
        end;


    TabTalent.SortColRow(true, 3);
    tabCompetence.SortColRow(true, ColCompLib);
    CalculTotaux();
    NiveauMetierTalentMax();
    MarqueNiveauEnCours();
    CalculAvancement();
    CalculTableExperience();

    ButtonAugmentation.visible := false;
    ButtonSauvegarde.visible   := true;
    ButtonPdf.visible          := false;
    AjustePositionTables();
  end;

procedure TWinPersonnages.MajTablesPersonnage();
  var
    IndOld:                   Integer;
    OldAugmentationTalent:    TArrayPersonnageTalent;
    Ind:                      Integer;
    CodesObjets:              TStringList;
    Avant:                    String;
  begin
    // Maj données générales
    Personnage.Age        := StrToIntDef(EditAge.Text,0);
    Personnage.Height     := StrToIntDef(EditHeight.Text,0);
    if EditMonnaie[0] <> nil then
      begin
        Personnage.MonnaieCO := StrToIntDef(EditMonnaie[0].Text, 0);
        Personnage.MonnaiePA := StrToIntDef(EditMonnaie[1].Text, 0);
        Personnage.MonnaieSB := StrToIntDef(EditMonnaie[2].Text, 0);
      end;
    Personnage.HairColors := EditHairColors.Text;
    Personnage.EyeColors  := EditEyeColors.Text;

    // Maj personnage Attribut
    Personnage.AugmentationAttribut := [];
    For Ind := 1 to TabAttribut.ColCount - 1 do
      if StrToIntDef(TabAttribut.Cells[Ind, LigAttBonus],0) > 0 then
        begin
          PersonnageAttribut.CodeAttribut  := TabAttribut.Cells[Ind, LigAttCode];
          PersonnageAttribut.Valeur        := StrToIntDef(TabAttribut.Cells[Ind, LigAttBonus],0);
          Personnage.AugmentationAttribut  += [PersonnageAttribut];
        end;

    // Maj personnage Compétences
    Personnage.AugmentationCompetence := [];
    For Ind := 1 to TabCompetence.Rowcount - 1 do
      if StrToIntDef(TabCompetence.Cells[ColCompWork, Ind],0) > 0 then
        begin
          PersonnageCompetence.CodeCompetence := TabCompetence.Cells[ColCompCode, Ind];
          PersonnageCompetence.Valeur         := StrToIntDef(TabCompetence.Cells[ColCompWork, Ind],0);
          Personnage.AugmentationCompetence   += [PersonnageCompetence];
        end;

    // Maj personnage Talent
    // OldAugmentationTalent conserve l'Asterisque deja calcule avant ce resync - meme
    // logique et meme raison que CalculTotaux ci-dessus (~l.2438), PersonnageTalent etant
    // ici la variable GLOBALE de l'unite (declaree ~l.450, non redeclaree localement dans
    // MajTables), donc partagee avec tout le reste du code.
    OldAugmentationTalent := Personnage.AugmentationTalent;
    Personnage.AugmentationTalent := [];
    for Ind := 1 to TabTalent.Rowcount - 1 do
      // <> 0 et non > 0 : une Vertu nommee (Knightly Virtue...) porte un NbAugm negatif
      // volontaire (deja comptee en cout sur la ligne generique, mais doit quand meme
      // survivre a l'enregistrement). Ne change rien pour les autres talents, dont NbAugm
      // n'est jamais negatif. CONTEXT.md 2.78, prises multiples.
      if StrToIntDef(TabTalent.Cells[ColTalNbAugm, Ind],0) <> 0 then
        begin
          PersonnageTalent.CodeTalent    := TabTalent.Cells[ColTalCode, Ind];
          PersonnageTalent.Valeur        := StrToIntDef(TabTalent.Cells[ColTalNbAugm, Ind],0);
          PersonnageTalent.Asterisque    := 0;
          for IndOld := 0 to high(OldAugmentationTalent) do
            if CompareRechercheValeur(OldAugmentationTalent[IndOld].CodeTalent, PersonnageTalent.CodeTalent) then
              begin
                PersonnageTalent.Asterisque := OldAugmentationTalent[IndOld].Asterisque;
                break;
              end;
          Personnage.AugmentationTalent  += [PersonnageTalent];
        end;

    // Competence <Skill> d'un talent possede : ajoutee aux competences de carriere (Perfect Pitch -> Chant)
    PersonnageAppliqueTalentsCompetences(Personnage);

    // Maj personnage Equipement
    AttribueIdAnimaux;
    Personnage.Equipement := [];
    for Ind := 1 to TabEquipement.RowCount - 1 do
      begin
        PersonnageEquipement.CodeEquipement := TabEquipement.Cells[2, Ind];
        // Cf. l'autre point de reconstruction depuis la grille (ci-dessus) : colonne 9.
        PersonnageEquipement.Quantite       := StrToIntDef(TabEquipement.Cells[9, Ind], 1);
        if PersonnageEquipement.Quantite < 1 then PersonnageEquipement.Quantite := 1;
        PersonnageEquipement.IdInstance     := TabEquipement.Cells[10, Ind];
        PersonnageEquipement.NomLibre       := TabEquipement.Cells[13, Ind];
        PersonnageEquipement.EncLibre       := StrToIntDef(TabEquipement.Cells[14, Ind], 0);
        PersonnageEquipement.PortePar       := TabEquipement.Cells[11, Ind];
        If TalentSort(TabEquipement.Cells[2, Ind]).CodeTalent <> ''
           then
          begin
            PersonnageEquipement.TypeEquipement    := TypeEquipSp;
            PersonnageEquipement.QualiteEquipement := '';
            PersonnageEquipement.CoutXp            := CalculOptionXpDiv25Inverse(StrToIntDef(TabEquipement.Cells[5, Ind],0));
            PersonnageEquipement.Porte              := False;
          end
        else
          begin
            PersonnageEquipement.TypeEquipement    := TabEquipement.Cells[3, Ind];
            PersonnageEquipement.QualiteEquipement := TabEquipement.Cells[7, Ind];
            PersonnageEquipement.CoutXp            := 0;
            PersonnageEquipement.Porte              := TabEquipement.Cells[8, Ind] <> '';
          end;
        Personnage.Equipement += [PersonnageEquipement];
      end;
    // Objets propres : on ne garde que ceux qui ont encore une ligne d'equipement, et les
    // specialisations propres effectivement prises par le personnage
    if Personnage.ObjetsPropres <> '' then
      begin
        CodesObjets := TStringList.Create;
        try
          CodesObjetsPropresUtilises(CodesObjets);
          Avant := Personnage.ObjetsPropres;
          Personnage.ObjetsPropres := ObjetsPropresUtiles(Personnage.ObjetsPropres, CodesObjets);
          // une specialisation elaguee ne doit plus etre proposee par la fenetre de choix
          if Personnage.ObjetsPropres <> Avant then
            InjecteObjetsPropres(Personnage.ObjetsPropres);
        finally
          CodesObjets.Free;
        end;
      end;

    // Maj Augmentation Xp MJ
    Personnage.XpCoutAttribut   := [];
    Personnage.XpCoutCompetence := [];
    Personnage.XpCoutTalent     := [];
    For Ind := 1 to TabAugmentationMjXp.Rowcount -1 do
      begin
        if TabAugmentationMjXp.Cells[ColAugmMjXpType, Ind] = ConstXmlCarac then
          begin
            PersonnageXpAttribut.CodeAttribut := TabAugmentationMjXp.Cells[ColAugmMjXpCode, Ind];
            PersonnageXpAttribut.Debut        := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpDebut, Ind],0);
            PersonnageXpAttribut.Fin          := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpFin, Ind],0);
            PersonnageXpAttribut.CoutXp       := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpReel, Ind],0);
            Personnage.XpCoutAttribut         += [PersonnageXpAttribut]
          end
        else if TabAugmentationMjXp.Cells[ColAugmMjXpType, Ind] = ConstXmlCompetence then
          begin
            PersonnageXpCompetence.CodeCompetence := TabAugmentationMjXp.Cells[ColAugmMjXpCode, Ind];
            PersonnageXpCompetence.Debut          := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpDebut, Ind],0);
            PersonnageXpCompetence.Fin            := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpFin, Ind],0);
            PersonnageXpCompetence.CoutXp         := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpReel, Ind],0);
            Personnage.XpCoutCompetence           += [PersonnageXpCompetence]
          end
        else if TabAugmentationMjXp.Cells[ColAugmMjXpType, Ind] = ConstXmlTalent then
          begin
            PersonnageXpTalent.CodeTalent := TabAugmentationMjXp.Cells[ColAugmMjXpCode, Ind];
            PersonnageXpTalent.Debut      := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpDebut, Ind],0);
            PersonnageXpTalent.Fin        := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpFin, Ind],0);
            PersonnageXpTalent.CoutXp     := StrToIntDef(TabAugmentationMjXp.Cells[ColAugmMjXpReel, Ind],0);
            Personnage.XpCoutTalent       += [PersonnageXpTalent]
          end;
      end;

    // Livre
    Personnage.LivresAcceptes := '';
    for Ind := 1 to TabLivre.RowCount - 1 do
      if (TabLivre.Cells[1, Ind] = ConstSelectionne) and (TabLivre.Cells[3, Ind] <> '') then
        Personnage.LivresAcceptes += AjouteAccolade(TabLivre.Cells[3, ind]);

    // Options
    Personnage.Options := '';
    if (CheckBoxXpDiv25.Checked = true) then
      Personnage.Options += AjouteAccolade(ConstXmlOptionXpDiv25);
    if (CheckBoxPdfFeldo2p.Checked = true) then
      Personnage.Options += AjouteAccolade(ConstXmlOptionFeldo2P);
    if (CheckBoxQuickArmor.Checked = true) then
      Personnage.Options += AjouteAccolade(ConstXmlOptionQuickArmor);
    if not CheckBoxMunition.Checked then
      Personnage.Options += AjouteAccolade(ConstXmlOptionSansMunition);
    if CheckBoxSansAsterisque.Checked then
      Personnage.Options += AjouteAccolade(ConstXmlOptionSansAsterisque)
    else if CheckBoxSansMontant.Checked then
      Personnage.Options += AjouteAccolade(ConstXmlOptionSansMontant);
    if CheckBoxStylePdf.Checked then
      Personnage.Options += AjouteAccolade(ConstXmlOptionStylePdf);
    if not CheckBoxCouleurPdf.Checked then
      Personnage.Options += AjouteAccolade(ConstXmlOptionPdfSansCouleur);
    if CheckBoxEconomiePdf.Checked then
      Personnage.Options += AjouteAccolade(ConstXmlOptionPdfEconomie);

    // Carrière
    if RadioButtonSuivant.checked or RadioButtonChanger.checked then
      begin
        if XmlSauvegarde() then
          close;
      end
    else
      CalculAvancement();
  end;

Procedure TWinPersonnages.MajTables();
  begin
    MajTablesAugmentations();
    MajTablesEvolutionCarriere();
    MajTablesPersonnage();
  end;



function TWinPersonnages.XmlSauvegarde(): Boolean;
  var
    fileName:              String;
    directoryPath:         String;
    FichierPrecedent:      String;
    XpEtat:                StructureXpEtat;
    PersonnageCorruption:  StructurePersonnageCorruption;
    Ind:                   Integer;
    ContenuPrecedent, ContenuNouveau: TStringList;
  begin
    Result := False;

    // Maj personnage Corruption
    Personnage.Corruption := [];
    for Ind := 1 to StringGridCorruption.RowCount - 1 do
      if trim(StringGridCorruption.Cells[1, Ind]) <> '' then
        begin
          PersonnageCorruption.Montant := StrToIntDef(StringGridCorruption.Cells[1, Ind], 0);
          PersonnageCorruption.Libelle := StringGridCorruption.Cells[2, Ind];
          Personnage.Corruption        += [PersonnageCorruption];
        end;

    // Maj personnage Destin, Resilience et Resolution
    Personnage.Destin := [];
    for Ind := 0 to PanelDestin.Compte - 1 do
      begin
        PersonnageCorruption.Montant := PanelDestin.Montant(Ind);
        PersonnageCorruption.Libelle := PanelDestin.Libelle(Ind);
        Personnage.Destin            += [PersonnageCorruption];
      end;
    Personnage.Resilience := [];
    for Ind := 0 to PanelResilience.Compte - 1 do
      begin
        PersonnageCorruption.Montant := PanelResilience.Montant(Ind);
        PersonnageCorruption.Libelle := PanelResilience.Libelle(Ind);
        Personnage.Resilience        += [PersonnageCorruption];
      end;
    Personnage.Resolve := [];
    for Ind := 0 to PanelResolve.Compte - 1 do
      begin
        PersonnageCorruption.Montant := PanelResolve.Montant(Ind);
        PersonnageCorruption.Libelle := PanelResolve.Libelle(Ind);
        Personnage.Resolve           += [PersonnageCorruption];
      end;

    // nouveau fichier
    directoryPath         := GetCurrentDir+ConstCheminPersonnage+NomPersonnage;
    FichierPrecedent      := XmlPersonnageFichierActuel(directoryPath);
    fileName              := directoryPath + '\' + FormatDateTime('yyyymmdd', Date) + '-' + FormatDateTime('hhnnss', Time) + '.xml';
    // Total/Restant lus directement sur CalculXpEtat (entiers) et non sur le texte affiche
    // de tabExperience : celui-ci porte un separateur de milliers (Format('%.0n',...)) que
    // StrToIntDef ne sait pas reparser - CurrentXp finissait a "0" des que Restant >= 1000.
    // Le parametre Xp doit rester le total BRUT (PersonnageXmlCreation le redivise lui-meme
    // par 25 pour ecrire Xp25) : XpEtat.Total bascule deja sur l'unite divisee des que
    // CheckBoxXpDiv25 est coche (CalculXpEtat, pour que Restante colle a l'ecran) - le
    // passer tel quel ici double-divisait Xp25 et ecrasait Xp (brut) par la valeur divisee
    // (ex. Xp=2675/CurrentXp=175 devenu Xp=107/Xp25=4 au lieu de Xp=2675/Xp25=107). Xp
    // reste donc lu sur EditTotalXp (toujours brut), seul XpRestante suit l'unite courante.
    XpEtat                := CalculXpEtat();
    if not PersonnageXmlCreation(Personnage, StrToIntDef(EditTotalXp.Text,0), XpEtat.Restante, fileName, Personnage.NomPersonnage) then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_066'));
        Exit;
      end;

    // Contenu identique au fichier precedent : le nouveau fichier n'apporte rien, on l'efface
    // plutot que d'accumuler des doublons a chaque Enregistrer sans changement reel (remplace
    // l'ancien controle RULES-MESS_024 sur 4 champs choisis, qui ratait tout changement gratuit).
    if (FichierPrecedent <> '') and FileExists(FichierPrecedent) then
      begin
        ContenuPrecedent := TStringList.Create;
        ContenuNouveau   := TStringList.Create;
        try
          ContenuPrecedent.LoadFromFile(FichierPrecedent);
          ContenuNouveau.LoadFromFile(fileName);
          if ContenuPrecedent.Text = ContenuNouveau.Text then
            begin
              DeleteFile(fileName);
              ShowMEssage(GetTexteLibelle('RULES-MESS_024'));
            end;
        finally
          ContenuPrecedent.Free;
          ContenuNouveau.Free;
        end;
      end;

    NeedUpdate            := true;
    RecherchePersonnage   := NomPersonnage;
    Result                := True;
  end;


function TWinPersonnages.ChercherValeurParCode(const Chaine: string; const CodeRecherche: string): string;
var
  Lignes: TStringList;
  i:      Integer;
  Code:   string;
  Valeur: string;
begin
  Lignes := TStringList.Create;
  try
    // Découper la chaîne en lignes
    Lignes.Text := Chaine;

    // Parcourir les lignes
    for i := 0 to Lignes.Count - 1 do
    begin
      // Séparer le code et la valeur en utilisant la tabulation comme séparateur
      Code := Copy(Lignes[i], 1, Pos(Separateurtabulation, Lignes[i]) - 1);
      Valeur := Copy(Lignes[i], Pos(Separateurtabulation, Lignes[i]) + 1, Length(Lignes[i]));

      // Vérifier si le code correspond à celui recherché
      if SameText(Code, CodeRecherche) then
      begin
        Result := Valeur;
        Exit;
      end;
    end;
  finally
    Lignes.Free;
  end;

  // Si le code n'a pas été trouvé, renvoyer une valeur par défaut ou une chaîne vide
  Result := '';
end;

Procedure TWinPersonnages.ChargerMetierEquipement(CodeMetier: String; NiveauMetier: Integer);
  var
    NbMetierEquipementTab: Integer;
    PMetierEquipement:     StructureMetierEquipement;
    PMetierEquipBrut:      StructureMetierEquipement;
    CodeAdapt:             String;
    ListeCode:             String;
    Typ:                   String;
    Lib:                   String;
    Code:                  String;
    PArme:                 StructureArme;
    PArmure:               StructureArmure;
    PTrapping:             StructureTrapping;
    I, J:                  Integer;
  begin
  // RAZ
  for I := 1 to TabMetierEquipement.RowCount -1 do
    For J := 1 to TabMetierEquipement.ColCount -1 do
      TabMetierEquipement.Cells[J, I] := '';
  TabMetierEquipement.Rowcount := 1;

  if CodeMetier <> '' then
   begin
    NbMetierEquipementTab        := 0;
    TabMetierEquipement.RowCount := 1;
    for PMetierEquipBrut in ListMetierEquipement do
      if CompareRechercheValeur(PMetierEquipBrut.CodeMetier, CodeMetier) and (PMetierEquipBrut.NiveauMetier = NiveauMetier) then
        Begin
           // Adapting Careers : un trapping remplace (ou retire) selon l ethnie ; le type est recalcule
           // sur le nouveau code (arme, armure ou Divers). Retrait sans ajout : pas de ligne.
           PMetierEquipement := PMetierEquipBrut;
           CodeAdapt := AdapterElement(CodeMetier, Personnage.Race, Personnage.ChoixAdaptation, NiveauMetier, ConstXmlTrapping, PMetierEquipBrut.Equipement);
           if CodeAdapt <> PMetierEquipBrut.Equipement then
             begin
               if CodeAdapt = '' then Continue;
               PMetierEquipement.Equipement     := CodeAdapt;
               PMetierEquipement.TypeEquipement := GetTypeMetierEquipement(CodeAdapt);
             end;
           NbMetierEquipementTab        := NbMetierEquipementTab + 1;
           TabMetierEquipement.RowCount := NbMetierEquipementTab + 1;
           ListeCode                    := GetListeEquipement(PMetierEquipement.Equipement, PMetierEquipement.TypeEquipement);
           TabMetierEquipement.Cells[0, NbMetierEquipementTab] := CaseVide;

           if Pos(',',ListeCode) > 0 then
             begin
               TabMetierEquipement.Cells[2, NbMetierEquipementTab]   := ConstArbreAuchoix;
               TabMetierEquipement.Cells[3, NbMetierEquipementTab]   := ListeCode;
               TabMetierEquipement.Cells[6, NbMetierEquipementTab]   := IntToStr(PMetierEquipement.Quantite);
             end
           else
             begin
               Code := PMetierEquipement.Equipement;
               if InList(PMetierEquipement.TypeEquipement,TypeEquipMetierArme) then
                   begin
                     PArme   := ChercheArme(Code);
                     Lib     := PArme.Libelle;
                     Typ     := TypeEquipWe;
                   end
                 else if PMetierEquipement.TypeEquipement = TypeEquipAR then
                   begin
                     PArmure := ChercheArmure(Code);
                     Lib     := PArmure.Libelle;
                     Typ     := TypeEquipAR;
                   end
                 else if PMetierEquipement.TypeEquipement = TypeEquipDI then
                   begin
                     // Cf. wincreation.pas ButtonMetierHasardClick : un code Divers peut
                     // etre un Trapping catalogue (RULES-TRAP_xxx), resolu ici sans changer
                     // sa classification TypeEquipDI (CONTEXT.md 2.77bis).
                     PTrapping := ChercheTrapping(Code);
                     if PTrapping.CodeTrapping <> '' then
                       Lib := PTrapping.Libelle
                     else
                       Lib := Code;
                     Typ     := TypeEquipDI;
                   end;
               TabMetierEquipement.Cells[1, NbMetierEquipementTab] := Code;
               TabMetierEquipement.Cells[2, NbMetierEquipementTab] := Lib;
               TabMetierEquipement.Cells[4, NbMetierEquipementTab] := Typ;
               TabMetierEquipement.Cells[6, NbMetierEquipementTab] := IntToStr(PMetierEquipement.Quantite);
             end;

        end;
   end;
  AdjustGridColumnsWidth(TabMetierEquipement, PageExperience.Height, false, false);
end;

Procedure TWinPersonnages.AfficheFabrication();
  var
    IndTab:       Integer;
    Code:         String;
    Val:          String;
    Strings:      TStringList;
    I:            Integer;
    PFabrication: StructureFabrication;
    TextFab:      String;
    NbLignesFab:  Integer;
  begin

    For IndTab := 1 to TabEquipement.RowCount - 1 do
      Begin
        // Ajoutez les éléments souhaités à la liste
        if InList(TabEquipement.Cells[7, IndTab],',0') then
          TabEquipement.Cells[6, IndTab] := ''
        else
          Begin
            TextFab  := '';
            strings  := TStringList.Create;
            ExtractStrings([','], [], PChar(TabEquipement.Cells[7, IndTab]), Strings);
            for I := 0 to Strings.Count -1 do
              Begin
                Code := ExtractStringBefore(Strings[I],' ');
                Val  := ExtractStringAfter(Strings[I],' ');
                PFabrication := ChercheFabrication(Code);
                // Une fabrication par ligne (LineEnding) : la cellule 6 n'est qu'un affichage, la
                // donnee reste dans la colonne 7. 20/09/2026.
                if TextFab <> '' then TextFab := TextFab + ',' + LineEnding;
                TextFab := TextFab + PFabrication.Libelle;
                if PFabrication.Maximum <> '1' then
                  TextFab := TextFab + '('+Val+')';
              end;
            NbLignesFab := Strings.Count;
            strings.free;
            TabEquipement.Cells[6, IndTab] := TextFab;
            if NbLignesFab < 1 then NbLignesFab := 1;
            TabEquipement.RowHeights[IndTab] := NbLignesFab * 18;
            if TabEquipement.RowHeights[IndTab] < TabEquipement.DefaultRowHeight then
              TabEquipement.RowHeights[IndTab] := TabEquipement.DefaultRowHeight;
          end;
        if TabEquipement.Cells[6, IndTab] = '' then
          TabEquipement.RowHeights[IndTab] := TabEquipement.DefaultRowHeight;
      end;
    // Recalcule la hauteur de la grille et la largeur de la colonne (lignes plus hautes).
    AdjustGridColumnsWidth(TabEquipement, 9999, false, false, true, 0, 0, ssautoboth, false);
  end;

Procedure TWinPersonnages.AugmentationAjouteXpMj(TypeDonnee: String);
  begin
    // en dernière ligne de la table, renseigner une ligne avec le texte <ajouter>
    // pour permettre d'ajouter un autre talent ou compétence hors carrière
    case TypeDonnee of
      ConstXmlTalent:
        if TabAugmentationTalent.Cells[ColAugmTalLib, TabAugmentationTalent.RowCount-1] <> GetTexteLibelle(ConstLabAdd) then
          begin
            TabAugmentationTalent.RowCount := TabAugmentationTalent.RowCount + 1;
            TabAugmentationTalent.Cells[2, TabAugmentationTalent.RowCount-1]            := CouleurKo;
            TabAugmentationTalent.Cells[ColAugmTalLib, TabAugmentationTalent.RowCount-1] := GetTexteLibelle(ConstLabAdd);
          end;
      ConstXmlCompetence:
        if TabAugmentationCompetence.Cells[ColAugmCompLib, TabAugmentationCompetence.RowCount-1] <> GetTexteLibelle(ConstLabAdd) then
          begin
            TabAugmentationCompetence.RowCount := TabAugmentationCompetence.RowCount + 1;
            TabAugmentationCompetence.Cells[2, TabAugmentationCompetence.RowCount-1]               := CouleurKo;
            TabAugmentationCompetence.Cells[ColAugmCompLib, TabAugmentationCompetence.RowCount-1] := GetTexteLibelle(ConstLabAdd);
          end;
    end;
  end;

Function TWinPersonnages.CalculOptionXpDiv25(Xp: Integer): Integer;
  begin
    if CheckBoxXpDiv25.checked then
      Result := trunc(Xp / 25)
    else
      Result := Xp;
  end;

Function TWinPersonnages.CalculOptionXpDiv25Inverse(Xp: Integer): Integer;
  // Inverse de CalculOptionXpDiv25 : les grilles portent des unites DIVISEES,
  // le XML porte de l'XP ABSOLUE. A n'appeler qu'au moment d'ecrire dans Personnage.
  begin
    if CheckBoxXpDiv25.checked then
      Result := Xp * 25
    else
      Result := Xp;
  end;

end.

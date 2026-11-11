unit CreationV1;

{$mode ObjFPC}{$H+}

// Creation d'un personnage WFRP 1re edition (Core p.14-18) dans WinCreation : les controles propres a V1
// sont poses dans les onglets de la fenetre (caracteristiques dans Attributs, classe dans Metier, puis
// age et competences de depart dans Competences de race). WinCreation garde le fil des phases ;
// cette unite tient les donnees et les controles de V1.

interface

uses
  Classes, SysUtils, StrUtils, Math, Controls, Menus, StdCtrls, ExtCtrls, Grids, Graphics, Spin,
  GlobalFonts, ChargeConstantes, ChargeTexte, ChargeRace, ChargeRaceAttribut, ChargeAttribut,
  ChargeMetierAttribut, UnitCalcul, ChargeCompetence, ChargeRacePhysique,
  ChargeMetier, ChargeMetierCompetence, ChargeTirageMetier, ChargeRegle, ChargeMetierEquipement, BCButton, BCLabelContour;

type
  // Choix exclusif (au choix / au hasard...) : des RadioButton dans un GroupBox, que MiseAJourUnContenaire sait styler
  // (un TRadioGroup n'est pas reconnu, son texte reste illisible sur le fond de la fenetre)
  TGroupeChoix = class(TGroupBox)
  private
    FIndex:   Integer;
    FBoutons: array of TRadioButton;
    procedure BoutonClick(Sender: TObject);
    procedure SetIndex(Valeur: Integer);
  public
    OnClic: TNotifyEvent;
    procedure Ajoute(AProprietaire: TComponent; const Legende: String; Largeur: Integer);
    property ItemIndex: Integer read FIndex write SetIndex;
  end;

  // WinCreation dit si une competence est deja prise par la race (grille des competences de race)
  TCompetenceRaceFunc = function(const Code: String): Boolean of object;
  TNbCompetenceRaceFunc = function(): Integer of object;

  // Une ligne du profil : la formule du livre decoupee en des + bonus
  TLigneCaracV1 = record
    Code:    String;
    Libelle: String;
    Formule: String;
    NbDes:   Integer;
    Faces:   Integer;
    Bonus:   Integer;
    Min1:    Boolean;
    De:      Integer;   // somme des des, -1 = pas encore tire
    Valeur:  Integer;   // -1 = pas encore definie
  end;

  { TCreationV1 }

  TCreationV1 = class
  private
    Proprietaire:  TComponent;   // proprietaire de tous les controles : un panneau a part, style en bloc a la fin du constructeur
    Modele:        TBCButton;    // bouton modele de WinCreation (style de la charte)
    // caracteristiques
    RgCarac:       TGroupeChoix;
    GridCarac:     TStringGrid;
    BtnTirerCarac: TBCButton;
    Lignes:        array of TLigneCaracV1;
    RaceDesLignes: String;
    // classe
    RgClasse:      TGroupeChoix;
    GridClasse:    TStringGrid;
    BtnTirerClasse: TBCButton;
    MemoClasse:    TMemo;
    // age et competences de depart (les competences de race restent dans la grille de WinCreation)
    RgAge:         TGroupeChoix;
    SpinAge:       TSpinEdit;
    BtnTirerAge:   TBCButton;
    LabNb:         TLabel;
    SpinNb:        TSpinEdit;
    GridChoix:     TStringGrid;   // table d100 de la classe et de l'ethnie, sans ce qui est deja pris
    GridPris:      TStringGrid;   // competences tirees ou choisies
    BtnTirerComp:  TBCButton;
    PrisCodes:     TStringList;
    PrisOrigines:  TStringList;   // LAB_834 (tiree) / LAB_835 (choisie) en face de chaque competence
    ChoixCodes:    TStringList;
    CleComp:       String;        // race + classe pour lesquelles la liste est construite
    CleAge:        String;
    // carriere de base (table d100 de la classe et de l'ethnie) et metier de l'Artisan
    RgCar:         TGroupeChoix;
    GridCar:       TStringGrid;
    BtnTirerCar:   TBCButton;
    ChkGreaterInt: TCheckBox;     // Greater Intelligence de Book of the Rat : Int du skaven +5, visible si le livre est charge
    ChkAcadRevise: TCheckBox;     // tableau Academic revise de Realms of Sorcery, visible si le livre est charge
    MemoCar:       TMemo;
    LabArt:        TLabel;
    GridArt:       TStringGrid;
    BtnTirerArt:   TBCButton;
    TirageCar:     TListTirageMetier;
    CleCar:        String;        // race + classe pour lesquelles la carriere est choisie
    // equipement de depart : textes du livre (classe, carriere) et argent
    MemoEquip:     TMemo;
    LabArgent:     TLabel;
    SpinArgent:    TSpinEdit;
    BtnTirerArgent: TBCButton;
    ArgentFixe:    Boolean;       // le montant a ete tire ou saisi
    CleEquip:      String;
    // objets de la liste de prix (216) : catalogue a droite, objets choisis dessous (double clic pour ajouter / retirer)
    GridObjets:    TStringGrid;
    GridObjPris:   TStringGrid;
    ObjPris:       TStringList;   // codes EquipmentV1 des objets choisis, un par exemplaire
    // equipement de depart de la carriere (SUBCHAPTER_ITEM) : une ligne par element, "A/B" = choix a la creation
    GridCarriere:  TStringGrid;
    LignesCarr:    TStringList;   // Equipement brut de chaque ligne (code, "A/B" ou texte libre)
    QuantCarr:     TStringList;   // Quantite brute de chaque ligne ('' = 1)
    BranchesMenu:  TStringList;   // codes proposes par le menu de choix en cours
    QuantMenuStr:  String;        // quantites brutes de la ligne dont le menu est ouvert
    MenuBr:        TPopupMenu;    // choix entre les branches d'un "A/B"
    function  NouveauBouton(Conteneur: TWinControl; Legende: String; Gauche, Haut, Largeur: Integer; Clic: TNotifyEvent): TBCButton;
    function  NouvelleGrille(Conteneur: TWinControl; Gauche, Haut, Largeur, Hauteur, NbCol: Integer): TStringGrid;
    function  NouveauGroupe(Conteneur: TWinControl; Gauche, Haut, Largeur: Integer; Modes: array of String; Clic: TNotifyEvent): TGroupeChoix;
    procedure StyleSpin(Spin: TSpinEdit);
    procedure Change();
    // caracteristiques
    procedure ConstruitLignes();
    procedure TireLigne(I: Integer);
    procedure CalculeValeur(I: Integer);
    procedure AfficheLignes();
    procedure RgCaracClick(Sender: TObject);
    procedure TirerCaracClick(Sender: TObject);
    procedure GridCaracDblClick(Sender: TObject);
    procedure GridCaracSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GridCaracSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
    // classe
    function  ExigencesEffectives(const PClasse: StructureClasseV1): String;
    function  ClasseDisponible(const PClasse: StructureClasseV1): Boolean;
    procedure SelectionneClasse(Code: String);
    procedure GridClasseSelect(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure RgClasseClick(Sender: TObject);
    procedure TirerClasseClick(Sender: TObject);
    // age et competences de depart
    function  EspeceDuPerso(): String;
    function  ModificateurAge(Age: Integer): Integer;
    function  TireAge(): Integer;
    function  CompetencePrise(const Code: String): Boolean;
    procedure AfficheCompetences();
    procedure TirerAgeClick(Sender: TObject);
    procedure SpinNbChange(Sender: TObject);
    procedure TirerCompClick(Sender: TObject);
    procedure GridChoixDblClick(Sender: TObject);
    procedure GridPrisDblClick(Sender: TObject);
    // carriere de base et metier de l'Artisan
    function  ReglePourClasse(): String;
    function  EstArtisan(const Code: String): Boolean;
    procedure SelectionneCarriere(Code: String);
    procedure SelectionneArtisan(Code: String);
    procedure AfficheMemoCarriere();
    procedure GridCarSelect(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GridArtSelect(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure RgCarClick(Sender: TObject);
    procedure ChkAcadReviseClick(Sender: TObject);
    procedure ChkGreaterIntClick(Sender: TObject);
    procedure TirerCarClick(Sender: TObject);
    procedure TirerArtClick(Sender: TObject);
    // equipement de depart
    function  PClasseDe(const Code: String): StructureClasseV1;
    procedure TirerArgentClick(Sender: TObject);
    procedure SpinArgentChange(Sender: TObject);
    procedure AfficheObjetsChoisis();
    procedure GridObjetsDblClick(Sender: TObject);
    procedure GridObjPrisDblClick(Sender: TObject);
    procedure GridCarriereDblClick(Sender: TObject);
    procedure BrancheClick(Sender: TObject);
    procedure AfficheEquipCarriere();
  public
    CodeRace:   String;
    CodeClasse: String;
    CodeCarriere: String;
    CodeArtisan:  String;
    OnChange:   TNotifyEvent;   // l'etat d'une etape a change (WinCreation peut rafraichir ses boutons)
    CompetenceDeRace: TCompetenceRaceFunc;
    NbCompetencesRace: TNbCompetenceRaceFunc;
    constructor Create(AProprietaire: TComponent; PageCarac, PageClasse, PageComp, PageCarriere, PageEquip: TWinControl; ModeleBouton: TBCButton);
    destructor Destroy; override;
    procedure AfficheCarrieres();
    function  CarriereComplete(): Boolean;
    procedure AfficheEquipement();
    function  EquipementComplet(): Boolean;
    function  ArgentDepart(): Integer;
    procedure ObjetsChoisis(Codes: TStringList);
    procedure CompetencesCarriere(Codes: TStringList);
    procedure AfficheAgeCompetences();
    function  AgeChoisi(): Integer;
    function  NbCompetencesVoulu(): Integer;
    function  NbCompetencesATirer(): Integer;
    function  NbCompetencesPrises(): Integer;
    function  CodePris(I: Integer): String;
    // la race vient d'etre enregistree par WinCreation : une autre race efface caracteristiques et classe
    procedure ChoisitRace(Code: String);
    procedure AfficheCaracteristiques();
    procedure AfficheClasses();
    function  CaracComplete(): Boolean;
    function  ValeurCarac(CodeAttribut: String): Integer;
    function  NbLignes(): Integer;
    function  LigneCode(I: Integer): String;
    function  LigneValeur(I: Integer): Integer;
    function  LigneLibelle(I: Integer): String;
  end;

implementation

const
  // Tableau Academic revise (Realms of Sorcery p.25) : remplace celui du Rulebook p.18 si la case est cochee
  RegleAcademicRevisee = 'WROS-RULE_CAREER_CHART_ACADEMIC_REVISED';
  RegleGreaterInt      = 'BOTR-RULE_GREATER_INTELLIGENCE';
  EthnieSkaven         = 'BOTR-RACE_SKAVEN';
  // Colonnes de la grille des caracteristiques
  ColLibelle = 0;
  ColFormule = 1;
  ColDes     = 2;
  ColValeur  = 3;

// "1d3+4", "2d10+20", "1d3-1 (minimum 1)", "1" : decoupe une formule du livre
procedure DecoupeFormule(Brut: String; var NbDes, Faces, Bonus: Integer; var Min1: Boolean);
  var
    Formule:  String;
    PosD, I:  Integer;
    Reste:    String;
  begin
    NbDes := 0;
    Faces := 0;
    Bonus := 0;
    Min1  := Pos('minimum 1', LowerCase(Brut)) > 0;
    Formule := LowerCase(Trim(Brut));
    if Pos(' ', Formule) > 0 then
      Formule := Copy(Formule, 1, Pos(' ', Formule) - 1);
    PosD := Pos('d', Formule);
    if PosD = 0 then
      begin
        Bonus := StrToIntDef(Formule, 0);
        Exit;
      end;
    NbDes := StrToIntDef(Copy(Formule, 1, PosD - 1), 1);
    Reste := Copy(Formule, PosD + 1, MaxInt);
    I := 1;
    while (I <= Length(Reste)) and (Reste[I] in ['0'..'9']) do
      Inc(I);
    Faces := StrToIntDef(Copy(Reste, 1, I - 1), 0);
    Reste := Copy(Reste, I, MaxInt);
    if Reste <> '' then
      Bonus := StrToIntDef(StringReplace(Reste, '+', '', []), 0);
  end;

constructor TCreationV1.Create(AProprietaire: TComponent; PageCarac, PageClasse, PageComp, PageCarriere, PageEquip: TWinControl; ModeleBouton: TBCButton);
  var
    Panneau: TPanel;
    I:       Integer;
  begin
    inherited Create;
    ArgentFixe := False;
    CleEquip   := '';
    Modele     := ModeleBouton;
    // les controles appartiennent a un panneau cache, style en bloc a la fin (MiseAJourUnContenaire)
    Panneau         := TPanel.Create(AProprietaire);
    Panneau.Visible := False;
    Panneau.Parent  := TWinControl(AProprietaire);
    Proprietaire    := Panneau;
    CodeRace   := '';
    CodeClasse := '';
    CodeCarriere := '';
    CodeArtisan  := '';
    CleCar       := '';
    TirageCar := TListTirageMetier.Create;
    PrisCodes    := TStringList.Create;
    ObjPris      := TStringList.Create;
    LignesCarr   := TStringList.Create;
    QuantCarr    := TStringList.Create;
    BranchesMenu := TStringList.Create;
    PrisOrigines := TStringList.Create;
    ChoixCodes   := TStringList.Create;
    CleComp := '';
    CleAge  := '';

    // caracteristiques
    RgCarac := NouveauGroupe(PageCarac, 8, 8, 880,
      [GetTexteLibelle('RULES-LAB_085'), GetTexteLibelle('RULES-LAB_089'), GetTexteLibelle('RULES-LAB_084')], @RgCaracClick);
    GridCarac := NouvelleGrille(PageCarac, 8, 80, 640, 430, 4);
    GridCarac.Cells[ColLibelle, 0] := GetTexteLibelle('RULES-LAB_008');
    GridCarac.Cells[ColFormule, 0] := GetTexteLibelle('RULES-LAB_819');
    GridCarac.Cells[ColDes,     0] := GetTexteLibelle('RULES-LAB_827');
    GridCarac.Cells[ColValeur,  0] := GetTexteLibelle('RULES-LAB_820');
    GridCarac.ColWidths[ColLibelle] := 260;
    GridCarac.ColWidths[ColFormule] := 160;
    GridCarac.ColWidths[ColDes]     := 100;
    GridCarac.ColWidths[ColValeur]  := 100;
    GridCarac.OnDblClick       := @GridCaracDblClick;
    // goRowSelect interdit l'editeur de cellule : selection par cellule, memes couleurs
    GridCarac.Options          := GridCarac.Options - [goRowSelect] + [goEditing];
    GridCarac.OnSelectEditor   := @GridCaracSelectEditor;
    GridCarac.OnSetEditText    := @GridCaracSetEditText;
    BtnTirerCarac := NouveauBouton(PageCarac, GetTexteLibelle('RULES-LAB_817'), 668, 80, 200, @TirerCaracClick);
    ChkGreaterInt := TCheckBox.Create(Proprietaire);
    ChkGreaterInt.Parent  := PageCarac;
    ChkGreaterInt.SetBounds(668, 130, 330, 24);
    ChkGreaterInt.Caption := ChercheRegle(RegleGreaterInt).Libelle;
    ChkGreaterInt.OnClick := @ChkGreaterIntClick;
    // un TCheckBox n'est pas style par MiseAJourUnContenaire : texte clair sur le fond sombre de l'onglet
    ChkGreaterInt.Font.Name  := ConstPoliceNom;
    ChkGreaterInt.Font.Size  := ConstPoliceTaille;
    ChkGreaterInt.Font.Bold  := True;
    ChkGreaterInt.Font.Color := clWhite;
    ChkGreaterInt.Visible := False;

    // classe
    // le groupe « Regle » de WinCreation (x 480 a 1000, y 0 a 96) reste visible en haut a droite de cette page
    RgClasse := NouveauGroupe(PageClasse, 8, 8, 460,
      [GetTexteLibelle('RULES-LAB_084'), GetTexteLibelle('RULES-LAB_085')], @RgClasseClick);
    GridClasse := NouvelleGrille(PageClasse, 8, 104, 640, 160, 3);
    GridClasse.Cells[0, 0] := GetTexteLibelle('RULES-LAB_815');
    GridClasse.Cells[1, 0] := GetTexteLibelle('RULES-LAB_822');
    GridClasse.Cells[2, 0] := '';
    GridClasse.ColWidths[0] := 150;
    GridClasse.ColWidths[1] := 330;
    GridClasse.ColWidths[2] := 150;
    GridClasse.OnSelectCell := @GridClasseSelect;
    BtnTirerClasse := NouveauBouton(PageClasse, GetTexteLibelle('RULES-LAB_085'), 668, 104, 200, @TirerClasseClick);
    MemoClasse := TMemo.Create(Proprietaire);
    MemoClasse.Parent     := PageClasse;
    MemoClasse.SetBounds(8, 279, 880, 280);
    MemoClasse.ReadOnly   := True;
    MemoClasse.ScrollBars := ssVertical;
    MemoClasse.WordWrap   := True;

    // age et competences de depart : age en haut, competences de race (grille de WinCreation) a gauche en dessous,
    // table d100 et competences prises a droite
    RgAge := NouveauGroupe(PageComp, 8, 8, 260, [GetTexteLibelle('RULES-LAB_829'), GetTexteLibelle('RULES-LAB_830')], nil);
    SpinAge := TSpinEdit.Create(Proprietaire);
    SpinAge.Parent := PageComp;
    SpinAge.SetBounds(278, 24, 70, 28);
    SpinAge.MinValue := 1;
    SpinAge.MaxValue := 999;
    SpinAge.Value    := 16;
    BtnTirerAge := NouveauBouton(PageComp, GetTexteLibelle('RULES-LAB_839'), 358, 20, 150, @TirerAgeClick);
    LabNb := TLabel.Create(Proprietaire);
    LabNb.Parent  := PageComp;
    LabNb.SetBounds(530, 30, 190, 20);
    LabNb.Caption := GetTexteLibelle('RULES-LAB_831');
    SpinNb := TSpinEdit.Create(Proprietaire);
    SpinNb.Parent := PageComp;
    SpinNb.SetBounds(725, 24, 70, 28);
    SpinNb.MinValue := 0;
    SpinNb.MaxValue := 30;
    SpinNb.Value    := 0;
    SpinNb.OnChange := @SpinNbChange;
    GridChoix := NouvelleGrille(PageComp, 520, 168, 480, 250, 2);
    GridChoix.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_836');
    GridChoix.Cells[1, 0]  := '%';
    GridChoix.ColWidths[0] := 390;
    GridChoix.ColWidths[1] := 70;
    GridChoix.OnDblClick   := @GridChoixDblClick;
    GridPris := NouvelleGrille(PageComp, 520, 430, 480, 250, 2);
    GridPris.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_836');
    GridPris.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_837');
    GridPris.ColWidths[0] := 340;
    GridPris.ColWidths[1] := 120;
    GridPris.OnDblClick   := @GridPrisDblClick;
    BtnTirerComp := NouveauBouton(PageComp, GetTexteLibelle('RULES-LAB_832'), 520, 700, 300, @TirerCompClick);

    // carriere de base : table d100 a gauche, fiche de la carriere et metier de l'Artisan a droite
    RgCar := NouveauGroupe(PageCarriere, 8, 8, 880,
      [GetTexteLibelle('RULES-LAB_084'), GetTexteLibelle('RULES-LAB_085')], @RgCarClick);
    GridCar := NouvelleGrille(PageCarriere, 8, 80, 440, 520, 2);
    GridCar.Cells[0, 0]  := '%';
    GridCar.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_096');
    GridCar.ColWidths[0] := 80;
    GridCar.ColWidths[1] := 330;
    GridCar.OnSelectCell := @GridCarSelect;
    BtnTirerCar := NouveauBouton(PageCarriere, GetTexteLibelle('RULES-LAB_085'), 468, 80, 200, @TirerCarClick);
    ChkAcadRevise := TCheckBox.Create(Proprietaire);
    ChkAcadRevise.Parent  := PageCarriere;
    ChkAcadRevise.SetBounds(690, 84, 300, 24);
    ChkAcadRevise.Caption := ChercheRegle(RegleAcademicRevisee).Libelle;
    ChkAcadRevise.OnClick := @ChkAcadReviseClick;
    ChkAcadRevise.Visible := False;
    MemoCar := TMemo.Create(Proprietaire);
    MemoCar.Parent     := PageCarriere;
    MemoCar.SetBounds(468, 120, 520, 220);
    MemoCar.ReadOnly   := True;
    MemoCar.ScrollBars := ssVertical;
    MemoCar.WordWrap   := True;
    LabArt := TLabel.Create(Proprietaire);
    LabArt.Parent  := PageCarriere;
    LabArt.SetBounds(468, 352, 400, 20);
    LabArt.Caption := GetTexteLibelle('RULES-LAB_812');
    GridArt := NouvelleGrille(PageCarriere, 468, 376, 520, 224, 2);
    GridArt.Cells[0, 0]  := '%';
    GridArt.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_812');
    GridArt.ColWidths[0] := 80;
    GridArt.ColWidths[1] := 400;
    GridArt.OnSelectCell := @GridArtSelect;
    BtnTirerArt := NouveauBouton(PageCarriere, GetTexteLibelle('RULES-LAB_085'), 468, 610, 200, @TirerArtClick);
    LabArt.Visible := False;
    GridArt.Visible := False;
    BtnTirerArt.Visible := False;

    // equipement de depart : le texte du livre, puis l'argent (formule de la classe)
    MemoEquip := TMemo.Create(Proprietaire);
    MemoEquip.Parent     := PageEquip;
    MemoEquip.SetBounds(8, 8, 470, 200);
    MemoEquip.ReadOnly   := True;
    MemoEquip.ScrollBars := ssVertical;
    MemoEquip.WordWrap   := True;
    LabArgent := TLabel.Create(Proprietaire);
    LabArgent.Parent  := PageEquip;
    LabArgent.SetBounds(8, 494, 500, 20);
    SpinArgent := TSpinEdit.Create(Proprietaire);
    SpinArgent.Parent := PageEquip;
    SpinArgent.SetBounds(520, 488, 90, 28);
    SpinArgent.MinValue := 0;
    SpinArgent.MaxValue := 9999;
    SpinArgent.Value    := 0;
    SpinArgent.OnChange := @SpinArgentChange;
    BtnTirerArgent := NouveauBouton(PageEquip, GetTexteLibelle('RULES-LAB_085'), 630, 486, 200, @TirerArgentClick);
    GridObjets := NouvelleGrille(PageEquip, 488, 8, 500, 280, 3);
    GridObjets.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_014');
    GridObjets.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_711');
    GridObjets.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_015');
    GridObjets.ColWidths[0] := 250;
    GridObjets.ColWidths[1] := 150;
    GridObjets.ColWidths[2] := 80;
    GridObjets.OnDblClick   := @GridObjetsDblClick;
    GridObjPris := NouvelleGrille(PageEquip, 488, 296, 500, 182, 3);
    GridObjPris.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_014');
    GridObjPris.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_711');
    GridObjPris.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_015');
    GridObjPris.ColWidths[0] := 250;
    GridObjPris.ColWidths[1] := 150;
    GridObjPris.ColWidths[2] := 80;
    GridObjPris.OnDblClick   := @GridObjPrisDblClick;
    // equipement de la carriere : double clic = prendre l'objet (ou choisir parmi les branches)
    GridCarriere := NouvelleGrille(PageEquip, 8, 216, 470, 262, 2);
    GridCarriere.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_013');
    GridCarriere.Cells[1, 0]  := '';
    MenuBr := TPopupMenu.Create(GridCarriere);
    GridCarriere.ColWidths[0] := 360;
    GridCarriere.ColWidths[1] := 80;
    GridCarriere.OnDblClick   := @GridCarriereDblClick;

    // charte : memos, libelles, groupes de choix et boutons, puis les controles repassent devant le fond de l'onglet
    StyleSpin(SpinAge);
    StyleSpin(SpinNb);
    StyleSpin(SpinArgent);
    MiseAJourUnContenaire(Panneau);
    for I := 0 to Panneau.ComponentCount - 1 do
      if (Panneau.Components[I] is TControl) and not (Panneau.Components[I] is TShape) then
        TControl(Panneau.Components[I]).BringToFront;
  end;

destructor TCreationV1.Destroy;
  begin
    TirageCar.Free;
    PrisCodes.Free;
    ObjPris.Free;
    LignesCarr.Free;
    QuantCarr.Free;
    BranchesMenu.Free;
    PrisOrigines.Free;
    ChoixCodes.Free;
    inherited Destroy;
  end;

// Bouton de la charte : copie du bouton modele de WinCreation (comme panelcarriereespece.pas)
function TCreationV1.NouveauBouton(Conteneur: TWinControl; Legende: String; Gauche, Haut, Largeur: Integer;
  Clic: TNotifyEvent): TBCButton;
  begin
    Result         := TBCButtonContour.Create(Proprietaire);
    Result.Assign(Modele);
    Result.Parent  := Conteneur;
    Result.SetBounds(Gauche, Haut, Largeur, 45);
    Result.Caption := Legende;
    Result.OnClick := Clic;
  end;

// TSpinEdit n'est pas style par MiseAJourUnContenaire : memes couleurs que les TEdit
procedure TCreationV1.StyleSpin(Spin: TSpinEdit);
  begin
    Spin.Font.Name  := ConstPoliceNom;
    Spin.Font.Size  := ConstPoliceTaille;
    Spin.Color      := CouleurDefColor;
    Spin.Font.Color := CouleurDefInverse;
  end;

procedure TGroupeChoix.BoutonClick(Sender: TObject);
  begin
    FIndex := TRadioButton(Sender).Tag;
    if Assigned(OnClic) then
      OnClic(Self);
  end;

procedure TGroupeChoix.SetIndex(Valeur: Integer);
  begin
    if (Valeur >= 0) and (Valeur <= High(FBoutons)) then
      begin
        FIndex := Valeur;
        FBoutons[Valeur].Checked := True;
      end;
  end;

procedure TGroupeChoix.Ajoute(AProprietaire: TComponent; const Legende: String; Largeur: Integer);
  var
    Radio: TRadioButton;
  begin
    Radio := TRadioButton.Create(AProprietaire);
    Radio.Parent  := Self;
    Radio.Caption := Legende;
    Radio.Tag     := Length(FBoutons);
    // le TGroupBox reserve en haut la place de son titre (vide ici) : le client commence plus bas
    Radio.SetBounds(12 + Length(FBoutons) * Largeur, 0, Largeur - 12, 28);
    Radio.OnClick := @BoutonClick;
    SetLength(FBoutons, Length(FBoutons) + 1);
    FBoutons[High(FBoutons)] := Radio;
  end;

function TCreationV1.NouvelleGrille(Conteneur: TWinControl; Gauche, Haut, Largeur, Hauteur, NbCol: Integer): TStringGrid;
  begin
    Result            := TStringGrid.Create(Proprietaire);
    Result.Parent     := Conteneur;
    Result.SetBounds(Gauche, Haut, Largeur, Hauteur);
    Result.ColCount   := NbCol;
    Result.RowCount   := 2;
    Result.FixedCols  := 0;
    Result.FixedRows  := 1;
    Result.DefaultRowHeight := 26;
    StylesTStringGrid(Result);
    SelectionGrilleWarhammer(Result);
  end;

function TCreationV1.NouveauGroupe(Conteneur: TWinControl; Gauche, Haut, Largeur: Integer;
  Modes: array of String; Clic: TNotifyEvent): TGroupeChoix;
  var
    I: Integer;
  begin
    Result              := TGroupeChoix.Create(Proprietaire);
    Result.Parent       := Conteneur;
    Result.SetBounds(Gauche, Haut, Largeur, 56);
    Result.Caption      := '';
    for I := 0 to High(Modes) do
      Result.Ajoute(Proprietaire, Modes[I], Largeur div Length(Modes));
    Result.ItemIndex    := 0;
    Result.OnClic       := Clic;
  end;

procedure TCreationV1.Change();
  begin
    if Assigned(OnChange) then
      OnChange(Self);
  end;

procedure TCreationV1.ChoisitRace(Code: String);
  begin
    if Code <> CodeRace then
      begin
        // une autre race : les caracteristiques et la classe sont a refaire
        CodeRace      := Code;
        RaceDesLignes := '';
        CodeClasse    := '';
      end;
  end;

////////////////////////////////////////////////////////////////////////////////
//                            CARACTERISTIQUES                                //
////////////////////////////////////////////////////////////////////////////////

procedure TCreationV1.AfficheCaracteristiques();
  begin
    // la case n'a de sens que pour le skaven et si Book of the Rat est charge
    ChkGreaterInt.Visible := (ChercheRegle(RegleGreaterInt).CodeRegle <> '') and CompareRechercheValeur(CodeRace, EthnieSkaven);
    ChkGreaterInt.Caption := ChercheRegle(RegleGreaterInt).Libelle;
    if RaceDesLignes <> CodeRace then
      ConstruitLignes()
    else
      AfficheLignes();
  end;

procedure TCreationV1.ConstruitLignes();
  var
    PRaceAttribut: StructureRaceAttribut;
    PRace:         StructureRace;
    N, I:          Integer;
  begin
    PRace := ChercheRace(CodeRace);
    SetLength(Lignes, 0);
    for PRaceAttribut in ListRaceAttribut do
      if CompareRechercheValeur(PRaceAttribut.CodeRace, CodeRace) then
        begin
          N := Length(Lignes);
          SetLength(Lignes, N + 1);
          Lignes[N].Code    := PRaceAttribut.CodeAttribut;
          Lignes[N].Libelle := ChercheAttribut(PRaceAttribut.CodeAttribut).Libelle;
          Lignes[N].Formule := PRaceAttribut.CalculRace;
          DecoupeFormule(PRaceAttribut.CalculRace, Lignes[N].NbDes, Lignes[N].Faces, Lignes[N].Bonus, Lignes[N].Min1);
          // Greater Intelligence : Int +5 (le +5 de Grey Seer / Ingenieur Skryre est dit dans la regle, non applique)
          if ChkGreaterInt.Visible and ChkGreaterInt.Checked and CompareRechercheValeur(PRaceAttribut.CodeAttribut, 'RULES-ATTR_Int') then
            begin
              Lignes[N].Bonus   := Lignes[N].Bonus + 5;
              Lignes[N].Formule := IntToStr(Lignes[N].NbDes) + 'd' + IntToStr(Lignes[N].Faces) + '+' + IntToStr(Lignes[N].Bonus);
            end;
          Lignes[N].De      := -1;
          Lignes[N].Valeur  := -1;
        end;
    // Destin : formule propre a la race, sans caracteristique du profil
    if PRace.DestinV1 <> '' then
      begin
        N := Length(Lignes);
        SetLength(Lignes, N + 1);
        Lignes[N].Code    := ConstCaracDestin;
        Lignes[N].Libelle := GetTexteLibelle('RULES-LAB_821');
        Lignes[N].Formule := PRace.DestinV1;
        DecoupeFormule(PRace.DestinV1, Lignes[N].NbDes, Lignes[N].Faces, Lignes[N].Bonus, Lignes[N].Min1);
        Lignes[N].De      := -1;
        Lignes[N].Valeur  := -1;
      end;
    // une formule sans de (A = 1) est deja definie
    for I := 0 to High(Lignes) do
      if Lignes[I].NbDes = 0 then
        CalculeValeur(I);
    RaceDesLignes := CodeRace;
    AfficheLignes();
  end;

procedure TCreationV1.TireLigne(I: Integer);
  var
    J, Total: Integer;
  begin
    if Lignes[I].NbDes = 0 then Exit;
    Total := 0;
    for J := 1 to Lignes[I].NbDes do
      Total := Total + Random(Lignes[I].Faces) + 1;
    Lignes[I].De := Total;
    CalculeValeur(I);
  end;

procedure TCreationV1.CalculeValeur(I: Integer);
  begin
    if Lignes[I].NbDes = 0 then
      Lignes[I].Valeur := Lignes[I].Bonus
    else if Lignes[I].De < 0 then
      begin
        Lignes[I].Valeur := -1;
        Exit;
      end
    else
      Lignes[I].Valeur := Lignes[I].De + Lignes[I].Bonus;
    if Lignes[I].Valeur < 0 then Lignes[I].Valeur := 0;
    if Lignes[I].Min1 and (Lignes[I].Valeur < 1) then Lignes[I].Valeur := 1;
  end;

procedure TCreationV1.AfficheLignes();
  var
    I: Integer;
  begin
    GridCarac.RowCount := Length(Lignes) + 1;
    for I := 0 to High(Lignes) do
      begin
        GridCarac.Cells[ColLibelle, I + 1] := Lignes[I].Libelle;
        GridCarac.Cells[ColFormule, I + 1] := Lignes[I].Formule;
        if Lignes[I].NbDes = 0 then
          GridCarac.Cells[ColDes, I + 1] := '-'
        else if Lignes[I].De < 0 then
          GridCarac.Cells[ColDes, I + 1] := ''
        else
          GridCarac.Cells[ColDes, I + 1] := IntToStr(Lignes[I].De);
        if Lignes[I].Valeur < 0 then
          GridCarac.Cells[ColValeur, I + 1] := ''
        else
          GridCarac.Cells[ColValeur, I + 1] := IntToStr(Lignes[I].Valeur);
      end;
    BtnTirerCarac.Visible := RgCarac.ItemIndex = 0;
    BtnTirerCarac.BringToFront;
    Change();
  end;

function TCreationV1.CaracComplete(): Boolean;
  var
    I: Integer;
  begin
    Result := Length(Lignes) > 0;
    for I := 0 to High(Lignes) do
      if Lignes[I].Valeur < 0 then
        Result := False;
  end;

function TCreationV1.ValeurCarac(CodeAttribut: String): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to High(Lignes) do
      if CompareRechercheValeur(CodeAttribut, Lignes[I].Code) then
        Exit(Lignes[I].Valeur);
  end;

function TCreationV1.NbLignes(): Integer;
  begin
    Result := Length(Lignes);
  end;

function TCreationV1.LigneCode(I: Integer): String;
  begin
    Result := Lignes[I].Code;
  end;

function TCreationV1.LigneValeur(I: Integer): Integer;
  begin
    Result := Lignes[I].Valeur;
  end;

function TCreationV1.LigneLibelle(I: Integer): String;
  begin
    Result := Lignes[I].Libelle;
  end;

procedure TCreationV1.RgCaracClick(Sender: TObject);
  begin
    AfficheLignes();
  end;

procedure TCreationV1.TirerCaracClick(Sender: TObject);
  var
    I: Integer;
  begin
    for I := 0 to High(Lignes) do
      TireLigne(I);
    AfficheLignes();
  end;

// Double clic en mode hasard : relance la seule ligne choisie
procedure TCreationV1.GridCaracDblClick(Sender: TObject);
  begin
    if (RgCarac.ItemIndex <> 0) or (GridCarac.Row < 1) then Exit;
    TireLigne(GridCarac.Row - 1);
    AfficheLignes();
  end;

// Saisie permise seulement dans la colonne qui correspond au mode : des (resultat de de) ou valeur (choix)
procedure TCreationV1.GridCaracSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
  begin
    if not (((RgCarac.ItemIndex = 1) and (aCol = ColDes) and (aRow >= 1) and (Lignes[aRow - 1].NbDes > 0))
       or ((RgCarac.ItemIndex = 2) and (aCol = ColValeur) and (aRow >= 1))) then
      Editor := nil;
  end;

procedure TCreationV1.GridCaracSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
  var
    I: Integer;
  begin
    I := aRow - 1;
    if (I < 0) or (I > High(Lignes)) then Exit;
    if (RgCarac.ItemIndex = 1) and (aCol = ColDes) and (Lignes[I].NbDes > 0) then
      begin
        Lignes[I].De := StrToIntDef(Value, -1);
        CalculeValeur(I);
        GridCarac.Cells[ColValeur, aRow] := IfThen(Lignes[I].Valeur < 0, '', IntToStr(Lignes[I].Valeur));
      end
    else if (RgCarac.ItemIndex = 2) and (aCol = ColValeur) then
      begin
        Lignes[I].Valeur := StrToIntDef(Value, -1);
        Lignes[I].De     := -1;
      end
    else
      Exit;
    Change();
  end;

////////////////////////////////////////////////////////////////////////////////
//                                 CLASSE                                     //
////////////////////////////////////////////////////////////////////////////////

// Exigences qui s'appliquent a la race : celles de la classe, dont une caracteristique est remplacee par
// l'exigence propre a la race si la classe en declare une (Rogue elfe : I 65).
function TCreationV1.ExigencesEffectives(const PClasse: StructureClasseV1): String;
  var
    General, Race: TStringList;
    I, J:     Integer;
    Espece:   String;
    Cle:      String;
    Trouve:   Boolean;
  begin
    Result := '';
    General := TStringList.Create;
    Race    := TStringList.Create;
    try
      ExtractStrings([','], [' '], PChar(PClasse.Exigences), General);
      ExtractStrings([','], [' '], PChar(PClasse.ExigencesRace), Race);
      Espece := ChercheRace(CodeRace).Espece;
      for I := 0 to Race.Count - 1 do
        if Pos(':', Race[I]) > 0 then
          if CompareRechercheValeur(Copy(Race[I], 1, Pos(':', Race[I]) - 1), Espece) then
            begin
              Cle := Copy(Race[I], Pos(':', Race[I]) + 1, MaxInt);   // CODE=valeur
              Trouve := False;
              for J := 0 to General.Count - 1 do
                if Copy(General[J], 1, Pos('=', General[J]) - 1) = Copy(Cle, 1, Pos('=', Cle) - 1) then
                  begin
                    General[J] := Cle;
                    Trouve := True;
                  end;
              if not Trouve then General.Add(Cle);
            end;
      Result := General.CommaText;
    finally
      General.Free;
      Race.Free;
    end;
  end;

function TCreationV1.ClasseDisponible(const PClasse: StructureClasseV1): Boolean;
  var
    Liste:  TStringList;
    I:      Integer;
    Code:   String;
    Seuil:  Integer;
  begin
    Result := True;
    Liste  := TStringList.Create;
    try
      Liste.CommaText := ExigencesEffectives(PClasse);
      for I := 0 to Liste.Count - 1 do
        begin
          Code  := Copy(Liste[I], 1, Pos('=', Liste[I]) - 1);
          Seuil := StrToIntDef(Copy(Liste[I], Pos('=', Liste[I]) + 1, MaxInt), 0);
          if ValeurCarac(Code) < Seuil then
            Result := False;
        end;
    finally
      Liste.Free;
    end;
  end;

procedure TCreationV1.AfficheClasses();
  var
    PClasse: StructureClasseV1;
    Liste:   TStringList;
    I, Lig:  Integer;
    Texte:   String;
    Selection: Integer;
  begin
    GridClasse.RowCount := ListClasseV1.Count + 1;
    Lig := 1;
    Selection := -1;
    Liste := TStringList.Create;
    try
      for PClasse in ListClasseV1 do
        begin
          Texte := '';
          Liste.CommaText := ExigencesEffectives(PClasse);
          for I := 0 to Liste.Count - 1 do
            begin
              if Texte <> '' then Texte := Texte + ', ';
              Texte := Texte + ChercheAttribut(Copy(Liste[I], 1, Pos('=', Liste[I]) - 1)).Libelle
                       + ' >= ' + Copy(Liste[I], Pos('=', Liste[I]) + 1, MaxInt);
            end;
          GridClasse.Cells[0, Lig] := PClasse.Libelle;
          GridClasse.Cells[1, Lig] := Texte;
          if ClasseDisponible(PClasse) then
            GridClasse.Cells[2, Lig] := GetTexteLibelle('RULES-LAB_823')
          else
            GridClasse.Cells[2, Lig] := GetTexteLibelle('RULES-LAB_824');
          if PClasse.CodeClasse = CodeClasse then Selection := Lig;
          Inc(Lig);
        end;
    finally
      Liste.Free;
    end;
    BtnTirerClasse.Visible := RgClasse.ItemIndex = 1;
    if Selection > 0 then
      begin
        GridClasse.Row := Selection;
        SelectionneClasse(CodeClasse);
      end
    else
      begin
        CodeClasse := '';
        MemoClasse.Lines.Clear;
      end;
  end;

procedure TCreationV1.SelectionneClasse(Code: String);
  var
    PClasse: StructureClasseV1;
  begin
    CodeClasse := '';
    MemoClasse.Lines.Clear;
    for PClasse in ListClasseV1 do
      if PClasse.CodeClasse = Code then
        begin
          if ClasseDisponible(PClasse) then
            CodeClasse := Code;
          MemoClasse.Lines.Text := PClasse.Libelle + sLineBreak + sLineBreak + PClasse.Description
                                   + sLineBreak + sLineBreak + PClasse.Equipement
                                   + sLineBreak + PClasse.Argent;
        end;
    Change();
  end;

procedure TCreationV1.GridClasseSelect(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  begin
    if (aRow >= 1) and (aRow <= ListClasseV1.Count) then
      SelectionneClasse(ListClasseV1[aRow - 1].CodeClasse);
  end;

procedure TCreationV1.RgClasseClick(Sender: TObject);
  begin
    BtnTirerClasse.Visible := RgClasse.ItemIndex = 1;
  end;

////////////////////////////////////////////////////////////////////////////////
//                     AGE ET COMPETENCES DE DEPART                           //
////////////////////////////////////////////////////////////////////////////////

function TCreationV1.EspeceDuPerso(): String;
  begin
    Result := ChercheRace(CodeRace).Espece;
  end;

function TCreationV1.ModificateurAge(Age: Integer): Integer;
  var
    PAge: StructureAgeCompV1;
  begin
    Result := 0;
    for PAge in ListAgeCompV1 do
      if CompareRechercheValeur(PAge.Espece, EspeceDuPerso()) and (Age >= PAge.AgeMin) and (Age <= PAge.AgeMax) then
        Result := PAge.Modifieur;
  end;

// Age du livre : "Young 6d6 years, mature 6d10 years. If the result is less than 16, roll again and add..."
function TCreationV1.TireAge(): Integer;
  var
    Texte, Mot, Des: String;
    P, I:            Integer;
  begin
    Result := 0;
    Texte := LowerCase(ChercheRacePhysique(RaceSourcePhysique(CodeRace)).FormuleAge);
    if RgAge.ItemIndex = 1 then Mot := 'mature ' else Mot := 'young ';
    P := Pos(Mot, Texte);
    if P = 0 then Exit;
    I := P + Length(Mot);
    Des := '';
    while (I <= Length(Texte)) and (Texte[I] in ['0'..'9', 'd']) do
      begin
        Des := Des + Texte[I];
        Inc(I);
      end;
    if Des = '' then Exit;
    Result := LanceFormule(Des, False);
    while Result < 16 do
      Result := Result + LanceFormule(Des, False);
  end;

function TCreationV1.AgeChoisi(): Integer;
  begin
    Result := SpinAge.Value;
  end;

function TCreationV1.NbCompetencesVoulu(): Integer;
  begin
    Result := SpinNb.Value;
  end;

// Core p.16 : les competences de race (obligatoires, la seconde au choix si le perso en a deux ou plus)
// font partie du total des competences initiales ; le hasard ne complete que le reste.
function TCreationV1.NbCompetencesATirer(): Integer;
  var
    NbRace: Integer;
  begin
    NbRace := 0;
    if Assigned(NbCompetencesRace) then
      NbRace := NbCompetencesRace();
    Result := Max(0, SpinNb.Value - Min(SpinNb.Value, NbRace));
  end;

function TCreationV1.NbCompetencesPrises(): Integer;
  begin
    Result := PrisCodes.Count;
  end;

function TCreationV1.CodePris(I: Integer): String;
  begin
    Result := PrisCodes[I];
  end;

// Deja prise : tiree ou choisie ici, ou donnee par la race
function TCreationV1.CompetencePrise(const Code: String): Boolean;
  begin
    Result := PrisCodes.IndexOf(Code) >= 0;
    if (not Result) and Assigned(CompetenceDeRace) then
      Result := CompetenceDeRace(Code);
  end;

// Arrivee sur l'onglet : la liste repart de zero si la race ou la classe a change
procedure TCreationV1.AfficheAgeCompetences();
  begin
    if CleAge <> CodeRace then
      begin
        CleAge := CodeRace;
        SpinAge.Value := 16;
        SpinNb.Value  := 0;
      end;
    if CleComp <> CodeRace + '|' + CodeClasse then
      begin
        CleComp := CodeRace + '|' + CodeClasse;
        PrisCodes.Clear;
        PrisOrigines.Clear;
        SpinNb.Value := 0;
      end;
    AfficheCompetences();
  end;

procedure TCreationV1.AfficheCompetences();
  var
    I, Lig:  Integer;
    PTirage: StructureTirageCompV1;
  begin
    GridPris.RowCount := Max(2, PrisCodes.Count + 1);
    GridPris.Rows[1].Clear;
    for I := 0 to PrisCodes.Count - 1 do
      begin
        GridPris.Cells[0, I + 1] := ChercheCompetence(PrisCodes[I]).Libelle;
        GridPris.Cells[1, I + 1] := GetTexteLibelle(IfThen(PrisOrigines[I] = '1', 'RULES-LAB_834', 'RULES-LAB_835'));
      end;
    // table d100 de la classe et de l'ethnie, sans ce qui est deja pris
    ChoixCodes.Clear;
    for PTirage in ListTirageCompV1 do
      if (PTirage.CodeClasse = CodeClasse) and CompareRechercheValeur(PTirage.Espece, EspeceDuPerso())
         and (not CompetencePrise(PTirage.CodeCompetence)) then
        ChoixCodes.Add(PTirage.CodeCompetence);
    GridChoix.RowCount := Max(2, ChoixCodes.Count + 1);
    GridChoix.Rows[1].Clear;
    Lig := 1;
    for PTirage in ListTirageCompV1 do
      if (PTirage.CodeClasse = CodeClasse) and CompareRechercheValeur(PTirage.Espece, EspeceDuPerso())
         and (not CompetencePrise(PTirage.CodeCompetence)) then
        begin
          GridChoix.Cells[0, Lig] := ChercheCompetence(PTirage.CodeCompetence).Libelle;
          GridChoix.Cells[1, Lig] := IntToStr(PTirage.Chance);
          Inc(Lig);
        end;
    Change();
  end;

procedure TCreationV1.TirerAgeClick(Sender: TObject);
  var
    Age: Integer;
  begin
    Age := TireAge();
    if Age > 0 then
      begin
        SpinAge.Value := Age;
        // le nombre de competences se tire avec l'age (D4 + modificateur d'age, Core p.15)
        SpinNb.Value  := Max(1, LanceFormule('1d4', False) + ModificateurAge(Age));
      end;
    Change();
  end;

procedure TCreationV1.SpinNbChange(Sender: TObject);
  begin
    Change();
  end;

// Tire le nombre (D4 + modificateur d'age) s'il n'est pas encore fixe, puis complete par la table d100 :
// un doublon est relance, ce qui revient a tirer parmi les competences restantes au prorata de leurs chances.
procedure TCreationV1.TirerCompClick(Sender: TObject);
  var
    PTirage:       StructureTirageCompV1;
    Total, Jet, A: Integer;
    Trouve:        Boolean;
  begin
    if SpinNb.Value = 0 then
      SpinNb.Value := Max(1, LanceFormule('1d4', False) + ModificateurAge(SpinAge.Value));
    while PrisCodes.Count < NbCompetencesATirer() do
      begin
        Total := 0;
        for PTirage in ListTirageCompV1 do
          if (PTirage.CodeClasse = CodeClasse) and CompareRechercheValeur(PTirage.Espece, EspeceDuPerso())
             and (not CompetencePrise(PTirage.CodeCompetence)) then
            Total := Total + PTirage.Chance;
        if Total <= 0 then Break;
        Jet := Random(Total) + 1;
        A := 0;
        Trouve := False;
        for PTirage in ListTirageCompV1 do
          if (not Trouve) and (PTirage.CodeClasse = CodeClasse) and CompareRechercheValeur(PTirage.Espece, EspeceDuPerso())
             and (not CompetencePrise(PTirage.CodeCompetence)) then
            begin
              A := A + PTirage.Chance;
              if Jet <= A then
                begin
                  PrisCodes.Add(PTirage.CodeCompetence);
                  PrisOrigines.Add('1');
                  Trouve := True;
                end;
            end;
      end;
    AfficheCompetences();
  end;

// Choix libre : double clic sur une competence de la table
procedure TCreationV1.GridChoixDblClick(Sender: TObject);
  begin
    if (GridChoix.Row < 1) or (GridChoix.Row > ChoixCodes.Count) then Exit;
    if SpinNb.Value = 0 then
      SpinNb.Value := Max(1, LanceFormule('1d4', False) + ModificateurAge(SpinAge.Value));
    if PrisCodes.Count >= NbCompetencesATirer() then Exit;
    PrisCodes.Add(ChoixCodes[GridChoix.Row - 1]);
    PrisOrigines.Add('2');
    AfficheCompetences();
  end;

// Double clic sur une competence tiree ou choisie : on la retire
procedure TCreationV1.GridPrisDblClick(Sender: TObject);
  var
    I: Integer;
  begin
    I := GridPris.Row - 1;
    if (I < 0) or (I >= PrisCodes.Count) then Exit;
    PrisCodes.Delete(I);
    PrisOrigines.Delete(I);
    AfficheCompetences();
  end;

// Hasard : une classe tiree parmi celles dont les exigences sont remplies
procedure TCreationV1.TirerClasseClick(Sender: TObject);
  var
    Possibles: TStringList;
    I:         Integer;
  begin
    Possibles := TStringList.Create;
    try
      for I := 0 to ListClasseV1.Count - 1 do
        if ClasseDisponible(ListClasseV1[I]) then
          Possibles.Add(IntToStr(I));
      if Possibles.Count = 0 then Exit;
      I := StrToInt(Possibles[Random(Possibles.Count)]);
      GridClasse.Row := I + 1;
      SelectionneClasse(ListClasseV1[I].CodeClasse);
    finally
      Possibles.Free;
    end;
  end;

////////////////////////////////////////////////////////////////////////////////
//                  CARRIERE DE BASE ET METIER DE L ARTISAN                   //
////////////////////////////////////////////////////////////////////////////////

// La table d'une classe est la regle RULES-RULE_CAREER_CHART_<CLASSE> (DATA_CAREER_ROLL)
function TCreationV1.ReglePourClasse(): String;
  begin
    if ChkAcadRevise.Visible and ChkAcadRevise.Checked then
      Result := RegleAcademicRevisee
    else
      Result := StringReplace(CodeClasse, 'CLASS_', 'RULE_CAREER_CHART_', []);
  end;

// Les des sont a refaire : la formule de l'Int a change
procedure TCreationV1.ChkGreaterIntClick(Sender: TObject);
  begin
    RaceDesLignes := '';
    AfficheCaracteristiques();
  end;

procedure TCreationV1.ChkAcadReviseClick(Sender: TObject);
  begin
    AfficheCarrieres();
    Change();
  end;

function TCreationV1.EstArtisan(const Code: String): Boolean;
  begin
    Result := (CodeSansLivre(Code) = 'WORK_ARTISAN') or (CodeSansLivre(Code) = 'WORK_ARTISANS_APPRENTICE');
  end;

// Arrivee sur l'onglet : la carriere repart de zero si la race ou la classe a change
procedure TCreationV1.AfficheCarrieres();
  var
    I:         Integer;
    Selection: Integer;
    Ligne:     StructureTirageMetier;
    Des:       Integer;
  begin
    // la case n'a de sens que pour la classe Academic et si Realms of Sorcery est charge
    ChkAcadRevise.Visible := (ChercheRegle(RegleAcademicRevisee).CodeRegle <> '') and (CodeClasse = 'RULES-CLASS_ACADEMIC');
    ChkAcadRevise.Caption := ChercheRegle(RegleAcademicRevisee).Libelle;
    if CleCar <> CodeRace + '|' + CodeClasse + '|' + BoolToStr(ChkAcadRevise.Visible and ChkAcadRevise.Checked) then
      begin
        CleCar       := CodeRace + '|' + CodeClasse + '|' + BoolToStr(ChkAcadRevise.Visible and ChkAcadRevise.Checked);
        CodeCarriere := '';
        CodeArtisan  := '';
      end;
    CalculeTirageMetier(CodeRace, ReglePourClasse(), TirageCar);
    Des := DesDuTirage(TirageCar);
    GridCar.RowCount := Max(2, TirageCar.Count + 1);
    GridCar.Rows[1].Clear;
    Selection := -1;
    I := 1;
    for Ligne in TirageCar do
      begin
        GridCar.Cells[0, I] := FormateTranche(Ligne.Debut, Ligne.Fin, Des);
        GridCar.Cells[1, I] := ChercheMetier(Ligne.CodeMetier).Libelle;
        if Ligne.CodeMetier = CodeCarriere then Selection := I;
        Inc(I);
      end;
    BtnTirerCar.Visible := RgCar.ItemIndex = 1;
    if Selection > 0 then
      GridCar.Row := Selection
    else
      CodeCarriere := '';
    // grille des metiers de l'Artisan
    GridArt.RowCount := Max(2, ListArtisanMetier.Count + 1);
    GridArt.Rows[1].Clear;
    for I := 0 to ListArtisanMetier.Count - 1 do
      begin
        GridArt.Cells[0, I + 1] := ListArtisanMetier[I].Tirage;
        GridArt.Cells[1, I + 1] := ListArtisanMetier[I].Libelle;
      end;
    AfficheMemoCarriere();
  end;

procedure TCreationV1.SelectionneCarriere(Code: String);
  begin
    CodeCarriere := Code;
    if not EstArtisan(Code) then CodeArtisan := '';
    AfficheMemoCarriere();
    Change();
  end;

procedure TCreationV1.SelectionneArtisan(Code: String);
  begin
    CodeArtisan := Code;
    AfficheMemoCarriere();
    Change();
  end;

// Fiche de la carriere choisie : ses competences (les % du livre ne sont pas repris ici) et, pour l'Artisan, celles du metier
procedure TCreationV1.AfficheMemoCarriere();
  var
    PMetierComp: StructureMetierCompetence;
    PArtisan:    StructureArtisanMetier;
    Liste:       TStringList;
    I:           Integer;
    Texte:       String;
  begin
    MemoCar.Lines.Clear;
    LabArt.Visible      := EstArtisan(CodeCarriere);
    GridArt.Visible     := LabArt.Visible;
    BtnTirerArt.Visible := LabArt.Visible and (RgCar.ItemIndex = 1);
    if CodeCarriere = '' then Exit;
    Texte := ChercheMetier(CodeCarriere).Libelle + sLineBreak;
    for PMetierComp in ListMetierCompetence do
      if CompareRechercheValeur(PMetierComp.CodeMetier, CodeCarriere) then
        Texte := Texte + sLineBreak + ChercheCompetence(PMetierComp.CodeCompetence).Libelle;
    if CodeArtisan <> '' then
      for PArtisan in ListArtisanMetier do
        if PArtisan.CodeMetier = CodeArtisan then
          begin
            Texte := Texte + sLineBreak + sLineBreak + PArtisan.Libelle;
            Liste := TStringList.Create;
            try
              ExtractStrings([','], [' '], PChar(PArtisan.Competences), Liste);
              for I := 0 to Liste.Count - 1 do
                Texte := Texte + sLineBreak + ChercheCompetence(Liste[I]).Libelle;
            finally
              Liste.Free;
            end;
          end;
    MemoCar.Lines.Text := Texte;
  end;

procedure TCreationV1.GridCarSelect(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  begin
    if (aRow >= 1) and (aRow <= TirageCar.Count) then
      SelectionneCarriere(TirageCar[aRow - 1].CodeMetier);
  end;

procedure TCreationV1.GridArtSelect(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  begin
    if (aRow >= 1) and (aRow <= ListArtisanMetier.Count) then
      SelectionneArtisan(ListArtisanMetier[aRow - 1].CodeMetier);
  end;

procedure TCreationV1.RgCarClick(Sender: TObject);
  begin
    BtnTirerCar.Visible := RgCar.ItemIndex = 1;
    BtnTirerArt.Visible := GridArt.Visible and (RgCar.ItemIndex = 1);
  end;

// Hasard : un d100 sur la table de la classe et de l'ethnie
procedure TCreationV1.TirerCarClick(Sender: TObject);
  var
    Jet, I: Integer;
  begin
    if TirageCar.Count = 0 then Exit;
    Jet := Random(100) + 1;
    for I := 0 to TirageCar.Count - 1 do
      if (Jet >= TirageCar[I].Debut) and (Jet <= TirageCar[I].Fin) then
        begin
          GridCar.Row := I + 1;
          SelectionneCarriere(TirageCar[I].CodeMetier);
          Break;
        end;
  end;

// Hasard : un d100 sur la table des metiers ("01-05", "100")
procedure TCreationV1.TirerArtClick(Sender: TObject);
  var
    Jet, I, P, Bas, Haut: Integer;
    T: String;
  begin
    Jet := Random(100) + 1;
    for I := 0 to ListArtisanMetier.Count - 1 do
      begin
        T := ListArtisanMetier[I].Tirage;
        P := Pos('-', T);
        if P > 0 then
          begin
            Bas  := StrToIntDef(Copy(T, 1, P - 1), 0);
            Haut := StrToIntDef(Copy(T, P + 1, MaxInt), 0);
          end
        else
          begin
            Bas  := StrToIntDef(T, 0);
            Haut := Bas;
          end;
        if Haut = 0 then Haut := 100;
        if (Jet >= Bas) and (Jet <= Haut) then
          begin
            GridArt.Row := I + 1;
            SelectionneArtisan(ListArtisanMetier[I].CodeMetier);
            Break;
          end;
      end;
  end;

// Une carriere choisie ; pour l'Artisan, un metier aussi
function TCreationV1.CarriereComplete(): Boolean;
  begin
    Result := (CodeCarriere <> '') and ((not EstArtisan(CodeCarriere)) or (CodeArtisan <> ''));
  end;

////////////////////////////////////////////////////////////////////////////////
//                         EQUIPEMENT DE DEPART                               //
////////////////////////////////////////////////////////////////////////////////

function TCreationV1.PClasseDe(const Code: String): StructureClasseV1;
  var
    PClasse: StructureClasseV1;
  begin
    Result := Default(StructureClasseV1);
    for PClasse in ListClasseV1 do
      if PClasse.CodeClasse = Code then
        Exit(PClasse);
  end;

// Textes du livre : equipement de la classe, puis de la carriere (un element par ligne) ; l'argent est tire a part
procedure TCreationV1.AfficheEquipement();
  var
    PClasse: StructureClasseV1;
    Texte:   String;
    I:       Integer;
  begin
    if CleEquip <> CodeRace + '|' + CodeClasse + '|' + CodeCarriere then
      begin
        CleEquip := CodeRace + '|' + CodeClasse + '|' + CodeCarriere;
        ArgentFixe := False;
        SpinArgent.Value := 0;
        ObjPris.Clear;
      end;
    if GridObjets.RowCount <= 2 then
      begin
        GridObjets.RowCount := ListObjetV1.Count + 1;
        for I := 0 to ListObjetV1.Count - 1 do
          begin
            GridObjets.Cells[0, I + 1] := ListObjetV1[I].Libelle;
            GridObjets.Cells[1, I + 1] := ListObjetV1[I].Categorie;
            GridObjets.Cells[2, I + 1] := ListObjetV1[I].Cout;
          end;
      end;
    AfficheObjetsChoisis();
    PClasse := PClasseDe(CodeClasse);
    Texte := PClasse.Libelle + sLineBreak + PClasse.Equipement + sLineBreak + sLineBreak
             + ChercheMetier(CodeCarriere).Libelle;
    MemoEquip.Lines.Text := Texte;
    AfficheEquipCarriere();
    LabArgent.Caption := GetTexteLibelle('RULES-LAB_694') + ' : ' + PClasse.Argent;
  end;

procedure TCreationV1.AfficheObjetsChoisis();
  var
    I:      Integer;
    PObjet: StructureObjetV1;
  begin
    GridObjPris.RowCount := Max(2, ObjPris.Count + 1);
    GridObjPris.Rows[1].Clear;
    for I := 0 to ObjPris.Count - 1 do
      begin
        PObjet := ChercheObjetV1(ObjPris[I]);
        GridObjPris.Cells[0, I + 1] := PObjet.Libelle;
        GridObjPris.Cells[1, I + 1] := GetTexteLibelle(PObjet.Categorie, PObjet.Categorie);  // mot du livre ou code RULES-V1CAT_*
        GridObjPris.Cells[2, I + 1] := PObjet.Cout;
      end;
  end;

// Double clic dans la liste de prix : l'objet est ajoute (autant d'exemplaires qu'on veut)
procedure TCreationV1.GridObjetsDblClick(Sender: TObject);
  begin
    if (GridObjets.Row < 1) or (GridObjets.Row > ListObjetV1.Count) then Exit;
    ObjPris.Add(ListObjetV1[GridObjets.Row - 1].Code);
    AfficheObjetsChoisis();
  end;

// Double clic sur un objet choisi : on le retire
procedure TCreationV1.GridObjPrisDblClick(Sender: TObject);
  var
    I: Integer;
  begin
    I := GridObjPris.Row - 1;
    if (I < 0) or (I >= ObjPris.Count) then Exit;
    ObjPris.Delete(I);
    AfficheObjetsChoisis();
  end;

// Equipement de depart de la carriere : libelles des objets (choix "A/B" = "A / B"), texte libre tel quel
procedure TCreationV1.AfficheEquipCarriere();
  var
    PEquip:   StructureMetierEquipement;
    Morceaux: TStringList;
    I, J:     Integer;
    Lib:      String;
    PObjet:   StructureObjetV1;
  begin
    LignesCarr.Clear;
    QuantCarr.Clear;
    for PEquip in ListMetierEquipement do
      if CompareRechercheValeur(PEquip.CodeMetier, CodeCarriere) then
        begin
          LignesCarr.Add(PEquip.Equipement);
          if PEquip.QuantiteListe <> '' then
            QuantCarr.Add(PEquip.QuantiteListe)
          else if PEquip.Quantite > 1 then
            QuantCarr.Add(IntToStr(PEquip.Quantite))
          else
            QuantCarr.Add('');
        end;
    GridCarriere.RowCount := Max(2, LignesCarr.Count + 1);
    GridCarriere.Rows[1].Clear;
    Morceaux := TStringList.Create;
    try
      for I := 0 to LignesCarr.Count - 1 do
        begin
          Morceaux.Clear;
          ExtractStrings([SeparateurMulti], [], PChar(LignesCarr[I]), Morceaux);
          Lib := '';
          for J := 0 to Morceaux.Count - 1 do
            begin
              PObjet := ChercheObjetV1(Morceaux[J]);
              if J > 0 then Lib := Lib + ' / ';
              if PObjet.Code <> '' then Lib := Lib + PObjet.Libelle
              else Lib := Lib + Morceaux[J];
            end;
          GridCarriere.Cells[0, I + 1] := Lib;
          GridCarriere.Cells[1, I + 1] := QuantCarr[I];
        end;
    finally
      Morceaux.Free;
    end;
  end;

// Double clic sur une ligne de la carriere : l'objet est pris ; un choix "A/B" ouvre un menu
procedure TCreationV1.GridCarriereDblClick(Sender: TObject);
  var
    I, J:  Integer;
    Item:  TMenuItem;
  begin
    I := GridCarriere.Row - 1;
    if (I < 0) or (I >= LignesCarr.Count) then Exit;
    BranchesMenu.Clear;
    ExtractStrings([SeparateurMulti], [], PChar(LignesCarr[I]), BranchesMenu);
    if BranchesMenu.Count = 0 then Exit;
    for J := 0 to BranchesMenu.Count - 1 do
      if ChercheObjetV1(BranchesMenu[J]).Code = '' then Exit;   // texte libre : rien a prendre
    QuantMenuStr := QuantCarr[I];
    if BranchesMenu.Count = 1 then
      begin
        MenuBr.Items.Clear;
        Item := TMenuItem.Create(MenuBr);
        Item.Tag := 0;
        BrancheClick(Item);
        Item.Free;
        Exit;
      end;
    MenuBr.Items.Clear;
    for J := 0 to BranchesMenu.Count - 1 do
      begin
        Item := TMenuItem.Create(MenuBr);
        Item.Caption := ChercheObjetV1(BranchesMenu[J]).Libelle;
        Item.Tag     := J;
        Item.OnClick := @BrancheClick;
        MenuBr.Items.Add(Item);
      end;
    MenuBr.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;

procedure TCreationV1.BrancheClick(Sender: TObject);
  var
    Branche, N, K: Integer;
  begin
    Branche := (Sender as TMenuItem).Tag;
    if (Branche < 0) or (Branche >= BranchesMenu.Count) then Exit;
    N := QuantiteDeBranche(QuantMenuStr, Branche);
    for K := 1 to N do
      ObjPris.Add(BranchesMenu[Branche]);
    AfficheObjetsChoisis();
  end;

procedure TCreationV1.ObjetsChoisis(Codes: TStringList);
  begin
    Codes.AddStrings(ObjPris);
  end;

// Hasard : la formule du livre ("3D6 Gold Crowns")
procedure TCreationV1.TirerArgentClick(Sender: TObject);
  var
    Formule: String;
  begin
    Formule := Trim(PClasseDe(CodeClasse).Argent);
    if Pos(' ', Formule) > 0 then
      Formule := Copy(Formule, 1, Pos(' ', Formule) - 1);
    SpinArgent.Value := LanceFormule(Formule, False);
    ArgentFixe := True;
    Change();
  end;

procedure TCreationV1.SpinArgentChange(Sender: TObject);
  begin
    ArgentFixe := True;
    Change();
  end;

function TCreationV1.EquipementComplet(): Boolean;
  begin
    Result := ArgentFixe;
  end;

function TCreationV1.ArgentDepart(): Integer;
  begin
    Result := SpinArgent.Value;
  end;

// Codes des competences de la carriere de base, plus celles du metier de l'Artisan s'il y en a un
procedure TCreationV1.CompetencesCarriere(Codes: TStringList);
  var
    PMetierComp: StructureMetierCompetence;
    PArtisan:    StructureArtisanMetier;
    Liste:       TStringList;
    I:           Integer;
  begin
    for PMetierComp in ListMetierCompetence do
      if CompareRechercheValeur(PMetierComp.CodeMetier, CodeCarriere) then
        Codes.Add(PMetierComp.CodeCompetence);
    if CodeArtisan = '' then Exit;
    for PArtisan in ListArtisanMetier do
      if PArtisan.CodeMetier = CodeArtisan then
        begin
          Liste := TStringList.Create;
          try
            ExtractStrings([','], [' '], PChar(PArtisan.Competences), Liste);
            for I := 0 to Liste.Count - 1 do
              if Codes.IndexOf(Liste[I]) < 0 then
                Codes.Add(Liste[I]);
          finally
            Liste.Free;
          end;
        end;
  end;

end.

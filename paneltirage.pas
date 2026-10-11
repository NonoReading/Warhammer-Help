unit PanelTirage;

{$mode ObjFPC}{$H+}

// Matrice editable d'une table de tirage de talents (DATA_RANDOM_TALENT), comme dans le livre papier :
// une ligne par talent, une colonne par ethnie du livre (plus la colonne generique "x", table par defaut
// du Rulebook). Cellule = nombre de tirages (poids V4, "3") ou fourchette (V5, "04-06") ; vide = absent du
// XML. Les talents et les ethnies s'affichent par leur libelle, le XML garde les codes
// (CONTEXT.md 2.107).
//
// Usage : creer, Initialiser, poser (Parent + SetBounds), puis Charger(Chapitre) a l'ouverture de la fiche
// et Controler puis Ecrire(Chapitre) a la validation. Chapitre = l'element DATA_RANDOM_TALENT du livre
// (celui qui contient les blocs <DATA_RANDOM_TALENT id=talent>).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, Graphics, DOM, BCButton,
  ChargeConstantes, ChargeTexte, UnitCalcul, GlobalFonts;

type
  // code (de talent ou d'ethnie) -> libelle affiche
  TFonctionLibelleTirage = function(Code: String): String of object;

  TPanelTirageTalent = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FLibTalent, FLibEthnie: TFonctionLibelleTirage;
    FTalentsLib: TStringList;   // talents proposes, libelle affiche ; parallele a FTalentsCode
    FTalentsCode: TStringList;
    FEthnieCodes: TStringList;  // code de l'ethnie de chaque colonne (colonne 1 + index) ; "-x" = table generique
    FNbColonnesInit: Integer;   // colonnes posees par Initialiser (les suivantes viennent du XML charge)
    function  CodeTalentDe(const Lib: String): String;
    function  LibelleTalent(const Code: String): String;
    function  ColonneDe(const Code: String): Integer;
    function  AjouterColonne(const Code: String): Integer;
    function  LigneDe(const Code: String): Integer;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
    procedure GrillePrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    function  DerniereLigne: Integer;  // derniere ligne de talent (la ligne Total est apres)
    procedure RecalculerTotaux;
    function  TotalColonne(C: Integer; out Vide: Boolean): Integer;
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonValiderClick(Sender: TObject);
    procedure BoutonAnnulerClick(Sender: TObject);
    function  GetLectureSeule: Boolean;
    procedure SetLectureSeule(Valeur: Boolean);
    function  GetNbLignes: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Modele : bouton dont les boutons du panneau copient l'aspect (une seule fois, a la creation).
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger. LibTalent/LibEthnie : libelle d'un code. Talents : codes des talents
    // que le choix d'une ligne propose. Ethnies : codes des ethnies du livre ouvert, une colonne chacune
    // (la colonne generique "-x" est toujours ajoutee en premier).
    procedure Configurer(ALibTalent, ALibEthnie: TFonctionLibelleTirage; Talents, Ethnies: TStrings);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque cellule est un nombre ou une fourchette, sans melange dans une colonne, et si aucun
    // talent n'est vide ou en double ; sinon message nommant la ligne ou la colonne (a appeler avant Ecrire).
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;  // contenu des cellules, pour detecter une modification
    procedure ActiverBoutons(Actif: Boolean);  // Valider et Annuler ne servent qu'une fois quelque chose modifie
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
    property  NbLignes: Integer read GetNbLignes;  // sans l'en-tete
  end;

  // Matrice editable de la table de tirage de race (DATA_RANDOM_SPECIE) : une ligne par race, avec le debut
  // et la fin de sa fourchette du d100. Le XML garde les codes ("01-90", ou "99" pour une valeur seule).
  // Table complete obligatoire : 1 a 100 sans trou ni chevauchement (CONTEXT.md 2.107).
  TPanelTirageRace = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FLibRace: TFonctionLibelleTirage;
    FRacesLib: TStringList;   // races proposees, libelle affiche ; parallele a FRacesCode
    FRacesCode: TStringList;
    function  LibelleRace(const Code: String): String;
    function  CodeRaceDe(const Lib: String): String;
    function  DerniereLigne: Integer;  // derniere ligne de race (la ligne Total est apres)
    procedure TrierLignes;
    procedure RecalculerTotal;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
    procedure GrillePrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonValiderClick(Sender: TObject);
    procedure BoutonAnnulerClick(Sender: TObject);
    function  GetLectureSeule: Boolean;
    procedure SetLectureSeule(Valeur: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger. ALibRace : libelle d'un code. Races : codes que le choix d'une ligne propose.
    procedure Configurer(ALibRace: TFonctionLibelleTirage; Races: TStrings);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque ligne a une race (sans doublon) et une fourchette valide, et si les fourchettes couvrent
    // 1 a 100 sans trou ni chevauchement ; sinon message nommant la race (a appeler avant Ecrire).
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

  // Matrice editable du tirage des metiers d'une regle (DATA_CAREER_ROLL) : une ligne par metier, une colonne
  // par ethnie ou race, cellule = Chance (largeur de la fourchette du d100). Une table par regle, choisie dans
  // la liste du haut. Le total d'une colonne s'affiche en vert a 100 mais n'est pas impose : une regle
  // PARTIELLE (Sea of Claws) ne surcharge qu'une section de la table (CONTEXT.md 2.107).
  TPanelTirageMetier = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre, FBarre2, FBarre3: TPanel;
    FEtiquetteRegle, FEtiquetteClasse: TLabel;
    FComboRegle, FComboColonne, FComboClasse: TComboBox;
    FBoutonAjouter, FBoutonRetirer, FBoutonColonne, FBoutonRetirerColonne, FBoutonValider, FBoutonAnnuler: TBCButton;
    FBoutonNouvelleRegle, FBoutonSupprimerRegle, FBoutonRenommerRegle: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FLibMetier, FLibColonne, FLibRegle, FLibClasse: TFonctionLibelleTirage;
    FMetiersLib, FMetiersCode: TStringList;      // metiers proposes (libelle / code, paralleles)
    FColonnesLib, FColonnesCode: TStringList;    // ethnies et races proposees pour une nouvelle colonne
    FReglesLib, FReglesCode: TStringList;        // regles du livre (libelle / code)
    FReglesClasse: TStringList;      // classe remplacee de chaque regle (parallele a FReglesCode, vide = regle totale)
    FReglesInitiales: TStringList;   // regles declarees (DATA_RULE) a l'ouverture : celles retirees seront supprimees du XML
    FReglesNouvelles: TStringList;   // regles creees depuis l'ouverture, "code=libelle"
    FReglesRenommees: TStringList;   // regles declarees renommees depuis l'ouverture, "code=libelle"
    FClassesCode: TStringList;       // classes proposees pour une regle partielle
    FPrefixe: String;                // code du livre, prefixe des nouvelles regles
    FParRegle: TStringList;     // code de regle -> Objects = TStringList de lignes "colonne"#9"metier"#9"chance"
    FRegle: String;             // regle affichee dans la grille
    FColCodes: TStringList;     // code de la colonne de chaque colonne de la grille (colonne 1 + index)
    FGrilleModifiee: Boolean;   // la grille a change depuis son affichage (sinon inutile de la ranger)
    function  LibelleMetier(const Code: String): String;
    function  CodeMetierDe(const Lib: String): String;
    function  LibelleColonne(const Code: String): String;
    function  CodeColonneDe(const Lib: String): String;
    function  LibelleRegle(const Code: String): String;
    function  LignesDeRegle(const Code: String): TStringList;
    procedure ViderRegles;
    procedure AfficherRegle(const Code: String);
    procedure RangerRegle;
    function  AjouterColonneGrille(const Code: String): Integer;
    function  DerniereLigne: Integer;
    procedure RecalculerTotaux;
    procedure ComboRegleChange(Sender: TObject);
    procedure ComboClasseChange(Sender: TObject);
    procedure SynchroClasse;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
    procedure GrillePrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonColonneClick(Sender: TObject);
    procedure BoutonRetirerColonneClick(Sender: TObject);
    procedure BoutonNouvelleRegleClick(Sender: TObject);
    procedure BoutonSupprimerRegleClick(Sender: TObject);
    procedure BoutonRenommerRegleClick(Sender: TObject);
    procedure BoutonValiderClick(Sender: TObject);
    procedure BoutonAnnulerClick(Sender: TObject);
    function  GetLectureSeule: Boolean;
    procedure SetLectureSeule(Valeur: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    // Classes proposees pour une regle partielle (codes, libelle par ALib) et code du livre ouvert (prefixe
    // des nouvelles regles) ; a appeler apres Configurer.
    procedure ConfigurerClasses(ALib: TFonctionLibelleTirage; Classes: TStrings; const Prefixe: String);
    // Declare une regle deja ecrite dans DATA_RULE du livre, avec sa classe remplacee (vide = regle totale).
    procedure DeclarerRegle(const Code, Classe: String);
    // Reporte dans DATA_RULE les regles creees, supprimees ou dont la classe a change (a appeler apres Ecrire).
    procedure EcrireRegles(Chapitre: TDOMElement; const Langue: String);
    // Vrai si des regles ont ete creees : DATA_RULE doit alors exister.
    function  ReglesACreer: Boolean;
    // A appeler avant chaque Charger. Metiers : codes proposes pour une ligne ; Colonnes : ethnies et races
    // proposees pour une nouvelle colonne ; Regles : regles du livre ouvert.
    procedure Configurer(ALibMetier, ALibColonne, ALibRegle: TFonctionLibelleTirage; Metiers, Colonnes, Regles: TStrings);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque cellule remplie a un metier et une chance entiere positive, sans metier en double dans
    // une colonne ; sinon message nommant la regle et la colonne (a appeler avant Ecrire).
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

const
  CodeEthniqueGenerique = '-x';  // <Specie>"-x" : table generique du Rulebook (ConstCodeRaceCreationGenerique)

implementation

// Fin d'une fourchette : le d100 des tables V5 s'ecrit "00" (98-00 = 98 a 100).
function BorneFin(const T: String): Integer;
begin
  if (T <> '') and (StrToIntDef(T, -1) = 0) then
    Result := 100
  else
    Result := StrToIntDef(T, 0);
end;

// Une cellule est un nombre ("3") ou une fourchette ("04-06"), rien d'autre.
function CelluleValide(const S: String; out Fourchette: Boolean): Boolean;
var
  P, A, B: Integer;
begin
  Fourchette := Pos('-', S) > 0;
  if not Fourchette then
  begin
    A := StrToIntDef(S, 0);
    Exit(A > 0);
  end;
  P := Pos('-', S);
  A := StrToIntDef(Copy(S, 1, P - 1), 0);
  B := BorneFin(Copy(S, P + 1, MaxInt));
  Result := (A > 0) and (B >= A);
end;

{ TPanelTirageTalent }

constructor TPanelTirageTalent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTalentsLib := TStringList.Create;
  FTalentsCode := TStringList.Create;
  FEthnieCodes := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;  // en haut : toujours visible, meme si le bas du panneau depasse la fenetre
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 1;
  FGrille.RowCount := 2;  // en-tete + ligne Total (toujours la derniere)
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;  // la colonne des talents est une colonne ordinaire (une colonne fixe s'affichait noir sur noir)
  FGrille.Options := FGrille.Options + [goEditing, goRowSelect] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.OnSelectCell := @GrilleSelectCell;
  FGrille.OnSetEditText := @GrilleSetEditText;
  FGrille.OnPrepareCanvas := @GrillePrepareCanvas;
  Visible := False;
end;

destructor TPanelTirageTalent.Destroy;
begin
  FTalentsLib.Free;
  FTalentsCode.Free;
  FEthnieCodes.Free;
  inherited Destroy;
end;

procedure TPanelTirageTalent.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_512', 'Add a line');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonAjouter.SetBounds(0, 0, 230, 50);
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonRetirer.SetBounds(240, 0, 250, 50);
  FBoutonValider := TBCButtonContour.Create(Self);
  FBoutonValider.Assign(Modele);
  FBoutonValider.Parent := FBarre;
  FBoutonValider.Caption := GetTexteLibelle('RULES-LAB_086');
  FBoutonValider.OnClick := @BoutonValiderClick;
  FBoutonValider.SetBounds(500, 0, 150, 50);
  FBoutonAnnuler := TBCButtonContour.Create(Self);
  FBoutonAnnuler.Assign(Modele);
  FBoutonAnnuler.Parent := FBarre;
  FBoutonAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  FBoutonAnnuler.OnClick := @BoutonAnnulerClick;
  FBoutonAnnuler.SetBounds(660, 0, 150, 50);
  ActiverBoutons(False);
  // les composants du panneau lui appartiennent : la fiche ne leur applique pas sa mise en forme
  // (police, couleurs, boutons), il faut donc l'appliquer ici (comme TPanelModificateurs).
  MiseAJourUnContenaire(Self);
end;

procedure TPanelTirageTalent.Configurer(ALibTalent, ALibEthnie: TFonctionLibelleTirage; Talents, Ethnies: TStrings);
var
  I: Integer;
begin
  FLibTalent := ALibTalent;
  FLibEthnie := ALibEthnie;
  FTalentsLib.Clear;
  FTalentsCode.Clear;
  for I := 0 to Talents.Count - 1 do
    LibelleTalent(Talents[I]);
  // colonnes : talent, generique, puis les ethnies du livre
  FEthnieCodes.Clear;
  FGrille.ColCount := 1;
  AjouterColonne(CodeEthniqueGenerique);
  for I := 0 to Ethnies.Count - 1 do
    if ColonneDe(Ethnies[I]) = 0 then
      AjouterColonne(Ethnies[I]);
  FGrille.ColWidths[0] := 260;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_007');
  FNbColonnesInit := FEthnieCodes.Count;
end;

// Libelle du talent dans la grille ; deux talents de meme libelle se distinguent par leur code.
function TPanelTirageTalent.LibelleTalent(const Code: String): String;
var
  I: Integer;
begin
  I := FTalentsCode.IndexOf(Code);
  if I >= 0 then Exit(FTalentsLib[I]);
  Result := FLibTalent(Code);
  if FTalentsLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FTalentsLib.Add(Result);
  FTalentsCode.Add(Code);
end;

function TPanelTirageTalent.CodeTalentDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FTalentsLib.IndexOf(Lib);
  if I >= 0 then Result := FTalentsCode[I];
end;

// Numero de colonne de la grille pour une ethnie (0 si elle n'en a pas).
function TPanelTirageTalent.ColonneDe(const Code: String): Integer;
var
  I: Integer;
begin
  I := FEthnieCodes.IndexOf(Code);
  if I < 0 then Result := 0 else Result := I + 1;
end;

function TPanelTirageTalent.AjouterColonne(const Code: String): Integer;
begin
  FEthnieCodes.Add(Code);
  Result := FEthnieCodes.Count;
  FGrille.ColCount := Result + 1;
  if Code = CodeEthniqueGenerique then
    FGrille.Cells[Result, 0] := 'x'
  else
    FGrille.Cells[Result, 0] := FLibEthnie(Code);
  FGrille.ColWidths[Result] := 90;
end;

// Numero de ligne de la grille pour un talent (0 si absent).
function TPanelTirageTalent.LigneDe(const Code: String): Integer;
var
  R: Integer;
begin
  Result := 0;
  for R := 1 to DerniereLigne do
    if CodeTalentDe(FGrille.Cells[0, R]) = Code then
      Exit(R);
end;

procedure TPanelTirageTalent.Charger(Chapitre: TDOMElement);
var
  Bloc, Enfant: TDOMNode;
  CodeTalent, CodeEthnie, Valeur: String;
  R, C: Integer;
begin
  FGrille.EditorMode := False;
  // repart des colonnes de Initialiser : retire les colonnes ajoutees par un chargement precedent
  while FEthnieCodes.Count > FNbColonnesInit do
    FEthnieCodes.Delete(FEthnieCodes.Count - 1);
  FGrille.ColCount := FEthnieCodes.Count + 1;
  FGrille.RowCount := 2;
  FGrille.Rows[1].Clear;
  FGrille.Cells[0, 1] := GetTexteLibelle('RULES-LAB_510', 'Total');
  if Chapitre = nil then
  begin
    RecalculerTotaux;
    Exit;
  end;
  Bloc := Chapitre.FirstChild;
  while Bloc <> nil do
  begin
    if (Bloc.NodeType = ELEMENT_NODE) and (Bloc.NodeName = 'DATA_RANDOM_TALENT') then
    begin
      CodeTalent := TDOMElement(Bloc).GetAttribute('id');
      CodeEthnie := '';
      Valeur := '';
      Enfant := Bloc.FirstChild;
      while Enfant <> nil do
      begin
        if Enfant.NodeType = ELEMENT_NODE then
        begin
          if Enfant.NodeName = 'Specie' then
            CodeEthnie := RemoveQuotes(Trim(Enfant.TextContent))
          else if Enfant.NodeName = 'Talent' then
            Valeur := RemoveQuotes(Trim(Enfant.TextContent));
        end;
        Enfant := Enfant.NextSibling;
      end;
      if (CodeTalent <> '') and (CodeEthnie <> '') and (Valeur <> '') then
      begin
        // une ethnie citee par le XML mais absente des colonnes ne doit pas se perdre a l'ecriture
        C := ColonneDe(CodeEthnie);
        if C = 0 then C := AjouterColonne(CodeEthnie);
        R := LigneDe(CodeTalent);
        if R = 0 then
        begin
          R := FGrille.RowCount - 1;
          FGrille.InsertColRow(False, R);  // avant la ligne Total
          FGrille.Cells[0, R] := LibelleTalent(CodeTalent);  // un talent hors liste propose y est ajoute
        end;
        FGrille.Cells[C, R] := Valeur;
      end;
    end;
    Bloc := Bloc.NextSibling;
  end;
  RecalculerTotaux;
end;

procedure TPanelTirageTalent.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  Bloc, E: TDOMElement;
  R, C: Integer;
  CodeTalent, Valeur: String;
begin
  FGrille.EditorMode := False;
  Doc := Chapitre.OwnerDocument;
  while Chapitre.FirstChild <> nil do
    Chapitre.RemoveChild(Chapitre.FirstChild);
  for R := 1 to DerniereLigne do
  begin
    CodeTalent := CodeTalentDe(FGrille.Cells[0, R]);
    if CodeTalent = '' then Continue;
    for C := 1 to FGrille.ColCount - 1 do
    begin
      Valeur := Trim(FGrille.Cells[C, R]);
      if Valeur = '' then Continue;
      Bloc := Doc.CreateElement('DATA_RANDOM_TALENT');
      Bloc.SetAttribute('id', CodeTalent);
      E := Doc.CreateElement('Specie');
      E.AppendChild(Doc.CreateTextNode('"' + FEthnieCodes[C - 1] + '"'));
      Bloc.AppendChild(E);
      E := Doc.CreateElement('Talent');
      E.SetAttribute('name', CodeTalent);
      E.AppendChild(Doc.CreateTextNode('"' + Valeur + '"'));
      Bloc.AppendChild(E);
      Bloc.AppendChild(Doc.CreateComment('  ' + FGrille.Cells[0, R] + '  '));
      Chapitre.AppendChild(Bloc);
    end;
  end;
end;

function TPanelTirageTalent.Controler: Boolean;
var
  R, C, R2: Integer;
  Valeur, Code: String;
  Fourchette, AFourchette, APoids, Vide: Boolean;
  Somme: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to DerniereLigne do
  begin
    Code := CodeTalentDe(Trim(FGrille.Cells[0, R]));
    if Code = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_506', 'Line %d: choose a talent.'), [R]));
      Exit(False);
    end;
    for R2 := 1 to R - 1 do
      if CodeTalentDe(Trim(FGrille.Cells[0, R2])) = Code then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_507', 'Lines %d and %d are the same talent.'), [R2, R]));
        Exit(False);
      end;
    for C := 1 to FGrille.ColCount - 1 do
    begin
      Valeur := Trim(FGrille.Cells[C, R]);
      if (Valeur <> '') and (not CelluleValide(Valeur, Fourchette)) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_508', 'Line %d, column %s: "%s" is neither a number nor a range (04-06).'),
          [R, FGrille.Cells[C, 0], Valeur]));
        Exit(False);
      end;
    end;
  end;
  // CalculeTirageTalent lit une table en fourchettes des qu'un tiret apparait : une colonne ne melange pas
  for C := 1 to FGrille.ColCount - 1 do
  begin
    AFourchette := False;
    APoids := False;
    for R := 1 to DerniereLigne do
    begin
      Valeur := Trim(FGrille.Cells[C, R]);
      if Valeur = '' then Continue;
      if Pos('-', Valeur) > 0 then AFourchette := True else APoids := True;
    end;
    if AFourchette and APoids then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_509', 'Column %s mixes weights and ranges: use one or the other.'),
        [FGrille.Cells[C, 0]]));
      Exit(False);
    end;
    // une table de tirage est vide (colonne sans talent) ou complete : le d100 est entierement reparti
    Somme := TotalColonne(C, Vide);
    if (not Vide) and (Somme <> 100) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_511', 'Column %s totals %d: it must be empty or total 100.'),
        [FGrille.Cells[C, 0], Somme]));
      Exit(False);
    end;
  end;
end;

function TPanelTirageTalent.DerniereLigne: Integer;
begin
  Result := FGrille.RowCount - 2;
end;

// La ligne Total n'est pas modifiable : on ne peut pas s'y placer.
procedure TPanelTirageTalent.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if aRow > DerniereLigne then CanSelect := False;
end;

procedure TPanelTirageTalent.GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
begin
  RecalculerTotaux;
end;

// Ligne Total en gras ; un total de 100 s'affiche en vert (la table est complete).
procedure TPanelTirageTalent.GrillePrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
begin
  if aRow <= DerniereLigne then Exit;
  FGrille.Canvas.Font.Style := [fsBold];
  if (aCol >= 1) and (FGrille.Cells[aCol, aRow] = '100') then
    FGrille.Canvas.Font.Color := clGreen;
end;

// Total d'une colonne : somme des poids ("3"), ou des largeurs des fourchettes ("04-06" = 3) ; une cellule
// invalide ne compte pas (Controler la refuse). Vide = aucune cellule remplie.
function TPanelTirageTalent.TotalColonne(C: Integer; out Vide: Boolean): Integer;
var
  R, A, B, P: Integer;
  Valeur: String;
begin
  Result := 0;
  Vide := True;
  for R := 1 to DerniereLigne do
  begin
    Valeur := Trim(FGrille.Cells[C, R]);
    if Valeur = '' then Continue;
    Vide := False;
    P := Pos('-', Valeur);
    if P > 0 then
    begin
      A := StrToIntDef(Copy(Valeur, 1, P - 1), 0);
      B := BorneFin(Copy(Valeur, P + 1, MaxInt));
      if (A > 0) and (B >= A) then Result := Result + B - A + 1;
    end
    else
      Result := Result + StrToIntDef(Valeur, 0);
  end;
end;

procedure TPanelTirageTalent.RecalculerTotaux;
var
  C: Integer;
  Vide: Boolean;
  Somme: Integer;
begin
  for C := 1 to FGrille.ColCount - 1 do
  begin
    Somme := TotalColonne(C, Vide);
    if Vide then
      FGrille.Cells[C, FGrille.RowCount - 1] := ''
    else
      FGrille.Cells[C, FGrille.RowCount - 1] := IntToStr(Somme);
  end;
end;

procedure TPanelTirageTalent.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  // colonne du talent : liste de choix ; les autres colonnes restent une saisie libre
  if (aCol <> 0) or (aRow < 1) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FTalentsLib);
end;

procedure TPanelTirageTalent.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount - 1;
  FGrille.InsertColRow(False, R);  // avant la ligne Total
  FGrille.Row := R;
  FGrille.Col := 0;
end;

procedure TPanelTirageTalent.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelTirageTalent.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelTirageTalent.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

procedure TPanelTirageTalent.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row <= DerniereLigne) then
  begin
    FGrille.DeleteRow(FGrille.Row);
    RecalculerTotaux;
  end;
end;

function TPanelTirageTalent.GetLectureSeule: Boolean;
begin
  Result := not (goEditing in FGrille.Options);
end;

// En lecture : grille non modifiable et sans boutons.
procedure TPanelTirageTalent.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
  begin
    FGrille.Options := FGrille.Options - [goEditing];
    FBarre.Visible := False;
  end
  else
  begin
    FGrille.Options := FGrille.Options + [goEditing];
    FBarre.Visible := True;
  end;
end;

function TPanelTirageTalent.GetNbLignes: Integer;
begin
  Result := DerniereLigne;
end;

procedure TPanelTirageTalent.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelTirageTalent.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

{ TPanelTirageRace }

constructor TPanelTirageRace.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRacesLib := TStringList.Create;
  FRacesCode := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 3;
  FGrille.RowCount := 2;  // en-tete + ligne Total (toujours la derniere)
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing, goRowSelect] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.OnSelectCell := @GrilleSelectCell;
  FGrille.OnSetEditText := @GrilleSetEditText;
  FGrille.OnPrepareCanvas := @GrillePrepareCanvas;
  Visible := False;
end;

destructor TPanelTirageRace.Destroy;
begin
  FRacesLib.Free;
  FRacesCode.Free;
  inherited Destroy;
end;

procedure TPanelTirageRace.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_512', 'Add a line');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonAjouter.SetBounds(0, 0, 230, 50);
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonRetirer.SetBounds(240, 0, 250, 50);
  FBoutonValider := TBCButtonContour.Create(Self);
  FBoutonValider.Assign(Modele);
  FBoutonValider.Parent := FBarre;
  FBoutonValider.Caption := GetTexteLibelle('RULES-LAB_086');
  FBoutonValider.OnClick := @BoutonValiderClick;
  FBoutonValider.SetBounds(500, 0, 150, 50);
  FBoutonAnnuler := TBCButtonContour.Create(Self);
  FBoutonAnnuler.Assign(Modele);
  FBoutonAnnuler.Parent := FBarre;
  FBoutonAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  FBoutonAnnuler.OnClick := @BoutonAnnulerClick;
  FBoutonAnnuler.SetBounds(660, 0, 150, 50);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

procedure TPanelTirageRace.Configurer(ALibRace: TFonctionLibelleTirage; Races: TStrings);
var
  I: Integer;
begin
  FLibRace := ALibRace;
  FRacesLib.Clear;
  FRacesCode.Clear;
  for I := 0 to Races.Count - 1 do
    LibelleRace(Races[I]);
  FGrille.ColWidths[0] := 260;
  FGrille.ColWidths[1] := 90;
  FGrille.ColWidths[2] := 90;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_042');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_141');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_142');
end;

// Libelle de la race dans la grille ; deux races de meme libelle se distinguent par leur code.
function TPanelTirageRace.LibelleRace(const Code: String): String;
var
  I: Integer;
begin
  I := FRacesCode.IndexOf(Code);
  if I >= 0 then Exit(FRacesLib[I]);
  Result := FLibRace(Code);
  if FRacesLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FRacesLib.Add(Result);
  FRacesCode.Add(Code);
end;

function TPanelTirageRace.CodeRaceDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FRacesLib.IndexOf(Lib);
  if I >= 0 then Result := FRacesCode[I];
end;

function TPanelTirageRace.DerniereLigne: Integer;
begin
  Result := FGrille.RowCount - 2;
end;

// Lignes par debut croissant (ordre de lecture du d100) ; un debut illisible passe en tete.
procedure TPanelTirageRace.TrierLignes;
var
  Cles: TStringList;
  R: Integer;
  L: String;
begin
  Cles := TStringList.Create;
  try
    for R := 1 to DerniereLigne do
      Cles.Add(Format('%.4d|%.4d|%s|%s|%s', [StrToIntDef(Trim(FGrille.Cells[1, R]), 0), R,
        FGrille.Cells[0, R], FGrille.Cells[1, R], FGrille.Cells[2, R]]));
    Cles.Sort;
    for R := 1 to Cles.Count do
    begin
      L := Cles[R - 1];
      Delete(L, 1, Pos('|', L));
      Delete(L, 1, Pos('|', L));
      FGrille.Cells[0, R] := Copy(L, 1, Pos('|', L) - 1);
      Delete(L, 1, Pos('|', L));
      FGrille.Cells[1, R] := Copy(L, 1, Pos('|', L) - 1);
      Delete(L, 1, Pos('|', L));
      FGrille.Cells[2, R] := L;
    end;
  finally
    Cles.Free;
  end;
end;

procedure TPanelTirageRace.Charger(Chapitre: TDOMElement);
var
  E: TDOMNode;
  Code, Plage: String;
  P, R: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 2;
  FGrille.Rows[1].Clear;
  FGrille.Cells[0, 1] := GetTexteLibelle('RULES-LAB_510', 'Total');
  if Chapitre <> nil then
  begin
    E := Chapitre.FirstChild;
    while E <> nil do
    begin
      if (E.NodeType = ELEMENT_NODE) and (E.NodeName = 'Specie') then
      begin
        Code := TDOMElement(E).GetAttribute('name');
        Plage := RemoveQuotes(Trim(E.TextContent));
        if (Code <> '') and (Plage <> '') then
        begin
          R := FGrille.RowCount - 1;
          FGrille.InsertColRow(False, R);  // avant la ligne Total
          FGrille.Cells[0, R] := LibelleRace(Code);  // une race hors liste proposee y est ajoutee
          P := Pos('-', Plage);
          if P > 0 then
          begin
            FGrille.Cells[1, R] := Trim(Copy(Plage, 1, P - 1));
            FGrille.Cells[2, R] := Trim(Copy(Plage, P + 1, MaxInt));
          end
          else
          begin
            FGrille.Cells[1, R] := Plage;  // valeur unique : meme debut et meme fin
            FGrille.Cells[2, R] := Plage;
          end;
        end;
      end;
      E := E.NextSibling;
    end;
  end;
  TrierLignes;
  RecalculerTotal;
end;

procedure TPanelTirageRace.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  E: TDOMElement;
  R, Debut, Fin: Integer;
  Plage: String;
begin
  FGrille.EditorMode := False;
  Doc := Chapitre.OwnerDocument;
  while Chapitre.FirstChild <> nil do
    Chapitre.RemoveChild(Chapitre.FirstChild);
  TrierLignes;
  for R := 1 to DerniereLigne do
  begin
    Debut := StrToIntDef(Trim(FGrille.Cells[1, R]), 0);
    Fin := BorneFin(Trim(FGrille.Cells[2, R]));
    if Debut = Fin then
      Plage := Format('%.2d', [Debut])
    else
      Plage := Format('%.2d-%.2d', [Debut, Fin]);
    E := Doc.CreateElement('Specie');
    E.SetAttribute('name', CodeRaceDe(FGrille.Cells[0, R]));
    E.AppendChild(Doc.CreateTextNode('"' + Plage + '"'));
    Chapitre.AppendChild(E);
  end;
end;

function TPanelTirageRace.Controler: Boolean;
var
  R, R2, Debut, Fin, Attendu: Integer;
  Code: String;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to DerniereLigne do
  begin
    Code := CodeRaceDe(Trim(FGrille.Cells[0, R]));
    if Code = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_513', 'Line %d: choose a race.'), [R]));
      Exit(False);
    end;
    for R2 := 1 to R - 1 do
      if CodeRaceDe(Trim(FGrille.Cells[0, R2])) = Code then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_514', 'Lines %d and %d are the same race.'), [R2, R]));
        Exit(False);
      end;
    Debut := StrToIntDef(Trim(FGrille.Cells[1, R]), 0);
    Fin := BorneFin(Trim(FGrille.Cells[2, R]));
    if (Debut < 1) or (Fin > 100) or (Fin < Debut) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_515',
        '%s: start and end must be numbers from 1 to 100, the start no greater than the end.'),
        [FGrille.Cells[0, R]]));
      Exit(False);
    end;
  end;
  // une fourchette commence juste apres la fin de la precedente : ni trou ni chevauchement
  TrierLignes;
  Attendu := 1;
  for R := 1 to DerniereLigne do
  begin
    Debut := StrToIntDef(Trim(FGrille.Cells[1, R]), 0);
    if Debut <> Attendu then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_516',
        '%s: the range must start at %d (no gap, no overlap).'), [FGrille.Cells[0, R], Attendu]));
      Exit(False);
    end;
    Attendu := BorneFin(Trim(FGrille.Cells[2, R])) + 1;
  end;
  if (DerniereLigne >= 1) and (Attendu <> 101) then
  begin
    ShowMessage(Format(GetTexteLibelle('RULES-LAB_517', 'The table must reach 100: it ends at %d.'), [Attendu - 1]));
    Exit(False);
  end;
end;

// La ligne Total n'est pas modifiable : on ne peut pas s'y placer.
procedure TPanelTirageRace.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if aRow > DerniereLigne then CanSelect := False;
end;

procedure TPanelTirageRace.GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
begin
  RecalculerTotal;
end;

// Ligne Total en gras ; un total de 100 s'affiche en vert (la table est complete).
procedure TPanelTirageRace.GrillePrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
begin
  if aRow <= DerniereLigne then Exit;
  FGrille.Canvas.Font.Style := [fsBold];
  if (aCol = 2) and (FGrille.Cells[aCol, aRow] = '100') then
    FGrille.Canvas.Font.Color := clGreen;
end;

// Total : somme des largeurs des fourchettes valides (colonne Fin de la ligne Total) ; vide si aucune ligne.
procedure TPanelTirageRace.RecalculerTotal;
var
  R, Debut, Fin, Somme: Integer;
begin
  Somme := 0;
  for R := 1 to DerniereLigne do
  begin
    Debut := StrToIntDef(Trim(FGrille.Cells[1, R]), 0);
    Fin := BorneFin(Trim(FGrille.Cells[2, R]));
    if (Debut >= 1) and (Fin >= Debut) then Somme := Somme + Fin - Debut + 1;
  end;
  if DerniereLigne < 1 then
    FGrille.Cells[2, FGrille.RowCount - 1] := ''
  else
    FGrille.Cells[2, FGrille.RowCount - 1] := IntToStr(Somme);
end;

procedure TPanelTirageRace.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  // colonne de la race : liste de choix ; le debut et la fin restent une saisie libre
  if (aCol <> 0) or (aRow < 1) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FRacesLib);
end;

procedure TPanelTirageRace.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount - 1;
  FGrille.InsertColRow(False, R);  // avant la ligne Total
  FGrille.Row := R;
  FGrille.Col := 0;
end;

procedure TPanelTirageRace.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row <= DerniereLigne) then
  begin
    FGrille.DeleteRow(FGrille.Row);
    RecalculerTotal;
  end;
end;

procedure TPanelTirageRace.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelTirageRace.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelTirageRace.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelTirageRace.GetLectureSeule: Boolean;
begin
  Result := not (goEditing in FGrille.Options);
end;

// En lecture : grille non modifiable et sans boutons.
procedure TPanelTirageRace.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
  begin
    FGrille.Options := FGrille.Options - [goEditing];
    FBarre.Visible := False;
  end
  else
  begin
    FGrille.Options := FGrille.Options + [goEditing];
    FBarre.Visible := True;
  end;
end;

procedure TPanelTirageRace.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelTirageRace.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

{ TPanelTirageMetier }

constructor TPanelTirageMetier.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMetiersLib := TStringList.Create;
  FMetiersCode := TStringList.Create;
  FColonnesLib := TStringList.Create;
  FColonnesCode := TStringList.Create;
  FReglesLib := TStringList.Create;
  FReglesCode := TStringList.Create;
  FReglesClasse := TStringList.Create;
  FReglesInitiales := TStringList.Create;
  FReglesNouvelles := TStringList.Create;
  FReglesRenommees := TStringList.Create;
  FClassesCode := TStringList.Create;
  FParRegle := TStringList.Create;
  FColCodes := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FBarre2 := TPanel.Create(Self);
  FBarre2.Parent := Self;
  FBarre2.Align := alTop;
  FBarre2.BevelOuter := bvNone;
  FBarre2.Caption := '';
  FBarre2.Height := 50;
  FBarre3 := TPanel.Create(Self);
  FBarre3.Parent := Self;
  FBarre3.Align := alTop;
  FBarre3.BevelOuter := bvNone;
  FBarre3.Caption := '';
  FBarre3.Height := 50;
  FEtiquetteClasse := TLabelContour.Create(Self);
  FEtiquetteClasse.Parent := FBarre3;
  FEtiquetteClasse.SetBounds(750, 16, 150, 20);
  FComboClasse := TComboBox.Create(Self);
  FComboClasse.Parent := FBarre3;
  FComboClasse.Style := csDropDownList;
  FComboClasse.SetBounds(910, 10, 330, 30);
  FComboClasse.OnChange := @ComboClasseChange;
  FEtiquetteRegle := TLabelContour.Create(Self);
  FEtiquetteRegle.Parent := FBarre2;
  FEtiquetteRegle.SetBounds(0, 16, 90, 20);
  FComboRegle := TComboBox.Create(Self);
  FComboRegle.Parent := FBarre2;
  FComboRegle.Style := csDropDownList;
  FComboRegle.SetBounds(100, 10, 330, 30);
  FComboRegle.OnChange := @ComboRegleChange;
  FComboColonne := TComboBox.Create(Self);
  FComboColonne.Parent := FBarre2;
  FComboColonne.Style := csDropDownList;
  FComboColonne.SetBounds(450, 10, 280, 30);
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 1;
  FGrille.RowCount := 2;  // en-tete + ligne Total (toujours la derniere)
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing, goRowSelect] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.OnSelectCell := @GrilleSelectCell;
  FGrille.OnSetEditText := @GrilleSetEditText;
  FGrille.OnPrepareCanvas := @GrillePrepareCanvas;
  Visible := False;
end;

destructor TPanelTirageMetier.Destroy;
begin
  ViderRegles;
  FMetiersLib.Free;
  FMetiersCode.Free;
  FColonnesLib.Free;
  FColonnesCode.Free;
  FReglesLib.Free;
  FReglesCode.Free;
  FReglesClasse.Free;
  FReglesInitiales.Free;
  FReglesNouvelles.Free;
  FReglesRenommees.Free;
  FClassesCode.Free;
  FParRegle.Free;
  FColCodes.Free;
  inherited Destroy;
end;

procedure TPanelTirageMetier.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_512', 'Add a line');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonAjouter.SetBounds(0, 0, 230, 50);
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonRetirer.SetBounds(240, 0, 250, 50);
  FBoutonValider := TBCButtonContour.Create(Self);
  FBoutonValider.Assign(Modele);
  FBoutonValider.Parent := FBarre;
  FBoutonValider.Caption := GetTexteLibelle('RULES-LAB_086');
  FBoutonValider.OnClick := @BoutonValiderClick;
  FBoutonValider.SetBounds(500, 0, 150, 50);
  FBoutonAnnuler := TBCButtonContour.Create(Self);
  FBoutonAnnuler.Assign(Modele);
  FBoutonAnnuler.Parent := FBarre;
  FBoutonAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  FBoutonAnnuler.OnClick := @BoutonAnnulerClick;
  FBoutonAnnuler.SetBounds(660, 0, 150, 50);
  FBoutonColonne := TBCButtonContour.Create(Self);
  FBoutonColonne.Assign(Modele);
  FBoutonColonne.Parent := FBarre2;
  FBoutonColonne.Caption := GetTexteLibelle('RULES-LAB_518', 'Add a column');
  FBoutonColonne.OnClick := @BoutonColonneClick;
  FBoutonColonne.SetBounds(740, 0, 230, 50);
  FBoutonRetirerColonne := TBCButtonContour.Create(Self);
  FBoutonRetirerColonne.Assign(Modele);
  FBoutonRetirerColonne.Parent := FBarre2;
  FBoutonRetirerColonne.Caption := GetTexteLibelle('RULES-LAB_519', 'Remove the column');
  FBoutonRetirerColonne.OnClick := @BoutonRetirerColonneClick;
  FBoutonRetirerColonne.SetBounds(980, 0, 250, 50);
  FEtiquetteRegle.Caption := GetTexteLibelle('RULES-LAB_319', 'Rules');
  FEtiquetteClasse.Caption := GetTexteLibelle('RULES-LAB_525', 'Class replaced');
  FBoutonNouvelleRegle := TBCButtonContour.Create(Self);
  FBoutonNouvelleRegle.Assign(Modele);
  FBoutonNouvelleRegle.Parent := FBarre3;
  FBoutonNouvelleRegle.Caption := GetTexteLibelle('RULES-LAB_523', 'New rule');
  FBoutonNouvelleRegle.OnClick := @BoutonNouvelleRegleClick;
  FBoutonNouvelleRegle.SetBounds(0, 0, 230, 50);
  FBoutonSupprimerRegle := TBCButtonContour.Create(Self);
  FBoutonSupprimerRegle.Assign(Modele);
  FBoutonSupprimerRegle.Parent := FBarre3;
  FBoutonSupprimerRegle.Caption := GetTexteLibelle('RULES-LAB_524', 'Delete the rule');
  FBoutonSupprimerRegle.OnClick := @BoutonSupprimerRegleClick;
  FBoutonSupprimerRegle.SetBounds(240, 0, 250, 50);
  FBoutonRenommerRegle := TBCButtonContour.Create(Self);
  FBoutonRenommerRegle.Assign(Modele);
  FBoutonRenommerRegle.Parent := FBarre3;
  FBoutonRenommerRegle.Caption := GetTexteLibelle('RULES-LAB_581', 'Rename the rule');
  FBoutonRenommerRegle.OnClick := @BoutonRenommerRegleClick;
  FBoutonRenommerRegle.SetBounds(500, 0, 240, 50);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

procedure TPanelTirageMetier.ViderRegles;
var
  I: Integer;
begin
  for I := 0 to FParRegle.Count - 1 do
    FParRegle.Objects[I].Free;
  FParRegle.Clear;
end;

// Libelle du metier dans la grille ; deux metiers de meme libelle se distinguent par leur code.
function TPanelTirageMetier.LibelleMetier(const Code: String): String;
var
  I: Integer;
begin
  I := FMetiersCode.IndexOf(Code);
  if I >= 0 then Exit(FMetiersLib[I]);
  Result := FLibMetier(Code);
  if FMetiersLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FMetiersLib.Add(Result);
  FMetiersCode.Add(Code);
end;

function TPanelTirageMetier.CodeMetierDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FMetiersLib.IndexOf(Lib);
  if I >= 0 then Result := FMetiersCode[I];
end;

function TPanelTirageMetier.LibelleColonne(const Code: String): String;
var
  I: Integer;
begin
  I := FColonnesCode.IndexOf(Code);
  if I >= 0 then Exit(FColonnesLib[I]);
  Result := FLibColonne(Code);
  if FColonnesLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FColonnesLib.Add(Result);
  FColonnesCode.Add(Code);
end;

function TPanelTirageMetier.CodeColonneDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FColonnesLib.IndexOf(Lib);
  if I >= 0 then Result := FColonnesCode[I];
end;

function TPanelTirageMetier.LibelleRegle(const Code: String): String;
var
  I: Integer;
begin
  I := FReglesCode.IndexOf(Code);
  if I >= 0 then Exit(FReglesLib[I]);
  Result := FLibRegle(Code);
  if FReglesLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FReglesLib.Add(Result);
  FReglesCode.Add(Code);
  FReglesClasse.Add('');
end;

procedure TPanelTirageMetier.Configurer(ALibMetier, ALibColonne, ALibRegle: TFonctionLibelleTirage; Metiers, Colonnes, Regles: TStrings);
var
  I: Integer;
begin
  FLibMetier := ALibMetier;
  FLibColonne := ALibColonne;
  FLibRegle := ALibRegle;
  FMetiersLib.Clear;
  FMetiersCode.Clear;
  FColonnesLib.Clear;
  FColonnesCode.Clear;
  FReglesLib.Clear;
  FReglesCode.Clear;
  FReglesClasse.Clear;
  FReglesInitiales.Clear;
  FReglesNouvelles.Clear;
  FReglesRenommees.Clear;
  for I := 0 to Metiers.Count - 1 do
    LibelleMetier(Metiers[I]);
  for I := 0 to Colonnes.Count - 1 do
    LibelleColonne(Colonnes[I]);
  for I := 0 to Regles.Count - 1 do
    LibelleRegle(Regles[I]);
  FGrille.ColWidths[0] := 260;
end;

// Lignes "colonne"#9"metier"#9"chance" d'une regle (nil si la regle n'a aucune entree).
function TPanelTirageMetier.LignesDeRegle(const Code: String): TStringList;
var
  I: Integer;
begin
  I := FParRegle.IndexOf(Code);
  if I < 0 then Exit(nil);
  Result := TStringList(FParRegle.Objects[I]);
end;

function TPanelTirageMetier.AjouterColonneGrille(const Code: String): Integer;
begin
  FColCodes.Add(Code);
  Result := FColCodes.Count;
  FGrille.ColCount := Result + 1;
  FGrille.Cells[Result, 0] := LibelleColonne(Code);
  FGrille.ColWidths[Result] := 110;
end;

function TPanelTirageMetier.DerniereLigne: Integer;
begin
  Result := FGrille.RowCount - 2;
end;

procedure TPanelTirageMetier.Charger(Chapitre: TDOMElement);
var
  Bloc, Enfant: TDOMNode;
  CodeRegle, CodeColonne, CodeMetier, Valeur: String;
  Lignes: TStringList;
begin
  FGrille.EditorMode := False;
  ViderRegles;
  FRegle := '';
  if Chapitre <> nil then
  begin
    Bloc := Chapitre.FirstChild;
    while Bloc <> nil do
    begin
      if (Bloc.NodeType = ELEMENT_NODE) and (Bloc.NodeName = 'Entry') then
      begin
        CodeRegle := '';
        CodeColonne := '';
        CodeMetier := '';
        Valeur := '';
        Enfant := Bloc.FirstChild;
        while Enfant <> nil do
        begin
          if Enfant.NodeType = ELEMENT_NODE then
          begin
            if Enfant.NodeName = 'Rule' then
              CodeRegle := RemoveQuotes(Trim(Enfant.TextContent))
            else if Enfant.NodeName = 'Specie' then
              CodeColonne := RemoveQuotes(Trim(Enfant.TextContent))
            else if Enfant.NodeName = 'Career' then
            begin
              CodeMetier := TDOMElement(Enfant).GetAttribute('name');
              Valeur := RemoveQuotes(Trim(Enfant.TextContent));
            end;
          end;
          Enfant := Enfant.NextSibling;
        end;
        if (CodeRegle <> '') and (CodeColonne <> '') and (CodeMetier <> '') then
        begin
          // un code cite par le XML et absent des listes proposees y est ajoute : rien ne se perd a l'ecriture
          LibelleRegle(CodeRegle);
          LibelleColonne(CodeColonne);
          LibelleMetier(CodeMetier);
          Lignes := LignesDeRegle(CodeRegle);
          if Lignes = nil then
          begin
            Lignes := TStringList.Create;
            FParRegle.AddObject(CodeRegle, Lignes);
          end;
          Lignes.Add(CodeColonne + #9 + CodeMetier + #9 + Valeur);
        end;
      end;
      Bloc := Bloc.NextSibling;
    end;
  end;
  FComboRegle.Items.Assign(FReglesLib);
  FComboColonne.Items.Assign(FColonnesLib);
  if FComboColonne.Items.Count > 0 then FComboColonne.ItemIndex := 0;
  if FReglesCode.Count > 0 then
  begin
    FComboRegle.ItemIndex := 0;
    AfficherRegle(FReglesCode[0]);
  end
  else
  begin
    FComboRegle.ItemIndex := -1;
    AfficherRegle('');
  end;
end;

// Pose dans la grille la table d'une regle : une colonne par ethnie ou race citee, une ligne par metier.
procedure TPanelTirageMetier.AfficherRegle(const Code: String);
var
  Lignes: TStringList;
  I, C, R, K, P1, P2: Integer;
  Col, Metier, Valeur, LibMetier: String;
begin
  FGrille.EditorMode := False;
  FRegle := Code;
  FColCodes.Clear;
  FGrille.ColCount := 1;
  FGrille.RowCount := 2;
  FGrille.Rows[1].Clear;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_006', 'Career');
  FGrille.Cells[0, 1] := GetTexteLibelle('RULES-LAB_510', 'Total');
  Lignes := LignesDeRegle(Code);
  if Lignes <> nil then
    for I := 0 to Lignes.Count - 1 do
    begin
      P1 := Pos(#9, Lignes[I]);
      Col := Copy(Lignes[I], 1, P1 - 1);
      P2 := Pos(#9, Copy(Lignes[I], P1 + 1, MaxInt)) + P1;
      Metier := Copy(Lignes[I], P1 + 1, P2 - P1 - 1);
      Valeur := Copy(Lignes[I], P2 + 1, MaxInt);
      C := FColCodes.IndexOf(Col) + 1;
      if C = 0 then C := AjouterColonneGrille(Col);
      LibMetier := LibelleMetier(Metier);
      R := 0;
      for K := 1 to DerniereLigne do
        if FGrille.Cells[0, K] = LibMetier then
        begin
          R := K;
          Break;
        end;
      if R = 0 then
      begin
        R := FGrille.RowCount - 1;
        FGrille.InsertColRow(False, R);  // avant la ligne Total
        FGrille.Cells[0, R] := LibMetier;
      end;
      FGrille.Cells[C, R] := Valeur;
    end;
  FGrilleModifiee := False;
  RecalculerTotaux;
  SynchroClasse;
end;

// Remet la grille dans les donnees de la regle affichee, colonne par colonne, metiers dans l'ordre de la grille.
procedure TPanelTirageMetier.RangerRegle;
var
  Lignes: TStringList;
  C, R: Integer;
  Metier, Valeur: String;
begin
  FGrille.EditorMode := False;
  if (FRegle = '') or not FGrilleModifiee then Exit;
  Lignes := LignesDeRegle(FRegle);
  if Lignes = nil then
  begin
    Lignes := TStringList.Create;
    FParRegle.AddObject(FRegle, Lignes);
  end;
  Lignes.Clear;
  for C := 1 to FGrille.ColCount - 1 do
    for R := 1 to DerniereLigne do
    begin
      Valeur := Trim(FGrille.Cells[C, R]);
      if Valeur = '' then Continue;
      Metier := CodeMetierDe(Trim(FGrille.Cells[0, R]));
      Lignes.Add(FColCodes[C - 1] + #9 + Metier + #9 + Valeur);
    end;
  FGrilleModifiee := False;  // la grille et les donnees sont de nouveau d'accord
end;

procedure TPanelTirageMetier.ConfigurerClasses(ALib: TFonctionLibelleTirage; Classes: TStrings; const Prefixe: String);
var
  I: Integer;
begin
  FLibClasse := ALib;
  FPrefixe := Prefixe;
  FClassesCode.Assign(Classes);
  FComboClasse.Items.Clear;
  FComboClasse.Items.Add(GetTexteLibelle('RULES-LAB_526', '(none: the rule replaces the whole table)'));
  for I := 0 to FClassesCode.Count - 1 do
    FComboClasse.Items.Add(FLibClasse(FClassesCode[I]));
end;

procedure TPanelTirageMetier.DeclarerRegle(const Code, Classe: String);
var
  I: Integer;
begin
  I := FReglesCode.IndexOf(Code);
  if I >= 0 then FReglesClasse[I] := Classe;
  if FReglesInitiales.IndexOf(Code) < 0 then FReglesInitiales.Add(Code);
end;

// La liste de la classe suit la regle affichee ; sans regle, elle est inactive.
procedure TPanelTirageMetier.SynchroClasse;
var
  I, K: Integer;
begin
  I := FReglesCode.IndexOf(FRegle);
  FComboClasse.Enabled := I >= 0;
  FBoutonSupprimerRegle.Enabled := I >= 0;
  FBoutonRenommerRegle.Enabled := I >= 0;
  if I < 0 then
  begin
    FComboClasse.ItemIndex := -1;
    Exit;
  end;
  K := FClassesCode.IndexOf(FReglesClasse[I]);
  if FReglesClasse[I] = '' then
    FComboClasse.ItemIndex := 0
  else if K >= 0 then
    FComboClasse.ItemIndex := K + 1
  else
    FComboClasse.ItemIndex := -1;  // classe absente de la liste : conservee telle quelle tant qu'on n'en choisit pas une autre
end;

procedure TPanelTirageMetier.ComboClasseChange(Sender: TObject);
var
  I: Integer;
begin
  I := FReglesCode.IndexOf(FRegle);
  if (I < 0) or (FComboClasse.ItemIndex < 0) then Exit;
  if FComboClasse.ItemIndex = 0 then
    FReglesClasse[I] := ''
  else
    FReglesClasse[I] := FClassesCode[FComboClasse.ItemIndex - 1];
end;

procedure TPanelTirageMetier.BoutonNouvelleRegleClick(Sender: TObject);
var
  Lib, Mot, Code: String;
  I, N: Integer;
begin
  FGrille.EditorMode := False;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_523', 'New rule'), GetTexteLibelle('RULES-LAB_527', 'Name of the rule'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;
  RangerRegle;
  Mot := '';
  for I := 1 to Length(Lib) do
    if (UpCase(Lib[I]) in ['A'..'Z']) and (Length(Mot) < 8) then
      Mot := Mot + UpCase(Lib[I]);
  if Mot = '' then Mot := 'NEW';
  Code := FPrefixe + '-RULE_' + Mot;
  N := 1;
  while FReglesCode.IndexOf(Code) >= 0 do
  begin
    Inc(N);
    Code := FPrefixe + '-RULE_' + Mot + IntToStr(N);
  end;
  if FReglesLib.IndexOf(Lib) >= 0 then Lib := Lib + ' [' + Code + ']';
  FReglesLib.Add(Lib);
  FReglesCode.Add(Code);
  FReglesClasse.Add('');
  FReglesNouvelles.Add(Code + '=' + Lib);
  FComboRegle.Items.Assign(FReglesLib);
  FComboRegle.ItemIndex := FReglesCode.Count - 1;
  AfficherRegle(Code);
end;

procedure TPanelTirageMetier.BoutonSupprimerRegleClick(Sender: TObject);
var
  I, K: Integer;
begin
  FGrille.EditorMode := False;
  I := FReglesCode.IndexOf(FRegle);
  if I < 0 then Exit;
  if MessageDlg(Format(GetTexteLibelle('RULES-LAB_528', 'Delete the rule %s and all its columns?'), [FReglesLib[I]]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  K := FParRegle.IndexOf(FRegle);
  if K >= 0 then
  begin
    FParRegle.Objects[K].Free;
    FParRegle.Delete(K);
  end;
  K := FReglesNouvelles.IndexOfName(FRegle);
  if K >= 0 then FReglesNouvelles.Delete(K);
  FReglesCode.Delete(I);
  FReglesLib.Delete(I);
  FReglesClasse.Delete(I);
  FRegle := '';
  FComboRegle.Items.Assign(FReglesLib);
  if FReglesCode.Count > 0 then
  begin
    FComboRegle.ItemIndex := 0;
    AfficherRegle(FReglesCode[0]);
  end
  else
  begin
    FComboRegle.ItemIndex := -1;
    AfficherRegle('');
  end;
end;

// Change le libelle de la regle affichee ; le code ne bouge pas (les tables qui la citent restent valables).
procedure TPanelTirageMetier.BoutonRenommerRegleClick(Sender: TObject);
var
  Nom: String;
  I, K: Integer;
begin
  FGrille.EditorMode := False;
  I := FReglesCode.IndexOf(FRegle);
  if I < 0 then Exit;
  Nom := FReglesLib[I];
  if not InputQuery(GetTexteLibelle('RULES-LAB_581', 'Rename the rule'), GetTexteLibelle('RULES-LAB_527', 'Name of the rule'), Nom) then Exit;
  Nom := Trim(Nom);
  if Nom = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;
  if Nom = FReglesLib[I] then Exit;
  if FReglesLib.IndexOf(Nom) >= 0 then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_582', 'Another rule already has this name.'));
    Exit;
  end;
  FReglesLib[I] := Nom;
  K := FReglesNouvelles.IndexOfName(FRegle);
  if K >= 0 then
    FReglesNouvelles[K] := FRegle + '=' + Nom
  else
  begin
    K := FReglesRenommees.IndexOfName(FRegle);
    if K >= 0 then
      FReglesRenommees[K] := FRegle + '=' + Nom
    else
      FReglesRenommees.Add(FRegle + '=' + Nom);
  end;
  FComboRegle.Items.Assign(FReglesLib);
  FComboRegle.ItemIndex := I;
end;

function TPanelTirageMetier.ReglesACreer: Boolean;
begin
  Result := FReglesNouvelles.Count > 0;
end;

// DATA_RULE : retire les regles supprimees, met a jour la classe des regles modifiees, ajoute les nouvelles.
procedure TPanelTirageMetier.EcrireRegles(Chapitre: TDOMElement; const Langue: String);
var
  Doc: TDOMDocument;
  N, Suivant, Fils: TDOMNode;
  Regle, E: TDOMElement;
  Code, Classe: String;
  I, K: Integer;
  Presentes: TStringList;
begin
  Doc := Chapitre.OwnerDocument;
  Presentes := TStringList.Create;
  try
    N := Chapitre.FirstChild;
    while N <> nil do
    begin
      Suivant := N.NextSibling;
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Rule') then
      begin
        Regle := TDOMElement(N);
        Code := Regle.GetAttribute('id');
        I := FReglesCode.IndexOf(Code);
        if (I < 0) and (FReglesInitiales.IndexOf(Code) >= 0) then
          Chapitre.RemoveChild(N)
        else if I >= 0 then
        begin
          Presentes.Add(Code);
          K := FReglesRenommees.IndexOfName(Code);
          if K >= 0 then
          begin
            Fils := Regle.FindNode('Description');
            if Fils = nil then
            begin
              E := Doc.CreateElement('Description');
              E.SetAttribute('language', Langue);
              Regle.InsertBefore(E, Regle.FirstChild);
              Fils := E;
            end;
            while Fils.FirstChild <> nil do Fils.RemoveChild(Fils.FirstChild);
            Fils.AppendChild(Doc.CreateTextNode('"' + FReglesRenommees.ValueFromIndex[K] + '"'));
          end;
          Classe := FReglesClasse[I];
          Fils := Regle.FindNode('Class');
          if not (((Fils <> nil) and (RemoveQuotes(Trim(Fils.TextContent)) = Classe)) or ((Fils = nil) and (Classe = ''))) then
          begin
            if Fils <> nil then Regle.RemoveChild(Fils);
            if Classe <> '' then
            begin
              E := Doc.CreateElement('Class');
              E.AppendChild(Doc.CreateTextNode('"' + Classe + '"'));
              Regle.AppendChild(E);
            end;
          end;
        end;
      end;
      N := Suivant;
    end;
    for I := 0 to FReglesNouvelles.Count - 1 do
    begin
      Code := FReglesNouvelles.Names[I];
      if (Presentes.IndexOf(Code) >= 0) or (FReglesCode.IndexOf(Code) < 0) then Continue;
      Regle := Doc.CreateElement('Rule');
      Regle.SetAttribute('id', Code);
      E := Doc.CreateElement('Description');
      E.SetAttribute('language', Langue);
      E.AppendChild(Doc.CreateTextNode('"' + FReglesNouvelles.ValueFromIndex[I] + '"'));
      Regle.AppendChild(E);
      Classe := FReglesClasse[FReglesCode.IndexOf(Code)];
      if Classe <> '' then
      begin
        E := Doc.CreateElement('Class');
        E.AppendChild(Doc.CreateTextNode('"' + Classe + '"'));
        Regle.AppendChild(E);
      end;
      Chapitre.AppendChild(Regle);
    end;
  finally
    Presentes.Free;
  end;
end;

procedure TPanelTirageMetier.ComboRegleChange(Sender: TObject);
begin
  if FComboRegle.ItemIndex < 0 then Exit;
  RangerRegle;
  AfficherRegle(FReglesCode[FComboRegle.ItemIndex]);
end;

procedure TPanelTirageMetier.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  Entree, E: TDOMElement;
  Lignes: TStringList;
  I, J, P1, P2: Integer;
  Col, Metier, Valeur: String;
begin
  RangerRegle;
  Doc := Chapitre.OwnerDocument;
  while Chapitre.FirstChild <> nil do
    Chapitre.RemoveChild(Chapitre.FirstChild);
  for I := 0 to FParRegle.Count - 1 do
  begin
    Lignes := TStringList(FParRegle.Objects[I]);
    for J := 0 to Lignes.Count - 1 do
    begin
      P1 := Pos(#9, Lignes[J]);
      Col := Copy(Lignes[J], 1, P1 - 1);
      P2 := Pos(#9, Copy(Lignes[J], P1 + 1, MaxInt)) + P1;
      Metier := Copy(Lignes[J], P1 + 1, P2 - P1 - 1);
      Valeur := Copy(Lignes[J], P2 + 1, MaxInt);
      Entree := Doc.CreateElement('Entry');
      E := Doc.CreateElement('Rule');
      E.AppendChild(Doc.CreateTextNode('"' + FParRegle[I] + '"'));
      Entree.AppendChild(E);
      E := Doc.CreateElement('Specie');
      E.AppendChild(Doc.CreateTextNode('"' + Col + '"'));
      Entree.AppendChild(E);
      E := Doc.CreateElement('Career');
      E.SetAttribute('name', Metier);
      E.AppendChild(Doc.CreateTextNode('"' + Valeur + '"'));
      Entree.AppendChild(E);
      Entree.AppendChild(Doc.CreateComment('  ' + LibelleMetier(Metier) + '  '));
      Chapitre.AppendChild(Entree);
    end;
  end;
end;

function TPanelTirageMetier.Controler: Boolean;
var
  Lignes: TStringList;
  Vus: TStringList;
  I, J, P1, P2: Integer;
  Col, Metier, Valeur, Cle: String;
begin
  Result := True;
  RangerRegle;
  for I := 0 to FParRegle.Count - 1 do
  begin
    Lignes := TStringList(FParRegle.Objects[I]);
    Vus := TStringList.Create;
    try
      for J := 0 to Lignes.Count - 1 do
      begin
        P1 := Pos(#9, Lignes[J]);
        Col := Copy(Lignes[J], 1, P1 - 1);
        P2 := Pos(#9, Copy(Lignes[J], P1 + 1, MaxInt)) + P1;
        Metier := Copy(Lignes[J], P1 + 1, P2 - P1 - 1);
        Valeur := Copy(Lignes[J], P2 + 1, MaxInt);
        if Metier = '' then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-LAB_520', 'Rule %s, column %s: a line has a chance but no career.'),
            [LibelleRegle(FParRegle[I]), LibelleColonne(Col)]));
          Exit(False);
        end;
        if StrToIntDef(Valeur, 0) <= 0 then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-LAB_521', 'Rule %s, column %s, %s: "%s" is not a whole number above 0.'),
            [LibelleRegle(FParRegle[I]), LibelleColonne(Col), LibelleMetier(Metier), Valeur]));
          Exit(False);
        end;
        Cle := Col + #9 + Metier;
        if Vus.IndexOf(Cle) >= 0 then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-LAB_522', 'Rule %s, column %s: %s appears twice.'),
            [LibelleRegle(FParRegle[I]), LibelleColonne(Col), LibelleMetier(Metier)]));
          Exit(False);
        end;
        Vus.Add(Cle);
      end;
    finally
      Vus.Free;
    end;
  end;
end;

procedure TPanelTirageMetier.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if aRow > DerniereLigne then CanSelect := False;
end;

procedure TPanelTirageMetier.GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
begin
  FGrilleModifiee := True;
  RecalculerTotaux;
end;

procedure TPanelTirageMetier.GrillePrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
begin
  if aRow <= DerniereLigne then Exit;
  FGrille.Canvas.Font.Style := [fsBold];
  if (aCol >= 1) and (FGrille.Cells[aCol, aRow] = '100') then
    FGrille.Canvas.Font.Color := clGreen;
end;

// Total d'une colonne = somme des chances ; vide si aucune cellule n'est remplie.
procedure TPanelTirageMetier.RecalculerTotaux;
var
  C, R, Somme: Integer;
  Vide: Boolean;
  Valeur: String;
begin
  for C := 1 to FGrille.ColCount - 1 do
  begin
    Somme := 0;
    Vide := True;
    for R := 1 to DerniereLigne do
    begin
      Valeur := Trim(FGrille.Cells[C, R]);
      if Valeur = '' then Continue;
      Vide := False;
      Somme := Somme + StrToIntDef(Valeur, 0);
    end;
    if Vide then
      FGrille.Cells[C, FGrille.RowCount - 1] := ''
    else
      FGrille.Cells[C, FGrille.RowCount - 1] := IntToStr(Somme);
  end;
end;

procedure TPanelTirageMetier.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  // colonne du metier : liste de choix ; les autres colonnes restent une saisie libre
  if (aCol <> 0) or (aRow < 1) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FMetiersLib);
end;

procedure TPanelTirageMetier.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount - 1;
  FGrille.InsertColRow(False, R);  // avant la ligne Total
  FGrille.Row := R;
  FGrille.Col := 0;
  FGrilleModifiee := True;
end;

procedure TPanelTirageMetier.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row <= DerniereLigne) then
  begin
    FGrille.DeleteRow(FGrille.Row);
    FGrilleModifiee := True;
    RecalculerTotaux;
  end;
end;

// Ajoute la colonne choisie dans la liste (sans effet si la regle l'a deja ou si aucune regle n'est affichee).
procedure TPanelTirageMetier.BoutonColonneClick(Sender: TObject);
var
  Code: String;
begin
  FGrille.EditorMode := False;
  if (FRegle = '') or (FComboColonne.ItemIndex < 0) then Exit;
  Code := FColonnesCode[FComboColonne.ItemIndex];
  if FColCodes.IndexOf(Code) >= 0 then Exit;
  AjouterColonneGrille(Code);
  FGrilleModifiee := True;
  RecalculerTotaux;
end;

// Retire la colonne ou se trouve la cellule selectionnee, avec toutes ses chances.
procedure TPanelTirageMetier.BoutonRetirerColonneClick(Sender: TObject);
var
  C: Integer;
begin
  FGrille.EditorMode := False;
  C := FGrille.Col;
  if (C < 1) or (C > FColCodes.Count) then Exit;
  FColCodes.Delete(C - 1);
  FGrille.DeleteCol(C);
  FGrilleModifiee := True;
  RecalculerTotaux;
end;

procedure TPanelTirageMetier.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelTirageMetier.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelTirageMetier.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelTirageMetier.GetLectureSeule: Boolean;
begin
  Result := not (goEditing in FGrille.Options);
end;

// En lecture : grille non modifiable, sans boutons ; le choix de la regle reste possible.
procedure TPanelTirageMetier.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
  FBarre3.Visible := not Valeur;
  FComboColonne.Visible := not Valeur;
  FBoutonColonne.Visible := not Valeur;
  FBoutonRetirerColonne.Visible := not Valeur;
end;

procedure TPanelTirageMetier.FinEdition;
begin
  FGrille.EditorMode := False;
end;

// Contenu de toutes les regles (donnees rangees) et de la grille affichee, pour detecter une modification.
function TPanelTirageMetier.Signature(const Sep: String): String;
var
  I, L, C: Integer;
begin
  Result := FRegle;
  for I := 0 to FParRegle.Count - 1 do
    Result := Result + Sep + FParRegle[I] + Sep + TStringList(FParRegle.Objects[I]).Text;
  for I := 0 to FReglesCode.Count - 1 do
    Result := Result + Sep + FReglesCode[I] + Sep + FReglesClasse[I];
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

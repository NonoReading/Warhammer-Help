unit PanelAdaptation;

{$mode ObjFPC}{$H+}

// Ethnies et substitutions d'une adaptation de carriere (DATA_CAREER_ADAPTATION, CONTEXT.md 2.103 et 2.107) dans sa
// fiche. Premier tableau : les ethnies visees (une par ligne, choisies par libelle ; le XML les joint par /).
// Second tableau : les substitutions, une ligne par remplacement, Niveau | Nature | Retirer | Ajouter. Une ligne sans Ajouter retire, une ligne sans
// Retirer ajoute. Le XML range les lignes par niveau (<Level><Order>) puis par nature (<Skill>, <Talent>, <Trapping>),
// chacune avec sa paire <Remove>/<Add> ; le panneau reecrit tous les niveaux. Competences et talents se choisissent par
// libelle, l'equipement aussi ; un texte libre (« Highborn Patronage ») est garde tel quel.
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelAdaptation = class(TPanelExtraFiche)
  private
    FTitre, FTitreEsp: TLabel;
    FBarre, FBarreEsp: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonAjEsp, FBoutonRetEsp: TBCButton;
    FGrille, FGrilleEsp: TStringGrid;
    FEspLib, FEspCode: TStringList;
    FCompLib, FCompCode, FTalLib, FTalCode, FEquipLib, FEquipCode: TStringList;
    FLectureSeule: Boolean;
    function  Especes: String;
    function  LibNature(const Balise: String): String;
    function  BaliseNature(const Lib: String): String;
    function  LibDe(Libs, Codes: TStringList; const Code: String): String;
    function  CodeDe(Libs, Codes: TStringList; const Lib: String): String;
    function  ListeNature(const Balise: String; out Libs, Codes: TStringList): Boolean;
    procedure AjouterLigne(Niveau: Integer; const Balise, Retire, Ajoute: String);
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonAjEspClick(Sender: TObject);
    procedure BoutonRetEspClick(Sender: TObject);
    procedure Positionner(Edition: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger. Listes "code=libelle|..." (les choix proposes) ; Ethnies = races, especes, nations.
    procedure Configurer(const Competences, Talents, Equipements, Ethnies: String);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  NiveauMax = 4;
  HauteurPanneau = 520;
  NbNatures = 3;
  BalisesNature: array[0..NbNatures - 1] of String = ('Skill', 'Talent', 'Trapping');

procedure Remplir(Libs, Codes: TStringList; const Choix: String);
var
  Liste: TStringList;
  I, P: Integer;
begin
  Libs.Clear;
  Codes.Clear;
  Liste := TStringList.Create;
  try
    Liste.Delimiter := '|';
    Liste.StrictDelimiter := True;
    Liste.DelimitedText := Choix;
    for I := 0 to Liste.Count - 1 do
    begin
      P := Pos('=', Liste[I]);
      if (P > 1) and (Codes.IndexOf(Copy(Liste[I], 1, P - 1)) < 0) then
      begin
        Codes.Add(Copy(Liste[I], 1, P - 1));
        Libs.Add(Copy(Liste[I], P + 1, MaxInt));
      end;
    end;
  finally
    Liste.Free;
  end;
end;

constructor TPanelAdaptation.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCompLib := TStringList.Create;
  FCompCode := TStringList.Create;
  FTalLib := TStringList.Create;
  FTalCode := TStringList.Create;
  FEquipLib := TStringList.Create;
  FEquipCode := TStringList.Create;
  FEspLib := TStringList.Create;
  FEspCode := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurPanneau;
  FTitreEsp := TLabelContour.Create(Self);
  FTitreEsp.Parent := Self;
  FBarreEsp := TPanel.Create(Self);
  FBarreEsp.Parent := Self;
  FBarreEsp.BevelOuter := bvNone;
  FBarreEsp.Caption := '';
  FGrilleEsp := TStringGrid.Create(Self);
  FGrilleEsp.Parent := Self;
  CouleurSelectionGrille(FGrilleEsp);
  FGrilleEsp.ColCount := 1;
  FGrilleEsp.RowCount := 1;
  FGrilleEsp.FixedRows := 1;
  FGrilleEsp.FixedCols := 0;
  FGrilleEsp.Options := FGrilleEsp.Options + [goEditing] - [goRangeSelect];
  FGrilleEsp.ColWidths[0] := 500;
  FGrilleEsp.OnSelectEditor := @GrilleSelectEditor;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.ColCount := 4;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.ColWidths[0] := 70;
  FGrille.ColWidths[1] := 150;
  FGrille.ColWidths[2] := 340;
  FGrille.ColWidths[3] := 340;
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  Positionner(True);
  Visible := False;
end;

// Disposition verticale : en lecture seule les barres de boutons disparaissent et les tableaux remontent.
procedure TPanelAdaptation.Positionner(Edition: Boolean);
var
  Y: Integer;
begin
  Y := 0;
  FTitreEsp.SetBounds(0, Y, 600, 20);
  Inc(Y, 24);
  FBarreEsp.Visible := Edition;
  if Edition then
  begin
    FBarreEsp.SetBounds(0, Y, 1000, 44);
    Inc(Y, 48);
  end;
  FGrilleEsp.SetBounds(0, Y, 500, 130);
  Inc(Y, 138);
  FTitre.SetBounds(0, Y, 600, 20);
  Inc(Y, 24);
  FBarre.Visible := Edition;
  if Edition then
  begin
    FBarre.SetBounds(0, Y, 1000, 44);
    Inc(Y, 48);
  end;
  FGrille.SetBounds(0, Y, 1000, 220);
  Height := Y + 228;
end;

destructor TPanelAdaptation.Destroy;
begin
  FCompLib.Free;
  FCompCode.Free;
  FTalLib.Free;
  FTalCode.Free;
  FEquipLib.Free;
  FEquipCode.Free;
  FEspLib.Free;
  FEspCode.Free;
  inherited Destroy;
end;

procedure TPanelAdaptation.Initialiser(Modele: TBCButton);
begin
  FTitreEsp.Caption := GetTexteLibelle('RULES-LAB_012', 'Possible species');
  FGrilleEsp.Cells[0, 0] := GetTexteLibelle('RULES-LAB_012', 'Possible species');
  FTitre.Caption := GetTexteLibelle('RULES-LAB_565', 'Substitutions');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_566', 'Level');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_567', 'Kind');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_568', 'Remove');
  FGrille.Cells[3, 0] := GetTexteLibelle('RULES-LAB_569', 'Add');
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.SetBounds(0, 0, 230, 40);
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_512', 'Add a line');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.SetBounds(240, 0, 230, 40);
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421', 'Remove the line');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonAjEsp := TBCButtonContour.Create(Self);
  FBoutonAjEsp.Assign(Modele);
  FBoutonAjEsp.Parent := FBarreEsp;
  FBoutonAjEsp.SetBounds(0, 0, 230, 40);
  FBoutonAjEsp.Caption := GetTexteLibelle('RULES-LAB_512', 'Add a line');
  FBoutonAjEsp.OnClick := @BoutonAjEspClick;
  FBoutonRetEsp := TBCButtonContour.Create(Self);
  FBoutonRetEsp.Assign(Modele);
  FBoutonRetEsp.Parent := FBarreEsp;
  FBoutonRetEsp.SetBounds(240, 0, 230, 40);
  FBoutonRetEsp.Caption := GetTexteLibelle('RULES-LAB_421', 'Remove the line');
  FBoutonRetEsp.OnClick := @BoutonRetEspClick;
  MiseAJourUnContenaire(Self);
end;

procedure TPanelAdaptation.Configurer(const Competences, Talents, Equipements, Ethnies: String);
begin
  Remplir(FCompLib, FCompCode, Competences);
  Remplir(FTalLib, FTalCode, Talents);
  Remplir(FEquipLib, FEquipCode, Equipements);
  Remplir(FEspLib, FEspCode, Ethnies);
end;

function TPanelAdaptation.LibNature(const Balise: String): String;
begin
  if Balise = 'Skill' then Result := GetTexteLibelle('RULES-LAB_009', 'Skill')
  else if Balise = 'Talent' then Result := GetTexteLibelle('RULES-LAB_007', 'Talent')
  else if Balise = 'Trapping' then Result := GetTexteLibelle('RULES-LAB_013', 'Equipment')
  else Result := '';
end;

function TPanelAdaptation.BaliseNature(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to NbNatures - 1 do
    if LibNature(BalisesNature[I]) = Trim(Lib) then Exit(BalisesNature[I]);
end;

function TPanelAdaptation.LibDe(Libs, Codes: TStringList; const Code: String): String;
var
  I: Integer;
begin
  Result := Trim(Code);
  I := Codes.IndexOf(Result);
  if I >= 0 then Result := Libs[I];  // un code inconnu ou un texte libre reste visible tel quel
end;

function TPanelAdaptation.CodeDe(Libs, Codes: TStringList; const Lib: String): String;
var
  I: Integer;
begin
  Result := Trim(Lib);
  // un libelle peut finir par une espace (Pistage ) : on compare sans espaces de bout
  for I := 0 to Libs.Count - 1 do
    if Trim(Libs[I]) = Result then
    begin
      Result := Codes[I];
      Break;
    end;
end;

// Libelles et codes proposes pour une nature (Balise) ; faux si la nature est vide.
function TPanelAdaptation.ListeNature(const Balise: String; out Libs, Codes: TStringList): Boolean;
begin
  Result := True;
  if Balise = 'Skill' then begin Libs := FCompLib; Codes := FCompCode; end
  else if Balise = 'Talent' then begin Libs := FTalLib; Codes := FTalCode; end
  else if Balise = 'Trapping' then begin Libs := FEquipLib; Codes := FEquipCode; end
  else begin Libs := nil; Codes := nil; Result := False; end;
end;

procedure TPanelAdaptation.AjouterLigne(Niveau: Integer; const Balise, Retire, Ajoute: String);
var
  R: Integer;
  Libs, Codes: TStringList;
begin
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Cells[0, R] := IntToStr(Niveau);
  FGrille.Cells[1, R] := LibNature(Balise);
  if ListeNature(Balise, Libs, Codes) then
  begin
    FGrille.Cells[2, R] := LibDe(Libs, Codes, Retire);
    FGrille.Cells[3, R] := LibDe(Libs, Codes, Ajoute);
  end
  else
  begin
    FGrille.Cells[2, R] := Retire;
    FGrille.Cells[3, R] := Ajoute;
  end;
end;

procedure TPanelAdaptation.Charger(Element: TDOMElement);
var
  Niv, Bloc: TDOMNode;
  N, I: Integer;
  Liste: TStringList;
begin
  FGrille.EditorMode := False;
  FGrilleEsp.EditorMode := False;
  FGrille.RowCount := 1;
  FGrilleEsp.RowCount := 1;
  Liste := TStringList.Create;
  try
    Liste.Delimiter := '/';
    Liste.StrictDelimiter := True;
    Liste.DelimitedText := ValeurXML(Element.FindNode('Specie'));
    for I := 0 to Liste.Count - 1 do
      if Trim(Liste[I]) <> '' then
      begin
        FGrilleEsp.RowCount := FGrilleEsp.RowCount + 1;
        FGrilleEsp.Cells[0, FGrilleEsp.RowCount - 1] := LibDe(FEspLib, FEspCode, Liste[I]);
      end;
  finally
    Liste.Free;
  end;
  Niv := Element.FirstChild;
  while Niv <> nil do
  begin
    if (Niv.NodeType = ELEMENT_NODE) and (Niv.NodeName = 'Level') then
    begin
      N := StrToIntDef(Trim(ValeurXML(Niv.FindNode('Order'))), 0);
      Bloc := Niv.FirstChild;
      while Bloc <> nil do
      begin
        if Bloc.NodeType = ELEMENT_NODE then
          for I := 0 to NbNatures - 1 do
            if Bloc.NodeName = BalisesNature[I] then
              AjouterLigne(N, Bloc.NodeName, ValeurXML(Bloc.FindNode('Remove')), ValeurXML(Bloc.FindNode('Add')));
        Bloc := Bloc.NextSibling;
      end;
    end;
    Niv := Niv.NextSibling;
  end;
end;

// Codes des ethnies du premier tableau, joints par / (lignes vides et doublons ignores).
function TPanelAdaptation.Especes: String;
var
  R: Integer;
  Code: String;
begin
  Result := '';
  for R := 1 to FGrilleEsp.RowCount - 1 do
  begin
    Code := CodeDe(FEspLib, FEspCode, FGrilleEsp.Cells[0, R]);
    if (Code = '') or (Pos('/' + Code + '/', '/' + Result + '/') > 0) then Continue;
    if Result <> '' then Result := Result + '/';
    Result := Result + Code;
  end;
end;

function TPanelAdaptation.Controler: Boolean;
var
  R, N: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  FGrilleEsp.EditorMode := False;
  if Especes = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_576', 'Choose at least one species.'));
    Exit(False);
  end;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    N := StrToIntDef(Trim(FGrille.Cells[0, R]), 0);
    if (N < 1) or (N > NiveauMax) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_573'), [R]));
      Exit(False);
    end;
    if BaliseNature(FGrille.Cells[1, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_574'), [R]));
      Exit(False);
    end;
    if (Trim(FGrille.Cells[2, R]) = '') and (Trim(FGrille.Cells[3, R]) = '') then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_575'), [R]));
      Exit(False);
    end;
  end;
end;

procedure TPanelAdaptation.Ecrire(Element: TDOMElement);
var
  Doc: TDOMDocument;
  Noeud, Suivant: TDOMNode;
  Niv, Bloc, E: TDOMElement;
  N, R, I: Integer;
  Balise, Retire, Ajoute: String;
  Libs, Codes: TStringList;
begin
  FGrille.EditorMode := False;
  FGrilleEsp.EditorMode := False;
  Doc := Element.OwnerDocument;
  E := TDOMElement(Element.FindNode('Specie'));
  if E = nil then
  begin
    E := Doc.CreateElement('Specie');
    Noeud := Element.FindNode('Career');
    if (Noeud <> nil) and (Noeud.NextSibling <> nil) then Element.InsertBefore(E, Noeud.NextSibling)
    else Element.AppendChild(E);
  end;
  EcrireValeurXML(E, Especes);
  Noeud := Element.FirstChild;
  while Noeud <> nil do
  begin
    Suivant := Noeud.NextSibling;
    if (Noeud.NodeType = ELEMENT_NODE) and (Noeud.NodeName = 'Level') then Element.RemoveChild(Noeud);
    Noeud := Suivant;
  end;
  for N := 1 to NiveauMax do
  begin
    Niv := nil;
    for I := 0 to NbNatures - 1 do
      for R := 1 to FGrille.RowCount - 1 do
      begin
        Balise := BaliseNature(FGrille.Cells[1, R]);
        if (StrToIntDef(Trim(FGrille.Cells[0, R]), 0) <> N) or (Balise <> BalisesNature[I]) then Continue;
        if Niv = nil then
        begin
          Niv := Doc.CreateElement('Level');
          Niv.SetAttribute('id', IntToStr(N));
          Element.AppendChild(Niv);
          E := Doc.CreateElement('Order');
          Niv.AppendChild(E);
          EcrireValeurXML(E, IntToStr(N));
        end;
        ListeNature(Balise, Libs, Codes);
        Retire := CodeDe(Libs, Codes, FGrille.Cells[2, R]);
        Ajoute := CodeDe(Libs, Codes, FGrille.Cells[3, R]);
        Bloc := Doc.CreateElement(Balise);
        Niv.AppendChild(Bloc);
        if Retire <> '' then
        begin
          E := Doc.CreateElement('Remove');
          Bloc.AppendChild(E);
          EcrireValeurXML(E, Retire);
        end;
        if Ajoute <> '' then
        begin
          E := Doc.CreateElement('Add');
          Bloc.AppendChild(E);
          EcrireValeurXML(E, Ajoute);
        end;
      end;
  end;
end;

function TPanelAdaptation.Signature(const Sep: String): String;
var
  R, C: Integer;
begin
  Result := '';
  for R := 1 to FGrilleEsp.RowCount - 1 do
    Result := Result + Sep + FGrilleEsp.Cells[0, R];
  for R := 1 to FGrille.RowCount - 1 do
    for C := 0 to 3 do
      Result := Result + Sep + FGrille.Cells[C, R];
end;

procedure TPanelAdaptation.MettreLectureSeule(Valeur: Boolean);
begin
  FLectureSeule := Valeur;
  if Valeur then
  begin
    FGrille.Options := FGrille.Options - [goEditing];
    FGrilleEsp.Options := FGrilleEsp.Options - [goEditing];
  end
  else
  begin
    FGrille.Options := FGrille.Options + [goEditing];
    FGrilleEsp.Options := FGrilleEsp.Options + [goEditing];
  end;
  Positionner(not Valeur);
end;

procedure TPanelAdaptation.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Items: TStringList;
  Libs, Codes: TStringList;
  I: Integer;
begin
  if FLectureSeule then Exit;
  if Sender = FGrilleEsp then
  begin
    if aRow < 1 then Exit;
    Editor := FGrilleEsp.EditorByStyle(cbsPickList);
    if not (Editor is TCustomComboBox) then Exit;
    TCustomComboBox(Editor).Style := csDropDown;  // une ethnie hors liste (autre livre) reste permise
    TCustomComboBox(Editor).Items.Assign(FEspLib);
    Exit;
  end;
  if (aRow < 1) or (aCol < 1) then Exit;
  Items := TStringList.Create;
  try
    if aCol = 1 then
    begin
      for I := 0 to NbNatures - 1 do
        Items.Add(LibNature(BalisesNature[I]));
    end
    else
    begin
      if not ListeNature(BaliseNature(FGrille.Cells[1, aRow]), Libs, Codes) then Exit;
      Items.Add('');  // case vide : simple ajout ou simple retrait
      Items.AddStrings(Libs);
    end;
    Editor := FGrille.EditorByStyle(cbsPickList);
    if not (Editor is TCustomComboBox) then Exit;
    // nature : liste fermee ; element : liste ouverte, un texte libre est permis
    if aCol = 1 then TCustomComboBox(Editor).Style := csDropDownList
    else TCustomComboBox(Editor).Style := csDropDown;
    TCustomComboBox(Editor).Items.Assign(Items);
  finally
    Items.Free;
  end;
end;

procedure TPanelAdaptation.BoutonAjouterClick(Sender: TObject);
var
  R, N: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  N := 1;
  if R > 1 then N := StrToIntDef(Trim(FGrille.Cells[0, R - 1]), 1);
  FGrille.Cells[0, R] := IntToStr(N);
  FGrille.Cells[1, R] := LibNature('Skill');
  FGrille.Cells[2, R] := '';
  FGrille.Cells[3, R] := '';
  FGrille.Row := R;
end;

procedure TPanelAdaptation.BoutonAjEspClick(Sender: TObject);
begin
  FGrilleEsp.EditorMode := False;
  FGrilleEsp.RowCount := FGrilleEsp.RowCount + 1;
  FGrilleEsp.Cells[0, FGrilleEsp.RowCount - 1] := '';
  FGrilleEsp.Row := FGrilleEsp.RowCount - 1;
end;

procedure TPanelAdaptation.BoutonRetEspClick(Sender: TObject);
begin
  FGrilleEsp.EditorMode := False;
  if (FGrilleEsp.Row >= 1) and (FGrilleEsp.RowCount > 1) then FGrilleEsp.DeleteRow(FGrilleEsp.Row);
end;

procedure TPanelAdaptation.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.RowCount > 1) then FGrille.DeleteRow(FGrille.Row);
end;

end.

unit PanelSigneEffets;

{$mode ObjFPC}{$H+}

// Effets d'un signe astral (DATA_STARSIGN) dans sa fiche : une ligne <Modifier name="RULES-ATTR_x">"2"</Modifier>
// par caracteristique modifiee. Les <Modifier> des <Variant> ne sont pas touches (CONTEXT.md 2.107, signes astraux).
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelSigneEffets = class(TPanelExtraFiche)
  private
    FTitre: TLabel;
    FGrille: TStringGrid;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FLibAttribut: TFonctionLibelle;
    FCodes, FLibelles: TStringList;
    FLectureSeule: Boolean;
    function  CodeDe(const Lib: String): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton; ALibAttribut: TFonctionLibelle);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  // caracteristiques que modifie un signe (les dix principales)
  CodesAttribut: array[0..9] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel');
  HauteurEffets = 190;

constructor TPanelSigneEffets.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCodes := TStringList.Create;
  FLibelles := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurEffets;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 400, 20);
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.SetBounds(0, 24, 400, 120);
  FGrille.ColCount := 2;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.ColWidths[0] := 250;
  FGrille.ColWidths[1] := 120;
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  Visible := False;
end;

destructor TPanelSigneEffets.Destroy;
begin
  FCodes.Free;
  FLibelles.Free;
  inherited Destroy;
end;

procedure TPanelSigneEffets.Initialiser(Modele: TBCButton; ALibAttribut: TFonctionLibelle);
  function Copie(const Legende: String; Clic: TNotifyEvent; Gauche, Largeur: Integer): TBCButton;
  begin
    Result := TBCButtonContour.Create(Self);
    Result.Assign(Modele);
    Result.Parent := Self;
    Result.Caption := Legende;
    Result.OnClick := Clic;
    Result.SetBounds(Gauche, 150, Largeur, 32);
  end;
begin
  FLibAttribut := ALibAttribut;
  FBoutonAjouter := Copie(GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 190);
  FBoutonRetirer := Copie(GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 200, 200);
  FTitre.Caption := GetTexteLibelle('RULES-LAB_538', 'Characteristic modifiers');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_008', 'Attribute');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_025', 'Value');
  MiseAJourUnContenaire(Self);
end;

function TPanelSigneEffets.CodeDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FLibelles.IndexOf(Lib);
  if I >= 0 then Result := FCodes[I];
end;

procedure TPanelSigneEffets.Charger(Element: TDOMElement);
var
  N: TDOMNode;
  Code, Lib: String;
  I, R: Integer;
begin
  FGrille.EditorMode := False;
  FCodes.Clear;
  FLibelles.Clear;
  for I := 0 to High(CodesAttribut) do
  begin
    FCodes.Add('RULES-ATTR_' + CodesAttribut[I]);
    FLibelles.Add(FLibAttribut('RULES-ATTR_' + CodesAttribut[I]));
  end;
  FGrille.RowCount := 1;
  N := Element.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Modifier') then
    begin
      Code := TDOMElement(N).GetAttribute('name');
      I := FCodes.IndexOf(Code);
      if I >= 0 then Lib := FLibelles[I] else Lib := Code;
      R := FGrille.RowCount;
      FGrille.RowCount := R + 1;
      FGrille.Cells[0, R] := Lib;
      FGrille.Cells[1, R] := ValeurXML(N);
      // une caracteristique hors de la liste proposee reste choisissable
      if I < 0 then
      begin
        FCodes.Add(Code);
        FLibelles.Add(Lib);
      end;
    end;
    N := N.NextSibling;
  end;
end;

function TPanelSigneEffets.Controler: Boolean;
var
  R, R2: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if CodeDe(Trim(FGrille.Cells[0, R])) = '' then
    begin
      ShowMessage(Format('%d : ', [R]) + GetTexteLibelle('RULES-LAB_404'));
      Exit(False);
    end;
    if StrToIntDef(Trim(FGrille.Cells[1, R]), 0) = 0 then
    begin
      ShowMessage(Format('%d : ', [R]) + GetTexteLibelle('RULES-LAB_418'));
      Exit(False);
    end;
    for R2 := 1 to R - 1 do
      if Trim(FGrille.Cells[0, R2]) = Trim(FGrille.Cells[0, R]) then
      begin
        ShowMessage(Format('%d : ', [R]) + FGrille.Cells[0, R]);
        Exit(False);
      end;
  end;
end;

// Les <Modifier> propres au signe (pas ceux des <Variant>) sont reecrits en fin d'element, apres les <Variant>.
procedure TPanelSigneEffets.Ecrire(Element: TDOMElement);
var
  N, Suivant: TDOMNode;
  E: TDOMElement;
  R: Integer;
begin
  FGrille.EditorMode := False;
  N := Element.FirstChild;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Modifier') then
      Element.RemoveChild(N);
    N := Suivant;
  end;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    E := Element.OwnerDocument.CreateElement('Modifier');
    E.SetAttribute('name', CodeDe(Trim(FGrille.Cells[0, R])));
    Element.AppendChild(E);
    EcrireValeurXML(E, IntToStr(StrToIntDef(Trim(FGrille.Cells[1, R]), 0)));
  end;
end;

function TPanelSigneEffets.Signature(const Sep: String): String;
var
  R: Integer;
begin
  Result := '';
  for R := 1 to FGrille.RowCount - 1 do
    Result := Result + Sep + FGrille.Cells[0, R] + Sep + FGrille.Cells[1, R];
end;

procedure TPanelSigneEffets.MettreLectureSeule(Valeur: Boolean);
begin
  FLectureSeule := Valeur;
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBoutonAjouter.Visible := not Valeur;
  FBoutonRetirer.Visible := not Valeur;
end;

procedure TPanelSigneEffets.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if (aCol <> 0) or (aRow < 1) or FLectureSeule then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FLibelles);
end;

procedure TPanelSigneEffets.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Cells[1, R] := '1';
  FGrille.Row := R;
  FGrille.Col := 0;
end;

procedure TPanelSigneEffets.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
end;

end.

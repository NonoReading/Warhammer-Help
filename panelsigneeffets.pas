unit PanelSigneEffets;

{$mode ObjFPC}{$H+}

// Effets d'un signe astral (DATA_STARSIGN) dans sa fiche : une ligne <Modifier name="RULES-ATTR_x">"2"</Modifier>
// par caracteristique modifiee. Les <Modifier> des <Variant> ne sont pas touches (CONTEXT.md 2.107, signes astraux).
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelSigneEffets = class(TPanelExtraFiche)
  private
    FTitre: TLabel;
    FGrille: TStringGrid;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FTitreVar: TLabel;
    FGrilleVar: TStringGrid;  // variantes (sous-tirage) : une ligne par <Modifier> de chaque <Variant range>
    FBoutonAjouterVar, FBoutonRetirerVar: TBCButton;
    FLibAttribut, FLibTalent: TFonctionLibelle;
    FCodes, FLibelles: TStringList;
    FTalCodes, FTalLibelles: TStringList;  // talents des variantes chargees : libelle <-> code
    FLectureSeule: Boolean;
    function  CodeTalentDe(const Lib: String): String;
    function  CodeDe(const Lib: String): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleVarSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonAjouterVarClick(Sender: TObject);
    procedure BoutonRetirerVarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton; ALibAttribut, ALibTalent: TFonctionLibelle);
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
  HauteurTotale = 390;  // effets du signe + variantes

constructor TPanelSigneEffets.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCodes := TStringList.Create;
  FLibelles := TStringList.Create;
  FTalCodes := TStringList.Create;
  FTalLibelles := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurTotale;
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
  FTitreVar := TLabelContour.Create(Self);
  FTitreVar.Parent := Self;
  FTitreVar.SetBounds(0, HauteurEffets, 400, 20);
  FGrilleVar := TStringGrid.Create(Self);
  FGrilleVar.Parent := Self;
  CouleurSelectionGrille(FGrilleVar);
  FGrilleVar.SetBounds(0, HauteurEffets + 24, 560, 120);
  FGrilleVar.ColCount := 4;
  FGrilleVar.RowCount := 1;
  FGrilleVar.FixedRows := 1;
  FGrilleVar.FixedCols := 0;
  FGrilleVar.Options := FGrilleVar.Options + [goEditing] - [goRangeSelect];
  FGrilleVar.ColWidths[0] := 80;
  FGrilleVar.ColWidths[1] := 200;
  FGrilleVar.ColWidths[2] := 180;
  FGrilleVar.ColWidths[3] := 80;
  FGrilleVar.OnSelectEditor := @GrilleVarSelectEditor;
  Visible := False;
end;

destructor TPanelSigneEffets.Destroy;
begin
  FCodes.Free;
  FLibelles.Free;
  FTalCodes.Free;
  FTalLibelles.Free;
  inherited Destroy;
end;

procedure TPanelSigneEffets.Initialiser(Modele: TBCButton; ALibAttribut, ALibTalent: TFonctionLibelle);
  function Copie(const Legende: String; Clic: TNotifyEvent; Gauche, Haut, Largeur: Integer): TBCButton;
  begin
    Result := TBCButtonContour.Create(Self);
    Result.Assign(Modele);
    Result.Parent := Self;
    Result.Caption := Legende;
    Result.OnClick := Clic;
    Result.SetBounds(Gauche, Haut, Largeur, 32);
  end;
begin
  FLibAttribut := ALibAttribut;
  FLibTalent := ALibTalent;
  FBoutonAjouter := Copie(GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 150, 190);
  FBoutonRetirer := Copie(GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 200, 150, 200);
  FBoutonAjouterVar := Copie(GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterVarClick, 0, HauteurEffets + 150, 190);
  FBoutonRetirerVar := Copie(GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerVarClick, 200, HauteurEffets + 150, 200);
  FTitre.Caption := GetTexteLibelle('RULES-LAB_538', 'Characteristic modifiers');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_008', 'Attribute');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_025', 'Value');
  FTitreVar.Caption := GetTexteLibelle('RULES-LAB_974', 'Variants (sub-roll)');
  FGrilleVar.Cells[0, 0] := GetTexteLibelle('RULES-LAB_530', 'Range');
  FGrilleVar.Cells[1, 0] := GetTexteLibelle('RULES-LAB_007', 'Talent');
  FGrilleVar.Cells[2, 0] := GetTexteLibelle('RULES-LAB_008', 'Attribute');
  FGrilleVar.Cells[3, 0] := GetTexteLibelle('RULES-LAB_025', 'Value');
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

function TPanelSigneEffets.CodeTalentDe(const Lib: String): String;
var
  I: Integer;
begin
  I := FTalLibelles.IndexOf(Lib);
  if I >= 0 then Result := FTalCodes[I] else Result := Lib;  // libelle inconnu : saisi tel quel comme code
end;

procedure TPanelSigneEffets.Charger(Element: TDOMElement);
var
  N, V, M: TDOMNode;
  Code, Lib, LibTal, Plage: String;
  I, R: Integer;
  Vide: Boolean;
begin
  FGrilleVar.EditorMode := False;
  FGrilleVar.RowCount := 1;
  FTalCodes.Clear;
  FTalLibelles.Clear;
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
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Variant') then
    begin
      Plage := TDOMElement(N).GetAttribute('range');
      Code := '';
      LibTal := '';
      V := N.FirstChild;
      while V <> nil do
      begin
        if (V.NodeType = ELEMENT_NODE) and (V.NodeName = 'Talent') then
        begin
          Code := ValeurXML(V);
          LibTal := FLibTalent(Code);
          if FTalCodes.IndexOf(Code) < 0 then
          begin
            FTalCodes.Add(Code);
            FTalLibelles.Add(LibTal);
          end;
        end;
        V := V.NextSibling;
      end;
      // une ligne par <Modifier> ; une variante sans <Modifier> garde une ligne a caracteristique vide
      Vide := True;
      M := N.FirstChild;
      while M <> nil do
      begin
        if (M.NodeType = ELEMENT_NODE) and (M.NodeName = 'Modifier') then
        begin
          Vide := False;
          R := FGrilleVar.RowCount;
          FGrilleVar.RowCount := R + 1;
          FGrilleVar.Cells[0, R] := Plage;
          FGrilleVar.Cells[1, R] := LibTal;
          I := FCodes.IndexOf(TDOMElement(M).GetAttribute('name'));
          if I >= 0 then Lib := FLibelles[I] else Lib := TDOMElement(M).GetAttribute('name');
          if I < 0 then
          begin
            FCodes.Add(TDOMElement(M).GetAttribute('name'));
            FLibelles.Add(Lib);
          end;
          FGrilleVar.Cells[2, R] := Lib;
          FGrilleVar.Cells[3, R] := ValeurXML(M);
        end;
        M := M.NextSibling;
      end;
      if Vide then
      begin
        R := FGrilleVar.RowCount;
        FGrilleVar.RowCount := R + 1;
        FGrilleVar.Cells[0, R] := Plage;
        FGrilleVar.Cells[1, R] := LibTal;
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
  FGrilleVar.EditorMode := False;
  for R := 1 to FGrilleVar.RowCount - 1 do
  begin
    if Trim(FGrilleVar.Cells[0, R]) = '' then
    begin
      ShowMessage(Format('%d : ', [R]) + GetTexteLibelle('RULES-LAB_404'));
      Exit(False);
    end;
    // caracteristique et valeur vont ensemble ; une ligne sans les deux est une variante sans effet
    if (Trim(FGrilleVar.Cells[2, R]) <> '') and ((CodeDe(Trim(FGrilleVar.Cells[2, R])) = '') or (StrToIntDef(Trim(FGrilleVar.Cells[3, R]), 0) = 0)) then
    begin
      ShowMessage(Format('%d : ', [R]) + GetTexteLibelle('RULES-LAB_418'));
      Exit(False);
    end;
  end;
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

// Les <Modifier> propres au signe (pas ceux des <Variant>) sont reecrits en fin d'element, apres les <Variant>,
// qui sont eux aussi reconstruits : les lignes de meme plage forment une seule <Variant>.
procedure TPanelSigneEffets.Ecrire(Element: TDOMElement);
var
  N, Suivant: TDOMNode;
  E, Var_, T: TDOMElement;
  R: Integer;
  Plage: String;
begin
  FGrille.EditorMode := False;
  FGrilleVar.EditorMode := False;
  N := Element.FirstChild;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and ((N.NodeName = 'Modifier') or (N.NodeName = 'Variant')) then
      Element.RemoveChild(N);
    N := Suivant;
  end;
  Var_ := nil;
  Plage := '';
  for R := 1 to FGrilleVar.RowCount - 1 do
  begin
    if (Var_ = nil) or (Trim(FGrilleVar.Cells[0, R]) <> Plage) then
    begin
      Plage := Trim(FGrilleVar.Cells[0, R]);
      Var_ := Element.OwnerDocument.CreateElement('Variant');
      Var_.SetAttribute('range', Plage);
      Element.AppendChild(Var_);
    end;
    if (Trim(FGrilleVar.Cells[1, R]) <> '') and (Var_.FindNode('Talent') = nil) then
    begin
      T := Element.OwnerDocument.CreateElement('Talent');
      Var_.AppendChild(T);
      EcrireValeurXML(T, CodeTalentDe(Trim(FGrilleVar.Cells[1, R])));
    end;
    if Trim(FGrilleVar.Cells[2, R]) <> '' then
    begin
      T := Element.OwnerDocument.CreateElement('Modifier');
      T.SetAttribute('name', CodeDe(Trim(FGrilleVar.Cells[2, R])));
      Var_.AppendChild(T);
      EcrireValeurXML(T, IntToStr(StrToIntDef(Trim(FGrilleVar.Cells[3, R]), 0)));
    end;
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
  for R := 1 to FGrilleVar.RowCount - 1 do
    Result := Result + Sep + FGrilleVar.Cells[0, R] + Sep + FGrilleVar.Cells[1, R] + Sep + FGrilleVar.Cells[2, R] + Sep + FGrilleVar.Cells[3, R];
end;

procedure TPanelSigneEffets.MettreLectureSeule(Valeur: Boolean);
begin
  FLectureSeule := Valeur;
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  if Valeur then
    FGrilleVar.Options := FGrilleVar.Options - [goEditing]
  else
    FGrilleVar.Options := FGrilleVar.Options + [goEditing];
  FBoutonAjouter.Visible := not Valeur;
  FBoutonRetirer.Visible := not Valeur;
  FBoutonAjouterVar.Visible := not Valeur;
  FBoutonRetirerVar.Visible := not Valeur;
end;

procedure TPanelSigneEffets.GrilleVarSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if (aCol <> 2) or (aRow < 1) or FLectureSeule then Exit;
  Editor := FGrilleVar.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FLibelles);
end;

procedure TPanelSigneEffets.BoutonAjouterVarClick(Sender: TObject);
var
  R: Integer;
begin
  FGrilleVar.EditorMode := False;
  R := FGrilleVar.RowCount;
  FGrilleVar.RowCount := R + 1;
  FGrilleVar.Row := R;
  FGrilleVar.Col := 0;
end;

procedure TPanelSigneEffets.BoutonRetirerVarClick(Sender: TObject);
begin
  FGrilleVar.EditorMode := False;
  if (FGrilleVar.Row >= 1) and (FGrilleVar.Row < FGrilleVar.RowCount) then
    FGrilleVar.DeleteRow(FGrilleVar.Row);
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

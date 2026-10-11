unit PanelOpinions;

{$mode ObjFPC}{$H+}

// Opinions d'une RACE sur les autres races (bloc <OPINIONS> de DATA_RACE, CONTEXT.md 2.107) dans la fiche de la race :
// une ligne <Opinion target="RACE" source="qui parle">citation</Opinion> par race visee. La cible est une race (pas une
// ethnie) et une race n'a qu'une seule source d'opinions : une ethnie affiche celles de sa race, sans surcharge
// (decision Nono, 08/10/2026). La citation s'ecrit sans guillemets, comme dans les livres existants.
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelOpinions = class(TPanelExtraFiche)
  private
    FTitre, FTitreTexte: TLabel;
    FGrille: TStringGrid;
    FTexte: TMemo;  // le texte de l'opinion de la ligne choisie : trop long pour une cellule
    FChargement: Boolean;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FCodes, FLibelles: TStringList;
    FLectureSeule: Boolean;
    function  CodeDe(const Lib: String): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSelection(Sender: TObject; aCol, aRow: Integer);
    procedure TexteChange(Sender: TObject);
    procedure AfficherTexte;
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger : les races proposees comme cible (codes et libelles de meme rang).
    procedure Configurer(Codes, Libelles: TStrings);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  HauteurOpinions = 400;

constructor TPanelOpinions.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCodes := TStringList.Create;
  FLibelles := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurOpinions;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 600, 20);
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.SetBounds(0, 24, 800, 150);
  FGrille.ColCount := 3;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.ColWidths[0] := 190;
  FGrille.ColWidths[1] := 250;
  FGrille.ColWidths[2] := 320;
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.OnSelectCell := @GrilleSelectCell;
  FGrille.OnSelection := @GrilleSelection;
  FTitreTexte := TLabelContour.Create(Self);
  FTitreTexte.Parent := Self;
  FTitreTexte.SetBounds(0, 182, 600, 20);
  FTexte := TMemo.Create(Self);
  FTexte.Parent := Self;
  FTexte.SetBounds(0, 204, 800, 130);
  FTexte.WordWrap := True;
  FTexte.ScrollBars := ssVertical;
  FTexte.OnChange := @TexteChange;
  Visible := False;
end;

destructor TPanelOpinions.Destroy;
begin
  FCodes.Free;
  FLibelles.Free;
  inherited Destroy;
end;

procedure TPanelOpinions.Initialiser(Modele: TBCButton);
  function Copie(const Legende: String; Clic: TNotifyEvent; Gauche, Largeur: Integer): TBCButton;
  begin
    Result := TBCButtonContour.Create(Self);
    Result.Assign(Modele);
    Result.Parent := Self;
    Result.Caption := Legende;
    Result.OnClick := Clic;
    Result.SetBounds(Gauche, 344, Largeur, 40);
  end;
begin
  FBoutonAjouter := Copie(GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230);
  FBoutonRetirer := Copie(GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250);
  FTitre.Caption := GetTexteLibelle('RULES-LAB_594', 'Opinions about other races');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_595', 'About the race');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_596', 'Who speaks');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_597', 'Opinion');
  FTitreTexte.Caption := GetTexteLibelle('RULES-LAB_597', 'Opinion');
  MiseAJourUnContenaire(Self);
end;

procedure TPanelOpinions.Configurer(Codes, Libelles: TStrings);
begin
  FCodes.Assign(Codes);
  FLibelles.Assign(Libelles);
end;

function TPanelOpinions.CodeDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FLibelles.IndexOf(Lib);
  if I >= 0 then Result := FCodes[I];
end;

procedure TPanelOpinions.Charger(Element: TDOMElement);
var
  N, O: TDOMNode;
  Code, Lib: String;
  I, R: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  N := Element.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'OPINIONS') then
    begin
      O := N.FirstChild;
      while O <> nil do
      begin
        if (O.NodeType = ELEMENT_NODE) and (O.NodeName = 'Opinion') then
        begin
          Code := TDOMElement(O).GetAttribute('target');
          I := FCodes.IndexOf(Code);
          if I >= 0 then
            Lib := FLibelles[I]
          else
          begin
            // une cible hors de la liste proposee reste choisissable
            Lib := Code;
            FCodes.Add(Code);
            FLibelles.Add(Lib);
          end;
          R := FGrille.RowCount;
          FGrille.RowCount := R + 1;
          FGrille.Cells[0, R] := Lib;
          FGrille.Cells[1, R] := TDOMElement(O).GetAttribute('source');
          FGrille.Cells[2, R] := Trim(O.TextContent);
        end;
        O := O.NextSibling;
      end;
    end;
    N := N.NextSibling;
  end;
  if FGrille.RowCount > 1 then FGrille.Row := 1;
  AfficherTexte;
end;

function TPanelOpinions.Controler: Boolean;
var
  R, R2: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if CodeDe(Trim(FGrille.Cells[0, R])) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_598', 'Line %d: choose the race the opinion is about.'), [R]));
      Exit(False);
    end;
    if Trim(FGrille.Cells[2, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_599', 'Line %d: write the opinion.'), [R]));
      Exit(False);
    end;
    for R2 := 1 to R - 1 do
      if Trim(FGrille.Cells[0, R2]) = Trim(FGrille.Cells[0, R]) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_600', 'Lines %d and %d are about the same race.'), [R2, R]));
        Exit(False);
      end;
  end;
end;

// Le bloc <OPINIONS> est reecrit en entier, apres les autres balises de la race ; aucune ligne = pas de bloc.
procedure TPanelOpinions.Ecrire(Element: TDOMElement);
var
  N, Suivant: TDOMNode;
  Bloc, E: TDOMElement;
  Doc: TDOMDocument;
  R: Integer;
begin
  FGrille.EditorMode := False;
  Doc := Element.OwnerDocument;
  N := Element.FirstChild;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'OPINIONS') then
      Element.RemoveChild(N);
    N := Suivant;
  end;
  if FGrille.RowCount < 2 then Exit;
  Bloc := Doc.CreateElement('OPINIONS');
  Element.AppendChild(Bloc);
  for R := 1 to FGrille.RowCount - 1 do
  begin
    E := Doc.CreateElement('Opinion');
    E.SetAttribute('target', CodeDe(Trim(FGrille.Cells[0, R])));
    E.SetAttribute('source', Trim(FGrille.Cells[1, R]));
    E.AppendChild(Doc.CreateTextNode(Trim(FGrille.Cells[2, R])));
    Bloc.AppendChild(Doc.CreateTextNode(#10));
    Bloc.AppendChild(E);
  end;
  Bloc.AppendChild(Doc.CreateTextNode(#10));
end;

function TPanelOpinions.Signature(const Sep: String): String;
var
  R, C: Integer;
begin
  Result := '';
  for R := 1 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, R];
end;

procedure TPanelOpinions.MettreLectureSeule(Valeur: Boolean);
begin
  FLectureSeule := Valeur;
  FTexte.ReadOnly := Valeur;
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBoutonAjouter.Visible := not Valeur;
  FBoutonRetirer.Visible := not Valeur;
end;

procedure TPanelOpinions.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if (aCol <> 0) or (aRow < 1) or FLectureSeule then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FLibelles);
end;

// Le texte (colonne 2) ne se saisit que dans le champ du bas : la cellule n'est pas editable.
procedure TPanelOpinions.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if FLectureSeule then Exit;
  if aCol = 2 then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
end;

procedure TPanelOpinions.GrilleSelection(Sender: TObject; aCol, aRow: Integer);
begin
  AfficherTexte;
end;

procedure TPanelOpinions.AfficherTexte;
begin
  FChargement := True;
  try
    if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
      FTexte.Text := FGrille.Cells[2, FGrille.Row]
    else
      FTexte.Text := '';
    FTexte.Enabled := (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount);
  finally
    FChargement := False;
  end;
end;

// Une opinion tient sur une ligne du XML : les retours a la ligne saisis deviennent des espaces.
procedure TPanelOpinions.TexteChange(Sender: TObject);
begin
  if FChargement then Exit;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.Cells[2, FGrille.Row] := Trim(StringReplace(StringReplace(FTexte.Text, #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
end;

procedure TPanelOpinions.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Row := R;
  FGrille.Col := 0;
  AfficherTexte;
end;

procedure TPanelOpinions.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
  AfficherTexte;
end;

end.

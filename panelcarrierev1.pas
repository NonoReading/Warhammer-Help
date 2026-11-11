unit PanelCarriereV1;

{$mode ObjFPC}{$H+}

// Schema d'avancement et competences d'une carriere WFRP1 (DATA_CAREER_V1), sous les champs de sa fiche :
//   <AdvanceScheme><Advance name="RULES-ATTR_WS">"10"</Advance>...</AdvanceScheme>
//   <SUBCHAPTER_SKILL><Skill name="RULES-COMP_x">"100"</Skill>...</SUBCHAPTER_SKILL>
// Le code reste dans le XML, la grille montre le libelle ; seule la valeur se modifie, une ligne peut se retirer.
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TListeCarriereV1 = record
    Titre: TLabel;
    Grille: TStringGrid;
    Codes: TStringList;
    Chapitre, Item: String;
    Libelle: TFonctionLibelle;
  end;

  TPanelCarriereV1 = class(TPanelExtraFiche)
  private
    FListes: array[0..1] of TListeCarriereV1;
    FBoutonRetirer: array[0..1] of TBCButton;
    FMode: Integer;
    procedure Construire(I: Integer; const Chapitre, Item: String; Haut: Integer);
    procedure ChargerListe(I: Integer; Element: TDOMElement);
    procedure EcrireListe(I: Integer; Element: TDOMElement);
    procedure BoutonRetirerClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton; LibAttribut, LibCompetence: TFonctionLibelle);
    // 0 = les deux listes, 1 = schema d'avancement seul, 2 = competences seules
    procedure DefinirMode(Mode: Integer);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  HauteurListe = 190;

constructor TPanelCarriereV1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  Height := 2 * HauteurListe;
  Construire(0, 'AdvanceScheme', 'Advance', 0);
  Construire(1, 'SUBCHAPTER_SKILL', 'Skill', HauteurListe);
  Visible := False;
end;

destructor TPanelCarriereV1.Destroy;
begin
  FListes[0].Codes.Free;
  FListes[1].Codes.Free;
  inherited Destroy;
end;

procedure TPanelCarriereV1.Construire(I: Integer; const Chapitre, Item: String; Haut: Integer);
begin
  FListes[I].Chapitre := Chapitre;
  FListes[I].Item := Item;
  FListes[I].Codes := TStringList.Create;
  FListes[I].Titre := TLabelContour.Create(Self);
  FListes[I].Titre.Parent := Self;
  FListes[I].Titre.SetBounds(0, Haut, 400, 20);
  FListes[I].Grille := TStringGrid.Create(Self);
  FListes[I].Grille.Parent := Self;
  CouleurSelectionGrille(FListes[I].Grille);
  FListes[I].Grille.SetBounds(0, Haut + 24, 400, 120);
  FListes[I].Grille.ColCount := 2;
  FListes[I].Grille.RowCount := 1;
  FListes[I].Grille.FixedRows := 1;
  FListes[I].Grille.FixedCols := 0;
  FListes[I].Grille.Options := FListes[I].Grille.Options + [goEditing] - [goRangeSelect];
  FListes[I].Grille.ColWidths[0] := 250;
  FListes[I].Grille.ColWidths[1] := 120;
end;

procedure TPanelCarriereV1.Initialiser(Modele: TBCButton; LibAttribut, LibCompetence: TFonctionLibelle);
var
  I: Integer;
begin
  FListes[0].Libelle := LibAttribut;
  FListes[1].Libelle := LibCompetence;
  FListes[0].Titre.Caption := GetTexteLibelle('RULES-LAB_008', 'Attribute');
  FListes[1].Titre.Caption := GetTexteLibelle('RULES-LAB_009', 'Skill');
  for I := 0 to 1 do
  begin
    FListes[I].Grille.Cells[0, 0] := FListes[I].Titre.Caption;
    FListes[I].Grille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_025', 'Value');
    FBoutonRetirer[I] := TBCButtonContour.Create(Self);
    FBoutonRetirer[I].Assign(Modele);
    FBoutonRetirer[I].Parent := Self;
    FBoutonRetirer[I].Caption := GetTexteLibelle('RULES-LAB_421');
    FBoutonRetirer[I].Tag := I;
    FBoutonRetirer[I].OnClick := @BoutonRetirerClick;
    FBoutonRetirer[I].SetBounds(0, I * HauteurListe + 150, 200, 32);
  end;
  MiseAJourUnContenaire(Self);
end;

procedure TPanelCarriereV1.DefinirMode(Mode: Integer);
var
  I, Haut: Integer;
begin
  FMode := Mode;
  Haut := 0;
  for I := 0 to 1 do
  begin
    FListes[I].Titre.Visible := (Mode = 0) or (Mode = I + 1);
    FListes[I].Grille.Visible := FListes[I].Titre.Visible;
    if FBoutonRetirer[I] <> nil then FBoutonRetirer[I].Visible := FListes[I].Titre.Visible;
    if not FListes[I].Titre.Visible then Continue;
    FListes[I].Titre.SetBounds(0, Haut, 400, 20);
    FListes[I].Grille.SetBounds(0, Haut + 24, 400, 120);
    if FBoutonRetirer[I] <> nil then FBoutonRetirer[I].SetBounds(0, Haut + 150, 200, 32);
    Haut := Haut + HauteurListe;
  end;
  Height := Haut;
end;

procedure TPanelCarriereV1.ChargerListe(I: Integer; Element: TDOMElement);
var
  Chapitre, N: TDOMNode;
  R: Integer;
  Code: String;
begin
  FListes[I].Grille.EditorMode := False;
  FListes[I].Grille.RowCount := 1;
  FListes[I].Codes.Clear;
  Chapitre := Element.FindNode(FListes[I].Chapitre);
  if Chapitre = nil then Exit;
  N := Chapitre.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = FListes[I].Item) then
    begin
      Code := TDOMElement(N).GetAttribute('name');
      R := FListes[I].Grille.RowCount;
      FListes[I].Grille.RowCount := R + 1;
      FListes[I].Codes.Add(Code);
      FListes[I].Grille.Cells[0, R] := FListes[I].Libelle(Code);
      FListes[I].Grille.Cells[1, R] := ValeurXML(N);
    end;
    N := N.NextSibling;
  end;
end;

procedure TPanelCarriereV1.Charger(Element: TDOMElement);
begin
  if (FMode = 0) or (FMode = 1) then ChargerListe(0, Element);
  if (FMode = 0) or (FMode = 2) then ChargerListe(1, Element);
end;

function TPanelCarriereV1.Controler: Boolean;
begin
  FListes[0].Grille.EditorMode := False;
  FListes[1].Grille.EditorMode := False;
  Result := True;
end;

procedure TPanelCarriereV1.EcrireListe(I: Integer; Element: TDOMElement);
var
  Chapitre, N, Suivant: TDOMNode;
  E: TDOMElement;
  R: Integer;
  Apres: String;
begin
  FListes[I].Grille.EditorMode := False;
  Chapitre := Element.FindNode(FListes[I].Chapitre);
  if Chapitre = nil then
  begin
    if FListes[I].Codes.Count = 0 then Exit;
    Chapitre := Element.OwnerDocument.CreateElement(FListes[I].Chapitre);
    // ordre du schema : AdvanceScheme, Skills, SUBCHAPTER_SKILL, Trappings, SUBCHAPTER_ITEM, StartMoney, Entries...
    if FListes[I].Chapitre = 'AdvanceScheme' then Apres := ',Skills,SUBCHAPTER_SKILL,Trappings,SUBCHAPTER_ITEM,StartMoney,Entries,Exits,ExitCodes,Source,Page,'
    else Apres := ',Trappings,SUBCHAPTER_ITEM,StartMoney,Entries,Exits,ExitCodes,Source,Page,';
    Suivant := Element.FirstChild;
    while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and (Pos(',' + Suivant.NodeName + ',', Apres) > 0)) do
      Suivant := Suivant.NextSibling;
    Element.InsertBefore(Chapitre, Suivant);
  end;
  N := Chapitre.FirstChild;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = FListes[I].Item) then
      Chapitre.RemoveChild(N);
    N := Suivant;
  end;
  for R := 1 to FListes[I].Grille.RowCount - 1 do
  begin
    E := Element.OwnerDocument.CreateElement(FListes[I].Item);
    E.SetAttribute('name', FListes[I].Codes[R - 1]);
    Chapitre.AppendChild(E);
    EcrireValeurXML(E, Trim(FListes[I].Grille.Cells[1, R]));
  end;
end;

procedure TPanelCarriereV1.Ecrire(Element: TDOMElement);
begin
  if (FMode = 0) or (FMode = 1) then EcrireListe(0, Element);
  if (FMode = 0) or (FMode = 2) then EcrireListe(1, Element);
end;

function TPanelCarriereV1.Signature(const Sep: String): String;
var
  I, R: Integer;
begin
  Result := '';
  for I := 0 to 1 do
    if (FMode = 0) or (FMode = I + 1) then
    for R := 1 to FListes[I].Grille.RowCount - 1 do
      Result := Result + Sep + FListes[I].Grille.Cells[0, R] + Sep + FListes[I].Grille.Cells[1, R];
end;

procedure TPanelCarriereV1.MettreLectureSeule(Valeur: Boolean);
var
  I: Integer;
begin
  for I := 0 to 1 do
  begin
    if Valeur then
      FListes[I].Grille.Options := FListes[I].Grille.Options - [goEditing]
    else
      FListes[I].Grille.Options := FListes[I].Grille.Options + [goEditing];
    FBoutonRetirer[I].Visible := (not Valeur) and ((FMode = 0) or (FMode = I + 1));
  end;
end;

procedure TPanelCarriereV1.BoutonRetirerClick(Sender: TObject);
var
  I: Integer;
begin
  I := TBCButton(Sender).Tag;
  FListes[I].Grille.EditorMode := False;
  if (FListes[I].Grille.Row >= 1) and (FListes[I].Grille.Row < FListes[I].Grille.RowCount) then
  begin
    FListes[I].Codes.Delete(FListes[I].Grille.Row - 1);
    FListes[I].Grille.DeleteRow(FListes[I].Grille.Row);
  end;
end;

end.

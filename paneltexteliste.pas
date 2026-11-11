unit PanelTexteListe;

{$mode ObjFPC}{$H+}

// Tableau a une colonne pour une balise dont le texte est une liste de mots separes par des virgules :
//   <Qualities>"Balanced, Defensive, Pummelling"</Qualities>   (arme WFRP2)
// Chaque mot est une ligne ; la cellule propose une liste deroulante de choix (saisie libre permise : tailles, notes...).
// A l'enregistrement les lignes sont recollees avec « , » ; si le tableau n'a pas change, le texte d'origine est rendu tel quel.
// Une virgule entre parentheses ne coupe pas : « Special (1-h, 2-h) » reste une ligne.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelTexteListe = class(TPanelExtraFiche)
  private
    FBalise: String;
    FSuivantes: String;       // balises qui suivent celle-ci dans l'element (virgules) : une balise neuve se range avant
    FTitre: TLabel;
    FGrille: TStringGrid;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FChoix: TStringList;
    FOrigine: String;         // texte d'origine de la balise
    FSignatureOrigine: String;
    function  Texte: String;
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
  public
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton; const Balise, CodeTitre, Suivantes: String);
    // mots proposes dans la liste deroulante
    procedure DefinirChoix(Mots: TStrings);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

// Coupe le texte aux virgules hors parentheses.
procedure DecouperMots(const Texte: String; Mots: TStrings);
var
  I, Prof: Integer;
  Mot: String;
begin
  Mots.Clear;
  Prof := 0;
  Mot := '';
  for I := 1 to Length(Texte) do
  begin
    if Texte[I] = '(' then Inc(Prof)
    else if (Texte[I] = ')') and (Prof > 0) then Dec(Prof);
    if (Texte[I] = ',') and (Prof = 0) then
    begin
      if Trim(Mot) <> '' then Mots.Add(Trim(Mot));
      Mot := '';
    end
    else
      Mot := Mot + Texte[I];
  end;
  if Trim(Mot) <> '' then Mots.Add(Trim(Mot));
end;

destructor TPanelTexteListe.Destroy;
begin
  FChoix.Free;
  inherited Destroy;
end;

procedure TPanelTexteListe.Initialiser(Modele: TBCButton; const Balise, CodeTitre, Suivantes: String);
begin
  FBalise := Balise;
  FSuivantes := Suivantes;
  FChoix := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  Height := 190;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 400, 20);
  FTitre.Caption := GetTexteLibelle(CodeTitre, Balise);
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.ColCount := 1;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.Cells[0, 0] := GetTexteLibelle(CodeTitre, Balise);
  FGrille.ColWidths[0] := 300;
  FGrille.SetBounds(0, 24, 324, 120);
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := Self;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_899');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonAjouter.SetBounds(0, 150, 200, 32);
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := Self;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonRetirer.SetBounds(210, 150, 200, 32);
  Visible := False;
  MiseAJourUnContenaire(Self);
end;

procedure TPanelTexteListe.DefinirChoix(Mots: TStrings);
begin
  FChoix.Assign(Mots);
end;

procedure TPanelTexteListe.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if (aRow < 1) or (FChoix.Count = 0) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if Editor is TCustomComboBox then TCustomComboBox(Editor).Items.Assign(FChoix);
end;

procedure TPanelTexteListe.Charger(Element: TDOMElement);
var
  Mots: TStringList;
  I: Integer;
begin
  FGrille.EditorMode := False;
  FOrigine := ValeurXML(Element.FindNode(FBalise));
  Mots := TStringList.Create;
  try
    DecouperMots(FOrigine, Mots);
    FGrille.RowCount := 1 + Mots.Count;
    for I := 0 to Mots.Count - 1 do FGrille.Cells[0, I + 1] := Mots[I];
  finally
    Mots.Free;
  end;
  FSignatureOrigine := Texte;
end;

function TPanelTexteListe.Texte: String;
var
  R: Integer;
begin
  Result := '';
  for R := 1 to FGrille.RowCount - 1 do
    if Trim(FGrille.Cells[0, R]) <> '' then
    begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + Trim(FGrille.Cells[0, R]);
    end;
end;

function TPanelTexteListe.Controler: Boolean;
begin
  FGrille.EditorMode := False;
  Result := True;
end;

procedure TPanelTexteListe.Ecrire(Element: TDOMElement);
var
  Noeud: TDOMNode;
  Nouveau: TDOMElement;
  Suivant: TDOMNode;
  Valeur: String;
begin
  FGrille.EditorMode := False;
  Valeur := Texte;
  // tableau inchange : le texte d'origine (espaces, ordre) est rendu tel quel
  if Valeur = FSignatureOrigine then Valeur := FOrigine;
  Noeud := Element.FindNode(FBalise);
  if Noeud = nil then
  begin
    if Valeur = '' then Exit;
    Nouveau := Element.OwnerDocument.CreateElement(FBalise);
    Suivant := Element.FirstChild;
    while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and
          (Pos(',' + Suivant.NodeName + ',', ',' + FSuivantes + ',') > 0)) do
      Suivant := Suivant.NextSibling;
    Element.InsertBefore(Nouveau, Suivant);
    Noeud := Nouveau;
  end
  else if Valeur = '' then
  begin
    Noeud.ParentNode.RemoveChild(Noeud);
    Exit;
  end;
  EcrireValeurXML(TDOMElement(Noeud), Valeur);
end;

function TPanelTexteListe.Signature(const Sep: String): String;
begin
  Result := Sep + Texte;
end;

procedure TPanelTexteListe.MettreLectureSeule(Valeur: Boolean);
begin
  if Valeur then FGrille.Options := FGrille.Options - [goEditing]
  else FGrille.Options := FGrille.Options + [goEditing];
  FBoutonAjouter.Visible := not Valeur;
  FBoutonRetirer.Visible := not Valeur;
end;

procedure TPanelTexteListe.BoutonAjouterClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := FGrille.RowCount + 1;
  FGrille.Row := FGrille.RowCount - 1;
end;

procedure TPanelTexteListe.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then FGrille.DeleteRow(FGrille.Row);
end;

end.

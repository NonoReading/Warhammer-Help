unit PanelLignesV1;

{$mode ObjFPC}{$H+}

// Tableau generique d'un element WFRP1 dont une balise porte des lignes, une balise par ligne et un sous-element par colonne :
//   <CombatModifiers><CombatModifier><Stat>"RULES-V1MOD_DAMAGE"</Stat><Value>"-2"</Value></CombatModifier>...
//   <RangeBands><RangeBand><Band>"RULES-V1RANGE_SHORT"</Band><Distance>"12"</Distance><Strength>"3"</Strength></RangeBand>...
// La premiere colonne peut proposer des choix : elle s'affiche par libelle, le XML garde le code.
// Les autres colonnes sont libres. Une ligne a besoin au moins de ses deux premieres colonnes.
// Tableau inchange : le XML d'origine n'est pas touche.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelLignesV1 = class(TPanelExtraFiche)
  private
    FBalise: String;          // balise du tableau (CombatModifiers)
    FLigneBalise: String;     // balise d'une ligne (CombatModifier)
    FSuivantes: String;       // balises qui suivent le tableau dans l'element (virgules)
    FColonnes: array of String;  // balise de chaque colonne
    FTitre: TLabel;
    FGrille: TStringGrid;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FLibelles: TStringList;   // choix de la premiere colonne : libelles, parallele a FCodes
    FCodes: TStringList;
    FSignatureOrigine: String;
    function  Texte: String;
    function  LibelleDe(const Code: String): String;
    function  CodeDe(const Libelle: String): String;
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
  public
    destructor Destroy; override;
    // Colonnes : « Balise|CodeLibelle » ; Choix : codes proposes dans la premiere colonne (vide = saisie libre)
    procedure Initialiser(Modele: TBCButton; const Balise, LigneBalise, CodeTitre, Suivantes: String;
      const Colonnes: array of String; const Choix: array of String);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

  // Plusieurs tableaux empiles dans le seul bloc « Extra » d'une fiche (modificateurs de combat puis bandes de portee).
  TPanelLignesMulti = class(TPanelExtraFiche)
  private
    FPanneaux: array of TPanelLignesV1;
  public
    procedure Ajouter(Panneau: TPanelLignesV1);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

procedure TPanelLignesMulti.Ajouter(Panneau: TPanelLignesV1);
begin
  SetLength(FPanneaux, Length(FPanneaux) + 1);
  FPanneaux[High(FPanneaux)] := Panneau;
  Panneau.Parent := Self;
  Panneau.Align := alNone;
  Panneau.SetBounds(0, (High(FPanneaux)) * Panneau.Height, 600, Panneau.Height);
  Panneau.Visible := True;
  BevelOuter := bvNone;
  Caption := '';
  Height := Length(FPanneaux) * Panneau.Height;
  Visible := False;
end;

procedure TPanelLignesMulti.Charger(Element: TDOMElement);
var
  I: Integer;
begin
  for I := 0 to High(FPanneaux) do FPanneaux[I].Charger(Element);
end;

function TPanelLignesMulti.Controler: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to High(FPanneaux) do
    if not FPanneaux[I].Controler then Result := False;
end;

procedure TPanelLignesMulti.Ecrire(Element: TDOMElement);
var
  I: Integer;
begin
  for I := 0 to High(FPanneaux) do FPanneaux[I].Ecrire(Element);
end;

function TPanelLignesMulti.Signature(const Sep: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FPanneaux) do Result := Result + FPanneaux[I].Signature(Sep);
end;

procedure TPanelLignesMulti.MettreLectureSeule(Valeur: Boolean);
var
  I: Integer;
begin
  for I := 0 to High(FPanneaux) do FPanneaux[I].MettreLectureSeule(Valeur);
end;

destructor TPanelLignesV1.Destroy;
begin
  FLibelles.Free;
  FCodes.Free;
  inherited Destroy;
end;

procedure TPanelLignesV1.Initialiser(Modele: TBCButton; const Balise, LigneBalise, CodeTitre, Suivantes: String;
  const Colonnes: array of String; const Choix: array of String);
var
  I, P, Larg: Integer;
begin
  FBalise := Balise;
  FLigneBalise := LigneBalise;
  FSuivantes := Suivantes;
  FLibelles := TStringList.Create;
  FCodes := TStringList.Create;
  for I := 0 to High(Choix) do
  begin
    FCodes.Add(Choix[I]);
    FLibelles.Add(GetTexteLibelle(Choix[I], Choix[I]));
  end;
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
  FGrille.ColCount := Length(Colonnes);
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  SetLength(FColonnes, Length(Colonnes));
  Larg := 0;
  for I := 0 to High(Colonnes) do
  begin
    P := Pos('|', Colonnes[I]);
    FColonnes[I] := Copy(Colonnes[I], 1, P - 1);
    FGrille.Cells[I, 0] := GetTexteLibelle(Copy(Colonnes[I], P + 1, MaxInt), FColonnes[I]);
    if I = 0 then FGrille.ColWidths[I] := 170 else FGrille.ColWidths[I] := 110;
    Larg := Larg + FGrille.ColWidths[I];
  end;
  FGrille.SetBounds(0, 24, Larg + 24, 120);
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

function TPanelLignesV1.LibelleDe(const Code: String): String;
var
  I: Integer;
begin
  I := FCodes.IndexOf(Code);
  if I >= 0 then Result := FLibelles[I] else Result := Code;
end;

function TPanelLignesV1.CodeDe(const Libelle: String): String;
var
  I: Integer;
begin
  I := FLibelles.IndexOf(Libelle);
  if I >= 0 then Result := FCodes[I] else Result := Libelle;
end;

procedure TPanelLignesV1.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if (aRow < 1) or (aCol <> 0) or (FLibelles.Count = 0) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if Editor is TCustomComboBox then TCustomComboBox(Editor).Items.Assign(FLibelles);
end;

procedure TPanelLignesV1.Charger(Element: TDOMElement);
var
  Noeud, Ligne: TDOMNode;
  R, C: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  Noeud := Element.FindNode(FBalise);
  if Noeud <> nil then
  begin
    Ligne := Noeud.FirstChild;
    while Ligne <> nil do
    begin
      if (Ligne.NodeType = ELEMENT_NODE) and (Ligne.NodeName = FLigneBalise) then
      begin
        R := FGrille.RowCount;
        FGrille.RowCount := R + 1;
        for C := 0 to High(FColonnes) do
          if C = 0 then FGrille.Cells[C, R] := LibelleDe(ValeurXML(Ligne.FindNode(FColonnes[C])))
          else FGrille.Cells[C, R] := ValeurXML(Ligne.FindNode(FColonnes[C]));
      end;
      Ligne := Ligne.NextSibling;
    end;
  end;
  FSignatureOrigine := Texte;
end;

function TPanelLignesV1.Texte: String;
var
  R, C: Integer;
  Vide: Boolean;
  Ligne: String;
begin
  Result := '';
  for R := 1 to FGrille.RowCount - 1 do
  begin
    Vide := True;
    Ligne := '';
    for C := 0 to High(FColonnes) do
    begin
      if Trim(FGrille.Cells[C, R]) <> '' then Vide := False;
      Ligne := Ligne + Trim(FGrille.Cells[C, R]) + '=';
    end;
    if not Vide then Result := Result + Ligne + '|';
  end;
end;

function TPanelLignesV1.Controler: Boolean;
begin
  FGrille.EditorMode := False;
  Result := True;
end;

procedure TPanelLignesV1.Ecrire(Element: TDOMElement);
var
  Noeud, Suivant, Ligne: TDOMNode;
  Doc: TDOMDocument;
  Racine, Cellule: TDOMElement;
  R, C: Integer;
begin
  FGrille.EditorMode := False;
  Noeud := Element.FindNode(FBalise);
  // inchange et balise deja la : XML d'origine intact (un element neuf, lui, recoit toujours le tableau)
  if (Noeud <> nil) and (Texte = FSignatureOrigine) then Exit;
  Doc := Element.OwnerDocument;
  Suivant := nil;
  if Noeud <> nil then
  begin
    Suivant := Noeud.NextSibling;
    Element.RemoveChild(Noeud);
  end
  else
  begin
    Suivant := Element.FirstChild;
    while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and
          (Pos(',' + Suivant.NodeName + ',', ',' + FSuivantes + ',') > 0)) do
      Suivant := Suivant.NextSibling;
  end;
  Racine := nil;
  for R := 1 to FGrille.RowCount - 1 do
    if (Trim(FGrille.Cells[0, R]) <> '') and ((Length(FColonnes) < 2) or (Trim(FGrille.Cells[1, R]) <> '')) then
    begin
      if Racine = nil then Racine := Doc.CreateElement(FBalise);
      Ligne := Doc.CreateElement(FLigneBalise);
      for C := 0 to High(FColonnes) do
        if (C < 2) or (Trim(FGrille.Cells[C, R]) <> '') then
        begin
          Cellule := Doc.CreateElement(FColonnes[C]);
          if C = 0 then EcrireValeurXML(Cellule, CodeDe(Trim(FGrille.Cells[C, R])))
          else EcrireValeurXML(Cellule, Trim(FGrille.Cells[C, R]));
          Ligne.AppendChild(Cellule);
        end;
      Racine.AppendChild(Ligne);
    end;
  if Racine <> nil then Element.InsertBefore(Racine, Suivant);
end;

function TPanelLignesV1.Signature(const Sep: String): String;
begin
  Result := Sep + Texte;
end;

procedure TPanelLignesV1.MettreLectureSeule(Valeur: Boolean);
begin
  if Valeur then FGrille.Options := FGrille.Options - [goEditing]
  else FGrille.Options := FGrille.Options + [goEditing];
  FBoutonAjouter.Visible := not Valeur;
  FBoutonRetirer.Visible := not Valeur;
end;

procedure TPanelLignesV1.BoutonAjouterClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := FGrille.RowCount + 1;
  FGrille.Row := FGrille.RowCount - 1;
end;

procedure TPanelLignesV1.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then FGrille.DeleteRow(FGrille.Row);
end;

end.

unit PanelListeChoix;

{$mode ObjFPC}{$H+}

// Liste de lignes d'une carriere WFRP2, un tableau par branche :
//   <SUBCHAPTER_SKILL><Skill name="RULES-COMP_A/RULES-COMP_B">"1"</Skill>...</SUBCHAPTER_SKILL>   (alternatives separees par « / »)
//   <SUBCHAPTER_TALENT>, <SUBCHAPTER_ITEM><Item name="...">"1"</Item>, <Advances><Advance name="RULES-ATTR_WS">"15"</Advance>
// Colonnes : une liste deroulante par alternative (la saisie libre reste possible : « 2d10 leaflets »), puis la valeur.
// Le texte du livre (<Skills>, <Talents>, <Trappings>) est rendu tel quel tant que le tableau n'a pas change,
// sinon il est refait a partir des libelles (« A or B » separes par des virgules).
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelListeChoix = class(TPanelExtraFiche)
  private
    FConteneur, FItem, FTexte: String;       // <SUBCHAPTER_SKILL> / Skill / Skills (FTexte = '' : pas de texte du livre)
    FApresConteneur, FApresTexte: String;    // balises qui suivent, pour ranger une balise neuve (virgules aux deux bouts)
    FNbAlt: Integer;
    FValeurVisible: Boolean;
    FValeurDefaut: String;
    FAttrValeur: String;                     // '' = la colonne valeur est le texte de la ligne ; sinon cet attribut (quantite)
    FOrigAttrs: TStringList;                 // autres attributs de chaque ligne (nom=valeur separes par #1)
    FLibelle: TFonctionLibelle;
    FChoix: TStringList;                     // code=libelle
    FTitre: TLabel;
    FGrille: TStringGrid;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FOrigNoms, FOrigValeurs, FCellulesInitiales: TStringList;
    FTexteOrigine, FSignatureInitiale: String;
    function  LibelleDe(const Code: String): String;
    function  CodeDe(const Texte: String): String;
    function  NomDeLigne(R: Integer): String;
    function  CellulesDeLigne(R: Integer): String;
    function  SignatureGrille: String;
    function  TexteDuLivre: String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton; const Conteneur, Item, Texte, ApresConteneur, ApresTexte: String;
      NbAlt: Integer; ValeurVisible: Boolean; const ValeurDefaut, AttrValeur: String; const IdTitre, IdValeur: String; Libelle: TFonctionLibelle);
    // propositions « code=libelle|code=libelle » (a appeler avant Charger)
    procedure Preparer(const Choix: String);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

constructor TPanelListeChoix.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChoix := TStringList.Create;
  FOrigNoms := TStringList.Create;
  FOrigValeurs := TStringList.Create;
  FCellulesInitiales := TStringList.Create;
  FOrigAttrs := TStringList.Create;
  FChoix.Delimiter := '|';
  FChoix.StrictDelimiter := True;
end;

destructor TPanelListeChoix.Destroy;
begin
  FChoix.Free;
  FOrigNoms.Free;
  FOrigValeurs.Free;
  FCellulesInitiales.Free;
  FOrigAttrs.Free;
  inherited Destroy;
end;

procedure TPanelListeChoix.Initialiser(Modele: TBCButton; const Conteneur, Item, Texte, ApresConteneur, ApresTexte: String;
  NbAlt: Integer; ValeurVisible: Boolean; const ValeurDefaut, AttrValeur: String; const IdTitre, IdValeur: String; Libelle: TFonctionLibelle);
var
  C: Integer;
begin
  FAttrValeur := AttrValeur;
  FConteneur := Conteneur;
  FItem := Item;
  FTexte := Texte;
  FApresConteneur := ApresConteneur;
  FApresTexte := ApresTexte;
  FNbAlt := NbAlt;
  FValeurVisible := ValeurVisible;
  FValeurDefaut := ValeurDefaut;
  FLibelle := Libelle;
  BevelOuter := bvNone;
  Caption := '';
  Height := 230;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 400, 20);
  FTitre.Caption := GetTexteLibelle(IdTitre);
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.ColCount := NbAlt + 1;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  for C := 0 to NbAlt - 1 do
  begin
    if C = 0 then FGrille.Cells[C, 0] := GetTexteLibelle(IdTitre)
    else FGrille.Cells[C, 0] := GetTexteLibelle('RULES-LAB_981', 'Or');
    FGrille.ColWidths[C] := 300;
  end;
  FGrille.Cells[NbAlt, 0] := GetTexteLibelle(IdValeur);
  if ValeurVisible then FGrille.ColWidths[NbAlt] := 110 else FGrille.ColWidths[NbAlt] := 0;
  FGrille.SetBounds(0, 24, NbAlt * 300 + FGrille.ColWidths[NbAlt] + 24, 150);
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := Self;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_899');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonAjouter.SetBounds(0, 184, 200, 32);
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := Self;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonRetirer.SetBounds(210, 184, 200, 32);
  Visible := False;
  MiseAJourUnContenaire(Self);
end;

procedure TPanelListeChoix.Preparer(const Choix: String);
begin
  FChoix.DelimitedText := Choix;
end;

function TPanelListeChoix.LibelleDe(const Code: String): String;
begin
  Result := '';
  if Code = '' then Exit;
  if FChoix.IndexOfName(Code) >= 0 then Result := FChoix.Values[Code];
  if (Result = '') and Assigned(FLibelle) then Result := FLibelle(Code);
  if Result = '' then Result := Code;
end;

// un libelle de la liste redevient son code ; toute autre saisie est gardee telle quelle
function TPanelListeChoix.CodeDe(const Texte: String): String;
var
  I: Integer;
begin
  Result := Trim(Texte);
  if Result = '' then Exit;
  for I := 0 to FChoix.Count - 1 do
    if FChoix.ValueFromIndex[I] = Result then
    begin
      Result := FChoix.Names[I];
      Exit;
    end;
end;

function TPanelListeChoix.CellulesDeLigne(R: Integer): String;
var
  C: Integer;
begin
  Result := '';
  for C := 0 to FNbAlt do Result := Result + #1 + Trim(FGrille.Cells[C, R]);
end;

function TPanelListeChoix.SignatureGrille: String;
var
  R: Integer;
begin
  Result := '';
  for R := 1 to FGrille.RowCount - 1 do Result := Result + #2 + CellulesDeLigne(R);
end;

// nom ecrit pour une ligne : l'origine si la ligne n'a pas bouge, sinon les alternatives rejointes par « / »
function TPanelListeChoix.NomDeLigne(R: Integer): String;
var
  C: Integer;
  Code: String;
begin
  if (R - 1 < FOrigNoms.Count) and (FOrigNoms[R - 1] <> '') and (R - 1 < FCellulesInitiales.Count)
    and (FCellulesInitiales[R - 1] = CellulesDeLigne(R)) then
  begin
    Result := FOrigNoms[R - 1];
    Exit;
  end;
  Result := '';
  for C := 0 to FNbAlt - 1 do
  begin
    Code := CodeDe(FGrille.Cells[C, R]);
    if Code = '' then Continue;
    if Result <> '' then Result := Result + '/';
    Result := Result + Code;
  end;
end;

procedure TPanelListeChoix.Charger(Element: TDOMElement);
var
  Conteneur, N: TDOMNode;
  R, C, P: Integer;
  Nom, Reste: String;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  FOrigNoms.Clear;
  FOrigValeurs.Clear;
  FCellulesInitiales.Clear;
  FOrigAttrs.Clear;
  if FTexte <> '' then FTexteOrigine := ValeurXML(Element.FindNode(FTexte)) else FTexteOrigine := '';
  Conteneur := Element.FindNode(FConteneur);
  if Conteneur <> nil then
  begin
    N := Conteneur.FirstChild;
    while N <> nil do
    begin
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = FItem) then
      begin
        R := FGrille.RowCount;
        FGrille.RowCount := R + 1;
        Nom := TDOMElement(N).GetAttribute('name');
        FOrigNoms.Add(Nom);
        FOrigValeurs.Add(ValeurXML(N));
        Reste := Nom;
        for C := 0 to FNbAlt - 1 do
        begin
          P := Pos('/', Reste);
          if (P = 0) or (C = FNbAlt - 1) then
          begin
            FGrille.Cells[C, R] := LibelleDe(Reste);
            Reste := '';
          end
          else
          begin
            FGrille.Cells[C, R] := LibelleDe(Copy(Reste, 1, P - 1));
            Reste := Copy(Reste, P + 1, MaxInt);
          end;
        end;
        // autres attributs de la ligne (hors name et hors colonne valeur) : gardes tels quels
        Reste := '';
        for P := 0 to TDOMElement(N).Attributes.Length - 1 do
          if (TDOMElement(N).Attributes[P].NodeName <> 'name') and (TDOMElement(N).Attributes[P].NodeName <> FAttrValeur) then
          begin
            if Reste <> '' then Reste := Reste + #1;
            Reste := Reste + TDOMElement(N).Attributes[P].NodeName + '=' + TDOMElement(N).Attributes[P].NodeValue;
          end;
        FOrigAttrs.Add(Reste);
        if FAttrValeur <> '' then FGrille.Cells[FNbAlt, R] := TDOMElement(N).GetAttribute(FAttrValeur)
        else FGrille.Cells[FNbAlt, R] := ValeurXML(N);
        FCellulesInitiales.Add(CellulesDeLigne(R));
      end;
      N := N.NextSibling;
    end;
  end;
  FSignatureInitiale := SignatureGrille;
end;

function TPanelListeChoix.Controler: Boolean;
begin
  FGrille.EditorMode := False;
  Result := True;
end;

// Texte du livre refait a partir du tableau : « A or B » separes par des virgules.
function TPanelListeChoix.TexteDuLivre: String;
var
  R, C: Integer;
  Ligne: String;
begin
  Result := '';
  for R := 1 to FGrille.RowCount - 1 do
  begin
    Ligne := '';
    for C := 0 to FNbAlt - 1 do
      if Trim(FGrille.Cells[C, R]) <> '' then
      begin
        if Ligne <> '' then Ligne := Ligne + ' or ';
        Ligne := Ligne + Trim(FGrille.Cells[C, R]);
      end;
    if Ligne = '' then Continue;
    if Result <> '' then Result := Result + ', ';
    Result := Result + Ligne;
  end;
end;

procedure TPanelListeChoix.Ecrire(Element: TDOMElement);
var
  Conteneur, N, Suivant: TDOMNode;
  E: TDOMElement;
  R, K: Integer;
  Nom, Valeur, Texte: String;
  Extras: TStringList;
begin
  FGrille.EditorMode := False;
  Conteneur := Element.FindNode(FConteneur);
  if (Conteneur = nil) and (FGrille.RowCount > 1) then
  begin
    Conteneur := Element.OwnerDocument.CreateElement(FConteneur);
    Suivant := Element.FirstChild;
    while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and (Pos(',' + Suivant.NodeName + ',', FApresConteneur) > 0)) do
      Suivant := Suivant.NextSibling;
    Element.InsertBefore(Conteneur, Suivant);
  end;
  if Conteneur <> nil then
  begin
    N := Conteneur.FirstChild;
    while N <> nil do
    begin
      Suivant := N.NextSibling;
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = FItem) then Conteneur.RemoveChild(N);
      N := Suivant;
    end;
    for R := 1 to FGrille.RowCount - 1 do
    begin
      Nom := NomDeLigne(R);
      if Nom = '' then Continue;
      Valeur := Trim(FGrille.Cells[FNbAlt, R]);
      E := Element.OwnerDocument.CreateElement(FItem);
      E.SetAttribute('name', Nom);
      if FAttrValeur <> '' then
      begin
        // la colonne est un attribut (quantite) ; le texte de la ligne garde sa valeur d'origine
        if Valeur <> '' then E.SetAttribute(FAttrValeur, Valeur);
        if (R - 1 < FOrigValeurs.Count) and (FOrigNoms[R - 1] <> '') then Valeur := FOrigValeurs[R - 1]
        else Valeur := FValeurDefaut;
      end
      else if Valeur = '' then Valeur := FValeurDefaut;
      if (R - 1 < FOrigAttrs.Count) and (FOrigAttrs[R - 1] <> '') then
      begin
        Extras := TStringList.Create;
        try
          Extras.Delimiter := #1;
          Extras.StrictDelimiter := True;
          Extras.QuoteChar := #2;
          Extras.DelimitedText := FOrigAttrs[R - 1];
          for K := 0 to Extras.Count - 1 do E.SetAttribute(Extras.Names[K], Extras.ValueFromIndex[K]);
        finally
          Extras.Free;
        end;
      end;
      Conteneur.AppendChild(E);
      EcrireValeurXML(E, Valeur);
    end;
  end;
  if FTexte = '' then Exit;
  if SignatureGrille = FSignatureInitiale then Texte := FTexteOrigine else Texte := TexteDuLivre;
  N := Element.FindNode(FTexte);
  if N = nil then
  begin
    if Texte = '' then Exit;
    N := Element.OwnerDocument.CreateElement(FTexte);
    Suivant := Element.FirstChild;
    while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and (Pos(',' + Suivant.NodeName + ',', FApresTexte) > 0)) do
      Suivant := Suivant.NextSibling;
    Element.InsertBefore(N, Suivant);
  end;
  EcrireValeurXML(TDOMElement(N), Texte);
end;

function TPanelListeChoix.Signature(const Sep: String): String;
begin
  Result := Sep + SignatureGrille;
end;

procedure TPanelListeChoix.MettreLectureSeule(Valeur: Boolean);
begin
  if Valeur then FGrille.Options := FGrille.Options - [goEditing]
  else FGrille.Options := FGrille.Options + [goEditing];
  FBoutonAjouter.Visible := not Valeur;
  FBoutonRetirer.Visible := not Valeur;
end;

procedure TPanelListeChoix.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  I: Integer;
begin
  if (aRow < 1) or (aCol >= FNbAlt) or (FChoix.Count = 0) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if Editor is TCustomComboBox then
  begin
    TCustomComboBox(Editor).Items.Clear;
    for I := 0 to FChoix.Count - 1 do TCustomComboBox(Editor).Items.Add(FChoix.ValueFromIndex[I]);
  end;
end;

procedure TPanelListeChoix.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FOrigNoms.Add('');
  FOrigValeurs.Add('');
  FCellulesInitiales.Add('');
  FOrigAttrs.Add('');
  if FAttrValeur = '' then FGrille.Cells[FNbAlt, R] := FValeurDefaut;
  FGrille.Row := R;
end;

procedure TPanelListeChoix.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
  begin
    FOrigNoms.Delete(FGrille.Row - 1);
    FOrigValeurs.Delete(FGrille.Row - 1);
    FCellulesInitiales.Delete(FGrille.Row - 1);
    FOrigAttrs.Delete(FGrille.Row - 1);
    FGrille.DeleteRow(FGrille.Row);
  end;
end;

end.

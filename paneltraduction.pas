unit PanelTraduction;

{$mode ObjFPC}{$H+}

// Grille de traduction d'un livre (CONTEXT.md, traductions de WinLivre) : une ligne par texte du livre source
// (balises portant language= et libelles <Text name=> de DATA_LABEL), avec le texte anglais en lecture seule
// et celui du livre de traduction en face (vide s'il n'est pas encore traduit). La colonne Traduction s'edite.
//
// Un texte se reconnait par une cle : la chaine des id= des ancetres + la balise (ou le name= d'un libelle).
// La meme cle des deux cotes apparie le texte source et sa traduction ; l'ordre des lignes est celui du livre source.
// Chaque ligne garde aussi sa CHAINE : les ancetres du texte dans le livre source (balise + id/name), de quoi
// recreer le texte dans le livre de traduction s'il n'y existe pas encore (ancetres reduits a leur id).
// Ecrire n'ecrit que les lignes modifiees ; une traduction videe retire la balise, un texte jamais saisi n'ajoute rien.
// Usage : creer, Initialiser, poser (Parent + SetBounds), Charger(Source, Traduction) puis Ecrire(Traduction).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, DOM, BCButton, ChargeTexte, GlobalFonts,
  PanelModificateurs, TraductionTexte;

type
  TPanelTraduction = class(TPanel)
  private
    FBarre: TPanel;
    FCompteur: TLabel;
    FFiltre: TCheckBox;
    FGrille: TStringGrid;
    FBoutonEnregistrer: TBCButton;
    FOnEnregistrer: TNotifyEvent;
    FCodes, FChamps, FSources, FTraduits, FOriginaux, FChaines, FOccurrences: TStringList;
    FLignes: array of Integer;  // ligne de la grille (moins 1) -> index dans les listes
    FRevision: Integer;
    procedure FiltreChange(Sender: TObject);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: String);
    procedure BoutonEnregistrerClick(Sender: TObject);
    procedure MajCompteur;
    procedure Remplir;
    procedure SetLectureSeule(Valeur: Boolean);
    function  GetLectureSeule: Boolean;
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    procedure Charger(Source, Traduction: TDOMDocument);
    // Ecrit les lignes modifiees dans le DOM du livre de traduction.
    procedure Ecrire(Traduction: TDOMDocument);
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnEnregistrer: TNotifyEvent read FOnEnregistrer write FOnEnregistrer;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

implementation

const
  LargeurCode = 240;
  LargeurChamp = 130;
  ColTraduction = 3;

// Enfant de Parent de balise Tag (et, si AttrNom <> '', dont cet attribut vaut AttrVal) ; cree s'il manque et que Creer.
function TrouverOuCreer(Parent: TDOMElement; const Tag, AttrNom, AttrVal: String; Creer: Boolean): TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  N := Parent.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = Tag)
      and ((AttrNom = '') or (TDOMElement(N).GetAttribute(AttrNom) = AttrVal)) then
      Exit(TDOMElement(N));
    N := N.NextSibling;
  end;
  if not Creer then Exit;
  Result := Parent.OwnerDocument.CreateElement(Tag);
  if AttrNom <> '' then Result.SetAttribute(AttrNom, AttrVal);
  Parent.AppendChild(Result);
end;

// Le Rang-ieme enfant de Parent de balise Tag dont language vaut Langue ; nil s'il n'existe pas.
function TrouverLangue(Parent: TDOMElement; const Tag, Langue: String; Rang: Integer): TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  N := Parent.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = Tag)
      and (UpperCase(TDOMElement(N).GetAttribute('language')) = UpperCase(Langue)) then
    begin
      if Rang = 0 then Exit(TDOMElement(N));
      Dec(Rang);
    end;
    N := N.NextSibling;
  end;
end;

// Ecrit (ou retire si Valeur est vide) le texte decrit par Chaine dans le livre de traduction.
procedure EcrireTexte(Doc: TDOMDocument; const Chaine, Langue: String; Rang: Integer; const Valeur: String);
var
  Parent, Feuille, Etiquette: TDOMElement;
  Segments, Parties: TStringList;
  I: Integer;
  Tag: String;
begin
  Parent := Doc.DocumentElement;
  Segments := TStringList.Create;
  Parties := TStringList.Create;
  try
    if Copy(Chaine, 1, 5) = 'LABEL' then
    begin
      // Libelle : DATA_LABEL / Label language=Langue / Text name=
      Parent := TrouverOuCreer(Parent, 'DATA_LABEL', '', '', Valeur <> '');
      if Parent = nil then Exit;
      Etiquette := TrouverLangue(Parent, 'Label', Langue, 0);
      if Etiquette = nil then
      begin
        if Valeur = '' then Exit;
        Etiquette := Doc.CreateElement('Label');
        Etiquette.SetAttribute('language', Langue);
        Parent.AppendChild(Etiquette);
      end;
      Feuille := TrouverOuCreer(Etiquette, 'Text', 'name', Copy(Chaine, 7, MaxInt), Valeur <> '');
      if Feuille = nil then Exit;
      if Valeur = '' then
        Etiquette.RemoveChild(Feuille)
      else
        EcrireValeurXML(Feuille, Valeur);
      Exit;
    end;
    Segments.StrictDelimiter := True;
    Segments.Delimiter := SepSeg;
    Segments.DelimitedText := Chaine;
    // Tous les segments sauf le dernier sont des ancetres ; le dernier est la balise du texte.
    for I := 0 to Segments.Count - 2 do
    begin
      Parties.StrictDelimiter := True;
      Parties.Delimiter := SepAttr;
      Parties.DelimitedText := Segments[I];
      while Parties.Count < 3 do Parties.Add('');
      Parent := TrouverOuCreer(Parent, Parties[0], Parties[1], Parties[2], Valeur <> '');
      if Parent = nil then Exit;
    end;
    Tag := Segments[Segments.Count - 1];
    Feuille := TrouverLangue(Parent, Tag, Langue, Rang);
    if Valeur = '' then
    begin
      if Feuille <> nil then Parent.RemoveChild(Feuille);
      Exit;
    end;
    if Feuille = nil then
    begin
      Feuille := Doc.CreateElement(Tag);
      Feuille.SetAttribute('language', Langue);
      Parent.AppendChild(Feuille);
    end;
    EcrireValeurXML(Feuille, Valeur);
  finally
    Segments.Free;
    Parties.Free;
  end;
end;

function TPanelTraduction.GetLectureSeule: Boolean;
begin
  Result := not (goEditing in FGrille.Options);
end;

constructor TPanelTraduction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCodes := TStringList.Create;
  FChamps := TStringList.Create;
  FSources := TStringList.Create;
  FTraduits := TStringList.Create;
  FOriginaux := TStringList.Create;
  FChaines := TStringList.Create;
  FOccurrences := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FCompteur := TLabel.Create(Self);
  FCompteur.Parent := FBarre;
  FCompteur.SetBounds(0, 14, 250, 24);
  FFiltre := TCheckBox.Create(Self);
  FFiltre.Parent := FBarre;
  FFiltre.SetBounds(270, 12, 360, 24);
  FFiltre.OnChange := @FiltreChange;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 4;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options - [goEditing];
  FGrille.OnSelectCell := @GrilleSelectCell;
  FGrille.OnSetEditText := @GrilleSetEditText;
  Visible := False;
end;

destructor TPanelTraduction.Destroy;
begin
  FCodes.Free;
  FChamps.Free;
  FSources.Free;
  FTraduits.Free;
  FOriginaux.Free;
  FChaines.Free;
  FOccurrences.Free;
  inherited Destroy;
end;

procedure TPanelTraduction.Initialiser(Modele: TBCButton);
begin
  FBoutonEnregistrer := TBCButtonContour.Create(Self);
  FBoutonEnregistrer.Assign(Modele);
  FBoutonEnregistrer.Parent := FBarre;
  FBoutonEnregistrer.Caption := GetTexteLibelle('RULES-LAB_670');
  FBoutonEnregistrer.OnClick := @BoutonEnregistrerClick;
  FBoutonEnregistrer.SetBounds(650, 0, 300, 50);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

procedure TPanelTraduction.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  if FBoutonEnregistrer <> nil then FBoutonEnregistrer.Visible := not Valeur;
end;

procedure TPanelTraduction.Resize;
var
  Reste: Integer;
begin
  inherited Resize;
  if FGrille = nil then Exit;
  Reste := (FGrille.ClientWidth - LargeurCode - LargeurChamp - 24) div 2;
  if Reste < 100 then Reste := 100;
  FGrille.ColWidths[0] := LargeurCode;
  FGrille.ColWidths[1] := LargeurChamp;
  FGrille.ColWidths[2] := Reste;
  FGrille.ColWidths[3] := Reste;
end;

procedure TPanelTraduction.FiltreChange(Sender: TObject);
begin
  FGrille.EditorMode := False;
  Remplir;
end;

// Seule la colonne Traduction s'edite.
procedure TPanelTraduction.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if not Visible then Exit;
  if (aCol = ColTraduction) and (aRow > 0) then
    FGrille.Options := FGrille.Options + [goEditing]
  else
    FGrille.Options := FGrille.Options - [goEditing];
  CanSelect := True;
end;

procedure TPanelTraduction.GrilleSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: String);
var
  Index: Integer;
begin
  if (ACol <> ColTraduction) or (ARow < 1) or (ARow > Length(FLignes)) then Exit;
  Index := FLignes[ARow - 1];
  if FTraduits[Index] = Value then Exit;
  FTraduits[Index] := Value;
  Inc(FRevision);
  MajCompteur;
end;

procedure TPanelTraduction.BoutonEnregistrerClick(Sender: TObject);
begin
  if Assigned(FOnEnregistrer) then FOnEnregistrer(Self);
end;

procedure TPanelTraduction.MajCompteur;
var
  I, NbTraduits: Integer;
begin
  NbTraduits := 0;
  for I := 0 to FSources.Count - 1 do
    if FTraduits[I] <> '' then Inc(NbTraduits);
  FCompteur.Caption := Format(GetTexteLibelle('RULES-LAB_669'), [NbTraduits, FSources.Count]);
end;

procedure TPanelTraduction.Remplir;
var
  I, Ligne: Integer;
  Seulement: Boolean;
begin
  Seulement := FFiltre.Checked;
  MajCompteur;
  SetLength(FLignes, FSources.Count);
  Ligne := 1;
  FGrille.BeginUpdate;
  try
    FGrille.RowCount := FSources.Count + 1;
    for I := 0 to FSources.Count - 1 do
    begin
      if Seulement and (FTraduits[I] <> '') then Continue;
      FLignes[Ligne - 1] := I;
      FGrille.Cells[0, Ligne] := FCodes[I];
      FGrille.Cells[1, Ligne] := FChamps[I];
      FGrille.Cells[2, Ligne] := FSources[I];
      FGrille.Cells[3, Ligne] := FTraduits[I];
      Inc(Ligne);
    end;
    FGrille.RowCount := Ligne;
    SetLength(FLignes, Ligne - 1);
  finally
    FGrille.EndUpdate;
  end;
end;

// Source : le livre dont le livre de traduction est la traduction. Traduction : le livre ouvert.
procedure TPanelTraduction.Charger(Source, Traduction: TDOMDocument);
var
  CS, CT: TCollecte;
  Index: TStringList;
  I, Pos: Integer;
begin
  FCodes.Clear;
  FChamps.Clear;
  FSources.Clear;
  FTraduits.Clear;
  FOriginaux.Clear;
  FChaines.Clear;
  FOccurrences.Clear;
  FRevision := 0;
  FFiltre.Caption := GetTexteLibelle('RULES-LAB_668');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_001');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_665');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_666');
  FGrille.Cells[3, 0] := GetTexteLibelle('RULES-LAB_667');
  CS := TCollecte.Create;
  CT := TCollecte.Create;
  Index := TStringList.Create;
  try
    Collecter(Source, CS);
    Collecter(Traduction, CT);
    Index.Sorted := True;
    Index.CaseSensitive := True;
    for I := 0 to CT.Cles.Count - 1 do
      Index.AddObject(CT.Cles[I], TObject(PtrInt(I)));
    for I := 0 to CS.Cles.Count - 1 do
    begin
      FCodes.Add(CS.Codes[I]);
      if CS.Champs[I] <> '' then
        FChamps.Add(GetTexteLibelle(CS.Champs[I]))
      else
        FChamps.Add('');
      FSources.Add(CS.Valeurs[I]);
      FChaines.Add(CS.Chaines[I]);
      FOccurrences.Add(CS.Occurrences[I]);
      Pos := Index.IndexOf(CS.Cles[I]);
      if Pos >= 0 then
        FTraduits.Add(CT.Valeurs[PtrInt(Index.Objects[Pos])])
      else
        FTraduits.Add('');
    end;
  finally
    CS.Free;
    CT.Free;
    Index.Free;
  end;
  FOriginaux.Assign(FTraduits);
  Resize;
  Remplir;
end;

procedure TPanelTraduction.Ecrire(Traduction: TDOMDocument);
var
  I: Integer;
  Langue: String;
begin
  Langue := LangueBrute(Traduction);
  for I := 0 to FSources.Count - 1 do
    if FTraduits[I] <> FOriginaux[I] then
      EcrireTexte(Traduction, FChaines[I], Langue, StrToIntDef(FOccurrences[I], 0), FTraduits[I]);
  FOriginaux.Assign(FTraduits);
end;

procedure TPanelTraduction.FinEdition;
begin
  FGrille.EditorMode := False;
end;

// Un simple compteur de modifications : relire toutes les traductions a chaque tick du minuteur serait couteux.
function TPanelTraduction.Signature(const Sep: String): String;
begin
  Result := IntToStr(FRevision);
end;

procedure TPanelTraduction.ActiverBoutons(Actif: Boolean);
begin
  if FBoutonEnregistrer <> nil then FBoutonEnregistrer.Enabled := Actif;
end;

end.

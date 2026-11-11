unit PanelSousBlocs;

{$mode ObjFPC}{$H+}

// Blocs repetes d'un element WFRP1, sous les champs de sa fiche, un tableau par balise :
//   <Bonus><Kind>"TEST"</Kind><Target>"Fear"</Target><Value>"+10"</Value></Bonus>   (competence)
//   <Prayer><Rank>..</Rank><Kind>..</Kind><Value>"WRDM-PRAYER_x"</Value></Prayer>    (culte)
//   <Gift><Rank>..</Rank><Text>..</Text></Gift>                                       (culte)
// Une colonne « codee » garde le code dans le XML et montre son libelle ; le texte tape est reconverti en code
// (libelle connu) ou garde tel quel. Ajouter / retirer une ligne ; les lignes sont reecrites a la place des anciennes.
// Description d'un bloc (Specs) : « Balise|IdLibelleTitre|Tag:IdLibelle,Tag:IdLibelle:c » (:c = colonne codee).
// Un Tag peut etre « . » (le texte de la ligne elle-meme : <Skill>"x"</Skill>) ou « @nom » (un attribut de la ligne :
// <Requirement name="x">"30"</Requirement>) ; les autres attributs de la ligne sont conserves tels quels.
// « *Balise » : tous les enfants <Balise name="code">"valeur"</Balise> de la ligne dans une seule cellule,
// montres « Libelle valeur, Libelle valeur » (une cellule inchangee reecrit les enfants d'origine).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TBlocSousBlocs = record
    Balise: String;
    Annexe: String;  // balise rattachee au tableau (BirthplaceHuman) : une ligne « suffixe / valeur » (spec « Balise+Annexe »)
    BaliseLigne: TStringList;  // pour chaque ligne : '' = balise du bloc, sinon l'annexe
    Titre: TLabel;
    Grille: TStringGrid;
    Tags: TStringList;
    Codee: array of Boolean;
    Origine: array of TStringList;  // code d'origine de chaque ligne, par colonne
    Attributs: array of TStringList;  // attributs de la cellule (nom=valeur separes par #1), par colonne
    Choix: array of TStringList;  // libelles proposes (liste deroulante) par colonne, nil = saisie libre
    BoutonAjouter, BoutonRetirer: TBCButton;
  end;

  TPanelSousBlocs = class(TPanelExtraFiche)
  private
    FBlocs: array of TBlocSousBlocs;
    FLibelle, FResolution: TFonctionLibelle;
    FConteneur: String;
    FLargeurNom: Integer;
    FHauteurGrille: Integer;
    FOrdre: String;  // ordre des balises de l'element (virgules) : un bloc neuf se range a sa place
    function  RangOrdre(const Balise: String): Integer;
    function  Portee(Element: TDOMElement): TDOMElement;
    procedure ChargerBloc(I: Integer; Element: TDOMElement);
    procedure EcrireBloc(I: Integer; Element: TDOMElement);
    function  CodeDeLaCellule(I, C, R: Integer): String;
    function  AffichageModifs(const Origine: String): String;
    procedure EcrireModifs(I, C, R: Integer; Ligne: TDOMElement);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
  public
    destructor Destroy; override;
    // la colonne Colonne du bloc Bloc ne se remplit plus qu'avec l'un de ces libelles
    procedure DefinirChoix(Bloc, Colonne: Integer; Libelles: TStrings);
    procedure Initialiser(Modele: TBCButton; Libelle, Resolution: TFonctionLibelle; const Specs: array of String);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
    property  OrdreBalises: String read FOrdre write FOrdre;
    // les blocs vivent dans cet enfant de l'element (SUBCHAPTER_PHYSICAL...) ; '' = l'element lui-meme
    property  Conteneur: String read FConteneur write FConteneur;
    // largeur de la colonne « @name » (0 = largeur par defaut) ; a fixer avant Initialiser
    property  LargeurNom: Integer read FLargeurNom write FLargeurNom;
    // hauteur des grilles en pixels (0 = 120 par defaut, pour les tables longues) ; a fixer avant Initialiser
    property  HauteurGrille: Integer read FHauteurGrille write FHauteurGrille;
  end;

implementation

const
  HauteurBloc = 200;

destructor TPanelSousBlocs.Destroy;
var
  I, C: Integer;
begin
  for I := 0 to High(FBlocs) do
  begin
    FBlocs[I].Tags.Free;
    FBlocs[I].BaliseLigne.Free;
    for C := 0 to High(FBlocs[I].Origine) do
    begin
      FBlocs[I].Origine[C].Free;
      FBlocs[I].Attributs[C].Free;
      FBlocs[I].Choix[C].Free;
    end;
  end;
  inherited Destroy;
end;

procedure TPanelSousBlocs.DefinirChoix(Bloc, Colonne: Integer; Libelles: TStrings);
begin
  if FBlocs[Bloc].Choix[Colonne] = nil then FBlocs[Bloc].Choix[Colonne] := TStringList.Create;
  FBlocs[Bloc].Choix[Colonne].Assign(Libelles);
end;

procedure TPanelSousBlocs.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  I: Integer;
begin
  if aRow < 1 then Exit;
  for I := 0 to High(FBlocs) do
    if (FBlocs[I].Grille = Sender) and (FBlocs[I].Choix[aCol] <> nil) then
    begin
      Editor := FBlocs[I].Grille.EditorByStyle(cbsPickList);
      if Editor is TCustomComboBox then TCustomComboBox(Editor).Items.Assign(FBlocs[I].Choix[aCol]);
    end;
end;

procedure TPanelSousBlocs.Initialiser(Modele: TBCButton; Libelle, Resolution: TFonctionLibelle; const Specs: array of String);
var
  I, C, Haut, Largeur, Hg, Pas: Integer;
  Morceaux, Colonnes, Col: TStringList;
begin
  FLibelle := Libelle;
  FResolution := Resolution;
  BevelOuter := bvNone;
  Caption := '';
  if FHauteurGrille > 0 then Hg := FHauteurGrille else Hg := 120;
  Pas := Hg + HauteurBloc - 120;  // boutons et titre sous / sur la grille
  Height := Length(Specs) * Pas;
  SetLength(FBlocs, Length(Specs));
  Morceaux := TStringList.Create;
  Colonnes := TStringList.Create;
  Col := TStringList.Create;
  try
    Morceaux.Delimiter := '|';
    Morceaux.StrictDelimiter := True;
    Colonnes.Delimiter := ',';
    Colonnes.StrictDelimiter := True;
    Col.Delimiter := ':';
    Col.StrictDelimiter := True;
    for I := 0 to High(Specs) do
    begin
      Haut := I * Pas;
      Morceaux.DelimitedText := Specs[I];
      Colonnes.DelimitedText := Morceaux[2];
      FBlocs[I].Balise := Morceaux[0];
      FBlocs[I].Annexe := '';
      if Pos('+', Morceaux[0]) > 0 then
      begin
        FBlocs[I].Annexe := Copy(Morceaux[0], Pos('+', Morceaux[0]) + 1, MaxInt);
        FBlocs[I].Balise := Copy(Morceaux[0], 1, Pos('+', Morceaux[0]) - 1);
        Morceaux[0] := FBlocs[I].Balise;
      end;
      FBlocs[I].BaliseLigne := TStringList.Create;
      FBlocs[I].Tags := TStringList.Create;
      SetLength(FBlocs[I].Codee, Colonnes.Count);
      SetLength(FBlocs[I].Origine, Colonnes.Count);
      SetLength(FBlocs[I].Attributs, Colonnes.Count);
      SetLength(FBlocs[I].Choix, Colonnes.Count);
      FBlocs[I].Titre := TLabelContour.Create(Self);
      FBlocs[I].Titre.Parent := Self;
      FBlocs[I].Titre.SetBounds(0, Haut, 400, 20);
      FBlocs[I].Titre.Caption := GetTexteLibelle(Morceaux[1], Morceaux[0]);
      FBlocs[I].Grille := TStringGrid.Create(Self);
      FBlocs[I].Grille.Parent := Self;
      CouleurSelectionGrille(FBlocs[I].Grille);
      FBlocs[I].Grille.ColCount := Colonnes.Count;
      FBlocs[I].Grille.RowCount := 1;
      FBlocs[I].Grille.FixedRows := 1;
      FBlocs[I].Grille.FixedCols := 0;
      FBlocs[I].Grille.Options := FBlocs[I].Grille.Options + [goEditing] - [goRangeSelect];
      FBlocs[I].Grille.OnSelectEditor := @GrilleSelectEditor;
      Largeur := 0;
      for C := 0 to Colonnes.Count - 1 do
      begin
        Col.DelimitedText := Colonnes[C];
        FBlocs[I].Tags.Add(Col[0]);
        FBlocs[I].Codee[C] := (Col.Count > 2) and (Col[2] = 'c');
        FBlocs[I].Origine[C] := TStringList.Create;
        FBlocs[I].Attributs[C] := TStringList.Create;
        FBlocs[I].Grille.Cells[C, 0] := GetTexteLibelle(Col[1], Col[0]);
        if FBlocs[I].Codee[C] or (Col[0][1] = '*') or (Col[0] = 'Text') then FBlocs[I].Grille.ColWidths[C] := 300
        else FBlocs[I].Grille.ColWidths[C] := 110;
        if (Col[0] = '@name') and (FLargeurNom > 0) then FBlocs[I].Grille.ColWidths[C] := FLargeurNom;
        Largeur := Largeur + FBlocs[I].Grille.ColWidths[C];
      end;
      FBlocs[I].Grille.SetBounds(0, Haut + 24, Largeur + 24, Hg);
      FBlocs[I].BoutonAjouter := TBCButtonContour.Create(Self);
      FBlocs[I].BoutonAjouter.Assign(Modele);
      FBlocs[I].BoutonAjouter.Parent := Self;
      FBlocs[I].BoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_899');
      FBlocs[I].BoutonAjouter.Tag := I;
      FBlocs[I].BoutonAjouter.OnClick := @BoutonAjouterClick;
      FBlocs[I].BoutonAjouter.SetBounds(0, Haut + 30 + Hg, 200, 32);
      FBlocs[I].BoutonRetirer := TBCButtonContour.Create(Self);
      FBlocs[I].BoutonRetirer.Assign(Modele);
      FBlocs[I].BoutonRetirer.Parent := Self;
      FBlocs[I].BoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
      FBlocs[I].BoutonRetirer.Tag := I;
      FBlocs[I].BoutonRetirer.OnClick := @BoutonRetirerClick;
      FBlocs[I].BoutonRetirer.SetBounds(210, Haut + 30 + Hg, 200, 32);
    end;
  finally
    Morceaux.Free;
    Colonnes.Free;
    Col.Free;
  end;
  Visible := False;
  MiseAJourUnContenaire(Self);
end;

procedure TPanelSousBlocs.ChargerBloc(I: Integer; Element: TDOMElement);
var
  N, F: TDOMNode;
  C, R, A: Integer;
  Code, Attrs, Nom: String;
begin
  FBlocs[I].Grille.EditorMode := False;
  FBlocs[I].Grille.RowCount := 1;
  FBlocs[I].BaliseLigne.Clear;
  for C := 0 to High(FBlocs[I].Origine) do
  begin
    FBlocs[I].Origine[C].Clear;
    FBlocs[I].Attributs[C].Clear;
  end;
  N := Element.FirstChild;
  while N <> nil do
  begin
    if (FBlocs[I].Annexe <> '') and (N.NodeType = ELEMENT_NODE) and (N.NodeName = FBlocs[I].Annexe) and
       (FBlocs[I].Tags.Count = 2) and (FBlocs[I].Tags[0] = '@name') and (FBlocs[I].Tags[1] = '.') then
    begin
      // balise rattachee (BirthplaceHuman) : nom = ce qui suit la balise du bloc (Human), valeur = son texte
      R := FBlocs[I].Grille.RowCount;
      FBlocs[I].Grille.RowCount := R + 1;
      FBlocs[I].BaliseLigne.Add(FBlocs[I].Annexe);
      Code := Copy(FBlocs[I].Annexe, Length(FBlocs[I].Balise) + 1, MaxInt);
      FBlocs[I].Origine[0].Add(Code);
      FBlocs[I].Attributs[0].Add('');
      FBlocs[I].Grille.Cells[0, R] := Code;
      Code := ValeurXML(N);
      FBlocs[I].Origine[1].Add(Code);
      FBlocs[I].Attributs[1].Add('');
      FBlocs[I].Grille.Cells[1, R] := Code;
    end
    else if (N.NodeType = ELEMENT_NODE) and (N.NodeName = FBlocs[I].Balise) then
    begin
      R := FBlocs[I].Grille.RowCount;
      FBlocs[I].Grille.RowCount := R + 1;
      FBlocs[I].BaliseLigne.Add('');
      for C := 0 to FBlocs[I].Tags.Count - 1 do
      begin
        Nom := FBlocs[I].Tags[C];
        Attrs := '';
        if Nom[1] = '*' then
        begin
          // enfants repetes : « code#2valeur » separes par #1, gardes tels quels dans Origine
          F := nil;
          Code := '';
          Attrs := Copy(Nom, 2, MaxInt);
          A := 0;
          F := N.FirstChild;
          while F <> nil do
          begin
            if (F.NodeType = ELEMENT_NODE) and (F.NodeName = Attrs) then
            begin
              if Code <> '' then Code := Code + #1;
              Code := Code + TDOMElement(F).GetAttribute('name') + #2 + ValeurXML(F);
              // autres attributs (quantite...) : gardes apres #4, sous la forme « nom=valeur » separes par #5
              for A := 0 to TDOMElement(F).Attributes.Length - 1 do
                if TDOMElement(F).Attributes[A].NodeName <> 'name' then
                  Code := Code + #4 + TDOMElement(F).Attributes[A].NodeName + '=' + TDOMElement(F).Attributes[A].NodeValue;
            end;
            F := F.NextSibling;
          end;
          Attrs := '';
          FBlocs[I].Origine[C].Add(Code);
          FBlocs[I].Attributs[C].Add('');
          FBlocs[I].Grille.Cells[C, R] := AffichageModifs(Code);
          Continue;
        end;
        if Nom[1] = '@' then
        begin
          F := nil;
          Code := TDOMElement(N).GetAttribute(Copy(Nom, 2, MaxInt));
        end
        else
        begin
          if Nom = '.' then F := N else F := N.FindNode(Nom);
          Code := ValeurXML(F);
          if F <> nil then
            for A := 0 to TDOMElement(F).Attributes.Length - 1 do
            begin
              if (Nom = '.') and (FBlocs[I].Tags.IndexOf('@' + TDOMElement(F).Attributes[A].NodeName) >= 0) then Continue;
              if Attrs <> '' then Attrs := Attrs + #1;
              Attrs := Attrs + TDOMElement(F).Attributes[A].NodeName + '=' + TDOMElement(F).Attributes[A].NodeValue;
            end;
        end;
        FBlocs[I].Origine[C].Add(Code);
        FBlocs[I].Attributs[C].Add(Attrs);
        if FBlocs[I].Codee[C] and (Code <> '') then
          FBlocs[I].Grille.Cells[C, R] := FLibelle(Code)
        else
          FBlocs[I].Grille.Cells[C, R] := Code;
      end;
    end;
    N := N.NextSibling;
  end;
end;

// L'element qui porte les lignes : l'element lui-meme, ou son bloc Conteneur (nil s'il n'existe pas).
function TPanelSousBlocs.Portee(Element: TDOMElement): TDOMElement;
var
  N: TDOMNode;
begin
  if FConteneur = '' then Exit(Element);
  N := Element.FindNode(FConteneur);
  if N = nil then Result := nil else Result := TDOMElement(N);
end;

procedure TPanelSousBlocs.Charger(Element: TDOMElement);
var
  I: Integer;
begin
  Element := Portee(Element);
  for I := 0 to High(FBlocs) do
    if Element <> nil then ChargerBloc(I, Element)
    else FBlocs[I].Grille.RowCount := 1;
end;

function TPanelSousBlocs.Controler: Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FBlocs) do FBlocs[I].Grille.EditorMode := False;
  Result := True;
end;

// Valeur a ecrire pour une cellule : le code d'origine si le libelle n'a pas change, sinon le code du libelle tape.
function TPanelSousBlocs.CodeDeLaCellule(I, C, R: Integer): String;
var
  Texte, Origine: String;
begin
  Texte := Trim(FBlocs[I].Grille.Cells[C, R]);
  if not FBlocs[I].Codee[C] then
  begin
    Result := Texte;
    Exit;
  end;
  Origine := '';
  if R - 1 < FBlocs[I].Origine[C].Count then Origine := FBlocs[I].Origine[C][R - 1];
  if (Origine <> '') and (Texte = FLibelle(Origine)) then
    Result := Origine
  else
  begin
    Result := FResolution(Texte);
    if Result = '' then Result := Texte;
  end;
end;

// « code#2valeur » separes par #1 -> « Libelle valeur, Libelle valeur ».
function TPanelSousBlocs.AffichageModifs(const Origine: String): String;
var
  Liste: TStringList;
  K, P: Integer;
  Valeur: String;
begin
  Result := '';
  Liste := TStringList.Create;
  try
    Liste.Delimiter := #1;
    Liste.StrictDelimiter := True;
    Liste.QuoteChar := #3;
    Liste.DelimitedText := Origine;
    for K := 0 to Liste.Count - 1 do
    begin
      P := Pos(#2, Liste[K]);
      if Result <> '' then Result := Result + ', ';
      Valeur := Copy(Liste[K], P + 1, MaxInt);
      if Pos(#4, Valeur) > 0 then Valeur := Copy(Valeur, 1, Pos(#4, Valeur) - 1);
      Result := Result + FLibelle(Copy(Liste[K], 1, P - 1)) + ' ' + Valeur;
    end;
  finally
    Liste.Free;
  end;
end;

// Reecrit les enfants d'une cellule « * » : ceux d'origine si le texte n'a pas change, sinon le texte relu
// (« Libelle valeur » separes par des virgules, le libelle redevient son code s'il est connu).
procedure TPanelSousBlocs.EcrireModifs(I, C, R: Integer; Ligne: TDOMElement);
var
  Liste: TStringList;
  K, P, Q: Integer;
  Texte, Origine, Item, Libelle, Valeur, Code, Extras: String;
  F: TDOMElement;
begin
  Texte := Trim(FBlocs[I].Grille.Cells[C, R]);
  if Texte = '' then Exit;
  Origine := '';
  if R - 1 < FBlocs[I].Origine[C].Count then Origine := FBlocs[I].Origine[C][R - 1];
  Liste := TStringList.Create;
  try
    Liste.Delimiter := #1;
    Liste.StrictDelimiter := True;
    Liste.QuoteChar := #3;
    if (Origine <> '') and (Texte = AffichageModifs(Origine)) then
      Liste.DelimitedText := Origine
    else
    begin
      Liste.Delimiter := ',';
      Liste.DelimitedText := Texte;
      for K := 0 to Liste.Count - 1 do
      begin
        Item := Trim(Liste[K]);
        P := LastDelimiter(' ', Item);
        if P = 0 then
        begin
          Libelle := Item;
          Valeur := '';
        end
        else
        begin
          Libelle := Trim(Copy(Item, 1, P - 1));
          Valeur := Copy(Item, P + 1, MaxInt);
        end;
        Code := FResolution(Libelle);
        if Code = '' then Code := Libelle;
        Liste[K] := Code + #2 + Valeur;
      end;
    end;
    for K := 0 to Liste.Count - 1 do
    begin
      P := Pos(#2, Liste[K]);
      F := Ligne.OwnerDocument.CreateElement(Copy(FBlocs[I].Tags[C], 2, MaxInt));
      F.SetAttribute('name', Copy(Liste[K], 1, P - 1));
      Ligne.AppendChild(F);
      Valeur := Copy(Liste[K], P + 1, MaxInt);
      Q := Pos(#4, Valeur);
      if Q > 0 then
      begin
        Extras := Copy(Valeur, Q + 1, MaxInt);
        Valeur := Copy(Valeur, 1, Q - 1);
        while Extras <> '' do
        begin
          Q := Pos(#4, Extras);
          if Q = 0 then Q := Length(Extras) + 1;
          Item := Copy(Extras, 1, Q - 1);
          Delete(Extras, 1, Q);
          if Pos('=', Item) > 0 then F.SetAttribute(Copy(Item, 1, Pos('=', Item) - 1), Copy(Item, Pos('=', Item) + 1, MaxInt));
        end;
      end;
      EcrireValeurXML(F, Valeur);
    end;
  finally
    Liste.Free;
  end;
end;

// Rang de la balise dans l'ordre de l'element (-1 si elle n'y est pas).
function TPanelSousBlocs.RangOrdre(const Balise: String): Integer;
var
  Liste: TStringList;
begin
  Liste := TStringList.Create;
  try
    Liste.StrictDelimiter := True;
    Liste.CommaText := FOrdre;
    Result := Liste.IndexOf(Balise);
  finally
    Liste.Free;
  end;
end;

procedure TPanelSousBlocs.EcrireBloc(I: Integer; Element: TDOMElement);
var
  N, Suivant, Premier: TDOMNode;
  E, F: TDOMElement;
  R, C, A, Passe: Integer;
  Valeur: String;
  Attrs: TStringList;
  EstAnnexe: Boolean;
begin
  FBlocs[I].Grille.EditorMode := False;
  Premier := nil;
  N := Element.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = FBlocs[I].Balise) then
    begin
      Premier := N;
      Break;
    end;
    N := N.NextSibling;
  end;
  if (Premier = nil) and (FOrdre <> '') and (RangOrdre(FBlocs[I].Balise) >= 0) then
  begin
    // aucun bloc deja la : avant la premiere balise qui vient apres dans le schema
    N := Element.FirstChild;
    while (N <> nil) and not ((N.NodeType = ELEMENT_NODE) and (RangOrdre(N.NodeName) > RangOrdre(FBlocs[I].Balise))) do
      N := N.NextSibling;
    Premier := N;
  end;
  // passe 0 : les lignes du bloc ; passe 1 : la balise rattachee (BirthplaceHuman), apres elles
  for Passe := 0 to 1 do
  for R := 1 to FBlocs[I].Grille.RowCount - 1 do
  begin
    EstAnnexe := (R - 1 < FBlocs[I].BaliseLigne.Count) and (FBlocs[I].BaliseLigne[R - 1] <> '');
    if EstAnnexe <> (Passe = 1) then Continue;
    if EstAnnexe then
    begin
      E := Element.OwnerDocument.CreateElement(FBlocs[I].Annexe);
      EcrireValeurXML(E, Trim(FBlocs[I].Grille.Cells[1, R]));
      if Premier <> nil then Element.InsertBefore(E, Premier)
      else Element.AppendChild(E);
      Continue;
    end;
    E := Element.OwnerDocument.CreateElement(FBlocs[I].Balise);
    for C := 0 to FBlocs[I].Tags.Count - 1 do
    begin
      if FBlocs[I].Tags[C][1] = '*' then
      begin
        EcrireModifs(I, C, R, E);
        Continue;
      end;
      Valeur := CodeDeLaCellule(I, C, R);
      if Valeur = '' then Continue;
      if FBlocs[I].Tags[C][1] = '@' then
      begin
        E.SetAttribute(Copy(FBlocs[I].Tags[C], 2, MaxInt), Valeur);
        Continue;
      end;
      if FBlocs[I].Tags[C] = '.' then F := E
      else
      begin
        F := Element.OwnerDocument.CreateElement(FBlocs[I].Tags[C]);
        E.AppendChild(F);
      end;
      EcrireValeurXML(F, Valeur);
      Attrs := TStringList.Create;
      try
        Attrs.Delimiter := #1;
        Attrs.StrictDelimiter := True;
        Attrs.QuoteChar := #2;
        Attrs.DelimitedText := FBlocs[I].Attributs[C][R - 1];
        for A := 0 to Attrs.Count - 1 do
          F.SetAttribute(Attrs.Names[A], Attrs.ValueFromIndex[A]);
      finally
        Attrs.Free;
      end;
    end;
    if Premier <> nil then Element.InsertBefore(E, Premier)
    else Element.AppendChild(E);
  end;
  N := Premier;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and ((N.NodeName = FBlocs[I].Balise) or
       ((FBlocs[I].Annexe <> '') and (N.NodeName = FBlocs[I].Annexe))) then
      Element.RemoveChild(N);
    N := Suivant;
  end;
end;

procedure TPanelSousBlocs.Ecrire(Element: TDOMElement);
var
  I: Integer;
  Mere: TDOMElement;
  Present: Boolean;
begin
  Mere := Element;
  Element := Portee(Mere);
  if Element = nil then
  begin
    // conteneur absent (element neuf, ou bloc qui ne porte que ces tableaux) : on le cree s'il y a des lignes a ecrire
    Present := False;
    for I := 0 to High(FBlocs) do
      if FBlocs[I].Grille.RowCount > 1 then Present := True;
    if not Present then Exit;
    Element := Mere.OwnerDocument.CreateElement(FConteneur);
    // Page est la derniere balise (schema) : le conteneur neuf se place avant elle
    if Mere.FindNode('Page') <> nil then Mere.InsertBefore(Element, Mere.FindNode('Page'))
    else Mere.AppendChild(Element);
  end;
  for I := 0 to High(FBlocs) do EcrireBloc(I, Element);
end;

function TPanelSousBlocs.Signature(const Sep: String): String;
var
  I, C, R: Integer;
begin
  Result := '';
  for I := 0 to High(FBlocs) do
    for R := 1 to FBlocs[I].Grille.RowCount - 1 do
      for C := 0 to FBlocs[I].Tags.Count - 1 do
        Result := Result + Sep + FBlocs[I].Grille.Cells[C, R];
end;

procedure TPanelSousBlocs.MettreLectureSeule(Valeur: Boolean);
var
  I: Integer;
begin
  for I := 0 to High(FBlocs) do
  begin
    if Valeur then
      FBlocs[I].Grille.Options := FBlocs[I].Grille.Options - [goEditing]
    else
      FBlocs[I].Grille.Options := FBlocs[I].Grille.Options + [goEditing];
    FBlocs[I].BoutonAjouter.Visible := not Valeur;
    FBlocs[I].BoutonRetirer.Visible := not Valeur;
  end;
end;

procedure TPanelSousBlocs.BoutonAjouterClick(Sender: TObject);
var
  I, C: Integer;
begin
  I := TBCButton(Sender).Tag;
  FBlocs[I].Grille.EditorMode := False;
  FBlocs[I].Grille.RowCount := FBlocs[I].Grille.RowCount + 1;
  FBlocs[I].BaliseLigne.Add('');
  for C := 0 to FBlocs[I].Tags.Count - 1 do
  begin
    FBlocs[I].Origine[C].Add('');
    // une nouvelle ligne reprend les attributs (langue) de la precedente
    if FBlocs[I].Attributs[C].Count > 0 then
      FBlocs[I].Attributs[C].Add(FBlocs[I].Attributs[C][FBlocs[I].Attributs[C].Count - 1])
    else
      FBlocs[I].Attributs[C].Add('');
  end;
  FBlocs[I].Grille.Row := FBlocs[I].Grille.RowCount - 1;
end;

procedure TPanelSousBlocs.BoutonRetirerClick(Sender: TObject);
var
  I, C: Integer;
begin
  I := TBCButton(Sender).Tag;
  FBlocs[I].Grille.EditorMode := False;
  if (FBlocs[I].Grille.Row >= 1) and (FBlocs[I].Grille.Row < FBlocs[I].Grille.RowCount) then
  begin
    FBlocs[I].BaliseLigne.Delete(FBlocs[I].Grille.Row - 1);
    for C := 0 to FBlocs[I].Tags.Count - 1 do
    begin
      FBlocs[I].Origine[C].Delete(FBlocs[I].Grille.Row - 1);
      FBlocs[I].Attributs[C].Delete(FBlocs[I].Grille.Row - 1);
    end;
    FBlocs[I].Grille.DeleteRow(FBlocs[I].Grille.Row);
  end;
end;

end.

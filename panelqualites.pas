unit PanelQualites;

{$mode ObjFPC}{$H+}

// Liste des qualites liees a un element (arme, armure) : une ligne par qualite, Qualite | Valeur | Or,
// avec Ajouter / Retirer. Le XML garde un texte "CODE valeur,CODE" ("-" si aucune) ; la grille montre le
// libelle. Les lignes marquees Or sont des qualites ALTERNATIVES (le porteur en choisit une) : elles forment
// ENSEMBLE un seul groupe, ecrit "A 2/B 3" a la place de la premiere (chaque partie garde sa valeur ; l'ancien
// "A/B 2" donne sa valeur a B). Un seul groupe par element. Meme principe que TPanelModificateurs : un bloc
// reutilisable, pose par TPanelFiche a droite de la grille des modificateurs.
//
// Usage : creer, Initialiser (une fois), puis Charger(Texte) a l'ouverture et Texte a la validation.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, BCButton, ChargeTexte, GlobalFonts;

type
  TPanelQualitesLiees = class(TPanel)
  private
    FEtiquette: TLabel;
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonNouvelle, FBoutonModifier: TBCButton;
    FOnNouvelle, FOnModifier: TNotifyEvent;
    FLibelles, FCodes: TStrings;  // qualites proposees : libelle affiche / code ecrit (listes de l'appelant)
    FCodesAvecValeur: TStrings;   // codes des qualites a valeur obligatoire (<NeedsValue>), liste de l'appelant
    function  LibelleDeCode(const Code: String): String;
    function  CodeDeLibelle(const Lib: String): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure SetOnNouvelle(Valeur: TNotifyEvent);
    procedure SetOnModifier(Valeur: TNotifyEvent);
    procedure PlacerBoutons;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Initialiser(Modele: TBCButton; Libelles, Codes: TStrings);
    // Largeur du bloc : colonnes et boutons suivent (meme gabarit que la grille des modificateurs)
    procedure Placer(Largeur: Integer);
    procedure Charger(const Texte: String);
    function  Texte: String;
    function  Signature(const Sep: String): String;
    // codes des qualites dont la valeur est obligatoire (liste detenue par l'appelant, jamais liberee ici)
    property  CodesAvecValeur: TStrings read FCodesAvecValeur write FCodesAvecValeur;
    // si fourni, un bouton "Nouvelle qualite" apparait a cote d'Ajouter/Retirer (objets propres d'un personnage)
    property  OnNouvelle: TNotifyEvent read FOnNouvelle write SetOnNouvelle;
    // idem pour "Modifier la qualite" (qualite selectionnee, voir CodeSelectionne)
    property  OnModifier: TNotifyEvent read FOnModifier write SetOnModifier;
    // code de la qualite de la ligne selectionnee, '' si aucune
    function  CodeSelectionne: String;
    // False (avec message nommant la ligne) si une qualite a valeur obligatoire n'en a pas, ou a une valeur invalide
    // (entier ou de comme 1d10) ; a appeler avant Texte
    function  Controler: Boolean;
    // lecture seule : plus d'edition ni de boutons, la grille reste active (elle defile)
    procedure SetLectureSeule(Valeur: Boolean);
  end;

implementation

constructor TPanelQualitesLiees.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  FEtiquette := TLabelContour.Create(Self);
  FEtiquette.Parent := Self;
  FEtiquette.Align := alTop;
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alBottom;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 32;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.ColCount := 3;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing, goRowSelect] - [goRangeSelect];
  FGrille.ColWidths[0] := 150;
  FGrille.ColWidths[1] := 90;
  FGrille.ColWidths[2] := 60;
  FGrille.OnSelectEditor := @GrilleSelectEditor;
end;

procedure TPanelQualitesLiees.Initialiser(Modele: TBCButton; Libelles, Codes: TStrings);
begin
  FLibelles := Libelles;
  FCodes := Codes;
  FEtiquette.Caption := GetTexteLibelle('RULES-LAB_476');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_476');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_025');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_494');
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_440');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FBoutonNouvelle := TBCButtonContour.Create(Self);
  FBoutonNouvelle.Assign(Modele);
  FBoutonNouvelle.Parent := FBarre;
  FBoutonNouvelle.Caption := GetTexteLibelle('RULES-LAB_649');
  FBoutonNouvelle.OnClick := FOnNouvelle;
  FBoutonNouvelle.Visible := Assigned(FOnNouvelle);
  FBoutonModifier := TBCButtonContour.Create(Self);
  FBoutonModifier.Assign(Modele);
  FBoutonModifier.Parent := FBarre;
  FBoutonModifier.Caption := GetTexteLibelle('RULES-LAB_650');
  FBoutonModifier.OnClick := FOnModifier;
  FBoutonModifier.Visible := Assigned(FOnModifier);
  // les composants crees ici appartiennent au panneau : meme mise en forme que PanelModificateurs
  MiseAJourUnContenaire(Self);
  Placer(820);
end;

procedure TPanelQualitesLiees.Placer(Largeur: Integer);
begin
  FGrille.ColWidths[0] := (Largeur * 55) div 100;
  FGrille.ColWidths[2] := (Largeur * 15) div 100;
  FGrille.ColWidths[1] := Largeur - FGrille.ColWidths[0] - FGrille.ColWidths[2] - 25;
  FBarre.Height := 50;
  PlacerBoutons;
end;

// Trois boutons (230/250) ; quand Nouvelle et Modifier existent, quatre boutons de 200 pour tenir dans 820.
procedure TPanelQualitesLiees.PlacerBoutons;
begin
  if Assigned(FOnModifier) then
  begin
    FBoutonAjouter.SetBounds(0, 0, 200, 50);
    FBoutonRetirer.SetBounds(205, 0, 200, 50);
    FBoutonNouvelle.SetBounds(410, 0, 200, 50);
    FBoutonModifier.SetBounds(615, 0, 200, 50);
  end
  else
  begin
    FBoutonAjouter.SetBounds(0, 0, 230, 50);
    FBoutonRetirer.SetBounds(240, 0, 250, 50);
    FBoutonNouvelle.SetBounds(500, 0, 250, 50);
  end;
end;

procedure TPanelQualitesLiees.SetOnNouvelle(Valeur: TNotifyEvent);
begin
  FOnNouvelle := Valeur;
  if FBoutonNouvelle <> nil then
  begin
    FBoutonNouvelle.OnClick := Valeur;
    FBoutonNouvelle.Visible := Assigned(Valeur);
  end;
end;

procedure TPanelQualitesLiees.SetOnModifier(Valeur: TNotifyEvent);
begin
  FOnModifier := Valeur;
  if FBoutonModifier <> nil then
  begin
    FBoutonModifier.OnClick := Valeur;
    FBoutonModifier.Visible := Assigned(Valeur);
    PlacerBoutons;
  end;
end;

function TPanelQualitesLiees.CodeSelectionne: String;
begin
  Result := '';
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    Result := CodeDeLibelle(Trim(FGrille.Cells[0, FGrille.Row]));
end;

function TPanelQualitesLiees.LibelleDeCode(const Code: String): String;
var
  I: Integer;
begin
  I := FCodes.IndexOf(Code);
  if I >= 0 then Result := FLibelles[I] else Result := Code;
end;

// Code ecrit pour un libelle choisi ; une saisie qui n'est pas dans la liste est gardee telle quelle.
function TPanelQualitesLiees.CodeDeLibelle(const Lib: String): String;
var
  I: Integer;
begin
  I := FLibelles.IndexOf(Lib);
  if I >= 0 then Result := FCodes[I] else Result := Lib;
end;

procedure TPanelQualitesLiees.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Combo: TCustomComboBox;
begin
  if (aRow < 1) or (aCol = 1) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  Combo := TCustomComboBox(Editor);
  Combo.Style := csDropDownList;
  Combo.Items.Clear;
  if aCol = 2 then
  begin
    // colonne Or : vide = qualite seule, sinon la ligne fait partie du groupe d'alternatives
    Combo.Items.Add('');
    Combo.Items.Add(GetTexteLibelle('RULES-LAB_494'));
  end
  else
    Combo.Items.AddStrings(FLibelles);
end;

procedure TPanelQualitesLiees.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Cells[0, R] := '';
  FGrille.Cells[1, R] := '';
  FGrille.Cells[2, R] := '';
  FGrille.Row := R;
end;

procedure TPanelQualitesLiees.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if FGrille.Row >= 1 then
    FGrille.DeleteRow(FGrille.Row);
end;

procedure TPanelQualitesLiees.Charger(const Texte: String);
var
  Liste, Parts: TStringList;
  I, J: Integer;
  Qual, Reste: String;
begin
  FGrille.RowCount := 1;
  if (Texte = '') or (Texte = '-') then Exit;
  Liste := TStringList.Create;
  Parts := TStringList.Create;
  try
    Liste.Delimiter := ',';
    Liste.StrictDelimiter := True;
    Liste.DelimitedText := Texte;
    Parts.Delimiter := '/';
    Parts.StrictDelimiter := True;
    for I := 0 to Liste.Count - 1 do
    begin
      if Trim(Liste[I]) = '' then Continue;
      // "A 2/B 3" : une ligne par partie, chacune avec sa valeur, toutes marquees Or
      Parts.DelimitedText := Trim(Liste[I]);
      for J := 0 to Parts.Count - 1 do
      begin
        Qual := Trim(Parts[J]);
        Reste := '';
        if Pos(' ', Qual) > 0 then
        begin
          Reste := Trim(Copy(Qual, Pos(' ', Qual) + 1, Length(Qual)));
          Qual := Copy(Qual, 1, Pos(' ', Qual) - 1);
        end;
        FGrille.RowCount := FGrille.RowCount + 1;
        FGrille.Cells[0, FGrille.RowCount - 1] := LibelleDeCode(Qual);
        FGrille.Cells[1, FGrille.RowCount - 1] := Reste;
        if Parts.Count > 1 then
          FGrille.Cells[2, FGrille.RowCount - 1] := GetTexteLibelle('RULES-LAB_494')
        else
          FGrille.Cells[2, FGrille.RowCount - 1] := '';
      end;
    end;
  finally
    Parts.Free;
    Liste.Free;
  end;
end;

function TPanelQualitesLiees.Texte: String;
var
  I, NbOr: Integer;
  Groupe, Un: String;
  GroupeEmis: Boolean;

  function UnePartie(Ligne: Integer): String;
  begin
    Result := CodeDeLibelle(Trim(FGrille.Cells[0, Ligne]));
    if (Result <> '') and (Trim(FGrille.Cells[1, Ligne]) <> '') then
      Result := Result + ' ' + Trim(FGrille.Cells[1, Ligne]);
  end;

  function EstOr(Ligne: Integer): Boolean;
  begin
    Result := (Trim(FGrille.Cells[2, Ligne]) <> '') and (CodeDeLibelle(Trim(FGrille.Cells[0, Ligne])) <> '');
  end;

begin
  Result := '';
  FGrille.EditorMode := False;
  // les lignes marquees Or forment ENSEMBLE un groupe d'alternatives (une seule ligne marquee : qualite ordinaire)
  NbOr := 0;
  Groupe := '';
  for I := 1 to FGrille.RowCount - 1 do
    if EstOr(I) then
    begin
      Inc(NbOr);
      if Groupe <> '' then Groupe := Groupe + '/';
      Groupe := Groupe + UnePartie(I);
    end;
  GroupeEmis := False;
  for I := 1 to FGrille.RowCount - 1 do
  begin
    Un := UnePartie(I);
    if Un = '' then Continue;
    if (NbOr >= 2) and EstOr(I) then
    begin
      if GroupeEmis then Continue;  // le groupe est ecrit une fois, a la place de sa premiere ligne
      GroupeEmis := True;
      Un := Groupe;
    end;
    if Result <> '' then Result := Result + ',';
    Result := Result + Un;
  end;
  if Result = '' then Result := '-';
end;

procedure TPanelQualitesLiees.SetLectureSeule(Valeur: Boolean);
begin
  FGrille.EditorMode := False;
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
end;

// Valeur d'une qualite : un entier (3), un entier signe (+1, une munition qui ajoute au Blast) ou un de (1d10).
function ValeurQualiteValide(const V: String): Boolean;
var
  I, D, Debut: Integer;
begin
  Result := False;
  if V = '' then Exit;
  Debut := 1;
  if V[1] in ['+', '-'] then Debut := 2;
  if Debut > Length(V) then Exit;
  D := 0;
  for I := Debut to Length(V) do
    if (V[I] in ['d', 'D']) and (D = 0) and (I > Debut) and (I < Length(V)) and (Debut = 1) then
      D := I
    else if not (V[I] in ['0'..'9']) then
      Exit;
  Result := True;
end;

function TPanelQualitesLiees.Controler: Boolean;
var
  I: Integer;
  Code, Lib, Valeur: String;
begin
  Result := True;
  if FCodesAvecValeur = nil then Exit;
  FGrille.EditorMode := False;
  for I := 1 to FGrille.RowCount - 1 do
  begin
    Lib := Trim(FGrille.Cells[0, I]);
    Code := CodeDeLibelle(Lib);
    if (Code = '') or (FCodesAvecValeur.IndexOf(Code) < 0) then Continue;
    Valeur := Trim(FGrille.Cells[1, I]);
    if Valeur = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_496'), [I, Lib]));
      FGrille.Row := I;
      Result := False;
      Exit;
    end;
    if not ValeurQualiteValide(Valeur) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_497'), [I, Lib]));
      FGrille.Row := I;
      Result := False;
      Exit;
    end;
  end;
end;

function TPanelQualitesLiees.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

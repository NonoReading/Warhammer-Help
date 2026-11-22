unit SaisieTableau;

{$mode ObjFPC}{$H+}

// Champ de fiche (genre gfTableau de PanelFiche) qui montre en tableau une valeur gardee EN TEXTE dans le XML :
// le XML ne change pas, les autres lecteurs (fiche animal, PDF, export) lisent toujours le meme texte.
// C'est un TEdit invisible qui porte le texte reel (PanelFiche le lit et l'ecrit comme n'importe quel champ texte) ;
// le tableau compagnon se met a jour quand le texte change, et reecrit le texte quand on le modifie.
//
// Choix (colonnes separees par |, la premiere entree donne la forme) :
//   'F' + separateur, puis un libelle par colonne : une ligne de valeurs fixes (profil : « 7 25 0 45 ... », separateur espace ;
//       « 32;4 (-);6 (8);-;25;50;60 », separateur point-virgule). Une seule ligne, les libelles en en-tete.
//   'T', puis 3 libelles (Trait, Specialisation, Valeur) : liste de traits separes par des virgules,
//       « Bestial, Size (Large), Trained (Broken, Mount), Weapon +7 » ; une ligne par trait, boutons Ajouter / Retirer.
//       Apres un « = » : les noms proposes (« Nom » ou « Nom<tab>S|N|P » : S specialisation, N nombre, P l'un ou l'autre).
//   'Q', puis 2 libelles (Fabrication, Niveau) : « CODE niveau,CODE niveau » ; la grille montre le libelle du code.
//       Apres un « = » : « code<tab>libelle » des fabrications proposees.
//   'E', puis 1 libelle (en-tete), puis « code=libelle » des valeurs proposees : liste de codes (races d'une carriere) ;
//       le texte reel les separe par une TABULATION (le code d'une valeur libre peut contenir des virgules) ; une ligne par code,
//       la grille montre le libelle, boutons Ajouter / Retirer. PanelFiche range chaque ligne dans une balise repetee (Specie, Specie#2...).

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, BCButton, BCLabelContour, ChargeTexte, GlobalFonts;

type
  TSaisieTableau = class(TEdit)
  private
    FPanneau: TPanel;
    FGrille: TStringGrid;
    FAjouter, FRetirer: TBCButton;
    FFixe: Boolean;
    FSep: String;
    FNb: Integer;        // colonnes
    FEnCours: Boolean;   // vrai pendant une mise a jour croisee texte <-> tableau
    FDernier: String;    // dernier texte ecrit par le tableau lui-meme : un changement de texte identique n'est pas externe
    FPropositions: TStringList;  // mode T : noms de traits proposes dans la liste deroulante de la premiere colonne
    FExigences: TStringList;     // mode T : « nom=S » (specialisation obligatoire), « =N » (nombre), « =P » (l'un ou l'autre)
    FQual: Boolean;              // mode Q : « CODE niveau,CODE niveau » ; la grille montre le libelle du code
    FListe: Boolean;             // mode E : une colonne, codes separes par une tabulation ; la grille montre le libelle du code
    FCodesProp: TStringList;     // mode Q : code de chaque nom propose (meme rang que FPropositions)
    function  LibelleDeCode(const Code: String): String;
    function  CodeDeLibelle(const Libelle: String): String;
    procedure VersGrille;
    procedure VersTexte(ACol: Integer = -1; ARow: Integer = -1; const Valeur: String = '');
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: String);
    procedure GrilleEditingDone(Sender: TObject);
    procedure AjouterClick(Sender: TObject);
    procedure RetirerClick(Sender: TObject);
  protected
    procedure TextChanged; override;
  public
    destructor Destroy; override;
    // pose le tableau compagnon (meme parent que le champ) ; Hauteur : voir HauteurTableau
    procedure Monter(Modele: TBCButton; const Choix: String; X, Y, L, H: Integer);
    procedure MettreLectureSeule(Valeur: Boolean);
    // mode T : False (avec le message a montrer) si un trait connu manque de sa specialisation ou de son nombre
    function  Controle(out Message: String): Boolean;
  end;

// hauteur du tableau compagnon selon la forme (Choix)
function HauteurTableau(const Choix: String): Integer;

implementation

function HauteurTableau(const Choix: String): Integer;
begin
  if (Choix <> '') and (Choix[1] = 'F') then Result := 62 else Result := 176;
end;

// Traits separes par des virgules hors parentheses
procedure DecouperTraits(const S: String; Liste: TStringList);
var
  I, Prof: Integer;
  Cur: String;
begin
  Liste.Clear;
  if Trim(S) = '' then Exit;
  Prof := 0;
  Cur := '';
  for I := 1 to Length(S) do
  begin
    if S[I] = '(' then Inc(Prof)
    else if S[I] = ')' then Dec(Prof);
    if (S[I] = ',') and (Prof = 0) then
    begin
      Liste.Add(Trim(Cur));
      Cur := '';
    end
    else Cur := Cur + S[I];
  end;
  Liste.Add(Trim(Cur));
end;

function ValeurNumerique(const T: String): Boolean;
begin
  // un chiffre en tete, ou un signe suivi d'un chiffre (« 100 », « +7 », « -1 »)
  Result := (T <> '') and ((T[1] in ['0'..'9']) or ((Length(T) > 1) and (T[1] in ['+', '-']) and (T[2] in ['0'..'9'])));
end;

// « Size (Large) », « Weapon +7 », « Fly 100 », « Trained (Broken, Mount) » -> nom, specialisation, valeur
procedure AnalyserTrait(const P: String; out Nom, Spec, Valeur: String);
var
  A, B, K: Integer;
  Reste: String;
begin
  Spec := '';
  Valeur := '';
  A := Pos('(', P);
  B := 0;
  for K := Length(P) downto 1 do
    if P[K] = ')' then begin B := K; Break; end;
  if (A > 0) and (B > A) then
  begin
    Nom := Trim(Copy(P, 1, A - 1));
    Spec := Copy(P, A + 1, B - A - 1);
    Valeur := Trim(Copy(P, B + 1, MaxInt));
    Exit;
  end;
  Nom := P;
  K := Length(P);
  while (K > 0) and (P[K] <> ' ') do Dec(K);
  if K > 1 then
  begin
    Reste := Copy(P, K + 1, MaxInt);
    if ValeurNumerique(Reste) then
    begin
      Nom := Trim(Copy(P, 1, K - 1));
      Valeur := Reste;
    end;
  end;
end;

function TSaisieTableau.Controle(out Message: String): Boolean;
var
  R: Integer;
  Nom, Spec, Valeur, Exigence: String;
begin
  Result := True;
  Message := '';
  if FFixe or (FGrille = nil) or (FExigences = nil) then Exit;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    Nom := Trim(FGrille.Cells[0, R]);
    if Nom = '' then Continue;
    Spec := Trim(FGrille.Cells[1, R]);
    Valeur := Trim(FGrille.Cells[2, R]);
    if Pos(')', Spec) > 0 then Continue;  // trait compose (« Weapon (Claws) +10 (Fast, Penetrating) ») : laisse tel que le livre l'ecrit
    Exigence := FExigences.Values[LowerCase(Nom)];
    if (Exigence = 'S') and (Spec = '') then
      Message := Format(GetTexteLibelle('RULES-LAB_TAB_ERR_SPEC', '%s: a specialisation is required.'), [Nom])
    else if (Exigence = 'N') and (Valeur = '') then
      Message := Format(GetTexteLibelle('RULES-LAB_TAB_ERR_VALEUR', '%s: a number is required.'), [Nom])
    else if (Exigence = 'P') and (Spec = '') and (Valeur = '') then
      Message := Format(GetTexteLibelle('RULES-LAB_TAB_ERR_PARAM', '%s: a specialisation or a number is required.'), [Nom]);
    if Message <> '' then
    begin
      FGrille.Row := R;
      Result := False;
      Exit;
    end;
  end;
end;

function TSaisieTableau.LibelleDeCode(const Code: String): String;
var
  K: Integer;
begin
  Result := Code;
  if FCodesProp = nil then Exit;
  K := FCodesProp.IndexOf(Code);
  if K >= 0 then Result := FPropositions[K];
end;

function TSaisieTableau.CodeDeLibelle(const Libelle: String): String;
var
  K: Integer;
begin
  Result := Libelle;
  if FCodesProp = nil then Exit;
  K := FPropositions.IndexOf(Libelle);
  if K >= 0 then Result := FCodesProp[K];
end;

destructor TSaisieTableau.Destroy;
begin
  FCodesProp.Free;
  FExigences.Free;
  FPropositions.Free;
  inherited Destroy;
end;

procedure TSaisieTableau.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if FFixe or (aRow < 1) or (aCol <> 0) or (FPropositions = nil) or (FPropositions.Count = 0) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);  // liste proposee
  if Editor is TCustomComboBox then TCustomComboBox(Editor).Items.Assign(FPropositions);
end;

procedure TSaisieTableau.Monter(Modele: TBCButton; const Choix: String; X, Y, L, H: Integer);
var
  Entrees: TStringList;
  I, Larg: Integer;
begin
  Entrees := TStringList.Create;
  try
    Entrees.Delimiter := '|';
    Entrees.StrictDelimiter := True;
    Entrees.DelimitedText := Choix;
    FFixe := (Entrees.Count > 0) and (Copy(Entrees[0], 1, 1) = 'F');
    if FFixe then
    begin
      if Length(Entrees[0]) > 1 then FSep := Entrees[0][2] else FSep := ' ';
      FNb := Entrees.Count - 1;
    end
    else
    begin
      FSep := ',';
      FQual := (Entrees.Count > 0) and (Copy(Entrees[0], 1, 1) = 'Q');
      FListe := (Entrees.Count > 0) and (Entrees[0] = 'E');
      if FListe then FNb := 1
      else if FQual then FNb := 2
      else FNb := 3;
    end;
    FPanneau := TPanel.Create(Self);
    FPanneau.Parent := Parent;
    FPanneau.BevelOuter := bvNone;
    FPanneau.Caption := '';
    FPanneau.SetBounds(X, Y + 22, L, H);
    FGrille := TStringGrid.Create(Self);
    FGrille.Parent := FPanneau;
    CouleurSelectionGrille(FGrille);
    FGrille.ColCount := FNb;
    FGrille.FixedCols := 0;
    FGrille.FixedRows := 1;
    FGrille.RowCount := 2;
    FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
    FGrille.OnSetEditText := @GrilleSetEditText;
    FGrille.OnEditingDone := @GrilleEditingDone;
    for I := 0 to FNb - 1 do
      if I + 1 < Entrees.Count then FGrille.Cells[I, 0] := Entrees[I + 1];
    // mode T : apres un « = », les noms proposes dans la liste deroulante de la premiere colonne
    if FQual or FListe then
    begin
      // mode Q « code<tab>libelle », mode E « code=libelle » : la grille montre le libelle, le texte garde le code
      FPropositions := TStringList.Create;
      FCodesProp := TStringList.Create;
      if FListe then
      begin
        for I := 2 to Entrees.Count - 1 do
          if Pos('=', Entrees[I]) > 0 then
          begin
            FCodesProp.Add(Copy(Entrees[I], 1, Pos('=', Entrees[I]) - 1));
            FPropositions.Add(Copy(Entrees[I], Pos('=', Entrees[I]) + 1, MaxInt));
          end;
      end
      else
        for I := 3 to Entrees.Count - 1 do
          if Pos(#9, Entrees[I]) > 0 then
          begin
            FCodesProp.Add(Copy(Entrees[I], 1, Pos(#9, Entrees[I]) - 1));
            FPropositions.Add(Copy(Entrees[I], Pos(#9, Entrees[I]) + 1, MaxInt));
          end;
      FGrille.OnSelectEditor := @GrilleSelectEditor;
    end
    else if not FFixe then
    begin
      FPropositions := TStringList.Create;
      FExigences := TStringList.Create;
      // « Nom » ou « Nom<tab>S|N|P » : la lettre dit ce que le trait exige
      for I := 5 to Entrees.Count - 1 do
        if Pos(#9, Entrees[I]) > 0 then
        begin
          FPropositions.Add(Copy(Entrees[I], 1, Pos(#9, Entrees[I]) - 1));
          FExigences.Add(LowerCase(Copy(Entrees[I], 1, Pos(#9, Entrees[I]) - 1)) + '=' + Copy(Entrees[I], Pos(#9, Entrees[I]) + 1, MaxInt));
        end
        else FPropositions.Add(Entrees[I]);
      FGrille.OnSelectEditor := @GrilleSelectEditor;
    end;
    Larg := L - 8;
    if FFixe then
    begin
      FGrille.SetBounds(0, 0, L, 58);
      for I := 0 to FNb - 1 do FGrille.ColWidths[I] := Larg div FNb;
    end
    else
    begin
      FGrille.SetBounds(0, 0, L, 132);
      if FListe then
        FGrille.ColWidths[0] := Larg - 24
      else if FQual then
      begin
        FGrille.ColWidths[0] := (Larg - 24) * 70 div 100;
        FGrille.ColWidths[1] := Larg - 24 - (Larg - 24) * 70 div 100;
      end
      else
      begin
        FGrille.ColWidths[0] := (Larg - 24) * 40 div 100;
        FGrille.ColWidths[1] := (Larg - 24) * 40 div 100;
        FGrille.ColWidths[2] := Larg - 24 - 2 * ((Larg - 24) * 40 div 100);
      end;
      FAjouter := TBCButtonContour.Create(Self);
      FAjouter.Assign(Modele);
      FAjouter.Parent := FPanneau;
      FAjouter.Caption := GetTexteLibelle('RULES-LAB_899');
      FAjouter.OnClick := @AjouterClick;
      FAjouter.SetBounds(0, 138, 200, 32);
      FRetirer := TBCButtonContour.Create(Self);
      FRetirer.Assign(Modele);
      FRetirer.Parent := FPanneau;
      FRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
      FRetirer.OnClick := @RetirerClick;
      FRetirer.SetBounds(210, 138, 200, 32);
    end;
  finally
    Entrees.Free;
  end;
  Visible := False;  // le texte reel reste lu et ecrit par la fiche ; seul le tableau se voit
  MiseAJourUnContenaire(FPanneau);
  StylesTStringGrid(FGrille);  // la grille appartient au champ, pas au panneau : MiseAJourUnContenaire ne la voit pas
  VersGrille;
end;

procedure TSaisieTableau.TextChanged;
begin
  inherited TextChanged;
  if (FGrille <> nil) and not FEnCours and (Text <> FDernier) then VersGrille;
end;

procedure TSaisieTableau.VersGrille;
var
  Morceaux: TStringList;
  I, R: Integer;
  Nom, Spec, Valeur, S: String;
begin
  if FGrille = nil then Exit;
  FEnCours := True;
  Morceaux := TStringList.Create;
  try
    FGrille.EditorMode := False;
    S := Trim(Text);
    if FFixe then
    begin
      FGrille.RowCount := 2;
      for I := 0 to FNb - 1 do FGrille.Cells[I, 1] := '';
      if S <> '' then
      begin
        if FSep = ' ' then
        begin
          Morceaux.Delimiter := ' ';
          Morceaux.StrictDelimiter := True;
          Morceaux.DelimitedText := S;
          for I := Morceaux.Count - 1 downto 0 do
            if Morceaux[I] = '' then Morceaux.Delete(I);
        end
        else
        begin
          Morceaux.Delimiter := FSep[1];
          Morceaux.StrictDelimiter := True;
          Morceaux.DelimitedText := S;
        end;
        for I := 0 to Morceaux.Count - 1 do
          if I < FNb - 1 then FGrille.Cells[I, 1] := Morceaux[I]
          else if I = FNb - 1 then FGrille.Cells[I, 1] := Morceaux[I]
          else FGrille.Cells[FNb - 1, 1] := FGrille.Cells[FNb - 1, 1] + FSep + Morceaux[I];
      end;
    end
    else if FListe then
    begin
      // « CODE<tab>CODE » : un code par ligne, la grille montre son libelle
      Morceaux.Delimiter := #9;
      Morceaux.StrictDelimiter := True;
      Morceaux.DelimitedText := S;
      if S = '' then Morceaux.Clear;
      FGrille.RowCount := Morceaux.Count + 1;
      if FGrille.RowCount < 2 then FGrille.RowCount := 2;
      FGrille.Cells[0, 1] := '';
      for R := 0 to Morceaux.Count - 1 do
        FGrille.Cells[0, R + 1] := LibelleDeCode(Trim(Morceaux[R]));
    end
    else if FQual then
    begin
      // « RULES-QUALITY_04 4,RULES-QUALITY_03 1 » : un code et son niveau par ligne
      Morceaux.Delimiter := ',';
      Morceaux.StrictDelimiter := True;
      Morceaux.DelimitedText := S;
      if S = '' then Morceaux.Clear;
      FGrille.RowCount := Morceaux.Count + 1;
      if FGrille.RowCount < 2 then FGrille.RowCount := 2;
      for R := 1 to FGrille.RowCount - 1 do
      begin
        FGrille.Cells[0, R] := '';
        FGrille.Cells[1, R] := '';
      end;
      for R := 0 to Morceaux.Count - 1 do
      begin
        Nom := Trim(Morceaux[R]);
        Valeur := '';
        I := Length(Nom);
        while (I > 0) and (Nom[I] in ['0'..'9']) do Dec(I);
        if (I > 0) and (I < Length(Nom)) and (Nom[I] = ' ') then
        begin
          Valeur := Copy(Nom, I + 1, MaxInt);
          Nom := Trim(Copy(Nom, 1, I - 1));
        end;
        FGrille.Cells[0, R + 1] := LibelleDeCode(Nom);
        FGrille.Cells[1, R + 1] := Valeur;
      end;
    end
    else
    begin
      DecouperTraits(S, Morceaux);
      FGrille.RowCount := Morceaux.Count + 1;
      if FGrille.RowCount < 2 then FGrille.RowCount := 2;
      for R := 1 to FGrille.RowCount - 1 do
      begin
        FGrille.Cells[0, R] := '';
        FGrille.Cells[1, R] := '';
        FGrille.Cells[2, R] := '';
      end;
      for R := 0 to Morceaux.Count - 1 do
      begin
        AnalyserTrait(Morceaux[R], Nom, Spec, Valeur);
        FGrille.Cells[0, R + 1] := Nom;
        FGrille.Cells[1, R + 1] := Spec;
        FGrille.Cells[2, R + 1] := Valeur;
      end;
    end;
  finally
    Morceaux.Free;
    FEnCours := False;
  end;
end;

procedure TSaisieTableau.VersTexte(ACol: Integer; ARow: Integer; const Valeur: String);
var
  I, R: Integer;
  Cellule, Ligne, Resultat: String;
  Tout: Boolean;

  // contenu d'une cellule : la valeur en cours de saisie remplace celle de la grille (l'editeur ne l'y a pas encore posee)
  function Cell(C, L: Integer): String;
  begin
    if (C = ACol) and (L = ARow) then Result := Trim(Valeur) else Result := Trim(FGrille.Cells[C, L]);
  end;
begin
  if FGrille = nil then Exit;
  Resultat := '';
  if FFixe then
  begin
    Tout := False;
    for I := 0 to FNb - 1 do
      if Cell(I, 1) <> '' then Tout := True;
    if Tout then
      for I := 0 to FNb - 1 do
      begin
        Cellule := Cell(I, 1);
        if (Cellule = '') and (FSep = ' ') then Cellule := '0';  // une case vide decalerait les valeurs suivantes
        if I > 0 then Resultat := Resultat + FSep;
        Resultat := Resultat + Cellule;
      end;
  end
  else if FListe then
  begin
    for R := 1 to FGrille.RowCount - 1 do
      if Cell(0, R) <> '' then
      begin
        if Resultat <> '' then Resultat := Resultat + #9;
        Resultat := Resultat + CodeDeLibelle(Cell(0, R));
      end;
  end
  else if FQual then
  begin
    for R := 1 to FGrille.RowCount - 1 do
      if Cell(0, R) <> '' then
      begin
        Ligne := CodeDeLibelle(Cell(0, R));
        if Cell(1, R) <> '' then Ligne := Ligne + ' ' + Cell(1, R);
        if Resultat <> '' then Resultat := Resultat + ',';
        Resultat := Resultat + Ligne;
      end;
  end
  else
    for R := 1 to FGrille.RowCount - 1 do
      if Cell(0, R) <> '' then
      begin
        Ligne := Cell(0, R);
        if Cell(1, R) <> '' then Ligne := Ligne + ' (' + Cell(1, R) + ')';
        if Cell(2, R) <> '' then Ligne := Ligne + ' ' + Cell(2, R);
        if Resultat <> '' then Resultat := Resultat + ', ';
        Resultat := Resultat + Ligne;
      end;
  FEnCours := True;
  try
    FDernier := Resultat;
    if Text <> Resultat then Text := Resultat;
  finally
    FEnCours := False;
  end;
end;

procedure TSaisieTableau.GrilleSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: String);
begin
  if FEnCours then Exit;
  VersTexte(ACol, ARow, Value);
end;

procedure TSaisieTableau.GrilleEditingDone(Sender: TObject);
begin
  if not FEnCours then VersTexte;
end;

procedure TSaisieTableau.AjouterClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := FGrille.RowCount + 1;
  FGrille.Row := FGrille.RowCount - 1;
end;

procedure TSaisieTableau.RetirerClick(Sender: TObject);
var
  I: Integer;
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
  begin
    if FGrille.RowCount > 2 then FGrille.DeleteRow(FGrille.Row)
    else
      for I := 0 to FNb - 1 do FGrille.Cells[I, 1] := '';
    VersTexte;
  end;
end;

procedure TSaisieTableau.MettreLectureSeule(Valeur: Boolean);
begin
  if FGrille = nil then Exit;
  if Valeur then FGrille.Options := FGrille.Options - [goEditing]
  else FGrille.Options := FGrille.Options + [goEditing];
  if FAjouter <> nil then FAjouter.Visible := not Valeur;
  if FRetirer <> nil then FRetirer.Visible := not Valeur;
end;

end.

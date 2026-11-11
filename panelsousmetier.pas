unit PanelSousMetier;

{$mode ObjFPC}{$H+}

// Table editable du second jet apres le jet de metier (DATA_CAREER_SUBCHOICE, CONTEXT.md 2.107) : pour chaque
// metier de depart, des metiers obtenus avec leur fourchette du d100. Une ligne par metier obtenu ; plusieurs
// lignes de meme depart ET de meme fourchette forment un choix, ecrit A/B/C dans une seule <Alternative>.
//
// Chaque bloc s'ecrit <Choice><Career>"X"</Career><Alternative name="A/B">"01-95"</Alternative></Choice>.
// Les fourchettes d'un meme metier de depart couvrent 1 a 100, sans trou ni chevauchement.
// Le bloc est reecrit en entier : aucun commentaire n'y est admis (ils feraient planter le chargement).
// Usage : creer, Initialiser, poser (Parent + SetBounds), Configurer puis Charger(Chapitre) a l'ouverture,
// Controler puis Ecrire(Chapitre) a la validation. Chapitre = l'element DATA_CAREER_SUBCHOICE du livre.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, Graphics, DOM, BCButton,
  ChargeConstantes, ChargeTexte, GlobalFonts, PanelModificateurs, PanelTirage;

type
  TPanelSousMetier = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FLibCarriere: TFonctionLibelleTirage;
    FCarrieresLib, FCarrieresCode: TStringList;
    function  LibCarriere(const Code: String): String;
    function  CodeCarriereDe(const Lib: String): String;
    function  Debut(R: Integer): Integer;
    function  Fin(R: Integer): Integer;
    function  CleGroupe(R: Integer): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonValiderClick(Sender: TObject);
    procedure BoutonAnnulerClick(Sender: TObject);
    function  GetLectureSeule: Boolean;
    procedure SetLectureSeule(Valeur: Boolean);
    function  Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
      Gauche, Largeur: Integer): TBCButton;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger. Carrieres : codes que le choix d'une ligne propose.
    procedure Configurer(ALibCarriere: TFonctionLibelleTirage; Carrieres: TStrings);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

implementation

constructor TPanelSousMetier.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCarrieresLib := TStringList.Create;
  FCarrieresCode := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 4;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  Visible := False;
end;

destructor TPanelSousMetier.Destroy;
begin
  FCarrieresLib.Free;
  FCarrieresCode.Free;
  inherited Destroy;
end;

function TPanelSousMetier.Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
  Gauche, Largeur: Integer): TBCButton;
begin
  Result := TBCButtonContour.Create(Self);
  Result.Assign(Modele);
  Result.Parent := Barre;
  Result.Caption := Legende;
  Result.OnClick := Clic;
  Result.SetBounds(Gauche, 0, Largeur, 50);
end;

procedure TPanelSousMetier.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230);
  FBoutonRetirer := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250);
  FBoutonValider := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_086'), @BoutonValiderClick, 500, 150);
  FBoutonAnnuler := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_166'), @BoutonAnnulerClick, 660, 150);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

// Libelle du metier dans la grille ; un code hors liste proposee y est ajoute.
function TPanelSousMetier.LibCarriere(const Code: String): String;
var
  I: Integer;
begin
  I := FCarrieresCode.IndexOf(Code);
  if I >= 0 then Exit(FCarrieresLib[I]);
  Result := FLibCarriere(Code);
  if FCarrieresLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FCarrieresLib.Add(Result);
  FCarrieresCode.Add(Code);
end;

function TPanelSousMetier.CodeCarriereDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FCarrieresLib.IndexOf(Lib);
  if I >= 0 then Result := FCarrieresCode[I];
end;

function TPanelSousMetier.Debut(R: Integer): Integer;
begin
  Result := StrToIntDef(Trim(FGrille.Cells[2, R]), 0);
end;

// Une fin vide vaut le debut (jet unique).
function TPanelSousMetier.Fin(R: Integer): Integer;
begin
  if Trim(FGrille.Cells[3, R]) = '' then
    Result := Debut(R)
  else
    Result := StrToIntDef(Trim(FGrille.Cells[3, R]), 0);
end;

// Depart + fourchette : les lignes qui la partagent forment un seul choix.
function TPanelSousMetier.CleGroupe(R: Integer): String;
begin
  Result := CodeCarriereDe(FGrille.Cells[0, R]) + #9 + IntToStr(Debut(R)) + #9 + IntToStr(Fin(R));
end;

procedure TPanelSousMetier.Configurer(ALibCarriere: TFonctionLibelleTirage; Carrieres: TStrings);
var
  I: Integer;
begin
  FLibCarriere := ALibCarriere;
  FCarrieresLib.Clear;
  FCarrieresCode.Clear;
  for I := 0 to Carrieres.Count - 1 do
    LibCarriere(Carrieres[I]);
  FGrille.ColWidths[0] := 300;
  FGrille.ColWidths[1] := 300;
  FGrille.ColWidths[2] := 100;
  FGrille.ColWidths[3] := 100;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_587', 'Starting career');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_588', 'Career obtained');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_141');
  FGrille.Cells[3, 0] := GetTexteLibelle('RULES-LAB_142');
end;

procedure TPanelSousMetier.Charger(Chapitre: TDOMElement);
var
  N, A: TDOMNode;
  Depart, Plage: String;
  Codes: TStringList;
  P, R, I: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  if Chapitre = nil then Exit;
  Codes := TStringList.Create;
  try
    Codes.Delimiter := '/';
    Codes.StrictDelimiter := True;
    N := Chapitre.FirstChild;
    while N <> nil do
    begin
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Choice') then
      begin
        Depart := ValeurXML(N.FindNode('Career'));
        A := N.FindNode('Alternative');
        if (Depart <> '') and (A <> nil) then
        begin
          Plage := ValeurXML(A);
          Codes.DelimitedText := TDOMElement(A).GetAttribute('name');
          for I := 0 to Codes.Count - 1 do
          begin
            R := FGrille.RowCount;
            FGrille.RowCount := R + 1;
            FGrille.Cells[0, R] := LibCarriere(Depart);
            FGrille.Cells[1, R] := LibCarriere(Trim(Codes[I]));
            P := Pos('-', Plage);
            if P > 0 then
            begin
              FGrille.Cells[2, R] := IntToStr(StrToIntDef(Copy(Plage, 1, P - 1), 0));
              FGrille.Cells[3, R] := IntToStr(StrToIntDef(Copy(Plage, P + 1, MaxInt), 0));
            end
            else
            begin
              FGrille.Cells[2, R] := IntToStr(StrToIntDef(Plage, 0));
              FGrille.Cells[3, R] := FGrille.Cells[2, R];
            end;
          end;
        end;
      end;
      N := N.NextSibling;
    end;
  finally
    Codes.Free;
  end;
end;

// Ordre de la grille ; les lignes de meme depart et de meme fourchette se regroupent en une alternative A/B/C,
// a la place de la premiere.
procedure TPanelSousMetier.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  Choix, E: TDOMElement;
  R, K: Integer;
  Dejas: TStringList;
  Cle, Noms, Plage: String;
begin
  FGrille.EditorMode := False;
  Doc := Chapitre.OwnerDocument;
  while Chapitre.FirstChild <> nil do
    Chapitre.RemoveChild(Chapitre.FirstChild);
  Dejas := TStringList.Create;
  try
    for R := 1 to FGrille.RowCount - 1 do
    begin
      Cle := CleGroupe(R);
      if Dejas.IndexOf(Cle) >= 0 then Continue;
      Dejas.Add(Cle);
      Noms := '';
      for K := R to FGrille.RowCount - 1 do
        if CleGroupe(K) = Cle then
        begin
          if Noms <> '' then Noms := Noms + '/';
          Noms := Noms + CodeCarriereDe(FGrille.Cells[1, K]);
        end;
      if Debut(R) = Fin(R) then
        Plage := Format('%.2d', [Debut(R)])
      else
        Plage := Format('%.2d-%.2d', [Debut(R), Fin(R)]);
      Choix := Doc.CreateElement('Choice');
      Chapitre.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(Choix);
      E := Doc.CreateElement('Career');
      Choix.AppendChild(Doc.CreateTextNode(#10));
      Choix.AppendChild(E);
      EcrireValeurXML(E, CodeCarriereDe(FGrille.Cells[0, R]));
      E := Doc.CreateElement('Alternative');
      E.SetAttribute('name', Noms);
      Choix.AppendChild(Doc.CreateTextNode(#10));
      Choix.AppendChild(E);
      EcrireValeurXML(E, Plage);
      Choix.AppendChild(Doc.CreateTextNode(#10));
    end;
    Chapitre.AppendChild(Doc.CreateTextNode(#10));
  finally
    Dejas.Free;
  end;
end;

function TPanelSousMetier.Controler: Boolean;
var
  R, K: Integer;
  Departs, Plages: TStringList;
  Attendu: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if CodeCarriereDe(FGrille.Cells[0, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_589', 'Line %d: choose the starting career.'), [R]));
      Exit(False);
    end;
    if CodeCarriereDe(FGrille.Cells[1, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_590', 'Line %d: choose the career obtained.'), [R]));
      Exit(False);
    end;
    if (Debut(R) < 1) or (Fin(R) > 100) or (Fin(R) < Debut(R)) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_515',
        '%s: start and end must be numbers from 1 to 100, the start no greater than the end.'),
        [FGrille.Cells[0, R]]));
      Exit(False);
    end;
    for K := 1 to R - 1 do
      if (FGrille.Cells[0, K] = FGrille.Cells[0, R]) and (FGrille.Cells[1, K] = FGrille.Cells[1, R]) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_591',
          'Lines %d and %d: same starting career and same career obtained.'), [K, R]));
        Exit(False);
      end;
  end;
  // par depart : les fourchettes distinctes, triees, se suivent de 1 a 100 (meme fourchette = un choix)
  Departs := TStringList.Create;
  Plages := TStringList.Create;
  try
    Plages.Sorted := True;
    Plages.Duplicates := dupIgnore;
    for R := 1 to FGrille.RowCount - 1 do
      if Departs.IndexOf(FGrille.Cells[0, R]) < 0 then Departs.Add(FGrille.Cells[0, R]);
    for K := 0 to Departs.Count - 1 do
    begin
      Plages.Clear;
      for R := 1 to FGrille.RowCount - 1 do
        if FGrille.Cells[0, R] = Departs[K] then
          Plages.Add(Format('%.3d-%.3d', [Debut(R), Fin(R)]));
      Attendu := 1;
      for R := 0 to Plages.Count - 1 do
      begin
        if StrToInt(Copy(Plages[R], 1, 3)) <> Attendu then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-LAB_516',
            '%s: the range must start at %d (no gap, no overlap).'), [Departs[K], Attendu]));
          Exit(False);
        end;
        Attendu := StrToInt(Copy(Plages[R], 5, 3)) + 1;
      end;
      if Attendu <> 101 then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_517', 'The table must reach 100: it ends at %d.'), [Attendu - 1]));
        Exit(False);
      end;
    end;
  finally
    Departs.Free;
    Plages.Free;
  end;
end;

procedure TPanelSousMetier.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if (aRow < 1) or (aCol > 1) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  TCustomComboBox(Editor).Items.Assign(FCarrieresLib);
end;

procedure TPanelSousMetier.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  // une nouvelle ligne reprend le depart de la precedente : on ajoute le plus souvent au meme metier
  if R > 1 then FGrille.Cells[0, R] := FGrille.Cells[0, R - 1];
  FGrille.Row := R;
  FGrille.Col := 1;
end;

procedure TPanelSousMetier.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
end;

procedure TPanelSousMetier.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelSousMetier.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelSousMetier.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelSousMetier.GetLectureSeule: Boolean;
begin
  Result := not FBarre.Visible;
end;

procedure TPanelSousMetier.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
end;

procedure TPanelSousMetier.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelSousMetier.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

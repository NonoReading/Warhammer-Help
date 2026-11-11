unit PanelNoms;

{$mode ObjFPC}{$H+}

// Noms d'une ethnie (bloc SUBCHAPTER_NAMES de DATA_SPECIE, CONTEXT.md 2.107) dans sa fiche : trois grilles.
//  - Modeles : <NamePattern sex rule>"Forename Surname"</NamePattern> (texte libre, syntaxe du moteur).
//  - Regles : <NameRule code>"libelle"</NameRule>, qu'un modele peut reserver (rule="CODE").
//  - Noms : <Name part sex name="Adam/Adamar">"1-5"</Name>, dans l'ordre du de. La PLAGE n'est pas saisie : elle se
//    calcule d'apres l'ordre des lignes. Chaque nom garde un poids (largeur de sa plage, 1 pour un nom nouveau), qui
//    voyage avec lui : un nom a plage large du livre d'origine la garde, et un tableau non touche s'ecrit a l'identique.
// Une table de plages = une partie ; une partie dont les noms sont separes par sexe (aucun sans sexe) a une table par
// sexe ; une partie qui melange noms sans sexe et noms M/F (Suffix des Nains) est un seul de partage.
// Le bloc est reecrit en entier ; ses commentaires sont gardes, regroupes en tete du bloc.
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelNoms = class(TPanelExtraFiche)
  private
    FTitre: TLabel;
    FTitres: array[0..2] of TLabel;
    FGrilles: array[0..2] of TStringGrid;  // 0 = modeles, 1 = regles, 2 = noms
    FBoutons: array[0..2, 0..3] of TBCButton;  // ajouter, retirer, monter, descendre (les deux derniers : noms seuls)
    FLectureSeule: Boolean;
    FLibM, FLibF, FLibTous: String;  // libelles de sexe lus une fois : CodeSexe est appele pour chaque ligne
    function  LibSexe(const Code: String): String;
    function  CodeSexe(const Lib: String): String;
    procedure RecalculerPlages;
    function  Parties: TStringList;
    function  Regles: TStringList;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonMonterClick(Sender: TObject);
    procedure BoutonDescendreClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Initialiser(Modele: TBCButton);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  HauteurNoms = 800;
  YTitre: array[0..2] of Integer = (28, 252, 424);
  HautGrille: array[0..2] of Integer = (130, 100, 300);
  PartiesCourantes: array[0..9] of String = ('Forename', 'Surname', 'Place', 'Clan', 'Epithet', 'First', 'Second',
    'End', 'Prefix', 'Suffix');

constructor TPanelNoms.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurNoms;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 600, 20);
  for I := 0 to 2 do
  begin
    FTitres[I] := TLabelContour.Create(Self);
    FTitres[I].Parent := Self;
    FTitres[I].SetBounds(0, YTitre[I], 600, 20);
    FGrilles[I] := TStringGrid.Create(Self);
    FGrilles[I].Parent := Self;
    CouleurSelectionGrille(FGrilles[I]);
    FGrilles[I].SetBounds(0, YTitre[I] + 22, 840, HautGrille[I]);
    FGrilles[I].RowCount := 1;
    FGrilles[I].FixedRows := 1;
    FGrilles[I].FixedCols := 0;
    FGrilles[I].Options := FGrilles[I].Options + [goEditing] - [goRangeSelect];
    FGrilles[I].OnSelectEditor := @GrilleSelectEditor;
    FGrilles[I].OnSelectCell := @GrilleSelectCell;
    FGrilles[I].OnSetEditText := @GrilleSetEditText;
  end;
  FGrilles[0].ColCount := 3;
  FGrilles[0].ColWidths[0] := 110;
  FGrilles[0].ColWidths[1] := 540;
  FGrilles[0].ColWidths[2] := 160;
  FGrilles[1].ColCount := 2;
  FGrilles[1].ColWidths[0] := 160;
  FGrilles[1].ColWidths[1] := 640;
  FGrilles[2].ColCount := 5;
  FGrilles[2].ColWidths[0] := 150;
  FGrilles[2].ColWidths[1] := 100;
  FGrilles[2].ColWidths[2] := 440;
  FGrilles[2].ColWidths[3] := 110;
  FGrilles[2].ColWidths[4] := 0;  // poids : jamais saisi
  Visible := False;
end;

procedure TPanelNoms.Initialiser(Modele: TBCButton);
var
  I: Integer;

  function Copie(const Legende: String; Clic: TNotifyEvent; Gauche, Largeur, Y, Rang: Integer): TBCButton;
  begin
    Result := TBCButtonContour.Create(Self);
    Result.Assign(Modele);
    Result.Parent := Self;
    Result.Caption := Legende;
    Result.OnClick := Clic;
    Result.Tag := Rang;
    Result.SetBounds(Gauche, Y, Largeur, 36);
  end;

begin
  FLibM := GetTexteLibelle('RULES-LAB_268', 'Male');
  FLibF := GetTexteLibelle('RULES-LAB_269', 'Female');
  FLibTous := GetTexteLibelle('RULES-LAB_613', 'Both');
  FTitre.Caption := GetTexteLibelle('RULES-LAB_614', 'Names');
  FTitres[0].Caption := GetTexteLibelle('RULES-LAB_615', 'Name patterns');
  FTitres[1].Caption := GetTexteLibelle('RULES-LAB_616', 'Name rules');
  FTitres[2].Caption := GetTexteLibelle('RULES-LAB_621', 'Name tables (in dice order)');
  FGrilles[0].Cells[0, 0] := GetTexteLibelle('RULES-LAB_625', 'Sex');
  FGrilles[0].Cells[1, 0] := GetTexteLibelle('RULES-LAB_617', 'Pattern');
  FGrilles[0].Cells[2, 0] := GetTexteLibelle('RULES-LAB_618', 'Rule');
  FGrilles[1].Cells[0, 0] := GetTexteLibelle('RULES-LAB_001', 'Code');
  FGrilles[1].Cells[1, 0] := GetTexteLibelle('RULES-LAB_002', 'Label');
  FGrilles[2].Cells[0, 0] := GetTexteLibelle('RULES-LAB_620', 'Part');
  FGrilles[2].Cells[1, 0] := GetTexteLibelle('RULES-LAB_625', 'Sex');
  FGrilles[2].Cells[2, 0] := GetTexteLibelle('RULES-LAB_622', 'Name');
  FGrilles[2].Cells[3, 0] := GetTexteLibelle('RULES-LAB_623', 'Range');
  for I := 0 to 2 do
  begin
    FBoutons[I, 0] := Copie(GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 200,
      YTitre[I] + 22 + HautGrille[I] + 6, I);
    FBoutons[I, 1] := Copie(GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 208, 230,
      YTitre[I] + 22 + HautGrille[I] + 6, I);
  end;
  FBoutons[2, 2] := Copie(GetTexteLibelle('RULES-LAB_626', 'Move up'), @BoutonMonterClick, 446, 150,
    YTitre[2] + 22 + HautGrille[2] + 6, 2);
  FBoutons[2, 3] := Copie(GetTexteLibelle('RULES-LAB_627', 'Move down'), @BoutonDescendreClick, 604, 170,
    YTitre[2] + 22 + HautGrille[2] + 6, 2);
  MiseAJourUnContenaire(Self);
end;

function TPanelNoms.LibSexe(const Code: String): String;
begin
  if Code = 'M' then
    Result := FLibM
  else if Code = 'F' then
    Result := FLibF
  else
    Result := FLibTous;
end;

function TPanelNoms.CodeSexe(const Lib: String): String;
begin
  if Lib = FLibM then
    Result := 'M'
  else if Lib = FLibF then
    Result := 'F'
  else
    Result := '';
end;

// Parties presentes dans la table des noms (sans doublon, ordre de premiere apparition).
function TPanelNoms.Parties: TStringList;
var
  R: Integer;
  P: String;
begin
  Result := TStringList.Create;
  for R := 1 to FGrilles[2].RowCount - 1 do
  begin
    P := Trim(FGrilles[2].Cells[0, R]);
    if (P <> '') and (Result.IndexOf(P) < 0) then Result.Add(P);
  end;
end;

// Codes des regles declarees (grille des regles).
function TPanelNoms.Regles: TStringList;
var
  R: Integer;
  C: String;
begin
  Result := TStringList.Create;
  for R := 1 to FGrilles[1].RowCount - 1 do
  begin
    C := Trim(FGrilles[1].Cells[0, R]);
    if (C <> '') and (Result.IndexOf(C) < 0) then Result.Add(C);
  end;
end;

// Plage de chaque nom : a la suite des precedents de sa table, sur la largeur de son poids. Une partie qui melange
// des noms sans sexe et des noms M/F n'a qu'un de, partage (Suffix des Nains) ; sinon une table par sexe.
// Deux passes sur les lignes, listes de quelques elements : le libelle de sexe est traduit une seule fois par ligne.
procedure TPanelNoms.RecalculerPlages;
var
  R, Poids, Debut, I, P, N: Integer;
  Partie, Cle: String;
  Sexes: array of String;
  LesParties, Cles: TStringList;
  SansSexe, AvecSexe: array of Boolean;
  Compte, PrecPoids, PrecDebut: array of Integer;
  PrecSexe: array of String;
  PrecAppairee: array of Boolean;
begin
  N := FGrilles[2].RowCount;
  SetLength(Sexes, N);
  SetLength(Compte, N + 1);
  SetLength(PrecPoids, N + 1);
  SetLength(PrecDebut, N + 1);
  SetLength(PrecSexe, N + 1);
  SetLength(PrecAppairee, N + 1);
  SetLength(SansSexe, N + 1);
  SetLength(AvecSexe, N + 1);
  LesParties := TStringList.Create;
  Cles := TStringList.Create;
  try
    for R := 1 to N - 1 do
    begin
      Partie := Trim(FGrilles[2].Cells[0, R]);
      Sexes[R] := CodeSexe(FGrilles[2].Cells[1, R]);
      P := LesParties.IndexOf(Partie);
      if P < 0 then
      begin
        P := LesParties.Add(Partie);
        SansSexe[P] := False;
        AvecSexe[P] := False;
      end;
      if Sexes[R] = '' then SansSexe[P] := True else AvecSexe[P] := True;
    end;
    for R := 1 to N - 1 do
    begin
      Partie := Trim(FGrilles[2].Cells[0, R]);
      P := LesParties.IndexOf(Partie);
      if SansSexe[P] and AvecSexe[P] then Cle := Partie else Cle := Partie + #1 + Sexes[R];
      I := Cles.IndexOf(Cle);
      if I < 0 then
      begin
        I := Cles.Add(Cle);
        Compte[I] := 0;
      end;
      Poids := StrToIntDef(FGrilles[2].Cells[4, R], 1);
      if Poids < 1 then Poids := 1;
      // partie melangee : un nom M suivi d'un nom F de meme poids se partagent la meme plage (i / a des Nains)
      if (Cle = Partie) and (Sexes[R] <> '') and (PrecSexe[I] <> '') and (PrecSexe[I] <> Sexes[R]) and
        not PrecAppairee[I] and (PrecPoids[I] = Poids) then
      begin
        Debut := PrecDebut[I];
        PrecAppairee[I] := True;
      end
      else
      begin
        Debut := Compte[I] + 1;
        Compte[I] := Compte[I] + Poids;
        PrecAppairee[I] := False;
      end;
      PrecSexe[I] := Sexes[R];
      PrecPoids[I] := Poids;
      PrecDebut[I] := Debut;
      if Poids = 1 then
        FGrilles[2].Cells[3, R] := IntToStr(Debut)
      else
        FGrilles[2].Cells[3, R] := IntToStr(Debut) + '-' + IntToStr(Debut + Poids - 1);
    end;
  finally
    LesParties.Free;
    Cles.Free;
  end;
end;

procedure TPanelNoms.Charger(Element: TDOMElement);
type
  TNom = record
    Partie, Sexe, Nom: String;
    Debut, Fin: Integer;
  end;
var
  N, B: TDOMNode;
  I, J, K, R, P: Integer;
  Noms: array of TNom;
  Nb: Integer;
  Plage: String;
  Bloc: TDOMNode;
  OrdreParties, DejaPlace: TStringList;
  Tmp: TNom;
  Cle: String;
  Partagee, SansSexe, AvecSexe: Boolean;
  Groupes: TStringList;
begin
  for I := 0 to 2 do
  begin
    FGrilles[I].EditorMode := False;
    FGrilles[I].RowCount := 1;
    FGrilles[I].BeginUpdate;  // pas de redessin ligne par ligne : plusieurs centaines de noms
  end;
  Nb := 0;
  SetLength(Noms, 0);
  Bloc := nil;
  N := Element.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'SUBCHAPTER_NAMES') then Bloc := N;
    N := N.NextSibling;
  end;
  if Bloc = nil then
  begin
    for I := 0 to 2 do FGrilles[I].EndUpdate;
    Exit;
  end;
  B := Bloc.FirstChild;
  while B <> nil do
  begin
    if B.NodeType = ELEMENT_NODE then
    begin
      if B.NodeName = 'NamePattern' then
      begin
        R := FGrilles[0].RowCount;
        FGrilles[0].RowCount := R + 1;
        FGrilles[0].Cells[0, R] := LibSexe(TDOMElement(B).GetAttribute('sex'));
        FGrilles[0].Cells[1, R] := ValeurXML(B);
        FGrilles[0].Cells[2, R] := TDOMElement(B).GetAttribute('rule');
      end
      else if B.NodeName = 'NameRule' then
      begin
        R := FGrilles[1].RowCount;
        FGrilles[1].RowCount := R + 1;
        FGrilles[1].Cells[0, R] := TDOMElement(B).GetAttribute('code');
        FGrilles[1].Cells[1, R] := ValeurXML(B);
      end
      else if B.NodeName = 'Name' then
      begin
        SetLength(Noms, Nb + 1);
        Noms[Nb].Partie := TDOMElement(B).GetAttribute('part');
        Noms[Nb].Sexe := TDOMElement(B).GetAttribute('sex');
        Noms[Nb].Nom := TDOMElement(B).GetAttribute('name');
        Plage := ValeurXML(B);
        P := Pos('-', Plage);
        if P > 0 then
        begin
          Noms[Nb].Debut := StrToIntDef(Copy(Plage, 1, P - 1), 1);
          Noms[Nb].Fin := StrToIntDef(Copy(Plage, P + 1, MaxInt), Noms[Nb].Debut);
        end
        else
        begin
          Noms[Nb].Debut := StrToIntDef(Plage, 1);
          Noms[Nb].Fin := Noms[Nb].Debut;
        end;
        Inc(Nb);
      end;
    end;
    B := B.NextSibling;
  end;
  // ordre des tables : parties dans leur ordre d'apparition ; dans une table, l'ordre du de (tri stable)
  OrdreParties := TStringList.Create;
  DejaPlace := TStringList.Create;
  Groupes := TStringList.Create;
  try
    for I := 0 to Nb - 1 do
      if OrdreParties.IndexOf(Noms[I].Partie) < 0 then OrdreParties.Add(Noms[I].Partie);
    for I := 0 to OrdreParties.Count - 1 do
    begin
      SansSexe := False;
      AvecSexe := False;
      for J := 0 to Nb - 1 do
        if Noms[J].Partie = OrdreParties[I] then
          if Noms[J].Sexe = '' then SansSexe := True else AvecSexe := True;
      Partagee := SansSexe and AvecSexe;
      Groupes.Clear;
      for J := 0 to Nb - 1 do
        if Noms[J].Partie = OrdreParties[I] then
        begin
          if Partagee then Cle := '' else Cle := Noms[J].Sexe;
          if Groupes.IndexOf(Cle) < 0 then Groupes.Add(Cle);
        end;
      for K := 0 to Groupes.Count - 1 do
      begin
        // les noms de ce groupe, tries par debut de plage (tri a bulles stable, listes de quelques centaines)
        SetLength(Noms, Nb);  // garde la taille
        DejaPlace.Clear;
        for J := 0 to Nb - 1 do
          if (Noms[J].Partie = OrdreParties[I]) and ((Partagee) or (Noms[J].Sexe = Groupes[K])) then
            DejaPlace.AddObject(IntToStr(J), TObject(PtrInt(Noms[J].Debut)));
        // tri par debut, stable : insertion
        for J := 1 to DejaPlace.Count - 1 do
        begin
          Cle := DejaPlace[J];
          P := PtrInt(DejaPlace.Objects[J]);
          R := J - 1;
          while (R >= 0) and (PtrInt(DejaPlace.Objects[R]) > P) do
          begin
            DejaPlace[R + 1] := DejaPlace[R];
            DejaPlace.Objects[R + 1] := DejaPlace.Objects[R];
            Dec(R);
          end;
          DejaPlace[R + 1] := Cle;
          DejaPlace.Objects[R + 1] := TObject(PtrInt(P));
        end;
        for J := 0 to DejaPlace.Count - 1 do
        begin
          Tmp := Noms[StrToInt(DejaPlace[J])];
          R := FGrilles[2].RowCount;
          FGrilles[2].RowCount := R + 1;
          FGrilles[2].Cells[0, R] := Tmp.Partie;
          FGrilles[2].Cells[1, R] := LibSexe(Tmp.Sexe);
          FGrilles[2].Cells[2, R] := Tmp.Nom;
          if Tmp.Fin >= Tmp.Debut then
            FGrilles[2].Cells[4, R] := IntToStr(Tmp.Fin - Tmp.Debut + 1)
          else
            FGrilles[2].Cells[4, R] := '1';
        end;
      end;
    end;
  finally
    OrdreParties.Free;
    DejaPlace.Free;
    Groupes.Free;
  end;
  RecalculerPlages;
  for I := 0 to 2 do FGrilles[I].EndUpdate;
end;

// Parties citees par un modele : mots commencant par une majuscule, hors texte entre apostrophes et hors ":M" / ":F".
procedure PartiesDuModele(const Modele: String; Liste: TStringList);
var
  I: Integer;
  Dedans: Boolean;
  Mot: String;
  ApresDeuxPoints: Boolean;

  procedure FinMot;
  begin
    if (Mot <> '') and (not ApresDeuxPoints) and (Mot[1] in ['A'..'Z']) and (Liste.IndexOf(Mot) < 0) then
      Liste.Add(Mot);
    Mot := '';
  end;

begin
  Dedans := False;
  Mot := '';
  ApresDeuxPoints := False;
  for I := 1 to Length(Modele) do
  begin
    if Modele[I] = '''' then
    begin
      FinMot;
      Dedans := not Dedans;
      Continue;
    end;
    if Dedans then Continue;
    if Modele[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_'] then
      Mot := Mot + Modele[I]
    else
    begin
      FinMot;
      ApresDeuxPoints := Modele[I] = ':';
    end;
  end;
  FinMot;
end;

function TPanelNoms.Controler: Boolean;
var
  R, K, J: Integer;
  PartiesPresentes, ReglesDeclarees, Cites: TStringList;
  Code, PartieAbsente: String;
  UnModeleComplet: Boolean;
begin
  Result := True;
  for K := 0 to 2 do FGrilles[K].EditorMode := False;
  PartiesPresentes := Parties;
  ReglesDeclarees := Regles;
  Cites := TStringList.Create;
  try
    for R := 1 to FGrilles[2].RowCount - 1 do
    begin
      if Trim(FGrilles[2].Cells[0, R]) = '' then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_628', 'Names, line %d: write the part.'), [R]));
        Exit(False);
      end;
      if Trim(FGrilles[2].Cells[2, R]) = '' then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_629', 'Names, line %d: write the name.'), [R]));
        Exit(False);
      end;
    end;
    for R := 1 to FGrilles[1].RowCount - 1 do
    begin
      Code := Trim(FGrilles[1].Cells[0, R]);
      if Code = '' then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_630', 'Rules, line %d: write the code.'), [R]));
        Exit(False);
      end;
      for J := 1 to R - 1 do
        if Trim(FGrilles[1].Cells[0, J]) = Code then
        begin
          ShowMessage(Format(GetTexteLibelle('RULES-LAB_631', 'Rules, lines %d and %d have the same code.'), [J, R]));
          Exit(False);
        end;
    end;
    for R := 1 to FGrilles[0].RowCount - 1 do
    begin
      if Trim(FGrilles[0].Cells[1, R]) = '' then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_632', 'Patterns, line %d: write the pattern.'), [R]));
        Exit(False);
      end;
      Code := Trim(FGrilles[0].Cells[2, R]);
      if (Code <> '') and (ReglesDeclarees.IndexOf(Code) < 0) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_633', 'Patterns, line %d: the rule "%s" is not declared.'), [R, Code]));
        Exit(False);
      end;
      Cites.Clear;
      PartiesDuModele(FGrilles[0].Cells[1, R], Cites);
      // une partie sans nom ici peut venir d'un autre livre (prenoms des nains, noms de famille de
      // l'Empire) : refus seulement si AUCUNE partie du modele n'a de nom dans les tables de l'ethnie
      PartieAbsente := '';
      UnModeleComplet := False;
      for J := 0 to Cites.Count - 1 do
        if PartiesPresentes.IndexOf(Cites[J]) >= 0 then
          UnModeleComplet := True
        else if PartieAbsente = '' then
          PartieAbsente := Cites[J];
      if (Cites.Count > 0) and not UnModeleComplet then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_634',
          'Patterns, line %d: the part "%s" has no name in the tables.'), [R, PartieAbsente]));
        Exit(False);
      end;
    end;
  finally
    PartiesPresentes.Free;
    ReglesDeclarees.Free;
    Cites.Free;
  end;
end;

// Le bloc est reecrit en entier : modeles, regles, puis noms (ordre de la grille, plage recalculee). Les commentaires
// de l'ancien bloc sont gardes en tete du nouveau ; rien a ecrire = pas de bloc.
procedure TPanelNoms.Ecrire(Element: TDOMElement);
var
  N, Suivant, Ancien: TDOMNode;
  Bloc, E: TDOMElement;
  Doc: TDOMDocument;
  Commentaires: TList;
  R, K: Integer;
  Plage: String;

  procedure Pose(const Balise, Valeur: String; const Attrs: array of String);
  var
    I: Integer;
  begin
    E := Doc.CreateElement(Balise);
    I := 0;
    while I < High(Attrs) do
    begin
      if Attrs[I + 1] <> '' then E.SetAttribute(Attrs[I], Attrs[I + 1]);
      Inc(I, 2);
    end;
    Bloc.AppendChild(Doc.CreateTextNode(#10));
    Bloc.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  for K := 0 to 2 do FGrilles[K].EditorMode := False;
  Doc := Element.OwnerDocument;
  RecalculerPlages;
  Commentaires := TList.Create;
  try
    Ancien := nil;
    N := Element.FirstChild;
    while N <> nil do
    begin
      Suivant := N.NextSibling;
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'SUBCHAPTER_NAMES') then
      begin
        Ancien := N;
        Break;
      end;
      N := Suivant;
    end;
    if Ancien <> nil then
    begin
      N := Ancien.FirstChild;
      while N <> nil do
      begin
        if N.NodeType = COMMENT_NODE then Commentaires.Add(N);
        N := N.NextSibling;
      end;
    end;
    Bloc := Doc.CreateElement('SUBCHAPTER_NAMES');
    for K := 0 to Commentaires.Count - 1 do
    begin
      Bloc.AppendChild(Doc.CreateTextNode(#10));
      Bloc.AppendChild(TDOMNode(Commentaires[K]).CloneNode(True));
    end;
    for R := 1 to FGrilles[0].RowCount - 1 do
      Pose('NamePattern', Trim(FGrilles[0].Cells[1, R]),
        ['sex', CodeSexe(FGrilles[0].Cells[0, R]), 'rule', Trim(FGrilles[0].Cells[2, R])]);
    for R := 1 to FGrilles[1].RowCount - 1 do
      Pose('NameRule', Trim(FGrilles[1].Cells[1, R]), ['code', Trim(FGrilles[1].Cells[0, R])]);
    for R := 1 to FGrilles[2].RowCount - 1 do
    begin
      Plage := FGrilles[2].Cells[3, R];
      Pose('Name', Plage, ['part', Trim(FGrilles[2].Cells[0, R]), 'sex', CodeSexe(FGrilles[2].Cells[1, R]),
        'name', Trim(FGrilles[2].Cells[2, R])]);
    end;
    Bloc.AppendChild(Doc.CreateTextNode(#10));
    if Ancien <> nil then Element.RemoveChild(Ancien);
    // rien d'autre que d'eventuels commentaires : pas de bloc
    if (FGrilles[0].RowCount > 1) or (FGrilles[1].RowCount > 1) or (FGrilles[2].RowCount > 1) then
    begin
      // le schema veut Page en derniere balise : le bloc se place avant elle
      Suivant := Element.FindNode('Page');
      if Suivant <> nil then
        Element.InsertBefore(Bloc, Suivant)
      else
        Element.AppendChild(Bloc);
    end
    else
      Bloc.Free;
  finally
    Commentaires.Free;
  end;
end;

function TPanelNoms.Signature(const Sep: String): String;
var
  I, R, C: Integer;
begin
  Result := '';
  for I := 0 to 2 do
    for R := 1 to FGrilles[I].RowCount - 1 do
      for C := 0 to FGrilles[I].ColCount - 1 do
        Result := Result + Sep + FGrilles[I].Cells[C, R];
end;

procedure TPanelNoms.MettreLectureSeule(Valeur: Boolean);
var
  I, J: Integer;
begin
  FLectureSeule := Valeur;
  for I := 0 to 2 do
  begin
    if Valeur then
      FGrilles[I].Options := FGrilles[I].Options - [goEditing]
    else
      FGrilles[I].Options := FGrilles[I].Options + [goEditing];
    for J := 0 to 3 do
      if FBoutons[I, J] <> nil then FBoutons[I, J].Visible := not Valeur;
  end;
end;

procedure TPanelNoms.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Liste: TStringList;
  Grille: TStringGrid;
  I: Integer;
  Combo: TCustomComboBox;
begin
  if (aRow < 1) or FLectureSeule then Exit;
  Grille := Sender as TStringGrid;
  Liste := TStringList.Create;
  try
    if (Grille = FGrilles[0]) and (aCol = 0) or (Grille = FGrilles[2]) and (aCol = 1) then
    begin
      Liste.Add(LibSexe(''));
      Liste.Add(LibSexe('M'));
      Liste.Add(LibSexe('F'));
    end
    else if (Grille = FGrilles[0]) and (aCol = 2) then
    begin
      Liste.Add('');
      for I := 1 to FGrilles[1].RowCount - 1 do
        if Trim(FGrilles[1].Cells[0, I]) <> '' then Liste.Add(Trim(FGrilles[1].Cells[0, I]));
    end
    else if (Grille = FGrilles[2]) and (aCol = 0) then
    begin
      for I := 0 to High(PartiesCourantes) do Liste.Add(PartiesCourantes[I]);
      for I := 1 to Grille.RowCount - 1 do
        if (Trim(Grille.Cells[0, I]) <> '') and (Liste.IndexOf(Trim(Grille.Cells[0, I])) < 0) then
          Liste.Add(Trim(Grille.Cells[0, I]));
    end
    else
      Exit;
    Editor := Grille.EditorByStyle(cbsPickList);
    if not (Editor is TCustomComboBox) then Exit;
    Combo := TCustomComboBox(Editor);
    // la partie se saisit aussi a la main (une partie propre a l'ethnie) ; les autres colonnes sont des choix fermes
    if (Grille = FGrilles[2]) and (aCol = 0) then
      Combo.Style := csDropDown
    else
      Combo.Style := csDropDownList;
    Combo.Items.Assign(Liste);
  finally
    Liste.Free;
  end;
end;

// Les colonnes calculees (plage, poids) ne se saisissent pas.
procedure TPanelNoms.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  Grille: TStringGrid;
begin
  if FLectureSeule then Exit;
  Grille := Sender as TStringGrid;
  if (Grille = FGrilles[2]) and (aCol >= 3) then
    Grille.Options := Grille.Options - [goEditing]
  else
    Grille.Options := Grille.Options + [goEditing];
end;

procedure TPanelNoms.GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
begin
  if (Sender = FGrilles[2]) and (aCol <= 1) then RecalculerPlages;
end;

procedure TPanelNoms.BoutonAjouterClick(Sender: TObject);
var
  I, R, PosIns: Integer;
  G: TStringGrid;
begin
  I := TBCButton(Sender).Tag;
  G := FGrilles[I];
  G.EditorMode := False;
  if I = 2 then
  begin
    // une ligne de plus sous la ligne choisie, de meme partie et de meme sexe
    PosIns := G.Row + 1;
    if PosIns < 1 then PosIns := G.RowCount;
    G.RowCount := G.RowCount + 1;
    G.MoveColRow(False, G.RowCount - 1, PosIns);
    R := PosIns;
    G.Cells[0, R] := '';
    G.Cells[1, R] := LibSexe('');
    G.Cells[2, R] := '';
    G.Cells[4, R] := '1';
    if R > 1 then
    begin
      G.Cells[0, R] := G.Cells[0, R - 1];
      G.Cells[1, R] := G.Cells[1, R - 1];
    end;
    G.Row := R;
    G.Col := 2;
    RecalculerPlages;
  end
  else
  begin
    R := G.RowCount;
    G.RowCount := R + 1;
    if I = 0 then G.Cells[0, R] := LibSexe('');
    G.Row := R;
    G.Col := 1;
  end;
end;

procedure TPanelNoms.BoutonRetirerClick(Sender: TObject);
var
  I: Integer;
begin
  I := TBCButton(Sender).Tag;
  FGrilles[I].EditorMode := False;
  if (FGrilles[I].Row >= 1) and (FGrilles[I].Row < FGrilles[I].RowCount) then
    FGrilles[I].DeleteRow(FGrilles[I].Row);
  if I = 2 then RecalculerPlages;
end;

procedure TPanelNoms.BoutonMonterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrilles[2].EditorMode := False;
  R := FGrilles[2].Row;
  if R > 1 then
  begin
    FGrilles[2].ExchangeColRow(False, R, R - 1);
    FGrilles[2].Row := R - 1;
    RecalculerPlages;
  end;
end;

procedure TPanelNoms.BoutonDescendreClick(Sender: TObject);
var
  R: Integer;
begin
  FGrilles[2].EditorMode := False;
  R := FGrilles[2].Row;
  if (R >= 1) and (R < FGrilles[2].RowCount - 1) then
  begin
    FGrilles[2].ExchangeColRow(False, R, R + 1);
    FGrilles[2].Row := R + 1;
    RecalculerPlages;
  end;
end;

end.

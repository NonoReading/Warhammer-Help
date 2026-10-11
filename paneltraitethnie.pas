unit PanelTraitEthnie;

{$mode ObjFPC}{$H+}

// Table editable des traits d'ethnie (DATA_SPECIE_TRAIT, CONTEXT.md 2.41 et 2.107) : une ligne par option d'un trait
// ("Provincial Trait" > "Northern Kislev"), avec jusqu'a trois groupes de talents. Un groupe est un talent, un choix
// entre deux talents (A/B) ou un talent aleatoire (RULES-T*). Le XML garde les codes ; la grille montre les libelles.
//
// Colonnes : 0 trait, 1 option, 2/3 groupe 1 (talent, ou), 4/5 groupe 2, 6/7 groupe 3, 8 identifiant de l'option (cache).
// Usage : creer, Initialiser, poser (Parent + SetBounds), Configurer puis Charger(Chapitre) a l'ouverture,
// Controler puis Ecrire(Chapitre) a la validation. Chapitre = l'element DATA_SPECIE_TRAIT du livre.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, Graphics, DOM, BCButton,
  ChargeConstantes, ChargeTexte, GlobalFonts, PanelModificateurs;

type
  TPanelTraitEthnie = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre, FBarre2: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonTrait, FBoutonRetirerTrait, FBoutonRenommerTrait, FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FTraitsLib, FTraitsCode, FTalLib, FTalCode, FTraitsInitiaux: TStringList;
    FPrefixe, FLangue: String;
    function  Sanitaire(const S: String; Longueur: Integer): String;
    function  LibTalent(const Code: String): String;
    function  CodeTalent(const Lib: String): String;
    function  LibTrait(const Code, Defaut: String): String;
    function  CodeTraitDe(const Lib: String): String;
    procedure PoserTalents(R: Integer; const Valeur: String);
    function  ComposerTalents(R: Integer): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonTraitClick(Sender: TObject);
    procedure BoutonRetirerTraitClick(Sender: TObject);
    procedure BoutonRenommerTraitClick(Sender: TObject);
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
    // A appeler avant chaque Charger. Talents = "code=libelle|..." (les talents proposes), Prefixe = code du livre ouvert
    // (pour le code d'un nouveau trait), Langue = langue des libelles ecrits.
    procedure Configurer(const Talents, Prefixe, Langue: String);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque ligne a un trait, une option et un premier talent ; sinon message.
    function  Controler: Boolean;
    // Traits presents au chargement et qui n'ont plus aucune ligne : "code=libelle" (a verifier avant d'ecrire).
    procedure TraitsRetires(Liste: TStrings);
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

implementation

const
  CodeAleatoire = 'RULES-T*';

constructor TPanelTraitEthnie.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTraitsLib := TStringList.Create;
  FTraitsCode := TStringList.Create;
  FTalLib := TStringList.Create;
  FTalCode := TStringList.Create;
  FTraitsInitiaux := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FBarre2 := TPanel.Create(Self);
  FBarre2.Parent := Self;
  FBarre2.Align := alTop;
  FBarre2.BevelOuter := bvNone;
  FBarre2.Caption := '';
  FBarre2.Height := 50;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 9;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  Visible := False;
end;

destructor TPanelTraitEthnie.Destroy;
begin
  FTraitsLib.Free;
  FTraitsCode.Free;
  FTalLib.Free;
  FTalCode.Free;
  FTraitsInitiaux.Free;
  inherited Destroy;
end;

function TPanelTraitEthnie.Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
  Gauche, Largeur: Integer): TBCButton;
begin
  Result := TBCButtonContour.Create(Self);
  Result.Assign(Modele);
  Result.Parent := Barre;
  Result.Caption := Legende;
  Result.OnClick := Clic;
  Result.SetBounds(Gauche, 0, Largeur, 50);
end;

procedure TPanelTraitEthnie.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230);
  FBoutonRetirer := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250);
  FBoutonValider := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_086'), @BoutonValiderClick, 500, 150);
  FBoutonAnnuler := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_166'), @BoutonAnnulerClick, 660, 150);
  FBoutonTrait := Copie(Modele, FBarre2, GetTexteLibelle('RULES-LAB_545', 'New trait'), @BoutonTraitClick, 0, 230);
  FBoutonRetirerTrait := Copie(Modele, FBarre2, GetTexteLibelle('RULES-LAB_546', 'Remove the trait'), @BoutonRetirerTraitClick, 240, 250);
  FBoutonRenommerTrait := Copie(Modele, FBarre2, GetTexteLibelle('RULES-LAB_579', 'Rename the trait'), @BoutonRenommerTraitClick, 500, 230);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

// Lettres et chiffres en majuscules, pour fabriquer un code a partir d'un nom.
function TPanelTraitEthnie.Sanitaire(const S: String; Longueur: Integer): String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    if (UpCase(S[I]) in ['A'..'Z', '0'..'9']) and (Length(Result) < Longueur) then
      Result := Result + UpCase(S[I]);
  if Result = '' then Result := 'X';
end;

function TPanelTraitEthnie.LibTalent(const Code: String): String;
var
  I: Integer;
begin
  if Trim(Code) = '' then Exit('');
  I := FTalCode.IndexOf(Trim(Code));
  if I >= 0 then
    Result := FTalLib[I]
  else
  begin
    // un code que la liste ne propose pas (talent d'un autre livre) reste visible et reste choisissable
    Result := Trim(Code);
    FTalCode.Add(Result);
    FTalLib.Add(Result);
  end;
end;

// Libelle choisi dans la liste ; un texte inconnu est pris pour un code.
function TPanelTraitEthnie.CodeTalent(const Lib: String): String;
var
  I: Integer;
begin
  Result := Trim(Lib);
  if Result = '' then Exit;
  I := FTalLib.IndexOf(Result);
  if I >= 0 then Result := FTalCode[I];
end;

function TPanelTraitEthnie.LibTrait(const Code, Defaut: String): String;
var
  I: Integer;
begin
  I := FTraitsCode.IndexOf(Code);
  if I >= 0 then Exit(FTraitsLib[I]);
  Result := Defaut;
  if Result = '' then Result := Code;
  if FTraitsLib.IndexOf(Result) >= 0 then Result := Result + ' [' + Code + ']';
  FTraitsCode.Add(Code);
  FTraitsLib.Add(Result);
end;

function TPanelTraitEthnie.CodeTraitDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FTraitsLib.IndexOf(Lib);
  if I >= 0 then Result := FTraitsCode[I];
end;

procedure TPanelTraitEthnie.Configurer(const Talents, Prefixe, Langue: String);
var
  Choix: TStringList;
  I, P: Integer;
begin
  FPrefixe := Prefixe;
  FLangue := Langue;
  FTalLib.Clear;
  FTalCode.Clear;
  FTraitsLib.Clear;
  FTraitsCode.Clear;
  Choix := TStringList.Create;
  try
    Choix.Delimiter := '|';
    Choix.StrictDelimiter := True;
    Choix.DelimitedText := Talents;
    FTalCode.Add(CodeAleatoire);
    FTalLib.Add(GetTexteLibelle('RULES-LAB_541', 'Random talent'));
    for I := 0 to Choix.Count - 1 do
    begin
      P := Pos('=', Choix[I]);
      if (P > 1) and (FTalCode.IndexOf(Copy(Choix[I], 1, P - 1)) < 0) then
      begin
        FTalCode.Add(Copy(Choix[I], 1, P - 1));
        FTalLib.Add(Copy(Choix[I], P + 1, MaxInt));
      end;
    end;
  finally
    Choix.Free;
  end;
  FGrille.ColWidths[0] := 170;
  FGrille.ColWidths[1] := 220;
  for I := 2 to 7 do
    FGrille.ColWidths[I] := 165;
  FGrille.ColWidths[8] := 0;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_542', 'Trait');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_543', 'Option');
  for I := 0 to 2 do
  begin
    FGrille.Cells[2 + 2 * I, 0] := GetTexteLibelle('RULES-LAB_007', 'Talent') + ' ' + IntToStr(I + 1);
    FGrille.Cells[3 + 2 * I, 0] := GetTexteLibelle('RULES-LAB_544', 'or');
  end;
end;

// Valeur du <Talent> d'une option : groupes separes par une virgule, un groupe = un talent ou "A/B".
procedure TPanelTraitEthnie.PoserTalents(R: Integer; const Valeur: String);
var
  Groupes, Alt: TStringList;
  G, J: Integer;
  Reste: String;
begin
  Groupes := TStringList.Create;
  Alt := TStringList.Create;
  try
    Groupes.Delimiter := ',';
    Groupes.StrictDelimiter := True;
    Groupes.DelimitedText := Valeur;
    Alt.Delimiter := '/';
    Alt.StrictDelimiter := True;
    for G := 0 to 2 do
    begin
      if G >= Groupes.Count then Break;
      Alt.DelimitedText := Trim(Groupes[G]);
      if Alt.Count = 0 then Continue;
      FGrille.Cells[2 + 2 * G, R] := LibTalent(Alt[0]);
      Reste := '';
      for J := 1 to Alt.Count - 1 do
      begin
        if Reste <> '' then Reste := Reste + '/';
        Reste := Reste + Trim(Alt[J]);
      end;
      FGrille.Cells[3 + 2 * G, R] := LibTalent(Reste);
    end;
  finally
    Alt.Free;
    Groupes.Free;
  end;
end;

function TPanelTraitEthnie.ComposerTalents(R: Integer): String;
var
  G: Integer;
  A, B: String;
begin
  Result := '';
  for G := 0 to 2 do
  begin
    A := CodeTalent(FGrille.Cells[2 + 2 * G, R]);
    B := CodeTalent(FGrille.Cells[3 + 2 * G, R]);
    if A = '' then Continue;
    if B <> '' then A := A + '/' + B;
    if Result <> '' then Result := Result + ',';
    Result := Result + A;
  end;
end;

procedure TPanelTraitEthnie.Charger(Chapitre: TDOMElement);
var
  Tr, Op: TDOMNode;
  CodeTrait, LibelleTrait: String;
  R: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  FTraitsInitiaux.Clear;
  if Chapitre = nil then Exit;
  Tr := Chapitre.FirstChild;
  while Tr <> nil do
  begin
    if (Tr.NodeType = ELEMENT_NODE) and (Tr.NodeName = 'SpecieTrait') then
    begin
      CodeTrait := TDOMElement(Tr).GetAttribute('id');
      LibelleTrait := LibTrait(CodeTrait, ValeurXML(Tr.FindNode('Description')));
      FTraitsInitiaux.Add(CodeTrait + '=' + LibelleTrait);
      Op := Tr.FirstChild;
      while Op <> nil do
      begin
        if (Op.NodeType = ELEMENT_NODE) and (Op.NodeName = 'Option') then
        begin
          R := FGrille.RowCount;
          FGrille.RowCount := R + 1;
          FGrille.Cells[0, R] := LibelleTrait;
          FGrille.Cells[1, R] := ValeurXML(Op.FindNode('Description'));
          FGrille.Cells[8, R] := TDOMElement(Op).GetAttribute('id');
          PoserTalents(R, ValeurXML(Op.FindNode('Talent')));
        end;
        Op := Op.NextSibling;
      end;
    end;
    Tr := Tr.NextSibling;
  end;
end;

// Les <SpecieTrait> sont reecrits ; les commentaires du bloc restent. Un trait sans ligne n'est pas ecrit.
procedure TPanelTraitEthnie.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  Traits, Utilises: TStringList;
  N, Suivant: TDOMNode;
  ElTrait, ElOption, E: TDOMElement;
  I, R: Integer;
  Code, IdOption, Base: String;
  Suffixe: Integer;

  procedure Balise(Parent: TDOMElement; const Nom, Valeur: String; Multilingue: Boolean);
  begin
    E := Doc.CreateElement(Nom);
    if Multilingue then E.SetAttribute('language', FLangue);
    Parent.AppendChild(Doc.CreateTextNode(#10));
    Parent.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  FGrille.EditorMode := False;
  Doc := Chapitre.OwnerDocument;
  N := Chapitre.FirstChild;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'SpecieTrait') then
      Chapitre.RemoveChild(N);
    N := Suivant;
  end;
  Traits := TStringList.Create;
  Utilises := TStringList.Create;
  try
    for R := 1 to FGrille.RowCount - 1 do
    begin
      Code := CodeTraitDe(FGrille.Cells[0, R]);
      if Traits.IndexOf(Code) < 0 then Traits.Add(Code);
    end;
    for I := 0 to Traits.Count - 1 do
    begin
      ElTrait := Doc.CreateElement('SpecieTrait');
      ElTrait.SetAttribute('id', Traits[I]);
      Balise(ElTrait, 'Description', LibTrait(Traits[I], ''), True);
      for R := 1 to FGrille.RowCount - 1 do
        if CodeTraitDe(FGrille.Cells[0, R]) = Traits[I] then
        begin
          IdOption := Trim(FGrille.Cells[8, R]);
          if (IdOption = '') or (Utilises.IndexOf(IdOption) >= 0) then
          begin
            Base := Traits[I] + '_' + Sanitaire(FGrille.Cells[1, R], 14);
            IdOption := Base;
            Suffixe := 1;
            while Utilises.IndexOf(IdOption) >= 0 do
            begin
              Inc(Suffixe);
              IdOption := Base + IntToStr(Suffixe);
            end;
          end;
          Utilises.Add(IdOption);
          ElOption := Doc.CreateElement('Option');
          ElOption.SetAttribute('id', IdOption);
          Balise(ElOption, 'Description', Trim(FGrille.Cells[1, R]), True);
          Balise(ElOption, 'Talent', ComposerTalents(R), False);
          ElOption.AppendChild(Doc.CreateTextNode(#10));
          ElTrait.AppendChild(Doc.CreateTextNode(#10));
          ElTrait.AppendChild(ElOption);
        end;
      ElTrait.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(ElTrait);
    end;
    Chapitre.AppendChild(Doc.CreateTextNode(#10));
  finally
    Utilises.Free;
    Traits.Free;
  end;
end;

function TPanelTraitEthnie.Controler: Boolean;
var
  R, G: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if CodeTraitDe(FGrille.Cells[0, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_547', 'Line %d: choose a trait.'), [R]));
      Exit(False);
    end;
    if Trim(FGrille.Cells[1, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_548', 'Line %d: enter the option name.'), [R]));
      Exit(False);
    end;
    if Trim(FGrille.Cells[2, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_549', 'Line %d: choose the first talent.'), [R]));
      Exit(False);
    end;
    for G := 0 to 2 do
      if (Trim(FGrille.Cells[2 + 2 * G, R]) = '') and (Trim(FGrille.Cells[3 + 2 * G, R]) <> '') then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_550', 'Line %d: an alternative needs its talent.'), [R]));
        Exit(False);
      end;
  end;
end;

procedure TPanelTraitEthnie.TraitsRetires(Liste: TStrings);
var
  I: Integer;
  Code: String;
  Present: Boolean;
  R: Integer;
begin
  for I := 0 to FTraitsInitiaux.Count - 1 do
  begin
    Code := FTraitsInitiaux.Names[I];
    Present := False;
    for R := 1 to FGrille.RowCount - 1 do
      if CodeTraitDe(FGrille.Cells[0, R]) = Code then Present := True;
    if not Present then Liste.Add(FTraitsInitiaux[I]);
  end;
end;

procedure TPanelTraitEthnie.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Items: TStringList;
begin
  if (aRow < 1) or (aCol = 1) or (aCol > 7) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  if aCol = 0 then
    TCustomComboBox(Editor).Items.Assign(FTraitsLib)
  else
  begin
    Items := TStringList.Create;
    try
      Items.Add('');  // case vide : pas de groupe ou pas d'alternative
      Items.AddStrings(FTalLib);
      TCustomComboBox(Editor).Items.Assign(Items);
    finally
      Items.Free;
    end;
  end;
end;

procedure TPanelTraitEthnie.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  // une nouvelle ligne reprend le trait de la precedente : on ajoute le plus souvent une option au meme trait
  if R > 1 then FGrille.Cells[0, R] := FGrille.Cells[0, R - 1]
  else if FTraitsLib.Count > 0 then FGrille.Cells[0, R] := FTraitsLib[0];
  FGrille.Row := R;
  FGrille.Col := 1;
end;

procedure TPanelTraitEthnie.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
end;

// Nouveau trait : son nom suffit ; une premiere ligne vide l'attend. Un nom deja pris reprend le trait existant.
procedure TPanelTraitEthnie.BoutonTraitClick(Sender: TObject);
var
  Nom, Code, Base: String;
  R, N: Integer;
begin
  FGrille.EditorMode := False;
  Nom := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_545', 'New trait'), GetTexteLibelle('RULES-LAB_403'), Nom) then Exit;
  Nom := Trim(Nom);
  if Nom = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;
  Code := CodeTraitDe(Nom);
  if Code = '' then
  begin
    Base := FPrefixe + '-TRAIT_' + Sanitaire(Nom, 12);
    Code := Base;
    N := 1;
    while FTraitsCode.IndexOf(Code) >= 0 do
    begin
      Inc(N);
      Code := Base + IntToStr(N);
    end;
    LibTrait(Code, Nom);
  end;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Cells[0, R] := LibTrait(Code, Nom);
  FGrille.Row := R;
  FGrille.Col := 1;
end;

// Retire toutes les lignes du trait de la ligne courante (Annuler les rend).
procedure TPanelTraitEthnie.BoutonRetirerTraitClick(Sender: TObject);
var
  Code: String;
  R: Integer;
begin
  FGrille.EditorMode := False;
  if (FGrille.Row < 1) or (FGrille.Row >= FGrille.RowCount) then Exit;
  Code := CodeTraitDe(FGrille.Cells[0, FGrille.Row]);
  if Code = '' then Exit;
  for R := FGrille.RowCount - 1 downto 1 do
    if CodeTraitDe(FGrille.Cells[0, R]) = Code then FGrille.DeleteRow(R);
end;

// Change le libelle du trait de la ligne courante ; le code, lui, ne bouge pas (les references restent valables).
procedure TPanelTraitEthnie.BoutonRenommerTraitClick(Sender: TObject);
var
  Ancien, Nom, Code: String;
  I, R: Integer;
begin
  FGrille.EditorMode := False;
  if (FGrille.Row < 1) or (FGrille.Row >= FGrille.RowCount) then Exit;
  Ancien := FGrille.Cells[0, FGrille.Row];
  Code := CodeTraitDe(Ancien);
  if Code = '' then Exit;
  Nom := Ancien;
  if not InputQuery(GetTexteLibelle('RULES-LAB_579', 'Rename the trait'), GetTexteLibelle('RULES-LAB_403'), Nom) then Exit;
  Nom := Trim(Nom);
  if Nom = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;
  if Nom = Ancien then Exit;
  if FTraitsLib.IndexOf(Nom) >= 0 then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_580', 'Another trait already has this name.'));
    Exit;
  end;
  I := FTraitsCode.IndexOf(Code);
  FTraitsLib[I] := Nom;
  for R := 1 to FGrille.RowCount - 1 do
    if FGrille.Cells[0, R] = Ancien then FGrille.Cells[0, R] := Nom;
end;

procedure TPanelTraitEthnie.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelTraitEthnie.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelTraitEthnie.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelTraitEthnie.GetLectureSeule: Boolean;
begin
  Result := not FBarre.Visible;
end;

procedure TPanelTraitEthnie.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
  FBarre2.Visible := not Valeur;
end;

procedure TPanelTraitEthnie.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelTraitEthnie.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

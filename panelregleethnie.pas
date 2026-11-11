unit PanelRegleEthnie;

{$mode ObjFPC}{$H+}

// Table editable des competences et talents qu'une regle donne a une ethnie en remplacement des siens
// (DATA_RULE_SPECIE) : une ligne par entree, avec la regle, l'ethnie (ou la race), le genre (competence ou
// talent) et la competence ou le talent donne. Le XML garde les codes ; la grille montre les libelles.
//
// Chaque entree s'ecrit <Entry><Rule>"code"</Rule><Specie>"code"</Specie><Skill>"code"</Skill></Entry>
// (<Talent> pour un talent). Une entree deja presente et conservee n'est pas reecrite : les commentaires du bloc
// restent en place.
// Usage : creer, Initialiser, poser (Parent + SetBounds), Configurer puis Charger(Chapitre) a l'ouverture,
// Controler puis Ecrire(Chapitre) a la validation. Chapitre = l'element DATA_RULE_SPECIE du livre.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, Graphics, DOM, BCButton,
  ChargeConstantes, ChargeTexte, GlobalFonts, PanelModificateurs, PanelTirage;

type
  // Une liste de choix : libelles montres dans la grille, codes gardes dans le XML.
  TListeLibelles = class
  private
    FLib: TFonctionLibelleTirage;
    FLibelles, FCodes: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configurer(ALib: TFonctionLibelleTirage; Codes: TStrings);
    function  LibelleDe(const Code: String): String;
    function  CodeDe(const Lib: String): String;
    property  Libelles: TStringList read FLibelles;
  end;

  TPanelRegleEthnie = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FRegles, FEspeces, FCompetences, FTalents: TListeLibelles;
    FLibCompetence, FLibTalent: String;
    function  ListeElements(Ligne: Integer): TListeLibelles;
    function  CodeElementDe(Ligne: Integer): String;
    function  GenreDe(Ligne: Integer): String;
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
    // A appeler avant chaque Charger. Regles, Especes, Competences, Talents : codes que le choix d'une ligne propose.
    procedure Configurer(ALibRegle, ALibEspece, ALibCompetence, ALibTalent: TFonctionLibelleTirage;
      Regles, Especes, Competences, Talents: TStrings);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque ligne est complete, sans doublon ; sinon message.
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

implementation

constructor TListeLibelles.Create;
begin
  FLibelles := TStringList.Create;
  FCodes := TStringList.Create;
end;

destructor TListeLibelles.Destroy;
begin
  FLibelles.Free;
  FCodes.Free;
  inherited Destroy;
end;

procedure TListeLibelles.Configurer(ALib: TFonctionLibelleTirage; Codes: TStrings);
var
  I: Integer;
begin
  FLib := ALib;
  FLibelles.Clear;
  FCodes.Clear;
  for I := 0 to Codes.Count - 1 do
    LibelleDe(Codes[I]);
end;

// Libelle d'un code ; un code hors liste proposee y est ajoute, et un libelle deja pris porte son code.
function TListeLibelles.LibelleDe(const Code: String): String;
var
  I: Integer;
begin
  I := FCodes.IndexOf(Code);
  if I >= 0 then Exit(FLibelles[I]);
  Result := FLib(Code);
  if FLibelles.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FLibelles.Add(Result);
  FCodes.Add(Code);
end;

function TListeLibelles.CodeDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FLibelles.IndexOf(Lib);
  if I >= 0 then Result := FCodes[I];
end;

constructor TPanelRegleEthnie.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRegles := TListeLibelles.Create;
  FEspeces := TListeLibelles.Create;
  FCompetences := TListeLibelles.Create;
  FTalents := TListeLibelles.Create;
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

destructor TPanelRegleEthnie.Destroy;
begin
  FRegles.Free;
  FEspeces.Free;
  FCompetences.Free;
  FTalents.Free;
  inherited Destroy;
end;

function TPanelRegleEthnie.Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
  Gauche, Largeur: Integer): TBCButton;
begin
  Result := TBCButtonContour.Create(Self);
  Result.Assign(Modele);
  Result.Parent := Barre;
  Result.Caption := Legende;
  Result.OnClick := Clic;
  Result.SetBounds(Gauche, 0, Largeur, 50);
end;

procedure TPanelRegleEthnie.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230);
  FBoutonRetirer := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250);
  FBoutonValider := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_086'), @BoutonValiderClick, 500, 150);
  FBoutonAnnuler := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_166'), @BoutonAnnulerClick, 660, 150);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

// Le genre d'une ligne se lit sur son libelle (colonne 2) : 'S' competence, 'T' talent, '' si non choisi.
function TPanelRegleEthnie.GenreDe(Ligne: Integer): String;
begin
  Result := '';
  if FGrille.Cells[2, Ligne] = FLibCompetence then Result := 'S'
  else if FGrille.Cells[2, Ligne] = FLibTalent then Result := 'T';
end;

function TPanelRegleEthnie.ListeElements(Ligne: Integer): TListeLibelles;
begin
  Result := nil;
  if GenreDe(Ligne) = 'S' then Result := FCompetences
  else if GenreDe(Ligne) = 'T' then Result := FTalents;
end;

function TPanelRegleEthnie.CodeElementDe(Ligne: Integer): String;
var
  Liste: TListeLibelles;
begin
  Result := '';
  Liste := ListeElements(Ligne);
  if Liste <> nil then Result := Liste.CodeDe(FGrille.Cells[3, Ligne]);
end;

procedure TPanelRegleEthnie.Configurer(ALibRegle, ALibEspece, ALibCompetence, ALibTalent: TFonctionLibelleTirage;
  Regles, Especes, Competences, Talents: TStrings);
begin
  FRegles.Configurer(ALibRegle, Regles);
  FEspeces.Configurer(ALibEspece, Especes);
  FCompetences.Configurer(ALibCompetence, Competences);
  FTalents.Configurer(ALibTalent, Talents);
  FLibCompetence := GetTexteLibelle('RULES-LAB_009', 'Skill');
  FLibTalent := GetTexteLibelle('RULES-LAB_007', 'Talent');
  FGrille.ColWidths[0] := 300;
  FGrille.ColWidths[1] := 300;
  FGrille.ColWidths[2] := 130;
  FGrille.ColWidths[3] := 300;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_618', 'Rule');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_042', 'Specie');
  FGrille.Cells[2, 0] := '';
  FGrille.Cells[3, 0] := FLibCompetence + ' / ' + FLibTalent;
end;

procedure TPanelRegleEthnie.Charger(Chapitre: TDOMElement);
var
  N: TDOMNode;
  Regle, Espece, Code, Genre: String;
  R: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  if Chapitre = nil then Exit;
  N := Chapitre.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Entry') then
    begin
      Regle := ValeurXML(N.FindNode('Rule'));
      Espece := ValeurXML(N.FindNode('Specie'));
      Genre := '';
      Code := '';
      if N.FindNode('Skill') <> nil then
      begin
        Genre := 'S';
        Code := ValeurXML(N.FindNode('Skill'));
      end
      else if N.FindNode('Talent') <> nil then
      begin
        Genre := 'T';
        Code := ValeurXML(N.FindNode('Talent'));
      end;
      if (Regle <> '') and (Espece <> '') and (Code <> '') then
      begin
        R := FGrille.RowCount;
        FGrille.RowCount := R + 1;
        FGrille.Cells[0, R] := FRegles.LibelleDe(Regle);
        FGrille.Cells[1, R] := FEspeces.LibelleDe(Espece);
        if Genre = 'S' then
        begin
          FGrille.Cells[2, R] := FLibCompetence;
          FGrille.Cells[3, R] := FCompetences.LibelleDe(Code);
        end
        else
        begin
          FGrille.Cells[2, R] := FLibTalent;
          FGrille.Cells[3, R] := FTalents.LibelleDe(Code);
        end;
      end;
    end;
    N := N.NextSibling;
  end;
end;

// Les entrees conservees restent telles quelles (avec leurs commentaires) ; les entrees retirees quittent le bloc ;
// les entrees nouvelles sont ajoutees a la fin. Cle d'une entree : regle, ethnie, genre et code, separes par une tabulation.
procedure TPanelRegleEthnie.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  N, Suivant: TDOMNode;
  Entree, E: TDOMElement;
  Voulus, Presents: TStringList;
  R, K: Integer;
  Regle, Espece, Genre, Code, Cle: String;
  Morceaux: TStringArray;
begin
  FGrille.EditorMode := False;
  Doc := Chapitre.OwnerDocument;
  Voulus := TStringList.Create;
  Presents := TStringList.Create;
  try
    // Presents : les lignes voulues pas encore retrouvees dans le bloc (une par exemplaire)
    for R := 1 to FGrille.RowCount - 1 do
      Presents.Add(FRegles.CodeDe(FGrille.Cells[0, R]) + #9 + FEspeces.CodeDe(FGrille.Cells[1, R]) + #9 +
        GenreDe(R) + #9 + CodeElementDe(R));
    Voulus.Assign(Presents);
    N := Chapitre.FirstChild;
    while N <> nil do
    begin
      Suivant := N.NextSibling;
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Entry') then
      begin
        Regle := ValeurXML(N.FindNode('Rule'));
        Espece := ValeurXML(N.FindNode('Specie'));
        Genre := '';
        Code := '';
        if N.FindNode('Skill') <> nil then
        begin
          Genre := 'S';
          Code := ValeurXML(N.FindNode('Skill'));
        end
        else if N.FindNode('Talent') <> nil then
        begin
          Genre := 'T';
          Code := ValeurXML(N.FindNode('Talent'));
        end;
        Cle := Regle + #9 + Espece + #9 + Genre + #9 + Code;
        // chaque entree conservee consomme une ligne voulue : une ligne repetee garde ses doublons
        K := Presents.IndexOf(Cle);
        if (K < 0) and (Regle <> '') and (Espece <> '') and (Code <> '') then
          Chapitre.RemoveChild(N)
        else if K >= 0 then
          Presents.Delete(K);
      end;
      N := Suivant;
    end;
    // ce qui reste dans Presents est a creer
    for R := 0 to Presents.Count - 1 do
    begin
      Morceaux := Presents[R].Split([#9]);
      Entree := Doc.CreateElement('Entry');
      Chapitre.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(Entree);
      E := Doc.CreateElement('Rule');
      Entree.AppendChild(Doc.CreateTextNode(#10));
      Entree.AppendChild(E);
      EcrireValeurXML(E, Morceaux[0]);
      E := Doc.CreateElement('Specie');
      Entree.AppendChild(Doc.CreateTextNode(#10));
      Entree.AppendChild(E);
      EcrireValeurXML(E, Morceaux[1]);
      if Morceaux[2] = 'S' then
        E := Doc.CreateElement('Skill')
      else
        E := Doc.CreateElement('Talent');
      Entree.AppendChild(Doc.CreateTextNode(#10));
      Entree.AppendChild(E);
      EcrireValeurXML(E, Morceaux[3]);
      Entree.AppendChild(Doc.CreateTextNode(#10));
    end;
    Chapitre.AppendChild(Doc.CreateTextNode(#10));
  finally
    Voulus.Free;
    Presents.Free;
  end;
end;

function TPanelRegleEthnie.Controler: Boolean;
var
  R, K, C: Integer;
  Pareil: Boolean;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if FRegles.CodeDe(FGrille.Cells[0, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_809', 'Line %d: choose a rule.'), [R]));
      Exit(False);
    end;
    if FEspeces.CodeDe(FGrille.Cells[1, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_584', 'Line %d: choose a species or an ethnicity.'), [R]));
      Exit(False);
    end;
    if GenreDe(R) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_810', 'Line %d: choose skill or talent.'), [R]));
      Exit(False);
    end;
    if CodeElementDe(R) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_811', 'Line %d: choose the skill or talent given.'), [R]));
      Exit(False);
    end;
    for K := 1 to R - 1 do
    begin
      Pareil := True;
      for C := 0 to 3 do
        if FGrille.Cells[C, K] <> FGrille.Cells[C, R] then Pareil := False;
      // un code generique (« * ») peut etre repete : deux langues ou deux talents au choix
      if Pareil and (Copy(CodeElementDe(R), Length(CodeElementDe(R)), 1) = '*') then Pareil := False;
      if Pareil then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_586', 'Line %d: this link already exists (line %d).'), [R, K]));
        Exit(False);
      end;
    end;
  end;
end;

procedure TPanelRegleEthnie.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Liste: TListeLibelles;
begin
  if aRow < 1 then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  case aCol of
    0: TCustomComboBox(Editor).Items.Assign(FRegles.Libelles);
    1: TCustomComboBox(Editor).Items.Assign(FEspeces.Libelles);
    2: begin
         TCustomComboBox(Editor).Items.Clear;
         TCustomComboBox(Editor).Items.Add(FLibCompetence);
         TCustomComboBox(Editor).Items.Add(FLibTalent);
       end;
    3: begin
         Liste := ListeElements(aRow);
         if Liste = nil then
           TCustomComboBox(Editor).Items.Clear
         else
           TCustomComboBox(Editor).Items.Assign(Liste.Libelles);
       end;
  end;
end;

procedure TPanelRegleEthnie.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  // une nouvelle ligne reprend la regle, l'ethnie et le genre de la precedente : on ajoute le plus souvent a la meme
  if R > 1 then
  begin
    FGrille.Cells[0, R] := FGrille.Cells[0, R - 1];
    FGrille.Cells[1, R] := FGrille.Cells[1, R - 1];
    FGrille.Cells[2, R] := FGrille.Cells[2, R - 1];
  end;
  FGrille.Row := R;
  FGrille.Col := 3;
end;

procedure TPanelRegleEthnie.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
end;

procedure TPanelRegleEthnie.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelRegleEthnie.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelRegleEthnie.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelRegleEthnie.GetLectureSeule: Boolean;
begin
  Result := not FBarre.Visible;
end;

procedure TPanelRegleEthnie.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
end;

procedure TPanelRegleEthnie.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelRegleEthnie.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

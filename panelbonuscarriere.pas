unit PanelBonusCarriere;

{$mode ObjFPC}{$H+}

// Paliers d'un bonus de carriere (DATA_CAREER_BONUS, CONTEXT.md 2.44 et 2.107) dans sa fiche : quatre lignes fixes, une par
// niveau. Chaque niveau donne une competence (ou deux au choix A/B), un talent (idem), et peut ouvrir un choix libre de
// competences (<SkillChoice Count Value>). Le XML garde les codes ; la grille montre les libelles.
// <SpecialRule> n'est pas touche. Les modificateurs du niveau (<ModifyCarac>, <ModifySkill>, <ModifyWeapon>...) s'editent
// dans une fenetre a part (bouton sous la grille) qui reprend la grille TPanelModificateurs ; la colonne Modificateurs
// n'en donne que le nombre. Le travail de la fenetre reste dans une copie du niveau jusqu'a Ecrire (Valider de la fiche).
//
// Colonnes : 0 niveau, 1/2 competence (A, ou B), 3/4 talent (A, ou B), 5 nombre de competences du choix libre,
// 6 avancees gratuites, 7 nombre de modificateurs (lecture seule).
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra).

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, DOM, BCButton,
  ChargeConstantes, ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelBonusCarriere = class(TPanelExtraFiche)
  private
    FTitre: TLabel;
    FGrille: TStringGrid;
    FCompLib, FCompCode, FTalLib, FTalCode: TStringList;
    FLectureSeule: Boolean;
    FBoutonModif: TBCButton;
    FModele: TBCButton;
    FLibAttribut: TFonctionLibelle;
    FCompLiees: TStrings;
    FCodesCompLiees, FCodesCondition: TStringList;
    FCopies: array[1..4] of TDOMElement;  // copie de chaque niveau : les modificateurs s'y editent avant Valider
    procedure LibererCopies;
    procedure ModifierNiveau;
    procedure BoutonModifClick(Sender: TObject);
    procedure FermerFenetreClick(Sender: TObject);
    function  LibDe(Libs, Codes: TStringList; const Code: String): String;
    function  CodeDe(Libs, Codes: TStringList; const Lib: String): String;
    procedure PoserGroupe(R, Col: Integer; Libs, Codes: TStringList; const Valeur: String);
    function  ComposerGroupe(R, Col: Integer; Libs, Codes: TStringList): String;
    function  TrouverNiveau(Element: TDOMElement; N: Integer): TDOMElement;
    procedure PoserBalise(Niveau: TDOMElement; const Balise, Valeur: String);
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Modele et suivants : ce qu'il faut a la grille des modificateurs (voir TPanelModificateurs.Initialiser) ;
    // Conditions : codes des conditions proposees (liste detenue par l'appelant).
    procedure Initialiser(Modele: TBCButton; ALibAttribut: TFonctionLibelle; CompLibelles: TStrings;
      CompCodes, Conditions: TStringList);
    // A appeler avant chaque Charger. Competences et Talents = "code=libelle|..." (les choix proposes).
    procedure Configurer(const Competences, Talents: String);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  NbNiveaux = 4;
  HauteurPaliers = 232;
  ColModificateurs = 7;

function EstModificateur(Noeud: TDOMNode): Boolean;
begin
  Result := (Noeud.NodeType = ELEMENT_NODE) and
    ((Pos('Modify', Noeud.NodeName) = 1) or (Noeud.NodeName = ConstXmlModificateur));
end;

function CompterModificateurs(Niveau: TDOMElement): Integer;
var
  Noeud: TDOMNode;
begin
  Result := 0;
  if Niveau = nil then Exit;
  Noeud := Niveau.FirstChild;
  while Noeud <> nil do
  begin
    if EstModificateur(Noeud) then Inc(Result);
    Noeud := Noeud.NextSibling;
  end;
end;

// Texte qui change des qu'un modificateur change (pour detecter une modification de la fiche).
function EmpreinteModificateurs(Niveau: TDOMElement): String;
var
  Noeud: TDOMNode;
  I: Integer;
begin
  Result := '';
  if Niveau = nil then Exit;
  Noeud := Niveau.FirstChild;
  while Noeud <> nil do
  begin
    if EstModificateur(Noeud) then
    begin
      Result := Result + '<' + Noeud.NodeName;
      for I := 0 to Noeud.Attributes.Length - 1 do
        Result := Result + ' ' + Noeud.Attributes[I].NodeName + '=' + Noeud.Attributes[I].NodeValue;
      Result := Result + '>' + Noeud.TextContent;
    end;
    Noeud := Noeud.NextSibling;
  end;
end;

procedure Remplir(Libs, Codes: TStringList; const Choix: String);
var
  Liste: TStringList;
  I, P: Integer;
begin
  Libs.Clear;
  Codes.Clear;
  Liste := TStringList.Create;
  try
    Liste.Delimiter := '|';
    Liste.StrictDelimiter := True;
    Liste.DelimitedText := Choix;
    for I := 0 to Liste.Count - 1 do
    begin
      P := Pos('=', Liste[I]);
      if (P > 1) and (Codes.IndexOf(Copy(Liste[I], 1, P - 1)) < 0) then
      begin
        Codes.Add(Copy(Liste[I], 1, P - 1));
        Libs.Add(Copy(Liste[I], P + 1, MaxInt));
      end;
    end;
  finally
    Liste.Free;
  end;
end;

constructor TPanelBonusCarriere.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCompLib := TStringList.Create;
  FCompCode := TStringList.Create;
  FTalLib := TStringList.Create;
  FTalCode := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurPaliers;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 600, 20);
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.SetBounds(0, 24, 1000, 150);
  FGrille.ColCount := 8;
  FGrille.RowCount := NbNiveaux + 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.ColWidths[0] := 60;
  FGrille.ColWidths[1] := 190;
  FGrille.ColWidths[2] := 190;
  FGrille.ColWidths[3] := 190;
  FGrille.ColWidths[4] := 190;
  FGrille.ColWidths[5] := 70;
  FGrille.ColWidths[6] := 80;
  FGrille.ColWidths[7] := 100;
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.OnSelectCell := @GrilleSelectCell;
  Visible := False;
end;

destructor TPanelBonusCarriere.Destroy;
begin
  LibererCopies;
  FCompLib.Free;
  FCompCode.Free;
  FTalLib.Free;
  FTalCode.Free;
  inherited Destroy;
end;

procedure TPanelBonusCarriere.Initialiser(Modele: TBCButton; ALibAttribut: TFonctionLibelle; CompLibelles: TStrings;
  CompCodes, Conditions: TStringList);
begin
  FModele := Modele;
  FLibAttribut := ALibAttribut;
  FCompLiees := CompLibelles;
  FCodesCompLiees := CompCodes;
  FCodesCondition := Conditions;
  FBoutonModif := TBCButtonContour.Create(Self);
  FBoutonModif.Assign(Modele);
  FBoutonModif.Parent := Self;
  FBoutonModif.SetBounds(0, 180, 300, 40);
  FBoutonModif.OnClick := @BoutonModifClick;
  FBoutonModif.Caption := GetTexteLibelle('RULES-LAB_562', 'Level modifiers...');
  FTitre.Caption := GetTexteLibelle('RULES-LAB_552', 'Career bonus levels');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_553', 'Level');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_009', 'Skill');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_554', 'or');
  FGrille.Cells[3, 0] := GetTexteLibelle('RULES-LAB_007', 'Talent');
  FGrille.Cells[4, 0] := GetTexteLibelle('RULES-LAB_554', 'or');
  FGrille.Cells[5, 0] := GetTexteLibelle('RULES-LAB_555', 'Free choice (skills)');
  FGrille.Cells[6, 0] := GetTexteLibelle('RULES-LAB_556', 'Free advances');
  FGrille.Cells[7, 0] := GetTexteLibelle('RULES-LAB_557', 'Modifiers');
  MiseAJourUnContenaire(Self);
end;

procedure TPanelBonusCarriere.LibererCopies;
var
  N: Integer;
begin
  for N := 1 to NbNiveaux do
  begin
    FCopies[N].Free;
    FCopies[N] := nil;
  end;
end;

procedure TPanelBonusCarriere.Configurer(const Competences, Talents: String);
begin
  Remplir(FCompLib, FCompCode, Competences);
  Remplir(FTalLib, FTalCode, Talents);
end;

function TPanelBonusCarriere.LibDe(Libs, Codes: TStringList; const Code: String): String;
var
  I: Integer;
begin
  if Trim(Code) = '' then Exit('');
  I := Codes.IndexOf(Trim(Code));
  if I >= 0 then
    Result := Libs[I]
  else
  begin
    // un code que la liste ne propose pas (element d'un autre livre) reste visible et reste choisissable
    Result := Trim(Code);
    Codes.Add(Result);
    Libs.Add(Result);
  end;
end;

function TPanelBonusCarriere.CodeDe(Libs, Codes: TStringList; const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  if Trim(Lib) = '' then Exit;
  // les libelles de la liste peuvent porter une espace finale (Description du livre) : comparaison sans espaces
  for I := 0 to Libs.Count - 1 do
    if SameText(Trim(Libs[I]), Trim(Lib)) then Exit(Codes[I]);
end;

// "A" ou "A/B" : la premiere alternative en Col, le reste (une ou plusieurs) en Col + 1.
procedure TPanelBonusCarriere.PoserGroupe(R, Col: Integer; Libs, Codes: TStringList; const Valeur: String);
var
  P: Integer;
  A, B: String;
begin
  P := Pos('/', Valeur);
  if P > 0 then
  begin
    A := Copy(Valeur, 1, P - 1);
    B := Copy(Valeur, P + 1, MaxInt);
  end
  else
  begin
    A := Valeur;
    B := '';
  end;
  FGrille.Cells[Col, R] := LibDe(Libs, Codes, A);
  FGrille.Cells[Col + 1, R] := LibDe(Libs, Codes, B);
end;

function TPanelBonusCarriere.ComposerGroupe(R, Col: Integer; Libs, Codes: TStringList): String;
var
  B: String;
begin
  Result := CodeDe(Libs, Codes, FGrille.Cells[Col, R]);
  if Result = '' then Exit;
  B := CodeDe(Libs, Codes, FGrille.Cells[Col + 1, R]);
  if B <> '' then Result := Result + '/' + B;
end;

function TPanelBonusCarriere.TrouverNiveau(Element: TDOMElement; N: Integer): TDOMElement;
var
  Noeud: TDOMNode;
begin
  Result := nil;
  Noeud := Element.FirstChild;
  while Noeud <> nil do
  begin
    if (Noeud.NodeType = ELEMENT_NODE) and (Noeud.NodeName = 'Level') and
       (StrToIntDef(Trim(ValeurXML(Noeud.FindNode('Order'))), 0) = N) then
      Exit(TDOMElement(Noeud));
    Noeud := Noeud.NextSibling;
  end;
end;

procedure TPanelBonusCarriere.Charger(Element: TDOMElement);
var
  N, R, NbModif: Integer;
  Niv: TDOMElement;
  Noeud: TDOMNode;
begin
  FGrille.EditorMode := False;
  LibererCopies;
  for N := 1 to NbNiveaux do
  begin
    R := N;
    FGrille.Rows[R].Clear;
    FGrille.Cells[0, R] := IntToStr(N);
    Niv := TrouverNiveau(Element, N);
    if Niv = nil then
    begin
      FCopies[N] := Element.OwnerDocument.CreateElement('Level');
      Continue;
    end;
    FCopies[N] := TDOMElement(Niv.CloneNode(True));
    PoserGroupe(R, 1, FCompLib, FCompCode, ValeurXML(Niv.FindNode('Skill')));
    PoserGroupe(R, 3, FTalLib, FTalCode, ValeurXML(Niv.FindNode('Talent')));
    NbModif := CompterModificateurs(Niv);
    Noeud := Niv.FirstChild;
    while Noeud <> nil do
    begin
      if (Noeud.NodeType = ELEMENT_NODE) then
      begin
        if Noeud.NodeName = 'SkillChoice' then
        begin
          FGrille.Cells[5, R] := TDOMElement(Noeud).GetAttribute('Count');
          FGrille.Cells[6, R] := TDOMElement(Noeud).GetAttribute('Value');
        end;
      end;
      Noeud := Noeud.NextSibling;
    end;
    if NbModif > 0 then FGrille.Cells[7, R] := IntToStr(NbModif);
  end;
end;

function TPanelBonusCarriere.Controler: Boolean;
var
  R: Integer;
  Nb, Av: String;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to NbNiveaux do
  begin
    if ((Trim(FGrille.Cells[2, R]) <> '') and (Trim(FGrille.Cells[1, R]) = '')) or
       ((Trim(FGrille.Cells[4, R]) <> '') and (Trim(FGrille.Cells[3, R]) = '')) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_559'), [R]));
      Exit(False);
    end;
    Nb := Trim(FGrille.Cells[5, R]);
    Av := Trim(FGrille.Cells[6, R]);
    if ((Nb <> '') or (Av <> '')) and ((StrToIntDef(Nb, 0) <= 0) or (StrToIntDef(Av, 0) <= 0)) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_560'), [R]));
      Exit(False);
    end;
  end;
end;

// Pose la valeur d'une balise du niveau ; une balise absente n'est creee que si elle porte une valeur, avant les
// modificateurs du niveau.
procedure TPanelBonusCarriere.PoserBalise(Niveau: TDOMElement; const Balise, Valeur: String);
var
  E: TDOMElement;
  Noeud: TDOMNode;
begin
  E := TDOMElement(Niveau.FindNode(Balise));
  if E = nil then
  begin
    if Valeur = '' then Exit;
    E := Niveau.OwnerDocument.CreateElement(Balise);
    Noeud := Niveau.FirstChild;
    while (Noeud <> nil) and not ((Noeud.NodeType = ELEMENT_NODE) and
          ((Pos('Modify', Noeud.NodeName) = 1) or (Noeud.NodeName = 'SkillChoice') or (Noeud.NodeName = 'SpecialRule'))) do
      Noeud := Noeud.NextSibling;
    if Noeud <> nil then Niveau.InsertBefore(E, Noeud) else Niveau.AppendChild(E);
  end;
  EcrireValeurXML(E, Valeur);
end;

procedure TPanelBonusCarriere.Ecrire(Element: TDOMElement);
var
  N, R: Integer;
  Niv, E: TDOMElement;
  Noeud, Suivant, Apres: TDOMNode;
  Competence, Talent, Nb, Av: String;
begin
  FGrille.EditorMode := False;
  for N := 1 to NbNiveaux do
  begin
    R := N;
    Competence := ComposerGroupe(R, 1, FCompLib, FCompCode);
    Talent := ComposerGroupe(R, 3, FTalLib, FTalCode);
    Nb := Trim(FGrille.Cells[5, R]);
    Av := Trim(FGrille.Cells[6, R]);
    Niv := TrouverNiveau(Element, N);
    if Niv = nil then
    begin
      if (Competence = '') and (Talent = '') and (Nb = '') and (CompterModificateurs(FCopies[N]) = 0) and
         (FCopies[N].FindNode('SpecialRule') = nil) then Continue;
      Niv := Element.OwnerDocument.CreateElement('Level');
      Niv.SetAttribute('id', Element.GetAttribute('id') + '_' + IntToStr(N));
      Element.AppendChild(Niv);
      E := Element.OwnerDocument.CreateElement('Order');
      Niv.AppendChild(E);
      EcrireValeurXML(E, IntToStr(N));
      // SpecialRule ne s'edite pas : un niveau cree de toutes pieces la reprend de la copie chargee
      if FCopies[N].FindNode('SpecialRule') <> nil then
        Niv.AppendChild(FCopies[N].FindNode('SpecialRule').CloneNode(True, Niv.OwnerDocument));
    end;
    PoserBalise(Niv, 'Skill', Competence);
    PoserBalise(Niv, 'Talent', Talent);
    // modificateurs : ceux de la copie remplacent ceux du niveau, places avant SkillChoice / SpecialRule
    Noeud := Niv.FirstChild;
    while Noeud <> nil do
    begin
      Suivant := Noeud.NextSibling;
      if EstModificateur(Noeud) then Niv.RemoveChild(Noeud);
      Noeud := Suivant;
    end;
    Apres := Niv.FirstChild;
    while (Apres <> nil) and not ((Apres.NodeType = ELEMENT_NODE) and
          ((Apres.NodeName = 'SkillChoice') or (Apres.NodeName = 'SpecialRule'))) do
      Apres := Apres.NextSibling;
    if FCopies[N] <> nil then
    begin
      Noeud := FCopies[N].FirstChild;
      while Noeud <> nil do
      begin
        if EstModificateur(Noeud) then
        begin
          if Apres <> nil then Niv.InsertBefore(Noeud.CloneNode(True, Niv.OwnerDocument), Apres)
          else Niv.AppendChild(Noeud.CloneNode(True, Niv.OwnerDocument));
        end;
        Noeud := Noeud.NextSibling;
      end;
    end;
    Noeud := Niv.FirstChild;
    while Noeud <> nil do
    begin
      Suivant := Noeud.NextSibling;
      if (Noeud.NodeType = ELEMENT_NODE) and (Noeud.NodeName = 'SkillChoice') then
        Niv.RemoveChild(Noeud);
      Noeud := Suivant;
    end;
    if (Nb <> '') and (Av <> '') then
    begin
      E := Element.OwnerDocument.CreateElement('SkillChoice');
      E.SetAttribute('Count', IntToStr(StrToIntDef(Nb, 0)));
      E.SetAttribute('Value', IntToStr(StrToIntDef(Av, 0)));
      Niv.AppendChild(E);
    end;
  end;
end;

function TPanelBonusCarriere.Signature(const Sep: String): String;
var
  R, C: Integer;
begin
  Result := '';
  for R := 1 to NbNiveaux do
    for C := 1 to 6 do
      Result := Result + Sep + FGrille.Cells[C, R];
  for R := 1 to NbNiveaux do
    Result := Result + Sep + EmpreinteModificateurs(FCopies[R]);
end;

procedure TPanelBonusCarriere.MettreLectureSeule(Valeur: Boolean);
begin
  FLectureSeule := Valeur;
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
end;

procedure TPanelBonusCarriere.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Items: TStringList;
begin
  if (aRow < 1) or (aCol < 1) or (aCol > 4) or FLectureSeule then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  Items := TStringList.Create;
  try
    Items.Add('');  // case vide : pas de choix ou pas d'alternative
    if aCol <= 2 then Items.AddStrings(FCompLib) else Items.AddStrings(FTalLib);
    TCustomComboBox(Editor).Items.Assign(Items);
  finally
    Items.Free;
  end;
end;

// Fenetre des modificateurs du niveau choisi : la grille TPanelModificateurs travaille sur la copie du niveau, qui
// n'est ecrite dans le XML qu'a Valider (Ecrire). En lecture seule, la fenetre ne fait que montrer.
procedure TPanelBonusCarriere.ModifierNiveau;
var
  Fenetre: TForm;
  Barre: TPanel;
  Grille: TPanelModificateurs;
  BOk, BAnnuler: TBCButton;
  N: Integer;
begin
  N := FGrille.Row;
  if (N < 1) or (N > NbNiveaux) or (FCopies[N] = nil) then Exit;
  if FLectureSeule and (CompterModificateurs(FCopies[N]) = 0) then Exit;
  FGrille.EditorMode := False;
  Fenetre := TForm.CreateNew(nil);
  try
    Fenetre.Caption := Format(GetTexteLibelle('RULES-LAB_563', 'Level %d: modifiers'), [N]);
    Fenetre.Position := poScreenCenter;
    Fenetre.SetBounds(0, 0, 950, 520);
    Barre := TPanel.Create(Fenetre);
    Barre.Parent := Fenetre;
    Barre.Align := alBottom;
    Barre.Height := 56;
    Barre.BevelOuter := bvNone;
    Barre.Caption := '';
    Grille := TPanelModificateurs.Create(Fenetre);
    Grille.Parent := Fenetre;
    Grille.Align := alClient;
    Grille.Initialiser(FModele, FLibAttribut, FCompLiees, FCodesCompLiees);
    Grille.CodesCondition := FCodesCondition;
    Grille.Charger(FCopies[N]);
    Grille.LectureSeule := FLectureSeule;
    BAnnuler := TBCButtonContour.Create(Fenetre);
    BAnnuler.Assign(FModele);
    BAnnuler.Parent := Barre;
    BAnnuler.SetBounds(240, 8, 220, 40);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @FermerFenetreClick;
    if not FLectureSeule then
    begin
      BOk := TBCButtonContour.Create(Fenetre);
      BOk.Assign(FModele);
      BOk.Parent := Barre;
      BOk.SetBounds(8, 8, 220, 40);
      BOk.Caption := GetTexteLibelle('RULES-LAB_086');
      BOk.Tag := mrOk;
      BOk.OnClick := @FermerFenetreClick;
    end;
    MiseAJourUnContenaire(Fenetre);
    // un controle refuse laisse la fenetre ouverte (le message nomme la ligne)
    repeat
      if Fenetre.ShowModal <> mrOk then Exit;
    until Grille.Controler;
    Grille.Ecrire(FCopies[N]);
    FGrille.Cells[ColModificateurs, N] := '';
    if CompterModificateurs(FCopies[N]) > 0 then
      FGrille.Cells[ColModificateurs, N] := IntToStr(CompterModificateurs(FCopies[N]));
  finally
    Fenetre.Free;
  end;
end;

procedure TPanelBonusCarriere.BoutonModifClick(Sender: TObject);
begin
  ModifierNiveau;
end;

procedure TPanelBonusCarriere.FermerFenetreClick(Sender: TObject);
begin
  TForm(TComponent(Sender).Owner).ModalResult := TControl(Sender).Tag;
end;

// Le numero de niveau et le nombre de modificateurs ne se saisissent pas.
procedure TPanelBonusCarriere.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  CanSelect := (aCol <> 0) and (aCol <> 7);
end;

end.

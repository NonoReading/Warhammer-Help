unit PanelEquipClasse;

{$mode ObjFPC}{$H+}

// Table editable de l'equipement de depart par classe (DATA_CLASS_ITEM) : une ligne par objet, avec sa classe,
// son code (ou son nom libre, "Lunch") et sa quantite. Le XML garde les codes ; la grille montre aussi le
// libelle de l'objet. Le code se saisit a la main ou se choisit dans les fenetres d'armes, d'armures et de
// divers (CONTEXT.md 2.107, suite).
//
// Colonne Action : Add (ajoute l'objet), Remove (retire l'objet cible d'une autre source, ex. le Rulebook) ou
// Replace (remplace l'objet cible par celui de la ligne). Le XML ecrit <Remove>"code"</Remove> et
// <Replace from="code">"nouveau"</Replace> apres le SUBCHAPTER_ITEM de la classe (meme vocabulaire que
// DATA_CAREER_ADAPTATION). Colonnes cachees : 4 = code de l'objet, 7 = code de la cible.
//
// Usage : creer, Initialiser, poser (Parent + SetBounds), Configurer puis Charger(Chapitre) a l'ouverture,
// Controler puis Ecrire(Chapitre) a la validation. Chapitre = l'element DATA_CLASS_ITEM du livre.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, MessageTest, Graphics, DOM, BCButton,
  ChargeConstantes, ChargeTexte, GlobalFonts, PanelTirage;

type
  // genre d'un objet (1 arme, 2 armure, 3 divers) d'apres son code ou son nom
  TFonctionGenreEquip = function(const Nom: String): Integer of object;
  // libelle d'un objet : code ou nom libre, quantites ("1", ou "2/1" pour un choix)
  TFonctionLibelleEquip = function(const Nom, Quantites: String): String of object;
  // codes des objets deja donnes a une classe par une autre source (Rulebook), pour choisir une cible
  TFonctionCiblesEquip = procedure(const CodeClasse: String; Codes: TStrings) of object;
  // Genre : 1 arme, 2 armure, 3 divers ; Code = code choisi, '' si l'utilisateur a annule
  TChoixEquipement = procedure(Genre: Integer; out Code: String) of object;

  TPanelEquipClasse = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre, FBarre2: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonValider, FBoutonAnnuler: TBCButton;
    FBoutonArme, FBoutonArmure, FBoutonDivers: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FOnChoisir: TChoixEquipement;
    FLibClasse: TFonctionLibelleTirage;
    FLibEquip: TFonctionLibelleEquip;
    FGenreEquip: TFonctionGenreEquip;
    FCibles: TFonctionCiblesEquip;
    FClassesLib, FClassesCode: TStringList;
    FActions: array[0..2] of String;  // libelles : 0 Add, 1 Remove, 2 Replace
    function  ActionDe(R: Integer): Integer;
    procedure ListeCibles(R: Integer; Codes, Libelles: TStrings);
    function  CodeCible(R: Integer; const Lib: String): String;
    function  LibelleClasse(const Code: String): String;
    function  CodeClasseDe(const Lib: String): String;
    function  QuantiteValide(const Q: String): Boolean;
    procedure MajLibelleLigne(R: Integer);
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonChoisirClick(Sender: TObject);
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
    // A appeler avant chaque Charger. Classes : codes que le choix d'une ligne propose.
    procedure Configurer(ALibClasse: TFonctionLibelleTirage; ALibEquip: TFonctionLibelleEquip;
      AGenreEquip: TFonctionGenreEquip; Classes: TStrings; ACibles: TFonctionCiblesEquip);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque ligne a une classe, un code ou un nom, et des quantites entieres >= 1 ; sinon message.
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  OnChoisir: TChoixEquipement read FOnChoisir write FOnChoisir;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

implementation

constructor TPanelEquipClasse.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClassesLib := TStringList.Create;
  FClassesCode := TStringList.Create;
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
  FGrille.ColCount := 9;  // 4 = code ou nom libre (cachee), 5 = Action, 6 = cible, 7 = code de la cible (cachee), 8 = groupe d'objets lies par '+' (cachee)
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.OnSelectCell := @GrilleSelectCell;
  FGrille.OnSetEditText := @GrilleSetEditText;
  Visible := False;
end;

destructor TPanelEquipClasse.Destroy;
begin
  FClassesLib.Free;
  FClassesCode.Free;
  inherited Destroy;
end;

function TPanelEquipClasse.Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
  Gauche, Largeur: Integer): TBCButton;
begin
  Result := TBCButtonContour.Create(Self);
  Result.Assign(Modele);
  Result.Parent := Barre;
  Result.Caption := Legende;
  Result.OnClick := Clic;
  Result.SetBounds(Gauche, 0, Largeur, 50);
end;

procedure TPanelEquipClasse.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230);
  FBoutonRetirer := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250);
  FBoutonValider := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_086'), @BoutonValiderClick, 500, 150);
  FBoutonAnnuler := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_166'), @BoutonAnnulerClick, 660, 150);
  // meme choix que l'equipement d'une carriere : Arme, Armure, Divers
  FBoutonArme := Copie(Modele, FBarre2, GetTexteLibelle('RULES-LAB_063') + '...', @BoutonChoisirClick, 0, 230);
  FBoutonArme.Tag := 1;
  FBoutonArmure := Copie(Modele, FBarre2, GetTexteLibelle('RULES-LAB_065') + '...', @BoutonChoisirClick, 240, 250);
  FBoutonArmure.Tag := 2;
  FBoutonDivers := Copie(Modele, FBarre2, GetTexteLibelle('RULES-LAB_064') + '...', @BoutonChoisirClick, 500, 310);
  FBoutonDivers.Tag := 3;
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

procedure TPanelEquipClasse.Configurer(ALibClasse: TFonctionLibelleTirage; ALibEquip: TFonctionLibelleEquip;
  AGenreEquip: TFonctionGenreEquip; Classes: TStrings; ACibles: TFonctionCiblesEquip);
var
  I: Integer;
begin
  FCibles := ACibles;
  FActions[0] := GetTexteLibelle('RULES-LAB_682', 'Add');
  FActions[1] := GetTexteLibelle('RULES-LAB_683', 'Remove');
  FActions[2] := GetTexteLibelle('RULES-LAB_684', 'Replace');
  FLibClasse := ALibClasse;
  FLibEquip := ALibEquip;
  FGenreEquip := AGenreEquip;
  FClassesLib.Clear;
  FClassesCode.Clear;
  for I := 0 to Classes.Count - 1 do
    LibelleClasse(Classes[I]);
  FGrille.ColWidths[0] := 200;
  FGrille.ColWidths[1] := 120;
  FGrille.ColWidths[2] := 420;
  FGrille.ColWidths[3] := 90;
  FGrille.ColWidths[4] := 0;
  FGrille.ColWidths[5] := 120;
  FGrille.ColWidths[6] := 380;
  FGrille.ColWidths[7] := 0;
  FGrille.ColWidths[8] := 0;
  FGrille.Cells[5, 0] := GetTexteLibelle('RULES-LAB_681', 'Action');
  FGrille.Cells[6, 0] := GetTexteLibelle('RULES-LAB_685', 'Target item');
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_385', 'Class');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_171', 'Type');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_013', 'Equipment');
  FGrille.Cells[3, 0] := GetTexteLibelle('RULES-LAB_376', 'Quantity');
end;

// Libelle de la classe dans la grille ; une classe hors liste proposee y est ajoutee.
function TPanelEquipClasse.LibelleClasse(const Code: String): String;
var
  I: Integer;
begin
  I := FClassesCode.IndexOf(Code);
  if I >= 0 then Exit(FClassesLib[I]);
  Result := FLibClasse(Code);
  if FClassesLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FClassesLib.Add(Result);
  FClassesCode.Add(Code);
end;

function TPanelEquipClasse.CodeClasseDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FClassesLib.IndexOf(Lib);
  if I >= 0 then Result := FClassesCode[I];
end;

// Quantites : un entier >= 1, ou plusieurs separes par SeparateurMulti (un choix "A/B" a une quantite par branche).
function TPanelEquipClasse.QuantiteValide(const Q: String): Boolean;
var
  Parts: TStringList;
  J: Integer;
begin
  Result := True;
  if Trim(Q) = '' then Exit;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := SeparateurMulti;
    Parts.DelimitedText := Q;
    for J := 0 to Parts.Count - 1 do
      if StrToIntDef(Trim(Parts[J]), 0) < 1 then Result := False;
  finally
    Parts.Free;
  end;
end;

// 0 = ajoute (par defaut), 1 = retire, 2 = remplace
function TPanelEquipClasse.ActionDe(R: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to 2 do
    if FGrille.Cells[5, R] = FActions[I] then Result := I;
end;

procedure TPanelEquipClasse.MajLibelleLigne(R: Integer);
var
  Q, Code: String;
begin
  Q := Trim(FGrille.Cells[3, R]);
  if Q = '' then Q := '1';
  FGrille.Cells[5, R] := FActions[ActionDe(R)];
  if Trim(FGrille.Cells[7, R]) <> '' then
    FGrille.Cells[6, R] := FLibEquip(Trim(FGrille.Cells[7, R]), '1')
  else
    FGrille.Cells[6, R] := '';
  if ActionDe(R) = 1 then
  begin
    // retrait : pas d'objet propre, le type est celui de la cible
    FGrille.Cells[2, R] := '';
    Code := Trim(FGrille.Cells[7, R]);
  end
  else
  begin
    FGrille.Cells[2, R] := FLibEquip(Trim(FGrille.Cells[4, R]), Q);
    Code := Trim(FGrille.Cells[4, R]);
  end;
  case FGenreEquip(Code) of
    1: FGrille.Cells[1, R] := GetTexteLibelle('RULES-LAB_063', 'Weapon');
    2: FGrille.Cells[1, R] := GetTexteLibelle('RULES-LAB_065', 'Armor');
  else
    FGrille.Cells[1, R] := GetTexteLibelle('RULES-LAB_064', 'Various');
  end;
end;

procedure TPanelEquipClasse.Charger(Chapitre: TDOMElement);
var
  Cl, Sous, It: TDOMNode;
  Classe, Q, Marque: String;
  R, J: Integer;
  Parts: TStringList;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  if FActions[0] = '' then
  begin
    FActions[0] := 'Add';
    FActions[1] := 'Remove';
    FActions[2] := 'Replace';
  end;
  Parts := TStringList.Create;
  Parts.StrictDelimiter := True;
  Parts.Delimiter := SeparateurEnsemble;
  try
  if Chapitre <> nil then
  begin
    Cl := Chapitre.FirstChild;
    while Cl <> nil do
    begin
      if (Cl.NodeType = ELEMENT_NODE) and (Cl.NodeName = 'Class') then
      begin
        Classe := TDOMElement(Cl).GetAttribute('name');
        Sous := Cl.FirstChild;
        while Sous <> nil do
        begin
          if (Sous.NodeType = ELEMENT_NODE) and (Sous.NodeName = 'SUBCHAPTER_ITEM') then
          begin
            It := Sous.FirstChild;
            while It <> nil do
            begin
              if (It.NodeType = ELEMENT_NODE) and (It.NodeName = 'Item') and
                 (TDOMElement(It).GetAttribute('name') <> '') then
              begin
                Q := TDOMElement(It).GetAttribute('quantite');
                if Q = '' then Q := '1';
                // des objets lies par '+' (Rulebook) deviennent une ligne chacun, avec la meme quantite
                Parts.DelimitedText := TDOMElement(It).GetAttribute('name');
                for J := 0 to Parts.Count - 1 do
                begin
                  R := FGrille.RowCount;
                  FGrille.RowCount := R + 1;
                  FGrille.Cells[0, R] := LibelleClasse(Classe);
                  FGrille.Cells[4, R] := Trim(Parts[J]);
                  FGrille.Cells[3, R] := Q;
                  FGrille.Cells[5, R] := FActions[0];
                  // lignes issues d'un meme Item « A+B » : meme marqueur, reassemblees a l'ecriture
                  if J = 0 then Marque := IntToStr(R);
                  if Parts.Count > 1 then FGrille.Cells[8, R] := Marque;
                  MajLibelleLigne(R);
                end;
              end;
              It := It.NextSibling;
            end;
          end
          else if (Sous.NodeType = ELEMENT_NODE) and (Sous.NodeName = 'Remove') then
          begin
            R := FGrille.RowCount;
            FGrille.RowCount := R + 1;
            FGrille.Cells[0, R] := LibelleClasse(Classe);
            FGrille.Cells[3, R] := '';
            FGrille.Cells[4, R] := '';
            FGrille.Cells[5, R] := FActions[1];
            FGrille.Cells[7, R] := Trim(StringReplace(Sous.TextContent, '"', '', [rfReplaceAll]));
            MajLibelleLigne(R);
          end
          else if (Sous.NodeType = ELEMENT_NODE) and (Sous.NodeName = 'Replace') then
          begin
            R := FGrille.RowCount;
            FGrille.RowCount := R + 1;
            FGrille.Cells[0, R] := LibelleClasse(Classe);
            FGrille.Cells[3, R] := TDOMElement(Sous).GetAttribute('quantite');
            FGrille.Cells[4, R] := Trim(StringReplace(Sous.TextContent, '"', '', [rfReplaceAll]));
            FGrille.Cells[5, R] := FActions[2];
            FGrille.Cells[7, R] := TDOMElement(Sous).GetAttribute('from');
            MajLibelleLigne(R);
          end;
          Sous := Sous.NextSibling;
        end;
      end;
      Cl := Cl.NextSibling;
    end;
  end;
  finally
    Parts.Free;
  end;
end;

// Une classe par bloc, dans l'ordre ou elles apparaissent dans la grille ; les objets gardent leur ordre.
procedure TPanelEquipClasse.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  Classes: TStringList;
  ElClasse, ElSous, ElItem: TDOMElement;
  I, R: Integer;
  Code, Q, MarqueAvant: String;
begin
  FGrille.EditorMode := False;
  MarqueAvant := '';
  Doc := Chapitre.OwnerDocument;
  while Chapitre.FirstChild <> nil do
    Chapitre.RemoveChild(Chapitre.FirstChild);
  Classes := TStringList.Create;
  try
    for R := 1 to FGrille.RowCount - 1 do
    begin
      Code := CodeClasseDe(Trim(FGrille.Cells[0, R]));
      if Classes.IndexOf(Code) < 0 then Classes.Add(Code);
    end;
    for I := 0 to Classes.Count - 1 do
    begin
      ElClasse := Doc.CreateElement('Class');
      ElClasse.SetAttribute('name', Classes[I]);
      ElSous := nil;
      ElItem := nil;
      for R := 1 to FGrille.RowCount - 1 do
        if (CodeClasseDe(Trim(FGrille.Cells[0, R])) = Classes[I]) and (ActionDe(R) = 0) then
        begin
          if ElSous = nil then
          begin
            ElSous := Doc.CreateElement('SUBCHAPTER_ITEM');
            ElClasse.AppendChild(Doc.CreateTextNode(#10));
            ElClasse.AppendChild(ElSous);
          end;
          // ligne du meme groupe que la precedente : objet lie par '+' a celui deja ecrit
          if (ElItem <> nil) and (Trim(FGrille.Cells[8, R]) <> '') and (Trim(FGrille.Cells[8, R]) = MarqueAvant) then
          begin
            ElItem.SetAttribute('name', ElItem.GetAttribute('name') + SeparateurEnsemble + Trim(FGrille.Cells[4, R]));
            Continue;
          end;
          MarqueAvant := Trim(FGrille.Cells[8, R]);
          Q := Trim(FGrille.Cells[3, R]);
          ElItem := Doc.CreateElement('Item');
          ElItem.SetAttribute('name', Trim(FGrille.Cells[4, R]));
          if (Q <> '') and (Q <> '1') then ElItem.SetAttribute('quantite', Q);
          ElItem.AppendChild(Doc.CreateTextNode('"1"'));
          ElSous.AppendChild(Doc.CreateTextNode(#10));
          ElSous.AppendChild(ElItem);
        end;
      if ElSous <> nil then
        ElSous.AppendChild(Doc.CreateTextNode(#10));
      // retraits et remplacements, apres les ajouts de la classe
      for R := 1 to FGrille.RowCount - 1 do
        if (CodeClasseDe(Trim(FGrille.Cells[0, R])) = Classes[I]) and (ActionDe(R) > 0) then
        begin
          if ActionDe(R) = 1 then
          begin
            ElItem := Doc.CreateElement('Remove');
            ElItem.AppendChild(Doc.CreateTextNode('"' + Trim(FGrille.Cells[7, R]) + '"'));
          end
          else
          begin
            ElItem := Doc.CreateElement('Replace');
            ElItem.SetAttribute('from', Trim(FGrille.Cells[7, R]));
            Q := Trim(FGrille.Cells[3, R]);
            if Q <> '' then ElItem.SetAttribute('quantite', Q);
            ElItem.AppendChild(Doc.CreateTextNode('"' + Trim(FGrille.Cells[4, R]) + '"'));
          end;
          ElClasse.AppendChild(Doc.CreateTextNode(#10));
          ElClasse.AppendChild(ElItem);
        end;
      ElClasse.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(ElClasse);
    end;
    Chapitre.AppendChild(Doc.CreateTextNode(#10));
  finally
    Classes.Free;
  end;
end;

function TPanelEquipClasse.Controler: Boolean;
var
  R: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if CodeClasseDe(Trim(FGrille.Cells[0, R])) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_529', 'Line %d: choose a class.'), [R]));
      Exit(False);
    end;
    if (ActionDe(R) > 0) and (Trim(FGrille.Cells[7, R]) = '') then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_686', 'Line %d: choose the item to remove or replace.'), [R]));
      Exit(False);
    end;
    if ActionDe(R) = 1 then Continue;  // un retrait n'a ni objet ni quantite
    if (Trim(FGrille.Cells[4, R]) = '') or not QuantiteValide(FGrille.Cells[3, R]) then
    begin
      ShowMessage(Format('%d : ', [R]) + GetTexteLibelle('RULES-LAB_379'));
      Exit(False);
    end;
  end;
end;

procedure TPanelEquipClasse.GrilleSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  // le type se deduit du code : on ne s'y place pas
  if ((aCol = 1) or (aCol = 4) or (aCol = 7)) and (aRow >= 1) then CanSelect := False;
  if (aCol = 6) and (aRow >= 1) and (ActionDe(aRow) = 0) then CanSelect := False;
  if (aCol = 2) and (aRow >= 1) and (ActionDe(aRow) = 1) then CanSelect := False;
end;

procedure TPanelEquipClasse.GrilleSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: String);
begin
  if aRow < 1 then Exit;
  if aCol = 2 then
    FGrille.Cells[4, aRow] := Value  // texte saisi a la main : nom libre, sans libelle a deduire
  else if aCol = 3 then
    MajLibelleLigne(aRow)
  else if aCol = 5 then
  begin
    if (ActionDe(aRow) = 2) and (Trim(FGrille.Cells[3, aRow]) = '1') then FGrille.Cells[3, aRow] := '';
    if (ActionDe(aRow) = 0) and (Trim(FGrille.Cells[3, aRow]) = '') then FGrille.Cells[3, aRow] := '1';
    MajLibelleLigne(aRow);
  end
  else if aCol = 6 then
  begin
    // la cible se choisit dans la liste : on retrouve son code par le libelle
    FGrille.Cells[7, aRow] := CodeCible(aRow, Value);
    MajLibelleLigne(aRow);
  end;
end;

// Libelles des objets deja donnes a la classe de la ligne par une autre source, avec leurs codes.
procedure TPanelEquipClasse.ListeCibles(R: Integer; Codes, Libelles: TStrings);
var
  I: Integer;
begin
  Codes.Clear;
  Libelles.Clear;
  if not Assigned(FCibles) then Exit;
  FCibles(CodeClasseDe(Trim(FGrille.Cells[0, R])), Codes);
  for I := 0 to Codes.Count - 1 do
    Libelles.Add(FLibEquip(Codes[I], '1'));
end;

function TPanelEquipClasse.CodeCible(R: Integer; const Lib: String): String;
var
  Codes, Libelles: TStringList;
  I: Integer;
begin
  Result := '';
  Codes := TStringList.Create;
  Libelles := TStringList.Create;
  try
    ListeCibles(R, Codes, Libelles);
    I := Libelles.IndexOf(Lib);
    if I >= 0 then Result := Codes[I];
  finally
    Codes.Free;
    Libelles.Free;
  end;
end;

procedure TPanelEquipClasse.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Codes, Libelles: TStringList;
begin
  if aRow < 1 then Exit;
  if aCol = 0 then
  begin
    Editor := FGrille.EditorByStyle(cbsPickList);
    if not (Editor is TCustomComboBox) then Exit;
    TCustomComboBox(Editor).Style := csDropDownList;
    TCustomComboBox(Editor).Items.Assign(FClassesLib);
  end
  else if aCol = 5 then
  begin
    Editor := FGrille.EditorByStyle(cbsPickList);
    if not (Editor is TCustomComboBox) then Exit;
    TCustomComboBox(Editor).Style := csDropDownList;
    TCustomComboBox(Editor).Items.Clear;
    TCustomComboBox(Editor).Items.Add(FActions[0]);
    TCustomComboBox(Editor).Items.Add(FActions[1]);
    TCustomComboBox(Editor).Items.Add(FActions[2]);
  end
  else if (aCol = 6) and (ActionDe(aRow) > 0) then
  begin
    Editor := FGrille.EditorByStyle(cbsPickList);
    if not (Editor is TCustomComboBox) then Exit;
    Codes := TStringList.Create;
    Libelles := TStringList.Create;
    try
      ListeCibles(aRow, Codes, Libelles);
      TCustomComboBox(Editor).Style := csDropDownList;
      TCustomComboBox(Editor).Items.Assign(Libelles);
    finally
      Codes.Free;
      Libelles.Free;
    end;
  end;
end;

procedure TPanelEquipClasse.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Cells[3, R] := '1';
  FGrille.Cells[5, R] := FActions[0];
  // une nouvelle ligne reprend la classe de la precedente : on ajoute le plus souvent a la meme classe
  if R > 1 then FGrille.Cells[0, R] := FGrille.Cells[0, R - 1];
  FGrille.Row := R;
  FGrille.Col := 2;
end;

procedure TPanelEquipClasse.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
end;

// Arme, Armure ou Divers : le code choisi remplace celui de la ligne courante.
procedure TPanelEquipClasse.BoutonChoisirClick(Sender: TObject);
var
  Code: String;
begin
  FGrille.EditorMode := False;
  if (FGrille.Row < 1) or (FGrille.Row >= FGrille.RowCount) or not Assigned(FOnChoisir) then Exit;
  Code := '';
  if ActionDe(FGrille.Row) = 1 then Exit;
  FOnChoisir(TBCButton(Sender).Tag, Code);
  if Code = '' then Exit;
  FGrille.Cells[4, FGrille.Row] := Code;
  MajLibelleLigne(FGrille.Row);
end;

procedure TPanelEquipClasse.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelEquipClasse.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelEquipClasse.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelEquipClasse.GetLectureSeule: Boolean;
begin
  Result := not FBarre.Visible;
end;

procedure TPanelEquipClasse.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
  FBarre2.Visible := not Valeur;
end;

procedure TPanelEquipClasse.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelEquipClasse.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

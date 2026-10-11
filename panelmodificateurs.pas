unit PanelModificateurs;

{$mode ObjFPC}{$H+}

// Grille unique des modificateurs d'un element (talent, qualite...) : une ligne par balise
// Modify* / Modificateur, Type | Cible | Valeur | Option. Types, cibles et options s'affichent par leur
// libelle ; le XML garde les codes. Extraite de winlivre.pas (CONTEXT.md 2.105, e3).
//
// Usage : creer, Initialiser, poser (Parent + SetBounds), Placer(DansQualite), puis Charger(Element) a
// l'ouverture de la fiche et Ecrire(Element) a la validation.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, DOM, BCButton,
  ChargeConstantes, ChargeModificateur, ChargeTexte, ChargeCompetence, UnitCalcul, GlobalFonts;

type
  TFonctionLibelle = function(Code: String): String of object;

  TPanelModificateurs = class(TPanel)
  private
    FLabel: TLabel;
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FDansQualite: Boolean;
    FTypeAvant: String;  // type de la ligne avant le choix dans la liste
    FLibAttribut: TFonctionLibelle;
    FCompLibelles: TStrings;  // competences liees (index 0 = ligne vide), parallele a FCompCodes
    FCompCodes: TStringList;
    FCodesCondition: TStringList;  // conditions (if=) proposees : codes declares par les livres (DATA_CONDITION), fournis par l'appelant
    FFiltreLib, FFiltreCode: TStringList;  // filtres affiches en libelle (RULES-LAB_x) : libelle -> code d'origine
    function  LibFiltre(const Code: String): String;
    function  CodeFiltre(const Lib: String): String;
    function  LibTypeBonus(const Balise: String): String;
    function  CodeTypeBonus(const Lib: String): String;
    function  LibCibleBonus(const Typ, Code: String): String;
    function  CodeCibleBonus(const Typ, Lib: String): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GrilleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GrillePickListSelect(Sender: TObject);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    function  GetLectureSeule: Boolean;
    procedure SetLectureSeule(Valeur: Boolean);
    function  GetNbLignes: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Modele : bouton dont les boutons Ajouter/Retirer copient l'aspect. LibAttribut : libelle d'une
    // caracteristique (RULES-ATTR_x). Libelles/Codes : liste des competences liees (index 0 = ligne vide).
    procedure Initialiser(Modele: TBCButton; ALibAttribut: TFonctionLibelle; Libelles: TStrings; Codes: TStringList);
    // Mise en page : la qualite est plus etroite et ne propose pas le tirage aleatoire (afflictions seulement).
    procedure Placer(DansQualite: Boolean);
    procedure Charger(Element: TDOMElement);
    procedure Ecrire(Element: TDOMElement);
    // Vrai si chaque ligne a une valeur utile ; sinon message nommant la ligne (a appeler avant Ecrire).
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;  // contenu des cellules, pour detecter une modification
    // codes des conditions proposees dans la colonne Condition (liste detenue par l'appelant, jamais liberee ici)
    property  CodesCondition: TStringList read FCodesCondition write FCodesCondition;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
    property  NbLignes: Integer read GetNbLignes;  // sans l'en-tete
  end;

// Le XML stocke ses valeurs sous la forme "1" ou "Agitator", guillemets compris.
// Meme convention que XmlExportImport, qui fait RemoveQuotes(UTF8Encode(...)).
function ValeurXML(Node: TDOMNode): String;
// Remplace le contenu texte d'un noeud XML en gardant la convention des guillemets (symetrique de ValeurXML).
procedure EcrireValeurXML(Element: TDOMElement; Valeur: String);
// Categorie de degats (cible de ModifyDamage) : libelle du code CC/CT ; autre code laisse tel quel.
function LibCategorieDegat(const Code: String): String;

implementation

const
  // caracteristiques proposees comme cible d'un bonus
  CodesCaracBonus: array[0..14] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel',
    'Fate', 'Resil', 'Wound', 'Supp', 'Move');
  // emplacements d'armure proposes comme cible d'une protection (ModifArmour)
  CodesEmplacementBonus: array[0..3] of String = (BonusTete, BonusBras, BonusCorps, BonusJambes);  // "Tous les emplacements"
  // choix proposes pour une protection : les quatre pieces d'armure + le bouclier (jamais dans "Tous")
  CodesEmplacementChoix: array[0..4] of String = (BonusTete, BonusBras, BonusCorps, BonusJambes, BonusBouclier);

function ValeurXML(Node: TDOMNode): String;
begin
  Result := '';
  if Node = nil then Exit;

  Result := RemoveQuotes(Trim(Node.TextContent));
end;

procedure EcrireValeurXML(Element: TDOMElement; Valeur: String);
begin
  while Element.FirstChild <> nil do
    Element.RemoveChild(Element.FirstChild);
  Element.AppendChild(Element.OwnerDocument.CreateTextNode('"' + Valeur + '"'));
end;

function LibCategorieDegat(const Code: String): String;
begin
  if Code = ConstCibleModifieDegatCC then
    Result := GetTexteLibelle('RULES-LAB_469')
  else if Code = ConstCibleModifieDegatCT then
    Result := GetTexteLibelle('RULES-LAB_470')
  else if Code = ConstCibleModifieDegatSort then
    Result := GetTexteLibelle('RULES-LAB_680')
  else
    Result := Code;
end;

// Types, natures de cible et libelles viennent de la table unique TypesEffet (chargemodificateur.pas).
function EstTypeBonus(const Nom: String): Boolean;
begin
  Result := IndiceTypeEffet(Nom) >= 0;
end;

function NatureTypeBonus(const Typ: String): NatureCibleModif;
var
  I: Integer;
begin
  I := IndiceTypeEffet(Typ);
  if I < 0 then Exit(ncLibre);
  Result := TypesEffet[I].Nature;
end;

function EstTypeCarac(const Typ: String): Boolean;
begin
  Result := NatureTypeBonus(Typ) = ncCarac;
end;

function EstTypeCompetence(const Typ: String): Boolean;
begin
  Result := NatureTypeBonus(Typ) = ncCompetence;
end;

function EstTypeDegat(const Typ: String): Boolean;
begin
  Result := NatureTypeBonus(Typ) = ncDegat;
end;

function EstTypeEmplacement(const Typ: String): Boolean;
begin
  Result := NatureTypeBonus(Typ) = ncEmplacement;
end;

// Choix de saisie seulement, jamais ecrit tel quel : voir Ecrire.
function LibTousEmplacements: String;
begin
  Result := GetTexteLibelle('RULES-LAB_471');
end;

// Specialisations d'une competence de base (lien <Generique>) : libelles dans Libs, codes dans Codes.
procedure SpecialitesDe(const CodeBase: String; Libs: TStrings; Codes: TStringList);
var
  I: Integer;
begin
  Libs.Clear;
  Codes.Clear;
  if (CodeBase = '') or (ListCompetence = nil) then Exit;
  for I := 0 to ListCompetence.Count - 1 do
    if ListCompetence[I].SousCompetence and (ListCompetence[I].CodeGenerique = CodeBase) then
    begin
      Libs.Add(ListCompetence[I].Libelle);
      Codes.Add(ListCompetence[I].CodeCompetence);
    end;
end;

// Code de la specialisation de libelle Lib sous la competence CodeBase ; CodeBase si elle n'existe pas.
function CodeSpecialiteBonus(const CodeBase, Lib: String): String;
var
  Libs, Codes: TStringList;
  I: Integer;
begin
  Result := CodeBase;
  Libs := TStringList.Create;
  Codes := TStringList.Create;
  try
    SpecialitesDe(CodeBase, Libs, Codes);
    I := Libs.IndexOf(Lib);
    if I >= 0 then Result := Codes[I];
  finally
    Libs.Free;
    Codes.Free;
  end;
end;

{ TPanelModificateurs }

constructor TPanelModificateurs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFiltreLib := TStringList.Create;
  FFiltreCode := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FLabel := TLabelContour.Create(Self);
  FLabel.Parent := Self;
  FLabel.Align := alTop;
  FLabel.Height := 22;
  FLabel.Caption := GetTexteLibelle('RULES-LAB_415');
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alBottom;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Bottom := 6;
  FGrille.ColCount := 5;  // Type, Cible, Valeur, Option, Condition (filtre if=)
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing, goRowSelect] - [goRangeSelect];
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_416');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_417');
  FGrille.Cells[2, 0] := GetTexteLibelle('RULES-LAB_418');
  FGrille.Cells[3, 0] := GetTexteLibelle('RULES-LAB_419');
  FGrille.Cells[4, 0] := GetTexteLibelle('RULES-LAB_472');
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  FGrille.ShowHint := True;
  FGrille.OnMouseMove := @GrilleMouseMove;
  FGrille.OnPickListSelect := @GrillePickListSelect;
  Visible := False;
end;

destructor TPanelModificateurs.Destroy;
begin
  FFiltreLib.Free;
  FFiltreCode.Free;
  inherited Destroy;
end;

// Filtre <if=> : code de libelle affiche en libelle ; le code d'origine est retenu pour l'ecriture.
function TPanelModificateurs.LibFiltre(const Code: String): String;
begin
  Result := Code;
  if Code = '' then Exit;
  // le libelle du livre ouvert d'abord (une condition creee en WinLivre n'est pas encore dans le magasin global)
  if Assigned(FLibAttribut) then Result := FLibAttribut(Code) else Result := GetTexteLibelle(Code, Code);
  if (Result <> Code) and (FFiltreLib.IndexOf(Result) < 0) then
  begin
    FFiltreLib.Add(Result);
    FFiltreCode.Add(Code);
  end;
end;

function TPanelModificateurs.CodeFiltre(const Lib: String): String;
var
  I: Integer;
begin
  Result := Lib;
  I := FFiltreLib.IndexOf(Lib);
  if I >= 0 then Result := FFiltreCode[I];
end;

procedure TPanelModificateurs.Initialiser(Modele: TBCButton; ALibAttribut: TFonctionLibelle; Libelles: TStrings; Codes: TStringList);
begin
  FLibAttribut := ALibAttribut;
  FCompLibelles := Libelles;
  FCompCodes := Codes;
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.Caption := GetTexteLibelle('RULES-LAB_420');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.Caption := GetTexteLibelle('RULES-LAB_421');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  // MiseEnFormeDesChamp(fiche) ne style que les composants dont la fiche est proprietaire : ceux du
  // panneau lui appartiennent, il faut donc appliquer la meme mise en forme (police, couleurs, boutons).
  MiseAJourUnContenaire(Self);
  Placer(False);
end;

procedure TPanelModificateurs.Placer(DansQualite: Boolean);
begin
  FDansQualite := DansQualite;
  if DansQualite then
  begin
    FGrille.ColWidths[0] := 140;
    FGrille.ColWidths[1] := 100;
    FGrille.ColWidths[2] := 50;
    FGrille.ColWidths[3] := 110;
    FGrille.ColWidths[4] := 150;
    FBarre.Height := 32;
    FBoutonAjouter.SetBounds(0, 0, 200, 32);
    FBoutonRetirer.SetBounds(210, 0, 200, 32);
  end
  else
  begin
    FGrille.ColWidths[0] := 170;
    FGrille.ColWidths[1] := 230;
    FGrille.ColWidths[2] := 80;
    FGrille.ColWidths[3] := 170;
    FGrille.ColWidths[4] := 170;
    FBarre.Height := 50;
    FBoutonAjouter.SetBounds(0, 0, 230, 50);
    FBoutonRetirer.SetBounds(240, 0, 250, 50);
  end;
end;

function TPanelModificateurs.GetLectureSeule: Boolean;
begin
  Result := not (goEditing in FGrille.Options);
end;

// En lecture : grille non modifiable, sans boutons, et masquee si l'element ne porte aucun modificateur.
procedure TPanelModificateurs.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
  begin
    FGrille.Options := FGrille.Options - [goEditing];
    FBarre.Visible := False;
    if FGrille.RowCount <= 1 then Visible := False;
  end
  else
  begin
    FGrille.Options := FGrille.Options + [goEditing];
    FBarre.Visible := True;
  end;
end;

function TPanelModificateurs.GetNbLignes: Integer;
begin
  Result := FGrille.RowCount - 1;
end;

procedure TPanelModificateurs.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelModificateurs.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

function TPanelModificateurs.LibTypeBonus(const Balise: String): String;
var
  I: Integer;
begin
  Result := Balise;
  I := IndiceTypeEffet(Balise);
  if I >= 0 then Result := GetTexteLibelle(TypesEffet[I].CodeLibelle);
end;

// Le format generique <Modificateur> n'est pas un type a part : la grille propose les types de la table.
function TPanelModificateurs.CodeTypeBonus(const Lib: String): String;
var
  I: Integer;
begin
  Result := Lib;
  for I := 0 to NbTypesEffet - 1 do
    if (TypesEffet[I].Balise <> ConstXmlModificateur) and (GetTexteLibelle(TypesEffet[I].CodeLibelle) = Lib) then
      Exit(TypesEffet[I].Balise);
end;

// Code -> libelle : caracteristique pour les types de caracteristique, competence liee pour les types de
// competence ; tout autre cas (arme, degats, armure...) reste en saisie libre.
function TPanelModificateurs.LibCibleBonus(const Typ, Code: String): String;
var
  I: Integer;
begin
  Result := Code;
  if Code = '' then Exit;
  if EstTypeCarac(Typ) and (Pos('RULES-ATTR_', Code) = 1) then
    Result := FLibAttribut(Code)
  else if EstTypeDegat(Typ) then
    Result := LibCategorieDegat(Code)
  else if EstTypeEmplacement(Typ) then
    Result := GetTexteLibelle(Code, Code)
  else if EstTypeCompetence(Typ) or (Typ = ConstXmlModifieArme) then
  begin
    I := FCompCodes.IndexOf(Code);
    if I > 0 then
      Result := FCompLibelles[I]
    else
      Result := LibCategorieDegat(Code);  // CC / CT : categorie de competence, meme libelle que pour les degats
  end;
end;

function TPanelModificateurs.CodeCibleBonus(const Typ, Lib: String): String;
var
  I: Integer;
begin
  Result := Lib;
  if Lib = '' then Exit;
  if EstTypeCarac(Typ) then
  begin
    for I := 0 to High(CodesCaracBonus) do
      if FLibAttribut('RULES-ATTR_' + CodesCaracBonus[I]) = Lib then Exit('RULES-ATTR_' + CodesCaracBonus[I]);
  end
  else if EstTypeDegat(Typ) then
  begin
    if Lib = LibCategorieDegat(ConstCibleModifieDegatCC) then Exit(ConstCibleModifieDegatCC);
    if Lib = LibCategorieDegat(ConstCibleModifieDegatCT) then Exit(ConstCibleModifieDegatCT);
    if Lib = LibCategorieDegat(ConstCibleModifieDegatSort) then Exit(ConstCibleModifieDegatSort);
  end
  else if EstTypeEmplacement(Typ) then
  begin
    for I := 0 to High(CodesEmplacementChoix) do
      if GetTexteLibelle(CodesEmplacementChoix[I], CodesEmplacementChoix[I]) = Lib then Exit(CodesEmplacementChoix[I]);
  end
  else if EstTypeCompetence(Typ) or (Typ = ConstXmlModifieArme) then
  begin
    I := FCompLibelles.IndexOf(Lib);
    if I > 0 then
      Result := FCompCodes[I]
    else if Lib = LibCategorieDegat(ConstCibleModifieDegatCC) then
      Result := ConstCibleModifieDegatCC
    else if Lib = LibCategorieDegat(ConstCibleModifieDegatCT) then
      Result := ConstCibleModifieDegatCT;
  end;
end;

// Une ligne par bonus/malus de l'element : Type | Cible | Valeur | Filtre. Les deux formats se lisent :
// <ModifyX name="Cible" [skill="Filtre" | if="Filtre"]>Valeur</ModifyX> et
// <Modificateur Type="ModifyX" Cible Facteur="Valeur" [Filtre]/>. Une cible imposee (type ncFixe) reste vide.
procedure TPanelModificateurs.Charger(Element: TDOMElement);
var
  Noeud: TDOMNode;
  E: TDOMElement;
  R: Integer;
  Typ, Cible, Valeur, Filtre, Specialite: String;
  Comp: StructureCompetence;
begin
  FGrille.RowCount := 1;
  Noeud := Element.FirstChild;
  while Noeud <> nil do
  begin
    if (Noeud.NodeType = ELEMENT_NODE) and EstTypeBonus(Noeud.NodeName) then
    begin
      E := TDOMElement(Noeud);
      if E.NodeName = ConstXmlModificateur then
      begin
        Typ := E.GetAttribute(ConstXmlType);
        Cible := E.GetAttribute(ConstXmlEffetCible);
        Valeur := E.GetAttribute(ConstXmlEffetFacteur);
        Filtre := E.GetAttribute(ConstXmlModificateurFiltre);
      end
      else
      begin
        Typ := E.NodeName;
        Cible := E.GetAttribute(ConstXmlData);
        Valeur := ValeurXML(E);
        Filtre := E.GetAttribute(ConstXmlModifieArmeCompetence);
        if Filtre = '' then Filtre := E.GetAttribute('if');
      end;
      R := FGrille.RowCount;
      FGrille.RowCount := R + 1;
      FGrille.Cells[0, R] := LibTypeBonus(Typ);
      if NatureTypeBonus(Typ) = ncFixe then Cible := '';
      Specialite := '';
      if EstTypeCompetence(Typ) and (Cible <> '') then
      begin
        Comp := ChercheCompetence(Cible);
        if Comp.SousCompetence and (Comp.CodeGenerique <> '') then
        begin
          Specialite := Comp.Libelle;  // la cible est une specialisation : base en Cible, specialite en Option
          Cible := Comp.CodeGenerique;
        end;
      end;
      FGrille.Cells[1, R] := LibCibleBonus(Typ, Cible);
      FGrille.Cells[2, R] := Valeur;
      // Option : specialite (competence) ou competence filtrant ModifyWeapon ; Condition : le if= (libelle)
      FGrille.Cells[3, R] := '';
      FGrille.Cells[4, R] := '';
      if EstTypeCompetence(Typ) then
      begin
        FGrille.Cells[3, R] := Specialite;
        FGrille.Cells[4, R] := LibFiltre(Filtre);
      end
      else if Typ = ConstXmlModifieArme then
        FGrille.Cells[3, R] := LibCibleBonus(Typ, Filtre)
      else
        FGrille.Cells[4, R] := LibFiltre(Filtre);
    end;
    Noeud := Noeud.NextSibling;
  end;
  Visible := True;
  FBarre.Visible := True;
end;

function TPanelModificateurs.Controler: Boolean;
var
  R, I: Integer;
  Typ, Valeur: String;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    Typ := CodeTypeBonus(Trim(FGrille.Cells[0, R]));
    I := IndiceTypeEffet(Typ);
    if I < 0 then Continue;
    // cible obligatoire, sauf les types a cible imposee : Ecrire ignorerait la ligne en silence
    if (TypesEffet[I].Nature <> ncFixe) and (CodeCibleBonus(Typ, Trim(FGrille.Cells[1, R])) = '') then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_478'), [R]));
      Result := False;
      Exit;
    end;
    if not TypesEffet[I].ValeurNonNulle then Continue;
    Valeur := Trim(FGrille.Cells[2, R]);
    // mots-cles du moteur sur les competences de talent (Bonus, ChooseDice) : pas des nombres
    if (Typ = ConstXmlModifieCompetence) and ((Valeur = ConstCompetenceBonus) or (Valeur = ConstCompetenceInverseDe)) then Continue;
    // une valeur nulle est admise sur une ligne a condition (colonne 4, information) et sur ModifyWeapon (filtre en Option)
    if (StrToIntDef(Valeur, MaxInt) = MaxInt)
      or ((StrToInt(Valeur) = 0) and (Trim(FGrille.Cells[4, R]) = '') and (Typ <> ConstXmlModifieArme)) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_477'), [R]));
      Result := False;
      Exit;
    end;
  end;
end;

// Remplace les bonus de l'element par les lignes de la grille (les autres balises ne sont pas touchees).
// Format : celui que decide EcritureGenerique (le meme que l'export), valeur non numerique toujours en balise historique.
procedure TPanelModificateurs.Ecrire(Element: TDOMElement);
var
  Noeud, Suivant: TDOMNode;
  E: TDOMElement;
  R, I, K, NbCibles: Integer;
  Typ, Cible, Valeur, Filtre: String;
begin
  Noeud := Element.FirstChild;
  while Noeud <> nil do
  begin
    Suivant := Noeud.NextSibling;
    if (Noeud.NodeType = ELEMENT_NODE) and EstTypeBonus(Noeud.NodeName) then
      Element.RemoveChild(Noeud);
    Noeud := Suivant;
  end;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    Typ := CodeTypeBonus(Trim(FGrille.Cells[0, R]));
    I := IndiceTypeEffet(Typ);
    if I < 0 then Continue;
    if TypesEffet[I].Nature = ncFixe then
      Cible := TypesEffet[I].CibleFixe
    else
      Cible := CodeCibleBonus(Typ, Trim(FGrille.Cells[1, R]));
    Valeur := Trim(FGrille.Cells[2, R]);
    Filtre := Trim(FGrille.Cells[3, R]);  // Option
    if Typ = ConstXmlModifieArme then
      Filtre := CodeCibleBonus(Typ, Filtre)  // competence filtrant ModifyWeapon (la Condition n'y est pas prise en compte)
    else if EstTypeCompetence(Typ) then
    begin
      if (Cible <> '') and (Filtre <> '') then Cible := CodeSpecialiteBonus(Cible, Filtre);
      Filtre := CodeFiltre(Trim(FGrille.Cells[4, R]));  // en Option, la specialite n'est pas un filtre : le if= vient de Condition
    end
    else
      Filtre := CodeFiltre(Trim(FGrille.Cells[4, R]));
    if Cible = '' then Continue;  // ligne incomplete : ignoree
    // "Tous les emplacements" est une simplification de saisie : une ligne par emplacement dans le XML
    NbCibles := 1;
    if EstTypeEmplacement(Typ) and (Cible = LibTousEmplacements) then
      NbCibles := Length(CodesEmplacementBonus);
    for K := 0 to NbCibles - 1 do
    begin
      if NbCibles > 1 then Cible := CodesEmplacementBonus[K];
      if EcritureGenerique(Typ, Filtre) and (StrToIntDef(Valeur, MaxInt) <> MaxInt) then
      begin
        E := Element.OwnerDocument.CreateElement(ConstXmlModificateur);
        E.SetAttribute(ConstXmlType, Typ);
        E.SetAttribute(ConstXmlEffetCible, Cible);
        E.SetAttribute(ConstXmlEffetFacteur, Valeur);
        E.SetAttribute(ConstXmlModificateurFiltre, Filtre);
        Element.AppendChild(E);
      end
      else
      begin
        E := Element.OwnerDocument.CreateElement(Typ);
        E.SetAttribute(ConstXmlData, Cible);
        if (Typ = ConstXmlModifieArme) and (Filtre <> '') then E.SetAttribute(ConstXmlModifieArmeCompetence, Filtre);
        Element.AppendChild(E);
        EcrireValeurXML(E, Valeur);
      end;
    end;
  end;
end;

// Bulle au survol : le texte entier d'une cellule que la colonne coupe.
procedure TPanelModificateurs.GrilleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  C, R: Integer;
  Texte: String;
begin
  FGrille.MouseToCell(X, Y, C, R);
  Texte := '';
  if (R >= 1) and (C >= 0) and (FGrille.Canvas.TextWidth(FGrille.Cells[C, R]) > FGrille.ColWidths[C] - 8) then
    Texte := FGrille.Cells[C, R];
  if Texte <> FGrille.Hint then
  begin
    FGrille.Hint := Texte;
    Application.CancelHint;  // sinon la bulle de la cellule precedente reste affichee
  end;
end;

// Type en liste ; cible en liste pour les caracteristiques et les competences, imposee pour les types a cible fixe,
// libre sinon ; filtre en liste de competences pour ModifyWeapon, libre sinon.
procedure TPanelModificateurs.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Typ: String;
  I: Integer;
  Combo: TCustomComboBox;
  Codes: TStringList;
  W: Integer;
begin
  if (aRow < 1) or not (aCol in [0, 1, 3, 4]) then Exit;
  Typ := CodeTypeBonus(FGrille.Cells[0, aRow]);
  if aCol = 0 then FTypeAvant := Typ;  // type avant le choix, pour GrillePickListSelect
  if (aCol = 1) and not (EstTypeCarac(Typ) or EstTypeCompetence(Typ) or EstTypeDegat(Typ) or EstTypeEmplacement(Typ)) then Exit;
  if (aCol = 3) and (Typ <> ConstXmlModifieArme) and not EstTypeCompetence(Typ) then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  Combo := TCustomComboBox(Editor);
  Combo.Style := csDropDownList;
  Combo.Items.Clear;
  if aCol = 0 then
  begin
    for I := 0 to NbTypesEffet - 1 do
      if (TypesEffet[I].Balise <> ConstXmlModificateur)
        and not ((TypesEffet[I].Balise = ConstXmlModifieAttributAleatoire) and FDansQualite) then  // tirage : afflictions seulement
        Combo.Items.Add(LibTypeBonus(TypesEffet[I].Balise));
  end
  else if (aCol = 1) and EstTypeCarac(Typ) then
  begin
    for I := 0 to High(CodesCaracBonus) do
      Combo.Items.Add(FLibAttribut('RULES-ATTR_' + CodesCaracBonus[I]));
  end
  else if (aCol = 1) and EstTypeDegat(Typ) then
  begin
    Combo.Items.Add(LibCategorieDegat(ConstCibleModifieDegatCC));
    Combo.Items.Add(LibCategorieDegat(ConstCibleModifieDegatCT));
    Combo.Items.Add(LibCategorieDegat(ConstCibleModifieDegatSort));
  end
  else if (aCol = 1) and EstTypeEmplacement(Typ) then
  begin
    for I := 0 to High(CodesEmplacementChoix) do
      Combo.Items.Add(GetTexteLibelle(CodesEmplacementChoix[I], CodesEmplacementChoix[I]));
    Combo.Items.Add(LibTousEmplacements);
  end
  else if aCol = 4 then
  begin
    // Condition (if=) : ligne vide = aucune, puis les conditions connues
    Combo.Items.Add('');
    if FCodesCondition <> nil then
      for I := 0 to FCodesCondition.Count - 1 do
        Combo.Items.Add(LibFiltre(FCodesCondition[I]));
    for I := 0 to FFiltreLib.Count - 1 do  // conditions lues dans les livres mais hors liste
      if Combo.Items.IndexOf(FFiltreLib[I]) < 0 then Combo.Items.Add(FFiltreLib[I]);
  end
  else if (aCol = 3) and EstTypeCompetence(Typ) then
  begin
    // Option d'un bonus de competence : les specialisations de la competence choisie en Cible
    Codes := TStringList.Create;
    try
      SpecialitesDe(CodeCibleBonus(Typ, Trim(FGrille.Cells[1, aRow])), Combo.Items, Codes);
      Combo.Items.Insert(0, '');  // ligne vide : la competence entiere
    finally
      Codes.Free;
    end;
  end
  else
    for I := 1 to FCompLibelles.Count - 1 do  // 0 = ligne vide
      Combo.Items.Add(FCompLibelles[I]);
  // la liste deroulante garde la largeur de la colonne : l'elargir au plus long libelle, et montrer
  // toutes les lignes (plafonne) pour qu'on voie ce qu'elle contient
  W := 0;
  for I := 0 to Combo.Items.Count - 1 do
    if FGrille.Canvas.TextWidth(Combo.Items[I]) > W then W := FGrille.Canvas.TextWidth(Combo.Items[I]);
  TComboBox(Combo).ItemWidth := W + 40;
  if Combo.Items.Count > 25 then Combo.DropDownCount := 25 else Combo.DropDownCount := Combo.Items.Count + 1;
end;

// Changer le type d'une ligne remet cible, valeur et option a leur defaut : ils n'ont plus de sens
// pour le nouveau type.
procedure TPanelModificateurs.GrillePickListSelect(Sender: TObject);
var
  R: Integer;
  Typ: String;
begin
  R := FGrille.Row;
  if (R < 1) or (FGrille.Col <> 0) or not (FGrille.Editor is TCustomComboBox) then Exit;
  with TCustomComboBox(FGrille.Editor) do  // ItemIndex : Text peut encore porter l'ancien libelle
    if ItemIndex >= 0 then
      Typ := CodeTypeBonus(Items[ItemIndex])
    else
      Typ := CodeTypeBonus(Text);
  if Typ = FTypeAvant then Exit;  // meme type reselectionne
  FTypeAvant := Typ;  // l'editeur reste ouvert : un second choix part de ce type
  FGrille.Cells[1, R] := '';
  FGrille.Cells[3, R] := '';
  FGrille.Cells[4, R] := '';  // le filtre d'origine n'a plus de sens pour le nouveau type
  if EstTypeDegat(Typ) then
    FGrille.Cells[1, R] := LibCategorieDegat(ConstCibleModifieDegatCC)  // corps a corps par defaut
  else if EstTypeEmplacement(Typ) then
    FGrille.Cells[1, R] := LibTousEmplacements;  // tous les emplacements par defaut
  if EstTypeCarac(Typ) then
    FGrille.Cells[2, R] := '+5'
  else if EstTypeCompetence(Typ) or (Typ = ConstXmlModifieAccuracy) then
    FGrille.Cells[2, R] := '+10'
  else
    FGrille.Cells[2, R] := '+1';
end;

procedure TPanelModificateurs.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  FGrille.Cells[0, R] := LibTypeBonus('ModifyCarac');
  FGrille.Cells[1, R] := '';
  FGrille.Cells[2, R] := '+5';
  FGrille.Cells[3, R] := '';
  FGrille.Cells[4, R] := '';
  FGrille.Row := R;
end;

procedure TPanelModificateurs.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if FGrille.Row >= 1 then
    FGrille.DeleteRow(FGrille.Row);
end;

end.

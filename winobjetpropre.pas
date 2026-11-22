unit WinObjetPropre;

{$mode ObjFPC}{$H+}

// Creation et edition d'un objet PROPRE AU PERSONNAGE (sans livre), depuis WinPersonnage : divers
// (<Trapping>), arme (<Weapon>) ou armure (<Armor>). Reutilise la fiche de WinLivre (TPanelFiche,
// grille des modificateurs, qualites liees) dans une fenetre modale ; l'objet est un element au format
// d'un livre, range dans <CUSTOM_ITEMS> de la fiche du personnage (Personnage.ObjetsPropres) et
// injecte dans les listes par InjecteObjetsPropres.

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, MessageTest, DOM, XMLRead, XMLWrite, BCButton,
  ChargeArmeBonus, ChargeArmureBonus, PanelFiche, PanelModificateurs, PanelQualites, ChargeConstantes, ChargeTexte, ChargeCompetence, GlobalFonts;

// Ouvre la fiche. Balise = Trapping, Weapon, Armor ou BonusMalus (qualite). Fragment = contenu de
// <CUSTOM_ITEMS> : l'element de ce code y est modifie, ou cree s'il n'y est pas. Vrai si l'utilisateur
// valide ; Fragment contient alors l'element et les qualites creees depuis sa fiche.
function SaisirObjetPropre(Modele: TBCButton; const Balise, Code: String; var Fragment: String): Boolean;
// Balise de l'element d'un objet propre (nom de la racine de son XML), '' si illisible.
function BaliseObjetPropre(const Xml: String): String;

// Code libre suivant PERSO-OBJ-<N> dans un contenu de <CUSTOM_ITEMS>.
function CodeObjetPropreSuivant(const Fragment: String): String;
// Fragment dans lequel l'objet Code est remplace par Xml (ajoute s'il n'existait pas).
function ObjetsPropresAvec(const Fragment, Code, Xml: String): String;
// Cree une specialisation propre (<Skill> ou <Talent>) de nom Nom sous le generique Parent et la
// range dans Fragment. Renvoie son code PERSO-<RADICAL>_<hex> ('' si Nom ou Parent est vide).
function AjouteSpecialisationPropre(var Fragment: String; EstTalent: Boolean; const Parent, Nom: String): String;
// Fragment ne gardant que les objets et specialisations dont le code figure dans Utilises, et les
// qualites propres encore citees par l'un d'eux.
function ObjetsPropresUtiles(const Fragment: String; Utilises: TStrings): String;
// Element du fragment portant ce code ('' si absent).
function ObjetPropreXml(const Fragment, Code: String): String;
// Cet element et les qualites propres qu'il cite ('' si le code n'est pas un objet propre).
function ObjetPropreAvecQualites(const Fragment, Code: String): String;

implementation

const
  ThemesTrapping: array[0..12] of String = ('RULES-LAB_190', 'RULES-LAB_191', 'RULES-LAB_192', 'RULES-LAB_193',
    'RULES-LAB_194', 'RULES-LAB_195', 'RULES-LAB_196', 'RULES-LAB_197', 'RULES-LAB_198', 'RULES-LAB_199',
    'RULES-LAB_1020', 'RULES-LAB_1021', 'RULES-LAB_1022');
  DisposEquipement: array[0..4] of String = ('RULES-DISPO_COMMON', 'RULES-DISPO_LIMITED', 'RULES-DISPO_RARE',
    'RULES-DISPO_EXOTIC', 'RULES-DISPO_UNIQUE');

  MateriauxArmure: array[0..7] of String = ('RULES-ARMOT_SOFTLEATHER', 'RULES-ARMOT_LEATHER', 'RULES-ARMOT_BOILLEDLEATHER',
    'RULES-ARMOT_MAIL', 'RULES-ARMOT_PLATE', 'RULES-ARMOT_SOFTKITS', 'RULES-ARMOT_BRIGANDINE', 'RULES-ARMOT_BONE');
  EmplacementsArmure: array[0..3] of String = ('RULES-ARMOL_HEAD', 'RULES-ARMOL_BODY', 'RULES-ARMOL_ARM', 'RULES-ARMOL_LEG');
  PorteesCorps: array[0..10] of String = ('PERSO', 'VSHORT', 'CLOSE', 'SHORT', 'AVERAGE', 'MID', 'LONG', 'VLONG', 'BIG', 'HUGE', 'MASSIVE');

type
  TFenetreObjetPropre = class(TForm)
  private
    FFiche:      TPanelFiche;
    FGrille:     TPanelModificateurs;
    FQualites:   TPanelQualitesLiees;
    FQualLib:    TStringList;
    FQualCodes:  TStringList;
    FQualValeur: TStringList;
    FCompLib:    TStringList;
    FCompCodes:  TStringList;
    FDoc:        TXMLDocument;
    FElement:    TDOMElement;
    FResultat:   String;
    FFragment:   String;
    FModele:     TBCButton;
    FBalise:     String;
    function  LibAttribut(Code: String): String;
    function  LibCode(Code: String): String;
    procedure ValiderClick(Sender: TObject);
    procedure AnnulerClick(Sender: TObject);
    procedure NouvelleQualiteClick(Sender: TObject);
    procedure ModifierQualiteClick(Sender: TObject);
    procedure RemplirQualites(Arme: Boolean);
    procedure DefinirChamps(const Balise: String);
  public
    constructor CreateObjet(AOwner: TComponent; Modele: TBCButton; const Balise, Code, Fragment: String);
    destructor Destroy; override;
    property Resultat: String read FResultat;
    property Fragment: String read FFragment;
  end;

function XmlDeNoeud(Noeud: TDOMNode): String;
var
  Flux: TStringStream;
begin
  Flux := TStringStream.Create('');
  try
    WriteXML(Noeud, Flux);
    Result := Trim(Flux.DataString);
  finally
    Flux.Free;
  end;
end;

function BaliseObjetPropre(const Xml: String): String;
var
  I: Integer;
  S: String;
begin
  S := TrimLeft(Xml);
  Result := '';
  if (S = '') or (S[1] <> '<') then Exit;
  I := 2;
  while (I <= Length(S)) and not (S[I] in [' ', '>', '/', #9, #10, #13]) do Inc(I);
  Result := Copy(S, 2, I - 2);
end;

// Document dont la racine <CUSTOM_ITEMS> contient le fragment.
function LireFragment(const Fragment: String): TXMLDocument;
var
  Flux: TStringStream;
begin
  Result := nil;
  Flux := TStringStream.Create('<' + ConstXmlObjetsPropres + '>' + Fragment + '</' + ConstXmlObjetsPropres + '>');
  try
    ReadXMLFile(Result, Flux);
  finally
    Flux.Free;
  end;
end;

function ReecrireFragment(Racine: TDOMNode): String;
var
  Noeud: TDOMNode;
begin
  Result := '';
  Noeud := Racine.FirstChild;
  while Noeud <> nil do
  begin
    if Noeud.NodeType = ELEMENT_NODE then
      Result := Result + XmlDeNoeud(Noeud) + LineEnding;
    Noeud := Noeud.NextSibling;
  end;
  Result := Trim(Result);
end;

function CodeSuivant(const Fragment, Prefixe: String): String;
var
  Guid: TGUID;
begin
  // Code unique (et non plus un compteur par fiche) : deux fiches en memoire, par exemple les
  // membres d'un groupe dont les objets sont poses sur un bien commun, ne se telescopent plus.
  // Fragment reste pour ne pas changer la signature.
  CreateGUID(Guid);
  Result := Prefixe + Copy(StringReplace(GUIDToString(Guid), '-', '', [rfReplaceAll]), 2, 12);
end;

function CodeObjetPropreSuivant(const Fragment: String): String;
begin
  Result := CodeSuivant(Fragment, ConstPrefixeObjetPropre);
end;

function ObjetsPropresAvec(const Fragment, Code, Xml: String): String;
var
  Doc, DocNouveau: TXMLDocument;
  Noeud, Suivant, Copie: TDOMNode;
begin
  Doc := LireFragment(Fragment);
  DocNouveau := LireFragment(Xml);
  try
    Noeud := Doc.DocumentElement.FirstChild;
    while Noeud <> nil do
    begin
      Suivant := Noeud.NextSibling;
      if (Noeud.NodeType = ELEMENT_NODE) and (TDOMElement(Noeud).GetAttribute('id') = Code) then
        Doc.DocumentElement.RemoveChild(Noeud);
      Noeud := Suivant;
    end;
    Copie := Doc.ImportNode(DocNouveau.DocumentElement.FirstChild, True);
    Doc.DocumentElement.AppendChild(Copie);
    Result := ReecrireFragment(Doc.DocumentElement);
  finally
    DocNouveau.Free;
    Doc.Free;
  end;
end;

function AjouteSpecialisationPropre(var Fragment: String; EstTalent: Boolean; const Parent, Nom: String): String;
var
  Radical, Balise, Echappe: String;
  P: Integer;
begin
  Result := '';
  if (Trim(Nom) = '') or (Parent = '') then Exit;
  // radical du parent sans prefixe de livre : RULES-COMPLORE_* -> COMPLORE (comparaison de AjouteLigne)
  Radical := Parent;
  P := Pos('-', Radical);
  if P > 0 then Radical := Copy(Radical, P + 1, Length(Radical));
  // un nom de talent contient des '_' (RULES-T_BLESS_* -> T_BLESS) : on retire le '_*' final de la generique
  if (Length(Radical) > 2) and (Copy(Radical, Length(Radical) - 1, 2) = '_*') then
    Radical := Copy(Radical, 1, Length(Radical) - 2)
  else
    begin
      P := Pos('_', Radical);
      if P > 0 then Radical := Copy(Radical, 1, P - 1);
    end;
  Result := CodeSuivant(Fragment, 'PERSO-' + Radical + '_');
  if EstTalent then Balise := 'Talent' else Balise := 'Skill';
  Echappe := StringReplace(Trim(Nom), '&', '&amp;', [rfReplaceAll]);
  Echappe := StringReplace(Echappe, '<', '&lt;', [rfReplaceAll]);
  Echappe := StringReplace(Echappe, '>', '&gt;', [rfReplaceAll]);
  Echappe := StringReplace(Echappe, '"', '&quot;', [rfReplaceAll]);
  Fragment := ObjetsPropresAvec(Fragment, Result,
    '<' + Balise + ' id="' + Result + '"><Description language="English">' + Echappe +
    '</Description><Generique>' + Parent + '</Generique></' + Balise + '>');
end;

function EstQualitePropre(const Id: String): Boolean;
begin
  Result := (Pos(ConstPrefixeQualiteArme, Id) = 1) or (Pos(ConstPrefixeQualiteArmure, Id) = 1);
end;

function ObjetsPropresUtiles(const Fragment: String; Utilises: TStrings): String;
var
  Doc: TXMLDocument;
  Noeud, Suivant: TDOMNode;
  Citees: TStringList;
  Id: String;
begin
  Result := '';
  if Trim(Fragment) = '' then Exit;
  Doc := LireFragment(Fragment);
  Citees := TStringList.Create;
  try
    // 1) les objets sans ligne d'equipement partent ; les qualites propres restent pour l'instant
    Noeud := Doc.DocumentElement.FirstChild;
    while Noeud <> nil do
    begin
      Suivant := Noeud.NextSibling;
      if Noeud.NodeType = ELEMENT_NODE then
      begin
        Id := TDOMElement(Noeud).GetAttribute('id');
        // une specialisation propre (<Skill>/<Talent>) se retient par son code de competence ou de
        // talent, un objet par sa ligne d'equipement : les deux partent s'ils ne servent a rien
        if not EstQualitePropre(Id) and (Utilises.IndexOf(Id) < 0) then
          Doc.DocumentElement.RemoveChild(Noeud);
      end;
      Noeud := Suivant;
    end;
    // 2) codes cites par les <Quality> des armes et armures restantes ("A 2,B", "A 2/B 3")
    Noeud := Doc.DocumentElement.FirstChild;
    while Noeud <> nil do
    begin
      if (Noeud.NodeType = ELEMENT_NODE) and (Noeud.FindNode('Quality') <> nil) then
        Citees.CommaText := StringReplace(StringReplace(ValeurXML(Noeud.FindNode('Quality')), '/', ',', [rfReplaceAll]), ' ', ',', [rfReplaceAll]) + ',' + Citees.CommaText;
      Noeud := Noeud.NextSibling;
    end;
    // 3) les qualites propres que plus rien ne cite partent
    Noeud := Doc.DocumentElement.FirstChild;
    while Noeud <> nil do
    begin
      Suivant := Noeud.NextSibling;
      if (Noeud.NodeType = ELEMENT_NODE) and EstQualitePropre(TDOMElement(Noeud).GetAttribute('id'))
         and (Citees.IndexOf(TDOMElement(Noeud).GetAttribute('id')) < 0) then
        Doc.DocumentElement.RemoveChild(Noeud);
      Noeud := Suivant;
    end;
    Result := ReecrireFragment(Doc.DocumentElement);
  finally
    Citees.Free;
    Doc.Free;
  end;
end;

function ObjetPropreXml(const Fragment, Code: String): String;
var
  Doc: TXMLDocument;
  Noeud: TDOMNode;
begin
  Result := '';
  if Trim(Fragment) = '' then Exit;
  Doc := LireFragment(Fragment);
  try
    Noeud := Doc.DocumentElement.FirstChild;
    while Noeud <> nil do
    begin
      if (Noeud.NodeType = ELEMENT_NODE) and (TDOMElement(Noeud).GetAttribute('id') = Code) then
      begin
        Result := XmlDeNoeud(Noeud);
        Exit;
      end;
      Noeud := Noeud.NextSibling;
    end;
  finally
    Doc.Free;
  end;
end;

// L'element de code Code et les qualites propres qu'il cite, prets a etre recopies dans la
// fiche d'un autre personnage (don d'un objet). Vide si Code n'est pas un objet propre.
function ObjetPropreAvecQualites(const Fragment, Code: String): String;
var
  Doc: TXMLDocument;
  Noeud, Objet: TDOMNode;
  Citees: TStringList;
begin
  Result := '';
  if Trim(Fragment) = '' then Exit;
  Doc := LireFragment(Fragment);
  Citees := TStringList.Create;
  try
    Objet := nil;
    Noeud := Doc.DocumentElement.FirstChild;
    while (Noeud <> nil) and (Objet = nil) do
    begin
      if (Noeud.NodeType = ELEMENT_NODE) and (TDOMElement(Noeud).GetAttribute('id') = Code) then
        Objet := Noeud;
      Noeud := Noeud.NextSibling;
    end;
    if Objet = nil then Exit;
    Result := XmlDeNoeud(Objet);
    if Objet.FindNode('Quality') <> nil then
      Citees.CommaText := StringReplace(StringReplace(ValeurXML(Objet.FindNode('Quality')), '/', ',', [rfReplaceAll]), ' ', ',', [rfReplaceAll]);
    Noeud := Doc.DocumentElement.FirstChild;
    while Noeud <> nil do
    begin
      if (Noeud.NodeType = ELEMENT_NODE) and EstQualitePropre(TDOMElement(Noeud).GetAttribute('id'))
         and (Citees.IndexOf(TDOMElement(Noeud).GetAttribute('id')) >= 0) then
        Result := Result + LineEnding + XmlDeNoeud(Noeud);
      Noeud := Noeud.NextSibling;
    end;
  finally
    Citees.Free;
    Doc.Free;
  end;
end;

{ TFenetreObjetPropre }

function TFenetreObjetPropre.LibAttribut(Code: String): String;
begin
  Result := GetTexteLibelle(Code);
end;

function TFenetreObjetPropre.LibCode(Code: String): String;
begin
  Result := GetTexteLibelle(Code);
end;

constructor TFenetreObjetPropre.CreateObjet(AOwner: TComponent; Modele: TBCButton; const Balise, Code, Fragment: String);
var
  I: Integer;
  Tri: TStringList;
  Flux: TStringStream;
  Xml: String;
begin
  inherited CreateNew(AOwner);
  FModele := Modele;
  FBalise := Balise;
  FFragment := Fragment;
  Xml := ObjetPropreXml(Fragment, Code);
  if Balise = 'BonusMalus' then
    Caption := GetTexteLibelle('RULES-LAB_649')
  else
    Caption := GetTexteLibelle('RULES-LAB_647');
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;

  // element a editer : l'existant, ou un <Trapping> vide sous le code donne
  if Trim(Xml) <> '' then
  begin
    Flux := TStringStream.Create(Xml);
    try
      ReadXMLFile(FDoc, Flux);
    finally
      Flux.Free;
    end;
    FElement := FDoc.DocumentElement;
  end
  else
  begin
    FDoc := TXMLDocument.Create;
    FElement := FDoc.CreateElement(Balise);
    FElement.SetAttribute('id', Code);
    FDoc.AppendChild(FElement);
  end;

  // cibles de competence de la grille : les competences de base du jeu, sans les specialisations
  FCompLib := TStringList.Create;
  FCompCodes := TStringList.Create;
  FCompLib.Add('');
  FCompCodes.Add('');
  Tri := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupIgnore;
    if ListCompetence <> nil then
      for I := 0 to ListCompetence.Count - 1 do
        if not ListCompetence[I].SousCompetence then
          Tri.Add(ListCompetence[I].Libelle + #1 + ListCompetence[I].CodeCompetence);
    for I := 0 to Tri.Count - 1 do
    begin
      FCompLib.Add(Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1));
      FCompCodes.Add(Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I])));
    end;
  finally
    Tri.Free;
  end;

  FGrille := TPanelModificateurs.Create(Self);
  FGrille.Parent := Self;
  FGrille.Initialiser(Modele, @LibAttribut, FCompLib, FCompCodes);
  FQualLib := TStringList.Create;
  FQualCodes := TStringList.Create;
  FQualValeur := TStringList.Create;
  if (Balise = 'Weapon') or (Balise = 'Armor') then
  begin
    RemplirQualites(Balise = 'Weapon');
    FQualites := TPanelQualitesLiees.Create(Self);
    FQualites.Parent := Self;
    FQualites.Visible := False;
    FQualites.Initialiser(Modele, FQualLib, FQualCodes);
    FQualites.CodesAvecValeur := FQualValeur;
    FQualites.OnNouvelle := @NouvelleQualiteClick;
    FQualites.OnModifier := @ModifierQualiteClick;
  end;
  FFiche := TPanelFiche.Create(Self);
  FFiche.Parent := Self;
  FFiche.Initialiser(Modele, FGrille, FQualites);
  FFiche.LibelleAttribut := @LibAttribut;
  FFiche.LibelleCode := @LibCode;
  FFiche.OnValider := @ValiderClick;
  FFiche.OnAnnuler := @AnnulerClick;
  DefinirChamps(Balise);
  FFiche.Charger(FElement);
  // mise en forme commune des fenetres (polices, couleurs), puis taille d'apres le contenu :
  // au-dela de l'ecran la fiche defile (Placer limite sa hauteur a celle de la fenetre)
  MiseEnFormeDesChamp(Self);
  ClientWidth := FFiche.Width;
  ClientHeight := FFiche.Height;
  if ClientHeight > Screen.WorkAreaHeight - 100 then
    ClientHeight := Screen.WorkAreaHeight - 100;
  FFiche.Placer(0, 0);
end;

destructor TFenetreObjetPropre.Destroy;
begin
  FCompLib.Free;
  FCompCodes.Free;
  FQualLib.Free;
  FQualCodes.Free;
  FQualValeur.Free;
  FDoc.Free;
  inherited Destroy;
end;

// Bouton Nouvelle qualite : fiche d'une qualite propre, rangee dans le fragment puis proposee dans la liste.
procedure TFenetreObjetPropre.NouvelleQualiteClick(Sender: TObject);
var
  Prefixe, CodeQ, XmlQ, Lib: String;
  Doc: TXMLDocument;
  Flux: TStringStream;
begin
  if FBalise = 'Weapon' then Prefixe := ConstPrefixeQualiteArme else Prefixe := ConstPrefixeQualiteArmure;
  CodeQ := CodeSuivant(FFragment, Prefixe);
  if not SaisirObjetPropre(FModele, 'BonusMalus', CodeQ, FFragment) then Exit;
  XmlQ := ObjetPropreXml(FFragment, CodeQ);
  if XmlQ = '' then Exit;
  Doc := nil;
  Flux := TStringStream.Create(XmlQ);
  try
    ReadXMLFile(Doc, Flux);
    Lib := ValeurXML(Doc.DocumentElement.FindNode('Description'));
    if Lib = '' then Lib := CodeQ;
    if FQualLib.IndexOf(Lib) >= 0 then Lib := Lib + ' (' + CodeQ + ')';
    FQualLib.Add(Lib);
    FQualCodes.Add(CodeQ);
    if ValeurXML(Doc.DocumentElement.FindNode('NeedsValue')) = '1' then FQualValeur.Add(CodeQ);
  finally
    Doc.Free;
    Flux.Free;
  end;
end;

// Bouton Modifier la qualite : rouvre la fiche de la qualite selectionnee si elle est propre au personnage.
// Libelle et case "valeur obligatoire" suivent ; la grille est rechargee pour afficher le nouveau nom.
procedure TFenetreObjetPropre.ModifierQualiteClick(Sender: TObject);
var
  CodeQ, XmlQ, Lib, Texte: String;
  Doc: TXMLDocument;
  Flux: TStringStream;
  I: Integer;
begin
  CodeQ := FQualites.CodeSelectionne;
  if not EstQualitePropre(CodeQ) then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_651'));
    Exit;
  end;
  if not SaisirObjetPropre(FModele, 'BonusMalus', CodeQ, FFragment) then Exit;
  XmlQ := ObjetPropreXml(FFragment, CodeQ);
  if XmlQ = '' then Exit;
  Doc := nil;
  Flux := TStringStream.Create(XmlQ);
  try
    ReadXMLFile(Doc, Flux);
    Lib := ValeurXML(Doc.DocumentElement.FindNode('Description'));
    if Lib = '' then Lib := CodeQ;
    I := FQualCodes.IndexOf(CodeQ);
    if I >= 0 then
    begin
      FQualLib[I] := '';
      if FQualLib.IndexOf(Lib) >= 0 then Lib := Lib + ' (' + CodeQ + ')';
      FQualLib[I] := Lib;
    end;
    I := FQualValeur.IndexOf(CodeQ);
    if ValeurXML(Doc.DocumentElement.FindNode('NeedsValue')) = '1' then
    begin
      if I < 0 then FQualValeur.Add(CodeQ);
    end
    else if I >= 0 then
      FQualValeur.Delete(I);
  finally
    Doc.Free;
    Flux.Free;
  end;
  Texte := FQualites.Texte;
  FQualites.Charger(Texte);
end;

// Qualites proposees : celles des livres charges (listes du jeu), triees par libelle ; un libelle en
// double est suivi de son code. Une qualite alternative declaree ("A/B") est ecartee : la colonne Or
// de la grille la remplace.
procedure TFenetreObjetPropre.RemplirQualites(Arme: Boolean);
var
  Tri: TStringList;
  I: Integer;
  Lib, Code: String;

  procedure Proposer(const ACode, ALib, AValeur: String);
  begin
    if (ACode = '') or (Pos('/', ACode) > 0) then Exit;
    if ALib = '' then Tri.Add(GetTexteLibelle(ACode) + #1 + ACode) else Tri.Add(ALib + #1 + ACode);
    if (AValeur = '1') and (FQualValeur.IndexOf(ACode) < 0) then FQualValeur.Add(ACode);
  end;

begin
  Tri := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupIgnore;
    if Arme then
    begin
      if ListArmeBonus <> nil then
        for I := 0 to ListArmeBonus.Count - 1 do
          Proposer(ListArmeBonus[I].CodeArmeBonus, ListArmeBonus[I].Libelle, ListArmeBonus[I].NeedsValue);
    end
    else if ListArmureBonus <> nil then
      for I := 0 to ListArmureBonus.Count - 1 do
        Proposer(ListArmureBonus[I].CodeArmureBonus, ListArmureBonus[I].Libelle, ListArmureBonus[I].NeedsValue);
    for I := 0 to Tri.Count - 1 do
    begin
      Lib := Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
      Code := Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I]));
      if FQualLib.IndexOf(Lib) >= 0 then Lib := Lib + ' (' + Code + ')';
      FQualLib.Add(Lib);
      FQualCodes.Add(Code);
    end;
  finally
    Tri.Free;
  end;
end;

// Champs de la fiche selon le type d'objet ; memes champs que la fiche du meme element dans WinLivre.
procedure TFenetreObjetPropre.DefinirChamps(const Balise: String);
var
  Themes, Dispos, Materiaux, Emplacements, Groupes, Portees, Code, Lib: String;
  I, P: Integer;
  Tri: TStringList;
begin
  Dispos := '';
  for I := Low(DisposEquipement) to High(DisposEquipement) do
    Dispos := Dispos + '|' + DisposEquipement[I];
  if Balise = 'Weapon' then
  begin
    // groupes de competence : competences de combat ou de tir, hors "(Any)" et choix "A/B"
    Tri := TStringList.Create;
    try
      Tri.Sorted := True;
      Tri.Duplicates := dupIgnore;
      if ListCompetence <> nil then
        for I := 0 to ListCompetence.Count - 1 do
          begin
            // les groupes (Melee (Basic)...) sont des specialisations : pas de filtre SousCompetence
            Code := ListCompetence[I].CodeCompetence;
            if (Pos('-COMP_MELEE__', Code) = 0) and (Pos('-COMP_RANGED__', Code) = 0) then Continue;
            if (Copy(Code, Length(Code), 1) = '*') or (Pos('/', Code) > 0) then Continue;
            Tri.Add(ListCompetence[I].Libelle + #1 + Code);
          end;
      Groupes := '';
      for I := 0 to Tri.Count - 1 do
        Groupes := Groupes + '|' + Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I])) + '=' + Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
    finally
      Tri.Free;
    end;
    // portees : celles de l'edition chargee (un code sans libelle n'en fait pas partie), puis Force x N
    Portees := '';
    for I := Low(PorteesCorps) to High(PorteesCorps) do
    begin
      Code := 'RULES-WEAPR_' + PorteesCorps[I];
      Lib := GetTexteLibelle(Code);
      if Lib = Code then Continue;
      Portees := Portees + '|' + Code + '=' + Lib;
    end;
    for I := 1 to 4 do
    begin
      if I = 1 then Code := '(BATTR_S)' else Code := '(BATTR_S)X' + IntToStr(I);
      Portees := Portees + '|' + Code + '=' + GetTexteLibelle('RULES-LAB_034') + ' ' + GetTexteLibelle('RULES-ATTR_S') + ' x ' + IntToStr(I);
    end;
    FFiche.Definir([
      ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True),
      ChampFiche('Skill', 'RULES-LAB_437', gfCode, False, False, False, False, Copy(Groupes, 2, MaxInt)),
      ChampFiche('Hand', 'RULES-LAB_053', gfListe, False, True, False, False, '0|1|2', cfEntier),
      ChampFiche('Ammunition', 'RULES-LAB_060', gfTexte, False, True, False, False, '', cfEntier),
      ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, True, False, False, '', cfEntier),
      ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix),
      ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, False, True, False, Copy(Dispos, 2, MaxInt)),
      ChampFiche('Reach', 'RULES-LAB_057', gfCodeLibre, False, False, True, False, Copy(Portees, 2, MaxInt)),
      ChampFiche('Damage', 'RULES-LAB_159', gfDegats, True, False, False, False),
      ChampFiche('Quality', 'RULES-LAB_476', gfQualites, False, False, False, False)]);
  end
  else if Balise = 'BonusMalus' then
  begin
    FFiche.Definir([
      ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True),
      ChampFiche('Modifier', 'RULES-LAB_034', gfListe, False, False, True, False, '+|-'),
      ChampFiche('Short', 'RULES-LAB_073', gfTexte, True, False, True),
      ChampFiche('NeedsValue', 'RULES-LAB_495', gfCases, True, False, True, False, '1=' + GetTexteLibelle('RULES-LAB_495')),
      ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True)]);
  end
  else if Balise = 'Armor' then
  begin
    Materiaux := '';
    for I := Low(MateriauxArmure) to High(MateriauxArmure) do
      Materiaux := Materiaux + '|' + MateriauxArmure[I];
    Emplacements := '';
    for I := Low(EmplacementsArmure) to High(EmplacementsArmure) do
      Emplacements := Emplacements + '|' + EmplacementsArmure[I] + '=' + GetTexteLibelle(EmplacementsArmure[I]);
    FFiche.Definir([
      ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
      ChampFiche('ArmorPoint', 'RULES-LAB_076', gfTexte, False, True, False, False, '', cfEntier),
      ChampFiche('Type', 'RULES-LAB_074', gfCode, False, True, False, False, Copy(Materiaux, 2, MaxInt)),
      ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, True, False, False, '', cfEntier),
      ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix),
      ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, False, True, False, Copy(Dispos, 2, MaxInt)),
      ChampFiche('Location', 'RULES-LAB_075', gfCases, False, True, False, False, Copy(Emplacements, 2, MaxInt)),
      ChampFiche('Quality', 'RULES-LAB_476', gfQualites, False, False, False, False)]);
  end
  else
  begin
    Themes := '';
    for I := Low(ThemesTrapping) to High(ThemesTrapping) do
      Themes := Themes + '|' + ThemesTrapping[I];
    FFiche.Definir([
      ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True),
      ChampFiche('Theme', 'RULES-LAB_201', gfCode, False, False, True, False, Copy(Themes, 2, MaxInt)),
      ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix),
      ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, True, False, False, '', cfEntier),
      ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, False, True, False, Copy(Dispos, 2, MaxInt)),
      ChampFiche('Carries', 'RULES-LAB_185', gfTexte, False, False, True, False, '', cfEntier)]);
  end;
end;

procedure TFenetreObjetPropre.ValiderClick(Sender: TObject);
begin
  if not FFiche.Ecrire(FElement, ConstAnglais) then Exit;
  FResultat := XmlDeNoeud(FElement);
  ModalResult := mrOk;
end;

procedure TFenetreObjetPropre.AnnulerClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

function SaisirObjetPropre(Modele: TBCButton; const Balise, Code: String; var Fragment: String): Boolean;
var
  F: TFenetreObjetPropre;
begin
  Result := False;
  F := TFenetreObjetPropre.CreateObjet(Application, Modele, Balise, Code, Fragment);
  try
    if F.ShowModal = mrOk then
    begin
      Fragment := ObjetsPropresAvec(F.Fragment, Code, F.Resultat);
      Result := True;
    end;
  finally
    F.Free;
  end;
end;

end.

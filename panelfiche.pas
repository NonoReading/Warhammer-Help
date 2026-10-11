unit PanelFiche;

{$mode ObjFPC}{$H+}

// Fiche unique d'un element du livre : en haut les champs PROPRES a l'element (liste de champs fournie
// par l'appelant : balise XML, libelle, genre), en bas la grille des modificateurs (TPanelModificateurs,
// la meme partout) et, pour les elements qui en portent, la liste des qualites liees (TPanelQualitesLiees)
// a sa droite, puis Valider / Annuler. Le panneau fait seul le dessin, la lecture du XML, l'ecriture
// (controle, creation des balises manquantes) et la signature qui detecte une modification.
// Un nouveau type d'element = une nouvelle liste de champs, jamais un nouvel ecran.
//
// Usage : creer, Initialiser (une fois), Definir(champs), poser (Parent, Left, Top), Charger(Element) a
// l'ouverture, Ecrire(Element, Langue) a la validation.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, CheckLst, Forms, Dialogs, DOM, BCButton,
  ChargeTexte, PanelModificateurs, PanelQualites, GlobalFonts;

type
  // appelee quand l'utilisateur change un champ liste fermee (gfCode) : Balise = balise du champ
  TChangementChampFiche = procedure(const Balise: String) of object;
  // controle propre a un type d'element, appele avant l'ecriture : False (apres son propre message) refuse Valider
  TControleFiche = function: Boolean of object;

  // gfListe      : liste deroulante, saisie libre permise (Choix = valeurs separees par |)
  // gfCode       : liste fermee, le XML garde le code et la liste montre son libelle
  // gfCodeLibre  : comme gfCode, mais une saisie hors liste est gardee telle quelle
  //                (Choix = "code" ou "code=libelle" separes par | ; sans libelle, LibelleCode le fournit)
  // gfDegats     : formule de degats "+(BATTR_S)+4" saisie en deux champs (bonus d'attribut, valeur fixe)
  // gfCases      : cases a cocher, plusieurs codes ecrits separes par une virgule (Choix = "code=libelle|...")
  // gfQualites   : liste des qualites liees (pas de champ en haut : bloc a droite de la grille)
  GenreChampFiche = (gfTexte, gfMemo, gfListe, gfCode, gfCodeLibre, gfDegats, gfQualites, gfCases);
  // controle de saisie du texte (applique si le champ n'est pas vide)
  ControleChampFiche = (cfAucun, cfEntier, cfPrix);

  StructureChampFiche = record
    Balise:      String;   // balise XML de l'element
    CodeLibelle: String;   // libelle affiche (RULES-LAB_x)
    Genre:       GenreChampFiche;
    Pleine:      Boolean;  // pleine largeur (sinon deux champs par ligne)
    Obligatoire: Boolean;  // refuse la validation si vide
    Facultatif:  Boolean;  // balise non creee si vide
    AvecLangue:  Boolean;  // attribut language sur la balise creee
    Choix:       String;
    Controle:    ControleChampFiche;
    Virtuel:     Boolean;  // affiche mais jamais ecrit dans l'element (l'appelant le range ailleurs)
  end;

  // Bloc propre a un type d'element, glisse sous les champs (apres la grille) : les effets d'un signe astral.
  // Charge, controle et ecrit en meme temps que la fiche ; les descendants sont dans leur propre unite.
  TPanelExtraFiche = class(TPanel)
  public
    procedure Charger(Element: TDOMElement); virtual; abstract;
    function  Controler: Boolean; virtual; abstract;
    procedure Ecrire(Element: TDOMElement); virtual; abstract;
    function  Signature(const Sep: String): String; virtual; abstract;
    procedure MettreLectureSeule(Valeur: Boolean); virtual; abstract;
  end;

  TPanelFiche = class(TPanel)
  private
    FChamps: array of StructureChampFiche;
    FEtiquettes, FEtiquettes2: array of TLabel;
    FSaisies, FSaisies2: array of TWinControl;  // FSaisies2 : valeur fixe des degats
    FOrigine: array of String;  // gfListe : valeur XML chargee (reecrite telle quelle si le texte affiche n'a pas change)
    FCodes: array of TStringList;  // gfCode/gfCodeLibre/gfDegats : code de chaque entree de la liste
    FIdxQual: Integer;             // indice du champ gfQualites, -1 si aucun
    FLibelleCode, FLibelleAttribut: TFonctionLibelle;
    FDefil: TScrollBox;  // tout le contenu : la fiche defile si la fenetre est trop basse
    FHauteurContenu: Integer;
    FGrille: TPanelModificateurs;
    FQualites: TPanelQualitesLiees;
    FExtra: TPanelExtraFiche;  // bloc facultatif sous la grille ; remis a nil par chaque Definir
    FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FOnChangementChamp: TChangementChampFiche;
    FOnControler: TControleFiche;
    FChargement: Boolean;  // vrai pendant Charger : les changements de liste ne sont pas ceux de l'utilisateur
    FYGrille: Integer;
    FHauteurPleine: Integer;  // hauteur avec Valider/Annuler (la lecture seule les retire)
    FLectureSeule: Boolean;
    FBaliseLibre: String;  // champ de cases reste modifiable dans une lecture seule partielle
    FSansGrille: Boolean;  // element sans modificateurs : la grille n'est ni montree ni ecrite
    FVerrous: String;      // codes de cases qu'on ne peut pas decocher, separes par des virgules
    procedure SetLectureSeule(Valeur: Boolean);
    procedure AppliquerLectureSeule(Valeur: Boolean; const BaliseLibre: String);
    procedure Vider;
    function  LibCode(const Code: String): String;
    procedure RemplirCodes(Indice: Integer; const Courant: String);
    procedure ChargerDegats(Indice: Integer; const Valeur: String);
    procedure ChargerCases(Indice: Integer; const Valeur: String);
    function  FixeDegats(Indice: Integer): String;
    function  ComposerDegats(Indice: Integer): String;
    function  TexteSaisie(Indice: Integer): String;
    function  VersAffichage(const Valeur: String): String;
    function  VersXml(const Texte: String): String;
    procedure ChangementSaisie(Sender: TObject);
    procedure ClicCase(Sender: TObject);
    procedure BoutonValiderClick(Sender: TObject);
    procedure BoutonAnnulerClick(Sender: TObject);
  public
    // Modele : bouton dont Valider/Annuler copient l'aspect. Grille : la grille des modificateurs
    // partagee (elle change de parent d'une fiche a l'autre). Qualites : le bloc des qualites liees, idem.
    procedure Initialiser(Modele: TBCButton; Grille: TPanelModificateurs; Qualites: TPanelQualitesLiees);
    procedure Definir(const Champs: array of StructureChampFiche);
    procedure Charger(Element: TDOMElement);
    // coche toutes les cases du champ (a appeler apres Charger quand une valeur absente veut dire "tout")
    procedure CocherTout(const Balise: String);
    // coche, dans le champ gfCases de cette balise, les codes de la liste (separes par des virgules)
    procedure CocherCodes(const Balise, Codes: String);
    // le champ de cette balise n'est plus ecrit dans l'element par Ecrire (il reste lu par ValeurChamp et Signature)
    procedure DeclarerVirtuel(const Balise: String);
    // a appeler apres Definir : cet element ne porte pas de modificateurs (une condition, par exemple)
    procedure MasquerGrille;
    // ces codes (virgules) ne peuvent plus etre decoches dans les champs de cases (une relation portee par un autre livre)
    procedure VerrouillerCases(const Codes: String);
    // fiche consultable, sauf les cases du champ de cette balise : Valider/Annuler restent la
    procedure LectureSeuleSauf(const Balise: String);
    // remplace les choix d'un champ gfCases (Choix = "code=libelle|...") en gardant coches les codes qui le sont deja
    procedure RemplacerChoix(const Balise, Choix: String);
    // Position de la fiche ; sa hauteur est limitee a la place disponible sous elle (ascenseur au-dela).
    procedure Placer(ALeft, ATop: Integer);
    // False (avec message) si un champ est invalide ; sinon ecrit les champs, la grille et les qualites.
    function  Ecrire(Element: TDOMElement; const Langue: String): Boolean;
    function  Signature(const Sep: String): String;
    // valeur saisie dans le champ de cette balise ('' si absent), pour un controle propre a l'element
    function  ValeurChamp(const Balise: String): String;
    // pose le texte d'un champ simple (gfTexte) ; a appeler apres Charger, pour un champ virtuel
    procedure SetValeurChamp(const Balise, Valeur: String);
    procedure ActiverBoutons(Actif: Boolean);
    // libelle affiche d'un code (gfCode, gfCodeLibre) ; sans fonction, le code lui-meme
    property  LibelleCode: TFonctionLibelle read FLibelleCode write FLibelleCode;
    // bloc supplementaire de la fiche ; a poser APRES Definir (qui le retire) et avant Charger
    property  Extra: TPanelExtraFiche read FExtra write FExtra;
    // libelle d'une caracteristique RULES-ATTR_x (gfDegats)
    property  LibelleAttribut: TFonctionLibelle read FLibelleAttribut write FLibelleAttribut;
    // fiche consultable seulement (livre officiel) : champs et grille non modifiables, Valider/Annuler masques ;
    // a poser APRES Charger (qui remet la fiche en mode edition)
    property  LectureSeule: Boolean read FLectureSeule write SetLectureSeule;
    property  OnChangementChamp: TChangementChampFiche read FOnChangementChamp write FOnChangementChamp;
    property  OnControler: TControleFiche read FOnControler write FOnControler;
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
  end;

function ChampFiche(const Balise, CodeLibelle: String; Genre: GenreChampFiche = gfTexte;
  Pleine: Boolean = False; Obligatoire: Boolean = False; Facultatif: Boolean = False;
  AvecLangue: Boolean = True; const Choix: String = ''; Controle: ControleChampFiche = cfAucun): StructureChampFiche;

// Entier positif ou nul (champ vide refuse) ; prix : vide, "-", ou suite "nombre + monnaie en majuscules" (5CO, 1CO5PA).
function EntierPositifFiche(const S: String): Boolean;
function PrixValideFiche(const S: String): Boolean;
// Decoupe une formule de degats "+(BATTR_S)+5" : code du bonus d'attribut et valeur fixe ; True si un bonus est present.
function DecouperDegatsFiche(Degats: String; out CodeBonus, Fixe: String): Boolean;
// Valeur fixe de degats acceptee : vide, "-", ou un entier signe ou non, eventuellement un de ("1d10").
function DegatsFixeValide(const S: String): Boolean;

implementation

const
  LargeurFiche = 820;
  LargeurColonne = 400;
  DecalColonne = 420;
  HauteurGrille = 218;
  AttributsDegats: array[0..9] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel');

function ChampFiche(const Balise, CodeLibelle: String; Genre: GenreChampFiche;
  Pleine, Obligatoire, Facultatif, AvecLangue: Boolean; const Choix: String; Controle: ControleChampFiche): StructureChampFiche;
begin
  Result.Balise      := Balise;
  Result.CodeLibelle := CodeLibelle;
  Result.Genre       := Genre;
  Result.Pleine      := Pleine;
  Result.Obligatoire := Obligatoire;
  Result.Facultatif  := Facultatif;
  Result.AvecLangue  := AvecLangue;
  Result.Choix       := Choix;
  Result.Controle    := Controle;
  Result.Virtuel      := False;
end;

function EntierPositifFiche(const S: String): Boolean;
var
  I: Integer;
begin
  Result := S <> '';
  for I := 1 to Length(S) do
    if not (S[I] in ['0'..'9']) then Exit(False);
end;

function PrixValideFiche(const S: String): Boolean;
var
  I, Chiffres, Lettres: Integer;
begin
  if (S = '') or (S = '-') then Exit(True);
  Result := False;
  I := 1;
  while I <= Length(S) do
  begin
    Chiffres := 0;
    while (I <= Length(S)) and (S[I] in ['0'..'9']) do begin Inc(I); Inc(Chiffres); end;
    Lettres := 0;
    while (I <= Length(S)) and (S[I] in ['A'..'Z']) do begin Inc(I); Inc(Lettres); end;
    if (Chiffres = 0) or (Lettres = 0) then Exit;
  end;
  Result := True;
end;

function DecouperDegatsFiche(Degats: String; out CodeBonus, Fixe: String): Boolean;
var
  P1, P2: Integer;
  Reste: String;
begin
  CodeBonus := '';
  Fixe      := '';
  Result    := False;
  Reste := Trim(Degats);
  if (Reste = '') or (Reste = '-') then
  begin
    Fixe := Reste;
    Exit;
  end;
  // Le bonus d'attribut est entre parentheses
  P1 := Pos('(', Reste);
  P2 := Pos(')', Reste);
  if (P1 > 0) and (P2 > P1) then
  begin
    CodeBonus := Copy(Reste, P1 + 1, P2 - P1 - 1);
    Delete(Reste, P1, P2 - P1 + 1);
    Result := True;
  end;
  // Nettoyer les '+' devenus orphelins apres le retrait du groupe
  while (Length(Reste) > 0) and (Reste[1] = '+') do
    Delete(Reste, 1, 1);
  Fixe := Trim(Reste);
end;

function DegatsFixeValide(const S: String): Boolean;
var
  I, N: Integer;
  VuD: Boolean;
begin
  Result := False;
  if (S = '') or (S = '-') then Exit(True);
  I := 1;
  if S[1] in ['+', '-'] then Inc(I);
  N := 0;
  VuD := False;
  while I <= Length(S) do
  begin
    if S[I] in ['0'..'9'] then
      Inc(N)
    else if (S[I] in ['d', 'D']) and (not VuD) and (N > 0) and (I < Length(S)) then
    begin
      VuD := True;
      N := 0;
    end
    else
      Exit;
    Inc(I);
  end;
  Result := N > 0;
end;

procedure TPanelFiche.Initialiser(Modele: TBCButton; Grille: TPanelModificateurs; Qualites: TPanelQualitesLiees);
begin
  FGrille := Grille;
  FQualites := Qualites;
  FIdxQual := -1;
  BevelOuter := bvNone;
  Caption := '';
  FDefil := TScrollBox.Create(Self);
  FDefil.Parent := Self;
  FDefil.Align := alClient;
  FDefil.BorderStyle := bsNone;
  FDefil.HorzScrollBar.Visible := False;
  FDefil.AutoScroll := True;
  FBoutonValider := TBCButtonContour.Create(Self);
  FBoutonValider.Assign(Modele);
  FBoutonValider.Parent := FDefil;
  FBoutonValider.OnClick := @BoutonValiderClick;
  FBoutonAnnuler := TBCButtonContour.Create(Self);
  FBoutonAnnuler.Assign(Modele);
  FBoutonAnnuler.Parent := FDefil;
  FBoutonAnnuler.OnClick := @BoutonAnnulerClick;
end;

procedure TPanelFiche.Vider;
var
  I: Integer;
begin
  for I := 0 to High(FEtiquettes) do FEtiquettes[I].Free;
  for I := 0 to High(FEtiquettes2) do FEtiquettes2[I].Free;
  for I := 0 to High(FSaisies) do FSaisies[I].Free;
  for I := 0 to High(FSaisies2) do FSaisies2[I].Free;
  for I := 0 to High(FCodes) do FCodes[I].Free;
  SetLength(FCodes, 0);
  SetLength(FEtiquettes, 0);
  SetLength(FEtiquettes2, 0);
  SetLength(FSaisies, 0);
  SetLength(FSaisies2, 0);
  SetLength(FOrigine, 0);
  SetLength(FChamps, 0);
  FIdxQual := -1;
end;

function TPanelFiche.LibCode(const Code: String): String;
begin
  if Assigned(FLibelleCode) then
    Result := FLibelleCode(Code)
  else
    Result := Code;
end;

procedure TPanelFiche.Definir(const Champs: array of StructureChampFiche);
var
  I, J, Y, Col, HLigne, H: Integer;
  Etiquette: TLabel;
  Saisie: TWinControl;
  X, L: Integer;
  Pleine: Boolean;
begin
  Vider;
  if FExtra <> nil then FExtra.Visible := False;
  FExtra := nil;
  FVerrous := '';
  FSansGrille := False;
  SetLength(FChamps, Length(Champs));
  SetLength(FEtiquettes, Length(Champs));
  SetLength(FEtiquettes2, Length(Champs));
  SetLength(FSaisies, Length(Champs));
  SetLength(FSaisies2, Length(Champs));
  SetLength(FOrigine, Length(Champs));
  SetLength(FCodes, Length(Champs));
  Y := 0;
  Col := 0;     // colonne du prochain champ non plein
  HLigne := 0;  // hauteur de la ligne en cours
  for I := 0 to High(Champs) do
  begin
    FChamps[I] := Champs[I];
    if Champs[I].Genre = gfQualites then
    begin
      FIdxQual := I;
      Continue;
    end;
    Pleine := Champs[I].Pleine or (Champs[I].Genre = gfDegats);
    if Pleine then
    begin
      if Col = 1 then begin Y := Y + HLigne; Col := 0; HLigne := 0; end;
      X := 0; L := LargeurFiche;
    end
    else
    begin
      X := Col * DecalColonne; L := LargeurColonne;
    end;
    if Champs[I].Genre = gfDegats then L := LargeurColonne;
    if Champs[I].Genre = gfMemo then H := 70
    else if (Champs[I].Genre = gfCases) and (Pos('|', Champs[I].Choix) = 0) then H := 28
    else if Champs[I].Genre = gfCases then H := 100
    else H := 28;

    Etiquette := TLabelContour.Create(Self);
    Etiquette.Parent := FDefil;
    Etiquette.SetBounds(X, Y, L, 20);
    Etiquette.Caption := GetTexteLibelle(Champs[I].CodeLibelle);
    FEtiquettes[I] := Etiquette;

    case Champs[I].Genre of
      gfMemo:
        begin
          Saisie := TMemo.Create(Self);
          TMemo(Saisie).ScrollBars := ssAutoVertical;
        end;
      gfCode, gfDegats:
        begin
          Saisie := TComboBox.Create(Self);
          TComboBox(Saisie).Style := csDropDownList;
          TComboBox(Saisie).OnChange := @ChangementSaisie;
          FCodes[I] := TStringList.Create;
        end;
      gfCodeLibre:
        begin
          Saisie := TComboBox.Create(Self);
          TComboBox(Saisie).Style := csDropDown;
          FCodes[I] := TStringList.Create;
        end;
      gfCases:
        begin
          Saisie := TCheckListBox.Create(Self);
          TCheckListBox(Saisie).OnClickCheck := @ClicCase;
          FCodes[I] := TStringList.Create;
        end;
      gfListe:
        begin
          Saisie := TComboBox.Create(Self);
          TComboBox(Saisie).Style := csDropDown;
          TComboBox(Saisie).Items.Delimiter := '|';
          TComboBox(Saisie).Items.StrictDelimiter := True;
          TComboBox(Saisie).Items.DelimitedText := Champs[I].Choix;
          for J := 0 to TComboBox(Saisie).Items.Count - 1 do
            TComboBox(Saisie).Items[J] := VersAffichage(TComboBox(Saisie).Items[J]);
        end;
    else
      Saisie := TEdit.Create(Self);
    end;
    Saisie.Parent := FDefil;
    Saisie.SetBounds(X, Y + 22, L, H);
    FSaisies[I] := Saisie;

    if Champs[I].Genre = gfDegats then
    begin
      // seconde moitie de la ligne : la valeur fixe
      FEtiquettes2[I] := TLabelContour.Create(Self);
      FEtiquettes2[I].Parent := FDefil;
      FEtiquettes2[I].SetBounds(DecalColonne, Y, LargeurColonne, 20);
      FSaisies2[I] := TEdit.Create(Self);
      FSaisies2[I].Parent := FDefil;
      FSaisies2[I].SetBounds(DecalColonne, Y + 22, LargeurColonne, H);
    end;

    if Pleine then
    begin
      Y := Y + 22 + H + 14;
      HLigne := 0;
    end
    else if Col = 0 then
    begin
      Col := 1;
      HLigne := 22 + H + 14;
    end
    else
    begin
      if 22 + H + 14 > HLigne then HLigne := 22 + H + 14;
      Y := Y + HLigne;
      Col := 0;
      HLigne := 0;
    end;
  end;
  if Col = 1 then Y := Y + HLigne;
  FYGrille := Y + 10;
  // les composants crees ici appartiennent au panneau : meme mise en forme que PanelModificateurs
  MiseAJourUnContenaire(Self);
end;

// Listes a codes : "code" ou "code=libelle". Sans libelle explicite, un code sans libelle n'appartient
// pas a l'edition chargee et n'est pas propose. Liste fermee : la valeur courante reste choisissable ;
// liste libre : une valeur hors liste est gardee dans la zone de saisie.
procedure TPanelFiche.RemplirCodes(Indice: Integer; const Courant: String);
var
  Choix: TStringList;
  Combo: TComboBox;
  I, P: Integer;
  Code, Lib: String;
begin
  Combo := TComboBox(FSaisies[Indice]);
  FCodes[Indice].Clear;
  Combo.Items.Clear;
  Choix := TStringList.Create;
  try
    Choix.Delimiter := '|';
    Choix.StrictDelimiter := True;
    Choix.DelimitedText := FChamps[Indice].Choix;
    for I := 0 to Choix.Count - 1 do
    begin
      P := Pos('=', Choix[I]);
      if P > 0 then
      begin
        Code := Copy(Choix[I], 1, P - 1);
        Lib := Copy(Choix[I], P + 1, Length(Choix[I]));
      end
      else
      begin
        Code := Choix[I];
        Lib := LibCode(Code);
        if Lib = Code then Continue;
      end;
      FCodes[Indice].Add(Code);
      Combo.Items.Add(Lib);
    end;
  finally
    Choix.Free;
  end;
  if FChamps[Indice].Genre = gfCodeLibre then
  begin
    I := FCodes[Indice].IndexOf(Courant);
    if I >= 0 then
      Combo.ItemIndex := I
    else
      Combo.Text := Courant;
    Exit;
  end;
  if (Courant <> '') and (Courant <> '-') and (FCodes[Indice].IndexOf(Courant) < 0) then
  begin
    FCodes[Indice].Add(Courant);
    Combo.Items.Add(LibCode(Courant));
  end;
  Combo.ItemIndex := FCodes[Indice].IndexOf(Courant);
end;

// Cases a cocher : chaque entree "code=libelle" de Choix ; les codes de Valeur (separes par une virgule)
// sont coches, ceux qui ne sont pas dans la liste sont ignores.
procedure TPanelFiche.ChargerCases(Indice: Integer; const Valeur: String);
var
  Choix, Presents: TStringList;
  Liste: TCheckListBox;
  I, P: Integer;
begin
  Liste := TCheckListBox(FSaisies[Indice]);
  FCodes[Indice].Clear;
  Liste.Items.Clear;
  Choix := TStringList.Create;
  Presents := TStringList.Create;
  try
    Choix.Delimiter := '|';
    Choix.StrictDelimiter := True;
    Choix.DelimitedText := FChamps[Indice].Choix;
    Presents.Delimiter := ',';
    Presents.StrictDelimiter := True;
    Presents.DelimitedText := Valeur;
    for I := 0 to Choix.Count - 1 do
    begin
      P := Pos('=', Choix[I]);
      if P > 0 then
      begin
        FCodes[Indice].Add(Copy(Choix[I], 1, P - 1));
        Liste.Items.Add(Copy(Choix[I], P + 1, Length(Choix[I])));
      end
      else
      begin
        FCodes[Indice].Add(Choix[I]);
        Liste.Items.Add(LibCode(Choix[I]));
      end;
    end;
    for I := 0 to Liste.Items.Count - 1 do
      Liste.Checked[I] := Presents.IndexOf(Trim(FCodes[Indice][I])) >= 0;
  finally
    Presents.Free;
    Choix.Free;
  end;
end;

procedure TPanelFiche.ChargerDegats(Indice: Integer; const Valeur: String);
var
  Combo: TComboBox;
  CodeBonus, Fixe: String;
  I: Integer;
begin
  DecouperDegatsFiche(Valeur, CodeBonus, Fixe);
  Combo := TComboBox(FSaisies[Indice]);
  FCodes[Indice].Clear;
  Combo.Items.Clear;
  FCodes[Indice].Add('');
  Combo.Items.Add(GetTexteLibelle('RULES-LAB_423'));  // aucun bonus
  for I := Low(AttributsDegats) to High(AttributsDegats) do
  begin
    FCodes[Indice].Add('BATTR_' + AttributsDegats[I]);
    if Assigned(FLibelleAttribut) then
      Combo.Items.Add(GetTexteLibelle('RULES-LAB_034') + ' ' + FLibelleAttribut('RULES-ATTR_' + AttributsDegats[I]))
    else
      Combo.Items.Add(GetTexteLibelle('RULES-LAB_034') + ' ' + AttributsDegats[I]);
  end;
  if (CodeBonus <> '') and (FCodes[Indice].IndexOf(CodeBonus) < 0) then  // valeur hors liste conservee
  begin
    FCodes[Indice].Add(CodeBonus);
    Combo.Items.Add(CodeBonus);
  end;
  Combo.ItemIndex := FCodes[Indice].IndexOf(CodeBonus);
  FEtiquettes[Indice].Caption := GetTexteLibelle(FChamps[Indice].CodeLibelle) + ' - ' + GetTexteLibelle('RULES-LAB_034');
  FEtiquettes2[Indice].Caption := GetTexteLibelle(FChamps[Indice].CodeLibelle) + ' - ' + GetTexteLibelle('RULES-LAB_424');
  TEdit(FSaisies2[Indice]).Text := Fixe;
end;

// Valeur fixe sans espaces (telle qu'elle est controlee).
function TPanelFiche.FixeDegats(Indice: Integer): String;
begin
  Result := StringReplace(Trim(TEdit(FSaisies2[Indice]).Text), ' ', '', [rfReplaceAll]);
end;

// Le texte ecrit est celui que DecouperDegatsFiche sait relire : "+(BATTR_S)+4", "+8", "-".
function TPanelFiche.ComposerDegats(Indice: Integer): String;
var
  Fixe: String;
  I: Integer;
begin
  Fixe := FixeDegats(Indice);
  if (Fixe <> '') and (Fixe <> '-') and not (Fixe[1] in ['+', '-']) then
    Fixe := '+' + Fixe;
  I := TComboBox(FSaisies[Indice]).ItemIndex;
  if I > 0 then
  begin
    Result := '+(' + FCodes[Indice][I] + ')';
    if (Fixe <> '') and (Fixe <> '-') then Result := Result + Fixe;
  end
  else if Fixe = '' then
    Result := '-'
  else
    Result := Fixe;
end;

// Jetons d'attribut des durees et portees : "(BATTR_WP)" -> "(Bonus Force Mentale)", "(ATTR_WP)" -> "(Force Mentale)".
// Sans fonction de libelle d'attribut, rien n'est converti.
function TPanelFiche.VersAffichage(const Valeur: String): String;
var
  I: Integer;
  Lib: String;
begin
  Result := Valeur;
  if not Assigned(FLibelleAttribut) then Exit;
  for I := Low(AttributsDegats) to High(AttributsDegats) do
  begin
    Lib := FLibelleAttribut('RULES-ATTR_' + AttributsDegats[I]);
    if (Lib = '') or (Lib = 'RULES-ATTR_' + AttributsDegats[I]) then Continue;
    Result := StringReplace(Result, '(BATTR_' + AttributsDegats[I] + ')', '(' + GetTexteLibelle('RULES-LAB_483') + ' ' + Lib + ')', [rfReplaceAll]);
    Result := StringReplace(Result, '(ATTR_' + AttributsDegats[I] + ')', '(' + Lib + ')', [rfReplaceAll]);
  end;
end;

// Sens inverse, pour un texte que l'utilisateur a modifie ; le bonus d'abord (sinon "(Bonus X)" ne serait jamais reconnu).
function TPanelFiche.VersXml(const Texte: String): String;
var
  I: Integer;
  Lib: String;
begin
  Result := Texte;
  if not Assigned(FLibelleAttribut) then Exit;
  for I := Low(AttributsDegats) to High(AttributsDegats) do
  begin
    Lib := FLibelleAttribut('RULES-ATTR_' + AttributsDegats[I]);
    if (Lib = '') or (Lib = 'RULES-ATTR_' + AttributsDegats[I]) then Continue;
    Result := StringReplace(Result, '(' + GetTexteLibelle('RULES-LAB_483') + ' ' + Lib + ')', '(BATTR_' + AttributsDegats[I] + ')', [rfReplaceAll]);
  end;
  for I := Low(AttributsDegats) to High(AttributsDegats) do
  begin
    Lib := FLibelleAttribut('RULES-ATTR_' + AttributsDegats[I]);
    if (Lib = '') or (Lib = 'RULES-ATTR_' + AttributsDegats[I]) then Continue;
    Result := StringReplace(Result, '(' + Lib + ')', '(ATTR_' + AttributsDegats[I] + ')', [rfReplaceAll]);
  end;
end;

function TPanelFiche.TexteSaisie(Indice: Integer): String;
var
  I: Integer;
begin
  case FChamps[Indice].Genre of
    gfMemo: Result := Trim(TMemo(FSaisies[Indice]).Text);
    gfCode:
      begin
        Result := '';
        if TComboBox(FSaisies[Indice]).ItemIndex >= 0 then
          Result := FCodes[Indice][TComboBox(FSaisies[Indice]).ItemIndex];
      end;
    gfCodeLibre:
      begin
        // un libelle de la liste devient son code, toute autre saisie est gardee telle quelle
        Result := Trim(TComboBox(FSaisies[Indice]).Text);
        I := TComboBox(FSaisies[Indice]).Items.IndexOf(Result);
        if I >= 0 then Result := FCodes[Indice][I];
      end;
    gfListe:
      begin
        Result := Trim(TComboBox(FSaisies[Indice]).Text);
        // texte inchange : on rend la valeur d'origine, jamais une reconversion (aucune donnee ne bouge sans saisie)
        if Result = Trim(VersAffichage(FOrigine[Indice])) then Result := Trim(FOrigine[Indice])
        else Result := VersXml(Result);
      end;
    gfDegats: Result := ComposerDegats(Indice);
    gfQualites: Result := FQualites.Texte;
    gfCases:
      begin
        Result := '';
        for I := 0 to TCheckListBox(FSaisies[Indice]).Items.Count - 1 do
          if TCheckListBox(FSaisies[Indice]).Checked[I] then
          begin
            if Result <> '' then Result := Result + ',';
            Result := Result + FCodes[Indice][I];
          end;
      end;
  else
    Result := Trim(TEdit(FSaisies[Indice]).Text);
  end;
end;

procedure TPanelFiche.Charger(Element: TDOMElement);
var
  I: Integer;
  Valeur: String;
begin
  FChargement := True;
  for I := 0 to High(FChamps) do
  begin
    Valeur := ValeurXML(Element.FindNode(FChamps[I].Balise));
    case FChamps[I].Genre of
      gfQualites: FQualites.Charger(Valeur);
      gfCode, gfCodeLibre: RemplirCodes(I, Valeur);
      gfCases: ChargerCases(I, Valeur);
      gfDegats: ChargerDegats(I, Valeur);
      gfMemo: TMemo(FSaisies[I]).Text := Valeur;
      gfListe:
        begin
          FOrigine[I] := Valeur;
          TComboBox(FSaisies[I]).Text := VersAffichage(Valeur);
        end;
    else
      TEdit(FSaisies[I]).Text := Valeur;
    end;
  end;
  FBoutonValider.Caption := GetTexteLibelle('RULES-LAB_086');
  FBoutonAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');

  // grille des modificateurs, puis (si l'element en a) les qualites liees en dessous, meme largeur ;
  // les boutons suivent
  FGrille.Parent := FDefil;
  if FSansGrille then
  begin
    FGrille.Visible := False;
    FHauteurContenu := FYGrille;
  end
  else
  begin
    FGrille.Visible := True;
    FGrille.Placer(False);
    FGrille.SetBounds(0, FYGrille, LargeurFiche, HauteurGrille);
    FGrille.LectureSeule := False;
    FGrille.Charger(Element);
    FHauteurContenu := FYGrille + HauteurGrille;
  end;
  if FExtra <> nil then
  begin
    FExtra.Parent := FDefil;
    FExtra.SetBounds(0, FHauteurContenu, LargeurFiche, FExtra.Height);
    FExtra.Charger(Element);
    FExtra.Visible := True;
    FHauteurContenu := FHauteurContenu + FExtra.Height;
  end;
  if FIdxQual >= 0 then
  begin
    FQualites.Parent := FDefil;
    FQualites.Placer(LargeurFiche);
    FQualites.SetBounds(0, FHauteurContenu + 10, LargeurFiche, HauteurGrille);
    FQualites.Visible := True;
    FHauteurContenu := FHauteurContenu + 10 + HauteurGrille;
  end
  else if FQualites <> nil then
    FQualites.Visible := False;
  FBoutonValider.SetBounds(0, FHauteurContenu + 12, 120, 32);
  FBoutonAnnuler.SetBounds(130, FHauteurContenu + 12, 120, 32);
  FHauteurContenu := FHauteurContenu + 12 + 32 + 10;
  FHauteurPleine := FHauteurContenu;
  Width := LargeurFiche + 25;  // + ascenseur
  Height := FHauteurContenu;
  SetLectureSeule(False);
  FChargement := False;
end;

procedure TPanelFiche.SetValeurChamp(const Balise, Valeur: String);
var
  I: Integer;
begin
  for I := 0 to High(FChamps) do
    if (FChamps[I].Balise = Balise) and (FSaisies[I] is TEdit) then TEdit(FSaisies[I]).Text := Valeur;
end;

function TPanelFiche.ValeurChamp(const Balise: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FChamps) do
    if FChamps[I].Balise = Balise then Exit(TexteSaisie(I));
end;

// En lecture seule la liste de cases reste active (son ascenseur doit servir) : on annule simplement le clic.
// Dans une lecture seule partielle, seules les cases du champ libre bougent ; un code verrouille ne se decoche pas.
procedure TPanelFiche.ClicCase(Sender: TObject);
var
  L: TCheckListBox;
  I, Rang: Integer;
begin
  L := TCheckListBox(Sender);
  Rang := L.ItemIndex;
  if Rang < 0 then Exit;
  for I := 0 to High(FSaisies) do
    if FSaisies[I] = L then
    begin
      if FLectureSeule and (FChamps[I].Balise <> FBaliseLibre) then
        L.Checked[Rang] := not L.Checked[Rang]
      else if (not L.Checked[Rang]) and (Pos(',' + Trim(FCodes[I][Rang]) + ',', ',' + FVerrous + ',') > 0) then
        L.Checked[Rang] := True;
      Exit;
    end;
end;

procedure TPanelFiche.ChangementSaisie(Sender: TObject);
var
  I: Integer;
begin
  if FChargement or not Assigned(FOnChangementChamp) then Exit;
  for I := 0 to High(FSaisies) do
    if FSaisies[I] = Sender then
    begin
      FOnChangementChamp(FChamps[I].Balise);
      Exit;
    end;
end;

procedure TPanelFiche.RemplacerChoix(const Balise, Choix: String);
var
  I, J: Integer;
  Coches: String;
begin
  for I := 0 to High(FChamps) do
    if (FChamps[I].Balise = Balise) and (FChamps[I].Genre = gfCases) then
    begin
      Coches := '';
      for J := 0 to TCheckListBox(FSaisies[I]).Items.Count - 1 do
        if TCheckListBox(FSaisies[I]).Checked[J] then
        begin
          if Coches <> '' then Coches := Coches + ',';
          Coches := Coches + FCodes[I][J];
        end;
      FChamps[I].Choix := Choix;
      FChargement := True;
      try
        ChargerCases(I, Coches);
      finally
        FChargement := False;
      end;
    end;
end;

procedure TPanelFiche.MasquerGrille;
begin
  FSansGrille := True;
end;

procedure TPanelFiche.DeclarerVirtuel(const Balise: String);
var
  I: Integer;
begin
  for I := 0 to High(FChamps) do
    if FChamps[I].Balise = Balise then FChamps[I].Virtuel := True;
end;

procedure TPanelFiche.CocherCodes(const Balise, Codes: String);
var
  I, J: Integer;
  Liste: TStringList;
begin
  Liste := TStringList.Create;
  try
    Liste.Delimiter := ',';
    Liste.StrictDelimiter := True;
    Liste.DelimitedText := Codes;
    for I := 0 to High(FChamps) do
      if (FChamps[I].Balise = Balise) and (FChamps[I].Genre = gfCases) then
        for J := 0 to TCheckListBox(FSaisies[I]).Items.Count - 1 do
          if Liste.IndexOf(Trim(FCodes[I][J])) >= 0 then TCheckListBox(FSaisies[I]).Checked[J] := True;
  finally
    Liste.Free;
  end;
end;

procedure TPanelFiche.CocherTout(const Balise: String);
var
  I, J: Integer;
begin
  for I := 0 to High(FChamps) do
    if (FChamps[I].Balise = Balise) and (FChamps[I].Genre = gfCases) then
      for J := 0 to TCheckListBox(FSaisies[I]).Items.Count - 1 do
        TCheckListBox(FSaisies[I]).Checked[J] := True;
end;

procedure TPanelFiche.SetLectureSeule(Valeur: Boolean);
begin
  AppliquerLectureSeule(Valeur, '');
end;

procedure TPanelFiche.LectureSeuleSauf(const Balise: String);
begin
  AppliquerLectureSeule(True, Balise);
end;

procedure TPanelFiche.VerrouillerCases(const Codes: String);
begin
  FVerrous := Codes;
end;

procedure TPanelFiche.AppliquerLectureSeule(Valeur: Boolean; const BaliseLibre: String);
var
  I: Integer;
begin
  FLectureSeule := Valeur;
  FBaliseLibre := BaliseLibre;
  for I := 0 to High(FSaisies) do
  begin
    if FSaisies[I] = nil then Continue;  // champ gfQualites : pas de controle en haut, le bloc des qualites est a part
    if FSaisies[I] is TEdit then TEdit(FSaisies[I]).ReadOnly := Valeur
    else if FSaisies[I] is TMemo then TMemo(FSaisies[I]).ReadOnly := Valeur
    else if FSaisies[I] is TCheckListBox then FSaisies[I].Enabled := True  // ascenseur actif ; ClicCase annule les clics
    else FSaisies[I].Enabled := not Valeur;
    if FSaisies2[I] <> nil then TEdit(FSaisies2[I]).ReadOnly := Valeur;
  end;
  FGrille.LectureSeule := Valeur;
  if FExtra <> nil then FExtra.MettreLectureSeule(Valeur);
  if FQualites <> nil then FQualites.SetLectureSeule(Valeur);
  FBoutonValider.Visible := (not Valeur) or (BaliseLibre <> '');
  FBoutonAnnuler.Visible := (not Valeur) or (BaliseLibre <> '');
  if Valeur and (BaliseLibre = '') then FHauteurContenu := FHauteurPleine - 44 else FHauteurContenu := FHauteurPleine;
  Height := FHauteurContenu;
end;

procedure TPanelFiche.Placer(ALeft, ATop: Integer);
var
  Libre: Integer;
begin
  Left := ALeft;
  Top := ATop;
  Height := FHauteurContenu;
  if Parent <> nil then
  begin
    Libre := Parent.ClientHeight - ATop - 8;
    if (Libre > 200) and (Libre < Height) then Height := Libre;
  end;
end;

function TPanelFiche.Ecrire(Element: TDOMElement; const Langue: String): Boolean;
var
  I: Integer;
  Valeur: String;
  Noeud, Suivant: TDOMNode;
  Nouveau: TDOMElement;
begin
  Result := False;
  for I := 0 to High(FChamps) do
  begin
    if FChamps[I].Genre = gfQualites then Continue;
    Valeur := TexteSaisie(I);
    if FChamps[I].Genre = gfDegats then
    begin
      if not DegatsFixeValide(FixeDegats(I)) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_425'));
        Exit;
      end;
    end
    else if FChamps[I].Genre in [gfCode, gfCases] then
    begin
      if (Valeur = '') and FChamps[I].Obligatoire then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_441'), [GetTexteLibelle(FChamps[I].CodeLibelle)]));
        Exit;
      end;
    end
    else if (FChamps[I].Controle = cfEntier) and ((Valeur <> '') or FChamps[I].Obligatoire) then
    begin
      if not EntierPositifFiche(Valeur) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_438'), [GetTexteLibelle(FChamps[I].CodeLibelle)]));
        Exit;
      end;
    end
    else if (FChamps[I].Controle = cfPrix) and not PrixValideFiche(StringReplace(Valeur, ' ', '', [rfReplaceAll])) then
    begin
      ShowMessage(GetTexteLibelle('RULES-LAB_439'));
      Exit;
    end
    else if FChamps[I].Obligatoire and (Valeur = '') then
    begin
      ShowMessage(GetTexteLibelle('RULES-LAB_404'));
      Exit;
    end;
  end;
  if FGrille.Visible and not FGrille.Controler then Exit;
  if (FExtra <> nil) and not FExtra.Controler then Exit;
  if Assigned(FOnControler) and not FOnControler() then Exit;
  if (FIdxQual >= 0) and (FQualites <> nil) and FQualites.Visible and not FQualites.Controler then Exit;
  for I := 0 to High(FChamps) do
  begin
    if FChamps[I].Virtuel then Continue;
    Valeur := TexteSaisie(I);
    if FChamps[I].Controle = cfPrix then Valeur := StringReplace(Valeur, ' ', '', [rfReplaceAll]);
    // liste fermee non obligatoire laissee vide : la balise existante n'est pas touchee
    if (FChamps[I].Genre = gfCode) and (Valeur = '') then Continue;
    Noeud := Element.FindNode(FChamps[I].Balise);
    if Noeud = nil then
    begin
      if FChamps[I].Facultatif and (Valeur = '') then Continue;
      Nouveau := Element.OwnerDocument.CreateElement(FChamps[I].Balise);
      if FChamps[I].AvecLangue then Nouveau.SetAttribute('language', Langue);
      // avant les modificateurs : le schema les attend apres les champs de l'element
      Suivant := Element.FirstChild;
      while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and (Pos('Modif', Suivant.NodeName) = 1)) do
        Suivant := Suivant.NextSibling;
      Element.InsertBefore(Nouveau, Suivant);
      Noeud := Nouveau;
    end;
    EcrireValeurXML(TDOMElement(Noeud), Valeur);
  end;
  if not FSansGrille then FGrille.Ecrire(Element);
  if FExtra <> nil then FExtra.Ecrire(Element);
  Result := True;
end;

function TPanelFiche.Signature(const Sep: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FChamps) do
    if FChamps[I].Genre = gfQualites then
      Result := Result + FQualites.Signature(Sep)
    else if FChamps[I].Genre = gfDegats then
      Result := Result + Sep + IntToStr(TComboBox(FSaisies[I]).ItemIndex) + Sep + TEdit(FSaisies2[I]).Text
    else if FChamps[I].Genre = gfCodeLibre then
      Result := Result + Sep + Trim(TComboBox(FSaisies[I]).Text)
    else
      Result := Result + Sep + TexteSaisie(I);
  if not FSansGrille then Result := Result + FGrille.Signature(Sep);
  if FExtra <> nil then Result := Result + FExtra.Signature(Sep);
end;

procedure TPanelFiche.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelFiche.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelFiche.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

end.

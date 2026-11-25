unit ChargeMetierAttribut;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, Generics.Collections;

Type
    StructureMetierAttribut	= Record
	CodeMetier:	String;
	NiveauMetier:	Integer;
	CodeAttribut:	String;
        Livre:          String;
End;

  TListMetierAttribut = Specialize TList<StructureMetierAttribut>;

  // V2 : schema d'avances d'une carriere (<Advances> de <Career>). Plafond du TOTAL des avances de
  // la caracteristique tant que la carriere est en cours, valeur du livre (5 = +5 %, 2 = +2).
  // Liste a part de StructureMetierAttribut, dont NiveauMetier est un niveau de carriere (V4).
  StructureMetierAvance = Record
    CodeMetier:     String;
    CodeAttribut:   String;
    Plafond:        Integer;
    Livre:          String;
  end;

  TListMetierAvance = Specialize TList<StructureMetierAvance>;

  // V2 : argent de depart d'une carriere (<StartMoney> de <Career>), formule en couronnes d'or :
  // "15CO" (fixe) ou "1d10CO" (au de). Liste a part, comme les avances.
  StructureMetierArgent = Record
    CodeMetier:     String;
    Formule:        String;
    Livre:          String;
  end;

  TListMetierArgent = Specialize TList<StructureMetierArgent>;

  // V2 : sorties d'une carriere en codes (<ExitCodes> de <Career>) ; Base = carriere de base (<Basic>).
  StructureMetierSortie = Record
    CodeMetier:     String;
    CodeSortie:     String;
    Livre:          String;
  end;

  TListMetierSortie = Specialize TList<StructureMetierSortie>;

  StructureMetierBase = Record
    CodeMetier:     String;
    Livre:          String;
  end;

  TListMetierBase = Specialize TList<StructureMetierBase>;

  // V1 : metier d'un Artisan (<Trade> de DATA_TRADE_V1). Competences et sorties en codes separes par des virgules.
  StructureArtisanMetier = Record
    CodeMetier:     String;
    Libelle:        String;
    Tirage:         String;
    Competences:    String;
    Sorties:        String;
    Note:           String;
    Livre:          String;
  end;

  TListArtisanMetier = Specialize TList<StructureArtisanMetier>;

  // V1 : classe de carriere (<Class> de DATA_CLASS_V1). Exigences en "CODE=valeur" separees par des virgules ;
  // ExigencesRace en "ESPECE:CODE=valeur" separees par des virgules (remplacent l'exigence generale de la meme caracteristique).
  StructureClasseV1 = Record
    CodeClasse:     String;
    Libelle:        String;
    Description:    String;
    Exigences:      String;
    ExigencesRace:  String;
    Equipement:     String;
    Argent:         String;
    Livre:          String;
  end;

  TListClasseV1 = Specialize TList<StructureClasseV1>;

  // V1 : une ligne de la table d100 des competences de depart (classe x ethnie) ; Chance en %
  StructureTirageCompV1 = Record
    CodeClasse:      String;
    Espece:          String;
    CodeCompetence:  String;
    Chance:          Integer;
  end;

  TListTirageCompV1 = Specialize TList<StructureTirageCompV1>;

  // V1 : modificateur du nombre de competences de depart selon l'age (D4 + modificateur)
  StructureAgeCompV1 = Record
    Espece:    String;
    AgeMin:    Integer;
    AgeMax:    Integer;
    Modifieur: Integer;
  end;

  TListAgeCompV1 = Specialize TList<StructureAgeCompV1>;

  // V1 : points de magie gagnes a chaque niveau d'une carriere magique (Espece 'ALL' = toutes)
  StructureGainMagieV1 = Record
    Espece:    String;
    Carriere:  String;
    NiveauMin: Integer;
    NiveauMax: Integer;
    Des:       String;
  end;

  TListGainMagieV1 = Specialize TList<StructureGainMagieV1>;

  // V1 : handicap d'un magicien ; Modif / Texte par stade (1 a 3), Modif = "RULES-ATTR_WS=-5;RULES-ATTR_I=-5"
  StructureHandicapV1 = Record
    Code:    String;
    Libelle: String;
    Modif:   array[1..3] of String;
    Texte:   array[1..3] of String;
  end;

  TListHandicapV1 = Specialize TList<StructureHandicapV1>;

  // V1 : ligne d'une table d100 de handicaps ; Auto = obtenu d'office au niveau 1 (pas de jet)
  StructureTirageHandicapV1 = Record
    Table: String;
    Code:  String;
    Min:   Integer;
    Max:   Integer;
    Auto:  Boolean;
  end;

  TListTirageHandicapV1 = Specialize TList<StructureTirageHandicapV1>;

  // V1 : ligne de la table d'avancement du Cleric (CLERIC) ou du Druidic Priest (DRUID) ;
  // Resultat = ADVANCE / NOT_READY / TRIAL / UNWORTHY / WRATH
  StructureAvancementPretreV1 = Record
    Table:     String;
    Min:       Integer;
    Max:       Integer;
    Resultat:  String;
    CadeauEP:  Boolean;
    Destin:    Integer;
    Benediction: Boolean;
    Explication: String;
  end;

  TListAvancementPretreV1 = Specialize TList<StructureAvancementPretreV1>;

  // V1 : familier du Druidic Priest (Core p.206) ; Comp1 est gagnee au niveau 1, Comp2 au niveau 2
  StructureFamilierV1 = Record
    Code:             String;
    Min:              Integer;
    Max:              Integer;
    Animal:           String;
    Comp1:            String;
    Comp2:            String;
    Armure:           String;
    Bouclier:         Boolean;
    ArmesInterdites:  String;
    Lieux:            String;
    Regime:           String;
  end;

  TListFamilierV1 = Specialize TList<StructureFamilierV1>;

  // V1 : culte de Realm of Divine Magic (DATA_CULT_V1) ; Libelle = nom du culte, Deite = id RULES-DEITY_* ('' si hors livre de base)
  StructureCulteV1 = Record
    Code:    String;
    Libelle: String;
    Deite:   String;
  end;

  TListCulteV1 = Specialize TList<StructureCulteV1>;

  // V1 : une priere de la liste d'un culte ; Rang = INITIATE, 1 a 4 ; Genre = REQUIRED (exigee pour monter de rang) ou HONOR
  StructurePriereCulteV1 = Record
    Culte:      String;
    Rang:       String;
    Genre:      String;
    CodePriere: String;
  end;

  TListPriereCulteV1 = Specialize TList<StructurePriereCulteV1>;

  // V1 : un objet de la liste de prix (Core p.290 et suivantes) ; Cout et Encombrement restent en texte du livre
  StructureObjetV1 = Record
    Code:            String;
    Libelle:         String;
    Categorie:       String;
    SousCategorie:   String;
    Cout:            String;
    Encombrement:    String;
    Disponibilite:   String;
    Combat:          String;
    PointsArmure:    String;
    Zones:           String;
    PorteeCourte:    String;   // tir : distances Short / Long / Extreme du livre, force par palier (« 3 » ou « 4/3/2 »), rechargement
    PorteeLongue:    String;
    PorteeExtreme:   String;
    ForceTir:        String;
    Rechargement:    String;
  end;

  TListObjetV1 = Specialize TList<StructureObjetV1>;

  // V1 : regle d'apprentissage d'un sort par niveau ("P", "1" a "4") ; les modificateurs sont lus dans le livre
  // ("x2", "x1", "-10"...), Echec = plage du d100 qui rate toujours ("96-100"), '' si aucune
  StructureApprentissageSortV1 = Record
    Niveau:    String;
    CoutEP:    Integer;
    ModInt:    String;
    ModFM:     String;
    EchecAuto: String;
  end;

  TListApprentissageSortV1 = Specialize TList<StructureApprentissageSortV1>;

Var
  ListApprentissageSortV1: TListApprentissageSortV1;
  ListHandicapV1:       TListHandicapV1;
  ListTirageHandicapV1: TListTirageHandicapV1;
  ListAvancementPretreV1: TListAvancementPretreV1;
  ListFamilierV1:       TListFamilierV1;
  ListCulteV1:          TListCulteV1;
  ListPriereCulteV1:    TListPriereCulteV1;
  ListObjetV1:         TListObjetV1;
  ListGainMagieV1:    TListGainMagieV1;
  ListTirageCompV1:     TListTirageCompV1;
  ListAgeCompV1:        TListAgeCompV1;
  ListClasseV1:         TListClasseV1;
  ListArtisanMetier:    TListArtisanMetier;
  ListMetierAttribut:   TListMetierAttribut;
  NbMetierAttribut:     Integer;
  ListMetierAvance:     TListMetierAvance;
  ListMetierArgent:     TListMetierArgent;
  ListMetierSortie:     TListMetierSortie;
  ListMetierBase:       TListMetierBase;

// Plafond d'avances de la caracteristique pour la carriere ; 0 = la carriere n'en donne pas.
function PlafondAvanceMetier(CodeMetier, CodeAttribut: String): Integer;
// V2 : la carriere ouvre-t-elle sur celle-ci (sortie listee) ?
function EstSortieMetier(CodeMetier, CodeSortie: String): Boolean;
// V2 : la carriere est-elle une carriere de base (Table 3-2) ?
function EstMetierDeBase(CodeMetier: String): Boolean;
// V2 : formule d'argent de depart de la carriere ("15CO", "1d10CO"), '' si elle n'en donne pas.
function ArgentDepartMetier(CodeMetier: String): String;
// V2 : valeur d'un palier d'avance : 5 (%) pour les huit caracteristiques du profil principal, 1 sinon.
function PasAvanceV2(CodeAttribut: String): Integer;
// V1 et V2 : les avances de caracteristique suivent le schema de la carriere (plafond par attribut, 100 XP l avance)
function AvanceParSchema(): Boolean;
// Valeur d une avance : V1 = +10 (%) ou +1 (M, S, T, W, A), V2 = PasAvanceV2
function PasAvance(CodeAttribut: String): Integer;
// V1 : dés du gain de points de magie en entrant dans ce niveau (code RULES-WORK_WIZARD_2), '' si la carriere n'en donne pas.
function DesGainMagieV1(Espece, CodeMetier: String): String;
// V1 : table de handicaps de la carriere (DEMONOLOGIST, NECROMANCER, EVIL_CHAOTIC_WIZARD), '' si elle n'en donne pas.
// Mauvais = le magicien est marque mauvais / chaotique (seul le Wizard et ses specialistes sont concernes).
function TableHandicapV1(CodeMetier: String; Mauvais: Boolean): String;
// V1 : niveau du code de carriere (RULES-WORK_WIZARD_2 -> 2, sans numero -> 1)
function NiveauCarriereV1(CodeMetier: String): Integer;
// V1 : premier element d'une liste separee par des ';', retire de Reste
function ElementSuivantV1(var Reste: String): String;
// V1 : handicap de la table pour ce jet d100 ('' si aucun)
function HandicapDuJetV1(Table: String; Jet: Integer): String;
// V1 : handicap obtenu d'office en entrant au niveau 1 ('' si aucun)
function HandicapAutoV1(Table: String): String;
function ChercheHandicapV1(Code: String): StructureHandicapV1;
// V1 : table d'avancement de la carriere (CLERIC, DRUID), '' si ce n'est ni un Cleric ni un Druidic Priest
function TableAvancementPretreV1(CodeMetier: String): String;
// V1 : EP payes pour un jet sur la Cleric Advance Table de Realm of Divine Magic (100 x rang vise), 0 hors Priest
function CoutJetPretreV1(CodeMetier: String): Integer;
// V1 : code de la premiere priere REQUIRED du culte a ce rang (INITIATE, 1 a 4) que le personnage n'a pas encore, '' si toutes sont acquises
function PriereExigeeManquanteV1(Culte, Rang, SortsV1: String): String;
// V1 : ligne de la table pour ce jet d100 ; Resultat = '' si aucune
function AvancementPretreDuJetV1(Table: String; Jet: Integer): StructureAvancementPretreV1;
// V1 : familier de la table pour ce jet d100 (Code = '' si aucun)
function FamilierDuJetV1(Jet: Integer): StructureFamilierV1;
function ChercheFamilierV1(Code: String): StructureFamilierV1;
function ChercheCulteV1(Code: String): StructureCulteV1;
// V1 : vrai si la carriere est l'Initiate de Realm of Divine Magic (le joueur y choisit son culte)
function EstInitiateV1(CodeMetier: String): Boolean;
// V1 : rang de clerc dans la liste des prieres d'un culte ("INITIATE", "1" a "4"), '' si la carriere n'est ni Initiate ni Priest
function RangClercV1(CodeMetier: String): String;
function LibelleClasseV1(Code: String): String;
// V1 : metier de l'Artisan pour ce jet d100 (CodeMetier = '' si aucun)
function MetierArtisanDuJetV1(Jet: Integer): StructureArtisanMetier;
function ChercheObjetV1(Code: String): StructureObjetV1;
function LibelleEquipementV1(Code: String): String;
// V1 : vrai si l'objet (code EquipmentV1) est interdit par les strictures du familier (armes, armure, bouclier)
function ObjetInterditFamilierV1(const PFamilier: StructureFamilierV1; const CodeObjet: String): Boolean;
// V1 : "CODE=stade;CODE=stade;CODE=stade" -> augmente le stade du handicap (le cree au stade 1), 3 au maximum ; rend le nouveau stade
function AjouteHandicapV1(var Liste: String; Code: String): Integer;
// V1 : stade du handicap dans la liste, 0 s'il n'y est pas
function StadeHandicapV1(Liste, Code: String): Integer;
// V1 : malus appliques a la caracteristique par les handicaps de la liste (negatif ou nul)
function MalusHandicapsV1(Liste, CodeAttribut: String): Integer;
// V1 : regle d'apprentissage du sort de ce niveau ("P", "1".."4") ; CoutEP = 0 si le niveau est inconnu
function ApprentissageSortV1(Niveau: String): StructureApprentissageSortV1;
// V1 : seuil du test d'Intelligence pour apprendre un sort de ce niveau (modificateur applique avant le jet), 0 si impossible
function SeuilApprentissageSortV1(Niveau: String; Intelligence: Integer): Integer;
// V1 : le d100 donne-t-il un echec automatique pour ce niveau (96-100 pour Petty et niveau 1) ?
function EchecAutoApprentissageV1(Niveau: String; Jet: Integer): Boolean;
// V1 : sorts appris "CODE|source|cout;..." ; la source est un texte libre ('|' et ';' en sont retires)
function SortConnuV1(Liste, CodeSort: String): Boolean;
procedure AjouteSortV1(var Liste: String; CodeSort, Source: String; CoutEP: Integer);
// V1 : total des EP depenses en sorts appris
function CoutSortsV1(Liste: String): Integer;
// V1 : tentatives ratees "CODE|source|Int;..." ; un nouvel essai exige une autre source ou une Intelligence plus haute
function EssaiPossibleSortV1(Echecs, CodeSort, Source: String; Intelligence: Integer): Boolean;
procedure AjouteEchecSortV1(var Echecs: String; CodeSort, Source: String; Intelligence: Integer);
// V1 : ecole de magie d'un code de carriere (RULES-WORK_WIZARD_2 -> WIZARD), '' si la carriere n'est pas magique
function EcoleMagieV1(CodeMetier: String): String;
// V1 : listes de sorts d'une ecole, separees par des ';' (WIZARD -> Petty;Battle) ; '' pour Cleric / Druidic Priest (sorts par intervention divine)
function ListesSortsEcoleV1(Ecole: String): String;


implementation

uses
  UnitCalcul;

function DesGainMagieV1(Espece, CodeMetier: String): String;
var
  PGain:  StructureGainMagieV1;
  Base:   String;
  Niveau: Integer;
  Pos_:   Integer;
begin
  Result := '';
  Base   := CodeMetier;
  Niveau := 1;
  Pos_   := LastDelimiter('_', CodeMetier);
  if (Pos_ > 0) and (StrToIntDef(Copy(CodeMetier, Pos_ + 1, 5), 0) > 0) then
    begin
      Niveau := StrToInt(Copy(CodeMetier, Pos_ + 1, 5));
      Base   := Copy(CodeMetier, 1, Pos_ - 1);
    end;
  for PGain in ListGainMagieV1 do
    if CompareRechercheValeur(PGain.Carriere, Base) and (Niveau >= PGain.NiveauMin) and (Niveau <= PGain.NiveauMax) and
       ((PGain.Espece = 'ALL') or CompareRechercheValeur(PGain.Espece, Espece) or
        // le livre dit "Human", l'espece du perso est RULES-SPECIE_HUMAN
        (UpperCase(RightStr(Espece, Length(PGain.Espece) + 1)) = '_' + UpperCase(PGain.Espece))) then
      Exit(PGain.Des);
end;

// Prend le premier element d'une liste separee par des ';' et le retire de Reste.
function ElementSuivantV1(var Reste: String): String;
var
  P: Integer;
begin
  P := Pos(';', Reste);
  if P = 0 then
    begin
      Result := Reste;
      Reste  := '';
    end
  else
    begin
      Result := Copy(Reste, 1, P - 1);
      Delete(Reste, 1, P);
    end;
end;

function NiveauCarriereV1(CodeMetier: String): Integer;
var
  Pos_: Integer;
begin
  Result := 1;
  Pos_   := LastDelimiter('_', CodeMetier);
  if (Pos_ > 0) and (StrToIntDef(Copy(CodeMetier, Pos_ + 1, 5), 0) > 0) then
    Result := StrToInt(Copy(CodeMetier, Pos_ + 1, 5));
end;

function TableHandicapV1(CodeMetier: String; Mauvais: Boolean): String;
begin
  Result := '';
  if Pos('_DEMONOLOGIST', UpperCase(CodeMetier)) > 0 then
    Result := 'DEMONOLOGIST'
  else if Pos('_NECROMANCER', UpperCase(CodeMetier)) > 0 then
    Result := 'NECROMANCER'
  else if Mauvais and (Pos('_WORK_', UpperCase(CodeMetier)) > 0) and
          (Pos('_CLERIC', UpperCase(CodeMetier)) = 0) and (Pos('_DRUIDIC', UpperCase(CodeMetier)) = 0) and
          (Pos('_ALCHEMIST', UpperCase(CodeMetier)) = 0) and
          (Pos('_WIZARD', UpperCase(CodeMetier)) + Pos('_ELEMENTALIST', UpperCase(CodeMetier)) + Pos('_ILLUSIONIST', UpperCase(CodeMetier)) > 0) then
    Result := 'EVIL_CHAOTIC_WIZARD';
end;

function HandicapDuJetV1(Table: String; Jet: Integer): String;
var
  PTirage: StructureTirageHandicapV1;
begin
  Result := '';
  for PTirage in ListTirageHandicapV1 do
    if (not PTirage.Auto) and (PTirage.Table = Table) and (Jet >= PTirage.Min) and (Jet <= PTirage.Max) then
      Exit(PTirage.Code);
end;

function HandicapAutoV1(Table: String): String;
var
  PTirage: StructureTirageHandicapV1;
begin
  Result := '';
  for PTirage in ListTirageHandicapV1 do
    if PTirage.Auto and (PTirage.Table = Table) then
      Exit(PTirage.Code);
end;

function TableAvancementPretreV1(CodeMetier: String): String;
begin
  Result := '';
  if Pos('_CLERIC', UpperCase(CodeMetier)) > 0 then
    Result := 'CLERIC'
  else if Pos('_DRUIDIC', UpperCase(CodeMetier)) > 0 then
    Result := 'DRUID'
  else if Pos('WRDM-WORK_PRIEST_', UpperCase(CodeMetier)) = 1 then
    Result := 'PRIEST';
end;

function CoutJetPretreV1(CodeMetier: String): Integer;
begin
  Result := 0;
  if TableAvancementPretreV1(CodeMetier) = 'PRIEST' then
    Result := 100 * NiveauCarriereV1(CodeMetier);
end;

function PriereExigeeManquanteV1(Culte, Rang, SortsV1: String): String;
var
  PPriere: StructurePriereCulteV1;
begin
  Result := '';
  for PPriere in ListPriereCulteV1 do
    if (PPriere.Culte = Culte) and (PPriere.Rang = Rang) and (PPriere.Genre = 'REQUIRED') and
       not SortConnuV1(SortsV1, PPriere.CodePriere) then
      Exit(PPriere.CodePriere);
end;

function AvancementPretreDuJetV1(Table: String; Jet: Integer): StructureAvancementPretreV1;
var
  PLigne: StructureAvancementPretreV1;
begin
  Result := Default(StructureAvancementPretreV1);
  for PLigne in ListAvancementPretreV1 do
    if (PLigne.Table = Table) and (Jet >= PLigne.Min) and (Jet <= PLigne.Max) then
      Exit(PLigne);
end;

function FamilierDuJetV1(Jet: Integer): StructureFamilierV1;
var
  PFamilier: StructureFamilierV1;
begin
  Result := Default(StructureFamilierV1);
  for PFamilier in ListFamilierV1 do
    if (Jet >= PFamilier.Min) and (Jet <= PFamilier.Max) then
      Exit(PFamilier);
end;

function ChercheFamilierV1(Code: String): StructureFamilierV1;
var
  PFamilier: StructureFamilierV1;
begin
  Result := Default(StructureFamilierV1);
  for PFamilier in ListFamilierV1 do
    if PFamilier.Code = Code then
      Exit(PFamilier);
end;

function ChercheCulteV1(Code: String): StructureCulteV1;
var
  PCulte: StructureCulteV1;
begin
  Result := Default(StructureCulteV1);
  for PCulte in ListCulteV1 do
    if PCulte.Code = Code then
      Exit(PCulte);
end;

function EstInitiateV1(CodeMetier: String): Boolean;
begin
  Result := UpperCase(CodeMetier) = 'WRDM-WORK_INITIATE';
end;

function RangClercV1(CodeMetier: String): String;
begin
  Result := '';
  if EstInitiateV1(CodeMetier) then
    Result := 'INITIATE'
  else if TableAvancementPretreV1(CodeMetier) = 'PRIEST' then
    Result := IntToStr(NiveauCarriereV1(CodeMetier));
end;

function LibelleClasseV1(Code: String): String;
var
  PClasse: StructureClasseV1;
begin
  Result := '';
  for PClasse in ListClasseV1 do
    if PClasse.CodeClasse = Code then
      Exit(PClasse.Libelle);
end;

function MetierArtisanDuJetV1(Jet: Integer): StructureArtisanMetier;
var
  PMetier:   StructureArtisanMetier;
  P, Bas, Haut: Integer;
begin
  Result := Default(StructureArtisanMetier);
  for PMetier in ListArtisanMetier do
    begin
      P := Pos('-', PMetier.Tirage);
      if P > 0 then
        begin
          Bas  := StrToIntDef(Copy(PMetier.Tirage, 1, P - 1), 0);
          Haut := StrToIntDef(Copy(PMetier.Tirage, P + 1, MaxInt), 0);
        end
      else
        begin
          Bas  := StrToIntDef(PMetier.Tirage, 0);
          Haut := Bas;
        end;
      if Haut = 0 then Haut := 100;
      if (Jet >= Bas) and (Jet <= Haut) then
        Exit(PMetier);
    end;
end;

function ChercheObjetV1(Code: String): StructureObjetV1;
var
  PObjet: StructureObjetV1;
begin
  Result := Default(StructureObjetV1);
  for PObjet in ListObjetV1 do
    if PObjet.Code = Code then
      Exit(PObjet);
end;

// Equipement de carriere V1 : le code RULES-EQUIP_... / BOTR-EQUIP_... est un EquipmentV1 de la
// liste de prix ; on affiche son libelle. Texte libre ("2D10 leaflets...") ou code inconnu : tel quel.
function LibelleEquipementV1(Code: String): String;
var
  Libelle: String;
begin
  Libelle := ChercheObjetV1(Code).Libelle;
  if Libelle <> '' then
    Result := Libelle
  else
    Result := Code;
end;

// Classement des armes selon les mots du livre (Core p.206) : le livre ne dit pas quelle arme est contondante
// ou tranchante, la liste ci-dessous est notre lecture (a faire valider par Nono)
function ObjetInterditFamilierV1(const PFamilier: StructureFamilierV1; const CodeObjet: String): Boolean;
  function Contient(const Mots: array of String): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to High(Mots) do
      if Pos(Mots[I], CodeObjet) > 0 then
        Exit(True);
  end;
var
  PObjet: StructureObjetV1;
begin
  Result := False;
  PObjet := ChercheObjetV1(CodeObjet);
  if PObjet.Code = '' then Exit;
  // categories : le livre peut donner le mot (WEAPON) ou le code (RULES-V1CAT_WEAPON)
  if ValeurLivreEgale(PObjet.Categorie, 'WEAPON') then
    begin
      if ValeurLivreEgale(PObjet.SousCategorie, 'MELEE') and Contient(['BUCKLER']) then
        Exit(not PFamilier.Bouclier);
      if (Pos('2-h', PFamilier.ArmesInterdites) > 0) and Contient(['TWO_HANDED', 'HALBERD']) then
        Exit(True);
      if (Pos('firearms', PFamilier.ArmesInterdites) > 0) and ValeurLivreEgale(PObjet.SousCategorie, 'FIREARM') then
        Exit(True);
      if (Pos('missile', PFamilier.ArmesInterdites) > 0) and ValeurLivreEgale(PObjet.SousCategorie, 'MISSILE') then
        Exit(True);
      if (Pos('blunt', PFamilier.ArmesInterdites) > 0) and ValeurLivreEgale(PObjet.SousCategorie, 'MELEE')
         and Contient(['CLUB', 'MACE', 'FLAIL', 'MORNING_STAR', 'WARHAMMER', 'KNUCKLE_DUSTER', 'QUARTER_STAFF']) then
        Exit(True);
      if (Pos('sharp', PFamilier.ArmesInterdites) > 0) and ValeurLivreEgale(PObjet.SousCategorie, 'MELEE')
         and Contient(['SWORD', 'AXE', 'DAGGER', 'CUTLASS', 'FOIL', 'RAPIER', 'SPEAR', 'HALBERD', 'LANCE', 'PICK']) then
        Exit(True);
    end
  else if ValeurLivreEgale(PObjet.Categorie, 'ARMOUR') then
    begin
      if Contient(['SHIELD']) then
        Exit(not PFamilier.Bouclier);
      if ValeurLivreEgale(PFamilier.Armure, 'None') then
        Exit(True);
      if ValeurLivreEgale(PFamilier.Armure, 'Leather') then
        Exit(not Contient(['LEATHER']));
    end;
end;

function ChercheHandicapV1(Code: String): StructureHandicapV1;
var
  PHandicap: StructureHandicapV1;
begin
  Result := Default(StructureHandicapV1);
  for PHandicap in ListHandicapV1 do
    if PHandicap.Code = Code then
      Exit(PHandicap);
end;

function StadeHandicapV1(Liste, Code: String): Integer;
var
  Reste: String;
  Item:  String;
  P:     Integer;
begin
  Result := 0;
  Reste  := Liste;
  while Reste <> '' do
    begin
      Item := ElementSuivantV1(Reste);
      P    := Pos('=', Item);
      if (P > 0) and (Copy(Item, 1, P - 1) = Code) then
        Exit(StrToIntDef(Copy(Item, P + 1, 3), 0));
    end;
end;

function AjouteHandicapV1(var Liste: String; Code: String): Integer;
var
  Reste:   String;
  Item:    String;
  Nouvelle: String;
  P:       Integer;
begin
  Result   := StadeHandicapV1(Liste, Code) + 1;
  if Result > 3 then
    Result := 3;
  Nouvelle := '';
  Reste    := Liste;
  while Reste <> '' do
    begin
      Item := ElementSuivantV1(Reste);
      P    := Pos('=', Item);
      if (P > 0) and (Copy(Item, 1, P - 1) <> Code) then
        Nouvelle := Nouvelle + Item + ';';
    end;
  Liste := Nouvelle + Code + '=' + IntToStr(Result);
end;

function MalusHandicapsV1(Liste, CodeAttribut: String): Integer;
var
  Reste:     String;
  Item:      String;
  Mod_:      String;
  PHandicap: StructureHandicapV1;
  P:         Integer;
  Stade:     Integer;
begin
  Result := 0;
  Reste  := Liste;
  while Reste <> '' do
    begin
      Item := ElementSuivantV1(Reste);
      P    := Pos('=', Item);
      if P = 0 then Continue;
      Stade := StrToIntDef(Copy(Item, P + 1, 3), 0);
      if (Stade < 1) or (Stade > 3) then Continue;
      PHandicap := ChercheHandicapV1(Copy(Item, 1, P - 1));
      Mod_      := PHandicap.Modif[Stade];
      while Mod_ <> '' do
        begin
          Item := ElementSuivantV1(Mod_);
          P    := Pos('=', Item);
          if (P > 0) and CompareRechercheValeur(Copy(Item, 1, P - 1), CodeAttribut) then
            Result := Result + StrToIntDef(StringReplace(Copy(Item, P + 1, 10), '+', '', []), 0);
        end;
    end;
end;

function ApprentissageSortV1(Niveau: String): StructureApprentissageSortV1;
var
  PRegle: StructureApprentissageSortV1;
begin
  Result := Default(StructureApprentissageSortV1);
  for PRegle in ListApprentissageSortV1 do
    if ValeurLivreEgale(PRegle.Niveau, Niveau) then   // mot (Master) ou code (RULES-V1LEVEL_MASTER)
      Exit(PRegle);
end;

function SeuilApprentissageSortV1(Niveau: String; Intelligence: Integer): Integer;
var
  PRegle: StructureApprentissageSortV1;
begin
  PRegle := ApprentissageSortV1(Niveau);
  Result := 0;
  if PRegle.CoutEP = 0 then Exit;
  if Copy(PRegle.ModInt, 1, 1) = 'x' then
    Result := Intelligence * StrToIntDef(Copy(PRegle.ModInt, 2, 3), 1)
  else
    Result := Intelligence + StrToIntDef(StringReplace(PRegle.ModInt, '+', '', []), 0);
  if Result < 0 then Result := 0;
end;

function EchecAutoApprentissageV1(Niveau: String; Jet: Integer): Boolean;
var
  Plage: String;
  P:     Integer;
begin
  Plage  := ApprentissageSortV1(Niveau).EchecAuto;
  P      := Pos('-', Plage);
  Result := (P > 0) and (Jet >= StrToIntDef(Copy(Plage, 1, P - 1), 101)) and
            (Jet <= StrToIntDef(Copy(Plage, P + 1, 5), 0));
end;

function SourceNettoyeeV1(Source: String): String;
begin
  Result := Trim(StringReplace(StringReplace(Source, '|', ' ', [rfReplaceAll]), ';', ',', [rfReplaceAll]));
end;

function SortConnuV1(Liste, CodeSort: String): Boolean;
var
  Reste: String;
  Item:  String;
begin
  Result := False;
  Reste  := Liste;
  while Reste <> '' do
    begin
      Item := ElementSuivantV1(Reste);
      if Copy(Item, 1, Pos('|', Item + '|') - 1) = CodeSort then
        Exit(True);
    end;
end;

procedure AjouteSortV1(var Liste: String; CodeSort, Source: String; CoutEP: Integer);
begin
  if SortConnuV1(Liste, CodeSort) then Exit;
  if Liste <> '' then Liste := Liste + ';';
  Liste := Liste + CodeSort + '|' + SourceNettoyeeV1(Source) + '|' + IntToStr(CoutEP);
end;

function CoutSortsV1(Liste: String): Integer;
var
  Reste:  String;
  Champs: TStringArray;
begin
  Result := 0;
  Reste  := Liste;
  while Reste <> '' do
    begin
      Champs := ElementSuivantV1(Reste).Split('|');
      if Length(Champs) >= 3 then
        Result := Result + StrToIntDef(Champs[2], 0);
    end;
end;

function EssaiPossibleSortV1(Echecs, CodeSort, Source: String; Intelligence: Integer): Boolean;
var
  Reste:  String;
  Item:   String;
  Champs: TStringArray;
begin
  Result := True;
  Reste  := Echecs;
  while Reste <> '' do
    begin
      Item   := ElementSuivantV1(Reste);
      Champs := Item.Split('|');
      if (Length(Champs) >= 3) and (Champs[0] = CodeSort) and
         (LowerCase(Champs[1]) = LowerCase(SourceNettoyeeV1(Source))) and
         (Intelligence <= StrToIntDef(Champs[2], 0)) then
        Exit(False);
    end;
end;

procedure AjouteEchecSortV1(var Echecs: String; CodeSort, Source: String; Intelligence: Integer);
begin
  if Echecs <> '' then Echecs := Echecs + ';';
  Echecs := Echecs + CodeSort + '|' + SourceNettoyeeV1(Source) + '|' + IntToStr(Intelligence);
end;

function EcoleMagieV1(CodeMetier: String): String;
const
  Ecoles: array[1..8] of String = ('ALCHEMIST', 'WIZARD', 'DEMONOLOGIST', 'ELEMENTALIST', 'ILLUSIONIST', 'NECROMANCER', 'CLERIC', 'DRUIDIC_PRIEST');
  EcolesCouleurV1: array[1..8] of String = ('BRIGHT', 'GOLD', 'JADE', 'LIGHT', 'AMBER', 'AMETHYST', 'CELESTIAL', 'GREY');
var
  I:    Integer;
  Code: String;
begin
  Result := '';
  Code   := UpperCase(CodeMetier);
  // Realms of Sorcery : colleges de couleur (BRIGHT_WIZARD_4...), Shaman de Kislev, mage elfe sylvain
  for I := Low(EcolesCouleurV1) to High(EcolesCouleurV1) do
    if Pos('_' + EcolesCouleurV1[I] + '_WIZARD_', Code) > 0 then
      Exit(EcolesCouleurV1[I]);
  if Pos('WORK_HEDGE_WIZARD', Code) > 0 then Exit('HEDGE');
  if Pos('WORK_KISLEVITE_SHAMAN', Code) > 0 then Exit('ICE');
  if Pos('WORK_WOOD_ELF_MAGE_', Code) > 0 then Exit('TREE_SONG');
  if (Pos('WORK_RUNESMITH', Code) > 0) or (Pos('WORK_RUNE_MASTER', Code) > 0) then Exit('RUNESMITH');
  for I := Low(Ecoles) to High(Ecoles) do
    if (Pos('WORK_' + Ecoles[I] + '_', Code) > 0) or (Copy(Code, Length(Code) - Length(Ecoles[I]), 99) = '_' + Ecoles[I]) then
      Exit(Ecoles[I]);
end;

function ListesSortsEcoleV1(Ecole: String): String;
begin
  Result := '';
  if Ecole = 'ALCHEMIST' then Result := 'Petty;Battle;Alchemy'
  // Hedge-Wizard : toutes les disciplines sauf Colour et High (Realms of Sorcery p.30)
  else if Ecole = 'HEDGE' then Result := 'Petty;Battle;Demonic;Elemental;Illusion;Necromantic;Alchemy;Ice;Tree Song'
  else if Ecole = 'ICE' then Result := 'Petty;Ice'
  else if Ecole = 'TREE_SONG' then Result := 'Petty;Tree Song'
  else if Ecole = 'RUNESMITH' then Result := 'Rune'
  else if (Ecole = 'BRIGHT') or (Ecole = 'GOLD') or (Ecole = 'JADE') or (Ecole = 'LIGHT') or
          (Ecole = 'AMBER') or (Ecole = 'AMETHYST') or (Ecole = 'CELESTIAL') or (Ecole = 'GREY') then
    Result := 'Petty;Battle;' + UpperCase(Copy(Ecole, 1, 1)) + LowerCase(Copy(Ecole, 2, 99))
  else if Ecole = 'WIZARD' then Result := 'Petty;Battle'
  else if Ecole = 'DEMONOLOGIST' then Result := 'Petty;Battle;Demonic'
  else if Ecole = 'ELEMENTALIST' then Result := 'Petty;Battle;Elemental'
  else if Ecole = 'ILLUSIONIST' then Result := 'Petty;Battle;Illusion'
  else if Ecole = 'NECROMANCER' then Result := 'Petty;Battle;Necromantic';
end;

function PlafondAvanceMetier(CodeMetier, CodeAttribut: String): Integer;
var
  PAvance: StructureMetierAvance;
begin
  Result := 0;
  for PAvance in ListMetierAvance do
    if CompareRechercheValeur(PAvance.CodeMetier, CodeMetier) and
       CompareRechercheValeur(PAvance.CodeAttribut, CodeAttribut) then
      Exit(PAvance.Plafond);
end;

function EstSortieMetier(CodeMetier, CodeSortie: String): Boolean;
var
  PSortie: StructureMetierSortie;
begin
  Result := False;
  for PSortie in ListMetierSortie do
    if CompareRechercheValeur(PSortie.CodeMetier, CodeMetier) and
       CompareRechercheValeur(PSortie.CodeSortie, CodeSortie) then
      Exit(True);
end;

function EstMetierDeBase(CodeMetier: String): Boolean;
var
  PBase: StructureMetierBase;
begin
  Result := False;
  for PBase in ListMetierBase do
    if CompareRechercheValeur(PBase.CodeMetier, CodeMetier) then
      Exit(True);
end;

function ArgentDepartMetier(CodeMetier: String): String;
var
  PArgent: StructureMetierArgent;
begin
  Result := '';
  for PArgent in ListMetierArgent do
    if CompareRechercheValeur(PArgent.CodeMetier, CodeMetier) then
      Exit(PArgent.Formule);
end;

function PasAvanceV2(CodeAttribut: String): Integer;
const
  Principal: array[0..7] of String = ('_WS', '_BS', '_S', '_T', '_Ag', '_Int', '_WP', '_Fel');
var
  I: Integer;
begin
  Result := 1;
  for I := 0 to 7 do
    if Copy(CodeAttribut, Length(CodeAttribut) - Length(Principal[I]) + 1, 9) = Principal[I] then
      Exit(5);
end;

function AvanceParSchema(): Boolean;
begin
  Result := (ValVersion = 'WFRP2') or (ValVersion = 'WFRP1');
end;

function PasAvance(CodeAttribut: String): Integer;
const
  Entiers: array[0..4] of String = ('_M', '_S', '_T', '_W', '_A');
var
  I: Integer;
begin
  if ValVersion <> 'WFRP1' then
    Exit(PasAvanceV2(CodeAttribut));
  Result := 10;
  for I := 0 to 4 do
    if Copy(CodeAttribut, Length(CodeAttribut) - Length(Entiers[I]) + 1, 9) = Entiers[I] then
      Exit(1);
end;

end.


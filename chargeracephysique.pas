unit ChargeRacePhysique;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Math, ChargeConstantes, Generics.Collections, UnitCalcul, ChargeRace;

// Details physiques d'une RACE (bloc SUBCHAPTER_PHYSICAL de DATA_RACE) : formule d'age,
// formule de taille en POUCES, et tables de couleur des yeux et des cheveux (2d10).
// CONTEXT.md, chantier "details physiques par ethnie".
Type
  StructureRacePhysique         = record
    CodeRace:                   String;
    Livre:                      String;
    FormuleAge:                 String;
    FormuleTaille:              String;
    // Taille humaine : si l'un des des fait 10, on relance un de et on l'ajoute.
    TailleExplose:              Boolean;
    // Nombre de tirages sur la table des yeux (2 pour les Elfes : couleurs panachees).
    NbTirageYeux:               Integer;
  end;

  StructureRaceCouleur          = record
    CodeRace:                   String;
    Livre:                      String;
    EstYeux:                    Boolean;   // True = yeux, False = cheveux
    Libelle:                    String;    // texte anglais brut, non traduit pour l'instant
    Plage:                      String;    // "2", "5-7"...
  end;

  // Noms d'une ethnie (bloc SUBCHAPTER_NAMES) : une entree de table (Partie = "First", "Forename"...,
  // Sexe = M / F / vide, Plage = tranche du de) et un modele d'assemblage ("First+Second?+End").
  StructureRaceNom              = record
    CodeRace:                   String;
    Livre:                      String;
    Partie:                     String;
    Sexe:                       String;
    Libelle:                    String;
    Plage:                      String;
  end;

  StructureRaceNomModele        = record
    CodeRace:                   String;
    Livre:                      String;
    Sexe:                       String;
    Modele:                     String;
    Regle:                      String;    // code de la regle de nom qui reserve ce modele ('' = ordinaire)
  end;

  StructureRaceNomRegle         = record
    CodeRace:                   String;
    Livre:                      String;
    Code:                       String;
    Libelle:                    String;    // id de libelle (INTERFACE) ou texte brut
  end;

  // Tables de details personnels V2 d'une race (Core V2 tables 2-6 a 2-17). Table = nom de la balise XML
  // (HeightFemale, HeightMale : Plage = formule en pouces ; Weight, AgeRoll, Siblings, Birthplace,
  // BirthplaceSettlement : Libelle = resultat, Plage = tranche du de ; BirthplaceHuman : Plage seule).
  StructureRaceDetailV2         = record
    CodeRace:                   String;
    Livre:                      String;
    Table:                      String;
    Libelle:                    String;
    Plage:                      String;
  end;

  // Table commune a toutes les races (signes distinctifs, signes astraux V2) : Entry name=Libelle detail=Detail.
  StructureTablePersonnelle     = record
    Livre:                      String;
    CodeTable:                  String;
    Libelle:                    String;
    Detail:                     String;
    Plage:                      String;
  end;

  // Resultat d'un tirage complet des details personnels V2 (taille en pouces, poids en livres).
  StructureDetailsV2            = record
    Age, Taille, Poids, Fratrie: Integer;
    Yeux, Cheveux, Signe, SigneAstral, Naissance: String;
  end;

  TListRaceDetailV2      = Specialize TList<StructureRaceDetailV2>;
  TListTablePersonnelle  = Specialize TList<StructureTablePersonnelle>;
  TListRacePhysique = Specialize TList<StructureRacePhysique>;
  TListRaceCouleur  = Specialize TList<StructureRaceCouleur>;
  TListRaceNom      = Specialize TList<StructureRaceNom>;
  TListRaceNomModele = Specialize TList<StructureRaceNomModele>;
  TListRaceNomRegle  = Specialize TList<StructureRaceNomRegle>;

Var
  ListRacePhysique:   TListRacePhysique;
  ListRaceCouleur:    TListRaceCouleur;
  NbRacePhysique:     Integer;
  ListRaceDetailV2:   TListRaceDetailV2;
  ListTablePersonnelle: TListTablePersonnelle;
  NbRaceCouleur:      Integer;
  ListRaceNom:        TListRaceNom;
  ListRaceNomModele:  TListRaceNomModele;
  ListRaceNomRegle:   TListRaceNomRegle;
  NbRaceNom:          Integer;
  NbRaceNomModele:    Integer;

function ChercheRacePhysique(CodeRace: String): StructureRacePhysique;
function RaceSourcePhysique(CodeRace: String): String;
function LanceFormule(Formule: String; Explose: Boolean): Integer;
function EffetsNaissanceRace(CodeRace, Naissance: String): String;
function EffetsParticulariteRace(CodeRace, Particularite: String): String;
procedure TireFamilierV2(CodeRace: String; Formes, Particularites: TStringList; out Effets: String);
function RaceATirageFamilier(CodeRace: String): Boolean;
procedure ListeLignesFamilier(CodeRace, Table: String; Lignes: TStrings);
function RaceAClan(CodeRace: String): Boolean;
function RaceAMutationDepart(CodeRace: String): Boolean;
procedure ListeClansRace(CodeRace: String; Clans: TStringList);
function ClanRaceParJet(CodeRace: String; Jet: Integer): String;
function TireClanRace(CodeRace: String; out Jet: Integer): String;
function TireCouleur(CodeRace: String; Yeux: Boolean; Jet: Integer): String;
function TireDetailsPhysiques(CodeRace: String; out Age: Integer; out Taille: Integer;
                              out Yeux: String; out Cheveux: String): Boolean;
function EstTableDetailV2(NomBalise: String): Boolean;
function TireDetailsV2(CodeRace: String; Femme: Boolean; out Details: StructureDetailsV2): Boolean;
function ChampPhysique(CodeRace, Champ: String; Femme: Boolean; var Jets: String): String;
function ConvertitTaille(Valeur: Integer; DeUnite, VersUnite: String): Integer;
function FormateTaille(Valeur: Integer; Unite: String): String;
function EthnieANoms(CodeRace: String): Boolean;
function RaceSourceNom(CodeRace, Partie: String): String;
function RaceANoms(CodeRace: String): Boolean;
function TireNom(CodeRace, Sexe: String; Regle: String = ''): String;
function TireNomJets(CodeRace, Sexe, Regle: String; var Jets: String): String;
procedure ReglesNomRace(CodeRace: String; Liste: TStringList);

implementation

function ChercheRacePhysique(CodeRace: String): StructureRacePhysique;
var
  PRacePhysique: StructureRacePhysique;
begin
  // Voir ChercheRaceAttribut : Result n'est pas initialise par Pascal (CONTEXT.md 2.17).
  Result := Default(StructureRacePhysique);
  for PRacePhysique in ListRacePhysique do
    if CompareRechercheValeur(PRacePhysique.CodeRace, CodeRace) then
      begin
        Result := PRacePhysique;
        break;
      end;
end;

// Code de la RACE dont on lit les details physiques : ils sont portes par la race (bloc DATA_RACE), pas par une
// ethnie. Une ethnie tire ceux de sa race (champ Espece) ; un code de race donne directement est accepte.
// '' si rien n'est trouve.
function RaceSourcePhysique(CodeRace: String): String;
var
  Espece: String;
begin
  Result := '';
  if ChercheRacePhysique(CodeRace).CodeRace <> '' then
    begin
      Result := CodeRace;
      Exit;
    end;
  Espece := Trim(ChercheRace(CodeRace).Espece);
  if (Espece <> '') and (ChercheRacePhysique(Espece).CodeRace <> '') then
    Result := Espece;
end;

// Evalue une formule "15+10d10", "57+2d10", "51+d10" : termes separes par '+', chacun soit
// une constante, soit [N]dM. Si Explose et qu'un de montre sa valeur maximale, UN de
// supplementaire est lance et ajoute (regle du Rulebook p.40 pour la taille humaine).
function LanceFormule(Formule: String; Explose: Boolean): Integer;
var
  Termes:       TStringList;
  I, J, PosD:   Integer;
  Terme:        String;
  NbDes, Faces: Integer;
  Jet:          Integer;
  Maxi:         Boolean;
begin
  Result := 0;
  Maxi   := False;
  Termes := TStringList.Create;
  try
    ExtractStrings(['+'], [' '], PChar(Formule), Termes);
    for I := 0 to Termes.Count - 1 do
      begin
        Terme := LowerCase(Trim(Termes[I]));
        PosD  := Pos('d', Terme);
        if PosD = 0 then
          Result := Result + StrToIntDef(Terme, 0)
        else
          begin
            NbDes := StrToIntDef(Copy(Terme, 1, PosD - 1), 1);
            Faces := StrToIntDef(Copy(Terme, PosD + 1, MaxInt), 0);
            if Faces < 1 then
              Continue;
            for J := 1 to NbDes do
              begin
                Jet    := Random(Faces) + 1;
                Result := Result + Jet;
                if Jet = Faces then
                  Maxi := True;
              end;
            if Explose and Maxi then
              begin
                Result := Result + Random(Faces) + 1;
                Maxi   := False;
              end;
          end;
      end;
  finally
    Termes.Free;
  end;
end;

// Libelle de la ligne dont la plage ("2", "5-7") contient Jet, pour les yeux ou les cheveux.
function TireCouleur(CodeRace: String; Yeux: Boolean; Jet: Integer): String;
var
  PRaceCouleur: StructureRaceCouleur;
  Bas, Haut:    Integer;
  Tiret:        Integer;
begin
  Result := '';
  for PRaceCouleur in ListRaceCouleur do
    if CompareRechercheValeur(PRaceCouleur.CodeRace, CodeRace) and (PRaceCouleur.EstYeux = Yeux) then
      begin
        Tiret := Pos('-', PRaceCouleur.Plage);
        if Tiret = 0 then
          begin
            Bas  := StrToIntDef(PRaceCouleur.Plage, 0);
            Haut := Bas;
          end
        else
          begin
            Bas  := StrToIntDef(Copy(PRaceCouleur.Plage, 1, Tiret - 1), 0);
            Haut := StrToIntDef(Copy(PRaceCouleur.Plage, Tiret + 1, MaxInt), 0);
          end;
        if (Jet >= Bas) and (Jet <= Haut) then
          begin
            Result := PRaceCouleur.Libelle;
            Exit;
          end;
      end;
end;

// Tire age, taille (en pouces), yeux et cheveux d'une ethnie. Faux si l'ethnie n'a aucune
// donnee physique (rien n'est alors modifie). Les yeux des Elfes (NbTirageYeux = 2) sont
// les deux couleurs separees par " / ".
function TireDetailsPhysiques(CodeRace: String; out Age: Integer; out Taille: Integer;
                              out Yeux: String; out Cheveux: String): Boolean;
var
  PRacePhysique: StructureRacePhysique;
  I:             Integer;
  Couleur:       String;
begin
  Age     := 0;
  Taille  := 0;
  Yeux    := '';
  Cheveux := '';
  CodeRace      := RaceSourcePhysique(CodeRace);
  PRacePhysique := ChercheRacePhysique(CodeRace);
  Result := PRacePhysique.CodeRace <> '';
  if not Result then
    Exit;
  Age    := LanceFormule(PRacePhysique.FormuleAge, False);
  Taille := LanceFormule(PRacePhysique.FormuleTaille, PRacePhysique.TailleExplose);
  for I := 1 to PRacePhysique.NbTirageYeux do
    begin
      Couleur := TireCouleur(CodeRace, True, LanceFormule('2d10', False));
      if Couleur <> '' then
        begin
          if Yeux <> '' then
            Yeux := Yeux + ' / ';
          Yeux := Yeux + Couleur;
        end;
    end;
  Cheveux := TireCouleur(CodeRace, False, LanceFormule('2d10', False));
end;

// Balises V2 du bloc SUBCHAPTER_PHYSICAL qui se rangent dans ListRaceDetailV2.
function EstTableDetailV2(NomBalise: String): Boolean;
begin
  Result := (NomBalise = ConstXmlPhysTailleFemme) or (NomBalise = ConstXmlPhysTailleHomme)
         or (NomBalise = ConstXmlPhysPoids) or (NomBalise = ConstXmlPhysAge)
         or (NomBalise = ConstXmlPhysFratrie) or (NomBalise = ConstXmlPhysNaissance)
         or (NomBalise = ConstXmlPhysLocalite) or (NomBalise = ConstXmlPhysNaissanceHumaine)
         or (NomBalise = ConstXmlPhysNaissanceEffet) or (NomBalise = ConstXmlPhysParticulariteEffet)
         or (NomBalise = ConstXmlPhysForme) or (NomBalise = ConstXmlPhysFormeAnimal) or (NomBalise = ConstXmlPhysParticularite);
end;

// Une plage du livre ("01-05", "00", "99-00", "2-3", "10") contient-elle le jet ? 00 = 100.
function PlageV2(Plage: String; Jet: Integer): Boolean;
var
  Tiret, Bas, Haut: Integer;
begin
  Tiret := Pos('-', Plage);
  if Tiret = 0 then
    begin
      Bas  := StrToIntDef(Plage, -1);
      Haut := Bas;
    end
  else
    begin
      Bas  := StrToIntDef(Copy(Plage, 1, Tiret - 1), -1);
      Haut := StrToIntDef(Copy(Plage, Tiret + 1, MaxInt), -1);
    end;
  if Bas = 0 then
    Bas := 100;
  if Haut = 0 then
    Haut := 100;
  Result := (Jet >= Bas) and (Jet <= Haut);
end;

// Resultat (Libelle) de la table d'une race dont la plage contient le jet ; '' si aucune.
function TireTableRace(CodeRace, Table: String; Jet: Integer): String;
var
  PDetail: StructureRaceDetailV2;
begin
  Result := '';
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = Table) and CompareRechercheValeur(PDetail.CodeRace, CodeRace)
       and PlageV2(PDetail.Plage, Jet) then
      Exit(PDetail.Libelle);
end;

function TableRaceExiste(CodeRace, Table: String): Boolean;
var
  PDetail: StructureRaceDetailV2;
begin
  Result := False;
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = Table) and CompareRechercheValeur(PDetail.CodeRace, CodeRace) then
      Exit(True);
end;

// Formule d'une balise a contenu seul (HeightFemale...), '' si la race ne l'a pas.
function FormuleRaceV2(CodeRace, Table: String): String;
var
  PDetail: StructureRaceDetailV2;
begin
  Result := '';
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = Table) and CompareRechercheValeur(PDetail.CodeRace, CodeRace) then
      Exit(PDetail.Plage);
end;

// Effets structures du lieu de naissance (clan Skaven) : liste "Skill:CODE;Talent:CODE;Item:CODE" de la
// ligne BirthplaceEffect dont le nom est celui du texte de naissance ; '' si la race n'en declare pas.
function EffetsNaissanceRace(CodeRace, Naissance: String): String;
var
  PDetail: StructureRaceDetailV2;
begin
  Result := '';
  if Naissance = '' then
    Exit;
  CodeRace := RaceSourcePhysique(CodeRace);
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = ConstXmlPhysNaissanceEffet) and CompareRechercheValeur(PDetail.CodeRace, CodeRace)
       and (Pos(PDetail.Libelle, Naissance) = 1) then
      Exit(PDetail.Plage);
end;

// Effets d'une particularite de forme (familiers, tables 7-1 et 7-2) : liste "Talent:CODE[=N];Natural:CODE;Grapple:N"
// de la ligne OddityEffect dont le nom est celui de la particularite ; '' si la race n'en declare pas.
function EffetsParticulariteRace(CodeRace, Particularite: String): String;
var
  PDetail: StructureRaceDetailV2;
begin
  Result := '';
  if Particularite = '' then
    Exit;
  CodeRace := RaceSourcePhysique(CodeRace);
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = ConstXmlPhysParticulariteEffet) and CompareRechercheValeur(PDetail.CodeRace, CodeRace)
       and (PDetail.Libelle = Particularite) then
      Exit(PDetail.Plage);
end;

// Tirage de la forme (table 7-1, avec l'animal de la 7-3) et des particularites (table 7-2) d'un familier cree
// (Realms of Sorcery). Player's Choice et GM's Choice sont relances ; Combination = deux formes tirees (sans nouvelle
// Combination) ; Roll Twice = deux tirages de plus (sans nouveau Roll Twice) ; une forme Insubstantial seule ne tire
// pas de particularites. Formes et Particularites recoivent les libelles a afficher, Effets la liste
// "Talent:CODE;Natural:CODE" des lignes OddityEffect correspondantes ('' si la race n'a pas ces tables).
procedure TireFamilierV2(CodeRace: String; Formes, Particularites: TStringList; out Effets: String);
var
  Insubstantiel, AutreForme: Boolean;

  procedure AjouteEffet(Nom: String);
  var
    E: String;
  begin
    E := EffetsParticulariteRace(CodeRace, Nom);
    if E <> '' then
      begin
        if Effets <> '' then
          Effets := Effets + ';';
        Effets := Effets + E;
      end;
  end;

  function TireNomTable(Table: String; Refuse: String): String;
  var
    Nom: String;
  begin
    repeat
      Nom := TireTableRace(CodeRace, Table, Random(100) + 1);
    until (Nom <> '') and (Nom <> 'Player''s Choice') and (Nom <> 'GM''s Choice') and (Nom <> Refuse);
    Result := Nom;
  end;

  procedure TireForme(DansCombinaison: Boolean);
  var
    Nom: String;
  begin
    if DansCombinaison then
      Nom := TireNomTable(ConstXmlPhysForme, 'Combination')
    else
      Nom := TireNomTable(ConstXmlPhysForme, '');
    if Nom = 'Combination' then
      begin
        TireForme(True);
        TireForme(True);
        Exit;
      end;
    if (Nom = 'Animalistic') or (Nom = 'Small Animalistic') or (Nom = 'Large Animalistic') then
      Formes.Add(Nom + ' (' + TireNomTable(ConstXmlPhysFormeAnimal, '') + ')')
    else
      Formes.Add(Nom);
    if Nom = 'Insubstantial' then
      Insubstantiel := True
    else
      AutreForme := True;
    AjouteEffet(Nom);
  end;

  procedure TireParticularite(DansRollTwice: Boolean);
  var
    Nom: String;
  begin
    if DansRollTwice then
      Nom := TireNomTable(ConstXmlPhysParticularite, 'Roll Twice')
    else
      Nom := TireNomTable(ConstXmlPhysParticularite, '');
    if Nom = 'Roll Twice' then
      begin
        TireParticularite(True);
        TireParticularite(True);
        Exit;
      end;
    Particularites.Add(Nom);
    AjouteEffet(Nom);
  end;

begin
  Formes.Clear;
  Particularites.Clear;
  Effets := '';
  Insubstantiel := False;
  AutreForme    := False;
  CodeRace := RaceSourcePhysique(CodeRace);
  if not TableRaceExiste(CodeRace, ConstXmlPhysForme) then
    Exit;
  TireForme(False);
  if AutreForme or not Insubstantiel then
    TireParticularite(False);
end;

// Libelles des lignes d'une table de la race, dans l'ordre du livre ; les lignes qui ne sont pas un resultat
// (Player's Choice, GM's Choice, Combination, Roll Twice) sont omises : elles se resolvent par le choix lui-meme.
procedure ListeLignesFamilier(CodeRace, Table: String; Lignes: TStrings);
var
  PDetail: StructureRaceDetailV2;
begin
  Lignes.Clear;
  CodeRace := RaceSourcePhysique(CodeRace);
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = Table) and CompareRechercheValeur(PDetail.CodeRace, CodeRace)
       and (PDetail.Libelle <> 'Player''s Choice') and (PDetail.Libelle <> 'GM''s Choice')
       and (PDetail.Libelle <> 'Combination') and (PDetail.Libelle <> 'Roll Twice') then
      Lignes.Add(PDetail.Libelle);
end;

// L'ethnie est-elle celle d'un familier CREE (tables 7-1 et 7-2 a tirer) ? La race declare les tables ; seule l'ethnie
// Created les tire (les familiers lies ont la forme de leur animal). Repere par le suffixe _CREATED du code d'ethnie.
function RaceATirageFamilier(CodeRace: String): Boolean;
begin
  Result := (Pos('_CREATED', CodeRace) > 0) and TableRaceExiste(RaceSourcePhysique(CodeRace), ConstXmlPhysForme);
end;

// La race declare-t-elle des effets de lieu de naissance (clan Skaven) ?
function RaceAClan(CodeRace: String): Boolean;
begin
  Result := TableRaceExiste(RaceSourcePhysique(CodeRace), ConstXmlPhysNaissanceEffet);
end;

// Vrai si l'ethnie declare une mutation de depart (balise StartingMutation, Mutant du Tome of Corruption).
function RaceAMutationDepart(CodeRace: String): Boolean;
begin
  Result := Trim(ChercheRace(CodeRace).MutationDepart) <> '';
end;

// Lignes "plage|libelle" de la table de naissance d'une race a clans, dans l'ordre du livre.
procedure ListeClansRace(CodeRace: String; Clans: TStringList);
var
  PDetail: StructureRaceDetailV2;
begin
  Clans.Clear;
  CodeRace := RaceSourcePhysique(CodeRace);
  for PDetail in ListRaceDetailV2 do
    if (PDetail.Table = ConstXmlPhysNaissance) and CompareRechercheValeur(PDetail.CodeRace, CodeRace) then
      Clans.Add(PDetail.Plage + '|' + PDetail.Libelle);
end;

// Clan d'une race a clans pour un jet de d100 donne (1 a 100, 00 = 100) ; '' si le jet n'est dans aucune plage.
function ClanRaceParJet(CodeRace: String; Jet: Integer): String;
begin
  Result := TireTableRace(RaceSourcePhysique(CodeRace), ConstXmlPhysNaissance, Jet);
end;

// Tirage d100 sur la table de naissance d'une race a clans : libelle du clan et jet obtenu.
function TireClanRace(CodeRace: String; out Jet: Integer): String;
begin
  Jet    := Random(100) + 1;
  Result := ClanRaceParJet(CodeRace, Jet);
end;

function TireTableCommune(CodeTable: String; Jet: Integer): String;
var
  PTable: StructureTablePersonnelle;
begin
  Result := '';
  for PTable in ListTablePersonnelle do
    if (PTable.CodeTable = CodeTable) and PlageV2(PTable.Plage, Jet) then
      Exit(PTable.Libelle);
end;

// Race qui porte la table des localites (l'humaine) : la table de naissance des Nains et des Halflings y renvoie.
function RaceLocalites(): String;
var
  PDetail: StructureRaceDetailV2;
begin
  Result := '';
  // L'humain du Rulebook d'abord : une ethnie (Tileen de Spears of the Maiden) peut porter ses propres localites
  if TableRaceExiste('RULES-SPECIE_HUMAN', ConstXmlPhysLocalite) then
    Exit('RULES-SPECIE_HUMAN');
  for PDetail in ListRaceDetailV2 do
    if PDetail.Table = ConstXmlPhysLocalite then
      Exit(PDetail.CodeRace);
end;

// Province puis localite ; Racine = la race qui porte ses propres tables, '' = celles de l'humain du Rulebook.
function TireNaissanceHumaine(Racine: String = ''): String;
var
  Humain: String;
begin
  Humain := Racine;
  if Humain = '' then
    Humain := RaceLocalites();
  Result := TireTableRace(Humain, ConstXmlPhysNaissance, Random(10) + 1);
  if Result <> '' then
    Result := Result + ', ' + TireTableRace(Humain, ConstXmlPhysLocalite, Random(10) + 1);
end;

// Naissance V2 : humain = province puis localite ; Nain et Halfling renvoient parfois a la table humaine.
function TireNaissanceV2(CodeRace: String): String;
var
  Jet:    Integer;
  Renvoi: String;
begin
  if TableRaceExiste(CodeRace, ConstXmlPhysLocalite) then
    Exit(TireNaissanceHumaine(CodeRace));
  Jet    := Random(100) + 1;
  Renvoi := FormuleRaceV2(CodeRace, ConstXmlPhysNaissanceHumaine);
  if (Renvoi <> '') and PlageV2(Renvoi, Jet) then
    Result := TireNaissanceHumaine()
  else
    Result := TireTableRace(CodeRace, ConstXmlPhysNaissance, Jet);
end;

// Partie constante d'une formule ("57+2d10" -> 57) et partie des ("2d10"), pour tirer ou saisir le jet des des.
function ConstanteFormule(Formule: String): Integer;
var
  Termes: TStringList;
  I:      Integer;
begin
  Result := 0;
  Termes := TStringList.Create;
  try
    ExtractStrings(['+'], [' '], PChar(Formule), Termes);
    for I := 0 to Termes.Count - 1 do
      if Pos('d', LowerCase(Termes[I])) = 0 then
        Result := Result + StrToIntDef(Trim(Termes[I]), 0);
  finally
    Termes.Free;
  end;
end;

function DesFormule(Formule: String): String;
var
  Termes: TStringList;
  I:      Integer;
begin
  Result := '';
  Termes := TStringList.Create;
  try
    ExtractStrings(['+'], [' '], PChar(Formule), Termes);
    for I := 0 to Termes.Count - 1 do
      if Pos('d', LowerCase(Termes[I])) > 0 then
        begin
          if Result <> '' then
            Result := Result + '+';
          Result := Result + Trim(Termes[I]);
        end;
  finally
    Termes.Free;
  end;
end;

// Plage possible d'un jet de des ("2d10" -> 2 a 20, "d100" -> 1 a 100). Un de qui explose peut ajouter
// UN de de plus (taille humaine V4).
procedure BornesDes(Des: String; Explose: Boolean; out Mini, Maxi: Integer);
var
  Termes:      TStringList;
  I, PosD, N, Faces: Integer;
begin
  Mini := 0;
  Maxi := 0;
  Termes := TStringList.Create;
  try
    ExtractStrings(['+'], [' '], PChar(Des), Termes);
    for I := 0 to Termes.Count - 1 do
      begin
        PosD  := Pos('d', LowerCase(Termes[I]));
        if PosD = 0 then
          Continue;
        N     := StrToIntDef(Copy(Trim(Termes[I]), 1, PosD - 1), 1);
        Faces := StrToIntDef(Copy(Trim(Termes[I]), PosD + 1, MaxInt), 1);
        Mini  := Mini + N;
        Maxi  := Maxi + N * Faces;
        if Explose then
          Maxi := Maxi + Faces;
      end;
  finally
    Termes.Free;
  end;
end;

// Jet numero Index d'une liste "a/b/c" : la valeur saisie si elle existe (ramenee dans la plage possible),
// sinon un jet tire (formule des) qui est ajoute a la liste. Index = Parts.Count : nouveau jet.
function PrendJet(Parts: TStringList; Index: Integer; DesJet: String; Explose: Boolean = False): Integer;
var
  Mini, Maxi: Integer;
begin
  if (Index < Parts.Count) and (StrToIntDef(Trim(Parts[Index]), -1) >= 0) then
    begin
      BornesDes(DesJet, Explose, Mini, Maxi);
      Result := StrToInt(Trim(Parts[Index]));
      if Result < Mini then
        Result := Mini;
      if Result > Maxi then
        Result := Maxi;
      Parts[Index] := IntToStr(Result);
      Exit;
    end;
  Result := LanceFormule(DesJet, Explose);
  while Parts.Count <= Index do
    Parts.Add('');
  Parts[Index] := IntToStr(Result);
end;

// Valeur d'UN champ des details physiques, a partir du ou des jets de Jets ("47", "7/3" : province puis
// localite). Jets vide : on tire et Jets recoit les jets, ce qui permet de les afficher, de les corriger
// (le vrai de du joueur) puis de recalculer. Champ : AGE, TAILLE (pouces), YEUX, CHEVEUX, et en V2 POIDS,
// FRATRIE, SIGNE, NAISSANCE, ASTRE. Resultat '' si la race n'a pas ce champ.
// Formules (V4, taille V2) : le jet est le total des des, valeur = constante + jet.
function ChampPhysique(CodeRace, Champ: String; Femme: Boolean; var Jets: String): String;
var
  PRacePhysique: StructureRacePhysique;
  EstV2:         Boolean;
  TailleParSexe: Boolean;
  Parts:         TStringList;
  I, Jet:        Integer;
  Couleur, Formule, Renvoi, Humain: String;
begin
  Result        := '';
  CodeRace      := RaceSourcePhysique(CodeRace);
  PRacePhysique := ChercheRacePhysique(CodeRace);
  if PRacePhysique.CodeRace = '' then
    Exit;
  EstV2 := TableRaceExiste(CodeRace, ConstXmlPhysPoids);
  Parts := TStringList.Create;
  try
    Parts.Delimiter       := '/';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText   := Jets;
    if Champ = 'AGE' then
      begin
        if EstV2 then
          Result := TireTableRace(CodeRace, ConstXmlPhysAge, PrendJet(Parts, 0, '1d100'))
        else
          begin
            Formule := PRacePhysique.FormuleAge;
            Result  := IntToStr(ConstanteFormule(Formule) + PrendJet(Parts, 0, DesFormule(Formule)));
          end;
      end
    else if Champ = 'TAILLE' then
      begin
        // V2 et WFRP1 : formule selon le sexe (HeightFemale / HeightMale) ; V4 : formule unique
        TailleParSexe := EstV2 or ((PRacePhysique.FormuleTaille = '') and TableRaceExiste(CodeRace, ConstXmlPhysTailleHomme));
        if TailleParSexe then
          Formule := FormuleRaceV2(CodeRace, IfThen(Femme, ConstXmlPhysTailleFemme, ConstXmlPhysTailleHomme))
        else
          Formule := PRacePhysique.FormuleTaille;
        Result := IntToStr(ConstanteFormule(Formule)
                  + PrendJet(Parts, 0, DesFormule(Formule), (not TailleParSexe) and PRacePhysique.TailleExplose));
      end
    else if Champ = 'YEUX' then
      begin
        if EstV2 then
          Result := TireCouleur(CodeRace, True, PrendJet(Parts, 0, '1d10'))
        else
          for I := 0 to PRacePhysique.NbTirageYeux - 1 do
            begin
              Couleur := TireCouleur(CodeRace, True, PrendJet(Parts, I, '2d10'));
              if Couleur <> '' then
                begin
                  if Result <> '' then
                    Result := Result + ' / ';
                  Result := Result + Couleur;
                end;
            end;
      end
    else if Champ = 'CHEVEUX' then
      begin
        if EstV2 then
          Result := TireCouleur(CodeRace, False, PrendJet(Parts, 0, '1d10'))
        else
          Result := TireCouleur(CodeRace, False, PrendJet(Parts, 0, '2d10'));
      end
    else if EstV2 then
      begin
        if Champ = 'POIDS' then
          Result := TireTableRace(CodeRace, ConstXmlPhysPoids, PrendJet(Parts, 0, '1d100'))
        else if Champ = 'FRATRIE' then
          Result := TireTableRace(CodeRace, ConstXmlPhysFratrie, PrendJet(Parts, 0, '1d10'))
        else if Champ = 'SIGNE' then
          Result := TireTableCommune('RULES-PERSONAL_DISTINGUISHING_MARKS', PrendJet(Parts, 0, '1d100'))
        else if Champ = 'ASTRE' then
          Result := TireTableCommune('RULES-PERSONAL_STAR_SIGN', PrendJet(Parts, 0, '1d100'))
        else if Champ = 'NAISSANCE' then
          begin
            // Humain : province puis localite (d10 chacun). Nain, Halfling : d100, puis province et localite
            // si la plage renvoie a la table humaine. Elfe : d100 seul.
            Humain := CodeRace;
            if not TableRaceExiste(CodeRace, ConstXmlPhysLocalite) then
              begin
                Jet    := PrendJet(Parts, 0, '1d100');
                Renvoi := FormuleRaceV2(CodeRace, ConstXmlPhysNaissanceHumaine);
                if (Renvoi <> '') and PlageV2(Renvoi, Jet) then
                  begin
                    Humain := RaceLocalites();
                    I      := 1;
                  end
                else
                  begin
                    Result := TireTableRace(CodeRace, ConstXmlPhysNaissance, Jet);
                    Humain := '';
                  end;
              end
            else
              I := 0;
            if Humain <> '' then
              begin
                Result := TireTableRace(Humain, ConstXmlPhysNaissance, PrendJet(Parts, I, '1d10'));
                if Result <> '' then
                  Result := Result + ', ' + TireTableRace(Humain, ConstXmlPhysLocalite, PrendJet(Parts, I + 1, '1d10'));
              end;
          end;
      end;
    // Jets : les jets de la derniere resolution (ceux saisis, completes par ceux tires)
    Parts.Delimiter := '/';
    Jets := Parts.DelimitedText;
  finally
    Parts.Free;
  end;
end;

// Tire les details personnels V2 d'une race (tables 2-6 a 2-17 du Core). Faux si la race n'a aucune table V2.
function TireDetailsV2(CodeRace: String; Femme: Boolean; out Details: StructureDetailsV2): Boolean;
var
  Formule, Renvoi: String;
  PRacePhysique:   StructureRacePhysique;
  Jet:             Integer;
begin
  Details := Default(StructureDetailsV2);
  CodeRace      := RaceSourcePhysique(CodeRace);
  PRacePhysique := ChercheRacePhysique(CodeRace);
  // Une race sans table de poids peut tout de meme porter une table de naissance (Skaven : clan, table 7-1).
  Result := (PRacePhysique.CodeRace <> '') and (TableRaceExiste(CodeRace, ConstXmlPhysPoids)
            or TableRaceExiste(CodeRace, ConstXmlPhysNaissance));
  if not Result then
    Exit;
  Details.Fratrie := -1;   // -1 = pas de table de fratrie : rien a afficher
  if TableRaceExiste(CodeRace, ConstXmlPhysPoids) then
    begin
      Formule := FormuleRaceV2(CodeRace, IfThen(Femme, ConstXmlPhysTailleFemme, ConstXmlPhysTailleHomme));
      Details.Taille := LanceFormule(Formule, False);
      Details.Poids  := StrToIntDef(TireTableRace(CodeRace, ConstXmlPhysPoids, Random(100) + 1), 0);
      Details.Age    := StrToIntDef(TireTableRace(CodeRace, ConstXmlPhysAge, Random(100) + 1), 0);
      Details.Fratrie := StrToIntDef(TireTableRace(CodeRace, ConstXmlPhysFratrie, Random(10) + 1), 0);
      Details.Yeux    := TireCouleur(CodeRace, True, Random(10) + 1);
      Details.Cheveux := TireCouleur(CodeRace, False, Random(10) + 1);
      Details.Signe       := TireTableCommune('RULES-PERSONAL_DISTINGUISHING_MARKS', Random(100) + 1);
      Details.SigneAstral := TireTableCommune('RULES-PERSONAL_STAR_SIGN', Random(100) + 1);
    end;
  // Naissance : humain = province puis localite (d10 chacun) ; Nain et Halfling renvoient parfois a la table humaine.
  if TableRaceExiste(CodeRace, ConstXmlPhysLocalite) then
    Details.Naissance := TireNaissanceHumaine(CodeRace)
  else
    begin
      Jet    := Random(100) + 1;
      Renvoi := FormuleRaceV2(CodeRace, ConstXmlPhysNaissanceHumaine);
      if (Renvoi <> '') and PlageV2(Renvoi, Jet) then
        Details.Naissance := TireNaissanceHumaine()
      else
        Details.Naissance := TireTableRace(CodeRace, ConstXmlPhysNaissance, Jet);
    end;
end;


// Passe une taille d'une unite a l'autre (CM / INCH, 1 pouce = 2,54 cm), arrondie a l'entier.
// Unite vide = pouces (fiches enregistrees avant l'unite par fiche).
function ConvertitTaille(Valeur: Integer; DeUnite, VersUnite: String): Integer;
begin
  if DeUnite = '' then
    DeUnite := ConstUniteInch;
  if VersUnite = '' then
    VersUnite := ConstUniteInch;
  if DeUnite = VersUnite then
    Result := Valeur
  else if VersUnite = ConstUniteCm then
    Result := Round(Valeur * 2.54)
  else
    Result := Round(Valeur / 2.54);
end;

// Taille ecrite dans SON unite : 175 cm -> 175 cm ; 69 pouces -> 5'9"
function FormateTaille(Valeur: Integer; Unite: String): String;
begin
  if Unite = ConstUniteCm then
    Result := IntToStr(Valeur) + ' cm'
  else
    Result := IntToStr(Valeur div 12) + '''' + IntToStr(Valeur mod 12) + '"';
end;

// Vrai si l'ethnie porte au moins une entree de la partie (Partie = '#' : un modele d'assemblage).
function EthnieAPartieNom(CodeRace, Partie: String): Boolean;
var
  PNom:    StructureRaceNom;
  PModele: StructureRaceNomModele;
begin
  Result := False;
  if Partie = '#' then
    begin
      for PModele in ListRaceNomModele do
        if CompareRechercheValeur(PModele.CodeRace, CodeRace) then
          Exit(True);
    end
  else
    for PNom in ListRaceNom do
      if CompareRechercheValeur(PNom.CodeRace, CodeRace) and (PNom.Partie = Partie) then
        Exit(True);
end;

// Vrai si l'ethnie porte elle-meme des donnees de noms (modele ou table), quelle qu'en soit la partie.
function EthnieANoms(CodeRace: String): Boolean;
var
  PNom: StructureRaceNom;
begin
  Result := EthnieAPartieNom(CodeRace, '#');
  if Result then
    Exit;
  for PNom in ListRaceNom do
    if CompareRechercheValeur(PNom.CodeRace, CodeRace) then
      Exit(True);
end;

// Ethnie dont on lit la partie de nom : l'ethnie elle-meme si elle la porte, sinon une ethnie de la
// meme race (Espece), celle du livre de la race en priorite (meme regle que RaceSourcePhysique).
// Chaque partie se cherche separement : le modele et les clans peuvent venir du Rulebook, les
// prenoms d'un autre livre. Une ethnie qui doit avoir SA liste (Norses, Bretonniens, Kislevites)
// la porte elle-meme : un repli par livre ferait piocher les Estaliens dans la liste kislevite.
// '' si rien n'est trouve.
function RaceSourceNom(CodeRace, Partie: String): String;
var
  PRace, PCandidat: StructureRace;
  Espece:           String;
begin
  Result := '';
  if EthnieAPartieNom(CodeRace, Partie) then
    begin
      Result := CodeRace;
      Exit;
    end;
  PRace  := ChercheRace(CodeRace);
  Espece := Trim(PRace.Espece);
  if Espece = '' then
    Exit;
  for PCandidat in ListRace do
    begin
      if not CompareRechercheValeur(PCandidat.Espece, Espece) then
        continue;
      if not EthnieAPartieNom(PCandidat.CodeRace, Partie) then
        continue;
      if Result = '' then
        Result := PCandidat.CodeRace;
      if ExtractStringBefore(PCandidat.CodeRace, SeparateurLivre) = ExtractStringBefore(Espece, SeparateurLivre) then
        begin
          Result := PCandidat.CodeRace;
          Exit;
        end;
    end;
end;

function RaceANoms(CodeRace: String): Boolean;
begin
  Result := RaceSourceNom(CodeRace, '#') <> '';
end;

// Borne haute d'une plage "2", "5-7" : c'est aussi la taille du de de la partie.
function BorneHautePlage(Plage: String): Integer;
var
  Tiret: Integer;
begin
  Tiret := Pos('-', Plage);
  if Tiret = 0 then
    Result := StrToIntDef(Plage, 0)
  else
    Result := StrToIntDef(Copy(Plage, Tiret + 1, MaxInt), 0);
end;

function PlageContient(Plage: String; Jet: Integer): Boolean;
var
  Tiret: Integer;
  Bas:   Integer;
begin
  Tiret := Pos('-', Plage);
  if Tiret = 0 then
    Bas := StrToIntDef(Plage, 0)
  else
    Bas := StrToIntDef(Copy(Plage, 1, Tiret - 1), 0);
  Result := (Jet >= Bas) and (Jet <= BorneHautePlage(Plage));
end;

// Coupe Texte aux Sep, sans rien interpreter (ExtractStrings traiterait les ' du modele comme
// des guillemets) ; les morceaux vides sont ignores.
procedure Decoupe(Texte: String; Sep: Char; Liste: TStringList);
var
  Debut, I: Integer;
begin
  Liste.Clear;
  Debut := 1;
  for I := 1 to Length(Texte) + 1 do
    if (I > Length(Texte)) or (Texte[I] = Sep) then
      begin
        if I > Debut then
          Liste.Add(Copy(Texte, Debut, I - Debut));
        Debut := I + 1;
      end;
end;

// "Gert(r)a" : la lettre entre parentheses est tiree a pile ou face ; "Brond(I)" -> Brond ou Brondi.
function ResoutVariantes(Nom: String): String;
var
  Ouvre, Ferme: Integer;
  Interieur:    String;
  Variantes:    TStringList;
begin
  Result := Nom;
  // "Adam/Adamar/Adhemar" : une des variantes au hasard
  if Pos('/', Result) > 0 then
    begin
      Variantes := TStringList.Create;
      try
        Decoupe(Result, '/', Variantes);
        if Variantes.Count > 0 then
          Result := Variantes[Random(Variantes.Count)];
      finally
        Variantes.Free;
      end;
    end;
  repeat
    Ouvre := Pos('(', Result);
    Ferme := Pos(')', Result);
    if (Ouvre = 0) or (Ferme < Ouvre) then
      Break;
    Interieur := Copy(Result, Ouvre + 1, Ferme - Ouvre - 1);
    if Length(Interieur) = 1 then
      Interieur := LowerCase(Interieur);
    if Random(2) = 0 then
      Interieur := '';
    Result := Copy(Result, 1, Ouvre - 1) + Interieur + Copy(Result, Ferme + 1, MaxInt);
  until False;
end;

// Tire une entree de la partie dans l'ethnie source. Sexe = M / F : ne garde que les entrees
// de ce sexe et celles sans sexe. La taille du de est la plus haute borne des entrees gardees.
function TireNomPartie(CodeRace, Partie, Sexe: String; Parts: TStringList; var Indice: Integer): String;
var
  Source: String;
  PNom:   StructureRaceNom;
  Maxi:   Integer;
  Jet:    Integer;
begin
  Result := '';
  Source := RaceSourceNom(CodeRace, Partie);
  if Source = '' then
    Exit;
  Maxi := 0;
  for PNom in ListRaceNom do
    if CompareRechercheValeur(PNom.CodeRace, Source) and (PNom.Partie = Partie)
       and ((PNom.Sexe = '') or (PNom.Sexe = Sexe)) and (BorneHautePlage(PNom.Plage) > Maxi) then
      Maxi := BorneHautePlage(PNom.Plage);
  if Maxi < 1 then
    Exit;
  // Jet saisi (liste Parts, un jet par morceau de table dans l'ordre du nom) ramene dans 1..Maxi, sinon tire ;
  // le jet est note dans Parts pour pouvoir etre affiche et corrige.
  if (Indice < Parts.Count) and (StrToIntDef(Trim(Parts[Indice]), -1) >= 0) then
    Jet := Min(Max(StrToInt(Trim(Parts[Indice])), 1), Maxi)
  else
    Jet := Random(Maxi) + 1;
  while Parts.Count <= Indice do
    Parts.Add('');
  Parts[Indice] := IntToStr(Jet);
  Inc(Indice);
  for PNom in ListRaceNom do
    if CompareRechercheValeur(PNom.CodeRace, Source) and (PNom.Partie = Partie)
       and ((PNom.Sexe = '') or (PNom.Sexe = Sexe)) and PlageContient(PNom.Plage, Jet) then
      begin
        Result := ResoutVariantes(PNom.Libelle);
        Exit;
      end;
end;

// Regles de nom declarees par l'ethnie qui porte le modele de CodeRace : Liste recoit des lignes
// "CODE=id de libelle". Vide si l'ethnie n'en declare aucune.
procedure ReglesNomRace(CodeRace: String; Liste: TStringList);
var
  Source: String;
  PRegle: StructureRaceNomRegle;
begin
  Liste.Clear;
  Source := RaceSourceNom(CodeRace, '#');
  if Source = '' then
    Exit;
  for PRegle in ListRaceNomRegle do
    if CompareRechercheValeur(PRegle.CodeRace, Source) and (Liste.IndexOfName(PRegle.Code) < 0) then
      Liste.Add(PRegle.Code + '=' + PRegle.Libelle);
end;

// Un modele au hasard parmi ceux de l'ethnie source pour ce sexe et cette regle ('' = modeles
// ordinaires) ; a defaut de modele du sexe, un modele sans sexe. '' si aucun.
function ChoisitModeleNom(Source, Sexe: String; Regle: String): String;
var
  PModele:            StructureRaceNomModele;
  ModeleSexe, ModeleSans: String;
  NbSexe, NbSans:     Integer;
begin
  ModeleSexe := '';
  ModeleSans := '';
  NbSexe     := 0;
  NbSans     := 0;
  for PModele in ListRaceNomModele do
    if CompareRechercheValeur(PModele.CodeRace, Source) and (PModele.Regle = Regle) then
      begin
        if PModele.Sexe = Sexe then
          begin
            Inc(NbSexe);
            if Random(NbSexe) = 0 then
              ModeleSexe := PModele.Modele;
          end
        else if PModele.Sexe = '' then
          begin
            Inc(NbSans);
            if Random(NbSans) = 0 then
              ModeleSans := PModele.Modele;
          end;
      end;
  if NbSexe > 0 then
    Result := ModeleSexe
  else
    Result := ModeleSans;
end;

// Assemble un nom selon le modele de l'ethnie (celui du sexe demande, sinon celui sans sexe).
// Modele : mots separes par des espaces ; un mot = elements separes par '+' ; un element est une
// partie ("Forename"), une partie d'un sexe impose ("Forename:M"), un texte fixe ('sson') ou
// l'un de ces elements suivi de '?' (present une fois sur deux). Un mot dont une partie
// obligatoire est introuvable (livre absent) est laisse de cote. Sexe vide : tire au hasard.
function TireNomJets(CodeRace, Sexe, Regle: String; var Jets: String): String;
var
  Parts: TStringList;
  Indice: Integer;
  Source, Modele, Mot, Element, Partie, SexePartie, Valeur, Morceau: String;
  Mots, Elements: TStringList;
  I, J, Deux: Integer;
  Facultatif, Manque: Boolean;
  EstTable, PrecedentTable: Boolean;
begin
  Result := '';
  Source := RaceSourceNom(CodeRace, '#');
  if Source = '' then
    Exit;
  if Sexe = '' then
    Sexe := IfThen(Random(2) = 0, 'M', 'F');
  // Plusieurs modeles possibles (ex. Nains : prenom du livre ou prefixe + suffixe) : un seul est
  // tire, au hasard, parmi ceux du sexe demande (a defaut, parmi ceux sans sexe). Une regle de nom
  // choisie prend d'abord les modeles marques de cette regle ; sans eux (ou sans regle), les
  // modeles ordinaires.
  Modele := ChoisitModeleNom(Source, Sexe, Regle);
  if (Modele = '') and (Regle <> '') then
    Modele := ChoisitModeleNom(Source, Sexe, '');
  if Modele = '' then
    Exit;
  Mots     := TStringList.Create;
  Elements := TStringList.Create;
  Parts    := TStringList.Create;
  Indice   := 0;
  try
    Decoupe(Jets, '/', Parts);
    Decoupe(Modele, ' ', Mots);
    for I := 0 to Mots.Count - 1 do
      begin
        Mot    := '';
        Manque := False;
        PrecedentTable := False;
        Elements.Clear;
        Decoupe(Mots[I], '+', Elements);
        for J := 0 to Elements.Count - 1 do
          begin
            Element    := Elements[J];
            Facultatif := (Element <> '') and (Element[Length(Element)] = '?');
            if Facultatif then
              Delete(Element, Length(Element), 1);
            if Facultatif and (Random(2) = 0) then
              Continue;
            if (Length(Element) >= 2) and (Element[1] = '''') then
              begin
                Morceau  := StringReplace(Copy(Element, 2, Length(Element) - 2), '_', ' ', [rfReplaceAll]);
                EstTable := False;
              end
            else
              begin
                Deux       := Pos(':', Element);
                SexePartie := Sexe;
                Partie     := Element;
                if Deux > 0 then
                  begin
                    Partie     := Copy(Element, 1, Deux - 1);
                    SexePartie := Copy(Element, Deux + 1, MaxInt);
                  end;
                Valeur := TireNomPartie(CodeRace, Partie, SexePartie, Parts, Indice);
                if Valeur = '' then
                  begin
                    Manque := True;
                    Break;
                  end;
                Morceau  := Valeur;
                EstTable := True;
              end;
            // Lissage a la jonction de deux morceaux de table (prefixe + suffixe...) : la meme lettre
            // n'est pas ecrite deux fois (Dur + rundi = Durundi, Ullia + a = Ullia).
            if EstTable and PrecedentTable and (Mot <> '') and (Morceau <> '')
               and (LowerCase(Mot[Length(Mot)]) = LowerCase(Morceau[1])) then
              Delete(Morceau, 1, 1);
            Mot := Mot + Morceau;
            PrecedentTable := EstTable;
          end;
        if Manque or (Mot = '') then
          Continue;
        if Result <> '' then
          Result := Result + ' ';
        Result := Result + Mot;
      end;
    Jets := '';
    for I := 0 to Indice - 1 do
      Jets := Jets + IfThen(I > 0, '/', '') + Parts[I];
  finally
    Parts.Free;
    Elements.Free;
    Mots.Free;
  end;
end;

// Nom sans suivi des jets.
function TireNom(CodeRace, Sexe: String; Regle: String = ''): String;
var
  Jets: String;
begin
  Jets := '';
  Result := TireNomJets(CodeRace, Sexe, Regle, Jets);
end;

end.

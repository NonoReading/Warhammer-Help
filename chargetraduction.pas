unit ChargeTraduction;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, ChargeConstantes, Generics.Collections, LazUTF8,
  ChargeAttribut, ChargeTexte, ChargeCompetence, ChargeTalent, ChargeRace, ChargeEspece, ChargeRegle,
  ChargeMetier, ChargeArme, ChargeArmeBonus, ChargeArmure, ChargeTrapping, ChargeArmureBonus,
  ChargeSort, ChargeFabrication, ChargeCorruptionTable, ChargeRacePhysique, ChargeDisease, ChargeNation, ChargeArmureSimplifie, ChargeSigneAstral, ChargeAffliction, UnitCalcul;

Type
  StructureTraduction   = record
    TypeDonnee:  string;
    Code:        string;
    Langue:      String;
    Libelle:     string;
    Description: string;
    Tests:       string;
    Resume:      string;
    Livre:       String;
    // Champs propres au catalogue des maladies (ConstPDisease) - Description porte Symptoms.
    Contraction: string;
    Incubation:  string;
    Duration:    string;
    // Champs propres aux signes astraux (ConstPSigneAstral) - Libelle porte Description.
    Titre:        string;
    Apparence:    string;
    Personnalite: string;
  end;

  StructureLivreTraduit = record
    Livre:       String;
    Langue:      String;
  end;

   TListTraduction = Specialize TList<StructureTraduction>;
   TListLivreTraduit = Specialize TList<StructureLivreTraduit>;

   Function InitTrad(TypeDonnee: String; Code: String; Code2: String; Livre: String): StructureTraduction;
   Procedure AddTrad(PTraduction: StructureTraduction; Langue:String);
   Procedure Traduit(Langue: String; Livre: String);
   // Traits d'un animal ou d'un vehicule, imprimes en anglais dans <AnimalTraits> : chaque nom
   // est rapproche du talent de meme nom anglais et rendu avec le libelle de la langue courante
   // ("Size (Large)" -> libelle FR de RULES-T0SIZ_LARG). Un nom sans talent (traits de bateau,
   // texte libre) reste tel quel. Detail (facultatif) recoit "Libelle : explication" par trait.
   Function TraitsAnimalAffiches(PTrapping: StructureTrapping; Detail: TStrings = nil): String;

var
  ListTraduction:   TListTraduction;
  ListLivreTraduit: TListLivreTraduit;
  NbTraduction:     Integer;
  NBLivreTraduit:   Integer;

implementation

Function InitTrad(TypeDonnee: String; Code: String; Code2: String; Livre: String): StructureTraduction;
  Var
    PTraduction: StructureTraduction;
  begin
    PTraduction.TypeDonnee   := TypeDonnee;
    PTraduction.Code         := Code;
    if Code2 <> '' then
      PTraduction.Code       := PTraduction.Code + ' ' + Code2;
    PTraduction.Langue       := '';
    PTraduction.Libelle      := '';
    PTraduction.Description  := '';
    PTraduction.Tests        := '';
    PTraduction.Resume       := '';
    PTraduction.Livre        := Livre;
    PTraduction.Contraction  := '';
    PTraduction.Incubation   := '';
    PTraduction.Duration     := '';
    PTraduction.Titre        := '';
    PTraduction.Apparence    := '';
    PTraduction.Personnalite := '';

    result := PTraduction;
  end;

Procedure AddTrad(PTraduction: StructureTraduction; Langue:String);
  Var
    PLivreTraduit: StructureLivreTraduit;
    Trouve:        Boolean = False;
  Begin
    PTraduction.Langue       := Langue;
    ListTraduction.add(PTraduction);
    inc(NbTraduction);

    For PLivreTraduit in ListLivreTraduit do
      if (PLivreTraduit.Livre = PTraduction.Livre) and (PLivreTraduit.Langue = PTraduction.Langue) then
        Trouve := true;
    if Not Trouve then
      begin
        PLivreTraduit.Livre := PTraduction.Livre;
        PLivreTraduit.Langue:= PTraduction.Langue;
        ListLivreTraduit.add(PLivreTraduit);
        inc(NBLivreTraduit);
      end;

  end;

// Code du talent dont le libelle ANGLAIS est Nom (ListTraduction garde l'anglais de tous les
// livres meme quand la langue courante est le francais), '' si aucun.
function CodeTalentDeNomAnglais(const Nom: String): String;
  var
    PTraduction: StructureTraduction;
  begin
    Result := '';
    for PTraduction in ListTraduction do
      if (PTraduction.TypeDonnee = ConstPTalent) and (PTraduction.Langue = ConstAnglais)
         and SameText(PTraduction.Libelle, Nom) then
        begin
          Result := PTraduction.Code;
          Exit;
        end;
  end;

// "+10", "2", "8+" : jeton numerique de fin de trait (Weapon +10, Armour 2, Ward 8+).
function EstJetonNumerique(const Jeton: String): Boolean;
  var
    Ind:      Integer;
    ADigit:   Boolean = False;
  begin
    Result := Jeton <> '';
    for Ind := 1 to Length(Jeton) do
      if Jeton[Ind] in ['0'..'9'] then
        ADigit := True
      else if not (Jeton[Ind] in ['+', '-']) then
        Result := False;
    Result := Result and ADigit;
  end;

// Un trait : Explication recoit la description du talent trouve ('' sinon).
function TraduitUnTraitAnimal(const Trait: String; out Explication: String): String;
  var
    Reste, Avant, Suffixe, Code, Libelle: String;
    Candidats:    array[0..2] of String;
    P, Ind:       Integer;
    PTalent:      StructureTalent;
  begin
    Result      := Trait;
    Explication := '';

    // 1) nom complet ("Size (Large)", "Strider (Deserts)")
    Code := CodeTalentDeNomAnglais(Trait);
    if Code <> '' then
      begin
        PTalent     := ChercheTalent(Code);
        Result      := PTalent.Libelle;
        Explication := PTalent.Description;
        Exit;
      end;

    // 2) nom nu + suffixes (parentheses, nombres), rattache a l'entree generique du talent
    Reste   := Trim(Trait);
    Suffixe := '';
    repeat
      Avant := Reste;
      if (Reste <> '') and (Reste[Length(Reste)] = ')') then
        begin
          P := RPos('(', Reste);
          if P > 1 then
            begin
              Suffixe := ' ' + Copy(Reste, P, MaxInt) + Suffixe;
              Reste   := Trim(Copy(Reste, 1, P - 1));
            end;
        end
      else
        begin
          P := RPos(' ', Reste);
          if (P > 0) and EstJetonNumerique(Copy(Reste, P + 1, MaxInt)) then
            begin
              Suffixe := ' ' + Copy(Reste, P + 1, MaxInt) + Suffixe;
              Reste   := Trim(Copy(Reste, 1, P - 1));
            end;
        end;
    until Reste = Avant;
    if (Reste = '') or (Reste = Trait) then
      Exit;

    Candidats[0] := Reste + ' (Any)';
    Candidats[1] := Reste + ' (Rating)';
    Candidats[2] := Reste;
    for Ind := 0 to 2 do
      begin
        Code := CodeTalentDeNomAnglais(Candidats[Ind]);
        if Code <> '' then
          begin
            PTalent := ChercheTalent(Code);
            Libelle := PTalent.Libelle;
            // le libelle francais d'un generique porte "(au choix)" : on ne garde que le nom
            P := Pos(' (', Libelle);
            if (Ind < 2) and (P > 1) then
              Libelle := Copy(Libelle, 1, P - 1);
            Result      := Libelle + Suffixe;
            Explication := PTalent.Description;
            Exit;
          end;
      end;
  end;

Function TraitsAnimalAffiches(PTrapping: StructureTrapping; Detail: TStrings = nil): String;
  var
    Traits, Courant, Explication, Trad: String;
    Profondeur, Ind: Integer;

  procedure Ajoute(const Brut: String);
    begin
      if Trim(Brut) = '' then
        Exit;
      Trad := TraduitUnTraitAnimal(Trim(Brut), Explication);
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + Trad;
      if (Detail <> nil) and (Explication <> '') then
        Detail.Add(Trad + ' : ' + Explication);
    end;

  begin
    Result := '';
    Traits := PTrapping.TraitsAnimal;
    // un bateau a ses propres traits (Sturdy, Armoured, Ram...) qui ne sont pas ceux du talent
    // homonyme : texte laisse tel quel
    if (PTrapping.ProfilBateau <> '') or (Traits = '') then
      begin
        Result := Traits;
        Exit;
      end;
    Courant    := '';
    Profondeur := 0;
    for Ind := 1 to Length(Traits) do
      begin
        if Traits[Ind] = '(' then
          Inc(Profondeur)
        else if Traits[Ind] = ')' then
          Dec(Profondeur);
        if (Traits[Ind] = ',') and (Profondeur <= 0) then
          begin
            Ajoute(Courant);
            Courant := '';
          end
        else
          Courant := Courant + Traits[Ind];
      end;
    Ajoute(Courant);
  end;

procedure TraduitAttribut(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PAttribut: StructureAttribut;
  begin
  for Ind :=0 to ListeAttribut.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListeAttribut[Ind].CodeAttribut) then
      begin
        PAttribut             := ListeAttribut[Ind];
        PAttribut.Description := PTraduction.Description;
        PAttribut.Libelle     := PTraduction.Libelle;
        PAttribut.Resume      := PTraduction.Resume;
        ListeAttribut[Ind]    := PAttribut;
      end;
  end;

procedure TraduitTexte(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PTexte: StructureTexte;
  begin
  for Ind :=0 to ListTexte.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListTexte[Ind].Code) then
      begin
        PTexte             := ListTexte[Ind];
        PTexte.Libelle     := PTraduction.Libelle;
        ListTexte[Ind]    := PTexte;
      end;
  end;

procedure TraduitCompetence(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PCompetence: StructureCompetence;
  begin
  for Ind :=0 to ListCompetence.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListCompetence[Ind].CodeCompetence) then
      begin
        PCompetence             := ListCompetence[Ind];
        PCompetence.Description := PTraduction.Description;
        PCompetence.Libelle     := PTraduction.Libelle;
        ListCompetence[Ind]     := PCompetence;
      end;
  end;

procedure TraduitTalent(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PTalent: StructureTalent;
  begin
  for Ind :=0 to ListTalent.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListTalent[Ind].CodeTalent) then
      begin
        PTalent             := ListTalent[Ind];
        PTalent.Description := PTraduction.Description;
        PTalent.Libelle     := PTraduction.Libelle;
        PTalent.tests       := PTraduction.tests;
        PTalent.Resume      := PTraduction.Resume;
        ListTalent[Ind]     := PTalent;
      end;
  end;

procedure TraduitRace(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PRace: StructureRace;
  begin
  for Ind :=0 to ListRace.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListRace[Ind].CodeRace) then
      begin
        PRace             := ListRace[Ind];
        PRace.Description := PTraduction.Description;
        PRace.Libelle     := PTraduction.Libelle;
        ListRace[Ind]     := PRace;
      end;
  end;

procedure TraduitEspece(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PEspece: StructureEspece;
  begin
  for Ind :=0 to ListEspece.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListEspece[Ind].CodeEspece) then
      begin
        PEspece            := ListEspece[Ind];
        PEspece.Libelle    := PTraduction.Libelle;
        ListEspece[Ind]    := PEspece;
      end;
  end;

procedure TraduitRegle(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PRegle: StructureRegle;
  begin
  for Ind :=0 to ListRegle.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListRegle[Ind].CodeRegle) then
      begin
        PRegle             := ListRegle[Ind];
        PRegle.Libelle     := PTraduction.Libelle;
        ListRegle[Ind]     := PRegle;
      end;
  end;

procedure TraduitMetier(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PMetier: StructureMetier;
  begin
  for Ind :=0 to ListMetier.Count - 1 do
    if CompareRechercheValeur(ListMetier[Ind].CodeMetier, PTraduction.Code) then
      begin
        PMetier             := ListMetier[Ind];
        PMetier.Description := PTraduction.Description;
        PMetier.Libelle     := PTraduction.Libelle;
        ListMetier[Ind]     := PMetier;
      end;
  end;

procedure TraduitArme(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PArme: StructureArme;
  begin
  for Ind :=0 to ListArme.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListArme[Ind].CodeArme) then
      begin
        PArme             := ListArme[Ind];
        PArme.Libelle     := PTraduction.Libelle;
        ListArme[Ind]     := PArme;
      end;
  end;

procedure TraduitArmeBonus(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PArmeBonus: StructureArmeBonus;
  begin
  for Ind :=0 to ListArmeBonus.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListArmeBonus[Ind].CodeArmeBonus) then
      begin
        PArmeBonus             := ListArmeBonus[Ind];
        PArmeBonus.Description := PTraduction.Description;
        PArmeBonus.Libelle     := PTraduction.Libelle;
        PArmeBonus.Resume      := PTraduction.Resume;
        ListArmeBonus[Ind]     := PArmeBonus;
      end;
  end;

procedure TraduitArmure(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PArmure: StructureArmure;
  begin
  for Ind :=0 to ListArmure.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListArmure[Ind].CodeArmure) then
      begin
        PArmure             := ListArmure[Ind];
        PArmure.Libelle     := PTraduction.Libelle;
        ListArmure[Ind]     := PArmure;
      end;
  end;

procedure TraduitTrapping(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PTrapping: StructureTrapping;
  begin
  for Ind :=0 to ListTrapping.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListTrapping[Ind].CodeTrapping) then
      begin
        PTrapping             := ListTrapping[Ind];
        PTrapping.Libelle     := PTraduction.Libelle;
        ListTrapping[Ind]     := PTrapping;
      end;
  end;

procedure TraduitArmureBonus(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PArmureBonus: StructureArmureBonus;
  begin
  for Ind :=0 to ListArmureBonus.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListArmureBonus[Ind].CodeArmureBonus) then
      begin
        PArmureBonus             := ListArmureBonus[Ind];
        PArmureBonus.Description := PTraduction.Description;
        PArmureBonus.Libelle     := PTraduction.Libelle;
        ListArmureBonus[Ind]     := PArmureBonus;
      end;
  end;

procedure TraduitSort(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PSort: StructureSort;
  begin
  for Ind :=0 to ListSort.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListSort[Ind].CodeSort) then
      begin
        PSort             := ListSort[Ind];
        PSort.Description := PTraduction.Description;
        PSort.Libelle     := PTraduction.Libelle;
        ListSort[Ind]     := PSort;
      end;
  end;

procedure TraduitFabrication(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PFabrication: StructureFabrication;
  begin
  for Ind :=0 to ListFabrication.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListFabrication[Ind].CodeFabrication) then
      begin
        PFabrication             := ListFabrication[Ind];
        PFabrication.Description := PTraduction.Description;
        PFabrication.Libelle     := PTraduction.Libelle;
        PFabrication.Resume      := PTraduction.Resume;
        ListFabrication[Ind]     := PFabrication;
      end;
  end;

procedure TraduitCorruptionTable(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PCorruptionTable: StructureCorruptionTable;
  begin
  // Code = code stable du catalogue (ex. "RULES-CORMEN_007", book-prefixed) depuis
  // le pivot du 17/08/2026 - CompareRechercheValeur standard, comme les autres
  // catalogues (Talents, Races, ...). Avant ce pivot, Code était une clé composée
  // TypeCorruption+Chance (plage D100), incompatible avec CompareRechercheValeur.
  for Ind :=0 to ListCorruptionTable.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListCorruptionTable[Ind].Code) then
      begin
        PCorruptionTable         := ListCorruptionTable[Ind];
        PCorruptionTable.Libelle := PTraduction.Libelle;
        PCorruptionTable.Effet   := PTraduction.Description;
        ListCorruptionTable[Ind] := PCorruptionTable;
      end;
  end;

procedure TraduitDisease(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PDisease: StructureDisease;
  begin
  for Ind :=0 to ListDisease.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListDisease[Ind].Code) then
      begin
        PDisease             := ListDisease[Ind];
        PDisease.Libelle     := PTraduction.Libelle;
        PDisease.Symptoms    := PTraduction.Description;
        PDisease.Contraction := PTraduction.Contraction;
        PDisease.Incubation  := PTraduction.Incubation;
        PDisease.Duration    := PTraduction.Duration;
        ListDisease[Ind]     := PDisease;
      end;
  end;

procedure TraduitNation(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PNation: StructureNation;
  begin
  for Ind :=0 to ListNation.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListNation[Ind].CodeNation) then
      begin
        PNation         := ListNation[Ind];
        PNation.Libelle := PTraduction.Libelle;
        ListNation[Ind] := PNation;
      end;
  end;

procedure TraduitArmureSimplifiee(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PArmureSimp: StructureArmureSimplifiee;
  begin
  for Ind :=0 to ListArmureSimplifiee.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListArmureSimplifiee[Ind].CodeArmure) then
      begin
        PArmureSimp         := ListArmureSimplifiee[Ind];
        PArmureSimp.Libelle := PTraduction.Libelle;
        ListArmureSimplifiee[Ind] := PArmureSimp;
      end;
  end;

procedure TraduitTrait(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PTrait: StructureTrait;
  begin
  for Ind :=0 to ListTrait.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListTrait[Ind].CodeTrait) then
      begin
        PTrait         := ListTrait[Ind];
        PTrait.Libelle := PTraduction.Libelle;
        ListTrait[Ind] := PTrait;
      end;
  end;

procedure TraduitTraitOption(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PTraitOption: StructureTraitOption;
  begin
  for Ind :=0 to ListTraitOption.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListTraitOption[Ind].CodeOption) then
      begin
        PTraitOption         := ListTraitOption[Ind];
        PTraitOption.Libelle := PTraduction.Libelle;
        ListTraitOption[Ind] := PTraitOption;
      end;
  end;

procedure TraduitCareerBonus(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PCareerBonus: StructureCareerBonus;
  begin
  for Ind :=0 to ListCareerBonus.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListCareerBonus[Ind].CodeBonus) then
      begin
        PCareerBonus         := ListCareerBonus[Ind];
        PCareerBonus.Libelle := PTraduction.Libelle;
        ListCareerBonus[Ind] := PCareerBonus;
      end;
  end;

procedure TraduitAdaptation(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PAdaptation: StructureCareerAdaptation;
  begin
  for Ind :=0 to ListCareerAdaptation.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListCareerAdaptation[Ind].CodeAdaptation) then
      begin
        PAdaptation         := ListCareerAdaptation[Ind];
        PAdaptation.Libelle := PTraduction.Libelle;
        ListCareerAdaptation[Ind] := PAdaptation;
      end;
  end;

procedure TraduitSigneAstral(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PSigne: StructureSigneAstral;
  begin
  for Ind :=0 to ListSigneAstral.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListSigneAstral[Ind].CodeSigne) then
      begin
        PSigne              := ListSigneAstral[Ind];
        PSigne.Libelle      := PTraduction.Libelle;
        PSigne.Titre        := PTraduction.Titre;
        PSigne.Apparence    := PTraduction.Apparence;
        PSigne.Personnalite := PTraduction.Personnalite;
        ListSigneAstral[Ind] := PSigne;
      end;
  end;

procedure TraduitAffliction(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PAffliction: StructureAffliction;
  begin
  for Ind :=0 to ListAffliction.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code, ListAffliction[Ind].Code) then
      begin
        PAffliction         := ListAffliction[Ind];
        PAffliction.Libelle := PTraduction.Libelle;
        PAffliction.Effet   := PTraduction.Description;
        ListAffliction[Ind] := PAffliction;
      end;
  end;

procedure TraduitRaceCouleur(const PTraduction: StructureTraduction);
  var
    Ind: Integer;
    PRaceCouleur: StructureRaceCouleur;
  begin
  // Code = "CodeRace Y|H Plage" (Y = yeux, H = cheveux) : la couleur n'a pas de code
  // propre, la plage de la table 2d10 l'identifie dans son ethnie.
  for Ind :=0 to ListRaceCouleur.Count - 1 do
    if CompareRechercheValeur(PTraduction.Code,
         ListRaceCouleur[Ind].CodeRace + ' ' + IfThen(ListRaceCouleur[Ind].EstYeux, 'Y', 'H')
         + '|' + ListRaceCouleur[Ind].Plage) then
      begin
        PRaceCouleur         := ListRaceCouleur[Ind];
        PRaceCouleur.Libelle := PTraduction.Libelle;
        ListRaceCouleur[Ind] := PRaceCouleur;
      end;
  end;

Procedure Traduit(Langue: String; Livre: String);
  var
    PTraduction:  StructureTraduction;
  begin
    // Pas de garde sur Langue = ConstAnglais ici : ListTexte/ListeAttribut/etc. ne sont
    // PAS rechargées avec du texte anglais frais lors d'un changement de livre/langue en
    // direct (XmlImport y est appelé avec OnlyPrimary=false, qui saute tout le bloc Texte/
    // Attribut/AttributAugmentation/CompetenceAugmentation - seul le premier chargement au
    // démarrage, avec OnlyPrimary=true, les remplit). Revenir à l'anglais doit donc, comme
    // pour toute autre langue, réappliquer explicitement les valeurs mises en cache dans
    // ListTraduction (qui contient bien des entrées Langue=ConstAnglais, ajoutées sans
    // condition par AddTrad dès le chargement initial). CONTEXT.md §2.8 (bug du 17/08/2026).
    For PTraduction in ListTraduction do
          if (PTraduction.Langue = Langue) and ((Livre = '') or (PTraduction.Livre = Livre)) then
            case PTraduction.TypeDonnee of
              ConstPAttribut: TraduitAttribut(PTraduction);
              ConstPTexte: TraduitTexte(PTraduction);
              ConstPCompetence: TraduitCompetence(PTraduction);
              ConstPTalent: TraduitTalent(PTraduction);
              ConstPRace: TraduitRace(PTraduction);
              ConstPEspece: TraduitEspece(PTraduction);
              ConstPRegle: TraduitRegle(PTraduction);
              ConstPMetier: TraduitMetier(PTraduction);
              ConstPArme: TraduitArme(PTraduction);
              ConstPArmeBonus: TraduitArmeBonus(PTraduction);
              ConstPArmure: TraduitArmure(PTraduction);
              ConstPTrapping: TraduitTrapping(PTraduction);
              ConstPArmureBonus: TraduitArmureBonus(PTraduction);
              ConstPSort: TraduitSort(PTraduction);
              ConstPFabrication: TraduitFabrication(PTraduction);
              ConstPCorruptionTable: TraduitCorruptionTable(PTraduction);
              ConstPDisease: TraduitDisease(PTraduction);
              ConstPNation: TraduitNation(PTraduction);
              ConstPArmureSimplifiee: TraduitArmureSimplifiee(PTraduction);
              ConstPTrait: TraduitTrait(PTraduction);
              ConstPTraitOption: TraduitTraitOption(PTraduction);
              ConstPCareerBonus: TraduitCareerBonus(PTraduction);
              ConstPAdaptation: TraduitAdaptation(PTraduction);
              ConstPSigneAstral: TraduitSigneAstral(PTraduction);
              ConstPAffliction: TraduitAffliction(PTraduction);
              ConstPRaceCouleur: TraduitRaceCouleur(PTraduction);
            end;

  end;

end.


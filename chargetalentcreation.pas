unit ChargeTalentCreation;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, Generics.Collections, ChargeTalent, UnitCalcul, ChargeTirageMetier;

Type
  StructureTalentCreation   = record
    CodeRace:           string;
    CodeTalent:		string;
    Chance:		string;
    Livre:              String;
end;

  TListTalentCreation = specialize TList<StructureTalentCreation>;

  StructureTirageTalent = record
    CodeTalent: String;
    Debut:      Integer;
    Fin:        Integer;
  end;

  TListTirageTalent = specialize TList<StructureTirageTalent>;

Var
  ListTalentCreation: TListTalentCreation;
  NbTalentCreation:   Integer;

Function DescriptionTalent(CodeTalent: String; CodeRace: String): String;
Function IntervalleChance(Chance: String; out Deb, Fin: Integer): Boolean;
Function TalentAleatoire(Jet: Integer; CodeRace: String): String;
// Table des talents aléatoires d'une ethnie (table de l'ethnie, sinon table générique du
// Rulebook), dans l'ordre du dé. Une table dont les Chance sont des fourchettes ("04-06",
// V5) est lue telle quelle ; une table dont les Chance sont des POIDS ("3", V4) est triée par
// libellé de la langue active puis cumulée : le Rulebook imprime cette table par ordre
// alphabétique de chaque langue.
Procedure CalculeTirageTalent(CodeRace: String; Tirage: TListTirageTalent);
Function TalentDejaPossede(Code: String; Deja: TStringList): Boolean;

implementation

uses
  ChargeRace;

Function DescriptionTalent(CodeTalent: String; CodeRace: String): String;
  var
    Lib:             String;
    PTalent:         StructureTalent;
    Tirage:          TListTirageTalent;
    Ligne:           StructureTirageTalent;
  begin
    // libellé de base
    PTalent  := ChercheTalent(CodeTalent);
    Lib      := PTalent.Description;
    if CompareRechercheValeur(CodeTalent, TalentGenerique) then
      begin
        // table de l'ethnie, sinon table générique de RULEBOOK, dans l'ordre du dé
        Tirage := TListTirageTalent.Create;
        try
          CalculeTirageTalent(CodeRace, Tirage);
          For Ligne in Tirage do
            begin
              PTalent  := ChercheTalent(Ligne.CodeTalent);
              Lib      := Lib + SeparateurRetourLigne + ' - ' + FormateTranche(Ligne.Debut, Ligne.Fin) + ' - ' + PTalent.Libelle;
            end;
        finally
          Tirage.Free;
        end;
      end;

    // envoyer le résultat
    Result := Lib;
  end;

Function IntervalleChance(Chance: String; out Deb, Fin: Integer): Boolean;
  begin
    Chance := Trim(Chance);
    if Pos('-', Chance) > 0 then
      begin
        Deb := StrToIntDef(ExtractStringBefore(Chance, '-'), 0);
        Fin := StrToIntDef(ExtractStringAfter(Chance, '-'), 0);
        if Fin = 0 then
          Fin := 100; // 00 sur un d100 vaut 100 (ex. 98-00)
      end
    else
      begin
        Deb := StrToIntDef(Chance, 0);
        Fin := Deb;
      end;
    Result := (Deb > 0) and (Fin >= Deb);
  end;


Procedure CalculeTirageTalent(CodeRace: String; Tirage: TListTirageTalent);
  type
    StructureEntree = record
      CodeTalent: String;
      Chance:     String;
      Cle:        String;
    end;
  var
    Entrees:         array of StructureEntree;
    NbEntrees:       Integer;
    PTalentCreation: StructureTalentCreation;
    PRace:           StructureRace;
    Espece:          String;
    Fourchettes:     Boolean;
    Deb, Fin:        Integer;
    Total, Cumul:    Integer;
    Poids:           Integer;
    Ind, Jnd:        Integer;
    Tmp:             StructureEntree;
    Ligne:           StructureTirageTalent;

  procedure Collecte(Race: String);
    begin
      For PTalentCreation in ListTalentCreation do
        if CompareRechercheValeur(PTalentCreation.CodeRace, Race) then
          begin
            if Length(Entrees) <= NbEntrees then
              SetLength(Entrees, NbEntrees + 32);
            Entrees[NbEntrees].CodeTalent := PTalentCreation.CodeTalent;
            Entrees[NbEntrees].Chance     := PTalentCreation.Chance;
            Entrees[NbEntrees].Cle        := CleTri(ChercheTalent(PTalentCreation.CodeTalent).Libelle);
            Inc(NbEntrees);
          end;
    end;

  begin
    Tirage.Clear;
    NbEntrees := 0;
    // 1 - table spécifique à la race, 2 - repli sur la table générique du RULESBOOK, 3 - repli sur la
    // table d'une autre ethnie de la même race (provinces humaines V2 du Career Compendium : la V2
    // n'a pas de table générique)
    Collecte(CodeRace);
    if NbEntrees = 0 then
      Collecte(ConstCodeRaceCreationGenerique);
    if NbEntrees = 0 then
      begin
        Espece := Trim(ChercheRace(CodeRace).Espece);
        if Espece <> '' then
          For PRace in ListRace do
            if (NbEntrees = 0) and CompareRechercheValeur(PRace.Espece, Espece) then
              Collecte(PRace.CodeRace);
      end;
    if NbEntrees = 0 then
      exit;

    Fourchettes := False;
    For Ind := 0 to NbEntrees - 1 do
      if Pos('-', Entrees[Ind].Chance) > 0 then
        Fourchettes := True;

    if Fourchettes then
      begin
        // table en fourchettes : lue telle quelle
        For Ind := 0 to NbEntrees - 1 do
          if IntervalleChance(Entrees[Ind].Chance, Deb, Fin) then
            begin
              Ligne.CodeTalent := Entrees[Ind].CodeTalent;
              Ligne.Debut      := Deb;
              Ligne.Fin        := Fin;
              Tirage.Add(Ligne);
            end;
        exit;
      end;

    // table en poids : tri par insertion (stable) sur le libellé de la langue active
    For Ind := 1 to NbEntrees - 1 do
      begin
        Tmp := Entrees[Ind];
        Jnd := Ind - 1;
        While (Jnd >= 0) and (Entrees[Jnd].Cle > Tmp.Cle) do
          begin
            Entrees[Jnd + 1] := Entrees[Jnd];
            Dec(Jnd);
          end;
        Entrees[Jnd + 1] := Tmp;
      end;

    Total := 0;
    For Ind := 0 to NbEntrees - 1 do
      Total := Total + StrToIntDef(Entrees[Ind].Chance, 0);
    if Total <= 0 then
      exit;

    // cumul des poids, ramené à 100 quand la table ne totalise pas 100
    Cumul := 0;
    For Ind := 0 to NbEntrees - 1 do
      begin
        Poids := StrToIntDef(Entrees[Ind].Chance, 0);
        if Poids <= 0 then
          Continue;
        Ligne.CodeTalent := Entrees[Ind].CodeTalent;
        Ligne.Debut      := (Cumul * 100) div Total + 1;
        Cumul            := Cumul + Poids;
        Ligne.Fin        := (Cumul * 100) div Total;
        if Ligne.Fin < Ligne.Debut then
          Ligne.Fin := Ligne.Debut;
        Tirage.Add(Ligne);
      end;
  end;

Function TalentAleatoire(Jet: Integer; CodeRace: String): String;
  var
    Tirage: TListTirageTalent;
    Ligne:  StructureTirageTalent;
  begin
    Result := '';
    Tirage := TListTirageTalent.Create;
    try
      CalculeTirageTalent(CodeRace, Tirage);
      For Ligne in Tirage do
        if (Jet >= Ligne.Debut) and (Jet <= Ligne.Fin) then
          begin
            Result := Ligne.CodeTalent;
            Exit;
          end;
    finally
      Tirage.Free;
    end;
  end;

Function TalentDejaPossede(Code: String; Deja: TStringList): Boolean;
  var
    Ind: Integer;
  begin
    Result := False;
    if Deja = nil then Exit;
    for Ind := 0 to Deja.Count - 1 do
      if CompareRechercheValeur(Code, Deja[Ind]) then
        begin
          Result := True;
          Exit;
        end;
  end;

end.


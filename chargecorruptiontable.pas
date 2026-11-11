unit ChargeCorruptionTable;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, ChargeRaceCorruptionCreation, ChargeRace, UnitCalcul,
  Generics.Collections;

Type
  // Catalogue des mutations (Physical/Mental Corruption Table), CONTEXT.md §2.7 (chantier
  // mutation). Code = code stable du livre (ex. "RULES-CORMEN_007"), pas une plage D100 :
  // le tirage D100 -> Code est décorrélé du catalogue (voir StructureCorruptionChance
  // ci-dessous), pour rester valide si un futur livre renumérote sa table de chance sans
  // toucher au catalogue (conception revue avec Nono le 17/08/2026). TypeCorruption =
  // CorruptionPhysique/CorruptionMentale (mêmes constantes que
  // StructureRaceCorruptionCreation). Effet en texte libre pour l'instant (pas d'application
  // automatique aux caractéristiques, conception validée avec Nono le 16/08/2026 - beaucoup
  // d'effets ne sont pas de simples deltas de caractéristique).
  StructureCorruptionTable = Record
	Livre:            string;
	TypeCorruption:   string;
	Code:             string;
	Libelle:          string;
	Effet:            string;
	Lore:             string;   // lore divin pour CorruptionDivine (Marques des Dieux), '' sinon
	// Seulement pour CorruptionMutation (Tome of Corruption, WFRP2), '' sinon :
	Peur:             string;   // points de peur ("1", "0-1", "1/2/3", "Varies")
	TypeMutation:     string;   // "Single" ou "Multiple N" (nombre de prises)
	Variations:       string;
	Cosmetique:       Boolean;
	// Code de la mutation de base quand cette entree est la 2e, 3e... prise d'une mutation a effets
	// par rang (Growth, Shrink), '' sinon. Hors table de chance ; l'ordre du livre donne le rang.
	MutationBase:     string;
end;

  TListCorruptionTable = Specialize TList<StructureCorruptionTable>;

  // Table de chance (D100 -> Code), CONTEXT.md §2.7 - propre à chaque livre, extensible sans
  // perturber les codes déjà stockés sur les personnages existants. Chance = plage D100
  // "01-05" (le "00" final vaut 100, cas particulier à gérer au tirage).
  StructureCorruptionChance = Record
	Livre:            string;
	TypeCorruption:   string;
	Chance:           string;
	Code:             string;
	Lore:             string;   // lore divin pour CorruptionDivine, '' sinon
end;

  TListCorruptionChance = Specialize TList<StructureCorruptionChance>;

var
  ListCorruptionTable:  TListCorruptionTable;
  nbCorruptionTable:     Integer;
  ListCorruptionChance: TListCorruptionChance;
  nbCorruptionChance:    Integer;

// Compare un jet D100 à une plage "Deb-Fin" (ex. "01-05", "96-00" - le "00" final vaut 100,
// deux d10 à 0 chacun donnent 100 en D100). Une plage "-" (pas de plage, ex.
// DATA_CORRUPTION_PHYSICAL pour les Elfes) ne matche jamais.
Function CorruptionDansPlage(Plage: String; Jet: Integer): Boolean;

// Détermine Physical ou Mental pour une race et un jet D100 donnés, via
// DATA_CORRUPTION_PHYSICAL/DATA_CORRUPTION_MENTAL (ListRaceCorruptionCreation). Renvoie ''
// si rien ne matche pour cette race (ex. Elfes, jamais Physical).
Function CorruptionTypeResultat(CodeRace: String; Jet: Integer): String;

// Cherche l'entrée du catalogue (Physical ou Mental Corruption Table, déjà déterminée) qui
// correspond à un jet D100 : d'abord la table de chance (D100 -> Code), puis le catalogue
// (Code -> Libelle/Effet). Code = '' dans le résultat si rien ne matche.
// Lore = '' pour Physical/Mental ; pour CorruptionDivine, le lore du dieu (ex. "Lore of Manann") :
// seules les lignes de chance de ce lore sont regardees.
Function CorruptionTableResultat(TypeCorruption: String; Jet: Integer; Lore: String = ''): StructureCorruptionTable;

// Retrouve une entrée du catalogue directement par son Code (ex. pour réafficher une mutation
// déjà stockée sur un personnage, sans repasser par un jet de dé). Résultat vide si le Code
// n'existe dans aucun livre chargé.
Function ChercheCorruptionTable(Code: String): StructureCorruptionTable;

// Mutation a effets par rang (champ MutationBase) : Code de la prise suivante quand Prises prises
// de la mutation Base (variantes de rang comprises) sont deja sur la fiche. Prises = 0 ou aucune
// entree de ce rang : Base lui-meme.
Function MutationCodePourPrise(Base: String; Prises: Integer): String;

// Code de la mutation de base d'un code stocke sur un personnage (Code lui-meme s'il n'est pas une prise de rang).
Function MutationCodeBase(Code: String): String;

// Une race a-t-elle une plage valide pour ce type de corruption (ex. False pour Physical chez
// les Elfes) ? Utilisé pour griser le choix direct Physical/Mental dans WinMutation (CONTEXT.md
// §2.7, mode Choix) - le mode Hasard/Résultat gère déjà ce cas via CorruptionDansPlage('-', ...)
// qui ne matche jamais, mais un choix direct contourne le jet de dé, donc doit être vérifié
// explicitement.
Function CorruptionTypeDisponible(CodeRace: String; TypeCorruption: String): Boolean;

// Ramene une ethnie de detail (ex. HELFG-RACE_CALED, sans entree propre dans
// DATA_CORRUPTION_PHYSICAL/MENTAL qui ne connaissent que les races de base du Rulebook) a la
// race de base qui porte la meme Espece (ChargeRace.pas) - meme principe que
// RegleMetierApplicable (chargeregle.pas) : l'ethnie prime, a defaut on remonte a l'espece.
// Renvoie CodeRace inchange si une entree lui correspond deja directement, ou si aucune
// espece commune n'est trouvee.
Function CorruptionCodeRaceEffectif(CodeRace: String): String;

implementation

Function CorruptionDansPlage(Plage: String; Jet: Integer): Boolean;
  var
    IndS: Integer;
    Deb, Fin: Integer;
  begin
    Result := False;
    if Plage = '-' then Exit;

    IndS := Pos(SeparateurChance, Plage);
    if IndS > 0 then
      begin
        Deb := StrToIntDef(Copy(Plage, 1, IndS - 1), 0);
        Fin := StrToIntDef(Copy(Plage, IndS + 1, Length(Plage)), 0);
        if Fin = 0 then
          Fin := 100;   // "00" final = 100
      end
    else
      begin
        Deb := StrToIntDef(Plage, 0);
        Fin := Deb;
      end;

    Result := (Jet >= Deb) and (Jet <= Fin);
  end;

Function CorruptionCodeRaceEffectif(CodeRace: String): String;
  var
    PRaceCorruptionCreation: StructureRaceCorruptionCreation;
    Espece:                  String;
  begin
    Result := CodeRace;
    for PRaceCorruptionCreation in ListRaceCorruptionCreation do
      if CompareRechercheValeur(CodeRace, PRaceCorruptionCreation.CodeRace) then
        Exit;

    Espece := ChercheRace(CodeRace).Espece;
    if Espece = '' then Exit;

    for PRaceCorruptionCreation in ListRaceCorruptionCreation do
      if CompareRechercheValeur(Espece, ChercheRace(PRaceCorruptionCreation.CodeRace).Espece) then
        begin
          Result := PRaceCorruptionCreation.CodeRace;
          Exit;
        end;
  end;

Function CorruptionTypeResultat(CodeRace: String; Jet: Integer): String;
  var
    PRaceCorruptionCreation: StructureRaceCorruptionCreation;
    CodeRaceEffectif:        String;
  begin
    Result := '';
    CodeRaceEffectif := CorruptionCodeRaceEffectif(CodeRace);
    for PRaceCorruptionCreation in ListRaceCorruptionCreation do
      if CompareRechercheValeur(CodeRaceEffectif, PRaceCorruptionCreation.CodeRace) then
        if CorruptionDansPlage(PRaceCorruptionCreation.Chance, Jet) then
          begin
            Result := PRaceCorruptionCreation.TypeCorruption;
            Exit;
          end;
  end;

Function CorruptionTableResultat(TypeCorruption: String; Jet: Integer; Lore: String = ''): StructureCorruptionTable;
  var
    PCorruptionChance: StructureCorruptionChance;
    PCorruptionTable:  StructureCorruptionTable;
    CodeTrouve:        String;
  begin
    Result := Default(StructureCorruptionTable);

    CodeTrouve := '';
    for PCorruptionChance in ListCorruptionChance do
      if (PCorruptionChance.TypeCorruption = TypeCorruption) and (PCorruptionChance.Lore = Lore)
         and CorruptionDansPlage(PCorruptionChance.Chance, Jet) then
        begin
          CodeTrouve := PCorruptionChance.Code;
          break;
        end;

    if CodeTrouve <> '' then
      for PCorruptionTable in ListCorruptionTable do
        if CompareRechercheValeur(CodeTrouve, PCorruptionTable.Code) then
          begin
            Result := PCorruptionTable;
            break;
          end;
  end;

Function ChercheCorruptionTable(Code: String): StructureCorruptionTable;
  var
    PCorruptionTable: StructureCorruptionTable;
  begin
    // Sans cette ligne, Result garde le contenu du PRECEDENT appel quand rien n'est trouve
    // (une fonction Pascal renvoyant un record ne l'initialise pas). Symptomes vus le
    // 22/08/2026 : un libelle de talent recopie d'une ligne a l'autre, une competence
    // affichee deux fois. CONTEXT.md 2.17.
    Result := Default(StructureCorruptionTable);

    for PCorruptionTable in ListCorruptionTable do
      if CompareRechercheValeur(Code, PCorruptionTable.Code) then
        begin
          Result := PCorruptionTable;
          break;
        end;
  end;

Function MutationCodePourPrise(Base: String; Prises: Integer): String;
  var
    PCorruptionTable: StructureCorruptionTable;
    Rang:             Integer;
  begin
    Result := Base;
    Rang   := 0;   // nombre de prises de rang 2, 3... rencontrees dans l'ordre du livre
    if Prises <= 0 then Exit;
    for PCorruptionTable in ListCorruptionTable do
      if (PCorruptionTable.MutationBase <> '') and CompareRechercheValeur(Base, PCorruptionTable.MutationBase) then
        begin
          Inc(Rang);
          if Rang = Prises then
            begin
              Result := PCorruptionTable.Code;
              Exit;
            end;
        end;
  end;

Function MutationCodeBase(Code: String): String;
  begin
    Result := ChercheCorruptionTable(Code).MutationBase;
    if Result = '' then Result := Code;
  end;

Function CorruptionTypeDisponible(CodeRace: String; TypeCorruption: String): Boolean;
  var
    PRaceCorruptionCreation: StructureRaceCorruptionCreation;
    CodeRaceEffectif:        String;
  begin
    Result := False;
    CodeRaceEffectif := CorruptionCodeRaceEffectif(CodeRace);
    for PRaceCorruptionCreation in ListRaceCorruptionCreation do
      if CompareRechercheValeur(CodeRaceEffectif, PRaceCorruptionCreation.CodeRace)
         and (PRaceCorruptionCreation.TypeCorruption = TypeCorruption)
         and (PRaceCorruptionCreation.Chance <> '-') then
        begin
          Result := True;
          Exit;
        end;
  end;

end.

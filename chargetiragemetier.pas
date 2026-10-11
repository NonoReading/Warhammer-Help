unit ChargeTirageMetier;

{$mode ObjFPC}{$H+}

interface

// Table de tirage d100 des métiers d'une ethnie, calculée à l'usage.
//
// Le XML ne porte plus des fourchettes (01-03) mais un POIDS par métier (3 = trois valeurs de
// dé), dans StructureRaceMetier.Chance / StructureRegleMetier.Chance. Les bornes se déduisent
// ici : les métiers sont classés par classe puis par libellé DANS LA LANGUE ACTIVE (c'est
// l'ordre des tables imprimées, FR comme EN : Apothicaire 46 dans le livre français), puis
// leurs poids sont cumulés. Une traduction n'a donc rien à saisir pour que le d100 colle au
// livre. Voir CONTEXT.md 2.1 (d100 des métiers par langue).
//
// Une règle (ChargeRegle) remplace la table de l'ethnie qu'elle couvre. Si elle déclare une
// classe remplacée (StructureRegle.ClasseRemplacee, cas de la règle Seafarer de Sea of Claws),
// elle est PARTIELLE : seuls les métiers de base de cette classe sont retirés, et ceux de la
// règle prennent leur place dans le classement (ils sont rangés comme s'ils étaient de cette
// classe).

uses
  Classes, SysUtils, Generics.Collections, LazUTF8, UnitCalcul, ChargeConstantes, ChargeMetier, ChargeTexte,
  ChargeRaceMetier, ChargeRegle, ChargeTraduction;

Type
  StructureTirageMetier = Record
    CodeMetier: String;
    Debut:      Integer;
    Fin:        Integer;
  End;

  TListTirageMetier = specialize TList<StructureTirageMetier>;

// Remplit Tirage (vidé d'abord) avec la table de l'ethnie, dans l'ordre du dé. CodeRegle vide
// = table de base. Une règle qui ne couvre pas l'ethnie laisse la table de base s'appliquer.
Procedure CalculeTirageMetier(CodeRace, CodeRegle: String; Tirage: TListTirageMetier);
// Fourchette affichable d'un métier dans un Tirage DEJA calculé ("01-03", "46", "100").
// ChanceBrute est la Chance du XML : 'X' ou '-' sont rendus tels quels, un poids est remplacé
// par la fourchette calculée. Calculer UN Tirage pour toute la liste affichée : le recalculer
// à chaque ligne figerait l'écran (constaté dans WinRace le 02/10/2026).
Function ChanceLigneTirage(Tirage: TListTirageMetier; CodeMetier, ChanceBrute: String): String;
Function FormateTranche(Debut, Fin: Integer): String;
// Clé de tri alphabétique (minuscules, sans accents), partagée avec ChargeTalentCreation.
Function CleTri(Texte: String): String;
// Libelle d'une classe (code CLASS_xxx) dans la langue des donnees, voir l'implementation.
Function LibelleClasse(Code: String): String;

implementation

Type
  StructureEntreeTirage = Record
    CodeMetier: String;
    Poids:      Integer;
    Cle:        String;
  End;

// Clé de tri : minuscules, sans accents, espaces de bord retirés (certains libellés français
// finissent par une espace). L'ordre alphabétique des livres ignore les accents.
Function CleTri(Texte: String): String;
  const
    Accentue: array[0..24] of String = ('à','â','ä','é','è','ê','ë','î','ï','ô','ö','ù','û','ü','ç','ñ','œ','æ','ÿ','á','í','ó','ú','ß','ø');
    Simple:   array[0..24] of String = ('a','a','a','e','e','e','e','i','i','o','o','u','u','u','c','n','oe','ae','y','a','i','o','u','ss','o');
  var
    Ind: Integer;
  begin
    Result := UTF8LowerCase(Trim(Texte));
    For Ind := 0 to High(Accentue) do
      Result := StringReplace(Result, Accentue[Ind], Simple[Ind], [rfReplaceAll]);
  end;

// Libelle d'une classe dans la LANGUE DES DONNEES (ValLangue), pas celle de l'interface :
// GetTexteLibelle serait ecrase par la passe Traduit(ValLangueInterface, INTERFACE), car
// INTERFACE.Xml definit aussi les classes. Ordre de recherche : traduction d'un livre dans
// ValLangue, puis en anglais (livre de donnees, puis INTERFACE), puis GetTexteLibelle.
Function LibelleClasse(Code: String): String;
  var
    PTraduction: StructureTraduction;
    Langues:     Array[0..1] of String;
    Passe:       Integer;
    Interface_:  Integer;
  begin
    Langues[0] := ValLangue;
    Langues[1] := ConstAnglais;
    Result     := '';
    For Passe := 0 to 1 do
      For Interface_ := 0 to 1 do
        if Result = '' then
          For PTraduction in ListTraduction do
            if (PTraduction.TypeDonnee = ConstPTexte) and (PTraduction.Langue = Langues[Passe])
               and ((PTraduction.Livre = ConstInterfaceBook) = (Interface_ = 1))
               and (PTraduction.Libelle <> '')
               and CompareRechercheValeur(PTraduction.Code, Code) then
              begin
                Result := PTraduction.Libelle;
                break;
              end;
    if Result = '' then
      Result := GetTexteLibelle(Code);
  end;

Function FormateTranche(Debut, Fin: Integer): String;
  function Un(V: Integer): String;
    begin
      if V >= 100 then
        Result := '100'
      else
        Result := Format('%.2d', [V]);
    end;
  begin
    if Debut = Fin then
      Result := Un(Debut)
    else
      Result := Un(Debut) + SeparateurChance + Un(Fin);
  end;

Procedure CalculeTirageMetier(CodeRace, CodeRegle: String; Tirage: TListTirageMetier);
  var
    Entrees:      Array of StructureEntreeTirage;
    NbEntrees:    Integer;
    PRaceMetier:  StructureRaceMetier;
    PRegleMetier: StructureRegleMetier;
    PMetier:      StructureMetier;
    PRegle:       StructureRegle;
    Regle:        String;
    EthnieSeule:  Boolean;
    ClasseRegle:  String;
    Poids:        Integer;
    Total, Cumul: Integer;
    Ind, Jnd:     Integer;
    Tmp:          StructureEntreeTirage;
    Ligne:        StructureTirageMetier;
    ClesClasse:   TStringList;

  // cle de tri d'une classe, cherchee une seule fois par table (LibelleClasse parcourt toutes
  // les traductions)
  Function CleClasse(Classe: String): String;
    var
      Pos_: Integer;
    begin
      Pos_ := ClesClasse.IndexOfName(Classe);
      if Pos_ >= 0 then
        Result := ClesClasse.ValueFromIndex[Pos_]
      else
        begin
          Result := CleTri(LibelleClasse(Classe));
          ClesClasse.Values[Classe] := Result;
        end;
    end;

  Procedure Ajoute(CodeMetier: String; PoidsLu: Integer; Classe: String);
    begin
      PMetier := ChercheMetier(CodeMetier);
      if Length(Entrees) <= NbEntrees then
        SetLength(Entrees, NbEntrees + 32);
      Entrees[NbEntrees].CodeMetier := PMetier.CodeMetier;
      Entrees[NbEntrees].Poids      := PoidsLu;
      Entrees[NbEntrees].Cle        := CleClasse(Classe) + #1 + CleTri(PMetier.Libelle);
      Inc(NbEntrees);
    end;

  begin
    Tirage.Clear;
    ClesClasse := TStringList.Create;
    try
    NbEntrees   := 0;
    ClasseRegle := '';

    Regle := CodeRegle;
    if not RegleCouvreRace(Regle, CodeRace) then
      Regle := '';

    // 1) la règle, si elle s'applique à cette ethnie
    if Regle <> '' then
      begin
        PRegle      := ChercheRegle(Regle);
        ClasseRegle := PRegle.ClasseRemplacee;
        EthnieSeule := RegleCibleEthnie(Regle, CodeRace);
        For PRegleMetier in ListRegleMetier do
          if RegleMetierApplicable(PRegleMetier, Regle, CodeRace, EthnieSeule) then
            begin
              Poids := StrToIntDef(PRegleMetier.Chance, 0);
              if Poids > 0 then
                begin
                  if ClasseRegle <> '' then
                    Ajoute(PRegleMetier.CodeMetier, Poids, ClasseRegle)
                  else
                    Ajoute(PRegleMetier.CodeMetier, Poids, ChercheMetier(PRegleMetier.CodeMetier).LibelleGroupe);
                end;
            end;
      end;

    // 2) la table de base : en entier sans règle, sinon seulement la part que la règle ne
    // remplace pas (rien pour une règle totale, la classe remplacée en moins pour une partielle)
    if (Regle = '') or (ClasseRegle <> '') then
      For PRaceMetier in ListRaceMetier do
        if CompareRechercheValeur(PRaceMetier.CodeRace, CodeRace) then
          begin
            Poids := StrToIntDef(PRaceMetier.Chance, 0);
            if Poids > 0 then
              begin
                PMetier := ChercheMetier(PRaceMetier.CodeMetier);
                if (ClasseRegle = '') or not CompareRechercheValeur(PMetier.LibelleGroupe, ClasseRegle) then
                  Ajoute(PRaceMetier.CodeMetier, Poids, PMetier.LibelleGroupe);
              end;
          end;

    // tri par insertion (stable, 100 lignes au plus)
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
      Total := Total + Entrees[Ind].Poids;
    if Total <= 0 then
      exit;

    // cumul des poids, ramené à 100 quand la table ne totalise pas 100 (d10, d20...)
    Cumul := 0;
    For Ind := 0 to NbEntrees - 1 do
      begin
        Ligne.CodeMetier := Entrees[Ind].CodeMetier;
        Ligne.Debut      := (Cumul * 100) div Total + 1;
        Cumul            := Cumul + Entrees[Ind].Poids;
        Ligne.Fin        := (Cumul * 100) div Total;
        if Ligne.Fin < Ligne.Debut then
          Ligne.Fin := Ligne.Debut;
        Tirage.Add(Ligne);
      end;
    finally
      ClesClasse.Free;
    end;
  end;

Function ChanceLigneTirage(Tirage: TListTirageMetier; CodeMetier, ChanceBrute: String): String;
  var
    Ligne: StructureTirageMetier;
  begin
    Result := ChanceBrute;
    if StrToIntDef(ChanceBrute, 0) <= 0 then
      exit;
    Result := '';
    For Ligne in Tirage do
      if CompareRechercheValeur(Ligne.CodeMetier, CodeMetier) then
        begin
          Result := FormateTranche(Ligne.Debut, Ligne.Fin);
          break;
        end;
  end;

end.

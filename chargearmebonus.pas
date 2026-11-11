unit ChargeArmeBonus;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, Generics.Collections, Unitcalcul, ChargeTexte;

Type
  StructureArmeBonus     = record
    CodeArmeBonus:    String;
    Libelle:          String;
    Description:      String;
    Resume:           String;
    PlusMoins:        String;
    NeedsValue:       String;
    QualitesAccordees: String;  // codes de qualites d'arme que celle-ci accorde (virgules), ex. Parry = Balanced + Defensive
    Livre:            String;
  end;

  TListArmeBonus =  Specialize TList<StructureArmeBonus>;

Var
  NbArmeBonus:     Integer;
  ListArmeBonus:   TListArmeBonus;
  // qualites d'arme propres au personnage en cours : jamais dans la liste des livres (CONTEXT.md 2.116)
  ListArmeBonusPerso: TListArmeBonus;

function ChercheArmeBonus(CodeArmeBonus :String): StructureArmeBonus;
function GetAllArmeBonusLibelle(CodeArmeBonus :String): String;
// Ajoute a la liste des qualites a expliquer (ArmeBonii) le code d'une qualite ; pour une alternative "A/B",
// chacune des parties, pour qu'elles aient chacune leur ligne d'explication.
procedure AjouteArmeBonii(var ArmeBonii: String; const Code: String);
// Une alternative telle qu'ecrite dans <Quality> : "A 2/B 3" (ou l'ancien "A/B 2"), valeurs par partie.
// Libelle "A 2 or B 3" ; codes seuls "A/B" (pour retrouver les explications).
function LibelleAlternatives(const Jeton: String): String;
function CodesAlternatives(const Jeton: String): String;

implementation

function GetAllArmeBonusLibelle(CodeArmeBonus :String): String;
// Remplace chaque code de qualite par son libelle, dans une liste separee par des virgules.
//
// L'ancienne version faisait un StringReplace de SOUS-CHAINE sur la liste entiere, apres
// avoir retire le prefixe de livre du code declare. Deux consequences :
//   - un code qui est le prefixe d'un autre (WEAPB4 dans WEAPB40) aurait corrompu
//     l'affichage en silence. Aucun cas aujourd'hui, les codes faisant tous deux
//     chiffres, mais l'equilibre ne tient qu'a cela.
//   - la comparaison ignorait le livre, alors que ChercheArmeBonus sait le gerer.
// Cette version decoupe la liste et resout chaque code entier via ChercheArmeBonus, qui
// passe par CompareRechercheValeur et accepte donc le code prefixe comme non prefixe.
//
// Deux formes particulieres sont conservees telles quelles :
//   "WEAPB18 2"        un indice numerique suit le code, separe par un espace
//   "WEAPB30/WEAPB12"  qualites alternatives, separees par SeparateurMulti
var
  Liste:        TStringList;
  Alternatives: TStringList;
  Element:      String;
  Suffixe:      String;
  Morceau:      String;
  Code:         String;
  PArmeBonus:   StructureArmeBonus;
  Ind:          Integer;
  IndAlt:       Integer;
Begin
  Result       := '';
  Liste        := TStringList.Create;
  Alternatives := TStringList.Create;
  try
    ExtractStrings([','], [], PChar(CodeArmeBonus), Liste);
    for Ind := 0 to Liste.Count - 1 do
      begin
        Element := Trim(Liste[Ind]);
        Suffixe := '';
        if Pos(' ', Element) > 0 then
          begin
            Suffixe := ' ' + Trim(ExtractStringAfter(Element, ' '));
            Element := Trim(ExtractStringBefore(Element, ' '));
          end;

        Alternatives.Clear;
        ExtractStrings([SeparateurMulti], [], PChar(Element), Alternatives);
        Morceau := '';
        for IndAlt := 0 to Alternatives.Count - 1 do
          begin
            Code       := Trim(Alternatives[IndAlt]);
            PArmeBonus := ChercheArmeBonus(Code);
            if PArmeBonus.Libelle <> '' then
              Code := PArmeBonus.Libelle;
            if Morceau <> '' then
              Morceau := Morceau + SeparateurMulti;
            Morceau := Morceau + Code;
          end;

        if Result <> '' then
          Result := Result + ',';
        Result := Result + Morceau + Suffixe;
      end;
  finally
    Alternatives.Free;
    Liste.Free;
  end;
end;

function ChercheArmeBonus(CodeArmeBonus :String): StructureArmeBonus;
var
  PArmeBonus:        StructureArmeBonus;
  Parties:           TStringList;
  Libelles:          String;
  Complet:           Boolean;
  Ind:               Integer;
Begin
  // Sans cette ligne, Result garde le contenu du PRECEDENT appel quand rien n'est trouve
  // (une fonction Pascal renvoyant un record ne l'initialise pas). Symptomes vus le
  // 22/08/2026 : un libelle de talent recopie d'une ligne a l'autre, une competence
  // affichee deux fois. CONTEXT.md 2.17.
  Result := Default(StructureArmeBonus);
    for PArmeBonus in ListArmeBonus do
      if CompareRechercheValeur(PArmeBonus.CodeArmeBonus, CodeArmeBonus) then
         Begin
           Result := PArmeBonus;
           break;
         end;
    if Result.CodeArmeBonus = '' then
      for PArmeBonus in ListArmeBonusPerso do
        if CompareRechercheValeur(PArmeBonus.CodeArmeBonus, CodeArmeBonus) then
          begin
            Result := PArmeBonus;
            break;
          end;
  // Qualites ALTERNATIVES "A/B" ou "A/B/C" (colonne Or de WinLivre) sans entree declaree : libelle "A or B"
  // compose des parties, que le porteur choisit entre elles. Une partie inconnue annule le repli.
  if (Result.CodeArmeBonus = '') and (Pos(SeparateurMulti, CodeArmeBonus) > 0) then
    begin
      Parties := TStringList.Create;
      try
        ExtractStrings([SeparateurMulti], [], PChar(CodeArmeBonus), Parties);
        Libelles := '';
        Complet  := Parties.Count > 1;
        for Ind := 0 to Parties.Count - 1 do
          begin
            PArmeBonus := ChercheArmeBonus(Trim(Parties[Ind]));
            if PArmeBonus.CodeArmeBonus = '' then
              Complet := False
            else
              begin
                if Libelles <> '' then
                  Libelles := Libelles + ' ' + GetTexteLibelle('RULES-LAB_494') + ' ';
                Libelles := Libelles + PArmeBonus.Libelle;
              end;
          end;
        if Complet then
          begin
            Result.CodeArmeBonus := CodeArmeBonus;
            Result.Libelle       := Libelles;
            Result.Resume        := Libelles;
          end;
      finally
        Parties.Free;
      end;
    end;
end;

function LibelleAlternatives(const Jeton: String): String;
var
  Parties: TStringList;
  Ind: Integer;
  Un, Valeur: String;
  PArmeBonus: StructureArmeBonus;
begin
  Result := '';
  Parties := TStringList.Create;
  try
    ExtractStrings([SeparateurMulti], [], PChar(Jeton), Parties);
    for Ind := 0 to Parties.Count - 1 do
      begin
        Un := Trim(Parties[Ind]);
        Valeur := '';
        if Pos(' ', Un) > 0 then
          begin
            Valeur := Trim(Copy(Un, Pos(' ', Un) + 1, Length(Un)));
            Un := Copy(Un, 1, Pos(' ', Un) - 1);
          end;
        PArmeBonus := ChercheArmeBonus(Un);
        if PArmeBonus.Libelle <> '' then Un := PArmeBonus.Libelle;
        if Valeur <> '' then Un := Un + ' ' + Valeur;
        if Result <> '' then
          Result := Result + ' ' + GetTexteLibelle('RULES-LAB_494') + ' ';
        Result := Result + Un;
      end;
  finally
    Parties.Free;
  end;
end;

function CodesAlternatives(const Jeton: String): String;
var
  Parties: TStringList;
  Ind: Integer;
  Un: String;
begin
  Result := '';
  Parties := TStringList.Create;
  try
    ExtractStrings([SeparateurMulti], [], PChar(Jeton), Parties);
    for Ind := 0 to Parties.Count - 1 do
      begin
        Un := Trim(Parties[Ind]);
        if Pos(' ', Un) > 0 then Un := Copy(Un, 1, Pos(' ', Un) - 1);
        if Result <> '' then Result := Result + SeparateurMulti;
        Result := Result + Un;
      end;
  finally
    Parties.Free;
  end;
end;

procedure AjouteArmeBonii(var ArmeBonii: String; const Code: String);
var
  Parties: TStringList;
  Ind:     Integer;
  Un:      String;
begin
  Parties := TStringList.Create;
  try
    if Pos(SeparateurMulti, Code) > 0 then
      ExtractStrings([SeparateurMulti], [], PChar(Code), Parties)
    else
      Parties.Add(Code);
    for Ind := 0 to Parties.Count - 1 do
      begin
        Un := Trim(Parties[Ind]);
        if Pos(Un, ArmeBonii) = 0 then
          begin
            if ArmeBonii <> '' then
              ArmeBonii := ArmeBonii + ',';
            ArmeBonii := ArmeBonii + Un;
          end;
      end;
  finally
    Parties.Free;
  end;
end;


initialization
  ListArmeBonusPerso := TListArmeBonus.Create;

end.

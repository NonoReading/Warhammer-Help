unit ChargeCompetence;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, Generics.Collections, UnitCalcul;

type
    StructureCompetence	               = record
  	CodeCompetence:		       string;
  	Libelle:                       string;
  	CodeAttribut:		       string;
  	Description:	               string;
  	SousCompetence:	               boolean;
        // Competence de base (balise <Basic>) : ligne du tableau Competences de base des PDF.
        DeBase:                        boolean;
        // Generique dont le joueur peut creer une specialisation libre (balise <FreeSpecialisation>)
        SpecLibre:                     boolean;
        Livre:                         string;
        // Code complet de la competence generique dont celle-ci est une specialisation,
        // lu depuis <Generique> quand present (CONTEXT.md 2.67). Vide si non renseigne
        // (competence non specialisee, ou specialisation sans generique '_*' identifiee).
        CodeGenerique:                 string;
        // WFRP1 : une ligne par <Bonus> (cible, valeur), vide hors V1
        BonusTexte:                    string;
    end;

  TListCompetence = Specialize TList<StructureCompetence>;

var
  ListCompetence:     TListCompetence;
  // specialisations de competence propres au personnage en cours : jamais dans la liste des livres (CONTEXT.md 2.116)
  ListCompetencePerso: TListCompetence;
  NbCompetence:       Integer;
  NbCompetenceUnique: Integer;
  DescriptionComp:    string;
  SpecialisationComp: string;

function ChercheCompetence(CodeCompetence :String): StructureCompetence;
function CodeGeneriqueDeduit(const Code: String): String;
function FamilleCompetence(const Code: String): String;
function CodeGeneriqueDe(const PCompetence: StructureCompetence): String;

implementation

// Code du generique d'une specialisation : le lien <Generique> de la fiche, a defaut le code deduit ('' si la
// competence n'est pas une specialisation).
function CodeGeneriqueDe(const PCompetence: StructureCompetence): String;
Begin
  if not PCompetence.SousCompetence then
    Result := ''
  else if PCompetence.CodeGenerique <> '' then
    Result := PCompetence.CodeGenerique
  else
    Result := CodeGeneriqueDeduit(PCompetence.CodeCompetence);
End;

// Competences V4 / V5 (24/10/2026, comme les talents) : specialisation RULES-COMP_LORE__BEASTS, generique
// RULES-COMP_LORE__*. Repli quand <Generique> n'est pas renseigne : famille = ce qui precede le '__'.
// Ancien format (V2) : radical avant le premier '_'.
function CodeGeneriqueDeduit(const Code: String): String;
var
  P: Integer;
Begin
  P := Pos(SeparateurSpecialisationTalent, Code);
  if P > 0 then
    Result := Copy(Code, 1, P + Length(SeparateurSpecialisationTalent) - 1) + '*'
  else
    Result := ExtractStringBefore(Code, ValeurSousCompetence) + ValeurGenerique;
End;

// Famille d'un code de competence, generique ou specialisation : RULES-COMP_LORE__BEASTS et RULES-COMP_LORE__*
// donnent RULES-COMP_LORE ; une competence sans specialisation est sa propre famille.
function FamilleCompetence(const Code: String): String;
var
  P: Integer;
Begin
  P := Pos(SeparateurSpecialisationTalent, Code);
  if P > 0 then
    Result := Copy(Code, 1, P - 1)
  else if Copy(Code, Length(Code) - 1, 2) = ValeurGenerique then
    Result := Copy(Code, 1, Length(Code) - 2)
  else
    Result := Code;
End;

function CountOccurrences(const str, subStr: string): Integer;
var
  index, count: Integer;
begin
  count := 0;
  index := 1;

  while index > 0 do
  begin
    index := Pos(subStr, str, index);
    if index > 0 then
    begin
      Inc(count);
      Inc(index, Length(subStr));
    end;
  end;

  Result := count;
end;

function ChercheCompetence(CodeCompetence :String): StructureCompetence;
var
  PCompetence:        StructureCompetence;
Begin
  // Sans cette ligne, Result garde le contenu du PRECEDENT appel quand rien n'est trouve
  // (une fonction Pascal renvoyant un record ne l'initialise pas). Symptomes vus le
  // 22/08/2026 : un libelle de talent recopie d'une ligne a l'autre, une competence
  // affichee deux fois. CONTEXT.md 2.17.
  Result := Default(StructureCompetence);
  for PCompetence in ListCompetence do
    if CompareRechercheValeur(PCompetence.CodeCompetence, CodeCompetence) then
       Begin
         Result := PCompetence;
         break;
       end;
  if Result.CodeCompetence = '' then
    for PCompetence in ListCompetencePerso do
      if CompareRechercheValeur(PCompetence.CodeCompetence, CodeCompetence) then
        begin
          Result := PCompetence;
          break;
        end;
end;

initialization
  ListCompetencePerso := TListCompetence.Create;


end.


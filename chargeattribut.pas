unit ChargeAttribut;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, ChargeTexte, Generics.Collections, Unitcalcul;

Type
  StructureAttribut      = record
    CodeAttribut:              string;
    Libelle:                   string;
    Description:               string;
    Resume:                    String;
    OrdreAttribut:             integer;
    Livre:                     String;
  end;

  TListeAttribut =  Specialize TList<StructureAttribut>;

Var
  NbAttribut:        Integer;
  ListeAttribut:     TListeAttribut;

function ChercheAttribut(CodeAttribut :String): StructureAttribut;

implementation

Function ChercheAttribut(CodeAttribut :String): StructureAttribut;
var
  PAttribut:          StructureAttribut;
Begin
  // Sans cette ligne, Result garde le contenu du PRECEDENT appel quand rien n'est trouve
  // (une fonction Pascal renvoyant un record ne l'initialise pas). Symptomes vus le
  // 22/08/2026 : un libelle de talent recopie d'une ligne a l'autre, une competence
  // affichee deux fois. CONTEXT.md 2.17.
  Result := Default(StructureAttribut);
  for PAttribut in ListeAttribut do
    if CompareRechercheValeur(PAttribut.CodeAttribut, CodeAttribut) then
      begin
       Result := PAttribut;
       break;
      end;
end;


end.


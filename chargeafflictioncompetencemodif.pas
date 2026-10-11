unit ChargeAfflictionCompetenceModif;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections;

Type
  // Pendant de ChargeCorruptionCompetenceModif (Mutations) pour les Afflictions - s'applique a
  // TOUTES les competences dont l'attribut de rattachement est CodeAttribut (ex. Stench/
  // Disfigurement, Unofficial Grimoire, "-10 to all Fellowship Tests"), sans modifier
  // l'attribut lui-meme. CodeSource = StructureAffliction.Code. Ajout du 27/09/2026, a la
  // demande de Nono.
  StructureAfflictionCompetenceAttributModif = Record
        Livre:          String;
        CodeSource:     String;
        CodeAttribut:   String;
        Valeur:         Integer;
end;

  TListAfflictionCompetenceAttributModif = Specialize TList<StructureAfflictionCompetenceAttributModif>;

Var
  ListAfflictionCompetenceAttributModif: TListAfflictionCompetenceAttributModif;
  NbAfflictionCompetenceAttributModif:   Integer;


implementation


end.

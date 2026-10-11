unit ChargeDiseaseModificateur;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeModificateur;

// Compteur des modificateurs declares par le catalogue Disease (ChargeDisease, Rulebook -
// Litany of Pestilence). Les entrees elles-memes vivent dans ListModificateur
// (TypeSource = SourceModifMaladie, CodeSource = StructureDisease.Code).
Var
  NbDiseaseModificateur:   Integer;


implementation


end.

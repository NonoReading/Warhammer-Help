unit ChargeDisease;

// Catalogue des maladies (The Litany of Pestilence, Rulebook p.186-188, CONTEXT.md chantier
// "AUDIT DES TXT" Rulebook). Consultation seule (comme ChargeCorruptionTable) : aucun effet
// mecanise, Contraction/Incubation/Duration/Symptoms en texte libre.

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections, UnitCalcul;

Type
  StructureDisease = Record
    Livre:       string;
    Code:        string;
    Libelle:     string;
    Contraction: string;
    Incubation:  string;
    Duration:    string;
    Symptoms:    string;
end;

  TListDisease = Specialize TList<StructureDisease>;

var
  ListDisease: TListDisease;
  nbDisease:   Integer;

// Resout un Code catalogue en entree complete - meme principe que ChercheCorruptionTable,
// utilise pour afficher/retrouver une maladie possedee par un personnage
// (StructurePersonnagePathologie.Code).
Function ChercheDisease(Code: String): StructureDisease;

implementation

Function ChercheDisease(Code: String): StructureDisease;
  var
    PDisease: StructureDisease;
  begin
    Result := Default(StructureDisease);

    for PDisease in ListDisease do
      if CompareRechercheValeur(Code, PDisease.Code) then
        begin
          Result := PDisease;
          break;
        end;
  end;

end.

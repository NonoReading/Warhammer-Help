unit ChargeAffliction;

// Catalogue des Afflictions (Unofficial Grimoire, fan book Chris MacLean, p.30-31,
// chapitre Dark Magic). Consultation seule, meme principe que ChargeDisease : aucun
// effet mecanise, pas de table de chance/tirage D100 (contrairement a la Physical/
// Mental Corruption Table, officielle - decision de Nono du 27/09/2026 de ne pas
// integrer ce sous-systeme d'un livre de fan au meme niveau que l'officiel). Le
// texte reprend les 3 plages D100 par categorie de lanceur (Chaos Lore/Daemonology/
// Necromancy) directement dans Effet, en texte libre.

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections, UnitCalcul;

Type
  StructureAffliction = Record
    Livre:   string;
    Code:    string;
    Libelle: string;
    Effet:   string;
end;

  TListAffliction = Specialize TList<StructureAffliction>;

var
  ListAffliction: TListAffliction;
  nbAffliction:   Integer;

// Resout un Code catalogue en entree complete (Livre/Libelle/Effet) - meme principe que
// ChercheCorruptionTable, utilise pour afficher/retrouver une affliction possedee par un
// personnage (StructurePersonnagePathologie.Code).
Function ChercheAffliction(Code: String): StructureAffliction;

implementation

Function ChercheAffliction(Code: String): StructureAffliction;
  var
    PAffliction: StructureAffliction;
  begin
    Result := Default(StructureAffliction);

    for PAffliction in ListAffliction do
      if CompareRechercheValeur(Code, PAffliction.Code) then
        begin
          Result := PAffliction;
          break;
        end;
  end;

end.

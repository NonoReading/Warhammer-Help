unit ChargeCompetenceAugmentation;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, Generics.Collections;

Type
  StructureCompetenceAugmentation  = record
    MinMax:     string;
    Cout:       integer;
    Livre:      String;
  end;

  TListeCompetenceAugmentation = Specialize TList<StructureCompetenceAugmentation>;

Var
  ListeCompetenceAugmentation:    TListeCompetenceAugmentation;
  NbCompetenceAugmentation:       Integer;

Function ChercheCompetenceAugmentation(Min :Integer; Max: Integer): StructureCompetenceAugmentation;

implementation

Function ChercheCompetenceAugmentation(Min :Integer; Max: Integer): StructureCompetenceAugmentation;
var
  PCompetenceAugmentation: StructureCompetenceAugmentation;
  MinMax:                  String;
Begin
  MinMax := IntToStr(Min)+'-'+IntToStr(Max);
  For PCompetenceAugmentation in ListeCompetenceAugmentation do
    if PCompetenceAugmentation.MinMax = MinMax then
      begin
       Result := PCompetenceAugmentation;
       Exit;
      end;
  // au dela de la derniere ligne chiffree, la ligne ouverte du livre (« 70+ ») s'applique
  For PCompetenceAugmentation in ListeCompetenceAugmentation do
    if Copy(PCompetenceAugmentation.MinMax, Length(PCompetenceAugmentation.MinMax), 1) = '+' then
      begin
       Result := PCompetenceAugmentation;
       Exit;
      end;
end;

end.


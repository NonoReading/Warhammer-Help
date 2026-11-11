unit ChargeAttributAugmentation;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, Generics.Collections;

Type
  StructureAttributAugmentation  = record
    MinMax:     string;
    Cout:       integer;
    Livre:      String;
  end;
  TListeAttributAugmentation = Specialize TList<StructureAttributAugmentation>;

Var
  ListeAttributAugmentation:      TListeAttributAugmentation;
  NbAttributAugmentation:         Integer;

Function ChercheAttributAugmentation(Min :Integer; Max: Integer): StructureAttributAugmentation;

implementation

Function ChercheAttributAugmentation(Min :Integer; Max: Integer): StructureAttributAugmentation;
var
  PAttributAugmentation: StructureAttributAugmentation;
  MinMax:                String;
Begin
  MinMax := IntToStr(Min)+'-'+IntToStr(Max);
  for PAttributAugmentation in ListeAttributAugmentation do
    if PAttributAugmentation.MinMax = MinMax then
      begin
       Result := PAttributAugmentation;
       Exit;
      end;
  // au dela de la derniere ligne chiffree, la ligne ouverte du livre (« 70+ ») s'applique
  for PAttributAugmentation in ListeAttributAugmentation do
    if Copy(PAttributAugmentation.MinMax, Length(PAttributAugmentation.MinMax), 1) = '+' then
      begin
       Result := PAttributAugmentation;
       Exit;
      end;
end;


end.


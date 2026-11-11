unit MessageTest;

{$mode objfpc}{$H+}

// Doit etre cite APRES Dialogs dans la clause uses : ShowMessage ci-dessous masque celui de Dialogs.
// En mode test (la pile d'appels n'a des numeros de ligne que si l'exe n'est pas strippe) (--winlivretest), le message va dans error.log au lieu d'ouvrir une boite qui bloque le test.

interface

uses
  SysUtils;

var
  TestSansMessageGlobal: Boolean = False;

procedure ShowMessage(const Msg: String);
procedure JournaliserException(E: Exception);

implementation

uses
  Classes, Dialogs, lnfodwrf;

procedure ShowMessage(const Msg: String);
begin
  if not TestSansMessageGlobal then
  begin
    Dialogs.ShowMessage(Msg);
    Exit;
  end;
  with TStringList.Create do
  try
    if FileExists('error.log') then LoadFromFile('error.log');
    Add('Message : ' + Msg);
    SaveToFile('error.log');
  finally
    Free;
  end;
end;

// ecrit l'exception et sa pile d'appels (lignes de code, grace a -gl) dans error.log
procedure JournaliserException(E: Exception);
var
  I: Integer;
begin
  with TStringList.Create do
  try
    if FileExists('error.log') then LoadFromFile('error.log');
    Add('Exception : ' + E.ClassName + ' : ' + E.Message);
    Add(BackTraceStrFunc(ExceptAddr));
    for I := 0 to ExceptFrameCount - 1 do
      Add(BackTraceStrFunc(ExceptFrames[I]));
    SaveToFile('error.log');
  finally
    Free;
  end;
end;

end.

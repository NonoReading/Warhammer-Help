unit GuideAide;

// Guide du joueur : boutons « Aide » et « ? Question » de WinCreation / WinPersonnage.
// Les guides sont des pages HTML generees par TRAVAIL\md_vers_html.py dans DOC\HTML\ :
//   anglais  PLAYER_GUIDE_<n>_<NOM>.html     francais  GUIDE_JOUEUR_<n>_<NOM>_FR.html
// (n = 1 creation, 2 modification, 3 questions). Le bouton ouvre la page dans le navigateur,
// a l ancre de l etape ou de la page affichee (ex. step-3, corruption), dans la langue de l interface.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls;

const
  GuideCreation     = 1;
  GuideModification = 2;
  GuideQuestions    = 3;

// Ouvre le guide de la phase donnee a l ancre donnee (vide = haut de page) ; message si absent.
procedure OuvreGuide(Phase: Integer; const Ancre: String);

// Cree un bouton simple (TButton) sur Parent, avec son libelle, son texte F1 et son evenement.
function CreeBoutonGuide(Parent: TWinControl; const Legende, CodeAide: String;
  Gauche, Haut, Largeur: Integer; Clic: TNotifyEvent): TButton;

implementation

uses
  Dialogs, Process, chargeconstantes;

procedure OuvreGuide(Phase: Integer; const Ancre: String);
const
  Noms: array[GuideCreation..GuideQuestions] of String = ('CREATION', 'MODIFICATION', 'QUESTIONS');
var
  Fichier, Chemin, Url: String;
  Proc: TProcess;
begin
  if (Phase < GuideCreation) or (Phase > GuideQuestions) then
    Exit;
  if Pos('FRAN', UpperCase(ValLangueInterface)) > 0 then
    Fichier := 'GUIDE_JOUEUR_' + IntToStr(Phase) + '_' + Noms[Phase] + '_FR.html'
  else
    Fichier := 'PLAYER_GUIDE_' + IntToStr(Phase) + '_' + Noms[Phase] + '.html';
  Chemin := GetCurrentDir + '\DOC\HTML\' + Fichier;
  if not FileExists(Chemin) then
    begin
    ShowMessage(Chemin + ' : file not found / fichier introuvable');
    Exit;
    end;
  Url := 'file:///' + StringReplace(StringReplace(Chemin, '\', '/', [rfReplaceAll]), ' ', '%20', [rfReplaceAll]);
  if Ancre <> '' then
    Url := Url + '#' + Ancre;
  // OpenURL (ShellExecute) abime l adresse avec Brave (« "file/// ») : on passe par cmd /c start,
  // qui la transmet telle quelle au navigateur par defaut, ancre comprise.
  Proc := TProcess.Create(nil);
  try
    Proc.CommandLine := 'cmd.exe /c start "" "' + Url + '"';
    Proc.Options     := [poNoConsole];
    Proc.Execute;
  finally
    Proc.Free;
  end;
end;

function CreeBoutonGuide(Parent: TWinControl; const Legende, CodeAide: String;
  Gauche, Haut, Largeur: Integer; Clic: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Parent);
  Result.Parent      := Parent;
  Result.Caption     := Legende;
  Result.HelpKeyword := CodeAide;
  Result.SetBounds(Gauche, Haut, Largeur, 30);
  Result.Anchors     := [akTop, akRight];
  Result.TabStop     := False;
  Result.OnClick     := Clic;
end;

end.

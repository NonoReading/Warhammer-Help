unit IndicateurChargement;

// Petite fenetre sans bordure « Chargement... » (nom du livre en cours + barre de
// progression), affichee pendant la lecture des livres XML (ChargerLivre) : le demarrage
// et le changement de version / langue sont longs et l'ecran restait fige sans rien dire.
// Pas de .lfm : la fenetre est construite a l'execution. Tout est sans effet si Debut n'a
// pas ete appele.

{$mode objfpc}{$H+}

interface

  procedure ChargementDebut(const Titre: String; Total: Integer);
  procedure ChargementAvance(const NomLivre: String);
  procedure ChargementFin;

implementation

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, ComCtrls, Graphics;

var
  Fen:    TForm = nil;
  Texte:  TLabel;
  Barre:  TProgressBar;
  Titre_: String;

procedure ChargementDebut(const Titre: String; Total: Integer);
  begin
    ChargementFin;
    // modes de test / lot (--pdf, --dump, --winlivretest...) : pas de fenetre, sauf --winlivre (interactif)
    if (ParamCount >= 1) and (Copy(ParamStr(1), 1, 2) = '--') and (ParamStr(1) <> '--winlivre') then
      exit;
    if Total < 1 then
      Total := 1;
    Titre_ := Titre;
    Fen := TForm.CreateNew(Application);
    Fen.BorderStyle := bsNone;
    Fen.FormStyle   := fsStayOnTop;
    Fen.Position    := poScreenCenter;
    Fen.Width       := 420;
    Fen.Height      := 80;
    Fen.Color       := clWindow;

    Texte           := TLabel.Create(Fen);
    Texte.Parent    := Fen;
    Texte.Left      := 12;
    Texte.Top       := 12;
    Texte.AutoSize  := false;
    Texte.Width     := 396;
    Texte.Caption   := Titre;

    Barre           := TProgressBar.Create(Fen);
    Barre.Parent    := Fen;
    Barre.Left      := 12;
    Barre.Top       := 44;
    Barre.Width     := 396;
    Barre.Min       := 0;
    Barre.Max       := Total;
    Barre.Position  := 0;

    Fen.Show;
    Screen.Cursor := crHourGlass;
    Application.ProcessMessages;
  end;

procedure ChargementAvance(const NomLivre: String);
  begin
    if Fen = nil then
      exit;
    Texte.Caption  := Titre_ + ' ' + NomLivre;
    Barre.Position := Barre.Position + 1;
    Application.ProcessMessages;
  end;

procedure ChargementFin;
  begin
    if Fen = nil then
      exit;
    Screen.Cursor := crDefault;
    FreeAndNil(Fen);
  end;

end.

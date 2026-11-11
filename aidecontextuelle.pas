unit AideContextuelle;

// Aide contextuelle (touche F1) pour les joueurs.
// Un controle porte dans HelpKeyword le code d un libelle (ex. RULES-HELP_MOMENTUM) ; F1 affiche ce
// texte dans une petite fenetre, avec une image facultative PICTURES\HELP\<code>.png (sans texte, pour
// ne pas avoir a la traduire). Sans HelpKeyword sur le controle, on remonte au parent puis a la fenetre ;
// si personne n en porte, F1 ne fait rien. Le crochet est pose une fois pour toutes les fenetres.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Graphics, LCLType;

// Affiche l aide du controle (ou de son premier parent qui en a une) ; Faux si aucune aide trouvee.
function AideContextuelle(Controle: TControl): Boolean;

implementation

uses
  chargeconstantes, chargetexte;

type
  TCrochetAide = class
    procedure TouchePressee(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

var
  Crochet: TCrochetAide;

function CodeAide(Controle: TControl): String;
begin
  Result := '';
  while Controle <> nil do
    begin
    if Controle.HelpKeyword <> '' then
      Exit(Controle.HelpKeyword);
    Controle := Controle.Parent;
    end;
end;

function AideContextuelle(Controle: TControl): Boolean;
var
  Code, Texte, Image: String;
  Fiche: TForm;
  Img: TImage;
  Memo: TMemo;
  Bouton: TButton;
begin
  Result := False;
  Code := CodeAide(Controle);
  if Code = '' then
    Exit;
  Texte := GetTexteLibelle(Code);
  if (Texte = '') or (Texte = Code) then
    Exit;
  Result := True;

  Fiche := TForm.CreateNew(Application);
  try
    Fiche.Caption     := 'F1';
    Fiche.Position    := poScreenCenter;
    Fiche.BorderStyle := bsDialog;
    Fiche.ClientWidth := 420;

    Img := nil;
    Image := CheminImage(GetCurrentDir + '\PICTURES\HELP\' + Code + '.png');
    if FileExists(Image) then
      begin
      Img := TImage.Create(Fiche);
      Img.Parent       := Fiche;
      Img.Proportional := True;
      Img.Stretch      := True;
      Img.Picture.LoadFromFile(Image);
      Img.SetBounds(10, 10, 400, 150);
      end;

    Memo := TMemo.Create(Fiche);
    Memo.Parent      := Fiche;
    Memo.ReadOnly    := True;
    Memo.WordWrap    := True;
    Memo.BorderStyle := bsNone;
    Memo.ParentColor := True;
    Memo.Text        := Texte;
    if Img <> nil then
      Memo.SetBounds(10, 170, 400, 110)
    else
      Memo.SetBounds(10, 10, 400, 130);

    Bouton := TButton.Create(Fiche);
    Bouton.Parent      := Fiche;
    Bouton.Caption     := 'OK';
    Bouton.ModalResult := mrOk;
    Bouton.Default     := True;
    Bouton.SetBounds(165, Memo.Top + Memo.Height + 10, 90, 28);

    Fiche.ClientHeight := Bouton.Top + Bouton.Height + 10;
    Fiche.ShowModal;
  finally
    Fiche.Free;
  end;
end;

procedure TCrochetAide.TouchePressee(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Actif, Graphique: TControl;
begin
  if (Key <> VK_F1) or (Shift <> []) then
    Exit;
  if Screen.ActiveForm = nil then
    Exit;
  // D abord le controle sous la souris (on vise ce qu on regarde), sinon celui qui a le focus.
  Actif := FindLCLControl(Mouse.CursorPos);
  // les boutons graphiques (TBCButton) ne sont pas des controles a fenetre : on descend dans le parent
  if Actif is TWinControl then
    begin
    Graphique := TWinControl(Actif).ControlAtPos(TWinControl(Actif).ScreenToClient(Mouse.CursorPos),
      [capfAllowDisabled, capfAllowWinControls, capfRecursive]);
    if Graphique <> nil then
      Actif := Graphique;
    end;
  if (Actif <> nil) and (GetParentForm(Actif) = Screen.ActiveForm) and AideContextuelle(Actif) then
    begin
    Key := 0;
    Exit;
    end;
  Actif := Screen.ActiveForm.ActiveControl;
  if Actif = nil then
    Actif := Screen.ActiveForm;
  if AideContextuelle(Actif) then
    Key := 0;
end;

initialization
  Crochet := TCrochetAide.Create;
  Application.AddOnKeyDownBeforeHandler(@Crochet.TouchePressee);

finalization
  if Application <> nil then
    Application.RemoveOnKeyDownBeforeHandler(@Crochet.TouchePressee);
  Crochet.Free;

end.

unit ChoixOption;

{$mode objfpc}{$H+}

// Petite fenetre de choix commune (WinCreation et WinPersonnage) : une liste d options, double-clic ou Ok = prendre.

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ChargeConstantes;

// Renvoie l index choisi, -1 si annule. Actuel = option preselectionnee (-1 = la premiere).
function TowChoisitOption(const Titre, Aide: String; Options: TStringList; Actuel: Integer): Integer;

implementation

type
  TAideChoixOption = class
    procedure DblClic(Sender: TObject);
  end;

procedure TAideChoixOption.DblClic(Sender: TObject);
  begin
    if (Sender is TListBox) and (TListBox(Sender).ItemIndex >= 0) and (TListBox(Sender).Parent is TForm) then
      TForm(TListBox(Sender).Parent).ModalResult := mrOk;
  end;

var
  Aide2: TAideChoixOption = nil;

function TowChoisitOption(const Titre, Aide: String; Options: TStringList; Actuel: Integer): Integer;
  var
    F: TForm;
    Lab: TLabel;
    Liste: TListBox;
    BOk, BAnnule: TButton;
  begin
    Result := -1;
    if Aide2 = nil then Aide2 := TAideChoixOption.Create;
    F := TForm.Create(Application);
    try
      F.Caption  := Titre;
      F.Position := poOwnerFormCenter;
      F.BorderStyle := bsDialog;
      F.ClientWidth  := 520;
      F.ClientHeight := 360;
      F.Color := clBlack;
      Lab := TLabel.Create(F);
      Lab.Parent     := F;
      Lab.AutoSize   := False;
      Lab.WordWrap   := True;
      Lab.SetBounds(12, 8, 496, 52);
      Lab.Caption    := Aide;
      Lab.Font.Name  := ConstPoliceNom;
      Lab.Font.Size  := ConstPoliceTaille;
      Lab.Font.Bold  := True;
      Lab.Font.Color := clWhite;
      Liste := TListBox.Create(F);
      Liste.Parent := F;
      Liste.SetBounds(12, 64, 496, 240);
      Liste.Name := 'ListeChoixOption';
      Liste.Items.Assign(Options);
      Liste.Font.Name := ConstPoliceNom;
      Liste.Font.Size := ConstPoliceTaille;
      Liste.Font.Bold := True;
      if (Actuel >= 0) and (Actuel < Liste.Items.Count) then Liste.ItemIndex := Actuel
      else if Liste.Items.Count > 0 then Liste.ItemIndex := 0;
      BOk := TButton.Create(F);
      BOk.Parent      := F;
      BOk.Caption     := 'Ok';
      BOk.ModalResult := mrOk;
      BOk.Default     := True;
      BOk.SetBounds(300, 316, 100, 32);
      BAnnule := TButton.Create(F);
      BAnnule.Parent      := F;
      BAnnule.Caption     := 'Cancel';
      BAnnule.ModalResult := mrCancel;
      BAnnule.Cancel      := True;
      BAnnule.SetBounds(408, 316, 100, 32);
      Liste.OnDblClick := @Aide2.DblClic;
      if F.ShowModal = mrOk then Result := Liste.ItemIndex;
    finally
      F.Free;
    end;
  end;

end.

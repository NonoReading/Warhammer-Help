unit WinJetPathologie;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Spin, Dialogs, BCButton,
  GlobalFonts, Graphics, BCLabelContour;

type

  { TWinJetPathologie }

  TWinJetPathologie = class(TForm)
    ButtonAnnuler: TBCButton;
    ButtonLancer:  TBCButton;
    ButtonValider: TBCButton;
    LabelInfo:     TLabelContour;
    SpinEditJet:   TSpinEdit;
    procedure FormCreate({%H-}Sender: TObject);
    procedure ButtonLancerClick({%H-}Sender: TObject);
    procedure ButtonValiderClick({%H-}Sender: TObject);
    procedure ButtonAnnulerClick({%H-}Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
  public
  end;

var
  WinJetPathologieForm: TWinJetPathologie;
  // Entree/sortie de la fenetre - meme principe que SelectWinJet/ChoixWinJetValeur
  // (WinLanceDes) mais generique (face de de variable, pas de resolution de Talent).
  // JetPathologieFace: face du de a proposer (ex. 10 pour 1d10). JetPathologieLibelle: texte
  // affiche (nom de l'Affliction + attribut vise). JetPathologieResultat: valeur validee par
  // Nono en sortie, 0 = annule (Ajout du 27/09/2026, a la demande de Nono).
  JetPathologieFace:      Integer;
  JetPathologieLibelle:   String;
  JetPathologieResultat:  Integer;

implementation

{$R *.lfm}

procedure TWinJetPathologie.FormCreate(Sender: TObject);
  begin
    MiseEnFormeDesChamp(self);
    JetPathologieResultat := 0;
    SpinEditJet.MinValue  := 1;
    SpinEditJet.MaxValue  := JetPathologieFace;
    SpinEditJet.Value     := Random(JetPathologieFace) + 1;
    LabelInfo.Caption     := JetPathologieLibelle;
    MiseEnFormeDesChamp(self);
  end;

procedure TWinJetPathologie.ButtonLancerClick(Sender: TObject);
  begin
    SpinEditJet.Value := Random(JetPathologieFace) + 1;
  end;

procedure TWinJetPathologie.ButtonValiderClick(Sender: TObject);
  begin
    JetPathologieResultat := SpinEditJet.Value;
    Close;
  end;

procedure TWinJetPathologie.ButtonAnnulerClick(Sender: TObject);
  begin
    JetPathologieResultat := 0;
    Close;
  end;

procedure TWinJetPathologie.FormPaint(Sender: TObject);
begin
  Canvas.Pen.Color   := ClWhite;
  Canvas.Pen.Width   := 3;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(2, 2, ClientWidth - 2, ClientHeight - 2);
end;

end.

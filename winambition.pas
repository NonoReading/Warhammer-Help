unit WinAmbition;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, BCButton,
  GlobalFonts, ChargeTexte, BCLabelContour;

type

  { TWinAmbition }

  TWinAmbition = class(TForm)
    ButtonValider:          TBCButton;
    ButtonAnnuler:          TBCButton;
    LabelCourt:             TLabelContour;
    LabelLong:              TLabelContour;
    LabelGroupeCourt:       TLabelContour;
    LabelGroupeLong:        TLabelContour;
    MemoCourt:              TMemo;
    MemoLong:               TMemo;
    MemoGroupeCourt:        TMemo;
    MemoGroupeLong:         TMemo;
    procedure FormCreate({%H-}Sender: TObject);
    procedure ButtonValiderClick({%H-}Sender: TObject);
    procedure ButtonAnnulerClick({%H-}Sender: TObject);
  private
  public
  end;

var
  WinAmbitionForm: TWinAmbition;
  // Entree/sortie de la fenetre, meme principe que JetPathologie*
  // (WinJetPathologie) : les 4 champs sont pre-remplis en entree par l'appelant
  // (winpersonnage.pas) et relus en sortie seulement si AmbitionValide = True.
  // 27/09/2026, demande de Nono.
  AmbitionCourtIn, AmbitionLongIn:               String;
  AmbitionGroupeCourtIn, AmbitionGroupeLongIn:   String;
  AmbitionCourtOut, AmbitionLongOut:             String;
  AmbitionGroupeCourtOut, AmbitionGroupeLongOut: String;
  AmbitionValide:                                Boolean;
  // Vrai si le personnage est dans un groupe (CONTEXT.md 2.100) : l'ambition de groupe vient
  // alors du fichier de groupe et se lit ici en lecture seule - elle se saisit desormais
  // dans WinGroupe. Solo (False) : comportement inchange, saisie possible ici comme avant.
  AmbitionGroupeLectureSeule:                    Boolean;

implementation

{$R *.lfm}

procedure TWinAmbition.FormCreate(Sender: TObject);
  begin
    MiseEnFormeDesChamp(self);
    Caption                  := GetTexteLibelle('RULES-PDF_AMBITION1_AMBITIONS');
    LabelCourt.Caption       := GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT') + GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT');
    LabelLong.Caption        := GetTexteLibelle('RULES-PDF_AMBITION3A_LONG') + GetTexteLibelle('RULES-PDF_AMBITION3B_LONG');
    LabelGroupeCourt.Caption := GetTexteLibelle('RULES-PDF_PARTY1_PARTY') + ' - ' + GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT') + GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT');
    LabelGroupeLong.Caption  := GetTexteLibelle('RULES-PDF_PARTY1_PARTY') + ' - ' + GetTexteLibelle('RULES-PDF_AMBITION3A_LONG') + GetTexteLibelle('RULES-PDF_AMBITION3B_LONG');
    MemoCourt.Text           := AmbitionCourtIn;
    MemoLong.Text            := AmbitionLongIn;
    MemoGroupeCourt.Text     := AmbitionGroupeCourtIn;
    MemoGroupeLong.Text      := AmbitionGroupeLongIn;
    MemoGroupeCourt.ReadOnly := AmbitionGroupeLectureSeule;
    MemoGroupeLong.ReadOnly  := AmbitionGroupeLectureSeule;
    AmbitionValide           := False;
  end;

procedure TWinAmbition.ButtonValiderClick(Sender: TObject);
  begin
    AmbitionCourtOut       := MemoCourt.Text;
    AmbitionLongOut        := MemoLong.Text;
    AmbitionGroupeCourtOut := MemoGroupeCourt.Text;
    AmbitionGroupeLongOut  := MemoGroupeLong.Text;
    AmbitionValide         := True;
    Close;
  end;

procedure TWinAmbition.ButtonAnnulerClick(Sender: TObject);
  begin
    AmbitionValide := False;
    Close;
  end;

end.

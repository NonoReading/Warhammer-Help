unit WinDiseaseCatalogue;

// Consultation du catalogue des maladies (The Litany of Pestilence, Rulebook p.186-188,
// CONTEXT.md chantier "AUDIT DES TXT" Rulebook, 23/09/2026) depuis le menu principal.
// Fenetre construite en code (pas de .lfm), calquee sur WinMutationCatalogue : une grille
// en lecture seule alimentee par ListDisease.
//
// Mode selection ajoute le 27/09/2026 (a la demande de Nono, ajout/retrait sur la fiche
// personnage) : colonne 6 (cachee) porte le Code, un double-clic renseigne
// PathologieCode/PathologieLibelle (ChargeConstantes) puis ferme la fenetre - meme principe
// que WinAfflictionCatalogue. La fenetre reste utilisable en pure consultation (ex.
// Bibliotheque du menu principal) : un double-clic n'a simplement aucun effet cote appelant
// s'il ignore PathologieCode.

{$mode ObjFPC}{$H+}

interface

uses
  GlobalFonts, Classes, SysUtils, Forms, Controls, Graphics, Grids,
  ChargeConstantes, ChargeTexte, ChargeDisease;

type

  { TWinDiseaseCatalogue }

  TWinDiseaseCatalogue = class(TForm)
  private
    TabDisease: TStringGrid;
    procedure Remplir();
    procedure TabDiseaseDblClick(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  WinDiseaseCat: TWinDiseaseCatalogue;

implementation

constructor TWinDiseaseCatalogue.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner);
  Caption      := GetTexteLibelle('RULES-LAB_281');
  Color        := clBlack;
  Width        := 1200;
  Height       := 600;
  PathologieCode    := '';
  PathologieLibelle := '';
  TabDisease             := TStringGrid.Create(Self);
  TabDisease.Parent      := Self;
  CouleurSelectionGrille(TabDisease);
  TabDisease.Align       := alClient;
  TabDisease.BorderSpacing.Around := 16;
  TabDisease.FixedCols   := 0;
  TabDisease.Options     := TabDisease.Options - [goEditing] + [goRowSelect];
  TabDisease.OnDblClick  := @TabDiseaseDblClick;
  Remplir();
end;

procedure TWinDiseaseCatalogue.Remplir();
  var
    P:   StructureDisease;
    Ind: Integer = 0;
  begin
    TabDisease.ColCount := 7;
    TabDisease.RowCount := ListDisease.Count + 1;
    TabDisease.Cells[0, 0] := GetTexteLibelle('RULES-LAB_014');
    TabDisease.Cells[1, 0] := GetTexteLibelle('RULES-LAB_282');
    TabDisease.Cells[2, 0] := GetTexteLibelle('RULES-LAB_283');
    TabDisease.Cells[3, 0] := GetTexteLibelle('RULES-LAB_284');
    TabDisease.Cells[4, 0] := GetTexteLibelle('RULES-LAB_285');
    TabDisease.Cells[5, 0] := GetTexteLibelle('RULES-LAB_128');
    for P in ListDisease do
      begin
        Inc(Ind);
        TabDisease.Cells[0, Ind] := P.Libelle;
        TabDisease.Cells[1, Ind] := P.Contraction;
        TabDisease.Cells[2, Ind] := P.Incubation;
        TabDisease.Cells[3, Ind] := P.Duration;
        TabDisease.Cells[4, Ind] := P.Symptoms;
        TabDisease.Cells[5, Ind] := GetTexteLibelle(P.Livre, '', '', true);
        TabDisease.Cells[6, Ind] := P.Code;
      end;
    TabDisease.ColWidths[0] := 130;
    TabDisease.ColWidths[1] := 320;
    TabDisease.ColWidths[2] := 100;
    TabDisease.ColWidths[3] := 100;
    TabDisease.ColWidths[4] := 260;
    TabDisease.ColWidths[5] := 150;
    TabDisease.ColWidths[6] := 0;   // Code, cache - sert juste au mode selection
  end;

procedure TWinDiseaseCatalogue.TabDiseaseDblClick(Sender: TObject);
  begin
    if (TabDisease.Row < 1) then Exit;
    PathologieCode    := TabDisease.Cells[6, TabDisease.Row];
    PathologieLibelle := TabDisease.Cells[0, TabDisease.Row];
    if (PathologieCode <> '') then
      Close;
  end;

end.

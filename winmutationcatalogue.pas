unit WinMutationCatalogue;

// Consultation du catalogue des mutations (Physical/Mental Corruption Table, CONTEXT.md
// 2.7) depuis le menu principal. Fenetre construite en code (pas de .lfm) : une grille en
// lecture seule alimentee par ListCorruptionTable. Distincte de WinMutation, qui sert au
// tirage d'une mutation pour un personnage.

{$mode ObjFPC}{$H+}

interface

uses
  GlobalFonts, Classes, SysUtils, Forms, Controls, Graphics, Grids,
  StdCtrls, ChargeConstantes, ChargeTexte, ChargeCorruptionTable;

type

  { TWinMutationCatalogue }

  TWinMutationCatalogue = class(TForm)
  private
    TabMutation: TStringGrid;
    MemoDetail:  TMemo;
    procedure Remplir();
    procedure LigneChoisie(Sender: TObject; aCol, aRow: Integer);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  WinMutationCat: TWinMutationCatalogue;

implementation

uses XmlExportImport;

constructor TWinMutationCatalogue.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner);
  Caption      := GetTexteLibelle('RULES-LAB_172');
  Color        := clBlack;
  Width        := 1000;
  Height       := 600;
  // Panneau de lecture en bas : le texte complet (Effet + Variations) de la ligne choisie,
  // car la cellule de la grille coupe les longs textes.
  MemoDetail              := TMemo.Create(Self);
  MemoDetail.Parent       := Self;
  MemoDetail.Align        := alBottom;
  MemoDetail.Height       := 200;
  MemoDetail.ReadOnly     := True;
  MemoDetail.WordWrap     := True;
  MemoDetail.ScrollBars   := ssAutoVertical;
  MemoDetail.BorderSpacing.Around := 16;
  TabMutation             := TStringGrid.Create(Self);
  TabMutation.Parent      := Self;
  CouleurSelectionGrille(TabMutation);
  TabMutation.Align       := alClient;
  TabMutation.BorderSpacing.Around := 16;
  TabMutation.FixedCols   := 0;
  TabMutation.Options     := TabMutation.Options - [goEditing] + [goRowSelect];
  TabMutation.OnSelection := @LigneChoisie;
  Remplir();
end;

procedure TWinMutationCatalogue.LigneChoisie(Sender: TObject; aCol, aRow: Integer);
  var
    P: StructureCorruptionTable;
  begin
    MemoDetail.Clear;
    if (aRow < 1) or (aRow > ListCorruptionTable.Count) then Exit;
    P := ListCorruptionTable[aRow - 1];
    MemoDetail.Lines.Add(P.Libelle);
    MemoDetail.Lines.Add(TexteOuPageMutation(P.Effet, P.Livre, P.Code));
    if P.Variations <> '' then
      MemoDetail.Lines.Add('Variations : ' + P.Variations);
  end;

procedure TWinMutationCatalogue.Remplir();
  var
    P:   StructureCorruptionTable;
    Ind: Integer = 0;
  begin
    TabMutation.ColCount := 5;
    TabMutation.RowCount := ListCorruptionTable.Count + 1;
    TabMutation.Cells[0, 0] := GetTexteLibelle('RULES-LAB_171');
    TabMutation.Cells[1, 0] := GetTexteLibelle('RULES-LAB_001');
    TabMutation.Cells[2, 0] := GetTexteLibelle('RULES-LAB_014');
    TabMutation.Cells[3, 0] := GetTexteLibelle('RULES-LAB_117');
    TabMutation.Cells[4, 0] := GetTexteLibelle('RULES-LAB_128');
    for P in ListCorruptionTable do
      begin
        Inc(Ind);
        TabMutation.Cells[0, Ind] := GetTexteLibelle(P.TypeCorruption);
        TabMutation.Cells[1, Ind] := P.Code;
        TabMutation.Cells[2, Ind] := P.Libelle;
        TabMutation.Cells[3, Ind] := TexteOuPageMutation(P.Effet, P.Livre, P.Code);
        TabMutation.Cells[4, Ind] := GetTexteLibelle(P.Livre, '', '', true);
      end;
    TabMutation.ColWidths[0] := 90;
    TabMutation.ColWidths[1] := 150;
    TabMutation.ColWidths[2] := 200;
    TabMutation.ColWidths[3] := 400;
    TabMutation.ColWidths[4] := 150;
  end;

end.

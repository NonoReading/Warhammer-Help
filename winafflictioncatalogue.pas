unit WinAfflictionCatalogue;

// Consultation du catalogue des Afflictions (Unofficial Grimoire, fan book, p.30-31,
// CONTEXT.md 2.96). Fenetre construite en code (pas de .lfm), calquee sur
// WinDiseaseCatalogue : une grille en lecture seule alimentee par ListAffliction.
//
// Mode selection ajoute le 27/09/2026 (a la demande de Nono, ajout/retrait sur la fiche
// personnage) : colonne 3 (cachee) porte le Code, un double-clic renseigne
// PathologieCode/PathologieLibelle (ChargeConstantes) puis ferme la fenetre - meme principe
// sortie que WinMutation, sans tirage D100 ni jauge de Resilience a gerer ici. La fenetre
// reste utilisable en pure consultation (ex. Bibliotheque du menu principal) : un double-clic
// n'a simplement aucun effet cote appelant s'il ignore PathologieCode.

{$mode ObjFPC}{$H+}

interface

uses
  GlobalFonts, Classes, SysUtils, Forms, Controls, Graphics, Grids,
  ChargeConstantes, ChargeTexte, ChargeAffliction;

type

  { TWinAfflictionCatalogue }

  TWinAfflictionCatalogue = class(TForm)
  private
    TabAffliction: TStringGrid;
    procedure Remplir();
    procedure TabAfflictionDblClick(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  WinAfflictionCat: TWinAfflictionCatalogue;

implementation

uses XmlExportImport;

constructor TWinAfflictionCatalogue.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner);
  Caption      := GetTexteLibelle('RULES-LAB_296');
  Color        := clBlack;
  Width        := 1200;
  Height       := 600;
  PathologieCode    := '';
  PathologieLibelle := '';
  TabAffliction             := TStringGrid.Create(Self);
  TabAffliction.Parent      := Self;
  CouleurSelectionGrille(TabAffliction);
  TabAffliction.Align       := alClient;
  TabAffliction.BorderSpacing.Around := 16;
  TabAffliction.FixedCols   := 0;
  TabAffliction.Options     := TabAffliction.Options - [goEditing] + [goRowSelect];
  TabAffliction.OnDblClick  := @TabAfflictionDblClick;
  Remplir();
end;

procedure TWinAfflictionCatalogue.Remplir();
  var
    P:   StructureAffliction;
    Ind: Integer = 0;
  begin
    TabAffliction.ColCount := 4;
    TabAffliction.RowCount := ListAffliction.Count + 1;
    TabAffliction.Cells[0, 0] := GetTexteLibelle('RULES-LAB_014');
    TabAffliction.Cells[1, 0] := GetTexteLibelle('RULES-LAB_128');
    TabAffliction.Cells[2, 0] := GetTexteLibelle('RULES-LAB_117');
    for P in ListAffliction do
      begin
        Inc(Ind);
        TabAffliction.Cells[0, Ind] := P.Libelle;
        TabAffliction.Cells[1, Ind] := GetTexteLibelle(P.Livre, '', '', true);
        TabAffliction.Cells[2, Ind] := TexteOuPage(P.Effet, ConstXmlDataAffliction, P.Livre, P.Code);
        TabAffliction.Cells[3, Ind] := P.Code;
      end;
    TabAffliction.ColWidths[0] := 200;
    TabAffliction.ColWidths[1] := 150;
    TabAffliction.ColWidths[2] := 700;
    TabAffliction.ColWidths[3] := 0;   // Code, cache - sert juste au mode selection
  end;

procedure TWinAfflictionCatalogue.TabAfflictionDblClick(Sender: TObject);
  begin
    if (TabAffliction.Row < 1) then Exit;
    PathologieCode    := TabAffliction.Cells[3, TabAffliction.Row];
    PathologieLibelle := TabAffliction.Cells[0, TabAffliction.Row];
    if (PathologieCode <> '') then
      Close;
  end;

end.

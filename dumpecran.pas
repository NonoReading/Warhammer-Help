unit DumpEcran;

// Mode --dumpwinlivre : ecrit en texte ce que la fiche affichee montrerait a l ecran
// (libelles, champs, listes deroulantes, cases, grilles), pour le lire sans voir la fenetre.
// Meme idee que --dumppdf. Ne parcourt que les controles visibles.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, ComCtrls, BCLabelContour, BCButton, Spin, StrUtils;

// Ajoute a Sortie la description des controles visibles sous Racine (Niveau = indentation de depart).
procedure DumpControles(Racine: TWinControl; Niveau: Integer; Sortie: TStrings);

implementation

const
  MAX_CHOIX = 40;
  MAX_LIGNES = 200;

function Retrait(Niveau: Integer): String;
begin
  Result := StringOfChar(' ', Niveau * 2);
end;

function Propre(const S: String): String;
begin
  Result := StringReplace(StringReplace(S, #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]);
end;

procedure DumpGrille(G: TStringGrid; Niveau: Integer; Sortie: TStrings);
var
  L, C: Integer;
  Ligne, Cellule: String;
  Max: Integer;
begin
  Sortie.Add(Retrait(Niveau) + 'GRILLE ' + G.Name + ' : ' + IntToStr(G.RowCount - G.FixedRows) + ' lignes x ' +
    IntToStr(G.ColCount) + ' colonnes');
  Max := G.RowCount - 1;
  if Max > MAX_LIGNES then Max := MAX_LIGNES;
  for L := 0 to Max do
  begin
    Ligne := '';
    for C := 0 to G.ColCount - 1 do
    begin
      if G.ColWidths[C] <= 0 then Continue;  // colonne cachee
      Cellule := Propre(G.Cells[C, L]);
      if Ligne <> '' then Ligne := Ligne + ' | ';
      Ligne := Ligne + Cellule;
    end;
    if L < G.FixedRows then Sortie.Add(Retrait(Niveau + 1) + '# ' + Ligne)
    else Sortie.Add(Retrait(Niveau + 1) + Ligne);
  end;
  if G.RowCount - 1 > MAX_LIGNES then
    Sortie.Add(Retrait(Niveau + 1) + '... (' + IntToStr(G.RowCount - 1 - MAX_LIGNES) + ' lignes de plus)');
end;

procedure DumpCombo(Cb: TComboBox; Niveau: Integer; Sortie: TStrings);
var
  I, N: Integer;
  Choix: String;
begin
  N := Cb.Items.Count;
  if N > MAX_CHOIX then N := MAX_CHOIX;
  Choix := '';
  for I := 0 to N - 1 do
  begin
    if Choix <> '' then Choix := Choix + ', ';
    Choix := Choix + Propre(Cb.Items[I]);
  end;
  if Cb.Items.Count > MAX_CHOIX then Choix := Choix + ', ... (' + IntToStr(Cb.Items.Count) + ' choix)';
  Sortie.Add(Retrait(Niveau) + 'LISTE ' + Cb.Name + ' = "' + Propre(Cb.Text) + '"  choix : ' + Choix);
end;

procedure DumpControles(Racine: TWinControl; Niveau: Integer; Sortie: TStrings);
var
  I: Integer;
  Ctl: TControl;
begin
  for I := 0 to Racine.ControlCount - 1 do
  begin
    Ctl := Racine.Controls[I];
    if not Ctl.Visible then Continue;
    if Ctl is TStringGrid then
      DumpGrille(TStringGrid(Ctl), Niveau, Sortie)
    else if Ctl is TComboBox then
      DumpCombo(TComboBox(Ctl), Niveau, Sortie)
    else if Ctl is TCheckBox then
    begin
      if TCheckBox(Ctl).Checked then
        Sortie.Add(Retrait(Niveau) + 'CASE [x] ' + Propre(TCheckBox(Ctl).Caption))
      else
        Sortie.Add(Retrait(Niveau) + 'CASE [ ] ' + Propre(TCheckBox(Ctl).Caption));
    end
    else if Ctl is TLabel then
    begin
      if TLabel(Ctl).Caption <> '' then
        Sortie.Add(Retrait(Niveau) + 'LIBELLE "' + Propre(TLabel(Ctl).Caption) + '"');
    end
    else if Ctl is TLabelContour then
    begin
      if TLabelContour(Ctl).Caption <> '' then
        Sortie.Add(Retrait(Niveau) + 'LIBELLE "' + Propre(TLabelContour(Ctl).Caption) + '"');
    end
    else if Ctl is TBCButton then
      Sortie.Add(Retrait(Niveau) + 'BCBOUTON ' + Ctl.Name + ' "' + Propre(TBCButton(Ctl).Caption) + '"' +
        IfThen(Ctl.Enabled, '', ' (inactif)'))
    else if Ctl is TCustomFloatSpinEdit then
      Sortie.Add(Retrait(Niveau) + 'NOMBRE ' + Ctl.Name + ' = ' + FloatToStr(TCustomFloatSpinEdit(Ctl).Value))
    else if Ctl is TMemo then
      Sortie.Add(Retrait(Niveau) + 'MEMO ' + Ctl.Name + ' = "' + Propre(TMemo(Ctl).Text) + '"' +
        '  (lecture seule : ' + BoolToStr(TMemo(Ctl).ReadOnly, True) + ')')
    else if Ctl is TEdit then
      Sortie.Add(Retrait(Niveau) + 'CHAMP ' + Ctl.Name + ' = "' + Propre(TEdit(Ctl).Text) + '"' +
        '  (lecture seule : ' + BoolToStr(TEdit(Ctl).ReadOnly, True) + ')')
    else if Ctl is TButton then
      Sortie.Add(Retrait(Niveau) + 'BOUTON "' + Propre(TButton(Ctl).Caption) + '"')
    else if Ctl is TRadioButton then
      Sortie.Add(Retrait(Niveau) + 'RADIO ' + BoolToStr(TRadioButton(Ctl).Checked, True) + ' "' +
        Propre(TRadioButton(Ctl).Caption) + '"')
    else if Ctl is TListBox then
      Sortie.Add(Retrait(Niveau) + 'LISTBOX ' + Ctl.Name + ' : ' + IntToStr(TListBox(Ctl).Items.Count) + ' elements');
    if Ctl is TWinControl then
      DumpControles(TWinControl(Ctl), Niveau + 1, Sortie);
  end;
end;

end.

unit WinFiltre;

{$mode ObjFPC}{$H+}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  BCButton, ChargeTexte, ChargeConstantes, GlobalFonts, ChargeEspece,
  ChargeTalent, ChargeAttribut, XmlExportImport, UnitCalcul, ChargeLivre, ChargeSort, BCLabelContour;

type

  { TWinFiltre }

  TWinFiltre = class(TForm)
    ButtonValider: TBCButton;
    LabelLivre: TLabelContour;
    LabelRace: TLabelContour;
    LabelGroupe: TLabelContour;
    LabelTalent: TLabelContour;
    LabelAttribut: TLabelContour;
    TabTalent: TStringGrid;
    TabLivre: TStringGrid;
    TabRace: TStringGrid;
    TabGroupe: TStringGrid;
    TabAttribut: TStringGrid;
    procedure ButtonValiderClick({%H-}Sender: TObject);
    procedure ChargeLivre();
    procedure ChargeRace();
    procedure ChargeGroupe();
    procedure ChargeTalent(SortSeul: Boolean);
    procedure ChargeAttribut();
    procedure ChargeLoreV2();
    procedure ChargeListesV2();
    procedure FormCreate({%H-}Sender: TObject);
    procedure TabAttributDblClick(Sender: TObject);
    procedure TabAttributMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TabGroupeDblClick({%H-}Sender: TObject);
    procedure TabGroupeMouseDown({%H-}Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure TabLivreDblClick({%H-}Sender: TObject);
    procedure TabLivreMouseDown({%H-}Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure TabRaceDblClick({%H-}Sender: TObject);
    procedure TabRaceMouseDown({%H-}Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure TabTalentDblClick({%H-}Sender: TObject);
    procedure TabTalentMouseDown({%H-}Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
  private
    CaseBase: TCheckBox;   // creee a l'execution (filtre des carrieres V1 / V2), pas dans le .lfm
    EtiquetteBase: TLabelContour;
    procedure EtiquetteBaseClick({%H-}Sender: TObject);

  public

  end;

var
  WinFiltres:           TWinFiltre;

implementation

{$R *.lfm}

procedure TWinFiltre.EtiquetteBaseClick(Sender: TObject);
begin
  CaseBase.Checked := not CaseBase.Checked;
end;

procedure TWinFiltre.ChargeLivre();
  var
    searchResult:  TSearchRec;
    directoryPath: string;
    i:             Integer = 0;
    Ordre:         String;
    Nom:           String;
    ListeLocale:   String = '';
    PLivre:        StructureLivre;
  begin
    LabelLivre.Caption         := GetTexteLibelle('RULES-LAB_128');

    TabLivre.Clear;
    // mise en forme du tableau de création du Livre
    TabLivre.ColCount         := 5;
    TabLivre.RowCount         := 10;
    TabLivre.ColWidths[0]     := 0;
    TabLivre.ColWidths[1]     := 20;
    TabLivre.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabLivre.ColWidths[2]     := 230;
    TabLivre.ColWidths[3]     := 0;
    TabLivre.ColWidths[4]     := 0;

    directoryPath := GetCurrentDir + ConstCheminLivre;
    if FindFirst(directoryPath + '*.xml', faAnyFile, searchResult) = 0 then
    begin
      repeat
        Nom := XmlLivre(ExtractStringBefore(searchResult.Name,'.'));

        if pos(AjouteAccolade(Nom), ListeLocale) = 0 then
        begin
          Inc(i);
          if TabLivre.RowCount <= i then
            TabLivre.RowCount      := TabLivre.RowCount + 1;
          if (ListeLocale = '') or (Pos(AjouteAccolade(Nom), ListeLivre) > 0) then
            begin
              TabLivre.Cells[1, I] := ConstSelectionne;
            end;
          ListeLocale              := ListeLocale + AjouteAccolade(Nom);
          TabLivre.Cells[2, I]     := GetTexteLibelle(Nom,'','',true);
          TabLivre.Cells[3, I]     := Nom;
          PLivre                   := ChercheLivreLibelle(Nom);
          Ordre                    := IntToStr(PLivre.Officiel);
          TabLivre.Cells[4, I]     := Ordre+Nom;
        end;
      until FindNext(searchResult) <> 0;
      FindClose(searchResult);
    end;

    // lignes de remplissage (10 au depart) retirees : elles montaient en tete au tri et comptaient
    // comme "non coche" dans ButtonValiderClick
    TabLivre.RowCount := i + 1;
    TabLivre.SortColRow(true,4);

  end;

procedure TWinFiltre.ChargeRace();
  var
    IndTab:        Integer = 0;
    PEspece:       StructureEspece;
  begin
    LabelRace.Caption         := GetTexteLibelle('RULES-LAB_042');

    TabRace.Clear;
    // mise en forme du tableau de création du Race
    TabRace.ColCount         := 4;
    TabRace.RowCount         := 10;
    TabRace.ColWidths[0]     := 0;
    TabRace.ColWidths[1]     := 20;
    TabRace.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabRace.ColWidths[2]     := 230;
    TabRace.ColWidths[3]     := 0;

    // Les RACES (Human, Halfling...) et non leurs ethnies : le filtre porte le code de race
    for PEspece in ListEspece do
      begin
          Inc(IndTab);
          if TabRace.RowCount <= IndTab then
            TabRace.RowCount := TabRace.RowCount + 1;
          if VerifieFiltre(PEspece.CodeEspece, SelectWinRace) then
            TabRace.Cells[1, IndTab] := ConstSelectionne;
          TabRace.Cells[2, IndTab]   := PEspece.Libelle;
          TabRace.Cells[3, IndTab]   := PEspece.CodeEspece;
    end;
    TabRace.RowCount := IndTab + 1;

  end;

procedure TWinFiltre.ChargeTalent(SortSeul: Boolean);
  var
    IndTab:        Integer = 0;
    PTalent:       StructureTalent;
    FamilleSort:   TStringList;
  begin
    LabelTalent.Caption         := GetTexteLibelle('RULES-LAB_007');

    TabTalent.Clear;
    // mise en forme du tableau de création du Talent
    TabTalent.ColCount         := 4;
    TabTalent.RowCount         := 10;
    TabTalent.ColWidths[0]     := 0;
    TabTalent.ColWidths[1]     := 20;
    TabTalent.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabTalent.ColWidths[2]     := 230;
    TabTalent.ColWidths[3]     := 0;

    // Quels talents concernent les sorts : lu dans les DONNEES (<Magic>/<SpellMode>), plus dans
    // les quatre constantes TalentSortXxx supprimees le 23/08/2026. CONTEXT.md 2.18.
    //
    // En deux temps, parce que la liste parcourue plus bas contient les SPECIALISATIONS
    // (RULES-T0012_HANDRICH) alors que <Magic>/<SpellMode> ne sont declares que sur l'entree
    // GENERIQUE (RULES-T0012_*). On releve donc d'abord les FAMILLES concernees - le code prive
    // de son "_specialisation" - puis on teste l'appartenance. Passer par ChercheTalent ligne a
    // ligne donnerait le meme resultat mais ferait 800 x 800 comparaisons a l'ouverture.
    //
    // La liste n'est construite que si SortSeul : dans l'autre cas elle ne sert a rien.
    FamilleSort := TStringList.Create;
    if SortSeul then
      for PTalent in ListTalent do
        if (PTalent.Magie <> ConstMagieAucune)
            or ((PTalent.ModeSort <> '') and (PTalent.ModeSort <> ConstModeSortAucun)) then
          FamilleSort.Add(RadicalTalent(PTalent.CodeTalent));

    for PTalent in ListTalent do
      begin
        if (pos(ValeurGenerique,PTalent.CodeTalent) = 0)
            and (pos(SeparateurMulti,PTalent.CodeTalent) = 0) then
          if (not SortSeul and (CodeFamilleTalent(PTalent.CodeTalent) = ''))
              or (SortSeul and (FamilleSort.IndexOf(RadicalTalent(PTalent.CodeTalent)) >= 0)) then
            begin
              Inc(IndTab);
              if TabTalent.RowCount <= IndTab then
                TabTalent.RowCount := TabTalent.RowCount + 1;
              if VerifieFiltre(PTalent.CodeTalent, SelectWinTalent) then
                TabTalent.Cells[1, IndTab] := ConstSelectionne;
              TabTalent.Cells[2, IndTab]   := PTalent.Libelle;
              TabTalent.Cells[3, IndTab]   := PTalent.CodeTalent;
            end;
    end;
    FamilleSort.Free;
    TabTalent.RowCount := IndTab + 1;
    TabTalent.SortColRow(true,2);

  end;

// Sorts WFRP2 : pas de talent de sort, le filtre porte sur le Lore (TypeSort, grille Talent reutilisee)
// et sur les listes de sorts (champ SpellLists, grille Groupe reutilisee).
procedure TWinFiltre.ChargeLoreV2();
  var
    IndTab:  Integer = 0;
    PSort:   StructureSort;
    Vus:     TStringList;
  begin
    LabelTalent.Caption         := GetTexteLibelle('RULES-LAB_018');

    TabTalent.Clear;
    TabTalent.ColCount         := 4;
    TabTalent.RowCount         := 1;
    TabTalent.ColWidths[0]     := 0;
    TabTalent.ColWidths[1]     := 20;
    TabTalent.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabTalent.ColWidths[2]     := 230;
    TabTalent.ColWidths[3]     := 0;

    Vus := TStringList.Create;
    try
      for PSort in ListSort do
        if (PSort.TypeSort <> '') and (Pos(ValeurGenerique, PSort.CodeSort) = 0)
            and (Vus.IndexOf(PSort.TypeSort) < 0) then
          begin
            Vus.Add(PSort.TypeSort);
            Inc(IndTab);
            TabTalent.RowCount := IndTab + 1;
            if VerifieFiltre(PSort.TypeSort, SelectWinTalent) then
              TabTalent.Cells[1, IndTab] := ConstSelectionne;
            TabTalent.Cells[2, IndTab]   := GetTexteLibelle(PSort.TypeSort);
            TabTalent.Cells[3, IndTab]   := PSort.TypeSort;
          end;
    finally
      Vus.Free;
    end;
    TabTalent.SortColRow(true,2);
  end;

procedure TWinFiltre.ChargeListesV2();
  var
    IndTab:  Integer = 0;
    PSort:   StructureSort;
    Vus:     TStringList;
    Noms:    TStringList;
    Ind:     Integer;
    Nom:     String;
  begin
    LabelGroupe.Caption         := GetTexteLibelle('RULES-LAB_757');

    TabGroupe.Clear;
    TabGroupe.ColCount         := 4;
    TabGroupe.RowCount         := 1;
    TabGroupe.ColWidths[0]     := 0;
    TabGroupe.ColWidths[1]     := 20;
    TabGroupe.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabGroupe.ColWidths[2]     := 230;
    TabGroupe.ColWidths[3]     := 0;

    Vus  := TStringList.Create;
    Noms := TStringList.Create;
    try
      for PSort in ListSort do
        if PSort.ListesSorts <> '' then
          begin
            Noms.Clear;
            ExtractStrings([','], [' '], PChar(PSort.ListesSorts), Noms);
            for Ind := 0 to Noms.Count - 1 do
              begin
                Nom := Trim(Noms[Ind]);
                if (Nom <> '') and (Vus.IndexOf(Nom) < 0) then
                  begin
                    Vus.Add(Nom);
                    Inc(IndTab);
                    TabGroupe.RowCount := IndTab + 1;
                    if VerifieFiltre(Nom, SelectWinGroupe) then
                      TabGroupe.Cells[1, IndTab] := ConstSelectionne;
                    TabGroupe.Cells[2, IndTab]   := Nom;
                    TabGroupe.Cells[3, IndTab]   := Nom;
                  end;
              end;
          end;
    finally
      Noms.Free;
      Vus.Free;
    end;
    TabGroupe.SortColRow(true,2);
  end;

procedure TWinFiltre.ChargeGroupe();
  var
    IndTab:        Integer = 0;
    PGroupe:       String;
  begin
    LabelGroupe.Caption         := GetTexteLibelle('RULES-LAB_039');

    TabGroupe.Clear;
    // mise en forme du tableau de création du Groupe
    TabGroupe.ColCount         := 4;
    TabGroupe.RowCount         := 1;
    TabGroupe.ColWidths[0]     := 0;
    TabGroupe.ColWidths[1]     := 20;
    TabGroupe.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabGroupe.ColWidths[2]     := 230;
    TabGroupe.ColWidths[3]     := 0;

    for PGroupe in ListGroup do
      begin
          Inc(IndTab);
          if TabGroupe.RowCount <= IndTab then
            TabGroupe.RowCount := TabGroupe.RowCount + 1;
          if VerifieFiltre(PGroupe, SelectWinGroupe) then
            TabGroupe.Cells[1, IndTab] := ConstSelectionne;
          TabGroupe.Cells[2, IndTab]   := GetTexteLibelle(PGroupe);
          TabGroupe.Cells[3, IndTab]   := PGroupe;
      end;

  end;

procedure TWinFiltre.ChargeAttribut();
  var
    IndTab:        Integer = 0;
    PAttribut:     StructureAttribut;
  begin
    LabelAttribut.Caption         := GetTexteLibelle('RULES-LAB_008');

    TabAttribut.Clear;
    // mise en forme du tableau de création du Attribut
    TabAttribut.ColCount         := 5;
    TabAttribut.RowCount         := 1;
    TabAttribut.ColWidths[0]     := 0;
    TabAttribut.ColWidths[1]     := 20;
    TabAttribut.Cells[2, 0]      := GetTexteLibelle('RULES-LAB_014');
    TabAttribut.ColWidths[2]     := 230;
    TabAttribut.ColWidths[3]     := 0;
    TabAttribut.ColWidths[4]     := 30;
    TabAttribut.Cells[4, 0]      := GetTexteLibelle('RULES-LAB_019');

    for PAttribut in ListeAttribut do
      begin
          if IndTab < 9 then
            begin
              AttributNiveau := '';
              Inc(IndTab);
              if TabAttribut.RowCount <= IndTab then
                TabAttribut.RowCount := TabAttribut.RowCount + 1;
              if VerifieFiltre(PAttribut.CodeAttribut, SelectWinAttribut) then
                begin
                  TabAttribut.Cells[1, IndTab] := ConstSelectionne;
                  if AttributNiveau <> '' then
                    TabAttribut.Cells[4, IndTab] := ExtractStringAfter(enleveaccolade(AttributNiveau),SeparateurDetail)
                  else
                    TabAttribut.Cells[4, IndTab]   := '0';
                end
              else
                TabAttribut.Cells[4, IndTab]   := '0';
              TabAttribut.Cells[2, IndTab]   := PAttribut.Libelle;
              TabAttribut.Cells[3, IndTab]   := PAttribut.CodeAttribut;

            end
      end;

  end;

procedure TWinFiltre.ButtonValiderClick(Sender: TObject);
Var
  Ind:   integer;
  NbNon: integer = 0;
begin
  ChoixWinLivre := '';
  if TabLivre.Visible then
    For Ind := 1 to (tabLivre.RowCount-1) do
      if TabLivre.Cells[1, Ind] = ConstSelectionne then
        ChoixWinLivre := ChoixWinLivre + AjouteAccolade(TabLivre.Cells[3, Ind])
      else
        inc(NbNon);
  if NbNon = 0 then
    ChoixWinLivre := ''
  else
    NbNon := 0;

  ChoixWinRace := '';
  if TabRace.visible then
    For Ind := 1 to (tabRace.RowCount-1) do
      if TabRace.Cells[1, Ind] = ConstSelectionne then
        ChoixWinRace := ChoixWinRace + AjouteAccolade(TabRace.Cells[3, Ind])
      else
        inc(NbNon);
  if NbNon = 0 then
    ChoixWinRace := ''
  else
    NbNon := 0;

  ChoixWinGroupe := '';
  if tabGroupe.Visible then
    For Ind := 1 to (tabGroupe.RowCount-1) do
      if TabGroupe.Cells[1, Ind] = ConstSelectionne then
        ChoixWinGroupe := ChoixWinGroupe + AjouteAccolade(TabGroupe.Cells[3, Ind])
      else
        inc(NbNon);
  if NbNon = 0 then
    ChoixWinGroupe := ''
  else
    NbNon := 0;

  ChoixWinTalent := '';
  if tabTalent.Visible then
    For Ind := 1 to (tabTalent.RowCount-1) do
      if TabTalent.Cells[1, Ind] = ConstSelectionne then
        ChoixWinTalent := ChoixWinTalent + AjouteAccolade(TabTalent.Cells[3, Ind])
      else
        inc(NbNon);
  if NbNon = 0 then
    ChoixWinTalent := ''
  else
    NbNon := 0;

  ChoixWinBase := Assigned(CaseBase) and CaseBase.Checked;

  ChoixWinAttribut := '';
  if tabAttribut.Visible then
    For Ind := 1 to (tabAttribut.RowCount-1) do
      if TabAttribut.Cells[1, Ind] = ConstSelectionne then
        ChoixWinAttribut := ChoixWinAttribut + AjouteAccolade(TabAttribut.Cells[3, Ind] + SeparateurDetail + TabAttribut.Cells[4, Ind])
      else
        inc(NbNon);
  if NbNon = 0 then
    ChoixWinAttribut := ''
  else
    NbNon := 0;

  Close
end;

procedure TWinFiltre.FormCreate(Sender: TObject);
Var
  AffLivre:  Boolean = False;
  AffRace:   Boolean = False;
  AffGroupe: Boolean = False;
  AffTalent: Boolean = False;
  AffAttribut:  Boolean = False;
  SortSeul:  Boolean = False;
  PosX:      Integer = 10;
begin
  // Carrieres V1 / V2 : case « carrieres de base seulement » (balise Basic), a droite du bouton Valider.
  // Creee AVANT MiseEnFormeDesChamp pour que son etiquette prenne le style des titres (le texte d'une
  // case a cocher themee reste noir sur le fond noir de la fenetre).
  if (WinFiltreAppelant = ConstXmlWork) and ((ValVersion = 'WFRP2') or (ValVersion = 'WFRP1')) then
    begin
      CaseBase            := TCheckBox.Create(Self);
      CaseBase.Parent     := Self;
      CaseBase.Caption    := '';
      CaseBase.Left       := ButtonValider.Left + ButtonValider.Width + 20;
      CaseBase.Top        := ButtonValider.Top + 14;
      CaseBase.Checked    := SelectWinBase;
      EtiquetteBase            := TLabelContour.Create(Self);
      EtiquetteBase.Parent     := Self;
      EtiquetteBase.Caption    := GetTexteLibelle('RULES-LAB_FILTRE_BASE');
      EtiquetteBase.Font.Color := clWhite;
      EtiquetteBase.Font.Height:= -27;
      EtiquetteBase.Left       := CaseBase.Left + 28;
      EtiquetteBase.Top        := ButtonValider.Top + 4;
      EtiquetteBase.OnClick    := @EtiquetteBaseClick;
    end;
  MiseEnFormeDesChamp(self);
  // grilles sans saisie : ligne entiere selectionnee, couleur commune
  SelectionGrilleWarhammer(TabTalent);
  SelectionGrilleWarhammer(TabLivre);
  SelectionGrilleWarhammer(TabRace);
  SelectionGrilleWarhammer(TabGroupe);
  SelectionGrilleWarhammer(TabAttribut);

  ButtonValider.Caption  := GetTexteLibelle('RULES-LAB_086');

  AffLivre := True;
  if WinFiltreAppelant = ConstXmlWork then
    begin
      AffRace  := True;
      AffGroupe:= True;
      AffTalent:= True;
      AffAttribut := True;
    end
  else if WinFiltreAppelant = ConstXmlSort then
    begin
      SortSeul := True;
      AffTalent:= True;
      AffGroupe:= (ValVersion = 'WFRP2');      // listes de sorts (V2 seulement)
    end;

  if AffLivre then
    Begin
      ChargeLivre();
      LabelLivre.visible     := true;
      TabLivre.visible   := true;
      TabLivre.Enabled   := true;
      LabelLivre.left        := PosX;
      TabLivre.left      := PosX;
      AdjustGridColumnsWidth(TabLivre, 0, false, false);
      PosX               := 10 + TabLivre.left + TabLivre.Width;
    end;

  if AffRace then
    Begin
      ChargeRace();
      LabelRace.visible    := true;
      TabRace.visible   := true;
      TabRace.Enabled   := true;
      LabelRace.left       := PosX;
      TabRace.left      := PosX;
      AdjustGridColumnsWidth(TabRace, 0, false, false);
      PosX              := 10 + TabRace.left + TabRace.Width;
    end;

  if AffGroupe then
    begin
      if SortSeul then
        ChargeListesV2()
      else
        ChargeGroupe();
      LabelGroupe.visible    := true;
      TabGroupe.visible := true;
      TabGroupe.Enabled := true;
      LabelGroupe.left       := PosX;
      TabGroupe.left    := PosX;
      AdjustGridColumnsWidth(TabGroupe, 0, false, false);
      PosX              := 10 + TabGroupe.left + TabGroupe.Width;
    end;

  if AffTalent then
    begin
      if SortSeul and (ValVersion = 'WFRP2') then
        ChargeLoreV2()
      else
        ChargeTalent(SortSeul);
      LabelTalent.visible    := true;
      TabTalent.visible := true;
      TabTalent.Enabled := true;
      LabelTalent.left       := PosX;
      TabTalent.left    := PosX;
      AdjustGridColumnsWidth(TabTalent, 0, false, false);
      PosX              := 10 + TabTalent.left + TabTalent.Width;
    end;

  if AffAttribut then
    begin
      ChargeAttribut();
      LabelAttribut.visible    := true;
      TabAttribut.visible := true;
      TabAttribut.Enabled := true;
      LabelAttribut.left       := PosX;
      TabAttribut.left    := PosX;
      AdjustGridColumnsWidth(TabAttribut, 0, false, false);
      PosX              := 10 + TabAttribut.left + TabAttribut.Width;
    end;

    //ButtonValider.left  := PosX + ButtonValider.Width;

    Width := PosX;

end;

procedure TWinFiltre.TabAttributDblClick(Sender: TObject);
var
  Ind:   Integer;
  Coche: String = ConstSelectionne;
  aCol, aRow: Integer;
  P : TPoint;
begin
  P := TabAttribut.ScreenToClient(Mouse.CursorPos);
  TabAttribut.MouseToCell(P.X, P.Y, ACol, ARow);
  if ACol = 1 then
    begin
      if TabAttribut.Cells[1,1] = ConstSelectionne then
        Coche := '';
      for Ind := 1 to TabAttribut.RowCount - 1 do
        TabAttribut.Cells[1, Ind] := Coche;
    end;
end;

procedure TWinFiltre.TabGroupeDblClick(Sender: TObject);
var
  Ind:   Integer;
  Coche: String = ConstSelectionne;
begin
  if TabGroupe.Cells[1,1] = ConstSelectionne then
    Coche := '';
  for Ind := 1 to TabGroupe.RowCount - 1 do
    TabGroupe.Cells[1, Ind] := Coche;

end;

procedure TWinFiltre.TabGroupeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  aCol, aRow: Integer;
begin
  TabGroupe.MouseToCell(X, Y, ACol, ARow);
  if (ARow > 0) then
    if TabGroupe.Cells[1, aRow] = ConstSelectionne then
      TabGroupe.Cells[1, aRow]    := ''
    else
      TabGroupe.Cells[1, aRow]    := ConstSelectionne;
end;

procedure TWinFiltre.TabLivreDblClick(Sender: TObject);
var
  Ind:   Integer;
  Coche: String = ConstSelectionne;
begin
  if TabLivre.Cells[1,1] = ConstSelectionne then
    Coche := '';
  for Ind := 1 to TabLivre.RowCount - 1 do
    TabLivre.Cells[1, Ind] := Coche;
end;

procedure TWinFiltre.TabLivreMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  aCol, aRow: Integer;
begin
  TabLivre.MouseToCell(X, Y, ACol, ARow);
  if (ARow > 0) then
    if TabLivre.Cells[1, aRow] = ConstSelectionne then
      TabLivre.Cells[1, aRow]     := ''
    else
      TabLivre.Cells[1, aRow]     := ConstSelectionne;
end;

procedure TWinFiltre.TabRaceDblClick(Sender: TObject);
var
  Ind:   Integer;
  Coche: String = ConstSelectionne;
begin
  if TabRace.Cells[1,1] = ConstSelectionne then
    Coche := '';
  for Ind := 1 to TabRace.RowCount - 1 do
    TabRace.Cells[1, Ind] := Coche;
end;

procedure TWinFiltre.TabRaceMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  aCol, aRow: Integer;
begin
  TabRace.MouseToCell(X, Y, ACol, ARow);
  if (ARow > 0) then
    if TabRace.Cells[1, aRow] = ConstSelectionne then
      TabRace.Cells[1, aRow]      := ''
    else
      TabRace.Cells[1, aRow]      := ConstSelectionne;

end;

procedure TWinFiltre.TabTalentDblClick(Sender: TObject);
var
  Ind:   Integer;
  Coche: String = ConstSelectionne;
begin
  if TabTalent.Cells[1,1] = ConstSelectionne then
    Coche := '';
  for Ind := 1 to TabTalent.RowCount - 1 do
    TabTalent.Cells[1, Ind] := Coche;
end;

procedure TWinFiltre.TabTalentMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  aCol, aRow: Integer;
begin
  TabTalent.MouseToCell(X, Y, ACol, ARow);
  if (ARow > 0) then
    if TabTalent.Cells[1, aRow] = ConstSelectionne then
      TabTalent.Cells[1, aRow]      := ''
    else
      TabTalent.Cells[1, aRow]      := ConstSelectionne;

end;

procedure TWinFiltre.TabAttributMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  aCol, aRow: Integer;
  Num:        Integer;
begin
  TabAttribut.MouseToCell(X, Y, ACol, ARow);
  if (ACol = 4) then
    if TabAttribut.Cells[1, aRow] <> ConstSelectionne then
      TabAttribut.Cells[1, aRow]      := ConstSelectionne
    else
      begin
        Num := StrToInt(TabAttribut.Cells[4, aRow]) + 1;
        if Num > 4 then
          Num := 0;
        TabAttribut.Cells[4, aRow]      := IntToStr(Num);
      end
  else if (ARow > 0) then
    if TabAttribut.Cells[1, aRow] = ConstSelectionne then
      TabAttribut.Cells[1, aRow]      := ''
    else
      TabAttribut.Cells[1, aRow]      := ConstSelectionne;
end;

end.


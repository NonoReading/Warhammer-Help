unit WinOptionRegle;

{$mode ObjFPC}{$H+}

interface

uses
  GlobalFonts, Classes, SysUtils, Forms, Controls, Grids, StdCtrls, ExtCtrls, ChargeConstantes,
  ChargeOptionRegle, ChargeRegle, ChargeTexte, ChargeSigneAstral,
  ChargeMetierSousMetier, ChargeMetierRaceChoixMetier;

type

  { TPanelOptionRegle }

  // Tableau des regles optionnelles des livres charges (options de livre + regles de tirage de
  // metier) : case a cocher, livre, libelle, et en dessous l'explication de la ligne choisie.
  // Reutilise par la fenetre TWinOptionRegle ET par la page des livres du menu (12/11/2026).
  // Construit en code (pas de .lfm). Charger() peut etre rappele apres un rechargement des livres.
  TPanelOptionRegle = class(TPanel)
  private
    TabOption:        TStringGrid;
    MemoExplication:  TMemo;
    RowIndex:         array of Integer; // ligne grille -> indice dans ListOptionRegle
    RowRegle:         array of Integer; // ligne grille -> indice dans ListRegle (-1 : c'est une option)
    RowCle:           array of String;  // ligne « par livre » (second jet, choix par espece) : cle de la case, sinon ''
    RowExpl:          array of String;  // ... et code du texte d'explication de cette ligne
    // Indices REELS des colonnes, renvoyes par GridAjouteColonne (jamais 0 : la
    // colonne fixe 0 d'une grille demarree a ColCount=1 n'est pas selectionnable au
    // clic - meme convention que TabLivre/ColLivreSel, warhammersource.pas. Ecrire
    // ou tester Col=0 rendait la case a cocher inutilisable (trouve par Nono en
    // essayant de cocher/decocher, 22/09/2026).
    ColActif:         Integer;
    ColLivre:         Integer;
    ColOption:        Integer;
    ColonnesCreees:   Boolean;
    LargLivre:        Integer;
    LargOption:       Integer;
    ModeRegles:       Boolean;
    procedure AjouteLigneLivre(Livre, Prefixe, CodeLibelle, CodeExpl: String; var Row: Integer);
    procedure TabOptionClick(Sender: TObject);
    procedure TabOptionSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  public
    // Livres coches (codes entre accolades) dont on montre les regles ; vide = tous les livres charges.
    FiltreLivres:     String;
    // Appele apres chaque case basculee (WinCreation y recharge la liste des regles).
    OnChangement:     TNotifyEvent;
    // AModeRegles = vrai : regles de tirage, choix valable pour la creation en cours seulement (WinCreation).
    // Faux : options de livre (armures rapides, signes, carrieres alternatives), gardees dans l'INI.
    constructor Create(TheOwner: TComponent; AModeRegles: Boolean; ALargLivre, ALargOption, AHauteurMemo: Integer); reintroduce;
    // (Re)remplit le tableau. Entetes relus dans la langue active.
    procedure Charger();
  end;

  { TWinOptionRegle }

  // Fenetre a part (bouton du menu) : meme tableau que celui de la page des livres.
  TWinOptionRegle = class(TForm)
  private
    PanneauOption:    TPanelOptionRegle;
    ButtonFermer:     TButton;
    procedure ButtonFermerClick(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  WinOptionRegles: TWinOptionRegle;

implementation

uses XmlExportImport;

{ TPanelOptionRegle }

constructor TPanelOptionRegle.Create(TheOwner: TComponent; AModeRegles: Boolean; ALargLivre, ALargOption, AHauteurMemo: Integer);
  begin
    inherited Create(TheOwner);
    ModeRegles   := AModeRegles;
    FiltreLivres := '';
    OnChangement := nil;
    BevelOuter   := bvNone;
    Caption      := '';
    LargLivre    := ALargLivre;
    LargOption   := ALargOption;
    ColonnesCreees := false;

    MemoExplication            := TMemo.Create(Self);
    MemoExplication.Parent     := Self;
    MemoExplication.Align      := alBottom;
    MemoExplication.Height     := AHauteurMemo;
    MemoExplication.ReadOnly   := true;
    MemoExplication.ScrollBars := ssVertical;

    TabOption           := TStringGrid.Create(Self);
    TabOption.Parent     := Self;
    TabOption.Align      := alClient;
    CouleurSelectionGrille(TabOption);
    TabOption.Options    := TabOption.Options + [goRowSelect] - [goRangeSelect];
    TabOption.FixedRows  := 1;
    TabOption.OnClick    := @TabOptionClick;
    TabOption.OnSelectCell := @TabOptionSelectCell;

    // Meme mise en forme que les autres grilles / memos des fenetres (police, couleurs, en-tetes) :
    // MiseEnFormeDesChamp ne voit que les controles existant au debut de FormCreate, donc un
    // panneau cree apres restait en texte blanc sur fond clair (ligne invisible, 12/11/2026).
    MiseAJourUnContenaire(Self);

    Charger();
  end;

// Ajoute (une seule fois par livre et par prefixe) la ligne « par livre » si le livre est coche.
procedure TPanelOptionRegle.AjouteLigneLivre(Livre, Prefixe, CodeLibelle, CodeExpl: String; var Row: Integer);
  var
    Ind: Integer;
  begin
    if (FiltreLivres <> '') and (Pos(AjouteAccolade(Livre), FiltreLivres) = 0) then exit;
    for Ind := 1 to Row do
      if RowCle[Ind] = Prefixe + Livre then exit;
    Inc(Row);
    // Tableaux de la ligne remplis AVANT RowCount : la grille appelle TabOptionSelectCell des l'ajout.
    RowIndex[Row] := -1;
    RowRegle[Row] := -1;
    RowCle[Row]   := Prefixe + Livre;
    RowExpl[Row]  := CodeExpl;
    TabOption.RowCount := Row + 1;
    if BasculeCreationActive(RowCle[Row]) then
      TabOption.Cells[ColActif, Row] := ''
    else
      TabOption.Cells[ColActif, Row] := ConstSelectionne;
    TabOption.Cells[ColLivre, Row]  := GetTexteLibelle(Livre, '', '', true);
    TabOption.Cells[ColOption, Row] := GetTexteLibelle(CodeLibelle);
  end;

procedure TPanelOptionRegle.Charger();
  var
    POptionRegle: StructureOptionRegle;
    PRegle:       StructureRegle;
    IndListe:     Integer;
    Row:          Integer;
  begin
    TabOption.RowCount := 1;
    MemoExplication.Text := '';
    // Les colonnes ne sont creees qu'une fois : un second ColCount := 1 sur une grille qui a
    // deja des Columns plantait (EGridException, grids.pas:3193, trouve par Nono le 22/09/2026).
    if not ColonnesCreees then
      begin
        TabOption.ColCount := 1;
        ColActif  := GridAjouteColonne(TabOption, GetTexteLibelle('RULES-LAB_278'), 20, taCenter);
        ColLivre  := GridAjouteColonne(TabOption, GetTexteLibelle('RULES-LAB_128'), LargLivre);
        ColOption := GridAjouteColonne(TabOption, GetTexteLibelle('RULES-LAB_002'), LargOption);
        TabOption.ColWidths[0] := 8;
        ColonnesCreees := true;
      end
    else
      begin
        TabOption.Columns[ColActif  - 1].Title.Caption := GetTexteLibelle('RULES-LAB_278');
        TabOption.Columns[ColLivre  - 1].Title.Caption := GetTexteLibelle('RULES-LAB_128');
        TabOption.Columns[ColOption - 1].Title.Caption := GetTexteLibelle('RULES-LAB_002');
      end;

    SetLength(RowIndex, ListOptionRegle.Count + 2 * ListRegle.Count + ListMetierSousMetier.Count + ListMetierRaceChoixMetier.Count + 1);
    SetLength(RowRegle, Length(RowIndex));
    SetLength(RowCle, Length(RowIndex));
    SetLength(RowExpl, Length(RowIndex));
    for Row := 0 to High(RowCle) do
      begin
        RowCle[Row]  := '';
        RowExpl[Row] := '';
      end;
    Row := 0;
    // Menu : reglage global (INI). Les signes astraux y figurent aussi ; l'etape Livre de WinCreation
    // part de ce reglage et peut l'inverser pour la creation en cours.
    for IndListe := 0 to ListOptionRegle.Count - 1 do
      if not ModeRegles then
      begin
        POptionRegle := ListOptionRegle[IndListe];
        Inc(Row);
        TabOption.RowCount := Row + 1;
        RowIndex[Row]       := IndListe;
        RowRegle[Row]       := -1;
        if OptionDesactivee(POptionRegle.Livre, POptionRegle.CodeOption) then
          TabOption.Cells[ColActif, Row] := ''
        else
          TabOption.Cells[ColActif, Row] := ConstSelectionne;
        TabOption.Cells[ColLivre, Row]  := GetTexteLibelle(POptionRegle.Livre, '', '', true);
        TabOption.Cells[ColOption, Row] := POptionRegle.Libelle;
      end;
    // Signes astraux des livres coches (option STARSIGN du livre) : meme tableau que les regles de tirage
    if ModeRegles then
    for IndListe := 0 to ListOptionRegle.Count - 1 do
      if (ListOptionRegle[IndListe].CodeOption = ConstOptionStarSign)
         and ((FiltreLivres = '') or (Pos(AjouteAccolade(ListOptionRegle[IndListe].Livre), FiltreLivres) > 0)) then
      begin
        POptionRegle := ListOptionRegle[IndListe];
        Inc(Row);
        TabOption.RowCount := Row + 1;
        RowIndex[Row]       := IndListe;
        RowRegle[Row]       := -1;
        if SigneAstralLivreActif(POptionRegle.Livre) then
          TabOption.Cells[ColActif, Row] := ConstSelectionne
        else
          TabOption.Cells[ColActif, Row] := '';
        TabOption.Cells[ColLivre, Row]  := GetTexteLibelle(POptionRegle.Livre, '', '', true);
        TabOption.Cells[ColOption, Row] := POptionRegle.Libelle;
      end;
    // Une case par livre pour le second jet de sous-metier et pour le choix de metier par espece
    if ModeRegles then
      begin
        for IndListe := 0 to ListMetierSousMetier.Count - 1 do
          AjouteLigneLivre(ListMetierSousMetier[IndListe].Livre, ConstCleSousMetier, 'RULES-LAB_1014', 'RULES-LAB_1015', Row);
        for IndListe := 0 to ListMetierRaceChoixMetier.Count - 1 do
          AjouteLigneLivre(ListMetierRaceChoixMetier[IndListe].Livre, ConstCleChoixMetier, 'RULES-LAB_1016', 'RULES-LAB_1017', Row);
        // Mutation de depart (V2) : une case par livre qui a une regle avec StartingMutation
        for IndListe := 0 to ListRegle.Count - 1 do
          if Trim(ListRegle[IndListe].MutationDepart) <> '' then
            AjouteLigneLivre(ListRegle[IndListe].Livre, ConstCleMutationDepart, 'RULES-LAB_1018', 'RULES-LAB_1019', Row);
      end;
    // Regles de tirage de metier (DATA_RULE) des livres coches
    if ModeRegles then
    for IndListe := 0 to ListRegle.Count - 1 do
      if (FiltreLivres = '') or (Pos(AjouteAccolade(ListRegle[IndListe].Livre), FiltreLivres) > 0) then
      begin
        PRegle := ListRegle[IndListe];
        Inc(Row);
        TabOption.RowCount := Row + 1;
        RowIndex[Row]       := -1;
        RowRegle[Row]       := IndListe;
        if RegleDesactivee(PRegle.Livre, PRegle.CodeRegle) then
          TabOption.Cells[ColActif, Row] := ''
        else
          TabOption.Cells[ColActif, Row] := ConstSelectionne;
        TabOption.Cells[ColLivre, Row]  := GetTexteLibelle(PRegle.Livre, '', '', true);
        TabOption.Cells[ColOption, Row] := PRegle.Libelle;
      end;
  end;

procedure TPanelOptionRegle.TabOptionClick(Sender: TObject);
  var
    POptionRegle: StructureOptionRegle;
    Liste:        TStringList;
  begin
    if (TabOption.Row < 1) or (TabOption.Row > High(RowIndex)) then exit;
    if TabOption.Col <> ColActif then exit;

    // Ligne « par livre » : choix valable pour la creation en cours seulement
    if RowCle[TabOption.Row] <> '' then
      begin
        BasculeRegleCreation(RowCle[TabOption.Row]);
        if BasculeCreationActive(RowCle[TabOption.Row]) then
          TabOption.Cells[ColActif, TabOption.Row] := ''
        else
          TabOption.Cells[ColActif, TabOption.Row] := ConstSelectionne;
        if Assigned(OnChangement) then
          OnChangement(Self);
        exit;
      end;

    // Une regle de tirage : choix gardé pour la creation en cours seulement (ni INI, ni personnage)
    if RowRegle[TabOption.Row] >= 0 then
      begin
        BasculeRegleCreation(ListRegle[RowRegle[TabOption.Row]].CodeRegle);
        if RegleDesactivee(ListRegle[RowRegle[TabOption.Row]].Livre, ListRegle[RowRegle[TabOption.Row]].CodeRegle) then
          TabOption.Cells[ColActif, TabOption.Row] := ''
        else
          TabOption.Cells[ColActif, TabOption.Row] := ConstSelectionne;
        if Assigned(OnChangement) then
          OnChangement(Self);
        exit;
      end;
    POptionRegle := ListOptionRegle[RowIndex[TabOption.Row]];
    // Signes astraux (tableau de WinCreation) : choix pour la creation en cours seulement
    if ModeRegles then
      begin
        BasculeRegleCreation(CleSigneAstralCreation(POptionRegle.Livre));
        if SigneAstralLivreActif(POptionRegle.Livre) then
          TabOption.Cells[ColActif, TabOption.Row] := ConstSelectionne
        else
          TabOption.Cells[ColActif, TabOption.Row] := '';
        if Assigned(OnChangement) then
          OnChangement(Self);
        exit;
      end;
    Liste        := TStringList.Create;
    try
      Liste.CommaText := ListeOptionDesactiveeParLivre.Values[POptionRegle.Livre];
      if TabOption.Cells[ColActif, TabOption.Row] = ConstSelectionne then
        begin
          // Actif -> desactive : ajoute le code a la liste du livre
          TabOption.Cells[ColActif, TabOption.Row] := '';
          if Liste.IndexOf(POptionRegle.CodeOption) < 0 then
            Liste.Add(POptionRegle.CodeOption);
        end
      else
        begin
          // Inactif -> reactive : retire le code de la liste du livre
          TabOption.Cells[ColActif, TabOption.Row] := ConstSelectionne;
          if Liste.IndexOf(POptionRegle.CodeOption) >= 0 then
            Liste.Delete(Liste.IndexOf(POptionRegle.CodeOption));
        end;
      ListeOptionDesactiveeParLivre.Values[POptionRegle.Livre] := Liste.CommaText;
    finally
      Liste.Free;
    end;

    // Persiste tout de suite (SauveIniOptions ne touche que les lignes OPTION du
    // .INI, chargeconstantes.pas - pas de dependance circulaire vers
    // warhammersource.pas/TMenu). Les regles de tirage jouent a la creation suivante ; les
    // options de livre (armures rapides, signes, carrieres alternatives) au prochain lancement.
    SauveIniOptions();
  end;

procedure TPanelOptionRegle.TabOptionSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  begin
    CanSelect := true;
    if (aRow < 1) or (aRow > High(RowIndex)) then exit;
    if RowCle[aRow] <> '' then
      begin
        MemoExplication.Text := GetTexteLibelle(RowExpl[aRow]);
        exit;
      end;
    if RowRegle[aRow] >= 0 then
      begin
        if RowRegle[aRow] < ListRegle.Count then
          MemoExplication.Text := ListRegle[RowRegle[aRow]].Explication;
        exit;
      end;
    if (RowIndex[aRow] < 0) or (RowIndex[aRow] >= ListOptionRegle.Count) then exit;
    MemoExplication.Text := TexteOuPage(ListOptionRegle[RowIndex[aRow]].Explication, ConstXmlDataOptionRule, ListOptionRegle[RowIndex[aRow]].Livre, ListOptionRegle[RowIndex[aRow]].CodeId);
  end;

{ TWinOptionRegle }

constructor TWinOptionRegle.Create(TheOwner: TComponent);
  begin
    inherited CreateNew(TheOwner);
    Self.Caption      := GetTexteLibelle('RULES-LAB_277');
    Self.Width         := 700;
    Self.Height        := 450;
    Self.Position      := poOwnerFormCenter;

    PanneauOption         := TPanelOptionRegle.Create(Self, false, 200, 380, 140);
    PanneauOption.Parent  := Self;
    PanneauOption.Left    := 8;
    PanneauOption.Top     := 8;
    PanneauOption.Width   := Self.Width - 24;
    PanneauOption.Height  := Self.Height - 64;
    PanneauOption.Anchors := [akLeft, akTop, akRight, akBottom];

    ButtonFermer            := TButton.Create(Self);
    ButtonFermer.Parent     := Self;
    ButtonFermer.Caption    := GetTexteLibelle('RULES-LAB_280');
    ButtonFermer.Width      := 100;
    ButtonFermer.Left       := Self.Width - ButtonFermer.Width - 16;
    ButtonFermer.Top        := PanneauOption.Top + PanneauOption.Height + 8;
    ButtonFermer.Anchors    := [akRight, akBottom];
    ButtonFermer.OnClick    := @ButtonFermerClick;
  end;

procedure TWinOptionRegle.ButtonFermerClick(Sender: TObject);
  begin
    Close;
  end;

end.

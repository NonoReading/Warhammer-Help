unit WinEquipement;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  ExtCtrls, BCButton, ChargeTrapping, GlobalFonts, ChargeConstantes,
  UnitCalcul, ChargeTexte, WinFiltre, WinAnimal, AncrageProportionnel,
  ChargeFabrication, BCLabelContour;

type

  TModeEquipements = (meTout, meHorsVehicules, meVehicules);  // voir ModeEquipements

  { TWinEquipements }

  // Liste des objets du catalogue DATA_TRAPPING, filtrable par theme
  // (balise <Theme>) et par livre.
  TWinEquipements = class(TForm)
    AffAcheteur: TEdit;
    AffLocalite: TEdit;
    AffSaison: TEdit;
    AffCap: TEdit;
    AffFabDesc: TMemo;
    AffDispo: TEdit;
    AffEnc: TEdit;
    AffLib: TEdit;
    AffLivre: TEdit;
    AffPrix: TEdit;
    ButtonFiche: TBCButton;
    ButtonFiltre: TBCButton;
    CombTheme: TComboBox;
    LabAcheteur: TLabelContour;
    LabLocalite: TLabelContour;
    LabSaison: TLabelContour;
    LabCap: TLabelContour;
    LabDispo: TLabelContour;
    LabEnc: TLabelContour;
    LabLivre: TLabelContour;
    LabPrix: TLabelContour;
    LabTheme: TLabelContour;
    LabFab: TLabelContour;
    TabEquip: TStringGrid;
    TabFab: TStringGrid;
    procedure ButtonFicheClick({%H-}Sender: TObject);
    procedure ButtonFiltreClick({%H-}Sender: TObject);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure FormKeyPress({%H-}Sender: TObject; var Key: char);
    procedure FormResize({%H-}Sender: TObject);
    procedure TabEquipDblClick({%H-}Sender: TObject);
    procedure TabEquipSelection({%H-}Sender: TObject; {%H-}aCol, aRow: Integer);
    procedure TabFabSelection({%H-}Sender: TObject; {%H-}aCol, aRow: Integer);
    procedure ThemeChange({%H-}Sender: TObject);
  private
    ListeThemes:   TStringList;
    FiltreLivre:   String;
    EnRemplissage: Boolean;
    Mode:          TModeEquipements;
    Ancrage:       TAncrageProportionnel;
    function  Retenu(PTrapping: StructureTrapping): Boolean;
    procedure AfficheFabrications(const ListeFab: String);
    procedure ChargeThemes;
    procedure Remplir;
  end;

const
  // theme des animaux, montures, vehicules et bateaux (RULES-LAB_195, "Animals and Vehicles")
  ThemeAnimauxVehicules = 'RULES-LAB_195';
  // ...scindes en trois themes pour la lisibilite : montures et animaux, bateaux, vehicules
  ThemeMontures  = 'RULES-LAB_260';
  ThemeBateaux   = 'RULES-LAB_261';
  ThemeVehicules = 'RULES-LAB_262';

function EstThemeAnimauxVehicules(const Theme: String): Boolean;

var
  WinEquipements:  TWinEquipements;
  ModeEquipements: TModeEquipements = meTout;

implementation

uses XmlExportImport;

{$R *.lfm}

function EstThemeAnimauxVehicules(const Theme: String): Boolean;
begin
  Result := (Theme = ThemeAnimauxVehicules) or (Theme = ThemeMontures)
            or (Theme = ThemeBateaux) or (Theme = ThemeVehicules);
end;

{ TWinEquipements }

procedure TWinEquipements.FormCreate(Sender: TObject);
begin
  EnRemplissage := false;
  FiltreLivre   := SelectWinLivre;
  ListeThemes   := TStringList.Create;

  MiseEnFormeDesChamp(Self);
  SelectionGrilleWarhammer(TabEquip);
  SelectionGrilleWarhammer(TabFab);
  Mode                 := ModeEquipements;
  if Mode = meVehicules then
    Caption            := GetTexteLibelle(ThemeAnimauxVehicules)
  else
    Caption            := GetTexteLibelle('RULES-LAB_202');
  LabTheme.Caption     := GetTexteLibelle('RULES-LAB_201');
  ButtonFiltre.Caption := GetTexteLibelle('RULES-LAB_133');
  ButtonFiche.Caption  := GetTexteLibelle('RULES-LAB_253');
  LabPrix.Caption      := GetTexteLibelle('RULES-LAB_054');
  LabEnc.Caption       := GetTexteLibelle('RULES-LAB_055');
  LabCap.Caption       := GetTexteLibelle('RULES-LAB_185');
  LabDispo.Caption     := GetTexteLibelle('RULES-LAB_056');
  LabLivre.Caption     := GetTexteLibelle('RULES-LAB_128');
  LabAcheteur.Caption  := GetTexteLibelle('RULES-LAB_204');
  LabLocalite.Caption  := GetTexteLibelle('RULES-LAB_238');
  LabSaison.Caption    := GetTexteLibelle('RULES-LAB_239');

  // colonnes fixees par le .lfm (ColCount = 9) : seuls les titres sont poses ici
  TabEquip.Cells[1, 0] := GetTexteLibelle('RULES-LAB_001');
  TabEquip.Cells[2, 0] := GetTexteLibelle('RULES-LAB_201');
  TabEquip.Cells[3, 0] := GetTexteLibelle('RULES-LAB_002');
  TabEquip.Cells[4, 0] := GetTexteLibelle('RULES-LAB_054');
  TabEquip.Cells[5, 0] := GetTexteLibelle('RULES-LAB_055');
  TabEquip.Cells[6, 0] := GetTexteLibelle('RULES-LAB_185');
  TabEquip.Cells[7, 0] := GetTexteLibelle('RULES-LAB_056');
  TabEquip.Cells[8, 0] := GetTexteLibelle('RULES-LAB_128');
  TabEquip.ColWidths[0] := 20;

  // tableau des fabrications posees sur l'objet (InherentCraftsmanship) : nom, texte complet
  // (colonne cachee, pour AffFabDesc au clic), resume court
  LabFab.Caption := GetTexteLibelle('RULES-LAB_125');
  TabFab.ColCount := 1;
  TabFab.ColWidths[0] := 20;
  GridAjouteColonne(TabFab, GetTexteLibelle('RULES-LAB_002'), 150);
  GridAjouteColonne(TabFab, '', 0);
  GridAjouteColonne(TabFab, GetTexteLibelle('RULES-LAB_125'), 240);

  ChargeThemes;
  Remplir;

  // Ancrage proportionnel, meme regle que WinArmure (voir AncrageProportionnel).
  Ancrage := TAncrageProportionnel.Create(Self);
  Ancrage.Ajouter(TabEquip, 0, 0.5);
  Ancrage.Ajouter(AffLib, 0.5, 0.5);
  Ancrage.Ajouter(LabPrix, 0.5, 0);
  Ancrage.Ajouter(AffPrix, 0.5, 0);
  Ancrage.Ajouter(LabEnc, 0.5, 0);
  Ancrage.Ajouter(AffEnc, 0.5, 0);
  Ancrage.Ajouter(LabCap, 0.5, 0);
  Ancrage.Ajouter(AffCap, 0.5, 0);
  Ancrage.Ajouter(LabDispo, 0.5, 0);
  Ancrage.Ajouter(AffDispo, 0.5, 0.5);
  Ancrage.Ajouter(LabLivre, 0.5, 0);
  Ancrage.Ajouter(AffLivre, 0.5, 0.5);
  Ancrage.Ajouter(LabAcheteur, 0.5, 0);
  Ancrage.Ajouter(AffAcheteur, 0.5, 0.5);
  Ancrage.Ajouter(LabLocalite, 0.5, 0);
  Ancrage.Ajouter(AffLocalite, 0.5, 0.5);
  Ancrage.Ajouter(LabSaison, 0.5, 0);
  Ancrage.Ajouter(AffSaison, 0.5, 0.5);
  Ancrage.Ajouter(LabFab, 0.5, 0);
  Ancrage.Ajouter(TabFab, 0.5, 0.5);
  Ancrage.Ajouter(AffFabDesc, 0.5, 0.5);
  Ancrage.Fixer;
  OnResize := @FormResize;
end;

procedure TWinEquipements.FormResize(Sender: TObject);
begin
  if Ancrage <> nil then
    Ancrage.Appliquer;
end;

procedure TWinEquipements.FormDestroy(Sender: TObject);
begin
  Ancrage.Free;
  ListeThemes.Free;
end;

function TWinEquipements.Retenu(PTrapping: StructureTrapping): Boolean;
begin
  case Mode of
    meHorsVehicules: Result := not EstThemeAnimauxVehicules(PTrapping.Theme);
    meVehicules:     Result := EstThemeAnimauxVehicules(PTrapping.Theme);
  else
    Result := True;
  end;
end;

// themes presents dans le catalogue (dans l'ordre du premier objet rencontre),
// precedes de l'entree "Tous"
procedure TWinEquipements.ChargeThemes;
var
  PTrapping: StructureTrapping;
begin
  ListeThemes.Clear;
  CombTheme.Items.Clear;
  ListeThemes.Add('');
  CombTheme.Items.Add(GetTexteLibelle('RULES-LAB_200'));
  for PTrapping in ListTrapping do
    if (PTrapping.Theme <> '') and (ListeThemes.IndexOf(PTrapping.Theme) < 0) and Retenu(PTrapping) then
      begin
        ListeThemes.Add(PTrapping.Theme);
        CombTheme.Items.Add(GetTexteLibelle(PTrapping.Theme));
      end;
  CombTheme.ItemIndex := 0;
end;

procedure TWinEquipements.Remplir;
var
  PTrapping: StructureTrapping;
  Theme:     String;
  Ind:       Integer;
begin
  Theme := '';
  if CombTheme.ItemIndex > 0 then
    Theme := ListeThemes[CombTheme.ItemIndex];

  EnRemplissage := true;
  try
    TabEquip.RowCount := 1;
    Ind := 0;
    for PTrapping in ListTrapping do
      if Retenu(PTrapping) and ((Theme = '') or (PTrapping.Theme = Theme)) and VerifieFiltre(PTrapping.Livre, FiltreLivre) then
        begin
          Inc(Ind);
          if TabEquip.RowCount <= Ind then
            TabEquip.RowCount := Ind + 1;
          TabEquip.Cells[1, Ind] := PTrapping.CodeTrapping;
          if PTrapping.Theme <> '' then
            TabEquip.Cells[2, Ind] := GetTexteLibelle(PTrapping.Theme);
          TabEquip.Cells[3, Ind] := PTrapping.Libelle;
          TabEquip.Cells[4, Ind] := TraduirePrix(PTrapping.Prix);
          TabEquip.Cells[5, Ind] := IntToStr(PTrapping.Encombrement);
          TabEquip.Cells[6, Ind] := IntToStr(PTrapping.Capacite);
          TabEquip.Cells[7, Ind] := ReplaceTexteLibelle(PTrapping.Disponibilite);
          TabEquip.Cells[8, Ind] := GetTexteLibelle(PTrapping.Livre, '', '', true);
        end;
    AdjustGridColumnsWidth(TabEquip, Self.Height, false, false);
    // la procedure agrandit la grille a la largeur de ses colonnes : on la remet a sa place
    TabEquip.SetBounds(10, 75, 620, Self.ClientHeight - 85);
    TabEquip.ScrollBars := ssAutoBoth;
    if Ancrage <> nil then
      Ancrage.Appliquer;
  finally
    EnRemplissage := false;
  end;
  if TabEquip.RowCount > 1 then
    begin
      TabEquip.Row := 1;
      TabEquipSelection(TabEquip, 1, 1);
    end;
end;

procedure TWinEquipements.TabEquipSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if EnRemplissage or (aRow < 1) or (aRow >= TabEquip.RowCount) then exit;
  AffLib.Text    := TabEquip.Cells[3, aRow];
  ButtonFiche.Visible := (ChercheTrapping(TabEquip.Cells[1, aRow]).ProfilAnimal <> '')
    or (ChercheTrapping(TabEquip.Cells[1, aRow]).ProfilBateau <> '')
    or (ChercheTrapping(TabEquip.Cells[1, aRow]).ProfilVehicule <> '');
  AffPrix.Text   := TabEquip.Cells[4, aRow];
  AffEnc.Text    := TabEquip.Cells[5, aRow];
  AffCap.Text    := TabEquip.Cells[6, aRow];
  AffDispo.Text  := TabEquip.Cells[7, aRow];
  AffLivre.Text  := TabEquip.Cells[8, aRow];
  LabCap.Visible := AffCap.Text <> '0';
  AffCap.Visible := AffCap.Text <> '0';
  // l'acheteur prefere n'est pas dans la grille : lu dans le catalogue, affiche seulement s'il existe
  AffAcheteur.Text    := GetTexteLibelle(ChercheTrapping(TabEquip.Cells[1, aRow]).Acheteur);
  LabAcheteur.Visible := AffAcheteur.Text <> '';
  AffAcheteur.Visible := AffAcheteur.Text <> '';
  // localite et saison (herbes) : meme regle, affichees seulement si le catalogue les porte
  AffLocalite.Text    := TraduireListeLibelles(ChercheTrapping(TabEquip.Cells[1, aRow]).Localite);
  LabLocalite.Visible := AffLocalite.Text <> '';
  AffLocalite.Visible := AffLocalite.Text <> '';
  AffSaison.Text      := TraduireListeLibelles(ChercheTrapping(TabEquip.Cells[1, aRow]).Saison);
  LabSaison.Visible   := AffSaison.Text <> '';
  AffSaison.Visible   := AffSaison.Text <> '';
  AfficheFabrications(ChercheTrapping(TabEquip.Cells[1, aRow]).Fabrication);
end;

// Fabrications d'origine de l'objet ("CODE niveau, CODE niveau"), meme lecture que WinArmor.
procedure TWinEquipements.AfficheFabrications(const ListeFab: String);
var
  Nb, Ind, J:  Integer;
  Fab:         String;
  PFabrication: StructureFabrication;
begin
  if (ListeFab <> '') and (ListeFab <> '-') then
    Nb := CountOccurrences(ListeFab, ',') + 1
  else
    Nb := 0;

  TabFab.RowCount := 2;
  for J := 1 to TabFab.ColCount - 1 do
    TabFab.Cells[J, 1] := '';
  AffFabDesc.Text := '';
  LabFab.Visible     := Nb > 0;
  TabFab.Visible     := Nb > 0;
  AffFabDesc.Visible := Nb > 0;
  if Nb = 0 then exit;

  if TabFab.RowCount <= Nb then
    TabFab.RowCount := Nb + 1;
  for Ind := 0 to Nb - 1 do
    begin
      Fab          := Trim(ExtractChaine(',', ListeFab, Ind + 1));
      PFabrication := ChercheFabrication(Trim(ExtractStringBefore(Fab, ' ')));
      if PFabrication.Maximum = '1' then
        TabFab.Cells[1, Ind + 1] := PFabrication.Libelle
      else
        TabFab.Cells[1, Ind + 1] := PFabrication.Libelle + ' ' + Trim(ExtractStringAfter(Fab, ' '));
      TabFab.Cells[2, Ind + 1] := TexteOuPage(PFabrication.Description, ConstXmlDataCraftsmanship, PFabrication.Livre, PFabrication.CodeFabrication);
      TabFab.Cells[3, Ind + 1] := PFabrication.Resume;
    end;
  TabFab.Row := 1;
  TabFabSelection(TabFab, 1, 1);
end;

procedure TWinEquipements.TabFabSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if (aRow >= 1) and (aRow < TabFab.RowCount) then
    AffFabDesc.Text := TabFab.Cells[2, aRow];
end;

// Mode selection (appel depuis WinPersonnage) : le double-clic renvoie le code de l'objet.
procedure TWinEquipements.TabEquipDblClick(Sender: TObject);
begin
  if (SelectWinTrapping <> '') and (TabEquip.Row > 0) then
    begin
      ChoixWinTrapping := TabEquip.Cells[1, TabEquip.Row];
      Close;
    end;
end;

procedure TWinEquipements.ThemeChange(Sender: TObject);
begin
  Remplir;
end;

procedure TWinEquipements.ButtonFicheClick(Sender: TObject);
begin
  if (TabEquip.Row > 0) and (TabEquip.Row < TabEquip.RowCount) then
    AfficheFicheAnimal(ChercheTrapping(TabEquip.Cells[1, TabEquip.Row]));
end;

procedure TWinEquipements.ButtonFiltreClick(Sender: TObject);
var
  FenFiltre: TWinFiltre;
begin
  SelectWinLivre     := FiltreLivre;
  WinFiltreAppelant  := ConstXmlArme;
  FenFiltre          := TWinFiltre.Create(Application);
  FenFiltre.Position := poOwnerFormCenter;
  FenFiltre.ShowModal;
  if ChoixWinLivre <> FiltreLivre then
    begin
      FiltreLivre := ChoixWinLivre;
      Remplir;
    end;
end;

procedure TWinEquipements.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #27 then Close;
end;

end.

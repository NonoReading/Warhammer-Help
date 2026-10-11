unit WinGroupe;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

// Fenetre d'affiliation a un groupe (CONTEXT.md 2.100), ouverte depuis l'onglet "Groupe" de
// WinPersonnage. Meme principe d'entree/sortie que WinAmbition : l'appelant pre-remplit les
// champs *In ; la fenetre modifie *Out et GroupeValide seulement si Creer/Rejoindre/Sortir
// est utilise, et accumule dans GroupeBiensRepris chaque bien rendu au personnage via
// "Reprendre" (etape 6) - traite par l'appelant a la fermeture, que GroupeValide soit vrai
// ou non.

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, Dialogs, BCButton,
  GlobalFonts, ChargeTexte, ChargePersonnage, ChargeGroupe, ChargeTrapping, BCLabelContour;

type

  { TWinGroupe }

  TWinGroupe = class(TForm)
    LabelGroupes:    TLabelContour;
    LabelMembres:    TLabelContour;
    LabelBiens:      TLabelContour;
    LabelObjets:     TLabelContour;
    TabGroupes:      TStringGrid;
    TabMembres:      TStringGrid;
    TabBiens:        TStringGrid;
    TabObjets:       TStringGrid;
    LabelAmbitionCourt: TLabelContour;
    LabelAmbitionLong:  TLabelContour;
    MemoAmbitionCourt:  TMemo;
    MemoAmbitionLong:   TMemo;
    ButtonCreer:     TBCButton;
    ButtonRejoindre: TBCButton;
    ButtonSortir:    TBCButton;
    ButtonReprendre: TBCButton;
    ButtonValiderAmbition: TBCButton;
    procedure FormCreate({%H-}Sender: TObject);
    procedure TabGroupesSelectCell({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer; var CanSelect: Boolean);
    procedure TabBiensSelectCell({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer; var CanSelect: Boolean);
    procedure ButtonCreerClick({%H-}Sender: TObject);
    procedure ButtonRejoindreClick({%H-}Sender: TObject);
    procedure ButtonSortirClick({%H-}Sender: TObject);
    procedure ButtonReprendreClick({%H-}Sender: TObject);
    procedure ButtonValiderAmbitionClick({%H-}Sender: TObject);
  private
    FBiensGroupe: TArrayPersonnageEquipement;
    procedure RafraichitGroupes;
    procedure RafraichitMembres(const NomGroupe: String);
    procedure RafraichitBiens(const NomGroupe: String);
    procedure RafraichitObjets(const IdBien: String);
    procedure RafraichitAmbitions(const NomGroupe: String);
    procedure RafraichitBoutons;
    function GroupeSelectionne: String;
    function BienSelectionneId: String;
  public
  end;

var
  WinGroupeForm: TWinGroupe;
  // Entree : dossier racine des personnages (GetCurrentDir+ConstCheminPersonnage), GroupeId
  // et Equipement actuels du personnage ouvert dans WinPersonnage.
  GroupeDirectoireIn: String;
  GroupeIdIn:         String;
  GroupeEquipementIn: TArrayPersonnageEquipement;
  // Sortie : nouveau GroupeId (vide = solo), seulement si GroupeValide = True.
  GroupeIdOut:        String;
  GroupeValide:       Boolean;
  // Sortie : biens repris par "Reprendre" (etape 6) - a ajouter a Personnage.Equipement par
  // l'appelant, meme si GroupeValide = False (une reprise n'est pas un changement de GroupeId).
  GroupeBiensRepris:  TArrayPersonnageEquipement;

implementation

{$R *.lfm}

procedure TWinGroupe.FormCreate(Sender: TObject);
  begin
    MiseEnFormeDesChamp(self);
    Caption               := GetTexteLibelle('RULES-LAB_301');
    LabelGroupes.Caption  := GetTexteLibelle('RULES-LAB_302');
    LabelMembres.Caption  := GetTexteLibelle('RULES-LAB_303');
    LabelBiens.Caption    := GetTexteLibelle('RULES-LAB_309');
    LabelObjets.Caption   := GetTexteLibelle('RULES-LAB_310');
    ButtonCreer.Caption     := GetTexteLibelle('RULES-LAB_304');
    ButtonRejoindre.Caption := GetTexteLibelle('RULES-LAB_305');
    ButtonSortir.Caption    := GetTexteLibelle('RULES-LAB_306');
    ButtonReprendre.Caption := GetTexteLibelle('RULES-LAB_311');
    LabelAmbitionCourt.Caption := GetTexteLibelle('RULES-PDF_PARTY1_PARTY') + ' - '
      + GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT') + GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT');
    LabelAmbitionLong.Caption := GetTexteLibelle('RULES-PDF_PARTY1_PARTY') + ' - '
      + GetTexteLibelle('RULES-PDF_AMBITION3A_LONG') + GetTexteLibelle('RULES-PDF_AMBITION3B_LONG');
    ButtonValiderAmbition.Caption := GetTexteLibelle('RULES-LAB_312');
    TabGroupes.ColCount     := 1;
    TabGroupes.ColWidths[0] := TabGroupes.Width - 4;
    TabMembres.ColCount     := 1;
    TabMembres.ColWidths[0] := TabMembres.Width - 4;
    TabBiens.ColCount       := 1;
    TabBiens.ColWidths[0]   := TabBiens.Width - 4;
    TabObjets.ColCount      := 1;
    TabObjets.ColWidths[0]  := TabObjets.Width - 4;
    // aucune grille n'est en saisie : ligne entiere selectionnee, meme couleur partout
    SelectionGrilleWarhammer(TabGroupes);
    SelectionGrilleWarhammer(TabMembres);
    SelectionGrilleWarhammer(TabBiens);
    SelectionGrilleWarhammer(TabObjets);
    GroupeValide            := False;
    GroupeBiensRepris       := [];
    RafraichitGroupes;
  end;

procedure TWinGroupe.RafraichitGroupes;
  var
    Noms:   TStringList;
    I, Ind: Integer;
  begin
    Noms := ListeFichiersGroupe(GroupeDirectoireIn);
    try
      Noms.Sort;
      TabGroupes.RowCount := Noms.Count + 1;
      TabGroupes.Cells[0, 0] := LabelGroupes.Caption;
      Ind := -1;
      for I := 0 to Noms.Count - 1 do
        begin
          TabGroupes.Cells[0, I + 1] := Noms[I];
          if Noms[I] = GroupeIdIn then
            Ind := I + 1;
        end;
      if Ind >= 1 then
        TabGroupes.Row := Ind;
    finally
      Noms.Free;
    end;
    RafraichitMembres(GroupeSelectionne);
    RafraichitBiens(GroupeSelectionne);
    RafraichitAmbitions(GroupeSelectionne);
  end;

procedure TWinGroupe.RafraichitMembres(const NomGroupe: String);
  var
    Noms: TStringList;
    I:    Integer;
  begin
    TabMembres.RowCount := 1;
    TabMembres.Cells[0, 0] := LabelMembres.Caption;
    if NomGroupe = '' then Exit;
    Noms := ListeMembresGroupe(GroupeDirectoireIn, NomGroupe);
    try
      Noms.Sort;
      TabMembres.RowCount := Noms.Count + 1;
      for I := 0 to Noms.Count - 1 do
        TabMembres.Cells[0, I + 1] := Noms[I];
    finally
      Noms.Free;
    end;
  end;

procedure TWinGroupe.RafraichitBiens(const NomGroupe: String);
  var
    I: Integer;
  begin
    TabBiens.RowCount := 1;
    TabBiens.Cells[0, 0] := LabelBiens.Caption;
    FBiensGroupe := [];
    if NomGroupe <> '' then
      FBiensGroupe := ListeBiensGroupe(GroupeDirectoireIn, NomGroupe);
    TabBiens.RowCount := Length(FBiensGroupe) + 1;
    for I := 0 to High(FBiensGroupe) do
      TabBiens.Cells[0, I + 1] := ChercheTrapping(FBiensGroupe[I].CodeEquipement).Libelle
                                  + ' (' + FBiensGroupe[I].IdInstance + ')';
    RafraichitObjets(BienSelectionneId);
  end;

procedure TWinGroupe.RafraichitObjets(const IdBien: String);
  var
    Noms: TStringList;
    I:    Integer;
  begin
    TabObjets.RowCount := 1;
    TabObjets.Cells[0, 0] := LabelObjets.Caption;
    if (IdBien = '') or (GroupeSelectionne = '') then
      begin
        RafraichitBoutons;
        Exit;
      end;
    Noms := ListeObjetsSurBien(GroupeDirectoireIn, GroupeSelectionne, IdBien);
    try
      TabObjets.RowCount := Noms.Count + 1;
      for I := 0 to Noms.Count - 1 do
        TabObjets.Cells[0, I + 1] := Noms[I];
    finally
      Noms.Free;
    end;
    RafraichitBoutons;
  end;

procedure TWinGroupe.RafraichitAmbitions(const NomGroupe: String);
  var
    Groupe:    StructureGroupe;
    Editable:  Boolean;
  begin
    Editable := (NomGroupe <> '') and (NomGroupe = GroupeIdIn);
    if NomGroupe = '' then
      begin
        MemoAmbitionCourt.Text := '';
        MemoAmbitionLong.Text  := '';
      end
    else
      begin
        Groupe                 := ChargeGroupeComplet(GroupeDirectoireIn, NomGroupe);
        MemoAmbitionCourt.Text := Groupe.AmbitionCourt;
        MemoAmbitionLong.Text  := Groupe.AmbitionLong;
      end;
    // Editable seulement pour SON PROPRE groupe (memes conditions que "Sortir"/"Reprendre") -
    // un autre groupe se consulte, ne se modifie pas.
    MemoAmbitionCourt.ReadOnly := not Editable;
    MemoAmbitionLong.ReadOnly  := not Editable;
    ButtonValiderAmbition.Enabled := Editable;
  end;

function TWinGroupe.GroupeSelectionne: String;
  begin
    if TabGroupes.Row >= 1 then
      Result := TabGroupes.Cells[0, TabGroupes.Row]
    else
      Result := '';
  end;

function TWinGroupe.BienSelectionneId: String;
  begin
    if (TabBiens.Row >= 1) and (TabBiens.Row - 1 <= High(FBiensGroupe)) then
      Result := FBiensGroupe[TabBiens.Row - 1].IdInstance
    else
      Result := '';
  end;

procedure TWinGroupe.RafraichitBoutons;
  begin
    ButtonCreer.Enabled     := (GroupeIdIn = '');
    ButtonRejoindre.Enabled := (GroupeIdIn = '') and (GroupeSelectionne <> '');
    ButtonSortir.Enabled    := (GroupeIdIn <> '') and
      not PersonnageUtiliseGroupe(GroupeIdIn, GroupeEquipementIn, GroupeDirectoireIn);
    // Reprendre : seulement un bien de SON PROPRE groupe, et seulement si personne (aucun
    // membre) n'a rien confie a ce bien pour l'instant (TabObjets vide) - demande de Nono.
    ButtonReprendre.Enabled := (GroupeIdIn <> '') and (GroupeSelectionne = GroupeIdIn)
      and (BienSelectionneId <> '') and (TabObjets.RowCount <= 1);
  end;

procedure TWinGroupe.TabGroupesSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  begin
    RafraichitMembres(GroupeSelectionne);
    RafraichitBiens(GroupeSelectionne);
    RafraichitAmbitions(GroupeSelectionne);
  end;

procedure TWinGroupe.TabBiensSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  begin
    // aRow n'est pas encore applique a TabBiens.Row au moment de l'evenement : on le force.
    TabBiens.Row := aRow;
    RafraichitObjets(BienSelectionneId);
  end;

procedure TWinGroupe.ButtonCreerClick(Sender: TObject);
  var
    Nom:       String;
    GroupeVide: StructureGroupe;
  begin
    Nom := Trim(InputBox(GetTexteLibelle('RULES-LAB_304'), GetTexteLibelle('RULES-LAB_307'), ''));
    if Nom = '' then Exit;
    if FileExists(NomFichierGroupe(GroupeDirectoireIn, Nom)) then Exit;
    GroupeVide.Biens         := [];
    GroupeVide.AmbitionCourt := '';
    GroupeVide.AmbitionLong  := '';
    GroupeXmlCreation(GroupeVide, NomFichierGroupe(GroupeDirectoireIn, Nom));
    GroupeIdOut  := Nom;
    GroupeValide := True;
    Close;
  end;

procedure TWinGroupe.ButtonRejoindreClick(Sender: TObject);
  begin
    if GroupeSelectionne = '' then Exit;
    GroupeIdOut  := GroupeSelectionne;
    GroupeValide := True;
    Close;
  end;

procedure TWinGroupe.ButtonSortirClick(Sender: TObject);
  begin
    GroupeIdOut  := '';
    GroupeValide := True;
    Close;
  end;

procedure TWinGroupe.ButtonReprendreClick(Sender: TObject);
  var
    Bien: StructurePersonnageEquipement;
  begin
    if (TabBiens.Row < 1) or (TabBiens.Row - 1 > High(FBiensGroupe))
       or (GroupeSelectionne <> GroupeIdIn) then Exit;
    Bien := FBiensGroupe[TabBiens.Row - 1];
    if Bien.IdInstance = '' then Exit;
    if not GroupeRetireBien(GroupeDirectoireIn, GroupeIdIn, Bien.IdInstance) then Exit;
    GroupeBiensRepris += [Bien];
    RafraichitBiens(GroupeSelectionne);
  end;

procedure TWinGroupe.ButtonValiderAmbitionClick(Sender: TObject);
  begin
    if GroupeSelectionne <> GroupeIdIn then Exit;
    GroupeEcritAmbitions(GroupeDirectoireIn, GroupeIdIn, MemoAmbitionCourt.Text, MemoAmbitionLong.Text);
  end;

end.

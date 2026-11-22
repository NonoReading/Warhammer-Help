unit WinCompetence;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Grids, StdCtrls, ExtCtrls, BCButton, ChargeCompetence, ChargeConstantes,
  GlobalFonts, ChargeTexte, UnitCalcul, LCLType, ChargeMetierCompetence,
  ChargeMetier, WinMetier, WinFiltre, AncrageProportionnel, BCLabelContour;

type

  { TWinCompetence }

  TWinCompetence = class(TForm)
    AffCode: TEdit;
    AffAttribut: TEdit;
    AffLib: TEdit;
    AffLivre: TEdit;
    AffSpecialisation: TEdit;
    ButtonFiltre: TBCButton;
    ImageWar: TImage;
    LabCode: TLabelContour;
    LabAttribut: TLabelContour;
    LabLivre: TLabelContour;
    LabMetierCompetence: TLabelContour;
    LabSpe: TLabelContour;
    LabSpecialisation: TLabelContour;
    LabLib: TLabelContour;
    LabDescription: TLabelContour;
    AffDescription: TMemo;
    TabMetierCompetence: TStringGrid;
    TabCompetence: TStringGrid;
    TabSpe: TStringGrid;
    LabBonus: TLabelContour;
    TabBonus: TStringGrid;
    procedure ButtonFiltreClick({%H-}Sender: TObject);
    procedure FormClose({%H-}Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormKeyPress({%H-}Sender: TObject; var Key: char);
    procedure FormResize({%H-}Sender: TObject);
    procedure TabCompetenceAfterSelection({%H-}Sender: TObject; {%H-}aCol, aRow: Integer);
    procedure TabCompetenceDblClick({%H-}Sender: TObject);
    procedure TabMetierCompetenceDblClick({%H-}Sender: TObject);
    procedure TabSpeDblClick({%H-}Sender: TObject);
    procedure WinCharger();
    Procedure WinVider();

  private
    Ancrage: TAncrageProportionnel;

  public

  end;

  var
    FenMetier:    TWinMetiers;
    FiltreLivre:  String;
    FenFiltre:    TWinFiltre;


implementation

uses XmlExportImport;

{$R *.lfm}

{ TWinCompetence }

// Vrai si Code appartient a la famille de la competence Ref (Ref comprise, sans le livre).
// Generique "X_*" : tout code qui commence par "X_" (V4 COMPART_*, V2 COMP_ACADEMIC_KNOWLEDGE_*).
// V2 (codes COMP_...) : le radical avant le 1er "_" vaut "COMP" pour toutes les competences,
// donc egalite stricte. V4 : meme radical avant le 1er "_".
function MemeFamille(Code, Ref: String): Boolean;
var
  Prefixe: String;
begin
  Code := CodeSansLivre(Code);
  Ref  := CodeSansLivre(Ref);
  if (Length(Ref) > 2) and (Copy(Ref, Length(Ref) - 1, 2) = ValeurGenerique) then
    begin
      Prefixe := Copy(Ref, 1, Length(Ref) - 1);
      Result  := Copy(Code, 1, Length(Prefixe)) = Prefixe;
    end
  else
    Result := FamilleCompetence(Code) = FamilleCompetence(Ref);
end;

// Vrai si la grille contient deja cette carriere avec ce niveau (colonnes 1 et 3).
function DejaListe(Grille: TStringGrid; CodeMetier: String; Niveau: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Grille.RowCount - 1 do
    if (Grille.Cells[1, I] = CodeMetier) and (Grille.Cells[3, I] = IntToStr(Niveau)) then
      Exit(True);
end;

procedure TWinCompetence.FormResize(Sender: TObject);
begin
    if Ancrage <> nil then
      Ancrage.Appliquer;
end;

procedure TWinCompetence.FormCreate(Sender: TObject);
begin
    FiltreLivre := SelectWinLivre;
    SelectWinLivre := '';   // lecture unique (pas de fuite vers la fenetre suivante)
    WinCharger();
    // Ancrage proportionnel, meme regle que WinRace (voir AncrageProportionnel).
    Ancrage := TAncrageProportionnel.Create(Self);
    Ancrage.Ajouter(ButtonFiltre, 0, 0.5);
    Ancrage.Ajouter(TabCompetence, 0, 0.5);
    Ancrage.Ajouter(AffCode, 0.5, 0);
    Ancrage.Ajouter(LabCode, 0.5, 0);
    Ancrage.Ajouter(LabLib, 0.5, 0);
    Ancrage.Ajouter(AffLib, 0.5, 0.5);
    Ancrage.Ajouter(LabAttribut, 0.5, 0);
    Ancrage.Ajouter(AffAttribut, 0.5, 0);
    Ancrage.Ajouter(LabDescription, 0.5, 0);
    Ancrage.Ajouter(AffDescription, 0.5, 0.5);
    Ancrage.Ajouter(LabSpecialisation, 0.5, 0);
    Ancrage.Ajouter(AffSpecialisation, 0.5, 0.5);
    Ancrage.Ajouter(ImageWar, 0.25, 0);
    Ancrage.Ajouter(TabMetierCompetence, 1, 0);
    Ancrage.Ajouter(LabMetierCompetence, 1, 0);
    Ancrage.Ajouter(LabBonus, 1, 0);
    Ancrage.Ajouter(TabBonus, 1, 0);
    Ancrage.Ajouter(LabLivre, 1, 0);
    Ancrage.Ajouter(AffLivre, 1, 0);
    Ancrage.Ajouter(LabSpe, 1, 0);
    Ancrage.Ajouter(TabSpe, 1, 0);
    Ancrage.Fixer;
end;

procedure TWinCompetence.WinCharger();
var
  PCompetence:   StructureCompetence;
  IndTab:        Integer;
  Accord:        Boolean;
begin
    // Appeler la procédure SetGlobalFonts au démarrage du formulaire
    MiseEnFormeDesChamp(self);
    // Ces trois tableaux se lisent par ligne (Cells[x, aRow]) : selection de la ligne entiere
    SelectionGrilleWarhammer(TabCompetence);
    SelectionGrilleWarhammer(TabMetierCompetence);
    SelectionGrilleWarhammer(TabSpe);

    TabCompetence.RowCount := 1;
    IndTab                 := 0;

    // on met toutes les données dans la table pour les afficher directement dans les champs
    if TabCompetence.ColCount < 2 then
      begin
        TabCompetence.ColCount     := 1;
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_001'));
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_002'), 265);
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_002'));
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_003'));
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_078'));
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_128'), 130);
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_001'), 130);
        GridAjouteColonne(TabCompetence, GetTexteLibelle('RULES-LAB_001'));
      end;
    TabCompetence.ColWidths[0] := 20;

    if TabMetierCompetence.ColCount < 2 then
      begin
        TabMetierCompetence.ColCount        := 1;
        GridAjouteColonne(TabMetierCompetence, GetTexteLibelle('RULES-LAB_001'), 0);
        GridAjouteColonne(TabMetierCompetence, GetTexteLibelle('RULES-LAB_006'), 250);
        GridAjouteColonne(TabMetierCompetence, GetTexteLibelle('RULES-LAB_019'), 70);
      end;
    TabMetierCompetence.RowCount        := 2;
    TabMetierCompetence.ColWidths[0]    := 20;

    if TabBonus.ColCount < 2 then
      begin
        TabBonus.ColCount := 1;
        GridAjouteColonne(TabBonus, GetTexteLibelle('RULES-LAB_001'), 0);
        GridAjouteColonne(TabBonus, 'Test', 170);
        GridAjouteColonne(TabBonus, 'Bonus', 70);
      end;
    TabBonus.RowCount     := 2;
    TabBonus.ColWidths[0] := 20;
    SelectionGrilleWarhammer(TabBonus);
    LabBonus.Caption      := 'Bonus';

    if TabSpe.ColCount < 2 then
      begin
        TabSpe.ColCount        := 1;
        GridAjouteColonne(TabSpe, GetTexteLibelle('RULES-LAB_001'), 0);
        GridAjouteColonne(TabSpe, GetTexteLibelle('RULES-LAB_078'), 70);
      end;
    TabSpe.RowCount        := 2;
    TabSpe.ColWidths[0]    := 20;

    // Lien explicite (CONTEXT.md 2.67) prioritaire sur la deduction par radical, qui
    // gardait le prefixe de livre de SelectWinCompetence au lieu de celui de la
    // generique - seul repli quand <Generique> n'est pas renseigne.
    PCompetence := ChercheCompetence(SelectWinCompetence);
    if (SelectWinCompetence <> '') and PCompetence.SousCompetence then
      begin
        if PCompetence.CodeGenerique <> '' then
          SelectWinCompetence := PCompetence.CodeGenerique
        else
          SelectWinCompetence := CodeGeneriqueDeduit(SelectWinCompetence);
      end;

    For PCompetence in ListCompetence do
      begin
        if (SelectWinCompetence <> '') and (PCompetence.CodeCompetence <> SelectWinCompetence) then
          Accord := False
        else
          Accord := True;
        if Accord and (PCompetence.SousCompetence = false) and VerifieFiltre(PCompetence.Livre, FiltreLivre) then
            Begin
              Inc(IndTab);
              TabCompetence.RowCount := TabCompetence.RowCount + 1;
              TabCompetence.Cells[1, IndTab] := PCompetence.CodeCompetence;
              TabCompetence.Cells[2, IndTab] := PCompetence.Libelle;
              TabCompetence.Cells[3, IndTab] := GetTexteLibelle(PCompetence.CodeAttribut);
              TabCompetence.Cells[4, IndTab] := TexteOuPage(PCompetence.Description, ConstXmlDataSkill, PCompetence.Livre, PCompetence.CodeCompetence);
              TabCompetence.Cells[6, IndTab] := GetTexteLibelle(PCompetence.Livre,'','',true);
              TabCompetence.Cells[7, IndTab] := PCompetence.CodeCompetence;
            end;
      end;
    //Sort
    TabCompetence.SortColRow(true,2);

    if FileExists(CheminImage(GetCurrentDir+ConstCheminLogo1)) then
      ImageWar.Picture.LoadFromFile(CheminImage(GetCurrentDir+ConstCheminLogo1));

    Self.Caption                := GetTexteLibelle('RULES-LAB_009');
    Labcode.Caption             := GetTexteLibelle('RULES-LAB_001');
    LabLib.Caption              := GetTexteLibelle('RULES-LAB_002');
    LabAttribut.Caption         := GetTexteLibelle('RULES-LAB_008');
    LabSpecialisation.caption   := GetTexteLibelle('RULES-LAB_078');
    LabDescription.caption      := GetTexteLibelle('RULES-LAB_003');
    LabMetierCompetence.caption := GetTexteLibelle('RULES-LAB_006');
    LabLivre.caption            := GetTexteLibelle('RULES-LAB_128');
    LabSpe.caption              := GetTexteLibelle('RULES-LAB_078');
    ButtonFiltre.Caption        := GetTexteLibelle('RULES-LAB_133');

    if SelectWinCompetence <> '' then
      begin
        tabCompetence.visible := false;
        TabCompetenceAfterSelection(self, 1, 1)
      end;

    AdjustGridColumnsWidth(TabCompetence, self.Height, false, false);
    if (TabCompetence.Width > (Labcode.Left - 20)) then
      TabCompetence.Width := (Labcode.Left - 20);
    // Liste vide possible (filtre, toggle .INI par livre) : la ligne 1 n'existe pas.
    if TabCompetence.RowCount > 1 then
      begin
        TabCompetence.Row := 1;
        TabCompetenceAfterSelection(TabCompetence, 1, 1);
      end;

    KeyPreview := true;
end;

Procedure TWinCompetence.WinVider();
  begin
      TabCompetence.Clear;
      TabCompetence.RowCount:= 1;
      AffDescription.Clear;
  end;

procedure TWinCompetence.ButtonFiltreClick(Sender: TObject);
  begin
    SelectWinLivre      := FiltreLivre;
    WinFiltreAppelant   := ConstXmlCompetence;
    FenFiltre           := TWinFiltre.Create(Application);
    FenFiltre.Position  := poOwnerFormCenter;
    FenFiltre.ShowModal;
    if (ChoixWinLivre <> FiltreLivre) then
     Begin
       FiltreLivre := ChoixWinLivre;
       WinVider();
       WinCharger();
     end;
  end;

procedure TWinCompetence.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #27 then close;
end;

procedure TWinCompetence.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
    TabCompetence.Clear;
    AffDescription.Clear;
    CloseAction := caFree;
end;

procedure TWinCompetence.TabCompetenceAfterSelection(Sender: TObject; aCol,
  aRow: Integer);
  var
    PMetierCompetence: StructureMetierCompetence;
    PMetier:           StructureMetier;
    PCompetence:       StructureCompetence;
    Ind:               Integer;
    Lignes:            TStringList;
  begin
    // renseigner les données
    AffCode.Text             := TabCompetence.Cells[1,aRow];
    AffLib.Text              := TabCompetence.Cells[2,aRow];
    AffAttribut.Text         := TabCompetence.Cells[3,aRow];
    Affdescription.Text      := TabCompetence.Cells[4,aRow];
    AffSpecialisation.Text   := TabCompetence.Cells[5,aRow];
    AffLivre.Text            := TabCompetence.Cells[6,aRow];

    // cacher les spécialisations si elles ne sont pas nécessaire
    AffSpecialisation.Visible:= (AffSpecialisation.Text <> '');
    LabSpecialisation.Visible:= (AffSpecialisation.Text <> '');

    // Table des bonus (WFRP1) : une ligne "cible #9 valeur" par <Bonus> de la competence
    ClearStringGrid(TabBonus);
    TabBonus.RowCount := 2;
    Lignes := TStringList.Create;
    try
      Lignes.Text := ChercheCompetence(AffCode.Text).BonusTexte;
      for Ind := 0 to Lignes.Count - 1 do
        begin
          if Ind + 2 > TabBonus.RowCount then
            TabBonus.RowCount := Ind + 2;
          TabBonus.Cells[2, Ind + 1] := Copy(Lignes[Ind], 1, Pos(#9, Lignes[Ind]) - 1);
          TabBonus.Cells[3, Ind + 1] := Copy(Lignes[Ind], Pos(#9, Lignes[Ind]) + 1, MaxInt);
        end;
      LabBonus.Visible := (Lignes.Count > 0);
      TabBonus.Visible := (Lignes.Count > 0);
    finally
      Lignes.Free;
    end;

    ClearStringGrid(TabMetierCompetence);
    TabMetierCompetence.RowCount := 2;
    Ind := 0;
    For PMetierCompetence in ListMetierCompetence do
      // Radicaux compares SANS le prefixe de livre : une carriere d'un livre peut citer une
      // competence generique d'un autre (meme piege que winspecialisation.pas AjouteLigne).
      if MemeFamille(PMetierCompetence.CodeCompetence, AffCode.Text) and not DejaListe(TabMetierCompetence, PMetierCompetence.CodeMetier, PMetierCompetence.NiveauMetier) then
        begin
          PMetier := chercheMetier(PMetierCompetence.CodeMetier);
          Inc(Ind);
          if Ind = TabMetierCompetence.RowCount then
            TabMetierCompetence.RowCount    := TabMetierCompetence.RowCount + 1;
          TabMetierCompetence.Cells[1, Ind] := PMetier.CodeMetier;
          TabMetierCompetence.Cells[2, Ind] := PMetier.Libelle;
          TabMetierCompetence.Cells[3, Ind] := IntToStr(PMetierCompetence.NiveauMetier);
        end;
    TabMetierCompetence.SortColRow(true,2);
    AdjustGridColumnsWidth(TabMetierCompetence, self.Height, false, false);

    ClearStringGrid(TabSpe);
    TabSpe.RowCount := 2;
    Ind := 0;
    if Pos(ValeurGenerique, AffCode.Text) > 0 then
      begin
        For PCompetence in ListCompetence do
          // Meme radical SANS le livre : une specialisation (ex. LUSTR-COMPPROJ_SARBAC) peut
          // venir d'un livre different de sa competence generique (ex. RULES-COMPPROJ_*).
          if (PCompetence.CodeCompetence <> AffCode.Text) and MemeFamille(PCompetence.CodeCompetence, AffCode.Text) then
            begin
              Inc(Ind);
              if Ind = TabSpe.RowCount then
                TabSpe.RowCount    := TabSpe.RowCount + 1;
              TabSpe.Cells[1, Ind]    := PCompetence.CodeCompetence;
              TabSpe.Cells[2, Ind]    := PCompetence.Libelle;
            end;
        AdjustGridColumnsWidth(TabSpe, self.Height, false, false);
      end;
    LabSpe.Visible := (Ind > 0);
    TabSpe.Visible := (Ind > 0);
    TabSpe.SortColRow(True, 2);
  end;

procedure TWinCompetence.TabCompetenceDblClick(Sender: TObject);
begin
  if ChoixWinTypeFichier <> '' then
    begin
      if TabSpe.Visible then
        showmessage(GetTexteLibelle('RULES-MESS_034'))
      else
        begin
          SelectWinCompetence := TabCompetence.Cells[1, TabCompetence.Row];
          close;
        end;
    end;
end;

procedure TWinCompetence.TabMetierCompetenceDblClick(Sender: TObject);
begin
  // ouvrir les métiers
  SelectWinMetier     := TabMetierCompetence.Cells[1,TabMetierCompetence.Row];
  FenMetier           := TWinMetiers.Create(Application);
  FenMetier.Position  := poOwnerFormCenter;
  FenMetier.ShowModal;
  SelectWinMetier     := '';

end;

procedure TWinCompetence.TabSpeDblClick(Sender: TObject);
begin
  if ChoixWinTypeFichier <> '' then
    begin
      SelectWinCompetence := TabSpe.Cells[1, Tabspe.Row];
      close;
    end;
end;

end.


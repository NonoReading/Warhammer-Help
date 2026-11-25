unit WinMetier;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, IntfGraphics, Dialogs, MessageTest, ComCtrls, Grids,
  ChargeMetier, ChargeConstantes, FPImage, LCLType, ExtCtrls, StdCtrls,
  BCButton, PReport, ChargeRaceMetier, ChargeRace, ChargeEspece, ChargeMetierNiveau,
  ChargeMetierAttribut, ChargeAttribut, ChargeMetierCompetence,
  ChargeCompetence, ChargeTalent, ChargeMetierTalent, GlobalFonts,
  ChargeMetierEquipement, ChargeArme, ChargeArmure, ChargeTrapping, ChargeTexte, UnitCalcul,
  ChargeMetierSousMetier, ChargeMetierRaceChoixMetier, WinFiltre,
  ChargeTalentCreation, Types, BGRABitmap, BGRABitmapTypes,
  fpPDF, LCLIntf,
  //PicsLib, PdfUtils,
  PdfMetier, PdfUtils, AncrageProportionnel, BCLabelContour;
type
  TMyNodeData = class
    AdditionalData: string;
  end;

  { TWinMetiers }

  TWinMetiers = class(TForm)
    AffCode: TEdit;
    AffLib: TEdit;
    AffLivre: TEdit;
    AffMetier: TEdit;
    AffAttribut: TEdit;
    AffType: TEdit;
    ButtonFiltre: TBCButton;
    ButtonPdf: TBCButton;
    ButtonPdfAll: TBCButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    ImageClass2: TImage;
    ImageClass1: TImage;
    ImageWar: TImage;
    LabCode: TLabelContour;
    LabAttribut: TLabelContour;
    LabDescription: TLabelContour;
    LabLib: TLabelContour;
    AffDescription: TMemo;
    LabLivre: TLabelContour;
    PanelDescription: TPanel;
    PanelHautGauche: TPanel;
    TabAttribut: TStringGrid;
    TabMetier: TStringGrid;
    TreeViewMetier1: TTreeView;
    procedure ButtonFiltreClick({%H-}Sender: TObject);
    procedure ButtonPdfAllClick({%H-}Sender: TObject);
    procedure ButtonPdfClick({%H-}Sender: TObject);
    procedure FormClose({%H-}Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery({%H-}Sender: TObject; var {%H-}CanClose: Boolean);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormKeyPress({%H-}Sender: TObject; var Key: char);
    procedure FormResize({%H-}Sender: TObject);
    procedure TabAttributDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure TabAttributSelectEditor({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure TabMetierDblClick({%H-}Sender: TObject);
    procedure TabMetierCompareCells({%H-}Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure TabMetierSelection({%H-}Sender: TObject; {%H-}aCol, aRow: Integer);
    procedure TreeViewMetier1AdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; {%H-}State: TCustomDrawState; {%H-}Stage: TCustomDrawStage;
      var {%H-}PaintImages, DefaultDraw: Boolean);
    procedure TreeViewMetier1Change({%H-}Sender: TObject; Node: TTreeNode);
    procedure TreeViewMetier1DblClick({%H-}Sender: TObject);
    Procedure WinVider();
    Procedure WinCharger();
    Function MetierFiltre(PMEtier: StructureMetier):Boolean;
    procedure ChargeRaceMetier();
    procedure ChargeAdaptationMetier();
    procedure ChargeMetierAttribut(Niveau: Integer; NodeBase: TTreeNode);
    procedure ChargeMetierNiveau();
    procedure ChargeEnchainementMetier();
    procedure ChargeMetiersArtisan();
    procedure ChargeMetierCompetence(Niveau: Integer; NodeBase: TTreeNode);
    procedure ChargeMetierTalent(Niveau: Integer; NodeBase: TTreeNode);
    procedure ChargeMetierEquipement(Niveau: Integer; NodeBase: TTreeNode);
  private
    Ancrage: TAncrageProportionnel;

  public

  end;

var
  WinMetiers:       TWinMetiers;
//  NbOcc:            Integer;
  Item:             TListItem;
  IndTab:           Integer;
  Node:             TTreeNode;
  picture:          TPicture;
  ListImage:        TImageList;
  Bitmap:           TBitmap;
  Path:             String;
  MetierEnCours:    String;
  NodeBranche:      TTreeNode;
  NodeSBrance:      TTreeNode;
  NodeSTBranche:    TTreeNode;
  NodeFeuille:      TTreeNode;
  NodeSFeuille:     TTreeNode;
  NodeSTFeuille:    TTreeNode;
  NbNiv:            Integer;
  NodeRect:         TRect;
  FrameRect:        TRect;
  TextWidth:        Integer;
  ColorLoc:         TColor;
  ColorList:        array of TColor;
  Nv:               Integer;
  TypeArme:         Integer = 1;
  TypeArmure:       Integer = 2;
  EquipArme:        String = '(W) ';
  EquipArmure:      String = '(P) ';
  EquipDivers:      String = '(D) ';
  FenFiltre:        TWinFiltre;
  FiltreLivre:      String;
  FiltreRace:       String;
  FiltreGroupe:     String;
  FiltreTalent:     String;
  FiltreAttribut:   String;
  FiltreBase:       Boolean = False;   // V1 / V2 : carrieres de base seulement
  FiltreTalentOu:   Boolean = False;   // talents coches en OU (un seul suffit) au lieu de ET
  CheminClass:      String;
  ForceClose:       Boolean = false;
implementation

uses XmlExportImport, ChargeCreationTow;

{$R *.lfm}

const
  NbColBase = 8;    // colonnes de TabMetier avant les statistiques (code ... groupe)
  NbColStat = 10;   // caracteristiques affichees, comme TabAttribut

{ TWinMetiers }

// Images
procedure ChargeImage(Niveau: Integer; CodeMetier: String);
begin
    Picture  := TPicture.Create;
    Bitmap   := TBitmap.Create;
    try
      // Le dossier d'icones vient du METIER lui-meme : cette fenetre affiche un metier
      // sans savoir quelle ethnie le joue. CheminNiveauImageMetier retombe seule sur
      // \PICTURES\NIV\ si le metier n'a pas de dossier propre.
      Path   := CheminNiveauImageMetier(CodeMetier, Niveau);
      // Icone absente pour ce niveau : on ajoute QUAND MEME une image, neutre, sinon les
      // index de ListImage se decalent d'un cran et chaque niveau afficherait l'icone du
      // suivant. Le cas se produit des qu'un livre amene un niveau plus haut que ce que
      // PICTURES\NIV\ contient.
      if FileExists(Path) then
        begin
          Picture.LoadFromFile(Path);
          Bitmap.Assign(Picture.graphic);
          // Pixel (1,1) : fond de l'icone. Une icone aux coins arrondis et transparents
          // (de de niveau maison) y est vide : on lit alors un pixel du corps.
          ColorLoc := CouleurFondIcone(Bitmap);
        end
      else
        begin
          Bitmap.SetSize(8, 8);
          Bitmap.Canvas.Brush.Color := CouleurGrisFonce;
          Bitmap.Canvas.FillRect(0, 0, 8, 8);
          ColorLoc := CouleurGrisFonce;
        end;
      ListImage.Add(Bitmap, nil);
      ColorList[Niveau] := ColorLoc;
    finally
      Picture.Free;
      Bitmap.Free;
    end;
end;

// Recharge icones et couleurs de niveau pour le metier couramment selectionne. Appelee a
// l'ouverture (CodeMetier vide -> dossier generique) puis a chaque changement de metier.
procedure ChargeImagesNiveau(CodeMetier: String);
  var
    IndNiv:   Integer;
    MaxNiv:   Integer;
  begin
    if not Assigned(ListImage) then
      ListImage := TImageList.Create(nil);
    ListImage.Clear;
    SetLength(ColorList, 0);
    // Dimensionne sur la donnee et non sur une constante : un livre qui apporte une
    // carriere a cinq niveaux fait grandir la liste tout seul. Voir MaxNiveauMetier.
    // Pas MaxNiveauMetier : le dossier NIV contient aussi des pastilles de couleur
    // rangees apres le dernier niveau. Voir MaxIndiceIconeNiveau.
    MaxNiv := MaxIndiceIconeNiveau();
    SetLength(ColorList, MaxNiv + 1);
    For IndNiv := 0 to MaxNiv Do
      ChargeImage(IndNiv, CodeMetier);
  end;

Function TWinMetiers.MetierFiltre(PMetier: StructureMetier):Boolean;
var
  ResLivre:        Boolean = True;
  ResRace:         Boolean = True;
  ResGroupe:       Boolean = True;
  ResTalent:       Boolean = True;
  ResAttribut:     Boolean = True;
  PRaceMetier:     StructureRaceMetier;
  PMetierTalent:   StructureMetierTalent;
  PMetierAttribut: StructureMetierAttribut;
  ResOneTalent:    Boolean = True;
  ResOneAttribut:  Boolean = True;
  Strings:         TStringList;
  Ind:             Integer;
  Niv:             Integer;
begin
  if not VerifieFiltre(PMetier.Livre, FiltreLivre) then
    ResLivre := false;

  if not VerifieFiltre(Pmetier.LibelleGroupe, filtreGroupe) then
    ResGroupe:= false;

  if FiltreBase and not EstMetierDeBase(PMetier.CodeMetier) then
    ResGroupe:= false;

  if FiltreRace <> '' then
    begin
      ResRace := false;
      For PRaceMetier in ListRaceMetier do
        begin
          if PMetier.CodeMetier = PRaceMetier.CodeMetier then
            // le filtre porte des codes de RACE : on compare a la race de l ethnie
            if VerifieFiltre(ChercheRace(PRaceMetier.CodeRace).Espece, FiltreRace)
               or VerifieFiltre(PRaceMetier.CodeRace, FiltreRace) then
              ResRace := True;
        end;
    end;

  if FiltreTalent <> '' then
      begin
        // ET : tous les talents coches ; OU : un seul suffit
        ResTalent := not FiltreTalentOu;
        Strings   := TStringList.Create;
        ExtractStrings([']'], [], PChar(FiltreTalent), Strings);
        for Ind := 0 to (Strings.count-1) Do
          begin
            ResOneTalent := false;
            For PMetierTalent in ListMetierTalent do
              begin
                if PMetier.CodeMetier = PMetierTalent.CodeMetier then
                  if VerifieFiltre(PMetierTalent.CodeTalent, Strings[Ind]+']') then
                    begin
                      ResOneTalent := True;
                      break;
                    end;
              end;
            if FiltreTalentOu then
              begin
                if ResOneTalent then
                  begin
                    ResTalent := True;
                    break;
                  end;
              end
            else if ResOneTalent = False then
              begin
                ResTalent := False;
                break;
              end;
          end;
        Strings.free;
      end;

  if FiltreAttribut <> '' then
      begin
        ResAttribut := True;
        Strings   := TStringList.Create;
        ExtractStrings([']'], [], PChar(FiltreAttribut), Strings);
        for Ind := 0 to (Strings.count-1) Do
          begin
            ResOneAttribut := false;
            For PMetierAttribut in ListMetierAttribut do
              begin
                if (PMetier.CodeMetier = PMetierAttribut.CodeMetier) and (PMetierAttribut.NiveauMetier > 0) then
                  if PMetierAttribut.CodeAttribut = ExtractStringBefore(EnleveAccolade(Strings[Ind]),SeparateurDetail) then
                    begin
                      Niv := StrToInt(ExtractStringAfter(EnleveAccolade(Strings[Ind]),SeparateurDetail));
                      if (Niv = 0) or (PMetierAttribut.NiveauMetier = Niv) then
                        begin
                          ResOneAttribut := True;
                          break;
                        end;
                    end;
              end;
            if ResOneAttribut = False then
              begin
                ResAttribut := False;
                break;
              end;
          end;
        Strings.free;
      end;

  Result := (ResLivre and ResRace and ResGroupe and ResTalent and ResAttribut);
end;

// Création
Procedure TWinMetiers.WinCharger();
var
  PMetier:    StructureMetier;
  PAttribut:  StructureAttribut;
  Accord:     Boolean;
  LocSel:     String;
  Nb:         Integer = 0;
  CodeStat:   array[0..NbColStat - 1] of String;
  NbStat:     Integer = 0;
  LignesCode: TStringList;
  PAvStat:    StructureMetierAvance;
  PMAttStat:  StructureMetierAttribut;
  SuffStat:   String;
  Col:        Integer;
  Vide:       Boolean;
  Lig:        Integer;

  // Pose Texte dans la colonne de la caracteristique CodeAtt, ligne de la carriere CodeMet.
  procedure PoseStat(CodeMet, CodeAtt, Texte: String);
  var
    IndL: Integer;
    IndC: Integer;
  begin
    if not LignesCode.Find(CodeMet, IndL) then
      Exit;
    for IndC := 0 to NbStat - 1 do
      if CodeStat[IndC] = CodeAtt then
        TabMetier.Cells[NbColBase + 1 + IndC, PtrInt(LignesCode.Objects[IndL])] := Texte;
  end;

begin
    // Appeler la procédure SetGlobalFonts au démarrage du formulaire
    MiseEnFormeDesChamp(self);
    SelectionGrilleWarhammer(TabMetier);

    TabMetier.RowCount := 1;
    IndTab             := 0;

    // on met toutes les données dans la table pour les afficher directement dans les champs
    if TabMetier.ColCount < 2 then
      begin
        TabMetier.ColCount     := 1;
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_001'));
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_002'),150);
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_039'),120);
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_001'));
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_128'),140);
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_001'),100);
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_001'));
        GridAjouteColonne(TabMetier, GetTexteLibelle('RULES-LAB_001'));
        // une colonne par caracteristique, meme liste (10 premieres de la version) que TabAttribut
        for PAttribut in ListeAttribut do
          if Nb < NbColStat then
            begin
              GridAjouteColonne(TabMetier, PAttribut.Resume, 40, taCenter);
              Inc(Nb);
            end;
      end;
    TabMetier.ColWidths[0] := 20;

    Nb := 0;
    for PAttribut in ListeAttribut do
      if Nb < NbColStat then
        begin
          CodeStat[Nb] := PAttribut.CodeAttribut;
          Inc(Nb);
        end;
    NbStat := Nb;
    Nb     := 0;

    LocSel := SeparateurMulti + SelectWinMetier + SeparateurMulti;

    for PMEtier in ListMetier do
      begin
        Accord := true;
        if (SelectWinMetierRace <> '') and not VerifieRaceMetier(SelectWinMetierRace, PMetier.CodeMetier) then
          Accord := false;
        if (SelectWinMetier <> '') and (pos(SeparateurMulti + PMetier.CodeMetier + SeparateurMulti, LocSel) = 0) then
          Accord := false;
        if not MetierFiltre(PMetier) then
          Accord := False;

        If Accord = true then
          begin
            Inc(IndTab);
            if IndTab = TabMetier.RowCount then
              TabMetier.RowCount := TabMetier.RowCount + 1;
            TabMetier.Cells[1, IndTab] := PMetier.CodeMetier;
            TabMetier.Cells[2, IndTab] := PMetier.Libelle;
            TabMetier.Cells[3, IndTab] := GetTexteLibelle(PMetier.LibelleGroupe);
            TabMetier.Cells[4, IndTab] := TexteOuPage(PMetier.Description, ConstXmlDataCareer, PMetier.Livre, PMetier.CodeMetier) + TexteMetierSousMetier(PMetier.CodeMetier, '') + TexteMetierRaceChoixMetier(PMetier.CodeMetier, '', '');
            TabMetier.Cells[5, IndTab] := GetTexteLibelle(PMetier.Livre,'','',true);
            TabMetier.Cells[6, IndTab] := PMetier.CodeMetier;
            TabMetier.Cells[7, IndTab] := PMetier.CodeCompetence;
            TabMetier.Cells[8, IndTab] := PMetier.LibelleGroupe;
          end;
      end;
    // Statistiques : V2 = plafond d'avance du schema (+10, +20%), V4 / V5 = niveau ou la
    // caracteristique apparait. Une colonne sans aucune valeur est cachee (largeur 0).
    LignesCode := TStringList.Create;
    try
      LignesCode.Sorted     := true;
      LignesCode.Duplicates := dupIgnore;
      for Lig := 1 to TabMetier.RowCount - 1 do
        LignesCode.Objects[LignesCode.Add(TabMetier.Cells[1, Lig])] := TObject(PtrInt(Lig));

      if ValVersion = 'WFRP2' then
        begin
          for PAvStat in ListMetierAvance do
            begin
              if PasAvanceV2(PAvStat.CodeAttribut) = 5 then SuffStat := '%' else SuffStat := '';
              PoseStat(PAvStat.CodeMetier, PAvStat.CodeAttribut, '+' + IntToStr(PAvStat.Plafond) + SuffStat);
            end;
        end
      else
        for PMAttStat in ListMetierAttribut do
          if PMAttStat.NiveauMetier > 0 then
            PoseStat(PMAttStat.CodeMetier, PMAttStat.CodeAttribut, IntToStr(PMAttStat.NiveauMetier));
    finally
      LignesCode.Free;
    end;
    // Bornee au nombre reel de caracteristiques (9 en TOW), pas au maximum de 10.
    for Col := NbColBase + 1 to NbColBase + NbStat do
      begin
        Vide := true;
        for Lig := 1 to TabMetier.RowCount - 1 do
          if TabMetier.Cells[Col, Lig] <> '' then
            begin
              Vide := false;
              Break;
            end;
        if Vide then
          TabMetier.ColWidths[Col] := 0
        else
          TabMetier.ColWidths[Col] := 40;
      end;

    TabMetier.SortColRow(true,2);

    if IndTab = 0 then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_048'));  // aucun résultat
        SelectWinLivre     := '';
        SelectWinRace      := '';
        SelectWinGroupe    := '';
        SelectWinTalent    := '';
        SelectWinAttribut  := '';
        FiltreLivre      := '';
        FiltreRace       := '';
        FiltreGroupe     := '';
        FiltreTalent     := '';
        FiltreAttribut   := '';
        FiltreBase       := False;
        FiltreTalentOu   := False;
        ForceClose        := true;
        Close;
      end
    else
      begin
        // Mise en forme du tableau des attributs
        if TabAttribut.ColCount < 2 then
          begin
            TabAttribut.Clear;
            TabAttribut.Options          := TabAttribut.Options + [goEditing, goAlwaysShowEditor];
            TabAttribut.ColCount         := 1;
            TabAttribut.RowCount         := 3;
            TabAttribut.ColWidths[0]     := 0;
            For PAttribut in ListeAttribut do
              begin
                If Nb < 10 then
                  begin
                    TabAttribut.Columns.Add;
                    TabAttribut.Columns[Nb].Alignment       := taCenter;
                    TabAttribut.Columns[Nb].Title.Caption   := PAttribut.Resume;
                    TabAttribut.Cells[nb+1,2]               := PAttribut.CodeAttribut;
                  end;
                TabAttribut.ColWidths[Nb+1]               := 40;
                Inc(Nb);
              end;
          end;
        TabAttribut.RowHeights[1]    := 40;
        TabAttribut.RowHeights[2]    := 1;
        // V2 : les cases portent un plafond d'avance ("+10%") et non un niveau : colonnes plus larges,
        // la grille s'etend vers la gauche (son bord droit ne bouge pas)
        if ValVersion = 'WFRP2' then
          begin
            for Nb := 1 to TabAttribut.ColCount - 1 do
              TabAttribut.ColWidths[Nb] := 46;
            TabAttribut.Left  := TabAttribut.Left - (46 - 40) * (TabAttribut.ColCount - 1);
            TabAttribut.Width := TabAttribut.Width + (46 - 40) * (TabAttribut.ColCount - 1);
            // le logo cede la place a la grille elargie
            ImageWar.Width := TabAttribut.Left - ImageWar.Left - 12;
          end;

        // charges les images des niveaux pour l'arbre
        ChargeImagesNiveau('');
        TreeViewMetier1.Images := ListImage;
        if FileExists(CheminImage(GetCurrentDir+ConstCheminLogo1)) then
         ImageWar.Picture.LoadFromFile(CheminImage(GetCurrentDir+ConstCheminLogo1));

        Self.Caption              := GetTexteLibelle('RULES-LAB_006');
        Labcode.Caption           := GetTexteLibelle('RULES-LAB_001');
        LabLib.Caption            := GetTexteLibelle('RULES-LAB_002');
        LabAttribut.Caption       := GetTexteLibelle('RULES-LAB_008');
        LabDescription.Caption    := GetTexteLibelle('RULES-LAB_003');
        LabLivre.Caption          := GetTexteLibelle('RULES-LAB_128');
        ButtonFiltre.Caption      := GetTexteLibelle('RULES-LAB_133');
        AdjustGridColumnsWidth(TabMetier, self.Height, false, true);

        // Liste vide possible : la ligne 1 n'existe pas.
        if TabMetier.RowCount > 1 then
          begin
            TabMetier.Row := 1;
            TabMetierSelection(TabMetier, 1, 1);
          end;

        if (SelectWinMetier <> '') then
          begin
            if Pos(SeparateurMulti,SelectWinMetier) = 0 then
              TabMetier.Visible := false;
            TabMetierSelection(self, 1,1);
          end;

        KeyPreview := true;
      end;
end;


procedure TWinMetiers.FormCreate(Sender: TObject);
begin
    FiltreLivre := SelectWinLivre;
    // Lecture unique : sinon la valeur reste dans la globale et fuit vers la prochaine fenetre ouverte.
    SelectWinLivre := '';
    TreeViewMetier1.OnDblClick := @TreeViewMetier1DblClick;
    TabMetier.OnCompareCells   := @TabMetierCompareCells;
    WinCharger();
    // Ancrage proportionnel, meme regle que WinRace (voir AncrageProportionnel).
    Ancrage := TAncrageProportionnel.Create(Self);
    Ancrage.Ajouter(TabMetier,        0,    0.5);
    Ancrage.Ajouter(ButtonFiltre,     0,    0.5);
    Ancrage.Ajouter(ButtonPdfAll,     0.5,  0);    // colle au bord droit du tableau
    Ancrage.Ajouter(ImageWar,         0.25, 0);    // centree au-dessus du tableau
    Ancrage.Ajouter(TreeViewMetier1,  0.5,  0);
    Ancrage.Ajouter(TabAttribut,      0.5,  0);
    Ancrage.Ajouter(Image1,           0.5,  0);
    Ancrage.Ajouter(Image2,           0.5,  0);
    Ancrage.Ajouter(Image3,           0.5,  0);
    Ancrage.Ajouter(ImageClass2,      0.5,  0);
    Ancrage.Ajouter(PanelHautGauche,  0.5,  0);
    Ancrage.Ajouter(AffMetier,        0.5,  0.5);
    Ancrage.Ajouter(PanelDescription, 0.5,  0.5);
    Ancrage.Fixer;
end;

procedure TWinMetiers.FormResize(Sender: TObject);
begin
    if Ancrage <> nil then
      Ancrage.Appliquer;
end;

procedure TWinMetiers.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #27 then close;
end;

procedure TWinMetiers.TabAttributDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  ImageIndex: Integer;
  CellWidth, CellHeight: Integer;
  ImageWidth, ImageHeight: Integer;
  AspectRatio: Double;
  LeftOffset, TopOffset: Integer;
  ImageRect: TRect;
  Grid: TStringGrid;
  Img: TBGRABitmap;
begin
  Grid := TStringGrid(Sender);
  if (aCol = 0) or (aRow = 0) then
    Grid.DefaultDrawCell(aCol, aRow, aRect, aState)
  else
  begin
    // Récupérer la valeur de la cellule correspondante (colonne 2)
    // Un plafond V2 (+1, +2, +15%) est du texte, pas un numero d'icone de niveau : sans ce
    // test, '+2' valait 2 et la colonne W affichait un de (16/10/2026).
    if Pos('+', Grid.Cells[aCol, aRow]) > 0 then
      ImageIndex := -1
    else
      ImageIndex := StrToIntDef(Grid.Cells[aCol, aRow], -1);

    // Vérifier que la valeur est valide et se situe dans la plage d'index d'image
    if (ImageIndex >= 0) and (ImageIndex < ListImage.Count) then
    begin
      // Calculer la taille de la cellule
      CellWidth := aRect.Right - aRect.Left;
      CellHeight := aRect.Bottom - aRect.Top;

      // Charger l'image depuis le fichier
      Img := TBGRABitmap.Create;
      try
        // La bande de caracteristiques ne passe PAS par ListImage : elle recharge le
        // fichier a chaque dessin. Elle doit donc resoudre le dossier elle-meme, sinon
        // l'arbre afficherait les glyphes du livre et la bande ceux du dossier generique.
        // Icone absente (version publiable sans l'image) : image vide, pas d'exception.
        if FileExists(CheminNiveauImageMetier(MetierEnCours, ImageIndex)) then
          Img.LoadFromFile(CheminNiveauImageMetier(MetierEnCours, ImageIndex))
        else
          Img.SetSize(1, 1);

        // Récupérer les dimensions de l'image originale
        ImageWidth := Img.Width;
        ImageHeight := Img.Height;

        // Calculer l'aspect ratio de l'image
        AspectRatio := ImageWidth / ImageHeight;

        // Si l'aspect ratio de la cellule est plus grand que celui de l'image,
        // l'image sera limitée par la hauteur de la cellule, sinon par la largeur
        if (CellWidth / CellHeight) > AspectRatio then
        begin
          ImageWidth := Round(CellHeight * AspectRatio);
          ImageHeight := CellHeight;
        end
        else
        begin
          ImageHeight := Round(CellWidth / AspectRatio);
          ImageWidth := CellWidth;
        end;

        // Calculer les décalages pour centrer l'image
        LeftOffset := (CellWidth - ImageWidth) div 2;
        TopOffset := (CellHeight - ImageHeight) div 2;

        // Calculer le rectangle de l'image dans la cellule
        ImageRect := Rect(aRect.Left + LeftOffset, aRect.Top + TopOffset,
                          aRect.Left + LeftOffset + ImageWidth,
                          aRect.Top + TopOffset + ImageHeight);

        // Dessiner l'image dans la cellule avec la taille ajustée
        Img.Resample(ImageWidth, ImageHeight);
        Img.Draw(Grid.Canvas, ImageRect);

      finally
        Img.Free;
      end;
    end
    else
      // Dessiner du texte par défaut si la valeur de l'index d'image est invalide.
      // Dessin direct, sans passer par DefaultDrawCell : il recalcule lui-meme la cellule
      // courante (WS, ligne 1) et la peignait en jaune quel que soit aState (16/10/2026).
      begin
        Grid.Canvas.Brush.Color := Grid.Color;
        Grid.Canvas.FillRect(aRect);
        Grid.Canvas.Font.Assign(Grid.Font);
        Grid.Canvas.Font.Color := clBlack;
        Grid.Canvas.TextRect(aRect, aRect.Left + 4, aRect.Top + 2, Grid.Cells[aCol, aRow]);
      end;
  end;
end;

procedure TWinMetiers.TabAttributSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  Editor := nil;
end;

// Tri au clic sur un titre : colonnes de statistiques comparees en nombres ("+5" avant "+10%"),
// les autres en texte comme le tri par defaut.
procedure TWinMetiers.TabMetierCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
var
  VA: Integer;
  VB: Integer;
begin
  if ACol > NbColBase then
    begin
      // pas extractnumbers : sa boucle (i < length) ignore le dernier caractere, "+1" donnerait vide
      VA     := StrToIntDef(StringReplace(StringReplace(TabMetier.Cells[ACol, ARow], '+', '', []), '%', '', []), -1);
      VB     := StrToIntDef(StringReplace(StringReplace(TabMetier.Cells[BCol, BRow], '+', '', []), '%', '', []), -1);
      if VA < VB then
        Result := -1
      else if VA > VB then
        Result := 1
      else
        Result := 0;
    end
  else
    Result := AnsiCompareText(TabMetier.Cells[ACol, ARow], TabMetier.Cells[BCol, BRow]);
end;

procedure TWinMetiers.TabMetierDblClick(Sender: TObject);
begin
  if SelectWinMetierRace <> '' then
   begin
     ChoixWinMetierRace := TabMetier.Cells[1, TabMetier.Row];
     Close;
   end;
end;

procedure TWinMetiers.WinVider();
Begin
  TabMetier.Clear;
  AffDescription.Clear;
  SetLength(ColorList, 0);
  DeleteData(TreeViewMetier1,TreeViewMetier1.Items.GetFirstNode);
end;

procedure TWinMetiers.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
    WinVider();
    CloseAction := caFree;
end;

procedure TWinMetiers.ButtonFiltreClick(Sender: TObject);
begin
  SelectWinLivre      := FiltreLivre;
  SelectWinRace       := FiltreRace;
  SelectWinGroupe     := FiltreGroupe;
  SelectWinTalent     := FiltreTalent;
  SelectWinAttribut   := FiltreAttribut;
  SelectWinBase       := FiltreBase;
  SelectWinTalentOu   := FiltreTalentOu;
  WinFiltreAppelant   := ConstXmlWork;
  FenFiltre           := TWinFiltre.Create(Application);
  FenFiltre.Position  := poOwnerFormCenter;
  FenFiltre.ShowModal;
  if (ChoixWinBase <> FiltreBase)
     or (ChoixWinTalentOu <> FiltreTalentOu)
     or (ChoixWinLivre <> FiltreLivre)
     or (ChoixWinRace <> FiltreRace)
     or (ChoixWinGroupe <> FiltreGroupe)
     or (ChoixWinTalent <> FiltreTalent)
     or (ChoixWinAttribut <> FiltreAttribut) then
   Begin
     FiltreLivre      := ChoixWinLivre;
     FiltreRace       := ChoixWinRace;
     FiltreGroupe     := ChoixWinGroupe;
     FiltreTalent     := ChoixWinTalent;
     FiltreAttribut   := ChoixWinAttribut;
     FiltreBase       := ChoixWinBase;
     FiltreTalentOu   := ChoixWinTalentOu;
     WinVider();
     WinCharger();
     if not ForceClose then
       TabMetierSelection(TabMetier, 1,1);
   end;
end;

procedure TWinMetiers.ButtonPdfAllClick(Sender: TObject);
var
  IndL:        Integer;
  ListeMetier: String = '';
begin
  For IndL := 1 to TabMetier.RowCount - 1 do
    begin
      if ListeMetier <> '' then ListeMetier := ListeMetier + SeparateurMulti;
      ListeMetier := ListeMetier + TabMetier.Cells[1, IndL];
    end;
  if ListeMetier <> '' then
    PdfMetierDoc(ListeMetier);
end;

procedure TWinMetiers.ButtonPdfClick(Sender: TObject);
begin
//  PdfMetierCreation(MetierEnCours);
  PdfMetierDoc(MetierEnCours);
end;

procedure TWinMetiers.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    TabMetier.Clear;
    AffDescription.Clear;
    SetLength(ColorList, 0);
    DeleteData(TreeViewMetier1,TreeViewMetier1.Items.GetFirstNode);
end;

// Niveau 1 : charger les races (regroupees par espece, ethnies en sous-noeuds
// repliés par defaut - CONTEXT.md, sinon une carriere humaine affiche une
// vingtaine d'ethnies au lieu d'une seule ligne "Human")
procedure TWinMetiers.ChargeRaceMetier();
Var
  PRace:        StructureRace;
  PRaceMetier:  StructureRaceMetier;
  PEspece:      StructureEspece;
  NodeData:     TMyNodeData;
  NodeRace:     TTreeNode;
  CodeEspece:   String;
Begin
    NodeBranche            := TreeViewMetier1.Items.AddChild(Node, ConstArbreRacePossible);
    NodeBranche.ImageIndex := 0;
    For PRaceMetier in ListRaceMetier do
      if (PRaceMetier.CodeMetier = MetierEnCours) and (PRaceMetier.Chance <> SeparateurChance) then
        Begin
          PRace      := ChercheRace(PRaceMetier.CodeRace);
          CodeEspece := Trim(PRace.Espece);

          // Cherche le noeud "espece" deja cree pour ce metier, sinon le cree
          NodeRace := NodeBranche.GetFirstChild;
          while Assigned(NodeRace) and (TMyNodeData(NodeRace.Data).AdditionalData <> CodeEspece) do
            NodeRace := NodeBranche.GetNextChild(NodeRace);
          if not Assigned(NodeRace) then
            begin
              PEspece                 := ChercheEspece(CodeEspece);
              NodeData                := TMyNodeData.Create;
              NodeData.AdditionalData := CodeEspece;
              NodeRace                := TreeViewMetier1.Items.AddChild(NodeBranche, PEspece.Libelle);
              NodeRace.ImageIndex     := 0;
              NodeRace.Data           := NodeData;
            end;

          NodeData                 := TMyNodeData.Create;
          NodeFeuille               := TreeViewMetier1.Items.AddChild(NodeRace, PRace.Libelle);
          NodeFeuille.ImageIndex    := 0;
          NodeData.AdditionalData   := PRace.CodeRace;
          NodeFeuille.Data          := NodeData;
        end;
    // aucune race declaree (carrieres du Compendium V2) : pas de branche vide
    if not Assigned(NodeBranche.GetFirstChild) then
      TreeViewMetier1.Items.Delete(NodeBranche);
end;

// Adapting Careers : une branche par adaptation applicable a la carriere, avec le detail de
// chaque substitution (le tableau reste celui de la carriere de base, l'ethnie n'est pas connue
// ici). 20/09/2026.
procedure TWinMetiers.ChargeAdaptationMetier();
  function LibelleElement(Nature, Code: String): String;
    begin
      if Code = '' then
        Exit('-');
      if Nature = ConstXmlTalent then
        Result := ChercheTalent(Code).Libelle
      else if Nature = ConstXmlTrapping then
        begin
          // Un trapping de carriere peut etre une arme, une munition, une armure ou un objet.
          Result := ChercheArme(Code).Libelle;
          if Result = '' then
            Result := ChercheArmure(Code).Libelle;
          if Result = '' then
            Result := ChercheTrapping(Code).Libelle;
        end
      else
        Result := ChercheCompetence(Code).Libelle;
      if Result = '' then
        Result := Code;
    end;
Var
  PAdapt:  StructureCareerAdaptation;
  PLigne:  StructureCareerAdaptationLigne;
  NodeAd:  TTreeNode;
  Titre:   String;
Begin
  for PAdapt in ListCareerAdaptation do
    if CompareRechercheValeur(PAdapt.CodeMetier, MetierEnCours) then
      begin
        Titre := PAdapt.Libelle;
        if PAdapt.Facultative then
          Titre := Titre + ' *';
        NodeAd            := TreeViewMetier1.Items.AddChild(Node, Titre);
        NodeAd.ImageIndex := 0;
        if PAdapt.Standing <> 0 then
          TreeViewMetier1.Items.AddChild(NodeAd, 'Standing +' + IntToStr(PAdapt.Standing)).ImageIndex := 0;
        for PLigne in ListCareerAdaptationLigne do
          if PLigne.CodeAdaptation = PAdapt.CodeAdaptation then
            TreeViewMetier1.Items.AddChild(NodeAd, IntToStr(PLigne.Niveau) + '. '
              + LibelleElement(PLigne.Nature, PLigne.Retire) + ' -> '
              + LibelleElement(PLigne.Nature, PLigne.Ajoute)).ImageIndex := 0;
      end;
End;

// Niveau 2 : charger les attributs
procedure TWinMetiers.ChargeMetierAttribut(Niveau: Integer; NodeBase: TTreeNode);
var
  PMetierAttribut:   StructureMetierAttribut;
  PAttribut:         StructureAttribut;
  NodeData:          TMyNodeData;
  I:                 Integer;

Begin

    NodeSBrance            := TreeViewMetier1.Items.AddChild(NodeBase, ConstArbreAttribut);
    NodeSBrance.ImageIndex := Niveau;
    For PMetierAttribut in ListMetierAttribut do
      if (PMetierAttribut.CodeMetier = MetierEnCours) and (PMetierAttribut.NiveauMetier = Niveau) then
        Begin
          NodeData                := TMyNodeData.Create;
          PAttribut               := ChercheAttribut(PMetierAttribut.CodeAttribut);
          NodeSFeuille            := TreeViewMetier1.Items.AddChild(NodeSBrance, PAttribut.Libelle);
          NodeSFeuille.ImageIndex := 0;
          NodeData.AdditionalData := PAttribut.CodeAttribut;
          NodeSFeuille.Data       := NodeData;
          for I := 1 to TabAttribut.Colcount do
            if TabAttribut.Cells[I-1, 2] = PAttribut.CodeAttribut then
              TabAttribut.Cells[I-1, 1] := IntToStr(PMetierAttribut.NiveauMetier);

        end;

    AdjustGridColumnsWidth(TabAttribut,0,false,false,false,0,0,ssnone);

end;

// Niveau 2 : charger les compétences
procedure TWinMetiers.ChargeMetierCompetence(Niveau: Integer; NodeBase: TTreeNode);
var
    PCompetence:        StructureCompetence;
    PGenerique:         StructureCompetence;
    PMetierCompetence:  StructureMetierCompetence;
    NodeData:           TMyNodeData;
    LibComp:            String;
    ListOpt:            TStringList;
    IndL:               Integer;
Begin
    NodeSBrance            := TreeViewMetier1.Items.AddChild(NodeBase, ConstArbreCompetence);
    NodeSBrance.ImageIndex := Niveau;
    For PMetierCompetence in ListMetierCompetence do
      if (PMetierCompetence.CodeMetier = MetierEnCours) and (PMetierCompetence.NiveauMetier = Niveau) then
        if Pos(SeparateurMulti, PMetierCompetence.CodeCompetence) > 0 then
          Begin
            // choix multiple : une sous-branche, une feuille par option
            NodeSTBranche            := TreeViewMetier1.Items.AddChild(NodeSBrance, ConstArbreAuChoix);
            NodeSTBranche.ImageIndex := 0;
            ListOpt                  := ListeMetierCompetence(PMetierCompetence.CodeCompetence);
            for IndL := 0 to ListOpt.Count - 1 do
              begin
                NodeData                 := TMyNodeData.Create;
                PCompetence              := ChercheCompetence(ListOpt[IndL]);
                NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, PCompetence.Libelle);
                NodeSTFeuille.ImageIndex := 0;
                NodeData.AdditionalData  := PCompetence.CodeCompetence;
                NodeSTFeuille.Data       := NodeData;
              end;
            ListOpt.Free;
          end
        else
          Begin
            NodeData                := TMyNodeData.Create;
            PCompetence             := ChercheCompetence(PMetierCompetence.CodeCompetence);
            LibComp                 := PCompetence.Libelle;
            if PMetierCompetence.CodeCompetence = TabMetier.Cells[7,TabMetier.Row] then
              LibComp               := LibComp + '*';
            NodeSFeuille := TreeViewMetier1.Items.AddChild(NodeSBrance, LibComp);
            NodeSFeuille.ImageIndex := 0;
            // specialisation -> sa fiche generique, seulement si elle existe (ids V2 "RULES-COMP_X" : pas de generique commun)
            if Pos(SeparateurSpecialisationTalent, PCompetence.CodeCompetence) > 0 then
              begin
                PGenerique := ChercheCompetence(CodeGeneriqueDeduit(PMetierCompetence.CodeCompetence));
                if PGenerique.CodeCompetence <> '' then
                  PCompetence := PGenerique;
              end;
            NodeData.AdditionalData := PCompetence.CodeCompetence;
            NodeSFeuille.Data       := NodeData;
          end;
end;

// Niveau 2 : charger les talents
procedure TWinMetiers.ChargeMetierTalent(Niveau: Integer; NodeBase: TTreeNode);
var
  PTalent:        StructureTalent;
  PGenTalent:     StructureTalent;
  PMetierTalent:  StructureMetierTalent;
  NodeData:       TMyNodeData;
  ListOpt:        TStringList;
  IndL:           Integer;
Begin
    NodeSBrance            := TreeViewMetier1.Items.AddChild(NodeBase, ConstArbreTalent);
    NodeSBrance.ImageIndex := Niveau;
    For PMetierTalent in ListMetierTalent do
      if (PMetierTalent.CodeMetier = MetierEnCours) and (PMetierTalent.NiveauMetier = Niveau) then
        if (Pos(SeparateurMulti, PMetierTalent.CodeTalent) > 0) or
           ((Pos(ValeurGenerique, PMetierTalent.CodeTalent) > 0) and (ChercheTalent(PMetierTalent.CodeTalent).CodeTalent = '')) then
          Begin
            // choix multiple, ou famille a etoile sans fiche (ROS-T_RUNE__*, deplie par ListeTalent comme
            // a la creation) : une sous-branche, une feuille par option (meme motif que
            // ChargeMetierCompetence ci-dessus)
            NodeSTBranche            := TreeViewMetier1.Items.AddChild(NodeSBrance, ConstArbreAuChoix);
            NodeSTBranche.ImageIndex := 0;
            ListOpt                  := ListeTalent(PMetierTalent.CodeTalent);
            for IndL := 0 to ListOpt.Count - 1 do
              begin
                NodeData                 := TMyNodeData.Create;
                PTalent                  := ChercheTalent(ListOpt[IndL]);
                NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, PTalent.Libelle);
                NodeSTFeuille.ImageIndex := 0;
                NodeData.AdditionalData  := PTalent.CodeTalent;
                NodeSTFeuille.Data       := NodeData;
              end;
            ListOpt.Free;
          end
        else
          Begin
              NodeData     := TMyNodeData.Create;
              PTalent      := ChercheTalent(PMetierTalent.CodeTalent);
              NodeSFeuille := TreeViewMetier1.Items.AddChild(NodeSBrance, PTalent.Libelle);
              NodeSFeuille.ImageIndex := 0;
              // specialisation -> sa fiche generique, seulement si elle existe (ids V2 : pas de generique commun)
              PGenTalent := ChercheTalent(CodeTalentGenerique(PTalent));
              if PGenTalent.CodeTalent <> '' then
                PTalent  := PGenTalent;
              NodeData.AdditionalData := PTalent.CodeTalent;
              NodeSFeuille.Data       := NodeData;
          end;
end;

// Niveau 2 : charger l'equipement
procedure TWinMetiers.ChargeMetierEquipement(Niveau: Integer; NodeBase: TTreeNode);
var
  PArme:               StructureArme;
  PArmure:             StructureArmure;
  PTrapping:           StructureTrapping;
  PMetierEquipement:   StructureMetierEquipement;
  StringsI:            TStringList;
  StringsT:            TStringList;
  IndL:                Integer;
  Code:                String;
  Qualite:             String;
  NodeData:            TMyNodeData;

Begin
    NodeSBrance            := TreeViewMetier1.Items.AddChild(NodeBase, ConstArbreEquipement);
    NodeSBrance.ImageIndex := Niveau;
    for PMetierEquipement in ListMetierEquipement do
      if (PMetierEquipement.CodeMetier = MetierEnCours) and (PMetierEquipement.NiveauMetier = Niveau) then
         if pos(SeparateurMulti, PMetierEquipement.Equipement) > 0 then
            begin
              // choix mutiple
               stringsI                := TStringList.Create;
               stringsT                := TStringList.Create;
               NodeSTBranche           := TreeViewMetier1.Items.AddChild(NodeSBrance, ConstArbreAuChoix);
               NodeSTBranche.ImageIndex := 0;
               ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.Equipement), stringsI);
               ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.TypeEquipement), stringsT);
               For IndL := 0 to 1 do
                 Begin
                   if pos(EquipementQualite, StringsT[IndL]) > 0 then
                     begin
                       Code   := Trim(copy(stringsI[IndL],1,length(stringsI[IndL]) - length(Equipementqualite)));
                       Qualite:= GetTexteLibelle('RULES-LAB_038');
                     end
                   else
                     begin
                       Code   := stringsI[IndL];
                       Qualite:= '';
                     end;
                   if InList(stringsT[IndL],TypeEquipMetierArme) then
                      begin
                        PArme                    := ChercheArme(Code);
                        NodeData                 := TMyNodeData.Create;
                        NodeData.AdditionalData  := PArme.CodeArme;
                        NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, EquipArme + PArme.Libelle + Qualite);
                        NodeSTFeuille.ImageIndex := 0;
                        NodeSTFeuille.Data       := NodeData;
                      end
                   else if stringsT[IndL] = TypeEquipAR then
                      begin
                        PArmure                  := ChercheArmure(Code);
                        NodeData                 := TMyNodeData.Create;
                        NodeData.AdditionalData  := PArmure.CodeArmure;
                        NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, EquipArmure + PArmure.Libelle + Qualite);
                        NodeSTFeuille.ImageIndex := 0;
                        NodeSTFeuille.Data       := NodeData;
                      end
                   else if stringsT[IndL] = TypeEquipDI then
                      begin
                        // Un code Divers peut etre un Trapping catalogue (RULES-TRAP_xxx),
                        // resolu sans changer sa classification TypeEquipDI (CONTEXT.md 2.77bis).
                        PTrapping := ChercheTrapping(Code);
                        if PTrapping.CodeTrapping <> '' then
                          begin
                            NodeData                 := TMyNodeData.Create;
                            NodeData.AdditionalData  := PTrapping.CodeTrapping;
                            NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, EquipDivers + PTrapping.Libelle);
                            NodeSTFeuille.Data       := NodeData;
                          end
                        else
                          NodeSTFeuille := TreeViewMetier1.Items.AddChild(NodeSTBranche, LibelleEquipementV1(stringsI[IndL]));
                        NodeSTFeuille.ImageIndex := 0;
                      end
                   end;
               stringsI.Free;
               stringsT.Free;
            end
         else if pos(SeparateurEnsemble, PMetierEquipement.Equipement) > 0 then
            begin
              // ensemble : les deux objets sont acquis en meme temps (ex. Storm Lantern +
              // Lamp Oil), une seule entree de trapping du livre = une seule coche
              // d'avancement (CONTEXT.md, chantier equipement/avancement) - a ne pas
              // confondre avec le "choix multiple" ci-dessus (SeparateurMulti).
               stringsI                := TStringList.Create;
               stringsT                := TStringList.Create;
               NodeSTBranche           := TreeViewMetier1.Items.AddChild(NodeSBrance, ConstArbreEnsemble);
               NodeSTBranche.ImageIndex := 0;
               ExtractStrings([SeparateurEnsemble], [], PChar(PMetierEquipement.Equipement), stringsI);
               ExtractStrings([SeparateurEnsemble], [], PChar(PMetierEquipement.TypeEquipement), stringsT);
               For IndL := 0 to 1 do
                 Begin
                   if pos(EquipementQualite, StringsT[IndL]) > 0 then
                     begin
                       Code   := Trim(copy(stringsI[IndL],1,length(stringsI[IndL]) - length(Equipementqualite)));
                       Qualite:= GetTexteLibelle('RULES-LAB_038');
                     end
                   else
                     begin
                       Code   := stringsI[IndL];
                       Qualite:= '';
                     end;
                   if InList(stringsT[IndL],TypeEquipMetierArme) then
                      begin
                        PArme                    := ChercheArme(Code);
                        NodeData                 := TMyNodeData.Create;
                        NodeData.AdditionalData  := PArme.CodeArme;
                        NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, EquipArme + PArme.Libelle + Qualite);
                        NodeSTFeuille.ImageIndex := 0;
                        NodeSTFeuille.Data       := NodeData;
                      end
                   else if stringsT[IndL] = TypeEquipAR then
                      begin
                        PArmure                  := ChercheArmure(Code);
                        NodeData                 := TMyNodeData.Create;
                        NodeData.AdditionalData  := PArmure.CodeArmure;
                        NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, EquipArmure + PArmure.Libelle + Qualite);
                        NodeSTFeuille.ImageIndex := 0;
                        NodeSTFeuille.Data       := NodeData;
                      end
                   else if stringsT[IndL] = TypeEquipDI then
                      begin
                        PTrapping := ChercheTrapping(Code);
                        if PTrapping.CodeTrapping <> '' then
                          begin
                            NodeData                 := TMyNodeData.Create;
                            NodeData.AdditionalData  := PTrapping.CodeTrapping;
                            NodeSTFeuille            := TreeViewMetier1.Items.AddChild(NodeSTBranche, EquipDivers + PTrapping.Libelle);
                            NodeSTFeuille.Data       := NodeData;
                          end
                        else
                          NodeSTFeuille := TreeViewMetier1.Items.AddChild(NodeSTBranche, LibelleEquipementV1(stringsI[IndL]));
                        NodeSTFeuille.ImageIndex := 0;
                      end
                   end;
               stringsI.Free;
               stringsT.Free;
            end
         else
            if InList(PMetierEquipement.TypeEquipement,TypeEquipMetierArme) then
                begin
                  if Pos(EquipementQualite, PMetierEquipement.Equipement) > 0 then
                    begin
                      Code   := Trim(copy(PMetierEquipement.Equipement,1,length(PMetierEquipement.Equipement) - length(Equipementqualite)));
                      Qualite:= GetTexteLibelle('RULES-LAB_038');
                    end
                  else
                    begin
                      Code   := PMetierEquipement.Equipement;
                      Qualite:= '';
                    end;
                  PArme                   := ChercheArme(Code);
                  NodeData                := TMyNodeData.Create;
                  NodeData.AdditionalData := PArme.CodeArme;
                  NodeSFeuille            := TreeViewMetier1.Items.AddChild(NodeSBrance, EquipArme + PArme.Libelle + qualite);
                  NodeSFeuille.ImageIndex := 0;
                  NodeSFeuille.Data       := NodeData;
                end
            else if PMetierEquipement.TypeEquipement = TypeEquipAR then
                begin
                  if Pos(EquipementQualite, PMetierEquipement.Equipement) > 0 then
                    begin
                      Code   := Trim(copy(PMetierEquipement.Equipement,1,length(PMetierEquipement.Equipement) - length(Equipementqualite)));
                      Qualite:= GetTexteLibelle('RULES-LAB_038');
                    end
                  else
                    begin
                      Code   := PMetierEquipement.Equipement;
                      Qualite:= '';
                    end;
                  PArmure                 := ChercheArmure(Code);
                  NodeData                := TMyNodeData.Create;
                  NodeData.AdditionalData := PArmure.CodeArmure;
                  NodeSFeuille            := TreeViewMetier1.Items.AddChild(NodeSBrance, EquipArmure + PArmure.Libelle + Qualite);
                  NodeSFeuille.ImageIndex := 0;
                  NodeSFeuille.Data       := NodeData;
                end
              else if PMetierEquipement.TypeEquipement = TypeEquipDI then
                begin
                  // Suffixe (Q), comme pour les armes et les armures ci-dessus : sans ce retrait, un
                  // code catalogue "RULES-TRAP_017 (Q)" ne se retrouvait pas et s'affichait brut
                  // (20/09/2026, Artisan niveau 4 et Signaller niveau 4).
                  if Pos(EquipementQualite, PMetierEquipement.Equipement) > 0 then
                    begin
                      Code   := Trim(copy(PMetierEquipement.Equipement,1,length(PMetierEquipement.Equipement) - length(Equipementqualite)));
                      Qualite:= GetTexteLibelle('RULES-LAB_038');
                    end
                  else
                    begin
                      Code   := PMetierEquipement.Equipement;
                      Qualite:= '';
                    end;
                  PTrapping := ChercheTrapping(Code);
                  if PTrapping.CodeTrapping <> '' then
                    begin
                      NodeData                := TMyNodeData.Create;
                      NodeData.AdditionalData := PTrapping.CodeTrapping;
                      NodeSFeuille            := TreeViewMetier1.Items.AddChild(NodeSBrance, EquipDivers + PTrapping.Libelle + Qualite + QuantiteSuffixe(PMetierEquipement.Quantite));
                      NodeSFeuille.Data       := NodeData;
                    end
                  else
                    NodeSFeuille := TreeViewMetier1.Items.AddChild(NodeSBrance, LibelleEquipementV1(PMetierEquipement.Equipement));
                  NodeSFeuille.ImageIndex := 0;
                end;
end;


// Niveau 1 : charger les niveaux des métiers
procedure TWinMetiers.ChargeMetierNiveau();
var
  PMetierNiveau:   StructureMetierNiveau;
  I:               Integer;
  NiveauTrouve:    Boolean;
  PAvance:         StructureMetierAvance;
  PAttributAv:     StructureAttribut;
  NodeDataAv:      TMyNodeData;
  SuffixeAv:       String;
Begin
    NiveauTrouve := False;
    for I := 1 to TabAttribut.Colcount - 1 do
       TabAttribut.Cells[I, 1] := '';

    for PMetierNiveau in ListMetierNiveau do
      if PMetierNiveau.CodeMetier = MetierEnCours then
        Begin
            NiveauTrouve := True;
            // Prefixe RULES- ajoute le 12/09/2026 - meme correctif que pdfpersonnage.pas, voir
            // son commentaire (CONTEXT.md 2.49/2.61).
            NodeBranche := TreeViewMetier1.Items.AddChild(Node, IntToStr(PMetierNiveau.NiveauMetier)+'.'+PMetierNiveau.Libelle+' - '+GetTexteLibelle('RULES-' + PMetierNiveau.SalaireMetier, '', ' '));
            NodeBranche.ImageIndex := PMetierNiveau.NiveauMetier;
            ChargeMetierAttribut(PMetierNiveau.NiveauMetier,NodeBranche);
            ChargeMetierCompetence(PMetierNiveau.NiveauMetier,NodeBranche);
            ChargeMetierTalent(PMetierNiveau.NiveauMetier,NodeBranche);
            ChargeMetierEquipement(PMetierNiveau.NiveauMetier,NodeBranche);
        end;

    // V2 : une carriere n'a pas de niveaux en donnees ; l'arbre montre ses competences, talents et materiel de depart (niveau 1)
    // V1 : meme arbre (Advance Scheme, competences de depart), sans talents
    if (not NiveauTrouve) and ((ValVersion = 'WFRP2') or (ValVersion = 'WFRP1')) then
      begin
        // schema d'avances de la carriere (<Advances>) : plafond par caracteristique
        NodeSBrance            := TreeViewMetier1.Items.AddChild(Node, ConstArbreAttribut);
        NodeSBrance.ImageIndex := 1;
        for PAvance in ListMetierAvance do
          if CompareRechercheValeur(PAvance.CodeMetier, MetierEnCours) then
            begin
              PAttributAv := ChercheAttribut(PAvance.CodeAttribut);
              if ValVersion = 'WFRP1' then
                begin
                  // V1 : M, S, T, W et A sont des points, le reste des pourcentages
                  if Pos(CodeSansLivre(PAvance.CodeAttribut), 'ATTR_M ATTR_S ATTR_T ATTR_W ATTR_A') > 0 then
                    SuffixeAv := ''
                  else
                    SuffixeAv := '%';
                end
              else if PasAvanceV2(PAvance.CodeAttribut) = 5 then SuffixeAv := '%' else SuffixeAv := '';
              NodeSFeuille            := TreeViewMetier1.Items.AddChild(NodeSBrance, PAttributAv.Libelle + ' +' + IntToStr(PAvance.Plafond) + SuffixeAv);
              NodeSFeuille.ImageIndex := 0;
              NodeDataAv              := TMyNodeData.Create;
              NodeDataAv.AdditionalData := PAttributAv.CodeAttribut;
              NodeSFeuille.Data       := NodeDataAv;
              for I := 1 to TabAttribut.Colcount do
                if TabAttribut.Cells[I-1, 2] = PAttributAv.CodeAttribut then
                  TabAttribut.Cells[I-1, 1] := '+' + IntToStr(PAvance.Plafond) + SuffixeAv;
            end;
        ChargeMetierCompetence(1, Node);
        // V1 : ni talents (leurs effets sont dans les competences) ni branche vide
        if ValVersion <> 'WFRP1' then
          ChargeMetierTalent(1, Node);
        ChargeMetierEquipement(1, Node);
      end;

end;

// Chainage des carrieres (V2, <ExitCodes>) : branche des carrieres dont celle-ci est la sortie
// ("Career entries", calcul inverse) et branche de ses propres sorties ("Career exits").
procedure TWinMetiers.ChargeEnchainementMetier();
  procedure Branche(Titre: String; Entrees: Boolean);
    var
      PSortie:  StructureMetierSortie;
      Code:     String;
      Lib:      String;
      I:        Integer;
      Present:  TStringList;
      NodeData: TMyNodeData;
    begin
      NodeBranche := nil;
      Present     := TStringList.Create;
      try
        for PSortie in ListMetierSortie do
          begin
            if Entrees then
              begin
                if PSortie.CodeSortie <> MetierEnCours then Continue;
                Code := PSortie.CodeMetier;
              end
            else
              begin
                if PSortie.CodeMetier <> MetierEnCours then Continue;
                Code := PSortie.CodeSortie;
              end;
            if Present.IndexOf(Code) >= 0 then Continue;
            Present.Add(Code);
            if NodeBranche = nil then
              begin
                NodeBranche            := TreeViewMetier1.Items.AddChild(Node, Titre);
                NodeBranche.ImageIndex := 0;
              end;
            NodeData                  := TMyNodeData.Create;
            NodeData.AdditionalData   := Code;
            Lib := ChercheMetier(Code).Libelle;
            // Carriere citee mais sans fiche (V1 : sorties vers les carrieres avancees pas encore
            // saisies) : le nom est deduit du code, RULES-WORK_PIT_FIGHTER -> Pit Fighter.
            if Lib = GetTexteLibelle('RULES-LAB_138') then
              begin
                Lib := LowerCase(StringReplace(CodeSansLivre(Code), '_', ' ', [rfReplaceAll]));
                if Pos(' ', Lib) > 0 then
                  Lib := Copy(Lib, Pos(' ', Lib) + 1, MaxInt);
                for I := 1 to Length(Lib) do
                  if (I = 1) or (Lib[I - 1] = ' ') then
                    Lib[I] := UpCase(Lib[I]);
              end;
            NodeFeuille               := TreeViewMetier1.Items.AddChild(NodeBranche, Lib);
            NodeFeuille.ImageIndex    := 0;
            NodeFeuille.Data          := NodeData;
          end;
      finally
        Present.Free;
      end;
    end;
begin
  Branche(GetTexteLibelle('RULES-LAB_703'), True);
  Branche(GetTexteLibelle('RULES-LAB_704'), False);
end;

// V1 : l'Artisan et son apprenti tirent un metier (DATA_TRADE_V1) : une branche "Metiers", un metier
// par ligne (tirage d100), avec ses competences et ses sorties propres.
procedure TWinMetiers.ChargeMetiersArtisan();
var
  PArtisan:   StructureArtisanMetier;
  Liste:      TStringList;
  NodeTitre:  TTreeNode;
  NodeMetier: TTreeNode;
  NodeSous:   TTreeNode;
  Lib:        String;
  I:          Integer;
begin
  if ValVersion <> 'WFRP1' then Exit;
  if (CodeSansLivre(MetierEnCours) <> 'WORK_ARTISAN') and
     (CodeSansLivre(MetierEnCours) <> 'WORK_ARTISANS_APPRENTICE') then Exit;
  if ListArtisanMetier.Count = 0 then Exit;

  NodeTitre            := TreeViewMetier1.Items.AddChild(Node, GetTexteLibelle('RULES-LAB_812'));
  NodeTitre.ImageIndex := 0;
  Liste := TStringList.Create;
  try
    for PArtisan in ListArtisanMetier do
      begin
        NodeMetier            := TreeViewMetier1.Items.AddChild(NodeTitre, PArtisan.Tirage + ' ' + PArtisan.Libelle);
        NodeMetier.ImageIndex := 0;

        Liste.Clear;
        ExtractStrings([','], [' '], PChar(PArtisan.Competences), Liste);
        for I := 0 to Liste.Count - 1 do
          begin
            NodeSous            := TreeViewMetier1.Items.AddChild(NodeMetier, ChercheCompetence(Liste[I]).Libelle);
            NodeSous.ImageIndex := 0;
          end;

        Liste.Clear;
        ExtractStrings([','], [' '], PChar(PArtisan.Sorties), Liste);
        for I := 0 to Liste.Count - 1 do
          begin
            Lib := ChercheMetier(Liste[I]).Libelle;
            // Carriere sans fiche : nom deduit du code, comme dans ChargeEnchainementMetier
            if Lib = GetTexteLibelle('RULES-LAB_138') then
              Lib := LowerCase(StringReplace(Copy(CodeSansLivre(Liste[I]), 6, MaxInt), '_', ' ', [rfReplaceAll]));
            NodeSous            := TreeViewMetier1.Items.AddChild(NodeMetier, GetTexteLibelle('RULES-LAB_704') + ' : ' + Lib);
            NodeSous.ImageIndex := 0;
          end;

        if PArtisan.Note <> '' then
          begin
            NodeSous            := TreeViewMetier1.Items.AddChild(NodeMetier, PArtisan.Note);
            NodeSous.ImageIndex := 0;
          end;
      end;
  finally
    Liste.Free;
  end;
end;

// Double clic sur une carriere d'entree ou de sortie : la selectionne dans la liste
// (sans effet si le filtre l'en a retiree).
procedure TWinMetiers.TreeViewMetier1DblClick(Sender: TObject);
var
  Sel:  TTreeNode;
  Ind:  Integer;
begin
  Sel := TreeViewMetier1.Selected;
  if (Sel = nil) or (Sel.Parent = nil) or (Sel.Data = nil) then Exit;
  if (Sel.Parent.Text <> GetTexteLibelle('RULES-LAB_703'))
     and (Sel.Parent.Text <> GetTexteLibelle('RULES-LAB_704')) then Exit;
  for Ind := 1 to TabMetier.RowCount - 1 do
    if TabMetier.Cells[1, Ind] = TMyNodeData(Sel.Data).AdditionalData then
      begin
        TabMetier.Row := Ind;
        Exit;
      end;
end;

// The Old World : arbre d une carriere, lu dans chargecreationtow (pas de DATA_CAREER_* de V4/V5).
// Chaque feuille porte son code dans Data, pour le texte de droite (TreeViewMetier1Change).
procedure ChargeMetierTow(TreeViewMetier1: TTreeView; const CodeCarriere: String);
var
  Carrieres: TTowCarrieres;
  Origines:  TTowOrigines;
  C:         TTowCarriere;
  I, K, P:   Integer;
  Br, Sb:    TTreeNode;
  Pl:        String;

  function Feuille(Parent: TTreeNode; const Txt, Code: String): TTreeNode;
  var D: TMyNodeData;
  begin
    Result            := TreeViewMetier1.Items.AddChild(Parent, Txt);
    Result.ImageIndex := 0;
    D                 := TMyNodeData.Create;
    D.AdditionalData  := Code;
    Result.Data       := D;
  end;

  procedure Emplacements(Parent: TTreeNode; const Slots: TTowSlots);
  var S, J: Integer;
  begin
    for S := 0 to High(Slots) do
      if Length(Slots[S]) = 1 then
        Feuille(Parent, TowLibelleDe(Slots[S][0]), Slots[S][0])
      else
        begin
          Sb            := TreeViewMetier1.Items.AddChild(Parent, ConstArbreAuChoix);
          Sb.ImageIndex := 0;
          for J := 0 to High(Slots[S]) do
            Feuille(Sb, TowLibelleDe(Slots[S][J]), Slots[S][J]);
        end;
  end;

begin
  Carrieres := TowCarrieresCache;
  Origines  := TowOriginesCache;
  P := -1;
  for I := 0 to High(Carrieres) do
    if Carrieres[I].Code = CodeCarriere then P := I;
  if P < 0 then Exit;
  C := Carrieres[P];

  // origines admises, avec la plage du d100 (rien = choix libre seulement)
  Br            := TreeViewMetier1.Items.AddChild(Node, ConstArbreRacepossible);
  Br.ImageIndex := 0;
  for I := 0 to High(Origines) do
    if TowCarriereAdmise(C, Origines[I].Code) then
      begin
        Pl := '';
        for K := 0 to High(C.Plages) do
          if (C.Plages[K].Origine = Origines[I].Code) and (C.Plages[K].De > 0) then
            begin
              if C.Plages[K].De = C.Plages[K].A then
                Pl := ' : ' + IntToStr(C.Plages[K].De)
              else
                Pl := ' : ' + IntToStr(C.Plages[K].De) + '-' + IntToStr(C.Plages[K].A);
            end;
        Feuille(Br, Origines[I].Libelle + Pl, Origines[I].Code);
      end;

  // caracteristiques favorisees (3 par carriere)
  if Length(C.Favoris) > 0 then
    begin
      Br            := TreeViewMetier1.Items.AddChild(Node, ConstArbreAttribut);
      Br.ImageIndex := 0;
      for K := 0 to High(C.Favoris) do
        Feuille(Br, ChercheAttribut(C.Favoris[K]).Libelle, C.Favoris[K]);
    end;

  // statut de depart
  Br := TreeViewMetier1.Items.AddChild(Node, 'Status');
  Br.ImageIndex := 0;
  Feuille(Br, C.Status, 'RULES-STATUS_' + C.Status);

  // competences : N a monter de +1 parmi les candidates
  Br            := TreeViewMetier1.Items.AddChild(Node, ConstArbreCompetence);
  Br.ImageIndex := 0;
  Sb            := TreeViewMetier1.Items.AddChild(Br, IntToStr(C.CompNb) + ' x ' + ConstArbreAuChoix + ' (+1)');
  Sb.ImageIndex := 0;
  for K := 0 to High(C.CompChoix) do
    Feuille(Sb, TowLibelleDe(C.CompChoix[K]), C.CompChoix[K]);

  if Length(C.LoreSlots) > 0 then
    begin
      Br            := TreeViewMetier1.Items.AddChild(Node, 'Lores');
      Br.ImageIndex := 0;
      Emplacements(Br, C.LoreSlots);
    end;

  if C.TalentCarriere <> '' then
    begin
      Br            := TreeViewMetier1.Items.AddChild(Node, ConstArbreTalent);
      Br.ImageIndex := 0;
      Feuille(Br, C.TalentCarriere, 'CAREER-TALENT:' + C.Code);
    end;

  if Length(C.Familles) > 0 then
    begin
      Br            := TreeViewMetier1.Items.AddChild(Node, GetTexteLibelle('RULES-MESS_141'));
      Br.ImageIndex := 0;
      for K := 0 to High(C.Familles) do
        Feuille(Br, TowLibelleDe(C.Familles[K]), C.Familles[K]);
    end;

  if Length(C.TrappingSlots) > 0 then
    begin
      Br            := TreeViewMetier1.Items.AddChild(Node, ConstArbreEquipement);
      Br.ImageIndex := 0;
      Emplacements(Br, C.TrappingSlots);
    end;

  if Length(C.AssetSlots) > 0 then
    begin
      Br            := TreeViewMetier1.Items.AddChild(Node, GetTexteLibelle('RULES-MESS_140'));
      Br.ImageIndex := 0;
      Emplacements(Br, C.AssetSlots);
    end;
end;

// sélectionner un métier
procedure TWinMetiers.TabMetierSelection(Sender: TObject; aCol, aRow: Integer);
  var
    I, J, K: Integer;
  begin
      DeleteData(TreeViewMetier1,TreeViewMetier1.Items.GetFirstNode);
      TreeViewMetier1.Items.Clear;

      // ajouter la racine
      MetierEnCours   := TabMetier.Cells[1,aRow];

      // Les icones de niveau peuvent etre propres a l'ethnie : on les recharge AVANT de
      // construire l'arbre et la bande d'attributs.
      ChargeImagesNiveau(MetierEnCours);

      Node            := TreeViewMetier1.Items.Add(nil, TabMetier.Cells[2,aRow]);
      Node.ImageIndex := 0;
      AffMetier.Text  := TabMetier.Cells[2,aRow];

      CheminClass     := CheminImageClasse(TabMetier.Cells[8,aRow]);
      if FileExists(CheminClass) then
        begin
          ImageClass1.Picture.LoadFromFile(CheminClass);
          ImageClass2.Picture.LoadFromFile(CheminClass);
        end;

      // charger les éléments
      if ValVersion = 'WFRPTOW' then
        begin
          ChargeMetierTow(TreeViewMetier1, MetierEnCours);
          // bande des caracteristiques : * sur les 3 favorisees de la carriere
          for I := 1 to TabAttribut.ColCount - 1 do
            TabAttribut.Cells[I, 1] := '';
          for J := 0 to High(TowCarrieresCache) do
            if TowCarrieresCache[J].Code = MetierEnCours then
              for K := 0 to High(TowCarrieresCache[J].Favoris) do
                for I := 1 to TabAttribut.ColCount - 1 do
                  if TabAttribut.Cells[I, 2] = TowCarrieresCache[J].Favoris[K] then
                    TabAttribut.Cells[I, 1] := '*';
        end
      else
        begin
          ChargeRaceMetier();
          ChargeAdaptationMetier();
          ChargeMetierNiveau();
          ChargeEnchainementMetier();
          ChargeMetiersArtisan();
        end;
      TreeViewMetier1.FullExpand;

      // Les ethnies (sous chaque espece de la branche "races possibles") restent
      // repliees par defaut - FullExpand les a ouvertes avec le reste de l'arbre.
      NodeBranche := Node.GetFirstChild;
      while Assigned(NodeBranche) and (NodeBranche.Text <> ConstArbreRacepossible) do
        NodeBranche := Node.GetNextChild(NodeBranche);
      if Assigned(NodeBranche) then
        begin
          NodeFeuille := NodeBranche.GetFirstChild;
          while Assigned(NodeFeuille) do
            begin
              NodeFeuille.Collapse(False);
              NodeFeuille := NodeBranche.GetNextChild(NodeFeuille);
            end;
        end;

      TreeViewMetier1.Selected := TreeViewMetier1.Items.GetFirstNode;
  end;

// Mise en forme de l'arbre
procedure TWinMetiers.TreeViewMetier1AdvancedCustomDrawItem(
  Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState;
  Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
begin
    if (Node.Level in [1,2]) then
      begin
         if (Node.Parent.Text <> ConstArbreRacepossible)
            and (Node.Parent.Text <> GetTexteLibelle('RULES-LAB_703'))
            and (Node.Parent.Text <> GetTexteLibelle('RULES-LAB_704')) then
               Sender.Font.Style := Sender.Font.Style + [fsBold]
         else
               Sender.Font.Style := Sender.Font.Style - [fsBold];


          // Dessiner le cadre autour de la feuille
          if Node.Level = 1 then
            begin
              NodeRect       := Node.DisplayRect(False);
              TextWidth      := Sender.Canvas.TextWidth(Node.Text);  // Largeur du texte de la feuille
              FrameRect      := NodeRect;
              FrameRect.Left := FrameRect.Left + TextWidth + ((Node.Level + 1) * 29) + 5;  // Ajuster la position du cadre ici
              // Le numero de niveau se lit AVANT le point, et non sur le premier
              // caractere : "10.Archmage" commence par '1'. Les bornes viennent du
              // tableau lui-meme, donc elles suivent MaxNiveauMetier sans le rappeler.
              Nv := StrToIntDef(ExtractStringBefore(Node.Text, '.'), 0);
              if (Nv >= 1) and (Nv <= High(ColorList)) then
                ColorLoc := ColorList[Nv]
              else
                ColorLoc := CouleurGrisFonce;  // Couleur du cadre
              Sender.Canvas.brush.Color := colorloc;  // Couleur du cadre
              Sender.Canvas.Pen.Width   := 1;  // Épaisseur du cadre
              Sender.Canvas.Rectangle(FrameRect);
            end
      end
    else
        begin
          Sender.Font.Style := Sender.Font.Style - [fsBold];
        end;
    DefaultDraw := True;  // Permettre le dessin par défaut
end;

procedure TWinMetiers.TreeViewMetier1Change(Sender: TObject; Node: TTreeNode);
Var
  PRace:        StructureRace;
  PEspece:      StructureEspece;
  PTalent:      StructureTalent;
  PAttribut:    StructureAttribut;
  PCompetence:  StructureCompetence;
  PArme:        StructureArme;
  PArmure:      StructureArmure;
  PTrapping:    StructureTrapping;
  PMetierLie:   StructureMetier;
  CheminImage1: String;
  CheminImage2: String;
  CheminImage3: String;
  NodeData:     TMyNodeData;
Begin
    if Assigned(Node) then
      begin
        CheminImage1         := '';
        CheminImage2         := '';
        CheminImage3         := '';
        AffCode.Text         := '';
        AffAttribut.Text     := '';
        AffDescription.Text  := TabMetier.Cells[4, TabMetier.Row];
        // Obtenez le texte du nœud sélectionné
        NodeData             := TMyNodeData(Node.Data);
        if (ValVersion = 'WFRPTOW') and (Node <> TreeViewMetier1.Items.GetFirstNode) then
          begin
            // TOW : le code de la feuille est dans Data, libelle et texte viennent du livre TOW
            AffType.text := Node.Parent.Text;
            if Node.Data <> nil then
              begin
                AffCode.Text := NodeData.AdditionalData;
                AffLib.Text  := TowLibelleDe(AffCode.Text);
                if TowExplicationDe(AffCode.Text) <> '' then
                  AffDescription.Text := TowExplicationDe(AffCode.Text);
              end;
          end
        else if Node <> TreeViewMetier1.Items.GetFirstNode then
          begin
            CheminImage2   := '';
            AffType.text   := Node.Parent.Text;
            if AffType.text = ConstArbreRacepossible then
                begin
                  // Noeud "espece" (regroupement de plusieurs ethnies) : pas de fiche
                  // detaillee a ce niveau, juste son libelle et son livre - le detail
                  // (age/taille/description/image) reste sur la feuille ethnie ci-dessous.
                  PEspece            := ChercheEspece(NodeData.AdditionalData);
                  AffCode.Text       := PEspece.CodeEspece;
                  AffLib.Text        := PEspece.Libelle;
                  AffLivre.Text      := getTexteLibelle(PEspece.Livre,'','',true);
                  AffDescription.Text:= '';
                end
            else if Assigned(Node.Parent.Parent) and (Node.Parent.Parent.Text = ConstArbreRacepossible) then
                begin
                  // Feuille ethnie, sous le noeud "espece" - comportement inchange.
                  AffType.text       := ConstArbreRacepossible;
                  PRace              := ChercheRace(NodeData.AdditionalData);
                  AffCode.Text       := PRace.CodeRace;
                  AffLib.Text        := PRace.Libelle;
                  AffLivre.Text      := getTexteLibelle(PRace.Livre,'','',true);
                  CheminImage1       := CheminRaceImage(PRace.CodeRace,'2');
                  CheminImage2       := CheminRaceImage(PRace.CodeRace,'1');
                  AffDescription.Text:= TexteOuPage(PRace.Description, ConstXmlDataSpecie, PRace.Livre, PRace.CodeRace);
                end
            else if ((AffType.text = GetTexteLibelle('RULES-LAB_703')) or (AffType.text = GetTexteLibelle('RULES-LAB_704')))
                    and (Node.Data <> nil) then
                begin
                  // carriere d'entree ou de sortie : sa fiche
                  PMetierLie         := ChercheMetier(NodeData.AdditionalData);
                  AffCode.Text       := PMetierLie.CodeMetier;
                  AffLib.Text        := PMetierLie.Libelle;
                  AffLivre.Text      := getTexteLibelle(PMetierLie.Livre,'','',true);
                  AffDescription.Text:= PMetierLie.Description;
                end
            else if (AffType.text = ConstArbreAttribut) and (Node.Data <> nil) then
                begin
                  PAttribut          := ChercheAttribut(NodeData.AdditionalData);
                  AffCode.Text       := PAttribut.CodeAttribut;
                  AffLib.Text        := PAttribut.Libelle;
                  AffDescription.Text:= TexteOuPage(PAttribut.Description, ConstXmlDataAttribut, PAttribut.Livre, PAttribut.CodeAttribut);
                end
            else if AffType.text = ConstArbreCompetence then
                Begin
                  if Node.Data <> nil then
                    begin
                      PCompetence        := ChercheCompetence(NodeData.AdditionalData);
                      AffCode.Text       := PCompetence.CodeCompetence;
                      AffLib.Text        := PCompetence.Libelle;
                      AffLivre.Text      := getTexteLibelle(PCompetence.Livre,'','',true);
                      AffAttribut.Text   := GetTExteLibelle(PCompetence.CodeAttribut);
                      AffDescription.Text:= TexteOuPage(PCompetence.Description, ConstXmlDataSkill, PCompetence.Livre, PCompetence.CodeCompetence);
                    end;
                end
            else if AffType.text = ConstArbreTalent then
                Begin
                  if Node.Data <> nil then
                    begin
                      PTalent            := ChercheTalent(NodeData.AdditionalData);
                      AffCode.Text       := PTalent.CodeTalent;
                      AffLib.Text        := PTalent.Libelle;
                      AffLivre.Text      := getTexteLibelle(PTalent.Livre,'','',true);
                      AffDescription.Text:= DescriptionTalentOuPage(PTalent.CodeTalent, ConstCodeRaceCreationGenerique);
                    end;
                end
            else if AffType.text = ConstArbreEquipement then
              Begin
                if Node.text <> ConstArbreAuchoix then
                begin
                  if Node.Data <> nil then
                    begin
                      if (copy(Node.text,1,Length(EquipArme)) = EquipArme) then
                        begin
                          PArme              := ChercheArme(NodeData.AdditionalData);
                          AffCode.Text       := PArme.CodeArme;
                          AffLib.Text        := PArme.Libelle;
                          AffLivre.Text      := getTexteLibelle(PArme.Livre,'','',true);
                          AffDescription.Text:= TexteArme(PArme);
                        end
                      else if (copy(Node.text,1,Length(EquipArmure)) = EquipArmure) then
                        begin
                          PArmure            := ChercheArmure(NodeData.AdditionalData);
                          AffCode.Text       := PArmure.CodeArmure;
                          AffLib.Text        := PArmure.Libelle;
                          AffLivre.Text      := getTexteLibelle(PArmure.Livre,'','',true);
                          AffDescription.Text:= TexteArmure(PArmure);
                        end
                      else if (copy(Node.text,1,Length(EquipDivers)) = EquipDivers) then
                        begin
                          PTrapping          := ChercheTrapping(NodeData.AdditionalData);
                          AffCode.Text       := PTrapping.CodeTrapping;
                          AffLib.Text        := PTrapping.Libelle;
                          AffLivre.Text      := getTexteLibelle(PTrapping.Livre,'','',true);
                          AffDescription.Text:= TexteTrapping(PTrapping);
                        end;
                    end;
                end;
              end
            else if AffType.text = ConstArbreAuchoix then
              Begin
                if Node.Data <> nil then
                  if Node.Parent.Parent.Text = ConstArbreCompetence then
                    begin
                      PCompetence        := ChercheCompetence(NodeData.AdditionalData);
                      AffCode.Text       := PCompetence.CodeCompetence;
                      AffLib.Text        := PCompetence.Libelle;
                      AffLivre.Text      := getTexteLibelle(PCompetence.Livre,'','',true);
                      AffAttribut.Text   := GetTexteLibelle(PCompetence.CodeAttribut);
                      if (PCompetence.Description = '')
                         and (Pos(SeparateurSpecialisationTalent, PCompetence.CodeCompetence) > 0) then
                        PCompetence      := ChercheCompetence(CodeGeneriqueDeduit(PCompetence.CodeCompetence));
                      AffDescription.Text:= TexteOuPage(PCompetence.Description, ConstXmlDataSkill, PCompetence.Livre, PCompetence.CodeCompetence);                    end
                  else
                  begin
                    PArme              := ChercheArme(NodeData.AdditionalData);
                  end;
              end;
          end;
       end;
        if ValVersion = 'WFRPTOW' then
          begin
            // TOW : une seule illustration par carriere (chemin commun CheminMetierImage), rien d autre a cote
            CheminImage1 := '';
            CheminImage2 := '';
          end;
        if CheminImage1 = '' then
           CheminImage3 := CheminMetierImage(MetierEnCours);
        if FileExists(CheminImage1) then
           Image1.Picture.LoadFromFile(CheminImage1)
        else
           Image1.Picture := nil;
        if FileExists(CheminImage2) then
           Image2.Picture.LoadFromFile(CheminImage2)
        else
           Image2.Picture := nil;
        if FileExists(CheminImage3) then
           Image3.Picture.LoadFromFile(CheminImage3)
        else
           Image3.Picture := nil;
        Image1.BringToFront;
        PanelHautGauche.visible := (AffCode.Text <> '');
        PanelDescription.visible:= (AffDescription.Text <> '');
        AffAttribut.visible     := (AffAttribut.Text <> '');
        LabAttribut.visible     := (AffAttribut.Text <> '');
   end;

end.


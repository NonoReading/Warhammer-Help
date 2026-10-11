unit GlobalFonts;

// gérer les polices et les couleurs par défaut des champs

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, StdCtrls, Forms, Grids, LazUtils, ComCtrls, fpttf,
  ChargeConstantes, Graphics, ExtCtrls, SysUtils, Buttons,
  Dialogs, LMessages,LclIntf, Types, BGRAControls, BGRABitmap, BGRABitmapTypes,
  BCButton, BCButtonFocus, BCTypes, BCLabel, BCLabelContour;


type
 TButton = Class(StdCtrls.Tbutton)
   Procedure WndProc(Var Msg:TLMessage);override;
 end;


procedure StylesTStringGrid(Table: TStringGrid);
// Ligne selectionnee commune a toutes les grilles : ligne entiere, fond rouge sombre, texte or du logo
procedure SelectionGrilleWarhammer(Table: TStringGrid);
// Meme couleur de selection sans changer le mode de selection (cellule ou ligne) de la grille
procedure CouleurSelectionGrille(Table: TStringGrid);
// Grille d affichage seul : aucune mise en evidence de la cellule courante
procedure SansSelectionGrille(Table: TStringGrid);
procedure MiseAJourUnContenaire(AContainer: TWinControl);
procedure MiseEnFormeDesChamp(Win: TForm);
procedure TabGenericDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; {%H-}aState: TGridDrawState);

const
  // Couleurs du logo Warhammer (echantillonnees sur l image du menu), BGR
  CouleurOrLogo    = TColor($0038E0F0);
  CouleurRougeLogo = TColor($002818E0);
  // Rouge sombre (140,20,30) : ligne selectionnee, environ 7,6:1 avec l or du logo
  CouleurSelection = TColor($001E148C);

implementation

type
  TGestionSelection = class
    class procedure PrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    class procedure PrepareCanvasNeutre(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
  end;

class procedure TGestionSelection.PrepareCanvas(Sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
begin
  if (aRow > 0) and (gdSelected in aState) then
    TStringGrid(Sender).Canvas.Font.Color := CouleurOrLogo;
end;

procedure CouleurSelectionGrille(Table: TStringGrid);
begin
  Table.SelectedColor    := CouleurSelection;
  Table.FocusRectVisible := False;
  // Une grille qui peint deja ses cellules (OnPrepareCanvas propre) garde son gestionnaire
  if not Assigned(Table.OnPrepareCanvas) then
    Table.OnPrepareCanvas := @TGestionSelection.PrepareCanvas;
end;

class procedure TGestionSelection.PrepareCanvasNeutre(Sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
begin
  // Cellule courante peinte comme les autres : meme fond, meme couleur de texte
  if aRow > 0 then
    begin
      TStringGrid(Sender).Canvas.Brush.Color := TStringGrid(Sender).Color;
      TStringGrid(Sender).Canvas.Font.Color  := TStringGrid(Sender).Font.Color;
    end;
end;

procedure SansSelectionGrille(Table: TStringGrid);
begin
  Table.SelectedColor    := Table.Color;
  Table.FocusRectVisible := False;
  Table.OnPrepareCanvas  := @TGestionSelection.PrepareCanvasNeutre;
end;

procedure SelectionGrilleWarhammer(Table: TStringGrid);
begin
  Table.Options := Table.Options - [goRangeSelect] + [goRowSelect, goDrawFocusSelected];
  CouleurSelectionGrille(Table);
end;

procedure StylesTStringGrid(Table: TStringGrid);
  begin
    Table.Font.Name        := ConstPoliceNom;
    Table.Color            := CouleurDefColor;
    if Table.Font.Size < ConstPoliceTaille then
      Table.Font.Size      := ConstPoliceTaille;
    Table.Font.Bold        := True;
    Table.Font.Color       := clBlack;
    Table.FixedColor       := clBlack;
    Table.GridLineColor    := clSilver;
    Table.TitleFont.Color  := clWhite;
    CouleurSelectionGrille(Table);
  end;

// Une procedure par type de composant ; MiseAJourUnContenaire les appelle dans l ordre du
// test "is" d origine (le premier type reconnu l emporte : TBCLabelContour avant TBCLabel).

procedure StyleOngletFond(AContainer: TWinControl; Onglet: TTabSheet);
var
  Shape: TShape;
  J: Integer;
begin
  Shape                  := tshape.Create(AContainer);
  Shape.Parent           := Onglet;
  Shape.Align            := alClient;
  Shape.Font.Name        := ConstPoliceNom;
  Shape.Font.Size        := ConstPoliceTaille;
  Shape.Brush.Color      := CouleurDefInverse;
  For J := 0 to Onglet.ControlCount  - 1 do
    begin
      if Onglet.Controls[J] is TLabel then
         begin
           TLabel(Onglet.Controls[J]).ParentColor := False;
           TLabel(Onglet.Controls[J]).Color       := ClREd;
           TLabel(Onglet.Controls[J]).Font.Color  := ClGray;
         end;
    end;
end;

// Fond uni derriere les RadioButton d'un GroupBox, meme procede que pour les TabSheet
// (un TShape en Align=alClient, windowed donc peint sous les RadioButton qui
// restent des HWND natifs par-dessus) : la legende d'un RadioButton Windows une fois actif
// ignore Font.Color et se dessine dans une teinte sombre, invisible sur le fond noir du
// formulaire - un fond clair derriere la rend lisible sans avoir a maitriser sa couleur.
// Signale par Nono le 12/09/2026 (WinMutations, GroupBoxMutationType/Entree), tentatives
// Font.Color puis SetWindowTheme sur le RadioButton lui-meme restees sans effet visible.
procedure StyleGroupBoxFond(AContainer: TWinControl; Groupe: TGroupBox);
var
  Shape: TShape;
begin
  Shape             := TShape.Create(AContainer);
  Shape.Parent      := Groupe;
  Shape.Align       := alClient;
  Shape.Brush.Color := CouleurDefColor;
end;

procedure StyleListeArbre(Champ: TControl);
begin
  Champ.Font.Name := ConstPoliceNom;
  Champ.Color     := CouleurDefColor;
  if Champ.Font.Size < ConstPoliceTaille then
     Champ.Font.Size := ConstPoliceTaille;
end;

procedure StyleMemo(Memo: TMemo);
begin
  Memo.Font.Name := ConstPoliceNom;
  if Memo.ReadOnly = true then
    begin
      Memo.Color     := CouleurDefColor;
      Memo.Font.Color:= CouleurDefInverse;
    end
  else
    Memo.Color     := ClWhite;
  if Memo.Font.Size < ConstPoliceTaille then
     Memo.Font.Size := ConstPoliceTaille;
end;

procedure StyleEdit(Edit: TEdit);
begin
  Edit.Font.Name := ConstPoliceNom;
  if Edit.ReadOnly = true then
    begin
      Edit.Color     := CouleurDefColor;
      Edit.Font.Color:= CouleurDefInverse;
    end
  else
    Edit.Color     := CouleurDefColor;
  if Edit.Font.Size < ConstPoliceTaille then
     Edit.Font.Size := ConstPoliceTaille;
end;

procedure StyleLibelle(Libelle: TControl);
begin
  Libelle.Font.Name := ConstPoliceNom;
  if Libelle.Font.Size < ConstPoliceTaille then
     Libelle.Font.Size := ConstPoliceTaille;
  Libelle.Font.Bold:= True;
  if Libelle is TLabelContour then
    begin
      // Libelle blanc cerne de rouge (Font.Color reste rouge : voir TLabelContour)
      TLabelContour(Libelle).CouleurTexte   := clWhite;
      TLabelContour(Libelle).ContourCouleur := CouleurRougeLogo;
    end
  else
    Libelle.Font.color:= CouleurRougeLogo;
end;

procedure StyleTitreContour(Titre: TBCLabelContour);
begin
  Titre.FontEx.Name   := ConstPoliceNom;
  Titre.FontEx.Height := 30;
  Titre.FontEx.Style  := [fsbold];
  Titre.FontEx.Color  := CouleurOrLogo;
  Titre.FontEx.Shadow := False;
  Titre.ContourCouleur   := CouleurRougeLogo;
  Titre.ContourEpaisseur := 2;
  Titre.Height := 40;
end;

procedure StyleLibelleBC(Libelle: TBCLabel);
begin
  Libelle.FontEx.Name         := ConstPoliceNom;
  Libelle.FontEx.Height       := 30;
  Libelle.FontEx.Style        := [fsbold];
  Libelle.FontEx.color        := CouleurOrLogo;
  Libelle.FontEx.Shadow       := True;
  Libelle.FontEx.ShadowColor  := CouleurRougeLogo;
  Libelle.FontEx.ShadowRadius := 5;
  Libelle.FontEx.ShadowOffsetX:= 2;
  Libelle.FontEx.ShadowOffsetY:= 2;
  Libelle.Height:= 40;
end;

procedure StyleRadio(Radio: TRadioButton);
begin
  Radio.Font.Name := ConstPoliceNom;
  Radio.Font.Size := ConstPoliceTaille;
  Radio.Font.Bold := True;
  // Le theme Windows dessine la legende d'un RadioButton actif dans sa propre teinte
  // (Font.Color ignore) - CouleurDefInverse suppose desormais le fond clair pose par le
  // TGroupBox ci-dessus (meme convention que TEdit/TMemo : texte fonce sur fond clair).
  Radio.Font.Color := CouleurDefInverse;
  Radio.Color     := CouleurDefColor;
end;

procedure StyleBouton(Bouton: TButton);
begin
  Bouton.Font.Name := ConstPoliceNom;
  if Bouton.Font.Size < ConstPoliceBtTaille then
     Bouton.Font.Size := ConstPoliceBtTaille;
  Bouton.Font.Bold:= True;
  Bouton.Color     := CouleurDefColor;
end;

procedure StyleBoutonBC(Bouton: TBCButton);
begin
  Bouton.StateNormal.Background.Gradient1.EndColor   := CouleurButton;//ClSilver;
  Bouton.StateNormal.Background.Gradient2.EndColor   := CouleurButton;//ClSilver;
  Bouton.StateNormal.Background.Gradient1.StartColor := CouleurButton;//ClSilver;
  Bouton.StateNormal.Background.Gradient2.StartColor := CouleurButton;//ClSilver;
  Bouton.StateNormal.FontEx.ShadowColor              := CouleurRougeLogo;
  Bouton.StateNormal.FontEx.ShadowRadius             := 5;
  // Texte jaune cerne de rouge (contour net) a la place de l ombre
  if Bouton is TBCButtonContour then
    Bouton.StateNormal.FontEx.Shadow := False;
  Bouton.StateNormal.FontEx.Color                    := CouleurOrLogo;
  Bouton.StateNormal.FontEx.Height                   := ConstPoliceBtTaille;
  Bouton.StateNormal.FontEx.Style                    := [fsBold];
  Bouton.StateNormal.FontEx.Name                     := ConstPoliceNom;
  Bouton.StateNormal.Border.Style                    := bboSolid;
  Bouton.StateNormal.Border.Width                    := 2;
  Bouton.StateNormal.Border.Color                    := CouleurRougeLogo;

  Bouton.StateHover.Background.Gradient1.EndColor    := CouleurOrLogo;
  Bouton.StateHover.Background.Gradient2.EndColor    := CouleurOrLogo;
  Bouton.StateHover.Background.Gradient1.StartColor  := CouleurOrLogo;
  Bouton.StateHover.Background.Gradient2.StartColor  := CouleurOrLogo;
  Bouton.StateHover.FontEx.Color                     := ClBlack;
  Bouton.StateHover.FontEx.Height                    := ConstPoliceBtTaille;
  Bouton.StateClicked.FontEx.Style                   := [fsbold];
  Bouton.StateHover.FontEx.Name                      := ConstPoliceNom;

  Bouton.StateClicked.Background.Gradient1.EndColor  := ClBlack;
  Bouton.StateClicked.Background.Gradient2.EndColor  := ClBlack;
  Bouton.StateClicked.Background.Gradient1.StartColor:= ClBlack;
  Bouton.StateClicked.Background.Gradient2.StartColor:= ClBlack;
  Bouton.StateClicked.FontEx.Color                   := CouleurButton;
  Bouton.StateClicked.FontEx.Height                  := ConstPoliceBtTaille;
  Bouton.StateClicked.FontEx.Style                   := [fsbold];
  Bouton.StateClicked.FontEx.Name                    := ConstPoliceNom;
end;

procedure StyleBoutonFocus(Bouton: TBCButtonFocus);
begin
  Bouton.StateNormal.Background.Gradient1.EndColor   := ClSilver;
  Bouton.StateNormal.Background.Gradient2.EndColor   := ClSilver;
  Bouton.StateNormal.Background.Gradient1.StartColor := ClSilver;
  Bouton.StateNormal.Background.Gradient2.StartColor := ClSilver;
  Bouton.StateNormal.FontEx.ShadowColor              := CouleurRougeLogo;
  Bouton.StateNormal.FontEx.ShadowRadius             := 5;
  // Texte jaune cerne de rouge (contour net) a la place de l ombre
  if Bouton is TBCButtonFocusContour then
    Bouton.StateNormal.FontEx.Shadow := False;
  Bouton.StateNormal.FontEx.Color                    := CouleurOrLogo;
  Bouton.StateNormal.FontEx.Height                   := ConstPoliceBtTaille;
  Bouton.StateNormal.FontEx.Style                    := [fsBold];
  Bouton.StateNormal.FontEx.Name                     := ConstPoliceNom;
  Bouton.StateNormal.Border.Style                    := bboSolid;
  Bouton.StateNormal.Border.Width                    := 2;
  Bouton.StateNormal.Border.Color                    := CouleurRougeLogo;

  Bouton.StateHover.Background.Gradient1.EndColor    := CouleurOrLogo;
  Bouton.StateHover.Background.Gradient2.EndColor    := CouleurOrLogo;
  Bouton.StateHover.Background.Gradient1.StartColor  := CouleurOrLogo;
  Bouton.StateHover.Background.Gradient2.StartColor  := CouleurOrLogo;
  Bouton.StateHover.FontEx.Color                     := ClBlack;
  Bouton.StateHover.FontEx.Height                    := ConstPoliceBtTaille;
  Bouton.StateClicked.FontEx.Style                   := [fsbold];
  Bouton.StateHover.FontEx.Name                      := ConstPoliceNom;

  Bouton.StateClicked.Background.Gradient1.EndColor  := ClBlack;
  Bouton.StateClicked.Background.Gradient2.EndColor  := ClBlack;
  Bouton.StateClicked.Background.Gradient1.StartColor:= ClBlack;
  Bouton.StateClicked.Background.Gradient2.StartColor:= ClBlack;
  Bouton.StateClicked.FontEx.Color                   := CouleurDefColor;
  Bouton.StateClicked.FontEx.Height                  := ConstPoliceBtTaille;
  Bouton.StateClicked.FontEx.Style                   := [fsbold];
  Bouton.StateClicked.FontEx.Name                    := ConstPoliceNom;
end;

procedure MiseAJourUnContenaire(AContainer: TWinControl);
var
  Composant: TComponent;
  I:         Integer;
begin
  // Mise à jour des différents types de champ pour homogénéiser le tout
  // Changer la couleur de la barre de titre en noir

  for I := 0 to AContainer.ComponentCount - 1 do
  begin
    Composant := AContainer.Components[I];
    if Composant is TTabSheet then
      StyleOngletFond(AContainer, TTabSheet(Composant))
    else if Composant is TGroupBox then
      StyleGroupBoxFond(AContainer, TGroupBox(Composant))
    else if (Composant is TComboBox) or (Composant is TTreeView) then
      StyleListeArbre(TControl(Composant))
    else if Composant is TMemo then
      StyleMemo(TMemo(Composant))
    else if Composant is TEdit then
      StyleEdit(TEdit(Composant))
    else if Composant is TStringGrid then
      StylesTStringGrid(TStringGrid(Composant))
    else if Composant is TLabel then
      StyleLibelle(TControl(Composant))
    // Titres : texte jaune cerne de rouge (doit preceder TBCLabel, dont il herite)
    else if Composant is TBCLabelContour then
      StyleTitreContour(TBCLabelContour(Composant))
    else if Composant is TBCLabel then
      StyleLibelleBC(TBCLabel(Composant))
    else if Composant is TRadioButton then
      StyleRadio(TRadioButton(Composant))
    else if Composant is TButton then
      StyleBouton(TButton(Composant))
    else if Composant is TBCButton then
      StyleBoutonBC(TBCButton(Composant))
    else if Composant is TBCButtonFocus then
      StyleBoutonFocus(TBCButtonFocus(Composant));
  end;
end;

Procedure TButton.WndPRoc(Var Msg:TLMessage);
//const GlyphOffset=4;
 var
   C:TControlCanvas;
   R:TREct;
//   TextDimension:Tsize;
//   X,Y,GlyphHeight:integer;
Begin
  Inherited;
  if Msg.Msg = LM_Paint Then
    Begin
      C             := TControlCanvas.Create;
      C.Control     := Self;
      C.Brush.Color := CouleurDefColor;
      R             := ClientRect;
      C.FillRect(R);
      C.Pen.Color   := CouleurDefInverse;
      C.Font.Bold   := true;
      if Self.Font.Size < ConstPoliceTaille then
        C.Font.Size := ConstPoliceTaille
      else
        C.Font.Size := Self.Font.Size;
      InFlateRect(R,-1,-1);
      C.Rectangle(R);
      C.TextOut(3,2,Caption);

      C.Free;
    end;
end;

procedure MiseEnFormeDesChamp(Win: TForm);
var
  I: Integer;
begin
  // Recherche des contenaires de l'unité en cours
  for I := 0 to Screen.FormCount - 1 do
  begin
    // Parcourir tous les formulaires ou composants qui affichent du texte
    if Screen.Forms[I] is TForm then
       if Screen.Forms[I] = Win then
          if Screen.Forms[I].Enabled then
            MiseAJourUnContenaire(Screen.Forms[I]);
  end;
end;

procedure TabGenericDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
Var
  CellText: string;
  TextWidth: Integer;
  TextX: Integer;
  TextY: integer;
  Grid:  TStringGrid;
begin
    Grid := TStringGrid(Sender);
    if (aCol > 0) then
     begin
       if aRow = 0 then
         begin
           // Dessiner le fond de la cellule de l'entête
           Grid.Canvas.Brush.Color := clBlack;
           Grid.Canvas.FillRect(aRect);

           // Dessiner le texte de l'entête centré horizontalement et verticalement
           Grid.Canvas.Font.Color := clWhite;
           Grid.Canvas.Font.Style := [fsBold];
           Grid.Canvas.Font.Size  := ConstPoliceTaille;
           Grid.Canvas.Font.Name  := ConstPoliceNom;

           // Calculer la position x et y du texte pour l'alignement centré
           if aCol > 0 then
           begin
             CellText  := Grid.Cells[aCol, aRow]; //Grid.Columns[aCol-1].Title.Caption; //
             TextWidth := Grid.Canvas.TextWidth(CellText);
             TextX     := aRect.Left + (aRect.Right - aRect.Left - TextWidth) div 2;
             TextY     := aRect.Top + (aRect.Bottom - aRect.Top - Grid.Canvas.TextHeight(CellText)) div 2;

             // Dessiner le texte de l'entête
             Grid.Canvas.TextRect(aRect, TextX, TextY, CellText);
           end;
         end
      end;
  end;


end.

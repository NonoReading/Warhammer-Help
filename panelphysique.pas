unit PanelPhysique;

{$mode ObjFPC}{$H+}

// Details physiques d'une RACE (bloc SUBCHAPTER_PHYSICAL de DATA_RACE, CONTEXT.md 2.107) dans la fiche de la race :
// formule d'age, formule de taille en pouces, relance de la taille au de maximal, nombre de jets sur la table des yeux,
// et deux tables 2d10 (yeux, cheveux) : Libelle / Debut / Fin. Les tables couvrent 2 a 20 sans trou ni chevauchement.
// Les formules sont des termes ajoutes par + : un nombre ou [N]dM (15+d10, 57+2d10, 10d10+20).
// Une race sans donnee n'a pas de bloc : les ethnies de la race tirent ceux de leur race.
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra), via TPanelRaceExtra.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, DOM, BCButton,
  ChargeTexte, GlobalFonts, PanelModificateurs, PanelFiche;

type
  TPanelPhysique = class(TPanelExtraFiche)
  private
    FTitre, FLabAge, FLabTaille, FLabJets, FLabExplose: TLabel;
    FEditAge, FEditTaille: TEdit;
    FCaseExplose: TCheckBox;
    FComboJets: TComboBox;
    FTitres: array[0..1] of TLabel;
    FGrilles: array[0..1] of TStringGrid;  // 0 = yeux, 1 = cheveux
    FBoutonsAjouter, FBoutonsRetirer: array[0..1] of TBCButton;
    FLectureSeule: Boolean;
    function  NomTable(I: Integer): String;
    function  FormuleValide(const F: String): Boolean;
    function  Debut(I, R: Integer): Integer;
    function  Fin(I, R: Integer): Integer;
    function  Contenu: Boolean;
    function  ControlerTable(I: Integer): Boolean;
    procedure LabExploseClick(Sender: TObject);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Initialiser(Modele: TBCButton);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

const
  HauteurPhysique = 560;
  BaliseTable: array[0..1] of String = ('Eye', 'Hair');
  YTitre: array[0..1] of Integer = (112, 336);

constructor TPanelPhysique.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  Height := HauteurPhysique;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 600, 20);
  FLabAge := TLabelContour.Create(Self);
  FLabAge.Parent := Self;
  FLabAge.SetBounds(0, 28, 240, 18);
  FEditAge := TEdit.Create(Self);
  FEditAge.Parent := Self;
  FEditAge.SetBounds(0, 48, 220, 26);
  FLabTaille := TLabelContour.Create(Self);
  FLabTaille.Parent := Self;
  FLabTaille.SetBounds(250, 28, 300, 18);
  FEditTaille := TEdit.Create(Self);
  FEditTaille.Parent := Self;
  FEditTaille.SetBounds(250, 48, 220, 26);
  FLabJets := TLabelContour.Create(Self);
  FLabJets.Parent := Self;
  FLabJets.SetBounds(500, 28, 300, 18);
  FComboJets := TComboBox.Create(Self);
  FComboJets.Parent := Self;
  FComboJets.SetBounds(500, 48, 100, 26);
  FComboJets.Style := csDropDownList;
  FComboJets.Items.Add('1');
  FComboJets.Items.Add('2');
  FComboJets.Items.Add('3');
  FCaseExplose := TCheckBox.Create(Self);
  FCaseExplose.Parent := Self;
  FCaseExplose.SetBounds(0, 80, 22, 22);
  // le texte d'une case a cocher est noir sur fond noir dans ce theme : il est porte par un libelle
  FLabExplose := TLabelContour.Create(Self);
  FLabExplose.Parent := Self;
  FLabExplose.SetBounds(28, 82, 700, 20);
  FLabExplose.OnClick := @LabExploseClick;
  for I := 0 to 1 do
  begin
    FTitres[I] := TLabelContour.Create(Self);
    FTitres[I].Parent := Self;
    FTitres[I].SetBounds(0, YTitre[I], 600, 20);
    FGrilles[I] := TStringGrid.Create(Self);
    FGrilles[I].Parent := Self;
    CouleurSelectionGrille(FGrilles[I]);
    FGrilles[I].SetBounds(0, YTitre[I] + 24, 545, 150);
    FGrilles[I].ColCount := 3;
    FGrilles[I].RowCount := 1;
    FGrilles[I].FixedRows := 1;
    FGrilles[I].FixedCols := 0;
    FGrilles[I].Options := FGrilles[I].Options + [goEditing] - [goRangeSelect];
    FGrilles[I].ColWidths[0] := 340;
    FGrilles[I].ColWidths[1] := 90;
    FGrilles[I].ColWidths[2] := 90;
  end;
  Visible := False;
end;

procedure TPanelPhysique.Initialiser(Modele: TBCButton);
var
  I: Integer;

  function Copie(const Legende: String; Clic: TNotifyEvent; Gauche, Largeur, Y, Rang: Integer): TBCButton;
  begin
    Result := TBCButtonContour.Create(Self);
    Result.Assign(Modele);
    Result.Parent := Self;
    Result.Caption := Legende;
    Result.OnClick := Clic;
    Result.Tag := Rang;
    Result.SetBounds(Gauche, Y, Largeur, 36);
  end;

begin
  FTitre.Caption := GetTexteLibelle('RULES-LAB_601', 'Physical details');
  FLabAge.Caption := GetTexteLibelle('RULES-LAB_602', 'Age (e.g. 15+d10)');
  FLabTaille.Caption := GetTexteLibelle('RULES-LAB_603', 'Height in inches (e.g. 57+2d10)');
  FLabJets.Caption := GetTexteLibelle('RULES-LAB_605', 'Eye rolls');
  FLabExplose.Caption := GetTexteLibelle('RULES-LAB_604', 'Height: one more die when a die shows its maximum');
  FTitres[0].Caption := GetTexteLibelle('RULES-LAB_606', 'Eye colours (2d10)');
  FTitres[1].Caption := GetTexteLibelle('RULES-LAB_607', 'Hair colours (2d10)');
  for I := 0 to 1 do
  begin
    FGrilles[I].Cells[0, 0] := GetTexteLibelle('RULES-LAB_608', 'Colour');
    FGrilles[I].Cells[1, 0] := GetTexteLibelle('RULES-LAB_141');
    FGrilles[I].Cells[2, 0] := GetTexteLibelle('RULES-LAB_142');
    FBoutonsAjouter[I] := Copie(GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230, YTitre[I] + 180, I);
    FBoutonsRetirer[I] := Copie(GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250, YTitre[I] + 180, I);
  end;
  MiseAJourUnContenaire(Self);
end;

function TPanelPhysique.NomTable(I: Integer): String;
begin
  Result := FTitres[I].Caption;
end;

// Termes ajoutes par + : un nombre entier ou [N]dM (N facultatif).
function TPanelPhysique.FormuleValide(const F: String): Boolean;
var
  Termes: TStringList;
  I, P: Integer;
  T: String;
begin
  Result := False;
  if Trim(F) = '' then Exit;
  Termes := TStringList.Create;
  try
    Termes.Delimiter := '+';
    Termes.StrictDelimiter := True;
    Termes.DelimitedText := StringReplace(Trim(F), ' ', '', [rfReplaceAll]);
    for I := 0 to Termes.Count - 1 do
    begin
      T := LowerCase(Termes[I]);
      if T = '' then Exit;
      P := Pos('d', T);
      if P = 0 then
      begin
        if StrToIntDef(T, -1) < 0 then Exit;
      end
      else
      begin
        if (P > 1) and (StrToIntDef(Copy(T, 1, P - 1), 0) < 1) then Exit;
        if StrToIntDef(Copy(T, P + 1, MaxInt), 0) < 1 then Exit;
      end;
    end;
    Result := True;
  finally
    Termes.Free;
  end;
end;

function TPanelPhysique.Debut(I, R: Integer): Integer;
begin
  Result := StrToIntDef(Trim(FGrilles[I].Cells[1, R]), 0);
end;

// Une fin vide vaut le debut.
function TPanelPhysique.Fin(I, R: Integer): Integer;
begin
  if Trim(FGrilles[I].Cells[2, R]) = '' then
    Result := Debut(I, R)
  else
    Result := StrToIntDef(Trim(FGrilles[I].Cells[2, R]), 0);
end;

function TPanelPhysique.Contenu: Boolean;
begin
  Result := (Trim(FEditAge.Text) <> '') or (Trim(FEditTaille.Text) <> '') or
            (FGrilles[0].RowCount > 1) or (FGrilles[1].RowCount > 1);
end;

procedure TPanelPhysique.Charger(Element: TDOMElement);
var
  N, B: TDOMNode;
  I, R: Integer;
  Plage: String;
  P: Integer;
begin
  FEditAge.Text := '';
  FEditTaille.Text := '';
  FCaseExplose.Checked := False;
  FComboJets.ItemIndex := 0;
  for I := 0 to 1 do
  begin
    FGrilles[I].EditorMode := False;
    FGrilles[I].RowCount := 1;
  end;
  N := Element.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'SUBCHAPTER_PHYSICAL') then
    begin
      B := N.FirstChild;
      while B <> nil do
      begin
        if B.NodeType = ELEMENT_NODE then
        begin
          if B.NodeName = 'Age' then
            FEditAge.Text := ValeurXML(B)
          else if B.NodeName = 'Height' then
            FEditTaille.Text := ValeurXML(B)
          else if B.NodeName = 'HeightExplode' then
            FCaseExplose.Checked := ValeurXML(B) = '1'
          else if B.NodeName = 'EyeRolls' then
            FComboJets.ItemIndex := StrToIntDef(ValeurXML(B), 1) - 1
          else
            for I := 0 to 1 do
              if B.NodeName = BaliseTable[I] then
              begin
                R := FGrilles[I].RowCount;
                FGrilles[I].RowCount := R + 1;
                FGrilles[I].Cells[0, R] := TDOMElement(B).GetAttribute('name');
                Plage := ValeurXML(B);
                P := Pos('-', Plage);
                if P > 0 then
                begin
                  FGrilles[I].Cells[1, R] := Copy(Plage, 1, P - 1);
                  FGrilles[I].Cells[2, R] := Copy(Plage, P + 1, MaxInt);
                end
                else
                begin
                  FGrilles[I].Cells[1, R] := Plage;
                  FGrilles[I].Cells[2, R] := Plage;
                end;
              end;
        end;
        B := B.NextSibling;
      end;
    end;
    N := N.NextSibling;
  end;
  if FComboJets.ItemIndex < 0 then FComboJets.ItemIndex := 0;
end;

function TPanelPhysique.ControlerTable(I: Integer): Boolean;
var
  R, K: Integer;
  Plages: TStringList;
  Attendu: Integer;
begin
  Result := True;
  FGrilles[I].EditorMode := False;
  if FGrilles[I].RowCount < 2 then Exit;
  for R := 1 to FGrilles[I].RowCount - 1 do
  begin
    if Trim(FGrilles[I].Cells[0, R]) = '' then
    begin
      ShowMessage(Format('%s : ', [NomTable(I)]) + Format(GetTexteLibelle('RULES-LAB_609', 'Line %d: choose a name.'), [R]));
      Exit(False);
    end;
    if (Debut(I, R) < 2) or (Fin(I, R) > 20) or (Fin(I, R) < Debut(I, R)) then
    begin
      ShowMessage(Format('%s : ', [NomTable(I)]) + Format(GetTexteLibelle('RULES-LAB_610',
        'Line %d: start and end must be numbers from 2 to 20, the start no greater than the end.'), [R]));
      Exit(False);
    end;
  end;
  Plages := TStringList.Create;
  try
    Plages.Sorted := True;
    for R := 1 to FGrilles[I].RowCount - 1 do
      Plages.Add(Format('%.3d-%.3d', [Debut(I, R), Fin(I, R)]));
    Attendu := 2;
    for K := 0 to Plages.Count - 1 do
    begin
      if StrToInt(Copy(Plages[K], 1, 3)) <> Attendu then
      begin
        ShowMessage(Format('%s : ', [NomTable(I)]) + Format(GetTexteLibelle('RULES-LAB_611',
          'the ranges must cover 2 to 20 without gap or overlap (problem at %d).'), [Attendu]));
        Exit(False);
      end;
      Attendu := StrToInt(Copy(Plages[K], 5, 3)) + 1;
    end;
    if Attendu <> 21 then
    begin
      ShowMessage(Format('%s : ', [NomTable(I)]) + Format(GetTexteLibelle('RULES-LAB_611',
        'the ranges must cover 2 to 20 without gap or overlap (problem at %d).'), [Attendu]));
      Exit(False);
    end;
  finally
    Plages.Free;
  end;
end;

function TPanelPhysique.Controler: Boolean;
begin
  Result := True;
  FGrilles[0].EditorMode := False;
  FGrilles[1].EditorMode := False;
  if not Contenu then Exit;
  if not FormuleValide(FEditAge.Text) then
  begin
    ShowMessage(FLabAge.Caption + ' : ' + GetTexteLibelle('RULES-LAB_612',
      'use numbers and dice added with +, for example 15+2d10.'));
    Exit(False);
  end;
  if not FormuleValide(FEditTaille.Text) then
  begin
    ShowMessage(FLabTaille.Caption + ' : ' + GetTexteLibelle('RULES-LAB_612',
      'use numbers and dice added with +, for example 15+2d10.'));
    Exit(False);
  end;
  Result := ControlerTable(0) and ControlerTable(1);
end;

// Le bloc est reecrit en entier, apres les autres balises de la race ; rien a ecrire = pas de bloc.
procedure TPanelPhysique.Ecrire(Element: TDOMElement);
var
  N, Suivant: TDOMNode;
  Bloc, E: TDOMElement;
  Doc: TDOMDocument;
  I, R: Integer;

  procedure Ajoute(const Balise, Valeur: String);
  begin
    E := Doc.CreateElement(Balise);
    Bloc.AppendChild(Doc.CreateTextNode(#10));
    Bloc.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  FGrilles[0].EditorMode := False;
  FGrilles[1].EditorMode := False;
  Doc := Element.OwnerDocument;
  N := Element.FirstChild;
  while N <> nil do
  begin
    Suivant := N.NextSibling;
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'SUBCHAPTER_PHYSICAL') then
      Element.RemoveChild(N);
    N := Suivant;
  end;
  if not Contenu then Exit;
  Bloc := Doc.CreateElement('SUBCHAPTER_PHYSICAL');
  Element.AppendChild(Bloc);
  Ajoute('Age', Trim(FEditAge.Text));
  Ajoute('Height', Trim(FEditTaille.Text));
  if FCaseExplose.Checked then Ajoute('HeightExplode', '1');
  // 1 est la valeur par defaut a la lecture : ecrit seulement si elle differe
  if FComboJets.ItemIndex > 0 then Ajoute('EyeRolls', IntToStr(FComboJets.ItemIndex + 1));
  for I := 0 to 1 do
    for R := 1 to FGrilles[I].RowCount - 1 do
    begin
      E := Doc.CreateElement(BaliseTable[I]);
      E.SetAttribute('name', Trim(FGrilles[I].Cells[0, R]));
      Bloc.AppendChild(Doc.CreateTextNode(#10));
      Bloc.AppendChild(E);
      if Debut(I, R) = Fin(I, R) then
        EcrireValeurXML(E, IntToStr(Debut(I, R)))
      else
        EcrireValeurXML(E, IntToStr(Debut(I, R)) + '-' + IntToStr(Fin(I, R)));
    end;
  Bloc.AppendChild(Doc.CreateTextNode(#10));
end;

function TPanelPhysique.Signature(const Sep: String): String;
var
  I, R, C: Integer;
begin
  Result := Sep + FEditAge.Text + Sep + FEditTaille.Text + Sep + BoolToStr(FCaseExplose.Checked) +
            Sep + IntToStr(FComboJets.ItemIndex);
  for I := 0 to 1 do
    for R := 1 to FGrilles[I].RowCount - 1 do
      for C := 0 to 2 do
        Result := Result + Sep + FGrilles[I].Cells[C, R];
end;

procedure TPanelPhysique.MettreLectureSeule(Valeur: Boolean);
var
  I: Integer;
begin
  FLectureSeule := Valeur;
  FEditAge.ReadOnly := Valeur;
  FEditTaille.ReadOnly := Valeur;
  FCaseExplose.Enabled := not Valeur;
  FComboJets.Enabled := not Valeur;
  for I := 0 to 1 do
  begin
    if Valeur then
      FGrilles[I].Options := FGrilles[I].Options - [goEditing]
    else
      FGrilles[I].Options := FGrilles[I].Options + [goEditing];
    FBoutonsAjouter[I].Visible := not Valeur;
    FBoutonsRetirer[I].Visible := not Valeur;
  end;
end;

procedure TPanelPhysique.LabExploseClick(Sender: TObject);
begin
  if FCaseExplose.Enabled then FCaseExplose.Checked := not FCaseExplose.Checked;
end;

procedure TPanelPhysique.BoutonAjouterClick(Sender: TObject);
var
  I, R: Integer;
begin
  I := TBCButton(Sender).Tag;
  FGrilles[I].EditorMode := False;
  R := FGrilles[I].RowCount;
  FGrilles[I].RowCount := R + 1;
  FGrilles[I].Row := R;
  FGrilles[I].Col := 0;
end;

procedure TPanelPhysique.BoutonRetirerClick(Sender: TObject);
var
  I: Integer;
begin
  I := TBCButton(Sender).Tag;
  FGrilles[I].EditorMode := False;
  if (FGrilles[I].Row >= 1) and (FGrilles[I].Row < FGrilles[I].RowCount) then
    FGrilles[I].DeleteRow(FGrilles[I].Row);
end;

end.

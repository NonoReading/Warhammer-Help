unit PanelCarriereEspece;

{$mode ObjFPC}{$H+}

// Table editable des liens carriere <-> espece (DATA_CAREER_SPECIE, CONTEXT.md 2.107) : une ligne par lien, avec
// l'espece (race ou ethnie) et la carriere qu'elle peut prendre. Le XML garde les codes ; la grille montre les
// libelles. Sert a rattacher une carriere d'un livre a une espece d'un autre livre.
//
// Chaque lien s'ecrit <Entry><Specie>"code"</Specie><Career name="code">"X"</Career></Entry> ("X" = accessible hors
// tirage). Un lien deja present et conserve n'est pas reecrit : les commentaires du bloc restent en place.
// Usage : creer, Initialiser, poser (Parent + SetBounds), Configurer puis Charger(Chapitre) a l'ouverture,
// Controler puis Ecrire(Chapitre) a la validation. Chapitre = l'element DATA_CAREER_SPECIE du livre.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Grids, Dialogs, Graphics, DOM, BCButton,
  ChargeConstantes, ChargeTexte, GlobalFonts, PanelModificateurs, PanelTirage;

type
  TPanelCarriereEspece = class(TPanel)
  private
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer, FBoutonValider, FBoutonAnnuler: TBCButton;
    FOnValider, FOnAnnuler: TNotifyEvent;
    FLibEspece, FLibCarriere: TFonctionLibelleTirage;
    FEspecesLib, FEspecesCode, FCarrieresLib, FCarrieresCode: TStringList;
    function  LibEspece(const Code: String): String;
    function  LibCarriere(const Code: String): String;
    function  CodeEspeceDe(const Lib: String): String;
    function  CodeCarriereDe(const Lib: String): String;
    procedure GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure BoutonValiderClick(Sender: TObject);
    procedure BoutonAnnulerClick(Sender: TObject);
    function  GetLectureSeule: Boolean;
    procedure SetLectureSeule(Valeur: Boolean);
    function  Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
      Gauche, Largeur: Integer): TBCButton;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger. Especes et Carrieres : codes que le choix d'une ligne propose.
    procedure Configurer(ALibEspece, ALibCarriere: TFonctionLibelleTirage; Especes, Carrieres: TStrings);
    procedure Charger(Chapitre: TDOMElement);
    procedure Ecrire(Chapitre: TDOMElement);
    // Vrai si chaque ligne a une espece et une carriere, sans doublon ; sinon message.
    function  Controler: Boolean;
    procedure FinEdition;
    function  Signature(const Sep: String): String;
    procedure ActiverBoutons(Actif: Boolean);
    property  OnValider: TNotifyEvent read FOnValider write FOnValider;
    property  OnAnnuler: TNotifyEvent read FOnAnnuler write FOnAnnuler;
    property  LectureSeule: Boolean read GetLectureSeule write SetLectureSeule;
  end;

implementation

constructor TPanelCarriereEspece.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEspecesLib := TStringList.Create;
  FEspecesCode := TStringList.Create;
  FCarrieresLib := TStringList.Create;
  FCarrieresCode := TStringList.Create;
  BevelOuter := bvNone;
  Caption := '';
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alTop;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 50;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.BorderSpacing.Top := 6;
  FGrille.ColCount := 2;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing] - [goRangeSelect];
  FGrille.OnSelectEditor := @GrilleSelectEditor;
  Visible := False;
end;

destructor TPanelCarriereEspece.Destroy;
begin
  FEspecesLib.Free;
  FEspecesCode.Free;
  FCarrieresLib.Free;
  FCarrieresCode.Free;
  inherited Destroy;
end;

function TPanelCarriereEspece.Copie(Modele: TBCButton; Barre: TPanel; const Legende: String; Clic: TNotifyEvent;
  Gauche, Largeur: Integer): TBCButton;
begin
  Result := TBCButtonContour.Create(Self);
  Result.Assign(Modele);
  Result.Parent := Barre;
  Result.Caption := Legende;
  Result.OnClick := Clic;
  Result.SetBounds(Gauche, 0, Largeur, 50);
end;

procedure TPanelCarriereEspece.Initialiser(Modele: TBCButton);
begin
  FBoutonAjouter := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_512', 'Add a line'), @BoutonAjouterClick, 0, 230);
  FBoutonRetirer := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_421'), @BoutonRetirerClick, 240, 250);
  FBoutonValider := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_086'), @BoutonValiderClick, 500, 150);
  FBoutonAnnuler := Copie(Modele, FBarre, GetTexteLibelle('RULES-LAB_166'), @BoutonAnnulerClick, 660, 150);
  ActiverBoutons(False);
  MiseAJourUnContenaire(Self);
end;

// Libelle de l'espece dans la grille ; un code hors liste proposee y est ajoute.
function TPanelCarriereEspece.LibEspece(const Code: String): String;
var
  I: Integer;
begin
  I := FEspecesCode.IndexOf(Code);
  if I >= 0 then Exit(FEspecesLib[I]);
  Result := FLibEspece(Code);
  if FEspecesLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FEspecesLib.Add(Result);
  FEspecesCode.Add(Code);
end;

function TPanelCarriereEspece.LibCarriere(const Code: String): String;
var
  I: Integer;
begin
  I := FCarrieresCode.IndexOf(Code);
  if I >= 0 then Exit(FCarrieresLib[I]);
  Result := FLibCarriere(Code);
  if FCarrieresLib.IndexOf(Result) >= 0 then
    Result := Result + ' [' + Code + ']';
  FCarrieresLib.Add(Result);
  FCarrieresCode.Add(Code);
end;

function TPanelCarriereEspece.CodeEspeceDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FEspecesLib.IndexOf(Lib);
  if I >= 0 then Result := FEspecesCode[I];
end;

function TPanelCarriereEspece.CodeCarriereDe(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  I := FCarrieresLib.IndexOf(Lib);
  if I >= 0 then Result := FCarrieresCode[I];
end;

procedure TPanelCarriereEspece.Configurer(ALibEspece, ALibCarriere: TFonctionLibelleTirage; Especes, Carrieres: TStrings);
var
  I: Integer;
begin
  FLibEspece := ALibEspece;
  FLibCarriere := ALibCarriere;
  FEspecesLib.Clear;
  FEspecesCode.Clear;
  FCarrieresLib.Clear;
  FCarrieresCode.Clear;
  for I := 0 to Especes.Count - 1 do
    LibEspece(Especes[I]);
  for I := 0 to Carrieres.Count - 1 do
    LibCarriere(Carrieres[I]);
  FGrille.ColWidths[0] := 380;
  FGrille.ColWidths[1] := 380;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_042', 'Specie');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_006', 'Career');
end;

procedure TPanelCarriereEspece.Charger(Chapitre: TDOMElement);
var
  N: TDOMNode;
  Espece, Carriere: String;
  R: Integer;
begin
  FGrille.EditorMode := False;
  FGrille.RowCount := 1;
  if Chapitre = nil then Exit;
  N := Chapitre.FirstChild;
  while N <> nil do
  begin
    if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Entry') then
    begin
      Espece := ValeurXML(N.FindNode('Specie'));
      if N.FindNode('Career') <> nil then
        Carriere := TDOMElement(N.FindNode('Career')).GetAttribute('name')
      else
        Carriere := '';
      if (Espece <> '') and (Carriere <> '') then
      begin
        R := FGrille.RowCount;
        FGrille.RowCount := R + 1;
        FGrille.Cells[0, R] := LibEspece(Espece);
        FGrille.Cells[1, R] := LibCarriere(Carriere);
      end;
    end;
    N := N.NextSibling;
  end;
end;

// Les liens conserves restent tels quels (avec leurs commentaires) ; les liens retires quittent le bloc ; les
// liens nouveaux sont ajoutes a la fin.
procedure TPanelCarriereEspece.Ecrire(Chapitre: TDOMElement);
var
  Doc: TDOMDocument;
  N, Suivant: TDOMNode;
  Entree, E: TDOMElement;
  Voulus, Presents: TStringList;
  R: Integer;
  Espece, Carriere, Cle: String;
begin
  FGrille.EditorMode := False;
  Doc := Chapitre.OwnerDocument;
  Voulus := TStringList.Create;
  Presents := TStringList.Create;
  try
    for R := 1 to FGrille.RowCount - 1 do
      Voulus.Add(CodeEspeceDe(FGrille.Cells[0, R]) + #9 + CodeCarriereDe(FGrille.Cells[1, R]));
    N := Chapitre.FirstChild;
    while N <> nil do
    begin
      Suivant := N.NextSibling;
      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Entry') then
      begin
        Espece := ValeurXML(N.FindNode('Specie'));
        Carriere := '';
        if N.FindNode('Career') <> nil then
          Carriere := TDOMElement(N.FindNode('Career')).GetAttribute('name');
        Cle := Espece + #9 + Carriere;
        if (Voulus.IndexOf(Cle) < 0) and (Espece <> '') and (Carriere <> '') then
          Chapitre.RemoveChild(N)
        else
          Presents.Add(Cle);
      end;
      N := Suivant;
    end;
    for R := 0 to Voulus.Count - 1 do
    begin
      if Presents.IndexOf(Voulus[R]) >= 0 then Continue;
      Presents.Add(Voulus[R]);
      Entree := Doc.CreateElement('Entry');
      Chapitre.AppendChild(Doc.CreateTextNode(#10));
      Chapitre.AppendChild(Entree);
      E := Doc.CreateElement('Specie');
      Entree.AppendChild(Doc.CreateTextNode(#10));
      Entree.AppendChild(E);
      EcrireValeurXML(E, Copy(Voulus[R], 1, Pos(#9, Voulus[R]) - 1));
      E := Doc.CreateElement('Career');
      E.SetAttribute('name', Copy(Voulus[R], Pos(#9, Voulus[R]) + 1, MaxInt));
      Entree.AppendChild(Doc.CreateTextNode(#10));
      Entree.AppendChild(E);
      EcrireValeurXML(E, 'X');
      Entree.AppendChild(Doc.CreateTextNode(#10));
    end;
    Chapitre.AppendChild(Doc.CreateTextNode(#10));
  finally
    Voulus.Free;
    Presents.Free;
  end;
end;

function TPanelCarriereEspece.Controler: Boolean;
var
  R, K: Integer;
begin
  Result := True;
  FGrille.EditorMode := False;
  for R := 1 to FGrille.RowCount - 1 do
  begin
    if CodeEspeceDe(FGrille.Cells[0, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_584', 'Line %d: choose a species or an ethnicity.'), [R]));
      Exit(False);
    end;
    if CodeCarriereDe(FGrille.Cells[1, R]) = '' then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_585', 'Line %d: choose a career.'), [R]));
      Exit(False);
    end;
    for K := 1 to R - 1 do
      if (FGrille.Cells[0, K] = FGrille.Cells[0, R]) and (FGrille.Cells[1, K] = FGrille.Cells[1, R]) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_586', 'Line %d: this link already exists (line %d).'), [R, K]));
        Exit(False);
      end;
  end;
end;

procedure TPanelCarriereEspece.GrilleSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if aRow < 1 then Exit;
  Editor := FGrille.EditorByStyle(cbsPickList);
  if not (Editor is TCustomComboBox) then Exit;
  TCustomComboBox(Editor).Style := csDropDownList;
  if aCol = 0 then
    TCustomComboBox(Editor).Items.Assign(FEspecesLib)
  else
    TCustomComboBox(Editor).Items.Assign(FCarrieresLib);
end;

procedure TPanelCarriereEspece.BoutonAjouterClick(Sender: TObject);
var
  R: Integer;
begin
  FGrille.EditorMode := False;
  R := FGrille.RowCount;
  FGrille.RowCount := R + 1;
  // une nouvelle ligne reprend l'espece de la precedente : on ajoute le plus souvent a la meme espece
  if R > 1 then FGrille.Cells[0, R] := FGrille.Cells[0, R - 1];
  FGrille.Row := R;
  FGrille.Col := 1;
end;

procedure TPanelCarriereEspece.BoutonRetirerClick(Sender: TObject);
begin
  FGrille.EditorMode := False;
  if (FGrille.Row >= 1) and (FGrille.Row < FGrille.RowCount) then
    FGrille.DeleteRow(FGrille.Row);
end;

procedure TPanelCarriereEspece.ActiverBoutons(Actif: Boolean);
begin
  FBoutonValider.Enabled := Actif;
  FBoutonAnnuler.Enabled := Actif;
end;

procedure TPanelCarriereEspece.BoutonValiderClick(Sender: TObject);
begin
  if Assigned(FOnValider) then FOnValider(Self);
end;

procedure TPanelCarriereEspece.BoutonAnnulerClick(Sender: TObject);
begin
  if Assigned(FOnAnnuler) then FOnAnnuler(Self);
end;

function TPanelCarriereEspece.GetLectureSeule: Boolean;
begin
  Result := not FBarre.Visible;
end;

procedure TPanelCarriereEspece.SetLectureSeule(Valeur: Boolean);
begin
  if Valeur then
    FGrille.Options := FGrille.Options - [goEditing]
  else
    FGrille.Options := FGrille.Options + [goEditing];
  FBarre.Visible := not Valeur;
end;

procedure TPanelCarriereEspece.FinEdition;
begin
  FGrille.EditorMode := False;
end;

function TPanelCarriereEspece.Signature(const Sep: String): String;
var
  L, C: Integer;
begin
  Result := '';
  for L := 0 to FGrille.RowCount - 1 do
    for C := 0 to FGrille.ColCount - 1 do
      Result := Result + Sep + FGrille.Cells[C, L];
end;

end.

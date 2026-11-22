unit PanelReserve;

{$mode ObjFPC}{$H+}

// Registre de points d'un personnage (Destin, Resilience, Resolution) : registre de lignes Montant | Commentaire, a la
// maniere de l'historique de Corruption. Valeur courante = maximum (Destin / Resilience, fourni par
// l'appelant) + somme des montants ; elle PEUT depasser le maximum (sorts et miracles qui donnent de la Fortune
// "au-dela de la limite naturelle", Rulebook p.170), l'affichage passe alors en rouge. Le panneau ne connait
// ni le personnage ni le XML : l'appelant le remplit (AjouteLigne) et le relit (Compte, Montant, Libelle).
//
// Usage : creer, Initialiser (une fois), puis Vider / AjouteLigne / SetMaximum au chargement d'une fiche.

interface

uses
  BCLabelContour, Classes, SysUtils, Graphics, Controls, StdCtrls, ExtCtrls, Grids, Dialogs, BCButton, ChargeTexte, GlobalFonts;

type
  TPanelReserve = class(TPanel)
  private
    FEtiquette: TLabel;
    FGrille: TStringGrid;
    FBarre: TPanel;
    FBoutonAjouter, FBoutonRetirer: TBCButton;
    FCourant: TLabel;
    FMaximum: Integer;
    FOnChange: TNotifyEvent;
    FCumul: Boolean;
    procedure BoutonAjouterClick(Sender: TObject);
    procedure BoutonRetirerClick(Sender: TObject);
    procedure GrilleEditingDone(Sender: TObject);
    procedure Changement;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Initialiser(Modele: TBCButton; const Titre: String);
    procedure SetTitre(const Titre: String);
    procedure Placer(Largeur: Integer);
    procedure Vider;
    procedure AjouteLigne(Montant: Integer; const Libelle: String);
    procedure SetMaximum(Valeur: Integer);
    function  Compte: Integer;
    function  Montant(Ind: Integer): Integer;
    function  Libelle(Ind: Integer): String;
    function  Courant: Integer;
    property  Maximum: Integer read FMaximum;
    property  OnChange: TNotifyEvent read FOnChange write FOnChange;
    // True (defaut) : valeur courante = maximum + lignes (Resolution). False : les lignes sont appliquees AILLEURS
    // par l'appelant (Destin, Resilience) ; le panneau montre le total fourni par SetMaximum.
    property  Cumul: Boolean read FCumul write FCumul;
    function  Somme: Integer;
  end;

implementation

constructor TPanelReserve.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  FCumul := True;
  FEtiquette := TLabelContour.Create(Self);
  FEtiquette.Parent := Self;
  FEtiquette.Align := alTop;
  FBarre := TPanel.Create(Self);
  FBarre.Parent := Self;
  FBarre.Align := alBottom;
  FBarre.BevelOuter := bvNone;
  FBarre.Caption := '';
  FBarre.Height := 84;
  FGrille := TStringGrid.Create(Self);
  FGrille.Parent := Self;
  CouleurSelectionGrille(FGrille);
  FGrille.Align := alClient;
  FGrille.ColCount := 2;
  FGrille.RowCount := 1;
  FGrille.FixedRows := 1;
  FGrille.FixedCols := 0;
  FGrille.Options := FGrille.Options + [goEditing, goRowSelect] - [goRangeSelect];
  FGrille.OnEditingDone := @GrilleEditingDone;
end;

procedure TPanelReserve.SetTitre(const Titre: String);
begin
  FEtiquette.Caption := Titre;
end;

procedure TPanelReserve.Initialiser(Modele: TBCButton; const Titre: String);
begin
  FEtiquette.Caption := Titre;
  FGrille.Cells[0, 0] := GetTexteLibelle('RULES-LAB_162');
  FGrille.Cells[1, 0] := GetTexteLibelle('RULES-LAB_163');
  FBoutonAjouter := TBCButtonContour.Create(Self);
  FBoutonAjouter.Assign(Modele);
  FBoutonAjouter.Parent := FBarre;
  FBoutonAjouter.Caption := '+' + GetTexteLibelle('RULES-LAB_164');
  FBoutonAjouter.OnClick := @BoutonAjouterClick;
  FBoutonRetirer := TBCButtonContour.Create(Self);
  FBoutonRetirer.Assign(Modele);
  FBoutonRetirer.Parent := FBarre;
  FBoutonRetirer.Caption := '-' + GetTexteLibelle('RULES-LAB_165');
  FBoutonRetirer.OnClick := @BoutonRetirerClick;
  FCourant := TLabel.Create(Self);
  FCourant.Parent := FBarre;
  MiseAJourUnContenaire(Self);
  Placer(400);
  Changement;
end;

procedure TPanelReserve.Placer(Largeur: Integer);
var
  NbBoutons, L: Integer;
begin
  FGrille.ColWidths[0] := 90;
  FGrille.ColWidths[1] := Largeur - 90 - 25;
  FBarre.Height := 84;
  FCourant.SetBounds(0, 4, Largeur, 24);
  NbBoutons := 2;
  L := (Largeur - 5 * (NbBoutons - 1)) div NbBoutons;
  FBoutonAjouter.SetBounds(0, 32, L, 50);
  FBoutonRetirer.SetBounds(L + 5, 32, L, 50);
end;

procedure TPanelReserve.Vider;
begin
  FGrille.RowCount := 1;
  Changement;
end;

procedure TPanelReserve.AjouteLigne(Montant: Integer; const Libelle: String);
begin
  FGrille.RowCount := FGrille.RowCount + 1;
  FGrille.Cells[0, FGrille.RowCount - 1] := IntToStr(Montant);
  FGrille.Cells[1, FGrille.RowCount - 1] := Libelle;
  Changement;
end;

procedure TPanelReserve.SetMaximum(Valeur: Integer);
begin
  FMaximum := Valeur;
  Changement;
end;

function TPanelReserve.Compte: Integer;
begin
  Result := FGrille.RowCount - 1;
end;

function TPanelReserve.Montant(Ind: Integer): Integer;
begin
  Result := StrToIntDef(Trim(FGrille.Cells[0, Ind + 1]), 0);
end;

function TPanelReserve.Libelle(Ind: Integer): String;
begin
  Result := FGrille.Cells[1, Ind + 1];
end;

function TPanelReserve.Somme: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Compte - 1 do
    Result := Result + Montant(I);
end;

function TPanelReserve.Courant: Integer;
begin
  if FCumul then Result := FMaximum + Somme
  else Result := FMaximum;
end;

// Affichage "Actuelle / Maximum" ; rouge si la valeur depasse le maximum (permis) ou passe sous zero.
procedure TPanelReserve.Changement;
begin
  if FCourant <> nil then
  begin
    if FCumul then
      FCourant.Caption := GetTexteLibelle('RULES-LAB_655') + ' : ' + IntToStr(Courant)
                          + ' / ' + IntToStr(FMaximum)
    else
      FCourant.Caption := GetTexteLibelle('RULES-LAB_660') + ' : ' + IntToStr(FMaximum);
    if (FCumul and (Courant > FMaximum)) or (Courant < 0) then
      FCourant.Font.Color := clRed
    else
      FCourant.Font.Color := clDefault;
  end;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPanelReserve.BoutonAjouterClick(Sender: TObject);
begin
  FGrille.RowCount := FGrille.RowCount + 1;
  FGrille.Cells[0, FGrille.RowCount - 1] := '-1';
  FGrille.Row := FGrille.RowCount - 1;
  FGrille.Col := 0;
  Changement;
end;

procedure TPanelReserve.BoutonRetirerClick(Sender: TObject);
var
  I: Integer;
begin
  if FGrille.Row > 0 then
    if MessageDlg(GetTexteLibelle('RULES-MESS_053'), mtConfirmation, mbYesNo, 0) = mrYes then
    begin
      for I := FGrille.Row to FGrille.RowCount - 2 do
        FGrille.Rows[I].Assign(FGrille.Rows[I + 1]);
      FGrille.RowCount := FGrille.RowCount - 1;
      Changement;
    end;
end;

procedure TPanelReserve.GrilleEditingDone(Sender: TObject);
begin
  Changement;
end;

end.

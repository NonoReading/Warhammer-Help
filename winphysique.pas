unit WinPhysique;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, StdCtrls, Spin, Dialogs, MessageTest, BCButton,
  GlobalFonts, ChargeConstantes, ChargeRacePhysique, ChargeTexte, Graphics, BCLabelContour;

type

  { TWinPhysique }

  TWinPhysique = class(TForm)
    ButtonAnnuler:    TBCButton;
    ButtonTirer:      TBCButton;
    ButtonValider:    TBCButton;
    EditCheveux:      TEdit;
    EditYeux:         TEdit;
    LabelAge:         TLabelContour;
    LabelCheveux:     TLabelContour;
    LabelTaille:      TLabelContour;
    ComboBoxUnite:    TComboBox;
    LabelYeux:        TLabelContour;
    SpinEditAge:      TSpinEdit;
    SpinEditTaille:   TSpinEdit;
    procedure FormCreate({%H-}Sender: TObject);
    procedure ButtonTirerClick({%H-}Sender: TObject);
    procedure ButtonValiderClick({%H-}Sender: TObject);
    procedure ButtonAnnulerClick({%H-}Sender: TObject);
    procedure ComboBoxUniteChange({%H-}Sender: TObject);
    procedure FormPaint({%H-}Sender: TObject);
  private
    FUnite: String;   // unite courante de SpinEditTaille : CM ou INCH
    // Details V2 (Core V2, tables 2-6 a 2-17), crees dans le code seulement en V2
    ComboSexe:        TComboBox;
    SpinPoids:        TSpinEdit;
    EditFratrie:      TEdit;
    EditSigne:        TEdit;
    EditNaissance:    TEdit;
    EditAstre:        TEdit;
    EditJets:         array[1..9] of TEdit;   // jet du de de chaque ligne (tire ou saisi)
    ButtonUpdate:     TBCButton;
    function NouveauBouton(Legende: String; Gauche, Haut, Largeur, Hauteur: Integer): TBCButton;
    procedure CreeChampsV2;
    procedure CreeSexeV1;
    procedure CreeSexeSeul;
    procedure NouveauDe(Haut, Champ: Integer);
    procedure RelanceChamp(Sender: TObject);
    function RelanceUnChamp(Champ: Integer): Boolean;
    procedure Applique(Champ: Integer; Resultat: String);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure JetKeyPress(Sender: TObject; var Key: Char);
    function NouveauLabelV2(Libelle: String; Haut: Integer): TLabelContour;
    procedure Tirer;
  public
  end;

var
  // Entree : ethnie du personnage et valeurs actuelles (0 / vide = pas encore definies,
  // la fenetre tire alors d'elle-meme). Sortie : valeurs validees, PhysiqueValide vrai
  // seulement si le joueur a clique sur Valider. Taille dans PhysiqueUnite (CM ou INCH).
  PhysiqueCodeRace: String;
  PhysiqueAge:      Integer;
  PhysiqueTaille:   Integer;
  PhysiqueUnite:    String;   // CM ou INCH ; taille a 0 : unite par defaut de l'interface (INI)
  PhysiqueYeux:     String;
  PhysiqueCheveux:  String;
  PhysiqueValide:   Boolean;
  // V2 : PhysiqueV2 vrai = la fenetre ajoute sexe, poids, fratrie, signe distinctif, naissance et signe astral.
  PhysiqueV2:       Boolean;
  // WFRP1 : age fixe (deja tire a la creation), taille selon le sexe, ni yeux ni cheveux
  PhysiqueV1:       Boolean;
  // V4 / V5 : vrai = la fenetre ajoute seulement la ligne Sexe (choix du nom de niveau de carriere)
  PhysiqueSexeSeul: Boolean;
  PhysiqueFemme:    Boolean;
  PhysiquePoids:    Integer;
  PhysiqueFratrie:  String;
  PhysiqueSigne:    String;
  PhysiqueNaissance: String;
  PhysiqueAstre:    String;

implementation

{$R *.lfm}

procedure TWinPhysique.FormCreate(Sender: TObject);
  var
    I: Integer;
  begin
    MiseEnFormeDesChamp(self);
    Caption                := GetTexteLibelle('RULES-LAB_266');
    LabelAge.Caption       := GetTexteLibelle('RULES-LAB_745');
    LabelTaille.Caption    := GetTexteLibelle('RULES-LAB_264');
    LabelYeux.Caption      := GetTexteLibelle('RULES-LAB_746');
    LabelCheveux.Caption   := GetTexteLibelle('RULES-LAB_747');
    ButtonTirer.Caption    := GetTexteLibelle('RULES-LAB_263');
    ButtonValider.Caption  := GetTexteLibelle('RULES-LAB_086');
    ButtonAnnuler.Caption  := GetTexteLibelle('RULES-LAB_166');
    PhysiqueValide := False;
    SpinEditAge.Value    := PhysiqueAge;
    // Unite de la fiche si une taille existe deja, sinon celle de l'interface (INI)
    if PhysiqueTaille = 0 then
      FUnite := UniteTaille
    else if PhysiqueUnite = '' then
      FUnite := ConstUniteInch
    else
      FUnite := PhysiqueUnite;
    if FUnite = ConstUniteCm then
      ComboBoxUnite.ItemIndex := 0
    else
      ComboBoxUnite.ItemIndex := 1;
    SpinEditTaille.Value := PhysiqueTaille;
    EditYeux.Text        := PhysiqueYeux;
    EditCheveux.Text     := PhysiqueCheveux;
    // Un bouton de relance par ligne : il ne retire que cette ligne (Tag = numero du champ)
    if not PhysiqueV1 then
      NouveauDe(SpinEditAge.Top, 1);
    NouveauDe(SpinEditTaille.Top, 2);
    if PhysiqueV1 then
      CreeSexeV1
    else
      begin
        NouveauDe(EditYeux.Top, 3);
        NouveauDe(EditCheveux.Top, 4);
      end;
    if PhysiqueV2 then
      CreeChampsV2
    else if PhysiqueSexeSeul then
      CreeSexeSeul;
    // UPDATE : applique les jets saisis, sous le Roll (meme colonne que les champs de jet)
    ButtonUpdate         := NouveauBouton(GetTexteLibelle('RULES-LAB_748'), 440, ButtonTirer.Top, 126, 31);
    ButtonUpdate.OnClick := @ButtonUpdateClick;
    // Colonne des libelles elargie : les champs et les boutons a droite de 180 se decalent de 60
    for I := 0 to ControlCount - 1 do
      if Controls[I] is TLabelContour then
        Controls[I].Width := 210
      else if Controls[I].Left >= 180 then
        Controls[I].Left := Controls[I].Left + 60;
    ClientWidth := ClientWidth + 180;
    // Premiere ouverture pour ce personnage : on propose directement un tirage
    if (PhysiqueAge = 0) and (PhysiqueTaille = 0) then
      Tirer
    else if PhysiqueV1 and (PhysiqueTaille = 0) then
      Tirer;
    MiseEnFormeDesChamp(self);
  end;

// Bouton au style de Roll (rouge et or) : les TButton standards sont restyles de travers par MiseEnFormeDesChamp.
function TWinPhysique.NouveauBouton(Legende: String; Gauche, Haut, Largeur, Hauteur: Integer): TBCButton;
  begin
    Result         := TBCButton.Create(Self);
    Result.Parent  := Self;
    Result.Assign(ButtonTirer);
    Result.SetBounds(Gauche, Haut, Largeur, Hauteur);
    Result.Caption := Legende;
    Result.Tag     := 0;
  end;

// Bouton de relance a droite d'une ligne, puis le champ du jet du de (avant le decalage de FormCreate :
// Left 450 -> 510 et 496 -> 556).
procedure TWinPhysique.NouveauDe(Haut, Champ: Integer);
  var
    Bouton: TBCButton;
  begin
    Bouton         := NouveauBouton('R', 450, Haut, 40, 28);
    Bouton.Hint    := GetTexteLibelle('RULES-LAB_263');
    Bouton.ShowHint := True;
    Bouton.Tag     := Champ;
    Bouton.OnClick := @RelanceChamp;
    EditJets[Champ]        := TEdit.Create(Self);
    EditJets[Champ].Parent := Self;
    EditJets[Champ].SetBounds(496, Haut, 70, 28);
    EditJets[Champ].OnKeyPress := @JetKeyPress;
    EditJets[Champ].Hint   := GetTexteLibelle('RULES-LAB_749');
    EditJets[Champ].ShowHint := True;
  end;

// Met le resultat d'un champ dans sa ligne.
procedure TWinPhysique.Applique(Champ: Integer; Resultat: String);
  begin
    case Champ of
      1: SpinEditAge.Value    := StrToIntDef(Resultat, SpinEditAge.Value);
      2: SpinEditTaille.Value := ConvertitTaille(StrToIntDef(Resultat, 0), ConstUniteInch, FUnite);
      3: EditYeux.Text        := Resultat;
      4: EditCheveux.Text     := Resultat;
      5: SpinPoids.Value      := StrToIntDef(Resultat, SpinPoids.Value);
      6: EditFratrie.Text     := Resultat;
      7: EditSigne.Text       := Resultat;
      8: EditNaissance.Text   := Resultat;
      9: EditAstre.Text       := Resultat;
    end;
  end;

const
  NomChamp: array[1..9] of String = ('AGE', 'TAILLE', 'YEUX', 'CHEVEUX', 'POIDS', 'FRATRIE', 'SIGNE', 'NAISSANCE', 'ASTRE');

// Relance UNE ligne : tire un nouveau jet et l'affiche dans son champ ; les autres lignes ne bougent pas.
function TWinPhysique.RelanceUnChamp(Champ: Integer): Boolean;
  var
    Jets, Resultat: String;
  begin
    Jets     := '';
    Resultat := ChampPhysique(PhysiqueCodeRace, NomChamp[Champ], (PhysiqueV2 or PhysiqueV1) and (ComboSexe.ItemIndex = 0), Jets);
    Result   := Resultat <> '';
    if not Result then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_265'));
        Exit;
      end;
    Applique(Champ, Resultat);
    EditJets[Champ].Text := Jets;
  end;

procedure TWinPhysique.RelanceChamp(Sender: TObject);
  begin
    RelanceUnChamp((Sender as TBCButton).Tag);
  end;

// Un jet ne contient que des chiffres et le separateur / (plusieurs des : province/localite).
procedure TWinPhysique.JetKeyPress(Sender: TObject; var Key: Char);
  begin
    if not (Key in ['0'..'9', '/', #8, #13]) then
      Key := #0;
  end;

// UPDATE : recalcule chaque ligne dont un jet est saisi (le vrai de du joueur) et complete le champ du jet.
// Les lignes sans jet gardent leur valeur.
procedure TWinPhysique.ButtonUpdateClick(Sender: TObject);
  var
    Champ:          Integer;
    Jets, Resultat: String;
  begin
    for Champ := 1 to 9 do
      if Assigned(EditJets[Champ]) and (Trim(EditJets[Champ].Text) <> '') then
        begin
          Jets     := Trim(EditJets[Champ].Text);
          Resultat := ChampPhysique(PhysiqueCodeRace, NomChamp[Champ], (PhysiqueV2 or PhysiqueV1) and (ComboSexe.ItemIndex = 0), Jets);
          if Resultat <> '' then
            begin
              Applique(Champ, Resultat);
              EditJets[Champ].Text := Jets;
            end;
        end;
  end;

function TWinPhysique.NouveauLabelV2(Libelle: String; Haut: Integer): TLabelContour;
  begin
    Result         := TLabelContour.Create(Self);
    Result.Parent  := Self;
    Result.Left    := 24;
    Result.Top     := Haut + 4;
    Result.Width   := 150;
    Result.Caption := Libelle;
  end;

// Champs V2 sous les champs communs ; les trois boutons descendent d'autant.
procedure TWinPhysique.CreeChampsV2;
  const
    Decalage = 276;   // hauteur ajoutee : six lignes de 46 pixels
  var
    Haut: Integer;
  begin
    Haut := 196;
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_742'), Haut);
    ComboSexe        := TComboBox.Create(Self);
    ComboSexe.Parent := Self;
    ComboSexe.SetBounds(190, Haut, 150, 28);
    ComboSexe.Style  := csDropDownList;
    ComboSexe.Items.Add(GetTexteLibelle('RULES-LAB_743'));
    ComboSexe.Items.Add(GetTexteLibelle('RULES-LAB_744'));
    if PhysiqueFemme then
      ComboSexe.ItemIndex := 0
    else
      ComboSexe.ItemIndex := 1;
    Inc(Haut, 46);
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_738'), Haut);
    SpinPoids        := TSpinEdit.Create(Self);
    SpinPoids.Parent := Self;
    SpinPoids.SetBounds(190, Haut, 80, 28);
    SpinPoids.MaxValue := 999;
    SpinPoids.Value  := PhysiquePoids;
    NouveauDe(Haut, 5);
    Inc(Haut, 46);
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_739'), Haut);
    EditFratrie        := TEdit.Create(Self);
    EditFratrie.Parent := Self;
    EditFratrie.SetBounds(190, Haut, 80, 28);
    EditFratrie.Text   := PhysiqueFratrie;
    NouveauDe(Haut, 6);
    Inc(Haut, 46);
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_740'), Haut);
    EditSigne        := TEdit.Create(Self);
    EditSigne.Parent := Self;
    EditSigne.SetBounds(190, Haut, 250, 28);
    EditSigne.Text   := PhysiqueSigne;
    NouveauDe(Haut, 7);
    Inc(Haut, 46);
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_741'), Haut);
    EditNaissance        := TEdit.Create(Self);
    EditNaissance.Parent := Self;
    EditNaissance.SetBounds(190, Haut, 250, 28);
    EditNaissance.Text   := PhysiqueNaissance;
    NouveauDe(Haut, 8);
    Inc(Haut, 46);
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_272'), Haut);
    EditAstre        := TEdit.Create(Self);
    EditAstre.Parent := Self;
    EditAstre.SetBounds(190, Haut, 250, 28);
    EditAstre.Text   := PhysiqueAstre;
    NouveauDe(Haut, 9);
    ButtonTirer.Top   := ButtonTirer.Top + Decalage;
    ButtonValider.Top := ButtonValider.Top + Decalage;
    ButtonAnnuler.Top := ButtonAnnuler.Top + Decalage;
    ClientHeight      := ClientHeight + Decalage;
  end;

// V4 / V5 : une seule ligne ajoutee sous les cheveux, les trois boutons descendent d'autant.
procedure TWinPhysique.CreeSexeSeul;
  const
    Decalage = 46;
    Haut     = 196;
  begin
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_742'), Haut);
    ComboSexe        := TComboBox.Create(Self);
    ComboSexe.Parent := Self;
    ComboSexe.SetBounds(190, Haut, 150, 28);
    ComboSexe.Style  := csDropDownList;
    ComboSexe.Items.Add(GetTexteLibelle('RULES-LAB_743'));
    ComboSexe.Items.Add(GetTexteLibelle('RULES-LAB_744'));
    if PhysiqueFemme then
      ComboSexe.ItemIndex := 0
    else
      ComboSexe.ItemIndex := 1;
    ButtonTirer.Top   := ButtonTirer.Top + Decalage;
    ButtonValider.Top := ButtonValider.Top + Decalage;
    ButtonAnnuler.Top := ButtonAnnuler.Top + Decalage;
    ClientHeight      := ClientHeight + Decalage;
  end;

// WFRP1 : le sexe prend la place des yeux et des cheveux (le livre n'a pas de tables de couleurs) ;
// l'age est celui de l'etape des competences, il n'est plus modifiable ici.
procedure TWinPhysique.CreeSexeV1;
  begin
    LabelYeux.Visible    := False;
    EditYeux.Visible     := False;
    LabelCheveux.Visible := False;
    EditCheveux.Visible  := False;
    SpinEditAge.Enabled  := False;
    NouveauLabelV2(GetTexteLibelle('RULES-LAB_742'), EditYeux.Top);
    ComboSexe        := TComboBox.Create(Self);
    ComboSexe.Parent := Self;
    ComboSexe.SetBounds(190, EditYeux.Top, 150, 28);
    ComboSexe.Style  := csDropDownList;
    ComboSexe.Items.Add(GetTexteLibelle('RULES-LAB_743'));
    ComboSexe.Items.Add(GetTexteLibelle('RULES-LAB_744'));
    if PhysiqueFemme then
      ComboSexe.ItemIndex := 0
    else
      ComboSexe.ItemIndex := 1;
  end;

// Roll : retire toutes les lignes (chacune avec son jet, affiche et corrigeable).
procedure TWinPhysique.Tirer;
  var
    Champ, Premier, Dernier: Integer;
  begin
    Premier := 1;
    if PhysiqueV2 then
      Dernier := 9
    else
      Dernier := 4;
    if PhysiqueV1 then
      begin
        Premier := 2;
        Dernier := 2;
      end;
    for Champ := Premier to Dernier do
      if not RelanceUnChamp(Champ) then
        Exit;
  end;

procedure TWinPhysique.ButtonTirerClick(Sender: TObject);
  begin
    Tirer;
  end;

procedure TWinPhysique.ComboBoxUniteChange(Sender: TObject);
  var
    Nouvelle: String;
  begin
    if ComboBoxUnite.ItemIndex = 0 then
      Nouvelle := ConstUniteCm
    else
      Nouvelle := ConstUniteInch;
    SpinEditTaille.Value := ConvertitTaille(SpinEditTaille.Value, FUnite, Nouvelle);
    FUnite := Nouvelle;
  end;

procedure TWinPhysique.ButtonValiderClick(Sender: TObject);
  begin
    PhysiqueAge     := SpinEditAge.Value;
    PhysiqueTaille  := SpinEditTaille.Value;
    PhysiqueUnite   := FUnite;
    PhysiqueYeux    := EditYeux.Text;
    PhysiqueCheveux := EditCheveux.Text;
    if PhysiqueV1 or PhysiqueSexeSeul then
      PhysiqueFemme := ComboSexe.ItemIndex = 0;
    if PhysiqueV2 then
      begin
        PhysiqueFemme     := ComboSexe.ItemIndex = 0;
        PhysiquePoids     := SpinPoids.Value;
        PhysiqueFratrie   := EditFratrie.Text;
        PhysiqueSigne     := EditSigne.Text;
        PhysiqueNaissance := EditNaissance.Text;
        PhysiqueAstre     := EditAstre.Text;
      end;
    PhysiqueValide  := True;
    Close;
  end;

procedure TWinPhysique.ButtonAnnulerClick(Sender: TObject);
  begin
    PhysiqueValide := False;
    Close;
  end;

procedure TWinPhysique.FormPaint(Sender: TObject);
begin
  Canvas.Pen.Color   := ClWhite;
  Canvas.Pen.Width   := 3;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(2, 2, ClientWidth - 2, ClientHeight - 2);
end;

end.

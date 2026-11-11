unit WinJetPathologie;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Spin, Dialogs, BCButton,
  GlobalFonts, Graphics, BCLabelContour;

type

  { TWinJetPathologie }

  TWinJetPathologie = class(TForm)
    ButtonAnnuler: TBCButton;
    ButtonLancer:  TBCButton;
    ButtonValider: TBCButton;
    LabelInfo:     TLabelContour;
    SpinEditJet:   TSpinEdit;
    procedure FormCreate({%H-}Sender: TObject);
    procedure ButtonLancerClick({%H-}Sender: TObject);
    procedure ButtonValiderClick({%H-}Sender: TObject);
    procedure ButtonAnnulerClick({%H-}Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
  public
  end;

var
  WinJetPathologieForm: TWinJetPathologie;
  // Entree/sortie de la fenetre - meme principe que SelectWinJet/ChoixWinJetValeur
  // (WinLanceDes) mais generique (face de de variable, pas de resolution de Talent).
  // JetPathologieFace: face du de a proposer (ex. 10 pour 1d10). JetPathologieLibelle: texte
  // affiche (nom de l'Affliction + attribut vise). JetPathologieResultat: valeur validee par
  // Nono en sortie, 0 = annule (Ajout du 27/09/2026, a la demande de Nono).
  JetPathologieFace:      Integer;
  JetPathologieLibelle:   String;
  JetPathologieResultat:  Integer;
  // Nombre de des (1 par defaut) : JetPathologieFace est alors la somme maximale (ex. 20 pour 2d10).
  // Remis a 1 par l'appelant (JetMutationValide) apres usage.
  JetPathologieNbDes:     Integer = 1;

// Mutation a <ModifyCaracAleatoire> (Tome of Corruption, "+Nd10 %") : montre le jet a valider ou
// corriger et renvoie sa valeur signee. True si la mutation n'a pas de jet (Valeur = 0) ou si le
// jet est valide ; False si Nono annule.
// Plusieurs <ModifyCaracAleatoire> : un jet par attribut, montres l'un apres l'autre ; ValeursEffets
// recoit alors "code=valeur;code=valeur" (vide s'il n'y a qu'un jet, range dans Valeur).
function JetMutationValide(CodeMutation, LibelleMutation: String; out Valeur: Integer; out ValeursEffets: String): Boolean;

implementation

{$R *.lfm}

uses ChargePersonnage, ChargeAttribut, ChargeTexte;

function JetMutationValide(CodeMutation, LibelleMutation: String; out Valeur: Integer; out ValeursEffets: String): Boolean;
  var
    Faces:     TArrayEntiersAleatoires;
    Attributs: TArrayCodesAleatoires;
    Face, Signe, Ind, Jet: Integer;
  begin
    Valeur         := 0;
    ValeursEffets  := '';
    Result         := True;
    PersonnageMutationEffetsAleatoires(CodeMutation, Faces, Attributs);
    for Ind := 0 to High(Faces) do
      begin
        Face  := Abs(Faces[Ind]);
        Signe := 1;
        if Faces[Ind] < 0 then Signe := -1;
        if Face <= 0 then continue;
        JetPathologieNbDes    := Face div 10;
        JetPathologieFace     := Face;
        JetPathologieLibelle  := Format(GetTexteLibelle('RULES-MESS_077'),
                                   [JetPathologieNbDes, LibelleMutation + ' (' + ChercheAttribut(Attributs[Ind]).Libelle + ')']);
        WinJetPathologieForm          := TWinJetPathologie.Create(Application);
        WinJetPathologieForm.Position := poOwnerFormCenter;
        WinJetPathologieForm.ShowModal;
        JetPathologieNbDes := 1;
        if JetPathologieResultat = 0 then
          begin
            Valeur        := 0;
            ValeursEffets := '';
            Result        := False;
            Exit;
          end;
        Jet := Signe * JetPathologieResultat;
        if Ind = 0 then
          Valeur := Jet;
        if ValeursEffets <> '' then
          ValeursEffets := ValeursEffets + ';';
        ValeursEffets := ValeursEffets + Attributs[Ind] + '=' + IntToStr(Jet);
      end;
    // Un seul jet : il reste dans Valeur, comme avant.
    if Length(Faces) <= 1 then
      ValeursEffets := '';
  end;

function LanceDes(): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 1 to JetPathologieNbDes do
      Result += Random(JetPathologieFace div JetPathologieNbDes) + 1;
  end;

procedure TWinJetPathologie.FormCreate(Sender: TObject);
  begin
    MiseEnFormeDesChamp(self);
    JetPathologieResultat := 0;
    SpinEditJet.MinValue  := JetPathologieNbDes;
    SpinEditJet.MaxValue  := JetPathologieFace;
    SpinEditJet.Value     := LanceDes();
    LabelInfo.Caption     := JetPathologieLibelle;
    MiseEnFormeDesChamp(self);
  end;

procedure TWinJetPathologie.ButtonLancerClick(Sender: TObject);
  begin
    SpinEditJet.Value := LanceDes();
  end;

procedure TWinJetPathologie.ButtonValiderClick(Sender: TObject);
  begin
    JetPathologieResultat := SpinEditJet.Value;
    Close;
  end;

procedure TWinJetPathologie.ButtonAnnulerClick(Sender: TObject);
  begin
    JetPathologieResultat := 0;
    Close;
  end;

procedure TWinJetPathologie.FormPaint(Sender: TObject);
begin
  Canvas.Pen.Color   := ClWhite;
  Canvas.Pen.Width   := 3;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(2, 2, ClientWidth - 2, ClientHeight - 2);
end;

end.

unit PanelImageLivre;

{$mode ObjFPC}{$H+}

// Apercu de l'image d'une ethnie ou d'une carriere dans WinLivre, avec un bouton « Remplacer l'image... ».
//
// Les images ne sont pas dans le livre : elles sont communes a tous les livres d'une version, dans
// \DATABASE\<version>\PICTURES\SPECIE\<code><indice>.PNG (ethnie, indice 1) et \CLASS\<code>.PNG (carriere),
// avec repli sur PICTURES_DEFAULT pour la lecture (CheminImage). Remplacer ecrit toujours dans PICTURES, en PNG,
// et retire la version transparente (_TRANS) pour que le programme la refabrique a partir de la nouvelle image.
// Usage : creer, Initialiser, poser le Parent, puis Afficher(...) ; Masquer pour la cacher.

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Dialogs, Graphics, ChargeConstantes, ChargeTexte;

type
  TPanelImageLivre = class(TPanel)
  private
    FImage: TImage;
    FBouton: TButton;
    FAucune: TLabel;
    FDossier, FNom: String;  // dossier relatif (\DATABASE\...\) et nom sans extension de l'image visee
    procedure BoutonClick(Sender: TObject);
    procedure Recharger;
  public
    constructor Create(AOwner: TComponent); override;
    // Genre : 'E' = ethnie (<code>1.PNG), 'C' = carriere (<code>.PNG). Modifiable : bouton actif.
    procedure Afficher(const Genre, Code: String; Modifiable: Boolean; ALeft, ATop: Integer);
    procedure Masquer;
  end;

implementation

constructor TPanelImageLivre.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  Width := 190;
  Height := 260;
  FImage := TImage.Create(Self);
  FImage.Parent := Self;
  FImage.SetBounds(0, 0, 190, 220);
  FImage.Proportional := True;
  FImage.Center := True;
  FAucune := TLabel.Create(Self);
  FAucune.Parent := Self;
  FAucune.SetBounds(0, 100, 190, 20);
  FAucune.Alignment := taCenter;
  FAucune.AutoSize := False;
  FBouton := TButton.Create(Self);
  FBouton.Parent := Self;
  FBouton.SetBounds(0, 228, 190, 28);
  FBouton.OnClick := @BoutonClick;
  Visible := False;
end;

procedure TPanelImageLivre.Recharger;
var
  Chemin: String;
begin
  FImage.Picture.Clear;
  Chemin := CheminImage(GetCurrentDir + FDossier + FNom + '.PNG');
  FAucune.Visible := not FileExists(Chemin);
  if FAucune.Visible then Exit;
  try
    FImage.Picture.LoadFromFile(Chemin);
  except
    FAucune.Visible := True;
  end;
end;

procedure TPanelImageLivre.Afficher(const Genre, Code: String; Modifiable: Boolean; ALeft, ATop: Integer);
begin
  if Code = '' then begin Masquer; Exit; end;
  if Genre = 'E' then
  begin
    FDossier := ConstCheminImageRace;
    FNom := Code + '1';
  end
  else
  begin
    FDossier := ConstCheminImageMetier;
    FNom := Code;
  end;
  // le chemin des constantes peut encore porter la place du livre : l'image ne depend pas du livre
  FDossier := StringReplace(FDossier, ConstLivre, '', [rfReplaceAll]);
  FAucune.Caption := GetTexteLibelle('RULES-LAB_990');
  FBouton.Caption := GetTexteLibelle('RULES-LAB_989');
  FBouton.Enabled := Modifiable;
  Recharger;
  SetBounds(ALeft, ATop, Width, Height);
  Visible := True;
  BringToFront;
end;

procedure TPanelImageLivre.Masquer;
begin
  Visible := False;
end;

procedure TPanelImageLivre.BoutonClick(Sender: TObject);
var
  Dialogue: TOpenDialog;
  Source: TPicture;
  Cible, Trans: String;
begin
  Dialogue := TOpenDialog.Create(Self);
  try
    Dialogue.Filter := GetTexteLibelle('RULES-LAB_991') + '|*.png;*.jpg;*.jpeg;*.bmp';
    if not Dialogue.Execute then Exit;
    if MessageDlg(GetTexteLibelle('RULES-LAB_992'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    Source := TPicture.Create;
    try
      Source.LoadFromFile(Dialogue.FileName);
      Cible := GetCurrentDir + FDossier + FNom + '.PNG';
      ForceDirectories(ExtractFilePath(Cible));
      Source.SaveToFile(Cible);  // ecrit au format de l'extension : toujours PNG
      Trans := GetCurrentDir + FDossier + FNom + ConstTransparent + '.PNG';
      if FileExists(Trans) then DeleteFile(Trans);
    finally
      Source.Free;
    end;
  finally
    Dialogue.Free;
  end;
  Recharger;
end;

end.

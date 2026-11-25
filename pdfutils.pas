unit PdfUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpPDF, ChargeConstantes, Math, Unitcalcul, Graphics, IntfGraphics, Controls, fpTTF,
  BGRABitmap, BGRABitmapTypes, LclIntF, LazUTF8, FPImage, FPReadPNG, FPWritePNG, FPWriteJPEG;

// Mode --dumppdf : si PdfTrace est cree, chaque texte ecrit par PdfEcrit / PdfCentre y est aussi
// note (x et y en mm de la page, texte). Nil en usage normal.
Var
  PdfTrace: TStringList = nil;
  // Mode liste (colonne de droite du PDF metier) : une ligne trop longue passe sur 2 ou 3 lignes,
  // coupee de preference apres un « / » (separateur de choix), et PdfRangeesSupp dit combien de
  // rangees supplementaires elle a prises (a ajouter par l appelant avant la ligne suivante).
  PdfModeListe: Boolean = false;
  PdfRangeesSupp: Integer = 0;

Procedure PdfTraceTexte(X, Y: Single; const Texte: String);
Procedure PdfEncadre(PdfPage: TPDFPage; X: Single; Y: Single; Bouclier: Boolean; TB1: String; TB2: String; TH: String);
Procedure PdfCentre(PdfPage: TPDFPage; Min: Single; Max: Single; Y: Single; Texte: String);
Procedure PdfEcrit(PdfPage: TPDFPage; Min: Single; Max: Single; Y: Single; Texte: String; MinPolice: Integer);
Procedure PdfTaillePolice(PdfPage: TPDFPage; IdPolice:Integer; NomPolice: String; Taille:Integer);
Function PdfSupprimeGenerique(Code: String; Chaine: String): String;
procedure RedimensionneImage(inWidth: dWord; inHeigth: dWord; maxWidth: dWord; maxHeigth: dWord; out resWidth: dWord; out resHeigth: dWord);
function ColorToARGB(AColor: TColor; Transparent: Integer): TARGBColor;
Function ChargeImageArrayColorFichier(Chemin: String): TColor;
Function ChargeImageArrayColor(Niveau: Integer): TColor;
// Libelle utilisable comme nom de fichier : les caracteres interdits sous Windows deviennent un
// tiret. Sans cela, "Dwarf (Karak Hirn/Black Mountains)" faisait echouer l'ecriture du PDF.
Function NomFichierSur(const Libelle: String): String;
// Couleur de fond d'une icone de niveau : pixel (1,1) ou, s'il est transparent (coins arrondis),
// pixel du corps (centre, au quart de la hauteur, sous le contour et hors des points).
Function CouleurFondIcone(Bmp: TBitmap): TColor;
// Comme CheminImage, mais rend un petit PNG transparent si l'image n'existe nulle part : un
// PDF dessine alors "rien" au lieu de lever une exception (version publiable, 11/10/2026).
Function CheminImagePdf(Chemin: String): String;
procedure ChargeImageTImageList(Niveau: Integer; ListImage: TImageList);
procedure RemplacerPixelParTransparent(const FileOrig: string; Const FileDest: String);
function TestCouleur(img: TBGRABitmap; x: integer;y: integer; VerifTrans: Boolean):boolean;
Function TailleTexte(Texte: String; FontTaille: Integer): TPDFFloat;
Function TestPixelZeroZero(Const Filename: String): Boolean;
// Vrai si les coins haut-gauche et bas-droit de l'image sont transparents (alpha < 128) : une
// illustration detouree, qui peut deborder sur un titre sans le cacher. Faux si le fond est plein.
Function ImageAFondTransparent(Const Filename: String): Boolean;
// Garamond (italique et gras) pour l'habillage du PDF Feldo : chemins des fichiers et presence
// dans le cache de polices. Faux si une des deux variantes manque (on reste alors en Arial).
Function PdfGaramondChemins(out Italique, Gras, Famille: String): Boolean;
Procedure PdfPolicesDeRepli;
Function PdfCheminPolice(Const Fichier: String): String;
// Supprime les autres PDF du dossier du PDF qu'on vient d'ecrire : seul le dernier est conserve
// (les XML d'historique permettent de regenerer les anciens). Un PDF ouvert dans une visionneuse
// ne peut pas etre supprime : il reste alors jusqu'a la prochaine creation.
Procedure PdfPurgeAnciens(Const Chemin: String);

implementation

Const
  ZeroRed   = 0;
  ZeroGreen = 0;
  ZeroBlue  = 0;

Procedure PdfEncadre(PdfPage: TPDFPage; X: Single; Y: Single; Bouclier: Boolean; TB1: String; TB2: String; TH: String);
  var
    Bas: Single;
  begin
    if Bouclier = false then
      begin
        PdfPage.DrawLine(X-2, Y-2, X+4, Y-2, 1);
        PdfPage.DrawLine(X-2, Y+4, X+4, Y+4, 1);
        PdfPage.DrawLine(X-2, Y-2, X-2, Y+4, 1);
        PdfPage.DrawLine(X+4, Y-2, X+4, Y+4, 1);
        Bas := 6;
      end
    else
      begin
       PdfPage.DrawLine(X-2.5, Y+2, X+1, Y+5, 1);
       PdfPage.DrawLine(X+1, Y+5, X+4.5, Y+2, 1);
       PdfPage.DrawLine(X-2.5, Y+2, X, Y-2.5, 1);
       PdfPage.DrawLine(X+4.5, Y+2, X+2, Y-2.5, 1);
       PdfPage.DrawLine(X+2, Y-2.5, X+1, Y-3.5, 1);
       PdfPage.DrawLine(X, Y-2.5, X+1, Y-3.5, 1);
       Bas := 7.5
      end;
    PdfCentre(PdfPage, X-6, X+10, Y-Bas, TB1);
    if TB2 <> '' then
      PdfCentre(PdfPage, X-8, X+10, Y-Bas-4, TB2);
    if TH <> '' then
      PdfCentre(PdfPage, X-8, X+12, Y+5, TH);
  end;

Procedure PdfTraceTexte(X, Y: Single; const Texte: String);
  var
    DefaultFormatSettings: TFormatSettings;
  begin
    DefaultFormatSettings := FormatSettings;
    DefaultFormatSettings.DecimalSeparator := '.';
    // Y arrive en mm depuis le bas de la page ; la trace le donne depuis le haut (page Letter, 279,4 mm)
    // pour que le tri lise la fiche de haut en bas.
    if (PdfTrace <> nil) and (Trim(Texte) <> '') then
      PdfTrace.Add(Format('haut=%05.1f x=%05.1f %s', [279.4 - Y, X, Texte], DefaultFormatSettings));
  end;

Function TailleTexte(Texte: String; FontTaille: Integer): TPDFFloat;
  var
    PosTemp:      TPDFFloat;
    lFC:          TFPFontCacheItem;
  Begin
    lFC     := gTTFontCache.Find(PdfFamilyName, PdfIsBold, PdfIsItalic);
    PosTemp := PDFTomm(lFC.TextWidth(Texte, FontTaille));
    Result  := PosTemp;
  end;

// Premiere ligne de Texte qui tient dans Diff a la police Taille ; Reste = ce qui suit.
// Coupe de preference apres un « / » (entre deux choix), sinon a la derniere espace, '|' ou ','.
Function CoupeLigne(const Texte: String; Taille: Integer; Diff: Float; out Reste: String): String;
  var
    N, K, P, I: Integer;
    C: String;
  begin
    N := UTF8Length(Texte);
    K := N;
    while (K > 1) and (TailleTexte(UTF8Copy(Texte, 1, K), Taille) > Diff) do
      Dec(K);
    if K >= N then
      begin
        Reste := '';
        Result := Texte;
        Exit;
      end;
    P := 0;
    I := K;
    while (I >= 2) and (P = 0) do   // choix : « ... / » avec une espace avant
      begin
        if (UTF8Copy(Texte, I, 1) = '/') and (UTF8Copy(Texte, I - 1, 1) = ' ') then
          P := I;
        Dec(I);
      end;
    I := K;
    while (I >= 1) and (P = 0) do
      begin
        C := UTF8Copy(Texte, I, 1);
        if (C = ' ') or (C = '|') or (C = ',') then
          P := I;
        Dec(I);
      end;
    if P = 0 then P := K;
    Result := Trim(UTF8Copy(Texte, 1, P));
    Reste := Trim(UTF8Copy(Texte, P + 1, N));
  end;

Procedure PdfEcrit(PdfPage: TPDFPage; Min: Single; Max: Single; Y: Single; Texte: String; MinPolice: Integer);
  var
    TailleTemp:   Integer = 0;
    Suite:        String;
    Piece:        String;
    NbPieces:     Integer;
    DeuxLignes:   Boolean = false;
    Ligne1:       String;
    Ligne2:       String;
    Ligne3:       String;
    PosTemp:      TPDFFloat;
    SousTrait:    Integer;
    Diff:         Float;
    Texte2:       String;

  BEgin
    PdfTraceTexte(Min, Y, Texte);
    PdfRangeesSupp := 0;
    Diff := (Max - Min) * 1.15;
    PosTemp := TailleTexte(Texte, PdfFontTaille);
    if PosTemp > Diff then
      begin
        TailleTemp := PdfFontTaille - 1;
        while TailleTexte(Texte, TailleTemp)  > Diff do
          Dec(TailleTemp);

        if TailleTemp < MinPolice then
          begin
            TailleTemp := MinPolice;
            DeuxLignes := true;
          end;

        if TailleTemp <> PdfFontTaille then
          PdfPage.SetFont(PdfFontEnCours, Tailletemp);
      end;

    if DeuxLignes and PdfModeListe then
      begin
        // Liste : jusqu'a 3 lignes espacees de 2,6 mm ; chaque ligne en plus prend une rangee
        // de la liste (PdfRangeesSupp), les lignes suivantes sont decalees par l'appelant.
        Suite := Texte;
        NbPieces := 0;
        while Suite <> '' do
          begin
            if NbPieces >= 2 then
              Piece := Suite   // 3e ligne : le reste, quoi qu'il arrive
            else
              Piece := CoupeLigne(Suite, TailleTemp, Diff, Texte2);
            if NbPieces >= 2 then Texte2 := '';
            if NbPieces > 0 then Piece := '   ' + Piece;
            PdfPage.WriteText(Min, Y + 0.4 - NbPieces * 2.6, Piece);
            Suite := Texte2;
            Inc(NbPieces);
          end;
        PdfRangeesSupp := NbPieces - 1;
      end
    else if DeuxLignes = true then
      begin
        SousTrait := 1;
        // Bornage du 06/09/2026 (CONTEXT.md - regression Feldo2P) : sans le test sur
        // UTF8Length(Texte), un texte sans espace/'|'/',' (ex. un code non resolu affiche
        // brut) faisait tourner ces deux while indefiniment - UTF8Copy renvoie '' au-dela
        // du debut de la chaine, et '' n'est jamais egal a ' ', '|' ou ','.
        while (Soustrait < UTF8Length(Texte))
              and (TailleTexte(UTF8Copy(Texte, 1, UTF8Length(Texte) - Soustrait), TailleTemp)  > Diff) do
          Inc(Soustrait);

        while (Soustrait < UTF8Length(Texte))
              and (UTF8Copy(Texte, UTF8Length(Texte) - Soustrait, 1) <> ' ')
              and (UTF8Copy(Texte, UTF8Length(Texte) - Soustrait, 1) <> '|')
              and (UTF8Copy(Texte, UTF8Length(Texte) - Soustrait, 1) <> ',') do
          Inc(Soustrait);

        Ligne1 := UTF8Copy(Texte, 1, UTF8Length(Texte) - Soustrait - 1);
        Ligne2 := UTF8Copy(Texte, UTF8Length(Texte) - Soustrait, UTF8Length(Texte));
        Ligne1 := Trim(Ligne1);

        if TailleTexte(Ligne2, TailleTemp) > Diff then
          begin
            Texte2 := Ligne2;
            SousTrait := 1;

            while (Soustrait < UTF8Length(Texte2))
                  and (TailleTexte(UTF8Copy(Texte2, 1, UTF8Length(Texte2) - Soustrait), TailleTemp)  > Diff) do
              Inc(Soustrait);

            while (Soustrait < UTF8Length(Texte2))
                  and (UTF8Copy(Texte2, UTF8Length(Texte2) - Soustrait, 1) <> ' ')
                  and (UTF8Copy(Texte2, UTF8Length(Texte2) - Soustrait, 1) <> '|')
                  and (UTF8Copy(Texte2, UTF8Length(Texte2) - Soustrait, 1) <> ',') do
              Inc(Soustrait);

            Ligne2 := UTF8Copy(Texte2, 1, UTF8Length(Texte2) - Soustrait - 1);
            Ligne3 := UTF8Copy(Texte2, UTF8Length(Texte2) - Soustrait, UTF8Length(Texte2));
            Ligne2 := Trim(Ligne2);
            PdfPage.WriteText(Min, Y+1.4, Ligne1);
            PdfPage.WriteText(Min, Y, ' '+Ligne2);
            PdfPage.WriteText(Min, Y-1.4, ' '+Ligne3);
          end
        else
          begin
            PdfPage.WriteText(Min, Y+1, Ligne1);
            PdfPage.WriteText(Min, Y-1, '  '+Ligne2);
          end;
      end
    else
      PdfPage.WriteText(Min, Y, Texte);
    if TailleTemp <> PdfFontTaille then
      PdfPage.SetFont(PdfFontEnCours, PdfFontTaille);
  end;

Procedure PdfTaillePolice(PdfPage: TPDFPage; IdPolice:Integer; NomPolice: String; Taille:Integer);
  Var
    NomFamille:       String;
    PdfTitreRepli:    Boolean;
  begin
    PdfFontTaille     := Taille;
    PdfFontEnCours    := IdPolice;
    PdfIsBold         := (Pos(ConstPoliceGras, NomPolice) > 0);
    PdfIsItalic       := (Pos(ConstPoliceItalique, NomPolice) > 0);
    NomFamille        := NomPolice;
    PdfTitreRepli     := (Length(ConstPoliceCarlson) > 0) and (ConstPoliceCarlson <> ConstPoliceArial)
                         and (Pos('Garamond', ConstPoliceCarlson) > 0)
                         and (Copy(NomPolice, 1, Length(ConstPoliceCarlson)) = ConstPoliceCarlson);
    if PdfIsBold then
       NomFamille := StringReplace(NomFamille,ConstPoliceGras,'', [rfReplaceAll]);
    if PdfIsItalic then
       NomFamille := StringReplace(NomFamille,ConstPoliceItalique,'', [rfReplaceAll]);
    PdfFamilyName     := TrimRight(NomFamille);
    // Garamond est plus petit et plus etroit qu'Arial a corps egal : +12 % pour retrouver le
    // meme encombrement visuel dans les cases du PDF Feldo habille.
    if (Pos('Garamond', PdfFamilyName) > 0) and (not PdfTitreRepli) then
      PdfFontTaille   := Round(Taille * 1.12);
    // Titres en repli : Garamond Bold est plus large que Caslon Antique Bold, les libelles
    // (Specie, Career Level, Height...) debordaient de leurs cases a corps egal.
    if PdfTitreRepli then
      PdfFontTaille   := Round(Taille * 0.85);
    PdfPage.SetFont(IdPolice, PdfFontTaille);
  end;

// Arial et Caslon Antique ne sont pas redistribuables : quand leurs fichiers manquent dans FONT\,
// repli sur EB Garamond (licence OFL, livree). Sans cela AddFont ouvre une boite d'erreur modale
// et PdfCentre / PdfEcrit plantent (gTTFontCache.Find du nom de famille renvoie nil).
// A appeler avant les AddFont : modifie les noms de famille utilises par PdfTaillePolice.
Procedure PdfPolicesDeRepli;
  var
    Dossier: String;
  begin
    Dossier := GetCurrentDir + ConstCheminImagePolice;
    if not (FileExists(Dossier + 'EBGaramond-Regular.ttf')
            and FileExists(Dossier + 'EBGaramond-Bold.ttf')
            and FileExists(Dossier + 'EBGaramond-Italic.ttf')
            and (gTTFontCache.Find('EB Garamond', False, False) <> nil)) then
      Exit;
    // Titre : DEUX espaces finaux = marque (distincte de 'EB Garamond Bold' des valeurs) (TrimRight l'efface pour la recherche dans le cache) pour que
    // PdfTaillePolice n'applique pas le +12 % prevu pour les valeurs en remplacement d'Arial.
    if not FileExists(Dossier + 'CaslonAntique.ttf') then
      ConstPoliceCarlson := 'EB Garamond  ';
    if not FileExists(Dossier + 'ariali.ttf') then
      ConstPoliceArial := 'EB Garamond';
  end;

// Chemin d'un fichier de police de FONT\ ; le fichier EB Garamond equivalent s'il manque.
Function PdfCheminPolice(Const Fichier: String): String;
  var
    Dossier: String;
    Repli:   String;
  begin
    Dossier := GetCurrentDir + ConstCheminImagePolice;
    Result  := Dossier + Fichier;
    if FileExists(Result) then
      Exit;
    if (Pos('Italic', Fichier) > 0) or (LowerCase(Fichier) = 'ariali.ttf') then
      Repli := 'EBGaramond-Italic.ttf'
    else if (Pos('Bold', Fichier) > 0) or (LowerCase(Fichier) = 'arialbd.ttf') then
      Repli := 'EBGaramond-Bold.ttf'
    else
      Repli := 'EBGaramond-Regular.ttf';
    if FileExists(Dossier + Repli) then
      Result := Dossier + Repli;
  end;

Function PdfGaramondChemins(out Italique, Gras, Famille: String): Boolean;
  var
    Dossiers: array[0..1] of String;
    Ind:      Integer;
  begin
    Result    := False;
    Italique  := '';
    Gras      := '';
    Famille   := 'Garamond';
    // EB Garamond (licence OFL) livree dans FONT\ : prioritaire, le PDF ne depend plus de Windows
    if FileExists(GetCurrentDir + ConstCheminImagePolice + 'EBGaramond-Italic.ttf')
       and FileExists(GetCurrentDir + ConstCheminImagePolice + 'EBGaramond-Bold.ttf')
       and (gTTFontCache.Find('EB Garamond', False, False) <> nil)
       and (gTTFontCache.Find('EB Garamond', True, False) <> nil) then
      begin
        Italique := GetCurrentDir + ConstCheminImagePolice + 'EBGaramond-Italic.ttf';
        Gras     := GetCurrentDir + ConstCheminImagePolice + 'EBGaramond-Bold.ttf';
        Famille  := 'EB Garamond';
        Exit(True);
      end;
    Dossiers[0] := GetCurrentDir + ConstCheminImagePolice;
    Dossiers[1] := 'C:\Windows\Fonts\';
    for Ind := 0 to High(Dossiers) do
      if FileExists(Dossiers[Ind] + 'GARAIT.TTF') and FileExists(Dossiers[Ind] + 'GARABD.TTF') then
        begin
          Italique := Dossiers[Ind] + 'GARAIT.TTF';
          Gras     := Dossiers[Ind] + 'GARABD.TTF';
          break;
        end;
    if Italique = '' then
      Exit;
    // le cache sert aux mesures (PdfCentre, PdfEcrit) : il doit connaitre la famille
    Result := (gTTFontCache.Find('Garamond', False, False) <> nil)
          and (gTTFontCache.Find('Garamond', True, False) <> nil);
  end;


Procedure PdfCentre(PdfPage: TPDFPage; Min: Single; Max: Single; Y: Single; Texte: String);
  var
    Ajout:        Single = 0.2;
    TailleTemp:   Integer = 0;
    Prorata:      Single;
    lFC:          TFPFontCacheItem;
    PosTemp:      TPDFFloat;
  BEgin
    PdfTraceTexte(Min, Y, Texte);
    lFC:= gTTFontCache.Find(PdfFamilyName, PdfIsBold, PdfIsItalic);
    PosTemp:= PDFTomm(lFC.TextWidth(Texte, PdfFontTaille));

    if PosTemp < (Max - Min) then
      Ajout := ((Max - Min - PosTemp) / 2)
    else
      begin
        Prorata    := (Max - Min) / PosTemp;
        Tailletemp := Ceil(PdfFontTaille * Prorata);
        if Tailletemp = PdfFontTaille then
          Tailletemp := Tailletemp - 1;

        PdfPage.SetFont(PdfFontEnCours, Tailletemp);
      end;

    PdfPage.WriteText( Min + Ajout, Y, Texte);
    if TailleTemp <> 0 then
      PdfPage.SetFont(PdfFontEnCours, PdfFontTaille);
  end;

Function PdfSupprimeGenerique(Code: String; Chaine: String): String;
  Begin
    if Pos(ValeurGenerique, Code) = 0 then
      Result := Chaine
    else
      Result := ExtractStringBefore(Chaine, '(');
  end;


procedure RedimensionneImage(inWidth: dWord; inHeigth: dWord; maxWidth: dWord; maxHeigth: dWord; out resWidth: dWord; out resHeigth: dWord);
  var
    Prorata: float;
  begin
    if (inWidth <> 0) and (inHeigth <> 0) and (maxWidth <> 0) and (maxHeigth <> 0) then
      begin
        if (inWidth / maxWidth) > (inHeigth / maxHeigth) then
          Prorata := (inWidth / maxWidth)
        else
          Prorata := (inHeigth / maxHeigth);
        resWidth := round(inWidth / Prorata);
        resHeigth:= round(inHeigth / Prorata);
      end
    else
      begin
        resWidth  := 0;
        resHeigth := 0;
      end;
  end;


function ColorToARGB(AColor: TColor; Transparent: Integer): TARGBColor;
type
  TColorRec = record r,g,b,a: byte; end;
  TARGBColorRec = record b,g,r,a: byte; end;
begin
  with TARGBColorRec(Result) do
  begin
    b := TColorRec(AColor).b;
    g := TColorRec(AColor).g;
    r := TColorRec(AColor).r;
    a := Transparent;
  end;
end;

// Couleur d'encadrement tiree du pixel [1,1] d'une image DESIGNEE PAR SON CHEMIN. Le
// chemin peut venir du dossier d'un livre : c'est l'appelant qui l'a resolu.
// Fichier absent = gris fonce, jamais d'exception - un niveau peut ne pas avoir d'icone.
Function NomFichierSur(const Libelle: String): String;
  var
    Ind: Integer;
  begin
    Result := Libelle;
    for Ind := 1 to Length(Result) do
      if Result[Ind] in [Chr(92), '/', ':', '*', '?', '"', '<', '>', '|'] then
        Result[Ind] := '-';
  end;

Function CouleurFondIcone(Bmp: TBitmap): TColor;
  var
    Img: TLazIntfImage;
  begin
    Result := Bmp.Canvas.Pixels[1, 1];
    Img := Bmp.CreateIntfImage;
    try
      if (Img.Width > 1) and (Img.Colors[1, 1].alpha < $8000) then
        Result := FPColorToTColor(Img.Colors[Img.Width div 2, Img.Height div 4]);
    finally
      Img.Free;
    end;
  end;

Function CheminImagePdf(Chemin: String): String;
  var
    Img: TFPMemoryImage;
    Ecr: TFPWriterPNG;
  begin
    Result := CheminImage(Chemin);
    if FileExists(Result) then
      Exit;
    Result := IncludeTrailingPathDelimiter(GetTempDir) + 'wh_image_vide.png';
    if FileExists(Result) then
      Exit;
    Img := TFPMemoryImage.Create(1, 1);
    Ecr := TFPWriterPNG.Create;
    try
      Img.Colors[0, 0] := FPColor(0, 0, 0, 0);
      Ecr.UseAlpha := True;
      Img.SaveToFile(Result, Ecr);
    finally
      Ecr.Free;
      Img.Free;
    end;
  end;

Function ChargeImageArrayColorFichier(Chemin: String): TColor;
  var
    picture:          TPicture;
    Bitmap:           TBitmap;
  begin
    Result := CouleurGrisFonce;
    if not FileExists(Chemin) then
      Exit;
    Picture  := TPicture.Create;
    Bitmap   := TBitmap.Create;
    try
      Picture.LoadFromFile(Chemin);
      Bitmap.Assign(Picture.graphic);
      Result := CouleurFondIcone(Bitmap);
    finally
      Picture.Free;
      Bitmap.Free;
    end;
  end;

// Variante historique, sur le dossier generique.
Function ChargeImageArrayColor(Niveau: Integer): TColor;
  begin
    Result := ChargeImageArrayColorFichier(CheminImage(GetCurrentDir+ConstCheminImageNiveau+InttoStr(Niveau)+'.PNG'));
  end;

procedure ChargeImageTImageList(Niveau: Integer; ListImage: TImageList);
  var
    picture:          TPicture;
    Bitmap:           TBitmap;
    Path:             String;
  begin
    Picture  := TPicture.Create;
    Bitmap   := TBitmap.Create;
    try
      Path   := CheminImage(GetCurrentDir+ConstCheminImageNiveau+InttoStr(Niveau)+'.PNG');
      if FileExists(Path) then
        begin
          Picture.LoadFromFile(Path);
          Bitmap.Assign(Picture.graphic);
        end
      else
        Bitmap.SetSize(8, 8);
      ListImage.Add(Bitmap, nil);
    finally
      Picture.Free;
      Bitmap.Free;
    end;
  end;

// ATTENTION - CETTE FONCTION N'EST PLUS APPELEE PAR PERSONNE depuis la reecriture de
// RemplacerPixelParTransparent le 31/08/2026, qui etait son unique utilisatrice. Elle est
// conservee telle quelle en attendant que Nono decide de la supprimer, avec les trois
// variables d'unite ZeroRed / ZeroGreen / ZeroBlue plus haut.
//
// NE PAS LA REUTILISER EN L'ETAT, elle porte deux defauts signales et non corriges :
//   - avec VerifTrans = True elle ne teste PAS la transparence. Elle compare R, G et B a
//     ceux de BGRAPixelTransparent, c'est-a-dire a (0,0,0), et IGNORE l'alpha : un pixel
//     NOIR OPAQUE y repond donc "oui, je suis transparent". Sur une icone a contour noir,
//     toute propagation basee dessus fuirait par le trait ;
//   - ZeroRed / ZeroGreen / ZeroBlue ne sont plus alimentees par personne et valent donc 0.
//     Avec VerifTrans = False, cette fonction compare aujourd'hui au noir, pas au fond.
function TestCouleur(img: TBGRABitmap; x: integer;y: integer; VerifTrans: Boolean):boolean;
var
  TestRed:   Integer;
  TestGreen: Integer;
  TestBlue:  Integer;
  MaxDiff:   Integer = 2000;
begin
  if VerifTrans then
    begin
      TestRed   := BGRAPixelTransparent.red;
      TestGreen := BGRAPixelTransparent.Green;
      TestBlue  := BGRAPixelTransparent.Blue;
    end
  else
    begin
      TestRed   := ZeroRed;
      TestGreen := ZeroGreen;
      TestBlue  := ZeroBlue;
    end;

  if (img.Colors[x, y].Red   = TestRed)   and // test equal
     (img.Colors[x, y].Green = TestGreen) and
     (img.Colors[x, y].Blue  = TestBlue)  then
    Result := true
  else if (VerifTrans = false) and            // test close if not test transparent
          (abs(img.Colors[x, y].Red   - TestRed)   < MaxDiff) and
          (abs(img.Colors[x, y].Green - TestGreen) < MaxDiff) and
          (abs(img.Colors[x, y].Blue  - TestBlue)  < MaxDiff) then
    Result := true
  else
    Result := false;
end;

Function TestPixelZeroZero(Const Filename: String): Boolean;
  var
    Img: TBGRABitmap;
    Res: Boolean = false;
  begin
    Img  := TBGRABitmap.Create(FileName);
  try
    Res  := (Img.GetPixel(0, 0) = BGRAPixelTransparent);
  finally
    Img.Free;
  end;
  Result := Res;
end;

Function ImageAFondTransparent(Const Filename: String): Boolean;
  var
    Img: TBGRABitmap;
  begin
    Result := False;
    if not FileExists(Filename) then
      Exit;
    Img := TBGRABitmap.Create(Filename);
    try
      if (Img.Width > 1) and (Img.Height > 1) then
        Result := (Img.GetPixel(0, 0).alpha < 128) and (Img.GetPixel(Img.Width - 1, Img.Height - 1).alpha < 128);
    finally
      Img.Free;
    end;
  end;


// Rend transparent tout pixel proche de la couleur du coin (0,0).
//
// REECRITE LE 31/08/2026 POUR LA VITESSE. L'ancienne version appelait Img.ReplaceColor A
// L'INTERIEUR de la double boucle. ReplaceColor reparcourt l'image ENTIERE a chaque appel ;
// et comme le test de couleur avait une TOLERANCE alors que ReplaceColor exige la couleur
// EXACTE, chaque pixel d'anti-aliasing du bord survivait au remplacement, matchait quand
// meme au test suivant, et declenchait un nouveau balayage complet. Des centaines de
// balayages de l'image entiere pour une seule icone.
//
// Second cout, plus discret : img.Colors[x,y] est l'accesseur TFPColor de FPImage, qui
// convertit le pixel BGRA en quatre canaux 16 bits A CHAQUE LECTURE - et l'ancien
// TestCouleur le relisait une fois par canal, appele jusqu'a trois fois par pixel. Une
// vingtaine de conversions par pixel la ou une seule lecture suffit.
//
// Ici : un seul passage, ligne par ligne. ScanLine[y] donne un pointeur direct sur les
// pixels de la ligne, qu'on avance par Inc(p) - donc un parcours qui suit l'ordre de la
// memoire, alors que l'ancienne boucle allait en colonnes (x externe) sur des donnees
// rangees en lignes.
//
// TOLERANCE IDENTIQUE, PAS APPROCHEE : l'ancien MaxDiff valait 2000 sur l'echelle 16 bits
// de TFPColor. Un ecart de N sur 8 bits vaut exactement N*257 sur 16 bits, donc
// "diff16 < 2000" equivaut a "diff8 <= 7", c'est-a-dire au "< 8" ci-dessous.
//
// SEMANTIQUE RETENUE (choix de Nono, 31/08/2026) : tout pixel proche du fond devient
// transparent, OU QU'IL SOIT dans l'image. C'est deja ce que faisait l'ancienne version en
// pratique : ReplaceColor etant globale, elle court-circuitait la logique de propagation
// depuis les bords ecrite juste au-dessus d'elle, qui ne servait donc a rien. Les icones du
// projet sont sur fond uni. Si l'une d'elles avait un jour du fond EMPRISONNE a l'interieur
// du dessin et devant rester opaque, il faudrait un vrai remplissage par diffusion depuis
// les bords - et il faudrait alors d'abord corriger TestCouleur (voir son commentaire).
procedure RemplacerPixelParTransparent(const FileOrig: string; Const FileDest: String);
const
  Tolerance = 8;
var
  Img:  TBGRABitmap;
  Fond: TBGRAPixel;
  p:    PBGRAPixel;
  x, y: Integer;
begin
  Img := TBGRABitmap.Create(FileOrig);
  try
    if (Img.Width = 0) or (Img.Height = 0) then
      begin
        Img.SaveToFile(FileDest);
        Exit;
      end;

    Fond := Img.GetPixel(0, 0);

    // COIN DEJA TRANSPARENT : l'image arrive avec son fond detoure, il n'y a rien a enlever.
    //
    // Sortir ici n'est pas une economie, c'est une PROTECTION. Le RVB d'un pixel transparent
    // vaut (0,0,0) : sans ce test, la comparaison ci-dessous prendrait le NOIR pour la
    // couleur de fond et effacerait tous les pixels noirs de l'image, contours du dessin
    // compris. Mesure faite le 31/08/2026 sur WORK132 a WORK135, les images des carrieres du
    // lot 2 de High Elf, qui arrivent toutes avec un fond deja transparent : environ 50 % de
    // leurs pixels y passaient.
    //
    // Le garde existait deja, mais chez les APPELANTS - le "if (Not TestPixelZeroZero(...))"
    // de CheminMetierImage et de CheminRaceImage. Il est desormais AUSSI dans la routine,
    // pour qu'un troisieme appelant ecrit plus tard ne puisse pas passer a cote.
    if Fond.alpha = 0 then
      begin
        Img.SaveToFile(FileDest);
        Exit;
      end;

    for y := 0 to Img.Height - 1 do
      begin
        p := Img.ScanLine[y];
        for x := 0 to Img.Width - 1 do
          begin
            // Un pixel deja transparent n'a pas a etre re-teste : son RVB ne veut plus rien
            // dire, et le rendre transparent une seconde fois ne changerait rien.
            if (p^.alpha > 0) and
               (Abs(Integer(p^.red)   - Integer(Fond.red))   < Tolerance) and
               (Abs(Integer(p^.green) - Integer(Fond.green)) < Tolerance) and
               (Abs(Integer(p^.blue)  - Integer(Fond.blue))  < Tolerance) then
              p^ := BGRAPixelTransparent;
            Inc(p);
          end;
      end;

    // OBLIGATOIRE apres une ecriture directe via ScanLine : BGRABitmap garde une copie
    // LCL du bitmap, qu'il faut invalider pour qu'elle soit reconstruite depuis les
    // donnees qu'on vient de modifier.
    Img.InvalidateBitmap;

    Img.SaveToFile(FileDest);
  finally
    Img.Free;
  end;
end;

Procedure PdfPurgeAnciens(Const Chemin: String);
  var
    Dossier: String;
    Rech: TSearchRec;
  begin
    Dossier := ExtractFilePath(Chemin);
    if FindFirst(Dossier + '*.PDF', faAnyFile, Rech) = 0 then
      try
        repeat
          if (Rech.Attr and faDirectory) = 0 then
            if CompareText(Rech.Name, ExtractFileName(Chemin)) <> 0 then
              DeleteFile(Dossier + Rech.Name);
        until FindNext(Rech) <> 0;
      finally
        FindClose(Rech);
      end;
  end;

end.


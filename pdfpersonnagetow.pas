unit PdfPersonnageTow;

{$mode ObjFPC}{$H+}

// PDF de personnage The Old World (WFRPTOW) : les valeurs sont ecrites SUR l'image de la feuille officielle
// (Character Sheet, 2 pages, format letter ; images PICTURES_DEFAULT\WFRPTOW\PDF\FOND-1.jpg / FOND-2.jpg, tirees du
// PDF officiel et hors licence du depot). Meme principe que le PDF V1 / V2 et que l'option « Fond officiel » du V5.
// GEOMETRIE : coordonnees en POINTS (1/72 pouce), origine EN HAUT A GAUCHE, relevees sur la feuille officielle
// (pdftotext -bbox) ; les routines de dessin convertissent en mm et retournent l'axe Y.
// Page 1 : identite, Fate, XP, Speed, Status, 9 caracteristiques et 16 competences (rangs et ticks), lores, talents,
// armes, Resilience / Protection, Trappings et Assets, contacts. Page 2 : niveau de Wizard, sorts, Grim Portent, notes.
// Branche par PdfPersonnageTowHook (pdfpersonnage.pas) : l'unite s'enregistre dans initialization.

interface

uses
  Classes, SysUtils, fpPDF, PdfUtils, PdfPersonnage, ChargeConstantes, ChargeTraduction, ChargePersonnage,
  ChargeRace, ChargeMetier, ChargeCompetence, ChargeTalent, ChargeArme, ChargeArmure, ChargeArmeBonus,
  ChargeSort, ChargeTrapping, ChargeTexte, ChargeCreationTow, UnitCalcul, Dialogs, LCLIntf, Math, StrUtils, Graphics;

Procedure PdfPersonnageTow(Personnage: StructurePersonnage);

implementation

const
  PL = 215.9;                // largeur de la feuille (mm) : 612 pt
  PH = 279.4;                // hauteur de la feuille (mm) : 792 pt
  Pt = 25.4 / 72;            // un point en mm
  DecalY = 0.0;              // ajustement vertical global du texte (mm)

var
  Page: TPDFPage;

// ---------------------------------------------------------------- outils de dessin (points, Y vers le bas)

function Mm(P: Single): Single;
  begin
    Result := P * Pt;
  end;

// Texte cadre a gauche entre X1 et X2, ligne de base en YBase
procedure Ecrit(X1, X2, YBase: Single; const Texte: String; Taille: Integer = 9; PoliceMin: Integer = 5);
  begin
    if Texte = '' then Exit;
    PdfTaillePolice(Page, PdfFontValue, ConstPoliceArial, Taille);
    PdfEcrit(Page, Mm(X1), Mm(X2), PH - Mm(YBase) + DecalY, Texte, PoliceMin);
  end;

// Texte centre entre X1 et X2
procedure Centre(X1, X2, YBase: Single; const Texte: String; Taille: Integer = 9);
  begin
    if Texte = '' then Exit;
    PdfTaillePolice(Page, PdfFontValue, ConstPoliceArial, Taille);
    PdfCentre(Page, Mm(X1), Mm(X2), PH - Mm(YBase) + DecalY, Texte);
  end;

// Disque plein (Plein) ou petit point (rond) centre en (Xc, Yc), rayon R (points)
procedure Pastille(Xc, Yc, R: Single);
  begin
    Page.SetColor(clBlack, True);
    // decalage relevé au rendu : les disques tombaient 2,4 pt trop haut et 1 pt trop a droite des hexagones
    Page.DrawEllipse(Mm(Xc - 1.0), PH - Mm(Yc + 2.4), Mm(2 * R), Mm(2 * R), 0.2, True, False);
    Page.SetColor(clBlack, False);
  end;

// Croix dans une case centree en (Xc, Yc), demi-cote D
procedure Croix(Xc, Yc, D: Single);
  begin
    Page.DrawLine(Mm(Xc - D), PH - Mm(Yc - D), Mm(Xc + D), PH - Mm(Yc + D), 0.5);
    Page.DrawLine(Mm(Xc - D), PH - Mm(Yc + D), Mm(Xc + D), PH - Mm(Yc - D), 0.5);
  end;

// Paragraphe : texte coupe aux mots (largeur estimee a 0.5 fois la taille par caractere), Pas = interligne (points)
procedure Paragraphe(X1, X2, Y0, Pas: Single; const Texte: String; Taille, MaxLignes: Integer);
  var
    Lignes: TStringList;
    Mots:   TStringList;
    Ligne, Essai: String;
    I, J, Cpl, N: Integer;
  begin
    if Trim(Texte) = '' then Exit;
    Cpl := Max(10, Trunc((X2 - X1) / (0.5 * Taille)));
    Lignes := TStringList.Create;
    Mots   := TStringList.Create;
    try
      Lignes.Text := StringReplace(Texte, '\n', LineEnding, [rfReplaceAll]);
      N := 0;
      for I := 0 to Lignes.Count - 1 do
        begin
          Mots.Clear;
          ExtractStrings([' '], [], PChar(Lignes[I]), Mots);
          Ligne := '';
          for J := 0 to Mots.Count - 1 do
            begin
              Essai := Trim(Ligne + ' ' + Mots[J]);
              if (Length(Essai) > Cpl) and (Ligne <> '') then
                begin
                  if N >= MaxLignes then Exit;
                  Ecrit(X1, X2, Y0 + N * Pas, Ligne, Taille);
                  Inc(N);
                  Ligne := Mots[J];
                end
              else
                Ligne := Essai;
            end;
          if N >= MaxLignes then Exit;
          Ecrit(X1, X2, Y0 + N * Pas, Ligne, Taille);
          Inc(N);
        end;
    finally
      Mots.Free;
      Lignes.Free;
    end;
  end;

// ---------------------------------------------------------------- lecture des donnees

function ValCarac(Personnage: StructurePersonnage; K: Integer): Integer;
  var Bonus: String;
  begin
    Result := PdfPersonnageAttribut(Personnage, TowCodesCarac[K], Bonus).Total;
  end;

function RangComp(Personnage: StructurePersonnage; const Code: String; out Ticks: Integer): Integer;
  var I: Integer;
  begin
    Result := 0;
    Ticks  := 0;
    for I := 0 to High(Personnage.CreationCompetence35) do
      if Personnage.CreationCompetence35[I].CodeCompetence = Code then
        begin
          Result := Personnage.CreationCompetence35[I].Valeur;
          Ticks  := Personnage.CreationCompetence35[I].TicksTow;
          Exit;
        end;
  end;

// Caracteristique (1..8) qui sert aux deux competences de la ligne : WS Melee / Defence, BS Shooting / Throwing...
function CaracDeComp(K: Integer): Integer;
  begin
    Result := (K - 1) div 2 + 1;
  end;

function IndexComp(const Code: String): Integer;
  var K: Integer;
  begin
    Result := 0;
    for K := 1 to TowNbComp do
      if TowCodesComp[K] = Code then Exit(K);
  end;

// Degats « +(BATTR_S)-1 » avec la Force du personnage ; texte brut si la formule n'est pas numerique
function DegatsTow(const Calcul: String; Force: Integer): String;
  var
    T: String;
    I, Somme, Signe, N: Integer;
  begin
    T := StringReplace(Calcul, '(BATTR_S)', IntToStr(Force), [rfReplaceAll]);
    T := StringReplace(T, 'BATTR_S', IntToStr(Force), [rfReplaceAll]);
    T := StringReplace(T, ' ', '', [rfReplaceAll]);
    if (T = '') or (T = '-') then Exit('-');
    Somme := 0; Signe := 1; I := 1;
    while I <= Length(T) do
      begin
        if T[I] = '+' then begin Signe := 1; Inc(I); end
        else if T[I] = '-' then begin Signe := -1; Inc(I); end
        else if T[I] in ['0'..'9'] then
          begin
            N := 0;
            while (I <= Length(T)) and (T[I] in ['0'..'9']) do
              begin
                N := N * 10 + Ord(T[I]) - 48;
                Inc(I);
              end;
            Somme := Somme + Signe * N;
            Signe := 1;
          end
        else Exit(Calcul);
      end;
    Result := IntToStr(Somme);
  end;

// Liste de qualites « CODE val,CODE val » -> libelles
function QualitesLisibles(const Liste: String): String;
  var
    Morceaux: TStringList;
    I: Integer;
    Code, Valeur, Lib: String;
  begin
    Result := '';
    if (Liste = '') or (Liste = '-') then Exit;
    Morceaux := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Liste), Morceaux);
      for I := 0 to Morceaux.Count - 1 do
        begin
          Code   := ExtractStringBefore(Trim(Morceaux[I]), ' ');
          Valeur := Trim(Copy(Trim(Morceaux[I]), Length(Code) + 1, 99));
          Lib    := ChercheArmeBonus(Code).Libelle;
          if Lib = '' then Lib := Code;
          if Result <> '' then Result := Result + ', ';
          Result := Result + Trim(Lib + ' ' + Valeur);
        end;
    finally
      Morceaux.Free;
    end;
  end;

// Un mot de libelle de code du livre TOW (« RULES-... ») ou texte tel quel
function Lib(const S: String): String;
  begin
    if Pos('RULES-', S) = 1 then Result := TowLibelleDe(S) else Result := S;
  end;

function TypeEgal(const A, B: String): Boolean;
  begin
    Result := TrimRight(A) = TrimRight(B);
  end;

// ---------------------------------------------------------------- page 1

procedure BlocIdentite(Personnage: StructurePersonnage);
  var
    Niv, I: Integer;
    YStatus: Single;
  begin
    Ecrit(48, 200, 107.5, Personnage.NomPersonnage, 10);
    Ecrit(48, 200, 122.0, ChercheRace(Personnage.Race).Libelle, 10);
    Ecrit(48, 200, 136.5, ChercheMetier(Personnage.MetierEnCours.CodeMetier).Libelle, 10);
    // Fate / Fortune, XP, Speed
    Centre(222, 246, 72, IntToStr(Personnage.FateTow), 14);
    Centre(268, 298, 72, IntToStr(Personnage.FortuneTow), 14);
    Centre(206, 258, 136, IntToStr(Personnage.XpActuel), 14);
    Centre(266, 316, 134, 'Average', 9);
    // Status : nom a cote du mot « Status », pastilles sur la ligne Brass / Silver / Gold
    if Personnage.StatusTow <> '' then
      Ecrit(500, 575, 57.5, Copy(Personnage.StatusTow, 1, 1) + LowerCase(Copy(Personnage.StatusTow, 2, 20)), 9);
    Niv := Personnage.StatusNiveauTow;
    if Niv > 0 then
      begin
        if UpperCase(Personnage.StatusTow) = 'BRASS' then YStatus := 71.5
        else if UpperCase(Personnage.StatusTow) = 'SILVER' then YStatus := 86.0
        else YStatus := 100.5;
        for I := 1 to Min(Niv, 5) do
          Pastille(509 + (I - 1) * 12.4, YStatus, 3.6);
      end;
  end;

procedure BlocCaracteristiquesCompetences(Personnage: StructurePersonnage);
  var
    K, Rang, Ticks, J: Integer;
    Y: Single;
  begin
    for K := 1 to 8 do
      begin
        Y := 177.5 + (K - 1) * 25.85;
        Centre(70, 82, Y + 8, IntToStr(ValCarac(Personnage, K)), 14);
        if TowCaracFavorite(Personnage.MetierEnCours.CodeMetier, TowCodesCarac[K]) then
          Croix(86.2, Y + 0.3, 2.6);
      end;
    for K := 1 to TowNbComp do
      begin
        Rang := RangComp(Personnage, TowCodesComp[K], Ticks);
        Y := 180.3 + (K - 1) * 12.77;
        // rang : chiffre dans la case a gauche du nom de la competence
        if Rang > 0 then
          Centre(95.3, 113.1, Y + 3.5, IntToStr(Rang), 9);
        // ticks (echecs de temps libre) : un disque par tick dans les hexagones, faciles a cocher en jouant
        for J := 1 to Min(Ticks, 6) do
          Pastille(168.6 + (J - 1) * 9.33, Y, 3.4);
      end;
  end;

procedure BlocLores(Personnage: StructurePersonnage);
  var
    I, Col, Lig: Integer;
    T: String;
  begin
    for I := 0 to High(Personnage.LoresTow) do
      begin
        Col := I mod 3;
        Lig := I div 3;
        if Lig > 2 then Break;
        T := Lib(Personnage.LoresTow[I].Code);
        if Personnage.LoresTow[I].Texte <> '' then
          T := T + ' (' + Lib(Personnage.LoresTow[I].Texte) + ')';
        Ecrit(262 + Col * 110, 366 + Col * 110, 181.5 + Lig * 11.6, T, 7);
      end;
  end;

// Talents : meme talent (et meme precision) regroupe, rang additionne
procedure BlocTalents(Personnage: StructurePersonnage);
  var
    Codes: TStringList;
    Rangs: array of Integer;
    I, K, N: Integer;
    Cle, T: String;

  procedure Ajoute(const T: StructurePersonnageTalent);
    var P: Integer;
    begin
      Cle := T.CodeTalent + '|' + T.ChoixTow;
      P := Codes.IndexOf(Cle);
      if P < 0 then
        begin
          Codes.Add(Cle);
          SetLength(Rangs, Codes.Count);
          Rangs[Codes.Count - 1] := 0;
          P := Codes.Count - 1;
        end;
      Rangs[P] := Rangs[P] + Max(T.Valeur, 1);
    end;

  begin
    Codes := TStringList.Create;
    try
      for I := 0 to High(Personnage.CreationTalent) do Ajoute(Personnage.CreationTalent[I]);
      for I := 0 to High(Personnage.AugmentationTalent) do Ajoute(Personnage.AugmentationTalent[I]);
      N := Codes.Count;
      for I := 0 to N - 1 do
        begin
          K := Pos('|', Codes[I]);
          T := ChercheTalent(Copy(Codes[I], 1, K - 1)).Libelle;
          if Pos('CAREER-TALENT:', Codes[I]) = 1 then
            T := Format(GetTexteLibelle('RULES-MESS_139'),
                        [TowLibelleDe(Copy(Codes[I], Length('CAREER-TALENT:') + 1, K - 1 - Length('CAREER-TALENT:')))])
          else if T = '' then
            T := TowLibelleDe(Copy(Codes[I], 1, K - 1));
          if Pos(';', Copy(Codes[I], K + 1, 200)) > 0 then
            T := T + ' (' + TowLibelleChoix(Copy(Codes[I], K + 1, 200)) + ')'
          else if Copy(Codes[I], K + 1, 200) <> '' then
            T := T + ' (' + Lib(Copy(Codes[I], K + 1, 200)) + ')';
          if Rangs[I] > 1 then T := T + ' x' + IntToStr(Rangs[I]);
          if I < 13 then
            Ecrit(262, 414, 246 + I * 11, T, 8)
          else if I < 26 then
            Ecrit(428, 580, 246 + (I - 13) * 11, T, 8);
        end;
    finally
      Codes.Free;
    end;
  end;

procedure BlocArmesArmures(Personnage: StructurePersonnage);
  var
    Eq: StructurePersonnageEquipement;
    PArme: StructureArme;
    NbArme, Protection, Force, K, Rang, Ticks, Corps, Bouclier: Integer;
    Y: Single;
    T: String;

  // le bouclier ajoute 1 ; parmi les armures de corps, seule la meilleure compte ; l'armure de monture (Barding) est ignoree
  procedure PoseArmure(const Code: String);
    var A: StructureArmure;
    begin
      A := ChercheArmure(Code);
      if A.CodeArmure = 'RULES-ARMO_BARDING' then Exit;
      if A.CodeArmure = 'RULES-ARMO_SHIELD' then
        Bouclier := Max(Bouclier, A.Protection)
      else
        Corps := Max(Corps, A.Protection);
    end;

  begin
    NbArme := 0;
    Protection := 0;
    Corps := 0;
    Bouclier := 0;
    Force := ValCarac(Personnage, 3);
    for Eq in Personnage.Equipement do
      begin
        if TypeEgal(Eq.TypeEquipement, TypeEquipWe) then
          begin
            if NbArme >= 4 then Continue;
            PArme := ChercheArme(Eq.CodeEquipement);
            Y := 442 + NbArme * 13.3;
            T := PArme.Libelle;
            if Eq.TexteTow <> '' then T := T + ' (' + Lib(Eq.TexteTow) + ')';
            Ecrit(32, 140, Y, T, 8);
            Ecrit(143, 186, Y, PArme.Portee, 8);
            K := IndexComp(PArme.CodeCompetence);
            if K > 0 then
              begin
                Rang := RangComp(Personnage, PArme.CodeCompetence, Ticks);
                Centre(190, 238, Y, IntToStr(ValCarac(Personnage, CaracDeComp(K)) + Rang), 8);
              end;
            Centre(243, 278, Y, DegatsTow(PArme.CalculDegat, Force), 8);
            if PArme.Mains > 0 then
              Centre(282, 315, Y, IntToStr(PArme.Mains) + 'h', 8);
            Ecrit(318, 582, Y, QualitesLisibles(PArme.ListeBonus), 7);
            Inc(NbArme);
          end
        else if TypeEgal(Eq.TypeEquipement, TypeEquipAr) then
          PoseArmure(Eq.CodeEquipement);
      end;
    // armure donnee par un Asset (Full Plate Armour...) : meme calcul
    for Eq in TowEquipementAssets(Personnage) do
      if TypeEgal(Eq.TypeEquipement, TypeEquipAr) then
        PoseArmure(Eq.CodeEquipement);
    // Resilience = Toughness + meilleure armure de corps + 1 si bouclier (Player's Guide p.97)
    Protection := Corps + Bouclier;
    Centre(30, 110, 556, IntToStr(ValCarac(Personnage, 4) + Protection), 16);
    Centre(118, 196, 556, IntToStr(Protection), 16);
  end;

procedure BlocTrappingsContacts(Personnage: StructurePersonnage);
  var
    Eq: StructurePersonnageEquipement;
    Ligne: StructurePersonnageLigneTow;
    N, NbContact: Integer;
    Y: Single;
    T: String;

  procedure Ajoute(const Texte: String);
    begin
      if N < 19 then
        Ecrit(224, 392, 547 + N * 10.6, Texte, 8);
      Inc(N);
    end;

  begin
    N := 0;
    for Eq in Personnage.Equipement do
      if TypeEgal(Eq.TypeEquipement, TypeEquipAr) then
        Ajoute(ChercheArmure(Eq.CodeEquipement).Libelle)
      else if TypeEgal(Eq.TypeEquipement, TypeEquipDi) or TypeEgal(Eq.TypeEquipement, TypeEquipAN) then
        begin
          T := PdfDiversLibelle(Eq);
          if Pos('RULES-', T) = 1 then T := TowLibelleDe(T);
          if Eq.TexteTow <> '' then T := T + ' (' + Lib(Eq.TexteTow) + ')';
          Ajoute(T);
        end;
    for Ligne in Personnage.LignesTow do
      if Ligne.Genre = 'ASSET' then
        begin
          T := Lib(Ligne.Code);
          // « FINAL » est un marqueur interne, pas un texte a lire
          if (Trim(Ligne.Texte) <> '') and (UpperCase(Trim(Ligne.Texte)) <> 'FINAL') then
            T := T + ' ' + Lib(Ligne.Texte);
          Ajoute('* ' + T);
        end;
    NbContact := 0;
    for Ligne in Personnage.LignesTow do
      if Ligne.Genre = 'CONTACT' then
        begin
          if NbContact >= 12 then Break;
          Y := 559 + NbContact * 14.2;
          Ecrit(421, 516, Y, Lib(Ligne.Code), 8);
          // colonne etroite : la famille de relation (texte court), pas la description du PNJ
          Ecrit(520, 584, Y,TowLibelleDe(Ligne.Famille), 7);
          Inc(NbContact);
        end;
  end;

// ---------------------------------------------------------------- page 2

procedure PageDeux(Personnage: StructurePersonnage);
  var
    Eq: StructurePersonnageEquipement;
    PSort: StructureSort;
    N, TailleDesc: Integer;
    Y: Single;
  begin
    if Personnage.WizardLevelTow > 0 then
      Centre(30, 145, 50, IntToStr(Personnage.WizardLevelTow), 12);
    // une seule taille pour toutes les descriptions (sinon PdfEcrit reduit chaque ligne a sa guise) :
    // la plus grande (6 a 4) qui tient en une ligne pour tous les sorts, sinon 4 (deux lignes si besoin)
    TailleDesc := 6;
    PdfTaillePolice(Page, PdfFontValue, ConstPoliceArial, 6);
    N := 0;
    for Eq in Personnage.Equipement do
      if TypeEgal(Eq.TypeEquipement, TypeEquipSp) then
        begin
          if N >= 8 then Break;
          PSort := ChercheSort(Eq.CodeEquipement);
          while (TailleDesc > 4)
            and (TailleTexte(PSort.Description, TailleDesc) > (Mm(578) - Mm(326)) * 1.15) do
            Dec(TailleDesc);
          Inc(N);
        end;
    N := 0;
    for Eq in Personnage.Equipement do
      if TypeEgal(Eq.TypeEquipement, TypeEquipSp) then
        begin
          if N >= 8 then Break;
          PSort := ChercheSort(Eq.CodeEquipement);
          Y := 247 + N * 13.0;
          Ecrit(38, 150, Y, PSort.Libelle, 8);
          Centre(152, 172, Y, PSort.Niveau, 8);
          Centre(173, 201, Y, PSort.Cible, 6);
          Centre(202, 237, Y, PSort.Portee, 7);
          Centre(238, 280, Y, PSort.Duree, 7);
          // case Memorised laissee vide : l'etat change en cours de partie (Endeavour Memorise Spell), a cocher au crayon
          Ecrit(326, 578, Y, PSort.Description, TailleDesc, TailleDesc);
          Inc(N);
        end;
    Paragraphe(40, 290, 436, 11, Personnage.GrimPortentTow, 9, 4);
    Paragraphe(312, 575, 420, 11, Personnage.NotesTow, 9, 16);
  end;

// ---------------------------------------------------------------- point d'entree

Procedure PdfPersonnageTow(Personnage: StructurePersonnage);
  var
    PDFDoc: TPDFDocument;
    PdfSection: TPDFSection;
    PdfChemin, Fond1, Fond2: String;
    PdfImgFond1, PdfImgFond2: Integer;
    Papier: TPDFPaper;
  begin
    Personnage := PersonnageSansMunitions(Personnage);
    Fond1 := CheminImagePdf(GetCurrentDir + '\PICTURES\WFRPTOW\PDF\FOND-1.jpg');
    Fond2 := CheminImagePdf(GetCurrentDir + '\PICTURES\WFRPTOW\PDF\FOND-2.jpg');
    // sans la feuille officielle (PICTURES absent), on previent au lieu de sortir des valeurs sans libelles
    if not (FileExists(Fond1) and FileExists(Fond2)) then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_122') + LineEnding + 'PICTURES\WFRPTOW\PDF\');
        Exit;
      end;
    PdfChemin := GetCurrentDir + ConstCheminPersonnage + Personnage.NomPersonnage + '\' + Personnage.NomPersonnage + ' ' +
                 FormatDateTime('yyyymmdd-hhnnss', Now) + '.PDF';
    // le dossier du perso peut porter un autre nom que celui de la fiche : on le cree plutot que d'echouer
    ForceDirectories(ExtractFilePath(PdfChemin));
    if FileExists(PdfChemin) then
      if not DeleteFile(PdfChemin) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_038'));
          Exit;
        end;
    PDFDoc := TPDFDocument.Create(nil);
    try
      PDFDoc.Options := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText];
      PDFDoc.StartDocument;
      PdfSection := PDFDoc.Sections.AddSection;
      Page := PDFDoc.Pages.AddPage;
      PdfPolicesDeRepli;
      PdfFontBack  := PDFDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
      PdfFontValue := PDFDoc.AddFont(PdfCheminPolice('ariali.ttf'), ConstPoliceArial);
      PdfFontBold  := PDFDoc.AddFont(PdfCheminPolice('arialbd.ttf'), ConstPoliceArial+ConstPoliceGras);
      PdfSection.AddPage(Page);
      // feuille officielle : format letter, 612 x 792 points
      FillChar(Papier, SizeOf(Papier), 0);
      Papier.W := 612;
      Papier.H := 792;
      Page.PaperType := ptCustom;
      Page.Paper := Papier;
      Page.UnitOfMeasure := uomMillimeters;
      PdfImgFond1 := PDFDoc.Images.AddFromFile(Fond1, False);
      PdfImgFond2 := PDFDoc.Images.AddFromFile(Fond2, False);
      Page.DrawImage(0, 0, PL, PH, PdfImgFond1);
      BlocIdentite(Personnage);
      BlocCaracteristiquesCompetences(Personnage);
      BlocLores(Personnage);
      BlocTalents(Personnage);
      BlocArmesArmures(Personnage);
      BlocTrappingsContacts(Personnage);
      // page 2
      Page := PDFDoc.Pages.AddPage;
      PdfSection.AddPage(Page);
      Page.PaperType := ptCustom;
      Page.Paper := Papier;
      Page.UnitOfMeasure := uomMillimeters;
      Page.DrawImage(0, 0, PL, PH, PdfImgFond2);
      PageDeux(Personnage);
      PDFDoc.SaveToFile(PdfChemin);
    finally
      PDFDoc.Free;
    end;
    PdfPurgeAnciens(PdfChemin);
    if not PdfSansOuverture then
      OpenDocument(PdfChemin);
  end;

initialization
  PdfPersonnageTowHook := @PdfPersonnageTow;

end.

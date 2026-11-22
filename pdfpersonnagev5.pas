unit PdfPersonnageV5;

{$mode ObjFPC}{$H+}

// PDF de personnage WFRP5 : fiche dessinee entierement en code (aucune image de fond), calquee sur la
// feuille du Rulebook V5 (pages 376-377, 215 x 270 mm). Meme logique que le PDF V4 : libelles RULES-PDF_*
// traduisibles (INTERFACE*.Xml), donnees lues par les memes fonctions (PdfPersonnageAttribut / Competence / Talent).
// Page 1 : en-tete, XP, tracker de carriere, caracteristiques, Fate / Fortune, mouvement, langues,
// competences (3 colonnes, base pre-imprimees dans l'ordre officiel), talents, ambitions, blessures, points d'armure.
// GEOMETRIE : toutes les coordonnees sont en mm, ORIGINE EN HAUT A GAUCHE (comme la feuille officielle, relevee
// par TRAVAIL\geometrie_page_v5.py) ; les routines de dessin convertissent (PH - Y).
// Branche par PdfPersonnageV5Hook (pdfpersonnage.pas) : l'unite s'enregistre dans initialization.

interface

uses
  Classes, SysUtils, fpPDF, PdfUtils, PdfPersonnage, ChargeConstantes, ChargeTraduction, ChargePersonnage,
  ChargeRace, ChargeRaceAttribut, ChargeMetier, ChargeMetierNiveau, ChargeCompetence, ChargeTalent,
  ChargeArme, ChargeArmure, ChargeArmeBonus, ChargeArmureBonus, ChargeSort, ChargeArmureSimplifie, ChargeTrapping,
  ChargeAttribut, ChargeGroupe, ChargeTexte, ChargeRacePhysique, ChargeSigneAstral, ChargeCorruptionTable, ChargeTalentEffet, ChargeModificateur, ChargeFabrication, UnitCalcul, Dialogs, LCLIntf, Math, StrUtils;

Procedure PdfPersonnageV5(Personnage: StructurePersonnage);

implementation

const
  PH         = 270;     // hauteur de la feuille (mm)
  PL         = 215;     // largeur de la feuille (mm)
  XG         = 5.1;     // bord gauche des blocs
  XD         = 210.4;   // bord droit des blocs
  PoliceMin  = 5;

var
  Page: TPDFPage;
  // Option « donnees seules » (feuille officielle deja imprimee) : ni filet, ni cadre, ni libelle, ni silhouette,
  // seulement les valeurs, croix de competences de carriere et cases du tracker / de corruption cochees
  DonneesSeules: Boolean = False;

// ---------------------------------------------------------------- petits outils de dessin (Y vers le bas)

// Trait de mise en page : supprime en mode « donnees seules »
procedure Trait(X1, Y1, X2, Y2: Single; Epais: Single = 0.4);
  begin
    if DonneesSeules then Exit;
    Page.DrawLine(X1, PH - Y1, X2, PH - Y2, Epais);
  end;

// Trait qui est une DONNEE (croix d'une case) : toujours dessine
procedure TraitCroix(X1, Y1, X2, Y2: Single; Epais: Single = 0.4);
  begin
    Page.DrawLine(X1, PH - Y1, X2, PH - Y2, Epais);
  end;

// Cadre (X1,YHaut)-(X2,YBas), trait epais
procedure Cadre(X1, YHaut, X2, YBas: Single; Epais: Single = 0.7);
  begin
    Trait(X1, YHaut, X2, YHaut, Epais);
    Trait(X1, YBas,  X2, YBas,  Epais);
    Trait(X1, YHaut, X1, YBas,  Epais);
    Trait(X2, YHaut, X2, YBas,  Epais);
  end;

// Case carree (cote S), cochee = croix dedans
procedure CaseCarree(X, YHaut, S: Single; Croix: Boolean = False; Epais: Single = 0.3);
  begin
    Cadre(X, YHaut, X + S, YHaut + S, Epais);
    if Croix then
      begin
        TraitCroix(X, YHaut, X + S, YHaut + S, 0.4);
        TraitCroix(X, YHaut + S, X + S, YHaut, 0.4);
      end;
  end;

// Libelle centre en police de titre (Caslon gras) ; YBas = bas de la ligne de texte
procedure LibelleCentre(X1, X2, YBas: Single; const Code: String; Taille: Integer = 9);
  begin
    if DonneesSeules then Exit;
    PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, Taille);
    PdfCentre(Page, X1, X2, PH - YBas + 1.3, GetTexteLibelle(Code));
  end;

// Libelle cadre a gauche
procedure LibelleGauche(X1, X2, YBas: Single; const Code: String; Taille: Integer = 8);
  begin
    if DonneesSeules then Exit;
    PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, Taille);
    PdfEcrit(Page, X1 + 0.8, X2 - 0.5, PH - YBas + 1.3, GetTexteLibelle(Code), PoliceMin);
  end;

// Valeur centree (police de valeur)
procedure ValeurCentre(X1, X2, YBas: Single; const Texte: String; Taille: Integer = 9);
  begin
    PdfTaillePolice(Page, PdfFontValue, ConstPoliceArial, Taille);
    PdfCentre(Page, X1, X2, PH - YBas + 1.3, Texte);
  end;

// Valeur cadree a gauche (rapetissee si trop longue)
procedure ValeurGauche(X1, X2, YBas: Single; const Texte: String; Taille: Integer = 9);
  begin
    PdfTaillePolice(Page, PdfFontValue, ConstPoliceArial, Taille);
    PdfEcrit(Page, X1 + 0.8, X2 - 0.5, PH - YBas + 1.3, Texte, PoliceMin);
  end;

// Petit texte de police de titre, centre sur Xc, bas du texte en YBas (indications des points d'armure)
procedure TexteCentre(Xc, YBas: Single; const Texte: String; Taille: Integer);
  begin
    if DonneesSeules then Exit;
    PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, Taille);
    PdfCentre(Page, Xc - 11, Xc + 11, PH - YBas + 0.6, Texte);
  end;

// ---------------------------------------------------------------- blocs

// Nom / Espece / Apparence (haut gauche) et XP (haut droite)
procedure BlocEnteteXp(Personnage: StructurePersonnage);
  var
    PRace: StructureRace;
    Apparence: String;
    XTotal: Integer;
  begin
    PRace := ChercheRace(Personnage.Race);
    Cadre(XG, 11.5, 138.4, 25.4);
    Trait(XG, 18.5, 138.4, 18.5);
    Trait(101.5, 11.5, 101.5, 18.5);
    LibelleGauche(XG, 22, 18.5, 'RULES-PDF_MAIN1_NAME');
    LibelleGauche(90, 101.5, 18.5, 'RULES-PDF_MAIN1_SPECIES');
    LibelleGauche(XG, 22, 25.4, 'RULES-PDF_MAIN1_APPEARANCE');
    ValeurGauche(22, 90, 18.5, Personnage.NomPersonnage);
    ValeurGauche(101.5, 138.4, 18.5, PersonnageRaceLibelle(Personnage, PRace.Libelle));
    // Apparence : age, taille, cheveux, yeux (ce que WinPhysique a defini)
    Apparence := '';
    if Personnage.Age > 0 then
      Apparence := GetTexteLibelle('RULES-PDF_MAIN4_AGE') + ' ' + IntToStr(Personnage.Age);
    if Personnage.Height > 0 then
      Apparence := Apparence + IfThen(Apparence <> '', ', ', '') + GetTexteLibelle('RULES-PDF_MAIN4_HEIGHT') + ' ' +
                   FormateTaille(Personnage.Height, Personnage.HeightUnit);
    if Trim(Personnage.HairColors) <> '' then
      Apparence := Apparence + IfThen(Apparence <> '', ', ', '') + GetTexteLibelle('RULES-PDF_MAIN4_HAIR') + ' ' + Personnage.HairColors;
    if Trim(Personnage.EyeColors) <> '' then
      Apparence := Apparence + IfThen(Apparence <> '', ', ', '') + GetTexteLibelle('RULES-PDF_MAIN4_EYES') + ' ' + Personnage.EyeColors;
    ValeurGauche(22, 138.4, 25.4, Apparence, 8);

    // XP : titre a gauche, 3 colonnes Current / Spent / Total
    XTotal := Personnage.XpTotal;
    Cadre(140.3, 44.5, XD, 56.3);
    Trait(147, 44.5, 147, 56.3);
    Trait(168.4, 44.5, 168.4, 56.3);
    Trait(190.3, 44.5, 190.3, 56.3);
    Trait(147, 49.1, XD, 49.1);
    LibelleCentre(140.3, 147, 54.0, 'RULES-PDF_V5_XP', 12);
    LibelleCentre(147, 168.4, 49.1, 'RULES-PDF_XP2A_CURRENT', 7);
    LibelleCentre(168.4, 190.3, 49.1, 'RULES-PDF_XP2B_SPENT', 7);
    LibelleCentre(190.3, XD, 49.1, 'RULES-PDF_XP2C_TOTAL', 7);
    ValeurCentre(147, 168.4, 56.3, IntToStr(Personnage.XpActuel));
    ValeurCentre(168.4, 190.3, 56.3, IntToStr(XTotal - Personnage.XpActuel));
    ValeurCentre(190.3, XD, 56.3, IntToStr(XTotal));
  end;

// Une case du tracker (carre 2.4 mm), cochee = remplie
procedure CaseTracker(X, YHaut: Single; Cochee: Boolean);
  var
    Coin: TPDFCoord;
  begin
    if DonneesSeules and not Cochee then Exit;   // la case vide est deja sur la feuille
    Coin.X := X;
    Coin.Y := PH - YHaut - 2.1;
    Page.SetColor(clBlack, True);
    Page.DrawRect(Coin, 2.1, 2.1, 0.25, Cochee, True, 0);
    Page.SetColor(clBlack, False);
  end;

// Classe / Carriere / Tracker / Statut : une ligne par carriere (au plus 3, la carriere en cours en dernier)
procedure BlocCarriere(Personnage: StructurePersonnage);
  const
    NbCases: array[1..3] of Integer = (10, 12, 14);
    YEntete = 34.1;
    HauteurLigne = 7.4;
    XClasse = 24.9;
    XCarriere = 56.5;
    XTracker = 119.5;
    Pas = 2.7;
  var
    Codes: TStringList;
    PersonnageMetier: StructurePersonnageMetier;
    PMetier: StructureMetier;
    PMetierNiveau: StructureMetierNiveau;
    I, Niv, K, PerLigne, Debut, Rang: Integer;
    YLigne, X: Single;
    EnCours: Boolean;
    Cochees: Integer;
  begin
    Cadre(XG, 28.1, 138.4, YEntete + 3 * HauteurLigne);
    Trait(XG, YEntete, 138.4, YEntete);
    for I := 1 to 2 do
      Trait(XG, YEntete + I * HauteurLigne, 138.4, YEntete + I * HauteurLigne);
    Trait(XClasse, 28.1, XClasse, YEntete + 3 * HauteurLigne);
    Trait(XCarriere, 28.1, XCarriere, YEntete + 3 * HauteurLigne);
    Trait(XTracker, 28.1, XTracker, YEntete + 3 * HauteurLigne);
    LibelleGauche(XG, XClasse, YEntete, 'RULES-PDF_MAIN1_CLASS');
    LibelleGauche(XClasse, 51, YEntete, 'RULES-PDF_MAIN2_CAREER');
    LibelleGauche(XCarriere, XTracker, YEntete, 'RULES-PDF_V5_TRACKER');
    LibelleGauche(XTracker, 138.4, YEntete, 'RULES-PDF_MAIN3_STATUS');

    // carrieres distinctes, anciennes puis en cours ; on garde les 3 dernieres
    Codes := TStringList.Create;
    try
      for PersonnageMetier in Personnage.MetierAncien do
        if (Codes.IndexOf(PersonnageMetier.CodeMetier) < 0) and
           (PersonnageMetier.CodeMetier <> Personnage.MetierEnCours.CodeMetier) then
          Codes.Add(PersonnageMetier.CodeMetier);
      Codes.Add(Personnage.MetierEnCours.CodeMetier);
      Debut := Max(0, Codes.Count - 3);
      for Rang := 0 to 2 do
        begin
          YLigne := YEntete + Rang * HauteurLigne;
          // le tracker est imprime meme sur une ligne sans carriere
          EnCours := (Debut + Rang = Codes.Count - 1);
          if Debut + Rang <= Codes.Count - 1 then
            begin
              PMetier := ChercheMetier(Codes[Debut + Rang]);
              ValeurGauche(XG, XClasse, YLigne + HauteurLigne - 1.5, GetTexteLibelle(PMetier.LibelleGroupe), 8);
              ValeurGauche(XClasse, XCarriere, YLigne + HauteurLigne - 1.5, PMetier.Libelle, 8);
              if EnCours then
                begin
                  PMetierNiveau := ChercheMetierNiveau(PMetier.CodeMetier, Personnage.MetierEnCours.NiveauMetier);
                  ValeurGauche(XTracker, 138.4, YLigne + HauteurLigne - 1.5,
                    GetTexteLibelle('RULES-' + StatutAdapte(PMetierNiveau.SalaireMetier, PMetier.CodeMetier,
                      Personnage.Race, Personnage.ChoixAdaptation), '', ' '), 8);
                end;
            end
          else
            EnCours := False;
          // tracker : trois niveaux (10 / 12 / 14 cases sur deux rangs) separes par un repere 2 / 3 / 4
          X := 57.7;
          for Niv := 1 to 3 do
            begin
              PerLigne := NbCases[Niv] div 2;
              if EnCours then
                Cochees := TrackerCompte(Personnage, Niv)
              else
                Cochees := 0;
              for K := 0 to NbCases[Niv] - 1 do
                CaseTracker(X + (K mod PerLigne) * Pas, YLigne + 1.0 + (K div PerLigne) * 2.9, K < Cochees);
              X := X + PerLigne * Pas + 0.2;
              // repere du niveau suivant (pre-imprime sur la feuille officielle)
              if not DonneesSeules then
                begin
                  Page.SetColor(clBlack, True);
                  PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 9);
                  PdfCentre(Page, X, X + 3.6, PH - (YLigne + 5.0), IntToStr(Niv + 1));
                end;
              X := X + 3.6;
            end;
        end;
    finally
      Codes.Free;
    end;
  end;

// Caracteristiques : Initial / Advances / Current sur 10 colonnes
procedure BlocCaracteristiques(Personnage: StructurePersonnage);
  const
    XDeb = 25.3;
    Larg = 8.3;
  var
    I: Integer;
    D: StructureDonnee;
    Bonus: String;
    PAttribut: StructureAttribut;
  begin
    Cadre(XG, 58.8, 108.4, 85.8);
    Trait(XG, 70.6, 108.4, 70.6);
    Trait(XG, 75.6, 108.4, 75.6);
    Trait(XG, 80.6, 108.4, 80.6);
    for I := 0 to 9 do
      Trait(XDeb + I * Larg, 65.5, XDeb + I * Larg, 85.8);
    LibelleCentre(XG, 108.4, 65.0, 'RULES-PDF_CHARAC1_CHARAC', 10);
    LibelleGauche(XG, XDeb, 75.6, 'RULES-PDF_CHARAC3_INITIAL', 7);
    LibelleGauche(XG, XDeb, 80.6, 'RULES-PDF_CHARAC3_ADVANCES', 7);
    LibelleGauche(XG, XDeb, 85.8, 'RULES-PDF_CHARAC3_CURRENT', 7);
    for I := 0 to 9 do
      begin
        PAttribut := ListeAttribut[I];
        if not DonneesSeules then
          begin
            PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 8);
            PdfCentre(Page, XDeb + I * Larg, XDeb + (I + 1) * Larg, PH - 70.6 + 1.3, GetTexteLibelle(PAttribut.Resume));
          end;
        D := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
        ValeurCentre(XDeb + I * Larg, XDeb + (I + 1) * Larg, 75.6, IntToStr(D.Base));
        if D.Augmentation <> 0 then
          ValeurCentre(XDeb + I * Larg, XDeb + (I + 1) * Larg, 80.6, IntToStr(D.Augmentation));
        ValeurCentre(XDeb + I * Larg, XDeb + (I + 1) * Larg, 85.8, IntToStr(D.Total));
      end;
  end;

// Fate / Fortune et Mouvement
procedure BlocFateFortuneMouvement(Personnage: StructurePersonnage; Mouv, BonusSprint: Integer);
  const
    X1 = 108.4;
    X2 = 150.4;
    XWalk = 124.3;
    XRun = 138.5;
  var
    D: StructureDonnee;
    Bonus: String;
  begin
    Cadre(X1, 58.8, X2, 85.8);
    Trait(X1, 65.6, X2, 65.6);
    Trait(X1, 76.1, X2, 76.1);
    Trait(X1, 80.3, X2, 80.3);
    Trait(XWalk, 76.1, XWalk, 85.8);
    Trait(XRun, 76.1, XRun, 85.8);
    // Fate
    LibelleGauche(X1, 125, 65.6, 'RULES-PDF_FATE2_FATE');
    D := PdfPersonnageAttribut(Personnage, ConstCaracDestin, Bonus);
    ValeurCentre(125, X2, 65.6, IntToStr(D.Total), 11);
    // Fortune : courante / maximum (le maximum = valeur de l'attribut), separes par la barre oblique
    LibelleGauche(X1, 128, 71.0, 'RULES-PDF_FATE3_FORTUNE');
    D := PdfPersonnageAttribut(Personnage, ConstCaracFortune, Bonus);
    Trait(138, 75.0, 133, 66.8);
    ValeurCentre(138, X2, 75.8, IntToStr(D.Total), 11);
    // Mouvement
    if not DonneesSeules then
      begin
        PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 6);
        PdfCentre(Page, X1, XWalk, PH - 80.3 + 1.3, GetTexteLibelle('RULES-PDF_MV2A_MOVEMENT'));
        PdfCentre(Page, XWalk, XRun, PH - 80.3 + 1.3, GetTexteLibelle('RULES-PDF_MV2B_WALK'));
        PdfCentre(Page, XRun, X2, PH - 80.3 + 1.3, GetTexteLibelle('RULES-PDF_MV2C_RUN'));
      end;
    ValeurCentre(X1, XWalk, 85.8, IntToStr(Mouv));
    ValeurCentre(XWalk, XRun, 85.8, IntToStr(Mouv * 2));
    ValeurCentre(XRun, X2, 85.8, IntToStr((Mouv + BonusSprint) * 4));
  end;

// Langues connues : competences de langue du personnage, trois lignes
procedure BlocLangues(Personnage: StructurePersonnage);
  const
    X1 = 151;
    NbLignes = 3;
    H = 6.0;
    YLignes = 67.9;
    XInt = 187;
    XAdv = 194.8;
    XSkill = 202.3;
  var
    I, Nb: Integer;
    PCompetence: StructureCompetence;
    D: StructureDonnee;
    DInt: StructureDonnee;
    Bonus: String;
    Bidon: Integer;
    Y: Single;
  begin
    Bidon := 0;
    Cadre(X1, 58.8, XD, 85.8);
    Trait(X1, 63.7, XD, 63.7);
    Trait(X1, YLignes, XD, YLignes);
    for I := 1 to NbLignes - 1 do
      Trait(X1, YLignes + I * H, XD, YLignes + I * H, 0.2);
    Trait(XInt, 63.7, XInt, 85.8);
    Trait(XAdv, 63.7, XAdv, 85.8);
    Trait(XSkill, 63.7, XSkill, 85.8);
    LibelleCentre(X1, XD, 63.5, 'RULES-PDF_V5_LANGUAGES', 9);
    LibelleCentre(X1, XInt, YLignes, 'RULES-PDF_SKILLS2_NAME', 6);
    LibelleCentre(XInt, XAdv, YLignes, 'RULES-PDF_V5_INT', 6);
    LibelleCentre(XAdv, XSkill, YLignes, 'RULES-PDF_SKILLS2_ADV', 6);
    LibelleCentre(XSkill, XD, YLignes, 'RULES-PDF_SKILLS2_SKILL', 6);
    for I := 0 to NbLignes - 1 do
      CaseCarree(X1 + 2.3, YLignes + I * H + 1.6, 2.8);
    DInt := PdfPersonnageAttribut(Personnage, ConstCaracInt, Bonus);
    Nb := 0;
    for PCompetence in ListCompetence do
      if (Pos('RULES-COMP_LANGUAGE__', PCompetence.CodeCompetence) = 1) and (Nb < NbLignes) then
        begin
          D := PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, Bidon);
          if (D.Total <> DInt.Total) or (D.Augmentation <> 0) then
            begin
              Y := YLignes + (Nb + 1) * H;
              ValeurGauche(X1 + 7, XInt, Y, PdfSupprimeGenerique(PCompetence.CodeCompetence, PCompetence.Libelle), 8);
              ValeurCentre(XInt, XAdv, Y, IntToStr(D.Base), 8);
              if D.Augmentation <> 0 then
                ValeurCentre(XAdv, XSkill, Y, IntToStr(D.Augmentation), 8);
              ValeurCentre(XSkill, XD, Y, IntToStr(D.Total), 8);
              Inc(Nb);
            end;
        end;
  end;

// ---- competences

// Specialisation APPRISE (avance <> 0) d'une competence generique, non encore imprimee
function SpecialisationApprise(Personnage: StructurePersonnage; const CodeGen: String; Utilises: TStringList;
  out Code: String; out D: StructureDonnee): Boolean;
  var
    PCompetence: StructureCompetence;
    Bidon: Integer;
    Trouve: Boolean;
  begin
    Bidon := 0;
    Trouve := False;
    Code := '';
    for PCompetence in ListCompetence do
      if (not Trouve) and (PCompetence.CodeGenerique = CodeGen) and (Pos('__BASIC', PCompetence.CodeCompetence) = 0) and
         (Utilises.IndexOf(PCompetence.CodeCompetence) < 0) then
        begin
          D := PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, Bidon);
          if D.Augmentation <> 0 then
            begin
              Code := PCompetence.CodeCompetence;
              Trouve := True;
            end;
        end;
    if (not Trouve) and (ListCompetencePerso <> nil) then
      for PCompetence in ListCompetencePerso do
        if (not Trouve) and (PCompetence.CodeGenerique = CodeGen) and (Pos('__BASIC', PCompetence.CodeCompetence) = 0) and
           (Utilises.IndexOf(PCompetence.CodeCompetence) < 0) then
          begin
            D := PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, Bidon);
            if D.Augmentation <> 0 then
              begin
                Code := PCompetence.CodeCompetence;
                Trouve := True;
              end;
          end;
    if Trouve then
      Utilises.Add(Code);
    Result := Trouve;
  end;

// Texte entre parentheses d'un libelle de specialisation ("Art (Painting)" -> "Painting")
function DansParentheses(const Libelle: String): String;
  var
    P, Q: Integer;
  begin
    P := Pos('(', Libelle);
    Q := RPos(')', Libelle);
    if (P > 0) and (Q > P) then
      Result := Copy(Libelle, P + 1, Q - P - 1)
    else
      Result := Libelle;
  end;

type
  // Geometrie d'une colonne de competences (mm, origine en haut a gauche)
  TColonneComp = record
    X1, X2: Single;          // bords de la colonne
    XCase: Single;           // case a cocher
    XNom, XCar, XAdv, XSk: Single;  // debut des colonnes Nom / Caracteristique / Adv / Skill
    YLibelleBas: Single;     // bas des libelles d'en-tete
    YLignes: Single;         // haut de la premiere ligne
    H: Single;               // hauteur d'une ligne
    NbLignes: Integer;
    Preimprime: Boolean;     // noms et caracteristiques deja imprimes sur la feuille (colonnes de base)
    XSpec: Single;           // « donnees seules » : debut de la specialisation, apres « Art* ( » pre-imprime
  end;

// Une colonne de competences : en-tete (Nom / Caracteristique / Adv / Skill) + lignes ; Codes = competences
// imprimees (un code finissant par "__*" = ligne de specialisation a remplir)
procedure ColonneCompetences(Personnage: StructurePersonnage; PMetier: StructureMetier; const C: TColonneComp;
  Codes: TStringList; Utilises: TStringList);
  var
    I: Integer;
    PCompetence, PGen: StructureCompetence;
    PAttribut: StructureAttribut;
    D: StructureDonnee;
    Bidon: Integer;
    Y, YBas: Single;
    Code, Nom, CodeAtt: String;
    Generique, Appris: Boolean;
  begin
    Bidon := 0;
    // en-tete
    LibelleCentre(C.XNom, C.XCar, C.YLibelleBas, 'RULES-PDF_SKILLS2_NAME', 6);
    LibelleCentre(C.XCar, C.XAdv, C.YLibelleBas, 'RULES-PDF_SKILLS2_CHARAC', 6);
    LibelleCentre(C.XAdv, C.XSk, C.YLibelleBas, 'RULES-PDF_SKILLS2_ADV', 6);
    LibelleCentre(C.XSk, C.X2, C.YLibelleBas, 'RULES-PDF_SKILLS2_SKILL', 6);
    Trait(C.X1, C.YLignes, C.X2, C.YLignes);
    // grille
    for I := 1 to C.NbLignes do
      Trait(C.X1, C.YLignes + I * C.H, C.X2, C.YLignes + I * C.H, 0.15);
    Trait(C.XCar, C.YLignes, C.XCar, C.YLignes + C.NbLignes * C.H, 0.15);
    Trait(C.XAdv, C.YLignes, C.XAdv, C.YLignes + C.NbLignes * C.H, 0.15);
    Trait(C.XSk,  C.YLignes, C.XSk,  C.YLignes + C.NbLignes * C.H, 0.15);
    // lignes
    for I := 0 to C.NbLignes - 1 do
      begin
        Y := C.YLignes + I * C.H;
        YBas := Y + C.H;
        Code := '';
        if I < Codes.Count then
          Code := Codes[I];
        Appris := False;
        Generique := (Length(Code) > 3) and (Copy(Code, Length(Code) - 2, 3) = '__*');
        if Code = '' then
          begin
            CaseCarree(C.XCase, Y + (C.H - 2.8) / 2, 2.8);
            Continue;
          end;
        if Generique then
          begin
            // ligne de specialisation : nom du generique + "*", puis la specialisation apprise (sinon des parentheses vides)
            PGen := ChercheCompetence(Code);
            PAttribut := ChercheAttribut(PGen.CodeAttribut);
            Nom := Trim(PdfSupprimeGenerique(Code, PGen.Libelle)) + '*';
            Appris := SpecialisationApprise(Personnage, Code, Utilises, CodeAtt, D);
            CaseCarree(C.XCase, Y + (C.H - 2.8) / 2, 2.8, False);
            if Appris then
              begin
                PCompetence := ChercheCompetence(CodeAtt);
                if DonneesSeules then
                  ValeurGauche(C.XSpec - 0.8, C.XCar - 3, YBas, DansParentheses(PCompetence.Libelle), 8)
                else
                  ValeurGauche(C.XNom - 0.8, C.XCar, YBas, Nom + ' (' + DansParentheses(PCompetence.Libelle) + ')', 8);
                if D.Augmentation <> 0 then
                  ValeurCentre(C.XAdv, C.XSk, YBas, IntToStr(D.Augmentation), 8);
                ValeurCentre(C.XSk, C.X2, YBas, IntToStr(D.Total), 8);
                if CompareCompetence(PCompetence.CodeCompetence, PMetier.CodeCompetence) or
                   CompareCompetence(PGen.CodeCompetence, PMetier.CodeCompetence) then
                  begin
                    TraitCroix(C.XCase, Y + (C.H - 2.8) / 2, C.XCase + 2.8, Y + (C.H - 2.8) / 2 + 2.8, 0.4);
                    TraitCroix(C.XCase, Y + (C.H - 2.8) / 2 + 2.8, C.XCase + 2.8, Y + (C.H - 2.8) / 2, 0.4);
                  end;
              end
            else if not DonneesSeules then
              begin
                PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 8);
                PdfEcrit(Page, C.XNom, C.XCar, PH - YBas + 1.3, Nom + ' (', PoliceMin);
                PdfCentre(Page, C.XCar - 3, C.XCar - 0.5, PH - YBas + 1.3, ')');
              end;
          end
        else
          begin
            PCompetence := ChercheCompetence(Code);
            D := PdfPersonnageCompetence(Personnage, Code, Bidon);
            CodeAtt := PCompetence.CodeAttribut;
            if CodeAtt = '' then
              CodeAtt := ChercheCompetence(PCompetence.CodeGenerique).CodeAttribut;
            PAttribut := ChercheAttribut(CodeAtt);
            Utilises.Add(Code);
            CaseCarree(C.XCase, Y + (C.H - 2.8) / 2, 2.8,
                       CompareCompetence(PCompetence.CodeCompetence, PMetier.CodeCompetence));
            if not (DonneesSeules and C.Preimprime) then
              ValeurGauche(C.XNom - 0.8, C.XCar, YBas, PdfSupprimeGenerique(PCompetence.CodeCompetence, PCompetence.Libelle), 8);
            if D.Augmentation <> 0 then
              ValeurCentre(C.XAdv, C.XSk, YBas, IntToStr(D.Augmentation), 8);
            ValeurCentre(C.XSk, C.X2, YBas, IntToStr(D.Total), 8);
          end;
        // caracteristique (en police de titre)
        if (PAttribut.CodeAttribut <> '') and not (DonneesSeules and C.Preimprime) then
          begin
            PdfTaillePolice(Page, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 8);
            PdfCentre(Page, C.XCar, C.XAdv, PH - YBas + 1.3, GetTexteLibelle(PAttribut.Resume));
          end;
      end;
  end;

// Les trois colonnes de competences : base pre-imprimees dans l'ordre de la feuille officielle, puis avancees apprises
procedure BlocCompetences(Personnage: StructurePersonnage; PMetier: StructureMetier);
  const
    Col1: array[0..13] of String = (
      'RULES-COMP_ART__*', 'RULES-COMP_ATHLETICS', 'RULES-COMP_BRIBERY', 'RULES-COMP_CHARM', 'RULES-COMP_CHARM_ANIMAL',
      'RULES-COMP_CLIMB', 'RULES-COMP_CONSUME_ALCOHOL', 'RULES-COMP_COOL', 'RULES-COMP_DODGE', 'RULES-COMP_DRIVE',
      'RULES-COMP_ENDURANCE', 'RULES-COMP_ENTERTAIN__*', 'RULES-COMP_GAMBLE', 'RULES-COMP_GOSSIP');
    Col2: array[0..14] of String = (
      'RULES-COMP_HAGGLE', 'RULES-COMP_INTIMIDATE', 'RULES-COMP_INTUITION', 'RULES-COMP_LEADERSHIP',
      'RULES-COMP_MELEE__*', 'RULES-COMP_MELEE__*', 'RULES-COMP_MELEE__BASIC', 'RULES-COMP_NAVIGATION',
      'RULES-COMP_OUTDOOR_SURVIVAL', 'RULES-COMP_PERCEPTION', 'RULES-COMP_RIDE__*', 'RULES-COMP_ROW',
      'RULES-COMP_STEALTH__RURAL', 'RULES-COMP_STEALTH__URBAN', 'RULES-COMP_STEALTH__UNDERGROUND');
  var
    L1, L2, L3, Utilises: TStringList;
    C: TColonneComp;
    I: Integer;
    PCompetence: StructureCompetence;
    D: StructureDonnee;
    Bidon: Integer;
  begin
    Bidon := 0;
    L1 := TStringList.Create;
    L2 := TStringList.Create;
    L3 := TStringList.Create;
    Utilises := TStringList.Create;
    try
      for I := 0 to High(Col1) do L1.Add(Col1[I]);
      for I := 0 to High(Col2) do L2.Add(Col2[I]);
      // cadre general et separateurs de colonnes
      Cadre(XG, 87.7, XD, 167.6);
      Trait(74.2, 87.7, 74.2, 167.6);
      Trait(140.9, 87.7, 140.9, 167.6);
      LibelleCentre(XG, 74.2, 93.6, 'RULES-PDF_V5_SKILLS', 11);
      // colonne 1 (base, a partir de la ligne 98.6)
      C.X1 := XG; C.X2 := 74.2; C.XCase := 8.5; C.XNom := 13.0; C.XCar := 39.7; C.XAdv := 57.8; C.XSk := 66.0;
      C.YLibelleBas := 98.0; C.YLignes := 98.6; C.H := 4.84; C.NbLignes := 14;
      C.Preimprime := True; C.XSpec := 19.2;
      ColonneCompetences(Personnage, PMetier, C, L1, Utilises);
      // colonne 2 (base)
      C.X1 := 74.2; C.X2 := 140.9; C.XCase := 76.4; C.XNom := 80.5; C.XCar := 107.3; C.XAdv := 124.0; C.XSk := 131.2;
      C.YLibelleBas := 92.4; C.YLignes := 93.2; C.H := 4.84; C.NbLignes := 15;
      C.Preimprime := True; C.XSpec := 90.5;
      ColonneCompetences(Personnage, PMetier, C, L2, Utilises);
      // colonne 3 : competences avancees apprises (jamais de base, jamais de langue)
      for PCompetence in ListCompetence do
        if (not PCompetence.DeBase) and (Utilises.IndexOf(PCompetence.CodeCompetence) < 0) and
           (L3.IndexOf(PCompetence.CodeCompetence) < 0) and (Pos('RULES-COMP_LANGUAGE__', PCompetence.CodeCompetence) <> 1) and
           (Copy(PCompetence.CodeCompetence, Length(PCompetence.CodeCompetence) - 2, 3) <> '__*') then
          begin
            D := PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, Bidon);
            if D.Augmentation <> 0 then
              L3.Add(PCompetence.CodeCompetence);
          end;
      C.X1 := 140.9; C.X2 := XD; C.XCase := 142.6; C.XNom := 148.0; C.XCar := 176.5; C.XAdv := 193.5; C.XSk := 200.5;
      C.YLibelleBas := 92.4; C.YLignes := 93.2; C.H := 6.09; C.NbLignes := 12;
      C.Preimprime := False; C.XSpec := C.XNom;
      ColonneCompetences(Personnage, PMetier, C, L3, Utilises);
    finally
      L1.Free; L2.Free; L3.Free; Utilises.Free;
    end;
  end;

// Talents : nom / description / page
procedure BlocTalents(Personnage: StructurePersonnage);
  const
    X2 = 100.6;
    XNom = 37.5;
    XPage = 91.5;
    YLignes = 183.3;
    NbLignes = 11;
    H = 5.9;
  var
    I, Nb, Bidon: Integer;
    PTalent, PGenerique: StructureTalent;
    D: StructureDonnee;
    Y: Single;
    Nom: String;
  begin
    Bidon := 0;
    Cadre(XG, 168.9, X2, YLignes + NbLignes * H);
    LibelleCentre(XG, X2, 175.6, 'RULES-PDF_TALENT1_TALENTS', 11);
    Trait(XG, YLignes, X2, YLignes);
    for I := 1 to NbLignes - 1 do
      Trait(XG, YLignes + I * H, X2, YLignes + I * H, 0.15);
    Trait(XNom, YLignes, XNom, YLignes + NbLignes * H, 0.15);
    Trait(XPage, YLignes, XPage, YLignes + NbLignes * H, 0.15);
    LibelleCentre(XG, XNom, 182.3, 'RULES-PDF_TALENT2_TALENTNAME', 6);
    LibelleCentre(XNom, XPage, 182.3, 'RULES-PDF_TALENT2_DESC', 6);
    Nb := 0;
    for PTalent in ListTalent do
      begin
        D := PdfPersonnageTalent(Personnage, PTalent.CodeTalent, Bidon);
        if (D.Total <> 0) and (Nb < NbLignes) then
          begin
            Y := YLignes + (Nb + 1) * H;
            Nom := PTalent.Libelle;
            if D.Total > 1 then
              Nom := Nom + ' ' + IntToStr(D.Total);
            ValeurGauche(XG, XNom, Y, Nom, 8);
            PGenerique := PTalent;
            if PTalent.SousTalent then
              PGenerique := ChercheTalent(CodeTalentGenerique(PTalent));
            ValeurGauche(XNom, XPage, Y, PGenerique.Resume, 7);
            Inc(Nb);
          end;
      end;
  end;

// Texte d'une ambition, precede de son titre (« Short-term: ») sauf en mode « donnees seules »
function AmbitionAvecTitre(const CodeA, CodeB, Texte: String): String;
  begin
    if DonneesSeules then
      Result := Texte
    else
      Result := GetTexteLibelle(CodeA) + GetTexteLibelle(CodeB) + ' ' + Texte;
  end;

// Ambitions personnelle et de groupe, blessures actuelles
procedure BlocAmbitionsBlessures(Personnage: StructurePersonnage; BF, BE, BFM, DurACuire, BonusBlessureFab: Integer);
  const
    X1 = 103.0;
    X2 = 152.7;
  var
    GroupeComplet: StructureGroupe;
    Court, Long_: String;
    PRaceAttribut: StructureRaceAttribut;
    I: Integer;
    Lib: array[0..4] of String;
    Val_: array[0..4] of String;
    Bornes: array[0..5] of Single;
  begin
    if Personnage.GroupeId <> '' then
      begin
        GroupeComplet := ChargeGroupeComplet(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId);
        Court := GroupeComplet.AmbitionCourt;
        Long_ := GroupeComplet.AmbitionLong;
      end
    else
      begin
        Court := Personnage.AmbitionGroupeCourt;
        Long_ := Personnage.AmbitionGroupeLong;
      end;
    // Une seule boite : ambition personnelle (haut) et de groupe (bas), chacune avec un titre et deux lignes
    Cadre(X1, 168.9, X2, 207.2);
    LibelleCentre(X1, X2, 175.8, 'RULES-PDF_V5_PERSONALAMBITION', 10);
    Trait(X1, 176.3, X2, 176.3);
    Trait(X1, 181.6, X2, 181.6, 0.15);
    Trait(X1, 186.4, X2, 186.4, 0.15);
    // « donnees seules » : la feuille officielle n'imprime pas « Short-term / Long-term », on n'ecrit que le texte
    ValeurGauche(X1, X2, 181.6, AmbitionAvecTitre('RULES-PDF_AMBITION2A_SHORT', 'RULES-PDF_AMBITION2B_SHORT', Personnage.AmbitionCourt), 7);
    ValeurGauche(X1, X2, 186.4, AmbitionAvecTitre('RULES-PDF_AMBITION3A_LONG', 'RULES-PDF_AMBITION3B_LONG', Personnage.AmbitionLong), 7);
    LibelleCentre(X1, X2, 192.8, 'RULES-PDF_V5_PARTYAMBITION', 10);
    Trait(X1, 193.5, X2, 193.5);
    Trait(X1, 198.6, X2, 198.6, 0.15);
    Trait(X1, 203.2, X2, 203.2, 0.15);
    ValeurGauche(X1, X2, 198.6, AmbitionAvecTitre('RULES-PDF_AMBITION2A_SHORT', 'RULES-PDF_AMBITION2B_SHORT', Court), 7);
    ValeurGauche(X1, X2, 203.2, AmbitionAvecTitre('RULES-PDF_AMBITION3A_LONG', 'RULES-PDF_AMBITION3B_LONG', Long_), 7);

    // Blessures actuelles : SB / TBx2 / WPB / Hardy / Total
    Cadre(X1, 209.5, X2, 248.2);
    LibelleCentre(X1, X2, 215.8, 'RULES-PDF_V5_CURRENTWOUNDS', 10);
    Trait(X1, 237.6, X2, 237.6);
    Trait(X1, 242.2, X2, 242.2);
    Bornes[0] := X1; Bornes[1] := 113.0; Bornes[2] := 121.0; Bornes[3] := 131.0; Bornes[4] := 140.5; Bornes[5] := X2;
    for I := 1 to 4 do
      Trait(Bornes[I], 237.6, Bornes[I], 248.2);
    Lib[0] := 'RULES-PDF_WOUNDS2_SB';   Val_[0] := IntToStr(Floor(BF / 10));
    Lib[1] := 'RULES-PDF_WOUNDS3_TBX2'; Val_[1] := IntToStr(Floor(BE / 10) * 2);
    Lib[2] := 'RULES-PDF_WOUNDS4_WPB';  Val_[2] := IntToStr(Floor(BFM / 10));
    Lib[3] := 'RULES-PDF_WOUNDS5_HARDY';
    if DurACuire > 0 then Val_[3] := IntToStr(DurACuire) else Val_[3] := '';
    PRaceAttribut := ChercheRaceAttribut(Personnage.Race, ConstCaracBlessure);
    Lib[4] := 'RULES-PDF_WOUNDS6_WOUNDS';
    Val_[4] := IntToStr(CalculBlessure(PRaceAttribut.CalculRace, BF, BE, BFM) + DurACuire + BonusBlessureFab);
    for I := 0 to 4 do
      begin
        LibelleCentre(Bornes[I], Bornes[I + 1], 242.2, Lib[I], 6);
        ValeurCentre(Bornes[I], Bornes[I + 1], 248.2, Val_[I], 9);
      end;
  end;

// Points d'armure : silhouette, six cases par zone de coup + ecu (valeurs a remplir par l'equipement plus tard)
procedure BlocPointsArmure(Personnage: StructurePersonnage; PdfImgShadow: Integer);
  var
    Tete, Bras, Corps, Jambes, Bouclier, IndLoca: Integer;
    Eq: StructurePersonnageEquipement;
    PArmure: StructureArmure;
    PArmSimp: StructureArmureSimplifiee;
    Loc: String;
  procedure Zone(X, YHaut: Single; const Plage, Nom1, Nom2: String; YPlage, YNom1, YNom2: Single; Points: Integer);
    begin
      CaseCarree(X, YHaut, 7.8, False, 0.5);
      if Points > 0 then ValeurCentre(X, X + 7.8, YHaut + 5.6, IntToStr(Points), 11);
      TexteCentre(X + 3.9, YPlage, Plage, 7);
      if Nom1 <> '' then TexteCentre(X + 3.9, YNom1, GetTexteLibelle(Nom1), 7);
      if Nom2 <> '' then TexteCentre(X + 3.9, YNom2, GetTexteLibelle(Nom2), 4);
    end;
  begin
    // Points portes par zone : armures PORTEES (meme regle que le PDF V4) + modificateurs (mutation, talent, fabrication)
    Tete := 0; Bras := 0; Corps := 0; Jambes := 0;
    for Eq in Personnage.Equipement do
      if Eq.Porte then
        begin
          if Eq.TypeEquipement = TypeEquipAR then
            begin
              PArmure := ChercheArmure(Eq.CodeEquipement);
              for IndLoca := 1 to CountOccurrences(PArmure.Emplacement, ',') + 1 do
                begin
                  Loc := ExtractChaine(',', PArmure.Emplacement, IndLoca);
                  if CompareRechercheValeur(Loc, BonusBras) then Bras := Bras + PArmure.Protection
                  else if CompareRechercheValeur(Loc, BonusCorps) then Corps := Corps + PArmure.Protection
                  else if CompareRechercheValeur(Loc, BonusJambes) then Jambes := Jambes + PArmure.Protection
                  else if CompareRechercheValeur(Loc, BonusTete) then Tete := Tete + PArmure.Protection;
                end;
            end
          else if Eq.TypeEquipement = TypeEquipARS then
            begin
              PArmSimp := ChercheArmureSimplifiee(Eq.CodeEquipement);
              Tete := Tete + PArmSimp.Protection; Bras := Bras + PArmSimp.Protection;
              Corps := Corps + PArmSimp.Protection; Jambes := Jambes + PArmSimp.Protection;
            end;
        end;
    Tete := Tete + PdfPersonnageArmureModif(Personnage, BonusTete);
    Bras := Bras + PdfPersonnageArmureModif(Personnage, BonusBras);
    Corps := Corps + PdfPersonnageArmureModif(Personnage, BonusCorps);
    Jambes := Jambes + PdfPersonnageArmureModif(Personnage, BonusJambes);
    Bouclier := PdfPersonnageArmureModif(Personnage, BonusBouclier);
    Cadre(154.1, 168.9, XD, 262.0);
    LibelleCentre(154.1, XD, 175.3, 'RULES-PDF_ARMOURPOINT_ARMOURPOINT', 11);
    // silhouette : calee sur la feuille officielle (mesure a la superposition, 14/11 : 13 % plus haute, 0,6 mm a gauche)
    if not DonneesSeules then
      Page.DrawImage(148.6, PH - 255.6, 51.9, 84.9, PdfImgShadow);
    Zone(157.3, 177.2, '01-09', 'RULES-PDF_ARMOURPOINT_HEAD', '', 176.7, 189.8, 0, Tete);
    Zone(199.8, 190.0, '10-24', 'RULES-PDF_ARMOURPOINT_LEFTARM1', 'RULES-PDF_ARMOURPOINT_LEFTARM2', 189.8, 203.3, 205.1, Bras);
    Zone(157.3, 198.8, '25-44', 'RULES-PDF_ARMOURPOINT_RIGHTARM1', 'RULES-PDF_ARMOURPOINT_RIGHTARM2', 198.5, 211.4, 213.1, Bras);
    Zone(199.8, 211.8, '45-79', 'RULES-PDF_ARMOURPOINT_BODY', '', 211.8, 224.9, 0, Corps);
    Zone(157.3, 224.2, '90-00', 'RULES-PDF_ARMOURPOINT_RIGHTLEG', '', 224.2, 237.8, 0, Jambes);
    Zone(199.8, 237.6, '80-89', 'RULES-PDF_ARMOURPOINT_LEFTLEG', '', 237.6, 250.8, 0, Jambes);
    if Bouclier > 0 then ValeurCentre(156.5, 166.1, 249.0, IntToStr(Bouclier), 10);
    // ecu
    Trait(156.5, 242.5, 166.1, 242.5, 0.5);
    Trait(156.5, 242.5, 156.5, 249.0, 0.5);
    Trait(166.1, 242.5, 166.1, 249.0, 0.5);
    Trait(156.5, 249.0, 161.3, 254.2, 0.5);
    Trait(166.1, 249.0, 161.3, 254.2, 0.5);
    TexteCentre(161.3, 259.2, GetTexteLibelle('RULES-PDF_ARMOURPOINT_SHIELD'), 7);
  end;

// ---------------------------------------------------------------- page 1

procedure PagePremiere(Personnage: StructurePersonnage; PMetier: StructureMetier; PdfImgShadow: Integer);
  var
    Mouv, BonusSprint, Ind, DurACuire, BonusBlessureFab, BF, BE, BFM: Integer;
    PRaceAttribut: StructureRaceAttribut;
    PAttribut: StructureAttribut;
    D: StructureDonnee;
    Bonus: String;
  begin
    // Mouvement : valeur de l'espece + modificateurs (meme calcul que le PDF V4)
    PRaceAttribut := ChercheRaceAttribut(Personnage.Race, ConstCaracMouvement);
    Mouv := StrToIntDef(PRaceAttribut.CalculRace, 0)
          + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracMouvement)
          + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracMouvement);
    BonusSprint := PersonnageTalentEffet(Personnage, ConstCibleEffetBonusSprint);
    // Bonus de Force / Endurance / Force mentale pour les blessures
    BF := 0; BE := 0; BFM := 0;
    for Ind := 0 to 9 do
      begin
        PAttribut := ListeAttribut[Ind];
        D := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
        case PAttribut.CodeAttribut of
          ConstCaracE:  BE  := D.Total;
          ConstCaracF:  BF  := D.Total;
          ConstCaracFM: BFM := D.Total;
        end;
      end;
    DurACuire := PersonnageTalentEffet(Personnage, ConstCibleEffetDurACuire);
    BonusBlessureFab := PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracBlessure)
                      + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracBlessure);

    BlocEnteteXp(Personnage);
    BlocCarriere(Personnage);
    BlocCaracteristiques(Personnage);
    BlocFateFortuneMouvement(Personnage, Mouv, BonusSprint);
    BlocLangues(Personnage);
    BlocCompetences(Personnage, PMetier);
    BlocTalents(Personnage);
    BlocAmbitionsBlessures(Personnage, BF, BE, BFM, DurACuire, BonusBlessureFab);
    BlocPointsArmure(Personnage, PdfImgShadow);
    // Pied de page : rappel imprime sous les cadres (position relevee par superposition sur la feuille officielle)
    TexteCentre(81.5, 251.8,GetTexteLibelle('RULES-PDF_V5_FOOTER'), 6);
  end;

// ---------------------------------------------------------------- page 2

// Tableau a colonnes : cadre, ligne de titre, lignes de separation et colonnes (bornes verticales)
procedure TableauColonnes(X1, X2, YHaut, YBas, YEnteteBas: Single; const Colonnes: array of Single; const Lignes: array of Single);
  var
    I: Integer;
  begin
    Cadre(X1, YHaut, X2, YBas);
    Trait(X1, YEnteteBas, X2, YEnteteBas, 0.5);
    for I := 0 to High(Lignes) do
      Trait(X1, Lignes[I], X2, Lignes[I], 0.15);
    for I := 0 to High(Colonnes) do
      Trait(Colonnes[I], YEnteteBas - 6.1, Colonnes[I], YBas, 0.15);
  end;

// Lien objet <-> animal : ' [A1]' (meme regle que le PDF V4)
function PdfLienAnimalV5(Eq: StructurePersonnageEquipement): String;
  begin
    Result := '';
    if Eq.PortePar <> '' then
      Result := ' [' + Eq.PortePar + ']'
    else if Eq.IdInstance <> '' then
      Result := ' [' + Eq.IdInstance + ']';
  end;

// Liste de qualites "CODE val,CODE val" -> libelles ; Armure = True : qualites d armure, sinon d arme
function QualitesLisibles(const Liste: String; Armure: Boolean): String;
  var
    Morceaux: TStringList;
    I: Integer;
    Code, Valeur, Lib: String;
  begin
    Result := '';
    if (Liste = '') or (Liste = '-') then
      Exit;
    Morceaux := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Liste), Morceaux);
      for I := 0 to Morceaux.Count - 1 do
        begin
          Code   := ExtractStringBefore(Trim(Morceaux[I]), ' ');
          Valeur := Trim(Copy(Trim(Morceaux[I]), Length(Code) + 1, 99));
          if Armure then
            Lib := ChercheArmureBonus(Code).Libelle
          else
            Lib := ChercheArmeBonus(Code).Libelle;
          if Lib = '' then
            Lib := Code;
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + Trim(Lib + ' ' + Valeur);
        end;
    finally
      Morceaux.Free;
    end;
  end;

// Lignes de donnees de la page 2 : armes, armures, possessions, sorts (colonnes de la feuille V5)
procedure DonneesPageSeconde(Personnage: StructurePersonnage; BF: Integer);
  var
    Eq: StructurePersonnageEquipement;
    PArme: StructureArme;
    PArmure: StructureArmure;
    PArmSimp: StructureArmureSimplifiee;
    PSort: StructureSort;
    NbArme, NbArmure, NbPoss, NbSort, I: Integer;
    EqMut, EqTous: TArrayPersonnageEquipement;
    YBas, XDeb, XFin: Single;
    Enc, EncArme, EncArmure, EncDivers: Integer;
    Portee: String;
    Deg, BonusCC, BonusCT: Integer;
  begin
    NbArme := 0; NbArmure := 0; NbPoss := 0; NbSort := 0;
    // Bonus de degats des talents (Strike Mighty Blow = corps a corps, Accurate Shot = tir) : meme appel que le PDF V4
    BonusCC := PersonnageModificateurUnique(Personnage, ConstXmlModifieDegat, ConstCibleModifieDegatCC, '', True);
    BonusCT := PersonnageModificateurUnique(Personnage, ConstXmlModifieDegat, ConstCibleModifieDegatCT, '', True);
    // + armes et armures accordees par une mutation (partie du corps, calculees a la volee, comme le PDF V4)
    EqMut := PersonnageMutationEquipement(Personnage);
    SetLength(EqTous, Length(Personnage.Equipement) + Length(EqMut));
    for I := 0 to High(Personnage.Equipement) do
      EqTous[I] := Personnage.Equipement[I];
    for I := 0 to High(EqMut) do
      EqTous[Length(Personnage.Equipement) + I] := EqMut[I];
    for Eq in EqTous do
      begin
        if (Eq.TypeEquipement = TypeEquipWe) and (NbArme < 4) then
          begin
            PArme := ChercheArme(Eq.CodeEquipement);
            YBas  := 75.1 + NbArme * 6.97 - 1.4;
            Portee := PArme.Portee;
            if Pos('(' + ConstBonusCaracF + ')', Portee) > 0 then
              Portee := IntToStr(MultiChaine(StringReplace(Portee, '(' + ConstBonusCaracF + ')', IntToStr(Trunc(BF / 10)), [rfReplaceAll])));
            ValeurGauche(10.2, 68.0, YBas, PArme.Libelle + PdfLienAnimalV5(Eq), 8);
            ValeurCentre(68.0, 90.2, YBas, ChercheCompetence(PArme.CodeCompetence).Libelle, 6);
            ValeurCentre(90.2, 98.3, YBas, IntToStr(PArme.Encombrement), 8);
            ValeurCentre(98.3, 116.7, YBas, GetAllTexteLibelle(Portee), 7);
            Deg := CalculDegat(PArme.CalculDegat, BF);
            if Pos(EquipementCC, PArme.CodeArme) > 0 then
              Deg := Deg + BonusCC + FabricationModificateurQualite(Eq.QualiteEquipement, ConstXmlModifieDegat, ConstCibleModifieDegatCC)
            else if Pos(EquipementCT, PArme.CodeArme) > 0 then
              Deg := Deg + BonusCT + FabricationModificateurQualite(Eq.QualiteEquipement, ConstXmlModifieDegat, ConstCibleModifieDegatCT);
            ValeurCentre(116.7, 127.8, YBas, IntToStr(Deg), 8);
            ValeurGauche(127.8, 209.5, YBas, QualitesLisibles(PArme.ListeBonus, False), 7);
            Inc(NbArme);
          end
        else if ((Eq.TypeEquipement = TypeEquipAR) or (Eq.TypeEquipement = TypeEquipARS)) and (NbArmure < 5) then
          begin
            YBas := 117.9 + NbArmure * 5.6 - 1.2;
            if Eq.TypeEquipement = TypeEquipAR then
              begin
                PArmure := ChercheArmure(Eq.CodeEquipement);
                ValeurGauche(10.2, 53.0, YBas, PArmure.Libelle + PdfLienAnimalV5(Eq), 8);
                ValeurCentre(53.0, 87.2, YBas, GetAllTexteLibelle(PArmure.Emplacement), 6);
                ValeurCentre(87.2, 96.0, YBas, IntToStr(PArmure.Encombrement), 8);
                ValeurCentre(96.0, 103.3, YBas, IntToStr(PArmure.Protection), 8);
                ValeurGauche(103.3, 209.5, YBas, QualitesLisibles(PArmure.ListeBonus, True), 7);
              end
            else
              begin
                PArmSimp := ChercheArmureSimplifiee(Eq.CodeEquipement);
                ValeurGauche(10.2, 53.0, YBas, PArmSimp.Libelle + PdfLienAnimalV5(Eq), 8);
                ValeurCentre(87.2, 96.0, YBas, IntToStr(PArmSimp.Encombrement), 8);
                ValeurCentre(96.0, 103.3, YBas, IntToStr(PArmSimp.Protection), 8);
                ValeurGauche(103.3, 209.5, YBas, QualitesLisibles(PArmSimp.ListeBonus, True), 7);
              end;
            Inc(NbArmure);
          end
        else if ((Eq.TypeEquipement = TypeEquipDI) or (Eq.TypeEquipement = TypeEquipAN)) and (NbPoss < 20) then
          begin
            // deux colonnes de 10 lignes ; le texte repose sur la ligne
            if NbPoss < 10 then
              begin XDeb := 13.1; XFin := 55.4; YBas := 154.1 + NbPoss * 5.77; end
            else
              begin XDeb := 61.6; XFin := 103.3; YBas := 154.1 + (NbPoss - 10) * 5.77; end;
            ValeurGauche(XDeb - 0.8, XFin - 7.0, YBas - 0.4, PdfDiversLibelle(Eq) + PdfLienAnimalV5(Eq), 7);
            ValeurCentre(XFin - 7.0, XFin, YBas - 0.4, PdfDiversTexteEnc(Eq), 7);
            Inc(NbPoss);
          end
        else if (Eq.TypeEquipement = TypeEquipSp) and (NbSort < 4) then
          begin
            PSort := ChercheSort(Eq.CodeEquipement);
            YBas  := 235.3 + NbSort * 6.7 - 1.4;
            ValeurGauche(10.2, 54.9, YBas, PSort.Libelle, 8);
            ValeurCentre(54.9, 68.0, YBas, LibelleValeurLivre(PSort.Niveau), 8);
            ValeurCentre(68.0, 85.3, YBas, PdfPersonnageRemplaceBonus(Personnage, PSort.Portee), 7);
            ValeurCentre(85.3, 103.6, YBas, PdfPersonnageRemplaceBonus(Personnage, PSort.Cible), 7);
            ValeurCentre(103.6, 123.2, YBas, PdfPersonnageRemplaceBonus(Personnage, PSort.Duree), 7);
            Inc(NbSort);
          end;
      end;
    // Encombrement par categorie (objets confies a un animal exclus)
    EncArme := 0; EncArmure := 0; EncDivers := 0;
    for Eq in Personnage.Equipement do
      if Eq.PortePar = '' then
        begin
          Enc := PdfEquipementEncombrementBrut(Eq);
          if Eq.TypeEquipement = TypeEquipWe then
            EncArme := EncArme + Enc
          else if (Eq.TypeEquipement = TypeEquipAR) or (Eq.TypeEquipement = TypeEquipARS) then
            begin
              if Eq.Porte and (Enc > 0) then
                Dec(Enc);
              EncArmure := EncArmure + Enc;
            end
          else if (Eq.TypeEquipement = TypeEquipDI) or (Eq.TypeEquipement = TypeEquipAN) then
            EncDivers := EncDivers + PdfDiversEncombrement(Eq);
        end;
    ValeurCentre(67.4, 87.7, 29.7 - 5.7 - 0.3, IntToStr(EncArme), 9);
    ValeurCentre(67.4, 87.7, 29.7 - 0.3, IntToStr(EncArmure), 9);
    ValeurCentre(67.4, 87.7, 35.4 - 0.3, IntToStr(EncDivers), 9);
    ValeurCentre(67.4, 87.7, 52.8 - 0.3, IntToStr(EncArme + EncArmure + EncDivers), 9);
  end;

procedure PageSeconde(Personnage: StructurePersonnage);
  var
    I, BF, BE, Perdue, DebutMut: Integer;
    D: StructureDonnee;
    Bonus: String;
    PCorruption: StructurePersonnageCorruption;
  begin
    D := PdfPersonnageAttribut(Personnage, ConstCaracF, Bonus);
    BF := D.Total;
    D := PdfPersonnageAttribut(Personnage, ConstCaracE, Bonus);
    BE := D.Total;

    // ---- Richesse / Encombrement
    Cadre(10.2, 11.1, 87.7, 52.8);
    Trait(10.2, 18.0, 87.7, 18.0, 0.5);
    Trait(46.8, 11.1, 46.8, 52.8, 0.5);
    LibelleCentre(10.2, 46.8, 17.4, 'RULES-PDF_WEALTH1_WEALTH', 11);
    LibelleCentre(46.8, 87.7, 17.4, 'RULES-PDF_ENCUMBRANCE1_ENCUMBRANCE', 11);
    Trait(26.1, 18.0, 26.1, 42.5, 0.15);
    Trait(10.2, 26.5, 46.8, 26.5, 0.15);
    Trait(10.2, 34.5, 46.8, 34.5, 0.15);
    Trait(10.2, 42.5, 46.8, 42.5, 0.15);
    LibelleCentre(10.2, 26.1, 25.5, 'RULES-PDF_WEALTH2_D', 11);
    LibelleCentre(10.2, 26.1, 33.5, 'RULES-PDF_WEALTH3_SS', 11);
    LibelleCentre(10.2, 26.1, 41.5, 'RULES-PDF_WEALTH4_GC', 11);
    ValeurCentre(26.1, 46.8, 25.5, IntToStr(Personnage.MonnaieSB), 10);
    ValeurCentre(26.1, 46.8, 33.5, IntToStr(Personnage.MonnaiePA), 10);
    ValeurCentre(26.1, 46.8, 41.5, IntToStr(Personnage.MonnaieCO), 10);
    if not DonneesSeules then
      begin
        // note de conversion des monnaies : pre-imprimee sur la feuille officielle
        ValeurCentre(10.2, 46.8, 47.6, GetTexteLibelle('RULES-PDF_V5_COINS1'), 5);
        ValeurCentre(10.2, 46.8, 50.0, GetTexteLibelle('RULES-PDF_V5_COINS2'), 5);
        ValeurCentre(10.2, 46.8, 52.4, GetTexteLibelle('RULES-PDF_V5_COINS3'), 5);
      end;
    Trait(67.4, 18.0, 67.4, 52.8, 0.15);
    for I := 0 to 4 do
      Trait(46.8, 24.0 + I * 5.7, 87.7, 24.0 + I * 5.7, 0.15);
    LibelleGauche(46.8, 67.4, 24.0, 'RULES-PDF_ENCUMBRANCE3_WEAPONS', 7);
    LibelleGauche(46.8, 67.4, 29.7, 'RULES-PDF_ENCUMBRANCE2_ARMOUR', 7);
    LibelleGauche(46.8, 67.4, 35.4, 'RULES-PDF_ENCUMBRANCE4_TRAPPINGS', 7);
    LibelleGauche(46.8, 67.4, 41.1, 'RULES-PDF_V5_OTHER', 7);
    LibelleGauche(46.8, 67.4, 46.8, 'RULES-PDF_V5_MAXENC', 7);
    LibelleGauche(46.8, 67.4, 52.8, 'RULES-PDF_ENCUMBRANCE6_TOTAL', 7);
    ValeurCentre(67.4, 87.7, 46.8, IntToStr(Floor(BF / 10) + Floor(BE / 10)
      + PersonnageTalentEffet(Personnage, ConstCibleEffetBonusEncomb)), 9);

    // ---- Corruption et mutations
    Cadre(89.5, 11.1, 209.5, 52.8);
    LibelleCentre(89.5, 209.5, 16.9, 'RULES-PDF_CORRUPTION', 11);
    Trait(89.5, 18.1, 209.5, 18.1, 0.5);
    LibelleGauche(89.5, 112, 22.8, 'RULES-PDF_V5_CORRUPTIONPOINTS', 7);
    Perdue := 0;
    for PCorruption in Personnage.Corruption do
      Perdue := Perdue + PCorruption.Montant;
    for I := 0 to 14 do
      CaseTracker(111.0 + I * 6.15, 19.6, I < Perdue);
    Trait(89.5, 23.3, 209.5, 23.3, 0.3);
    LibelleGauche(89.5, 124.6, 28.4, 'RULES-PDF_V5_MUTATION', 7);
    LibelleGauche(124.6, 209.5, 28.4, 'RULES-PDF_SPELL2_EFFECT', 7);
    Trait(89.5, 29.2, 209.5, 29.2, 0.3);
    Trait(124.6, 23.3, 124.6, 52.8, 0.15);
    for I := 0 to 2 do
      Trait(89.5, 35.1 + I * 5.9, 209.5, 35.1 + I * 5.9, 0.15);
    // Mutations obtenues : les 4 plus recentes (4 lignes sur la feuille), libelle de la table + effet
    DebutMut := Max(0, Length(Personnage.Mutations) - 4);
    for I := DebutMut to High(Personnage.Mutations) do
      begin
        ValeurGauche(89.5, 124.6, 35.1 + (I - DebutMut) * 5.9, ChercheCorruptionTable(Personnage.Mutations[I].Code).Libelle, 8);
        ValeurGauche(124.6, 209.5, 35.1 + (I - DebutMut) * 5.9, PersonnageMutationEffetTexte(Personnage.Mutations[I]), 7);
      end;

    // ---- Armes
    TableauColonnes(10.2, 209.5, 55.6, 96.0, 68.2, [68.0, 90.2, 98.3, 116.7, 127.8], [75.1, 82.0, 89.0]);
    LibelleCentre(10.2, 209.5, 61.7, 'RULES-PDF_WEAPONS1_WEAPONS', 11);
    LibelleGauche(18.2, 68, 67.6, 'RULES-PDF_WEAPONS2_NAME', 6);
    LibelleCentre(68.0, 90.2, 67.6, 'RULES-PDF_WEAPONS2_GROUP', 6);
    LibelleCentre(90.2, 98.3, 67.6, 'RULES-PDF_WEAPONS2_ENCUMBRANCE', 6);
    LibelleCentre(98.3, 116.7, 67.6, 'RULES-PDF_WEAPONS2_RANGE', 6);
    LibelleCentre(116.7, 127.8, 67.6, 'RULES-PDF_WEAPONS2_DAMAGE', 6);
    LibelleGauche(129.0, 209.5, 67.6, 'RULES-PDF_WEAPONS2_QUALITIES', 6);

    // ---- Armures
    TableauColonnes(10.2, 209.5, 98.7, 140.2, 112.3, [53.0, 87.2, 96.0, 103.3], [117.9, 123.5, 129.1, 134.7]);
    LibelleCentre(10.2, 209.5, 105.2, 'RULES-PDF_ARMOUR1_ARMOUR', 11);
    LibelleGauche(18.2, 53, 110.8, 'RULES-PDF_ARMOUR2_NAME', 6);
    LibelleCentre(53.0, 87.2, 110.8, 'RULES-PDF_ARMOUR2_LOCATIONS', 6);
    LibelleCentre(87.2, 96.0, 110.8, 'RULES-PDF_ARMOUR2_ENCUMBRANCE', 6);
    LibelleCentre(96.0, 103.3, 110.8, 'RULES-PDF_ARMOUR2_ARMOURPOINT', 6);
    LibelleGauche(104.0, 209.5, 110.8, 'RULES-PDF_ARMOUR2_QUALITIES', 6);

    // ---- Possessions et notes
    Cadre(10.2, 142.8, 108.7, 209.7);
    LibelleCentre(10.2, 108.7, 149.3, 'RULES-PDF_TRAPPING1_TRAPPINGS', 11);
    for I := 0 to 9 do
      begin
        Trait(13.1, 154.1 + I * 5.77, 55.4, 154.1 + I * 5.77, 0.15);
        Trait(61.6, 154.1 + I * 5.77, 103.3, 154.1 + I * 5.77, 0.15);
      end;
    Cadre(111.0, 142.8, 209.5, 209.7);
    LibelleCentre(111.0, 209.5, 149.3, 'RULES-PDF_V5_NOTES', 11);

    // ---- Sorts et prieres
    TableauColonnes(10.2, 209.5, 212.2, 262.0, 228.4, [54.9, 68.0, 85.3, 103.6, 123.2], [235.3, 242.0, 248.7, 255.4]);
    LibelleCentre(10.2, 209.5, 219.2, 'RULES-PDF_SPELL1_SPELL', 11);
    Trait(10.2, 220.5, 209.5, 220.5, 0.5);
    LibelleGauche(18.2, 54.9, 227.0, 'RULES-PDF_SPELL2_NAME', 6);
    LibelleCentre(54.9, 68.0, 227.0, 'RULES-PDF_SPELL2_CN', 6);
    LibelleCentre(68.0, 85.3, 227.0, 'RULES-PDF_SPELL2_RANGE', 6);
    LibelleCentre(85.3, 103.6, 227.0, 'RULES-PDF_SPELL2_TARGET', 6);
    LibelleCentre(103.6, 123.2, 227.0, 'RULES-PDF_SPELL2_DURATION', 6);
    Trait(158.5, 255.4, 158.5, 262.0, 0.3);
    Trait(168.6, 255.4, 168.6, 262.0, 0.3);
    LibelleCentre(158.5, 168.6, 261.2, 'RULES-PDF_SPELL3_SIN', 7);

    DonneesPageSeconde(Personnage, BF);
  end;

// ---------------------------------------------------------------- point d'entree

Procedure PdfPersonnageV5(Personnage: StructurePersonnage);
  var
    PDFDoc: TPDFDocument;
    PdfSection: TPDFSection;
    PdfChemin: String;
    PdfImgShadow, PdfImgFond1, PdfImgFond2: Integer;
    FondOfficiel: Boolean;
    PMetier: StructureMetier;
    Papier: TPDFPaper;
  begin
    Personnage := PersonnageSansMunitions(Personnage);
    DonneesSeules := Pos(AjouteAccolade(ConstXmlOptionPdfDonneesSeules), Personnage.Options) > 0;
    PdfChemin  :=GetCurrentDir + ConstCheminPersonnage + Personnage.NomPersonnage + '\' + Personnage.NomPersonnage + ' ' +
                  FormatDateTime('yyyymmdd-hhnnss', Now) + '.PDF';
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
      // feuille officielle : 215 x 270 mm (en points : 609 x 765)
      FillChar(Papier, SizeOf(Papier), 0);
      Papier.W := Round(PL / 25.4 * 72);
      Papier.H := Round(PH / 25.4 * 72);
      Page.PaperType := ptCustom;
      Page.Paper := Papier;
      Page.UnitOfMeasure := uomMillimeters;
      PdfImgShadow := PDFDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir + ConstCheminPdfShadow), False);
      PMetier := ChercheMetier(Personnage.MetierEnCours.CodeMetier);
      // fond officiel : image de la feuille sous les valeurs (implique donnees seules)
      FondOfficiel := Pos(AjouteAccolade(ConstXmlOptionPdfFondOfficiel), Personnage.Options) > 0;
      if FondOfficiel then
        begin
          DonneesSeules := True;
          PdfImgFond1 := PDFDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir + '\PICTURES\WFRP5\PDF\FOND-376.jpg'), False);
          PdfImgFond2 := PDFDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir + '\PICTURES\WFRP5\PDF\FOND-377.jpg'), False);
          Page.DrawImage(0, 0, PL, PH, PdfImgFond1);
        end;
      PagePremiere(Personnage, PMetier, PdfImgShadow);
      // page 2 : meme feuille
      Page := PDFDoc.Pages.AddPage;
      PdfSection.AddPage(Page);
      Page.PaperType := ptCustom;
      Page.Paper := Papier;
      Page.UnitOfMeasure := uomMillimeters;
      if FondOfficiel then
        Page.DrawImage(0, 0, PL, PH, PdfImgFond2);
      PageSeconde(Personnage);
      PDFDoc.SaveToFile(PdfChemin);
    finally
      PDFDoc.Free;
    end;
    PdfPurgeAnciens(PdfChemin);
    if not PdfSansOuverture then
      OpenDocument(PdfChemin);
  end;

initialization
  PdfPersonnageV5Hook := @PdfPersonnageV5;

end.

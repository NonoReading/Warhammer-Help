unit PdfMetier;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

interface

uses
  Classes, SysUtils, fpPDF, Dialogs, MessageTest, PicsLib, Graphics, LCLIntf,
  ChargeRaceMetier, ChargeMetierNiveau, ChargeMetier, ChargeConstantes,
  ChargeMetierAttribut, ChargeAttribut, ChargeMetierCompetence,
  ChargeCompetence, ChargeTalent, ChargeMetierTalent, ChargeMetierEquipement,
  ChargeArme, ChargeArmure, ChargeTrapping, PdfPersonnage,
  ChargeTexte, UnitCalcul, PdfUtils;

function PdfPositionFeuille(Base:Integer; NbLigne:Integer; NbDetail:Integer): Real;
Procedure PdfMetierDoc(ListeMetier: String);
Procedure PdfMetierPage(PDFDoc: TPDFDocument; PDFPage: TPDFPage; MetierEnCours: String);

Var
  CheminClass:    String;
  HautFeuille:    Integer = 0;
  TailleCellule:  Integer = 8;
  HautAttribut:   Integer = 5;
  PdfImgFront:    Integer;
  PdfImgFeuille:  Integer;
  PdfImgGauche:   Integer;
  PdfImgDroite:   Integer;
  APdfImgClasse:  Array of array of String;
  NbPdfImgClasse: Integer = 0;
  ColorList:      array of TColor;
  PdfImgNv:       Array of Integer;

implementation

uses ChargeCreationTow;

function PdfPositionFeuille(Base:Integer; NbLigne:Integer; NbDetail:Integer): Real;
var
  TailleLigne:  Real = 5.5;
  TailleDetail: Real = 3.5;
begin
  Result := Base - (NbLigne * TailleLigne) - (NbDetail * TailleDetail) + 1 - HautFeuille;
end;

// Nom du fichier PDF d une carriere : son libelle ; si le meme libelle existe dans un autre livre
// (deux Agitator : Rulebook et Book of the Rat), les doublons prennent le livre entre
// parentheses, sauf le Rulebook, sinon le lot ecrase l un par l autre.
Function NomFichierMetier(const PMetier: StructureMetier): String;
var
  PAutre: StructureMetier;
  Doublon: Boolean;
  Liv: String;
begin
  Result := TrimRight(PMetier.Libelle);
  Doublon := False;
  for PAutre in ListMetier do
    if (PAutre.CodeMetier <> PMetier.CodeMetier) and (TrimRight(PAutre.Libelle) = Result) then
      begin
        Doublon := True;
        Break;
      end;
  // Le Rulebook est le livre principal : il garde le nom simple (Agitator.PDF), comme dans les
  // listes de carrieres liees ou son livre n est pas precise.
  if Doublon and (Pos('RULESBOOK', UpperCase(PMetier.Livre)) = 0) then
    begin
      Liv := GetTexteLibelle(PMetier.Livre, '', '', true);
      if Copy(Liv, 1, 4) = '(F) ' then
        Liv := Copy(Liv, 5, MaxInt);
      if Liv <> '' then
        Result := Result + ' (' + Liv + ')';
    end;
end;

Procedure PdfMetierDoc(ListeMetier: String);
var
  PDFDoc:             TPDFDocument;
  PDFSection:         TPDFSection;
  PDFPage:            TPDFPage;
  PdfChemin:          String;
  PDFOption:          TPDFOptions;
  Strings:            TStringList;
  PMetier:            StructureMetier;
  IndL:               Integer;
begin
  strings          := TStringList.Create;
  ExtractStrings([SeparateurMulti], [], PChar(ListeMetier), strings);
  // Chemin de l'image que vous souhaitez ajouter
  PMetier      := chercheMetier(Strings[0]);
  if strings.Count = 1 then
    PdfChemin    := GetCurrentDir+ConstCheminPersonnage+'\'+NomFichierSur(NomFichierMetier(PMetier))+'.PDF'
  else
    PdfChemin    := GetCurrentDir+ConstCheminPersonnage+'\'+NomFichierSur(TrimRight(GetTexteLibelle('RULES-LAB_006')))+'.PDF';

  if FileExists(PdfChemin) then
    if not DeleteFile(PdfChemin) then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_038'));
      exit;
    end;
  PDFDoc           := TPDFDocument.Create(nil);
  PDFOption        := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText];
  PDFDoc.Options   := PDFOption;
  PDFDoc.StartDocument;
  PdfSection       := PDFDoc.Sections.AddSection;

  PdfImgFront       := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfMetierBack, ConstLangue, ValLangue, [rfReplaceAll])));
  PdfImgGauche      := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierLigneG),false);
  PdfImgDroite      := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierLigneD),false);
  PdfImgFeuille     := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierAdvance),false);
  SetLength(APdfImgClasse,8,2);

  PdfPolicesDeRepli;
  PdfFontBold      := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
  PdfFontValue     := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique.ttf'), ConstPoliceCarlson);
  PdfFontItalique  := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Italic.ttf'), ConstPoliceCarlson+ConstPoliceItalique);

  For IndL := 0 to strings.count-1 do
    begin
      PdfPage          := PDFDoc.Pages.AddPage;
      PdfSection.AddPage(PdfPage);
      PdfPage.PaperType:= ptA4;
      PdfPage.UnitOfMeasure := uomMillimeters;
      PdfMetierPage(PDFDoc, PDFPage, strings[IndL]);
    end;

  PDFDoc.SaveToFile(PdfChemin);
  PDFDoc.Free;

  if not PdfSansOuverture then
    OpenDocument(PdfChemin);

  NbPdfImgClasse := 0;
  for IndL := low(APdfImgClasse) to High(APdfImgClasse) do
    APdfImgClasse[IndL,0] := '';

end;

// Adapting Careers : lignes du bas du pave de droite, de haut en bas (titre, Standing, une ligne
// par substitution). Meme resolution de libelles que WinMetier.
Procedure PdfLignesAdaptation(MetierEnCours: String; Lignes: TStringList);
  function LibelleElement(Nature, Code: String): String;
    begin
      if Code = '' then
        Exit('-');
      if Nature = ConstXmlTalent then
        Result := ChercheTalent(Code).Libelle
      else if Nature = ConstXmlTrapping then
        begin
          Result := ChercheArme(Code).Libelle;
          if Result = '' then
            Result := ChercheArmure(Code).Libelle;
          if Result = '' then
            Result := ChercheTrapping(Code).Libelle;
        end
      else
        Result := ChercheCompetence(Code).Libelle;
      if Result = '' then
        Result := Code;
    end;
Var
  PAdapt: StructureCareerAdaptation;
  PLigne: StructureCareerAdaptationLigne;
  Titre:  String;
Begin
  for PAdapt in ListCareerAdaptation do
    if CompareRechercheValeur(PAdapt.CodeMetier, MetierEnCours) then
      begin
        Titre := PAdapt.Libelle;
        if PAdapt.Facultative then
          Titre := Titre + ' *';
        Lignes.Add(Titre);
        if PAdapt.Standing <> 0 then
          Lignes.Add('¤Standing +' + IntToStr(PAdapt.Standing));
        for PLigne in ListCareerAdaptationLigne do
          if PLigne.CodeAdaptation = PAdapt.CodeAdaptation then
            Lignes.Add('¤' + IntToStr(PLigne.Niveau) + '. ' + LibelleElement(PLigne.Nature, PLigne.Retire)
              + ' -> ' + LibelleElement(PLigne.Nature, PLigne.Ajoute));
      end;
End;

Procedure PdfMetierPage(PDFDoc: TPDFDocument; PDFPage: TPDFPage; MetierEnCours: String);
var
  PMetier:            StructureMetier;
  DebutImgMetier:     Integer = 10;
  DebutFeuille:       Integer = 100;
  NbLigne:            Integer;
  DebutTexte:         Integer;
  NbDetail:           Integer;
  IndDetail:          Integer;
  DecDetail:          Real;
  MaxDetail:          Integer;
  DebutSous:          Integer = 10;
  DebutDetail:        Integer = 15;
  LargeurFeuille:     Integer = 100;
  MargeDroite:        Integer = 5;
  DebutTalent:        Integer = 45;
  FinAttribut:        Double = 0;
  // ATTENTION : NbNiveauMetier est un NOMBRE DE LIGNES, pas un numero de niveau. Les deux
  // se confondaient tant que toute carriere commencait au niveau 1 ; ce n'est plus vrai.
  NbNiveauMetier:     Integer = 0;
  NvMinMetier:        Integer = 1;
  TotalEquip:         Integer = 0;
  TotalTalent:        Integer = 0;
  MaxTailleDetail:    Integer = 110;
  MinPolice:          integer = 7;
  ListPage:           TStringList;
  PdfImgClasse:       Integer;
  AddImg:             Boolean = true;

  // Talent a etoile (ROS-T_RUNE__*) : aucune fiche, seulement des specialisations. On imprime le nom
  // de la famille (libelle de la premiere specialisation avant sa parenthese) suivi de {Au choix}.
  // Vide si le code n'est pas une famille ou si aucune specialisation n'est chargee.
  function LibelleFamilleTalent(Code: String): String;
    var
      Liste: TStringList;
      Lib: String;
      P: Integer;
    begin
      Result := '';
      if Pos(ValeurGenerique, Code) = 0 then Exit;
      Liste := ListeTalent(Code);
      try
        if Liste.Count = 0 then Exit;
        Lib := Trim(ChercheTalent(Liste[0]).Libelle);
        P := Pos(' (', Lib);
        if P > 0 then
          Lib := Copy(Lib, 1, P - 1);
        if Lib <> '' then
          Result := Lib + ' ' + ConstArbreAuChoix;
      finally
        Liste.Free;
      end;
    end;

  // V2 : un code peut etre un choix "A/B" (ex. Savvy or Suave). Libelles joints par " / ".
  function LibelleChoix(Talent: Boolean; Code: String): String;
    var
      Parties: TStringList;
      Ind: Integer;
      Lib: String;
    begin
      Parties := TStringList.Create;
      try
        ExtractStrings(['/'], [], PChar(Code), Parties);
        Result := '';
        for Ind := 0 to Parties.Count - 1 do
          begin
            if Talent then
              Lib := ChercheTalent(Parties[Ind]).Libelle
            else
              Lib := ChercheCompetence(Parties[Ind]).Libelle;
            if Lib = '' then
              Lib := Parties[Ind];
            if Result <> '' then
              Result := Result + ' / ';
            Result := Result + Trim(Lib);
          end;
      finally
        Parties.Free;
      end;
    end;

  // Icones et couleurs de ce metier, reconstruites a chaque page.
  procedure PrepareIcones;
    var
      IndL: Integer;
      CheminIcone: String;
    begin
      // ICONES ET COULEURS DE CE METIER, reconstruites A CHAQUE PAGE.
      //
      // Elles etaient construites UNE SEULE FOIS dans PdfMetierDoc, pour le PREMIER metier de la
      // liste : tous les suivants dessinaient donc avec ses images, ses couleurs et son nombre de
      // niveaux. Sans consequence tant que tout le monde partageait les icones generiques ; le
      // devenu depuis que le dossier depend du livre - un PDF melant une carriere elfique et une
      // du Rulebook donnait les glyphes elfiques aux deux. Signale le 31/08/2026, corrige le
      // 01/09 sur demande de Nono, qui note qu'on ne le voit qu'en lancant plusieurs metiers.
      //
      // Les indices restent comptes depuis 1 - PdfImgNv[Nv-1] - meme quand le metier commence
      // au niveau 3 : seules les boucles de DESSIN partent de NvMinMetier.
      //
      // Cote taille du fichier : une meme icone ajoutee a deux pages est stockee deux fois par
      // PdfDoc.Images. C'est le prix d'une image juste, et il ne se paie que sur un PDF
      // multi-metiers.
      ColorList := [];
      PdfImgNv  := [];
      SetLength(ColorList, ChercheMaxMetierNiveau(MetierEnCours) + 1);
      For IndL := 1 to ChercheMaxMetierNiveau(MetierEnCours) do
        begin
          CheminIcone := CheminNiveauImageMetier(MetierEnCours, IndL);
          // Icone absente : on garde la place avec -1 plutot que d'echouer, et les dessins
          // testent ce -1. Un niveau peut ne pas avoir d'image.
          if FileExists(CheminIcone) then
            PdfImgNv += [PdfDoc.Images.AddFromFile(CheminIcone,false)]
          else
            PdfImgNv += [-1];
          ColorList[IndL] := ChargeImageArrayColorFichier(CheminIcone);
        end;
    end;

  // Image du groupe de metiers : reutilisee d une page a l autre, sinon ajoutee au document.
  procedure ChargeImageClasse;
    var
      I: Integer;
    begin
      CheminClass     := CheminImageClasse(PMetier.LibelleGroupe);
      for I := low(APdfImgClasse) to High(APdfImgClasse) do
        if APdfImgClasse[i,0] = PMetier.LibelleGroupe+'.png' then
          begin
            PdfImgClasse    := StrToIntDef(APdfImgClasse[I,1],0);
            AddImg          := false;
            break;
          end;

      if (AddImg) and FileExists(CheminClass) then
          begin
            PdfImgClasse  := PdfDoc.Images.AddFromFile(CheminClass,false);

            APdfImgClasse[NbPdfImgClasse,0] := PMetier.LibelleGroupe+'.png';
            APdfImgClasse[NbPdfImgClasse,1] := IntToStr(PdfImgClasse);
            Inc(NbPdfImgClasse);
          end;
    end;

  // Fond, filets, groupe, image et titre de la classe.
  procedure DessineEntete;
    var
      Path: String;
      IWidth, IHeight: dword;
      CWidth, cHeight: dword;
      ListEspece: String;
      TexteLivre: String;
    begin
      // image fond
      PdfPage.DrawImage(0, 0, 210, 297, PdfImgFront);

      // Haut et bas de page
        // gauche
        Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierLigneG);
        GetImageSize(Path, IWidth, IHeight);
        RedimensionneImage(IWidth, IHeight, 85, 999, CWidth, cHeight);
        PdfPage.DrawImage(10, 10, cWidth, cHeight, PdfImgGauche);
        PdfPage.DrawImage(10, 287, cWidth, cHeight, PdfImgGauche);

        // droite
        Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierLigneD);
        GetImageSize(Path, IWidth, IHeight);
        RedimensionneImage(IWidth, IHeight, 85, 999, CWidth, cHeight);
        PdfPage.DrawImage(115, 10, cWidth, cHeight, PdfImgDroite);
        PdfPage.DrawImage(115, 287, cWidth, cHeight, PdfImgDroite);

        // texte
        PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 9);
        PdfCentre(PdfPage, 95, 115, 11, WideUpperCase(WideString(GetTexteLibelle(PMetier.LibelleGroupe))){%H-});
        PdfCentre(PdfPage, 95, 115, 288, WideUpperCase(WideString(GetTexteLibelle(PMetier.LibelleGroupe))){%H-});

      // Image Classe
      Path              := CheminClass;
      if FileExists(Path) then
        begin
          GetImageSize(Path, IWidth, IHeight);
          RedimensionneImage(IWidth, IHeight, 10, 10, CWidth, cHeight);
          PdfPage.DrawImage(15, 275, CWidth, CHeight, PdfImgClasse);
        end;

      // texte
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 24);
      PdfEcrit(PdfPage, 17 + CWidth, 999, 278, WideUpperCase(WideString(PMetier.Libelle)){%H-},MinPolice);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 9);
      ListEspece := MetierRaceCourt(MetierEnCours);
      PdfEcrit(PdfPage, 17 + CWidth, 999, 275, ListEspece,MinPolice);
      // Colonne de gauche seulement (le pave de droite commence vers x = 98) : un titre de livre long
      // (livres de fans) passait dessous. Coupe au dernier mot qui tient a la police minimale, « ... »
      // en fin, pour rester sur une ligne.
      TexteLivre := GetTexteLibelle('RULES-LAB_128') {%H-}+ ' : ' + WideUpperCase(WideString(GetTexteLibelle(PMetier.Livre, '', '', true))){%H-};
      if TailleTexte(TexteLivre, MinPolice) > (96 - DebutImgMetier) * 1.15 then
        begin
          while (Pos(' ', TexteLivre) > 0) and (TailleTexte(TexteLivre + '...', MinPolice) > (96 - DebutImgMetier) * 1.15) do
            TexteLivre := TrimRight(Copy(TexteLivre, 1, LastDelimiter(' ', TexteLivre) - 1));
          TexteLivre := TexteLivre + '...';
        end;
      PdfEcrit(PdfPage, DebutImgMetier, 96, 268, TexteLivre, MinPolice);
    end;

  // Tableau du schema d avance (attributs par niveau), colonne de gauche.
  procedure DessineSchemaAvance;
    var
      Path: String;
      IWidth, IHeight: dword;
      CWidth, cHeight: dword;
      Ind, Nv: Integer;
      Coord: TPDFCoord;
      PAttribut: StructureAttribut;
      PMetierAttribut: StructureMetierAttribut;
      PAvance: StructureMetierAvance;
    begin
      Ind := 0;
      For PAttribut in ListeAttribut do
        Begin
          Inc(Ind);
          if Ind <= 10 then
            begin
              Nv := 0;
              For PMetierAttribut in ListMetierAttribut do
                if (PMetierAttribut.CodeMetier = MetierEnCours) and (PMetierAttribut.CodeAttribut = PAttribut.CodeAttribut) then
                  begin
                    Nv := PMetierAttribut.NiveauMetier;
                    break;
                  end;
              if Nv > 0 then
                begin
                  Path := CheminNiveauImageMetier(MetierEnCours, Nv);
                  PdfPage.SetColor(ColorToARGB(ColorList[Nv],0),false);
                  Coord.X := DebutImgMetier + ((Ind - 1.0) * TailleCellule);
                  // La ligne est comptee depuis le PREMIER niveau du metier, pas depuis 1.
                  Coord.Y := 261.15 - HautAttribut - ((Nv - NvMinMetier)*4.7);
                  PdfPage.DrawRect(Coord,TailleCellule,4.7,0,true,false,0);
                  // Le rectangle colore est toujours dessine ; l'icone seulement si elle existe.
                  if PdfImgNv[NV-1] >= 0 then
                    begin
                      GetImageSize(Path, IWidth, IHeight);
                      RedimensionneImage(IWidth, IHeight, TailleCellule, 4, CWidth, cHeight);
                      PdfPage.DrawImage(DebutImgMetier + ((Ind-0.75)*TailleCellule),Coord.Y, CWidth, cHeight, PdfImgNv[NV-1]);
                    end;
                  Coord.Y := 261.15 - HautAttribut + 4.7;
                  PdfPage.DrawRect(Coord,TailleCellule,4.7,0,true,false,0);
                  PdfPage.SetColor(clblack,false);
                end
              else if ChercheMaxMetierNiveau(MetierEnCours) = 0 then
                // V1/V2 : pas de niveaux, une seule ligne = le plafond d avances du livre.
                for PAvance in ListMetierAvance do
                  if (PAvance.CodeMetier = MetierEnCours) and (PAvance.CodeAttribut = PAttribut.CodeAttribut) then
                    begin
                      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson, 9);
                      PdfCentre(PdfPage, DebutImgMetier + ((Ind-1)*TailleCellule), DebutImgMetier + (Ind*TailleCellule), 261.15 - HautAttribut + 1.15, '+' + IntToStr(PAvance.Plafond));
                      break;
                    end;
              PdfCentre(PdfPage,DebutImgMetier + ((Ind-1)*TailleCellule),DebutImgMetier + (ind*TailleCellule),267-HautAttribut,PAttribut.Resume);
            end;
            // Bas du tableau du schema d'avance : une ligne par niveau, la derniere etant
            // celle du niveau le plus haut de CE metier. C'est aussi le point d'ancrage de
            // l'image placee dessous (voir l'appel a DrawImage plus bas), donc le tableau
            // pousse la suite vers le bas quand il grandit.
            FinAttribut := 261.15 - HautAttribut - ((NbNiveauMetier - 1) * 4.7);
        end;

      // Traits horizontaux : une ligne d'entete plus un niveau, d'ou le +1. C'etait ecrit
      // "0 to 5", ce qui valait exactement 0 to 4+1 tant que toutes les carrieres avaient
      // quatre niveaux.
      For Ind := 0 to NbNiveauMetier + 1 do
        PdfPage.DrawLine(DebutImgMetier,270.7 - HautAttribut - (Ind * 4.75),DebutImgMetier + (TailleCellule*10),270.7 - HautAttribut - (Ind * 4.75),1);

      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 9);
      // Traits verticaux : ils descendent jusqu'au dernier trait horizontal. Le 246.95 d'avant
      // etait 270.7 moins les cinq bandes de 4.75 d'une carriere a quatre niveaux.
      for Ind := 1 to 9 do
        PdfPage.DrawLine(DebutImgMetier + (Ind*Taillecellule),270.7 - HautAttribut - ((NbNiveauMetier + 1) * 4.75),DebutImgMetier + (Ind*TailleCellule),270.7-HautAttribut,1);
    end;

  // Competences du niveau Nv (cadre et detail).
  procedure NiveauCompetences(Nv: Integer);
    var
      Coord: TPDFCoord;
      PMetierCompetence: StructureMetierCompetence;
      PCompetence: StructureCompetence;
      PAttribut: StructureAttribut;
      TexteCompetence: String;
      Trouve: Boolean;
      IndC: Integer;
    begin
      // COMPETENCE
      // rectangle
      Inc(NbLigne);
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne,NbDetail)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, GetTexteLibelle('RULES-LAB_009')+' : ',MinPolice);

      // détail compétences
      IndDetail := 0;
      DecDetail := 0;

      For PMetierCompetence in ListMetierCompetence do
        if (PMetierCompetence.CodeMetier = MetierEnCours) and (PMetierCompetence.NiveauMetier = Nv) then
          begin
            Inc(IndDetail);
            PCompetence := ChercheCompetence(PMetierCompetence.CodeCompetence);
            if PMetierCompetence.CodeCompetence = PMetier.CodeCompetence then
              PdfTaillePolice(PdfPage, PdfFontItalique, ConstPoliceCarlson, 9)
            else
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson+ConstPoliceItalique, 9);
            PAttribut := ChercheAttribut(PCompetence.CodeAttribut);
            if (PCompetence.Libelle = '') and (Pos('/', PMetierCompetence.CodeCompetence) > 0) then
              TexteCompetence := LibelleChoix(False, PMetierCompetence.CodeCompetence)
            else
              begin
                TexteCompetence := Trim(PCompetence.Libelle);
                // Specialisation libre (V2 : « Academic Knowledge (Various) ») : famille + {Au choix},
                // comme les talents a etoile.
                if PCompetence.SpecLibre and (Pos(' (', TexteCompetence) > 0) then
                  TexteCompetence := Copy(TexteCompetence, 1, Pos(' (', TexteCompetence) - 1) + ' ' + ConstArbreAuChoix;
                // Pas de crochets vides quand la competence n a pas de caracteristique liee.
                if GetTexteLibelle(PAttribut.Resume) <> '' then
                  TexteCompetence := TexteCompetence + ' ['+GetTexteLibelle(PAttribut.Resume)+']';
              end;
            Trouve          := false;
            for IndC := 0 to ListPage.count-1 do
              if ListPage[IndC] = PCompetence.CodeCompetence then
                begin
                  Trouve := true;
                  Break;
                end;

            if not trouve then
              TexteCompetence := TexteCompetence +' *';

            // Limite a droite (comme les talents) : une competence a choix multiples longue est
            // reduite au lieu de sortir de la page.
            PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail, DebutFeuille + DecDetail + LargeurFeuille - MargeDroite, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), '¤ '+TexteCompetence,MinPolice);
            Inc(IndDetail, PdfRangeesSupp);   // ligne coupee : les suivantes descendent d autant
            Maxdetail := IndDetail;
          end;
    end;

  // Talents du niveau Nv.
  procedure NiveauTalents(Nv: Integer);
    var
      PMetierTalent: StructureMetierTalent;
      PTalent: StructureTalent;
      TexteTal: String;
    begin
      // TALENT
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous + DebutTalent, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, GetTexteLibelle('RULES-LAB_007')+' : ',MinPolice);

      // détail talents
      IndDetail := 0;
      DecDetail := 0;

      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson, 9);
      For PMetierTalent in ListMetierTalent do
        if (PMetierTalent.CodeMetier = MetierEnCours) and ((Nv = 0) or (PMetierTalent.NiveauMetier = Nv)) then
          begin
            Inc(IndDetail);
            Inc(TotalTalent);
            PTalent := ChercheTalent(PMetierTalent.CodeTalent);
            TexteTal := PTalent.Libelle;
            if TexteTal = '' then
              begin
                TexteTal := LibelleFamilleTalent(PMetierTalent.CodeTalent);
                if (TexteTal = '') and (Pos('/', PMetierTalent.CodeTalent) > 0) then
                  TexteTal := LibelleChoix(True, PMetierTalent.CodeTalent);
              end;
            PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail + DebutTalent, DebutFeuille + DecDetail+ DebutTalent + LargeurFeuille - MargeDroite, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), '¤ '+TexteTal,MinPolice);
          end;
      if IndDetail > MaxDetail then
        MaxDetail := IndDetail;
      NbDetail := NbDetail + MaxDetail;
    end;

  // Equipement du niveau Nv.
  procedure NiveauEquipements(Nv: Integer);
    var
      Coord: TPDFCoord;
      PMetierEquipement: StructureMetierEquipement;
      PArme: StructureArme;
      PArmure: StructureArmure;
      PTrapping: StructureTrapping;
      StringEquip: TStringList;
      StringType: TStringList;
      LigneEquip: String;
      LigneType: String;
      LigneIndice: Integer;
      Decalage: String;
      Qualite: String;
      Equipement: String;
      LibDivers: String;
    begin
      // Equipement
      Inc(NbLigne);
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne,NbDetail)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, GetTexteLibelle('RULES-LAB_013')+' : ',MinPolice);

      // détail Equipements
      IndDetail   := 0;
      DecDetail   := 0;
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson, 9);

      For PMetierEquipement in ListMetierEquipement do
        if (PMetierEquipement.CodeMetier = MetierEnCours) and ((Nv = 0) or (PMetierEquipement.NiveauMetier = Nv)) then
          begin
            StringEquip := TStringList.Create;
            StringType  := TStringList.Create;

            if Pos(SeparateurEnsemble, PMetierEquipement.Equipement) > 0 then
              begin
                // ensemble : "A+B" acquis en meme temps, pas un choix - a ne pas
                // decouper par SeparateurMulti (CONTEXT.md, chantier equipement/
                // avancement), sinon les deux codes restent colles et disparaissent
                // silencieusement plus bas (aucun InList ne les reconnait).
                ExtractStrings([SeparateurEnsemble], [], PChar(PMetierEquipement.Equipement), StringEquip);
                ExtractStrings([SeparateurEnsemble], [], PChar(PMetierEquipement.TypeEquipement), StringType);
                Inc(IndDetail);
                PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail, DebutFeuille + DecDetail + 110, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), '¤ '+ConstArbreEnsemble,MinPolice);
                Decalage := '     -';
              end
            else
              begin
                ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.Equipement), StringEquip);
                ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.TypeEquipement), StringType);

                if StringEquip.Count > 1 then
                  begin
                    Inc(IndDetail);
                    PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail, DebutFeuille + DecDetail + 110, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), '¤ '+ConstArbreAuChoix,MinPolice);
                    Decalage := '     -';
                  end
                else
                  Decalage := '¤';
              end;

            LigneIndice := 0;
            For LigneEquip in StringEquip do
              begin
                Qualite    := '';
                Equipement := LigneEquip;
                if (Pos(EquipementQualite, Equipement) > 0) then
                  begin
                    Qualite    := ' '+EquipementQualite;
                    Equipement := Trim(ExtractStringBefore(LigneEquip,EquipementQualite));
                  end;
                LigneType := StringType[LigneIndice];
                Inc(LigneIndice);
                if InList(LigneType,TypeEquipMetierArme) then
                    begin
                      Inc(IndDetail);
                      PArme   := ChercheArme(Equipement);
                      if pos(ValeurGenerique, PArme.CodeArme) = 0 then
                        Inc(TotalEquip);
                      PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail, 999, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), Decalage+' '+PArme.Libelle+Qualite,MinPolice);
                      Inc(IndDetail, PdfRangeesSupp);
                    end
                  else if LigneType = TypeEquipAR then
                    begin
                      Inc(IndDetail);
                      Inc(TotalEquip);
                      PArmure := ChercheArmure(Equipement);
                      PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail, DebutFeuille + DecDetail + 110, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), Decalage+' '+PArmure.Libelle+Qualite,MinPolice);
                      Inc(IndDetail, PdfRangeesSupp);
                    end
                  else if LigneType = TypeEquipDI then
                    begin
                      Inc(IndDetail);
                      // Un code Divers peut etre un Trapping catalogue (RULES-TRAP_xxx) : on affiche son libelle.
                      PTrapping := ChercheTrapping(Equipement);
                      if PTrapping.CodeTrapping <> '' then
                        LibDivers := PTrapping.Libelle
                      else
                        LibDivers := LibelleEquipementV1(Equipement);
                      PdfEcrit(PdfPage,DebutFeuille + DecDetail + DebutDetail, DebutFeuille + DecDetail + 110, PdfPositionFeuille(DebutTexte,NbLigne,IndDetail+NbDetail), Decalage+' '+LibDivers+Qualite,MinPolice);
                      Inc(IndDetail, PdfRangeesSupp);
                    end;
                end;
              StringEquip.free;
              StringType.Free;
            end;
    end;

  // V1/V2 : carrieres d'origine (Entrees = True, calcul inverse de <ExitCodes>) ou carrieres
  // qui suivent. Le livre est ajoute entre parentheses sauf pour le Rulebook.
  procedure ChargeLiens(Entrees: Boolean; Lignes: TStringList);
    var
      PSortie: StructureMetierSortie;
      PLien: StructureMetier;
      Code, Lib, Liv: String;
      I: Integer;
    begin
      for PSortie in ListMetierSortie do
        begin
          if Entrees then
            begin
              if PSortie.CodeSortie <> MetierEnCours then Continue;
              Code := PSortie.CodeMetier;
            end
          else
            begin
              if PSortie.CodeMetier <> MetierEnCours then Continue;
              Code := PSortie.CodeSortie;
            end;
          PLien := ChercheMetier(Code);
          Lib := PLien.Libelle;
          Liv := '';
          if RechercheTrouve then
            begin
              if (PLien.Livre <> '') and (Pos('RULESBOOK', UpperCase(PLien.Livre)) = 0) then
                Liv := GetTexteLibelle(PLien.Livre, '', '', true);
            end
          else
            begin
              // Carriere citee sans fiche : nom deduit du code (RULES-WORK_PIT_FIGHTER -> Pit Fighter),
              // pas de livre invente.
              Lib := LowerCase(StringReplace(CodeSansLivre(Code), '_', ' ', [rfReplaceAll]));
              if Pos(' ', Lib) > 0 then
                Lib := Copy(Lib, Pos(' ', Lib) + 1, MaxInt);
              for I := 1 to Length(Lib) do
                if (I = 1) or (Lib[I - 1] = ' ') then
                  Lib[I] := UpCase(Lib[I]);
            end;
          // Le libelle d un livre non officiel commence par « (F) » : on l enleve pour ne pas
          // obtenir « ((F) Livre) ».
          if Copy(Liv, 1, 4) = '(F) ' then
            Liv := Copy(Liv, 5, MaxInt);
          if Liv <> '' then
            Lib := Lib + ' (' + Liv + ')';
          if Lignes.IndexOf(Lib) < 0 then
            Lignes.Add(Lib);
        end;
    end;

  // V1/V2 : libelles des talents de la carriere (famille a etoile et choix A/B inclus), une ligne chacun.
  procedure ChargeTalentsListe(Lignes: TStringList);
    var
      PMetierTalent: StructureMetierTalent;
      Texte: String;
    begin
      for PMetierTalent in ListMetierTalent do
        if PMetierTalent.CodeMetier = MetierEnCours then
          begin
            Texte := ChercheTalent(PMetierTalent.CodeTalent).Libelle;
            if Texte = '' then
              begin
                Texte := LibelleFamilleTalent(PMetierTalent.CodeTalent);
                if (Texte = '') and (Pos('/', PMetierTalent.CodeTalent) > 0) then
                  Texte := LibelleChoix(True, PMetierTalent.CodeTalent);
              end;
            Lignes.Add(Texte);
          end;
    end;

  // Bande grise + lignes, dans la colonne de droite, a la suite des competences (meme mise en
  // page que NiveauCompetences).
  procedure BandeLiens(Titre: String; Lignes: TStringList);
    var
      Coord: TPDFCoord;
      I, Supp: Integer;
    begin
      if Lignes.Count = 0 then Exit;
      Inc(NbLigne);
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne,NbDetail)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, Titre + ' : ',MinPolice);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson+ConstPoliceItalique, 9);
      Supp := 0;   // rangees prises en plus par les lignes coupees
      for I := 0 to Lignes.Count - 1 do
        begin
          PdfEcrit(PdfPage,DebutFeuille + DebutDetail, DebutFeuille + LargeurFeuille - MargeDroite, PdfPositionFeuille(DebutTexte,NbLigne,I+1+Supp+NbDetail), '¤ '+Lignes[I],MinPolice);
          Inc(Supp, PdfRangeesSupp);
        end;
      NbDetail := NbDetail + Lignes.Count + Supp;
    end;

  // TOW : carriere lue dans TowCarrieresCache (les listes V1 a V5 sont vides en TOW). Faux si absente.
  function TrouveCarriereTow(out C: TTowCarriere): Boolean;
    var
      I: Integer;
      Cache: TTowCarrieres;
    begin
      Result := False;
      Cache := TowCarrieresCache;
      for I := 0 to High(Cache) do
        if Cache[I].Code = MetierEnCours then
          begin
            C := Cache[I];
            Result := True;
            Exit;
          end;
    end;

  // TOW : une * dans la case des 3 caracteristiques favorisees de la carriere, sous l en-tete du tableau.
  procedure MarqueFavorisTow;
    var
      C: TTowCarriere;
      PAttribut: StructureAttribut;
      Ind, K: Integer;
    begin
      if not TrouveCarriereTow(C) then Exit;
      PdfPage.SetColor(clBlack,false);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson, 9);
      Ind := 0;
      for PAttribut in ListeAttribut do
        begin
          Inc(Ind);
          if Ind > 10 then Break;
          for K := 0 to High(C.Favoris) do
            if C.Favoris[K] = PAttribut.CodeAttribut then
              PdfCentre(PdfPage, DebutImgMetier + ((Ind-1)*TailleCellule), DebutImgMetier + (Ind*TailleCellule), 261.15 - HautAttribut + 1.15, '*');
        end;
    end;

  // TOW : bande grise + lignes. Une ligne commencant par « ~ » est un sous-choix (retrait, tiret).
  procedure BandeTow(Titre: String; Lignes: TStringList);
    var
      Coord: TPDFCoord;
      I: Integer;
    begin
      if Lignes.Count = 0 then Exit;
      Inc(NbLigne);
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne,NbDetail)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, Titre + ' : ',MinPolice);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson+ConstPoliceItalique, 9);
      for I := 0 to Lignes.Count - 1 do
        if Copy(Lignes[I], 1, 1) = '~' then
          PdfEcrit(PdfPage,DebutFeuille + DebutDetail + 5, DebutFeuille + LargeurFeuille - MargeDroite, PdfPositionFeuille(DebutTexte,NbLigne,I+1+NbDetail), '- '+Copy(Lignes[I], 2, MaxInt),MinPolice)
        else
          PdfEcrit(PdfPage,DebutFeuille + DebutDetail, DebutFeuille + LargeurFeuille - MargeDroite, PdfPositionFeuille(DebutTexte,NbLigne,I+1+NbDetail), '¤ '+Lignes[I],MinPolice);
      NbDetail := NbDetail + Lignes.Count;
    end;

  // TOW : emplacements (un code = fixe ; plusieurs = « {Au choix} » puis les options en sous-lignes).
  procedure SlotsTow(Lignes: TStringList; const Slots: TTowSlots);
    var
      S, J: Integer;
    begin
      for S := 0 to High(Slots) do
        if Length(Slots[S]) = 1 then
          Lignes.Add(TowLibelleDe(Slots[S][0]))
        else
          begin
            Lignes.Add(ConstArbreAuChoix);
            for J := 0 to High(Slots[S]) do
              Lignes.Add('~' + TowLibelleDe(Slots[S][J]));
          end;
    end;

  // TOW : colonne de droite = origines et plages de d100, statut, competences, lores, talent de carriere,
  // contacts, equipement, atouts (memes donnees que WinMetier, ChargeMetierTow).
  procedure DessineTow;
    var
      C: TTowCarriere;
      Origines: TTowOrigines;
      L: TStringList;
      I, K: Integer;
      Pl: String;
    begin
      PdfPage.DrawImage(DebutFeuille - 2, 15, LargeurFeuille, 260, PdfImgFeuille);
      NbLigne    := 0;
      NbDetail   := 0;
      DebutTexte := 265;
      if not TrouveCarriereTow(C) then Exit;
      Origines := TowOriginesCache;
      L := TStringList.Create;
      try
        for I := 0 to High(Origines) do
          if TowCarriereAdmise(C, Origines[I].Code) then
            begin
              Pl := '';
              for K := 0 to High(C.Plages) do
                if (C.Plages[K].Origine = Origines[I].Code) and (C.Plages[K].De > 0) then
                  begin
                    if C.Plages[K].De = C.Plages[K].A then
                      Pl := ' : ' + IntToStr(C.Plages[K].De)
                    else
                      Pl := ' : ' + IntToStr(C.Plages[K].De) + '-' + IntToStr(C.Plages[K].A);
                  end;
              L.Add(Origines[I].Libelle + Pl);
            end;
        BandeTow(ConstArbreRacepossible, L);

        L.Clear;
        L.Add(C.Status);
        BandeTow('Status', L);

        L.Clear;
        L.Add(IntToStr(C.CompNb) + ' x ' + ConstArbreAuChoix + ' (+1)');
        for K := 0 to High(C.CompChoix) do
          L.Add('~' + TowLibelleDe(C.CompChoix[K]));
        BandeTow(ConstArbreCompetence, L);

        L.Clear;
        SlotsTow(L, C.LoreSlots);
        BandeTow('Lores', L);

        L.Clear;
        if C.TalentCarriere <> '' then
          L.Add(C.TalentCarriere);
        BandeTow(ConstArbreTalent, L);

        L.Clear;
        for K := 0 to High(C.Familles) do
          L.Add(TowLibelleDe(C.Familles[K]));
        BandeTow(GetTexteLibelle('RULES-MESS_141'), L);

        L.Clear;
        SlotsTow(L, C.TrappingSlots);
        BandeTow(ConstArbreEquipement, L);

        L.Clear;
        SlotsTow(L, C.AssetSlots);
        BandeTow(GetTexteLibelle('RULES-MESS_140'), L);
      finally
        L.Free;
      end;
    end;

  // TOW : encadre du bas = texte du talent de carriere, coupe a ~70 caracteres par ligne.
  procedure DessineInfosBasTow;
    var
      C: TTowCarriere;
      Texte, Ligne, Mot: String;
      Mots, L: TStringList;
      I: Integer;
      Coord: TPDFCoord;
    begin
      if not TrouveCarriereTow(C) then Exit;
      if C.TalentCarriere = '' then Exit;
      Texte := C.TalentCarriereTexte;
      if Texte = '' then
        Texte := TowExplicationDe('CAREER-TALENT:' + C.Code);
      L := TStringList.Create;
      Mots := TStringList.Create;
      try
        Mots.Delimiter := ' ';
        Mots.StrictDelimiter := True;
        Mots.DelimitedText := StringReplace(StringReplace(Texte, #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]);
        Ligne := '¤' + C.TalentCarriere + ' :';
        for I := 0 to Mots.Count - 1 do
          begin
            Mot := Mots[I];
            if Mot = '' then Continue;
            if Length(Ligne) + Length(Mot) + 1 > 70 then
              begin
                L.Add(Ligne);
                Ligne := Mot;
              end
            else
              Ligne := Ligne + ' ' + Mot;
          end;
        L.Add(Ligne);
        PdfPage.DrawImage(DebutImgMetier-2, 15, 90, (L.Count + 1) * 4, PdfImgFeuille);
        PdfPage.SetColor(clBlack,false);
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceCarlson, 9);
        for I := 0 to L.Count - 1 do
          PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(L.Count-1-I)*4, L[I],MinPolice);
        PdfPage.SetColor($E0E0E0,false);
        Coord.X := DebutImgMetier + 1;
        Coord.Y := 19+L.Count*4;
        PdfPage.DrawRect(Coord, MaxTailleDetail - DebutImgMetier - 15,4,0,true,false,0);
        PdfPage.SetColor(clBlack,false);
        PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
        PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+L.Count*4, GetTexteLibelle('RULES-LAB_007'),MinPolice);
        NbDetail := L.Count + 2;
      finally
        Mots.Free;
        L.Free;
      end;
    end;

  // Colonne de droite : une bande par niveau (libelle, salaire), puis competences, talents, equipement.
  procedure DessineNiveaux;
    var
      Path: String;
      IWidth, IHeight: dword;
      CWidth, cHeight: dword;
      Nv: Integer;
      Coord: TPDFCoord;
      PMetierNiveau: StructureMetierNiveau;
      LiensOrigine, LiensSuite: TStringList;
    begin
    Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierAdvance);
    PdfPage.DrawImage(DebutFeuille - 2, 15, LargeurFeuille, 260, PdfImgFeuille);

    NbLigne := 0;
    NbDetail:= 0;
    DebutTexte := 265;
    // V1/V2 : carriere sans niveau. Une seule bande, les competences ; talents et equipement
    // sont deja dans l encadre du bas (DessineInfosBas).
    if ChercheMaxMetierNiveau(MetierEnCours) = 0 then
      begin
        PdfModeListe := true;   // lignes longues : coupees apres un « / », rangees decalees
        Inc(NbDetail);
        NiveauCompetences(1);
        // V1/V2 : les talents ne sont PAS a droite des competences (libelles longs et choix
        // multiples se chevauchent) mais dans leur propre bande dessous, puis la bande equipement.
        // Niveau 0 = tous les niveaux (le niveau saisi pour un equipement V1/V2 n est pas fiable).
        NbDetail := NbDetail + IndDetail;
        LiensOrigine := TStringList.Create;
        try
          ChargeTalentsListe(LiensOrigine);
          BandeLiens(GetTexteLibelle('RULES-LAB_007'), LiensOrigine);
        finally
          LiensOrigine.Free;
        end;
        NiveauEquipements(0);
        NbDetail := NbDetail + IndDetail;
        LiensOrigine := TStringList.Create;
        LiensSuite   := TStringList.Create;
        try
          ChargeLiens(True, LiensOrigine);
          ChargeLiens(False, LiensSuite);
          BandeLiens(GetTexteLibelle('RULES-LAB_703'), LiensOrigine);
          BandeLiens(GetTexteLibelle('RULES-LAB_704'), LiensSuite);
        finally
          LiensOrigine.Free;
          LiensSuite.Free;
        end;
        PdfModeListe := false;
        Exit;
      end;
    // Depuis le premier niveau du metier : une carriere qui commence au 3 ne doit pas
    // afficher les icones des niveaux 1 et 2, qu'aucune bande ne suit.
    for Nv := NvMinMetier to ChercheMaxMetierNiveau(MetierEnCours) do
      begin
        Inc(NBDetail);
        Path := CheminNiveauImageMetier(MetierEnCours, Nv);
        if PdfImgNv[Nv-1] >= 0 then
          begin
            GetImageSize(Path, IWidth, IHeight);
            RedimensionneImage(IWidth, IHeight, 5, 5, CWidth, cHeight);
            PdfPage.DrawImage(DebutFeuille + 5 ,PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) - 1, CWidth, cHeight, PdfImgNv[Nv-1]);
          end;
        for PMetierNiveau in ListMetierNiveau do
          if (PMetierNiveau.CodeMetier = Metierencours) and (PMetierNiveau.NiveauMetier = Nv) then
            begin
              // rectangle
              PdfPage.SetColor(ColorToARGB(ColorList[Nv],0),false);
              Coord.X := DebutFeuille + 11;
              Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) - 1;
              PdfPage.DrawRect(Coord,LargeurFeuille - MargeDroite -11 ,5,0,true,false,0);

              // libellé niveau et salaire
              PdfPage.SetColor(clBlack,false);
              PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
              PdfEcrit(PdfPage,DebutFeuille + 12, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, PMetierNiveau.Libelle,MinPolice);
              // Prefixe RULES- ajoute le 12/09/2026 - meme correctif que pdfpersonnage.pas, voir
              // son commentaire (CONTEXT.md 2.49/2.61).
              PdfEcrit(PdfPage,DebutFeuille + 75, 999, PdfPositionFeuille(DebutTexte,NbLigne,NbDetail) + 0.5, GetTexteLibelle('RULES-' + PMetierNiveau.SalaireMetier, '', ' '),MinPolice);

              NiveauCompetences(Nv);
              NiveauTalents(Nv);
              NiveauEquipements(Nv);

    NbDetail := NbDetail + IndDetail;
    Inc(NbLigne);
            end;
      end;
    end;

  // Encadre du bas de page : adaptations, talents puis equipement de toute la carriere.
  procedure DessineInfosBas;
    var
      Ind: Integer;
      Coord: TPDFCoord;
      PMetierTalent: StructureMetierTalent;
      PTalent: StructureTalent;
      PMetierEquipement: StructureMetierEquipement;
      PArme: StructureArme;
      PArmure: StructureArmure;
      StringEquip: TStringList;
      StringType: TStringList;
      LigneEquip: String;
      LigneType: String;
      LigneIndice: Integer;
      Equipement: String;
      DernierTalent: Integer;
      LignesAdapt: TStringList;
      AvecTalent: Boolean;
      TexteTalent: String;
      PosPoint: Integer;
    begin
      // V1/V2 (carriere sans niveau) : NiveauTalents et NiveauEquipements ne sont pas appeles, les
      // totaux sont donc a zero alors que l encadre imprime tous les talents et l equipement de la
      // carriere. On compte ici les memes lignes que la boucle d impression plus bas, sinon le fond
      // reste trop petit (vu sur CCOMP_CARE_ABBOT).
      if ChercheMaxMetierNiveau(MetierEnCours) = 0 then
        begin
          TotalTalent := 0;
          TotalEquip  := 0;
          for PMetierTalent in ListMetierTalent do
            if PMetierTalent.CodeMetier = MetierEnCours then
              Inc(TotalTalent);
          for PMetierEquipement in ListMetierEquipement do
            if PMetierEquipement.CodeMetier = MetierEnCours then
              begin
                StringEquip := TStringList.Create;
                StringType  := TStringList.Create;
                ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.Equipement), StringEquip);
                ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.TypeEquipement), StringType);
                for LigneIndice := 0 to StringEquip.Count - 1 do
                  begin
                    LigneType  := StringType[LigneIndice];
                    Equipement := Trim(ExtractStringBefore(StringEquip[LigneIndice],EquipementQualite));
                    if InList(LigneType,TypeEquipMetierArme) then
                      begin
                        PArme := ChercheArme(Equipement);
                        if Pos(ValeurGenerique,PArme.CodeArme) = 0 then
                          Inc(TotalEquip);
                      end
                    else if LigneType = TypeEquipAR then
                      Inc(TotalEquip);
                  end;
                StringEquip.Free;
                StringType.Free;
              end;
        end;
      // dessin fond info complémentaires
      If TotalTalent > 0 then
        Totaltalent := Totaltalent + 1;
      If TotalEquip > 0 then
        TotalEquip := TotalEquip + 1;
      // Adapting Careers : en bas du pave de droite (les lignes montent depuis y=20)
      LignesAdapt := TStringList.Create;
      PdfLignesAdaptation(MetierEnCours, LignesAdapt);
      // V1 : les talents n existent pas, ni leur en-tete ni leur liste dans l encadre du bas.
      AvecTalent := ValVersion <> 'WFRP1';
      if not AvecTalent then
        begin
          TotalTalent := 0;
          // Rien a mettre dans l encadre : pas d equipement chiffre, pas d adaptation.
          if (TotalEquip = 0) and (LignesAdapt.Count = 0) then
            begin
              LignesAdapt.Free;
              NbDetail := 0;
              Exit;
            end;
        end;
      PdfPage.DrawImage(DebutImgMetier-2, 15, 90, (TotalEquip + TotalTalent + 1 + Ord(AvecTalent) + LignesAdapt.Count) * 4, PdfImgFeuille);

      // information complémentaires
        // Adaptations, tout en bas
        PdfPage.SetColor(clBlack,false);
        for Ind := 0 to LignesAdapt.Count - 1 do
          PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(LignesAdapt.Count-1-Ind)*4, LignesAdapt[Ind],MinPolice);
        // Talent
        NbDetail := LignesAdapt.Count;
        LignesAdapt.Free;
        if AvecTalent then
        For Ind := ListMetierTalent.count -1 downto 0 do
          begin
            PMetierTalent := ListMetierTalent[Ind];
            if (PMetierTalent.CodeMetier = MetierEnCours) then
              begin
                inc(Nbdetail);
                PTalent := ChercheTalent(PMetierTalent.CodeTalent);
                if (PTalent.Libelle = '') and (LibelleFamilleTalent(PMetierTalent.CodeTalent) <> '') then
                  PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbDetail-1)*4, '¤'+LibelleFamilleTalent(PMetierTalent.CodeTalent),MinPolice)
                else if (PTalent.Libelle = '') and (Pos('/', PMetierTalent.CodeTalent) > 0) then
                  PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbDetail-1)*4, '¤'+LibelleChoix(True, PMetierTalent.CodeTalent),MinPolice)
                else
                  begin
                    // V5 / TOW : Short vide, le texte est dans Explanation (Description) ; on n en
                    // garde que la premiere phrase pour tenir sur la ligne de l encadre.
                    TexteTalent := PTalent.Resume;
                    if TexteTalent = '' then
                      begin
                        TexteTalent := PTalent.Description;
                        PosPoint := Pos('. ', TexteTalent);
                        if PosPoint > 0 then
                          TexteTalent := Copy(TexteTalent, 1, PosPoint);
                        // une seule ligne, a la police minimale : sinon la ligne passe sur deux rangees
                        // et recouvre la suivante. On coupe au dernier mot qui tient, suivi de « ... ».
                        // borne a 94 : le fond du bas s arrete vers x = 97 (MaxTailleDetail = 110 le depassait)
                        if TailleTexte('¤'+PTalent.Libelle+' : '+TexteTalent, MinPolice) > (94 - DebutImgMetier - 2) * 1.15 then
                          begin
                            while (Pos(' ', TexteTalent) > 0) and
                                  (TailleTexte('¤'+PTalent.Libelle+' : '+TexteTalent+'...', MinPolice) > (94 - DebutImgMetier - 2) * 1.15) do
                              TexteTalent := TrimRight(Copy(TexteTalent, 1, LastDelimiter(' ', TexteTalent) - 1));
                            TexteTalent := TexteTalent + '...';
                          end;
                      end;
                    PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbDetail-1)*4, '¤'+PTalent.Libelle+' : '+TexteTalent,MinPolice);
                  end
              end;
          end;
        if AvecTalent then
          begin
            inc(NbDetail);
            PdfPage.SetColor($E0E0E0,false);
            Coord.X := DebutImgMetier + 1;
            Coord.Y := 19+(NbDetail-1)*4;
            PdfPage.DrawRect(Coord, MaxTailleDetail - DebutImgMetier - 15,4,0,true,false,0);

            PdfPage.SetColor(clBlack,false);
            PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbDetail-1)*4, GetTexteLibelle('RULES-LAB_007'),MinPolice);
            inc(NbDetail);
          end;
        DernierTalent := NbDetail;
        For Ind := ListMetierEquipement.count -1 downto 0 do
          begin
            PMetierEquipement := ListMetierEquipement[Ind];
            if (PMetierEquipement.CodeMetier = MetierEnCours) then
              begin
                StringEquip := TStringList.Create;
                StringType  := TStringList.Create;

                ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.Equipement), StringEquip);
                ExtractStrings([SeparateurMulti], [], PChar(PMetierEquipement.TypeEquipement), StringType);

                LigneIndice := 0;
                For LigneEquip in StringEquip do
                  begin
                    Equipement := Trim(ExtractStringBefore(LigneEquip,EquipementQualite));
                    LigneType  := StringType[LigneIndice];
                    Inc(LigneIndice);

                    if InList(LigneType,TypeEquipMetierArme) then
                        begin
                          PArme   := ChercheArme(Equipement);
                          if Pos(ValeurGenerique,PArme.CodeArme) = 0 then
                            begin
                              Inc(NbDetail);
                              PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbDetail-1)*4, '¤'+TexteLigneArme(PArme),MinPolice);
                            end;
                        end
                      else if LigneType = TypeEquipAR then
                        begin
                          PArmure := ChercheArmure(Equipement);
                          Inc(NbDetail);
                          PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbDetail-1)*4, '¤'+TexteLigneArmure(PArmure),MinPolice);
                        end;
                  end;
              end;
          end;
      if DernierTalent <> NbDetail then
        begin
          inc(NbDetail);
          PdfPage.SetColor($E0E0E0,false);
          Coord.X := DebutImgMetier + 1;
          Coord.Y := 19+(NbDetail-1)*4;
          PdfPage.DrawRect(Coord, MaxTailleDetail - DebutImgMetier - 15,4,0,true,false,0);

          PdfPage.SetColor(clBlack,false);
          PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail - DebutImgMetier - 2 , 20+(NbDetail-1)*4, GetTexteLibelle('RULES-LAB_013'),MinPolice);
        end;
    end;

  // Image de la carriere, sous le schema d avance.
  procedure DessineImageMetier;
    var
      Path: String;
      PdfImgMetier: Integer;
      IWidth, IHeight: dword;
      CWidth, cHeight: dword;
    begin
      // image métier
      Path              := CheminMetierImage(MetierEnCours);
      // Un metier sans image (fichier absent) ne doit pas faire planter le PDF.
      if FileExists(Path) then
        begin
          PdfImgMetier      := PdfDoc.Images.AddFromFile(Path,false);
          GetImageSize(Path, IWidth, IHeight);
          // Fond plein : l'image reste dans la colonne de gauche (largeur 90) ; fond transparent :
          // le debordement voulu (95) est conserve.
          if ImageAFondTransparent(Path) then
            RedimensionneImage(IWidth, IHeight, 95, Trunc(finAttribut) - 30 -(NbDetail*4), CWidth, cHeight)
          else
            RedimensionneImage(IWidth, IHeight, 90, Trunc(finAttribut) - 30 -(NbDetail*4), CWidth, cHeight);
          PdfPage.DrawImage(DebutImgMetier-2, FinAttribut - cHeight - 5, cWidth, cHeight, PdfImgMetier);
        end;
    end;

begin
  PMetier := chercheMetier(MetierEnCours);
  // Premier et dernier niveau de CE metier. Une carriere avancee - Smith-priest of Vaul,
  // Storm Weaver, Loremaster of Hoeth - ne declare que les niveaux 3 a 5 : partir de 1
  // dessinait deux lignes vides en haut du schema d'avance et deux icones orphelines au
  // debut de la colonne de droite (signale par Nono le 31/08/2026, capture a l'appui).
  //
  // NbNiveauMetier devient donc un NOMBRE DE LIGNES et non le numero du dernier niveau.
  // Les deux valaient la meme chose tant que tout commencait a 1, et toute la geometrie
  // ci-dessous s'en servait deja comme d'un compte - elle n'a donc pas a changer.
  NvMinMetier    := ChercheMinMetierNiveau(MetierEnCours);
  if NvMinMetier < 1 then
    NvMinMetier  := 1;
  NbNiveauMetier := ChercheMaxMetierNiveau(MetierEnCours) - NvMinMetier + 1;
  if NbNiveauMetier < 1 then
    NbNiveauMetier := 1;

  PrepareIcones;

  ListPage       := TStringList.Create;

  PdfPersonnageCompetenceTri(ListPage);

  CheminClass     := CheminImageClasse(PMetier.LibelleGroupe);
  ChargeImageClasse;

  DessineEntete;
  DessineSchemaAvance;
  if ValVersion = 'WFRPTOW' then
    begin
      MarqueFavorisTow;
      DessineTow;
      DessineInfosBasTow;
    end
  else
    begin
      DessineNiveaux;
      DessineInfosBas;
    end;
  DessineImageMetier;

  ListPage.Free;
end;

end.


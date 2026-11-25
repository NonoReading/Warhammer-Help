unit PdfRace;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpPDF, Dialogs, MessageTest, PicsLib, Graphics, LCLIntf,
  ChargeRace, ChargeEspece, ChargeConstantes, ChargeAttribut, ChargeRaceAttribut,
  ChargeRaceCompetence, ChargeCompetence, ChargeRaceTalent, ChargeTalent,
  ChargeRaceMetier, ChargeTirageMetier, ChargeMetier, ChargeMetierAttribut, ChargeCreationTow, PdfPersonnage,
  ChargeTexte, PdfUtils, UnitCalcul;

Procedure PdfRaceCreation(RaceEnCours: String);
function PdfPositionFeuille(Base:Integer; NbLigne:Integer): Real;

implementation

Var
  HautFeuille:   Integer = 0;

function PdfPositionFeuille(Base:Integer; NbLigne:Integer): Real;
var
  TailleLigne:  Real = 3.5;

begin
  Result := Base - (NbLigne * TailleLigne) + 1 - HautFeuille;
end;

Procedure PdfRaceCreation(RaceEnCours: String);
  var
    PDFDoc:             TPDFDocument;
    PDFSection:         TPDFSection;
    PDFPage:            TPDFPage;
    PdfChemin:          String;
    PDFOption:          TPDFOptions;
    PRace:              StructureRace;
    MinPolice:          integer = 7;
    DebutFeuille:       Integer = 100;
    LargeurFeuille:     Integer = 100;
    DebutImgMetier:     Integer = 10;
    TailleCellule:      Integer = 8;
    HautAttribut:       Integer = 5;
    DebutSous:          Integer = 10;
    DebutTalent:        Integer = 60;
    NbLigne:            Integer = 0;
    DebutTexte:         Integer = 265;
    MargeDroite:        Integer = 5;
    DecAuchoix:         Integer = 0;
    DebutCompetence:    Integer;
    NbTalent:           Integer;
    Totaltalent:        Integer = 0;
    MaxTailleDetail:    Integer = 110;
    ListPage:           TStringList;

    // The Old World : donnees de l'origine (le livre TOW n'a pas de DATA_RACE_*), comme WinRace.
    function TrouveOrigineTow(out O: TTowOrigine): Boolean;
      var
        Orig: TTowOrigines;
        I: Integer;
      begin
      Result := False;
      Orig   := TowOriginesCache;
      for I := 0 to High(Orig) do
        if Orig[I].Code = RaceEnCours then
          begin
            O      := Orig[I];
            Result := True;
            Exit;
          end;
      end;

    // Fond, filets, titre et image de feuille.
    procedure DessineFondEntete;
      var
        PdfImgFront, PdfImgGauche, PdfImgDroite, PdfImgFeuille: Integer;
        Path: String;
        IWidth, IHeight: dword;
        CWidth, cHeight: dword;
      begin
    // image fond
    Path              := CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfMetierBack, ConstLangue, ValLangue, [rfReplaceAll]));
    PdfImgFront       := PdfDoc.Images.AddFromFile(Path);
    PdfPage.DrawImage(0, 0, 210, 297, PdfImgFront);

    // Haut et bas de page
      // gauche
      Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierLigneG);
      PdfImgGauche      := PdfDoc.Images.AddFromFile(Path,false);
      GetImageSize(Path, IWidth, IHeight);
      RedimensionneImage(IWidth, IHeight, 85, 999, CWidth, cHeight);
      PdfPage.DrawImage(10, 10, cWidth, cHeight, PdfImgGauche);
      PdfPage.DrawImage(10, 287, cWidth, cHeight, PdfImgGauche);

      // droite
      Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierLigneD);
      PdfImgDroite      := PdfDoc.Images.AddFromFile(Path,false);
      GetImageSize(Path, IWidth, IHeight);
      RedimensionneImage(IWidth, IHeight, 85, 999, CWidth, cHeight);
      PdfPage.DrawImage(115, 10, cWidth, cHeight, PdfImgDroite);
      PdfPage.DrawImage(115, 287, cWidth, cHeight, PdfImgDroite);

      // texte
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 9);
      PdfCentre(PdfPage, 95, 115, 11, WideUpperCase(WideString(ChercheEspece(PRace.Espece).Libelle)){%H-});
      PdfCentre(PdfPage, 95, 115, 288, WideUpperCase(WideString(ChercheEspece(PRace.Espece).Libelle)){%H-});

      // texte
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 24);
      PdfEcrit(PdfPage, 17, 999, 278, WideUpperCase(WideString(PRace.Libelle)){%H-},MinPolice);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 9);
      PdfEcrit(PdfPage, DebutImgMetier, 999, 268, GetTexteLibelle('RULES-LAB_128') {%H-}+ ' : ' + WideUpperCase(WideString(GetTexteLibelle(PRace.Livre))){%H-}, MinPolice);


      // image Feuille
      Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierAdvance);
      PdfImgFeuille     := PdfDoc.Images.AddFromFile(Path,false);
      PdfPage.DrawImage(DebutFeuille - 2, 15, LargeurFeuille, 260, PdfImgFeuille);
      end;

    // Attributs de la race (tableau puis attributs complementaires).
    procedure SectionAttributs;
      var
        Ind: Integer;
        Coord: TPDFCoord;
        PAttribut: StructureAttribut;
        PRaceAttribut: StructureRaceAttribut;
        StringAttribut: TStringList;
        IndAttribut: Integer;
        OTow: TTowOrigine;
        KTow: Integer;
      begin
      // Attributs complémentaires
      // rectangle
      Inc(NbLigne);
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous - 5;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous - 5, 999, PdfPositionFeuille(DebutTexte,NbLigne) + 0.5, GetTexteLibelle('RULES-LAB_008')+' : ',MinPolice);

      Ind := 0;
      For PAttribut in ListeAttribut do
        Begin
          Inc(Ind);
          if Ind <= 10 then
            begin
              PdfCentre(PdfPage,DebutImgMetier + ((Ind-1)*TailleCellule),DebutImgMetier + (ind*TailleCellule),267-HautAttribut,PAttribut.Resume);
              if ValVersion = 'WFRPTOW' then
                begin
                  // TOW : valeur de depart, et maximum entre parentheses sur la ligne du dessous
                  KTow := TowIndexCarac(PAttribut.CodeAttribut);
                  if (KTow > 0) and TrouveOrigineTow(OTow) then
                    begin
                      PdfCentre(PdfPage,DebutImgMetier + ((Ind-1)*TailleCellule),DebutImgMetier + (ind*TailleCellule),262-HautAttribut,IntToStr(OTow.Depart[KTow]));
                      if OTow.Maximum[KTow] > 0 then
                        PdfCentre(PdfPage,DebutImgMetier + ((Ind-1)*TailleCellule),DebutImgMetier + (ind*TailleCellule),257-HautAttribut,'('+IntToStr(OTow.Maximum[KTow])+')');
                    end;
                end
              else
              for PRaceAttribut in ListRaceAttribut do
                if (PRaceAttribut.CodeRace = RaceEnCours) and (PRaceAttribut.CodeAttribut = PAttribut.CodeAttribut) then
                  begin
                    PdfCentre(PdfPage,DebutImgMetier + ((Ind-1)*TailleCellule),DebutImgMetier + (ind*TailleCellule),262-HautAttribut,' '+ExtractStringBefore(PRaceAttribut.CalculRace,'+'));
                    PdfCentre(PdfPage,DebutImgMetier + ((Ind-1)*TailleCellule),DebutImgMetier + (ind*TailleCellule),257-HautAttribut,'+'+ExtractStringAfter(PRaceAttribut.CalculRace,'+'));
                    break;
                  end;
            end
          else
            begin
              for PRaceAttribut in ListRaceAttribut do
                if (PRaceAttribut.CodeRace = RaceEnCours) and (PRaceAttribut.CodeAttribut = PAttribut.CodeAttribut) then
                  begin
                    inc(NbLigne);
                    PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+PAttribut.Libelle,MinPolice);
                    StringAttribut  := TStringList.Create;
                    ExtractStrings(['+'], [], PChar(PRaceAttribut.CalculRace), StringAttribut);
                    for IndAttribut := 0 to StringAttribut.count - 1 do
                      begin
                        if indAttribut <> 0 then
                          begin
                            inc(NbLigne);
                            PdfEcrit(PdfPage,DebutFeuille + DebutSous + 30, 999, PdfPositionFeuille(DebutTexte,NbLigne), '   + '+ReplaceTexteLibelle(StringAttribut[IndAttribut]),MinPolice);
                          end
                        else
                          PdfEcrit(PdfPage,DebutFeuille + DebutSous + 30, 999, PdfPositionFeuille(DebutTexte,NbLigne), ': '+ReplaceTexteLibelle(StringAttribut[IndAttribut]),MinPolice);
                      end;
                    StringAttribut.Free;
                    break;
                  end;
            end;
        end;
      end;

    // Competences de race.
    procedure SectionCompetences;
      var
        Coord: TPDFCoord;
        PRaceCompetence: StructureRaceCompetence;
        PCompetence: StructureCompetence;
        PAttribut: StructureAttribut;
        TexteCompetence: String;
        IndC: Integer;
        Trouve: Boolean;
        OTow: TTowOrigine;
        KTow, JTow: Integer;
      begin
      // Compétences
      // rectangle
      Inc(NbLigne);
      Inc(NbLigne);
      DebutCompetence := NbLigne;
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous - 5;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous - 5, 999, PdfPositionFeuille(DebutTexte,NbLigne) + 0.5, GetTexteLibelle('RULES-LAB_009')+' : ',MinPolice);

      if ValVersion = 'WFRPTOW' then
        begin
          // TOW : competences fixes au rang de l'origine, N au choix, puis les lores
          if TrouveOrigineTow(OTow) then
            begin
              for KTow := 0 to High(OTow.CompFixes) do
                begin
                  Inc(NbLigne);
                  PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+TowLibelleDe(OTow.CompFixes[KTow])+' : '+IntToStr(OTow.CompRang), MinPolice);
                end;
              if OTow.CompLibres > 0 then
                begin
                  Inc(NbLigne);
                  PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+IntToStr(OTow.CompLibres)+' x '+ConstArbreAuChoix+' : '+IntToStr(OTow.CompRang), MinPolice);
                end;
              if Length(OTow.LoreSlots) > 0 then
                begin
                  Inc(NbLigne);
                  PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), 'Lores :', MinPolice);
                  for KTow := 0 to High(OTow.LoreSlots) do
                    if Length(OTow.LoreSlots[KTow]) = 1 then
                      begin
                        Inc(NbLigne);
                        PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+TowLibelleDe(OTow.LoreSlots[KTow][0]), MinPolice);
                      end
                    else
                      begin
                        Inc(NbLigne);
                        PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+ConstArbreAuChoix, MinPolice);
                        for JTow := 0 to High(OTow.LoreSlots[KTow]) do
                          begin
                            Inc(NbLigne);
                            PdfEcrit(PdfPage,DebutFeuille + DebutSous + 5, 999, PdfPositionFeuille(DebutTexte,NbLigne), '- '+TowLibelleDe(OTow.LoreSlots[KTow][JTow]), MinPolice);
                          end;
                      end;
                end;
            end;
        end
      else
      For PRaceCompetence in ListRaceCompetence do
        if (PRaceCompetence.CodeRace = RaceEnCours) then
          begin
            Inc(NbLigne);
            PCompetence := ChercheCompetence(PRaceCompetence.CodeCompetence);
            PAttribut := ChercheAttribut(PCompetence.CodeAttribut);
            TexteCompetence := Trim(PCompetence.Libelle);
            // V1 : pas de caracteristique liee, donc pas de crochets vides.
            if GetTexteLibelle(PAttribut.Resume) <> '' then
              TexteCompetence := TexteCompetence + ' ['+GetTexteLibelle(PAttribut.Resume)+']';
            Trouve          := false;
            for IndC := 0 to ListPage.count-1 do
              if ListPage[IndC] = PCompetence.CodeCompetence then
                begin
                  Trouve := true;
                  Break;
                end;

            if not trouve then
              TexteCompetence := TexteCompetence +' *';

            PdfEcrit(PdfPage,DebutFeuille + DebutSous, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+TexteCompetence, MinPolice);
          end;
      end;

    // Talents de race ; NbLigne reprend la colonne la plus longue.
    procedure SectionTalents;
      var
        Coord: TPDFCoord;
        PRaceTalent: StructureRaceTalent;
        PTalent: StructureTalent;
        StringTalent: TStringList;
        IndTalent: Integer;
        OTow: TTowOrigine;
        KTow: Integer;
      begin
      // Talents
      // rectangle
      NbTalent := DebutCompetence;
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutTalent - 5;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbTalent)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutTalent - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutTalent - 5, 999, PdfPositionFeuille(DebutTexte,NbTalent) + 0.5, GetTexteLibelle('RULES-LAB_007')+' : ',MinPolice);

      if ValVersion = 'WFRPTOW' then
        begin
          // TOW : talents fixes, table du d10, echange
          if TrouveOrigineTow(OTow) then
            begin
              for KTow := 0 to High(OTow.TalentsFixes) do
                begin
                  Inc(NbTalent);
                  PdfEcrit(PdfPage,DebutFeuille + DebutTalent, DebutFeuille + LargeurFeuille - MargeDroite - 5, PdfPositionFeuille(DebutTexte,NbTalent), '¤ '+TowLibelleDe(OTow.TalentsFixes[KTow]), MinPolice);
                end;
              if OTow.TalentTirages > 0 then
                begin
                  Inc(NbTalent);
                  PdfEcrit(PdfPage,DebutFeuille + DebutTalent, 999, PdfPositionFeuille(DebutTexte,NbTalent), '¤ '+IntToStr(OTow.TalentTirages)+' x d10', MinPolice);
                  for KTow := 0 to High(OTow.TableTalents) do
                    begin
                      Inc(NbTalent);
                      if OTow.TableTalents[KTow].De = OTow.TableTalents[KTow].A then
                        PdfEcrit(PdfPage,DebutFeuille + DebutTalent + 5, DebutFeuille + LargeurFeuille - MargeDroite - 5, PdfPositionFeuille(DebutTexte,NbTalent), IntToStr(OTow.TableTalents[KTow].De)+' : '+TowLibelleDe(OTow.TableTalents[KTow].Code), MinPolice)
                      else
                        PdfEcrit(PdfPage,DebutFeuille + DebutTalent + 5, DebutFeuille + LargeurFeuille - MargeDroite - 5, PdfPositionFeuille(DebutTexte,NbTalent), IntToStr(OTow.TableTalents[KTow].De)+'-'+IntToStr(OTow.TableTalents[KTow].A)+' : '+TowLibelleDe(OTow.TableTalents[KTow].Code), MinPolice);
                    end;
                end;
              if (OTow.Echange <> '') and (OTow.Echange <> 'NONE') and (OTow.TalentEchange <> '') then
                begin
                  Inc(NbTalent);
                  PdfEcrit(PdfPage,DebutFeuille + DebutTalent, DebutFeuille + LargeurFeuille - MargeDroite - 5, PdfPositionFeuille(DebutTexte,NbTalent), OTow.Echange+' : '+TowLibelleDe(OTow.TalentEchange), MinPolice);
                end;
            end;
        end
      else
      For PRaceTalent in ListRaceTalent do
        if (PRaceTalent.CodeRace = RaceEnCours) then
          begin
            StringTalent  := TStringList.Create;
            ExtractStrings([SeparateurMulti], [], PChar(PRaceTalent.CodeTalent), StringTalent);

            DecAuchoix := 0;
            For IndTalent := 0 to StringTalent.count - 1 do
              begin
                if (IndTalent = 0) and (StringTalent.count > 1) then
                  begin
                    Inc(NbTalent);
                    DecAuchoix := 5;
                    PdfEcrit(PdfPage,DebutFeuille + DebutTalent, 999, PdfPositionFeuille(DebutTexte,NbTalent), ConstArbreAuChoix, MinPolice);
                  end;
                Inc(NbTalent);
                PTalent := ChercheTalent(StringTalent[IndTalent]);
                PdfEcrit(PdfPage,DebutFeuille + DebutTalent + DecAuchoix, 999, PdfPositionFeuille(DebutTexte,NbTalent), '¤ '+PTalent.Libelle, MinPolice);
                Inc(Totaltalent);
              end;
          end;

      if NbTalent > NbLigne then
        NbLigne := NbTalent;
      end;

    // Carrieres possibles, groupees par classe, avec leur tirage.
    procedure SectionCarrieres;
      var
        Ind: Integer;
        Coord: TPDFCoord;
        PRaceMetier: StructureRaceMetier;
        PMetier: StructureMetier;
        DerniereClasse: String;
        TirageMetier: TListTirageMetier;
        PClasse: StructureClasseV1;
        LigneTirage: StructureTirageMetier;
        Des: Integer;
        CarrieresTow: TTowCarrieres;
        ITow, KTow: Integer;
        PlageTow: String;
      begin
      // CArrières
      // rectangle
      Inc(NbLigne);
      Inc(NbLigne);
      PdfPage.SetColor($E0E0E0,false);
      Coord.X := DebutFeuille + DebutSous - 5;
      Coord.Y := PdfPositionFeuille(DebutTexte,NbLigne)-0.5;
      PdfPage.DrawRect(Coord,LargeurFeuille - DebutSous - MargeDroite,4,0,true,false,0);
      PdfPage.SetColor(ClBlack,false);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 10);
      PdfEcrit(PdfPage,DebutFeuille + DebutSous - 5, 999, PdfPositionFeuille(DebutTexte,NbLigne) + 0.5, GetTexteLibelle('RULES-LAB_006')+' : ',MinPolice);

      DerniereClasse  := '';
      // table de tirage calculee une fois pour la race (pas une fois par ligne)
      TirageMetier    := TListTirageMetier.Create;
      CalculeTirageMetier(RaceEnCours, '', TirageMetier);
      DebutCompetence := NbLigne;
      if ValVersion = 'WFRPTOW' then
        begin
          // TOW : carrieres admises pour l'origine, avec la plage du d100 (rien = choix libre seulement)
          CarrieresTow := TowCarrieresCache;
          For ITow := 0 to High(CarrieresTow) do
            if TowCarriereAdmise(CarrieresTow[ITow], RaceEnCours) then
              begin
                PlageTow := '';
                For KTow := 0 to High(CarrieresTow[ITow].Plages) do
                  if (CarrieresTow[ITow].Plages[KTow].Origine = RaceEnCours) and (CarrieresTow[ITow].Plages[KTow].De > 0) then
                    if CarrieresTow[ITow].Plages[KTow].De = CarrieresTow[ITow].Plages[KTow].A then
                      PlageTow := IntToStr(CarrieresTow[ITow].Plages[KTow].De)
                    else
                      PlageTow := IntToStr(CarrieresTow[ITow].Plages[KTow].De)+'-'+IntToStr(CarrieresTow[ITow].Plages[KTow].A);
                if (DebutSous < 50) and (PdfPositionFeuille(DebutTexte,NbLigne + 2) < 20) then
                  begin
                    NbLigne   := DebutCompetence;
                    DebutSous := 50;
                  end;
                Inc(NbLigne);
                PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix, 999, PdfPositionFeuille(DebutTexte,NbLigne), '¤ '+CarrieresTow[ITow].Libelle, MinPolice);
                if (PlageTow <> '') and (TailleTexte(CarrieresTow[ITow].Libelle+'  ', PdfFontTaille) < 30) then
                  PdfPage.DrawLine(DebutFeuille + DebutSous + DecAuchoix + TailleTexte(CarrieresTow[ITow].Libelle+'  ', PdfFontTaille),PdfPositionFeuille(DebutTexte,NbLigne),DebutFeuille + DebutSous + DecAuchoix + 30,PdfPositionFeuille(DebutTexte,NbLigne),1);
                if PlageTow <> '' then
                  PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix + 30, 999, PdfPositionFeuille(DebutTexte,NbLigne), ' '+PlageTow, MinPolice);
              end;
        end
      else if ValVersion = 'WFRP1' then
        begin
          // V1 : une table de tirage par classe (regle CAREER_CHART_<CLASSE>), comme la creation V1
          For PClasse in ListClasseV1 do
            begin
              CalculeTirageMetier(RaceEnCours, StringReplace(PClasse.CodeClasse, 'CLASS_', 'RULE_CAREER_CHART_', []), TirageMetier);
              if TirageMetier.Count = 0 then Continue;
              Des := DesDuTirage(TirageMetier);
              if (DebutSous < 50) and (PdfPositionFeuille(DebutTexte,NbLigne + 4) < 20) then
                begin
                  NbLigne   := DebutCompetence;
                  DebutSous := 50;
                end;
              Inc(NbLigne);
              Inc(NbLigne);
              PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix, 999, PdfPositionFeuille(DebutTexte,NbLigne), ' '+LibelleClasse(PClasse.CodeClasse), MinPolice);
              For LigneTirage in TirageMetier do
                begin
                  PMetier := ChercheMetier(LigneTirage.CodeMetier);
                  if (DebutSous < 50) and (PdfPositionFeuille(DebutTexte,NbLigne + 2) < 20) then
                    begin
                      NbLigne   := DebutCompetence;
                      DebutSous := 50;
                    end;
                  Inc(NbLigne);
                  PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix, 999, PdfPositionFeuille(DebutTexte,NbLigne), '   ¤ '+PMetier.Libelle, MinPolice);
                  if TailleTexte(PMetier.Libelle+'  ', PdfFontTaille) < 30 then
                    PdfPage.DrawLine(DebutFeuille + DebutSous + DecAuchoix + TailleTexte(PMetier.Libelle+'  ', PdfFontTaille),PdfPositionFeuille(DebutTexte,NbLigne),DebutFeuille + DebutSous + DecAuchoix + 30,PdfPositionFeuille(DebutTexte,NbLigne),1);
                  PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix + 30, 999, PdfPositionFeuille(DebutTexte,NbLigne), ' '+FormateTranche(LigneTirage.Debut, LigneTirage.Fin, Des), MinPolice);
                end;
            end;
        end
      else
      For PRaceMetier in ListRaceMetier do
        if (PRaceMetier.CodeRace = RaceEnCours) and (PRaceMetier.Chance <> 'X') then
          begin
            if PdfPositionFeuille(DebutTexte,NbLigne + MetierRaceNbSuivant(RaceEnCours,PRaceMetier.CodeMetier) + 2) < 20 then
              Begin
                NbLigne   := DebutCompetence;
                DebutSous := 50;
              end;

            PMetier := ChercheMetier(PRaceMetier.CodeMetier);
            if DerniereClasse <> PMetier.LibelleGroupe then
              begin
                Inc(NbLigne);
                Inc(NbLigne);
                PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix, 999, PdfPositionFeuille(DebutTexte,NbLigne), ' '+GetTexteLibelle(PMetier. LibelleGroupe), MinPolice);

                DerniereClasse := PMetier.LibelleGroupe;
              end;

            Inc(NbLigne);
            PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix, 999, PdfPositionFeuille(DebutTexte,NbLigne), '   ¤ '+PMetier.Libelle, MinPolice);
            if TailleTexte(PMetier.Libelle+'  ', PdfFontTaille) < 30 then
              PdfPage.DrawLine(DebutFeuille + DebutSous + DecAuchoix + TailleTexte(PMetier.Libelle+'  ', PdfFontTaille),PdfPositionFeuille(DebutTexte,NbLigne),DebutFeuille + DebutSous + DecAuchoix + 30,PdfPositionFeuille(DebutTexte,NbLigne),1);
            PdfEcrit(PdfPage,DebutFeuille + DebutSous + DecAuchoix + 30, 999, PdfPositionFeuille(DebutTexte,NbLigne), ' '+ChanceLigneTirage(TirageMetier, PRaceMetier.CodeMetier, PRaceMetier.Chance), MinPolice);
          end;
      TirageMetier.Free;

      PdfPage.DrawLine(DebutImgMetier,271-HautAttribut,DebutImgMetier + (TailleCellule*10),271-HautAttribut,1);
      PdfPage.DrawLine(DebutImgMetier,266-HautAttribut,DebutImgMetier + (TailleCellule*10),266-HautAttribut,1);
      PdfPage.DrawLine(DebutImgMetier,256-HautAttribut,DebutImgMetier + (TailleCellule*10),256-HautAttribut,1);
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceCarlson+ConstPoliceGras, 9);
      for Ind := 1 to 9 do
        PdfPage.DrawLine(DebutImgMetier + (Ind*Taillecellule),256-HautAttribut,DebutImgMetier + (Ind*TailleCellule),271-HautAttribut,1);
      end;

    // Encadre du bas de page : descriptions des talents.
    procedure InfosBas;
      var
        PdfImgFeuille: Integer;
        Path: String;
        Ind: Integer;
        Coord: TPDFCoord;
        PRaceTalent: StructureRaceTalent;
        PTalent: StructureTalent;
        StringTalent: TStringList;
        IndTalent: Integer;
      begin
      // dessin fond info complémentaires
      If TotalTalent > 0 then
        Totaltalent := Totaltalent + 1;
      Path              := CheminImagePdf(GetCurrentDir+ConstCheminPdfMetierAdvance);
      PdfImgFeuille     := PdfDoc.Images.AddFromFile(Path,false);
      PdfPage.DrawImage(DebutImgMetier-2, 15, 90, (TotalTalent + 2) * 4, PdfImgFeuille);

      // information complémentaires
        // Talent
        NbLigne := 0;
        For Ind := ListRaceTalent.count -1 downto 0 do
          begin
            PRaceTalent := ListRaceTalent[Ind];
            if (PRaceTalent.CodeRace = RaceEnCours) then
              begin
                StringTalent  := TStringList.Create;
                ExtractStrings([SeparateurMulti], [], PChar(PRaceTalent.CodeTalent), StringTalent);

                DecAuchoix := 0;
                For IndTalent := 0 to StringTalent.count - 1 do
                  begin
                    inc(NbLigne);
                    PTalent := ChercheTalent(StringTalent[IndTalent]);
                    PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail, 20+(NbLigne-1)*4, '¤'+PTalent.Libelle+' : '+PTalent.Resume,MinPolice)
                  end;
              end;
          end;
        inc(NbLigne);
        PdfPage.SetColor($E0E0E0,false);
        Coord.X := DebutImgMetier + 1;
        Coord.Y := 19+(NbLigne-1)*4;
        PdfPage.DrawRect(Coord, MaxTailleDetail - DebutImgMetier - 15,4,0,true,false,0);
        PdfPage.SetColor(clBlack,false);
        PdfEcrit(PdfPage,DebutImgMetier+2, MaxTailleDetail - DebutImgMetier - 2 , 20+(NbLigne-1)*4, GetTexteLibelle('RULES-LAB_007'),MinPolice);

        PdfPage.SetColor(clBlack,false);
      end;

    // Illustrations de la race.
    procedure ImagesRace;
      var
        Path: String;
        Ind: Integer;
        PdfImgRace: Integer;
        IWidth, IHeight: dword;
        CWidth, cHeight: dword;
        NbImages: Integer;
        Opaque: Boolean;
        XImage: Integer;
      begin
    // Une seule illustration : elle prend la zone cumulee des deux emplacements
    // (x 0..125, y 105..230), centree, au lieu de rester a la taille d'une moitie.
    NbImages := 0;
    For Ind := 1 to 2 do
      if FileExists(CheminRaceImage(RaceEnCours, IntToStr(Ind))) then
        Inc(NbImages);
    // Aucune illustration : l'icone de la race de base, dans la meme zone qu'a l'ecran.
    if NbImages = 0 then
      begin
        Path := CheminIconeEspece(chercheRace(RaceEnCours).Espece);
        if Path <> '' then
          begin
            PdfImgRace := PdfDoc.Images.AddFromFile(Path,false);
            GetImageSize(Path, IWidth, IHeight);
            // colonne de droite du PDF des x ~105 : l'icone reste a gauche, marge du texte (x 13)
            RedimensionneImage(IWidth, IHeight, 85, 85, CWidth, cHeight);
            PdfPage.DrawImage(13, 105 + Round((125 - cHeight) / 2), cWidth, cHeight, PdfImgRace);
          end;
      end;
    // image race 1
    For Ind := 1 to 2 do
      begin
        Path              := CheminRaceImage(RaceEnCours, IntToStr(Ind));
        if FileExists(Path) then
          begin
            PdfImgRace        := PdfDoc.Images.AddFromFile(Path,false);
            GetImageSize(Path, IWidth, IHeight);
            // Fond plein : l'image ne doit pas deborder sur la colonne de droite (elle cacherait
            // les titres). Fond transparent : le debordement voulu en V4 est conserve.
            Opaque := not ImageAFondTransparent(Path);
            if NbImages = 1 then
              begin
                if Opaque then
                  begin
                    RedimensionneImage(IWidth, IHeight, 85, 125, CWidth, cHeight);
                    PdfPage.DrawImage(13, 105 + Round((125 - cHeight) / 2), cWidth, cHeight, PdfImgRace);
                  end
                else
                  begin
                    RedimensionneImage(IWidth, IHeight, 125, 125, CWidth, cHeight);
                    PdfPage.DrawImage(Round((125 - cWidth) / 2), 105 + Round((125 - cHeight) / 2), cWidth, cHeight, PdfImgRace);
                  end;
              end
            else
              begin
                if Opaque then
                  begin
                    RedimensionneImage(IWidth, IHeight, 85, 80, CWidth, cHeight);
                    XImage := 13;
                  end
                else
                  begin
                    RedimensionneImage(IWidth, IHeight, 95, 80, CWidth, cHeight);
                    XImage := 30;
                  end;
                PdfPage.DrawImage(XImage - ((ind-1) * 35), 150 - ((ind-1)*45), cWidth, cHeight, PdfImgRace);
              end;
          end;
      end;
      end;

begin
    PRace := chercheRace(RaceEnCours);

    // Chemin de l'image que vous souhaitez ajouter
    PdfChemin        := GetCurrentDir+ConstCheminPersonnage+'\'+NomFichierSur(TrimRight(PRace.Libelle))+'.PDF';

    ListPage       := TStringList.Create;

    PdfPersonnageCompetenceTri(ListPage);

    if FileExists(PdfChemin) then
      if not DeleteFile(PdfChemin) then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_038'));
        exit;
      end;
    PDFDoc           := TPDFDocument.Create(nil);
    PDFOption        := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText ];
    PDFDoc.Options   := PDFOption;
    PDFDoc.StartDocument;
    PdfSection       := PDFDoc.Sections.AddSection;

    PdfPage          := PDFDoc.Pages.AddPage;
    PdfPolicesDeRepli;
    PdfFontBold      := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
    PdfFontValue     := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique.ttf'), ConstPoliceCarlson);
    PdfFontItalique  := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Italic.ttf'), ConstPoliceCarlson+ConstPoliceItalique);

    PdfSection.AddPage(PdfPage);
    PdfPage.PaperType:= ptA4;
    PdfPage.UnitOfMeasure := uomMillimeters;

    DessineFondEntete;
    SectionAttributs;
    SectionCompetences;
    SectionTalents;
    SectionCarrieres;
    InfosBas;
    ImagesRace;

    PDFDoc.SaveToFile(PdfChemin);
    PDFDoc.Free;

    if not PdfSansOuverture then
      OpenDocument(PdfChemin);

  end;

end.


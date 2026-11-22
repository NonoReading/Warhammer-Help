unit WinSpecialisation;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, GlobalFonts,
  WinObjetPropre, XmlExportImport,
  ChargeTalent, ChargeCompetence, UnitCalcul, ChargeConstantes, ChargeTexte,
  ChargeArme, ChargeArmure, ChargeArmureSimplifie, ChargeMetierCompetence, ChargeRace,
  ChargeMetier, ChargeTrapping, BCButton, BCLabelContour;

type

  { TWinSpecialisation }

  { TWinSpecialisations }

  TWinSpecialisations = class(TForm)
    ButtonAjouter: TBCButtonContour;   // +Specialisation propre au personnage (catalogue ouvert seulement)
    TabSpecialisation: TStringGrid;
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure TabSpecialisationDblClick({%H-}Sender: TObject);
    procedure ButtonAjouterClick({%H-}Sender: TObject);
    function  AjoutPermis: Boolean;
    function  FamilleLibreTalent: String;
    Procedure ChargeSpecialisation(CodeGenerique: String);
    Procedure AjouteLigne(Gen: String; Code: String; Lib :string; Typ :String; SansTest :Boolean);

  private

  public

  end;

var
  WinSpecialisations: TWinSpecialisations;
  FiltreLivre:        String;
  // +Specialisation propre : a la creation (WinCreation) et a l'evolution (WinPersonnage).
  // ObjetsPropresChoix = le fragment <CUSTOM_ITEMS> du personnage en cours de creation, que WinCreation
  // recopie dans sa fiche avant l'enregistrement. A l'evolution, WinPersonnage pose ObjetsPropresCible
  // sur Personnage.ObjetsPropres le temps de l'ouverture (nil le reste du temps) : le fragment est alors
  // lu et ecrit directement dans la fiche.
  AjoutSpecialisationLibre: Boolean = False;
  ObjetsPropresChoix:       String  = '';
  ObjetsPropresCible:       PString = nil;

implementation

{$R *.lfm}

{ TWinSpecialisation }

Procedure TWinSpecialisations.AjouteLigne(Gen: String; Code: String; Lib :string; Typ :String; SansTest :Boolean);
// ajouter une ligne dans la table
  var
    MemeRadical: Boolean;
  Begin
    // Comparer les radicaux SANS le prefixe de livre : Code et Gen peuvent venir de deux
    // livres differents (ex. RULES-COMPPROJ_* generique, LUSTR-COMPPROJ_SARBAC specialisation),
    // le prefixe seul suffit sinon a faire echouer le rapprochement.
    // Talents et competences V4 / V5 : la famille est ce qui precede le '__' (le radical avant le
    // premier '_' vaut 'T' ou 'COMP' pour tous) ; autres types : ancien radical.
    if (Pos(SeparateurSpecialisationTalent, Code) > 0) or (Pos(SeparateurSpecialisationTalent, Gen) > 0) then
      MemeRadical := FamilleCompetence(CodeSansLivre(Code)) = FamilleCompetence(CodeSansLivre(Gen))
    else
      MemeRadical := ExtractStringBefore(CodeSansLivre(Code),'_') = ExtractStringBefore(CodeSansLivre(Gen),'_');
    if (SansTest = true) or
       (MemeRadical
           and (Pos(SeparateurMulti, Code) = 0)
           and (Pos(ValeurGenerique, Code) = 0)) then
      begin
        TabSpecialisation.rowcount := TabSpecialisation.rowcount + 1;
        TabSpecialisation.Cells[1, TabSpecialisation.rowcount-1] := Code;
        TabSpecialisation.Cells[2, TabSpecialisation.rowcount-1] := Lib;
        TabSpecialisation.Cells[3, TabSpecialisation.rowcount-1] := Typ;
      end;

  end;

Procedure TWinSpecialisations.ChargeSpecialisation(CodeGenerique: String);
// ajout les données dans la table
  var
    PTalent:           StructureTalent;
    PCompetence:       StructureCompetence;
    PArme:             StructureArme;
    PArmure:           StructureArmure;
    PArmureSimplifiee: StructureArmureSimplifiee;
    PTrapping:         StructureTrapping;
    Res:               String;
    NbL:               Integer;
    MaxL:              Integer;
    ListOpt:           TStringList;
  begin
    case ChoixWinTypeFichier of
      ConstXmlSousChapitreTalent:    // Talents
        // Grail Virtue (NATIO-T0002) : pool deja filtre par l'appelant (TabAugmentationTalentDblClick,
        // winpersonnage.pas) aux noms possedes en Knightly Virtue - teste EN PREMIER, meme
        // raison que le trait d'ethnie juste en dessous : un seul candidat ne contient pas
        // de '/' et tomberait sinon dans le catalogue complet. CONTEXT.md 2.78.
        if ChoixWinVertuGrail <> '' then
          begin
            MaxL := CountOccurrences(ChoixWinVertuGrail, ',') + 1;
            for NbL := 1 to MaxL do
              begin
                Res := Trim(ExtractChaine(',', ChoixWinVertuGrail, NbL));
                if Res <> '' then
                  AjouteLigne(CodeGenerique, Res, ChercheTalent(Res).Libelle, '', true);
              end;
          end
        // Trait d'ethnie : ses options sont proposees comme le seraient les branches
        // d'un choix A/B. Teste AVANT le Pos(SeparateurMulti), parce qu'un code de trait
        // ne contient pas de '/' et tomberait sinon dans le catalogue complet des
        // talents. Le libelle vient de la table des options. CONTEXT.md 2.41.
        else if ChercheTrait(CodeGenerique).CodeTrait <> '' then
          begin
            ListOpt := OptionsDuTrait(CodeGenerique);
            for NbL := 0 to ListOpt.Count - 1 do
              AjouteLigne(CodeGenerique, ListOpt[NbL],
                          ChercheTraitOption(ListOpt[NbL]).Libelle, '', true);
            ListOpt.Free;
          end
        else if Pos(SeparateurMulti, CodeGenerique) > 0 then
          begin
            ListOpt := ListeTalent(CodeGenerique);
            for NbL := 0 to ListOpt.Count - 1 do
              begin
                PTalent := ChercheTalent(ListOpt[NbL]);
                if VerifieFiltre(PTalent.Livre, FiltreLivre) then
                  AjouteLigne(CodeGenerique, ListOpt[NbL], PTalent.Libelle, '', true);
              end;
            ListOpt.Free;
          end
        else
          begin
            for PTalent in ListTalent do
              // les traits de creature sont exclus : ils s'acquierent a la naissance par la race,
              // jamais par un choix du joueur (CONTEXT.md 2.15). C'est le SEUL endroit du
              // programme qui propose le catalogue complet - partout ailleurs les talents
              // viennent d'une table explicite (ListMetierTalent, ListRaceTalent,
              // ListTalentCreation), donc rien d'autre a filtrer.
              if VerifieFiltre(PTalent.Livre, FiltreLivre) and (not PTalent.Trait) then
                AjouteLigne(CodeGenerique, PTalent.CodeTalent, PTalent.Libelle, '', false);
            // specialisations propres au personnage en cours (hors des listes des livres)
            for PTalent in ListTalentPerso do
              if VerifieFiltre(PTalent.Livre, FiltreLivre) then
                AjouteLigne(CodeGenerique, PTalent.CodeTalent, PTalent.Libelle, '', false);
          end;

      ConstXmlSousChapitreCompetence:      // Compétences
        if Pos(SeparateurMulti, CodeGenerique) > 0 then
          begin
            ListOpt := ListeMetierCompetence(CodeGenerique);
            for NbL := 0 to ListOpt.Count - 1 do
              begin
                PCompetence := ChercheCompetence(ListOpt[NbL]);
                if VerifieFiltre(PCompetence.Livre, FiltreLivre) then
                  AjouteLigne(CodeGenerique, ListOpt[NbL], PCompetence.Libelle, '', true);
              end;
            ListOpt.Free;
          end
        else
          begin
            for PCompetence in ListCompetence do
              if VerifieFiltre(PCompetence.Livre, FiltreLivre) then
                AjouteLigne(CodeGenerique, PCompetence.CodeCompetence, PCompetence.Libelle, '', false);
            // specialisations propres au personnage en cours (hors des listes des livres)
            for PCompetence in ListCompetencePerso do
              if VerifieFiltre(PCompetence.Livre, FiltreLivre) then
                AjouteLigne(CodeGenerique, PCompetence.CodeCompetence, PCompetence.Libelle, '', false);
          end;

      ConstXmlSousChapitreArme:     // Armess
        for PArme in ListArme do
          if VerifieFiltre(PArme.Livre, FiltreLivre) then
            AjouteLigne(CodeGenerique, PArme.CodeArme, PArme.Libelle, '', false);

      ConstXmlSousChapitreArmure:   // Armures
        for PArmure in ListArmure do
          if VerifieFiltre(PArmure.Livre, FiltreLivre) then
            AjouteLigne(CodeGenerique, PArmure.CodeArmure, PArmure.Libelle, '', false);

      ConstXmlSousChapitreArmureSimp: // Set d'armure
        for PArmureSimplifiee in ListArmureSimplifiee do
          if VerifieFiltre(PArmureSimplifiee.Livre, FiltreLivre) then
            AjouteLigne(CodeGenerique, PArmureSimplifiee.CodeArmure, PArmureSimplifiee.Libelle, '', false);

      ConstXmlChapitreEquipement:   // Equipements
        begin
          MaxL                    := CountOccurrences(CodeGenerique, ',') + 1;
          For NbL := 1 to MaxL do
            begin
              Res                 := ExtractChaine(',',CodeGenerique, NbL);
              // Le code porte son prefixe de livre (RULES-COMB_BASE_01) : tester les cinq
              // premiers caracteres de Res donnait "RULES", jamais COMB_/PROJ_/MUNI_/ARMO_,
              // donc TOUT tombait dans le else et s'affichait avec son code brut en libelle
              // et "Various" en type. Meme moule que GetTypeMetierEquipement
              // (unitcalcul.pas l.218) : on decoupe d'abord, on teste CodeValeur ensuite.
              DecoupeCodeValeur(Res);
              case copy(CodeValeur,1,5) of
                EquipementCC,EquipementCT,EquipementMU:
                  begin
                    PArme         := chercheArme(res);
                    if VerifieFiltre(PArme.Livre, FiltreLivre) then
                      AjouteLigne(CodeGenerique, PArme.CodeArme, PArme.Libelle, TypeEquipWe, false);
                  end;
                EquipementAR:
                  begin
                    PArmure       := chercheArmure(res);
                    if VerifieFiltre(PArmure.Livre, FiltreLivre) then
                      AjouteLigne(CodeGenerique, PArmure.CodeArmure, PArmure.Libelle, TypeEquipAr, false);
                  end;
                else
                  begin
                    // objet Divers : libelle de sa fiche Trapping s'il en a une, sinon le code (comme avant)
                    PTrapping := ChercheTrapping(Res);
                    if PTrapping.CodeTrapping <> '' then
                      AjouteLigne(CodeGenerique, Res, PTrapping.Libelle, TypeEquipDi, true)
                    else
                      AjouteLigne(CodeGenerique, Res, Res, TypeEquipDi, true);
                  end;
              end;
            end;
        end;

      ConstXmlDataCareerBonus:      // Appartenances (regiment, ordre de chevalerie, culte)
        // CodeGenerique est ICI une liste de codes deja filtree par
        // AppartenancesCandidates (metier + ethnie + non deja acquises) - meme forme que
        // la liste d'equipement juste au-dessus. Rien n'est donc filtre a nouveau, et pas
        // davantage sur le livre : une appartenance n'existe que si son livre est charge.
        // La premiere ligne, de code VIDE, est le "aucune" : le programme ne peut pas
        // deviner qu'un soldat est un mercenaire sans regiment, il faut pouvoir le dire.
        // CONTEXT.md 2.44.
        begin
          AjouteLigne(CodeGenerique, '', GetTexteLibelle(ConstLabSansAppartenance), '', true);
          MaxL := CountOccurrences(CodeGenerique, ',') + 1;
          For NbL := 1 to MaxL do
            begin
              Res := Trim(ExtractChaine(',', CodeGenerique, NbL));
              if Res <> '' then
                AjouteLigne(CodeGenerique, Res, ChercheCareerBonus(Res).Libelle, '', true);
            end;
        end;
    end;
    AdjustGridColumnsWidth(TabSpecialisation,self.Height, true, true);
  end;

procedure TWinSpecialisations.FormCreate(Sender: TObject);
// initialisation
  begin
    // bouton +Specialisation : TBCButtonContour du .lfm (meme style que les boutons de WinPersonnage),
    // invisible tant que la liste n'est pas chargee
    ButtonAjouter.Caption := '+' + GetTexteLibelle('RULES-LAB_689');
    MiseEnFormeDesChamp(self);
    // ligne entiere selectionnee, meme couleur que les autres fenetres de choix
    SelectionGrilleWarhammer(TabSpecialisation);
          // on met toutes les données dans la table pour les afficher directement dans les champs
    TabSpecialisation.RowCount      := 1;
    TabSpecialisation.ColCount      := 4;
    TabSpecialisation.ColWidths[0]  := 20;
    TabSpecialisation.Cells[1,0]    := GetTexteLibelle('RULES-LAB_002');
    // le code reste en colonne 1 (lu a la validation) mais n'est pas montre : seul le libelle compte
    TabSpecialisation.ColWidths[1]  := 0;
    TabSpecialisation.Cells[2,0]    := GetTexteLibelle(ConstLabSelSpe);
    TabSpecialisation.ColWidths[2]  := 250;
    TabSpecialisation.Cells[3,0]    := '';
    TabSpecialisation.ColWidths[3]  := 0;

    FiltreLivre := SelectWinLivre;
    // les specialisations propres du personnage vivent dans le livre virtuel des objets propres
    if FiltreLivre <> '' then
      FiltreLivre := FiltreLivre + AjouteAccolade(ConstLivreObjetsPropres);

    case ChoixWinTypeFichier of
      ConstXmlSousChapitreTalent:       ChargeSpecialisation(ChoixWinTalent);
      ConstXmlSousChapitreCompetence:   ChargeSpecialisation(ChoixWinCompetence);
      ConstXmlSousChapitreArme:         ChargeSpecialisation(ChoixWinArme);
      ConstXmlSousChapitreArmure:       ChargeSpecialisation(ChoixWinArmure);
      ConstXmlSousChapitreArmureSimp:   ChargeSpecialisation(ChoixWinArmureSimp);
      ConstXmlChapitreEquipement:       ChargeSpecialisation(ChoixWinEquipement);
      ConstXmlDataCareerBonus:          ChargeSpecialisation(ChoixWinCareerBonus);
    end;
    ButtonAjouter.Visible := AjoutPermis();
    // mise en page par code (les ancrages du .lfm laissaient la liste recouvrir le bouton) :
    // bouton en bas, liste juste au-dessus ; sans bouton, la liste prend toute la hauteur
    if ButtonAjouter.Visible then
      begin
        ButtonAjouter.Top := ClientHeight - ButtonAjouter.Height - 11;
        TabSpecialisation.Height := ButtonAjouter.Top - 8 - TabSpecialisation.Top;
        ButtonAjouter.BringToFront;
      end
    else
      TabSpecialisation.Height := ClientHeight - 11 - TabSpecialisation.Top;
  end;

function TWinSpecialisations.FamilleLibreTalent: String;
// Generique ouvert (<FreeSpecialisation>) auquel se rattache le talent a choisir, '' sinon.
// ChoixWinTalent est le generique lui-meme, ou une liste « A/B » de specialisations de la MEME famille
// (carriere : « Etiquette (Nobles) ou Etiquette (Cultists) ») : la fenetre montre alors toute la famille,
// on peut donc y ajouter la sienne. Une liste de familles differentes reste fermee.
  var
    I, N: Integer;
    Part, Fam: String;
  begin
    Result := '';
    if ChoixWinTalent = '' then exit;
    N := CountOccurrences(ChoixWinTalent, SeparateurMulti) + 1;
    for I := 1 to N do
      begin
        Part := Trim(ExtractChaine(SeparateurMulti, ChoixWinTalent, I));
        if Pos(ValeurGenerique, Part) > 0 then Fam := Part else Fam := CodeFamilleTalent(Part);
        if Fam = '' then begin Result := ''; exit; end;
        if (I > 1) and (Fam <> Result) then begin Result := ''; exit; end;
        Result := Fam;
      end;
    if not ChercheTalent(Result).SpecLibre then Result := '';
  end;

function TWinSpecialisations.AjoutPermis: Boolean;
// +Specialisation seulement sur un catalogue OUVERT (talent ou competence a specialiser) : une liste
// fermee par le livre (choix A/B, options de trait, Grail Virtue, equipement, appartenance) ne s'ouvre pas
  begin
    if not (AjoutSpecialisationLibre or (ObjetsPropresCible <> nil)) then
      begin
        Result := False;
        exit;
      end;
    case ChoixWinTypeFichier of
      ConstXmlSousChapitreTalent:
        Result := (ChoixWinVertuGrail = '') and (ChercheTrait(ChoixWinTalent).CodeTrait = '')
                  // seuls les generiques marques <FreeSpecialisation> du livre l'acceptent (Craftsman, Etiquette...) ;
                  // Invoke (dieux), Arcane Magic (domaines), competences de combat liees aux armes : refuses
                  and (FamilleLibreTalent <> '');
      ConstXmlSousChapitreCompetence:
        Result := (ChoixWinCompetence <> '') and (Pos(SeparateurMulti, ChoixWinCompetence) = 0)
                  and ChercheCompetence(ChoixWinCompetence).SpecLibre;
    else
      Result := False;
    end;
  end;

procedure TWinSpecialisations.ButtonAjouterClick(Sender: TObject);
// cree une specialisation propre au personnage sous le generique, la range dans la fiche (<CUSTOM_ITEMS>)
// et la prend tout de suite ; un nom deja dans la liste (casse ignoree) est pris tel quel, sans doublon
  var
    Nom:       String = '';
    CodeParent: String;
    Xml:       String;
    Code:      String;
    EstTalent: Boolean;
    I, P:      Integer;
    Base:      String;
  begin
    EstTalent := (ChoixWinTypeFichier = ConstXmlSousChapitreTalent);
    if EstTalent then CodeParent := FamilleLibreTalent else CodeParent := ChoixWinCompetence;
    if not InputQuery(GetTexteLibelle('RULES-LAB_689'), GetTexteLibelle('RULES-LAB_690'), Nom) then exit;
    Nom := Trim(Nom);
    if Nom = '' then exit;
    // le joueur ne donne que le texte qui remplace « (Any) » : « Etiquette » + « test » = « Etiquette (test) »
    if EstTalent then Base := ChercheTalent(CodeParent).Libelle else Base := ChercheCompetence(CodeParent).Libelle;
    P := Pos(' (', Base);
    while (P > 0) and (Pos(' (', Copy(Base, P + 1, MaxInt)) > 0) do
      P := P + Pos(' (', Copy(Base, P + 1, MaxInt));
    if P > 0 then Base := Trim(Copy(Base, 1, P - 1));
    if (Base <> '') and not SameText(Copy(Nom, 1, Length(Base) + 2), Base + ' (') then
      Nom := Base + ' (' + Nom + ')';
    for I := 1 to TabSpecialisation.RowCount - 1 do
      if SameText(Trim(TabSpecialisation.Cells[2, I]), Nom) then
        begin
          TabSpecialisation.Row := I;
          TabSpecialisationDblClick(nil);
          exit;
        end;
    if ObjetsPropresCible <> nil then Xml := ObjetsPropresCible^ else Xml := ObjetsPropresChoix;
    Code := AjouteSpecialisationPropre(Xml, EstTalent, CodeParent, Nom);
    if Code = '' then exit;
    if ObjetsPropresCible <> nil then ObjetsPropresCible^ := Xml else ObjetsPropresChoix := Xml;
    InjecteObjetsPropres(Xml);
    TabSpecialisation.RowCount := 1;
    ChargeSpecialisation(CodeParent);
    for I := 1 to TabSpecialisation.RowCount - 1 do
      if TabSpecialisation.Cells[1, I] = Code then
        begin
          TabSpecialisation.Row := I;
          TabSpecialisationDblClick(nil);
          exit;
        end;
  end;

procedure TWinSpecialisations.FormPaint(Sender: TObject);
begin
  Canvas.Pen.Color   := ClWhite;
  Canvas.Pen.Width   := 3;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(2, 2, ClientWidth - 2, ClientHeight - 2);
end;

procedure TWinSpecialisations.TabSpecialisationDblClick(Sender: TObject);
// renvoyer le code sélectionné et fermer la fenête
  var
    Val: String;
    Lib: String;
    Typ: String;
  begin
    if TabSpecialisation.Row > 0 then
      begin
        Val := TabSpecialisation.Cells[1, TabSpecialisation.Row];
        Lib := TabSpecialisation.Cells[2, TabSpecialisation.Row];
        Typ := TabSpecialisation.Cells[3, TabSpecialisation.Row];
        case ChoixWinTypeFichier of
          ConstXmlSousChapitreTalent:     SelectWinTalent     := Val;
          ConstXmlSousChapitreCompetence: SelectWinCompetence := Val;
          ConstXmlSousChapitreArme:       SelectWinArme       := Val;
          ConstXmlSousChapitreArmure:     SelectWinArmure     := Val;
          ConstXmlSousChapitreArmureSimp: SelectWinArmureSimp := Val;
          ConstXmlChapitreEquipement:     SelectWinEquipement := Val;
          // Val vide = la ligne "aucune appartenance", et c'est une reponse valable :
          // l'appelant ne greffe rien. CONTEXT.md 2.44.
          ConstXmlDataCareerBonus:        SelectWinCareerBonus := Val;
        end;
        SelWinLibelle  := Lib;
        SelWinType     := Typ;
        close;
      end;
  end;

end.


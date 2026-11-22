unit WarhammerSource;

{$mode objfpc}{$H+}
{$ModeSwitch ArrayOperators}

interface

uses
  Classes, SysUtils, Forms, Graphics, ExtCtrls, StdCtrls, Grids, Dialogs, MessageTest,
  Controls, Buttons, IndicateurChargement, BGRABitmap, BGRABitmapTypes, TraductionTexte, DOM, XMLRead, WinCompetence,
  ChargeCompetence, ChargeConstantes, ChargeAttribut, ChargeTalent, WinTalent,
  ChargeMetier, ChargeMetierNiveau, ChargeMetierAttribut, ChargeCoutXp,
  ChargeMetierCompetence, ChargeMetierTalent, WinMetier, ChargeRaceMetier,
  ChargeRace, ChargeEspece, ChargeNation, ChargeRegle, WinRaces, ChargeRaceAttribut, ChargeRacePhysique, ChargeSigneAstral, ChargeRaceCompetence,
  ChargeRaceTalent, GlobalFonts, WinCreation, ChargeTalentCreation,
  WinPersonnage, ChargeAttributAugmentation, ChargeCompetenceAugmentation,
  ChargeArme, WinWeapon, WinEquipement, ChargeArmeBonus, ChargeMetierEquipement, ChargeArmure,
  ChargeArmureBonus, ChargeArmureBonusTalent, ChargeArmeBonusTalent, WinArmor, ChargeTrapping, ChargeSort, WinSpell, ChargeTexte,
  ChargeFabrication, WinMutationCatalogue, ChargeDisease, WinDiseaseCatalogue, ChargeAffliction, WinAfflictionCatalogue, ChargeClassEquipement, Unitcalcul, ChargeMetierSousMetier, ChargeTirageMetier,
  ChargeMetierRaceChoixMetier, ChargePersonnage, ChargeCreationTow, ChargeRaceCreation,
  ChargeTraduction, ChargeArmureSimplifie, ChargeOptionRegle, WinOptionRegle, ChargeLivre,
  ChargeTalentEffet, ChargeTalentCompetenceModif,
  ChargeRaceCorruptionCreation,
  ChargeCorruptionTable, ChargeRaceOpinion,
  ChargeCorruptionCompetenceModif,
  ChargeCorruptionTalent, ChargeCorruptionEquipement,
  ChargeModificateur, ChargeTalentModificateur, ChargeCareerBonusModificateur,
  ChargeArmeModificateur, ChargeArmureBonusModificateur, ChargeCorruptionModificateur,
  ChargeAfflictionCompetenceModif,
  CustomDrawn_Common, BCButton, BCLabel, fpTTF,
  PdfPersonnage, PdfPersonnageV5, PdfPersonnageTow, PdfUtils, PdfMetier, PdfRace, XmlExportImport, fppdf, WinLivre, ScriptEcran, Process, BCLabelContour;

type

  { TMenu }

  TMenu = class(TForm)
    BoutonCompetence: TImage;
    BoutonMetier: TImage;
    BoutonRace: TImage;
    BoutonTalent: TImage;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ButtonCompetence: TBCButton;
    ButtonCreation: TBCButton;
    ButtonOuvrirLivre: TBCButton;
    ButtonDisclaimerLivre: TBCButton;
    ButtonExportLivre: TBCButton;
    ButtonCreationLivre: TBCButton;
    ButtonPdf: TBCButton;
    ButtonMetier: TBCButton;
    ButtonModification: TBCButton;
    ButtonRace: TBCButton;
    TabBibliotheque: TStringGrid;   // creee dans FormCreate (Arme, Armure, Equipement, Sort...)
    ButtonTalent: TBCButton;
    ComboBoxLangue: TComboBox;
    ComboBoxVersion: TComboBox;
    ComboBoxLangueInterface: TComboBox;
    ImageFond: TImage;
    Label1: TBCLabelContour;
    Label2: TBCLabelContour;
    Label3: TBCLabelContour;
    Label4: TBCLabelContour;
    Label5: TBCLabelContour;
    Panel2: TPanel;
    Panel3: TPanel;
    TabLivre: TStringGrid;
    TotLivreCompetence: TEdit;
    TotLivreTalent: TEdit;
    TotLivreRace: TEdit;
    Logo1: TImage;
    Logo2: TImage;
    TotLivreMetier: TEdit;
    Panel1: TPanel;
    TabPersonnage: TStringGrid;
    ButtonOptionRegle: TBCButton;
    ButtonMAJLivres: TBCButton;
    ButtonTestsAuto: TBCButton;
    procedure BoutonCompetenceClick({%H-}Sender: TObject);
    procedure BoutonTalentClick({%H-}Sender: TObject);
    procedure ButtonArmureClick({%H-}Sender: TObject);
    procedure ButtonArmeClick({%H-}Sender: TObject);
    procedure ButtonEquipementClick({%H-}Sender: TObject);
    procedure ButtonCreationClick({%H-}Sender: TObject);
    procedure ButtonCreationLivreClick(Sender: TObject);
    procedure ButtonModificationClick({%H-}Sender: TObject);
    procedure ButtonOuvrirLivreClick({%H-}Sender: TObject);
    procedure ButtonDisclaimerLivreClick({%H-}Sender: TObject);
    procedure ButtonPdfClick({%H-}Sender: TObject);
    procedure ButtonRaceClick({%H-}Sender: TObject);
    procedure ButtonSortClick({%H-}Sender: TObject);
    procedure ButtonTalentClick({%H-}Sender: TObject);
    procedure ButtonCompetenceClick({%H-}Sender: TObject);
    procedure ButtonMetierClick({%H-}Sender: TObject);
    procedure BoutonMetierClick({%H-}Sender: TObject);
    procedure BoutonRaceClick({%H-}Sender: TObject);
    procedure ButtonXmlClick({%H-}Sender: TObject);
    procedure ChargerImage();
    procedure ComboBoxLangueSelect({%H-}Sender: TObject);
    procedure ComboBoxVersionSelect({%H-}Sender: TObject);
    procedure ComboBoxLangueInterfaceSelect({%H-}Sender: TObject);
    procedure FormActivate({%H-}Sender: TObject);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormResize({%H-}Sender: TObject);
    procedure ChargerPersonnages();
    Procedure ChargeIni();
    procedure ChargerLivre(ForceMaJ: Boolean; ForceLivre: String);
    procedure TabLivreDblClick({%H-}Sender: TObject);
    procedure TabBibliothequeDblClick({%H-}Sender: TObject);
    procedure RemplirTabBibliotheque();
    procedure MasqueElementsV1();
    procedure TabLivreMouseMove({%H-}Sender: TObject; {%H-}Shift: TShiftState; X, Y: Integer);
    procedure SauveIni();
    function XmlPersonnageFichierActuel(const Directory: string): string;
    procedure LotPdfPersonnages();
    procedure LotPdfMetiersRaces();
    procedure LotNaissance();
    procedure LotFamilier();
    procedure LotCreer();
    procedure LotTestCreation();
    procedure TesterCasCreation(const FichierCas: String; Sortie: TStringList; var NbCas, NbEchec: Integer);
    procedure ButtonTestsAutoClick(Sender: TObject);
    procedure PoserBoutonTestsAuto();
    procedure LotDumpPersonnages();
    procedure LotDumpEcran();
    procedure LotDumpPdf();
    procedure LotReecritPersonnages();
    procedure LotRetraitLivre();
    procedure LancerWinLivre(const Chemin: String);
    procedure OuvrirWinLivreSeul(const Chemin: String);
    procedure WinLivreFerme(Sender: TObject; var CloseAction: TCloseAction);
    procedure RafraichirLibellesMenu();
    procedure ChargerListeVersions();
    procedure ChargerListeLanguesInterface();
    procedure PeuplerTabLivre();
    procedure LibelleLivreLigne(Ind: Integer);
    procedure MajTauxTraduction();
    procedure AjustePositionFenetre();
    procedure ButtonOptionRegleClick(Sender: TObject);
    procedure ButtonMAJLivresClick(Sender: TObject);
    procedure RafraichirBoutonMAJLivres();
    function  LivresCochesActuellement(): String;
  private
    FenetreInitialisee:       Boolean;
    LargeurFenetreBase:       Integer;
    LargeurTabLivreBase:      Integer;
    LargeurTabPersonnageBase: Integer;
    // Livres réellement chargés en mémoire lors du dernier ChargerLivre (par opposition
    // à LivresCharges, recalculée à chaque coche/décoche - voir RafraichirBoutonMAJLivres).
    LivresChargesSnapshot:    String;
  public
  end;


var
  Menu:               TMenu;
  FenCompetence:      TWinCompetence;
  FenTalent:          TWintTalent;
  FenMetier:          TWinMetiers;
  FenRace:            TWinRace;
  FenCreation:        TWinCreations;
  FenPersonnage:      TWinPersonnages;
  FenArme:            TWinWeapons;
  FenArmure:          TWinArmors;
  FenSort:            TWinSpells;
  FenLivre:           TWinLivres;
  ColLivreSel:        Integer = 1;
  ColLivreLib:        Integer = 2;
  ColLivreCod:        Integer = 3;
  ColLivreOrd:        Integer = 4;
  ColLivreRac:        Integer = 5;
  ColLivreWor:        Integer = 6;
  ColLivreO_F:        Integer = 7;
  ColLivreAbr:        Integer = 8;
  ColLivreCom:        Integer = 9;
  ColLivreTal:        Integer = 10;
  ColLivreArm:        Integer = 11;
  ColLivreArU:        Integer = 12;
  ColLivreEqu:        Integer = 13;
  ColLivreSor:        Integer = 14;
  ColLivreTra:        Integer = 15;
  ColLivreTrd:        Integer = 16;
  ColLivreChe:        Integer = 17;
  ColPersoNom:        Integer = 1;
  ColPersoWor:        Integer = 2;
  ColPersoRac:        Integer = 3;
  ColPersoNiv:        Integer = 4;
  ColPersoTXp:        Integer = 5;
  ColPersoCXp:        Integer = 6;
  ColPersoLOb:        Integer = 7;
  ColPersoLNe:        Integer = 8;


implementation

{$R *.lfm}

function CodePersoStable(const S: String): String;
  // --dump : les codes PERSO-xxx__<hexa> (specialisations propres, suffixe unique a chaque creation) perdent leur
  // suffixe (remplace par #), pour que la fiche de reference des tests d'ecran reste comparable
  var
    P, Q: Integer;
  begin
    Result := '';
    P := 1;
    while P <= Length(S) do
      begin
        if Copy(S, P, 6) = 'PERSO-' then
          begin
            Q := P;
            while (Q <= Length(S)) and not (S[Q] in ['"', ' ', '<', '>', #13, #10]) do
              begin
                if (Copy(S, Q, 2) = '__') and (Q > P) then
                  begin
                    Result := Result + Copy(S, P, Q + 2 - P) + '#';
                    Q := Q + 2;
                    while (Q <= Length(S)) and (S[Q] in ['0'..'9', 'A'..'F']) do Inc(Q);
                    P := Q;
                    Break;
                  end;
                Inc(Q);
              end;
            if P < Q then
              begin
                Result := Result + Copy(S, P, Q - P);
                P := Q;
              end;
          end
        else
          begin
            Result := Result + S[P];
            Inc(P);
          end;
      end;
  end;

function LibelleVersion(const Code: String): String;
  // Code d'édition (WFRP4) -> libellé de la liste déroulante avec l'année de sortie du
  // jeu (Nono, 31/10/2026). La 3e édition n'est pas gérée par le projet.
  begin
    if Code = 'WFRP1' then Result := Code + ' (1986)'
    else if Code = 'WFRP2' then Result := Code + ' (2005)'
    else if Code = 'WFRP4' then Result := Code + ' (2018)'
    else if Code = 'WFRP5' then Result := Code + ' (2026)'
    else if Code = 'WFRPTOW' then Result := Code + ' (2025)'
    else Result := Code;
  end;

procedure ReimporterAttributs();
  // Attributs et coûts d'augmentation sont des données "primaires", lues une seule fois au
  // démarrage pour l'édition active : ChargerLivre ne les relit pas. Au changement de
  // version (V2 -> V1 : titres I / Dex / Ld / Cl vides) on les remplace par ceux du
  // dossier de la nouvelle édition (Nono, 31/10/2026).
  var
    Recherche: TSearchRec;
    Fichiers:  TStringList;
    Ind:       Integer;
  begin
    ListeAttribut.Clear;
    ListeAttributAugmentation.Clear;
    ListeCompetenceAugmentation.Clear;
    NbAttribut               := 0;
    NbAttributAugmentation   := 0;
    NbCompetenceAugmentation := 0;
    Fichiers := TStringList.Create;
    try
      if FindFirst(GetCurrentDir + ConstCheminLivre + '*.xml', faAnyFile, Recherche) = 0 then
        begin
          repeat
            Fichiers.Add(ExtractStringBefore(Recherche.Name, '.'));
          until FindNext(Recherche) <> 0;
          FindClose(Recherche);
        end;
      ImportAttributsSeuls := true;
      try
        for Ind := 0 to Fichiers.Count - 1 do
          XmlImport(Fichiers[Ind], true);
      finally
        ImportAttributsSeuls := false;
      end;
    finally
      Fichiers.Free;
    end;
  end;

function CodeVersion(const Libelle: String): String;
  // Inverse de LibelleVersion : le code est le premier mot du libellé.
  var
    P: Integer;
  begin
    P := Pos(' ', Libelle);
    if P > 0 then Result := Copy(Libelle, 1, P - 1)
    else Result := Libelle;
  end;

{ TMenu }


procedure TMenu.ChargerImage();
  var
    Bmp: TBGRABitmap;

  // Image du menu : \PICTURES\<Version>\MENU\<meme nom de fichier> d'abord (logo et bandeaux
  // propres a l'edition, repli PICTURES_DEFAULT de CheminImage), sinon celle de \PICTURES\BACK\.
  function CheminMenu(const CheminBack: String): String;
    begin
      Result := GetCurrentDir + '\PICTURES\' + ValVersion + '\MENU\' + ExtractFileName(CheminBack);
      Result := CheminImage(Result);
      if not FileExists(Result) then
        Result := CheminImage(GetCurrentDir + CheminBack);
    end;

  procedure ChargerBandeau(Image: TImage; const CheminBack: String);
    var
      Chemin: String;
    begin
      Chemin := CheminMenu(CheminBack);
      if FileExists(Chemin) then
        Image.Picture.LoadFromFile(Chemin);
    end;

  begin
    // récupérer les images de fond
    ChargerBandeau(Logo1, ConstCheminLogo1);
    ChargerBandeau(Logo2, ConstCheminLogo2);
    ChargerBandeau(BoutonRace, ConstCheminBoutonRace);
    ChargerBandeau(BoutonMetier, ConstCheminBoutonMetier);
    ChargerBandeau(BoutonCompetence, ConstCheminBoutonCompetence);
    ChargerBandeau(BoutonTalent, ConstCheminBoutonTalent);
    // Fond : une seule fois (ChargerImage est rappelee au changement de version ; le
    // reappliquer cumulerait la transparence et le grainerait).
    if ImageFond.Picture.Bitmap.Empty and FileExists(CheminImage(GetCurrentDir+ConstCheminBack)) then
       begin
         Bmp :=TBGRABitmap.Create(CheminImage(GetCurrentDir+ConstCheminBack));
         Bmp.ApplyGlobalOpacity(100);
         ImageFond.Picture.Bitmap.Assign(Bmp);
         Bmp.Free;
         ImageFond.Transparent := True;
         ImageFond.SendToBack;
       end;
  end;

procedure TMenu.SauveIni();
var
  FilePathLoc: String;
  MyFile:   TextFile;
  Ind:      Integer;
  Liste:    String = '';
begin
  FilePathLoc := GetCurrentDir + ConstFichierIni;
  if FileExists(FilePathLoc) then
    DeleteFile(FilePathLoc);
  // Ouverture du fichier en écriture
  AssignFile(MyFile, FilePathLoc);
  Rewrite(MyFile);

  // Écriture dans le fichier
  Writeln(MyFile, ConstIniLangue + comboboxlangue.items[ComboBoxLangue.Itemindex]);
  if ComboBoxVersion.Itemindex <> -1 then
    Writeln(MyFile, ConstIniVersion + CodeVersion(ComboBoxVersion.items[ComboBoxVersion.Itemindex]));
  if ComboBoxLangueInterface.Itemindex <> -1 then
    Writeln(MyFile, ConstIniLangueInterface + ComboBoxLangueInterface.items[ComboBoxLangueInterface.Itemindex]);
  Writeln(MyFile, ConstIniUniteTaille + UniteTaille);
  if ImagesDefautSeul then
    Writeln(MyFile, ConstIniImagesDefautSeul + '1');

  // Sélection de livres cochés, une ligne par édition (CONTEXT.md §2.70) : la table garde
  // en mémoire la sélection de TOUTES les éditions déjà rencontrées - on ne met à jour ici
  // que celle de l'édition active (reflétée par TabLivre en ce moment), puis on réécrit
  // TOUTE la table, sans quoi la ligne de l'autre édition serait perdue à chaque sauvegarde.
  if ComboBoxVersion.Itemindex <> -1 then
    begin
      for Ind := 1 to TabLivre.RowCount -1 do
          if TabLivre.Cells[ColLivreSel, Ind] = ConstSelectionne then
            Liste := Liste + AjouteAccolade(TabLivre.Cells[ColLivreCod, Ind]);
      ListeLivreParVersion.Values[CodeVersion(ComboBoxVersion.items[ComboBoxVersion.Itemindex])] := Liste;
    end;
  for Ind := 0 to ListeLivreParVersion.Count - 1 do
    // Nom vide : reliquat de l'ancien format .INI à une seule ligne 'BOOK=...' (sans
    // édition), lu comme tel une seule fois à la transition - ne rien réécrire, sans quoi
    // cette ligne morte resterait indéfiniment (13/09/2026, CONTEXT.md §2.70).
    if ListeLivreParVersion.Names[Ind] <> '' then
      Writeln(MyFile, ConstIniLivre + ListeLivreParVersion.Names[Ind] + '=' + ListeLivreParVersion.ValueFromIndex[Ind]);

  // Options desactivees par livre (pas encore d'interface pour les modifier - la table
  // n'est aujourd'hui peuplee que par lecture du .INI existant - mais on la reecrit pour
  // ne pas perdre une ligne posee a la main, meme principe que ListeLivreParVersion).
  for Ind := 0 to ListeOptionDesactiveeParLivre.Count - 1 do
    if ListeOptionDesactiveeParLivre.Names[Ind] <> '' then
      Writeln(MyFile, ConstIniOption + ListeOptionDesactiveeParLivre.Names[Ind] + '=' + ListeOptionDesactiveeParLivre.ValueFromIndex[Ind]);

  // Fermeture du fichier
  CloseFile(MyFile);

end;

procedure TMenu.ComboBoxLangueSelect(Sender: TObject);
  // Changement de langue en direct, sans fermer le programme (CONTEXT.md §2.8,
  // demandé par Nono le 17/08/2026). Mécanisme calqué sur celui déjà utilisé pour changer
  // de livre actif (TabLivreDblClick -> ChargerLivre(true,'')) : vider/recharger les
  // données, puis retraduire (Traduit(ValLangue,'')). Deux différences avec le changement
  // de livre : (1) il faut aussi rafraîchir les libellés déjà posés sur le menu lui-même
  // (RafraichirLibellesMenu, voir plus bas - FormCreate ne peut pas être rappelé tel quel,
  // il ajoute des colonnes de grille à chaque appel) ; (2) certaines fenêtres doivent être
  // fermées puis rouvertes pour afficher la nouvelle langue.
  // Fiches personnage (TWinPersonnages) et assistant de création (TWinCreations) sont
  // volontairement EXCLUS de la fermeture/réouverture automatique et BLOQUENT le
  // changement de langue s'ils sont ouverts (choix de Nono) : Personnage et les records
  // associés sont des variables globales PARTAGÉES par toutes les fenêtres WinPersonnage
  // (pas un champ propre à chaque fenêtre, voir CONTEXT.md §4) - les fermer sans
  // sauvegarde risquerait de perdre une saisie non enregistrée.
  // Les autres fenêtres secondaires ouvertes (catalogues Livre/Compétence/Talent/Race/
  // Sorts/Arme/Armure/Métier) sont fermées puis rouvertes à l'identique - état minimal
  // (juste "était ouverte"), pas de position/onglet/ligne sélectionnée mémorisé (choix
  // volontairement simple, comme le reste de ce chantier).
  var
    Langue:            String;
    Ind:               Integer;
    BloqueLangue:      Boolean;
    OuvertLivre:       Boolean;
    OuvertCompetence:  Boolean;
    OuvertTalent:      Boolean;
    OuvertRace:        Boolean;
    OuvertSort:        Boolean;
    OuvertArme:        Boolean;
    OuvertArmure:      Boolean;
    OuvertMetier:      Boolean;
  begin
    if (ComboBoxLangue.Itemindex) <> -1 then
      begin
        Langue := comboboxlangue.items[ComboBoxLangue.Itemindex];
        If Langue <> ValLangue then
          begin
            BloqueLangue := false;
            for Ind := 0 to Screen.FormCount - 1 do
              if ((Screen.Forms[Ind] is TWinPersonnages) or (Screen.Forms[Ind] is TWinCreations))
                 and Screen.Forms[Ind].Visible then
                BloqueLangue := true;

            if BloqueLangue then
              ShowMessage(GetTexteLibelle('RULES-MESS_055'))
            else
              if MessageDlg(GetTexteLibelle('RULES-MESS_041')+' : '+Langue, mtConfirmation, mbYesNo, 0) = mrYes then
                begin
                  OuvertLivre      := false;
                  OuvertCompetence := false;
                  OuvertTalent     := false;
                  OuvertRace       := false;
                  OuvertSort       := false;
                  OuvertArme       := false;
                  OuvertArmure     := false;
                  OuvertMetier     := false;
                  for Ind := Screen.FormCount - 1 downto 0 do
                    begin
                      if Screen.Forms[Ind] is TWinLivres then
                        begin
                          OuvertLivre := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinCompetence then
                        begin
                          OuvertCompetence := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWintTalent then
                        begin
                          OuvertTalent := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinRace then
                        begin
                          OuvertRace := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinSpells then
                        begin
                          OuvertSort := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinWeapons then
                        begin
                          OuvertArme := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinArmors then
                        begin
                          OuvertArmure := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinMetiers then
                        begin
                          OuvertMetier := true;
                          Screen.Forms[Ind].Close;
                        end;
                    end;

                  ValLangue := Langue;
                  ChargerLivre(true, '');
                  // ChargerLivre vient d'appliquer Traduit(ValLangue,'') à TOUS les livres, y
                  // compris INTERFACE - la langue d'interface doit rester décorrélée de la
                  // langue des livres (CONTEXT.md §2.70).
                  Traduit(ValLangueInterface, ConstInterfaceBook);
                  ChargerPersonnages();
                  RafraichirLibellesMenu();
                  SauveIni();

                  if OuvertLivre then
                    begin
                      FenLivre          := TWinLivres.Create(Application);
                      FenLivre.Position := poOwnerFormCenter;
                      FenLivre.Show;
                    end;
                  if OuvertCompetence then
                    begin
                      FenCompetence          := TWinCompetence.Create(Application);
                      FenCompetence.Position := poOwnerFormCenter;
                      FenCompetence.Show;
                    end;
                  if OuvertTalent then
                    begin
                      FenTalent          := TWintTalent.Create(Application);
                      FenTalent.Position := poOwnerFormCenter;
                      FenTalent.Show;
                    end;
                  if OuvertRace then
                    begin
                      FenRace          := TWinRace.Create(Application);
                      FenRace.Position := poOwnerFormCenter;
                      FenRace.Show;
                    end;
                  if OuvertSort then
                    begin
                      FenSort          := TWinSpells.Create(Application);
                      FenSort.Position := poOwnerFormCenter;
                      FenSort.Show;
                    end;
                  if OuvertArme then
                    begin
                      FenArme          := TWinWeapons.Create(Application);
                      FenArme.Position := poOwnerFormCenter;
                      FenArme.Show;
                    end;
                  if OuvertArmure then
                    begin
                      FenArmure          := TWinArmors.Create(Application);
                      FenArmure.Position := poOwnerFormCenter;
                      FenArmure.Show;
                    end;
                  if OuvertMetier then
                    begin
                      FenMetier          := TWinMetiers.Create(Application);
                      FenMetier.Position := poOwnerFormCenter;
                      FenMetier.Show;
                    end;
                end;
          end;
      end;
  end;

procedure TMenu.ComboBoxVersionSelect(Sender: TObject);
  // Rechargement à chaud de la version WFRP4/WFRP5 (Nono, 13/09/2026, CONTEXT.md §2.70) :
  // même mécanisme que ComboBoxLangueSelect (§2.8) - bloqué si WinPersonnage/WinCreation est
  // ouvert, fenêtres catalogue fermées puis rouvertes, ConstCheminLivre/ConstCheminPersonnage
  // (Var depuis le 13/09/2026) recalculés depuis la version choisie, TabLivre rescannée
  // (PeuplerTabLivre) puis ChargerLivre/ChargerPersonnages rejoués.
  // Chemins d'images races/métiers/sorts/niveaux recalculés depuis la version ici aussi
  // (Nono, 14/09/2026, CONTEXT.md §2.70) - même correctif qu'au démarrage (FormCreate) : plus
  // figés sur WFRP4\. Reste hors périmètre (pas demandé) : images du PDF de personnage
  // (ConstCheminPdf*), desormais suivies par PdfCheminsSelonVersion (repli WFRP4\).
  var
    Version:           String;
    Ind:               Integer;
    BloqueVersion:     Boolean;
    OuvertLivre:       Boolean;
    OuvertCompetence:  Boolean;
    OuvertTalent:      Boolean;
    OuvertRace:        Boolean;
    OuvertSort:        Boolean;
    OuvertArme:        Boolean;
    OuvertArmure:      Boolean;
    OuvertMetier:      Boolean;
  begin
    if ComboBoxVersion.ItemIndex <> -1 then
      begin
        Version := CodeVersion(ComboBoxVersion.Items[ComboBoxVersion.ItemIndex]);
        if Version <> ValVersion then
          begin
            BloqueVersion := false;
            for Ind := 0 to Screen.FormCount - 1 do
              // Visible : une fenetre fermee reste en vie (caHide par defaut), cachee
              if ((Screen.Forms[Ind] is TWinPersonnages) or (Screen.Forms[Ind] is TWinCreations))
                 and Screen.Forms[Ind].Visible then
                BloqueVersion := true;

            if BloqueVersion then
              ShowMessage(GetTexteLibelle('RULES-MESS_062'))
            else
              if MessageDlg(GetTexteLibelle('RULES-MESS_061')+' : '+Version, mtConfirmation, mbYesNo, 0) = mrYes then
                begin
                  OuvertLivre      := false;
                  OuvertCompetence := false;
                  OuvertTalent     := false;
                  OuvertRace       := false;
                  OuvertSort       := false;
                  OuvertArme       := false;
                  OuvertArmure     := false;
                  OuvertMetier     := false;
                  for Ind := Screen.FormCount - 1 downto 0 do
                    begin
                      if Screen.Forms[Ind] is TWinLivres then
                        begin
                          OuvertLivre := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinCompetence then
                        begin
                          OuvertCompetence := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWintTalent then
                        begin
                          OuvertTalent := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinRace then
                        begin
                          OuvertRace := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinSpells then
                        begin
                          OuvertSort := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinWeapons then
                        begin
                          OuvertArme := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinArmors then
                        begin
                          OuvertArmure := true;
                          Screen.Forms[Ind].Close;
                        end
                      else if Screen.Forms[Ind] is TWinMetiers then
                        begin
                          OuvertMetier := true;
                          Screen.Forms[Ind].Close;
                        end;
                    end;

                  ValVersion             := Version;
                  ConstCheminLivre       := '\DATABASE\' + ValVersion + '\';
                  ConstCheminPersonnage  := '\SAVED_CARACTERS\' + ValVersion + '\';
                  ForceDirectories(GetCurrentDir + ConstCheminPersonnage);  // absent dans le zip de release
                  ConstCheminImageRace  := '\DATABASE\' + ValVersion + '\PICTURES\SPECIE\';
                  ConstCheminImageMetier := '\DATABASE\' + ValVersion + '\PICTURES\CLASS\';
                  ConstCheminImageSort   := '\DATABASE\' + ValVersion + '\PICTURES\SPELL\';
                  ConstCheminImageNiveau       := '\PICTURES\' + ValVersion + '\NIV\';
                  ConstCheminImageNiveauRacine := '\PICTURES\' + ValVersion + '\';
       PdfCheminsSelonVersion(ValVersion);
                  PdfCheminsSelonVersion(ValVersion);
                  ChargerImage();
                  // Sélection de livres cochés de la NOUVELLE édition (CONTEXT.md §2.70) -
                  // sans ce recalcul, PeuplerTabLivre() rescannait bien les livres de la
                  // nouvelle édition mais gardait la sélection de l'ancienne (ListeLivre non
                  // à jour), cochant seulement les codes qu'elle avait en commun avec
                  // l'édition précédente - les autres livres restaient affichés mais
                  // décochés, donc non chargés (symptôme relevé par Nono après le switch).
                  ListeLivre            := ListeLivreParVersion.Values[ValVersion];
                  // Rescanner TabLivre AVANT ChargerLivre : celui-ci relit la sélection
                  // depuis TabLivre.Cells[ColLivreSel,...] (ForceMaj=true) pour savoir quoi
                  // importer - sans ce rescan, TabLivre resterait affichée avec les livres
                  // de l'édition précédente (symptôme relevé par Nono en testant WFRP5).
                  PeuplerTabLivre();
                  ReimporterAttributs();
                  ChargerLivre(true, '');
                  // ChargerLivre vient d'appliquer Traduit(ValLangue,'') à TOUS les livres, y
                  // compris INTERFACE - la langue d'interface doit rester décorrélée de la
                  // langue des livres (même correctif que ComboBoxLangueSelect, §2.70).
                  Traduit(ValLangueInterface, ConstInterfaceBook);
                  ChargerPersonnages();
                  RafraichirLibellesMenu();
                  SauveIni();

                  if OuvertLivre then
                    begin
                      FenLivre          := TWinLivres.Create(Application);
                      FenLivre.Position := poOwnerFormCenter;
                      FenLivre.Show;
                    end;
                  if OuvertCompetence then
                    begin
                      FenCompetence          := TWinCompetence.Create(Application);
                      FenCompetence.Position := poOwnerFormCenter;
                      FenCompetence.Show;
                    end;
                  if OuvertTalent then
                    begin
                      FenTalent          := TWintTalent.Create(Application);
                      FenTalent.Position := poOwnerFormCenter;
                      FenTalent.Show;
                    end;
                  if OuvertRace then
                    begin
                      FenRace          := TWinRace.Create(Application);
                      FenRace.Position := poOwnerFormCenter;
                      FenRace.Show;
                    end;
                  if OuvertSort then
                    begin
                      FenSort          := TWinSpells.Create(Application);
                      FenSort.Position := poOwnerFormCenter;
                      FenSort.Show;
                    end;
                  if OuvertArme then
                    begin
                      FenArme          := TWinWeapons.Create(Application);
                      FenArme.Position := poOwnerFormCenter;
                      FenArme.Show;
                    end;
                  if OuvertArmure then
                    begin
                      FenArmure          := TWinArmors.Create(Application);
                      FenArmure.Position := poOwnerFormCenter;
                      FenArmure.Show;
                    end;
                  if OuvertMetier then
                    begin
                      FenMetier          := TWinMetiers.Create(Application);
                      FenMetier.Position := poOwnerFormCenter;
                      FenMetier.Show;
                    end;
                end;
          end;
      end;
  end;

procedure TMenu.ChargerListeVersions();
  // Peuple ComboBoxVersion (Nono, 13/09/2026, CONTEXT.md §2.70) : scanne chaque
  // sous-répertoire de DATABASE\ (une version par répertoire, ex. WFRP4, futur WFRP5) et,
  // dès qu'un livre de ce répertoire porte <OFFICIAL>"0"</OFFICIAL> (le livre de règles
  // de cette version, seul à porter cette valeur - chargeconstantes.pas), lit sa balise
  // <VERSION> et arrête la recherche pour ce répertoire : inutile de lire les autres
  // livres, un seul par répertoire suffit à nommer la version.
  // Sélection : reprend la valeur du .INI (lue plus tôt dans ChargeIni, dans ValVersion)
  // si elle correspond à une version trouvée ; sinon (première ligne du .INI absente,
  // ou version disparue) se positionne sur la première ligne de la liste.
  var
    DirectoryPath: String;
    SearchDir:     TSearchRec;
    SearchFile:    TSearchRec;
    CheminFichier: String;
    Version:       String;
    ValIni:        String;
  begin
    ComboBoxVersion.Style := csDropDownList;
    ValIni     := ValVersion;
    ValVersion := '';

    DirectoryPath := GetCurrentDir + '\DATABASE\';
    if FindFirst(DirectoryPath + DirectorySeparator + '*', faDirectory, SearchDir) = 0 then
      begin
        repeat
          if ((SearchDir.Attr and faDirectory) = faDirectory) and (SearchDir.Name <> '.') and (SearchDir.Name <> '..') then
            begin
              Version := '';
              if FindFirst(DirectoryPath + SearchDir.Name + DirectorySeparator + '*.xml', faAnyFile, SearchFile) = 0 then
                begin
                  repeat
                    CheminFichier := DirectoryPath + SearchDir.Name + DirectorySeparator + SearchFile.Name;
                    if XmlLivreBalise(CheminFichier, ConstXmlOfficielLivre) = '0' then
                      begin
                        Version := XmlLivreBalise(CheminFichier, ConstXmlVersionLivre);
                        break;
                      end;
                  until FindNext(SearchFile) <> 0;
                  FindClose(SearchFile);
                end;

              if (Version <> '') and (ComboBoxVersion.Items.IndexOf(LibelleVersion(Version)) = -1) then
                begin
                  ComboBoxVersion.Items.Add(LibelleVersion(Version));
                  if Version = ValIni then
                    begin
                      ComboBoxVersion.ItemIndex := ComboBoxVersion.Items.Count - 1;
                      ValVersion                := Version;
                    end;
                end;
            end;
        until FindNext(SearchDir) <> 0;
        FindClose(SearchDir);
      end;

    // Rien dans le .INI, ou valeur disparue : première ligne de la liste (Nono, 13/09/2026).
    if (ValVersion = '') and (ComboBoxVersion.Items.Count > 0) then
      begin
        ComboBoxVersion.ItemIndex := 0;
        ValVersion                := CodeVersion(ComboBoxVersion.Items[0]);
      end;
  end;

procedure TMenu.ComboBoxLangueInterfaceSelect(Sender: TObject);
  // Sélecteur de langue de l'interface (RULES-LAB_*/RULES-MESS_*, décorrélé de la langue
  // des livres - Nono, 13/09/2026, CONTEXT.md §2.70) : même principe que
  // ComboBoxVersionSelect, seule la persistance .INI est branchée ici. Le rafraîchissement
  // de l'affichage (retraduire les libellés déjà posés dans la langue choisie) est laissé
  // à Nono.
  var
    Langue: String;
  begin
    if ComboBoxLangueInterface.ItemIndex <> -1 then
      begin
        Langue := ComboBoxLangueInterface.Items[ComboBoxLangueInterface.ItemIndex];
        if Langue <> ValLangueInterface then
          begin
            ValLangueInterface := Langue;
            SauveIni();
            // Retraduire uniquement les libellés d'interface (RULES-LAB_*/RULES-MESS_*, Livre
            // = ConstInterfaceBook) et rafraîchir les captions déjà posées sur le menu -
            // affichage demandé par Nono (CONTEXT.md §2.70). Les fenêtres secondaires
            // (WinLivre, WinCompetence, ...) ne sont pas fermées/rouvertes ici, contrairement
            // au changement de langue des livres : leurs libellés RULES-LAB_*/RULES-MESS_*
            // resteront dans l'ancienne langue d'interface jusqu'à réouverture.
            Traduit(ValLangueInterface, ConstInterfaceBook);
            RafraichirLibellesMenu();
          end;
      end;
  end;

procedure ListeFichiersInterface(Liste: TStrings);
  // Noms (sans extension) des fichiers d'interface de DATABASE\ : INTERFACE d'abord (anglais, base de repli), puis
  // INTERFACE_<LANGUE> par ordre alphabetique. Une langue creee dans WinLivre (Nouvelle traduction) est ainsi
  // reprise sans toucher au code.
  var
    SR:   TSearchRec;
    Noms: TStringList;
  begin
    Liste.Clear;
    if FileExists(GetCurrentDir + ConstCheminInterface + ConstFichierInterface + '.xml') then
      Liste.Add(ConstFichierInterface);
    Noms := TStringList.Create;
    try
      Noms.Sorted := True;
      if FindFirst(GetCurrentDir + ConstCheminInterface + ConstFichierInterface + '_*.xml', faAnyFile, SR) = 0 then
        begin
          repeat
            Noms.Add(ExtractStringBefore(SR.Name, '.'));
          until FindNext(SR) <> 0;
          FindClose(SR);
        end;
      Liste.AddStrings(Noms);
    finally
      Noms.Free;
    end;
  end;

procedure TMenu.ChargerListeLanguesInterface();
  // Peuple ComboBoxLangueInterface (Nono, 13/09/2026, CONTEXT.md §2.70) : pas de scan,
  // contrairement à ChargerListeVersions - INTERFACE.Xml/INTERFACE_FRANCAIS.Xml sont à
  // emplacement fixe (ConstCheminInterface), on lit juste leur balise <language> à tour de
  // rôle (XmlLivreBalise, comme le sélecteur de version). Sélection : reprend la valeur du
  // .INI (lue plus tôt dans ChargeIni, dans ValLangueInterface) si elle correspond à une
  // langue trouvée ; sinon (première ligne du .INI absente, ou langue disparue) se
  // positionne sur la première ligne de la liste - même règle que la version.
  var
    CheminFichier: String;
    Langue:        String;
    ValIni:        String;
    Fichiers:      TStringList;
    Ind:           Integer;
  begin
    ComboBoxLangueInterface.Style := csDropDownList;
    ValIni              := ValLangueInterface;
    ValLangueInterface  := '';

    Fichiers := TStringList.Create;
    try
      ListeFichiersInterface(Fichiers);
      for Ind := 0 to Fichiers.Count - 1 do
        begin
          CheminFichier := GetCurrentDir + ConstCheminInterface + Fichiers[Ind] + '.xml';
          Langue        := XmlLivreBalise(CheminFichier, ConstXmlLanguage);
          if (Langue <> '') and (ComboBoxLangueInterface.Items.IndexOf(Langue) = -1) then
            begin
              ComboBoxLangueInterface.Items.Add(Langue);
              if Langue = ValIni then
                begin
                  ComboBoxLangueInterface.ItemIndex := ComboBoxLangueInterface.Items.Count - 1;
                  ValLangueInterface                := Langue;
                end;
            end;
        end;
    finally
      Fichiers.Free;
    end;

    // Rien dans le .INI, ou valeur disparue : première ligne de la liste (même règle que
    // la version, Nono, 13/09/2026).
    if (ValLangueInterface = '') and (ComboBoxLangueInterface.Items.Count > 0) then
      begin
        ComboBoxLangueInterface.ItemIndex := 0;
        ValLangueInterface                := ComboBoxLangueInterface.Items[0];
      end;
  end;

procedure TMenu.LibelleLivreLigne(Ind: Integer);
  // Libelle d'un livre dans TabLivre : texte traduit s'il existe, sinon nom d'affichage du
  // livre (<BOOKNAME>) plutot que le code "BOOK ...". Un seul endroit pour le remplissage
  // initial et les deux rafraichissements (langue, traduction).
  var
    Nom:     String;
    Libelle: String;
    Affiche: String;
  begin
    Nom     := TabLivre.Cells[ColLivreCod, Ind];
    Libelle := GetTexteLibelle(Nom,'','',true);
    if SameText(Libelle, Nom) then
      begin
        Affiche := XmlNomAffichageLivre(GetCurrentDir + ConstCheminLivre + TabLivre.Cells[ColLivreChe, Ind]);
        if Affiche <> '' then
          Libelle := Affiche;
      end;
    TabLivre.Cells[ColLivreLib, Ind] := Libelle;
  end;

procedure TMenu.PeuplerTabLivre();
  // Peuple TabLivre (grille "Livres" du menu) et ComboBoxLangue en scannant ConstCheminLivre
  // (Var depuis le 13/09/2026, CONTEXT.md §2.70) - extrait de FormCreate (mécanique
  // inchangée) pour être rejouable au changement de version (ComboBoxVersionSelect), sans
  // quoi TabLivre restait figée sur les livres de l'ancienne édition après un rechargement.
  // Remise à zéro volontairement limitée à TabLivre/LivresLivres/LivresCharges (propres à
  // l'édition) : ListeLangue et ComboBoxLangue.Items ne sont PAS réinitialisés, une langue
  // déjà connue d'une édition précédente doit rester dans la liste plutôt que dupliquée.
  var
    SearchResult:  TSearchRec;
    DirectoryPath: String;
    I:             Integer;
    Ordre:         String;
    Nom:           String;
    PLivre:        StructureLivre;
  begin
    TabLivre.RowCount := 1;
    LivresLivres       := '';
    LivresCharges       := '';
    I := 0;

    DirectoryPath := GetCurrentDir + ConstCheminLivre;
    if FindFirst(DirectoryPath + '*.xml', faAnyFile, SearchResult) = 0 then
    begin
      repeat
        Nom := XmlLivre(ExtractStringBefore(SearchResult.Name,'.'));
        if Pos(AjouteAccolade(LivreLangue), ListeLangue) = 0 then
          begin
             ComboBoxLangue.Items.add(LivreLangue);
             if LivreLangue = ValLangue then
               ComboBoxLangue.itemindex := ComboBoxLangue.items.count - 1;
             ListeLangue := ListeLangue + AjouteAccolade(LivreLangue);
          end;

        if pos(AjouteAccolade(Nom), LivresLivres) = 0 then
        begin
          Inc(I);
          if TabLivre.RowCount <= I then
            TabLivre.RowCount      := TabLivre.RowCount + 1;
          if (ListeLivre = '') or (Pos(AjouteAccolade(Nom), ListeLivre) > 0) then
            begin
              TabLivre.Cells[ColLivreSel, I] := ConstSelectionne;
              LivresCharges        := LivresCharges + AjouteAccolade(Nom);
            end;
          LivresLivres                       := LivresLivres + AjouteAccolade(Nom);
          TabLivre.Cells[ColLivreCod, I]     := Nom;
          TabLivre.Cells[ColLivreChe, I]     := SearchResult.Name;
          LibelleLivreLigne(I);
          // Lu dans le XML du livre, pas dans ListLivre : au changement de version ListLivre est
          // vide ou garde les livres de l'ancienne edition (livre non trouve = Officiel 0 = tout « O »).
          Ordre                              := XmlLivreBalise(DirectoryPath + SearchResult.Name, ConstXmlOfficielLivre);
          if Ordre = '' then
            begin
              PLivre                         := ChercheLivreLibelle(Nom);
              Ordre                          := IntToStr(PLivre.Officiel);
            end;
          if Ordre = '2' then
            TabLivre.Cells[ColLivreO_F, I]   := ConstLivreFacultatif
          else
            TabLivre.Cells[ColLivreO_F, I]   := ConstLivreOfficiel;
          // Le Rulebook passe toujours en tete : certains livres (WFRP1) portent OFFICIAL=0 comme lui.
          if Nom = ConstRulesBook then
            TabLivre.Cells[ColLivreOrd, I]   := '0'+Nom
          else if Ordre = '0' then
            TabLivre.Cells[ColLivreOrd, I]   := '1'+Nom
          else
            TabLivre.Cells[ColLivreOrd, I]   := Ordre+Nom;
            TabLivre.Cells[ColLivreChe, I]   := SearchResult.Name;
          ListBook                 += [Nom];
        end;
      until FindNext(SearchResult) <> 0;
      FindClose(SearchResult);
    end;
    TabLivre.SortColRow(true,ColLivreOrd);
    MajTauxTraduction();
  end;

function LangueEnTete(const Fichier: String): String;
  // Langue d'un livre lue dans les premiers octets du fichier (balise <language> de l'en-tete),
  // sans parser le livre entier.
  var
    F:    TFileStream;
    Buf:  String;
    P, Q: Integer;
  begin
    Result := '';
    try
      F := TFileStream.Create(Fichier, fmOpenRead or fmShareDenyNone);
      try
        SetLength(Buf, 2048);
        SetLength(Buf, F.Read(Buf[1], 2048));
      finally
        F.Free;
      end;
    except
      Exit;
    end;
    P := Pos('<language>', Buf);
    Q := Pos('</language>', Buf);
    if (P = 0) or (Q <= P) then Exit;
    Result := UpperCase(RemoveQuotes(Trim(Copy(Buf, P + 10, Q - P - 10))));
  end;

procedure TMenu.MajTauxTraduction();
  // Colonne "pourcentage traduit" de TabLivre pour la langue choisie (ValLangue). Vide pour l'anglais et pour un
  // livre deja ecrit dans cette langue ; 0 % sans fichier de traduction ; sinon textes traduits / textes du livre
  // (TraductionTexte.CompterTraduction). Fichier de traduction : <livre>_<LANGUE>.Xml a cote du livre. Seuls les
  // livres qui ont une traduction dans cette langue sont lus en entier.
  var
    Ind:            Integer;
    Source, Trad:   String;
    DocSource:      TXMLDocument;
    DocTrad:        TXMLDocument;
    Traduits:       Integer;
    Total:          Integer;
  begin
    for Ind := 1 to TabLivre.RowCount - 1 do
      begin
        TabLivre.Cells[ColLivreTrd, Ind] := '';
        if (TabLivre.Cells[ColLivreCod, Ind] = '') or (ValLangue = '') or (ValLangue = ConstAnglais) then
          Continue;
        Source := GetCurrentDir + ConstCheminLivre + TabLivre.Cells[ColLivreChe, Ind];
        if not FileExists(Source) then Continue;
        Trad := ChangeFileExt(Source, '') + '_' + UpperCase(ValLangue) + '.Xml';
        if not FileExists(Trad) then
          begin
            if LangueEnTete(Source) <> UpperCase(ValLangue) then
              TabLivre.Cells[ColLivreTrd, Ind] := '0 %';
            Continue;
          end;
        DocSource := nil;
        DocTrad   := nil;
        try
          try
            ReadXMLFile(DocSource, Source);
            ReadXMLFile(DocTrad, Trad);
            CompterTraduction(DocSource, DocTrad, Traduits, Total);
            if Total > 0 then
              TabLivre.Cells[ColLivreTrd, Ind] := IntToStr((Traduits * 100) div Total) + ' %';
          except
            TabLivre.Cells[ColLivreTrd, Ind] := '';
          end;
        finally
          DocSource.Free;
          DocTrad.Free;
        end;
      end;
  end;

Procedure TMenu.RafraichirLibellesMenu();
  // Rafraîchit les libellés déjà posés sur le menu principal après un changement de
  // langue en direct (CONTEXT.md §2.8). Duplique DÉLIBÉRÉMENT un sous-ensemble de
  // FormCreate plutôt que de le rappeler : FormCreate fait aussi de la construction à
  // usage unique (GridAjouteColonne ajoute une colonne à chaque appel, les Listxxx.Create
  // fuiraient l'instance précédente, plusieurs listes/tableaux sont remplis par += donc
  // dupliqueraient leur contenu) - seul le sous-ensemble "libellé simple, sûr à
  // réécrire" est repris ici. Si un nouveau libellé est ajouté à FormCreate plus tard,
  // penser à l'ajouter aussi ici s'il doit changer avec la langue.
  var
    Ind:          Integer;
    LargeurForm:  Integer;
    HauteurForm:  Integer;
    LargeurLivre: Integer;
    HauteurLivre: Integer;
    LargeurPerso: Integer;
    HauteurPerso: Integer;
  begin
    // Filet de sécurité contre le grossissement cumulatif de la fenêtre à chaque
    // changement de langue (CONTEXT.md §2.8, bug du 18/08/2026) : malgré le
    // ScaleDpi=false plus bas, la taille continuait à dériver un peu plus à chaque appel
    // - cause exacte non identifiée avec certitude (LCL). Solution de contournement
    // proposée par Nono : mémoriser la taille de la fenêtre et des deux grilles avant
    // tout rafraîchissement, et la réimposer de force juste après, quoi qu'il se soit
    // passé entre-temps.
    LargeurForm  := Self.Width;
    HauteurForm  := Self.Height;
    LargeurLivre := TabLivre.Width;
    HauteurLivre := TabLivre.Height;
    LargeurPerso := TabPersonnage.Width;
    HauteurPerso := TabPersonnage.Height;

    TypeEquipCC         := GetTexteLibelle('RULES-LAB_061');
    TypeEquipCT         := GetTexteLibelle('RULES-LAB_062');
    TypeEquipMU         := GetTexteLibelle('RULES-LAB_060');
    TypeEquipMetierArme := TypeEquipCC+','+TypeEquipCT+','+TypeEquipMU;
    TypeEquipWe         := GetTexteLibelle('RULES-LAB_063');
    TypeEquipDI         := GetTexteLibelle('RULES-LAB_064');
    TypeEquipAN         := GetTexteLibelle('RULES-LAB_252');
    TypeEquipAR         := GetTexteLibelle('RULES-LAB_065');
    TypeEquipARS        := GetTexteLibelle('RULES-LAB_150');

    // En-têtes de colonnes déjà créées (pas de GridAjouteColonne ici, qui ajouterait une
    // colonne de plus à chaque changement de langue - on réécrit juste le titre de la
    // colonne existante, retrouvée via les mêmes constantes d'indice que FormCreate).
    TabLivre.Columns[ColLivreLib - 1].Title.Caption := GetTexteLibelle('RULES-LAB_014');

    TabPersonnage.Columns[ColPersoNom - 1].Title.Caption := GetTexteLibelle('RULES-LAB_014');
    TabPersonnage.Columns[ColPersoWor - 1].Title.Caption := GetTexteLibelle('RULES-LAB_006');
    TabPersonnage.Columns[ColPersoRac - 1].Title.Caption := GetTexteLibelle('RULES-LAB_042');
    TabPersonnage.Columns[ColPersoNiv - 1].Title.Caption := GetTexteLibelle('RULES-LAB_019');
    TabPersonnage.Columns[ColPersoTXp - 1].Title.Caption := GetTexteLibelle('RULES-LAB_035');
    TabPersonnage.Columns[ColPersoCXp - 1].Title.Caption := GetTexteLibelle('RULES-LAB_041');
    TabPersonnage.Columns[ColPersoLOb - 1].Title.Caption := GetTexteLibelle('RULES-LAB_128');
    TabPersonnage.Columns[ColPersoLNe - 1].Title.Caption := GetTexteLibelle('RULES-LAB_136');

    // Libellés des livres eux-mêmes (une ligne par livre dans TabLivre, pas juste
    // l'en-tête de colonne) - même appel que FormCreate (ligne ~620).
    for Ind := 1 to TabLivre.RowCount - 1 do
      if TabLivre.Cells[ColLivreCod, Ind] <> '' then
        LibelleLivreLigne(Ind);
    TabLivre.Columns[ColLivreTrd - 1].Title.Caption := GetTexteLibelle('RULES-LAB_679');
    MajTauxTraduction();

    ConstArbreAttribut          := GetTexteLibelle('RULES-LAB_008');
    ConstArbreCompetence        := GetTexteLibelle('RULES-LAB_009');
    ConstArbreTalent            := GetTexteLibelle('RULES-LAB_007');
    ConstArbreAuChoix           := GetTexteLibelle('RULES-LAB_010');
    ConstArbreEnsemble          := GetTexteLibelle('RULES-LAB_186');
    ConstArbreMetierPossible    := GetTexteLibelle('RULES-LAB_011');
    ConstArbreRacePossible      := GetTexteLibelle('RULES-LAB_012');
    ConstArbreEquipement        := GetTexteLibelle('RULES-LAB_013');
    ConstArbreCorruption        := GetTexteLibelle('RULES-LAB_156');

    Label1.Caption              := GetTexteLibelle('RULES-LAB_082');
    ButtonCompetence.Caption    := GetTexteLibelle('RULES-LAB_009');
    ButtonTalent.Caption        := GetTexteLibelle('RULES-LAB_007');
    ButtonMetier.Caption        := GetTexteLibelle('RULES-LAB_006');
    ButtonRace.Caption          := GetTexteLibelle('RULES-LAB_042');
    RemplirTabBibliotheque();

    Label2.Caption              := GetTexteLibelle('RULES-LAB_081');
    ButtonCreation.Caption      := GetTexteLibelle('RULES-LAB_079');
    ButtonModification.Caption  := GetTexteLibelle('RULES-LAB_080');

    Label3.Caption              := GetTexteLibelle('RULES-LAB_128');

    ButtonCreationLivre.Caption := GetTexteLibelle('RULES-LAB_154');
    ButtonOuvrirLivre.Caption   := GetTexteLibelle('RULES-LAB_155');
    if Assigned(ButtonMAJLivres) then
      ButtonMAJLivres.Caption   := GetTexteLibelle('RULES-LAB_295');

    Label4.Caption              := GetTexteLibelle('RULES-LAB_183');
    Label5.Caption              := GetTexteLibelle('RULES-LAB_184');
    ButtonOptionRegle.Caption   := GetTexteLibelle('RULES-LAB_277');
    PoserBoutonTestsAuto();

    // Remettre les colonnes auto-dimensionnées à leur largeur de départ (celle donnée à
    // GridAjouteColonne dans FormCreate) avant de rappeler AdjustGridColumnsWidth : sa
    // Grid.AutoSizeColumn ne fait qu'agrandir une colonne, jamais la rétrécir - sans ce
    // reset, les tables s'élargissaient un peu plus à chaque changement de langue en
    // direct (CONTEXT.md §2.8, bug du 17/08/2026).
    TabLivre.ColWidths[ColLivreSel] := 20;
    TabLivre.ColWidths[ColLivreLib] := 230;
    TabLivre.ColWidths[ColLivreRac] := 30;
    TabLivre.ColWidths[ColLivreWor] := 30;
    TabLivre.ColWidths[ColLivreO_F] := 30;
    TabLivre.ColWidths[ColLivreAbr] := 30;
    TabLivre.ColWidths[ColLivreCom] := 30;
    TabLivre.ColWidths[ColLivreTal] := 30;
    TabLivre.ColWidths[ColLivreArm] := 30;
    TabLivre.ColWidths[ColLivreArU] := 30;
    TabLivre.ColWidths[ColLivreEqu] := 30;
    TabLivre.ColWidths[ColLivreSor] := 30;
    TabLivre.ColWidths[ColLivreTra] := 30;
    TabLivre.ColWidths[ColLivreTrd] := 50;

    TabPersonnage.ColWidths[ColPersoNom] := 100;
    TabPersonnage.ColWidths[ColPersoWor] := 150;
    TabPersonnage.ColWidths[ColPersoRac] := 200;
    TabPersonnage.ColWidths[ColPersoNiv] := 30;
    TabPersonnage.ColWidths[ColPersoTXp] := 30;
    TabPersonnage.ColWidths[ColPersoCXp] := 30;
    TabPersonnage.ColWidths[ColPersoLOb] := 150;
    TabPersonnage.ColWidths[ColPersoLNe] := 150;

    AdjustGridColumnsWidth(TabLivre, Self.Height, true, true, True, 0, 10, ssAutoBoth, false);
    AdjustGridColumnsWidth(TabPersonnage, Self.Height, true, true, True, 0, 10, ssAutoBoth, false);

    // Réimposer la taille mémorisée au tout début, quoi qu'AdjustGridColumnsWidth ait pu
    // faire dériver entre-temps.
    Self.Width          := LargeurForm;
    Self.Height         := HauteurForm;
    TabLivre.Width       := LargeurLivre;
    TabLivre.Height      := HauteurLivre;
    TabPersonnage.Width  := LargeurPerso;
    TabPersonnage.Height := HauteurPerso;

    // Les deux AdjustGridColumnsWidth ci-dessus peuvent avoir fait deriver TabLivre/
    // TabPersonnage un instant avant la remise en place ci-dessus - Button3/
    // TabPersonnage.Left/Button1/colonne Bibliotheque (ancrage du 15/09/2026) ne sont pas
    // touches par cette fonction et pourraient donc rester calcules sur un etat
    // intermediaire perime. Reancre tout depuis l'etat final remis en place ci-dessus.
    AjustePositionFenetre();
  end;

procedure TMenu.FormActivate(Sender: TObject);
begin
  if NeedUpdate then
    begin
      ChargerPersonnages;
      NeedUpdate := false;
    end;
  if RecherchePersonnage <> '' then
    begin
      NomPersonnage         := RecherchePersonnage;
      RecherchePersonnage   := '';
      FenPersonnage         := TWinPersonnages.Create(Application);
      FenPersonnage.Position:= poOwnerFormCenter;
      FenPersonnage.Show;
    end
end;

Procedure TMenu.ChargeIni();
  var
    Ind:           Integer;
    DirectoryPath: string;
    fichier:       TextFile;
    ligne:         string;
    LocLangue:     String;
    LocVersion:    String;
    LocLangueInterface: String;
    LocUniteTaille: String;
    PosEgal:       Integer;
  begin
    // récupérer la langue dans la fichier ini s'il existe
    LocLangue     := ValLangue;
    LocVersion    := '';
    LocLangueInterface := '';
    LocUniteTaille := '';
    DirectoryPath := GetCurrentDir+ConstFichierIni;
    if FileExists(DirectoryPath) then
      begin
        AssignFile(fichier, DirectoryPath);
        Reset(fichier);

        while not Eof(fichier) do
          begin
            ReadLn(fichier, ligne);
            Ligne := ReplaceTilde(Ligne);
            if pos(ConstIniLangue, Ligne) > 0 then
              LocLangue := ExtractStringAfter(Ligne,ConstIniLangue);
            // BOOK<version>=<liste> - une ligne par édition (13/09/2026, CONTEXT.md §2.70) ;
            // ListeLivre (la sélection RÉSOLUE de l'édition active) n'est affectée
            // définitivement que plus tard dans FormCreate, une fois ValVersion validée par
            // ChargerListeVersions - même principe que ValVersion ci-dessous.
            if pos(ConstIniLivre, Ligne) = 1 then
              begin
                PosEgal := Pos('=', Ligne);
                if PosEgal > Length(ConstIniLivre) then
                  ListeLivreParVersion.Values[Copy(Ligne, Length(ConstIniLivre)+1, PosEgal-Length(ConstIniLivre)-1)]
                    := Copy(Ligne, PosEgal+1, MaxInt);
              end;
            // OPTION<Livre>=<liste des codes d'option desactivees, separes par virgule>
            // (A FAIRE.txt "TOGGLE .INI PAR LIVRE", 22/09/2026) - meme principe que BOOK<version>=
            // ci-dessus.
            if pos(ConstIniOption, Ligne) = 1 then
              begin
                PosEgal := Pos('=', Ligne);
                if PosEgal > Length(ConstIniOption) then
                  ListeOptionDesactiveeParLivre.Values[Copy(Ligne, Length(ConstIniOption)+1, PosEgal-Length(ConstIniOption)-1)]
                    := Copy(Ligne, PosEgal+1, MaxInt);
              end;
            if pos(ConstIniVersion, Ligne) > 0 then
              LocVersion := ExtractStringAfter(Ligne,ConstIniVersion);
            if pos(ConstIniLangueInterface, Ligne) > 0 then
              LocLangueInterface := ExtractStringAfter(Ligne,ConstIniLangueInterface);
            if pos(ConstIniUniteTaille, Ligne) = 1 then
              LocUniteTaille := UpperCase(Trim(ExtractStringAfter(Ligne,ConstIniUniteTaille)));
            if pos(ConstIniImagesDefautSeul, Ligne) = 1 then
              ImagesDefautSeul := UpperCase(Trim(ExtractStringAfter(Ligne,ConstIniImagesDefautSeul))) = '1';
          end;
        CloseFile(fichier);
      end;
    ValLangue  := LocLangue;
    // ValVersion n'est affectée définitivement que dans ChargerListeVersions (appelée
    // plus tard dans FormCreate, une fois ComboBoxVersion peuplé) - même ordre que la
    // langue : lecture brute du .INI ici, résolution contre la liste déroulante ensuite.
    ValVersion := LocVersion;
    // Même principe pour la langue de l'interface (RULES-LAB_*/RULES-MESS_*, CONTEXT.md
    // §2.70) : résolution définitive dans ChargerListeLanguesInterface, appelée plus tard
    // dans FormCreate, une fois ComboBoxLangueInterface peuplé.
    ValLangueInterface := LocLangueInterface;
    // Unite de taille par defaut : cle absente ou inconnue -> CM si les livres sont en francais
    if (LocUniteTaille = ConstUniteCm) or (LocUniteTaille = ConstUniteInch) then
      UniteTaille := LocUniteTaille
    else if LocLangue = 'FRANCAIS' then
      UniteTaille := ConstUniteCm
    else
      UniteTaille := ConstUniteInch;

    // retrouver la langue dans la liste déroulante
    for ind := 0 to ComboBoxLangue.items.count -1 do
      if ComboBoxLangue.items[Ind] = LocLangue then
        begin
          ComboBoxLangue.itemindex := Ind;
          ValLangue                := LocLangue; // la langue existe, on peut l'enregistrer
          break;
        end;

  end;

procedure TMenu.ChargerLivre(ForceMaJ: Boolean; ForceLivre: String);
  var
    i:                     Integer = 0;

    procedure ImporterUnLivre(FileName, NomLivre: String);
      var
        J: Integer;

        procedure Pose(Col, Nb: Integer);
          begin
            if Nb > 0 then
              TabLivre.Cells[Col, J] := IntToStr(Nb);
          end;

      begin
        ChargementAvance(NomLivre);
        // Rechargement complet : les textes des livres ont ete vides plus haut, la passe « vrai »
        // (libelles seuls) les remet ; sans elle les libelles propres a un livre restent en code.
        if ForceMaj then
          begin
            ImportLibellesSeuls := true;
            try
              XmlImport(FileName, true);
            finally
              ImportLibellesSeuls := false;
            end;
          end;
        XmlImport(FileName, false);
        for J := 1 to TabLivre.RowCount - 1 do
          if TabLivre.Cells[ColLivreCod, J] = NomLivre then
            begin
              Pose(ColLivreRac, LivreNbRace);
              Pose(ColLivreWor, LivreNbMetier);
              Pose(ColLivreCom, LivreNbCompetence);
              Pose(ColLivreTal, LivreNbTalent);
              Pose(ColLivreArm, LivreNbArme);
              Pose(ColLivreArU, LivreNbArmure);
              Pose(ColLivreEqu, LivreNbTrapping);
              Pose(ColLivreSor, LivreNbSort);
              Pose(ColLivreTra, LivreNbTrait);
              break;
            end;
      end;

    procedure RazCompteurs;
      begin
        NbRace	                    := 0;
        NbEspece                    := 0;
        NbNation                    := 0;
        NbRegle                     := 0;
        NbRegleMetier               := 0;
        NbTalent	            := 0;
        NbCompetence	            := 0;
        NbMetierCompetence	    := 0;
        NbMetier	            := 0;
        NbMetierNiveau	            := 0;
        NbMetierAttribut	    := 0;
        NbMetierTalent	            := 0;
        NbRaceMetier	            := 0;
        NbRaceAttribut	            := 0;
        NbRacePhysique              := 0;
        NbRaceCouleur               := 0;
        NbRaceNom                   := 0;
        NbRaceNomModele             := 0;
        NbRaceCompetence	    := 0;
        NbRaceTalent	            := 0;
        NbTalentCreation	    := 0;
        NbArme	                    := 0;
        NbArmure	            := 0;
        NbArmureSimplifiee          := 0;
        NbArmeBonus	            := 0;
        NbMetierEquipement	    := 0;
        NbArmureBonus	            := 0;
        NbSort	                    := 0;
        NbFabrication	            := 0;
        NbFabricationModificateur   := 0;
        NbSigneAstral               := 0;
        NbSigneEffet                := 0;
        NbRaceCreation	            := 0;
        NbMetierSousMetier	    := 0;
        NbMetierRaceChoixMetier	    := 0;
        NbTalentUnique	            := 0;
        NbCompetenceUnique	    := 0;
        NbArmeUnique	            := 0;
        NbTraduction                := 0;
        NbRaceCorruptionCreation    := 0;
        nbCorruptionTable           := 0;
        nbCorruptionChance          := 0;
        nbDisease                   := 0;
        nbAffliction                := 0;
        NbClassEquipement           := 0;
        NbTalentEffet                := 0;
        NbTalentCompetenceModif     := 0;
        NbTalentModificateur        := 0;
        NbArmeModificateur          := 0;
        NbArmureBonusModificateur   := 0;
        NbCorruptionModificateur    := 0;
        NbRaceOpinion               := 0;
        NbTrapping                  := 0;
        NbTrait                     := 0;
        NbTraitOption               := 0;
        NbSortTalent                := 0;
        NbCareerBonus               := 0;
        NbCareerBonusNiveau         := 0;
        NbCareerBonusModificateur   := 0;
        NbCareerBonusSpecialRule    := 0;
        NbCareerAdaptation          := 0;
        NbCareerAdaptationLigne     := 0;
      end;

    procedure ViderListes;
      var
        I: Integer;
      begin
        // vider les données
        ListRace.Clear;
        ListEspece.Clear;
        ListNation.Clear;
        ListRegle.Clear;
        ListRegleSource.Clear;
        ListRegleMetier.Clear;
        ListRegleEthnie.Clear;
        ListRegleFond.Clear;
        ListFondTirage.Clear;
        ListFondCompte.Clear;
        ListTalent.Clear;
        OublieFamillesTalent;
        ListCompetence.Clear;
        ListMetierCompetence.Clear;
        ListMetier.Clear;
        ListMetierNiveau.Clear;
        ListMetierAttribut.Clear;
        ListMetierAvance.Clear;
        ListMetierArgent.Clear;
        ListMetierSortie.Clear;
        ListArtisanMetier.Clear;
        ListClasseV1.Clear;
        ListTirageCompV1.Clear;
        ListAgeCompV1.Clear;
        ListGainMagieV1.Clear;
        ListApprentissageSortV1.Clear;
        ListHandicapV1.Clear;
        ListTirageHandicapV1.Clear;
        ListAvancementPretreV1.Clear;
        ListFamilierV1.Clear;
        ListCulteV1.Clear;
        ListPriereCulteV1.Clear;
        ListObjetV1.Clear;
        ListMetierBase.Clear;
        ListMetierTalent.Clear;
        ListRaceMetier.Clear;
        ListRaceMetierSource.Clear;
        ListRaceAttribut.Clear;
        ListRacePhysique.Clear;
        ListRaceCouleur.Clear;
        ListRaceDetailV2.Clear;
        ListTablePersonnelle.Clear;
        ListRaceNom.Clear;
        ListRaceNomModele.Clear;
        ListRaceNomRegle.Clear;
        ListRaceCompetence.Clear;
        ListRaceTalent.Clear;
        ListTalentCreation.Clear;
        ListArme.Clear;
        ListArmure.Clear;
        ListTrapping.Clear;
        // Oubliées jusqu'au 21/08/2026 : toutes deux remplies par XmlImport comme leurs
        // voisines, mais jamais vidées ici - chaque rechargement (changement de livre actif
        // ou de langue) rajoutait donc leur contenu par-dessus l'ancien. Visible sur le PDF
        // de personnage : l'annotation d'armure s'affichait deux fois, "(4) -10% (4) -10%".
        ListArmureSimplifiee.Clear;
        ListArmureSimplifieeSource.Clear;
        ListOptionRegle.Clear;
        ListArmeBonus.Clear;
        ListMetierEquipement.Clear;
        ListArmureBonus.Clear;
        ListSort.Clear;
        ListSortTalent.Clear;
        ListTrait.Clear;
        ListTraitOption.Clear;
        ListCareerBonus.Clear;
        ListCareerBonusNiveau.Clear;
        ListCareerBonusSpecialRule.Clear;
        ListCareerAdaptation.Clear;
        ListCareerAdaptationLigne.Clear;
        ListFabrication.Clear;
        ListSigneAstral.Clear;
        ListSigneAstralSource.Clear;
        ListSigneEffet.Clear;
        ListRaceCreation.Clear;
        ListMetierSousMetier.Clear;
        ListMetierRaceChoixMetier.Clear;
        ListRaceCorruptionCreation.Clear;
        ListCorruptionTable.Clear;
        ListCorruptionChance.Clear;
        ListDisease.Clear;
        ListAffliction.Clear;
        ListAfflictionCompetenceAttributModif.Clear;
        ListClassEquipement.Clear;
        ListTalentEffet.Clear;
        ListTalentCompetenceModif.Clear;
        ListRaceOpinion.Clear;
        ListCorruptionCompetenceAttributModif.Clear;
        ListCorruptionTalent.Clear;
        ListCorruptionEquipement.Clear;
        ListArmureBonusTalent.Clear;
        ListArmeBonusTalent.Clear;
        // ListArmeModificateur/ListArmureBonusModificateur n'avaient pas d'equivalent .Clear
        // avant leur creation (migration ModifyCarac, 11/09/2026) : rattrapage au passage,
        // meme risque de doublon au rechargement que l'oubli documente ci-dessus pour
        // ListArmureSimplifiee/ListArmeBonus le 21/08/2026.
        ListModificateur.Clear;
        ListConditionDonnee.Clear;
        // Textes et traductions : jamais vides jusqu'au 08/11/2026, donc un rechargement complet (changement
        // de Version, de langue des livres, de selection) empilait les anciens par-dessus les nouveaux et les
        // recherches rendaient le PREMIER trouve, celui de l'edition precedente. On retire tout sauf ceux de
        // l'interface (lue une seule fois, hors dossier de version) ; les livres charges les remettent.
        for I := ListTexte.Count - 1 downto 0 do
          if ListTexte[I].Livre <> ConstInterfaceBook then
            begin
              ListTexte.Delete(I);
              Dec(NbTexte);
            end;
        for I := ListTraduction.Count - 1 downto 0 do
          if ListTraduction[I].Livre <> ConstInterfaceBook then
            begin
              ListTraduction.Delete(I);
        // (NbTraduction est deja remis a 0 plus haut)
            end;
      end;

    procedure ChargerLesLivres;
      var
        SearchResult: TSearchRec;
        DirectoryPath: string;
        Nom: String;
        ListeFichiersACharger: TStringList;
        ListeNomsACharger: TStringList;
        Idx: Integer;
        RulesBookIndex: Integer;
      begin
        directoryPath          := GetCurrentDir + ConstCheminLivre;
        ListeFichiersACharger  := TStringList.Create;
        ListeNomsACharger      := TStringList.Create;
        try
          if FindFirst(directoryPath + '*.xml', faAnyFile, searchResult) = 0 then
          begin
            repeat
              Nom := XmlLivre(ExtractStringBefore(searchResult.Name,'.'));
              if (pos(AjouteAccolade(Nom), LivresCharges) > 0) and ((ForceLivre = '') or ((LivreComplet = false) and (ForceLivre = Nom))) then
                begin
                  ListeFichiersACharger.Add(ExtractStringBefore(searchResult.Name, '.'));
                  ListeNomsACharger.Add(Nom);
                end;
            until FindNext(searchResult) <> 0;
            FindClose(searchResult);
          end;

          RulesBookIndex := -1;
          for Idx := 0 to ListeNomsACharger.Count - 1 do
            if ListeNomsACharger[Idx] = ConstRulesBook then
              begin
                RulesBookIndex := Idx;
                break;
              end;

          ChargementDebut(GetTexteLibelle('RULES-MESS_119'), ListeNomsACharger.Count);
          if RulesBookIndex >= 0 then
            begin
              ImporterUnLivre(ListeFichiersACharger[RulesBookIndex], ListeNomsACharger[RulesBookIndex]);
              ListeFichiersACharger.Delete(RulesBookIndex);
              ListeNomsACharger.Delete(RulesBookIndex);
            end;

          for Idx := 0 to ListeFichiersACharger.Count - 1 do
            ImporterUnLivre(ListeFichiersACharger[Idx], ListeNomsACharger[Idx]);
        finally
          ChargementFin;
          ListeFichiersACharger.Free;
          ListeNomsACharger.Free;
        end;
      end;

  begin
    // Raz des variables
    if ForceMaj then
      begin
        RazCompteurs;
        ViderListes;
      end;

    // chercher les livres
    if ForceMaj or (ForceLivre <> '') then
      begin
        LivresCharges := '';
        for I := 1 to TabLivre.RowCount - 1 do
          if (TabLivre.Cells[ColLivreSel, I] = ConstSelectionne) or (TabLivre.Cells[ColLivreCod, I] = ForceLivre) then
            LivresCharges := LivresCharges + AjouteAccolade(TabLivre.Cells[ColLivreCod, I]);
      end;

    // mettre à jour les données
    // Le RULESBOOK doit être importé en premier parmi les livres à charger ici,
    // pour la même raison que dans FormCreate (voir xmlexportimport.pas /
    // ChercheRace) : un supplément (ex. BOOK LUSTRIA) peut ajouter un <Specie>
    // qui référence une race déjà définie dans le RULESBOOK.
    ChargerLesLivres;

    // Tous les livres sont chargés : propager l'accessibilité des métiers entre ethnies
    // d'une même race (voir ChargeRaceMetier.CompleteRaceMetierParEspece).
    CompleteRaceMetierParEspece;

    // affichages des valeurs
    TotLivreRace.Text            := IntToStr(NbRace);
    TotLivreRace.Alignment       := TaCenter;
    TotLivreMetier.Text          := IntToStr(NbMetier);
    TotLivreMetier.Alignment     := TaCenter;
    TotLivreCompetence.Text      := IntToStr(NbCompetenceUnique);
    TotLivreCompetence.Alignment := TaCenter;
    TotLivreTalent.Text          := IntToStr(NbTalentUnique);
    TotLivreTalent.Alignment     := TaCenter;
    RemplirTabBibliotheque();

    Traduit(ValLangue, '');
  end;

procedure TMenu.TabLivreMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  // Survol de l'en-tête d'une colonne de TabLivre : le hint donne la signification de la
  // lettre. Calculé à chaque survol (GetTexteLibelle), donc suit le changement de langue.
var
  ACol, ARow: Integer;
  Texte:      String;
begin
  Texte := '';
  TabLivre.MouseToCell(X, Y, ACol, ARow);
  if ARow = 0 then
    begin
      if ACol = ColLivreSel then Texte := GetTexteLibelle('RULES-LAB_211')
      else if ACol = ColLivreRac then Texte := GetTexteLibelle('RULES-LAB_212')
      else if ACol = ColLivreWor then Texte := GetTexteLibelle('RULES-LAB_213')
      else if ACol = ColLivreO_F then Texte := GetTexteLibelle('RULES-LAB_214')
      else if ACol = ColLivreCom then Texte := GetTexteLibelle('RULES-LAB_215')
      else if ACol = ColLivreTal then Texte := GetTexteLibelle('RULES-LAB_216')
      else if ACol = ColLivreArm then Texte := GetTexteLibelle('RULES-LAB_217')
      else if ACol = ColLivreArU then Texte := GetTexteLibelle('RULES-LAB_218')
      else if ACol = ColLivreEqu then Texte := GetTexteLibelle('RULES-LAB_219')
      else if ACol = ColLivreSor then Texte := GetTexteLibelle('RULES-LAB_220')
      else if ACol = ColLivreTra then Texte := GetTexteLibelle('RULES-LAB_221')
      else if ACol = ColLivreTrd then Texte := GetTexteLibelle('RULES-LAB_678');
    end;
  if TabLivre.Hint <> Texte then
    begin
      TabLivre.Hint := Texte;
      Application.CancelHint;
    end;
end;

procedure TMenu.RemplirTabBibliotheque();
  var
    PTrapping:  StructureTrapping;
    PObjetV1:   StructureObjetV1;
    NbVehicule: Integer;
    LargLib:    Integer;
    LargTot:    Integer;
    LargCell:   Integer;
    Ind:        Integer;
  // Tableau des categories secondaires de la Bibliotheque (Arme, Armure, Equipement, Sort) :
  // remplace les lignes bouton + total + image. Pour ajouter une categorie : une ligne ici
  // et son ouverture dans TabBibliothequeDblClick (l'ordre des lignes est le meme).
  procedure Ligne(Ind: Integer; Libelle: String; Nb: Integer);
    begin
      TabBibliotheque.Cells[0, Ind] := Libelle;
      TabBibliotheque.Cells[1, Ind] := IntToStr(Nb);
    end;
begin
  MasqueElementsV1();
  if TabBibliotheque = nil then
    exit;
  TabBibliotheque.RowCount := 9;
  TabBibliotheque.Cells[0, 0] := GetTexteLibelle('RULES-LAB_014');
  TabBibliotheque.Cells[1, 0] := GetTexteLibelle('RULES-LAB_021');
  if ValVersion = 'WFRP1' then
    begin
      // V1 : objets de ListObjetV1 comptes par Categorie (WEAPON, ARMOUR, TRANSPORT, le reste = equipement)
      NbVehicule := 0;
      Ind        := 0;
      LargLib    := 0;
      for PObjetV1 in ListObjetV1 do
        if ValeurLivreEgale(PObjetV1.Categorie, 'WEAPON') then Inc(LargLib)
        else if ValeurLivreEgale(PObjetV1.Categorie, 'ARMOUR') then Inc(Ind)
        else if ValeurLivreEgale(PObjetV1.Categorie, 'TRANSPORT') then Inc(NbVehicule);
      Ligne(1, GetTexteLibelle('RULES-LAB_063'), LargLib);
      Ligne(2, GetTexteLibelle('RULES-LAB_065'), Ind);
      Ligne(3, GetTexteLibelle('RULES-LAB_202'), ListObjetV1.Count - LargLib - Ind - NbVehicule);
      Ligne(4, GetTexteLibelle(ThemeAnimauxVehicules), NbVehicule);
    end
  else
    begin
      Ligne(1, GetTexteLibelle('RULES-LAB_063'), NbArme);
      Ligne(2, GetTexteLibelle('RULES-LAB_065'), NbArmure);
      // Animaux, montures, vehicules et bateaux (theme RULES-LAB_195) : ligne a part
      NbVehicule := 0;
      for PTrapping in ListTrapping do
        if EstThemeAnimauxVehicules(PTrapping.Theme) then
          Inc(NbVehicule);
      Ligne(3, GetTexteLibelle('RULES-LAB_202'), NbTrapping - NbVehicule);
      Ligne(4, GetTexteLibelle(ThemeAnimauxVehicules), NbVehicule);
    end;
  Ligne(5, GetTexteLibelle('RULES-LAB_083'), NbSort);
  Ligne(6, GetTexteLibelle('RULES-LAB_172'), ListCorruptionTable.Count);
  Ligne(7, GetTexteLibelle('RULES-LAB_281'), ListDisease.Count);
  Ligne(8, GetTexteLibelle('RULES-LAB_296'), ListAffliction.Count);

  // Colonnes et cadre ajustes aux donnees : libelle le plus long et total le plus large
  // (police grasse, comme dessinee par SelectionGrilleWarhammer) plus une marge.
  LargLib := 0;
  LargTot := 0;
  TabBibliotheque.Canvas.Font.Assign(TabBibliotheque.Font);
  TabBibliotheque.Canvas.Font.Style := [Graphics.fsBold];
  for Ind := 0 to TabBibliotheque.RowCount - 1 do
    begin
      LargCell := TabBibliotheque.Canvas.TextWidth(TabBibliotheque.Cells[0, Ind]);
      if LargCell > LargLib then LargLib := LargCell;
      LargCell := TabBibliotheque.Canvas.TextWidth(TabBibliotheque.Cells[1, Ind]);
      if LargCell > LargTot then LargTot := LargCell;
    end;
  TabBibliotheque.ColWidths[0] := LargLib + 20;
  TabBibliotheque.ColWidths[1] := LargTot + 20;
  TabBibliotheque.Width        := TabBibliotheque.ColWidths[0] + TabBibliotheque.ColWidths[1] + 4;
end;

// V1 : pas de talents (leurs effets sont dans les competences) ; le PDF n'existe pas encore
// pour la V1 et planterait a l'ouverture : a retirer d'ici au fur et a mesure. La bibliotheque (armes, armures...) n'est PAS masquee : une ligne a 0 ne s'ouvre pas.
procedure TMenu.MasqueElementsV1();
var
  Visible1: Boolean;
begin
  Visible1 := ValVersion <> 'WFRP1';
  ButtonTalent.Visible        := Visible1;
  BoutonTalent.Visible        := Visible1;
  TotLivreTalent.Visible      := Visible1;
  // V1 : la creation existe (WinCreation avec CreationV1)
  ButtonCreation.Visible      := True;
  // V1 : WinPersonnage ouvre une fiche V1 (liste des personnages et Modification rendues)
  ButtonModification.Visible  := True;
  // V1 : la feuille officielle du Core V1 (PdfPersonnageV1)
  ButtonPdf.Visible           := True;
  TabPersonnage.Visible       := True;
end;

// V1 : fenetre-catalogue simple des objets de ListObjetV1 d'un groupe (1 arme, 2 armure,
// 3 equipement, 4 transport) ; creee en code, sans fiche .lfm
procedure OuvreCatalogueObjetsV1(Groupe: Integer; const Titre: String);
var
  Fen:  TForm;
  Grid: TStringGrid;
  PObj: StructureObjetV1;
  Ligne, Gr: Integer;
begin
  Fen := TForm.Create(Application);
  Fen.Caption  := Titre;
  Fen.Position := poOwnerFormCenter;
  Fen.Width    := 760;
  Fen.Height   := 520;
  Grid := TStringGrid.Create(Fen);
  Grid.Parent  := Fen;
  Grid.Align   := alClient;
  Grid.Options := Grid.Options - [goEditing] + [goRowSelect];
  Grid.ColCount := 6;
  Grid.RowCount := 1;
  Grid.FixedCols := 0;
  Grid.Cells[0, 0] := GetTexteLibelle('RULES-LAB_014');
  Grid.Cells[1, 0] := 'Cat.';
  Grid.Cells[2, 0] := 'Prix';
  Grid.Cells[3, 0] := 'Enc.';
  Grid.Cells[4, 0] := 'Dispo.';
  Grid.Cells[5, 0] := 'Combat / PA';
  Grid.ColWidths[0] := 230;
  for Ligne := 1 to 5 do Grid.ColWidths[Ligne] := 100;
  for PObj in ListObjetV1 do
    begin
      if ValeurLivreEgale(PObj.Categorie, 'WEAPON') then Gr := 1
      else if ValeurLivreEgale(PObj.Categorie, 'ARMOUR') then Gr := 2
      else if ValeurLivreEgale(PObj.Categorie, 'TRANSPORT') then Gr := 4
      else Gr := 3;
      if Gr <> Groupe then Continue;
      Grid.RowCount := Grid.RowCount + 1;
      Ligne := Grid.RowCount - 1;
      Grid.Cells[0, Ligne] := PObj.Libelle;
      Grid.Cells[1, Ligne] := PObj.Categorie;
      Grid.Cells[2, Ligne] := PObj.Cout;
      Grid.Cells[3, Ligne] := PObj.Encombrement;
      Grid.Cells[4, Ligne] := PObj.Disponibilite;
      if PObj.PointsArmure <> '' then
        Grid.Cells[5, Ligne] := PObj.PointsArmure
      else
        Grid.Cells[5, Ligne] := LibelleModifsCombatV1(PObj.Combat);
    end;
  Fen.ShowModal;
  Fen.Free;
end;

procedure TMenu.TabBibliothequeDblClick(Sender: TObject);
begin
  // Categorie sans aucune fiche (V1 : pas encore saisie) : rien a ouvrir, la fenetre planterait
  // sur une grille vide.
  if StrToIntDef(TabBibliotheque.Cells[1, TabBibliotheque.Row], 0) = 0 then
    Exit;
  if (ValVersion = 'WFRP1') and (TabBibliotheque.Row in [1..4]) then
    begin
      OuvreCatalogueObjetsV1(TabBibliotheque.Row, TabBibliotheque.Cells[0, TabBibliotheque.Row]);
      Exit;
    end;
  case TabBibliotheque.Row of
    1: ButtonArmeClick(Sender);
    2: ButtonArmureClick(Sender);
    3: ButtonEquipementClick(Sender);
    4: begin
         ModeEquipements := meVehicules;
         WinEquipements  := TWinEquipements.Create(Application);
         ModeEquipements := meTout;
         WinEquipements.Position := poOwnerFormCenter;
         WinEquipements.Show;
       end;
    5: ButtonSortClick(Sender);
    6: begin
         WinMutationCat          := TWinMutationCatalogue.Create(Application);
         WinMutationCat.Position := poOwnerFormCenter;
         WinMutationCat.Show;
       end;
    7: begin
         WinDiseaseCat           := TWinDiseaseCatalogue.Create(Application);
         WinDiseaseCat.Position  := poOwnerFormCenter;
         WinDiseaseCat.Show;
       end;
    8: begin
         WinAfflictionCat           := TWinAfflictionCatalogue.Create(Application);
         WinAfflictionCat.Position  := poOwnerFormCenter;
         WinAfflictionCat.Show;
       end;
  end;
end;

procedure TMenu.TabLivreDblClick(Sender: TObject);
var
  BookPath: String;
begin
  if (TabLivre.Cells[ColLivreLib, TabLivre.Row] <> '') then
  begin
    // Si double-click sur la PREMIÈRE colonne (sélection) → toggle + charger
    if TabLivre.Col = ColLivreSel then
      begin
        if (TabLivre.Row > 1) then
          begin
          // Comportement actuel : toggle sélection
          if TabLivre.Cells[ColLivreSel, TabLivre.Row] <> ConstSelectionne then
            TabLivre.Cells[ColLivreSel, TabLivre.Row] := ConstSelectionne
          else
          begin
            TabLivre.Cells[ColLivreSel, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreRac, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreWor, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreCom, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreTal, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreArm, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreArU, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreEqu, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreSor, TabLivre.Row] := '';
            TabLivre.Cells[ColLivreTra, TabLivre.Row] := '';
          end;
          // Le rechargement effectif (ChargerLivre/ChargerPersonnages/SauveIni) est
          // différé au clic sur ButtonMAJLivres (CONTEXT.md, 26/09/2026) : avec la
          // taille prise par le corpus de livres, cocher/décocher un seul livre
          // relançait un reparsing complet de TOUS les livres sélectionnés à chaque
          // clic - devenu très lent. On se contente ici de signaler l'écart via le
          // bouton MAJ ; le traitement groupe les coches suivantes en un seul appel.
          RafraichirBoutonMAJLivres();
        end
      end
    // Si double-click sur une AUTRE colonne → ouvrir WinLivre avec le livre
    else
    begin
      // Construire le chemin : DATABASE\<version>\BOOK RULESBOOK.Xml - suit ConstCheminLivre
      // (Var depuis le 13/09/2026, CONTEXT.md §2.70) au lieu d'un littéral WFRP4 figé, sans
      // quoi le double-clic ouvrirait le mauvais livre une fois sur une autre version.
      BookPath := GetCurrentDir + ConstCheminLivre + TabLivre.Cells[ColLivreChe, TabLivre.Row];

      // WinLivre tourne dans son propre processus (--winlivre), chargement du livre compris
      LancerWinLivre(BookPath);
    end;
  end;
end;

// Recalcule, à partir des cases cochées de TabLivre, la même chaîne concaténée
// (AjouteAccolade par code de livre) que celle que ChargerLivre calcule dans
// LivresCharges - mais purement en lecture, sans rien recharger (26/09/2026).
function TMenu.LivresCochesActuellement(): String;
  var
    I: Integer;
  begin
    Result := '';
    for I := 1 to TabLivre.RowCount - 1 do
      if TabLivre.Cells[ColLivreSel, I] = ConstSelectionne then
        Result := Result + AjouteAccolade(TabLivre.Cells[ColLivreCod, I]);
  end;

// Affiche/masque ButtonMAJLivres selon que les cases cochées à l'écran (LivresCochesActuellement)
// correspondent ou non aux livres réellement chargés en mémoire (LivresChargesSnapshot, mis à
// jour uniquement par ButtonMAJLivresClick après un ChargerLivre effectif).
procedure TMenu.RafraichirBoutonMAJLivres();
  begin
    if not Assigned(ButtonMAJLivres) then Exit;
    // Caption reposée ici (pas seulement lors du GetTexteLibelle initial de PeuplerTabLivre,
    // qui a un timing fragile vis-à-vis du chargement d'INTERFACE.Xml et de l'Assign() posé
    // juste après la création) : garantit un texte à jour au moment précis où le bouton
    // redevient visible (Nono a signalé le bouton vide le 26/09/2026).
    ButtonMAJLivres.Caption := GetTexteLibelle('RULES-LAB_295');
    ButtonMAJLivres.Visible := (LivresCochesActuellement() <> LivresChargesSnapshot);
  end;

procedure TMenu.ButtonMAJLivresClick(Sender: TObject);
  begin
    ChargerLivre(true, '');
    ChargerPersonnages();
    SauveIni();
    // LivresCharges (variable globale, chargeconstantes.pas) n'est mise à jour par
    // ChargerLivre QUE si ForceMaj (ce qui est le cas ici) - mais au démarrage
    // (ChargerLivre(false,'') dans FormCreate) elle reste vide, d'où le recours à notre
    // propre calcul (LivresCochesActuellement) pour le snapshot, cohérent dans les deux cas.
    LivresChargesSnapshot := LivresCochesActuellement();
    RafraichirBoutonMAJLivres();
  end;

procedure TMenu.FormCreate(Sender: TObject);
  var
    Idx:                 Integer;

  // Creation des listes de la base de donnees (une par type de donnee).
  procedure CreerListes;
    begin
      // création de la base de donnée
      ListRace                     := TListRace.Create;
      ListEspece                   := TListEspece.Create;
      ListNation                   := TListNation.Create;
      ListRegle                    := TListRegle.Create;
      ListRegleSource              := TListRegle.Create;
      ListRegleMetier              := TListRegleMetier.Create;
      ListRegleEthnie              := TListRegleEthnie.Create;
      ListRegleFond                := TListRegleFond.Create;
      ListFondTirage               := TListFondTirage.Create;
      ListFondCompte               := TListFondCompte.Create;
      ListTalent                   := TListTalent.Create;
      ListCompetence               := TListCompetence.Create;
      ListMetierCompetence         := TListMetierCompetence.Create;
      ListMetier                   := TListMetier.Create;
      ListMetierNiveau             := TListMetierNiveau.Create;
      ListMetierAttribut           := TListMetierAttribut.Create;
      ListMetierAvance             := TListMetierAvance.Create;
      ListMetierArgent             := TListMetierArgent.Create;
      ListMetierSortie             := TListMetierSortie.Create;
      ListArtisanMetier            := TListArtisanMetier.Create;
      ListClasseV1                 := TListClasseV1.Create;
      ListTirageCompV1             := TListTirageCompV1.Create;
      ListAgeCompV1                := TListAgeCompV1.Create;
      ListGainMagieV1              := TListGainMagieV1.Create;
      ListApprentissageSortV1      := TListApprentissageSortV1.Create;
      ListHandicapV1               := TListHandicapV1.Create;
      ListTirageHandicapV1         := TListTirageHandicapV1.Create;
      ListAvancementPretreV1       := TListAvancementPretreV1.Create;
      ListFamilierV1               := TListFamilierV1.Create;
      ListCulteV1                  := TListCulteV1.Create;
      ListPriereCulteV1            := TListPriereCulteV1.Create;
      ListObjetV1                  := TListObjetV1.Create;
      ListMetierBase               := TListMetierBase.Create;
      ListMetierTalent             := TListMetierTalent.Create;
      ListeAttribut                := TListeAttribut.Create;
      ListRaceMetier               := TListRaceMetier.Create;
      ListRaceMetierSource         := TListRaceMetierSource.Create;
      ListRaceAttribut             := TListRaceAttribut.Create;
      ListRacePhysique             := TListRacePhysique.Create;
      ListRaceCouleur              := TListRaceCouleur.Create;
      ListRaceDetailV2             := TListRaceDetailV2.Create;
      ListTablePersonnelle         := TListTablePersonnelle.Create;
      ListRaceNom                  := TListRaceNom.Create;
      ListRaceNomModele            := TListRaceNomModele.Create;
      ListRaceNomRegle             := TListRaceNomRegle.Create;
      ListRaceCompetence           := TListRaceCompetence.Create;
      ListRaceTalent               := TListRaceTalent.Create;
      ListTalentCreation           := TListTalentCreation.Create;
      ListeAttributAugmentation    := TListeAttributAugmentation.Create;
      ListeCompetenceAugmentation  := TListeCompetenceAugmentation.Create;
      ListArme                     := TListArme.Create;
      ListArmure                   := TListArmure.Create;
      ListTrapping                 := TListTrapping.Create;
      ListArmureSimplifiee         := TListArmureSimplifiee.Create;
      ListArmureSimplifieeSource   := TListArmureSimplifiee.Create;
      ListOptionRegle               := TListOptionRegle.Create;
      ListArmeBonus                := TListArmeBonus.Create;
      ListMetierEquipement         := TListMetierEquipement.Create;
      ListArmureBonus              := TListArmureBonus.Create;
      ListSort                     := TListSort.Create;
      ListSortTalent               := TListSortTalent.Create;
      ListTrait                    := TListTrait.Create;
      ListTraitOption              := TListTraitOption.Create;
      ListCareerBonus              := TListCareerBonus.Create;
      ListCareerBonusNiveau        := TListCareerBonusNiveau.Create;
      ListCareerBonusSpecialRule    := TListCareerBonusSpecialRule.Create;
      ListCareerAdaptation         := TListCareerAdaptation.Create;
      ListCareerAdaptationLigne    := TListCareerAdaptationLigne.Create;
      ListFabrication              := TListFabrication.Create;
      ListSigneAstral              := TListSigneAstral.Create;
      ListSigneAstralSource        := TListSigneAstral.Create;
      ListSigneEffet               := TListSigneEffet.Create;
      ListRaceCreation             := TListRaceCreation.Create;
      ListMetierSousMetier         := TListMetierSousMetier.Create;
      ListMetierRaceChoixMetier    := TListMetierRaceChoixMetier.Create;
      ListTraduction               := TListTraduction.Create;
      ListLivre                    := TListLivre.Create;
      ListLivreTraduit             := TListLivreTraduit.Create;
      ListTexte                    := TListTexte.Create;
      ListRaceCorruptionCreation   := TListRaceCorruptionCreation.Create;
      ListCorruptionTable          := TListCorruptionTable.Create;
      ListCorruptionChance         := TListCorruptionChance.Create;
      ListDisease                  := TListDisease.Create;
      ListAffliction               := TListAffliction.Create;
      ListClassEquipement          := TListClassEquipement.Create;
      ListTalentEffet               := TListTalentEffet.Create;
      ListTalentCompetenceModif    := TListTalentCompetenceModif.Create;
      ListRaceOpinion              := TListRaceOpinion.Create;
      ListCorruptionCompetenceAttributModif := TListCorruptionCompetenceAttributModif.Create;
      ListCorruptionTalent         := TListCorruptionTalent.Create;
      ListCorruptionEquipement     := TListCorruptionEquipement.Create;
      ListArmureBonusTalent        := TListArmureBonusTalent.Create;
      ListArmeBonusTalent          := TListArmeBonusTalent.Create;
      ListAfflictionCompetenceAttributModif := TListAfflictionCompetenceAttributModif.Create;
    end;

  // Import des livres du dossier de la version, RULESBOOK en premier.
  procedure ImporterLivres;
    var
      SearchResult:        TSearchRec;
      DirectoryPath:       string;
      ListeFichiersLivres: TStringList;
      RulesBookIndex:      Integer;
      Idx:                 Integer;
    begin
      // chercher les livres
      // Le RULESBOOK doit être chargé en premier : d'autres livres (ex. BOOK
      // LUSTRIA) peuvent ajouter des <Specie> qui référencent des races déjà
      // définies dans le RULESBOOK (voir xmlexportimport.pas / ChercheRace) ;
      // il faut donc que les vraies données du RULESBOOK soient en place avant
      // qu'un éventuel stub de supplément ne soit traité, quel que soit l'ordre
      // renvoyé par FindFirst/FindNext.
      directoryPath        := GetCurrentDir + ConstCheminLivre;
      ListeFichiersLivres  := TStringList.Create;
      try
        if FindFirst(directoryPath + '*.xml', faAnyFile, searchResult) = 0 then
        begin
          repeat
            ListeFichiersLivres.Add(ExtractStringBefore(searchResult.Name, '.'));
          until FindNext(searchResult) <> 0;
          FindClose(searchResult);
        end;

        RulesBookIndex := -1;
        for Idx := 0 to ListeFichiersLivres.Count - 1 do
          if XmlLivre(ListeFichiersLivres[Idx]) = ConstRulesBook then
            begin
              RulesBookIndex := Idx;
              break;
            end;

        if RulesBookIndex >= 0 then
          begin
            XmlImport(ListeFichiersLivres[RulesBookIndex], true);
            ListeFichiersLivres.Delete(RulesBookIndex);
          end;

        for Idx := 0 to ListeFichiersLivres.Count - 1 do
          XmlImport(ListeFichiersLivres[Idx], true);
      finally
        ListeFichiersLivres.Free;
      end;
    end;

  // Import des libelles d interface (deux fichiers a emplacement fixe).
  procedure ImporterInterface;
    var
      FichiersInterface:   TStringList;
      Idx:                 Integer;
    begin
      // Libellés/messages d'interface (RULES-LAB_*/RULES-MESS_*) : vivent dans
      // INTERFACE.Xml/INTERFACE_FRANCAIS.Xml, directement sous DATABASE\ (pas sous
      // WFRP4\/WFRP5\) pour ne pas être dupliqués entre éditions - décision de Nono le
      // 13/09/2026 (CONTEXT.md §2.70). Pas de scan : deux fichiers à emplacement fixe,
      // chargés explicitement ici (anglais d'abord, comme pour le RULESBOOK) via le
      // chemin complet plutôt que ConstCheminLivre.
      FichiersInterface := TStringList.Create;
      try
        ListeFichiersInterface(FichiersInterface);
        for Idx := 0 to FichiersInterface.Count - 1 do
          XmlImport(FichiersInterface[Idx], true,
                    GetCurrentDir + ConstCheminInterface + FichiersInterface[Idx] + '.xml');
      finally
        FichiersInterface.Free;
      end;
    end;

  // Libelles des types d equipement.
  procedure InitTypesEquipement;
    begin
      TypeEquipCC         := GetTexteLibelle('RULES-LAB_061');
      TypeEquipCT         := GetTexteLibelle('RULES-LAB_062');
      TypeEquipMU         := GetTexteLibelle('RULES-LAB_060');
      TypeEquipMetierArme := TypeEquipCC+','+TypeEquipCT+','+TypeEquipMU;
      TypeEquipWe         := GetTexteLibelle('RULES-LAB_063');
      TypeEquipDI         := GetTexteLibelle('RULES-LAB_064');
      TypeEquipAN         := GetTexteLibelle('RULES-LAB_252');
      TypeEquipAR         := GetTexteLibelle('RULES-LAB_065');
      TypeEquipARS        := GetTexteLibelle('RULES-LAB_150');
    end;

  // Mise en forme des tableaux Livre, Bibliotheque et Personnage.
  procedure InitGrilles;
    begin
      TabLivre.Clear;
      // mise en forme du tableau de création du Livre
      TabLivre.ColCount         := 1;
      TabLivre.RowCount         := 1;
      TabLivre.ColWidths[0]     := 20;
      // Grille des categories secondaires (creee ici, sous les quatre boutons principaux)
      if TabBibliotheque = nil then
        begin
          TabBibliotheque              := TStringGrid.Create(Self);
          TabBibliotheque.Name         := 'TabBibliotheque';  // pour les scripts d'ecran
          TabBibliotheque.Parent       := Self;
          TabBibliotheque.SetBounds(ButtonRace.Left, 564, ButtonRace.Width + 160,
                                    Button1.Top + Button1.Height - 564 - 16);
          TabBibliotheque.Anchors      := [akLeft];   // position et hauteur recalculees dans AjustePositionFenetre
          TabBibliotheque.ColCount     := 2;
          TabBibliotheque.FixedCols    := 0;
          TabBibliotheque.FixedRows    := 1;
          TabBibliotheque.ColWidths[0] := TabBibliotheque.Width - 90;
          TabBibliotheque.ColWidths[1] := 60;
          TabBibliotheque.Options      := TabBibliotheque.Options - [goRangeSelect] + [goRowSelect];
          TabBibliotheque.ScrollBars   := ssAutoVertical;
          TabBibliotheque.OnDblClick   := @TabBibliothequeDblClick;
        end;
      // Ligne selectionnee identique dans les trois tableaux du menu
      SelectionGrilleWarhammer(TabLivre);
      SelectionGrilleWarhammer(TabPersonnage);
      SelectionGrilleWarhammer(TabBibliotheque);
      MasqueElementsV1();
      ColLivreSel := GridAjouteColonne(TabLivre, 'S', 20, taCenter);
      ColLivreLib := GridAjouteColonne(TabLivre, GetTexteLibelle('RULES-LAB_014'), 230);
      ColLivreCod := GridAjouteColonne(TabLivre, '');
      ColLivreOrd := GridAjouteColonne(TabLivre, '');
      ColLivreRac := GridAjouteColonne(TabLivre, 'R', 30);
      ColLivreWor := GridAjouteColonne(TabLivre, 'W', 30);
      ColLivreO_F := GridAjouteColonne(TabLivre, 'B', 30);
      ColLivreAbr := GridAjouteColonne(TabLivre, 'A', 30);
      ColLivreCom := GridAjouteColonne(TabLivre, 'C', 30);
      ColLivreTal := GridAjouteColonne(TabLivre, 'T', 30);
      ColLivreArm := GridAjouteColonne(TabLivre, 'Wp', 30);
      ColLivreArU := GridAjouteColonne(TabLivre, 'Ar', 30);
      ColLivreEqu := GridAjouteColonne(TabLivre, 'E', 30);
      ColLivreSor := GridAjouteColonne(TabLivre, 'Sp', 30);
      ColLivreTra := GridAjouteColonne(TabLivre, 'Tr', 30);
      ColLivreTrd := GridAjouteColonne(TabLivre, GetTexteLibelle('RULES-LAB_679'), 50, taRightJustify);
      ColLivreChe := GridAjouteColonne(TabLivre, '');

      // mise en forme du tableau des personnages
      TabPersonnage.ColCount         := 1;
      TabPersonnage.RowCount         := 1;
      TabPersonnage.ColWidths[0]     := 20;
      ColPersoNom  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_014'), 100);
      ColPersoWor  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_006'), 150);
      ColPersoRac  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_042'), 200);
      ColPersoNiv  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_019'), 30, Tacenter);
      ColPersoTXp  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_035'), 30, taRightJustify);
      ColPersoCXp  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_041'), 30, taRightJustify);
      ColPersoLOb  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_128'), 150);
      ColPersoLNe  := GridAjouteColonne(TabPersonnage, GetTexteLibelle('RULES-LAB_136'), 150);
    end;

  // Libelles de l interface et des arbres.
  procedure InitLibelles;
    begin
      ConstArbreAttribut          := GetTexteLibelle('RULES-LAB_008');
      ConstArbreCompetence        := GetTexteLibelle('RULES-LAB_009');
      ConstArbreTalent            := GetTexteLibelle('RULES-LAB_007');
      ConstArbreAuChoix           := GetTexteLibelle('RULES-LAB_010');
      ConstArbreEnsemble          := GetTexteLibelle('RULES-LAB_186');
      ConstArbreMetierPossible    := GetTexteLibelle('RULES-LAB_011');
      ConstArbreRacePossible      := GetTexteLibelle('RULES-LAB_012');
      ConstArbreEquipement        := GetTexteLibelle('RULES-LAB_013');
      ConstArbreCorruption        := GetTexteLibelle('RULES-LAB_156');

      Label1.Caption              := GetTexteLibelle('RULES-LAB_082');
      ButtonCompetence.Caption    := GetTexteLibelle('RULES-LAB_009');
      ButtonTalent.Caption        := GetTexteLibelle('RULES-LAB_007');
      ButtonMetier.Caption        := GetTexteLibelle('RULES-LAB_006');
      ButtonRace.Caption          := GetTexteLibelle('RULES-LAB_042');

      Label2.Caption              := GetTexteLibelle('RULES-LAB_081');
      ButtonCreation.Caption      := GetTexteLibelle('RULES-LAB_079');
      ButtonModification.Caption  := GetTexteLibelle('RULES-LAB_080');

      Label3.Caption              := GetTexteLibelle('RULES-LAB_128');

      ButtonCreationLivre.Caption := GetTexteLibelle('RULES-LAB_154');
      ButtonOuvrirLivre.Caption   := GetTexteLibelle('RULES-LAB_155');

      Label4.Caption              := GetTexteLibelle('RULES-LAB_183');
      Label5.Caption              := GetTexteLibelle('RULES-LAB_184');
      ButtonOptionRegle.Caption   := GetTexteLibelle('RULES-LAB_277');
      PoserBoutonTestsAuto();
    end;

  // Largeurs de colonnes, largeurs minimales et references d ancrage de la fenetre.
  procedure InitDimensions;
    var
      LargeurMinTabLivre:  Integer;
    begin
      AdjustGridColumnsWidth(TabLivre, Self.Height, true, true, True, 0, 10);
      AdjustGridColumnsWidth(TabPersonnage, Self.Height, true, true, True, 0, 10);

      // TabLivre.Width réel (colonnes sommées par AdjustGridColumnsWidth ci-dessus) peut
      // être plus étroit que les 4 boutons Livre fixes au-dessus (ButtonExportLivre/
      // OuvrirLivre/DisclaimerLivre/CreationLivre, Left=224 dans le .lfm - jamais reancrés,
      // restent dans la colonne TabLivre) : leur bord droit dépasserait alors celui de
      // TabLivre, chevauchant Button3/TabPersonnage dès que TabLivre est à cette largeur -
      // cause réelle du chevauchement signalé par Nono le 15/09/2026 (pas une histoire de
      // redimensionnement : le plancher de 300 posé plus tôt dans le .lfm était trop
      // petit, arbitraire, jamais recalé sur ces boutons). Calculé plutôt que recopié en
      // dur, pour rester juste si le .lfm bouge.
      LargeurMinTabLivre := ButtonExportLivre.Left + ButtonExportLivre.Width;
      if ButtonOuvrirLivre.Left + ButtonOuvrirLivre.Width > LargeurMinTabLivre then
        LargeurMinTabLivre := ButtonOuvrirLivre.Left + ButtonOuvrirLivre.Width;
      if ButtonDisclaimerLivre.Left + ButtonDisclaimerLivre.Width > LargeurMinTabLivre then
        LargeurMinTabLivre := ButtonDisclaimerLivre.Left + ButtonDisclaimerLivre.Width;
      if ButtonCreationLivre.Left + ButtonCreationLivre.Width > LargeurMinTabLivre then
        LargeurMinTabLivre := ButtonCreationLivre.Left + ButtonCreationLivre.Width;
      TabLivre.Constraints.MinWidth := LargeurMinTabLivre - TabLivre.Left;

      // Même piège côté TabPersonnage : ButtonPdf (seul bouton de cette colonne à ne pas
      // démarrer au bord gauche de la table, +224 dans le .lfm) déborderait à droite si
      // TabPersonnage devenait plus étroite que ButtonPdf.Left-TabPersonnage.Left+
      // ButtonPdf.Width (Nono, 15/09/2026 - même correctif que TabLivre ci-dessus).
      TabPersonnage.Constraints.MinWidth :=
        (ButtonPdf.Left - TabPersonnage.Left) + ButtonPdf.Width;

      // Ancrage de la fenêtre principale (A FAIRE.txt, demande Nono 13/09/2026) : largeur
      // de référence capturée ICI, juste après les AdjustGridColumnsWidth ci-dessus - la
      // tentative précédente (référence prise au premier OnResize réel, pour parer une
      // hypothétique mise à l'échelle DPI tardive) n'a pas résolu le chevauchement observé
      // par Nono en agrandissant et ajoutait de la complexité sans bénéfice démontré :
      // retour à une capture simple et déterministe. AjustePositionFenetre borne aussi
      // désormais TabLivre/TabPersonnage à ne jamais redescendre sous cette référence
      // (Constraints.MinWidth posée en filet de sécurité côté LCL en plus, sur les deux
      // grilles dans le .lfm).
      FenetreInitialisee       := true;
      LargeurFenetreBase       := Self.ClientWidth;
      LargeurTabLivreBase      := TabLivre.Width;
      LargeurTabPersonnageBase := TabPersonnage.Width;
    end;

  // Polices et fichier image temporaire.
  procedure InitPolices;
    begin
    // Charger Les polices
     gTTFontCache.SearchPath.Add('C:\Windows\Fonts');
     gTTFontCache.SearchPath.Add(GetCurrentDir + ConstCheminImagePolice);
     gTTFontCache.BuildFontCache;

     ImageTmp := GetCurrentDir+'TMP.PNG';
    end;

  // Modes sans fenetre (--pdf, --reecrit, --dump, --retrait, --export) et --winlivre.
  procedure ModesLot;
    var
      TowBase:  String;
      TowPerso: StructurePersonnage;
      TowDump:  TStringList;
    begin
     // Mode lot : WarhammerHelp.exe --pdf <dossier personnage> [...] ecrit les PDF puis quitte.
     if (ParamCount >= 1) and (ParamStr(1) = '--pdfmetier') then
       begin
         LotPdfMetiersRaces();
         Halt(0);
       end;
     if (ParamCount >= 2) and (ParamStr(1) = '--pdf') then
       begin
         LotPdfPersonnages();
         Halt(0);
       end;
     // WarhammerHelp.exe --dump <dossier de sortie> <dossier personnage> [...]
     // WarhammerHelp.exe --reecrit <dossier de sortie> <dossier personnage> [...] : charge chaque fiche
     // puis la reecrit (PersonnageXmlCreation) dans <sortie>\<dossier>.xml. Sert a comparer avant/apres
     // une modification de la lecture ou de l ecriture des fiches (diff des XML).
     if (ParamCount >= 3) and (ParamStr(1) = '--reecrit') then
       begin
         LotReecritPersonnages();
         Halt(0);
       end;
     // WarhammerHelp.exe --towcherche <fichier de sortie> : controle (lecture seule) de ce que le moteur commun
     // (ChercheRace / Metier / Talent / Competence / Sort / Attribut) sait retrouver pour des codes du livre TOW.
     if (ParamCount >= 2) and (ParamStr(1) = '--towcherche') then
       begin
         TowDump := TStringList.Create;
         TowDump.Add('RACE      RULES-SPECIE_DWARF       -> [' + ChercheRace('RULES-SPECIE_DWARF').Libelle + '] livre=[' + ChercheRace('RULES-SPECIE_DWARF').Livre + ']');
         TowDump.Add('METIER    RULES-WORK_APOTHECARY  -> [' + ChercheMetier('RULES-WORK_APOTHECARY').Libelle + '] livre=[' + ChercheMetier('RULES-WORK_APOTHECARY').Livre + ']');
         TowDump.Add('TALENT    RULES-T_ACROBATIC   -> [' + ChercheTalent('RULES-T_ACROBATIC').Libelle + '] livre=[' + ChercheTalent('RULES-T_ACROBATIC').Livre + ']');
         TowDump.Add('COMP      RULES-COMP_MELEE         -> [' + ChercheCompetence('RULES-COMP_MELEE').Libelle + '] livre=[' + ChercheCompetence('RULES-COMP_MELEE').Livre + ']');
         TowDump.Add('SORT      RULES-SPELL_CURSE_OF_COWARDLY_FLIGHT -> [' + ChercheSort('RULES-SPELL_CURSE_OF_COWARDLY_FLIGHT').Libelle + '] livre=[' + ChercheSort('RULES-SPELL_CURSE_OF_COWARDLY_FLIGHT').Livre + ']');
         TowDump.Add('ATTRIBUT  RULES-ATTR_WS            -> [' + ChercheAttribut('RULES-ATTR_WS').Libelle + '] livre=[' + ChercheAttribut('RULES-ATTR_WS').Livre + ']');
         TowDump.SaveToFile(ParamStr(2));
         TowDump.Free;
         Halt(0);
       end;
     // WarhammerHelp.exe --tow <dossier de sortie> <fichier xml TOW> : lit un personnage The Old World,
     // ecrit <nom>.txt (dump) et <nom>.reecrit.xml, puis relit le XML reecrit et ecrit <nom>.relu.txt.
     // Les deux .txt doivent etre identiques (aller-retour sans perte, etape 3 du plan TOW).
     if (ParamCount >= 3) and (ParamStr(1) = '--tow') then
       begin
         ForceDirectories(ParamStr(2));
         TowBase := IncludeTrailingPathDelimiter(ParamStr(2)) + ChangeFileExt(ExtractFileName(ParamStr(3)), '');
         TowPerso := PersonnageXmlChargement(ParamStr(3));
         TowDump := PersonnageTowDump(TowPerso);
         TowDump.SaveToFile(TowBase + '.txt');
         TowDump.Free;
         PersonnageXmlCreation(TowPerso, TowPerso.XpTotal, TowPerso.XpActuel, TowBase + '.reecrit.xml', TowPerso.NomPersonnage);
         TowPerso := PersonnageXmlChargement(TowBase + '.reecrit.xml');
         TowDump := PersonnageTowDump(TowPerso);
         TowDump.SaveToFile(TowBase + '.relu.txt');
         TowDump.Free;
         Halt(0);
       end;
     if (ParamCount >= 3) and (ParamStr(1) = '--dump') then
       begin
         LotDumpPersonnages();
         Halt(0);
       end;
     // WarhammerHelp.exe --dumpecran <dossier sortie> <perso>... : contenu de WinPersonnage (fenetre
     // creee sans etre affichee) dans <sortie>\<perso>.ecran.txt, a comparer au --dump et au PDF.
     if (ParamCount >= 3) and (ParamStr(1) = '--dumpecran') then
       begin
         LotDumpEcran();
         Halt(0);
       end;
     // WarhammerHelp.exe --dumppdf <dossier sortie> <perso>... : textes ecrits dans le PDF (avec leur
     // position) dans <sortie>\<perso>.pdf.txt, a comparer au --dump et au --dumpecran.
     if (ParamCount >= 3) and (ParamStr(1) = '--dumppdf') then
       begin
         LotDumpPdf();
         Halt(0);
       end;
     // WarhammerHelp.exe --naissance <code ethnie> [nombre] : tire les details V2 (naissance, signe, astre)
     // de l ethnie et ecrit les resultats dans NAISSANCE.txt. Sert a verifier une table Birthplace.
     if (ParamCount >= 2) and (ParamStr(1) = '--naissance') then
       begin
         LotNaissance();
         Halt(0);
       end;
     // WarhammerHelp.exe --familier <code ethnie> [nombre] : tire la forme et les particularites d un familier
     // cree (tables 7-1, 7-3, 7-2) et ecrit FAMILIER.txt, une ligne par tirage avec les effets appliques.
     if (ParamCount >= 2) and (ParamStr(1) = '--familier') then
       begin
         LotFamilier();
         Halt(0);
       end;
     // WarhammerHelp.exe --creer <code ethnie> <code carriere> <nom> : cree un personnage avec WinCreation
     // (fenetre non affichee, boutons Hasard), l'enregistre sous <nom> et ecrit le deroulement dans CREER.txt.
     if (ParamCount >= 4) and (ParamStr(1) = '--creer') then
       begin
         LotCreer();
         Halt(0);
       end;
     // WarhammerHelp.exe --testcreation <cas.txt> <sortie.txt> : executes sans fenetre les cas de test des
     // regles de WinCreation (une ligne = un cas) et ecrit OK / ECHEC par cas. Voir TRAVAIL\tester_creation.py.
     if (ParamCount >= 3) and (ParamStr(1) = '--testcreation') then
       begin
         LotTestCreation();
         Halt(0);
       end;
     // WarhammerHelp.exe --retrait <code livre> : retire le livre des listes, le reimporte, puis
     // exporte tous les livres (a comparer a un --export simple). Trace dans LOT_RETRAIT.txt.
     if (ParamCount >= 2) and (ParamStr(1) = '--retrait') then
       begin
         LotRetraitLivre();
         ButtonXmlClick(nil);
         Halt(0);
       end;
     // WarhammerHelp.exe --export : meme export que le bouton XML (tous les livres charges
     // vers DATABASE_EXPORT\), puis quitte. Sert au controle d aller-retour.
     if (ParamCount >= 1) and (ParamStr(1) = '--export') then
       begin
         ButtonXmlClick(nil);
         Halt(0);
       end;
     // WarhammerHelp.exe --winlivretest <livre> <sortie.xml> <arbre.txt> : charge le livre dans WinLivre,
     // valide chaque fiche suivie, ecrit le XML issu de la fenetre et la liste des noeuds, puis quitte.
     if (ParamCount >= 4) and (ParamStr(1) = '--winlivretest') then
       begin
         try
           FenLivre := TWinLivres.Create(Application);
           FenLivre.ChargerXMLFile(ParamStr(2));
           // 5e parametre « edit » : test d'edition (Page saisie a 999 dans chaque fiche, controlee dans le XML ecrit)
           FenLivre.TesterAllerRetour(ParamStr(3), ParamStr(4), (ParamCount >= 5) and (ParamStr(5) = 'edit'));
         except
           on E: Exception do
           begin
             // en test, une exception va dans error.log (avec la pile d appels) au lieu d ouvrir une boite
             JournaliserException(E);
             Halt(2);
           end;
         end;
         Halt(0);
       end;
     // WarhammerHelp.exe --dumpwinlivre <livre> <sortie.txt> [N] : charge le livre dans WinLivre, selectionne N noeuds
     // par type (0 ou absent = tous) et ecrit en texte ce que chaque fiche afficherait a l ecran, puis quitte.
     if (ParamCount >= 3) and (ParamStr(1) = '--dumpwinlivre') then
       begin
         try
           FenLivre := TWinLivres.Create(Application);
           FenLivre.ChargerXMLFile(ParamStr(2));
           if ParamCount >= 4 then FenLivre.DumpEcran(ParamStr(3), StrToIntDef(ParamStr(4), 0))
           else FenLivre.DumpEcran(ParamStr(3), 0);
         except
           on E: Exception do
           begin
             JournaliserException(E);
             Halt(2);
           end;
         end;
         Halt(0);
       end;
     // WarhammerHelp.exe --winlivre [chemin du livre] : second processus ou WinLivre est seul
     // visible (menu cache). Ses listes sont propres au processus : l Update de WinLivre ne
     // touche jamais celles du jeu principal (CONTEXT.md 2.106).
     // WarhammerHelp.exe --script <fichier> : rejoue des clics / saisies dans les vraies fenetres
     // (voir scriptecran.pas), ecrit <fichier>.sortie.txt puis quitte. Menu cache.
     if (ParamCount >= 2) and (ParamStr(1) = '--script') then
       begin
         Application.ShowMainForm := False;
         LancerScript(ParamStr(2));
       end;
     if (ParamCount >= 1) and (ParamStr(1) = '--winlivre') then
       begin
         if ParamCount >= 2 then
           OuvrirWinLivreSeul(ParamStr(2))
         else
           OuvrirWinLivreSeul('');
       end;
    end;

  begin
       Randomize;
       // Tests de non-regression (--creer) : WH_GRAINE fixe le hasard pour que deux executions donnent le meme personnage
       if GetEnvironmentVariable('WH_GRAINE') <> '' then
         RandSeed := StrToIntDef(GetEnvironmentVariable('WH_GRAINE'), 1);

       // ButtonOptionRegle (regles optionnelles, A FAIRE.txt "TOGGLE .INI PAR LIVRE",
       // CONTEXT.md 2.89, 22/09/2026) et ButtonMAJLivres (26/09/2026) sont désormais posés
       // dans le .lfm (TBCButton, même style que les boutons Livre) plutôt que créés ici en
       // code - Nono a demandé à pouvoir les repositionner depuis l'éditeur de formulaire
       // Lazarus, ce qu'un composant créé dynamiquement (l'ancienne version, TButton puis
       // TBCButton+Assign) ne permet pas. Leur Caption reste posé en code (GetTexteLibelle,
       // PeuplerTabLivre/RafraichirBoutonMAJLivres) car il dépend de la langue d'interface,
       // pas figé au design.

       // Sélection de livres cochés, une par édition (Nono, 13/09/2026, CONTEXT.md §2.70) -
       // créée AVANT ChargeIni() qui la peuple depuis le .INI.
       ListeLivreParVersion := TStringList.Create;
       ListeOptionDesactiveeParLivre := TStringList.Create;

       // Charger Les données
       ChargeIni();

       // Images du Menu : APRES ChargeIni, car l'option DEFAULTLICENSELESS du .INI
       // decide si PICTURES est ignore (CheminImage), et doit etre connue avant le chargement.
       ChargerImage();

       // Sélecteur de version WFRP4/WFRP5 (CONTEXT.md §2.70) : appelée ICI, avant tout
       // chargement de livre, pour que ValVersion soit validée contre les répertoires
       // DATABASE\* réellement présents au disque AVANT de calculer ConstCheminLivre/
       // ConstCheminPersonnage juste en dessous - sans quoi le programme rouvrait toujours
       // WFRP4\ au démarrage même si le .INI mémorisait WFRP5 (symptôme relevé par Nono :
       // la combo affichait bien "WFRP5" mais les données chargées restaient celles de
       // WFRP4). ChargerListeVersions ne dépend d'aucune liste créée plus bas : elle scanne
       // DATABASE\ directement via XmlLivreBalise, indépendamment de ConstCheminLivre.
       ChargerListeVersions();
       ConstCheminLivre       := '\DATABASE\' + ValVersion + '\';
       ConstCheminPersonnage  := '\SAVED_CARACTERS\' + ValVersion + '\';
       ForceDirectories(GetCurrentDir + ConstCheminPersonnage);  // absent dans le zip de release
       // Chemins d'images races/métiers/sorts alignés sur la version comme ConstCheminLivre
       // ci-dessus (Nono, 14/09/2026, CONTEXT.md §2.70) - ne sont plus figés sur WFRP4\ (l'un
       // d'eux, ConstCheminImageMetier, était même figé sur WFRP5\ à tort, indépendamment de
       // ValVersion). Un dossier de version pas encore garni (WFRP5\PICTURES\SPECIE\ n'existe
       // pas encore au disque) se comporte comme aujourd'hui : FileExists échoue dans
       // CheminRaceImage/CheminMetierImage/CheminSortImage, aucune image trouvée.
       ConstCheminImageRace   := '\DATABASE\' + ValVersion + '\PICTURES\SPECIE\';
       ConstCheminImageMetier := '\DATABASE\' + ValVersion + '\PICTURES\CLASS\';
       ConstCheminImageSort   := '\DATABASE\' + ValVersion + '\PICTURES\SPELL\';
       // Icones de niveau, même correctif (Nono, 14/09/2026, CONTEXT.md §2.70) - images
       // WFRP5 ajoutées par Nono sous PICTURES\WFRP5\NIV\.
       ConstCheminImageNiveau       := '\PICTURES\' + ValVersion + '\NIV\';
       ConstCheminImageNiveauRacine := '\PICTURES\' + ValVersion + '\';
       // Logo et bandeaux selon la version resolue (premier ChargerImage : version pas encore connue)
       ChargerImage();
       // Sélection de livres cochés de CETTE édition (résolue depuis ListeLivreParVersion,
       // peuplée par ChargeIni - CONTEXT.md §2.70) - lue par PeuplerTabLivre plus bas.
       ListeLivre             := ListeLivreParVersion.Values[ValVersion];

       CreerListes;

       // chercher les livres
       ImporterLivres;

       ImporterInterface;

       InitTypesEquipement;

       InitGrilles;

       ComboBoxLangue.Style    := csDropDownList;
       // chercher les livres
       PeuplerTabLivre();

       // sélecteur de langue de l'interface, décorrélé de la langue des livres (CONTEXT.md §2.70)
       ChargerListeLanguesInterface();

       // charger les livres
       ChargerLivre(false, '');
       LivresChargesSnapshot := LivresCochesActuellement();
       RafraichirBoutonMAJLivres();

       // Retraduire les libellés d'interface selon ValLangueInterface : ChargerLivre vient
       // d'appliquer Traduit(ValLangue,'') à TOUS les livres, y compris INTERFACE - la langue
       // d'interface doit rester décorrélée de la langue des livres (CONTEXT.md §2.70).
       Traduit(ValLangueInterface, ConstInterfaceBook);

       // PeuplerTabLivre (plus haut) a posé les noms de livres AVANT cette traduction : sans
       // ce rafraîchissement, le Rulebook s'affichait "Rules Book" au démarrage en français.
       for Idx := 1 to TabLivre.RowCount - 1 do
         if TabLivre.Cells[ColLivreCod, Idx] <> '' then
           LibelleLivreLigne(Idx);

       // chargesr les personnages
       ChargerPersonnages();

       // liste des groupes de métiers
       // Corrige le 15/09/2026 (Nono, WinFiltre) : ces codes etaient nus (sans prefixe
       // RULES-), contrairement a PMetier.LibelleGroupe (xmlexportimport.pas:2055, lu depuis
       // <Class>"RULES-CLASS_*"</Class>). Deux consequences silencieuses, meme cause -
       // VerifieRecherche (chargeconstantes.pas:1247) exige LivreRecherche = LivreValeur : un
       // code nu ne peut jamais matcher un code prefixe, ni dans un sens ni dans l'autre :
       // 1. GetTexteLibelle(PGroupe) dans WinFiltre.ChargeGroupe (winfiltre.pas:225) ne
       //    trouvait jamais l'entree ListTexte (deplacee dans INTERFACE.Xml le 15/09/2026,
       //    mais deja prefixee RULES- avant ce deplacement) - repli sur le code brut affiche.
       // 2. VerifieFiltre(PMetier.LibelleGroupe, filtreGroupe) dans WinMetier
       //    (winmetier.pas:204) compare par sous-chaine (chargeconstantes.pas:1097) : un
       //    filtre construit sans prefixe ("{CLASS_ACAD}...") ne contient jamais
       //    "{RULES-CLASS_WARR}" - un choix PARTIEL de classes ne matchait donc plus aucun
       //    metier (choix complet = filtre vide = pas de filtrage, d'ou le symptome
       //    invisible tant que toutes les classes restent cochees).
       ListGroup += ['RULES-CLASS_ACAD'];
       ListGroup += ['RULES-CLASS_BURG'];
       ListGroup += ['RULES-CLASS_COUR'];
       ListGroup += ['RULES-CLASS_PEAS'];
       ListGroup += ['RULES-CLASS_RANG'];
       ListGroup += ['RULES-CLASS_RIVE'];
       ListGroup += ['RULES-CLASS_ROGU'];
       ListGroup += ['RULES-CLASS_WARR'];

       // Appeler la procédure SetGlobalFonts au démarrage du formulaire
       MiseEnFormeDesChamp(self);
       InitLibelles;
       InitDimensions;
       InitPolices;
       ModesLot;
  end;

function CreateMutexW(Attr: Pointer; Initial: LongBool; Nom: PWideChar): PtrUInt; stdcall; external 'kernel32.dll' name 'CreateMutexW';
function ErreurSysteme(): LongWord; stdcall; external 'kernel32.dll' name 'GetLastError';

// Un seul WinLivre par livre : mutex nomme d apres le chemin, libere par Windows a la fin du
// processus (meme apres un plantage). Renvoie faux si un autre processus tient deja ce livre.
var
  VerrousLivres: array of PtrUInt;

function VerrouLivre(const Chemin: String): Boolean;
  const
    ERREUR_DEJA_EXISTANT = 183;
  var
    Nom: UnicodeString;
    Poignee: PtrUInt;
  begin
    Nom := UnicodeString('Local\WarhammerHelp_WinLivre_' +
           StringReplace(StringReplace(UpperCase(ExpandFileName(Chemin)), '\', '_', [rfReplaceAll]),
                         ':', '_', [rfReplaceAll]));
    Poignee := CreateMutexW(nil, True, PWideChar(Nom));
    Result := (Poignee <> 0) and (ErreurSysteme() <> ERREUR_DEJA_EXISTANT);
    if Result then
      begin
        SetLength(VerrousLivres, Length(VerrousLivres) + 1);
        VerrousLivres[High(VerrousLivres)] := Poignee;
      end;
  end;

procedure TMenu.LancerWinLivre(const Chemin: String);
  // Lance un second WarhammerHelp en mode --winlivre (WinLivre seul, listes propres). Le jeu
  // principal ne voit les changements qu a son prochain demarrage.
  var
    Proc: TProcess;
  begin
    Proc := TProcess.Create(nil);
    try
      Proc.Executable       := Application.ExeName;
      Proc.CurrentDirectory := GetCurrentDir;
      Proc.Parameters.Add('--winlivre');
      if Chemin <> '' then
        Proc.Parameters.Add(Chemin);
      Proc.Options := [];
      Proc.Execute;
    finally
      Proc.Free;
    end;
  end;

procedure TMenu.OuvrirWinLivreSeul(const Chemin: String);
  begin
    if (Chemin <> '') and not VerrouLivre(Chemin) then
      begin
        MessageDlg(GetTexteLibelle('RULES-LAB_505'), mtInformation, [mbOK], 0);
        Halt(0);
      end;
    Application.ShowMainForm := False;
    FenLivre := TWinLivres.Create(Application);
    FenLivre.Position := poScreenCenter;
    FenLivre.AddHandlerClose(@WinLivreFerme);
    if Chemin <> '' then
      FenLivre.ChargerXMLFile(Chemin);
    FenLivre.Show;
  end;

procedure TMenu.WinLivreFerme(Sender: TObject; var CloseAction: TCloseAction);
  begin
    Application.Terminate;
  end;

procedure TMenu.LotRetraitLivre();
  // Test de XmlRetireLivre (A FAIRE.txt, ENREGISTREMENT PAR L EXPORT) : retire le livre passe en
  // argument des listes globales, le reimporte (OnlyPrimary vrai puis faux, comme au demarrage et
  // au rechargement) et trace l'etat des listes avant/retire/apres dans LOT_RETRAIT.txt.
  var
    Code, Libelle: String;
    Fichiers:      TStringList;
    Trace:         TStringList;
    Rech:          TSearchRec;
    Ind:           Integer;

    function Etat(): String;
      begin
        Result := 'Talent=' + IntToStr(ListTalent.Count) + '/' + IntToStr(NbTalent)
          + ' Metier=' + IntToStr(ListMetier.Count) + '/' + IntToStr(NbMetier)
          + ' Arme=' + IntToStr(ListArme.Count) + '/' + IntToStr(NbArme)
          + ' Sort=' + IntToStr(ListSort.Count) + '/' + IntToStr(NbSort)
          + ' Fabrication=' + IntToStr(ListFabrication.Count)
          + ' Texte=' + IntToStr(ListTexte.Count) + '/' + IntToStr(NbTexte)
          + ' Traduction=' + IntToStr(ListTraduction.Count) + '/' + IntToStr(NbTraduction)
          + ' Modificateur=' + IntToStr(ListModificateur.Count)
          + ' SpecialRule=' + IntToStr(ListCareerBonusSpecialRule.Count)
          + ' Regle=' + IntToStr(ListRegle.Count) + '/' + IntToStr(ListRegleSource.Count);
      end;

  begin
    Code     := ParamStr(2);
    Libelle  := ChercheLivre(Code).Libelle;
    Fichiers := TStringList.Create;
    Trace    := TStringList.Create;
    try
      if Libelle = '' then
        begin
          Trace.Add('LIVRE INCONNU : ' + Code);
          Exit;
        end;
      if FindFirst(GetCurrentDir + ConstCheminLivre + '*.xml', faAnyFile, Rech) = 0 then
        begin
          repeat
            if XmlLivre(ExtractStringBefore(Rech.Name, '.')) = Libelle then
              Fichiers.Add(ExtractStringBefore(Rech.Name, '.'));
          until FindNext(Rech) <> 0;
          FindClose(Rech);
        end;
      // L'anglais (nom le plus court) d'abord, puis les traductions.
      Fichiers.Sort;
      Trace.Add('Livre : ' + Code + ' = ' + Libelle + ' (' + IntToStr(Fichiers.Count) + ' fichier(s))');
      Trace.Add('AVANT  : ' + Etat());
      XmlRetireLivre(Libelle);
      Trace.Add('RETIRE : ' + Etat());
      for Ind := 0 to Fichiers.Count - 1 do
        XmlImport(Fichiers[Ind], true);
      for Ind := 0 to Fichiers.Count - 1 do
        XmlImport(Fichiers[Ind], false);
      CompleteRaceMetierParEspece;
      Traduit(ValLangue, Libelle);
      Trace.Add('APRES  : ' + Etat());
    finally
      Trace.SaveToFile(GetCurrentDir + '\LOT_RETRAIT.txt');
      Trace.Free;
      Fichiers.Free;
    end;
  end;

// WarhammerHelp.exe --pdfmetier : un PDF par carriere (PdfMetierDoc) puis un par race
// (PdfRaceCreation), sans ouvrir le lecteur. Les fichiers portent le libelle de la carriere ou de la
// race, dans SAVED_CARACTERS\<version>\. Sert a comparer avant/apres une modification de pdfmetier.pas
// ou de pdfrace.pas (pdftotext + rendu). Trace dans LOT_PDF.txt.
procedure TMenu.LotPdfMetiersRaces();
  Var
    PMetier: StructureMetier;
    PRace:   StructureRace;
    Codes:   TStringList;
    Trace:   TStringList;
    Ind:     Integer;
  begin
    Trace            := TStringList.Create;
    Codes            := TStringList.Create;
    PdfSansOuverture := True;
    try
      Codes.Sorted     := True;
      Codes.Duplicates := dupIgnore;
      for PMetier in ListMetier do
        Codes.Add(PMetier.CodeMetier);
      for Ind := 0 to Codes.Count - 1 do
        begin
          PdfMetierDoc(Codes[Ind]);
          Trace.Add('METIER : ' + Codes[Ind]);
        end;
      Codes.Clear;
      for PRace in ListRace do
        Codes.Add(PRace.CodeRace);
      for Ind := 0 to Codes.Count - 1 do
        begin
          PdfRaceCreation(Codes[Ind]);
          Trace.Add('RACE : ' + Codes[Ind]);
        end;
    finally
      Trace.SaveToFile(GetCurrentDir+'\LOT_PDF.txt');
      Codes.Free;
      Trace.Free;
    end;
  end;

procedure TMenu.LotPdfPersonnages();
  // Un PDF par dossier de SAVED_CARACTERS\<version>\ passe en argument (meme chemin et meme
  // choix de gabarit que ButtonPdfClick), sans ouvrir le lecteur. Trace dans LOT_PDF.txt.
  Var
    Ind:        Integer;
    Chemin:     String;
    Personnage: StructurePersonnage;
    Trace:      TStringList;
  begin
    Trace            := TStringList.Create;
    PdfSansOuverture := True;
    try
      for Ind := 2 to ParamCount do
        begin
          Chemin := XmlPersonnageFichierActuel(GetCurrentDir+ConstCheminPersonnage+ParamStr(Ind));
          if Chemin = '' then
            begin
              Trace.Add('ABSENT : ' + ParamStr(Ind));
              Continue;
            end;
          Personnage := PersonnageXmlChargement(Chemin);
          if Pos(AjouteAccolade(ConstXmlOptionFeldo2P), Personnage.Options) > 0 then
            PdfPersonnageCreationFeldo2P(Personnage)
          else
            PdfPersonnageCreation(Personnage, true);
          Trace.Add('OK : ' + ParamStr(Ind) + ' <- ' + Chemin);
        end;
    finally
      Trace.SaveToFile(GetCurrentDir+'\LOT_PDF.txt');
      Trace.Free;
    end;
  end;

procedure TMenu.FormResize(Sender: TObject);
  begin
    AjustePositionFenetre();
  end;

procedure TMenu.AjustePositionFenetre();
  var
    EcartTotal: Integer;
  begin
    // Un OnResize qui arriverait avant la fin de FormCreate (construction de la fenetre,
    // ex. ChargeIni qui touche Self.Width) n'a encore rien a reancrer - LargeurFenetreBase
    // n'est capturee (dans FormCreate) qu'une fois FenetreInitialisee passee a true.
    if not FenetreInitialisee then
      exit;

    EcartTotal := Self.ClientWidth - LargeurFenetreBase;

    // Nono le 15/09/2026 : les deux tables ne doivent jamais devenir plus petites que leur
    // taille de depart, quelle qu'en soit la cause (fenetre retrecie sous la reference, ou
    // ecart transitoire pendant un drag) - en dessous, elles restent a leur taille de
    // depart plutot que de se chevaucher ; c'est alors la colonne Bibliotheque a droite qui
    // sortirait progressivement du cadre visible, jamais les deux tables qui s'ecrasent
    // l'une sur l'autre.
    if EcartTotal < 0 then
      EcartTotal := 0;

    // TabLivre et TabPersonnage se partagent l'ecart moitie-moitie a l'elargissement
    // (A FAIRE.txt, demande Nono 13/09/2026). Le reste d'un ecart impair va a
    // TabPersonnage pour que la somme des deux largeurs colle exactement a EcartTotal.
    TabLivre.Width       := LargeurTabLivreBase + (EcartTotal div 2);
    TabPersonnage.Width  := LargeurTabPersonnageBase + (EcartTotal - (EcartTotal div 2));

    // Tout ce qui est place ENTRE les deux tables (Button3) et APRES (Button1 puis toute
    // la colonne Bibliotheque) est reancre en chaine a partir de la geometrie fraichement
    // recalculee ci-dessus - jamais stocke, toujours recalcule depuis l'etat courant, meme
    // principe que AjustePositionTables (winpersonnage.pas). Les ecarts fixes (6/10/8/16/
    // 64/184) sont ceux du .lfm d'origine entre chaque controle et son voisin de gauche.
    Button3.Left         := TabLivre.Left + TabLivre.Width + 6;
    TabPersonnage.Left   := Button3.Left + Button3.Width + 10;
    Button1.Left         := TabPersonnage.Left + TabPersonnage.Width + 8;

    // Meme piege que TabLivre/TabPersonnage/Button2 plus haut, cote colonne Bibliotheque :
    // son premier element (ButtonRace et les 6 autres TBCButton, +16 apres Button1) ne
    // doit jamais chevaucher Panel2/Panel3 (Version/Interface, jamais reancres, bord droit
    // fixe Panel2.Left+Panel2.Width) - releve par Nono le 15/09/2026, les deux tables pres
    // de leur minimum ramenant Button1 trop a gauche.
    if Button1.Left < (Panel2.Left + Panel2.Width) - 16 then
      Button1.Left := (Panel2.Left + Panel2.Width) - 16;

    // Libelle et boutons de la colonne Personnages, au-dessus de TabPersonnage - alignes
    // sur son bord gauche (ButtonPdf a +224 dans le .lfm d'origine), suivent donc le meme
    // decalage que la table plutot que de rester figes (Nono, 15/09/2026).
    Label2.Left             := TabPersonnage.Left;
    ButtonCreation.Left     := TabPersonnage.Left;
    ButtonModification.Left := TabPersonnage.Left;
    ButtonPdf.Left          := TabPersonnage.Left + 224;

    // Button2 (ligne separatrice horizontale au-dessus des deux tables) s'arrete pile au
    // bord droit de TabPersonnage dans le .lfm d'origine (Left=0, Width=968=432+536) -
    // grandit donc du meme ecart total que les deux tables reunies. Ne doit cependant
    // jamais finir avant Panel2/Panel3 (combos Version/Interface, jamais reancres, bord
    // droit fixe a Panel2.Left+Panel2.Width) : si TabPersonnage redescendait pres de son
    // minimum, Button2 s'arreterait sinon avant elles (Nono, 15/09/2026).
    if TabPersonnage.Left + TabPersonnage.Width > Panel2.Left + Panel2.Width then
      Button2.Width := TabPersonnage.Left + TabPersonnage.Width
    else
      Button2.Width := Panel2.Left + Panel2.Width;

    Label1.Left            := Button1.Left + 184;
    TabBibliotheque.Left   := Button1.Left + 16;
    // Meme suivi vertical que les boutons Race..Talent (Anchors [akLeft] seul : ils derivent
    // avec la hauteur de la fenetre) : le tableau reste a 129 px sous ButtonTalent (564-435
    // dans le .lfm d'origine) et descend jusqu'a 16 px du bas de la colonne (Button1).
    TabBibliotheque.Top    := ButtonTalent.Top + 129 + 20;
    // Hauteur ajustee au nombre de lignes (plus de bande vide sous le dernier total),
    // plafonnee au bas de la colonne ; l'ascenseur reprend si les lignes depassent.
    TabBibliotheque.Height := TabBibliotheque.GridHeight + 4;
    if TabBibliotheque.Top + TabBibliotheque.Height > Button1.Top + Button1.Height - 16 then
      TabBibliotheque.Height := (Button1.Top + Button1.Height - 16) - TabBibliotheque.Top;
    ButtonRace.Left        := Button1.Left + 16;
    ButtonMetier.Left      := Button1.Left + 16;
    ButtonCompetence.Left  := Button1.Left + 16;
    ButtonTalent.Left      := Button1.Left + 16;

    TotLivreRace.Left       := Button1.Left + 64;
    TotLivreMetier.Left     := Button1.Left + 64;
    TotLivreCompetence.Left := Button1.Left + 64;
    TotLivreTalent.Left     := Button1.Left + 64;

    BoutonRace.Left        := Button1.Left + 184;
    BoutonMetier.Left      := Button1.Left + 184;
    BoutonCompetence.Left  := Button1.Left + 184;
    BoutonTalent.Left      := Button1.Left + 184;
  end;

procedure TMenu.ButtonCompetenceClick(Sender: TObject);
  begin
    // ouvrr les compétences
    FenCompetence          := TWinCompetence.Create(Application);
    FenCompetence.Position := poOwnerFormCenter;
    FenCompetence.Show;
  end;

procedure TMenu.ButtonTalentClick(Sender: TObject);
  begin
    // ouvrir les talents
    FenTalent          := TWintTalent.Create(Application);
    FenTalent.Position := poOwnerFormCenter;
    FenTalent.Show;
  end;

procedure TMenu.ButtonRaceClick(Sender: TObject);
  begin
    // ouvrir les races
    FenRace          := TWinRace.Create(Application);
    FenRace.Position := poOwnerFormCenter;
    FenRace.Show;
  end;

procedure TMenu.ButtonSortClick(Sender: TObject);
begin
  FenSort          := TWinSpells.Create(Application);
  FenSort.Position := poOwnerFormCenter;
  FenSort.Show;
end;

procedure TMenu.ButtonCreationClick(Sender: TObject);
  begin
    // créer un personnage
    FenCreation         := TWinCreations.Create(Application);
    FenCreation.Position := poOwnerFormCenter;
    FenCreation.Show;
  end;

procedure TMenu.ButtonCreationLivreClick(Sender: TObject);
var
  Code, Nom, Chemin, Officiel, Complet: String;
  F: TStringList;
begin
  // Cree l en-tete d un livre vide puis l ouvre dans WinLivre. Livre perso : OFFICIAL 2 ;
  // livre officiel a saisir : OFFICIAL 1 + COMPLETE 0 (modifiable tant qu il est inacheve).
  Code := '';
  Nom  := '';
  if not InputQuery(Caption, 'Code du livre (2 a 6 lettres/chiffres, ex. MYBK)', Code) then Exit;
  Code := UpperCase(Trim(Code));
  if (Length(Code) < 2) or (Length(Code) > 6) then
    begin
      MessageDlg('Code invalide.', mtWarning, [mbOK], 0);
      Exit;
    end;
  if not InputQuery(Caption, 'Nom du livre', Nom) then Exit;
  Nom := Trim(StringReplace(Nom, '"', '', [rfReplaceAll]));
  if Nom = '' then Exit;
  if MessageDlg('Livre perso (oui) ou nouveau livre officiel a saisir (non) ?',
       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Officiel := '2';
      Complet  := '1';
    end
  else
    begin
      Officiel := '1';
      Complet  := '0';
    end;
  Chemin := GetCurrentDir + ConstCheminLivre + 'BOOK ' + UpperCase(Nom) + '.Xml';
  if FileExists(Chemin) then
    begin
      MessageDlg('Ce livre existe deja.', mtWarning, [mbOK], 0);
      Exit;
    end;
  F := TStringList.Create;
  try
    F.Add('<?xml version="1.0" encoding="UTF-8"?>');
    F.Add('<DATA_BOOK>');
    F.Add('<CODE_BOOK>"' + Code + '"</CODE_BOOK>');
    F.Add('<BOOK>"BOOK ' + UpperCase(Nom) + '"</BOOK>');
    F.Add('<BOOKNAME>"' + Nom + '"</BOOKNAME>');
    F.Add('<language>"ENGLISH"</language>');
    F.Add('<VERSION>"' + ValVersion + '"</VERSION>');
    F.Add('<OFFICIAL>"' + Officiel + '"</OFFICIAL>');
    F.Add('<COMPLETE>"' + Complet + '"</COMPLETE>');
    F.Add('</DATA_BOOK>');
    F.SaveToFile(Chemin);
  finally
    F.Free;
  end;
  LancerWinLivre(Chemin);
end;

procedure TMenu.ButtonArmeClick(Sender: TObject);
begin
  FenArme          := TWinWeapons.Create(Application);
  FenArme.Position := poOwnerFormCenter;
  FenArme.Show;
end;

procedure TMenu.ButtonEquipementClick(Sender: TObject);
begin
  ModeEquipements         := meHorsVehicules;
  WinEquipements          := TWinEquipements.Create(Application);
  ModeEquipements         := meTout;
  WinEquipements.Position := poOwnerFormCenter;
  WinEquipements.Show;
end;

procedure TMenu.BoutonCompetenceClick(Sender: TObject);
begin
  FenCompetence          := TWinCompetence.Create(Application);
  FenCompetence.Position := poOwnerFormCenter;
  FenCompetence.Show;
end;

procedure TMenu.BoutonTalentClick(Sender: TObject);
begin
  FenTalent          := TWintTalent.Create(Application);
  FenTalent.Position := poOwnerFormCenter;
  FenTalent.Show;
end;

procedure TMenu.ButtonArmureClick(Sender: TObject);
begin
  FenArmure          := TWinArmors.Create(Application);
  FenArmure.Position := poOwnerFormCenter;
  FenArmure.Show;
end;

// Libelle du bouton « Tests automatiques » (le bouton est dans warhammersource.lfm, meme style que les autres).
procedure TMenu.PoserBoutonTestsAuto();
  begin
    ButtonTestsAuto.Caption := GetTexteLibelle('RULES-LAB_1005');
  end;

// Lance les cas de test de creation de la version affichee (TRAVAIL\CAS_CREATION_<version>*.txt, comme
// --testcreation) et affiche un resume par fichier puis le detail des echecs.
procedure TMenu.ButtonTestsAutoClick(Sender: TObject);
  Var
    Dossier, NomFichier, SortiePersos: String;
    Fichiers, Echecs, Rapport, SortieFichier: TStringList;
    Recherche: TSearchRec;
    Ind, NbCas, NbEchec, TotalCas, TotalEchec: Integer;
    Fenetre: TForm;
    Memo: TMemo;
  begin
    if MessageDlg(GetTexteLibelle('RULES-LAB_1005'), GetTexteLibelle('RULES-MESS_125'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    Dossier := GetCurrentDir + '\TRAVAIL\';
    Fichiers      := TStringList.Create;
    Echecs        := TStringList.Create;
    Rapport       := TStringList.Create;
    SortieFichier := TStringList.Create;
    try
      Fichiers.Sorted := True;
      if FindFirst(Dossier + 'CAS_CREATION_' + ValVersion + '*.txt', faAnyFile, Recherche) = 0 then
        begin
          repeat
            Fichiers.Add(Recherche.Name);
          until FindNext(Recherche) <> 0;
          FindClose(Recherche);
        end;
      if Fichiers.Count = 0 then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_124') + LineEnding + Dossier + 'CAS_CREATION_' + ValVersion + '*.txt');
          Exit;
        end;
      Screen.Cursor := crHourGlass;
      try
        TotalCas   := 0;
        TotalEchec := 0;
        for Ind := 0 to Fichiers.Count - 1 do
          begin
            NomFichier := Fichiers[Ind];
            SortieFichier.Clear;
            NbCas   := 0;
            NbEchec := 0;
            TesterCasCreation(Dossier + NomFichier, SortieFichier, NbCas, NbEchec);
            Rapport.Add(Format('%s : %d %s, %d %s', [NomFichier, NbCas, GetTexteLibelle('RULES-LAB_1006'),
              NbEchec, GetTexteLibelle('RULES-LAB_1007')]));
            Inc(TotalCas, NbCas);
            Inc(TotalEchec, NbEchec);
            for NomFichier in SortieFichier do
              if Copy(NomFichier, 1, 5) = 'ECHEC' then
                Echecs.Add(NomFichier);
          end;
      finally
        Screen.Cursor := crDefault;
      end;
      Rapport.Insert(0, '');
      Rapport.Insert(0, Format('%s : %d %s, %d %s', [ValVersion, TotalCas, GetTexteLibelle('RULES-LAB_1006'),
        TotalEchec, GetTexteLibelle('RULES-LAB_1007')]));
      if Echecs.Count > 0 then
        begin
          Rapport.Add('');
          Rapport.AddStrings(Echecs);
        end;
      // non-regression de WinPersonnage : TRAVAIL\tester_persos.py (lance le programme dans un dossier isole)
      if FileExists(Dossier + 'tester_persos.py') then
        begin
          Screen.Cursor := crHourGlass;
          try
            SortiePersos := '';
            Rapport.Add('');
            if RunCommandInDir(GetCurrentDir, 'python', ['TRAVAIL\tester_persos.py', '--versions', ValVersion], SortiePersos) then
              Rapport.Add('tester_persos.py : ' + Trim(SortiePersos))
            else
              Rapport.Add('tester_persos.py : ECHEC ' + Trim(SortiePersos));
          finally
            Screen.Cursor := crDefault;
          end;
        end;
      Fenetre := TForm.CreateNew(Application);
      try
        Fenetre.Caption  := GetTexteLibelle('RULES-LAB_1005');
        Fenetre.Position := poOwnerFormCenter;
        Fenetre.Width    := 900;
        Fenetre.Height   := 500;
        Memo             := TMemo.Create(Fenetre);
        Memo.Parent      := Fenetre;
        Memo.Align       := alClient;
        Memo.ReadOnly    := True;
        Memo.ScrollBars  := ssBoth;
        Memo.Lines.Assign(Rapport);
        Fenetre.ShowModal;
      finally
        Fenetre.Free;
      end;
    finally
      SortieFichier.Free;
      Rapport.Free;
      Echecs.Free;
      Fichiers.Free;
    end;
  end;

procedure TMenu.ButtonOptionRegleClick(Sender: TObject);
begin
  WinOptionRegles          := TWinOptionRegle.Create(Application);
  WinOptionRegles.Position := poOwnerFormCenter;
  WinOptionRegles.ShowModal;
end;

procedure TMenu.ButtonModificationClick(Sender: TObject);
  begin
    // ouvrir un personnage
    if TabPersonnage.Cells[ColPersoLNe, TabPersonnage.Row] <> '' then
      ShowMessage(GetTexteLibelle('RULES-MESS_046') + TabPersonnage.Cells[ColPersoLNe, TabPersonnage.Row])
    else
      begin
      NomPersonnage         := TabPersonnage.Cells[1, TabPersonnage.Row];
      if NomPersonnage <> '' then
        begin
          FenPersonnage         := TWinPersonnages.Create(Application);
          FenPersonnage.Position:= poOwnerFormCenter;
          FenPersonnage.Show;
        end;
      end;

  end;

procedure TMenu.ButtonOuvrirLivreClick(Sender: TObject);
  begin
    // ouvrir un livre
    CodeLivre        := TabLivre.Cells[ColLivreAbr, TabLivre.Row];
    NomLivre         := TabLivre.Cells[ColLivreCod, TabLivre.Row];
    if (NomLivre <> '') and (TabLivre.Cells[ColLivreSel, TabLivre.Row] = ConstSelectionne) then
      LancerWinLivre('');
  end;

procedure TMenu.ButtonDisclaimerLivreClick(Sender: TObject);
  var
    PLivre: StructureLivre;
  begin
    if TabLivre.Cells[ColLivreCod, TabLivre.Row] <> '' then
      begin
        PLivre := ChercheLivreLibelle(TabLivre.Cells[ColLivreCod, TabLivre.Row]);
        // Le champ DISCLAIMER de l'en-tete est le texte d'origine (anglais) ; une traduction est
        // un libelle CODELIVRE-DISCLAIMER du livre de traduction, le champ sert de repli.
        if PLivre.Disclaimer <> '' then
          ShowMessage(GetTexteLibelle(PLivre.CodeLivre + SeparateurLivre + 'DISCLAIMER', PLivre.Disclaimer))
        else
          ShowMessage(GetTexteLibelle('RULES-LAB_498'));
      end;
  end;

function TMenu.XmlPersonnageFichierActuel(const Directory: string): string;
var
  SearchRec:       TSearchRec;
  HighestFileName: string;
begin
  HighestFileName := '';

  if FindFirst(Directory + PathDelim + '*.xml', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
      begin
        // Vérifier si le fichier a l'extension .xml
        if UpperCase(ExtractFileExt(SearchRec.Name)) = UpperCase('.xml') then
        begin
          // Comparer le nom du fichier avec le nom le plus élevé trouvé jusqu'à présent
          if HighestFileName = '' then
            HighestFileName := SearchRec.Name
          else if CompareText(SearchRec.Name, HighestFileName) > 0 then
            HighestFileName := SearchRec.Name;
        end;
      end;
    until FindNext(SearchRec) <> 0;
  end;

  if HighestFileName <> '' then
    Result := IncludeTrailingPathDelimiter(Directory) + HighestFileName
  else
    Result := '';
end;

procedure TMenu.LotReecritPersonnages();
  // Aller-retour de fiche : lecture (PersonnageXmlChargement) puis ecriture (PersonnageXmlCreation) dans
  // <sortie>\<dossier personnage>.xml. Les XP viennent de la fiche lue. Trace dans LOT_REECRIT.txt.
  Var
    Ind:        Integer;
    Chemin:     String;
    Personnage: StructurePersonnage;
    Trace:      TStringList;
  begin
    Trace := TStringList.Create;
    try
      ForceDirectories(ParamStr(2));
      for Ind := 3 to ParamCount do
        begin
          Chemin := XmlPersonnageFichierActuel(GetCurrentDir+ConstCheminPersonnage+ParamStr(Ind));
          if Chemin = '' then
            begin
              Trace.Add('ABSENT : ' + ParamStr(Ind));
              Continue;
            end;
          Personnage := PersonnageXmlChargement(Chemin);
          if PersonnageXmlCreation(Personnage, Personnage.XpTotal, Personnage.XpActuel,
                                   IncludeTrailingPathDelimiter(ParamStr(2)) + ParamStr(Ind) + '.xml', Personnage.NomPersonnage) then
            Trace.Add('OK : ' + ParamStr(Ind))
          else
            Trace.Add('ECHEC : ' + ParamStr(Ind));
        end;
    finally
      Trace.SaveToFile(GetCurrentDir+'\LOT_REECRIT.txt');
      Trace.Free;
    end;
  end;

procedure TMenu.LotNaissance();
  // --naissance <code ethnie> [nombre] : NAISSANCE.txt, une ligne par tirage des details V2.
  Var
    Ind, Nb:  Integer;
    Details:  StructureDetailsV2;
    Sortie:   TStringList;
  begin
    Nb := 20;
    if ParamCount >= 3 then
      Nb := StrToIntDef(ParamStr(3), 20);
    Sortie := TStringList.Create;
    try
      for Ind := 1 to Nb do
        if TireDetailsV2(ParamStr(2), Random(2) = 0, Details) then
          Sortie.Add(Format('Age=%d Taille=%d Poids=%d Fratrie=%d Signe=%s | Astre=%s | Naissance=%s | Effets=%s',
            [Details.Age, Details.Taille, Details.Poids, Details.Fratrie, Details.Signe, Details.SigneAstral, Details.Naissance,
             EffetsNaissanceRace(ParamStr(2), Details.Naissance)]))
        else
          Sortie.Add('Aucune table V2 pour ' + ParamStr(2));
    finally
      Sortie.SaveToFile(GetCurrentDir + '\NAISSANCE.txt');
      Sortie.Free;
    end;
  end;

procedure TMenu.LotFamilier();
  // --familier <code ethnie> [nombre] : FAMILIER.txt, une ligne par tirage.
  Var
    Ind, Nb:  Integer;
    Formes, Particularites, Sortie: TStringList;
    Effets:   String;
  begin
    Nb := 20;
    if ParamCount >= 3 then
      Nb := StrToIntDef(ParamStr(3), 20);
    Formes         := TStringList.Create;
    Particularites := TStringList.Create;
    Sortie         := TStringList.Create;
    try
      Formes.Delimiter := ',';
      Particularites.Delimiter := ',';
      for Ind := 1 to Nb do
        begin
          TireFamilierV2(ParamStr(2), Formes, Particularites, Effets);
          if Formes.Count = 0 then
            Sortie.Add('Aucune table de familier pour ' + ParamStr(2))
          else
            Sortie.Add(Format('Formes=%s | Particularites=%s | Effets=%s',
              [Formes.DelimitedText, Particularites.DelimitedText, Effets]));
        end;
    finally
      Sortie.SaveToFile(GetCurrentDir + '\FAMILIER.txt');
      Sortie.Free;
      Particularites.Free;
      Formes.Free;
    end;
  end;

procedure TMenu.LotTestCreation();
  // --testcreation <cas.txt> <sortie.txt> : voir TesterCasCreation pour le format des cas.
  Var
    Sortie: TStringList;
    NbCas, NbEchec: Integer;
  begin
    Sortie  := TStringList.Create;
    NbCas   := 0;
    NbEchec := 0;
    try
      TesterCasCreation(ParamStr(2), Sortie, NbCas, NbEchec);
      Sortie.Add(Format('TOTAL %d cas, %d echec', [NbCas, NbEchec]));
    finally
      Sortie.SaveToFile(ParamStr(3));
      Sortie.Free;
    end;
  end;

procedure TMenu.TesterCasCreation(const FichierCas: String; Sortie: TStringList; var NbCas, NbEchec: Integer);
  // Lance les cas d'un fichier (cumule dans NbCas / NbEchec, ajoute une ligne OK / ECHEC par cas a Sortie).
  // Un cas par ligne, 7 champs separes par « | » :
  //   id | fonction | arg1 | arg2 | arg3 | attendu | source      (# = commentaire)
  // fonctions : metier (ethnie, regle, jet d100)        -> code du metier tire
  //             codes  (genre S/T, regle, ethnie)       -> codes effectifs, tries, separes par des virgules
  //             couvre (regle, ethnie)                  -> 1 / 0 (RegleCouvreRace)
  //             remplace (regle, ethnie, genre S/T)     -> 1 / 0 (RegleRemplaceGenre)
  //             fond   (ethnie, -, jet d100)            -> regle de background (RegleFondTirage)
  //             talent (ethnie, -, jet d100)            -> talent tire au hasard (CalculeTirageTalent)
  //             sousmetier (metier, -, 2e jet d100)     -> metier du second jet (ResultMetierSousMetier)
  //             choixmetier (ethnie, metier)            -> metier/alternative/... (ResultMetierRaceChoixMetier)
  //             niveaubonus (appartenance, palier 1-4)  -> « competences;talents » du palier (NiveauxDuCareerBonus)
  //             memetirage (ethnie, regle)              -> 1 si la regle donne la table de base pour cette ethnie
  //             appartenances (metier, ethnie)          -> regiments / ordres proposes, tries
  //             competencev1 (classe, espece, jet d100) -> competence de depart V1 (DATA_SKILL_ROLL_V1, chances cumulees)
  //             blessures (formule, F/E/FM)             -> Blessures de depart (CalculBlessure, bonus = dizaine)
  //             cout (type C/S/T, de/vers, code)        -> XP d'une avance (CoutXpBase), version = celle du programme
  //             suite (type C/S/T, « a>b>c », code)     -> somme des couts de chaque achat successif
  // L'attendu vient du livre (champ source), jamais d'une copie du resultat du programme.
  Var
    Cas, Champs, Liste: TStringList;
    Ind, Jet, Etape, SommeEtapes: Integer;
    Ligne, Fonction, Obtenu, Attendu, TypeCout: String;
    Tirage: TListTirageMetier;
    Tranche: StructureTirageMetier;
    Niveaux: TListCareerBonusNiveau;
    NivBonus: StructureCareerBonusNiveau;
    TirageComp: StructureTirageCompV1;
    CumulComp:  Integer;
    TirageTal:  TListTirageTalent;
    LigneTal:   StructureTirageTalent;
  begin
    Cas     := TStringList.Create;
    Champs  := TStringList.Create;
    Tirage  := TListTirageMetier.Create;
    try
      Champs.StrictDelimiter := True;
      Champs.Delimiter       := '|';
      Champs.QuoteChar       := #1;
      Cas.LoadFromFile(FichierCas);
      for Ind := 0 to Cas.Count - 1 do
        begin
          Ligne := Trim(Cas[Ind]);
          if (Ligne = '') or (Ligne[1] = '#') then
            continue;
          Champs.DelimitedText := Ligne;
          while Champs.Count < 7 do
            Champs.Add('');
          for Jet := 0 to Champs.Count - 1 do
            Champs[Jet] := Trim(Champs[Jet]);
          Fonction := LowerCase(Champs[1]);
          Attendu  := Champs[5];
          Obtenu   := '?fonction inconnue';
          if Fonction = 'metier' then
            begin
              Obtenu := '';
              Jet    := StrToIntDef(Champs[4], 0);
              CalculeTirageMetier(Champs[2], Champs[3], Tirage);
              for Tranche in Tirage do
                if (Jet >= Tranche.Debut) and (Jet <= Tranche.Fin) then
                  Obtenu := Tranche.CodeMetier;
            end
          else if Fonction = 'codes' then
            begin
              Liste := CodesRaceEffectifs(Champs[2], Champs[3], Champs[4]);
              try
                Liste.Sorted := True;
                Liste.Delimiter := ',';
                Liste.StrictDelimiter := True;
                Liste.QuoteChar := #1;
                Obtenu := Liste.DelimitedText;
              finally
                Liste.Free;
              end;
            end
          else if Fonction = 'couvre' then
            Obtenu := IntToStr(Ord(RegleCouvreRace(Champs[2], Champs[3])))
          else if Fonction = 'remplace' then
            Obtenu := IntToStr(Ord(RegleRemplaceGenre(Champs[2], Champs[3], Champs[4])))
          else if Fonction = 'fond' then
            Obtenu := RegleFondTirage(Champs[2], StrToIntDef(Champs[4], 0))
          else if Fonction = 'talent' then
            // talent tire au hasard a la creation (table de l ethnie, ou generique) pour un jet d100
            begin
              Obtenu := '';
              Jet    := StrToIntDef(Champs[4], 0);
              TirageTal := TListTirageTalent.Create;
              try
                CalculeTirageTalent(Champs[2], TirageTal);
                for LigneTal in TirageTal do
                  if (Jet >= LigneTal.Debut) and (Jet <= LigneTal.Fin) then
                    Obtenu := LigneTal.CodeTalent;
              finally
                TirageTal.Free;
              end;
            end
          else if Fonction = 'competencev1' then
            begin
              // chances cumulees dans l'ordre des donnees, comme TCreationV1.TirerCompClick
              Obtenu   := '';
              CumulComp := 0;
              Jet      := StrToIntDef(Champs[4], 0);
              for TirageComp in ListTirageCompV1 do
                if (TirageComp.CodeClasse = Champs[2]) and CompareRechercheValeur(TirageComp.Espece, Champs[3]) then
                  begin
                    CumulComp := CumulComp + TirageComp.Chance;
                    if (Obtenu = '') and (Jet <= CumulComp) then
                      Obtenu := TirageComp.CodeCompetence;
                  end;
            end
          else if Fonction = 'blessures' then
            // Blessures de depart : formule d ethnie (ex. 1xBATTR_S+2xBATTR_T+1xBATTR_WP), valeurs « F/E/FM » (carac. totales)
            begin
              Liste := TStringList.Create;
              try
                ExtractStrings(['/'], [], PChar(Champs[3]), Liste);
                if Liste.Count = 3 then
                  Obtenu := IntToStr(CalculBlessure(Champs[2], StrToIntDef(Liste[0], 0), StrToIntDef(Liste[1], 0), StrToIntDef(Liste[2], 0)))
                else
                  Obtenu := '?valeurs F/E/FM attendues';
              finally
                Liste.Free;
              end;
            end
          else if Fonction = 'sousmetier' then
            // second d100 apres le metier tire (DATA_CAREER_SUBCHOICE) : '' = pas de sous-metier
            Obtenu := StringReplace(ResultMetierSousMetier(Champs[2], StrToIntDef(Champs[4], 0), ''), SeparateurMulti, '/', [rfReplaceAll])
          else if Fonction = 'memetirage' then
            // la regle donne-t-elle exactement la table de base pour cette ethnie (non couverte) ? 1 / 0
            begin
              Liste := TStringList.Create;
              try
                CalculeTirageMetier(Champs[2], '', Tirage);
                for Tranche in Tirage do
                  Liste.Add(Format('%s:%d-%d', [Tranche.CodeMetier, Tranche.Debut, Tranche.Fin]));
                Obtenu := Liste.Text;
                Liste.Clear;
                CalculeTirageMetier(Champs[2], Champs[3], Tirage);
                for Tranche in Tirage do
                  Liste.Add(Format('%s:%d-%d', [Tranche.CodeMetier, Tranche.Debut, Tranche.Fin]));
                Obtenu := IntToStr(Ord((Liste.Text = Obtenu) and (Liste.Count > 0)));
              finally
                Liste.Free;
              end;
            end
          else if Fonction = 'niveaubonus' then
            // competences et talents donnes par un palier d une appartenance (regiment) : « competences | talents »
            begin
              Obtenu := '(palier absent)';
              Niveaux := NiveauxDuCareerBonus(Champs[2]);
              try
                for NivBonus in Niveaux do
                  if NivBonus.Niveau = StrToIntDef(Champs[3], 0) then
                    Obtenu := NivBonus.ListeCompetence + ';' + NivBonus.ListeTalent;
              finally
                Niveaux.Free;
              end;
            end
          else if Fonction = 'appartenances' then
            // regiments / ordres proposes pour (metier, ethnie) : codes tries (AppartenancesCandidates)
            begin
              Liste := TStringList.Create;
              try
                ExtractStrings([','], [], PChar(AppartenancesCandidates(Champs[2], Champs[3], '')), Liste);
                Liste.Sorted := True;
                Liste.Delimiter := ',';
                Liste.StrictDelimiter := True;
                Liste.QuoteChar := #1;
                Obtenu := Liste.DelimitedText;
              finally
                Liste.Free;
              end;
            end
          else if Fonction = 'cout' then
            // cout en XP d'une avance, hors surcout MJ et option XP / 25 : type C / S / T (caracteristique,
            // competence, talent), « de/vers » (valeur de depart / valeur visee), code d'attribut (V1 / V2, facultatif)
            begin
              Liste := TStringList.Create;
              try
                ExtractStrings(['/'], [], PChar(Champs[3]), Liste);
                if Liste.Count = 2 then
                  begin
                    if Champs[2] = 'C' then
                      TypeCout := ConstXmlCarac
                    else if Champs[2] = 'S' then
                      TypeCout := ConstXmlCompetence
                    else
                      TypeCout := ConstXmlTalent;
                    Obtenu := IntToStr(CoutXpBase(TypeCout, StrToIntDef(Liste[0], 0), StrToIntDef(Liste[1], 0), Champs[4]));
                  end
                else
                  Obtenu := '?de/vers attendu';
              finally
                Liste.Free;
              end;
            end
          else if Fonction = 'suite' then
            // suite d'achats : type C / S / T, valeurs successives « 0>3>8>13 » ; Obtenu = somme des couts de chaque
            // etape (CoutXpBase de l'une a la suivante), a comparer au cout d'un seul achat du depart a l'arrivee
            begin
              Liste := TStringList.Create;
              try
                ExtractStrings(['>'], [], PChar(Champs[3]), Liste);
                if Champs[2] = 'C' then
                  TypeCout := ConstXmlCarac
                else if Champs[2] = 'S' then
                  TypeCout := ConstXmlCompetence
                else
                  TypeCout := ConstXmlTalent;
                SommeEtapes := 0;
                for Etape := 1 to Liste.Count - 1 do
                  SommeEtapes := SommeEtapes +
                    CoutXpBase(TypeCout, StrToIntDef(Liste[Etape - 1], 0), StrToIntDef(Liste[Etape], 0), Champs[4]);
                Obtenu := IntToStr(SommeEtapes);
              finally
                Liste.Free;
              end;
            end
          else if Fonction = 'coutreel' then
            // cout reel d'un talent (CoutReelTalent) : arg2 = cout de base, arg3 = « hors » (hors carriere)
            // et / ou « mj » (ajoute par le MJ), separes par une barre, ou vide
            Obtenu := IntToStr(CoutReelTalent(StrToIntDef(Champs[2], 0), Pos('hors', Champs[3]) > 0, Pos('mj', Champs[3]) > 0))
          else if Fonction = 'choixmetier' then
            // metier de remplacement propose pour le metier tire (DATA_SPECIE_CAREER_CHOICE) : metier/alternative/...
            Obtenu := StringReplace(ResultMetierRaceChoixMetier(Champs[3], Champs[2], ''), SeparateurMulti, '/', [rfReplaceAll]);
          Inc(NbCas);
          if Obtenu = Attendu then
            Sortie.Add('OK ' + Champs[0])
          else
            begin
              Inc(NbEchec);
              Sortie.Add(Format('ECHEC %s | %s(%s, %s, %s) | attendu=%s obtenu=%s | %s',
                [Champs[0], Fonction, Champs[2], Champs[3], Champs[4], Attendu, Obtenu, Champs[6]]));
            end;
        end;
    finally
      Tirage.Free;
      Champs.Free;
      Cas.Free;
    end;
  end;

procedure TMenu.LotCreer();
  // --creer <ethnie> <carriere> <nom> : CREER.txt. La fenetre n'est pas liberee (Close la met en file,
  // le programme s'arrete juste apres).
  Var
    Fenetre: TWinCreations;
    Rapport: TStringList;
  begin
    Rapport := TStringList.Create;
    try
      Fenetre := TWinCreations.Create(Application);
      // 5e parametre facultatif : code d'une regle optionnelle (DATA_RULE) a choisir dans le combo
      if ((ParamCount >= 5) and Fenetre.CreationAuto(ParamStr(2), ParamStr(3), ParamStr(4), Rapport, ParamStr(5)))
         or ((ParamCount < 5) and Fenetre.CreationAuto(ParamStr(2), ParamStr(3), ParamStr(4), Rapport)) then
        Rapport.Add('OK : ' + ParamStr(4) + ' enregistre')
      else
        Rapport.Add('ECHEC');
      Rapport.SaveToFile(GetCurrentDir + '\CREER.txt');
    finally
      Rapport.Free;
    end;
  end;

procedure TMenu.LotDumpPdf();
  // Meme chemin que LotPdfPersonnages, mais PdfTrace recueille chaque texte ecrit dans le PDF :
  // <sortie>\<perso>.pdf.txt, une ligne "y= x= texte" (mm), triee de haut en bas puis de gauche a droite.
  // Le PDF est aussi ecrit (dossier du perso), comme --pdf.
  Var
    Ind:        Integer;
    Chemin:     String;
    Personnage: StructurePersonnage;
  begin
    ForceDirectories(ParamStr(2));
    PdfSansOuverture := True;
    for Ind := 3 to ParamCount do
      begin
        Chemin := XmlPersonnageFichierActuel(GetCurrentDir+ConstCheminPersonnage+ParamStr(Ind));
        if Chemin = '' then
          Continue;
        Personnage := PersonnageXmlChargement(Chemin);
        PdfTrace   := TStringList.Create;
        try
          if Pos(AjouteAccolade(ConstXmlOptionFeldo2P), Personnage.Options) > 0 then
            PdfPersonnageCreationFeldo2P(Personnage)
          else
            PdfPersonnageCreation(Personnage, true);
          PdfTrace.Sort;
          PdfTrace.SaveToFile(IncludeTrailingPathDelimiter(ParamStr(2)) + ParamStr(Ind) + '.pdf.txt');
        finally
          FreeAndNil(PdfTrace);
        end;
      end;
  end;

procedure TMenu.LotDumpEcran();
  Var
    Ind:     Integer;
    Sortie:  TStringList;
    Fenetre: TWinPersonnages;
  begin
    ForceDirectories(ParamStr(2));
    for Ind := 3 to ParamCount do
      begin
        NomPersonnage := ParamStr(Ind);
        Sortie        := TStringList.Create;
        try
          Fenetre := TWinPersonnages.Create(Application);
          try
            Fenetre.DumpEcran(Sortie);
          finally
            Fenetre.Free;
          end;
          Sortie.SaveToFile(IncludeTrailingPathDelimiter(ParamStr(2)) + ParamStr(Ind) + '.ecran.txt');
        finally
          Sortie.Free;
        end;
      end;
  end;

procedure TMenu.LotDumpPersonnages();
  // Valeurs calculees d un personnage (memes fonctions que l ecran WinPersonnage et le PDF),
  // une ligne par valeur non nulle, dans <sortie>\<dossier personnage>.txt : sert a comparer
  // avant/apres une migration (diff) pour ce que le PDF ne montre pas. Aucune formule propre.
  Var
    Ind, IndA:  Integer;
    Dossier:    String;
    Chemin:     String;
    Code:       String;
    Personnage: StructurePersonnage;
    Copie:      StructurePersonnage;
    Sortie:     TStringList;
    TowDumpPerso: TStringList;
    Mutation:   StructurePersonnageMutation;
    Pathologie: StructurePersonnagePathologie;
    PersoTalent: StructurePersonnageTalent;

  procedure Ligne(Genre, Code: String; Valeurs: String);
    begin
      if Valeurs <> '' then
        Sortie.Add(Genre + ' ' + CodePersoStable(Code) + ' ' + Valeurs);
    end;

  function Val(Nom: String; Valeur: Integer): String;
    begin
      if Valeur <> 0 then
        Result := Nom + '=' + IntToStr(Valeur) + ' '
      else
        Result := '';
    end;

  begin
    Dossier := ParamStr(2);
    ForceDirectories(Dossier);
    Sortie  := TStringList.Create;
    try
      for Ind := 3 to ParamCount do
        begin
          Chemin := XmlPersonnageFichierActuel(GetCurrentDir+ConstCheminPersonnage+ParamStr(Ind));
          Sortie.Clear;
          if Chemin = '' then
            begin
              Sortie.Add('ABSENT');
              Sortie.SaveToFile(IncludeTrailingPathDelimiter(Dossier) + ParamStr(Ind) + '.txt');
              Continue;
            end;
          if ValVersion = 'WFRPTOW' then
            begin
              // format TOW a part : l ancien chargeur plante (access violation)
              TowDumpPerso := PersonnageTowDump(PersonnageXmlChargement(Chemin));
              try
                TowDumpPerso.SaveToFile(IncludeTrailingPathDelimiter(Dossier) + ParamStr(Ind) + '.txt');
              finally
                TowDumpPerso.Free;
              end;
              Continue;
            end;
          Personnage := PersonnageXmlChargement(Chemin);
          Sortie.Add('PERSONNAGE ' + Personnage.NomPersonnage);
          // Valeurs STOCKEES dans la fiche (pas de calcul) : identite, naissance, attributs,
          // competences, equipement. Permet de verifier une creation sans passer par le PDF.
          Sortie.Add('IDENTITE race=' + Personnage.Race + ' metier=' + Personnage.MetierEnCours.CodeMetier
            + ' niveau=' + IntToStr(Personnage.MetierEnCours.NiveauMetier) + ' sexe=' + Personnage.SexeV2
            + ' age=' + IntToStr(Personnage.Age) + ' taille=' + IntToStr(Personnage.Height)
            + ' poids=' + IntToStr(Personnage.PoidsV2) + ' fratrie=' + Personnage.FratrieV2);
          Sortie.Add('NAISSANCE ' + Personnage.NaissanceV2 + ' | astre=' + Personnage.AstreV2
            + ' | signe=' + Personnage.SigneDistinctifV2);
          // Signe astral (Archives II, balise StarSign) : ligne ecrite seulement s il y en a un
          if Personnage.SigneAstral <> '' then
            begin
              Sortie.Add('SIGNE-ASTRAL ' + Personnage.SigneAstral + ' variante=' + Personnage.SigneAstralVariante);
              if Personnage.SigneAstralTalent <> '' then
                Sortie.Add('SIGNE-ASTRAL-TALENT ' + CodePersoStable(Personnage.SigneAstralTalent));
            end;
          // Specialisations propres au personnage (<CUSTOM_ITEMS>, +Specialisation)
          if Personnage.ObjetsPropres <> '' then
            Sortie.Add('OBJETS-PROPRES ' + CodePersoStable(Personnage.ObjetsPropres));
          for IndA := 0 to High(Personnage.CreationAttribut) do
            Sortie.Add('STOCK-ATTR-CREATION ' + Personnage.CreationAttribut[IndA].CodeAttribut + ' valeur='
              + IntToStr(Personnage.CreationAttribut[IndA].Valeur) + ' bonus=' + Personnage.CreationAttribut[IndA].Bonus);
          for IndA := 0 to High(Personnage.AvanceGratuiteAttribut) do
            Sortie.Add('STOCK-ATTR-GRATUITE ' + Personnage.AvanceGratuiteAttribut[IndA].CodeAttribut + ' valeur='
              + IntToStr(Personnage.AvanceGratuiteAttribut[IndA].Valeur));
          for IndA := 0 to High(Personnage.AugmentationAttribut) do
            Sortie.Add('STOCK-ATTR-AUGMENTATION ' + Personnage.AugmentationAttribut[IndA].CodeAttribut + ' valeur='
              + IntToStr(Personnage.AugmentationAttribut[IndA].Valeur));
          for IndA := 0 to High(Personnage.CreationCompetence35) do
            Sortie.Add('STOCK-COMP-CREATION35 ' + Personnage.CreationCompetence35[IndA].CodeCompetence + ' valeur='
              + IntToStr(Personnage.CreationCompetence35[IndA].Valeur));
          for IndA := 0 to High(Personnage.CreationCompetence40) do
            Sortie.Add('STOCK-COMP-CREATION40 ' + Personnage.CreationCompetence40[IndA].CodeCompetence + ' valeur='
              + IntToStr(Personnage.CreationCompetence40[IndA].Valeur));
          for IndA := 0 to High(Personnage.MetierCompetence) do
            Sortie.Add('STOCK-COMP-METIER ' + Personnage.MetierCompetence[IndA].CodeCompetence + ' valeur='
              + IntToStr(Personnage.MetierCompetence[IndA].Valeur));
          for IndA := 0 to High(Personnage.AugmentationCompetence) do
            Sortie.Add('STOCK-COMP-AUGMENTATION ' + Personnage.AugmentationCompetence[IndA].CodeCompetence + ' valeur='
              + IntToStr(Personnage.AugmentationCompetence[IndA].Valeur));
          for IndA := 0 to High(Personnage.Equipement) do
            Sortie.Add('STOCK-EQUIPEMENT ' + Personnage.Equipement[IndA].TypeEquipement + ' '
              + Personnage.Equipement[IndA].CodeEquipement + ' porte=' + BoolToStr(Personnage.Equipement[IndA].Porte, True)
              + ' source=' + Personnage.Equipement[IndA].Source);
          for IndA := 0 to ListeAttribut.Count - 1 do
            begin
              Code := ListeAttribut[IndA].CodeAttribut;
              Ligne('ATTR', Code,
                Val('talent', PersonnageTalentAttributModif(Personnage, Code))
                + Val('mutation', PersonnageMutationAttributModif(Personnage, Code))
                + Val('affliction', PersonnageAfflictionAttributModif(Personnage, Code))
                + Val('maladie', PersonnageDiseaseAttributModif(Personnage, Code))
                + Val('arme', PersonnageArmeAttributModif(Personnage, Code))
                + Val('armure', PersonnageArmureBonusAttributModif(Personnage, Code))
                + Val('carriere', PersonnageCareerBonusAttributModif(Personnage, Code))
                + Val('unique', PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, Code)));
            end;
          for IndA := 0 to ListCompetence.Count - 1 do
            begin
              Code := ListCompetence[IndA].CodeCompetence;
              Ligne('COMP', Code,
                Val('modif', PersonnageCompetenceModificateur(Personnage, Code))
                + Val('carriere', PersonnageCareerBonusCompetenceModif(Personnage, Code))
                + Val('mutation', PersonnageMutationCompetenceModif(Personnage, Code)));
            end;
          for PersoTalent in Personnage.CreationTalent do
            begin
              Copie := Personnage;
              Ligne('TALENT-CREATION', PersoTalent.CodeTalent,
                'asterisque=' + IntToStr(PersonnageTalentAsterisque(Copie, PersoTalent.CodeTalent)) + ' ');
            end;
          for PersoTalent in Personnage.AugmentationTalent do
            begin
              Copie := Personnage;
              Ligne('TALENT-AUGMENTATION', PersoTalent.CodeTalent,
                'asterisque=' + IntToStr(PersonnageTalentAsterisque(Copie, PersoTalent.CodeTalent)) + ' ');
            end;
          // Niveau de carriere de chaque talent possede (colonne niveau de WinPersonnage).
          for PersoTalent in Personnage.CreationTalent do
            Ligne('TALENT-NIVEAU', PersoTalent.CodeTalent,
              'niveau=' + IntToStr(PersonnageTalentNiveauMetier(Personnage, PersoTalent.CodeTalent)) + ' ');
          for PersoTalent in Personnage.AugmentationTalent do
            Ligne('TALENT-NIVEAU', PersoTalent.CodeTalent,
              'niveau=' + IntToStr(PersonnageTalentNiveauMetier(Personnage, PersoTalent.CodeTalent)) + ' ');
          // Effets de talent (<Effet Cible=...>) et bonus de degats a distance (<Modificateur>),
          // memes fonctions que le PDF : Sturdy, Sprinter, Pure Soul, Accurate Shot.
          Ligne('EFFET', ConstCibleEffetDurACuire, Val('valeur', PersonnageTalentEffet(Personnage, ConstCibleEffetDurACuire)));
          Ligne('EFFET', ConstCibleEffetBonusEncomb, Val('valeur', PersonnageTalentEffet(Personnage, ConstCibleEffetBonusEncomb)));
          Ligne('EFFET', ConstCibleEffetBonusSprint, Val('valeur', PersonnageTalentEffet(Personnage, ConstCibleEffetBonusSprint)));
          Ligne('EFFET', ConstCibleEffetAmePure, Val('valeur', PersonnageTalentEffet(Personnage, ConstCibleEffetAmePure)));
          for IndA := 0 to ListTalentEffet.Count - 1 do
            Ligne('EFFET-DEFINI', ListTalentEffet[IndA].CodeTalent, ListTalentEffet[IndA].Cible + ' '
              + ListTalentEffet[IndA].Forme + ' ' + IntToStr(ListTalentEffet[IndA].Facteur) + ' ');
          Ligne('CORRUPTION-TOTAL', '-', Val('max', PersonnageCorruptionTotal(Personnage)));
          Ligne('DEGAT-CT', '-', Val('bonus', PersonnageModificateurUnique(Personnage,
                                    ConstXmlModifieDegat, ConstCibleModifieDegatCT, '', True)));
          for Mutation in Personnage.Mutations do
            Ligne('MUTATION', Mutation.Code, '[' + PersonnageMutationEffetTexte(Mutation) + ']');
          for Pathologie in Personnage.Pathologies do
            Ligne('PATHOLOGIE', Pathologie.Code, '[' + PersonnagePathologieEffetTexte(Pathologie) + ']');
          Sortie.SaveToFile(IncludeTrailingPathDelimiter(Dossier) + ParamStr(Ind) + '.txt');
        end;
    finally
      Sortie.Free;
    end;
  end;

procedure TMenu.ButtonPdfClick(Sender: TObject);
  Var
    Chemin: String;
    Personnage: StructurePersonnage;
  begin
    Chemin     := XmlPersonnageFichierActuel(GetCurrentDir+ConstCheminPersonnage+TabPersonnage.Cells[1, TabPersonnage.Row]);
    Personnage := PersonnageXmlChargement(Chemin);
    // Meme choix que le bouton PDF de WinPersonnage : l'option PdfFeldo2P de la fiche decide du gabarit.
    if Pos(AjouteAccolade(ConstXmlOptionFeldo2P), Personnage.Options) > 0 then
      PdfPersonnageCreationFeldo2P(Personnage)
    else
      PdfPersonnageCreation(Personnage, true);
  end;

procedure TMenu.ButtonMetierClick(Sender: TObject);
  begin
    // ouvrir les métiers
    FenMetier          := TWinMetiers.Create(Application);
    FenMetier.Position := poOwnerFormCenter;
    FenMetier.Show;
  end;

procedure TMenu.BoutonMetierClick(Sender: TObject);
begin
  FenMetier          := TWinMetiers.Create(Application);
  FenMetier.Position := poOwnerFormCenter;
  FenMetier.Show;

end;

procedure TMenu.BoutonRaceClick(Sender: TObject);
begin
  FenRace          := TWinRace.Create(Application);
  FenRace.Position := poOwnerFormCenter;
  FenRace.Show;
end;

procedure TMenu.ButtonXmlClick(Sender: TObject);
var
//  Ind:    Integer;
  PLivreTraduit: StructureLivreTraduit;
begin
//  For Ind := 1 to TabLivre.RowCount - 1 do
//  XmlExportBook(TabLivre.Cells[ColLivreCod, Ind], ConstAnglais);
    // L'export reecrit les livres depuis les listes en memoire, au format V4/V5 : les donnees V2
    // (sorts, equipement, carrieres...) y sortiraient sous une forme fausse. Rien n'est ecrit en WFRP2.
    if ValVersion = 'WFRP2' then
      begin
        if Sender <> nil then
          ShowMessage(GetTexteLibelle('RULES-MESS_072'));
        exit;
      end;
    if ValLangue = ConstAnglais then
      For PLivreTraduit in ListLivreTraduit do
        begin
          if PLivreTraduit.langue <> ConstAnglais then
            Traduit(PLivreTraduit.langue, PLivreTraduit.Livre);
          XmlExportBook(PLivreTraduit.Livre , PLivreTraduit.langue);
          if PLivreTraduit.langue <> ConstAnglais then
            Traduit(ConstAnglais, PLivreTraduit.Livre);
        end;
end;

procedure TMenu.ChargerPersonnages();
  var
    searchResult:  TSearchRec;
    directoryPath: string;
    i:             Integer = 0;
    Chemin:        String;
    Personnage:    StructurePersonnage;
    PTow:          StructurePersonnage;
    PMetier:       StructureMetier;
    PRace:         StructureRace;
    Livre:         String;
    LivreTab:      String;
    strings:       TStringList;
    Ind:           Integer;
    j:             Integer;
    LivreTrouve:   Boolean;
    NbDossiers:    Integer;
  begin
    // Remise à zéro avant rescan (13/09/2026, CONTEXT.md §2.70) : sans elle, TabPersonnage
    // ne fait qu'ajouter/écraser des lignes au fil des appels - au changement de version,
    // si le nouveau ConstCheminPersonnage pointe vers un dossier vide ou absent (cas de
    // SAVED_CARACTERS\WFRP5\ aujourd'hui), les personnages de l'édition précédente
    // restaient affichés (même symptôme que TabLivre, relevé par Nono en testant).
    TabPersonnage.RowCount := 1;
    directoryPath := GetCurrentDir + ConstCheminPersonnage;

    // Lecture du XML de chaque personnage = lente : compte d'abord les dossiers pour la
    // barre de chargement, et fige le dessin de la grille pendant le remplissage (elle se
    // redessinait a chaque ligne, d'ou une barre « finie » avant le tableau complet).
    NbDossiers := 0;
    if FindFirst(directoryPath + DirectorySeparator + '*', faDirectory, searchResult) = 0 then
      begin
        repeat
          if ((searchResult.Attr and faDirectory) = faDirectory) and (searchResult.Name <> '.') and (searchResult.Name <> '..') then
            Inc(NbDossiers);
        until FindNext(searchResult) <> 0;
        FindClose(searchResult);
      end;
    ChargementDebut(GetTexteLibelle('RULES-MESS_120'), NbDossiers);
    TabPersonnage.BeginUpdate;
    try
    if FindFirst(directoryPath + DirectorySeparator + '*', faDirectory, searchResult) = 0 then
    begin
      repeat
        if ((searchResult.Attr and faDirectory) = faDirectory) and (searchResult.Name <> '.') and (searchResult.Name <> '..') then
        begin
          ChargementAvance(searchResult.Name);
          i                         := i + 1;
          TabPersonnage.RowCount    := i + 1;
          TabPersonnage.Cells[ColPersoNom, I] := searchResult.Name;
          Chemin     := PersonnageXmlFichierActuel(directoryPath + searchResult.Name);
          if Chemin = '' then
            begin
              // Dossier de personnage sans fichier XML dedans (creation interrompue,
              // ex. nom termine par un espace : CreateDir tronque silencieusement le
              // dossier mais l'ecriture du XML avec le nom non tronque echoue ensuite).
              // PersonnageXmlChargement('') plante sans ce garde-fou - et comme ce
              // rescan tourne a chaque demarrage, le programme ne se rouvrait plus du
              // tout tant que le dossier vide restait sur le disque. On ignore la ligne.
              i                      := i - 1;
              TabPersonnage.RowCount := i + 1;
              Continue;
            end;
          if ValVersion = 'WFRPTOW' then
            begin
              // perso TOW : le chargeur commun suffit, l ancien chargeur V1-V5 ne lit pas ses champs
              PTow := PersonnageXmlChargement(Chemin);
              TabPersonnage.Cells[ColPersoWor, I] := TowLibelleDe(PTow.MetierEnCours.CodeMetier);
              TabPersonnage.Cells[ColPersoRac, I] := TowLibelleDe(PTow.Race);
              TabPersonnage.Cells[ColPersoNiv, I] := '1';
              TabPersonnage.Cells[ColPersoTXp, I] := IntToStr(PTow.XpTotal);
              TabPersonnage.Cells[ColPersoCXp, I] := IntToStr(PTow.XpActuel);
              Continue;
            end;
          if not PersonnageResumeFichier(Chemin, Personnage) then
            Personnage := PersonnageXmlChargement(Chemin);
          PMetier    := chercheMetier(Personnage.MetierEnCours.CodeMetier);
          PRace      := chercheRace(Personnage.Race);
          TabPersonnage.Cells[ColPersoWor, I] := PMetier.Libelle;
          TabPersonnage.Cells[ColPersoRac, I] := PRace.Libelle;
          TabPersonnage.Cells[ColPersoNiv, I] := IntToStr(Personnage.MetierEnCours.NiveauMetier);
          TabPersonnage.Cells[ColPersoTXp, I] := Format('%.0n',[Personnage.XpTotal/1]);
          TabPersonnage.Cells[ColPersoCXp, I] := Format('%.0n',[Personnage.XpActuel/1]);
          TabPersonnage.Cells[ColPersoLOb, I] := Personnage.LivresObligatoires;

          strings       := TStringList.Create;
          ExtractStrings(['['], [], PChar(Personnage.LivresObligatoires), Strings);
          for Ind := 0 to (Strings.count - 1) Do
            begin
              LivreTrouve := False;
              Livre       := Strings[ind];
              Livre       := StringReplace(StringReplace(Livre, '[', '', [rfReplaceAll]), ']', '', [rfReplaceAll]);
              For J := 1 to TabLivre.RowCount - 1 Do
                begin
                  LivreTab := TabLivre.Cells[ColLivreCod, J];
                  if (LivreTab = Livre) and (TabLivre.Cells[ColLivreSel, J] = ConstSelectionne) then
                    begin
                      LivreTrouve := True;
                      Break;
                    end;
                end;
              If LivreTrouve = false then
                TabPersonnage.Cells[ColPersoLNe, I] := TabPersonnage.Cells[ColPersoLNe, I] + AjouteAccolade(Livre);
            end;
            Strings.Free;
        end;
      until FindNext(searchResult) <> 0;
      FindClose(searchResult);
    end;
    finally
      TabPersonnage.EndUpdate;
      ChargementFin;
    end;
    AdjustGridColumnsWidth(TabPersonnage, Self.Height, true, true, True, 0, 0);

    // Cet AdjustGridColumnsWidth (marge 0, differente des appels marge 10 de FormCreate)
    // peut retrecir TabPersonnage.Width en dehors de tout redimensionnement de fenetre -
    // ChargerPersonnages est rappelee hors FormCreate (FormActivate, si NeedUpdate), donc
    // apres que l'ancrage de la fenetre (AjustePositionFenetre) a deja pose sa reference.
    // Sans ce rappel, TabPersonnage se retrouvait plus etroite que ce que Button1/la
    // colonne Bibliotheque attendaient - Button3/TabPersonnage.Left etc. restant calcules
    // sur l'ancienne largeur, chevauchement releve par Nono le 15/09/2026 en agrandissant
    // la fenetre (voir Log.txt). Reancre tout depuis l'etat courant, quoi que
    // AdjustGridColumnsWidth ait pu faire deriver.
    AjustePositionFenetre();

    // Définir le chemin du répertoire
    directoryPath := GetCurrentDir + ConstCheminPersonnage;
  end;

end.


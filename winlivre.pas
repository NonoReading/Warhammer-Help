unit WinLivre;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, ExtCtrls, Menus,
  Dialogs, MessageTest, Graphics, BCButton, ChargeConstantes, ChargeModificateur, ChargeTexte, ChargeCompetence, ChargeTalent, ChargeSort, ChargeMetier, ChargeMetierEquipement, ChargeLivre, ChargeArme, ChargeArmure, ChargeTrapping, ChargeRace, ChargeEspece, ChargeRegle, ChargeTirageMetier, UnitCalcul, PanelModificateurs, PanelFiche, PanelQualites, PanelTirage, PanelEquipClasse, PanelTraitEthnie, PanelCarriereEspece, PanelRegleEthnie, PanelSousMetier, PanelSigneEffets, PanelCarriereV1, PanelCarrieresCoches, PanelListeChoix, PanelSousBlocs, PanelTexteListe, PanelLignesV1, PanelBonusCarriere, PanelAdaptation, PanelRaceExtra, PanelNoms, PanelTraduction, PanelImageLivre, Grids,
  Generics.Collections, DOM, XMLRead, XMLWrite, FGL, GlobalFonts, BCLabelContour;

type
  // Structure pour stocker les données du XML
  TRaceData = record
    Code: String;
    Libelle: String;
    Description: String;
  end;
  
  PRaceData = ^TRaceData;
  TRaceDataMap = specialize TFPGMap<String, PRaceData>;
  
  // Structure pour les attributs
  TAttributData = record
    Code: String;
    Libelle: String;
    Valeur: String;  // "2d10+20" ou "1xBATTR_S+2xBATTR_T..."
  end;
  
  PAttributData = ^TAttributData;
  TAttributDataMap = specialize TFPGMap<String, PAttributData>;
  
  // Structure pour les composants d'une formule calculée
  TFormulaComponent = record
    Coefficient: Integer;     // 1, 2, 0, etc.
    AttrCode: String;         // BATTR_S, BATTR_T, BATTR_WP
    AttrLabel: String;        // "Strength", "Toughness", etc.
  end;
  
  TFormulaComponentArray = array of TFormulaComponent;

const
  // Préfixes d'affichage de l'équipement dans l'arbre (comme dans WinMetier)
  EquipArme   = '(W) ';
  EquipArmure = '(P) ';
  EquipDivers = '(D) ';

const
  // Types de noeud de l'arbre de WinLivre (TNodeInfo.TypeNode). Les valeurs sont celles
  // historiques : ne pas renumeroter sans relire tous les SetNodeInfo/GetNodeType.
  NT_CHAPITRE                   = 0;
  NT_RACE                       = 1;
  NT_ATTRIBUT                   = 2;
  NT_COMPETENCES_RACE           = 3;
  NT_COMPETENCE                 = 4;
  NT_TALENTS_RACE               = 5;
  NT_TALENT_ALEATOIRE           = 6;
  NT_CHOIX                      = 7;
  NT_TALENT_CHOIX               = 8;
  NT_CARRIERES_RACE             = 9;
  NT_TALENT_FIXE                = 10;
  NT_CHOIX_TALENT               = 11;
  NT_CHOIX_ITEM                 = 12;
  NT_CARRIERE                   = 13;
  NT_METIER_NIVEAU1             = 14;
  NT_RACES_POSSIBLES            = 15;
  NT_RACE_POSSIBLE              = 16;
  NT_NIVEAU_METIER              = 17;
  NT_BRANCHE_ATTRIBUT_NIVEAU    = 18;
  NT_ATTRIBUT_NIVEAU            = 19;
  NT_BRANCHE_COMPETENCE_NIVEAU  = 20;
  NT_COMPETENCE_NIVEAU          = 21;
  NT_BRANCHE_TALENT_NIVEAU      = 22;
  NT_TALENT_NIVEAU              = 23;
  NT_BRANCHE_EQUIPEMENT_NIVEAU  = 24;
  NT_EQUIPEMENT_NIVEAU          = 25;
  NT_COMPETENCE_N1              = 26;
  NT_SPECIALISATION_COMPETENCE  = 27;
  NT_TALENT_N1                  = 28;
  NT_SPECIALISATION_TALENT      = 29;
  NT_ARME                       = 30;
  NT_ARMURE                     = 31;
  NT_QUALITE_ARME               = 32;
  NT_ARMURE_SIMPLIFIEE          = 33;
  NT_QUALITE_ARMURE             = 34;
  NT_SORT                       = 35;
  NT_TIRAGE_RACE                = 36;
  NT_INFO_LIVRE                 = 37;
  NT_TRAPPING                   = 38;
  NT_FABRICATION                = 39;
  NT_NATION                     = 40;
  NT_OPTION_REGLE               = 41;
  NT_CORRUPTION_PHYSIQUE        = 42;
  NT_CORRUPTION_MENTALE         = 43;
  NT_MALADIE                    = 44;
  NT_AFFLICTION                 = 45;
  NT_TABLE_VALEURS              = 53;
  NT_ATTRIBUTS_ETHNIE           = 54;
  NT_CORRUPTION_ETHNIE          = 55;
  NT_NIVEAUX_CARRIERE           = 56;
  NT_RACE_GROUPE                = 57;
  NT_CONDITION                  = 58;
  NT_EQUIP_CLASSE               = 59;
  NT_SIGNE_ASTRAL               = 60;
  NT_TRAIT_ETHNIE               = 61;
  NT_BONUS_CARRIERE             = 62;
  NT_ADAPTATION_CARRIERE        = 63;
  NT_LIEN_CARRIERE_ESPECE       = 64;
  NT_SECOND_JET                 = 65;
  NT_COMPETENCE_V2              = 66;  // competence WFRP2 : fiche texte, consultation seule (CONTEXT.md 2.122)
  NT_TALENT_V2                  = 67;  // talent WFRP2 : idem
  NT_SORT_V2                    = 68;  // sort WFRP2 : idem, regroupe par domaine (Lore)
  NT_EQUIPEMENT_V2              = 69;  // article d'equipement WFRP2 : idem, regroupe par table (Category)
  NT_REGLE_ETHNIE               = 70;  // regles qui remplacent competences et talents d'une ethnie (DATA_RULE_SPECIE)
  NT_SORT_V1                    = 71;  // sort WFRP1 (DATA_SPELL_V1) : fiche editable, regroupe par liste (SpellList)
  NT_COMPETENCE_V1              = 72;  // competence WFRP1 (DATA_SKILL_V1, balise <Skill>) : fiche editable
  NT_EQUIPEMENT_V1              = 73;  // objet WFRP1 (DATA_EQUIPMENT_V1) : fiche editable, regroupe par Category
  NT_DIEU_V1                    = 74;  // divinite WFRP1 (DATA_DEITY_V1, balise <Deity>) : fiche editable (textes ; acces aux sorts / competences non montres)
  NT_CULTE_V1                   = 75;  // culte WFRP1 (DATA_CULT_V1, balise <Cult>) : fiche editable (nom ; prieres non montrees)
  NT_CLASSE_V1                  = 77;  // classe WFRP1 (DATA_CLASS_V1, balise <Class>) : fiche editable (textes ; exigences non montrees)
  NT_METIER_V1                  = 78;  // metier d'artisan WFRP1 (DATA_TRADE_V1, balise <Trade>) : fiche editable (nom, plage ; competences non montrees)
  NT_HANDICAP_V1                = 79;  // handicap WFRP1 (DATA_DISABILITY_V1, balise <Disability>) : fiche editable (nom, texte ; stades non montres)
  NT_LIGNE_TABLE_V1             = 80;  // ligne sans id d'une table WFRP1 (tirages, ages, disponibilite...) : fiche editable, champs tires de ses balises
  NT_CORRUPTION_V2              = 82;  // corruption WFRP2 (DATA_CORRUPTION_TABLE_MUTATION / _DIVINE, balise <Corruption name>) : fiche generique
  NT_LIBELLE_LIVRE              = 83;  // libelle du livre (DATA_LABEL / Label language / Text name), code du noeud = LANGUE|nom : fiche code + texte
  NT_ATTRIBUT_V1                = 81;  // caracteristique WFRP1 (DATA_ATTRIBUT, balise <Attribut id>) : fiche editable (textes, abreviation, ordre)
  NT_ENTREES_CARRIERE           = 84;  // branche « metiers d'entree » d'une carriere WFRP2 : cases a cocher (Entries)
  NT_SORTIES_CARRIERE           = 85;  // branche « metiers de sortie » d'une carriere WFRP2 : cases a cocher (Exits + ExitCodes)
  NT_CARAC_CARRIERE             = 86;  // branche « caracteristiques » d'une carriere WFRP2 : profils du livre + tableau Advances
  NT_COMPETENCES_CARRIERE       = 87;  // branche « competences » d'une carriere WFRP2 : tableau a alternatives (SUBCHAPTER_SKILL)
  NT_TALENTS_CARRIERE           = 88;  // branche « talents » d'une carriere WFRP2 : tableau a alternatives (SUBCHAPTER_TALENT)
  NT_EQUIPEMENT_CARRIERE        = 89;  // branche « equipement » d'une carriere WFRP2 : tableau (SUBCHAPTER_ITEM)
  NT_FAMILIER_V1                = 76;  // familier WFRP1 (DATA_FAMILIAR_V1, balise <Familiar>) : fiche editable (textes ; competences et regime non montres)
  // 46 a 52 : petites tables a entrees nommees (index PetitesTablesChapitre = type - NT_PETITE_TABLE_DEBUT)
  NT_PETITE_TABLE_DEBUT = 46;
  NT_PETITE_TABLE_FIN   = 52;

type
  
  // Information portée par chaque noeud du TreeView.
  // Remplace l'ancien Node.Data := Pointer(PtrInt(type)) : on garde le type
  // ET le code de l'élément, ce qui permettra de remonter vers le XML.
  TNodeInfo = class
    TypeNode: Integer;
    Code:     String;
    Chapitre: String;  // balise du chapitre pour une branche (cle de l'encart explicatif RULES-HELP_BRANCHE_<balise>)
  end;

  TListeChampsFiche = array of StructureChampFiche;

  TWinLivres = class(TForm)
    // Panels
    PanelLeft: TPanel;
    PanelRight: TPanel;
    SplitterMain: TSplitter;
    
    // Left Side - TreeView
    PanelTopButtons: TPanel;
    LabelLivre: TLabelContour;
    ButtonChargerXML: TBCButton;
    ButtonEnregistrerTravail: TBCButton;
    ButtonPublierRevision: TBCButton;
    ButtonNouvelleTraduction: TBCButton;  // cree un livre de traduction vide dans une nouvelle langue
    ButtonMettreAJour: TBCButton;  // remplace le livre dans les listes globales du moteur par l'ebauche
    ButtonFinaliser: TBCButton;  // COMPLETE 0 -> 1 : le livre inacheve devient un livre propose aux joueurs
    TreeViewLivre: TTreeView;
    
    // Right Side - Form dynamique
    LabelFormTitle: TLabelContour;
    ScrollBox: TScrollBox;
    GroupBoxForm: TGroupBox;
    
    // Attribute Controls (hidden until attribute selected)
    LabelFormAttrName: TLabelContour;
    EditFormAttrName: TEdit;
    LabelFormAttrDices: TLabelContour;
    EditFormAttrDices: TEdit;
    LabelFormAttrBaseValue: TLabelContour;
    EditFormAttrBaseValue: TEdit;
    LabelFormAttrFormula: TLabelContour;
    EditFormAttrFormula: TEdit;
    
    // Component Controls for calculated attributes (up to 3 components)
    LabelFormComponent1: TLabelContour;
    EditFormComponent1Attr: TEdit;
    EditFormComponent1Coeff: TEdit;
    LabelFormComponent2: TLabelContour;
    EditFormComponent2Attr: TEdit;
    EditFormComponent2Coeff: TEdit;
    LabelFormComponent3: TLabelContour;
    EditFormComponent3Attr: TEdit;
    EditFormComponent3Coeff: TEdit;
    
    // Skills Grid (hidden until skills section selected)
    LabelFormSkills: TLabelContour;
    StringGridSkills: TStringGrid;
    StringGridCareers: TStringGrid;
    StringGridRaces: TStringGrid;
    StringGridAttributs: TStringGrid;
    StringGridCompetences: TStringGrid;
    StringGridTalents: TStringGrid;
    StringGridEquipement: TStringGrid;
    StringGridDetail: TStringGrid;
    StringGridQualites: TStringGrid;
    MemoDetail: TMemo;
    // Attributs d'une ethnie : dés + valeur fixe, 4 valeurs simples, coefficients des Blessures
    StringGridAttrEthnie: TStringGrid;
    StringGridAttrSimples: TStringGrid;
    StringGridAttrBlessures: TStringGrid;
    LabelAttrBlessures: TLabelContour;
    LabelTotalCareers: TLabelContour;
    PanelAttrBoutons: TPanel;
    ButtonAttrValider: TBCButton;
    ButtonAttrAnnuler: TBCButton;

    // Talents (to be created in code)
    LabelTalentsRandom: TLabel;
    TreeViewTalents: TTreeView;
    
    // Buttons
    
    // PopupMenu
    PopupMenuTree: TPopupMenu;
    MenuItemAjouter: TMenuItem;
    MenuItemModifier: TMenuItem;
    MenuItemSupprimer: TMenuItem;
    MenuItemDeplierBranche: TMenuItem;
    MenuItemReplierBranche: TMenuItem;
    MenuItemNouvelleDivinite: TMenuItem;
    MenuItemNouveauCulte: TMenuItem;
    MenuItemNouveauSortV1: TMenuItem;
    MenuItemNouvelObjetV1: TMenuItem;
    MenuItemNouvelleClasse: TMenuItem;
    MenuItemNouveauHandicap: TMenuItem;
    MenuItemNouveauFamilier: TMenuItem;
    MenuItemLigneNouvelle: TMenuItem;
    MenuItemLigneDupliquer: TMenuItem;
    MenuItemLigneSupprimer: TMenuItem;
    MenuItemNouvelleRace: TMenuItem;
    MenuItemNouvelleCompetence: TMenuItem;
    MenuItemNouveauTalent: TMenuItem;
    MenuItemNouvelleArme: TMenuItem;
    MenuItemNouvelleSpecialisation: TMenuItem;
    MenuItemNouvelleSpecTalent: TMenuItem;
    
    // Événements
    procedure FormCreate(Sender: TObject);
    procedure ButtonQuestionClick(Sender: TObject);
    procedure CreerPanneauxDetail;
    procedure AjouterEntreeMenu(Popup: TPopupMenu; var Entree: TMenuItem; Clic: TNotifyEvent);
    procedure InitTalentsUI();
    procedure FormShow(Sender: TObject);
    procedure ButtonChargerXMLClick(Sender: TObject);
    function  LangueExportOk: Boolean;
    function  EstLivreTraduction: Boolean;
    procedure AfficherTraduction;
    procedure TraductionEnregistrerClick(Sender: TObject);
    procedure ButtonNouvelleTraductionClick(Sender: TObject);
    procedure ButtonEnregistrerTravailClick(Sender: TObject);
    procedure ButtonPublierRevisionClick(Sender: TObject);
    procedure ButtonFinaliserClick(Sender: TObject);
    procedure ButtonMettreAJourClick(Sender: TObject);
    procedure MajBoutonFinaliser;
    function  LivreInacheve: Boolean;
    function DossierTravailLivre(AFilePath: String): String;
    function DerniereVersionTravail(AFilePath: String): String;
    procedure TreeViewLivreChange(Sender: TObject; Node: TTreeNode);
    procedure TreeViewLivreChanging(Sender: TObject; Node: TTreeNode; var AllowChange: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    function ConfirmerAbandonModifs: Boolean;
    procedure GridNiveauPrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure TreeViewLivreDblClick(Sender: TObject);
    procedure GridNiveauxDblClick(Sender: TObject);
    procedure TreeViewLivreContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure PopupMenuTreePopup(Sender: TObject);
    procedure MenuItemAjouterClick(Sender: TObject);
    procedure MenuItemModifierClick(Sender: TObject);
    procedure MenuItemSupprimerClick(Sender: TObject);
    procedure MenuDeplierBrancheClick(Sender: TObject);
    procedure MenuReplierBrancheClick(Sender: TObject);
    function NoeudGroupeV1(Node: TTreeNode; TypeFeuille: Integer): TTreeNode;
    procedure CreerElementV1(Chap, NomTag, Infixe, ChampNom, CodeLibBranche, CodeLibTitre: String;
      TypeFeuille: Integer; const AutresChamps: array of String; GroupeNoeud: TTreeNode = nil);
    procedure MenuNouveauSortV1Click(Sender: TObject);
    procedure MenuNouvelObjetV1Click(Sender: TObject);
    procedure MenuNouvelleDiviniteClick(Sender: TObject);
    procedure MenuNouveauCulteClick(Sender: TObject);
    procedure MenuNouvelleClasseClick(Sender: TObject);
    procedure MenuNouveauHandicapClick(Sender: TObject);
    procedure MenuNouveauFamilierClick(Sender: TObject);
    procedure ModifierLigneTable(Operation: Integer);  // 0 nouvelle, 1 dupliquer, 2 supprimer
    procedure MenuLigneNouvelleClick(Sender: TObject);
    procedure MenuLigneDupliquerClick(Sender: TObject);
    procedure MenuLigneSupprimerClick(Sender: TObject);
    procedure ButtonAttrValiderClick(Sender: TObject);
    procedure ButtonAttrAnnulerClick(Sender: TObject);
    procedure GridAttrEthnieSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GridAttrEthnieSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: string);
    function InstantaneAttrEthnie(Substitue: TObject; aCol, aRow: Integer; const Val: String): String;
    procedure MajBoutonsAttr(Modifie: Boolean);
    procedure FermerEditeursAttr;
    procedure AfficherInfosLivre();
    function  RangerDisclaimer: Boolean;

  private
    // Variables
    XMLDoc: TXMLDocument;
    CurrentFilePath: String;  // Chemin complet du XML charge (sert a l'enregistrement)
    DerniereEbauche: String;  // Ebauche du dernier Update reussi (etat de restauration), vide = fichier de DATABASE
    AttrRaceCode: String;  // Ethnie dont les attributs sont affiches dans les tableaux
    PopupMenuSkills: TPopupMenu;  // Menu contextuel du tableau des competences d'une ethnie
    MenuSkillAjouter, MenuSkillSupprimer, MenuSkillFusionner, MenuSkillScinder, MenuSkillRetirer: TMenuItem;
    RowSkillCtx: Integer;  // Ligne sous le clic droit
    AttrNiveauxValides: TStringList;  // niveaux declares de la carriere (+ 0) pour la colonne Niv. des attributs
    PanelBonus: TPanelModificateurs;  // bonus/malus d'un talent ou d'une qualite : une ligne par balise Modify* / Modificateur
    ComboCompLieeFiche: TComboBox;  // competence liee d'un talent (remplace EditFormCompPrinc)
    CodesCompLieeFiche: TStringList;
    QualCodesAvecValeur: TStringList;  // qualites a valeur obligatoire (<NeedsValue>) du Rulebook et du livre ouvert
    CodesConditions: TStringList;  // conditions (if=) declarees par le Rulebook et le livre ouvert (DATA_CONDITION)
    BenedInit: String;  // benedictions cochees a l'ouverture de la fiche d'un dieu (seuls les changements sont reecrits)
    PanelQualitesArme: TPanelQualitesLiees;  // qualites liees (arme ; armure ensuite)
    QualLibelles, QualCodes: TStringList;  // qualites d'arme proposees : libelle affiche / code ecrit
    RulebookBaseDoc: TXMLDocument;  // Rulebook anglais complet (le fichier de langue ne porte que des textes, ni TypSpell ni lignes de DATA_SPELL_TALENT)
    RulebookDoc: TXMLDocument;  // Rulebook de l'edition du livre ouvert, lu une fois (RulebookXML)
    RulebookEssaye: Boolean;
    RulebookLangue: String;  // langue du Rulebook en memoire
    RulebookDossier: String;  // dossier (= edition) dont viennent RulebookDoc / RulebookBaseDoc
    RulebookTextes: TStringList;  // ses <Text> : code=libelle
    MenuItemNouvelleArmure: TMenuItem;
    MenuItemNouveauTrapping: TMenuItem;
    MenuItemNouvelleMaladie: TMenuItem;
    MenuItemNouvelleAffliction: TMenuItem;
    MenuItemNouveauSigne: TMenuItem;
    PanelCarriereV1: TPanelCarriereV1;  // schema d'avancement et competences d'une carriere WFRP1
    PanelBonusCompetenceV1: TPanelSousBlocs;  // <Bonus> d'une competence WFRP1
    PanelCulteV1: TPanelSousBlocs;            // <Prayer> et <Gift> d'un culte WFRP1
    PanelCochesCarriere: array[0..1] of TPanelCarrieresCoches;  // 0 = metiers d'entree, 1 = metiers de sortie (carriere WFRP2)
    PanelListesCarriere: array[0..4] of TPanelListeChoix;  // 0 = Advances, 1 = competences, 2 = talents, 3 = equipement (carriere WFRP2), 4 = equipement (carriere WFRP1)
    FicheCoches: Integer;     // 0 = fiche normale d'une carriere, sinon branche : 1 entrees, 2 sorties, 3 caracteristiques, 4 competences, 5 talents, 6 equipement
    PanelCarriereV2: TPanelSousBlocs;        // Advances / SUBCHAPTER_ITEM / SUBCHAPTER_SKILL / SUBCHAPTER_TALENT d'une carriere WFRP2
    PanelDieuV1: TPanelSousBlocs;            // <SpellAccess> et <SkillAccess> d'une divinite WFRP1
    PanelClasseV1: TPanelSousBlocs;           // <Requirement> d'une classe WFRP1
    PanelHandicapV1: TPanelSousBlocs;         // <Permanent> et <Stage> d'un handicap WFRP1
    PanelMetierV1: TPanelSousBlocs;           // <Skill> et <ExitCode> d'un metier d'artisan WFRP1
    PanelTableauxGen: TPanelSousBlocs;        // balises repetees <Balise name="x">"v"</Balise> d'une fiche generique : un tableau par balise (recree a chaque fiche)
    AnnexesTableauGen: TStringList;           // balises rattachees a un tableau (BirthplaceHuman -> Birthplace), meme rang que BalisesTableauGen ('' = aucune)
    ConteneurTableauGen: String;              // bloc de la fiche qui porte ces balises ('' = l'element)
    BalisesTableauGen: TStringList;           // balises de la fiche generique en cours qui passent en tableau
    PanelEffetTalent: TPanelSousBlocs;        // <Effet Cible Forme Facteur Carac> d'un talent (drapeaux du moteur)
    FTimerFamille: TTimer;                    // differe la reconstruction de la fiche talent apres le clic sur une famille
    FamillesTalent: String;                   // familles cochees dans la fiche talent (MAGIE, MOTEUR, NIVEAU), jamais ecrites dans le XML
    FTalentElement: TDOMElement;              // talent affiche, pour reconstruire la fiche apres un changement de famille
    FTalentEtranger: Boolean;
    PanelQualitesV2: TPanelTexteListe;        // <Qualities> d'un objet WFRP2 : un mot par ligne, liste deroulante
    PanelLignesObjetV1: TPanelLignesMulti;    // objet WFRP1 : modificateurs de combat (Modificateur | Valeur) puis bandes de portee (Bande | Distance | ES)
    PanelTableCout: TPanelSousBlocs;          // <Cost name="plage"> de DATA_SKILL_COST / DATA_ATTRIBUT_COST
    PanelTableChance: TPanelSousBlocs;        // <Chance name="plage"> de DATA_CORRUPTION_PHYSICAL / MENTAL_CHANCE
    PanelTableChoix: TPanelSousBlocs;         // <Choice Specie Career Alternative> de DATA_SPECIE_CAREER_CHOICE
    PanelLiensCarriere: TPanelSousBlocs;      // <Link name="carriere 1">"carriere 2"</Link> de DATA_CAREER_LINK_V1 (WFRP1)
    PanelSigneEffets: TPanelSigneEffets;  // effets (Modifier) d'un signe astral, sous les champs de sa fiche
    MenuItemNouveauBonus: TMenuItem;
    PanelBonusCarriere: TPanelBonusCarriere;  // paliers d'un bonus de carriere, sous les champs de sa fiche
    PanelNoms: TPanelNoms;  // noms d'une ethnie (modeles, regles, tables), sous les champs de sa fiche
    PanelRaceExtra: TPanelRaceExtra;  // opinions et details physiques d'une race, sous les champs de sa fiche
    PanelAdaptation: TPanelAdaptation;  // substitutions d'une adaptation de carriere, sous les champs de sa fiche
    MenuItemNouvelleAdaptation: TMenuItem;
    MenuItemNouvelleMutation: TMenuItem;
    MenuItemNouvelleNation: TMenuItem;
    MenuItemNouvelleCondition: TMenuItem;
    MenuItemNouvelleFabrication: TMenuItem;
    MenuItemNouvelleQualite: TMenuItem;
    PanelTirage: TPanelTirageTalent;  // matrice des tirages de talents (DATA_RANDOM_TALENT) : talent x ethnie
    PanelTirageMetier: TPanelTirageMetier;  // matrice du tirage des metiers d'une regle (DATA_CAREER_ROLL) : metier x ethnie ou race
    PanelTirageRace: TPanelTirageRace;  // table du tirage de race (DATA_RANDOM_SPECIE) : race, debut, fin
    PanelSousMetier: TPanelSousMetier;  // second jet apres le metier (DATA_CAREER_SUBCHOICE) : depart, obtenu, fourchette
    PanelTraduction: TPanelTraduction;  // livre de traduction : grille anglais / langue du livre (lecture seule)
    PanelImageLivre: TPanelImageLivre;  // apercu + remplacement de l'image d'une ethnie / d'une carriere
    PanelCarriereEspece: TPanelCarriereEspece;  // liens carriere <-> espece (DATA_CAREER_SPECIE) : espece, carriere
    TestSansMessage: Boolean;  // test --winlivretest : les validateurs ne montrent aucune boite de dialogue
    PanelRegleEthnie: TPanelRegleEthnie;  // regles par ethnie (DATA_RULE_SPECIE) : regle, ethnie, competence ou talent
    PanelTraitEthnie: TPanelTraitEthnie;  // traits d'ethnie (DATA_SPECIE_TRAIT) : trait, option, groupes de talents
    PanelEquipClasse: TPanelEquipClasse;  // equipement de depart par classe (DATA_CLASS_ITEM) : classe, objet, quantite
    PanelFiche: TPanelFiche;  // fiche generique : champs propres a l'element + grille des modificateurs + Valider/Annuler
    FicheTag: String;         // balise de l'element affiche dans PanelFiche
    FicheTypeNoeud: Integer;  // type de noeud de l'arbre correspondant
    FicheGenerique: Boolean;  // la fiche affichee est la fiche generique WFRP1 (AfficherFicheGeneriqueV1)
    MenuItemNouveauSort: TMenuItem;
    FicheSnapshot: String;  // contenu des champs d'une fiche ou d'un panneau modifiable a l'affichage ('' = rien a perdre)
    TimerFiche: TTimer;  // grise/degrise Valider et Annuler selon FicheSnapshot
    TalSortLib, TalSortCodes: TStringList;  // talents proposes pour l'acces a un sort (libelle, code)
    ModeEquipCarriere: Boolean;// StringGridAttrEthnie affiche l'equipement d'une carriere (nom, quantite, niveau)
    ModeAttrCarriere: Boolean;  // StringGridAttrEthnie affiche les attributs d'une carriere (niveau d'acquisition)
    ModeNiveaux: Boolean;  // StringGridAttrEthnie affiche les niveaux d'une carriere (nom, salaire)
    AttrColW: array[0..2] of Integer;  // largeurs d'origine des colonnes de StringGridAttrEthnie
    PopupMenuNiveaux: TPopupMenu;
    MenuNivFin, MenuNivDebut, MenuNivSupprimer: TMenuItem;
    MenuEquipArme, MenuEquipArmure, MenuEquipDivers: TMenuItem;  // choix dans le catalogue (equipement d'une carriere)
    RowNivCtx: Integer;
    ModeCarriere: Boolean;  // StringGridSkills affiche les competences/talents d'une CARRIERE (colonne Niv.)
    NbNiveauxCarriere: Integer;
    AttrCodeNiveau: String;  // "CARRIERE|niveau" du noeud affiche en ModeCarriere
    ModeCorruption: Boolean;  // les tableaux d'attributs affichent les tranches de corruption de l'ethnie
    ModeTalents: Boolean;  // StringGridSkills affiche les talents de l'ethnie au lieu de ses competences
    AttrSnapshot: String;  // Contenu des cellules modifiables a l'affichage : sert a detecter un changement
    RacesDataList: TRaceDataMap;
    AttributesDataList: TAttributDataMap;  // Attributs de la race actuelle
    AttributeValuesMap: TStringList;  // Map attribute codes to raw values
    MetierRacesMap: TStringList;  // CODE_METIER=CodeRace1|CodeRace2|...
    NiveauCourantAffiche: Integer;  // niveau mis en évidence dans les grilles
    RaceSkillsData: TStringList;        // Compétences de la race sélectionnée
    RaceCareersData: TStringList;       // Carrières de la race sélectionnée (Code|Valeur)
    NodeSelectionnee: TTreeNode;
    MemoEncartBranche: TMemo;  // encart « a quoi sert cette branche » (affiche quand une branche est selectionnee)
    TypeNodeSelectionnee: String;  // 'CHAPITRE', 'DONNEE' ou 'ATTRIBUT'
    CodeDonneeSelectionnee: String;
    CurrentRaceCode: String;        // Store code of selected race
    CurrentAttributeValue: String;  // Store raw attribute value for display
    
    // Procédures privées
    function GetBookLabel(BookCode: String): String;
    procedure AfficherDonneeRace(ACode: String);
    procedure AfficherFicheEthnie(Element: TDOMElement; ACode: String);
    procedure AfficherDonneeAttribut(ACode: String);
    procedure ParseAttributValue(Valeur: String; out AttrType: String; out Dices: String; out BaseValue: String; out SimpleValue: String; out Formula: String);
    function GetAttributLabel(CodeAttribut: String): String;
    function LibelleCompetenceCarriereV1(Code: String): String;
    function LibelleChoixCompetence(const Code: String): String;
    function LibelleSortV1(Code: String): String;
    function CodeSortV1(Libelle: String): String;
    function TableValeursEditable(const Chapitre: String): Boolean;
    procedure AfficherFicheTableValeurs(const Chapitre: String);
    function LibelleCorruption(Code: String): String;
    function CodeCorruption(Libelle: String): String;
    function LibelleChoixMetier(Code: String): String;
    function CodeChoixMetier(Libelle: String): String;
    function ChoixCompetencesV1: String;
    function ChoixMeresSpecialisationV1(const Courant: String): String;
    function ChoixDivinitesV1(const Courant: String): String;
    function ChoixValeursBalise(const Balise, Courant: String): String;
    function ChoixRegimeV1: String;
    function ChoixMotsV1(const Prefixe: String; const Mots: array of String; Codes: Boolean = False): String;
    function ChoixParBaliseV2(const Balise: String): String;
    function ChoixMeresTalentsV2(const Courant: String): String;
    function ChoixTalentsLiesV2(const Courants: String): String;
    function  NouveauBouton(Proprio: TComponent): TBCButton;
    function  InstantaneFiche: String;
    procedure PrendreSnapshotFiche;
    procedure AfficherTirageTalent;
    function  ChapitreTirageTalent: TDOMElement;
    function  LibelleTalentTirage(Code: String): String;
    function  LibelleCompetenceTirage(Code: String): String;
    function  LibelleEthnieTirage(Code: String): String;
    procedure TirageValiderClick(Sender: TObject);
    procedure TirageAnnulerClick(Sender: TObject);
    procedure TirageRaceValiderClick(Sender: TObject);
    procedure TirageRaceAnnulerClick(Sender: TObject);
    procedure AfficherTirageRaceMatrice;
    procedure EquipClasseValiderClick(Sender: TObject);
    procedure EquipClasseAnnulerClick(Sender: TObject);
    procedure EquipClasseChoisir(Genre: Integer; out Code: String);
    procedure CiblesEquipClasse(const CodeClasse: String; Codes: TStrings);
    procedure AfficherEquipClasse;
    procedure CarriereEspeceValiderClick(Sender: TObject);
    procedure CarriereEspeceAnnulerClick(Sender: TObject);
    procedure AfficherCarriereEspece;
    procedure RegleEthnieValiderClick(Sender: TObject);
    procedure RegleEthnieAnnulerClick(Sender: TObject);
    procedure AfficherRegleEthnie;
    function  ChapitreRegleEthnie: TDOMElement;
    procedure SousMetierValiderClick(Sender: TObject);
    procedure SousMetierAnnulerClick(Sender: TObject);
    procedure AfficherSousMetier;
    function  ChapitreSousMetier: TDOMElement;
    function  ChapitreCarriereEspece: TDOMElement;
    procedure TraitsEthnieValiderClick(Sender: TObject);
    procedure TraitsEthnieAnnulerClick(Sender: TObject);
    procedure AfficherTraitsEthnie;
    function  ChapitreTraitsEthnie: TDOMElement;
    function  TraitEthnieCite(const Code: String): Boolean;
    function  ChapitreEquipClasse: TDOMElement;
    function  ChoisirEquipementCatalogue(Genre: Integer): String;
    function  GenreEquipement(const Nom: String): Integer;
    function  LibelleEnsembleEquipement(const Nom: String): String;
    function  ChapitreTirageRace: TDOMElement;
    procedure AfficherTirageMetier;
    function  ChapitreTirageMetier: TDOMElement;
    function  LibelleMetierTirage(Code: String): String;
    function  LibelleColonneTirage(Code: String): String;
    function  LibelleRegleTirage(Code: String): String;
    function  LibelleClasseTirage(Code: String): String;
    procedure TirageMetierValiderClick(Sender: TObject);
    procedure TirageMetierAnnulerClick(Sender: TObject);
    procedure MajBoutonsFiche;
    procedure TimerFicheTimer(Sender: TObject);
    procedure BoutonDialogueClick(Sender: TObject);
    procedure ToucheDialogue(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AfficherFicheSort(Element: TDOMElement);
    procedure RemplirTalentsSort(const TypeSort: String);
    procedure TypesTalents(Resultat: TStringList);
    function  TalentHorsFamille(const TypeSort, Talents: String): String;
    function  LibelleTalentCoche(const Code: String): String;
    function  ChoixTalentsSort(const TalentsCoches: String): String;
    function  ChoixTalentsSigne(const Courant: String): String;
    function  FicheControler: Boolean;
    procedure FicheChangementChamp(const Balise: String);
    procedure CocherTalentUnique;
    function  ConfirmerSortsSansTalent: Boolean;
    function  TalentsDeTable(const CodeSort: String): String;
    procedure EcrireTalentsTable(const CodeSort, Talents: String);
    procedure RangerTalentsSort(Element: TDOMElement);
    function  ChoixBenedictions(const Dieu: String; out Coches, Verrous: String): String;
    function  ChoixCasesLabels(Premier, Dernier: Integer): String;
    function  AutreLivreRulebook: Boolean;
    function  ChapitreReserveRulebook(const Chapitre: String): Boolean;
    function  TrouverTalentRulebook(const Id: String): TDOMElement;
    procedure RangerBenedictionsDieu(const Dieu: String);
    procedure RemplirConditions;
    function  TalentsDeTableDoc(Doc: TXMLDocument; const CodeSort: String): String;
    function  RulebookXML: TXMLDocument;
    function  RulebookBaseXML: TXMLDocument;
    function  LibelleAffiche(const Code: String): String;
    function  LibelleBonusMalusRulebook(const Code: String): String;
    procedure RemplirGroupesArmes(Tri: TStringList);
    procedure RemplirQualitesArme(const Marqueur: String);
    function  NoeudArmures(Node: TTreeNode): TTreeNode;
    function  NoeudTrappings(Node: TTreeNode): TTreeNode;
    function  NoeudQualites(Node: TTreeNode; out ArmureQ: Boolean): TTreeNode;
    procedure CreerQualite;
    procedure MenuNouvelleQualiteClick(Sender: TObject);
    procedure AfficherFicheQualite(Element: TDOMElement);
    procedure CreerTrapping;
    procedure MenuNouveauTrappingClick(Sender: TObject);
    procedure CreerMaladie;
    procedure AfficherFicheMaladie(Element: TDOMElement);
    procedure AfficherFicheAffliction(Element: TDOMElement);
    procedure AfficherFicheMutation(Element: TDOMElement; TypeNoeud: Integer);
    function  TypeBrancheMutation(Node: TTreeNode): Integer;
    procedure CreerMutation;
    procedure AfficherFicheNation(Element: TDOMElement);
    procedure AfficherFicheOption(Element: TDOMElement);
    procedure CreerNation;
    procedure EcrireLibelleLivre(const Code, Texte: String);
    procedure SupprimerLibelleLivre(const Code: String);
    procedure AfficherFicheCondition(Element: TDOMElement);
    procedure AfficherDonneeCondition(Code: String);
    function  TrouverTexteLibelle(const Code: String): TDOMElement;
    procedure AfficherDonneeLibelle(Code: String);
    procedure AfficherDonneeV2(Code, NomTag: String);
    procedure ChargerBrancheGroupeeV2(ChapitreTag, ElementTag, GroupeTag, CodeTitre: String; TypeNoeud: Integer; NodeParent: TTreeNode; SansBranche: Boolean = False);
    procedure CreerCondition;
    procedure MenuNouvelleConditionClick(Sender: TObject);
    procedure AfficherFicheFabrication(Element: TDOMElement);
    function  NoeudFabrications(Node: TTreeNode): TTreeNode;
    procedure CreerFabrication;
    procedure MenuNouvelleFabricationClick(Sender: TObject);
    procedure MenuNouvelleNationClick(Sender: TObject);
    procedure MenuNouvelleMutationClick(Sender: TObject);
    procedure FicheValiderClick(Sender: TObject);
    procedure FicheAnnulerClick(Sender: TObject);
    procedure ReafficherFiche;
    procedure MenuNouvelleMaladieClick(Sender: TObject);
    procedure CreerAffliction;
    procedure MenuNouvelleAfflictionClick(Sender: TObject);
    procedure CreerSigneAstral;
    procedure MenuNouveauSigneClick(Sender: TObject);
    procedure AfficherFicheSigneAstral(Element: TDOMElement);
    function  ChoixParTags(const Tags: array of String; const Courant: String): String;
    procedure CreerBonusCarriere;
    procedure CreerAdaptation;
    procedure MenuNouvelleAdaptationClick(Sender: TObject);
    procedure AfficherFicheAdaptation(Element: TDOMElement);
    procedure MenuNouveauBonusClick(Sender: TObject);
    procedure AfficherFicheBonusCarriere(Element: TDOMElement);
    procedure AfficherFicheTrapping(Element: TDOMElement);
    procedure AfficherFicheArme(Element: TDOMElement);
    procedure AfficherFicheArmureSimple(Element: TDOMElement);
    procedure AfficherFicheArmure(Element: TDOMElement);
    function  LibelleChoixFiche(Code: String): String;
    procedure CreerArmure;
    procedure CreerSort;
    procedure MenuNouveauSortClick(Sender: TObject);
    function  NoeudSorts(Node: TTreeNode): TTreeNode;
    procedure MenuNouvelleArmureClick(Sender: TObject);
    function  CodeQualiteArme(const Lib: String): String;
    function  LibelleQualiteArme(const Code: String): String;
    function TranslateBATTRCode(BATTRCode: String): String;
    function ParseFormulaComponents(Formula: String): TFormulaComponentArray;
    procedure LoadAttributesForRace(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
    procedure LoadSkillsForRaceTree(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
    procedure LoadTalentsForRaceTree(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
    procedure LoadCareersForRaceTree(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
    // Branche Métier de niveau 1
    procedure ConstruireMetierRacesMap();
    procedure LoadMetierRacesPossibles(CareerCode: String; MetierNode: TTreeNode);
    procedure LoadMetierNiveaux(CareerElement: TDOMElement; CareerCode: String; MetierNode: TTreeNode);
    procedure LoadMetierNiveauAttributs(CareerElement: TDOMElement; Niveau: Integer; CodeNiveau: String; NodeBase: TTreeNode);
    procedure LoadMetierNiveauCompetences(CareerElement: TDOMElement; Niveau: Integer; SkillPrincipal: String; CodeNiveau: String; NodeBase: TTreeNode);
    procedure LoadMetierNiveauTalents(CareerElement: TDOMElement; Niveau: Integer; CodeNiveau: String; NodeBase: TTreeNode);
    procedure RemplirBrancheNiveauCompetences(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer; SkillPrincipal: String);
    procedure RemplirBrancheNiveauTalents(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer);
    procedure AfficherCompetencesCarriere(CodeNiveau: String; Talents: Boolean);
    procedure ValiderCompetencesCarriere;
    function  NiveauParDefaut: String;
    procedure LoadMetierNiveauEquipement(CareerElement: TDOMElement; Niveau: Integer; CodeNiveau: String; NodeBase: TTreeNode);
    procedure AjouterFeuilleEquipement(NomItem: String; NodeBase: TTreeNode; Quantite: Integer = 1);
    procedure LoadSkillsForRace(RaceElement: TDOMElement; RaceCode: String);
    procedure LoadCareersForRace(RaceElement: TDOMElement);
    procedure AfficherSkillsForRace(RaceCode: String);
    procedure AfficherTalentsForRace();
    procedure AfficherCareersForRace(RaceCode: String);
    procedure AfficherRacesForMetier(CareerCode: String);
    procedure PoserImageLivre(const Genre, Code: String);
    procedure AfficherFicheCarriere(Element: TDOMElement);
    procedure AfficherDonneeMetier(CareerCode: String);
    procedure AfficherBrancheCoches(CareerCode: String; Genre: Integer);
    procedure AfficherBrancheCarriereV1(Element: TDOMElement; CareerCode: String; Genre: Integer);
    procedure AfficherFicheCompetence(Element: TDOMElement; TypeNoeud: Integer);
    procedure AfficherDonneeCompetence(CodeComp, Titre: String);
    procedure LoadCorruptionForRaceTree(RaceNode: TTreeNode; RaceCode: String);
    procedure ChargerBrancheSimple(ChapitreTag, ElementTag, TitreBranche: String; TypeNoeud: Integer; NodeParent: TTreeNode; Regrouper: Boolean = False; Trier: Boolean = True);
    procedure ChargerBrancheLignesV1(ChapitreTag, TitreBranche: String; NodeParent: TTreeNode);
    function  TrouverLigneTable(Code: String): TDOMElement;
    function  TexteLigneTable(Ligne: TDOMElement): String;
    function  LibelleCodeV1(const Code: String): String;
    function  EstLivreV1: Boolean;
    function  EstLivreV2: Boolean;
    function  VersionFicheLivre: String;
    function  ChapitreV1Permis(const NomChap: String): Boolean;
    function  ChapitrePermisVersion(const NomChap: String): Boolean;
    procedure AfficherLigneTable(Code: String);
    procedure ChampsGeneriques(Mere: TDOMElement; Prefixe: String; var Champs: TListeChampsFiche; var N: Integer);
    procedure AfficherFicheGeneriqueV1(Element: TDOMElement; BaliseElement: String; TypeNoeud: Integer; Code: String);
    procedure ListerBalisesEnTableau(Element: TDOMElement);
    procedure AfficherDonneeCorruptionV2(Code: String);
    function  FicheGeneriqueV1Possible(Element: TDOMElement): Boolean;
    procedure AfficherFicheTalent(Element: TDOMElement; Etranger: Boolean = False);
    procedure ReconstruireFicheTalent(Donnee: PtrInt);
    procedure TimerFamilleTick(Sender: TObject);
    procedure AfficherDonneeTalent(CodeTalent, Titre: String);
    function  NotesDonnees(Element: TDOMElement): String;
    procedure AfficherDonneeEquipement(Code, TagName, Titre: String);
    procedure AfficherDonneeMaladie(Code: String);
    function AplatirElement(Element: TDOMElement): String;
    procedure AfficherDonneePetiteTable(Chapitre, TagElement, Code: String);
    procedure AfficherDonneeChapitre(Chapitre: String);
    procedure AfficherDonneeBonusMalus(Code, Titre: String; ElementTag: String = 'BonusMalus');
    procedure AfficherDonneeSort(Code, Titre: String);
    procedure AjouterLigneDetail(Libelle, Valeur: String; Toujours: Boolean = False);
    function  PrefixeLivre(Code: String): String;
    function  TraduireCodesMultiples(Valeur: String): String;
    function  EffetsFabrication(Element: TDOMElement): String;
    function  EffetsTalent(Element: TDOMElement): String;
    function  LibelleDeCode(Code: String): String;
    function  TraduireCodesDansTexte(Texte: String): String;
    function  DecouperDegats(Degats: String; out CodeBonus, Fixe: String): Boolean;
    function  TrouverElementParId(TagName, Id: String): TDOMElement;
    procedure AfficherAttributsForNiveau(CodeNiveau: String);
    procedure AfficherAttributsEthnie(RaceCode: String);
    procedure AfficherCorruptionEthnie(RaceCode: String);
    procedure AfficherNiveauxCarriere(CareerCode: String);
    procedure ValiderNiveauxCarriere;
    procedure ValiderAttributsCarriere;
    procedure ValiderEquipementCarriere;
    procedure RemplirCompLieeFiche(const CodeActuel: String);
    function LibelleLigneEquipement(const NomItem, Quantites: String): String;
    procedure RemplirBrancheNiveauEquipement(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer);
    procedure RemplirBrancheNiveauAttributs(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer);
    procedure GridAttrEthnieContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MenuNivFinClick(Sender: TObject);
    procedure MenuNivDebutClick(Sender: TObject);
    procedure MenuNivSupprimerClick(Sender: TObject);
    procedure MenuEquipChoisirClick(Sender: TObject);
    procedure AjouterLigneNiveau(ARow, Id: Integer; ModeleRow: Integer);
    procedure ValiderCorruptionEthnie;
    procedure AfficherCompetencesForNiveau(CodeNiveau: String);
    procedure AfficherTalentsForNiveau(CodeNiveau: String);
    procedure AfficherEquipementForNiveau(CodeNiveau: String);
    function  LibelleEquipement(NomItem: String; out TypeEquip: Char): String;
    function  TrouverCareerElement(CareerCode: String): TDOMElement;
    function  AjouterNoeudCarriere(NodeCareers: TTreeNode; XMLElement: TDOMElement): TTreeNode;
    procedure RemplirCodesClasse(Codes: TStrings; ClasseActuelle: String);
    function  CreationPermise: Boolean;
    function  EditionPermise: Boolean;
    function  NoeudCarrieres(Node: TTreeNode): TTreeNode;
    function  DemanderNouvelleCarriere(out Lib, Classe: String): Boolean;
    function  CodeNouvelleCarriere(const Lib: String): String;
    function  AjouterNoeudEthnie(NodeRaces: TTreeNode; XMLElement: TDOMElement): TTreeNode;
    function  NoeudEthnies(Node: TTreeNode): TTreeNode;
    function  DemanderNouvelleEthnie(out Lib, Espece: String): Boolean;
    function  CodeNouvelleEthnie(Lib: String): String;
    procedure CreerEthnie;
    procedure CreerRace;
    function  NoeudBrancheSimple(Node: TTreeNode; CodeLibelle: String; TypeFeuille: Integer): TTreeNode;
    procedure CreerCompetenceOuTalent(EstTalent: Boolean);
    procedure CreerArme;
    procedure MenuNouvelleArmeClick(Sender: TObject);
    function  NoeudArmes(Node: TTreeNode): TTreeNode;
    procedure CreerSpecialisationCompetence(EstTalent: Boolean);
    procedure MenuNouvelleSpecTalentClick(Sender: TObject);
    procedure MenuNouvelleSpecialisationClick(Sender: TObject);
    procedure MenuNouvelleCompetenceClick(Sender: TObject);
    procedure MenuNouveauTalentClick(Sender: TObject);
    procedure CollecterReferences(Noeud: TDOMNode; Code: String; Definition: TDOMElement; Chapitre: String;
      Bloquants: TStrings; Citations: TFPList);
    procedure SupprimerSelection;
    function  NoeudRacesGroupes(Node: TTreeNode): TTreeNode;
    function  AjouterNoeudRaceGroupe(Branche: TTreeNode; Race: TDOMElement): TTreeNode;
    procedure AfficherRaceGroupe(ACode: String);
    procedure MenuNouvelleRaceClick(Sender: TObject);
    procedure RemplirCodesRaces(Codes, Libelles: TStrings);
    procedure CreerCarriere;
    procedure MasquerAfficherElements(ElementType: String);
    procedure GridSkillsSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GridSkillsSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: string);
    procedure GridSkillsCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
    procedure GridSkillsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MenuSkillAjouterClick(Sender: TObject);
    procedure MenuSkillSupprimerClick(Sender: TObject);
    procedure MenuSkillFusionnerClick(Sender: TObject);
    procedure MenuSkillScinderClick(Sender: TObject);
    procedure MenuSkillRetirerClick(Sender: TObject);
    procedure RemplirLigneSkill(ARow: Integer; const Code: String; Coche: Boolean);
    procedure ValiderCompetencesEthnie;
    procedure AjouterNoeudSkill(Pere: TTreeNode; const SkillCode: String);
    procedure AjouterNoeudTalent(Pere: TTreeNode; const TalentCode: String);
    procedure AfficherTalentsEthnie(RaceCode: String);
    procedure RemplirLigneTalent(ARow: Integer; const Code: String; Coche: Boolean);
    function BaseLigne(const Code: String): String;
    procedure SpecsLigne(const Base: String; Libelles, Codes: TStrings);
    function LigneASpecs(const Base: String): Boolean;
    function InstantaneSkills: String;
    procedure GridCareersSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GridCareersSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: string);
    procedure GridCareersCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
    procedure RemplirNoeudCarrieres(RaceElement: TDOMElement; NodeCareers: TTreeNode);
    procedure ValiderCarrieresEthnie;
    function InstantaneCareers: String;
    procedure MajTranchesCareers;
    procedure AfficheTotalCareers(Total: Integer);
    function InstantaneCourant: String;
    procedure ShowComponentControl(Index: Integer; AttrLabel: String; Coefficient: String);
    procedure HideComponentControls(Index: Integer);
    procedure NettoyerForm();
    procedure MasquerForm();
    procedure InitialiserControles();
    
  public
    procedure ChargerXMLFile(AFilePath: String);
    procedure TesterAllerRetour(const Sortie, Arbre: String; Edition: Boolean = False);
    function  AjoutRetraitLigneGrilles(Cont: TWinControl; const Ajouter, Retirer: String): Integer;
    procedure DumpEcran(const Sortie: String; Echantillon: Integer);
    procedure TesterGrillesCarriere(Doc: TXMLDocument; Racine: TDOMElement);
  end;

var
  WinLivres: TWinLivres;
  FileName: String;        // Nom complet du fichier (ex: "BOOK RULESBOOK.Xml")
  FileCode: String;        // Nom sans extension (ex: "BOOK RULESBOOK")
implementation

uses WinWeapon, WinArmor, WinEquipement, XmlExportImport, ChargeSigneAstral, DumpEcran, GuideAide, AideContextuelle;

{$R *.lfm}

const
  TiersSalaire: array[0..2] of String = ('TIERS_BRASS', 'TIERS_SILVER', 'TIERS_GOLD');
  ClassesCarriere: array[0..7] of String = ('RULES-CLASS_ACAD', 'RULES-CLASS_BURG', 'RULES-CLASS_COUR', 'RULES-CLASS_PEAS',
    'RULES-CLASS_RANG', 'RULES-CLASS_RIVE', 'RULES-CLASS_ROGU', 'RULES-CLASS_WARR');

  AttributsCarriere: array[0..9] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel');

// Entier positif ou nul ? (champ vide refuse)
function EntierPositif(S: String; out N: Integer): Boolean;
begin
  S := Trim(S);
  N := StrToIntDef(S, -1);
  Result := (S <> '') and (N >= 0);
end;

// ✨ HELPERS TREEVIEW - gestion du TNodeInfo porté par chaque noeud

const
  // Chapitres à entrées nommées, dans l'ordre des types de noeud 46 à 52.
  PetitesTablesChapitre: array[0..6] of String = ('DATA_STARSIGN', 'DATA_RULE', 'DATA_CAREER_BONUS',
    'DATA_CAREER_ADAPTATION', 'DATA_SPELL_TALENT', 'DATA_CLASS_ITEM', 'DATA_SPECIE_TRAIT');
  PetitesTablesTag: array[0..6] of String = ('StarSign', 'Rule', 'CareerBonus',
    'Adaptation', 'Sort', 'Class', 'SpecieTrait');
  PetitesTablesLib: array[0..6] of String = ('RULES-LAB_318', 'RULES-LAB_319', 'RULES-LAB_320',
    'RULES-LAB_321', 'RULES-LAB_322', 'RULES-LAB_323', 'RULES-LAB_324');
  // Chapitres de valeurs, affichés en bloc (type 53).
  TablesEntieres: array[0..9] of String = ('DATA_SKILL_COST', 'DATA_ATTRIBUT_COST',
    'DATA_CAREER_ROLL', 'DATA_CAREER_SUBCHOICE', 'DATA_RANDOM_TALENT',
    'DATA_CORRUPTION_PHYSICAL_CHANCE', 'DATA_CORRUPTION_MENTAL_CHANCE', 'DATA_SPECIE_CAREER_CHOICE',
    'DATA_CAREER_LINK_V1', 'DATA_CAREER_LINK_V2');
  TablesEntieresLib: array[0..9] of String = ('RULES-LAB_325', 'RULES-LAB_326',
    'RULES-LAB_327', 'RULES-LAB_328', 'RULES-LAB_329', 'RULES-LAB_340', 'RULES-LAB_341', 'RULES-LAB_977',
    'RULES-LAB_983', 'RULES-LAB_983');

// Libellé d'interface d'un chapitre technique (DATA_...), le nom du chapitre s'il n'en a pas.
function LibelleChapitre(Chapitre: String): String;
var
  I: Integer;
begin
  Result := Chapitre;
  for I := 0 to High(PetitesTablesChapitre) do
    if PetitesTablesChapitre[I] = Chapitre then
      Exit(GetTexteLibelle(PetitesTablesLib[I]));
  for I := 0 to High(TablesEntieres) do
    if TablesEntieres[I] = Chapitre then
      Exit(GetTexteLibelle(TablesEntieresLib[I]));
end;

// Attache un TNodeInfo au noeud. Libère l'ancien s'il y en avait un.
procedure SetNodeInfo(Node: TTreeNode; AType: Integer; ACode: String = ''; AChapitre: String = '');
var
  Info: TNodeInfo;
begin
  if Node = nil then Exit;
  
  if Node.Data <> nil then
    TNodeInfo(Node.Data).Free;
  
  Info          := TNodeInfo.Create;
  Info.TypeNode := AType;
  Info.Code     := ACode;
  Info.Chapitre := AChapitre;
  Node.Data     := Info;
end;

// Type du noeud, ou -1 si le noeud est nil / sans info
function GetNodeType(Node: TTreeNode): Integer;
begin
  if (Node = nil) or (Node.Data = nil) then
    Result := -1
  else
    Result := TNodeInfo(Node.Data).TypeNode;
end;

// Code du noeud, ou '' si le noeud est nil / sans info
function GetNodeCode(Node: TTreeNode): String;
begin
  if (Node = nil) or (Node.Data = nil) then
    Result := ''
  else
    Result := TNodeInfo(Node.Data).Code;
end;

// Page du livre source de la fiche (balise <Page>, 12/10/2026). Lecture seule : vide si la fiche
// n'en porte pas. La cle de la table est le bloc DATA_* + l'id, d'ou la liste des blocs.
function PageDeFiche(const Code: String): String;
const
  Blocs: array[0..24] of String = ('DATA_SKILL_V2', 'DATA_TALENT_V2', 'DATA_SPELL_V2', 'DATA_EQUIPMENT_V2', 'DATA_TALENT', 'DATA_TALENT_SPECIALIZATION', 'DATA_SPELL',
    'DATA_CAREER', 'DATA_ARMOR', 'DATA_WEAPON', 'DATA_SKILL', 'DATA_SKILL_SPECIALIZATION',
    'DATA_TRAPPING', 'DATA_RACE', 'DATA_NATION', 'DATA_SPECIE', 'DATA_RULE', 'DATA_CONDITION',
    'DATA_DISEASE', 'DATA_AFFLICTION', 'DATA_ARMOR_BONUS', 'DATA_WEAPON_BONUS',
    'DATA_CRAFTMANSHIP', 'DATA_STARSIGN', 'DATA_SPECIE_TRAIT');
var
  I: Integer;
begin
  Result := '';
  if Code = '' then Exit;
  for I := Low(Blocs) to High(Blocs) do
  begin
    Result := PageFiche(Blocs[I], Code);
    if Result <> '' then Exit;
  end;
end;

// Libère tous les TNodeInfo de l'arbre. À appeler AVANT Items.Clear,
// sinon les objets restent en mémoire (fuite).
procedure LibererNodesData(Tree: TTreeView);
var
  I: Integer;
begin
  if Tree = nil then Exit;
  
  for I := 0 to Tree.Items.Count - 1 do
    if Tree.Items[I].Data <> nil then
    begin
      TNodeInfo(Tree.Items[I].Data).Free;
      Tree.Items[I].Data := nil;
    end;
end;

// Famille d'un attribut d'ethnie d'apres la fin de son code (le prefixe de livre varie) :
// 'BLESSURES' (formule), 'SIMPLE' (Fate, Resil, Supp, Move) ou 'CARAC' (des + valeur fixe).
function ClasseAttributEthnie(CodeAttr: String): String;
var
  Suffixe: String;
begin
  Suffixe := Copy(CodeAttr, Pos('ATTR_', CodeAttr) + 5, Length(CodeAttr));
  if Suffixe = 'Wound' then
    Result := 'BLESSURES'
  else if (Suffixe = 'Fate') or (Suffixe = 'Resil') or (Suffixe = 'Supp') or (Suffixe = 'Move') then
    Result := 'SIMPLE'
  else
    Result := 'CARAC';
end;

// ✨ ÉVÉNEMENTS FORM

// Panneaux et listes de la zone de detail (cree par FormCreate, dans cet ordre : PanelFiche depend de
// PanelBonus et PanelQualitesArme, eux-memes crees plus haut).
procedure TWinLivres.CreerPanneauxDetail;
var
  I: Integer;
  Tableau: TPanelLignesV1;
begin
  TalSortLib := TStringList.Create;
  TalSortCodes := TStringList.Create;
  QualLibelles := TStringList.Create;
  QualCodes := TStringList.Create;
  QualCodesAvecValeur := TStringList.Create;
  PanelQualitesArme := TPanelQualitesLiees.Create(Self);
  PanelQualitesArme.Parent := StringGridDetail.Parent;
  PanelQualitesArme.Visible := False;
  PanelQualitesArme.Initialiser(ButtonChargerXML, QualLibelles, QualCodes);
  PanelQualitesArme.CodesAvecValeur := QualCodesAvecValeur;
  PanelFiche := TPanelFiche.Create(Self);
  PanelFiche.Parent := StringGridDetail.Parent;
  PanelFiche.Initialiser(ButtonChargerXML, PanelBonus, PanelQualitesArme);
  PanelFiche.LibelleAttribut := @GetAttributLabel;
  PanelFiche.OnControler := @FicheControler;
  PanelFiche.OnChangementChamp := @FicheChangementChamp;
  PanelFiche.LibelleCode := @LibelleChoixFiche;
  PanelFiche.OnValider := @FicheValiderClick;
  PanelFiche.OnAnnuler := @FicheAnnulerClick;
  PanelFiche.Visible := False;
  PanelTirage := TPanelTirageTalent.Create(Self);
  PanelTirage.Parent := StringGridDetail.Parent;
  PanelTirage.Initialiser(ButtonChargerXML);
  PanelTirage.OnValider := @TirageValiderClick;
  PanelTirage.OnAnnuler := @TirageAnnulerClick;
  PanelTirageMetier := TPanelTirageMetier.Create(Self);
  PanelTirageMetier.Parent := StringGridDetail.Parent;
  PanelTirageMetier.Initialiser(ButtonChargerXML);
  PanelTirageMetier.OnValider := @TirageMetierValiderClick;
  PanelTirageMetier.OnAnnuler := @TirageMetierAnnulerClick;
  PanelTirageRace := TPanelTirageRace.Create(Self);
  PanelTirageRace.Parent := StringGridDetail.Parent;
  PanelTirageRace.Initialiser(ButtonChargerXML);
  PanelTirageRace.OnValider := @TirageRaceValiderClick;
  PanelTirageRace.OnAnnuler := @TirageRaceAnnulerClick;
  PanelEquipClasse := TPanelEquipClasse.Create(Self);
  PanelEquipClasse.Parent := StringGridDetail.Parent;
  PanelEquipClasse.Initialiser(ButtonChargerXML);
  PanelEquipClasse.OnValider := @EquipClasseValiderClick;
  PanelEquipClasse.OnAnnuler := @EquipClasseAnnulerClick;
  PanelEquipClasse.OnChoisir := @EquipClasseChoisir;
  PanelTraduction := TPanelTraduction.Create(Self);
  PanelTraduction.Parent := StringGridDetail.Parent;
  PanelTraduction.Initialiser(ButtonChargerXML);
  PanelTraduction.OnEnregistrer := @TraductionEnregistrerClick;
  PanelImageLivre := TPanelImageLivre.Create(Self);
  PanelImageLivre.Parent := StringGridDetail.Parent;
  PanelCarriereEspece := TPanelCarriereEspece.Create(Self);
  PanelCarriereEspece.Parent := StringGridDetail.Parent;
  PanelCarriereEspece.Initialiser(ButtonChargerXML);
  PanelCarriereEspece.OnValider := @CarriereEspeceValiderClick;
  PanelCarriereEspece.OnAnnuler := @CarriereEspeceAnnulerClick;
  PanelRegleEthnie := TPanelRegleEthnie.Create(Self);
  PanelRegleEthnie.Parent := StringGridDetail.Parent;
  PanelRegleEthnie.Initialiser(ButtonChargerXML);
  PanelRegleEthnie.OnValider := @RegleEthnieValiderClick;
  PanelRegleEthnie.OnAnnuler := @RegleEthnieAnnulerClick;
  PanelSousMetier := TPanelSousMetier.Create(Self);
  PanelSousMetier.Parent := StringGridDetail.Parent;
  PanelSousMetier.Initialiser(ButtonChargerXML);
  PanelSousMetier.OnValider := @SousMetierValiderClick;
  PanelSousMetier.OnAnnuler := @SousMetierAnnulerClick;
  PanelTraitEthnie := TPanelTraitEthnie.Create(Self);
  PanelTraitEthnie.Parent := StringGridDetail.Parent;
  PanelTraitEthnie.Initialiser(ButtonChargerXML);
  PanelTraitEthnie.OnValider := @TraitsEthnieValiderClick;
  PanelTraitEthnie.OnAnnuler := @TraitsEthnieAnnulerClick;
  PanelSigneEffets := TPanelSigneEffets.Create(Self);
  PanelSigneEffets.Initialiser(ButtonChargerXML, @GetAttributLabel, @LibelleTalentTirage);
  PanelCarriereV1 := TPanelCarriereV1.Create(Self);
  PanelCarriereV1.Initialiser(ButtonChargerXML, @GetAttributLabel, @LibelleCompetenceCarriereV1);
  PanelBonusCompetenceV1 := TPanelSousBlocs.Create(Self);
  PanelBonusCompetenceV1.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Bonus|RULES-LAB_904|Kind:RULES-LAB_901,Target:RULES-LAB_905,Value:RULES-LAB_025']);
  PanelBonusCompetenceV1.OrdreBalises := 'Description,Explanation,Bonus,Cumulative,Variants,Page';
  PanelDieuV1 := TPanelSousBlocs.Create(Self);
  PanelDieuV1.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['SpellAccess|RULES-LAB_908|Kind:RULES-LAB_901,Value:RULES-LAB_911:c,Note:RULES-LAB_910',
     'SkillAccess|RULES-LAB_909|Kind:RULES-LAB_901,Value:RULES-LAB_009:c,Note:RULES-LAB_910']);
  PanelDieuV1.OrdreBalises := 'Description,Explanation,Alignment,Domain,Strictures,SpellAccess,SkillAccess,Trials,Blessings,Temples,FriendsEnemies,Page';
  PanelCochesCarriere[0] := TPanelCarrieresCoches.Create(Self, False);
  PanelCochesCarriere[1] := TPanelCarrieresCoches.Create(Self, True);
  for I := 0 to 4 do PanelListesCarriere[I] := TPanelListeChoix.Create(Self);
  PanelListesCarriere[0].Initialiser(ButtonChargerXML, 'Advances', 'Advance', '',
    ',Skills,Talents,Trappings,StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page,',
    '', 1, True, '', '', 'RULES-LAB_008', 'RULES-LAB_025', @GetAttributLabel);
  PanelListesCarriere[1].Initialiser(ButtonChargerXML, 'SUBCHAPTER_SKILL', 'Skill', 'Skills',
    ',SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page,',
    ',Talents,Trappings,StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page,',
    3, False, '1', '', 'RULES-LAB_009', 'RULES-LAB_025', @LibelleDeCode);
  PanelListesCarriere[2].Initialiser(ButtonChargerXML, 'SUBCHAPTER_TALENT', 'Talent', 'Talents',
    ',Entries,Exits,ExitCodes,Basic,Source,Page,',
    ',Trappings,StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page,',
    3, False, '1', '', 'RULES-LAB_007', 'RULES-LAB_025', @LibelleDeCode);
  PanelListesCarriere[3].Initialiser(ButtonChargerXML, 'SUBCHAPTER_ITEM', 'Item', 'Trappings',
    ',SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page,',
    ',StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page,',
    3, True, '1', 'quantite', 'RULES-LAB_013', 'RULES-LAB_025', @LibelleDeCode);
  // carriere WFRP1 : meme tableau, ordre des balises du schema V1 (SUBCHAPTER_SKILL, Trappings, SUBCHAPTER_ITEM, StartMoney...)
  PanelListesCarriere[4].Initialiser(ButtonChargerXML, 'SUBCHAPTER_ITEM', 'Item', 'Trappings',
    ',StartMoney,Entries,Exits,ExitCodes,Source,Page,',
    ',SUBCHAPTER_ITEM,StartMoney,Entries,Exits,ExitCodes,Source,Page,',
    3, True, '1', 'quantite', 'RULES-LAB_013', 'RULES-LAB_025', @LibelleDeCode);
  PanelCarriereV2 := TPanelSousBlocs.Create(Self);
  PanelCarriereV2.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Advances|RULES-LAB_945|*Advance:RULES-LAB_945',
     'SUBCHAPTER_ITEM|RULES-LAB_013|*Item:RULES-LAB_013',
     'SUBCHAPTER_SKILL|RULES-LAB_009|*Skill:RULES-LAB_009',
     'SUBCHAPTER_TALENT|RULES-LAB_007|*Talent:RULES-LAB_007']);
  PanelCarriereV2.OrdreBalises := 'Description,Explanation,MainProfile,SecondaryProfile,Advances,Skills,Talents,Trappings,StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,ExitCodes,Basic,Source,Page';
  PanelClasseV1 := TPanelSousBlocs.Create(Self);
  PanelClasseV1.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Requirement|RULES-LAB_912|@name:RULES-LAB_008:c,.:RULES-LAB_025',
     'RaceRequirement|RULES-LAB_922|Specie:RULES-LAB_923:c,*Requirement:RULES-LAB_912']);
  PanelClasseV1.OrdreBalises := 'Description,Explanation,Requirement,RaceRequirement,Trappings,Money,Page';
  PanelHandicapV1 := TPanelSousBlocs.Create(Self);
  PanelHandicapV1.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Permanent|RULES-LAB_915|@name:RULES-LAB_008:c,.:RULES-LAB_025',
     'Stage|RULES-LAB_920|@number:RULES-LAB_900,*Modifier:RULES-LAB_921,Text:RULES-LAB_906']);
  PanelHandicapV1.OrdreBalises := 'Description,Explanation,Stage,Permanent,InsanityPoints,Page';
  PanelMetierV1 := TPanelSousBlocs.Create(Self);
  PanelMetierV1.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Skill|RULES-LAB_009|.:RULES-LAB_009:c', 'ExitCode|RULES-LAB_918|.:RULES-LAB_918:c']);
  PanelMetierV1.OrdreBalises := 'Description,Roll,Skill,ExitCode,Note';
  PanelQualitesV2 := TPanelTexteListe.Create(Self);
  PanelQualitesV2.Initialiser(ButtonChargerXML, 'Qualities', 'RULES-LAB_720', 'Locations,ArmourPoints,Availability,Note,Page');
  PanelLignesObjetV1 := TPanelLignesMulti.Create(Self);
  Tableau := TPanelLignesV1.Create(Self);
  Tableau.Initialiser(ButtonChargerXML, 'CombatModifiers', 'CombatModifier', 'RULES-LAB_895',
    'RangeBands,Reload,ArmourPoints,Locations,Note,Page', ['Stat|RULES-LAB_993', 'Value|RULES-LAB_994'],
    ['RULES-V1MOD_INITIATIVE', 'RULES-V1MOD_TOHIT', 'RULES-V1MOD_DAMAGE', 'RULES-V1MOD_PARRY']);
  PanelLignesObjetV1.Ajouter(Tableau);
  Tableau := TPanelLignesV1.Create(Self);
  Tableau.Initialiser(ButtonChargerXML, 'RangeBands', 'RangeBand', 'RULES-LAB_718',
    'Reload,ArmourPoints,Locations,Note,Page', ['Band|RULES-LAB_995', 'Distance|RULES-LAB_996', 'Strength|RULES-LAB_997'],
    ['RULES-V1RANGE_POINTBLANK', 'RULES-V1RANGE_SHORT', 'RULES-V1RANGE_LONG', 'RULES-V1RANGE_EXTREME']);
  PanelLignesObjetV1.Ajouter(Tableau);
  PanelEffetTalent := TPanelSousBlocs.Create(Self);
  PanelEffetTalent.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Effet|RULES-LAB_964|@Cible:RULES-LAB_905,@Forme:RULES-LAB_965,@Facteur:RULES-LAB_966,@Carac:RULES-LAB_967']);
  PanelTableCout := TPanelSousBlocs.Create(Self);
  PanelTableCout.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Cost|RULES-LAB_025|@name:RULES-LAB_976,.:RULES-LAB_025']);
  PanelTableChance := TPanelSousBlocs.Create(Self);
  PanelTableChance.Initialiser(ButtonChargerXML, @LibelleCorruption, @CodeCorruption,
    ['Chance|RULES-LAB_156|@name:RULES-LAB_976,.:RULES-LAB_156:c']);
  PanelTableChoix := TPanelSousBlocs.Create(Self);
  PanelTableChoix.Initialiser(ButtonChargerXML, @LibelleChoixMetier, @CodeChoixMetier,
    ['Choice|RULES-LAB_977|Specie:RULES-LAB_923:c,Career:RULES-LAB_006:c,Alternative:RULES-LAB_978:c']);
  PanelLiensCarriere := TPanelSousBlocs.Create(Self);
  PanelLiensCarriere.HauteurGrille := 500;  // plusieurs centaines de liens par livre
  PanelLiensCarriere.Initialiser(ButtonChargerXML, @LibelleChoixMetier, @CodeChoixMetier,
    ['Link|RULES-LAB_983|@name:RULES-LAB_984:c,.:RULES-LAB_985:c']);
  PanelCulteV1 := TPanelSousBlocs.Create(Self);
  PanelCulteV1.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1,
    ['Prayer|RULES-LAB_902|Rank:RULES-LAB_900,Kind:RULES-LAB_901,Value:RULES-LAB_907:c',
     'Gift|RULES-LAB_903|Rank:RULES-LAB_900,Text:RULES-LAB_906']);
  PanelCulteV1.OrdreBalises := 'Description,Deity,Prayer,Gift,Page';
  PanelBonusCarriere := TPanelBonusCarriere.Create(Self);
  PanelBonusCarriere.Initialiser(ButtonChargerXML, @GetAttributLabel, ComboCompLieeFiche.Items, CodesCompLieeFiche, CodesConditions);
  PanelAdaptation := TPanelAdaptation.Create(Self);
  PanelAdaptation.Initialiser(ButtonChargerXML);
  PanelNoms := TPanelNoms.Create(Self);
  PanelNoms.Initialiser(ButtonChargerXML);
  PanelRaceExtra := TPanelRaceExtra.Create(Self);
  PanelRaceExtra.Initialiser(ButtonChargerXML);
end;

// Cree une entree de menu, branche son clic (nil = aucun) et l'ajoute au menu.
procedure TWinLivres.AjouterEntreeMenu(Popup: TPopupMenu; var Entree: TMenuItem; Clic: TNotifyEvent);
begin
  Entree := TMenuItem.Create(Self);
  if Assigned(Clic) then
    Entree.OnClick := Clic;
  Popup.Items.Add(Entree);
end;

procedure TWinLivres.ButtonQuestionClick(Sender: TObject);
begin
  OuvreGuide(GuideQuestions, '');
end;

procedure TWinLivres.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  RacesDataList := TRaceDataMap.Create;
  AttributesDataList := TAttributDataMap.Create;
  AttributeValuesMap := TStringList.Create;
  AttrNiveauxValides := TStringList.Create;
  MetierRacesMap := TStringList.Create;
  RaceSkillsData := TStringList.Create;
  RaceCareersData := TStringList.Create;
  NodeSelectionnee := nil;
  TypeNodeSelectionnee := '';
  CodeDonneeSelectionnee := '';
  CurrentRaceCode := '';
  CurrentAttributeValue := '';
  XMLDoc := nil;
  
  // Initialiser les contrôles
  InitialiserControles();
  
  // Initialiser l'UI des talents
  InitTalentsUI();

  TreeViewLivre.ReadOnly := True;

  // Entree « Nouvelle race... » du menu de l'arbre (libelle pose a l'ouverture du menu)
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleRace, @MenuNouvelleRaceClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleCompetence, @MenuNouvelleCompetenceClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauTalent, @MenuNouveauTalentClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleArme, @MenuNouvelleArmeClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleArmure, @MenuNouvelleArmureClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleQualite, @MenuNouvelleQualiteClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauTrapping, @MenuNouveauTrappingClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleMaladie, @MenuNouvelleMaladieClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleAffliction, @MenuNouvelleAfflictionClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauSigne, @MenuNouveauSigneClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauBonus, @MenuNouveauBonusClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleAdaptation, @MenuNouvelleAdaptationClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleMutation, @MenuNouvelleMutationClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleNation, @MenuNouvelleNationClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleCondition, @MenuNouvelleConditionClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleFabrication, @MenuNouvelleFabricationClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauSort, @MenuNouveauSortClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleSpecialisation, @MenuNouvelleSpecialisationClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleSpecTalent, @MenuNouvelleSpecTalentClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemDeplierBranche, @MenuDeplierBrancheClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemReplierBranche, @MenuReplierBrancheClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleDivinite, @MenuNouvelleDiviniteClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauCulte, @MenuNouveauCulteClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauSortV1, @MenuNouveauSortV1Click);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelObjetV1, @MenuNouvelObjetV1Click);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouvelleClasse, @MenuNouvelleClasseClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauHandicap, @MenuNouveauHandicapClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemNouveauFamilier, @MenuNouveauFamilierClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemLigneNouvelle, @MenuLigneNouvelleClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemLigneDupliquer, @MenuLigneDupliquerClick);
  AjouterEntreeMenu(PopupMenuTree, MenuItemLigneSupprimer, @MenuLigneSupprimerClick);

  // Menu contextuel du tableau des competences d'une ethnie (libelles poses a l'affichage)
  PopupMenuSkills := TPopupMenu.Create(Self);
  AjouterEntreeMenu(PopupMenuSkills, MenuSkillAjouter, @MenuSkillAjouterClick);
  AjouterEntreeMenu(PopupMenuSkills, MenuSkillSupprimer, @MenuSkillSupprimerClick);
  AjouterEntreeMenu(PopupMenuSkills, MenuSkillFusionner, nil);
  AjouterEntreeMenu(PopupMenuSkills, MenuSkillScinder, @MenuSkillScinderClick);
  AjouterEntreeMenu(PopupMenuSkills, MenuSkillRetirer, nil);
  StringGridSkills.PopupMenu := PopupMenuSkills;
  StringGridSkills.OnCheckboxToggled := @GridSkillsCheckboxToggled;
  StringGridSkills.OnContextPopup := @GridSkillsContextPopup;
  StringGridSkills.OnSelectEditor := @GridSkillsSelectEditor;
  for I := 0 to 2 do
    AttrColW[I] := StringGridAttrEthnie.Columns[I].Width;
  with StringGridAttrEthnie.Columns.Add do  // col 4 : montant du salaire, visible seulement pour les niveaux
  begin
    Title.Caption := 'Montant';
    Width := 0;
  end;
  with StringGridAttrEthnie.Columns.Add do  // col 5 : forme feminine du nom du niveau (DescriptionFeminine), niveaux seulement
  begin
    Title.Caption := 'Feminin';
    Width := 0;
  end;
  PopupMenuNiveaux := TPopupMenu.Create(Self);
  AjouterEntreeMenu(PopupMenuNiveaux, MenuNivFin, @MenuNivFinClick);
  AjouterEntreeMenu(PopupMenuNiveaux, MenuNivDebut, @MenuNivDebutClick);
  AjouterEntreeMenu(PopupMenuNiveaux, MenuNivSupprimer, @MenuNivSupprimerClick);
  MenuEquipArme := TMenuItem.Create(Self);
  MenuEquipArme.Tag := 1;
  MenuEquipArme.OnClick := @MenuEquipChoisirClick;
  PopupMenuNiveaux.Items.Add(MenuEquipArme);
  MenuEquipArmure := TMenuItem.Create(Self);
  MenuEquipArmure.Tag := 2;
  MenuEquipArmure.OnClick := @MenuEquipChoisirClick;
  PopupMenuNiveaux.Items.Add(MenuEquipArmure);
  MenuEquipDivers := TMenuItem.Create(Self);
  MenuEquipDivers.Tag := 3;
  MenuEquipDivers.OnClick := @MenuEquipChoisirClick;
  PopupMenuNiveaux.Items.Add(MenuEquipDivers);
  MenuEquipArme.Visible := False;
  MenuEquipArmure.Visible := False;
  MenuEquipDivers.Visible := False;
  StringGridAttrEthnie.PopupMenu := PopupMenuNiveaux;
  CodesCompLieeFiche := TStringList.Create;
  ComboCompLieeFiche := TComboBox.Create(Self);
  ComboCompLieeFiche.Parent := GroupBoxForm;
  ComboCompLieeFiche.SetBounds(0, 0, 200, 25);  // jamais affichee : sert de source de liste a la grille
  ComboCompLieeFiche.Style := csDropDownList;
  ComboCompLieeFiche.Visible := False;
  PanelBonus := TPanelModificateurs.Create(Self);
  PanelBonus.Parent := GroupBoxForm;
  PanelBonus.Initialiser(ButtonChargerXML, @GetAttributLabel, ComboCompLieeFiche.Items, CodesCompLieeFiche);
  CodesConditions := TStringList.Create;
  PanelBonus.CodesCondition := CodesConditions;
  PanelTopButtons.Height := 315;  // place pour les quatrieme, cinquieme et sixieme boutons
  ButtonNouvelleTraduction := NouveauBouton(Self);
  ButtonNouvelleTraduction.Parent := PanelTopButtons;
  ButtonNouvelleTraduction.SetBounds(10, 265, 380, 35);
  ButtonNouvelleTraduction.Caption := GetTexteLibelle('RULES-LAB_672');
  ButtonNouvelleTraduction.OnClick := @ButtonNouvelleTraductionClick;
  ButtonFinaliser := NouveauBouton(Self);
  ButtonFinaliser.Parent := PanelTopButtons;
  ButtonFinaliser.SetBounds(10, 175, 380, 35);
  ButtonFinaliser.Caption := GetTexteLibelle('RULES-LAB_433');
  ButtonFinaliser.OnClick := @ButtonFinaliserClick;
  ButtonFinaliser.Enabled := False;
  ButtonMettreAJour := NouveauBouton(Self);
  ButtonMettreAJour.Parent := PanelTopButtons;
  ButtonMettreAJour.SetBounds(10, 220, 380, 35);
  ButtonMettreAJour.Caption := GetTexteLibelle('RULES-LAB_499');
  ButtonChargerXML.Caption := GetTexteLibelle('RULES-LAB_503');
  ButtonEnregistrerTravail.Caption := GetTexteLibelle('RULES-LAB_348');
  ButtonPublierRevision.Caption := GetTexteLibelle('RULES-LAB_350');
  ButtonMettreAJour.OnClick := @ButtonMettreAJourClick;
  // Aide : bouton « ? Question » (GuideAide.pas) et aide F1 (AideContextuelle.pas)
  CreeBoutonGuide(Self, GetTexteLibelle('RULES-HELP_LAB_QUESTION', '? Question'), 'RULES-HELP_BTN_QUESTION',
    ClientWidth - 150, 4, 140, @ButtonQuestionClick);
  ButtonChargerXML.HelpKeyword        := 'RULES-HELP_LIVRE_CHARGER';
  ButtonEnregistrerTravail.HelpKeyword := 'RULES-HELP_LIVRE_ENREGISTRER';
  ButtonPublierRevision.HelpKeyword   := 'RULES-HELP_LIVRE_PUBLIER';
  ButtonNouvelleTraduction.HelpKeyword := 'RULES-HELP_LIVRE_TRADUCTION';
  ButtonMettreAJour.HelpKeyword       := 'RULES-HELP_LIVRE_MAJ';
  ButtonFinaliser.HelpKeyword         := 'RULES-HELP_LIVRE_FINALISER';
  TreeViewLivre.HelpKeyword           := 'RULES-HELP_LIVRE_ARBRE';
  StringGridSkills.HelpKeyword        := 'RULES-HELP_LIVRE_SKILLS';
  StringGridCareers.HelpKeyword       := 'RULES-HELP_LIVRE_CAREERS';
  MemoEncartBranche := TMemo.Create(Self);
  with MemoEncartBranche do
  begin
    Parent := TreeViewLivre.Parent;  // sous l'arbre : l'arbre se raccourcit, la partie droite ne change pas
    Align := alBottom;
    Height := 110;
    BorderSpacing.Around := 4;
    ReadOnly := True;
    TabStop := False;
    BorderStyle := bsNone;
    ScrollBars := ssNone;
    WordWrap := True;
    Color := $302820;
    Font.Color := clWhite;
    Font.Size := 11;
    Visible := False;
  end;
  TimerFiche := TTimer.Create(Self);
  TimerFiche.Interval := 300;
  TimerFiche.OnTimer := @TimerFicheTimer;
  CreerPanneauxDetail;
  StringGridAttrEthnie.OnContextPopup := @GridAttrEthnieContextPopup;
  StringGridAttrEthnie.OnDblClick := @GridNiveauxDblClick;
  with StringGridSkills.Columns.Add do  // col 5 : niveau, visible seulement pour une carriere
  begin
    Title.Caption := 'Niv.';
    Width := 0;
  end;
  StringGridSkills.OnSetEditText := @GridSkillsSetEditText;
  StringGridCareers.OnCheckboxToggled := @GridCareersCheckboxToggled;
  StringGridCareers.OnSelectEditor := @GridCareersSelectEditor;
  StringGridCareers.OnSetEditText := @GridCareersSetEditText;

  // Style
  try
    MiseEnFormeDesChamp(Self);   // À implémenter plus tard
    // grilles sans saisie : ligne entiere selectionnee, couleur commune
    SelectionGrilleWarhammer(StringGridRaces);
    SelectionGrilleWarhammer(StringGridAttributs);
    SelectionGrilleWarhammer(StringGridCompetences);
    SelectionGrilleWarhammer(StringGridTalents);
    SelectionGrilleWarhammer(StringGridEquipement);
    SelectionGrilleWarhammer(StringGridDetail);
    SelectionGrilleWarhammer(StringGridQualites);
  except
    // GlobalFonts non disponible, continuer sans
  end;
end;

// ========== INITIALISER L'UI DES TALENTS ==========
procedure TWinLivres.InitTalentsUI();
begin
  // Créer le label "Talents aléatoires"
  LabelTalentsRandom := TLabelContour.Create(Self);
  LabelTalentsRandom.Parent := Self;
  LabelTalentsRandom.Left := 430;
  LabelTalentsRandom.Top := 350;
  LabelTalentsRandom.Width := 300;
  LabelTalentsRandom.Height := 20;
  LabelTalentsRandom.Caption := '';
  LabelTalentsRandom.Visible := False;
  
  // Créer le TTreeView pour les talents
  TreeViewTalents := TTreeView.Create(Self);
  TreeViewTalents.Parent := Self;
  TreeViewTalents.Left := 430;
  TreeViewTalents.Top := 120;
  TreeViewTalents.Width := 600;
  TreeViewTalents.Height := 220;
  TreeViewTalents.Visible := False;
end;

procedure TWinLivres.FormShow(Sender: TObject);
begin
  // Afficher le bouton de chargement XML
  // (Message supprimé pour l'instant)
end;

procedure TWinLivres.InitialiserControles();
begin
  // Mettre à jour les captions pour Races
  LabelLivre.Caption := GetTexteLibelle('RULES-LAB_155');        // 'Open book'
  
  // Mettre à jour les captions pour Attributs
  LabelFormAttrName.Caption := GetTexteLibelle('RULES-LAB_008');  // 'Attribute'
  LabelFormAttrDices.Caption := GetTexteLibelle('RULES-LAB_161'); // 'Dices'
  LabelFormAttrBaseValue.Caption := GetTexteLibelle('RULES-LAB_025'); // 'Value'
  LabelFormAttrFormula.Caption := GetTexteLibelle('RULES-LAB_020'); // 'Calculation'
  LabelFormSkills.Caption := GetTexteLibelle('RULES-LAB_087');  // 'Specie's Skills'
  // Libellé emprunté aux traductions PDF, faute de LAB_ dédié à 'Classe'.
  
  // Mettre à jour les captions pour Composants
  LabelFormComponent1.Caption := 'Component 1:';
  LabelFormComponent2.Caption := 'Component 2:';
  LabelFormComponent3.Caption := 'Component 3:';
  
  // Rendre READ-ONLY pour l'affichage
  EditFormAttrName.ReadOnly := True;
  EditFormAttrDices.ReadOnly := True;
  EditFormAttrBaseValue.ReadOnly := True;
  EditFormAttrFormula.ReadOnly := True;
  EditFormComponent1Attr.ReadOnly := True;
  EditFormComponent1Coeff.ReadOnly := True;
  EditFormComponent2Attr.ReadOnly := True;
  EditFormComponent2Coeff.ReadOnly := True;
  EditFormComponent3Attr.ReadOnly := True;
  EditFormComponent3Coeff.ReadOnly := True;
  
  MasquerForm();
end;

// ✨ CHARGEMENT XML

procedure TWinLivres.ButtonChargerXMLClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Filter := 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
    OpenDialog.InitialDir := ExtractFilePath(Application.ExeName) + 'DATABASE';
    
    if OpenDialog.Execute and ConfirmerAbandonModifs then
      ChargerXMLFile(OpenDialog.FileName);
  finally
    OpenDialog.Free;
  end;
end;

// Enregistre l'etat memoire (XMLDoc) dans TRAVAIL\<livre>\<AAAAMMJJ-HHMMSS>.xml, a cote de
// l'executable. Jamais d'ecrasement, DATABASE n'est pas touche (CONTEXT.md 2.1).
// Talents donnes a un sort par le bloc DATA_SPELL_TALENT d'un livre (les dieux d'une benediction, CONTEXT.md 2.39),
// separes par des virgules.
function TWinLivres.TalentsDeTableDoc(Doc: TXMLDocument; const CodeSort: String): String;
var
  Chapitre: TDOMNode;
  Sorts: TDOMNodeList;
  I: Integer;
  V: String;
begin
  Result := '';
  if Doc = nil then Exit;
  Chapitre := Doc.GetElementsByTagName('DATA_SPELL_TALENT').Item[0];
  if Chapitre = nil then Exit;
  Sorts := TDOMElement(Chapitre).GetElementsByTagName('Sort');
  for I := 0 to Sorts.Count - 1 do
    if TDOMElement(Sorts.Item[I]).GetAttribute('id') = CodeSort then
    begin
      V := Trim(ValeurXML(Sorts.Item[I].FindNode('Talent')));
      if V = '' then Continue;
      if Result <> '' then Result := Result + ',';
      Result := Result + V;
    end;
end;

// Talents donnes a un sort par le bloc DATA_SPELL_TALENT du livre ouvert.
function TWinLivres.TalentsDeTable(const CodeSort: String): String;
begin
  Result := TalentsDeTableDoc(XMLDoc, CodeSort);
end;

// Ecrit (ou retire si vide) la ligne <Sort id=CodeSort><Talent> du bloc DATA_SPELL_TALENT du livre ouvert ; le bloc est
// cree apres DATA_SPELL au besoin.
procedure TWinLivres.EcrireTalentsTable(const CodeSort, Talents: String);
var
  Chapitre, Livre, Spell: TDOMNode;
  Sorts: TDOMNodeList;
  Ligne, E: TDOMElement;
  I: Integer;
begin
  if XMLDoc = nil then Exit;
  Chapitre := XMLDoc.GetElementsByTagName('DATA_SPELL_TALENT').Item[0];
  Ligne := nil;
  if Chapitre <> nil then
  begin
    Sorts := TDOMElement(Chapitre).GetElementsByTagName('Sort');
    for I := 0 to Sorts.Count - 1 do
      if TDOMElement(Sorts.Item[I]).GetAttribute('id') = CodeSort then
      begin
        Ligne := TDOMElement(Sorts.Item[I]);
        Break;
      end;
  end;
  if Talents = '' then
  begin
    if Ligne <> nil then Ligne.ParentNode.RemoveChild(Ligne);
    Exit;
  end;
  if Chapitre = nil then
  begin
    Livre := XMLDoc.DocumentElement;  // DATA_BOOK est la racine : son parent serait le document
    Chapitre := XMLDoc.CreateElement('DATA_SPELL_TALENT');
    Spell := XMLDoc.GetElementsByTagName('DATA_SPELL').Item[0];
    if (Spell <> nil) and (Spell.NextSibling <> nil) then
      Spell.ParentNode.InsertBefore(Chapitre, Spell.NextSibling)
    else if Spell <> nil then
      Spell.ParentNode.AppendChild(Chapitre)
    else
      Livre.AppendChild(Chapitre);
  end;
  if Ligne = nil then
  begin
    Ligne := XMLDoc.CreateElement('Sort');
    Ligne.SetAttribute('id', CodeSort);
    Chapitre.AppendChild(Ligne);
    E := XMLDoc.CreateElement('Talent');
    Ligne.AppendChild(E);
  end;
  EcrireValeurXML(TDOMElement(Ligne.FindNode('Talent')), Talents);
end;

// Apres l'ecriture de la fiche d'un sort : une benediction garde ses dieux dans DATA_SPELL_TALENT (<Talent> vide, comme le
// Rulebook), tout autre type dans <Talent> (et sa ligne de table, s'il en avait une, disparait). Une seule source par sort.
procedure TWinLivres.RangerTalentsSort(Element: TDOMElement);
var
  Code, Talents: String;
  N: TDOMNode;
begin
  Code := Element.GetAttribute('id');
  Talents := PanelFiche.ValeurChamp('Talent');
  if SameText(PanelFiche.ValeurChamp('TypSpell'), 'Blessing') then
  begin
    N := Element.FindNode('Talent');
    if N <> nil then EcrireValeurXML(TDOMElement(N), '');
    EcrireTalentsTable(Code, Talents);
  end
  else
    EcrireTalentsTable(Code, '');
end;

// Sorts du livre ouvert sans talent d'acces (ni <Talent>, ni ligne dans DATA_SPELL_TALENT) : personne ne
// peut les apprendre et rien ne le signale. Avant d'ecrire un fichier, on les liste et on demande confirmation.
// True = continuer (aucun sort concerne, ou Nono confirme).
function TWinLivres.ConfirmerSortsSansTalent: Boolean;
var
  Chapitre: TDOMNode;
  Sorts: TDOMNodeList;
  I, Nb: Integer;
  Elem: TDOMElement;
  Liste: String;
begin
  Result := True;
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Chapitre := XMLDoc.GetElementsByTagName('DATA_SPELL').Item[0];
  if Chapitre = nil then Exit;
  Sorts := TDOMElement(Chapitre).GetElementsByTagName('Sort');
  Nb := 0;
  Liste := '';
  for I := 0 to Sorts.Count - 1 do
  begin
    Elem := TDOMElement(Sorts.Item[I]);
    if Trim(ValeurXML(Elem.FindNode('Talent'))) <> '' then Continue;
    if Trim(TalentsDeTable(Elem.GetAttribute('id'))) <> '' then Continue;
    Inc(Nb);
    if Nb <= 10 then
      Liste := Liste + LineEnding + '- ' + ValeurXML(Elem.FindNode('Description'));
  end;
  if Nb = 0 then Exit;
  if Nb > 10 then Liste := Liste + LineEnding + '...';
  Result := MessageDlg(Format(GetTexteLibelle('RULES-LAB_484'), [Nb, Liste + LineEnding + LineEnding]),
    mtWarning, [mbYes, mbNo], 0) = mrYes;
end;

// Un livre de traduction se reconnait a la balise TRANSLATION_OF de son en-tete.
function TWinLivres.EstLivreTraduction: Boolean;
begin
  Result := (XMLDoc <> nil) and (XMLDoc.DocumentElement <> nil)
    and (XMLDoc.DocumentElement.FindNode(ConstXmlTraductionDe) <> nil);
end;

// Grille anglais / traduction du livre ouvert. Le livre source est cherche dans le dossier du livre ouvert :
// celui dont CODE_BOOK vaut TRANSLATION_OF et qui n'est pas lui-meme une traduction.
procedure TWinLivres.AfficherTraduction;
var
  CodeSource, Dossier, Fichier, Candidat: String;
  Source: TXMLDocument;
  SR: TSearchRec;
begin
  MasquerAfficherElements('');
  MasquerForm();
  CodeSource := ValeurXML(XMLDoc.DocumentElement.FindNode(ConstXmlTraductionDe));
  Dossier := ExtractFilePath(CurrentFilePath);
  Fichier := '';
  if FindFirst(Dossier + '*.xml', faAnyFile, SR) = 0 then
  try
    repeat
      Candidat := Dossier + SR.Name;
      if (SR.Attr and faDirectory) <> 0 then Continue;
      if SameText(Candidat, CurrentFilePath) then Continue;
      if (XmlLivreBalise(Candidat, ConstXmlCodeLivre) = CodeSource)
        and (XmlLivreBalise(Candidat, ConstXmlTraductionDe) = '') then
      begin
        Fichier := Candidat;
        Break;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
  Source := nil;
  try
    if Fichier <> '' then ReadXMLFile(Source, Fichier);
    PanelTraduction.Charger(Source, XMLDoc);
  finally
    Source.Free;
  end;
  PanelTraduction.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelTraduction.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelTraduction.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelTraduction.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelTraduction.LectureSeule := not EditionPermise;
  PanelTraduction.Visible := True;
  CodeDonneeSelectionnee := 'TRADUCTION';
  if EditionPermise then PrendreSnapshotFiche;
end;

// Cree un livre de traduction vide (en-tete seul) pour un livre source et une langue, puis l'ouvre sur la grille.
// Fichier : <source>_<LANGUE>.Xml a cote de la source (BOOK_X.Xml -> BOOK_X_BRETON.Xml, INTERFACE.Xml -> INTERFACE_BRETON.Xml).
procedure TWinLivres.ButtonNouvelleTraductionClick(Sender: TObject);
var
  Dlg: TOpenDialog;
  Source, Cible, Langue, Code: String;
  Doc: TXMLDocument;
  Racine, Noeud: TDOMElement;
  I: Integer;

  procedure Ajouter(const Balise, Valeur: String);
  begin
    Noeud := Doc.CreateElement(Balise);
    Noeud.AppendChild(Doc.CreateTextNode('"' + Valeur + '"'));
    Racine.AppendChild(Noeud);
  end;

begin
  if not ConfirmerAbandonModifs then Exit;
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := GetTexteLibelle('RULES-LAB_677');
    Dlg.Filter := 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
    Dlg.InitialDir := ExtractFilePath(Application.ExeName) + 'DATABASE';
    if not Dlg.Execute then Exit;
    Source := Dlg.FileName;
  finally
    Dlg.Free;
  end;
  if XmlLivreBalise(Source, ConstXmlTraductionDe) <> '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_676'));
    Exit;
  end;
  Code := XmlLivreBalise(Source, ConstXmlCodeLivre);
  if Code = '' then Exit;
  Langue := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_672'), GetTexteLibelle('RULES-LAB_673'), Langue) then Exit;
  Langue := UpperCase(Trim(Langue));
  if Langue = '' then Exit;
  for I := 1 to Length(Langue) do
    if not (Langue[I] in ['A'..'Z', '_']) then
    begin
      ShowMessage(GetTexteLibelle('RULES-LAB_674'));
      Exit;
    end;
  Cible := ChangeFileExt(Source, '') + '_' + Langue + '.Xml';
  if FileExists(Cible) then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_675') + LineEnding + Cible);
    Exit;
  end;
  Doc := TXMLDocument.Create;
  try
    Racine := Doc.CreateElement(ConstXmlDataBook);
    Doc.AppendChild(Racine);
    Ajouter(ConstXmlCodeLivre, Code);
    Ajouter(ConstXmlLibelleLivre, XmlLivreBalise(Source, ConstXmlLibelleLivre));
    Ajouter('language', Langue);
    Ajouter(ConstXmlTraductionDe, Code);
    Ajouter(ConstXmlVersionLivre, XmlLivreBalise(Source, ConstXmlVersionLivre));
    Ajouter(ConstXmlOfficielLivre, XmlLivreBalise(Source, ConstXmlOfficielLivre));
    Ajouter(ConstXmlCompletLivre, '1');
    WriteXMLFile(Doc, Cible);
  finally
    Doc.Free;
  end;
  ChargerXMLFile(Cible);
end;

// Ecrit le livre de traduction ouvert dans DATABASE. L'ancienne version part dans
// DATABASE\HISTORIQUE\<CODE_BOOK>_<LANGUE>\TRADUCTION-<horodatage>.xml (jamais d'ecrasement).
procedure TWinLivres.TraductionEnregistrerClick(Sender: TObject);
var
  Temp, Cible, DossierHisto, CodeLivre, Langue: String;
begin
  if (XMLDoc = nil) or (CurrentFilePath = '') or not EstLivreTraduction then Exit;
  PanelTraduction.FinEdition;
  PanelTraduction.Ecrire(XMLDoc);
  CodeLivre := ValeurXML(XMLDoc.DocumentElement.FindNode(ConstXmlTraductionDe));
  Langue := ValeurXML(XMLDoc.DocumentElement.FindNode('language'));
  Temp := CurrentFilePath + '.tmp';
  Cible := '';
  try
    WriteXMLFile(XMLDoc, Temp);
    if FileExists(CurrentFilePath) then
    begin
      DossierHisto := ExtractFilePath(Application.ExeName) + 'DATABASE' + PathDelim + 'HISTORIQUE' + PathDelim
        + CodeLivre + '_' + Langue;
      if not ForceDirectories(DossierHisto) then
        raise Exception.Create('Dossier impossible a creer : ' + DossierHisto);
      Cible := IncludeTrailingPathDelimiter(DossierHisto) + 'TRADUCTION-' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.xml';
      if not RenameFile(CurrentFilePath, Cible) then
        raise Exception.Create('Deplacement impossible : ' + Cible);
    end;
    if not RenameFile(Temp, CurrentFilePath) then
    begin
      if Cible <> '' then RenameFile(Cible, CurrentFilePath);  // on remet l'ancien en place
      raise Exception.Create('Ecriture impossible : ' + CurrentFilePath);
    end;
    ShowMessage(GetTexteLibelle('RULES-LAB_671') + LineEnding + CurrentFilePath);
    AfficherTraduction;
  except
    on E: Exception do
    begin
      if FileExists(Temp) then DeleteFile(Temp);
      ShowMessage(E.Message);
    end;
  end;
end;

// Un livre ne s'ecrit qu'en anglais : dans une autre langue, les libelles traduits du Rulebook pourraient finir dans le fichier.
function TWinLivres.LangueExportOk: Boolean;
// Deux conditions : le livre ouvert n'est pas un livre de traduction (balise TRANSLATION_OF de l'en-tete :
// il ne s'enregistre ni ne s'importe), et l'interface est en anglais (libelles traduits sinon).
var
  Livre: TDOMNode;
begin
  Result := True;
  if XMLDoc <> nil then
  begin
    Livre := XMLDoc.GetElementsByTagName(ConstXmlDataBook).Item[0];
    // Un livre de traduction se reconnait a TRANSLATION_OF, pas a <language> (un livre peut etre d'origine non anglaise).
    if (Livre <> nil) and (Livre.FindNode(ConstXmlTraductionDe) <> nil) then Result := False;
  end;
  if not Result then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_504'));
    Exit;
  end;
  Result := ValLangue = ConstAnglais;
  if not Result then ShowMessage(GetTexteLibelle('RULES-LAB_487'));
end;

procedure TWinLivres.ButtonEnregistrerTravailClick(Sender: TObject);
var
  Dossier, Fichier: String;
begin
  if (XMLDoc = nil) or (CurrentFilePath = '') then Exit;
  if not LangueExportOk then Exit;
  if not ConfirmerSortsSansTalent then Exit;
  Dossier := DossierTravailLivre(CurrentFilePath);
  if not ForceDirectories(Dossier) then
  begin
    ShowMessage(Format(GetTexteLibelle('RULES-LAB_451'), [Dossier]));
    Exit;
  end;
  Fichier := IncludeTrailingPathDelimiter(Dossier) + FormatDateTime('yyyymmdd-hhnnss', Now) + '.xml';
  try
    WriteXMLFile(XMLDoc, Fichier);
    ShowMessage(GetTexteLibelle('RULES-LAB_349') + ' :' + LineEnding + Fichier);
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

// Publie XMLDoc comme nouvelle revision du livre : REVISION = date du jour dans DATA_BOOK,
// fichier ecrit a la place de celui de DATABASE, dont l'ancienne version est deplacee dans
// DATABASE\HISTORIQUE\<CODE_BOOK>\<ancienne REVISION>.xml (jamais d'ecrasement, CONTEXT.md 2.1).
// Le nouveau fichier est ecrit d'abord a cote (.tmp) : si l'ecriture echoue, rien n'a bouge.
procedure TWinLivres.ButtonPublierRevisionClick(Sender: TObject);
var
  Livre, NoeudRev, NoeudComplete, NoeudCode, NoeudLabel: TDOMNode;
  Ancien: TXMLDocument;
  Libelle, Aujourdhui, AncienneRev, CodeLivre, DossierHisto, Cible, Temp: String;
begin
  if (XMLDoc = nil) or (CurrentFilePath = '') then Exit;
  if not FileExists(CurrentFilePath) then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_353'));
    Exit;
  end;
  if not LangueExportOk then Exit;
  if not ConfirmerSortsSansTalent then Exit;
  if MessageDlg(GetTexteLibelle('RULES-LAB_350'), GetTexteLibelle('RULES-LAB_351'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  // Libelle facultatif : Annuler abandonne la publication, vide = pas de libelle
  Libelle := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_350'), GetTexteLibelle('RULES-LAB_354'), Libelle) then Exit;
  Libelle := Trim(Libelle);

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  if Livre = nil then Exit;
  Aujourdhui := FormatDateTime('yyyymmdd', Now);

  // Revision et code de l'ancien fichier (a defaut de REVISION : la date du fichier)
  AncienneRev := FormatDateTime('yyyymmdd', FileDateToDateTime(FileAge(CurrentFilePath)));
  CodeLivre := ChangeFileExt(ExtractFileName(CurrentFilePath), '');
  Ancien := nil;
  try
    ReadXMLFile(Ancien, CurrentFilePath);
    NoeudRev := Ancien.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('REVISION');
    if NoeudRev <> nil then
      AncienneRev := RemoveQuotes(Trim(UTF8Encode(NoeudRev.TextContent)));
    NoeudCode := Ancien.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('CODE_BOOK');
    if NoeudCode <> nil then
      CodeLivre := RemoveQuotes(Trim(UTF8Encode(NoeudCode.TextContent)));
  finally
    Ancien.Free;
  end;

  // REVISION dans le DATA_BOOK courant, juste apres COMPLETE (ordre du schema)
  NoeudRev := Livre.FindNode('REVISION');
  if NoeudRev = nil then
  begin
    NoeudRev := XMLDoc.CreateElement('REVISION');
    NoeudComplete := Livre.FindNode(ConstXmlCompletLivre);
    if (NoeudComplete <> nil) and (NoeudComplete.NextSibling <> nil) then
      Livre.InsertBefore(NoeudRev, NoeudComplete.NextSibling)
    else
      Livre.AppendChild(NoeudRev);
  end;
  EcrireValeurXML(TDOMElement(NoeudRev), Aujourdhui);

  // REVISION_LABEL juste apres REVISION : mis a jour, cree ou retire selon le libelle saisi
  NoeudLabel := Livre.FindNode('REVISION_LABEL');
  if Libelle = '' then
  begin
    if NoeudLabel <> nil then Livre.RemoveChild(NoeudLabel);
  end
  else
  begin
    if NoeudLabel = nil then
    begin
      NoeudLabel := XMLDoc.CreateElement('REVISION_LABEL');
      if NoeudRev.NextSibling <> nil then
        Livre.InsertBefore(NoeudLabel, NoeudRev.NextSibling)
      else
        Livre.AppendChild(NoeudLabel);
    end;
    EcrireValeurXML(TDOMElement(NoeudLabel), Libelle);
  end;

  DossierHisto := ExtractFilePath(Application.ExeName) + 'DATABASE' + PathDelim + 'HISTORIQUE' + PathDelim + CodeLivre;
  if not ForceDirectories(DossierHisto) then
  begin
    ShowMessage(Format(GetTexteLibelle('RULES-LAB_451'), [DossierHisto]));
    Exit;
  end;
  Cible := IncludeTrailingPathDelimiter(DossierHisto) + AncienneRev + '.xml';
  if FileExists(Cible) then
    Cible := IncludeTrailingPathDelimiter(DossierHisto) + AncienneRev + FormatDateTime('-hhnnss', Now) + '.xml';

  Temp := CurrentFilePath + '.tmp';
  try
    WriteXMLFile(XMLDoc, Temp);
    if not RenameFile(CurrentFilePath, Cible) then
      raise Exception.Create('Deplacement impossible : ' + Cible);
    if not RenameFile(Temp, CurrentFilePath) then
    begin
      RenameFile(Cible, CurrentFilePath);  // on remet l'ancien en place
      raise Exception.Create('Ecriture impossible : ' + CurrentFilePath);
    end;
    ShowMessage(GetTexteLibelle('RULES-LAB_352') + ' ' + Aujourdhui);
  except
    on E: Exception do
    begin
      if FileExists(Temp) then DeleteFile(Temp);
      ShowMessage(E.Message);
    end;
  end;
end;

// Livre inacheve : <COMPLETE> = 0 dans DATA_BOOK.
function TWinLivres.LivreInacheve: Boolean;
var
  Livre, Noeud: TDOMNode;
begin
  Result := False;
  if XMLDoc = nil then Exit;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  if Livre = nil then Exit;
  Noeud := Livre.FindNode(ConstXmlCompletLivre);
  Result := (Noeud <> nil) and (ValeurXML(Noeud) = '0');
end;

procedure TWinLivres.MajBoutonFinaliser;
begin
  ButtonFinaliser.Enabled := LivreInacheve and (CurrentFilePath <> '');
end;

// Finalisation : COMPLETE passe de 0 a 1 et l'etat en memoire remplace le stub de DATABASE.
// Le stub est deplace dans DATABASE\HISTORIQUE\<CODE_BOOK>\BROUILLON-<horodatage>.xml (jamais d'ecrasement).
// TRAVAIL\ n'est plus relu (DerniereVersionTravail ne joue que pour COMPLETE = 0) et reste en historique.
procedure TWinLivres.ButtonMettreAJourClick(Sender: TObject);
// Remplace le livre dans les listes globales par l'ebauche (XmlMajLivre). L'ebauche est ecrite dans un
// fichier temporaire : DATABASE n'est pas touche. Echec : XmlMajLivre restaure le dernier etat bon.
var
  Code, Origine, Ebauche, Erreur: String;
begin
  if (XMLDoc = nil) or (CurrentFilePath = '') then Exit;
  if not LangueExportOk then Exit;
  if not ConfirmerSortsSansTalent then Exit;
  Code    := ChangeFileExt(ExtractFileName(CurrentFilePath), '');
  Origine := GetCurrentDir + ConstCheminLivre + Code + '.xml';
  Ebauche := IncludeTrailingPathDelimiter(GetTempDir) + 'WinLivre_' + Code + '_' + FormatDateTime('hhnnsszzz', Now) + '.xml';
  try
    WriteXMLFile(XMLDoc, Ebauche);
    if (not FileExists(Origine))
      or (XmlLivreBalise(Ebauche, ConstXmlLibelleLivre) <> XmlLivreBalise(Origine, ConstXmlLibelleLivre)) then
    begin
      ShowMessage(GetTexteLibelle('RULES-LAB_502'));
      DeleteFile(Ebauche);
      Exit;
    end;
    Erreur := XmlMajLivre(Code, Ebauche, DerniereEbauche);
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      DeleteFile(Ebauche);
      Exit;
    end;
  end;
  if Erreur <> '' then
  begin
    DeleteFile(Ebauche);
    ShowMessage(GetTexteLibelle('RULES-LAB_501') + LineEnding + Erreur);
    Exit;
  end;
  if DerniereEbauche <> '' then DeleteFile(DerniereEbauche);
  DerniereEbauche := Ebauche;
  ShowMessage(GetTexteLibelle('RULES-LAB_500'));
end;

procedure TWinLivres.ButtonFinaliserClick(Sender: TObject);
var
  Livre, NoeudCode, NoeudComplete: TDOMNode;
  CodeLivre, DossierHisto, Cible, Temp: String;
begin
  if (XMLDoc = nil) or (CurrentFilePath = '') or not LivreInacheve then Exit;
  if not LangueExportOk then Exit;
  if not ConfirmerAbandonModifs then Exit;
  if MessageDlg(GetTexteLibelle('RULES-LAB_433'), GetTexteLibelle('RULES-LAB_434'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  NoeudComplete := Livre.FindNode(ConstXmlCompletLivre);
  CodeLivre := ChangeFileExt(ExtractFileName(CurrentFilePath), '');
  NoeudCode := Livre.FindNode('CODE_BOOK');
  if NoeudCode <> nil then
    CodeLivre := ValeurXML(NoeudCode);

  EcrireValeurXML(TDOMElement(NoeudComplete), '1');
  Temp := CurrentFilePath + '.tmp';
  Cible := '';
  try
    WriteXMLFile(XMLDoc, Temp);
    if FileExists(CurrentFilePath) then
    begin
      DossierHisto := ExtractFilePath(Application.ExeName) + 'DATABASE' + PathDelim + 'HISTORIQUE' + PathDelim + CodeLivre;
      if not ForceDirectories(DossierHisto) then
        raise Exception.Create('Dossier impossible a creer : ' + DossierHisto);
      Cible := IncludeTrailingPathDelimiter(DossierHisto) + 'BROUILLON-' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.xml';
      if not RenameFile(CurrentFilePath, Cible) then
        raise Exception.Create('Deplacement impossible : ' + Cible);
    end;
    if not RenameFile(Temp, CurrentFilePath) then
    begin
      if Cible <> '' then RenameFile(Cible, CurrentFilePath);  // on remet l'ancien en place
      raise Exception.Create('Ecriture impossible : ' + CurrentFilePath);
    end;
    MajBoutonFinaliser;
    ShowMessage(GetTexteLibelle('RULES-LAB_435') + ' :' + LineEnding + CurrentFilePath);
  except
    on E: Exception do
    begin
      EcrireValeurXML(TDOMElement(NoeudComplete), '0');
      if FileExists(Temp) then DeleteFile(Temp);
      ShowMessage(E.Message);
    end;
  end;
end;

// ========== HELPER FUNCTION ==========
function TWinLivres.GetBookLabel(BookCode: String): String;
begin
  // Les fichiers s'appellent BOOK_XXX.Xml, le code livre est "BOOK XXX"
  Result := GetTexteLibelle(StringReplace(BookCode, '_', ' ', [rfReplaceAll]), '', '', true);
end;

// ========== PARSE ATTRIBUTE VALUE ==========
procedure TWinLivres.ParseAttributValue(Valeur: String; out AttrType: String; out Dices: String; out BaseValue: String; out SimpleValue: String; out Formula: String);
var
  PosD10: Integer;
  PosPlus: Integer;
  DicesPart: String;
begin
  Dices := '';
  BaseValue := '';
  SimpleValue := '';
  Formula := '';
  AttrType := '';
  
  // Enlever les guillemets si présents
  if (Length(Valeur) > 0) and (Valeur[1] = '"') then
    Valeur := Copy(Valeur, 2, Length(Valeur) - 2);
  if (Length(Valeur) > 0) and (Valeur[Length(Valeur)] = '"') then
    Valeur := Copy(Valeur, 1, Length(Valeur) - 1);
  
  PosD10 := Pos('d10', Valeur);
  
  if PosD10 > 0 then
  begin
    // Type 1: Format simple avec dés: "2d10+20"
    AttrType := 'DICES';
    DicesPart := Copy(Valeur, 1, PosD10 - 1);
    Dices := DicesPart;
    
    // Chercher la partie +X après d10
    PosPlus := Pos('+', Valeur);
    if PosPlus > 0 then
      BaseValue := Copy(Valeur, PosPlus + 1, Length(Valeur))
    else
      BaseValue := '0';
  end
  else if Pos('xBATTR_', Valeur) > 0 then
  begin
    // Type 2: Format complexe avec références à attributs: "1xBATTR_S+2xBATTR_T..."
    AttrType := 'FORMULA';
    Formula := Valeur;
  end
  else
  begin
    // Type 3: Valeur fixe simple: "2", "1", "3", "4"
    AttrType := 'SIMPLE';
    SimpleValue := Valeur;
  end;
end;

// ========== TRANSLATE BATTR CODE ==========
function TWinLivres.TranslateBATTRCode(BATTRCode: String): String;
var
  AttrCode: String;
begin
  // BATTR_S → RULES-ATTR_S, etc.
  AttrCode := 'RULES-ATTR_' + Copy(BATTRCode, 7, Length(BATTRCode));
  Result := GetAttributLabel(AttrCode);
end;

// ========== PARSE FORMULA COMPONENTS ==========
function TWinLivres.ParseFormulaComponents(Formula: String): TFormulaComponentArray;
var
  Parts: TStringList;
  I: Integer;
  Part: String;
  PosX: Integer;
  Coefficient: String;
  AttrCode: String;
  Component: TFormulaComponent;
begin
  Result := nil;
  
  // Enlever les guillemets
  if (Length(Formula) > 0) and (Formula[1] = '"') then
    Formula := Copy(Formula, 2, Length(Formula) - 2);
  if (Length(Formula) > 0) and (Formula[Length(Formula)] = '"') then
    Formula := Copy(Formula, 1, Length(Formula) - 1);
  
  // Remplacer les '+' par des séparateurs
  Formula := StringReplace(Formula, '+', '|', [rfReplaceAll]);
  Formula := StringReplace(Formula, '|', '+', [rfReplaceAll]);
  
  Parts := TStringList.Create;
  try
    ExtractStrings(['+'], [], PChar(Formula), Parts);
    
    for I := 0 to Parts.Count - 1 do
    begin
      Part := Trim(Parts[I]);
      if Part = '' then Continue;
      
      // Parser "1xBATTR_S"
      PosX := Pos('x', Part);
      if PosX > 0 then
      begin
        Coefficient := Copy(Part, 1, PosX - 1);
        AttrCode := Copy(Part, PosX + 1, Length(Part));
        
        Component.Coefficient := StrToIntDef(Coefficient, 0);
        Component.AttrCode := AttrCode;
        Component.AttrLabel := TranslateBATTRCode(AttrCode);
        
        SetLength(Result, Length(Result) + 1);
        Result[Length(Result) - 1] := Component;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

// ========== GET ATTRIBUTE LABEL ==========
function TWinLivres.GetAttributLabel(CodeAttribut: String): String;
var
  TextElements: TDOMNodeList;
  I: Integer;
  XMLElement: TDOMElement;
  Libelle: String;
begin
  Result := CodeAttribut;  // Fallback
  
  if XMLDoc = nil then Exit;
  
  // Chercher dans DATA_LABEL
  TextElements := XMLDoc.GetElementsByTagName('Text');
  
  for I := 0 to TextElements.Count - 1 do
  begin
    XMLElement := TDOMElement(TextElements.Item[I]);
    if XMLElement.GetAttribute('name') = CodeAttribut then
    begin
      Result := XMLElement.TextContent;
      if (Length(Result) > 0) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
        Result := Copy(Result, 2, Length(Result) - 2);
      Exit;
    end;
  end;
  
  // Absent du DATA_LABEL du livre : libellé d'interface (les attributs et
  // les titres de branche y sont définis, pas dans le livre).
  Libelle := GetTexteLibelle(CodeAttribut);
  if Libelle <> '' then
    Result := Libelle;
  // caracteristique propre a WFRP1 (Ld...) : sa Description est dans le livre ouvert ou le Rulebook
  if Result = CodeAttribut then
  begin
    XMLElement := TrouverElementParId('Attribut', CodeAttribut);
    if XMLElement <> nil then Libelle := ValeurXML(XMLElement.FindNode('Description')) else Libelle := '';
    // la ligne <Attribut name="..."> d'une ethnie est trouvee par name= mais n'a pas de Description : repli sur le Rulebook
    if Libelle = '' then Libelle := LibelleCodeV1(CodeAttribut);
    // dernier recours : la definition <Attribut id> du Rulebook (langue des livres, puis anglais)
    if (Libelle = '') and (RulebookXML <> nil) then
    begin
      TextElements := RulebookXML.GetElementsByTagName('Attribut');
      for I := 0 to TextElements.Count - 1 do
        if (Libelle = '') and (TDOMElement(TextElements.Item[I]).GetAttribute('id') = CodeAttribut) then
          Libelle := ValeurXML(TextElements.Item[I].FindNode('Description'));
    end;
    if (Libelle = '') and (RulebookBaseXML <> nil) then
    begin
      TextElements := RulebookBaseXML.GetElementsByTagName('Attribut');
      for I := 0 to TextElements.Count - 1 do
        if (Libelle = '') and (TDOMElement(TextElements.Item[I]).GetAttribute('id') = CodeAttribut) then
          Libelle := ValeurXML(TextElements.Item[I].FindNode('Description'));
    end;
    if Libelle <> '' then Result := Libelle;
  end;
end;

// ========== LOAD ATTRIBUTES FOR RACE ==========
procedure TWinLivres.LoadAttributesForRace(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
var
  AttrChapter: TDOMNode;
  AttrElements: TDOMNodeList;
  I: Integer;
  AttrElement: TDOMElement;
  AttrCode, AttrValue: String;
  NodeAttributes, NodeAttr: TTreeNode;
begin
  // Chercher la section SUBCHAPTER_ATTR
  AttrChapter := RaceElement.FindNode('SUBCHAPTER_ATTR');
  
  if AttrChapter = nil then Exit;
  
  // Créer la branche "Attributs"
  NodeAttributes := TreeViewLivre.Items.AddChild(RaceNode, GetAttributLabel('RULES-LAB_008'));
  SetNodeInfo(NodeAttributes, NT_ATTRIBUTS_ETHNIE, RaceCode);  // 54 = attributs d'une ethnie (tableaux)
  
  // Récupérer tous les éléments Attribut
  AttrElements := TDOMElement(AttrChapter).GetElementsByTagName('Attribut');
  
  if AttrElements.Count > 0 then
  begin
    for I := 0 to AttrElements.Count - 1 do
    begin
      AttrElement := TDOMElement(AttrElements.Item[I]);
      AttrCode := AttrElement.GetAttribute('name');
      AttrValue := AttrElement.TextContent;
      
      if AttrCode = '' then Continue;
      
      // Créer un nœud pour cet attribut
      NodeAttr := TreeViewLivre.Items.AddChild(NodeAttributes, GetAttributLabel(AttrCode) + ': ' + AttrValue);
      SetNodeInfo(NodeAttr, NT_ATTRIBUT);  // 2 = attribut
    end;
  end;
end;

// ========== LOAD SKILLS FOR RACE IN TREE ==========
// Noeud(s) d'une competence d'ethnie : une feuille ; un choix "A/B/C" donne un noeud "au choix"
// avec une feuille par option, comme pour les talents (la competence combinee n'a pas besoin
// d'etre declaree).
procedure TWinLivres.AjouterNoeudSkill(Pere: TTreeNode; const SkillCode: String);
var
  Competence: StructureCompetence;
  Noeud: TTreeNode;
  Parts: TStringList;
  J: Integer;
begin
  if Pos('/', SkillCode) > 0 then
  begin
    Noeud := TreeViewLivre.Items.AddChild(Pere, GetTexteLibelle('RULES-LAB_127'));
    SetNodeInfo(Noeud, NT_CHOIX);  // 7 = choice node
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := '/';
      Parts.DelimitedText := SkillCode;
      for J := 0 to Parts.Count - 1 do
      begin
        Competence := ChercheCompetence(Trim(Parts[J]));
        if Competence.CodeCompetence <> '' then
          SetNodeInfo(TreeViewLivre.Items.AddChild(Noeud, Competence.Libelle), NT_COMPETENCE)  // 4 = skill item
        else
          SetNodeInfo(TreeViewLivre.Items.AddChild(Noeud, Trim(Parts[J])), 4);
      end;
    finally
      Parts.Free;
    end;
  end
  else
  begin
    Competence := ChercheCompetence(SkillCode);
    if Competence.CodeCompetence <> '' then
      SetNodeInfo(TreeViewLivre.Items.AddChild(Pere, Competence.Libelle), NT_COMPETENCE);
  end;
end;

procedure TWinLivres.LoadSkillsForRaceTree(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
var
  SkillChapter: TDOMNode;
  SkillElements: TDOMNodeList;
  I: Integer;
  SkillCode: String;
  NodeSkills: TTreeNode;
  SkillNode: TDOMNode;
begin
  SkillChapter := RaceElement.FindNode('SUBCHAPTER_SKILL');
  
  if SkillChapter = nil then Exit;
  
  // Créer la branche "Compétences" (traduite)
  NodeSkills := TreeViewLivre.Items.AddChild(RaceNode, GetTexteLibelle('RULES-LAB_087'));
  SetNodeInfo(NodeSkills, NT_COMPETENCES_RACE, RaceCode);  // 3 = skills chapter
  
  // Récupérer les enfants directs de SUBCHAPTER_SKILL (pas récursif!)
  SkillElements := SkillChapter.ChildNodes;
  
  if SkillElements.Count > 0 then
  begin
    for I := 0 to SkillElements.Count - 1 do
    begin
      SkillNode := SkillElements[I];
      if SkillNode.NodeName = 'Skill' then
      begin
        SkillCode := Trim(SkillNode.TextContent);
        // Enlever les guillemets
        if (Length(SkillCode) > 0) and (SkillCode[1] = '"') then
          SkillCode := Copy(SkillCode, 2, Length(SkillCode) - 2);
        if (Length(SkillCode) > 0) and (SkillCode[Length(SkillCode)] = '"') then
          SkillCode := Copy(SkillCode, 1, Length(SkillCode) - 1);
        
        if SkillCode = '' then Continue;
        
        AjouterNoeudSkill(NodeSkills, SkillCode);
      end;
    end;
  end;
end;

// ========== CHARGER TALENTS POUR RACE ==========
// Noeud(s) d'un talent d'ethnie : aleatoire (RULES-T*), choix "A/B" (noeud "au choix" avec une
// feuille par option) ou talent fixe.
procedure TWinLivres.AjouterNoeudTalent(Pere: TTreeNode; const TalentCode: String);
var
  Talent: StructureTalent;
  NodeTalent, NodeChoice: TTreeNode;
  TalentParts: TStringList;
  J: Integer;
begin
  if TalentCode = 'RULES-T*' then
  begin
    NodeTalent := TreeViewLivre.Items.AddChild(Pere, GetTexteLibelle('RULES-LAB_085'));  // "Randomly"
    SetNodeInfo(NodeTalent, NT_TALENT_ALEATOIRE);  // 6 = random talent
  end
  else if Pos('/', TalentCode) > 0 then
  begin
    NodeChoice := TreeViewLivre.Items.AddChild(Pere, GetTexteLibelle('RULES-LAB_127'));
    SetNodeInfo(NodeChoice, NT_CHOIX);  // 7 = choice node
    TalentParts := TStringList.Create;
    try
      TalentParts.StrictDelimiter := True;
      TalentParts.Delimiter := '/';
      TalentParts.DelimitedText := TalentCode;
      for J := 0 to TalentParts.Count - 1 do
      begin
        Talent := ChercheTalent(Trim(TalentParts[J]));
        if Talent.CodeTalent <> '' then
        begin
          NodeTalent := TreeViewLivre.Items.AddChild(NodeChoice, Talent.Libelle);
          SetNodeInfo(NodeTalent, NT_TALENT_CHOIX);  // 8 = talent choice item
        end;
      end;
    finally
      TalentParts.Free;
    end;
  end
  else
  begin
    Talent := ChercheTalent(TalentCode);
    if Talent.CodeTalent <> '' then
    begin
      NodeTalent := TreeViewLivre.Items.AddChild(Pere, Talent.Libelle);
      SetNodeInfo(NodeTalent, NT_TALENT_CHOIX);  // 8 = talent item
    end;
  end;
end;

procedure TWinLivres.LoadTalentsForRaceTree(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
var
  TalentChapter, TalentNode: TDOMNode;
  NodeTalents: TTreeNode;
  TalentCode: String;
begin
  TalentChapter := RaceElement.FindNode('SUBCHAPTER_TALENT');
  if TalentChapter = nil then Exit;

  // Branche "Talents" (traduite)
  NodeTalents := TreeViewLivre.Items.AddChild(RaceNode, GetTexteLibelle('RULES-LAB_007'));
  SetNodeInfo(NodeTalents, NT_TALENTS_RACE, RaceCode);  // 5 = talents chapter

  TalentNode := TalentChapter.FirstChild;
  while TalentNode <> nil do
  begin
    if TalentNode.NodeName = 'Talent' then
    begin
      TalentCode := ValeurXML(TalentNode);
      if TalentCode <> '' then
        AjouterNoeudTalent(NodeTalents, TalentCode);
    end;
    TalentNode := TalentNode.NextSibling;
  end;
end;

// ========== CHARGER CARRIÈRES POUR RACE ==========
// Tranches du d100 de corruption physique et mentale propres à une race :
// ce sont les <Specie name="..."> de DATA_CORRUPTION_PHYSICAL / _MENTAL,
// rangés chacun sous leur race. Une race absente de la liste n'a pas de noeud.
procedure TWinLivres.LoadCorruptionForRaceTree(RaceNode: TTreeNode; RaceCode: String);
const
  Chapitres: array[0..1] of String = ('DATA_CORRUPTION_PHYSICAL', 'DATA_CORRUPTION_MENTAL');
var
  Chap: TDOMNodeList;
  Elements: TDOMNodeList;
  I, J: Integer;
  Trouve: Boolean;
  Node: TTreeNode;
begin
  if XMLDoc = nil then Exit;
  Trouve := False;
  for I := 0 to 1 do
  begin
    Chap := XMLDoc.GetElementsByTagName(Chapitres[I]);
    if Chap.Count = 0 then Continue;
    Elements := TDOMElement(Chap.Item[0]).GetElementsByTagName('Specie');
    for J := 0 to Elements.Count - 1 do
      if TDOMElement(Elements.Item[J]).GetAttribute('name') = RaceCode then
        Trouve := True;
  end;
  if not Trouve then Exit;  // race sans tranche dans ce livre : pas de noeud
  Node := TreeViewLivre.Items.AddChild(RaceNode, GetTexteLibelle('RULES-LAB_156'));
  SetNodeInfo(Node, NT_CORRUPTION_ETHNIE, RaceCode);  // 55 = tranches de corruption d'une ethnie (modifiables)
end;

procedure TWinLivres.LoadCareersForRaceTree(RaceElement: TDOMElement; RaceNode: TTreeNode; RaceCode: String);
var
  NodeCareers: TTreeNode;
begin
  if RaceElement.FindNode('SUBCHAPTER_CAREER') = nil then Exit;

  // Créer la branche "Career" (traduite)
  NodeCareers := TreeViewLivre.Items.AddChild(RaceNode, GetTexteLibelle('RULES-LAB_006'));
  SetNodeInfo(NodeCareers, NT_CARRIERES_RACE, RaceCode);  // 9 = careers chapter
  RemplirNoeudCarrieres(RaceElement, NodeCareers);
end;

// Une feuille par <Career> de l'ethnie sous la branche des carrieres.
procedure TWinLivres.RemplirNoeudCarrieres(RaceElement: TDOMElement; NodeCareers: TTreeNode);
var
  CareerChapter: TDOMNode;
  CareerElements: TDOMNodeList;
  I: Integer;
  CareerCode, CareerDesc, DisplayText: String;
  NodeCareer: TTreeNode;
  CareerNode: TDOMNode;
  Metier: StructureMetier;
  Livre: StructureLivre;
begin
  CareerChapter := RaceElement.FindNode('SUBCHAPTER_CAREER');
  if CareerChapter = nil then Exit;

  // Récupérer les enfants directs de SUBCHAPTER_CAREER
  CareerElements := CareerChapter.ChildNodes;
  
  if CareerElements.Count > 0 then
  begin
    for I := 0 to CareerElements.Count - 1 do
    begin
      CareerNode := CareerElements[I];
      if CareerNode.NodeName = 'Career' then
      begin
        CareerCode := TDOMElement(CareerNode).GetAttribute('name');
        
        if CareerCode = '' then Continue;
        
        // Chercher la carrière dans ListMetier (charge tous les livres)
        Metier := ChercheMetier(CareerCode);
        
        if Metier.CodeMetier <> '' then
        begin
          CareerDesc := Metier.Libelle;
          
          // Chercher le nom du livre via le code du livre
          Livre := ChercheLivreLibelle(Metier.Livre);
          
          // Afficher: "Nom Métier (Nom Livre)"
          if Livre.CodeLivre <> '' then
            DisplayText := CareerDesc + ' (' + GetTexteLibelle(Livre.Libelle) + ')'
          else
            DisplayText := CareerDesc + ' (' + Metier.Livre + ')';  // Fallback avec code livre
        end
        else
        begin
          CareerDesc := CareerCode;  // Fallback si métier pas trouvé
          DisplayText := CareerDesc;
        end;
        
        // Créer un nœud pour cette carrière
        NodeCareer := TreeViewLivre.Items.AddChild(NodeCareers, DisplayText);
        SetNodeInfo(NodeCareer, NT_CARRIERE);  // 13 = career item
      end;
    end;
  end;
end;

// ========== AFFICHER DONNÉE ATTRIBUT ==========
procedure TWinLivres.AfficherDonneeAttribut(ACode: String);
var
  AttrType: String;
  Dices, BaseValue, SimpleValue, Formula: String;
  FormulaComponents: TFormulaComponentArray;
  I: Integer;
begin
  NettoyerForm();
  
  // Parser la valeur de l'attribut
  ParseAttributValue(ACode, AttrType, Dices, BaseValue, SimpleValue, Formula);
  
  // Masquer tous les contrôles de race
  
  // Afficher selon le type d'attribut
  case AttrType of
    'SIMPLE': begin
      // Type 3: Valeur fixe (ex: "2", "1", "3", "4")
      LabelFormAttrName.Visible := False;
      EditFormAttrName.Visible := False;
      
      LabelFormAttrDices.Visible := False;
      EditFormAttrDices.Visible := False;
      LabelFormAttrBaseValue.Visible := True;
      EditFormAttrBaseValue.Visible := True;
      EditFormAttrBaseValue.Text := SimpleValue;
      LabelFormAttrBaseValue.Caption := GetTexteLibelle('RULES-LAB_025'); // 'Value'
      LabelFormAttrFormula.Visible := False;
      EditFormAttrFormula.Visible := False;
      
      for I := 1 to 3 do
        HideComponentControls(I);
    end;
    
    'DICES': begin
      // Type 1: Format avec dés (ex: "2d10+20")
      LabelFormAttrName.Visible := False;
      EditFormAttrName.Visible := False;
      
      LabelFormAttrDices.Visible := True;
      EditFormAttrDices.Visible := True;
      EditFormAttrDices.Text := Dices;
      LabelFormAttrDices.Caption := GetTexteLibelle('RULES-LAB_161'); // 'Dices'
      
      LabelFormAttrBaseValue.Visible := True;
      EditFormAttrBaseValue.Visible := True;
      EditFormAttrBaseValue.Text := BaseValue;
      LabelFormAttrBaseValue.Caption := GetTexteLibelle('RULES-LAB_025'); // 'Value'
      
      LabelFormAttrFormula.Visible := False;
      EditFormAttrFormula.Visible := False;
      
      for I := 1 to 3 do
        HideComponentControls(I);
    end;
    
    'FORMULA': begin
      // Type 2: Format calculé (ex: "1xBATTR_S+2xBATTR_T+1xBATTR_WP")
      // Afficher les composants avec label = attribut, champ = coefficient
      LabelFormAttrName.Visible := False;
      EditFormAttrName.Visible := False;
      
      // Masquer les champs simples/dices
      LabelFormAttrDices.Visible := False;
      EditFormAttrDices.Visible := False;
      LabelFormAttrBaseValue.Visible := False;
      EditFormAttrBaseValue.Visible := False;
      LabelFormAttrFormula.Visible := False;
      EditFormAttrFormula.Visible := False;
      
      // Parser et afficher les composants
      FormulaComponents := ParseFormulaComponents(Formula);
      for I := 0 to Length(FormulaComponents) - 1 do
      begin
        if I < 3 then
          ShowComponentControl(I + 1, FormulaComponents[I].AttrLabel, IntToStr(FormulaComponents[I].Coefficient));
      end;
      
      // Masquer les composants inutilisés
      for I := Length(FormulaComponents) + 1 to 3 do
        HideComponentControls(I);
    end;
  end;
  
  GroupBoxForm.Visible := True;
end;

procedure TWinLivres.ShowComponentControl(Index: Integer; AttrLabel: String; Coefficient: String);
begin
  case Index of
    1: begin
      LabelFormComponent1.Visible := True;
      EditFormComponent1Coeff.Visible := True;
      LabelFormComponent1.Caption := AttrLabel + ':';  // Label = Attribute name
      EditFormComponent1Coeff.Text := Coefficient;     // Field = just the number
      EditFormComponent1Attr.Visible := False;         // Hide the attribute field
    end;
    2: begin
      LabelFormComponent2.Visible := True;
      EditFormComponent2Coeff.Visible := True;
      LabelFormComponent2.Caption := AttrLabel + ':';
      EditFormComponent2Coeff.Text := Coefficient;
      EditFormComponent2Attr.Visible := False;
    end;
    3: begin
      LabelFormComponent3.Visible := True;
      EditFormComponent3Coeff.Visible := True;
      LabelFormComponent3.Caption := AttrLabel + ':';
      EditFormComponent3Coeff.Text := Coefficient;
      EditFormComponent3Attr.Visible := False;
    end;
  end;
end;

procedure TWinLivres.HideComponentControls(Index: Integer);
begin
  case Index of
    1: begin
      LabelFormComponent1.Visible := False;
      EditFormComponent1Attr.Visible := False;
      EditFormComponent1Coeff.Visible := False;
    end;
    2: begin
      LabelFormComponent2.Visible := False;
      EditFormComponent2Attr.Visible := False;
      EditFormComponent2Coeff.Visible := False;
    end;
    3: begin
      LabelFormComponent3.Visible := False;
      EditFormComponent3Attr.Visible := False;
      EditFormComponent3Coeff.Visible := False;
    end;
  end;
end;

// ========== BRANCHE MÉTIER (niveau 1) ==========

// Sous-branche "Races possibles" : les races dont le SUBCHAPTER_CAREER
// référence ce métier. On lit la map pré-calculée pour éviter de rebalayer
// toutes les races pour chaque métier.
procedure TWinLivres.LoadMetierRacesPossibles(CareerCode: String; MetierNode: TTreeNode);
var
  NodeBranche, NodeFeuille: TTreeNode;
  ListeCodes: TStringList;
  I, Idx: Integer;
  CodeRace, LibelleRace: String;
  PRace: PRaceData;
begin
  if MetierRacesMap = nil then Exit;
  
  // Rien à afficher si aucune race ne propose ce métier
  if MetierRacesMap.Values[CareerCode] = '' then Exit;
  
  NodeBranche := TreeViewLivre.Items.AddChild(MetierNode, ConstArbreRacePossible);
  SetNodeInfo(NodeBranche, NT_RACES_POSSIBLES, CareerCode);  // 15 = branche races possibles
  
  ListeCodes := TStringList.Create;
  try
    ListeCodes.Delimiter     := '|';
    ListeCodes.StrictDelimiter := True;
    ListeCodes.DelimitedText := MetierRacesMap.Values[CareerCode];
    
    for I := 0 to ListeCodes.Count - 1 do
    begin
      CodeRace := ListeCodes[I];
      if CodeRace = '' then Continue;
      
      // Libellé de la race depuis les données déjà chargées
      LibelleRace := CodeRace;  // fallback
      if RacesDataList <> nil then
      begin
        Idx := RacesDataList.IndexOf(CodeRace);
        if Idx >= 0 then
        begin
          PRace := RacesDataList.Data[Idx];
          if PRace <> nil then
            LibelleRace := PRace^.Libelle;
        end;
      end;
      
      NodeFeuille := TreeViewLivre.Items.AddChild(NodeBranche, LibelleRace);
      SetNodeInfo(NodeFeuille, NT_RACE_POSSIBLE, CodeRace);  // 16 = race possible
    end;
  finally
    ListeCodes.Free;
  end;
end;

// Sous-branche "Attribut" d'un niveau de métier
procedure TWinLivres.LoadMetierNiveauAttributs(CareerElement: TDOMElement; Niveau: Integer; CodeNiveau: String; NodeBase: TTreeNode);
var
  Chapitre: TDOMNode;
  NodeBranche: TTreeNode;
begin
  Chapitre := CareerElement.FindNode('SUBCHAPTER_ATTR');
  if Chapitre = nil then Exit;
  
  NodeBranche := TreeViewLivre.Items.AddChild(NodeBase, ConstArbreAttribut);
  SetNodeInfo(NodeBranche, NT_BRANCHE_ATTRIBUT_NIVEAU, CodeNiveau);  // 18 = branche attributs du niveau
  RemplirBrancheNiveauAttributs(NodeBranche, Chapitre, Niveau);
end;

// Feuilles d'une branche "Attribut" : les <Attribut> du chapitre dont la valeur est ce niveau.
procedure TWinLivres.RemplirBrancheNiveauAttributs(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer);
var
  Elements: TDOMNodeList;
  I: Integer;
  NodeFeuille: TTreeNode;
  CodeAttr: String;
begin
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Attribut');
  for I := 0 to Elements.Count - 1 do
  begin
    // On ne garde que les attributs dont la valeur correspond au niveau
    if ValeurXML(Elements.Item[I]) <> IntToStr(Niveau) then Continue;
    CodeAttr := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeAttr = '' then Continue;
    NodeFeuille := TreeViewLivre.Items.AddChild(NodeBranche, GetAttributLabel(CodeAttr));
    SetNodeInfo(NodeFeuille, NT_ATTRIBUT_NIVEAU, CodeAttr);  // 19 = attribut du niveau
  end;
end;

// Libelle d'un code de competence (Genre 'S') ou de talent (Genre 'T') du niveau d'une carriere : un choix
// « A/B » est libelle morceau par morceau (le code brut n'a pas de fiche) ; un code inconnu reste tel quel.
function LibelleChoixNiveau(const Code, Genre: String): String;
var
  Morceaux: TStringList;
  I: Integer;
  Lib: String;
begin
  Morceaux := TStringList.Create;
  try
    Morceaux.Delimiter := '/';
    Morceaux.StrictDelimiter := True;
    Morceaux.DelimitedText := Code;
    Result := '';
    for I := 0 to Morceaux.Count - 1 do
    begin
      if Genre = 'S' then
        Lib := ChercheCompetence(Morceaux[I]).Libelle
      else
        Lib := ChercheTalent(Morceaux[I]).Libelle;
      if Lib = '' then Lib := Morceaux[I];
      if I > 0 then Result := Result + '/';
      Result := Result + Lib;
    end;
  finally
    Morceaux.Free;
  end;
end;

// Feuilles d'une branche "Compétence" d'un niveau : les <Skill> du chapitre dont la valeur est ce niveau.
// SkillPrincipal = le <Skill> racine du <Career>, marqué d'une étoile.
procedure TWinLivres.RemplirBrancheNiveauCompetences(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer; SkillPrincipal: String);
var
  Elements: TDOMNodeList;
  I: Integer;
  NodeFeuille: TTreeNode;
  CodeComp, LibComp: String;
  Competence: StructureCompetence;
begin
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Skill');
  for I := 0 to Elements.Count - 1 do
  begin
    if ValeurXML(Elements.Item[I]) <> IntToStr(Niveau) then Continue;
    CodeComp := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeComp = '' then Continue;
    Competence := ChercheCompetence(CodeComp);
    if Competence.CodeCompetence <> '' then
      LibComp := Competence.Libelle
    else
      LibComp := LibelleChoixNiveau(CodeComp, 'S');  // choix A/B ou compétence inconnue
    if CodeComp = SkillPrincipal then
      LibComp := LibComp + ' *';
    NodeFeuille := TreeViewLivre.Items.AddChild(NodeBranche, LibComp);
    SetNodeInfo(NodeFeuille, NT_COMPETENCE_NIVEAU, CodeComp);  // 21 = compétence du niveau
  end;
end;

// Sous-branche "Compétence" d'un niveau de métier.
procedure TWinLivres.LoadMetierNiveauCompetences(CareerElement: TDOMElement; Niveau: Integer; SkillPrincipal: String; CodeNiveau: String; NodeBase: TTreeNode);
var
  Chapitre: TDOMNode;
  NodeBranche: TTreeNode;
begin
  Chapitre := CareerElement.FindNode('SUBCHAPTER_SKILL');
  if Chapitre = nil then Exit;
  NodeBranche := TreeViewLivre.Items.AddChild(NodeBase, ConstArbreCompetence);
  SetNodeInfo(NodeBranche, NT_BRANCHE_COMPETENCE_NIVEAU, CodeNiveau);  // 20 = branche compétences du niveau
  RemplirBrancheNiveauCompetences(NodeBranche, Chapitre, Niveau, SkillPrincipal);
end;

procedure TWinLivres.RemplirBrancheNiveauTalents(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer);
var
  Elements: TDOMNodeList;
  I: Integer;
  NodeFeuille: TTreeNode;
  CodeTal, LibTal: String;
  Talent: StructureTalent;
begin
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Talent');
  for I := 0 to Elements.Count - 1 do
  begin
    if ValeurXML(Elements.Item[I]) <> IntToStr(Niveau) then Continue;
    CodeTal := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeTal = '' then Continue;
    Talent := ChercheTalent(CodeTal);
    if Talent.CodeTalent <> '' then
      LibTal := Talent.Libelle
    else
      LibTal := LibelleChoixNiveau(CodeTal, 'T');  // choix A/B ou talent inconnu
    NodeFeuille := TreeViewLivre.Items.AddChild(NodeBranche, LibTal);
    SetNodeInfo(NodeFeuille, NT_TALENT_NIVEAU, CodeTal);  // 23 = talent du niveau
  end;
end;

// Sous-branche "Talent" d'un niveau de métier
procedure TWinLivres.LoadMetierNiveauTalents(CareerElement: TDOMElement; Niveau: Integer; CodeNiveau: String; NodeBase: TTreeNode);
var
  Chapitre: TDOMNode;
  NodeBranche: TTreeNode;
begin
  Chapitre := CareerElement.FindNode('SUBCHAPTER_TALENT');
  if Chapitre = nil then Exit;
  NodeBranche := TreeViewLivre.Items.AddChild(NodeBase, ConstArbreTalent);
  SetNodeInfo(NodeBranche, NT_BRANCHE_TALENT_NIVEAU, CodeNiveau);  // 22 = branche talents du niveau
  RemplirBrancheNiveauTalents(NodeBranche, Chapitre, Niveau);
end;

// Résout un nom d'équipement du XML en libellé affichable.
// TypeEquip renvoie 'W' pour une arme, 'P' pour une armure, 'D' pour du
// texte libre ("writing set"). Partagé par l'arbre et la grille.
function TWinLivres.LibelleEquipement(NomItem: String; out TypeEquip: Char): String;
var
  CodeItem, Qualite: String;
  Arme: StructureArme;
  Armure: StructureArmure;
  Trapping: StructureTrapping;
begin
  Result    := '';
  TypeEquip := 'D';
  
  CodeItem := Trim(NomItem);
  if CodeItem = '' then Exit;
  
  // Suffixe de qualité "(Q)"
  if Pos(EquipementQualite, CodeItem) > 0 then
  begin
    CodeItem := Trim(Copy(CodeItem, 1, Length(CodeItem) - Length(EquipementQualite)));
    Qualite  := GetTexteLibelle('RULES-LAB_038');  // ' de qualité'
  end
  else
    Qualite := '';
  
  if (Pos(EquipementCC, CodeItem) > 0) or
     (Pos(EquipementCT, CodeItem) > 0) or
     (Pos(EquipementMU, CodeItem) > 0) then
  begin
    // Arme (corps à corps, projectile ou munition)
    TypeEquip := 'W';
    Arme := ChercheArme(CodeItem);
    if Arme.CodeArme <> '' then
      Result := Arme.Libelle + Qualite
    else
      Result := CodeItem + Qualite;  // fallback
  end
  else if Pos(EquipementAR, CodeItem) > 0 then
  begin
    // Armure
    TypeEquip := 'P';
    Armure := ChercheArmure(CodeItem);
    if Armure.CodeArmure <> '' then
      Result := Armure.Libelle + Qualite
    else
      Result := CodeItem + Qualite;  // fallback
  end
  else if Pos(EquipementTR, CodeItem) > 0 then
  begin
    // Trapping (équipement divers du catalogue DATA_TRAPPING)
    TypeEquip := 'T';
    Trapping := ChercheTrapping(CodeItem);
    if Trapping.CodeTrapping <> '' then
      Result := Trapping.Libelle + Qualite
    else if (Pos(' (', CodeItem) > 0) and (ChercheTrapping(Copy(CodeItem, 1, Pos(' (', CodeItem) - 1)).CodeTrapping <> '') then
      // « RULES-TRAP_TRADE_TOOLS (Thief) » : le code suivi de sa precision, le libelle du code puis la precision
      Result := ChercheTrapping(Copy(CodeItem, 1, Pos(' (', CodeItem) - 1)).Libelle +
        Copy(CodeItem, Pos(' (', CodeItem), MaxInt) + Qualite
    else
      Result := CodeItem + Qualite;  // fallback
  end
  else
    // Texte libre : "writing set", "impressive hat", "patron"...
    Result := NomItem;
end;

// Ajoute une feuille d'équipement sous NodeBase.
procedure TWinLivres.AjouterFeuilleEquipement(NomItem: String; NodeBase: TTreeNode; Quantite: Integer = 1);
var
  NodeFeuille: TTreeNode;
  Libelle: String;
  TypeEquip: Char;
begin
  if Trim(NomItem) = '' then Exit;

  Libelle := LibelleEquipement(NomItem, TypeEquip) + QuantiteSuffixe(Quantite);

  case TypeEquip of
    'W': Libelle := EquipArme + Libelle;
    'P': Libelle := EquipArmure + Libelle;
    // Trapping ('T') et texte libre ('D', LibelleEquipement l.1164) traites pareil que dans
    // l'autre case TypeEquip de cette unite (ligne ~2757) et que WinMetier (EquipDivers) -
    // corrige le 15/09/2026, ce else manquait (audit "listes fermees").
    else Libelle := EquipDivers + Libelle;
  end;

  NodeFeuille := TreeViewLivre.Items.AddChild(NodeBase, Libelle);
  SetNodeInfo(NodeFeuille, NT_EQUIPEMENT_NIVEAU, Trim(NomItem));
end;

// Sous-branche "Equipement" d'un niveau de métier.
// Le XML mélange du texte libre ("writing set") et des codes
// ("RULES-ARMO_04"), le type se déduit du préfixe du code.
procedure TWinLivres.LoadMetierNiveauEquipement(CareerElement: TDOMElement; Niveau: Integer; CodeNiveau: String; NodeBase: TTreeNode);
var
  Chapitre: TDOMNode;
  NodeBranche: TTreeNode;
begin
  Chapitre := CareerElement.FindNode('SUBCHAPTER_ITEM');
  if Chapitre = nil then Exit;

  NodeBranche := TreeViewLivre.Items.AddChild(NodeBase, ConstArbreEquipement);
  SetNodeInfo(NodeBranche, NT_BRANCHE_EQUIPEMENT_NIVEAU, CodeNiveau);  // 24 = branche équipement du niveau
  RemplirBrancheNiveauEquipement(NodeBranche, Chapitre, Niveau);
end;

// Feuilles d'une branche "Equipement" : les <Item> du chapitre dont la valeur est ce niveau.
procedure TWinLivres.RemplirBrancheNiveauEquipement(NodeBranche: TTreeNode; Chapitre: TDOMNode; Niveau: Integer);
var
  Elements: TDOMNodeList;
  I, J: Integer;
  NodeChoix: TTreeNode;
  NomItem: String;
  Choix: TStringList;
begin
  Elements:= TDOMElement(Chapitre).GetElementsByTagName('Item');
  
  for I := 0 to Elements.Count - 1 do
  begin
    if ValeurXML(Elements.Item[I]) <> IntToStr(Niveau) then Continue;
    
    NomItem := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if NomItem = '' then Continue;
    
    if Pos(SeparateurMulti, NomItem) > 0 then
    begin
      // Choix multiple : "A/B" -> sous-branche "au choix"
      NodeChoix := TreeViewLivre.Items.AddChild(NodeBranche, ConstArbreAuChoix);
      SetNodeInfo(NodeChoix, NT_EQUIPEMENT_NIVEAU);  // 25 : nœud passif, pas la branche Equipement

      Choix := TStringList.Create;
      try
        Choix.Delimiter       := SeparateurMulti;
        Choix.StrictDelimiter := True;
        Choix.DelimitedText   := NomItem;

        // quantite="2/1/1" : une quantite par branche (CONTEXT.md, equipement a choix)
        for J := 0 to Choix.Count - 1 do
          AjouterFeuilleEquipement(Choix[J], NodeChoix,
            QuantiteDeBranche(TDOMElement(Elements.Item[I]).GetAttribute('quantite'), J));
      finally
        Choix.Free;
      end;
    end
    else if Pos(SeparateurEnsemble, NomItem) > 0 then
    begin
      // Ensemble : "A+B" -> sous-branche "ensemble" - les deux objets sont acquis en
      // meme temps (ex. Storm Lantern+Lamp Oil), pas un choix, a ne pas confondre avec
      // SeparateurMulti ci-dessus (CONTEXT.md, chantier equipement/avancement).
      NodeChoix := TreeViewLivre.Items.AddChild(NodeBranche, ConstArbreEnsemble);
      SetNodeInfo(NodeChoix, NT_EQUIPEMENT_NIVEAU);

      Choix := TStringList.Create;
      try
        Choix.Delimiter       := SeparateurEnsemble;
        Choix.StrictDelimiter := True;
        Choix.DelimitedText   := NomItem;

        for J := 0 to Choix.Count - 1 do
          AjouterFeuilleEquipement(Choix[J], NodeChoix);
      finally
        Choix.Free;
      end;
    end
    else
      AjouterFeuilleEquipement(NomItem, NodeBranche,
        StrToIntDef(TDOMElement(Elements.Item[I]).GetAttribute('quantite'), 1));
  end;
end;

// Sous-branches "niveau" d'un métier : 1.Pamphleteer - Bronze 1, etc.
procedure TWinLivres.LoadMetierNiveaux(CareerElement: TDOMElement; CareerCode: String; MetierNode: TTreeNode);
var
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  I, Niveau, P: Integer;
  LevelElement: TDOMElement;
  NodeNiveau: TTreeNode;
  LibNiveau, Salaire, TexteNiveau, SkillPrincipal: String;
begin
  Chapitre := CareerElement.FindNode('SUBCHAPTER_LEVEL');
  if Chapitre = nil then Exit;
  
  // Compétence principale du métier : le <Skill> direct du <Career>
  SkillPrincipal := ValeurXML(CareerElement.FindNode('Skill'));
  
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Level');
  
  for I := 0 to Elements.Count - 1 do
  begin
    LevelElement := TDOMElement(Elements.Item[I]);
    
    Niveau := StrToIntDef(LevelElement.GetAttribute('id'), 0);
    if Niveau = 0 then Continue;
    
    LibNiveau := ValeurXML(LevelElement.FindNode('Description'));
    Salaire   := ValeurXML(LevelElement.FindNode('Salary'));
    
    // "1.Pamphleteer - Bronze 1"
    TexteNiveau := IntToStr(Niveau) + '.' + LibNiveau;
    if Salaire <> '' then
    begin
      // Palier (TIERS_SILVER) en libelle, montant apres l espace
      P := Pos(' ', Salaire);
      if P > 0 then
        TexteNiveau := TexteNiveau + ' - ' + GetTexteLibelle('RULES-' + Copy(Salaire, 1, P - 1)) +
          Copy(Salaire, P, Length(Salaire))
      else
        TexteNiveau := TexteNiveau + ' - ' + GetTexteLibelle('RULES-' + Salaire);
    end;
    
    NodeNiveau := TreeViewLivre.Items.AddChild(MetierNode, TexteNiveau);
    // Code = "CODEMETIER|niveau" pour retrouver l'élément XML plus tard
    SetNodeInfo(NodeNiveau, NT_NIVEAU_METIER, CareerCode + '|' + IntToStr(Niveau));  // 17 = niveau
    
    LoadMetierNiveauAttributs(CareerElement, Niveau, CareerCode + '|' + IntToStr(Niveau), NodeNiveau);
    LoadMetierNiveauCompetences(CareerElement, Niveau, SkillPrincipal, CareerCode + '|' + IntToStr(Niveau), NodeNiveau);
    LoadMetierNiveauTalents(CareerElement, Niveau, CareerCode + '|' + IntToStr(Niveau), NodeNiveau);
    LoadMetierNiveauEquipement(CareerElement, Niveau, CareerCode + '|' + IntToStr(Niveau), NodeNiveau);
  end;
end;

// Construit la table métier -> races qui le proposent, en un seul balayage
// des <Specie>. Évite de rebalayer toutes les races pour chaque métier.
procedure TWinLivres.ConstruireMetierRacesMap();
var
  SpecieElements, CareerElements: TDOMNodeList;
  I, J: Integer;
  SpecieElement: TDOMElement;
  Chapitre: TDOMNode;
  CodeRace, CodeMetier, Actuel: String;
begin
  if MetierRacesMap = nil then
    MetierRacesMap := TStringList.Create;
  
  MetierRacesMap.Clear;
  
  if XMLDoc = nil then Exit;
  
  SpecieElements := XMLDoc.GetElementsByTagName('Specie');
  
  for I := 0 to SpecieElements.Count - 1 do
  begin
    SpecieElement := TDOMElement(SpecieElements.Item[I]);
    CodeRace := SpecieElement.GetAttribute('id');
    if CodeRace = '' then Continue;
    
    Chapitre := SpecieElement.FindNode('SUBCHAPTER_CAREER');
    if Chapitre = nil then Continue;
    
    CareerElements := TDOMElement(Chapitre).GetElementsByTagName('Career');
    
    for J := 0 to CareerElements.Count - 1 do
    begin
      CodeMetier := TDOMElement(CareerElements.Item[J]).GetAttribute('name');
      if CodeMetier = '' then Continue;
      // "-" = carriere indisponible pour cette race : pas une race possible
      if Trim(StringReplace(TDOMElement(CareerElements.Item[J]).TextContent, '"', '', [rfReplaceAll])) = SeparateurChance then Continue;

      Actuel := MetierRacesMap.Values[CodeMetier];
      if Actuel = '' then
        MetierRacesMap.Values[CodeMetier] := CodeRace
      else
        MetierRacesMap.Values[CodeMetier] := Actuel + '|' + CodeRace;
    end;
  end;
end;

// Construit une branche plate depuis un chapitre du XML.
// Sert pour DATA_SKILL, DATA_SKILL_SPECIALIZATION, DATA_TALENT et
// DATA_TALENT_SPECIALIZATION : même structure, seul le nombre de champs
// par entrée diffère, ce dont s'occupe l'affichage.
// Regrouper = True insère un niveau intermédiaire par élément mère, déduit
// du code de la spécialisation ("RULES-COMPART_CALLI" -> "RULES-COMPART_*").
procedure TWinLivres.ChargerBrancheSimple(ChapitreTag, ElementTag, TitreBranche: String; TypeNoeud: Integer; NodeParent: TTreeNode; Regrouper: Boolean = False; Trier: Boolean = True);
var
  Chapitres, Elements, SortsRulebook: TDOMNodeList;
  I, Idx, Src, JSort: Integer;
  Etrangers: Boolean;
  PrefEtranger: String;
  XMLElement, MereElement, Autre: TDOMElement;
  NodeBranche, NodeFeuille, NodeMere, NodeCible: TTreeNode;
  Code, Libelle, CodeMere, LibelleMere: String;
  Meres: TStringList;
begin
  if XMLDoc = nil then Exit;
  
  Chapitres := XMLDoc.GetElementsByTagName(ChapitreTag);
  // chaque livre montre aussi les specialisations de talent du Rulebook (en lecture seule, hors benedictions)
  Etrangers := (ChapitreTag = 'DATA_TALENT_SPECIALIZATION') and AutreLivreRulebook;
  PrefEtranger := '';
  if Etrangers then
    PrefEtranger := ValeurXML(RulebookXML.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('CODE_BOOK'));
  // Livre de travail : la branche existe meme vide, pour pouvoir la remplir ensuite
  if (Chapitres.Count = 0) and not CreationPermise and not Etrangers then Exit;
  // chapitre reserve au Rulebook (caracteristiques...) : pas de branche vide dans les autres livres
  if (Chapitres.Count = 0) and ChapitreReserveRulebook(ChapitreTag) then Exit;
  // livre V1 : pas de branche vide pour un chapitre que son schema n'admet pas
  if (Chapitres.Count = 0) and EstLivreV1 and not ChapitreV1Permis(ChapitreTag) then Exit;
  // toute version : pas de branche vide pour un chapitre qui n'existe pas dans cette edition (V1 : voir ci-dessus)
  if (Chapitres.Count = 0) and not Etrangers and not ChapitrePermisVersion(ChapitreTag) then Exit;

  NodeBranche := TreeViewLivre.Items.AddChild(NodeParent, TitreBranche);
  SetNodeInfo(NodeBranche, NT_CHAPITRE);  // 0 = chapitre
  TNodeInfo(NodeBranche.Data).Chapitre := ChapitreTag;
  if (Chapitres.Count = 0) and not Etrangers then Exit;

  // On reste dans le chapitre : les éléments de même nom nichés dans les
  // SUBCHAPTER_* des races et des métiers sont ailleurs dans le document.
  Elements := nil;
  
  // Table code mère -> noeud, pour ne créer chaque mère qu'une fois
  // sans supposer que le XML soit trié.
  Meres := TStringList.Create;
  try
    Meres.Sorted := True;
    
    for Src := 0 to 1 do
    begin
    // Src 0 : les elements du livre ; Src 1 : ceux du Rulebook que le livre ne porte pas (specialisations de talent)
    if Src = 0 then
    begin
      if Chapitres.Count = 0 then Continue;
      Elements := TDOMElement(Chapitres.Item[0]).GetElementsByTagName(ElementTag);
    end
    else
    begin
      if not Etrangers then Break;
      if RulebookXML.GetElementsByTagName(ChapitreTag).Item[0] = nil then Break;
      Elements := TDOMElement(RulebookXML.GetElementsByTagName(ChapitreTag).Item[0]).GetElementsByTagName(ElementTag);
    end;
    for I := 0 to Elements.Count - 1 do
    begin
      XMLElement := TDOMElement(Elements.Item[I]);
      
      Code := XMLElement.GetAttribute('id');
      if Code = '' then Code := XMLElement.GetAttribute('name');  // corruptions : clé dans 'name'
      if Code = '' then Continue;
      if (Src = 1) and (TrouverElementParId(ElementTag, Code) <> nil) then Continue;

      Libelle := ValeurXML(XMLElement.FindNode('Description'));
      if (Libelle = '') and (ElementTag = 'Familiar') then Libelle := ValeurXML(XMLElement.FindNode('Animal'));
      if Libelle = '' then
      begin
        // Libellé d'interface (ex. RULES-CLASS_ACAD), sinon description de la
        // même entrée définie ailleurs (un <Sort> de DATA_SPELL_TALENT renvoie
        // au <Sort> de DATA_SPELL), sinon le code : visible = libellé manquant.
        if ElementTag = 'Condition' then Libelle := GetAttributLabel(Code) else Libelle := GetTexteLibelle(Code);
        if Libelle = Code then
        begin
          Autre := TrouverElementParId(ElementTag, Code);
          if (Autre <> nil) and (Autre <> XMLElement) then
            Libelle := ValeurXML(Autre.FindNode('Description'));
          // un <Sort> de DATA_SPELL_TALENT : le nom est dans le sort lui-meme (SpellV2, SpellV1 ou Spell)
          if ((Libelle = '') or (Libelle = Code)) and (ElementTag = 'Sort') then
          begin
            Autre := TrouverElementParId('SpellV2', Code);
            if Autre = nil then Autre := TrouverElementParId('SpellV1', Code);
            if Autre = nil then Autre := TrouverElementParId('Spell', Code);
            if Autre <> nil then Libelle := ValeurXML(Autre.FindNode('Description'));
            // une benediction ajoutee par un autre livre (ligne de talents seule) : son nom est dans le Rulebook
            if ((Libelle = '') or (Libelle = Code)) and (RulebookXML <> nil) then
            begin
              Libelle := '';
              SortsRulebook := RulebookXML.GetElementsByTagName('Sort');
              for JSort := 0 to SortsRulebook.Count - 1 do
              begin
                Autre := TDOMElement(SortsRulebook.Item[JSort]);
                if (Autre.GetAttribute('id') = Code) and (Autre.FindNode('Description') <> nil) then
                begin
                  Libelle := ValeurXML(Autre.FindNode('Description'));
                  Break;
                end;
              end;
            end;
          end;
          if Libelle = '' then
            Libelle := Code;
        end;
      end;

      if Src = 1 then Libelle := Libelle + ' [' + PrefEtranger + ']';
      NodeCible := NodeBranche;

      if Regrouper then
      begin
        CodeMere := '';
        if ElementTag = 'Talent' then
        begin
          // Un nom de talent contient lui-meme des '_' : la specialisation est reconnue a son '__'
          // (RULES-T_BLESS__SIGMAR). La famille est le <Generique> de la fiche, a defaut ce qui precede le '__'.
          if XMLElement.FindNode('Generique') <> nil then
            CodeMere := ValeurXML(XMLElement.FindNode('Generique'));
          if (CodeMere = '') and (Pos(ValeurGenerique, Code) = 0) and (Pos(SeparateurSpecialisationTalent, Code) > 0) then
            CodeMere := Copy(Code, 1, Pos(SeparateurSpecialisationTalent, Code) - 1) + ValeurGeneriqueTalent;
        end
        else
        begin
          // Competences V4 / V5 : meme regle que les talents, la famille est le <Generique> de la fiche,
          // a defaut ce qui precede le '__' (RULES-COMP_LORE__BEASTS -> RULES-COMP_LORE__*).
          if XMLElement.FindNode('Generique') <> nil then
            CodeMere := ValeurXML(XMLElement.FindNode('Generique'));
          if (CodeMere = '') and (Pos(ValeurGenerique, Code) = 0) and (Pos(SeparateurSpecialisationTalent, Code) > 0) then
            CodeMere := CodeGeneriqueDeduit(Code);
        end;
        if CodeMere <> '' then
        begin

          Idx := Meres.IndexOf(CodeMere);
          if Idx >= 0 then
            NodeCible := TTreeNode(Meres.Objects[Idx])
          else
          begin
            // Libellé de la mère depuis son propre chapitre
            LibelleMere := '';
            MereElement := TrouverElementParId(ElementTag, CodeMere);
            if MereElement <> nil then
              LibelleMere := ValeurXML(MereElement.FindNode('Description'));
            // la mere peut vivre dans un autre livre (les dieux de Nations : RULES-T0012_*, mere "Bless (Any)" du Rulebook)
            if (LibelleMere = '') and (RulebookXML <> nil) then
            begin
              Autre := nil;
              for Idx := 0 to RulebookXML.GetElementsByTagName(ElementTag).Count - 1 do
                if TDOMElement(RulebookXML.GetElementsByTagName(ElementTag).Item[Idx]).GetAttribute('id') = CodeMere then
                begin
                  Autre := TDOMElement(RulebookXML.GetElementsByTagName(ElementTag).Item[Idx]);
                  Break;
                end;
              if Autre <> nil then LibelleMere := ValeurXML(Autre.FindNode('Description'));
            end;
            // sinon la competence generique de la base (ou du jeu de libelles), comme pour une feuille
            if LibelleMere = '' then
              LibelleMere := LibelleDeCode(CodeMere);
            if LibelleMere = '' then
              LibelleMere := LibelleCodeV1(CodeMere);
            // RULES-COMP_ARCANE_LANGUAGE__* : la competence RULES-COMP_ARCANE_LANGUAGE, suivie de "(Any)" comme le Rulebook
            if (LibelleMere = '') and (Copy(CodeMere, Length(CodeMere) - 2, 3) = '__*') then
            begin
              LibelleMere := LibelleCodeV1(Copy(CodeMere, 1, Length(CodeMere) - 3));
              if LibelleMere <> '' then LibelleMere := LibelleMere + ' (Any)';
            end;
            // talent generique V2 sans talent mere defini (RULES-T_FLIER__*) : nom du premier talent du groupe,
            // sans sa parenthese, suivi de « (Any) »
            if (LibelleMere = '') and (Copy(CodeMere, Length(CodeMere) - 2, 3) = '__*') and (Libelle <> '') then
            begin
              LibelleMere := Libelle;
              if Pos(' (', LibelleMere) > 0 then LibelleMere := Copy(LibelleMere, 1, Pos(' (', LibelleMere) - 1);
              LibelleMere := LibelleMere + ' (Any)';
            end;
            // V2 : parent defini sans le « _* » final (Rulebook : RULES-COMP_SPEAK_ARCANE_LANGUAGE),
            // alors que ses specialisations pointent vers RULES-COMP_SPEAK_ARCANE_LANGUAGE_*
            if (LibelleMere = '') and (Copy(CodeMere, Length(CodeMere) - 1, 2) = '_*') then
            begin
              Autre := TrouverElementParId(ElementTag, Copy(CodeMere, 1, Length(CodeMere) - 2));
              if Autre <> nil then LibelleMere := ValeurXML(Autre.FindNode('Description'));
              if (LibelleMere = '') and (RulebookXML <> nil) then
                for Idx := 0 to RulebookXML.GetElementsByTagName(ElementTag).Count - 1 do
                  if TDOMElement(RulebookXML.GetElementsByTagName(ElementTag).Item[Idx]).GetAttribute('id') = Copy(CodeMere, 1, Length(CodeMere) - 2) then
                  begin
                    LibelleMere := ValeurXML(TDOMElement(RulebookXML.GetElementsByTagName(ElementTag).Item[Idx]).FindNode('Description'));
                    Break;
                  end;
              if LibelleMere <> '' then LibelleMere := LibelleMere + ' (Various)';
            end;
            if LibelleMere = '' then
              LibelleMere := CodeMere;  // fallback

            NodeMere := TreeViewLivre.Items.AddChild(NodeBranche, LibelleMere);
            SetNodeInfo(NodeMere, NT_CHAPITRE, CodeMere);  // 0 = regroupement passif
            
            Meres.AddObject(CodeMere, NodeMere);
            NodeCible := NodeMere;
          end;
        end;
      end;
      
      NodeFeuille := TreeViewLivre.Items.AddChild(NodeCible, Libelle);
      SetNodeInfo(NodeFeuille, TypeNoeud, Code);
    end;
    end;

    // Ordre alphabetique des libelles (sauf tables dont l'ordre du livre compte :
    // tranches de d100) ; les meres de regroupement sont triees avec leurs feuilles.
    if Trier then
    begin
      for I := 0 to Meres.Count - 1 do
        TTreeNode(Meres.Objects[I]).AlphaSort;
      NodeBranche.AlphaSort;
    end;
  finally
    Meres.Free;
  end;
end;

// Dossier des versions de travail d'un livre (sans separateur final). WFRP4 garde l'ancien
// emplacement TRAVAIL\<nom du livre> ; les autres versions (dossier parent du fichier,
// DATABASE\WFRP2, WFRP5...) ont leur sous-dossier TRAVAIL\<version>\<nom du livre>, pour
// qu'un livre de meme nom dans deux versions ne partage pas ses copies.
function TWinLivres.DossierTravailLivre(AFilePath: String): String;
var
  Version: String;
begin
  Result := ExtractFilePath(Application.ExeName) + 'TRAVAIL' + PathDelim;
  Version := ExtractFileName(ExcludeTrailingPathDelimiter(ExtractFilePath(AFilePath)));
  if (Version <> '') and (UpperCase(Version) <> 'WFRP4') and (UpperCase(Version) <> 'DATABASE') then
    Result := Result + Version + PathDelim;
  Result := Result + ChangeFileExt(ExtractFileName(AFilePath), '');
end;

// Si le livre charge est inacheve (<COMPLETE> = 0 dans DATA_BOOK), renvoie la version de
// travail la plus recente de TRAVAIL\<nom du livre>\ (le tri alphabetique des noms
// AAAAMMJJ-HHMMSS est le tri chronologique). Sinon, ou s'il n'y en a aucune : ''.
// Un livre sans balise COMPLETE est complet (cas des livres existants).
function TWinLivres.DerniereVersionTravail(AFilePath: String): String;
var
  Livre, Noeud: TDOMNode;
  Dossier: String;
  SR: TSearchRec;
  Meilleur: String;
begin
  Result := '';
  if XMLDoc = nil then Exit;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  if Livre = nil then Exit;
  Noeud := Livre.FindNode(ConstXmlCompletLivre);
  if (Noeud = nil) or (Trim(StringReplace(UTF8Encode(Noeud.TextContent), '"', '', [rfReplaceAll])) <> '0') then Exit;
  Dossier := DossierTravailLivre(AFilePath) + PathDelim;
  Meilleur := '';
  if FindFirst(Dossier + '*.xml', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory = 0) and (SR.Name > Meilleur) then Meilleur := SR.Name;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  if Meilleur <> '' then Result := Dossier + Meilleur;
end;

procedure TWinLivres.ChargerXMLFile(AFilePath: String);
var
  NodeRoot: TTreeNode;
  NodeRaces: TTreeNode;
  NodeCareers: TTreeNode;
  NodeEquip: TTreeNode;
  FileName: String;
  Travail: String;

  procedure BrancheInfosLivre;
  var
    NodeInfos: TTreeNode;
  begin
    NodeInfos := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_128'));
    SetNodeInfo(NodeInfos, NT_INFO_LIVRE, '', 'BOOK_INFO');
  end;

  procedure BrancheRaces;
  var
    SpecieElements: TDOMNodeList;
    I: Integer;
  begin
    NodeRaces := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_042'));
    SetNodeInfo(NodeRaces, NT_CHAPITRE, '', 'DATA_SPECIE');
    
    SpecieElements := XMLDoc.GetElementsByTagName('Specie');
    
    if SpecieElements.Count > 0 then
      begin
        for I := 0 to SpecieElements.Count - 1 do
          begin
            AjouterNoeudEthnie(NodeRaces, TDOMElement(SpecieElements.Item[I]));
          end;
      end;
  end;

  procedure BrancheRacesGroupes;
  var
    NodeRacesGroupes: TTreeNode;
    ElementsRaces: TDOMNodeList;
    I: Integer;
  begin
    NodeRacesGroupes := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_397'));
    SetNodeInfo(NodeRacesGroupes, NT_CHAPITRE, '', 'DATA_RACE');
    ElementsRaces := XMLDoc.GetElementsByTagName('DATA_RACE');
    if ElementsRaces.Count > 0 then
      for I := 0 to ElementsRaces.Item[0].ChildNodes.Count - 1 do
        if (ElementsRaces.Item[0].ChildNodes[I].NodeName = 'Race') and
           (TDOMElement(ElementsRaces.Item[0].ChildNodes[I]).GetAttribute('id') <> '') then
          AjouterNoeudRaceGroupe(NodeRacesGroupes, TDOMElement(ElementsRaces.Item[0].ChildNodes[I]));
    NodeRacesGroupes.AlphaSort;
  end;

  procedure BrancheCarrieres;
  var
    XMLElement: TDOMElement;
    CareerElements: TDOMNodeList;
    I: Integer;
    Code: String;
  begin
    ConstruireMetierRacesMap();
    
    NodeCareers := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_006'));
    SetNodeInfo(NodeCareers, NT_CHAPITRE, '', 'DATA_CAREER');
    
    CareerElements := XMLDoc.GetElementsByTagName('Career');
    
    if CareerElements.Count > 0 then
      begin
        for I := 0 to CareerElements.Count - 1 do
          begin
            XMLElement := TDOMElement(CareerElements.Item[I]);
            
            // GetElementsByTagName ramène AUSSI les <Career name="..."> des
            // SUBCHAPTER_CAREER des races. On ne garde que les métiers racine.
            if (XMLElement.ParentNode <> nil) and
               (XMLElement.ParentNode.NodeName = 'SUBCHAPTER_CAREER') then
              Continue;
            
            Code := XMLElement.GetAttribute('id');
            
            // Ignorer les éléments sans Code valide
            if Code = '' then
              Continue;
            
            AjouterNoeudCarriere(NodeCareers, XMLElement);
          end;
      end;
  end;

  procedure BrancheCompetencesTalents;
  begin
    ChargerBrancheSimple('DATA_SKILL', 'Skill', GetTexteLibelle('RULES-LAB_009'), 26, NodeRoot);
    ChargerBrancheSimple('DATA_SKILL_SPECIALIZATION', 'Skill', GetTexteLibelle('RULES-LAB_146'), 27, NodeRoot, True);
    
    // ========== TALENTS ==========
    ChargerBrancheSimple('DATA_TALENT', 'Talent', GetTexteLibelle('RULES-LAB_007'), 28, NodeRoot);
    ChargerBrancheSimple('DATA_TALENT_SPECIALIZATION', 'Talent', GetTexteLibelle('RULES-LAB_147'), 29, NodeRoot, True);

    // ========== WFRP2 : competences et talents en texte (balises propres, SCHEMA_WFRP2.xsd) ==========
    ChargerBrancheSimple('DATA_SKILL_V2', 'SkillV2', GetTexteLibelle('RULES-LAB_009'), NT_COMPETENCE_V2, NodeRoot);
    ChargerBrancheSimple('DATA_TALENT_V2', 'TalentV2', GetTexteLibelle('RULES-LAB_007'), NT_TALENT_V2, NodeRoot);
    ChargerBrancheGroupeeV2('DATA_SPELL_V2', 'SpellV2', 'Lore', 'RULES-LAB_083', NT_SORT_V2, NodeRoot);

    // ========== WFRP1 : sorts (SCHEMA_WFRP1.xsd), groupes par liste de sorts ==========
    ChargerBrancheGroupeeV2('DATA_SPELL_V1', 'SpellV1', 'SpellList', 'RULES-LAB_083', NT_SORT_V1, NodeRoot);
    ChargerBrancheSimple('DATA_SKILL_V1', 'Skill', GetTexteLibelle('RULES-LAB_009'), NT_COMPETENCE_V1, NodeRoot);

    // ========== WFRP1 : divinites, cultes et familiers ==========
    ChargerBrancheSimple('DATA_DEITY_V1', 'Deity', GetTexteLibelle('RULES-LAB_869'), NT_DIEU_V1, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_CULT_V1', 'Cult', GetTexteLibelle('RULES-LAB_870'), NT_CULTE_V1, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_FAMILIAR_V1', 'Familiar', GetTexteLibelle('RULES-LAB_871'), NT_FAMILIER_V1, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_DISABILITY_V1', 'Disability', GetTexteLibelle('RULES-LAB_842'), NT_HANDICAP_V1, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_ATTRIBUT', 'Attribut', GetTexteLibelle('RULES-LAB_924'), NT_ATTRIBUT_V1, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_CLASS_V1', 'Class', GetTexteLibelle('RULES-LAB_880'), NT_CLASSE_V1, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_TRADE_V1', 'Trade', GetTexteLibelle('RULES-LAB_812'), NT_METIER_V1, NodeRoot, False, False);

    // ========== WFRP1 : tables de lignes sans id (une ligne = un nœud) ==========
    ChargerBrancheLignesV1(ConstXmlDataSkillRollV1, GetTexteLibelle('RULES-LAB_885'), NodeRoot);
    ChargerBrancheLignesV1(ConstXmlDataRegleMetier, GetTexteLibelle('RULES-LAB_886'), NodeRoot);
    ChargerBrancheLignesV1(ConstXmlDataSkillCountAgeV1, GetTexteLibelle('RULES-LAB_887'), NodeRoot);
    ChargerBrancheLignesV1('DATA_SPELL_LEARNING_V1', GetTexteLibelle('RULES-LAB_888'), NodeRoot);
    ChargerBrancheLignesV1(ConstXmlDataMagicPointGainV1, GetTexteLibelle('RULES-LAB_891'), NodeRoot);
    ChargerBrancheLignesV1(ConstXmlDataPriestAdvanceV1, GetTexteLibelle('RULES-LAB_892'), NodeRoot);
    ChargerBrancheLignesV1(ConstXmlDataDisabilityRollV1, GetTexteLibelle('RULES-LAB_893'), NodeRoot);
    ChargerBrancheLignesV1('DATA_AVAILABILITY_V1', GetTexteLibelle('RULES-LAB_889'), NodeRoot);
    ChargerBrancheLignesV1('DATA_CLOTHING_QUALITY_V1', GetTexteLibelle('RULES-LAB_890'), NodeRoot);
  end;

  procedure BrancheEquipement;
  begin
    NodeEquip := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_013'));
    SetNodeInfo(NodeEquip, NT_CHAPITRE, '', 'EQUIPEMENT');
    // ordre de creation : fabrication et bonus d'abord (les armes et armures s'appuient dessus)
    ChargerBrancheSimple('DATA_CRAFTMANSHIP', 'Craftsmanship', GetTexteLibelle('RULES-LAB_125'), 39, NodeEquip);
    ChargerBrancheSimple('DATA_WEAPON_BONUS', 'BonusMalus',
                         GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_063'), 32, NodeEquip);
    ChargerBrancheSimple('DATA_ARMOR_BONUS', 'BonusMalus',
                         GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_065'), 34, NodeEquip);
    // WFRP2 : les tables d'equipement du livre sont directement sous ce noeud
    ChargerBrancheGroupeeV2('DATA_EQUIPMENT_V2', 'EquipmentV2', 'Category', '', NT_EQUIPEMENT_V2, NodeEquip, True);
    
    // WFRP1 : objets groupes par categorie
    ChargerBrancheGroupeeV2('DATA_EQUIPMENT_V1', 'EquipmentV1', 'Category', '', NT_EQUIPEMENT_V1, NodeEquip, True);

    ChargerBrancheSimple('DATA_WEAPON', 'Weapon', GetTexteLibelle('RULES-LAB_063'), 30, NodeEquip);
    ChargerBrancheSimple('DATA_ARMOR',  'Armor',  GetTexteLibelle('RULES-LAB_065'), 31, NodeEquip);
    ChargerBrancheSimple('DATA_ARMOR_SIMP', 'ArmorSimp', GetTexteLibelle('RULES-LAB_149'), 33, NodeEquip);
    ChargerBrancheSimple('DATA_TRAPPING', 'Trapping', GetTexteLibelle('RULES-LAB_196'), 38, NodeEquip);
  end;

  // libelles du livre (DATA_LABEL) : un noeud par <Text>, code LANGUE|nom, texte du noeud = le libelle lui-meme
  procedure BrancheLibellesLivre;
  var
    Bloc, Etiquette, Texte: TDOMNode;
    Lang, Nom, Lib: String;
    NodeBranche, NodeLangue: TTreeNode;
  begin
    Bloc := XMLDoc.GetElementsByTagName('DATA_LABEL').Item[0];
    if Bloc = nil then Exit;
    NodeBranche := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_975'));
    SetNodeInfo(NodeBranche, NT_CHAPITRE, '', 'DATA_LABEL');
    Etiquette := Bloc.FirstChild;
    while Etiquette <> nil do
    begin
      if Etiquette.NodeName = 'Label' then
      begin
        Lang := TDOMElement(Etiquette).GetAttribute('language');
        NodeLangue := TreeViewLivre.Items.AddChild(NodeBranche, Lang);
        SetNodeInfo(NodeLangue, NT_CHAPITRE);
        Texte := Etiquette.FirstChild;
        while Texte <> nil do
        begin
          if Texte.NodeName = 'Text' then
          begin
            Nom := TDOMElement(Texte).GetAttribute('name');
            Lib := ValeurXML(Texte);
            if Lib = '' then Lib := Nom;
            SetNodeInfo(TreeViewLivre.Items.AddChild(NodeLangue, Lib), NT_LIBELLE_LIVRE, Lang + '|' + Nom);
          end;
          Texte := Texte.NextSibling;
        end;
      end;
      Etiquette := Etiquette.NextSibling;
    end;
  end;

  procedure BrancheTablesRegles;
  begin
    ChargerBrancheSimple('DATA_NATION', 'Nation', GetTexteLibelle('RULES-LAB_332'), 40, NodeRoot);
    ChargerBrancheSimple('DATA_CONDITION', 'Condition', GetTexteLibelle('RULES-LAB_488'), 58, NodeRoot);
    ChargerBrancheSimple('DATA_OPTION_RULE', 'OptionRule', GetTexteLibelle('RULES-LAB_277'), 41, NodeRoot);
    ChargerBrancheSimple('DATA_CORRUPTION_TABLE_PHYSICAL', 'Corruption', GetTexteLibelle('RULES-LAB_156') + ' (' + GetTexteLibelle('RULES-LAB_330') + ')', 42, NodeRoot, False, False);
    ChargerBrancheSimple('DATA_CORRUPTION_TABLE_MENTAL', 'Corruption', GetTexteLibelle('RULES-LAB_156') + ' (' + GetTexteLibelle('RULES-LAB_331') + ')', 43, NodeRoot, False, False);
    // WFRP2 : mutations et corruptions divines (fiche generique) et leurs tables de tirage (lignes)
    ChargerBrancheSimple('DATA_CORRUPTION_TABLE_MUTATION', 'Corruption', GetTexteLibelle('RULES-LAB_947'), NT_CORRUPTION_V2, NodeRoot, False, False);
    ChargerBrancheLignesV1('DATA_CORRUPTION_MUTATION_CHANCE', GetTexteLibelle('RULES-LAB_949'), NodeRoot);
    ChargerBrancheSimple('DATA_CORRUPTION_TABLE_DIVINE', 'Corruption', GetTexteLibelle('RULES-LAB_948'), NT_CORRUPTION_V2, NodeRoot, False, False);
    ChargerBrancheLignesV1('DATA_CORRUPTION_DIVINE_CHANCE', GetTexteLibelle('RULES-LAB_950'), NodeRoot);
    // WFRP2 (Liber Fanatica) : tables du BACKGROUND, lignes sans id
    ChargerBrancheLignesV1('DATA_RULE_BACKGROUND', GetTexteLibelle('RULES-LAB_953'), NodeRoot);
    ChargerBrancheLignesV1('DATA_RULE_BACKGROUND_COUNT', GetTexteLibelle('RULES-LAB_954'), NodeRoot);
    ChargerBrancheLignesV1('DATA_RULE_SKILL_ROLL', GetTexteLibelle('RULES-LAB_952'), NodeRoot);
    ChargerBrancheLignesV1('DATA_RULE_TALENT_ROLL', GetTexteLibelle('RULES-LAB_951'), NodeRoot);
    ChargerBrancheLignesV1(ConstXmlDataTablePersonnelle, GetTexteLibelle('RULES-LAB_955'), NodeRoot);
    ChargerBrancheSimple('DATA_DISEASE', 'Disease', GetTexteLibelle('RULES-LAB_281'), 44, NodeRoot);
    ChargerBrancheSimple('DATA_AFFLICTION', 'Affliction', GetTexteLibelle('RULES-LAB_296'), 45, NodeRoot);
    ChargerBrancheSimple('DATA_STARSIGN', 'StarSign', GetTexteLibelle('RULES-LAB_318'), 60, NodeRoot);
    ChargerBrancheSimple('DATA_CAREER_BONUS', 'CareerBonus', GetTexteLibelle('RULES-LAB_320'), 62, NodeRoot);
    ChargerBrancheSimple('DATA_CAREER_ADAPTATION', 'Adaptation', GetTexteLibelle('RULES-LAB_321'), 63, NodeRoot);
  end;

  procedure BranchePetitesTables;
  var
    NodeTirage: TTreeNode;
    I: Integer;
  begin
    for I := 0 to High(PetitesTablesChapitre) do
      // DATA_RULE se cree et se modifie dans la matrice du tirage des metiers (DATA_CAREER_ROLL), pas ici
      // DATA_STARSIGN a sa fiche (type 60), DATA_CAREER_BONUS aussi (type 62), DATA_CAREER_ADAPTATION aussi (type 63)
      if (PetitesTablesChapitre[I] <> 'DATA_RULE') and (PetitesTablesChapitre[I] <> 'DATA_CLASS_ITEM') and
         (PetitesTablesChapitre[I] <> 'DATA_STARSIGN') and (PetitesTablesChapitre[I] <> 'DATA_SPECIE_TRAIT') and
         (PetitesTablesChapitre[I] <> 'DATA_CAREER_BONUS') and (PetitesTablesChapitre[I] <> 'DATA_CAREER_ADAPTATION') and
         (PetitesTablesChapitre[I] <> 'DATA_SPELL_TALENT') then  // s'edite depuis la fiche du sort ou celle du dieu
        ChargerBrancheSimple(PetitesTablesChapitre[I], PetitesTablesTag[I], LibelleChapitre(PetitesTablesChapitre[I]), NT_PETITE_TABLE_DEBUT + I, NodeRoot);
    // livre WFRP1 : ses regles (DATA_RULE) sont des fiches propres, la matrice du tirage des metiers ne les montre pas
    // (WFRP2 aussi depuis la 64e partie : Liber Fanatica a des regles de background avec Description et Page)
    if SameText(ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode(ConstXmlVersionLivre)), 'WFRP1') or
       SameText(ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode(ConstXmlVersionLivre)), 'WFRP2') or
       (XMLDoc.GetElementsByTagName('DATA_RULE').Count > 0) then  // V4 : Page et Description d'une regle ne sont pas dans la matrice
      ChargerBrancheSimple('DATA_RULE', 'Rule', LibelleChapitre('DATA_RULE'), NT_PETITE_TABLE_DEBUT + 1, NodeRoot);
    // DATA_SPECIE_TRAIT : un seul noeud, qui ouvre la grille de tous les traits d'ethnie (type 61)
    if (XMLDoc.GetElementsByTagName('DATA_SPECIE_TRAIT').Count > 0) or (CreationPermise and not EstLivreV1 and ChapitrePermisVersion('DATA_SPECIE_TRAIT')) then
    begin
      NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot, LibelleChapitre('DATA_SPECIE_TRAIT'));
      SetNodeInfo(NodeTirage, NT_TRAIT_ETHNIE, '', 'DATA_SPECIE_TRAIT');
    end;
    // DATA_CAREER_SPECIE : un seul noeud, qui ouvre la table des liens carriere <-> espece (type 64)
    if (XMLDoc.GetElementsByTagName('DATA_CAREER_SPECIE').Count > 0) or (CreationPermise and not EstLivreV1 and ChapitrePermisVersion('DATA_CAREER_SPECIE')) then
    begin
      NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_583', 'Career species'));
      SetNodeInfo(NodeTirage, NT_LIEN_CARRIERE_ESPECE, '', 'DATA_CAREER_SPECIE');
    end;
    // DATA_RULE_SPECIE : un seul noeud, qui ouvre la table des regles par ethnie (type 70)
    if (XMLDoc.GetElementsByTagName('DATA_RULE_SPECIE').Count > 0) or (CreationPermise and ChapitrePermisVersion('DATA_RULE_SPECIE')) then
    begin
      NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot, GetTexteLibelle('RULES-LAB_808', 'Rules by ethnicity'));
      SetNodeInfo(NodeTirage, NT_REGLE_ETHNIE, '', 'DATA_RULE_SPECIE');
    end;
    // DATA_CLASS_ITEM : un seul noeud, qui ouvre la table d'equipement de toutes les classes
    if (XMLDoc.GetElementsByTagName('DATA_CLASS_ITEM').Count > 0) or (CreationPermise and not EstLivreV1 and ChapitrePermisVersion('DATA_CLASS_ITEM')) then
    begin
      NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot, LibelleChapitre('DATA_CLASS_ITEM'));
      SetNodeInfo(NodeTirage, NT_EQUIP_CLASSE, '', 'DATA_CLASS_ITEM');
    end;
    // DATA_CAREER_SUBCHOICE : un seul noeud, qui ouvre la grille du second jet (type 65)
    if (XMLDoc.GetElementsByTagName('DATA_CAREER_SUBCHOICE').Count > 0) or (CreationPermise and not EstLivreV1 and ChapitrePermisVersion('DATA_CAREER_SUBCHOICE')) then
    begin
      NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot, LibelleChapitre('DATA_CAREER_SUBCHOICE'));
      SetNodeInfo(NodeTirage, NT_SECOND_JET, '', 'DATA_CAREER_SUBCHOICE');
    end;
    for I := 0 to High(TablesEntieres) do
      if ((XMLDoc.GetElementsByTagName(TablesEntieres[I]).Count > 0) or
          (CreationPermise and (not EstLivreV1 or ChapitreV1Permis(TablesEntieres[I])) and
           ChapitrePermisVersion(TablesEntieres[I]))) and
         (TablesEntieres[I] <> 'DATA_CAREER_SUBCHOICE') and
         not ((XMLDoc.GetElementsByTagName(TablesEntieres[I]).Count = 0) and ChapitreReserveRulebook(TablesEntieres[I])) and
         ((TablesEntieres[I] <> 'DATA_CAREER_LINK_V1') or EstLivreV1) and  // liens entre carrieres : un chapitre par version
         ((TablesEntieres[I] <> 'DATA_CAREER_LINK_V2') or EstLivreV2) then
      begin
        NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot, LibelleChapitre(TablesEntieres[I]));
        SetNodeInfo(NodeTirage, NT_TABLE_VALEURS, TablesEntieres[I], TablesEntieres[I]);
      end;
  end;

  procedure BrancheSorts;
  begin
    ChargerBrancheSimple('DATA_SPELL', 'Sort', GetTexteLibelle('RULES-LAB_083'), 35, NodeRoot);
  end;

  procedure BrancheTirageRace;
  var
    NodeTirage: TTreeNode;
  begin
    // ========== TIRAGE ALÉATOIRE DE RACE ==========
    // Un seul noeud, sans enfant : il ouvre directement la table.
    if (XMLDoc.GetElementsByTagName('DATA_RANDOM_SPECIE').Count > 0) or (CreationPermise and not EstLivreV1 and ChapitrePermisVersion('DATA_RANDOM_SPECIE')) then
    begin
      NodeTirage := TreeViewLivre.Items.AddChild(NodeRoot,
                      GetTexteLibelle('RULES-LAB_042') + ' ' + GetTexteLibelle('RULES-LAB_085'));
      SetNodeInfo(NodeTirage, NT_TIRAGE_RACE, '', 'DATA_RANDOM_SPECIE');
    end;
  end;

begin
  try
    // Charger le fichier XML
    ReadXMLFile(XMLDoc, AFilePath);
    
    if XMLDoc = nil then
      begin
        // ShowMessage('Erreur: Impossible de charger le XML');
        Exit;
      end;

    // Livre inacheve (COMPLETE = 0) : le fichier de DATABASE n'est qu'un stub, on charge
    // la version de travail la plus recente. CurrentFilePath reste celui du stub : il nomme
    // le dossier TRAVAIL ou l'enregistrement ecrit.
    Travail := DerniereVersionTravail(AFilePath);
    if Travail <> '' then
    begin
      XMLDoc.Free;
      XMLDoc := nil;
      ReadXMLFile(XMLDoc, Travail);
    end;

    CurrentFilePath := AFilePath;
    if DerniereEbauche <> '' then DeleteFile(DerniereEbauche);
    DerniereEbauche := '';

    // Effacer l'arbre (libérer les TNodeInfo AVANT le Clear)
    LibererNodesData(TreeViewLivre);
    TreeViewLivre.Items.Clear;
    if RacesDataList <> nil then
      RacesDataList.Clear;
    MasquerAfficherElements('');  // plus de fiche ni de grille du livre precedent
    MasquerForm();
    
    FileName := ExtractFileName(AFilePath);  // "BOOK RULESBOOK.Xml"
    FileCode := Copy(FileName, 1, Length(FileName) - 4);  // "BOOK RULESBOOK"

    // Récupérer le label traduit
    NodeRoot := TreeViewLivre.Items.Add(nil, GetBookLabel(FileCode));
    // Pas de libelle traduit : nom d'affichage du livre (<BOOKNAME>) plutot que le code "BOOK ..."
    if SameText(NodeRoot.Text, StringReplace(FileCode, '_', ' ', [rfReplaceAll])) and (XmlNomAffichageLivre(AFilePath) <> '') then
      NodeRoot.Text := XmlNomAffichageLivre(AFilePath);

    // Afficher le nom complet dans LabelLivre
    LabelLivre.Caption := GetTexteLibelle('RULES-LAB_128') + ': ' + FileName;
    ButtonEnregistrerTravail.Caption := GetTexteLibelle('RULES-LAB_348');
    ButtonPublierRevision.Caption := GetTexteLibelle('RULES-LAB_350');
    ButtonFinaliser.Caption := GetTexteLibelle('RULES-LAB_433');
    ButtonMettreAJour.Caption := GetTexteLibelle('RULES-LAB_499');
    MajBoutonFinaliser;

    // Afficher dans LabelFormTitle
    LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_128') + ': ' + FileName;
    SetNodeInfo(NodeRoot, NT_CHAPITRE);  // 0 = chapitre

    // Livre de traduction : pas d'arbre de donnees, la grille anglais / traduction
    if EstLivreTraduction then
    begin
      AfficherTraduction;
      Exit;
    end;

    // Ordre de creation : ce qui ne depend de rien d'abord, puis ce qui s'appuie dessus
    BrancheInfosLivre;
    BrancheCompetencesTalents;
    BrancheEquipement;
    BrancheSorts;
    BrancheTablesRegles;
    BrancheRaces;
    BrancheRacesGroupes;
    BrancheCarrieres;
    BrancheTirageRace;
    BranchePetitesTables;
    BrancheLibellesLivre;

    // Races et carrieres en ordre alphabetique (sinon l'ordre du fichier)
    NodeRaces.AlphaSort;
    NodeCareers.AlphaSort;

    // Expand les branches principales
    NodeRoot.Expand(False);
    
    LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_128') + ': ' + FileName;
    
  except
    on E: Exception do
      // ShowMessage('Erreur: ' + E.Message);
  end;
end;

// ✨ ÉVÉNEMENTS TREEVIEW

procedure TWinLivres.TreeViewLivreChange(Sender: TObject; Node: TTreeNode);
var
  RaceCodeFound: String;
  PageSource: String;
begin
  if Node = nil then Exit;
  
  NodeSelectionnee := Node;
  FicheGenerique := False;
  // Titre par defaut = texte du noeud (sinon le libelle de la maquette « Select » reste affiche
  // pour les types qui ne fixent pas de titre) ; chaque branche ci-dessous peut le remplacer
  LabelFormTitle.Caption := Node.Text;
  MemoEncartBranche.Visible := False;
  // Image d'ethnie / de carriere : seulement sur la branche de l'ethnie ou de la carriere (reposee par AfficherDonnee...),
  // pas sur ses sous-branches (Attribute, Specie's Skills, Talent, Career...)
  if PanelImageLivre <> nil then
    PanelImageLivre.Masquer;
  // Encart : a quoi sert la branche (texte RULES-HELP_BRANCHE_<balise>, absent = pas d'encart)
  if (Node.Data <> nil) and (TNodeInfo(Node.Data).Chapitre <> '') then
  begin
    PageSource := 'RULES-HELP_BRANCHE_' + TNodeInfo(Node.Data).Chapitre;
    RaceCodeFound := GetTexteLibelle(PageSource);
    if (RaceCodeFound <> '') and (RaceCodeFound <> PageSource) then
    begin
      MemoEncartBranche.Text := RaceCodeFound;
      MemoEncartBranche.Visible := True;
    end;
  end;

  // Vérifier le type de nœud basé sur Node.Data
  case GetNodeType(Node) of
    NT_CHAPITRE: begin
         // C'est un chapitre (Races, Attributes, Careers, etc.)
         TypeNodeSelectionnee := 'CHAPITRE';
         MasquerAfficherElements('');  // Masquer tous les grids
         MasquerForm();
         if EstLivreTraduction then AfficherTraduction;
       end;
    NT_RACE: begin
         // C'est une race
         TypeNodeSelectionnee := 'DONNEE';
         CurrentRaceCode := GetNodeCode(Node);
         LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_042') + ': ' + Node.Text;
         MasquerAfficherElements('');  // Masquer tous les grids
         AfficherDonneeRace(CurrentRaceCode);
       end;
    NT_ATTRIBUT: begin
         // C'est un attribut
         TypeNodeSelectionnee := 'ATTRIBUT';
         // Extract raw value from "Label: Value" format
         CurrentAttributeValue := Copy(Node.Text, Pos(': ', Node.Text) + 2, Length(Node.Text));
         // Display attribute name in title
         LabelFormTitle.Caption := Copy(Node.Text, 1, Pos(': ', Node.Text) - 1);
         MasquerAfficherElements('');  // Masquer tous les grids
         AfficherDonneeAttribut(CurrentAttributeValue);
       end;
    NT_RACE_GROUPE: begin
         // Une race (DATA_RACE) : libelle modifiable
         TypeNodeSelectionnee := 'DONNEE';
         MasquerAfficherElements('');
         AfficherRaceGroupe(GetNodeCode(Node));
       end;
    NT_NIVEAUX_CARRIERE: begin
         // Branche "Niveaux" d'une carriere : nom et salaire de chaque niveau, ajout et retrait
         TypeNodeSelectionnee := 'CHAPITRE';
         if Node.Parent <> nil then
           LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_369') + ': ' + Node.Parent.Text;
         AfficherNiveauxCarriere(GetNodeCode(Node));
       end;
    NT_CORRUPTION_ETHNIE: begin
         // Tranches d100 de corruption physique et mentale d'une ethnie
         TypeNodeSelectionnee := 'CHAPITRE';
         if Node.Parent <> nil then
           LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_156') + ': ' + Node.Parent.Text;
         AfficherCorruptionEthnie(GetNodeCode(Node));
       end;
    NT_ATTRIBUTS_ETHNIE: begin
         // C'est la branche "Attributs" d'une ethnie : tableaux dés / valeurs simples / Blessures
         TypeNodeSelectionnee := 'CHAPITRE';
         if Node.Parent <> nil then
           LabelFormTitle.Caption := GetAttributLabel('RULES-LAB_008') + ': ' + Node.Parent.Text;
         AfficherAttributsEthnie(GetNodeCode(Node));
       end;
    NT_COMPETENCES_RACE: begin
         // C'est une branche "Compétences de race"
         TypeNodeSelectionnee := 'CHAPITRE';
         // Afficher toutes les compétences de la race parente
         RaceCodeFound := GetNodeCode(Node);
         
         if RaceCodeFound <> '' then
         begin
           if Node.Parent <> nil then
             LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_087') + ': ' + Node.Parent.Text;
           
           AfficherSkillsForRace(RaceCodeFound);  // Appelle MasquerAfficherElements('COMPETENCE')
         end
         else
         begin
           MasquerAfficherElements('');  // Masquer tous les grids
           MasquerForm();
         end;
       end;
    NT_COMPETENCE: begin
         // C'est un item "Compétence"
         TypeNodeSelectionnee := 'COMPETENCE';
         LabelFormTitle.Caption := Node.Text;
         // Pour l'instant, juste afficher le nom
         MasquerAfficherElements('');  // Masquer tous les grids
         MasquerForm();
       end;
    NT_TALENTS_RACE: begin
         // C'est la branche "Talents"
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_007');
         RaceCodeFound := GetNodeCode(Node);
         if RaceCodeFound <> '' then
           AfficherTalentsEthnie(RaceCodeFound)  // grille modifiable (ModeTalents)
         else
           AfficherTalentsForRace();  // Appelle MasquerAfficherElements('TALENT')
       end;
    NT_CARRIERES_RACE: begin
         // C'est la branche "Carrières de race"
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_006');
         
         RaceCodeFound := GetNodeCode(Node);
         
         if RaceCodeFound <> '' then
           AfficherCareersForRace(RaceCodeFound)  // Appelle MasquerAfficherElements('CARRIERE')
         else
         begin
           MasquerAfficherElements('');  // Masquer tous les grids
           MasquerForm();
         end;
       end;
    NT_CARRIERE: begin
         // C'est un item "Carrière"
         TypeNodeSelectionnee := 'CARRIERE';
         LabelFormTitle.Caption := Node.Text;
         // Pour l'instant, juste afficher le nom
         MasquerAfficherElements('');  // Masquer tous les grids
         MasquerForm();
       end;
    NT_METIER_NIVEAU1: begin
         // C'est un métier de niveau 1
         TypeNodeSelectionnee := 'METIER';
         AfficherDonneeMetier(GetNodeCode(Node));
       end;
    NT_ENTREES_CARRIERE, NT_SORTIES_CARRIERE, NT_CARAC_CARRIERE, NT_COMPETENCES_CARRIERE, NT_TALENTS_CARRIERE, NT_EQUIPEMENT_CARRIERE: begin
         // Branches d'une carriere WFRP2 : entrees / sorties en cases, caracteristiques / competences / talents / equipement en tableaux
         TypeNodeSelectionnee := 'METIER';
         case GetNodeType(Node) of
           NT_ENTREES_CARRIERE: AfficherBrancheCoches(GetNodeCode(Node), 1);
           NT_SORTIES_CARRIERE: AfficherBrancheCoches(GetNodeCode(Node), 2);
           NT_CARAC_CARRIERE: AfficherBrancheCoches(GetNodeCode(Node), 3);
           NT_COMPETENCES_CARRIERE: AfficherBrancheCoches(GetNodeCode(Node), 4);
           NT_TALENTS_CARRIERE: AfficherBrancheCoches(GetNodeCode(Node), 5);
         else
           AfficherBrancheCoches(GetNodeCode(Node), 6);
         end;
       end;
    NT_RACES_POSSIBLES: begin
         // Branche "Races possibles" d'un métier
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := ConstArbreRacePossible;
         if Node.Parent <> nil then
           LabelFormTitle.Caption := ConstArbreRacePossible + ': ' + Node.Parent.Text;
         
         AfficherRacesForMetier(GetNodeCode(Node));
       end;
    NT_BRANCHE_ATTRIBUT_NIVEAU: begin
         // Branche "Attribut" d'un niveau de métier
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := ConstArbreAttribut;
         if Node.Parent <> nil then
           LabelFormTitle.Caption := ConstArbreAttribut + ': ' + Node.Parent.Text;
         
         AfficherAttributsForNiveau(GetNodeCode(Node));
       end;
    NT_BRANCHE_COMPETENCE_NIVEAU: begin
         // Branche "Compétence" d'un niveau de métier
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := ConstArbreCompetence;
         if Node.Parent <> nil then
           LabelFormTitle.Caption := ConstArbreCompetence + ': ' + Node.Parent.Text;
         
         AfficherCompetencesCarriere(GetNodeCode(Node), False);
       end;
    NT_BRANCHE_TALENT_NIVEAU: begin
         // Branche "Talent" d'un niveau de métier
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := ConstArbreTalent;
         if Node.Parent <> nil then
           LabelFormTitle.Caption := ConstArbreTalent + ': ' + Node.Parent.Text;
         
         AfficherCompetencesCarriere(GetNodeCode(Node), True);
       end;
    NT_BRANCHE_EQUIPEMENT_NIVEAU: begin
         // Branche "Equipement" d'un niveau de métier
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := ConstArbreEquipement;
         if Node.Parent <> nil then
           LabelFormTitle.Caption := ConstArbreEquipement + ': ' + Node.Parent.Text;
         
         AfficherEquipementForNiveau(GetNodeCode(Node));
       end;
    NT_COMPETENCE_N1: begin
         // Compétence de niveau 1
         TypeNodeSelectionnee := 'COMPETENCE';
         AfficherDonneeCompetence(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_009'));
       end;
    NT_SPECIALISATION_COMPETENCE: begin
         // Spécialisation de compétence
         TypeNodeSelectionnee := 'COMPETENCE';
         AfficherDonneeCompetence(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_146'));
       end;
    NT_TALENT_N1: begin
         // Talent de niveau 1
         TypeNodeSelectionnee := 'TALENT';
         AfficherDonneeTalent(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_007'));
       end;
    NT_SPECIALISATION_TALENT: begin
         // Spécialisation de talent
         TypeNodeSelectionnee := 'TALENT';
         AfficherDonneeTalent(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_147'));
       end;
    NT_ARME: begin
         // Arme
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeEquipement(GetNodeCode(Node), 'Weapon', GetTexteLibelle('RULES-LAB_063'));
       end;
    NT_ARMURE: begin
         // Armure
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeEquipement(GetNodeCode(Node), 'Armor', GetTexteLibelle('RULES-LAB_065'));
       end;
    NT_QUALITE_ARME: begin
         // Qualité d'arme
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node),
                                  GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_063'));
       end;
    NT_ARMURE_SIMPLIFIEE: begin
         // Armure simplifiée
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeEquipement(GetNodeCode(Node), 'ArmorSimp', GetTexteLibelle('RULES-LAB_149'));
       end;
    NT_QUALITE_ARMURE: begin
         // Qualité d'armure
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node),
                                  GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_065'));
       end;
    NT_TRAPPING: begin
         // Trapping (équipement divers)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeEquipement(GetNodeCode(Node), 'Trapping', GetTexteLibelle('RULES-LAB_196'));
       end;
    NT_FABRICATION: begin
         // Fabrication (Craftsmanship)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_125'), 'Craftsmanship');
       end;
    NT_NATION: begin
         // Nation
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_332'), 'Nation');
       end;
    NT_CONDITION: begin
         // Condition (if=)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeCondition(GetNodeCode(Node));
       end;
    NT_LIBELLE_LIVRE: begin
         // Libelle du livre (DATA_LABEL)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeLibelle(GetNodeCode(Node));
       end;
    NT_OPTION_REGLE: begin
         // Option de règle
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_277'), 'OptionRule');
       end;
    NT_CORRUPTION_PHYSIQUE, NT_CORRUPTION_MENTALE: begin
         // Corruption (table physique ou mentale)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_156'), 'Corruption');
       end;
    NT_MALADIE: begin
         // Maladie
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeMaladie(GetNodeCode(Node));
       end;
    NT_AFFLICTION: begin
         // Affliction
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_296'), 'Affliction');
       end;
    NT_SIGNE_ASTRAL: begin
         // Signe astral
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_272'), 'StarSign');
       end;
    NT_COMPETENCE_V2: begin
         // Competence WFRP2 (lecture seule)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'SkillV2');
       end;
    NT_TALENT_V2: begin
         // Talent WFRP2 (lecture seule)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'TalentV2');
       end;
    NT_SORT_V2: begin
         // Sort WFRP2 (lecture seule)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'SpellV2');
       end;
    NT_SORT_V1: begin
         // Sort WFRP1 (editable)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'SpellV1');
       end;
    NT_COMPETENCE_V1: begin
         // Competence WFRP1 (editable)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'SkillV1');
       end;
    NT_EQUIPEMENT_V1: begin
         // Objet WFRP1 (editable)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'EquipmentV1');
       end;
    NT_DIEU_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Deity');
       end;
    NT_CULTE_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Cult');
       end;
    NT_FAMILIER_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Familiar');
       end;
    NT_HANDICAP_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Disability');
       end;
    NT_LIGNE_TABLE_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherLigneTable(GetNodeCode(Node));
       end;
    NT_ATTRIBUT_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Attribut');
       end;
    NT_CORRUPTION_V2: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeCorruptionV2(GetNodeCode(Node));
       end;
    NT_CLASSE_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Class');
       end;
    NT_METIER_V1: begin
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'Trade');
       end;
    NT_EQUIPEMENT_V2: begin
         // Article d'equipement WFRP2 (lecture seule)
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeV2(GetNodeCode(Node), 'EquipmentV2');
       end;
    NT_BONUS_CARRIERE: begin
         // Bonus de carriere
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_320'), 'CareerBonus');
       end;
    NT_ADAPTATION_CARRIERE: begin
         // Adaptation de carriere
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeBonusMalus(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_321'), 'Adaptation');
       end;
    NT_PETITE_TABLE_DEBUT..NT_PETITE_TABLE_FIN: begin
         // Petite table technique à entrées nommées
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneePetiteTable(PetitesTablesChapitre[GetNodeType(Node) - NT_PETITE_TABLE_DEBUT],
                                   PetitesTablesTag[GetNodeType(Node) - NT_PETITE_TABLE_DEBUT], GetNodeCode(Node));
       end;
    NT_TABLE_VALEURS: begin
         // Table de valeurs : tout le chapitre
         TypeNodeSelectionnee := 'EQUIPEMENT';
         AfficherDonneeChapitre(GetNodeCode(Node));
       end;
    NT_SORT: begin
         // Sort
         TypeNodeSelectionnee := 'SORT';
         AfficherDonneeSort(GetNodeCode(Node), GetTexteLibelle('RULES-LAB_083'));
       end;
    NT_TIRAGE_RACE: begin
         // Table de tirage aléatoire de race
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_042') + ' ' + GetTexteLibelle('RULES-LAB_085');
         AfficherTirageRaceMatrice;
       end;
    NT_TRAIT_ETHNIE: begin
         // Traits d'ethnie
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := LibelleChapitre('DATA_SPECIE_TRAIT');
         AfficherTraitsEthnie;
       end;
    NT_LIEN_CARRIERE_ESPECE: begin
         // Liens carriere <-> espece
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_583', 'Career species');
         AfficherCarriereEspece;
       end;
    NT_REGLE_ETHNIE: begin
         // Regles par ethnie
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_808', 'Rules by ethnicity');
         AfficherRegleEthnie;
       end;
    NT_SECOND_JET: begin
         // Second jet apres le metier
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := LibelleChapitre('DATA_CAREER_SUBCHOICE');
         AfficherSousMetier;
       end;
    NT_EQUIP_CLASSE: begin
         // Equipement de depart par classe
         TypeNodeSelectionnee := 'CHAPITRE';
         LabelFormTitle.Caption := LibelleChapitre('DATA_CLASS_ITEM');
         AfficherEquipClasse;
       end;
    NT_INFO_LIVRE: begin
             // Informations du livre (bloc DATA_BOOK)
             TypeNodeSelectionnee := 'LIVRE';
             AfficherInfosLivre();
           end;
    NT_RACE_POSSIBLE, NT_NIVEAU_METIER, NT_ATTRIBUT_NIVEAU, NT_COMPETENCE_NIVEAU, NT_TALENT_NIVEAU, NT_EQUIPEMENT_NIVEAU: begin
         // Sous-branches d'un métier : races possibles, niveaux et leur contenu.
         // Affichage seul pour l'instant, la saisie viendra plus tard.
         TypeNodeSelectionnee := 'METIER';
         LabelFormTitle.Caption := Node.Text;
         MasquerAfficherElements('');  // Masquer tous les grids
         MasquerForm();
       end;
  else
    begin
      // Cas non gérés
      MasquerAfficherElements('');  // Masquer tous les grids
      MasquerForm();
    end;
  end;
  // Page du livre source, en lecture seule, a la suite du titre de la fiche
  PageSource := PageDeFiche(GetNodeCode(Node));
  if (PageSource <> '') and LabelFormTitle.Visible then
    LabelFormTitle.Caption := LabelFormTitle.Caption + ' (p. ' + PageSource + ')';
end;

// Des cellules modifiees et non validees (boutons Valider/Annuler actifs) vont etre perdues :
// demande confirmation. Oui = on abandonne (boutons regrises), Non = on reste sur l'ecran.
function TWinLivres.ConfirmerAbandonModifs: Boolean;
begin
  Result := True;
  // fiches et panneaux modifiables (arme, sort, competence, talent, carriere, race)
  if FicheSnapshot <> '' then
  begin
    PanelBonus.FinEdition;
    PanelTirage.FinEdition;
    PanelTirageRace.FinEdition;
    PanelEquipClasse.FinEdition;
    PanelTraitEthnie.FinEdition;
    PanelCarriereEspece.FinEdition;
    PanelRegleEthnie.FinEdition;
    PanelTraduction.FinEdition;
    PanelSousMetier.FinEdition;
    PanelTirageMetier.FinEdition;
    if (InstantaneFiche <> FicheSnapshot) and not TestSansMessage then  // test d'edition : on abandonne sans demander
    begin
      Result := MessageDlg(GetTexteLibelle('RULES-LAB_355'), mtConfirmation, [mbYes, mbNo], 0) = mrYes;
      if not Result then Exit;
    end;
    FicheSnapshot := '';
    MajBoutonsFiche;
  end;
  if not ButtonAttrValider.Enabled then Exit;
  if AttrSnapshot = '' then  // aucun ecran d'attributs affiche depuis le lancement : rien a perdre
  begin
    MajBoutonsAttr(False);
    Exit;
  end;
  FermerEditeursAttr;
  if InstantaneCourant = AttrSnapshot then
  begin
    MajBoutonsAttr(False);
    Exit;
  end;
  Result := MessageDlg(GetTexteLibelle('RULES-LAB_355'), mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  if Result then
    MajBoutonsAttr(False);
end;

procedure TWinLivres.TreeViewLivreChanging(Sender: TObject; Node: TTreeNode; var AllowChange: Boolean);
begin
  AllowChange := ConfirmerAbandonModifs;
end;

procedure TWinLivres.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmerAbandonModifs;
end;

procedure TWinLivres.TreeViewLivreDblClick(Sender: TObject);
begin
  // Pour l'instant, juste READ-ONLY
  // Double-clic ne fait rien
end;

// Grille des niveaux d'une carriere : le double-clic d'une ligne ouvre le noeud
// de ce niveau dans l'arbre (profil, competences, talents, equipement).
procedure TWinLivres.GridNiveauxDblClick(Sender: TObject);
var
  Pt: TPoint;
  C, R, I: Integer;
  Pere, N: TTreeNode;
  Cible: String;
begin
  if not ModeNiveaux then Exit;
  Pt := StringGridAttrEthnie.ScreenToClient(Mouse.CursorPos);
  StringGridAttrEthnie.MouseToCell(Pt.X, Pt.Y, C, R);
  if R < 1 then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Cible := AttrRaceCode + '|' + Trim(StringGridAttrEthnie.Cells[1, R]);
  Pere := TreeViewLivre.Selected;
  if Pere = nil then Exit;
  if Pere.Parent <> nil then Pere := Pere.Parent;  // le noeud « niveaux » est une soeur des niveaux
  for I := 0 to Pere.Count - 1 do
  begin
    N := Pere.Items[I];
    if GetNodeCode(N) = Cible then
    begin
      TreeViewLivre.Selected := N;
      Exit;
    end;
  end;
end;

procedure TWinLivres.TreeViewLivreContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  Noeud: TTreeNode;
begin
  Handled := False;
  // le clic droit ne selectionne pas : le menu agit sur le noeud sous la souris
  Noeud := TreeViewLivre.GetNodeAt(MousePos.X, MousePos.Y);
  if (Noeud <> nil) and (Noeud <> TreeViewLivre.Selected) then
    TreeViewLivre.Selected := Noeud;
end;

// Menu contextuel de l'arbre : seule la creation d'une carriere existe pour l'instant.
// Elle n'est offerte que sur la branche des carrieres (ou l'une d'elles) d'un livre de travail.
procedure TWinLivres.PopupMenuTreePopup(Sender: TObject);
var
  ArmureQ: Boolean;
begin
  if NoeudEthnies(TreeViewLivre.Selected) <> nil then
    MenuItemAjouter.Caption := GetTexteLibelle('RULES-LAB_387')
  else
    MenuItemAjouter.Caption := GetTexteLibelle('RULES-LAB_382');
  MenuItemAjouter.Visible := (NoeudCarrieres(TreeViewLivre.Selected) <> nil) or (NoeudEthnies(TreeViewLivre.Selected) <> nil);
  MenuItemAjouter.Enabled := (XMLDoc <> nil) and CreationPermise and MenuItemAjouter.Visible;
  MenuItemNouvelleRace.Caption := GetTexteLibelle('RULES-LAB_392');
  MenuItemNouvelleRace.Visible := NoeudRacesGroupes(TreeViewLivre.Selected) <> nil;
  MenuItemNouvelleRace.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleCompetence.Caption := GetTexteLibelle('RULES-LAB_401');
  MenuItemNouvelleCompetence.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_009', 26) <> nil;
  MenuItemNouvelleCompetence.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauTalent.Caption := GetTexteLibelle('RULES-LAB_402');
  MenuItemNouveauTalent.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_007', 28) <> nil;
  MenuItemNouveauTalent.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleArme.Caption := GetTexteLibelle('RULES-LAB_436');
  MenuItemNouvelleArme.Visible := NoeudArmes(TreeViewLivre.Selected) <> nil;
  MenuItemNouvelleArme.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleArmure.Caption := GetTexteLibelle('RULES-LAB_442');
  MenuItemNouvelleArmure.Visible := NoeudArmures(TreeViewLivre.Selected) <> nil;
  MenuItemNouvelleArmure.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleQualite.Visible := NoeudQualites(TreeViewLivre.Selected, ArmureQ) <> nil;
  if ArmureQ then
    MenuItemNouvelleQualite.Caption := GetTexteLibelle('RULES-LAB_459')
  else
    MenuItemNouvelleQualite.Caption := GetTexteLibelle('RULES-LAB_458');
  MenuItemNouvelleQualite.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauTrapping.Caption := GetTexteLibelle('RULES-LAB_457');
  MenuItemNouveauTrapping.Visible := NoeudTrappings(TreeViewLivre.Selected) <> nil;
  MenuItemNouveauTrapping.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleMaladie.Caption := GetTexteLibelle('RULES-LAB_475');
  MenuItemNouvelleMaladie.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_281', 44) <> nil;
  MenuItemNouvelleMaladie.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleAffliction.Caption := GetTexteLibelle('RULES-LAB_479');
  MenuItemNouvelleAffliction.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_296', 45) <> nil;
  MenuItemNouvelleAffliction.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauSigne.Caption := GetTexteLibelle('RULES-LAB_537', 'New star sign');
  MenuItemNouveauSigne.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_318', 60) <> nil;
  MenuItemNouveauSigne.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauBonus.Caption := GetTexteLibelle('RULES-LAB_558', 'New career bonus');
  MenuItemNouveauBonus.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_320', 62) <> nil;
  MenuItemNouveauBonus.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleAdaptation.Caption := GetTexteLibelle('RULES-LAB_564', 'New career adaptation');
  MenuItemNouvelleAdaptation.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_321', 63) <> nil;
  MenuItemNouvelleAdaptation.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleMutation.Caption := GetTexteLibelle('RULES-LAB_480');
  MenuItemNouvelleMutation.Visible := TypeBrancheMutation(TreeViewLivre.Selected) <> 0;
  MenuItemNouvelleMutation.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleNation.Caption := GetTexteLibelle('RULES-LAB_481');
  MenuItemNouvelleNation.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_332', 40) <> nil;
  MenuItemNouvelleNation.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleCondition.Caption := GetTexteLibelle('RULES-LAB_489');
  MenuItemNouvelleCondition.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_488', 58) <> nil;
  MenuItemNouvelleCondition.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleFabrication.Caption := GetTexteLibelle('RULES-LAB_482');
  MenuItemNouvelleFabrication.Visible := NoeudFabrications(TreeViewLivre.Selected) <> nil;
  MenuItemNouvelleFabrication.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauSort.Caption := GetTexteLibelle('RULES-LAB_452');
  MenuItemNouveauSort.Visible := (NoeudSorts(TreeViewLivre.Selected) <> nil) and not EstLivreV1;
  MenuItemNouveauSort.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleSpecialisation.Caption := GetTexteLibelle('RULES-LAB_406');
  MenuItemNouvelleSpecialisation.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_146', 27) <> nil;
  MenuItemNouvelleSpecialisation.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleSpecTalent.Caption := GetTexteLibelle('RULES-LAB_410');
  MenuItemNouvelleSpecTalent.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_147', 29) <> nil;
  MenuItemNouvelleSpecTalent.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemDeplierBranche.Caption := GetTexteLibelle('RULES-LAB_927', 'Expand branch');
  MenuItemDeplierBranche.Visible := (TreeViewLivre.Selected <> nil) and (TreeViewLivre.Selected.Count > 0);
  MenuItemReplierBranche.Caption := GetTexteLibelle('RULES-LAB_928', 'Collapse branch');
  MenuItemReplierBranche.Visible := MenuItemDeplierBranche.Visible;
  MenuItemNouvelleDivinite.Caption := GetTexteLibelle('RULES-LAB_932', 'New deity');
  MenuItemNouvelleDivinite.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_869', NT_DIEU_V1) <> nil;
  MenuItemNouvelleDivinite.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauCulte.Caption := GetTexteLibelle('RULES-LAB_933', 'New cult');
  MenuItemNouveauCulte.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_870', NT_CULTE_V1) <> nil;
  MenuItemNouveauCulte.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauSortV1.Caption := GetTexteLibelle('RULES-LAB_937', 'New spell');
  MenuItemNouveauSortV1.Visible := NoeudGroupeV1(TreeViewLivre.Selected, NT_SORT_V1) <> nil;
  MenuItemNouveauSortV1.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelObjetV1.Caption := GetTexteLibelle('RULES-LAB_938', 'New item');
  MenuItemNouvelObjetV1.Visible := NoeudGroupeV1(TreeViewLivre.Selected, NT_EQUIPEMENT_V1) <> nil;
  MenuItemNouvelObjetV1.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouvelleClasse.Caption := GetTexteLibelle('RULES-LAB_935', 'New class');
  MenuItemNouvelleClasse.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_880', NT_CLASSE_V1) <> nil;
  MenuItemNouvelleClasse.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauHandicap.Caption := GetTexteLibelle('RULES-LAB_936', 'New disability');
  MenuItemNouveauHandicap.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_842', NT_HANDICAP_V1) <> nil;
  MenuItemNouveauHandicap.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemNouveauFamilier.Caption := GetTexteLibelle('RULES-LAB_934', 'New familiar');
  MenuItemNouveauFamilier.Visible := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_871', NT_FAMILIER_V1) <> nil;
  MenuItemNouveauFamilier.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemLigneNouvelle.Caption := GetTexteLibelle('RULES-LAB_929', 'New line');
  MenuItemLigneDupliquer.Caption := GetTexteLibelle('RULES-LAB_930', 'Duplicate line');
  MenuItemLigneSupprimer.Caption := GetTexteLibelle('RULES-LAB_931', 'Delete line');
  MenuItemLigneDupliquer.Visible := (TreeViewLivre.Selected <> nil) and (GetNodeType(TreeViewLivre.Selected) = NT_LIGNE_TABLE_V1);
  MenuItemLigneSupprimer.Visible := MenuItemLigneDupliquer.Visible;
  // « Nouvelle ligne » : sur une ligne, ou sur la branche dont les filles sont des lignes (ajout en fin de table)
  MenuItemLigneNouvelle.Visible := MenuItemLigneDupliquer.Visible or ((TreeViewLivre.Selected <> nil) and
    (TreeViewLivre.Selected.Count > 0) and (GetNodeType(TreeViewLivre.Selected.GetLastChild) = NT_LIGNE_TABLE_V1));
  MenuItemLigneNouvelle.Enabled := (XMLDoc <> nil) and CreationPermise;
  MenuItemLigneDupliquer.Enabled := MenuItemLigneNouvelle.Enabled;
  MenuItemLigneSupprimer.Enabled := MenuItemLigneNouvelle.Enabled;
  MenuItemModifier.Visible := False;
  MenuItemSupprimer.Caption := GetTexteLibelle('RULES-LAB_398');
  MenuItemSupprimer.Visible := (TreeViewLivre.Selected <> nil) and (GetNodeType(TreeViewLivre.Selected) in [NT_RACE, NT_METIER_NIVEAU1, NT_COMPETENCE_N1, NT_SPECIALISATION_COMPETENCE, NT_TALENT_N1, NT_SPECIALISATION_TALENT, NT_ARME, NT_ARMURE, NT_QUALITE_ARME, NT_QUALITE_ARMURE, NT_SORT, NT_TRAPPING, NT_FABRICATION, NT_NATION, NT_CORRUPTION_PHYSIQUE, NT_CORRUPTION_MENTALE, NT_MALADIE, NT_AFFLICTION, NT_RACE_GROUPE, NT_CONDITION, NT_SIGNE_ASTRAL, NT_BONUS_CARRIERE, NT_ADAPTATION_CARRIERE, NT_DIEU_V1, NT_CULTE_V1, NT_FAMILIER_V1, NT_CLASSE_V1, NT_HANDICAP_V1, NT_SORT_V1, NT_EQUIPEMENT_V1]);
  MenuItemSupprimer.Enabled := (XMLDoc <> nil) and CreationPermise;
end;

// Deplie / replie le noeud selectionne et tous ses descendants.
procedure TWinLivres.MenuDeplierBrancheClick(Sender: TObject);
begin
  if TreeViewLivre.Selected = nil then Exit;
  TreeViewLivre.BeginUpdate;
  try
    TreeViewLivre.Selected.Expand(True);
  finally
    TreeViewLivre.EndUpdate;
  end;
end;

procedure TWinLivres.MenuReplierBrancheClick(Sender: TObject);
begin
  if TreeViewLivre.Selected = nil then Exit;
  TreeViewLivre.BeginUpdate;
  try
    TreeViewLivre.Selected.Collapse(True);
  finally
    TreeViewLivre.EndUpdate;
  end;
end;

// Ligne d'une table V1 : nouvelle (copie videe de la ligne choisie), copie ou suppression.
// Les lignes sont reperees par leur rang : apres l'operation, les freres du noeud sont renumerotes.
// Petite fenetre : le resultat d'une nouvelle ligne d'avancement de pretre (code lu par le moteur).
function ChoisirResultatPretre(out Code: String): Boolean;
const
  Codes: array[0..4] of String = ('WRATH', 'UNWORTHY', 'TRIAL', 'NOT_READY', 'ADVANCE');
var
  F: TForm;
  Liste: TComboBox;
  Etiquette: TLabel;
  Ok: TButton;
  I: Integer;
begin
  Code := '';
  F := TForm.CreateNew(nil);
  try
    F.BorderStyle := bsDialog;
    F.Position := poScreenCenter;
    F.Caption := 'Result';
    F.ClientWidth := 380;
    F.ClientHeight := 110;
    Etiquette := TLabel.Create(F);
    Etiquette.Parent := F;
    Etiquette.SetBounds(12, 12, 356, 20);
    Etiquette.Caption := 'Result';
    Liste := TComboBox.Create(F);
    Liste.Parent := F;
    Liste.Style := csDropDownList;
    Liste.SetBounds(12, 36, 356, 24);
    for I := 0 to High(Codes) do
      Liste.Items.Add(GetTexteLibelle('RULES-LAB_' + IntToStr(940 + I)));
    Liste.ItemIndex := 4;
    Ok := TButton.Create(F);
    Ok.Parent := F;
    Ok.SetBounds(12, 72, 100, 28);
    Ok.Caption := 'OK';
    Ok.ModalResult := mrOk;
    Ok.Default := True;
    Result := F.ShowModal = mrOk;
    if Result then Code := Codes[Liste.ItemIndex];
  finally
    F.Free;
  end;
end;

procedure TWinLivres.ModifierLigneTable(Operation: Integer);

  procedure Vider(El: TDOMElement);
  var
    Fils: TDOMNode;
  begin
    Fils := El.FirstChild;
    if not (Fils is TDOMElement) then
    begin
      while El.FirstChild <> nil do El.RemoveChild(El.FirstChild);
      Exit;
    end;
    while Fils <> nil do
    begin
      if Fils is TDOMElement then Vider(TDOMElement(Fils));
      Fils := Fils.NextSibling;
    end;
  end;

var
  Node, Pere, Suivant, NouveauNoeud: TTreeNode;
  Code, Prefixe, ResultatPretre: String;
  Ligne, Copie, Nouveau: TDOMElement;
  Fils, Suivant2: TDOMNode;
  I, P: Integer;
begin
  Node := TreeViewLivre.Selected;
  if (Node = nil) or (XMLDoc = nil) or not CreationPermise then Exit;
  // branche de lignes : la nouvelle ligne se range apres la derniere
  if (Operation = 0) and (GetNodeType(Node) <> NT_LIGNE_TABLE_V1) and (Node.Count > 0) then
    Node := Node.GetLastChild;
  if GetNodeType(Node) <> NT_LIGNE_TABLE_V1 then Exit;
  Code := GetNodeCode(Node);
  Ligne := TrouverLigneTable(Code);
  Pere := Node.Parent;
  if (Ligne = nil) or (Pere = nil) then Exit;
  if not ConfirmerAbandonModifs then Exit;
  P := LastDelimiter('|', Code);
  Prefixe := Copy(Code, 1, P);
  if Operation = 2 then
  begin
    if MessageDlg(Format(GetTexteLibelle('RULES-LAB_399'), [Node.Text, 0]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    MasquerForm();
    Ligne.ParentNode.RemoveChild(Ligne);
    Node.Delete;
    NouveauNoeud := nil;
  end
  else
  begin
    // ligne d'avancement de pretre : le resultat se choisit avant la fiche, il decide des balises
    ResultatPretre := '';
    if (Operation = 0) and (Ligne.ParentNode.ParentNode <> nil) and
       (Ligne.ParentNode.ParentNode.NodeName = ConstXmlDataPriestAdvanceV1) then
      if not ChoisirResultatPretre(ResultatPretre) then Exit;
    Copie := TDOMElement(Ligne.CloneNode(True));
    if Operation = 0 then Vider(Copie);
    if ResultatPretre <> '' then
    begin
      Fils := Copie.FirstChild;
      while Fils <> nil do
      begin
        Suivant2 := Fils.NextSibling;
        if (Fils is TDOMElement) and (Fils.NodeName <> 'Range') and (Fils.NodeName <> 'Explanation') then
          Copie.RemoveChild(Fils);
        Fils := Suivant2;
      end;
      Fils := Copie.FirstChild;
      while (Fils <> nil) and (Fils.NodeName <> 'Explanation') do Fils := Fils.NextSibling;
      Nouveau := XMLDoc.CreateElement('Result');
      EcrireValeurXML(Nouveau, ResultatPretre);
      Copie.InsertBefore(Nouveau, Fils);
      if ResultatPretre = 'UNWORTHY' then
        for I := 1 to 3 do
        begin
          Nouveau := XMLDoc.CreateElement('NewCareerClass');
          EcrireValeurXML(Nouveau, '');
          Copie.InsertBefore(Nouveau, Fils);
        end;
    end;
    Ligne.ParentNode.InsertBefore(Copie, Ligne.NextSibling);
    Suivant := Node.GetNextSibling;
    if Suivant <> nil then
      NouveauNoeud := TreeViewLivre.Items.Insert(Suivant, TexteLigneTable(Copie))
    else
      NouveauNoeud := TreeViewLivre.Items.AddChild(Pere, TexteLigneTable(Copie));
  end;
  for I := 0 to Pere.Count - 1 do
    SetNodeInfo(Pere.Items[I], NT_LIGNE_TABLE_V1, Prefixe + IntToStr(I));
  if NouveauNoeud <> nil then
    TreeViewLivre.Selected := NouveauNoeud;
end;

procedure TWinLivres.MenuLigneNouvelleClick(Sender: TObject);
begin
  ModifierLigneTable(0);
end;

procedure TWinLivres.MenuLigneDupliquerClick(Sender: TObject);
begin
  ModifierLigneTable(1);
end;

procedure TWinLivres.MenuLigneSupprimerClick(Sender: TObject);
begin
  ModifierLigneTable(2);
end;

// Correction des donnees EXISTANTES : tout livre ouvert, officiel compris (errata). Creer et supprimer restent
// reserves a CreationPermise. Le versionnement (version de travail, revision, HISTORIQUE) protege l'original.
function TWinLivres.EditionPermise: Boolean;
begin
  Result := XMLDoc <> nil;
end;

// Livre ou l'on peut creer : livre de fan (<OFFICIAL> = 2) ou inacheve (<COMPLETE> = 0).
// Jamais le Rulebook ni un supplement officiel complet.
function TWinLivres.CreationPermise: Boolean;
var
  Livre, Noeud: TDOMNode;
begin
  Result := False;
  if XMLDoc = nil then Exit;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  if Livre = nil then Exit;
  Noeud := Livre.FindNode(ConstXmlOfficielLivre);
  if (Noeud <> nil) and (StrToIntDef(ValeurXML(Noeud), 0) = ConstLivreFanOfficiel) then
    Result := True;
  Noeud := Livre.FindNode(ConstXmlCompletLivre);
  if (Noeud <> nil) and (ValeurXML(Noeud) = '0') then
    Result := True;
end;

// Branche « Carrieres » si le noeud est cette branche ou l'une de ses carrieres, sinon nil.
function TWinLivres.NoeudCarrieres(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_METIER_NIVEAU1) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Level = 1) and (Node.Text = GetTexteLibelle('RULES-LAB_006')) then
    Result := Node;
end;

// Noeud d'une ethnie : donnees pour la liste, puis attributs, competences, talents, carrieres et corruption.
function TWinLivres.AjouterNoeudEthnie(NodeRaces: TTreeNode; XMLElement: TDOMElement): TTreeNode;
var
  J: Integer;
  Code, Description, Explanation: String;
  RaceData: TRaceData;
  PRaceData: ^TRaceData;
  NodeRace: TTreeNode;
  DescNode, ExplNode: TDOMNode;
begin
  Result := nil;
  Code := XMLElement.GetAttribute('id');
  if Code = '' then Exit;
  
  // Chercher Description et Explanation
  DescNode := XMLElement.FindNode('Description');
  ExplNode := XMLElement.FindNode('Explanation');
  
  if DescNode <> nil then
    Description := ValeurXML(DescNode)
  else
    Description := '';
  
  if ExplNode <> nil then
    Explanation := ValeurXML(ExplNode)
  else
    Explanation := '';

  // Une ethnie sans Description n'est qu'un AJOUT (carrieres, ...) a une race
  // definie dans un autre livre : on reprend le libelle de cette race.
  if Description = '' then
  begin
    if ListRace <> nil then
      for J := 0 to ListRace.Count - 1 do
        if CompareRechercheValeur(ListRace[J].CodeRace, Code) then
        begin
          Description := ListRace[J].Libelle;
          Break;
        end;
    if Description = '' then
      Description := Code;
  end;
  
  // Stocker dans la liste
  RaceData.Code := Code;
  RaceData.Libelle := Description;
  RaceData.Description := Explanation;
  
  New(PRaceData);
  PRaceData^ := RaceData;
  RacesDataList.Add(Code, PRaceData);
  
  // Ajouter dans l'arbre
  NodeRace := TreeViewLivre.Items.AddChild(NodeRaces, RaceData.Libelle);
  SetNodeInfo(NodeRace, NT_RACE, Code);  // 1 = donnée
  
  // V1 : une ethnie n'a aucune sous-branche, tout se lit et se modifie dans sa fiche
  if not EstLivreV1 then
  begin
    // ========== CHARGER LES ATTRIBUTS DE CETTE RACE ==========
    LoadAttributesForRace(XMLElement, NodeRace, Code);

    // ========== CHARGER LES COMPÉTENCES DE CETTE RACE DANS L'ARBRE ==========
    LoadSkillsForRaceTree(XMLElement, NodeRace, Code);

    // ========== CHARGER LES TALENTS DE CETTE RACE DANS L'ARBRE ==========
    LoadTalentsForRaceTree(XMLElement, NodeRace, Code);

    // ========== CHARGER LES CARRIÈRES DE CETTE RACE DANS L'ARBRE ==========
    LoadCareersForRaceTree(XMLElement, NodeRace, Code);

    // ========== CORRUPTION DE CETTE RACE (tranches de tirage) ==========
    LoadCorruptionForRaceTree(NodeRace, Code);
  end;
  Result := NodeRace;
end;

// Noeud d'une carriere racine : sous-branches « races possibles » et « niveaux », puis niveaux.
function TWinLivres.AjouterNoeudCarriere(NodeCareers: TTreeNode; XMLElement: TDOMElement): TTreeNode;
var
  Code, Description: String;
begin
  Code := XMLElement.GetAttribute('id');
  Description := ValeurXML(XMLElement.FindNode('Description'));
  if Description = '' then
    Description := Code;  // fallback
  Result := TreeViewLivre.Items.AddChild(NodeCareers, Description);
  SetNodeInfo(Result, NT_METIER_NIVEAU1, Code);  // 14 = métier racine
  LoadMetierRacesPossibles(Code, Result);
  // Carriere WFRP2 : metiers d'entree et de sortie, un tableau de cases par branche (pas de feuille par metier)
  if XMLElement.FindNode('MainProfile') <> nil then
    begin
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_982', 'Characteristics')), NT_CARAC_CARRIERE, Code);
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_009')), NT_COMPETENCES_CARRIERE, Code);
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_007')), NT_TALENTS_CARRIERE, Code);
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_013')), NT_EQUIPEMENT_CARRIERE, Code);
      // ni entrees ni sorties en V2 non plus : liens du chapitre DATA_CAREER_LINK_V2
    end;
  // Carriere WFRP1 (schema d'avancement) : une branche par bloc, comme en WFRP2
  if XMLElement.FindNode('AdvanceScheme') <> nil then
    begin
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_982', 'Characteristics')), NT_CARAC_CARRIERE, Code);
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_009')), NT_COMPETENCES_CARRIERE, Code);
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_013')), NT_EQUIPEMENT_CARRIERE, Code);
      // ni entrees ni sorties en V1 : ce sont les liens du chapitre DATA_CAREER_LINK_V1 (WinMetier les lit dans les deux sens)
    end;
  // Carriere WFRP2 (profil texte, pas d'echelons) : ni noeud ni niveaux (CONTEXT.md 2.122)
  if (XMLElement.FindNode('MainProfile') = nil) and (XMLElement.FindNode('AdvanceScheme') = nil) then
    begin
      SetNodeInfo(TreeViewLivre.Items.AddChild(Result, GetTexteLibelle('RULES-LAB_369')), 56, Code);  // 56 = niveaux (edition)
      LoadMetierNiveaux(XMLElement, Code, Result);
    end;
end;

// Les 8 classes du Rulebook, puis celles que d'autres carrieres du livre declarent, puis la classe actuelle.
procedure TWinLivres.RemplirCodesClasse(Codes: TStrings; ClasseActuelle: String);
var
  Elements: TDOMNodeList;
  I: Integer;
  C: String;
begin
  Codes.Clear;
  for I := 0 to High(ClassesCarriere) do
    Codes.Add(ClassesCarriere[I]);
  Elements := XMLDoc.GetElementsByTagName('Career');
  for I := 0 to Elements.Count - 1 do
  begin
    C := ValeurXML(TDOMElement(Elements.Item[I]).FindNode('Class'));
    if (C <> '') and (Codes.IndexOf(C) < 0) then
      Codes.Add(C);
  end;
  if (ClasseActuelle <> '') and (Codes.IndexOf(ClasseActuelle) < 0) then
    Codes.Add(ClasseActuelle);
end;

// Boite « Nouvelle carriere » : nom et classe (les deux obligatoires).
function TWinLivres.DemanderNouvelleCarriere(out Lib, Classe: String): Boolean;
var
  F: TForm;
  EditNom: TEdit;
  Combo: TComboBox;
  Codes: TStringList;
  I: Integer;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
begin
  Result := False;
  Lib := '';
  Classe := '';
  Codes := TStringList.Create;
  F := TForm.CreateNew(Self);
  try
    F.Caption := GetTexteLibelle('RULES-LAB_383');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 140;

    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_384');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);

    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 62, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_385');
    Combo := TComboBox.Create(F);
    Combo.Parent := F;
    Combo.SetBounds(12, 80, 356, 24);
    Combo.Style := csDropDownList;
    RemplirCodesClasse(Codes, '');
    for I := 0 to Codes.Count - 1 do
      Combo.Items.Add(GetTexteLibelle(Codes[I]));
    // V2 : une carriere n'a pas de classe (SCHEMA_WFRP2.xsd), le choix n'est pas propose
    if EstLivreV2 then
    begin
      Lbl.Visible := False;
      Combo.Visible := False;
    end;

    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, 104, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, 104, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;

    while F.ShowModal = mrOk do
    begin
      if (Trim(EditNom.Text) = '') or (not EstLivreV2 and (Combo.ItemIndex < 0)) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_386'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      if Combo.ItemIndex >= 0 then Classe := Codes[Combo.ItemIndex];
      Result := True;
      Break;
    end;
  finally
    F.Free;
    Codes.Free;
  end;
end;

// Code a nom "<CODE_BOOK>-WORK_NOM" (libelle en majuscules, ponctuation -> _) ; un chiffre en suffixe
// departage deux carrieres de meme nom dans le livre.
function TWinLivres.CodeNouvelleCarriere(const Lib: String): String;
var
  Livre: TDOMNode;
  Prefixe, Mot: String;
  I, N: Integer;
begin
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK')) + '-WORK_';
  Mot := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Mot := Mot + UpCase(Lib[I])
    else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
      Mot := Mot + '_';
  while (Mot <> '') and (Mot[Length(Mot)] = '_') do
    Delete(Mot, Length(Mot), 1);
  if Mot = '' then Mot := 'NEW';
  N := 1;
  Result := Prefixe + Mot;
  while TrouverCareerElement(Result) <> nil do
  begin
    Inc(N);
    Result := Prefixe + Mot + IntToStr(N);
  end;
end;

// Cree le squelette d'une carriere en memoire (XMLDoc), l'ajoute a l'arbre et la selectionne ;
// les ecrans d'edition existants la completent. Rien n'est ecrit sur disque ici.
procedure TWinLivres.CreerCarriere;
var
  Lib, Classe, Code, Langue, NomChapitre: String;
  Livre, Chapitre: TDOMNode;
  Carriere, Niveau: TDOMElement;
  NodeCareers, NodeNouveau: TTreeNode;
  I: Integer;

  function Ajouter(Parent: TDOMElement; const Nom: String; const Valeur: String = '';
    AvecValeur: Boolean = False; AvecLangue: Boolean = False): TDOMElement;
  begin
    Result := XMLDoc.CreateElement(Nom);
    if AvecLangue then
      Result.SetAttribute('language', Langue);
    Parent.AppendChild(Result);
    if AvecValeur then
      EcrireValeurXML(Result, Valeur);
  end;

begin
  NodeCareers := NoeudCarrieres(TreeViewLivre.Selected);
  if (NodeCareers = nil) or (XMLDoc = nil) or not CreationPermise then Exit;
  if not ConfirmerAbandonModifs then Exit;
  if not DemanderNouvelleCarriere(Lib, Classe) then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Code := CodeNouvelleCarriere(Lib);

  // V1 : SCHEMA_WFRP1.xsd ne connait que DATA_CAREER_V1
  if EstLivreV1 then NomChapitre := 'DATA_CAREER_V1' else NomChapitre := 'DATA_CAREER';
  Chapitre := XMLDoc.GetElementsByTagName(NomChapitre).Item[0];
  if Chapitre = nil then
    Chapitre := Ajouter(TDOMElement(Livre), NomChapitre);

  Carriere := Ajouter(TDOMElement(Chapitre), 'Career');
  Carriere.SetAttribute('id', Code);
  Ajouter(Carriere, 'Description', Lib, True, True);
  Ajouter(Carriere, 'Explanation', '', True, True);
  if EstLivreV2 then
  begin
    // V2 : profils en texte, listes en texte et en codes, pas de niveaux ni de classe (SCHEMA_WFRP2.xsd) ;
    // Advances est facultatif et vide interdit : la fiche l'ecrit des qu'une ligne est saisie
    Ajouter(Carriere, 'MainProfile', '-', True);
    Ajouter(Carriere, 'SecondaryProfile', '-', True);
    Ajouter(Carriere, 'Skills', '', True);
    Ajouter(Carriere, 'Talents', '', True);
    Ajouter(Carriere, 'Trappings', '', True);
    Ajouter(Carriere, 'SUBCHAPTER_ITEM');
    Ajouter(Carriere, 'SUBCHAPTER_SKILL');
    Ajouter(Carriere, 'SUBCHAPTER_TALENT');
    Ajouter(Carriere, 'Entries', '', True);
    Ajouter(Carriere, 'Exits', '', True);
    Ajouter(Carriere, 'Page', '', True);
  end
  else
  begin
  Ajouter(Carriere, 'Class', Classe, True);
  if SameText(ValeurXML(Livre.FindNode(ConstXmlVersionLivre)), 'WFRP1') then
  begin
    // V1 : une carriere = un echelon, schema d'avancement et competences (comme « Alchemist, level 1 »)
    Ajouter(Carriere, 'Level', '1', True);
    Ajouter(Carriere, 'EntryCost', '', True);
    Ajouter(Carriere, 'AdvanceScheme');
    Ajouter(Carriere, 'Skills', '', True);
    Ajouter(Carriere, 'SUBCHAPTER_SKILL');
    Ajouter(Carriere, 'Trappings', '', True);
    // pas de <Exits> en V1 (SCHEMA_WFRP1.xsd) : les liens sont dans DATA_CAREER_LINK_V1
    Ajouter(Carriere, 'Page', '', True);
  end
  else
  begin
    Niveau := Ajouter(Ajouter(Carriere, 'SUBCHAPTER_LEVEL'), 'Level');
    Niveau.SetAttribute('id', '1');
    Ajouter(Niveau, 'Description', Lib, True, True);
    Ajouter(Niveau, 'Salary', 'TIERS_BRASS 1', True);
    // les dix caracteristiques a 0 (jamais de niveau) : l'ecran d'edition ne reecrit que les lignes existantes
    Chapitre := Ajouter(Carriere, 'SUBCHAPTER_ATTR');
    for I := 0 to High(AttributsCarriere) do
      Ajouter(TDOMElement(Chapitre), 'Attribut', '0', True).SetAttribute('name', 'RULES-ATTR_' + AttributsCarriere[I]);
    Ajouter(Carriere, 'SUBCHAPTER_SKILL');
    Ajouter(Carriere, 'SUBCHAPTER_TALENT');
    Ajouter(Carriere, 'SUBCHAPTER_ITEM');
    // comme les 191 carrieres du Rulebook V4 : numero de page, vide a la creation
    Ajouter(Carriere, 'Page', '', True);
  end;
  end;

  NodeNouveau := AjouterNoeudCarriere(NodeCareers, Carriere);
  NodeCareers.AlphaSort;
  NodeCareers.Expand(False);
  TreeViewLivre.Selected := NodeNouveau;
end;

// Branche « Races » (ethnies) si le noeud est cette branche ou l'une de ses ethnies, sinon nil.
function TWinLivres.NoeudEthnies(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_RACE) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Level = 1) and (Node.Text = GetTexteLibelle('RULES-LAB_042')) then
    Result := Node;
end;

// Boite « Nouvelle ethnie » : nom et race parente (les deux obligatoires).
function TWinLivres.DemanderNouvelleEthnie(out Lib, Espece: String): Boolean;
var
  F: TForm;
  EditNom: TEdit;
  Combo: TComboBox;
  Codes: TStringList;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
begin
  Result := False;
  Lib := '';
  Espece := '';
  Codes := TStringList.Create;
  F := TForm.CreateNew(Self);
  try
    F.Caption := GetTexteLibelle('RULES-LAB_388');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 140;

    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_389');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);

    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 62, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_390');
    Combo := TComboBox.Create(F);
    Combo.Parent := F;
    Combo.SetBounds(12, 80, 356, 24);
    Combo.Style := csDropDownList;
    RemplirCodesRaces(Codes, Combo.Items);

    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, 104, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, 104, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;

    while F.ShowModal = mrOk do
    begin
      if (Trim(EditNom.Text) = '') or (Combo.ItemIndex < 0) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_391'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      Espece := Codes[Combo.ItemIndex];
      Result := True;
      Break;
    end;
  finally
    F.Free;
    Codes.Free;
  end;
end;

// Code libre "<CODE_BOOK>-RACE_<MOT>" : le MOT vient du libelle (lettres A-Z, 5 au plus) ;
// un numero lui est ajoute si le code existe deja.
function TWinLivres.CodeNouvelleEthnie(Lib: String): String;
var
  Livre: TDOMNode;
  Prefixe, Mot, Base: String;
  I, N: Integer;
begin
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK')) + '-RACE_';
  Mot := '';
  Lib := UpperCase(Lib);
  for I := 1 to Length(Lib) do
    if (Lib[I] in ['A'..'Z']) and (Length(Mot) < 5) then
      Mot := Mot + Lib[I];
  if Mot = '' then Mot := 'NEW';
  Base := Prefixe + Mot;
  Result := Base;
  N := 1;
  while TrouverElementParId('Specie', Result) <> nil do
  begin
    Inc(N);
    Result := Base + IntToStr(N);
  end;
end;

// Cree le squelette d'une ethnie en memoire (XMLDoc), l'ajoute a l'arbre et la selectionne ;
// les ecrans d'edition existants la completent. Rien n'est ecrit sur disque ici.
procedure TWinLivres.CreerEthnie;
const
  CodesAttr: array[0..14] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel',
    'Fate', 'Resil', 'Wound', 'Supp', 'Move');
  ValeursAttr: array[0..14] of String = ('2d10+20', '2d10+20', '2d10+20', '2d10+20', '2d10+20',
    '2d10+20', '2d10+20', '2d10+20', '2d10+20', '2d10+20', '0', '0', '1xBATTR_S+2xBATTR_T+1xBATTR_WP', '2', '4');
var
  Lib, Espece, Code, Langue: String;
  Livre, Chapitre: TDOMNode;
  Ethnie: TDOMElement;
  NodeRaces, NodeNouveau: TTreeNode;
  I: Integer;
  Version: String;
  Codes, Valeurs: TStringList;

  function Ajouter(Parent: TDOMElement; const Nom: String; const Valeur: String = '';
    AvecValeur: Boolean = False; AvecLangue: Boolean = False): TDOMElement;
  begin
    Result := XMLDoc.CreateElement(Nom);
    if AvecLangue then
      Result.SetAttribute('language', Langue);
    Parent.AppendChild(Result);
    if AvecValeur then
      EcrireValeurXML(Result, Valeur);
  end;

  procedure AjouterAttr(const Code, Valeur: String);
  begin
    Codes.Add(Code);
    Valeurs.Add(Valeur);
  end;

begin
  NodeRaces := NoeudEthnies(TreeViewLivre.Selected);
  if (NodeRaces = nil) or (XMLDoc = nil) or not CreationPermise then Exit;
  if not ConfirmerAbandonModifs then Exit;
  if not DemanderNouvelleEthnie(Lib, Espece) then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Code := CodeNouvelleEthnie(Lib);

  Chapitre := XMLDoc.GetElementsByTagName('DATA_SPECIE').Item[0];
  if Chapitre = nil then
    Chapitre := Ajouter(TDOMElement(Livre), 'DATA_SPECIE');

  Ethnie := Ajouter(TDOMElement(Chapitre), 'Specie');
  Ethnie.SetAttribute('id', Code);
  Ajouter(Ethnie, 'Description', Lib, True, True);
  Ajouter(Ethnie, 'Explanation', '', True, True);
  Ajouter(Ethnie, 'Ethnic', Espece, True);
  Version := UpperCase(ValeurXML(Livre.FindNode(ConstXmlVersionLivre)));
  // les attributs a des valeurs neutres, avec les codes de la version du livre :
  // l'ecran d'edition ne reecrit que les lignes existantes
  Codes := TStringList.Create;
  Valeurs := TStringList.Create;
  try
    if Version = 'WFRP1' then
    begin
      // V1 : Rule / Wounds / FatePoints au niveau de l'ethnie, 14 caracteristiques a codes V1
      Ajouter(Ethnie, 'Rule', '', True);
      Ajouter(Ethnie, 'Wounds', '1d3+4', True);
      Ajouter(Ethnie, 'FatePoints', '1d3+1', True);
      AjouterAttr('M', '4'); AjouterAttr('WS', '2d10+20'); AjouterAttr('BS', '2d10+20');
      AjouterAttr('S', '1d3+1'); AjouterAttr('T', '1d3+1'); AjouterAttr('W', '1d3+4');
      AjouterAttr('I', '2d10+20'); AjouterAttr('A', '1'); AjouterAttr('Dex', '2d10+20');
      AjouterAttr('Ld', '2d10+20'); AjouterAttr('Int', '2d10+20'); AjouterAttr('Cl', '2d10+20');
      AjouterAttr('WP', '2d10+20'); AjouterAttr('Fel', '2d10+20');
    end
    else if Version = 'WFRP2' then
    begin
      // V2 : W et FP = tables de d10 par plage
      AjouterAttr('WS', '2d10+20'); AjouterAttr('BS', '2d10+20'); AjouterAttr('S', '2d10+20');
      AjouterAttr('T', '2d10+20'); AjouterAttr('Ag', '2d10+20'); AjouterAttr('Int', '2d10+20');
      AjouterAttr('WP', '2d10+20'); AjouterAttr('Fel', '2d10+20'); AjouterAttr('A', '1');
      AjouterAttr('M', '4'); AjouterAttr('Mag', '0'); AjouterAttr('IP', '0');
      AjouterAttr('W', '1-3: 11; 4-6: 12; 7-9: 13; 10: 14');
      AjouterAttr('FP', '1-4: 1; 5-7: 2; 8-10: 3');
    end
    else
      for I := 0 to High(CodesAttr) do
        AjouterAttr(CodesAttr[I], ValeursAttr[I]);
    Chapitre := Ajouter(Ethnie, 'SUBCHAPTER_ATTR');
    for I := 0 to Codes.Count - 1 do
      Ajouter(TDOMElement(Chapitre), 'Attribut', Valeurs[I], True).SetAttribute('name', 'RULES-ATTR_' + Codes[I]);
  finally
    Codes.Free;
    Valeurs.Free;
  end;
  Ajouter(Ethnie, 'SUBCHAPTER_SKILL');
  // V1 : ni talents ni metiers par ethnie (les carrieres viennent des tirages de carriere)
  if Version <> 'WFRP1' then
  begin
    Ajouter(Ethnie, 'SUBCHAPTER_TALENT');
    Ajouter(Ethnie, 'SUBCHAPTER_CAREER');
  end;
  // Page : derniere balise de la sequence du schema
  Ajouter(Ethnie, 'Page', '', True);

  NodeNouveau := AjouterNoeudEthnie(NodeRaces, Ethnie);
  NodeRaces.AlphaSort;
  NodeRaces.Expand(False);
  TreeViewLivre.Selected := NodeNouveau;
end;

// Branche « Races » (regroupements DATA_RACE) si le noeud est cette branche ou l'une de ses races, sinon nil.
function TWinLivres.NoeudRacesGroupes(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_RACE_GROUPE) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Level = 1) and (Node.Text = GetTexteLibelle('RULES-LAB_397')) then
    Result := Node;
end;

function TWinLivres.AjouterNoeudRaceGroupe(Branche: TTreeNode; Race: TDOMElement): TTreeNode;
var
  Code, Lib: String;
begin
  Code := Race.GetAttribute('id');
  Lib := ValeurXML(Race.FindNode('Description'));
  if Lib = '' then
    Lib := GetTexteLibelle(Code);  // le libelle d'une race du Rulebook peut n'etre que dans l'interface
  Result := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Result, NT_RACE_GROUPE, Code);  // 57 = race (DATA_RACE)
end;

// Formulaire d'une race : code en lecture seule, libelle modifiable (Valider / Annuler du formulaire).
procedure TWinLivres.AfficherRaceGroupe(ACode: String);
var
  Race: TDOMElement;
  CodesRaces, LibRaces: TStringList;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Race := TrouverElementParId('Race', ACode);
  if Race = nil then Exit;
  if FicheGeneriqueV1Possible(Race) then
  begin
    AfficherFicheGeneriqueV1(Race, 'Race', NT_RACE_GROUPE, ACode);
    Exit;
  end;
  FicheTag := 'Race';
  FicheTypeNoeud := NT_RACE_GROUPE;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  PanelFiche.MasquerGrille;  // un groupe de races ne porte aucun modificateur
  CodesRaces := TStringList.Create;
  LibRaces := TStringList.Create;
  try
    RemplirCodesRaces(CodesRaces, LibRaces);
    PanelRaceExtra.Configurer(CodesRaces, LibRaces);
  finally
    CodesRaces.Free;
    LibRaces.Free;
  end;
  PanelFiche.Extra := PanelRaceExtra;
  PanelFiche.Charger(Race);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  CodeDonneeSelectionnee := ACode;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Races proposees a une ethnie : celles deja chargees (ListEspece) puis celles de DATA_RACE du livre ouvert
// (une race creee dans cette session n'est pas encore dans ListEspece).
procedure TWinLivres.RemplirCodesRaces(Codes, Libelles: TStrings);
var
  Elements: TDOMNodeList;
  I: Integer;
  Id: String;
begin
  Codes.Clear;
  Libelles.Clear;
  if ListEspece <> nil then
    for I := 0 to ListEspece.Count - 1 do
    begin
      Codes.Add(ListEspece[I].CodeEspece);
      Libelles.Add(ListEspece[I].Libelle);
    end;
  Elements := XMLDoc.GetElementsByTagName('Race');
  for I := 0 to Elements.Count - 1 do
  begin
    Id := TDOMElement(Elements.Item[I]).GetAttribute('id');
    if (Id <> '') and (Codes.IndexOf(Id) < 0) then
    begin
      Codes.Add(Id);
      Libelles.Add(ValeurXML(TDOMElement(Elements.Item[I]).FindNode('Description')));
    end;
  end;
end;

// Cree une race (bloc DATA_RACE, un <Race id> avec sa seule <Description>, comme le Rulebook).
// Elle n'a pas de noeud dans l'arbre : on la choisit dans la boite « Nouvelle ethnie ».
procedure TWinLivres.CreerRace;
var
  Lib, Mot, Prefixe, Code, Langue: String;
  Livre, Chapitre: TDOMNode;
  Race, Desc: TDOMElement;
  Elements: TDOMNodeList;
  I, N: Integer;
  Existe: Boolean;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  if NoeudRacesGroupes(TreeViewLivre.Selected) = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  repeat
    if not InputQuery(GetTexteLibelle('RULES-LAB_393'), GetTexteLibelle('RULES-LAB_394'), Lib) then Exit;
    Lib := Trim(Lib);
    if Lib = '' then
      ShowMessage(GetTexteLibelle('RULES-LAB_395'));
  until Lib <> '';

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK')) + '-SPECIE_';
  Mot := '';
  for I := 1 to Length(Lib) do
    if (UpCase(Lib[I]) in ['A'..'Z']) and (Length(Mot) < 8) then
      Mot := Mot + UpCase(Lib[I]);
  if Mot = '' then Mot := 'NEW';
  Code := Prefixe + Mot;
  N := 1;
  repeat
    Existe := False;
    Elements := XMLDoc.GetElementsByTagName('Race');
    for I := 0 to Elements.Count - 1 do
      if TDOMElement(Elements.Item[I]).GetAttribute('id') = Code then
        Existe := True;
    if Existe then
    begin
      Inc(N);
      Code := Prefixe + Mot + IntToStr(N);
    end;
  until not Existe;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_RACE').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_RACE');
    Livre.AppendChild(Chapitre);
  end;
  Race := XMLDoc.CreateElement('Race');
  Race.SetAttribute('id', Code);
  Chapitre.AppendChild(Race);
  Desc := XMLDoc.CreateElement('Description');
  Desc.SetAttribute('language', Langue);
  Race.AppendChild(Desc);
  EcrireValeurXML(Desc, Lib);
  Branche := NoeudRacesGroupes(TreeViewLivre.Selected);
  if Branche <> nil then
  begin
    Noeud := AjouterNoeudRaceGroupe(Branche, Race);
    Branche.AlphaSort;
    Branche.Expand(False);
    TreeViewLivre.Selected := Noeud;
  end;
end;

// Branche « Competences » (ou « Talents ») si le noeud est cette branche ou l'une de ses feuilles, sinon nil.
function TWinLivres.NoeudBrancheSimple(Node: TTreeNode; CodeLibelle: String; TypeFeuille: Integer): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  // on remonte jusqu'a la branche (une feuille peut etre sous un regroupement)
  while (Node.Level > 1) and (Node.Parent <> nil) do
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Level = 1) and (Node.Text = GetTexteLibelle(CodeLibelle)) then
    Result := Node;
end;

// Cree une competence (nom + caracteristique) ou un talent (nom) dans le livre de travail.
// Squelette comme le Rulebook ; le reste (explication, maximum...) se complete ensuite.
procedure TWinLivres.CreerCompetenceOuTalent(EstTalent: Boolean);
var
  Lib, Mot, Prefixe, Code, Langue, NomTag, Chap, Attr, Suffixe: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  I, N, TypeFeuille: Integer;
  Branche, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  Combo: TComboBox;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok, AvecSpec: Boolean;
  CaseSpec: TCheckBox;

  function Existe(C: String): Boolean;
  begin
    Result := TrouverElementParId(NomTag, C) <> nil;
  end;

  procedure Ajouter(Pere: TDOMElement; Nom, Valeur: String; AvecLangue: Boolean);
  var
    E: TDOMElement;
  begin
    E := XMLDoc.CreateElement(Nom);
    if AvecLangue then E.SetAttribute('language', Langue);
    Pere.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  if EstTalent then
  begin
    NomTag := 'Talent'; Chap := 'DATA_TALENT'; TypeFeuille := 28;
    Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_007', 28);
  end
  else
  begin
    NomTag := 'Skill'; Chap := 'DATA_SKILL'; TypeFeuille := 26;
    if EstLivreV1 then begin Chap := 'DATA_SKILL_V1'; TypeFeuille := NT_COMPETENCE_V1; end;
    Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_009', 26);
  end;
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Ok := False;
  AvecSpec := False;
  CaseSpec := nil;
  Attr := '';
  F := TForm.CreateNew(Self);
  try
    if EstTalent then F.Caption := GetTexteLibelle('RULES-LAB_402')
                 else F.Caption := GetTexteLibelle('RULES-LAB_401');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    if EstTalent or EstLivreV1 then F.ClientHeight := 120 else F.ClientHeight := 170;
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);
    Combo := nil;
    if not EstTalent then
    begin
      Lbl := TLabelContour.Create(F);
      Lbl.Parent := F;
      Lbl.SetBounds(12, 62, 356, 18);
      Lbl.Caption := GetTexteLibelle('RULES-LAB_405');
      Combo := TComboBox.Create(F);
      Combo.Parent := F;
      Combo.SetBounds(12, 80, 356, 24);
      Combo.Style := csDropDownList;
      for I := 0 to High(AttributsCarriere) do
        Combo.Items.Add(GetAttributLabel('RULES-ATTR_' + AttributsCarriere[I]));
      CaseSpec := TCheckBox.Create(F);
      CaseSpec.Parent := F;
      CaseSpec.SetBounds(12, 112, 356, 20);
      CaseSpec.Caption := GetTexteLibelle('RULES-LAB_407');
      // V1 : une competence n'a pas de caracteristique de base (SCHEMA_WFRP1.xsd)
      if EstLivreV1 then
      begin
        Lbl.Visible := False;
        Combo.Visible := False;
        Combo.ItemIndex := 0;
        CaseSpec.Top := 62;
      end;
    end;
    if EstTalent then
    begin
      CaseSpec := TCheckBox.Create(F);
      CaseSpec.Parent := F;
      CaseSpec.SetBounds(12, 62, 356, 20);
      CaseSpec.Caption := GetTexteLibelle('RULES-LAB_414');
    end;
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if (Trim(EditNom.Text) = '') or ((Combo <> nil) and (Combo.ItemIndex < 0)) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      if Combo <> nil then Attr := 'RULES-ATTR_' + AttributsCarriere[Combo.ItemIndex];
      if CaseSpec <> nil then AvecSpec := CaseSpec.Checked;
      Ok := True;
      Break;
    end;
  finally
    F.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  if EstTalent then
  begin
    // avec specialites : code "T0012_*" et libelle "(Any)", comme "Bless (Any)" du Rulebook
    if AvecSpec then Suffixe := ValeurSousCompetence + '*' else Suffixe := '';
    N := 1;
    repeat
      Code := Prefixe + '-T' + Format('%.4d', [N]) + Suffixe;
      Inc(N);
    until not Existe(Code);
    if AvecSpec then Lib := Lib + ' (Any)';
  end
  else
  begin
    // nom de la competence en majuscules, mots separes par '_' (RULES-COMP_SLEIGHT_OF_HAND)
    Mot := '';
    for I := 1 to Length(Lib) do
      if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
        Mot := Mot + UpCase(Lib[I])
      else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
        Mot := Mot + '_';
    Mot := Trim(Mot);
    while (Mot <> '') and (Mot[Length(Mot)] = '_') do
      Delete(Mot, Length(Mot), 1);
    if Mot = '' then Mot := 'NEW';
    // avec specialites : code en "__*" et libelle "(Any)", comme "Art (Any)" du Rulebook
    // V1 : la competence a variantes porte <Variants>, son code reste sans « __* » et son libelle sans « (Any) »
    if AvecSpec and not EstLivreV1 then Suffixe := ValeurGeneriqueTalent else Suffixe := '';
    Code := Prefixe + '-COMP_' + Mot + Suffixe;
    N := 1;
    while Existe(Code) do
    begin
      Inc(N);
      Code := Prefixe + '-COMP_' + Mot + IntToStr(N) + Suffixe;
    end;
    if AvecSpec and not EstLivreV1 then Lib := Lib + ' (Any)';
  end;

  Chapitre := XMLDoc.GetElementsByTagName(Chap).Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement(Chap);
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement(NomTag);
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  if not EstTalent and not EstLivreV1 then Ajouter(Elem, 'Attribut', Attr, False);
  Ajouter(Elem, 'Description', Lib, True);
  if EstTalent and EstLivreV2 then
  begin
    // talent V2 : seulement Description / Explanation / Page (Short, Max, PDF et Test sont propres a la V4)
    Ajouter(Elem, 'Explanation', '', True);
    Ajouter(Elem, 'Page', '', True);
  end
  else if EstTalent then
  begin
    Ajouter(Elem, 'Short', '', True);
    Ajouter(Elem, 'Explanation', '', True);
    Ajouter(Elem, 'Max', '1', False);
    Ajouter(Elem, 'PDF', '', False);
    Ajouter(Elem, 'Test', '', True);
  end
  else
  begin
    Ajouter(Elem, 'Explanation', '', True);
    if AvecSpec and EstLivreV1 then Ajouter(Elem, 'Variants', '1', False);
    // competence V2 : RelatedTalents et Page (SkillV2Type)
    if EstLivreV2 then
    begin
      Ajouter(Elem, 'RelatedTalents', '', True);
      Ajouter(Elem, 'Page', '', True);
    end;
  end;

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, TypeFeuille, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

// Cree un element V1 simple (divinite, culte, familier) : nom saisi, id "<livre>-<Infixe>_<NOM>", puis les balises
// obligatoires de SCHEMA_WFRP1.xsd laissees vides (a completer dans la fiche).
// Noeud de groupe (liste d'un sort, categorie d'un objet) V1 : le noeud lui-meme s'il porte des feuilles du type,
// ou le parent d'une de ces feuilles ; nil sinon.
function TWinLivres.NoeudGroupeV1(Node: TTreeNode; TypeFeuille: Integer): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if GetNodeType(Node) = TypeFeuille then
    Node := Node.Parent;
  if (Node <> nil) and (GetNodeType(Node) = NT_CHAPITRE) and (Node.Count > 0) and
     (GetNodeType(Node.GetFirstChild) = TypeFeuille) then
    Result := Node;
end;

procedure TWinLivres.CreerElementV1(Chap, NomTag, Infixe, ChampNom, CodeLibBranche, CodeLibTitre: String;
  TypeFeuille: Integer; const AutresChamps: array of String; GroupeNoeud: TTreeNode);
var
  Lib, Mot, Prefixe, Code, Langue, Attr, Valeur: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  I, N, P: Integer;
  AvecLangue: Boolean;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  if GroupeNoeud <> nil then
    Branche := GroupeNoeud
  else
    Branche := NoeudBrancheSimple(TreeViewLivre.Selected, CodeLibBranche, TypeFeuille);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle(CodeLibTitre), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  // nom en majuscules, mots separes par '_' (RULES-DEITY_THE_OLD_FAITH)
  Mot := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Mot := Mot + UpCase(Lib[I])
    else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
      Mot := Mot + '_';
  while (Mot <> '') and (Mot[Length(Mot)] = '_') do
    Delete(Mot, Length(Mot), 1);
  if Mot = '' then Mot := 'NEW';
  Code := Prefixe + '-' + Infixe + '_' + Mot;
  N := 1;
  while TrouverElementParId(NomTag, Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + '-' + Infixe + '_' + Mot + IntToStr(N);
  end;
  Chapitre := XMLDoc.GetElementsByTagName(Chap).Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement(Chap);
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement(NomTag);
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement(ChampNom);
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, Lib);
  // "*Balise" = texte a langue (LangString) ; "Balise@name=valeur" = balise a attribut name
  for I := Low(AutresChamps) to High(AutresChamps) do
  begin
    Mot := AutresChamps[I];
    Attr := '';
    P := Pos('@name=', Mot);
    if P > 0 then
    begin
      Attr := Copy(Mot, P + 6, MaxInt);
      Mot := Copy(Mot, 1, P - 1);
    end;
    AvecLangue := (Mot <> '') and (Mot[1] = '*');
    if AvecLangue then Delete(Mot, 1, 1);
    // "Balise=#G" : la valeur est celle du groupe (liste du sort, categorie de l'objet)
    Valeur := '';
    if (GroupeNoeud <> nil) and (Length(Mot) > 3) and (Copy(Mot, Length(Mot) - 2, 3) = '=#G') then
    begin
      Mot := Copy(Mot, 1, Length(Mot) - 3);
      Valeur := GroupeNoeud.Text;
    end;
    E := XMLDoc.CreateElement(Mot);
    if AvecLangue then E.SetAttribute('language', Langue);
    if Attr <> '' then E.SetAttribute('name', Attr);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;
  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, TypeFeuille, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleDiviniteClick(Sender: TObject);
begin
  CreerElementV1('DATA_DEITY_V1', 'Deity', 'DEITY', 'Description', 'RULES-LAB_869', 'RULES-LAB_932', NT_DIEU_V1, ['Alignment']);
end;

procedure TWinLivres.MenuNouveauCulteClick(Sender: TObject);
begin
  CreerElementV1('DATA_CULT_V1', 'Cult', 'CULT', 'Description', 'RULES-LAB_870', 'RULES-LAB_933', NT_CULTE_V1, []);
end;

procedure TWinLivres.MenuNouveauSortV1Click(Sender: TObject);
begin
  // le sort va dans la liste choisie (noeud de liste, ou sort de cette liste)
  CreerElementV1('DATA_SPELL_V1', 'SpellV1', 'SPELL', 'Description', '', 'RULES-LAB_937', NT_SORT_V1,
    ['*Explanation', 'SpellList=#G', 'SpellLevel', 'MagicPoints', 'Range', 'Duration', 'Ingredients'],
    NoeudGroupeV1(TreeViewLivre.Selected, NT_SORT_V1));
end;

procedure TWinLivres.MenuNouvelObjetV1Click(Sender: TObject);
begin
  // la fiche propose tous les champs du schema : seule la categorie est creee ici
  CreerElementV1('DATA_EQUIPMENT_V1', 'EquipmentV1', 'EQUIP', 'Description', '', 'RULES-LAB_938', NT_EQUIPEMENT_V1,
    ['Category=#G'], NoeudGroupeV1(TreeViewLivre.Selected, NT_EQUIPEMENT_V1));
end;

procedure TWinLivres.MenuNouvelleClasseClick(Sender: TObject);
begin
  // au moins une exigence de caracteristique (Requirement), a regler ensuite dans le XML
  CreerElementV1('DATA_CLASS_V1', 'Class', 'CLASS', 'Description', 'RULES-LAB_880', 'RULES-LAB_935', NT_CLASSE_V1,
    ['*Explanation', 'Requirement@name=RULES-ATTR_WS', 'Trappings', 'Money']);
end;

procedure TWinLivres.MenuNouveauHandicapClick(Sender: TObject);
begin
  CreerElementV1('DATA_DISABILITY_V1', 'Disability', 'DISABILITY', 'Description', 'RULES-LAB_842', 'RULES-LAB_936', NT_HANDICAP_V1,
    ['*Explanation']);
end;

procedure TWinLivres.MenuNouveauFamilierClick(Sender: TObject);
begin
  CreerElementV1('DATA_FAMILIAR_V1', 'Familiar', 'FAMILIAR', 'Animal', 'RULES-LAB_871', 'RULES-LAB_934', NT_FAMILIER_V1,
    ['Range', 'Skill1', 'Skill2', 'Armour', 'Shield', 'TimesPlaces', 'Diet']);
end;

// Rulebook de l'edition du livre ouvert (meme dossier), lu une fois : sert aux listes de choix
// (groupes d'armes, qualites) car ListCompetence n'est remplie qu'apres un chargement complet des livres.
function TWinLivres.RulebookXML: TXMLDocument;
var
  Fichier: String;
  Textes: TDOMNodeList;
  I: Integer;
begin
  // un livre d'une autre edition (autre dossier) a ete ouvert : les Rulebooks gardes ne sont plus les bons
  if RulebookDossier <> ExtractFilePath(CurrentFilePath) then
  begin
    RulebookDossier := ExtractFilePath(CurrentFilePath);
    RulebookDoc.Free;
    RulebookDoc := nil;
    RulebookBaseDoc.Free;
    RulebookBaseDoc := nil;
    RulebookEssaye := False;
  end;
  // la langue des livres peut changer en cours de session : le Rulebook suit
  if RulebookEssaye and (RulebookLangue <> ValLangue) then
  begin
    RulebookDoc.Free;
    RulebookDoc := nil;
    RulebookEssaye := False;
  end;
  if (RulebookDoc = nil) and not RulebookEssaye then
  begin
    RulebookEssaye := True;
    RulebookLangue := ValLangue;
    if RulebookTextes = nil then RulebookTextes := TStringList.Create;
    RulebookTextes.Clear;
    Fichier := ExtractFilePath(CurrentFilePath) + 'BOOK_RULESBOOK_' + ValLangue + '.Xml';
    if (ValLangue = ConstAnglais) or not FileExists(Fichier) then
      Fichier := ExtractFilePath(CurrentFilePath) + 'BOOK_RULESBOOK.Xml';
    if FileExists(Fichier) then
    try
      ReadXMLFile(RulebookDoc, Fichier);
      Textes := RulebookDoc.GetElementsByTagName('Text');
      for I := 0 to Textes.Count - 1 do
        RulebookTextes.Add(RemoveQuotes(TDOMElement(Textes.Item[I]).GetAttribute('name')) + '=' + ValeurXML(Textes.Item[I]));
    except
      RulebookDoc := nil;  // Rulebook illisible : seules les donnees du livre ouvert sont proposees
    end;
  end;
  Result := RulebookDoc;
end;

// Le Rulebook anglais complet, lu une fois : en langue de livres non anglaise RulebookXML est le fichier de langue,
// qui n'a ni TypSpell (benedictions) ni lignes de DATA_SPELL_TALENT.
function TWinLivres.RulebookBaseXML: TXMLDocument;
var
  Fichier: String;
begin
  if ValLangue = ConstAnglais then Exit(RulebookXML);
  RulebookXML;  // verifie le dossier et vide les deux caches si le livre ouvert a change d'edition
  if RulebookBaseDoc = nil then
  begin
    Fichier := ExtractFilePath(CurrentFilePath) + 'BOOK_RULESBOOK.Xml';
    if FileExists(Fichier) then
    try
      ReadXMLFile(RulebookBaseDoc, Fichier);
    except
      RulebookBaseDoc := nil;
    end;
  end;
  Result := RulebookBaseDoc;
end;

// Libelle d'un code a afficher : celui du Rulebook dans la langue des livres s'il existe,
// sinon le libelle charge ; un code inconnu reste tel quel.
function TWinLivres.LibelleAffiche(const Code: String): String;
begin
  Result := '';
  if (ValLangue <> ConstAnglais) and (RulebookXML <> nil) then
    Result := RulebookTextes.Values[Code];
  if Result = '' then
    Result := GetTexteLibelle(Code);
end;

// Libelle d'une qualite (<BonusMalus>) du Rulebook dans la langue des livres, '' si inconnue.
function TWinLivres.LibelleBonusMalusRulebook(const Code: String): String;
var
  Elements: TDOMNodeList;
  I: Integer;
begin
  Result := '';
  if RulebookXML = nil then Exit;
  Elements := RulebookXML.GetElementsByTagName('BonusMalus');
  for I := 0 to Elements.Count - 1 do
    if RemoveQuotes(TDOMElement(Elements.Item[I]).GetAttribute('id')) = Code then
    begin
      Result := ValeurXML(Elements.Item[I].FindNode('Description'));
      Exit;
    end;
end;

// Groupes d'armes proposes : competences de combat ou de tir (hors "(Any)" et choix "A/B"),
// "libelle" + #1 + "code", du Rulebook et du livre ouvert.
procedure TWinLivres.RemplirGroupesArmes(Tri: TStringList);

  procedure Proposer(const CodeSkill, Libelle: String);
  var
    K: Integer;
  begin
    for K := 0 to Tri.Count - 1 do  // un code deja propose garde son premier libelle
      if Copy(Tri[K], Pos(#1, Tri[K]) + 1, Length(Tri[K])) = CodeSkill then Exit;
    if (Pos('-COMP_MELEE__', CodeSkill) = 0) and (Pos('-COMP_RANGED__', CodeSkill) = 0) then Exit;
    if Copy(CodeSkill, Length(CodeSkill), 1) = '*' then Exit;
    if Pos('/', CodeSkill) > 0 then Exit;
    Tri.Add(Libelle + #1 + CodeSkill);
  end;

  procedure Parcourir(Doc: TXMLDocument);
  var
    Elements: TDOMNodeList;
    I: Integer;
    Id, Lib: String;
  begin
    Elements := Doc.GetElementsByTagName('Skill');
    for I := 0 to Elements.Count - 1 do
    begin
      Id := RemoveQuotes(TDOMElement(Elements.Item[I]).GetAttribute('id'));
      if Id = '' then Continue;
      Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
      if Lib = '' then Lib := GetTexteLibelle(Id);
      if Lib = '' then Lib := Id;
      Proposer(Id, Lib);
    end;
  end;

var
  I: Integer;
begin
  Tri.Sorted := True;
  Tri.Duplicates := dupIgnore;
  if ListCompetence <> nil then
    for I := 0 to ListCompetence.Count - 1 do
      if not ListCompetence[I].SousCompetence then
        Proposer(ListCompetence[I].CodeCompetence, ListCompetence[I].Libelle);
  if XMLDoc <> nil then Parcourir(XMLDoc);
  if RulebookXML <> nil then Parcourir(RulebookXML);
end;

// Qualites d'arme proposees : <BonusMalus> "WEAPB" du livre ouvert et du Rulebook, triees par libelle.
// Un libelle en double (meme nom dans deux livres) est suivi de son code pour rester distinct.
procedure TWinLivres.RemplirQualitesArme(const Marqueur: String);
var
  Tri: TStringList;
  I: Integer;
  Lib, Code: String;

  procedure Parcourir(Doc: TXMLDocument);
  var
    Elements: TDOMNodeList;
    J: Integer;
    Id, L: String;
  begin
    Elements := Doc.GetElementsByTagName('BonusMalus');
    for J := 0 to Elements.Count - 1 do
    begin
      Id := RemoveQuotes(TDOMElement(Elements.Item[J]).GetAttribute('id'));
      if Pos(Marqueur, Id) = 0 then Continue;
      if Pos('/', Id) > 0 then Continue;  // qualite alternative declaree (Hack or Trip) : la colonne Or de la grille la remplace
      L := ValeurXML(Elements.Item[J].FindNode('Description'));
      if L = '' then L := GetTexteLibelle(Id);
      Tri.Add(L + #1 + Id);
      if (ValeurXML(Elements.Item[J].FindNode('NeedsValue')) = '1') and (QualCodesAvecValeur.IndexOf(Id) < 0) then
        QualCodesAvecValeur.Add(Id);
    end;
  end;

begin
  QualLibelles.Clear;
  QualCodes.Clear;
  QualCodesAvecValeur.Clear;
  Tri := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupIgnore;
    if XMLDoc <> nil then Parcourir(XMLDoc);
    if RulebookXML <> nil then Parcourir(RulebookXML);
    for I := 0 to Tri.Count - 1 do
    begin
      Lib := Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
      Code := Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I]));
      if QualLibelles.IndexOf(Lib) >= 0 then Lib := Lib + ' (' + Code + ')';
      QualLibelles.Add(Lib);
      QualCodes.Add(Code);
    end;
  finally
    Tri.Free;
  end;
end;

// Libelle affiche pour un code de qualite ; un code inconnu reste tel quel.
function TWinLivres.LibelleQualiteArme(const Code: String): String;
var
  I: Integer;
begin
  I := QualCodes.IndexOf(Code);
  if I >= 0 then Result := QualLibelles[I] else Result := Code;
end;

// Code ecrit pour un libelle choisi ; une saisie qui n'est pas dans la liste est gardee telle quelle.
function TWinLivres.CodeQualiteArme(const Lib: String): String;
var
  I: Integer;
begin
  I := QualLibelles.IndexOf(Lib);
  if I >= 0 then Result := QualCodes[I] else Result := Lib;
end;

// Entier positif ou nul (Mains, Munitions, Encombrement) : meme controle que la fiche generique.
function EntierPositif(const S: String): Boolean;
begin
  Result := EntierPositifFiche(S);
end;

// Prix : vide, "-", ou une suite "nombre + monnaie en lettres majuscules" (5CO, 12PA, 1CO5PA).
function PrixValide(const S: String): Boolean;
begin
  Result := PrixValideFiche(S);
end;

// Branche « Armures » si le noeud est cette branche ou l'une de ses armures, sinon nil.
function TWinLivres.NoeudArmures(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_ARMURE) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Text = GetTexteLibelle('RULES-LAB_065')) then
    Result := Node;
end;

const
  // materiaux et emplacements proposes ; un code sans libelle n'appartient pas a l'edition chargee
  MateriauxArmure: array[0..6] of String = ('RULES-ARMOT_SOFTLEATHER', 'RULES-ARMOT_LEATHER', 'RULES-ARMOT_BOILLEDLEATHER',
    'RULES-ARMOT_MAIL', 'RULES-ARMOT_PLATE', 'RULES-ARMOT_SOFTKITS', 'RULES-ARMOT_BRIGANDINE');
  EmplacementsArmure: array[0..3] of String = ('RULES-ARMOL_HEAD', 'RULES-ARMOL_BODY', 'RULES-ARMOL_ARM', 'RULES-ARMOL_LEG');

// Cree une armure : nom seul ; le code suit la convention des livres <LIVRE>-ARMO_NOM. Squelette : corps, 1 point,
// premier materiau de l'edition, Common ; le reste se saisit ensuite dans la fiche.
procedure TWinLivres.CreerArmure;
var
  Lib, Code, Prefixe, Langue, Materiau, Mot: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  I, N: Integer;
  Branche, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok: Boolean;

  procedure Ajouter(Nom, Valeur: String; AvecLangue: Boolean);
  var
    E: TDOMElement;
  begin

    E := XMLDoc.CreateElement(Nom);
    if AvecLangue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudArmures(TreeViewLivre.Selected);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Ok := False;
  F := TForm.CreateNew(Self);
  try
    F.Caption := GetTexteLibelle('RULES-LAB_442');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 120;
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if Trim(EditNom.Text) = '' then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      Ok := True;
      Break;
    end;
  finally
    F.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  // nom de l'armure en majuscules, mots separes par '_' (RULES-ARMO_LEATHER_SKULLCAP)
  Mot := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Mot := Mot + UpCase(Lib[I])
    else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
      Mot := Mot + '_';
  while (Mot <> '') and (Mot[Length(Mot)] = '_') do
    Delete(Mot, Length(Mot), 1);
  if Mot = '' then Mot := 'NEW';
  Code := Prefixe + '-ARMO_' + Mot;
  N := 1;
  while TrouverElementParId('Armor', Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + '-ARMO_' + Mot + IntToStr(N);
  end;
  Materiau := '';
  for I := Low(MateriauxArmure) to High(MateriauxArmure) do
    if GetTexteLibelle(MateriauxArmure[I]) <> MateriauxArmure[I] then
    begin
      Materiau := MateriauxArmure[I];
      Break;
    end;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_ARMOR').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_ARMOR');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Armor');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', Lib, True);
  Ajouter('Availability', 'RULES-DISPO_COMMON', False);
  Ajouter('Encumbrance', '0', False);
  Ajouter('Quality', '-', False);
  Ajouter('Location', 'RULES-ARMOL_BODY', False);
  Ajouter('ArmorPoint', '1', False);
  if Materiau <> '' then Ajouter('Type', Materiau, False);

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_ARMURE, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

const
  // types de sort : valeur ecrite dans <TypSpell> (anglais, comme les livres) / libelle affiche
  TypesSortXml: array[0..6] of String = ('Minor Magic', 'Arcane Magic', 'Domain Magic', 'Chaos Magic', 'Blessing', 'Miracle', 'Ritual');
  TypesSortLib: array[0..6] of String = ('RULES-LAB_068', 'RULES-LAB_069', 'RULES-LAB_070', 'RULES-LAB_071', 'RULES-LAB_066', 'RULES-LAB_067', 'RULES-LAB_453');

// Branche « Sorts » si le noeud est cette branche ou l'un de ses sorts, sinon nil.
function TWinLivres.NoeudSorts(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_SORT) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Text = GetTexteLibelle('RULES-LAB_083')) then
    Result := Node;
end;

// Nom en majuscules pour un code a nom : lettres et chiffres, le reste devient un seul '_' (Dazzle -> DAZZLE).
function NomEnMajuscules(const Lib: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Result := Result + UpCase(Lib[I])
    else if (Result <> '') and (Result[Length(Result)] <> '_') then
      Result := Result + '_';
  while (Result <> '') and (Result[Length(Result)] = '_') do
    Delete(Result, Length(Result), 1);
  if Result = '' then Result := 'NEW';
end;

// Cree un sort : nom + type (balise <TypSpell>, valeur en anglais comme dans les livres). Code <LIVRE>-SPELL_NOM.
// Squelette : cible 1, duree Instantane, portee Contact, niveau 0 ; le reste se saisit ensuite.
procedure TWinLivres.CreerSort;
var
  Lib, Code, Prefixe, Langue, TypeSort: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  I, N: Integer;
  Branche, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  Combo: TComboBox;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok: Boolean;

  procedure Ajouter(Nom, Valeur: String; AvecLangue: Boolean);
  var
    E: TDOMElement;
  begin
    E := XMLDoc.CreateElement(Nom);
    if AvecLangue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudSorts(TreeViewLivre.Selected);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Ok := False;
  TypeSort := '';
  F := TForm.CreateNew(Self);
  try
    F.Caption := GetTexteLibelle('RULES-LAB_452');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 170;
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 62, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_116');
    Combo := TComboBox.Create(F);
    Combo.Parent := F;
    Combo.SetBounds(12, 80, 356, 24);
    Combo.Style := csDropDownList;
    for I := Low(TypesSortXml) to High(TypesSortXml) do
      Combo.Items.Add(GetTexteLibelle(TypesSortLib[I]));
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if (Trim(EditNom.Text) = '') or (Combo.ItemIndex < 0) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      TypeSort := TypesSortXml[Combo.ItemIndex];
      Ok := True;
      Break;
    end;
  finally
    F.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  Code := Prefixe + '-SPELL_' + NomEnMajuscules(Lib);
  while TrouverElementParId('Sort', Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + '-SPELL_' + NomEnMajuscules(Lib) + '_' + IntToStr(N);
  end;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_SPELL').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_SPELL');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Sort');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', Lib, True);
  Ajouter('Target', '1', False);
  Ajouter('Duration', GetTexteLibelle('RULES-LAB_430'), False);
  Ajouter('Range', GetTexteLibelle('RULES-LAB_432'), False);
  // talent d'acces : sans lui le sort est injoignable. Un seul talent possible pour ce type -> pose d'office
  // ; sinon vide, a choisir sur la fiche (une benediction aussi : les dieux, RULES-T0012_*).
  RemplirTalentsSort(TypeSort);
  if TalSortCodes.Count = 1 then
    Ajouter('Talent', TalSortCodes[0], False)
  else
    Ajouter('Talent', '', False);
  Ajouter('Level', '0', False);
  Ajouter('TypSpell', TypeSort, False);

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_SORT, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouveauSortClick(Sender: TObject);
begin
  CreerSort;
end;

procedure TWinLivres.MenuNouvelleArmureClick(Sender: TObject);
begin
  CreerArmure;
end;


// Branche « Qualite d'arme » ou « Qualite d'armure » si le noeud est cette branche ou l'une de ses qualites,
// sinon nil. ArmureQ dit de laquelle il s'agit.
function TWinLivres.NoeudQualites(Node: TTreeNode; out ArmureQ: Boolean): TTreeNode;
begin
  Result := nil;
  ArmureQ := False;
  if Node = nil then Exit;
  if (GetNodeType(Node) in [NT_QUALITE_ARME, NT_QUALITE_ARMURE]) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if GetNodeType(Node) <> NT_CHAPITRE then Exit;
  if Node.Text = GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_063') then
    Result := Node
  else if Node.Text = GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_065') then
  begin
    Result := Node;
    ArmureQ := True;
  end;
end;

// Cree une qualite d'arme (<LIVRE>-WEAPB_NOM) ou d'armure (<LIVRE>-ARMOB_NOM) : nom seul, le reste se saisit ensuite.
procedure TWinLivres.CreerQualite;
var
  Lib, Code, Prefixe, Langue, Radical, NomChapitre: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  N, I: Integer;
  Mot: String;
  Branche, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok, ArmureQ: Boolean;

  procedure Ajouter(Nom, Valeur: String; AvecLangue: Boolean);
  var
    E: TDOMElement;
  begin
    E := XMLDoc.CreateElement(Nom);
    if AvecLangue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudQualites(TreeViewLivre.Selected, ArmureQ);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Ok := False;
  F := TForm.CreateNew(Self);
  try
    if ArmureQ then F.Caption := GetTexteLibelle('RULES-LAB_459') else F.Caption := GetTexteLibelle('RULES-LAB_458');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 120;
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if Trim(EditNom.Text) = '' then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      Ok := True;
      Break;
    end;
  finally
    F.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  if ArmureQ then
  begin
    Radical := '-ARMOB_';
    NomChapitre := 'DATA_ARMOR_BONUS';
  end
  else
  begin
    Radical := '-WEAPB_';
    NomChapitre := 'DATA_WEAPON_BONUS';
  end;
  // nom de la qualite en majuscules, mots separes par '_' (RULES-WEAPB_TRAP_BLADE, RULES-ARMOB_FLEXIBLE)
  Mot := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Mot := Mot + UpCase(Lib[I])
    else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
      Mot := Mot + '_';
  while (Mot <> '') and (Mot[Length(Mot)] = '_') do
    Delete(Mot, Length(Mot), 1);
  if Mot = '' then Mot := 'NEW';
  Code := Prefixe + Radical + Mot;
  N := 1;
  while TrouverElementParId('BonusMalus', Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + Radical + Mot + IntToStr(N);
  end;

  Chapitre := XMLDoc.GetElementsByTagName(NomChapitre).Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement(NomChapitre);
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('BonusMalus');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', Lib, True);
  Ajouter('Explanation', '-', True);
  Ajouter('Modifier', '+', False);

  if ArmureQ then
    Noeud := TreeViewLivre.Items.AddChild(Branche, Lib)
  else
    Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  if ArmureQ then SetNodeInfo(Noeud, NT_QUALITE_ARMURE, Code) else SetNodeInfo(Noeud, NT_QUALITE_ARME, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleQualiteClick(Sender: TObject);
begin
  CreerQualite;
end;

// Fiche d'une qualite d'arme ou d'armure : seule la liste des champs lui est propre ; modifiable si le livre l'autorise.
procedure TWinLivres.AfficherFicheQualite(Element: TDOMElement);
var
  ChampModif: StructureChampFiche;
  EstArme: Boolean;
begin
  if Element = nil then Exit;
  EstArme := (Element.ParentNode <> nil) and (Element.ParentNode.NodeName = 'DATA_WEAPON_BONUS');
  FicheTag := 'BonusMalus';
  FicheTypeNoeud := GetNodeType(TreeViewLivre.Selected);
  // Modifier avec attribut name (malus d'armure sur une competence) : la liste +/- ne sait pas le porter
  if (Element.FindNode('Modifier') <> nil) and (TDOMElement(Element.FindNode('Modifier')).GetAttribute('name') <> '') then
    ChampModif := ChampFiche('Modifier', 'RULES-LAB_034', gfTexte, False, False, True, False)
  else
    ChampModif := ChampFiche('Modifier', 'RULES-LAB_034', gfListe, False, False, True, False, '+|-');
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True),
    ChampModif,
    ChampFiche('Modifier@name', 'RULES-LAB_034', gfTexte, True, False, True, False),
    ChampFiche('Short', 'RULES-LAB_073', gfTexte, True, False, not EstArme),  // obligatoire au schema pour une qualite d'arme
    ChampFiche('NeedsValue', 'RULES-LAB_495', gfCases, True, False, True, False, '1=' + GetTexteLibelle('RULES-LAB_495')),
    // qualites d'arme donnees par celle-ci : un ou plusieurs codes separes par des virgules
    ChampFiche('WeaponQuality', 'RULES-LAB_292', gfTexte, True, False, True, False),
    ChampFiche('Talent', 'RULES-LAB_007', gfCodeLibre, False, False, True, False,
      ChoixParTags(['Talent'], ValeurXML(Element.FindNode('Talent')))),
    ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, False),  // obligatoire au schema (arme et armure)
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  // ordre du schema : Description, Explanation, (Short), puis le reste, Page en dernier
  if EstArme then
    PanelFiche.OrdreBalises := 'Description,Explanation,Short,*NeedsValue,*WeaponQuality,*Talent,Modifier,*Page'
  else
    PanelFiche.OrdreBalises := 'Description,Explanation,*Modifier,*NeedsValue,*Corruption,*Talent,*Page';
  RemplirCompLieeFiche('');  // cibles de competence de la grille (liste commune avec la fiche de talent)
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Branche « Trappings » si le noeud est cette branche ou l'un de ses trappings, sinon nil.
function TWinLivres.NoeudTrappings(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_TRAPPING) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Text = GetTexteLibelle('RULES-LAB_196')) then
    Result := Node;
end;

const
  // themes proposes (RULES-LAB_190 a 199) et disponibilites ; un code sans libelle n'appartient pas a l'edition chargee
  ThemesTrapping: array[0..14] of String = ('RULES-LAB_190', 'RULES-LAB_191', 'RULES-LAB_192', 'RULES-LAB_193',
    'RULES-LAB_194', 'RULES-LAB_195', 'RULES-LAB_196', 'RULES-LAB_197', 'RULES-LAB_198', 'RULES-LAB_199',
    'RULES-LAB_260', 'RULES-LAB_261', 'RULES-LAB_262', 'RULES-LAB_288', 'RULES-LAB_313');
  DisposEquipement: array[0..4] of String = ('RULES-DISPO_COMMON', 'RULES-DISPO_LIMITED', 'RULES-DISPO_RARE',
    'RULES-DISPO_EXOTIC', 'RULES-DISPO_UNIQUE');

// Cree un trapping : nom seul ; code <LIVRE>-TRAP_NOM. Squelette : theme divers, Common, encombrement 0.
procedure TWinLivres.CreerTrapping;
var
  Lib, Code, Prefixe, Langue: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok: Boolean;

  procedure Ajouter(Nom, Valeur: String; AvecLangue: Boolean);
  var
    E: TDOMElement;
  begin
    E := XMLDoc.CreateElement(Nom);
    if AvecLangue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudTrappings(TreeViewLivre.Selected);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Ok := False;
  F := TForm.CreateNew(Self);
  try
    F.Caption := GetTexteLibelle('RULES-LAB_457');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 120;
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if Trim(EditNom.Text) = '' then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      Ok := True;
      Break;
    end;
  finally
    F.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  Code := Prefixe + '-TRAP_' + NomEnMajuscules(Lib);
  while TrouverElementParId('Trapping', Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + '-TRAP_' + NomEnMajuscules(Lib) + '_' + IntToStr(N);
  end;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_TRAPPING').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_TRAPPING');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Trapping');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', Lib, True);
  Ajouter('Theme', 'RULES-LAB_196', False);
  Ajouter('Availability', 'RULES-DISPO_COMMON', False);
  Ajouter('Encumbrance', '0', False);

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_TRAPPING, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouveauTrappingClick(Sender: TObject);
begin
  CreerTrapping;
end;

// Cree une maladie : nom, contraction, incubation, duree, symptomes (la fiche est une grille en
// lecture seule, tout se saisit donc ici) ; code <LIVRE>-DISEASE_NNN, cle dans l'attribut name.
// Les modificateurs chiffres (<ModifyCarac>) ne sont pas encore editables : a poser dans le XML.
procedure TWinLivres.CreerMaladie;
const
  LibChamps: array[0..4] of String = ('RULES-LAB_403', 'RULES-LAB_282', 'RULES-LAB_283', 'RULES-LAB_284', 'RULES-LAB_285');
  TagChamps: array[1..4] of String = ('Contraction', 'Incubation', 'Duration', 'Symptoms');
var
  Code, Prefixe, Langue: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  N, I: Integer;
  Branche, Noeud: TTreeNode;
  F: TForm;
  Edits: array[0..4] of TEdit;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok: Boolean;
  Valeurs: array[0..4] of String;

  procedure Ajouter(Nom, Valeur: String);
  var
    E: TDOMElement;
  begin
    E := XMLDoc.CreateElement(Nom);
    E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_281', 44);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Ok := False;
  F := TForm.CreateNew(Self);
  try
    F.Caption := GetTexteLibelle('RULES-LAB_475');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 420;
    F.ClientHeight := 12 + 5 * 52 + 50;
    for I := 0 to 4 do
    begin
      Lbl := TLabelContour.Create(F);
      Lbl.Parent := F;
      Lbl.SetBounds(12, 12 + I * 52, 396, 18);
      Lbl.Caption := GetTexteLibelle(LibChamps[I]);
      Edits[I] := TEdit.Create(F);
      Edits[I].Parent := F;
      Edits[I].SetBounds(12, 30 + I * 52, 396, 24);
    end;
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(190, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(302, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if Trim(Edits[0].Text) = '' then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      for I := 0 to 4 do
        Valeurs[I] := Trim(Edits[I].Text);
      Ok := True;
      Break;
    end;
  finally
    F.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-DISEASE_' + Format('%.3d', [N]);
    Inc(N);
  until TrouverElementParId('Disease', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_DISEASE').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_DISEASE');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Disease');
  Elem.SetAttribute('name', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', Valeurs[0]);
  for I := 1 to 4 do
    if (Valeurs[I] <> '') or (I < 4) then  // Symptoms est facultatif au schema, les trois autres obligatoires
      Ajouter(TagChamps[I], Valeurs[I]);

  Noeud := TreeViewLivre.Items.AddChild(Branche, Valeurs[0]);
  SetNodeInfo(Noeud, NT_MALADIE, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleMaladieClick(Sender: TObject);
begin
  CreerMaladie;
end;

// Cree une affliction : le nom suffit, l'explication et les modificateurs se saisissent sur la fiche.
// Code <LIVRE>-AFFLICT_NNN, cle dans l'attribut name.
procedure TWinLivres.CreerAffliction;
var
  Code, Prefixe, Langue, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_296', 45);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_479'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-AFFLICT_' + Format('%.3d', [N]);
    Inc(N);
  until TrouverElementParId('Affliction', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_AFFLICTION').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_AFFLICTION');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Affliction');
  Elem.SetAttribute('name', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement('Description');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, Lib);
  E := XMLDoc.CreateElement('Explanation');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, '');

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_AFFLICTION, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleAfflictionClick(Sender: TObject);
begin
  CreerAffliction;
end;

function TWinLivres.LibelleChoixFiche(Code: String): String;
begin
  Result := LibelleAffiche(Code);
end;

// Fiche d'un trapping : seule la liste des champs lui est propre ; modifiable si le livre l'autorise.
procedure TWinLivres.AfficherFicheTrapping(Element: TDOMElement);
var
  Themes, Dispos, Familles: String;
  I: Integer;
  AvecFamilles: Boolean;
  Champs: TTableauChampsFiche;

  function Rempli(const Balise: String): Boolean;
  begin
    Result := (Element.FindNode(Balise) <> nil) and (Trim(ValeurXML(Element.FindNode(Balise))) <> '');
  end;

  procedure Ajoute(const Champ: StructureChampFiche);
  begin
    SetLength(Champs, Length(Champs) + 1);
    Champs[High(Champs)] := Champ;
  end;

  // abreviation d'une caracteristique (RULES-SHORTATTR_x), pour l'en-tete d'une colonne
  function CourtAttr(const Code: String): String;
  begin
    Result := GetTexteLibelle('RULES-SHORTATTR_' + Code, Code);
  end;

  // fabrications proposees (qualites et defauts de fabrication) du livre ouvert et du Rulebook : « |=|code<tab>libelle »
  function PropositionsFabrications: String;
  var
    Liste: TStringList;
    Doc: TXMLDocument;
    Elements: TDOMNodeList;
    N, K: Integer;
    Code, Lib: String;
  begin
    Result := '';
    Liste := TStringList.Create;
    try
      Liste.Sorted := True;
      Liste.Duplicates := dupIgnore;
      for N := 0 to 1 do
      begin
        if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
        if Doc = nil then Continue;
        Elements := Doc.GetElementsByTagName('Craftsmanship');
        for K := 0 to Elements.Count - 1 do
        begin
          Code := TDOMElement(Elements.Item[K]).GetAttribute('id');
          Lib := Trim(ValeurXML(Elements.Item[K].FindNode('Description')));
          if Lib = '' then Lib := GetTexteLibelle(Code, Code);
          if (Code <> '') and (Pos('|', Lib) = 0) then Liste.Add(Lib + #1 + Code);
        end;
      end;
      for K := 0 to Liste.Count - 1 do
        Result := Result + '|' + Copy(Liste[K], Pos(#1, Liste[K]) + 1, MaxInt) + #9 + Copy(Liste[K], 1, Pos(#1, Liste[K]) - 1);
      if Result <> '' then Result := '|=' + Result;
    finally
      Liste.Free;
    end;
  end;

  // noms des traits de creature proposes : talents marques <Trait> du livre ouvert et du Rulebook, sans leur
  // suite « (Any) » / « (Rating) », tries ; chaine « |= |nom|nom... » a la suite des libelles de colonnes
  function PropositionsTraits: String;
  var
    Liste: TStringList;
    Doc: TXMLDocument;
    Elements: TDOMNodeList;
    N, K, P: Integer;
    Nom, Code, Exigence, Suite: String;
  begin
    Result := '';
    Liste := TStringList.Create;
    try
      Liste.Sorted := True;
      Liste.Duplicates := dupIgnore;
      for N := 0 to 1 do
      begin
        if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
        if Doc = nil then Continue;
        Elements := Doc.GetElementsByTagName('Talent');
        for K := 0 to Elements.Count - 1 do
          if ValeurXML(Elements.Item[K].FindNode('Trait')) = ConstVrai then
          begin
            // une specialisation (RULES-T_SIZE__LARG) n'est pas un trait a part : seule sa mere (__*) est proposee
            Code := TDOMElement(Elements.Item[K]).GetAttribute('id');
            if (Pos('__', Code) > 0) and (Copy(Code, Length(Code) - 2, 3) <> '__*') then Continue;
            Nom := Trim(ValeurXML(Elements.Item[K].FindNode('Description')));
            P := Pos(' (', Nom);
            Exigence := '';
            if P > 0 then
            begin
              // « (Any) » : specialisation ; « (Rating) » : nombre ; autre mot (Type, Target...) : l'un ou l'autre
              Suite := LowerCase(Trim(Copy(Nom, P + 2, Length(Nom) - P - 2)));
              if Suite = 'any' then Exigence := 'S'
              else if Suite = 'rating' then Exigence := 'N'
              else Exigence := 'P';
              Nom := Copy(Nom, 1, P - 1);
            end;
            if (Nom <> '') and (Pos('|', Nom) = 0) and (Pos(#9, Nom) = 0) then
            begin
              if Exigence <> '' then Nom := Nom + #9 + Exigence;
              Liste.Add(Nom);
            end;
          end;
      end;
      for K := 0 to Liste.Count - 1 do Result := Result + '|' + Liste[K];
      if Result <> '' then Result := '|=' + Result;
    finally
      Liste.Free;
    end;
  end;
begin
  if Element = nil then Exit;
  FicheTag := 'Trapping';
  FicheTypeNoeud := NT_TRAPPING;
  Themes := '';
  for I := Low(ThemesTrapping) to High(ThemesTrapping) do
    Themes := Themes + '|' + ThemesTrapping[I];
  Dispos := '';
  for I := Low(DisposEquipement) to High(DisposEquipement) do
    Dispos := Dispos + '|' + DisposEquipement[I];
  // familles (groupes Animal, Vehicule, Commerce, Qualite) : cochees par l'utilisateur ou deja presentes dans les donnees
  Familles := FamillesTalent;
  if Rempli('AnimalProfile') or Rempli('AnimalTraits') then Familles := Familles + ',ANIMAL';
  if Rempli('BoatProfile') or Rempli('VehicleProfile') then Familles := Familles + ',VEHICULE';
  if Rempli('Locality') or Rempli('Season') then Familles := Familles + ',COMMERCE';
  if Rempli('InherentCraftsmanship') then Familles := Familles + ',QUALITE';
  AvecFamilles := EditionPermise;
  FTalentElement := Element;  // pour reconstruire la fiche apres un changement de famille
  Ajoute(ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True));
  if AvecFamilles then
    Ajoute(ChampFiche('FamilleTrapping', 'RULES-LAB_FAMILLE_TRAPPING', gfCases, False, False, True, False,
      'ANIMAL=' + GetTexteLibelle('RULES-LAB_FAMILLE_ANIMAL', 'Animal') +
      '|VEHICULE=' + GetTexteLibelle('RULES-LAB_FAMILLE_VEHICULE', 'Boat / vehicle') +
      '|COMMERCE=' + GetTexteLibelle('RULES-LAB_FAMILLE_COMMERCE', 'Trade goods (locality, season)') +
      '|QUALITE=' + GetTexteLibelle('RULES-LAB_FAMILLE_QUALITE', 'Inherent craftsmanship')));
  Ajoute(ChampFiche('Theme', 'RULES-LAB_201', gfCode, False, True, False, False, Copy(Themes, 2, MaxInt)));
  Ajoute(ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix));
  Ajoute(ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, False, True, False, '', cfEntierSigne));
  Ajoute(ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, False, False, False, Copy(Dispos, 2, MaxInt)));
  Ajoute(ChampFiche('Carries', 'RULES-LAB_185', gfTexte, False, False, True, False, '', cfEntier));
  Ajoute(EnGroupes(ChampFiche('Locality', 'RULES-LAB_238', gfCases, False, False, True, False, ChoixCasesLabels(229, 237)), 'Commerce'));
  Ajoute(EnGroupes(ChampFiche('Season', 'RULES-LAB_239', gfCases, False, False, True, False,
    ChoixCasesLabels(226, 228) + '|RULES-LAB_225=' + GetTexteLibelle('RULES-LAB_225')), 'Commerce'));  // ordre du livre : hiver puis printemps
  // profils et traits en tableau (genre gfTableau) : le XML garde son texte (« 7 25 0 ... », « 32;4 (-);... », « Bestial, Size (Large) »)
  Ajoute(EnGroupes(ChampFiche('AnimalProfile', 'RULES-LAB_960', gfTableau, True, False, True, False,
    'F |' + CourtAttr('Move') + '|' + CourtAttr('WS') + '|' + CourtAttr('BS') + '|' + CourtAttr('S') + '|' + CourtAttr('T') +
    '|' + CourtAttr('I') + '|' + CourtAttr('Ag') + '|' + CourtAttr('Dex') + '|' + CourtAttr('Int') + '|' + CourtAttr('WP') +
    '|' + CourtAttr('Fel') + '|' + CourtAttr('Wound')), 'Animal'));
  Ajoute(EnGroupes(ChampFiche('AnimalTraits', 'RULES-LAB_961', gfTableau, True, False, True, False,
    'T|' + GetTexteLibelle('RULES-LAB_TAB_TRAIT', 'Trait') + '|' + GetTexteLibelle('RULES-LAB_TAB_SPEC', 'Specialisation') +
    '|' + GetTexteLibelle('RULES-LAB_TAB_VALEUR', 'Value') + PropositionsTraits), 'Animal'));
  Ajoute(EnGroupes(ChampFiche('BoatProfile', 'RULES-LAB_963', gfTableau, True, False, True, False,
    'F;|' + GetTexteLibelle('RULES-LAB_TAB_EQUIPAGE', 'Crew') + '|' + GetTexteLibelle('RULES-LAB_TAB_VOILE', 'Sail M') +
    '|' + GetTexteLibelle('RULES-LAB_TAB_RAMES', 'Oar M') + '|' + GetTexteLibelle('RULES-LAB_TAB_MAN', 'Man') +
    '|' + GetTexteLibelle('RULES-LAB_TAB_TAILLE', 'Size') + '|' + CourtAttr('T') + '|' + CourtAttr('Wound')), 'Vehicule'));
  Ajoute(EnGroupes(ChampFiche('VehicleProfile', 'RULES-LAB_979', gfTableau, True, False, True, False,
    'F;|' + GetTexteLibelle('RULES-LAB_TAB_MOTEUR', 'Motive power') + '|' + CourtAttr('T') + '|' + CourtAttr('Wound') +
    '|' + GetTexteLibelle('RULES-LAB_TAB_FRAPPE', 'Strike')), 'Vehicule'));
  Ajoute(EnGroupes(ChampFiche('InherentCraftsmanship', 'RULES-LAB_962', gfTableau, True, False, True, False,
    'Q|' + GetTexteLibelle('RULES-LAB_125') + '|' + GetTexteLibelle('RULES-LAB_019') + PropositionsFabrications), 'Qualite'));
  Ajoute(ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False));
  FiltrerChampsFiche(Champs, Element, VersionFicheLivre, Familles);
  PanelFiche.Definir(Champs);
  if AvecFamilles then PanelFiche.DeclarerVirtuel('FamilleTrapping');
  RemplirCompLieeFiche('');  // cibles de competence de la grille (liste commune avec la fiche de talent)
  PanelFiche.Charger(Element);
  if AvecFamilles then PanelFiche.CocherCodes('FamilleTrapping', Familles);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Branche « Armes » si le noeud est cette branche ou l'une de ses armes, sinon nil.
function TWinLivres.NoeudArmes(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_ARME) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Text = GetTexteLibelle('RULES-LAB_063')) then
    Result := Node;
end;

type
  // Liste des groupes de la boite de creation d'une arme : la case Munition la restreint aux groupes de tir (PROJ_).
  TFiltreGroupesArme = class
    Combo: TComboBox;
    Tri, Codes: TStringList;
    procedure Remplir(SeulementTir: Boolean);
    procedure CaseClick(Sender: TObject);
  end;

procedure TFiltreGroupesArme.Remplir(SeulementTir: Boolean);
var
  I: Integer;
  Code: String;
begin
  Combo.Items.Clear;
  Codes.Clear;
  for I := 0 to Tri.Count - 1 do
  begin
    Code := Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I]));
    if SeulementTir and (Pos('COMP_RANGED', Code) = 0) then Continue;
    Combo.Items.Add(Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1));
    Codes.Add(Code);
  end;
  Combo.ItemIndex := -1;
end;

procedure TFiltreGroupesArme.CaseClick(Sender: TObject);
begin
  Remplir(TCheckBox(Sender).Checked);
end;

// Cree une arme : nom + groupe d'armes (competence de combat ou de tir). Le code suit la convention des
// livres : <LIVRE>-COMB_NOM ou <LIVRE>-PROJ_NOM (LUSTR-COMB_SHORT_SWORD). Squelette seul, les autres champs se saisissent ensuite.
procedure TWinLivres.CreerArme;
var
  Lib, Code, Prefixe, Langue, Groupe, Id, Mot: String;
  Livre, Chapitre: TDOMNode;
  Elem: TDOMElement;
  N, I: Integer;
  Branche, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  Combo: TComboBox;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok, Munition: Boolean;
  CaseMun, CaseTir: TCheckBox;
  Tir: Boolean;
  Filtre: TFiltreGroupesArme;
  Tri, Codes: TStringList;

  procedure Ajouter(Nom, Valeur: String; AvecLangue: Boolean);
  var
    E: TDOMElement;
  begin
    E := XMLDoc.CreateElement(Nom);
    if AvecLangue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudArmes(TreeViewLivre.Selected);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Tri := TStringList.Create;
  Codes := TStringList.Create;
  Ok := False;
  Groupe := '';
  Munition := False;
  Filtre := TFiltreGroupesArme.Create;
  F := TForm.CreateNew(Self);
  try
    RemplirGroupesArmes(Tri);

    F.Caption := GetTexteLibelle('RULES-LAB_436');
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 380;
    F.ClientHeight := 205;
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 12, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
    EditNom := TEdit.Create(F);
    EditNom.Parent := F;
    EditNom.SetBounds(12, 30, 356, 24);
    Lbl := TLabelContour.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(12, 62, 356, 18);
    Lbl.Caption := GetTexteLibelle('RULES-LAB_437');
    Combo := TComboBox.Create(F);
    Combo.Parent := F;
    Combo.SetBounds(12, 80, 356, 24);
    Combo.Style := csDropDownList;
    Filtre.Combo := Combo;
    Filtre.Tri := Tri;
    Filtre.Codes := Codes;
    Filtre.Remplir(False);
    CaseMun := TCheckBox.Create(F);
    CaseMun.Parent := F;
    CaseMun.SetBounds(12, 114, 356, 22);
    CaseMun.Caption := GetTexteLibelle('RULES-LAB_592', 'Ammunition (arrows, bolts, bullets)');
    CaseMun.OnClick := @Filtre.CaseClick;
    CaseTir := nil;
    if EstLivreV2 then
    begin
      // V2 : pas de groupe d'armes (Skill = « - » partout) ; une case dit si l'arme est de tir (PROJ_V2_)
      Lbl.Visible := False;
      Combo.Visible := False;
      CaseTir := TCheckBox.Create(F);
      CaseTir.Parent := F;
      CaseTir.SetBounds(12, 62, 356, 22);
      CaseTir.Caption := GetTexteLibelle('RULES-LAB_ARME_TIR_V2', 'Ranged weapon (bow, crossbow, sling...)');
      CaseMun.Top := 90;
      F.ClientHeight := 170;
    end;
    BOk := NouveauBouton(F);
    BOk.Parent := F;
    BOk.SetBounds(150, F.ClientHeight - 38, 105, 32);
    BOk.Caption := GetTexteLibelle('RULES-LAB_106');
    BOk.Tag := mrOk;
    BOk.OnClick := @BoutonDialogueClick;
    BAnnuler := NouveauBouton(F);
    BAnnuler.Parent := F;
    BAnnuler.SetBounds(262, F.ClientHeight - 38, 105, 32);
    BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
    BAnnuler.Tag := mrCancel;
    BAnnuler.OnClick := @BoutonDialogueClick;
    F.KeyPreview := True;
    F.OnKeyDown := @ToucheDialogue;
    while F.ShowModal = mrOk do
    begin
      if (Trim(EditNom.Text) = '') or (not EstLivreV2 and (Combo.ItemIndex < 0)) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_404'));
        Continue;
      end;
      if not EstLivreV2 and CaseMun.Checked and (Pos('COMP_RANGED', Codes[Combo.ItemIndex]) = 0) then
      begin
        ShowMessage(GetTexteLibelle('RULES-LAB_593', 'An ammunition serves a ranged weapon group: choose a ranged skill.'));
        Continue;
      end;
      Lib := Trim(EditNom.Text);
      if EstLivreV2 then
      begin
        Groupe := '-';
        Tir := CaseTir.Checked or CaseMun.Checked;
      end
      else
      begin
        Groupe := Codes[Combo.ItemIndex];
        Tir := Pos('COMP_RANGED', Groupe) > 0;
      end;
      Munition := CaseMun.Checked;
      Ok := True;
      Break;
    end;
  finally
    F.Free;
    Filtre.Free;
    Codes.Free;
    Tri.Free;
  end;
  if not Ok then Exit;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  // le jeu reconnait une arme a son code COMB_ (corps a corps) ou PROJ_ (tir), une munition a MUNI_ ;
  // nom en majuscules (RULES-COMB_SHORT_SWORD)
  if Munition then Id := 'MUNI_'
  else if Tir then Id := 'PROJ_'
  else Id := 'COMB_';
  // V2 : les armes du livre portent COMB_V2_ / PROJ_V2_ / MUNI_V2_
  if EstLivreV2 then Id := Id + 'V2_';
  N := 1;
  Mot := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Mot := Mot + UpCase(Lib[I])
    else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
      Mot := Mot + '_';
  while (Mot <> '') and (Mot[Length(Mot)] = '_') do
    Delete(Mot, Length(Mot), 1);
  if Mot = '' then Mot := 'NEW';
  Code := Prefixe + '-' + Id + Mot;
  while TrouverElementParId('Weapon', Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + '-' + Id + Mot + IntToStr(N);
  end;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_WEAPON').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_WEAPON');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Weapon');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', Lib, True);
  Ajouter('Skill', Groupe, False);
  if Munition then Ajouter('Damage', '+0', False) else Ajouter('Damage', '-', False);
  if EstLivreV2 then
  begin
    // arme V2 : codes DISPO2 / WTYPE2, portee en texte (armes de tir seulement), Price et Page, ni Ammunition ni code de portee
    Ajouter('Availability', 'RULES-DISPO2_COMMON', False);
    if Tir then Ajouter('Reach', '', False);
    Ajouter('Price', '', False);
    Ajouter('Encumbrance', '0', False);
    Ajouter('Quality', '', False);
    if Munition then Ajouter('Hand', '0', False) else Ajouter('Hand', '1', False);
    Ajouter('Type', 'RULES-WTYPE2_ORDINARY', False);
    Ajouter('Page', '', False);
  end
  else
  begin
    Ajouter('Availability', 'RULES-DISPO_COMMON', False);
    Ajouter('Reach', 'RULES-WEAPR_PERSO', False);
    Ajouter('Encumbrance', '0', False);
    Ajouter('Quality', '-', False);
    if Munition then
    begin
      Ajouter('Hand', '0', False);
      Ajouter('Ammunition', '1', False);
    end
    else
    begin
      Ajouter('Hand', '1', False);
      Ajouter('Ammunition', '0', False);
    end;
  end;

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_ARME, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleArmeClick(Sender: TObject);
begin
  CreerArme;
end;

// Cree une specialisation de competence : <Skill id="<MERE sans *><MOT>"> dans DATA_SKILL_SPECIALIZATION,
// avec <Description> "Base (Nom)" et <Generique> = la mere. Les meres proposees sont les competences
// en "_*" du livre ouvert.
procedure TWinLivres.CreerSpecialisationCompetence(EstTalent: Boolean);
var
  Lib, Mot, Code, Langue, Base, CodeMere, CodeSansEtoile, NomTag, ChapMere, ChapSpec, LabBranche: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  Elements: TDOMNodeList;
  Codes, Libs: TStringList;
  I, N, P, TypeFeuille: Integer;
  Branche, NodeMere, Noeud: TTreeNode;
  F: TForm;
  EditNom: TEdit;
  Combo: TComboBox;
  BOk, BAnnuler: TBCButton;
  Lbl: TLabel;
  Ok: Boolean;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  if EstTalent then begin NomTag := 'Talent'; ChapMere := 'DATA_TALENT'; ChapSpec := 'DATA_TALENT_SPECIALIZATION'; TypeFeuille := 29; LabBranche := 'RULES-LAB_147'; end
  else begin NomTag := 'Skill'; ChapMere := 'DATA_SKILL'; ChapSpec := 'DATA_SKILL_SPECIALIZATION'; TypeFeuille := 27; LabBranche := 'RULES-LAB_146'; end;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, LabBranche, TypeFeuille);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;

  Codes := TStringList.Create;
  Libs := TStringList.Create;
  try
    Chapitre := XMLDoc.GetElementsByTagName(ChapMere).Item[0];
    if Chapitre <> nil then
    begin
      Elements := TDOMElement(Chapitre).GetElementsByTagName(NomTag);
      for I := 0 to Elements.Count - 1 do
      begin
        E := TDOMElement(Elements.Item[I]);
        CodeMere := E.GetAttribute('id');
        if (Length(CodeMere) > 2) and (Copy(CodeMere, Length(CodeMere) - 1, 2) = ValeurSousCompetence + '*') then
        begin
          Codes.Add(CodeMere);
          Libs.Add(ValeurXML(E.FindNode('Description')));
        end;
      end;
    end;
    // WFRP1 : la competence a specialites est une <Skill id="RULES-COMP_ARCANE_LANGUAGE"> portant <Variants>"1"</Variants> ;
    // sa mere de regroupement est RULES-COMP_ARCANE_LANGUAGE__* (lien <Generique> des specialisations)
    if not EstTalent then
      for N := 0 to 1 do
      begin
        if N = 0 then Livre := XMLDoc else Livre := RulebookXML;
        if Livre = nil then Continue;
        Elements := TDOMDocument(Livre).GetElementsByTagName('Skill');
        for I := 0 to Elements.Count - 1 do
        begin
          E := TDOMElement(Elements.Item[I]);
          CodeMere := E.GetAttribute('id');
          if (CodeMere = '') or (Copy(CodeMere, Length(CodeMere), 1) = '*') or (Pos('__', CodeMere) > 0) then Continue;
          if (ValeurXML(E.FindNode('Variants')) = '') or (ValeurXML(E.FindNode('Variants')) = '0') then Continue;
          CodeMere := CodeMere + '__*';
          if Codes.IndexOf(CodeMere) >= 0 then Continue;
          Codes.Add(CodeMere);
          Libs.Add(ValeurXML(E.FindNode('Description')));
        end;
      end;
    // + celles des autres livres charges (ex. "Lore (Any)" du Rulebook)
    if EstTalent then
    begin
      if ListTalent <> nil then
        for I := 0 to ListTalent.Count - 1 do
        begin
          CodeMere := ListTalent[I].CodeTalent;
          if (Length(CodeMere) > 2) and (Copy(CodeMere, Length(CodeMere) - 1, 2) = ValeurSousCompetence + '*') and
             (Codes.IndexOf(CodeMere) < 0) then
          begin
            Codes.Add(CodeMere);
            Libs.Add(ListTalent[I].Libelle);
          end;
        end;
    end
    else if ListCompetence <> nil then
      for I := 0 to ListCompetence.Count - 1 do
      begin
        CodeMere := ListCompetence[I].CodeCompetence;
        if (Length(CodeMere) > 2) and (Copy(CodeMere, Length(CodeMere) - 1, 2) = ValeurSousCompetence + '*') and
           (Codes.IndexOf(CodeMere) < 0) then
        begin
          Codes.Add(CodeMere);
          Libs.Add(ListCompetence[I].Libelle);
        end;
      end;
    if Codes.Count = 0 then
    begin
      if EstTalent then ShowMessage(GetTexteLibelle('RULES-LAB_412'))
                   else ShowMessage(GetTexteLibelle('RULES-LAB_409'));
      Exit;
    end;

    Ok := False;
    F := TForm.CreateNew(Self);
    try
      if EstTalent then F.Caption := GetTexteLibelle('RULES-LAB_410')
                   else F.Caption := GetTexteLibelle('RULES-LAB_406');
      F.Position := poOwnerFormCenter;
      F.BorderStyle := bsDialog;
      F.ClientWidth := 380;
      F.ClientHeight := 140;
      Lbl := TLabelContour.Create(F);
      Lbl.Parent := F;
      Lbl.SetBounds(12, 12, 356, 18);
      Lbl.Caption := GetTexteLibelle('RULES-LAB_403');
      EditNom := TEdit.Create(F);
      EditNom.Parent := F;
      EditNom.SetBounds(12, 30, 356, 24);
      Lbl := TLabelContour.Create(F);
      Lbl.Parent := F;
      Lbl.SetBounds(12, 62, 356, 18);
      if EstTalent then Lbl.Caption := GetTexteLibelle('RULES-LAB_413') else Lbl.Caption := GetTexteLibelle('RULES-LAB_408');
      Combo := TComboBox.Create(F);
      Combo.Parent := F;
      Combo.SetBounds(12, 80, 356, 24);
      Combo.Style := csDropDownList;
      Combo.Items.AddStrings(Libs);
      BOk := NouveauBouton(F);
      BOk.Parent := F;
      BOk.SetBounds(150, 104, 105, 32);
      BOk.Caption := GetTexteLibelle('RULES-LAB_106');
      BOk.Tag := mrOk;
      BOk.OnClick := @BoutonDialogueClick;
      BAnnuler := NouveauBouton(F);
      BAnnuler.Parent := F;
      BAnnuler.SetBounds(262, 104, 105, 32);
      BAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
      BAnnuler.Tag := mrCancel;
      BAnnuler.OnClick := @BoutonDialogueClick;
      F.KeyPreview := True;
      F.OnKeyDown := @ToucheDialogue;
      while F.ShowModal = mrOk do
      begin
        if (Trim(EditNom.Text) = '') or (Combo.ItemIndex < 0) then
        begin
          ShowMessage(GetTexteLibelle('RULES-LAB_404'));
          Continue;
        end;
        Lib := Trim(EditNom.Text);
        CodeMere := Codes[Combo.ItemIndex];
        Base := Libs[Combo.ItemIndex];
        Ok := True;
        Break;
      end;
    finally
      F.Free;
    end;
  finally
    Codes.Free;
    Libs.Free;
  end;
  if not Ok then Exit;

  // "Art (Any)" -> "Art"
  P := Pos(' (', Base);
  if P > 0 then Base := Copy(Base, 1, P - 1);
  CodeSansEtoile := Copy(CodeMere, 1, Length(CodeMere) - 1);

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  // nom de la specialisation en majuscules, mots separes par '_' (RULES-COMP_LORE__OLD_ONES)
  Mot := '';
  for I := 1 to Length(Lib) do
    if UpCase(Lib[I]) in ['A'..'Z', '0'..'9'] then
      Mot := Mot + UpCase(Lib[I])
    else if (Mot <> '') and (Mot[Length(Mot)] <> '_') then
      Mot := Mot + '_';
  while (Mot <> '') and (Mot[Length(Mot)] = '_') do
    Delete(Mot, Length(Mot), 1);
  if Mot = '' then Mot := 'NEW';
  // code du livre ouvert + suite de la mere (DWARF-COMP_LORE__ pour la mere RULES-COMP_LORE__*)
  P := Pos('-', CodeSansEtoile);
  CodeSansEtoile := ValeurXML(Livre.FindNode('CODE_BOOK')) + Copy(CodeSansEtoile, P, Length(CodeSansEtoile));
  Code := CodeSansEtoile + Mot;
  N := 1;
  while (TrouverElementParId(NomTag, Code) <> nil) or ((not EstTalent) and (ChercheCompetence(Code).CodeCompetence <> '')) do
  begin
    Inc(N);
    Code := CodeSansEtoile + Mot + IntToStr(N);
  end;

  Chapitre := XMLDoc.GetElementsByTagName(ChapSpec).Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement(ChapSpec);
    Livre.AppendChild(Chapitre);
  end;
  Lib := Base + ' (' + Lib + ')';
  Elem := XMLDoc.CreateElement(NomTag);
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement('Description');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, Lib);
  E := XMLDoc.CreateElement('Generique');
  Elem.AppendChild(E);
  EcrireValeurXML(E, CodeMere);

  // regroupement de la mere dans l'arbre (cree au besoin), puis la feuille dessous
  NodeMere := nil;
  for I := 0 to Branche.Count - 1 do
    if (GetNodeType(Branche.Items[I]) = NT_CHAPITRE) and (GetNodeCode(Branche.Items[I]) = CodeSansEtoile + '*') then
      NodeMere := Branche.Items[I];
  if NodeMere = nil then
  begin
    NodeMere := TreeViewLivre.Items.AddChild(Branche, Base + ' (Any)');
    SetNodeInfo(NodeMere, NT_CHAPITRE, CodeSansEtoile + '*');
  end;
  Noeud := TreeViewLivre.Items.AddChild(NodeMere, Lib);
  SetNodeInfo(Noeud, TypeFeuille, Code);
  NodeMere.AlphaSort;
  Branche.AlphaSort;
  Branche.Expand(False);
  NodeMere.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleSpecTalentClick(Sender: TObject);
begin
  CreerSpecialisationCompetence(True);
end;

procedure TWinLivres.MenuNouvelleSpecialisationClick(Sender: TObject);
begin
  CreerSpecialisationCompetence(False);
end;

procedure TWinLivres.MenuNouvelleCompetenceClick(Sender: TObject);
begin
  CreerCompetenceOuTalent(False);
end;

procedure TWinLivres.MenuNouveauTalentClick(Sender: TObject);
begin
  CreerCompetenceOuTalent(True);
end;

procedure TWinLivres.MenuNouvelleRaceClick(Sender: TObject);
begin
  CreerRace;
end;

// Parcourt le document (hors definition) et releve les endroits qui citent Code, soit par l'attribut name,
// soit par la valeur d'un element feuille (ou l'un des morceaux d'une valeur "A/B", "A,B", "A+B").
// Une carriere citee dans le SUBCHAPTER_CAREER d'une ethnie, ou une ethnie citee dans la table des talents
// aleatoires (une ligne DATA_RANDOM_TALENT par talent et par ethnie), sont de simples listes que l'on vide (Citations) ;
// tout autre endroit bloque la suppression (Bloquants = nom du chapitre racine).
procedure TWinLivres.CollecterReferences(Noeud: TDOMNode; Code: String; Definition: TDOMElement; Chapitre: String;
  Bloquants: TStrings; Citations: TFPList);
var
  Enfant, Sous: TDOMNode;
  E: TDOMElement;
  A_Enfants: Boolean;
  Morceaux: TStringList;
  Cite: Boolean;
  Valeur: String;
begin
  Enfant := Noeud.FirstChild;
  while Enfant <> nil do
  begin
    if (Enfant.NodeType = ELEMENT_NODE) and (Enfant <> Definition) then
    begin
      E := TDOMElement(Enfant);
      if Noeud = XMLDoc.DocumentElement then
        Chapitre := E.NodeName;
      // le libelle d'une condition (DATA_LABEL) porte son code en attribut name : ce n'est pas une citation
      if (Definition <> nil) and (Definition.NodeName = 'Condition') and (Chapitre = 'DATA_LABEL') then
      begin
        Enfant := Enfant.NextSibling;
        Continue;
      end;
      A_Enfants := False;
      Sous := E.FirstChild;
      while Sous <> nil do
      begin
        if Sous.NodeType = ELEMENT_NODE then
          A_Enfants := True;
        Sous := Sous.NextSibling;
      end;
      Morceaux := TStringList.Create;
      try
        // if= (balise historique) ou Filtre= (balise generique <Modificateur>) : la condition citee (DATA_CONDITION)
        Cite := (E.GetAttribute('name') = Code) or (E.GetAttribute('if') = Code) or
                (E.GetAttribute(ConstXmlModificateurFiltre) = Code);
        if (not Cite) and (not A_Enfants) then
        begin
          Valeur := ValeurXML(E);
          Morceaux.Delimiter := '/';
          Morceaux.StrictDelimiter := True;
          Morceaux.DelimitedText := StringReplace(StringReplace(StringReplace(Valeur, ',', '/', [rfReplaceAll]), '+', '/', [rfReplaceAll]), ' ', '/', [rfReplaceAll]);
          Cite := Morceaux.IndexOf(Code) >= 0;
        end;
      finally
        Morceaux.Free;
      end;
      if Cite then
      begin
        if (E.NodeName = 'Career') and (E.ParentNode <> nil) and (E.ParentNode.NodeName = 'SUBCHAPTER_CAREER') and
           (Citations <> nil) then
          Citations.Add(E)
        else if (E.NodeName = 'Specie') and (E.ParentNode <> nil) and (E.ParentNode.NodeName = 'DATA_RANDOM_TALENT') and
                (Citations <> nil) then
          Citations.Add(E.ParentNode)  // ligne de la table des talents aleatoires de cette ethnie : retiree entiere
        else if Bloquants.IndexOf(Chapitre) < 0 then
          Bloquants.Add(Chapitre);
      end
      else if A_Enfants then
        CollecterReferences(E, Code, Definition, Chapitre, Bloquants, Citations);
    end;
    Enfant := Enfant.NextSibling;
  end;
end;

// Supprime la carriere, l'ethnie ou la race selectionnee (memoire seulement, jusqu'a l'enregistrement d'une
// version de travail). Refuse si autre chose que la liste de carrieres d'une ethnie y renvoie, dans ce livre.
procedure TWinLivres.SupprimerSelection;
var
  Node, N: TTreeNode;
  NomTag, Code, Lib: String;
  Definition: TDOMElement;
  Bloquants: TStringList;
  Citations: TFPList;
  I: Integer;
  Ref, Suivant: TDOMNode;
  Pere: TDOMNode;
  Specie: TDOMElement;
begin
  Node := TreeViewLivre.Selected;
  if (Node = nil) or (XMLDoc = nil) or not CreationPermise then Exit;
  case GetNodeType(Node) of
    NT_METIER_NIVEAU1: NomTag := 'Career';
    NT_RACE: NomTag := 'Specie';
    NT_RACE_GROUPE: NomTag := 'Race';
    NT_ARME: NomTag := 'Weapon';
    NT_ARMURE: NomTag := 'Armor';
    NT_SORT: NomTag := 'Sort';
    NT_TRAPPING: NomTag := 'Trapping';
    NT_MALADIE: NomTag := 'Disease';
    NT_AFFLICTION: NomTag := 'Affliction';
    NT_SIGNE_ASTRAL: NomTag := 'StarSign';
    NT_BONUS_CARRIERE: NomTag := 'CareerBonus';
    NT_ADAPTATION_CARRIERE: NomTag := 'Adaptation';
    NT_CORRUPTION_PHYSIQUE, NT_CORRUPTION_MENTALE: NomTag := 'Corruption';
    NT_NATION: NomTag := 'Nation';
    NT_FABRICATION: NomTag := 'Craftsmanship';
    NT_QUALITE_ARME, NT_QUALITE_ARMURE: NomTag := 'BonusMalus';
    NT_CONDITION: NomTag := 'Condition';
    NT_COMPETENCE_N1, NT_SPECIALISATION_COMPETENCE: NomTag := 'Skill';
    NT_TALENT_N1, NT_SPECIALISATION_TALENT: NomTag := 'Talent';
    NT_DIEU_V1: NomTag := 'Deity';
    NT_CULTE_V1: NomTag := 'Cult';
    NT_FAMILIER_V1: NomTag := 'Familiar';
    NT_CLASSE_V1: NomTag := 'Class';
    NT_HANDICAP_V1: NomTag := 'Disability';
    NT_SORT_V1: NomTag := 'SpellV1';
    NT_EQUIPEMENT_V1: NomTag := 'EquipmentV1';
  else
    Exit;
  end;
  if not ConfirmerAbandonModifs then Exit;
  Code := GetNodeCode(Node);
  Lib := Node.Text;
  if NomTag = 'Career' then
    Definition := TrouverCareerElement(Code)
  else
    Definition := TrouverElementParId(NomTag, Code);
  if Definition = nil then Exit;

  Bloquants := TStringList.Create;
  Citations := TFPList.Create;
  try
    if NomTag <> 'Race' then
      CollecterReferences(XMLDoc.DocumentElement, Code, Definition, '', Bloquants, Citations)
    else
      CollecterReferences(XMLDoc.DocumentElement, Code, Definition, '', Bloquants, nil);
    if Bloquants.Count > 0 then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_400'), [Lib, StringReplace(Trim(Bloquants.Text), #13#10, ', ', [rfReplaceAll])]));
      Exit;
    end;
    if MessageDlg(Format(GetTexteLibelle('RULES-LAB_399'), [Lib, Citations.Count]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

    // l'element quitte les listes qui le citent (avec le commentaire qui suit)
    for I := 0 to Citations.Count - 1 do
    begin
      Ref := TDOMNode(Citations[I]);
      Pere := Ref.ParentNode;
      Suivant := Ref.NextSibling;
      while (Suivant <> nil) and (Suivant.NodeType = TEXT_NODE) and (Trim(Suivant.NodeValue) = '') do
        Suivant := Suivant.NextSibling;
      if (Suivant <> nil) and (Suivant.NodeType = COMMENT_NODE) then
        Pere.RemoveChild(Suivant);
      Pere.RemoveChild(Ref);
    end;
    Definition.ParentNode.RemoveChild(Definition);
    if NomTag = 'Condition' then
      SupprimerLibelleLivre(Code);

    // l'arbre suit le XML
    if NomTag = 'Career' then
    begin
      for I := 0 to TreeViewLivre.Items.Count - 1 do
      begin
        N := TreeViewLivre.Items[I];
        if GetNodeType(N) <> NT_CARRIERES_RACE then Continue;  // branche des carrieres d'une ethnie
        Specie := TrouverElementParId('Specie', GetNodeCode(N));
        if Specie = nil then Continue;
        N.DeleteChildren;
        RemplirNoeudCarrieres(Specie, N);
      end;
    end
    else if NomTag = 'Specie' then
    begin
      I := 0;
      while I < TreeViewLivre.Items.Count do
      begin
        N := TreeViewLivre.Items[I];
        if (GetNodeType(N) = NT_RACE_POSSIBLE) and (GetNodeCode(N) = Code) then
        begin
          if (N.Parent <> nil) and (N.Parent.Count = 1) then
            N.Parent.Delete  // la branche « races possibles » n'a plus de feuille
          else
            N.Delete;
          I := 0;  // les index ont bouge : on repart du debut
        end
        else
          Inc(I);
      end;
    end;
    Node := TreeViewLivre.Selected;
    if (Node <> nil) and (GetNodeCode(Node) = Code) and (GetNodeType(Node) in [NT_RACE, NT_METIER_NIVEAU1, NT_COMPETENCE_N1, NT_SPECIALISATION_COMPETENCE, NT_TALENT_N1, NT_SPECIALISATION_TALENT, NT_ARME, NT_ARMURE, NT_QUALITE_ARME, NT_QUALITE_ARMURE, NT_SORT, NT_TRAPPING, NT_FABRICATION, NT_NATION, NT_CORRUPTION_PHYSIQUE, NT_CORRUPTION_MENTALE, NT_MALADIE, NT_AFFLICTION, NT_RACE_GROUPE, NT_CONDITION, NT_SIGNE_ASTRAL, NT_BONUS_CARRIERE, NT_ADAPTATION_CARRIERE, NT_DIEU_V1, NT_CULTE_V1, NT_FAMILIER_V1, NT_CLASSE_V1, NT_HANDICAP_V1, NT_SORT_V1, NT_EQUIPEMENT_V1]) then
    begin
      MasquerForm();
      Node.Delete;
    end;
    ConstruireMetierRacesMap();
  finally
    Citations.Free;
    Bloquants.Free;
  end;
end;

procedure TWinLivres.MenuItemAjouterClick(Sender: TObject);
begin
  if NoeudEthnies(TreeViewLivre.Selected) <> nil then
    CreerEthnie
  else
    CreerCarriere;
end;

procedure TWinLivres.MenuItemModifierClick(Sender: TObject);
begin
  // À implémenter
end;

procedure TWinLivres.MenuItemSupprimerClick(Sender: TObject);
begin
  SupprimerSelection;
end;

// ========== LOAD SKILLS FOR RACE ==========
procedure TWinLivres.LoadSkillsForRace(RaceElement: TDOMElement; RaceCode: String);
var
  SkillChapter: TDOMNode;
  SkillElements: TDOMNodeList;
  I: Integer;
  SkillCode: String;
  SkillNode: TDOMNode;
begin
  RaceSkillsData.Clear;
  
  // Trouver SUBCHAPTER_SKILL
  SkillChapter := RaceElement.FindNode('SUBCHAPTER_SKILL');
  if SkillChapter = nil then Exit;
  
  if SkillChapter <> nil then
  begin
    SkillElements := SkillChapter.ChildNodes;
    
    for I := 0 to SkillElements.Count - 1 do
    begin
      SkillNode := SkillElements[I];
      if SkillNode.NodeName = 'Skill' then
      begin
        // Récupérer le code de la compétence (le texte du nœud)
        SkillCode := Trim(SkillNode.TextContent);
        // Enlever les guillemets si présents
        if (Length(SkillCode) > 0) and (SkillCode[1] = '"') then
          SkillCode := Copy(SkillCode, 2, Length(SkillCode) - 2);
        if (Length(SkillCode) > 0) and (SkillCode[Length(SkillCode)] = '"') then
          SkillCode := Copy(SkillCode, 1, Length(SkillCode) - 1);
        
        if SkillCode <> '' then
          RaceSkillsData.Add(SkillCode);
      end;
    end;
  end;
end;

// ========== LOAD CAREERS FOR RACE ==========
procedure TWinLivres.LoadCareersForRace(RaceElement: TDOMElement);
var
  CareerChapter: TDOMNode;
  CareerElements: TDOMNodeList;
  I: Integer;
  CareerCode, CareerValue: String;
  CareerNode: TDOMNode;
  CareerElement: TDOMElement;
begin
  RaceCareersData.Clear;
  
  // Trouver SUBCHAPTER_CAREER
  CareerChapter := RaceElement.FindNode('SUBCHAPTER_CAREER');
  if CareerChapter = nil then Exit;
  
  if CareerChapter <> nil then
  begin
    CareerElements := CareerChapter.ChildNodes;
    
    for I := 0 to CareerElements.Count - 1 do
    begin
      CareerNode := CareerElements[I];
      if CareerNode.NodeName = 'Career' then
      begin
        // Récupérer le code de la carrière (attribut name)
        CareerElement := TDOMElement(CareerNode);
        CareerCode := CareerElement.GetAttribute('name');
        
        // Récupérer la valeur (le texte du nœud)
        CareerValue := Trim(CareerNode.TextContent);
        // Enlever les guillemets si présents
        if (Length(CareerValue) > 0) and (CareerValue[1] = '"') then
          CareerValue := Copy(CareerValue, 2, Length(CareerValue) - 2);
        if (Length(CareerValue) > 0) and (CareerValue[Length(CareerValue)] = '"') then
          CareerValue := Copy(CareerValue, 1, Length(CareerValue) - 1);
        
        if CareerCode <> '' then
          RaceCareersData.Add(CareerCode + '|' + CareerValue);  // Format: Code|Valeur
      end;
    end;
  end;
end;

// ========== MASQUER/AFFICHER ELEMENTS - FONCTION CENTRALISEE ==========
procedure TWinLivres.MasquerAfficherElements(ElementType: String);
var
  I: Integer;
begin
  // Masquer tous les éléments par défaut
  ModeCorruption := False;
  ModeCarriere := False;
  StringGridSkills.Columns[4].Width := 0;
  if ModeNiveaux or ModeAttrCarriere or ModeEquipCarriere then
    for I := 0 to 2 do
      StringGridAttrEthnie.Columns[I].Width := AttrColW[I];
  ModeNiveaux := False;
  ModeAttrCarriere := False;
  ModeEquipCarriere := False;
  StringGridAttrEthnie.Width := 600;  // dimensions d'origine ; l'equipement d'une carriere agrandit le tableau
  StringGridAttrEthnie.Height := 330;
  MenuNivDebut.Visible := True;
  MenuEquipArme.Visible := False;
  MenuEquipArmure.Visible := False;
  MenuEquipDivers.Visible := False;
  StringGridAttrEthnie.Columns[3].Width := 0;
  StringGridAttrEthnie.Columns[4].Width := 0;  // nom feminin : seulement dans le tableau des niveaux
  LabelFormSkills.Visible := False;
  StringGridSkills.Visible := False;
  StringGridCareers.Visible := False;
  StringGridRaces.Visible := False;
  StringGridAttributs.Visible := False;
  StringGridCompetences.Visible := False;
  StringGridTalents.Visible := False;
  StringGridEquipement.Visible := False;
  StringGridDetail.Visible := False;
  StringGridQualites.Visible := False;
  PanelFiche.Visible := False;
  PanelTirage.Visible := False;
  PanelTirageRace.Visible := False;
  PanelEquipClasse.Visible := False;
  PanelTraitEthnie.Visible := False;
  PanelCarriereEspece.Visible := False;
  PanelRegleEthnie.Visible := False;
  PanelTraduction.Visible := False;
  PanelSousMetier.Visible := False;
  PanelTirageMetier.Visible := False;
  FicheSnapshot := '';
  MemoDetail.Visible := False;
  StringGridAttrEthnie.Visible := False;
  StringGridAttrSimples.Visible := False;
  StringGridAttrBlessures.Visible := False;
  LabelAttrBlessures.Visible := False;
  LabelTotalCareers.Visible := False;
  PanelAttrBoutons.Visible := False;
  if TreeViewTalents <> nil then
    TreeViewTalents.Visible := False;
  if LabelTalentsRandom <> nil then
    LabelTalentsRandom.Visible := False;
  
  // Afficher selon le type d'élément sélectionné
  case ElementType of
    'COMPETENCE':
      begin
        // Afficher compétences (StringGridSkills)
        LabelFormSkills.Visible := True;
        StringGridSkills.Visible := True;
        PanelAttrBoutons.Visible := True;  // Valider / Annuler, comme les attributs d'ethnie
        PanelAttrBoutons.Left := 940;  // a droite du grand tableau
        // Les autres grids restent masqués
      end;
    
    'CARRIERE', 'METIER':
      begin
        // Afficher métiers (StringGridCareers)
        LabelFormSkills.Visible := True;
        StringGridCareers.Visible := True;
        PanelAttrBoutons.Left := 940;
        // Les autres grids restent masqués
      end;
    
    'RACE':
      begin
        // Afficher les races (StringGridRaces).
        // Pas de LabelFormSkills ici : son libellé est 'Compétence de race',
        // hors sujet au-dessus d'une liste de races. Le titre vient de LabelFormTitle.
        StringGridRaces.Visible := True;
      end;
    
    'ATTRIBUT_METIER':
      begin
        // Grille des attributs d'un niveau de métier
        StringGridAttributs.Visible := True;
      end;
    
    'ATTRIBUT_ETHNIE':
      begin
        // Les trois tableaux des attributs d'une ethnie
        StringGridAttrEthnie.Visible := True;
        StringGridAttrSimples.Visible := True;
        StringGridAttrBlessures.Visible := True;
        LabelAttrBlessures.Visible := True;
        PanelAttrBoutons.Visible := True;
        PanelAttrBoutons.Left := 640;
      end;

    'COMPETENCE_METIER':
      begin
        // Grille des compétences d'un niveau de métier
        StringGridCompetences.Visible := True;
      end;
    
    'TALENT_METIER':
      begin
        // Grille des talents d'un niveau de métier
        StringGridTalents.Visible := True;
      end;
    
    'EQUIPEMENT_METIER':
      begin
        // Grille de l'équipement d'un niveau de métier
        StringGridEquipement.Visible := True;
      end;
    
    'DETAIL':
      begin
        // Grille clé/valeur : détail d'une arme ou d'une armure
        StringGridDetail.Visible := True;
      end;
    
    'TALENT':
      begin
        // Afficher talents (TreeViewTalents)
        if TreeViewTalents <> nil then
          TreeViewTalents.Visible := True;
        if LabelTalentsRandom <> nil then
          LabelTalentsRandom.Visible := True;
        // Les autres grids restent masqués
      end;
    
    else
      begin
        // RIEN: masquer tous les grids
        // (les Visible := False sont déjà appliqués ci-dessus)
      end;
  end;
end;

// ========== COMPETENCES D'UNE ETHNIE (EDITION) ==========
// Une ligne par <Skill> de l'ethnie (cochee), plus une ligne decochee par competence du
// catalogue absente de l'ethnie. Une meme competence peut avoir plusieurs lignes (plusieurs
// specialisations) ; un <Skill> "A/B" est un choix entre specialisations (on peut le remplacer
// par une seule specialisation de la liste ; le choix d'origine reste propose en tete). Cells : 1 = code du <Skill> (colonne cachee), 2 = competence,
// 3 = specialisation, 4 = case a cocher ('1'/'0').

// Code generique "XXX_*" d'un code de competence (un code sans specialisation se renvoie lui-meme).
function BaseCompetence(const Code: String): String;
var
  Premier: String;
  P: Integer;
begin
  Premier := Code;
  P := Pos('/', Premier);
  if P > 0 then
    Premier := Copy(Premier, 1, P - 1);
  Result := Premier;
  if ChercheCompetence(Premier).SousCompetence then
    Result := CodeGeneriqueDe(ChercheCompetence(Premier));
end;

// Specialisations d'une competence generique : libelles et codes en parallele.
procedure SpecsDe(const Base: String; Libelles, Codes: TStrings);
var
  I: Integer;
  Code: String;
begin
  Libelles.Clear;
  Codes.Clear;
  for I := 0 to ListCompetence.Count - 1 do
    if ListCompetence[I].SousCompetence then
    begin
      Code := ListCompetence[I].CodeCompetence;
      if CodeGeneriqueDe(ListCompetence[I]) = Base then
      begin
        Libelles.Add(ListCompetence[I].Libelle);
        Codes.Add(Code);
      end;
    end;
end;

function CompetenceASpecs(const Base: String): Boolean;
var
  Libs, Codes: TStringList;
begin
  Libs := TStringList.Create;
  Codes := TStringList.Create;
  try
    SpecsDe(Base, Libs, Codes);
    Result := Libs.Count > 0;
  finally
    Codes.Free;
    Libs.Free;
  end;
end;

// Talents : le generique est "RULES-T0139_*", ses specialisations "RULES-T0139_GOUT" ; un talent
// sans '_', un aleatoire (RULES-T*) ou un choix "A/B" est sa propre base.
function BaseTalent(const Code: String): String;
begin
  Result := Code;
  if (Code = 'RULES-T*') or (Pos('/', Code) > 0) then Exit;
  // un nom de talent contient des '_' : la famille est cherchee parmi les generiques declares
  if CodeFamilleTalent(Code) <> '' then
    Result := CodeFamilleTalent(Code);
end;

procedure SpecsTalent(const Base: String; Libelles, Codes: TStrings);
var
  I: Integer;
  Code, Prefixe: String;
begin
  if Copy(Base, Length(Base) - 1, 2) <> '_*' then Exit;
  Prefixe := Copy(Base, 1, Length(Base) - 1);
  for I := 0 to ListTalent.Count - 1 do
  begin
    Code := ListTalent[I].CodeTalent;
    if (Code <> Base) and (Pos('/', Code) = 0) and (Copy(Code, 1, Length(Prefixe)) = Prefixe) then
    begin
      Libelles.Add(ListTalent[I].Libelle);
      Codes.Add(Code);
    end;
  end;
end;

function TWinLivres.BaseLigne(const Code: String): String;
begin
  if ModeTalents then
    Result := BaseTalent(Code)
  else
    Result := BaseCompetence(Code);
end;

procedure TWinLivres.SpecsLigne(const Base: String; Libelles, Codes: TStrings);
begin
  if ModeTalents then
    SpecsTalent(Base, Libelles, Codes)
  else
    SpecsDe(Base, Libelles, Codes);
end;

function TWinLivres.LigneASpecs(const Base: String): Boolean;
var
  Libs, Codes: TStringList;
begin
  Libs := TStringList.Create;
  Codes := TStringList.Create;
  try
    SpecsLigne(Base, Libs, Codes);
    Result := Libs.Count > 0;
  finally
    Codes.Free;
    Libs.Free;
  end;
end;

// Remplit une ligne du tableau a partir du code d'un <Skill>.
procedure TWinLivres.RemplirLigneSkill(ARow: Integer; const Code: String; Coche: Boolean);
var
  Competence, Generique: StructureCompetence;
  Base, Spec, LibBase: String;
  Parts: TStringList;
  I: Integer;
begin
  Base := BaseCompetence(Code);
  Generique := ChercheCompetence(Base);
  Spec := '';
  if Pos('/', Code) > 0 then
  begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := '/';
      Parts.DelimitedText := Code;
      for I := 0 to Parts.Count - 1 do
      begin
        Competence := ChercheCompetence(Trim(Parts[I]));
        if Spec <> '' then Spec := Spec + ' / ';
        if Competence.CodeCompetence <> '' then
          Spec := Spec + Competence.Libelle
        else
          Spec := Spec + Trim(Parts[I]);
      end;
    finally
      Parts.Free;
    end;
  end
  else
  begin
    Competence := ChercheCompetence(Code);
    if Competence.CodeCompetence = '' then
      Spec := ''
    else if Competence.SousCompetence then
      Spec := Competence.Libelle
    else if Coche and (Code = Base) and CompetenceASpecs(Base) then
      Spec := GetTexteLibelle('RULES-LAB_127');  // generique : au choix
  end;

  StringGridSkills.Cells[1, ARow] := Code;
  if Generique.CodeCompetence <> '' then
    StringGridSkills.Cells[2, ARow] := Generique.Libelle
  else
  begin
    // generique WFRP1 « FAMILLE__* » : sa fiche porte l'id sans le « __* » (ex. RULES-COMP_SPEAK_LANGUAGE)
    LibBase := LibelleCodeV1(Base);
    if (LibBase = '') and (Copy(Base, Length(Base) - 2, 3) = '__*') then
      LibBase := LibelleCodeV1(Copy(Base, 1, Length(Base) - 3));
    if LibBase = '' then LibBase := Base;
    StringGridSkills.Cells[2, ARow] := LibBase;
  end;
  StringGridSkills.Cells[3, ARow] := Spec;
  if Coche then
    StringGridSkills.Cells[4, ARow] := '1'
  else
    StringGridSkills.Cells[4, ARow] := '0';
  // niveau (carriere) : efface si decochee, par defaut si coche sans niveau
  if not Coche then
    StringGridSkills.Cells[5, ARow] := ''
  else if ModeCarriere and (StringGridSkills.Cells[5, ARow] = '') then
    StringGridSkills.Cells[5, ARow] := NiveauParDefaut;
end;

// Codes des lignes cochees, dans l'ordre du tableau : une ligne decochee ne compte pas.
function TWinLivres.InstantaneSkills: String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to StringGridSkills.RowCount - 1 do
    if StringGridSkills.Cells[4, I] = '1' then
      Result := Result + StringGridSkills.Cells[1, I] + '@' + StringGridSkills.Cells[5, I] + '#';
end;

// Etat courant de l'ecran modifiable affiche (competences ou attributs d'une ethnie).
function TWinLivres.InstantaneCourant: String;
begin
  if StringGridSkills.Visible then
    Result := InstantaneSkills
  else if StringGridCareers.Visible then
    Result := InstantaneCareers
  else
    Result := InstantaneAttrEthnie(nil, 0, 0, '');
end;

procedure TWinLivres.AfficherSkillsForRace(RaceCode: String);
var
  RaceElement: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  I, RowIdx, P: Integer;
  Code: String;
  Presentes, Bases, Absentes: TStringList;
begin
  // Afficher compétences, masquer les autres éléments
  MasquerAfficherElements('COMPETENCE');
  ModeTalents := False;
  LabelFormSkills.Caption := GetTexteLibelle('RULES-LAB_087');

  // Masquer les contrôles de race et attributs
  LabelFormAttrName.Visible := False;
  EditFormAttrName.Visible := False;
  GroupBoxForm.Visible := False;

  AttrRaceCode := RaceCode;
  AttrSnapshot := '';
  MajBoutonsAttr(False);
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  MenuSkillAjouter.Caption := GetTexteLibelle('RULES-LAB_356');
  MenuSkillSupprimer.Caption := GetTexteLibelle('RULES-LAB_357');
  MenuSkillFusionner.Caption := GetTexteLibelle('RULES-LAB_360');
  MenuSkillScinder.Caption := GetTexteLibelle('RULES-LAB_361');
  MenuSkillRetirer.Caption := GetTexteLibelle('RULES-LAB_364');

  StringGridSkills.RowCount := 1;

  RaceElement := TrouverElementParId('Specie', RaceCode);
  if RaceElement = nil then Exit;

  Presentes := TStringList.Create;
  Bases := TStringList.Create;
  Absentes := TStringList.Create;
  try
    Absentes.Sorted := True;
    Absentes.Duplicates := dupAccept;

    // <Skill> de l'ethnie, dans l'ordre du XML
    Chapitre := RaceElement.FindNode('SUBCHAPTER_SKILL');
    if Chapitre <> nil then
    begin
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if Enfant.NodeName = 'Skill' then
        begin
          Code := ValeurXML(Enfant);
          if Code <> '' then
          begin
            Presentes.Add(Code);
            Bases.Add(BaseCompetence(Code));
          end;
        end;
        Enfant := Enfant.NextSibling;
      end;
    end;

    // Competences du catalogue absentes de l'ethnie (triees par libelle)
    for I := 0 to ListCompetence.Count - 1 do
      if not ListCompetence[I].SousCompetence then
        if Bases.IndexOf(ListCompetence[I].CodeCompetence) < 0 then
          Absentes.Add(ListCompetence[I].Libelle + '|' + ListCompetence[I].CodeCompetence);

    if Presentes.Count + Absentes.Count = 0 then
    begin
      MasquerAfficherElements('');
      Exit;
    end;

    StringGridSkills.RowCount := Presentes.Count + Absentes.Count + 1;
    RowIdx := 1;
    for I := 0 to Presentes.Count - 1 do
    begin
      RemplirLigneSkill(RowIdx, Presentes[I], True);
      Inc(RowIdx);
    end;
    for I := 0 to Absentes.Count - 1 do
    begin
      P := Pos('|', Absentes[I]);
      RemplirLigneSkill(RowIdx, Copy(Absentes[I], P + 1, Length(Absentes[I])), False);
      Inc(RowIdx);
    end;
  finally
    Absentes.Free;
    Bases.Free;
    Presentes.Free;
  end;

  AttrSnapshot := InstantaneSkills;
  MajBoutonsAttr(False);
end;

// Remplit une ligne du tableau a partir du code d'un <Talent> : aleatoire (RULES-T*), choix
// "A/B" (libelles joints par " / " en colonne 3) ou talent fixe.
procedure TWinLivres.RemplirLigneTalent(ARow: Integer; const Code: String; Coche: Boolean);
var
  Talent: StructureTalent;
  Parts: TStringList;
  I: Integer;
  Lib, Spec: String;
begin
  Spec := '';
  if Code = 'RULES-T*' then
    Lib := GetTexteLibelle('RULES-LAB_085')  // "Randomly"
  else if Pos('/', Code) > 0 then
  begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := '/';
      Parts.DelimitedText := Code;
      for I := 0 to Parts.Count - 1 do
      begin
        Talent := ChercheTalent(Trim(Parts[I]));
        if Spec <> '' then Spec := Spec + ' / ';
        if Talent.CodeTalent <> '' then
          Spec := Spec + Talent.Libelle
        else
          Spec := Spec + Trim(Parts[I]);
      end;
    finally
      Parts.Free;
    end;
    Lib := GetTexteLibelle('RULES-LAB_127');  // "au choix"
  end
  else
  begin
    Talent := ChercheTalent(Code);
    if Talent.CodeTalent <> '' then
      Lib := Talent.Libelle
    else
      Lib := Code;
    if Code <> BaseTalent(Code) then
    begin
      // specialisation : generique en colonne 2, libelle complet en colonne 3
      Spec := Lib;
      Lib := ChercheTalent(BaseTalent(Code)).Libelle;
      if Lib = '' then Lib := Spec;
    end
    else if Coche and LigneASpecs(Code) then
      Spec := GetTexteLibelle('RULES-LAB_127');  // generique : au choix
  end;
  StringGridSkills.Cells[1, ARow] := Code;
  StringGridSkills.Cells[2, ARow] := Lib;
  StringGridSkills.Cells[3, ARow] := Spec;
  if Coche then
    StringGridSkills.Cells[4, ARow] := '1'
  else
    StringGridSkills.Cells[4, ARow] := '0';
  // niveau (carriere) : efface si decochee, par defaut si coche sans niveau
  if not Coche then
    StringGridSkills.Cells[5, ARow] := ''
  else if ModeCarriere and (StringGridSkills.Cells[5, ARow] = '') then
    StringGridSkills.Cells[5, ARow] := NiveauParDefaut;
end;

// Talents d'une ethnie dans le tableau des competences (ModeTalents) : les <Talent> du XML dans
// l'ordre (coches), puis les talents du catalogue absents, decoches et tries par libelle.
procedure TWinLivres.AfficherTalentsEthnie(RaceCode: String);
var
  RaceElement: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  I, RowIdx, P: Integer;
  Code: String;
  Presentes, Absentes, Bases: TStringList;
begin
  MasquerAfficherElements('COMPETENCE');
  ModeTalents := True;
  LabelFormSkills.Caption := GetTexteLibelle('RULES-LAB_007');  // Talents

  LabelFormAttrName.Visible := False;
  EditFormAttrName.Visible := False;
  GroupBoxForm.Visible := False;

  AttrRaceCode := RaceCode;
  AttrSnapshot := '';
  MajBoutonsAttr(False);
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  MenuSkillAjouter.Caption := GetTexteLibelle('RULES-LAB_363');
  MenuSkillSupprimer.Caption := GetTexteLibelle('RULES-LAB_357');
  MenuSkillFusionner.Caption := GetTexteLibelle('RULES-LAB_360');
  MenuSkillScinder.Caption := GetTexteLibelle('RULES-LAB_361');
  MenuSkillRetirer.Caption := GetTexteLibelle('RULES-LAB_364');

  StringGridSkills.RowCount := 1;

  RaceElement := TrouverElementParId('Specie', RaceCode);
  if RaceElement = nil then Exit;

  Presentes := TStringList.Create;
  Absentes := TStringList.Create;
  Bases := TStringList.Create;
  try
    Absentes.Sorted := True;
    Absentes.Duplicates := dupAccept;

    Chapitre := RaceElement.FindNode('SUBCHAPTER_TALENT');
    if Chapitre <> nil then
    begin
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if Enfant.NodeName = 'Talent' then
        begin
          Code := ValeurXML(Enfant);
          if Code <> '' then Presentes.Add(Code);
        end;
        Enfant := Enfant.NextSibling;
      end;
    end;

    // Talents du catalogue absents de l'ethnie : les generiques et talents simples (les
    // specialisations se choisissent dans la liste de la ligne), sans choix "A/B" declares.
    // Une ligne "aleatoire" decochee permet d'en cocher un de plus.
    for I := 0 to Presentes.Count - 1 do
      Bases.Add(BaseTalent(Presentes[I]));
    for I := 0 to ListTalent.Count - 1 do
    begin
      Code := ListTalent[I].CodeTalent;
      if (Code = '') or (Code = 'RULES-T*') or (Pos('/', Code) > 0) then Continue;
      if Code <> BaseTalent(Code) then Continue;  // specialisation
      if Bases.IndexOf(Code) < 0 then
        Absentes.Add(ListTalent[I].Libelle + '|' + Code);
    end;
    // la ligne "aleatoire" decochee sert a en ajouter un : inutile (et trompeuse) hors livre modifiable
    if CreationPermise then
      Absentes.Add(GetTexteLibelle('RULES-LAB_085') + '|RULES-T*');

    if Presentes.Count + Absentes.Count = 0 then
    begin
      MasquerAfficherElements('');
      Exit;
    end;

    StringGridSkills.RowCount := Presentes.Count + Absentes.Count + 1;
    RowIdx := 1;
    for I := 0 to Presentes.Count - 1 do
    begin
      RemplirLigneTalent(RowIdx, Presentes[I], True);
      Inc(RowIdx);
    end;
    for I := 0 to Absentes.Count - 1 do
    begin
      P := Pos('|', Absentes[I]);
      RemplirLigneTalent(RowIdx, Copy(Absentes[I], P + 1, Length(Absentes[I])), False);
      Inc(RowIdx);
    end;
  finally
    Bases.Free;
    Absentes.Free;
    Presentes.Free;
  end;

  AttrSnapshot := InstantaneSkills;
  MajBoutonsAttr(False);
end;

// La specialisation est choisie dans une liste propre a la ligne ; les autres colonnes
// (la case a cocher se gere seule) ne s'editent pas. Un choix "A/B" propose son libelle
// d'origine puis les specialisations seules.
procedure TWinLivres.GridSkillsSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  Code: String;
  Libs, Codes: TStringList;
  N: Integer;
begin
  if ModeCarriere and (aCol = 5) then
  begin
    // niveau : liste de 1 au nombre de niveaux, seulement sur une ligne cochee
    if (aRow > 0) and (StringGridSkills.Cells[4, aRow] = '1') then
    begin
      Editor := StringGridSkills.EditorByStyle(cbsPickList);
      if Editor is TCustomComboBox then
      begin
        TCustomComboBox(Editor).Style := csDropDownList;
        TCustomComboBox(Editor).Items.Clear;
        for N := 1 to NbNiveauxCarriere do
          TCustomComboBox(Editor).Items.Add(IntToStr(N));
      end;
    end
    else
      Editor := nil;
    Exit;
  end;
  if aCol <> 3 then
  begin
    Editor := nil;
    Exit;
  end;
  Code := StringGridSkills.Cells[1, aRow];
  if Code = '' then
  begin
    Editor := nil;
    Exit;
  end;
  Libs := TStringList.Create;
  Codes := TStringList.Create;
  try
    SpecsLigne(BaseLigne(Code), Libs, Codes);
    if Libs.Count = 0 then
      Editor := nil
    else
    begin
      if Pos('/', Code) > 0 then
        Libs.Insert(0, StringGridSkills.Cells[3, aRow])  // le choix "A / B" d'origine
      else
        Libs.Insert(0, GetTexteLibelle('RULES-LAB_127'));  // generique : au choix
      Editor := StringGridSkills.EditorByStyle(cbsPickList);
      if Editor is TCustomComboBox then
      begin
        TCustomComboBox(Editor).Style := csDropDownList;
        TCustomComboBox(Editor).Items.Assign(Libs);
      end;
    end;
  finally
    Codes.Free;
    Libs.Free;
  end;
end;

// Choisir une specialisation remplace le code de la ligne (et la coche) ; le choix generique
// remet le code generique "XXX_*".
procedure TWinLivres.GridSkillsSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: string);
var
  Code, Base, NouveauCode: String;
  Libs, Codes: TStringList;
  I: Integer;
begin
  if ModeCarriere and (aCol = 5) and (aRow > 0) then
    StringGridSkills.Cells[5, aRow] := Value;  // la cellule n'est pas encore a jour
  if (aCol = 3) and (aRow > 0) then
  begin
    Code := StringGridSkills.Cells[1, aRow];
    if (Code <> '') and ((Pos('/', Code) = 0) or (Pos(' / ', Value) = 0)) then
    begin
      Base := BaseLigne(Code);
      NouveauCode := '';
      if (Value = '') or (Value = GetTexteLibelle('RULES-LAB_127')) then
        NouveauCode := Base
      else
      begin
        Libs := TStringList.Create;
        Codes := TStringList.Create;
        try
          SpecsLigne(Base, Libs, Codes);
          I := Libs.IndexOf(Value);
          if I >= 0 then
            NouveauCode := Codes[I];
        finally
          Codes.Free;
          Libs.Free;
        end;
      end;
      if NouveauCode <> '' then
      begin
        StringGridSkills.Cells[1, aRow] := NouveauCode;
        if NouveauCode <> Base then
        begin
          StringGridSkills.Cells[4, aRow] := '1';
          if ModeCarriere and (StringGridSkills.Cells[5, aRow] = '') then
            StringGridSkills.Cells[5, aRow] := NiveauParDefaut;
        end;
      end;
    end;
  end;
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

procedure TWinLivres.GridSkillsCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
var
  Code: String;
begin
  if aRow > 0 then
  begin
    Code := StringGridSkills.Cells[1, aRow];
    if ModeCarriere then
    begin
      // cocher donne le niveau affiche ; decocher l'efface
      if aState = cbChecked then
      begin
        if StringGridSkills.Cells[5, aRow] = '' then
          StringGridSkills.Cells[5, aRow] := NiveauParDefaut;
      end
      else
        StringGridSkills.Cells[5, aRow] := '';
    end;
    if (Code <> '') and (Pos('/', Code) = 0) and (Code = BaseLigne(Code)) and (Code <> 'RULES-T*') then
    begin
      // Ligne generique : "au choix" affiche seulement quand elle est cochee
      if aState = cbChecked then
      begin
        if (StringGridSkills.Cells[3, aRow] = '') and LigneASpecs(Code) then
          StringGridSkills.Cells[3, aRow] := GetTexteLibelle('RULES-LAB_127');
      end
      else if StringGridSkills.Cells[3, aRow] = GetTexteLibelle('RULES-LAB_127') then
        StringGridSkills.Cells[3, aRow] := '';
    end;
  end;
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

procedure TWinLivres.GridSkillsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  C, R, I: Integer;
  Code: String;
  Item: TMenuItem;
  Parts: TStringList;
begin
  StringGridSkills.MouseToCell(MousePos.X, MousePos.Y, C, R);
  RowSkillCtx := R;
  Handled := R < 1;  // hors des lignes : pas de menu
  if not Handled then
  begin
    Code := StringGridSkills.Cells[1, R];
    if ModeTalents and (Code = 'RULES-T*') then
    begin
      MenuSkillAjouter.Caption := GetTexteLibelle('RULES-LAB_363');  // un talent aleatoire de plus
      MenuSkillAjouter.Enabled := True;
    end
    else
    begin
      MenuSkillAjouter.Caption := GetTexteLibelle('RULES-LAB_356');
      MenuSkillAjouter.Enabled := (Code <> '') and (Pos('/', Code) = 0) and LigneASpecs(BaseLigne(Code));
    end;
    MenuSkillSupprimer.Enabled := True;
    // Sous-menu : une entree par autre competence cochee (la ligne choisie est fondue dans celle-ci)
    MenuSkillFusionner.Clear;
    if (Code <> '') and (Code <> 'RULES-T*') and (StringGridSkills.Cells[4, R] = '1') then
      for I := 1 to StringGridSkills.RowCount - 1 do
        if (I <> R) and (StringGridSkills.Cells[4, I] = '1') and (StringGridSkills.Cells[1, I] <> '')
          and (StringGridSkills.Cells[1, I] <> 'RULES-T*') then
        begin
          Item := TMenuItem.Create(MenuSkillFusionner);
          Item.Caption := Trim(StringGridSkills.Cells[2, I] + ' ' + StringGridSkills.Cells[3, I]);
          Item.Tag := I;
          Item.OnClick := @MenuSkillFusionnerClick;
          MenuSkillFusionner.Add(Item);
        end;
    MenuSkillFusionner.Enabled := MenuSkillFusionner.Count > 0;
    MenuSkillScinder.Enabled := Pos('/', Code) > 0;
    // Sous-menu : une entree par option du choix "A/B/C" (Tag = rang de l'option)
    MenuSkillRetirer.Clear;
    if Pos('/', Code) > 0 then
    begin
      Parts := TStringList.Create;
      try
        Parts.StrictDelimiter := True;
        Parts.Delimiter := '/';
        Parts.DelimitedText := Code;
        for I := 0 to Parts.Count - 1 do
        begin
          Item := TMenuItem.Create(MenuSkillRetirer);
          if ModeTalents then
            Item.Caption := ChercheTalent(Trim(Parts[I])).Libelle
          else
            Item.Caption := ChercheCompetence(Trim(Parts[I])).Libelle;
          if Item.Caption = '' then Item.Caption := Trim(Parts[I]);
          Item.Tag := I;
          Item.OnClick := @MenuSkillRetirerClick;
          MenuSkillRetirer.Add(Item);
        end;
      finally
        Parts.Free;
      end;
    end;
    MenuSkillRetirer.Enabled := MenuSkillRetirer.Count > 0;
  end;
end;

// Nouvelle ligne decochee de la meme competence, juste dessous, pour une autre specialisation.
procedure TWinLivres.MenuSkillAjouterClick(Sender: TObject);
var
  Base: String;
begin
  if (RowSkillCtx < 1) or (RowSkillCtx >= StringGridSkills.RowCount) then Exit;
  FermerEditeursAttr;
  Base := BaseLigne(StringGridSkills.Cells[1, RowSkillCtx]);
  StringGridSkills.InsertColRow(False, RowSkillCtx + 1);
  if ModeTalents then
    RemplirLigneTalent(RowSkillCtx + 1, Base, Base = 'RULES-T*')  // aleatoire : coche d'emblee
  else
    RemplirLigneSkill(RowSkillCtx + 1, Base, False);
  StringGridSkills.Row := RowSkillCtx + 1;
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

// Supprime la ligne si la competence en a d'autres ; sinon la decoche simplement.
procedure TWinLivres.MenuSkillSupprimerClick(Sender: TObject);
var
  Base: String;
  I, N: Integer;
begin
  if (RowSkillCtx < 1) or (RowSkillCtx >= StringGridSkills.RowCount) then Exit;
  FermerEditeursAttr;
  Base := BaseLigne(StringGridSkills.Cells[1, RowSkillCtx]);
  N := 0;
  for I := 1 to StringGridSkills.RowCount - 1 do
    if BaseLigne(StringGridSkills.Cells[1, I]) = Base then
      Inc(N);
  // un choix "A/B" disparait ; un aleatoire aussi tant qu'il en reste un autre
  if (N > 1) or (ModeTalents and (Pos('/', Base) > 0)) then
    StringGridSkills.DeleteRow(RowSkillCtx)
  else if ModeTalents then
    RemplirLigneTalent(RowSkillCtx, Base, False)
  else
    RemplirLigneSkill(RowSkillCtx, Base, False);
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

// Deux lignes cochees (la ligne cliquee et celle choisie dans le sous-menu, Tag = son numero)
// deviennent un seul choix "A/B" (OU), a la place de la ligne cliquee.
procedure TWinLivres.MenuSkillFusionnerClick(Sender: TObject);
var
  Autre, Cible: Integer;
  Fusion: String;
begin
  Autre := TMenuItem(Sender).Tag;
  Cible := RowSkillCtx;
  if (Cible < 1) or (Cible >= StringGridSkills.RowCount) or (Autre < 1)
    or (Autre >= StringGridSkills.RowCount) or (Autre = Cible) then Exit;
  if (StringGridSkills.Cells[4, Cible] <> '1') or (StringGridSkills.Cells[4, Autre] <> '1') then Exit;
  FermerEditeursAttr;
  Fusion := StringGridSkills.Cells[1, Cible] + '/' + StringGridSkills.Cells[1, Autre];
  StringGridSkills.DeleteRow(Autre);
  if Autre < Cible then
    Dec(Cible);
  if ModeTalents then
    RemplirLigneTalent(Cible, Fusion, True)
  else
    RemplirLigneSkill(Cible, Fusion, True);
  StringGridSkills.Row := Cible;
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

// Un choix "A/B" redevient une ligne cochee par option (plusieurs lignes = ET).
procedure TWinLivres.MenuSkillScinderClick(Sender: TObject);
var
  Parts: TStringList;
  I: Integer;
begin
  if (RowSkillCtx < 1) or (RowSkillCtx >= StringGridSkills.RowCount) then Exit;
  if Pos('/', StringGridSkills.Cells[1, RowSkillCtx]) = 0 then Exit;
  FermerEditeursAttr;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := '/';
    Parts.DelimitedText := StringGridSkills.Cells[1, RowSkillCtx];
    for I := Parts.Count - 1 downto 1 do
    begin
      StringGridSkills.InsertColRow(False, RowSkillCtx + 1);
      if ModeTalents then
        RemplirLigneTalent(RowSkillCtx + 1, Trim(Parts[I]), True)
      else
        RemplirLigneSkill(RowSkillCtx + 1, Trim(Parts[I]), True);
      StringGridSkills.Cells[5, RowSkillCtx + 1] := StringGridSkills.Cells[5, RowSkillCtx];
    end;
    if ModeTalents then
      RemplirLigneTalent(RowSkillCtx, Trim(Parts[0]), True)
    else
      RemplirLigneSkill(RowSkillCtx, Trim(Parts[0]), True);
  finally
    Parts.Free;
  end;
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

// Retire une option d'un choix "A/B/C" : elle devient une ligne cochee seule, sous le choix,
// qui garde les autres options (ou la derniere, devenue une ligne simple).
procedure TWinLivres.MenuSkillRetirerClick(Sender: TObject);
var
  Parts: TStringList;
  Retiree, Reste: String;
  I, Rang: Integer;
begin
  if (RowSkillCtx < 1) or (RowSkillCtx >= StringGridSkills.RowCount) then Exit;
  if Pos('/', StringGridSkills.Cells[1, RowSkillCtx]) = 0 then Exit;
  Rang := TMenuItem(Sender).Tag;
  FermerEditeursAttr;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := '/';
    Parts.DelimitedText := StringGridSkills.Cells[1, RowSkillCtx];
    if (Rang < 0) or (Rang >= Parts.Count) then Exit;
    Retiree := Trim(Parts[Rang]);
    Parts.Delete(Rang);
    Reste := '';
    for I := 0 to Parts.Count - 1 do
    begin
      if Reste <> '' then Reste := Reste + '/';
      Reste := Reste + Trim(Parts[I]);
    end;
  finally
    Parts.Free;
  end;
  StringGridSkills.InsertColRow(False, RowSkillCtx + 1);
  if ModeTalents then
  begin
    RemplirLigneTalent(RowSkillCtx + 1, Retiree, True);
    RemplirLigneTalent(RowSkillCtx, Reste, True);
  end
  else
  begin
    RemplirLigneSkill(RowSkillCtx + 1, Retiree, True);
    RemplirLigneSkill(RowSkillCtx, Reste, True);
  end;
  StringGridSkills.Cells[5, RowSkillCtx + 1] := StringGridSkills.Cells[5, RowSkillCtx];
  MajBoutonsAttr(InstantaneSkills <> AttrSnapshot);
end;

// Reecrit SUBCHAPTER_SKILL de l'ethnie d'apres les lignes cochees (memoire seulement).
// Les <Skill> inchanges sont reutilises tels quels ; rien n'est touche si la liste est identique.
procedure TWinLivres.ValiderCompetencesEthnie;
var
  RaceElement: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  Element: TDOMElement;
  Nouveaux, Anciens: TStringList;
  Originaux, Finaux: TList;
  I, J: Integer;
  Code: String;
  Identique: Boolean;
  Noeud: TTreeNode;
  NomChapitre, NomElement: String;
  TypeNoeud: Integer;
begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  if ModeTalents then
  begin
    NomChapitre := 'SUBCHAPTER_TALENT';
    NomElement := 'Talent';
    TypeNoeud := 5;
  end
  else
  begin
    NomChapitre := 'SUBCHAPTER_SKILL';
    NomElement := 'Skill';
    TypeNoeud := 3;
  end;
  RaceElement := TrouverElementParId('Specie', AttrRaceCode);
  if RaceElement = nil then Exit;

  Nouveaux := TStringList.Create;
  Anciens := TStringList.Create;
  Originaux := TList.Create;
  Finaux := TList.Create;
  try
    Nouveaux.CaseSensitive := True;
    Anciens.CaseSensitive := True;

    // ---- 1. Validation : une meme competence ne peut etre cochee deux fois ----
    for I := 1 to StringGridSkills.RowCount - 1 do
    begin
      Code := Trim(StringGridSkills.Cells[1, I]);
      if (StringGridSkills.Cells[4, I] <> '1') or (Code = '') then Continue;
      if (Nouveaux.IndexOf(Code) >= 0) and (Code <> 'RULES-T*') then
      begin
        MajBoutonsAttr(True);
        if not TestSansMessage then
        begin
          if ModeTalents then
            ShowMessage(GetTexteLibelle('RULES-LAB_362'))
          else
            ShowMessage(GetTexteLibelle('RULES-LAB_358'));
        end;
        StringGridSkills.Row := I;
        Exit;
      end;
      Nouveaux.Add(Code);
    end;

    // ---- 2. Ecriture ----
    Chapitre := RaceElement.FindNode(NomChapitre);
    if Chapitre = nil then
    begin
      if Nouveaux.Count > 0 then
        Chapitre := RaceElement.AppendChild(XMLDoc.CreateElement(NomChapitre));
    end;

    if Chapitre <> nil then
    begin
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if Enfant.NodeName = NomElement then
        begin
          Originaux.Add(Enfant);
          Anciens.AddObject(ValeurXML(Enfant), Enfant);
        end;
        Enfant := Enfant.NextSibling;
      end;

      Identique := Anciens.Count = Nouveaux.Count;
      if Identique then
        for I := 0 to Nouveaux.Count - 1 do
          if Anciens[I] <> Nouveaux[I] then
            Identique := False;

      if not Identique then
      begin
        for I := 0 to Nouveaux.Count - 1 do
        begin
          J := Anciens.IndexOf(Nouveaux[I]);
          if J >= 0 then
          begin
            Finaux.Add(Anciens.Objects[J]);
            Anciens[J] := '';  // consomme : un code vide n'est jamais cherche
          end
          else
          begin
            Element := XMLDoc.CreateElement(NomElement);
            EcrireValeurXML(Element, Nouveaux[I]);
            Finaux.Add(Element);
          end;
        end;
        for I := 0 to Originaux.Count - 1 do
          Chapitre.RemoveChild(TDOMNode(Originaux[I]));
        for I := 0 to Finaux.Count - 1 do
          Chapitre.AppendChild(TDOMNode(Finaux[I]));

        // ---- 3. Les noeuds de l'arbre suivent le XML ----
        Noeud := NodeSelectionnee;
        if (Noeud <> nil) and (GetNodeType(Noeud) = TypeNoeud) then
        begin
          Noeud.DeleteChildren;
          Enfant := Chapitre.FirstChild;
          while Enfant <> nil do
          begin
            if Enfant.NodeName = NomElement then
            begin
              if ModeTalents then
                AjouterNoeudTalent(Noeud, ValeurXML(Enfant))
              else
                AjouterNoeudSkill(Noeud, ValeurXML(Enfant));
            end;
            Enfant := Enfant.NextSibling;
          end;
        end;
      end;
    end;
  finally
    Finaux.Free;
    Originaux.Free;
    Anciens.Free;
    Nouveaux.Free;
  end;

  if ModeTalents then
    AfficherTalentsEthnie(AttrRaceCode)
  else
    AfficherSkillsForRace(AttrRaceCode);
end;

// ========== NIVEAUX D'UNE CARRIERE ==========
// Un niveau existe s'il est declare dans SUBCHAPTER_LEVEL : le nombre de niveaux est le plus grand
// numero, le niveau minimum le plus petit (carriere avancee, p. ex. un niveau 3 a 5, ou une variante
// qui remplace le seul niveau 2). Tableau : N. (lecture seule), Nom, Palier du salaire, Montant.
procedure TWinLivres.AjouterLigneNiveau(ARow, Id: Integer; ModeleRow: Integer);
begin
  StringGridAttrEthnie.Cells[1, ARow] := IntToStr(Id);
  StringGridAttrEthnie.Cells[2, ARow] := '';
  StringGridAttrEthnie.Cells[5, ARow] := '';
  StringGridAttrEthnie.Cells[3, ARow] := StringGridAttrEthnie.Cells[3, ModeleRow];
  StringGridAttrEthnie.Cells[4, ARow] := StringGridAttrEthnie.Cells[4, ModeleRow];
end;

procedure TWinLivres.AfficherNiveauxCarriere(CareerCode: String);
var
  CareerElement: TDOMElement;
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  Niveau: TDOMElement;
  I, K, P, RowIdx: Integer;
  Salaire, Tier: String;
begin
  MasquerAfficherElements('ATTRIBUT_ETHNIE');
  ModeNiveaux := True;
  StringGridAttrSimples.Visible := False;
  StringGridAttrBlessures.Visible := False;
  LabelAttrBlessures.Visible := False;
  PanelAttrBoutons.Left := 640;
  GroupBoxForm.Visible := False;
  AttrRaceCode := CareerCode;
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  MenuNivFin.Caption := GetTexteLibelle('RULES-LAB_370');
  MenuNivDebut.Caption := GetTexteLibelle('RULES-LAB_371');
  MenuNivSupprimer.Caption := GetTexteLibelle('RULES-LAB_372');
  MenuNivDebut.Visible := True;

  StringGridAttrEthnie.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_019');  // Niv.
  StringGridAttrEthnie.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_014');  // Nom
  StringGridAttrEthnie.Columns[2].Title.Caption := GetTexteLibelle('RULES-LAB_145');  // Salaire
  StringGridAttrEthnie.Columns[3].Title.Caption := GetTexteLibelle('RULES-LAB_374');  // Montant
  StringGridAttrEthnie.Columns[0].Width := 70;
  StringGridAttrEthnie.Columns[1].Width := 250;
  StringGridAttrEthnie.Columns[2].Width := 120;
  StringGridAttrEthnie.Columns[3].Width := 80;
  StringGridAttrEthnie.Columns[4].Title.Caption := GetTexteLibelle('RULES-LAB_1004');  // Nom feminin
  StringGridAttrEthnie.Columns[4].Width := 200;
  StringGridAttrEthnie.RowCount := 1;
  AttrSnapshot := '';
  MajBoutonsAttr(False);

  CareerElement := TrouverCareerElement(CareerCode);
  if CareerElement = nil then Exit;
  Chapitre := CareerElement.FindNode('SUBCHAPTER_LEVEL');
  if Chapitre = nil then Exit;
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Level');
  StringGridAttrEthnie.RowCount := Elements.Count + 1;
  RowIdx := 1;
  for I := 0 to Elements.Count - 1 do
  begin
    Niveau := TDOMElement(Elements.Item[I]);
    Salaire := ValeurXML(Niveau.FindNode('Salary'));  // "TIERS_SILVER 3"
    P := Pos(' ', Salaire);
    if P > 0 then
      Tier := Copy(Salaire, 1, P - 1)
    else
      Tier := Salaire;
    StringGridAttrEthnie.Cells[1, RowIdx] := Niveau.GetAttribute('id');
    StringGridAttrEthnie.Cells[2, RowIdx] := ValeurXML(Niveau.FindNode('Description'));
    StringGridAttrEthnie.Cells[5, RowIdx] := ValeurXML(Niveau.FindNode('DescriptionFeminine'));
    StringGridAttrEthnie.Cells[3, RowIdx] := Tier;
    for K := 0 to 2 do
      if TiersSalaire[K] = Tier then
        StringGridAttrEthnie.Cells[3, RowIdx] := GetTexteLibelle('RULES-' + Tier);
    if P > 0 then
      StringGridAttrEthnie.Cells[4, RowIdx] := Trim(Copy(Salaire, P + 1, Length(Salaire)))
    else
      StringGridAttrEthnie.Cells[4, RowIdx] := '';
    Inc(RowIdx);
  end;
  StringGridAttrEthnie.RowCount := RowIdx;
  AttrSnapshot := InstantaneAttrEthnie(nil, 0, 0, '');
  MajBoutonsAttr(False);
end;

procedure TWinLivres.GridAttrEthnieContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  C, R: Integer;
begin
  Handled := not (ModeNiveaux or ModeEquipCarriere);
  if Handled then Exit;
  StringGridAttrEthnie.MouseToCell(MousePos.X, MousePos.Y, C, R);
  RowNivCtx := R;
  if ModeEquipCarriere then
  begin
    MenuNivFin.Enabled := True;
    MenuNivSupprimer.Enabled := R >= 1;
    MenuEquipArme.Enabled := R >= 1;
    MenuEquipArmure.Enabled := R >= 1;
    MenuEquipDivers.Enabled := R >= 1;
    Exit;
  end;
  MenuNivFin.Enabled := (StringGridAttrEthnie.RowCount > 1) and
    (StrToIntDef(StringGridAttrEthnie.Cells[1, StringGridAttrEthnie.RowCount - 1], 9) < 9);
  MenuNivDebut.Enabled := (StringGridAttrEthnie.RowCount > 1) and
    (StrToIntDef(StringGridAttrEthnie.Cells[1, 1], 1) > 1);
  // on ne retire que le premier ou le dernier niveau, et jamais le seul
  MenuNivSupprimer.Enabled := (R >= 1) and (StringGridAttrEthnie.RowCount > 2) and
    ((R = 1) or (R = StringGridAttrEthnie.RowCount - 1));
end;

procedure TWinLivres.MenuNivFinClick(Sender: TObject);
var
  N: Integer;
begin
  FermerEditeursAttr;
  N := StringGridAttrEthnie.RowCount;
  if ModeEquipCarriere then
  begin
    // nouvel equipement : au niveau affiche s'il est declare, sinon au premier niveau
    StringGridAttrEthnie.RowCount := N + 1;
    StringGridAttrEthnie.Cells[1, N] := '';
    StringGridAttrEthnie.Cells[2, N] := '';
    StringGridAttrEthnie.Cells[3, N] := '1';
    if AttrNiveauxValides.IndexOf(IntToStr(NiveauCourantAffiche)) > 0 then
      StringGridAttrEthnie.Cells[4, N] := IntToStr(NiveauCourantAffiche)
    else if AttrNiveauxValides.Count > 1 then
      StringGridAttrEthnie.Cells[4, N] := AttrNiveauxValides[1];
    StringGridAttrEthnie.Row := N;
    StringGridAttrEthnie.Col := 2;
    MajBoutonsAttr(InstantaneAttrEthnie(nil, 0, 0, '') <> AttrSnapshot);
    Exit;
  end;
  if N < 2 then Exit;
  StringGridAttrEthnie.RowCount := N + 1;
  AjouterLigneNiveau(N, StrToIntDef(StringGridAttrEthnie.Cells[1, N - 1], 0) + 1, N - 1);
  StringGridAttrEthnie.Row := N;
  MajBoutonsAttr(InstantaneAttrEthnie(nil, 0, 0, '') <> AttrSnapshot);
end;

procedure TWinLivres.MenuNivDebutClick(Sender: TObject);
begin
  FermerEditeursAttr;
  if StringGridAttrEthnie.RowCount < 2 then Exit;
  StringGridAttrEthnie.InsertColRow(False, 1);
  AjouterLigneNiveau(1, StrToIntDef(StringGridAttrEthnie.Cells[1, 2], 2) - 1, 2);
  StringGridAttrEthnie.Row := 1;
  MajBoutonsAttr(InstantaneAttrEthnie(nil, 0, 0, '') <> AttrSnapshot);
end;

procedure TWinLivres.MenuNivSupprimerClick(Sender: TObject);
begin
  FermerEditeursAttr;
  if ModeEquipCarriere then
  begin
    if (RowNivCtx >= 1) and (RowNivCtx < StringGridAttrEthnie.RowCount) then
    begin
      StringGridAttrEthnie.DeleteRow(RowNivCtx);
      MajBoutonsAttr(InstantaneAttrEthnie(nil, 0, 0, '') <> AttrSnapshot);
    end;
    Exit;
  end;
  if (RowNivCtx < 1) or (RowNivCtx >= StringGridAttrEthnie.RowCount) or (StringGridAttrEthnie.RowCount < 3) then Exit;
  StringGridAttrEthnie.DeleteRow(RowNivCtx);
  MajBoutonsAttr(InstantaneAttrEthnie(nil, 0, 0, '') <> AttrSnapshot);
end;

// Ouvre la fenetre de selection de WinPersonnage (1 arme, 2 armure, 3 divers) ; '' si l'utilisateur annule.
function TWinLivres.ChoisirEquipementCatalogue(Genre: Integer): String;
var
  Choix: String;
  Fen: TForm;
begin
  SelectWinLivre := '';
  Choix := '';
  case Genre of
    1: begin
         SelectWinArme := ConstSelectionne;
         SelectWinArmeCompetences := '';
         Fen := TWinWeapons.Create(Application);
         Fen.Position := poOwnerFormCenter;
         Fen.ShowModal;
         Choix := ChoixWinArme;
         SelectWinArme := '';
         ChoixWinArme := '';
       end;
    2: begin
         SelectWinQuickArmor := False;
         SelectWinArmure := ConstSelectionne;
         Fen := TWinArmors.Create(Application);
         Fen.Position := poOwnerFormCenter;
         Fen.ShowModal;
         Choix := ChoixWinArmure;
         SelectWinArmure := '';
         ChoixWinArmure := '';
       end;
    3: begin
         SelectWinTrapping := ConstSelectionne;
         ModeEquipements := meTout;
         Fen := TWinEquipements.Create(Application);
         Fen.Position := poOwnerFormCenter;
         Fen.ShowModal;
         Choix := ChoixWinTrapping;
         SelectWinTrapping := '';
         ChoixWinTrapping := '';
       end;
  end;
  SelectWinLivre := '';
  Result := Choix;
end;

// Libelle d'un ensemble d'objets lies par '+' ("RULES-TRAP_004+RULES-TRAP_044") : chaque objet par son libelle.
function TWinLivres.LibelleEnsembleEquipement(const Nom: String): String;
var
  Parts: TStringList;
  J: Integer;
  TypeEquip: Char;
begin
  Result := '';
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := SeparateurEnsemble;
    Parts.DelimitedText := Nom;
    for J := 0 to Parts.Count - 1 do
    begin
      if J > 0 then Result := Result + ' ' + SeparateurEnsemble + ' ';
      Result := Result + LibelleEquipement(Trim(Parts[J]), TypeEquip);
    end;
  finally
    Parts.Free;
  end;
end;

// Choisit le code de la ligne dans la fenetre de selection de WinPersonnage (armes, armures ou divers) :
// le code choisi remplace le contenu de la cellule (un choix "A/B" se saisit a la main).
procedure TWinLivres.MenuEquipChoisirClick(Sender: TObject);
var
  Choix: String;
begin
  FermerEditeursAttr;
  if (RowNivCtx < 1) or (RowNivCtx >= StringGridAttrEthnie.RowCount) then Exit;
  Choix := ChoisirEquipementCatalogue(TMenuItem(Sender).Tag);
  if Choix = '' then Exit;
  StringGridAttrEthnie.Cells[2, RowNivCtx] := Choix;
  StringGridAttrEthnie.Cells[1, RowNivCtx] := LibelleLigneEquipement(Choix, StringGridAttrEthnie.Cells[3, RowNivCtx]);
  MajBoutonsAttr(InstantaneAttrEthnie(nil, 0, 0, '') <> AttrSnapshot);
end;

// Reecrit SUBCHAPTER_LEVEL d'apres le tableau (memoire seulement). Un niveau retire emporte les
// <Skill>, <Talent>, <Attribut> et <Item> de la carriere qui lui sont rattaches, apres confirmation.
procedure TWinLivres.ValiderNiveauxCarriere;
var
  CareerElement, Niveau: TDOMElement;
  Chapitre, Sous, Enfant: TDOMNode;
  Branche, Noeud: TTreeNode;
  Nouveaux, Anciens, Retires: TStringList;
  AEnlever, Elements: TList;
  I, J, K, N, Montant, Compte: Integer;
  Id, Nom, Code, Langue: String;
  Memes: Boolean;
const
  Chapitres: array[0..3] of String = ('SUBCHAPTER_SKILL', 'SUBCHAPTER_TALENT', 'SUBCHAPTER_ATTR', 'SUBCHAPTER_ITEM');

  procedure PoserSous(Parent: TDOMElement; const NomBalise, Valeur: String);
  var
    B: TDOMNode;
    E: TDOMElement;
  begin
    B := Parent.FindNode(NomBalise);
    if B = nil then
    begin
      E := XMLDoc.CreateElement(NomBalise);
      if NomBalise = 'Description' then
        E.SetAttribute('language', Langue);
      Parent.AppendChild(XMLDoc.CreateTextNode(#10));
      Parent.AppendChild(E);
      EcrireValeurXML(E, Valeur);
    end
    else if ValeurXML(B) <> Valeur then
      EcrireValeurXML(TDOMElement(B), Valeur);
  end;

  // Forme feminine du nom (balise facultative, juste apres Description, avant Salary) : posee si remplie, retiree si videe.
  procedure PoserFeminin(Parent: TDOMElement; const Valeur: String);
  var
    B, Salaire: TDOMNode;
    E: TDOMElement;
  begin
    B := Parent.FindNode('DescriptionFeminine');
    if B <> nil then
    begin
      if Valeur = '' then
        Parent.RemoveChild(B)
      else if ValeurXML(B) <> Valeur then
        EcrireValeurXML(TDOMElement(B), Valeur);
      Exit;
    end;
    if Valeur = '' then Exit;
    E := XMLDoc.CreateElement('DescriptionFeminine');
    E.SetAttribute('language', Langue);
    Salaire := Parent.FindNode('Salary');
    if Salaire <> nil then
    begin
      Parent.InsertBefore(E, Salaire);
      Parent.InsertBefore(XMLDoc.CreateTextNode(#10), Salaire);
    end
    else
    begin
      Parent.AppendChild(XMLDoc.CreateTextNode(#10));
      Parent.AppendChild(E);
    end;
    EcrireValeurXML(E, Valeur);
  end;

begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  CareerElement := TrouverCareerElement(AttrRaceCode);
  if CareerElement = nil then Exit;

  Nouveaux := TStringList.Create;  // "id|nom|tier|montant"
  Anciens := TStringList.Create;
  Retires := TStringList.Create;
  AEnlever := TList.Create;
  Elements := TList.Create;
  try
    Anciens.CaseSensitive := True;
    Retires.CaseSensitive := True;

    // ---- 1. Validation ----
    for I := 1 to StringGridAttrEthnie.RowCount - 1 do
    begin
      Nom := Trim(StringGridAttrEthnie.Cells[2, I]);
      K := -1;
      for J := 0 to 2 do
        if StringGridAttrEthnie.Cells[3, I] = GetTexteLibelle('RULES-' + TiersSalaire[J]) then
          K := J;
      if (Nom = '') or (K < 0) or not EntierPositif(StringGridAttrEthnie.Cells[4, I], Montant) or (Montant > 99) then
      begin
        MajBoutonsAttr(True);
        ShowMessage(GetTexteLibelle('RULES-LAB_375'));
        StringGridAttrEthnie.Row := I;
        Exit;
      end;
      Nouveaux.AddObject(Trim(StringGridAttrEthnie.Cells[1, I]), TObject(PtrInt(I)));
    end;
    if Nouveaux.Count = 0 then
    begin
      MajBoutonsAttr(True);
      Exit;
    end;

    Chapitre := CareerElement.FindNode('SUBCHAPTER_LEVEL');
    if Chapitre = nil then Exit;
    Langue := 'ENGLISH';
    Enfant := Chapitre.FirstChild;
    while Enfant <> nil do
    begin
      if Enfant.NodeName = 'Level' then
      begin
        Elements.Add(Enfant);
        Anciens.Add(TDOMElement(Enfant).GetAttribute('id'));
        Sous := Enfant.FindNode('Description');
        if (Sous <> nil) and (TDOMElement(Sous).GetAttribute('language') <> '') then
          Langue := TDOMElement(Sous).GetAttribute('language');
      end;
      Enfant := Enfant.NextSibling;
    end;

    // Niveaux retires : ce qui leur est rattache part avec eux (apres accord)
    for I := 0 to Anciens.Count - 1 do
      if Nouveaux.IndexOf(Anciens[I]) < 0 then
        Retires.Add(Anciens[I]);
    if Retires.Count > 0 then
    begin
      Compte := 0;
      for K := 0 to 3 do
      begin
        Sous := CareerElement.FindNode(Chapitres[K]);
        if Sous = nil then Continue;
        Enfant := Sous.FirstChild;
        while Enfant <> nil do
        begin
          if (Enfant.NodeType = ELEMENT_NODE) and (Retires.IndexOf(ValeurXML(Enfant)) >= 0) then
          begin
            AEnlever.Add(Enfant);
            Inc(Compte);
          end;
          Enfant := Enfant.NextSibling;
        end;
      end;
      if (Compte > 0) and (MessageDlg(Format(GetTexteLibelle('RULES-LAB_373'), [Compte]),
        mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
      begin
        MajBoutonsAttr(True);
        Exit;
      end;
      for I := 0 to AEnlever.Count - 1 do
        TDOMNode(AEnlever[I]).ParentNode.RemoveChild(TDOMNode(AEnlever[I]));
    end;

    // ---- 2. Ecriture : l'ordre et la liste des niveaux, puis nom et salaire ----
    Memes := Anciens.Count = Nouveaux.Count;
    if Memes then
      for I := 0 to Nouveaux.Count - 1 do
        if Anciens[I] <> Nouveaux[I] then
          Memes := False;
    if not Memes then
    begin
      AEnlever.Clear;
      for I := 0 to Nouveaux.Count - 1 do
      begin
        J := Anciens.IndexOf(Nouveaux[I]);
        if J >= 0 then
          Niveau := TDOMElement(TDOMNode(Elements[J]))
        else
        begin
          Niveau := XMLDoc.CreateElement('Level');
          Niveau.SetAttribute('id', Nouveaux[I]);
        end;
        AEnlever.Add(Niveau);  // liste finale, dans l'ordre du tableau
      end;
      while Chapitre.FirstChild <> nil do
        Chapitre.RemoveChild(Chapitre.FirstChild);
      for I := 0 to AEnlever.Count - 1 do
      begin
        Chapitre.AppendChild(XMLDoc.CreateTextNode(#10));
        Chapitre.AppendChild(TDOMNode(AEnlever[I]));
      end;
      Chapitre.AppendChild(XMLDoc.CreateTextNode(#10));
    end;
    for I := 0 to Nouveaux.Count - 1 do
    begin
      N := PtrInt(Nouveaux.Objects[I]);
      Id := Nouveaux[I];
      Niveau := nil;
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if (Enfant.NodeName = 'Level') and (TDOMElement(Enfant).GetAttribute('id') = Id) then
          Niveau := TDOMElement(Enfant);
        Enfant := Enfant.NextSibling;
      end;
      if Niveau = nil then Continue;
      Code := '';
      for J := 0 to 2 do
        if StringGridAttrEthnie.Cells[3, N] = GetTexteLibelle('RULES-' + TiersSalaire[J]) then
          Code := TiersSalaire[J];
      PoserSous(Niveau, 'Description', Trim(StringGridAttrEthnie.Cells[2, N]));
      PoserFeminin(Niveau, Trim(StringGridAttrEthnie.Cells[5, N]));
      PoserSous(Niveau, 'Salary', Code + ' ' + Trim(StringGridAttrEthnie.Cells[4, N]));
    end;

    // ---- 3. L'arbre : les noeuds niveau de la carriere sont refaits ----
    Branche := NodeSelectionnee;
    if (Branche <> nil) and (GetNodeType(Branche) = NT_NIVEAUX_CARRIERE) and (Branche.Parent <> nil) then
    begin
      Noeud := Branche.Parent;
      for I := Noeud.Count - 1 downto 0 do
        if GetNodeType(Noeud.Items[I]) = NT_NIVEAU_METIER then
          Noeud.Items[I].Delete;
      LoadMetierNiveaux(CareerElement, AttrRaceCode, Noeud);
    end;
  finally
    Elements.Free;
    AEnlever.Free;
    Retires.Free;
    Anciens.Free;
    Nouveaux.Free;
  end;
  AfficherNiveauxCarriere(AttrRaceCode);
end;

// ========== COMPETENCES ET TALENTS D'UNE CARRIERE (tous niveaux) ==========
// Meme tableau que pour une ethnie, avec une colonne Niv. (col 5). Lignes = les <Skill>/<Talent>
// de la carriere (coches, par niveau croissant), puis le catalogue decoche. CodeNiveau = "CARRIERE|n" ;
// n est le niveau donne aux lignes que l'on coche.
function TWinLivres.NiveauParDefaut: String;
var
  N: Integer;
begin
  N := NiveauCourantAffiche;
  if (N < 1) or (N > NbNiveauxCarriere) then N := 1;
  Result := IntToStr(N);
end;

procedure TWinLivres.AfficherCompetencesCarriere(CodeNiveau: String; Talents: Boolean);
var
  CareerElement: TDOMElement;
  Chapitre, Enfant, Niveaux: TDOMNode;
  PipePos, I, RowIdx, P, Rang: Integer;
  CareerCode, Code, NomElement: String;
  Tri, Presentes, Bases, Absentes: TStringList;
begin
  MasquerAfficherElements('COMPETENCE');
  ModeTalents := Talents;
  ModeCarriere := True;
  if Talents then
    LabelFormSkills.Caption := GetTexteLibelle('RULES-LAB_007')
  else
    LabelFormSkills.Caption := GetTexteLibelle('RULES-LAB_087');

  LabelFormAttrName.Visible := False;
  EditFormAttrName.Visible := False;
  GroupBoxForm.Visible := False;

  PipePos := Pos('|', CodeNiveau);
  if PipePos = 0 then Exit;
  CareerCode := Copy(CodeNiveau, 1, PipePos - 1);
  NiveauCourantAffiche := StrToIntDef(Copy(CodeNiveau, PipePos + 1, Length(CodeNiveau)), 0);
  AttrRaceCode := CareerCode;
  AttrCodeNiveau := CodeNiveau;
  AttrSnapshot := '';
  MajBoutonsAttr(False);
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  MenuSkillAjouter.Caption := GetTexteLibelle('RULES-LAB_356');
  MenuSkillSupprimer.Caption := GetTexteLibelle('RULES-LAB_357');
  MenuSkillFusionner.Caption := GetTexteLibelle('RULES-LAB_360');
  MenuSkillScinder.Caption := GetTexteLibelle('RULES-LAB_361');
  MenuSkillRetirer.Caption := GetTexteLibelle('RULES-LAB_364');

  StringGridSkills.RowCount := 1;
  StringGridSkills.Columns[4].Title.Caption := GetTexteLibelle('RULES-LAB_019');  // Niv.
  StringGridSkills.Columns[4].Width := 80;

  CareerElement := TrouverCareerElement(CareerCode);
  if CareerElement = nil then Exit;
  NbNiveauxCarriere := 1;
  Niveaux := CareerElement.FindNode('SUBCHAPTER_LEVEL');
  if Niveaux <> nil then
  begin
    NbNiveauxCarriere := TDOMElement(Niveaux).GetElementsByTagName('Level').Count;
    // carriere dont les niveaux ne partent pas de 1 (Stoneshaper : seul le niveau 2 est declare)
    for I := 0 to TDOMElement(Niveaux).GetElementsByTagName('Level').Count - 1 do
      if StrToIntDef(TDOMElement(TDOMElement(Niveaux).GetElementsByTagName('Level').Item[I]).GetAttribute('id'), 0) > NbNiveauxCarriere then
        NbNiveauxCarriere := StrToIntDef(TDOMElement(TDOMElement(Niveaux).GetElementsByTagName('Level').Item[I]).GetAttribute('id'), 0);
  end;
  if NbNiveauxCarriere < 1 then NbNiveauxCarriere := 1;

  if Talents then
  begin
    Chapitre := CareerElement.FindNode('SUBCHAPTER_TALENT');
    NomElement := 'Talent';
  end
  else
  begin
    Chapitre := CareerElement.FindNode('SUBCHAPTER_SKILL');
    NomElement := 'Skill';
  end;

  Tri := TStringList.Create;
  Presentes := TStringList.Create;
  Bases := TStringList.Create;
  Absentes := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupAccept;
    Absentes.Sorted := True;
    Absentes.Duplicates := dupAccept;

    // Elements de la carriere, par niveau croissant (le rang garde l'ordre du XML a niveau egal)
    if Chapitre <> nil then
    begin
      Rang := 0;
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if Enfant.NodeName = NomElement then
        begin
          Code := TDOMElement(Enfant).GetAttribute('name');
          if Code <> '' then
          begin
            Tri.Add(Format('%.2d|%.4d|%s', [StrToIntDef(ValeurXML(Enfant), 1), Rang, Code]));
            Inc(Rang);
          end;
        end;
        Enfant := Enfant.NextSibling;
      end;
    end;
    for I := 0 to Tri.Count - 1 do
    begin
      Code := Copy(Tri[I], 9, Length(Tri[I]));
      Presentes.AddObject(Code, TObject(PtrInt(StrToIntDef(Copy(Tri[I], 1, 2), 1))));
      if Talents then
        Bases.Add(BaseTalent(Code))
      else
        Bases.Add(BaseCompetence(Code));
    end;

    // Catalogue : ce qui n'est pas deja dans la carriere (les specialisations se choisissent sur la ligne)
    if Talents then
    begin
      for I := 0 to ListTalent.Count - 1 do
      begin
        Code := ListTalent[I].CodeTalent;
        if (Code = '') or (Code = 'RULES-T*') or (Pos('/', Code) > 0) then Continue;
        if Code <> BaseTalent(Code) then Continue;
        if Bases.IndexOf(Code) < 0 then
          Absentes.Add(ListTalent[I].Libelle + '|' + Code);
      end;
    end
    else
    begin
      for I := 0 to ListCompetence.Count - 1 do
        if not ListCompetence[I].SousCompetence then
          if Bases.IndexOf(ListCompetence[I].CodeCompetence) < 0 then
            Absentes.Add(ListCompetence[I].Libelle + '|' + ListCompetence[I].CodeCompetence);
    end;

    StringGridSkills.RowCount := Presentes.Count + Absentes.Count + 1;
    RowIdx := 1;
    for I := 0 to Presentes.Count - 1 do
    begin
      if Talents then
        RemplirLigneTalent(RowIdx, Presentes[I], True)
      else
        RemplirLigneSkill(RowIdx, Presentes[I], True);
      StringGridSkills.Cells[5, RowIdx] := IntToStr(PtrInt(Presentes.Objects[I]));
      Inc(RowIdx);
    end;
    for I := 0 to Absentes.Count - 1 do
    begin
      P := Pos('|', Absentes[I]);
      if Talents then
        RemplirLigneTalent(RowIdx, Copy(Absentes[I], P + 1, Length(Absentes[I])), False)
      else
        RemplirLigneSkill(RowIdx, Copy(Absentes[I], P + 1, Length(Absentes[I])), False);
      Inc(RowIdx);
    end;
  finally
    Absentes.Free;
    Bases.Free;
    Presentes.Free;
    Tri.Free;
  end;

  AttrSnapshot := InstantaneSkills;
  MajBoutonsAttr(False);
end;

// Reecrit SUBCHAPTER_SKILL / SUBCHAPTER_TALENT de la carriere d'apres les lignes cochees (memoire
// seulement) : par niveau croissant, un <Skill name="CODE">"niveau"</Skill> suivi de son commentaire.
// Les elements deja presents gardent leur commentaire ; rien n'est touche si la liste est identique.
procedure TWinLivres.ValiderCompetencesCarriere;
var
  CareerElement: TDOMElement;
  Chapitre, Enfant, Suivant, Commentaire: TDOMNode;
  Element: TDOMElement;
  NomChapitre, NomElement, Code: String;
  Tri, Vus, Anciens: TStringList;
  Elements, Commentaires, FElements, FCommentaires: TList;
  I, J, N, Niv: Integer;
  Identique, Principale: Boolean;
  NoeudNiveau, Branche: TTreeNode;
  TypeBranche: Integer;
  SkillPrincipal: String;

  function LibelleCode(const C: String): String;
  var
    Parts: TStringList;
    K: Integer;
    L: String;
  begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := '/';
      Parts.DelimitedText := C;
      Result := '';
      for K := 0 to Parts.Count - 1 do
      begin
        if ModeTalents then
          L := ChercheTalent(Trim(Parts[K])).Libelle
        else
          L := ChercheCompetence(Trim(Parts[K])).Libelle;
        if L = '' then L := Trim(Parts[K]);
        if Result <> '' then Result := Result + ' / ';
        Result := Result + L;
      end;
    finally
      Parts.Free;
    end;
  end;

begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  if ModeTalents then
  begin
    NomChapitre := 'SUBCHAPTER_TALENT';
    NomElement := 'Talent';
    TypeBranche := NT_BRANCHE_TALENT_NIVEAU;
  end
  else
  begin
    NomChapitre := 'SUBCHAPTER_SKILL';
    NomElement := 'Skill';
    TypeBranche := NT_BRANCHE_COMPETENCE_NIVEAU;
  end;
  CareerElement := TrouverCareerElement(AttrRaceCode);
  if CareerElement = nil then Exit;

  Tri := TStringList.Create;
  Vus := TStringList.Create;
  Anciens := TStringList.Create;
  Elements := TList.Create;
  Commentaires := TList.Create;
  FElements := TList.Create;
  FCommentaires := TList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupAccept;
    Vus.CaseSensitive := True;
    Anciens.CaseSensitive := True;

    // ---- 1. Validation : un niveau valide et pas de doublon ----
    for I := 1 to StringGridSkills.RowCount - 1 do
    begin
      Code := Trim(StringGridSkills.Cells[1, I]);
      if (StringGridSkills.Cells[4, I] <> '1') or (Code = '') then Continue;
      N := StrToIntDef(Trim(StringGridSkills.Cells[5, I]), 0);
      if (N < 1) or (N > NbNiveauxCarriere) then
      begin
        MajBoutonsAttr(True);
        ShowMessage(GetTexteLibelle('RULES-LAB_368'));
        StringGridSkills.Row := I;
        Exit;
      end;
      // une meme competence revient legitimement a deux niveaux (Duellist : Melee (*) en 1 et 4, Huffer : Lore (Local) en 1 et 3)
      if Vus.IndexOf(Code + '|' + IntToStr(N)) >= 0 then
      begin
        MajBoutonsAttr(True);
        if not TestSansMessage then
        begin
          if ModeTalents then
            ShowMessage(GetTexteLibelle('RULES-LAB_362'))
          else
            ShowMessage(GetTexteLibelle('RULES-LAB_358'));
        end;
        StringGridSkills.Row := I;
        Exit;
      end;
      Vus.Add(Code + '|' + IntToStr(N));
      Tri.Add(Format('%.2d|%.4d|%s', [N, I, Code]));
    end;

    // la competence principale de la carriere doit rester une competence cochee de niveau 1
    // (carriere a Parent : sa competence principale est celle de la carriere parente)
    if (not ModeTalents) and (CareerElement.FindNode('Parent') = nil) then
    begin
      Code := ValeurXML(CareerElement.FindNode('Skill'));
      Principale := False;
      for I := 0 to Tri.Count - 1 do
        // premier niveau de la carriere (Tri est trie) : il ne vaut pas toujours 1 (Stoneshaper commence au niveau 2)
        if (Copy(Tri[I], 1, 2) = Copy(Tri[0], 1, 2)) and (Copy(Tri[I], 9, Length(Tri[I])) = Code) then
          Principale := True
        // ou une des deux competences au choix d un niveau suivant (Doom Priest, Forge Priest : Lore (Theology) / Lore (Warfare) au niveau 2)
        else if Pos('/' + Code + '/', '/' + Copy(Tri[I], 9, Length(Tri[I])) + '/') > 0 then
          Principale := True;
      if (Code <> '') and not Principale then
      begin
        MajBoutonsAttr(True);
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_381'), [LibelleCode(Code)]));
        Exit;
      end;
    end;

    // ---- 2. Ecriture ----
    Chapitre := CareerElement.FindNode(NomChapitre);
    if Chapitre = nil then
    begin
      if Tri.Count > 0 then
        Chapitre := CareerElement.AppendChild(XMLDoc.CreateElement(NomChapitre));
    end;

    if Chapitre <> nil then
    begin
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if Enfant.NodeName = NomElement then
        begin
          // le commentaire qui suit l'element (en sautant les blancs) lui appartient
          Suivant := Enfant.NextSibling;
          while (Suivant <> nil) and (Suivant.NodeType = TEXT_NODE) and (Trim(Suivant.TextContent) = '') do
            Suivant := Suivant.NextSibling;
          if (Suivant <> nil) and (Suivant.NodeType = COMMENT_NODE) then
            Commentaires.Add(Suivant)
          else
            Commentaires.Add(nil);
          Elements.Add(Enfant);
          Anciens.Add(TDOMElement(Enfant).GetAttribute('name') + '@' + ValeurXML(Enfant));
        end;
        Enfant := Enfant.NextSibling;
      end;

      Identique := Anciens.Count = Tri.Count;
      if Identique then
        for I := 0 to Tri.Count - 1 do
          if Anciens[I] <> Copy(Tri[I], 9, Length(Tri[I])) + '@' + IntToStr(StrToInt(Copy(Tri[I], 1, 2))) then
            Identique := False;

      if not Identique then
      begin
        // Elements finaux : on reprend l'ancien (et son commentaire) quand le code existait deja
        Anciens.Clear;
        for I := 0 to Elements.Count - 1 do
          Anciens.AddObject(TDOMElement(TDOMNode(Elements[I])).GetAttribute('name'), TObject(PtrInt(I)));
        for I := 0 to Tri.Count - 1 do
        begin
          Code := Copy(Tri[I], 9, Length(Tri[I]));
          Niv := StrToInt(Copy(Tri[I], 1, 2));
          J := Anciens.IndexOf(Code);
          if J >= 0 then
          begin
            J := PtrInt(Anciens.Objects[J]);
            Element := TDOMElement(TDOMNode(Elements[J]));
            Commentaire := TDOMNode(Commentaires[J]);
            Anciens[Anciens.IndexOf(Code)] := '';  // consomme
          end
          else
          begin
            Element := XMLDoc.CreateElement(NomElement);
            Element.SetAttribute('name', Code);
            Commentaire := nil;
          end;
          if ValeurXML(Element) <> IntToStr(Niv) then
            EcrireValeurXML(Element, IntToStr(Niv));
          if Commentaire = nil then
            Commentaire := XMLDoc.CreateComment(' ' + LibelleCode(Code) + ' ');
          FElements.Add(Element);
          FCommentaires.Add(Commentaire);
        end;
        while Chapitre.FirstChild <> nil do
          Chapitre.RemoveChild(Chapitre.FirstChild);
        for I := 0 to FElements.Count - 1 do
        begin
          Chapitre.AppendChild(XMLDoc.CreateTextNode(#10));
          Chapitre.AppendChild(TDOMNode(FElements[I]));
          Chapitre.AppendChild(XMLDoc.CreateTextNode(#10 + '  '));
          Chapitre.AppendChild(TDOMNode(FCommentaires[I]));
        end;
        Chapitre.AppendChild(XMLDoc.CreateTextNode(#10));

        // ---- 3. L'arbre suit le XML : les feuilles de chaque niveau de la carriere, partout ou elle
        // apparait dans l'arbre (noeuds "niveau" de code "CARRIERE|n")
        SkillPrincipal := ValeurXML(CareerElement.FindNode('Skill'));
        for I := 0 to TreeViewLivre.Items.Count - 1 do
        begin
          NoeudNiveau := TreeViewLivre.Items[I];
          if GetNodeType(NoeudNiveau) <> NT_NIVEAU_METIER then Continue;
          Code := GetNodeCode(NoeudNiveau);
          if Copy(Code, 1, Length(AttrRaceCode) + 1) <> AttrRaceCode + '|' then Continue;
          Niv := StrToIntDef(Copy(Code, Pos('|', Code) + 1, Length(Code)), 0);
          for J := 0 to NoeudNiveau.Count - 1 do
          begin
            Branche := NoeudNiveau.Items[J];
            if GetNodeType(Branche) <> TypeBranche then Continue;
            Branche.DeleteChildren;
            if ModeTalents then
              RemplirBrancheNiveauTalents(Branche, Chapitre, Niv)
            else
              RemplirBrancheNiveauCompetences(Branche, Chapitre, Niv, SkillPrincipal);
          end;
        end;
      end;
    end;
  finally
    FCommentaires.Free;
    FElements.Free;
    Commentaires.Free;
    Elements.Free;
    Anciens.Free;
    Vus.Free;
    Tri.Free;
  end;

  AfficherCompetencesCarriere(AttrCodeNiveau, ModeTalents);
end;

// ========== AFFICHER TALENTS POUR RACE ==========
procedure TWinLivres.AfficherTalentsForRace();
var
  TalentNode, ChildNode, NodeTalent, ChildChoice, NodeChoice: TTreeNode;
  RandomCount, I, J: Integer;
begin
  // Afficher talents, masquer les autres éléments
  MasquerAfficherElements('TALENT');
  
  // Chercher le nœud "Talent" sélectionné ou parent
  TalentNode := nil;
  
  if NodeSelectionnee <> nil then
  begin
    // Si on a cliqué sur "Talent", c'est directement
    if Pos('Talent', NodeSelectionnee.Text) > 0 then
      TalentNode := NodeSelectionnee
    // Sinon, chercher le parent "Talent"
    else if NodeSelectionnee.Parent <> nil then
      TalentNode := NodeSelectionnee.Parent;
  end;
  
  if TalentNode = nil then
  begin
    // Pas de talents trouvés
    if LabelTalentsRandom <> nil then
      LabelTalentsRandom.Visible := False;
    if TreeViewTalents <> nil then
    begin
      LibererNodesData(TreeViewTalents);
      TreeViewTalents.Items.Clear;
    end;
    Exit;
  end;
  
  // Masquer les compétences
  LabelFormSkills.Visible := False;
  StringGridSkills.Visible := False;
  
  // Compter les talents aléatoires et remplir l'arbre
  RandomCount := 0;
  
  if TreeViewTalents <> nil then
  begin
    TreeViewTalents.Items.BeginUpdate;
    try
      LibererNodesData(TreeViewTalents);
      TreeViewTalents.Items.Clear;
      
      // Boucler sur les enfants du nœud Talent (TTreeView source)
      for I := 0 to TalentNode.Count - 1 do
      begin
        ChildNode := TalentNode.Items[I];
        
        if ChildNode <> nil then
        begin
          // CASE 1: Nœud "Choix" - afficher avec enfants
          if Pos(GetTexteLibelle('RULES-LAB_127'), ChildNode.Text) > 0 then
          begin
            NodeTalent := TreeViewTalents.Items.Add(nil, ChildNode.Text);
            SetNodeInfo(NodeTalent, NT_CHOIX_TALENT);  // 11 = choice node
            
            // Ajouter les enfants du choix
            for J := 0 to ChildNode.Count - 1 do
            begin
              ChildChoice := ChildNode.Items[J];
              if ChildChoice <> nil then
              begin
                NodeChoice := TreeViewTalents.Items.AddChild(NodeTalent, ChildChoice.Text);
                SetNodeInfo(NodeChoice, NT_CHOIX_ITEM);  // 12 = choice item
              end;
            end;
          end
          // CASE 2: Talent aléatoire - compter seulement (vérifier par Data)
          else if GetNodeType(ChildNode) = NT_TALENT_ALEATOIRE then
            Inc(RandomCount)
          // CASE 3: Talent fixe - ajouter directement
          else
          begin
            NodeTalent := TreeViewTalents.Items.Add(nil, ChildNode.Text);
            SetNodeInfo(NodeTalent, NT_TALENT_FIXE);  // 10 = talent node
          end;
        end;
      end;
    finally
      TreeViewTalents.Items.EndUpdate;
    end;
  end;
  
  // Afficher le nombre de talents aléatoires
  if LabelTalentsRandom <> nil then
  begin
    if RandomCount > 0 then
    begin
      LabelTalentsRandom.Caption := GetTexteLibelle('RULES-LAB_085') + ': ' + IntToStr(RandomCount);
      LabelTalentsRandom.BringToFront;
      LabelTalentsRandom.Visible := True;
    end
    else
      LabelTalentsRandom.Visible := False;
  end;
  
  // Afficher le TreeViewTalents
  if TreeViewTalents <> nil then
  begin
    TreeViewTalents.BringToFront;
    TreeViewTalents.Visible := True;
  end;
end;

// ========== ATTRIBUTS D'UNE CARRIERE (tous niveaux) ==========
// Les attributs de Warhammer sont un ensemble FERME : les dix sont toujours presents dans
// SUBCHAPTER_ATTR, chacun portant le niveau ou il est acquis (0 = jamais). Tableau : Attribut
// (lecture seule) et Niv. (liste 0 + niveaux declares). Le code est garde dans la colonne 3, masquee.
// CodeNiveau a la forme "RULES-WORK01|2" ; le niveau n'est qu'un point d'entree.
procedure TWinLivres.AfficherAttributsForNiveau(CodeNiveau: String);
var
  CareerElement: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  Elements: TDOMNodeList;
  I, RowIdx, PipePos: Integer;
  CareerCode, CodeAttr: String;
begin
  MasquerAfficherElements('ATTRIBUT_ETHNIE');
  ModeAttrCarriere := True;
  StringGridAttrSimples.Visible := False;
  StringGridAttrBlessures.Visible := False;
  LabelAttrBlessures.Visible := False;
  PanelAttrBoutons.Left := 640;
  GroupBoxForm.Visible := False;
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  StringGridAttrEthnie.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_008');  // Attribut
  StringGridAttrEthnie.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_019');  // Niv.
  StringGridAttrEthnie.Columns[0].Width := 250;
  StringGridAttrEthnie.Columns[1].Width := 80;
  StringGridAttrEthnie.Columns[2].Width := 0;
  StringGridAttrEthnie.RowCount := 1;
  AttrSnapshot := '';
  MajBoutonsAttr(False);

  // Decouper "CODEMETIER|niveau"
  PipePos := Pos('|', CodeNiveau);
  if PipePos = 0 then Exit;
  CareerCode := Copy(CodeNiveau, 1, PipePos - 1);
  NiveauCourantAffiche := StrToIntDef(Copy(CodeNiveau, PipePos + 1, Length(CodeNiveau)), 0);
  AttrRaceCode := CareerCode;
  AttrCodeNiveau := CodeNiveau;

  CareerElement := TrouverCareerElement(CareerCode);
  if CareerElement = nil then Exit;

  AttrNiveauxValides.Clear;
  AttrNiveauxValides.Add('0');
  Chapitre := CareerElement.FindNode('SUBCHAPTER_LEVEL');
  if Chapitre <> nil then
  begin
    Enfant := Chapitre.FirstChild;
    while Enfant <> nil do
    begin
      if Enfant.NodeName = 'Level' then
        AttrNiveauxValides.Add(TDOMElement(Enfant).GetAttribute('id'));
      Enfant := Enfant.NextSibling;
    end;
  end;

  Chapitre := CareerElement.FindNode('SUBCHAPTER_ATTR');
  if Chapitre = nil then Exit;
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Attribut');
  // Pas de tri : l'ordre du XML est l'ordre canonique de Warhammer
  // (CC, CT, F, E, I, Ag, Dex, Int, FM, Soc), plus parlant qu'un tri alphabetique.
  StringGridAttrEthnie.RowCount := Elements.Count + 1;
  RowIdx := 1;
  for I := 0 to Elements.Count - 1 do
  begin
    CodeAttr := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeAttr = '' then Continue;
    StringGridAttrEthnie.Cells[1, RowIdx] := GetAttributLabel(CodeAttr);
    StringGridAttrEthnie.Cells[2, RowIdx] := ValeurXML(Elements.Item[I]);
    StringGridAttrEthnie.Cells[3, RowIdx] := CodeAttr;
    Inc(RowIdx);
  end;
  StringGridAttrEthnie.RowCount := RowIdx;
  AttrSnapshot := InstantaneAttrEthnie(nil, 0, 0, '');
  MajBoutonsAttr(False);
end;

// Ecrit le niveau de chaque <Attribut> de la carriere (memoire seulement) et refait les feuilles
// de la branche Attribut de chaque niveau, partout ou la carriere apparait dans l'arbre.
procedure TWinLivres.ValiderAttributsCarriere;
var
  CareerElement: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  NoeudNiveau, Branche: TTreeNode;
  I, J, Niv: Integer;
  Code, Valeur: String;
begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  CareerElement := TrouverCareerElement(AttrRaceCode);
  if CareerElement = nil then Exit;
  Chapitre := CareerElement.FindNode('SUBCHAPTER_ATTR');
  if Chapitre = nil then Exit;

  // ---- 1. Validation : un niveau declare (ou 0) pour chaque ligne ----
  for I := 1 to StringGridAttrEthnie.RowCount - 1 do
    // carriere a Parent (Guild Engineer) : ses valeurs viennent des niveaux de la carriere parente, non declares ici
    if (AttrNiveauxValides.IndexOf(Trim(StringGridAttrEthnie.Cells[2, I])) < 0) and
       ((CareerElement.FindNode('Parent') = nil) or (StrToIntDef(Trim(StringGridAttrEthnie.Cells[2, I]), -1) < 0)) then
    begin
      MajBoutonsAttr(True);
      ShowMessage(GetTexteLibelle('RULES-LAB_368'));
      StringGridAttrEthnie.Row := I;
      Exit;
    end;

  // ---- 2. Ecriture : seulement ce qui change ----
  for I := 1 to StringGridAttrEthnie.RowCount - 1 do
  begin
    Code := StringGridAttrEthnie.Cells[3, I];
    Valeur := Trim(StringGridAttrEthnie.Cells[2, I]);
    Enfant := Chapitre.FirstChild;
    while Enfant <> nil do
    begin
      if (Enfant.NodeName = 'Attribut') and (TDOMElement(Enfant).GetAttribute('name') = Code) and
         (ValeurXML(Enfant) <> Valeur) then
        EcrireValeurXML(TDOMElement(Enfant), Valeur);
      Enfant := Enfant.NextSibling;
    end;
  end;

  // ---- 3. L'arbre suit le XML ----
  for I := 0 to TreeViewLivre.Items.Count - 1 do
  begin
    NoeudNiveau := TreeViewLivre.Items[I];
    if GetNodeType(NoeudNiveau) <> NT_NIVEAU_METIER then Continue;
    Code := GetNodeCode(NoeudNiveau);
    if Copy(Code, 1, Length(AttrRaceCode) + 1) <> AttrRaceCode + '|' then Continue;
    Niv := StrToIntDef(Copy(Code, Pos('|', Code) + 1, Length(Code)), 0);
    for J := 0 to NoeudNiveau.Count - 1 do
    begin
      Branche := NoeudNiveau.Items[J];
      if GetNodeType(Branche) <> NT_BRANCHE_ATTRIBUT_NIVEAU then Continue;
      Branche.DeleteChildren;
      RemplirBrancheNiveauAttributs(Branche, Chapitre, Niv);
    end;
  end;
  AfficherAttributsForNiveau(AttrCodeNiveau);
end;

// ========== AFFICHER LES ATTRIBUTS D'UNE ETHNIE ==========
// Trois tableaux, lus dans le <Specie> : les caracteristiques (nombre de D10 +
// valeur fixe), les quatre valeurs simples (Fate, Resilience, Points
// supplementaires, Mouvement) et les coefficients de la formule des Blessures.
// L'ordre du XML est conserve.
procedure TWinLivres.AfficherAttributsEthnie(RaceCode: String);
var
  RaceElement: TDOMElement;
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  I, RowCar, RowSimple, RowBless, J: Integer;
  CodeAttr, Famille, Valeur: String;
  AttrType, Dices, BaseValue, SimpleValue, Formula: String;
  Composants: TFormulaComponentArray;
begin
  MasquerAfficherElements('ATTRIBUT_ETHNIE');
  StringGridAttrSimples.Top := 395;  // AfficherCorruptionEthnie le remonte
  GroupBoxForm.Visible := False;
  AttrRaceCode := RaceCode;
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  AttrSnapshot := '';
  MajBoutonsAttr(False);

  LabelAttrBlessures.Caption := GetAttributLabel('RULES-ATTR_Wound');  // Points de vie
  StringGridAttrEthnie.RowCount := 1;
  StringGridAttrSimples.RowCount := 1;
  StringGridAttrBlessures.RowCount := 1;

  // Col 0 = vide (reservee Lazarus) : les titres de Columns[] sont decales d'un cran
  StringGridAttrEthnie.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_014');  // Nom
  StringGridAttrEthnie.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_344');  // Nombre de D10
  StringGridAttrEthnie.Columns[2].Title.Caption := GetTexteLibelle('RULES-LAB_345');  // Valeur fixe
  StringGridAttrSimples.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_014');
  StringGridAttrSimples.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_025');  // Valeur
  StringGridAttrBlessures.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_014');
  StringGridAttrBlessures.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_346');  // Coefficient

  RaceElement := TrouverElementParId('Specie', RaceCode);
  if RaceElement = nil then Exit;
  Chapitre := RaceElement.FindNode('SUBCHAPTER_ATTR');
  if Chapitre = nil then Exit;

  Elements := TDOMElement(Chapitre).GetElementsByTagName('Attribut');
  StringGridAttrEthnie.RowCount := Elements.Count + 1;
  StringGridAttrSimples.RowCount := Elements.Count + 1;
  StringGridAttrBlessures.RowCount := Elements.Count + 4;
  RowCar := 1;
  RowSimple := 1;
  RowBless := 1;

  for I := 0 to Elements.Count - 1 do
  begin
    CodeAttr := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeAttr = '' then Continue;
    Valeur := ValeurXML(Elements.Item[I]);

    Famille := ClasseAttributEthnie(CodeAttr);

    if Famille = 'BLESSURES' then
    begin
      ParseAttributValue(Valeur, AttrType, Dices, BaseValue, SimpleValue, Formula);
      Composants := ParseFormulaComponents(Formula);
      for J := 0 to Length(Composants) - 1 do
      begin
        StringGridAttrBlessures.Cells[1, RowBless] := Composants[J].AttrLabel;
        StringGridAttrBlessures.Cells[2, RowBless] := IntToStr(Composants[J].Coefficient);
        Inc(RowBless);
      end;
    end
    else if Famille = 'SIMPLE' then
    begin
      StringGridAttrSimples.Cells[1, RowSimple] := GetAttributLabel(CodeAttr);
      StringGridAttrSimples.Cells[2, RowSimple] := Valeur;
      Inc(RowSimple);
    end
    else
    begin
      ParseAttributValue(Valeur, AttrType, Dices, BaseValue, SimpleValue, Formula);
      StringGridAttrEthnie.Cells[1, RowCar] := GetAttributLabel(CodeAttr);
      if AttrType = 'DICES' then
      begin
        if Dices = '' then Dices := '1';  // "d10+20" = un seul D10
        StringGridAttrEthnie.Cells[2, RowCar] := Dices;
        StringGridAttrEthnie.Cells[3, RowCar] := BaseValue;
      end
      else
      begin
        // Format inattendu : valeur brute dans la colonne "fixe", rien dans les D10
        StringGridAttrEthnie.Cells[2, RowCar] := '';
        StringGridAttrEthnie.Cells[3, RowCar] := Valeur;
      end;
      Inc(RowCar);
    end;
  end;

  StringGridAttrEthnie.RowCount := RowCar;
  StringGridAttrSimples.RowCount := RowSimple;
  StringGridAttrBlessures.RowCount := RowBless;

  // Les tableaux vides (V2 : tout est dans le premier) ne servent a rien : on les masque.
  StringGridAttrSimples.Visible := StringGridAttrSimples.RowCount > 1;
  StringGridAttrBlessures.Visible := StringGridAttrBlessures.RowCount > 1;
  LabelAttrBlessures.Visible := StringGridAttrBlessures.Visible;

  AttrSnapshot := InstantaneAttrEthnie(nil, 0, 0, '');
  MajBoutonsAttr(False);
end;

// Les colonnes des valeurs (2 et suivantes) sont modifiables, la colonne du nom ne l'est pas.
procedure TWinLivres.GridAttrEthnieSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  K: Integer;
begin
  if (aCol < 2) or (ModeCorruption and (aRow <> 1)) then
    Editor := nil
  else if ModeEquipCarriere and (Sender = StringGridAttrEthnie) and (aCol = 4) then
  begin
    // niveau de l'equipement : un niveau declare de la carriere
    Editor := StringGridAttrEthnie.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
    begin
      TCustomComboBox(Editor).Style := csDropDownList;
      TCustomComboBox(Editor).Items.Assign(AttrNiveauxValides);
      if TCustomComboBox(Editor).Items.Count > 0 then
        TCustomComboBox(Editor).Items.Delete(0);  // pas de niveau 0 pour un equipement
    end;
  end
  else if ModeAttrCarriere and (Sender = StringGridAttrEthnie) and (aCol = 2) then
  begin
    // niveau d'acquisition : 0 (jamais) ou un niveau declare de la carriere
    Editor := StringGridAttrEthnie.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
    begin
      TCustomComboBox(Editor).Style := csDropDownList;
      TCustomComboBox(Editor).Items.Assign(AttrNiveauxValides);
    end;
  end
  else if ModeNiveaux and (Sender = StringGridAttrEthnie) and (aCol = 3) then
  begin
    // palier du salaire : liste Brass / Silver / Gold
    Editor := StringGridAttrEthnie.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
    begin
      TCustomComboBox(Editor).Style := csDropDownList;
      TCustomComboBox(Editor).Items.Clear;
      for K := 0 to 2 do
        TCustomComboBox(Editor).Items.Add(GetTexteLibelle('RULES-' + TiersSalaire[K]));
    end;
  end;
end;

// Contenu de toutes les cellules modifiables, mis bout a bout. Pendant la frappe, la
// cellule en cours d'edition n'est pas forcement a jour : on lui substitue Val.
function TWinLivres.InstantaneAttrEthnie(Substitue: TObject; aCol, aRow: Integer; const Val: String): String;
var
  Grilles: array[0..2] of TStringGrid;
  G, I, C: Integer;
  Cellule: String;
begin
  Grilles[0] := StringGridAttrEthnie;
  Grilles[1] := StringGridAttrSimples;
  Grilles[2] := StringGridAttrBlessures;
  Result := '';
  for G := 0 to 2 do
  begin
    for I := 1 to Grilles[G].RowCount - 1 do
      for C := 2 to Grilles[G].ColCount - 1 do
      begin
        if (Grilles[G] = Substitue) and (C = aCol) and (I = aRow) then
          Cellule := Val
        else
          Cellule := Grilles[G].Cells[C, I];
        Result := Result + Trim(Cellule) + '|';
      end;
    Result := Result + '#';
  end;
end;

// Valider et Annuler ne servent que s'il y a quelque chose a valider ou a annuler.
procedure TWinLivres.MajBoutonsAttr(Modifie: Boolean);
begin
  // TBCButton se grise tout seul quand Enabled = False
  ButtonAttrValider.Enabled := Modifie;
  ButtonAttrAnnuler.Enabled := Modifie;
end;

procedure TWinLivres.GridAttrEthnieSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: string);
var
  P: Integer;
begin
  if ModeCorruption and (aRow = 1) and (aCol = 2) then
  begin
    // la corruption mentale suit : le complement a 100 (vide tant que la saisie n'est pas valide)
    if EntierPositif(Value, P) and (P <= 100) then
      StringGridAttrSimples.Cells[2, 2] := IntToStr(100 - P)
    else
      StringGridAttrSimples.Cells[2, 2] := '';
  end;
  if ModeEquipCarriere and (Sender = StringGridAttrEthnie) and (aCol in [2, 3]) and (aRow >= 1) then
  begin
    // le libelle resolu suit le code et la quantite en cours de saisie
    if aCol = 2 then
      StringGridAttrEthnie.Cells[1, aRow] := LibelleLigneEquipement(Value, StringGridAttrEthnie.Cells[3, aRow])
    else
      StringGridAttrEthnie.Cells[1, aRow] := LibelleLigneEquipement(StringGridAttrEthnie.Cells[2, aRow], Value);
  end;
  MajBoutonsAttr(InstantaneAttrEthnie(Sender, aCol, aRow, Value) <> AttrSnapshot);
end;

// Le bouton (TBCButton) ne prend pas le focus : un editeur de cellule reste ouvert pendant
// le clic. On le ferme avant de lire ou de recharger les cellules, sinon il reecrirait
// son ancienne saisie par-dessus.
procedure TWinLivres.FermerEditeursAttr;
begin
  StringGridAttrEthnie.EditorMode := False;
  StringGridAttrSimples.EditorMode := False;
  StringGridAttrBlessures.EditorMode := False;
  StringGridSkills.EditorMode := False;
  StringGridCareers.EditorMode := False;
end;

procedure TWinLivres.ButtonAttrAnnulerClick(Sender: TObject);
begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  if StringGridSkills.Visible then
  begin
    if ModeCarriere then
      AfficherCompetencesCarriere(AttrCodeNiveau, ModeTalents)
    else if ModeTalents then
      AfficherTalentsEthnie(AttrRaceCode)
    else
      AfficherSkillsForRace(AttrRaceCode);
    Exit;
  end;
  if StringGridCareers.Visible then
  begin
    AfficherCareersForRace(AttrRaceCode);
    Exit;
  end;
  if ModeEquipCarriere then
  begin
    AfficherEquipementForNiveau(AttrCodeNiveau);
    Exit;
  end;
  if ModeAttrCarriere then
  begin
    AfficherAttributsForNiveau(AttrCodeNiveau);
    Exit;
  end;
  if ModeNiveaux then
  begin
    AfficherNiveauxCarriere(AttrRaceCode);
    Exit;
  end;
  if ModeCorruption then
  begin
    AfficherCorruptionEthnie(AttrRaceCode);
    Exit;
  end;
  AfficherAttributsEthnie(AttrRaceCode);
end;

// Ecrit les valeurs des tableaux dans XMLDoc (memoire seulement, pas de disque).
// Valide tout avant d'ecrire quoi que ce soit ; ne touche que ce qui a change.
procedure TWinLivres.ButtonAttrValiderClick(Sender: TObject);
var
  RaceElement: TDOMElement;
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  Element: TDOMElement;
  I, J, N, F, RowCar, RowSimple, RowBless: Integer;
  CodeAttr, Famille, Ancien, Nouveau: String;
  AttrType, Dices, BaseValue, SimpleValue, Formula: String;
  Composants: TFormulaComponentArray;
  Changement: Boolean;
  Noeud: TTreeNode;
begin
  if StringGridSkills.Visible then
  begin
    if ModeCarriere then
      ValiderCompetencesCarriere
    else
      ValiderCompetencesEthnie;
    Exit;
  end;
  if StringGridCareers.Visible then
  begin
    ValiderCarrieresEthnie;
    Exit;
  end;
  if ModeEquipCarriere then
  begin
    ValiderEquipementCarriere;
    Exit;
  end;
  if ModeAttrCarriere then
  begin
    ValiderAttributsCarriere;
    Exit;
  end;
  if ModeNiveaux then
  begin
    ValiderNiveauxCarriere;
    Exit;
  end;
  if ModeCorruption then
  begin
    ValiderCorruptionEthnie;
    Exit;
  end;
  FermerEditeursAttr;
  MajBoutonsAttr(False);  // grise des le clic : preuve visible que le clic est recu
  RaceElement := TrouverElementParId('Specie', AttrRaceCode);
  if RaceElement = nil then Exit;
  Chapitre := RaceElement.FindNode('SUBCHAPTER_ATTR');
  if Chapitre = nil then Exit;

  // ---- 1. Validation : rien n'est ecrit si une cellule est invalide ----
  for I := 1 to StringGridAttrEthnie.RowCount - 1 do
  begin
    if Trim(StringGridAttrEthnie.Cells[2, I]) = '' then Continue;  // format inattendu : conserve tel quel
    if not EntierPositif(StringGridAttrEthnie.Cells[2, I], N) then
    begin
      MajBoutonsAttr(True);
      if not TestSansMessage then ShowMessage(GetTexteLibelle('RULES-LAB_347'));
      StringGridAttrEthnie.Row := I;
      StringGridAttrEthnie.Col := 2;
      Exit;
    end;
    if not EntierPositif(StringGridAttrEthnie.Cells[3, I], N) then
    begin
      MajBoutonsAttr(True);
      if not TestSansMessage then ShowMessage(GetTexteLibelle('RULES-LAB_347'));
      StringGridAttrEthnie.Row := I;
      StringGridAttrEthnie.Col := 3;
      Exit;
    end;
  end;
  for I := 1 to StringGridAttrSimples.RowCount - 1 do
    if not EntierPositif(StringGridAttrSimples.Cells[2, I], N) then
    begin
      MajBoutonsAttr(True);
      if not TestSansMessage then ShowMessage(GetTexteLibelle('RULES-LAB_347'));
      StringGridAttrSimples.Row := I;
      StringGridAttrSimples.Col := 2;
      Exit;
    end;
  for I := 1 to StringGridAttrBlessures.RowCount - 1 do
    if not EntierPositif(StringGridAttrBlessures.Cells[2, I], N) then
    begin
      MajBoutonsAttr(True);
      if not TestSansMessage then ShowMessage(GetTexteLibelle('RULES-LAB_347'));
      StringGridAttrBlessures.Row := I;
      StringGridAttrBlessures.Col := 2;
      Exit;
    end;

  // ---- 2. Ecriture : meme parcours et meme classement que l'affichage ----
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Attribut');
  RowCar := 1;
  RowSimple := 1;
  RowBless := 1;
  Changement := False;

  for I := 0 to Elements.Count - 1 do
  begin
    Element := TDOMElement(Elements.Item[I]);
    CodeAttr := Element.GetAttribute('name');
    if CodeAttr = '' then Continue;
    Ancien := ValeurXML(Element);
    Famille := ClasseAttributEthnie(CodeAttr);

    if Famille = 'BLESSURES' then
    begin
      ParseAttributValue(Ancien, AttrType, Dices, BaseValue, SimpleValue, Formula);
      Composants := ParseFormulaComponents(Formula);
      Nouveau := '';
      Changement := False;
      for J := 0 to Length(Composants) - 1 do
      begin
        EntierPositif(StringGridAttrBlessures.Cells[2, RowBless], N);
        if N <> Composants[J].Coefficient then Changement := True;
        if Nouveau <> '' then Nouveau := Nouveau + '+';
        Nouveau := Nouveau + IntToStr(N) + 'x' + Composants[J].AttrCode;
        Inc(RowBless);
      end;
      if Changement then
        EcrireValeurXML(Element, Nouveau);
    end
    else if Famille = 'SIMPLE' then
    begin
      EntierPositif(StringGridAttrSimples.Cells[2, RowSimple], N);
      Nouveau := IntToStr(N);
      if Nouveau <> Ancien then
        EcrireValeurXML(Element, Nouveau);
      Inc(RowSimple);
    end
    else
    begin
      if Trim(StringGridAttrEthnie.Cells[2, RowCar]) <> '' then
      begin
        EntierPositif(StringGridAttrEthnie.Cells[2, RowCar], N);
        EntierPositif(StringGridAttrEthnie.Cells[3, RowCar], F);
        ParseAttributValue(Ancien, AttrType, Dices, BaseValue, SimpleValue, Formula);
        if Dices = '' then Dices := '1';
        if (AttrType <> 'DICES') or (IntToStr(N) <> Dices) or (IntToStr(F) <> BaseValue) then
        begin
          Nouveau := IntToStr(N) + 'd10';
          if F > 0 then Nouveau := Nouveau + '+' + IntToStr(F);
          EcrireValeurXML(Element, Nouveau);
        end;
      end;
      Inc(RowCar);
    end;
  end;

  // ---- 3. Le texte des noeuds d'attribut de l'arbre suit le XML ----
  Noeud := NodeSelectionnee;
  if (Noeud <> nil) and (GetNodeType(Noeud) = NT_ATTRIBUTS_ETHNIE) then
  begin
    J := 0;
    for I := 0 to Elements.Count - 1 do
    begin
      Element := TDOMElement(Elements.Item[I]);
      CodeAttr := Element.GetAttribute('name');
      if CodeAttr = '' then Continue;
      if J < Noeud.Count then
        Noeud.Items[J].Text := GetAttributLabel(CodeAttr) + ': ' + Element.TextContent;
      Inc(J);
    end;
  end;

  AfficherAttributsEthnie(AttrRaceCode);
end;

// ========== CORRUPTION D'UNE ETHNIE ==========
// Deux lignes (physique, mental) dans le tableau des valeurs simples : la tranche d100 de chaque
// <Specie name="..."> de DATA_CORRUPTION_PHYSICAL / _MENTAL, ou "-" (aucune). Ligne absente du XML :
// affichee "-" ; rien n'est cree si elle reste "-".
const
  ChapitresCorruption: array[0..1] of String = ('DATA_CORRUPTION_PHYSICAL', 'DATA_CORRUPTION_MENTAL');

function TrouverSpecieCorruption(Chap: Integer; const RaceCode: String; Racine: TDOMDocument): TDOMElement;
var
  Chapitres, Elements: TDOMNodeList;
  J: Integer;
begin
  Result := nil;
  Chapitres := Racine.GetElementsByTagName(ChapitresCorruption[Chap]);
  if Chapitres.Count = 0 then Exit;
  Elements := TDOMElement(Chapitres.Item[0]).GetElementsByTagName('Specie');
  for J := 0 to Elements.Count - 1 do
    if TDOMElement(Elements.Item[J]).GetAttribute('name') = RaceCode then
    begin
      Result := TDOMElement(Elements.Item[J]);
      Exit;
    end;
end;

// Un seul reglage : le pourcentage de corruption physique P (0 a 100). La corruption mentale
// en est deduite : physique = 01-P ("-" si P = 0), mental = P+1-100 ("-" si P = 100).
procedure TWinLivres.AfficherCorruptionEthnie(RaceCode: String);
var
  Element: TDOMElement;
  V, Fin: String;
  P: Integer;
begin
  MasquerAfficherElements('ATTRIBUT_ETHNIE');
  ModeCorruption := True;
  StringGridAttrEthnie.Visible := False;
  StringGridAttrBlessures.Visible := False;
  LabelAttrBlessures.Visible := False;
  StringGridAttrSimples.Visible := True;
  StringGridAttrSimples.Top := StringGridAttrEthnie.Top;
  PanelAttrBoutons.Left := 640;
  GroupBoxForm.Visible := False;
  AttrRaceCode := RaceCode;
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  StringGridAttrEthnie.RowCount := 1;
  StringGridAttrBlessures.RowCount := 1;
  StringGridAttrSimples.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_014');  // Nom
  StringGridAttrSimples.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_366');  // Pourcentage
  StringGridAttrSimples.RowCount := 3;
  StringGridAttrSimples.Cells[1, 1] := GetTexteLibelle('RULES-LAB_156') + ' (' + GetTexteLibelle('RULES-LAB_330') + ')';
  StringGridAttrSimples.Cells[1, 2] := GetTexteLibelle('RULES-LAB_156') + ' (' + GetTexteLibelle('RULES-LAB_331') + ')';
  P := 0;
  Element := nil;
  if XMLDoc <> nil then
    Element := TrouverSpecieCorruption(0, RaceCode, XMLDoc);
  if Element <> nil then
  begin
    V := ValeurXML(Element);  // "01-50" ou "-"
    Fin := Copy(V, Pos('-', V) + 1, Length(V));
    P := StrToIntDef(Trim(Fin), 0);
    if (P < 0) or (P > 100) then P := 0;
  end;
  StringGridAttrSimples.Cells[2, 1] := IntToStr(P);
  StringGridAttrSimples.Cells[2, 2] := IntToStr(100 - P);
  AttrSnapshot := InstantaneAttrEthnie(nil, 0, 0, '');
  MajBoutonsAttr(False);
end;

// Ecrit les deux tranches dans XMLDoc (memoire seulement). Entier hors 0-100 : rien n'est ecrit.
procedure TWinLivres.ValiderCorruptionEthnie;
var
  I, P: Integer;
  Norm: array[0..1] of String;
  Chapitres: TDOMNodeList;
  Element: TDOMElement;
begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  if not EntierPositif(StringGridAttrSimples.Cells[2, 1], P) or (P > 100) then
  begin
    MajBoutonsAttr(True);
    ShowMessage(GetTexteLibelle('RULES-LAB_365'));
    StringGridAttrSimples.Row := 1;
    StringGridAttrSimples.Col := 2;
    Exit;
  end;
  if P = 0 then Norm[0] := '-' else Norm[0] := Format('01-%.2d', [P]);
  if P = 100 then Norm[1] := '-' else Norm[1] := Format('%.2d-100', [P + 1]);
  for I := 0 to 1 do
  begin
    Element := TrouverSpecieCorruption(I, AttrRaceCode, XMLDoc);
    if Element <> nil then
    begin
      if ValeurXML(Element) <> Norm[I] then
        EcrireValeurXML(Element, Norm[I]);
    end
    else if Norm[I] <> '-' then
    begin
      Chapitres := XMLDoc.GetElementsByTagName(ChapitresCorruption[I]);
      if Chapitres.Count = 0 then Continue;
      Element := XMLDoc.CreateElement('Specie');
      Element.SetAttribute('name', AttrRaceCode);
      Chapitres.Item[0].AppendChild(Element);
      EcrireValeurXML(Element, Norm[I]);
    end;
  end;
  AfficherCorruptionEthnie(AttrRaceCode);
end;

// ========== AFFICHER COMPÉTENCES D'UN NIVEAU DE MÉTIER ==========
// Contrairement aux attributs, les compétences forment un ensemble OUVERT :
// une même compétence peut apparaître plusieurs fois avec des spécialisations
// différentes (Métier (Apothicaire) et Métier (Empoisonneur)). Les lignes
// viennent donc du XML et non de ListCompetence, sinon les doublons de
// spécialisation seraient impossibles à représenter.
// CodeNiveau a la forme "RULES-WORK01|2".
procedure TWinLivres.AfficherCompetencesForNiveau(CodeNiveau: String);
var
  CareerElement: TDOMElement;
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  I, RowIdx, PipePos: Integer;
  CareerCode, CodeComp, BaseCode, SkillPrincipal: String;
  ColComp, ColSpec: String;
  Competence, Generique: StructureCompetence;
begin
  MasquerAfficherElements('COMPETENCE_METIER');
  
  // Masquer les contrôles de saisie
  GroupBoxForm.Visible := False;
  
  // Découper "CODEMETIER|niveau"
  PipePos := Pos('|', CodeNiveau);
  if PipePos = 0 then Exit;
  
  CareerCode := Copy(CodeNiveau, 1, PipePos - 1);
  NiveauCourantAffiche := StrToIntDef(Copy(CodeNiveau, PipePos + 1, Length(CodeNiveau)), 0);
  
  CareerElement := TrouverCareerElement(CareerCode);
  if CareerElement = nil then Exit;
  
  Chapitre := CareerElement.FindNode('SUBCHAPTER_SKILL');
  if Chapitre = nil then Exit;
  
  // Compétence principale du métier, marquée d'une étoile comme dans l'arbre
  SkillPrincipal := ValeurXML(CareerElement.FindNode('Skill'));
  
  StringGridCompetences.RowCount := 1;
  
  // Col 0 = vide (réservé Lazarus)
  StringGridCompetences.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_001');  // Code
  StringGridCompetences.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_009');  // Compétence
  StringGridCompetences.Columns[2].Title.Caption := GetTexteLibelle('RULES-LAB_078');  // Spécialisation
  StringGridCompetences.Columns[3].Title.Caption := GetTexteLibelle('RULES-LAB_019');  // Niv.
  
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Skill');
  
  // Pas de tri : l'ordre du XML groupe déjà les compétences par niveau croissant.
  StringGridCompetences.RowCount := Elements.Count + 1;
  RowIdx := 1;
  
  for I := 0 to Elements.Count - 1 do
  begin
    CodeComp := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeComp = '' then Continue;
    
    Competence := ChercheCompetence(CodeComp);
    
    if Competence.CodeCompetence = '' then
    begin
      // Compétence inconnue : on montre au moins le code
      ColComp := CodeComp;
      ColSpec := '';
    end
    else if Competence.SousCompetence then
    begin
      // Spécialisation : remonter à la compétence générique "XXX_*"
      BaseCode := CodeGeneriqueDe(Competence);

      Generique := ChercheCompetence(BaseCode);
      if Generique.CodeCompetence <> '' then
        ColComp := Generique.Libelle
      else
        ColComp := BaseCode;
      
      ColSpec := Competence.Libelle;
    end
    else
    begin
      // Compétence sans spécialisation
      ColComp := Competence.Libelle;
      ColSpec := '';
    end;
    
    if CodeComp = SkillPrincipal then
      ColComp := ColComp + ' *';
    
    StringGridCompetences.Cells[1, RowIdx] := CodeComp;
    StringGridCompetences.Cells[2, RowIdx] := ColComp;
    StringGridCompetences.Cells[3, RowIdx] := ColSpec;
    StringGridCompetences.Cells[4, RowIdx] := ValeurXML(Elements.Item[I]);
    
    Inc(RowIdx);
  end;
  
  StringGridCompetences.RowCount := RowIdx;
  
  AdjustGridColumnsWidth(StringGridCompetences, 0, False, False, True, 10, 10, ssAutoBoth);
end;

// ========== AFFICHER TALENTS D'UN NIVEAU DE MÉTIER ==========
// Même modèle que les compétences : ensemble ouvert, spécialisations possibles
// (RULES-T0136_* = Etiquette (au choix)), donc les lignes viennent du XML.
// CodeNiveau a la forme "RULES-WORK01|2".
procedure TWinLivres.AfficherTalentsForNiveau(CodeNiveau: String);
var
  CareerElement: TDOMElement;
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  I, RowIdx, PipePos: Integer;
  CareerCode, CodeTal, BaseCode: String;
  ColTal, ColSpec: String;
  Talent, Generique: StructureTalent;
begin
  MasquerAfficherElements('TALENT_METIER');
  
  // Masquer les contrôles de saisie
  GroupBoxForm.Visible := False;
  
  // Découper "CODEMETIER|niveau"
  PipePos := Pos('|', CodeNiveau);
  if PipePos = 0 then Exit;
  
  CareerCode := Copy(CodeNiveau, 1, PipePos - 1);
  NiveauCourantAffiche := StrToIntDef(Copy(CodeNiveau, PipePos + 1, Length(CodeNiveau)), 0);
  
  CareerElement := TrouverCareerElement(CareerCode);
  if CareerElement = nil then Exit;
  
  Chapitre := CareerElement.FindNode('SUBCHAPTER_TALENT');
  if Chapitre = nil then Exit;
  
  StringGridTalents.RowCount := 1;
  
  // Col 0 = vide (réservé Lazarus)
  StringGridTalents.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_001');  // Code
  StringGridTalents.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_007');  // Talent
  StringGridTalents.Columns[2].Title.Caption := GetTexteLibelle('RULES-LAB_078');  // Spécialisation
  StringGridTalents.Columns[3].Title.Caption := GetTexteLibelle('RULES-LAB_019');  // Niv.
  
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Talent');
  
  // Pas de tri : l'ordre du XML groupe déjà les talents par niveau croissant.
  StringGridTalents.RowCount := Elements.Count + 1;
  RowIdx := 1;
  
  for I := 0 to Elements.Count - 1 do
  begin
    CodeTal := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if CodeTal = '' then Continue;
    
    Talent := ChercheTalent(CodeTal);
    
    if Talent.CodeTalent = '' then
    begin
      // Talent inconnu : on montre au moins le code
      ColTal  := CodeTal;
      ColSpec := '';
    end
    else if Talent.SousTalent then
    begin
      // Spécialisation : remonter au talent générique "XXX_*"
      if Talent.CodeGenerique <> '' then
        BaseCode := Talent.CodeGenerique
      else
        BaseCode := CodeFamilleTalent(CodeTal);
      
      Generique := ChercheTalent(BaseCode);
      if Generique.CodeTalent <> '' then
        ColTal := Generique.Libelle
      else
        ColTal := BaseCode;
      
      ColSpec := Talent.Libelle;
    end
    else
    begin
      // Talent sans spécialisation
      ColTal  := Talent.Libelle;
      ColSpec := '';
    end;
    
    StringGridTalents.Cells[1, RowIdx] := CodeTal;
    StringGridTalents.Cells[2, RowIdx] := ColTal;
    StringGridTalents.Cells[3, RowIdx] := ColSpec;
    StringGridTalents.Cells[4, RowIdx] := ValeurXML(Elements.Item[I]);
    
    Inc(RowIdx);
  end;
  
  StringGridTalents.RowCount := RowIdx;
  
  AdjustGridColumnsWidth(StringGridTalents, 0, False, False, True, 10, 10, ssAutoBoth);
end;

// ========== EQUIPEMENT D'UNE CARRIERE (tous niveaux) ==========
// Une ligne = une entree <Item> du XML. Un choix multiple ("A/B") reste sur UNE ligne, ses options
// jointes par le separateur ; une quantite par option se saisit "2/1/1". Tableau : Equipement (libelle
// resolu, lecture seule), Code ou texte, Quantite, Niv. (liste des niveaux declares).
// CodeNiveau a la forme "RULES-WORK01|2" ; le niveau n'est qu'un point d'entree.
function TWinLivres.LibelleLigneEquipement(const NomItem, Quantites: String): String;
var
  J: Integer;
  Choix: TStringList;
begin
  Result := '';
  if Trim(NomItem) = '' then Exit;
  if Pos(SeparateurMulti, NomItem) > 0 then
  begin
    Choix := TStringList.Create;
    try
      Choix.Delimiter       := SeparateurMulti;
      Choix.StrictDelimiter := True;
      Choix.DelimitedText   := NomItem;
      for J := 0 to Choix.Count - 1 do
      begin
        if Result <> '' then
          Result := Result + ' ' + SeparateurMulti + ' ';
        Result := Result + LibelleEnsembleEquipement(Trim(Choix[J])) +
          QuantiteSuffixe(QuantiteDeBranche(Quantites, J));
      end;
    finally
      Choix.Free;
    end;
  end
  else
    Result := LibelleEnsembleEquipement(Trim(NomItem)) +
      QuantiteSuffixe(QuantiteDeBranche(Quantites, 0));
end;

procedure TWinLivres.AfficherEquipementForNiveau(CodeNiveau: String);
var
  CareerElement: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  Elements: TDOMNodeList;
  I, RowIdx, PipePos: Integer;
  CareerCode, NomItem, Quantite: String;
begin
  MasquerAfficherElements('ATTRIBUT_ETHNIE');
  ModeEquipCarriere := True;
  StringGridAttrEthnie.Width := 900;
  StringGridAttrEthnie.Height := 500;
  StringGridAttrSimples.Visible := False;
  StringGridAttrBlessures.Visible := False;
  LabelAttrBlessures.Visible := False;
  PanelAttrBoutons.Left := 940;
  GroupBoxForm.Visible := False;
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');
  MenuNivFin.Caption := GetTexteLibelle('RULES-LAB_377');
  MenuNivSupprimer.Caption := GetTexteLibelle('RULES-LAB_378');
  MenuNivDebut.Visible := False;
  MenuEquipArme.Caption := GetTexteLibelle('RULES-LAB_063') + '...';    // Arme
  MenuEquipArmure.Caption := GetTexteLibelle('RULES-LAB_065') + '...';  // Armure
  MenuEquipDivers.Caption := GetTexteLibelle('RULES-LAB_064') + '...';  // Divers
  MenuEquipArme.Visible := True;
  MenuEquipArmure.Visible := True;
  MenuEquipDivers.Visible := True;
  StringGridAttrEthnie.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_013');  // Equipement
  StringGridAttrEthnie.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_001');  // Code
  StringGridAttrEthnie.Columns[2].Title.Caption := GetTexteLibelle('RULES-LAB_376');  // Quantite
  StringGridAttrEthnie.Columns[3].Title.Caption := GetTexteLibelle('RULES-LAB_019');  // Niv.
  StringGridAttrEthnie.Columns[0].Width := 320;
  StringGridAttrEthnie.Columns[1].Width := 0;  // colonne Code masquee (edition seulement, le libelle est en colonne 0)
  StringGridAttrEthnie.Columns[2].Width := 80;
  StringGridAttrEthnie.Columns[3].Width := 60;
  StringGridAttrEthnie.RowCount := 1;
  AttrSnapshot := '';
  MajBoutonsAttr(False);

  // Decouper "CODEMETIER|niveau"
  PipePos := Pos('|', CodeNiveau);
  if PipePos = 0 then Exit;
  CareerCode := Copy(CodeNiveau, 1, PipePos - 1);
  NiveauCourantAffiche := StrToIntDef(Copy(CodeNiveau, PipePos + 1, Length(CodeNiveau)), 0);
  AttrRaceCode := CareerCode;
  AttrCodeNiveau := CodeNiveau;

  CareerElement := TrouverCareerElement(CareerCode);
  if CareerElement = nil then Exit;

  AttrNiveauxValides.Clear;
  AttrNiveauxValides.Add('0');
  Chapitre := CareerElement.FindNode('SUBCHAPTER_LEVEL');
  if Chapitre <> nil then
  begin
    Enfant := Chapitre.FirstChild;
    while Enfant <> nil do
    begin
      if Enfant.NodeName = 'Level' then
        AttrNiveauxValides.Add(TDOMElement(Enfant).GetAttribute('id'));
      Enfant := Enfant.NextSibling;
    end;
  end;

  Chapitre := CareerElement.FindNode('SUBCHAPTER_ITEM');
  if Chapitre = nil then Exit;
  Elements := TDOMElement(Chapitre).GetElementsByTagName('Item');
  StringGridAttrEthnie.RowCount := Elements.Count + 1;
  RowIdx := 1;
  for I := 0 to Elements.Count - 1 do
  begin
    NomItem := TDOMElement(Elements.Item[I]).GetAttribute('name');
    if NomItem = '' then Continue;
    Quantite := TDOMElement(Elements.Item[I]).GetAttribute('quantite');
    if Quantite = '' then Quantite := '1';
    StringGridAttrEthnie.Cells[1, RowIdx] := LibelleLigneEquipement(NomItem, Quantite);
    StringGridAttrEthnie.Cells[2, RowIdx] := NomItem;
    StringGridAttrEthnie.Cells[3, RowIdx] := Quantite;
    StringGridAttrEthnie.Cells[4, RowIdx] := ValeurXML(Elements.Item[I]);
    Inc(RowIdx);
  end;
  StringGridAttrEthnie.RowCount := RowIdx;
  AttrSnapshot := InstantaneAttrEthnie(nil, 0, 0, '');
  MajBoutonsAttr(False);
end;

// Reecrit SUBCHAPTER_ITEM de la carriere d'apres le tableau (memoire seulement), par niveau croissant
// (l'ordre des lignes est conserve a l'interieur d'un niveau), puis refait les feuilles de l'arbre.
// Un <Item> n'a que name et, si elle differe de 1, quantite : rien n'est touche si la liste est identique.
procedure TWinLivres.ValiderEquipementCarriere;
var
  CareerElement, Element: TDOMElement;
  Chapitre, Enfant: TDOMNode;
  NoeudNiveau, Branche: TTreeNode;
  Tri, Anciens, Nouveaux: TStringList;
  Parts: TStringList;
  I, J, N, Niv: Integer;
  Nom, Quantite, Code: String;
begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  CareerElement := TrouverCareerElement(AttrRaceCode);
  if CareerElement = nil then Exit;

  Tri := TStringList.Create;
  Anciens := TStringList.Create;
  Nouveaux := TStringList.Create;
  Parts := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupAccept;
    Parts.StrictDelimiter := True;
    Parts.Delimiter := SeparateurMulti;

    // ---- 1. Validation ----
    for I := 1 to StringGridAttrEthnie.RowCount - 1 do
    begin
      Nom := Trim(StringGridAttrEthnie.Cells[2, I]);
      Quantite := Trim(StringGridAttrEthnie.Cells[3, I]);
      if Quantite = '' then Quantite := '1';
      Parts.DelimitedText := Quantite;
      N := 0;
      for J := 0 to Parts.Count - 1 do
        if StrToIntDef(Trim(Parts[J]), 0) < 1 then
          N := 1;
      if (Nom = '') or (N = 1) then
      begin
        MajBoutonsAttr(True);
        ShowMessage(GetTexteLibelle('RULES-LAB_379'));
        StringGridAttrEthnie.Row := I;
        Exit;
      end;
      if (AttrNiveauxValides.IndexOf(Trim(StringGridAttrEthnie.Cells[4, I])) < 1) then
      begin
        MajBoutonsAttr(True);
        ShowMessage(GetTexteLibelle('RULES-LAB_368'));
        StringGridAttrEthnie.Row := I;
        Exit;
      end;
      Tri.Add(Format('%.4d|%.4d|%s|%s', [StrToInt(Trim(StringGridAttrEthnie.Cells[4, I])), I, Quantite, Nom]));
    end;

    // ---- 2. Ecriture ----
    Chapitre := CareerElement.FindNode('SUBCHAPTER_ITEM');
    if (Chapitre = nil) and (Tri.Count > 0) then
      Chapitre := CareerElement.AppendChild(XMLDoc.CreateElement('SUBCHAPTER_ITEM'));
    if Chapitre = nil then Exit;

    Enfant := Chapitre.FirstChild;
    while Enfant <> nil do
    begin
      if Enfant.NodeName = 'Item' then
      begin
        Quantite := TDOMElement(Enfant).GetAttribute('quantite');
        if Quantite = '' then Quantite := '1';
        Anciens.Add(Format('%d|%s|%s', [StrToIntDef(ValeurXML(Enfant), 0), Quantite,
          TDOMElement(Enfant).GetAttribute('name')]));
      end;
      Enfant := Enfant.NextSibling;
    end;
    for I := 0 to Tri.Count - 1 do
    begin
      Code := Tri[I];  // "niveau|rang|quantite|nom" : le nom peut contenir '|' par extension
      Niv := StrToInt(Copy(Code, 1, 4));
      Delete(Code, 1, 10);
      Quantite := Copy(Code, 1, Pos('|', Code) - 1);
      Nom := Copy(Code, Pos('|', Code) + 1, Length(Code));
      Nouveaux.Add(Format('%d|%s|%s', [Niv, Quantite, Nom]));
    end;

    if Anciens.Text <> Nouveaux.Text then
    begin
      while Chapitre.FirstChild <> nil do
        Chapitre.RemoveChild(Chapitre.FirstChild);
      for I := 0 to Nouveaux.Count - 1 do
      begin
        Code := Nouveaux[I];
        Niv := StrToInt(Copy(Code, 1, Pos('|', Code) - 1));
        Delete(Code, 1, Pos('|', Code));
        Quantite := Copy(Code, 1, Pos('|', Code) - 1);
        Nom := Copy(Code, Pos('|', Code) + 1, Length(Code));
        Element := XMLDoc.CreateElement('Item');
        Element.SetAttribute('name', Nom);
        if Quantite <> '1' then
          Element.SetAttribute('quantite', Quantite);
        EcrireValeurXML(Element, IntToStr(Niv));
        Chapitre.AppendChild(XMLDoc.CreateTextNode(#10));
        Chapitre.AppendChild(Element);
      end;
      Chapitre.AppendChild(XMLDoc.CreateTextNode(#10));

      // ---- 3. L'arbre suit le XML : la branche Equipement de chaque niveau de la carriere ----
      for I := 0 to TreeViewLivre.Items.Count - 1 do
      begin
        NoeudNiveau := TreeViewLivre.Items[I];
        if GetNodeType(NoeudNiveau) <> NT_NIVEAU_METIER then Continue;
        Code := GetNodeCode(NoeudNiveau);
        if Copy(Code, 1, Length(AttrRaceCode) + 1) <> AttrRaceCode + '|' then Continue;
        Niv := StrToIntDef(Copy(Code, Pos('|', Code) + 1, Length(Code)), 0);
        Branche := nil;
        for J := 0 to NoeudNiveau.Count - 1 do
          if GetNodeType(NoeudNiveau.Items[J]) = NT_BRANCHE_EQUIPEMENT_NIVEAU then
            Branche := NoeudNiveau.Items[J];
        if Branche = nil then
        begin
          // la carriere n'avait pas encore d'equipement : la branche est creee
          Branche := TreeViewLivre.Items.AddChild(NoeudNiveau, ConstArbreEquipement);
          SetNodeInfo(Branche, NT_BRANCHE_EQUIPEMENT_NIVEAU, Code);
        end;
        Branche.DeleteChildren;
        RemplirBrancheNiveauEquipement(Branche, Chapitre, Niv);
      end;
    end;
  finally
    Parts.Free;
    Nouveaux.Free;
    Anciens.Free;
    Tri.Free;
  end;
  AfficherEquipementForNiveau(AttrCodeNiveau);
end;

// Met en évidence les lignes du niveau courant.
// Partagé par toutes les grilles dont la DERNIÈRE colonne est le niveau.
// OnPrepareCanvas plutôt que OnDrawCell : on ne change que le pinceau,
// la grille se dessine elle-même normalement.
procedure TWinLivres.GridNiveauPrepareCanvas(Sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
var
  Grille: TStringGrid;
begin
  if aRow < 1 then Exit;           // ligne d'en-tête
  if NiveauCourantAffiche = 0 then Exit;
  
  Grille := TStringGrid(Sender);
  if Grille.ColCount < 1 then Exit;
  
  if Grille.Cells[Grille.ColCount - 1, aRow] = IntToStr(NiveauCourantAffiche) then
    Grille.Canvas.Brush.Color := $00F0E4D8;  // fond discret
end;

// ========== AFFICHER RACES FOR METIER ==========
// Liste TOUTES les races de ListRace et coche celles qui proposent ce métier.
// Symétrique de AfficherCareersForRace, qui liste tous les métiers pour une race.
procedure TWinLivres.AfficherRacesForMetier(CareerCode: String);
var
  I, RowIdx, PipePos: Integer;
  Race: StructureRace;
  RacesDuMetier: TStringList;
  TempRacesData: TStringList;
  Ligne, Selected, Libelle, Code, LivreStr: String;
begin
  // Afficher le grid des races, masquer le reste
  MasquerAfficherElements('RACE');
  
  // Masquer les contrôles de race et attributs
  
  if ListRace = nil then Exit;
  
  StringGridRaces.RowCount := 1;
  
  // Les colonnes sont définies dans le .lfm
  // Col 0 = vide (réservé Lazarus), 1 = Code, 2 = Libellé, 3 = Livre, 4 = Sélectionné
  StringGridRaces.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_001');  // Code
  StringGridRaces.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_002');  // Libellé
  StringGridRaces.Columns[2].Title.Caption := GetTexteLibelle('RULES-LAB_128');  // Livre
  StringGridRaces.Columns[3].Title.Caption := GetTexteLibelle('RULES-LAB_004');  // Sélectionné
  
  // Codes des races qui proposent ce métier
  RacesDuMetier := TStringList.Create;
  TempRacesData := TStringList.Create;
  try
    if MetierRacesMap <> nil then
    begin
      RacesDuMetier.Delimiter       := '|';
      RacesDuMetier.StrictDelimiter := True;
      RacesDuMetier.DelimitedText   := MetierRacesMap.Values[CareerCode];
    end;
    
    // Format de tri : "Selected|Libelle|Code|Livre"
    // Selected = "0" si la race propose le métier (donc en premier), "1" sinon
    for I := 0 to ListRace.Count - 1 do
    begin
      Race := ListRace[I];
      if Race.CodeRace = '' then Continue;
      
      if RacesDuMetier.IndexOf(Race.CodeRace) >= 0 then
        Selected := '0'
      else
        Selected := '1';
      
      TempRacesData.Add(Selected + '|' + Race.Libelle + '|' + Race.CodeRace + '|' +
                        GetTexteLibelle(Race.Livre, '', '', True));
    end;
    
    // Tri : sélectionnées d'abord ("0" < "1"), puis alphabétique par libellé
    TempRacesData.Sort;
    
    StringGridRaces.RowCount := TempRacesData.Count + 1;
    RowIdx := 1;
    
    for I := 0 to TempRacesData.Count - 1 do
    begin
      // Découpage manuel : DelimitedText se comporte mal avec le pipe
      Ligne := TempRacesData[I];
      
      PipePos  := Pos('|', Ligne);
      Selected := Copy(Ligne, 1, PipePos - 1);
      Ligne    := Copy(Ligne, PipePos + 1, Length(Ligne));
      
      PipePos  := Pos('|', Ligne);
      Libelle  := Copy(Ligne, 1, PipePos - 1);
      Ligne    := Copy(Ligne, PipePos + 1, Length(Ligne));
      
      PipePos  := Pos('|', Ligne);
      Code     := Copy(Ligne, 1, PipePos - 1);
      LivreStr := Copy(Ligne, PipePos + 1, Length(Ligne));
      
      StringGridRaces.Cells[1, RowIdx] := Code;
      StringGridRaces.Cells[2, RowIdx] := Libelle;
      StringGridRaces.Cells[3, RowIdx] := LivreStr;
      
      if Selected = '0' then
        StringGridRaces.Cells[4, RowIdx] := '✓'
      else
        StringGridRaces.Cells[4, RowIdx] := '';
      
      Inc(RowIdx);
    end;
  finally
    TempRacesData.Free;
    RacesDuMetier.Free;
  end;
  
  AdjustGridColumnsWidth(StringGridRaces, 0, False, False, True, 10, 10, ssAutoBoth);
  
  GroupBoxForm.Visible := False;
end;

// ========== AFFICHER CAREERS FOR RACE ==========
procedure TWinLivres.AfficherCareersForRace(RaceCode: String);
var
  RowIdx, I, J: Integer;
  Metier: StructureMetier;
  CareerFound: Boolean;
  CareerValue: String;
  CodeLivre: String;
  TempCareersData: TStringList;
  RaceElement: TDOMElement;
  SpecieElements: TDOMNodeList;
  Line: String;
  PipePos: Integer;
  Selected, Libelle, Code, LivreStr, Chance, LibClasse, Prefixe: String;
  Excedent, Reduit: Integer;
begin
  // Afficher carrières, masquer les autres éléments
  MasquerAfficherElements('CARRIERE');

  // Masquer les contrôles de race et attributs

  // Valider / Annuler, comme les competences d'ethnie
  PanelAttrBoutons.Visible := True;
  AttrRaceCode := RaceCode;
  AttrSnapshot := '';
  MajBoutonsAttr(False);
  ButtonAttrValider.Caption := GetTexteLibelle('RULES-LAB_086');
  ButtonAttrAnnuler.Caption := GetTexteLibelle('RULES-LAB_166');

  // Chercher l'élément race dans le XML
  if XMLDoc = nil then Exit;
  
  RaceElement := nil;
  SpecieElements := XMLDoc.GetElementsByTagName('Specie');
  
  for I := 0 to SpecieElements.Count - 1 do
  begin
    if TDOMElement(SpecieElements[I]).GetAttribute('id') = RaceCode then
    begin
      RaceElement := TDOMElement(SpecieElements[I]);
      Break;
    end;
  end;
  
  if RaceElement = nil then Exit;
  
  // Charger les carrières de cette race
  LoadCareersForRace(RaceElement);
  
  if ListMetier = nil then Exit;
  
  // Créer le StringGrid pour les carrières
  StringGridCareers.RowCount := 1;
  
  // Les colonnes sont définies dans le .lfm
  // Col 0 = vide (réservé Lazarus)
  // Col 1 = Code
  // Col 2 = Libellé
  // Col 3 = Livre
  // Col 4 = Sélectionné
  // Col 5 = Chance
  
  // Préparer les données dans une liste temporaire pour tri
  TempCareersData := TStringList.Create;
  try
    for I := 0 to ListMetier.Count - 1 do
    begin
      Metier := ListMetier[I];
      
      // Chercher dans RaceCareersData
      CareerFound := False;
      CareerValue := '';
      for J := 0 to RaceCareersData.Count - 1 do
      begin
        if Pos(Metier.CodeMetier + '|', RaceCareersData[J]) = 1 then
        begin
          CareerFound := True;
          CareerValue := Copy(RaceCareersData[J], Length(Metier.CodeMetier) + 2, Length(RaceCareersData[J]));
          Break;
        end;
      end;
      
      // Chercher le livre
      // Libelle (traduit) du livre, comme la grille des races
      CodeLivre := GetTexteLibelle(Metier.Livre, '', '', True);
      if CodeLivre = '' then CodeLivre := Metier.Livre;

      // Format stockage pour tri: "Selected|CleClasse|CleLibelle|Libelle|Code|Livre|Classe|CareerValue"
      // Selected = "0" pour sélectionné (viendra en premier), "1" pour non-sélectionné ;
      // puis l'ordre du dé : classe, puis libellé (mêmes clés que CalculeTirageMetier)
      LibClasse := LibelleClasse(Metier.LibelleGroupe);
      Prefixe := CleTri(LibClasse) + '|' + CleTri(Metier.Libelle) + '|' + Metier.Libelle + '|' +
        Metier.CodeMetier + '|' + CodeLivre + '|' + LibClasse + '|';
      if CareerFound then
        TempCareersData.Add('0|' + Prefixe + CareerValue)
      else
        TempCareersData.Add('1|' + Prefixe);
    end;
    
    // TRIER: D'abord sélectionnés (1 avant 0), puis alphabétique par Libellé
    TempCareersData.Sort;
    
    // Remplir le grid avec les données triées
    StringGridCareers.RowCount := TempCareersData.Count + 1;
    
    RowIdx := 1;
    for I := 0 to TempCareersData.Count - 1 do
    begin
      // Parser la ligne: "Selected|CleClasse|CleLibelle|Libelle|Code|Livre|Classe|CareerValue"
      // Parsing manuel robuste (évite les problèmes avec DelimitedText)
      Line := TempCareersData[I];
      
      // Extraire Selected (premier pipe)
      PipePos := Pos('|', Line);
      Selected := Copy(Line, 1, PipePos - 1);
      Line := Copy(Line, PipePos + 1, Length(Line));

      // Les deux clés de tri ne servent plus
      for J := 1 to 2 do
      begin
        PipePos := Pos('|', Line);
        Line := Copy(Line, PipePos + 1, Length(Line));
      end;
      
      // Extraire Libelle (deuxième pipe)
      PipePos := Pos('|', Line);
      Libelle := Copy(Line, 1, PipePos - 1);
      Line := Copy(Line, PipePos + 1, Length(Line));
      
      // Extraire Code (troisième pipe)
      PipePos := Pos('|', Line);
      Code := Copy(Line, 1, PipePos - 1);
      Line := Copy(Line, PipePos + 1, Length(Line));
      
      // Extraire Livre (quatrième pipe)
      PipePos := Pos('|', Line);
      LivreStr := Copy(Line, 1, PipePos - 1);
      Line := Copy(Line, PipePos + 1, Length(Line));

      // Extraire Classe (cinquième pipe), le reste est la Chance
      PipePos := Pos('|', Line);
      LibClasse := Copy(Line, 1, PipePos - 1);
      Chance := Copy(Line, PipePos + 1, Length(Line));
      
      // Col 1: Code
      StringGridCareers.Cells[1, RowIdx] := Code;
      
      // Col 2: Libellé
      StringGridCareers.Cells[2, RowIdx] := Libelle;
      
      // Col 3: Livre
      StringGridCareers.Cells[3, RowIdx] := LivreStr;
      
      // Col 4: Sélectionné (case à cocher native : '1' coché, '0' décoché)
      if Selected = '0' then
        StringGridCareers.Cells[4, RowIdx] := '1'
      else
        StringGridCareers.Cells[4, RowIdx] := '0';
      
      // Col 5: Chance
      StringGridCareers.Cells[5, RowIdx] := Chance;

      // Col 6: Classe (Col 7 et 8 : voir MajTranchesCareers)
      StringGridCareers.Cells[6, RowIdx] := LibClasse;
      
      Inc(RowIdx);
    end;
    
  finally
    TempCareersData.Free;
  end;
  
  MajTranchesCareers;

  // Ajuster automatiquement les dimensions du grid
  AdjustGridColumnsWidth(StringGridCareers, 0, False, False, true, 10, 10, ssAutoBoth);
  // Tout doit tenir dans 900 de large (les boutons restent à droite, à 940) sans défilement :
  // colonne réservée masquée, puis Livre et Libellé rognés au besoin
  StringGridCareers.ColWidths[0] := 0;
  StringGridCareers.ColWidths[1] := 0;  // le code metier n'interesse pas : le libelle suffit (la colonne reste lue par le code)
  Excedent := -880;  // 900 moins la barre verticale
  for J := 0 to StringGridCareers.ColCount - 1 do
    Excedent := Excedent + StringGridCareers.ColWidths[J];
  for J := 3 downto 2 do  // Livre puis Libellé
    if Excedent > 0 then
    begin
      Reduit := StringGridCareers.ColWidths[J] - Excedent;
      if Reduit < 130 then Reduit := 130;
      Excedent := Excedent - (StringGridCareers.ColWidths[J] - Reduit);
      StringGridCareers.ColWidths[J] := Reduit;
    end;
  StringGridCareers.Width := 900;

  GroupBoxForm.Visible := False;

  AttrSnapshot := InstantaneCareers;
  MajBoutonsAttr(False);
end;

// Total des poids au-dessus de la grille : rouge s'il n'est pas 100 (les tranches sont alors étirées).
procedure TWinLivres.AfficheTotalCareers(Total: Integer);
begin
  LabelTotalCareers.Visible := True;
  LabelTotalCareers.Caption := Format(GetTexteLibelle('RULES-LAB_450'), [Total]);
  if Total = 100 then
    LabelTotalCareers.Font.Color := clGreen
  else
    LabelTotalCareers.Font.Color := clRed;
end;

// Colonnes Min-Max et % classe : la table d100 que donneraient les poids saisis (lignes cochees),
// dans l'ordre du dé (classe puis libellé) et ramenée à 100 comme CalculeTirageMetier.
procedure TWinLivres.MajTranchesCareers;
type
  TLigneTranche = record
    Ligne, Poids, Debut, Fin: Integer;
    Cle: String;
  end;
var
  G: TStringGrid;
  I, J, N, Total, Cumul, Poids, Debut, Fin: Integer;
  Lignes: array of TLigneTranche;
  Tmp: TLigneTranche;
  Classes: TStringList;
  P: Integer;
begin
  G := StringGridCareers;
  SetLength(Lignes, G.RowCount);
  N := 0;
  Total := 0;
  AfficheTotalCareers(0);
  for I := 1 to G.RowCount - 1 do
  begin
    G.Cells[7, I] := '';
    G.Cells[8, I] := '';
    if G.Cells[4, I] <> '1' then Continue;
    Poids := StrToIntDef(Trim(G.Cells[5, I]), 0);
    if Poids <= 0 then
    begin
      G.Cells[7, I] := Trim(G.Cells[5, I]);  // 'X' ou vide : hors tirage
      Continue;
    end;
    Lignes[N].Ligne := I;
    Lignes[N].Poids := Poids;
    Lignes[N].Cle := CleTri(G.Cells[6, I]) + #1 + CleTri(G.Cells[2, I]);
    Total := Total + Poids;
    Inc(N);
  end;
  // Total des poids dans l'en-tête : différent de 100, les tranches sont étirées (voir ci-dessus)
  AfficheTotalCareers(Total);
  if Total <= 0 then Exit;

  for I := 1 to N - 1 do
  begin
    Tmp := Lignes[I];
    J := I - 1;
    while (J >= 0) and (Lignes[J].Cle > Tmp.Cle) do
    begin
      Lignes[J + 1] := Lignes[J];
      Dec(J);
    end;
    Lignes[J + 1] := Tmp;
  end;

  Classes := TStringList.Create;  // classe=poids cumulé (en dés)
  try
    Cumul := 0;
    for I := 0 to N - 1 do
    begin
      Debut := (Cumul * 100) div Total + 1;
      Cumul := Cumul + Lignes[I].Poids;
      Fin := (Cumul * 100) div Total;
      if Fin < Debut then Fin := Debut;
      Lignes[I].Debut := Debut;
      Lignes[I].Fin := Fin;
      G.Cells[7, Lignes[I].Ligne] := FormateTranche(Debut, Fin);
      P := Classes.IndexOfName(G.Cells[6, Lignes[I].Ligne]);
      if P < 0 then
        Classes.Values[G.Cells[6, Lignes[I].Ligne]] := IntToStr(Fin - Debut + 1)
      else
        Classes.ValueFromIndex[P] := IntToStr(StrToInt(Classes.ValueFromIndex[P]) + Fin - Debut + 1);
    end;
    for I := 0 to N - 1 do
      G.Cells[8, Lignes[I].Ligne] := Classes.Values[G.Cells[6, Lignes[I].Ligne]] + ' %';
  finally
    Classes.Free;
  end;
end;

// Codes et chances des lignes cochees, dans l'ordre du tableau.
function TWinLivres.InstantaneCareers: String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to StringGridCareers.RowCount - 1 do
    if StringGridCareers.Cells[4, I] = '1' then
      Result := Result + StringGridCareers.Cells[1, I] + '=' + Trim(StringGridCareers.Cells[5, I]) + '#';
end;

// Seule la colonne Chance se saisit ; la case Selectionne se gere seule.
procedure TWinLivres.GridCareersSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  if aCol <> 5 then
    Editor := nil;
end;

procedure TWinLivres.GridCareersSetEditText(Sender: TObject; aCol, aRow: Integer; const Value: string);
begin
  if aCol = 5 then
  begin
    StringGridCareers.Cells[5, aRow] := Value;  // la cellule n'est mise à jour qu'après l'événement
    MajTranchesCareers;
  end;
  MajBoutonsAttr(InstantaneCareers <> AttrSnapshot);
end;

// Cocher une ligne sans chance lui donne 'X' (eligible hors tirage) ; decocher garde le texte.
procedure TWinLivres.GridCareersCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
begin
  if (aRow > 0) and (aState = cbChecked) and (Trim(StringGridCareers.Cells[5, aRow]) = '') then
    StringGridCareers.Cells[5, aRow] := 'X';
  MajTranchesCareers;
  MajBoutonsAttr(InstantaneCareers <> AttrSnapshot);
end;

// Chance valide : 'X' ou '-' (hors tirage, deja dans les livres officiels) ou un poids entier de 1 a 100
// (nombre de valeurs de de du metier ; les bornes se calculent a l'usage, voir ChargeTirageMetier).
function ChanceValide(S: String): Boolean;
var
  Poids: Integer;
begin
  S := Trim(S);
  if (S = 'X') or (S = '-') then
  begin
    Result := True;
    Exit;
  end;
  Poids := StrToIntDef(S, 0);
  Result := (Poids >= 1) and (Poids <= 100);
end;

// Reecrit SUBCHAPTER_CAREER de l'ethnie d'apres les lignes cochees (memoire seulement).
// Un <Career> existant garde sa place ; un retire emporte le commentaire qui le suit.
procedure TWinLivres.ValiderCarrieresEthnie;
var
  RaceElement: TDOMElement;
  Chapitre, Enfant, Suivant: TDOMNode;
  Element: TDOMElement;
  I: Integer;
  Code, Chance: String;
  Coches: TStringList;
  Trouves: TList;
begin
  FermerEditeursAttr;
  MajBoutonsAttr(False);
  RaceElement := TrouverElementParId('Specie', AttrRaceCode);
  if RaceElement = nil then Exit;

  Coches := TStringList.Create;
  Trouves := TList.Create;
  try
    Coches.CaseSensitive := True;

    // ---- 1. Validation : rien n'est ecrit si une chance est invalide ----
    for I := 1 to StringGridCareers.RowCount - 1 do
    begin
      if StringGridCareers.Cells[4, I] <> '1' then Continue;
      Chance := StringReplace(Trim(StringGridCareers.Cells[5, I]), '–', '-', [rfReplaceAll]);
      if not ChanceValide(Chance) then
      begin
        MajBoutonsAttr(True);
        if TestSansMessage then
          with TStringList.Create do
          try
            if FileExists('error.log') then LoadFromFile('error.log');
            Add('Chance invalide : ' + AttrRaceCode + ' / ' + StringGridCareers.Cells[1, I] + ' = [' + Chance + ']');
            SaveToFile('error.log');
          finally
            Free;
          end
        else
          ShowMessage(GetTexteLibelle('RULES-LAB_359'));
        StringGridCareers.Row := I;
        StringGridCareers.Col := 5;
        Exit;
      end;
      Coches.Values[StringGridCareers.Cells[1, I]] := Chance;
    end;

    // ---- 2. Ecriture ----
    Chapitre := RaceElement.FindNode('SUBCHAPTER_CAREER');
    if Chapitre = nil then
    begin
      if Coches.Count = 0 then Exit;
      Chapitre := RaceElement.AppendChild(XMLDoc.CreateElement('SUBCHAPTER_CAREER'));
    end;

    // existants : mis a jour si la chance change, retires si decoches
    Enfant := Chapitre.FirstChild;
    while Enfant <> nil do
    begin
      Suivant := Enfant.NextSibling;
      if Enfant.NodeName = 'Career' then
      begin
        Element := TDOMElement(Enfant);
        Code := Element.GetAttribute('name');
        if Coches.IndexOfName(Code) >= 0 then
        begin
          Trouves.Add(Enfant);
          Chance := Coches.Values[Code];
          if ValeurXML(Enfant) <> Chance then
            EcrireValeurXML(Element, Chance);
        end
        else
        begin
          // le commentaire qui suit (ex. <!-- Apothecary -->) part avec la carriere
          while (Suivant <> nil) and (Suivant.NodeType = TEXT_NODE) and (Trim(Suivant.NodeValue) = '') do
            Suivant := Suivant.NextSibling;
          if (Suivant <> nil) and (Suivant.NodeType = COMMENT_NODE) then
          begin
            Enfant := Suivant.NextSibling;
            Chapitre.RemoveChild(Suivant);
            Suivant := Enfant;
          end;
          Chapitre.RemoveChild(Enfant);
        end;
      end;
      Enfant := Suivant;
    end;

    // nouveaux : ajoutes a la fin
    for I := 1 to StringGridCareers.RowCount - 1 do
    begin
      if StringGridCareers.Cells[4, I] <> '1' then Continue;
      Code := StringGridCareers.Cells[1, I];
      Element := nil;
      Enfant := Chapitre.FirstChild;
      while Enfant <> nil do
      begin
        if (Enfant.NodeName = 'Career') and (TDOMElement(Enfant).GetAttribute('name') = Code) then
        begin
          Element := TDOMElement(Enfant);
          Break;
        end;
        Enfant := Enfant.NextSibling;
      end;
      if Element = nil then
      begin
        Element := XMLDoc.CreateElement('Career');
        Element.SetAttribute('name', Code);
        EcrireValeurXML(Element, Coches.Values[Code]);
        Chapitre.AppendChild(Element);
        Chapitre.AppendChild(XMLDoc.CreateComment(' ' + StringGridCareers.Cells[2, I] + ' '));
      end;
    end;

    // ---- 3. L'arbre suit le XML : on recharge la branche des carrieres de l'ethnie ----
    if (NodeSelectionnee <> nil) and (GetNodeType(NodeSelectionnee) = NT_CARRIERES_RACE) then
    begin
      NodeSelectionnee.DeleteChildren;
      RemplirNoeudCarrieres(RaceElement, NodeSelectionnee);
    end;
  finally
    Trouves.Free;
    Coches.Free;
  end;

  AfficherCareersForRace(AttrRaceCode);
end;

// En-tete du livre (bloc DATA_BOOK) : six champs d'identite en lecture seule (les changer casserait les codes du livre)
// et la mention legale <DISCLAIMER>, modifiable dans un livre de fan ou inacheve seulement (un livre officiel garde son
// texte legal tel qu'il a ete recopie). Meme fiche que les autres elements ; PanelFiche ne cree pas la balise a sa place :
// voir RangerDisclaimer.
procedure TWinLivres.AfficherInfosLivre();
var
  Racine: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Racine := XMLDoc.DocumentElement;
  FicheTag := 'Livre';
  FicheTypeNoeud := NT_INFO_LIVRE;
  PanelFiche.Definir([
    ChampFiche('CODE_BOOK', 'RULES-LAB_635', gfTexte, False, False, True, False),
    ChampFiche('BOOK', 'RULES-LAB_636', gfTexte, False, False, True, False),
    ChampFiche('language', 'RULES-LAB_637', gfTexte, False, False, True, False),
    ChampFiche('VERSION', 'RULES-LAB_638', gfTexte, False, False, True, False),
    ChampFiche('OFFICIAL', 'RULES-LAB_639', gfTexte, False, False, True, False),
    ChampFiche('COMPLETE', 'RULES-LAB_640', gfTexte, False, False, True, False),
    ChampFiche('DISCLAIMER', 'RULES-LAB_641', gfMemo, True, False, True, False)]);
  PanelFiche.DeclarerVirtuel('CODE_BOOK');
  PanelFiche.DeclarerVirtuel('BOOK');
  PanelFiche.DeclarerVirtuel('language');
  PanelFiche.DeclarerVirtuel('VERSION');
  PanelFiche.DeclarerVirtuel('OFFICIAL');
  PanelFiche.DeclarerVirtuel('COMPLETE');
  PanelFiche.MasquerGrille;
  PanelFiche.Charger(Racine);
  if CreationPermise then
    PanelFiche.LectureSeuleSauf('DISCLAIMER')
  else
    PanelFiche.LectureSeule := True;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  CodeDonneeSelectionnee := 'DATA_BOOK';
  LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_128');
  if CreationPermise then PrendreSnapshotFiche;
end;

// La mention legale se range apres les champs d'identite et avant les blocs de donnees (ordre du schema) ; vide = pas de
// balise. Refus d'un guillemet droit : la lecture retire les guillemets qui encadrent la valeur.
function TWinLivres.RangerDisclaimer: Boolean;
const
  Entete: array[0..7] of String = ('CODE_BOOK', 'BOOK', 'language', 'VERSION', 'OFFICIAL', 'COMPLETE', 'REVISION',
    'REVISION_LABEL');
var
  Racine: TDOMElement;
  Noeud, Suivant: TDOMNode;
  Texte: String;
  I: Integer;
  EstEntete: Boolean;
begin
  Result := False;
  Racine := XMLDoc.DocumentElement;
  Texte := Trim(PanelFiche.ValeurChamp('DISCLAIMER'));
  if Pos('"', Texte) > 0 then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_642', 'The legal notice must not contain a straight double quote ("): use quotation marks of another kind.'));
    Exit;
  end;
  Noeud := Racine.FindNode('DISCLAIMER');
  if Texte = '' then
  begin
    if Noeud <> nil then Racine.RemoveChild(Noeud);
    Exit(True);
  end;
  if Noeud = nil then
    Noeud := XMLDoc.CreateElement('DISCLAIMER')
  else
    Racine.RemoveChild(Noeud);
  EcrireValeurXML(TDOMElement(Noeud), Texte);
  // avant le premier element qui n'est pas un champ d'en-tete
  Suivant := Racine.FirstChild;
  while Suivant <> nil do
  begin
    EstEntete := (Suivant.NodeType <> ELEMENT_NODE);
    if not EstEntete then
      for I := 0 to High(Entete) do
        if Suivant.NodeName = Entete[I] then EstEntete := True;
    if not EstEntete then Break;
    Suivant := Suivant.NextSibling;
  end;
  Racine.InsertBefore(Noeud, Suivant);
  Result := True;
end;

// ✨ AFFICHAGE DYNAMIQUE

procedure TWinLivres.AfficherDonneeRace(ACode: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Specie', ACode);
  if Element = nil then Exit;
  // V4 / V5 : la fiche a son panneau de noms, meme quand l'ethnie n'a pas encore de SUBCHAPTER_NAMES (ethnie neuve)
  if (EstLivreV1 or EstLivreV2) and FicheGeneriqueV1Possible(Element) then
  begin
    AfficherFicheGeneriqueV1(Element, 'Specie', NT_RACE, ACode);
    PoserImageLivre('E', ACode);
    Exit;
  end;
  FamillesTalent := '';  // nouvelle navigation : les familles cochees ne se gardent pas d'une ethnie a l'autre
  AfficherFicheEthnie(Element, ACode);
end;

// Fiche d'une ethnie (V2, V4, V5). Champs rares en groupes : Rattachement (Nationality 16 ethnies sur 88, PictureLevel 11,
// V4 / V5) et Recit (Background, RoleplayingHints : 4 ethnies sur 103, V2) ; familles cochees ou deja presentes.
procedure TWinLivres.AfficherFicheEthnie(Element: TDOMElement; ACode: String);
var
  Familles: String;
  AvecFamilles: Boolean;
  Champs: TTableauChampsFiche;
  I: Integer;

  procedure Ajoute(const Champ: StructureChampFiche);
  begin
    SetLength(Champs, Length(Champs) + 1);
    Champs[High(Champs)] := Champ;
  end;
begin
  FicheTag := 'Specie';
  FicheTypeNoeud := NT_RACE;
  Familles := FamillesTalent;
  AvecFamilles := EditionPermise;
  FTalentElement := Element;  // pour reconstruire la fiche apres un changement de famille
  SetLength(Champs, 0);
  Ajoute(ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True));
  if AvecFamilles then
    Ajoute(ChampFiche('FamilleEthnie', 'RULES-LAB_FAMILLE_ETHNIE', gfCases, False, False, True, False,
      'RATTACHEMENT=' + GetTexteLibelle('RULES-LAB_FAMILLE_RATTACHEMENT', 'Nationality, level picture') +
      '|RECIT=' + GetTexteLibelle('RULES-LAB_FAMILLE_RECIT', 'Background, roleplaying hints')));
  Ajoute(ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True));
  Ajoute(ChampFiche('Ethnic', 'RULES-LAB_561', gfCodeLibre, False, False, True, False,
    ChoixParTags(['Race'], ValeurXML(Element.FindNode('Ethnic')))));
  Ajoute(EnGroupes(ChampFiche('Nationality', 'RULES-LAB_332', gfCodeLibre, False, False, True, False,
    ChoixParTags(['Nation'], ValeurXML(Element.FindNode('Nationality')))), 'Rattachement+V4,V5'));
  Ajoute(EnGroupes(ChampFiche('PictureLevel', 'RULES-LAB_958', gfTexte, False, False, True, False), 'Rattachement+V4,V5'));
  Ajoute(EnGroupes(ChampFiche('Background', 'RULES-LAB_726', gfMemo, True, False, True, False), 'Recit+V2'));
  Ajoute(EnGroupes(ChampFiche('RoleplayingHints', 'RULES-LAB_727', gfMemo, True, False, True, False), 'Recit+V2'));
  Ajoute(ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False));
  FiltrerChampsFiche(Champs, Element, VersionFicheLivre, Familles);
  PanelFiche.Definir(Champs);
  if AvecFamilles then PanelFiche.DeclarerVirtuel('FamilleEthnie');
  PanelFiche.MasquerGrille;  // le moteur ne lit aucun modificateur d'ethnie
  PanelFiche.Extra := PanelNoms;
  PanelFiche.Charger(Element);
  if AvecFamilles then PanelFiche.CocherCodes('FamilleEthnie', Familles);
  // une ethnie sans Description n'est qu'un ajout a une race d'un autre livre : le libelle de l'arbre est celui de cette race
  if (RacesDataList <> nil) and (PanelFiche.ValeurChamp('Description') = '') then
  begin
    I := RacesDataList.IndexOf(ACode);
    if I >= 0 then PanelFiche.SetValeurChamp('Description', RacesDataList.Data[I]^.Libelle);
  end;
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  CodeDonneeSelectionnee := ACode;
  PoserImageLivre('E', ACode);
  if EditionPermise then PrendreSnapshotFiche;
end;

// ========== AFFICHER DONNÉE MÉTIER ==========
// Retrouve un élément racine par son attribut id, en écartant les éléments
// de même nom nichés dans les SUBCHAPTER_*, qui eux portent un attribut name.
function TWinLivres.TrouverElementParId(TagName, Id: String): TDOMElement;
var
  Elements: TDOMNodeList;
  I: Integer;
  Element: TDOMElement;
begin
  Result := nil;
  if (XMLDoc = nil) or (Id = '') then Exit;
  
  Elements := XMLDoc.GetElementsByTagName(TagName);
  
  for I := 0 to Elements.Count - 1 do
  begin
    Element := TDOMElement(Elements.Item[I]);
    // une ligne de DATA_SPELL_TALENT porte l'id du sort sans etre le sort
    if (Element.ParentNode <> nil) and (Element.ParentNode.NodeName = 'DATA_SPELL_TALENT') then Continue;
    
    if Element.GetAttribute('id') = Id then
    begin
      Result := Element;
      Exit;
    end;
    // repli sur name= (reference), seulement si aucun element n'a cet id : une ligne de tirage
    // <Skill name="x"> placee avant la definition ne doit pas la masquer
    if (Result = nil) and (Element.GetAttribute('name') = Id) then Result := Element;
  end;
end;

// La definition d'une carriere porte un attribut id ; les <Career name="..."> des ethnies n'en sont que
// des references (vides) et peuvent venir avant dans le document : on ne retient que l'id.
function TWinLivres.TrouverCareerElement(CareerCode: String): TDOMElement;
var
  Elements: TDOMNodeList;
  I: Integer;
begin
  Result := nil;
  if (XMLDoc = nil) or (CareerCode = '') then Exit;
  Elements := XMLDoc.GetElementsByTagName('Career');
  for I := 0 to Elements.Count - 1 do
    if TDOMElement(Elements.Item[I]).GetAttribute('id') = CareerCode then
    begin
      Result := TDOMElement(Elements.Item[I]);
      Exit;
    end;
  Result := TrouverElementParId('Career', CareerCode);
end;

// Découpe un calcul de dégâts du type "+(BATTR_S)+5" en deux parties :
// le code du bonus d'attribut, et la valeur fixe. Renvoie True si un bonus
// est présent. Tolère l'absence de l'un ou l'autre.
function TWinLivres.DecouperDegats(Degats: String; out CodeBonus, Fixe: String): Boolean;
begin
  Result := DecouperDegatsFiche(Degats, CodeBonus, Fixe);
end;

// ========== AFFICHER DONNÉE ÉQUIPEMENT (arme / armure) ==========

// Ajoute une ligne à la grille de détail.
// Toujours = True force l'affichage même sans valeur, pour les champs dont
// la seule présence est l'information (une qualité sans valeur associée).
procedure TWinLivres.AjouterLigneDetail(Libelle, Valeur: String; Toujours: Boolean = False);
var
  Ligne: Integer;
begin
  if (Valeur = '') and (not Toujours) then Exit;
  
  Ligne := StringGridDetail.RowCount;
  StringGridDetail.RowCount := Ligne + 1;
  StringGridDetail.Cells[1, Ligne] := Libelle;
  StringGridDetail.Cells[2, Ligne] := Valeur;
end;

// Préfixe de livre d'un code, "RULES-COMB_05" -> "RULES-".
// Les codes référencés dans les champs sont écrits sans préfixe alors que
// les id des éléments le portent.
function TWinLivres.PrefixeLivre(Code: String): String;
var
  P: Integer;
begin
  P := Pos('-', Code);
  if P > 0 then
    Result := Copy(Code, 1, P)
  else
    Result := '';
end;

// Remplit la grille des qualités. Grille séparée de la grille générale
// parce que les deux n'ont pas la même nature : la générale a une ligne fixe
// par champ du XML, celle-ci une liste variable qu'on pourra compléter.
// Format : "WEAPB18 2,WEAPB08,WEAPB27" — certaines portent une valeur,
// séparée du code par une espace.
// Traduit une valeur de champ qui contient un ou plusieurs codes séparés
// par des virgules, par exemple Quality = "ARMOB_03,ARMOB_08".
function TWinLivres.TraduireCodesMultiples(Valeur: String): String;
var
  Codes: TStringList;
  I: Integer;
begin
  Result := '';
  if (Valeur = '') or (Valeur = '-') then
  begin
    Result := Valeur;
    Exit;
  end;
  
  Codes := TStringList.Create;
  try
    Codes.Delimiter       := ',';
    Codes.StrictDelimiter := True;
    Codes.DelimitedText   := Valeur;
    
    for I := 0 to Codes.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + LibelleAffiche(Trim(Codes[I]));
    end;
  finally
    Codes.Free;
  end;
end;

// Affiche une arme ou une armure dans la grille clé/valeur.
// Les deux ont des champs différents, on n'affiche donc que ceux présents
// dans l'élément XML plutôt qu'un formulaire figé.
// Arme, armure, trapping, armure simplifiee : la fiche generique, modifiable seulement si le livre l'autorise
// (un livre officiel la montre en lecture seule). Titre n'est plus utilise.
procedure TWinLivres.AfficherDonneeEquipement(Code, TagName, Titre: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId(TagName, Code);
  if Element = nil then Exit;
  // livre WFRP2 : codes de disponibilite, de type et de portee propres a l'edition, que les listes fermees de la fiche WFRP4 refusent
  if ((TagName = 'Weapon') or (TagName = 'Armor')) and FicheGeneriqueV1Possible(Element) then
  begin
    if TagName = 'Weapon' then
      AfficherFicheGeneriqueV1(Element, TagName, NT_ARME, Code)
    else
      AfficherFicheGeneriqueV1(Element, TagName, NT_ARMURE, Code);
  end
  else if TagName = 'Weapon' then
    AfficherFicheArme(Element)
  else if TagName = 'Armor' then
    AfficherFicheArmure(Element)
  else if TagName = 'Trapping' then
  begin
    FamillesTalent := '';  // nouvelle navigation : les familles cochees ne se gardent pas d'un objet a l'autre
    AfficherFicheTrapping(Element);
  end
  else if TagName = 'ArmorSimp' then
    AfficherFicheArmureSimple(Element);
  CodeDonneeSelectionnee := Code;
end;

// Fiche d'une armure simplifiee (DATA_ARMOR_SIMP) : affichage seul, meme dans un livre de fan (aucune creation).
procedure TWinLivres.AfficherFicheArmureSimple(Element: TDOMElement);
var
  Dispos: String;
  I: Integer;
begin
  if Element = nil then Exit;
  FicheTag := 'ArmorSimp';
  FicheTypeNoeud := NT_ARMURE_SIMPLIFIEE;
  RemplirQualitesArme('ARMOB');
  Dispos := '';
  for I := Low(DisposEquipement) to High(DisposEquipement) do
    Dispos := Dispos + '|' + DisposEquipement[I];
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('ArmorPoint', 'RULES-LAB_076', gfTexte, False, True, False, False, '', cfEntier),
    ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, True, False, False, '', cfEntier),
    ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix),
    ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, True, False, False, Copy(Dispos, 2, MaxInt)),
    ChampFiche('Quality', 'RULES-LAB_476', gfQualites, False, False, False, False)]);
  // ordre du schema (ArmorSimpType)
  PanelFiche.OrdreBalises := 'Description,Availability,Price,Encumbrance,Quality,ArmorPoint';
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := True;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
end;

// Fiche d'une armure : seule la liste des champs lui est propre ; modifiable si le livre l'autorise.
procedure TWinLivres.AfficherFicheArmure(Element: TDOMElement);
var
  Dispos, Materiaux, Emplacements: String;
  I: Integer;
begin
  if Element = nil then Exit;
  FicheTag := 'Armor';
  FicheTypeNoeud := NT_ARMURE;
  RemplirQualitesArme('ARMOB');
  Dispos := '';
  for I := Low(DisposEquipement) to High(DisposEquipement) do
    Dispos := Dispos + '|' + DisposEquipement[I];
  Materiaux := '';
  for I := Low(MateriauxArmure) to High(MateriauxArmure) do
    Materiaux := Materiaux + '|' + MateriauxArmure[I];
  Emplacements := '';
  for I := Low(EmplacementsArmure) to High(EmplacementsArmure) do
    Emplacements := Emplacements + '|' + EmplacementsArmure[I] + '=' + LibelleAffiche(EmplacementsArmure[I]);
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('ArmorPoint', 'RULES-LAB_076', gfTexte, False, True, False, False, '', cfEntier),
    ChampFiche('Type', 'RULES-LAB_074', gfCode, False, True, False, False, Copy(Materiaux, 2, MaxInt)),
    ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, True, False, False, '', cfEntier),
    ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix),
    ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, True, False, False, Copy(Dispos, 2, MaxInt)),
    ChampFiche('Location', 'RULES-LAB_075', gfCases, False, True, False, False, Copy(Emplacements, 2, MaxInt)),
    ChampFiche('Quality', 'RULES-LAB_476', gfQualites, False, False, False, False)]);
  RemplirCompLieeFiche('');  // cibles de competence de la grille (liste commune avec la fiche de talent)
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Fiche d'une arme : seule la liste des champs lui est propre ; modifiable si le livre l'autorise.
procedure TWinLivres.AfficherFicheArme(Element: TDOMElement);
const
  PorteesCorps: array[0..10] of String = ('PERSO', 'VSHORT', 'CLOSE', 'SHORT', 'AVERAGE', 'MID', 'LONG', 'VLONG', 'BIG', 'HUGE', 'MASSIVE');
var
  Groupes, Portees, Dispos, Code, Lib: String;
  Tri: TStringList;
  I: Integer;
begin
  if Element = nil then Exit;
  FicheTag := 'Weapon';
  FicheTypeNoeud := NT_ARME;
  RemplirQualitesArme('WEAPB');
  // groupes de competence proposes : "code=libelle"
  Groupes := '';
  Tri := TStringList.Create;
  try
    RemplirGroupesArmes(Tri);
    for I := 0 to Tri.Count - 1 do
      Groupes := Groupes + '|' + Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I])) + '=' + Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
  finally
    Tri.Free;
  end;
  // portees : les portees different d'une edition a l'autre (VSHORT, AVERAGE, VLONG, MASSIVE n'existent qu'en WFRP5),
  // un code sans libelle n'appartient pas a l'edition chargee ; puis le bonus de Force x N
  Portees := '';
  for I := Low(PorteesCorps) to High(PorteesCorps) do
  begin
    Code := 'RULES-WEAPR_' + PorteesCorps[I];
    Lib := LibelleAffiche(Code);
    if Lib = Code then Continue;
    Portees := Portees + '|' + Code + '=' + Lib;
  end;
  for I := 1 to 4 do
  begin
    if I = 1 then Code := '(BATTR_S)' else Code := '(BATTR_S)X' + IntToStr(I);
    Portees := Portees + '|' + Code + '=' + GetTexteLibelle('RULES-LAB_034') + ' ' + GetAttributLabel('RULES-ATTR_S') + ' x ' + IntToStr(I);
  end;
  Dispos := '';
  for I := Low(DisposEquipement) to High(DisposEquipement) do
    Dispos := Dispos + '|' + DisposEquipement[I];
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True),
    ChampFiche('Skill', 'RULES-LAB_437', gfCode, False, False, False, False, Copy(Groupes, 2, MaxInt)),
    ChampFiche('Hand', 'RULES-LAB_053', gfListe, False, True, False, False, '0|1|2', cfEntier),
    ChampFiche('Ammunition', 'RULES-LAB_060', gfTexte, False, True, False, False, '', cfEntier),
    ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, True, False, False, '', cfEntier),
    ChampFiche('Price', 'RULES-LAB_054', gfTexte, False, False, True, False, '', cfPrix),
    ChampFiche('Availability', 'RULES-LAB_056', gfCode, False, True, False, False, Copy(Dispos, 2, MaxInt)),
    ChampFiche('Reach', 'RULES-LAB_057', gfCodeLibre, False, False, True, False, Copy(Portees, 2, MaxInt)),
    ChampFiche('Damage', 'RULES-LAB_159', gfDegats, True, False, False, False),
    ChampFiche('Quality', 'RULES-LAB_476', gfQualites, False, False, False, False)]);
  RemplirCompLieeFiche('');  // cibles de competence de la grille (liste commune avec la fiche de talent)
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// ========== AFFICHER DONNÉE SORT ==========
// Fiche d'un sort : meme presentation que les autres elements (PanelFiche), editable si le livre l'autorise,
// sinon en lecture seule. Duree et portee : gabarits a jetons (BATTR_xx) / (ATTR_xx) lus par le moteur, saisie libre permise.
// Talents d'acces : cases a cocher (virgules), au moins un obligatoire.
procedure TWinLivres.AfficherFicheSort(Element: TDOMElement);
var
  Types, Talents, Duree, Portee, Coches: String;
  I: Integer;
  Unites: array[0..3] of String;
begin
  if Element = nil then Exit;
  FicheTag := 'Sort';
  FicheTypeNoeud := NT_SORT;
  Types := '';
  for I := Low(TypesSortXml) to High(TypesSortXml) do
    Types := Types + '|' + TypesSortXml[I] + '=' + GetTexteLibelle(TypesSortLib[I]);
  RemplirTalentsSort(ValeurXML(Element.FindNode('TypSpell')));
  // talent d'acces : controle a FicheValiderClick (un <Talent> ou une ligne de DATA_SPELL_TALENT)
  // talents du sort = son <Talent> + les lignes de DATA_SPELL_TALENT du livre (les dieux d'une benediction)
  Coches := ValeurXML(Element.FindNode('Talent'));
  if TalentsDeTable(Element.GetAttribute('id')) <> '' then
  begin
    if Coches <> '' then Coches := Coches + ',';
    Coches := Coches + TalentsDeTable(Element.GetAttribute('id'));
  end;
  Talents := '|' + ChoixTalentsSort(Coches);
  for I := 0 to 3 do
    Unites[I] := GetTexteLibelle('RULES-LAB_' + IntToStr(426 + I));
  Duree := GetTexteLibelle('RULES-LAB_430');
  for I := 0 to 3 do
    Duree := Duree + '|(BATTR_WP) ' + Unites[I];
  Duree := Duree + '|(BATTR_Fel) ' + Unites[0] + '|(BATTR_Int) ' + Unites[0] + '|6 ' + Unites[0] + '|1 ' + Unites[0];
  Portee := GetTexteLibelle('RULES-LAB_431') + '|' + GetTexteLibelle('RULES-LAB_432') +
    '|(ATTR_WP)m|(BATTR_WP)m|(ATTR_Fel)m|(ATTR_Int)m|6m';
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, False, True),
    ChampFiche('TypSpell', 'RULES-LAB_116', gfCode, False, True, False, False, Copy(Types, 2, MaxInt)),
    ChampFiche('Duration', 'RULES-LAB_109', gfListe, False, False, True, False, Duree),
    ChampFiche('Range', 'RULES-LAB_057', gfListe, False, False, True, False, Portee),
    ChampFiche('Target', 'RULES-LAB_108', gfTexte, False, False, True, False),
    // texte libre : le niveau d'un rituel peut etre une formule (« Equal to the Beast's Wounds », « 50 (25) »)
    ChampFiche('Level', 'RULES-LAB_019', gfTexte, False, False, True, False),
    ChampFiche('Talent', 'RULES-LAB_007', gfCases, True, False, True, False, Copy(Talents, 2, MaxInt)),
    ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True),
    ChampFiche('XpFixed', 'RULES-LAB_959', gfTexte, True, False, True, False),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  // ordre du schema (SortType) : sans lui, un sort neuf est ecrit dans l'ordre d'affichage de la fiche
  PanelFiche.OrdreBalises := 'Description,*Explanation,Target,Duration,Range,Talent,Level,TypSpell,*XpFixed,*CULTE,*Page';
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.CocherCodes('Talent', Coches);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
  CocherTalentUnique;  // apres le snapshot : la case cochee compte comme une modification, Valider s'active
end;

procedure TWinLivres.AfficherDonneeSort(Code, Titre: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Sort', Code);
  if Element = nil then Exit;
  AfficherFicheSort(Element);
  CodeDonneeSelectionnee := Code;
end;

// Contenu des champs de l'ecran modifiable affiche (fiche, entete de carriere, race, panneau d'arme ou de sort).
// '' si aucun : sert a detecter un changement, comme InstantaneSkills pour les grilles.
function TWinLivres.InstantaneFiche: String;
const
  Sep = #1;
begin
  Result := '';
  if PanelFiche.Visible then
    Result := 'M' + PanelFiche.Signature(Sep)
  else if PanelTirage.Visible then
    Result := 'T' + PanelTirage.Signature(Sep)
  else if PanelTirageRace.Visible then
    Result := 'R' + PanelTirageRace.Signature(Sep)
  else if PanelTirageMetier.Visible then
    Result := 'C' + PanelTirageMetier.Signature(Sep)
  else if PanelEquipClasse.Visible then
    Result := 'E' + PanelEquipClasse.Signature(Sep)
  else if PanelTraitEthnie.Visible then
    Result := 'N' + PanelTraitEthnie.Signature(Sep)
  else if PanelCarriereEspece.Visible then
    Result := 'S' + PanelCarriereEspece.Signature(Sep)
  else if PanelRegleEthnie.Visible then
    Result := 'G' + PanelRegleEthnie.Signature(Sep)
  else if PanelTraduction.Visible then
    Result := 'L' + PanelTraduction.Signature(Sep)
  else if PanelSousMetier.Visible then
    Result := 'U' + PanelSousMetier.Signature(Sep);
end;

procedure TWinLivres.PrendreSnapshotFiche;
begin
  FicheSnapshot := InstantaneFiche;
  MajBoutonsFiche;
end;

// Valider et Annuler ne servent qu'une fois quelque chose modifie.
procedure TWinLivres.MajBoutonsFiche;
var
  Modifie: Boolean;
begin
  Modifie := (FicheSnapshot <> '') and (InstantaneFiche <> FicheSnapshot);
  if PanelFiche.Visible then
    PanelFiche.ActiverBoutons(Modifie);
  if PanelTirage.Visible then
    PanelTirage.ActiverBoutons(Modifie);
  if PanelTirageRace.Visible then
    PanelTirageRace.ActiverBoutons(Modifie);
  if PanelTirageMetier.Visible then
    PanelTirageMetier.ActiverBoutons(Modifie);
  if PanelEquipClasse.Visible then
    PanelEquipClasse.ActiverBoutons(Modifie);
  if PanelTraitEthnie.Visible then
    PanelTraitEthnie.ActiverBoutons(Modifie);
  if PanelCarriereEspece.Visible then
    PanelCarriereEspece.ActiverBoutons(Modifie);
  if PanelRegleEthnie.Visible then
    PanelRegleEthnie.ActiverBoutons(Modifie);
  if PanelTraduction.Visible then
    PanelTraduction.ActiverBoutons(Modifie);
  if PanelSousMetier.Visible then
    PanelSousMetier.ActiverBoutons(Modifie);
  if (FicheSnapshot <> '') and GroupBoxForm.Visible then
  begin
  end;
  // Valider/Annuler/Supprimer du formulaire : seulement sur un ecran modifiable
end;

procedure TWinLivres.TimerFicheTimer(Sender: TObject);
begin
  if FicheSnapshot <> '' then
    MajBoutonsFiche;
end;

// Bouton au style de ceux du haut a gauche (copie de ButtonChargerXML, puis habillage de globalfonts).
function TWinLivres.NouveauBouton(Proprio: TComponent): TBCButton;
begin
  Result := TBCButtonContour.Create(Proprio);
  Result.Assign(ButtonChargerXML);
  Result.Caption := '';
  Result.OnClick := nil;
end;

// Boutons des boites de dialogue : Tag = resultat modal (TBCButton n'a pas de ModalResult).
procedure TWinLivres.BoutonDialogueClick(Sender: TObject);
begin
  GetParentForm(TControl(Sender)).ModalResult := TControl(Sender).Tag;
end;

// Entree valide, Echap annule (le role de Default/Cancel des anciens boutons).
procedure TWinLivres.ToucheDialogue(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then
    TForm(Sender).ModalResult := mrOk
  else if Key = 27 then
    TForm(Sender).ModalResult := mrCancel
  else
    Exit;
  Key := 0;
end;

// Libelle d'un talent coche qui n'est plus dans la liste proposee (le type du sort a change) : Description du livre
// ouvert, du Rulebook, puis des talents charges, enfin le libelle d'un code ; le code lui-meme en dernier recours.
function TWinLivres.LibelleTalentCoche(const Code: String): String;
var
  Doc: TXMLDocument;
  Elems: TDOMNodeList;
  I, N: Integer;
begin
  Result := '';
  for N := 0 to 1 do
  begin
    if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
    if Doc = nil then Continue;
    Elems := Doc.GetElementsByTagName('Talent');
    for I := 0 to Elems.Count - 1 do
      if TDOMElement(Elems.Item[I]).GetAttribute('id') = Code then
      begin
        Result := ValeurXML(Elems.Item[I].FindNode('Description'));
        if Result <> '' then Exit;
      end;
  end;
  Result := ChercheTalent(Code).Libelle;
  if Result = '' then Result := LibelleAffiche(Code);
end;

// Talents proposes pour l'acces a un sort : ceux deja cites par un sort du livre ouvert ou du Rulebook,
// tries par libelle ; un libelle en double est suivi de son code.
// Cases de talents d'un sort ("code=libelle|..."), a appeler apres RemplirTalentsSort : les talents deja coches en tete
// (libelle propose, sinon libelle du code) ; livre modifiable : suivis des autres talents proposes ; lecture seule : seulement les coches.
function TWinLivres.ChoixTalentsSort(const TalentsCoches: String): String;
var
  Propres: TStringList;
  I, J: Integer;
  Lib: String;
begin
  Result := '';
  Propres := TStringList.Create;
  try
    Propres.Delimiter := ',';
    Propres.StrictDelimiter := True;
    Propres.DelimitedText := TalentsCoches;
    for I := 0 to Propres.Count - 1 do
    begin
      Propres[I] := Trim(Propres[I]);
      if Propres[I] = '' then Continue;
      J := TalSortCodes.IndexOf(Propres[I]);
      if J >= 0 then Lib := TalSortLib[J] else Lib := LibelleTalentCoche(Propres[I]);
      if Lib = '' then Lib := Propres[I];
      if Result <> '' then Result := Result + '|';
      Result := Result + Propres[I] + '=' + Lib;
    end;
    if CreationPermise then
      for I := 0 to TalSortCodes.Count - 1 do
        if Propres.IndexOf(TalSortCodes[I]) < 0 then
        begin
          if Result <> '' then Result := Result + '|';
          Result := Result + TalSortCodes[I] + '=' + TalSortLib[I];
        end;
  finally
    Propres.Free;
  end;
end;

// Fourchette de d100 d'un signe astral : "05", "01-05", "96-00" (00 = 100). False si le format ou les bornes sont faux.
function FourchetteSigne(const S: String; out Debut, Fin: Integer): Boolean;
var
  P: Integer;
  A, B: String;

  function Borne(const T: String): Integer;
  begin
    Result := StrToIntDef(Trim(T), -1);
    if Result = 0 then Result := 100;
  end;

begin
  P := Pos('-', S);
  if P > 0 then
  begin
    A := Copy(S, 1, P - 1);
    B := Copy(S, P + 1, MaxInt);
  end
  else
  begin
    A := S;
    B := S;
  end;
  Debut := Borne(A);
  Fin := Borne(B);
  Result := (Debut >= 1) and (Fin <= 100) and (Debut <= Fin);
end;

// Controle propre a la fiche, avant l'ecriture. Signe astral : la fourchette est valide et ne recouvre celle d'aucun
// autre signe du livre (le trou est permis : un livre de fan peut ne decrire qu'une partie de la table).
function TWinLivres.FicheControler: Boolean;
var
  Elems: TDOMNodeList;
  I, D, F, D2, F2: Integer;
  Autre: TDOMElement;
  Signe: StructureSigneAstral;
  LivreOuvert, Masques: String;
begin
  Result := True;
  if (FicheTag <> 'StarSign') or (XMLDoc = nil) then Exit;
  if not FourchetteSigne(Trim(PanelFiche.ValeurChamp('Range')), D, F) then
  begin
    ShowMessage(Format(GetTexteLibelle('RULES-LAB_539', 'Range "%s" is invalid: use 05, 01-05 or 96-00 (00 = 100), between 1 and 100.'),
      [PanelFiche.ValeurChamp('Range')]));
    Exit(False);
  end;
  Elems := XMLDoc.GetElementsByTagName('StarSign');
  for I := 0 to Elems.Count - 1 do
  begin
    Autre := TDOMElement(Elems.Item[I]);
    if Autre.GetAttribute('id') = CodeDonneeSelectionnee then Continue;
    if not FourchetteSigne(Trim(ValeurXML(Autre.FindNode('Range'))), D2, F2) then Continue;
    if (D <= F2) and (D2 <= F) then
    begin
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_540', 'This range overlaps the one of %s.'), [ValeurXML(Autre.FindNode('Description'))]));
      Exit(False);
    end;
  end;
  // Signes d'AUTRES livres : le dernier livre charge gagne sur une plage commune, donc le signe de ce livre
  // masquera l'autre sur la plage recouverte. Avertissement seulement, l'enregistrement continue.
  LivreOuvert := ValeurXML(XMLDoc.DocumentElement.FindNode(ConstXmlLibelleLivre));
  Masques := '';
  for Signe in ListSigneAstralSource do
    if (Signe.Livre <> LivreOuvert) and FourchetteSigne(Signe.Plage, D2, F2) and (D <= F2) and (D2 <= F) then
      Masques := Masques + #10 + Signe.Libelle + ' (' + Signe.Livre + ', ' + Signe.Plage + ')';
  if Masques <> '' then
    ShowMessage(Format(GetTexteLibelle('RULES-LAB_687', 'This range overlaps star signs of other books. The last loaded book wins, so this sign will hide them on the common range:%s'), [Masques]));
end;

// Talents proposes pour un signe astral ("code=libelle|...", tries par libelle) : tous ceux du livre ouvert et du Rulebook.
// Le talent courant s'y ajoute s'il n'y est pas (un generique "RULES-T0092_*" garde son code, avec le libelle du talent de base).
function TWinLivres.ChoixTalentsSigne(const Courant: String): String;
var
  Liste, Vus: TStringList;
  Doc: TXMLDocument;
  Elems: TDOMNodeList;
  I, N, P: Integer;
  Code, Lib, Prec: String;
begin
  Result := '';
  Liste := TStringList.Create;
  Vus := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupAccept;
    Vus.Sorted := True;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      Elems := Doc.GetElementsByTagName('Talent');
      for I := 0 to Elems.Count - 1 do
      begin
        Code := TDOMElement(Elems.Item[I]).GetAttribute('id');
        if (Code = '') or (Vus.IndexOf(Code) >= 0) then Continue;
        Vus.Add(Code);
        Liste.Add(LibelleTalentTirage(Code) + #9 + Code);
      end;
    end;
    if (Courant <> '') and (Vus.IndexOf(Courant) < 0) then
    begin
      Lib := LibelleTalentTirage(RadicalTalent(Courant));
      if (Length(Courant) > 0) and (Courant[Length(Courant)] = '*') then Lib := Lib + ' (*)';
      Liste.Add(Lib + #9 + Courant);
    end;
    Prec := '';
    for I := 0 to Liste.Count - 1 do
    begin
      P := Pos(#9, Liste[I]);
      Lib := Copy(Liste[I], 1, P - 1);
      Code := Copy(Liste[I], P + 1, MaxInt);
      if Lib = Prec then Lib := Lib + ' [' + Code + ']' else Prec := Lib;
      if Result <> '' then Result := Result + '|';
      Result := Result + Code + '=' + Lib;
    end;
  finally
    Vus.Free;
    Liste.Free;
  end;
end;

// Sort modifiable sans talent coche dont la liste ne propose qu'un seul talent : on le coche (jamais pour une benediction,
// ou un sort deja relie par DATA_SPELL_TALENT : alors la fiche ne touche a rien).
procedure TWinLivres.CocherTalentUnique;
begin
  if (FicheTag <> 'Sort') or not CreationPermise then Exit;
  if PanelFiche.ValeurChamp('Talent') <> '' then Exit;
  if TalentsDeTable(CodeDonneeSelectionnee) <> '' then Exit;
  if TalSortCodes.Count = 1 then PanelFiche.CocherTout('Talent');
end;

// Un champ liste fermee de la fiche a change : pour un sort, le type decide des talents proposes.
procedure TWinLivres.FicheChangementChamp(const Balise: String);
var
  Coches: TStringList;
  I: Integer;
begin
  // famille de talent cochee / decochee : la fiche est reconstruite apres l'evenement (le controle clique serait detruit)
  if ((FicheTag = 'Talent') and (Balise = 'FamilleTalent')) or ((FicheTag = 'Trapping') and (Balise = 'FamilleTrapping')) or
     ((FicheTag = 'Career') and (Balise = 'FamilleCarriere')) or ((FicheTag = 'Specie') and (Balise = 'FamilleEthnie')) then
  begin
    FamillesTalent := UpperCase(PanelFiche.ValeurChamp(Balise));
    // minuteur et non file asynchrone : le clic sur la case doit etre completement termine avant que Definir
    // detruise la liste de cases (detruite pendant son propre clic, WinLivre se fermait)
    if FTimerFamille = nil then
    begin
      FTimerFamille := TTimer.Create(Self);
      FTimerFamille.Enabled := False;
      FTimerFamille.Interval := 80;
      FTimerFamille.OnTimer := @TimerFamilleTick;
    end;
    FTimerFamille.Enabled := False;
    FTimerFamille.Enabled := True;
    Exit;
  end;
  if (FicheTag = 'Sort') and (Balise = 'TypSpell') and CreationPermise then
  begin
    RemplirTalentsSort(PanelFiche.ValeurChamp('TypSpell'));
    // seuls restent coches les talents encore proposes pour le nouveau type (un talent hors famille serait refuse)
    Coches := TStringList.Create;
    try
      Coches.Delimiter := ',';
      Coches.StrictDelimiter := True;
      Coches.DelimitedText := PanelFiche.ValeurChamp('Talent');
      for I := Coches.Count - 1 downto 0 do
        if (TalSortCodes.Count > 0) and (TalSortCodes.IndexOf(Trim(Coches[I])) < 0) then Coches.Delete(I);
      PanelFiche.RemplacerChoix('Talent', ChoixTalentsSort(Coches.DelimitedText));
    finally
      Coches.Free;
    end;
    CocherTalentUnique;
  end;
end;

// True si la liste "A,B,C" contient Valeur (comparaison sans casse, espaces ignores).
function ListeContient(const Liste, Valeur: String): Boolean;
var
  L: TStringList;
  I: Integer;
begin
  Result := False;
  L := TStringList.Create;
  try
    L.Delimiter := ',';
    L.StrictDelimiter := True;
    L.DelimitedText := Liste;
    for I := 0 to L.Count - 1 do
      if SameText(Trim(L[I]), Valeur) then Exit(True);
  finally
    L.Free;
  end;
end;


// Chapitres qui ne definissent que les regles de base du jeu : dans un livre autre que le Rulebook,
// on ne montre pas leur branche tant que le livre n'y met rien.
function TWinLivres.ChapitreReserveRulebook(const Chapitre: String): Boolean;
begin
  Result := AutreLivreRulebook and
    ((Chapitre = 'DATA_ATTRIBUT') or
     (Chapitre = 'DATA_SKILL_COST') or (Chapitre = 'DATA_ATTRIBUT_COST') or
     (Chapitre = 'DATA_CORRUPTION_PHYSICAL_CHANCE') or (Chapitre = 'DATA_CORRUPTION_MENTAL_CHANCE'));
end;

// Vrai si le livre ouvert n'est pas le Rulebook (il en reprend alors les elements, en lecture seule).
function TWinLivres.AutreLivreRulebook: Boolean;
var
  A, B: TDOMNode;
begin
  Result := False;
  if (XMLDoc = nil) or (RulebookXML = nil) then Exit;
  A := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  B := RulebookXML.GetElementsByTagName('DATA_BOOK').Item[0];
  if (A = nil) or (B = nil) then Exit;
  Result := ValeurXML(A.FindNode('CODE_BOOK')) <> ValeurXML(B.FindNode('CODE_BOOK'));
end;

// Un talent ou une specialisation de talent du Rulebook (nil si absent) : affiche, jamais modifie.
function TWinLivres.TrouverTalentRulebook(const Id: String): TDOMElement;
var
  Elements: TDOMNodeList;
  I: Integer;
begin
  Result := nil;
  if (RulebookXML = nil) or (Id = '') then Exit;
  Elements := RulebookXML.GetElementsByTagName('Talent');
  for I := 0 to Elements.Count - 1 do
    if TDOMElement(Elements.Item[I]).GetAttribute('id') = Id then
    begin
      Result := TDOMElement(Elements.Item[I]);
      Exit;
    end;
end;

// La liste "A,B,C" privee de Valeur (comparaison sans casse).
function RetirerDeListe(const Liste, Valeur: String): String;
var
  L: TStringList;
  I: Integer;
begin
  Result := '';
  L := TStringList.Create;
  try
    L.Delimiter := ',';
    L.StrictDelimiter := True;
    L.DelimitedText := Liste;
    for I := 0 to L.Count - 1 do
      if (Trim(L[I]) <> '') and not SameText(Trim(L[I]), Valeur) then
      begin
        if Result <> '' then Result := Result + ',';
        Result := Result + Trim(L[I]);
      end;
  finally
    L.Free;
  end;
end;

// Toutes les benedictions des livres (Rulebook et livre ouvert) sous la forme "code=libelle|..." triee par libelle ;
// Coches = celles qui citent ce dieu (leur <Talent>, ou une ligne de DATA_SPELL_TALENT de l'un des deux livres).
// Cases a cocher "code=libelle|..." pour les libelles RULES-LAB_<Premier> a RULES-LAB_<Dernier> (localites, saisons).
function TWinLivres.ChoixCasesLabels(Premier, Dernier: Integer): String;
var
  I: Integer;
  Code: String;
begin
  Result := '';
  for I := Premier to Dernier do
  begin
    Code := 'RULES-LAB_' + IntToStr(I);
    if Result <> '' then Result := Result + '|';
    Result := Result + Code + '=' + GetTexteLibelle(Code);
  end;
end;

function TWinLivres.ChoixBenedictions(const Dieu: String; out Coches, Verrous: String): String;
var
  Vus, Tri: TStringList;
  Docs: array[0..1] of TXMLDocument;
  D, J, I: Integer;
  Elements: TDOMNodeList;
  El: TDOMElement;
  Id, Lib, PrefRulebook: String;
  Cite, CiteRulebook, Autre: Boolean;
begin
  Result := '';
  Coches := '';
  Verrous := '';
  Autre := AutreLivreRulebook;
  PrefRulebook := '';
  if Autre then PrefRulebook := ValeurXML(RulebookXML.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('CODE_BOOK'));
  Docs[0] := RulebookBaseXML;
  Docs[1] := XMLDoc;
  Vus := TStringList.Create;
  Tri := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupAccept;
    Vus.Sorted := True;
    Vus.Duplicates := dupIgnore;
    for D := 0 to 1 do
    begin
      if Docs[D] = nil then Continue;
      Elements := Docs[D].GetElementsByTagName('Sort');
      for J := 0 to Elements.Count - 1 do
      begin
        El := TDOMElement(Elements.Item[J]);
        if (El.ParentNode <> nil) and (El.ParentNode.NodeName = 'DATA_SPELL_TALENT') then Continue;
        if not SameText(ValeurXML(El.FindNode('TypSpell')), 'Blessing') then Continue;
        Id := El.GetAttribute('id');
        if Vus.IndexOf(Id) >= 0 then Continue;
        Vus.Add(Id);
        Lib := ValeurXML(El.FindNode('Description'));
        if Lib = '' then Lib := Id;
        Tri.Add(Lib + #1 + Id);
      end;
    end;
    for I := 0 to Tri.Count - 1 do
    begin
      Id := Copy(Tri[I], Pos(#1, Tri[I]) + 1, MaxInt);
      Lib := Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
      Cite := False;
      CiteRulebook := False;
      for D := 0 to 1 do
      begin
        if Docs[D] = nil then Continue;
        if ListeContient(TalentsDeTableDoc(Docs[D], Id), Dieu) then
        begin
          Cite := True;
          if Autre and (D = 0) then CiteRulebook := True;
        end;
        Elements := Docs[D].GetElementsByTagName('Sort');
        for J := 0 to Elements.Count - 1 do
        begin
          El := TDOMElement(Elements.Item[J]);
          if (El.ParentNode <> nil) and (El.ParentNode.NodeName = 'DATA_SPELL_TALENT') then Continue;
          if (El.GetAttribute('id') = Id) and ListeContient(ValeurXML(El.FindNode('Talent')), Dieu) then
          begin
            Cite := True;
            if Autre and (D = 0) then CiteRulebook := True;
          end;
        end;
      end;
      // une relation portee par le Rulebook (autre livre que celui ouvert) ne se decoche pas : verrou, signale par le livre
      if CiteRulebook then Lib := Lib + ' [' + PrefRulebook + ']';
      if Result <> '' then Result := Result + '|';
      Result := Result + Id + '=' + Lib;
      if Cite then
      begin
        if Coches <> '' then Coches := Coches + ',';
        Coches := Coches + Id;
      end;
      if CiteRulebook then
      begin
        if Verrous <> '' then Verrous := Verrous + ',';
        Verrous := Verrous + Id;
      end;
    end;
  finally
    Tri.Free;
    Vus.Free;
  end;
end;

// Fiche d'un dieu validee : seules les benedictions dont la case a change sont reecrites, dans le livre ouvert. Cochee =
// le dieu rejoint la ligne de DATA_SPELL_TALENT de la benediction ; decochee = il en sort (et de son <Talent> s'il y etait).
// Une relation portee par un autre livre (Rulebook) ne peut pas etre retiree d'ici.
procedure TWinLivres.RangerBenedictionsDieu(const Dieu: String);
var
  Choix, Inutile, Inutile2, Nouveau, Id, Table: String;
  Parts: TStringList;
  I: Integer;
  El: TDOMElement;
  Coche, Etait: Boolean;
begin
  Choix := ChoixBenedictions(Dieu, Inutile, Inutile2);
  Nouveau := PanelFiche.ValeurChamp('Benedictions');
  Parts := TStringList.Create;
  try
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := Choix;
    for I := 0 to Parts.Count - 1 do
    begin
      Id := Copy(Parts[I], 1, Pos('=', Parts[I]) - 1);
      Coche := ListeContient(Nouveau, Id);
      Etait := ListeContient(BenedInit, Id);
      if Coche = Etait then Continue;
      Table := TalentsDeTableDoc(XMLDoc, Id);
      if Coche then
      begin
        if Table <> '' then Table := Table + ',';
        EcrireTalentsTable(Id, Table + Dieu);
      end
      else
      begin
        EcrireTalentsTable(Id, RetirerDeListe(Table, Dieu));
        El := TrouverElementParId('Sort', Id);
        if (El <> nil) and (El.FindNode('Talent') <> nil) then
          EcrireValeurXML(TDOMElement(El.FindNode('Talent')), RetirerDeListe(ValeurXML(El.FindNode('Talent')), Dieu));
      end;
    end;
  finally
    Parts.Free;
  end;
end;

// Types de sort (<SpellTypes>) ouverts par chaque talent des livres (Rulebook, puis livre ouvert par-dessus), sous la
// forme "code=Type1,Type2" ; les talents sans type ne figurent pas. Une specialisation herite de son generique
// (<Generique>, a defaut le radical + '_*'), comme ChercheTalent.
procedure TWinLivres.TypesTalents(Resultat: TStringList);
var
  Propres, Gen, Ids: TStringList;
  I: Integer;
  Id, T, G: String;

  procedure Lire(Doc: TXMLDocument);
  var
    Elems: TDOMNodeList;
    J: Integer;
    Code, V: String;
  begin
    Elems := Doc.GetElementsByTagName('Talent');
    for J := 0 to Elems.Count - 1 do
    begin
      Code := TDOMElement(Elems.Item[J]).GetAttribute('id');
      if Code = '' then Continue;
      Ids.Add(Code);
      V := ValeurXML(Elems.Item[J].FindNode('SpellTypes'));
      if V <> '' then Propres.Values[Code] := V;
      V := ValeurXML(Elems.Item[J].FindNode('Generique'));
      if V <> '' then Gen.Values[Code] := V;
    end;
  end;

begin
  Resultat.Clear;
  Propres := TStringList.Create;
  Gen := TStringList.Create;
  Ids := TStringList.Create;
  try
    Ids.Sorted := True;
    Ids.Duplicates := dupIgnore;
    if RulebookXML <> nil then Lire(RulebookXML);
    if XMLDoc <> nil then Lire(XMLDoc);
    for I := 0 to Ids.Count - 1 do
    begin
      Id := Ids[I];
      T := Propres.Values[Id];
      if T = '' then
      begin
        G := Gen.Values[Id];
        if G = '' then G := CodeFamilleTalent(Id);
        if (G = '') and (Pos('_', Id) > 0) and (Pos('-T_', Id) = 0) then G := Copy(Id, 1, Pos('_', Id)) + '*';
        if (G <> '') and (G <> Id) then T := Propres.Values[G];
      end;
      if T <> '' then Resultat.Values[Id] := T;
    end;
  finally
    Ids.Free;
    Gen.Free;
    Propres.Free;
  end;
end;

// Premier talent coche qui n'ouvre pas ce type de sort, '' si tout est dans la famille. Aucun talent des livres ne
// declare ce type (livre sans <SpellTypes>) : pas de controle.
function TWinLivres.TalentHorsFamille(const TypeSort, Talents: String): String;
var
  Map, Codes: TStringList;
  I: Integer;
  Declare: Boolean;
begin
  Result := '';
  if TypeSort = '' then Exit;
  Map := TStringList.Create;
  Codes := TStringList.Create;
  try
    TypesTalents(Map);
    Declare := False;
    for I := 0 to Map.Count - 1 do
      if ListeContient(Map.ValueFromIndex[I], TypeSort) then
      begin
        Declare := True;
        Break;
      end;
    if not Declare then Exit;
    Codes.Delimiter := ',';
    Codes.StrictDelimiter := True;
    Codes.DelimitedText := Talents;
    for I := 0 to Codes.Count - 1 do
      if (Trim(Codes[I]) <> '') and not ListeContient(Map.Values[Trim(Codes[I])], TypeSort) then
        Exit(Trim(Codes[I]));
  finally
    Codes.Free;
    Map.Free;
  end;
end;

procedure TWinLivres.RemplirTalentsSort(const TypeSort: String);
var
  Tri, Cites, LibsTalents, TypesParId, MapTypes: TStringList;
  I: Integer;
  Lib, Code, TypeFiltre, TypeDuSort: String;

  // libelles de tous les talents (<Talent id> / <Description>), Rulebook d'abord, livre ouvert par-dessus
  procedure LireLibellesTalents(Doc: TXMLDocument);
  var
    Elems: TDOMNodeList;
    J: Integer;
    Id, D: String;
  begin
    Elems := Doc.GetElementsByTagName('Talent');
    for J := 0 to Elems.Count - 1 do
    begin
      Id := TDOMElement(Elems.Item[J]).GetAttribute('id');
      if Id = '' then Continue;
      D := ValeurXML(Elems.Item[J].FindNode('Description'));
      if D <> '' then LibsTalents.Values[Id] := D;
    end;
  end;

  // type de chaque sort (id -> TypSpell), pour les lignes de DATA_SPELL_TALENT qui n'en portent pas
  procedure LireTypes(Doc: TXMLDocument);
  var
    Elems: TDOMNodeList;
    J: Integer;
    Id, T: String;
  begin
    Elems := Doc.GetElementsByTagName('Sort');
    for J := 0 to Elems.Count - 1 do
    begin
      Id := TDOMElement(Elems.Item[J]).GetAttribute('id');
      T := ValeurXML(Elems.Item[J].FindNode('TypSpell'));
      if (Id <> '') and (T <> '') then TypesParId.Values[Id] := T;
    end;
  end;

  function LibelleTalent(const C: String): String;
  begin
    Result := LibsTalents.Values[C];
    if Result = '' then Result := LibelleAffiche(C);
    if Result = '' then Result := C;
  end;

  procedure Parcourir(Doc: TXMLDocument);
  var
    Elements: TDOMNodeList;
    J, K: Integer;
    Liste: TStringList;
  begin
    Liste := TStringList.Create;
    try
      Liste.Delimiter := ',';
      Liste.StrictDelimiter := True;
      Elements := Doc.GetElementsByTagName('Sort');
      for J := 0 to Elements.Count - 1 do
      begin
        // type connu : seulement les talents des sorts du meme type (derive des donnees ; la balise SpellTypes viendra).
        // Une ligne de DATA_SPELL_TALENT n'a pas de TypSpell : on prend celui du sort du meme id (les dieux d'une benediction).
        TypeDuSort := ValeurXML(Elements.Item[J].FindNode('TypSpell'));
        if TypeDuSort = '' then TypeDuSort := TypesParId.Values[TDOMElement(Elements.Item[J]).GetAttribute('id')];
        if (TypeFiltre <> '') and not SameText(TypeDuSort, TypeFiltre) then Continue;
        Liste.DelimitedText := ValeurXML(Elements.Item[J].FindNode('Talent'));
        for K := 0 to Liste.Count - 1 do
          if Trim(Liste[K]) <> '' then Cites.Add(Trim(Liste[K]));
      end;
    finally
      Liste.Free;
    end;
  end;

begin
  TalSortLib.Clear;
  TalSortCodes.Clear;
  Tri := TStringList.Create;
  Cites := TStringList.Create;
  LibsTalents := TStringList.Create;
  TypesParId := TStringList.Create;
  try
    if RulebookXML <> nil then LireLibellesTalents(RulebookXML);
    if RulebookXML <> nil then LireTypes(RulebookXML);
    if XMLDoc <> nil then LireTypes(XMLDoc);
    if XMLDoc <> nil then LireLibellesTalents(XMLDoc);
    Cites.Sorted := True;
    Cites.Duplicates := dupIgnore;
    Tri.Sorted := True;
    Tri.Duplicates := dupIgnore;
    TypeFiltre := TypeSort;
    // type connu : les talents qui DECLARENT l'ouvrir (<SpellTypes>, specialisations comprises) ; si aucun livre
    // n'en declare, repli sur les talents cites par les sorts du meme type.
    if TypeFiltre <> '' then
    begin
      MapTypes := TStringList.Create;
      try
        TypesTalents(MapTypes);
        for I := 0 to MapTypes.Count - 1 do
          if ListeContient(MapTypes.ValueFromIndex[I], TypeFiltre) then Cites.Add(MapTypes.Names[I]);
      finally
        MapTypes.Free;
      end;
    end;
    if Cites.Count = 0 then
    begin
      if XMLDoc <> nil then Parcourir(XMLDoc);
      if RulebookXML <> nil then Parcourir(RulebookXML);
    end;
    if (Cites.Count = 0) and (TypeFiltre <> '') then
    begin
      // aucun sort de ce type : tous les talents cites, comme avant
      TypeFiltre := '';
      if XMLDoc <> nil then Parcourir(XMLDoc);
      if RulebookXML <> nil then Parcourir(RulebookXML);
    end;
    for I := 0 to Cites.Count - 1 do
      Tri.Add(LibelleTalent(Cites[I]) + #1 + Cites[I]);
    for I := 0 to Tri.Count - 1 do
    begin
      Lib := Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
      Code := Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I]));
      if TalSortLib.IndexOf(Lib) >= 0 then Lib := Lib + ' (' + Code + ')';
      TalSortLib.Add(Lib);
      TalSortCodes.Add(Code);
    end;
  finally
    TypesParId.Free;
    LibsTalents.Free;
    Cites.Free;
    Tri.Free;
  end;
end;

// ========== PETITES TABLES TECHNIQUES ==========
// Met un élément à plat en une ligne : "Tag[id]=valeur" pour chaque enfant,
// récursivement entre parenthèses. Sert aux tables sans écran dédié.
function TWinLivres.AplatirElement(Element: TDOMElement): String;
var
  Enfant: TDOMNode;
  Cle, Sous: String;
begin
  Result := '';
  Enfant := Element.FirstChild;
  while Enfant <> nil do
  begin
    if Enfant.NodeType = ELEMENT_NODE then
    begin
      Cle := Enfant.NodeName;
      if TDOMElement(Enfant).GetAttribute('id') <> '' then
        Cle := Cle + '[' + TDOMElement(Enfant).GetAttribute('id') + ']'
      else if TDOMElement(Enfant).GetAttribute('name') <> '' then
        Cle := Cle + '[' + TDOMElement(Enfant).GetAttribute('name') + ']';

      Sous := AplatirElement(TDOMElement(Enfant));
      if Sous = '' then
        Sous := TraduireCodesDansTexte(ValeurXML(Enfant))
      else
        Sous := '(' + Sous + ')';

      if Result <> '' then
        Result := Result + '; ';
      Result := Result + Cle + '=' + Sous;
    end;
    Enfant := Enfant.NextSibling;
  end;
end;

// Libelle (<Description>) du talent de ce code, cherche dans le livre ouvert puis dans le Rulebook ; le code sinon.
function LibelleTalentDeCode(const Code: String; Docs: array of TXMLDocument): String;
var
  N, J: Integer;
  Elems: TDOMNodeList;
begin
  Result := Code;
  for N := Low(Docs) to High(Docs) do
  begin
    if Docs[N] = nil then Continue;
    Elems := Docs[N].GetElementsByTagName('Talent');
    for J := 0 to Elems.Count - 1 do
      if TDOMElement(Elems.Item[J]).GetAttribute('id') = Code then
      begin
        if ValeurXML(Elems.Item[J].FindNode('Description')) <> '' then
          Exit(ValeurXML(Elems.Item[J].FindNode('Description')));
      end;
  end;
end;

// Une entrée d'une petite table : une ligne par balise enfant.
procedure TWinLivres.AfficherDonneePetiteTable(Chapitre, TagElement, Code: String);
var
  Chap: TDOMNodeList;
  Elements: TDOMNodeList;
  I: Integer;
  Element, Trouve: TDOMElement;
  Enfant: TDOMNode;
  Valeur: String;
  ListeCodes: TStringList;
  K: Integer;
begin
  MasquerAfficherElements('DETAIL');
  MasquerForm();

  if XMLDoc = nil then Exit;
  Chap := XMLDoc.GetElementsByTagName(Chapitre);
  if Chap.Count = 0 then Exit;

  // Cherché dans SON chapitre : un même identifiant peut exister ailleurs
  // (les <Sort> de DATA_SPELL_TALENT reprennent ceux de DATA_SPELL).
  Trouve := nil;
  Elements := TDOMElement(Chap.Item[0]).GetElementsByTagName(TagElement);
  for I := 0 to Elements.Count - 1 do
  begin
    Element := TDOMElement(Elements.Item[I]);
    if (Element.GetAttribute('id') = Code) or (Element.GetAttribute('name') = Code) then
    begin
      Trouve := Element;
      Break;
    end;
  end;
  if Trouve = nil then Exit;

  // regle d'un livre WFRP1 : fiche generique (nom, page...), editable
  if (Chapitre = 'DATA_RULE') and FicheGeneriqueV1Possible(Trouve) then
  begin
    MasquerAfficherElements('');
    AfficherFicheGeneriqueV1(Trouve, TagElement, NT_PETITE_TABLE_DEBUT + 1, Code);
    Exit;
  end;

  StringGridDetail.RowCount := 1;
  StringGridDetail.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_002');
  StringGridDetail.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_025');

  // un sort de DATA_SPELL_TALENT : son nom (texte du noeud) dans le titre, le code reste sur la ligne « Code »
  if (Chapitre = 'DATA_SPELL_TALENT') and (NodeSelectionnee <> nil) then
    LabelFormTitle.Caption := LibelleChapitre(Chapitre) + ': ' + NodeSelectionnee.Text
  else
    LabelFormTitle.Caption := LibelleChapitre(Chapitre) + ': ' + Code;
  AjouterLigneDetail(GetTexteLibelle('RULES-LAB_001'), Code);

  Enfant := Trouve.FirstChild;
  while Enfant <> nil do
  begin
    if Enfant.NodeType = ELEMENT_NODE then
    begin
      Valeur := AplatirElement(TDOMElement(Enfant));
      if (Valeur = '') and (Chapitre = 'DATA_SPELL_TALENT') and (Enfant.NodeName = 'Talent') then
      begin
        // le talent du sort en libelle, pas son code ; plusieurs talents (dieux d'une benediction) = codes separes par des virgules
        ListeCodes := TStringList.Create;
        try
          ListeCodes.StrictDelimiter := True;
          ListeCodes.CommaText := ValeurXML(Enfant);
          // un talent par ligne (tableau) : le libelle de la balise n'est donne qu'a la premiere
          for K := 0 to ListeCodes.Count - 1 do
          begin
            Valeur := LibelleTalentDeCode(Trim(ListeCodes[K]), [XMLDoc, RulebookXML]);
            if K = 0 then AjouterLigneDetail(GetTexteLibelle(Enfant.NodeName), Valeur)
            else AjouterLigneDetail('', Valeur);
          end;
          Valeur := #1;  // lignes deja ajoutees
        finally
          ListeCodes.Free;
        end;
      end
      else if Valeur = '' then
        Valeur := TraduireCodesDansTexte(ValeurXML(Enfant))
      else
        Valeur := '(' + Valeur + ')';
      if TDOMElement(Enfant).GetAttribute('id') <> '' then
        Valeur := '[' + TDOMElement(Enfant).GetAttribute('id') + '] ' + Valeur;
      if Valeur <> #1 then AjouterLigneDetail(GetTexteLibelle(Enfant.NodeName), Valeur);
    end;
    Enfant := Enfant.NextSibling;
  end;

  CodeDonneeSelectionnee := Code;
  AdjustGridColumnsWidth(StringGridDetail, 0, False, False, True, 10, 10, ssAutoBoth);
  StringGridQualites.Visible := False;
end;

// Le chapitre DATA_RANDOM_TALENT du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore :
// les blocs <DATA_RANDOM_TALENT id=talent> qu'il contient portent le meme nom.
function TWinLivres.ChapitreTirageTalent: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_RANDOM_TALENT');
  if N <> nil then Result := TDOMElement(N);
end;

// Libelle d'un talent de la matrice : celui du livre ouvert (un talent cree dans cette session n'est pas
// encore dans les listes), sinon celui des listes du jeu.
function TWinLivres.LibelleTalentTirage(Code: String): String;
var
  El: TDOMElement;
  PT: StructureTalent;
begin
  Result := '';
  El := TrouverElementParId('Talent', Code);
  if El <> nil then Result := ValeurXML(El.FindNode('Description'));
  if Result = '' then
  begin
    PT := ChercheTalent(Code);
    if PT.CodeTalent = Code then Result := PT.Libelle;
  end;
  if Result = '' then Result := Code;
end;

function TWinLivres.LibelleEthnieTirage(Code: String): String;
var
  El: TDOMElement;
  PR: StructureRace;
begin
  Result := '';
  El := TrouverElementParId('Specie', Code);
  if El <> nil then Result := ValeurXML(El.FindNode('Description'));
  if Result = '' then
  begin
    PR := ChercheRace(Code);
    if PR.CodeRace = Code then Result := PR.Libelle;
  end;
  if Result = '' then Result := Code;
end;

// Matrice des tirages de talents : une ligne par talent, une colonne par ethnie du livre ouvert (plus la
// colonne generique "x"). Les talents proposes : ceux du jeu et ceux du livre ouvert.
procedure TWinLivres.AfficherTirageTalent;
var
  Talents, Ethnies: TStringList;
  PT: StructureTalent;
  Liste: TDOMNodeList;
  E: TDOMElement;
  I: Integer;
begin
  LabelFormTitle.Caption := LibelleChapitre('DATA_RANDOM_TALENT');
  Talents := TStringList.Create;
  Ethnies := TStringList.Create;
  try
    Talents.Sorted := True;
    Talents.Duplicates := dupIgnore;
    Ethnies.Sorted := True;
    Ethnies.Duplicates := dupIgnore;
    for PT in ListTalent do
      Talents.Add(PT.CodeTalent);
    Liste := XMLDoc.GetElementsByTagName('Talent');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Talents.Add(E.GetAttribute('id'));
    end;
    // les ethnies definies par le livre : <Specie id=...> (les <Specie> des blocs de tirage n'ont pas d'id)
    Liste := XMLDoc.GetElementsByTagName('Specie');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Ethnies.Add(E.GetAttribute('id'));
    end;
    PanelTirage.Configurer(@LibelleTalentTirage, @LibelleEthnieTirage, Talents, Ethnies);
  finally
    Talents.Free;
    Ethnies.Free;
  end;
  PanelTirage.Charger(ChapitreTirageTalent);
  PanelTirage.LectureSeule := not EditionPermise;
  PanelTirage.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelTirage.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelTirage.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelTirage.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelTirage.Visible := True;
  CodeDonneeSelectionnee := 'DATA_RANDOM_TALENT';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.TirageValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
begin
  if not PanelTirage.Controler then Exit;
  Chap := ChapitreTirageTalent;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_RANDOM_TALENT');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelTirage.Ecrire(Chap);
  AfficherDonneeChapitre('DATA_RANDOM_TALENT');
end;

procedure TWinLivres.TirageAnnulerClick(Sender: TObject);
begin
  AfficherDonneeChapitre('DATA_RANDOM_TALENT');
end;

// Le chapitre DATA_RANDOM_SPECIE du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore.
function TWinLivres.ChapitreTirageRace: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_RANDOM_SPECIE');
  if N <> nil then Result := TDOMElement(N);
end;

// Table du tirage de race : une ligne par race, avec le debut et la fin de sa fourchette. Races proposees :
// celles du livre ouvert et celles du Rulebook (un livre qui ajoute une race redonne la table complete).
procedure TWinLivres.AfficherTirageRaceMatrice;
var
  Races: TStringList;
  Liste: TDOMNodeList;
  E: TDOMElement;
  I: Integer;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  LabelFormTitle.Caption := GetTexteLibelle('RULES-LAB_042') + ' ' + GetTexteLibelle('RULES-LAB_085');
  Races := TStringList.Create;
  try
    Races.Sorted := True;
    Races.Duplicates := dupIgnore;
    // les <Specie id=...> sont les races (les <Specie name=...> du tirage n'ont pas d'id)
    Liste := XMLDoc.GetElementsByTagName('Specie');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Races.Add(E.GetAttribute('id'));
    end;
    if (RulebookXML <> nil) and AutreLivreRulebook then
    begin
      Liste := RulebookXML.GetElementsByTagName('Specie');
      for I := 0 to Liste.Count - 1 do
      begin
        E := TDOMElement(Liste.Item[I]);
        if E.GetAttribute('id') <> '' then Races.Add(E.GetAttribute('id'));
      end;
    end;
    PanelTirageRace.Configurer(@LibelleEthnieTirage, Races);
  finally
    Races.Free;
  end;
  PanelTirageRace.Charger(ChapitreTirageRace);
  PanelTirageRace.LectureSeule := not EditionPermise;
  PanelTirageRace.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelTirageRace.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelTirageRace.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelTirageRace.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelTirageRace.Visible := True;
  CodeDonneeSelectionnee := 'DATA_RANDOM_SPECIE';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.TirageRaceValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
begin
  if not PanelTirageRace.Controler then Exit;
  Chap := ChapitreTirageRace;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_RANDOM_SPECIE');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelTirageRace.Ecrire(Chap);
  AfficherTirageRaceMatrice;
end;

procedure TWinLivres.TirageRaceAnnulerClick(Sender: TObject);
begin
  AfficherTirageRaceMatrice;
end;

// Le chapitre DATA_CLASS_ITEM du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore.
function TWinLivres.ChapitreEquipClasse: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_CLASS_ITEM');
  if N <> nil then Result := TDOMElement(N);
end;

// Genre d'un objet d'apres son code (la premiere branche d'un choix "A/B") : 1 arme, 2 armure, 3 divers.
function TWinLivres.GenreEquipement(const Nom: String): Integer;
var
  Premier: String;
  P: Integer;
  TypeEquip: Char;
begin
  Premier := Nom;
  P := Pos(SeparateurMulti, Premier);
  if P > 0 then Premier := Copy(Premier, 1, P - 1);
  P := Pos(SeparateurEnsemble, Premier);
  if P > 0 then Premier := Copy(Premier, 1, P - 1);
  LibelleEquipement(Trim(Premier), TypeEquip);
  case TypeEquip of
    'W': Result := 1;
    'P': Result := 2;
  else
    Result := 3;
  end;
end;

// Objets que le Rulebook donne deja a une classe : les cibles possibles d'un retrait ou d'un
// remplacement. Un ensemble A+B se propose en deux objets (comme la grille les montre).
procedure TWinLivres.CiblesEquipClasse(const CodeClasse: String; Codes: TStrings);
var
  Chap, Cl, Sous, It: TDOMNode;
  Parts: TStringList;
  J: Integer;
begin
  Codes.Clear;
  if (RulebookXML = nil) or (CodeClasse = '') then Exit;
  Chap := RulebookXML.DocumentElement.FindNode('DATA_CLASS_ITEM');
  if Chap = nil then Exit;
  Parts := TStringList.Create;
  Parts.StrictDelimiter := True;
  Parts.Delimiter := SeparateurEnsemble;
  try
    Cl := Chap.FirstChild;
    while Cl <> nil do
    begin
      if (Cl.NodeType = ELEMENT_NODE) and (Cl.NodeName = 'Class') and
         (TDOMElement(Cl).GetAttribute('name') = CodeClasse) then
      begin
        Sous := Cl.FirstChild;
        while Sous <> nil do
        begin
          if (Sous.NodeType = ELEMENT_NODE) and (Sous.NodeName = 'SUBCHAPTER_ITEM') then
          begin
            It := Sous.FirstChild;
            while It <> nil do
            begin
              if (It.NodeType = ELEMENT_NODE) and (It.NodeName = 'Item') then
              begin
                Parts.DelimitedText := TDOMElement(It).GetAttribute('name');
                for J := 0 to Parts.Count - 1 do
                  if (Trim(Parts[J]) <> '') and (Codes.IndexOf(Trim(Parts[J])) < 0) then
                    Codes.Add(Trim(Parts[J]));
              end;
              It := It.NextSibling;
            end;
          end;
          Sous := Sous.NextSibling;
        end;
      end;
      Cl := Cl.NextSibling;
    end;
  finally
    Parts.Free;
  end;
end;

procedure TWinLivres.EquipClasseChoisir(Genre: Integer; out Code: String);
begin
  SelectWinLivre := '';
  Code := ChoisirEquipementCatalogue(Genre);
end;

// Equipement de depart par classe : une ligne par objet. Classes proposees : les 8 du Rulebook.
procedure TWinLivres.AfficherEquipClasse;
var
  Classes: TStringList;
  I: Integer;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Classes := TStringList.Create;
  try
    for I := 0 to High(ClassesCarriere) do
      Classes.Add(ClassesCarriere[I]);
    PanelEquipClasse.Configurer(@LibelleClasseTirage, @LibelleLigneEquipement, @GenreEquipement, Classes,
      @CiblesEquipClasse);
  finally
    Classes.Free;
  end;
  PanelEquipClasse.Charger(ChapitreEquipClasse);
  PanelEquipClasse.LectureSeule := not EditionPermise;
  PanelEquipClasse.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelEquipClasse.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelEquipClasse.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelEquipClasse.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelEquipClasse.Visible := True;
  CodeDonneeSelectionnee := 'DATA_CLASS_ITEM';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.EquipClasseValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
begin
  if not PanelEquipClasse.Controler then Exit;
  Chap := ChapitreEquipClasse;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_CLASS_ITEM');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelEquipClasse.Ecrire(Chap);
  AfficherEquipClasse;
end;

procedure TWinLivres.EquipClasseAnnulerClick(Sender: TObject);
begin
  AfficherEquipClasse;
end;

// Le chapitre DATA_CAREER_SPECIE du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore.
function TWinLivres.ChapitreCarriereEspece: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_CAREER_SPECIE');
  if N <> nil then Result := TDOMElement(N);
end;

// Liens carriere <-> espece : l'espece est une race ou une ethnie, de ce livre ou d'un autre.
procedure TWinLivres.AfficherCarriereEspece;
var
  Metiers, Especes: TStringList;
  PM: StructureMetier;
  PR: StructureRace;
  PE: StructureEspece;
  Liste: TDOMNodeList;
  E: TDOMElement;
  I: Integer;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Metiers := TStringList.Create;
  Especes := TStringList.Create;
  try
    Metiers.Sorted := True;
    Metiers.Duplicates := dupIgnore;
    Especes.Sorted := True;
    Especes.Duplicates := dupIgnore;
    for PM in ListMetier do
      Metiers.Add(PM.CodeMetier);
    Liste := XMLDoc.GetElementsByTagName('Career');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Metiers.Add(E.GetAttribute('id'));
    end;
    for PR in ListRace do
      Especes.Add(PR.CodeRace);
    for PE in ListEspece do
      Especes.Add(PE.CodeEspece);
    Liste := XMLDoc.GetElementsByTagName('Specie');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Especes.Add(E.GetAttribute('id'));
    end;
    Liste := XMLDoc.GetElementsByTagName('Race');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Especes.Add(E.GetAttribute('id'));
    end;
    PanelCarriereEspece.Configurer(@LibelleColonneTirage, @LibelleMetierTirage, Especes, Metiers);
  finally
    Metiers.Free;
    Especes.Free;
  end;
  PanelCarriereEspece.Charger(ChapitreCarriereEspece);
  PanelCarriereEspece.LectureSeule := not EditionPermise;
  PanelCarriereEspece.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelCarriereEspece.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelCarriereEspece.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelCarriereEspece.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelCarriereEspece.Visible := True;
  CodeDonneeSelectionnee := 'DATA_CAREER_SPECIE';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.CarriereEspeceValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
begin
  if not PanelCarriereEspece.Controler then Exit;
  Chap := ChapitreCarriereEspece;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_CAREER_SPECIE');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelCarriereEspece.Ecrire(Chap);
  AfficherCarriereEspece;
end;

procedure TWinLivres.CarriereEspeceAnnulerClick(Sender: TObject);
begin
  AfficherCarriereEspece;
end;

// Le chapitre DATA_RULE_SPECIE du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore.
function TWinLivres.ChapitreRegleEthnie: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_RULE_SPECIE');
  if N <> nil then Result := TDOMElement(N);
end;

// Libelle d'une competence : celui du livre ouvert, sinon celui des listes du jeu.
function TWinLivres.LibelleCompetenceTirage(Code: String): String;
var
  E: TDOMElement;
  PC: StructureCompetence;
begin
  Result := '';
  E := TrouverElementParId('Skill', Code);
  if E <> nil then Result := ValeurXML(E.FindNode('Description'));
  if Result = '' then
  begin
    PC := ChercheCompetence(Code);
    if PC.CodeCompetence = Code then Result := PC.Libelle;
  end;
  if Result = '' then Result := Code;
end;

// Regles par ethnie : regles, ethnies et races, competences et talents du jeu et du livre ouvert au choix.
procedure TWinLivres.AfficherRegleEthnie;
var
  Regles, Especes, Competences, Talents: TStringList;
  PRg: StructureRegle;
  PR: StructureRace;
  PE: StructureEspece;
  PC: StructureCompetence;
  PT: StructureTalent;
  Liste: TDOMNodeList;
  E: TDOMElement;

  procedure AjouteIds(Cible: TStrings; const Balise: String);
  var
    J: Integer;
  begin
    Liste := XMLDoc.GetElementsByTagName(Balise);
    for J := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[J]);
      if E.GetAttribute('id') <> '' then Cible.Add(E.GetAttribute('id'));
    end;
  end;

begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Regles := TStringList.Create;
  Especes := TStringList.Create;
  Competences := TStringList.Create;
  Talents := TStringList.Create;
  try
    Regles.Sorted := True;
    Regles.Duplicates := dupIgnore;
    Especes.Sorted := True;
    Especes.Duplicates := dupIgnore;
    Competences.Sorted := True;
    Competences.Duplicates := dupIgnore;
    Talents.Sorted := True;
    Talents.Duplicates := dupIgnore;
    for PRg in ListRegle do
      Regles.Add(PRg.CodeRegle);
    AjouteIds(Regles, 'Rule');
    for PR in ListRace do
      Especes.Add(PR.CodeRace);
    for PE in ListEspece do
      Especes.Add(PE.CodeEspece);
    AjouteIds(Especes, 'Specie');
    AjouteIds(Especes, 'Race');
    for PC in ListCompetence do
      Competences.Add(PC.CodeCompetence);
    AjouteIds(Competences, 'Skill');
    for PT in ListTalent do
      Talents.Add(PT.CodeTalent);
    AjouteIds(Talents, 'Talent');
    PanelRegleEthnie.Configurer(@LibelleRegleTirage, @LibelleColonneTirage, @LibelleCompetenceTirage,
      @LibelleTalentTirage, Regles, Especes, Competences, Talents);
  finally
    Regles.Free;
    Especes.Free;
    Competences.Free;
    Talents.Free;
  end;
  PanelRegleEthnie.Charger(ChapitreRegleEthnie);
  PanelRegleEthnie.LectureSeule := not EditionPermise;
  PanelRegleEthnie.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelRegleEthnie.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelRegleEthnie.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelRegleEthnie.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelRegleEthnie.Visible := True;
  CodeDonneeSelectionnee := 'DATA_RULE_SPECIE';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.RegleEthnieValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
begin
  if not PanelRegleEthnie.Controler then Exit;
  Chap := ChapitreRegleEthnie;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_RULE_SPECIE');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelRegleEthnie.Ecrire(Chap);
  AfficherRegleEthnie;
end;

procedure TWinLivres.RegleEthnieAnnulerClick(Sender: TObject);
begin
  AfficherRegleEthnie;
end;

// Le chapitre DATA_CAREER_SUBCHOICE du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore.
function TWinLivres.ChapitreSousMetier: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_CAREER_SUBCHOICE');
  if N <> nil then Result := TDOMElement(N);
end;

// Second jet apres le jet de metier : metiers du jeu et du livre ouvert, au choix dans chaque cellule.
procedure TWinLivres.AfficherSousMetier;
var
  Metiers: TStringList;
  PM: StructureMetier;
  Liste: TDOMNodeList;
  E: TDOMElement;
  I: Integer;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Metiers := TStringList.Create;
  try
    Metiers.Sorted := True;
    Metiers.Duplicates := dupIgnore;
    for PM in ListMetier do
      Metiers.Add(PM.CodeMetier);
    Liste := XMLDoc.GetElementsByTagName('Career');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Metiers.Add(E.GetAttribute('id'));
    end;
    PanelSousMetier.Configurer(@LibelleMetierTirage, Metiers);
  finally
    Metiers.Free;
  end;
  PanelSousMetier.Charger(ChapitreSousMetier);
  PanelSousMetier.LectureSeule := not EditionPermise;
  PanelSousMetier.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelSousMetier.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelSousMetier.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelSousMetier.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelSousMetier.Visible := True;
  CodeDonneeSelectionnee := 'DATA_CAREER_SUBCHOICE';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.SousMetierValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
begin
  if not PanelSousMetier.Controler then Exit;
  Chap := ChapitreSousMetier;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_CAREER_SUBCHOICE');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelSousMetier.Ecrire(Chap);
  AfficherSousMetier;
end;

procedure TWinLivres.SousMetierAnnulerClick(Sender: TObject);
begin
  AfficherSousMetier;
end;

// Le chapitre DATA_SPECIE_TRAIT du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore.
function TWinLivres.ChapitreTraitsEthnie: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_SPECIE_TRAIT');
  if N <> nil then Result := TDOMElement(N);
end;

// Vrai si une liste de talents (hors le bloc des traits lui-meme) cite ce trait : une ethnie le propose.
function TWinLivres.TraitEthnieCite(const Code: String): Boolean;
var
  Elems: TDOMNodeList;
  I: Integer;
  Liste: TStringList;
  El: TDOMElement;
begin
  Result := False;
  Liste := TStringList.Create;
  try
    Liste.Delimiter := ',';
    Liste.StrictDelimiter := True;
    Elems := XMLDoc.GetElementsByTagName('Talent');
    for I := 0 to Elems.Count - 1 do
    begin
      El := TDOMElement(Elems.Item[I]);
      if (El.ParentNode <> nil) and (El.ParentNode.NodeName = 'Option') then Continue;
      Liste.DelimitedText := StringReplace(ValeurXML(El), '/', ',', [rfReplaceAll]);
      if Liste.IndexOf(Code) >= 0 then Exit(True);
    end;
  finally
    Liste.Free;
  end;
end;

// Traits d'ethnie : une ligne par option, trois groupes de talents au plus.
procedure TWinLivres.AfficherTraitsEthnie;
var
  Livre: TDOMNode;
  Langue: String;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  PanelTraitEthnie.Configurer(ChoixTalentsSigne(''), ValeurXML(Livre.FindNode('CODE_BOOK')), Langue);
  PanelTraitEthnie.Charger(ChapitreTraitsEthnie);
  PanelTraitEthnie.LectureSeule := not EditionPermise;
  PanelTraitEthnie.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelTraitEthnie.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelTraitEthnie.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelTraitEthnie.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelTraitEthnie.Visible := True;
  CodeDonneeSelectionnee := 'DATA_SPECIE_TRAIT';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.TraitsEthnieValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
  Retires: TStringList;
  I: Integer;
begin
  if not PanelTraitEthnie.Controler then Exit;
  // un trait dont toutes les lignes ont disparu quitte le livre : refuse si une ethnie le propose encore
  Retires := TStringList.Create;
  try
    PanelTraitEthnie.TraitsRetires(Retires);
    for I := 0 to Retires.Count - 1 do
      if TraitEthnieCite(Retires.Names[I]) then
      begin
        ShowMessage(Format(GetTexteLibelle('RULES-LAB_551', 'The trait "%s" is still offered by an ethnicity: it cannot be removed.'),
          [Retires.ValueFromIndex[I]]));
        Exit;
      end;
  finally
    Retires.Free;
  end;
  Chap := ChapitreTraitsEthnie;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_SPECIE_TRAIT');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelTraitEthnie.Ecrire(Chap);
  AfficherTraitsEthnie;
end;

procedure TWinLivres.TraitsEthnieAnnulerClick(Sender: TObject);
begin
  AfficherTraitsEthnie;
end;

// Le chapitre DATA_CAREER_ROLL du livre ouvert (enfant direct de DATA_BOOK), nil s'il n'existe pas encore :
// ses <Entry> portent chacune une regle, une ethnie ou une race, et un metier avec sa chance.
function TWinLivres.ChapitreTirageMetier: TDOMElement;
var
  N: TDOMNode;
begin
  Result := nil;
  if XMLDoc = nil then Exit;
  N := XMLDoc.DocumentElement.FindNode('DATA_CAREER_ROLL');
  if N <> nil then Result := TDOMElement(N);
end;

function TWinLivres.LibelleMetierTirage(Code: String): String;
var
  El: TDOMElement;
  PM: StructureMetier;
begin
  Result := '';
  El := TrouverElementParId('Career', Code);
  if El <> nil then Result := ValeurXML(El.FindNode('Description'));
  if Result = '' then
  begin
    PM := ChercheMetier(Code);
    if PM.CodeMetier = Code then Result := PM.Libelle;
  end;
  if Result = '' then Result := Code;
end;

// Une colonne est une ethnie (<Specie id>) ou une race (<Race id>) ; une race porte le suffixe "(Race)".
function TWinLivres.LibelleColonneTirage(Code: String): String;
var
  El: TDOMElement;
  PR: StructureRace;
  PE: StructureEspece;
begin
  Result := '';
  El := TrouverElementParId('Specie', Code);
  if El <> nil then Result := ValeurXML(El.FindNode('Description'));
  if Result = '' then
  begin
    PR := ChercheRace(Code);
    if PR.CodeRace = Code then Result := PR.Libelle;
  end;
  if Result = '' then
  begin
    El := TrouverElementParId('Race', Code);
    if El <> nil then Result := ValeurXML(El.FindNode('Description'));
    if Result = '' then
    begin
      PE := ChercheEspece(Code);
      if PE.CodeEspece = Code then Result := PE.Libelle;
    end;
    if Result <> '' then Result := Result + ' (' + GetTexteLibelle('RULES-LAB_390') + ')';
  end;
  if Result = '' then Result := Code;
end;

function TWinLivres.LibelleRegleTirage(Code: String): String;
var
  El: TDOMElement;
  PR: StructureRegle;
begin
  Result := '';
  El := TrouverElementParId('Rule', Code);
  if El <> nil then Result := ValeurXML(El.FindNode('Description'));
  if Result = '' then
  begin
    PR := ChercheRegle(Code);
    if PR.CodeRegle = Code then Result := PR.Libelle;
  end;
  if Result = '' then Result := Code;
end;

function TWinLivres.LibelleClasseTirage(Code: String): String;
begin
  Result := GetTexteLibelle(Code);
end;

// Matrice du tirage des metiers : une table par regle du livre ouvert (metiers x ethnies ou races).
procedure TWinLivres.AfficherTirageMetier;
var
  Metiers, Colonnes, Regles, Classes: TStringList;
  PM: StructureMetier;
  PR: StructureRace;
  PE: StructureEspece;
  Liste: TDOMNodeList;
  E: TDOMElement;
  I: Integer;
begin
  LabelFormTitle.Caption := LibelleChapitre('DATA_CAREER_ROLL');
  Metiers := TStringList.Create;
  Colonnes := TStringList.Create;
  Regles := TStringList.Create;
  try
    Metiers.Sorted := True;
    Metiers.Duplicates := dupIgnore;
    Colonnes.Sorted := True;
    Colonnes.Duplicates := dupIgnore;
    Regles.Sorted := True;
    Regles.Duplicates := dupIgnore;
    for PM in ListMetier do
      Metiers.Add(PM.CodeMetier);
    Liste := XMLDoc.GetElementsByTagName('Career');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Metiers.Add(E.GetAttribute('id'));
    end;
    for PR in ListRace do
      Colonnes.Add(PR.CodeRace);
    for PE in ListEspece do
      Colonnes.Add(PE.CodeEspece);
    Liste := XMLDoc.GetElementsByTagName('Specie');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Colonnes.Add(E.GetAttribute('id'));
    end;
    Liste := XMLDoc.GetElementsByTagName('Race');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Colonnes.Add(E.GetAttribute('id'));
    end;
    // les regles declarees par le livre ouvert : <Rule id=...> (les <Rule> des entrees n'ont pas d'id)
    Liste := XMLDoc.GetElementsByTagName('Rule');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then Regles.Add(E.GetAttribute('id'));
    end;
    PanelTirageMetier.Configurer(@LibelleMetierTirage, @LibelleColonneTirage, @LibelleRegleTirage,
      Metiers, Colonnes, Regles);
    // classes proposees pour une regle partielle, puis la classe de chaque regle declaree par le livre
    Classes := TStringList.Create;
    try
      for I := 0 to High(ClassesCarriere) do
        Classes.Add(ClassesCarriere[I]);
      PanelTirageMetier.ConfigurerClasses(@LibelleClasseTirage, Classes,
        ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('CODE_BOOK')));
    finally
      Classes.Free;
    end;
    Liste := XMLDoc.GetElementsByTagName('Rule');
    for I := 0 to Liste.Count - 1 do
    begin
      E := TDOMElement(Liste.Item[I]);
      if E.GetAttribute('id') <> '' then
        PanelTirageMetier.DeclarerRegle(E.GetAttribute('id'), ValeurXML(E.FindNode('Class')));
    end;
  finally
    Metiers.Free;
    Colonnes.Free;
    Regles.Free;
  end;
  PanelTirageMetier.Charger(ChapitreTirageMetier);
  PanelTirageMetier.LectureSeule := not EditionPermise;
  PanelTirageMetier.Anchors := [akLeft, akTop, akRight, akBottom];
  PanelTirageMetier.SetBounds(StringGridDetail.Left, StringGridDetail.Top,
    PanelTirageMetier.Parent.ClientWidth - StringGridDetail.Left - 10,
    PanelTirageMetier.Parent.ClientHeight - StringGridDetail.Top - 10);
  PanelTirageMetier.Visible := True;
  CodeDonneeSelectionnee := 'DATA_CAREER_ROLL';
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.TirageMetierValiderClick(Sender: TObject);
var
  Chap: TDOMElement;
  ChapRegle: TDOMNode;
  Langue: String;
begin
  if not PanelTirageMetier.Controler then Exit;
  Chap := ChapitreTirageMetier;
  if Chap = nil then
  begin
    Chap := XMLDoc.CreateElement('DATA_CAREER_ROLL');
    XMLDoc.DocumentElement.AppendChild(Chap);
  end;
  PanelTirageMetier.Ecrire(Chap);
  // DATA_RULE : regles creees, supprimees ou dont la classe a change (avant DATA_CAREER_ROLL, comme a l'export)
  ChapRegle := XMLDoc.DocumentElement.FindNode('DATA_RULE');
  if (ChapRegle = nil) and PanelTirageMetier.ReglesACreer then
  begin
    ChapRegle := XMLDoc.CreateElement('DATA_RULE');
    XMLDoc.DocumentElement.InsertBefore(ChapRegle, Chap);
  end;
  if ChapRegle <> nil then
  begin
    Langue := ValeurXML(XMLDoc.DocumentElement.FindNode('language'));
    if Langue = '' then Langue := 'ENGLISH';
    PanelTirageMetier.EcrireRegles(TDOMElement(ChapRegle), Langue);
  end;
  AfficherDonneeChapitre('DATA_CAREER_ROLL');
end;

procedure TWinLivres.TirageMetierAnnulerClick(Sender: TObject);
begin
  AfficherDonneeChapitre('DATA_CAREER_ROLL');
end;

// Tout un chapitre de valeurs (coûts, tirages, sous-choix...) : une ligne par
// entrée, clé = identifiant ou nom si l'entrée en a un, sinon le nom de balise.
procedure TWinLivres.AfficherDonneeChapitre(Chapitre: String);
var
  Chap: TDOMNodeList;
  Enfant: TDOMNode;
  Cle, Valeur: String;
begin
  MasquerAfficherElements('DETAIL');
  MasquerForm();

  if XMLDoc = nil then Exit;
  // ces trois ecrans ont leur propre fiche ou panneau : la grille de detail (restee du noeud precedent) n'a rien a faire la
  if TableValeursEditable(Chapitre) then
  begin
    StringGridDetail.Visible := False;
    AfficherFicheTableValeurs(Chapitre);
    Exit;
  end;
  if Chapitre = 'DATA_RANDOM_TALENT' then
  begin
    StringGridDetail.Visible := False;
    AfficherTirageTalent;
    Exit;
  end;
  if Chapitre = 'DATA_CAREER_ROLL' then
  begin
    StringGridDetail.Visible := False;
    AfficherTirageMetier;
    Exit;
  end;
  Chap := XMLDoc.GetElementsByTagName(Chapitre);
  if Chap.Count = 0 then Exit;

  StringGridDetail.RowCount := 1;
  StringGridDetail.Columns[0].Title.Caption := GetTexteLibelle('RULES-LAB_002');
  StringGridDetail.Columns[1].Title.Caption := GetTexteLibelle('RULES-LAB_025');

  LabelFormTitle.Caption := LibelleChapitre(Chapitre);

  // Item[0] : pour DATA_RANDOM_TALENT, les entrées portent le même nom que le chapitre.
  Enfant := TDOMElement(Chap.Item[0]).FirstChild;
  while Enfant <> nil do
  begin
    if Enfant.NodeType = ELEMENT_NODE then
    begin
      Cle := TDOMElement(Enfant).GetAttribute('id');
      if Cle = '' then Cle := TDOMElement(Enfant).GetAttribute('name');
      if Cle = '' then Cle := Enfant.NodeName;

      Valeur := AplatirElement(TDOMElement(Enfant));
      if Valeur = '' then
        Valeur := TraduireCodesDansTexte(ValeurXML(Enfant));
      AjouterLigneDetail(Cle, Valeur, True);
    end;
    Enfant := Enfant.NextSibling;
  end;

  CodeDonneeSelectionnee := Chapitre;
  AdjustGridColumnsWidth(StringGridDetail, 0, False, False, True, 10, 10, ssAutoBoth);
  StringGridQualites.Visible := False;
end;

// ========== AFFICHER DONNÉE MALADIE ==========
// Fiche generique (contraction, incubation, duree, symptomes, grille des modificateurs), modifiable seulement
// si le livre l'autorise : un livre officiel la montre en lecture seule.
procedure TWinLivres.AfficherDonneeMaladie(Code: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Disease', Code);
  if Element = nil then Exit;
  AfficherFicheMaladie(Element);
  CodeDonneeSelectionnee := Code;
end;

// Fiche d'une maladie : seule la liste des champs lui est propre ; modifiable si le livre l'autorise.
procedure TWinLivres.AfficherFicheMaladie(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'Disease';
  FicheTypeNoeud := NT_MALADIE;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Contraction', 'RULES-LAB_282', gfTexte, True),
    ChampFiche('Incubation', 'RULES-LAB_283'),
    ChampFiche('Duration', 'RULES-LAB_284'),
    ChampFiche('Symptoms', 'RULES-LAB_285', gfMemo, True, False, True),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  RemplirCompLieeFiche('');  // cibles de competence de la grille (liste commune avec la fiche de talent)
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Fiche d'une affliction : editable si le livre l'autorise, sinon la meme fiche en lecture seule.
procedure TWinLivres.AfficherFicheAffliction(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'Affliction';
  FicheTypeNoeud := NT_AFFLICTION;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True),
    ChampFiche('ModifyHands', 'RULES-LAB_980', gfTexte, False, False, True, False),
    ChampFiche('ModifyHands@name', 'RULES-LAB_980', gfTexte, True, False, True, False)]);
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Fiche d'un signe astral (DATA_STARSIGN, Archives II p.39) : champs simples et multilingues, un talent et la grille
// des Modifier (PanelSigneEffets). Les sous-tirages (Variant) ne s'editent pas encore : la fiche les laisse tels quels.
procedure TWinLivres.AfficherFicheSigneAstral(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'StarSign';
  FicheTypeNoeud := NT_SIGNE_ASTRAL;
  PanelFiche.Definir([
    ChampFiche('Range', 'RULES-LAB_530', gfTexte, False, True, False, False),
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Title', 'RULES-LAB_046', gfTexte, True, True),
    ChampFiche('Classical', 'RULES-LAB_531', gfTexte, False, False, False, False),
    ChampFiche('Ascendant', 'RULES-LAB_532', gfTexte, False, False, False, False),
    ChampFiche('Dates', 'RULES-LAB_533', gfTexte, True, False, False, False),
    ChampFiche('God', 'RULES-LAB_534', gfTexte, False, False, False, False),
    ChampFiche('Appearance', 'RULES-LAB_535', gfTexte, True, False),
    ChampFiche('Personality', 'RULES-LAB_536', gfMemo, True, False),
    ChampFiche('Talent', 'RULES-LAB_007', gfCodeLibre, False, False, True, False, ChoixTalentsSigne(ValeurXML(Element.FindNode('Talent')))),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  PanelFiche.MasquerGrille;  // les effets du signe ne sont pas ceux de la grille des modificateurs
  PanelFiche.Extra := PanelSigneEffets;
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Cree un signe astral : le nom suffit, la fourchette et le reste se completent dans la fiche (Range est obligatoire).
// Code <LIVRE>-STARnn, cle dans l'attribut id ; les balises sont ecrites dans l'ordre du schema.
procedure TWinLivres.CreerSigneAstral;
var
  Code, Prefixe, Langue, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;

  procedure Ajouter(const Balise: String; Multilingue: Boolean; const Valeur: String);
  begin
    E := XMLDoc.CreateElement(Balise);
    if Multilingue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_318', 60);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_537', 'New star sign'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-STAR' + Format('%.2d', [N]);
    Inc(N);
  until TrouverElementParId('StarSign', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_STARSIGN').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_STARSIGN');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('StarSign');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Range', False, '');
  Ajouter('Description', True, Lib);
  Ajouter('Title', True, '');
  Ajouter('Classical', False, '');
  Ajouter('Ascendant', False, '');
  Ajouter('Dates', False, '');
  Ajouter('God', False, '');
  Ajouter('Appearance', True, '');
  Ajouter('Personality', True, '');

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_SIGNE_ASTRAL, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouveauSigneClick(Sender: TObject);
begin
  CreerSigneAstral;
end;

// Choix "code=libelle|..." pour une liste deroulante : tous les elements portant un id, des balises Tags, du livre ouvert
// et du Rulebook, tries par libelle ; un libelle en double est suivi de son code ; le code courant s'ajoute s'il manque.
function TWinLivres.ChoixParTags(const Tags: array of String; const Courant: String): String;
var
  Liste, Vus: TStringList;
  Doc: TXMLDocument;
  Elems: TDOMNodeList;
  I, N, T, P: Integer;
  Code, Lib, Prec: String;
begin
  Result := '';
  Liste := TStringList.Create;
  Vus := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupAccept;
    Vus.Sorted := True;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      for T := Low(Tags) to High(Tags) do
      begin
        Elems := Doc.GetElementsByTagName(Tags[T]);
        for I := 0 to Elems.Count - 1 do
        begin
          Code := TDOMElement(Elems.Item[I]).GetAttribute('id');
          if (Code = '') or (Vus.IndexOf(Code) >= 0) then Continue;
          Vus.Add(Code);
          Lib := ValeurXML(Elems.Item[I].FindNode('Description'));
          if Lib = '' then Lib := LibelleDeCode(Code);
          if Lib = '' then Lib := Code;
          Liste.Add(Lib + #9 + Code);
        end;
      end;
    end;
    if (Courant <> '') and (Vus.IndexOf(Courant) < 0) then
    begin
      Lib := LibelleDeCode(Courant);
      if Lib = '' then Lib := Courant;
      Liste.Add(Lib + #9 + Courant);
    end;
    Prec := '';
    for I := 0 to Liste.Count - 1 do
    begin
      P := Pos(#9, Liste[I]);
      Lib := Copy(Liste[I], 1, P - 1);
      Code := Copy(Liste[I], P + 1, MaxInt);
      if Lib = Prec then Lib := Lib + ' [' + Code + ']' else Prec := Lib;
      if Result <> '' then Result := Result + '|';
      Result := Result + Code + '=' + Lib;
    end;
  finally
    Vus.Free;
    Liste.Free;
  end;
end;

// Fiche d'un bonus de carriere (DATA_CAREER_BONUS, Nations of Mankind) : nom, carriere, ethnie ou nation, et la grille
// des quatre niveaux (PanelBonusCarriere). Les modificateurs des niveaux s'editent dans une fenetre a part ; SpecialRule ne s'edite pas.
procedure TWinLivres.AfficherFicheBonusCarriere(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'CareerBonus';
  FicheTypeNoeud := NT_BONUS_CARRIERE;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Career', 'RULES-LAB_006', gfCodeLibre, False, True, False, False, ChoixParTags(['Career'], ValeurXML(Element.FindNode('Career')))),
    ChampFiche('Specie', 'RULES-LAB_561', gfCodeLibre, False, False, True, False, ChoixParTags(['Specie', 'Race', 'Nation'], ValeurXML(Element.FindNode('Specie'))))]);
  PanelFiche.MasquerGrille;
  PanelBonusCarriere.Configurer(ChoixParTags(['Skill'], ''), ChoixTalentsSigne(''));
  PanelFiche.Extra := PanelBonusCarriere;
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Cree un bonus de carriere : le nom suffit, la carriere et le reste se completent dans la fiche (Career est obligatoire).
// Code <LIVRE>-BONUSnn, cle dans l'attribut id ; les quatre niveaux sont crees vides.
procedure TWinLivres.CreerBonusCarriere;
var
  Code, Prefixe, Langue, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E, Niv: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;

  procedure Ajouter(Parent: TDOMElement; const Balise: String; Multilingue: Boolean; const Valeur: String);
  begin
    E := XMLDoc.CreateElement(Balise);
    if Multilingue then E.SetAttribute('language', Langue);
    Parent.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_320', 62);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_558', 'New career bonus'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-BONUS' + Format('%.2d', [N]);
    Inc(N);
  until TrouverElementParId('CareerBonus', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_CAREER_BONUS').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_CAREER_BONUS');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('CareerBonus');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter(Elem, 'Description', True, Lib);
  Ajouter(Elem, 'Career', False, '');
  Ajouter(Elem, 'Specie', False, '');
  for N := 1 to 4 do
  begin
    Niv := XMLDoc.CreateElement('Level');
    Niv.SetAttribute('id', Code + '_' + IntToStr(N));
    Elem.AppendChild(Niv);
    Ajouter(Niv, 'Order', False, IntToStr(N));
    Ajouter(Niv, 'Skill', False, '');
    Ajouter(Niv, 'Talent', False, '');
  end;

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_BONUS_CARRIERE, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouveauBonusClick(Sender: TObject);
begin
  CreerBonusCarriere;
end;

// Fiche d'une adaptation de carriere (DATA_CAREER_ADAPTATION, Adapting Careers) : nom, carriere, ethnies (texte brut,
// facultative, Standing ; les ethnies et les substitutions sont dans PanelAdaptation.
procedure TWinLivres.AfficherFicheAdaptation(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'Adaptation';
  FicheTypeNoeud := NT_ADAPTATION_CARRIERE;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Career', 'RULES-LAB_006', gfCodeLibre, False, True, False, False, ChoixParTags(['Career'], ValeurXML(Element.FindNode('Career')))),
    ChampFiche('Optional', 'RULES-LAB_570', gfCode, False, False, True, False, '1=' + GetTexteLibelle('RULES-LAB_572', 'Yes')),
    ChampFiche('Standing', 'RULES-LAB_571', gfTexte, False, False, True, False, '', cfEntier)]);
  PanelFiche.MasquerGrille;
  PanelAdaptation.Configurer(ChoixParTags(['Skill'], ''), ChoixTalentsSigne(''),
    ChoixParTags(['Trapping', 'Weapon', 'Armor'], ''), ChoixParTags(['Specie', 'Race', 'Nation'], ''));
  PanelFiche.Extra := PanelAdaptation;
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Cree une adaptation : le nom suffit, la carriere, les ethnies et les substitutions se completent dans la fiche.
// Code <LIVRE>-ADAPTnnn, cle dans l'attribut id.
procedure TWinLivres.CreerAdaptation;
var
  Code, Prefixe, Langue, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;

  procedure Ajouter(const Balise: String; Multilingue: Boolean; const Valeur: String);
  begin
    E := XMLDoc.CreateElement(Balise);
    if Multilingue then E.SetAttribute('language', Langue);
    Elem.AppendChild(E);
    EcrireValeurXML(E, Valeur);
  end;

begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_321', 63);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_564', 'New career adaptation'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-ADAPT' + Format('%.3d', [N]);
    Inc(N);
  until TrouverElementParId('Adaptation', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_CAREER_ADAPTATION').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_CAREER_ADAPTATION');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Adaptation');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  Ajouter('Description', True, Lib);
  Ajouter('Career', False, '');
  Ajouter('Specie', False, '');

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_ADAPTATION_CARRIERE, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleAdaptationClick(Sender: TObject);
begin
  CreerAdaptation;
end;

// Fiche d'une mutation : comme l'affliction, editable si le livre l'autorise, sinon en lecture seule.
procedure TWinLivres.AfficherFicheMutation(Element: TDOMElement; TypeNoeud: Integer);
begin
  if Element = nil then Exit;
  FicheTag := 'Corruption';
  FicheTypeNoeud := TypeNoeud;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True),
    ChampFiche('Weapon', 'RULES-LAB_063', gfCodeLibre, False, False, True, False, ChoixParTags(['Weapon'], ValeurXML(Element.FindNode('Weapon')))),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// 42 (physique) ou 43 (mentale) si le noeud est sous l'une des deux branches de mutations, sinon 0.
function TWinLivres.TypeBrancheMutation(Node: TTreeNode): Integer;
const
  CodesLib: array[0..1] of String = ('RULES-LAB_330', 'RULES-LAB_331');
var
  I: Integer;
begin
  Result := 0;
  if Node = nil then Exit;
  while (Node.Level > 1) and (Node.Parent <> nil) do
    Node := Node.Parent;
  if (GetNodeType(Node) <> NT_CHAPITRE) or (Node.Level <> 1) then Exit;
  for I := 0 to 1 do
    if Node.Text = GetTexteLibelle('RULES-LAB_156') + ' (' + GetTexteLibelle(CodesLib[I]) + ')' then
      Result := 42 + I;
end;

// Cree une mutation dans la table physique ou mentale selon la branche : code <LIVRE>-CORPHY_NOM / CORMEN_NOM.
procedure TWinLivres.CreerMutation;
var
  Code, Prefixe, Langue, Lib, NomChap, Mot: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N, TypeFeuille: Integer;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  TypeFeuille := TypeBrancheMutation(TreeViewLivre.Selected);
  if TypeFeuille = 0 then Exit;
  Branche := TreeViewLivre.Selected;
  while (Branche.Level > 1) and (Branche.Parent <> nil) do
    Branche := Branche.Parent;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_480'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  if TypeFeuille = 42 then
  begin
    NomChap := 'DATA_CORRUPTION_TABLE_PHYSICAL';
    Mot := 'CORPHY_';
  end
  else
  begin
    NomChap := 'DATA_CORRUPTION_TABLE_MENTAL';
    Mot := 'CORMEN_';
  end;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  Code := Prefixe + '-' + Mot + NomEnMajuscules(Lib);
  while TrouverElementParId('Corruption', Code) <> nil do
  begin
    Inc(N);
    Code := Prefixe + '-' + Mot + NomEnMajuscules(Lib) + '_' + IntToStr(N);
  end;

  Chapitre := XMLDoc.GetElementsByTagName(NomChap).Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement(NomChap);
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Corruption');
  Elem.SetAttribute('name', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement('Description');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, Lib);
  E := XMLDoc.CreateElement('Explanation');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, '');

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, TypeFeuille, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleMutationClick(Sender: TObject);
begin
  CreerMutation;
end;

// Fiche d'une nation : la Description seule (la grille ne sert qu'a l'uniformite), lecture seule en livre officiel.
procedure TWinLivres.AfficherFicheNation(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'Nation';
  FicheTypeNoeud := NT_NATION;
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Fiche d'une option de regle : affichage seul, meme dans un livre de fan. Son Code de bascule
// (QUICKARMOUR...) est compare a du code Pascal : une option n'a d'effet que si le programme la connait,
// donc ni creation ni edition tant que les options ne sont pas des donnees.
procedure TWinLivres.AfficherFicheOption(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'OptionRule';
  FicheTypeNoeud := NT_OPTION_REGLE;
  PanelFiche.Definir([
    ChampFiche('Code', 'RULES-LAB_001', gfTexte, False, False, True, False),
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := True;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
end;

// Fiche d'une fabrication (Crafting) : Description, Short, Max, Applies, Explanation + grille des effets.
// Applies = cases a cocher (virgules, comme le lit winfabrication.pas), obligatoire : les trois cochees = tous les objets.
// Balise absente (generiques du Rulebook) = tous : affichee avec les trois cases cochees.
// <Modifier> (BONUS, PRACTICAL, UNRELIABLE, BULKY) est lie a du code Pascal : non affiche, conserve tel quel.
procedure TWinLivres.AfficherFicheFabrication(Element: TDOMElement);
var
  Applique: String;
begin
  if Element = nil then Exit;
  FicheTag := 'Craftsmanship';
  FicheTypeNoeud := NT_FABRICATION;
  Applique := 'Weapon=' + GetTexteLibelle('RULES-LAB_063') + '|Armour=' + GetTexteLibelle('RULES-LAB_065') +
    '|Misc=' + GetTexteLibelle('RULES-LAB_064');
  RemplirQualitesArme('WEAPB');  // WeaponQuality : qualites d'arme ajoutees, en panneau a libelles
  PanelFiche.Definir([
    ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Short', 'RULES-LAB_073', gfTexte, True, False, True),
    ChampFiche('Max', 'RULES-LAB_044', gfTexte, False, False, True, False, '', cfEntier),
    ChampFiche('Applies', 'RULES-LAB_333', gfCases, False, True, False, False, Applique),
    ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True),
    ChampFiche('Talent', 'RULES-LAB_007', gfTexte, False, False, True, False),
    ChampFiche('Talent#2', 'RULES-LAB_007', gfTexte, False, False, True, False),
    ChampFiche('Talent#3', 'RULES-LAB_007', gfTexte, False, False, True, False),
    ChampFiche('RangeBonus', 'RULES-LAB_057', gfTexte, False, False, True, False, '', cfEntier),
    ChampFiche('WeaponQuality', 'RULES-LAB_292', gfQualites, False, False, True, False),
    ChampFiche('AlternateWeapon', 'RULES-LAB_339', gfTexte, False, False, True, False),
    ChampFiche('Encumbrance', 'RULES-LAB_055', gfTexte, False, False, True, False, '', cfEntier),
    // regle propre au programme : le mot-cle de <Modifier> declenche un calcul ecrit en Pascal (chargefabrication.pas)
    ChampFiche('Modifier', 'RULES-LAB_034', gfCode, False, False, True, False, '=-' +
      '|BONUS=' + GetTexteLibelle('RULES-CRAFTMOD_BONUS', 'BONUS') +
      '|PRACTICAL=' + GetTexteLibelle('RULES-CRAFTMOD_PRACTICAL', 'PRACTICAL') +
      '|UNRELIABLE=' + GetTexteLibelle('RULES-CRAFTMOD_UNRELIABLE', 'UNRELIABLE') +
      '|BULKY=' + GetTexteLibelle('RULES-CRAFTMOD_BULKY', 'BULKY')),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  // ordre du schema (CraftsmanshipType) : Explanation et Short avant les balises libres, Page en dernier
  PanelFiche.OrdreBalises := 'Description,*Explanation,Short,*Applies,*Max,*Talent,*RangeBonus,*WeaponQuality,*AlternateWeapon,*Encumbrance,*Modifier,*Page';
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  // balise absente = fabrication generique (tous les objets) : on la montre explicitement
  if ValeurXML(Element.FindNode('Applies')) = '' then PanelFiche.CocherTout('Applies');
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

function TWinLivres.NoeudFabrications(Node: TTreeNode): TTreeNode;
begin
  Result := nil;
  if Node = nil then Exit;
  if (GetNodeType(Node) = NT_FABRICATION) and (Node.Parent <> nil) then
    Node := Node.Parent;
  if (GetNodeType(Node) = NT_CHAPITRE) and (Node.Text = GetTexteLibelle('RULES-LAB_125')) then
    Result := Node;
end;

// Cree une fabrication : le nom suffit (Max a 1), le reste et les effets se saisissent sur la fiche.
// Code <LIVRE>-QUALITY_NNN, cle dans l'attribut id.
procedure TWinLivres.CreerFabrication;
var
  Code, Prefixe, Langue, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudFabrications(TreeViewLivre.Selected);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_482'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-QUALITY_' + Format('%.3d', [N]);
    Inc(N);
  until TrouverElementParId('Craftsmanship', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_CRAFTMANSHIP').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_CRAFTMANSHIP');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Craftsmanship');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement('Description');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, Lib);
  E := XMLDoc.CreateElement('Explanation');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, '');
  E := XMLDoc.CreateElement('Max');
  Elem.AppendChild(E);
  EcrireValeurXML(E, '1');
  E := XMLDoc.CreateElement('Applies');
  Elem.AppendChild(E);
  EcrireValeurXML(E, 'Weapon,Armour,Misc');  // tout, explicite

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_FABRICATION, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleFabricationClick(Sender: TObject);
begin
  CreerFabrication;
end;

// Cree une nation : le nom suffit. Code <LIVRE>-NATION_NNN, cle dans l'attribut id.
procedure TWinLivres.CreerNation;
var
  Code, Prefixe, Langue, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_332', 40);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_481'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-NATION_' + Format('%.3d', [N]);
    Inc(N);
  until TrouverElementParId('Nation', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_NATION').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_NATION');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Nation');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement('Description');
  E.SetAttribute('language', Langue);
  Elem.AppendChild(E);
  EcrireValeurXML(E, Lib);

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_NATION, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleNationClick(Sender: TObject);
begin
  CreerNation;
end;

// ========== CONDITIONS (if=) D'UN LIVRE ==========
// Une condition = <Condition id><Kind> dans DATA_CONDITION, son libelle dans le DATA_LABEL du livre (CONTEXT.md 2.105).

// Ecrit (ou cree) le libelle d'un code dans le DATA_LABEL du livre ouvert, pour la langue du livre.
procedure TWinLivres.EcrireLibelleLivre(const Code, Texte: String);
var
  Livre, Bloc, Noeud: TDOMNode;
  Etiquette, Ligne: TDOMElement;
  Langue: String;
  Textes: TDOMNodeList;
  I: Integer;
begin
  if XMLDoc = nil then Exit;
  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Langue := ValeurXML(Livre.FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  Bloc := XMLDoc.GetElementsByTagName('DATA_LABEL').Item[0];
  if Bloc = nil then
  begin
    Bloc := XMLDoc.CreateElement('DATA_LABEL');
    Livre.AppendChild(Bloc);
  end;
  Etiquette := nil;
  Noeud := Bloc.FirstChild;
  while Noeud <> nil do
  begin
    if (Noeud.NodeName = 'Label') and (TDOMElement(Noeud).GetAttribute('language') = Langue) then
    begin
      Etiquette := TDOMElement(Noeud);
      Break;
    end;
    Noeud := Noeud.NextSibling;
  end;
  if Etiquette = nil then
  begin
    Etiquette := XMLDoc.CreateElement('Label');
    Etiquette.SetAttribute('language', Langue);
    Bloc.AppendChild(Etiquette);
  end;
  Textes := Etiquette.GetElementsByTagName('Text');
  for I := 0 to Textes.Count - 1 do
    if TDOMElement(Textes.Item[I]).GetAttribute('name') = Code then
    begin
      EcrireValeurXML(TDOMElement(Textes.Item[I]), Texte);
      Exit;
    end;
  Ligne := XMLDoc.CreateElement('Text');
  Ligne.SetAttribute('name', Code);
  Etiquette.AppendChild(Ligne);
  EcrireValeurXML(Ligne, Texte);
end;

// Retire le libelle d'un code du DATA_LABEL du livre ouvert (toutes langues).
procedure TWinLivres.SupprimerLibelleLivre(const Code: String);
var
  Bloc, Etiquette: TDOMNode;
  Textes: TDOMNodeList;
  I: Integer;
begin
  if XMLDoc = nil then Exit;
  Bloc := XMLDoc.GetElementsByTagName('DATA_LABEL').Item[0];
  if Bloc = nil then Exit;
  Etiquette := Bloc.FirstChild;
  while Etiquette <> nil do
  begin
    if Etiquette.NodeName = 'Label' then
    begin
      Textes := TDOMElement(Etiquette).GetElementsByTagName('Text');
      for I := Textes.Count - 1 downto 0 do
        if TDOMElement(Textes.Item[I]).GetAttribute('name') = Code then
          Textes.Item[I].ParentNode.RemoveChild(Textes.Item[I]);
    end;
    Etiquette := Etiquette.NextSibling;
  end;
end;

// <Text> d'un libelle du livre ouvert, par son code LANGUE|nom (nil si absent).
function TWinLivres.TrouverTexteLibelle(const Code: String): TDOMElement;
var
  Langue, Nom: String;
  Bloc, Etiquette, Texte: TDOMNode;
begin
  Result := nil;
  if (XMLDoc = nil) or (Pos('|', Code) = 0) then Exit;
  Langue := ExtractStringBefore(Code, '|');
  Nom := ExtractStringAfter(Code, '|');
  Bloc := XMLDoc.GetElementsByTagName('DATA_LABEL').Item[0];
  if Bloc = nil then Exit;
  Etiquette := Bloc.FirstChild;
  while Etiquette <> nil do
  begin
    if (Etiquette.NodeName = 'Label') and (TDOMElement(Etiquette).GetAttribute('language') = Langue) then
    begin
      Texte := Etiquette.FirstChild;
      while Texte <> nil do
      begin
        if (Texte.NodeName = 'Text') and (TDOMElement(Texte).GetAttribute('name') = Nom) then
        begin
          Result := TDOMElement(Texte);
          Exit;
        end;
        Texte := Texte.NextSibling;
      end;
    end;
    Etiquette := Etiquette.NextSibling;
  end;
end;

// Fiche d'un libelle du livre : code (affichage seul) et texte, tous deux ranges a la main (champs virtuels).
procedure TWinLivres.AfficherDonneeLibelle(Code: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverTexteLibelle(Code);
  if Element = nil then Exit;
  FicheTag := 'Libelle';
  FicheTypeNoeud := NT_LIBELLE_LIVRE;
  PanelFiche.Definir([
    ChampFiche('Code', 'RULES-LAB_001', gfTexte, False, False, True, False),
    ChampFiche('Libelle', 'RULES-LAB_002', gfTexte, True, True, False, False)]);
  PanelFiche.DeclarerVirtuel('Code');
  PanelFiche.DeclarerVirtuel('Libelle');
  PanelFiche.DeclarerAffichageSeul('Code');
  PanelFiche.MasquerGrille;
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.SetValeurChamp('Code', Element.GetAttribute('name'));
  PanelFiche.SetValeurChamp('Libelle', ValeurXML(Element));
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
  CodeDonneeSelectionnee := Code;
end;

// Fiche d'une condition : libelle (range dans le DATA_LABEL, champ virtuel) et nature (Kind).
procedure TWinLivres.AfficherFicheCondition(Element: TDOMElement);
begin
  if Element = nil then Exit;
  FicheTag := 'Condition';
  FicheTypeNoeud := NT_CONDITION;
  PanelFiche.Definir([
    ChampFiche('Libelle', 'RULES-LAB_002', gfTexte, True, True),
    ChampFiche('Kind', 'RULES-LAB_493', gfCode, False, True, False, False,
      'Information=' + GetTexteLibelle('RULES-LAB_490') + '|Optional=' + GetTexteLibelle('RULES-LAB_491') +
      '|Conditional=' + GetTexteLibelle('RULES-LAB_492')),
    ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
  PanelFiche.DeclarerVirtuel('Libelle');
  PanelFiche.MasquerGrille;  // une condition ne porte aucun modificateur
  RemplirCompLieeFiche('');
  PanelFiche.Charger(Element);
  PanelFiche.SetValeurChamp('Libelle', GetAttributLabel(Element.GetAttribute('id')));
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Fiche d'une competence ou d'un talent WFRP2 : texte du livre, consultation seule.
procedure TWinLivres.AfficherDonneeV2(Code, NomTag: String);
const
  // balise de l'article d'equipement et libelle ; seuls les champs presents sont affiches
  ChampsEquipement: array[0..35, 0..1] of String = (
    ('Category', 'RULES-LAB_711'), ('SubCategory', 'RULES-LAB_712'), ('Cost', 'RULES-LAB_015'),
    ('CostWeek', 'RULES-LAB_713'), ('Share', 'RULES-LAB_714'), ('Encumbrance', 'RULES-LAB_715'),
    ('Group', 'RULES-LAB_716'), ('Damage', 'RULES-LAB_717'), ('Range', 'RULES-LAB_718'),
    ('Reload', 'RULES-LAB_719'), ('Qualities', 'RULES-LAB_720'), ('Locations', 'RULES-LAB_721'),
    ('ArmourPoints', 'RULES-LAB_722'), ('Availability', 'RULES-LAB_723'), ('Note', 'RULES-LAB_724'),
    ('LagTime', 'RULES-LAB_764'), ('Volatility', 'RULES-LAB_765'), ('IngredientCost', 'RULES-LAB_766'),
    ('IngredientLocale', 'RULES-LAB_767'), ('IngredientDifficulty', 'RULES-LAB_768'),
    ('CreationDifficulty', 'RULES-LAB_769'), ('CreationTime', 'RULES-LAB_770'),
    ('AcademicKnowledge', 'RULES-LAB_771'), ('Powers', 'RULES-LAB_772'), ('SideEffects', 'RULES-LAB_784'), ('History', 'RULES-LAB_773'),
    ('RuneType', 'RULES-LAB_775'), ('InscriptionNumber', 'RULES-LAB_776'), ('Empowerment', 'RULES-LAB_777'),
    ('PermanentEffect', 'RULES-LAB_778'), ('TemporaryEffect', 'RULES-LAB_779'),
    ('CombatModifiers', 'RULES-LAB_895'), ('Profile', 'RULES-LAB_250'), ('Skills', 'RULES-LAB_009'),
    ('Talents', 'RULES-LAB_007'), ('SpecialRules', 'RULES-ANIMV2_SPECIAL'));
var
  Element: TDOMElement;
  Champs: array of StructureChampFiche;
  K, N: Integer;
  Dispo, Courant: String;
  Mots, Morceaux: TStringList;
begin
  MasquerAfficherElements('');
  MasquerForm();
  // la competence WFRP1 porte la balise <Skill> (NomTag 'SkillV1' sert seulement a la reconnaitre)
  if NomTag = 'SkillV1' then
    Element := TrouverElementParId('Skill', Code)
  else
    Element := TrouverElementParId(NomTag, Code);
  if Element = nil then Exit;
  if NomTag = 'SkillV1' then FicheTag := 'Skill' else FicheTag := NomTag;
  if NomTag = 'SkillV1' then
    begin
      FicheTypeNoeud := NT_COMPETENCE_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Generique', 'RULES-LAB_146', gfTexte, True, False, True, False),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True),
        ChampFiche('Variants', 'RULES-LAB_913', gfTexte, True, False, True, False),
        ChampFiche('Cumulative', 'RULES-LAB_914', gfTexte, True, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
      PanelFiche.OrdreBalises := 'Description,Explanation,Bonus,*Cumulative,*Variants,*Page';
    end
  else if NomTag = 'SkillV2' then
    begin
      FicheTypeNoeud := NT_COMPETENCE_V2;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('SkillType', 'RULES-LAB_706', gfTexte, True, False, True, False),
        ChampFiche('Characteristic', 'RULES-LAB_705', gfTexte, True, False, True, False),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True),
        ChampFiche('RelatedTalents', 'RULES-LAB_707', gfMemo, True, False, True, False)]);
    end
  else if (NomTag = 'EquipmentV2') or (NomTag = 'EquipmentV1') then
    begin
      if NomTag = 'EquipmentV1' then FicheTypeNoeud := NT_EQUIPEMENT_V1 else FicheTypeNoeud := NT_EQUIPEMENT_V2;
      SetLength(Champs, 4 + Length(ChampsEquipement));
      Champs[0] := ChampFiche('Description', 'RULES-LAB_002', gfTexte, True);
      N := 1;
      // libelle francais d'un objet V1 (2e <Description language="FRENCH">) : champ propre, sa langue en attribut
      if (NomTag = 'EquipmentV1') and (NoeudDeBalise(Element, 'Description#2') <> nil) then
      begin
        Champs[N] := ChampFiche('Description#2', 'Description (2)', gfTexte, True, False, False, False);
        Inc(N);
        Champs[N] := ChampFiche('Description#2@language', 'Description (2) language', gfTexte, True, False, False, False);
        Inc(N);
      end;
      for K := 0 to High(ChampsEquipement) do
        // V1 : tous les champs du schema sont proposes (balise creee seulement si remplie) ; V2 : ceux deja presents
        if ((Element.FindNode(ChampsEquipement[K, 0]) <> nil) and
            not ((NomTag = 'EquipmentV2') and (ChampsEquipement[K, 0] = 'Qualities')) and  // Qualities : tableau (PanelQualitesV2)
            not ((NomTag = 'EquipmentV1') and ((ChampsEquipement[K, 0] = 'CombatModifiers') or (ChampsEquipement[K, 0] = 'Range')))) or  // CombatModifiers et Range : tableaux (PanelLignesObjetV1)
           ((NomTag = 'EquipmentV1') and (Pos(',' + ChampsEquipement[K, 0] + ',',
             ',SubCategory,Cost,Encumbrance,Availability,Reload,ArmourPoints,Locations,Note,') > 0)) then
        begin
          if (NomTag = 'EquipmentV1') and (ChampsEquipement[K, 0] = 'Category') then
            Champs[N] := ChampFiche('Category', ChampsEquipement[K, 1], gfCodeLibre, True, False, True, False,
              ChoixMotsV1('V1CAT_', ['WEAPON', 'MISC', 'TRANSPORT', 'ARMOUR', 'CLOTHING', 'HIRELING', 'SUBSISTENCE', 'DWELLING', 'MEDICAL'], True))
          else if (NomTag = 'EquipmentV1') and (ChampsEquipement[K, 0] = 'SubCategory') then
            Champs[N] := ChampFiche('SubCategory', ChampsEquipement[K, 1], gfCodeLibre, True, False, True, False,
              ChoixMotsV1('V1SUBCAT_', ['MELEE', 'MISSILE', 'TOOLS', 'FIREARM', 'HOUSEHOLD', 'MUSIC', 'CARRYING', 'LIVESTOCK',
                'ILLUMINATION', 'SKILLED', 'VEHICLE', 'TRAVEL', 'POTION', 'UNSKILLED', 'CHARM', 'READING', 'RIDING', 'POISON'], True))
          else if (NomTag = 'EquipmentV1') and (ChampsEquipement[K, 0] = 'Locations') then
            // zones couvertes : cases a cocher, valeurs ecrites « Body/Arms » (separees par une barre oblique)
            Champs[N] := ChampFiche('Locations', ChampsEquipement[K, 1], gfCases, True, False, True, False,
              ChoixMotsV1('V1LOC_', ['Head', 'Body', 'Arms', 'Legs', 'All'], True))
          else if (NomTag = 'EquipmentV1') and (ChampsEquipement[K, 0] = 'Availability') then
            Champs[N] := ChampFiche('Availability', ChampsEquipement[K, 1], gfCodeLibre, True, False, True, False,
              ChoixMotsV1('DISPO2_', ['Plentiful', 'Common', 'Average', 'Scarce', 'Rare', 'Very Rare', 'Almost Unknown'], True))
          else if (NomTag = 'EquipmentV2') and (ChampsEquipement[K, 0] = 'Availability') then
          begin
            // mots du livre (Common...), parfois ecrits en code (RULES-DISPO2_SCARCE) ou « - » : la valeur d'origine reste proposee
            Dispo := ChoixMotsV1('DISPO2_', ['Abundant', 'Plentiful', 'Common', 'Average', 'Scarce', 'Rare', 'Very Rare', 'Extremely Rare'], True) + '|-=-';
            Courant := ValeurXML(Element.FindNode('Availability'));
            if (Pos('RULES-DISPO2_', Courant) = 1) and (Length(Courant) > Length('RULES-DISPO2_'))
               and (Pos('|' + Courant + '=', '|' + Dispo) = 0) then
              Dispo := Dispo + '|' + Courant + '=' + GetTexteLibelle(Courant);
            Champs[N] := ChampFiche('Availability', ChampsEquipement[K, 1], gfCodeLibre, True, False, True, False, Dispo);
          end
          else if (NomTag = 'EquipmentV2') and (ChampsEquipement[K, 0] = 'Locations') then
            // zones V2 : cases a cocher, valeurs separees par « , » (« Body, Left Front Leg, and Right Front Leg » rendue telle quelle si inchangee)
            Champs[N] := ChampFiche('Locations', ChampsEquipement[K, 1], gfCases, True, False, True, False,
              ChoixMotsV1('V1LOC_', ['Head', 'Body', 'Arms', 'Legs', 'Left Front Leg', 'Right Front Leg', 'All'], True))
          else if (NomTag = 'EquipmentV2') and (ChoixParBaliseV2(ChampsEquipement[K, 0]) <> '') then
            Champs[N] := ChampFiche(ChampsEquipement[K, 0], ChampsEquipement[K, 1], gfCodeLibre, True, False, True, False,
              ChoixParBaliseV2(ChampsEquipement[K, 0]))
          else
            Champs[N] := ChampFiche(ChampsEquipement[K, 0], ChampsEquipement[K, 1], gfTexte, True, False, True, False);
          Inc(N);
        end;
      if (NomTag = 'EquipmentV1') or (Element.FindNode('Page') <> nil) then
        begin
          Champs[N] := ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False);
          Inc(N);
        end;
      SetLength(Champs, N);
      PanelFiche.Definir(Champs);
      if NomTag = 'EquipmentV1' then PanelFiche.DeclarerSeparateurCases('Locations', '/')
      else PanelFiche.DeclarerSeparateurCases('Locations', ', ');
      if NomTag = 'EquipmentV1' then
        PanelFiche.OrdreBalises := 'Description,Category,*SubCategory,*Cost,*Encumbrance,*Availability,*CombatModifiers,*RangeBands,*Reload,*ArmourPoints,*Locations,*Note,*Page'
      else
        // ordre de SCHEMA_WFRP2.xsd (EquipmentV2Type)
        PanelFiche.OrdreBalises := 'Description,Category,*SubCategory,*Cost,*CostWeek,*Share,*Encumbrance,*Group,*Damage,*Range,*Reload,*Qualities,*Locations,*ArmourPoints,*Availability,*Profile,*Skills,*Talents,*SpecialRules,*Note,*Page,*LagTime,*Volatility,*IngredientCost,*IngredientLocale,*IngredientDifficulty,*CreationDifficulty,*CreationTime,*AcademicKnowledge,*Powers,*SideEffects,*History,*RuneType,*InscriptionNumber,*Empowerment,*PermanentEffect,*TemporaryEffect';
      // la categorie est celle de la branche ou l'objet a ete cree : elle ne se modifie pas ici
      PanelFiche.DeclarerAffichageSeul('Category');
    end
  else if NomTag = 'SpellV2' then
    begin
      FicheTypeNoeud := NT_SORT_V2;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        // Lore, CastingNumber, CastingTime, Ingredient : obligatoires au schema (SpellV2Type), ecrits meme vides
        ChampFiche('Lore', 'RULES-LAB_708', gfTexte, True, False, False, False),
        ChampFiche('CastingNumber', 'RULES-LAB_335', gfTexte, True, False, False, False),
        ChampFiche('CastingTime', 'RULES-LAB_709', gfTexte, True, False, False, False),
        ChampFiche('Ingredient', 'RULES-LAB_710', gfTexte, True, False, False, False),
        ChampFiche('Range', 'RULES-LAB_718', gfTexte, True, False, True, False),
        ChampFiche('Duration', 'RULES-LAB_284', gfTexte, True, False, True, False),
        ChampFiche('Cult', 'RULES-LAB_781', gfTexte, True, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False),
        ChampFiche('SpellLists', 'RULES-LAB_757', gfTexte, True, False, True, False),
        ChampFiche('RitualType', 'RULES-LAB_758', gfCodeLibre, True, False, True, False, ChoixParBaliseV2('RitualType')),
        ChampFiche('ArcaneLanguage', 'RULES-LAB_759', gfTexte, True, False, True, False),
        ChampFiche('MagicMin', 'RULES-LAB_760', gfTexte, True, False, True, False),
        ChampFiche('XPCost', 'RULES-LAB_761', gfTexte, True, False, True, False),
        ChampFiche('Conditions', 'RULES-LAB_762', gfMemo, True, False, True, False),
        ChampFiche('Consequences', 'RULES-LAB_763', gfMemo, True, False, True, False),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True),
        ChampFiche('Talent', 'RULES-LAB_007', gfTexte, True, False, True, False)]);
      // le talent d'acces n'est pas dans le sort : il est range dans DATA_SPELL_TALENT (EcrireTalentsTable)
      PanelFiche.DeclarerVirtuel('Talent');
      // ordre de SCHEMA_WFRP2.xsd (SpellV2Type) : une balise ajoutee se range a sa place
      PanelFiche.OrdreBalises := 'Description,Explanation,Lore,CastingNumber,CastingTime,Ingredient,*Page,*SpellLists,*Duration,*Range,*Cult,*RitualType,*ArcaneLanguage,*MagicMin,*XPCost,*Conditions,*Consequences';
    end
  else if NomTag = 'Deity' then
    begin
      FicheTypeNoeud := NT_DIEU_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Alignment', 'RULES-LAB_872', gfCodeLibre, True, False, True, False,
          ChoixMotsV1('V1ALIGN_', ['Neutral', 'Chaos', 'Law', 'Good', 'Evil'], True)),
        ChampFiche('Domain', 'RULES-LAB_873', gfTexte, True, False, True, False),
        ChampFiche('Strictures', 'RULES-LAB_874', gfMemo, True, False, True, False),
        ChampFiche('Trials', 'RULES-LAB_875', gfMemo, True, False, True, False),
        ChampFiche('Blessings', 'RULES-LAB_876', gfMemo, True, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
    end
  else if NomTag = 'Disability' then
    begin
      FicheTypeNoeud := NT_HANDICAP_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True),
        ChampFiche('InsanityPoints', 'RULES-LAB_916', gfTexte, True, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
    end
  else if NomTag = 'Attribut' then
    begin
      FicheTypeNoeud := NT_ATTRIBUT_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Short', 'RULES-LAB_925', gfTexte, True, False, True),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True),
        ChampFiche('Order', 'RULES-LAB_926', gfTexte, True, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
      PanelFiche.OrdreBalises := 'Description,Explanation,Short,*Order,*Page';
    end
  else if NomTag = 'Class' then
    begin
      FicheTypeNoeud := NT_CLASSE_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True),
        ChampFiche('Trappings', 'RULES-LAB_196', gfMemo, True, False, True, False),
        ChampFiche('Money', 'RULES-LAB_694', gfTexte, True, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
    end
  else if NomTag = 'Trade' then
    begin
      FicheTypeNoeud := NT_METIER_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Roll', 'RULES-LAB_877', gfTexte, True, False, True, False),
        ChampFiche('Note', 'RULES-LAB_910', gfTexte, True, False, True, False)]);
    end
  else if NomTag = 'Cult' then
    begin
      FicheTypeNoeud := NT_CULTE_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Deity', 'RULES-LAB_534', gfCodeLibre, True, False, True, False,
          ChoixDivinitesV1(ValeurXML(Element.FindNode('Deity')))),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
    end
  else if NomTag = 'Familiar' then
    begin
      FicheTypeNoeud := NT_FAMILIER_V1;
      PanelFiche.Definir([
        ChampFiche('Animal', 'RULES-LAB_252', gfTexte, True),
        ChampFiche('Range', 'RULES-LAB_877', gfTexte, True, False, True, False),
        ChampFiche('Skill1', 'RULES-FAMDIET_SKILLS', gfCodeLibre, False, False, True, False, ChoixCompetencesV1),
        ChampFiche('Skill2', 'RULES-FAMDIET_SKILLS', gfCodeLibre, False, False, True, False, ChoixCompetencesV1),
        ChampFiche('SkillNote', 'RULES-LAB_917', gfTexte, True, False, True, False),
        ChampFiche('Diet', 'RULES-FAMDIET_DIET', gfCodeLibre, False, False, True, False, ChoixRegimeV1),
        ChampFiche('Armour', 'RULES-EQCAT2_ARMOUR', gfCodeLibre, True, False, True, False,
          ChoixMotsV1('V1ARMOUR_', ['None', 'Leather', 'Any'], True)),
        ChampFiche('Shield', 'RULES-ARMOL_SHIELD', gfTexte, True, False, True, False),
        ChampFiche('ForbiddenWeapons', 'RULES-LAB_878', gfCases, True, False, True, False,
          ChoixMotsV1('V1WPN_', ['2-h', 'firearms', 'missile', 'blunt', 'sharp'])),
        ChampFiche('TimesPlaces', 'RULES-LAB_879', gfTexte, True, False, True, False)]);
      PanelFiche.OrdreBalises := 'Range,Animal,Skill1,Skill2,*SkillNote,Armour,Shield,*ForbiddenWeapons,TimesPlaces,Diet';
    end
  else if NomTag = 'SpellV1' then
    begin
      FicheTypeNoeud := NT_SORT_V1;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('SpellList', 'RULES-LAB_847', gfCodeLibre, True, False, True, False, ChoixValeursBalise('SpellList', ValeurXML(Element.FindNode('SpellList')))),
        ChampFiche('SpellLevel', 'RULES-LAB_848', gfCodeLibre, True, False, True, False,
          // P / Master / High = codes (traduisibles) ; chiffres 1 a 5 = valeur inchangee (non traduisibles)
          ChoixMotsV1('V1LEVEL_', ['P'], True) + '|1=1|2=2|3=3|4=4|5=5|' + ChoixMotsV1('V1LEVEL_', ['Master', 'High'], True)),
        ChampFiche('MagicPoints', 'RULES-LAB_867', gfTexte, True, False, True, False),
        ChampFiche('Range', 'RULES-LAB_718', gfTexte, True, False, True, False),
        ChampFiche('Duration', 'RULES-LAB_284', gfTexte, True, False, True, False),
        ChampFiche('Ingredients', 'RULES-LAB_868', gfTexte, True, False, True, False),
        ChampFiche('MagicTest', 'RULES-LAB_894', gfCodeLibre, True, False, True, False,
          ChoixMotsV1('V1YESNO_', ['oui', 'non'], True)),
        ChampFiche('AreaOfEffect', 'RULES-LAB_897', gfTexte, True, False, True, False),
        ChampFiche('Resistance', 'RULES-LAB_898', gfCodeLibre, True, False, True, False,
          ChoixMotsV1('V1RESIST_', ['None', 'WP'], True)),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True)]);
      PanelFiche.OrdreBalises := 'Description,Explanation,SpellList,SpellLevel,MagicPoints,Range,Duration,Ingredients,*AreaOfEffect,*Resistance,*MagicTest,*Page';
    end
  else
    begin
      FicheTypeNoeud := NT_TALENT_V2;
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True)]);
    end;
  PanelFiche.MasquerGrille;
  if FicheTypeNoeud = NT_COMPETENCE_V1 then PanelFiche.Extra := PanelBonusCompetenceV1
  else if FicheTypeNoeud = NT_CULTE_V1 then PanelFiche.Extra := PanelCulteV1
  else if FicheTypeNoeud = NT_DIEU_V1 then PanelFiche.Extra := PanelDieuV1
  else if FicheTypeNoeud = NT_CLASSE_V1 then PanelFiche.Extra := PanelClasseV1
  else if FicheTypeNoeud = NT_HANDICAP_V1 then PanelFiche.Extra := PanelHandicapV1
  else if FicheTypeNoeud = NT_METIER_V1 then PanelFiche.Extra := PanelMetierV1
  else if FicheTypeNoeud = NT_EQUIPEMENT_V1 then PanelFiche.Extra := PanelLignesObjetV1
  else if (FicheTypeNoeud = NT_EQUIPEMENT_V2) and (Element.FindNode('Qualities') <> nil) then
  begin
    // qualites de l'objet : noms definis dans DATA_WEAPON_BONUS (livre + Rulebook), plus les mots courants hors definition
    Mots := TStringList.Create;
    Morceaux := TStringList.Create;
    try
      Morceaux.Delimiter := '|';
      Morceaux.StrictDelimiter := True;
      Morceaux.DelimitedText := ChoixParTags(['BonusMalus'], '');
      for K := 0 to Morceaux.Count - 1 do
        if Pos('=', Morceaux[K]) > 0 then Mots.Add(Copy(Morceaux[K], Pos('=', Morceaux[K]) + 1, MaxInt));
      Mots.Add('None');
      Mots.Add('Special');
      PanelQualitesV2.DefinirChoix(Mots);
    finally
      Morceaux.Free;
      Mots.Free;
    end;
    PanelFiche.Extra := PanelQualitesV2;
  end;
  PanelFiche.Charger(Element);
  if FicheTypeNoeud = NT_SORT_V2 then PanelFiche.SetValeurChamp('Talent', TalentsDeTable(Element.GetAttribute('id')));
  PanelFiche.LectureSeule := not (FicheTypeNoeud in [NT_SORT_V2, NT_EQUIPEMENT_V2, NT_SORT_V1, NT_COMPETENCE_V1, NT_EQUIPEMENT_V1, NT_DIEU_V1, NT_CULTE_V1, NT_FAMILIER_V1, NT_CLASSE_V1, NT_METIER_V1, NT_HANDICAP_V1, NT_ATTRIBUT_V1]) or not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  CodeDonneeSelectionnee := Code;
end;

// ========== Tables WFRP1 a lignes sans id ==========
// Code d'une ligne : <balise du chapitre>|<rang de la ligne dans le chapitre>.
function TWinLivres.TrouverLigneTable(Code: String): TDOMElement;
var
  P, N, K: Integer;
  Courant, Fils: TDOMNode;
  Reste: String;
begin
  Result := nil;
  P := Pos('|', Code);
  if (XMLDoc = nil) or (P = 0) then Exit;
  Courant := XMLDoc.GetElementsByTagName(Copy(Code, 1, P - 1)).Item[0];
  Reste := Copy(Code, P + 1, MaxInt);
  // Reste = rangs successifs separes par "|" (chapitre -> ligne, ou chapitre -> <Table> -> ligne)
  while (Courant <> nil) and (Reste <> '') do
  begin
    P := Pos('|', Reste);
    if P = 0 then P := Length(Reste) + 1;
    N := StrToIntDef(Copy(Reste, 1, P - 1), -1);
    Reste := Copy(Reste, P + 1, MaxInt);
    K := 0;
    Fils := Courant.FirstChild;
    Courant := nil;
    while Fils <> nil do
    begin
      if Fils.NodeType = ELEMENT_NODE then
      begin
        if K = N then
        begin
          Courant := Fils;
          Break;
        end;
        Inc(K);
      end;
      Fils := Fils.NextSibling;
    end;
  end;
  if Courant <> nil then Result := TDOMElement(Courant);
end;

// Livre ouvert de l'edition WFRP1 : ses donnees suivent SCHEMA_WFRP1.xsd (chapitres *_V1), pas le format V4.
function TWinLivres.EstLivreV1: Boolean;
begin
  Result := (XMLDoc <> nil) and (XMLDoc.GetElementsByTagName('DATA_BOOK').Count > 0) and
    SameText(ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode(ConstXmlVersionLivre)), 'WFRP1');
end;

// Version du livre ouvert sous la forme 'V1', 'V2', 'V4', 'V5' (jeton des groupes d'affichage des fiches) ; '' si inconnue.
function TWinLivres.VersionFicheLivre: String;
var
  Brut: String;
begin
  Result := '';
  if (XMLDoc = nil) or (XMLDoc.GetElementsByTagName('DATA_BOOK').Count = 0) then Exit;
  Brut := UpperCase(ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode(ConstXmlVersionLivre)));
  if (Length(Brut) = 5) and (Copy(Brut, 1, 4) = 'WFRP') then Result := 'V' + Brut[5];
end;

function TWinLivres.EstLivreV2: Boolean;
begin
  Result := (XMLDoc <> nil) and (XMLDoc.GetElementsByTagName('DATA_BOOK').Count > 0) and
    SameText(ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode(ConstXmlVersionLivre)), 'WFRP2');
end;

// Une branche vide (livre de travail) n'est proposee que si son chapitre existe dans la version du livre ouvert
// (relevé des chapitres des livres de DATABASE, 09/11/2026 ; la V5 suit la V4). Chiffres = versions 1, 2, 4, 5.
// Un chapitre inconnu de la table reste propose ; un chapitre deja rempli est toujours montre (voir les appelants).
function TWinLivres.ChapitrePermisVersion(const NomChap: String): Boolean;
const
  Table: String =
    '|DATA_AFFLICTION=45|DATA_ARMOR=245|DATA_ARMOR_BONUS=45|DATA_ARMOR_SIMP=45|DATA_ATTRIBUT=1245|DATA_ATTRIBUT_COST=45' +
    '|DATA_CAREER=245|DATA_CAREER_ADAPTATION=45|DATA_CAREER_BONUS=245|DATA_CAREER_ROLL=1245|DATA_CAREER_SPECIE=45' +
    '|DATA_CAREER_SUBCHOICE=45|DATA_CLASS_ITEM=45|DATA_CONDITION=45|DATA_CORRUPTION_DIVINE_CHANCE=2|DATA_CORRUPTION_MENTAL=45' +
    '|DATA_CORRUPTION_MENTAL_CHANCE=45|DATA_CORRUPTION_MUTATION_CHANCE=2|DATA_CORRUPTION_PHYSICAL=45|DATA_CORRUPTION_PHYSICAL_CHANCE=45' +
    '|DATA_CORRUPTION_TABLE_DIVINE=2|DATA_CORRUPTION_TABLE_MENTAL=45|DATA_CORRUPTION_TABLE_MUTATION=2|DATA_CORRUPTION_TABLE_PHYSICAL=45' +
    '|DATA_CRAFTMANSHIP=45|DATA_DISEASE=45|DATA_LABEL=45|DATA_NATION=45|DATA_OPTION_RULE=45|DATA_PERSONAL_TABLE=2|DATA_RACE=1245' +
    '|DATA_RANDOM_SPECIE=45|DATA_RANDOM_TALENT=245|DATA_RULE=1245|DATA_RULE_BACKGROUND=2|DATA_RULE_BACKGROUND_COUNT=2' +
    '|DATA_RULE_SKILL_ROLL=2|DATA_RULE_SPECIE=2|DATA_RULE_TALENT_ROLL=2|DATA_SKILL=245|DATA_SKILL_COST=45' +
    '|DATA_SKILL_SPECIALIZATION=1245|DATA_SPECIE=1245|DATA_SPECIE_CAREER_CHOICE=45|DATA_SPECIE_TRAIT=45|DATA_SPELL=45' +
    '|DATA_SPELL_TALENT=245|DATA_STARSIGN=45|DATA_TALENT=245|DATA_TALENT_SPECIALIZATION=245|DATA_TRAPPING=45|DATA_WEAPON=245' +
    '|DATA_WEAPON_BONUS=245|';
var
  V: String;
  P: Integer;
begin
  Result := True;
  V := VersionFicheLivre;
  if V = '' then Exit;
  V := Copy(V, 2, 1);
  // chapitres propres a une edition : suffixe _V1 / _V2
  if Copy(NomChap, Length(NomChap) - 2, 3) = '_V1' then Exit(V = '1');
  if Copy(NomChap, Length(NomChap) - 2, 3) = '_V2' then Exit(V = '2');
  P := Pos('|' + NomChap + '=', Table);
  if P = 0 then Exit;
  // 4 caracteres au plus apres « = » : les chiffres puis le separateur « | » (aucun nom de chapitre ne contient de chiffre)
  Result := Pos(V, Copy(Table, P + Length(NomChap) + 2, 4)) > 0;
end;

// Chapitres que SCHEMA_WFRP1.xsd admet : les *_V1 et les blocs communs. Les autres (talents, armes, maladies...)
// ne sont pas proposes, meme vides, dans un livre de travail V1.
function TWinLivres.ChapitreV1Permis(const NomChap: String): Boolean;
begin
  Result := (Copy(NomChap, Length(NomChap) - 2, 3) = '_V1') or
    (Pos('|' + NomChap + '|', '|DATA_ATTRIBUT|DATA_SKILL_SPECIALIZATION|DATA_SPECIE|DATA_RACE|DATA_PERSONAL_TABLE|DATA_RULE|DATA_RULE_SPECIE|DATA_RULE_SKILL_ROLL|DATA_CAREER_ROLL|') > 0);
end;

// Libelle d'un code de carriere, d'espece / race ou de regle WFRP1 pris dans le livre ouvert (puis le Rulebook), '' si inconnu.
// Affichage seulement : le code reste ce qui est ecrit dans le XML.
function TWinLivres.LibelleCodeV1(const Code: String): String;
var
  I, K: Integer;
  Doc: TXMLDocument;
  Balise: String;
  Element: TDOMElement;
  Liste: TDOMNodeList;
begin
  Result := '';
  if Code = '' then Exit;
  if RacesDataList <> nil then
  begin
    I := RacesDataList.IndexOf(Code);
    if (I >= 0) and (RacesDataList.Data[I]^.Libelle <> '') then Exit(RacesDataList.Data[I]^.Libelle);
  end;
  for I := 0 to 2 do
  begin
    // 3e source : le Rulebook complet (RulebookXML est le fichier de langue quand la langue n'est pas l'anglais)
    case I of
      0: Doc := XMLDoc;
      1: Doc := RulebookXML;
    else Doc := RulebookBaseXML;
    end;
    if Doc = nil then Continue;
    for Balise in ['Career', 'Specie', 'Race', 'Rule', 'Attribut', 'Skill', 'Disability', 'Class', 'SpellV1'] do
    begin
      Liste := Doc.GetElementsByTagName(Balise);
      for K := 0 to Liste.Count - 1 do
      begin
        Element := TDOMElement(Liste.Item[K]);
        if Element.GetAttribute('id') <> Code then Continue;
        Result := ValeurXML(Element.FindNode('Description'));
        if Result <> '' then Exit;
      end;
    end;
    // carriere a niveaux (RULES-WORK_ALCHEMIST -> _1 .. _4) : le libelle du niveau 1 sans ", level 1"
    Liste := Doc.GetElementsByTagName('Career');
    for K := 0 to Liste.Count - 1 do
    begin
      Element := TDOMElement(Liste.Item[K]);
      if Element.GetAttribute('id') <> Code + '_1' then Continue;
      Result := ValeurXML(Element.FindNode('Description'));
      if Pos(',', Result) > 0 then Result := Copy(Result, 1, Pos(',', Result) - 1);
      if Result <> '' then Exit;
    end;
  end;
end;

// Libelle d'une ligne : ses valeurs, codes remplaces par leur libelle, separees par " - ".
function TWinLivres.TexteLigneTable(Ligne: TDOMElement): String;
  function Lib(const Valeur: String): String;
  var
    Trouve: String;
    Element: TDOMElement;
  begin
    Result := LibelleDeCode(Valeur);
    if Result = '' then Result := GetTexteLibelle(Valeur);
    if (Result = '') or (Result = Valeur) then
    begin
      Trouve := LibelleCodeV1(Valeur);
      if Trouve <> '' then Result := Trouve else if Result = '' then Result := Valeur;
    end;
    if (Result = Valeur) and (Pos('DISABILITY_', Valeur) > 0) then
    begin
      // handicap : sa description, dans le livre ouvert
      Element := TrouverElementParId('Disability', Valeur);
      if Element <> nil then
      begin
        Trouve := ValeurXML(Element.FindNode('Description'));
        if Trouve <> '' then Result := Trouve;
      end;
    end;
  end;
var
  Fils: TDOMNode;
  Valeur, Nom, Morceau: String;
begin
  Result := '';
  // ligne sans balise fille (<Entry name="...">"01-09"</Entry>) : son attribut puis son texte
  if not (Ligne.FirstChild is TDOMElement) and (Ligne.GetAttribute('name') <> '') then
    Exit(Lib(Ligne.GetAttribute('name')) + ' ' + ValeurXML(Ligne));
  Fils := Ligne.FirstChild;
  while Fils <> nil do
  begin
    if (Fils.NodeType = ELEMENT_NODE) and (Fils.NodeName <> 'Explanation') then
    begin
      Valeur := ValeurXML(Fils);
      Nom := TDOMElement(Fils).GetAttribute('name');
      if Nom <> '' then Morceau := Lib(Nom) + ' ' + Valeur else Morceau := Lib(Valeur);
      if Result <> '' then Result := Result + ' - ';
      Result := Result + Morceau;
    end;
    Fils := Fils.NextSibling;
  end;
  if Result = '' then Result := Ligne.NodeName;
end;

// Un champ par balise de Parent (et un par attribut name), en descendant dans les sous-chapitres ("SUBCHAPTER_ATTR/Attribut#2").
// Description / Explanation de l'element racine gardent leur libelle habituel et leur attribut language.
// Un commentaire ou un blanc peut preceder la premiere balise fille : on les saute.
function AUneFilleElement(Noeud: TDOMNode): Boolean;
var
  F: TDOMNode;
begin
  Result := False;
  F := Noeud.FirstChild;
  while (F <> nil) and not Result do
  begin
    Result := F.NodeType = ELEMENT_NODE;
    F := F.NextSibling;
  end;
end;

procedure TWinLivres.ChampsGeneriques(Mere: TDOMElement; Prefixe: String; var Champs: TListeChampsFiche; var N: Integer);
var
  Fils: TDOMNode;
  Nom, Chemin, Lib: String;
  K: Integer;
  Vues: TStringList;

  // libelle (code RULES-LAB_...) du titre d'un champ d'arme / d'armure V2 ; la balise elle-meme si aucun
  function LabelEquipementV2(const Element, Balise: String): String;
  begin
    Result := Balise;
    if Balise = 'Skill' then Result := 'RULES-LAB_009'
    else if Balise = 'Damage' then Result := 'RULES-LAB_159'
    else if Balise = 'Availability' then Result := 'RULES-LAB_056'
    else if Balise = 'Reach' then Result := 'RULES-LAB_057'
    else if Balise = 'Price' then Result := 'RULES-LAB_054'
    else if Balise = 'Encumbrance' then Result := 'RULES-LAB_055'
    else if Balise = 'Quality' then Result := 'RULES-LAB_476'
    else if Balise = 'Hand' then Result := 'RULES-LAB_053'
    else if Balise = 'Type' then
    begin
      if Element = 'Weapon' then Result := 'RULES-LAB_171' else Result := 'RULES-LAB_074';
    end
    else if Balise = 'Location' then Result := 'RULES-LAB_075'
    else if Balise = 'ArmorPoint' then Result := 'RULES-LAB_076';
  end;

  // ChoixParTags ; une valeur « CODE_A/CODE_B » (choix entre deux) est ajoutee avec « libelle A / libelle B »
  function ChoixCodesLibelles(const Tags: array of String; const Courant: String): String;
  var
    Parties: TStringList;
    J, P: Integer;
    Libs, L: String;
  begin
    if Pos('/', Courant) = 0 then
    begin
      Result := ChoixParTags(Tags, Courant);
      Exit;
    end;
    Result := ChoixParTags(Tags, '');
    Parties := TStringList.Create;
    try
      Parties.Delimiter := '/';
      Parties.StrictDelimiter := True;
      Parties.DelimitedText := Courant;
      Libs := '';
      for J := 0 to Parties.Count - 1 do
      begin
        // libelle pris dans la liste deja construite (« |CODE=libelle| »), sinon LibelleDeCode, sinon le code
        L := '';
        P := Pos('|' + Trim(Parties[J]) + '=', '|' + Result);
        if P > 0 then
        begin
          L := Copy('|' + Result, P + Length(Trim(Parties[J])) + 2, MaxInt);
          if Pos('|', L) > 0 then L := Copy(L, 1, Pos('|', L) - 1);
        end;
        if L = '' then L := LibelleDeCode(Trim(Parties[J]));
        if L = '' then L := Trim(Parties[J]);
        if Libs <> '' then Libs := Libs + ' / ';
        Libs := Libs + L;
      end;
    finally
      Parties.Free;
    end;
    if Result <> '' then Result := Result + '|';
    Result := Result + Courant + '=' + Libs;
  end;

  // degats V2 que les deux champs (bonus d'attribut, valeur fixe) relisent sans rien changer : "+(BATTR_S)", "+(BATTR_S)-3", "+6"
  function DegatsV2Simple(const S: String): Boolean;
  var
    J, P: Integer;
  begin
    Result := False;
    if Copy(S, 1, 8) = '+(BATTR_' then
    begin
      P := Pos(')', S);
      if P = 0 then Exit;
      Result := True;
      for J := P + 1 to Length(S) do
        if not ((J = P + 1) and (S[J] in ['+', '-'])) and not (S[J] in ['0'..'9']) then Result := False;
      if (P < Length(S)) and (Length(S) = P + 1) then Result := False;
    end
    else if (Length(S) >= 2) and (S[1] = '+') then
    begin
      Result := True;
      for J := 2 to Length(S) do
        if not (S[J] in ['0'..'9']) then Result := False;
    end;
  end;

  // groupes de competence d'arme (« code=libelle »), comme la fiche d'arme dediee
  function ListeGroupesArme: String;
  var
    TriG: TStringList;
    J: Integer;
  begin
    Result := '';
    TriG := TStringList.Create;
    try
      RemplirGroupesArmes(TriG);
      for J := 0 to TriG.Count - 1 do
        Result := Result + '|' + Copy(TriG[J], Pos(#1, TriG[J]) + 1, Length(TriG[J])) + '=' + Copy(TriG[J], 1, Pos(#1, TriG[J]) - 1);
    finally
      TriG.Free;
    end;
    Result := Copy(Result, 2, MaxInt);
  end;

  // portees d'arme V4 / V5 (« code=libelle ») : un code sans libelle n'appartient pas a l'edition chargee ; puis Force x N
  function ListePorteesArme: String;
  const
    PorteesCorps: array[0..10] of String = ('PERSO', 'VSHORT', 'CLOSE', 'SHORT', 'AVERAGE', 'MID', 'LONG', 'VLONG', 'BIG', 'HUGE', 'MASSIVE');
  var
    J: Integer;
    CodeP, LibP: String;
  begin
    Result := '';
    for J := Low(PorteesCorps) to High(PorteesCorps) do
    begin
      CodeP := 'RULES-WEAPR_' + PorteesCorps[J];
      LibP := LibelleAffiche(CodeP);
      if LibP = CodeP then Continue;
      Result := Result + '|' + CodeP + '=' + LibP;
    end;
    for J := 1 to 4 do
    begin
      if J = 1 then CodeP := '(BATTR_S)' else CodeP := '(BATTR_S)X' + IntToStr(J);
      Result := Result + '|' + CodeP + '=' + GetTexteLibelle('RULES-LAB_034') + ' ' + GetAttributLabel('RULES-ATTR_S') + ' x ' + IntToStr(J);
    end;
    Result := Copy(Result, 2, MaxInt);
  end;

  // liste « code=libelle » d'un champ d'arme / d'armure V2 ; '' si le champ reste libre
  function ChoixEquipementV2(const Element, Balise: String): String;
  var
    J: Integer;
  begin
    Result := '';
    if (Element = 'Weapon') and not EstLivreV1 and not EstLivreV2 and (Balise = 'Skill') then
      Result := ListeGroupesArme
    else if (Element = 'Weapon') and not EstLivreV1 and not EstLivreV2 and (Balise = 'Reach') then
      Result := ListePorteesArme
    else if (Element = 'Weapon') and not EstLivreV1 and not EstLivreV2 and (Balise = 'Type') then
      Result := ChoixMotsV1('WTYPE_', ['Sword', 'Axe', 'Hammer', 'Lance', 'Halberd', 'Spear', 'Shield', 'Rapier', 'Swordbreaker'], True)
    else if (Balise = 'Availability') and not EstLivreV2 then
    begin
      // livres V4 : echelle a 5 niveaux (RULES-DISPO_*), comme la fiche equipement
      for J := Low(DisposEquipement) to High(DisposEquipement) do
        Result := Result + '|' + DisposEquipement[J] + '=' + GetTexteLibelle(DisposEquipement[J], DisposEquipement[J]);
      Result := Copy(Result, 2, MaxInt) + '|-=-';
    end
    else if Balise = 'Availability' then
      Result := ChoixMotsV1('DISPO2_', ['Abundant', 'Plentiful', 'Common', 'Average', 'Scarce', 'Rare', 'Very Rare', 'Extremely Rare'], True) + '|-=-'
    else if (Balise = 'Type') and (Element = 'Weapon') then
      Result := ChoixMotsV1('WTYPE2_', ['Ordinary', 'Two-Handed', 'Ammunition', 'Entangling', 'Throwing', 'Gunpowder', 'Flail',
        'Parrying', 'Fencing', 'Cavalry', 'Sling', 'Special', 'Crossbow', 'Longbow', 'Engineer', 'Blowgun', 'Bow', 'Engineering',
        'Choppa', 'Orc Choppa', 'White Wolf', 'Explosive'], True)
    else if (Balise = 'Quality') and (Element = 'Weapon') then
      Result := ChoixMotsV1('WEAPQ_', ['Armour Piercing', 'Balanced', 'Defensive', 'Experimental', 'Fast', 'Impact', 'Precise',
        'Pummelling', 'Shrapnel', 'Slow', 'Snare', 'Special', 'Tiring', 'Unreliable'], True)
    else if (Balise = 'Type') and (Element = 'Armor') then
      for J := Low(MateriauxArmure) to High(MateriauxArmure) do
        Result := Result + '|' + MateriauxArmure[J] + '=' + LibelleAffiche(MateriauxArmure[J])
    else if (Balise = 'Location') and (Element = 'Armor') then
    begin
      for J := Low(EmplacementsArmure) to High(EmplacementsArmure) do
        Result := Result + '|' + EmplacementsArmure[J] + '=' + LibelleAffiche(EmplacementsArmure[J]);
      Result := Result + '|RULES-ARMOL_ANY=' + LibelleAffiche('RULES-ARMOL_ANY');
    end;
    if (Result <> '') and (Result[1] = '|') then Result := Copy(Result, 2, MaxInt);
  end;

begin
  // element sans balise fille : son texte ("." = l'element lui-meme) et son attribut name
  if not AUneFilleElement(Mere) then
  begin
    SetLength(Champs, N + 4);
    Champs[N] := ChampFiche(Prefixe + '.', Mere.NodeName, gfTexte, True, False, True, False);
    Inc(N);
    // tirage de corruption : le dieu de la table (lore) precede la tranche (name)
    if Mere.GetAttribute('lore') <> '' then
    begin
      Champs[N] := ChampFiche(Prefixe + '.@lore', Mere.NodeName + ' (lore)', gfTexte, True, False, True, False);
      Inc(N);
    end;
    if Mere.GetAttribute('name') <> '' then
    begin
      if (Mere.NodeName = 'Entry') and (Mere.ParentNode <> nil) and (Mere.ParentNode.ParentNode <> nil) and
         (Mere.ParentNode.ParentNode.NodeName = ConstXmlDataDisabilityRollV1) then
        // ligne du tirage des handicaps : liste des handicaps du livre et du Rulebook
        Champs[N] := ChampFiche(Prefixe + '.@name', Mere.NodeName + ' (name)', gfCodeLibre, True, False, True, False, ChoixParTags(['Disability'], Mere.GetAttribute('name')))
      else
        Champs[N] := ChampFiche(Prefixe + '.@name', Mere.NodeName + ' (name)', gfTexte, True, False, True, False);
      Inc(N);
    end;
    // ligne d'une table personnelle (DATA_PERSONAL_TABLE) : le detail suit le nom
    if Mere.GetAttribute('detail') <> '' then
    begin
      Champs[N] := ChampFiche(Prefixe + '.@detail', Mere.NodeName + ' (detail)', gfTexte, True, False, True, False);
      Inc(N);
    end;
    SetLength(Champs, N);
    Exit;
  end;
  Vues := TStringList.Create;
  try
    Fils := Mere.FirstChild;
    while Fils <> nil do
    begin
      if Fils.NodeType = ELEMENT_NODE then
      begin
        // une balise repetee (NewCareerClass x3) : la 2e s'appelle "Balise#2", etc.
        K := Vues.IndexOf(Fils.NodeName);
        if K < 0 then K := Vues.AddObject(Fils.NodeName, TObject(PtrInt(0)));
        Vues.Objects[K] := TObject(PtrInt(Vues.Objects[K]) + 1);
        Nom := Fils.NodeName;
        if PtrInt(Vues.Objects[K]) > 1 then Nom := Nom + '#' + IntToStr(PtrInt(Vues.Objects[K]));
        Chemin := Prefixe + Nom;
        // balise passee en tableau (voir ListerBalisesEnTableau) : pas de champ
        if (BalisesTableauGen <> nil) and
           ((BalisesTableauGen.IndexOf(Fils.NodeName) >= 0) or (AnnexesTableauGen.IndexOf(Fils.NodeName) >= 0)) and
           ((Prefixe = '') and (ConteneurTableauGen = '') or
            (ConteneurTableauGen <> '') and (Prefixe = ConteneurTableauGen + '/')) then
        begin
          Fils := Fils.NextSibling;
          Continue;
        end;
        if AUneFilleElement(Fils) then
          ChampsGeneriques(TDOMElement(Fils), Chemin + '/', Champs, N)
        else
        begin
          SetLength(Champs, N + 2);
          if (Prefixe = '') and (Fils.NodeName = 'Explanation') then
            Champs[N] := ChampFiche(Chemin, 'RULES-LAB_003', gfMemo, True, False, not EstLivreV2, True)
          else if (Prefixe = '') and (Fils.NodeName = 'Description') then
            Champs[N] := ChampFiche(Chemin, 'RULES-LAB_002', gfTexte, True, False, not EstLivreV2, True)
          else if ((Mere.NodeName = 'Specie') or
                   (((Mere.NodeName = 'SUBCHAPTER_SKILL') or (Mere.NodeName = 'SUBCHAPTER_TALENT')) and
                    (Mere.ParentNode <> nil) and (Mere.ParentNode.NodeName = 'Specie'))) and
                  (TDOMElement(Fils).GetAttribute('name') = '') and
                  ((Fils.NodeName = 'Ethnic') or (Fils.NodeName = 'Skill') or (Fils.NodeName = 'Talent')) then
          begin
            // familier : ethnie, competence et talent par leur libelle ; « A/B » = un choix entre deux
            if Fils.NodeName = 'Ethnic' then Lib := ChoixCodesLibelles(['Race'], ValeurXML(Fils))
            else if Fils.NodeName = 'Skill' then Lib := ChoixCodesLibelles(['Skill'], ValeurXML(Fils))
            else Lib := ChoixCodesLibelles(['Talent'], ValeurXML(Fils));
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False, Lib);
          end
          else if (Mere.NodeName = 'SUBCHAPTER_CAREER') and (Fils.NodeName = 'Career') and
                  (TDOMElement(Fils).GetAttribute('name') <> '') and
                  (Mere.ParentNode <> nil) and (Mere.ParentNode.NodeName = 'Specie') then
            // carriere d'une espece : la valeur est la chance au tirage (X ou nombre de valeurs du d100)
            Champs[N] := ChampFiche(Chemin, 'RULES-LAB_986', gfTexte, True, False, not EstLivreV2, False)
          else if (Prefixe = '') and (Mere.NodeName = 'Weapon') and (Fils.NodeName = 'Damage') and
                  DegatsV2Simple(ValeurXML(Fils)) then
            Champs[N] := ChampFiche(Chemin, 'RULES-LAB_159', gfDegats, True, False, False, False)
          else if (Prefixe = '') and ((Mere.NodeName = 'Weapon') or (Mere.NodeName = 'Armor')) and
                  (Fils.NodeName = 'Quality') and not EstLivreV1 and not EstLivreV2 then
          begin
            // livre V4 : qualites en liste « A,B,C » (panneau a lignes, libelles), comme la fiche dediee
            if Mere.NodeName = 'Weapon' then RemplirQualitesArme('WEAPB') else RemplirQualitesArme('ARMOB');
            Champs[N] := ChampFiche(Chemin, 'RULES-LAB_476', gfQualites, False, False, False, False);
          end
          else if (Prefixe = '') and ((Mere.NodeName = 'Weapon') or (Mere.NodeName = 'Armor')) and
                  (ChoixEquipementV2(Mere.NodeName, Fils.NodeName) <> '') then
            // arme / armure V2 : valeurs ecrites en codes dans le XML, proposees par leur libelle
            Champs[N] := ChampFiche(Chemin, LabelEquipementV2(Mere.NodeName, Fils.NodeName), gfCodeLibre, True, False, not EstLivreV2, False,
              ChoixEquipementV2(Mere.NodeName, Fils.NodeName))
          else if (Prefixe = '') and ((Mere.NodeName = 'Weapon') or (Mere.NodeName = 'Armor')) and
                  (LabelEquipementV2(Mere.NodeName, Fils.NodeName) <> Fils.NodeName) then
            Champs[N] := ChampFiche(Chemin, LabelEquipementV2(Mere.NodeName, Fils.NodeName), gfTexte, True, False, not EstLivreV2, False)
          else if Fils.NodeName = 'Class' then
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False, ChoixParTags(['Class'], ValeurXML(Fils)))
          else if (Fils.NodeName = 'Career') and (TDOMElement(Fils).GetAttribute('name') = '') then
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False, ChoixParTags(['Career'], ValeurXML(Fils)))
          else if Fils.NodeName = 'Result' then
          begin
            // avancement des pretres : code d'effet lu par le moteur (chargemetierattribut.pas)
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False,
              'WRATH=' + GetTexteLibelle('RULES-LAB_940') + '|UNWORTHY=' + GetTexteLibelle('RULES-LAB_941') +
              '|TRIAL=' + GetTexteLibelle('RULES-LAB_942') + '|NOT_READY=' + GetTexteLibelle('RULES-LAB_943') +
              '|ADVANCE=' + GetTexteLibelle('RULES-LAB_944'));
          end
          else if Fils.NodeName = 'Race' then
          begin
            // gains de points de magie : 'ALL' (toutes les especes) ou un code d'espece
            Lib := ValeurXML(Fils);
            if Lib = 'ALL' then Lib := '';
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False,
              'ALL=' + GetTexteLibelle('RULES-LAB_939') + '|' + ChoixParTags(['Specie', 'Race', 'Nation'], Lib));
          end
          else if Fils.NodeName = 'Generique' then
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False, ChoixMeresSpecialisationV1(ValeurXML(Fils)))
          else if Fils.NodeName = 'Specie' then
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False, ChoixParTags(['Specie', 'Race', 'Nation'], ValeurXML(Fils)))
          else if Fils.NodeName = 'MutationType' then
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfCodeLibre, True, False, not EstLivreV2, False, ChoixParBaliseV2('MutationType'))
          else
            // un texte traduisible du livre (Variations...) garde son attribut language
            // livres V2 : balise du livre ecrite meme vide (obligatoire au schema) ; un sous-chapitre vide (SUBCHAPTER_x) reste facultatif
            // (V1 / V4 : comportement d'avant, une balise vide n'est pas recreee)
            Champs[N] := ChampFiche(Chemin, Fils.NodeName, gfTexte, True, False, (Pos('SUBCHAPTER_', Fils.NodeName) = 1) or not EstLivreV2, TDOMElement(Fils).GetAttribute('language') <> '');
          Inc(N);
          if (Fils.NodeName = 'Opinion') and (TDOMElement(Fils).GetAttribute('target') <> '') then
          begin
            // opinion d'une race : la race visee et celui qui parle sont des attributs
            SetLength(Champs, N + 2);
            Champs[N] := ChampFiche(Chemin + '@target', Fils.NodeName + ' (target)', gfCodeLibre, True, False, not EstLivreV2, False, ChoixParTags(['Specie', 'Race', 'Nation'], TDOMElement(Fils).GetAttribute('target')));
            Inc(N);
            Champs[N] := ChampFiche(Chemin + '@source', Fils.NodeName + ' (source)', gfTexte, True, False, not EstLivreV2, False);
            Inc(N);
          end;
          if TDOMElement(Fils).GetAttribute('name') <> '' then
          begin
            // code de competence en attribut (<Skill name="RULES-COMP_...">) : liste des competences du livre et du Rulebook
            if Fils.NodeName = 'Skill' then
              Champs[N] := ChampFiche(Chemin + '@name', Fils.NodeName + ' (name)', gfCodeLibre, True, False, True, False, ChoixParTags(['Skill'], TDOMElement(Fils).GetAttribute('name')))
            else if Fils.NodeName = 'Career' then
              Champs[N] := ChampFiche(Chemin + '@name', Fils.NodeName + ' (name)', gfCodeLibre, True, False, True, False, ChoixParTags(['Career'], TDOMElement(Fils).GetAttribute('name')))
            else if Fils.NodeName = 'NewCareerClass' then
              Champs[N] := ChampFiche(Chemin + '@name', Fils.NodeName + ' (name)', gfCodeLibre, True, False, True, False, ChoixParTags(['Class'], TDOMElement(Fils).GetAttribute('name')))
            else if (Fils.NodeName = 'Entry') and (Fils.ParentNode <> nil) and (Fils.ParentNode.ParentNode <> nil) and
                    (Fils.ParentNode.ParentNode.NodeName = ConstXmlDataDisabilityRollV1) then
              // ligne du tirage des handicaps : liste des handicaps du livre et du Rulebook
              Champs[N] := ChampFiche(Chemin + '@name', Fils.NodeName + ' (name)', gfCodeLibre, True, False, True, False, ChoixParTags(['Disability'], TDOMElement(Fils).GetAttribute('name')))
            else
              Champs[N] := ChampFiche(Chemin + '@name', Fils.NodeName + ' (name)', gfTexte, True, False, True, False);
            Inc(N);
          end;
          SetLength(Champs, N);
        end;
      end;
      Fils := Fils.NextSibling;
    end;
  finally
    Vues.Free;
  end;
end;

// Fiche generique d'un element d'un livre WFRP1 dont la fiche habituelle (nom + texte) cacherait des donnees :
// elle garde la balise de l'element, son type de noeud et son code, et montre tout le reste.
// Balises feuilles repetees au moins 3 fois sous l'element, toutes avec un attribut name
// (<Eye name="Blue">"2"</Eye>) : elles passent en tableau (nom, valeur) au lieu d'un champ par ligne.
// Cherche d'abord sous l'element, puis dans le premier de ses blocs (SUBCHAPTER_PHYSICAL...) qui en contient ;
// ConteneurTableauGen = nom de ce bloc ('' = l'element lui-meme).
procedure TWinLivres.ListerBalisesEnTableau(Element: TDOMElement);

  procedure Scanner(Mere: TDOMNode);
  var
    Fils: TDOMNode;
    Compte, SansNom: TStringList;
    K: Integer;
    Nom: String;
  begin
    Compte := TStringList.Create;
    SansNom := TStringList.Create;
    try
      Fils := Mere.FirstChild;
      while Fils <> nil do
      begin
        if Fils.NodeType = ELEMENT_NODE then
        begin
          Nom := Fils.NodeName;
          K := Compte.IndexOf(Nom);
          if K < 0 then K := Compte.AddObject(Nom, TObject(PtrInt(0)));
          Compte.Objects[K] := TObject(PtrInt(Compte.Objects[K]) + 1);
          if AUneFilleElement(Fils) or (TDOMElement(Fils).GetAttribute('name') = '') then
            if SansNom.IndexOf(Nom) < 0 then SansNom.Add(Nom);
        end;
        Fils := Fils.NextSibling;
      end;
      for K := 0 to Compte.Count - 1 do
        if (PtrInt(Compte.Objects[K]) >= 3) and (SansNom.IndexOf(Compte[K]) < 0) and
           (Pos(',' + Compte[K] + ',', ',Skill,Career,NewCareerClass,Opinion,Entry,Class,Race,Specie,Result,') = 0) then
          BalisesTableauGen.Add(Compte[K]);
      // balise isolee sans name dont le nom prolonge celui d'un tableau (BirthplaceHuman) : ligne du meme tableau
      for K := 0 to BalisesTableauGen.Count - 1 do
      begin
        AnnexesTableauGen.Add('');
        Fils := Mere.FirstChild;
        while Fils <> nil do
        begin
          Nom := Fils.NodeName;
          if (Fils.NodeType = ELEMENT_NODE) and (Length(Nom) > Length(BalisesTableauGen[K])) and
             (Copy(Nom, 1, Length(BalisesTableauGen[K])) = BalisesTableauGen[K]) and
             not AUneFilleElement(Fils) and (TDOMElement(Fils).GetAttribute('name') = '') and
             (PtrInt(Compte.Objects[Compte.IndexOf(Nom)]) = 1) then
            AnnexesTableauGen[K] := Nom;
          Fils := Fils.NextSibling;
        end;
      end;
    finally
      Compte.Free;
      SansNom.Free;
    end;
  end;

var
  Fils: TDOMNode;
begin
  if BalisesTableauGen = nil then BalisesTableauGen := TStringList.Create;
  if AnnexesTableauGen = nil then AnnexesTableauGen := TStringList.Create;
  BalisesTableauGen.Clear;
  AnnexesTableauGen.Clear;
  ConteneurTableauGen := '';
  Scanner(Element);
  if BalisesTableauGen.Count > 0 then Exit;
  Fils := Element.FirstChild;
  while Fils <> nil do
  begin
    if (Fils.NodeType = ELEMENT_NODE) and AUneFilleElement(Fils) then
    begin
      BalisesTableauGen.Clear;
      AnnexesTableauGen.Clear;
      Scanner(Fils);
      if BalisesTableauGen.Count > 0 then
      begin
        ConteneurTableauGen := Fils.NodeName;
        Exit;
      end;
    end;
    Fils := Fils.NextSibling;
  end;
end;

procedure TWinLivres.AfficherFicheGeneriqueV1(Element: TDOMElement; BaliseElement: String; TypeNoeud: Integer; Code: String);
var
  Champs: TListeChampsFiche;
  N: Integer;
  Specs: array of String;
begin
  FicheTag := BaliseElement;
  FicheTypeNoeud := TypeNoeud;
  FicheGenerique := True;
  N := 0;
  SetLength(Champs, 0);
  ListerBalisesEnTableau(Element);
  ChampsGeneriques(Element, '', Champs, N);
  PanelFiche.Definir(Champs);
  PanelFiche.MasquerGrille;
  // le tableau precedent (Definir l'a deja masque) est jete, un nouveau est cree pour les balises de cette fiche
  FreeAndNil(PanelTableauxGen);
  if BalisesTableauGen.Count > 0 then
  begin
    SetLength(Specs, BalisesTableauGen.Count);
    for N := 0 to BalisesTableauGen.Count - 1 do
    begin
      Specs[N] := BalisesTableauGen[N];
      if AnnexesTableauGen[N] <> '' then Specs[N] := Specs[N] + '+' + AnnexesTableauGen[N];
      // premiere colonne = nom du resultat (Pale Grey, 90...), deuxieme = tranche du de
      // caracteristiques d'une ethnie (RULES-ATTR_M...) : nom affiche par son libelle (colonne codee), le code reste dans le XML
      if BalisesTableauGen[N] = 'Attribut' then
        Specs[N] := Specs[N] + '|' + BalisesTableauGen[N] + '|@name:RULES-LAB_014:c,.:RULES-LAB_976'
      else
        Specs[N] := Specs[N] + '|' + BalisesTableauGen[N] + '|@name:RULES-LAB_014,.:RULES-LAB_976';
    end;
    PanelTableauxGen := TPanelSousBlocs.Create(Self);
    PanelTableauxGen.LargeurNom := 300;
    PanelTableauxGen.Conteneur := ConteneurTableauGen;
    PanelTableauxGen.Initialiser(ButtonChargerXML, @LibelleSortV1, @CodeSortV1, Specs);
    PanelFiche.Extra := PanelTableauxGen;
  end;
  BalisesTableauGen.Clear;
  AnnexesTableauGen.Clear;  // les autres fiches generiques ne doivent pas en heriter
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  CodeDonneeSelectionnee := Code;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Corruption WFRP2 (mutation ou corruption divine) : fiche generique, toutes les balises du livre.
procedure TWinLivres.AfficherDonneeCorruptionV2(Code: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Corruption', Code);
  if Element = nil then Exit;
  AfficherFicheGeneriqueV1(Element, 'Corruption', NT_CORRUPTION_V2, Code);
end;

// Livre WFRP1 ou WFRP2 sans tables de noms (celles-ci gardent leur panneau) : ses fiches generiques montrent toutes les donnees.
function TWinLivres.FicheGeneriqueV1Possible(Element: TDOMElement): Boolean;
var
  Version: String;
begin
  Result := (XMLDoc <> nil) and (Element <> nil) and (Element.FindNode('SUBCHAPTER_NAMES') = nil);
  if not Result then Exit;
  Version := ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode(ConstXmlVersionLivre));
  Result := SameText(Version, 'WFRP1') or SameText(Version, 'WFRP2') or SameText(Version, 'WFRP4');
end;

// Fiche d'une ligne : un champ par balise de la ligne (et un par attribut name).
procedure TWinLivres.AfficherLigneTable(Code: String);
const
  BalisesCadeau: array[0..3] of String = ('EPGift', 'FatePoint', 'Blessing', 'FamiliarSkills');
var
  Ligne: TDOMElement;
  Champs: TListeChampsFiche;
  N, I, J, K: Integer;
  EstPretre, Present: Boolean;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Ligne := TrouverLigneTable(Code);
  if Ligne = nil then Exit;
  FicheTag := 'Ligne';
  FicheTypeNoeud := NT_LIGNE_TABLE_V1;
  N := 0;
  SetLength(Champs, 0);
  ChampsGeneriques(Ligne, '', Champs, N);
  // ligne d'avancement de pretre : les quatre cadeaux facultatifs sont toujours proposes ; vides, leur balise n'existe pas
  EstPretre := (Ligne.ParentNode <> nil) and (Ligne.ParentNode.ParentNode <> nil) and
    (Ligne.ParentNode.ParentNode.NodeName = ConstXmlDataPriestAdvanceV1);
  if EstPretre then
    for I := 0 to High(BalisesCadeau) do
    begin
      Present := False;
      for J := 0 to High(Champs) do
        if Champs[J].Balise = BalisesCadeau[I] then Present := True;
      if Present then Continue;
      J := Length(Champs);
      for K := 0 to High(Champs) do
        if Champs[K].Balise = 'Explanation' then
        begin
          J := K;
          Break;
        end;
      SetLength(Champs, Length(Champs) + 1);
      for K := High(Champs) downto J + 1 do Champs[K] := Champs[K - 1];
      Champs[J] := ChampFiche(BalisesCadeau[I], BalisesCadeau[I], gfTexte, True, False, True, False);
    end;
  PanelFiche.Definir(Champs);
  if EstPretre then
    PanelFiche.OrdreBalises := 'Range,Result,NewCareerClass,*EPGift,*FatePoint,*Blessing,*FamiliarSkills,Explanation';
  PanelFiche.MasquerGrille;
  PanelFiche.Charger(Ligne);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  CodeDonneeSelectionnee := Code;
end;

procedure TWinLivres.ChargerBrancheLignesV1(ChapitreTag, TitreBranche: String; NodeParent: TTreeNode);
var
  Chapitre, Fils, Sous: TDOMNode;
  NodeBranche, NodeSous, NodeFeuille: TTreeNode;
  K, J: Integer;
begin
  if XMLDoc = nil then Exit;
  Chapitre := XMLDoc.GetElementsByTagName(ChapitreTag).Item[0];
  if Chapitre = nil then Exit;
  NodeBranche := TreeViewLivre.Items.AddChild(NodeParent, TitreBranche);
  SetNodeInfo(NodeBranche, NT_CHAPITRE);
  TNodeInfo(NodeBranche.Data).Chapitre := ChapitreTag;
  K := 0;
  Fils := Chapitre.FirstChild;
  while Fils <> nil do
  begin
    if Fils.NodeType = ELEMENT_NODE then
    begin
      if Fils.NodeName = 'Table' then
      begin
        // table nommee (<Table id="CLERIC">) : une sous-branche, ses lignes dessous
        NodeSous := TreeViewLivre.Items.AddChild(NodeBranche, GetTexteLibelle(TDOMElement(Fils).GetAttribute('id')));
        SetNodeInfo(NodeSous, NT_CHAPITRE);
        J := 0;
        Sous := Fils.FirstChild;
        while Sous <> nil do
        begin
          if Sous.NodeType = ELEMENT_NODE then
          begin
            NodeFeuille := TreeViewLivre.Items.AddChild(NodeSous, TexteLigneTable(TDOMElement(Sous)));
            SetNodeInfo(NodeFeuille, NT_LIGNE_TABLE_V1, ChapitreTag + '|' + IntToStr(K) + '|' + IntToStr(J));
            Inc(J);
          end;
          Sous := Sous.NextSibling;
        end;
      end
      else
      begin
        NodeFeuille := TreeViewLivre.Items.AddChild(NodeBranche, TexteLigneTable(TDOMElement(Fils)));
        SetNodeInfo(NodeFeuille, NT_LIGNE_TABLE_V1, ChapitreTag + '|' + IntToStr(K));
      end;
      Inc(K);
    end;
    Fils := Fils.NextSibling;
  end;
end;

// Branche WFRP2 groupee : un noeud par valeur de GroupeTag (domaine d'un sort, table d'equipement),
// dans l'ordre du livre ; elements dans l'ordre du livre aussi, donc sans tri alphabetique.
procedure TWinLivres.ChargerBrancheGroupeeV2(ChapitreTag, ElementTag, GroupeTag, CodeTitre: String; TypeNoeud: Integer; NodeParent: TTreeNode; SansBranche: Boolean);
var
  Chapitre: TDOMNode;
  Chapitres: TDOMNodeList;
  Elements: TDOMNodeList;
  Element: TDOMElement;
  NodeBranche, NodeDomaine, NodeFeuille: TTreeNode;
  Domaines: TStringList;
  I, Idx, C: Integer;
  Code, Domaine, Lib: String;
begin
  if XMLDoc = nil then Exit;
  Chapitres := XMLDoc.GetElementsByTagName(ChapitreTag);
  if Chapitres.Count = 0 then Exit;
  if SansBranche then
    NodeBranche := NodeParent
  else
  begin
    NodeBranche := TreeViewLivre.Items.AddChild(NodeParent, GetTexteLibelle(CodeTitre));
    SetNodeInfo(NodeBranche, NT_CHAPITRE, '', ChapitreTag);
  end;
  Domaines := TStringList.Create;
  try
    // un livre peut porter plusieurs blocs du meme chapitre (ex. DATA_EQUIPMENT_V2) : on les lit tous
    for C := 0 to Chapitres.Count - 1 do
    begin
      Chapitre := Chapitres.Item[C];
      Elements := TDOMElement(Chapitre).GetElementsByTagName(ElementTag);
      for I := 0 to Elements.Count - 1 do
      begin
        Element := TDOMElement(Elements.Item[I]);
        Code := Element.GetAttribute('id');
        if Code = '' then Continue;
        Domaine := ValeurXML(Element.FindNode(GroupeTag));
        Idx := Domaines.IndexOf(Domaine);
        if Idx >= 0 then
          NodeDomaine := TTreeNode(Domaines.Objects[Idx])
        else
        begin
          // livres convertis : la categorie est un CODE (RULES-EQCAT2_*), on affiche son libelle
          // un groupe « RULES-T_xxx__* » est un talent generique : libelle du talent mere + « (Any) »
          if Copy(Domaine, 1, 6) = 'RULES-' then
          begin
            Lib := '';
            if Copy(Domaine, Length(Domaine) - 2, 3) = '__*' then
            begin
              Lib := ChercheTalent(Domaine).Libelle;
              if Lib = '' then
              begin
                // talent mere non defini dans les livres : nom du premier talent du groupe, sans sa parenthese
                Lib := ValeurXML(Element.FindNode('Description'));
                if Pos(' (', Lib) > 0 then Lib := Copy(Lib, 1, Pos(' (', Lib) - 1);
              end;
              if Lib <> '' then Lib := Lib + ' (Any)';
            end;
            if Lib = '' then Lib := GetTexteLibelle(Domaine, Domaine);
            NodeDomaine := TreeViewLivre.Items.AddChild(NodeBranche, Lib);
          end
          else if (ElementTag = 'EquipmentV1') and (Domaine <> '') then
            // livre V1 : la categorie est le mot du livre (WEAPON) ; libelle RULES-V1CAT_*, mot brut si absent
            NodeDomaine := TreeViewLivre.Items.AddChild(NodeBranche, GetTexteLibelle('RULES-V1CAT_' + Domaine, Domaine))
          else
            NodeDomaine := TreeViewLivre.Items.AddChild(NodeBranche, Domaine);
          SetNodeInfo(NodeDomaine, NT_CHAPITRE);
          Domaines.AddObject(Domaine, NodeDomaine);
        end;
        NodeFeuille := TreeViewLivre.Items.AddChild(NodeDomaine, ValeurXML(Element.FindNode('Description')));
        SetNodeInfo(NodeFeuille, TypeNoeud, Code);
      end;
    end;
  finally
    Domaines.Free;
  end;
end;

procedure TWinLivres.AfficherDonneeCondition(Code: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Condition', Code);
  if Element = nil then Exit;
  AfficherFicheCondition(Element);
  CodeDonneeSelectionnee := Code;
end;

// Cree une condition : le libelle suffit (nature Conditional par defaut). Code <LIVRE>-COND_NN, cle dans l'attribut id.
procedure TWinLivres.CreerCondition;
var
  Code, Prefixe, Lib: String;
  Livre, Chapitre: TDOMNode;
  Elem, E: TDOMElement;
  N: Integer;
  Branche, Noeud: TTreeNode;
begin
  if (XMLDoc = nil) or not CreationPermise then Exit;
  Branche := NoeudBrancheSimple(TreeViewLivre.Selected, 'RULES-LAB_488', 58);
  if Branche = nil then Exit;
  if not ConfirmerAbandonModifs then Exit;
  Lib := '';
  if not InputQuery(GetTexteLibelle('RULES-LAB_489'), GetTexteLibelle('RULES-LAB_403'), Lib) then Exit;
  Lib := Trim(Lib);
  if Lib = '' then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_404'));
    Exit;
  end;

  Livre := XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0];
  Prefixe := ValeurXML(Livre.FindNode('CODE_BOOK'));
  N := 1;
  repeat
    Code := Prefixe + '-COND_' + Format('%.2d', [N]);
    Inc(N);
  until TrouverElementParId('Condition', Code) = nil;

  Chapitre := XMLDoc.GetElementsByTagName('DATA_CONDITION').Item[0];
  if Chapitre = nil then
  begin
    Chapitre := XMLDoc.CreateElement('DATA_CONDITION');
    Livre.AppendChild(Chapitre);
  end;
  Elem := XMLDoc.CreateElement('Condition');
  Elem.SetAttribute('id', Code);
  Chapitre.AppendChild(Elem);
  E := XMLDoc.CreateElement('Kind');
  Elem.AppendChild(E);
  EcrireValeurXML(E, 'Conditional');
  EcrireLibelleLivre(Code, Lib);

  Noeud := TreeViewLivre.Items.AddChild(Branche, Lib);
  SetNodeInfo(Noeud, NT_CONDITION, Code);
  Branche.AlphaSort;
  Branche.Expand(False);
  TreeViewLivre.Selected := Noeud;
end;

procedure TWinLivres.MenuNouvelleConditionClick(Sender: TObject);
begin
  CreerCondition;
end;

procedure TWinLivres.FicheValiderClick(Sender: TObject);
var
  Element: TDOMElement;
  Langue, Lib, Hors, LibType: String;
  I: Integer;
  Feuille, Ancien, Groupe: TTreeNode;
begin
  // en-tete du livre : seule la mention legale se range (RangerDisclaimer), le reste est en lecture seule
  if FicheTag = 'Livre' then
  begin
    if RangerDisclaimer then ReafficherFiche;
    Exit;
  end;
  // libelle du livre : le texte se range directement dans le <Text>
  if FicheTag = 'Libelle' then
  begin
    Element := TrouverTexteLibelle(CodeDonneeSelectionnee);
    if Element = nil then Exit;
    EcrireValeurXML(Element, PanelFiche.ValeurChamp('Libelle'));
    if TreeViewLivre.Selected <> nil then
      TreeViewLivre.Selected.Text := PanelFiche.ValeurChamp('Libelle');
    ReafficherFiche;
    Exit;
  end;
  if FicheTag = 'TableValeurs' then
  begin
    if XMLDoc.GetElementsByTagName(CodeDonneeSelectionnee).Count = 0 then Exit;
    Langue := ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('language'));
    if Langue = '' then Langue := 'ENGLISH';
    if PanelFiche.Ecrire(TDOMElement(XMLDoc.GetElementsByTagName(CodeDonneeSelectionnee).Item[0]), Langue) then ReafficherFiche;
    Exit;
  end;
  if FicheTag = 'Career' then
    Element := TrouverCareerElement(CodeDonneeSelectionnee)
  else if FicheTag = 'Ligne' then
    Element := TrouverLigneTable(CodeDonneeSelectionnee)
  else
    Element := TrouverElementParId(FicheTag, CodeDonneeSelectionnee);
  // specialisation d'un autre livre : seules les benedictions se rangent, dans le livre ouvert
  if (Element = nil) and (FicheTag = 'Talent') and (TrouverTalentRulebook(CodeDonneeSelectionnee) <> nil) then
  begin
    RangerBenedictionsDieu(CodeDonneeSelectionnee);
    ReafficherFiche;
    Exit;
  end;
  if Element = nil then Exit;
  Langue := ValeurXML(XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].FindNode('language'));
  if Langue = '' then Langue := 'ENGLISH';
  // sort : au moins un talent d'acces (les cases montrent aussi les dieux d'une benediction, lus dans DATA_SPELL_TALENT)
  if (FicheTag = 'Sort') and (PanelFiche.ValeurChamp('Talent') = '') then
  begin
    ShowMessage(GetTexteLibelle('RULES-LAB_456'));
    Exit;
  end;
  // sort : un talent coche doit ouvrir ce type de sort (<SpellTypes>) - refus, pas d'avertissement (decision Nono 04/10/2026)
  if FicheTag = 'Sort' then
  begin
    Hors := TalentHorsFamille(PanelFiche.ValeurChamp('TypSpell'), PanelFiche.ValeurChamp('Talent'));
    if Hors <> '' then
    begin
      LibType := PanelFiche.ValeurChamp('TypSpell');
      for I := Low(TypesSortXml) to High(TypesSortXml) do
        if SameText(TypesSortXml[I], LibType) then LibType := GetTexteLibelle(TypesSortLib[I]);
      ShowMessage(Format(GetTexteLibelle('RULES-LAB_485'), [LibelleAffiche(Hors), LibType]));
      Exit;
    end;
  end;
  if not PanelFiche.Ecrire(Element, Langue) then Exit;
  if FicheTag = 'Ligne' then
  begin
    if TreeViewLivre.Selected <> nil then TreeViewLivre.Selected.Text := TexteLigneTable(Element);
    ReafficherFiche;
    Exit;
  end;
  if FicheTag = 'Sort' then RangerTalentsSort(Element);
  if FicheTypeNoeud = NT_SORT_V2 then EcrireTalentsTable(Element.GetAttribute('id'), Trim(PanelFiche.ValeurChamp('Talent')));
  if FicheTag = 'Condition' then EcrireLibelleLivre(CodeDonneeSelectionnee, PanelFiche.ValeurChamp('Libelle'));
  if (FicheTag = 'Talent') and (Pos('T_BLESS__', CodeSansLivre(CodeDonneeSelectionnee)) = 1) then
    RangerBenedictionsDieu(CodeDonneeSelectionnee);
  Lib := ValeurXML(Element.FindNode('Description'));
  if FicheTag = 'Condition' then Lib := PanelFiche.ValeurChamp('Libelle');
  // signe astral : un talent efface retire la balise (un <Talent> vide serait lu comme un talent sans code)
  if (FicheTag = 'StarSign') and (Element.FindNode('Talent') <> nil) and (ValeurXML(Element.FindNode('Talent')) = '') then
    Element.RemoveChild(Element.FindNode('Talent'));
  if (FicheTag = 'Specie') and (RacesDataList <> nil) then
  begin
    I := RacesDataList.IndexOf(CodeDonneeSelectionnee);
    if I >= 0 then
    begin
      RacesDataList.Data[I]^.Libelle := Lib;
      RacesDataList.Data[I]^.Description := ValeurXML(Element.FindNode('Explanation'));
    end;
  end;
  for I := 0 to TreeViewLivre.Items.Count - 1 do
    if ((GetNodeType(TreeViewLivre.Items[I]) = FicheTypeNoeud) or ((FicheTag = 'Talent') and (GetNodeType(TreeViewLivre.Items[I]) = NT_SPECIALISATION_TALENT)) or ((FicheTag = 'Skill') and (GetNodeType(TreeViewLivre.Items[I]) in [NT_COMPETENCE_N1, NT_SPECIALISATION_COMPETENCE]))) and (GetNodeCode(TreeViewLivre.Items[I]) = CodeDonneeSelectionnee) then
      TreeViewLivre.Items[I].Text := Lib;
  // sort V1 : la liste (SpellList) a pu changer, on range la feuille sous le bon groupe
  if FicheTypeNoeud = NT_SORT_V1 then
    for I := 0 to TreeViewLivre.Items.Count - 1 do
      if (GetNodeType(TreeViewLivre.Items[I]) = NT_SORT_V1) and (GetNodeCode(TreeViewLivre.Items[I]) = CodeDonneeSelectionnee) then
      begin
        Feuille := TreeViewLivre.Items[I];
        Ancien := Feuille.Parent;
        Groupe := nil;
        Lib := ValeurXML(Element.FindNode('SpellList'));
        if (Ancien <> nil) and (Ancien.Parent <> nil) and (Ancien.Text <> Lib) then
        begin
          Groupe := Ancien.Parent.GetFirstChild;
          while (Groupe <> nil) and (Groupe.Text <> Lib) do Groupe := Groupe.GetNextSibling;
          if Groupe = nil then
          begin
            Groupe := TreeViewLivre.Items.AddChild(Ancien.Parent, Lib);
            SetNodeInfo(Groupe, NT_CHAPITRE);
          end;
          Feuille.MoveTo(Groupe, naAddChild);
          if Ancien.Count = 0 then Ancien.Delete;
          TreeViewLivre.Selected := Feuille;
        end;
        Break;
      end;
  ReafficherFiche;
end;

// Test : sous-chapitres des carrieres (niveaux, competences, talents, attributs, equipement) reconstruits par les
// validateurs de grilles, comme pour les especes. Deuxieme passe, car les validateurs refont des noeuds de l'arbre.
procedure TWinLivres.TesterGrillesCarriere(Doc: TXMLDocument; Racine: TDOMElement);
const
  Types: array[0..4] of Integer = (NT_NIVEAUX_CARRIERE, NT_BRANCHE_COMPETENCE_NIVEAU, NT_BRANCHE_TALENT_NIVEAU,
    NT_BRANCHE_ATTRIBUT_NIVEAU, NT_BRANCHE_EQUIPEMENT_NIVEAU);
  Noms: array[0..4] of String = ('SUBCHAPTER_LEVEL', 'SUBCHAPTER_SKILL', 'SUBCHAPTER_TALENT', 'SUBCHAPTER_ATTR', 'SUBCHAPTER_ITEM');
var
  Codes: TStringList;
  I, K: Integer;
  Code, CodeNoeud: String;
  Noeud: TTreeNode;
  Original, Conteneur, Neuf, Fils: TDOMElement;
  Enfant, Sous, Suivant: TDOMNode;
begin
  Codes := TStringList.Create;
  try
    for I := 0 to TreeViewLivre.Items.Count - 1 do
      if (GetNodeType(TreeViewLivre.Items[I]) = NT_NIVEAUX_CARRIERE) and (Codes.IndexOf(GetNodeCode(TreeViewLivre.Items[I])) < 0) then
        Codes.Add(GetNodeCode(TreeViewLivre.Items[I]));
    for Code in Codes do
    begin
      Original := TrouverCareerElement(Code);
      if Original = nil then Continue;
      for K := 0 to High(Types) do
      begin
        Noeud := nil;
        for I := 0 to TreeViewLivre.Items.Count - 1 do
        begin
          if GetNodeType(TreeViewLivre.Items[I]) <> Types[K] then Continue;
          CodeNoeud := GetNodeCode(TreeViewLivre.Items[I]);
          if (K = 0) and (CodeNoeud = Code) then Noeud := TreeViewLivre.Items[I]
          else if (K > 0) and (Copy(CodeNoeud, 1, Length(Code) + 1) = Code + '|') then Noeud := TreeViewLivre.Items[I];
          if Noeud <> nil then Break;
        end;
        if Noeud = nil then Continue;
        TreeViewLivre.Selected := Noeud;
        TreeViewLivreChange(TreeViewLivre, Noeud);
        Enfant := Original.FindNode(Noms[K]);
        if Enfant <> nil then
          case K of
            0: begin
              // les niveaux restent, leur nom et leur salaire sont relus dans la grille
              Sous := Enfant.FirstChild;
              while Sous <> nil do
              begin
                Suivant := Sous.NextSibling;
                if Sous.NodeName = 'Level' then
                begin
                  while Sous.FirstChild <> nil do Sous.RemoveChild(Sous.FirstChild);
                end;
                Sous := Suivant;
              end;
            end;
            3: begin
              Sous := Enfant.FirstChild;
              while Sous <> nil do
              begin
                if Sous.NodeName = 'Attribut' then EcrireValeurXML(TDOMElement(Sous), '');
                Sous := Sous.NextSibling;
              end;
            end;
          else Original.RemoveChild(Enfant);
          end;
        ButtonAttrValiderClick(nil);
        Enfant := Original.FindNode(Noms[K]);
        if Enfant = nil then Continue;
        Conteneur := TDOMElement(Racine.FindNode('DATA_CAREER'));
        if Conteneur = nil then
        begin
          Conteneur := Doc.CreateElement('DATA_CAREER');
          Racine.AppendChild(Conteneur);
        end;
        Neuf := nil;
        Sous := Conteneur.FirstChild;
        while (Sous <> nil) and (Neuf = nil) do
        begin
          if (Sous.NodeType = ELEMENT_NODE) and (TDOMElement(Sous).GetAttribute('id') = Original.GetAttribute('id')) then
            Neuf := TDOMElement(Sous);
          Sous := Sous.NextSibling;
        end;
        if Neuf = nil then
        begin
          Neuf := Doc.CreateElement('Career');
          Neuf.SetAttribute('id', Original.GetAttribute('id'));
          Conteneur.AppendChild(Neuf);
        end;
        Fils := TDOMElement(Neuf.FindNode(Noms[K]));
        if Fils <> nil then Neuf.RemoveChild(Fils);
        // ordre du schema (CareerType) : niveaux, caracteristiques, competences, talents, equipement, puis Page :
        // le bloc se place avant la premiere balise de rang superieur
        Sous := Neuf.FirstChild;
        while (Sous <> nil) and not ((Sous.NodeType = ELEMENT_NODE) and
          (Pos('|' + Sous.NodeName + '|', '|SUBCHAPTER_LEVEL|SUBCHAPTER_ATTR|SUBCHAPTER_SKILL|SUBCHAPTER_TALENT|SUBCHAPTER_ITEM|Page|') >
           Pos('|' + Enfant.NodeName + '|', '|SUBCHAPTER_LEVEL|SUBCHAPTER_ATTR|SUBCHAPTER_SKILL|SUBCHAPTER_TALENT|SUBCHAPTER_ITEM|Page|'))) do
          Sous := Sous.NextSibling;
        Neuf.InsertBefore(Enfant.CloneNode(True, Doc), Sous);
      end;
    end;
  finally
    Codes.Free;
  end;
end;

// Dump de l'ecran (WarhammerHelp.exe --dumpwinlivre <livre> <sortie.txt> [N]) : pour chaque noeud de
// l'arbre (N par type de noeud, 0 = tous), selectionne le noeud et ecrit en texte ce que la fiche affiche
// (libelles, champs, listes, cases, grilles). Sert a lire l'ecran sans le voir.
procedure TWinLivres.DumpEcran(const Sortie: String; Echantillon: Integer);
var
  I, T: Integer;
  Node: TTreeNode;
  Lignes: TStringList;
  Vus: TStringList;
  Cle: String;
  Cpt: Integer;
begin
  Lignes := TStringList.Create;
  Vus := TStringList.Create;
  TestSansMessage := True;
  TestSansMessageGlobal := True;
  try
    for I := 0 to TreeViewLivre.Items.Count - 1 do
    begin
      Node := TreeViewLivre.Items[I];
      T := GetNodeType(Node);
      if Echantillon > 0 then
      begin
        Cle := IntToStr(T);
        Cpt := StrToIntDef(Vus.Values[Cle], 0);
        if Cpt >= Echantillon then Continue;
        Vus.Values[Cle] := IntToStr(Cpt + 1);
      end;
      Lignes.Add('=== NOEUD type ' + IntToStr(T) + ' code "' + GetNodeCode(Node) + '" texte "' + Node.Text + '"');
      try
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Lignes.Add('  TITRE "' + LabelFormTitle.Caption + '"');
        DumpControles(StringGridDetail.Parent, 1, Lignes);
      except
        on E: Exception do Lignes.Add('  !!! EXCEPTION ' + E.Message);
      end;
    end;
    // arbre complet (tous les noeuds, meme sans echantillon) : texte affiche de chaque noeud, pour reperer un code brut
    Lignes.Add('=== ARBRE COMPLET');
    for I := 0 to TreeViewLivre.Items.Count - 1 do
    begin
      Node := TreeViewLivre.Items[I];
      Lignes.Add(StringOfChar(' ', 2 * Node.Level) + 'type ' + IntToStr(GetNodeType(Node)) + ' "' + Node.Text + '"');
    end;
    Lignes.SaveToFile(Sortie);
  finally
    Vus.Free;
    Lignes.Free;
  end;
end;

// Test d'aller-retour sans ecran (WarhammerHelp.exe --winlivretest <livre> <sortie> <arbre>) :
// chaque fiche des types suivis est affichee puis validee telle quelle, donc le XML ecrit vient
// des champs de la fiche ; <arbre> liste tous les noeuds (type;code;texte) pour verifier qu'aucune donnee ne manque.
// Clique « Ajouter » puis « Retirer » sur chaque couple de boutons visibles d'un meme parent (une grille) ; rend le nombre de couples cliques
function TWinLivres.AjoutRetraitLigneGrilles(Cont: TWinControl; const Ajouter, Retirer: String): Integer;
var
  I, J: Integer;
  BA, BR: TBCButton;
begin
  Result := 0;
  BA := nil;
  BR := nil;
  for I := 0 to Cont.ControlCount - 1 do
  begin
    if Cont.Controls[I] is TWinControl then
      if Cont.Controls[I].Visible then
        Inc(Result, AjoutRetraitLigneGrilles(TWinControl(Cont.Controls[I]), Ajouter, Retirer));
    if (Cont.Controls[I] is TBCButton) and Cont.Controls[I].Visible then
    begin
      if Cont.Controls[I].Caption = Ajouter then BA := TBCButton(Cont.Controls[I]);
      if Cont.Controls[I].Caption = Retirer then BR := TBCButton(Cont.Controls[I]);
    end;
  end;
  J := 0;
  if (BA <> nil) and (BR <> nil) and BA.Enabled and BR.Enabled and Assigned(BA.OnClick) and Assigned(BR.OnClick) then
  begin
    BA.OnClick(BA);
    BR.OnClick(BR);
    J := 1;
  end;
  Inc(Result, J);
end;

procedure TWinLivres.TesterAllerRetour(const Sortie, Arbre: String; Edition: Boolean);
var
  I, IndiceCoches, NbPageModif, NbGrillesModif: Integer;
  Node: TTreeNode;
  Liste: TStringList;
  Doc: TXMLDocument;
  Racine, Conteneur, Original, Neuf, Table: TDOMElement;
  Enfant: TDOMNode;
  J: Integer;
  Attribut: TDOMElement;
  ValeursAttr, Tri: TStringList;
  Langue, Talents, NomSousChapitre: String;
  BenedDieux: TStringList;  // benediction -> dieux qui la donnent (fiches des dieux du livre)
  Present: Boolean;
begin
  NbPageModif := 0;
  NbGrillesModif := 0;
  Liste := TStringList.Create;
  Doc := TXMLDocument.Create;
  TestSansMessage := True;
  TestSansMessageGlobal := True;
  ValeursAttr := TStringList.Create;
  BenedDieux := TStringList.Create;
  try
    // le livre exporte est BATI A PARTIR DE L'ARBRE : chaque element ne contient que les champs de sa fiche
    // (en-tete du livre mis a part) ; ce qui n'est pas affiche n'est pas ecrit, et ressort a la comparaison.
    Racine := Doc.CreateElement('DATA_BOOK');
    Doc.AppendChild(Racine);
    Langue := 'ENGLISH';
    Enfant := XMLDoc.DocumentElement.FirstChild;
    while Enfant <> nil do
    begin
      if (Enfant.NodeType = ELEMENT_NODE) and (Copy(Enfant.NodeName, 1, 5) <> 'DATA_') then
        Racine.AppendChild(Enfant.CloneNode(True, Doc));
      if SameText(Enfant.NodeName, 'language') then Langue := ValeurXML(Enfant);
      Enfant := Enfant.NextSibling;
    end;
    if Langue = '' then Langue := 'ENGLISH';
    for I := 0 to TreeViewLivre.Items.Count - 1 do
    begin
      Node := TreeViewLivre.Items[I];
      Liste.Add(IntToStr(GetNodeType(Node)) + ';' + GetNodeCode(Node) + ';' + Node.Text);
      if GetNodeType(Node) = NT_REGLE_ETHNIE then
      begin
        // regles par ethnie : la grille ecrit tout le chapitre DATA_RULE_SPECIE
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_RULE_SPECIE');
        Racine.AppendChild(Conteneur);
        PanelRegleEthnie.Ecrire(Conteneur);
        Continue;
      end;
      if GetNodeType(Node) = NT_LIBELLE_LIVRE then
      begin
        // libelle du livre : un <Text name> dans le <Label language> de sa langue, texte tire de la fiche
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := TDOMElement(Racine.FindNode('DATA_LABEL'));
        if Conteneur = nil then
        begin
          Conteneur := Doc.CreateElement('DATA_LABEL');
          Racine.AppendChild(Conteneur);
        end;
        Table := nil;
        Enfant := Conteneur.FirstChild;
        while (Enfant <> nil) and (Table = nil) do
        begin
          if TDOMElement(Enfant).GetAttribute('language') = ExtractStringBefore(GetNodeCode(Node), '|') then
            Table := TDOMElement(Enfant);
          Enfant := Enfant.NextSibling;
        end;
        if Table = nil then
        begin
          Table := Doc.CreateElement('Label');
          Table.SetAttribute('language', ExtractStringBefore(GetNodeCode(Node), '|'));
          Conteneur.AppendChild(Table);
        end;
        Neuf := Doc.CreateElement('Text');
        Neuf.SetAttribute('name', PanelFiche.ValeurChamp('Code'));
        Table.AppendChild(Neuf);
        EcrireValeurXML(Neuf, PanelFiche.ValeurChamp('Libelle'));
        Continue;
      end;
      if GetNodeType(Node) = NT_TRAIT_ETHNIE then
      begin
        // traits d'ethnie : la table ecrit tout le chapitre DATA_SPECIE_TRAIT
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_SPECIE_TRAIT');
        Racine.AppendChild(Conteneur);
        PanelTraitEthnie.Ecrire(Conteneur);
        Continue;
      end;
      if GetNodeType(Node) = NT_LIEN_CARRIERE_ESPECE then
      begin
        // liens carriere <-> espece : la table ecrit tout le chapitre DATA_CAREER_SPECIE
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_CAREER_SPECIE');
        Racine.AppendChild(Conteneur);
        PanelCarriereEspece.Ecrire(Conteneur);
        Continue;
      end;
      if GetNodeType(Node) = NT_EQUIP_CLASSE then
      begin
        // equipement de depart par classe : la grille ecrit tout le chapitre DATA_CLASS_ITEM
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_CLASS_ITEM');
        Racine.AppendChild(Conteneur);
        PanelEquipClasse.Ecrire(Conteneur);
        Continue;
      end;
      if GetNodeType(Node) = NT_CORRUPTION_ETHNIE then
      begin
        // tranches de corruption d'une ethnie : la fiche les ecrit dans XMLDoc, les <Specie> de la race
        // sont copies dans les chapitres DATA_CORRUPTION_PHYSICAL / _MENTAL du document neuf
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        ValiderCorruptionEthnie;
        for J := 0 to 1 do
        begin
          Original := TrouverSpecieCorruption(J, GetNodeCode(Node), XMLDoc);
          if Original = nil then Continue;
          Conteneur := TDOMElement(Racine.FindNode(ChapitresCorruption[J]));
          if Conteneur = nil then
          begin
            Conteneur := Doc.CreateElement(ChapitresCorruption[J]);
            Racine.AppendChild(Conteneur);
          end;
          Conteneur.AppendChild(Original.CloneNode(True, Doc));
        end;
        Continue;
      end;
      if GetNodeType(Node) = NT_SECOND_JET then
      begin
        // second jet apres le metier : la grille ecrit tout le chapitre DATA_CAREER_SUBCHOICE
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_CAREER_SUBCHOICE');
        Racine.AppendChild(Conteneur);
        PanelSousMetier.Ecrire(Conteneur);
        Continue;
      end;
      if GetNodeType(Node) = NT_TIRAGE_RACE then
      begin
        // tirage de race : la table ecrit tout le chapitre DATA_RANDOM_SPECIE
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_RANDOM_SPECIE');
        Racine.AppendChild(Conteneur);
        PanelTirageRace.Ecrire(Conteneur);
        Continue;
      end;
      if (GetNodeType(Node) = NT_TABLE_VALEURS) and (GetNodeCode(Node) = 'DATA_RANDOM_TALENT') then
      begin
        // tirages de talents : la matrice talent x ethnie ecrit tout le chapitre
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement('DATA_RANDOM_TALENT');
        Racine.AppendChild(Conteneur);
        PanelTirage.Ecrire(Conteneur);
        Continue;
      end;
      if (GetNodeType(Node) = NT_TABLE_VALEURS) and TableValeursEditable(GetNodeCode(Node)) then
      begin
        // chapitre absent du livre d'origine (livres WFRP2) : la fiche ne s'affiche pas, rien a ecrire
        if XMLDoc.GetElementsByTagName(GetNodeCode(Node)).Count = 0 then Continue;
        // coûts et tirages de corruption : la grille ecrit tout le chapitre
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Conteneur := Doc.CreateElement(GetNodeCode(Node));
        Racine.AppendChild(Conteneur);
        PanelFiche.Ecrire(Conteneur, Langue);
        Continue;
      end;
      if GetNodeType(Node) in [NT_COMPETENCES_RACE, NT_TALENTS_RACE, NT_CARRIERES_RACE, NT_ATTRIBUTS_ETHNIE] then
      begin
        // grilles de sous-branche d'une espece : le sous-chapitre d'origine est retire du document de travail,
        // le validateur le reconstruit a partir de la grille, puis il est copie dans le document neuf
        // (attributs : les elements restent mais leurs valeurs sont videes, sauf les Blessures dont la formule sert a l'affichage)
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);
        Original := TrouverElementParId('Specie', GetNodeCode(Node));
        if Original <> nil then
        begin
          case GetNodeType(Node) of
            NT_COMPETENCES_RACE: NomSousChapitre := 'SUBCHAPTER_SKILL';
            NT_TALENTS_RACE: NomSousChapitre := 'SUBCHAPTER_TALENT';
            NT_ATTRIBUTS_ETHNIE: NomSousChapitre := 'SUBCHAPTER_ATTR';
          else NomSousChapitre := 'SUBCHAPTER_CAREER';
          end;
          Enfant := Original.FindNode(NomSousChapitre);
          ValeursAttr.Clear;
          if GetNodeType(Node) = NT_ATTRIBUTS_ETHNIE then
          begin
            if Enfant <> nil then
              for J := 0 to TDOMElement(Enfant).GetElementsByTagName('Attribut').Count - 1 do
              begin
                Attribut := TDOMElement(TDOMElement(Enfant).GetElementsByTagName('Attribut').Item[J]);
                ValeursAttr.Add(ValeurXML(Attribut));
                if ClasseAttributEthnie(Attribut.GetAttribute('name')) <> 'BLESSURES' then EcrireValeurXML(Attribut, '');
              end;
          end
          else if Enfant <> nil then Original.RemoveChild(Enfant);
          case GetNodeType(Node) of
            NT_CARRIERES_RACE: ValiderCarrieresEthnie;
            NT_ATTRIBUTS_ETHNIE: ButtonAttrValiderClick(nil);
          else ValiderCompetencesEthnie;
          end;
          Enfant := Original.FindNode(NomSousChapitre);
          if (GetNodeType(Node) = NT_ATTRIBUTS_ETHNIE) and (Enfant <> nil) then
          begin
            // valeur que la grille ne sait pas editer : elle reste telle quelle dans un vrai export
            for J := 0 to TDOMElement(Enfant).GetElementsByTagName('Attribut').Count - 1 do
            begin
              Attribut := TDOMElement(TDOMElement(Enfant).GetElementsByTagName('Attribut').Item[J]);
              // la grille n'ecrit pas « +0 » : « 2d10 » reconstruit equivaut a « 2d10+0 » d'origine
              if (J < ValeursAttr.Count) and ((ValeurXML(Attribut) = '') or (ValeurXML(Attribut) + '+0' = ValeursAttr[J])) then
                EcrireValeurXML(Attribut, ValeursAttr[J]);
            end;
          end;
          if Enfant <> nil then
          begin
            Conteneur := TDOMElement(Racine.FindNode('DATA_SPECIE'));
            if Conteneur = nil then
            begin
              Conteneur := Doc.CreateElement('DATA_SPECIE');
              Racine.AppendChild(Conteneur);
            end;
            Neuf := nil;
            Table := TDOMElement(Conteneur.FirstChild);
            while (Table <> nil) and (Neuf = nil) do
            begin
              if (Table.NodeType = ELEMENT_NODE) and (Table.GetAttribute('id') = Original.GetAttribute('id')) then Neuf := Table;
              Table := TDOMElement(Table.NextSibling);
            end;
            if Neuf = nil then
            begin
              Neuf := Doc.CreateElement('Specie');
              Neuf.SetAttribute('id', Original.GetAttribute('id'));
              Conteneur.AppendChild(Neuf);
            end;
            // la fiche de l'espece a pu deja ecrire ce sous-chapitre : la grille le remplace
            if Neuf.FindNode(NomSousChapitre) <> nil then Neuf.RemoveChild(Neuf.FindNode(NomSousChapitre));
            // Page est la derniere balise d'une ethnie (schema) : la grille se place avant elle
            if Neuf.FindNode('Page') <> nil then
              Neuf.InsertBefore(Enfant.CloneNode(True, Doc), Neuf.FindNode('Page'))
            else
              Neuf.AppendChild(Enfant.CloneNode(True, Doc));
          end;
        end;
        Continue;
      end;
      if GetNodeType(Node) in [NT_SORT, NT_SORT_V2, NT_EQUIPEMENT_V2, NT_COMPETENCE_V2, NT_TALENT_V2, NT_SORT_V1, NT_COMPETENCE_V1, NT_EQUIPEMENT_V1, NT_DIEU_V1, NT_CULTE_V1, NT_FAMILIER_V1, NT_CLASSE_V1, NT_METIER_V1, NT_HANDICAP_V1, NT_ATTRIBUT_V1, NT_CORRUPTION_V2, NT_METIER_NIVEAU1, NT_LIGNE_TABLE_V1, NT_RACE, NT_RACE_GROUPE, 27, NT_TALENT_N1, 29, NT_ARME, NT_ARMURE, NT_QUALITE_ARME, NT_QUALITE_ARMURE, NT_PETITE_TABLE_DEBUT + 1, 26, NT_BONUS_CARRIERE, NT_ADAPTATION_CARRIERE, NT_TRAPPING, NT_FABRICATION, NT_SIGNE_ASTRAL, NT_CORRUPTION_PHYSIQUE, NT_CORRUPTION_MENTALE, NT_MALADIE, NT_AFFLICTION, NT_CONDITION, NT_ARMURE_SIMPLIFIEE, NT_NATION, NT_OPTION_REGLE] then
      begin
        TreeViewLivre.Selected := Node;
        TreeViewLivreChange(TreeViewLivre, Node);  // sans ecran, la selection ne declenche pas l'affichage de la fiche
        // ces types n'ont pas tous la fiche generique : seule celle-ci ecrit tout l'element
        // (la fiche d'ethnie a tables de noms n'est pas generique, mais son panneau PanelNoms ecrit SUBCHAPTER_NAMES)
        if (GetNodeType(Node) in [NT_RACE, NT_RACE_GROUPE, 27, NT_PETITE_TABLE_DEBUT + 1]) and not FicheGenerique and
          not ((FicheTag = 'Specie') and (PanelFiche.Extra = PanelNoms)) then Continue;
        if FicheTag = 'Career' then
          Original := TrouverCareerElement(CodeDonneeSelectionnee)
        else if FicheTag = 'Ligne' then
          Original := TrouverLigneTable(CodeDonneeSelectionnee)
        else
          Original := TrouverElementParId(FicheTag, CodeDonneeSelectionnee);
        if (Original = nil) or (Original.ParentNode = nil) then
        begin
          Liste.Add('SANS_ELEMENT;' + FicheTag + ';' + CodeDonneeSelectionnee);
          Continue;
        end;
        if (FicheTag = 'Ligne') and (Original.ParentNode.NodeName = 'Table') then
        begin
          // ligne d'une <Table id="..."> : le chapitre, puis la table, sont recrees dans le document neuf
          Conteneur := TDOMElement(Racine.FindNode(Original.ParentNode.ParentNode.NodeName));
          if Conteneur = nil then
          begin
            Conteneur := Doc.CreateElement(Original.ParentNode.ParentNode.NodeName);
            Racine.AppendChild(Conteneur);
          end;
          Table := nil;
          Enfant := Conteneur.FirstChild;
          while (Enfant <> nil) and (Table = nil) do
          begin
            if (Enfant.NodeName = 'Table') and (TDOMElement(Enfant).GetAttribute('id') = TDOMElement(Original.ParentNode).GetAttribute('id')) then
              Table := TDOMElement(Enfant);
            Enfant := Enfant.NextSibling;
          end;
          if Table = nil then
          begin
            Table := Doc.CreateElement('Table');
            Table.SetAttribute('id', TDOMElement(Original.ParentNode).GetAttribute('id'));
            Conteneur.AppendChild(Table);
          end;
          Conteneur := Table;
        end
        else
        begin
          Conteneur := TDOMElement(Racine.FindNode(Original.ParentNode.NodeName));
          if Conteneur = nil then
          begin
            Conteneur := Doc.CreateElement(Original.ParentNode.NodeName);
            Racine.AppendChild(Conteneur);
          end;
        end;
        Neuf := Doc.CreateElement(Original.NodeName);
        if Original.GetAttribute('id') <> '' then Neuf.SetAttribute('id', Original.GetAttribute('id'));
        // corruptions et maladies : la cle est dans l'attribut name, que la fiche ne porte pas
        if (Original.GetAttribute('id') = '') and ((FicheTag = 'Corruption') or (FicheTag = 'Disease') or (FicheTag = 'Affliction')) then Neuf.SetAttribute('name', Original.GetAttribute('name'));
        Conteneur.AppendChild(Neuf);
        // test d'edition : la Page est saisie a 999 dans chaque fiche qui en a une ; elle doit ressortir telle quelle dans le XML
        if Edition and PanelFiche.PoserTexteChamp('Page', '999') then Inc(NbPageModif);
        // test d'edition : sur chaque grille visible, « Ajouter » puis « Retirer » (ligne ajoutee = ligne retiree) ne doit rien changer au XML
        if Edition then Inc(NbGrillesModif, AjoutRetraitLigneGrilles(Self, GetTexteLibelle('RULES-LAB_899'), GetTexteLibelle('RULES-LAB_421')));
        PanelFiche.Ecrire(Neuf, Langue);
        // carriere WFRP2 : entrees et sorties ne sont plus des champs de la fiche mais des branches de cases
        if (FicheTag = 'Career') and (Original.FindNode('MainProfile') <> nil) then
        begin
          // profils + Advances : la fiche de la branche « caracteristiques », ecrite dans le meme element
          AfficherBrancheCoches(Original.GetAttribute('id'), 3);
          PanelFiche.Ecrire(Neuf, Langue);
          for IndiceCoches := 1 to 3 do
          begin
            PanelListesCarriere[IndiceCoches].Charger(Original);
            PanelListesCarriere[IndiceCoches].Ecrire(Neuf);
          end;
          for IndiceCoches := 0 to 1 do
          begin
            PanelCochesCarriere[IndiceCoches].Charger(Original);
            PanelCochesCarriere[IndiceCoches].Ecrire(Neuf);
          end;
        end;
        // carriere WFRP1 : schema, competences, equipement, entrees et sorties sont des branches, ecrites dans le meme element
        if (FicheTag = 'Career') and (Original.FindNode('AdvanceScheme') <> nil) then
          for IndiceCoches := 3 to 5 do
          begin
            AfficherBrancheCoches(Original.GetAttribute('id'), IndiceCoches + Ord(IndiceCoches = 5));  // genres 3, 4 puis 6 (ni talents, ni entrees, ni sorties en V1)
            PanelFiche.Ecrire(Neuf, Langue);
          end;
        // fabrication generique (balise Applies absente) : la fiche coche tout par defaut, ce que le livre n'ecrit pas
        if (FicheTag = 'Craftsmanship') and (Original.FindNode('Applies') = nil) and (Neuf.FindNode('Applies') <> nil) then
          Neuf.RemoveChild(Neuf.FindNode('Applies'));
        // benediction V4 : ses dieux sont rangés dans DATA_SPELL_TALENT, son <Talent> reste vide (RangerTalentsSort)
        // (une benediction dont le livre garde les dieux dans son <Talent> les garde la : le test ne la deplace pas)
        Talents := '';
        if (FicheTypeNoeud = NT_SORT) and SameText(PanelFiche.ValeurChamp('TypSpell'), 'Blessing') and (ValeurXML(Original.FindNode('Talent')) = '') then
          Talents := 'B';
        if Talents = 'B' then
          if Neuf.FindNode('Talent') <> nil then EcrireValeurXML(TDOMElement(Neuf.FindNode('Talent')), '');
        if (FicheTypeNoeud = NT_SORT_V2) or (Talents = 'B') then
        begin
          // talent d'acces du sort : une ligne de DATA_SPELL_TALENT par talent, comme dans le livre
          Talents := PanelFiche.ValeurChamp('Talent');
          if Talents <> '' then
          begin
            Conteneur := TDOMElement(Racine.FindNode('DATA_SPELL_TALENT'));
            if Conteneur = nil then
            begin
              Conteneur := Doc.CreateElement('DATA_SPELL_TALENT');
              Racine.AppendChild(Conteneur);
            end;
            while Talents <> '' do
            begin
              Table := Doc.CreateElement('Sort');
              Table.SetAttribute('id', Original.GetAttribute('id'));
              Enfant := Doc.CreateElement('Talent');
              // V4 : une seule ligne par benediction, tous les dieux dans le meme <Talent> (EcrireTalentsTable)
              if FicheTypeNoeud = NT_SORT then
                TDOMElement(Enfant).AppendChild(Doc.CreateTextNode('"' + Talents + '"'))
              else
                TDOMElement(Enfant).AppendChild(Doc.CreateTextNode('"' + Trim(ExtractStringBefore(Talents, ',')) + '"'));
              Table.AppendChild(Enfant);
              Conteneur.AppendChild(Table);
              if (FicheTypeNoeud = NT_SORT) or (Pos(',', Talents) = 0) then Talents := '' else Talents := ExtractStringAfter(Talents, ',');
            end;
          end;
        end;
        // dieu de la Benediction : les benedictions cochees dans sa fiche, rangees apres la boucle dans DATA_SPELL_TALENT
        if (FicheTag = 'Talent') and (Pos('T_BLESS__', CodeSansLivre(Original.GetAttribute('id'))) = 1) then
        begin
          Talents := PanelFiche.ValeurChamp('Benedictions');
          while Talents <> '' do
          begin
            NomSousChapitre := Trim(ExtractStringBefore(Talents, ','));
            if NomSousChapitre <> '' then
            begin
              if BenedDieux.IndexOfName(NomSousChapitre) < 0 then BenedDieux.Values[NomSousChapitre] := Original.GetAttribute('id')
              else BenedDieux.Values[NomSousChapitre] := BenedDieux.Values[NomSousChapitre] + ',' + Original.GetAttribute('id');
            end;
            if Pos(',', Talents) = 0 then Talents := '' else Talents := ExtractStringAfter(Talents, ',');
          end;
        end;
        // ethnie sans Description (simple ajout a une race d'un autre livre) : la fiche y affiche le libelle de la race, qui n'est pas une donnee du livre
        if (FicheTag = 'Specie') and (Original.FindNode('Description') = nil) and (Neuf.FindNode('Description') <> nil) then
          Neuf.RemoveChild(Neuf.FindNode('Description'));
      end;
    end;
    // benedictions donnees par les dieux de ce livre mais decrites ailleurs (Rulebook) : une ligne par benediction,
    // sans les dieux que le Rulebook cite deja
    for I := 0 to BenedDieux.Count - 1 do
    begin
      NomSousChapitre := BenedDieux.Names[I];
      Conteneur := TDOMElement(Racine.FindNode('DATA_SPELL_TALENT'));
      Present := False;
      if Conteneur <> nil then
      begin
        Enfant := Conteneur.FirstChild;
        while Enfant <> nil do
        begin
          if (Enfant.NodeType = ELEMENT_NODE) and (TDOMElement(Enfant).GetAttribute('id') = NomSousChapitre) then Present := True;
          Enfant := Enfant.NextSibling;
        end;
      end;
      if Present then Continue;
      Talents := BenedDieux.ValueFromIndex[I];
      Langue := '';
      while Talents <> '' do
      begin
        if not (AutreLivreRulebook and ListeContient(TalentsDeTableDoc(RulebookBaseXML, NomSousChapitre), Trim(ExtractStringBefore(Talents, ',')))) then
        begin
          if Langue <> '' then Langue := Langue + ',';
          Langue := Langue + Trim(ExtractStringBefore(Talents, ','));
        end;
        if Pos(',', Talents) = 0 then Talents := '' else Talents := ExtractStringAfter(Talents, ',');
      end;
      if Langue = '' then Continue;
      // les dieux d une ligne du livre sont ranges par code : l ordre de l arbre n est pas celui du livre
      Tri := TStringList.Create;
      try
        Tri.Delimiter := ',';
        Tri.StrictDelimiter := True;
        Tri.DelimitedText := Langue;
        Tri.Sort;
        Langue := Tri.DelimitedText;
      finally
        Tri.Free;
      end;
      if Conteneur = nil then
      begin
        Conteneur := Doc.CreateElement('DATA_SPELL_TALENT');
        Racine.AppendChild(Conteneur);
      end;
      Table := Doc.CreateElement('Sort');
      Table.SetAttribute('id', NomSousChapitre);
      Enfant := Doc.CreateElement('Talent');
      TDOMElement(Enfant).AppendChild(Doc.CreateTextNode('"' + Langue + '"'));
      Table.AppendChild(Enfant);
      Conteneur.AppendChild(Table);
    end;
    TesterGrillesCarriere(Doc, Racine);
    // le test cree un chapitre pour chaque panneau meme sans ligne : un chapitre sans element n'existe pas dans le livre
    Enfant := Racine.FirstChild;
    while Enfant <> nil do
    begin
      Original := TDOMElement(Enfant.NextSibling);  // (pas un element : sert seulement a garder le suivant)
      if (Enfant.NodeType = ELEMENT_NODE) and (Copy(Enfant.NodeName, 1, 5) = 'DATA_') and
         (TDOMElement(Enfant).GetElementsByTagName('*').Count = 0) then
        Racine.RemoveChild(Enfant);
      Enfant := Original;
    end;
    if Edition then Liste.Add('PAGE_MODIFIEE;' + IntToStr(NbPageModif) + ';');
    if Edition then Liste.Add('GRILLES_AJOUT_RETRAIT;' + IntToStr(NbGrillesModif) + ';');
    Liste.SaveToFile(Arbre);
    WriteXMLFile(Doc, Sortie);
  finally
    BenedDieux.Free;
    ValeursAttr.Free;
    Liste.Free;
    Doc.Free;
  end;
end;

procedure TWinLivres.FicheAnnulerClick(Sender: TObject);
begin
  ReafficherFiche;
end;

procedure TWinLivres.ReafficherFiche;
begin
  if FicheTag = 'TableValeurs' then
    AfficherFicheTableValeurs(CodeDonneeSelectionnee)
  else if (FicheTag = 'Corruption') and (FicheTypeNoeud = NT_CORRUPTION_V2) then
    AfficherDonneeCorruptionV2(CodeDonneeSelectionnee)
  else if (FicheTag = 'Skill') and (FicheTypeNoeud = NT_COMPETENCE_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'SkillV1')
  else if FicheTag = 'Livre' then
    AfficherInfosLivre
  else if FicheTag = 'Disease' then
    AfficherDonneeMaladie(CodeDonneeSelectionnee)
  else if FicheTag = 'Talent' then
    AfficherDonneeTalent(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_007'))
  else if (FicheTag = 'Skill') and (FicheTypeNoeud = 27) then
    AfficherDonneeCompetence(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_146'))
  else if FicheTag = 'Skill' then
    AfficherDonneeCompetence(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_009'))
  else if (FicheTag = 'Career') and (FicheCoches > 0) then
    AfficherBrancheCoches(CodeDonneeSelectionnee, FicheCoches)
  else if FicheTag = 'Career' then
    AfficherDonneeMetier(CodeDonneeSelectionnee)
  else if FicheTag = 'Ligne' then
    AfficherLigneTable(CodeDonneeSelectionnee)
  else if FicheTag = 'Specie' then
    AfficherDonneeRace(CodeDonneeSelectionnee)
  else if FicheTag = 'Race' then
    AfficherRaceGroupe(CodeDonneeSelectionnee)
  else if FicheTag = 'Sort' then
    AfficherDonneeSort(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_083'))
  else if FicheTag = 'SpellV1' then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'SpellV1')
  else if FicheTag = 'EquipmentV1' then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'EquipmentV1')
  else if (FicheTag = 'Deity') and (FicheTypeNoeud = NT_DIEU_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Deity')
  else if (FicheTag = 'Disability') and (FicheTypeNoeud = NT_HANDICAP_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Disability')
  else if (FicheTag = 'Attribut') and (FicheTypeNoeud = NT_ATTRIBUT_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Attribut')
  else if (FicheTag = 'Class') and (FicheTypeNoeud = NT_CLASSE_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Class')
  else if (FicheTag = 'Trade') and (FicheTypeNoeud = NT_METIER_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Trade')
  else if (FicheTag = 'Cult') and (FicheTypeNoeud = NT_CULTE_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Cult')
  else if (FicheTag = 'Familiar') and (FicheTypeNoeud = NT_FAMILIER_V1) then
    AfficherDonneeV2(CodeDonneeSelectionnee, 'Familiar')
  else if FicheTag = 'Craftsmanship' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_125'), 'Craftsmanship')
  else if FicheTag = 'OptionRule' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_277'), 'OptionRule')
  else if FicheTag = 'Nation' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_332'), 'Nation')
  else if FicheTag = 'Condition' then
    AfficherDonneeCondition(CodeDonneeSelectionnee)
  else if FicheTag = 'Corruption' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_156'), 'Corruption')
  else if FicheTag = 'Affliction' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_296'), 'Affliction')
  else if FicheTag = 'StarSign' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_272'), 'StarSign')
  else if FicheTag = 'CareerBonus' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_320'), 'CareerBonus')
  else if FicheTag = 'Adaptation' then
    AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_321'), 'Adaptation')
  else if FicheTag = 'Weapon' then
    AfficherDonneeEquipement(CodeDonneeSelectionnee, 'Weapon', GetTexteLibelle('RULES-LAB_063'))
  else if FicheTag = 'Armor' then
    AfficherDonneeEquipement(CodeDonneeSelectionnee, 'Armor', GetTexteLibelle('RULES-LAB_065'))
  else if FicheTag = 'Trapping' then
    AfficherDonneeEquipement(CodeDonneeSelectionnee, 'Trapping', GetTexteLibelle('RULES-LAB_196'))
  else if FicheTag = 'BonusMalus' then
  begin
    if FicheTypeNoeud = 34 then
      AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_065'))
    else
      AfficherDonneeBonusMalus(CodeDonneeSelectionnee, GetTexteLibelle('RULES-LAB_476') + ' ' + GetTexteLibelle('RULES-LAB_063'));
  end;
end;

// ========== AFFICHER DONNÉE QUALITÉ (BonusMalus) ==========
// Réutilise les deux emplacements libres du formulaire en changeant leur
// intitulé : une qualité n'a ni compétence ni maximum, mais un résumé et
// un modificateur. Chaque procédure d'affichage pose ses propres intitulés,
// pour qu'aucune ne dépende de l'écran précédent.
// Libelle d'un identifiant de donnee (carriere, competence, talent, sort, equipement ou
// texte), '' si rien n'est trouve. La famille se reconnait au motif du code.
function TWinLivres.LibelleDeCode(Code: String): String;
var
  Reste: String;
  TypeEquip: Char;
  Element: TDOMElement;
begin
  Result := '';
  Reste := CodeSansLivre(Code);
  if Pos('WORK', Reste) = 1 then // WORK_NOM
  begin
    if ChercheMetier(Code).CodeMetier <> '' then
      Result := ChercheMetier(Code).Libelle;
  end
  else if (Pos('T0', Reste) = 1) then
    Result := ChercheTalent(Code).Libelle
  else if Pos('COMP', Reste) = 1 then
    Result := ChercheCompetence(Code).Libelle
  else if (Pos('SPELL', Reste) = 1) or (Pos('BENED', Reste) = 1) then
    Result := ChercheSort(Code).Libelle
  else if (Pos('CORPHY', Reste) = 1) or (Pos('CORMEN', Reste) = 1) then
  begin
    // Corruption : entree des tables DATA_CORRUPTION_TABLE_*, cle dans 'name'
    Element := TrouverElementParId('Corruption', Code);
    if Element <> nil then
      Result := ValeurXML(Element.FindNode('Description'));
  end
  else if (Pos(EquipementCC, Reste) > 0) or (Pos(EquipementCT, Reste) > 0) or
          (Pos(EquipementMU, Reste) > 0) or (Pos(EquipementAR, Reste) > 0) or
          (Pos(EquipementTR, Reste) > 0) then
    Result := LibelleEquipement(Code, TypeEquip);
  if Result = '' then
    Result := GetTexteLibelle(Code, '');
  if Result = Code then
    Result := '';
end;

// Remplace dans un texte chaque identifiant "LIVRE-XXXX" reconnu par son libelle
// (ex. "RULES-WORK57" -> "Soldat") ; les autres morceaux restent tels quels.
function TWinLivres.TraduireCodesDansTexte(Texte: String): String;
var
  I, Debut: Integer;
  Jeton, Prefixe, Lib: String;
  Lettre: Boolean;
  K: Integer;

  function EstCaractereCode(C: Char): Boolean;
  begin
    Result := C in ['A'..'Z', 'a'..'z', '0'..'9', '_', '-', '*'];
  end;
begin
  Result := '';
  I := 1;
  while I <= Length(Texte) do
  begin
    if EstCaractereCode(Texte[I]) then
    begin
      Debut := I;
      while (I <= Length(Texte)) and EstCaractereCode(Texte[I]) do
        Inc(I);
      Jeton := Copy(Texte, Debut, I - Debut);
      Lib := '';
      K := Pos('-', Jeton);
      if (K > 1) and (K < Length(Jeton)) then
      begin
        Prefixe := Copy(Jeton, 1, K - 1);
        Lettre := False;
        for K := 1 to Length(Prefixe) do
          if Prefixe[K] in ['A'..'Z'] then Lettre := True
          else if not (Prefixe[K] in ['0'..'9']) then
          begin
            Lettre := False;
            Break;
          end;
        if Lettre then
          Lib := LibelleDeCode(Jeton);
      end;
      if Lib <> '' then
        Result := Result + Lib
      else
        Result := Result + Jeton;
    end
    else
    begin
      Result := Result + Texte[I];
      Inc(I);
    end;
  end;
end;

// Liste des effets portes par une Fabrication (Craftsmanship) : une ligne par balise
// d'effet (ModifyDamage, ModifyCarac, ModifySkill...), libelle traduit, nom de cible
// traduit quand c'est un code (les jokers "*" restent tels quels).
function TWinLivres.EffetsFabrication(Element: TDOMElement): String;
var
  Noeud: TDOMNode;
  Nom, Cible, Valeur, Lib: String;

  function Traduit(Code: String): String;
  begin
    if (Code = '') or (Pos('*', Code) > 0) then
      Result := Code
    else
      Result := GetTexteLibelle(Code, Code);
  end;
begin
  Result := '';
  Noeud := Element.FirstChild;
  while Noeud <> nil do
  begin
    if Noeud.NodeType = ELEMENT_NODE then
    begin
      Nom    := Noeud.NodeName;
      Cible  := TDOMElement(Noeud).GetAttribute('name');
      Valeur := ValeurXML(Noeud);
      Lib    := '';
      if IndiceTypeEffet(Nom) >= 0 then
        // effet de la table : affiche par la grille des modificateurs (PanelBonus)
      else if Nom = 'ModifyDamage' then
        Lib := GetTexteLibelle('RULES-LAB_159') + ' (' + LibCategorieDegat(Cible) + ')'
      else if Nom = 'ModifyCarac' then
        Lib := Traduit(Cible)
      else if Nom = 'ModifySkill' then
      begin
        Lib := ChercheCompetence(Cible).Libelle;
        if Lib = '' then Lib := Traduit(Cible);
      end
      else if Nom = 'ModifArmour' then
        Lib := GetTexteLibelle('RULES-LAB_076') + ' (' + Traduit(Cible) + ')'
      else if Nom = 'ModifyTestSL' then
        Lib := GetTexteLibelle('RULES-LAB_334') + ' (' + Traduit(Cible) + ')'
      else if Nom = 'ModifyCN' then
        Lib := GetTexteLibelle('RULES-LAB_335') + ' (' + Traduit(Cible) + ')'
      else if Nom = 'ModifyDamageReceived' then
        Lib := GetTexteLibelle('RULES-LAB_336')
      else if Nom = 'ModifyAccurate' then
        Lib := GetTexteLibelle('RULES-LAB_337')
      else if Nom = 'ModifyReloadRate' then
        Lib := GetTexteLibelle('RULES-LAB_338')
      else if Nom = 'Encumbrance' then
        Lib := GetTexteLibelle('RULES-LAB_055')
      else if Nom = 'RangeBonus' then
        Lib := GetTexteLibelle('RULES-LAB_057')
      else if Nom = 'Talent' then
      begin
        Lib := GetTexteLibelle('RULES-LAB_007');
        Valeur := ChercheTalent(Valeur).Libelle;
        if Valeur = '' then Valeur := ValeurXML(Noeud);
      end
      else if Nom = 'WeaponQuality' then
      begin
        Lib := GetTexteLibelle('RULES-LAB_292');
        Valeur := Traduit(Valeur);
      end
      else if Nom = 'AlternateWeapon' then
      begin
        Lib := GetTexteLibelle('RULES-LAB_339');
        Valeur := Traduit(Valeur);
      end;
      if Lib <> '' then
      begin
        if Result <> '' then Result := Result + LineEnding;
        Result := Result + Lib + ' : ' + Valeur;
      end;
    end;
    Noeud := Noeud.NextSibling;
  end;
end;

procedure TWinLivres.AfficherDonneeBonusMalus(Code, Titre: String; ElementTag: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  NettoyerForm();
  
  Element := TrouverElementParId(ElementTag, Code);
  if Element = nil then
  begin
    MasquerForm();
    Exit;
  end;

  // Affliction : fiche generique (editable en livre de fan ou inacheve, sinon consultable)
  if ElementTag = 'Affliction' then
  begin
    MasquerForm();
    AfficherFicheAffliction(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Signe astral : fiche generique ; Modifier, Talent et Variant sont conserves tels quels
  if ElementTag = 'StarSign' then
  begin
    MasquerForm();
    AfficherFicheSigneAstral(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Bonus de carriere : fiche generique ; les modificateurs des niveaux et SpecialRule sont conserves tels quels
  if ElementTag = 'CareerBonus' then
  begin
    MasquerForm();
    AfficherFicheBonusCarriere(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Adaptation de carriere : fiche generique et grille des substitutions
  if ElementTag = 'Adaptation' then
  begin
    MasquerForm();
    AfficherFicheAdaptation(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Fabrication (Crafting) : fiche generique
  if ElementTag = 'Craftsmanship' then
  begin
    MasquerForm();
    AfficherFicheFabrication(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Option de regle : fiche generique, TOUJOURS en lecture seule (son Code pilote du code Pascal)
  if ElementTag = 'OptionRule' then
  begin
    MasquerForm();
    AfficherFicheOption(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Nation : fiche generique (Description seule)
  if ElementTag = 'Nation' then
  begin
    MasquerForm();
    AfficherFicheNation(Element);
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Mutation : meme fiche (table physique 42 ou mentale 43)
  if ElementTag = 'Corruption' then
  begin
    MasquerForm();
    AfficherFicheMutation(Element, GetNodeType(TreeViewLivre.Selected));
    CodeDonneeSelectionnee := Code;
    Exit;
  end;

  // Qualite d'arme ou d'armure : fiche generique (en lecture seule dans un livre officiel)
  if ElementTag = 'BonusMalus' then
  begin
    MasquerForm();
    AfficherFicheQualite(Element);
    CodeDonneeSelectionnee := Code;
  end;
end;

// ========== AFFICHER DONNÉE TALENT ==========
// Sert pour DATA_TALENT et DATA_TALENT_SPECIALIZATION. Comme pour les
// compétences, on n'affiche que les champs réellement renseignés : certains
// talents ont un <Attribut>""</Attribut> ou un <Skill>""</Skill> vide.
// Effets d'un talent, tels que les porte le XML : <Modificateur Type Cible Facteur>
// (degats, protection : valeur par niveau), <ModifyCarac>, <ModifySkill> et
// <ModifySkillAttribut>. Les <Effet> sont des drapeaux internes du moteur (AmePure,
// BonusSprint...), sans sens pour le lecteur : non affiches.
function TWinLivres.EffetsTalent(Element: TDOMElement): String;
var
  Noeud: TDOMNode;
  Nom, Cible, Valeur, Lib, Facteur: String;
  Competence: StructureCompetence;

  function Traduit(Code: String): String;
  begin
    if (Code = '') or (Pos('*', Code) > 0) then
      Result := Code
    else
      Result := GetTexteLibelle(Code, Code);
  end;
begin
  Result := '';
  Noeud := Element.FirstChild;
  while Noeud <> nil do
  begin
    if Noeud.NodeType = ELEMENT_NODE then
    begin
      Nom    := Noeud.NodeName;
      Cible  := TDOMElement(Noeud).GetAttribute('name');
      Valeur := ValeurXML(Noeud);
      Lib    := '';
      if Nom = 'Modificateur' then
      begin
        Cible   := TDOMElement(Noeud).GetAttribute('Cible');
        Facteur := TDOMElement(Noeud).GetAttribute('Facteur');
        if Facteur = '' then Facteur := '1';
        Valeur := '+' + Facteur + ' ' + GetTexteLibelle('RULES-LAB_343');
        if TDOMElement(Noeud).GetAttribute('Type') = 'ModifyDamage' then
          Lib := GetTexteLibelle('RULES-LAB_159') + ' (' + LibCategorieDegat(Cible) + ')'
        else if TDOMElement(Noeud).GetAttribute('Type') = 'ModifArmour' then
          Lib := GetTexteLibelle('RULES-LAB_076') + ' (' + Traduit(Cible) + ')';
      end
      else if Nom = 'ModifyCarac' then
        Lib := Traduit(Cible)
      else if Nom = 'ModifySkill' then
      begin
        // "Bonus" est un mot-cle du moteur ; les autres mots-cles ne sont pas affiches
        if Valeur = 'Bonus' then
          Valeur := GetTexteLibelle('RULES-LAB_034')
        else if (Valeur = '') or not (Valeur[1] in ['+', '-', '0'..'9']) then
          Valeur := '';
        if Valeur <> '' then
        begin
          Competence := ChercheCompetence(Cible);
          Lib := Competence.Libelle;
          if Lib = '' then Lib := Traduit(Cible);
        end;
      end
      else if Nom = 'ModifySkillAttribut' then
        Lib := GetTexteLibelle('RULES-LAB_342') + ' (' + Traduit(Cible) + ')';
      if Lib <> '' then
      begin
        if Result <> '' then Result := Result + LineEnding;
        Result := Result + Lib + ' : ' + Valeur;
      end;
    end;
    Noeud := Noeud.NextSibling;
  end;
end;

// Fiche d'un talent ou d'une specialisation de talent : la fiche generique (champs en haut, grille des
// modificateurs en bas), modifiable seulement si le livre l'autorise. Le Max est une liste a saisie libre ;
// <Attribut> n'est plus montre (remplace par ModifyCarac). Une competence donnee par un talent = effet AddSkillToCareer.
procedure TWinLivres.AfficherFicheTalent(Element: TDOMElement; Etranger: Boolean);
const
  Attributs: array[0..9] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel');
var
  Maximums, Dieu, Coches, Verrous, Familles: String;
  I: Integer;
  AvecFamilles: Boolean;
  Champs: TTableauChampsFiche;

  function Rempli(const Balise: String): Boolean;
  begin
    Result := (Element.FindNode(Balise) <> nil) and (Trim(ValeurXML(Element.FindNode(Balise))) <> '');
  end;

  // familles actives : cochees par l'utilisateur, ou deja presentes dans les donnees du talent
  function FamillesActives: String;
  begin
    Result := FamillesTalent;
    if Rempli('Magic') or Rempli('SpellTypes') or Rempli('XpMultiplier') or Rempli('XpFloor') or
       Rempli('XpDivisor') or Rempli('XpFree') or Rempli('SpellMode') then Result := Result + ',MAGIE';
    if Element.FindNode('Effet') <> nil then Result := Result + ',MOTEUR';
    if Rempli('GrantAt') or Rempli('LoseAt') then Result := Result + ',NIVEAU';
  end;

  procedure Ajoute(const Champ: StructureChampFiche);
  begin
    SetLength(Champs, Length(Champs) + 1);
    Champs[High(Champs)] := Champ;
  end;

  procedure AjouteFamilles;
  begin
    if AvecFamilles then
      Ajoute(ChampFiche('FamilleTalent', 'RULES-LAB_FAMILLE_TALENT', gfCases, True, False, True, False,
        'MAGIE=' + GetTexteLibelle('RULES-LAB_FAMILLE_MAGIE', 'Magic talent') +
        '|MOTEUR=' + GetTexteLibelle('RULES-LAB_FAMILLE_MOTEUR', 'Engine effect') +
        '|NIVEAU=' + GetTexteLibelle('RULES-LAB_FAMILLE_NIVEAU', 'Granted / lost at a career level')));
  end;

  // champs que porte un talent de regle : competences liees (PDF), magie, couts d'experience
  procedure AjouteSuite;
  begin
    // PDF : propre a V4 / V5 (absent en V2, 110 talents V4 non vides, balise toujours vide en V5)
    Ajoute(EnGroupes(ChampFiche('PDF', 'RULES-LAB_691', gfTexte, True, False, True, False), 'V4,V5'));
    // groupe « Magie » : visible seulement si l'un de ces champs est deja rempli (talents de magie)
    Ajoute(EnGroupes(ChampFiche('Magic', 'RULES-LAB_968', gfTexte, True, False, True, False), 'Magie'));
    Ajoute(EnGroupes(ChampFiche('SpellTypes', 'RULES-LAB_969', gfTexte, True, False, True, False), 'Magie'));
    Ajoute(EnGroupes(ChampFiche('XpMultiplier', 'RULES-LAB_970', gfTexte, True, False, True, False), 'Magie'));
    Ajoute(EnGroupes(ChampFiche('XpFloor', 'RULES-LAB_971', gfTexte, True, False, True, False), 'Magie'));
    Ajoute(EnGroupes(ChampFiche('XpDivisor', 'RULES-LAB_972', gfTexte, True, False, True, False), 'Magie'));
    Ajoute(EnGroupes(ChampFiche('XpFree', 'RULES-LAB_973', gfTexte, True, False, True, False), 'Magie'));
    // talent octroye / perdu a un niveau de carriere : « CODE_CARRIERE/niveau »
    // groupe « Niveau » : visible seulement si l'un des deux est deja rempli (2 occurrences en tout : Nations of Mankind)
    Ajoute(EnGroupes(ChampFiche('GrantAt', 'RULES-LAB_461', gfTexte, False, False, True, False), 'Niveau'));
    Ajoute(EnGroupes(ChampFiche('LoseAt', 'RULES-LAB_462', gfTexte, False, False, True, False), 'Niveau'));
  end;
begin
  if Element = nil then Exit;
  FicheTag := 'Talent';
  FicheTypeNoeud := NT_TALENT_N1;
  RemplirCompLieeFiche('');  // cibles de competence de la grille
  // Max : chiffres usuels et bonus de chaque caracteristique (notation "(BATTR_x)" lue par winpersonnage)
  Maximums := '1=1|2=2|3=3|4=4|99=99';
  for I := Low(Attributs) to High(Attributs) do
    Maximums := Maximums + '|(BATTR_' + Attributs[I] + ')=' + GetTexteLibelle('RULES-LAB_034') + ' ' +
      GetAttributLabel('RULES-ATTR_' + Attributs[I]);
  Dieu := Element.GetAttribute('id');
  Coches := '';
  Verrous := '';
  FTalentElement := Element;
  FTalentEtranger := Etranger;
  Familles := FamillesActives;
  // cases « familles » : elles ajoutent ou retirent des champs (groupes Magie, Moteur, Niveau) ; jamais ecrites dans le XML
  AvecFamilles := EditionPermise and not Etranger;
  // un dieu de la Benediction (T0012_*) : les benedictions qu'il donne, cochees ici et rangees dans DATA_SPELL_TALENT
  if Pos('T_BLESS__', CodeSansLivre(Dieu)) = 1 then
  begin
    Ajoute(ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True));
    AjouteFamilles;
    Ajoute(ChampFiche('Generique', 'RULES-LAB_146', gfTexte, True, False, True, False));
    Ajoute(ChampFiche('Max', 'RULES-LAB_044', gfCodeLibre, False, False, True, False, Maximums));
    Ajoute(ChampFiche('SpellMode', 'RULES-LAB_956', gfCodeLibre, False, False, True, False, 'AUTO=AUTO|CHOICE=CHOICE|NONE=NONE'));
    Ajoute(ChampFiche('Test', 'RULES-LAB_422', gfTexte, True, False, True));
    Ajoute(ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True));
    Ajoute(ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False));
    AjouteSuite;
    Ajoute(ChampFiche('Benedictions', 'RULES-LAB_066', gfCases, True, False, True, False, ChoixBenedictions(Dieu, Coches, Verrous)));
    FiltrerChampsFiche(Champs, Element, VersionFicheLivre, Familles);
    PanelFiche.Definir(Champs);
    PanelFiche.DeclarerVirtuel('Benedictions');
    if AvecFamilles then PanelFiche.DeclarerVirtuel('FamilleTalent');
    if Pos('MOTEUR', Familles) > 0 then PanelFiche.Extra := PanelEffetTalent;  // groupe « Moteur »
  end
  else if Element.FindNode('Generique') <> nil then
  begin
    // specialisation de talent : modele de talent generique (ex. "RULES-TAL_xxx_*")
    Ajoute(ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True));
    AjouteFamilles;
    Ajoute(ChampFiche('Generique', 'RULES-LAB_146', gfCodeLibre, True, False, True, False,
      ChoixMeresTalentsV2(ValeurXML(Element.FindNode('Generique')))));
    Ajoute(ChampFiche('Max', 'RULES-LAB_044', gfCodeLibre, False, False, True, False, Maximums));
    Ajoute(EnGroupes(ChampFiche('Trait', 'RULES-LAB_688', gfCases, True, False, True, False,
      ConstVrai + '=' + GetTexteLibelle('RULES-LAB_688', 'Creature trait (cannot be bought or chosen)')), 'V4,V5'));
    Ajoute(ChampFiche('Test', 'RULES-LAB_422', gfTexte, True, False, True));
    Ajoute(ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True));
    Ajoute(ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False));
    AjouteSuite;
    FiltrerChampsFiche(Champs, Element, VersionFicheLivre, Familles);
    PanelFiche.Definir(Champs);
    if AvecFamilles then PanelFiche.DeclarerVirtuel('FamilleTalent');
    if Pos('MOTEUR', Familles) > 0 then PanelFiche.Extra := PanelEffetTalent;  // groupe « Moteur »
  end
  else
  begin
    Ajoute(ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True));
    AjouteFamilles;
    Ajoute(ChampFiche('Max', 'RULES-LAB_044', gfCodeLibre, False, False, True, False, Maximums));
    Ajoute(EnGroupes(ChampFiche('Trait', 'RULES-LAB_688', gfCases, True, False, True, False,
      ConstVrai + '=' + GetTexteLibelle('RULES-LAB_688', 'Creature trait (cannot be bought or chosen)')), 'V4,V5'));
    // SpellMode : rare (V2 7 / 646, V4 6 / 567, V5 5 / 230), range dans le groupe Magie
    Ajoute(EnGroupes(ChampFiche('SpellMode', 'RULES-LAB_956', gfCodeLibre, False, False, True, False, 'AUTO=AUTO|CHOICE=CHOICE|NONE=NONE'), 'Magie'));
    Ajoute(ChampFiche('Test', 'RULES-LAB_422', gfTexte, True, False, True));
    Ajoute(ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True));
    Ajoute(ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False));
    AjouteSuite;
    FiltrerChampsFiche(Champs, Element, VersionFicheLivre, Familles);
    PanelFiche.Definir(Champs);
    if AvecFamilles then PanelFiche.DeclarerVirtuel('FamilleTalent');
    // groupe « Moteur » : le bloc Engine effect n'apparait que si le talent a un <Effet> ou si la famille est cochee
    if Pos('MOTEUR', Familles) > 0 then PanelFiche.Extra := PanelEffetTalent;
  end;
  PanelFiche.Charger(Element);
  if AvecFamilles then PanelFiche.CocherCodes('FamilleTalent', Familles);
  BenedInit := Coches;
  if Coches <> '' then PanelFiche.CocherCodes('Benedictions', Coches);
  PanelFiche.VerrouillerCases(Verrous);
  // une specialisation d'un autre livre : tout est en lecture seule, sauf les cases des benedictions (livre modifiable)
  if Etranger and EditionPermise then
    PanelFiche.LectureSeuleSauf('Benedictions')
  else
    PanelFiche.LectureSeule := not EditionPermise or Etranger;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

// Reconstruit la fiche du talent affiche apres un changement de famille, en gardant les saisies en cours
// (champs texte et listes ; la grille des bonus et le bloc Engine effect repartent des donnees du livre).
procedure TWinLivres.ReconstruireFicheTalent(Donnee: PtrInt);
var
  Balises, Valeurs: TStringList;
begin
  if (FTalentElement = nil) or ((FicheTag <> 'Talent') and (FicheTag <> 'Trapping') and (FicheTag <> 'Career') and
     (FicheTag <> 'Specie')) then Exit;
  Balises := TStringList.Create;
  Valeurs := TStringList.Create;
  try
    try
      PanelFiche.SauverValeurs(Balises, Valeurs);
      // comme en navigation normale : fiche masquee et focus hors de la fiche avant que Definir detruise les champs
      // (une liste detruite pendant qu'elle a le focus faisait fermer WinLivre)
      PanelFiche.Visible := False;
      ActiveControl := nil;
      if FicheTag = 'Trapping' then
        AfficherFicheTrapping(FTalentElement)
      else if FicheTag = 'Career' then
        AfficherFicheCarriere(FTalentElement)
      else if FicheTag = 'Specie' then
        AfficherFicheEthnie(FTalentElement, CodeDonneeSelectionnee)
      else
        AfficherFicheTalent(FTalentElement, FTalentEtranger);
      PanelFiche.RestaurerValeurs(Balises, Valeurs);
    except
      on E: Exception do
        ShowMessage('Reconstruction de la fiche talent : ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    Valeurs.Free;
    Balises.Free;
  end;
end;

procedure TWinLivres.TimerFamilleTick(Sender: TObject);
begin
  FTimerFamille.Enabled := False;
  ReconstruireFicheTalent(0);
end;

procedure TWinLivres.AfficherDonneeTalent(CodeTalent, Titre: String);
var
  Element: TDOMElement;
  Etranger: Boolean;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Talent', CodeTalent);
  Etranger := False;
  if Element = nil then
  begin
    Element := TrouverTalentRulebook(CodeTalent);
    Etranger := Element <> nil;
  end;
  if Element = nil then Exit;
  FamillesTalent := '';
  AfficherFicheTalent(Element, Etranger);
  CodeDonneeSelectionnee := CodeTalent;
end;

// Donnees portees par un element mais sans controle de saisie : competence de base (Basic),
// talent octroye / perdu a un niveau de carriere (GrantAt / LoseAt), effets d'une qualite d'arme
// (Modify*). Affichees en fin de titre, en libelles, pour qu'elles ne restent pas invisibles.
function TWinLivres.NotesDonnees(Element: TDOMElement): String;
  function Carriere(const Valeur: String): String;
  var
    Code, Niv: String;
    CarEl: TDOMElement;
  begin
    Code := Trim(ExtractStringBefore(Valeur, '/'));
    Niv  := Trim(ExtractStringAfter(Valeur, '/'));
    CarEl := TrouverCareerElement(Code);
    if CarEl <> nil then
      Code := ValeurXML(CarEl.FindNode('Description'));
    Result := Code + ' ' + GetTexteLibelle('RULES-LAB_463') + ' ' + Niv;
  end;
  procedure Ajouter(const Texte: String);
  begin
    if Result <> '' then Result := Result + ' ; ';
    Result := Result + Texte;
  end;
  procedure Effet(const Balise, Code: String);
  var
    N: TDOMNode;
  begin
    N := Element.FindNode(Balise);
    if N <> nil then
      Ajouter(GetTexteLibelle(Code) + ' ' + ValeurXML(N));
  end;
var
  N: TDOMNode;
begin
  Result := '';
  if Element = nil then Exit;
  N := Element.FindNode('Basic');
  if (N <> nil) and (ValeurXML(N) = '1') then
    Ajouter(GetTexteLibelle('RULES-LAB_460'));
  N := Element.FindNode('GrantAt');
  if N <> nil then
    Ajouter(GetTexteLibelle('RULES-LAB_461') + ' : ' + Carriere(ValeurXML(N)));
  N := Element.FindNode('LoseAt');
  if N <> nil then
    Ajouter(GetTexteLibelle('RULES-LAB_462') + ' : ' + Carriere(ValeurXML(N)));
  Effet('ModifyAccurate', 'RULES-LAB_464');
  Effet('ModifyReloadRate', 'RULES-LAB_466');
  Effet('ModifyReloadMin', 'RULES-LAB_467');
  if Result <> '' then
    Result := '  [' + Result + ']';
end;

// ========== AFFICHER DONNÉE COMPÉTENCE ==========
// Sert pour DATA_SKILL et DATA_SKILL_SPECIALIZATION : fiche generique (PanelFiche). Une specialisation
// n'a qu'un libelle : Attribut et Explication ne se montrent que pour une competence (balise Attribut presente).
procedure TWinLivres.AfficherFicheCompetence(Element: TDOMElement; TypeNoeud: Integer);
const
  Attributs: array[0..9] of String = ('WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel');
var
  CodeAttr, Choix: String;
  I: Integer;
  Champs: TTableauChampsFiche;
begin
  if Element = nil then Exit;
  FicheTag := 'Skill';
  FicheTypeNoeud := TypeNoeud;
  CodeAttr := ValeurXML(Element.FindNode('Attribut'));
  // une competence generique (« Trade (Various) ») porte un Attribut vide : la balise est la, la valeur non
  if (Element.FindNode('Attribut') = nil) and (Element.FindNode('Generique') <> nil) and
     (ValeurXML(Element.FindNode('Generique')) <> '') then
  begin
    // specialisation : sa mere (RULES-COMP_LORE__*) en libelle (« Lore (Any) »), pas en code brut
    CodeAttr := ValeurXML(Element.FindNode('Generique'));
    Choix := LibelleDeCode(CodeAttr);
    if (Choix = '') and (Copy(CodeAttr, Length(CodeAttr) - 2, 3) = '__*') then
    begin
      Choix := LibelleCodeV1(Copy(CodeAttr, 1, Length(CodeAttr) - 3));
      if Choix <> '' then Choix := Choix + ' (Any)';
    end;
    if Choix = '' then Choix := CodeAttr;
    PanelFiche.Definir([
      ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True),
      ChampFiche('Generique', 'RULES-LAB_146', gfCodeLibre, True, False, True, False, CodeAttr + '=' + Choix)]);
  end
  else if Element.FindNode('Attribut') = nil then
    PanelFiche.Definir([
      ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True)])
  else
  begin
    // les dix caracteristiques ; une valeur hors liste reste choisissable
    Choix := '';
    for I := Low(Attributs) to High(Attributs) do
      Choix := Choix + '|RULES-ATTR_' + Attributs[I] + '=' + GetAttributLabel('RULES-ATTR_' + Attributs[I]);
    if CodeAttr = '' then
      Choix := Choix + '|='
    else if Pos('|' + CodeAttr + '=', Choix) = 0 then
      Choix := Choix + '|' + CodeAttr + '=' + GetAttributLabel(CodeAttr);
    // groupes par version : Basic n'existe pas en V5, RelatedTalents seulement en V2 (un champ deja rempli reste visible)
    SetLength(Champs, 6);
    Champs[0] := ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True);
    Champs[1] := ChampFiche('Attribut', 'RULES-LAB_008', gfCode, False, CodeAttr <> '', CodeAttr = '', False, Copy(Choix, 2, MaxInt));
    Champs[2] := ChampFiche('Explanation', 'RULES-LAB_279', gfMemo, True, False, True);
    Champs[3] := EnGroupes(ChampFiche('Basic', 'RULES-LAB_881', gfCode, False, False, True, False,
      '1=' + GetTexteLibelle('RULES-LAB_882') + '|0=' + GetTexteLibelle('RULES-LAB_883')), 'V1,V2,V4');
    // talents lies : cases a cocher (codes de talents separes par des virgules) ; « None » ancien = aucune case
    Champs[4] := EnGroupes(ChampFiche('RelatedTalents', 'RULES-LAB_707', gfCases, True, False, True, False,
      ChoixTalentsLiesV2(ValeurXML(Element.FindNode('RelatedTalents')))), 'V2');
    Champs[5] := ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False);
    FiltrerChampsFiche(Champs, Element, VersionFicheLivre, '');
    PanelFiche.Definir(Champs);
    PanelFiche.OrdreBalises := 'Attribut,Description,Explanation,*Basic,*RelatedTalents,*Page';
  end;
  PanelFiche.MasquerGrille;  // une competence ne porte aucun modificateur
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.AfficherDonneeCompetence(CodeComp, Titre: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverElementParId('Skill', CodeComp);
  if Element = nil then Exit;
  if (Titre = GetTexteLibelle('RULES-LAB_146')) and FicheGeneriqueV1Possible(Element) then
    AfficherFicheGeneriqueV1(Element, 'Skill', 27, CodeComp)
  else if Titre = GetTexteLibelle('RULES-LAB_146') then
    AfficherFicheCompetence(Element, 27)
  else
    AfficherFicheCompetence(Element, 26);
  CodeDonneeSelectionnee := CodeComp;
end;

// Libelle d'une competence de carriere V4, ou d'un choix « A/B/C » : chaque morceau en libelle, jamais en code brut.
function TWinLivres.LibelleChoixCompetence(const Code: String): String;
var
  Morceaux: TStringList;
  K: Integer;
  Un, Lib: String;
begin
  Result := '';
  Morceaux := TStringList.Create;
  try
    Morceaux.StrictDelimiter := True;
    Morceaux.Delimiter := '/';
    Morceaux.DelimitedText := Code;
    for K := 0 to Morceaux.Count - 1 do
    begin
      Un := Trim(Morceaux[K]);
      Lib := ChercheCompetence(Un).Libelle;
      if ChercheCompetence(Un).CodeCompetence = '' then Lib := '';
      if Lib = '' then Lib := LibelleDeCode(Un);
      if (Lib = '') and (Copy(Un, Length(Un) - 2, 3) = '__*') then
      begin
        Lib := LibelleCodeV1(Copy(Un, 1, Length(Un) - 3));
        if Lib <> '' then Lib := Lib + ' (Any)';
      end;
      if Lib = '' then Lib := Un;
      if K > 0 then Result := Result + ' / ';
      Result := Result + Lib;
    end;
  finally
    Morceaux.Free;
  end;
end;

function TWinLivres.LibelleCompetenceCarriereV1(Code: String): String;
var
  Competence: StructureCompetence;
begin
  Competence := ChercheCompetence(Code);
  if Competence.CodeCompetence <> '' then
    Result := Competence.Libelle
  else
    Result := LibelleAffiche(Code);
  if ((Result = '') or (Result = Code)) and (LibelleCodeV1(Code) <> '') then Result := LibelleCodeV1(Code);
end;

// Libelle d'un sort / d'une priere WFRP1 du livre ouvert (sa Description), sinon celui du code.
// Tables de valeurs a plage -> valeur (<Cost name="0-5">"25"</Cost>, <Chance name="01-05">"code de corruption"</Chance>) :
// grille editable, la fiche ecrit tout le chapitre.
function TWinLivres.TableValeursEditable(const Chapitre: String): Boolean;
begin
  Result := (Chapitre = 'DATA_SKILL_COST') or (Chapitre = 'DATA_ATTRIBUT_COST') or
    (Chapitre = 'DATA_CORRUPTION_PHYSICAL_CHANCE') or (Chapitre = 'DATA_CORRUPTION_MENTAL_CHANCE') or
    (Chapitre = 'DATA_SPECIE_CAREER_CHOICE') or (Chapitre = 'DATA_CAREER_LINK_V1') or
    (Chapitre = 'DATA_CAREER_LINK_V2');
end;

procedure TWinLivres.AfficherFicheTableValeurs(const Chapitre: String);
var
  Chap, Liste: TDOMNodeList;
  Libelles: TStringList;
  Table: String;
  Fils: TDOMNode;
  I: Integer;
  PM: StructureMetier;
  DuRulebook: Boolean;
begin
  MasquerAfficherElements('');
  MasquerForm();
  if XMLDoc = nil then Exit;
  Chap := XMLDoc.GetElementsByTagName(Chapitre);
  // liens entre carrieres : un livre V1 neuf n'a pas encore le chapitre, il est cree vide (autorise par SCHEMA_WFRP1.xsd)
  if (Chap.Count = 0) and CreationPermise and
     (((Chapitre = 'DATA_CAREER_LINK_V1') and EstLivreV1) or ((Chapitre = 'DATA_CAREER_LINK_V2') and EstLivreV2)) then
  begin
    XMLDoc.GetElementsByTagName('DATA_BOOK').Item[0].AppendChild(XMLDoc.CreateElement(Chapitre));
    Chap := XMLDoc.GetElementsByTagName(Chapitre);
  end;
  // table de regles absente de ce livre : celle du Rulebook s'applique, montree en lecture seule
  DuRulebook := False;
  if (Chap.Count = 0) and (RulebookBaseXML <> nil) then
  begin
    Chap := RulebookBaseXML.GetElementsByTagName(Chapitre);
    DuRulebook := Chap.Count > 0;
  end;
  if Chap.Count = 0 then Exit;
  FicheTag := 'TableValeurs';
  FicheTypeNoeud := NT_TABLE_VALEURS;
  CodeDonneeSelectionnee := Chapitre;
  if DuRulebook then
    LabelFormTitle.Caption := LibelleChapitre(Chapitre) + ' - ' + GetTexteLibelle('RULES-LAB_TABLE_RULEBOOK', 'Rulebook table, not changed by this book');
  PanelFiche.Definir([]);
  PanelFiche.MasquerGrille;  // pas de modificateurs dans ces tables
  if (Chapitre = 'DATA_CORRUPTION_PHYSICAL_CHANCE') or (Chapitre = 'DATA_CORRUPTION_MENTAL_CHANCE') then
  begin
    // la colonne propose les corruptions existantes de la table, pas une saisie libre
    Libelles := TStringList.Create;
    try
      if Chapitre = 'DATA_CORRUPTION_PHYSICAL_CHANCE' then Table := 'DATA_CORRUPTION_TABLE_PHYSICAL'
      else Table := 'DATA_CORRUPTION_TABLE_MENTAL';
      Liste := XMLDoc.GetElementsByTagName(Table);
      if Liste.Count > 0 then
      begin
        Fils := Liste.Item[0].FirstChild;
        while Fils <> nil do
        begin
          if (Fils.NodeType = ELEMENT_NODE) and (Fils.NodeName = 'Corruption') and
             (ValeurXML(Fils.FindNode('Description')) <> '') then
            Libelles.Add(ValeurXML(Fils.FindNode('Description')));
          Fils := Fils.NextSibling;
        end;
      end;
      PanelTableChance.DefinirChoix(0, 1, Libelles);
    finally
      Libelles.Free;
    end;
    PanelFiche.Extra := PanelTableChance;
  end
  else if Chapitre = 'DATA_SPECIE_CAREER_CHOICE' then
    PanelFiche.Extra := PanelTableChoix
  else if (Chapitre = 'DATA_CAREER_LINK_V1') or (Chapitre = 'DATA_CAREER_LINK_V2') then
  begin
    // les deux colonnes proposent les carrieres connues (livre ouvert, puis celles du jeu), pas une saisie libre
    Libelles := TStringList.Create;
    try
      Libelles.Sorted := True;
      Libelles.Duplicates := dupIgnore;
      Liste := XMLDoc.GetElementsByTagName('Career');
      for I := 0 to Liste.Count - 1 do
        if (TDOMElement(Liste.Item[I]).GetAttribute('id') <> '') and (Liste.Item[I].FindNode('AdvanceScheme') <> nil) and
           (ValeurXML(Liste.Item[I].FindNode('Description')) <> '') then
          Libelles.Add(ValeurXML(Liste.Item[I].FindNode('Description')));
      for PM in ListMetier do
        if Trim(PM.Libelle) <> '' then Libelles.Add(Trim(PM.Libelle));
      PanelLiensCarriere.DefinirChoix(0, 0, Libelles);
      PanelLiensCarriere.DefinirChoix(0, 1, Libelles);
    finally
      Libelles.Free;
    end;
    PanelFiche.Extra := PanelLiensCarriere;
  end
  else
    PanelFiche.Extra := PanelTableCout;
  RemplirCompLieeFiche('');
  PanelFiche.Charger(TDOMElement(Chap.Item[0]));
  PanelFiche.LectureSeule := DuRulebook or not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise and not DuRulebook then PrendreSnapshotFiche;
end;

function TWinLivres.LibelleCorruption(Code: String): String;
var
  Corruption: TDOMElement;
begin
  Result := '';
  Corruption := TrouverElementParId('Corruption', Code);
  if Corruption <> nil then Result := ValeurXML(Corruption.FindNode('Description'));
end;

function TWinLivres.CodeCorruption(Libelle: String): String;
var
  Elements: TDOMNodeList;
  I: Integer;
  Cle: String;
begin
  Result := '';
  Elements := XMLDoc.GetElementsByTagName('Corruption');
  for I := 0 to Elements.Count - 1 do
    if ValeurXML(Elements.Item[I].FindNode('Description')) = Libelle then
    begin
      Cle := TDOMElement(Elements.Item[I]).GetAttribute('id');
      if Cle = '' then Cle := TDOMElement(Elements.Item[I]).GetAttribute('name');
      Result := Cle;
      Exit;
    end;
end;

// Race ou metier d'un choix de metier par espece : element du livre ouvert, sinon race / metier du jeu, sinon le code.
function TWinLivres.LibelleChoixMetier(Code: String): String;
var
  El: TDOMElement;
  PR: StructureRace;
  PM: StructureMetier;
begin
  Result := '';
  El := TrouverElementParId('Career', Code);
  if El = nil then El := TrouverElementParId('Specie', Code);
  if El <> nil then Result := ValeurXML(El.FindNode('Description'));
  if Result = '' then
  begin
    PM := ChercheMetier(Code);
    if PM.CodeMetier = Code then Result := PM.Libelle;
  end;
  if Result = '' then
  begin
    PR := ChercheRace(Code);
    if PR.CodeRace = Code then Result := PR.Libelle;
  end;
end;

function TWinLivres.CodeChoixMetier(Libelle: String): String;
var
  PM: StructureMetier;
  PR: StructureRace;
begin
  Result := CodeSortV1(Libelle);
  if Result <> '' then Exit;
  for PM in ListMetier do
    if Trim(PM.Libelle) = Trim(Libelle) then Exit(PM.CodeMetier);
  for PR in ListRace do
    if Trim(PR.Libelle) = Trim(Libelle) then Exit(PR.CodeRace);
end;

function TWinLivres.LibelleSortV1(Code: String): String;
var
  Sort: TDOMElement;
begin
  Result := '';
  Sort := TrouverElementParId('SpellV1', Code);
  if Sort <> nil then Result := ValeurXML(Sort.FindNode('Description'));
  if Result = '' then Result := LibelleCompetenceCarriereV1(Code);
  // caracteristique (RULES-ATTR_M, _Ld...) : libelle d'interface ou Description du Rulebook
  if ((Result = '') or (Result = Code)) and (Copy(Code, 1, 11) = 'RULES-ATTR_') then
    Result := GetAttributLabel(Code);
end;

// Code de l'element du livre dont la Description est Libelle (sort, competence, carriere...), sinon de
// l'attribut du jeu dont le libelle est Libelle ; '' si aucun.
function TWinLivres.CodeSortV1(Libelle: String): String;
const
  Attributs: array[0..13] of String = ('M', 'WS', 'BS', 'S', 'T', 'W', 'I', 'A', 'Dex', 'Ld', 'Int', 'Cl', 'WP', 'Fel');
var
  Elements: TDOMNodeList;
  I: Integer;
begin
  Result := '';
  Elements := XMLDoc.GetElementsByTagName('*');
  for I := 0 to Elements.Count - 1 do
    if (TDOMElement(Elements.Item[I]).GetAttribute('id') <> '')
      and (ValeurXML(Elements.Item[I].FindNode('Description')) = Libelle) then
    begin
      Result := TDOMElement(Elements.Item[I]).GetAttribute('id');
      Exit;
    end;
  for I := 0 to High(Attributs) do
    if (GetAttributLabel('RULES-ATTR_' + Attributs[I]) = Libelle) or (Attributs[I] = Libelle) then
    begin
      Result := 'RULES-ATTR_' + Attributs[I];
      Exit;
    end;
end;

// Competences du livre ouvert, au format « code=libelle|... » d'un champ de fiche a liste.
function TWinLivres.ChoixCompetencesV1: String;
var
  Elements: TDOMNodeList;
  I: Integer;
begin
  Result := '';
  Elements := XMLDoc.GetElementsByTagName('Skill');
  for I := 0 to Elements.Count - 1 do
    if TDOMElement(Elements.Item[I]).GetAttribute('id') <> '' then
      Result := Result + '|' + TDOMElement(Elements.Item[I]).GetAttribute('id') + '='
        + ValeurXML(Elements.Item[I].FindNode('Description'));
  Result := Copy(Result, 2, MaxInt);
end;

// Competences a specialisations (Variants) du livre ouvert et du Rulebook : « <id>__*=<libelle> (Any)|... »,
// la valeur de <Generique> d'une specialisation ; la valeur courante s'ajoute si elle manque.
function TWinLivres.ChoixMeresSpecialisationV1(const Courant: String): String;
var
  Liste: TStringList;
  Doc: TXMLDocument;
  Elements: TDOMNodeList;
  I, N: Integer;
  Code, Lib: String;
begin
  Result := '';
  Liste := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupIgnore;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      Elements := Doc.GetElementsByTagName('Skill');
      for I := 0 to Elements.Count - 1 do
      begin
        Code := TDOMElement(Elements.Item[I]).GetAttribute('id');
        // V4 : la mere d'une specialisation est une competence dont l'id finit par __* (son libelle porte deja « (Any) »)
        if (Length(Code) > 3) and (Copy(Code, Length(Code) - 2, 3) = '__*') then
        begin
          Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
          if Lib <> '' then Liste.Add(Lib + #9 + Code);
          Continue;
        end;
        if (Code = '') or (Elements.Item[I].FindNode('Variants') = nil) then Continue;
        Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
        if Lib = '' then Lib := Code;
        Liste.Add(Lib + ' (Any)' + #9 + Code + '__*');
      end;
    end;
    if (Courant <> '') and (Pos(#9 + Courant, Liste.Text) = 0) then
      Liste.Add(Courant + #9 + Courant);
    for I := 0 to Liste.Count - 1 do
      Result := Result + '|' + Copy(Liste[I], Pos(#9, Liste[I]) + 1, MaxInt) + '=' + Copy(Liste[I], 1, Pos(#9, Liste[I]) - 1);
    Result := Copy(Result, 2, MaxInt);
  finally
    Liste.Free;
  end;
end;

// Divinites (balise Deity avec id) du livre ouvert et du Rulebook : « code=libelle|... » ; la valeur courante s'ajoute si elle manque.
function TWinLivres.ChoixDivinitesV1(const Courant: String): String;
var
  Liste: TStringList;
  Doc: TXMLDocument;
  Elements: TDOMNodeList;
  I, N: Integer;
  Code, Lib: String;
begin
  Result := '';
  Liste := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupIgnore;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      Elements := Doc.GetElementsByTagName('Deity');
      for I := 0 to Elements.Count - 1 do
      begin
        Code := TDOMElement(Elements.Item[I]).GetAttribute('id');
        if Code = '' then Continue;
        Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
        if Lib = '' then Lib := Code;
        Liste.Add(Lib + #9 + Code);
      end;
    end;
    if (Courant <> '') and (Pos(#9 + Courant, Liste.Text) = 0) then
      Liste.Add(Courant + #9 + Courant);
    for I := 0 to Liste.Count - 1 do
      Result := Result + '|' + Copy(Liste[I], Pos(#9, Liste[I]) + 1, MaxInt) + '=' + Copy(Liste[I], 1, Pos(#9, Liste[I]) - 1);
    Result := Copy(Result, 2, MaxInt);
  finally
    Liste.Free;
  end;
end;

// Valeurs distinctes d'une balise (SpellList...) dans le livre ouvert et le Rulebook, triees, au format « valeur=valeur|... ».
function TWinLivres.ChoixValeursBalise(const Balise, Courant: String): String;
var
  Liste: TStringList;
  Doc: TXMLDocument;
  Elements: TDOMNodeList;
  I, N: Integer;
  Valeur: String;
begin
  Result := '';
  Liste := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupIgnore;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      Elements := Doc.GetElementsByTagName(Balise);
      for I := 0 to Elements.Count - 1 do
      begin
        Valeur := ValeurXML(Elements.Item[I]);
        if Valeur <> '' then Liste.Add(Valeur);
      end;
    end;
    if Courant <> '' then Liste.Add(Courant);
    for I := 0 to Liste.Count - 1 do
      Result := Result + '|' + Liste[I] + '=' + Liste[I];
    Result := Copy(Result, 2, MaxInt);
  finally
    Liste.Free;
  end;
end;

// Regimes de familier (valeurs de <Diet> du livre ouvert), au format « code=libelle|... ».
function TWinLivres.ChoixRegimeV1: String;
var
  Elements: TDOMNodeList;
  I: Integer;
  Code: String;
begin
  Result := '';
  Elements := XMLDoc.GetElementsByTagName('Diet');
  for I := 0 to Elements.Count - 1 do
  begin
    Code := ValeurXML(Elements.Item[I]);
    if (Code <> '') and (Pos('|' + Code + '=', '|' + Result) = 0) then
      Result := Result + '|' + Code + '=' + GetTexteLibelle('RULES-FAMDIET_' + Code);
  end;
  Result := Copy(Result, 2, MaxInt);
end;

// Liste « mot du livre = libelle traduit » pour une balise V1 dont la valeur est un mot anglais du livre
// (Plentiful, Neutral...). Le libelle est RULES-<Prefixe><MOT EN MAJUSCULES, ESPACES -> _> ; sans libelle, le mot lui-meme.
// La valeur ecrite dans le XML reste le mot du livre.
function TWinLivres.ChoixMotsV1(const Prefixe: String; const Mots: array of String; Codes: Boolean): String;
var
  I: Integer;
  Cle: String;
begin
  Result := '';
  for I := 0 to High(Mots) do
  begin
    Cle := 'RULES-' + Prefixe + StringReplace(StringReplace(StringReplace(UpperCase(Mots[I]), ' ', '_', [rfReplaceAll]),
      '-', '_', [rfReplaceAll]), '/', '_', [rfReplaceAll]);
    // Codes = True : la valeur ecrite dans le XML est le CODE (livres convertis) ; sinon le mot du livre
    if Codes then
      Result := Result + '|' + Cle + '=' + GetTexteLibelle(Cle, Mots[I])
    else
      Result := Result + '|' + Mots[I] + '=' + GetTexteLibelle(Cle, Mots[I]);
  end;
  Result := Copy(Result, 2, MaxInt);
end;

// Talents « mere » d'une specialisation (id finissant par __*, ex. Arcane Lore) du livre ouvert et du Rulebook :
// « code=libelle (Any) » tries par libelle ; le code courant s'ajoute s'il manque.
function TWinLivres.ChoixMeresTalentsV2(const Courant: String): String;
var
  Liste: TStringList;
  Doc: TXMLDocument;
  Elements: TDOMNodeList;
  I, N: Integer;
  Code, Lib: String;
begin
  Result := '';
  Liste := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupIgnore;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      Elements := Doc.GetElementsByTagName('Talent');
      for I := 0 to Elements.Count - 1 do
      begin
        Code := TDOMElement(Elements.Item[I]).GetAttribute('id');
        if (Length(Code) < 4) or (Copy(Code, Length(Code) - 2, 3) <> '__*') then Continue;
        Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
        if Lib = '' then Lib := Code;
        // les meres V4 portent deja « (Any) » dans leur libelle (« Blessed (Any) »), celles de V2 non
        if (Length(Lib) >= 5) and SameText(Copy(Lib, Length(Lib) - 4, 5), '(Any)') then
          Liste.Add(Lib + #9 + Code)
        else
          Liste.Add(Lib + ' (Any)' + #9 + Code);
      end;
    end;
    if (Courant <> '') and (Pos(#9 + Courant, Liste.Text) = 0) then
      Liste.Add(Courant + #9 + Courant);
    for I := 0 to Liste.Count - 1 do
      Result := Result + '|' + Copy(Liste[I], Pos(#9, Liste[I]) + 1, MaxInt) + '=' + Copy(Liste[I], 1, Pos(#9, Liste[I]) - 1);
    Result := Copy(Result, 2, MaxInt);
  finally
    Liste.Free;
  end;
end;

// Talents proposes en « talents lies » d'une competence V2 : tous ceux du livre ouvert et du Rulebook (sauf les meres
// « __* »), « code=libelle » tries par libelle ; un code deja present dans la valeur s'ajoute s'il manque.
function TWinLivres.ChoixTalentsLiesV2(const Courants: String): String;
var
  Liste, Deja: TStringList;
  Doc: TXMLDocument;
  Elements: TDOMNodeList;
  I, N: Integer;
  Code, Lib: String;
begin
  Result := '';
  Liste := TStringList.Create;
  Deja := TStringList.Create;
  try
    Liste.Sorted := True;
    Liste.Duplicates := dupIgnore;
    Deja.Sorted := True;
    Deja.Duplicates := dupIgnore;
    for N := 0 to 1 do
    begin
      if N = 0 then Doc := XMLDoc else Doc := RulebookXML;
      if Doc = nil then Continue;
      Elements := Doc.GetElementsByTagName('Talent');
      for I := 0 to Elements.Count - 1 do
      begin
        Code := TDOMElement(Elements.Item[I]).GetAttribute('id');
        if (Code = '') or (Copy(Code, Length(Code) - 2, 3) = '__*') or (Deja.IndexOf(Code) >= 0) then Continue;
        Deja.Add(Code);
        Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
        if Lib = '' then Lib := Code;
        Liste.Add(Lib + #9 + Code);
      end;
    end;
    // valeur deja presente (codes, ou ancien texte libre) : ce qui n'est pas dans la liste est ajoute tel quel
    with TStringList.Create do
    try
      StrictDelimiter := True;
      Delimiter := ',';
      DelimitedText := Courants;
      for I := 0 to Count - 1 do
        if (Trim(Strings[I]) <> '') and (Deja.IndexOf(Trim(Strings[I])) < 0) then
          Liste.Add(Trim(Strings[I]) + #9 + Trim(Strings[I]));
    finally
      Free;
    end;
    for I := 0 to Liste.Count - 1 do
      Result := Result + '|' + Copy(Liste[I], Pos(#9, Liste[I]) + 1, MaxInt) + '=' + Copy(Liste[I], 1, Pos(#9, Liste[I]) - 1);
    Result := Copy(Result, 2, MaxInt);
  finally
    Deja.Free;
    Liste.Free;
  end;
end;

// Liste de choix d'une balise des livres WFRP2 (valeurs relevees dans les 70 livres par TRAVAIL\valeurs_par_balise.py) ;
// '' si la balise n'a pas de liste. Une valeur du livre hors liste reste affichee et conservee telle quelle.
function TWinLivres.ChoixParBaliseV2(const Balise: String): String;
begin
  Result := '';
  if Balise = 'Category' then
    Result := ChoixMotsV1('EQCAT2_', ['Creatures', 'Melee Weapons', 'Missile Weapons', 'Runes', 'Special Equipment', 'Magic Items',
      'Miscellanea', 'Tools', 'Tables', 'Clothing', 'Carrying Equipment', 'Food and Drink', 'Personal Equipment',
      'Reading and Writing', 'Livestock', 'Vehicles', 'Mounts', 'Advanced Armour', 'Musical Instruments', 'Lighting',
      'Services', 'Barding', 'Familiars', 'Vehicle Upgrades', 'Travel Services', 'Mount Gear', 'Animals', 'Lodging'], True)
  else if Balise = 'SubCategory' then
    Result := ChoixMotsV1('EQCAT2_', ['Draughts', 'Talismanic Runes', 'Weapon Runes', 'Divine Runes', 'Poisons', 'Religious Equipment',
      'Armour Runes', 'Oddities', 'Artefacts', 'Replacements and Appendages', 'Engineering Runes', 'Ammunition', 'Chain',
      'Skilled Services', 'Leather', 'Plate', 'Common Services', 'Armour Sets', 'Construct Runes', 'Tool Runes',
      'Protection Runes', 'Alchemical Mixtures'], True)
  else if Balise = 'Group' then
    Result := ChoixMotsV1('WTYPE2_', ['Ordinary', 'Two-Handed', 'Ammunition', 'Entangling', 'Throwing', 'Gunpowder', 'Flail',
      'Parrying', 'Fencing', 'Cavalry', 'Sling', 'Special', 'Crossbow', 'Longbow', 'Engineer', 'Blowgun', 'Bow', 'Engineering',
      'Choppa', 'Orc Choppa', 'White Wolf'], True)
  else if Balise = 'Volatility' then
    Result := ChoixMotsV1('V2VOLAT_', ['Mild', 'Minor', 'Moderate', 'Major', 'Extreme'], True)
  else if Balise = 'RuneType' then
    Result := ChoixMotsV1('V2RUNE_', ['Talismanic', 'Weapon', 'Armour', 'Divine/Talismanic', 'Engineering', 'Divine/Special',
      'Divine', 'Construct', 'Divine/Weapon', 'Tool', 'Protection'], True)
  else if Balise = 'RitualType' then
    Result := ChoixMotsV1('V2RITUAL_', ['Arcane', 'Divine', 'Arcane/Divine', 'Dark Magic', 'Natural'], True)
  else if Balise = 'MutationType' then
    Result := ChoixMotsV1('V2MUT_', ['Single', 'Multiple', 'Multiple 2', 'Multiple 3', 'Multiple 4', 'Multiple 5', 'Multiple 6'], True);
end;

// Fiche d'une carriere : libelle, description, classe et competence principale (une des competences de niveau 1).
procedure TWinLivres.AfficherFicheCarriere(Element: TDOMElement);
var
  Classe, CodeComp, LibComp, ChoixClasse, ChoixComp, Familles: String;
  Elements: TDOMNodeList;
  ChapitreSkill: TDOMNode;
  Tri: TStringList;
  Codes: TStringList;
  I: Integer;
  AvecFamilles: Boolean;
  Champs: TTableauChampsFiche;

  procedure AjouteChamp(var Liste: TTableauChampsFiche; const Champ: StructureChampFiche);
  begin
    SetLength(Liste, Length(Liste) + 1);
    Liste[High(Liste)] := Champ;
  end;
begin
  if Element = nil then Exit;
  FicheTag := 'Career';
  FicheTypeNoeud := NT_METIER_NIVEAU1;
  FicheCoches := 0;
  // Carriere WFRP2 (CONTEXT.md 2.122) : fiche simple, consultation seule, aucun champ de saisie V4
  if Element.FindNode('MainProfile') <> nil then
    begin
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True),
        ChampFiche('Basic', 'RULES-LAB_881', gfCode, False, False, True, False, '1=' + GetTexteLibelle('RULES-LAB_882') + '|0=' + GetTexteLibelle('RULES-LAB_883')),
        ChampFiche('StartMoney', 'RULES-LAB_694', gfTexte, False, False, True, False),
        ChampFiche('Source', 'RULES-LAB_946', gfTexte, False, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
      // profils, competences, talents, equipement, entrees et sorties : une branche chacun (AfficherBrancheCoches)
      PanelFiche.OrdreBalises := 'Description,Explanation,MainProfile,SecondaryProfile,Advances,Skills,Talents,Trappings,*StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,*ExitCodes,*Basic,*Source,*Page';
      PanelFiche.MasquerGrille;
      PanelFiche.Charger(Element);
      PanelFiche.LectureSeule := not EditionPermise;
      PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
      PanelFiche.Visible := True;
      if EditionPermise then PrendreSnapshotFiche;
      Exit;
    end;
  // Carriere WFRP1 (schema d'avancement, pas de niveaux) : textes du livre ; le schema et les listes de codes ne sont pas montres
  if Element.FindNode('AdvanceScheme') <> nil then
    begin
      Codes := TStringList.Create;
      try
        RemplirCodesClasse(Codes, ValeurXML(Element.FindNode('Class')));
        ChoixClasse := '';
        for I := 0 to Codes.Count - 1 do
          ChoixClasse := ChoixClasse + '|' + Codes[I] + '=' + GetTexteLibelle(Codes[I]);
      finally
        Codes.Free;
      end;
      // schema d'avancement, competences, equipement, entrees et sorties : une branche chacun (AfficherBrancheCarriereV1)
      PanelFiche.Definir([
        ChampFiche('Description', 'RULES-LAB_002', gfTexte, True),
        ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True),
        ChampFiche('Basic', 'RULES-LAB_881', gfCode, False, False, True, False, '1=' + GetTexteLibelle('RULES-LAB_882') + '|0=' + GetTexteLibelle('RULES-LAB_883')),
        ChampFiche('Class', 'RULES-PDF_MAIN1_CLASS', gfCode, False, False, True, False, Copy(ChoixClasse, 2, MaxInt)),
        ChampFiche('Level', 'RULES-LAB_019', gfTexte, False, False, True, False),
        ChampFiche('EntryCost', 'RULES-LAB_919', gfTexte, False, False, True, False),
        ChampFiche('MagicSchool', 'RULES-LAB_896', gfTexte, False, False, True, False),
        ChampFiche('Page', 'RULES-LAB_699', gfTexte, True, False, True, False)]);
      PanelFiche.OrdreBalises := 'Description,Explanation,*Class,*Basic,*Level,*MagicSchool,*EntryCost,AdvanceScheme,Skills,SUBCHAPTER_SKILL,Trappings,SUBCHAPTER_ITEM,*StartMoney,*Source,*Page';
      PanelFiche.MasquerGrille;
      PanelFiche.Extra := nil;
      PanelFiche.Charger(Element);
      PanelFiche.LectureSeule := not EditionPermise;
      PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
      PanelFiche.Visible := True;
      if EditionPermise then PrendreSnapshotFiche;
      Exit;
    end;
  Classe :=ValeurXML(Element.FindNode('Class'));
  CodeComp := ValeurXML(Element.FindNode('Skill'));
  // classes : le XML porte un code (CLASS_BURG), traduit a l'affichage
  Codes := TStringList.Create;
  try
    RemplirCodesClasse(Codes, Classe);
    ChoixClasse := '';
    for I := 0 to Codes.Count - 1 do
      ChoixClasse := ChoixClasse + '|' + Codes[I] + '=' + GetTexteLibelle(Codes[I]);
  finally
    Codes.Free;
  end;
  // la competence principale est l'une des competences de niveau 1 de la carriere ; la valeur actuelle reste choisissable
  Tri := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupAccept;
    ChapitreSkill := Element.FindNode('SUBCHAPTER_SKILL');
    if ChapitreSkill <> nil then
    begin
      Elements := TDOMElement(ChapitreSkill).GetElementsByTagName('Skill');
      for I := 0 to Elements.Count - 1 do
        if ValeurXML(Elements.Item[I]) = '1' then
        begin
          LibComp := TDOMElement(Elements.Item[I]).GetAttribute('name');
          if LibComp = '' then Continue;
          Tri.Add(LibelleChoixCompetence(LibComp) + #1 + LibComp);
        end;
    end;
    if (CodeComp <> '') and (Pos(#1 + CodeComp, Tri.Text) = 0) then
    begin
      Tri.Add(LibelleChoixCompetence(CodeComp) + #1 + CodeComp);
    end;
    ChoixComp := '';
    for I := 0 to Tri.Count - 1 do
      ChoixComp := ChoixComp + '|' + Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I])) + '=' + Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1);
  finally
    Tri.Free;
  end;
  // familles (groupes Espece, Variante) : champs rares (Specie 10 carrieres sur 203, Parent 18, PictureLevel 9, V4 seulement),
  // montres si deja remplis ou si l'utilisateur coche la famille (case virtuelle, jamais ecrite dans le XML)
  Familles := FamillesTalent;
  if (Element.FindNode('Specie') <> nil) then Familles := Familles + ',ESPECE';
  if (Element.FindNode('Parent') <> nil) or (Element.FindNode('PictureLevel') <> nil) then Familles := Familles + ',VARIANTE';
  AvecFamilles := EditionPermise;
  FTalentElement := Element;  // pour reconstruire la fiche apres un changement de famille
  SetLength(Champs, 0);
  AjouteChamp(Champs, ChampFiche('Description', 'RULES-LAB_002', gfTexte, True, True));
  if AvecFamilles then
    AjouteChamp(Champs, ChampFiche('FamilleCarriere', 'RULES-LAB_FAMILLE_CARRIERE', gfCases, False, False, True, False,
      'ESPECE=' + GetTexteLibelle('RULES-LAB_FAMILLE_ESPECE', 'Restricted to species') +
      '|VARIANTE=' + GetTexteLibelle('RULES-LAB_FAMILLE_VARIANTE', 'Variant of another career')));
  AjouteChamp(Champs, ChampFiche('Explanation', 'RULES-LAB_003', gfMemo, True, False, True));
  AjouteChamp(Champs, ChampFiche('Class', 'RULES-PDF_MAIN1_CLASS', gfCode, False, False, True, False, Copy(ChoixClasse, 2, MaxInt)));
  AjouteChamp(Champs, ChampFiche('Skill', 'RULES-LAB_009', gfCode, False, False, True, False, Copy(ChoixComp, 2, MaxInt)));
  AjouteChamp(Champs, EnGroupes(ChampFiche('Specie', 'RULES-LAB_561', gfCodeLibre, False, False, True, False, ChoixParTags(['Specie', 'Race', 'Nation'], ValeurXML(Element.FindNode('Specie')))), 'Espece+V4,V5'));
  AjouteChamp(Champs, EnGroupes(ChampFiche('Specie#2', 'RULES-LAB_561', gfCodeLibre, False, False, True, False, ChoixParTags(['Specie', 'Race', 'Nation'], ValeurXML(NoeudDeBalise(Element, 'Specie#2')))), 'Espece+V4,V5'));
  AjouteChamp(Champs, EnGroupes(ChampFiche('Specie#3', 'RULES-LAB_561', gfCodeLibre, False, False, True, False, ChoixParTags(['Specie', 'Race', 'Nation'], ValeurXML(NoeudDeBalise(Element, 'Specie#3')))), 'Espece+V4,V5'));
  AjouteChamp(Champs, EnGroupes(ChampFiche('Parent', 'RULES-LAB_957', gfCodeLibre, False, False, True, False, ChoixParTags(['Career'], ValeurXML(Element.FindNode('Parent')))), 'Variante+V4,V5'));
  AjouteChamp(Champs, EnGroupes(ChampFiche('PictureLevel', 'RULES-LAB_958', gfTexte, False, False, True, False), 'Variante+V4,V5'));
  AjouteChamp(Champs, ChampFiche('Page', 'RULES-LAB_699', gfTexte, False, False, True, False));
  FiltrerChampsFiche(Champs, Element, VersionFicheLivre, Familles);
  PanelFiche.Definir(Champs);
  // ordre du schema (CareerType) : Skill avant Class, les blocs de niveaux apres les balises libres, Page en dernier
  PanelFiche.OrdreBalises := 'Description,Explanation,*Skill,Class,*Parent,*Ammunition,*PictureLevel,*Specie,*SUBCHAPTER_LEVEL,*SUBCHAPTER_ATTR,*SUBCHAPTER_SKILL,*SUBCHAPTER_TALENT,*SUBCHAPTER_ITEM,*Page';
  if AvecFamilles then PanelFiche.DeclarerVirtuel('FamilleCarriere');
  PanelFiche.MasquerGrille;  // la carriere ne porte aucun modificateur (ceux de l'appartenance sont a part)
  PanelFiche.Charger(Element);
  if AvecFamilles then PanelFiche.CocherCodes('FamilleCarriere', Familles);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
end;

procedure TWinLivres.AfficherDonneeMetier(CareerCode: String);
var
  Element: TDOMElement;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverCareerElement(CareerCode);
  if Element = nil then Exit;
  FamillesTalent := '';  // nouvelle navigation : les familles cochees ne se gardent pas d'une carriere a l'autre
  AfficherFicheCarriere(Element);
  CodeDonneeSelectionnee := CareerCode;
  PoserImageLivre('C', CareerCode);
end;

// Apercu de l'image de l'ethnie / de la carriere, a droite de la fiche (ou collee au bord droit si la place manque).
procedure TWinLivres.PoserImageLivre(const Genre, Code: String);
var
  X: Integer;
begin
  X := PanelFiche.Left + PanelFiche.Width + 8;
  if X + PanelImageLivre.Width > PanelImageLivre.Parent.ClientWidth then
    X := PanelImageLivre.Parent.ClientWidth - PanelImageLivre.Width - 4;
  PanelImageLivre.Afficher(Genre, Code, EditionPermise, X, PanelFiche.Top);
end;

// Branche d'une carriere WFRP1 : 3 schema d'avancement, 4 competences (texte + grille), 6 equipement.
// Meme principe que les branches WFRP2. Les entrees et sorties ne sont pas dans la carriere : voir DATA_CAREER_LINK_V1.
procedure TWinLivres.AfficherBrancheCarriereV1(Element: TDOMElement; CareerCode: String; Genre: Integer);
begin
  FicheTag := 'Career';
  FicheTypeNoeud := NT_METIER_NIVEAU1;
  FicheCoches := Genre;
  case Genre of
    4: PanelFiche.Definir([ChampFiche('Skills', 'RULES-LAB_009', gfMemo, True, False, True, False)]);
    // equipement de depart : tableau d'objets (« A / B » = choix a la creation), le texte du livre reste dans Trappings
    6: begin
         PanelListesCarriere[4].Preparer(ChoixParTags(['EquipmentV1'], ''));
         PanelFiche.Definir([]);
       end;
  else
    PanelFiche.Definir([]);
  end;
  PanelFiche.OrdreBalises := 'Description,Explanation,*Class,*Basic,*Level,*MagicSchool,*EntryCost,AdvanceScheme,Skills,SUBCHAPTER_SKILL,Trappings,SUBCHAPTER_ITEM,*StartMoney,*Source,*Page';
  PanelFiche.MasquerGrille;
  if Genre = 3 then
  begin
    PanelCarriereV1.DefinirMode(1);
    PanelFiche.Extra := PanelCarriereV1;
  end
  else if Genre = 4 then
  begin
    PanelCarriereV1.DefinirMode(2);
    PanelFiche.Extra := PanelCarriereV1;
  end
  else if Genre = 6 then
    PanelFiche.Extra := PanelListesCarriere[4];
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
  CodeDonneeSelectionnee := CareerCode;
end;

procedure TWinLivres.AfficherBrancheCoches(CareerCode: String; Genre: Integer);
const
  AttributsV2: array[0..17] of String = ('M', 'WS', 'BS', 'S', 'T', 'W', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel', 'A', 'Mag', 'IP', 'FP', 'SB', 'TB');
var
  Sorties: Boolean;
  Element: TDOMElement;
  ChoixListe, LibAttr: String;
  Tri, Choix: TStringList;
  Docs: array[0..1] of TXMLDocument;
  Elements: TDOMNodeList;
  D, I, K: Integer;
  Code, Nom: String;
begin
  MasquerAfficherElements('');
  MasquerForm();
  Element := TrouverCareerElement(CareerCode);
  if Element = nil then Exit;
  if Element.FindNode('AdvanceScheme') <> nil then
  begin
    AfficherBrancheCarriereV1(Element, CareerCode, Genre);
    Exit;
  end;
  if Genre >= 3 then
  begin
    // caracteristiques (profils du livre + Advances), competences, talents, equipement : tableaux
    FicheTag := 'Career';
    FicheTypeNoeud := NT_METIER_NIVEAU1;
    FicheCoches := Genre;
    ChoixListe := '';
    case Genre of
      3: begin
           for K := 0 to High(AttributsV2) do
           begin
             LibAttr := GetAttributLabel('RULES-ATTR_' + AttributsV2[K]);
             if (LibAttr = '') or (LibAttr = 'RULES-ATTR_' + AttributsV2[K]) then Continue;
             if ChoixListe <> '' then ChoixListe := ChoixListe + '|';
             ChoixListe := ChoixListe + 'RULES-ATTR_' + AttributsV2[K] + '=' + LibAttr;
           end;
           K := 0;
         end;
      4: begin ChoixListe := ChoixParTags(['Skill'], ''); K := 1; end;
      5: begin ChoixListe := ChoixParTags(['Talent'], ''); K := 2; end;
    else
      begin ChoixListe := ChoixParTags(['Weapon', 'Armor', 'EquipmentV2', 'Trapping'], ''); K := 3; end;
    end;
    PanelListesCarriere[K].Preparer(ChoixListe);
    if Genre = 3 then
      PanelFiche.Definir([
        ChampFiche('MainProfile', 'RULES-LAB_701', gfTexte, True, False, True, False),
        ChampFiche('SecondaryProfile', 'RULES-LAB_702', gfTexte, True, False, True, False)])
    else
      PanelFiche.Definir([]);
    PanelFiche.OrdreBalises := 'Description,Explanation,MainProfile,SecondaryProfile,Advances,Skills,Talents,Trappings,*StartMoney,SUBCHAPTER_ITEM,SUBCHAPTER_SKILL,SUBCHAPTER_TALENT,Entries,Exits,*ExitCodes,*Basic,*Source,*Page';
    PanelFiche.MasquerGrille;
    PanelFiche.Extra := PanelListesCarriere[K];
    PanelFiche.Charger(Element);
    PanelFiche.LectureSeule := not EditionPermise;
    PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
    PanelFiche.Visible := True;
    if EditionPermise then PrendreSnapshotFiche;
    CodeDonneeSelectionnee := CareerCode;
    Exit;
  end;
  Sorties := Genre = 2;
  Tri := TStringList.Create;
  Choix := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupAccept;
    Docs[0] := XMLDoc;
    Docs[1] := RulebookBaseXML;
    for D := 0 to 1 do
    begin
      if (Docs[D] = nil) or ((D = 1) and (Docs[1] = Docs[0])) then Continue;
      Elements := Docs[D].GetElementsByTagName('Career');
      for I := 0 to Elements.Count - 1 do
      begin
        Code := TDOMElement(Elements.Item[I]).GetAttribute('id');
        if (Code = '') or (TDOMElement(Elements.Item[I]).FindNode('MainProfile') = nil) then Continue;
        Nom := ValeurXML(TDOMElement(Elements.Item[I]).FindNode('Description'));
        if Nom = '' then Continue;
        Tri.Add(Nom + #1 + Code);
      end;
    end;
    for I := 0 to Tri.Count - 1 do
    begin
      K := Pos(#1, Tri[I]);
      Code := Copy(Tri[I], K + 1, MaxInt);
      Nom := Copy(Tri[I], 1, K - 1);
      if Choix.IndexOfName(Code) < 0 then Choix.Add(Code + '=' + Nom);
    end;
    if Sorties then K := 1 else K := 0;
    PanelCochesCarriere[K].Preparer(Choix);
  finally
    Choix.Free;
    Tri.Free;
  end;
  FicheTag := 'Career';
  FicheTypeNoeud := NT_METIER_NIVEAU1;
  if Sorties then FicheCoches := 2 else FicheCoches := 1;
  PanelFiche.Definir([]);
  PanelFiche.MasquerGrille;
  PanelFiche.Extra := PanelCochesCarriere[K];
  PanelFiche.Charger(Element);
  PanelFiche.LectureSeule := not EditionPermise;
  PanelFiche.Placer(StringGridDetail.Left, StringGridDetail.Top);
  PanelFiche.Visible := True;
  if EditionPermise then PrendreSnapshotFiche;
  CodeDonneeSelectionnee := CareerCode;
end;

procedure TWinLivres.NettoyerForm();
begin
  FicheSnapshot := '';
  if ComboCompLieeFiche <> nil then  // NettoyerForm est appelee dans FormCreate avant sa creation
    ComboCompLieeFiche.Visible := False;
  if PanelBonus <> nil then
    PanelBonus.Visible := False;
  if PanelImageLivre <> nil then
    PanelImageLivre.Masquer;
  EditFormAttrName.Clear;
  EditFormAttrDices.Clear;
  EditFormAttrBaseValue.Clear;
  EditFormAttrFormula.Clear;
  EditFormComponent1Attr.Clear;
  EditFormComponent1Coeff.Clear;
  EditFormComponent2Attr.Clear;
  EditFormComponent2Coeff.Clear;
  EditFormComponent3Attr.Clear;
  EditFormComponent3Coeff.Clear;
  CodeDonneeSelectionnee := '';
  
  // Hide all controls by default
  LabelFormAttrName.Visible := False;
  EditFormAttrName.Visible := False;
  LabelFormAttrDices.Visible := False;
  EditFormAttrDices.Visible := False;
  LabelFormAttrBaseValue.Visible := False;
  EditFormAttrBaseValue.Visible := False;
  LabelFormAttrFormula.Visible := False;
  EditFormAttrFormula.Visible := False;
  
  // Hide component controls
  LabelFormComponent1.Visible := False;
  EditFormComponent1Attr.Visible := False;
  EditFormComponent1Coeff.Visible := False;
  LabelFormComponent2.Visible := False;
  EditFormComponent2Attr.Visible := False;
  EditFormComponent2Coeff.Visible := False;
  LabelFormComponent3.Visible := False;
  EditFormComponent3Attr.Visible := False;
  EditFormComponent3Coeff.Visible := False;
  
  // Hide skills grid
  LabelFormSkills.Visible := False;
  StringGridCareers.Visible := False;
  LabelTotalCareers.Visible := False;
end;

procedure TWinLivres.MasquerForm();
begin
  GroupBoxForm.Visible := False;
  LabelFormSkills.Visible := False;
  StringGridCareers.Visible := False;
  
  // Vérifier avant d'accéder aux contrôles talents
  if LabelTalentsRandom <> nil then
    LabelTalentsRandom.Visible := False;
  if TreeViewTalents <> nil then
    TreeViewTalents.Visible := False;

  // (le titre n'est plus remis a « Select » : TreeViewLivreChange le fixe au texte du noeud)
  NettoyerForm();
end;

// ✨ BOUTONS FORM (DÉSACTIVÉS POUR AFFICHAGE)

// Entete d'une carriere : libelle (<Description>), texte (<Explanation>), classe et competence principale.
// Memoire seulement, comme les autres edition de WinLivre ; l'arbre prend le nouveau libelle.
// Liste de la competence liee d'un talent : aucune, puis les competences chargees et celles du livre ouvert
// (une competence creee dans cette session n'est pas encore dans ListCompetence), triees par libelle.
// Les conditions (if=) proposees : celles du Rulebook et du livre ouvert (bloc DATA_CONDITION), sans doublon.
procedure TWinLivres.RemplirConditions;
var
  Docs: array[0..1] of TXMLDocument;
  D, J: Integer;
  Chapitre: TDOMNode;
  Elements: TDOMNodeList;
  Id: String;
begin
  CodesConditions.Clear;
  Docs[0] := RulebookXML;
  Docs[1] := XMLDoc;
  for D := 0 to 1 do
  begin
    if Docs[D] = nil then Continue;
    Chapitre := Docs[D].GetElementsByTagName('DATA_CONDITION').Item[0];
    if Chapitre = nil then Continue;
    Elements := TDOMElement(Chapitre).GetElementsByTagName('Condition');
    for J := 0 to Elements.Count - 1 do
    begin
      Id := TDOMElement(Elements.Item[J]).GetAttribute('id');
      if (Id <> '') and (CodesConditions.IndexOf(Id) < 0) then CodesConditions.Add(Id);
    end;
  end;
end;

procedure TWinLivres.RemplirCompLieeFiche(const CodeActuel: String);
var
  Tri: TStringList;
  Elements: TDOMNodeList;
  I: Integer;
  Id, Lib: String;
begin
  RemplirConditions;
  Tri := TStringList.Create;
  try
    Tri.Sorted := True;
    Tri.Duplicates := dupIgnore;
    if ListCompetence <> nil then
      for I := 0 to ListCompetence.Count - 1 do
        if not ListCompetence[I].SousCompetence then
          Tri.Add(ListCompetence[I].Libelle + #1 + ListCompetence[I].CodeCompetence);
    Elements := XMLDoc.GetElementsByTagName('Skill');
    for I := 0 to Elements.Count - 1 do
    begin
      Id := TDOMElement(Elements.Item[I]).GetAttribute('id');
      if Id = '' then Continue;
      Lib := ValeurXML(Elements.Item[I].FindNode('Description'));
      if Lib = '' then Lib := Id;
      Tri.Add(Lib + #1 + Id);
    end;
    if (CodeActuel <> '') and (Pos(#1 + CodeActuel, Tri.Text) = 0) then
      Tri.Add(CodeActuel + #1 + CodeActuel);  // la valeur actuelle reste choisissable
    CodesCompLieeFiche.Clear;
    ComboCompLieeFiche.Items.Clear;
    CodesCompLieeFiche.Add('');
    ComboCompLieeFiche.Items.Add('');
    for I := 0 to Tri.Count - 1 do
    begin
      ComboCompLieeFiche.Items.Add(Copy(Tri[I], 1, Pos(#1, Tri[I]) - 1));
      CodesCompLieeFiche.Add(Copy(Tri[I], Pos(#1, Tri[I]) + 1, Length(Tri[I])));
    end;
  finally
    Tri.Free;
  end;
  ComboCompLieeFiche.ItemIndex := CodesCompLieeFiche.IndexOf(CodeActuel);
end;

end.
